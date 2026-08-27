// Plist.swift -- an XML property-list reader, Foundation-free.
//
// WHY THIS EXISTS AT ALL. `Bundle` is the third piece of the process layer, and
// the one §6 flagged as most likely to need Foundation. It does not: reading
// Info.plist needs a parser, and a parser is self-contained. Foundation's
// PropertyListSerialization is the real API, but adopting it would drag in the
// module whose mere VISIBILITY flips 33 canImport guards in OpenUIKit onto a
// path this sysroot cannot satisfy (see the build's freestanding guard).
//
// SCOPE IS DELIBERATELY THE MEASURED ONE, NOT THE SPECIFICATION. Every
// Info.plist reachable from here is XML -- the six .app fixtures in
// ~/uikit/Tools/oracle2, and macOS's own Calculator.app and Safari.app were
// checked as a sanity test. The element set is what those files actually use:
// dict, key, string, array, integer, real, true/false, data, and empty forms
// like <dict/>. Comments, the XML declaration and the DOCTYPE are skipped.
//
// WHAT THIS DOES NOT DO, stated rather than discovered later: BINARY plists
// (`bplist00`). Shipped iOS apps ship binary Info.plists, so a real .ipa will
// need that reader. It is a separate, self-contained job and there is no
// fixture for it here yet -- so it is a named gap, not an assumed-away one.
// `Plist.parse` returns nil on a binary plist rather than guessing, and
// `Bundle` reports that distinctly.

/// A property-list value. `Any` is avoided so the tree can be matched
/// exhaustively and so nothing needs a bridge.
indirect enum PlistValue {
    case string(String)
    case integer(Int)
    case real(Double)
    case boolean(Bool)
    case array([PlistValue])
    case dictionary([String: PlistValue])
    /// base64 text, left undecoded: nothing in an Info.plist we read needs the
    /// bytes, and decoding it would be code with no caller.
    case data(String)

    var stringValue: String? { if case .string(let s) = self { return s }; return nil }
    var intValue: Int? { if case .integer(let i) = self { return i }; return nil }
    var boolValue: Bool? { if case .boolean(let b) = self { return b }; return nil }
    var arrayValue: [PlistValue]? { if case .array(let a) = self { return a }; return nil }
    var dictionaryValue: [String: PlistValue]? {
        if case .dictionary(let d) = self { return d }; return nil
    }
}

enum PlistError: Error, CustomStringConvertible {
    case binaryFormat
    case malformed(String)

    var description: String {
        switch self {
        case .binaryFormat:
            return "binary property list (bplist00) -- only XML is implemented; see Plist.swift"
        case .malformed(let why):
            return "malformed XML property list: \(why)"
        }
    }
}

enum Plist {
    /// Parse UTF-8 plist bytes. Returns the root value, or the reason it could
    /// not -- never a partial tree, and never a guess.
    static func parse(_ bytes: [UInt8]) -> Result<PlistValue, PlistError> {
        // Binary plists start with the literal "bplist". Detected FIRST so the
        // failure names the format instead of dying inside the XML scanner.
        let magic: [UInt8] = Array("bplist".utf8)
        if bytes.count >= magic.count, Array(bytes.prefix(magic.count)) == magic {
            return .failure(.binaryFormat)
        }
        var p = Parser(scalars: Array(String(decoding: bytes, as: UTF8.self).unicodeScalars))
        return p.parseDocument()
    }
}

private struct Parser {
    let scalars: [Unicode.Scalar]
    var i = 0

    init(scalars: [Unicode.Scalar]) { self.scalars = scalars }

    var atEnd: Bool { i >= scalars.count }

    mutating func skipSpace() {
        while i < scalars.count, scalars[i] == " " || scalars[i] == "\n"
            || scalars[i] == "\r" || scalars[i] == "\t" { i += 1 }
    }

    /// Skip whitespace and anything that is not element content: the `<?xml?>`
    /// declaration, the DOCTYPE, and comments. Comments matter -- the oracle2
    /// fixtures carry them between keys, and a scanner that treated `<!--` as a
    /// tag would read `--` as an element name.
    mutating func skipNoise() {
        while true {
            skipSpace()
            guard i + 1 < scalars.count, scalars[i] == "<" else { return }
            let n = scalars[i + 1]
            if n == "?" || n == "!" {
                if matches("<!--") {
                    guard let end = find("-->", from: i + 4) else { i = scalars.count; return }
                    i = end + 3
                } else {
                    guard let end = find(">", from: i + 2) else { i = scalars.count; return }
                    i = end + 1
                }
            } else {
                return
            }
        }
    }

