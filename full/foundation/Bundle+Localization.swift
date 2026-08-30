// Resource-bundle metadata and localization for the standalone Foundation
// guest facade.
//
// OpenUIKit owns the Bundle identity because UIKit exposes it in public
// signatures while Foundation is hidden from the OpenUIKit compilation. This
// later facade extends that exact class with filesystem-backed behavior. The
// XML plist and strings readers are project-owned, fail-closed parsers: they do
// not claim binary-plist support or silently return partial dictionaries.

import FoundationEssentials
import OpenUIKit

public extension OpenUIKit.Bundle {
    /// The parsed XML Info.plist dictionary, or nil when the bundle has no
    /// readable, well-formed XML property list.
    var infoDictionary: [String: Any]? {
        guard let data = FileManager.default.contents(atPath: _guestInfoPlistPath),
              let root = _FoundationGuestPlist.parse(Array(data)),
              case .dictionary(let dictionary) = root else { return nil }
        return dictionary.mapValues(\._anyValue)
    }

    func object(forInfoDictionaryKey key: String) -> Any? {
        infoDictionary?[key]
    }

    var bundleIdentifier: String? {
        object(forInfoDictionaryKey: "CFBundleIdentifier") as? String
    }

    /// Every localization directory physically present in the resource root.
    var localizations: [String] {
        guard let resourcePath,
              let entries = try? FileManager.default.contentsOfDirectory(atPath: resourcePath)
        else { return [] }
        return entries.compactMap { entry in
            guard entry.hasSuffix(".lproj"), entry.count > 6 else { return nil }
            return String(entry.dropLast(6))
        }.sorted()
    }

    var developmentLocalization: String? {
        object(forInfoDictionaryKey: "CFBundleDevelopmentRegion") as? String
    }

    /// The ordered bundle-localization match used by `localizedString`.
    var preferredLocalizations: [String] {
        let available = localizations
        guard !available.isEmpty else {
            if let developmentLocalization, !developmentLocalization.isEmpty {
                return [developmentLocalization]
            }
            return [Locale.preferredLanguages.first ?? "en"]
        }

        var result: [String] = []
        for preference in Locale.preferredLanguages {
            if let match = _foundationGuestLocalizationMatch(preference, in: available),
               !result.contains(match) {
                result.append(match)
            }
        }
        for fallback in [developmentLocalization, "Base", "en"] {
            if let fallback,
               let match = _foundationGuestLocalizationMatch(fallback, in: available),
               !result.contains(match) {
                result.append(match)
            }
        }
        if result.isEmpty, let first = available.first { result.append(first) }
        return result
    }

    /// Conventional App Store receipt location. Foundation exposes this URL
    /// even before a receipt exists; an existing sandbox receipt takes
    /// precedence so unchanged TestFlight channel checks keep their spelling.
    var appStoreReceiptURL: URL? {
        let contents = bundleURL.appendingPathComponent("Contents", isDirectory: true)
        var isDirectory = false
        let container = FileManager.default.fileExists(
            atPath: contents.path,
            isDirectory: &isDirectory
        ) && isDirectory ? contents : bundleURL
        let receiptDirectory = container.appendingPathComponent(
            "_MASReceipt",
            isDirectory: true
        )
        let sandbox = receiptDirectory.appendingPathComponent(
            "sandboxReceipt",
            isDirectory: false
        )
        if FileManager.default.fileExists(atPath: sandbox.path) {
            return sandbox
        }
        return receiptDirectory.appendingPathComponent("receipt", isDirectory: false)
    }

    func path(forResource name: String?, ofType extensionName: String?) -> String? {
        url(forResource: name, withExtension: extensionName)?.path
    }

    /// Looks up one key in the preferred `.lproj` table chain.
    func localizedString(
        forKey key: String,
        value: String?,
        table tableName: String?
    ) -> String {
        let table = tableName?.isEmpty == false ? tableName! : "Localizable"
        for language in preferredLocalizations {
            let nestedName = "\(language).lproj/\(table)"
            guard let url = url(forResource: nestedName, withExtension: "strings"),
                  let data = FileManager.default.contents(atPath: url.path),
                  let strings = _FoundationGuestStringsFile.parse(Array(data)) else {
                continue
            }
            if let localized = strings[key] { return localized }
        }
        if let value, !value.isEmpty { return value }
        return key
    }

