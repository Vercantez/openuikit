@_exported import Foundation

/// Observed on the pinned Apple iOS 26.1 oracle: `MXErrorDomain` is the
/// string `MXErrorDomain`.
public let MXErrorDomain = "MXErrorDomain"

/// Portable counterpart of MetricKit's bridged `NS_ERROR_ENUM`.
///
/// Raw values match the pinned Apple iOS 26.1 oracle
/// (`experiment/apple-framework-oracle-20260901` @ `39c0286`):
/// `launchTaskUnknown=4`, `launchTaskInvalidID=0`, `launchTaskDuplicated=3`,
/// `launchTaskInternalFailure=5`, `launchTaskMaxCount=1`,
/// `launchTaskPastDeadline=2`.
public struct MXError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case launchTaskInvalidID = 0
        case launchTaskMaxCount = 1
        case launchTaskPastDeadline = 2
        case launchTaskDuplicated = 3
        case launchTaskUnknown = 4
        case launchTaskInternalFailure = 5
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { MXErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let launchTaskUnknown = Code.launchTaskUnknown
    public static let launchTaskInvalidID = Code.launchTaskInvalidID
    public static let launchTaskDuplicated = Code.launchTaskDuplicated
    public static let launchTaskInternalFailure = Code.launchTaskInternalFailure
    public static let launchTaskMaxCount = Code.launchTaskMaxCount
    public static let launchTaskPastDeadline = Code.launchTaskPastDeadline

    public static func == (lhs: MXError, rhs: MXError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension MXError.Code {
    public static func ~= (match: MXError.Code, error: any Error) -> Bool {
        (error as? MXError)?.code == match
    }
}

/// Typed identifier for an extended-launch measurement task.
public struct MXLaunchTaskID: RawRepresentable, Hashable, Sendable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

/// Subscriber for MetricKit metric and diagnostic payloads.
///
/// Linux never delivers Apple telemetry. Default implementations are empty so
/// the two Objective-C optional methods remain optional-like without `@objc`.
public protocol MXMetricManagerSubscriber: NSObjectProtocol {
    func didReceive(_ payloads: [MXMetricPayload])
    func didReceive(_ payloads: [MXDiagnosticPayload])
}

extension MXMetricManagerSubscriber {
    public func didReceive(_ payloads: [MXMetricPayload]) {
        _ = payloads
    }

    public func didReceive(_ payloads: [MXDiagnosticPayload]) {
        _ = payloads
    }
}

/// Shared MetricKit manager.
///
/// Linux has no MetricKit daemon. `pastPayloads` and `pastDiagnosticPayloads`
/// stay empty and subscribers are never invoked. `add(_:)` retains strongly
/// and identity-deduplicates, matching the pinned simulator observation that
/// `MXMetricManager` retained an added subscriber strongly.
///
/// Launch measurement stays fail-closed because Linux has no MetricKit
/// service. On the pinned simulator, extend of an empty task ID returned
/// success, while an immediate finish of that ID and of a never-started ID
/// threw domain `MXErrorDomain` code 5. That finite observation is not a
/// universal daemon contract; Linux does not fabricate extend success and
/// throws `MXError.launchTaskInternalFailure` (raw value 5) for both APIs.
open class MXMetricManager: NSObject, @unchecked Sendable {
    private static let _shared = MXMetricManager()

    open class var shared: MXMetricManager { _shared }

    private let lock = NSLock()
    private var subscribers: [any MXMetricManagerSubscriber] = []

    private override init() {
        super.init()
    }

    open var pastPayloads: [MXMetricPayload] { [] }

    open var pastDiagnosticPayloads: [MXDiagnosticPayload] { [] }

    open func add(_ subscriber: any MXMetricManagerSubscriber) {
        let object = subscriber as AnyObject
        lock.lock()
        if !subscribers.contains(where: { ($0 as AnyObject) === object }) {
            subscribers.append(subscriber)
        }
        lock.unlock()
    }

    open func remove(_ subscriber: any MXMetricManagerSubscriber) {
        let object = subscriber as AnyObject
        lock.lock()
        subscribers.removeAll { ($0 as AnyObject) === object }
        lock.unlock()
    }

    /// Linux has no launch-measurement OS service. Fails closed with the
    /// oracle's observed finish identity (`MXErrorDomain` code 5) rather than
    /// fabricating the pinned simulator empty-ID extend success.
    open class func extendLaunchMeasurement(forTaskID taskID: MXLaunchTaskID) throws {
        _ = taskID
        throw MXError(.launchTaskInternalFailure)
    }

    /// Linux has no launch-measurement OS service. Fails closed with
    /// `MXError.launchTaskInternalFailure` (raw value 5), the identity an
    /// immediate finish of an empty ID and of a never-started ID threw on the
    /// pinned simulator. That finite observation is not a later-task-state
    /// contract.
    open class func finishExtendedLaunchMeasurement(forTaskID taskID: MXLaunchTaskID) throws {
        _ = taskID
        throw MXError(.launchTaskInternalFailure)
    }

    @_spi(OpenUIKitHost)
    public var _portableSubscriberCount: Int {
        lock.lock()
        let count = subscribers.count
        lock.unlock()
        return count
    }

    @_spi(OpenUIKitHost)
    public func _portableContains(_ subscriber: any MXMetricManagerSubscriber) -> Bool {
        let object = subscriber as AnyObject
        lock.lock()
        let contained = subscribers.contains { ($0 as AnyObject) === object }
        lock.unlock()
        return contained
    }

    @_spi(OpenUIKitHost)
    public func _portableRemoveAllSubscribers() {
        lock.lock()
        subscribers.removeAll()
        lock.unlock()
    }
}
