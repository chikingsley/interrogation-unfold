"""Decrypt and extract Defold encrypted script files."""

from __future__ import annotations

from collections import Counter
from typing import TypedDict

import lz4.block

from interrogation_unfold.defold_archive import ArchiveEntry, read_arci
from interrogation_unfold.defold_manifest import parse_manifest
from interrogation_unfold.paths import (
    ARCD_PATH,
    ARCI_PATH,
    DECRYPTED_BYTECODE_OUTPUT_DIR,
    DMANIFEST_PATH,
)
from interrogation_unfold.protobuf import WIRE_LENGTH_DELIMITED, bytes_field, decode_all_fields

XTEA_KEY = b"aQj8CScgNP4VsfXK"
XTEA_DELTA = 0x9E3779B9
XTEA_ROUNDS = 32
MASK32 = 0xFFFFFFFF
LUAJIT_SIGNATURE = b"\x1bLJ"
LUA_FIELD_SOURCE = 1
LUA_FIELD_FILENAME = 2
LUA_FIELD_BYTECODE_32 = 3
LUA_FIELD_BYTECODE_64 = 4


class LuaModule(TypedDict):
    """Decoded Defold LuaModule payload."""

    script: bytes
    filename: str
    bytecode_32: bytes
    bytecode_64: bytes


class EncryptedEntry(ArchiveEntry):
    """Archive entry with resolved manifest URL."""

    url: str


def bytes_to_int32_be(data: bytes, n: int) -> list[int]:
    """Convert bytes to a big-endian int32 array."""
    result = [0] * (n >> 2)
    for index, byte in enumerate(data):
        result[index >> 2] |= (byte & 0xFF) << ((3 - (index & 3)) << 3)
    return result


def int32_to_bytes_be(values: list[int]) -> bytes:
    """Convert an int32 array back to big-endian bytes."""
    result = bytearray(len(values) * 4)
    for index, value in enumerate(values):
        masked = value & MASK32
        result[index * 4] = (masked >> 24) & 0xFF
        result[index * 4 + 1] = (masked >> 16) & 0xFF
        result[index * 4 + 2] = (masked >> 8) & 0xFF
        result[index * 4 + 3] = masked & 0xFF
    return bytes(result)


def xtea_encrypt(values: list[int], key: list[int]) -> list[int]:
    """XTEA-encrypt a 64-bit block."""
    first, second = values[0] & MASK32, values[1] & MASK32
    state = 0
    for _ in range(XTEA_ROUNDS):
        first = (
            first + ((((second << 4) ^ (second >> 5)) + second) ^ (state + key[state & 3]))
        ) & MASK32
        state = (state + XTEA_DELTA) & MASK32
        second = (
            second + ((((first << 4) ^ (first >> 5)) + first) ^ (state + key[(state >> 11) & 3]))
        ) & MASK32
    return [first, second]


def xtea_ctr_decrypt(data: bytes, key: bytes) -> bytes:
    """Decrypt bytes using XTEA in CTR mode."""
    int_key = bytes_to_int32_be(key, len(key))
    result = bytearray(len(data))
    counter = [0, 0]
    encrypted_counter = b""

    for index, byte in enumerate(data):
        if index % 8 == 0:
            encrypted_counter = int32_to_bytes_be(xtea_encrypt(counter, int_key))
            counter[1] = (counter[1] + 1) & MASK32
        result[index] = (byte ^ encrypted_counter[index % 8]) & 0xFF

    return bytes(result)


def parse_lua_module(data: bytes) -> LuaModule:
    """Parse Defold's compiled LuaModule protobuf wrapper."""
    inner_data = None
    for field_number, wire_type, value in decode_all_fields(data):
        if field_number == LUA_FIELD_SOURCE and wire_type == WIRE_LENGTH_DELIMITED:
            inner_data = bytes_field(value)
            break

    if inner_data is None:
        return {"script": b"", "filename": "", "bytecode_32": b"", "bytecode_64": b""}

    result: dict[int, bytes] = {}
    for field_number, wire_type, value in decode_all_fields(inner_data):
        if (
            field_number
            in {LUA_FIELD_SOURCE, LUA_FIELD_FILENAME, LUA_FIELD_BYTECODE_32, LUA_FIELD_BYTECODE_64}
            and wire_type == WIRE_LENGTH_DELIMITED
        ):
            field_bytes = bytes_field(value)
            if field_bytes is not None:
                result[field_number] = field_bytes

    filename_raw = result.get(LUA_FIELD_FILENAME, b"")
    return {
        "script": result.get(LUA_FIELD_SOURCE, b""),
        "filename": filename_raw.decode("utf-8", errors="replace"),
        "bytecode_32": result.get(LUA_FIELD_BYTECODE_32, b""),
        "bytecode_64": result.get(LUA_FIELD_BYTECODE_64, b""),
    }


