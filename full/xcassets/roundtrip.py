#!/usr/bin/env python3
"""roundtrip.py -- every payload byte, source to flat directory.

    ./roundtrip.py <index-dir> <corpus-dir>

The flat directory is content-addressed (`Resources/ab/<sha256><ext>`), so
"the file's name equals the hash of its contents" is already most of the
check. That is deliberately NOT the whole check, because it is circular: the
tool chose both the name and the bytes, and a tool that hashed the wrong file
would agree with itself perfectly.

So this verifies three separate things, and the third is the one that matters:

  1. every payload the index references EXISTS in the flat directory;
  2. its contents hash to the name it was filed under;
  3. **a file with that hash exists in the ORIGINAL corpus** -- re-walked here
     from the corpus tree, independently of the index -- and its bytes are
     identical. Nothing the tool recorded is taken on trust.
"""
import glob, hashlib, json, os, sys
from collections import Counter


def sha256_file(p):
    h = hashlib.sha256()
    with open(p, "rb") as fh:
        for c in iter(lambda: fh.read(1 << 20), b""):
            h.update(c)
    return h.hexdigest()


def walk_payloads(rec, out):
    for key in ("variants", "files", "orphan_files"):
        for v in rec.get(key, []):
            p = v.get("payload", v)
            if isinstance(p, dict) and "sha256" in p:
                out.append(p)


def main():
    index_dir, corpus = sys.argv[1], sys.argv[2]

    # INDEPENDENT INVENTORY of every file inside every .xcassets in the corpus.
    # Built by walking the corpus, not by reading the index.
    corpus_by_hash = {}
    n_corpus_files = 0
    for app in sorted(os.listdir(corpus)):
        appdir = os.path.join(corpus, app)
        if not os.path.isdir(os.path.join(appdir, ".git")):
            continue
        for dirpath, dirnames, _ in os.walk(appdir):
            if ".git" in dirnames:
                dirnames.remove(".git")
            if not dirpath.endswith(".xcassets"):
                continue
            dirnames[:] = []
            for sub, _, files in os.walk(dirpath):
                for f in files:
                    if f == "Contents.json" or f.startswith("."):
                        continue
                    fp = os.path.join(sub, f)
                    if not os.path.isfile(fp):
                        continue
                    n_corpus_files += 1
                    corpus_by_hash.setdefault(sha256_file(fp), fp)
    print("corpus payload files          %6d   (%d distinct by content)"
          % (n_corpus_files, len(corpus_by_hash)))

    stats = Counter()
    failures = []
    for f in sorted(glob.glob(os.path.join(index_dir, "*", "index.json"))):
        base = os.path.dirname(f)
        ix = json.load(open(f))
        payloads = []
        for rec in list(ix["assets"].values()) + list(ix["unresolved"].values()):
            walk_payloads(rec, payloads)
        # Collided assets keep their full record, so their payloads are
        # referenced too.  Leaving them out is how 167 copied-but-unreferenced
        # files went unnoticed the first time.
        for lst in ix.get("collisions", {}).values():
            for c in lst:
                walk_payloads(c["record"], payloads)
        payloads.extend(ix.get("folder_orphans", []))
        seen = set()
        for p in payloads:
            stats["references"] += 1
            if p["sha256"] in seen:
                continue
            seen.add(p["sha256"])
            stats["distinct"] += 1
            flat = os.path.join(base, ix["resources_dir"], p["file"])
            if not os.path.isfile(flat):
                failures.append(("missing in flat dir", ix["app"], p["file"])); continue
            got = sha256_file(flat)
            if got != p["sha256"]:
                failures.append(("flat file hashes to %s" % got, ix["app"], p["file"])); continue
            if os.path.getsize(flat) != p["bytes"]:
                failures.append(("size %d, index says %d" % (os.path.getsize(flat), p["bytes"]),
                                 ix["app"], p["file"])); continue
            src = corpus_by_hash.get(p["sha256"])
            if src is None:
                failures.append(("no corpus file has this hash", ix["app"], p["file"])); continue
            with open(flat, "rb") as a, open(src, "rb") as b:
                if a.read() != b.read():
                    failures.append(("bytes differ from corpus source", ix["app"], p["file"]))
                    continue
            stats["verified"] += 1

    print("index payload references      %6d" % stats["references"])
    print("distinct payloads checked     %6d" % stats["distinct"])
    print("byte-identical to the corpus  %6d of %d" % (stats["verified"], stats["distinct"]))

    # THE OTHER DIRECTION, and the one that actually found the bug: every
    # distinct payload in the corpus must be referenced by some index.  A tool
    # that copies a file and then references nothing looks perfect from the
    # index side.
    referenced = set()
    for f in sorted(glob.glob(os.path.join(index_dir, "*", "index.json"))):
        ix = json.load(open(f))
        ps = []
        for rec in list(ix["assets"].values()) + list(ix["unresolved"].values()):
            walk_payloads(rec, ps)
        for lst in ix.get("collisions", {}).values():
            for c in lst:
                walk_payloads(c["record"], ps)
        ps.extend(ix.get("folder_orphans", []))
        referenced.update(p["sha256"] for p in ps)
    unref = [h for h in corpus_by_hash if h not in referenced]
    print("corpus payloads referenced    %6d of %d" % (len(corpus_by_hash) - len(unref),
                                                       len(corpus_by_hash)))
    for h in unref[:20]:
        failures.append(("in the corpus, referenced by no index", "-",
                         os.path.relpath(corpus_by_hash[h], corpus)))
    if len(unref) > 20:
        failures.append(("... and %d more unreferenced corpus payloads" % (len(unref) - 20), "-", ""))
    if failures:
        print("")
        for why, app, f in failures[:40]:
            print("   FAIL %-34s %-18s %s" % (why, app, f))
        if len(failures) > 40:
            print("   ... %d more" % (len(failures) - 40))
        print("VERDICT: %d payload(s) did not round-trip." % len(failures))
        return 1
    print("VERDICT: every payload byte round-trips.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
