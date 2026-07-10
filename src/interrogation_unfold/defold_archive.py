"""Defold archive-index parsing helpers."""

from __future__ import annotations

import struct
from pathlib import Path
from typing import TypedDict

HASH_MAX_LENGTH = 64
NOT_COMPRESSED = 0xFFFFFFFF

FLAG_ENCRYPTED = 1 << 0
FLAG_COMPRESSED = 1 << 1
FLAG_LIVEUPDATE = 1 << 2

HEADER_VERSION_OFFSET = 0x0
HEADER_ENTRY_COUNT_OFFSET = 0x10
HEADER_ENTRY_OFFSET_OFFSET = 0x14
HEADER_HASH_OFFSET_OFFSET = 0x18
HEADER_HASH_LENGTH_OFFSET = 0x1C
ENTRY_SIZE = 16


class ArchiveEntry(TypedDict):
    """One resource entry in a Defold ``game.arci`` file."""

    resource_offset: int
    size: int
    compressed_size: int
    flags: int
    hash: str
    is_compressed: bool
    is_encrypted: bool
    is_liveupdate: bool


class ArchiveIndex(TypedDict):
    """Parsed Defold archive index."""

    version: int
    entry_count: int
    entries: list[ArchiveEntry]


def read_arci(path: Path, *, announce: bool = False) -> ArchiveIndex:
    """Parse a Defold ``game.arci`` archive index file."""
    data = path.read_bytes()

    version = struct.unpack_from(">I", data, HEADER_VERSION_OFFSET)[0]
    entry_count = struct.unpack_from(">I", data, HEADER_ENTRY_COUNT_OFFSET)[0]
    entry_offset = struct.unpack_from(">I", data, HEADER_ENTRY_OFFSET_OFFSET)[0]
    hash_offset = struct.unpack_from(">I", data, HEADER_HASH_OFFSET_OFFSET)[0]
    hash_length = struct.unpack_from(">I", data, HEADER_HASH_LENGTH_OFFSET)[0]

    if announce:
        print(f"Archive Index v{version}")
        print(f"  Entry count:  {entry_count}")
        print(f"  Entry offset: 0x{entry_offset:X}")
        print(f"  Hash offset:  0x{hash_offset:X}")
        print(f"  Hash length:  {hash_length} bytes")

    entries: list[ArchiveEntry] = []
    for index in range(entry_count):
        entry_start = entry_offset + index * ENTRY_SIZE
        resource_offset, size, compressed_size, flags = struct.unpack_from(
            ">IIII",
            data,
            entry_start,
        )

        hash_start = hash_offset + index * HASH_MAX_LENGTH
        hash_bytes = data[hash_start : hash_start + hash_length]
        is_compressed = compressed_size != NOT_COMPRESSED
        stored_size = compressed_size if is_compressed else size

        entries.append(
            {
                "resource_offset": resource_offset,
                "size": size,
                "compressed_size": stored_size,
                "flags": flags,
                "hash": hash_bytes.hex(),
                "is_compressed": is_compressed,
                "is_encrypted": bool(flags & FLAG_ENCRYPTED),
                "is_liveupdate": bool(flags & FLAG_LIVEUPDATE),
            }
        )

    return {"version": version, "entry_count": entry_count, "entries": entries}
