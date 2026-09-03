#!/usr/bin/env python3
"""Rewrite a thin 64-bit Mach-O into dyld-shared-cache layout.

Extracted cache dylibs (ipsw dyld extract) keep the CACHE's packing: data
segments are placed contiguously, so a segment's vmaddr and fileoff need not
be page-aligned and the delta from __TEXT to __DATA_CONST can be huge.
Apple's dsc_extractor.bundle, which would rebuild standalone dylibs, SIGBUSes
on macOS 26.5.2 caches. This rewriter produces the same shape from a normal
Apple-built dylib so machorun can test the copy-map path without touching
Apple's binary.

It never executes the guest. It rewrites load commands, section headers,
LINKEDIT offsets, chained-fixup starts, export-trie image offsets, nlist
n_value, ARM64 ADRP/LDR/ADD page immediates, and (format-6) rebase targets,
then packs file bytes tightly.

    scripts/pack_macho.py pack IN.dylib -o OUT.dylib [--id INSTALL_NAME]
                                                [--sparse | --gap N]
    scripts/pack_macho.py rename IN -o OUT --from STR --to STR
    scripts/pack_macho.py oversize IN -o OUT [--segment NAME]
    scripts/pack_macho.py strip-fixups IN.dylib -o OUT.dylib [--id INSTALL_NAME]
    scripts/pack_macho.py inspect FILE
    scripts/pack_macho.py --selftest
"""
from __future__ import annotations

import argparse
import os
import struct
import sys
from typing import Callable

MH_MAGIC_64 = 0xFEEDFACF
LC_REQ_DYLD = 0x80000000
LC_SEGMENT_64 = 0x19
LC_SYMTAB = 0x02
LC_DYSYMTAB = 0x0B
LC_LOAD_DYLIB = 0x0C
LC_ID_DYLIB = 0x0D
LC_LOAD_WEAK_DYLIB = 0x18 | LC_REQ_DYLD
LC_RPATH = 0x1C | LC_REQ_DYLD
LC_REEXPORT_DYLIB = 0x1F | LC_REQ_DYLD
LC_DYLD_INFO = 0x22
LC_DYLD_INFO_ONLY = 0x22 | LC_REQ_DYLD
LC_FUNCTION_STARTS = 0x26
LC_DATA_IN_CODE = 0x29
LC_CODE_SIGNATURE = 0x1D
LC_DYLIB_CODE_SIGN_DRS = 0x2B
LC_DYLD_EXPORTS_TRIE = 0x33 | LC_REQ_DYLD
LC_DYLD_CHAINED_FIXUPS = 0x34 | LC_REQ_DYLD
LC_SEGMENT_SPLIT_INFO = 0x1E
LC_ATOM_INFO = 0x36

S_ZEROFILL = 0x1
S_THREAD_LOCAL_ZEROFILL = 0x12

# Matches the operator's 2026-09-03 wall: libswiftObjectiveC __DATA_CONST
# vmaddr ...7720, i.e. 0x720 into a 4 KiB page. CACHE_GAP (0x10000) is a
# small stand-in for packed-contiguous cache data; CACHE_SPARSE_DELTA is
# the measured TEXT-to-DATA gap on that extract (cache-wide addresses,
# not a packed file).
CACHE_UNALIGN = 0x720
CACHE_GAP = 0x10000
CACHE_SPARSE_DELTA = 0x22256720  # DATA_CONST.vmaddr - TEXT.vmaddr
HOST_PAGE = 4096


def uleb_decode(buf: bytes | bytearray, p: int) -> tuple[int, int]:
    r = s = 0
    while True:
        if p >= len(buf):
            raise ValueError("uleb overruns buffer")
        c = buf[p]
        p += 1
        r |= (c & 0x7F) << s
        s += 7
        if not c & 0x80:
            return r, p


def uleb_encode(value: int, width: int | None = None) -> bytes:
    out = bytearray()
    v = value
    while True:
        b = v & 0x7F
        v >>= 7
        if v:
            out.append(b | 0x80)
        else:
            out.append(b)
            break
    if width is None:
        return bytes(out)
    if len(out) > width:
        raise ValueError(
            f"uleb {value:#x} needs {len(out)} bytes, only {width} available"
        )
    if len(out) < width:
        out[-1] |= 0x80
        while len(out) < width - 1:
            out.append(0x80)
        out.append(0x00)
    return bytes(out)


def aligned(n: int, page: int = HOST_PAGE) -> bool:
    return (n & (page - 1)) == 0


class Segment:
    def __init__(self, lc_off: int, name: str, vmaddr: int, vmsize: int,
                 fileoff: int, filesize: int, maxprot: int, initprot: int,
                 nsects: int, flags: int, sects: list):
        self.lc_off = lc_off
        self.name = name
        self.vmaddr = vmaddr
        self.vmsize = vmsize
        self.fileoff = fileoff
        self.filesize = filesize
        self.maxprot = maxprot
        self.initprot = initprot
        self.nsects = nsects
        self.flags = flags
        self.sects = sects  # list of dicts
        self.new_vmaddr = vmaddr
        self.new_vmsize = vmsize
        self.new_fileoff = fileoff
        self.new_filesize = filesize

    @property
    def vm_delta(self) -> int:
        return self.new_vmaddr - self.vmaddr


