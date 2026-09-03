#!/usr/bin/env python3
"""Regression teeth for the unchanged Focus onboarding guest boundary."""

from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[2]
BUILD = ROOT / "full/swiftui/build_focus_onboarding_guest.sh"
FI_BUILDER = ROOT / "full/foundationinternationalization/build_foundation_internationalization.sh"
HARNESS = ROOT / "full/swiftui/FocusOnboardingGuestMain.swift"
UUID_PROBE = ROOT / "full/swiftui/FocusOnboardingUUIDProbe.c"
UUID_COMPAT = ROOT / "full/foundation/uuid_compat.c"
FOUNDATION = ROOT / "full/appshim/FoundationGuest.swift"
ACCESSOR = ROOT / "full/swiftui/FocusOnboardingBundle.generated.swift"
WIDGET_ACCESSOR = ROOT / "full/swiftui/FocusWidgetBundle.generated.swift"
BUILD_FULL = ROOT / "full/scripts/build_full.sh"
STUBS = ROOT / "full/foundation/fm_unimplemented.c"
FOUNDATION_RUNTIME_LINK_CONTRACT = (
    "-lswift_StringProcessing",
    "-lswiftSynchronization",
    "/usr/lib/swift/libswift_StringProcessing.dylib",
    "/usr/lib/swift/libswiftSynchronization.dylib",
    "/usr/lib/swift/libswiftDarwin.dylib",
    "/usr/lib/swift/libswift_Concurrency.dylib",
)
FOUNDATION_RUNTIME_UNDEFINED_CONTRACT = (
    ("EXPECTED_FOUNDATION_STRING_PROCESSING_UNDEFINEDS", 19, "17_StringProcessing"),
    ("EXPECTED_FOUNDATION_SYNCHRONIZATION_UNDEFINEDS", 2, "15Synchronization"),
    ("EXPECTED_FOUNDATION_REGEX_PARSER_UNDEFINEDS", 0, "12_RegexParser"),
)


def validate_foundation_runtime_contract(source: str) -> None:
    for token in FOUNDATION_RUNTIME_LINK_CONTRACT:
        if source.count(token) != 1:
            raise AssertionError(f"Foundation runtime-link contract drifted: {token}")
    if "-lswift_RegexParser" in source or "libswift_RegexParser.tbd" in source:
        raise AssertionError("Foundation runtime-link contract guessed RegexParser")
    for assignment, expected, predicate in FOUNDATION_RUNTIME_UNDEFINED_CONTRACT:
        match = re.search(rf"(?m)^{re.escape(assignment)}=([0-9]+)$", source)
        if match is None or int(match.group(1)) != expected:
            raise AssertionError(
                f"Foundation runtime-undefined contract drifted: {assignment}"
            )
        if source.count(f'index($0, "{predicate}")') != 1:
            raise AssertionError(
                f"Foundation runtime-undefined predicate drifted: {predicate}"
            )


