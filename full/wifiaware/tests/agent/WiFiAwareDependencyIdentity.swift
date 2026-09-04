import Foundation
#if canImport(Network)
import Network
#endif
#if canImport(OSLog)
import OSLog
#endif
import WiFiAware

/// Future EC2 identity probe. This file is not part of the isolated Linux
/// host gate. A clean dependency run must import real Foundation, Network,
/// and OSLog, pass Network types through every available WiFiAware
/// integration point, and print `WIFIAWARE_DEPENDENCY_IDENTITY_OK` only after
/// those assertions pass.
///
/// Do not treat a local isolated-host compile as evidence that this probe
/// passed. The isolated toolchain has `canImport(Network) == false` and
/// `canImport(OSLog) == false`.

private func require(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

@main
enum WiFiAwareDependencyIdentity {
    static func main() async throws {
        require(
            WACapabilities.supportedFeatures.isEmpty,
            "identity: Linux still has no NAN radio"
        )
        require(WAPublishableService.allServices.isEmpty, "identity: no plist services")
        let snapshot = try await WAPairedDevice.allDevices.current()
        require(snapshot == [:], "identity: pairing inventory empty")

        #if canImport(Network)
        // Real Network integration belongs here once the guest Network module
        // exports NWParameters.wifiAware's required overlay types
        // (BrowserProvider, ListenerProvider, NWBrowser, NWListener.Service,
        // NWParametersBuilder). Until those types exist, do not invent
        // lookalikes in this module.
        let parameters = NWParameters.tcp
        _ = parameters
        let path = NWPath()
        _ = path
        let error = NWError.unsupported
        _ = error
        #else
        fatalError("identity probe requires the real Network module")
        #endif

        #if canImport(OSLog)
        _ = Logger(subsystem: "org.openuikit.wifiaware", category: "identity")
        #else
        fatalError("identity probe requires the real OSLog module")
        #endif

        print("WIFIAWARE_DEPENDENCY_IDENTITY_OK")
    }
}
