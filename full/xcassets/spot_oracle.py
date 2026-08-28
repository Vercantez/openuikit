#!/usr/bin/env python3
"""spot_oracle.py -- score the reader against Apple's own asset-catalog compiler.

    ./spot_oracle.py <corpus-dir> <work-dir> [--apps a,b,c] [--limit N]

    actool --compile ... <catalog>        Apple compiles the catalog
    assetutil --info Assets.car           Apple dumps what it produced
    xcassets_tool.py index <catalog>      we read the same directory

`assetutil` reports each rendition's `Name`, `Scale`, `Idiom`, `Appearance` and
`RenditionName` -- the SOURCE FILE BASENAME -- and, for colours, the resolved
`Color components`. So the two sides can be compared as sets of tuples without
either one seeing the other's intermediate state.

THIS IS A REAL DIFFERENTIAL, and a stronger one than the JSON oracle's:
`actool` is closed-source, written by the vendor of the format, and shares no
code with this reader. Nothing here is a self-test.

The rules, the exclusions and their counts are pre-registered in EXPECTED.md,
committed before this file ran over the corpus.
"""
import argparse, json, os, shutil, subprocess, sys, tempfile
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
TOOL = os.path.join(HERE, "xcassets_tool.py")

# P2: idioms `actool` is not being asked to compile.  Excluded and counted,
# never scored as "the oracle is missing a row we have".
# `car` WAS IN THIS LIST AND SHOULD NOT HAVE BEEN.  CarPlay is an iOS feature:
# actool compiling for iphoneos emits `car` renditions, and excluding them on
# the tool side while the oracle kept them produced 12 phantom "only in actool"
# rows from pocket-casts' Carplay.xcassets.  Same shape as #72's URL oracle,
# where a pre-registered expected-fail list of 16 measured out at 7 -- a
# pre-registration is a number like any other and has to be re-derived.
NON_IOS_IDIOMS = {"watch", "tv", "vision", "watch-marketing", "mac",
                  "ios-marketing"}
# `assetutil` SPELLS IDIOMS DIFFERENTLY from Contents.json: the source says
# `iphone` / `ipad`, the dump says `phone` / `pad`.  Same idiom, two
# vocabularies -- and left unmapped it produced 99 "only in the tool" plus a
# matching 109 "only in actool", i.e. the same rows counted twice as
# divergences.  That was the COMPARATOR being wrong, not the reader: the reader
# records the spelling the file uses, which is the only defensible thing for it
# to do.
ORACLE_IDIOM = {"phone": "iphone", "pad": "ipad"}

# `assetutil` TRUNCATES RenditionName AT 127 CHARACTERS.  Measured, not
# inferred: Telegram-iOS generates filenames like
# `submodules_TelegramUI_Images.xcassets_Call_CallMuteButton.imageset_CallMuteIcon@2x_Before_<40-hex>.png`
# and the dump cuts them mid-hash, extension and all.  Comparing those by
# equality is comparing our filename against a prefix of it.
RENDITION_NAME_LIMIT = 127

APPEARANCE_MAP = {None: "any", "UIAppearanceAny": "any",
                  "UIAppearanceLight": "light", "UIAppearanceDark": "dark",
                  "UIAppearanceTinted": "tinted"}


def ssort(x):
    """`actool` can report a rendition with no Scale, so None must sort."""
    return sorted(x, key=lambda v: (v is None, v))


def run(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, **kw)


def compile_catalog(catalog, out):
    os.makedirs(out, exist_ok=True)
    r = run(["actool", "--compile", out,
             "--platform", "iphoneos",
             "--minimum-deployment-target", "15.0",
             "--target-device", "iphone", "--target-device", "ipad",
             "--output-partial-info-plist", os.path.join(out, "part.plist"),
             "--output-format", "human-readable-text", catalog])
    car = os.path.join(out, "Assets.car")
    if not os.path.isfile(car):
        # DISTINGUISH "actool failed" FROM "actool compiled to nothing".  The
        # first version reported both as refusals and printed the last line of
        # actool's output, which is a PATH -- so 18 catalogs were "refused" with
        # a message that said nothing.  A catalog holding only content this
        # platform does not build (tvOS brand assets, a lone dataset) makes
        # actool exit 0 and emit no car, and that is not a failure.
        tail = [l for l in (r.stderr or r.stdout or "").strip().splitlines()
                if l and not l.startswith("/") and not l.startswith("/*")]
        why = tail[-1] if tail else ("actool exited %d and produced no Assets.car" % r.returncode)
        return None, ("EMPTY: " if r.returncode == 0 else "FAILED: ") + why
    return car, None


