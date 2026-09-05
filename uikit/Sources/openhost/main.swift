// openhost CLI — SDL2 live host for OpenUIKit scenes. Owner: host module (M7).
//
// Usage:
//   openhost <scene.json> [--scale N]
//       Open an SDL window on the scene and run the real-time loop:
//       SDL_GetTicks drives OpenUIKitRuntime.animationTime (t = 0 at
//       start), mouse events are forwarded as touches (controls react
//       live), control actions log to stdout. Quit: close window / Cmd-Q /
//       Escape.
//   openhost <scene.json> [--scale N] --script events.json --record outdir
//       Deterministic-clock scripted mode: drive {t, kind: down|move|up,
//       x, y} events and capture PNG frames at the script's "captures"
//       times into outdir, then exit (the window still opens; frames are
//       identical run-to-run).
//
// Environment: OPENUIKIT_BACKEND / OPENUIKIT_COMPOSITOR / OPENUIKIT_FONT_DIR
// (same as openrender). Run from the repo root (OpenUIKit resources are found
// via the default relative resourceRoot) — scripts/host.sh does this for you.
//
// Sharing: SceneBuilder.swift and SceneIO.swift are symlinks to
// ../openrender/ — one scene-building implementation for both executables.

import Foundation
import OpenUIKit
import ConformanceApps

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
if let v = ProcessInfo.processInfo.environment["OPENUIKIT_COMPOSITOR"] {
    switch v {
    case "layers": OpenUIKitRuntime.compositor = .layers
    case "renderpass": OpenUIKitRuntime.compositor = .renderPass
    default:
        FileHandle.standardError.write(
            Data("warning: ignoring unknown OPENUIKIT_COMPOSITOR=\(v) (use layers|renderpass)\n".utf8))
    }
}
// Layer-contents caching kill switch (M8 perf): OPENUIKIT_LAYER_CACHE=off
// renders every frame from scratch (A/B comparison, cache debugging).
if let v = ProcessInfo.processInfo.environment["OPENUIKIT_LAYER_CACHE"] {
    switch v {
    case "off", "0": OpenUIKitRuntime.layerCaching = false
    case "on", "1": OpenUIKitRuntime.layerCaching = true
    default:
        FileHandle.standardError.write(
            Data("warning: ignoring unknown OPENUIKIT_LAYER_CACHE=\(v) (use on|off)\n".utf8))
    }
}
// Font directory override: OPENUIKIT_FONT_DIR=<dir>. Same contract as
// openrender's (see its main.swift): the library's built-in search list points
// at macOS system paths, so off Darwin glyphs missing from the harvested ink
// table would not draw at all. openhost needs this too now that it builds and
// runs on Linux (scripts/linux_selector_verify.sh).
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

let usage = """
usage: openhost <scene.json> [--scale N] [--script events.json --record outdir]
       openhost --app <name> [--scale N] [--ipad] [--script events.json --record outdir]
       openhost --nav-demo   [--scale N] [--script events.json --record outdir]

--app boots one of the DemoApp apps in a live window (see AppMode.swift):
  demo      the Settings app (docs/APP_FEEL.md)
  tasks     the Tasks todo app (UITableView, M10)
  textdemo  the text-input form (UITextField/UITextView, M8)
  showcase  all three in a UITabBarController — large titles, table,
            modal profile sheet (M10)
  selectors target-action demo wired entirely with addTarget(_:action:for:)
            and UITapGestureRecognizer(target:action:) — no closures
            (docs/OBJC_RUNTIME.md). Script: scripts/selector_interaction.json
  pocketcasts a REAL app screen — UNMODIFIED source from
            Automattic/pocket-casts-ios (the options-picker sheet), compiled
            against OpenUIKit (docs/REAL_APP_TEST.md)
\(ConformanceApps.usageLines)
"""

var scenePath: String? = nil
var scaleOverride: Double? = nil
var scriptPath: String? = nil
var recordDir: String? = nil
var navDemo = false
var navLargeTitles = false
if ProcessInfo.processInfo.environment["OPENUIKIT_FORCE_IOS"] == "1" { forceIOSCut = true }
if ProcessInfo.processInfo.environment["OPENUIKIT_CONFORMANCE_IPAD"] == "1" {
    conformancePadIdiom = true
}
var appName: String? = nil

