// Portable public OSLog framework: store, entries, and the in-process ring.
//
// Isolated Linux host gate has no `os` module. Overlay types (Logger, OSLog,
// OSSignposter) live in sibling sources and write into the ring below.
// Darwin `@_exported import os` is a later integration step (IceCubes).

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import Foundation

/// Darwin `os.os_activity_id_t` lookalike used by OSLog.framework signatures.
public typealias os_activity_id_t = UInt64
/// Darwin `os.os_signpost_id_t` lookalike used by OSLog.framework signatures.
public typealias os_signpost_id_t = UInt64

public enum OSLogPortable {
    public enum Backend: String, Sendable, Hashable {
        case standardError = "standard-error"
    }

    /// Diagnostics are synchronously written to fd 2 by the shared os runtime.
    public static let backend: Backend = .standardError

    /// Linux/machorun has no Apple unified-log daemon or libswiftos runtime.
    public static let supportsUnifiedLogging = false

    /// Event and interval signposts have visible diagnostic semantics.
    public static let supportsSignposts = true

    /// Generated and object-derived signpost IDs are meaningful per process.
    public static let signpostIdentityScope = "process-local"

    /// Fail-closed errors for OSLogStore factory methods that cannot succeed
    /// without Apple's unified-log catalog or `.logarchive` parser.
    public struct StoreError: Error, Equatable, Hashable, Sendable {
        public let code: Int

        public static let logArchiveUnavailable = StoreError(code: 1)
    }
}

// MARK: - In-process ring

/// Current-process catalog backing `OSLogStore.init(scope: .currentProcessIdentifier)`.
///
/// Capacity 4096 is a port bound (Apple's catalog is larger). Probe
/// `/tmp/oslog-probe-fw-oslog` on OpenUIKit-2x-fw-oslog, iPhone SE 3rd gen,
/// iOS 26.1, 2026-09-05: 29 current-process rows, no wrap.
enum OSLogRing {
    static let capacity = 4096
    private static let lock = NSLock()
    private static var entries: [OSLogEntry] = []

    static func append(_ entry: OSLogEntry) {
        lock.lock()
        defer { lock.unlock() }
        entries.append(entry)
        if entries.count > capacity {
            entries.removeFirst(entries.count - capacity)
        }
    }

    static func snapshot() -> [OSLogEntry] {
        lock.lock()
        defer { lock.unlock() }
        return entries
    }
}

enum OSLogProcessInfo {
    static func processName() -> String {
        ProcessInfo.processInfo.processName
    }

    static func processIdentifier() -> pid_t {
        pid_t(ProcessInfo.processInfo.processIdentifier)
    }

    /// Probe 2026-09-05 SE 2x / iOS 26.1: `sender` equals `process` ("oslogprobe").
    static func sender() -> String {
        processName()
    }

    /// Probe 2026-09-05 SE 2x / iOS 26.1: `threadIdentifier` is the Darwin
    /// `pthread_threadid_np` tid (sample 57490599), not zero.
    static func threadIdentifier() -> UInt64 {
        #if canImport(Darwin)
        var tid: UInt64 = 0
        pthread_threadid_np(nil, &tid)
        return tid
        #elseif canImport(Glibc)
        return UInt64(truncatingIfNeeded: pthread_self())
        #else
        return 0
        #endif
    }
}

enum OSLogTypeRaw {
    /// os/log.h + probe 2026-09-05: default=0 info=1 debug=2 error=16 fault=17.
    static let `default`: UInt8 = 0x00
    static let info: UInt8 = 0x01
    static let debug: UInt8 = 0x02
    static let error: UInt8 = 0x10
    static let fault: UInt8 = 0x11

    static func osType(from level: OSLogEntryLog.Level) -> UInt8 {
        switch level {
        case .debug: return debug
        case .info: return info
        case .notice: return `default`
        case .error: return error
        case .fault: return fault
        case .undefined: return `default`
        }
    }

    static func level(from osType: UInt8) -> OSLogEntryLog.Level {
        switch osType {
        case debug: return .debug
        case info: return .info
        case `default`: return .notice
        case error: return .error
        case fault: return .fault
        default: return .undefined
        }
    }

    /// Probe 2: `messageType == "default"` matches notice; `"notice"` matches none.
    static func name(from level: OSLogEntryLog.Level) -> String {
        switch level {
        case .debug: return "debug"
        case .info: return "info"
        case .notice: return "default"
        case .error: return "error"
        case .fault: return "fault"
        case .undefined: return "undefined"
        }
    }

