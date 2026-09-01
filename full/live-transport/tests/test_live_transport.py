from __future__ import annotations

import os
import hashlib
import json
from pathlib import Path
import platform
import shutil
import subprocess
import tempfile
import textwrap
import unittest


HERE = Path(__file__).resolve().parent
LIVE = HERE.parent
FULL = LIVE.parent
XCODEPLAN = FULL / "xcodeplan"
PROOF_APP = LIVE / "proof-app"


UIKIT_FIXTURE = r"""
@_exported import Foundation

public enum OpenUIKitRuntime {
    @MainActor
    public static func configureApplicationBundleResources(at path: String) {}
}

public final class Bitmap {
    public let width: Int
    public let height: Int
    public var pixels: [UInt8]
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.pixels = [UInt8](repeating: 0, count: width * height * 4)
    }
}

public enum UIKeyEventKey {
    case backspace, left, right, up, down, `return`
}

public final class UITouch {
    public enum Phase { case began, moved, ended, cancelled }
}

@MainActor
public final class UIWindow {
    public func layoutIfNeeded() {}
    public func tick(timestamp: Double) {}
    public func sendTouch(
        _ phase: UITouch.Phase,
        at point: CGPoint,
        timestamp: Double,
        touchID: Int = 0
    ) {}
    public func sendText(_ text: String, timestamp: Double = 0) {}
    public func sendKey(_ key: UIKeyEventKey, timestamp: Double = 0) {}
}

@MainActor
public enum UIRenderer {
    public static func render(_ root: UIWindow, scale: CGFloat) -> Bitmap {
        Bitmap(width: 390, height: 844)
    }
}

public enum UISceneActivationState { case foregroundActive }

@MainActor
public final class UIWindowScene {
    public var activationState: UISceneActivationState = .foregroundActive
    public var windows: [UIWindow] = [UIWindow()]
    public var keyWindow: UIWindow? { windows.first }
}

@MainActor
public final class UIApplication {
    public func _hostWillTerminate() {}
}
"""


RUN_LOOP_FIXTURE = r"""
import UIKit

protocol HostFrameSource {
    func now() -> Double
    func wait(until deadline: Double)
}

struct MonotonicFrameSource: HostFrameSource {
    func now() -> Double { 0 }
    func wait(until deadline: Double) {}
}

@MainActor
struct UIKitFrameDriver {
    let window: UIWindow
    var frameInterval: Double = 1.0 / 60.0
    func tick(at timestamp: Double) { window.tick(timestamp: timestamp) }
    func nextDeadline(after timestamp: Double) -> Double { timestamp + frameInterval }
}

@MainActor
struct UIKitRunLoop {
    let window: UIWindow
    let source: HostFrameSource
    var frameInterval: Double = 1.0 / 60.0
    func run(
        timeout: Double,
        until predicate: () -> Bool
    ) -> (elapsed: Double, turns: Int) {
        _ = predicate()
        return (frameInterval, 1)
    }
}
"""


