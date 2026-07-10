"""Recover PNG frames from Defold 1.2.171 texture resources."""

from __future__ import annotations

import json
import shutil
import struct
import subprocess
from dataclasses import asdict, dataclass
from pathlib import Path

from interrogation_unfold.protobuf import WIRE_LENGTH_DELIMITED, bytes_field, decode_all_fields

TEXTURE_FORMAT_RGBA = 2
TEXTURE_FORMAT_LUMINANCE_ALPHA = 10
TEXTURE_SET_FIELD_ANIMATION = 2
TEXTURE_SET_FIELD_TEX_COORDS = 18
UV_FLOATS_PER_FRAME = 8


@dataclass(frozen=True)
class TextureImage:
    """The single platform-specific image stored in a ``.texturec`` file."""

    width: int
    height: int
    original_width: int
    original_height: int
    format: int
    data: bytes


@dataclass(frozen=True)
class TextureAnimation:
    """One named animation range from a ``.texturesetc`` atlas."""

    name: str
    width: int
    height: int
    start: int
    end: int
    fps: int
    playback: int


@dataclass(frozen=True)
class FrameRect:
    """A top-left-origin atlas crop rectangle."""

    x: int
    y: int
    width: int
    height: int


@dataclass(frozen=True)
class TextureSet:
    """Named animations and UV coordinates from a ``.texturesetc`` file."""

    texture: str
    animations: tuple[TextureAnimation, ...]
    tex_coords: tuple[float, ...]


def _field_map(message: bytes) -> dict[int, int | bytes]:
    return {field_number: value for field_number, _wire_type, value in decode_all_fields(message)}


def parse_texture_image(path: Path) -> TextureImage:
    """Read the first image alternative from a Defold compiled texture."""
    alternatives = [
        bytes_field(value)
        for field_number, wire_type, value in decode_all_fields(path.read_bytes())
        if field_number == 1 and wire_type == WIRE_LENGTH_DELIMITED
    ]
    image_message = next((value for value in alternatives if value is not None), None)
    if image_message is None:
        msg = f"No image alternative found in {path}"
        raise ValueError(msg)

    fields = _field_map(image_message)
    data = fields.get(8)
    if not isinstance(data, bytes):
        msg = f"No image payload found in {path}"
        raise TypeError(msg)

    return TextureImage(
        width=int(fields[1]),
        height=int(fields[2]),
        original_width=int(fields[3]),
        original_height=int(fields[4]),
        format=int(fields[5]),
        data=data,
    )


def parse_texture_set(path: Path) -> TextureSet:
    """Read animation ranges and packed UV coordinates from a compiled atlas."""
    texture = ""
    animations: list[TextureAnimation] = []
    tex_coords: tuple[float, ...] = ()

    for field_number, wire_type, value in decode_all_fields(path.read_bytes()):
        if field_number == 1 and wire_type == WIRE_LENGTH_DELIMITED:
            raw = bytes_field(value)
            if raw is not None:
                texture = raw.decode("utf-8", errors="replace")
        elif field_number == TEXTURE_SET_FIELD_ANIMATION and wire_type == WIRE_LENGTH_DELIMITED:
            raw = bytes_field(value)
            if raw is None:
                continue
            fields = _field_map(raw)
            name = fields.get(1)
            if not isinstance(name, bytes):
                continue
            animations.append(
                TextureAnimation(
                    name=name.decode("utf-8", errors="replace"),
                    width=int(fields[2]),
                    height=int(fields[3]),
                    start=int(fields[4]),
                    end=int(fields[5]),
                    fps=int(fields.get(6, 30)),
                    playback=int(fields.get(7, 0)),
                )
            )
        elif field_number == TEXTURE_SET_FIELD_TEX_COORDS and wire_type == WIRE_LENGTH_DELIMITED:
            raw = bytes_field(value)
            if raw is not None:
                tex_coords = struct.unpack(f"<{len(raw) // 4}f", raw)

    if not tex_coords:
        msg = f"No texture coordinates found in {path}"
        raise ValueError(msg)
    return TextureSet(texture=texture, animations=tuple(animations), tex_coords=tex_coords)


