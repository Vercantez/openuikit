#!/usr/bin/env python3
"""Widen the Objective-C *isa* mask in any staged arm64 Mach-O.

    widen_isa_mask.py <in.dylib> <out.dylib> [--manifest out.json] [--dry-run]
                      [--allow-unclassified]

WHY
---
machorun runs a Darwin userland inside a Linux address space, so it selects
objc4's wide isa layout (machorun patches-macho/0001-wide-va-isa-layout.patch):

    ISA_MASK 0x007ffffffffffff8    bits 3..54

A Swift runtime built for arm64-apple-*macos* instead bakes Apple's device mask
into every isa read:

    ISA_MASK 0x00007ffffffffff8    bits 3..46   (a 2^47 user-VA ceiling)

machorun maps guests above 2^47, so the narrow mask strips bit 47 off class
pointers and the next dereference faults. Both masks are contiguous runs of ones
from bit 3, so both encode as AArch64 64-bit logical immediates with N=1,
immr=61, differing only in imms (43 vs 51): a six-bit, same-length rewrite.

THE TRAP THIS TOOL EXISTS TO AVOID
----------------------------------
The isa mask is NOT the only constant with that value. objc4's DEBUG_DATA_MASK
is *also* 0x00007ffffffffff8 on non-device targets, and it masks a completely
different field — class_data_bits_t at offset 0x20 of an objc_class, yielding a
class_rw_t*. Widening those sites is silent corruption.

Measured on Apple's shipped arm64 libswiftCore (iOS 26.1 simruntime): 48 isa
sites (already wide, because a simulator build follows the ARM64e scheme) and
**9 narrow sites that are data-bits masks, not isa masks**, all inside
_swift_initClassMetadataImpl / _swift_updateClassMetadataImpl. An
immediate-only rewriter would corrupt exactly those 9.

So this tool classifies every candidate by DATAFLOW before touching it:

    ldr Xs, [Xb]          -> ISA         (offset 0 is the isa field)   REWRITE
    ldr Xs, [Xb, #0x20]   -> DATA_BITS   (objc_class::bits)            REFUSE
    anything else         -> UNCLASSIFIED                              REFUSE

and refuses to write at all if anything is UNCLASSIFIED, unless you pass
--allow-unclassified having looked at the report.

It is idempotent: an already-wide binary reports zero ISA rewrites and is
byte-identical on output.
"""
import argparse, hashlib, json, struct, sys

NARROW = 0x00007ffffffffff8   # bits 3..46 — Apple device / macOS
WIDE   = 0x007ffffffffffff8   # bits 3..54 — ARM64e / simulator / machorun
IMMR, NARROW_IMMS, WIDE_IMMS = 61, 43, 51


# ---------------------------------------------------------------- Mach-O ----
def parse(d):
    magic = struct.unpack_from('<I', d, 0)[0]
    if magic != 0xfeedfacf:
        sys.exit(f'not a 64-bit little-endian Mach-O (magic {magic:#x}); '
                 'fat/arm64e binaries must be thinned first')
    cputype = struct.unpack_from('<i', d, 4)[0]
    if cputype != 0x0100000c:
        sys.exit(f'not arm64 (cputype {cputype:#x})')
    ncmds = struct.unpack_from('<I', d, 16)[0]
    off, text, syms = 32, None, []
    for _ in range(ncmds):
        cmd, cmdsize = struct.unpack_from('<2I', d, off)
        if cmd == 0x19:  # LC_SEGMENT_64
            seg = d[off+8:off+24].rstrip(b'\0').decode()
            nsects = struct.unpack_from('<I', d, off+64)[0]
            so = off + 72
            for _i in range(nsects):
                sect = d[so:so+16].rstrip(b'\0').decode()
                addr, size = struct.unpack_from('<2Q', d, so+32)
                fo = struct.unpack_from('<I', d, so+48)[0]
                if seg == '__TEXT' and sect == '__text':
                    text = (addr, size, fo)
                so += 80
        elif cmd == 0x2:  # LC_SYMTAB
            symoff, nsyms, stroff, strsize = struct.unpack_from('<4I', d, off+8)
            strs = d[stroff:stroff+strsize]
            for i in range(nsyms):
                n_strx, n_type, n_sect, n_desc, n_value = \
                    struct.unpack_from('<IBBHQ', d, symoff + i*16)
                if n_type & 0x0e != 0x0e or not n_value:   # N_SECT only
                    continue
                end = strs.find(b'\0', n_strx)
                syms.append((n_value, strs[n_strx:end].decode('utf-8', 'replace')))
        off += cmdsize
    if text is None:
        sys.exit('no __TEXT,__text')
    syms.sort()
    return text, syms


def fn_start_index(syms, text_addr, va):
    """Instruction index of the start of the function containing va."""
    lo, hi = 0, len(syms)
    while lo < hi:
        mid = (lo + hi) // 2
        if syms[mid][0] <= va:
            lo = mid + 1
        else:
            hi = mid
    start = syms[lo-1][0] if lo else text_addr
    return (start - text_addr) // 4


def symbolize(syms, va):
    lo, hi = 0, len(syms)
    while lo < hi:
        mid = (lo + hi) // 2
        if syms[mid][0] <= va:
            lo = mid + 1
        else:
            hi = mid
    return syms[lo-1][1] if lo else '?'


# --------------------------------------------------------------- decoding ---
def is_and_imm(insn, imms):
    """AND (0x124) or ANDS (0x1e4) immediate, 64-bit, N=1, immr=IMMR, given imms."""
    return ((insn >> 23) in (0x124, 0x1e4)
            and (insn >> 22) & 1 == 1
            and (insn >> 16) & 0x3f == IMMR
            and (insn >> 10) & 0x3f == imms)


