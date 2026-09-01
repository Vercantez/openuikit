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
    "SwiftUI",
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
            "COpenDispatch",
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

        for module in PRIVATE_DYLIBS:
            binary = macho(filetype=6, install_name=f"/usr/lib/lib{module}.dylib")
            (self.root / f"products/lib{module}.dylib").write_bytes(binary)
            (self.root / f"runtime-root/darwin/usr/lib/lib{module}.dylib").write_bytes(
                binary
            )

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
            loads=("/usr/lib/libSwiftUI.dylib", "/usr/lib/libUIKit.dylib"),
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
            for module in ("SwiftUI", "UIKit", "OpenUIKit", "Combine", "OpenCombine")
        )
        (self.root / "attestation/framework-module-loading.log").write_text(
            module_log, encoding="utf-8"
        )
        (self.root / "attestation/opencombine-sources.json").write_text(
            "{}\n", encoding="utf-8"
        )
        (self.root / "attestation/opencombine-sources.nul").write_bytes(b"source.swift\0")
        for name in (
            "foundation-internationalization-abi.tsv",
            "foundation-internationalization-host.tsv",
            "foundation-internationalization-sources.tsv",
        ):
            (self.root / f"attestation/{name}").write_text(
                f"format\t{name}\n", encoding="utf-8"
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
            "target=arm64-apple-ios18.0-simulator dylibs=12 swiftui_sources=11 "
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
        self.assertEqual(metadata["paths"]["resources"], "resources/OpenUIKit")
        rooted = platform_package.rooted_compile_arguments(
            root, metadata["swift_compile_arguments"]
        )
        self.assertIn(os.fspath(root / "sdk"), rooted)
        self.assertIn(
            f"-I{root / 'platform-include/CPortableIO'}",
            rooted,
        )

    def test_changed_artifact_is_rejected(self) -> None:
        (self.root / "products/libSwiftUI.dylib").write_bytes(b"changed")
        with self.assertRaisesRegex(platform_package.TrueIOSPlatformError, "artifact changed"):
            platform_package.validate(self.root)

    def test_unattested_stale_file_is_rejected(self) -> None:
        (self.root / "runtime-root/stale-object.o").write_bytes(b"stale")
        with self.assertRaisesRegex(platform_package.TrueIOSPlatformError, "coverage differs"):
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
