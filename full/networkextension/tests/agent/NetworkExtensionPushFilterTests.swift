@_spi(OpenUIKitHost) import NetworkExtension
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
func testURLFilterBoundary() {
    neWait {
        let verdict = await NEURLFilter.verdict(for: URL(string: "https://example.invalid")!)
        precondition(verdict == .unknown)
        let prefilter = NEURLFilterPrefilter(
            data: .smallFilter(Data([0x00])),
            tag: "t1",
            bitCount: 8,
            hashCount: 1,
            murmurSeed: 0
        )
        precondition(prefilter.tag == "t1")
        switch prefilter.data {
        case .smallFilter(let data):
            precondition(data.count == 1)
        case .temporaryFilepath:
            fatalError("expected smallFilter")
        }
        do {
            try NEURLFilterManager.shared.setConfiguration(
                pirServerURL: URL(string: "https://pir.example.invalid")!,
                pirPrivacyPassIssuerURL: nil,
                pirAuthenticationToken: "token",
                controlProviderBundleIdentifier: "example.urlfilter"
            )
            fatalError("URL filter configuration must fail closed")
        } catch let error as NEURLFilterManager.Error {
            precondition(error == .configurationInvalid)
            precondition(error.rawValue == 2)
        } catch {
            fatalError("unexpected URL filter configuration error \(error)")
        }
    }
}

@MainActor
func testMainActorConfigurations() {
    _ = NEAppExtensionConfiguration()
    _ = NEURLFilterControlProviderConfiguration()
    _ = NEHotspotEvaluationProviderConfiguration()
    _ = NEHotspotAuthenticationProviderConfiguration()
}

func testURLFilterAndHotspotManagerSurface() {
let endpoint = NWHostEndpoint(hostname: "example.invalid", port: "443")
let command = NEHotspotHelperCommand()
let udp = NEAppProxyUDPFlow()
let tcp = NWTCPConnection(endpoint: endpoint)
let request = NSMutableURLRequest(url: URL(string: "https://example.invalid")!)
request.bind(to: command)

let hotspotManager = NEHotspotManager.shared
hotspotManager.safariDomains = ["example.invalid"]
hotspotManager.evaluatedSSIDs = ["Cafe"]
hotspotManager.evaluationProviderBundleIdentifier = "eval"
hotspotManager.authenticationProviderBundleIdentifier = "auth"
hotspotManager.isEnabled = false
_ = NEHotspotManager.Error.internalError.localizedDescription

_ = NEURLFilterManager.shared.pirServerURL
_ = NEURLFilterManager.shared.appBundleIdentifier
_ = NEURLFilterManager.shared.pirAuthenticationToken
NEURLFilterManager.shared.prefilterFetchInterval = 60
_ = NEURLFilterManager.shared.pirPrivacyPassIssuerURL
_ = NEURLFilterManager.shared.controlProviderBundleIdentifier
NEURLFilterManager.shared.isEnabled = false
let err = NEURLFilterManager.Error.configurationInvalid
_ = err.helpAnchor
_ = err.failureReason
_ = err.errorDescription
_ = err.recoverySuggestion
_ = err.localizedDescription
_ = NEURLFilterManager.Status.invalid.rawValue
let prefilter = NEURLFilterPrefilter(
    data: .temporaryFilepath(URL(fileURLWithPath: "/tmp/prefilter")),
    tag: "t2",
    bitCount: 4,
    hashCount: 2,
    murmurSeed: 7
)
_ = prefilter.murmurSeed
_ = prefilter.bitCount
_ = prefilter.hashCount

_ = NEAppProxyProviderManager()

final class UDPHandler: NEAppProxyUDPFlowHandling {
    func handleNewUDPFlow(
        _ flow: NEAppProxyUDPFlow,
        initialRemoteFlowEndpoint remoteEndpoint: NWEndpoint
    ) -> Bool {
        _ = (flow, remoteEndpoint)
        return false
    }
}
_ = UDPHandler().handleNewUDPFlow(udp, initialRemoteFlowEndpoint: endpoint)

final class AuthDelegate: NSObject, NWTCPConnectionAuthenticationDelegate {}
let auth = AuthDelegate()
_ = auth.shouldEvaluateTrust(for: tcp)
_ = auth.shouldProvideIdentity(for: tcp)

let handler: NEHotspotHelperHandler = { _ in }
_ = handler
}
