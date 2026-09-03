#!/usr/bin/env python3
"""Drop the LC_LOAD_DYLIB that ld64.lld 18-20 emits beside every LC_REEXPORT_DYLIB.

ld64.lld (release/18.x through 20.x, lld/MachO/Writer.cpp createLoadCommands)
assigns ONE dylib ordinal per DylibFile but emits TWO load commands for a
re-exported dylib: LC_LOAD_DYLIB followed by LC_REEXPORT_DYLIB. dyld and
machorun number ordinals by load-command position, so every bind past the
first re-exported dylib points one library off. Measured on the x86_64 box
2026-09-03 linking libswiftDarwin with Apple's four shells: Bool metadata
`_$sSbN` (defined only in libswiftCore, per-file ordinal 8) was attributed to
libswift_DarwinFoundation2 (load command 8) and machorun refused. lld main
emits only LC_REEXPORT_DYLIB (lcType = LC_REEXPORT_DYLIB); ld64 always did.

This edit removes each LC_LOAD_DYLIB whose install name also appears as an
LC_REEXPORT_DYLIB. Load commands live in the header region ahead of the
first section, so removing one shifts only the later load commands within
that region; ncmds/sizeofcmds shrink and the freed tail is zeroed. Nothing
else in the file (offsets, binds, exports) changes — exactly the bounded
diff the caller verifies with otool -L / objdump --bind afterwards.

usage: dedupe_reexport_loads.py <macho> [--check]
  --check   exit 3 if duplicates exist, 0 if none; never writes
exit 0 (deduped or nothing to do), 2 on a malformed file
"""
from __future__ import annotations

import struct
import sys

MH_MAGIC_64 = 0xFEEDFACF
LC_LOAD_DYLIB = 0x0C
LC_LOAD_WEAK_DYLIB = 0x80000018
LC_REEXPORT_DYLIB = 0x8000001F


def load_commands(data: bytes):
    magic, _cpu, _sub, _ft, ncmds, sizeofcmds, _flags, _res = struct.unpack_from(
        "<IiiIIIII", data, 0
    )
    if magic != MH_MAGIC_64:
        raise ValueError("not a 64-bit little-endian Mach-O")
    off = 32
    cmds = []
    for _ in range(ncmds):
        cmd, cmdsize = struct.unpack_from("<II", data, off)
        if cmdsize < 8 or off + cmdsize > 32 + sizeofcmds:
            raise ValueError("load command overruns sizeofcmds")
        cmds.append((off, cmd, cmdsize))
        off += cmdsize
    return ncmds, sizeofcmds, cmds


def dylib_name(data: bytes, off: int, cmdsize: int) -> str:
    name_off = struct.unpack_from("<I", data, off + 8)[0]
    raw = data[off + name_off : off + cmdsize]
    return raw.split(b"\0", 1)[0].decode("utf-8", "replace")


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(__doc__, file=sys.stderr)
        return 2
    path = argv[1]
    check = "--check" in argv[2:]
    data = bytearray(open(path, "rb").read())
    try:
        ncmds, sizeofcmds, cmds = load_commands(data)
    except (ValueError, struct.error) as e:
        print(f"dedupe_reexport_loads: {path}: {e}", file=sys.stderr)
        return 2
    reexported = {
        dylib_name(data, off, sz) for off, cmd, sz in cmds if cmd == LC_REEXPORT_DYLIB
    }
    doomed = [
        (off, cmd, sz)
        for off, cmd, sz in cmds
        if cmd in (LC_LOAD_DYLIB, LC_LOAD_WEAK_DYLIB)
        and dylib_name(data, off, sz) in reexported
    ]
    if not doomed:
        print(f"dedupe_reexport_loads: {path}: no LC_LOAD_DYLIB duplicates a re-export")
        return 0
    names = ", ".join(dylib_name(data, o, s) for o, _, s in doomed)
    if check:
        print(f"dedupe_reexport_loads: {path}: DUPLICATE load commands for {names}")
        return 3
    # Rebuild the load-command region without the doomed commands.
    keep = bytearray()
    for off, cmd, sz in cmds:
        if (off, cmd, sz) in doomed:
            continue
        keep += data[off : off + sz]
    region_end = 32 + sizeofcmds
    new_size = len(keep)
    data[32 : 32 + new_size] = keep
    data[32 + new_size : region_end] = b"\0" * (region_end - 32 - new_size)
    struct.pack_into("<II", data, 16, ncmds - len(doomed), new_size)
    open(path, "wb").write(data)
    print(
        f"dedupe_reexport_loads: {path}: removed {len(doomed)} LC_LOAD_DYLIB "
        f"({names}); ncmds {ncmds}->{ncmds - len(doomed)} sizeofcmds {sizeofcmds}->{new_size}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
