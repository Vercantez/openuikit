import Foundation
import Network
import Security
import ExtensionFoundation
@_spi(OpenUIKitHost) import NetworkExtension

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// Future EC2 identity/ABI probe. This file is not part of the isolated Linux
/// host gate. It requires real `Network`, `Security`, and `ExtensionFoundation`
/// modules, then loads `libNetworkExtension.dylib` and exercises both the
/// legacy NetworkExtension-owned `NW*` classes and the modern dependency types.
///
/// Do not treat a local isolated-host compile as evidence that this probe passed.

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fatalError(message)
    }
}

private func requireSymbol(_ handle: UnsafeMutableRawPointer, _ name: String) {
    require(dlsym(handle, name) != nil, "missing symbol \(name)")
}

private func firstPresentSymbol(
    _ handle: UnsafeMutableRawPointer,
    _ names: [String]
) -> String {
    for name in names {
        if dlsym(handle, name) != nil {
            return name
        }
    }
    fatalError("none of the candidate symbols were present: \(names)")
}

/// Compile-time witnesses that dependency-bearing APIs take the first-party
/// types, not module-local lookalikes.
private enum DependencyWitness {
    static let setMetadata: (NEAppProxyFlow, Network.NWParameters) -> Void = {
        $0.setMetadata(on: $1)
    }

    static let assignInterface: (NEAppProxyFlow, Network.NWInterface?) -> Void = {
        $0.interface = $1
    }

    static let setIdentity: (NEHotspotEAPSettings, SecIdentity) -> Bool = {
        $0.setIdentity($1)
    }

    static let evaluateTrust: (
        any NWTCPConnectionAuthenticationDelegate,
        NWTCPConnection,
        [Any],
        @escaping (SecTrust) -> Void
    ) -> Void = { delegate, connection, chain, completion in
        delegate.evaluateTrust(
            for: connection,
            peerCertificateChain: chain,
            completionHandler: completion
        )
    }

    static let provideIdentity: (
        any NWTCPConnectionAuthenticationDelegate,
        NWTCPConnection,
        @escaping (SecIdentity, [Any]) -> Void
    ) -> Void = { delegate, connection, completion in
        delegate.provideIdentity(for: connection, completionHandler: completion)
    }
}

private final class IdentityAuthDelegate: NSObject, NWTCPConnectionAuthenticationDelegate {}

private final class HostPacketTunnel: NEPacketTunnelProvider {
    override func startTunnel(options: [String: NSObject]? = nil) async throws {
        try await super.startTunnel(options: options)
    }
}

@available(iOS 26.0, macOS 26.0, *)
private func exerciseURLFilterControl<E: NEURLFilterControlProvider>(
    _ provider: E
) async {
    let prefilter = try? await provider.fetchPrefilter(existingPrefilterTag: nil)
    require(prefilter == nil, "URL filter control invented a prefilter")
}

@main
enum NetworkExtensionDependencyIdentity {
    static func main() async {
        exerciseLegacyNetworkExtensionTypes()
        exerciseModernNetworkTypes()
        exerciseSecurityWitnesses()
        await exerciseExtensionFoundationTypes()
        await exerciseCallbackScheduling()
        inspectLoadedDylib()
        print("NETWORKEXTENSION_DEPENDENCY_IDENTITY_OK")
    }

    static func exerciseLegacyNetworkExtensionTypes() {
        let host = NetworkExtension.NWHostEndpoint(hostname: "example.invalid", port: "443")
        require(host.hostname == "example.invalid", "legacy NWHostEndpoint drifted")
        let endpoint: NetworkExtension.NWEndpoint = host
        let path = NetworkExtension.NWPath(status: .unsatisfied)
        require(path.status == .unsatisfied, "legacy NWPath drifted")
        let tcp = NetworkExtension.NWTCPConnection(endpoint: endpoint)
        require(tcp.state == .disconnected, "legacy NWTCPConnection drifted")
        let udp = NetworkExtension.NWUDPSession(endpoint: endpoint)
        require(udp.state == .failed, "legacy NWUDPSession drifted")
        _ = NetworkExtension.NWTLSParameters()
        _ = tcp
        _ = udp
    }

