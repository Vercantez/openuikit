// Fail-closed stand-in for FirebaseRemoteConfig from firebase-ios-sdk 11.15.0
// (fdc352fa). Surface = what ios-oss touches:
//   Library/RemoteConfig/RemoteConfligClient.swift   (RemoteConfig wrapper:
//     fetchAndActivate / activate / fetch / setDefaults /
//     addOnConfigUpdateListener / configValue(forKey:))
//   Library/RemoteConfig/RemoteConfigClientType.swift (the same signatures,
//     `configValue(forKey:).boolValue`)
//   Library/MockRemoteConfigClient.swift (subclasses RemoteConfigValue with
//     `override var boolValue`, constructs `ConfigUpdateListenerRegistration()`)
//   Kickstarter-iOS/AppDelegate.swift:463-503 (`RemoteConfig.remoteConfig()`,
//     `RemoteConfigErrorDomain`, `RemoteConfigError.internalError`,
//     `RemoteConfigUpdate.updatedKeys`)
//
// Behaviour: there is no Remote Config backend. Every fetch completes once,
// on the main queue, with the failure status and an NSError in
// `RemoteConfigErrorDomain` / `.internalError` — the code the app itself
// treats as "almost certainly just a connection error" (AppDelegate.swift:
// 499-501). `activate` reports `false` with the same error. No update
// listener ever fires. Every value is the SDK's static default for an
// unknown key: empty string, false, 0, empty data, source `.static`.
// Defaults passed to `setDefaults` are NOT served back — nothing claims a
// value arrived from anywhere.
import Foundation

public let RemoteConfigErrorDomain = "com.google.remoteconfig.ErrorDomain"

public enum RemoteConfigError: Int, Error {
    case unknown = 8001
    case throttled = 8002
    case internalError = 8003
}

public enum RemoteConfigFetchStatus: Int {
    case noFetchYet
    case success
    case failure
    case throttled
}

public enum RemoteConfigFetchAndActivateStatus: Int {
    case successFetchedFromRemote
    case successUsingPreFetchedData
    case error
}

public enum RemoteConfigSource: Int {
    case remote
    case `default`
    case `static`
}

open class RemoteConfigValue: NSObject {
    public override init() { super.init() }

    open var stringValue: String { "" }
    open var numberValue: NSNumber { NSNumber(value: 0) }
    open var dataValue: Data { Data() }
    open var boolValue: Bool { false }
    open var jsonValue: Any? { nil }
    open var source: RemoteConfigSource { .static }
}

public final class RemoteConfigUpdate: NSObject {
    public let updatedKeys: Set<String>
    init(updatedKeys: Set<String>) { self.updatedKeys = updatedKeys }
}

open class ConfigUpdateListenerRegistration: NSObject {
    public override init() { super.init() }
    open func remove() {}
}

public final class RemoteConfig: NSObject {
    private static let shared = RemoteConfig()
    private override init() { super.init() }

    public static func remoteConfig() -> RemoteConfig { shared }

    /// Not SDK API: the error every fetch/activate reports.
    public static func unavailableError() -> NSError {
        NSError(domain: RemoteConfigErrorDomain, code: RemoteConfigError.internalError.rawValue, userInfo: [
            NSLocalizedDescriptionKey: "Firebase Remote Config is not available on OpenUIKit (fail-closed shim)",
        ])
    }

    public var lastFetchStatus: RemoteConfigFetchStatus { .noFetchYet }

    public func fetch(completionHandler: ((RemoteConfigFetchStatus, Error?) -> Void)? = nil) {
        guard let completionHandler else { return }
        DispatchQueue.main.async { completionHandler(.failure, Self.unavailableError()) }
    }

    public func fetchAndActivate(completionHandler: ((RemoteConfigFetchAndActivateStatus, Error?) -> Void)? = nil) {
        guard let completionHandler else { return }
        DispatchQueue.main.async { completionHandler(.error, Self.unavailableError()) }
    }

    public func activate(completion: ((Bool, Error?) -> Void)? = nil) {
        guard let completion else { return }
        DispatchQueue.main.async { completion(false, Self.unavailableError()) }
    }

    /// Accepted and not served: see the file header.
    public func setDefaults(_ defaults: [String: NSObject]?) {}

    /// Returns a registration; the listener is never called.
    public func addOnConfigUpdateListener(
        remoteConfigUpdateCompletion listener: @escaping (RemoteConfigUpdate?, Error?) -> Void
    ) -> ConfigUpdateListenerRegistration {
        ConfigUpdateListenerRegistration()
    }

    public func configValue(forKey key: String?) -> RemoteConfigValue { RemoteConfigValue() }
}
