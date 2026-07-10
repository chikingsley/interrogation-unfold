"""Inventory reports for the checked-in readable Interrogation corpus."""

from __future__ import annotations

import json
import re
from collections import Counter
from pathlib import Path
from typing import Any, TypedDict

from interrogation_unfold.paths import CORPUS, ROOT

type CountPairs = list[tuple[str, int]]

STAT_NAMES = {
    0: "empathy",
    1: "fear",
    2: "health",
    3: "insanity",
    4: "cruelty",
    5: "insanity_cruelty",
    6: "times_asked",
    7: "times_answered",
    8: "torture_damage",
    9: "popularity",
    10: "press",
    11: "authorities",
    13: "tab_approval",
    14: "jen_approval",
    15: "mordecai_approval",
    16: "equity",
    17: "freedom",
    18: "evolution",
    19: "lawful",
    20: "justice",
}

CONDITION_TYPES = {
    6: "flag_is_set",
    7: "flag_is_not_set",
    8: "or",
    11: "and",
    31: "as_subject",
    32: "at_least",
    33: "at_most",
    34: "is_equal",
    35: "ternary",
    36: "more_than",
    37: "less_than",
}

EFFECT_TYPES = {
    3: "set_flag",
    4: "win",
    7: "lose",
    8: "unset_flag",
    11: "conditional_effect",
    12: "navigate",
    13: "fire_event",
    14: "play_animation",
    15: "set_idle",
    16: "replace_page",
    17: "increment_stat",
}


class EpisodeRow(TypedDict):
    """Summary for one episode JSON file."""

    file: str
    level_id: Any
    namespace: Any
    subjects: int
    questions: int
    answers: int
    hints: int
    common_texts: int


class EpisodeTotals(TypedDict):
    """Aggregate episode graph counters."""

    files: int
    subjects: int
    questions: int
    answers: int
    hints: int
    condition_types: CountPairs
    effect_types: CountPairs
    stat_refs: CountPairs
    flags_top: list[tuple[str, int]]


class FuiorInventory(TypedDict):
    """Aggregate FUIOR script counters."""

    files_by_folder: CountPairs
    commands: CountPairs


def label(counter: Counter[int], names: dict[int, str]) -> CountPairs:
    """Render numeric game enum values with known labels."""
    return [(names.get(key, str(key)), value) for key, value in counter.most_common()]


def _record_conditions(value: dict[Any, Any], condition_types: Counter[int]) -> None:
    for key in ("conditions", "visibility_conditions"):
        conditions = value.get(key)
        if not isinstance(conditions, list):
            continue
        for condition in conditions:
            if isinstance(condition, dict):
                condition_type = condition.get("type")
                if isinstance(condition_type, int):
                    condition_types[condition_type] += 1


def _record_effects(value: dict[Any, Any], effect_types: Counter[int]) -> None:
    for key in ("effects", "repeating_effects"):
        effects = value.get(key)
        if not isinstance(effects, list):
            continue
        for effect in effects:
            if isinstance(effect, dict):
                effect_type = effect.get("type")
                if isinstance(effect_type, int):
                    effect_types[effect_type] += 1


def _record_stat_reference(value: dict[Any, Any], stat_refs: Counter[int]) -> None:
    if value.get("type") not in {32, 33, 34, 36, 37}:
        return
    condition_value = value.get("value") or {}
    if isinstance(condition_value, dict):
        stat = condition_value.get("stat")
        if isinstance(stat, int):
            stat_refs[stat] += 1


def _record_flag_reference(value: dict[Any, Any], flags: Counter[str]) -> None:
    if value.get("type") not in {3, 6, 7, 8}:
        return
    flag_value = value.get("value")
    if isinstance(flag_value, str):
        flags[flag_value] += 1


def _walk_episode(
    value: Any,
    condition_types: Counter[int],
    effect_types: Counter[int],
    stat_refs: Counter[int],
    flags: Counter[str],
) -> None:
    if isinstance(value, dict):
        _record_conditions(value, condition_types)
        _record_effects(value, effect_types)
        _record_stat_reference(value, stat_refs)
        _record_flag_reference(value, flags)

        for child in value.values():
            _walk_episode(child, condition_types, effect_types, stat_refs, flags)
    elif isinstance(value, list):
        for item in value:
            _walk_episode(item, condition_types, effect_types, stat_refs, flags)


