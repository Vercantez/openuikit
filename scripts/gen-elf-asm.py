#!/usr/bin/env python3
"""
Translate objc4's Mach-O assembly into ELF/GAS dialect.

This is a SCRIPT rather than a forked .s file on purpose: objc-msg-arm64.s is
868 lines of load-bearing dispatch code that Apple changes between releases.
A fork would silently rot; a translator either still applies to the next drop
or fails loudly.

Everything it does is a *dialect* transform. It does not change a single
instruction, register, offset or branch. Run it, then diff the output against
the input to review.

WHAT IS TRANSLATED (all measured against clang 18's integrated assembler,
aarch64-unknown-linux-gnu):

  symbols     Mach-O prefixes C symbols with '_'; ELF does not.
              `_objc_msgSend` -> `objc_msgSend`, `__objc_msgNil` -> `_objc_msgNil`.
  labels      Mach-O assembler-local labels start with 'L'; ELF uses '.L'.
  macros      Apple's `as` takes positional args `$0`; GAS/LLVM-ELF needs
              named parameters. `.endmacro` -> `.endm`.
  sections    `.section __SEG,__sect,...` -> the ELF section that clang emits
              for the same content (measured in docs/PORT_MAP.md 3.2: the rule
              is "strip the leading __", and cstrings land in .rodata.str1.1).
  addressing  `sym@PAGE` / `sym@PAGEOFF` -> `sym` / `:lo12:sym`.
  visibility  `.private_extern X` -> `.globl X` + `.hidden X`.
              `.alt_entry X` -> dropped (ELF allows aliases at one address).
              `.subsections_via_symbols` -> dropped (no ELF analogue).
  alignment   `.align N` -> `.p2align N` (Mach-O's .align is log2; GAS's
              meaning is target-dependent, so make it explicit).
  unwind      Mach-O `__LD,__compact_unwind` -> `.cfi_startproc/.cfi_endproc`.
              SEE THE CAVEAT BELOW.

WHAT IS **NOT** TRANSLATED -- read this before trusting the output:

  1. CFI inside SAVE_REGS/RESTORE_REGS. Those macros move SP and spill
     registers. The emitted .cfi_startproc/.cfi_endproc give a correct frame
     ONLY for the `NoFrame` functions (objc_msgSend and friends, which never
     touch SP). Unwinding out of _objc_msgSend_uncached mid-frame will produce
     a wrong CFA. Fixing this needs .cfi_def_cfa_offset/.cfi_offset inside
     those macros, by hand. Recorded in docs/UNIMPLEMENTED.md.
  2. objc_restartableRanges. The table is emitted so objc-cache.mm links, but
     cache GC is off in this port, so nothing reads it.
  3. GOT indirection. Every symbol the messenger references is defined inside
     libobjc.so and is hidden, so adrp/add reaches it directly with no PLT.
     If a referenced symbol ever becomes preemptible this must become
     :got:/:got_lo12:, and the failure mode is a link error, not silence.
"""

import re
import sys

# Mach-O prefixes every C symbol with one '_'; ELF does not. So `_foo` (C
# `foo`) loses one, and `__foo` (C `_foo`) loses one too.
# Section names like __TEXT/__DATA also start with '__', but .section lines are
# handled and returned before this ever runs.
LEADING_UNDERSCORE = re.compile(r'(?<![A-Za-z0-9_.$\\])_([A-Za-z_][A-Za-z0-9_]*)')

# Assembler-local labels: Mach-O 'L...', ELF '.L...'
LOCAL_LABEL = re.compile(r'(?<![A-Za-z0-9_.$\\])(L[A-Za-z0-9_$.]+)')

# ...but only if the token contains a lowercase letter. Everything L-prefixed
# in objc4's assembly that is NOT a label is all-caps: the AArch64 operand
# keywords LSL/LSR/LR, and the C macros LOOKUP, LOOKUP_INITIALIZE,
# LOOKUP_RESOLVER, LOW_4, LP64. Every real local label (LExit, LLookupStart,
# LCacheMiss, LNilOrTagged, ...) is mixed case. Both halves of that claim were
# checked against the source; `grep -ohE '\\bL[A-Za-z0-9_$]+'` over
# objc-msg-arm64.s and arm64-asm.h lists them all.
HAS_LOWER = re.compile(r'[a-z]')

# Headers that are themselves assembly and get translated alongside the .s.
TRANSLATED_HEADERS = {'arm64-asm'}

# Symbols that are (a) defined in this assembly, (b) exported for debuggers,
# and (c) addressed from the same file with adrp/add.
#
# On Mach-O that combination is fine. On ELF a .globl symbol is PREEMPTIBLE by
# default -- another shared object could define it -- so the linker refuses:
#
#   relocation R_AARCH64_ADR_PREL_PG_HI21 against symbol
#   `objc_debug_taggedpointer_classes' which may bind externally can not be
#   used when making a shared object
#
# STV_PROTECTED is exactly the semantics we want: still exported, but always
# resolves to this object's definition, so PC-relative addressing is legal.
# .hidden would work too but would stop lldb/gdb from finding these, and they
# exist only for lldb/gdb.
PROTECTED_SYMBOLS = {
    'objc_debug_taggedpointer_classes',
    'objc_debug_taggedpointer_ext_classes',
    'objc_indexed_classes',
    'MagicSelRef',
}