    static func exerciseModernNetworkTypes() {
        let parameters: Network.NWParameters = NWParameters.tcp
        require(
            ObjectIdentifier(NWParameters.self) == ObjectIdentifier(Network.NWParameters.self),
            "NWParameters is not the Network module type"
        )
        require(
            ObjectIdentifier(NWInterface.self) == ObjectIdentifier(Network.NWInterface.self),
            "NWInterface is not the Network module type"
        )

        let flow = NEAppProxyTCPFlow()
        DependencyWitness.setMetadata(flow, parameters)
        let tunnel = NEPacketTunnelProvider()
        let iface: Network.NWInterface? = tunnel.virtualInterface
        DependencyWitness.assignInterface(flow, iface)

        let modernHost = Network.NWEndpoint.Host("example.invalid")
        let modernPort = Network.NWEndpoint.Port.https
        let modern = Network.NWEndpoint.hostPort(host: modernHost, port: modernPort)
        let legacy = NetworkExtension.NWHostEndpoint(hostname: "example.invalid", port: "443")
        require(
            ObjectIdentifier(type(of: modern as Any))
                != ObjectIdentifier(type(of: legacy as Any)),
            "legacy NWEndpoint class collided with Network.NWEndpoint"
        )
    }

    static func exerciseSecurityWitnesses() {
        require(
            ObjectIdentifier(SecIdentity.self) == ObjectIdentifier(Security.SecIdentity.self),
            "SecIdentity is not the Security module type"
        )
        require(
            ObjectIdentifier(SecTrust.self) == ObjectIdentifier(Security.SecTrust.self),
            "SecTrust is not the Security module type"
        )
        _ = DependencyWitness.setIdentity
        _ = DependencyWitness.evaluateTrust
        _ = DependencyWitness.provideIdentity
        let delegate = IdentityAuthDelegate()
        let connection = NWTCPConnection(
            endpoint: NWHostEndpoint(hostname: "example.invalid", port: "443")
        )
        require(delegate.shouldEvaluateTrust(for: connection) == false, "trust default drifted")
        require(delegate.shouldProvideIdentity(for: connection) == false, "identity default drifted")
    }

    static func exerciseExtensionFoundationTypes() async {
        let configuration = NEURLFilterControlProviderConfiguration()
        _ = configuration
        let evaluation = NEHotspotEvaluationProviderConfiguration()
        _ = evaluation
        let _: NEURLFilterControlProvider.Protocol = NEURLFilterControlProvider.self
        let _: NEHotspotEvaluationProvider.Protocol = NEHotspotEvaluationProvider.self
        let _: NEHotspotAuthenticationProvider.Protocol = NEHotspotAuthenticationProvider.self
        _ = exerciseURLFilterControl
    }

    static func exerciseCallbackScheduling() async {
        let tunnel: NEProvider = HostPacketTunnel()
        let endpoint = NetworkExtension.NWHostEndpoint(hostname: "example.invalid", port: "80")
        let connection = tunnel.createTCPConnection(
            to: endpoint,
            enableTLS: false,
            tlsParameters: nil,
            delegate: nil
        )
        require(connection.endpoint === endpoint, "existential TCP factory drifted")

        var returned = false
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            NEVPNManager.shared().loadFromPreferences { error in
                require(returned, "identity probe callback ran inline")
                require(
                    NetworkExtensionHostCallback.isCurrentQueue,
                    "identity probe callback missed host queue"
                )
                require(error != nil, "loadFromPreferences must fail closed")
                continuation.resume()
            }
            returned = true
        }
    }

    static func inspectLoadedDylib() {
        let path = CommandLine.arguments.dropFirst().first ?? "libNetworkExtension.dylib"
        guard let handle = dlopen(path, RTLD_NOW) else {
            let message = String(cString: dlerror())
            fatalError("dlopen failed for \(path): \(message)")
        }
        defer { dlclose(handle) }

        _ = firstPresentSymbol(handle, [
            "$s16NetworkExtension16NEVPNErrorDomainSSvp",
            "_NEVPNErrorDomain",
            "NEVPNErrorDomain"
        ])
        requireSymbol(
            handle,
            "$s16NetworkExtension14NWHostEndpointC8hostname4portACSS_SStcfC"
        )
        requireSymbol(handle, "$s16NetworkExtension10NWEndpointCMa")
        require(
            dlsym(handle, "NWParameters") == nil,
            "libNetworkExtension.dylib exported a module-local NWParameters lookalike"
        )
        require(
            dlsym(handle, "$s16NetworkExtension12NWParametersCMa") == nil,
            "libNetworkExtension.dylib defined NetworkExtension.NWParameters"
        )
        require(
            dlsym(handle, "$s16NetworkExtension11NWInterfaceVMa") == nil,
            "libNetworkExtension.dylib defined NetworkExtension.NWInterface"
        )
    }
}
