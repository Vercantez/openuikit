import Foundation
import Dispatch
import Network
import OSLog
import WiFiAware

/// Future EC2 dependency-identity probe.
///
/// Isolated `tests/acceptance/test_host.sh` does not compile this file. A clean
/// EC2 run must:
/// 1. Build guest `os`/`OSLog`, `Network`, and Foundation modules/dylibs.
/// 2. Build `WiFiAware` with those `-I`/`-L` paths so `canImport(Network)` and
///    `canImport(OSLog)` are true.
/// 3. Link this client against `libWiFiAware.dylib` and the dependency dylibs.
/// 4. Run with `LD_LIBRARY_PATH` and confirm `libWiFiAware.dylib` loaded.
///
/// Guest Network currently has `NWParameters`, `NWPath`, `NWError`, and
/// `NWListener`, but not `NWBrowser`, `NWListener.Service`, `BrowserProvider`,
/// `ListenerProvider`, or `NWParametersBuilder`. Those WiFiAware surfaces stay
/// deferred. This file never declares a WiFiAware-owned NW lookalike.

do {
    try WiFiAwareDependencyIdentity.runBlocking {
        try await WiFiAwareDependencyIdentity.run()
    }
    print("WIFIAWARE_DEPENDENCY_IDENTITY_OK")
} catch {
    fputs("WIFIAWARE_DEPENDENCY_IDENTITY_FAILED: \(error)\n", stderr)
    exit(1)
}

private enum WiFiAwareDependencyIdentity {
    final class Box: @unchecked Sendable {
        var result: Result<Void, Error> = .success(())
    }

    static func runBlocking(_ body: @escaping @Sendable () async throws -> Void) throws {
        let box = Box()
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            do {
                try await body()
                box.result = .success(())
            } catch {
                box.result = .failure(error)
            }
            semaphore.signal()
        }
        semaphore.wait()
        try box.result.get()
    }

    static func assertNetworkType(_ type: Any.Type) {
        let name = String(reflecting: type)
        precondition(
            name.hasPrefix("Network."),
            "expected Network-owned type, got \(name)"
        )
        precondition(
            !name.contains("WiFiAware"),
            "WiFiAware-owned NW lookalike is forbidden: \(name)"
        )
    }

    static func decode<T: Decodable>(_ json: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }

    static func run() async throws {
        assertNetworkType(Network.NWParameters.self)
        assertNetworkType(Network.NWPath.self)
        assertNetworkType(Network.NWError.self)
        assertNetworkType(Network.NWListener.self)

        _ = OSLogPortable.backend
        precondition(OSLogPortable.supportsUnifiedLogging == false)
        let logger = Logger(subsystem: "WiFiAware", category: "dependency-identity")
        logger.debug("WiFiAware dependency identity against real Network and OSLog")

        let parameters: Network.NWParameters = .tcp
        precondition(parameters.wifiAware.performanceMode == .bulk)
        _ = parameters.wifiAware { $0 = .realtime }
        precondition(parameters.wifiAware.performanceMode == .realtime)
        parameters.wifiAware = .defaults
        precondition(parameters.wifiAware.performanceMode == .bulk)

        let posix = Network.NWError.posix(1)
        let dns = Network.NWError.dns(2)
        let tls = Network.NWError.tls(3)
        let unsupported = Network.NWError.unsupported
        precondition(posix.wifiAware == nil)
        precondition(dns.wifiAware == nil)
        precondition(tls.wifiAware == nil)
        precondition(unsupported.wifiAware == nil)

        let path = Network.NWPath()
        do {
            _ = try await path.wifiAware
            preconditionFailure("NWPath.wifiAware must not invent a datapath")
        } catch let error as WAError {
            if case .wifiAwareUnsupported = error {
            } else {
                preconditionFailure("expected wifiAwareUnsupported, got \(error)")
            }
        }

        let service: WAPublishableService = try decode("{\"name\":\"identity-xfer\"}")
        let publisher = WAPublisherListener.wifiAware(
            .connecting(
                to: service,
                from: .allPairedDevices,
                datapath: .realtime
            )
        )
        let listenerParameters: Network.NWParameters = .tcp
        publisher.configureParameters(listenerParameters)
        precondition(listenerParameters.wifiAware.performanceMode == .realtime)
        precondition(listenerParameters.includePeerToPeer)

        let listener = try Network.NWListener(using: listenerParameters)
        var listenerStates: [Network.NWListener.State] = []
        listener.stateUpdateHandler = { state in
            listenerStates.append(state)
        }
        listener.start(queue: DispatchQueue.main)
        precondition(!listenerStates.isEmpty)
        if case .failed(let error) = listener.state {
            precondition(error.wifiAware == nil)
        } else {
            preconditionFailure("guest NWListener must fail closed")
        }

        let subscribeService: WASubscribableService = try decode("{\"name\":\"identity-xfer\"}")
        let browser = WASubscriberBrowser.wifiAware(
            .connecting(to: .allPairedDevices, from: subscribeService)
        )
        let configured = browser.configureParameters(listener.parameters)
        precondition(configured.includePeerToPeer)
        let defaulted = browser.configureParameters(nil)
        precondition(defaulted.wifiAware.performanceMode == .bulk)

        let monitor = Network.NWPathMonitor()
        var observed: [Network.NWPath.Status] = []
        monitor.pathUpdateHandler = { update in
            observed.append(update.status)
        }
        monitor.start(queue: DispatchQueue.main)
        precondition(!observed.isEmpty)
        do {
            _ = try await monitor.currentPath.wifiAware
            preconditionFailure("path monitor snapshots are not Wi-Fi Aware datapaths")
        } catch let error as WAError {
            if case .wifiAwareUnsupported = error {
            } else {
                preconditionFailure("expected wifiAwareUnsupported, got \(error)")
            }
        }

        let asService: any WAService = service
        precondition(asService.name == "identity-xfer")

        do {
            _ = try await WAPairedDevice.allDevices.current()
            preconditionFailure("pairing store must stay fail-closed")
        } catch let error as WAError {
            if case .wifiAwareUnsupported = error {
            } else {
                preconditionFailure("expected wifiAwareUnsupported, got \(error)")
            }
        }
    }
}
