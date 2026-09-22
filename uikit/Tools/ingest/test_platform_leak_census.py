"""Tests for platform_leak_census.py (fixture-only)."""
from __future__ import annotations

import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import platform_leak_census as plc  # noqa: E402


class ConditionTests(unittest.TestCase):
    def test_conditions(self):
        self.assertIs(plc.active_on_macos("os(macOS)"), True)
        self.assertIs(plc.active_on_macos("os(iOS)"), False)
        self.assertIs(plc.active_on_macos("canImport(UIKit)"), False)
        self.assertIs(plc.active_on_macos("!os(macOS)"), False)
        self.assertIs(plc.active_on_macos("!os(iOS)"), True)
        self.assertIs(plc.active_on_macos("os(iOS) || os(tvOS)"), False)
        self.assertIs(plc.active_on_macos("os(macOS) || targetEnvironment(macCatalyst)"), True)
        self.assertIsNone(plc.active_on_macos("DEBUG"))


class ClassifyTests(unittest.TestCase):
    def setUp(self):
        self.texts = {
            "RSCore/UIKit/ImageHeaderView.swift": "#if os(iOS)\nimport UIKit\nclass ImageHeaderView {}\n#endif\n",
            "RSCore/UIKit/UIStoryboard+RSCore.swift":
                "#if os(iOS)\nextension UIStoryboard {\n static var account: UIStoryboard { .init() }\n}\n#endif\n",
            "Shared/Assets.swift": "struct Colors {\n#if os(macOS)\n static let a = 1\n#else // iOS\n static let vibrantText = 2\n#endif\n}\n",
            "iOS/Local.swift": "func f() { let account = 1 }\n",
            "iOS/Real.swift": "class Present {}\n",
        }
        self.defs = plc.definitions(self.texts)

    def test_rules(self):
        errors = [
            {"file": "/x/A.swift", "msg": "cannot convert value of type 'RSImage' (aka 'NSImage') to expected argument type 'UIImage'"},
            {"file": "/x/A.swift", "msg": "'BGAppRefreshTask' is unavailable in macOS"},
            {"file": "/x/B.swift", "msg": "cannot find 'ImageHeaderView' in scope"},
            {"file": "/x/B.swift", "msg": "type 'Assets.Colors' has no member 'vibrantText'"},
            {"file": "/x/C.swift", "msg": "type 'UIStoryboard' has no member 'account'"},
            {"file": "/x/C.swift", "msg": "value of type 'UIView' has no member 'frobnicate'"},
            {"file": "/x/C.swift", "msg": "cannot find 'Present' in scope"},
        ]
        out = plc.classify(errors, self.defs, self.texts)
        self.assertEqual(out["total"], 7)
        self.assertEqual(out["leakage"], 5)
        rules = dict(out["leakage_by_rule"])
        self.assertEqual(rules["L3 defined only under a dropped branch"], 2)
        self.assertEqual(rules["L4 member defined only in a dropped extension of the type"], 1)
        self.assertEqual(sum(v for k, v in rules.items() if k.startswith("L1")), 1)
        self.assertEqual(rules["L2 unavailable in macOS"], 1)
        self.assertEqual(dict(out["rest_by_message"]),
                         {"value of type 'UIView' has no member 'frobnicate'": 1, "cannot find 'Present' in scope": 1})


if __name__ == "__main__":
    unittest.main()
