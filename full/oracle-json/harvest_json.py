#!/usr/bin/env python3
"""harvest_json.py -- build the JSON differential corpus from REAL app source.

    ./harvest_json.py <corpus-dir> <out-corpus.json>

Same four shipping apps the URL oracle and the model census used
(artsy/eidolon, duckduckgo/iOS, kickstarter/ios-oss, Automattic/pocket-casts-ios),
shallow-cloned.  Two sources of real documents:

  * `.json` FILES committed in the repos -- API-response fixtures, test stubs,
    GraphQL query templates, xcassets metadata, tuist/spm manifests.
  * JSON LITERALS embedded in `.swift` / `.m` / `.h` sources -- Swift
    triple-quoted multi-line strings and ordinary `"..."` strings whose
    content looks like a JSON document.  These are what test suites feed to
    JSONDecoder directly.

DOCUMENTS ARE STORED BASE64, and that is not incidental.  A JSON corpus has to
carry documents that are NOT valid JSON (truncated, bad escapes, invalid
UTF-8) -- error behaviour is half the contract.  Base64 also keeps the corpus
FILE itself plain ASCII, so the runner, whose own JSON decoder is the thing
under test, can always load its inputs.  Both the oracle and the runner
hand-roll the same 20-line base64 decoder rather than call Foundation's, for
the same reason: exercise the thing under test and as little else as possible.

REAL AND SYNTHETIC ARE DENOMINATED SEPARATELY, always.  The real set says what
shipping apps contain; the synthetic set covers edges apps happen not to ship
(int64 boundaries, lone surrogates, 512-deep nesting).  Mixing them into one
number would let a corpus that is 80% invented claim to be "real-world".
"""
import base64, hashlib, json, os, re, sys
from collections import Counter

REPOS = ["eidolon", "iOS", "ios-oss", "pocket-casts-ios"]
# The committed corpus has to stay proportionate to the repository it lives in
# (largest tracked file before this: 612 KB).  A 128 KB cap admitted seven
# ~100 KB GraphQL fixtures that alone were 2 MB of base64 and taught the
# scanner nothing a 24 KB document does not.  Large documents still matter --
# they are the only ones that exercise buffer growth -- so they are kept, under
# their own small quota rather than the general one.
MAX_FILE = 24 * 1024
MIN_FILE = 2
QUOTA_DEFAULT = 45
QUOTA_OVERRIDE = {"large": 12}
SRC_EXT = (".swift", ".m", ".mm", ".h")
# `.js` was in this list and was REMOVED after looking at what it produced.
# DuckDuckGo vendors a minified autoconsent bundle whose string literals are
# CSS selectors -- `[role=tablist]`, `[data-cookie-accept-all]` -- every one of
# which starts with `[`, ends with `]`, and fails to parse.  They arrived
# labelled "real malformed JSON from a shipping app" and were nothing of the
# kind: they were the harvester being wrong.  See the literal1 rule below.


# ---------------------------------------------------------------------------
# feature fingerprint -- used to SELECT for diversity rather than at random.
# Sampling 300 of 2,791 uniformly would return 300 near-identical xcassets
# Contents.json files, because that is what the corpus is mostly made of.
# ---------------------------------------------------------------------------
def features(b: bytes):
    f = set()
    try:
        t = b.decode("utf-8")
    except UnicodeDecodeError:
        f.add("invalid-utf8")
        t = b.decode("utf-8", "replace")
    if any(ord(c) > 127 for c in t):
        f.add("non-ascii")
    if "\\u" in t:
        f.add("uescape")
    if re.search(r"\\u[dD][89abAB][0-9a-fA-F]{2}", t):
        f.add("surrogate")
    if re.search(r"[-+]?\d+[eE][-+]?\d+", t):
        f.add("exponent")
    if re.search(r"\d+\.\d{15,}", t):
        f.add("longfrac")
    if re.search(r"\b\d{16,}\b", t):
        f.add("bigint")
    if re.search(r"-0\b", t):
        f.add("negzero")
    if "null" in t:
        f.add("null")
    if "true" in t or "false" in t:
        f.add("bool")
    if "[]" in t or "{}" in t:
        f.add("empty-container")
    if "\\/" in t:
        f.add("escaped-slash")
    if "\\t" in t or "\\n" in t or "\\r" in t or "\\b" in t or "\\f" in t:
        f.add("ctrl-escape")
    depth = 0
    best = 0
    instr = False
    esc = False
    for ch in t:
        if esc:
            esc = False
            continue
        if instr:
            if ch == "\\":
                esc = True
            elif ch == '"':
                instr = False
            continue
        if ch == '"':
            instr = True
        elif ch in "[{":
            depth += 1
            best = max(best, depth)
        elif ch in "]}":
            depth -= 1
    if best >= 6:
        f.add("deep6")
    if best >= 10:
        f.add("deep10")
    f.add("depth%d" % min(best, 12))
    if len(b) > 16384:
        f.add("large")
    if t.lstrip()[:1] not in ("{", "["):
        f.add("top-fragment")
    # duplicate keys, cheaply and only at the top level of each object body
    if re.search(r'("(?:[^"\\]|\\.)*")\s*:.*\1\s*:', t):
        f.add("maybe-dupkey")
    return f


