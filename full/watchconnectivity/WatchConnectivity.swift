@_exported import Foundation

/// Apple's public WatchConnectivity error domain. The ObjC constant is
/// exported as `_WCErrorDomain`; the Swift overlay exposes this string.
public let WCErrorDomain = "WCErrorDomain"

/// Portable counterpart of WatchConnectivity's bridged `NS_ERROR_ENUM`.
///
/// Numeric codes follow the public `WCErrorCode` enumeration from the
/// Xcode 26.1 iPhoneOS SDK (`genericError = 7001` through
/// `watchOnlyApp = 7019`). Stored `userInfo` is preserved exactly; this
/// overlay does not insert a default localized-description entry.
public struct WCError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case genericError = 7001
        case sessionNotSupported = 7002
        case sessionMissingDelegate = 7003
        case sessionNotActivated = 7004
        case deviceNotPaired = 7005
        case watchAppNotInstalled = 7006
        case notReachable = 7007
        case invalidParameter = 7008
        case payloadTooLarge = 7009
        case payloadUnsupportedTypes = 7010
        case messageReplyFailed = 7011
        case messageReplyTimedOut = 7012
        case fileAccessDenied = 7013
        case deliveryFailed = 7014
        case insufficientSpace = 7015
        case sessionInactive = 7016
        case transferTimedOut = 7017
        case companionAppNotInstalled = 7018
        case watchOnlyApp = 7019
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { WCErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let genericError = Code.genericError
    public static let sessionNotSupported = Code.sessionNotSupported
    public static let sessionMissingDelegate = Code.sessionMissingDelegate
    public static let sessionNotActivated = Code.sessionNotActivated
    public static let deviceNotPaired = Code.deviceNotPaired
    public static let watchAppNotInstalled = Code.watchAppNotInstalled
    public static let notReachable = Code.notReachable
    public static let invalidParameter = Code.invalidParameter
    public static let payloadTooLarge = Code.payloadTooLarge
    public static let payloadUnsupportedTypes = Code.payloadUnsupportedTypes
    public static let messageReplyFailed = Code.messageReplyFailed
    public static let messageReplyTimedOut = Code.messageReplyTimedOut
    public static let fileAccessDenied = Code.fileAccessDenied
    public static let deliveryFailed = Code.deliveryFailed
    public static let insufficientSpace = Code.insufficientSpace
    public static let sessionInactive = Code.sessionInactive
    public static let transferTimedOut = Code.transferTimedOut
    public static let companionAppNotInstalled = Code.companionAppNotInstalled
    public static let watchOnlyApp = Code.watchOnlyApp

    public static func == (lhs: WCError, rhs: WCError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension WCError.Code {
    /// Allow matching a WatchConnectivity error code against an arbitrary error.
    public static func ~= (match: WCError.Code, error: any Error) -> Bool {
        (error as? WCError)?.code == match
    }
}

/// Activation state of a `WCSession`. Linux never leaves `.notActivated`
/// because there is no paired Apple Watch or WatchConnectivity daemon.
public enum WCSessionActivationState: Int, Hashable, Sendable {
    case notActivated = 0
    case inactive = 1
    case activated = 2
}

/// Delegate for session activation, reachability, and payload delivery.
///
/// Incoming message, file, user-info, and application-context callbacks never
/// fire on Linux: there is no counterpart device. Optional methods have empty
/// defaults matching Apple's ObjC optional protocol requirements.
public protocol WCSessionDelegate: NSObjectProtocol {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    )
    func sessionDidBecomeInactive(_ session: WCSession)
    func sessionDidDeactivate(_ session: WCSession)
    func sessionWatchStateDidChange(_ session: WCSession)
    func sessionReachabilityDidChange(_ session: WCSession)
    func session(_ session: WCSession, didReceiveMessage message: [String: Any])
    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    )
    func session(_ session: WCSession, didReceiveMessageData messageData: Data)
    func session(
        _ session: WCSession,
        didReceiveMessageData messageData: Data,
        replyHandler: @escaping (Data) -> Void
    )
    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    )
    func session(
        _ session: WCSession,
        didFinish userInfoTransfer: WCSessionUserInfoTransfer,
        error: (any Error)?
    )
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any])
    func session(
        _ session: WCSession,
        didFinish fileTransfer: WCSessionFileTransfer,
        error: (any Error)?
    )
    func session(_ session: WCSession, didReceive file: WCSessionFile)
}

extension WCSessionDelegate {
    public func sessionWatchStateDidChange(_ session: WCSession) {
        _ = session
    }