class Image:
    def __init__(self, data: bytes):
        if len(data) < 32:
            raise ValueError("too small to be Mach-O")
        magic, = struct.unpack_from("<I", data, 0)
        if magic != MH_MAGIC_64:
            raise ValueError(f"not a thin little-endian 64-bit Mach-O (magic {magic:#x})")
        self.data = bytearray(data)
        (self.cputype, self.cpusub, self.ftype, self.ncmds,
         self.sizeofcmds, self.flags) = struct.unpack_from("<iiIIII", data, 4)
        self.segs: list[Segment] = []
        self.cmd_offs: list[tuple[int, int, int]] = []  # (off, cmd, cmdsize)
        self._parse()

    def _parse(self) -> None:
        off = 32
        for _ in range(self.ncmds):
            cmd, cs = struct.unpack_from("<II", self.data, off)
            if cs < 8 or off + cs > len(self.data):
                raise ValueError(f"malformed load command at {off}")
            self.cmd_offs.append((off, cmd, cs))
            if cmd == LC_SEGMENT_64:
                self._parse_segment(off)
            off += cs

    def _parse_segment(self, off: int) -> None:
        name = self.data[off + 8:off + 24].split(b"\0", 1)[0].decode("ascii", "replace")
        vmaddr, vmsize, fo, fs, mx, ini, nsec, fl = struct.unpack_from(
            "<QQQQiiII", self.data, off + 24)
        sects = []
        so = off + 72
        for _ in range(nsec):
            sn = self.data[so:so + 16].split(b"\0", 1)[0].decode("ascii", "replace")
            addr, size, soff, align, reloff, nreloc, sfl, r1, r2, r3 = struct.unpack_from(
                "<QQIIIIIIII", self.data, so + 32)
            sects.append({
                "lc_off": so, "name": sn, "addr": addr, "size": size,
                "offset": soff, "align": align, "reloff": reloff, "nreloc": nreloc,
                "flags": sfl, "r1": r1, "r2": r2, "r3": r3,
            })
            so += 80
        self.segs.append(Segment(off, name, vmaddr, vmsize, fo, fs, mx, ini, nsec, fl, sects))

    def find_cmd(self, which: int) -> list[tuple[int, int]]:
        return [(o, cs) for o, c, cs in self.cmd_offs if c == which]

    def preferred_base(self) -> int:
        for s in self.segs:
            if s.name == "__TEXT":
                return s.vmaddr
        raise ValueError("no __TEXT")

    def used_in_segment(self, seg: Segment) -> int:
        """Bytes of the segment that actually carry file content (not page padding)."""
        used = 0
        if seg.name == "__TEXT":
            used = 32 + self.sizeofcmds
        for sec in seg.sects:
            if (sec["flags"] & 0xFF) in (S_ZEROFILL, S_THREAD_LOCAL_ZEROFILL):
                continue
            if sec["size"] == 0:
                continue
            used = max(used, sec["addr"] + sec["size"] - seg.vmaddr)
            if sec["offset"] >= seg.fileoff:
                used = max(used, sec["offset"] + sec["size"] - seg.fileoff)
        if used == 0:
            used = seg.filesize
        if seg.filesize and used > seg.filesize:
            used = seg.filesize
        return used


def plan_pack(img: Image, unalign: int = CACHE_UNALIGN, gap: int = CACHE_GAP,
              sparse: bool = False) -> None:
    """Pack non-__TEXT/__PAGEZERO segments like a dyld shared cache slice.

    __TEXT keeps its vmaddr (the mach header is the lowest mapped byte). Its
    filesize shrinks to the used prefix so the next segment's fileoff is not
    page-aligned. Subsequent segments are placed at
        round_up(text.vmaddr + text.vmsize, 1) + gap + unalign
    and then packed against each other with no page rounding, so they share
    host pages and their vmaddrs are not page-aligned.

    `--sparse` sets the first data vmaddr to text.vmaddr + CACHE_SPARSE_DELTA
    (0x22256720: libswiftObjectiveC __DATA_CONST - __TEXT, measured
    2026-09-03). File bytes stay packed; only the VM gap is huge.
    """
    text = next((s for s in img.segs if s.name == "__TEXT"), None)
    if text is None:
        raise ValueError("no __TEXT")
    text.new_vmaddr = text.vmaddr
    text.new_vmsize = text.vmsize  # keep page-sized so it does not share with DATA
    text_used = img.used_in_segment(text)
    text.new_filesize = text_used
    text.new_fileoff = 0 if text.fileoff == 0 else text.fileoff

    if sparse:
        gap = CACHE_SPARSE_DELTA - text.vmsize - unalign
        if gap < 0:
            raise ValueError(
                f"CACHE_SPARSE_DELTA {CACHE_SPARSE_DELTA:#x} is smaller than "
                f"TEXT.vmsize {text.vmsize:#x} + unalign {unalign:#x}"
            )

    cursor_vm = text.vmaddr + text.vmsize + gap + unalign
    cursor_file = text.new_fileoff + text.new_filesize

    for seg in img.segs:
        if seg.name in ("__PAGEZERO", "__TEXT"):
            continue
        used = img.used_in_segment(seg)
        if used == 0:
            used = max(seg.filesize, 1) if seg.vmsize else 0
        seg.new_vmaddr = cursor_vm
        seg.new_fileoff = cursor_file
        seg.new_filesize = used if seg.filesize else 0
        # vmsize covers the used file bytes; zerofill tails stay inside vmsize
        # if the original vmsize was larger than filesize -- but for packing we
        # want DATA_CONST and DATA to share a page, so we take the used size
        # and any zerofill that the original placed immediately after.
        zfill = 0
        if seg.vmsize > seg.filesize and seg.filesize:
            # Keep a small zerofill tail (the original BSS) but do not keep
            # the page-padding that made vmsize 0x4000.
            zfill = min(seg.vmsize - seg.filesize, 0x40)
        seg.new_vmsize = max(seg.new_filesize + zfill, used if used else 0)
        if seg.new_vmsize == 0:
            seg.new_vmsize = 1
        cursor_vm = seg.new_vmaddr + seg.new_vmsize
        cursor_file = seg.new_fileoff + seg.new_filesize


def reloc_vm(img: Image, addr: int) -> int:
    """Map an old vmaddr (or image offset from preferred_base) through the plan."""
    base = img.preferred_base()
    # Try as a vmaddr first, then as an image offset.
    for seg in img.segs:
        if seg.vmaddr <= addr < seg.vmaddr + max(seg.vmsize, 1):
            return addr + seg.vm_delta
    abs_addr = base + addr
    for seg in img.segs:
        if seg.vmaddr <= abs_addr < seg.vmaddr + max(seg.vmsize, 1):
            return (abs_addr + seg.vm_delta) - base
    return addr


S_ATTR_PURE_INSTRUCTIONS = 0x80000000


def decode_adrp(insn: int, pc: int) -> tuple[int, int] | None:
    if (insn & 0x9F000000) != 0x90000000:
        return None
    rd = insn & 31
    immlo = (insn >> 29) & 3
    immhi = (insn >> 5) & 0x7FFFF
    imm = (immhi << 2) | immlo
    if imm & (1 << 20):
        imm -= 1 << 21
    return rd, (pc & ~0xFFF) + (imm << 12)


