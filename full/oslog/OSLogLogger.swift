// Logger / OSLog / os_log overlay for the OSLog module (Linux host gate).
//
// Measurements: `/tmp/oslog-probe-fw-oslog` on OpenUIKit-2x-fw-oslog
// (iPhone SE 3rd gen, iOS 26.1, 2026-09-05). Apple docs cited in comments.
//
// Sibling `uikit/Sources/os` (wave 26) accepts the same call shapes and
// discards them. This module writes into `OSLogRing` so `OSLogStore` can
// read them back. Divergences are listed in the agent report.

import Foundation

/// Explicit integer/float checks. Linux Swift 6.2.4 has refused some
/// `any BinaryInteger` / `any BinaryFloatingPoint` expressions Apple's
/// compiler accepts.
enum OSLogScalar {
    static func isInteger<T>(_ value: T) -> Bool {
        int64(value) != nil
    }

    static func isFloat<T>(_ value: T) -> Bool {
        double(value) != nil && !(value is Bool)
    }

    static func int64<T>(_ value: T) -> Int64? {
        if let v = value as? Int { return Int64(v) }
        if let v = value as? Int8 { return Int64(v) }
        if let v = value as? Int16 { return Int64(v) }
        if let v = value as? Int32 { return Int64(v) }
        if let v = value as? Int64 { return v }
        if let v = value as? UInt8 { return Int64(v) }
        if let v = value as? UInt16 { return Int64(v) }
        if let v = value as? UInt32 { return Int64(v) }
        if let v = value as? UInt64 { return Int64(bitPattern: v) }
        if let v = value as? UInt { return Int64(bitPattern: UInt64(v)) }
        return nil
    }

    static func double<T>(_ value: T) -> Double? {
        if value is Bool { return nil }
        if let v = value as? Double { return v }
        if let v = value as? Float { return Double(v) }
        return nil
    }
}

// MARK: - Privacy

/// Privacy options for interpolated values.
///
/// Apple: https://developer.apple.com/documentation/os/oslogprivacy
/// `public` always shows the value; `private` redacts in Console as
/// `"<private>"`; `sensitive` always redacts. Probe 2026-09-05 currentProcessIdentifier
/// `composedMessage`: `.private` / `.auto` strings are visible in-process;
/// `.sensitive` is `"<private>"` even in-process (string and int).
public struct OSLogPrivacy: Equatable, Sendable {
    public enum Mask: Equatable, Sendable {
        /// Probe formatString: `%{private,mask.hash}s`. In-process
        /// composedMessage still showed the raw value (sample "hunter2").
        case hash
    }

    enum Kind: Equatable, Sendable {
        case `public`
        case `private`
        case sensitive
        case auto
    }

    var kind: Kind
    var mask: Mask?

    public init() {
        self.kind = .auto
        self.mask = nil
    }

    init(kind: Kind, mask: Mask?) {
        self.kind = kind
        self.mask = mask
    }

    public static let `public` = OSLogPrivacy(kind: .public, mask: nil)
    public static let `private` = OSLogPrivacy(kind: .private, mask: nil)
    public static let sensitive = OSLogPrivacy(kind: .sensitive, mask: nil)
    public static let auto = OSLogPrivacy(kind: .auto, mask: nil)

    public static func `private`(mask: Mask) -> OSLogPrivacy {
        OSLogPrivacy(kind: .private, mask: mask)
    }

    public static func sensitive(mask: Mask) -> OSLogPrivacy {
        OSLogPrivacy(kind: .sensitive, mask: mask)
    }

    public static func auto(mask: Mask) -> OSLogPrivacy {
        OSLogPrivacy(kind: .auto, mask: mask)
    }
}

// MARK: - Interpolation / message

public struct OSLogInterpolation: StringInterpolationProtocol {
    struct Piece {
        var literal: String
        var placeholder: String
        var rendered: String
        var category: OSLogMessageComponent.ArgumentCategory
        var stringValue: String?
        var int64: Int64
        var uint64: UInt64
        var double: Double
        var number: NSNumber?
        var dataValue: Data?
    }

    var literals: [String] = []
    var pieces: [Piece] = []

    public init(literalCapacity: Int, interpolationCount: Int) {
        literals.reserveCapacity(literalCapacity)
        pieces.reserveCapacity(interpolationCount)
        _ = interpolationCount
    }

