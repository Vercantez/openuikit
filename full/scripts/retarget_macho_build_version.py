#!/usr/bin/env python3
"""Rewrite one thin Mach-O LC_BUILD_VERSION for an isolated target SDK.

This does not translate machine code or symbols. It changes the platform and
packed deployment versions on already-compatible ARM64 runtime copies so LLD
can close a coherent iOS-simulator graph. Source runtime artifacts are never
modified.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import struct


MH_MAGIC_64 = 0xFEEDFACF
LC_BUILD_VERSION = 0x32


def packed_version(value: str) -> int:
    pieces = value.split(".")
    if not 1 <= len(pieces) <= 3 or any(not piece.isdigit() for piece in pieces):
        raise ValueError(f"invalid version: {value}")
    numbers = [int(piece) for piece in pieces] + [0, 0]
    major, minor, patch = numbers[:3]
    if major > 0xFFFF or minor > 0xFF or patch > 0xFF:
        raise ValueError(f"version component is out of range: {value}")
    return (major << 16) | (minor << 8) | patch


def retarget(path: Path, platform: int, minimum: int, sdk: int) -> None:
    data = bytearray(path.read_bytes())
    if len(data) < 32 or struct.unpack_from("<I", data, 0)[0] != MH_MAGIC_64:
        raise ValueError(f"not a thin little-endian 64-bit Mach-O: {path}")
    command_count = struct.unpack_from("<I", data, 16)[0]
    offset = 32
    found = 0
    for _ in range(command_count):
        if offset + 8 > len(data):
            raise ValueError(f"truncated load-command table: {path}")
        command, size = struct.unpack_from("<II", data, offset)
        if size < 8 or offset + size > len(data):
            raise ValueError(f"invalid load command: {path}")
        if command == LC_BUILD_VERSION:
            if size < 24:
                raise ValueError(f"short LC_BUILD_VERSION: {path}")
            struct.pack_into("<III", data, offset + 8, platform, minimum, sdk)
            found += 1
        offset += size
    if found != 1:
        raise ValueError(f"expected one LC_BUILD_VERSION, found {found}: {path}")
    path.write_bytes(data)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--platform", type=int, required=True)
    parser.add_argument("--minimum-os", required=True)
    parser.add_argument("--sdk", required=True)
    parser.add_argument("files", nargs="+", type=Path)
    args = parser.parse_args()
    minimum = packed_version(args.minimum_os)
    sdk = packed_version(args.sdk)
    for path in args.files:
        retarget(path, args.platform, minimum, sdk)
        print(f"retargeted\t{path}\tplatform={args.platform}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
