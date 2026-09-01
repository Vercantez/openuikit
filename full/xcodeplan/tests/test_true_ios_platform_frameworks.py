#!/usr/bin/env python3

from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[3]
BUILDER = ROOT / "full/xcodeplan/build_true_ios_platform_frameworks.sh"
PROBE = ROOT / "full/xcodeplan/tests/TrueIOSSwiftUIDylibProbe.swift"
INTEGRATION = (
    ROOT / "full/xcodeplan/TRUE_IOS_FOUNDATIONMODELS_NATURALLANGUAGE_INTEGRATION.md"
)


class TrueIOSPlatformFrameworkTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.builder = BUILDER.read_text(encoding="utf-8")
        cls.probe = PROBE.read_text(encoding="utf-8")
        cls.integration = INTEGRATION.read_text(encoding="utf-8")

    def test_builder_is_valid_strict_shell(self) -> None:
        subprocess.run(["bash", "-n", str(BUILDER)], check=True)
        self.assertIn("set -euo pipefail", self.builder)

    def test_builder_emits_the_split_first_party_dylib_graph(self) -> None:
        for module in (
            "FoundationEssentials",
            "FoundationInternationalization",
            "Foundation",
            "Dispatch",
            "OpenCoreGraphics",
            "OpenUIKit",
            "DeveloperToolsSupport",
            "UIKit",
            "OpenCombine",
            "Combine",
            "Symbols",
            "SwiftUI",
            "UniformTypeIdentifiers",
            "BackgroundTasks",
            "CoreSpotlight",
            "FoundationModels",
            "NaturalLanguage",
            "AuthenticationServices",
            "_AuthenticationServices_SwiftUI",
            "Accelerate",
            "Compression",
            "CoreText",
        ):
            self.assertIn(f"lib{module}.dylib", self.builder)
            if module != "FoundationInternationalization":
                self.assertIn(f"/usr/lib/lib{module}.dylib", self.builder)
        self.assertIn("PRIVATE_DYLIBS=(_FoundationICU)", self.builder)
        self.assertIn("RUNTIME_SWIFT_MODULES=(Observation)", self.builder)
        self.assertIn("/usr/lib/swift/libswiftObservation.dylib", self.builder)
        runtime_search = self.builder.index('-L"$RUNTIME_ROOT/darwin/usr/lib/swift"')
        inherited_search = self.builder.index('-L"$MRROOT_INPUT/darwin/usr/lib"')
        self.assertLess(runtime_search, inherited_search)
        self.assertIn("DYLIB_INSTALL_PREFIX=/usr/lib", self.builder)
        self.assertIn(
            "_$s10Foundation24_getErrorDefaultUserInfoyyXlSgxs0C0RzlF",
            self.builder,
        )
        self.assertIn(
            "_$s10Foundation21_bridgeNSErrorToError_3outSbSo0C0C_"
            "SpyxGtAA021_ObjectiveCBridgeableE0RzlF",
            self.builder,
        )
        self.assertIn("_$s10Foundation26_ObjectiveCBridgeableErrorMp", self.builder)
        self.assertIn(
            "_$sSo10CFErrorRefas5Error10FoundationMc", self.builder
        )
        self.assertIn("COpenFoundationCore/module.modulemap", self.builder)
        for forbidden in (
            "_CFErrorGetDomain", "_CFErrorGetCode", "_CFErrorCopyUserInfo"
        ):
            self.assertIn(forbidden, self.builder)

        self.assertIn('TARGET=arm64-apple-ios18.0-simulator', self.builder)
        self.assertIn('PLATFORM=ios-simulator', self.builder)
        self.assertIn('SDK_VERSION=26.1', self.builder)
        self.assertIn('-framework SwiftUI -framework UIKit', self.builder)
        self.assertEqual(
            self.builder.count("-Xfrontend -enable-cross-import-overlays"), 1
        )

    def test_full_foundation_precedes_final_uikit_and_swiftui(self) -> None:
        foundation = self.builder.index("33-source public Foundation facade")
        developer_tools = self.builder.index("post-Foundation DeveloperToolsSupport")
        swiftui = self.builder.index("-module-name SwiftUI -emit-module")
        self.assertLess(foundation, developer_tools)
        self.assertLess(developer_tools, swiftui)
        self.assertIn("FOUNDATION_ICU_JOBS", self.builder)
        self.assertIn('LINK_PLATFORM="$PLATFORM"', self.builder)
        self.assertIn('DYLIB_INSTALL_PREFIX=/usr/lib', self.builder)

    def test_platform_publishes_six_relocatable_compiler_plugins(self) -> None:
        for module in (
            "ObservationMacros",
            "FoundationMacros",
            "SwiftDataMacros",
            "FoundationModelsMacros",
            "OpenUIKitPreviewMacros",
            "OpenSwiftUIMacros",
        ):
            self.assertIn(f"lib{module}.so", self.builder)
        self.assertIn("true-ios-compiler-plugins-v1", self.builder)
        self.assertIn("host-tools", self.builder)

    def test_public_modules_are_consumed_from_framework_bundles(self) -> None:
        self.assertIn('FRAMEWORKS=$SDK_OUT/System/Library/Frameworks', self.builder)
        self.assertIn('stage_framework "$module"', self.builder)
        self.assertIn('-Rmodule-loading', self.builder)
        for module in (
            "SwiftUI",
            "UIKit",
            "FoundationModels",
            "NaturalLanguage",
            "AuthenticationServices",
            "_AuthenticationServices_SwiftUI",
            "UniformTypeIdentifiers",
            "BackgroundTasks",
            "CoreSpotlight",
            "Accelerate",
            "Compression",
            "CoreText",
        ):
            self.assertIn(module, self.builder)
        self.assertIn(
            'loaded module \'$module\'; source: \'$expected_module_path\'',
            self.builder,
        )
        self.assertIn('-sdk "$SDK_OUT" -I "$APPLE_OVERLAYS_OUT"', self.builder)
        self.assertIn('PUBLISHED_INCLUDE=$stage/platform-include', self.builder)
        self.assertNotIn('mkdir -p "$SDK_OUT/usr/local"', self.builder)
        self.assertNotIn('$SDK_OUT/usr/local/include', self.builder)

    def test_build_is_source_preserving_atomic_and_stale_safe(self) -> None:
        self.assertIn('uikit_status=$(git -C "$UIKIT" status', self.builder)
        self.assertIn('SOURCE_SUBJECT_BEFORE=$(source_subject)', self.builder)
        self.assertIn('SOURCE_SUBJECT_AFTER=$(source_subject)', self.builder)
        self.assertIn('rm -rf -- "$OUTPUT_ROOT"', self.builder)
        self.assertIn('stage=$(mktemp -d', self.builder)
        self.assertIn('rm -rf -- "$BUILD" "$INCLUDE"', self.builder)
        self.assertIn('mv "$stage" "$OUTPUT_ROOT"', self.builder)
        self.assertIn('sha256sum -c attestation/target-sdk-inputs.sha256', self.builder)
        self.assertIn(
            'find products package internal-modules sdk apple-overlays platform-include',
            self.builder,
        )
        self.assertIn('runtime-root sdk-provenance', self.builder)
        self.assertIn('find attestation -type f', self.builder)
        self.assertIn('> "$AUDIT/symlinks.tsv"', self.builder)
        self.assertIn('artifacts=$artifact_ledger_sha symlinks=$symlink_ledger_sha', self.builder)
        self.assertIn('true_ios_platform_package.py', self.builder)
        self.assertIn('"$stage" --emit-summary', self.builder)
        self.assertIn(
            'current_full_subject=$(bash "$W/full/scripts/uihelpers_subject.sh"',
            self.builder,
        )
        self.assertIn(
            '"$FULL/foundation-fe-object-provenance.tsv"', self.builder
        )
        self.assertIn('python3 "$FE_OBJECT_PROVENANCE_TOOL" verify', self.builder)
        self.assertIn(
            "full build is incompatible with active project sources", self.builder
        )

    def test_probe_exercises_swiftui_through_uikit_at_runtime(self) -> None:
        self.assertIn('import SwiftUI', self.probe)
        self.assertIn('import UIKit', self.probe)
        self.assertIn('import FoundationModels', self.probe)
        self.assertIn('import NaturalLanguage', self.probe)
        self.assertIn('import AuthenticationServices', self.probe)
        self.assertIn('import UniformTypeIdentifiers', self.probe)
        self.assertIn('import BackgroundTasks', self.probe)
        self.assertIn('import CoreSpotlight', self.probe)
        self.assertIn('import Accelerate', self.probe)
        self.assertIn('import Compression', self.probe)
        self.assertIn('import CoreText', self.probe)
        self.assertIn('UIHostingController', self.probe)
        self.assertIn('VStack(spacing:', self.probe)
        self.assertIn('Button("Advance")', self.probe)
        self.assertIn('precondition(renderedText && renderedButton)', self.probe)
        marker = 'TRUE_IOS_SWIFTUI_DYLIB_RUNTIME_OK'
        self.assertIn(marker, self.probe)
        self.assertIn(marker, self.builder)
        self.assertIn("let cfErrorAsError: any Error = cfError", self.probe)
        self.assertIn("recognizer.dominantLanguage", self.probe)
        self.assertIn("SystemLanguageModel.default", self.probe)
        self.assertIn('"portable".generatedContent.jsonString', self.probe)
        self.assertIn("EnvironmentValues().webAuthenticationSession", self.probe)
        self.assertIn("BGAppRefreshTaskRequest", self.probe)
        self.assertIn("pendingTaskRequests()", self.probe)
        self.assertIn("CSSearchableItemAttributeSet", self.probe)
        self.assertIn("indexSearchableItems", self.probe)
        self.assertIn("vImageBoxConvolve_ARGB8888", self.probe)
        self.assertIn("InputFilter<Data>(.decompress", self.probe)
        self.assertIn("CTFontManagerRegisterFontsForURL", self.probe)
        self.assertIn(
            "cfErrorAsError._getEmbeddedNSError() === cfError", self.probe
        )

    def test_background_tasks_and_core_spotlight_are_true_ios_products(self) -> None:
        for evidence in (
            "UNIFORM_TYPE_IDENTIFIERS_SOURCES_MANIFEST",
            "BACKGROUND_TASKS_SOURCES_MANIFEST",
            "CORE_SPOTLIGHT_SOURCES_MANIFEST",
            "true-ios-backgroundtasks-corespotlight-sources-v1",
            "true-ios-backgroundtasks-corespotlight-loads-v1",
            "-lFoundation -lFoundationEssentials -lDispatch",
            "-lUniformTypeIdentifiers",
            "BackgroundTasks Dispatch load count drifted",
            "CoreSpotlight UniformTypeIdentifiers load count drifted",
        ):
            self.assertIn(evidence, self.builder)
        self.assertIn("uniform-types=text", self.probe)
        self.assertIn("backgroundtasks=scheduler", self.probe)
        self.assertIn("corespotlight=index", self.probe)

    def test_foundationmodels_and_naturallanguage_frontier_is_cold_and_exact(self) -> None:
        for evidence in (
            "foundationmodels-icecubes-probe",
            "naturallanguage-generalization-probe",
            "foundationmodels-macro-expansions.log",
            "foundationmodels-runtime-exports.txt",
            "foundationmodels-naturallanguage-sources.tsv",
            "foundationmodels-apple-26.1.txt",
            "naturallanguage-generalization-apple-26.1.txt",
            "FOUNDATIONMODELS_GUEST_MACHO_OK",
            "NaturalLanguage 29-row generalization",
        ):
            self.assertIn(evidence, self.builder)
        self.assertIn("libFoundationModelsMacros.so", self.builder)
        self.assertIn("true-ios-foundationmodels-natural-auth-loads-v2", self.builder)
        self.assertIn("cmp \"$AUDIT/naturallanguage-generalization-runtime.log\"", self.builder)

    def test_cold_runtime_has_one_portable_foundation_identity(self) -> None:
        self.assertIn("rewrite_macho_dependency.py", self.builder)
        self.assertIn(
            "/System/Library/Frameworks/Foundation.framework/Foundation",
            self.builder,
        )
        self.assertIn("/usr/lib/libFoundation.dylib", self.builder)
        for library in (
            "libswiftCore.dylib",
            "libswiftSynchronization.dylib",
            "libswift_Builtin_float.dylib",
            "libswift_Concurrency.dylib",
            "libswift_RegexParser.dylib",
            "libswift_StringProcessing.dylib",
        ):
            self.assertIn(library, self.builder)
        self.assertIn(
            "true-ios-runtime-foundation-load-rewrites-v1", self.builder
        )
        self.assertIn("runtime-foundation-load-rewrites.tsv", self.builder)
        self.assertIn("foundationmodels-runtime.stderr.log", self.builder)
        self.assertIn("NaturalLanguage cold loader stderr differs", self.builder)

    def test_coretext_probe_keeps_the_real_filemanager_fts_contract(self) -> None:
        self.assertEqual(
            self.probe.count("try? manager.removeItem(at: root)"), 2
        )
        self.assertIn(
            "try manager.createDirectory(at: root, withIntermediateDirectories: true)",
            self.probe,
        )
        self.assertEqual(self.probe.count("try manager.copyItem"), 2)
        self.assertNotIn("let fontData = try Data(contentsOf: source)", self.probe)
        self.assertNotIn(
            "precondition(!manager.fileExists(atPath: root.path))", self.probe
        )
        self.assertNotIn(
            'rm -rf -- "$stage/coretext-runtime-fonts"', self.builder
        )

    def test_integration_contract_requires_a_fresh_complete_fts_replay(self) -> None:
        for omitted in (
            "d03d48d0ad67e7fb3cfef84666077d8a9021a81d",
            "d05115d3fe2b25a2b51b82401d1f694caeac3f9b",
        ):
            self.assertIn(omitted, self.integration)
        self.assertIn(
            "MACHORUN=/private/tmp/machorun-fts-20260901", self.integration
        )
        self.assertIn('bash "$replay/full/scripts/build_full.sh"', self.integration)
        self.assertIn(
            'MRROOT_INPUT="$replay/scratch/mrroot_full"', self.integration
        )
        self.assertIn(
            "OUTPUT_ROOT=/private/tmp/true-fm-nl-fts-platform-proof-20260901/"
            "true-ios-platform",
            self.integration,
        )
        self.assertIn("do not copy a lone `libSystem.B.dylib`", self.integration)


if __name__ == "__main__":
    unittest.main()