def episode_inventory(
    corpus_dir: Path = CORPUS,
    root_dir: Path = ROOT,
) -> tuple[list[EpisodeRow], EpisodeTotals]:
    """Summarize episode JSON graph files."""
    rows: list[EpisodeRow] = []
    condition_types: Counter[int] = Counter()
    effect_types: Counter[int] = Counter()
    stat_refs: Counter[int] = Counter()
    flags: Counter[str] = Counter()

    for path in sorted((corpus_dir / "episodes").glob("*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        rows.append(
            {
                "file": str(path.relative_to(root_dir)),
                "level_id": data.get("level_id"),
                "namespace": data.get("intl_namespace"),
                "subjects": len(data.get("subjects") or []),
                "questions": len(data.get("questions") or []),
                "answers": len(data.get("answers") or []),
                "hints": len(data.get("hints") or []),
                "common_texts": len(data.get("common_texts") or []),
            }
        )
        _walk_episode(data, condition_types, effect_types, stat_refs, flags)

    totals: EpisodeTotals = {
        "files": len(rows),
        "subjects": sum(row["subjects"] for row in rows),
        "questions": sum(row["questions"] for row in rows),
        "answers": sum(row["answers"] for row in rows),
        "hints": sum(row["hints"] for row in rows),
        "condition_types": label(condition_types, CONDITION_TYPES),
        "effect_types": label(effect_types, EFFECT_TYPES),
        "stat_refs": label(stat_refs, STAT_NAMES),
        "flags_top": flags.most_common(20),
    }
    return rows, totals


def fuior_inventory(corpus_dir: Path = CORPUS) -> FuiorInventory:
    """Summarize FUIOR narrative DSL files."""
    command_counts: Counter[str] = Counter()
    folder_counts: Counter[str] = Counter()
    speaker_pattern = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
    fuior_dir = corpus_dir / "fuior"

    for path in sorted(fuior_dir.rglob("*.fui")):
        rel = path.relative_to(fuior_dir)
        folder_counts[rel.parts[0] if len(rel.parts) > 1 else "(root)"] += 1

        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            if stripped.startswith("*"):
                command_counts["choice_option"] += 1
                continue
            if ":" in stripped:
                speaker = stripped.split(":", 1)[0].strip()
                if speaker_pattern.match(speaker):
                    command_counts["dialogue_line"] += 1
                    continue
            command_counts[stripped.split()[0]] += 1

    return {
        "files_by_folder": folder_counts.most_common(),
        "commands": command_counts.most_common(30),
    }


def lua_inventory(
    corpus_dir: Path = CORPUS,
    root_dir: Path = ROOT,
) -> list[tuple[str, int, int]]:
    """Summarize Lua files by top-level subsystem."""
    rows: list[tuple[str, int, int]] = []
    for directory in sorted(path for path in corpus_dir.iterdir() if path.is_dir()):
        files = list(directory.rglob("*.lua"))
        if not files:
            continue
        line_count = 0
        for file_path in files:
            with file_path.open(encoding="utf-8", errors="replace") as handle:
                line_count += sum(1 for _ in handle)
        rows.append((str(directory.relative_to(root_dir)), len(files), line_count))
    return sorted(rows, key=lambda row: row[2], reverse=True)


def _append_section(lines: list[str], title: str) -> None:
    lines.extend(("", title, "-" * len(title)))


def build_inventory_report() -> str:
    """Build the human-readable inventory report."""
    episode_rows, episode_totals = episode_inventory()
    fuior = fuior_inventory()
    lua_rows = lua_inventory()
    lines: list[str] = []

    _append_section(lines, "Episode Totals")
    lines.extend(
        f"{key}: {episode_totals[key]}"
        for key in ("files", "subjects", "questions", "answers", "hints")
    )

    _append_section(lines, "Largest Episodes")
    lines.extend(
        (
            f"{row['file']}: {row['questions']} questions, "
            f"{row['answers']} answers, {row['subjects']} subjects"
        )
        for row in sorted(episode_rows, key=lambda item: item["questions"], reverse=True)[:12]
    )

    _append_section(lines, "Condition Types")
    for name, count in episode_totals["condition_types"]:
        lines.append(f"{name}: {count}")

    _append_section(lines, "Effect Types")
    for name, count in episode_totals["effect_types"]:
        lines.append(f"{name}: {count}")

    _append_section(lines, "Stat References")
    for name, count in episode_totals["stat_refs"]:
        lines.append(f"{name}: {count}")

    _append_section(lines, "Top Flags")
    for flag, count in episode_totals["flags_top"]:
        lines.append(f"{flag}: {count}")

    _append_section(lines, "FUIOR Scripts")
    for folder, count in fuior["files_by_folder"]:
        lines.append(f"{folder}: {count}")

    _append_section(lines, "FUIOR Commands")
    for command, count in fuior["commands"]:
        lines.append(f"{command}: {count}")

    _append_section(lines, "Lua Subsystems")
    for path, files, lines_count in lua_rows:
        lines.append(f"{path}: {files} files, {lines_count} lines")

    return "\n".join(lines).lstrip() + "\n"


def main() -> None:
    """Print the corpus inventory report."""
    print(build_inventory_report(), end="")