def encode_adrp(rd: int, pc: int, target_page: int) -> int:
    imm = (target_page - (pc & ~0xFFF)) >> 12
    if imm < -(1 << 20) or imm >= (1 << 20):
        raise ValueError(f"ADRP immediate {imm} out of range")
    immlo = imm & 3
    immhi = (imm >> 2) & 0x7FFFF
    return 0x90000000 | ((immlo & 3) << 29) | (immhi << 5) | (rd & 31)


def decode_ldst_uoff(insn: int) -> tuple[int, int, int] | None:
    """Unsigned-offset LDR/STR. Returns (rt, rn, byte_offset) or None."""
    if (insn & 0x3B000000) != 0x39000000:
        return None
    size = insn >> 30
    imm12 = (insn >> 10) & 0xFFF
    rn = (insn >> 5) & 31
    rt = insn & 31
    return rt, rn, imm12 << size


def encode_ldst_uoff(insn: int, new_off: int) -> int:
    size = insn >> 30
    scale = 1 << size
    if new_off % scale:
        raise ValueError(f"LDR/STR offset {new_off:#x} not aligned to {scale}")
    imm12 = new_off // scale
    if imm12 > 0xFFF:
        raise ValueError(f"LDR/STR offset {new_off:#x} exceeds unsigned12")
    return (insn & ~(0xFFF << 10)) | (imm12 << 10)


def decode_add_imm(insn: int) -> tuple[int, int, int] | None:
    """64-bit ADD Xd, Xn, #imm12 (shift 0)."""
    if (insn & 0xFF800000) != 0x91000000:
        return None
    imm12 = (insn >> 10) & 0xFFF
    rn = (insn >> 5) & 31
    rd = insn & 31
    return rd, rn, imm12


def encode_add_imm(insn: int, new_imm: int) -> int:
    if new_imm > 0xFFF:
        raise ValueError(f"ADD immediate {new_imm:#x} exceeds 12 bits")
    return (insn & ~(0xFFF << 10)) | (new_imm << 10)


def patch_arm64_page_relocs(img: Image) -> int:
    """Rewrite ADRP+LDR/STR/ADD pairs whose page moved with the packed layout.

    ld64 bakes the GOT/DATA page into the instruction stream. Moving
    DATA_CONST from 0x4000 to 0x14720 without this leaves
        ADRP x16, #0x4000; LDR x16, [x16, #8]
    in __stubs, which is the 2026-09-03 packed-fixture SIGSEGV: pc at the
    LDR, fault at slide+0x4008, while the GOT lives at +0x14720 and the
    gap is PROT_NONE. Real cache extracts already have ADRP matching the
    packed vmaddrs; this exists so the fixture does too.
    """
    n = 0
    for seg in img.segs:
        for sec in seg.sects:
            if not (sec["flags"] & S_ATTR_PURE_INSTRUCTIONS):
                continue
            if sec["size"] < 8 or sec["offset"] == 0:
                continue
            start = sec["offset"]
            size = sec["size"] & ~3
            i = 0
            while i + 4 <= size:
                pc = sec["addr"] + i
                p = start + i
                insn = struct.unpack_from("<I", img.data, p)[0]
                adrp = decode_adrp(insn, pc)
                i += 4
                if adrp is None:
                    continue
                rd, old_page = adrp
                new_page = None
                j = 0
                while j < 32 and i + j + 4 <= size:
                    q = start + i + j
                    follow = struct.unpack_from("<I", img.data, q)[0]
                    ldst = decode_ldst_uoff(follow)
                    add = decode_add_imm(follow)
                    old_ea = None
                    if ldst is not None and ldst[1] == rd:
                        old_ea = old_page + ldst[2]
                    elif add is not None and add[1] == rd:
                        old_ea = old_page + add[2]
                    if old_ea is not None:
                        new_ea = reloc_vm(img, old_ea)
                        if new_ea != old_ea:
                            want_page = new_ea & ~0xFFF
                            if new_page is None:
                                new_page = want_page
                            elif new_page != want_page:
                                raise ValueError(
                                    f"ADRP x{rd} at {pc:#x} uses split pages "
                                    f"{new_page:#x} and {want_page:#x}"
                                )
                            new_off = new_ea - new_page
                            if ldst is not None:
                                struct.pack_into("<I", img.data, q,
                                                 encode_ldst_uoff(follow, new_off))
                            else:
                                struct.pack_into("<I", img.data, q,
                                                 encode_add_imm(follow, new_off))
                            n += 1
                    j += 4
                    # Stop at another ADRP that redefines this register.
                    nxt = decode_adrp(follow, sec["addr"] + i + j - 4)
                    if nxt is not None and nxt[0] == rd:
                        break
                if new_page is not None and new_page != old_page:
                    struct.pack_into("<I", img.data, p,
                                     encode_adrp(rd, pc, new_page))
                    n += 1
    return n


def patch_nlists(img: Image) -> None:
    for off, cs in img.find_cmd(LC_SYMTAB):
        symoff, nsyms, stroff, strsize = struct.unpack_from("<IIII", img.data, off + 8)
        for i in range(nsyms):
            p = symoff + i * 16
            n_strx, n_type, n_sect, n_desc, n_value = struct.unpack_from("<IBBHQ", img.data, p)
            if n_sect == 0 or n_value == 0:
                continue
            new = reloc_vm(img, n_value)
            if new != n_value:
                struct.pack_into("<Q", img.data, p + 8, new)


class TrieNode:
    __slots__ = ("flags", "value", "extra", "children")

    def __init__(self) -> None:
        self.flags: int | None = None
        self.value: int = 0
        self.extra: bytes = b""  # terminal bytes after flags[+value]
        self.children: list[tuple[bytes, TrieNode]] = []


def parse_export_trie(buf: bytes | bytearray, trie_off: int, trie_size: int) -> TrieNode:
    end = trie_off + trie_size

    def walk(node_off: int, depth: int) -> TrieNode:
        node = TrieNode()
        if depth > 128 or node_off >= trie_size:
            return node
        p = trie_off + node_off
        term_size, q = uleb_decode(buf, p)
        t = q
        children = q + term_size
        if term_size > 0:
            flags, t = uleb_decode(buf, t)
            node.flags = flags
            if not (flags & 0x08) and not (flags & 0x10):
                value, t = uleb_decode(buf, t)
                node.value = value
                node.extra = bytes(buf[t:q + term_size])
            else:
                node.extra = bytes(buf[t:q + term_size])
        if children >= end:
            return node
        nchild = buf[children]
        p = children + 1
        for _ in range(nchild):
            start = p
            while p < end and buf[p]:
                p += 1
            edge = bytes(buf[start:p])
            p += 1
            coff, p = uleb_decode(buf, p)
            node.children.append((edge, walk(coff, depth + 1)))
        return node

    return walk(0, 0)


