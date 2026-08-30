#!/usr/bin/env python3
"""Static regression teeth for the source-unchanged guest proof boundary."""

from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[2]
BUILD = ROOT / "full/swiftui/build_focus_widget_guest.sh"
ACCESSOR = ROOT / "full/swiftui/FocusWidgetBundle.generated.swift"
HARNESS = ROOT / "full/swiftui/FocusWidgetGuestMain.swift"
ATTEST = ROOT / "full/swiftui/focus_widget_guest_attest.pl"
ADVERSARIAL = ROOT / "full/swiftui/test_focus_widget_guest_adversarial.sh"
BUILD_FULL = ROOT / "full/scripts/build_full.sh"


class FocusWidgetGuestProofTests(unittest.TestCase):
    def test_build_compiles_pinned_focus_paths_directly(self) -> None:
        text = BUILD.read_text()
        self.assertIn(
            "EXPECTED_UIKIT_COMMIT="
            "8f98af2e53af566923de6616f3629bec0661aa8c",
            text,
        )
        self.assertIn(
            "EXPECTED_UIKIT_TREE="
            "a8b809d35b52ef317517914922392f395a8da59c",
            text,
        )
        self.assertIn("OpenUIKit checkout is not clean", text)
        self.assertIn("pinned OpenUIKit checkout changed during execution", text)
        self.assertIn("printf 'uikit_commit\\t%s\\n'", text)
        self.assertIn("printf 'uikit_tree\\t%s\\n'", text)
        self.assertIn('"$FOCUS_WIDGET/Assets.swift"', text)
        self.assertIn('"$FOCUS_WIDGET/SearchWidgetView.swift"', text)
        self.assertIn("efac8d1c98b562374e54eea7540b4201523db670a6353eff8f0a0273d294526e", text)
        self.assertIn("721669388a4556e1609f580ed87d6065b63981770e71b0f77db292767b05f6c2", text)
        self.assertNotRegex(text, r"(?m)^\s*(cp|sed|perl|python\d*)\b.*\$FOCUS_WIDGET/(Assets|SearchWidgetView)\.swift")

    def test_compatibility_support_and_harness_admit_their_boundary(self) -> None:
        accessor = ACCESSOR.read_text()
        self.assertIn("compatibility build support", accessor)
        self.assertIn("declares no Widget resources", accessor)
        self.assertIn("SWIFT_MODULE_RESOURCE_BUNDLE_UNAVAILABLE", accessor)
        self.assertNotIn("SwiftPM-equivalent", accessor)
        self.assertIn('"Focus_Widget.bundle"', accessor)
        self.assertIn("Bundle.main.bundleURL.appendingPathComponent", accessor)
        self.assertIn("guard let bundle = Bundle(url: url)", accessor)
        self.assertIn("_ = Gradient.quickAccessWidget", accessor)
        self.assertIn("_ = Image.logo", accessor)
        self.assertIn("@MainActor", accessor)
        harness = HARNESS.read_text()
        self.assertIn("proof tooling, not Focus application source", harness)
        self.assertIn("SearchWidgetView(", harness)
        self.assertIn("UIRenderer.render", harness)
        self.assertIn("cpio_write_file", harness)
        self.assertIn(
            "FocusWidgetResourceProof.bundlePath == resourceBundle", harness
        )
        self.assertIn(
            "FocusWidgetResourceProof.resourcePath == resourceBundle", harness
        )
        self.assertIn("FocusWidgetResourceProof.exerciseUnchangedAssets()", harness)
        self.assertNotIn("OpenUIKitRuntime.imageSearchPaths", harness)

    def test_foundation_hidden_and_mach_o_runtime_gates_exist(self) -> None:
        text = BUILD.read_text()
        self.assertIn("foundationessentials_import_guard.swift", text)
        self.assertIn('SYS=$W/scratch/sysroot_fe4', text)
        self.assertIn('-target arm64-apple-macos15.0', text)
        self.assertIn('"${FE_FLAGS[@]}"', text)
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
        self.assertIn("EXPECTED_PACKAGE_FILE_COUNT=96", text)
        self.assertIn("EXPECTED_PACKAGE_DIRECTORY_COUNT=12", text)
        self.assertIn('assert_exact_text "package top-level inventory"', text)
        self.assertIn('assert_exact_text "package directory inventory"', text)
        self.assertIn('assert_exact_text "FoundationEssentials module inventory"', text)
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
            self.assertIn('"${FE_FLAGS[@]}"', compile_step)
            self.assertIn('-I "$PACKAGE"', compile_step)
            self.assertNotIn('-I "$FULL"', compile_step)
            self.assertNotIn('"${CINC[@]}"', compile_step)
        self.assertIn('-I "$PACKAGE/modules/FoundationEssentials"', text)
        self.assertNotIn('FE_FLAGS=(-I "$FE_OUT"', text)
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

    def test_openuikit_link_inputs_cover_main_actor_deinit_provider(self) -> None:
        text = BUILD.read_text()
        expected = text.split("expected_openuikit_inputs=", 1)[1].split(
            "expected_swiftui_inputs=", 1
        )[0]
        self.assertIn('"$MRROOT/darwin/usr/lib/libSystem.B.dylib"', expected)
        self.assertIn('"$FULL/openuikit.o"', expected)

    def test_swiftui_package_compiles_and_attests_complete_source_directory(self) -> None:
        text = BUILD.read_text()
        helper = ATTEST.read_text()
        self.assertIn('SWIFTUI_SOURCE_DIR=$UIKIT/Sources/SwiftUI', text)
        self.assertIn('SWIFTUI_SOURCES=("$SWIFTUI_SOURCE_DIR"/*.swift)', text)
        self.assertIn('"${SWIFTUI_SOURCES[@]}"', text)
        self.assertIn('unsupported SwiftUI source node', text)
        self.assertIn("[ \"$uikit/Sources/SwiftUI\", 'openuikit/Sources/SwiftUI' ]", helper)

    def test_observation_closes_over_sibling_combine_dylibs(self) -> None:
        text = BUILD.read_text()
        helper = ATTEST.read_text()
        for dylib in ("libCombine.dylib", "libOpenCombine.dylib"):
            self.assertIn(dylib, text)
        self.assertIn("-lOpenUIKit -lOpenCoreGraphics -lCombine -lOpenCombine", text)
        self.assertIn("OPENCOMBINE_ROOT", text)
        self.assertIn("OpenCombine.o", helper)
        self.assertIn("COpenCombineHelpers.cpp", helper)
        self.assertIn("OpenCombine root is outside project root", helper)
        self.assertIn("OpenCombine input $_->[1]", helper)
        self.assertIn("OpenCombine => 'libCombine'", helper)
        self.assertIn("OpenCombine => 'libOpenCombine'", helper)

    def test_symbol_provider_and_missing_dylib_controls_are_fail_closed(self) -> None:
        text = BUILD.read_text()
        self.assertIn("libOpenUIKit.defined", text)
        self.assertIn("libOpenCoreGraphics.defined", text)
        self.assertIn("libSwiftUI.defined", text)
        self.assertIn("focus_widget_guest.defined", text)
        self.assertIn("framework-providers.tsv", text)
        self.assertIn('perl "$ATTEST" providers', text)
        self.assertIn('--opencoregraphics "$PACKAGE/libOpenCoreGraphics.dylib"', text)
        self.assertIn("--demangle swift-demangle", text)
        self.assertIn("Universal, non-vacuous two-level provider gate", text)
        self.assertIn("_$sxSg7SwiftUI9_OpenViewA2bCRzlMc", text)
        self.assertIn("_$s4Body7SwiftUI9_OpenViewPTl", text)
        self.assertIn("_$s10ObjectiveC8SelectorV9OpenUIKitE10actionNameSSvg", text)
        self.assertIn("_OBJC_CLASS_$__TtC9OpenUIKit11UITextRange", text)
        self.assertIn("_$s16OpenCoreGraphics6CGRectV0A5UIKitE5inset", text)
        self.assertIn("missing-swiftui-control", text)
        self.assertIn("missing-libSwiftUI control exited", text)
        self.assertIn("missing-libSwiftUI discriminator changed", text)
        self.assertIn("missing-openuikit-control", text)
        self.assertIn("missing-libOpenUIKit control exited", text)
        self.assertIn("missing-libOpenUIKit requester changed", text)
        self.assertIn("run_missing_observation_control combine libCombine.dylib", text)
        self.assertIn("run_missing_observation_control opencombine libOpenCombine.dylib", text)
        self.assertIn("missing-$missing_name requester changed", text)

    def test_cross_process_pixels_and_packaged_artifacts_are_bracketed(self) -> None:
        text = BUILD.read_text()
        self.assertIn("focus-search-widget.first.png", text)
        self.assertIn("separate guest processes emitted different PNG bytes", text)
        self.assertIn("separate guest processes emitted different proof logs", text)
        self.assertIn("printf 'libSwiftUI\\t%s\\n'", text)
        self.assertIn("printf 'libOpenUIKit\\t%s\\n'", text)
        self.assertIn("printf 'SwiftUI-module\\t%s\\n'", text)
        self.assertIn("printf 'package-tree\\t%s\\n'", text)
        self.assertIn("printf 'FocusWidgetBundle.generated.swift\\t%s\\n'", text)
        self.assertIn("printf 'SwiftUI-package/per-run-tree\\t%s\\n'", text)
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
        self.assertIn("BUILD_INPUT_MANIFEST=$FULL/focus-widget-build-inputs.manifest", text)
        self.assertIn("assert_build_input_inventory", text)
        self.assertIn("complete build-input inventory drifted", text)
        self.assertIn("complete-build-inputs/per-run-manifest", text)
        self.assertIn("SwiftUI.swiftsourceinfo/per-run", text)
        self.assertIn("SwiftUI-package/per-run-tree", text)
        self.assertNotIn("complete-build-inputs/manifest\\t", text)
        self.assertNotIn("SwiftUI-package/tree\\t", text)

    def test_complete_resume_inventory_covers_all_consumed_cache_trees(self) -> None:
        helper = ATTEST.read_text()
        for artifact in (
            "foundationessentials_import_guard.swift",
            "build-full/foundation/essentials",
            "build-full/foundation/collections",
            "build-full/foundation/os",
            "build-full/foundation/cshims",
            "sdk/sysroot_fe4",
            '"$full/OpenUIKit.$_"',
            '"$full/OpenCoreGraphics.$_"',
            "qw(swiftmodule swiftdoc swiftsourceinfo abi.json)",
            "inc/CPortableIO",
            "inc/CSTBTrueType",
        ):
            self.assertIn(artifact, helper)
        for linker_input in (
            "libswiftCore.tbd",
            "libSystem.tbd",
            "libobjc.tbd",
            "libswift_Concurrency.tbd",
            "libswiftObjectiveC.tbd",
            "libswiftDarwin.tbd",
            "libswift_StringProcessing.tbd",
            "libswiftSynchronization.tbd",
        ):
            self.assertIn(linker_input, helper)
        self.assertIn("unsupported inventory node type", helper)
        self.assertIn("symlink target", helper)

    def test_build_and_runtime_manifests_are_atomic_and_resume_cannot_rewrite(self) -> None:
        text = BUILD.read_text()
        self.assertIn('mktemp "$FULL/.focus-widget-build-inputs.recording.XXXXXX"', text)
        self.assertIn('mv "$build_input_recording" "$BUILD_INPUT_MANIFEST"', text)
        self.assertIn('mktemp "$FULL/.focus-widget-runtime-closure.recording.XXXXXX"', text)
        self.assertIn('mv "$runtime_closure_recording" "$RUNTIME_CLOSURE_MANIFEST"', text)
        normal = text.split('if [ "$skip_full_build" != 1 ]; then', 1)[1]
        self.assertIn('else\n    [ -f "$BUILD_INPUT_MANIFEST" ]', normal)
        runtime = text.split("Resolve the executable's complete transitive", 1)[1]
        self.assertIn('else\n    [ -f "$RUNTIME_CLOSURE_MANIFEST" ]', runtime)
        self.assertGreaterEqual(text.count("assert_build_input_inventory"), 6)
        self.assertGreaterEqual(text.count("assert_runtime_closure"), 5)

    def test_recursive_runtime_closure_includes_extensionless_substrate_stubs(self) -> None:
        helper = ATTEST.read_text()
        self.assertIn("macho_commands", helper)
        self.assertIn("LC_REEXPORT_DYLIB", helper)
        self.assertIn("LC_LOAD_WEAK_DYLIB", helper)
        self.assertIn("weak-missing", helper)
        self.assertIn("Foundation.framework/Foundation", helper)
        self.assertIn("CoreFoundation.framework/CoreFoundation", helper)
        self.assertIn("known substrate stub is absent from recursive closure", helper)
        build_full = BUILD_FULL.read_text()
        self.assertIn("restaging $framework loud-abort stub", build_full)
        self.assertIn("staged\\tdarwin/System/Library/Frameworks/%s.framework/%s", build_full)

    def test_provider_gate_is_universal_and_rejects_reverse_ownership(self) -> None:
        helper = ATTEST.read_text()
        for module in ("SwiftUI", "OpenUIKit", "OpenCoreGraphics", "Combine", "OpenCombine"):
            self.assertIn(module, helper)
        self.assertIn("no two-level bind", helper)
        self.assertIn("expected exactly", helper)
        self.assertIn("does not define imported symbol", helper)
        self.assertIn("reverse ownership violation", helper)
        self.assertIn("bind table contains framework symbol absent from undefined table", helper)
        self.assertIn("vacuous provider gate", helper)
        self.assertIn("unclassified framework-bearing symbol", helper)
        self.assertIn("associated type descriptor", helper)
        self.assertIn("extension in", helper)
        self.assertIn("^_OBJC_(?:CLASS|METACLASS)_\\$__TtC", helper)
        self.assertIn("^_OBJC_IVAR_\\$__TtC", helper)
        self.assertIn("for (1 .. $nested_count + 2)", helper)
        self.assertIn("length($class_tail) == 0", helper)
        self.assertNotIn("_Tt[A-Za-z]*9OpenUIKit", helper)
        self.assertIn("'definition'", helper)

    def test_objc_old_mangling_classifier_behavior(self) -> None:
        result = subprocess.run(
            ["perl", str(ATTEST), "objc-classifier-selftest"],
            check=True,
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            result.stdout,
            "OBJC_CLASSIFIER_SELFTEST_OK positives=7 negatives=13\n",
        )

    def test_adversarial_resume_matrix_covers_reviewed_tamper_classes(self) -> None:
        text = ADVERSARIAL.read_text()
        for label in (
            "guard-source",
            "swiftmodule",
            "foundationessentials-swiftmodule",
            "modulemap",
            "header",
            "header-extra",
            "header-missing",
            "header-symlink",
            "sysroot-tbd",
            "extensionless-stub",
            "runtime-ancestor-symlink",
            "provider-logic",
            "inventory-logic",
        ):
            self.assertIn(label, text)
        self.assertIn("expect_resume_refusal", text)
        self.assertIn("reached guest success before refusal", text)
        self.assertIn("clean isolated resume completed", text)
        helper = ATTEST.read_text()
        self.assertIn("require_regular_beneath_no_links", helper)
        self.assertIn("path component is a symlink", helper)


if __name__ == "__main__":
    unittest.main()