    public mutating func appendLiteral(_ literal: String) {
        if pieces.isEmpty && literals.isEmpty {
            literals.append(literal)
        } else if pieces.isEmpty {
            literals[0].append(literal)
        } else {
            literals.append(literal)
        }
    }

    public mutating func appendInterpolation<T>(_ value: T) {
        appendValue(value, privacy: .auto)
    }

    public mutating func appendInterpolation<T>(_ value: T, privacy: OSLogPrivacy) {
        appendValue(value, privacy: privacy)
    }

    public mutating func appendInterpolation(_ value: Error, privacy: OSLogPrivacy) {
        appendValue(String(describing: value), privacy: privacy)
    }

    public mutating func appendInterpolation(_ value: Data) {
        appendData(value, privacy: .auto)
    }

    public mutating func appendInterpolation(_ value: Data, privacy: OSLogPrivacy) {
        appendData(value, privacy: privacy)
    }

    public mutating func appendInterpolation(_ value: UInt64) {
        appendUnsigned(value, privacy: .auto)
    }

    public mutating func appendInterpolation(_ value: UInt64, privacy: OSLogPrivacy) {
        appendUnsigned(value, privacy: privacy)
    }

    public mutating func appendInterpolation(_ value: Double) {
        appendValue(value, privacy: .auto)
    }

    public mutating func appendInterpolation(_ value: Double, privacy: OSLogPrivacy) {
        appendValue(value, privacy: privacy)
    }

    private mutating func appendData(_ value: Data, privacy: OSLogPrivacy) {
        if literals.count == pieces.count {
            literals.append("")
        }
        let placeholder = Self.placeholder(conversion: .string, privacy: privacy)
        let rendered = privacy.kind == .sensitive ? "<private>" : "<data>"
        let piece = Piece(
            literal: "",
            placeholder: placeholder,
            rendered: rendered,
            category: privacy.kind == .sensitive ? .undefined : .data,
            stringValue: nil,
            int64: 0,
            uint64: 0,
            double: 0,
            number: nil,
            dataValue: privacy.kind == .sensitive ? nil : value
        )
        pieces.append(piece)
    }

    private mutating func appendUnsigned(_ value: UInt64, privacy: OSLogPrivacy) {
        if literals.count == pieces.count {
            literals.append("")
        }
        let placeholder = Self.placeholder(conversion: .signed, privacy: privacy)
        let rendered = privacy.kind == .sensitive ? "<private>" : String(value)
        let piece = Piece(
            literal: "",
            placeholder: placeholder,
            rendered: rendered,
            category: privacy.kind == .sensitive ? .undefined : .uInt64,
            stringValue: nil,
            int64: 0,
            uint64: privacy.kind == .sensitive ? 0 : value,
            double: 0,
            number: privacy.kind == .sensitive ? nil : NSNumber(value: value),
            dataValue: nil
        )
        pieces.append(piece)
    }

    private mutating func appendValue<T>(_ value: T, privacy: OSLogPrivacy) {
        if literals.count == pieces.count {
            literals.append("")
        }
        let conversion = conversion(for: value)
        let placeholder = Self.placeholder(conversion: conversion, privacy: privacy)
        let rendered = Self.render(value, privacy: privacy)
        var piece = Piece(
            literal: "",
            placeholder: placeholder,
            rendered: rendered,
            category: Self.category(for: value, privacy: privacy),
            stringValue: nil,
            int64: 0,
            uint64: 0,
            double: 0,
            number: nil,
            dataValue: nil
        )
        if privacy.kind == .sensitive {
            piece.category = .undefined
        } else {
            fill(&piece, value: value)
        }
        pieces.append(piece)
    }

    private enum Conversion {
        case string
        case object
        case signed
        case boolean
        case float
    }

    private func conversion<T>(for value: T) -> Conversion {
        if value is Bool { return .boolean }
        if OSLogScalar.isInteger(value) { return .signed }
        if OSLogScalar.isFloat(value) { return .float }
        if value is String || value is NSString { return .string }
        return .string
    }

