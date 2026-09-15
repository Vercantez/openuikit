import Foundation
import Dispatch
import Matter

func testAttestationPrimitivesWave11() {
    let blob = Data([1, 2, 3])
    let csr = CSRInfo(nonce: blob, elements: blob, elementsSignature: blob, csr: blob)
    _ = csr.nonce
    _ = csr.elements
    _ = csr.elementsSignature
    _ = csr.csr
    mtrRequire(csr.nonce == blob, "CSRInfo nonce")
    let att = AttestationInfo(challenge: blob, nonce: blob, elements: blob, elementsSignature: blob, dac: blob, pai: blob, certificationDeclaration: blob, firmwareInfo: blob)
    _ = att.challenge
    _ = att.nonce
    _ = att.elements
    _ = att.elementsSignature
    _ = att.dac
    _ = att.pai
    _ = att.certificationDeclaration
    _ = att.firmwareInfo
    mtrRequire(att.dac == blob, "AttestationInfo dac")
}

func testDeviceAttestationInfoWave11() {
    let blob = Data([4, 5])
    let info = MTRDeviceAttestationInfo(deviceAttestationChallenge: blob, nonce: blob, elementsTLV: blob, elementsSignature: blob, deviceAttestationCertificate: blob, productAttestationIntermediateCertificate: blob, certificationDeclaration: blob, firmwareInfo: blob)
    _ = info.challenge
    _ = info.nonce
    _ = info.elementsSignature
    _ = info.certificationDeclaration
    _ = info.deviceAttestationCertificate
    _ = info.productAttestationIntermediateCertificate
    _ = info.elementsTLV
    _ = info.firmwareInfo
    mtrRequire(info.elementsTLV == blob, "MTRDeviceAttestationInfo elementsTLV")
    let def = MTRDeviceAttestationInfo()
    _ = def.challenge
}

func testDeviceAttestationDeviceInfoWave11() {
    let info = MTRDeviceAttestationDeviceInfo()
    info.attestationChallenge = Data([1])
    _ = info.attestationChallenge
    info.attestationNonce = Data([2])
    _ = info.attestationNonce
    info.basicInformationVendorID = n(1)
    _ = info.basicInformationVendorID
    info.basicInformationProductID = n(2)
    _ = info.basicInformationProductID
    info.certificateDeclaration = Data([3])
    _ = info.certificateDeclaration
    info.certificationDeclaration = Data([4])
    _ = info.certificationDeclaration
    info.dacCertificate = Data([5])
    _ = info.dacCertificate
    info.dacPAICertificate = Data([6])
    _ = info.dacPAICertificate
    info.elementsSignature = Data([7])
    _ = info.elementsSignature
    info.elementsTLV = Data([8])
    _ = info.elementsTLV
    info.productID = n(9)
    _ = info.productID
    info.vendorID = n(10)
    _ = info.vendorID
    mtrRequire(info.vendorID == n(10), "MTRDeviceAttestationDeviceInfo vendorID")
}

func testOperationalCSRInfoWave11() {
    let blob = Data([7])
    let a = MTROperationalCSRInfo(csr: blob, csrNonce: blob, csrElementsTLV: blob, attestationSignature: blob)
    _ = a.csr
    _ = a.csrNonce
    _ = a.csrElementsTLV
    _ = a.attestationSignature
    mtrRequire(a.csr == blob, "MTROperationalCSRInfo csr")
    let b = MTROperationalCSRInfo(csrNonce: blob, csrElementsTLV: blob, attestationSignature: blob)
    mtrRequire(b != nil, "MTROperationalCSRInfo nonce init")
    let c = MTROperationalCSRInfo(csrElementsTLV: blob, attestationSignature: blob)
    mtrRequire(c != nil, "MTROperationalCSRInfo elements init")
    let params = MTROperationalCredentialsClusterCSRResponseParams()
    params.attestationSignature = blob
    params.nocsrElements = blob
    let d = MTROperationalCSRInfo(csrResponseParams: params)
    mtrRequire(d != nil && d!.attestationSignature == blob, "MTROperationalCSRInfo response init")
}

