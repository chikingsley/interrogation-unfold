"""Shared repository paths used by the analysis CLI."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CORPUS = ROOT / "corpus"
RAW_DIR = ROOT / "raw"
ARCHIVES_DIR = RAW_DIR / "archives"
METADATA_DIR = RAW_DIR / "metadata"
ARCI_PATH = ARCHIVES_DIR / "game.arci"
ARCD_PATH = ARCHIVES_DIR / "game.arcd"
DMANIFEST_PATH = METADATA_DIR / "game.dmanifest"
GENERATED_DIR = ROOT / "generated"
EXTRACTED_OUTPUT_DIR = GENERATED_DIR / "extracted"
DECRYPTED_BYTECODE_OUTPUT_DIR = GENERATED_DIR / "decrypted-bytecode"
