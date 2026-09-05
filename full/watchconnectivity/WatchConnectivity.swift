@_exported import Foundation
import Dispatch

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
        return NSDictionary(dictionary: lhs.userInfo).isEqual(
            NSDictionary(dictionary: rhs.userInfo)
        )
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
///
/// The public WCSession header delivers every delegate method on one serial
/// background queue that is never the main queue.
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

    /// Public WCSession.h contract: every `WCSessionDelegate` method is
    /// invoked on one serial background queue that is never the main queue.
    private let delegateQueue = DispatchQueue(
        label: "WatchConnectivity.WCSession.delegate",
        qos: .utility
    )
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
    /// service, so the session stays `.notActivated`. When a delegate is set,
    /// it is told so on the session's serial non-main delegate queue.
    open func activate() {
        let currentDelegate = delegate
        guard let currentDelegate else {
            return
        }
        enqueueDelegate { [weak self] in
            guard let self else { return }
            currentDelegate.session(
                self,
                activationDidCompleteWith: .notActivated,
                error: WCError(.sessionNotSupported)
            )
        }
    }

    open func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?,
        errorHandler: ((any Error) -> Void)? = nil
    ) {
        _ = replyHandler
        let error = sendingError(for: message)
        guard let errorHandler else { return }
        enqueueDelegate {
            errorHandler(error)
        }
    }

    open func sendMessageData(
        _ data: Data,
        replyHandler: ((Data) -> Void)?,
        errorHandler: ((any Error) -> Void)? = nil
    ) {
        _ = (data, replyHandler)
        guard let errorHandler else { return }
        let error = sessionFailureError()
        enqueueDelegate {
            errorHandler(error)
        }
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
        enqueueDelegate { [weak self] in
            guard let self else { return }
            self.delegate?.session(self, didFinish: transfer, error: error)
        }
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
        enqueueDelegate { [weak self] in
            guard let self else { return }
            self.delegate?.session(self, didFinish: transfer, error: error)
        }
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

    private func enqueueDelegate(_ body: @escaping () -> Void) {
        let work = WatchConnectivityDelegateWork(body: body)
        delegateQueue.async {
            work.run()
        }
    }
}

/// `@Sendable` box so delegate work can hop onto the serial queue under
/// Swift 6 without claiming Apple Watch transport is Sendable.
private struct WatchConnectivityDelegateWork: @unchecked Sendable {
    let body: () -> Void
    func run() { body() }
}

/// Property-list screening using Foundation's canonical identities
/// (`NSString`, `NSNumber`, `NSDate`, `NSData`, `NSArray`, `NSDictionary`
/// with `NSString` keys). `NSNull` is not a property-list value. Exact Apple
/// size limits are private TBD symbols and are not enforced here.
enum WatchConnectivityPayload {
    static func isPropertyListDictionary(_ dictionary: [String: Any]) -> Bool {
        isCanonicalPropertyListValue(NSDictionary(dictionary: dictionary))
    }

    static func isCanonicalPropertyListValue(_ value: Any) -> Bool {
        if value is NSNull {
            return false
        }
        if value is NSString || value is NSNumber || value is NSDate || value is NSData {
            return true
        }
        if let array = value as? NSArray {
            for element in array {
                if !isCanonicalPropertyListValue(element) {
                    return false
                }
            }
            return true
        }
        if let dictionary = value as? NSDictionary {
            for key in dictionary.allKeys {
                guard key is NSString else { return false }
                guard isCanonicalPropertyListValue(dictionary[key] as Any) else {
                    return false
                }
            }
            return true
        }
        return false
    }
}