    static func normalizeMessageType(_ value: Any?) -> Int? {
        if let number = value as? NSNumber {
            return number.intValue
        }
        if let number = value as? Int {
            return number
        }
        if let number = value as? Int64 {
            return Int(number)
        }
        if let number = value as? UInt8 {
            return Int(number)
        }
        if let text = value as? String {
            switch text {
            case "debug": return Int(debug)
            case "info": return Int(info)
            case "default": return Int(`default`)
            case "error": return Int(error)
            case "fault": return Int(fault)
            default: return nil
            }
        }
        return nil
    }
}

// MARK: - OSLogEntry

/// A unified-log entry. Apple produces instances from `OSLogStore`; this port
/// materializes them from the in-process ring `Logger` / `os_log` write into.
open class OSLogEntry: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    open var composedMessage: String { _composedMessage }
    open var date: Date { _date }
    open var storeCategory: StoreCategory { _storeCategory }

    private let _composedMessage: String
    private let _date: Date
    private let _storeCategory: StoreCategory

    /// Raw values match the pinned `dotnet/macios` `OSLogEntryStoreCategory`
    /// `NS_ENUM` order (Undefined=0 … LongTerm30=8).
    /// Probe 2026-09-05 SE 2x / iOS 26.1: current-process Logger rows are 0.
    public enum StoreCategory: Int, Sendable, Equatable, Hashable {
        case undefined = 0
        case metadata = 1
        case shortTerm = 2
        case longTermAuto = 3
        case longTerm1 = 4
        case longTerm3 = 5
        case longTerm7 = 6
        case longTerm14 = 7
        case longTerm30 = 8
    }

    init(
        composedMessage: String,
        date: Date,
        storeCategory: StoreCategory
    ) {
        self._composedMessage = composedMessage
        self._date = date
        self._storeCategory = storeCategory
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open func encode(with coder: NSCoder) {
        _ = coder
    }
}

/// Activity-region entry. Conforms to `OSLogEntryFromProcess`.
open class OSLogEntryActivity: OSLogEntry, OSLogEntryFromProcess {
    open var parentActivityIdentifier: os_activity_id_t { _parentActivityIdentifier }
    open var activityIdentifier: os_activity_id_t { _activityIdentifier }
    open var process: String { _process }
    open var processIdentifier: pid_t { _processIdentifier }
    open var sender: String { _sender }
    open var threadIdentifier: UInt64 { _threadIdentifier }

    private let _parentActivityIdentifier: os_activity_id_t
    private let _activityIdentifier: os_activity_id_t
    private let _process: String
    private let _processIdentifier: pid_t
    private let _sender: String
    private let _threadIdentifier: UInt64

    init(
        composedMessage: String,
        date: Date,
        storeCategory: StoreCategory,
        parentActivityIdentifier: os_activity_id_t,
        activityIdentifier: os_activity_id_t,
        process: String,
        processIdentifier: pid_t,
        sender: String,
        threadIdentifier: UInt64
    ) {
        self._parentActivityIdentifier = parentActivityIdentifier
        self._activityIdentifier = activityIdentifier
        self._process = process
        self._processIdentifier = processIdentifier
        self._sender = sender
        self._threadIdentifier = threadIdentifier
        super.init(
            composedMessage: composedMessage,
            date: date,
            storeCategory: storeCategory
        )
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }
}

/// Catalog boundary marker. Apple's class has no additional public fields.
open class OSLogEntryBoundary: OSLogEntry {
    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }
}

/// Process-origin metadata shared by activity, log, and signpost entries.
public protocol OSLogEntryFromProcess: AnyObject {
    var activityIdentifier: os_activity_id_t { get }
    var process: String { get }
    var processIdentifier: pid_t { get }
    var sender: String { get }
    var threadIdentifier: UInt64 { get }
}

/// A formatted log line with payload components.
open class OSLogEntryLog: OSLogEntry, OSLogEntryFromProcess, OSLogEntryWithPayload {
    /// Raw values match the pinned `dotnet/macios` `OSLogEntryLogLevel`
    /// `NS_ENUM` order (Undefined=0 … Fault=5). Probe 2026-09-05: same.
    public enum Level: Int, Sendable, Equatable, Hashable {
        case undefined = 0
        case debug = 1
        case info = 2
        case notice = 3
        case error = 4
        case fault = 5
    }

