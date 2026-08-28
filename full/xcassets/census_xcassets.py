#!/usr/bin/env python3
"""census_xcassets.py -- enumerate EVERY Contents.json key the 20-app corpus uses.

    ./census_xcassets.py <corpus-dir> out.json

THIS RUNS BEFORE ANY READER IS WRITTEN, and that ordering is the point.  The
asset-catalog format as documented is large; the part twenty shipping apps
actually use is a much smaller set, and the reader should implement the second
one and REFUSE on everything else.  It is the same move `APP_COMPAT.md` made
for UIKit: 737 types exist, apps reference ~171, and that is what made the
punch list finite.

WHAT IS COUNTED, and with what denominator:

  * asset TYPES     -- the extension of each directory inside a `.xcassets`
                       (`.imageset`, `.colorset`, `.appiconset`, ...), plus the
                       namespace-providing plain folders.
  * top-level KEYS  -- per asset type.
  * ENTRY keys      -- the keys inside `images` / `colors` / `data` / `symbols`
                       entries, per asset type.
  * VALUES          -- for the enum-shaped fields (idiom, scale, appearance,
                       value, color-space, ...), because "we handle `idiom`"
                       means nothing without knowing which idioms occur.

Every row carries BOTH counts: how many occurrences, and **how many of the 20
apps** it appears in.  A key used 4,000 times in one app is a different fact
from one used 40 times in twenty apps, and only the second is evidence about
the format rather than about one codebase.
"""
import json, os, sys
from collections import Counter, defaultdict

# Fields whose VALUE space is small and load-bearing -- a reader must branch on
# each of these, so the census records the values, not just the key.
ENUMISH = {
    "idiom", "scale", "appearance", "value", "color-space", "subtype",
    "template-rendering-intent", "compression-type", "display-gamut",
    "graphics-feature-set", "memory", "screen-width", "width-class",
    "height-class", "language-direction", "platform", "role", "size",
    "localization", "reference", "symbol-kit-rendering", "unassigned",
    "auto-scaling", "preserves-vector-representation", "provides-namespace",
    "on-demand-resource-tags", "alignment-insets", "colorspace",
}


def walk_catalogs(root):
    """Yield (app, catalog_path, asset_dir_or_None, contents_path)."""
    for app in sorted(os.listdir(root)):
        appdir = os.path.join(root, app)
        if not os.path.isdir(os.path.join(appdir, ".git")):
            continue
        for dirpath, dirnames, filenames in os.walk(appdir):
            if ".git" in dirnames:
                dirnames.remove(".git")
            if not dirpath.endswith(".xcassets"):
                continue
            dirnames[:] = []          # walk the catalog ourselves, below
            for sub, subdirs, subfiles in os.walk(dirpath):
                if "Contents.json" in subfiles:
                    yield app, dirpath, sub, os.path.join(sub, "Contents.json")


def asset_type(catalog, assetdir):
    if os.path.realpath(assetdir) == os.path.realpath(catalog):
        return ".xcassets"
    ext = os.path.splitext(assetdir)[1]
    return ext if ext else "<folder>"


ENTRY_ARRAYS = ("images", "colors", "data", "symbols", "assets", "layers",
                "properties", "info")


