"""Decrypt and extract Defold encrypted script files.

Reads directly from the game archive (arci/arcd), decrypts with XTEA-CTR
using Defold's static key, decompresses LZ4, then extracts LuaJIT bytecode
from the protobuf wrapper.
"""

import struct
import sys
from collections import Counter
from pathlib import Path

import lz4.block

# --- Defold's static XTEA key (unchanged across all versions) ---
XTEA_KEY = b"aQj8CScgNP4VsfXK"

ENCRYPTED_EXTENSIONS = {".scriptc", ".gui_scriptc", ".render_scriptc", ".luac"}
XTEA_DELTA = 0x9E3779B9
XTEA_ROUNDS = 32
MASK32 = 0xFFFFFFFF

BASE_DIR = Path(__file__).parent
ARCI_PATH = BASE_DIR / "game.arci"
ARCD_PATH = BASE_DIR / "game.arcd"
DMANIFEST_PATH = BASE_DIR / "game.dmanifest"
OUTPUT_DIR = BASE_DIR / "decrypted"

HASH_MAX_LENGTH = 64
NOT_COMPRESSED = 0xFFFFFFFF
FLAG_ENCRYPTED = 1 << 0


# === XTEA-CTR Decryption ===

def bytes_to_int32_be(data: bytes, n: int) -> list[int]:
    """Convert bytes to big-endian int32 array (matches Java toIntArray)."""
    result = [0] * (n >> 2)
    for i in range(len(data)):
        result[i >> 2] |= (data[i] & 0xFF) << ((3 - (i & 3)) << 3)
    return result


def int32_to_bytes_be(values: list[int]) -> bytes:
    """Convert int32 array back to big-endian bytes (matches Java toByteArray)."""
    result = bytearray(len(values) * 4)
    for i, v in enumerate(values):
        v = v & MASK32
        result[i * 4] = (v >> 24) & 0xFF
        result[i * 4 + 1] = (v >> 16) & 0xFF
        result[i * 4 + 2] = (v >> 8) & 0xFF
        result[i * 4 + 3] = v & 0xFF
    return bytes(result)


def xtea_encrypt(v: list[int], key: list[int]) -> list[int]:
    """XTEA encrypt a 64-bit block (two int32s)."""
    v0, v1 = v[0] & MASK32, v[1] & MASK32
    s = 0
    for _ in range(XTEA_ROUNDS):
        v0 = (v0 + ((((v1 << 4) ^ (v1 >> 5)) + v1) ^ (s + key[s & 3]))) & MASK32
        s = (s + XTEA_DELTA) & MASK32
        v1 = (v1 + ((((v0 << 4) ^ (v0 >> 5)) + v0) ^ (s + key[(s >> 11) & 3]))) & MASK32
    return [v0, v1]


def xtea_ctr_decrypt(data: bytes, key: bytes) -> bytes:
    """Decrypt data using XTEA in CTR mode."""
    int_key = bytes_to_int32_be(key, 16)
    result = bytearray(len(data))
    counter = [0, 0]
    enc_counter = b""

    for i in range(len(data)):
        if i % 8 == 0:
            enc_counter = int32_to_bytes_be(xtea_encrypt(counter, int_key))
            counter[1] = (counter[1] + 1) & MASK32
        result[i] = (data[i] ^ enc_counter[i % 8]) & 0xFF

    return bytes(result)


# === Protobuf Parsing ===

def decode_varint(buf, pos):
    result = 0
    shift = 0
    while pos < len(buf):
        b = buf[pos]
        result |= (b & 0x7F) << shift
        pos += 1
        if not (b & 0x80):
            break
        shift += 7
    return result, pos


def decode_all_fields(buf):
    fields = []
    pos = 0
    while pos < len(buf):
        if pos >= len(buf):
            break
        tag, pos = decode_varint(buf, pos)
        field_number = tag >> 3
        wire_type = tag & 0x07

        if wire_type == 0:  # varint
            val, pos = decode_varint(buf, pos)
        elif wire_type == 2:  # length-delimited
            length, pos = decode_varint(buf, pos)
            val = buf[pos:pos + length]
            pos += length
        elif wire_type == 1:  # 64-bit
            val = struct.unpack_from("<Q", buf, pos)[0]
            pos += 8
        elif wire_type == 5:  # 32-bit
            val = struct.unpack_from("<I", buf, pos)[0]
            pos += 4
        else:
            break

        fields.append((field_number, wire_type, val))
    return fields