    open var level: Level { _level }
    open var activityIdentifier: os_activity_id_t { _activityIdentifier }
    open var process: String { _process }
    open var processIdentifier: pid_t { _processIdentifier }
    open var sender: String { _sender }
    open var threadIdentifier: UInt64 { _threadIdentifier }
    open var category: String { _category }
    open var components: [OSLogMessageComponent] { _components }
    open var formatString: String { _formatString }
    open var subsystem: String { _subsystem }

    private let _level: Level
    private let _activityIdentifier: os_activity_id_t
    private let _process: String
    private let _processIdentifier: pid_t
    private let _sender: String
    private let _threadIdentifier: UInt64
    private let _category: String
    private let _components: [OSLogMessageComponent]
    private let _formatString: String
    private let _subsystem: String

    init(
        composedMessage: String,
        date: Date,
        storeCategory: StoreCategory,
        level: Level,
        activityIdentifier: os_activity_id_t,
        process: String,
        processIdentifier: pid_t,
        sender: String,
        threadIdentifier: UInt64,
        category: String,
        components: [OSLogMessageComponent],
        formatString: String,
        subsystem: String
    ) {
        self._level = level
        self._activityIdentifier = activityIdentifier
        self._process = process
        self._processIdentifier = processIdentifier
        self._sender = sender
        self._threadIdentifier = threadIdentifier
        self._category = category
        self._components = components
        self._formatString = formatString
        self._subsystem = subsystem
        super.init(
            composedMessage: composedMessage,
            date: date,
            storeCategory: storeCategory
        )
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }
}

/// Signpost interval or event entry.
open class OSLogEntrySignpost: OSLogEntry, OSLogEntryFromProcess, OSLogEntryWithPayload {
    /// Raw values match the pinned `dotnet/macios` `OSLogEntrySignpostType`
    /// `NS_ENUM` order (Undefined=0 … Event=3).
    public enum SignpostType: Int, Sendable, Equatable, Hashable {
        case undefined = 0
        case intervalBegin = 1
        case intervalEnd = 2
        case event = 3
    }

    open var signpostIdentifier: os_signpost_id_t { _signpostIdentifier }
    open var signpostName: String { _signpostName }
    open var signpostType: SignpostType { _signpostType }
    open var activityIdentifier: os_activity_id_t { _activityIdentifier }
    open var process: String { _process }
    open var processIdentifier: pid_t { _processIdentifier }
    open var sender: String { _sender }
    open var threadIdentifier: UInt64 { _threadIdentifier }
    open var category: String { _category }
    open var components: [OSLogMessageComponent] { _components }
    open var formatString: String { _formatString }
    open var subsystem: String { _subsystem }

    private let _signpostIdentifier: os_signpost_id_t
    private let _signpostName: String
    private let _signpostType: SignpostType
    private let _activityIdentifier: os_activity_id_t
    private let _process: String
    private let _processIdentifier: pid_t
    private let _sender: String
    private let _threadIdentifier: UInt64
    private let _category: String
    private let _components: [OSLogMessageComponent]
    private let _formatString: String
    private let _subsystem: String

    init(
        composedMessage: String,
        date: Date,
        storeCategory: StoreCategory,
        signpostIdentifier: os_signpost_id_t,
        signpostName: String,
        signpostType: SignpostType,
        activityIdentifier: os_activity_id_t,
        process: String,
        processIdentifier: pid_t,
        sender: String,
        threadIdentifier: UInt64,
        category: String,
        components: [OSLogMessageComponent],
        formatString: String,
        subsystem: String
    ) {
        self._signpostIdentifier = signpostIdentifier
        self._signpostName = signpostName
        self._signpostType = signpostType
        self._activityIdentifier = activityIdentifier
        self._process = process
        self._processIdentifier = processIdentifier
        self._sender = sender
        self._threadIdentifier = threadIdentifier
        self._category = category
        self._components = components
        self._formatString = formatString
        self._subsystem = subsystem
        super.init(
            composedMessage: composedMessage,
            date: date,
            storeCategory: storeCategory
        )
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }
}