def is_jsonish(b: bytes) -> bool:
    """Cheap gate for embedded literals: does it look like a JSON document at
    all?  We deliberately do NOT require it to PARSE -- malformed documents are
    exactly what we want from test suites."""
    try:
        t = b.decode("utf-8").strip()
    except UnicodeDecodeError:
        return False
    if len(t) < 2:
        return False
    if t[0] not in "{[":
        return False
    if t[-1] not in "}]":
        return False
    return True


def collect_files(root):
    out = []
    for repo in REPOS:
        base = os.path.join(root, repo)
        for dirpath, dirnames, filenames in os.walk(base):
            dirnames[:] = [d for d in dirnames if d != ".git"]
            for fn in filenames:
                if not fn.endswith(".json"):
                    continue
                p = os.path.join(dirpath, fn)
                try:
                    sz = os.path.getsize(p)
                except OSError:
                    continue
                if sz < MIN_FILE or sz > MAX_FILE:
                    continue
                with open(p, "rb") as fh:
                    b = fh.read()
                out.append((repo, os.path.relpath(p, root), "file", b))
    return out


TRIPLE = re.compile(r'"""(.*?)"""', re.S)
SINGLE = re.compile(r'"((?:[^"\\\n]|\\.)*)"')


def unescape_swift(s: str) -> str:
    """Undo the Swift/ObjC source-level escaping of a single-line literal, so
    what we store is the DOCUMENT the app feeds to JSONDecoder, not its
    source spelling."""
    out = []
    i = 0
    while i < len(s):
        c = s[i]
        if c == "\\" and i + 1 < len(s):
            n = s[i + 1]
            mapping = {"n": "\n", "t": "\t", "r": "\r", '"': '"', "\\": "\\", "0": "\0"}
            if n in mapping:
                out.append(mapping[n])
                i += 2
                continue
            if n == "u" and i + 2 < len(s) and s[i + 2] == "{":
                j = s.index("}", i)
                out.append(chr(int(s[i + 3:j], 16)))
                i = j + 1
                continue
        out.append(c)
        i += 1
    return "".join(out)


def collect_literals(root):
    out = []
    for repo in REPOS:
        base = os.path.join(root, repo)
        for dirpath, dirnames, filenames in os.walk(base):
            dirnames[:] = [d for d in dirnames if d != ".git"]
            for fn in filenames:
                if not fn.endswith(SRC_EXT):
                    continue
                p = os.path.join(dirpath, fn)
                try:
                    txt = open(p, "r", encoding="utf-8", errors="replace").read()
                except OSError:
                    continue
                if "{" not in txt:
                    continue
                rel = os.path.relpath(p, root)
                for m in TRIPLE.finditer(txt):
                    body = m.group(1).strip("\n")
                    if "\\(" in body:     # interpolation: not a fixed document
                        continue
                    # SWIFT-UNESCAPE FIRST, and this is not cosmetic.  A
                    # multi-line literal still processes `\"` and `\\`, so the
                    # document the app hands to JSONDecoder is `unescape(src)`,
                    # not `src`.  Skipping this step invents malformity: source
                    # `\\"` (a correct JSON escape) would be recorded as a
                    # backslash followed by a bare quote.
                    b = unescape_swift(body).encode("utf-8")
                    if MIN_FILE <= len(b) <= MAX_FILE and is_jsonish(b):
                        out.append((repo, rel, "literal3", b))
                for m in SINGLE.finditer(txt):
                    raw = m.group(1)
                    if len(raw) < 2 or raw[0] not in "{[":
                        continue
                    if "\\(" in raw:          # string interpolation: not a document
                        continue
                    b = unescape_swift(raw).encode("utf-8")
                    if not (MIN_FILE <= len(b) <= MAX_FILE and is_jsonish(b)):
                        continue
                    # A ONE-LINE literal must PARSE to be admitted, and the
                    # asymmetry with files and triple-quoted literals is
                    # deliberate.  `[`...`]` on one line is far more often a
                    # CSS selector, a regex character class or a Swift array
                    # literal than a JSON document, and admitting those would
                    # have inflated the "real malformed documents" count with
                    # things that were never JSON.  Multi-line and `.json`
                    # files carry no such ambiguity, so they are admitted
                    # malformed -- which is where the real broken documents,
                    # like DuckDuckGo's trailing-comma privacy-config-example,
                    # actually come from.
                    try:
                        json.loads(b.decode("utf-8"))
                    except Exception:
                        continue
                    out.append((repo, rel, "literal1", b))
    return out


