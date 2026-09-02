#!/usr/bin/env python3
"""Regression teeth for the unchanged Focus full-package guest boundary."""

from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[2]
BUILD = ROOT / "full/swiftui/build_focus_package_guest.sh"
BASE_BUILD = ROOT / "full/swiftui/build_focus_onboarding_guest.sh"
FOUNDATION = ROOT / "full/appshim/FoundationGuest.swift"
PACKAGE_PROBE = ROOT / "full/swiftui/FocusPackageRuntimeProbe.swift"
LICENSES_PROBE = ROOT / "full/swiftui/FocusLicensesGuestMain.swift"
LICENSES_ACCESSOR = ROOT / "full/swiftui/FocusLicensesBundle.generated.swift"
SNAPKIT_ACCESSOR = ROOT / "full/swiftui/FocusSnapKitBundle.generated.swift"
DESIGNSYSTEM_ACCESSOR = (
    ROOT / "full/swiftui/FocusDesignSystemBundle.generated.swift"
)
WIDGET_ACCESSOR = ROOT / "full/swiftui/FocusWidgetBundle.generated.swift"
ONBOARDING_ACCESSOR = ROOT / "full/swiftui/FocusOnboardingBundle.generated.swift"
ACCESSOR_ATTEST = ROOT / "full/swiftui/focus_resource_accessor_attest.pl"
ACCESSOR_ORACLE = ROOT / "full/swiftui/FOCUS_RESOURCE_ACCESSOR_ORACLE.tsv"
FOCUS = ROOT / "scratch/ladder-corpus/focus-ios/focus-ios"
SNAPKIT = ROOT / "scratch/xcodeplan-deps/SnapKit"