/// Payload fields shared by log and signpost entries.
public protocol OSLogEntryWithPayload: AnyObject {
    var category: String { get }
    var components: [OSLogMessageComponent] { get }
    var formatString: String { get }
    var subsystem: String { get }
}

// MARK: - Enumerator / message component / position

/// ObjC enumerator over `OSLogEntry`. The Swift overlay returns
/// `AnySequence<OSLogEntry>` wrapping this enumerator.
open class OSLogEnumerator: NSEnumerator {
    public struct Options: OptionSet, Sendable, Hashable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        /// Pinned `OSLogEnumeratorReverse = 0x1`.
        public static let reverse = Options(rawValue: 1)
    }

    private let items: [OSLogEntry]
    private var index = 0

    init(items: [OSLogEntry]) {
        self.items = items
        super.init()
    }

    public override func nextObject() -> Any? {
        guard index < items.count else { return nil }
        let item = items[index]
        index += 1
        return item
    }
}

/// One format placeholder plus its decoded argument.
open class OSLogMessageComponent: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    /// Raw values match the pinned `dotnet/macios`
    /// `OSLogMessageComponentArgumentCategory` `NS_ENUM` order.
    /// Probe 2026-09-05: string interpolations are 4, signed ints 3, empty 0.
    public enum ArgumentCategory: Int, Sendable, Equatable, Hashable {
        case undefined = 0
        case data = 1
        case double = 2
        case int64 = 3
        case string = 4
        case uInt64 = 5
    }

    /// Swift overlay over the ObjC argument accessors.
    public enum Argument {
        case undefined
        case data(Data)
        case double(Double)
        case signed(Int64)
        case string(String)
        case unsigned(UInt64)
    }

    open var formatSubstring: String { _formatSubstring }
    open var placeholder: String { _placeholder }
    open var argumentCategory: ArgumentCategory { _argumentCategory }
    open var argumentDataValue: Data? { _argumentDataValue }
    open var argumentDoubleValue: Double { _argumentDoubleValue }
    open var argumentInt64Value: Int64 { _argumentInt64Value }
    open var argumentNumberValue: NSNumber? { _argumentNumberValue }
    open var argumentStringValue: String? { _argumentStringValue }
    open var argumentUInt64Value: UInt64 { _argumentUInt64Value }

    open var argument: Argument {
        switch argumentCategory {
        case .undefined:
            return .undefined
        case .data:
            return .data(argumentDataValue ?? Data())
        case .double:
            return .double(argumentDoubleValue)
        case .int64:
            return .signed(argumentInt64Value)
        case .string:
            return .string(argumentStringValue ?? "")
        case .uInt64:
            return .unsigned(argumentUInt64Value)
        }
    }

    private let _formatSubstring: String
    private let _placeholder: String
    private let _argumentCategory: ArgumentCategory
    private let _argumentDataValue: Data?
    private let _argumentDoubleValue: Double
    private let _argumentInt64Value: Int64
    private let _argumentNumberValue: NSNumber?
    private let _argumentStringValue: String?
    private let _argumentUInt64Value: UInt64

    init(
        formatSubstring: String,
        placeholder: String,
        argumentCategory: ArgumentCategory,
        argumentDataValue: Data? = nil,
        argumentDoubleValue: Double = 0,
        argumentInt64Value: Int64 = 0,
        argumentNumberValue: NSNumber? = nil,
        argumentStringValue: String? = nil,
        argumentUInt64Value: UInt64 = 0
    ) {
        self._formatSubstring = formatSubstring
        self._placeholder = placeholder
        self._argumentCategory = argumentCategory
        self._argumentDataValue = argumentDataValue
        self._argumentDoubleValue = argumentDoubleValue
        self._argumentInt64Value = argumentInt64Value
        self._argumentNumberValue = argumentNumberValue
        self._argumentStringValue = argumentStringValue
        self._argumentUInt64Value = argumentUInt64Value
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open func encode(with coder: NSCoder) {
        _ = coder
    }

    /// Probe 2026-09-05: interpolated rows always carry a trailing empty
    /// undefined component; static strings are a single undefined component.
    static func trailingEmpty() -> OSLogMessageComponent {
        OSLogMessageComponent(
            formatSubstring: "",
            placeholder: "",
            argumentCategory: .undefined
        )
    }

    static func staticText(_ text: String) -> OSLogMessageComponent {
        OSLogMessageComponent(
            formatSubstring: text,
            placeholder: "",
            argumentCategory: .undefined
        )
    }
}