class LiveTransportTests(unittest.TestCase):
    def run_checked(self, *command: str, env: dict[str, str] | None = None) -> str:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            env=env,
        )
        if result.returncode:
            self.fail(
                "command failed:\n"
                + " ".join(command)
                + "\nstdout:\n"
                + result.stdout
                + "\nstderr:\n"
                + result.stderr
            )
        return result.stdout

    def test_protocol_layout_and_bidirectional_core(self) -> None:
        compiler = shutil.which("clang")
        if not compiler:
            self.skipTest("clang is unavailable")
        with tempfile.TemporaryDirectory(prefix="openui-live-c-test-") as raw:
            executable = Path(raw) / "transport-tests"
            self.run_checked(
                compiler,
                "-std=c11",
                "-Wall",
                "-Wextra",
                "-Werror",
                "-I",
                str(LIVE / "include"),
                "-I",
                str(LIVE),
                str(LIVE / "OpenUIKitLiveTransportCommon.c"),
                str(LIVE / "OpenUIKitLiveTransportGuest.c"),
                str(LIVE / "OpenUIKitLiveTransportHost.c"),
                str(HERE / "OpenUIKitLiveTransportTests.c"),
                "-o",
                str(executable),
            )
            output = self.run_checked(str(executable))
            self.assertEqual(
                output,
                "OPENUIKIT_LIVE_TRANSPORT_TEST_OK "
                "frames=2000 inputs=3 drops=1 torn=0\n",
            )

    def test_bidirectional_core_is_sanitizer_clean(self) -> None:
        compiler = shutil.which("clang")
        if not compiler:
            self.skipTest("clang is unavailable")
        sources = (
            LIVE / "OpenUIKitLiveTransportCommon.c",
            LIVE / "OpenUIKitLiveTransportGuest.c",
            LIVE / "OpenUIKitLiveTransportHost.c",
            HERE / "OpenUIKitLiveTransportTests.c",
        )
        with tempfile.TemporaryDirectory(prefix="openui-live-sanitizer-") as raw:
            root = Path(raw)
            executed = 0
            sanitizers = [("undefined", "undefined")]
            # Apple's sanitizer runtimes shipped with macOS 26 currently
            # crash during TSan process initialization (before main).  The
            # production Linux gate still runs the race detector.
            if platform.system() == "Linux":
                sanitizers.append(("thread", "thread"))
            for label, sanitizer in sanitizers:
                executable = root / f"transport-{label}"
                probe = subprocess.run(
                    [
                        compiler,
                        "-std=c11",
                        f"-fsanitize={sanitizer}",
                        "-x",
                        "c",
                        "-",
                        "-o",
                        str(root / f"probe-{label}"),
                    ],
                    input="int main(void) { return 0; }\n",
                    capture_output=True,
                    text=True,
                )
                if probe.returncode:
                    continue
                executed += 1
                self.run_checked(
                    compiler,
                    "-std=c11",
                    "-Wall",
                    "-Wextra",
                    "-Werror",
                    "-g",
                    f"-fsanitize={sanitizer}",
                    "-DSTRESS_FINAL_SEQUENCE=300",
                    "-DSTRESS_MAX_SNAPSHOTS=5000",
                    "-I",
                    str(LIVE / "include"),
                    "-I",
                    str(LIVE),
                    *(str(source) for source in sources),
                    "-o",
                    str(executable),
                )
                environment = os.environ.copy()
                environment["ASAN_OPTIONS"] = "halt_on_error=1"
                environment["UBSAN_OPTIONS"] = "halt_on_error=1"
                environment["TSAN_OPTIONS"] = "halt_on_error=1"
                self.run_checked(str(executable), env=environment)
            self.assertGreater(executed, 0, "clang provides no requested sanitizer runtime")

    def test_sdl_host_builds_against_native_sdl2(self) -> None:
        compiler = shutil.which("clang")
        pkg_config = shutil.which("pkg-config")
        if not compiler or not pkg_config:
            self.skipTest("native clang/pkg-config is unavailable")
        flags = subprocess.run(
            [pkg_config, "--cflags", "--libs", "sdl2"],
            capture_output=True,
            text=True,
        )
        if flags.returncode:
            self.skipTest("SDL2 development package is unavailable")
        with tempfile.TemporaryDirectory(prefix="openui-live-sdl-build-") as raw:
            executable = Path(raw) / "openui-live-sdl-host"
            self.run_checked(
                compiler,
                "-std=c11",
                "-Wall",
                "-Wextra",
                "-Werror",
                "-I",
                str(LIVE / "include"),
                "-I",
                str(LIVE),
                str(LIVE / "OpenUIKitLiveTransportCommon.c"),
                str(LIVE / "OpenUIKitLiveTransportHost.c"),
                str(LIVE / "OpenUIKitLiveSDLHost.c"),
                *flags.stdout.split(),
                "-o",
                str(executable),
            )
            self.assertTrue(executable.is_file())

    def test_guest_c_compiles_for_the_real_ios_18_5_abi(self) -> None:
        if platform.system() != "Darwin" or not shutil.which("xcrun"):
            self.skipTest("Apple simulator compiler is unavailable")
        sdk = self.run_checked(
            "xcrun", "--sdk", "iphonesimulator", "--show-sdk-path"
        ).strip()
        with tempfile.TemporaryDirectory(prefix="openui-live-ios-c-") as raw:
            objects = []
            for source in (
                "OpenUIKitLiveTransportCommon.c",
                "OpenUIKitLiveTransportGuest.c",
            ):
                destination = Path(raw) / f"{source}.o"
                self.run_checked(
                    "xcrun",
                    "--sdk",
                    "iphonesimulator",
                    "clang",
                    "-target",
                    "arm64-apple-ios18.5-simulator",
                    "-isysroot",
                    sdk,
                    "-std=c11",
                    "-Wall",
                    "-Wextra",
                    "-Werror",
                    "-fvisibility=hidden",
                    "-I",
                    str(LIVE / "include"),
                    "-I",
                    str(LIVE),
                    "-c",
                    str(LIVE / source),
                    "-o",
                    str(destination),
                )
                self.assertTrue(destination.is_file())
                objects.append(destination)
            undefined = self.run_checked(
                "xcrun", "nm", "-u", *(str(path) for path in objects)
            )
            self.assertNotIn(
                "___atomic_", undefined,
                "the ARM64 transport unexpectedly imports a libatomic helper",
            )

    def test_real_swift_host_and_transport_typecheck_together(self) -> None:
        swiftc = shutil.which("swiftc")
        if not swiftc:
            self.skipTest("swiftc is unavailable")
        with tempfile.TemporaryDirectory(prefix="openui-live-swift-") as raw:
            root = Path(raw)
            modules = root / "modules"
            modules.mkdir()
            uikit = root / "UIKit.swift"
            uikit.write_text(textwrap.dedent(UIKIT_FIXTURE), encoding="utf-8")
            self.run_checked(
                swiftc,
                "-parse-as-library",
                "-emit-module",
                "-module-name",
                "UIKit",
                str(uikit),
                "-emit-module-path",
                str(modules / "UIKit.swiftmodule"),
            )

            cportable = root / "CPortableIO"
            cportable.mkdir()
            (cportable / "cportableio.h").write_text(
                "const char *cpio_getenv(const char *name);\n",
                encoding="utf-8",
            )
            (cportable / "module.modulemap").write_text(
                'module CPortableIO { header "cportableio.h" export * }\n',
                encoding="utf-8",
            )
            run_loop = root / "RunLoop.swift"
            run_loop.write_text(textwrap.dedent(RUN_LOOP_FIXTURE), encoding="utf-8")
            self.run_checked(
                swiftc,
                "-typecheck",
                "-I",
                str(modules),
                "-Xcc",
                f"-fmodule-map-file={LIVE / 'include/module.modulemap'}",
                "-Xcc",
                f"-I{LIVE / 'include'}",
                "-Xcc",
                f"-fmodule-map-file={cportable / 'module.modulemap'}",
                "-Xcc",
                f"-I{cportable}",
                str(XCODEPLAN / "PortableUIKitLiveTransport.swift"),
                str(XCODEPLAN / "PortableUIKitApplicationHost.swift"),
                str(run_loop),
            )

    def test_headless_route_is_explicitly_opt_in_and_build_wired(self) -> None:
        host = (XCODEPLAN / "PortableUIKitApplicationHost.swift").read_text(
            encoding="utf-8"
        )
        transport = (XCODEPLAN / "PortableUIKitLiveTransport.swift").read_text(
            encoding="utf-8"
        )
        build = (XCODEPLAN / "build_portable_application_guest.sh").read_text(
            encoding="utf-8"
        )
        self.assertEqual(transport.count('cpio_getenv("OPENUIKIT_LIVE_TRANSPORT")'), 1)
        self.assertIn("guard let rawPath", transport)
        self.assertIn("return nil", transport)
        self.assertIn("if let liveTransport", host)
        headless = host.index("let runLoop = UIKitRunLoop")
        opt_in = host.index("if let liveTransport")
        self.assertLess(opt_in, headless)
        self.assertIn("PortableUIKitLiveTransport.swift", build)
        self.assertIn("OpenUIKitLiveTransportCommon.c", build)
        self.assertIn("OpenUIKitLiveTransportGuest.c", build)
        self.assertIn('extra_objects+=("${live_transport_objects[@]}")', build)
        self.assertIn("live-transport-objects.tsv", build)

    def test_proof_app_is_a_canonical_unchanged_xcode_target(self) -> None:
        before = {
            path.relative_to(PROOF_APP).as_posix(): hashlib.sha256(
                path.read_bytes()
            ).hexdigest()
            for path in sorted(PROOF_APP.rglob("*"))
            if path.is_file()
        }
        with tempfile.TemporaryDirectory(prefix="openui-live-proof-plan-") as raw:
            root = Path(raw)
            inventory = root / "inventory.json"
            plan = root / "plan"
            self.run_checked(
                "python3",
                "-B",
                str(XCODEPLAN / "project_inventory.py"),
                str(PROOF_APP / "LiveTransportProof.xcodeproj"),
                "--scheme",
                "LiveTransportProof",
                "--output",
                str(inventory),
            )
            self.run_checked(
                "python3",
                "-B",
                str(XCODEPLAN / "application_build_plan.py"),
                str(inventory),
                "--source-root",
                str(PROOF_APP),
                "--output-dir",
                str(plan),
                "--require-canonical-project-inventory",
            )
            frozen = json.loads(inventory.read_text(encoding="utf-8"))
            self.assertEqual(
                [entry["path"] for entry in frozen["sources"]],
                [
                    "App/AppDelegate.swift",
                    "App/LiveTransportProofViewController.swift",
                    "App/SceneDelegate.swift",
                ],
            )
            self.assertEqual(
                frozen["configuration"]["target"]["build_settings"]
                ["IPHONEOS_DEPLOYMENT_TARGET"],
                "18.5",
            )
            generated = (plan / "GeneratedSceneBootstrap.swift").read_text(
                encoding="utf-8"
            )
            self.assertIn("PortableUIKitApplicationHost.prepare()", generated)
            self.assertIn("SceneDelegate()", generated)
            self.run_checked(
                "python3",
                "-B",
                str(XCODEPLAN / "application_build_plan.py"),
                str(plan / "application-build-plan.json"),
                "--source-root",
                str(PROOF_APP),
                "--verify",
            )
        after = {
            path.relative_to(PROOF_APP).as_posix(): hashlib.sha256(
                path.read_bytes()
            ).hexdigest()
            for path in sorted(PROOF_APP.rglob("*"))
            if path.is_file()
        }
        self.assertEqual(after, before)

    def test_proof_app_typechecks_unchanged_against_apple_uikit(self) -> None:
        if platform.system() != "Darwin" or not shutil.which("xcrun"):
            self.skipTest("Apple UIKit compiler oracle is unavailable")
        sdk = self.run_checked(
            "xcrun", "--sdk", "iphonesimulator", "--show-sdk-path"
        ).strip()
        self.run_checked(
            "xcrun",
            "--sdk",
            "iphonesimulator",
            "swiftc",
            "-target",
            "arm64-apple-ios18.5-simulator",
            "-sdk",
            sdk,
            "-typecheck",
            str(PROOF_APP / "App/AppDelegate.swift"),
            str(PROOF_APP / "App/LiveTransportProofViewController.swift"),
            str(PROOF_APP / "App/SceneDelegate.swift"),
        )

    def test_runtime_harness_is_source_pinned_read_only_and_localhost_only(self) -> None:
        harness_path = LIVE / "live_runtime_harness.sh"
        entrypoint_path = LIVE / "container_entrypoint.sh"
        for script in (
            harness_path,
            entrypoint_path,
            LIVE / "build_linux_sdl_host.sh",
        ):
            self.run_checked("bash", "-n", str(script))
        harness = harness_path.read_text(encoding="utf-8")
        entrypoint = entrypoint_path.read_text(encoding="utf-8")
        dockerfile = (LIVE / "Dockerfile").read_text(encoding="utf-8")
        self.assertIn('git -C "$source_repo" archive', harness)
        self.assertIn('actual_tree=$(git -C "$source_repo"', harness)
        self.assertIn("--no-cache", harness)
        self.assertIn('-p "127.0.0.1:${port}:6080"', harness)
        self.assertIn('-v "$guest_root:/guest-root:ro"', harness)
        self.assertIn('-v "$application_output:/application:ro"', harness)
        self.assertNotIn('$source_repo:/', harness)
        self.assertIn('OPENUIKIT_LIVE_TRANSPORT="$transport"', entrypoint)
        self.assertIn("xdotool mousemove --window", entrypoint)
        self.assertIn("'Linux UIKit'", entrypoint)
        self.assertIn("initial_pixel_sha256", entrypoint)
        self.assertIn("clicked_pixel_sha256", entrypoint)
        self.assertIn("typed_pixel_sha256", entrypoint)
        self.assertIn("COPY full/live-transport", dockerfile)
        self.assertIn('org.opencontainers.image.revision="${SUPPORT_COMMIT}"', dockerfile)


if __name__ == "__main__":
    unittest.main()