    private var _guestInfoPlistPath: String {
        let contents = bundleURL.appendingPathComponent("Contents", isDirectory: true)
        var isDirectory = false
        if FileManager.default.fileExists(atPath: contents.path, isDirectory: &isDirectory),
           isDirectory {
            return contents.appendingPathComponent("Info.plist").path
        }
        return bundleURL.appendingPathComponent("Info.plist").path
    }
}

public func NSLocalizedString(
    _ key: String,
    tableName: String? = nil,
    bundle: Bundle = .main,
    value: String = "",
    comment: String
) -> String {
    _ = comment
    return bundle.localizedString(forKey: key, value: value, table: tableName)
}

private func _foundationGuestLocalizationMatch(
    _ preference: String,
    in available: [String]
) -> String? {
    let normalized = preference.replacingOccurrences(of: "_", with: "-").lowercased()
    if let exact = available.first(where: {
        $0.replacingOccurrences(of: "_", with: "-").lowercased() == normalized
    }) {
        return exact
    }
    let language = normalized.split(separator: "-").first.map(String.init) ?? normalized
    return available.first(where: {
        let candidate = $0.replacingOccurrences(of: "_", with: "-").lowercased()
        return candidate == language || candidate.hasPrefix(language + "-")
    })
}

private indirect enum _FoundationGuestPlistValue {
    case string(String)
    case integer(Int)
    case real(Double)
    case boolean(Bool)
    case array([_FoundationGuestPlistValue])
    case dictionary([String: _FoundationGuestPlistValue])

    var _anyValue: Any {
        switch self {
        case .string(let value): return value
        case .integer(let value): return value
        case .real(let value): return value
        case .boolean(let value): return value
        case .array(let values): return values.map(\._anyValue)
        case .dictionary(let values): return values.mapValues(\._anyValue)
        }
    }
}

private enum _FoundationGuestPlist {
    static func parse(_ bytes: [UInt8]) -> _FoundationGuestPlistValue? {
        let binaryMagic = Array("bplist".utf8)
        guard bytes.count < binaryMagic.count ||
                Array(bytes.prefix(binaryMagic.count)) != binaryMagic else { return nil }
        guard let text = String(bytes: bytes, encoding: .utf8) else { return nil }
        var parser = _FoundationGuestXMLPlistParser(scalars: Array(text.unicodeScalars))
        return parser.parseDocument()
    }
}

private struct _FoundationGuestXMLPlistParser {
    let scalars: [Unicode.Scalar]
    var index = 0

    mutating func parseDocument() -> _FoundationGuestPlistValue? {
        skipNoise()
        guard let tag = readTag(), tag.name == "plist", !tag.selfClosing else { return nil }
        skipNoise()
        guard let value = parseValue() else { return nil }
        skipNoise()
        guard matches("</plist>") else { return nil }
        index += 8
        skipNoise()
        return index == scalars.count ? value : nil
    }

    mutating func parseValue() -> _FoundationGuestPlistValue? {
        skipNoise()
        guard let tag = readTag() else { return nil }
        switch tag.name {
        case "true":
            guard tag.selfClosing || consumeClosing("true") else { return nil }
            return .boolean(true)
        case "false":
            guard tag.selfClosing || consumeClosing("false") else { return nil }
            return .boolean(false)
        case "dict":
            if tag.selfClosing { return .dictionary([:]) }
            var result: [String: _FoundationGuestPlistValue] = [:]
            while true {
                skipNoise()
                if matches("</dict>") {
                    index += 7
                    return .dictionary(result)
                }
                guard let keyTag = readTag(), keyTag.name == "key", !keyTag.selfClosing else {
                    return nil
                }
                guard let key = readText(), consumeClosing("key"),
                      let value = parseValue() else { return nil }
                result[key] = value
            }
        case "array":
            if tag.selfClosing { return .array([]) }
            var result: [_FoundationGuestPlistValue] = []
            while true {
                skipNoise()
                if matches("</array>") {
                    index += 8
                    return .array(result)
                }
                guard let value = parseValue() else { return nil }
                result.append(value)
            }
        case "string", "integer", "real":
            if tag.selfClosing {
                return tag.name == "string" ? .string("") : nil
            }
            guard let text = readText(), consumeClosing(tag.name) else { return nil }
            switch tag.name {
            case "string": return .string(text)
            case "integer":
                guard let value = Int(text._foundationGuestASCIITrimmed) else { return nil }
                return .integer(value)
            case "real":
                guard let value = Double(text._foundationGuestASCIITrimmed) else { return nil }
                return .real(value)
            default: return nil
            }
        default:
            return nil
        }
    }

