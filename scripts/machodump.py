#!/usr/bin/env python3
"""machodump — the measurement tool behind docs/MACHO_NOTES.md.

Not part of the loader. Its job is to make every number in MACHO_NOTES.md
reproducible, and to give the loader implementation a second opinion to diff
against while bringing up macho.c / fixups_*.c.

    ./scripts/machodump.py [-v] FILE...

Prints load commands, segments/sections, the chained-fixups tables with each
chain decoded, the classic rebase/bind/lazy opcode streams decoded, and the
export trie.  arm64 thin Mach-O only, which is deliberate: fat and arm64e are
out of scope (see docs/PLAN.md III.6f/g) and this tool should say so loudly
rather than half-work.
"""
import struct
import sys

LC_REQ_DYLD = 0x80000000

LC_NAMES = {
    0x01: "LC_SEGMENT",       0x02: "LC_SYMTAB",        0x04: "LC_THREAD",
    0x05: "LC_UNIXTHREAD",    0x0B: "LC_DYSYMTAB",      0x0C: "LC_LOAD_DYLIB",
    0x0D: "LC_ID_DYLIB",      0x0E: "LC_LOAD_DYLINKER", 0x0F: "LC_ID_DYLINKER",
    0x11: "LC_PREBOUND_DYLIB",0x18 | LC_REQ_DYLD: "LC_LOAD_WEAK_DYLIB",
    0x19: "LC_SEGMENT_64",    0x1B: "LC_UUID",          0x1D: "LC_CODE_SIGNATURE",
    0x1E: "LC_SEGMENT_SPLIT_INFO",
    0x1F | LC_REQ_DYLD: "LC_REEXPORT_DYLIB",
    0x1C | LC_REQ_DYLD: "LC_RPATH",
    0x22: "LC_DYLD_INFO",     0x22 | LC_REQ_DYLD: "LC_DYLD_INFO_ONLY",
    0x23 | LC_REQ_DYLD: "LC_LOAD_UPWARD_DYLIB",
    0x24: "LC_VERSION_MIN_MACOSX", 0x25: "LC_VERSION_MIN_IPHONEOS",
    0x26: "LC_FUNCTION_STARTS", 0x28 | LC_REQ_DYLD: "LC_MAIN",
    0x29: "LC_DATA_IN_CODE",  0x2A: "LC_SOURCE_VERSION",
    0x2B: "LC_DYLIB_CODE_SIGN_DRS", 0x2C: "LC_ENCRYPTION_INFO_64",
    0x32: "LC_BUILD_VERSION",
    0x33 | LC_REQ_DYLD: "LC_DYLD_EXPORTS_TRIE",
    0x34 | LC_REQ_DYLD: "LC_DYLD_CHAINED_FIXUPS",
    0x35: "LC_FILESET_ENTRY", 0x36: "LC_ATOM_INFO",
}

DYLIB_CMDS = {0x0C, 0x0D, 0x1F | LC_REQ_DYLD, 0x18 | LC_REQ_DYLD,
              0x23 | LC_REQ_DYLD, 0x1C | LC_REQ_DYLD, 0x0E, 0x0F}

SECT_TYPES = {
    0x0: "S_REGULAR", 0x1: "S_ZEROFILL", 0x2: "S_CSTRING_LITERALS",
    0x5: "S_LITERAL_POINTERS", 0x6: "S_NON_LAZY_SYMBOL_POINTERS",
    0x7: "S_LAZY_SYMBOL_POINTERS", 0x8: "S_SYMBOL_STUBS",
    0x9: "S_MOD_INIT_FUNC_POINTERS", 0xA: "S_MOD_TERM_FUNC_POINTERS",
    0xB: "S_COALESCED", 0x11: "S_THREAD_LOCAL_REGULAR",
    0x12: "S_THREAD_LOCAL_ZEROFILL", 0x13: "S_THREAD_LOCAL_VARIABLES",
    0x14: "S_THREAD_LOCAL_VARIABLE_POINTERS",
    0x15: "S_THREAD_LOCAL_INIT_FUNCTION_POINTERS",
    0x16: "S_INIT_FUNC_OFFSETS",
}