def parse_lua_module(data: bytes) -> dict:
    """Parse Defold's compiled Lua module protobuf.

    Outer message (LuaModule):
        Field 1: nested LuaSource message
        Field 2: module dependencies (repeated string)
        Field 3: resource dependencies (repeated string)

    Inner LuaSource:
        Field 1: script (bytes) - Lua source text (HTML5 only)
        Field 2: filename (string)
        Field 3: bytecode (bytes) - LuaJIT 32-bit
        Field 4: bytecode_64 (bytes) - LuaJIT 64-bit
    """
    outer_fields = decode_all_fields(data)

    # Extract inner LuaSource from field 1
    inner_data = None
    for fn, wt, val in outer_fields:
        if fn == 1 and wt == 2:
            inner_data = val
            break

    if inner_data is None:
        return {"script": b"", "filename": "", "bytecode_32": b"", "bytecode_64": b""}

    inner_fields = decode_all_fields(inner_data)
    result = {}
    for fn, wt, val in inner_fields:
        if fn in (1, 2, 3, 4) and wt == 2:
            result[fn] = val

    filename_raw = result.get(2, b"")
    return {
        "script": result.get(1, b""),
        "filename": filename_raw.decode("utf-8", errors="replace") if isinstance(filename_raw, bytes) else "",
        "bytecode_32": result.get(3, b""),
        "bytecode_64": result.get(4, b""),
    }


# === Archive Reading ===

def read_arci(path: Path) -> list[dict]:
    data = path.read_bytes()
    entry_count = struct.unpack_from(">I", data, 0x10)[0]
    entry_offset = struct.unpack_from(">I", data, 0x14)[0]
    hash_offset = struct.unpack_from(">I", data, 0x18)[0]
    hash_length = struct.unpack_from(">I", data, 0x1C)[0]

    entries = []
    for i in range(entry_count):
        eo = entry_offset + i * 16
        resource_offset, size, compressed_size, flags = struct.unpack_from(">IIII", data, eo)

        ho = hash_offset + i * HASH_MAX_LENGTH
        hash_hex = data[ho:ho + hash_length].hex()

        is_compressed = compressed_size != NOT_COMPRESSED
        if not is_compressed:
            compressed_size = size

        entries.append({
            "resource_offset": resource_offset,
            "size": size,
            "compressed_size": compressed_size,
            "flags": flags,
            "hash": hash_hex,
            "is_compressed": is_compressed,
            "is_encrypted": bool(flags & FLAG_ENCRYPTED),
        })
    return entries


def parse_manifest(path: Path) -> dict:
    raw = path.read_bytes()
    manifest_fields = decode_all_fields(raw)

    manifest_data = None
    for fn, wt, val in manifest_fields:
        if fn == 1 and wt == 2:
            manifest_data = val
            break

    data_fields = decode_all_fields(manifest_data)
    resources = [val for fn, wt, val in data_fields if fn == 3 and wt == 2]

    hash_to_url = {}
    for res_buf in resources:
        res_fields = decode_all_fields(res_buf)
        url = None
        hash_hex = None
        for fn, wt, val in res_fields:
            if fn == 1 and wt == 2:
                url = val.decode("utf-8", errors="replace")
            elif fn == 3 and wt == 2:
                inner = decode_all_fields(val)
                for ifn, iwt, ival in inner:
                    if ifn == 1 and iwt == 2:
                        hash_hex = ival.hex()
                        break
        if hash_hex and url:
            hash_to_url[hash_hex] = url
    return hash_to_url


# === Main ===

