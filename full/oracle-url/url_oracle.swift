// url_oracle.swift -- harvest REAL Foundation's URL(string:) decomposition.
//
// The golden file any URL implementation must match, whether it ends up backed
// by CFURL or written in portable Swift. Built the way every oracle in this
// project is: run the real thing, record what it says, diff against it later.
import Foundation

let path = CommandLine.arguments[1]
let data = try! Data(contentsOf: URL(fileURLWithPath: path))
let inputs = try! JSONDecoder().decode([String].self, from: data)

func s(_ v: String?) -> Any { v ?? NSNull() }
func i(_ v: Int?) -> Any { v ?? NSNull() }

var out: [[String: Any]] = []
for input in inputs {
    var row: [String: Any] = ["input": input]
    guard let u = URL(string: input) else {
        row["parses"] = false
        out.append(row); continue
    }
    row["parses"] = true
    row["absoluteString"] = u.absoluteString
    row["scheme"] = s(u.scheme)
    row["host"] = s(u.host)
    row["port"] = i(u.port)
    row["path"] = u.path
    row["query"] = s(u.query)
    row["fragment"] = s(u.fragment)
    row["user"] = s(u.user)
    row["password"] = s(u.password)
    row["relativePath"] = u.relativePath
    row["isFileURL"] = u.isFileURL
    row["lastPathComponent"] = u.lastPathComponent
    row["pathExtension"] = u.pathExtension
    row["pathComponents"] = u.pathComponents
    // The path operations apps actually call (census: appendingPathComponent
    // is 12.9% of URL member uses, second only to absoluteString).
    row["appendingPathComponent_x"] = u.appendingPathComponent("x").absoluteString
    row["deletingLastPathComponent"] = u.deletingLastPathComponent().absoluteString
    out.append(row)
}
let json = try! JSONSerialization.data(withJSONObject: out, options: [.prettyPrinted, .sortedKeys])
FileHandle.standardOutput.write(json)
