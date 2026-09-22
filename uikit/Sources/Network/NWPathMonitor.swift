// Fail-closed NWPathMonitor for NetNewsWire RSWeb/NetworkMonitor.swift
// (`NWPathMonitor()`, `pathUpdateHandler`, `start(queue:)`, `cancel()`;
// path `status`, `availableInterfaces.first?.type`, `isExpensive`,
// `isConstrained`). Declarations follow iPhoneSimulator26.1.sdk
// Network.swiftinterface.
//
// MEASURED on Network.framework (Tools/oracle2/nwpathprobe,
// transcript-macos.txt): before `start` the path is `.unsatisfied`, reason
// `.notAvailable`, no interfaces, not expensive/constrained, no
// IPv4/IPv6/DNS, `queue` nil; `start(queue:)` calls the handler once on
// that queue; `cancel()` delivers nothing further.
//
// The port has no path source (no interface scan, no reachability), so it
// never reports connectivity: the one path it delivers is the measured
// pre-start unsatisfied path. Nothing here fabricates a network.

import Dispatch

public struct NWInterface: Hashable, CustomDebugStringConvertible, Sendable {
    public enum InterfaceType: Hashable, Sendable {
        case other
        case wifi
        case cellular
        case wiredEthernet
        case loopback
    }

    public let type: InterfaceType
    public let name: String
    public let index: Int

    public var debugDescription: String { name }
}

public struct NWPath: Equatable, CustomDebugStringConvertible, Sendable {
    public enum Status: Hashable, Sendable {
        case satisfied
        case unsatisfied
        case requiresConnection
    }

    public enum UnsatisfiedReason: Hashable, Sendable {
        case notAvailable
        case cellularDenied
        case wifiDenied
        case localNetworkDenied
        case vpnInactive
    }

    public let status: Status
    public let unsatisfiedReason: UnsatisfiedReason
    public let availableInterfaces: [NWInterface]
    public let isExpensive: Bool
    public let isConstrained: Bool
    public let supportsIPv4: Bool
    public let supportsIPv6: Bool
    public let supportsDNS: Bool

    public func usesInterfaceType(_ type: NWInterface.InterfaceType) -> Bool {
        availableInterfaces.contains { $0.type == type }
    }

    public var debugDescription: String {
        status == .satisfied ? "satisfied" : "unsatisfied (No network route)"
    }

    /// The measured pre-start path; the only path the port reports.
    static let unavailable = NWPath(
        status: .unsatisfied, unsatisfiedReason: .notAvailable, availableInterfaces: [],
        isExpensive: false, isConstrained: false, supportsIPv4: false, supportsIPv6: false, supportsDNS: false)
}

public final class NWPathMonitor: @unchecked Sendable {
    private let lock = DispatchQueue(label: "openuikit.nwpathmonitor.state")
    private var _handler: (@Sendable (_ newPath: NWPath) -> Void)?
    private var _queue: DispatchQueue?
    private var cancelled = false

    public init() {}
    public init(requiredInterfaceType: NWInterface.InterfaceType) { _ = requiredInterfaceType }
    public init(prohibitedInterfaceTypes: [NWInterface.InterfaceType]) { _ = prohibitedInterfaceTypes }

    public var currentPath: NWPath { .unavailable }

    public var queue: DispatchQueue? { lock.sync { _queue } }

    @preconcurrency public var pathUpdateHandler: (@Sendable (_ newPath: NWPath) -> Void)? {
        get { lock.sync { _handler } }
        set { lock.sync { _handler = newValue } }
    }

    public func start(queue: DispatchQueue) {
        let started: Bool = lock.sync {
            guard _queue == nil, !cancelled else { return false }
            _queue = queue
            return true
        }
        guard started else { return }
        queue.async { [self] in
            let handler: (@Sendable (NWPath) -> Void)? = lock.sync { cancelled ? nil : _handler }
            handler?(.unavailable)
        }
    }

    public func cancel() {
        lock.sync { cancelled = true }
    }
}
