// openrender CLI. Owner: rendercli module.
// Usage:
//   openrender render <outdir> <scene.json>...
// Mirrors Tools/oracle/main.swift (scene interpretation, layout dump format,
// exit codes, messages) but renders with OpenUIKit instead of real UIKit.

import Foundation

func renderScene(file: String, outdir: String) throws {
    let scene = try loadSceneFile(file)
    let result = runScene(scene, warn: warnToStderr)
    try writeJSONFile(result.layout, path: "\(outdir)/\(result.name).layout.json")
    try writeBinaryFile(result.png, path: "\(outdir)/\(result.name).png")
    print("rendered \(result.name)")
}

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
    exit(failures == 0 ? 0 : 1)
default:
    print("unknown command \(args[1])")
    exit(1)
}