def oracle_rows(car):
    r = run(["assetutil", "--info", car])
    if r.returncode != 0:
        return None, (r.stderr or "assetutil failed").strip().splitlines()[-1]
    try:
        entries = json.loads(r.stdout)
    except Exception as e:
        return None, "assetutil output is not JSON: %s" % e
    images, colors, datas = set(), {}, {}
    for e in entries:
        t = e.get("AssetType")
        if t is None:
            continue                      # the header record
        name = e.get("Name")
        idiom = ORACLE_IDIOM.get(e.get("Idiom"), e.get("Idiom"))
        app = APPEARANCE_MAP.get(e.get("Appearance"), e.get("Appearance"))
        if t == "Color":
            colors[(name, idiom, app)] = (e.get("Colorspace"),
                                          tuple(e.get("Color components") or ()))
        elif t == "Data":
            # DATASETS CARRY NO `RenditionName` -- measured: actool keeps the
            # bytes and drops the source filename.  So they cannot join the
            # image comparison, and both of the corpus's two datasets were
            # showing up as "only in the tool" for that reason alone.  They are
            # compared on what the oracle DOES report: the name, the idiom and
            # `Data Length`, which is the payload's byte count.
            datas[(name, idiom)] = e.get("Data Length")
        elif t in ("Image", "PDF", "Vector"):
            rn = e.get("RenditionName")
            if rn is None:
                continue
            images.add((name, e.get("Scale"), idiom, app, rn))
    return (images, colors, datas), None


VECTOR_EXT = {".pdf", ".svg"}


def tool_rows(index):
    """Same tuple shape, from our index.  Only the covered, comparable types.

    Also returns the set of asset NAMES the pre-registration excludes, so the
    ORACLE side can be filtered by the same rule.  The first run excluded
    appiconsets, symbolsets and system-colour references from the tool side
    only, and then reported 5 images and 7 colours as "only in actool" -- which
    was a one-sided exclusion, not a divergence."""
    images, colors = set(), {}
    excluded = Counter()
    excluded_names = set()     # whole assets: appiconset, symbolset
    excluded_keys = set()      # single variants: system-colour references
    vector_names = set()
    datas = {}
    for name, rec in index["assets"].items():
        t = rec["type"]
        if t == "dataset":
            for v in rec["variants"]:
                datas[(name, v["idiom"])] = v["payload"]["bytes"]
            continue
        if t == "appiconset":            # P3: name only
            excluded["appiconset_variants"] += len(rec["variants"])
            excluded_names.add(name)
            continue
        if t == "symbolset":             # P4: our own scope statement
            excluded["symbolset_variants"] += len(rec["variants"])
            excluded_names.add(name)
            continue
        if t == "colorset":
            for v in rec["variants"]:
                if v.get("srgb") is None:
                    # A `reference` to a system colour.  actool RESOLVES these
                    # -- it has the system palette -- and the reader cannot,
                    # because the value is not in the catalog.  Excluded on
                    # BOTH sides and reported as a finding, not as a defect.
                    # PER VARIANT, NOT PER ASSET.  Three NetNewsWire colorsets
                    # are MIXED -- `fullScreenBackgroundColor` has a real
                    # gray-gamma-22 dark variant beside an
                    # `any` variant that references `systemBackgroundColor`.
                    # Excluding the whole asset dropped the concrete variant
                    # from the oracle side and reported it as "only in the
                    # tool", which was the exclusion being too coarse rather
                    # than a divergence.
                    excluded["colorset_system_reference"] += 1
                    excluded_keys.add((name, v["idiom"], v["appearance"]))
                    continue
                if v["idiom"] in NON_IOS_IDIOMS:
                    excluded["non_ios_idiom"] += 1
                    continue
                colors[(name, v["idiom"], v["appearance"])] = (
                    v["color_space"], v.get("native"))
            continue
        for v in rec["variants"]:
            if v["idiom"] in NON_IOS_IDIOMS:
                excluded["non_ios_idiom"] += 1
                continue
            if v["payload"]["ext"] in VECTOR_EXT:
                vector_names.add((name, v["payload"]["filename"]))
            images.add((name, v.get("scale"), v["idiom"], v["appearance"],
                        v["payload"]["filename"]))
    return images, colors, datas, excluded, excluded_names, excluded_keys, vector_names