class FocusOnboardingGuestProofTests(unittest.TestCase):
    def test_build_script_has_valid_shell_syntax(self) -> None:
        subprocess.run(["bash", "-n", str(BUILD)], check=True)
        subprocess.run(["bash", "-n", str(FI_BUILDER)], check=True)

    def test_exact_twelve_source_boundary_is_hash_pinned_and_direct(self) -> None:
        text = BUILD.read_text()
        self.assertIn("EXPECTED_FOCUS_COMMIT=a2832521c1daa0c23419c73705ae043ed60c9791", text)
        self.assertIn("SwiftUI source inventory is empty", text)
        self.assertIn("unsupported SwiftUI source node", text)
        self.assertNotIn("seven-source", text)
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
        self.assertIn("assert_vendor_tree", text)
        self.assertIn(
            "EXPECTED_UIKIT_TREE=$EXPECTED_INREPO_UIKIT_TREE",
            text,
        )
        self.assertIn("attested OpenUIKit source=HEAD:uikit", text)
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
        self.assertNotIn("EXPECTED_UIKIT_COMMIT_OVERRIDE", text)
        for digest in (
            "3db199a93294a4ea0e6549522c29e8b2e4dbfb979bd60c07cdad5d00386734f5",
            "144c49c747d4689d9ca98d353cb5474b311473629383a779d99f1b705969a04d",
        ):
            self.assertIn(digest, text)
        self.assertIn("contains a symlink/special node", text)
        self.assertIn("post-run-Focus", text)
        self.assertIn("post-run-OpenUIKit", text)

    def test_framework_graph_uses_ten_real_macho_dylibs(self) -> None:
        text = BUILD.read_text()
        self.assertIn("-parse-stdlib -typecheck", text)
        self.assertIn("-e 'import Swift'", text)
        names = (
            "FoundationEssentials", "OpenCoreGraphics", "OpenUIKit", "Foundation",
            "OpenCombine", "Combine", "Symbols", "SwiftUI", "Widget", "Onboarding",
        )
        for name in names:
            self.assertIn(f"lib{name}.dylib", text)
        self.assertIn("MH_MAGIC_64[[:space:]]+${OTOOL_CPU}", text)
        self.assertIn('actual_id=$(llvm-otool-18 -D', text)
        self.assertIn('focus_widget_guest_attest.pl" closure', text)
        self.assertIn('"$MRROOT/machorun"', text)
        self.assertIn("run_machorun_site interaction-path ./focus_onboarding_guest", text)
        self.assertIn("compile the first-party Symbols value model while Foundation is hidden", text)
        self.assertIn("libSymbols Apple Symbols load count", text)
        self.assertIn("-lOpenUIKit -lOpenCoreGraphics -lCombine -lOpenCombine -lSymbols", text)
        swiftui_link = text.split(
            "-install_name @rpath/libSwiftUI.dylib", 1
        )[1].split("-install_name @rpath/libWidget.dylib", 1)[0]
        self.assertIn(
            "-lOpenUIKit -lOpenCoreGraphics -lCombine -lOpenCombine -lSymbols "
            "-lFoundationEssentials",
            swiftui_link,
        )

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

    def test_foundation_umbrella_link_names_the_four_missing_input_classes(self) -> None:
        build = BUILD.read_text()
        foundation_link = build.split("run_link libFoundation ", 1)[1].split(
            "run_link libSwiftUI ", 1
        )[0]
        self.assertIn("libswift_Concurrency.tbd", foundation_link)
        self.assertIn("libswiftDarwin.tbd", foundation_link)
        self.assertIn("libOpenCoreGraphics.dylib", foundation_link)
        self.assertIn("$RELATIVE_TIME_DARWIN", foundation_link)
        self.assertIn('"$SYS/usr/lib/swift/libswiftDarwin.tbd"', foundation_link)
        self.assertIn('"$SYS/usr/lib/swift/libswift_Concurrency.tbd"', foundation_link)
        self.assertIn('"$PACKAGE/libOpenCoreGraphics.dylib"', foundation_link)
        self.assertNotIn("-lswift_Concurrency", foundation_link)
        self.assertNotIn("-lswiftDarwin", foundation_link)
        self.assertEqual(build.count("-lswift_StringProcessing"), 1)
        self.assertEqual(build.count("-lswiftSynchronization"), 1)

    def test_dylib_links_print_argv_and_record_contributing_input_maps(self) -> None:
        text = BUILD.read_text()
        self.assertIn("run_link()", text)
        self.assertIn("printf '%s-link'", text)
        self.assertIn("link_map_inputs()", text)
        self.assertIn('assert_exact_text "libFoundation linker inputs"', text)
        self.assertIn("expected_foundation_inputs", text)
        self.assertIn("expected_foundationessentials_inputs", text)
        self.assertIn("expected_widget_inputs", text)
        self.assertIn("expected_onboarding_inputs", text)
        self.assertIn('-map "$AUDIT/libFoundation.link-map"', text)
        self.assertIn("run_link libFoundation ", text)
        self.assertIn("run_link libFoundationEssentials ", text)
        self.assertIn("run_link libWidget ", text)
        self.assertIn("run_link libOnboarding ", text)
        foundation_expected = text.split("expected_foundation_inputs=", 1)[1].split(
            "expected_widget_inputs=", 1
        )[0]
        for required in (
            "libswift_Concurrency.tbd",
            "libswiftDarwin.tbd",
            "libOpenCoreGraphics.dylib",
            "$RELATIVE_TIME_DARWIN",
        ):
            self.assertIn(required, foundation_expected)
        self.assertIn(
            'grep -Fq "$required" "$AUDIT/libFoundation.link-map"',
            text,
        )

    def test_relative_time_bridge_is_built_and_preloaded_like_frameworks(self) -> None:
        text = BUILD.read_text()
        self.assertIn(
            "== build the OpenRelativeTime Darwin bridge and Linux host helper",
            text,
        )
        self.assertIn("full/relativetime/OpenRelativeTimeBridge.c", text)
        self.assertIn("full/relativetime/OpenRelativeTimeHost.c", text)
        self.assertIn("full/relativetime/OpenRelativeTimeHostTests.c", text)
        self.assertIn("run_link libOpenRelativeTime ", text)
        self.assertIn("run_link libOpenRelativeTimeRuntime ", text)
        self.assertIn("full/relativetime/build_host_helper.sh", text)
        self.assertIn("RELATIVE_TIME_RUNTIME=$RUNROOT/darwin/usr/lib/libOpenRelativeTime.dylib", text)
        self.assertIn("RELATIVE_TIME_DARWIN=$PACKAGE/libOpenRelativeTime.dylib", text)
        self.assertIn(
            "RELATIVE_TIME_HOST=$HOST_BRIDGE_DIR/libOpenRelativeTimeHost.so",
            text,
        )
        self.assertIn(
            "OPEN_RELATIVE_TIME_HOST_OK icu=real locale=en,fr,de,ja styles=4 bounds=hard",
            text,
        )
        self.assertIn("_glibc_openui_relative_time_v1_format", text)
        self.assertIn(
            "EARLY_PLATFORM_HOST_PRELOAD=$DISPATCH_HOST:$FOUNDATION_INTL_HOST:$RELATIVE_TIME_HOST",
            text,
        )
        self.assertIn("@rpath/libOpenRelativeTime.dylib", text)
        self.assertIn(
            "-install_name /usr/lib/libOpenRelativeTime.dylib",
            text,
        )
        self.assertIn("-reexport_library \"$RELATIVE_TIME_RUNTIME\"", text)
        self.assertIn("LC_REEXPORT_DYLIB", text)
        self.assertIn("assert_no_glibc_host_imports \"$RELATIVE_TIME_DARWIN\"", text)
        self.assertIn(
            "== clone shared machorun root into a writable run-local overlay",
            text,
        )

    def test_foundation_intl_bridge_is_packaged_preloaded_and_in_closure(self) -> None:
        text = BUILD.read_text()
        self.assertIn(
            "== build the OpenFoundationInternationalization Darwin bridge and Linux host helper",
            text,
        )
        self.assertIn(
            "full/foundationinternationalization/OpenFoundationInternationalizationBridge.c",
            text,
        )
        self.assertIn(
            "full/foundationinternationalization/OpenFoundationInternationalizationHost.c",
            text,
        )
        self.assertIn(
            "full/foundationinternationalization/build_host_helper.sh",
            text,
        )
        self.assertIn("run_link libOpenFoundationInternationalization ", text)
        self.assertIn(
            "FOUNDATION_INTL_RUNTIME=$RUNROOT/darwin/usr/lib/libOpenFoundationInternationalization.dylib",
            text,
        )
        self.assertIn(
            "FOUNDATION_INTL_DARWIN=$PACKAGE/libOpenFoundationInternationalization.dylib",
            text,
        )
        self.assertIn(
            "FOUNDATION_INTL_HOST=$HOST_BRIDGE_DIR/libOpenFoundationInternationalizationHost.so",
            text,
        )
        self.assertIn(
            "-install_name @rpath/libOpenFoundationInternationalization.dylib",
            text,
        )
        self.assertIn(
            "-install_name /usr/lib/libOpenFoundationInternationalization.dylib",
            text,
        )
        self.assertIn("-reexport_library \"$FOUNDATION_INTL_RUNTIME\"", text)
        self.assertIn(
            "assert_no_glibc_host_imports \"$FOUNDATION_INTL_DARWIN\"",
            text,
        )
        self.assertIn("full/xcodeplan/rewrite_macho_dependency.py", text)
        self.assertIn(
            'python3 -B "$MACHO_DEPENDENCY_REWRITER" "$PACKAGE/lib_FoundationICU.dylib"',
            text,
        )
        self.assertIn("/usr/lib/libOpenFoundationInternationalization.dylib", text)
        self.assertIn("@rpath/libOpenFoundationInternationalization.dylib", text)
        self.assertNotIn("install_name_tool", text)
        self.assertIn(
            "OPEN_FOUNDATION_INTERNATIONALIZATION_HOST_OK realpath=bounded,versioned",
            text,
        )
        self.assertIn(
            "EARLY_PLATFORM_HOST_PRELOAD=$DISPATCH_HOST:$FOUNDATION_INTL_HOST:$RELATIVE_TIME_HOST",
            text,
        )
        self.assertIn(
            'package/libOpenFoundationInternationalization.dylib',
            text,
        )
        self.assertIn(
            "runtime-closure inventory omitted package/libOpenFoundationInternationalization.dylib",
            text,
        )
        self.assertIn(
            "runtime-closure inventory omitted the run-local OpenFoundationInternationalization Darwin bridge",
            text,
        )
        self.assertIn('--guest-root "$RUNROOT"', text)
        self.assertNotIn('--guest-root "$MRROOT"', text)

    def test_run_step_preloads_every_built_host_helper(self) -> None:
        text = BUILD.read_text()
        run = text.split(
            "== run exact Focus interaction path on Linux/machorun", 1
        )[1]
        helpers = sorted(set(re.findall(r"libOpen[A-Za-z]+Host\.so", text)))
        self.assertEqual(
            helpers,
            [
                "libOpenDispatchHost.so",
                "libOpenFoundationInternationalizationHost.so",
                "libOpenRelativeTimeHost.so",
            ],
        )
        self.assertNotIn("libOpenURLTransportHost.so", text)
        assignments = dict(
            re.findall(
                r"^([A-Z0-9_]+)=\$HOST_BRIDGE_DIR/(libOpen[A-Za-z]+Host\.so)$",
                text,
                re.MULTILINE,
            )
        )
        inverse = {name: var for var, name in assignments.items()}
        preload_lines = [
            line
            for line in run.splitlines()
            if line.startswith("EARLY_PLATFORM_HOST_PRELOAD=")
        ]
        self.assertEqual(len(preload_lines), 1, preload_lines)
        preload_line = preload_lines[0]
        self.assertEqual(
            preload_line,
            "EARLY_PLATFORM_HOST_PRELOAD=$DISPATCH_HOST:$FOUNDATION_INTL_HOST:$RELATIVE_TIME_HOST",
        )
        for helper in helpers:
            self.assertIn(helper, inverse)
            self.assertIn(f"${inverse[helper]}", preload_line)
        self.assertIn("== compose Linux host preload", run)
        self.assertIn("printf 'LD_PRELOAD=%s\\n'", run)
        self.assertIn("== host dlsym probe of composed LD_PRELOAD", run)
        self.assertIn("run_machorun_site interaction-path ./focus_onboarding_guest", run)
        self.assertLess(
            run.index('bash "$W/full/dispatch/build_host_bridge.sh"'),
            run.index("EARLY_PLATFORM_HOST_PRELOAD="),
        )
        self.assertLess(
            run.index("EARLY_PLATFORM_HOST_PRELOAD="),
            run.index('LD_PRELOAD="$EARLY_PLATFORM_HOST_PRELOAD'),
        )
        self.assertLess(
            run.index("== compose Linux host preload"),
            run.index("== host dlsym probe of composed LD_PRELOAD"),
        )
        self.assertLess(
            run.index("== host dlsym probe of composed LD_PRELOAD"),
            run.index("run_machorun_site interaction-path"),
        )
        self.assertIn('MACHORUN_ROOT="$RUNROOT"', text)
        self.assertNotIn('MACHORUN_ROOT="$MRROOT"', text)
        self.assertIn("full/swiftui/host_preload_dlsym_probe.c", text)
        self.assertEqual(text.count('"$MRROOT/machorun" "$@"'), 1)
        self.assertEqual(text.count("echo \"== machorun site: $site\""), 1)
        self.assertEqual(len(re.findall(r"\brun_machorun_site \S+", text)), 1)

    def test_foundation_runtime_closure_is_exact_and_mutation_sensitive(self) -> None:
        source = BUILD.read_text()
        validate_foundation_runtime_contract(source)
        self.assertIn('llvm-nm-18 -u -j "$OUT/foundation.o"', source)
        for token in FOUNDATION_RUNTIME_LINK_CONTRACT:
            with self.subTest(deleted=token):
                with self.assertRaisesRegex(AssertionError, "runtime-link"):
                    validate_foundation_runtime_contract(source.replace(token, "", 1))
        for assignment, expected, predicate in FOUNDATION_RUNTIME_UNDEFINED_CONTRACT:
            with self.subTest(mutated=assignment):
                with self.assertRaisesRegex(AssertionError, "runtime-undefined"):
                    validate_foundation_runtime_contract(
                        source.replace(
                            f"{assignment}={expected}",
                            f"{assignment}={expected + 1}",
                            1,
                        )
                    )
            with self.subTest(deleted=predicate):
                with self.assertRaisesRegex(AssertionError, "runtime-undefined"):
                    validate_foundation_runtime_contract(
                        source.replace(predicate, "deleted-predicate", 1)
                    )

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

    def test_compatibility_support_uses_the_exact_normalized_bundle(self) -> None:
        accessor = ACCESSOR.read_text()
        widget_accessor = WIDGET_ACCESSOR.read_text()
        harness = HARNESS.read_text()
        build = BUILD.read_text()
        self.assertIn("compatibility build support", accessor)
        self.assertIn("declares no Onboarding resources", accessor)
        self.assertIn("SWIFT_MODULE_RESOURCE_BUNDLE_UNAVAILABLE", accessor)
        self.assertNotIn("SwiftPM-equivalent", accessor)
        self.assertIn('"Focus_Onboarding.bundle"', accessor)
        self.assertIn("Bundle.main.bundleURL.appendingPathComponent", accessor)
        self.assertIn("guard let bundle = Bundle(url: url)", accessor)
        self.assertIn("_ = Color.actionButton", accessor)
        self.assertIn("_ = Image.logo", accessor)
        self.assertIn('named: "icon_logo"', accessor)
        self.assertIn("in: Bundle.module", accessor)
        self.assertIn('"Focus_Widget.bundle"', widget_accessor)
        self.assertIn("_ = Gradient.quickAccessWidget", widget_accessor)
        self.assertIn("_ = Image.logo", widget_accessor)
        self.assertIn(
            "FocusOnboardingResourceProof.bundlePath == arguments[1]", harness
        )
        self.assertIn(
            "FocusOnboardingResourceProof.resourcePath == arguments[1]", harness
        )
        self.assertIn(
            "FocusOnboardingResourceProof.exerciseUnchangedAssets()", harness
        )
        self.assertIn("unchanged Onboarding named image did not resolve", harness)
        self.assertIn(
            "FocusWidgetResourceProof.bundlePath == arguments[2]", harness
        )
        self.assertIn(
            "FocusWidgetResourceProof.resourcePath == arguments[2]", harness
        )
        self.assertIn("FocusWidgetResourceProof.exerciseUnchangedAssets()", harness)
        self.assertNotIn("OpenUIKitRuntime.imageSearchPaths", harness)
        self.assertIn(
            'cp -a "$ONBOARDING_INPUT" "$OUT/Focus_Onboarding.bundle"', build
        )
        self.assertNotIn(
            '"$OUT/resources/Focus_Onboarding.bundle"', build
        )
        self.assertIn(
            'cp -a "$WIDGET_INPUT" "$OUT/Focus_Widget.bundle"', build
        )
        self.assertNotIn('"$OUT/resources/Focus_Widget.bundle"', build)
        self.assertIn("printf 'onboarding-bundle-accessor\\t%s\\n'", build)
        self.assertIn("printf 'widget-bundle-accessor\\t%s\\n'", build)

    def test_compatibility_support_is_explicitly_not_application_source(self) -> None:
        self.assertIn("not Mozilla Focus application", ACCESSOR.read_text())
        self.assertIn("source. Pinned Focus Package.swift", ACCESSOR.read_text())
        self.assertIn("Project-owned Linux/machorun harness", HARNESS.read_text())
        self.assertIn("Project-owned runtime probe", UUID_PROBE.read_text())
        self.assertIn("static let module: Bundle", ACCESSOR.read_text())

    def test_foundation_internationalization_is_a_named_umbrella_prerequisite(self) -> None:
        source = FOUNDATION.read_text()
        build = BUILD.read_text()
        self.assertIn("@_exported import FoundationInternationalization", source)
        self.assertIn(
            'full/foundationinternationalization/build_foundation_internationalization.sh',
            build,
        )
        self.assertIn("SWIFT_FOUNDATION_ICU=", build)
        self.assertIn('bash "$FOUNDATION_INTERNATIONALIZATION_BUILDER"', build)
        self.assertIn(
            "== build pinned FoundationInternationalization against the same sysroot",
            build,
        )
        umbrella = build.split(
            "== compile the bounded Foundation umbrella after SwiftUI", 1
        )[1].split("== FoundationGuest/UIKit notification identity compile proof", 1)[0]
        self.assertIn("-I \"$PACKAGE\"", umbrella)
        self.assertIn("libFoundationInternationalization.dylib", build)
        self.assertIn("-lFoundationInternationalization", build)
        self.assertIn("corefoundation_guest_sources.txt", build)

    def test_fi_swiftc_gets_fe_collections_os_and_cshims_includes(self) -> None:
        subprocess.run(["bash", "-n", str(FI_BUILDER)], check=True)
        builder = FI_BUILDER.read_text()
        build = BUILD.read_text()
        swiftc = builder.split('"${SWIFTC[@]}" -parse-as-library', 1)[1].split(
            "ld64.lld-18", 1
        )[0]
        ld = builder.split(
            '-o "$STAGE/lib/libFoundationInternationalization.dylib"', 1
        )[1].split("-L\"$STAGE/lib\"", 1)[0]
        umbrella_ld = build.split(
            '== package ten reusable guest dylibs', 1
        )[1].split('libFoundation.dylib', 1)[1].split(
            'for install_name in "${FOUNDATION_RUNTIME_INSTALL_NAMES[@]}"', 1
        )[0]
        self.assertIn('${COLLECTIONS:+-I "$COLLECTIONS"}', swiftc)
        self.assertIn('${OSMOD:+-I "$OSMOD"}', swiftc)
        self.assertIn(
            '-Xcc -fmodule-map-file="$STAGE/include/_FoundationCShims/module.modulemap"',
            swiftc,
        )
        self.assertIn('-Xcc -I"$STAGE/include/_FoundationCShims"', swiftc)
        self.assertIn('COLLECTIONS="$FE_COLLECTIONS"', build)
        self.assertIn('OSMOD="$FE_OS"', build)
        self.assertIn('CSHIMS="$FE_CSHIMS"', build)
        self.assertIn(
            '${COLLECTIONS:+"$COLLECTIONS/InternalCollectionsUtilities.o"}', ld
        )
        self.assertIn('${COLLECTIONS:+"$COLLECTIONS/OrderedCollections.o"}', ld)
        self.assertIn('${COLLECTIONS:+"$COLLECTIONS/_RopeModule.o"}', ld)
        self.assertIn('${OSMOD:+"$OSMOD/os.o"}', ld)
        self.assertIn('${CSHIMS:+"$CSHIMS/platform_shims.o"}', ld)
        self.assertIn('${CSHIMS:+"$CSHIMS/string_shims.o"}', ld)
        self.assertIn('${CSHIMS:+"$CSHIMS/uuid.o"}', ld)
        self.assertIn('"${FE_OBJECTS[@]}"', umbrella_ld)
        fe_flags = build.split("FE_FLAGS=(", 1)[1].split("FE_OBJECTS=(", 1)[0]
        self.assertIn('-I "$FE_COLLECTIONS"', fe_flags)
        self.assertIn('-I "$FE_OS"', fe_flags)
        self.assertIn(
            '-Xcc -fmodule-map-file="$SWIFT_FOUNDATION/Sources/_FoundationCShims/include/module.modulemap"',
            fe_flags,
        )

    def test_umbrella_compile_passes_opencombine_helpers_module_map(self) -> None:
        text = BUILD.read_text()
        self.assertIn(
            'cp "$OPENCOMBINE_HELPERS/include/COpenCombineHelpers.h"',
            text,
        )
        self.assertIn(
            '"$OPENCOMBINE_HELPERS/include/module.modulemap" '
            '"$PACKAGE/include/COpenCombineHelpers/"',
            text,
        )
        self.assertIn(
            'packaged COpenCombineHelpers module map is missing from PACKAGE/include',
            text,
        )
        umbrella = text.split(
            "== compile the bounded Foundation umbrella after SwiftUI", 1
        )[1].split("== FoundationGuest/UIKit notification identity compile proof", 1)[0]
        self.assertIn('umbrella_swiftc=(', umbrella)
        self.assertIn('printf \'umbrella-swiftc\'', umbrella)
        self.assertIn('printf \' %q\' "${umbrella_swiftc[@]}"', umbrella)
        self.assertIn('"${umbrella_swiftc[@]}"', umbrella)
        self.assertIn('"${PACKAGE_CINC[@]}"', umbrella)
        self.assertIn(
            '-Xcc -fmodule-map-file="$PACKAGE/include/COpenCombineHelpers/module.modulemap"',
            umbrella,
        )
        self.assertIn('-Xcc -I"$PACKAGE/include/COpenCombineHelpers"', umbrella)
        package_cinc = text.split("PACKAGE_CINC=(", 1)[1].split("FE_OUT=", 1)[0]
        self.assertIn(
            '-Xcc -fmodule-map-file="$PACKAGE/include/COpenCombineHelpers/module.modulemap"',
            package_cinc,
        )
        self.assertIn('-Xcc -I"$PACKAGE/include/COpenCombineHelpers"', package_cinc)

    def test_umbrella_imports_project_dispatch_not_sysroot(self) -> None:
        text = BUILD.read_text()
        self.assertNotIn("-disable-implicit-swift-module-map", text)
        self.assertNotIn("SWIFT_FORCE_MODULE_LOADING", text)
        dispatch = text.split(
            "== compile the project Dispatch module before the Foundation umbrella", 1
        )[1].split("== compile the bounded Foundation umbrella after SwiftUI", 1)[0]
        umbrella = text.split(
            "== compile the bounded Foundation umbrella after SwiftUI", 1
        )[1].split("== FoundationGuest/UIKit notification identity compile proof", 1)[0]
        self.assertIn('"$W/full/dispatch/Dispatch.swift"', dispatch)
        self.assertIn('"$W/full/dispatch/OpenDispatchBridge.c"', dispatch)
        self.assertIn("DISPATCH_DARWIN=$RUNROOT/darwin/usr/lib/libOpenDispatch.dylib", text)
        self.assertIn("-install_name /usr/lib/libOpenDispatch.dylib", dispatch)
        self.assertIn('"$DISPATCH_DARWIN"', dispatch)
        self.assertIn(
            'assert_no_glibc_host_imports "$PACKAGE/libDispatch.dylib"',
            dispatch,
        )
        self.assertNotIn('"$OUT/open-dispatch-bridge.o" \\', dispatch.split("run_link libDispatch", 1)[1])
        self.assertIn('-module-name Dispatch', dispatch)
        self.assertIn('-emit-module-path "$PACKAGE/Dispatch.swiftmodule"', dispatch)
        self.assertIn('-I "$PACKAGE"', dispatch)
        self.assertNotIn("-I \"$SYS/usr/lib/swift\"", dispatch)
        self.assertNotIn("-I$SYS/usr/lib/swift", dispatch)
        self.assertNotIn("-I \"$SYS/usr/lib/swift\"", umbrella)
        self.assertNotIn("-I$SYS/usr/lib/swift", umbrella)
        self.assertIn('-I "$PACKAGE"', umbrella)
        package_index = umbrella.index('-I "$PACKAGE"')
        sys_index = umbrella.find("$SYS/usr/lib/swift")
        if sys_index != -1:
            self.assertLess(package_index, sys_index)
        self.assertIn("project Dispatch swiftmodule is missing after build", dispatch)
        swiftc = text.split("SWIFTC=(", 1)[1].split("LD=(", 1)[0]
        self.assertNotIn("-I \"$SYS/usr/lib/swift\"", swiftc)
        self.assertNotIn("-I$SYS/usr/lib/swift", swiftc)

    def test_darwin_compiles_do_not_include_host_toolchain_swift(self) -> None:
        text = BUILD.read_text()
        swiftc = text.split("SWIFTC=(", 1)[1].split("LD=(", 1)[0]
        package_cinc = text.split("PACKAGE_CINC=(", 1)[1].split("FE_OUT=", 1)[0]
        fe_flags = text.split("FE_FLAGS=(", 1)[1].split("FE_OBJECTS=(", 1)[0]
        umbrella = text.split(
            "== compile the bounded Foundation umbrella after SwiftUI", 1
        )[1].split("== FoundationGuest/UIKit notification identity compile proof", 1)[0]
        self.assertIn('-target "$TARGET"', swiftc)
        self.assertIn('-sdk "$SYS"', swiftc)
        self.assertIn('-Xcc -isysroot -Xcc "$SYS"', swiftc)
        self.assertIn('-Xcc -target -Xcc "$TARGET"', swiftc)
        self.assertIn(
            '-Xcc -fmodule-map-file="$PACKAGE/include/CoreFoundation/module.modulemap"',
            package_cinc,
        )
        self.assertIn('-Xcc -I"$PACKAGE/include/CoreFoundation"', package_cinc)
        self.assertIn(
            'cp "$CF_HEADER_DIR/CoreFoundation.h"',
            text,
        )
        for blob in (swiftc, package_cinc, fe_flags, umbrella):
            self.assertNotIn("-I /usr/lib/swift", blob)
            self.assertNotIn("-I/usr/lib/swift", blob)
            self.assertNotIn("-Xcc -I/usr/lib/swift", blob)
            self.assertNotIn("/usr/lib/swift/CoreFoundation", blob)
            self.assertNotIn("arm64e-apple-macos", blob)
        self.assertIn("arm64-apple-macos", (ROOT / "full/scripts/guest_arch.inc").read_text())

    def test_machorun_sites_share_composed_preload_and_runtime_overlay(self) -> None:
        text = BUILD.read_text()
        helper = (ROOT / "full/swiftui/host_preload_dlsym_probe.c").read_text()
        resolve = (ROOT / "machorun/src/resolve.c").read_text()
        image = (ROOT / "machorun/src/image.c").read_text()
        deny = (ROOT / "machorun/src/host_deny.c").read_text()
        self.assertIn("run_machorun_site()", text)
        self.assertIn('echo "== machorun site: $site"', text)
        self.assertIn('LD_PRELOAD="$EARLY_PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}"', text)
        self.assertIn('MACHORUN_ROOT="$RUNROOT"', text)
        self.assertIn("cp -a \"$MRROOT/.\" \"$RUNROOT/\"", text)
        self.assertIn("dlsym(RTLD_DEFAULT", helper)
        self.assertIn("from->is_runtime", resolve)
        self.assertIn("host_lookup(name)", resolve)
        self.assertIn("*is_runtime = 1;", image)
        self.assertIn("A Darwin absolute path.", image)
        self.assertIn("`_glibc_*` IS NOT AND MUST NOT BE DENIED", deny)
        self.assertIn(
            "if (!*found && from->is_runtime)",
            resolve,
        )

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
