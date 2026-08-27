#!/usr/bin/env python3
"""Member-level census: which INITIALIZERS and MEMBERS do apps actually call?

The type-level census (model_census.py) says URL is 2,844 uses. It does not say
which of URL's ~90 members those uses touch -- and that is the number that makes
an implementation finite, exactly as APP_COMPAT.md's "~171 of 737 UIKit types"
did at type level.

TWO HALVES WITH DIFFERENT RELIABILITY, kept separate on purpose:

  INITIALIZERS are PRECISE. `URL(string:` can only be URL's, because the type
  name immediately precedes the paren. These counts can be trusted.

  MEMBERS OVER-COUNT. `.path` is not URL-exclusive and no regex can tell whose
  it is. The RANKING is the usable output; the absolute numbers are not. Same
  caveat as the type census, stated for the same reason.
"""
import os, re, sys, json
from collections import Counter

INIT_TYPES = ["URL", "Data", "Date", "UUID", "URLRequest"]
MEMBERS = {
    "URL": ["absoluteString","path","lastPathComponent","pathExtension","appendingPathComponent",
            "appendingPathExtension","deletingLastPathComponent","deletingPathExtension","host",
            "scheme","query","queryItems","port","relativePath","standardized","isFileURL",
            "baseURL","pathComponents","fragment","user","password","absoluteURL","appending"],
    "Date": ["timeIntervalSince1970","timeIntervalSinceNow","timeIntervalSinceReferenceDate",
             "addingTimeInterval","timeIntervalSince","now","compare","distance","advanced"],
}

def main():
    corpus, outp = sys.argv[1], sys.argv[2]
    init = {t: Counter() for t in INIT_TYPES}
    bare = Counter()
    mem = Counter()
    irx = {t: re.compile(r'\b'+t+r'\(\s*([a-zA-Z_]\w*)\s*:') for t in INIT_TYPES}
    brx = {t: re.compile(r'\b'+t+r'\(\s*\)') for t in INIT_TYPES}
    mrx = {(t, m): re.compile(r'\.'+m+r'\b') for t, ms in MEMBERS.items() for m in ms}
    files = 0
    for root, dirs, fs in os.walk(corpus):
        dirs[:] = [d for d in dirs if d not in (".git", "Carthage", "Pods", ".build")]
        for f in fs:
            if not f.endswith(".swift"):
                continue
            files += 1
            try:
                s = open(os.path.join(root, f), encoding="utf-8", errors="ignore").read()
            except OSError:
                continue
            for t, rx in irx.items():
                init[t].update(rx.findall(s))
            for t, rx in brx.items():
                bare[t] += len(rx.findall(s))
            for (t, m), rx in mrx.items():
                n = len(rx.findall(s))
                if n:
                    mem[t + "." + m] += n
    out = {"files": files,
           "initializers": {t: dict(init[t]) for t in INIT_TYPES},
           "bare_initializers": dict(bare),
           "members_RANKING_ONLY": dict(mem.most_common())}
    json.dump(out, open(outp, "w"), indent=1)
    print(f"scanned {files} swift files\n")
    for t in INIT_TYPES:
        tot = sum(init[t].values()) + bare[t]
        if not tot:
            continue
        print(f"{t}  ({tot} initializer calls, PRECISE)")
        if bare[t]:
            print(f"   {t}(){'':<{max(0,18-len(t))}}{bare[t]:>6}")
        for lab, n in init[t].most_common(6):
            print(f"   {t}({lab}:){'':<{max(0,16-len(lab))}}{n:>6}")
        print()
    print("MEMBERS -- RANKING ONLY, counts over-count (see docstring)")
    for k, n in mem.most_common(18):
        print(f"   .{k:<40}{n:>6}")

main()
