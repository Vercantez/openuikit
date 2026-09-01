#!/usr/bin/env python3
"""Rewrite one exact Mach-O dylib dependency without changing file layout.

The true-iOS Linux runtime publishes its portable Foundation implementation at
``/usr/lib/libFoundation.dylib``.  Apple's simulator Swift runtime dylibs name
Foundation by its framework path, however.  Loading both spellings under
machorun maps the same portable image twice and registers every Foundation
Objective-C class twice.  This utility performs the deliberately narrow,
shorter-in-place load-command rewrite used by the platform builder.

Only a 64-bit little-endian Mach-O is accepted.  The old dependency must occur
exactly once in a load/reexport command, the replacement must fit in the
existing command, and no byte outside that command's name field is changed.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import struct
import sys


_MH_MAGIC_64 = 0xFEEDFACF
_DYLIB_LOAD_COMMANDS = {0x0C, 0x20, 0x80000018, 0x8000001F, 0x80000023}


class MachODependencyRewriteError(ValueError):
    """The input is not the exact rewrite subject promised by the caller."""


def rewrite_dependency(payload: bytes, old: str, new: str) -> bytes:
    if not old or not new or "\0" in old or "\0" in new:
        raise MachODependencyRewriteError("dependency names must be non-empty UTF-8 strings")
    if len(payload) < 32:
        raise MachODependencyRewriteError("truncated Mach-O header")
    magic, _cpu, _subtype, _filetype, ncmds, sizeofcmds, _flags, _reserved = (
        struct.unpack_from("<IiiIIIII", payload, 0)
    )
    if magic != _MH_MAGIC_64:
        raise MachODependencyRewriteError("input is not a 64-bit little-endian Mach-O")
    commands_end = 32 + sizeofcmds
    if commands_end > len(payload):
        raise MachODependencyRewriteError("truncated Mach-O load commands")

    old_bytes = old.encode("utf-8")
    new_bytes = new.encode("utf-8")
    result = bytearray(payload)
    matches: list[tuple[int, int]] = []
    cursor = 32
    for _ in range(ncmds):
        if cursor + 8 > commands_end:
            raise MachODependencyRewriteError("truncated Mach-O command header")
        command, command_size = struct.unpack_from("<II", payload, cursor)
        if command_size < 8 or cursor + command_size > commands_end:
            raise MachODependencyRewriteError("invalid Mach-O command size")
        if command in _DYLIB_LOAD_COMMANDS:
            if command_size < 24:
                raise MachODependencyRewriteError("short dylib load command")
            name_offset = struct.unpack_from("<I", payload, cursor + 8)[0]
            if name_offset < 24 or name_offset >= command_size:
                raise MachODependencyRewriteError("invalid dylib name offset")
            start = cursor + name_offset
            end = cursor + command_size
            nul = payload.find(b"\0", start, end)
            if nul < 0:
                raise MachODependencyRewriteError("unterminated dylib dependency name")
            if payload[start:nul] == old_bytes:
                matches.append((start, end))
        cursor += command_size
    if cursor != commands_end:
        raise MachODependencyRewriteError("Mach-O load-command denominator drifted")
    if len(matches) != 1:
        raise MachODependencyRewriteError(
            f"expected one exact dependency {old!r}, found {len(matches)}"
        )

    start, end = matches[0]
    if len(new_bytes) + 1 > end - start:
        raise MachODependencyRewriteError("replacement does not fit the existing command")
    result[start:end] = new_bytes + bytes(end - start - len(new_bytes))
    return bytes(result)


def rewrite_file(path: Path, old: str, new: str) -> None:
    try:
        payload = path.read_bytes()
    except OSError as exc:
        raise MachODependencyRewriteError(f"cannot read {path}: {exc}") from exc
    rewritten = rewrite_dependency(payload, old, new)
    try:
        with path.open("r+b") as handle:
            handle.write(rewritten)
            handle.truncate()
    except OSError as exc:
        raise MachODependencyRewriteError(f"cannot rewrite {path}: {exc}") from exc


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", type=Path)
    parser.add_argument("old")
    parser.add_argument("new")
    arguments = parser.parse_args(argv)
    try:
        rewrite_file(arguments.path, arguments.old, arguments.new)
    except MachODependencyRewriteError as exc:
        parser.exit(2, f"rewrite_macho_dependency: {exc}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