    public func sessionReachabilityDidChange(_ session: WCSession) {
        _ = session
    }

    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        _ = (session, message)
    }

    public func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        _ = (session, message, replyHandler)
    }

    public func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        _ = (session, messageData)
    }

    public func session(
        _ session: WCSession,
        didReceiveMessageData messageData: Data,
        replyHandler: @escaping (Data) -> Void
    ) {
        _ = (session, messageData, replyHandler)
    }

    public func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        _ = (session, applicationContext)
    }

    public func session(
        _ session: WCSession,
        didFinish userInfoTransfer: WCSessionUserInfoTransfer,
        error: (any Error)?
    ) {
        _ = (session, userInfoTransfer, error)
    }

    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        _ = (session, userInfo)
    }

    public func session(
        _ session: WCSession,
        didFinish fileTransfer: WCSessionFileTransfer,
        error: (any Error)?
    ) {
        _ = (session, fileTransfer, error)
    }

    public func session(_ session: WCSession, didReceive file: WCSessionFile) {
        _ = (session, file)
    }
}

/// A file payload associated with a session file transfer.
open class WCSessionFile: NSObject {
    public let fileURL: URL
    public let metadata: [String: Any]?

    init(fileURL: URL, metadata: [String: Any]?) {
        self.fileURL = fileURL
        self.metadata = metadata
        super.init()
    }
}

/// An in-flight or finished file transfer. Linux never starts a real transfer.
open class WCSessionFileTransfer: NSObject {
    public let file: WCSessionFile
    public let progress: Progress
    private let lock = NSLock()
    private var transferring = false

    init(file: WCSessionFile, progress: Progress) {
        self.file = file
        self.progress = progress
        super.init()
    }

    public var isTransferring: Bool {
        lock.lock()
        defer { lock.unlock() }
        return transferring
    }

    public func cancel() {
        lock.lock()
        transferring = false
        lock.unlock()
        progress.cancel()
    }
}

/// A dictionary payload queued for the counterpart. Linux never delivers it.
/// Apple's class conforms to `NSSecureCoding`; decoding fails closed because
/// the on-disk archive keys are not part of the public graph.
open class WCSessionUserInfoTransfer: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let isCurrentComplicationInfo: Bool
    public let userInfo: [String: Any]
    private let lock = NSLock()
    private var transferring = false

    init(userInfo: [String: Any], isCurrentComplicationInfo: Bool) {
        self.userInfo = userInfo
        self.isCurrentComplicationInfo = isCurrentComplicationInfo
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }

    public var isTransferring: Bool {
        lock.lock()
        defer { lock.unlock() }
        return transferring
    }

    public func cancel() {
        lock.lock()
        transferring = false
        lock.unlock()
    }
}

/// Linux has no Apple Watch pairing, WatchConnectivity daemon, or
/// complication budget. `isSupported()` is therefore `false`, the default
/// session stays `.notActivated`, and every send or transfer fails closed.
/// Fabricating a paired watch, reachable counterpart, or delivered payload
/// would be a device-service lie.
open class WCSession: NSObject {
    private static let defaultSession = WCSession()
    private let lock = NSLock()
    private weak var sessionDelegate: (any WCSessionDelegate)?
    private var storedApplicationContext: [String: Any] = [:]
    private var storedReceivedApplicationContext: [String: Any] = [:]
    private var storedOutstandingFileTransfers: [WCSessionFileTransfer] = []
    private var storedOutstandingUserInfoTransfers: [WCSessionUserInfoTransfer] = []

    private override init() {
        super.init()
    }

    open class func isSupported() -> Bool { false }

    open class var `default`: WCSession { defaultSession }

