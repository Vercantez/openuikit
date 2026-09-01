import Foundation
@preconcurrency import Dispatch

/// Portable `PKPushType` newtype. The public graph models this as a Swift
/// `RawRepresentable` string wrapper (`init(rawValue:)`, `Hashable`,
/// `Equatable`, `Sendable`). Darwin `NSString` payloads for the public
/// constants are **not** in the pinned corpus and are not claimed here.
///
/// The constant `rawValue` strings below are a **Linux-local** source-compatible
/// fallback so `.voIP` / `.complication` / `.fileProvider` compile. They are
/// not Apple-observed bytes; compare typed constants, not guessed strings.
public struct PKPushType: RawRepresentable, Hashable, Equatable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Voice-over-IP call invitations. Linux-local placeholder raw value.
    public static let voIP = PKPushType(rawValue: "PKPushTypeVoIP")

    /// WatchOS complication pushes. Deprecated on iOS in favor of delivering
    /// complication updates directly on watchOS. Linux-local placeholder raw value.
    @available(
        iOS,
        introduced: 9.0,
        deprecated: 13.0,
        message: "Complication pushes are supported directly on watchOS now, so this should no longer be used on iOS."
    )
    public static let complication = PKPushType(rawValue: "PKPushTypeComplication")

    /// File-provider change signaling. Linux-local placeholder raw value.
    public static let fileProvider = PKPushType(rawValue: "PKPushTypeFileProvider")
}

/// Device token plus push type, produced by Apple Push Notification service on
/// Darwin. Linux never mints APNs identity; host tests may construct instances
/// through `@_spi(OpenUIKitHost)` without claiming Apple provenance.
open class PKPushCredentials: NSObject, @unchecked Sendable {
    private let storedType: PKPushType
    private let storedToken: Foundation.Data

    open var type: PKPushType { storedType }
    open var token: Foundation.Data { storedToken }

    @_spi(OpenUIKitHost)
    public init(type: PKPushType, token: Foundation.Data) {
        storedType = type
        storedToken = Foundation.Data(token)
        super.init()
    }
}

/// Incoming PushKit payload. The dictionary is a local snapshot; this type
/// does not contact Apple services.
open class PKPushPayload: NSObject, @unchecked Sendable {
    private let storedType: PKPushType
    private let storedDictionary: [AnyHashable: Any]

    open var type: PKPushType { storedType }
    open var dictionaryPayload: [AnyHashable: Any] { storedDictionary }

    @_spi(OpenUIKitHost)
    public init(type: PKPushType, dictionaryPayload: [AnyHashable: Any]) {
        storedType = type
        storedDictionary = dictionaryPayload
        super.init()
    }
}

/// Delegate for `PKPushRegistry`. Optional Objective-C requirements are
/// expressed as protocol-extension defaults because Linux has no ObjC
/// runtime for `optional` protocol witnesses. The completion-handler and
/// `async` incoming-push presentations share one ObjC selector in the pinned
/// graph; the default completion witness forwards to the async requirement
/// so a Swift-only implementer still observes host-injected payloads.
public protocol PKPushRegistryDelegate: NSObjectProtocol {
    func pushRegistry(
        _ registry: PKPushRegistry,
        didUpdate pushCredentials: PKPushCredentials,
        for type: PKPushType
    )

    func pushRegistry(
        _ registry: PKPushRegistry,
        didInvalidatePushTokenFor type: PKPushType
    )

    @available(
        iOS,
        introduced: 8.0,
        deprecated: 11.0,
        message: "Use the completion-handler or async variant instead."
    )
    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType
    )

    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        completion: @escaping @Sendable () -> Void
    )

    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType
    ) async
}

extension PKPushRegistryDelegate {
    public func pushRegistry(
        _ registry: PKPushRegistry,
        didInvalidatePushTokenFor type: PKPushType
    ) {
        _ = registry
        _ = type
    }

    @available(
        iOS,
        introduced: 8.0,
        deprecated: 11.0,
        message: "Use the completion-handler or async variant instead."
    )
    public func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType
    ) {
        _ = registry
        _ = payload
        _ = type
    }

    public func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        completion: @escaping @Sendable () -> Void
    ) {
        Task {
            await self.pushRegistry(
                registry,
                didReceiveIncomingPushWith: payload,
                for: type
            )
            completion()
        }
    }

    public func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType
    ) async {
        _ = registry
        _ = payload
        _ = type
    }
}

