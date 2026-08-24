// openrender CLI. Owner: rendercli module.
// Usage:
//   openrender render <outdir> <scene.json>...
// Mirrors Tools/oracle/main.swift (scene interpretation, layout dump format,
// exit codes, messages) but renders with OpenUIKit instead of real UIKit.

import Foundation
import OpenUIKit

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
if let v = ProcessInfo.processInfo.environment["OPENUIKIT_COMPOSITOR"] {
    switch v {
    case "layers": OpenUIKitRuntime.compositor = .layers
    case "renderpass": OpenUIKitRuntime.compositor = .renderPass
    default:
        FileHandle.standardError.write(
            Data("warning: ignoring unknown OPENUIKIT_COMPOSITOR=\(v) (use layers|renderpass)\n".utf8))
    }
}

// Glyph-ink harvest diagnostics: OPENUIKIT_INK_LOG=<path> writes every ink
// table miss ("W|<key>" / "O|<key>", one per line) after rendering.
let inkLogPath = ProcessInfo.processInfo.environment["OPENUIKIT_INK_LOG"]
if inkLogPath != nil { GlyphInkTable.logMisses = true }

let args = CommandLine.arguments
guard args.count >= 3 else {
    print("usage: openrender render <outdir> <scene.json>...")
    exit(1)
}
switch args[1] {
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
