#!/usr/bin/env python3
"""build_fixture.py -- assemble the resolution-oracle fixture from the corpus.

    ./build_fixture.py <corpus> <index-dir> <out-dir>

Produces, in <out-dir>:

    Fixture.xcassets/          real corpus assets, copied whole
    CollideA.xcassets/         two catalogs defining ONE shared name, so that
    CollideB.xcassets/         "which definition wins" is an answerable question
    grid.json                  the pre-registered rows
    Candidates/               every candidate payload, by sha256

WHY A FIXTURE INSTEAD OF THE CORPUS CATALOGS.  Compiling all 176 catalogs and
resolving every asset would be a coverage sweep; this is an ALGORITHM oracle.
The grid is chosen to cover the SHAPES the census found, one row per shape per
trait combination, and it is small enough that every row can be printed.

RASTER ONLY, and that is a real exclusion rather than a convenience.  `actool`
rasterises a `.pdf` or `.svg` at every scale the target needs (5,032 of 8,900
image variants in #79), so what UIKit hands back for a vector asset is not the
source file and cannot hash-equal it.  Vector assets are therefore excluded
BY CONSTRUCTION here and, independently, would be caught by the probe's
identification check -- two defences because this one is easy to get wrong.
"""
import base64, glob, hashlib, json, os, shutil, sys
from collections import Counter, defaultdict

RASTER = {".png", ".jpg", ".jpeg"}


def load_indexes(index_dir):
    out = {}
    for f in sorted(glob.glob(os.path.join(index_dir, "*", "index.json"))):
        ix = json.load(open(f))
        out[ix["app"]] = (ix, os.path.dirname(f))
    return out


def asset_source_dir(corpus, app, catalogs, name, index):
    """Find the on-disk .imageset/.colorset directory for an index entry."""
    leaf = name.split("/")[-1]
    for cat in catalogs:
        for ext in (".imageset", ".colorset"):
            for root, dirs, _ in os.walk(os.path.join(corpus, app, cat)):
                for d in dirs:
                    if d == leaf + ext:
                        return os.path.join(root, d)
    return None


def shape_of(rec):
    """Classify an imageset by the census shapes the grid has to cover."""
    vs = rec["variants"]
    scales = {v.get("scale") for v in vs}
    apps = {v["appearance"] for v in vs}
    idioms = {v["idiom"] for v in vs}
    exts = {v["payload"]["ext"] for v in vs}
    if not exts <= RASTER:
        return None
    tags = []
    if scales == {1, 2, 3}:
        tags.append("scale-all-three")
    elif scales == {1, 2}:
        tags.append("scale-1-2-only")       # a 3x device must fall DOWN
    elif scales == {1, 3} or scales == {2, 3}:
        tags.append("scale-gap")            # a 2x device must fall UP or DOWN
    if scales == {None}:
        tags.append("scaleless")
    if apps & {"dark"}:
        tags.append("appearance-dark")
    if apps & {"light"}:
        tags.append("appearance-light")
    if idioms - {"universal"}:
        tags.append("idiom-specific")
    # `resizing` carries cap insets, and the census found BOTH spellings in the
    # same corpus -- `cap-insets` (WordPress, Telegram) and `capInsets`
    # (eidolon, Telegram).  A reader keyed on one drops the other silently, so
    # the grid has to carry one of each and `UIImage.capInsets` has to confirm
    # the numbers survived.
    for v in vs:
        r = v.get("resizing")
        if r:
            tags.append("resizing-%s" % (r.get("insets_spelling") or "none"))
            break
    return tags or None