    func matches(_ s: String) -> Bool {
        let t = Array(s.unicodeScalars)
        guard i + t.count <= scalars.count else { return false }
        for (k, c) in t.enumerated() where scalars[i + k] != c { return false }
        return true
    }

    func find(_ s: String, from: Int) -> Int? {
        let t = Array(s.unicodeScalars)
        guard !t.isEmpty else { return nil }
        var k = from
        while k + t.count <= scalars.count {
            var hit = true
            for (j, c) in t.enumerated() where scalars[k + j] != c { hit = false; break }
            if hit { return k }
            k += 1
        }
        return nil
    }

    /// Read `<name ...>` or `<name/>`. Returns the name and whether it was
    /// self-closing, leaving `i` past the tag.
    mutating func readTag() -> (name: String, selfClosing: Bool)? {
        guard i < scalars.count, scalars[i] == "<" else { return nil }
        guard let close = find(">", from: i) else { return nil }
        var body = ""
        var k = i + 1
        while k < close { body.unicodeScalars.append(scalars[k]); k += 1 }
        i = close + 1
        let selfClosing = body.hasSuffix("/")
        if selfClosing { body.removeLast() }
        let name = body.split(separator: " ").first.map(String.init) ?? body
        return (name, selfClosing)
    }

    /// Text up to the next `<`, with the five XML entities resolved.
    mutating func readText() -> String {
        var out = ""
        while i < scalars.count, scalars[i] != "<" {
            if scalars[i] == "&" {
                if matches("&amp;") { out += "&"; i += 5; continue }
                if matches("&lt;") { out += "<"; i += 4; continue }
                if matches("&gt;") { out += ">"; i += 4; continue }
                if matches("&quot;") { out += "\""; i += 6; continue }
                if matches("&apos;") { out += "'"; i += 6; continue }
            }
            out.unicodeScalars.append(scalars[i])
            i += 1
        }
        return out
    }

    mutating func parseDocument() -> Result<PlistValue, PlistError> {
        skipNoise()
        guard let open = readTag(), open.name == "plist" else {
            return .failure(.malformed("expected a <plist> root element"))
        }
        if open.selfClosing { return .failure(.malformed("<plist/> has no root value")) }
        skipNoise()
        return parseValue()
    }

    mutating func parseValue() -> Result<PlistValue, PlistError> {
        skipNoise()
        guard let tag = readTag() else { return .failure(.malformed("expected a value element")) }
        switch tag.name {
        case "true":  return .success(.boolean(true))
        case "false": return .success(.boolean(false))
        case "dict":
            if tag.selfClosing { return .success(.dictionary([:])) }
            var out: [String: PlistValue] = [:]
            while true {
                skipNoise()
                guard let t = readTag() else { return .failure(.malformed("unterminated <dict>")) }
                if t.name == "/dict" { return .success(.dictionary(out)) }
                guard t.name == "key" else {
                    return .failure(.malformed("expected <key> in <dict>, saw <\(t.name)>"))
                }
                let key = readText()
                _ = readTag()                 // </key>
                switch parseValue() {
                case .failure(let e): return .failure(e)
                case .success(let v): out[key] = v
                }
            }
        case "array":
            if tag.selfClosing { return .success(.array([])) }
            var out: [PlistValue] = []
            while true {
                skipNoise()
                if matches("</array>") { i += 8; return .success(.array(out)) }
                switch parseValue() {
                case .failure(let e): return .failure(e)
                case .success(let v): out.append(v)
                }
            }
        case "string", "integer", "real", "data":
            let text = readText()
            _ = readTag()                     // the closing tag
            switch tag.name {
            case "string": return .success(.string(tag.selfClosing ? "" : text))
            case "data":   return .success(.data(text))
            case "integer":
                guard let n = Int(text.trimmedPlistText) else {
                    return .failure(.malformed("<integer> is not an integer: \(text)"))
                }
                return .success(.integer(n))
            default:
                guard let d = Double(text.trimmedPlistText) else {
                    return .failure(.malformed("<real> is not a number: \(text)"))
                }
                return .success(.real(d))
            }
        default:
            return .failure(.malformed("unsupported element <\(tag.name)>"))
        }
    }
}

private extension String {
    /// Trim ASCII whitespace without Foundation's `trimmingCharacters`.
    var trimmedPlistText: String {
        var s = Substring(self)
        while let c = s.first, c == " " || c == "\n" || c == "\r" || c == "\t" { s = s.dropFirst() }
        while let c = s.last, c == " " || c == "\n" || c == "\r" || c == "\t" { s = s.dropLast() }
        return String(s)
    }
}