func testOperationalCertificateChainWave11() {
    let blob = Data([8])
    let chain = MTROperationalCertificateChain(operationalCertificate: blob, intermediateCertificate: blob, rootCertificate: blob, adminSubject: n(3))
    _ = chain.operationalCertificate
    _ = chain.intermediateCertificate
    _ = chain.rootCertificate
    _ = chain.adminSubject
    mtrRequire(chain.operationalCertificate == blob, "MTROperationalCertificateChain operationalCertificate")
    mtrRequire(chain.adminSubject == n(3), "MTROperationalCertificateChain adminSubject")
}

func testCommandWithRequiredResponseWave11() {
    let path = MTRCommandPath(endpointID: n(1), clusterID: n(6), commandID: n(2))
    let cmd = MTRCommandWithRequiredResponse(path: path, commandFields: ["k": n(1)], requiredResponse: [n(1): ["v": n(2)]])
    _ = cmd.path
    _ = cmd.commandFields
    _ = cmd.requiredResponse
    mtrRequire(cmd.path?.command == n(2), "MTRCommandWithRequiredResponse path")
    let blank = MTRCommandWithRequiredResponse()
    blank.commandFields = ["k": n(1)]
    _ = blank.commandFields
}

func testStorageBehaviorConfigurationWave11() {
    let def = MTRDeviceStorageBehaviorConfiguration.withDefaultStorageBehavior()
    _ = def.disableStorageBehaviorOptimization
    _ = def.reportToPersistenceDelayTime
    _ = def.reportToPersistenceDelayTimeMax
    _ = def.recentReportTimesMaxCount
    _ = def.timeBetweenReportsTooShortThreshold
    _ = def.timeBetweenReportsTooShortMinThreshold
    _ = def.reportToPersistenceDelayMaxMultiplier
    _ = def.deviceReportingExcessivelyIntervalThreshold
    mtrRequire(def.disableStorageBehaviorOptimization == false, "default storage behavior")
    let off = MTRDeviceStorageBehaviorConfiguration.withStorageBehaviorOptimizationDisabled()
    mtrRequire(off.disableStorageBehaviorOptimization == true, "disabled storage behavior")
    let custom = MTRDeviceStorageBehaviorConfiguration(reportToPersistenceDelayTime: 1.5, reportToPersistenceDelayTimeMax: 3.0, recentReportTimesMaxCount: 4, timeBetweenReportsTooShortThreshold: 0.5, timeBetweenReportsTooShortMinThreshold: 0.25, reportToPersistenceDelayMaxMultiplier: 2.0, deviceReportingExcessivelyIntervalThreshold: 60.0)
    mtrRequire(custom.recentReportTimesMaxCount == 4, "custom storage behavior count")
    mtrRequire(custom.reportToPersistenceDelayTime == 1.5, "custom storage behavior delay")
}

func testMetricsWave11() {
    let metrics = MTRMetrics()
    _ = metrics.uniqueIdentifier
    mtrRequire(metrics.allKeys.isEmpty, "MTRMetrics allKeys")
    mtrRequire(metrics.metricData(forKey: "nope") == nil, "MTRMetrics metricData")
    let data = MTRMetricData()
    data.value = n(1)
    _ = data.value
    data.duration = n(2)
    _ = data.duration
    data.errorCode = n(3)
    _ = data.errorCode
    mtrRequire(data.errorCode == n(3), "MTRMetricData errorCode")
}

func testAttributeValueWaiterWave11() {
    let waiter = MTRAttributeValueWaiter()
    _ = waiter.uuid
    waiter.uuid = UUID()
    _ = waiter.uuid
    waiter.cancel()
}

func testServerAttributeWave11() {
    let attr = MTRServerAttribute(readonlyAttributeWithID: n(10), initialValue: ["type": n(1)], requiredPrivilege: .view)
    mtrRequire(attr != nil, "MTRServerAttribute readonly init")
    guard let readonly = attr else { return }
    _ = readonly.attributeID
    _ = readonly.requiredReadPrivilege
    _ = readonly.value
    _ = readonly.isWritable
    mtrRequire(readonly.attributeID == n(10), "MTRServerAttribute attributeID")
    mtrRequire(readonly.setValue(["type": n(2)]) == false, "readonly setValue fails")
    readonly.isWritable = true
    mtrRequire(readonly.setValue(["type": n(2)]) == true, "writable setValue succeeds")
    let feature = MTRServerAttribute.newFeatureMapAttribute(withInitialValue: n(3))
    _ = feature.attributeID
    mtrRequire(feature.requiredReadPrivilege == .view, "feature map privilege")
}

