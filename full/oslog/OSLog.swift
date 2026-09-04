// Portable public OSLog framework boundary.
//
// On Darwin, the module still re-exports the lower-level `os` Logger /
// OSSignpost identity so sources may mix `import os` and `import OSLog`.
// The isolated Linux host gate has no `os` module: host-compiled sources
// import Foundation only and declare the OSLog.framework store/entry
// surface locally. Linux has no unified-log daemon; store queries are
// inert (empty) and log-archive opens fail closed.

#if canImport(os)
@_exported import os
#else
/// Darwin `os.os_activity_id_t` lookalike used by OSLog.framework signatures.
public typealias os_activity_id_t = UInt64
/// Darwin `os.os_signpost_id_t` lookalike used by OSLog.framework signatures.
public typealias os_signpost_id_t = UInt64
#endif

import Foundation

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

// MARK: - OSLogEntry

/// A unified-log entry. Apple produces instances from `OSLogStore`; Linux
/// never fabricates catalog rows, so public construction stays unavailable.
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
    /// `NS_ENUM` order (Undefined=0 … Fault=5).
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
/// `AnySequence<OSLogEntry>` instead; Linux never yields catalog rows.
open class OSLogEnumerator: NSEnumerator {
    public struct Options: OptionSet, Sendable, Hashable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        /// Pinned `OSLogEnumeratorReverse = 0x1`.
        public static let reverse = Options(rawValue: 1)
    }

    public override func nextObject() -> Any? {
        nil
    }
}

/// One format placeholder plus its decoded argument.
open class OSLogMessageComponent: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    /// Raw values match the pinned `dotnet/macios`
    /// `OSLogMessageComponentArgumentCategory` `NS_ENUM` order.
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
}

/// Opaque cursor into a store. Linux positions are tokens only; they do not
/// read an Apple timesync database.
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

// MARK: - OSLogStore

/// Query handle for unified-log entries.
///
/// `init(scope: .currentProcessIdentifier)` succeeds with an empty in-memory
/// store: Linux has no logd catalog, so the current process contributes no
/// rows. `init(url:)` / `init(URL:)` fail closed because the `.logarchive`
/// layout is not in the public seed and must not be guessed.
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
        _ = options
        _ = position
        _ = predicate
        return AnySequence([])
    }
}
