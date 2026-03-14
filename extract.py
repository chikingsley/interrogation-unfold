#!/usr/bin/env python3
"""
Extract files from a Defold game archive (game.arci + game.arcd + game.dmanifest).

Designed for "Interrogation: You Will Be Deceived" built with Defold 1.2.171.
"""

import struct
from collections import Counter
from pathlib import Path

import lz4.block

# --- Configuration ---
BASE_DIR = Path(__file__).parent
ARCI_PATH = BASE_DIR / "game.arci"
ARCD_PATH = BASE_DIR / "game.arcd"
DMANIFEST_PATH = BASE_DIR / "game.dmanifest"
OUTPUT_DIR = BASE_DIR / "output"

HASH_MAX_LENGTH = 64  # Each hash slot is padded to 64 bytes
NOT_COMPRESSED = 0xFFFFFFFF

# Archive entry flags
FLAG_ENCRYPTED = 1 << 0
FLAG_COMPRESSED = 1 << 1
FLAG_LIVEUPDATE = 1 << 2


def read_arci(path: Path) -> dict:
    """Parse the .arci archive index file."""
    with open(path, "rb") as f:
        data = f.read()

    # Header (0x20 = 32 bytes)
    version = struct.unpack_from(">I", data, 0x0)[0]
    # 0x4: padding (4 bytes)
    # 0x8: userdata (8 bytes)
    entry_count = struct.unpack_from(">I", data, 0x10)[0]
    entry_offset = struct.unpack_from(">I", data, 0x14)[0]
    hash_offset = struct.unpack_from(">I", data, 0x18)[0]
    hash_length = struct.unpack_from(">I", data, 0x1C)[0]

    print(f"Archive Index v{version}")
    print(f"  Entry count:  {entry_count}")
    print(f"  Entry offset: 0x{entry_offset:X}")
    print(f"  Hash offset:  0x{hash_offset:X}")
    print(f"  Hash length:  {hash_length} bytes")

    entries = []
    for i in range(entry_count):
        # Read the 16-byte entry
        eo = entry_offset + i * 16
        resource_offset, size, compressed_size, flags = struct.unpack_from(
            ">IIII", data, eo
        )

        # Read the hash (hash_length bytes from the hash block, each block is 64 bytes)
        ho = hash_offset + i * HASH_MAX_LENGTH
        hash_bytes = data[ho : ho + hash_length]
        hash_hex = hash_bytes.hex()

        is_compressed = compressed_size != NOT_COMPRESSED
        if not is_compressed:
            compressed_size = size

        entries.append(
            {
                "resource_offset": resource_offset,
                "size": size,
                "compressed_size": compressed_size,
                "flags": flags,
                "hash": hash_hex,
                "is_compressed": is_compressed,
                "is_encrypted": bool(flags & FLAG_ENCRYPTED),
                "is_liveupdate": bool(flags & FLAG_LIVEUPDATE),
            }
        )

    return {"version": version, "entry_count": entry_count, "entries": entries}


