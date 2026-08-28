#!/usr/bin/env python3
"""xcassets_tool.py -- read SOURCE-FORM .xcassets and emit a flat resource
directory plus a resolution index.

    ./xcassets_tool.py index <app-dir> --out <dir> [--strict]
    ./xcassets_tool.py resolve <index.json> <name> [--scale 2] [--appearance dark] [--idiom phone]

SCOPE, stated first because half of this format is out of it.

  * INPUT IS SOURCE FORM ONLY -- directories, `Contents.json`, and the png /
    pdf / jpg / svg payloads beside them.  The compiled `.car` produced by
    `actool` is PROPRIETARY AND OUT OF SCOPE, deliberately: this project
    recompiles apps from source, so the source form is the input we actually
    have.  `actool` and `assetutil` are used in `spot_oracle.py` as an ORACLE,
    never as a dependency of this tool.

  * The COVERED asset types are `.imageset`, `.colorset`, `.appiconset`,
    `.dataset`, `.symbolset`, namespace folders and the catalog root.  Measured
    over the 20-app ladder corpus those are 7,470 of 8,046 asset directories.
    Every other type -- `.sticker`, `.imagestack`, `.brandassets`,
    `.complicationset`, `.launchimage`, ... -- is RECORDED, NOT RESOLVED: it
    appears in the index under `unresolved` with its type and its payload
    files, so a consumer that asks for one gets a refusal naming the type
    rather than a wrong answer.  The counts are printed, never hidden.

  * SYMBOLSET IS RECORD-NOT-RESOLVE, and the measurement is why: 27 symbolsets
    across 9 of 20 apps, and every one is a `.svg` payload whose rendering
    needs a symbol engine this project does not have.  The index carries the
    file so nothing is lost; it does not claim to resolve it.

REFUSAL IS THE DEFAULT.  Every key this reader meets must be in a table below,
and an unknown one aborts naming the file, the key and the asset.  A reader
that skips what it does not understand produces a silently wrong render three
layers away -- the `succeeds-and-does-nothing` failure this project has already
paid for more than once.  `--strict` additionally turns the recorded-not-
resolved types into refusals, for a caller that wants all-or-nothing.
"""
import argparse, hashlib, json, os, re, shutil, sys
from collections import Counter, defaultdict

# ---------------------------------------------------------------------------
# THE KEY TABLES ARE THE CENSUS, TRANSCRIBED.  Every name below was MEASURED in
# `xcassets-census-2026-08-27.json` over 176 catalogs and 8,216 Contents.json
# in the 20 pinned apps; the comment on each is its (uses / apps-of-20).  This
# is the `~171` move: the documented format is much larger than the part twenty
# shipping apps use, and the reader implements the measured part and refuses
# the rest.
# ---------------------------------------------------------------------------

COVERED = {".imageset", ".colorset", ".appiconset", ".dataset", ".symbolset"}

TOP_KEYS = {
    ".imageset":    {"images", "info", "properties"},        # 6785/20, 6785/20, 3113/17
    ".colorset":    {"colors", "info"},                      # 510/17
    ".appiconset":  {"images", "info", "properties"},        # 146/19, 146/19, 3/1
    ".dataset":     {"data", "info"},                        # 2/2
    ".symbolset":   {"symbols", "info", "properties"},       # 27/9, 27/9, 4/1
    "<folder>":     {"info", "properties"},                  # 510/16, 143/6
    ".xcassets":    {"info", "properties"},                  # 170/20, 2/1
}

ENTRY_KEYS = {
    ".imageset": {
        "idiom",              # 11004/20
        "filename",           #  9166/20  -- ABSENT on 1828 entries; see below
        "scale",              #  5932/19  -- ABSENT on 5122 entries; see below
        "appearances",        #   370/14
        "screen-width",       #   100/3
        "language-direction", #    14/3
        "resizing",           #    11/3
        "height-class",       #     2/1
    },
    ".colorset":   {"idiom", "color", "appearances"},        # 886, 866, 376
    ".appiconset": {"idiom", "size", "filename", "scale", "platform",
                    "role", "subtype", "appearances"},       # 1218,1218,1025,1007,226,88,74,116
    ".dataset":    {"idiom", "filename"},                    # 2/2
    ".symbolset":  {"idiom", "filename"},                    # 27/9
}

