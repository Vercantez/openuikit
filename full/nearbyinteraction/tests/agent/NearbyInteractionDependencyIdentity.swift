import Foundation
import NearbyInteraction

/// Isolated-host identity probe. The sealed host gate does not compile this
/// file. The later EC2 integration build imports real Foundation and passes
/// genuine Foundation values through public NearbyInteraction APIs.
func nearbyInteractionDependencyIdentityProbe() {
    let domain: String = NIErrorDomain
    precondition(domain == "NIErrorDomain")

    let info: [String: Any] = ["foundation": UUID().uuidString]
    let error = NIError(.unsupportedPlatform, userInfo: info)
    precondition(error.userInfo["foundation"] as? String == info["foundation"] as? String)
    let ns = error as NSError
    precondition(ns.domain == NIErrorDomain)
    precondition(ns.code == NIError.Code.unsupportedPlatform.rawValue)

    let tokenUUID = UUID()
    let session = NISession()
    precondition(session.discoveryToken != nil)
    _ = tokenUUID

    let identifier = UUID()
    let data = Data([0x01, 0x02, 0x03])
    do {
        _ = try NINearbyAccessoryConfiguration(accessoryData: data, bluetoothPeerIdentifier: identifier)
        preconditionFailure("accessory init must fail closed")
    } catch let ni as NIError {
        precondition(ni.code == .invalidConfiguration)
    } catch {
        let nsError = error as NSError
        precondition(nsError.domain == NIErrorDomain)
        precondition(nsError.code == NIError.Code.invalidConfiguration.rawValue)
    }

    let network = 7
    let config = NIDLTDOAConfiguration(networkIdentifier: network)
    precondition(config.networkIdentifier == network)
}
