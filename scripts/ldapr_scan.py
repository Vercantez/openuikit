#!/usr/bin/env python3
"""ldapr_scan.py -- count ARMv8.3-RCpc LDAPR instructions in a Mach-O.

    scripts/ldapr_scan.py <mach-o> [<mach-o>...]
    scripts/ldapr_scan.py --quiet <mach-o>      # exit 1 if any are present

WHY THIS IS NOT A GREP OVER A DISASSEMBLER, and the answer is that a grep over
a disassembler gave the wrong answer and looked right doing it.

valgrind 3.22 does not implement LDAPR, so a guest whose images contain it dies
with SIGILL. Deciding whether scripts/valgrind_guest.sh can be used therefore
depends on counting them. That count was originally taken with

    objdump --macho -d libswiftCore.dylib | grep -c ldapr

which reported 0 -- and 0 is exactly what a clean library reports. It is not
clean. LLVM's objdump CANNOT DECODE LDAPR for this Mach-O; it emits the raw
word instead:

    otool   -tV:  000000000010bc24   ldapr   x20, [x23]
    objdump -d :          10bc24:   .long   0xf8bfc2f4

So `grep ldapr` finds nothing, the instrument fails silently, and its failure
is indistinguishable from success. Two independent methods now agree the real
count for our libswiftCore is 215, not 0: `otool -tV | grep -c` on macOS, and
the encoding scan below. The scan is what this file exists for, because otool
is macOS-only and the decision has to be makeable inside the Linux container.

THE ENCODING, so this is checkable rather than trusted. LDAPR is
`size:2 111000 1 0 1 11111 1100 00 Rn:5 Rt:5`, i.e. the low 10 bits are the
register fields and everything above them is fixed per operand size:

    0xF8BFC000  LDAPR   (64-bit)      0xB8BFC000  LDAPR  (32-bit)
    0x38BFC000  LDAPRB                0x78BFC000  LDAPRH

Verified against a word otool decoded for us: 0xf8bfc2f4 & 0xFFFFFC00 is
0xF8BFC000, and scanning our libswiftCore this way yields 215 -- the same
number otool reports, from a completely different route.

It scans __TEXT,__text only. Data can contain any bit pattern, and counting
those would inflate the number with things the CPU never executes.
"""
import struct
import sys

MASK = 0xFFFFFC00
FORMS = {
    0xF8BFC000: "ldapr",
    0xB8BFC000: "ldapr(w)",
    0x38BFC000: "ldaprb",
    0x78BFC000: "ldaprh",
}

MH_MAGIC_64 = 0xFEEDFACF
FAT_MAGIC = 0xCAFEBABE
LC_SEGMENT_64 = 0x19


def _slices(data):
    """Yield (offset, size) for each arm64 slice; a thin file is one slice."""
    if len(data) < 4:
        return
    if struct.unpack_from(">I", data, 0)[0] == FAT_MAGIC:
        n = struct.unpack_from(">I", data, 4)[0]
        for i in range(n):
            cpu, _sub, off, size, _al = struct.unpack_from(">5I", data, 8 + i * 20)
            if cpu == 0x0100000C:            # CPU_TYPE_ARM64
                yield off, size
        return
    yield 0, len(data)


def text_sections(data, base):
    """(file_offset, size) of every __TEXT,__text in this slice."""
    magic = struct.unpack_from("<I", data, base)[0]
    if magic != MH_MAGIC_64:
        return
    ncmds = struct.unpack_from("<I", data, base + 16)[0]
    p = base + 32
    for _ in range(ncmds):
        cmd, cmdsize = struct.unpack_from("<II", data, p)
        if cmd == LC_SEGMENT_64:
            segname = data[p + 8:p + 24].rstrip(b"\0").decode("ascii", "replace")
            nsects = struct.unpack_from("<I", data, p + 64)[0]
            sp = p + 72
            for _s in range(nsects):
                sectname = data[sp:sp + 16].rstrip(b"\0").decode("ascii", "replace")
                offset, = struct.unpack_from("<I", data, sp + 48)
                size, = struct.unpack_from("<Q", data, sp + 40)
                if segname == "__TEXT" and sectname == "__text":
                    yield base + offset, size
                sp += 80
        p += cmdsize


def scan(path):
    with open(path, "rb") as f:
        data = f.read()
    counts = {}
    scanned = 0
    for off, _size in _slices(data):
        for toff, tsize in text_sections(data, off):
            scanned += tsize
            end = min(toff + tsize, len(data)) - 3
            for i in range(toff, end, 4):
                w = struct.unpack_from("<I", data, i)[0]
                form = FORMS.get(w & MASK)
                if form:
                    counts[form] = counts.get(form, 0) + 1
    return counts, scanned


def main(argv):
    quiet = "--quiet" in argv
    files = [a for a in argv[1:] if not a.startswith("-")]
    if not files:
        print(__doc__.strip().splitlines()[2].strip(), file=sys.stderr)
        return 64
    total = 0
    for path in files:
        try:
            counts, scanned = scan(path)
        except (OSError, struct.error) as e:
            print("ldapr_scan: %s: %s" % (path, e), file=sys.stderr)
            return 66
        n = sum(counts.values())
        total += n
        if not quiet:
            detail = ", ".join("%s=%d" % kv for kv in sorted(counts.items()))
            print("%-52s %5d  %s" % (path, n, detail if detail else "clean"))
    if quiet:
        print(total)
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
