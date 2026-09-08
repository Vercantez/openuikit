#!/usr/bin/env python3
"""Fail-closed adapter and measured Focus selector spelling regression tests."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

import route_a_selectors as adapter

HERE = Path(__file__).resolve().parent
UIKIT = HERE.parent.parent


class RouteASelectorTests(unittest.TestCase):
    def test_measured_selector_spellings_and_private_dispatch(self):
        source = '''import UIKit
class Example: UIView {
    let literal = "#selector(fake) @objc"
    // #selector(comment)
    /* nested /* @objc */ #selector(comment) */
    func wire() {
        use(#selector(plain))
        use(#selector(changed(_:)))
        use(#selector(self.toggle(sender:)))
        use(#selector(Example.keyboardWillShow))
        use(#selector(explicit(_:)))
    }
    @objc private func plain() {}
    @objc private func changed(_ sender: UISwitch) {}
    @objc private func toggle(sender: UISwitch) {}
    @objc func keyboardWillShow(notification: NSNotification) {}
    @objc(chosenName:) private func explicit(_ sender: UISwitch) {}
}'''
        result, report = adapter.transform(source)
        self.assertTrue(report["complete"], report)
        self.assertEqual([item["selector"] for item in report["selectors"]],
                         ["plain", "changed:", "toggleWithSender:",
                          "keyboardWillShowWithNotification:", "chosenName:"])
        self.assertIn('private func toggle(sender: UISwitch)', result)
        self.assertIn('.action("toggleWithSender:", Example.toggle(sender:))', result)
        self.assertIn('.action("plain", Example.plain)', result)
        self.assertIn('let literal = "#selector(fake) @objc"', result)
        self.assertIn('/* nested /* @objc */ #selector(comment) */', result)

    def test_actual_focus_files(self):
        cases = [("Tracking Protection/Views/SwitchTableViewCell.swift", "toggleWithSender:"),
                 ("Theme/ThemeCells/ThemeTableViewToggleCell.swift", "toggleSwitched:")]
        for path, selector in cases:
            source = (UIKIT / "Sources/Blockzilla/Blockzilla" / path).read_text()
            _, report = adapter.transform(source, path)
            self.assertTrue(report["complete"], report)
            self.assertEqual(report["counts"]["selectors"], 1)
            self.assertEqual(report["counts"]["dispatch_classes"], 1)
            self.assertEqual(report["selectors"][0]["selector"], selector)

    def test_audit_does_not_count_partial_file_as_emittable(self):
        with tempfile.TemporaryDirectory() as temporary:
            source = Path(temporary) / "Input.swift"
            source.write_text('''class Example {
                @objc func tap() {}
                @objc var enabled = true
                func wire() { use(#selector(tap)) }
            }''')
            report = adapter.audit([source])
            self.assertEqual(report["totals"]["lowered_selectors"], 1)
            self.assertEqual(report["totals"]["emittable_selectors"], 0)
            self.assertEqual(report["totals"]["not_emittable_selectors"], 1)
            self.assertEqual(report["totals"]["not_emittable_objc_attributes"], 2)

    def test_no_guess_for_unresolved_or_overloaded_reference(self):
        source = '''class Example: UIView {
  func wire() { use(#selector(missing)); use(#selector(tap)); use(#selector(Other.tap)) }
  @objc func tap(_ sender: UISwitch) {}
  @objc func tap(sender: UIButton) {}
}'''
        _, report = adapter.transform(source)
        self.assertFalse(report["complete"])
        self.assertEqual(report["counts"]["lowered_selectors"], 0)

    def test_unsupported_objc_shapes_preserved_and_diagnosed(self):
        for declaration in ["@objc var enabled = true", "@objc static func tap() {}",
                            "@objc override func tap() {}", "@objc func tap() -> Bool { true }",
                            "@objc func tap(_ a: UISwitch, event: UIEvent?) {}",
                            "@objc func tap(_ closure: () -> Void) {}",
                            "@objc func tap() throws {}"]:
            source = f"class Example: UIView {{ {declaration} }}"
            result, report = adapter.transform(source)
            self.assertFalse(report["complete"], declaration)
            self.assertEqual(result, source)
            self.assertIn("reason", report["objc_attributes"][0])

    def test_implicit_exposure_and_generic_targets_refused(self):
        for source in ["@objcMembers class Example: UIView {}",
                       "class Example<T>: UIView { @objc func tap() {} }"]:
            _, report = adapter.transform(source)
            self.assertFalse(report["complete"])

    def test_actual_generic_focus_publisher(self):
        path = UIKIT / "Sources/Blockzilla/Blockzilla/UIComponents/URLBar/Combine+UIControl.swift"
        result, report = adapter.transform(path.read_text(), str(path))
        self.assertTrue(report["complete"], report)
        self.assertEqual(report["counts"]["lowered_selectors"], 1)
        self.assertEqual(report["counts"]["lowered_objc_attributes"], 1)
        self.assertIn("SelectorDispatching where SubscriberType.Input == Control", result)
        self.assertIn("ActionTable<UIControlSubscription<SubscriberType, Control>>", result)
        self.assertIn('.action("eventHandler", UIControlSubscription<SubscriberType, Control>.eventHandler)', result)
        self.assertIn('action: Selector.named("eventHandler")', result)
        self.assertIn("private func eventHandler()", result)

    def test_generic_constraints_are_not_an_inheritance_clause(self):
        source = '''final class Target<T: AnyObject> {
            @objc private func tap() {}
            func wire() { use(#selector(tap)) }
        }'''
        result, report = adapter.transform(source)
        self.assertTrue(report["complete"], report)
        self.assertIn("Target<T: AnyObject> : SelectorDispatching", result)
        self.assertIn("ActionTable<Target<T>>", result)

    def test_unmeasured_generic_shapes_fail_closed(self):
        headers = ["class Target<T>", "final class Target<each T>",
                   "final class Target<T>: Base<T>",
                   "final class Target<T> where T: Equatable",
                   "final class Target<T> where T == Int",
                   "final class Target<T: P & Q>"]
        for header in headers:
            source = header + " { @objc func tap() {} func wire() { use(#selector(tap)) } }"
            result, report = adapter.transform(source)
            self.assertFalse(report["complete"], header)
            self.assertEqual(result, source)
        source = '''class Outer<T> {
            final class Target<U> { @objc func tap() {} func wire() { use(#selector(tap)) } }
        }'''
        _, report = adapter.transform(source)
        self.assertFalse(report["complete"])
        self.assertIn("nested generic", report["objc_attributes"][0]["reason"])
        source = '''final class Target<T> {
            @objc func tap(_ sender: UIControl) {}
            func wire() { use(#selector(tap(_:))) }
        }'''
        _, report = adapter.transform(source)
        self.assertFalse(report["complete"])
        self.assertIn("zero-argument", report["objc_attributes"][0]["reason"])

    def test_generic_selector_outside_specialization_is_refused(self):
        source = '''final class Target<T> { @objc func tap() {} }
        class Caller { func wire() { use(#selector(Target.tap)) } }'''
        _, report = adapter.transform(source)
        self.assertFalse(report["complete"])
        self.assertIn("enclosing specialization", report["selectors"][0]["reason"])

    def test_unmeasured_label_requires_explicit_objc_name(self):
        source = "class Example { @objc func move(with sender: NSObject) {} }"
        _, report = adapter.transform(source)
        self.assertFalse(report["complete"])
        self.assertIn("unmeasured", report["objc_attributes"][0]["reason"])
        _, report = adapter.transform(source.replace("@objc", "@objc(moveWith:)"))
        self.assertTrue(report["complete"], report)

    def test_existing_perform_requires_manual_integration(self):
        source = '''class Example: UIView {
  func wire() { use(#selector(tap)) }
  @objc func tap() {}
  func perform(_ name: String, with sender: Any?) -> Bool { false }
}'''
        _, report = adapter.transform(source)
        self.assertEqual(report["counts"]["lowered_selectors"], 0)
        self.assertIn("manual integration", report["selectors"][0]["reason"])

    def test_existing_dispatch_in_extension_requires_manual_integration(self):
        source = '''class Example: UIView {
  func wire() { use(#selector(tap)) }
  @objc func tap() {}
}
extension Example: SelectorDispatching {
  func perform(_ name: String, with sender: Any?) -> Bool { false }
}'''
        _, report = adapter.transform(source)
        self.assertFalse(report["complete"])
        self.assertIn("manual integration", report["selectors"][0]["reason"])

    def test_conditional_method_does_not_make_unconditional_registry(self):
        source = '''class Example: UIView {
#if DEBUG
  @objc func tap() {}
  func wire() { use(#selector(tap)) }
#endif
}'''
        _, report = adapter.transform(source)
        self.assertFalse(report["complete"])
        self.assertIn("conditionally", report["objc_attributes"][0]["reason"])

    def test_whole_class_condition_preserves_registry_condition(self):
        source = '''#if DEBUG
class Example: UIView {
  @objc func tap() {}
  func wire() { use(#selector(tap)) }
}
#endif'''
        result, report = adapter.transform(source)
        self.assertTrue(report["complete"])
        self.assertLess(result.index("public func perform"), result.index("#endif"))

    def test_explicit_target_in_same_file(self):
        source = '''class Example { func wire() { use(#selector(Callback.go)) } }
private class Callback { @objc func go() {} }'''
        result, report = adapter.transform(source)
        self.assertTrue(report["complete"], report)
        self.assertIn("class Callback : SelectorDispatching", result)
        self.assertNotIn("class Example : SelectorDispatching", result)

    def test_raw_multiline_strings_and_interpolation_fail_closed(self):
        source = 'let raw = #"""#selector(fake) @objc \"""#\nclass Example {}'
        _, report = adapter.transform(source)
        self.assertEqual(report["counts"]["selectors"], 0)
        _, report = adapter.transform(r'let s = "\(#selector(tap))"')
        self.assertIn("interpolation", report["errors"][0])

    def test_cli_requires_route_and_preserves_original(self):
        with tempfile.TemporaryDirectory() as temporary:
            source = Path(temporary) / "Input.swift"
            output = Path(temporary) / "Output.swift"
            original = "class Example { @objc func tap() {} func wire() { use(#selector(tap)) } }"
            source.write_text(original)
            command = [sys.executable, str(HERE / "route_a_selectors.py"), "rewrite", str(source)]
            denied = subprocess.run(command + ["--output", str(output)], capture_output=True, text=True)
            self.assertNotEqual(denied.returncode, 0)
            self.assertFalse(output.exists())
            denied = subprocess.run(command + ["--route-a", "--output", str(source)], capture_output=True, text=True)
            self.assertNotEqual(denied.returncode, 0)
            denied = subprocess.run(command + ["--route-a", "--output", str(output), "--report", str(source)],
                                    capture_output=True, text=True)
            self.assertNotEqual(denied.returncode, 0)
            self.assertEqual(source.read_text(), original)
            done = subprocess.run(command + ["--route-a", "--output", str(output)], capture_output=True, text=True)
            self.assertEqual(done.returncode, 0, done.stderr)
            self.assertTrue(json.loads(done.stdout)["complete"])
            self.assertEqual(source.read_text(), original)
            self.assertIn("GENERATED: native Linux route (a)", output.read_text())
            self.assertIn("import OpenUIKit\n", output.read_text())

    def test_cli_never_emits_partial_dispatch(self):
        with tempfile.TemporaryDirectory() as temporary:
            source = Path(temporary) / "Input.swift"
            output = Path(temporary) / "Output.swift"
            source.write_text("class Example { func wire() { use(#selector(missing)) } }")
            done = subprocess.run([sys.executable, str(HERE / "route_a_selectors.py"), "rewrite",
                                   "--route-a", str(source), "--output", str(output)],
                                  capture_output=True, text=True)
            self.assertEqual(done.returncode, 2)
            self.assertFalse(output.exists())


if __name__ == "__main__":
    unittest.main()
