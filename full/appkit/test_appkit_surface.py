from pathlib import Path
import hashlib
import unittest


FULL = Path(__file__).resolve().parents[1]
APPKIT = FULL / "appkit/AppKit.swift"
SWIFTUI = FULL / "appkit/SwiftUIAppKitCompatibility.swift"
STOREKIT = FULL / "storekit/StoreKit.swift"
TESTS = FULL / "appkit/tests"
CORE_BUILDER = FULL / "frameworks/build_core_guest_package.sh"
CORE_MANIFEST = FULL / "frameworks/core_package_manifest.py"
CANONICAL_MANIFEST = FULL / "xcodeplan/core_guest_package.py"


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
        storekit = (TESTS / "StoreKitAppKitRuntime.swift").read_text(
            encoding="utf-8"
        )
        self.assertIn("product.purchase(confirmIn: NSWindow())", storekit)
        self.assertIn("case .paymentsUnavailable", storekit)
        self.assertIn("APPKIT_STOREKIT_MACHO_OK", storekit)

    def test_full_untouched_frontier_driver_accepts_only_a_later_wall(self):
        driver = (
            TESTS / "test_revenuecat_appkit_frontier_guest.sh"
        ).read_text(encoding="utf-8")
        for token in (
            "tracked Swift source count",
            "selected source count",
            "no such module 'AppKit'",
            "versioned AppKit framework binary is missing",
            "compile and runtime AppKit framework binaries differ",
            "-F frameworks exactly once",
            "-framework AppKit exactly once",
            "REVENUECAT_APPKIT_FRONTIER_OK",
        ):
            self.assertIn(token, driver)
        self.assertIn("-module-name RevenueCat -typecheck", driver)
        self.assertIn('"${selected_sources[@]}"', driver)
        self.assertNotIn("sed -i", driver)
        self.assertNotIn("Sources/AppKit.swift", driver)

    def test_revenuecat_host_replay_is_sterile_and_fail_closed(self):
        driver = (
            TESTS / "run_revenuecat_appkit_frontiers_host.sh"
        ).read_text(encoding="utf-8")
        for token in (
            "sha256:138303d276d49b9b3b6aa9ee277dfb30b876e24557f80c07fd5d52044ef2d9d7",
            "--platform linux/arm64",
            "--network none --read-only",
            '"$ROOT:/w:ro"',
            '"$PACKAGE:/package:ro"',
            '"$REVENUECAT:/revenuecat:ro"',
            "test_revenuecat_appkit_frontier_guest.sh",
            "test_revenuecat_frontier_guest.sh",
            ".INVALID-DO-NOT-USE",
            "source_census_sha",
            "HOST_PROOF_COMPLETE",
        ):
            self.assertIn(token, driver)
        self.assertNotIn("docker run --rm -it", driver)

    def test_focused_builder_requires_a_real_versioned_framework(self):
        builder = (TESTS / "build_appkit_focused_guest.sh").read_text(
            encoding="utf-8"
        )
        for token in (
            "-module-name AppKit -module-link-name AppKit",
            "-enable-library-evolution",
            "AppKit.framework/Versions/C/AppKit",
            "arm64-apple-macos.swiftmodule",
            "-install_name \"$APPKIT_ID\"",
            "llvm-nm-18 --defined-only",
            "llvm-nm-18 --undefined-only",
            "llvm-otool-18 -L",
            "EXPECTED_EXPORT_COUNT=198",
            "EXPECTED_EXPORT_SHA=dd9b850d2dcf4deb398752a950248a229",
            "absolute_compile_arguments",
            "appkit-load-identities.txt",
            "AppKitGuestRuntime",
            "AppKitInterfaceOracle",
            "MACHORUN_ROOT",
            "APPKIT_FOCUSED_GUEST_OK",
        ):
            self.assertIn(token, builder)
        self.assertIn("cmp \"$versioned/AppKit\"", builder)
        self.assertIn("AppKit guest interface differs from Apple", builder)

    def test_validator_and_mutations_cover_every_material_boundary(self):
        validator = (
            TESTS / "validate_appkit_focused_guest.sh"
        ).read_text(encoding="utf-8")
        mutations = (
            TESTS / "test_validate_appkit_focused_guest_mutations.sh"
        ).read_text(encoding="utf-8")
        for token in (
            "compile and cold-runtime AppKit binaries differ",
            "AppKit exact export contract drifted",
            "AppKit exact import contract drifted",
            "AppKit binary load closure drifted",
            "AppKit cold oracle differs from Apple",
            "proof module hash drifted",
            "APPKIT_FOCUSED_VALIDATE_OK",
        ):
            self.assertIn(token, validator)
        for mutation in (
            "framework-byte",
            "runtime-byte",
            "module-missing",
            "export-attestation",
            "load-attestation",
            "oracle-log",
            "completion-record",
            "framework-link",
            "install-identity",
            "load-closure",
        ):
            self.assertIn(mutation, mutations)
        self.assertIn("APPKIT_VALIDATOR_MUTATIONS_OK", mutations)

    def test_production_package_owns_the_complete_versioned_appkit_route(self):
        builder = CORE_BUILDER.read_text(encoding="utf-8")
        for token in (
            "APPKIT_SOURCES_MANIFEST=",
            "SWIFTUI_APPKIT_SOURCES_MANIFEST=",
            "write_appkit_sources_attestation",
            "AppKit.framework/Versions/C/AppKit",
            "-module-name AppKit -module-link-name AppKit",
            "-enable-library-evolution",
            "arm64-apple-macos.swiftinterface",
            'ln -s C "$APPKIT_FRAMEWORK/Versions/Current"',
            'ln -s Versions/Current/AppKit "$APPKIT_FRAMEWORK/AppKit"',
            '-install_name "$APPKIT_INSTALL_NAME"',
            "EXPECTED_APPKIT_EXPORT_COUNT=198",
            "EXPECTED_APPKIT_EXPORT_SHA=dd9b850d2dcf4deb398752a950248a229",
            "EXPECTED_APPKIT_IMPORT_SHA=58c8c02cadac24ec680699924a8e4bcc",
            'cmp "$APPKIT_LOAD_IDENTITIES"',
            "libSwiftUI AppKit load count",
            "APPKIT_GUEST_MACHO_OK",
            "APPKIT_SWIFTUI_COLOR_MACHO_OK",
            "APPKIT_STOREKIT_MACHO_OK",
            "attestation/appkit-framework.tsv",
            "--appkit-sources attestation/appkit-sources.tsv",
            "-F frameworks -framework AppKit -framework IOKit",
            'if [ "$framework" = StoreKit ]; then',
            "expected_appkit_load=1",
        ):
            self.assertIn(token, builder)
        self.assertNotIn("lib/libAppKit.dylib", builder)

        for validator_path in (CORE_MANIFEST, CANONICAL_MANIFEST):
            validator = validator_path.read_text(encoding="utf-8")
            for token in (
                "appkit_sources",
                "require_appkit_framework_contract",
                "AppKit.framework/Versions/C/AppKit",
                "arm64-apple-macos.private.swiftinterface",
                "AppKit compile/runtime framework identities differ",
                "Versions/Current/AppKit",
                "Versions/Current/Modules",
                "not libAppKit",
            ):
                self.assertIn(token, validator)


if __name__ == "__main__":
    unittest.main()
