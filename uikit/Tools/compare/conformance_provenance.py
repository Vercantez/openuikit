#!/usr/bin/env python3
"""conformance_provenance.py — what a conformance golden set was captured FROM.

  python3 Tools/compare/conformance_provenance.py write <golden-dir> <App>
      writes <golden-dir>/provenance.json (run from uikit/, right after the
      simulator capture; scripts/conformance_flow.sh does this)
  python3 Tools/compare/conformance_provenance.py fingerprint <App>
      prints the app fingerprint of the current tree

app_fingerprint is a content hash of Sources/ConformanceApps/<App>/ (the app's
sources and script.json): scripts/agent_merge.sh refuses a committed golden set
whose app_fingerprint differs from the merged tree's (STALE GOLDENS: the app
changed after the capture). probe_fingerprint covers the real-UIKit probe
(Tools/oracle2/confprobe, its Info.plists, scripts/conformance_probe_sim.sh);
a change there is reported, not refused.

agent_merge.sh carries its own copy of app_fingerprint(); keep them identical.
"""
import datetime, glob, hashlib, json, os, subprocess, sys


def _tree_hash(paths, root):
    h = hashlib.sha256()
    for rel in sorted(paths):
        with open(os.path.join(root, rel), "rb") as f:
            h.update(rel.encode() + b"\0" + hashlib.sha256(f.read()).hexdigest().encode() + b"\n")
    return h.hexdigest()


def _files_under(d, root):
    out = []
    for dirpath, dirnames, filenames in os.walk(os.path.join(root, d)):
        dirnames[:] = [n for n in dirnames if not n.startswith(".")]
        for n in filenames:
            if not n.startswith("."):
                out.append(os.path.relpath(os.path.join(dirpath, n), root))
    return out


def app_fingerprint(app, root="."):
    return _tree_hash(_files_under(f"Sources/ConformanceApps/{app}", root), root)


def probe_fingerprint(root="."):
    files = _files_under("Tools/oracle2/confprobe", root)
    files += [os.path.relpath(p, root) for p in glob.glob(os.path.join(root, "Tools/oracle2/ConfProbe*-Info.plist"))]
    files.append("scripts/conformance_probe_sim.sh")
    return _tree_hash([f for f in files if os.path.exists(os.path.join(root, f))], root)


def main():
    if len(sys.argv) == 3 and sys.argv[1] == "fingerprint":
        print(app_fingerprint(sys.argv[2]))
        return
    if len(sys.argv) != 4 or sys.argv[1] != "write":
        sys.exit(__doc__)
    golden, app = sys.argv[2], sys.argv[3]
    head = subprocess.run(["git", "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
    dirty = subprocess.run(["git", "status", "--porcelain", "--", f"Sources/ConformanceApps/{app}"],
                           capture_output=True, text=True).stdout.strip() != ""
    prov = {"app": app,
            "app_fingerprint": app_fingerprint(app),
            "probe_fingerprint": probe_fingerprint(),
            "captured": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "head": head, "app_dirty": dirty}
    json.dump(prov, open(os.path.join(golden, "provenance.json"), "w"), indent=1)


if __name__ == "__main__":
    main()