class FocusPackageGuestProofTests(unittest.TestCase):
    def test_build_scripts_have_valid_shell_syntax(self) -> None:
        subprocess.run(["bash", "-n", str(BUILD)], check=True)
        subprocess.run(["bash", "-n", str(BASE_BUILD)], check=True)

    def test_both_clean_module_caches_are_explicitly_prewarmed(self) -> None:
        for script in (BUILD, BASE_BUILD):
            text = script.read_text()
            self.assertIn("-parse-stdlib -typecheck", text)
            self.assertIn("-e 'import Swift'", text)

    def test_landed_uikit_is_literal_and_base_proof_is_preserved(self) -> None:
        text = BUILD.read_text()
        self.assertIn(
            "EXPECTED_UIKIT_TREE=$EXPECTED_INREPO_UIKIT_TREE",
            text,
        )
        self.assertIn('assert_vendor_tree "$W" uikit', text)
        self.assertIn(
            'bash "$W/full/swiftui/build_focus_onboarding_guest.sh"', text
        )
        self.assertNotIn("EXPECTED_UIKIT_COMMIT_OVERRIDE", text)
        self.assertNotIn("${EXPECTED_UIKIT_COMMIT:?", text)
        self.assertNotIn(
            "EXPECTED_UIKIT_COMMIT="
            "62dea0d97a3b9074e5c016820492bd0656b9a35a",
            text,
        )
        self.assertIn("printf 'uikit-tree\\t%s\\n'", text)
        self.assertIn("HEAD:uikit", text)
        self.assertIn("FOCUS_ONBOARDING_MACHO_GUEST_OK", BASE_BUILD.read_text())

    def test_exact_unchanged_source_boundaries_are_pinned(self) -> None:
        text = BUILD.read_text()
        expected = {
            "SNAPKIT": ("SnapKit", 36, "0e3d407c38d2edfe48fecd643ef36519883bdec12e93d31d4fde4945168f5194"),
            "DESIGNSYSTEM": ("DesignSystem", 7, "fb619b923007c5e15a1d57f8f6a696377fe8fc991e211c66cb4ef62c8e385c66"),
            "WIDGET": ("Widget", 2, "e8f92a22ebf14849b8406e61b1ac531335ed6d0b937b6b629df25f7318f16e44"),
            "ONBOARDING": ("Onboarding", 21, "3653d727155b031f93f0bb6532f49428f48b8c39476f61e9f703cf81ad10d243"),
            "LICENSES": ("Licenses", 2, "43273d263b95324f5598b3c423fa38801b3e8a20aff85f36a3cf792fe25fd53e"),
        }
        for name, (label, count, digest) in expected.items():
            self.assertIn(f"EXPECTED_{name}_COUNT={count}", text)
            self.assertIn(f"EXPECTED_{name}_MANIFEST={digest}", text)
            self.assertIn(f"check_source_manifest {label}", text)
            self.assertIn(f"check_source_manifest post-{label}", text)
        self.assertEqual(text.count("LC_ALL=C sort -z"), 6)
        self.assertIn("EXPECTED_FOCUS_COMMIT=a2832521", text)
        self.assertIn("EXPECTED_SNAPKIT_COMMIT=e74fe2a", text)
        self.assertNotRegex(
            text,
            r"(?m)^\s*(sed|perl|python\d*)\b.*\$FOCUS_SOURCES.*\.swift",
        )

    def test_foundation_has_one_identity_and_pinned_observation_provider(self) -> None:
        source = FOUNDATION.read_text()
        self.assertIn("@_exported import FoundationEssentials", source)
        self.assertIn("@_exported import Combine", source)
        self.assertIn("public typealias NSCoder = OpenUIKit.NSCoder", source)
        self.assertIn("public typealias Bundle = OpenUIKit.Bundle", source)
        self.assertNotIn("public typealias NSString", source)
        self.assertEqual(source.count("public typealias Bundle"), 1)
        self.assertNotIn("func url(\n        forResource", source)
        self.assertIn("case value(AnyHashable)", source)
        self.assertIn("case identity(ObjectIdentifier)", source)
        self.assertIn("private var storage: [Key: Any]", source)
        self.assertIn("func canOpenURL(_ url: URL)", source)

    def test_snapkit_debugging_exclusion_is_exact_and_audited(self) -> None:
        text = BUILD.read_text()
        self.assertIn("EXPECTED_SNAPKIT_TOTAL_COUNT=37", text)
        self.assertIn("EXPECTED_SNAPKIT_COUNT=36", text)
        self.assertIn(
            "EXPECTED_SNAPKIT_DEBUGGING_SHA="
            "6af70d54a6e6fb112d87f8adb93caead0bc2afc472e4bbb04347bf591be3b3e3",
            text,
        )
        self.assertIn("! -name Debugging.swift", text)
        self.assertIn("SnapKit exclusion count is not exactly one", text)
        self.assertIn("snapkit-source-exclusions-v1", text)
        self.assertIn("requires-NSObject-ObjC-dynamic-description-surface", text)
        self.assertIn("printf 'snapkit-exclusions\\t%s\\n'", text)
        self.assertNotIn("! -name SnapKit.generated.swift", text)

    def test_bundle_published_and_snapkit_runtime_are_behavioral(self) -> None:
        source = PACKAGE_PROBE.read_text()
        for token in (
            "Bundle.main",
            "Bundle(path:",
            "Bundle(for:",
            'forResource: "bundle-provider-marker"',
            '"/Resources/bundle-provider-marker.txt"',
            'url(forResource: "present", withExtension: "txt")',
            "OnboardingEventsHandlerV1",
            "OnboardingEventsHandlerV2",
            "storedV2 == [.onboarding(.v2)]",
            "snapView.snp.makeConstraints",
            "snapView.snp.removeConstraints()",
            "NSMutableSet()",
            "weak var retainedEqual",
            "weak var retainedIdentity",
            "identity-keyed object retention",
        ):
            self.assertIn(token, source)
        build = BUILD.read_text()
        for marker in (
            "FOCUS_PACKAGE_FOUNDATION_OK",
            "FOCUS_PACKAGE_PUBLISHED_OK",
            "FOCUS_PACKAGE_SNAPKIT_OK",
        ):
            self.assertIn(marker, source)
            self.assertIn(marker, build)

        self.assertIn(
            '"$PROBE_APP/Contents/MacOS/FocusPackageProbe"', build
        )
        self.assertNotIn(
            "./FocusPackageProbe.app/Contents/MacOS/FocusPackageProbe", build
        )
        self.assertNotIn("PROVIDER_GUEST_PATH", build)
        self.assertIn(
            '"$PROBE_APP" "$OUT/FlatResources.bundle" "$PROVIDER"', build
        )
        self.assertIn(
            "c574e2edbf1969f408fc94e597304e30cdf22f4eee76b5c84d45afcb06ca1df3",
            build,
        )
        self.assertIn("post-run-dynamic-Bundle-provider-marker", build)
        self.assertIn("printf 'bundle-provider-image\\t%s\\n'", build)
        self.assertIn("printf 'bundle-provider-marker\\t%s\\n'", build)

    def test_designsystem_resources_are_explicitly_compile_only(self) -> None:
        accessor = DESIGNSYSTEM_ACCESSOR.read_text()
        build = BUILD.read_text()
        self.assertIn("compatibility build support", accessor)
        self.assertIn("declares no DesignSystem resources", accessor)
        self.assertIn("SWIFT_MODULE_RESOURCE_BUNDLE_UNAVAILABLE", accessor)
        self.assertIn("compile/link-only compatibility support", accessor)
        self.assertIn("Swift.fatalError", accessor)
        self.assertNotIn(".bundle", accessor)
        self.assertNotIn("appendingPathComponent", accessor)
        self.assertIn("printf 'designsystem-bundle-accessor\\t%s\\n'", build)

    def test_resource_accessor_oracle_is_executable_and_fail_closed(self) -> None:
        selftest = subprocess.run(
            ["perl", str(ACCESSOR_ATTEST), "selftest"],
            check=True,
            text=True,
            capture_output=True,
        )
        self.assertEqual(
            selftest.stdout.strip(),
            "RESOURCE_ACCESSOR_SELFTEST_OK positives=3 negatives=21",
        )
        observed = subprocess.run(
            [
                "perl",
                str(ACCESSOR_ATTEST),
                "attest",
                "--focus-root",
                str(FOCUS),
                "--snapkit-root",
                str(SNAPKIT),
                "--support-root",
                str(ROOT),
                "--build-script",
                str(BUILD),
            ],
            check=True,
            capture_output=True,
        ).stdout
        self.assertEqual(observed, ACCESSOR_ORACLE.read_bytes())

    def test_exact_swiftpm_resource_graph_and_direct_build_policy_are_attested(self) -> None:
        oracle = ACCESSOR_ORACLE.read_text()
        build = BUILD.read_text()
        attestor = ACCESSOR_ATTEST.read_text()
        for token in (
            "Focus/DesignSystem\tunavailable\t-\tSWIFT_PACKAGE,SWIFT_MODULE_RESOURCE_BUNDLE_UNAVAILABLE",
            "Focus/Widget\tunavailable\t-\tSWIFT_PACKAGE,SWIFT_MODULE_RESOURCE_BUNDLE_UNAVAILABLE",
            "Focus/Onboarding\tunavailable\t-\tSWIFT_PACKAGE,SWIFT_MODULE_RESOURCE_BUNDLE_UNAVAILABLE",
            "Focus/Licenses\tavailable\tFocus_Licenses.bundle\tSWIFT_PACKAGE,SWIFT_MODULE_RESOURCE_BUNDLE_AVAILABLE",
            "SnapKit/SnapKit\tavailable\tSnapKit_SnapKit.bundle\tSWIFT_PACKAGE,SWIFT_MODULE_RESOURCE_BUNDLE_AVAILABLE",
            "direct-swiftc\tresource-defines\tnone\tupstream-conditional-hits=0",
            "normalization\tFocus/Licenses\tabsolute-build-path=<BUILD_PATH>\tterminal=LF-appended",
            "normalization\tSnapKit/SnapKit\tabsolute-build-path=<BUILD_PATH>\tterminal=LF-appended",
        ):
            self.assertIn(token, oracle)
        for digest in (
            "2d29b769de137389f5613de6755211b255533375bf6003a2192f514e96899248",
            "632a0df0276ba7828f456ae3964f158fb7115d05f175ddf637abdd7ab4a4633b",
            "ebb3e3c90a96e832e848e577c04b0cb9f16723c487c0efa727114d49c0a5492a",
            "a07418e5fe128e224cd37964bc21c503b7aa2f575e7b4927468478ad873214fe",
            "a15ebd0e3c1e83ae3f8456593f1fb0c761af03e1b9742a9f34ede4c83669fe95",
            "056cdac408eab88cced7e48cab8548c5393f6ac3040a8b0a578e77f08885b218",
        ):
            self.assertIn(digest, oracle + build + attestor)
        self.assertIn("balanced_target_calls", attestor)
        self.assertIn("upstream_conditional_hits", attestor)
        self.assertIn("swiftc_invocations", attestor)
        self.assertIn("later-ledger", attestor)
        self.assertIn("misplaced", attestor)
        self.assertIn("__SWAPPED_SUPPORT__", attestor)
        self.assertNotIn("index($build, '\\\${SWIFTC[@]}'", attestor)
        for path in (
            ROOT / "full/swiftui/oracles/apple-swiftpm-6.2.1/Focus_Licenses.resource_bundle_accessor.normalized.swift.txt",
            ROOT / "full/swiftui/oracles/apple-swiftpm-6.2.1/SnapKit_SnapKit.resource_bundle_accessor.normalized.swift.txt",
        ):
            data = path.read_bytes()
            self.assertTrue(data.endswith(b"}\n"))
            self.assertFalse(data.endswith(b"}\n\n"))
        self.assertIn('perl "$ACCESSOR_ATTEST" attest', build)
        self.assertEqual(build.count('perl "$ACCESSOR_ATTEST" attest'), 2)
        self.assertIn("post-resource-accessor-provenance.tsv", build)
        self.assertIn("printf 'resource-accessor-provenance\\t%s\\n'", build)
        self.assertNotRegex(
            build,
            r"(?:^|\s)-D\s*SWIFT_PACKAGE\b|(?:^|\s)-DSWIFT_PACKAGE\b",
        )
        self.assertNotIn("-D SWIFT_MODULE_RESOURCE_BUNDLE_", build)
        self.assertNotIn("-DSWIFT_MODULE_RESOURCE_BUNDLE_", build)

    def test_undeclared_focus_resource_support_is_honestly_compatibility_only(self) -> None:
        for accessor_path, bundle_name in (
            (WIDGET_ACCESSOR, "Focus_Widget.bundle"),
            (ONBOARDING_ACCESSOR, "Focus_Onboarding.bundle"),
        ):
            accessor = accessor_path.read_text()
            self.assertIn("compatibility build support", accessor)
            self.assertIn("SWIFT_MODULE_RESOURCE_BUNDLE_UNAVAILABLE", accessor)
            self.assertIn(bundle_name, accessor)
            self.assertIn("Bundle.main.bundleURL.appendingPathComponent", accessor)
            self.assertIn("Swift.fatalError", accessor)
            self.assertNotIn("buildPath", accessor)
        for support in (
            "FocusDesignSystemBundle.generated.swift",
            "FocusWidgetBundle.generated.swift",
            "FocusOnboardingBundle.generated.swift",
        ):
            self.assertIn(support, BUILD.read_text())

    def test_snapkit_swiftpm_privacy_bundle_is_staged_and_exercised(self) -> None:
        accessor = SNAPKIT_ACCESSOR.read_text()
        build = BUILD.read_text()
        probe = PACKAGE_PROBE.read_text()
        for token in (
            '"SnapKit_SnapKit.bundle"',
            "Bundle.main.bundleURL.appendingPathComponent",
            "Bundle(path: mainPath)",
            "Swift.fatalError",
        ):
            self.assertIn(token, accessor)
        self.assertNotIn("buildPath", accessor)
        self.assertIn("FocusSnapKitBundle.generated.swift", build)
        self.assertIn('$PROBE_APP/SnapKit_SnapKit.bundle', build)
        self.assertIn('cp "$SNAPKIT_ROOT/Sources/PrivacyInfo.xcprivacy"', build)
        self.assertIn("SnapKit_SnapKit.bundle file inventory is not exactly one", build)
        self.assertIn("FocusSnapKitResourceProof.bundlePath", probe)
        self.assertIn("FocusSnapKitResourceProof.privacyManifestPath", probe)
        self.assertIn("FocusSnapKitResourceProof.missingResourcePath == nil", probe)
        self.assertIn("resource=privacy", probe)
        self.assertIn("post-run-staged-SnapKit-privacy-resource", build)
        self.assertIn("printf 'snapkit-bundle-accessor\\t%s\\n'", build)
        self.assertIn("printf 'snapkit-privacy-resource\\t%s\\n'", build)

    def test_licenses_uses_generated_primary_bundle_and_real_navigation(self) -> None:
        build = BUILD.read_text()
        accessor = LICENSES_ACCESSOR.read_text()
        probe = LICENSES_PROBE.read_text()
        for digest in (
            "63812032c2b82d2eb8269ed63458192e2783a3274919bf751b7ec6c09791376d",
            "560a8535f642e0f42ea9a4b155491256d4405e57dcca3f1565509ad6bf10f1d8",
        ):
            self.assertIn(digest, build)
        self.assertIn('module-name Licenses', build)
        self.assertIn('"${LICENSES_SRCS[@]}"', build)
        self.assertIn('libLicenses.dylib', build)
        self.assertIn('LICENSES_BUNDLE=$LICENSES_APP/Focus_Licenses.bundle', build)
        self.assertIn('"$LICENSES_BUNDLE/focus-ios.plist"', build)
        self.assertIn('"$LICENSES_BUNDLE/license-list.plist"', build)
        self.assertIn("Focus_Licenses.bundle file inventory is not exactly two", build)
        self.assertIn("Licenses resources leaked loose into app Contents/Resources", build)
        self.assertNotIn('$LICENSES_APP/Contents/Resources/focus-ios.plist', build)
        self.assertNotIn('$LICENSES_APP/Contents/Resources/license-list.plist', build)
        self.assertIn("post-run-staged-Focus-license-resource", build)
        self.assertIn("post-run-staged-library-licenses-resource", build)
        self.assertIn("LicenseListView()", probe)
        self.assertIn("@main", probe)
        self.assertIn("@MainActor", probe)
        self.assertIn('"SwiftUI.NavigationLink"', probe)
        self.assertIn("links.count == 8", probe)
        self.assertIn("window.tick(timestamp: 0.1)", probe)
        self.assertIn("navigation.viewControllers.count == 2", probe)
        self.assertIn(
            "FocusLicensesResourceProof.bundlePath == expectedBundle",
            probe,
        )
        self.assertIn('arguments[1] + "/Focus_Licenses.bundle"', probe)
        self.assertIn("FocusLicensesResourceProof.focusLicensePath", probe)
        self.assertIn("FocusLicensesResourceProof.libraryLicensesPath", probe)
        self.assertIn("FocusLicensesResourceProof.missingResourcePath == nil", probe)
        self.assertIn('"$LICENSES_APP"', build)
        self.assertIn("resources=2 bundle=module rows=8 navigation=push", build)
        self.assertIn("Bundle.main.bundleURL.appendingPathComponent", accessor)
        self.assertIn('"Focus_Licenses.bundle"', accessor)
        self.assertIn("Bundle(path: mainPath)", accessor)
        self.assertIn("Swift.fatalError", accessor)
        self.assertNotIn("static var module: Bundle { .main }", accessor)
        self.assertNotIn("buildPath", accessor)
        self.assertIn("not Mozilla Focus", accessor)
        self.assertIn("application source", accessor)

    def test_licenses_missing_bundle_control_rejects_loose_decoys(self) -> None:
        build = BUILD.read_text()
        for token in (
            "FocusLicensesMissing.app",
            '"$MISSING_LICENSES_APP/Contents/Resources"',
            '"$FOCUS_SOURCES/Licenses/focus-ios.plist"',
            '"$FOCUS_SOURCES/Licenses/license-list.plist"',
            "missing_licenses_rc",
            "expected SIGTRAP/133",
            "could not load main-relative Focus_Licenses.bundle:",
            "missing-bundle control unexpectedly gained adjacent resources",
            "licenses-missing-bundle.normalized.tsv",
            "licenses-missing-bundle-normalized",
            "fatal-message\\t%s",
            "topology\\tadjacent-bundle\\tabsent",
            "topology\\tapp-loose-decoys\\texact=2",
            "topology\\tcwd-loose-decoys\\texact=2",
            "success-marker\\tabsent",
        ):
            self.assertIn(token, build)
        self.assertNotIn("licenses-missing-bundle-stderr\\t", build)
        self.assertIn('cp "$FOCUS_SOURCES/Licenses/focus-ios.plist"', build)
        self.assertIn('"$OUT/"', build)
        self.assertIn('[ ! -e "$MISSING_LICENSES_APP/Focus_Licenses.bundle" ]', build)

    def test_outputs_are_real_arm64_macho_images(self) -> None:
        text = BUILD.read_text()
        for name in (
            "UIKit", "SnapKit", "DesignSystem", "Widget", "Onboarding", "Licenses"
        ):
            self.assertIn(f"lib{name}.dylib", text)
        self.assertIn("MH_MAGIC_64[[:space:]]+ARM64", text)
        self.assertIn('PROBE_APP=$OUT/FocusPackageProbe.app', text)
        self.assertIn('"$PROBE_APP/Contents/MacOS/FocusPackageProbe"', text)
        self.assertIn("FocusLicensesGuest.app/Contents/MacOS", text)
        self.assertIn("printf 'package-guest\\t%s\\n'", text)
        self.assertIn("printf 'licenses-guest\\t%s\\n'", text)
        self.assertIn("printf 'onboarding-bundle-accessor\\t%s\\n'", text)
        self.assertIn("printf 'widget-bundle-accessor\\t%s\\n'", text)
        self.assertIn("printf 'licenses-bundle-accessor\\t%s\\n'", text)
        self.assertGreaterEqual(text.count('focus_widget_guest_attest.pl" closure'), 4)
        self.assertIn("package probe recursive runtime closure drifted", text)
        self.assertIn("Licenses recursive runtime closure drifted", text)
        self.assertIn('"$MRROOT/machorun"', text)
        provider_link = text.split(
            "-install_name @rpath/FocusPackageProbe.framework/FocusPackageProbe",
            1,
        )[1].split('"${SWIFTC[@]}"', 1)[0]
        for tbd in (
            "libswiftCore.tbd",
            "libswiftObjectiveC.tbd",
            "libSystem.tbd",
            "libobjc.tbd",
        ):
            self.assertIn(tbd, provider_link)
        self.assertNotIn("$MRROOT/darwin/usr/lib/libSystem.B.dylib", provider_link)
        self.assertNotIn("-undefined dynamic_lookup", provider_link)
        self.assertIn(
            "dynamic Bundle provider is absent from recursive runtime closure",
            text,
        )


if __name__ == "__main__":
    unittest.main()
