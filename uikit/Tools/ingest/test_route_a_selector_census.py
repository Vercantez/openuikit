#!/usr/bin/env python3
import importlib.util
from pathlib import Path
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location("census", Path(__file__).with_name("route_a_selector_census.py"))
census = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(census)


class CensusTests(unittest.TestCase):
    def test_comments_literals_and_interpolation(self):
        source = r'''// #selector(comment) @objc
/* outer /* #selector(nested) */ @objc */
let quoted = "#selector(string) @objc"
let raw = #"#selector(raw) @objc"#
let multiline = """
#selector(multiline) @objc
"""
let interpolated = "action: \(#selector(real(_:)))"
let rawInterpolation = #"action: \#(#selector(other))"#
@objcMembers class Delegate: NSObject {
    @objc(custom:) func real(_ sender: Any) {}
}
'''
        masked = census.mask_noncode(source)
        self.assertEqual(len(masked), len(source))
        self.assertEqual(masked.count("\n"), source.count("\n"))
        self.assertEqual(masked.count("#selector"), 2)
        self.assertEqual(masked.count("@objc"), 2)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "Example.swift"
            path.write_text(source)
            result = census.scan_file(path)
        self.assertEqual(result["counts"], {"selector": 2, "objc": 1, "objcMembers": 1})
        self.assertEqual([o["expression"] for o in result["occurrences"] if o["kind"] == "selector"], ["real(_:)", "other"])

    def test_perform_call_not_declaration_and_generic_inheritance(self):
        source = '''class Generic<T: Item>: Parent<T>, Protocol where T: Other {
    func perform(_ action: Selector) {}
    func fire() { perform(#selector(tapped), with: nil, afterDelay: 0) }
    class func factory() {}
}
class Root {}
'''
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "Example.swift"
            path.write_text(source)
            result = census.scan_file(path)
        self.assertEqual(result["counts"], {"selector": 1, "perform": 1})
        self.assertEqual([(c["name"], c["first_inherited_type"]) for c in result["classes"]], [("Generic", "Parent"), ("Root", None)])

    def test_source_inheritance_and_unknown_are_distinct(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "Example.swift").write_text('class Direct: NSObject {}\nclass Child: Direct {}\nclass Unresolved: Missing {}\nclass Plain {}\n')
            result = census.inventory({"example": [str(root)]}, root / "NoSDK")
        summary = result["summary"]["example"]
        self.assertEqual(summary["nsobject_direct"], 1)
        self.assertEqual(summary["nsobject_transitive"], 1)
        self.assertEqual(summary["nsobject_unresolved_base"], 1)
        self.assertEqual(summary["nsobject_no_inheritance"], 1)


if __name__ == "__main__":
    unittest.main()
