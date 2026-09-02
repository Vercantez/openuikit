// Minimal JSON parser. Pure Swift, no Foundation. Owner: runtime-util.

public enum JSONValue {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public var doubleValue: Double? { if case .number(let d) = self { return d }; return nil }
    public var stringValue: String? { if case .string(let s) = self { return s }; return nil }
    public var boolValue: Bool? { if case .bool(let b) = self { return b }; return nil }
    public var arrayValue: [JSONValue]? { if case .array(let a) = self { return a }; return nil }
    public var objectValue: [String: JSONValue]? { if case .object(let o) = self { return o }; return nil }
    public subscript(key: String) -> JSONValue? { objectValue?[key] }
    public subscript(index: Int) -> JSONValue? {
        guard let a = arrayValue, index >= 0, index < a.count else { return nil }
        return a[index]
    }

    public static func parse(_ bytes: [UInt8]) -> JSONValue? {
        var parser = _JSONParser(bytes: bytes)
        guard let v = parser.parseValue() else { return nil }
        parser.skipWhitespace()
        return parser.pos == bytes.count ? v : nil
    }
    public static func parse(_ text: String) -> JSONValue? { parse(Array(text.utf8)) }
}

private struct _JSONParser {
    let bytes: [UInt8]
    var pos = 0

    mutating func skipWhitespace() {
        while pos < bytes.count {
            let b = bytes[pos]
            if b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D { pos += 1 } else { break }
        }
    }
    mutating func parseValue() -> JSONValue? {
        skipWhitespace()
        guard pos < bytes.count else { return nil }
        switch bytes[pos] {
        case UInt8(ascii: "{"): return parseObject()
        case UInt8(ascii: "["): return parseArray()
        case UInt8(ascii: "\""): return parseString().map { .string($0) }
        case UInt8(ascii: "t"):
            return consume("true") ? .bool(true) : nil
        case UInt8(ascii: "f"):
            return consume("false") ? .bool(false) : nil
        case UInt8(ascii: "n"):
            return consume("null") ? JSONValue.null : nil
        default: return parseNumber()
        }
    }
    mutating func consume(_ s: String) -> Bool {
        let u = Array(s.utf8)
        guard pos + u.count <= bytes.count else { return false }
        for (i, b) in u.enumerated() where bytes[pos + i] != b { return false }
        pos += u.count
        return true
    }
    mutating func parseObject() -> JSONValue? {
        pos += 1  // {
        var dict: [String: JSONValue] = [:]
        skipWhitespace()
        if pos < bytes.count && bytes[pos] == UInt8(ascii: "}") { pos += 1; return .object(dict) }
        while true {
            skipWhitespace()
            guard pos < bytes.count, bytes[pos] == UInt8(ascii: "\""), let key = parseString() else { return nil }
            skipWhitespace()
            guard pos < bytes.count, bytes[pos] == UInt8(ascii: ":") else { return nil }
            pos += 1
            guard let v = parseValue() else { return nil }
            dict[key] = v
            skipWhitespace()
            guard pos < bytes.count else { return nil }
            if bytes[pos] == UInt8(ascii: ",") { pos += 1; continue }
            if bytes[pos] == UInt8(ascii: "}") { pos += 1; return .object(dict) }
            return nil
        }
    }
    mutating func parseArray() -> JSONValue? {
        pos += 1  // [
        var arr: [JSONValue] = []
        skipWhitespace()
        if pos < bytes.count && bytes[pos] == UInt8(ascii: "]") { pos += 1; return .array(arr) }
        while true {
            guard let v = parseValue() else { return nil }
            arr.append(v)
            skipWhitespace()
            guard pos < bytes.count else { return nil }
            if bytes[pos] == UInt8(ascii: ",") { pos += 1; continue }
            if bytes[pos] == UInt8(ascii: "]") { pos += 1; return .array(arr) }
            return nil
        }
    }
    mutating func parseString() -> String? {
        pos += 1  // opening quote
        var out: [UInt8] = []
        while pos < bytes.count {
            let b = bytes[pos]
            if b == UInt8(ascii: "\"") { pos += 1; return String(decoding: out, as: UTF8.self) }
            if b == UInt8(ascii: "\\") {
                pos += 1
                guard pos < bytes.count else { return nil }
                switch bytes[pos] {
                case UInt8(ascii: "\""): out.append(UInt8(ascii: "\""))
                case UInt8(ascii: "\\"): out.append(UInt8(ascii: "\\"))
                case UInt8(ascii: "/"): out.append(UInt8(ascii: "/"))
                case UInt8(ascii: "b"): out.append(8)
                case UInt8(ascii: "f"): out.append(12)
                case UInt8(ascii: "n"): out.append(10)
                case UInt8(ascii: "r"): out.append(13)
                case UInt8(ascii: "t"): out.append(9)
                case UInt8(ascii: "u"):
                    guard pos + 4 < bytes.count else { return nil }
                    var code = 0
                    for i in 1...4 {
                        let h = bytes[pos + i]
                        let d: Int
                        switch h {
                        case UInt8(ascii: "0")...UInt8(ascii: "9"): d = Int(h - UInt8(ascii: "0"))
                        case UInt8(ascii: "a")...UInt8(ascii: "f"): d = Int(h - UInt8(ascii: "a")) + 10
                        case UInt8(ascii: "A")...UInt8(ascii: "F"): d = Int(h - UInt8(ascii: "A")) + 10
                        default: return nil
                        }
                        code = code * 16 + d
                    }
                    pos += 4
                    var codepoint = code
                    // Surrogate pair
                    if code >= 0xD800 && code <= 0xDBFF, pos + 6 < bytes.count,
                       bytes[pos + 1] == UInt8(ascii: "\\"), bytes[pos + 2] == UInt8(ascii: "u") {
                        var low = 0
                        var ok = true
                        for i in 3...6 {
                            let h = bytes[pos + i]
                            let d: Int
                            switch h {
                            case UInt8(ascii: "0")...UInt8(ascii: "9"): d = Int(h - UInt8(ascii: "0"))
                            case UInt8(ascii: "a")...UInt8(ascii: "f"): d = Int(h - UInt8(ascii: "a")) + 10
                            case UInt8(ascii: "A")...UInt8(ascii: "F"): d = Int(h - UInt8(ascii: "A")) + 10
                            default: ok = false; d = 0
                            }
                            if !ok { break }
                            low = low * 16 + d
                        }
                        if ok && low >= 0xDC00 && low <= 0xDFFF {
                            codepoint = 0x10000 + (code - 0xD800) * 0x400 + (low - 0xDC00)
                            pos += 6
                        }
                    }
                    if let scalar = Unicode.Scalar(codepoint) {
                        out += Array(String(Character(scalar)).utf8)
                    }
                default: return nil
                }
                pos += 1
            } else {
                out.append(b)
                pos += 1
            }
        }
        return nil
    }
    mutating func parseNumber() -> JSONValue? {
        let start = pos
        while pos < bytes.count {
            let b = bytes[pos]
            if (b >= UInt8(ascii: "0") && b <= UInt8(ascii: "9")) || b == UInt8(ascii: "-")
                || b == UInt8(ascii: "+") || b == UInt8(ascii: ".") || b == UInt8(ascii: "e")
                || b == UInt8(ascii: "E") {
                pos += 1
            } else { break }
        }
        guard pos > start, let d = Double(String(decoding: bytes[start..<pos], as: UTF8.self)) else { return nil }
        return .number(d)
    }
}
