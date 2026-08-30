#!/usr/bin/env python3
"""Regression teeth for the unchanged Focus onboarding guest boundary."""

from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[2]
BUILD = ROOT / "full/swiftui/build_focus_onboarding_guest.sh"
HARNESS = ROOT / "full/swiftui/FocusOnboardingGuestMain.swift"
UUID_PROBE = ROOT / "full/swiftui/FocusOnboardingUUIDProbe.c"
UUID_COMPAT = ROOT / "full/foundation/uuid_compat.c"
FOUNDATION = ROOT / "full/appshim/FoundationGuest.swift"
ACCESSOR = ROOT / "full/swiftui/FocusOnboardingBundle.generated.swift"
BUILD_FULL = ROOT / "full/scripts/build_full.sh"
STUBS = ROOT / "full/foundation/fm_unimplemented.c"


class FocusOnboardingGuestProofTests(unittest.TestCase):
    def test_build_script_has_valid_shell_syntax(self) -> None:
        subprocess.run(["bash", "-n", str(BUILD)], check=True)

    def test_exact_twelve_source_boundary_is_hash_pinned_and_direct(self) -> None:
        text = BUILD.read_text()
        self.assertIn("EXPECTED_FOCUS_COMMIT=a2832521c1daa0c23419c73705ae043ed60c9791", text)
        self.assertIn("expected the complete six-source SwiftUI directory", text)
        relatives = re.findall(r"^    '([^']+\.swift)'$", text, re.MULTILINE)
        self.assertEqual(len(relatives), 12)
        hashes = re.search(
            r"SOURCE_HASHES=\(\n(.*?)\n\)", text, re.DOTALL
        ).group(1)
        self.assertEqual(len(re.findall(r"^[ ]{4}[0-9a-f]{64}$", hashes, re.MULTILINE)), 12)
        self.assertIn('"${onboarding_sources[@]}"', text)
        self.assertIn('"$FOCUS_WIDGET/Assets.swift"', text)
        self.assertIn('"$FOCUS_WIDGET/SearchWidgetView.swift"', text)
        self.assertNotRegex(
            text,
            r"(?m)^\s*(cp|sed|perl|python\d*)\b.*\$FOCUS_(ONBOARDING|WIDGET).*\.swift",
        )

    def test_inputs_are_clean_and_resources_are_content_pinned(self) -> None:
        text = BUILD.read_text()
        self.assertIn("assert_clean_commit", text)
        self.assertIn("EXPECTED_UIKIT_COMMIT=13479babf5caf308973388c7fdc789f9116750c0", text)
        for digest in (
            "3db199a93294a4ea0e6549522c29e8b2e4dbfb979bd60c07cdad5d00386734f5",
            "144c49c747d4689d9ca98d353cb5474b311473629383a779d99f1b705969a04d",
        ):
            self.assertIn(digest, text)
        self.assertIn("contains a symlink/special node", text)
        self.assertIn("post-run-Focus", text)
        self.assertIn("post-run-OpenUIKit", text)

    def test_framework_graph_uses_nine_real_macho_dylibs(self) -> None:
        text = BUILD.read_text()
        names = (
            "FoundationEssentials", "OpenCoreGraphics", "OpenUIKit", "Foundation",
            "OpenCombine", "Combine", "SwiftUI", "Widget", "Onboarding",
        )
        for name in names:
            self.assertIn(f"lib{name}.dylib", text)
        self.assertIn("MH_MAGIC_64[[:space:]]+ARM64", text)
        self.assertIn('actual_id=$(llvm-otool-18 -D', text)
        self.assertIn('focus_widget_guest_attest.pl" closure', text)
        self.assertIn('"$MRROOT/machorun" ./focus_onboarding_guest', text)

    def test_foundation_umbrella_preserves_one_essentials_provider(self) -> None:
        source = FOUNDATION.read_text()
        build = BUILD.read_text()
        self.assertIn("@_exported import FoundationEssentials", source)
        self.assertIn("public typealias NSCoder = OpenUIKit.NSCoder", source)
        self.assertIn("public typealias Bundle = OpenUIKit.Bundle", source)
        self.assertIn("func canOpenURL(_ url: URL)", source)
        foundation_link = build.split("libFoundation.dylib", 1)[1].split(
            "libSwiftUI.dylib", 1
        )[0]
        self.assertIn("-lFoundationEssentials", foundation_link)
        self.assertNotIn("-reexport_library", foundation_link)

    def test_uuid_substrate_replaces_stubs_and_is_exercised(self) -> None:
        implementation = UUID_COMPAT.read_text()
        probe = UUID_PROBE.read_text()
        build_full = BUILD_FULL.read_text()
        stubs = STUBS.read_text()
        for symbol in (
            "uuid_clear", "uuid_compare", "uuid_copy", "uuid_generate",
            "uuid_generate_random", "uuid_generate_time", "uuid_is_null",
            "uuid_parse", "uuid_unparse", "uuid_unparse_lower", "uuid_unparse_upper",
        ):
            self.assertIn(f"{symbol}(", implementation)
        self.assertIn("if (high_character == '\\0') return -1", implementation)
        self.assertIn("uuid=full", HARNESS.read_text())
        self.assertIn("open_focus_uuid_compat_probe", probe)
        self.assertIn("version_and_variant(value, 1)", probe)
        self.assertIn("version_and_variant(value, 4)", probe)
        self.assertIn("copy[0] != 0xa5", probe)
        self.assertIn("OPEN_FOUNDATION_UUID_COMPAT", stubs)
        self.assertIn('"$W/full/foundation/uuid_compat.c"', build_full)
        self.assertIn('"$FE_OUT/uuid_compat.o"', build_full)

    def test_guest_checks_host_turn_touches_url_and_dismissal(self) -> None:
        text = HARNESS.read_text()
        self.assertIn("window.hitTest(point, with: nil) === control", text)
        self.assertIn("window.sendTouch(.began", text)
        self.assertIn("window.sendTouch(.ended", text)
        self.assertIn("window.tick(timestamp: 0.1)", text)
        self.assertIn("published navigation rendered synchronously", text)
        self.assertIn("UIApplication.urlOpenHandler", text)
        self.assertIn("dismissals == 1", text)
        self.assertIn("defaultBrowserSettingsTapped", text)
        self.assertIn("defaultBrowserSkip", text)

    def test_generated_support_is_explicitly_not_application_source(self) -> None:
        self.assertIn("not Mozilla Focus application source", ACCESSOR.read_text())
        self.assertIn("Project-owned Linux/machorun harness", HARNESS.read_text())
        self.assertIn("Project-owned runtime probe", UUID_PROBE.read_text())
        self.assertIn("static var module: Bundle { .main }", ACCESSOR.read_text())

    def test_success_marker_is_exact_and_fail_closed(self) -> None:
        build = BUILD.read_text()
        marker = (
            "FOCUS_ONBOARDING_MACHO_GUEST_OK sources=12 pages=2 touches=3 "
            "uuid=full telemetry=getStartedAppeared,getStartedButtonTapped,"
            "defaultBrowserAppeared,defaultBrowserSettingsTapped,defaultBrowserSkip"
        )
        self.assertIn(marker, build)
        harness = HARNESS.read_text()
        self.assertIn('"FOCUS_ONBOARDING_MACHO_GUEST_OK "', harness)
        self.assertIn('"sources=12 pages=2 touches=3 uuid=full telemetry="', harness)
        self.assertIn("exact runtime success marker is missing", build)


if __name__ == "__main__":
    unittest.main()
