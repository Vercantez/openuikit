import Foundation

/// Portable Linux starting point for Apple's public `WiFiAware` module.
///
/// Object-model types, Codable empty error details, parameter values, and
/// fail-closed empty pairing/service inventories are real in-process values.
/// This module never invents a NAN radio, paired device, entitlement grant,
/// or successful publish/subscribe session. Network overlay APIs
/// (`NWParameters.wifiAware`, browser/listener providers) are omitted from
/// this isolated compile because the host Swift toolchain has no `Network`
/// module; those rows stay `deferred`.

/// Features that a host device can support.
public struct WACapabilities: Sendable {
    public enum Feature: Sendable, Hashable, Codable, CaseIterable {
        case wifiAware
    }

    /// Linux has no NAN radio. Apple documents an empty set when unsupported.
    public static var supportedFeatures: Set<Feature> { [] }

    /// No connectable NAN peers exist on this host.
    public static var maximumConnectableDevices: Int { 0 }

    /// No Info.plist Wi-Fi Aware publish inventory exists on this host.
    public static var maximumPublishableServices: Int { 0 }

    /// No Info.plist Wi-Fi Aware subscribe inventory exists on this host.
    public static var maximumSubscribableServices: Int { 0 }
}

/// Performance criterion for a Wi-Fi Aware datapath.
public enum WAPerformanceMode: Sendable, Hashable, Codable, CaseIterable {
    case bulk
    case realtime
}

/// Wi-Fi layer quality-of-service used to transmit packets.
public enum WAAccessCategory: Sendable, Hashable, Codable, CaseIterable {
    case bestEffort
    case background
    case interactiveVideo
    case interactiveVoice
}

/// Parameters configuring a Wi-Fi Aware data path connection.
public struct WAParameters: Sendable {
    public var performanceMode: WAPerformanceMode

    public static let defaults = WAParameters(performanceMode: .bulk)
    public static let realtime = WAParameters(performanceMode: .realtime)

    public init(performanceMode: WAPerformanceMode = .bulk) {
        self.performanceMode = performanceMode
    }
}
