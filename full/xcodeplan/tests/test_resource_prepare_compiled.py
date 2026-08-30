#!/usr/bin/env python3
"""Compile and run the real application host against a minimal UIKit fixture."""

from __future__ import annotations

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


HERE = Path(__file__).resolve().parent
XCODEPLAN = HERE.parent


CPORTABLE_IO = r"""
import Foundation

public func cpio_read_file(
    _ path: UnsafePointer<CChar>?,
    _ size: UnsafeMutablePointer<Int>?
) -> UnsafeMutableRawPointer? {
    guard let path,
          let data = FileManager.default.contents(atPath: String(cString: path)),
          !data.isEmpty else {
        size?.pointee = 0
        return nil
    }
    let bytes = UnsafeMutableRawPointer.allocate(byteCount: data.count, alignment: 1)
    data.copyBytes(to: bytes.assumingMemoryBound(to: UInt8.self), count: data.count)
    size?.pointee = data.count
    return bytes
}

public func cpio_free(_ bytes: UnsafeMutableRawPointer?) {
    bytes?.deallocate()
}

public func cpio_getenv(_ name: UnsafePointer<CChar>?) -> UnsafePointer<CChar>? {
    nil
}
"""


UIKIT = r"""
import Foundation

public struct Bundle {
    public static let main = Bundle()

    private init() {}

    public var resourcePath: String? {
        ProcessInfo.processInfo.environment["OPENUIKIT_RESOURCE_PROBE_ROOT"]
    }
}

public enum OpenUIKitRuntime {
    public static var resourceRoot = "unbound"
    public static var imageSearchPaths: [String] = []
    public static var imageScreenScale = 0
    public static var fontPaths: [String: String] = [:]
}

public struct UIFont {
    public static func systemFont(ofSize size: Double) -> UIFont { UIFont() }
}

public enum FontEngine {
    public private(set) static var loadCount = 0
    public private(set) static var loadedResourceRoot: String?
    private static var tableAdvance: Double?

    public static func advance(of scalar: Unicode.Scalar, font: UIFont) -> Double {
        if let tableAdvance { return tableAdvance }
        loadCount += 1
        loadedResourceRoot = OpenUIKitRuntime.resourceRoot
        let path = OpenUIKitRuntime.resourceRoot + "/font_metrics.json"
        let loaded = FileManager.default.contents(atPath: path)?.isEmpty == false
        let value = loaded ? 9.0 : 0.0
        tableAdvance = value
        return value
    }
}

public enum UIImage {
    public private(set) static var namedCacheClearCount = 0
    public static func clearNamedCache() { namedCacheClearCount += 1 }
}

public final class UIApplication {
    public func _hostWillTerminate() {}
}

public enum UISceneActivationState {
    case foregroundActive
}

public final class UIWindow {}

public final class UIWindowScene {
    public var activationState: UISceneActivationState = .foregroundActive
    public var windows: [UIWindow] = [UIWindow()]
    public var keyWindow: UIWindow? { windows.first }
}
"""


RUN_LOOP = r"""
import UIKit

struct MonotonicFrameSource {}

struct UIKitRunLoop {
    struct Result {
        let turns: Int
        let elapsed: Double
    }

    let frameInterval = 1.0 / 60.0

    init(window: UIWindow, source: MonotonicFrameSource) {}

    func run(timeout: Double, until shouldStop: () -> Bool) -> Result {
        Result(turns: shouldStop() ? 1 : 0, elapsed: frameInterval)
    }
}
"""