    /// Probe: auto string `%s`, public `%{public}s`, private `%{private}s`,
    /// sensitive `%{sensitive}s`, hash `%{private,mask.hash}s`.
    /// Int: `%ld` / `%{public}ld` / `%{private}ld` / `%{sensitive}ld`.
    /// Bool auto: `%{bool}d`.
    private static func placeholder(conversion: Conversion, privacy: OSLogPrivacy) -> String {
        let spec: String
        switch conversion {
        case .string: spec = "s"
        case .object: spec = "@"
        case .signed: spec = "ld"
        case .boolean: spec = privacy.kind == .auto ? "{bool}d" : "d"
        case .float: spec = "f"
        }
        let brace: String
        switch privacy.kind {
        case .public:
            brace = "{public}"
        case .private:
            if privacy.mask == .hash {
                brace = "{private,mask.hash}"
            } else {
                brace = "{private}"
            }
        case .sensitive:
            if privacy.mask == .hash {
                brace = "{sensitive,mask.hash}"
            } else {
                brace = "{sensitive}"
            }
        case .auto:
            if conversion == .boolean {
                return "%{bool}d"
            }
            return "%" + spec
        }
        return "%" + brace + spec
    }

    /// Probe composedMessage: `.sensitive` → `"<private>"` (Apple docs + sample
    /// `PRIV sensitive-str <private>`). `.private` is visible in-process.
    private static func render<T>(_ value: T, privacy: OSLogPrivacy) -> String {
        if privacy.kind == .sensitive {
            return "<private>"
        }
        if let flag = value as? Bool {
            return flag ? "true" : "false"
        }
        return String(describing: value)
    }

    private static func category<T>(for value: T, privacy: OSLogPrivacy) -> OSLogMessageComponent.ArgumentCategory {
        if privacy.kind == .sensitive { return .undefined }
        if value is Bool || OSLogScalar.isInteger(value) { return .int64 }
        if OSLogScalar.isFloat(value) { return .double }
        return .string
    }

    private func fill<T>(_ piece: inout Piece, value: T) {
        if let flag = value as? Bool {
            piece.int64 = flag ? 1 : 0
            piece.number = NSNumber(value: piece.int64)
            return
        }
        if let signed = OSLogScalar.int64(value) {
            piece.int64 = signed
            piece.number = NSNumber(value: signed)
            return
        }
        if let number = OSLogScalar.double(value) {
            piece.double = number
            piece.number = NSNumber(value: number)
            piece.category = .double
            return
        }
        piece.stringValue = String(describing: value)
    }

    func makeMessage() -> (composed: String, format: String, components: [OSLogMessageComponent]) {
        var composed = ""
        var format = ""
        var components: [OSLogMessageComponent] = []
        if pieces.isEmpty {
            let text = literals.first ?? ""
            return (text, text, [OSLogMessageComponent.staticText(text)])
        }
        for index in pieces.indices {
            let prefix = index < literals.count ? literals[index] : ""
            let piece = pieces[index]
            composed += prefix
            composed += piece.rendered
            format += prefix
            format += piece.placeholder
            components.append(
                OSLogMessageComponent(
                    formatSubstring: prefix,
                    placeholder: piece.placeholder,
                    argumentCategory: piece.category,
                    argumentDataValue: piece.dataValue,
                    argumentDoubleValue: piece.double,
                    argumentInt64Value: piece.int64,
                    argumentNumberValue: piece.number,
                    argumentStringValue: piece.stringValue,
                    argumentUInt64Value: piece.uint64
                )
            )
        }
        if literals.count > pieces.count {
            let tail = literals[pieces.count]
            composed += tail
            format += tail
        }
        components.append(OSLogMessageComponent.trailingEmpty())
        return (composed, format, components)
    }
}

public struct OSLogMessage: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    let composedMessage: String
    let formatString: String
    let components: [OSLogMessageComponent]

    public init(stringLiteral value: String) {
        composedMessage = value
        formatString = value
        components = [OSLogMessageComponent.staticText(value)]
    }

    public init(stringInterpolation: OSLogInterpolation) {
        let built = stringInterpolation.makeMessage()
        composedMessage = built.composed
        formatString = built.format
        components = built.components
    }
}

// MARK: - OSLogType / OSLog handle

