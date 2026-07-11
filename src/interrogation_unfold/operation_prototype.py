"""Prepare the private recovered-asset payload used by the operation prototype."""

from __future__ import annotations

import json
import os
import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from interrogation_unfold.asset_library import DEFAULT_OUTPUT_DIR

DEFAULT_PROTOTYPE_ASSET_DIR = (
    Path(__file__).parents[2]
    / "prototypes"
    / "operation-platform-two"
    / "public"
    / "private-assets"
)


@dataclass(frozen=True)
class AnimationSelection:
    """One recovered animation selected for the browser prototype."""

    character: str
    animation: str


ANIMATIONS = (
    AnimationSelection("tutor", "tutor_idle"),
    AnimationSelection("tutor", "tutor_idle_blink"),
    AnimationSelection("tutor", "tutor_explain"),
    AnimationSelection("tutor", "tutor_secret"),
    AnimationSelection("diana", "diana_idle"),
    AnimationSelection("diana", "diana_idle_blink"),
    AnimationSelection("diana", "diana_interested"),
    AnimationSelection("diana", "diana_idle_scared"),
    AnimationSelection("diana", "diana_smile"),
)

SCENE_ASSETS = {
    "background": "assets/level/level/background/000.png",
    "chair": "assets/level/level/chair/000.png",
    "table": "assets/level/level/table/000.png",
    "recorderPaused": "assets/level/level/recorder_pause/000.png",
    "recorderPlaying": "assets/level/level/recorder_play/000.png",
    "bubbleLeft": "assets/level/level/bubble_left_tail/000.png",
    "bubbleRight": "assets/level/level/bubble_right_tail/000.png",
}

CASE_FILE_STATES = (
    "casefile1",
    "casefile2",
    "casefile3",
    "casefile5",
    "casefile7",
    "casefile9",
    "casefile10",
    "casefile11",
    "casefile12",
    "casefile14",
    "casefile16",
)


def _link_or_copy(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    try:
        os.link(source, destination)
    except OSError:
        shutil.copy2(source, destination)


def _load_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text())
    if not isinstance(value, dict):
        msg = f"Expected a JSON object in {path}"
        raise TypeError(msg)
    return value


def _prepare_animation(
    asset_library: Path,
    output_dir: Path,
    selection: AnimationSelection,
) -> dict[str, Any]:
    animation_root = asset_library / "characters" / selection.character / "interrogation"
    source_manifest = _load_json(animation_root / "manifest.json")
    source_animations = source_manifest.get("animations")
    if not isinstance(source_animations, dict):
        msg = f"Missing animations object in {animation_root / 'manifest.json'}"
        raise TypeError(msg)
    animation = source_animations.get(selection.animation)
    if not isinstance(animation, dict):
        msg = f"Missing recovered animation {selection.animation}"
        raise FileNotFoundError(msg)
    source_frames = animation.get("frames")
    if not isinstance(source_frames, list) or not all(
        isinstance(frame, str) for frame in source_frames
    ):
        msg = f"Invalid frame list for {selection.animation}"
        raise TypeError(msg)

    web_frames: list[str] = []
    for frame in source_frames:
        source = animation_root / frame
        relative = Path("characters") / selection.character / frame
        _link_or_copy(source, output_dir / relative)
        web_frames.append(f"./private-assets/{relative.as_posix()}")

    return {
        "frames": web_frames,
        "fps": animation["fps"],
        "width": animation["width"],
        "height": animation["height"],
    }


def _prepare_scene(asset_library: Path, output_dir: Path) -> dict[str, str]:
    scene: dict[str, str] = {}
    for name, source_relative in SCENE_ASSETS.items():
        source = asset_library / source_relative
        relative = Path("scene") / f"{name}.png"
        _link_or_copy(source, output_dir / relative)
        scene[name] = f"./private-assets/{relative.as_posix()}"
    return scene


def _prepare_case_file(asset_library: Path, output_dir: Path) -> list[str]:
    web_frames: list[str] = []
    for index, state in enumerate(CASE_FILE_STATES):
        source = asset_library / "assets" / "level" / "casefile" / "casefile" / state / "000.png"
        relative = Path("case-file") / f"{index:02d}.png"
        _link_or_copy(source, output_dir / relative)
        web_frames.append(f"./private-assets/{relative.as_posix()}")
    return web_frames


def prepare_operation_prototype(
    *,
    asset_library: Path = DEFAULT_OUTPUT_DIR,
    output_dir: Path = DEFAULT_PROTOTYPE_ASSET_DIR,
    clean: bool = False,
) -> dict[str, Any]:
    """Materialize the small, ignored asset pack required by the browser operation."""
    if clean and output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    animations = {
        selection.animation: _prepare_animation(asset_library, output_dir, selection)
        for selection in ANIMATIONS
    }
    manifest: dict[str, Any] = {
        "notice": "Private local benchmark assets. Do not publish or commit.",
        "animations": animations,
        "scene": _prepare_scene(asset_library, output_dir),
        "caseFile": _prepare_case_file(asset_library, output_dir),
    }

    manifest_path = output_dir / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    return manifest
