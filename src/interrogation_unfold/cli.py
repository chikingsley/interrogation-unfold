"""Console entry point for corpus inspection and archive tooling."""

from __future__ import annotations

import argparse
from collections.abc import Sequence

from interrogation_unfold import corpus, decrypt, extract


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
    else:  # pragma: no cover - argparse enforces the command set.
        return 2

    return 0
