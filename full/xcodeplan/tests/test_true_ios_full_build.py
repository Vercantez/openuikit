#!/usr/bin/env python3

import importlib.util
from pathlib import Path
import struct
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[3]
RETARGET_PATH = ROOT / "full/scripts/retarget_macho_build_version.py"
BUILD_FULL_PATH = ROOT / "full/scripts/build_full.sh"
STAGE_SDK_PATH = ROOT / "full/xcodeplan/stage_true_ios_full_sdk.sh"
UIHELPERS_SUBJECT_PATH = ROOT / "full/scripts/uihelpers_subject.sh"
FE_PROVENANCE_PATH = ROOT / "full/foundation/fe_object_provenance.py"


def load_retarget_module():
    spec = importlib.util.spec_from_file_location("retarget_macho", RETARGET_PATH)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def thin_macho(*, platform: int = 1, minimum: int = 0x000F0000,
               sdk: int = 0x001A0100) -> bytes:
    header = struct.pack(
        "<IIIIIIII",
        0xFEEDFACF,
        0x0100000C,
        0,
        6,
        1,
        24,
        0,
        0,
    )
    build_version = struct.pack("<IIIIII", 0x32, 24, platform, minimum, sdk, 0)
    return header + build_version + b"payload-is-untouched"


class RetargetMachOBuildVersionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.module = load_retarget_module()

    def test_packed_versions_are_exact(self) -> None:
        self.assertEqual(self.module.packed_version("18"), 0x00120000)
        self.assertEqual(self.module.packed_version("26.1"), 0x001A0100)
        self.assertEqual(self.module.packed_version("18.2.3"), 0x00120203)

    def test_only_build_version_identity_is_retargeted(self) -> None:
        before = thin_macho()
        with tempfile.TemporaryDirectory() as temporary:
            product = Path(temporary) / "runtime.dylib"
            product.write_bytes(before)
            self.module.retarget(
                product,
                platform=7,
                minimum=self.module.packed_version("18.0"),
                sdk=self.module.packed_version("26.1"),
            )
            after = product.read_bytes()

        self.assertEqual(len(after), len(before))
        self.assertEqual(after[:40], before[:40])
        self.assertEqual(after[52:], before[52:])
        self.assertEqual(struct.unpack_from("<III", after, 40), (7, 0x00120000, 0x001A0100))

    def test_non_macho_and_missing_build_version_are_refused(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            product = Path(temporary) / "invalid"
            product.write_bytes(b"not a Mach-O")
            with self.assertRaisesRegex(ValueError, "not a thin"):
                self.module.retarget(product, 7, 0x00120000, 0x001A0100)

            header_only = struct.pack(
                "<IIIIIIII", 0xFEEDFACF, 0x0100000C, 0, 6, 0, 0, 0, 0
            )
            product.write_bytes(header_only)
            with self.assertRaisesRegex(ValueError, "expected one LC_BUILD_VERSION"):
                self.module.retarget(product, 7, 0x00120000, 0x001A0100)


class TrueIOSFullBuildContractTests(unittest.TestCase):
    def test_full_builder_parameterizes_target_and_link_platform(self) -> None:
        source = BUILD_FULL_PATH.read_text(encoding="utf-8")
        for required in (
            'TARGET=${TARGET:-arm64-apple-macos15.0}',
            'LINK_PLATFORM=${LINK_PLATFORM:-macos}',
            'LINK_SDK_VERSION=${LINK_SDK_VERSION:-$MINOS}',
            'APPLE_SWIFT_USER_OVERLAYS=${APPLE_SWIFT_USER_OVERLAYS:-}',
            'SF=${SF:-$W/scratch/swift-foundation}',
            'SC=${SC:-$W/scratch/swift-collections}',
            'BASE_RUNTIME_SOURCE=${BASE_RUNTIME_SOURCE:-$W/scratch/mrroot}',
            '-platform_version "$LINK_PLATFORM" "$MINOS" "$LINK_SDK_VERSION"',
            '--platform 7 --minimum-os "$MINOS" --sdk "$LINK_SDK_VERSION"',
        ):
            self.assertIn(required, source)

    def test_sdk_stager_separates_darwin_from_sdk_modules(self) -> None:
        source = STAGE_SDK_PATH.read_text(encoding="utf-8")
        self.assertIn("APPLE_USER_MODULES=(", source)
        self.assertIn('copy_module_variant "$module_name" "$STAGE/apple-overlays"', source)
        self.assertIn("core SDK unexpectedly contains an iOS Apple SDK interface", source)
        self.assertIn(
            "TRUE_IOS_FULL_SDK_COMPLETE target=arm64-apple-ios18.0-simulator apple-overlays=darwin,objectivec",
            source,
        )

    def test_subject_bracket_accepts_explicit_pinned_source_roots(self) -> None:
        source = UIHELPERS_SUBJECT_PATH.read_text(encoding="utf-8")
        self.assertIn('SWIFT_FOUNDATION=${3:-$ROOT/scratch/swift-foundation}', source)
        self.assertIn('SWIFT_COLLECTIONS=${4:-$ROOT/scratch/swift-collections}', source)
        builder = BUILD_FULL_PATH.read_text(encoding="utf-8")
        self.assertEqual(builder.count('"$W" "$UIKIT" "$SF" "$SC"'), 2)

    def test_full_builder_publishes_fe_source_object_provenance_atomically(self) -> None:
        builder = BUILD_FULL_PATH.read_text(encoding="utf-8")
        provenance = FE_PROVENANCE_PATH.read_text(encoding="utf-8")
        self.assertIn("foundation-fe-object-provenance.tsv.tmp", builder)
        self.assertIn('python3 "$FE_OBJECT_PROVENANCE_TOOL" attest', builder)
        self.assertIn('python3 "$FE_OBJECT_PROVENANCE_TOOL" verify', builder)
        provenance_publish = builder.index(
            'mv "$OUT/foundation-fe-object-provenance.tsv.tmp"'
        )
        subject_publish = builder.index(
            'mv "$OUT/uihelpers-subject.sha256.tmp"'
        )
        self.assertLess(provenance_publish, subject_publish)
        for object_path in (
            "FoundationEssentials.o",
            "InternalCollectionsUtilities.o",
            "OrderedCollections.o",
            "_RopeModule.o",
            "os.o",
            "platform_shims.o",
            "string_shims.o",
            "uuid.o",
            "fm_unimplemented.o",
            "removefile_compat.o",
            "uuid_compat.o",
        ):
            self.assertIn(object_path, provenance)
        for source_path in (
            "os-module/os.swift",
            "fm_unimplemented.c",
            "removefile_compat.c",
            "removefile_compat.h",
            "uuid_compat.c",
        ):
            self.assertIn(source_path, provenance)

    def test_developer_tools_support_is_a_standalone_full_build_dependency(self) -> None:
        builder = BUILD_FULL_PATH.read_text(encoding="utf-8")
        self.assertIn(
            "BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODE="
            "${BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODE:-standalone}",
            builder,
        )
        self.assertIn(
            'case "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODE" in', builder
        )
        self.assertIn('if [ "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODE" = standalone ]; then', builder)
        self.assertIn('if [ "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODE" = external ]; then', builder)
        self.assertIn("disabled DTS mode lacks the core-package ownership token", builder)
        self.assertIn('-module-name DeveloperToolsSupport', builder)
        self.assertIn('$UIKIT/Sources/DeveloperToolsSupport/Preview.swift', builder)
        self.assertIn('PREVIEW_LINK_OBJECTS=("$DTS_OUT/developertoolsupport.o")', builder)
        foundation = builder.index("== app-only Foundation identity shim")
        developer_tools = builder.index(
            "== DeveloperToolsSupport (canonical target module)", foundation
        )
        uikit = builder.index("== literal UIKit shim", developer_tools)
        self.assertLess(foundation, developer_tools)
        self.assertLess(developer_tools, uikit)
        self.assertIn('-I "$OUT" -I "$APPINC"', builder[foundation:uikit])
        subject = UIHELPERS_SUBJECT_PATH.read_text(encoding="utf-8")
        self.assertIn('"$UIKIT/Sources/DeveloperToolsSupport"', subject)

    def test_full_runtime_stages_and_preloads_the_closed_host_boundary(self) -> None:
        builder = BUILD_FULL_PATH.read_text(encoding="utf-8")
        self.assertIn("HOST_RUNTIME_FILES=(", builder)
        self.assertIn("libOpenDispatchHost.so", builder)
        self.assertIn('rm -rf -- "$ROOTDIR/host"', builder)
        runner = (ROOT / "full/scripts/run_suite.sh").read_text(encoding="utf-8")
        self.assertIn('find "$MRROOT_HOST/host" -name \'*.so\'', runner)
        self.assertIn('HOSTOPT=(-e "LD_LIBRARY_PATH=$MRROOT/host"', runner)
        self.assertIn('${HOSTOPT[@]+"${HOSTOPT[@]}"}', runner)
        self.assertIn('CONTAINER_IMAGE=${CONTAINER_IMAGE:-swift-macho-spike:noble}', runner)
        self.assertIn('"$CONTAINER_IMAGE"', runner)


if __name__ == "__main__":
    unittest.main()