CS_ALIAS = {"p3": "display-p3", "srgb": "srgb", "extended srgb": "extended-srgb",
            "gray gamma 22": "gray-gamma-22", "extended range srgb": "extended-srgb",
            "extended linear srgb": "extended-srgb"}


def compare(oracle, tool, name_of_catalog, report):
    (o_img, o_col, o_dat) = oracle
    (t_img, t_col, t_dat, excluded, excluded_names, excluded_keys, vector_names) = tool
    st = Counter()
    # The pre-registered exclusions applied to the ORACLE side too.
    o_img = {r for r in o_img if r[0] not in excluded_names}
    o_col = {k: v for k, v in o_col.items()
             if k[0] not in excluded_names and k not in excluded_keys}

    # ---- images -------------------------------------------------------
    # A tool variant with `scale: null` is matched against ANY scale the
    # oracle assigned it, because a scaleless entry is exactly the case where
    # the two implementations might legitimately differ, and pinning it to a
    # guess would score our guess rather than the reader.
    # Both sides are keyed on the filename TRUNCATED to the oracle's own limit,
    # so a name the dump cut at 127 characters still compares against the file
    # it came from.  Truncating both sides rather than prefix-matching keeps the
    # comparison a set operation and cannot accidentally match two different
    # long names -- if it ever did, they would be identical for 127 characters.
    def clip127(f):
        return f[:RENDITION_NAME_LIMIT]

    o_by_key = defaultdict(set)
    for (n, s, i, a, f) in o_img:
        o_by_key[(n, i, a, clip127(f))].add(s)
    t_by_key = defaultdict(set)
    for (n, s, i, a, f) in t_img:
        t_by_key[(n, i, a, clip127(f))].add(s)

    for k, tscales in sorted(t_by_key.items()):
        if k not in o_by_key:
            st["image_tool_only"] += 1
            report.append(("IMAGE only in the tool", name_of_catalog, k, ""))
            continue
        oscales = o_by_key[k]
        if (k[0], k[3]) in vector_names and tscales != oscales:
            # ACTOOL GENERATES, THE SOURCE DECLARES.  A single PDF entry marked
            # `1x` comes back as renditions at 1x, 2x, 3x and a scaleless
            # vector one: actool RASTERISES the vector at every scale the
            # target needs.  That is a property of the compiler, not of the
            # catalog, and a reader of source form cannot and should not
            # reproduce it.  Counted and printed in its own class rather than
            # folded into "agree", which would have been the easy way to make
            # the scoreboard green.
            st["image_vector_expanded_by_actool"] += 1
            report.append(("NOTE actool expanded a vector", name_of_catalog, k,
                           "source %s -> actool %s" % (ssort(tscales), ssort(oscales))))
            continue
        if None in tscales:
            # A source entry with no `scale` key.  It matches whatever scale
            # actool assigned -- but WHAT it assigned is recorded and printed,
            # because "matches anything" is a rule that would pass even if the
            # reader were wrong, and the interesting fact is what actool does.
            st["image_scaleless_matched"] += 1
            st["image_agree"] += 1
            report.append(("NOTE scaleless entry, actool assigned", name_of_catalog,
                           k, "scale %s" % ssort(oscales)))
            continue
        if tscales == oscales:
            st["image_agree"] += 1
        else:
            st["image_scale_differs"] += 1
            report.append(("IMAGE scale differs", name_of_catalog, k,
                           "tool %s vs actool %s" % (ssort(tscales), ssort(oscales))))
    for k in sorted(o_by_key):
        if k not in t_by_key:
            st["image_oracle_only"] += 1
            report.append(("IMAGE only in actool", name_of_catalog, k, ""))

    # ---- colours ------------------------------------------------------
    for k, (space, comps) in sorted(t_col.items()):
        if k not in o_col:
            st["color_tool_only"] += 1
            report.append(("COLOR only in the tool", name_of_catalog, k, ""))
            continue
        ospace, ocomps = o_col[k]
        ospace_n = CS_ALIAS.get((ospace or "").lower(), ospace)
        if ospace_n != space:
            st["color_space_differs"] += 1
            report.append(("COLOR colour space differs", name_of_catalog, k,
                           "tool %s vs actool %s" % (space, ospace)))
            continue
        if comps is None or len(ocomps) != len(comps):
            st["color_arity_differs"] += 1
            report.append(("COLOR component count differs", name_of_catalog, k,
                           "tool %s vs actool %s" % (comps, ocomps)))
            continue
        if all(abs(a - b) <= 1e-6 for a, b in zip(comps, ocomps)):
            st["color_agree"] += 1
        else:
            st["color_differs"] += 1
            report.append(("COLOR components differ", name_of_catalog, k,
                           "tool %s vs actool %s" % (
                               [round(c, 8) for c in comps], list(ocomps))))
    for k in sorted(o_col):
        if k not in t_col:
            st["color_oracle_only"] += 1
            report.append(("COLOR only in actool", name_of_catalog, k, ""))
    # ---- datasets -----------------------------------------------------
    for k, n in sorted(t_dat.items()):
        if k not in o_dat:
            st["data_tool_only"] += 1
            report.append(("DATA only in the tool", name_of_catalog, k, ""))
        elif o_dat[k] != n:
            st["data_differs"] += 1
            report.append(("DATA byte length differs", name_of_catalog, k,
                           "tool %s vs actool %s" % (n, o_dat[k])))
        else:
            st["data_agree"] += 1
    for k in sorted(o_dat):
        if k not in t_dat:
            st["data_oracle_only"] += 1
            report.append(("DATA only in actool", name_of_catalog, k, ""))

    for k, v in excluded.items():
        st["excluded_" + k] += v
    return st


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("corpus"); ap.add_argument("work")
    ap.add_argument("--apps", default=None)
    ap.add_argument("--limit", type=int, default=0)
    args = ap.parse_args()

    apps = args.apps.split(",") if args.apps else sorted(os.listdir(args.corpus))
    catalogs = []
    for app in apps:
        appdir = os.path.join(args.corpus, app)
        if not os.path.isdir(os.path.join(appdir, ".git")):
            continue
        for dirpath, dirnames, _ in os.walk(appdir):
            if ".git" in dirnames:
                dirnames.remove(".git")
            for d in list(dirnames):
                if d.endswith(".xcassets"):
                    catalogs.append((app, os.path.join(dirpath, d)))
                    dirnames.remove(d)
    catalogs.sort()
    if args.limit:
        catalogs = catalogs[:args.limit]

    # DO NOT rm -rf THE WORK DIRECTORY.  The obvious `shutil.rmtree(work)`
    # was written here and then removed: the first path tried already held a
    # 64 KB executable another agent had left in the shared scratchpad two days
    # earlier.  A tool that clears its own workspace clears whatever it was
    # pointed at.  Refuse instead, and say what is in the way.
    if os.path.exists(args.work):
        if not os.path.isdir(args.work):
            print("REFUSING: %s exists and is not a directory" % args.work, file=sys.stderr)
            return 2
        if os.listdir(args.work):
            print("REFUSING: %s is not empty -- point me at a fresh directory"
                  % args.work, file=sys.stderr)
            return 2
    os.makedirs(args.work, exist_ok=True)
    total = Counter()
    report = []
    refusals = []
    compiled = 0

    for n, (app, cat) in enumerate(catalogs):
        wd = os.path.join(args.work, "%03d" % n)
        shutil.rmtree(wd, ignore_errors=True)
        os.makedirs(wd)
        car, err = compile_catalog(cat, os.path.join(wd, "car"))
        label = "%s/%s" % (app, os.path.basename(cat))
        if car is None:
            # P7: named and counted, never absorbed into the denominator.
            refusals.append((label, err))
            continue
        o, err = oracle_rows(car)
        if o is None:
            refusals.append((label, err))
            continue
        r = run([sys.executable, TOOL, "index", cat, "--out", os.path.join(wd, "idx")])
        if r.returncode != 0:
            refusals.append((label, "reader refused: " + (r.stderr or "").strip().splitlines()[-1]))
            continue
        index = json.load(open(os.path.join(wd, "idx", "index.json")))
        compiled += 1
        total.update(compare(o, tool_rows(index), label, report))
        shutil.rmtree(os.path.join(wd, "car"), ignore_errors=True)

    print("catalogs found                  %4d" % len(catalogs))
    print("compiled by actool and scored   %4d" % compiled)
    empty = [x for x in refusals if x[1].startswith("EMPTY:")]
    failed = [x for x in refusals if not x[1].startswith("EMPTY:")]
    print("actool compiled to nothing      %4d   (no renditions for this platform)" % len(empty))
    print("actool or the reader FAILED     %4d" % len(failed))
    refusals = failed + empty
    for label, why in refusals[:25]:
        print("   REFUSED %-42s %s" % (label[-42:], (why or "")[:90]))
    if len(refusals) > 25:
        print("   ... %d more" % (len(refusals) - 25))

    # PRINT THE DISAGREEMENTS, DO NOT COUNT THEM.
    kinds = Counter(k for k, _, _, _ in report)
    if report:
        print("")
        for kind in sorted(kinds):
            rows = [r for r in report if r[0] == kind]
            print("-- %s: %d" % (kind, len(rows)))
            for _, cat, key, extra in rows[:12]:
                print("     %-46s %s %s" % (cat[-46:], key, extra))
            if len(rows) > 12:
                print("     ... %d more" % (len(rows) - 12))

    img_total = total["image_agree"] + total["image_scale_differs"] + \
        total["image_tool_only"] + total["image_oracle_only"] + \
        total["image_vector_expanded_by_actool"]
    col_total = total["color_agree"] + total["color_differs"] + \
        total["color_space_differs"] + total["color_arity_differs"] + \
        total["color_tool_only"] + total["color_oracle_only"]
    print("")
    print("IMAGE variants")
    print("  agree with actool             %5d of %d" % (total["image_agree"], img_total))
    print("    of which scaleless          %5d" % total["image_scaleless_matched"])
    print("  vector expanded by actool     %5d   (a compiler property, not a divergence)"
          % total["image_vector_expanded_by_actool"])
    print("  scale differs                 %5d   (must be 0)" % total["image_scale_differs"])
    print("  only in the tool              %5d   (must be 0)" % total["image_tool_only"])
    print("  only in actool                %5d   (must be 0)" % total["image_oracle_only"])
    dat_total = (total["data_agree"] + total["data_differs"]
                 + total["data_tool_only"] + total["data_oracle_only"])
    print("DATASETS  (no RenditionName from actool; compared on byte length)")
    print("  agree with actool             %5d of %d" % (total["data_agree"], dat_total))
    print("  byte length differs           %5d   (must be 0)" % total["data_differs"])
    print("  only in the tool              %5d   (must be 0)" % total["data_tool_only"])
    print("  only in actool                %5d   (must be 0)" % total["data_oracle_only"])
    print("COLOUR variants")
    print("  agree with actool             %5d of %d" % (total["color_agree"], col_total))
    print("  components differ             %5d   (must be 0)" % total["color_differs"])
    print("  colour space differs          %5d   (must be 0)" % total["color_space_differs"])
    print("  only in the tool              %5d   (must be 0)" % total["color_tool_only"])
    print("  only in actool                %5d   (must be 0)" % total["color_oracle_only"])
    print("EXCLUDED by pre-registration (EXPECTED.md), not scored")
    for k in sorted(total):
        if k.startswith("excluded_") and total[k]:
            print("  %-30s %5d" % (k[len("excluded_"):], total[k]))

    ok = (compiled > 0 and total["image_scale_differs"] == 0
          and total["data_differs"] == 0 and total["data_tool_only"] == 0
          and total["data_oracle_only"] == 0
          and total["image_tool_only"] == 0 and total["image_oracle_only"] == 0
          and total["color_differs"] == 0 and total["color_space_differs"] == 0
          and total["color_arity_differs"] == 0
          and total["color_tool_only"] == 0 and total["color_oracle_only"] == 0)
    print("")
    print("VERDICT: %s" % ("the reader and actool agree on every compared tuple."
                           if ok else "at least one condition failed."))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
