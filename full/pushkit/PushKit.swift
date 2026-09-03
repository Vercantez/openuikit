@_exported import Foundation
@preconcurrency import Dispatch

// MARK: - PKPushType
//
// Swift overlay of the imported `NS_TYPED_ENUM` `PKPushType`. The three
// public static lets match macios `Field` identifiers (`PKPushTypeVoIP`,
// `PKPushTypeComplication`, `PKPushTypeFileProvider`). The exact Darwin
// NSString *payload* of those constants is unobserved in this seed; Linux
// uses the Field identifier as the raw value. That is a reconstruction
// convention, not an Apple-oracle measurement.

/// PushKit topic identifier. `Hashable` / `RawRepresentable` so a registry
/// can store `Set<PKPushType>`.
public struct PKPushType: RawRepresentable, Hashable, Sendable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// macios `Field("PKPushTypeVoIP")`. Apple NSString payload unobserved.
    public static let voIP = PKPushType(rawValue: "PKPushTypeVoIP")

    /// macios `Field("PKPushTypeComplication")`. Deprecated on iOS 13 in the
    /// graph ("use watchOS directly"); still a public identifier.
    public static let complication = PKPushType(rawValue: "PKPushTypeComplication")

    /// macios `Field("PKPushTypeFileProvider")`. Apple NSString payload unobserved.
    public static let fileProvider = PKPushType(rawValue: "PKPushTypeFileProvider")
}

// MARK: - Credentials / payload
//
// Apple's classes are `NSObject` with `DisableDefaultCtor`: the system
// constructs them. Linux exposes no public initializer. Host tests build
// in-process instances through `PushKitHostControl` without claiming APNs
// origin. `token` / `dictionaryPayload` use copy semantics (macios
// `ArgumentSemantic.Copy`).

/// Device token plus push type delivered by Apple on Darwin. Linux never
/// receives APNs credentials; locally constructed instances exist only for
/// object-model and host-test dispatch.
open class PKPushCredentials: NSObject {
    private let storedType: PKPushType
    private let storedToken: Data

    @available(*, unavailable, message: "PKPushCredentials has no public default initializer")
    public override init() {
        fatalError("PKPushCredentials() is unavailable")
    }

    init(type: PKPushType, token: Data) {
        self.storedType = type
        self.storedToken = Data(token)
        super.init()
    }

    open var type: PKPushType { storedType }

    open var token: Data { Data(storedToken) }
}

/// Incoming push body plus type. Linux never receives APNs payloads;
/// locally constructed instances exist only for the object model and
/// host-test dispatch.
open class PKPushPayload: NSObject {
    private let storedType: PKPushType
    private let storedPayload: NSDictionary

    @available(*, unavailable, message: "PKPushPayload has no public default initializer")
    public override init() {
        fatalError("PKPushPayload() is unavailable")
    }

    init(type: PKPushType, dictionaryPayload: [AnyHashable: Any]) {
        self.storedType = type
        self.storedPayload = NSDictionary(dictionary: dictionaryPayload)
        super.init()
    }

    open var type: PKPushType { storedType }

    open var dictionaryPayload: [AnyHashable: Any] {
        var copy: [AnyHashable: Any] = [:]
        storedPayload.enumerateKeysAndObjects { key, value, _ in
            guard let hashableKey = key as? AnyHashable else { return }
            copy[hashableKey] = value
        }
        return copy
    }
}

// MARK: - Host-test control
//
// Intentionally hidden from ordinary `import PushKit` clients. Not part of
// Apple's public PushKit surface. Used to occupy the registry callback
// queue and to construct in-process credentials/payloads. Delivery helpers
// hop onto that queue with `async` and never claim APNs success.
// `pushToken(for:)` stays nil.

private struct PushKitUncheckedWork: @unchecked Sendable {
    let body: () -> Void
}

@_spi(OpenUIKitHost)
public enum PushKitHostControl {
    public static func makeCredentials(type: PKPushType, token: Data) -> PKPushCredentials {
        PKPushCredentials(type: type, token: token)
    }

    public static func makePayload(
        type: PKPushType,
        dictionaryPayload: [AnyHashable: Any]
    ) -> PKPushPayload {
        PKPushPayload(type: type, dictionaryPayload: dictionaryPayload)
    }

    public static func enqueueCallbackProbe(
        _ registry: PKPushRegistry,
        _ body: @escaping () -> Void
    ) {
        registry.hostEnqueue(PushKitUncheckedWork(body: body).body)
    }

    /// Deliver a locally constructed credentials object onto the registry
    /// callback queue. Does not store an APNs token and does not make
    /// `pushToken(for:)` return non-nil.
    public static func deliverLocalCredentials(
        _ registry: PKPushRegistry,
        credentials: PKPushCredentials,
        type: PKPushType
    ) {
        registry.hostDeliverCredentials(credentials, type: type)
    }

    /// Deliver a locally constructed payload via the iOS 11+ completion
    /// path. Does not represent an Apple push.
    public static func deliverLocalIncomingPush(
        _ registry: PKPushRegistry,
        payload: PKPushPayload,
        type: PKPushType
    ) {
        registry.hostDeliverIncomingPush(payload, type: type)
    }

    /// Deliver a local invalidation callback. Linux has no Apple token to
    /// invalidate; this only exercises delegate dispatch.
    public static func deliverLocalInvalidation(
        _ registry: PKPushRegistry,
        type: PKPushType
    ) {
        registry.hostDeliverInvalidation(type: type)
    }
}
