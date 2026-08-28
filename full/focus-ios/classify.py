#!/usr/bin/env python3
"""Classify the focus-ios census logs (#93 phase 2).

Prints the DENOMINATOR at every level. A census that reports only what it found
cannot be told apart from one that looked at nothing.
"""
import collections
import os
import re
import sys

OUT = sys.argv[1]
APP = sys.argv[2]
LOGS = os.path.join(OUT, "logs")

ERR = re.compile(r"error: (.*)")
NAME = re.compile(r"cannot find (?:type )?'([^']+)' in scope")
MEMBER = re.compile(r"(?:value of type|type) '([^']+)' has no member '([^']+)'")
APPLE = re.compile(r"^(UI|NS|CG|CA|CF|WK|CL|AV|MK|SK|UT|QL)[A-Z]")

# App-declared symbols, so "cannot find X" can be split into a real API gap and
# a consequence of a module that failed earlier.
decl = re.compile(r"\b(?:class|struct|enum|protocol|typealias|actor)\s+([A-Za-z_]\w*)")
own = set()
for dp, dn, fns in os.walk(APP):
    if ".git" in dp.split(os.sep):
        continue
    for fn in fns:
        if fn.endswith(".swift"):
            try:
                own |= set(decl.findall(open(os.path.join(dp, fn), encoding="utf-8",
                                             errors="replace").read()))
            except OSError:
                pass

def norm(msg):
    return re.sub(r"'[^']*'", "'X'", re.sub(r"\d+", "N", msg)).strip()

stages = []
for fn in sorted(os.listdir(LOGS)):
    if not fn.endswith(".log"):
        continue
    txt = open(os.path.join(LOGS, fn), encoding="utf-8", errors="replace").read()
    stages.append((fn[:-4], txt, txt.count("error:")))

print("=== STAGES (every one reported, including the clean ones) ===")
for name, _, n in stages:
    print("  %-26s %5d errors" % (name, n))
print("  %-26s %5d" % ("TOTAL", sum(n for _, _, n in stages)))

# Whole-corpus error-kind breakdown
kinds = collections.Counter()
names = collections.Counter()
members = collections.Counter()
for _, txt, _ in stages:
    for m in ERR.finditer(txt):
        kinds[norm(m.group(1))] += 1
    for m in NAME.finditer(txt):
        names[m.group(1)] += 1
    for m in MEMBER.finditer(txt):
        members[(m.group(1), m.group(2))] += 1

print("\n=== ERROR KINDS, ranked (denominator %d) ===" % sum(kinds.values()))
for k, n in kinds.most_common(18):
    print("  %5d  %s" % (n, k))

real = {n: c for n, c in names.items() if APPLE.match(n) and n not in own}
mine = {n: c for n, c in names.items() if n in own}
other = {n: c for n, c in names.items() if n not in real and n not in mine}
print("\n=== MISSING TYPES: %d distinct / %d occurrences ===" % (len(names), sum(names.values())))
print("  Apple-framework names (a REAL gap)     : %3d distinct / %4d uses"
      % (len(real), sum(real.values())))
print("  app's own symbols (an earlier failure) : %3d distinct / %4d uses"
      % (len(mine), sum(mine.values())))
print("  other                                  : %3d distinct / %4d uses"
      % (len(other), sum(other.values())))
print("\n  the real Apple-type gap, ranked:")
for n, c in sorted(real.items(), key=lambda kv: (-kv[1], kv[0])):
    print("   %4d  %s" % (c, n))

# SnapKit's DSL is an extension property on UIKit types (`view.snp`), so its
# absence shows up as a member error on a UIKit type. Attributing that to
# OpenUIKit would inflate the #94 list with work that is really "SnapKit did not
# build". Split it out by name rather than lumping it in.
SNAPKIT_MEMBERS = {"snp", "snp_"}
snapkit_members = {(t, m): c for (t, m), c in members.items() if m in SNAPKIT_MEMBERS}
apple_members = {(t, m): c for (t, m), c in members.items()
                 if APPLE.match(t.split(".")[-1].strip("[]?")) and m not in SNAPKIT_MEMBERS}
print("\n=== MISSING MEMBERS on types that DO exist ===")
print("  total member errors                    : %d" % sum(members.values()))
print("  on Apple-framework types (the #94 list): %d distinct / %d uses"
      % (len(apple_members), sum(apple_members.values())))
print("  SnapKit's own DSL (.snp / .snp_)        : %d distinct / %d uses"
      % (len(snapkit_members), sum(snapkit_members.values())))
by_type = collections.Counter()
for (t, m), c in apple_members.items():
    by_type[t] += c
print("\n  by owning type, ranked:")
for t, c in by_type.most_common(25):
    ms = sorted(m for (tt, m) in apple_members if tt == t)
    print("   %4d  %-34s %s" % (c, t, ", ".join(ms[:6]) + (" …" if len(ms) > 6 else "")))