func testServerClusterWave11() {
    let cluster = MTRServerCluster(clusterID: n(29), revision: n(1))
    mtrRequire(cluster != nil, "MTRServerCluster init")
    guard let c = cluster else { return }
    _ = c.clusterID
    _ = c.attributes
    _ = c.accessGrants
    _ = c.clusterRevision
    mtrRequire(c.clusterRevision == n(1), "MTRServerCluster revision")
    let grant = MTRAccessGrant(forAllNodesWithPrivilege: .view)
    c.addAccessGrant(grant)
    mtrRequire(c.accessGrants.count == 1, "MTRServerCluster addAccessGrant")
    c.removeAccessGrant(grant)
    mtrRequire(c.accessGrants.isEmpty, "MTRServerCluster removeAccessGrant")
    let attr = MTRServerAttribute()
    mtrRequire(c.addAttribute(attr) == true, "MTRServerCluster addAttribute")
    let descriptor = MTRServerCluster.newDescriptor()
    mtrRequire(descriptor.clusterID == n(29), "MTRServerCluster newDescriptor")
}

func testServerEndpointWave11() {
    let rev = MTRDeviceTypeRevision(deviceTypeID: n(22), revision: n(1))
    mtrRequire(rev != nil, "MTRDeviceTypeRevision init")
    let ep = MTRServerEndpoint(endpointID: n(1), deviceTypes: [rev!])
    mtrRequire(ep != nil, "MTRServerEndpoint init")
    guard let endpoint = ep else { return }
    _ = endpoint.endpointID
    _ = endpoint.deviceTypes
    _ = endpoint.accessGrants
    _ = endpoint.serverClusters
    mtrRequire(endpoint.endpointID == n(1), "MTRServerEndpoint endpointID")
    let cluster = MTRServerCluster()
    mtrRequire(endpoint.addServerCluster(cluster) == true, "MTRServerEndpoint addServerCluster")
    mtrRequire(endpoint.serverClusters.count == 1, "MTRServerEndpoint serverClusters")
    let grant = MTRAccessGrant(forAllNodesWithPrivilege: .operate)
    endpoint.addAccessGrant(grant)
    mtrRequire(endpoint.accessGrants.count == 1, "MTRServerEndpoint addAccessGrant")
    endpoint.removeAccessGrant(grant)
    mtrRequire(endpoint.accessGrants.isEmpty, "MTRServerEndpoint removeAccessGrant")
}

func testStateCacheContainerReadWave11() {
    let container = MTRClusterStateCacheContainer()
    container.readAttributes(withEndpointID: n(1), clusterID: n(6), attributeID: n(0), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
}

func testXPCParametersWave11() {
    let params = MTRXPCDeviceControllerParameters()
    _ = params.uniqueIdentifier
    params.uniqueIdentifier = UUID()
    _ = params.uniqueIdentifier
}

func testCommissionableBrowserResultWave11() {
    let result = MTRCommissionableBrowserResult()
    result.instanceName = "lamp"
    _ = result.instanceName
    result.vendorID = n(1)
    _ = result.vendorID
    result.productID = n(2)
    _ = result.productID
    result.discriminator = n(3)
    _ = result.discriminator
    result.commissioningMode = true
    _ = result.commissioningMode
    mtrRequire(result.commissioningMode == true, "MTRCommissionableBrowserResult commissioningMode")
}

func testCommissioneeInfoWave11() {
    let info = MTRCommissioneeInfo()
    info.productIdentity = MTRProductIdentity(vendorID: n(1), productID: n(2))
    _ = info.productIdentity
    info.endpointsById = [n(0): MTREndpointInfo()]
    _ = info.endpointsById
    info.rootEndpoint = MTREndpointInfo()
    _ = info.rootEndpoint
    mtrRequire(info.rootEndpoint != nil, "MTRCommissioneeInfo rootEndpoint")
}
