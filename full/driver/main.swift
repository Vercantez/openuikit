// main.swift -- Foundation-free driver for the full OpenUIKit module.
//
// This replaces ONLY Sources/openrender/{main,SceneIO}.swift, which are the
// two files in that target that use Foundation ("All Foundation use is
// isolated here", SceneIO.swift's own header). Sources/openrender/
// SceneBuilder.swift -- 76 KB, every scene type in the suite -- is compiled
// VERBATIM from ~/uikit alongside this file; it already declares that it must
// not import Foundation and consumes OpenUIKit's own `JSONValue`.
//
// The Foundation calls this file replaces, and what they became:
//   Data(contentsOf: URL(fileURLWithPath:))  -> ResourceIO.readFile   (CPortableIO)
//   Data(bytes).write(to:)                   -> cpio_write_file       (CPortableIO)
//   FileHandle.standardError.write           -> cpio_log_stderr       (CPortableIO)
//   ProcessInfo.processInfo.environment      -> cpio_getenv           (CPortableIO)
//   JSONSerialization                        -> JSONValue.parse       (OpenUIKit MiniJSON)
// Every replacement is a facility OpenUIKit already ships for exactly this
// reason; nothing here is a new dependency.
//
// layout.json IS written, by a small serialiser below, because
// Tools/compare/compare.py -- the project's own gate -- grades layout
// alongside pixels and a scene passes only if BOTH pass. Skipping it would
// have meant reporting a score the project does not recognise.

import CPortableIO
import OpenUIKit

func warnToStderr(_ message: String) { cpio_log_stderr(message) }

func loadSceneFile(_ path: String) -> JSONValue? {
    guard let bytes = ResourceIO.readFile(path) else {
        warnToStderr("cannot read \(path)")
        return nil
    }
    guard let value = JSONValue.parse(bytes), value.objectValue != nil else {
        warnToStderr("top-level JSON is not an object: \(path)")
        return nil
    }
    return value
}

func writeBinaryFile(_ bytes: [UInt8], path: String) -> Bool {
    bytes.withUnsafeBufferPointer { buf in
        cpio_write_file(path, buf.baseAddress, bytes.count) != 0
    }
}

// JSONValue -> text, replacing openrender's JSONSerialization call. Only the
// VALUES matter: Tools/compare/compare.py json.loads this file and compares
// numbers with a 0.5 pt tolerance, so formatting is free. Keys are sorted so
// two runs of the same scene produce identical bytes.
func jsonText(_ v: JSONValue) -> String {
    switch v {
    case .null: return "null"
    case .bool(let b): return b ? "true" : "false"
    case .number(let d):
        // Integral values print without a fractional part, as JSONSerialization
        // does; anything else gets full precision so no layout digit is lost.
        if d == d.rounded(), abs(d) < 1e15 { return String(Int64(d)) }
        return String(d)
    case .string(let s):
        var out = "\""
        for c in s.unicodeScalars {
            switch c {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            default:
                if c.value < 0x20 {
                    let hex = String(c.value, radix: 16)
                    out += "\\u" + String(repeating: "0", count: 4 - hex.count) + hex
                } else {
                    out.unicodeScalars.append(c)
                }
            }
        }
        return out + "\""
    case .array(let a): return "[" + a.map(jsonText).joined(separator: ",") + "]"
    case .object(let o):
        return "{" + o.keys.sorted().map { "\(jsonText(.string($0))):\(jsonText(o[$0]!))" }
            .joined(separator: ",") + "}"
    }
}

func writeJSONFile(_ v: JSONValue, path: String) -> Bool {
    writeBinaryFile(Array(jsonText(v).utf8), path: path)
}

// Backend / compositor overrides, same env vars and spellings as openrender.
func envString(_ name: String) -> String? {
    guard let c = cpio_getenv(name) else { return nil }
    return String(cString: c)
}
if let v = envString("OPENUIKIT_BACKEND") {
    switch v {
    case "swift": OpenUIKitRuntime.renderBackend = .swift
    case "quartz": OpenUIKitRuntime.renderBackend = .quartz
    default: warnToStderr("warning: ignoring unknown OPENUIKIT_BACKEND=\(v) (use swift|quartz)")
    }
}
if let v = envString("OPENUIKIT_COMPOSITOR") {
    switch v {
    case "layers": OpenUIKitRuntime.compositor = .layers
    case "renderpass": OpenUIKitRuntime.compositor = .renderPass
    default: warnToStderr("warning: ignoring unknown OPENUIKIT_COMPOSITOR=\(v) (use layers|renderpass)")
    }
}
if let v = envString("OPENUIKIT_RESOURCE_ROOT") { OpenUIKitRuntime.resourceRoot = v }

