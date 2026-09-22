#!/usr/bin/env python3
"""nibdump.py <file.nib|dir.storyboardc> ... — print compiled NIBArchives.

Reads the same container layout as Sources/OpenUIKit/UINib.swift (header,
object/key/value/class tables, high-bit-terminated varints). One block per
object: `#index ClassName` then each value `key = value`; references print as
`@N<Class>` (strings inline). For a .storyboardc directory, prints Info.plist
and then every .nib in it (a `.nib` directory prints its runtime.nib).
"""
import os
import plistlib
import struct
import sys


def varint(b, p):
    v = shift = 0
    while True:
        x = b[p]
        p += 1
        v |= (x & 0x7F) << shift
        shift += 7
        if x & 0x80:
            return v, p


def parse(b):
    assert b[:10] == b"NIBArchive", "not a NIBArchive"
    f = struct.unpack_from("<10I", b, 10)
    oc, oo, kc, ko, vc, vo, cc, co = f[2:]
    classes = []
    p = co
    for _ in range(cc):
        n, p = varint(b, p)
        ex, p = varint(b, p)
        p += 4 * ex
        classes.append(b[p:p + n].rstrip(b"\0").decode())
        p += n
    keys = []
    p = ko
    for _ in range(kc):
        n, p = varint(b, p)
        keys.append(b[p:p + n].decode())
        p += n
    values = []
    p = vo
    for _ in range(vc):
        k, p = varint(b, p)
        t = b[p]
        p += 1
        if t == 0:
            v = struct.unpack_from("<b", b, p)[0]; p += 1
        elif t == 1:
            v = struct.unpack_from("<h", b, p)[0]; p += 2
        elif t == 2:
            v = struct.unpack_from("<i", b, p)[0]; p += 4
        elif t == 3:
            v = struct.unpack_from("<q", b, p)[0]; p += 8
        elif t == 4:
            v = False
        elif t == 5:
            v = True
        elif t == 6:
            v = struct.unpack_from("<f", b, p)[0]; p += 4
        elif t == 7:
            v = struct.unpack_from("<d", b, p)[0]; p += 8
        elif t == 8:
            n, p = varint(b, p)
            v = bytes(b[p:p + n]); p += n
        elif t == 9:
            v = None
        elif t == 10:
            v = ("ref", struct.unpack_from("<I", b, p)[0]); p += 4
        else:
            raise ValueError(f"value type {t}")
        values.append((keys[k], v))
    objs = []
    p = oo
    for _ in range(oc):
        ci, p = varint(b, p)
        fv, p = varint(b, p)
        n, p = varint(b, p)
        objs.append((classes[ci], values[fv:fv + n]))
    return objs


def fmt(v, objs):
    if isinstance(v, tuple):
        i = v[1]
        cls, vals = objs[i]
        if cls in ("NSString", "NSMutableString"):
            for k, x in vals:
                if k == "NS.bytes":
                    return f"@{i} {x.decode(errors='replace')!r}"
        return f"@{i}<{cls}>"
    if isinstance(v, bytes):
        if v and v[0] == 7 and (len(v) - 1) % 8 == 0 and len(v) > 1:
            n = (len(v) - 1) // 8
            return "{" + ", ".join(f"{x:g}" for x in struct.unpack_from(f"<{n}d", v, 1)) + "}"
        try:
            s = v.decode()
            if s.isprintable():
                return repr(s)
        except UnicodeDecodeError:
            pass
        return v.hex()
    return repr(v)


def dump(path):
    objs = parse(open(path, "rb").read())
    print(f"== {path} ({len(objs)} objects)")
    for i, (cls, vals) in enumerate(objs):
        if cls == "NSString":
            continue
        print(f"#{i} {cls}")
        for k, v in vals:
            print(f"    {k} = {fmt(v, objs)}")


def main(args):
    for arg in args:
        if os.path.isdir(arg) and not arg.endswith(".nib"):
            info = os.path.join(arg, "Info.plist")
            if os.path.exists(info):
                print(plistlib.load(open(info, "rb")))
            for n in sorted(os.listdir(arg)):
                if n.endswith(".nib"):
                    p = os.path.join(arg, n)
                    dump(os.path.join(p, "runtime.nib") if os.path.isdir(p) else p)
        elif os.path.isdir(arg):
            dump(os.path.join(arg, "runtime.nib"))
        else:
            dump(arg)


if __name__ == "__main__":
    main(sys.argv[1:])
