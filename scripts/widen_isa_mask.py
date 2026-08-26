#!/usr/bin/env python3
"""Widen libswiftCore's hardcoded Objective-C isa mask to match machorun's objc4.

THE BUG
-------
machorun patches objc4's isa layout because the host is Linux, whose user
addresses are 48 bits wide (machorun patches-macho/0001-wide-va-isa-layout.patch):

    ISA_MASK  0x007ffffffffffff8      bits 3..54   (machorun objc4)

Swift hardcodes Apple's macOS/arm64 value instead — SWIFT_ABI_ARM64_OBJC_ISA_MASK
in include/swift/ABI/System.h — and bakes it into 48 AND-immediate instructions:

    ISA_MASK  0x00007ffffffffff8      bits 3..46   (libswiftCore)

machorun maps guest images above 2^47, so masking a class pointer with Swift's
narrower mask strips bit 47:

    0x0000fe3de57774b8  ->  0x00007e3de57774b8

which is not a class, and the very next instruction dereferences it. That is
the fault at swift_unknownObjectRelease+0x10 (`ldrb w9, [x8, #0x20]`).

Only the *unknownObject* retain/release family reads the isa — swift_retain and
swift_release never do. That is exactly why plain classes work and non-class-
bound existentials / AnyObject fault.

THE FIX
-------
Proper fix is to rebuild with SWIFT_ABI_ARM64_OBJC_ISA_MASK widened to
0x007ffffffffffff8 (patch 6 in scripts/apply_patches.py). This script is the
same change applied in place, so an existing dylib can be unblocked without a
rebuild machine.

Both masks are contiguous runs of ones starting at bit 3, so both encode as
AArch64 64-bit logical immediates with N=1, immr=61, differing only in imms:

    0x00007ffffffffff8  = 44 ones  -> imms = 43
    0x007ffffffffffffff8= 52 ones  -> imms = 51

so the edit is 6 bits per instruction and the instruction length is unchanged.
"""
import struct, sys, shutil

OLD_MASK = 0x00007ffffffffff8
NEW_MASK = 0x007ffffffffffff8
OLD_IMMS, NEW_IMMS = 43, 51
IMMR = 61

def segments(d):
    ncmds = struct.unpack_from('<I', d, 16)[0]
    off = 32
    for _ in range(ncmds):
        cmd, cmdsize = struct.unpack_from('<2I', d, off)
        if cmd == 0x19:  # LC_SEGMENT_64
            segname = d[off+8:off+24].rstrip(b'\0').decode()
            nsects = struct.unpack_from('<I', d, off+64)[0]
            so = off + 72
            for _i in range(nsects):
                sect = d[so:so+16].rstrip(b'\0').decode()
                addr, size = struct.unpack_from('<2Q', d, so+32)
                fo = struct.unpack_from('<I', d, so+48)[0]
                yield segname, sect, addr, size, fo
                so += 80
        off += cmdsize

def main(src, dst):
    shutil.copyfile(src, dst)
    d = bytearray(open(dst, 'rb').read())

    text = [s for s in segments(bytes(d)) if s[0] == '__TEXT' and s[1] == '__text']
    if not text:
        sys.exit('no __TEXT,__text')
    _, _, addr, size, fo = text[0]

    patched_insns = 0
    for i in range(0, size, 4):
        insn = struct.unpack_from('<I', d, fo + i)[0]
        # 64-bit logical-immediate ops that take the isa mask, by bits 31..23:
        #   AND  0x124      ANDS 0x1e4 (the flags-setting form, used where the
        #                   runtime masks and tests for null in one instruction)
        if (insn >> 23) not in (0x124, 0x1e4):
            continue
        if ((insn >> 22) & 1) != 1:            # N
            continue
        if ((insn >> 16) & 0x3f) != IMMR:      # immr
            continue
        if ((insn >> 10) & 0x3f) != OLD_IMMS:  # imms
            continue
        new = (insn & ~(0x3f << 10)) | (NEW_IMMS << 10)
        struct.pack_into('<I', d, fo + i, new)
        patched_insns += 1

    # The writable _swift_isaMask global, and any other data word holding the
    # narrow mask, so anything reading it agrees with the code.
    patched_data = 0
    old_b, new_b = struct.pack('<Q', OLD_MASK), struct.pack('<Q', NEW_MASK)
    for seg, sect, addr, size, fo in segments(bytes(d)):
        if seg not in ('__DATA', '__DATA_CONST'):
            continue
        for i in range(0, max(0, size - 8), 8):
            if d[fo+i:fo+i+8] == old_b:
                d[fo+i:fo+i+8] = new_b
                patched_data += 1

    open(dst, 'wb').write(d)
    print(f'{dst}\n  AND-immediate sites widened: {patched_insns}\n  data words widened:          {patched_data}')

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
