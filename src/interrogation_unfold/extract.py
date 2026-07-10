"""Extract files from a Defold game archive."""

from __future__ import annotations

from collections import Counter
from dataclasses import dataclass
from pathlib import Path

import lz4.block

from interrogation_unfold.defold_archive import ArchiveIndex, read_arci
from interrogation_unfold.defold_manifest import parse_manifest
from interrogation_unfold.paths import ARCD_PATH, ARCI_PATH, DMANIFEST_PATH, EXTRACTED_OUTPUT_DIR

MAX_PRINTED_ERRORS = 20


@dataclass(frozen=True)
class ExtractionResult:
    """Archive extraction counters and diagnostics."""

    stats: Counter[str]
    unmatched: list[str]
    errors: list[str]


def extract_archive(
    index: ArchiveIndex,
    hash_to_url: dict[str, str],
    arcd_path: Path,
    output_dir: Path,
) -> ExtractionResult:
    """Extract all archive entries that can be matched to manifest URLs."""
    output_dir.mkdir(parents=True, exist_ok=True)

    stats: Counter[str] = Counter()
    unmatched: list[str] = []
    errors: list[str] = []

    with arcd_path.open("rb") as arcd:
        for entry in index["entries"]:
            stats["total"] += 1

            url = hash_to_url.get(entry["hash"])
            if url is None:
                stats["unmatched"] += 1
                unmatched.append(entry["hash"])
                continue

            stats["matched"] += 1
            if entry["is_encrypted"]:
                stats["encrypted"] += 1
            if entry["is_compressed"]:
                stats["compressed"] += 1
            else:
                stats["uncompressed"] += 1
            if entry["is_liveupdate"]:
                stats["liveupdate"] += 1

            arcd.seek(entry["resource_offset"])
            data = arcd.read(entry["compressed_size"])

            if entry["is_compressed"] and not entry["is_encrypted"]:
                try:
                    data = lz4.block.decompress(data, uncompressed_size=entry["size"])
                    stats["decompressed_ok"] += 1
                except lz4.block.LZ4BlockError as exc:
                    stats["decompress_fail"] += 1
                    errors.append(f"LZ4 decompress failed for {url}: {exc}")
            elif entry["is_compressed"] and entry["is_encrypted"]:
                stats["encrypted_compressed"] += 1

            out_path = output_dir / url.lstrip("/")
            out_path.parent.mkdir(parents=True, exist_ok=True)
            out_path.write_bytes(data)
            stats["saved"] += 1

    return ExtractionResult(stats=stats, unmatched=unmatched, errors=errors)


def print_stats(result: ExtractionResult) -> None:
    """Print extraction statistics."""
    stats = result.stats
    print("\n" + "=" * 60)
    print("EXTRACTION RESULTS")
    print("=" * 60)
    print(f"Total entries in archive:  {stats['total']}")
    print(f"Matched to URLs:           {stats['matched']}")
    print(f"Unmatched (no URL):        {stats['unmatched']}")
    print()
    print(f"Compressed entries:        {stats['compressed']}")
    print(f"Uncompressed entries:      {stats['uncompressed']}")
    print(f"Encrypted entries:         {stats['encrypted']}")
    print(f"  (encrypted+compressed):  {stats['encrypted_compressed']}")
    print(f"Live update entries:       {stats['liveupdate']}")
    print()
    print(f"Successfully decompressed: {stats['decompressed_ok']}")
    print(f"Decompression failures:    {stats['decompress_fail']}")
    print(f"Files saved:               {stats['saved']}")

    if result.errors:
        print(f"\nErrors ({len(result.errors)}):")
        for err in result.errors[:MAX_PRINTED_ERRORS]:
            print(f"  - {err}")
        if len(result.errors) > MAX_PRINTED_ERRORS:
            print(f"  ... and {len(result.errors) - MAX_PRINTED_ERRORS} more")

    if result.unmatched:
        print("\nFirst 10 unmatched hashes:")
        for hash_hex in result.unmatched[:10]:
            print(f"  {hash_hex}")


def show_file_type_summary(output_dir: Path) -> None:
    """Show a summary of extracted file types."""
    ext_counter: Counter[str] = Counter()
    total_size = 0
    for path in output_dir.rglob("*"):
        if path.is_file():
            ext_counter[path.suffix or "(no extension)"] += 1
            total_size += path.stat().st_size

    print(f"\n{'=' * 60}")
    print("FILE TYPE SUMMARY")
    print(f"{'=' * 60}")
    print(f"Total extracted size: {total_size / (1024 * 1024):.1f} MB")
    print(f"\n{'Extension':<30} {'Count':>8}")
    print("-" * 40)
    for ext, count in ext_counter.most_common():
        print(f"{ext:<30} {count:>8}")


def main() -> None:
    """Run the archive extractor."""
    print("Defold Archive Extractor")
    print(f"ARCI: {ARCI_PATH}")
    print(f"ARCD: {ARCD_PATH}")
    print(f"DMANIFEST: {DMANIFEST_PATH}")
    print(f"Output: {EXTRACTED_OUTPUT_DIR}")
    print()

    if not ARCI_PATH.exists() or not ARCD_PATH.exists():
        print("game.arci and game.arcd not found.")
        print("Copy them into raw/archives/ from the app bundle.")
        raise SystemExit(1)

    print("--- Parsing archive index ---")
    index = read_arci(ARCI_PATH, announce=True)

    print("\n--- Parsing manifest ---")
    hash_to_url = parse_manifest(DMANIFEST_PATH, announce=True)

    print("\n--- Extracting files ---")
    result = extract_archive(index, hash_to_url, ARCD_PATH, EXTRACTED_OUTPUT_DIR)

    print_stats(result)
    show_file_type_summary(EXTRACTED_OUTPUT_DIR)