def reloc_export_trie(img: Image, node: TrieNode) -> None:
    if node.flags is not None and not (node.flags & 0x08) and not (node.flags & 0x10):
        node.value = reloc_vm(img, node.value)
    for _, child in node.children:
        reloc_export_trie(img, child)


def encode_export_trie(root: TrieNode) -> bytes:
    """Lay out the trie in DFS order; iterate until child-offset ULEBs stabilize."""
    offsets: dict[int, int] = {}

    def encode_one(node: TrieNode) -> bytes:
        term = bytearray()
        if node.flags is not None:
            term += uleb_encode(node.flags)
            if not (node.flags & 0x08) and not (node.flags & 0x10):
                term += uleb_encode(node.value)
            term += node.extra
        out = bytearray(uleb_encode(len(term)))
        out += term
        out.append(len(node.children))
        for edge, child in node.children:
            out += edge + b"\0"
            out += uleb_encode(offsets.get(id(child), 0))
        return bytes(out)

    blob = b""
    for _ in range(16):
        new_off: dict[int, int] = {}
        parts: list[bytes] = []

        def place(node: TrieNode) -> None:
            b = encode_one(node)
            new_off[id(node)] = sum(len(p) for p in parts)
            parts.append(b)
            for _, child in node.children:
                place(child)

        place(root)
        blob = b"".join(parts)
        if new_off == offsets:
            break
        offsets = new_off
    else:
        raise ValueError("export trie layout did not converge")
    return blob


def set_export_trie_loc(img: Image, old_off: int, new_off: int, new_size: int) -> None:
    for off, cs in img.find_cmd(LC_DYLD_EXPORTS_TRIE):
        o, s = struct.unpack_from("<II", img.data, off + 8)
        if o == old_off:
            struct.pack_into("<II", img.data, off + 8, new_off, new_size)
    for off, cs in img.find_cmd(LC_DYLD_INFO) + img.find_cmd(LC_DYLD_INFO_ONLY):
        fields = list(struct.unpack_from("<10I", img.data, off + 8))
        if fields[8] == old_off:
            fields[8] = new_off
            fields[9] = new_size
            struct.pack_into("<10I", img.data, off + 8, *fields)


def _patch_export_trie_inplace(img: Image, trie_off: int, trie_size: int) -> None:
    """Overwrite export addresses in-place, keeping each ULEB's original width."""
    buf = img.data

    def walk(node_off: int, depth: int = 0) -> None:
        if depth > 128 or node_off >= trie_size:
            return
        p = trie_off + node_off
        term_size, q = uleb_decode(buf, p)
        t = q
        children = q + term_size
        if term_size > 0:
            flags, t = uleb_decode(buf, t)
            if not (flags & 0x08) and not (flags & 0x10):  # not REEXPORT / STUB_AND_RESOLVER
                val_start = t
                value, val_end = uleb_decode(buf, t)
                width = val_end - val_start
                new = reloc_vm(img, value)
                if new != value:
                    enc = uleb_encode(new, width)
                    buf[val_start:val_end] = enc
        if children >= trie_off + trie_size:
            return
        nchild = buf[children]
        p = children + 1
        for _ in range(nchild):
            while p < trie_off + trie_size and buf[p]:
                p += 1
            p += 1  # NUL
            coff, p = uleb_decode(buf, p)
            walk(coff, depth + 1)

    walk(0)


def patch_export_trie(img: Image, trie_off: int, trie_size: int) -> None:
    """Relocate regular export addresses.

    Packed layout keeps each ULEB's original width so the committed packed
    dylib stays bit-identical. Sparse packing moves DATA to +0x22256720 and
    `_greet_counter` no longer fits in 3 bytes: rebuild the trie and append
    it to __LINKEDIT.
    """
    if trie_size == 0:
        return
    try:
        _patch_export_trie_inplace(img, trie_off, trie_size)
        return
    except ValueError:
        pass

    root = parse_export_trie(img.data, trie_off, trie_size)
    reloc_export_trie(img, root)
    blob = encode_export_trie(root)

    le = next((s for s in img.segs if s.name == "__LINKEDIT"), None)
    if le is None:
        raise ValueError("export trie grew and there is no __LINKEDIT to hold it")
    insert_at = le.fileoff + le.filesize
    if insert_at < len(img.data):
        raise ValueError(
            f"__LINKEDIT is not at EOF (ends {insert_at}, file {len(img.data)}); "
            "refusing to grow the export trie"
        )
    if insert_at > len(img.data):
        img.data.extend(bytes(insert_at - len(img.data)))
    img.data.extend(blob)
    extra = len(blob)
    le.filesize += extra
    le.new_filesize += extra
    if le.new_vmsize < le.new_filesize:
        le.new_vmsize = le.new_filesize
    set_export_trie_loc(img, trie_off, insert_at, extra)