MH_FLAGS = [
    (0x000001, "MH_NOUNDEFS"), (0x000004, "MH_DYLDLINK"),
    (0x000080, "MH_TWOLEVEL"), (0x001000, "MH_BINDS_TO_WEAK"),
    (0x080000, "MH_NO_REEXPORTED_DYLIBS"), (0x200000, "MH_PIE"),
    (0x800000, "MH_HAS_TLV_DESCRIPTORS"),
    (0x2000000, "MH_APPLICATION_EXTENSION"),
]

PTR_FORMATS = {
    1: "ARM64E", 2: "64", 3: "32", 4: "32_CACHE", 5: "32_FIRMWARE",
    6: "64_OFFSET", 7: "ARM64E_KERNEL", 8: "64_KERNEL_CACHE",
    9: "ARM64E_USERLAND", 10: "ARM64E_FIRMWARE", 11: "X86_64_KERNEL_CACHE",
    12: "ARM64E_USERLAND24",
}

SEG_FLAGS = [(0x1, "SG_HIGHVM"), (0x4, "SG_NORELOC"), (0x8, "SG_PROTECTED_VERSION_1"),
             (0x10, "SG_READ_ONLY")]


def uleb(b, p):
    r = s = 0
    while True:
        c = b[p]
        p += 1
        r |= (c & 0x7F) << s
        s += 7
        if not c & 0x80:
            return r, p


def sleb(b, p):
    r = s = 0
    while True:
        c = b[p]
        p += 1
        r |= (c & 0x7F) << s
        s += 7
        if not c & 0x80:
            if c & 0x40:
                r -= 1 << s
            return r, p


def cstr(b, p):
    return b[p:b.index(b"\0", p)].decode("utf-8", "replace")


def flagstr(v, table):
    return "|".join(n for m, n in table if v & m) or "-"