    open weak var delegate: (any WCSessionDelegate)? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return sessionDelegate
        }
        set {
            lock.lock()
            sessionDelegate = newValue
            lock.unlock()
        }
    }

    open var activationState: WCSessionActivationState { .notActivated }
    open var hasContentPending: Bool { false }
    open var isPaired: Bool { false }
    open var isWatchAppInstalled: Bool { false }
    open var isComplicationEnabled: Bool { false }
    open var watchDirectoryURL: URL? { nil }
    open var isReachable: Bool { false }
    open var remainingComplicationUserInfoTransfers: Int { 0 }

    open var applicationContext: [String: Any] {
        lock.lock()
        defer { lock.unlock() }
        return storedApplicationContext
    }

    open var receivedApplicationContext: [String: Any] {
        lock.lock()
        defer { lock.unlock() }
        return storedReceivedApplicationContext
    }

    open var outstandingFileTransfers: [WCSessionFileTransfer] {
        lock.lock()
        defer { lock.unlock() }
        return storedOutstandingFileTransfers
    }

    open var outstandingUserInfoTransfers: [WCSessionUserInfoTransfer] {
        lock.lock()
        defer { lock.unlock() }
        return storedOutstandingUserInfoTransfers
    }

    /// Attempts to activate the session. Linux has no WatchConnectivity
    /// service, so the session stays `.notActivated` and the delegate is
    /// told so immediately. Callback queue parity with Apple is an oracle
    /// question; this overlay delivers fail-closed on the calling thread.
    open func activate() {
        let currentDelegate = delegate
        guard let currentDelegate else {
            return
        }
        currentDelegate.session(
            self,
            activationDidCompleteWith: .notActivated,
            error: WCError(.sessionNotSupported)
        )
    }

    open func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?,
        errorHandler: ((any Error) -> Void)? = nil
    ) {
        _ = replyHandler
        let error = sendingError(for: message)
        errorHandler?(error)
    }

    open func sendMessageData(
        _ data: Data,
        replyHandler: ((Data) -> Void)?,
        errorHandler: ((any Error) -> Void)? = nil
    ) {
        _ = (data, replyHandler)
        errorHandler?(sessionFailureError())
    }

    open func updateApplicationContext(_ applicationContext: [String: Any]) throws {
        if !WatchConnectivityPayload.isPropertyListDictionary(applicationContext) {
            throw WCError(.payloadUnsupportedTypes)
        }
        throw sessionFailureError()
    }

    @discardableResult
    open func transferUserInfo(_ userInfo: [String: Any] = [:]) -> WCSessionUserInfoTransfer {
        finishUserInfoTransfer(userInfo, isCurrentComplicationInfo: false)
    }

    @discardableResult
    open func transferCurrentComplicationUserInfo(
        _ userInfo: [String: Any] = [:]
    ) -> WCSessionUserInfoTransfer {
        finishUserInfoTransfer(userInfo, isCurrentComplicationInfo: true)
    }

    @discardableResult
    open func transferFile(_ file: URL, metadata: [String: Any]?) -> WCSessionFileTransfer {
        let error: WCError
        if let metadata, !WatchConnectivityPayload.isPropertyListDictionary(metadata) {
            error = WCError(.payloadUnsupportedTypes)
        } else if !file.isFileURL {
            error = WCError(.invalidParameter)
        } else if !FileManager.default.isReadableFile(atPath: file.path) {
            error = WCError(.fileAccessDenied)
        } else {
            error = sessionFailureError()
        }

        let payload = WCSessionFile(fileURL: file, metadata: metadata)
        let progress = Progress(totalUnitCount: 1)
        progress.cancel()
        let transfer = WCSessionFileTransfer(file: payload, progress: progress)
        delegate?.session(self, didFinish: transfer, error: error)
        return transfer
    }

    private func finishUserInfoTransfer(
        _ userInfo: [String: Any],
        isCurrentComplicationInfo: Bool
    ) -> WCSessionUserInfoTransfer {
        let error: WCError
        if !WatchConnectivityPayload.isPropertyListDictionary(userInfo) {
            error = WCError(.payloadUnsupportedTypes)
        } else {
            error = sessionFailureError()
        }
        let transfer = WCSessionUserInfoTransfer(
            userInfo: userInfo,
            isCurrentComplicationInfo: isCurrentComplicationInfo
        )
        delegate?.session(self, didFinish: transfer, error: error)
        return transfer
    }

    private func sendingError(for message: [String: Any]) -> WCError {
        if !WatchConnectivityPayload.isPropertyListDictionary(message) {
            return WCError(.payloadUnsupportedTypes)
        }
        return sessionFailureError()
    }

    private func sessionFailureError() -> WCError {
        if !Self.isSupported() {
            return WCError(.sessionNotSupported)
        }
        if activationState != .activated {
            return WCError(.sessionNotActivated)
        }
        if delegate == nil {
            return WCError(.sessionMissingDelegate)
        }
        if !isReachable {
            return WCError(.notReachable)
        }
        return WCError(.sessionNotSupported)
    }
}

/// Local property-list screening. Exact Apple size limits are private TBD
/// symbols and are not enforced here.
enum WatchConnectivityPayload {
    static func isPropertyListDictionary(_ dictionary: [String: Any]) -> Bool {
        dictionary.values.allSatisfy(isPropertyListValue)
    }

    static func isPropertyListValue(_ value: Any) -> Bool {
        if value is NSNull { return true }
        if value is String || value is NSString { return true }
        if value is Data || value is NSData { return true }
        if value is Date || value is NSDate { return true }
        if value is Bool { return true }
        if value is Int || value is Int8 || value is Int16 || value is Int32 || value is Int64 {
            return true
        }
        if value is UInt || value is UInt8 || value is UInt16 || value is UInt32 || value is UInt64 {
            return true
        }
        if value is Float || value is Double { return true }
        if value is NSNumber { return true }
        if let array = value as? [Any] {
            return array.allSatisfy(isPropertyListValue)
        }
        if let dictionary = value as? [String: Any] {
            return dictionary.values.allSatisfy(isPropertyListValue)
        }
        if let dictionary = value as? NSDictionary {
            for (key, element) in dictionary {
                guard key is String || key is NSString else { return false }
                if !isPropertyListValue(element) { return false }
            }
            return true
        }
        if let array = value as? NSArray {
            for element in array {
                if !isPropertyListValue(element) { return false }
            }
            return true
        }
        return false
    }
}