SECTION_MAP = {
    # Mach-O section spec (normalised, whitespace-collapsed) -> ELF directive.
    '__TEXT,__objc_methname,cstring_literals':
        '.section .rodata.str1.1,"aMS",@progbits,1',
    '__DATA,__objc_selrefs,literal_pointers,no_dead_strip':
        '.section objc_selrefs,"aw",@progbits',
    '__TEXT,__const':
        '.section .rodata,"a",@progbits',
    '__DATA,__const':
        '.section .data.rel.ro,"aw",@progbits',
    '__DATA_CONST,__objc_scoffs':
        '.section objc_scoffs,"aw",@progbits',
    # Mach-O compact unwind has no ELF analogue at all -- ELF uses DWARF CFI
    # in .eh_frame. Sites are inside `#if !TARGET_OS_LINUX` branches (dead on
    # this target) but the translator is line-based, so map it to a comment.
    '__LD,__compact_unwind,regular,debug':
        '// [elf] __LD,__compact_unwind has no ELF analogue; see CFI_START',
}


def translate(src: str) -> str:
    out = []
    in_block_comment = False
    for line in src.split('\n'):
        if in_block_comment:
            out.append(line)
            if '*/' in line:
                in_block_comment = False
            continue
        if '/*' in line and '*/' not in line[line.index('/*'):]:
            in_block_comment = True
        out.append(translate_line(line))
    return '\n'.join(out)


def split_comment(line):
    """Return (code, comment). Only // and /* */ starting a comment region."""
    idx = len(line)
    for marker in ('//', '/*'):
        p = line.find(marker)
        if p != -1:
            idx = min(idx, p)
    return line[:idx], line[idx:]


def translate_line(line: str) -> str:
    stripped = line.strip()

    # Preprocessor lines pass through untouched: they are C, not asm, and the
    # identifiers in them (SUPPORT_INDEXED_ISA, __LP64__, ...) are macros.
    # The one exception is an #include of another file we translate: the
    # translated .s must see the translated header, or its `.L`-prefixed
    # references will not match the header's `L`-prefixed definitions
    # (e.g. LTailCallCachedImpIndirectBranch, defined inside TailCallCachedImp
    # in arm64-asm.h and referenced by _objc_msgSend_indirect_branch).
    if stripped.startswith('#'):
        return re.sub(r'#(\s*)include(\s+)"([A-Za-z0-9_.-]+)\.h"',
                      lambda m: '#%sinclude%s"%s-elf.h"' % (m.group(1), m.group(2), m.group(3))
                      if m.group(3) in TRANSLATED_HEADERS else m.group(0),
                      line)

    code, comment = split_comment(line)
    c = code

    # ---- directives ----------------------------------------------------
    m = re.match(r'^(\s*)\.section\s+(.*)$', c)
    if m:
        indent, spec = m.group(1), re.sub(r'\s+', '', m.group(2))
        if spec in SECTION_MAP:
            return indent + SECTION_MAP[spec] + comment
        raise SystemExit('gen-elf-asm: unmapped section %r (line: %s)' % (spec, line))

    if re.match(r'^\s*\.subsections_via_symbols\b', c):
        return '\t// [elf] .subsections_via_symbols: no ELF analogue, dropped'

    m = re.match(r'^(\s*)\.alt_entry\s+(\S+)\s*$', c)
    if m:
        return '%s// [elf] .alt_entry %s: ELF allows aliases at one address' % (
            m.group(1), m.group(2))

    m = re.match(r'^(\s*)\.private_extern\s+(\S+)\s*$', c)
    if m:
        indent, sym = m.group(1), fix_symbol(m.group(2))
        return '%s.globl %s\n%s.hidden %s%s' % (indent, sym, indent, sym, comment)

    m = re.match(r'^(\s*)\.globl\s+(\S+)\s*$', c)
    if m:
        indent, sym = m.group(1), fix_symbol(m.group(2))
        if sym in PROTECTED_SYMBOLS:
            return '%s.globl %s\n%s.protected %s%s' % (indent, sym, indent, sym, comment)
        return '%s.globl %s%s' % (indent, sym, comment)

    m = re.match(r'^(\s*)\.align\s+(\d+)\s*$', c)
    if m:
        return '%s.p2align %s%s' % (m.group(1), m.group(2), comment)

    c = re.sub(r'\.endmacro\b', '.endm', c)

    # ---- addressing ----------------------------------------------------
    c = re.sub(r'([A-Za-z0-9_.$]+)@PAGEOFF\b', r':lo12:\1', c)
    c = re.sub(r'([A-Za-z0-9_.$]+)@PAGE\b', r'\1', c)

    # ---- symbols and labels -------------------------------------------
    c = LOCAL_LABEL.sub(_label_sub, c)
    c = LEADING_UNDERSCORE.sub(r'\1', c)

    return c + comment


def _label_sub(m):
    tok = m.group(1)
    return '.' + tok if HAS_LOWER.search(tok) else tok


def fix_symbol(s: str) -> str:
    s = LOCAL_LABEL.sub(_label_sub, s)
    return LEADING_UNDERSCORE.sub(r'\1', s)


def main():
    if len(sys.argv) != 3:
        sys.exit('usage: gen-elf-asm.py <in.s|in.h> <out.s|out.h>')
    src = open(sys.argv[1]).read()
    banner = (
        '// GENERATED by scripts/gen-elf-asm.py from %s -- do not edit.\n'
        '// Mach-O -> ELF/GAS dialect only; no instruction was changed.\n'
        '// Read the script\'s docstring for what is NOT translated.\n\n'
        % sys.argv[1].split('/')[-1])
    open(sys.argv[2], 'w').write(banner + translate(src))


if __name__ == '__main__':
    main()