    mutating func skipNoise() {
        while true {
            skipSpace()
            guard index + 1 < scalars.count, scalars[index] == "<" else { return }
            if matches("<!--") {
                guard let end = find("-->", from: index + 4) else {
                    index = scalars.count
                    return
                }
                index = end + 3
            } else if scalars[index + 1] == "?" || scalars[index + 1] == "!" {
                guard let end = find(">", from: index + 2) else {
                    index = scalars.count
                    return
                }
                index = end + 1
            } else {
                return
            }
        }
    }

    mutating func skipSpace() {
        while index < scalars.count,
              scalars[index] == " " || scalars[index] == "\n" ||
                scalars[index] == "\r" || scalars[index] == "\t" {
            index += 1
        }
    }

    mutating func readTag() -> (name: String, selfClosing: Bool)? {
        guard index < scalars.count, scalars[index] == "<",
              let close = find(">", from: index + 1) else { return nil }
        var body = ""
        body.unicodeScalars.append(contentsOf: scalars[index + 1..<close])
        index = close + 1
        let selfClosing = body.hasSuffix("/")
        if selfClosing { body.removeLast() }
        let name: String
        if let separator = body.firstIndex(where: { $0 == " " || $0 == "\t" }) {
            name = String(body[..<separator])
        } else {
            name = body
        }
        return (name, selfClosing)
    }

    mutating func readText() -> String? {
        var output = ""
        while index < scalars.count, scalars[index] != "<" {
            if scalars[index] == "&" {
                if consumeEntity("&amp;", as: "&", into: &output) { continue }
                if consumeEntity("&lt;", as: "<", into: &output) { continue }
                if consumeEntity("&gt;", as: ">", into: &output) { continue }
                if consumeEntity("&quot;", as: "\"", into: &output) { continue }
                if consumeEntity("&apos;", as: "'", into: &output) { continue }
                return nil
            }
            output.unicodeScalars.append(scalars[index])
            index += 1
        }
        return output
    }

    mutating func consumeEntity(
        _ entity: String,
        as replacement: String,
        into output: inout String
    ) -> Bool {
        guard matches(entity) else { return false }
        output += replacement
        index += entity.unicodeScalars.count
        return true
    }

    mutating func consumeClosing(_ name: String) -> Bool {
        let closing = "</\(name)>"
        guard matches(closing) else { return false }
        index += closing.unicodeScalars.count
        return true
    }

    func matches(_ value: String) -> Bool {
        let target = Array(value.unicodeScalars)
        guard index + target.count <= scalars.count else { return false }
        return target.indices.allSatisfy { scalars[index + $0] == target[$0] }
    }

    func find(_ value: String, from start: Int) -> Int? {
        let target = Array(value.unicodeScalars)
        guard !target.isEmpty else { return nil }
        var cursor = start
        while cursor + target.count <= scalars.count {
            if target.indices.allSatisfy({ scalars[cursor + $0] == target[$0] }) {
                return cursor
            }
            cursor += 1
        }
        return nil
    }
}

private enum _FoundationGuestStringsFile {
    static func parse(_ bytes: [UInt8]) -> [String: String]? {
        guard let source = String(bytes: bytes, encoding: .utf8) else { return nil }
        var parser = _FoundationGuestStringsParser(scalars: Array(source.unicodeScalars))
        return parser.parse()
    }
}

