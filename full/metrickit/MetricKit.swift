@_exported import Foundation

/// Linux-local value of `MXErrorDomain`. Apple's exact domain string is not in
/// the pinned public inputs; see `oracle-questions.tsv`.
public let MXErrorDomain = "MXErrorDomain"

/// Portable counterpart of MetricKit's bridged `NS_ERROR_ENUM`.
///
/// Numeric codes follow the public sequential `MXErrorCode` enumeration from
/// Xcode 26.1 `MXError.h` (`launchTaskUnknown = 0` through
/// `launchTaskPastDeadline = 5`). Confirm on an Apple runtime before treating
/// these integers as ABI-stable.
public struct MXError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case launchTaskUnknown = 0
        case launchTaskInvalidID = 1
        case launchTaskDuplicated = 2
        case launchTaskInternalFailure = 3
        case launchTaskMaxCount = 4
        case launchTaskPastDeadline = 5
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
/// Linux has no MetricKit daemon, so `pastPayloads` and
/// `pastDiagnosticPayloads` are always empty, subscribers are recorded but
/// never invoked, and launch-measurement APIs fail closed.
open class MXMetricManager: NSObject, @unchecked Sendable {
    private static let _shared = MXMetricManager()

    open class var shared: MXMetricManager { _shared }

    private let lock = NSLock()
    private var subscribers: [WeakMXSubscriber] = []

    private override init() {
        super.init()
    }

    open var pastPayloads: [MXMetricPayload] { [] }

    open var pastDiagnosticPayloads: [MXDiagnosticPayload] { [] }

    open func add(_ subscriber: any MXMetricManagerSubscriber) {
        let object = subscriber as AnyObject
        lock.lock()
        subscribers.removeAll { $0.object == nil || $0.object === object }
        subscribers.append(WeakMXSubscriber(object))
        lock.unlock()
    }

    open func remove(_ subscriber: any MXMetricManagerSubscriber) {
        let object = subscriber as AnyObject
        lock.lock()
        subscribers.removeAll { $0.object == nil || $0.object === object }
        lock.unlock()
    }

    /// Linux has no launch-measurement OS service. Always fails closed.
    open class func extendLaunchMeasurement(forTaskID taskID: MXLaunchTaskID) throws {
        _ = taskID
        throw MXError(.launchTaskInternalFailure)
    }

    /// Linux never successfully starts an extended launch measurement.
    open class func finishExtendedLaunchMeasurement(forTaskID taskID: MXLaunchTaskID) throws {
        _ = taskID
        throw MXError(.launchTaskUnknown)
    }

    @_spi(OpenUIKitHost)
    public var _portableSubscriberCount: Int {
        lock.lock()
        subscribers.removeAll { $0.object == nil }
        let count = subscribers.count
        lock.unlock()
        return count
    }
}

private final class WeakMXSubscriber {
    weak var object: AnyObject?

    init(_ object: AnyObject) {
        self.object = object
    }
}
