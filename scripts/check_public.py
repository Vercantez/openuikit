#!/usr/bin/env python3
"""For each PUBLIC, UNREVIEWED declaration, report Apple's declared return type.

    check_public.py <CFDerivedMethods.h>

THE CLEAN-ROOM LINE, stated as a mechanism rather than an intention: the
declaration TEXT comes from our generator (derived from CoreFoundation's own
call sites). Apple's header is consulted for ONE THING — whether the RETURN TYPE
we derived matches Foundation's contract — and reports agree/differ. It does not
supply text, and nothing it prints is copied into a shipping header; a human
decides each correction.

That distinction is easy to blur once you are reconciling generated output
against those headers, so the tool is deliberately built to be incapable of
generating: it emits a verdict per selector, never a declaration.
"""
import re, subprocess, os, sys, collections

SDK = subprocess.run(["xcrun", "--sdk", "macosx", "--show-sdk-path"],
                     capture_output=True, text=True).stdout.strip()
HDRS = os.path.join(SDK, "System/Library/Frameworks/Foundation.framework/Headers")

NOISE = re.compile(
    r'\b(NS_SWIFT_[A-Z_]+(\([^)]*\))?|API_(AVAILABLE|DEPRECATED|UNAVAILABLE)\([^)]*\)'
    r'|NS_AVAILABLE[A-Z_]*(\([^)]*\))?|NS_DEPRECATED[A-Z_]*\([^)]*\)'
    r'|NS_RETURNS_[A-Z_]+|NS_REQUIRES_[A-Z_]+|NS_DESIGNATED_INITIALIZER'
    r'|NS_REFINED_FOR_SWIFT|NS_NOESCAPE|_Nullable|_Nonnull|_Null_unspecified'
    r'|nullable|nonnull|null_unspecified|__unsafe_unretained|__kindof)\b')

def apple_return_types():
    """selector -> set of return types Apple declares for it."""
    out = collections.defaultdict(set)
    for fn in sorted(os.listdir(HDRS)):
        if not fn.endswith(".h"):
            continue
        try:
            txt = open(os.path.join(HDRS, fn), errors="replace").read()
        except OSError:
            continue
        for m in re.finditer(r'^\s*([-+])\s*\(([^)]*)\)([^;{]*);', txt, re.M):
            ret = NOISE.sub('', m.group(2)).strip()
            body = m.group(3)
            parts = re.findall(r'(\w+)\s*:', body)
            sel = "".join(p + ":" for p in parts) if parts else body.strip().split()[0] if body.strip() else None
            if sel:
                out[sel].add(ret)
        for m in re.finditer(r'^\s*@property\s*(\([^)]*\))?\s*([^;]+);', txt, re.M):
            body = NOISE.sub('', m.group(2)).strip()
            toks = body.split()
            if len(toks) >= 2 and toks[-1].isidentifier():
                out[toks[-1]].add(" ".join(toks[:-1]))
    return out

DECL = re.compile(r'^\s*([-+])\s*\(([^)]*)\)\s*(.*?);.*PUBLIC, UNREVIEWED')

def selector_of(body):
    parts = re.findall(r'(\w+):', body)
    return "".join(p + ":" for p in parts) if parts else body.strip()

apple = apple_return_types()
agree = differ = unknown = 0
print(f"{'selector':<44} {'ours':<22} {'Apple declares':<24} verdict")
print("-" * 104)
for line in open(sys.argv[1]):
    m = DECL.match(line)
    if not m:
        continue
    ours, body = m.group(2).strip(), m.group(3)
    sel = selector_of(body)
    got = apple.get(sel)
    if not got:
        unknown += 1
        print(f"{sel:<44} {ours:<22} {'(not found)':<24} NO REFERENCE")
        continue
    norm = {t.replace('*', ' *').split() and " ".join(t.split()) for t in got}
    if ours in norm:
        agree += 1
        print(f"{sel:<44} {ours:<22} {sorted(norm)[0]:<24} agree")
    else:
        differ += 1
        print(f"{sel:<44} {ours:<22} {' | '.join(sorted(norm))[:24]:<24} DIFFERS")
print(f"\n# agree {agree}   differ {differ}   no-reference {unknown}", file=sys.stderr)