def main():
    corpus, index_dir, out = sys.argv[1], sys.argv[2], sys.argv[3]
    if os.path.exists(out) and os.listdir(out):
        print("REFUSING: %s is not empty -- point me at a fresh directory" % out,
              file=sys.stderr)
        return 2
    os.makedirs(out, exist_ok=True)

    indexes = load_indexes(index_dir)
    QUOTA = {"scale-all-three": 6, "scale-1-2-only": 4, "scale-gap": 4,
             "scaleless": 6, "appearance-dark": 8, "appearance-light": 3,
             "idiom-specific": 6, "resizing-cap-insets": 3,
             "resizing-capInsets": 3, "resizing-none": 2}
    picked, have = [], Counter()
    colours, colour_have = [], Counter()

    for app, (ix, _) in sorted(indexes.items()):
        for name, rec in sorted(ix["assets"].items()):
            if rec["type"] == "imageset":
                tags = shape_of(rec)
                if not tags:
                    continue
                if not any(have[t] < QUOTA[t] for t in tags):
                    continue
                src = asset_source_dir(corpus, app, ix["catalogs"], name, ix)
                if src is None:
                    continue
                picked.append((app, name, rec, tags, src))
                have.update(tags)
            elif rec["type"] == "colorset":
                # one per (encoding, colour space), so all four encodings and
                # all four spaces the census found are represented
                for v in rec["variants"]:
                    if v.get("srgb") is None:
                        continue
                    encs = tuple(sorted(set((v.get("encodings") or {}).values())))
                    key = (encs, v["color_space"])
                    if colour_have[key] >= 2:
                        continue
                    src = asset_source_dir(corpus, app, ix["catalogs"], name, ix)
                    if src is None:
                        continue
                    colours.append((app, name, rec, key, src))
                    colour_have[key] += 1
                    break

    # ---- assemble the fixture catalog ---------------------------------
    fx = os.path.join(out, "Fixture.xcassets")
    os.makedirs(fx)
    json.dump({"info": {"author": "xcode", "version": 1}},
              open(os.path.join(fx, "Contents.json"), "w"))
    cand = os.path.join(out, "Candidates")
    os.makedirs(cand)

    rows = []
    used_names = set()
    seen_payload = set()

    def emit(app, name, rec, src, kind, tags):
        # Fixture names are prefixed with the app so that assets from different
        # apps cannot collide inside the one catalog -- collisions are tested
        # deliberately, below, and must not arrive by accident here.
        fname = "%s_%s" % (app.replace("-", "_"), name.split("/")[-1])
        if fname in used_names:
            return None
        used_names.add(fname)
        dst = os.path.join(fx, fname + os.path.splitext(src)[1])
        shutil.copytree(src, dst)
        cands = []
        for v in rec["variants"]:
            if kind == "colour":
                # Colour variants have no payload file at all -- the value IS
                # the data.  They are identified by their resolved components,
                # not by a pixel hash, so they take a different route through
                # the probe entirely.
                cands.append({"idiom": v["idiom"], "appearance": v["appearance"],
                              "native": v.get("native"), "srgb": v.get("srgb"),
                              "color_space": v.get("color_space"),
                              "encodings": v.get("encodings")})
                continue
            p = v["payload"]
            if p["sha256"] not in seen_payload:
                shutil.copyfile(os.path.join(os.path.dirname(src), os.path.basename(src),
                                             p["filename"]),
                                os.path.join(cand, p["sha256"] + p["ext"]))
                seen_payload.add(p["sha256"])
            cands.append({"sha256": p["sha256"], "file": p["sha256"] + p["ext"],
                          "filename": p["filename"], "idiom": v["idiom"],
                          "appearance": v["appearance"], "scale": v.get("scale"),
                          "resizing": v.get("resizing")})
        rows.append({"asset": fname, "kind": kind, "origin_app": app,
                     "origin_name": name, "shapes": tags, "candidates": cands})
        return fname

    for app, name, rec, tags, src in picked:
        emit(app, name, rec, src, "image", tags)
    for app, name, rec, key, src in colours:
        emit(app, name, rec, src, "colour", ["colour:%s:%s" % (",".join(key[0]), key[1])])

    # ---- the two shapes the REAL corpus cannot supply -----------------
    #
    # DENOMINATED SEPARATELY, as in #77.  Measured on the selection above:
    # the corpus's 11 explicit `light` entries (3 apps) are all on assets that
    # raster-only selection excludes, and no raster imageset ships {1x,3x}
    # with 2x absent.  Both are core to the algorithm -- `light` is step 3's
    # whole point and a 1x/3x gap is the only way to observe step 4 falling
    # UP -- so they are constructed here and labelled `synthetic`, never
    # counted with the real rows.
    for nm, entries, colours, tag in [
        ("SynLightDark",
         [("any2", "2x", None), ("light2", "2x", "light"), ("dark2", "2x", "dark")],
         [(200, 200, 200, 255), (30, 60, 90, 255), (240, 120, 10, 255)],
         "syn-appearance-light"),
        ("SynScaleGap13",
         [("g1", "1x", None), ("g3", "3x", None)],
         [(11, 22, 33, 255), (99, 88, 77, 255)],
         "syn-scale-gap-1-3"),
    ]:
        d = os.path.join(fx, nm + ".imageset")
        os.makedirs(d)
        imgs, cands = [], []
        for (fn, scale, app_), rgba in zip(entries, colours):
            png = make_png(rgba)
            open(os.path.join(d, fn + ".png"), "wb").write(png)
            e = {"idiom": "universal", "scale": scale, "filename": fn + ".png"}
            if app_:
                e["appearances"] = [{"appearance": "luminosity", "value": app_}]
            imgs.append(e)
            h = hashlib.sha256(png).hexdigest()
            if h not in seen_payload:
                open(os.path.join(cand, h + ".png"), "wb").write(png)
                seen_payload.add(h)
            cands.append({"sha256": h, "file": h + ".png", "filename": fn + ".png",
                          "idiom": "universal", "appearance": app_ or "any",
                          "scale": int(scale[0])})
        json.dump({"images": imgs, "info": {"author": "xcode", "version": 1}},
                  open(os.path.join(d, "Contents.json"), "w"))
        rows.append({"asset": nm, "kind": "image", "origin_app": "-",
                     "origin_name": "synthetic", "shapes": [tag, "synthetic"],
                     "candidates": cands})

    # ---- the collision fixture ---------------------------------------
    # Two catalogs, ONE shared asset name, compiled together.  The index
    # records both definitions and refuses to pick; this asks actool and UIKit
    # what they do, which is a question the index cannot answer from source
    # alone and which INDEX_FORMAT.md currently leaves to the consumer.
    coll = []
    for tag, colour in (("CollideA", (255, 0, 0, 255)), ("CollideB", (0, 0, 255, 255))):
        d = os.path.join(out, tag + ".xcassets", "Collide.imageset")
        os.makedirs(d)
        json.dump({"info": {"author": "xcode", "version": 1}},
                  open(os.path.join(out, tag + ".xcassets", "Contents.json"), "w"))
        png = make_png(colour)
        fn = "%s.png" % tag.lower()
        open(os.path.join(d, fn), "wb").write(png)
        json.dump({"images": [{"idiom": "universal", "scale": "2x", "filename": fn}],
                   "info": {"author": "xcode", "version": 1}},
                  open(os.path.join(d, "Contents.json"), "w"))
        h = hashlib.sha256(png).hexdigest()
        open(os.path.join(cand, h + ".png"), "wb").write(png)
        coll.append({"sha256": h, "file": h + ".png", "filename": fn,
                     "idiom": "universal", "appearance": "any", "scale": 2,
                     "catalog": tag})
    rows.append({"asset": "Collide", "kind": "collision", "origin_app": "-",
                 "origin_name": "-", "shapes": ["name-collision"],
                 "candidates": coll})

    json.dump({"rows": rows}, open(os.path.join(out, "grid.json"), "w"),
              indent=1, sort_keys=True)

    print("fixture assets      %4d  (%d image, %d colour, 1 collision)"
          % (len(rows), sum(1 for r in rows if r["kind"] == "image"),
             sum(1 for r in rows if r["kind"] == "colour")))
    print("candidate payloads  %4d" % len(seen_payload))
    print("shape coverage:")
    for t, n in sorted(have.items()):
        print("   %-20s %d" % (t, n))
    print("colour coverage (encodings, space):")
    for k, n in sorted(colour_have.items()):
        print("   %-40s %d" % (str(k), n))
    return 0


def make_png(rgba, w=8, h=8):
    import struct, zlib
    def chunk(t, d):
        c = t + d
        return struct.pack(">I", len(d)) + c + struct.pack(">I", zlib.crc32(c) & 0xffffffff)
    raw = b"".join(b"\x00" + bytes(rgba) * w for _ in range(h))
    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


if __name__ == "__main__":
    sys.exit(main())