def parse_manifest_binary(path: Path) -> dict:
    """
    Parse the dmanifest protobuf to extract URL-to-hash mappings.

    The file is a ManifestFile protobuf message where:
    - Field 1 (data): bytes containing a serialized ManifestData message
    - ManifestData field 3 (resources): repeated ResourceEntry
    - ResourceEntry (older proto, matching Defold 1.2.171):
        - field 1: url (string)
        - field 2: url_hash (uint64)
        - field 3: hash (HashDigest submessage, field 1 = bytes)
        - field 4: dependants (repeated HashDigest)
        - field 5: flags (uint32)
    """
    raw = path.read_bytes()

    # Manually decode the protobuf wire format since compiling the full
    # proto chain with custom extensions is complex. The wire format is simple:
    # Each field is: (field_number << 3 | wire_type) as a varint, then the value.

    def decode_varint(buf, pos):
        """Decode a varint from buf at position pos."""
        result = 0
        shift = 0
        while True:
            b = buf[pos]
            result |= (b & 0x7F) << shift
            pos += 1
            if not (b & 0x80):
                break
            shift += 7
        return result, pos

    def decode_field(buf, pos):
        """Decode a single protobuf field, return (field_number, wire_type, value, new_pos) or None."""
        if pos >= len(buf):
            return None
        tag, pos = decode_varint(buf, pos)
        field_number = tag >> 3
        wire_type = tag & 0x7

        if wire_type == 0:  # Varint
            value, pos = decode_varint(buf, pos)
        elif wire_type == 2:  # Length-delimited
            length, pos = decode_varint(buf, pos)
            value = buf[pos : pos + length]
            pos += length
        elif wire_type == 1:  # 64-bit
            value = struct.unpack_from("<Q", buf, pos)[0]
            pos += 8
        elif wire_type == 5:  # 32-bit
            value = struct.unpack_from("<I", buf, pos)[0]
            pos += 4
        else:
            # Skip unknown wire types by returning None
            return None

        return field_number, wire_type, value, pos

    def decode_all_fields(buf):
        """Decode all fields from a protobuf message buffer."""
        fields = []
        pos = 0
        while pos < len(buf):
            result = decode_field(buf, pos)
            if result is None:
                break
            field_number, wire_type, value, pos = result
            fields.append((field_number, wire_type, value))
        return fields

    def extract_hash_from_digest(buf):
        """Extract the hash bytes from a HashDigest submessage (field 1 = bytes)."""
        result = decode_field(buf, 0)
        if result and result[0] == 1 and result[1] == 2:
            return result[2]  # The bytes value
        return buf  # Fallback: treat the whole thing as the hash

    # Step 1: Decode ManifestFile - field 1 is 'data' (bytes containing ManifestData)
    manifest_file_fields = decode_all_fields(raw)

    manifest_data_bytes = None
    for fn, wt, val in manifest_file_fields:
        if fn == 1 and wt == 2:  # data field
            manifest_data_bytes = val
            break

    if manifest_data_bytes is None:
        raise ValueError("Could not find ManifestData in ManifestFile")

    # Step 2: Decode ManifestData - field 3 is repeated ResourceEntry
    manifest_data_fields = decode_all_fields(manifest_data_bytes)

    resources = []
    for fn, wt, val in manifest_data_fields:
        if fn == 3 and wt == 2:  # ResourceEntry (length-delimited = submessage)
            resources.append(val)

    # Step 3: Decode each ResourceEntry
    # The older proto (matching this game version) uses:
    #   Field 1: url (string)
    #   Field 2: url_hash (uint64, varint-encoded)
    #   Field 3: hash (HashDigest submessage, field 1 = bytes)
    #   Field 4: dependants (repeated HashDigest)
    #   Field 5: flags (uint32)
    hash_to_url = {}
    url_list = []

    for res_buf in resources:
        res_fields = decode_all_fields(res_buf)
        hash_hex = None
        url = None

        for fn, wt, val in res_fields:
            if fn == 1 and wt == 2:  # url (string)
                url = val.decode("utf-8", errors="replace")
            elif fn == 3 and wt == 2:  # HashDigest submessage
                hash_bytes = extract_hash_from_digest(val)
                hash_hex = hash_bytes.hex()

        if hash_hex and url:
            hash_to_url[hash_hex] = url
            url_list.append(url)

    print(f"\nManifest: {len(url_list)} resource entries parsed")
    return hash_to_url


