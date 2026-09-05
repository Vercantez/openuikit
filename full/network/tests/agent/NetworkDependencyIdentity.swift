import Foundation
import Network

func networkDependencyIdentityProbe() {
    let data = Data([127, 0, 0, 1])
    let address = IPv4Address(data)
    precondition(address?.rawValue == data)
    let url = URL(string: "https://example.invalid")!
    let endpoint = NWEndpoint.url(url)
    _ = endpoint.debugDescription
    let parameters = NWParameters.tcp
    _ = NWConnection(to: endpoint, using: parameters)
}

#if NETWORK_IDENTITY_MAIN
networkDependencyIdentityProbe()
print("NETWORK_DEPENDENCY_IDENTITY_OK")
#endif