private struct _FoundationGuestStringsParser {
    let scalars: [Unicode.Scalar]
    var index = 0

    mutating func parse() -> [String: String]? {
        var result: [String: String] = [:]
        while true {
            guard skipNoise() else { return nil }
            if index == scalars.count { return result }
            guard let key = readToken(), skipNoise(), consume("="), skipNoise(),
                  let value = readToken(), skipNoise(), consume(";") else { return nil }
            result[key] = value
        }
    }

    mutating func skipNoise() -> Bool {
        while true {
            while index < scalars.count, scalars[index] == " " || scalars[index] == "\t" ||
                    scalars[index] == "\r" || scalars[index] == "\n" {
                index += 1
            }
            if matches("/*") {
                guard let end = find("*/", from: index + 2) else { return false }
                index = end + 2
                continue
            }
            if matches("//") {
                while index < scalars.count, scalars[index] != "\n" { index += 1 }
                continue
            }
            return true
        }
    }

    mutating func readToken() -> String? {
        guard index < scalars.count else { return nil }
        if scalars[index] == "\"" { return readQuoted() }
        let start = index
        while index < scalars.count,
              scalars[index] != " " && scalars[index] != "\t" &&
                scalars[index] != "\r" && scalars[index] != "\n" &&
                scalars[index] != "=" && scalars[index] != ";" {
            index += 1
        }
        guard index > start else { return nil }
        var token = ""
        token.unicodeScalars.append(contentsOf: scalars[start..<index])
        return token
    }

    mutating func readQuoted() -> String? {
        guard consume("\"") else { return nil }
        var output = ""
        while index < scalars.count {
            let scalar = scalars[index]
            index += 1
            if scalar == "\"" { return output }
            guard scalar == "\\" else {
                output.unicodeScalars.append(scalar)
                continue
            }
            guard index < scalars.count else { return nil }
            let escaped = scalars[index]
            index += 1
            switch escaped {
            case "n": output.append("\n")
            case "r": output.append("\r")
            case "t": output.append("\t")
            case "\"": output.append("\"")
            case "\\": output.append("\\")
            case "U", "u":
                guard let value = readHexScalar(count: 4),
                      let unicode = Unicode.Scalar(value) else { return nil }
                output.unicodeScalars.append(unicode)
            default:
                output.unicodeScalars.append(escaped)
            }
        }
        return nil
    }

    mutating func readHexScalar(count: Int) -> UInt32? {
        guard index + count <= scalars.count else { return nil }
        var value: UInt32 = 0
        for _ in 0..<count {
            let scalar = scalars[index]
            index += 1
            let digit: UInt32
            switch scalar.value {
            case 48...57: digit = scalar.value - 48
            case 65...70: digit = scalar.value - 65 + 10
            case 97...102: digit = scalar.value - 97 + 10
            default: return nil
            }
            value = value * 16 + digit
        }
        return value
    }

    mutating func consume(_ value: String) -> Bool {
        guard matches(value) else { return false }
        index += value.unicodeScalars.count
        return true
    }

    func matches(_ value: String) -> Bool {
        let target = Array(value.unicodeScalars)
        guard index + target.count <= scalars.count else { return false }
        return target.indices.allSatisfy { scalars[index + $0] == target[$0] }
    }

    func find(_ value: String, from start: Int) -> Int? {
        let target = Array(value.unicodeScalars)
        var cursor = start
        while cursor + target.count <= scalars.count {
            if target.indices.allSatisfy({ scalars[cursor + $0] == target[$0] }) {
                return cursor
            }
            cursor += 1
        }
        return nil
    }
}

private extension String {
    var _foundationGuestASCIITrimmed: String {
        var value = Substring(self)
        while let first = value.first,
              first == " " || first == "\t" || first == "\r" || first == "\n" {
            value = value.dropFirst()
        }
        while let last = value.last,
              last == " " || last == "\t" || last == "\r" || last == "\n" {
            value = value.dropLast()
        }
        return String(value)
    }
}