public struct OSLogType: Equatable, RawRepresentable, Sendable {
    public var rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    /// Probe 2026-09-05 / os/log.h: default=0x00 info=0x01 debug=0x02
    /// error=0x10 fault=0x11.
    public static let `default` = OSLogType(rawValue: 0x00)
    public static let info = OSLogType(rawValue: 0x01)
    public static let debug = OSLogType(rawValue: 0x02)
    public static let error = OSLogType(rawValue: 0x10)
    public static let fault = OSLogType(rawValue: 0x11)
}

public struct OSLog: Equatable, @unchecked Sendable {
    public let subsystem: String
    public let category: String

    public static let `default` = OSLog(subsystem: "com.apple.runtime-issues", category: "os")
    public static let disabled = OSLog(subsystem: "", category: "")

    public init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
    }
}

// MARK: - Logger

public struct Logger: Sendable {
    public let subsystem: String
    public let category: String

    public init() {
        self.subsystem = ""
        self.category = ""
    }

    public init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
    }

    public init(_ log: OSLog) {
        self.subsystem = log.subsystem
        self.category = log.category
    }

    public func log(_ message: OSLogMessage) {
        record(.notice, message)
    }

    public func log(level: OSLogType, _ message: OSLogMessage) {
        record(OSLogTypeRaw.level(from: level.rawValue), message)
    }

    /// Probe: `trace` did not persist (debug). The ring keeps it as `.debug`.
    public func trace(_ message: OSLogMessage) { record(.debug, message) }
    /// Probe: `debug` / `log(level: .debug)` did not persist on iOS 26.1 SE.
    /// The in-process ring keeps debug rows (port; Apple drops them unless
    /// additional logging is enabled).
    public func debug(_ message: OSLogMessage) { record(.debug, message) }
    /// Probe: `info` → `OSLogEntryLog.Level.info` (2).
    public func info(_ message: OSLogMessage) { record(.info, message) }
    /// Probe: `notice` / `log()` / `log(level: .default)` → `.notice` (3).
    public func notice(_ message: OSLogMessage) { record(.notice, message) }
    /// Probe: `warning` → `.error` (4), same as `error`.
    public func warning(_ message: OSLogMessage) { record(.error, message) }
    /// Probe: `error` / `log(level: .error)` → `.error` (4).
    public func error(_ message: OSLogMessage) { record(.error, message) }
    /// Probe: `critical` → `.fault` (5), same as `fault`.
    public func critical(_ message: OSLogMessage) { record(.fault, message) }
    /// Probe: `fault` / `log(level: .fault)` → `.fault` (5).
    public func fault(_ message: OSLogMessage) { record(.fault, message) }

    private func record(_ level: OSLogEntryLog.Level, _ message: OSLogMessage) {
        OSLogRecord.log(
            subsystem: subsystem,
            category: category,
            level: level,
            composedMessage: message.composedMessage,
            formatString: message.formatString,
            components: message.components
        )
        diagnostic(level, message.composedMessage)
    }

    private func diagnostic(_ level: OSLogEntryLog.Level, _ text: String) {
        let line = "[\(subsystem):\(category)] \(text)\n"
        if let data = line.data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
        _ = level
    }
}

// MARK: - os_log C-style subset

/// Corpus subset: `%@ %d %s %{public}@ %{private}d` (plus `%{public}s` / `%{private}@`
/// measured on the same probe).
public func os_log(
    _ message: StaticString,
    dso: UnsafeRawPointer = #dsohandle,
    log: OSLog = .default,
    type: OSLogType = .default,
    _ args: CVarArg...
) {
    _ = dso
    let format = staticStringText(message)
    let built = OSLogCFormat.apply(format: format, args: args)
    OSLogRecord.log(
        subsystem: log.subsystem,
        category: log.category,
        level: OSLogTypeRaw.level(from: type.rawValue),
        composedMessage: built.composed,
        formatString: built.format,
        components: built.components
    )
}

public func os_log(
    _ type: OSLogType,
    dso: UnsafeRawPointer = #dsohandle,
    log: OSLog = .default,
    _ message: OSLogMessage
) {
    _ = dso
    OSLogRecord.log(
        subsystem: log.subsystem,
        category: log.category,
        level: OSLogTypeRaw.level(from: type.rawValue),
        composedMessage: message.composedMessage,
        formatString: message.formatString,
        components: message.components
    )
}

public func os_log(_ message: OSLogMessage) {
    os_log(.default, log: .default, message)
}