PROBE = r"""
import UIKit

@MainActor
private struct DelegateInitializerProbe {
    init(expectedRoot: String) {
        precondition(OpenUIKitRuntime.resourceRoot == expectedRoot)
        precondition(FontEngine.loadCount == 1)
        precondition(FontEngine.loadedResourceRoot == expectedRoot)
    }
}

@main
struct ResourcePrepareProbe {
    @MainActor
    static func main() {
        guard let resources = Bundle.main.resourcePath else {
            preconditionFailure("fixture resource root missing")
        }
        let expectedRoot = resources + "/OpenUIKit"

        PortableUIKitApplicationHost.prepare()
        _ = DelegateInitializerProbe(expectedRoot: expectedRoot)
        precondition(OpenUIKitRuntime.fontPaths["system"]?.hasSuffix("DejaVuSans.ttf") == true)
        precondition(UIImage.namedCacheClearCount == 1)

        PortableUIKitApplicationHost.prepare()
        precondition(FontEngine.loadCount == 1)
        precondition(FontEngine.loadedResourceRoot == expectedRoot)
        precondition(UIImage.namedCacheClearCount == 2)
        print("RESOURCE_PREPARE_COMPILED_OK root=packaged loads=1 prepares=2 delegate=after")
    }
}
"""


class CompiledResourcePrepareTests(unittest.TestCase):
    def test_real_host_prepares_packaged_tables_before_delegate_initialization(self) -> None:
        swiftc = shutil.which("swiftc")
        if swiftc is None:
            self.skipTest("swiftc is unavailable")

        with tempfile.TemporaryDirectory(prefix="portable-uikit-resource-probe-") as raw:
            root = Path(raw)
            modules = root / "modules"
            modules.mkdir()
            sources = root / "sources"
            sources.mkdir()
            resources = root / "resources" / "OpenUIKit"
            fonts = resources / "fonts"
            fonts.mkdir(parents=True)

            (resources / "system_colors.json").write_text("{}\n", encoding="utf-8")
            (resources / "font_metrics.json").write_text(
                '{"fixture":"packaged"}\n', encoding="utf-8"
            )
            (fonts / "DejaVuSans.ttf").write_bytes(b"regular-fixture")
            (fonts / "DejaVuSans-Bold.ttf").write_bytes(b"bold-fixture")

            cportable = sources / "CPortableIO.swift"
            uikit = sources / "UIKit.swift"
            run_loop = sources / "RunLoop.swift"
            probe = sources / "Probe.swift"
            cportable.write_text(CPORTABLE_IO, encoding="utf-8")
            uikit.write_text(UIKIT, encoding="utf-8")
            run_loop.write_text(RUN_LOOP, encoding="utf-8")
            probe.write_text(PROBE, encoding="utf-8")

            self._run(
                swiftc,
                "-parse-as-library",
                "-emit-module",
                "-emit-object",
                "-module-name",
                "CPortableIO",
                str(cportable),
                "-emit-module-path",
                str(modules / "CPortableIO.swiftmodule"),
                "-o",
                str(modules / "CPortableIO.o"),
            )
            self._run(
                swiftc,
                "-parse-as-library",
                "-emit-module",
                "-emit-object",
                "-module-name",
                "UIKit",
                str(uikit),
                "-emit-module-path",
                str(modules / "UIKit.swiftmodule"),
                "-o",
                str(modules / "UIKit.o"),
            )

            executable = root / "resource-prepare-probe"
            self._run(
                swiftc,
                "-parse-as-library",
                "-I",
                str(modules),
                str(XCODEPLAN / "PortableUIKitApplicationHost.swift"),
                str(run_loop),
                str(probe),
                str(modules / "CPortableIO.o"),
                str(modules / "UIKit.o"),
                "-o",
                str(executable),
            )

            environment = os.environ.copy()
            environment["OPENUIKIT_RESOURCE_PROBE_ROOT"] = str(resources.parent)
            result = subprocess.run(
                [str(executable)],
                check=True,
                capture_output=True,
                text=True,
                env=environment,
            )
            self.assertEqual(result.stderr, "")
            self.assertEqual(
                result.stdout,
                "RESOURCE_PREPARE_COMPILED_OK "
                "root=packaged loads=1 prepares=2 delegate=after\n",
            )

    def _run(self, *command: str) -> None:
        result = subprocess.run(command, capture_output=True, text=True)
        if result.returncode != 0:
            self.fail(
                "command failed:\n"
                + " ".join(command)
                + "\nstdout:\n"
                + result.stdout
                + "\nstderr:\n"
                + result.stderr
            )


if __name__ == "__main__":
    unittest.main()