def classify(code, idx, fn_start):
    """Classify by the NEAREST PRECEDING load that defines this AND's source.

    LDR (immediate, unsigned offset), 64-bit: bits 31..22 == 0b1111100101,
    imm12 scaled by 8. Offset 0 is objc_object::isa; offset 0x20 is
    objc_class::bits.

    A fixed instruction window is not enough: the runtime keeps the isa in a
    callee-saved register across calls, so -[_TtCs12_SwiftObject hash] masks a
    value loaded fourteen instructions earlier. Scanning back to the start of
    the containing function and taking the first defining load handles both
    that and the tight `ldr; and` form Apple's data-bits sites use.
    """
    rn = (code[idx] >> 5) & 0x1f
    for j in range(idx - 1, max(fn_start, 0) - 1, -1):
        prev = code[j]
        if (prev >> 22) != 0b1111100101:      # not LDR imm, 64-bit
            continue
        if (prev & 0x1f) != rn:               # not writing our source register
            continue
        off = ((prev >> 10) & 0xfff) * 8
        if off == 0:
            return 'ISA', off
        if off == 0x20:
            return 'DATA_BITS', off
        return 'UNCLASSIFIED', off
    return 'UNCLASSIFIED', None


# ------------------------------------------------------------------- main ---
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('src'); ap.add_argument('dst')
    ap.add_argument('--manifest')
    ap.add_argument('--dry-run', action='store_true')
    ap.add_argument('--allow-unclassified', action='store_true')
    a = ap.parse_args()

    raw = open(a.src, 'rb').read()
    (addr, size, fo), syms = parse(raw)
    d = bytearray(raw)
    n = size // 4
    code = list(struct.unpack_from(f'<{n}I', d, fo))

    sites, already_wide = [], []
    for i, insn in enumerate(code):
        va = addr + i*4
        if is_and_imm(insn, WIDE_IMMS):
            already_wide.append(va)
            continue
        if not is_and_imm(insn, NARROW_IMMS):
            continue
        kind, off = classify(code, i, fn_start_index(syms, addr, va))
        sites.append({'vmaddr': hex(va), 'kind': kind,
                      'src_offset': (hex(off) if off is not None else None),
                      'function': symbolize(syms, va)})

    kinds = {}
    for s in sites:
        kinds[s['kind']] = kinds.get(s['kind'], 0) + 1

    print(f'{a.src}')
    print(f'  narrow candidates : {len(sites)}')
    for k in ('ISA', 'DATA_BITS', 'UNCLASSIFIED'):
        if kinds.get(k):
            print(f'    {k:<14}: {kinds[k]}')
    print(f'  already wide      : {len(already_wide)}')

    for s in sites:
        if s['kind'] != 'ISA':
            print(f"  !! {s['kind']} at {s['vmaddr']} src=[x,{s['src_offset']}] "
                  f"in {s['function'][:70]}")

    if kinds.get('UNCLASSIFIED') and not a.allow_unclassified:
        sys.exit('\nREFUSING TO WRITE: unclassified mask sites above. Inspect them, '
                 'then re-run with --allow-unclassified if they really are isa reads.')

    if not sites and already_wide:
        print('  -> already widened; nothing to do (idempotent no-op)')

    patched = [s for s in sites if s['kind'] == 'ISA']
    for s in patched:
        i = (int(s['vmaddr'], 16) - addr) // 4
        struct.pack_into('<I', d, fo + i*4,
                         (code[i] & ~(0x3f << 10)) | (WIDE_IMMS << 10))

    # The writable _swift_isaMask global and any other data word holding it.
    data_words = 0
    ob, nb = struct.pack('<Q', NARROW), struct.pack('<Q', WIDE)
    off, ncmds = 32, struct.unpack_from('<I', raw, 16)[0]
    for _ in range(ncmds):
        cmd, cmdsize = struct.unpack_from('<2I', raw, off)
        if cmd == 0x19:
            seg = raw[off+8:off+24].rstrip(b'\0').decode()
            if seg in ('__DATA', '__DATA_CONST'):
                nsects = struct.unpack_from('<I', raw, off+64)[0]
                so = off + 72
                for _i in range(nsects):
                    ssize = struct.unpack_from('<Q', raw, so+40)[0]
                    sfo = struct.unpack_from('<I', raw, so+48)[0]
                    for k in range(0, max(0, ssize - 8), 8):
                        if d[sfo+k:sfo+k+8] == ob:
                            d[sfo+k:sfo+k+8] = nb
                            data_words += 1
                    so += 80
        off += cmdsize

    print(f'  -> ISA sites widened: {len(patched)}   data words widened: {data_words}')

    if a.dry_run:
        print('  (dry run; nothing written)')
        return

    open(a.dst, 'wb').write(d)
    man = {
        'tool': 'widen_isa_mask.py',
        'source': a.src, 'output': a.dst,
        'narrow_mask': hex(NARROW), 'wide_mask': hex(WIDE),
        'sha256_before': hashlib.sha256(raw).hexdigest(),
        'sha256_after': hashlib.sha256(bytes(d)).hexdigest(),
        'isa_sites_widened': len(patched),
        'data_words_widened': data_words,
        'already_wide_sites': len(already_wide),
        'refused': [s for s in sites if s['kind'] != 'ISA'],
        'sites': patched,
        'note': 'Widened binaries encode a 48-bit host VA and are machorun-specific.',
    }
    if a.manifest:
        json.dump(man, open(a.manifest, 'w'), indent=2)
        print(f'  manifest: {a.manifest}')


if __name__ == '__main__':
    main()
