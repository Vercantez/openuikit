import Foundation

#if canImport(Network)
import Network
#endif
#if canImport(OSLog)
import OSLog
#endif

/// Linux starting point for Apple's public `WiFiAware` module.
///
/// Value types, errors, service names, and publisher/subscriber configuration
/// compile and behave deterministically. Discovery, pairing, radio datapaths,
/// entitlements, and Network listener/browser integration stay fail-closed:
/// this host has no Wi-Fi Aware hardware or pairing daemon.
public enum WiFiAwareAvailability: Sendable {
    /// Always `false` on this Linux starting point.
    public static let isSupported = false
}

#if canImport(OSLog)
private let wiFiAwareLog = Logger(subsystem: "WiFiAware", category: "WiFiAware")
#endif

func wiFiAwareUnsupportedError() -> WAError {
#if canImport(OSLog)
    wiFiAwareLog.debug("Wi-Fi Aware is unavailable on this host")
#endif
    return .wifiAwareUnsupported(WAError.WiFiAwareUnsupportedDetails())
}

/// Features the current device supports for Wi-Fi Aware.
public struct WACapabilities: Sendable {
    /// Hardware and system features this process can actually use.
    ///
    /// Linux reports an empty set: the radio, pairing store, and entitlements
    /// are not present. ``Feature/wifiAware`` exists as a value but is never
    /// listed here.
    public static var supportedFeatures: Set<Feature> { [] }

    /// Maximum paired devices this process can connect to at once.
    public static var maximumConnectableDevices: Int { 0 }

    /// Maximum services this process can publish at once.
    public static var maximumPublishableServices: Int { 0 }

    /// Maximum services this process can subscribe to at once.
    public static var maximumSubscribableServices: Int { 0 }

    public enum Feature: Sendable, Hashable, Codable, CaseIterable {
        case wifiAware
    }
}

/// Connection performance preference for a Wi-Fi Aware datapath.
public enum WAPerformanceMode: Sendable, Hashable, Codable, CaseIterable {
    case bulk
    case realtime
}

/// 802.11 access category used by performance reports.
public enum WAAccessCategory: Sendable, Hashable, Codable, CaseIterable {
    case bestEffort
    case background
    case interactiveVideo
    case interactiveVoice
}

/// Wi-Fi Aware specific parameters applied to a Network connection.
public struct WAParameters: Sendable {
    public static let defaults = WAParameters(performanceMode: .bulk)
    public static let realtime = WAParameters(performanceMode: .realtime)

    public var performanceMode: WAPerformanceMode

    public init(performanceMode: WAPerformanceMode = .bulk) {
        self.performanceMode = performanceMode
    }
}

#if canImport(Network)
private final class WiFiAwareParameterStorage: @unchecked Sendable {
    static let shared = WiFiAwareParameterStorage()
    private let lock = NSLock()
    private var values: [ObjectIdentifier: WAParameters] = [:]

    func get(_ object: NWParameters) -> WAParameters {
        lock.lock()
        defer { lock.unlock() }
        return values[ObjectIdentifier(object)] ?? .defaults
    }

    func set(_ parameters: WAParameters, for object: NWParameters) {
        lock.lock()
        values[ObjectIdentifier(object)] = parameters
        lock.unlock()
    }
}

extension NWParameters {
    public var wifiAware: WAParameters {
        get { WiFiAwareParameterStorage.shared.get(self) }
        set { WiFiAwareParameterStorage.shared.set(newValue, for: self) }
    }

    public func wifiAware(_ configurator: (inout WAParameters) -> Void) -> Self {
        var parameters = wifiAware
        configurator(&parameters)
        wifiAware = parameters
        return self
    }
}

extension NWError {
    /// Linux `NWError` cases do not wrap ``WAError``. Always `nil`.
    public var wifiAware: WAError? { nil }
}

extension NWPath {
    /// This path is never a Wi-Fi Aware datapath on Linux.
    public var wifiAware: WAPath? {
        get async throws {
            throw wiFiAwareUnsupportedError()
        }
    }
}
#endif
