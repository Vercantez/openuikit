#!/usr/bin/env python3
"""Stage NetNewsWire.app for the guest (uikit/fixtures/realapp/netnewswire).

    stage_bundle.py <corpus NetNewsWire dir> <out NetNewsWire.app> \
        [--bundle <SwiftPM resource bundle dir> ...]

* fixtures/realapp/netnewswire/compiled/: Xcode's compiled resources, copied;
* resources.json: every verbatim resource copied from the corpus, refusing a
  SHA-256 mismatch (the pinned corpus is the only source);
* the SwiftPM resource bundles the guest build produced (--bundle);
* OpenUIKit/AssetCatalogs: the corpus's iOS Assets.xcassets indexed by
  full/xcassets/xcassets_tool.py (OpenUIKit does not read Assets.car);
* OpenUIKit/*.json: OpenUIKit's measured tables.
The executable is installed by the caller. The output must not exist.
"""
import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
UIKIT = os.path.normpath(os.path.join(HERE, "..", ".."))
TREE = os.path.dirname(UIKIT)
FIXTURE = os.path.join(UIKIT, "fixtures", "realapp", "netnewswire")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("corpus")
    ap.add_argument("out")
    ap.add_argument("--bundle", action="append", default=[])
    a = ap.parse_args()
    if os.path.exists(a.out):
        sys.exit(f"stage_bundle: {a.out} exists")
    shutil.copytree(os.path.join(FIXTURE, "compiled"), a.out)
    manifest = json.load(open(os.path.join(FIXTURE, "resources.json")))
    for e in manifest["verbatim"]:
        src = os.path.join(a.corpus, e["corpus"])
        data = open(src, "rb").read()
        if hashlib.sha256(data).hexdigest() != e["sha256"]:
            sys.exit(f"stage_bundle: {e['corpus']} does not match its pinned SHA-256")
        dst = os.path.join(a.out, e["bundle"])
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(dst, "wb") as f:
            f.write(data)
    for b in a.bundle:
        shutil.copytree(b, os.path.join(a.out, os.path.basename(b.rstrip("/"))))
    stage = os.path.join(a.out, ".xcassets-stage")
    os.makedirs(stage)
    shutil.copytree(os.path.join(a.corpus, "iOS", "Resources", "Assets.xcassets"),
                    os.path.join(stage, "Assets.xcassets"))
    subprocess.run([sys.executable, os.path.join(TREE, "full", "xcassets", "xcassets_tool.py"),
                    "index", stage, "--out", os.path.join(a.out, "OpenUIKit", "AssetCatalogs")], check=True)
    shutil.rmtree(stage)
    res = os.path.join(UIKIT, "Sources", "OpenUIKit", "Resources")
    for n in sorted(os.listdir(res)):
        if n.endswith(".json"):
            shutil.copy2(os.path.join(res, n), os.path.join(a.out, "OpenUIKit", n))
    print(f"staged {a.out}: compiled + {len(manifest['verbatim'])} verbatim + {len(a.bundle)} bundles")


if __name__ == "__main__":
    main()
