import json
from pathlib import Path

from interrogation_unfold.operation_prototype import (
    ANIMATIONS,
    CASE_FILE_STATES,
    SCENE_ASSETS,
    prepare_operation_prototype,
)


def test_prepare_operation_prototype(tmp_path: Path) -> None:
    library = tmp_path / "library"
    output = tmp_path / "output"

    characters: dict[str, dict[str, object]] = {}
    for selection in ANIMATIONS:
        character = characters.setdefault(selection.character, {})
        character[selection.animation] = {
            "frames": [f"{selection.animation}/000.png"],
            "fps": 4,
            "width": 10,
            "height": 20,
        }

    for character, animations in characters.items():
        root = library / "characters" / character / "interrogation"
        root.mkdir(parents=True)
        (root / "manifest.json").write_text(json.dumps({"animations": animations}))
        for animation in animations:
            frame = root / animation / "000.png"
            frame.parent.mkdir()
            frame.write_bytes(b"frame")

    for relative in SCENE_ASSETS.values():
        source = library / relative
        source.parent.mkdir(parents=True, exist_ok=True)
        source.write_bytes(b"scene")

    for state in CASE_FILE_STATES:
        source = library / "assets" / "level" / "casefile" / "casefile" / state / "000.png"
        source.parent.mkdir(parents=True)
        source.write_bytes(b"case")

    manifest = prepare_operation_prototype(
        asset_library=library,
        output_dir=output,
        clean=True,
    )

    assert len(manifest["animations"]) == len(ANIMATIONS)
    assert len(manifest["scene"]) == len(SCENE_ASSETS)
    assert len(manifest["caseFile"]) == len(CASE_FILE_STATES)
    assert (output / "manifest.json").is_file()
    assert (output / "characters" / "tutor" / "tutor_idle" / "000.png").read_bytes() == b"frame"