def patch_chained(img: Image) -> None:
    found = img.find_cmd(LC_DYLD_CHAINED_FIXUPS)
    if not found:
        return
    off, _ = found[0]
    dataoff, datasize = struct.unpack_from("<II", img.data, off + 8)
    if datasize < 28:
        return
    (ver, starts_off, imp_off, sym_off, imp_count, imp_fmt,
     sym_fmt) = struct.unpack_from("<7I", img.data, dataoff)
    if ver != 0:
        return
    base = img.preferred_base()
    so = dataoff + starts_off
    nseg, = struct.unpack_from("<I", img.data, so)
    offs = struct.unpack_from(f"<{nseg}I", img.data, so + 4)
    for i, o2 in enumerate(offs):
        if o2 == 0:
            continue
        p = so + o2
        ssz, ps, fmt, seg_off, maxp, pcount = struct.unpack_from("<IHHQIH", img.data, p)
        if i >= len(img.segs):
            continue
        seg = img.segs[i]
        new_seg_off = seg.new_vmaddr - base
        if new_seg_off != seg_off:
            struct.pack_into("<Q", img.data, p + 8, new_seg_off)
        if fmt not in (2, 6):
            continue
        pstarts = struct.unpack_from(f"<{pcount}H", img.data, p + 22)
        for pi, st in enumerate(pstarts):
            if st == 0xFFFF or st & 0x8000:
                continue
            cur = seg.fileoff + pi * ps + st
            n = 0
            while True:
                if cur + 8 > len(img.data):
                    break
                raw, = struct.unpack_from("<Q", img.data, cur)
                bind = (raw >> 63) & 1
                nxt = (raw >> 51) & 0xFFF
                if not bind and fmt == 6:
                    target = raw & 0xFFFFFFFFF
                    high_and_rest = raw & ~0xFFFFFFFFF
                    new = reloc_vm(img, target)
                    if new != target:
                        if new > 0xFFFFFFFFF:
                            raise ValueError(f"rebase target {new:#x} exceeds 36 bits")
                        struct.pack_into("<Q", img.data, cur, high_and_rest | new)
                n += 1
                if nxt == 0 or n > 100000:
                    break
                cur += nxt * 4


def patch_linkedit_offs(img: Image, delta: Callable[[int], int]) -> None:
    """Shift file offsets that live inside LINKEDIT (and similar) load commands."""
    def patch_pair(off: int, field_off: int = 8) -> None:
        o, s = struct.unpack_from("<II", img.data, off + field_off)
        if o:
            struct.pack_into("<II", img.data, off + field_off, delta(o), s)

    for off, cmd, cs in img.cmd_offs:
        if cmd in (LC_DYLD_CHAINED_FIXUPS, LC_DYLD_EXPORTS_TRIE, LC_FUNCTION_STARTS,
                   LC_DATA_IN_CODE, LC_CODE_SIGNATURE, LC_SEGMENT_SPLIT_INFO,
                   LC_DYLIB_CODE_SIGN_DRS, LC_ATOM_INFO):
            patch_pair(off)
        elif cmd in (LC_DYLD_INFO, LC_DYLD_INFO_ONLY):
            fields = list(struct.unpack_from("<10I", img.data, off + 8))
            for i in range(0, 10, 2):
                if fields[i]:
                    fields[i] = delta(fields[i])
            struct.pack_into("<10I", img.data, off + 8, *fields)
        elif cmd == LC_SYMTAB:
            symoff, nsyms, stroff, strsize = struct.unpack_from("<IIII", img.data, off + 8)
            struct.pack_into("<IIII", img.data, off + 8,
                             delta(symoff) if symoff else 0, nsyms,
                             delta(stroff) if stroff else 0, strsize)
        elif cmd == LC_DYSYMTAB:
            fields = list(struct.unpack_from("<18I", img.data, off + 8))
            # file-offset fields: tocoff(6), nmodtab skip, extrefsymoff(10),
            # indirectsymoff(12), extreloff(14), locreloff(16)
            for idx in (6, 10, 12, 14, 16):
                if fields[idx]:
                    fields[idx] = delta(fields[idx])
            struct.pack_into("<18I", img.data, off + 8, *fields)


def patch_segment_headers(img: Image) -> None:
    for seg in img.segs:
        struct.pack_into("<QQQQ", img.data, seg.lc_off + 24,
                         seg.new_vmaddr, seg.new_vmsize, seg.new_fileoff, seg.new_filesize)
        for sec in seg.sects:
            new_addr = sec["addr"] + seg.vm_delta
            new_off = 0
            if sec["offset"] and not ((sec["flags"] & 0xFF) in (S_ZEROFILL, S_THREAD_LOCAL_ZEROFILL)):
                new_off = sec["offset"] - seg.fileoff + seg.new_fileoff
            struct.pack_into("<QQI", img.data, sec["lc_off"] + 32, new_addr, sec["size"], new_off)


def rebuild_file(img: Image) -> bytes:
    """Concatenate packed segment file bytes; load commands already patched in img.data."""
    end = 0
    parts: list[tuple[int, bytes]] = []
    for seg in img.segs:
        if seg.new_filesize == 0:
            continue
        blob = bytes(img.data[seg.fileoff:seg.fileoff + seg.new_filesize])
        if len(blob) < seg.new_filesize:
            blob = blob + bytes(seg.new_filesize - len(blob))
        parts.append((seg.new_fileoff, blob))
        end = max(end, seg.new_fileoff + seg.new_filesize)
    out = bytearray(end)
    for fo, blob in parts:
        out[fo:fo + len(blob)] = blob
    return bytes(out)


def set_lc_string(data: bytearray, old: str, new: str) -> int:
    """Replace old with new in LC_ID_DYLIB / LC_LOAD_* / LC_RPATH strings. Returns count."""
    n = 0
    magic, = struct.unpack_from("<I", data, 0)
    if magic != MH_MAGIC_64:
        raise ValueError("not a thin 64-bit Mach-O")
    ncmds, sizeofcmds = struct.unpack_from("<II", data, 16)
    off = 32
    old_b = old.encode("ascii")
    new_b = new.encode("ascii")
    dylib_cmds = {LC_LOAD_DYLIB, LC_ID_DYLIB, LC_LOAD_WEAK_DYLIB, LC_REEXPORT_DYLIB, LC_RPATH}
    for _ in range(ncmds):
        cmd, cs = struct.unpack_from("<II", data, off)
        if cmd in dylib_cmds:
            name_off, = struct.unpack_from("<I", data, off + 8)
            room = cs - name_off
            cur = data[off + name_off:off + cs].split(b"\0", 1)[0]
            if cur == old_b:
                if len(new_b) + 1 > room:
                    raise ValueError(
                        f"cannot fit {new!r} ({len(new_b)+1} bytes) into cmdsize room {room}"
                    )
                pad = bytes(room)
                repl = new_b + b"\0"
                data[off + name_off:off + cs] = (repl + pad)[:room]
                n += 1
        off += cs
    return n


