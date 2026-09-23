from __future__ import annotations

import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))

import check_runtime_names as crn  # noqa: E402

INCLUDE = HERE.parent / "include"


class RuntimeNameTests(unittest.TestCase):
    def test_headers_declare_the_facade_and_bridge_classes(self) -> None:
        rows = crn.declared(INCLUDE)
        names = {runtime for _, runtime, _ in rows}
        for expected in ("_TtC10Foundation8NSString", "_TtC10Foundation7NSArray",
                         "_TtC10Foundation12NSDictionary", "_TtC10Foundation8NSNumber",
                         "_TtC20FoundationObjCBridge15NSMutableString",
                         "_TtC20FoundationObjCBridge6NSDate", "_TtC20FoundationObjCBridge5NSSet"):
            self.assertIn(expected, names)
        for _, runtime, module in rows:
            self.assertEqual(crn.module_of(runtime), module, runtime)

    def test_missing_class_and_wrong_module_are_refused(self) -> None:
        rows = [("NSString.h", "_TtC10Foundation8NSString", "Foundation"),
                ("NSDate.h", "_TtC20FoundationObjCBridge6NSDate", "Foundation")]
        found = crn.problems(rows, {"_OBJC_CLASS_$__TtC10Foundation8NSString"})
        self.assertEqual(len(found), 2)
        self.assertIn("no object defines Objective-C class _TtC20FoundationObjCBridge6NSDate", found[0])
        self.assertIn("header says Foundation", found[1])
        self.assertEqual(crn.problems([], set()), ["no OF_SWIFT_CLASS declarations found"])


if __name__ == "__main__":
    unittest.main()