def main():
    if not ARCI_PATH.exists() or not ARCD_PATH.exists():
        print("game.arci and game.arcd not found.")
        print("Copy them from /Applications/Interrogation.app/Wrapper/Interrogation.app/")
        sys.exit(1)

    print("Parsing archive index...")
    entries = read_arci(ARCI_PATH)

    print("Parsing manifest...")
    hash_to_url = parse_manifest(DMANIFEST_PATH)

    # Find encrypted entries
    encrypted = []
    for entry in entries:
        if not entry["is_encrypted"]:
            continue
        url = hash_to_url.get(entry["hash"])
        if url:
            entry["url"] = url
            encrypted.append(entry)

    print(f"Found {len(encrypted)} encrypted entries")

    stats = Counter()
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    with open(ARCD_PATH, "rb") as arcd:
        for entry in encrypted:
            url = entry["url"]
            stats["total"] += 1

            # Read raw data from archive
            arcd.seek(entry["resource_offset"])
            data = arcd.read(entry["compressed_size"])

            # Step 1: Decrypt
            data = xtea_ctr_decrypt(data, XTEA_KEY)

            # Step 2: Decompress if needed
            if entry["is_compressed"]:
                try:
                    data = lz4.block.decompress(data, uncompressed_size=entry["size"])
                    stats["decompressed"] += 1
                except Exception as e:
                    print(f"  WARN: LZ4 decompress failed for {url}: {e}")
                    stats["decompress_fail"] += 1
                    continue

            # Step 3: Parse LuaSource protobuf
            try:
                parsed = parse_lua_module(data)
            except Exception as e:
                print(f"  WARN: protobuf parse failed for {url}: {e}")
                stats["parse_fail"] += 1
                continue

            # Get bytecode (prefer 64-bit for arm64 iOS)
            bytecode = parsed["bytecode_64"] or parsed["bytecode_32"] or parsed["script"]
            if not bytecode:
                stats["empty"] += 1
                continue

            filename = parsed["filename"] or url
            is_luajit = bytecode[:3] == b"\x1bLJ"
            is_lua_source = not is_luajit

            if parsed["bytecode_64"]:
                stats["bytecode_64"] += 1
            elif parsed["bytecode_32"]:
                stats["bytecode_32"] += 1
            if parsed["script"]:
                stats["lua_source"] += 1

            # Determine output path and extension
            rel_path = url.lstrip("/")
            # Remove compiled 'c' suffix
            if rel_path.endswith("c"):
                rel_path = rel_path[:-1]

            if is_lua_source:
                # Lua source text — save as .lua
                for old_ext in (".script", ".gui_script", ".render_script"):
                    if rel_path.endswith(old_ext):
                        rel_path = rel_path[:-len(old_ext)] + ".lua"
                        break
            else:
                # LuaJIT bytecode — save as .ljbc
                for old_ext in (".script", ".gui_script", ".render_script", ".lua"):
                    if rel_path.endswith(old_ext):
                        rel_path = rel_path[:-len(old_ext)] + ".ljbc"
                        break
                if not rel_path.endswith(".ljbc"):
                    rel_path += ".ljbc"

            out_path = OUTPUT_DIR / rel_path
            out_path.parent.mkdir(parents=True, exist_ok=True)
            out_path.write_bytes(bytecode)

            stats["saved"] += 1
            print(f"  {url} -> {filename} ({'source' if is_lua_source else 'LuaJIT bytecode'})")

    print(f"\n{'='*50}")
    print(f"Decryption complete!")
    print(f"  Total encrypted: {stats['total']}")
    print(f"  Saved:           {stats['saved']}")
    print(f"    64-bit bc:     {stats['bytecode_64']}")
    print(f"    32-bit bc:     {stats['bytecode_32']}")
    print(f"    Lua source:    {stats['lua_source']}")
    print(f"  LZ4 decompressed: {stats['decompressed']}")
    print(f"  Decompress fail:  {stats['decompress_fail']}")
    print(f"  Parse fail:       {stats['parse_fail']}")
    print(f"  Empty:            {stats['empty']}")
    print(f"\nOutput: {OUTPUT_DIR}/")

    ljbc_count = stats["bytecode_64"] + stats["bytecode_32"]
    if ljbc_count:
        print(f"\n{ljbc_count} LuaJIT bytecode files saved as .ljbc")
        print("To decompile to readable Lua, install luajit-decompiler-v2:")
        print("  git clone https://github.com/marsinator358/luajit-decompiler-v2.git")
        print("  cd luajit-decompiler-v2 && cmake -B build && cmake --build build")
        print(f"  ./build/luajit-decompiler-v2 {OUTPUT_DIR} -o decompiled/")


if __name__ == "__main__":
    main()
