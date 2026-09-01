from __future__ import annotations

import hashlib
import os
from pathlib import Path
import struct
import sys
import tempfile
import unittest


HERE = Path(__file__).resolve().parent
TOOL_DIR = HERE.parent
sys.path.insert(0, os.fspath(TOOL_DIR))

import true_ios_platform_package as platform_package  # noqa: E402


MODULES = (
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
    "NaturalLanguage",
    "AuthenticationServices",
    "_AuthenticationServices_SwiftUI",
    "Accelerate",
    "Compression",
    "CoreText",
)
PRIVATE_DYLIBS = ("_FoundationICU",)
SUFFIXES = ("swiftmodule", "swiftdoc", "swiftsourceinfo", "abi.json")
VARIANT = "arm64-apple-ios-simulator"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_command(command: int, payload: bytes) -> bytes:
    size = 8 + len(payload)
    size = (size + 7) & ~7
    return struct.pack("<II", command, size) + payload + bytes(size - 8 - len(payload))


def dylib_command(command: int, name: str) -> bytes:
    encoded = name.encode("utf-8") + b"\0"
    return load_command(command, struct.pack("<IIII", 24, 0, 0x10000, 0x10000) + encoded)


def macho(*, filetype: int, install_name: str | None = None,
          loads: tuple[str, ...] = ()) -> bytes:
    commands = [
        load_command(
            0x32,
            struct.pack("<IIII", 7, 0x00120000, 0x001A0100, 0),
        )
    ]
    if install_name is not None:
        commands.append(dylib_command(0x0D, install_name))
    commands.extend(dylib_command(0x0C, name) for name in loads)
    payload = b"".join(commands)
    header = struct.pack(
        "<IiiIIIII",
        0xFEEDFACF,
        0x0100000C,
        0,
        filetype,
        len(commands),
        len(payload),
        0,
        0,
    )
    return header + payload


def elf64_aarch64(label: str) -> bytes:
    payload = bytearray(64)
    payload[:6] = b"\x7fELF\x02\x01"
    struct.pack_into("<H", payload, 16, 3)
    struct.pack_into("<H", payload, 18, 183)
    payload.extend(label.encode("utf-8"))
    return bytes(payload)


class TrueIOSPlatformPackageTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="true-ios-package-test.")
        self.root = Path(self.temporary.name) / "package"
        for directory in (
            "apple-overlays",
            "attestation",
            "host-tools/swift/host/plugins",
            "host-tools/swift/linux",
            "internal-modules",
            "package",
            "platform-include",
            "products",
            "resources/OpenUIKit/fonts",
            "runtime-root/darwin/System/Library/Frameworks",
            "runtime-root/darwin/usr/lib/swift",
            "runtime-root/host",
            "sdk/System/Library/Frameworks",
            "sdk/usr/lib/swift",
            "sdk-provenance",
        ):
            (self.root / directory).mkdir(parents=True, exist_ok=True)

        for module in (
            "Darwin",
            "ObjectiveC",
            "_DarwinFoundation1",
            "_DarwinFoundation2",
            "_DarwinFoundation3",
        ):
            directory = self.root / f"apple-overlays/{module}.swiftmodule"
            directory.mkdir()
            (directory / f"{VARIANT}.swiftinterface").write_text(
                f"// {module}\n", encoding="utf-8"
            )
            (directory / f"{VARIANT}.swiftdoc").write_bytes(module.encode("utf-8"))

        for module in (
            "CHostClock",
            "COpenCombineHelpers",
            "COpenAccelerate",
            "COpenCompression",
            "COpenDispatch",
            "COpenFoundationCore",
            "COpenRelativeTime",
            "COpenURLTransport",
            "CPortableIO",
            "CQuartz",
            "CSTBTrueType",
            "_FoundationCShims",
        ):
            directory = self.root / f"platform-include/{module}"
            directory.mkdir()
            (directory / "module.modulemap").write_text(
                f"module {module} {{}}\n", encoding="utf-8"
            )
        (self.root / "platform-include/COpenFoundationCore/OpenFoundationCFError.h").write_text(
            "typedef struct __CFError *CFErrorRef;\n", encoding="utf-8"
        )
        (self.root / "platform-include/COpenAccelerate/Accelerate.h").write_text(
            "typedef long vImage_Error;\n", encoding="utf-8"
        )
        (self.root / "platform-include/COpenCompression/OpenCompressionABI.h").write_text(
            "typedef int compression_algorithm;\n", encoding="utf-8"
        )
        icu = self.root / "platform-include/FoundationICU/_foundation_unicode"
        icu.mkdir(parents=True)
        (icu / "module.modulemap").write_text(
            "module _FoundationICU {}\n", encoding="utf-8"
        )

        for relative in (
            "sdk/usr/lib/libSystem.B.tbd",
            "sdk/usr/lib/libobjc.A.tbd",
            "sdk/usr/lib/swift/libswiftCore.tbd",
            "sdk/usr/lib/swift/libswiftObjectiveC.tbd",
            "sdk/usr/lib/swift/libswift_Concurrency.tbd",
        ):
            path = self.root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(relative + "\n", encoding="utf-8")
        (self.root / "sdk/usr/lib/libSystem.tbd").symlink_to("libSystem.B.tbd")
        (self.root / "sdk/usr/lib/libobjc.tbd").symlink_to("libobjc.A.tbd")

        for module in MODULES:
            binary = macho(
                filetype=6, install_name=f"/usr/lib/lib{module}.dylib"
            )
            product = self.root / f"products/lib{module}.dylib"
            product.write_bytes(binary)
            sdk_framework = self.root / f"sdk/System/Library/Frameworks/{module}.framework"
            runtime_framework = (
                self.root
                / f"runtime-root/darwin/System/Library/Frameworks/{module}.framework"
            )
            for framework in (sdk_framework, runtime_framework):
                module_directory = framework / f"Modules/{module}.swiftmodule"
                module_directory.mkdir(parents=True)
                (framework / module).write_bytes(binary)
            runtime_library = self.root / f"runtime-root/darwin/usr/lib/lib{module}.dylib"
            runtime_library.parent.mkdir(parents=True, exist_ok=True)
            runtime_library.write_bytes(binary)
            for suffix in SUFFIXES:
                payload = f"{module}:{suffix}\n".encode("utf-8")
                (self.root / f"package/{module}.{suffix}").write_bytes(payload)
                for framework in (sdk_framework, runtime_framework):
                    (framework / f"Modules/{module}.swiftmodule/{VARIANT}.{suffix}").write_bytes(
                        payload
                    )

        authentication_services_overlay = (
            "cross-import-overlay: AuthenticationServices + SwiftUI\n"
        )
        overlay_relative = (
            "AuthenticationServices.framework/Modules/"
            "AuthenticationServices.swiftcrossimport/SwiftUI.swiftoverlay"
        )
        for relative in (
            "package/AuthenticationServices.swiftcrossimport/SwiftUI.swiftoverlay",
            f"sdk/System/Library/Frameworks/{overlay_relative}",
            f"runtime-root/darwin/System/Library/Frameworks/{overlay_relative}",
        ):
            path = self.root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(authentication_services_overlay, encoding="utf-8")

        for module in PRIVATE_DYLIBS:
            binary = macho(filetype=6, install_name=f"/usr/lib/lib{module}.dylib")
            (self.root / f"products/lib{module}.dylib").write_bytes(binary)
            (self.root / f"runtime-root/darwin/usr/lib/lib{module}.dylib").write_bytes(
                binary
            )

        observation_binary = macho(
            filetype=6,
            install_name="/usr/lib/swift/libswiftObservation.dylib",
        )
        (
            self.root
            / "runtime-root/darwin/usr/lib/swift/libswiftObservation.dylib"
        ).write_bytes(observation_binary)
        observation_directory = self.root / "sdk/usr/lib/swift/Observation.swiftmodule"
        observation_directory.mkdir(parents=True)
        for suffix in SUFFIXES:
            payload = f"Observation:{suffix}\n".encode("utf-8")
            (self.root / f"package/Observation.{suffix}").write_bytes(payload)
            (observation_directory / f"{VARIANT}.{suffix}").write_bytes(payload)

        for relative in (
            "runtime-root/darwin/usr/lib/libSystem.B.dylib",
            "runtime-root/darwin/usr/lib/libSystem.real.dylib",
            "runtime-root/darwin/usr/lib/libobjc.A.dylib",
            "runtime-root/darwin/usr/lib/libquartz.dylib",
            "runtime-root/darwin/usr/lib/libswiftcompat.dylib",
            "runtime-root/darwin/usr/lib/swift/libswiftCore.dylib",
            "runtime-root/darwin/usr/lib/swift/libswiftObjectiveC.dylib",
            "runtime-root/darwin/usr/lib/swift/libswift_Concurrency.dylib",
        ):
            path = self.root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(relative + "\n", encoding="utf-8")
        for library in (
            "libBlocksRuntime.so",
            "libOpenDispatchHost.so",
            "libOpenFoundationInternationalizationHost.so",
            "libOpenRelativeTimeHost.so",
            "libOpenURLTransportHost.so",
            "libOpenCompressionHost.so",
            "libdispatch.so",
        ):
            (self.root / f"runtime-root/host/{library}").write_text(
                library + "\n", encoding="utf-8"
            )

        plugin_modules = (
            "ObservationMacros",
            "FoundationMacros",
            "SwiftDataMacros",
            "OpenUIKitPreviewMacros",
            "OpenSwiftUIMacros",
        )
        plugin_records: list[str] = ["format\ttrue-ios-compiler-plugins-v1\n"]
        for module in plugin_modules:
            relative = f"host-tools/swift/host/plugins/lib{module}.so"
            plugin = self.root / relative
            plugin.write_bytes(elf64_aarch64(module))
            plugin_records.append(
                f"plugin\t{module}\t{relative}\t{sha256(plugin)}\n"
            )
        for library in (
            "libSwiftSyntaxMacros.so",
            "libSwiftSyntaxBuilder.so",
            "libSwiftParserDiagnostics.so",
            "libSwiftBasicFormat.so",
            "libSwiftParser.so",
            "libSwiftDiagnostics.so",
            "libSwiftSyntax.so",
        ):
            (self.root / f"host-tools/swift/host/{library}").write_bytes(
                elf64_aarch64(library)
            )
        for library in (
            "libswiftCore.so",
            "libswift_Concurrency.so",
            "libswiftGlibc.so",
            "libdispatch.so",
            "libswift_Builtin_float.so",
            "libBlocksRuntime.so",
            "libswiftSwiftOnoneSupport.so",
            "libswift_StringProcessing.so",
            "libswift_RegexParser.so",
        ):
            (self.root / f"host-tools/swift/linux/{library}").write_bytes(
                elf64_aarch64(library)
            )
        (self.root / "attestation/compiler-plugins.tsv").write_text(
            "".join(plugin_records), encoding="utf-8"
        )
        loader = self.root / "runtime-root/machorun"
        loader.write_text("loader\n", encoding="utf-8")
        loader.chmod(0o755)

        for relative in (
            "system_colors.json",
            "font_metrics.json",
            "text_decorations.json",
            "fonts/DejaVuSans.ttf",
            "fonts/DejaVuSans-Bold.ttf",
        ):
            (self.root / f"resources/OpenUIKit/{relative}").write_text(
                relative + "\n", encoding="utf-8"
            )

        probe = macho(
            filetype=2,
            loads=(
                "/usr/lib/libSwiftUI.dylib",
                "/usr/lib/libUIKit.dylib",
                "/usr/lib/libNaturalLanguage.dylib",
                "/usr/lib/libAuthenticationServices.dylib",
                "/usr/lib/lib_AuthenticationServices_SwiftUI.dylib",
                "/usr/lib/libAccelerate.dylib",
                "/usr/lib/libCompression.dylib",
                "/usr/lib/libCoreText.dylib",
            ),
        )
        (self.root / "true-ios-swiftui-dylib-probe").write_bytes(probe)

        (self.root / "sdk-provenance/SDK_COMPLETE").write_text(
            "TRUE_IOS_FULL_SDK_COMPLETE target=arm64-apple-ios18.0-simulator "
            "apple-overlays=darwin,objectivec\n",
            encoding="ascii",
        )
        sdk_input = "apple-overlays/Darwin.swiftmodule/arm64-apple-ios-simulator.swiftinterface"
        (self.root / "sdk-provenance/target-sdk-inputs.sha256").write_text(
            f"{sha256(self.root / sdk_input)}  {sdk_input}\n", encoding="ascii"
        )
        self.source_subject = "1" * 64
        (self.root / "attestation/source-subject.before.sha256").write_text(
            self.source_subject + "\n", encoding="ascii"
        )
        (self.root / "attestation/source-subject.after.sha256").write_text(
            self.source_subject + "\n", encoding="ascii"
        )
        (self.root / "attestation/runtime.log").write_text(
            "TRUE_IOS_SWIFTUI_DYLIB_RUNTIME_OK descendants=3 text=rendered button=rendered\n",
            encoding="utf-8",
        )
        module_log = "".join(
            f"loaded module '{module}'; source: '/stage/sdk/System/Library/Frameworks/"
            f"{module}.framework/Modules/{module}.swiftmodule/{VARIANT}.swiftmodule'\n"
            for module in (
                "SwiftUI",
                "UIKit",
                "OpenUIKit",
                "Combine",
                "OpenCombine",
                "NaturalLanguage",
                "AuthenticationServices",
                "_AuthenticationServices_SwiftUI",
                "Accelerate",
                "Compression",
                "CoreText",
            )
        )
        (self.root / "attestation/framework-module-loading.log").write_text(
            module_log, encoding="utf-8"
        )
        (self.root / "attestation/opencombine-sources.json").write_text(
            "{}\n", encoding="utf-8"
        )
        (self.root / "attestation/opencombine-sources.nul").write_bytes(b"source.swift\0")
        (
            self.root / "attestation/naturallanguage-authenticationservices-loads.tsv"
        ).write_text(
            "format\ttrue-ios-natural-auth-loads-v1\n"
            "probe\tnaturallanguage=1\tauthenticationservices=1\toverlay=1\n"
            "overlay\tbase=1\tswiftui=1\tapple-self-load=0\n",
            encoding="ascii",
        )
        (
            self.root / "attestation/accelerate-compression-coretext-loads.tsv"
        ).write_text(
            "format\ttrue-ios-accelerate-compression-coretext-loads-v1\n"
            "probe\taccelerate=1\tcompression=1\tcoretext=1\n"
            "accelerate\tvimage-export=1\tapple-self-load=0\n"
            "compression\tc-exports=2\thost-imports=2\tbrotli-load=0\tapple-self-load=0\n"
            "coretext\tapple-self-load=0\n",
            encoding="ascii",
        )
        (
            self.root / "attestation/accelerate-apple-differential.log"
        ).write_text(
            "edge-status=0\n"
            "edge-pixels=23,4,5,6,30,6,7,8,37,8,9,10,43,10,11,12,50,12,13,14,57,14,15,16,63,16,17,18,70,18,19,20,77,20,21,22\n"
            "alpha-status=0\n"
            "alpha-pixels=10,4,5,6,20,6,7,8,30,8,9,10,40,10,11,12,50,12,13,14,60,14,15,16,70,16,17,18,80,18,19,20,90,20,21,22\n"
            "errors=even:-21767,no-edge:-21768,roi:-21774\n",
            encoding="ascii",
        )
        (self.root / "attestation/compression-brotli-apple.txt").write_text(
            "algorithm=compression_algorithm(rawValue: 2818)\n"
            "encoded=iyaASWNlQ3ViZXMgdW50b3VjaGVkIFJldmVudWVDYXQgQnJvdGxpIHJlc3BvbnNlOiBwb3J0YWJsZSBNYWNoLU8gZ3Vlc3RzIG9uIExpbnV4Aw==\n"
            "decoded=IceCubes untouched RevenueCat Brotli response: portable Mach-O guests on Linux\n",
            encoding="ascii",
        )
        (self.root / "attestation/coretext-font-manager-apple.txt").write_text(
            "domain=com.apple.CoreText.CTFontManagerErrorDomain\n"
            "codes=already:105,duplicate:305\n"
            "first=true,domain:nil,code:nil\n"
            "repeat=false,domain:com.apple.CoreText.CTFontManagerErrorDomain,code:105\n"
            "duplicate=true,domain:nil,code:nil\n"
            "invalid=false,domain:com.apple.CoreText.CTFontManagerErrorDomain,code:103\n"
            "missing=false,domain:com.apple.CoreText.CTFontManagerErrorDomain,code:101\n",
            encoding="ascii",
        )
        (self.root / "attestation/open-compression-host-test.log").write_text(
            "OPEN_COMPRESSION_HOST_OK algorithm=brotli roundtrip=exact "
            "malformed=fail-closed limit=hard abi=v1\n",
            encoding="ascii",
        )
        (self.root / "attestation/open-compression-abi.tsv").write_text(
            "format\topen-compression-abi-v1\n"
            "response-layout\tsize=24\tpointers=64-bit\n"
            "symbol\topenui_compression_v1_transform\tguest-export=_openui_compression_v1_transform\tguest-host-import=_glibc_openui_compression_v1_transform\thost-export=openui_compression_v1_transform\n"
            "symbol\topenui_compression_v1_release\tguest-export=_openui_compression_v1_release\tguest-host-import=_glibc_openui_compression_v1_release\thost-export=openui_compression_v1_release\n",
            encoding="ascii",
        )
        (self.root / "attestation/open-compression-host.tsv").write_text(
            "format\topen-compression-host-v1\n"
            "host-abi\tELF64-AArch64\n"
            "algorithm\tbrotli\tencode=real\tdecode=real\n"
            "limits\tguest-input=256MiB\tguest-output=256MiB\n"
            "apple-transcript\tc3c7826b4bf603fcd4ec3f2ca9ae97906409789e352af48f926bf1acce6c9b65\n"
            "transitive-soname\tlibbrotlidec.so.1\n"
            "transitive-soname\tlibbrotlienc.so.1\n"
            "transitive-soname\tlibbrotlicommon.so.1\n",
            encoding="ascii",
        )
        for name in (
            "foundation-internationalization-abi.tsv",
            "foundation-internationalization-host.tsv",
            "foundation-internationalization-sources.tsv",
        ):
            (self.root / f"attestation/{name}").write_text(
                f"format\t{name}\n", encoding="utf-8"
            )
        (self.root / "attestation/foundation-runtime-exports.txt").write_text(
            "\n".join(
                sorted(
                    (
                        "_$s10Foundation24_getErrorDefaultUserInfoyyXlSgxs0C0RzlF",
                        "_$s10Foundation21_bridgeNSErrorToError_3outSbSo0C0C_SpyxGtAA021_ObjectiveCBridgeableE0RzlF",
                        "_$s10Foundation26_ObjectiveCBridgeableErrorMp",
                        "_$sSo10CFErrorRefas5Error10FoundationMc",
                    )
                )
            )
            + "\n",
            encoding="utf-8",
        )
        (self.root / "attestation/foundation-runtime-undefineds.txt").write_text(
            "_objc_msgSend\n", encoding="utf-8"
        )
        self.seal()

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def seal(self) -> None:
        for relative in (
            "PLATFORM_COMPLETE",
            "attestation/artifacts.sha256",
            "attestation/symlinks.tsv",
        ):
            path = self.root / relative
            if path.exists() or path.is_symlink():
                path.unlink()
        regular: list[Path] = []
        links: list[Path] = []
        for directory, directory_names, filenames in os.walk(self.root, followlinks=False):
            base = Path(directory)
            for name in list(directory_names):
                path = base / name
                if path.is_symlink():
                    links.append(path)
                    directory_names.remove(name)
            for name in filenames:
                path = base / name
                (links if path.is_symlink() else regular).append(path)
        artifact_ledger = self.root / "attestation/artifacts.sha256"
        artifact_ledger.write_text(
            "".join(
                f"{sha256(path)}\t{path.relative_to(self.root).as_posix()}\n"
                for path in sorted(regular)
            ),
            encoding="utf-8",
        )
        symlink_ledger = self.root / "attestation/symlinks.tsv"
        symlink_ledger.write_text(
            "".join(
                f"{hashlib.sha256(os.readlink(path).encode('utf-8')).hexdigest()}\t"
                f"{path.relative_to(self.root).as_posix()}\t{os.readlink(path)}\n"
                for path in sorted(links)
            ),
            encoding="utf-8",
        )
        (self.root / "PLATFORM_COMPLETE").write_text(
            "TRUE_IOS_PLATFORM_COMPLETE "
            "target=arm64-apple-ios18.0-simulator dylibs=20 swiftui_sources=11 "
            f"source={self.source_subject} artifacts={sha256(artifact_ledger)} "
            f"symlinks={sha256(symlink_ledger)}\n",
            encoding="ascii",
        )

    def test_valid_package_emits_relocatable_arguments(self) -> None:
        root, metadata = platform_package.validate(self.root)
        self.assertEqual(metadata["target"], "arm64-apple-ios18.0-simulator")
        self.assertEqual(metadata["modules"], list(MODULES))
        self.assertIn("sdk", metadata["swift_compile_arguments"])
        self.assertIn("-framework", metadata["executable_link_arguments"])
        self.assertEqual(
            metadata["swift_compile_arguments"].count("-enable-cross-import-overlays"),
            1,
        )
        self.assertNotIn(
            "-disable-implicit-string-processing-module-import",
            metadata["swift_compile_arguments"],
        )
        self.assertEqual(metadata["paths"]["resources"], "resources/OpenUIKit")
        rooted = platform_package.rooted_compile_arguments(
            root, metadata["swift_compile_arguments"]
        )
        self.assertIn(os.fspath(root / "sdk"), rooted)
        self.assertIn(
            f"-I{root / 'platform-include/CPortableIO'}",
            rooted,
        )
        self.assertIn(
            f"-fmodule-map-file={root / 'platform-include/COpenFoundationCore/module.modulemap'}",
            rooted,
        )
        for module in ("COpenAccelerate", "COpenCompression"):
            self.assertIn(
                f"-fmodule-map-file={root / f'platform-include/{module}/module.modulemap'}",
                rooted,
            )
        for framework in ("Accelerate", "Compression", "CoreText"):
            index = metadata["executable_link_arguments"].index(framework)
            self.assertEqual(metadata["executable_link_arguments"][index - 1], "-framework")

    def test_changed_artifact_is_rejected(self) -> None:
        (self.root / "products/libSwiftUI.dylib").write_bytes(b"changed")
        with self.assertRaisesRegex(platform_package.TrueIOSPlatformError, "artifact changed"):
            platform_package.validate(self.root)

    def test_unattested_stale_file_is_rejected(self) -> None:
        (self.root / "runtime-root/stale-object.o").write_bytes(b"stale")
        with self.assertRaisesRegex(platform_package.TrueIOSPlatformError, "coverage differs"):
            platform_package.validate(self.root)

    def test_cferror_clang_substrate_is_required(self) -> None:
        (
            self.root
            / "platform-include/COpenFoundationCore/OpenFoundationCFError.h"
        ).unlink()
        with self.assertRaisesRegex(
            platform_package.TrueIOSPlatformError,
            "artifact|CFError opaque header",
        ):
            platform_package.validate(self.root)

    def test_frontier_c_headers_are_required(self) -> None:
        for relative, label in (
            ("platform-include/COpenAccelerate/Accelerate.h", "Accelerate"),
            (
                "platform-include/COpenCompression/OpenCompressionABI.h",
                "Compression",
            ),
        ):
            with self.subTest(module=label):
                with tempfile.TemporaryDirectory(prefix="true-ios-frontier-header.") as temporary:
                    clone = Path(temporary) / "package"
                    import shutil

                    shutil.copytree(self.root, clone, symlinks=True)
                    (clone / relative).unlink()
                    with self.assertRaisesRegex(
                        platform_package.TrueIOSPlatformError,
                        "artifact|header",
                    ):
                        platform_package.validate(clone)

    def test_resealed_frontier_transcript_mutation_is_rejected(self) -> None:
        transcript = self.root / "attestation/compression-brotli-apple.txt"
        transcript.write_text("forged\n", encoding="ascii")
        self.seal()
        with self.assertRaisesRegex(
            platform_package.TrueIOSPlatformError,
            "frozen Apple transcript differs",
        ):
            platform_package.validate(self.root)

    def test_resealed_missing_cferror_error_conformance_is_rejected(self) -> None:
        exports = self.root / "attestation/foundation-runtime-exports.txt"
        exports.write_text(
            exports.read_text(encoding="utf-8").replace(
                "_$sSo10CFErrorRefas5Error10FoundationMc\n", ""
            ),
            encoding="utf-8",
        )
        self.seal()
        with self.assertRaisesRegex(
            platform_package.TrueIOSPlatformError,
            "Foundation runtime bridge exports are missing",
        ):
            platform_package.validate(self.root)

    def test_resealed_absent_cferror_c_api_import_is_rejected(self) -> None:
        undefineds = self.root / "attestation/foundation-runtime-undefineds.txt"
        undefineds.write_text(
            "_CFErrorGetDomain\n_objc_msgSend\n", encoding="utf-8"
        )
        self.seal()
        with self.assertRaisesRegex(
            platform_package.TrueIOSPlatformError,
            "Foundation CFError bridge imports absent C APIs",
        ):
            platform_package.validate(self.root)

    def test_resealed_non_ios_macho_is_rejected(self) -> None:
        product = self.root / "products/libSwiftUI.dylib"
        payload = bytearray(product.read_bytes())
        struct.pack_into("<I", payload, 40, 1)
        product.write_bytes(payload)
        for relative in (
            "sdk/System/Library/Frameworks/SwiftUI.framework/SwiftUI",
            "runtime-root/darwin/usr/lib/libSwiftUI.dylib",
            "runtime-root/darwin/System/Library/Frameworks/SwiftUI.framework/SwiftUI",
        ):
            (self.root / relative).write_bytes(payload)
        self.seal()
        with self.assertRaisesRegex(platform_package.TrueIOSPlatformError, "platform/minOS/SDK"):
            platform_package.validate(self.root)

    def test_resealed_framework_copy_divergence_is_rejected(self) -> None:
        framework = self.root / "sdk/System/Library/Frameworks/UIKit.framework/UIKit"
        framework.write_bytes(macho(filetype=6, install_name="/usr/lib/libUIKit.dylib") + b"x")
        self.seal()
        with self.assertRaisesRegex(platform_package.TrueIOSPlatformError, "published copies differ"):
            platform_package.validate(self.root)

    def test_symlink_escaping_the_package_is_rejected(self) -> None:
        product = self.root / "products/libCombine.dylib"
        product.unlink()
        product.symlink_to("../../outside")
        self.seal()
        with self.assertRaisesRegex(platform_package.TrueIOSPlatformError, "dangling or escaping"):
            platform_package.validate(self.root)


if __name__ == "__main__":
    unittest.main()