/// Opaque cursor into a store. Linux positions are applied against the
/// in-process ring (date lower-bound / window since the newest row).
open class OSLogPosition: NSObject {
    enum Kind: Equatable {
        case date(Date)
        case timeIntervalSinceEnd(TimeInterval)
        case timeIntervalSinceLatestBoot(TimeInterval)
    }

    let kind: Kind

    init(kind: Kind) {
        self.kind = kind
        super.init()
    }
}

// MARK: - Predicate matching

enum OSLogPredicate {
    static func matches(_ entry: OSLogEntry, predicate: NSPredicate?) -> Bool {
        guard let predicate else { return true }
#if os(Linux)
        // swift-corelibs-foundation: `init(format:)` is unavailable and
        // `predicateFormat` is deprecated (host gate is -warnings-as-errors).
        // Callers pass `NSPredicate(block:)`; evaluate against the entry.
        return predicate.evaluate(with: entry)
#else
        // Darwin: documented keys (subsystem/category/messageType/level/
        // eventMessage) are not all KVC properties of OSLogEntry. Probe
        // 2026-09-05 SE 2x / iOS 26.1: `messageType == "error"` or `== 16`.
        return eval(parse(predicate.predicateFormat), entry: entry)
#endif
    }

#if !os(Linux)
    private indirect enum Node {
        case always(Bool)
        case and([Node])
        case or([Node])
        case not(Node)
        case compare(String, Op, Atom)
    }

    private enum Op {
        case eq, ne, contains, begins, ends, gt, ge, lt, le
    }

    private enum Atom {
        case text(String)
        case number(Int)
    }

    private static func eval(_ node: Node, entry: OSLogEntry) -> Bool {
        switch node {
        case .always(let value):
            return value
        case .and(let children):
            for child in children {
                if !eval(child, entry: entry) { return false }
            }
            return true
        case .or(let children):
            for child in children {
                if eval(child, entry: entry) { return true }
            }
            return children.isEmpty
        case .not(let child):
            return !eval(child, entry: entry)
        case .compare(let key, let op, let atom):
            return compare(value(for: key, entry: entry), op, atom)
        }
    }

    private static func compare(_ lhs: Any?, _ op: Op, _ atom: Atom) -> Bool {
        let rhs: Any
        switch atom {
        case .text(let text): rhs = text
        case .number(let number): rhs = NSNumber(value: number)
        }
        switch op {
        case .eq: return equal(lhs, rhs)
        case .ne: return !equal(lhs, rhs)
        case .contains: return indexOf(stringify(lhs), stringify(rhs)) != nil
        case .begins: return stringify(lhs).hasPrefix(stringify(rhs))
        case .ends: return stringify(lhs).hasSuffix(stringify(rhs))
        case .gt: return ordered(lhs, rhs) == .orderedDescending
        case .ge:
            let o = ordered(lhs, rhs)
            return o == .orderedDescending || o == .orderedSame
        case .lt: return ordered(lhs, rhs) == .orderedAscending
        case .le:
            let o = ordered(lhs, rhs)
            return o == .orderedAscending || o == .orderedSame
        }
    }

    private static func parse(_ format: String) -> Node {
        if format == "TRUEPREDICATE" { return .always(true) }
        if format == "FALSEPREDICATE" { return .always(false) }
        return parseOr(Array(format), index: 0).node
    }

    private static func parseOr(_ chars: [Character], index: Int) -> (node: Node, index: Int) {
        var (node, i) = parseAnd(chars, index: index)
        var parts = [node]
        while true {
            i = skipSpace(chars, i)
            if matchWord(chars, i, "OR") {
                i = skipSpace(chars, i + 2)
                let next = parseAnd(chars, index: i)
                parts.append(next.node)
                i = next.index
            } else {
                break
            }
        }
        if parts.count == 1 { return (parts[0], i) }
        return (.or(parts), i)
    }

    private static func parseAnd(_ chars: [Character], index: Int) -> (node: Node, index: Int) {
        var (node, i) = parsePrimary(chars, index: index)
        var parts = [node]
        while true {
            i = skipSpace(chars, i)
            if matchWord(chars, i, "AND") {
                i = skipSpace(chars, i + 3)
                let next = parsePrimary(chars, index: i)
                parts.append(next.node)
                i = next.index
            } else {
                break
            }
        }
        if parts.count == 1 { return (parts[0], i) }
        return (.and(parts), i)
    }

