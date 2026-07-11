"""Console entry point for corpus inspection and archive tooling."""

from __future__ import annotations

import argparse
from collections.abc import Sequence
from pathlib import Path

from interrogation_unfold import corpus, decrypt, extract
from interrogation_unfold.asset_library import DEFAULT_OUTPUT_DIR, build_asset_library
from interrogation_unfold.defold_texture import recover_animations
from interrogation_unfold.operation_prototype import (
    DEFAULT_PROTOTYPE_ASSET_DIR,
    prepare_operation_prototype,
)
from interrogation_unfold.tutorial_export import export_tutorial


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
    tutorial_parser = subparsers.add_parser(
        "export-tutorial",
        help="Export the original Episode 0 academy tutorial as resolved local JSON.",
    )
    tutorial_parser.add_argument("output_path", type=Path)
    library_parser = subparsers.add_parser(
        "build-asset-library",
        help="Recover extracted atlases into folders and build a browsable source-aware catalog.",
    )
    library_parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help=f"Library destination. Defaults to {DEFAULT_OUTPUT_DIR}.",
    )
    library_parser.add_argument(
        "--scope",
        choices=("characters", "all"),
        default="all",
        help="Recover character atlases only or the complete visual payload.",
    )
    library_parser.add_argument(
        "--clean",
        action="store_true",
        help="Remove the destination before rebuilding it.",
    )
    library_parser.add_argument(
        "--metadata-only",
        action="store_true",
        help="Build the catalog without decoding PNG frames.",
    )
    operation_parser = subparsers.add_parser(
        "prepare-operation-prototype",
        help="Prepare the ignored private asset pack for Operation Platform Two.",
    )
    operation_parser.add_argument(
        "--asset-library",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help=f"Recovered asset library. Defaults to {DEFAULT_OUTPUT_DIR}.",
    )
    operation_parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_PROTOTYPE_ASSET_DIR,
        help=f"Private asset destination. Defaults to {DEFAULT_PROTOTYPE_ASSET_DIR}.",
    )
    operation_parser.add_argument(
        "--clean",
        action="store_true",
        help="Remove the destination before preparing it.",
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
    elif args.command == "export-tutorial":
        export_tutorial(args.output_path)
        print(f"Exported original tutorial data to {args.output_path}")
    elif args.command == "build-asset-library":
        catalog = build_asset_library(
            output_dir=args.output_dir,
            scope=args.scope,
            clean=args.clean,
            metadata_only=args.metadata_only,
        )
        summary = catalog["summary"]
        print(
            f"Built {summary['atlases']} atlases, {summary['atlas_clips']} clips, "
            f"and {summary['logical_sequences']} logical sequences in {args.output_dir}"
        )
    elif args.command == "prepare-operation-prototype":
        manifest = prepare_operation_prototype(
            asset_library=args.asset_library,
            output_dir=args.output_dir,
            clean=args.clean,
        )
        print(
            f"Prepared {len(manifest['animations'])} animations and "
            f"{len(manifest['caseFile'])} case-file states in {args.output_dir}"
        )
    else:  # pragma: no cover - argparse enforces the command set.
        return 2

    return 0