var it = CommandLine.arguments.dropFirst().makeIterator()
while let arg = it.next() {
    switch arg {
    case "--app":
        guard let v = it.next() else { print(usage); exit(1) }
        appName = v
    case "--ipad":
        // Pad idiom + 820×1180 window + measured iPad (A16) safe area.
        // Phone `--app` (no flag) is unchanged. Same surface as
        // realapp_settings_light_ipad / history / storage.
        conformancePadIdiom = true
    case "--nav-demo":
        navDemo = true
    case "--large-titles":
        navLargeTitles = true
    case "--scale":
        guard let v = it.next(), let s = Double(v), s > 0 else {
            print(usage); exit(1)
        }
        scaleOverride = s
    case "--script":
        guard let v = it.next() else { print(usage); exit(1) }
        scriptPath = v
    case "--record":
        guard let v = it.next() else { print(usage); exit(1) }
        recordDir = v
    case "-h", "--help":
        print(usage); exit(0)
    default:
        guard scenePath == nil else { print(usage); exit(1) }
        scenePath = arg
    }
}

let modeCount = (scenePath != nil ? 1 : 0) + (navDemo ? 1 : 0)
    + (appName != nil ? 1 : 0)
guard modeCount == 1 else { print(usage); exit(1) }
guard (scriptPath == nil) == (recordDir == nil) else {
    print("--script and --record must be used together\n\(usage)"); exit(1)
}

// Top-level code in `main.swift` is NOT main-actor isolated, but everything
// below it builds, lays out and renders UIKit objects, and those are
// `@MainActor` now -- exactly as they are in real UIKit. The tool is
// single-threaded and this IS the process's main thread, so state that once
// here and let the compiler check the rest, instead of hopping actors (which
// would need an async entry point) or disabling the check per site.
// `assumeIsolated` traps if the assumption is ever violated.
try MainActor.assumeIsolated {
    // CONFORMANCE APPS (docs/HILLCLIMB.md): `--app <name> --script <script>
    // --record <dir>` where <name> is a Sources/ConformanceApps app replays
    // the script's NAMED ACTIONS and records the files
    // Tools/oracle2/confprobe records from real UIKit. The oracle is the iOS
    // simulator, so the iOS cut is on unconditionally here — there is no
    // Catalyst reading of a conformance app to preserve.
    if let appName, let script = scriptPath, let record = recordDir,
       ConformanceApps.isRegistered(appName) {
        OpenUIKitRuntime.systemFontCut = .iOS
        let scale = scaleOverride.map { CGFloat($0) } ?? appModeDefaultScale
        let parsed = parseConformanceScript(try loadSceneFile(script))
        // OPENUIKIT_APP_STYLE (set by conformance_flow.sh --dark) wins over
        // the script field so a light script.json can still drive a dark
        // timeline. Probe honours CONFPROBE_STYLE the same way.
        let style = ConformanceClock.resolvedStyle(
            script: parsed.style,
            environment: ProcessInfo.processInfo.environment["OPENUIKIT_APP_STYLE"])
        let uiStyle: UIUserInterfaceStyle = style == "dark" ? .dark : .light
        let scene = buildAppScene(appName, scaleOverride: scale, style: uiStyle)
        try FileManager.default.createDirectory(atPath: record,
                                                withIntermediateDirectories: true)
        let written = try runConformanceScripted(scene, app: appName, steps: parsed.steps,
                                                 captures: parsed.captures, style: style,
                                                 outdir: record)
        print("recorded \(written.count) captures to \(record) style=\(style)")
        exit(0)
    }

    let scene: HostScene
    if let appName {
        // --app mode has no in-app appearance switch; OPENUIKIT_APP_STYLE=dark
        // boots it in dark mode so semantic-color coverage can be captured.
        var style: UIUserInterfaceStyle = .light
        if let v = ProcessInfo.processInfo.environment["OPENUIKIT_APP_STYLE"] {
            switch v {
            case "dark": style = .dark
            case "light": style = .light
            default:
                FileHandle.standardError.write(
                    Data("warning: ignoring unknown OPENUIKIT_APP_STYLE=\(v) (use light|dark)\n".utf8))
            }
        }
        scene = buildAppScene(appName, scaleOverride: scaleOverride.map { CGFloat($0) },
                              style: style)
    } else if navDemo {
        scene = buildNavDemoScene(scaleOverride: scaleOverride.map { CGFloat($0) }, largeTitles: navLargeTitles)
    } else {
        let sceneJSON = try loadSceneFile(scenePath!)
        scene = buildHostScene(sceneJSON, scaleOverride: scaleOverride.map { CGFloat($0) },
                               warn: warnToStderr)
    }

    if let scriptPath, let recordDir {
        let (events, captures) = parseScript(try loadSceneFile(scriptPath))
        try FileManager.default.createDirectory(atPath: recordDir,
                                                withIntermediateDirectories: true)
        let written = try runScripted(scene, events: events, captures: captures,
                                      outdir: recordDir)
        print("recorded \(written.count) frames to \(recordDir)")
        exit(0)
    }

    runLive(scene)

}