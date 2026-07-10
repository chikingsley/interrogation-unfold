"""Minimal protobuf wire helpers for old Defold manifest/script containers."""

from __future__ import annotations

import struct

type WireValue = int | bytes
type Field = tuple[int, int, WireValue]
type DecodedField = tuple[int, int, WireValue, int]

WIRE_VARINT = 0
WIRE_64BIT = 1
WIRE_LENGTH_DELIMITED = 2
WIRE_32BIT = 5


def decode_varint(buf: bytes, pos: int) -> tuple[int, int]:
    """Decode a protobuf varint from ``buf`` starting at ``pos``."""
    result = 0
    shift = 0
    while pos < len(buf):
        byte = buf[pos]
        result |= (byte & 0x7F) << shift
        pos += 1
        if not byte & 0x80:
            return result, pos
        shift += 7
    msg = "Unexpected end of buffer while decoding protobuf varint"
    raise ValueError(msg)


def decode_field(buf: bytes, pos: int) -> DecodedField | None:
    """Decode one protobuf field, returning ``None`` for unsupported wire types."""
    if pos >= len(buf):
        return None

    tag, pos = decode_varint(buf, pos)
    field_number = tag >> 3
    wire_type = tag & 0x7

    if wire_type == WIRE_VARINT:
        value, pos = decode_varint(buf, pos)
    elif wire_type == WIRE_LENGTH_DELIMITED:
        length, pos = decode_varint(buf, pos)
        value = buf[pos : pos + length]
        pos += length
    elif wire_type == WIRE_64BIT:
        value = struct.unpack_from("<Q", buf, pos)[0]
        pos += 8
    elif wire_type == WIRE_32BIT:
        value = struct.unpack_from("<I", buf, pos)[0]
        pos += 4
    else:
        return None

    return field_number, wire_type, value, pos


def decode_all_fields(buf: bytes) -> list[Field]:
    """Decode all supported protobuf fields from a message buffer."""
    fields: list[Field] = []
    pos = 0
    while pos < len(buf):
        decoded = decode_field(buf, pos)
        if decoded is None:
            break
        field_number, wire_type, value, pos = decoded
        fields.append((field_number, wire_type, value))
    return fields


def bytes_field(value: WireValue) -> bytes | None:
    """Return ``value`` when it is a length-delimited bytes field."""
    if isinstance(value, bytes):
        return value
    return None
