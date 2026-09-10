"""Tests for spm_app_chain.py — fixture-only, no corpus needed."""
from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
TOOL = os.path.join(HERE, "spm_app_chain.py")


class SpmAppChainTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix="spm_app_chain_")
        self.corpus = os.path.join(self.tmp, "corpus")
        self.checkouts = os.path.join(self.tmp, "checkouts")
        self.openuikit = os.path.join(self.tmp, "uikit")
        for rel in ["corpus/App/Sources/App", "checkouts/Dep/Sources/Dep", "uikit/Sources/Shims/Svc"]:
            os.makedirs(os.path.join(self.tmp, rel))
        open(os.path.join(self.corpus, "App/Sources/App/A.swift"), "w").write("import Dep\nimport Svc\n")
        open(os.path.join(self.corpus, "App/Sources/App/Info.plist"), "w").write("<plist/>")
        open(os.path.join(self.checkouts, "Dep/Sources/Dep/D.swift"), "w").write("public let d = 1\n")
        open(os.path.join(self.openuikit, "Sources/Shims/Svc/S.swift"), "w").write("public let s = 1\n")
        self.spec = os.path.join(self.tmp, "chain.json")
        json.dump({
            "name": "Chain",
            "shims": [{"name": "Svc", "root": "openuikit", "path": "Sources/Shims/Svc"}],
            "targets": [
                {"name": "Dep", "root": "checkouts", "path": "Dep/Sources/Dep", "swift_language_mode": "5"},
                {"name": "App", "root": "corpus", "path": "App/Sources/App", "deps": ["Dep", "Svc"],
                 "openuikit": ["UIKit"], "exclude": ["Info.plist"], "resources": ["Res"]},
            ],
        }, open(self.spec, "w"))

    def run_tool(self, *extra):
        out = os.path.join(self.tmp, "out")
        p = subprocess.run([sys.executable, TOOL, self.spec, "--out", out, "--corpus", self.corpus,
                            "--checkouts", self.checkouts, "--openuikit", self.openuikit, *extra],
                           capture_output=True, text=True)
        return p, out

    def test_links_targets_and_renders_manifest(self):
        p, out = self.run_tool()
        self.assertEqual(p.returncode, 0, p.stderr)
        manifest = open(os.path.join(out, "Package.swift")).read()
        self.assertIn('swift-tools-version:6.0', manifest)
        self.assertIn('defaultLocalization: "en"', manifest)
        self.assertIn('.package(name: "OpenUIKit", path: "%s")' % json.dumps(self.openuikit)[1:-1], manifest)
        self.assertIn('dependencies: ["Dep", "Svc", .product(name: "UIKit", package: "OpenUIKit")]', manifest)
        self.assertIn('exclude: ["Info.plist"]', manifest)
        self.assertIn('resources: [.process("Res")]', manifest)
        self.assertIn('swiftSettings: [.swiftLanguageMode(.v5)]', manifest)
        # shims come first so a target may depend on them
        self.assertLess(manifest.index('name: "Svc"'), manifest.index('name: "Dep"'))
        for name, src in [("App", os.path.join(self.corpus, "App/Sources/App")),
                          ("Dep", os.path.join(self.checkouts, "Dep/Sources/Dep")),
                          ("Svc", os.path.join(self.openuikit, "Sources/Shims/Svc"))]:
            link = os.path.join(out, "Sources", name)
            self.assertTrue(os.path.islink(link), name)
            self.assertEqual(os.path.realpath(link), os.path.realpath(src))
        # upstream trees untouched
        self.assertEqual(sorted(os.listdir(os.path.join(self.corpus, "App/Sources/App"))), ["A.swift", "Info.plist"])

    def test_copy_writes_provenance_hashes(self):
        p, out = self.run_tool("--copy")
        self.assertEqual(p.returncode, 0, p.stderr)
        prov = json.load(open(os.path.join(out, "PROVENANCE.json")))
        self.assertEqual(set(prov), {"App", "Dep", "Svc"})
        self.assertEqual(sorted(prov["App"]["files"]), ["A.swift", "Info.plist"])
        self.assertEqual(len(prov["Dep"]["files"]["D.swift"]), 64)
        self.assertFalse(os.path.islink(os.path.join(out, "Sources", "App")))

    def test_rejects_forward_dependency_and_missing_dir(self):
        spec = json.load(open(self.spec))
        spec["targets"].reverse()
        json.dump(spec, open(self.spec, "w"))
        p, _ = self.run_tool()
        self.assertEqual(p.returncode, 1)
        self.assertIn("dependency Dep is not declared before it", p.stderr)
        spec["targets"].reverse()
        spec["targets"][0]["path"] = "Dep/Sources/Nope"
        json.dump(spec, open(self.spec, "w"))
        p, _ = self.run_tool()
        self.assertEqual(p.returncode, 1)
        self.assertIn("no such directory", p.stderr)


if __name__ == "__main__":
    unittest.main()
