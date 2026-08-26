#!/usr/bin/env python3
"""Survey isa/data mask usage across a set of arm64 Mach-O binaries.

Answers "do Apple's shipped dylibs carry the narrow mask?" as a measurement
rather than an assumption. Reuses widen_isa_mask.py's decoder and dataflow
classifier so the survey and the rewriter cannot disagree.

    survey_isa_masks.py <binary> [<binary> ...]
"""
import struct, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from widen_isa_mask import parse, is_and_imm, classify, fn_start_index, \
                           NARROW_IMMS, WIDE_IMMS


def survey(path):
    raw = open(path, 'rb').read()
    if struct.unpack_from('<I', raw, 0)[0] != 0xfeedfacf:
        return None
    if struct.unpack_from('<i', raw, 4)[0] != 0x0100000c:
        return None
    (addr, size, fo), syms = parse(raw)
    code = list(struct.unpack_from(f'<{size//4}I', raw, fo))
    wide = isa = data = unk = 0
    for i, insn in enumerate(code):
        if is_and_imm(insn, WIDE_IMMS):
            wide += 1
        elif is_and_imm(insn, NARROW_IMMS):
            kind, _ = classify(code, i, fn_start_index(syms, addr, addr + i*4))
            if kind == 'ISA':
                isa += 1
            elif kind == 'DATA_BITS':
                data += 1
            else:
                unk += 1
    return wide, isa, data, unk


def main():
    print(f'{"binary":<44} {"wide":>6} {"narrowISA":>10} {"narrowDATA":>11} {"unclass":>8}')
    print('-' * 84)
    for p in sys.argv[1:]:
        r = survey(p)
        name = os.path.basename(p)
        if r is None:
            print(f'{name:<44} {"(not arm64 thin Mach-O)":>38}')
            continue
        wide, isa, data, unk = r
        flag = '  <-- narrow isa sites' if isa else ''
        print(f'{name:<44} {wide:>6} {isa:>10} {data:>11} {unk:>8}{flag}')


if __name__ == '__main__':
    main()