func staticStringText(_ value: StaticString) -> String {
    value.withUTF8Buffer { buffer in
        String(decoding: buffer, as: UTF8.self)
    }
}

enum OSLogCFormat {
    static func apply(format: String, args: [CVarArg]) -> (composed: String, format: String, components: [OSLogMessageComponent]) {
        if args.isEmpty {
            return (format, format, [OSLogMessageComponent.staticText(format)])
        }
        var composed = ""
        var index = format.startIndex
        var argIndex = 0
        var components: [OSLogMessageComponent] = []
        var prefix = ""
        while index < format.endIndex {
            if format[index] == "%" {
                let start = index
                var cursor = format.index(after: index)
                if cursor < format.endIndex && format[cursor] == "%" {
                    prefix.append("%")
                    index = format.index(after: cursor)
                    continue
                }
                while cursor < format.endIndex && format[cursor] == "{" {
                    guard let close = scanBrace(format, from: cursor) else { break }
                    cursor = format.index(after: close)
                }
                if cursor < format.endIndex {
                    cursor = format.index(after: cursor)
                }
                let placeholder = String(format[start..<cursor])
                let rendered: String
                if argIndex < args.count {
                    rendered = render(placeholder: placeholder, arg: args[argIndex])
                    let cat = category(placeholder: placeholder)
                    let values = argumentValues(arg: args[argIndex], category: cat, placeholder: placeholder)
                    components.append(
                        OSLogMessageComponent(
                            formatSubstring: prefix,
                            placeholder: placeholder,
                            argumentCategory: values.category,
                            argumentDoubleValue: values.double,
                            argumentInt64Value: values.int64,
                            argumentNumberValue: values.number,
                            argumentStringValue: values.string,
                            argumentUInt64Value: values.uint64
                        )
                    )
                    argIndex += 1
                } else {
                    rendered = placeholder
                }
                composed.append(prefix)
                composed.append(rendered)
                prefix = ""
                index = cursor
            } else {
                prefix.append(format[index])
                index = format.index(after: index)
            }
        }
        composed.append(prefix)
        if !args.isEmpty {
            components.append(OSLogMessageComponent.trailingEmpty())
        }
        return (composed, format, components)
    }

    private static func scanBrace(_ format: String, from start: String.Index) -> String.Index? {
        var cursor = format.index(after: start)
        while cursor < format.endIndex {
            if format[cursor] == "}" { return cursor }
            cursor = format.index(after: cursor)
        }
        return nil
    }

    private static func render(placeholder: String, arg: CVarArg) -> String {
        if isSensitive(placeholder) { return "<private>" }
        return stringify(arg)
    }

    private static func isSensitive(_ placeholder: String) -> Bool {
        placeholder.hasPrefix("%{sensitive")
    }

    private static func category(placeholder: String) -> OSLogMessageComponent.ArgumentCategory {
        if isSensitive(placeholder) { return .undefined }
        if placeholder.hasSuffix("d") || placeholder.hasSuffix("ld") || placeholder.hasSuffix("i") {
            return .int64
        }
        if placeholder.hasSuffix("f") || placeholder.hasSuffix("g") {
            return .double
        }
        return .string
    }

    private static func stringify(_ arg: CVarArg) -> String {
        if let text = arg as? String { return text }
        if let text = arg as? NSString { return text as String }
        if let number = arg as? NSNumber { return number.stringValue }
        return String(describing: arg)
    }

    private static func argumentValues(
        arg: CVarArg,
        category: OSLogMessageComponent.ArgumentCategory,
        placeholder: String
    ) -> (
        category: OSLogMessageComponent.ArgumentCategory,
        string: String?,
        int64: Int64,
        uint64: UInt64,
        double: Double,
        number: NSNumber?
    ) {
        if isSensitive(placeholder) {
            return (.undefined, nil, 0, 0, 0, nil)
        }
        if category == .int64 {
            let signed: Int64
            if let number = arg as? NSNumber {
                signed = number.int64Value
            } else if let value = arg as? Int {
                signed = Int64(value)
            } else if let value = arg as? Int64 {
                signed = value
            } else {
                signed = 0
            }
            return (.int64, nil, signed, 0, 0, NSNumber(value: signed))
        }
        let text = stringify(arg)
        return (.string, text, 0, 0, 0, nil)
    }
}
