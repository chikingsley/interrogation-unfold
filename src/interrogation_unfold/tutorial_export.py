"""Export the shipped Episode 0 tutorial as browser-consumable local data."""

from __future__ import annotations

import json
import re
from copy import deepcopy
from pathlib import Path
from typing import Any

from interrogation_unfold.paths import CORPUS

LUA_STRING_ENTRY = re.compile(r'^\s*\["(?P<key>[^"]+)"\]\s*=\s*"(?P<value>(?:\\.|[^"])*)",?\s*$')

TUTORIAL_SCRIPT = [
    {
        "id": "welcome",
        "lines": ["tutorial.tutor1", "tutorial.tutor2", "tutorial.tutor3"],
        "gate": "casefile_open",
    },
    {"id": "casefile", "lines": ["tutorial.tutor4"], "gate": "subject_brought_in"},
    {
        "id": "straight_ask",
        "lines": ["tutorial.tutor5"],
        "page": "step1",
        "gate": "completed_intro",
    },
    {
        "id": "meters",
        "lines": [f"tutorial.tutor{index}" for index in range(6, 13)],
        "page": "step2",
        "gate": "empathy_4",
    },
    {
        "id": "fear",
        "lines": ["tutorial.tutor13", "tutorial.tutor14", "tutorial.tutor15"],
        "page": "step3",
        "gate": "fear_4",
    },
    {
        "id": "off_record",
        "lines": ["tutorial.tutor16", "tutorial.tutor17", "tutorial.tutor18"],
        "gate": "recorder_off",
    },
    {
        "id": "torture",
        "lines": ["tutorial.tutor19", "tutorial.tutor20", "tutorial.tutor21"],
        "gate": "two_tortures",
    },
    {"id": "return_record", "lines": ["tutorial.tutor22"], "gate": "recorder_on"},
    {
        "id": "wrap",
        "lines": [f"tutorial.tutor{index}" for index in range(23, 27)],
        "page": "step3",
        "gate": "tutorial_won",
    },
    {"id": "complete", "lines": ["tutorial.tutor27"], "gate": "win"},
]

TORTURE_EFFECTS = {
    "grab": {"id": 1, "damage": 1, "fear": 1, "health": -1, "empathy": -1},
    "wall": {"id": 2, "damage": 2, "fear": 2, "health": -2, "empathy": -2},
    "waterboard": {"id": 3, "damage": 3, "fear": 4, "health": -3, "empathy": -4},
    "cut": {"id": 4, "damage": 3, "fear": 3, "health": -3, "empathy": -3},
}


def parse_lua_string_table(path: Path) -> dict[str, str]:
    """Parse the flat quoted string entries used by shipped localization tables."""
    entries: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        match = LUA_STRING_ENTRY.match(line)
        if match is None:
            continue
        raw = match.group("value")
        entries[match.group("key")] = json.loads(f'"{raw}"')
    return entries


def _resolve_localized_fields(value: Any, strings: dict[str, str]) -> Any:
    if isinstance(value, dict):
        return {key: _resolve_localized_fields(child, strings) for key, child in value.items()}
    if isinstance(value, list):
        return [_resolve_localized_fields(child, strings) for child in value]
    if isinstance(value, str) and value in strings:
        return {"key": value, "text": strings[value]}
    return value


def build_tutorial_export(corpus_dir: Path = CORPUS) -> dict[str, Any]:
    """Build a faithful, resolved data package for the original academy tutorial."""
    level_strings = parse_lua_string_table(corpus_dir / "intl" / "level_episode0.en.lua")
    chapter_strings = parse_lua_string_table(corpus_dir / "intl" / "chapter1.en.lua")
    strings = {**level_strings, **chapter_strings}
    episode = json.loads((corpus_dir / "episodes" / "episode0.json").read_text(encoding="utf-8"))

    tutor_keys = [key for step in TUTORIAL_SCRIPT for key in step["lines"]]
    feedback_keys = sorted(
        key for key in chapter_strings if key.startswith("tutorial.") and key not in tutor_keys
    )

    return {
        "benchmark": "interrogation-academy-tutorial",
        "source": {
            "engine": "Defold 1.2.171",
            "game_version": "1.1.9.dc9529f2",
            "progression": "main/progression/chapter1/tutorial.lua",
            "episode": "episodes/episode0.json",
        },
        "slides": ["A few years ago"],
        "script": deepcopy(TUTORIAL_SCRIPT),
        "tutor_lines": {key: chapter_strings[key] for key in tutor_keys},
        "feedback": {key: chapter_strings[key] for key in feedback_keys},
        "episode": _resolve_localized_fields(episode, strings),
        "torture_effects": TORTURE_EFFECTS,
    }


def export_tutorial(output_path: Path, corpus_dir: Path = CORPUS) -> None:
    """Write the browser tutorial data package to ``output_path``."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(build_tutorial_export(corpus_dir), indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
