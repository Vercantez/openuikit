#!/usr/bin/env python3
"""Verify reconstructed ObjC signatures against Apple's real Foundation headers.

NOT a generator. This project's standard is clean-room reconstruction
(~/swiftcore-macho/sdk/foundation/Foundation.h states it), so the header we ship
is written by hand from documented API. This tool is the CHECK on that: for each
selector we care about, it reports what Apple's header actually declares, so a
reconstructed signature can be compared against the real ABI instead of trusted.

A wrong ObjC signature is the same silent-ABI hazard class as posix_spawnattr_t,
moved from C to Objective-C: the message compiles, the selector matches, and the
argument or return register is wrong.

Usage: verify_sigs.py <selector-list-file>
"""
import re, subprocess, sys, os, collections

SDK = subprocess.run(["xcrun", "--sdk", "macosx", "--show-sdk-path"],
                     capture_output=True, text=True).stdout.strip()
HDRS = os.path.join(SDK, "System/Library/Frameworks/Foundation.framework/Headers")

# strip the noise Apple's headers carry that is not part of the ABI
NOISE = re.compile(
    r'\b(NS_SWIFT_[A-Z_]+(\([^)]*\))?|API_(AVAILABLE|DEPRECATED|UNAVAILABLE)\([^)]*\)'
    r'|NS_AVAILABLE[A-Z_]*(\([^)]*\))?|NS_DEPRECATED[A-Z_]*\([^)]*\)'
    r'|NS_RETURNS_[A-Z_]+|NS_REQUIRES_[A-Z_]+|NS_DESIGNATED_INITIALIZER'
    r'|NS_REFINED_FOR_SWIFT|NS_FORMAT_[A-Z_]+\([^)]*\)|__unsafe_unretained'
    r'|_Nullable|_Nonnull|_Null_unspecified|nullable|nonnull|null_unspecified'
    r'|NS_NOESCAPE|CF_[A-Z_]+)\b')

def selector_of(decl):
    """Derive the selector from a method declaration."""
    body = decl.split(')', 1)[1] if ')' in decl.split(None, 1)[1] else decl
    # crude but adequate: take identifiers immediately followed by ':' plus a
    # trailing bare identifier for zero-arg methods
    parts = re.findall(r'(\w+)\s*:', decl)
    if parts:
        return "".join(p + ":" for p in parts)
    m = re.search(r'\)\s*(\w+)\s*(?:;|__|NS_|API_)', decl)
    return m.group(1) if m else None

def scan():
    decls = collections.defaultdict(list)   # selector -> [(header, cleaned decl)]
    for fn in sorted(os.listdir(HDRS)):
        if not fn.endswith(".h"):
            continue
        try:
            txt = open(os.path.join(HDRS, fn), errors="replace").read()
        except OSError:
            continue
        # methods
        for m in re.finditer(r'^\s*([-+]\s*\([^)]*\)[^;{]*);', txt, re.M):
            d = NOISE.sub('', m.group(1))
            d = re.sub(r'\s+', ' ', d).strip()
            s = selector_of(d)
            if s:
                decls[s].append((fn, d))
        # readonly properties are selectors too (count, length, ...)
        for m in re.finditer(r'^\s*@property\s*(\([^)]*\))?\s*([^;]+);', txt, re.M):
            body = NOISE.sub('', m.group(2)).strip()
            name = body.split()[-1].lstrip('*')
            if name.isidentifier():
                decls[name].append((fn, f"@property {body}"))
    return decls

want = [l.strip().lstrip('-+') for l in open(sys.argv[1])
        if l.strip() and not l.startswith('#')]
decls = scan()
found = miss = 0
for s in want:
    hits = decls.get(s, [])
    if hits:
        found += 1
        seen = set()
        uniq = [(h, d) for h, d in hits if not (d in seen or seen.add(d))]
        print(f"{s}")
        for h, d in uniq[:3]:
            print(f"    {h:<28} {d}")
    else:
        miss += 1
        print(f"{s}\n    -- NOT FOUND in Apple's Foundation headers --")
print(f"\n# {found} of {len(want)} selectors located; {miss} not found",
      file=sys.stderr)
