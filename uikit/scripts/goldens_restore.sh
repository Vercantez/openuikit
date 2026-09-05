#!/bin/zsh
# goldens_restore.sh [set...] — copy committed goldens/ios/<set>/ back to the
# /tmp paths the flows expect, so a Linux agent (or a Mac with a wiped /tmp)
# can grade with SKIP_CAPTURE=1 and no simulator:
#
#   /tmp/ios_suite/golden_ios
#   /tmp/golden_realapp_ios
#   /tmp/hc-conformance-<App>[-dark|-ipad|-rtl|-ax1]/golden
#
# Existing dests that already have files are left alone (a live round's
# captures win). FORCE=1 replaces them. Named sets restrict the restore;
# with no args every set in the manifest is considered.
#
#   scripts/goldens_restore.sh
#   scripts/goldens_restore.sh ios_suite golden_realapp_ios
#   FORCE=1 scripts/goldens_restore.sh hc-conformance-NavFlow
set -e
setopt null_glob
cd "$(dirname "$0")/.."
ROOT=$PWD
SRC=goldens/ios
MAN=$SRC/manifest.json

[[ -f "$MAN" ]] || { echo "goldens_restore: no $MAN — run scripts/goldens_snapshot.sh on a Mac that has the /tmp goldens" >&2; exit 2; }

python3 - "$ROOT" "$SRC" "${FORCE:-}" "$@" <<'PY'
import hashlib, json, os, shutil, sys

root, src_rel, force = sys.argv[1], sys.argv[2], sys.argv[3]
want = sys.argv[4:]
src = os.path.join(root, src_rel)
man = json.load(open(os.path.join(src, "manifest.json")))
sets = man.get("sets") or {}
if want:
    missing = [n for n in want if n not in sets]
    if missing:
        sys.exit("goldens_restore: unknown set(s): " + ", ".join(missing)
                 + " (have: " + ", ".join(sorted(sets)) + ")")
    names = want
else:
    names = sorted(sets)

def nonempty(path):
    if not os.path.isdir(path):
        return False
    for dirpath, _, filenames in os.walk(path):
        if any(not n.startswith(".") for n in filenames):
            return True
    return False

def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()

restored, skipped, verified = [], [], 0
for name in names:
    info = sets[name]
    dest = info["dest"]
    from_dir = os.path.join(src, name)
    if not os.path.isdir(from_dir):
        sys.exit(f"goldens_restore: {from_dir} missing from the snapshot")
    if nonempty(dest) and not force:
        skipped.append(name)
        continue
    if os.path.isdir(dest):
        shutil.rmtree(dest)
    os.makedirs(dest, exist_ok=True)
    files = info.get("files") or {}
    for rel in sorted(files):
        a = os.path.join(from_dir, rel)
        b = os.path.join(dest, rel)
        os.makedirs(os.path.dirname(b), exist_ok=True)
        shutil.copy2(a, b)
        got = sha256(b)
        if got != files[rel]:
            sys.exit(f"goldens_restore: sha256 mismatch {name}/{rel}: {got} != {files[rel]}")
        verified += 1
    restored.append(name)
    pngs = info.get("pngs", sum(1 for f in files if f.endswith(".png")))
    print(f"  restored {name} -> {dest} ({pngs} png, captured {info.get('captured')}, {info.get('device')})")

n = len(names)
if restored and not skipped:
    print(f"goldens_restore: /tmp had none; restored {len(restored)} set(s) from committed goldens/ios (head {man.get('head_short')})")
elif restored and skipped:
    print(f"goldens_restore: restored {len(restored)} missing set(s) from committed goldens/ios; {len(skipped)} already in /tmp")
elif skipped:
    print(f"goldens_restore: /tmp already has all {len(skipped)} committed set(s); not replacing (FORCE=1 to overwrite)")
else:
    print("goldens_restore: nothing to restore")
if restored:
    print(f"  verified sha256 for {verified} file(s)")
PY
