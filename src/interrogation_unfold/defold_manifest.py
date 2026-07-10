"""Defold manifest parsing helpers."""

from __future__ import annotations

from pathlib import Path

from interrogation_unfold.protobuf import WIRE_LENGTH_DELIMITED, bytes_field, decode_all_fields

FIELD_MANIFEST_DATA = 1
FIELD_RESOURCE_ENTRY = 3
FIELD_RESOURCE_URL = 1
FIELD_RESOURCE_HASH = 3
FIELD_DIGEST_BYTES = 1


def _first_bytes_field(buf: bytes, wanted_field: int) -> bytes | None:
    for field_number, wire_type, value in decode_all_fields(buf):
        if field_number == wanted_field and wire_type == WIRE_LENGTH_DELIMITED:
            return bytes_field(value)
    return None


def _resource_entries(manifest_data: bytes) -> list[bytes]:
    resources: list[bytes] = []
    for field_number, wire_type, value in decode_all_fields(manifest_data):
        if field_number == FIELD_RESOURCE_ENTRY and wire_type == WIRE_LENGTH_DELIMITED:
            resource = bytes_field(value)
            if resource is not None:
                resources.append(resource)
    return resources


def _extract_hash_from_digest(buf: bytes) -> bytes:
    digest = _first_bytes_field(buf, FIELD_DIGEST_BYTES)
    return buf if digest is None else digest


def _resource_mapping(resource: bytes) -> tuple[str | None, str | None]:
    hash_hex = None
    url = None
    for field_number, wire_type, value in decode_all_fields(resource):
        if field_number == FIELD_RESOURCE_URL and wire_type == WIRE_LENGTH_DELIMITED:
            url_bytes = bytes_field(value)
            if url_bytes is not None:
                url = url_bytes.decode("utf-8", errors="replace")
        elif field_number == FIELD_RESOURCE_HASH and wire_type == WIRE_LENGTH_DELIMITED:
            hash_bytes = bytes_field(value)
            if hash_bytes is not None:
                hash_hex = _extract_hash_from_digest(hash_bytes).hex()
    return hash_hex, url


def parse_manifest(path: Path, *, announce: bool = False) -> dict[str, str]:
    """Parse ``game.dmanifest`` and return archive hash to resource URL mappings."""
    manifest_data = _first_bytes_field(path.read_bytes(), FIELD_MANIFEST_DATA)
    if manifest_data is None:
        msg = "Could not find ManifestData in ManifestFile"
        raise ValueError(msg)

    hash_to_url: dict[str, str] = {}
    for resource in _resource_entries(manifest_data):
        hash_hex, url = _resource_mapping(resource)
        if hash_hex and url:
            hash_to_url[hash_hex] = url

    if announce:
        print(f"\nManifest: {len(hash_to_url)} resource entries parsed")
    return hash_to_url