class Image:
    def __init__(self, path):
        self.path = path
        self.d = open(path, "rb").read()
        self.segs = []       # (name, vmaddr, vmsize, fileoff, filesize, initprot, maxprot, flags)
        self.sects = []
        self.dylibs = []     # ordinal order, for lib_ordinal resolution
        self.cf = None
        self.di = None
        self.trie = None
        self.symtab = None
        self.entryoff = None
        self.parse()

    def parse(self):
        d = self.d
        magic, = struct.unpack_from("<I", d, 0)
        if magic in (0xBEBAFECA, 0xCAFEBABE):
            sys.exit(f"{self.path}: fat binary — out of scope (PLAN.md III.6g); "
                     f"use `lipo -thin arm64` first")
        if magic != 0xFEEDFACF:
            sys.exit(f"{self.path}: not a 64-bit little-endian Mach-O (magic {magic:#x})")
        (_, cputype, cpusub, ftype, ncmds, _, flags, _) = struct.unpack_from("<IiiIIIII", d, 0)
        self.cputype, self.cpusub, self.ftype, self.flags = cputype, cpusub, ftype, flags
        print(f"{self.path}")
        print(f"  header: cputype={cputype:#x} cpusubtype={cpusub:#x} filetype={ftype} "
              f"ncmds={ncmds} flags={flags:#x} [{flagstr(flags, MH_FLAGS)}]")
        if cputype != 0x0100000C:
            print(f"  !! not CPU_TYPE_ARM64 — this tool only understands arm64")
        if cpusub & 0xFF == 2:
            print(f"  !! cpusubtype ARM64E — pointer auth, out of scope (PLAN.md III.6f)")

        off = 32
        for _ in range(ncmds):
            cmd, cs = struct.unpack_from("<II", d, off)
            name = LC_NAMES.get(cmd, f"LC_{cmd:#x}")
            if cmd == 0x19:
                self._segment(off, name)
            elif cmd in DYLIB_CMDS:
                o, = struct.unpack_from("<I", d, off + 8)
                s = cstr(d, off + o)
                if cmd in (0x0C, 0x18 | LC_REQ_DYLD, 0x1F | LC_REQ_DYLD, 0x23 | LC_REQ_DYLD):
                    self.dylibs.append(s)
                    print(f"  {name} [ordinal {len(self.dylibs)}] {s}")
                else:
                    print(f"  {name} {s}")
            elif cmd == 0x28 | LC_REQ_DYLD:
                eo, ss = struct.unpack_from("<QQ", d, off + 8)
                self.entryoff = eo
                print(f"  LC_MAIN entryoff={eo:#x} stacksize={ss:#x}")
            elif cmd == 0x05:
                fl, cnt = struct.unpack_from("<II", d, off + 8)
                print(f"  LC_UNIXTHREAD flavor={fl} count={cnt} "
                      f"(dyld-only on arm64 — PLAN.md I.10)")
            elif cmd == 0x34 | LC_REQ_DYLD:
                self.cf = struct.unpack_from("<II", d, off + 8)
                print(f"  LC_DYLD_CHAINED_FIXUPS dataoff={self.cf[0]} datasize={self.cf[1]}")
            elif cmd == 0x33 | LC_REQ_DYLD:
                self.trie = struct.unpack_from("<II", d, off + 8)
                print(f"  LC_DYLD_EXPORTS_TRIE dataoff={self.trie[0]} datasize={self.trie[1]}")
            elif cmd in (0x22, 0x22 | LC_REQ_DYLD):
                f = struct.unpack_from("<10I", d, off + 8)
                self.di = f
                self.trie = (f[8], f[9])
                print(f"  {name} rebase={f[0]}+{f[1]} bind={f[2]}+{f[3]} "
                      f"weak={f[4]}+{f[5]} lazy={f[6]}+{f[7]} export={f[8]}+{f[9]}")
            elif cmd == 0x02:
                self.symtab = struct.unpack_from("<4I", d, off + 8)
                print(f"  LC_SYMTAB symoff={self.symtab[0]} nsyms={self.symtab[1]} "
                      f"stroff={self.symtab[2]} strsize={self.symtab[3]}")
            elif cmd == 0x1D:
                o, s = struct.unpack_from("<II", d, off + 8)
                print(f"  LC_CODE_SIGNATURE dataoff={o} datasize={s}  (ignored on Linux)")
            elif cmd == 0x32:
                pl, mn, sdk, nt = struct.unpack_from("<IIII", d, off + 8)
                print(f"  LC_BUILD_VERSION platform={pl} minos={mn >> 16}.{(mn >> 8) & 0xFF} "
                      f"sdk={sdk >> 16}.{(sdk >> 8) & 0xFF}")
            else:
                print(f"  {name}")
            off += cs

    def _segment(self, off, name):
        d = self.d
        sn = d[off + 8:off + 24].rstrip(b"\0").decode()
        vmaddr, vmsize, fo, fs, mx, ini, nsec, fl = struct.unpack_from("<QQQQiiII", d, off + 24)
        self.segs.append((sn, vmaddr, vmsize, fo, fs, ini, mx, fl))
        warn = ""
        if vmaddr % 0x4000 or fo % 0x4000:
            warn = "  !! NOT 16K-ALIGNED (PLAN.md I.4)"
        print(f"  {name} {sn:14s} vm={vmaddr:#014x}+{vmsize:#x} file={fo}+{fs} "
              f"prot={ini}/{mx} flags={fl:#x}[{flagstr(fl, SEG_FLAGS)}] nsects={nsec}{warn}")
        so = off + 72
        for _ in range(nsec):
            secn = d[so:so + 16].rstrip(b"\0").decode()
            a, sz, o, al, ro, nr, sfl, r1, r2 = struct.unpack_from("<QQIIIIIII", d, so + 32)
            self.sects.append((sn, secn, a, sz, o, sfl, r1, r2))
            t = SECT_TYPES.get(sfl & 0xFF, f"type{sfl & 0xFF:#x}")
            print(f"      {secn:18s} addr={a:#x} size={sz:#x} off={o} "
                  f"align=2^{al} flags={sfl:#010x} [{t}] r1={r1} r2={r2}")
            so += 80


