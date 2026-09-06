import Foundation
import Dispatch
import Matter

func testClusterOperationalCredentialsDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    guard let cluster = MTRClusterOperationalCredentials(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterOperationalCredentials init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeCommissionedFabrics(with: MTRReadParams())
    _ = cluster.readAttributeCurrentFabricIndex(with: MTRReadParams())
    _ = cluster.readAttributeFabrics(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeNOCs(with: MTRReadParams())
    _ = cluster.readAttributeSupportedFabrics(with: MTRReadParams())
    _ = cluster.readAttributeTrustedRootCertificates(with: MTRReadParams())
}

func testClusterOperationalCredentialsCommandFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    guard let cluster = MTRClusterOperationalCredentials(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterOperationalCredentials init")
        return
    }
    cluster.csrRequest(with: MTROperationalCredentialsClusterCSRRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.csrRequest(with: MTROperationalCredentialsClusterCSRRequestParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.addNOC(with: MTROperationalCredentialsClusterAddNOCParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.addNOC(with: MTROperationalCredentialsClusterAddNOCParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.addTrustedRootCertificate(with: MTROperationalCredentialsClusterAddTrustedRootCertificateParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.addTrustedRootCertificate(with: MTROperationalCredentialsClusterAddTrustedRootCertificateParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.attestationRequest(with: MTROperationalCredentialsClusterAttestationRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.attestationRequest(with: MTROperationalCredentialsClusterAttestationRequestParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.certificateChainRequest(with: MTROperationalCredentialsClusterCertificateChainRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.certificateChainRequest(with: MTROperationalCredentialsClusterCertificateChainRequestParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.removeFabric(with: MTROperationalCredentialsClusterRemoveFabricParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.removeFabric(with: MTROperationalCredentialsClusterRemoveFabricParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.updateFabricLabel(with: MTROperationalCredentialsClusterUpdateFabricLabelParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.updateFabricLabel(with: MTROperationalCredentialsClusterUpdateFabricLabelParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.updateNOC(with: MTROperationalCredentialsClusterUpdateNOCParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.updateNOC(with: MTROperationalCredentialsClusterUpdateNOCParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
}

func testClusterOperationalCredentialsInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    _ = MTRClusterOperationalCredentials(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterOperationalCredentials(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

