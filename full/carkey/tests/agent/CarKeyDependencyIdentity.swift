import CarKey
import Foundation

/// Isolated-host identity probe. The sealed host gate does not compile this
/// file. The later EC2 integration build imports real Foundation and passes
/// genuine Foundation values through public CarKey APIs.
func carKeyDependencyIdentityProbe() {
    let nonce = Data("foundation-nonce".utf8)
    let signed = Data([0x01, 0x02, 0x03])
    let signature = Data([0x04, 0x05])
    let attestation = CarKeyRemoteControlSession.Attestation(
        appBundleIdentifier: Bundle.main.bundleIdentifier ?? "linux.carkey",
        nonce: nonce,
        signedData: signed,
        signature: signature
    )
    precondition(attestation.nonce == nonce)
    precondition(attestation.signedData == signed)

    let vehicleID = UUID().uuidString
    let action = RemoteKeylessEntryAction(
        functionID: FunctionIdentifier(rawValue: 1),
        actionID: ActionIdentifier(rawValue: 2),
        vehicleID: vehicleID
    )
    precondition(action.recipientVehicleID == vehicleID)

    let report = VehicleReport(
        identifier: vehicleID,
        isConnected: false,
        proprietaryDataByFunction: [:]
    )
    precondition(report.identifier == vehicleID)
}
