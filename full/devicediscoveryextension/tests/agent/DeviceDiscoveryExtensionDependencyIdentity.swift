import DeviceDiscoveryExtension
import Foundation

/// Isolated-host identity probe. The sealed host gate does not compile this
/// file. The later EC2 integration build imports real Foundation and passes
/// genuine Foundation values through public DeviceDiscoveryExtension APIs.
func deviceDiscoveryExtensionDependencyIdentityProbe() {
    let domain: String = DDErrorDomain
    precondition(domain == "DDErrorDomain")

    let info: [String: Any] = ["foundation": UUID().uuidString]
    let error = DDError(.unsupported, userInfo: info)
    precondition(error.userInfo["foundation"] as? String == info["foundation"] as? String)
    let ns = error as NSError
    precondition(ns.domain == DDErrorDomain)
    precondition(ns.code == DDError.Code.unsupported.rawValue)

    let uuid = UUID()
    let url = URL(string: "https://example.invalid/device")!
    let device = DDDevice(
        displayName: "Foundation Probe",
        category: .desktopComputer,
        protocolType: UTType("public.data"),
        identifier: uuid.uuidString
    )
    device.bluetoothIdentifier = uuid
    device.url = url
    precondition(device.bluetoothIdentifier == uuid)
    precondition(device.url == url)
    precondition(device.identifier == uuid.uuidString)

    let data = Data([0x0A, 0x0B])
    device.txtRecord = NWTXTRecord(data)
    precondition(device.txtRecord == NWTXTRecord(data))
}
