#!/usr/bin/env python3
"""Static regression teeth for the source-unchanged guest proof boundary."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]
BUILD = ROOT / "full/swiftui/build_focus_widget_guest.sh"
ACCESSOR = ROOT / "full/swiftui/FocusWidgetBundle.generated.swift"
HARNESS = ROOT / "full/swiftui/FocusWidgetGuestMain.swift"


class FocusWidgetGuestProofTests(unittest.TestCase):
    def test_build_compiles_pinned_focus_paths_directly(self) -> None:
        text = BUILD.read_text()
        self.assertIn('"$FOCUS_WIDGET/Assets.swift"', text)
        self.assertIn('"$FOCUS_WIDGET/SearchWidgetView.swift"', text)
        self.assertIn("efac8d1c98b562374e54eea7540b4201523db670a6353eff8f0a0273d294526e", text)
        self.assertIn("721669388a4556e1609f580ed87d6065b63981770e71b0f77db292767b05f6c2", text)
        self.assertNotRegex(text, r"(?m)^\s*(cp|sed|perl|python\d*)\b.*\$FOCUS_WIDGET/(Assets|SearchWidgetView)\.swift")

    def test_generated_and_harness_files_admit_their_boundary(self) -> None:
        self.assertIn("Generated build support", ACCESSOR.read_text())
        harness = HARNESS.read_text()
        self.assertIn("proof tooling, not Focus application source", harness)
        self.assertIn("SearchWidgetView(", harness)
        self.assertIn("UIRenderer.render", harness)
        self.assertIn("cpio_write_file", harness)

    def test_foundation_hidden_and_mach_o_runtime_gates_exist(self) -> None:
        text = BUILD.read_text()
        self.assertIn("guard_no_foundation.swift", text)
        self.assertIn("llvm-otool-18 -hv", text)
        self.assertIn("MH_MAGIC_64[[:space:]]+ARM64", text)
        self.assertIn('scripts/require_fresh_root.sh" "$MRROOT"', text)
        self.assertIn('"$MRROOT/machorun" ./focus_widget_guest', text)
        for forbidden in ("Foundation.framework", "SwiftUI.framework", "SwiftUICore.framework"):
            self.assertIn(forbidden.replace(".", r"\."), text)

    def test_frameworks_are_real_dylibs_with_exact_identity_and_rpaths(self) -> None:
        text = BUILD.read_text()
        self.assertIn("-dylib -install_name @rpath/libOpenUIKit.dylib", text)
        self.assertIn("-dylib -install_name @rpath/libSwiftUI.dylib", text)
        self.assertIn('"$PACKAGE/libOpenUIKit.dylib"', text)
        self.assertIn('"$PACKAGE/libSwiftUI.dylib"', text)
        self.assertIn('"libOpenUIKit LC_ID_DYLIB"', text)
        self.assertIn('"libSwiftUI LC_ID_DYLIB"', text)
        self.assertIn('"guest LC_RPATH set"', text)
        self.assertIn("expected_openuikit_loads", text)
        self.assertIn("expected_swiftui_loads", text)
        self.assertIn("expected_guest_loads", text)
        self.assertIn("EXPECTED_PACKAGE_FILE_COUNT=51", text)
        self.assertIn("EXPECTED_PACKAGE_DIRECTORY_COUNT=6", text)
        self.assertIn('assert_exact_text "package top-level inventory"', text)
        self.assertIn("packaged CQuartz headers drifted", text)
        self.assertIn('rm -rf "$MC"', text)

    def test_executable_links_frameworks_instead_of_their_objects(self) -> None:
        text = BUILD.read_text()
        focus_compile = text.split('echo "== FocusWidget', 1)[1].split(
            'echo "== guest harness', 1
        )[0]
        harness_compile = text.split('echo "== guest harness', 1)[1].split(
            'echo "== package OpenUIKit', 1
        )[0]
        for compile_step in (focus_compile, harness_compile):
            self.assertIn('"${PACKAGE_CINC[@]}"', compile_step)
            self.assertIn('-I "$PACKAGE"', compile_step)
            self.assertNotIn('-I "$FULL"', compile_step)
            self.assertNotIn('"${CINC[@]}"', compile_step)
        link = text.split('echo "== link arm64 Mach-O against packaged dylibs', 1)[1]
        link = link.split("llvm-otool-18 -hv", 1)[0]
        self.assertIn('-L"$PACKAGE" -lSwiftUI -lOpenUIKit', link)
        self.assertNotIn('"$OUT/swiftui.o"', link)
        self.assertNotIn('"$FULL/openuikit.o"', link)
        self.assertNotIn('"$FULL/opencoregraphics.o"', link)
        self.assertIn('"$AUDIT/focus_widget_guest.link-map"', link)
        self.assertIn("executable link map contains framework object", text)
        self.assertIn("expected_openuikit_inputs", text)
        self.assertIn("expected_swiftui_inputs", text)
        self.assertIn("expected_guest_inputs", text)
        self.assertIn('assert_exact_text "guest linker inputs"', text)

    def test_symbol_provider_and_missing_dylib_controls_are_fail_closed(self) -> None:
        text = BUILD.read_text()
        self.assertIn("libOpenUIKit.defined", text)
        self.assertIn("libSwiftUI.defined", text)
        self.assertIn("focus_widget_guest.defined", text)
        self.assertIn("executable still contains static framework definitions", text)
        self.assertIn("app SwiftUI imports do not bind to libSwiftUI", text)
        self.assertIn("SwiftUI imports do not bind to libOpenUIKit", text)
        self.assertIn("missing-swiftui-control", text)
        self.assertIn("missing-libSwiftUI control exited", text)
        self.assertIn("missing-libSwiftUI discriminator changed", text)
        self.assertIn("missing-openuikit-control", text)
        self.assertIn("missing-libOpenUIKit control exited", text)
        self.assertIn("missing-libOpenUIKit requester changed", text)

    def test_cross_process_pixels_and_packaged_artifacts_are_bracketed(self) -> None:
        text = BUILD.read_text()
        self.assertIn("focus-search-widget.first.png", text)
        self.assertIn("separate guest processes emitted different PNG bytes", text)
        self.assertIn("separate guest processes emitted different proof logs", text)
        self.assertIn("printf 'libSwiftUI\\t%s\\n'", text)
        self.assertIn("printf 'libOpenUIKit\\t%s\\n'", text)
        self.assertIn("printf 'SwiftUI-module\\t%s\\n'", text)
        self.assertIn("printf 'package-tree\\t%s\\n'", text)
        self.assertIn("printf 'SwiftUI-package/tree\\t%s\\n'", text)
        self.assertIn("printf 'libSwiftUI.dylib\\t%s\\n'", text)
        self.assertIn("printf 'libOpenUIKit.dylib\\t%s\\n'", text)

    def test_normalized_bundle_is_hash_pinned(self) -> None:
        text = BUILD.read_text()
        for digest in (
            "2eb8af32cc6d69161dc35f1536682dcba2dd4db21ea0015cf241701f32468d12",
            "180d76a144c6e74324283e8bfb72d9d7bb32125fe57769e3403b0ca72b6ef415",
            "75759bdc8a68e4694bda34486c47e347ab8af010ebb8de7372b0ca443c08186b",
            "f71bc94e686809660d920da6f7804174097e038302a843c3533da45ceda44af2",
            "144c49c747d4689d9ca98d353cb5474b311473629383a779d99f1b705969a04d",
        ):
            self.assertIn(digest, text)
        self.assertIn("EXPECTED_RESOURCE_FILE_COUNT=16", text)
        self.assertIn("EXPECTED_RESOURCE_DIRECTORY_COUNT=7", text)
        self.assertIn("! -type d ! -type f", text)
        self.assertIn("resource_input_after", text)

    def test_runtime_proves_pixels_clipping_and_determinism(self) -> None:
        harness = HARNESS.read_text()
        self.assertIn(".frame(width: 135, height: 135)", harness)
        self.assertIn(".clipShape(RoundedRectangle(cornerRadius: 20))", harness)
        self.assertIn("let renderScale: CGFloat = 2", harness)
        self.assertIn("first.width == 270 && first.height == 270", harness)
        self.assertIn("first.pixels == second.pixels", harness)
        self.assertIn("png == repeatedPNG", harness)
        self.assertIn("gradientLeft != gradientRight", harness)
        self.assertIn("label.isHidden = true", harness)
        self.assertIn("pixelDifference(first, titleHidden, in: titleFrame)", harness)
        self.assertIn("titleDifference.count >= 30", harness)
        for name in ("titlePixels", "searchPixels", "logoPixels"):
            self.assertIn(name, harness)

    def test_font_and_complete_subject_brackets_are_explicit(self) -> None:
        text = BUILD.read_text()
        self.assertIn("DejaVuSans.ttf", text)
        self.assertIn("DejaVuSans-Bold.ttf", text)
        self.assertIn("support_before=$(support_digest)", text)
        self.assertIn("runtime_before=$(runtime_fingerprint)", text)
        self.assertIn("runtime_after=$(runtime_fingerprint)", text)
        self.assertIn("SUBSTRATE_MANIFEST=$FULL/focus-widget-substrate.sha256", text)
        self.assertIn("substrate_artifact_digest", text)
        self.assertIn("SKIP_FULL_BUILD substrate artifacts drifted", text)


if __name__ == "__main__":
    unittest.main()
