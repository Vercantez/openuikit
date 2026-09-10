#!/usr/bin/env python3
"""Tests for target_scope.py and ladder_census.py --target-scope.

    python3 -m unittest full/ladder/test_target_scope.py      (from the repo root)

Three things are proved, none of which needs Xcode:
  1. the whole-file macOS guard rule accepts exactly the shapes it claims to;
  2. partial guards are reported as regions and NOT treated as whole-file;
  3. over a synthetic two-app corpus, an app not named in the scope file is
     BYTE-IDENTICAL with and without the flag (the control), and the named app
     loses exactly the out-of-scope file's uses.
The real NetNewsWire clone is used for a fourth check only when it is present.
"""
import json, os, pathlib, subprocess, sys, tempfile, unittest

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import target_scope as ts  # noqa: E402

CORPUS = pathlib.Path.home() / "openuikit" / "scratch" / "ladder-corpus" / "NetNewsWire"


class GuardRule(unittest.TestCase):
    def test_whole_file_guard_variants(self):
        for g in ("#if os(macOS)", "#if os(OSX)", "#if canImport(AppKit)",
                  "#if targetEnvironment(macCatalyst)"):
            src = f"// header\n{g}\nimport AppKit\nclass A: NSToolbarItem {{}}\n#endif\n"
            self.assertEqual(ts.whole_file_mac_guard(src), g, g)

    def test_not_whole_file(self):
        self.assertIsNone(ts.whole_file_mac_guard(
            "#if os(macOS)\nimport AppKit\n#endif\nclass A {}\n"))           # closes early
        self.assertIsNone(ts.whole_file_mac_guard(
            "#if os(macOS)\nimport AppKit\n#else\nimport UIKit\n#endif\n"))   # has an iOS branch
        self.assertIsNone(ts.whole_file_mac_guard(
            "#if os(iOS)\nimport UIKit\n#endif\n"))                          # iOS-only stays
        self.assertIsNone(ts.whole_file_mac_guard(
            "#if !os(macOS)\nimport UIKit\n#endif\n"))                       # negated stays
        self.assertIsNone(ts.whole_file_mac_guard("import UIKit\n"))

    def test_nested_inner_guard_is_still_whole_file(self):
        src = "#if os(macOS)\n#if DEBUG\nlet x = 1\n#endif\nlet y = NSToolbarItem()\n#endif\n"
        self.assertEqual(ts.whole_file_mac_guard(src), "#if os(macOS)")

    def test_partial_regions(self):
        src = "import Foundation\n#if os(macOS)\nlet a = NSToolbarItem()\n#else\nlet a = UIView()\n#endif\n"
        spans = ts.partial_guard_regions(src)
        self.assertEqual(len(spans), 1)
        a, b = spans[0]
        self.assertIn("NSToolbarItem", src[a:b])
        self.assertNotIn("UIView", src[a:b])
        self.assertIsNone(ts.whole_file_mac_guard(src))


def _write(p, text):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text)


class CensusScope(unittest.TestCase):
    def test_scoped_walk_and_control(self):
        with tempfile.TemporaryDirectory() as d:
            d = pathlib.Path(d)
            for app in ("Alpha", "Beta"):
                (d / "corpus" / app / ".git").mkdir(parents=True)
            _write(d / "corpus/Alpha/iOS/A.swift", "import UIKit\nlet v = UIView()\n")
            _write(d / "corpus/Alpha/Mac/M.swift", "import AppKit\nlet t = NSToolbarItem()\n")
            _write(d / "corpus/Beta/B.swift", "import UIKit\nlet t = NSToolbarItem()\nlet v = UIView()\n")
            _write(d / "sdk.txt", "UIView\nNSToolbarItem\n")
            _write(d / "ours.txt", "UIView\n")
            _write(d / "scope.json", json.dumps({"apps": {"Alpha": {"target": "Alpha-iOS",
                                                           "files": ["iOS/A.swift"]}}}))
            census = HERE / "ladder_census.py"
            base = [sys.executable, str(census), str(d / "corpus"), str(d / "sdk.txt"), str(d / "ours.txt")]
            subprocess.run(base + [str(d / "whole.json")], check=True, capture_output=True)
            subprocess.run(base + [str(d / "scoped.json"), f"--target-scope={d / 'scope.json'}"],
                           check=True, capture_output=True)
            whole, scoped = json.load(open(d / "whole.json")), json.load(open(d / "scoped.json"))
            # control: the unnamed app is identical
            self.assertEqual(whole["apps"]["Beta"], scoped["apps"]["Beta"])
            self.assertEqual(whole["apps"]["Beta"]["uikit"]["missing"], [["NSToolbarItem", 1]])
            # the named app loses exactly the out-of-scope file
            self.assertEqual(whole["apps"]["Alpha"]["uikit"]["missing"], [["NSToolbarItem", 1]])
            self.assertEqual(scoped["apps"]["Alpha"]["uikit"]["missing"], [])
            self.assertEqual(scoped["apps"]["Alpha"]["uikit"]["swift_files"], 1)
            self.assertEqual(scoped["apps"]["Alpha"]["_scope"]["files"], 1)
            self.assertEqual(scoped["_scope"]["Alpha"]["target"], "Alpha-iOS")
            self.assertNotIn("_scope", whole)
            # build shape is repo-wide in both
            self.assertEqual(whole["apps"]["Alpha"]["build"], scoped["apps"]["Alpha"]["build"])


@unittest.skipUnless((CORPUS / "NetNewsWire.xcodeproj").is_dir(), "NetNewsWire clone not present")
class RealProject(unittest.TestCase):
    def test_netnewswire_ios_scope_has_no_toolbar_item(self):
        s = ts.build_scope(str(CORPUS), str(CORPUS / "NetNewsWire.xcodeproj"), "NetNewsWire-iOS")
        self.assertEqual(s["target"], "NetNewsWire-iOS")
        self.assertTrue(all(f.startswith(("iOS/", "Shared/", "Modules/")) for f in s["files"]))
        self.assertFalse(any(f.startswith("Mac/") for f in s["files"]))
        self.assertIn("Modules/RSCore", s["local_packages"])
        self.assertIn("Modules/NewsBlur", s["local_packages"])       # transitive via Account
        self.assertEqual(s["unresolved_products"], [])
        excluded = {e["file"] for e in s["excluded_whole_file_guard"]}
        self.assertIn("Modules/RSCore/Sources/RSCore/AppKit/RSToolbarItem.swift", excluded)
        for f in s["files"]:
            if f.endswith(".swift"):
                self.assertNotIn("NSToolbarItem", (CORPUS / f).read_text(errors="ignore"), f)


if __name__ == "__main__":
    unittest.main()