/// Process-local push registry. Assigning `desiredPushTypes` records the
/// requested types and never talks to APNs, so `pushToken(for:)` stays `nil`
/// until a host injects credentials. Removing a type that had a cached token
/// clears it and informs the delegate; Apple identity is never fabricated.
open class PKPushRegistry: NSObject, @unchecked Sendable {
    private let callbackQueue: DispatchQueue
    private let usesMainCallbackQueue: Bool
    private let stateLock = NSLock()
    private weak var storedDelegate: (any PKPushRegistryDelegate)?
    private var storedDesiredPushTypes: Set<PKPushType>?
    private var tokens: [PKPushType: Foundation.Data] = [:]

    public init(queue: DispatchQueue?) {
        usesMainCallbackQueue = queue == nil
        callbackQueue = queue ?? DispatchQueue.main
        super.init()
    }

    open weak var delegate: (any PKPushRegistryDelegate)? {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return storedDelegate
        }
        set {
            stateLock.lock()
            storedDelegate = newValue
            stateLock.unlock()
        }
    }

    open var desiredPushTypes: Set<PKPushType>? {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return storedDesiredPushTypes
        }
        set {
            let invalidations = replaceDesiredPushTypes(newValue)
            for type in invalidations {
                deliverOnCallbackQueue { [weak self] in
                    guard let self, let delegate = self.delegate else { return }
                    delegate.pushRegistry(self, didInvalidatePushTokenFor: type)
                }
            }
        }
    }

    open func pushToken(for type: PKPushType) -> Foundation.Data? {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard storedDesiredPushTypes?.contains(type) == true else { return nil }
        return tokens[type]
    }

    @_spi(OpenUIKitHost)
    public var _portableCallbackQueue: DispatchQueue { callbackQueue }

    @_spi(OpenUIKitHost)
    public var _portableUsesMainCallbackQueue: Bool { usesMainCallbackQueue }

    /// Installs a host-supplied token for a type that was already requested.
    /// Returns `false` without mutating state when the type is not desired;
    /// this path never invents an APNs registration.
    @_spi(OpenUIKitHost)
    @discardableResult
    public func _portableInstallCredentials(_ credentials: PKPushCredentials) -> Bool {
        let type = credentials.type
        let token = credentials.token
        let accepted: Bool = withState {
            guard storedDesiredPushTypes?.contains(type) == true else { return false }
            tokens[type] = token
            return true
        }
        guard accepted else { return false }
        deliverOnCallbackQueue { [weak self] in
            guard let self, let delegate = self.delegate else { return }
            delegate.pushRegistry(self, didUpdate: credentials, for: type)
        }
        return true
    }

    /// Delivers a locally constructed payload to the completion-handler
    /// (and, via the default witness, async) incoming-push requirement.
    /// Types that were never requested are ignored.
    @_spi(OpenUIKitHost)
    @discardableResult
    public func _portableDeliverIncomingPush(
        _ payload: PKPushPayload,
        completion: (@Sendable () -> Void)? = nil
    ) -> Bool {
        let type = payload.type
        let accepted = withState { storedDesiredPushTypes?.contains(type) == true }
        guard accepted else {
            completion?()
            return false
        }
        deliverOnCallbackQueue { [weak self] in
            guard let self, let delegate = self.delegate else {
                completion?()
                return
            }
            delegate.pushRegistry(
                self,
                didReceiveIncomingPushWith: payload,
                for: type,
                completion: {
                    completion?()
                }
            )
        }
        return true
    }

    /// Invokes the deprecated three-argument incoming-push requirement.
    @_spi(OpenUIKitHost)
    @discardableResult
    public func _portableDeliverIncomingPushDeprecated(_ payload: PKPushPayload) -> Bool {
        let type = payload.type
        let accepted = withState { storedDesiredPushTypes?.contains(type) == true }
        guard accepted else { return false }
        deliverOnCallbackQueue { [weak self] in
            guard let self, let delegate = self.delegate else { return }
            delegate.pushRegistry(
                self,
                didReceiveIncomingPushWith: payload,
                for: type
            )
        }
        return true
    }

    private func withState<T>(_ body: () -> T) -> T {
        stateLock.lock()
        defer { stateLock.unlock() }
        return body()
    }

    private func replaceDesiredPushTypes(_ newValue: Set<PKPushType>?) -> [PKPushType] {
        withState {
            let previous = storedDesiredPushTypes ?? []
            let next = newValue ?? []
            storedDesiredPushTypes = newValue
            var invalidations: [PKPushType] = []
            for type in previous where !next.contains(type) {
                if tokens.removeValue(forKey: type) != nil {
                    invalidations.append(type)
                }
            }
            for type in tokens.keys where !next.contains(type) {
                tokens.removeValue(forKey: type)
            }
            return invalidations
        }
    }

    private func deliverOnCallbackQueue(_ body: @escaping @Sendable () -> Void) {
        callbackQueue.async(execute: body)
    }
}
