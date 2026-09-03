#!/usr/bin/env python3
"""Static regression teeth for the source-unchanged guest proof boundary."""

import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
BUILD = ROOT / "full/swiftui/build_focus_widget_guest.sh"
ACCESSOR = ROOT / "full/swiftui/FocusWidgetBundle.generated.swift"
HARNESS = ROOT / "full/swiftui/FocusWidgetGuestMain.swift"
ATTEST = ROOT / "full/swiftui/focus_widget_guest_attest.pl"
ADVERSARIAL = ROOT / "full/swiftui/test_focus_widget_guest_adversarial.sh"
BUILD_FULL = ROOT / "full/scripts/build_full.sh"
INVENTORIES_PY = ROOT / "full/swiftui/guest_gate_inventories.py"
INVENTORIES_INC = ROOT / "full/swiftui/guest_gate_inventories.inc"
X86_ORACLE = ROOT / "full/swiftui/test_guest_gate_inventories_x86_oracle.sh"
GUEST_ARCH_PY = ROOT / "full/scripts/guest_arch.py"


def _load_module(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


inventories = _load_module(INVENTORIES_PY, "guest_gate_inventories")
guest_arch = _load_module(GUEST_ARCH_PY, "guest_arch")


class FocusWidgetGuestProofTests(unittest.TestCase):
    def test_build_compiles_pinned_focus_paths_directly(self) -> None:
        text = BUILD.read_text()
        self.assertIn(
            "EXPECTED_UIKIT_TREE=$EXPECTED_INREPO_UIKIT_TREE",
            text,
        )
        self.assertIn('assert_vendor_tree "$W" uikit', text)
        self.assertIn("HEAD:uikit", text)
        self.assertIn("attested OpenUIKit source=HEAD:uikit", text)
        self.assertIn("printf 'uikit_tree\\t%s\\n'", text)
        pins = (ROOT / "scripts/vendor_pins.sh").read_text()
        self.assertIn(
            "EXPECTED_INREPO_UIKIT_TREE="
            "e737cdd02e89f8aa7446ee69a6464ac1c2108335",
            pins,
        )
        self.assertNotIn(
            "EXPECTED_UIKIT_COMMIT="
            "62dea0d97a3b9074e5c016820492bd0656b9a35a",
            text,
        )
        self.assertNotIn(
            "EXPECTED_UIKIT_TREE="
            "3dfd6024557632949c9a5036522871a36d4a0cf0",
            text,
        )
        self.assertIn('"$FOCUS_WIDGET/Assets.swift"', text)
        self.assertIn('"$FOCUS_WIDGET/SearchWidgetView.swift"', text)
        actual_tree = subprocess.check_output(
            ["git", "rev-parse", "HEAD:uikit"],
            cwd=ROOT,
            text=True,
        ).strip()
        self.assertEqual(
            actual_tree,
            "e737cdd02e89f8aa7446ee69a6464ac1c2108335",
        )
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

    def test_gate_consumes_env_preparer_before_vendor_attestation(self) -> None:
        text = BUILD.read_text()
        self.assertIn('PREPARE_TOOL=$W/scripts/env/prepare.py', text)
        self.assertIn('LEDGER_TOOL=$W/scripts/env/ledger.py', text)
        self.assertIn(
            'python3 "$PREPARE_TOOL" --contract "$W/env/contract.json" --root "$W"',
            text,
        )
        self.assertLess(
            text.index('export FULL_OUT_SUFFIX'),
            text.index('--gate focus-widget'),
        )
        self.assertIn('--gate focus-widget', text)
        self.assertIn(
            'python3 "$LEDGER_TOOL" --style focus-widget require-hash "$1" "$2" "$3"',
            text,
        )
        self.assertLess(
            text.index('--gate focus-widget'),
            text.index('assert_vendor_tree "$W" uikit'),
        )
        self.assertIn("EXPECTED_UIKIT_TREE=$EXPECTED_INREPO_UIKIT_TREE", text)
        self.assertIn("attested OpenUIKit source=HEAD:uikit", text)
        self.assertIn(
            "efac8d1c98b562374e54eea7540b4201523db670a6353eff8f0a0273d294526e",
            text,
        )
        self.assertIn(
            "721669388a4556e1609f580ed87d6065b63981770e71b0f77db292767b05f6c2",
            text,
        )

    def test_foundation_hidden_and_mach_o_runtime_gates_exist(self) -> None:
        text = BUILD.read_text()
        self.assertIn("foundationessentials_import_guard.swift", text)
        self.assertIn('SYS=$W/scratch/sysroot_fe4${FULL_OUT_SUFFIX}', text)
        self.assertIn('-target "$TARGET"', text)
        self.assertIn('"${FE_FLAGS[@]}"', text)
        self.assertIn("llvm-otool-18 -hv", text)
        self.assertIn("MH_MAGIC_64[[:space:]]+${OTOOL_CPU}", text)
        self.assertIn('scripts/require_fresh_root.sh" "$MRROOT"', text)
        self.assertIn('"$MRROOT/machorun" ./focus_widget_guest', text)
        for forbidden in ("Foundation.framework", "SwiftUI.framework", "SwiftUICore.framework"):
            self.assertIn(forbidden.replace(".", r"\."), text)

    def test_run_step_preloads_shared_dispatch_host_bridge(self) -> None:
        text = BUILD.read_text()
        self.assertIn('bash "$W/full/dispatch/build_host_bridge.sh"', text)
        self.assertIn("EARLY_PLATFORM_HOST_PRELOAD=$DISPATCH_HOST", text)
        preload = (
            'LD_PRELOAD="$EARLY_PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}"'
        )
        self.assertIn(preload, text)
        self.assertEqual(text.count(preload), 5)
        self.assertEqual(text.count('"$MRROOT/machorun" ./focus_widget_guest'), 5)
        self.assertIn(
            'LD_LIBRARY_PATH="$HOST_BRIDGE_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"',
            text,
        )
        self.assertIn("host-libOpenDispatchHost.so", text)
        helper = (ROOT / "full/dispatch/build_host_bridge.sh").read_text()
        self.assertIn("OPEN_DISPATCH_HOST_OK", helper)
        self.assertIn("openui_dispatch_host_v1_get_global_queue", helper)
        self.assertIn("GLIBC_2.38", helper)
        self.assertIn("libBlocksRuntime.so", helper)
        builder = (
            ROOT / "full/frameworks/build_core_guest_package.sh"
        ).read_text()
        self.assertIn('bash "$W/full/dispatch/build_host_bridge.sh"', builder)
        self.assertIn("GLIBC_2.38", builder)

    def test_frameworks_are_real_dylibs_with_exact_identity_and_rpaths(self) -> None:
        text = BUILD.read_text()
        self.assertIn("-dylib -install_name @rpath/libOpenUIKit.dylib", text)
        self.assertIn("-dylib -install_name @rpath/libSwiftUI.dylib", text)
        self.assertIn("-dylib -install_name @rpath/libSymbols.dylib", text)
        self.assertIn('"$PACKAGE/libOpenUIKit.dylib"', text)
        self.assertIn('"$PACKAGE/libSwiftUI.dylib"', text)
        self.assertIn('"$PACKAGE/libSymbols.dylib"', text)
        self.assertIn('"libOpenUIKit LC_ID_DYLIB"', text)
        self.assertIn('"libSwiftUI LC_ID_DYLIB"', text)
        self.assertIn('"libSymbols LC_ID_DYLIB"', text)
        self.assertIn('"guest LC_RPATH set"', text)
        self.assertIn("expected_openuikit_loads", text)
        self.assertIn("expected_swiftui_loads", text)
        self.assertIn("expected_swiftui_inputs", text)
        self.assertIn("expected_symbols_loads", text)
        self.assertIn("expected_guest_loads", text)
        self.assertIn('guest_gate_inventory widget loads swiftui', text)
        self.assertIn('guest_gate_inventory widget inputs swiftui', text)
        self.assertIn(
            "EXPECTED_PACKAGE_FILE_COUNT=$(guest_gate_inventory widget package file_count)",
            text,
        )
        self.assertIn(
            "EXPECTED_PACKAGE_DIRECTORY_COUNT=$(guest_gate_inventory widget package directory_count)",
            text,
        )
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
        link = text.split('echo "== link Mach-O against packaged dylibs', 1)[1]
        link = link.split("llvm-otool-18 -hv", 1)[0]
        self.assertIn('-L"$PACKAGE" -lSwiftUI -lOpenUIKit', link)
        self.assertNotIn('"$OUT/swiftui.o"', link)
        self.assertNotIn('"$FULL/openuikit.o"', link)
        self.assertNotIn('"$FULL/opencoregraphics.o"', link)
        self.assertIn('"$AUDIT/focus_widget_guest.link-map"', link)
        self.assertIn("executable link map contains framework object", text)
        self.assertIn("expected_openuikit_inputs", text)
        self.assertIn("expected_swiftui_inputs", text)
        self.assertIn("expected_symbols_inputs", text)
        self.assertIn("expected_guest_inputs", text)
        self.assertIn('assert_exact_text "guest linker inputs"', text)

    def test_openuikit_link_inputs_cover_main_actor_deinit_provider(self) -> None:
        text = BUILD.read_text()
        self.assertIn('guest_gate_inventory widget inputs openuikit', text)
        expected = inventories.inputs("widget", "openuikit", "arm64")
        self.assertIn("{MRROOT}/darwin/usr/lib/libSystem.B.dylib", expected)
        self.assertIn("{FULL}/openuikit.o", expected)

    def test_swiftui_package_compiles_and_attests_complete_source_directory(self) -> None:
        text = BUILD.read_text()
        helper = ATTEST.read_text()
        self.assertIn('SWIFTUI_SOURCE_DIR=$UIKIT/Sources/SwiftUI', text)
        self.assertIn('SWIFTUI_SOURCES=("$SWIFTUI_SOURCE_DIR"/*.swift)', text)
        self.assertIn('"${SWIFTUI_SOURCES[@]}"', text)
        self.assertIn('unsupported SwiftUI source node', text)
        self.assertIn("[ \"$uikit/Sources/SwiftUI\", 'openuikit/Sources/SwiftUI' ]", helper)
        self.assertIn('SYMBOLS_SOURCE_DIR=$UIKIT/Sources/Symbols', text)
        self.assertIn('SYMBOLS_SOURCES=("$SYMBOLS_SOURCE_DIR"/*.swift)', text)
        self.assertIn("EXPECTED_SYMBOLS_SWIFT_COUNT=1", text)
        self.assertIn('"${SYMBOLS_SOURCES[@]}"', text)
        self.assertIn('unsupported Symbols source node', text)
        self.assertIn("[ \"$uikit/Sources/Symbols\", 'openuikit/Sources/Symbols' ]", helper)

    def test_observation_closes_over_sibling_combine_dylibs(self) -> None:
        text = BUILD.read_text()
        helper = ATTEST.read_text()
        for dylib in ("libCombine.dylib", "libOpenCombine.dylib"):
            self.assertIn(dylib, text)
        self.assertIn("-lOpenUIKit -lOpenCoreGraphics -lCombine -lOpenCombine", text)
        self.assertIn("-lOpenUIKit -lOpenCoreGraphics -lCombine -lOpenCombine -lSymbols", text)
        self.assertIn(
            "-lOpenUIKit -lOpenCoreGraphics -lCombine -lOpenCombine -lSymbols "
            "-lFoundationEssentials",
            text,
        )
        self.assertIn("libSymbols Apple Symbols load count", text)
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
        self.assertIn('--foundationessentials "$PACKAGE/libFoundationEssentials.dylib"', text)
        self.assertIn('--demangle "$SWIFT_DEMANGLE"', text)
        self.assertIn("readlink -f", text)
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
        self.assertIn("run_missing_observation_control symbols libSymbols.dylib", text)
        self.assertIn("missing-$missing_name requester changed", text)
        # Sibling copy lists already include FoundationEssentials (OpenUIKit and
        # the guest load it too). A missing-FE control would be required-by
        # libOpenUIKit, not libSwiftUI, so this change does not add one.
        missing = text.split("run_missing_observation_control combine", 1)[1]
        self.assertGreaterEqual(missing.count("libFoundationEssentials.dylib"), 3)

    def test_cross_process_pixels_and_packaged_artifacts_are_bracketed(self) -> None:
        text = BUILD.read_text()
        self.assertIn("focus-search-widget.first.png", text)
        self.assertIn("separate guest processes emitted different PNG bytes", text)
        self.assertIn("separate guest processes emitted different proof logs", text)
        self.assertIn("printf 'libSwiftUI\\t%s\\n'", text)
        self.assertIn("printf 'libOpenUIKit\\t%s\\n'", text)
        self.assertIn("printf 'libSymbols\\t%s\\n'", text)
        self.assertIn("printf 'SwiftUI-module\\t%s\\n'", text)
        self.assertIn("printf 'package-tree\\t%s\\n'", text)
        self.assertIn("printf 'FocusWidgetBundle.generated.swift\\t%s\\n'", text)
        self.assertIn("printf 'SwiftUI-package/per-run-tree\\t%s\\n'", text)
        self.assertIn("printf 'libSwiftUI.dylib\\t%s\\n'", text)
        self.assertIn("printf 'libOpenUIKit.dylib\\t%s\\n'", text)
        self.assertIn("printf 'libSymbols.dylib\\t%s\\n'", text)

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
        self.assertIn("guest_gate_inventories.py", text)
        self.assertIn("guest_gate_inventories.inc", text)
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
            "guest_gate_inventories.py",
            "guest_gate_inventories.inc",
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

    def test_nested_guest_root_has_canonical_labels_and_tamper_teeth(self) -> None:
        with tempfile.TemporaryDirectory(prefix="nested-guest-root-closure.") as temporary:
            package = Path(temporary) / "package"
            guest_root = package / "guest-root"
            executable = package / "probe/CoreGuestPackageProbe"
            runtime = guest_root / "darwin/usr/lib/swift/libRuntime.dylib"
            foundation = (
                guest_root
                / "darwin/System/Library/Frameworks/Foundation.framework/Foundation"
            )
            core_foundation = (
                guest_root
                / "darwin/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation"
            )
            loader = guest_root / "machorun"
            root_manifest = guest_root / ".manifest"
            for fixture in (
                executable,
                runtime,
                foundation,
                core_foundation,
                loader,
                root_manifest,
            ):
                fixture.parent.mkdir(parents=True, exist_ok=True)
                fixture.write_text(f"{fixture.name}\n", encoding="utf-8")

            fake_otool = Path(temporary) / "fake-otool"
            fake_otool.write_text(
                """#!/usr/bin/env python3
from pathlib import Path
import sys

dependencies = {
    "CoreGuestPackageProbe": ["/usr/lib/swift/libRuntime.dylib"],
    "libRuntime.dylib": [
        "/System/Library/Frameworks/Foundation.framework/Foundation",
        "/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation",
    ],
}
for dependency in dependencies.get(Path(sys.argv[-1]).name, []):
    print("Load command 0")
    print("      cmd LC_LOAD_DYLIB")
    print(f"     name {dependency} (offset 24)")
""",
                encoding="utf-8",
            )
            fake_otool.chmod(0o755)

            command = [
                "perl",
                str(ATTEST),
                "closure",
                "--otool",
                str(fake_otool),
                "--executable",
                str(executable),
                "--package",
                str(package),
                "--guest-root",
                str(guest_root),
            ]
            accepted = subprocess.run(
                command, check=True, capture_output=True, text=True
            )
            self.assertIn(
                "file\tguest-root/darwin/usr/lib/swift/libRuntime.dylib\t",
                accepted.stdout,
            )
            self.assertIn(
                "file\tguest-root/darwin/System/Library/Frameworks/"
                "Foundation.framework/Foundation\t",
                accepted.stdout,
            )
            self.assertIn(
                "edge\texecutable/CoreGuestPackageProbe\tLC_LOAD_DYLIB\t"
                "/usr/lib/swift/libRuntime.dylib\t"
                "guest-root/darwin/usr/lib/swift/libRuntime.dylib",
                accepted.stdout,
            )
            self.assertIn(
                "edge\tguest-root/darwin/usr/lib/swift/libRuntime.dylib\t"
                "LC_LOAD_DYLIB\t"
                "/System/Library/Frameworks/Foundation.framework/Foundation\t"
                "guest-root/darwin/System/Library/Frameworks/"
                "Foundation.framework/Foundation",
                accepted.stdout,
            )
            self.assertNotIn("package/guest-root/", accepted.stdout)

            foundation.unlink()
            os.symlink(
                "../CoreFoundation.framework/CoreFoundation",
                foundation,
            )
            symlinked = subprocess.run(
                command, check=False, capture_output=True, text=True
            )
            self.assertNotEqual(symlinked.returncode, 0)
            self.assertIn("path component is a symlink", symlinked.stderr)

            foundation.unlink()
            missing = subprocess.run(
                command, check=False, capture_output=True, text=True
            )
            self.assertNotEqual(missing.returncode, 0)
            self.assertIn("cannot resolve LC_LOAD_DYLIB", missing.stderr)

    def test_provider_gate_is_universal_and_rejects_reverse_ownership(self) -> None:
        helper = ATTEST.read_text()
        for module in (
            "SwiftUI",
            "OpenUIKit",
            "OpenCoreGraphics",
            "FoundationEssentials",
            "Combine",
            "OpenCombine",
        ):
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
        self.assertIn("protocol conformance descriptor", helper)
        self.assertIn("protocol witness table", helper)
        self.assertIn("owning_module_from_demangle", helper)
        self.assertNotIn("conformance_protocol_module", helper)
        self.assertNotIn("/^\\(extension in", helper)
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

    def test_conformance_descriptors_are_owned_by_the_protocol_module(self) -> None:
        helper = ATTEST.read_text()
        exact = (
            "_$s16OpenCoreGraphics7CGFloatV7SwiftUI01_A16VectorArithmeticADMc"
        )
        self.assertIn(exact, helper)
        self.assertIn(
            "_$s16OpenCoreGraphics7CGFloatV7SwiftUIE16magnitudeSquaredSdvpMV",
            helper,
        )
        self.assertIn(
            "_$s20FoundationEssentials15AttributeScopesO7SwiftUIE7swiftUISdvpMV",
            helper,
        )
        self.assertIn(
            "_$s20FoundationEssentials15AttributeScopesO7SwiftUIE7swiftUISdvg",
            helper,
        )
        self.assertIn(
            "_$s20FoundationEssentials22AttributeDynamicLookupO7SwiftUIEyxqd__cluig",
            helper,
        )
        self.assertIn("_$s16OpenCoreGraphics7CGFloatVMn", helper)
        self.assertIn("_$s20FoundationEssentials15AttributeScopesOMn", helper)
        self.assertIn("conformance-classifier-selftest", helper)
        self.assertIn("owning_module_from_demangle", helper)
        result = subprocess.run(
            ["perl", str(ATTEST), "conformance-classifier-selftest"],
            check=True,
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            result.stdout,
            "CONFORMANCE_CLASSIFIER_SELFTEST_OK positives=7 negatives=2\n",
        )
        self.assertEqual(result.stderr, "")

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

    def test_x86_suffix_env_prepare_resolves_only_suffixed_trees(self) -> None:
        import re
        import shutil

        text = BUILD.read_text()
        self.assertIn("export FULL_OUT_SUFFIX", text)
        self.assertIn(
            'OPENCOMBINE_RESULT=$OPENCOMBINE_ROOT/export${FULL_OUT_SUFFIX}/RESULT.txt',
            text,
        )
        self.assertIn("export-x86_64/RESULT.txt", ATTEST.read_text())
        unsuffixed = re.compile(
            r"/scratch/(mrroot_full|mrroot_fe|sysroot_fe4|mrroot)(?!-x86_64)(?=/|\s|$)"
        )
        with tempfile.TemporaryDirectory(prefix="widget-x86-suffix.") as tmp:
            fixture = Path(tmp)
            (fixture / "env").mkdir()
            shutil.copy2(ROOT / "env/contract.json", fixture / "env/contract.json")
            for trap in (
                "scratch/sysroot_fe4/usr/include",
                "scratch/mrroot/darwin/usr/lib/swift",
                "scratch/mrroot_full/darwin/usr/lib",
                "scratch/mrroot_fe/darwin/usr/lib/swift",
            ):
                path = fixture / trap
                path.mkdir(parents=True)
                (path / ".trap").write_text("arm64-only\n", encoding="utf-8")
            proc = subprocess.run(
                [
                    "python3",
                    str(ROOT / "scripts/env/prepare.py"),
                    "--root",
                    str(fixture),
                    "--gate",
                    "focus-widget",
                    "--verify-only",
                    "--no-fetch",
                ],
                env={**os.environ, "FULL_OUT_SUFFIX": "-x86_64"},
                capture_output=True,
                text=True,
            )
            self.assertEqual(proc.returncode, 0, proc.stderr + proc.stdout)
            for line in proc.stdout.splitlines():
                if line.startswith("ENV_PREPARE_"):
                    self.assertIsNone(unsuffixed.search(line), line)
            self.assertRegex(proc.stdout, r"id=sysroot_fe4 .*sysroot_fe4-x86_64")
            self.assertRegex(proc.stdout, r"id=mrroot_full .*mrroot_full-x86_64")
            self.assertRegex(proc.stdout, r"id=mrroot-base-runtime .*mrroot-x86_64")
            self.assertNotRegex(
                proc.stdout,
                r"id=sysroot_fe4 .*scratch/sysroot_fe4(?:/|\s)",
            )


# Arm64 hashes of the inventories Gate B asserted at e93727e0 / current main.
# Changing an arm64 list without updating these pins is a false-green: the
# operator's arm64 widget gate would then diverge from what this file records.
_ARM64_WIDGET_LOAD_SHA256 = {
    "combine": "de782fb75c10a6708b718b419a715b0ed820a27cf643a5148ec277e520895039",
    "foundationessentials": "4d3801b04b67184a933564c1bcb608884a2b76a40ab0000bd3a4391dc51552e4",
    "guest": "ef127146815795ff4d28287450c8d3dcf45b7b02d763da1b025c998bb64b5d81",
    "opencombine": "cb7dd88fea0eee87eb156ebd2a1a2191366a1bcfef4579cc6306764297fc2c36",
    "opencoregraphics": "8ca2ac9655c5d0e3854addfa8d08e0258a4da34d22d379ab6b4ce0789c8709e8",
    "openuikit": "9042a6ca8b30f5f7f8c017401449e737d139a86a40239240a8a72219bfbe663f",
    "swiftui": "f1285a0e3a49dc1aebf1c8753a14f1a51ba39f7323ae2577042c8b7abf4025a5",
    "symbols": "33355a1f20997221c9fd5a7557f44ff0fcbc8a235fbb5a7b35ea5015aa6984bf",
}
_X86_WIDGET_LOAD_SHA256 = {
    "openuikit": "dd0590d96c4ae3d34bf95cd253d41f35a9e3a0ae8b1a81f50f5fbe87feef89d5",
    "foundationessentials": "92d52ef2b005a80128e7ee17bd90aff3cd271af3b8df21543825ca8262ddba86",
}
_ARM64_WIDGET_INPUT_SHA256 = {
    "combine": "2fb8cf23b974cfc6272337e5992a6273ddbcfe8f7b3748b82e3a4868c2fac00e",
    "foundationessentials": "7892f6d74073e1e7f606cc6a718988e46b4e66c8426b362b1880ba53d732d1c6",
    "guest": "fe87b72e55f03dac218cd9cc6069fdc501eed9814d0870ff6920a4c890bfc1b3",
    "opencombine": "1759c45b9efb1161ab8fda800dd89285d13aa8393ade080ff1a1fc70fa8b3f7c",
    "opencoregraphics": "24691bdfddb9f4f2a5e8d3dcab92f0cbce3f935ea661630aba5eddb800e9bd2f",
    "openuikit": "420fde904d3f834b0448821995abc3596a9845599f290bee04f2aab8d1bf052f",
    "swiftui": "c3e54e497e1a5a77603407803c0581a6b50443114a77434e5da3a776bec4e608",
    "symbols": "028d043be0132451b21a39d37dc0e368b3a5299638ba3393df108f79d647531b",
}
_ARM64_ONBOARDING_INPUT_SHA256 = {
    "combine": "2fb8cf23b974cfc6272337e5992a6273ddbcfe8f7b3748b82e3a4868c2fac00e",
    "foundation": "aeda8311f2404b181030892be67d698cffe1e0444f7e7b14ac37e608b2f5db34",
    "foundationessentials": "f39d87645cb95b700727ac4c2eeb484f347bd0bb1e2723dfe1e65d7d843a0f43",
    "onboarding": "3f9f79428632bbf02dd3be042c9f3aa36bc0a1e41df9e179d0334cc1188248d2",
    "opencombine": "1759c45b9efb1161ab8fda800dd89285d13aa8393ade080ff1a1fc70fa8b3f7c",
    "opencoregraphics": "24691bdfddb9f4f2a5e8d3dcab92f0cbce3f935ea661630aba5eddb800e9bd2f",
    "openuikit": "e69497be0b2108c1292902c44201b3dae932a9722aa76525561f1e942a946280",
    "swiftui": "c3e54e497e1a5a77603407803c0581a6b50443114a77434e5da3a776bec4e608",
    "symbols": "028d043be0132451b21a39d37dc0e368b3a5299638ba3393df108f79d647531b",
    "widget": "37110da55798084f729b85ab7c2f5b3898ad4ac19edfcb43e67bfb0299a3b537",
}
_ARM64_PACKAGE_SHA256 = {
    "names": "f7f24a6f88a070a04f7c2225a991d42379d5bcfe6681541dc87a3864dc035cef",
    "directories": "6f919ab8362dc40f9cea64edd9b93a1e59aee0be48fdb2622c956392b02406be",
    "fe_module_files": "f3bdd5f1c2f371c76a19a96bab86c624318d21b8e85d253c805cbe033d9f50cb",
}


class FocusWidgetGuestInventoryTests(unittest.TestCase):
    """Arch-conditional inventories: arm64 byte-identical, x86 present for every check."""

    def test_gate_scripts_resolve_inventories_from_one_place(self) -> None:
        widget = BUILD.read_text()
        onboarding = (
            ROOT / "full/swiftui/build_focus_onboarding_guest.sh"
        ).read_text()
        self.assertIn("guest_gate_inventories.inc", widget)
        self.assertIn("guest_gate_inventories.inc", onboarding)
        self.assertIn("guest_gate_inventory widget loads", widget)
        self.assertIn("guest_gate_inventory widget inputs", widget)
        self.assertIn("guest_gate_inventory widget package", widget)
        self.assertIn("guest_gate_inventory onboarding inputs", onboarding)
        self.assertNotIn("libswift_errno.dylib", widget)
        self.assertNotIn("/usr/lib/swift/libswift_DarwinFoundation1.dylib", widget)
        self.assertIn("MH_MAGIC_64[[:space:]]+${OTOOL_CPU}", widget)
        self.assertIn("MH_MAGIC_64[[:space:]]+${OTOOL_CPU}", onboarding)

    def test_arm64_widget_loads_are_hash_pinned(self) -> None:
        self.assertEqual(
            tuple(sorted(_ARM64_WIDGET_LOAD_SHA256)),
            inventories.check_names("widget", "loads"),
        )
        for name, digest in _ARM64_WIDGET_LOAD_SHA256.items():
            items = inventories.loads("widget", name, "arm64")
            self.assertEqual(inventories.inventory_sha256(items), digest, name)
            self.assertEqual(
                inventories.loads("widget", name, "arm64"),
                inventories.WIDGET_LOADS_ARM64[name],
                name,
            )

    def test_arm64_widget_inputs_are_hash_pinned(self) -> None:
        self.assertEqual(
            tuple(sorted(_ARM64_WIDGET_INPUT_SHA256)),
            inventories.check_names("widget", "inputs"),
        )
        for name, digest in _ARM64_WIDGET_INPUT_SHA256.items():
            items = inventories.inputs("widget", name, "arm64")
            self.assertEqual(inventories.inventory_sha256(items), digest, name)

    def test_arm64_onboarding_inputs_are_hash_pinned(self) -> None:
        self.assertEqual(
            tuple(sorted(_ARM64_ONBOARDING_INPUT_SHA256)),
            inventories.check_names("onboarding", "inputs"),
        )
        for name, digest in _ARM64_ONBOARDING_INPUT_SHA256.items():
            items = inventories.inputs("onboarding", name, "arm64")
            self.assertEqual(inventories.inventory_sha256(items), digest, name)

    def test_arm64_package_inventories_are_hash_pinned(self) -> None:
        self.assertEqual(inventories.WIDGET_PACKAGE_FILE_COUNT, 101)
        self.assertEqual(inventories.WIDGET_PACKAGE_DIRECTORY_COUNT, 12)
        self.assertEqual(
            inventories.package_scalar("file_count", "arm64"), "101"
        )
        self.assertEqual(
            inventories.package_scalar("directory_count", "arm64"), "12"
        )
        for name, digest in _ARM64_PACKAGE_SHA256.items():
            items = inventories.package_items(name, "arm64")
            self.assertEqual(inventories.inventory_sha256(items), digest, name)

    def test_x86_64_has_every_widget_check(self) -> None:
        for kind in ("loads", "inputs", "package"):
            names = inventories.check_names("widget", kind)
            self.assertTrue(names, kind)
            for name in names:
                if kind == "loads":
                    arm = inventories.loads("widget", name, "arm64")
                    x86 = inventories.loads("widget", name, "x86_64")
                elif kind == "inputs":
                    arm = inventories.inputs("widget", name, "arm64")
                    x86 = inventories.inputs("widget", name, "x86_64")
                else:
                    if name in ("file_count", "directory_count"):
                        arm = inventories.package_scalar(name, "arm64")
                        x86 = inventories.package_scalar(name, "x86_64")
                        self.assertEqual(arm, x86, name)
                        continue
                    arm = inventories.package_items(name, "arm64")
                    x86 = inventories.package_items(name, "x86_64")
                if kind == "loads":
                    self.assertEqual(
                        x86,
                        inventories.macos_overlay_autolink_loads(arm, "x86_64"),
                        f"{kind}/{name}",
                    )
                    # errno -> libswiftDarwin in place; one entry shorter only
                    # when libswiftDarwin was already listed (dedupe).
                    dropped = (
                        inventories.ARM64_OVERLAY_AUTOLINK in arm
                        and inventories.X86_OVERLAY_AUTOLINK in arm
                    )
                    self.assertEqual(
                        len(x86),
                        len(arm) - (1 if dropped else 0),
                        f"{kind}/{name}",
                    )
                elif kind == "inputs":
                    expected = arm
                    wl = inventories.loads("widget", name, "arm64") if name in inventories.check_names("widget", "loads") else ()
                    if (
                        inventories.ARM64_OVERLAY_AUTOLINK in wl
                        and inventories.X86_OVERLAY_AUTOLINK not in wl
                        and inventories.X86_OVERLAY_AUTOLINK_TBD not in arm
                    ):
                        expected = arm + (inventories.X86_OVERLAY_AUTOLINK_TBD,)
                    self.assertEqual(x86, expected, f"{kind}/{name}")
                else:
                    self.assertEqual(x86, arm, f"{kind}/{name}")
                self.assertTrue(x86, f"{kind}/{name} empty")
        self.assertEqual(
            inventories.otool_cpu("x86_64"), guest_arch.otool_cpu("x86_64")
        )
        self.assertEqual(
            inventories.otool_cpu("arm64"), guest_arch.otool_cpu("arm64")
        )
        self.assertEqual(inventories.otool_cpu("x86_64"), "X86_64")
        self.assertEqual(inventories.otool_cpu("arm64"), "ARM64")

    def test_x86_64_has_every_onboarding_input_check(self) -> None:
        for name in inventories.check_names("onboarding", "inputs"):
            arm = inventories.inputs("onboarding", name, "arm64")
            x86 = inventories.inputs("onboarding", name, "x86_64")
            # x86_64 appends libswiftDarwin.tbd for a dylib whose loads gained
            # libswiftDarwin by the errno replacement (measured: OpenUIKit).
            expected = arm
            widget_loads = inventories.loads("widget", name, "arm64") if name in inventories.check_names("widget", "loads") else ()
            if (
                inventories.ARM64_OVERLAY_AUTOLINK in widget_loads
                and inventories.X86_OVERLAY_AUTOLINK not in widget_loads
                and inventories.X86_OVERLAY_AUTOLINK_TBD not in arm
            ):
                expected = arm + (inventories.X86_OVERLAY_AUTOLINK_TBD,)
            self.assertEqual(x86, expected, name)
            self.assertEqual(
                inventories.inventory_sha256(arm),
                _ARM64_ONBOARDING_INPUT_SHA256[name],
                name,
            )
            self.assertEqual(
                inventories.inventory_sha256(x86),
                inventories.inventory_sha256(expected),
                name,
            )

    def test_x86_overlay_autolink_drops_errno_keeps_darwin(self) -> None:
        for name in ("openuikit", "foundationessentials"):
            arm = inventories.loads("widget", name, "arm64")
            x86 = inventories.loads("widget", name, "x86_64")
            self.assertIn(inventories.ARM64_OVERLAY_AUTOLINK, arm)
            self.assertNotIn(inventories.ARM64_OVERLAY_AUTOLINK, x86)
            # errno -> libswiftDarwin in place, dropped when Darwin is already
            # listed (ld64 records a dylib once, at its first reference).
            if inventories.X86_OVERLAY_AUTOLINK in arm:
                expected = tuple(
                    item for item in arm if item != inventories.ARM64_OVERLAY_AUTOLINK
                )
            else:
                expected = tuple(
                    inventories.X86_OVERLAY_AUTOLINK
                    if item == inventories.ARM64_OVERLAY_AUTOLINK
                    else item
                    for item in arm
                )
            self.assertEqual(x86, expected, name)
            self.assertEqual(x86.count(inventories.X86_OVERLAY_AUTOLINK), 1, name)
            self.assertEqual(
                inventories.macos_overlay_autolink_loads(arm, "x86_64"), x86
            )
            self.assertFalse(
                any("DarwinFoundation1" in item for item in x86), name
            )
            self.assertEqual(
                inventories.inventory_sha256(x86),
                _X86_WIDGET_LOAD_SHA256[name],
                name,
            )
        fe_x86 = inventories.loads("widget", "foundationessentials", "x86_64")
        self.assertIn("/usr/lib/swift/libswiftDarwin.dylib", fe_x86)
        # Measured on the x86_64 box (main a9e85d41): OpenUIKit records
        # libswiftDarwin where arm64 records libswift_errno, at the end.
        ui_x86 = inventories.loads("widget", "openuikit", "x86_64")
        self.assertEqual(ui_x86[-1], "/usr/lib/swift/libswiftDarwin.dylib")
        self.assertNotIn("/usr/lib/swift/libswiftDarwin.dylib", inventories.loads("widget", "openuikit", "arm64"))
        # Link-map inputs: Darwin.tbd already listed on arm64; drop errno.tbd
        # rather than substituting the DarwinFoundation1 tbd.
        for gate in ("widget", "onboarding"):
            fe_in_arm = inventories.inputs(gate, "foundationessentials", "arm64")
            fe_in_x86 = inventories.inputs(gate, "foundationessentials", "x86_64")
            self.assertIn("{SYS}/usr/lib/swift/libswiftDarwin.tbd", fe_in_arm)
            self.assertEqual(fe_in_x86, fe_in_arm)
            self.assertNotIn(inventories.ARM64_OVERLAY_AUTOLINK_TBD, fe_in_arm)
        self.assertEqual(
            inventories.macos_overlay_autolink_inputs(
                (
                    "{SYS}/usr/lib/swift/libswiftDarwin.tbd",
                    inventories.ARM64_OVERLAY_AUTOLINK_TBD,
                ),
                "x86_64",
            ),
            ("{SYS}/usr/lib/swift/libswiftDarwin.tbd",),
        )
        # FE Darwin/StringProcessing/Synchronization/errno stay off libSwiftUI
        # on both arches; DarwinFoundation1 must not leak onto SwiftUI either.
        swiftui_arm = inventories.loads("widget", "swiftui", "arm64")
        swiftui_x86 = inventories.loads("widget", "swiftui", "x86_64")
        self.assertEqual(swiftui_arm, swiftui_x86)
        for forbidden in (
            "libswiftDarwin.dylib",
            "libswift_StringProcessing.dylib",
            "libswiftSynchronization.dylib",
            "libswift_errno.dylib",
            "libswift_DarwinFoundation1.dylib",
        ):
            self.assertFalse(
                any(forbidden in item for item in swiftui_arm), forbidden
            )
        self.assertIn("@rpath/libFoundationEssentials.dylib", swiftui_arm)
        swiftui_inputs = inventories.inputs("widget", "swiftui", "arm64")
        self.assertIn("{PACKAGE}/libFoundationEssentials.dylib", swiftui_inputs)

    def test_cli_emits_printf_compatible_lists(self) -> None:
        arm = subprocess.check_output(
            [
                "python3",
                str(INVENTORIES_PY),
                "--arch",
                "arm64",
                "--gate",
                "widget",
                "--kind",
                "loads",
                "--name",
                "openuikit",
            ],
            text=True,
        )
        x86 = subprocess.check_output(
            [
                "python3",
                str(INVENTORIES_PY),
                "--arch",
                "x86_64",
                "--gate",
                "widget",
                "--kind",
                "loads",
                "--name",
                "openuikit",
            ],
            text=True,
        )
        self.assertTrue(arm.endswith("libswift_errno.dylib\n"))
        self.assertTrue(x86.endswith("libswiftDarwin.dylib\n"))
        self.assertNotIn("libswift_errno.dylib", x86)
        self.assertNotIn("DarwinFoundation1", x86)
        binds = [
            "--bind",
            "PACKAGE=/pkg",
            "--bind",
            "SYS=/sys",
            "--bind",
            "MRROOT=/mr",
            "--bind",
            "FULL=/full",
            "--bind",
            "OUT=/out",
            "--bind",
            "FE_OUT=/fe",
            "--bind",
            "FE_COLLECTIONS=/col",
            "--bind",
            "FE_OS=/os",
            "--bind",
            "FE_CSHIMS=/cs",
            "--bind",
            "OPENCOMBINE_ARTIFACTS=/oc",
            "--bind",
            "RELATIVE_TIME_RUNTIME=/rt",
        ]
        emitted = subprocess.check_output(
            [
                "python3",
                str(INVENTORIES_PY),
                "--arch",
                "arm64",
                "--gate",
                "widget",
                "--kind",
                "inputs",
                "--name",
                "openuikit",
                *binds,
            ],
            text=True,
        )
        self.assertIn("/pkg/libFoundationEssentials.dylib\n", emitted)
        self.assertIn("/full/openuikit.o\n", emitted)
        self.assertIn("/mr/darwin/usr/lib/libSystem.B.dylib\n", emitted)

    def test_inc_and_python_are_present(self) -> None:
        self.assertTrue(INVENTORIES_PY.is_file())
        self.assertTrue(INVENTORIES_INC.is_file())
        self.assertIn("guest_gate_inventory()", INVENTORIES_INC.read_text())

    def test_bash_helper_emits_arch_conditional_openuikit_loads(self) -> None:
        script = r"""
set -euo pipefail
W=%s
. "$W/full/scripts/guest_arch.inc"
. "$W/full/swiftui/guest_gate_inventories.inc"
ARCH=arm64
guest_gate_inventory widget loads openuikit
printf '==SPLIT==\n'
ARCH=x86_64
guest_gate_inventory widget loads openuikit
""" % ROOT
        result = subprocess.run(
            ["bash", "-c", script],
            check=True,
            capture_output=True,
            text=True,
        )
        arm, x86 = result.stdout.split("==SPLIT==\n", 1)
        self.assertTrue(arm.strip().endswith("libswift_errno.dylib"))
        self.assertTrue(x86.strip().endswith("libswiftDarwin.dylib"))
        self.assertNotIn("libswift_DarwinFoundation1.dylib", arm)
        self.assertNotIn("libswift_errno.dylib", x86)
        self.assertNotIn("DarwinFoundation1", x86)

    def test_x86_oracle_ld64_attributes_reexports_to_libswiftDarwin(self) -> None:
        result = subprocess.run(
            ["bash", str(X86_ORACLE)],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            result.returncode,
            0,
            result.stderr or result.stdout,
        )
        self.assertIn(
            "GUEST_GATE_X86_ORACLE_OK "
            "loads=libswiftDarwin,libSystem.B bind=libswiftDarwin",
            result.stdout,
        )


if __name__ == "__main__":
    unittest.main()