def _encrypted_entries(
    entries: list[ArchiveEntry],
    hash_to_url: dict[str, str],
) -> list[EncryptedEntry]:
    encrypted: list[EncryptedEntry] = []
    for entry in entries:
        if not entry["is_encrypted"]:
            continue
        url = hash_to_url.get(entry["hash"])
        if url is None:
            continue
        encrypted.append({**entry, "url": url})
    return encrypted


def _bytecode_output_path(url: str, *, is_lua_source: bool) -> str:
    rel_path = url.lstrip("/").removesuffix("c")

    if is_lua_source:
        for old_ext in (".script", ".gui_script", ".render_script"):
            if rel_path.endswith(old_ext):
                return rel_path[: -len(old_ext)] + ".lua"
        return rel_path

    for old_ext in (".script", ".gui_script", ".render_script", ".lua"):
        if rel_path.endswith(old_ext):
            return rel_path[: -len(old_ext)] + ".ljbc"
    if rel_path.endswith(".ljbc"):
        return rel_path
    return f"{rel_path}.ljbc"


def _decrypt_entries(encrypted: list[EncryptedEntry]) -> Counter[str]:
    stats: Counter[str] = Counter()
    DECRYPTED_BYTECODE_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    with ARCD_PATH.open("rb") as arcd:
        for entry in encrypted:
            url = entry["url"]
            stats["total"] += 1

            arcd.seek(entry["resource_offset"])
            data = arcd.read(entry["compressed_size"])
            data = xtea_ctr_decrypt(data, XTEA_KEY)

            if entry["is_compressed"]:
                try:
                    data = lz4.block.decompress(data, uncompressed_size=entry["size"])
                    stats["decompressed"] += 1
                except lz4.block.LZ4BlockError as exc:
                    print(f"  WARN: LZ4 decompress failed for {url}: {exc}")
                    stats["decompress_fail"] += 1
                    continue

            try:
                parsed = parse_lua_module(data)
            except ValueError as exc:
                print(f"  WARN: protobuf parse failed for {url}: {exc}")
                stats["parse_fail"] += 1
                continue

            bytecode = parsed["bytecode_64"] or parsed["bytecode_32"] or parsed["script"]
            if not bytecode:
                stats["empty"] += 1
                continue

            is_luajit = bytecode.startswith(LUAJIT_SIGNATURE)
            is_lua_source = not is_luajit

            if parsed["bytecode_64"]:
                stats["bytecode_64"] += 1
            elif parsed["bytecode_32"]:
                stats["bytecode_32"] += 1
            if parsed["script"]:
                stats["lua_source"] += 1

            rel_path = _bytecode_output_path(url, is_lua_source=is_lua_source)
            out_path = DECRYPTED_BYTECODE_OUTPUT_DIR / rel_path
            out_path.parent.mkdir(parents=True, exist_ok=True)
            out_path.write_bytes(bytecode)

            stats["saved"] += 1
            kind = "source" if is_lua_source else "LuaJIT bytecode"
            print(f"  {url} -> {parsed['filename'] or url} ({kind})")

    return stats


def _print_summary(stats: Counter[str]) -> None:
    print(f"\n{'=' * 50}")
    print("Decryption complete!")
    print(f"  Total encrypted: {stats['total']}")
    print(f"  Saved:           {stats['saved']}")
    print(f"    64-bit bc:     {stats['bytecode_64']}")
    print(f"    32-bit bc:     {stats['bytecode_32']}")
    print(f"    Lua source:    {stats['lua_source']}")
    print(f"  LZ4 decompressed: {stats['decompressed']}")
    print(f"  Decompress fail:  {stats['decompress_fail']}")
    print(f"  Parse fail:       {stats['parse_fail']}")
    print(f"  Empty:            {stats['empty']}")
    print(f"\nOutput: {DECRYPTED_BYTECODE_OUTPUT_DIR}/")

    luajit_count = stats["bytecode_64"] + stats["bytecode_32"]
    if luajit_count:
        print(f"\n{luajit_count} LuaJIT bytecode files saved as .ljbc")
        print("To decompile to readable Lua, install luajit-decompiler-v2:")
        print("  git clone https://github.com/marsinator358/luajit-decompiler-v2.git")
        print("  cd luajit-decompiler-v2 && cmake -B build && cmake --build build")
        print(
            f"  ./build/luajit-decompiler-v2 {DECRYPTED_BYTECODE_OUTPUT_DIR} "
            "-o generated/decompiled-lua/",
        )


def main() -> None:
    """Run encrypted script decryption."""
    if not ARCI_PATH.exists() or not ARCD_PATH.exists():
        print("game.arci and game.arcd not found.")
        print("Copy them into raw/archives/ from the app bundle.")
        raise SystemExit(1)

    print("Parsing archive index...")
    index = read_arci(ARCI_PATH)

    print("Parsing manifest...")
    hash_to_url = parse_manifest(DMANIFEST_PATH)
    encrypted = _encrypted_entries(index["entries"], hash_to_url)
    print(f"Found {len(encrypted)} encrypted entries")

    _print_summary(_decrypt_entries(encrypted))
