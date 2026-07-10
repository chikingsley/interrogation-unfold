"""Console entry point for corpus inspection and archive tooling."""

from __future__ import annotations

import argparse
from collections.abc import Sequence
from pathlib import Path

from interrogation_unfold import corpus, decrypt, extract
from interrogation_unfold.defold_texture import recover_animations


def build_parser() -> argparse.ArgumentParser:
    """Build the top-level command parser."""
    parser = argparse.ArgumentParser(
        prog="interrogation-unfold",
        description="Inspect and regenerate the Interrogation readable corpus.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("inspect", help="Print inventory for the checked-in corpus.")
    subparsers.add_parser("extract", help="Extract raw resources into generated/extracted/.")
    subparsers.add_parser(
        "decrypt",
        help="Decrypt encrypted Defold script resources into generated/decrypted-bytecode/.",
    )
    recover_parser = subparsers.add_parser(
        "recover-texture",
        help="Decode a Defold texture atlas and recover named animation frames.",
    )
    recover_parser.add_argument("texturec", type=Path)
    recover_parser.add_argument("texturesetc", type=Path)
    recover_parser.add_argument("output_dir", type=Path)
    recover_parser.add_argument(
        "--animation",
        action="append",
        default=[],
        help="Animation to recover; repeat the option to select several. Defaults to all.",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    """Run the selected CLI command."""
    args = build_parser().parse_args(argv)

    if args.command == "inspect":
        corpus.main()
    elif args.command == "extract":
        extract.main()
    elif args.command == "decrypt":
        decrypt.main()
    elif args.command == "recover-texture":
        manifest = recover_animations(
            args.texturec,
            args.texturesetc,
            args.output_dir,
            tuple(args.animation),
        )
        animations = manifest["animations"]
        if not isinstance(animations, dict):
            raise TypeError
        print(f"Recovered {len(animations)} animations into {args.output_dir}")
    else:  # pragma: no cover - argparse enforces the command set.
        return 2

    return 0
