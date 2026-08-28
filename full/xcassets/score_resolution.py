#!/usr/bin/env python3
"""score_resolution.py -- does the index choose what UIKit chose?

    ./score_resolution.py <fixture-dir> <results-dir>

The probe reported, for each (asset, idiom, appearance) on each device, the
DISTANCE from UIKit's returned image to every candidate payload. This asks
`xcassets_tool.resolve` — the algorithm specified in INDEX_FORMAT.md — the same
question and compares the two answers.

The algorithm under test was never in the probe's process: the probe does not
know it and does not compare anything. Predictions are in
EXPECTED_RESOLUTION.md, committed before either file existed.
"""
import glob, json, os, sys
from collections import Counter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from xcassets_tool import resolve            # the specification under test

# ---------------------------------------------------------------------------
# IDENTIFICATION THRESHOLDS, SET FROM MEASURED DATA, NOT CHOSEN.
#
# `actool` re-encodes payloads, so UIKit's returned image is NOT byte-identical
# to the source file for most real assets — exact hashing identified only 33 of
# 92 rows on the first run. Measured over 276 rows and 69 same-size candidate
# pairs, in mean-absolute-difference per byte (0..255):
#
#     UIKit vs the nearest candidate      max  0.2817   median 0.0075
#     any two same-size candidates        min 49.5000   median 117.63
#
# A 176x margin. IDENTIFY_MAX is 7x the worst observed match and MARGIN_MIN is
# a fifth of the closest observed pair, so both have room and neither is at a
# boundary. Different-DIMENSION candidates need no threshold at all: they are
# separated by their size, which for the scale axis is the answer itself.
IDENTIFY_MAX = 2.0
MARGIN_MIN = 10.0

# Component tolerance. UIColor round-trips through CGColor; measured agreement
# on the display-p3 rows is ~3e-5, so 1e-3 is loose enough to be about the
# colour and tight enough to catch a wrong variant (variants differ by ~0.1+).
COMPONENT_TOL = 1e-3


def as_asset(row):
    """Grid candidates -> the shape `resolve` expects."""
    vs = []
    for c in row["candidates"]:
        v = {"idiom": c["idiom"], "appearance": c["appearance"], "scale": c.get("scale")}
        if row["kind"] == "colour":
            v.update({"native": c.get("native"), "srgb": c.get("srgb"),
                      "color_space": c.get("color_space")})
        else:
            v["payload"] = {"sha256": c["sha256"], "filename": c["filename"]}
            v["resizing"] = c.get("resizing")
        vs.append(v)
    return {"type": row["kind"], "variants": vs}


def identify(dists):
    """-> (sha, why). The nearest same-dimension candidate, if it is near
    enough AND far enough ahead of the runner-up."""
    same = sorted([d for d in dists if d.get("dims_match") and d.get("mad") is not None],
                  key=lambda d: d["mad"])
    if not same:
        return None, "no candidate has the returned image's dimensions"
    if same[0]["mad"] > IDENTIFY_MAX:
        return None, "nearest candidate is %.3f away (limit %.1f)" % (same[0]["mad"], IDENTIFY_MAX)
    if len(same) > 1 and same[1]["mad"] - same[0]["mad"] < MARGIN_MIN:
        return None, ("nearest %.3f and runner-up %.3f are within %.1f"
                      % (same[0]["mad"], same[1]["mad"], MARGIN_MIN))
    return same[0]["sha256"], "mad %.4f" % same[0]["mad"]


def expected_components(v):
    """What UIKit's getRed:green:blue:alpha: should report, per colour space.

    MEASURED, and it CORRECTS this oracle's own pre-registration (P4, which
    said the index's `srgb` field could not be corroborated by any oracle):

      * srgb / extended-srgb -> the native components, unchanged.
      * display-p3           -> the index's OWN sRGB CONVERSION. UIColor's
        `getRed:` converts out of P3 (while `cgColor.colorSpace` still reports
        DisplayP3), and it agrees with `to_srgb()` to ~3e-5 on every P3 row.
        So the P3 matrix IS corroborated after all, which #79 said no oracle
        could do.
      * gray-gamma-22        -> the native WHITE value replicated, NOT the
        conversion. UIKit does not gamma-convert here; it reports the gray
        component in all three channels. `to_srgb()` returns 0.902873 for a
        white of 0.9 and UIKit reports 0.9. Neither is wrong -- one is a
        colour-managed conversion and the other is component reporting -- but a
        consumer that wants to MATCH UIKit must use `native`.
    """
    space = v.get("color_space")
    if space == "gray-gamma-22":
        n = v.get("native") or []
        if len(n) != 2:
            return None, "gray native is not [white, alpha]"
        return [n[0], n[0], n[0], n[1]], "native white replicated"
    if space == "display-p3":
        return v.get("srgb"), "index's own P3->sRGB conversion"
    return v.get("native"), "native components"