def pack_bytes(data: bytes, install_name: str | None = None,
               unalign: int = CACHE_UNALIGN, gap: int = CACHE_GAP,
               sparse: bool = False) -> bytes:
    img = Image(data)
    plan_pack(img, unalign=unalign, gap=gap, sparse=sparse)

    # ADRP immediates live in TEXT at the old file offsets. Patch them
    # before rebuild_file copies the used TEXT prefix out.
    patch_arm64_page_relocs(img)

    # Patch LINKEDIT blobs and chained pointers while they still sit at old fileoffs.
    patch_chained(img)
    patch_nlists(img)
    for off, cs in img.find_cmd(LC_DYLD_EXPORTS_TRIE):
        o, s = struct.unpack_from("<II", img.data, off + 8)
        patch_export_trie(img, o, s)
    for off, cs in img.find_cmd(LC_DYLD_INFO) + img.find_cmd(LC_DYLD_INFO_ONLY):
        fields = struct.unpack_from("<10I", img.data, off + 8)
        patch_export_trie(img, fields[8], fields[9])

    def file_delta(old_off: int) -> int:
        for seg in img.segs:
            if seg.filesize and seg.fileoff <= old_off < seg.fileoff + seg.filesize:
                return old_off - seg.fileoff + seg.new_fileoff
        return old_off

    patch_linkedit_offs(img, file_delta)
    patch_segment_headers(img)
    if install_name is not None:
        # Replace whatever LC_ID_DYLIB currently says.
        img2 = Image(bytes(img.data))
        for off, cs in img2.find_cmd(LC_ID_DYLIB):
            name_off, = struct.unpack_from("<I", img.data, off + 8)
            cur = bytes(img.data[off + name_off:off + cs]).split(b"\0", 1)[0].decode("ascii", "replace")
            if cur != install_name:
                n = set_lc_string(img.data, cur, install_name)
                if n == 0:
                    raise ValueError(f"failed to set LC_ID_DYLIB to {install_name!r}")
    return rebuild_file(img)


def oversize_bytes(data: bytes, segment: str = "__LINKEDIT") -> bytes:
    img = Image(data)
    out = bytearray(data)
    found = False
    for seg in img.segs:
        if seg.name != segment:
            continue
        found = True
        # Claim one byte past EOF, measured from the segment's fileoff.
        new_fs = (len(data) - seg.fileoff) + 1
        if new_fs <= 0:
            new_fs = len(data) + 1
        struct.pack_into("<Q", out, seg.lc_off + 24 + 24, new_fs)  # filesize at +48
        break
    if not found:
        raise ValueError(f"no segment {segment!r}")
    return bytes(out)


def strip_fixup_lcs(data: bytes) -> bytes:
    """Drop LC_DYLD_INFO / LC_DYLD_INFO_ONLY / LC_DYLD_CHAINED_FIXUPS.

    Cache extracts keep LC_DYLD_EXPORTS_TRIE and the DATA pointers dyld already
    resolved inside the cache, with no rebase or bind stream for a loader to
    apply. The fixture that exercises machorun's refusal is this rewrite of an
    otherwise ordinary dylib.
    """
    img = Image(data)
    keep: list[tuple[int, int]] = []
    stripped = 0
    drop = {LC_DYLD_CHAINED_FIXUPS, LC_DYLD_INFO, LC_DYLD_INFO_ONLY}
    for off, cmd, cs in img.cmd_offs:
        if cmd in drop:
            stripped += 1
            continue
        keep.append((off, cs))
    if stripped == 0:
        raise ValueError("no LC_DYLD_INFO / LC_DYLD_CHAINED_FIXUPS to strip")
    blob = bytearray()
    for off, cs in keep:
        blob += data[off:off + cs]
    orig_sizeof = img.sizeofcmds
    if len(blob) > orig_sizeof:
        raise ValueError("stripped load commands grew")
    out = bytearray(data)
    struct.pack_into("<II", out, 16, len(keep), len(blob))
    out[32:32 + orig_sizeof] = bytes(orig_sizeof)
    out[32:32 + len(blob)] = blob
    return bytes(out)


def inspect(path: str) -> None:
    data = open(path, "rb").read()
    img = Image(data)
    print(f"{path}  {len(data)} bytes")
    for seg in img.segs:
        va = "aligned" if aligned(seg.vmaddr) else f"UNALIGNED +{seg.vmaddr & (HOST_PAGE-1):#x}"
        fo = "aligned" if aligned(seg.fileoff) or seg.filesize == 0 else f"UNALIGNED +{seg.fileoff & (HOST_PAGE-1):#x}"
        print(f"  {seg.name:14s} vm={seg.vmaddr:#014x}+{seg.vmsize:#x}  "
              f"file={seg.fileoff}+{seg.filesize}  vmaddr={va}  fileoff={fo}")
    info = img.find_cmd(LC_DYLD_INFO) + img.find_cmd(LC_DYLD_INFO_ONLY)
    chained = img.find_cmd(LC_DYLD_CHAINED_FIXUPS)
    exports = img.find_cmd(LC_DYLD_EXPORTS_TRIE)
    if info:
        for off, _ in info:
            fields = struct.unpack_from("<10I", data, off + 8)
            print(f"  LC_DYLD_INFO  rebase={fields[0]}+{fields[1]}  bind={fields[2]}+{fields[3]}  "
                  f"weak={fields[4]}+{fields[5]}  lazy={fields[6]}+{fields[7]}  "
                  f"export={fields[8]}+{fields[9]}")
    if chained:
        for off, _ in chained:
            dataoff, datasize = struct.unpack_from("<II", data, off + 8)
            print(f"  LC_DYLD_CHAINED_FIXUPS  dataoff={dataoff} datasize={datasize}")
    if exports:
        for off, _ in exports:
            dataoff, datasize = struct.unpack_from("<II", data, off + 8)
            print(f"  LC_DYLD_EXPORTS_TRIE  dataoff={dataoff} datasize={datasize}")
    if not info and not chained:
        print("  fixups: none (no LC_DYLD_INFO / LC_DYLD_CHAINED_FIXUPS)")
    dc = next((s for s in img.segs if s.name == "__DATA_CONST"), None)
    if dc and dc.filesize >= 8:
        sample, = struct.unpack_from("<Q", data, dc.fileoff)
        print(f"  __DATA_CONST[0] = {sample:#018x}")


def cmd_pack(args: argparse.Namespace) -> int:
    data = open(args.input, "rb").read()
    out = pack_bytes(data, install_name=args.id, unalign=args.unalign,
                     gap=args.gap, sparse=args.sparse)
    os.makedirs(os.path.dirname(os.path.abspath(args.output)) or ".", exist_ok=True)
    open(args.output, "wb").write(out)
    inspect(args.output)
    return 0


