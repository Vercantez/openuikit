#!/usr/bin/env python3
"""reconcile.py -- prove the tool saw EVERY asset directory the census found.

    ./reconcile.py <census.json> <index-dir> <corpus-dir>

WHY THIS EXISTS AS A SEPARATE GATE.  The first full run of `xcassets_tool.py`
indexed all twenty apps with zero refusals, which looked like a result.  It was
not: 7,424 covered assets against the census's 7,470 -- a silent gap of 46,
because the walker stopped at every non-covered asset directory and 46 covered
assets live *inside* one.  Nothing in the tool's own output could have shown
that, because the tool was the thing that was wrong.

So the accounting is stated as an identity that must hold EXACTLY, with an
independent count of the corpus on the other side:

    asset directories on disk
      = indexed under a unique name
      + lost to a name collision
      + unresolved roots (types outside the covered set)
      + nested inside an unresolved root
      + namespace folders + plain folders + catalog roots

`>= ` is not good enough and neither is "close": a number that nearly ties is a
number nobody has checked.
"""
import json, os, sys, glob
from collections import Counter

COVERED = {".imageset", ".colorset", ".appiconset", ".dataset", ".symbolset"}


def count_on_disk(corpus):
    """Independent census of the corpus: every directory inside a .xcassets."""
    types = Counter()
    catalogs = 0
    for app in sorted(os.listdir(corpus)):
        appdir = os.path.join(corpus, app)
        if not os.path.isdir(os.path.join(appdir, ".git")):
            continue
        for dirpath, dirnames, filenames in os.walk(appdir):
            if ".git" in dirnames:
                dirnames.remove(".git")
            if not dirpath.endswith(".xcassets"):
                continue
            catalogs += 1
            dirnames[:] = []
            for sub, subdirs, subfiles in os.walk(dirpath):
                if sub == dirpath:
                    continue
                ext = os.path.splitext(os.path.basename(sub))[1]
                types[ext or "<folder>"] += 1
    return types, catalogs


def main():
    census_path, index_dir, corpus = sys.argv[1], sys.argv[2], sys.argv[3]
    disk, catalogs_on_disk = count_on_disk(corpus)

    tot = Counter()
    indexes = sorted(glob.glob(os.path.join(index_dir, "*", "index.json")))
    for f in indexes:
        ix = json.load(open(f))
        tot["indexed"] += len(ix["assets"])
        tot["unresolved_roots"] += len(ix["unresolved"])
        tot["collided"] += sum(len(v) for v in ix["collisions"].values())
        tot["catalogs"] += len(ix["catalogs"])
        for k, v in ix["stats"].items():
            tot[k] += v

    disk_asset_dirs = sum(n for t, n in disk.items() if t != "<folder>")
    disk_folders = disk["<folder>"]

    accounted = (tot["indexed"] + tot["collided"] + tot["unresolved_roots"]
                 + tot["nested_under_unresolved"])
    # `unresolved_roots` already counts the nested-inside-covered anomalies,
    # because they are recorded in the same `unresolved` map.
    # namespace + plain folders are counted by the tool; folders nested under an
    # unresolved root are counted in nested_under_unresolved, so subtract them
    # from the folder side to compare like with like.
    nested_folders = tot.get("nested_under_unresolved_<folder>", 0)
    tool_folders = (tot["namespace_folders"] + tot["plain_folders"]
                    + tot["folders_without_contents_json"])

    print("apps indexed                       %d" % len(indexes))
    print("catalogs: on disk %d   walked %d   with root Contents.json %d   without %d"
          % (catalogs_on_disk, tot["catalogs"],
             tot["catalogs_with_root_contents_json"],
             tot["catalogs_without_root_contents_json"]))
    print("")
    print("ASSET DIRECTORIES")
    print("  on disk (independent count)      %6d" % disk_asset_dirs)
    print("    indexed under a unique name    %6d" % tot["indexed"])
    print("    lost to a name collision       %6d" % tot["collided"])
    print("    unresolved roots               %6d" % tot["unresolved_roots"])
    print("    nested inside an unresolved    %6d  (of which %d are folders)"
          % (tot["nested_under_unresolved"], nested_folders))
    print("  accounted                        %6d" % (accounted - nested_folders))
    print("")
    print("FOLDERS")
    print("  on disk                          %6d" % disk_folders)
    print("    namespace (provides-namespace) %6d" % tot["namespace_folders"])
    print("    plain                          %6d" % tot["plain_folders"])
    print("    without a Contents.json        %6d" % tot["folders_without_contents_json"])
    print("    nested inside an unresolved    %6d" % nested_folders)
    print("  accounted                        %6d" % (tool_folders + nested_folders))
    print("")
    print("BY TYPE (disk vs tool)")
    ok = True
    for t in sorted(disk):
        if t == "<folder>":
            continue
        d = disk[t]
        if t in COVERED:
            got = (tot["assets_" + t] + tot.get("nested_under_unresolved_" + t, 0)
                   + tot.get("nested_inside_covered_asset_" + t, 0))
            # collisions are already inside assets_<type>
        else:
            got = (tot.get("unresolved_" + t, 0) + tot.get("nested_under_unresolved_" + t, 0)
                   + tot.get("nested_inside_covered_asset_" + t, 0))
        flag = "" if got == d else "   <== MISMATCH"
        if got != d:
            ok = False
        print("  %-24s disk %6d   tool %6d%s" % (t, d, got, flag))

    print("")
    fails = []
    if accounted - nested_folders != disk_asset_dirs:
        fails.append("asset directories: %d accounted vs %d on disk"
                     % (accounted - nested_folders, disk_asset_dirs))
    if tool_folders + nested_folders != disk_folders:
        fails.append("folders: %d accounted vs %d on disk"
                     % (tool_folders + nested_folders, disk_folders))
    if tot["catalogs"] != catalogs_on_disk:
        fails.append("catalogs: walked %d vs %d on disk" % (tot["catalogs"], catalogs_on_disk))
    if not ok:
        fails.append("at least one per-type count differs")

    if os.path.isfile(census_path):
        c = json.load(open(census_path))
        if c["contents_json"] != (tot["catalogs_with_root_contents_json"]
                                  + disk_asset_dirs + disk_folders
                                  - tot["folders_without_contents_json"]):
            print("note: census Contents.json %d; disk asset dirs %d + folders %d + roots %d"
                  % (c["contents_json"], disk_asset_dirs, disk_folders,
                     tot["catalogs_with_root_contents_json"]))

    if fails:
        for f in fails:
            print("MISMATCH: %s" % f)
        print("VERDICT: the tool did not see everything on disk.")
        return 1
    print("VERDICT: every asset directory and folder on disk is accounted for.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