    private static func parsePrimary(_ chars: [Character], index: Int) -> (node: Node, index: Int) {
        var i = skipSpace(chars, index)
        if matchWord(chars, i, "NOT") {
            i = skipSpace(chars, i + 3)
            let inner = parsePrimary(chars, index: i)
            return (.not(inner.node), inner.index)
        }
        if i < chars.count && chars[i] == "(" {
            let inner = parseOr(chars, index: i + 1)
            i = skipSpace(chars, inner.index)
            if i < chars.count && chars[i] == ")" { i += 1 }
            return (inner.node, i)
        }
        return parseCompare(chars, index: i)
    }

    private static func parseCompare(_ chars: [Character], index: Int) -> (node: Node, index: Int) {
        var i = skipSpace(chars, index)
        let keyStart = i
        while i < chars.count && isIdent(chars[i]) { i += 1 }
        let key = String(chars[keyStart..<i])
        i = skipSpace(chars, i)
        let op: Op
        if matchWord(chars, i, "CONTAINS") {
            op = .contains
            i = skipSpace(chars, i + 8)
        } else if matchWord(chars, i, "BEGINSWITH") {
            op = .begins
            i = skipSpace(chars, i + 10)
        } else if matchWord(chars, i, "ENDSWITH") {
            op = .ends
            i = skipSpace(chars, i + 8)
        } else if matchToken(chars, i, "!=") {
            op = .ne
            i = skipSpace(chars, i + 2)
        } else if matchToken(chars, i, "==") {
            op = .eq
            i = skipSpace(chars, i + 2)
        } else if matchToken(chars, i, ">=") {
            op = .ge
            i = skipSpace(chars, i + 2)
        } else if matchToken(chars, i, "<=") {
            op = .le
            i = skipSpace(chars, i + 2)
        } else if matchToken(chars, i, ">") {
            op = .gt
            i = skipSpace(chars, i + 1)
        } else if matchToken(chars, i, "<") {
            op = .lt
            i = skipSpace(chars, i + 1)
        } else if matchToken(chars, i, "=") {
            op = .eq
            i = skipSpace(chars, i + 1)
        } else {
            return (.always(true), i)
        }
        let atom: Atom
        if i < chars.count && chars[i] == "\"" {
            var j = i + 1
            var text = ""
            while j < chars.count && chars[j] != "\"" {
                text.append(chars[j])
                j += 1
            }
            if j < chars.count { j += 1 }
            atom = .text(text)
            i = j
        } else {
            let numStart = i
            if i < chars.count && (chars[i] == "-" || chars[i] == "+") { i += 1 }
            while i < chars.count && chars[i].isNumber { i += 1 }
            let raw = String(chars[numStart..<i])
            atom = .number(Int(raw) ?? 0)
        }
        return (.compare(key, op, atom), i)
    }

    private static func skipSpace(_ chars: [Character], _ index: Int) -> Int {
        var i = index
        while i < chars.count && chars[i].isWhitespace { i += 1 }
        return i
    }

    private static func isIdent(_ ch: Character) -> Bool {
        ch.isLetter || ch.isNumber || ch == "_"
    }

    private static func matchWord(_ chars: [Character], _ index: Int, _ word: String) -> Bool {
        let wordChars = Array(word)
        guard index + wordChars.count <= chars.count else { return false }
        for offset in 0..<wordChars.count {
            if chars[index + offset] != wordChars[offset] { return false }
        }
        let end = index + wordChars.count
        if end < chars.count && isIdent(chars[end]) { return false }
        return true
    }

    private static func matchToken(_ chars: [Character], _ index: Int, _ token: String) -> Bool {
        let tokenChars = Array(token)
        guard index + tokenChars.count <= chars.count else { return false }
        for offset in 0..<tokenChars.count {
            if chars[index + offset] != tokenChars[offset] { return false }
        }
        return true
    }