def cmd_rename(args: argparse.Namespace) -> int:
    data = bytearray(open(args.input, "rb").read())
    n = set_lc_string(data, args.frm, args.to)
    if n == 0:
        print(f"pack_macho: {args.frm!r} not found in {args.input}", file=sys.stderr)
        return 1
    open(args.output, "wb").write(data)
    print(f"replaced {n} occurrence(s) of {args.frm!r} -> {args.to!r}")
    return 0


def cmd_oversize(args: argparse.Namespace) -> int:
    data = open(args.input, "rb").read()
    out = oversize_bytes(data, segment=args.segment)
    open(args.output, "wb").write(out)
    print(f"wrote {args.output} ({len(out)} bytes, {args.segment} filesize past EOF)")
    return 0


def cmd_inspect(args: argparse.Namespace) -> int:
    inspect(args.input)
    return 0


def cmd_strip_fixups(args: argparse.Namespace) -> int:
    data = open(args.input, "rb").read()
    out = strip_fixup_lcs(data)
    if args.id is not None:
        buf = bytearray(out)
        img = Image(out)
        for off, cs in img.find_cmd(LC_ID_DYLIB):
            name_off, = struct.unpack_from("<I", out, off + 8)
            cur = out[off + name_off:off + cs].split(b"\0", 1)[0].decode("ascii", "replace")
            if cur != args.id:
                n = set_lc_string(buf, cur, args.id)
                if n == 0:
                    raise ValueError(f"failed to set LC_ID_DYLIB to {args.id!r}")
        out = bytes(buf)
    os.makedirs(os.path.dirname(os.path.abspath(args.output)) or ".", exist_ok=True)
    open(args.output, "wb").write(out)
    inspect(args.output)
    return 0