def chained(img):
    d, (base, size) = img.d, img.cf
    (ver, starts_off, imp_off, sym_off, imp_count, imp_fmt,
     sym_fmt) = struct.unpack_from("<7I", d, base)
    print("  --- chained fixups ---")
    print(f"  header: version={ver} starts_offset={starts_off} imports_offset={imp_off} "
          f"symbols_offset={sym_off} imports_count={imp_count} "
          f"imports_format={imp_fmt} symbols_format={sym_fmt}")
    if imp_fmt != 1:
        print(f"  !! imports_format {imp_fmt} not DYLD_CHAINED_IMPORT — loader must abort")

    imports = []
    for k in range(imp_count):
        v, = struct.unpack_from("<I", d, base + imp_off + 4 * k)
        lib, weak, noff = v & 0xFF, (v >> 8) & 1, v >> 9
        nm = cstr(d, base + sym_off + noff)
        tgt = img.dylibs[lib - 1] if 1 <= lib <= len(img.dylibs) else f"special({lib:#x})"
        imports.append((lib, weak, nm, tgt))

    so = base + starts_off
    nseg, = struct.unpack_from("<I", d, so)
    offs = struct.unpack_from(f"<{nseg}I", d, so + 4)
    print(f"  starts_in_image: seg_count={nseg} seg_info_offset={list(offs)}")
    for i, o2 in enumerate(offs):
        if o2 == 0:
            continue
        p = so + o2
        ssz, ps, fmt, seg_off, maxp, pcount = struct.unpack_from("<IHHQIH", d, p)
        pstarts = struct.unpack_from(f"<{pcount}H", d, p + 22)
        fn = PTR_FORMATS.get(fmt, "?")
        print(f"   seg[{i}] {img.segs[i][0]}: size={ssz} page_size={ps:#x} "
              f"pointer_format={fmt} (DYLD_CHAINED_PTR_{fn}) segment_offset={seg_off:#x} "
              f"max_valid_pointer={maxp} page_count={pcount} page_start={list(pstarts)}")
        if fmt not in (2, 6):
            print(f"   !! pointer_format {fmt} unsupported by the planned loader")
            continue
        sfo = img.segs[i][3]
        sva = img.segs[i][1]
        for pi, st in enumerate(pstarts):
            if st == 0xFFFF:
                continue
            if st & 0x8000:
                print(f"      page {pi}: START_MULTI ({st:#x}) — not handled")
                continue
            cur = sfo + pi * ps + st
            va = sva + pi * ps + st
            n = 0
            while True:
                raw, = struct.unpack_from("<Q", d, cur)
                bind = (raw >> 63) & 1
                nxt = (raw >> 51) & 0xFFF
                if bind:
                    ordn = raw & 0xFFFFFF
                    addend = (raw >> 24) & 0xFF
                    lib, weak, nm, tgt = imports[ordn] if ordn < len(imports) else (0, 0, "?", "?")
                    print(f"      @{va:#x} raw={raw:#018x} BIND   ord={ordn} addend={addend} "
                          f"next={nxt}  -> {nm} (from {tgt}){' WEAK' if weak else ''}")
                else:
                    target = raw & 0xFFFFFFFFF
                    high8 = (raw >> 36) & 0xFF
                    kind = "imageoff" if fmt == 6 else "vmaddr"
                    print(f"      @{va:#x} raw={raw:#018x} REBASE {kind}={target:#x} "
                          f"high8={high8:#x} next={nxt}")
                n += 1
                if nxt == 0:
                    break
                cur += nxt * 4
                va += nxt * 4
                if n > 100000:
                    print("      !! runaway chain"); break

    for k, (lib, weak, nm, tgt) in enumerate(imports):
        print(f"   import[{k}]: lib_ordinal={lib} ({tgt}) weak={weak} {nm}")


REB_OPS = {0x00: "DONE", 0x10: "SET_TYPE_IMM", 0x20: "SET_SEGMENT_AND_OFFSET_ULEB",
           0x30: "ADD_ADDR_ULEB", 0x40: "ADD_ADDR_IMM_SCALED",
           0x50: "DO_REBASE_IMM_TIMES", 0x60: "DO_REBASE_ULEB_TIMES",
           0x70: "DO_REBASE_ADD_ADDR_ULEB", 0x80: "DO_REBASE_ULEB_TIMES_SKIPPING_ULEB"}

BIND_OPS = {0x00: "DONE", 0x10: "SET_DYLIB_ORDINAL_IMM", 0x20: "SET_DYLIB_ORDINAL_ULEB",
            0x30: "SET_DYLIB_SPECIAL_IMM", 0x40: "SET_SYMBOL_TRAILING_FLAGS_IMM",
            0x50: "SET_TYPE_IMM", 0x60: "SET_ADDEND_SLEB",
            0x70: "SET_SEGMENT_AND_OFFSET_ULEB", 0x80: "ADD_ADDR_ULEB",
            0x90: "DO_BIND", 0xA0: "DO_BIND_ADD_ADDR_ULEB",
            0xB0: "DO_BIND_ADD_ADDR_IMM_SCALED", 0xC0: "DO_BIND_ULEB_TIMES_SKIPPING_ULEB",
            0xD0: "THREADED"}