def frame_rect(texture_set: TextureSet, frame: int, width: int, height: int) -> FrameRect:
    """Convert one Defold bottom-left-origin UV quad to a PNG crop rectangle."""
    start = frame * UV_FLOATS_PER_FRAME
    coordinates = texture_set.tex_coords[start : start + UV_FLOATS_PER_FRAME]
    if len(coordinates) != UV_FLOATS_PER_FRAME:
        msg = f"Frame {frame} is outside the texture set"
        raise IndexError(msg)

    us = coordinates[0::2]
    vs = coordinates[1::2]
    x0 = round(min(us) * width)
    x1 = round(max(us) * width)
    y0 = round((1.0 - max(vs)) * height)
    y1 = round((1.0 - min(vs)) * height)
    return FrameRect(x=x0, y=y0, width=x1 - x0, height=y1 - y0)


def decode_atlas(texture: TextureImage, output_path: Path) -> None:
    """Decode an uncompressed iOS Defold texture to a correctly oriented PNG."""
    ffmpeg = shutil.which("ffmpeg")
    if ffmpeg is None:
        msg = "ffmpeg is required to recover PNG textures"
        raise RuntimeError(msg)

    if texture.format == TEXTURE_FORMAT_RGBA:
        pixel_format = "rgba"
        filters = "vflip"
    elif texture.format == TEXTURE_FORMAT_LUMINANCE_ALPHA:
        pixel_format = "ya8"
        filters = "vflip"
    else:
        msg = f"Unsupported Defold texture format: {texture.format}"
        raise ValueError(msg)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(  # noqa: S603 - ffmpeg path and argument vector are explicit.
        [
            ffmpeg,
            "-hide_banner",
            "-loglevel",
            "error",
            "-f",
            "rawvideo",
            "-pixel_format",
            pixel_format,
            "-video_size",
            f"{texture.width}x{texture.height}",
            "-i",
            "pipe:0",
            "-vf",
            filters,
            "-frames:v",
            "1",
            "-y",
            str(output_path),
        ],
        input=texture.data,
        check=True,
    )


def recover_animations(
    texturec_path: Path,
    texturesetc_path: Path,
    output_dir: Path,
    names: tuple[str, ...] = (),
) -> dict[str, object]:
    """Decode an atlas and crop selected named animations into numbered PNGs."""
    ffmpeg = shutil.which("ffmpeg")
    if ffmpeg is None:
        msg = "ffmpeg is required to recover PNG textures"
        raise RuntimeError(msg)

    texture = parse_texture_image(texturec_path)
    texture_set = parse_texture_set(texturesetc_path)
    selected = [
        animation for animation in texture_set.animations if not names or animation.name in names
    ]
    unknown = sorted(set(names) - {animation.name for animation in selected})
    if unknown:
        msg = f"Unknown animations: {', '.join(unknown)}"
        raise ValueError(msg)

    output_dir.mkdir(parents=True, exist_ok=True)
    atlas_path = output_dir / "atlas.png"
    decode_atlas(texture, atlas_path)

    animation_manifest: dict[str, object] = {}
    for animation in selected:
        animation_dir = output_dir / animation.name
        animation_dir.mkdir(parents=True, exist_ok=True)
        frames: list[str] = []
        for output_index, atlas_index in enumerate(range(animation.start, animation.end)):
            rect = frame_rect(texture_set, atlas_index, texture.width, texture.height)
            output_path = animation_dir / f"{output_index:03d}.png"
            subprocess.run(  # noqa: S603 - ffmpeg path and argument vector are explicit.
                [
                    ffmpeg,
                    "-hide_banner",
                    "-loglevel",
                    "error",
                    "-i",
                    str(atlas_path),
                    "-vf",
                    f"crop={rect.width}:{rect.height}:{rect.x}:{rect.y}",
                    "-frames:v",
                    "1",
                    "-y",
                    str(output_path),
                ],
                check=True,
            )
            frames.append(str(output_path.relative_to(output_dir)))
        animation_manifest[animation.name] = {
            **asdict(animation),
            "frames": frames,
        }

    manifest: dict[str, object] = {
        "source": {
            "texturec": str(texturec_path),
            "texturesetc": str(texturesetc_path),
        },
        "texture": {
            "width": texture.width,
            "height": texture.height,
            "format": texture.format,
        },
        "animations": animation_manifest,
    }
    (output_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n",
        encoding="utf-8",
    )
    return manifest