    private static func value(for key: String, entry: OSLogEntry) -> Any? {
        if key == "composedMessage" || key == "eventMessage" {
            return entry.composedMessage
        }
        if key == "date" { return entry.date }
        if key == "storeCategory" { return entry.storeCategory.rawValue }
        if key == "process", let from = entry as? OSLogEntryFromProcess {
            return from.process
        }
        if key == "sender", let from = entry as? OSLogEntryFromProcess {
            return from.sender
        }
        if key == "processIdentifier", let from = entry as? OSLogEntryFromProcess {
            return NSNumber(value: from.processIdentifier)
        }
        if key == "threadIdentifier", let from = entry as? OSLogEntryFromProcess {
            return NSNumber(value: from.threadIdentifier)
        }
        if key == "activityIdentifier", let from = entry as? OSLogEntryFromProcess {
            return NSNumber(value: from.activityIdentifier)
        }
        if key == "subsystem", let payload = entry as? OSLogEntryWithPayload {
            return payload.subsystem
        }
        if key == "category", let payload = entry as? OSLogEntryWithPayload {
            return payload.category
        }
        if key == "formatString", let payload = entry as? OSLogEntryWithPayload {
            return payload.formatString
        }
        if key == "eventType" {
            if entry is OSLogEntrySignpost { return "signpostEvent" }
            if entry is OSLogEntryLog { return "logEvent" }
            if entry is OSLogEntryActivity { return "activityEvent" }
            return "unknown"
        }
        if let log = entry as? OSLogEntryLog {
            if key == "level" { return log.level.rawValue }
            if key == "messageType" {
                return Int(OSLogTypeRaw.osType(from: log.level))
            }
        }
        if let sign = entry as? OSLogEntrySignpost {
            if key == "signpostName" { return sign.signpostName }
            if key == "signpostType" { return sign.signpostType.rawValue }
            if key == "signpostIdentifier" {
                return NSNumber(value: sign.signpostIdentifier)
            }
        }
        return nil
    }

    private static func equal(_ lhs: Any?, _ rhs: Any?) -> Bool {
        if lhs == nil && rhs == nil { return true }
        if let ln = OSLogTypeRaw.normalizeMessageType(lhs),
           let rn = OSLogTypeRaw.normalizeMessageType(rhs),
           (lhs is String || rhs is String || lhs is NSNumber || rhs is NSNumber) {
            if ln == rn { return true }
        }
        if let ls = lhs as? String, let rs = rhs as? String {
            return ls == rs
        }
        if let ln = lhs as? NSNumber, let rn = rhs as? NSNumber {
            return ln == rn
        }
        if let ld = lhs as? Date, let rd = rhs as? Date {
            return ld == rd
        }
        if let ls = stringifyOptional(lhs), let rs = stringifyOptional(rhs) {
            return ls == rs
        }
        return false
    }

    private static func ordered(_ lhs: Any?, _ rhs: Any?) -> ComparisonResult {
        if let ln = lhs as? NSNumber, let rn = rhs as? NSNumber {
            return ln.compare(rn)
        }
        if let ld = lhs as? Date, let rd = rhs as? Date {
            return ld.compare(rd)
        }
        return stringify(lhs).compare(stringify(rhs))
    }

    private static func stringify(_ value: Any?) -> String {
        stringifyOptional(value) ?? ""
    }

    private static func stringifyOptional(_ value: Any?) -> String? {
        guard let value else { return nil }
        if let text = value as? String { return text }
        if let number = value as? NSNumber { return number.stringValue }
        return String(describing: value)
    }

    /// Index-scan so guest sources never pull `_StringProcessing.contains`.
    private static func indexOf(_ haystack: String, _ needle: String) -> String.Index? {
        if needle.isEmpty { return haystack.startIndex }
        var index = haystack.startIndex
        while index < haystack.endIndex {
            if haystack[index...].hasPrefix(needle) { return index }
            index = haystack.index(after: index)
        }
        return nil
    }
#endif
}

enum OSLogPositionFilter {
    static func apply(_ entries: [OSLogEntry], position: OSLogPosition?) -> [OSLogEntry] {
        guard let position else { return entries }
        switch position.kind {
        case .date(let date):
            // Documented start cursor: keep rows at-or-after `date`.
            // Probe 2 on SE 2x / iOS 26.1 did not constrain currentProcessIdentifier
            // (a future date still returned 7/7). The ring applies the cursor so
            // `position(date:)` is observable; see oracle-questions.tsv.
            return entries.filter { $0.date >= date }
        case .timeIntervalSinceEnd(let seconds):
            guard let newest = entries.last else { return [] }
            let start = newest.date.addingTimeInterval(-seconds)
            return entries.filter { $0.date >= start }
        case .timeIntervalSinceLatestBoot:
            // No timesync / boot database. Keep every current-process row.
            return entries
        }
    }
}

