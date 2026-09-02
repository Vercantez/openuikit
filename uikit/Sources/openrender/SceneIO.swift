// Foundation-facing IO for the openrender CLI. Owner: rendercli module.
//
// All Foundation use is isolated here (and in main.swift). This file never
// names CG geometry types, so Apple's CoreGraphics types (dragged in by
// Foundation on Darwin) cannot clash with OpenCoreGraphics' types.
// Scene JSON is parsed with JSONSerialization and converted into
// OpenUIKit.JSONValue, the Foundation-free interchange type the builder
// (SceneBuilder.swift) consumes.

import Foundation
import OpenUIKit

enum SceneIOError: Error, CustomStringConvertible {
    case notJSONObject(String)
    var description: String {
        switch self {
        case .notJSONObject(let path): return "top-level JSON is not an object: \(path)"
        }
    }
}

func loadSceneFile(_ path: String) throws -> JSONValue {
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    // Parsed with OpenUIKit's own MiniJSON rather than JSONSerialization:
    // it yields JSONValue directly (no NSNumber round-trip, which cannot
    // distinguish `true` from `1` without CoreFoundation, unavailable off
    // Darwin).
    guard let value = JSONValue.parse([UInt8](data)) else {
        throw SceneIOError.notJSONObject(path)
    }
    guard value.objectValue != nil else { throw SceneIOError.notJSONObject(path) }
    return value
}

private func toFoundation(_ v: JSONValue) -> Any {
    switch v {
    case .object(let d): return d.mapValues(toFoundation)
    case .array(let a): return a.map(toFoundation)
    case .number(let d): return d
    case .string(let s): return s
    case .bool(let b): return b
    case .null: return NSNull()
    }
}

func writeJSONFile(_ v: JSONValue, path: String) throws {
    let data = try JSONSerialization.data(withJSONObject: toFoundation(v),
                                          options: [.prettyPrinted, .sortedKeys])
    try data.write(to: URL(fileURLWithPath: path))
}

func writeBinaryFile(_ bytes: [UInt8], path: String) throws {
    try Data(bytes).write(to: URL(fileURLWithPath: path))
}

func warnToStderr(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}
