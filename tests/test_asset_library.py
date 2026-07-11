import struct
import zlib

from interrogation_unfold.asset_library import build_usage_index, discover_lua_sequences
from interrogation_unfold.defold_texture import FrameRect, crop_rgba, write_rgba_png


def _png_scanlines(payload: bytes) -> bytes:
    offset = 8
    compressed = bytearray()
    while offset < len(payload):
        length = struct.unpack(">I", payload[offset : offset + 4])[0]
        chunk_type = payload[offset + 4 : offset + 8]
        chunk = payload[offset + 8 : offset + 8 + length]
        if chunk_type == b"IDAT":
            compressed.extend(chunk)
        offset += length + 12
    return zlib.decompress(compressed)


def test_png_writer_preserves_cropped_rgba_pixels(tmp_path):
    red = bytes((255, 0, 0, 255))
    green = bytes((0, 255, 0, 255))
    blue = bytes((0, 0, 255, 255))
    white = bytes((255, 255, 255, 255))
    pixels = red + green + blue + white

    cropped = crop_rgba(pixels, 2, FrameRect(x=1, y=0, width=1, height=2))
    output = tmp_path / "crop.png"
    write_rgba_png(output, 1, 2, cropped)

    assert output.read_bytes().startswith(b"\x89PNG\r\n\x1a\n")
    assert _png_scanlines(output.read_bytes()) == b"\x00" + green + b"\x00" + white


def test_logical_sequences_recover_runtime_composed_character_animation():
    sequences = discover_lua_sequences()
    by_name = {sequence["name"]: sequence for sequence in sequences}

    assert len(sequences) == 64
    assert sum(len(sequence["frames"]) for sequence in sequences) == 731
    assert by_name["helene_idle"]["character"] == "helene"
    assert by_name["helene_idle"]["context"] == "interrogation"
    assert by_name["elias_idle4_cut"]["fps"] == 19
    assert len(by_name["elias_idle4_cut"]["frames"]) > 20


def test_usage_index_connects_episode_answers_and_fuior_scene_commands():
    usages = build_usage_index()

    assert any(
        usage["kind"] == "answer" and "answer 5" in usage["detail"] for usage in usages["actor_wtf"]
    )
    assert any(
        usage["kind"] == "fuior-animate"
        and usage["source"] == "fuior/chapter1/interlude_b2.fui"
        and usage["line"] == 49
        for usage in usages["jen_normal_angry"]
    )
    assert any(
        usage["kind"] == "play-animation-effect" and "companion=True" in usage["detail"]
        for usage in usages["interpreter_wtf"]
    )