def main():
    root, outp = sys.argv[1], sys.argv[2]

    types = Counter(); types_apps = defaultdict(set)
    topkeys = defaultdict(Counter); topkeys_apps = defaultdict(lambda: defaultdict(set))
    arrays = defaultdict(Counter)
    entrykeys = defaultdict(lambda: defaultdict(Counter))
    entrykeys_apps = defaultdict(lambda: defaultdict(lambda: defaultdict(set)))
    values = defaultdict(Counter); values_apps = defaultdict(lambda: defaultdict(set))
    unparsable = []
    per_app = defaultdict(lambda: Counter())
    n_contents = 0
    catalogs = set()

    def note_value(key, v, app):
        if isinstance(v, (dict, list)):
            return
        s = json.dumps(v) if not isinstance(v, str) else v
        values[key][s] += 1
        values_apps[key][s].add(app)

    def scan_entry(t, container, entry, app):
        if not isinstance(entry, dict):
            entrykeys[t][container]["<non-object entry: %s>" % type(entry).__name__] += 1
            return
        for k, v in entry.items():
            entrykeys[t][container][k] += 1
            entrykeys_apps[t][container][k].add(app)
            if k in ENUMISH:
                note_value(k, v, app)
            # `appearances` is a list of {appearance, value} pairs; its two
            # keys are the ones a dark-mode-aware reader branches on, so they
            # are recorded rather than left inside an opaque blob.
            if k == "appearances" and isinstance(v, list):
                for a in v:
                    if isinstance(a, dict):
                        for ak, av in a.items():
                            entrykeys[t]["appearances[]"][ak] += 1
                            entrykeys_apps[t]["appearances[]"][ak].add(app)
                            note_value(ak, av, app)
            if k == "color" and isinstance(v, dict):
                for ck, cv in v.items():
                    entrykeys[t]["color{}"][ck] += 1
                    entrykeys_apps[t]["color{}"][ck].add(app)
                    if ck in ENUMISH:
                        note_value(ck, cv, app)
                    if ck == "components" and isinstance(cv, dict):
                        for comp in cv:
                            entrykeys[t]["color.components{}"][comp] += 1
                            entrykeys_apps[t]["color.components{}"][comp].add(app)

    for app, catalog, assetdir, cpath in walk_catalogs(root):
        catalogs.add(catalog)
        n_contents += 1
        t = asset_type(catalog, assetdir)
        types[t] += 1; types_apps[t].add(app)
        per_app[app][t] += 1
        try:
            with open(cpath, "rb") as fh:
                raw = fh.read()
            doc = json.loads(raw.decode("utf-8"))
        except Exception as e:
            # RECORDED, NOT SWALLOWED.  A Contents.json this census cannot read
            # is a fact about the corpus and the first thing the reader has to
            # cope with; counting it as zero would hide it.
            unparsable.append({"app": app, "path": os.path.relpath(cpath, root),
                               "error": str(e)[:120]})
            continue
        if not isinstance(doc, dict):
            unparsable.append({"app": app, "path": os.path.relpath(cpath, root),
                               "error": "top level is %s, not an object" % type(doc).__name__})
            continue
        for k, v in doc.items():
            topkeys[t][k] += 1
            topkeys_apps[t][k].add(app)
            if isinstance(v, list):
                arrays[t][k] += len(v)
                for e in v:
                    scan_entry(t, k, e, app)
            elif isinstance(v, dict):
                for ik, iv in v.items():
                    entrykeys[t][k + "{}"][ik] += 1
                    entrykeys_apps[t][k + "{}"][ik].add(app)
                    if ik in ENUMISH:
                        note_value(ik, iv, app)
            else:
                note_value(k, v, app)

    def dump_counter(c, appsets):
        return {k: {"uses": n, "apps": len(appsets[k])} for k, n in c.most_common()}

    out = {
        "corpus_root": root,
        "apps": len(per_app),
        "catalogs": len(catalogs),
        "contents_json": n_contents,
        "unparsable": unparsable,
        "asset_types": dump_counter(types, types_apps),
        "top_level_keys": {t: dump_counter(topkeys[t], topkeys_apps[t]) for t in sorted(topkeys)},
        "array_entry_counts": {t: dict(arrays[t]) for t in sorted(arrays)},
        "entry_keys": {
            t: {cont: dump_counter(entrykeys[t][cont], entrykeys_apps[t][cont])
                for cont in sorted(entrykeys[t])}
            for t in sorted(entrykeys)
        },
        "values": {k: dump_counter(values[k], values_apps[k]) for k in sorted(values)},
        "per_app_asset_types": {a: dict(c) for a, c in sorted(per_app.items())},
    }
    with open(outp, "w") as fh:
        json.dump(out, fh, indent=1, sort_keys=True)

    print("apps %d   catalogs %d   Contents.json %d   unparsable %d"
          % (out["apps"], out["catalogs"], out["contents_json"], len(unparsable)))
    print("\nasset types (uses / apps of 20):")
    for t, d in out["asset_types"].items():
        print("   %-18s %7d  %2d" % (t, d["uses"], d["apps"]))
    print("\ntop-level keys by asset type:")
    for t in sorted(out["top_level_keys"]):
        ks = ", ".join("%s(%d/%d)" % (k, v["uses"], v["apps"])
                       for k, v in out["top_level_keys"][t].items())
        print("   %-18s %s" % (t, ks))
    print("\nentry keys, .imageset/images:")
    for k, v in out["entry_keys"].get(".imageset", {}).get("images", {}).items():
        print("   %-32s %7d  %2d" % (k, v["uses"], v["apps"]))
    print("\nvalue spaces:")
    for k in sorted(out["values"]):
        vs = out["values"][k]
        shown = ", ".join("%s(%d/%d)" % (v, d["uses"], d["apps"]) for v, d in list(vs.items())[:14])
        more = "" if len(vs) <= 14 else "  ... %d more" % (len(vs) - 14)
        print("   %-30s %s%s" % (k, shown, more))
    print("\nwrote %s" % outp)


if __name__ == "__main__":
    main()