INFO_KEYS = {"author", "version", "template-rendering-intent"}   # the third: 5/1

PROPERTY_KEYS = {
    "preserves-vector-representation",          # 1561/16
    "template-rendering-intent",                # 2452/16
    "compression-type",                         #    2/1
    "localizable",                              #    1/1
    "provides-namespace",                       #  143/6   (folders)
    "pre-rendered",                             #    3/1   (appiconset)
    "symbol-rendering-intent",                  #    4/1   (symbolset)
    "generate-swift-asset-symbol-extensions",   #    2/1   (catalog root)
}

COLOR_KEYS = {"color-space", "components", "platform", "reference"}   # 852,852,13,14
COMPONENT_KEYS = {"red", "green", "blue", "alpha", "white"}           # 850x3, 852, 2
APPEARANCE_KEYS = {"appearance", "value"}

# Value spaces, all measured.  An unknown value refuses exactly like an unknown
# key: "we handle `idiom`" means nothing without knowing which idioms occur.
IDIOMS = {"universal", "ipad", "iphone", "watch", "tv", "ios-marketing", "mac",
          "car", "watch-marketing", "vision"}
SCALES = {"1x", "2x", "3x"}
APPEARANCE_NAMES = {"luminosity"}                       # 862/16, the only one
APPEARANCE_VALUES = {"dark", "light", "tinted"}         # 793/16, 11/3, 58/7
COLOR_SPACES = {"srgb", "display-p3", "extended-srgb", "gray-gamma-22"}
LANGUAGE_DIRECTIONS = {"left-to-right", "right-to-left"}
HEIGHT_CLASSES = {"compact", "regular"}
RESIZING_MODES = {"9-part", "3-part-horizontal", "3-part-vertical"}
CENTER_MODES = {"stretch", "fill", "tile"}

PAYLOAD_EXT = {".png", ".jpg", ".jpeg", ".pdf", ".svg", ".gif", ".json",
               ".heic", ".webp", ".data", ".plist", ".mp3", ".m4a", ".caf"}


class Refusal(Exception):
    """Raised instead of skipping.  Carries the file so the message is
    actionable -- `succeeds-and-does-nothing` starts with an error that does
    not say where."""


def refuse(path, msg):
    raise Refusal("%s\n    in %s" % (msg, path))


# ---------------------------------------------------------------------------
# Colour components.
#
# FOUR ENCODINGS OCCUR, all written as JSON STRINGS, and the classification is
# PER VALUE rather than per dictionary.  Measured:
#
#     decimal "0.5"   449 rgb triples / 11 apps      -> float, already 0..1
#     hex     "0xB4"  366 rgb triples /  9 apps      -> /255
#     integer "189"    ~32 triples    /  4 apps      -> /255
#     "0" / "1"          9 values     /  1 app       -> AMBIGUOUS in isolation
#
# The nine ambiguous values are NetNewsWire's account-icon colours, and they
# are not ambiguous in context: `{"red":"1","green":"123","blue":"199"}` is one
# integer triple, and `alpha` in the SAME dictionary is written `"1.000"`.  So
# Xcode writes alpha as a float beside integer components, which rules out any
# per-dictionary rule.  PRE-REGISTERED: a value containing `.` is a float, a
# value starting with `0x` is hex/255, anything else is an integer/255 -- and
# `spot_oracle.py` checks exactly this against `assetutil`, which is Apple's
# own resolution of the same file.
# ---------------------------------------------------------------------------
_HEX = re.compile(r"^0[xX][0-9a-fA-F]+$")


def component_value(raw, path, key):
    if isinstance(raw, (int, float)) and not isinstance(raw, bool):
        s = repr(raw)
    elif isinstance(raw, str):
        s = raw.strip()
    else:
        refuse(path, "component %r has non-scalar value %r" % (key, raw))
    if _HEX.match(s):
        return int(s, 16) / 255.0, "hex"
    if "." in s or "e" in s.lower():
        try:
            return float(s), "float"
        except ValueError:
            refuse(path, "component %r is not a number: %r" % (key, raw))
    try:
        return int(s) / 255.0, "int255"
    except ValueError:
        refuse(path, "component %r is not a number: %r" % (key, raw))