def extract_archive(
    index: dict, hash_to_url: dict, arcd_path: Path, output_dir: Path
):
    """Extract all files from the archive."""
    output_dir.mkdir(parents=True, exist_ok=True)

    stats = Counter()
    unmatched = []
    errors = []

    with open(arcd_path, "rb") as arcd:
        for entry in index["entries"]:
            stats["total"] += 1

            # Get the URL for this entry
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

            # Read data from archive
            arcd.seek(entry["resource_offset"])
            data = arcd.read(entry["compressed_size"])

            # Decompress if compressed and not encrypted
            if entry["is_compressed"] and not entry["is_encrypted"]:
                try:
                    data = lz4.block.decompress(
                        data, uncompressed_size=entry["size"]
                    )
                    stats["decompressed_ok"] += 1
                except Exception as e:
                    stats["decompress_fail"] += 1
                    errors.append(f"LZ4 decompress failed for {url}: {e}")
                    # Save the raw compressed data instead
            elif entry["is_compressed"] and entry["is_encrypted"]:
                stats["encrypted_compressed"] += 1

            # Build output path
            # URLs look like /path/to/file.extensionc
            out_path = output_dir / url.lstrip("/")
            out_path.parent.mkdir(parents=True, exist_ok=True)

            out_path.write_bytes(data)
            stats["saved"] += 1

    return stats, unmatched, errors


def print_stats(stats, unmatched, errors):
    """Print extraction statistics."""
    print("\n" + "=" * 60)
    print("EXTRACTION RESULTS")
    print("=" * 60)
    print(f"Total entries in archive:  {stats['total']}")
    print(f"Matched to URLs:           {stats['matched']}")
    print(f"Unmatched (no URL):        {stats['unmatched']}")
    print(f"")
    print(f"Compressed entries:        {stats['compressed']}")
    print(f"Uncompressed entries:      {stats['uncompressed']}")
    print(f"Encrypted entries:         {stats['encrypted']}")
    print(f"  (encrypted+compressed):  {stats['encrypted_compressed']}")
    print(f"Live update entries:       {stats['liveupdate']}")
    print(f"")
    print(f"Successfully decompressed: {stats['decompressed_ok']}")
    print(f"Decompression failures:    {stats['decompress_fail']}")
    print(f"Files saved:               {stats['saved']}")

    if errors:
        print(f"\nErrors ({len(errors)}):")
        for err in errors[:20]:
            print(f"  - {err}")
        if len(errors) > 20:
            print(f"  ... and {len(errors) - 20} more")

    if unmatched:
        print(f"\nFirst 10 unmatched hashes:")
        for h in unmatched[:10]:
            print(f"  {h}")


def show_file_type_summary(output_dir: Path):
    """Show summary of extracted file types."""
    ext_counter = Counter()
    total_size = 0
    for f in output_dir.rglob("*"):
        if f.is_file():
            ext = f.suffix if f.suffix else "(no extension)"
            ext_counter[ext] += 1
            total_size += f.stat().st_size

    print(f"\n{'=' * 60}")
    print("FILE TYPE SUMMARY")
    print(f"{'=' * 60}")
    print(f"Total extracted size: {total_size / (1024 * 1024):.1f} MB")
    print(f"\n{'Extension':<30} {'Count':>8}")
    print("-" * 40)
    for ext, count in ext_counter.most_common():
        print(f"{ext:<30} {count:>8}")


def main():
    print("Defold Archive Extractor")
    print(f"ARCI: {ARCI_PATH}")
    print(f"ARCD: {ARCD_PATH}")
    print(f"DMANIFEST: {DMANIFEST_PATH}")
    print(f"Output: {OUTPUT_DIR}")
    print()

    # Step 1: Parse the archive index
    print("--- Parsing archive index ---")
    index = read_arci(ARCI_PATH)

    # Step 2: Parse the manifest for URL mappings
    print("\n--- Parsing manifest ---")
    hash_to_url = parse_manifest_binary(DMANIFEST_PATH)

    # Step 3: Extract files
    print("\n--- Extracting files ---")
    stats, unmatched, errors = extract_archive(index, hash_to_url, ARCD_PATH, OUTPUT_DIR)

    # Step 4: Print results
    print_stats(stats, unmatched, errors)
    show_file_type_summary(OUTPUT_DIR)


if __name__ == "__main__":
    main()
