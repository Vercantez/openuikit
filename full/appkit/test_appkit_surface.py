from pathlib import Path
import hashlib
import unittest


FULL = Path(__file__).resolve().parents[1]
APPKIT = FULL / "appkit/AppKit.swift"
SWIFTUI = FULL / "appkit/SwiftUIAppKitCompatibility.swift"
STOREKIT = FULL / "storekit/StoreKit.swift"
TESTS = FULL / "appkit/tests"


class AppKitSurfaceTests(unittest.TestCase):
    def test_complete_revenuecat_surface_is_implemented(self):
        source = APPKIT.read_text(encoding="utf-8")
        for declaration in (
            "open class NSApplication",
            "public struct ModalResponse",
            "open class NSWindow",
            "open class NSButton",
            "open class NSAlert",
            "public struct Style",
            "open class NSWorkspace",
            "open class NSFont",
            "open class NSFontManager",
            "open class NSColor",
        ):
            self.assertIn(declaration, source)
        for spelling in (
            "willBecomeActiveNotification",
            "willResignActiveNotification",
            "didResignActiveNotification",
            "didBecomeActiveNotification",
            "alertFirstButtonReturn",
            "alertSecondButtonReturn",
            "alertThirdButtonReturn",
            "addButton(withTitle",
            "runModal()",
            "open(_ url: URL)",
            "inFileViewerRootedAtPath",
            "availableFonts",
            "availableFontFamilies",
            "availableMembers(ofFontFamily",
            "getRed(",
        ):
            self.assertIn(spelling, source)

    def test_headless_operations_fail_closed(self):
        source = APPKIT.read_text(encoding="utf-8")
        self.assertGreaterEqual(source.count("return false"), 2)
        self.assertIn("caseInsensitiveCompare(\"cancel\")", source)
        self.assertIn("return .abort", source)
        self.assertIn("return nil", source)
        self.assertNotIn("Process(", source)
        self.assertNotIn("xdg-open", source)

    def test_swiftui_color_bridge_preserves_fixed_rgba(self):
        source = SWIFTUI.read_text(encoding="utf-8")
        self.assertIn("init(nsColor: NSColor)", source)
        self.assertIn("convenience init(_ color: _OpenColor)", source)
        self.assertIn("case .resolved(let color)", source)
        self.assertIn("case .named:", source)
        self.assertIn("return (0, 0, 0, 0)", source)
        self.assertIn("components.alpha * opacity", source)

    def test_storekit_window_purchase_is_fail_closed(self):
        source = STOREKIT.read_text(encoding="utf-8")
        self.assertIn("@_exported import AppKit", source)
        self.assertIn("confirmIn window: NSWindow", source)
        self.assertIn("throw StoreKitPortableError(.paymentsUnavailable)", source)

    def test_apple_golden_is_exact_and_ten_rows(self):
        golden = (TESTS / "appkit-interface-apple-xcode-26.1.txt").read_bytes()
        self.assertEqual(len(golden.decode().splitlines()), 10)
        self.assertEqual(
            hashlib.sha256(golden).hexdigest(),
            "7e6460172de03f740a085b12550ed6c1fa4f041706103bf62d4d413a385c90ff",
        )

    def test_revenuecat_subject_is_pinned_without_source_edits(self):
        census = (TESTS / "revenuecat-appkit-frontier.tsv").read_text(
            encoding="utf-8"
        )
        self.assertIn("commit=57043e7e0173c48d64e171944ac76a34d2467fa1", census)
        self.assertIn("tree=72a2e1e9b6986fadca9b863d235c4a52aab38fb4", census)
        self.assertIn("sources=530/531", census)
        self.assertEqual(census.count("\nsource\t"), 10)
        self.assertIn("PurchasesReceiptParser+Extensions.swift", census)

    def test_runtime_gates_cover_behavior_not_just_import(self):
        runtime = (TESTS / "AppKitGuestRuntime.swift").read_text(encoding="utf-8")
        color = (TESTS / "SwiftUIAppKitColorRuntime.swift").read_text(
            encoding="utf-8"
        )
        self.assertIn("alert.runModal() == .alertThirdButtonReturn", runtime)
        self.assertIn("noCancel.runModal() == .abort", runtime)
        self.assertIn("!workspace.open(url)", runtime)
        self.assertIn("NSFontManager.shared.availableFonts.isEmpty", runtime)
        self.assertIn("Color(nsColor: source)", color)
        self.assertIn("NSColor(color)", color)


if __name__ == "__main__":
    unittest.main()
