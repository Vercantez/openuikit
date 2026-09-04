// openrender CLI. Owner: rendercli module.
// Usage:
//   openrender render <outdir> <scene.json>...
// Mirrors Tools/oracle/main.swift (scene interpretation, layout dump format,
// exit codes, messages) but renders with OpenUIKit instead of real UIKit.

import Foundation
import OpenUIKit

@MainActor
func renderScene(file: String, outdir: String) throws {
    let scene = try loadSceneFile(file)
    let result = runScene(scene, warn: warnToStderr)
    try writeJSONFile(result.layout, path: "\(outdir)/\(result.name).layout.json")
    for (file, data) in result.pngs {
        try writeBinaryFile(data, path: "\(outdir)/\(file)")
    }
    if result.pngs.count == 1 {
        print("rendered \(result.name)")
    } else {
        print("rendered \(result.name) (\(result.pngs.count) frames)")
    }
}

// Backend override: OPENUIKIT_BACKEND=swift|quartz (default: library default).
if let v = ProcessInfo.processInfo.environment["OPENUIKIT_BACKEND"] {
    switch v {
    case "swift": OpenUIKitRuntime.renderBackend = .swift
    case "quartz": OpenUIKitRuntime.renderBackend = .quartz
    default:
        FileHandle.standardError.write(
            Data("warning: ignoring unknown OPENUIKIT_BACKEND=\(v) (use swift|quartz)\n".utf8))
    }
}

// Compositor override: OPENUIKIT_COMPOSITOR=layers|renderpass (default:
// library default; layers requires the quartz backend).
if ProcessInfo.processInfo.environment["OPENUIKIT_FORCE_IOS"] == "1" { forceIOSCut = true }
if ProcessInfo.processInfo.environment["OPENUIKIT_IOS_SNAP"] == "0" { OpenUIKitRuntime.disableIOSOriginSnap = true }
if let v = ProcessInfo.processInfo.environment["OPENUIKIT_COMPOSITOR"] {
    switch v {
    case "layers": OpenUIKitRuntime.compositor = .layers
    case "renderpass": OpenUIKitRuntime.compositor = .renderPass
    default:
        FileHandle.standardError.write(
            Data("warning: ignoring unknown OPENUIKIT_COMPOSITOR=\(v) (use layers|renderpass)\n".utf8))
    }
}
// Layer-contents caching kill switch (M8 perf; only reachable by repeated
// renders of one tree, e.g. animation frame captures): OPENUIKIT_LAYER_CACHE=off.
if let v = ProcessInfo.processInfo.environment["OPENUIKIT_LAYER_CACHE"] {
    switch v {
    case "off", "0": OpenUIKitRuntime.layerCaching = false
    case "on", "1": OpenUIKitRuntime.layerCaching = true
    default:
        FileHandle.standardError.write(
            Data("warning: ignoring unknown OPENUIKIT_LAYER_CACHE=\(v) (use on|off)\n".utf8))
    }
}

// Glyph-ink harvest diagnostics: OPENUIKIT_INK_LOG=<path> writes every ink
// table miss ("W|<key>" / "O|<key>", one per line) after rendering.
let inkLogPath = ProcessInfo.processInfo.environment["OPENUIKIT_INK_LOG"]
if inkLogPath != nil { GlyphInkTable.logMisses = true }

// Font directory override: OPENUIKIT_FONT_DIR=<dir>. The library's built-in
// search list points at macOS system paths; off Darwin there is no system SF
// to fall back to, so glyphs missing from the harvested ink table would not
// draw at all. Point this at a directory holding SFNS.ttf / SFNSMono.ttf /
// SFNSItalic.ttf (user-supplied — Apple's fonts are not redistributable) to
// get identical output on any platform.
if let dir = ProcessInfo.processInfo.environment["OPENUIKIT_FONT_DIR"] {
    let base = dir.hasSuffix("/") ? String(dir.dropLast()) : dir
    for (key, file) in [("system", "SFNS.ttf"), ("mono", "SFNSMono.ttf"),
                        ("italic", "SFNSItalic.ttf")] {
        let path = base + "/" + file
        if FileManager.default.isReadableFile(atPath: path) {
            OpenUIKitRuntime.fontPaths[key] = path
        }
    }
    if OpenUIKitRuntime.fontPaths.isEmpty {
        FileHandle.standardError.write(
            Data("warning: OPENUIKIT_FONT_DIR=\(dir) has no SFNS*.ttf\n".utf8))
    }
}

// Top-level code in `main.swift` is NOT main-actor isolated, but everything
// below it builds, lays out and renders UIKit objects, and those are
// `@MainActor` now -- exactly as they are in real UIKit. The tool is
// single-threaded and this IS the process's main thread, so state that once
// here and let the compiler check the rest, instead of hopping actors (which
// would need an async entry point) or disabling the check per site.
// `assumeIsolated` traps if the assumption is ever violated.
try MainActor.assumeIsolated {
    let args = CommandLine.arguments
    guard args.count >= 3 else {
        print("usage: openrender render <outdir> <scene.json>...")
        print("       openrender scrolltrace <oracle-trace.json> <out.json>")
        print("       openrender realapp <outdir> [assets-dir]")
        exit(1)
    }
    switch args[1] {
    case "scrolltrace":
        guard args.count == 4 else {
            print("usage: openrender scrolltrace <oracle-trace.json> <out.json>")
            exit(1)
        }
        do {
            try runScrollTrace(traceFile: args[2], outFile: args[3])
            exit(0)
        } catch {
            print("FAIL \(args[2]): \(error)")
            exit(1)
        }
    case "realapp":
        // The real-app harness (docs/REAL_APP_TEST.md): unmodified pocket-casts
        // source, rendered headlessly.
        let outdir = args[2]
        let assets = args.count >= 4 ? args[3] : "fixtures/realapp/assets"
        if let v = ProcessInfo.processInfo.environment["OPENUIKIT_REALAPP_SCALE"],
           let s = Double(v), s > 0 { realAppScale = CGFloat(s) }
        try FileManager.default.createDirectory(atPath: outdir, withIntermediateDirectories: true)
        for variant in realAppVariants {
            let result = runRealApp(variant, assets: assets)
            try writeJSONFile(result.layout, path: "\(outdir)/\(result.name).layout.json")
            for (file, data) in result.pngs {
                try writeBinaryFile(data, path: "\(outdir)/\(file)")
            }
            print("rendered \(result.name)")
        }
        if let inkLogPath {
            let lines = GlyphInkTable.missedKeys.sorted().joined(separator: "\n")
            try? (lines + "\n").write(toFile: inkLogPath, atomically: true, encoding: .utf8)
        }
        exit(0)
    case "render":
        let outdir = args[2]
        try FileManager.default.createDirectory(atPath: outdir, withIntermediateDirectories: true)
        var failures = 0
        for file in args.dropFirst(3) {
            do { try renderScene(file: file, outdir: outdir) }
            catch { print("FAIL \(file): \(error)"); failures += 1 }
        }
        if let inkLogPath {
            let lines = GlyphInkTable.missedKeys.sorted().joined(separator: "\n")
            try? (lines + "\n").write(toFile: inkLogPath, atomically: true, encoding: .utf8)
        }
        exit(failures == 0 ? 0 : 1)
    default:
        print("unknown command \(args[1])")
        exit(1)
    }

}