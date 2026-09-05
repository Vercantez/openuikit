#!/bin/zsh
# goldens_snapshot.sh — copy every iOS golden set currently on disk into
# goldens/ios/<set>/ and write goldens/ios/manifest.json (git HEAD, device,
# capture time per set, sha256 per file).
#
# Sets discovered (all axes present on this machine, including rtl/ax1 that
# hillclimb does not recapture every round):
#   /tmp/ios_suite/golden_ios              -> goldens/ios/ios_suite/
#   /tmp/golden_realapp_ios                -> goldens/ios/golden_realapp_ios/
#   /tmp/hc-conformance-<App>[-axis]/golden
#                                          -> goldens/ios/hc-conformance-<App>[-axis]/
#
#   scripts/goldens_snapshot.sh
#   FORCE=1 scripts/goldens_snapshot.sh    # replace goldens/ios even if present
set -e
setopt null_glob
cd "$(dirname "$0")/.."
ROOT=$PWD
DST=goldens/ios

python3 - "$ROOT" "$DST" "${FORCE:-}" <<'PY'
import hashlib, json, os, shutil, sys, glob, datetime

root, dst_rel, force = sys.argv[1], sys.argv[2], sys.argv[3]
dst = os.path.join(root, dst_rel)
os.chdir(root)

def shas(src):
    files = {}
    for dirpath, dirnames, filenames in os.walk(src):
        dirnames.sort()
        for name in sorted(filenames):
            if name.startswith("."):
                continue
            path = os.path.join(dirpath, name)
            rel = os.path.relpath(path, src)
            h = hashlib.sha256()
            with open(path, "rb") as f:
                for chunk in iter(lambda: f.read(1 << 20), b""):
                    h.update(chunk)
            files[rel.replace("\\", "/")] = h.hexdigest()
    return files

def newest_mtime(src):
    newest = 0.0
    for dirpath, _, filenames in os.walk(src):
        for name in filenames:
            if name.startswith("."):
                continue
            t = os.path.getmtime(os.path.join(dirpath, name))
            if t > newest:
                newest = t
    return datetime.datetime.utcfromtimestamp(newest).strftime("%Y-%m-%dT%H:%M:%SZ") if newest else None

def device_of(src):
    """Read the capture device off layout dumps (never guessed)."""
    found = []
    seen = set()
    paths = glob.glob(os.path.join(src, "*.layout.json"))
    paths.sort()
    for p in paths:
        try:
            d = json.load(open(p))
        except Exception:
            continue
        label = None
        screen = d.get("screen") or {}
        bounds = screen.get("bounds")
        scale = screen.get("scale")
        idiom = d.get("userInterfaceIdiom")
        if bounds and scale is not None:
            b = tuple(bounds[:2]) if len(bounds) >= 2 else None
            if b == (375, 667) and scale == 2:
                label = "iPhone SE (3rd generation) @2x"
            elif b == (393, 852) and scale == 3:
                label = "iPhone 16 @3x"
            elif b == (667, 375) and scale == 2:
                label = "iPhone SE (3rd generation) @2x landscape"
            elif b == (820, 1180) and scale == 2:
                label = "iPad (A16) @2x"
            else:
                label = f"bounds={list(bounds)} scale={scale}"
            if idiom:
                label = f"{label} idiom={idiom}"
        else:
            views = d.get("views") or []
            if views:
                fr = views[0].get("frame") or views[0].get("absFrame") or []
                if len(fr) >= 4:
                    w, h = fr[2], fr[3]
                    if (w, h) == (393, 852):
                        label = "iPhone 16 @3x"
                    elif w == 375:
                        label = "iPhone SE (3rd generation) @2x"
                    elif (w, h) == (667, 375):
                        label = "iPhone SE (3rd generation) @2x landscape"
                    elif (w, h) == (820, 1180):
                        label = "iPad (A16) @2x"
        cat = d.get("contentSizeCategory") or d.get("windowContentSizeCategory")
        if label and cat and cat not in ("UICTContentSizeCategoryL", "UICTContentSizeCategoryLarge"):
            label = f"{label} {cat}"
        if label and label not in seen:
            seen.add(label)
            found.append(label)
    return " + ".join(found) if found else "unknown"

def has_pngs(path):
    for dirpath, _, filenames in os.walk(path):
        if any(n.endswith(".png") and not n.startswith(".") for n in filenames):
            return True
    return False

sets = []  # (name, src, dest_tmp)
ios = "/tmp/ios_suite/golden_ios"
if has_pngs(ios):
    sets.append(("ios_suite", ios, "/tmp/ios_suite/golden_ios"))
ra = "/tmp/golden_realapp_ios"
if has_pngs(ra):
    sets.append(("golden_realapp_ios", ra, "/tmp/golden_realapp_ios"))
for golden in sorted(glob.glob("/tmp/hc-conformance-*/golden")):
    if not has_pngs(golden):
        continue
    name = os.path.basename(os.path.dirname(golden))
    if name.endswith(".flow.log"):
        continue
    sets.append((name, golden, golden))

if not sets:
    sys.exit("goldens_snapshot: no golden sets on disk under /tmp/ios_suite/golden_ios, "
             "/tmp/golden_realapp_ios, or /tmp/hc-conformance-*/golden")

if os.path.isdir(dst) and not force:
    # Replace the tree: a snapshot is "what is on disk right now".
    shutil.rmtree(dst)
os.makedirs(dst, exist_ok=True)

head = os.popen("git rev-parse HEAD").read().strip()
head_short = os.popen("git rev-parse --short HEAD").read().strip()
uikit_tree = os.popen("git rev-parse HEAD:uikit 2>/dev/null").read().strip() or head
snap_time = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")

manifest = {
    "head": head,
    "head_short": head_short,
    "uikit_tree": uikit_tree,
    "snapshot_time": snap_time,
    "sets": {},
}

n_files = 0
for name, src, dest_tmp in sets:
    out = os.path.join(dst, name)
    if os.path.isdir(out):
        shutil.rmtree(out)
    os.makedirs(out, exist_ok=True)
    for dirpath, dirnames, filenames in os.walk(src):
        dirnames.sort()
        rel_dir = os.path.relpath(dirpath, src)
        target_dir = out if rel_dir == "." else os.path.join(out, rel_dir)
        os.makedirs(target_dir, exist_ok=True)
        for fn in sorted(filenames):
            if fn.startswith("."):
                continue
            shutil.copy2(os.path.join(dirpath, fn), os.path.join(target_dir, fn))
    files = shas(out)
    n_files += len(files)
    captured = newest_mtime(src)
    device = device_of(src)
    pngs = sum(1 for f in files if f.endswith(".png"))
    manifest["sets"][name] = {
        "dest": dest_tmp,
        "device": device,
        "captured": captured,
        "pngs": pngs,
        "files": files,
    }
    print(f"  {name}: {pngs} png, {len(files)} files, device={device}, captured={captured}")

json.dump(manifest, open(os.path.join(dst, "manifest.json"), "w"), indent=1, sort_keys=False)
print(f"goldens_snapshot: {len(sets)} set(s), {n_files} files -> {dst_rel}/  head={head_short}")
PY