# sRGB transfer function, both directions.  Used only for the colour spaces
# that are not already sRGB-encoded.
def _srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _linear_to_srgb(c):
    if c <= 0.0031308:
        return c * 12.92
    return 1.055 * (abs(c) ** (1 / 2.4)) * (1 if c >= 0 else -1) - 0.055


# Display P3 -> sRGB, via XYZ (D65 for both, so no chromatic adaptation).
# Matrix is P3-to-XYZ followed by XYZ-to-sRGB, multiplied out.
_P3_TO_SRGB = (
    ( 1.2249401762805587, -0.2249401762805586,  0.0),
    (-0.0420569547346552,  1.0420569547346551,  0.0),
    (-0.0196375657176094, -0.0786360655913931,  1.0982736313090025),
)


def to_srgb(space, comps, path):
    """Return (r, g, b, a) in sRGB-encoded 0..1, plus a note about how."""
    a = comps.get("alpha", 1.0)
    if space in ("srgb", "extended-srgb"):
        # Same primaries and the same transfer function; extended-srgb merely
        # permits values outside 0..1 and they are kept, not clamped -- a clamp
        # here would silently change the colour of a wide-gamut asset.
        return (comps.get("red", 0.0), comps.get("green", 0.0),
                comps.get("blue", 0.0), a), space
    if space == "gray-gamma-22":
        w = comps.get("white")
        if w is None:
            refuse(path, "gray-gamma-22 colour has no `white` component")
        lin = w ** 2.2
        v = _linear_to_srgb(lin)
        return (v, v, v, a), "gray-gamma-22 -> sRGB (gamma 2.2 decode)"
    if space == "display-p3":
        lin = [_srgb_to_linear(comps.get(k, 0.0)) for k in ("red", "green", "blue")]
        out = []
        for row in _P3_TO_SRGB:
            out.append(_linear_to_srgb(sum(m * v for m, v in zip(row, lin))))
        return (out[0], out[1], out[2], a), "display-p3 -> sRGB (D65, no adaptation)"
    refuse(path, "unknown color-space %r" % space)


# ---------------------------------------------------------------------------
# Reading
# ---------------------------------------------------------------------------
def check_keys(doc, allowed, path, what):
    for k in doc:
        if k not in allowed:
            refuse(path, "unknown %s key %r (allowed: %s)"
                   % (what, k, ", ".join(sorted(allowed))))


def check_value(val, allowed, path, what):
    if val not in allowed:
        refuse(path, "unknown %s value %r (allowed: %s)"
               % (what, val, ", ".join(sorted(allowed))))


def read_appearances(entry, path):
    """-> 'any' | 'light' | 'dark' | 'tinted'.

    An entry with no `appearances` is the ANY variant -- the one UIKit uses
    when no more specific match exists.  It is not the same as `light`, and 11
    entries in 3 apps really do say `light` explicitly."""
    aps = entry.get("appearances")
    if aps is None:
        return "any"
    if not isinstance(aps, list):
        refuse(path, "`appearances` is %s, expected a list" % type(aps).__name__)
    found = None
    for a in aps:
        if not isinstance(a, dict):
            refuse(path, "`appearances` entry is %s, expected an object" % type(a).__name__)
        check_keys(a, APPEARANCE_KEYS, path, "appearances[]")
        check_value(a.get("appearance"), APPEARANCE_NAMES, path, "appearance")
        check_value(a.get("value"), APPEARANCE_VALUES, path, "appearance value")
        if found is not None and found != a["value"]:
            refuse(path, "entry declares two appearances: %r and %r" % (found, a["value"]))
        found = a["value"]
    return found


def read_scale(entry, path):
    """-> 1 | 2 | 3 | None.

    None means the entry declares NO scale, and that is not an error: 4,758
    image entries in the corpus carry a filename and no `scale` key -- 43% of
    all image entries, more than any other shape.  They are single-scale or
    vector assets that match any requested scale.  A reader that required
    `scale` would silently drop nearly half the corpus."""
    s = entry.get("scale")
    if s is None:
        return None
    check_value(s, SCALES, path, "scale")
    return int(s[0])