def opcodes(img, label, off, size, ops, has_symbols):
    if size == 0:
        return
    d = img.d
    print(f"  --- {label} stream @{off}+{size} ---")
    print(f"    raw: {d[off:off + size].hex(' ')}")
    p, end = off, off + size
    while p < end:
        b = d[p]
        op, imm = b & 0xF0, b & 0x0F
        nm = ops.get(op, f"{op:#x}")
        p += 1
        args = ""
        if op in (0x20, 0x70) and ops is REB_OPS or op == 0x20 and ops is BIND_OPS:
            v, p = uleb(d, p)
            args = f"seg={imm} offset={v:#x}"
        elif ops is BIND_OPS and op == 0x70:
            v, p = uleb(d, p)
            args = f"seg={imm} offset={v:#x}"
        elif op == 0x40 and has_symbols:
            s = cstr(d, p)
            p += len(s.encode()) + 1
            args = f"flags={imm:#x} '{s}'"
        elif op in (0x30, 0x80) or (ops is BIND_OPS and op in (0x20,)):
            v, p = uleb(d, p)
            args = f"uleb={v:#x}"
        elif ops is BIND_OPS and op == 0x60:
            v, p = sleb(d, p)
            args = f"sleb={v}"
        elif ops is REB_OPS and op in (0x60, 0x70):
            v, p = uleb(d, p)
            args = f"uleb={v:#x}"
        elif op in (0xA0,) and ops is BIND_OPS:
            v, p = uleb(d, p)
            args = f"uleb={v:#x}"
        elif op == 0x80 and ops is REB_OPS:
            a, p = uleb(d, p)
            bq, p = uleb(d, p)
            args = f"count={a} skip={bq:#x}"
        elif op == 0xC0 and ops is BIND_OPS:
            a, p = uleb(d, p)
            bq, p = uleb(d, p)
            args = f"count={a} skip={bq:#x}"
        else:
            args = f"imm={imm}"
        print(f"    {b:#04x}  {nm} {args}")
        if op == 0x00:
            # A rebase/bind stream ends at DONE; a lazy stream is a sequence of
            # DONE-terminated mini-programs, so keep going until the tail is all
            # zero padding.
            if all(c == 0 for c in d[p:end]):
                if p < end:
                    print(f"    ({end - p} bytes of zero padding)")
                break


def export_trie(img):
    if not img.trie or img.trie[1] == 0:
        return
    base, size = img.trie
    d = img.d
    print(f"  --- export trie @{base}+{size} ---")
    print(f"    raw: {d[base:base + size].hex(' ')}")

    def walk(p, prefix, depth):
        term, q = uleb(d, p)
        if term:
            r = q
            flags, r = uleb(d, r)
            if flags & 0x08:      # REEXPORT
                ordn, r = uleb(d, r)
                nm = cstr(d, r)
                print(f"    {'  ' * depth}TERM {prefix!r} REEXPORT ordinal={ordn} as={nm!r}")
            elif flags & 0x10:    # STUB_AND_RESOLVER
                stub, r = uleb(d, r)
                res, r = uleb(d, r)
                print(f"    {'  ' * depth}TERM {prefix!r} STUB={stub:#x} RESOLVER={res:#x}")
            else:
                addr, r = uleb(d, r)
                print(f"    {'  ' * depth}TERM {prefix!r} flags={flags:#x} "
                      f"imageoff={addr:#x}")
        q += term
        n = d[q]
        q += 1
        for _ in range(n):
            s = cstr(d, q)
            q += len(s.encode()) + 1
            child, q = uleb(d, q)
            walk(base + child, prefix + s, depth + 1)

    walk(base, "", 0)


def main(argv):
    if not argv:
        sys.exit(__doc__)
    for path in argv:
        img = Image(path)
        if img.cf:
            chained(img)
        if img.di:
            f = img.di
            opcodes(img, "rebase", f[0], f[1], REB_OPS, False)
            opcodes(img, "bind", f[2], f[3], BIND_OPS, True)
            opcodes(img, "weak bind", f[4], f[5], BIND_OPS, True)
            opcodes(img, "lazy bind", f[6], f[7], BIND_OPS, True)
        export_trie(img)
        print()


if __name__ == "__main__":
    main(sys.argv[1:])
