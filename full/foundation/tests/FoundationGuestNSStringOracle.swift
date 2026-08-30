import Foundation

private func field(_ label: String, _ value: Any) {
    print("\(label)=\(value)")
}

private func rangeText(_ range: NSRange) -> String {
    if range.location == NSNotFound { return "not-found" }
    return "\(range.location):\(range.length)"
}

private func hex(_ value: unichar) -> String {
    String(format: "%04X", value)
}

private struct ObjectCollection<ObjectType: AnyObject> {
    let items: [ObjectType]
}

private func makeCharactersString() -> NSString {
    let units: [unichar] = [0x0041, 0xD83D, 0xDE42, 0x0062]
    return units.withUnsafeBufferPointer {
        NSString(characters: $0.baseAddress!, length: $0.count)
    }
}

private func makeUTF8String() -> NSString? {
    let bytes = Array("café".utf8CString)
    return bytes.withUnsafeBufferPointer {
        NSString(utf8String: $0.baseAddress!)
    }
}

private func invalidUTF8Accepted() -> Bool {
    let bytes: [UInt8] = [0xC3, 0x28]
    return bytes.withUnsafeBytes {
        NSString(
            bytes: $0.baseAddress!,
            length: $0.count,
            encoding: String.Encoding.utf8.rawValue
        ) != nil
    }
}

let value = NSString(string: "A🙂é")
let valueAsAny: Any = value
field("class.nsobject", valueAsAny is NSObject)
field("value.description", value.description)
field("value.debug", value.debugDescription)
field("value.empty", NSString().description.isEmpty)
field("utf16.length", value.length)
field("utf16.0", hex(value.character(at: 0)))
field("utf16.1", hex(value.character(at: 1)))
field("utf16.2", hex(value.character(at: 2)))
field("utf16.4", hex(value.character(at: 4)))
field("substring.from", value.substring(from: 1))
field("substring.to", value.substring(to: 3))
field("substring.range", value.substring(with: NSRange(location: 3, length: 2)))

let same = NSString(string: "A🙂é")
let different = NSString(string: "different")
field("equal.value", value.isEqual(to: "A🙂é"))
field("equal.object", value.isEqual(same))
field("equal.reject", value.isEqual(different))
field("equal.hash", value.hash == same.hash)
field("compare.same", NSString(string: "Focus").compare("Focus").rawValue)
field(
    "compare.case",
    NSString(string: "Focus").compare("focus", options: .caseInsensitive).rawValue
)
field(
    "compare.range",
    NSString(string: "xxFocusyy").compare(
        "focus",
        options: .caseInsensitive,
        range: NSRange(location: 2, length: 5),
        locale: nil
    ).rawValue
)
field(
    "compare.case-convenience",
    NSString(string: "Focus").caseInsensitiveCompare("focus").rawValue
)
field("prefix", NSString(string: "Focus Linux").hasPrefix("Focus"))
field("suffix", NSString(string: "Focus Linux").hasSuffix("Linux"))
field("range.forward", rangeText(NSString(string: "aBAba").range(of: "ba")))
field(
    "range.backwards",
    rangeText(NSString(string: "aBAba").range(of: "ba", options: [.caseInsensitive, .backwards]))
)
field("range.missing", rangeText(NSString(string: "abc").range(of: "z")))

let bridgeObject: NSString = "bridge" as NSString
let implicitObject: NSString = "implicit"
let bridgeValue: String = bridgeObject as String
let swiftAny: Any = "any-bridge"
let objectAny: Any = NSString(string: "object-bridge")
field("bridge.direct", bridgeObject.description)
field("bridge.implicit", NSString(string: String(implicitObject)).description)
field("bridge.value", bridgeValue)
field("bridge.any-object", (swiftAny as? NSString)?.description ?? "nil")
field("bridge.any-value", objectAny as? String ?? "nil")
field("bridge.init", String(NSString(string: "initializer")))
field(
    "bridge.generic-reference",
    ObjectCollection<NSString>(items: [implicitObject]).items.count
)

let copied = value.copy() as! NSString
let protocolCopy = (value as NSCopying).copy(with: nil) as! NSString
field("copy.identity", copied === value)
field("copy.protocol-identity", protocolCopy === value)

field("utf8.pointer", String(cString: value.utf8String!))
field("utf8.init", makeUTF8String()?.description ?? "nil")
field("utf8.invalid", invalidUTF8Accepted())
field("characters.init", makeCharactersString().description)
field(
    "data.init",
    NSString(data: Data("東京".utf8), encoding: String.Encoding.utf8.rawValue)?.description ?? "nil"
)
field(
    "data.output",
    String(data: NSString(string: "café").data(using: String.Encoding.utf8.rawValue)!, encoding: .utf8) ?? "nil"
)
field("format", NSString(format: "%@-%02d", "focus", 7).description)

let path = NSString(string: "/tmp/focus/archive.tar.gz")
field("path.last", path.lastPathComponent)
field("path.extension", path.pathExtension)
field("path.delete-extension", path.deletingPathExtension)
field("path.delete-last", path.deletingLastPathComponent)
field("path.append", NSString(string: "/tmp/focus").appendingPathComponent("file.txt"))
