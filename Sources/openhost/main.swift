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
// Environment: OPENUIKIT_BACKEND / OPENUIKIT_COMPOSITOR (same as
// openrender). Run from the repo root (OpenUIKit resources are found via
// the default relative resourceRoot) — scripts/host.sh does this for you.
//
// Sharing: SceneBuilder.swift and SceneIO.swift are symlinks to
// ../openrender/ — one scene-building implementation for both executables.

import Foundation
import OpenUIKit

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

let usage = """
usage: openhost <scene.json> [--scale N] [--script events.json --record outdir]
       openhost --nav-demo   [--scale N] [--script events.json --record outdir]
"""

var scenePath: String? = nil
var scaleOverride: Double? = nil
var scriptPath: String? = nil
var recordDir: String? = nil
var navDemo = false

var it = CommandLine.arguments.dropFirst().makeIterator()
while let arg = it.next() {
    switch arg {
    case "--nav-demo":
        navDemo = true
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

guard navDemo != (scenePath != nil) else { print(usage); exit(1) }
guard (scriptPath == nil) == (recordDir == nil) else {
    print("--script and --record must be used together\n\(usage)"); exit(1)
}

let scene: HostScene
if navDemo {
    scene = buildNavDemoScene(scaleOverride: scaleOverride.map { CGFloat($0) })
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