def main():
    fixture, results_dir = sys.argv[1], sys.argv[2]
    grid = {r["asset"]: r for r in json.load(open(os.path.join(fixture, "grid.json")))["rows"]}
    files = sorted(glob.glob(os.path.join(results_dir, "resolution_*.json")))
    if not files:
        print("REFUSING: no result files in %s" % results_dir, file=sys.stderr)
        return 2

    st = Counter()
    fails, colour_fails, notes = [], [], []
    undecidable, devices = {}, []
    sep_min = None

    for f in files:
        d = json.load(open(f))
        devices.append((d["device_scale"], d["device_idiom"], len(d["results"])))
        undecidable.update(d.get("undecidable") or {})
        # INSTRUMENT CHECK 1: same-size candidates of one asset must be far
        # apart, or a row on that asset passes no matter what UIKit returns.
        for asset, seps in (d.get("candidate_separation") or {}).items():
            for s in seps:
                m = s.get("mad")
                if m is None:
                    continue
                sep_min = m if sep_min is None else min(sep_min, m)
                if m < MARGIN_MIN:
                    undecidable[asset] = ("two same-size candidates are only %.3f apart" % m)

        for r in d["results"]:
            row = grid.get(r["asset"])
            if row is None:
                st["result_without_grid_row"] += 1
                continue
            scale = int(d["device_scale"])
            ask = "%s/%s/%dx" % (r["ask_idiom"], r["ask_appearance"], scale)

            if row["kind"] == "collision":
                st["collision_rows"] += 1
                sha, _ = identify(r.get("distances") or [])
                notes.append(("COLLISION (no prediction registered)", r["asset"], ask,
                              "UIKit returned %s" % _name(row, sha)))
                continue

            if r.get("error"):
                st["uikit_returned_nothing"] += 1
                fails.append(("UIKit returned nothing", r["asset"], ask, r["error"]))
                continue

            # ---- colours ------------------------------------------------
            if row["kind"] == "colour":
                got = r.get("components")
                if got is None:
                    st["colour_no_components"] += 1
                    fails.append(("no components from UIColor", r["asset"], ask, ""))
                    continue
                v, _ = resolve(as_asset(row), scale=scale,
                               appearance=r["ask_appearance"], idiom=r["ask_idiom"])
                if v is None:
                    st["colour_index_no_match"] += 1
                    fails.append(("index resolved nothing", r["asset"], ask, ""))
                    continue
                if v.get("srgb") is None and v.get("native") is None:
                    # A system-colour reference. #79 established the index
                    # cannot resolve these (the palette is not in the catalog)
                    # and records them instead. actool CAN. Excluded on both
                    # sides, counted, named -- never scored as a difference.
                    st["colour_system_reference"] += 1
                    continue
                want, how = expected_components(v)
                if want is None:
                    st["colour_no_expectation"] += 1
                    fails.append(("no comparable components", r["asset"], ask, how))
                    continue
                st["colour_scored"] += 1
                st["colour_by_%s" % (v.get("color_space") or "?")] += 1
                if len(want) == len(got) and all(abs(a - b) <= COMPONENT_TOL
                                                 for a, b in zip(want, got)):
                    st["colour_agree"] += 1
                else:
                    st["colour_differs"] += 1
                    colour_fails.append((r["asset"], ask, v.get("color_space"), how, want, got))
                continue

            # ---- images -------------------------------------------------
            if r["ask_idiom"] == "unspecified":
                # NOT A STATE AN APP CAN BE IN.  `UITraitCollection
                # .userInterfaceIdiom` on a real device is phone, pad or mac;
                # `.unspecified` was asked out of thoroughness and measures
                # something else entirely -- UIKit substitutes the DEVICE's
                # idiom, so on an iPad it returned `...~ipad.png` where the
                # index, asked for an idiom named "unspecified", correctly
                # found no exact match and fell back to universal (or, for
                # assets with no universal variant, to nothing at all).
                # Excluded and counted, with the finding recorded, rather than
                # scored as 24 divergences that are really one artefact of the
                # question.
                st["ask_unspecified_excluded"] += 1
                sha, _ = identify(r.get("distances") or [])
                notes.append(("ASK .unspecified -- UIKit substitutes the device idiom",
                              r["asset"], ask,
                              "UIKit returned %s on a %s device"
                              % (_name(row, sha), d["device_idiom"])))
                continue
            if r["asset"] in undecidable:
                st["undecidable_rows"] += 1
                continue
            sha, why = identify(r.get("distances") or [])
            if sha is None:
                # RESIZABLE ASSETS CANNOT BE PIXEL-IDENTIFIED, and the check
                # caught it rather than guessing.  Measured: Telegram's
                # `BubbleNotification` has a 53x124 source and UIKit returns
                # 53x117 -- `actool` COLLAPSES the stretchable region of a
                # 9-part image, so the stored rendition is not the source
                # bitmap at all.  Named here so the class is visible instead of
                # being a bare "unidentified" count.
                if any((c.get("resizing") or {}).get("cap_insets")
                       for c in row["candidates"]):
                    st["unidentified_resizable"] += 1
                # INSTRUMENT failure, not a disagreement: this row cannot
                # decide anything and is never counted as agreement.
                st["unidentified"] += 1
                notes.append(("UNIDENTIFIED (instrument, not scored)", r["asset"], ask, why))
                continue
            st["identified"] += 1
            if r.get("match_kind") == "exact":
                st["identified_exact"] += 1
            v, trace = resolve(as_asset(row), scale=scale,
                               appearance=r["ask_appearance"], idiom=r["ask_idiom"])
            if v is None:
                st["index_no_match"] += 1
                fails.append(("index resolved nothing", r["asset"], ask,
                              "UIKit chose %s" % _name(row, sha)))
                continue
            st["image_scored"] += 1
            # CAP INSETS.  Checked on the rows that have them, because the
            # census found BOTH `cap-insets` and `capInsets` in one corpus and
            # a reader keyed on one spelling drops the other in silence.
            # `UIImage.capInsets` is what UIKit built from the compiled
            # catalog, so it confirms the numbers survived the parse.
            rz = (v.get("resizing") or {}).get("cap_insets")
            if rz:
                st["capinsets_scored"] += 1
                st["capinsets_by_%s" % ((v["resizing"] or {}).get("insets_spelling") or "?")] += 1
                # CAP INSETS ARE PIXELS IN Contents.json AND POINTS IN UIImage.
                # Measured: Telegram's chat bubbles declare
                # {top 26, left 26, bottom 32, right 26} on a 2x variant and
                # `UIImage.capInsets` reports {13, 13, 16, 13} -- exactly half.
                # So the stored numbers are in the VARIANT's pixels and UIKit
                # divides by its scale.
                #
                # SCOPE: every resizing asset in the corpus that survives
                # raster-only selection is 2x-only, so "divide by the chosen
                # variant's scale" and "divide by 2" are not distinguishable
                # from this data.  The former is stated because it is the only
                # reading consistent with points being scale-independent, and
                # it is flagged as observed at 2x only.
                vscale = v.get("scale") or 1
                got_ci = r.get("cap_insets") or {}
                want_ci = {k: float(rz.get(k) or 0) / vscale
                           for k in ("top", "left", "bottom", "right")}
                have_ci = {k: float(got_ci.get(k) or 0) for k in ("top", "left", "bottom", "right")}
                if want_ci == have_ci:
                    st["capinsets_agree"] += 1
                else:
                    st["capinsets_differ"] += 1
                    fails.append(("CAP INSETS differ", r["asset"], ask,
                                  "index/%dx %s | UIKit %s" % (vscale, want_ci, have_ci)))
            if v["payload"]["sha256"] == sha:
                st["image_agree"] += 1
            else:
                st["image_differs"] += 1
                fails.append(("CHOSE A DIFFERENT VARIANT", r["asset"], ask,
                              "index %s | UIKit %s | %s"
                              % (v["payload"]["filename"], _name(row, sha), "; ".join(trace))))

    # ---- report -------------------------------------------------------
    print("devices")
    for s, i, n in devices:
        print("   scale %-4s idiom %-7s results %4d" % (s, i, n))
    print("   1x is unreachable: no 1x simulator device exists")
    print("")
    print("INSTRUMENT CHECKS, before any scoreboard")
    print("   closest same-size candidate pair    %8.3f   (must exceed %.1f)"
          % (sep_min if sep_min is not None else -1, MARGIN_MIN))
    print("   assets ruled undecidable            %8d   %s"
          % (len(undecidable), list(undecidable)[:3] if undecidable else ""))
    print("   image rows identified               %8d of %d"
          % (st["identified"], st["identified"] + st["unidentified"]))
    print("     of which byte-exact               %8d   (the rest actool re-encoded)"
          % st["identified_exact"])
    print("   image rows unidentified, NOT scored  %7d" % st["unidentified"])
    print("     of which resizable (actool re-slices) %5d" % st["unidentified_resizable"])

    for bucket, rows in (("", fails),):
        for kind in sorted({f[0] for f in rows}):
            sel = [f for f in rows if f[0] == kind]
            print("")
            print("-- %s: %d" % (kind, len(sel)))
            for _, a, ask, extra in sel[:16]:
                print("     %-34s %-22s %s" % (a[:34], ask, extra))
            if len(sel) > 16:
                print("     ... %d more" % (len(sel) - 16))
    if colour_fails:
        print("")
        print("-- COLOUR components differ: %d" % len(colour_fails))
        for a, ask, space, how, want, got in colour_fails[:16]:
            print("     %-34s %-22s %s (%s)" % (a[:34], ask, space, how))
            print("       index %s" % [round(x, 6) for x in (want or [])])
            print("       UIKit %s" % [round(x, 6) for x in got])
    if notes:
        for kind in sorted({n[0] for n in notes}):
            sel = [n for n in notes if n[0] == kind]
            print("")
            print("-- %s: %d" % (kind, len(sel)))
            seen = set()
            for _, a, ask, extra in sel:
                if (a, extra) in seen:
                    continue
                seen.add((a, extra))
                print("     %-34s %-22s %s" % (a[:34], ask, extra))
                if len(seen) >= 10:
                    print("     ... (%d rows in this class)" % len(sel))
                    break

    print("")
    print("IMAGES    agree with UIKit    %4d of %d" % (st["image_agree"], st["image_scored"]))
    print("          chose differently   %4d   (must be 0)" % st["image_differs"])
    print("          index found none    %4d   (must be 0)" % st["index_no_match"])
    print("CAP INSETS agree with UIKit  %4d of %d" % (st["capinsets_agree"], st["capinsets_scored"]))
    print("          differ              %4d   (must be 0)" % st["capinsets_differ"])
    for k in sorted(st):
        if k.startswith("capinsets_by_"):
            print("          by spelling: %-13s %4d" % (k[len("capinsets_by_"):], st[k]))
    print("COLOURS   agree with UIKit    %4d of %d" % (st["colour_agree"], st["colour_scored"]))
    print("          differ              %4d   (must be 0)" % st["colour_differs"])
    for k in sorted(st):
        if k.startswith("colour_by_"):
            print("          by space: %-16s %4d" % (k[len("colour_by_"):], st[k]))
    print("          system references   %4d   (excluded: the palette is not in the catalog)"
          % st["colour_system_reference"])
    print("COLLISION rows recorded       %4d   (no prediction registered)" % st["collision_rows"])
    print("EXCLUDED  ask .unspecified    %4d   (not a state an app can be in)"
          % st["ask_unspecified_excluded"])

    # THE VACUOUS CASE REFUSES. A scoreboard over zero decidable rows is a run
    # that measured nothing, and it must not read as a pass.
    if st["image_scored"] == 0 or st["colour_scored"] == 0:
        print("")
        print("REFUSING: %d image and %d colour rows were decidable -- nothing was measured."
              % (st["image_scored"], st["colour_scored"]))
        return 2

    ok = (st["image_differs"] == 0 and st["index_no_match"] == 0
          and st["capinsets_differ"] == 0
          and st["colour_differs"] == 0 and st["uikit_returned_nothing"] == 0
          and st["colour_no_expectation"] == 0)
    print("")
    print("VERDICT: %s" % ("the index chooses what UIKit chooses on every decidable row."
                           if ok else "at least one condition failed."))
    return 0 if ok else 1


def _name(row, sha):
    if sha is None:
        return "<unidentified>"
    for c in row["candidates"]:
        if c.get("sha256") == sha:
            return c.get("filename") or sha[:12]
    return sha[:12]


if __name__ == "__main__":
    sys.exit(main())
