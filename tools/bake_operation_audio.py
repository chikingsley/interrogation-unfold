# /// script
# requires-python = ">=3.13"
# dependencies = [
#   "omnivoice==0.2.0",
#   "soundfile>=0.13.1",
# ]
# ///
"""Bake the operation prototype's three consistent OmniVoice speakers."""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import soundfile as sf  # ty: ignore[unresolved-import]
import torch  # ty: ignore[unresolved-import]
from omnivoice.models.omnivoice import OmniVoice  # ty: ignore[unresolved-import]
from omnivoice.utils.common import get_best_device  # ty: ignore[unresolved-import]

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CONTENT = (
    REPO_ROOT / "prototypes" / "operation-platform-two" / "src" / "operation.json"
)
DEFAULT_OUTPUT = (
    REPO_ROOT / "prototypes" / "operation-platform-two" / "public" / "private-audio"
)
DEFAULT_CONTACT_REFERENCE = Path(
    "/home/simon/github/episodic/planning/planning-v4/prototypes/pilots/"
    "concierge-call/public/audio/generated/omnivoice-concierge-audition.wav"
)
CONTACT_REFERENCE_TEXT = (
    "Bonjour, monsieur. Je comprends un peu l'anglais, mais parlez lentement, "
    "s'il vous plaît."
)


@dataclass(frozen=True)
class Line:
    audio_id: str
    speaker: str
    script: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--content", type=Path, default=DEFAULT_CONTENT)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument(
        "--contact-reference",
        type=Path,
        default=DEFAULT_CONTACT_REFERENCE,
    )
    parser.add_argument("--model", default="k2-fsa/OmniVoice")
    parser.add_argument("--device", default=None)
    parser.add_argument("--num-step", type=int, default=32)
    parser.add_argument("--force", action="store_true")
    return parser.parse_args()


def load_lines(path: Path) -> list[Line]:
    content: dict[str, Any] = json.loads(path.read_text())
    unique: dict[str, Line] = {}
    for beat in content["beats"]:
        audio_id = beat.get("audioId")
        if audio_id is None:
            continue
        line = Line(audio_id, beat["speaker"], beat["script"])
        existing = unique.get(audio_id)
        if existing is not None and existing != line:
            raise ValueError(f"Conflicting definitions for {audio_id}")
        unique[audio_id] = line
    return list(unique.values())


def seed_everything(seed: int) -> None:
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)


def save_audio(path: Path, audio: Any, sampling_rate: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    sf.write(path, audio, sampling_rate)


def make_reference(
    model: OmniVoice,
    *,
    path: Path,
    text: str,
    language: str,
    instruct: str,
    seed: int,
    num_step: int,
    force: bool,
) -> None:
    if path.exists() and not force:
        return
    seed_everything(seed)
    audio = model.generate(
        text=text,
        language=language,
        instruct=instruct,
        num_step=num_step,
        position_temperature=0.0,
    )[0]
    save_audio(path, audio, model.sampling_rate)


def main() -> None:
    args = parse_args()
    lines = load_lines(args.content)
    args.output.mkdir(parents=True, exist_ok=True)

    if not args.contact_reference.is_file():
        raise FileNotFoundError(f"Missing contact reference: {args.contact_reference}")

    device = args.device or get_best_device()
    print(f"Loading {args.model} on {device}")
    model = OmniVoice.from_pretrained(
        args.model,
        device_map=device,
        dtype=torch.float16,
    )

    reference_dir = args.output / "_references"
    handler_reference = reference_dir / "handler.wav"
    courier_reference = reference_dir / "courier.wav"
    handler_reference_text = (
        "Keep your eyes on the clock. We move only when the call confirms the time."
    )
    courier_reference_text = (
        "Bonsoir. Je vous appelle pour confirmer l'heure et le lieu du rendez-vous."
    )
    make_reference(
        model,
        path=handler_reference,
        text=handler_reference_text,
        language="en",
        instruct="male, middle-aged, low pitch",
        seed=7301,
        num_step=args.num_step,
        force=args.force,
    )
    make_reference(
        model,
        path=courier_reference,
        text=courier_reference_text,
        language="fr",
        instruct="male, middle-aged, moderate pitch",
        seed=7302,
        num_step=args.num_step,
        force=args.force,
    )

    prompts = {
        "handler": model.create_voice_clone_prompt(
            str(handler_reference),
            handler_reference_text,
        ),
        "courier": model.create_voice_clone_prompt(
            str(courier_reference),
            courier_reference_text,
        ),
        "contact": model.create_voice_clone_prompt(
            str(args.contact_reference),
            CONTACT_REFERENCE_TEXT,
        ),
    }
    languages = {"handler": "en", "courier": "fr", "contact": "fr"}

    manifest: dict[str, dict[str, Any]] = {}
    for index, line in enumerate(lines):
        destination = args.output / f"{line.audio_id}.wav"
        if not destination.exists() or args.force:
            print(f"[{index + 1:02d}/{len(lines):02d}] {line.speaker}: {line.audio_id}")
            seed_everything(8100 + index)
            audio = model.generate(
                text=line.script,
                language=languages[line.speaker],
                voice_clone_prompt=prompts[line.speaker],
                num_step=args.num_step,
                position_temperature=0.0,
            )[0]
            save_audio(destination, audio, model.sampling_rate)
        info = sf.info(destination)
        manifest[line.audio_id] = {
            "path": f"./private-audio/{destination.name}",
            "speaker": line.speaker,
            "seconds": round(info.duration, 3),
        }

    manifest_path = args.output / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Wrote {len(manifest)} lines to {args.output}")


if __name__ == "__main__":
    main()