// MARK: - OSLogStore

/// Query handle for unified-log entries.
///
/// `init(scope: .currentProcessIdentifier)` succeeds with an in-process ring
/// that `Logger` / `os_log` / `OSSignposter` append to. `init(url:)` fails
/// closed because the `.logarchive` layout is not in the public seed.
open class OSLogStore: NSObject {
    /// iOS public surface only names `currentProcessIdentifier`. The pinned
    /// macios binding records `System = 0` and `CurrentProcessIdentifier = 1`;
    /// the explicit raw value keeps `init(rawValue: 0)` failing as on iOS.
    public enum Scope: Int, Sendable, Equatable, Hashable {
        case currentProcessIdentifier = 1
    }

    private override init() {
        super.init()
    }

    public convenience init(scope: Scope) throws {
        switch scope {
        case .currentProcessIdentifier:
            self.init()
        }
    }

    public convenience init(url: URL) throws {
        _ = url
        throw OSLogPortable.StoreError.logArchiveUnavailable
    }

    public convenience init(URL url: URL) throws {
        try self.init(url: url)
    }

    open func position(date: Date) -> OSLogPosition {
        OSLogPosition(kind: .date(date))
    }

    open func position(timeIntervalSinceEnd seconds: TimeInterval) -> OSLogPosition {
        OSLogPosition(kind: .timeIntervalSinceEnd(seconds))
    }

    open func position(timeIntervalSinceLatestBoot seconds: TimeInterval) -> OSLogPosition {
        OSLogPosition(kind: .timeIntervalSinceLatestBoot(seconds))
    }

    open func getEntries(
        with options: OSLogEnumerator.Options = [],
        at position: OSLogPosition? = nil,
        matching predicate: NSPredicate? = nil
    ) throws -> AnySequence<OSLogEntry> {
        var rows = OSLogPositionFilter.apply(OSLogRing.snapshot(), position: position)
        if let predicate {
            rows = rows.filter { OSLogPredicate.matches($0, predicate: predicate) }
        }
        // Documented `OSLogEnumeratorReverse`: newest first.
        // Probe 2: Apple's Swift `getEntries(with: .reverse)` AnySequence on
        // iOS 26.1 SE stayed chronological (sameOrder=true, 7 rows). The port
        // honours the OptionSet name; see oracle-questions.tsv.
        if options.contains(.reverse) {
            rows.reverse()
        }
        let enumerator = OSLogEnumerator(items: rows)
        return AnySequence(
            AnyIterator { enumerator.nextObject() as? OSLogEntry }
        )
    }
}

enum OSLogRecord {
    static func log(
        subsystem: String,
        category: String,
        level: OSLogEntryLog.Level,
        composedMessage: String,
        formatString: String,
        components: [OSLogMessageComponent]
    ) {
        let entry = OSLogEntryLog(
            composedMessage: composedMessage,
            date: Date(),
            storeCategory: .undefined,
            level: level,
            activityIdentifier: 0,
            process: OSLogProcessInfo.processName(),
            processIdentifier: OSLogProcessInfo.processIdentifier(),
            sender: OSLogProcessInfo.sender(),
            threadIdentifier: OSLogProcessInfo.threadIdentifier(),
            category: category,
            components: components,
            formatString: formatString,
            subsystem: subsystem
        )
        OSLogRing.append(entry)
    }

    static func signpost(
        subsystem: String,
        category: String,
        name: String,
        type: OSLogEntrySignpost.SignpostType,
        identifier: os_signpost_id_t,
        composedMessage: String,
        formatString: String,
        components: [OSLogMessageComponent]
    ) {
        let entry = OSLogEntrySignpost(
            composedMessage: composedMessage,
            date: Date(),
            storeCategory: .undefined,
            signpostIdentifier: identifier,
            signpostName: name,
            signpostType: type,
            activityIdentifier: 0,
            process: OSLogProcessInfo.processName(),
            processIdentifier: OSLogProcessInfo.processIdentifier(),
            sender: OSLogProcessInfo.sender(),
            threadIdentifier: OSLogProcessInfo.threadIdentifier(),
            category: category,
            components: components,
            formatString: formatString,
            subsystem: subsystem
        )
        OSLogRing.append(entry)
    }
}