def main():
    root, outp = sys.argv[1], sys.argv[2]
    raw = collect_files(root) + collect_literals(root)
    print("raw candidates: %d" % len(raw))

    # dedupe by CONTENT -- this is what collapses the ~2,600 xcassets
    # Contents.json files, most of which are byte-identical to each other.
    seen = {}
    for repo, rel, kind, b in raw:
        h = hashlib.sha256(b).hexdigest()
        if h not in seen:
            seen[h] = (repo, rel, kind, b)
    uniq = list(seen.values())
    print("unique by content: %d" % len(uniq))

    # Diversity-first selection: walk the features rarest-first and take
    # documents that carry a feature still under quota.  What this optimises
    # for is stated so it can be argued with: cover every feature the corpus
    # HAS, rather than reproduce the corpus's own frequency distribution.
    feat = {h: features(v[3]) for h, v in zip(seen.keys(), uniq)}
    hlist = list(seen.keys())
    counts = Counter()
    for h in hlist:
        counts.update(feat[h])
    order = sorted(hlist, key=lambda h: (min((counts[f] for f in feat[h]), default=10**9), len(feat[h]) * -1))

    quota = lambda f: QUOTA_OVERRIDE.get(f, QUOTA_DEFAULT)
    TARGET = 340
    picked, have = [], Counter()

    # MALFORMED REAL DOCUMENTS ARE TAKEN UNCONDITIONALLY.  Error behaviour is
    # half the contract and shipping apps contain very few deliberately-broken
    # documents, so a quota would drop the scarcest thing in the corpus.
    # `json.loads` is only the FINDER here -- Python's verdict is never
    # recorded; the golden comes from macOS Foundation alone.
    malformed = []
    for h in hlist:
        try:
            json.loads(seen[h][3].decode("utf-8"))
        except Exception:
            malformed.append(h)
    print("real documents Python cannot parse: %d (all taken)" % len(malformed))
    for h in malformed[:TARGET]:
        picked.append(h)
        have.update(feat[h])

    for h in order:
        if len(picked) >= TARGET:
            break
        if h in set(picked):
            continue
        fs = feat[h]
        if any(have[f] >= quota(f) for f in fs if f in QUOTA_OVERRIDE):
            continue          # a capped feature is a hard cap, not a tie-break
        if any(have[f] < quota(f) for f in fs):
            picked.append(h)
            have.update(fs)
    print("selected real documents: %d" % len(picked))

    docs = []
    for i, h in enumerate(picked):
        repo, rel, kind, b = seen[h]
        docs.append({
            "id": "real-%04d" % i,
            "set": "real",
            "kind": kind,
            "origin": rel,
            "features": sorted(feat[h]),
            "bytes": len(b),
            "b64": base64.b64encode(b).decode("ascii"),
        })

    with open(outp, "w") as fh:
        json.dump(docs, fh, indent=1, sort_keys=True)
    print("wrote %s: %d docs" % (outp, len(docs)))
    print("feature coverage:")
    for f, n in sorted(have.items()):
        print("   %-16s %d" % (f, n))
    per_repo = Counter(seen[h][0] for h in picked)
    print("per repo:", dict(per_repo))
    print("per kind:", dict(Counter(seen[h][2] for h in picked)))


if __name__ == "__main__":
    main()