def _selftest() -> int:
    """Pack the committed libdylib_greet.dylib and check the invariants."""
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(root, "tests/bin/libdylib_greet.dylib")
    if not os.path.isfile(src):
        print("selftest: tests/bin/libdylib_greet.dylib missing", file=sys.stderr)
        return 1
    data = open(src, "rb").read()
    packed = pack_bytes(data, install_name="@rpath/libcache_packed.dylib")
    img = Image(packed)
    assert img.find_cmd(LC_ID_DYLIB), "packed dylib lost LC_ID_DYLIB"
    off, cs = img.find_cmd(LC_ID_DYLIB)[0]
    name_off, = struct.unpack_from("<I", packed, off + 8)
    ident = packed[off + name_off:off + cs].split(b"\0", 1)[0]
    assert ident == b"@rpath/libcache_packed.dylib", ident

    text = next(s for s in img.segs if s.name == "__TEXT")
    data_c = next(s for s in img.segs if s.name == "__DATA_CONST")
    data_s = next(s for s in img.segs if s.name == "__DATA")
    assert aligned(text.vmaddr), "TEXT vmaddr should stay aligned (header is the base)"
    assert not aligned(data_c.vmaddr), (
        f"DATA_CONST vmaddr {data_c.vmaddr:#x} should not be page-aligned"
    )
    assert not aligned(data_c.fileoff), (
        f"DATA_CONST fileoff {data_c.fileoff} should not be page-aligned"
    )
    assert data_c.vmaddr - text.vmaddr > CACHE_GAP, "TEXT-to-DATA gap should be cache-like"
    # DATA_CONST and DATA must share a host page (union-of-prots case).
    page_c = data_c.vmaddr & ~(HOST_PAGE - 1)
    page_d = data_s.vmaddr & ~(HOST_PAGE - 1)
    assert page_c == page_d, (
        f"DATA_CONST page {page_c:#x} != DATA page {page_d:#x}; union-of-prots untested"
    )
    # Intra-segment: __got still sits at the start of DATA_CONST.
    got = next(s for s in data_c.sects if s["name"] == "__got")
    assert got["addr"] == data_c.vmaddr, (hex(got["addr"]), hex(data_c.vmaddr))
    # Stubs must ADRP the packed GOT page, not the pre-pack 0x4000 page.
    # Measured crash without this: pc imageoff 0x5e0, fault at slide+0x4008.
    stubs = next(s for s in text.sects if s["name"] == "__stubs")
    stub0 = struct.unpack_from("<I", packed, stubs["offset"])[0]
    adrp = decode_adrp(stub0, stubs["addr"])
    assert adrp is not None, hex(stub0)
    got_page = data_c.vmaddr & ~(HOST_PAGE - 1)
    assert adrp[1] == got_page, (
        f"stub ADRP targets {adrp[1]:#x}, packed GOT page is {got_page:#x}"
    )
    ldr = struct.unpack_from("<I", packed, stubs["offset"] + 4)[0]
    ldst = decode_ldst_uoff(ldr)
    assert ldst is not None and ldst[1] == adrp[0]
    slot = got_page + ldst[2]
    assert data_c.vmaddr <= slot < data_c.vmaddr + data_c.vmsize, (
        f"stub LDR lands at {slot:#x}, packed GOT is {data_c.vmaddr:#x}+{data_c.vmsize:#x}"
    )

    sparse = pack_bytes(data, install_name="@rpath/libcache_sparse.dylib", sparse=True)
    simg = Image(sparse)
    assert simg.find_cmd(LC_ID_DYLIB), "sparse dylib lost LC_ID_DYLIB"
    soff, scs = simg.find_cmd(LC_ID_DYLIB)[0]
    sname_off, = struct.unpack_from("<I", sparse, soff + 8)
    sident = sparse[soff + sname_off:soff + scs].split(b"\0", 1)[0]
    assert sident == b"@rpath/libcache_sparse.dylib", sident
    stext = next(s for s in simg.segs if s.name == "__TEXT")
    sdc = next(s for s in simg.segs if s.name == "__DATA_CONST")
    sds = next(s for s in simg.segs if s.name == "__DATA")
    assert sdc.vmaddr - stext.vmaddr == CACHE_SPARSE_DELTA, (
        hex(sdc.vmaddr - stext.vmaddr)
    )
    assert not aligned(sdc.vmaddr), hex(sdc.vmaddr)
    assert not aligned(sdc.fileoff), sdc.fileoff
    assert (sdc.vmaddr & ~(HOST_PAGE - 1)) == (sds.vmaddr & ~(HOST_PAGE - 1))
    sstubs = next(s for s in stext.sects if s["name"] == "__stubs")
    sstub0 = struct.unpack_from("<I", sparse, sstubs["offset"])[0]
    sadrp = decode_adrp(sstub0, sstubs["addr"])
    assert sadrp is not None, hex(sstub0)
    sgot_page = sdc.vmaddr & ~(HOST_PAGE - 1)
    assert sgot_page == CACHE_SPARSE_DELTA & ~(HOST_PAGE - 1)
    assert sadrp[1] == sgot_page, (
        f"sparse stub ADRP targets {sadrp[1]:#x}, GOT page is {sgot_page:#x}"
    )
    scf = simg.find_cmd(LC_DYLD_EXPORTS_TRIE)
    assert scf, "sparse dylib lost the export trie"
    soffs, ssize = struct.unpack_from("<II", sparse, scf[0][0] + 8)
    sroot = parse_export_trie(sparse, soffs, ssize)

    def _find_export(node, prefix=b""):
        found = []
        if node.flags is not None and prefix:
            found.append((prefix, node.value))
        for edge, child in node.children:
            found.extend(_find_export(child, prefix + edge))
        return found

    exports = dict(_find_export(sroot))
    assert b"_greet_counter" in exports, exports
    assert exports[b"_greet_counter"] == sds.vmaddr, (
        hex(exports[b"_greet_counter"]), hex(sds.vmaddr)
    )

    cf = img.find_cmd(LC_DYLD_CHAINED_FIXUPS)
    assert cf, "packed dylib lost chained fixups"
    dataoff, _ = struct.unpack_from("<II", packed, cf[0][0] + 8)
    starts_off, = struct.unpack_from("<I", packed, dataoff + 4)
    so = dataoff + starts_off
    nseg, = struct.unpack_from("<I", packed, so)
    offs = struct.unpack_from(f"<{nseg}I", packed, so + 4)
    dc_idx = next(i for i, s in enumerate(img.segs) if s.name == "__DATA_CONST")
    p = so + offs[dc_idx]
    seg_off, = struct.unpack_from("<Q", packed, p + 8)
    assert seg_off == data_c.vmaddr - text.vmaddr, (hex(seg_off), hex(data_c.vmaddr))

    oversized = oversize_bytes(data, "__LINKEDIT")
    oimg = Image(oversized)
    le = next(s for s in oimg.segs if s.name == "__LINKEDIT")
    assert le.fileoff + le.filesize > len(oversized)

    nofix = strip_fixup_lcs(data)
    nimg = Image(nofix)
    assert not nimg.find_cmd(LC_DYLD_CHAINED_FIXUPS), "strip-fixups left LC_DYLD_CHAINED_FIXUPS"
    assert not nimg.find_cmd(LC_DYLD_INFO) and not nimg.find_cmd(LC_DYLD_INFO_ONLY)
    assert nimg.find_cmd(LC_DYLD_EXPORTS_TRIE), "strip-fixups dropped LC_DYLD_EXPORTS_TRIE"
    ndc = next(s for s in nimg.segs if s.name == "__DATA_CONST")
    assert ndc.filesize > 0

    # rename round-trip
    buf = bytearray(data)
    n = set_lc_string(buf, "@rpath/libdylib_greet.dylib", "@rpath/libcache_layout.dylib")
    assert n >= 1
    n = set_lc_string(buf, "@rpath/libcache_layout.dylib", "@rpath/libdylib_greet.dylib")
    assert n >= 1
    assert bytes(buf) == data

    print("pack_macho --selftest ok")
    print(f"  packed {len(data)} -> {len(packed)} bytes; "
          f"DATA_CONST vm={data_c.vmaddr:#x} fileoff={data_c.fileoff}; "
          f"DATA vm={data_s.vmaddr:#x}; shared page {page_c:#x}")
    print(f"  sparse {len(data)} -> {len(sparse)} bytes; "
          f"DATA_CONST vm={sdc.vmaddr:#x} (TEXT+{CACHE_SPARSE_DELTA:#x}); "
          f"GOT page {sgot_page:#x}")
    return 0


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest="cmd")

    sp = sub.add_parser("pack", help="rewrite into packed non-page-aligned layout")
    sp.add_argument("input")
    sp.add_argument("-o", "--output", required=True)
    sp.add_argument("--id", help="set LC_ID_DYLIB to this install name")
    sp.add_argument("--unalign", type=lambda x: int(x, 0), default=CACHE_UNALIGN)
    sp.add_argument("--gap", type=lambda x: int(x, 0), default=CACHE_GAP)
    sp.add_argument(
        "--sparse",
        action="store_true",
        help="place DATA_CONST at TEXT+0x22256720 (Apple cache-wide addresses); "
             "implies ignoring --gap",
    )

    sr = sub.add_parser("rename", help="replace an LC string (install name / load path)")
    sr.add_argument("input")
    sr.add_argument("-o", "--output", required=True)
    sr.add_argument("--from", dest="frm", required=True)
    sr.add_argument("--to", required=True)

    so = sub.add_parser("oversize", help="set a segment's filesize past EOF (negative fixture)")
    so.add_argument("input")
    so.add_argument("-o", "--output", required=True)
    so.add_argument("--segment", default="__LINKEDIT")

    sf = sub.add_parser(
        "strip-fixups",
        help="drop LC_DYLD_INFO / LC_DYLD_CHAINED_FIXUPS (cache-extract refusal fixture)",
    )
    sf.add_argument("input")
    sf.add_argument("-o", "--output", required=True)
    sf.add_argument("--id", help="set LC_ID_DYLIB to this install name")

    si = sub.add_parser("inspect", help="print segment alignment and fixup load commands")
    si.add_argument("input")

    p.add_argument("--selftest", action="store_true")
    args = p.parse_args(argv)
    if args.selftest:
        return _selftest()
    if args.cmd == "pack":
        return cmd_pack(args)
    if args.cmd == "rename":
        return cmd_rename(args)
    if args.cmd == "oversize":
        return cmd_oversize(args)
    if args.cmd == "strip-fixups":
        return cmd_strip_fixups(args)
    if args.cmd == "inspect":
        return cmd_inspect(args)
    p.print_help()
    return 2


if __name__ == "__main__":
    sys.exit(main())
