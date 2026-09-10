// Fail-closed stand-in for statsig-kit 1.61.0 (8c28267e), the surface
// ios-oss's Experimentation package touches (StatsigClient.swift). No network,
// no storage: the client never reports itself initialised, every gate reads
// false, every experiment/layer value is nil, and the completion is called
// once with an error so the app's own "Statsig reload error" path runs —
// the same log line the real SDK printed on the iOS 26.1 oracle with the
// demo key (ios-oss-launch.md).
import Foundation

public struct StatsigUnavailable: Error, LocalizedError {
    public var errorDescription: String? { "Statsig is not available on OpenUIKit (fail-closed shim)" }
    public init() {}
}

public struct StatsigEnvironment {
    public enum EnvironmentTier: String { case Production, Staging, Development }
    public let tier: EnvironmentTier?
    public init(tier: EnvironmentTier? = nil) { self.tier = tier }
}

public struct StatsigOptions {
    public let environment: StatsigEnvironment?
    public init(environment: StatsigEnvironment? = nil) { self.environment = environment }
}

public struct StatsigUser {
    public let userID: String?
    public let customIDs: [String: String]?
    public init(userID: String? = nil, customIDs: [String: String]? = nil) {
        self.userID = userID
        self.customIDs = customIDs
    }
}

public protocol StatsigDynamicConfigValue {}
extension Bool: StatsigDynamicConfigValue {}
extension Int: StatsigDynamicConfigValue {}
extension Double: StatsigDynamicConfigValue {}
extension String: StatsigDynamicConfigValue {}
extension Array: StatsigDynamicConfigValue {}
extension Dictionary: StatsigDynamicConfigValue {}

public struct DynamicConfig {
    public let name: String
    public func getValue<T: StatsigDynamicConfigValue>(forKey _: String) -> T? { nil }
    public func getValue<T: StatsigDynamicConfigValue>(forKey _: String, defaultValue: T) -> T { defaultValue }
}

public struct Layer {
    public let name: String
    public func getValue<T: StatsigDynamicConfigValue>(forKey _: String) -> T? { nil }
    public func getValue<T: StatsigDynamicConfigValue>(forKey _: String, defaultValue: T) -> T { defaultValue }
}

public final class StatsigClient {
    public let sdkKey: String
    public private(set) var user: StatsigUser
    public let options: StatsigOptions?

    public init(sdkKey: String, user: StatsigUser? = nil, options: StatsigOptions? = nil,
                completion: ((Error?) -> Void)? = nil) {
        self.sdkKey = sdkKey
        self.user = user ?? StatsigUser()
        self.options = options
        completion?(StatsigUnavailable())
    }

    public func isInitialized() -> Bool { false }
    public func checkGate(_ gateName: String) -> Bool { false }
    public func getExperiment(_ experimentName: String) -> DynamicConfig { DynamicConfig(name: experimentName) }
    public func getConfig(_ configName: String) -> DynamicConfig { DynamicConfig(name: configName) }
    public func getLayer(_ layerName: String) -> Layer { Layer(name: layerName) }
    public func updateUserWithResult(_ user: StatsigUser, completion: ((Error?) -> Void)? = nil) {
        self.user = user
        completion?(StatsigUnavailable())
    }
    public func openDebugView() {}
    public func shutdown() {}
}