// Font directory override: OPENUIKIT_FONT_DIR=<dir>. Mirrors openrender's
// main.swift exactly, including the three file names and the empty-dir
// warning. The library's built-in search list points at macOS system paths;
// off Darwin there is no system SF to fall back to, so glyphs missing from the
// harvested ink table would not draw at all. Readability is tested by actually
// reading (ResourceIO) rather than FileManager.isReadableFile, which is
// Foundation.
if let dir = envString("OPENUIKIT_FONT_DIR") {
    let base = dir.hasSuffix("/") ? String(dir.dropLast()) : dir
    for (key, file) in [("system", "SFNS.ttf"), ("mono", "SFNSMono.ttf"),
                        ("italic", "SFNSItalic.ttf")] {
        let path = base + "/" + file
        if ResourceIO.readFile(path) != nil {
            OpenUIKitRuntime.fontPaths[key] = path
        }
    }
    if OpenUIKitRuntime.fontPaths.isEmpty {
        warnToStderr("warning: OPENUIKIT_FONT_DIR=\(dir) has no SFNS*.ttf")
    }
}

// argv: <outdir> <scene.json>...
// Each scene is rendered independently and a failure is reported and skipped,
// so one unsupported scene cannot hide the result of the other 107. A scene
// that CRASHES still takes the process down -- the runner drives one scene per
// process for exactly that reason, so a crash is attributable rather than fatal
// to the scoreboard.
//
// `runScene` is @MainActor (UIKit classes are, as in real UIKit). Top-level
// code in this file is not implicitly main-actor isolated, so the work is
// wrapped in assumeIsolated: this IS the main thread -- machorun calls the
// executable's entry point directly -- and the assertion documents that.
@MainActor
func renderAll(_ args: [String]) {
    let outdir = args[1]
    var rendered = 0
    var failed = 0
    for path in args[2...] {
        guard let scene = loadSceneFile(path) else { failed += 1; continue }
        let result = runScene(scene, warn: warnToStderr)
        var ok = writeJSONFile(result.layout, path: "\(outdir)/\(result.name).layout.json")
        if !ok { warnToStderr("cannot write \(outdir)/\(result.name).layout.json") }
        for (file, data) in result.pngs {
            if !writeBinaryFile(data, path: "\(outdir)/\(file)") {
                warnToStderr("cannot write \(outdir)/\(file)")
                ok = false
            }
        }
        if ok {
            rendered += 1
            print("rendered \(result.name)" + (result.pngs.count == 1 ? "" : " (\(result.pngs.count) frames)"))
        } else {
            failed += 1
        }
    }
    warnToStderr("[render_full] rendered=\(rendered) failed=\(failed)")
    cpio_exit(failed == 0 ? 0 : 1)
}

// `render_full realapp <outdir> [assets]` boots the APP lifecycle instead of a
// scene: UIScreen configured, UIWindow, rootViewController, makeKeyAndVisible,
// a modal presentation, and the animation clock run past the transition. That
// is ~/uikit's Sources/openrender/RealApp.swift, compiled verbatim.
@MainActor
func renderRealApp(_ outdir: String, assets: String) {
    var ok = 0, bad = 0
    for variant in realAppVariants {
        let result = runRealApp(variant, assets: assets)
        var good = writeJSONFile(result.layout, path: "\(outdir)/\(result.name).layout.json")
        for (file, data) in result.pngs {
            if !writeBinaryFile(data, path: "\(outdir)/\(file)") { good = false }
        }
        if good { ok += 1; print("rendered \(result.name)") } else { bad += 1 }
    }
    warnToStderr("[render_full] realapp rendered=\(ok) failed=\(bad)")
    cpio_exit(bad == 0 ? 0 : 1)
}

let args = CommandLine.arguments
if args.count >= 2, args[1] == "runloop" {
    warnToStderr("[render_full] run-loop self-test (wall clock vs synthetic clock)")
    let ok = MainActor.assumeIsolated { runLoopSelfTest() }
    warnToStderr(ok ? "[render_full] RUN LOOP OK" : "[render_full] RUN LOOP FAILED")
    cpio_exit(ok ? 0 : 1)
}
if args.count >= 2, args[1] == "launch" {
    warnToStderr("[render_full] launch-by-name self-test (delegate discovered from a string)")
    let ok = MainActor.assumeIsolated { launchByNameSelfTest() }
    warnToStderr(ok ? "[render_full] LAUNCH BY NAME OK" : "[render_full] LAUNCH BY NAME FAILED")
    cpio_exit(ok ? 0 : 1)
}
if args.count >= 3, args[1] == "realapp" {
    let assets = args.count >= 4 ? args[3] : "/uikit/fixtures/realapp/assets"
    MainActor.assumeIsolated { renderRealApp(args[2], assets: assets) }
}
if args.count < 3 {
    warnToStderr("usage: \(args.first ?? "render_full") <outdir> <scene.json>...")
    cpio_exit(2)
}
MainActor.assumeIsolated { renderAll(args) }