def read_resizing(entry, path):
    r = entry.get("resizing")
    if r is None:
        return None
    if not isinstance(r, dict):
        refuse(path, "`resizing` is %s, expected an object" % type(r).__name__)
    # BOTH SPELLINGS OCCUR.  Xcode wrote `capInsets` in older versions and
    # `cap-insets` in newer ones, and the corpus contains 9 of the first and 2
    # of the second across 3 apps.  A reader keyed on one spelling drops the
    # other without a word.
    check_keys(r, {"mode", "center", "cap-insets", "capInsets"}, path, "resizing")
    check_value(r.get("mode"), RESIZING_MODES, path, "resizing mode")
    center = r.get("center")
    if center is not None:
        check_keys(center, {"mode", "width", "height"}, path, "resizing.center")
        check_value(center.get("mode"), CENTER_MODES, path, "resizing center mode")
    insets = r.get("cap-insets", r.get("capInsets"))
    if insets is not None:
        check_keys(insets, {"top", "bottom", "left", "right"}, path, "resizing cap insets")
    return {"mode": r["mode"],
            "center": center,
            "cap_insets": insets,
            "insets_spelling": "cap-insets" if "cap-insets" in r else
                               ("capInsets" if "capInsets" in r else None)}


def sha256_file(p):
    h = hashlib.sha256()
    with open(p, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


class Reader:
    def __init__(self, strict=False):
        self.strict = strict
        self.assets = {}
        self.unresolved = {}
        self.collisions = defaultdict(list)
        self.folder_orphans = []
        self.payloads = {}           # sha256 -> (abs source path, size)
        self.stats = Counter()
        self.catalogs = []

    # -- naming -----------------------------------------------------------
    #
    # NAMESPACING IS A MEASURED RULE, NOT AN ASSUMPTION.  A plain folder inside
    # a catalog contributes to the asset name ONLY if its Contents.json says
    # `"provides-namespace": true` (143 folders in 6 apps).  The other 367
    # folders in the corpus are pure organisation and are invisible to the
    # name.  Getting this backwards renames a sixth of some apps' assets.
    def asset_name(self, catalog, assetdir, namespaces):
        base = os.path.splitext(os.path.basename(assetdir))[0]
        return "/".join(namespaces + [base]) if namespaces else base

    def read_catalog(self, catalog):
        self.catalogs.append(catalog)
        root_contents = os.path.join(catalog, "Contents.json")
        if os.path.isfile(root_contents):
            doc = self.load(root_contents)
            check_keys(doc, TOP_KEYS[".xcassets"], root_contents, "catalog root")
            self.check_info_and_properties(doc, root_contents)
            self.stats["catalogs_with_root_contents_json"] += 1
        else:
            # 6 of the 176 catalogs in the corpus have no root Contents.json.
            # Legal and unremarkable -- counted so that "176 catalogs, 170
            # roots" is a stated fact rather than a discrepancy someone finds
            # later while reconciling against the census.
            self.stats["catalogs_without_root_contents_json"] += 1
        self.walk(catalog, catalog, [])

    def load(self, path):
        try:
            with open(path, "rb") as fh:
                raw = fh.read()
        except OSError as e:
            refuse(path, "cannot read: %s" % e)
        try:
            doc = json.loads(raw.decode("utf-8"))
        except Exception as e:
            refuse(path, "not valid UTF-8 JSON: %s" % e)
        if not isinstance(doc, dict):
            refuse(path, "top level is %s, expected an object" % type(doc).__name__)
        return doc

    def check_info_and_properties(self, doc, path):
        info = doc.get("info")
        if info is not None:
            if not isinstance(info, dict):
                refuse(path, "`info` is %s, expected an object" % type(info).__name__)
            check_keys(info, INFO_KEYS, path, "info")
        props = doc.get("properties")
        if props is not None:
            if not isinstance(props, dict):
                refuse(path, "`properties` is %s, expected an object" % type(props).__name__)
            check_keys(props, PROPERTY_KEYS, path, "properties")
        return props or {}

    def walk(self, catalog, d, namespaces):
        # LOOSE FILES SITTING IN A FOLDER OR AT THE CATALOG ROOT.  Not part of
        # any asset, and easy to miss because nothing points at them -- vlc-ios
        # ships a `Contents 2.json` in a folder, presumably a merge leftover.
        # They are recorded so the flat directory carries every byte the repo
        # does, and so the payload accounting closes.
        for name in sorted(os.listdir(d)):
            p = os.path.join(d, name)
            if os.path.isfile(p) and name != "Contents.json" and not name.startswith("."):
                self.folder_orphans.append(self.record_payload(p))
                self.stats["loose_files_in_folders"] += 1

        for name in sorted(os.listdir(d)):
            p = os.path.join(d, name)
            if not os.path.isdir(p):
                continue
            ext = os.path.splitext(name)[1]
            if ext == "":
                # a namespace-or-organisation folder
                cj = os.path.join(p, "Contents.json")
                ns = namespaces
                if os.path.isfile(cj):
                    doc = self.load(cj)
                    check_keys(doc, TOP_KEYS["<folder>"], cj, "folder")
                    props = self.check_info_and_properties(doc, cj)
                    if props.get("provides-namespace") is True:
                        ns = namespaces + [name]
                        self.stats["namespace_folders"] += 1
                    else:
                        self.stats["plain_folders"] += 1
                else:
                    self.stats["folders_without_contents_json"] += 1
                self.walk(catalog, p, ns)
                continue
            self.read_asset(catalog, p, ext, namespaces)

    def read_asset(self, catalog, assetdir, ext, namespaces):
        name = self.asset_name(catalog, assetdir, namespaces)
        cj = os.path.join(assetdir, "Contents.json")
        if not os.path.isfile(cj):
            refuse(assetdir, "asset directory has no Contents.json")
        if ext not in COVERED:
            if self.strict:
                refuse(cj, "asset type %r is outside the covered set (--strict)" % ext)
            # DESCEND ANYWAY, to count and to keep the bytes.  A non-covered
            # asset can CONTAIN covered ones -- 46 `.imageset` and `.symbolset`
            # directories in the corpus live inside a `.stickerpack`,
            # `.imagestack`, `.brandassets`, `.complicationset` or
            # `.launchimage`.  They are not addressable by name the way a
            # top-level imageset is, so they do not enter `assets`; but if this
            # reader simply stopped here, 46 assets and their payloads would
            # vanish from every total and the tool's numbers would not tie out
            # to the census.  An unexplained gap of 46 is exactly the shape of
            # a gate whose scope excludes the answer.
            payloads = []
            nested = Counter()
            for sub, subdirs, subfiles in os.walk(assetdir):
                if sub != assetdir:
                    sext = os.path.splitext(os.path.basename(sub))[1]
                    nested[sext or "<folder>"] += 1
                    self.stats["nested_under_unresolved"] += 1
                    self.stats["nested_under_unresolved_" + (sext or "<folder>")] += 1
                for f in sorted(subfiles):
                    fp = os.path.join(sub, f)
                    if f == "Contents.json" or not os.path.isfile(fp) or f.startswith("."):
                        continue
                    payloads.append(self.record_payload(fp))
            self.unresolved[name] = {"type": ext,
                                     "reason": "asset type outside the covered set",
                                     "nested_asset_dirs": dict(nested),
                                     "files": payloads}
            self.stats["unresolved_assets"] += 1
            self.stats["unresolved_" + ext] += 1
            return

        doc = self.load(cj)
        check_keys(doc, TOP_KEYS[ext], cj, "%s top level" % ext)
        props = self.check_info_and_properties(doc, cj)
        self.stats["assets_" + ext] += 1

        if ext == ".colorset":
            rec = self.read_colorset(doc, cj, props)
        else:
            rec = self.read_fileset(doc, cj, assetdir, ext, props)

        # AN ASSET DIRECTORY INSIDE ANOTHER ASSET DIRECTORY.  Three exist in the
        # corpus, all in firefox-ios, all `.imageset` inside `.imageset`
        # (`globeLarge.imageset/privateModeLarge.imageset` and two under
        # `lightningFillLarge.imageset`), and they look like an editor
        # accident rather than a feature.  They are recorded as anomalies with
        # their payloads kept, because the alternative is a walker that ends
        # three assets short and cannot say which three.  What `actool` does
        # with them is answered by the oracle, not guessed at here.
        for sub in sorted(os.listdir(assetdir)):
            subp = os.path.join(assetdir, sub)
            if not os.path.isdir(subp):
                continue
            sext = os.path.splitext(sub)[1]
            files = []
            for r, _, fs in os.walk(subp):
                for f in sorted(fs):
                    fp = os.path.join(r, f)
                    if f == "Contents.json" or f.startswith(".") or not os.path.isfile(fp):
                        continue
                    files.append(self.record_payload(fp))
            self.unresolved["%s/%s" % (name, os.path.splitext(sub)[0])] = {
                "type": sext or "<folder>",
                "reason": "asset directory nested inside another asset directory",
                "files": files,
            }
            self.stats["nested_inside_covered_asset"] += 1
            self.stats["nested_inside_covered_asset_" + (sext or "<folder>")] += 1

        if name in self.assets:
            # NAME COLLISIONS ARE RECORDED IN FULL, NOT RESOLVED SILENTLY.  Two
            # catalogs in one app can define the same asset name -- 624 do in
            # this corpus, `AppIcon` most of all -- and which one wins at
            # runtime depends on bundle order, so the index says so rather than
            # picking.
            #
            # The LOSING RECORD IS KEPT, and the first version of this code did
            # not keep it.  That dropped the variants of 624 assets, and with
            # them 167 payload files that had been copied into the flat
            # directory and were then referenced by nothing.  `roundtrip.py`
            # found it by walking the corpus independently; the index alone
            # could never have shown it, because the index was the thing that
            # was short.
            self.collisions[name].append({"contents": cj, "record": rec})
            self.stats["name_collisions"] += 1
            return
        self.assets[name] = rec

    def read_colorset(self, doc, path, props):
        variants = []
        for e in doc.get("colors", []):
            if not isinstance(e, dict):
                refuse(path, "`colors` entry is %s, expected an object" % type(e).__name__)
            check_keys(e, ENTRY_KEYS[".colorset"], path, ".colorset colors[]")
            check_value(e.get("idiom"), IDIOMS, path, "idiom")
            appearance = read_appearances(e, path)
            color = e.get("color")
            if color is None:
                # 20 of 886 colour entries declare no colour: an unassigned
                # slot Xcode left behind.  Skipped, and COUNTED, so "20 fewer
                # variants than entries" is never a mystery.
                self.stats["colorset_entries_without_color"] += 1
                continue
            check_keys(color, COLOR_KEYS, path, "color")
            if "reference" in color:
                # 14 entries in 5 apps name a SYSTEM colour instead of giving
                # components (`systemBackgroundColor`, `labelColor`, ...).  We
                # do not have the system palette, so this is recorded and not
                # resolved -- inventing a value would be the worst outcome.
                self.stats["colorset_system_references"] += 1
                variants.append({"idiom": e["idiom"], "appearance": appearance,
                                 "srgb": None, "reference": color["reference"],
                                 "platform": color.get("platform")})
                continue
            space = color.get("color-space")
            check_value(space, COLOR_SPACES, path, "color-space")
            comps_raw = color.get("components")
            if not isinstance(comps_raw, dict):
                refuse(path, "`components` is %s, expected an object"
                       % type(comps_raw).__name__)
            check_keys(comps_raw, COMPONENT_KEYS, path, "components")
            comps, encodings = {}, {}
            for k, v in comps_raw.items():
                comps[k], encodings[k] = component_value(v, path, k)
            rgba, how = to_srgb(space, comps, path)
            variants.append({"idiom": e["idiom"], "appearance": appearance,
                             "srgb": [round(c, 6) for c in rgba],
                             "color_space": space, "conversion": how,
                             "encodings": encodings,
                             "platform": color.get("platform")})
        return {"type": "colorset", "properties": props, "variants": variants}

    def read_fileset(self, doc, path, assetdir, ext, props):
        arr = {".imageset": "images", ".appiconset": "images",
               ".dataset": "data", ".symbolset": "symbols"}[ext]
        variants = []
        seen_files = set()
        for e in doc.get(arr, []):
            if not isinstance(e, dict):
                refuse(path, "`%s` entry is %s, expected an object" % (arr, type(e).__name__))
            check_keys(e, ENTRY_KEYS[ext], path, "%s %s[]" % (ext, arr))
            check_value(e.get("idiom"), IDIOMS, path, "idiom")
            fn = e.get("filename")
            if fn is None:
                # 1,828 image entries in the corpus declare a slot and provide
                # no file.  Xcode leaves these behind when a variant is removed
                # from the editor.  They are NOT missing files and NOT an
                # error; they are counted so the denominator stays honest.
                self.stats["entries_without_filename"] += 1
                continue
            fp = os.path.join(assetdir, fn)
            if not os.path.isfile(fp):
                refuse(path, "entry names %r and that file is not in the asset directory" % fn)
            seen_files.add(fn)
            v = {"payload": self.record_payload(fp),
                 "idiom": e["idiom"],
                 "appearance": read_appearances(e, path)}
            if ext in (".imageset", ".appiconset"):
                v["scale"] = read_scale(e, path)
            if ext == ".imageset":
                v["screen_width"] = e.get("screen-width")
                v["language_direction"] = e.get("language-direction")
                v["height_class"] = e.get("height-class")
                if v["language_direction"] is not None:
                    check_value(v["language_direction"], LANGUAGE_DIRECTIONS, path,
                                "language-direction")
                if v["height_class"] is not None:
                    check_value(v["height_class"], HEIGHT_CLASSES, path, "height-class")
                v["resizing"] = read_resizing(e, path)
            if ext == ".appiconset":
                v["size"] = e.get("size")
                v["role"] = e.get("role")
                v["subtype"] = e.get("subtype")
                v["platform"] = e.get("platform")
            variants.append(v)

        # Files present on disk that no entry names.  Not an error -- but a
        # silent one would mean the flat directory is missing bytes the app
        # ships, so it is counted and listed.
        orphans = []
        for f in sorted(os.listdir(assetdir)):
            fp = os.path.join(assetdir, f)
            if f == "Contents.json" or not os.path.isfile(fp) or f in seen_files:
                continue
            if f.startswith("."):
                continue
            orphans.append(self.record_payload(fp))
            self.stats["orphan_payload_files"] += 1
        rec = {"type": ext[1:], "properties": props, "variants": variants}
        if orphans:
            rec["orphan_files"] = orphans
        if ext == ".symbolset":
            rec["resolution"] = "recorded-not-resolved: needs a symbol engine"
        return rec

    def record_payload(self, fp):
        h = sha256_file(fp)
        size = os.path.getsize(fp)
        if h not in self.payloads:
            self.payloads[h] = (fp, size)
            self.stats["unique_payloads"] += 1
        self.stats["payload_references"] += 1
        ext = os.path.splitext(fp)[1].lower()
        # `filename` is the ORIGINAL basename, kept beside the
        # content-addressed name.  It is what `assetutil` calls
        # `RenditionName`, so it is the field the oracle compares -- and
        # without it the index could only be checked against itself.
        return {"sha256": h, "bytes": size, "ext": ext, "filename": os.path.basename(fp),
                "source": fp, "file": "%s/%s%s" % (h[:2], h, ext)}


# ---------------------------------------------------------------------------
# Resolution -- the algorithm the OpenUIKit handover has to reimplement.
# Specified in INDEX_FORMAT.md and checked by spot_oracle.py.
# ---------------------------------------------------------------------------
def resolve(asset, scale=2, appearance="light", idiom="universal"):
    """Pick one variant, or None.  Returns (variant, trace)."""
    trace = []
    vs = [v for v in asset["variants"] if v.get("payload") or "srgb" in v]
    if not vs:
        return None, ["no variants"]

    # 1. IDIOM.  An exact idiom beats `universal`; anything else is excluded.
    exact = [v for v in vs if v["idiom"] == idiom]
    univ = [v for v in vs if v["idiom"] == "universal"]
    vs = exact or univ
    trace.append("idiom=%s -> %d (exact %d, universal %d)" % (idiom, len(vs), len(exact), len(univ)))
    if not vs:
        return None, trace

    # 2. APPEARANCE.  An exact appearance beats `any`; `light` and `dark` never
    #    substitute for each other.
    exact = [v for v in vs if v["appearance"] == appearance]
    anyv = [v for v in vs if v["appearance"] == "any"]
    vs = exact or anyv
    trace.append("appearance=%s -> %d (exact %d, any %d)" % (appearance, len(vs), len(exact), len(anyv)))
    if not vs:
        return None, trace

    # 3. SCALE.  Exact, else the smallest scale ABOVE the request (upscaling a
    #    smaller asset looks worse than downscaling a larger one), else the
    #    largest below.  A variant with scale None matches any request and is
    #    ranked last so an explicit match always wins.
    exact = [v for v in vs if v.get("scale") == scale]
    if exact:
        vs = exact
        trace.append("scale=%d exact -> %d" % (scale, len(vs)))
    else:
        above = sorted((v for v in vs if v.get("scale") and v["scale"] > scale),
                       key=lambda v: v["scale"])
        below = sorted((v for v in vs if v.get("scale") and v["scale"] < scale),
                       key=lambda v: -v["scale"])
        none = [v for v in vs if v.get("scale") is None]
        vs = above[:1] or below[:1] or none
        trace.append("scale=%d -> %s" % (scale, "above" if above else ("below" if below else "scaleless")))
    if not vs:
        return None, trace
    return vs[0], trace


# ---------------------------------------------------------------------------
def cmd_index(args):
    reader = Reader(strict=args.strict)
    app = os.path.abspath(args.app)
    catalogs = []
    for dirpath, dirnames, _ in os.walk(app):
        if ".git" in dirnames:
            dirnames.remove(".git")
        for d in list(dirnames):
            if d.endswith(".xcassets"):
                catalogs.append(os.path.join(dirpath, d))
                dirnames.remove(d)
    catalogs.sort()
    for c in catalogs:
        reader.read_catalog(c)

    out = os.path.abspath(args.out)
    res = os.path.join(out, "Resources")
    os.makedirs(res, exist_ok=True)
    copied = 0
    for h, (src, size) in reader.payloads.items():
        ext = os.path.splitext(src)[1].lower()
        dst = os.path.join(res, h[:2], "%s%s" % (h, ext))
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        if not os.path.exists(dst):
            shutil.copyfile(src, dst)
            copied += 1

    # Strip the absolute source paths: the index is a build product that
    # travels, and a machine-specific path in it is a trap for the reader who
    # ships it somewhere else.
    def strip(rec):
        for v in rec.get("variants", []) + rec.get("files", []) + rec.get("orphan_files", []):
            q = v.get("payload", v)
            q.pop("source", None)
    for rec in list(reader.assets.values()) + list(reader.unresolved.values()):
        strip(rec)
    for lst in reader.collisions.values():
        for c in lst:
            strip(c["record"])
    for q in reader.folder_orphans:
        q.pop("source", None)

    index = {
        "format": "openuikit-xcassets-index",
        "version": 1,
        "app": os.path.basename(app),
        "catalogs": [os.path.relpath(c, app) for c in reader.catalogs],
        "resources_dir": "Resources",
        "assets": reader.assets,
        "unresolved": reader.unresolved,
        "collisions": {k: [{"contents": os.path.relpath(c["contents"], app),
                            "record": c["record"]} for c in v]
                       for k, v in reader.collisions.items()},
        "folder_orphans": reader.folder_orphans,
        "stats": dict(reader.stats),
    }
    with open(os.path.join(out, "index.json"), "w") as fh:
        json.dump(index, fh, indent=1, sort_keys=True)

    s = reader.stats
    print("%-22s catalogs %3d  assets %5d  unresolved %4d  payloads %5d (%d copied)"
          % (index["app"], len(reader.catalogs), len(reader.assets),
             len(reader.unresolved), s["unique_payloads"], copied))
    return index


def cmd_resolve(args):
    index = json.load(open(args.index))
    a = index["assets"].get(args.name)
    if a is None:
        u = index["unresolved"].get(args.name)
        if u:
            print("REFUSED: %r is a %s -- %s" % (args.name, u["type"], u["reason"]))
            return 3
        print("not found: %r" % args.name)
        return 4
    v, trace = resolve(a, scale=args.scale, appearance=args.appearance, idiom=args.idiom)
    for t in trace:
        print("   %s" % t)
    print(json.dumps(v, indent=1, sort_keys=True))
    return 0


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("index"); p.add_argument("app"); p.add_argument("--out", required=True)
    p.add_argument("--strict", action="store_true"); p.set_defaults(fn=cmd_index)
    p = sub.add_parser("resolve"); p.add_argument("index"); p.add_argument("name")
    p.add_argument("--scale", type=int, default=2)
    p.add_argument("--appearance", default="light")
    p.add_argument("--idiom", default="universal"); p.set_defaults(fn=cmd_resolve)
    args = ap.parse_args()
    try:
        r = args.fn(args)
    except Refusal as e:
        print("REFUSED: %s" % e, file=sys.stderr)
        return 2
    return r if isinstance(r, int) else 0


if __name__ == "__main__":
    sys.exit(main())
