import Foundation
import Dispatch
import Matter

func testMTROperationalCredentialsClusterAddNOCParamsParamsWave11() {
    let _MTROperationalCredentialsClusterAddNOCParams = MTROperationalCredentialsClusterAddNOCParams()
    _MTROperationalCredentialsClusterAddNOCParams.adminVendorId = n(1)
    _ = _MTROperationalCredentialsClusterAddNOCParams.adminVendorId
    _MTROperationalCredentialsClusterAddNOCParams.caseAdminSubject = n(1)
    _ = _MTROperationalCredentialsClusterAddNOCParams.caseAdminSubject
    _MTROperationalCredentialsClusterAddNOCParams.icacValue = Data([1])
    _ = _MTROperationalCredentialsClusterAddNOCParams.icacValue
    _MTROperationalCredentialsClusterAddNOCParams.ipkValue = Data([1])
    _ = _MTROperationalCredentialsClusterAddNOCParams.ipkValue
    _MTROperationalCredentialsClusterAddNOCParams.nocValue = Data([1])
    _ = _MTROperationalCredentialsClusterAddNOCParams.nocValue
    _MTROperationalCredentialsClusterAddNOCParams.serverSideProcessingTimeout = n(1)
    _ = _MTROperationalCredentialsClusterAddNOCParams.serverSideProcessingTimeout
    _MTROperationalCredentialsClusterAddNOCParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROperationalCredentialsClusterAddNOCParams.timedInvokeTimeoutMs
    mtrRequire(_MTROperationalCredentialsClusterAddNOCParams.description.contains("MTROperationalCredentialsClusterAddNOCParams"), "MTROperationalCredentialsClusterAddNOCParams desc")
}

func testMTROperationalCredentialsClusterAddTrustedRootCertificateParamsParamsWave11() {
    let _MTROperationalCredentialsClusterAddTrustedRootCertificateParams = MTROperationalCredentialsClusterAddTrustedRootCertificateParams()
    _MTROperationalCredentialsClusterAddTrustedRootCertificateParams.rootCACertificate = Data([1])
    _ = _MTROperationalCredentialsClusterAddTrustedRootCertificateParams.rootCACertificate
    _MTROperationalCredentialsClusterAddTrustedRootCertificateParams.rootCertificate = Data([1])
    _ = _MTROperationalCredentialsClusterAddTrustedRootCertificateParams.rootCertificate
    _MTROperationalCredentialsClusterAddTrustedRootCertificateParams.serverSideProcessingTimeout = n(1)
    _ = _MTROperationalCredentialsClusterAddTrustedRootCertificateParams.serverSideProcessingTimeout
    _MTROperationalCredentialsClusterAddTrustedRootCertificateParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROperationalCredentialsClusterAddTrustedRootCertificateParams.timedInvokeTimeoutMs
    mtrRequire(_MTROperationalCredentialsClusterAddTrustedRootCertificateParams.description.contains("MTROperationalCredentialsClusterAddTrustedRootCertificateParams"), "MTROperationalCredentialsClusterAddTrustedRootCertificateParams desc")
}

func testMTROperationalCredentialsClusterAttestationRequestParamsParamsWave11() {
    let _MTROperationalCredentialsClusterAttestationRequestParams = MTROperationalCredentialsClusterAttestationRequestParams()
    _MTROperationalCredentialsClusterAttestationRequestParams.attestationNonce = Data([1])
    _ = _MTROperationalCredentialsClusterAttestationRequestParams.attestationNonce
    _MTROperationalCredentialsClusterAttestationRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTROperationalCredentialsClusterAttestationRequestParams.serverSideProcessingTimeout
    _MTROperationalCredentialsClusterAttestationRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROperationalCredentialsClusterAttestationRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTROperationalCredentialsClusterAttestationRequestParams.description.contains("MTROperationalCredentialsClusterAttestationRequestParams"), "MTROperationalCredentialsClusterAttestationRequestParams desc")
}

func testMTROperationalCredentialsClusterAttestationResponseParamsParamsWave11() {
    let _MTROperationalCredentialsClusterAttestationResponseParams = (try? MTROperationalCredentialsClusterAttestationResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTROperationalCredentialsClusterAttestationResponseParams()
    _MTROperationalCredentialsClusterAttestationResponseParams.attestationElements = Data([1])
    _ = _MTROperationalCredentialsClusterAttestationResponseParams.attestationElements
    _MTROperationalCredentialsClusterAttestationResponseParams.attestationSignature = Data([1])
    _ = _MTROperationalCredentialsClusterAttestationResponseParams.attestationSignature
    _MTROperationalCredentialsClusterAttestationResponseParams.signature = Data([1])
    _ = _MTROperationalCredentialsClusterAttestationResponseParams.signature
    _MTROperationalCredentialsClusterAttestationResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROperationalCredentialsClusterAttestationResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTROperationalCredentialsClusterAttestationResponseParams.description.contains("MTROperationalCredentialsClusterAttestationResponseParams"), "MTROperationalCredentialsClusterAttestationResponseParams desc")
}

func testMTROperationalCredentialsClusterCSRRequestParamsParamsWave11() {
    let _MTROperationalCredentialsClusterCSRRequestParams = MTROperationalCredentialsClusterCSRRequestParams()
    _MTROperationalCredentialsClusterCSRRequestParams.csrNonce = Data([1])
    _ = _MTROperationalCredentialsClusterCSRRequestParams.csrNonce
    _MTROperationalCredentialsClusterCSRRequestParams.isForUpdateNOC = n(1)
    _ = _MTROperationalCredentialsClusterCSRRequestParams.isForUpdateNOC
    _MTROperationalCredentialsClusterCSRRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTROperationalCredentialsClusterCSRRequestParams.serverSideProcessingTimeout
    _MTROperationalCredentialsClusterCSRRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROperationalCredentialsClusterCSRRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTROperationalCredentialsClusterCSRRequestParams.description.contains("MTROperationalCredentialsClusterCSRRequestParams"), "MTROperationalCredentialsClusterCSRRequestParams desc")
}

func testMTROperationalCredentialsClusterCSRResponseParamsParamsWave11() {
    let _MTROperationalCredentialsClusterCSRResponseParams = (try? MTROperationalCredentialsClusterCSRResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTROperationalCredentialsClusterCSRResponseParams()
    _MTROperationalCredentialsClusterCSRResponseParams.attestationSignature = Data([1])
    _ = _MTROperationalCredentialsClusterCSRResponseParams.attestationSignature
    _MTROperationalCredentialsClusterCSRResponseParams.nocsrElements = Data([1])
    _ = _MTROperationalCredentialsClusterCSRResponseParams.nocsrElements
    _MTROperationalCredentialsClusterCSRResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROperationalCredentialsClusterCSRResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTROperationalCredentialsClusterCSRResponseParams.description.contains("MTROperationalCredentialsClusterCSRResponseParams"), "MTROperationalCredentialsClusterCSRResponseParams desc")
}

func testMTROperationalCredentialsClusterCertificateChainRequestParamsParamsWave11() {
    let _MTROperationalCredentialsClusterCertificateChainRequestParams = MTROperationalCredentialsClusterCertificateChainRequestParams()
    _MTROperationalCredentialsClusterCertificateChainRequestParams.certificateType = n(1)
    _ = _MTROperationalCredentialsClusterCertificateChainRequestParams.certificateType
    _MTROperationalCredentialsClusterCertificateChainRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTROperationalCredentialsClusterCertificateChainRequestParams.serverSideProcessingTimeout
    _MTROperationalCredentialsClusterCertificateChainRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROperationalCredentialsClusterCertificateChainRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTROperationalCredentialsClusterCertificateChainRequestParams.description.contains("MTROperationalCredentialsClusterCertificateChainRequestParams"), "MTROperationalCredentialsClusterCertificateChainRequestParams desc")
}

func testMTROperationalCredentialsClusterCertificateChainResponseParamsParamsWave11() {
    let _MTROperationalCredentialsClusterCertificateChainResponseParams = (try? MTROperationalCredentialsClusterCertificateChainResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTROperationalCredentialsClusterCertificateChainResponseParams()
    _MTROperationalCredentialsClusterCertificateChainResponseParams.certificate = Data([1])
    _ = _MTROperationalCredentialsClusterCertificateChainResponseParams.certificate
    _MTROperationalCredentialsClusterCertificateChainResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROperationalCredentialsClusterCertificateChainResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTROperationalCredentialsClusterCertificateChainResponseParams.description.contains("MTROperationalCredentialsClusterCertificateChainResponseParams"), "MTROperationalCredentialsClusterCertificateChainResponseParams desc")
}

func testMTROperationalCredentialsClusterFabricDescriptorParamsWave11() {
    let _MTROperationalCredentialsClusterFabricDescriptor = MTROperationalCredentialsClusterFabricDescriptor()
    _MTROperationalCredentialsClusterFabricDescriptor.fabricIndex = n(1)
    _ = _MTROperationalCredentialsClusterFabricDescriptor.fabricIndex
    _MTROperationalCredentialsClusterFabricDescriptor.label = "x"
    _ = _MTROperationalCredentialsClusterFabricDescriptor.label
    _MTROperationalCredentialsClusterFabricDescriptor.rootPublicKey = Data([1])
    _ = _MTROperationalCredentialsClusterFabricDescriptor.rootPublicKey
    mtrRequire(!_MTROperationalCredentialsClusterFabricDescriptor.description.isEmpty, "MTROperationalCredentialsClusterFabricDescriptor desc")
}

func testMTROperationalCredentialsClusterFabricDescriptorStructParamsWave11() {
    let _MTROperationalCredentialsClusterFabricDescriptorStruct = MTROperationalCredentialsClusterFabricDescriptorStruct()
    _MTROperationalCredentialsClusterFabricDescriptorStruct.fabricID = n(1)
    _ = _MTROperationalCredentialsClusterFabricDescriptorStruct.fabricID
    _MTROperationalCredentialsClusterFabricDescriptorStruct.fabricId = n(1)
    _ = _MTROperationalCredentialsClusterFabricDescriptorStruct.fabricId
    _MTROperationalCredentialsClusterFabricDescriptorStruct.fabricIndex = n(1)
    _ = _MTROperationalCredentialsClusterFabricDescriptorStruct.fabricIndex
    _MTROperationalCredentialsClusterFabricDescriptorStruct.label = "x"
    _ = _MTROperationalCredentialsClusterFabricDescriptorStruct.label
    _MTROperationalCredentialsClusterFabricDescriptorStruct.nodeID = n(1)
    _ = _MTROperationalCredentialsClusterFabricDescriptorStruct.nodeID
    _MTROperationalCredentialsClusterFabricDescriptorStruct.nodeId = n(1)
    _ = _MTROperationalCredentialsClusterFabricDescriptorStruct.nodeId
    _MTROperationalCredentialsClusterFabricDescriptorStruct.rootPublicKey = Data([1])
    _ = _MTROperationalCredentialsClusterFabricDescriptorStruct.rootPublicKey
    _MTROperationalCredentialsClusterFabricDescriptorStruct.vendorID = n(1)
    _ = _MTROperationalCredentialsClusterFabricDescriptorStruct.vendorID
    _MTROperationalCredentialsClusterFabricDescriptorStruct.vendorId = n(1)
    _ = _MTROperationalCredentialsClusterFabricDescriptorStruct.vendorId
    mtrRequire(_MTROperationalCredentialsClusterFabricDescriptorStruct.description.contains("MTROperationalCredentialsClusterFabricDescriptorStruct"), "MTROperationalCredentialsClusterFabricDescriptorStruct desc")
}

func testMTROperationalCredentialsClusterNOCResponseParamsParamsWave11() {
    let _MTROperationalCredentialsClusterNOCResponseParams = (try? MTROperationalCredentialsClusterNOCResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTROperationalCredentialsClusterNOCResponseParams()
    _MTROperationalCredentialsClusterNOCResponseParams.debugText = "x"
    _ = _MTROperationalCredentialsClusterNOCResponseParams.debugText
    _MTROperationalCredentialsClusterNOCResponseParams.fabricIndex = n(1)
    _ = _MTROperationalCredentialsClusterNOCResponseParams.fabricIndex
    _MTROperationalCredentialsClusterNOCResponseParams.statusCode = n(1)
    _ = _MTROperationalCredentialsClusterNOCResponseParams.statusCode
    _MTROperationalCredentialsClusterNOCResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROperationalCredentialsClusterNOCResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTROperationalCredentialsClusterNOCResponseParams.description.contains("MTROperationalCredentialsClusterNOCResponseParams"), "MTROperationalCredentialsClusterNOCResponseParams desc")
}

func testMTROperationalCredentialsClusterNOCStructParamsWave11() {
    let _MTROperationalCredentialsClusterNOCStruct = MTROperationalCredentialsClusterNOCStruct()
    _MTROperationalCredentialsClusterNOCStruct.fabricIndex = n(1)
    _ = _MTROperationalCredentialsClusterNOCStruct.fabricIndex
    _MTROperationalCredentialsClusterNOCStruct.icac = Data([1])
    _ = _MTROperationalCredentialsClusterNOCStruct.icac
    _MTROperationalCredentialsClusterNOCStruct.noc = Data([1])
    _ = _MTROperationalCredentialsClusterNOCStruct.noc
    mtrRequire(_MTROperationalCredentialsClusterNOCStruct.description.contains("MTROperationalCredentialsClusterNOCStruct"), "MTROperationalCredentialsClusterNOCStruct desc")
}

func testMTROperationalCredentialsClusterRemoveFabricParamsParamsWave11() {
    let _MTROperationalCredentialsClusterRemoveFabricParams = MTROperationalCredentialsClusterRemoveFabricParams()
    _MTROperationalCredentialsClusterRemoveFabricParams.fabricIndex = n(1)
    _ = _MTROperationalCredentialsClusterRemoveFabricParams.fabricIndex
    _MTROperationalCredentialsClusterRemoveFabricParams.serverSideProcessingTimeout = n(1)
    _ = _MTROperationalCredentialsClusterRemoveFabricParams.serverSideProcessingTimeout
    _MTROperationalCredentialsClusterRemoveFabricParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROperationalCredentialsClusterRemoveFabricParams.timedInvokeTimeoutMs
    mtrRequire(_MTROperationalCredentialsClusterRemoveFabricParams.description.contains("MTROperationalCredentialsClusterRemoveFabricParams"), "MTROperationalCredentialsClusterRemoveFabricParams desc")
}

func testMTROperationalCredentialsClusterUpdateFabricLabelParamsParamsWave11() {
    let _MTROperationalCredentialsClusterUpdateFabricLabelParams = MTROperationalCredentialsClusterUpdateFabricLabelParams()
    _MTROperationalCredentialsClusterUpdateFabricLabelParams.label = "x"
    _ = _MTROperationalCredentialsClusterUpdateFabricLabelParams.label
    _MTROperationalCredentialsClusterUpdateFabricLabelParams.serverSideProcessingTimeout = n(1)
    _ = _MTROperationalCredentialsClusterUpdateFabricLabelParams.serverSideProcessingTimeout
    _MTROperationalCredentialsClusterUpdateFabricLabelParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROperationalCredentialsClusterUpdateFabricLabelParams.timedInvokeTimeoutMs
    mtrRequire(_MTROperationalCredentialsClusterUpdateFabricLabelParams.description.contains("MTROperationalCredentialsClusterUpdateFabricLabelParams"), "MTROperationalCredentialsClusterUpdateFabricLabelParams desc")
}

func testMTROperationalCredentialsClusterUpdateNOCParamsParamsWave11() {
    let _MTROperationalCredentialsClusterUpdateNOCParams = MTROperationalCredentialsClusterUpdateNOCParams()
    _MTROperationalCredentialsClusterUpdateNOCParams.icacValue = Data([1])
    _ = _MTROperationalCredentialsClusterUpdateNOCParams.icacValue
    _MTROperationalCredentialsClusterUpdateNOCParams.nocValue = Data([1])
    _ = _MTROperationalCredentialsClusterUpdateNOCParams.nocValue
    _MTROperationalCredentialsClusterUpdateNOCParams.serverSideProcessingTimeout = n(1)
    _ = _MTROperationalCredentialsClusterUpdateNOCParams.serverSideProcessingTimeout
    _MTROperationalCredentialsClusterUpdateNOCParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROperationalCredentialsClusterUpdateNOCParams.timedInvokeTimeoutMs
    mtrRequire(_MTROperationalCredentialsClusterUpdateNOCParams.description.contains("MTROperationalCredentialsClusterUpdateNOCParams"), "MTROperationalCredentialsClusterUpdateNOCParams desc")
}

func testMTROperationalStateClusterErrorStateStructParamsWave11() {
    let _MTROperationalStateClusterErrorStateStruct = MTROperationalStateClusterErrorStateStruct()
    _MTROperationalStateClusterErrorStateStruct.errorStateDetails = "x"
    _ = _MTROperationalStateClusterErrorStateStruct.errorStateDetails
    _MTROperationalStateClusterErrorStateStruct.errorStateID = n(1)
    _ = _MTROperationalStateClusterErrorStateStruct.errorStateID
    _MTROperationalStateClusterErrorStateStruct.errorStateLabel = "x"
    _ = _MTROperationalStateClusterErrorStateStruct.errorStateLabel
    mtrRequire(_MTROperationalStateClusterErrorStateStruct.description.contains("MTROperationalStateClusterErrorStateStruct"), "MTROperationalStateClusterErrorStateStruct desc")
}

func testMTROperationalStateClusterOperationCompletionEventParamsWave11() {
    let _MTROperationalStateClusterOperationCompletionEvent = MTROperationalStateClusterOperationCompletionEvent()
    _MTROperationalStateClusterOperationCompletionEvent.completionErrorCode = n(1)
    _ = _MTROperationalStateClusterOperationCompletionEvent.completionErrorCode
    _MTROperationalStateClusterOperationCompletionEvent.pausedTime = n(1)
    _ = _MTROperationalStateClusterOperationCompletionEvent.pausedTime
    _MTROperationalStateClusterOperationCompletionEvent.totalOperationalTime = n(1)
    _ = _MTROperationalStateClusterOperationCompletionEvent.totalOperationalTime
    mtrRequire(_MTROperationalStateClusterOperationCompletionEvent.description.contains("MTROperationalStateClusterOperationCompletionEvent"), "MTROperationalStateClusterOperationCompletionEvent desc")
}

func testMTROperationalStateClusterOperationalCommandResponseParamsParamsWave11() {
    let _MTROperationalStateClusterOperationalCommandResponseParams = (try? MTROperationalStateClusterOperationalCommandResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTROperationalStateClusterOperationalCommandResponseParams()
    _MTROperationalStateClusterOperationalCommandResponseParams.commandResponseState = MTROperationalStateClusterErrorStateStruct()
    _ = _MTROperationalStateClusterOperationalCommandResponseParams.commandResponseState
    mtrRequire(_MTROperationalStateClusterOperationalCommandResponseParams.description.contains("MTROperationalStateClusterOperationalCommandResponseParams"), "MTROperationalStateClusterOperationalCommandResponseParams desc")
}

func testMTROperationalStateClusterOperationalErrorEventParamsWave11() {
    let _MTROperationalStateClusterOperationalErrorEvent = MTROperationalStateClusterOperationalErrorEvent()
    _MTROperationalStateClusterOperationalErrorEvent.errorState = MTROperationalStateClusterErrorStateStruct()
    _ = _MTROperationalStateClusterOperationalErrorEvent.errorState
    mtrRequire(_MTROperationalStateClusterOperationalErrorEvent.description.contains("MTROperationalStateClusterOperationalErrorEvent"), "MTROperationalStateClusterOperationalErrorEvent desc")
}

func testMTROperationalStateClusterOperationalStateStructParamsWave11() {
    let _MTROperationalStateClusterOperationalStateStruct = MTROperationalStateClusterOperationalStateStruct()
    _MTROperationalStateClusterOperationalStateStruct.operationalStateID = n(1)
    _ = _MTROperationalStateClusterOperationalStateStruct.operationalStateID
    _MTROperationalStateClusterOperationalStateStruct.operationalStateLabel = "x"
    _ = _MTROperationalStateClusterOperationalStateStruct.operationalStateLabel
    mtrRequire(_MTROperationalStateClusterOperationalStateStruct.description.contains("MTROperationalStateClusterOperationalStateStruct"), "MTROperationalStateClusterOperationalStateStruct desc")
}

func testMTROperationalStateClusterPauseParamsParamsWave11() {
    let _MTROperationalStateClusterPauseParams = MTROperationalStateClusterPauseParams()
    _MTROperationalStateClusterPauseParams.serverSideProcessingTimeout = n(1)
    _ = _MTROperationalStateClusterPauseParams.serverSideProcessingTimeout
    _MTROperationalStateClusterPauseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROperationalStateClusterPauseParams.timedInvokeTimeoutMs
    mtrRequire(_MTROperationalStateClusterPauseParams.description.contains("MTROperationalStateClusterPauseParams"), "MTROperationalStateClusterPauseParams desc")
}

func testMTROperationalStateClusterResumeParamsParamsWave11() {
    let _MTROperationalStateClusterResumeParams = MTROperationalStateClusterResumeParams()
    _MTROperationalStateClusterResumeParams.serverSideProcessingTimeout = n(1)
    _ = _MTROperationalStateClusterResumeParams.serverSideProcessingTimeout
    _MTROperationalStateClusterResumeParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROperationalStateClusterResumeParams.timedInvokeTimeoutMs
    mtrRequire(_MTROperationalStateClusterResumeParams.description.contains("MTROperationalStateClusterResumeParams"), "MTROperationalStateClusterResumeParams desc")
}

func testMTROperationalStateClusterStartParamsParamsWave11() {
    let _MTROperationalStateClusterStartParams = MTROperationalStateClusterStartParams()
    _MTROperationalStateClusterStartParams.serverSideProcessingTimeout = n(1)
    _ = _MTROperationalStateClusterStartParams.serverSideProcessingTimeout
    _MTROperationalStateClusterStartParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROperationalStateClusterStartParams.timedInvokeTimeoutMs
    mtrRequire(_MTROperationalStateClusterStartParams.description.contains("MTROperationalStateClusterStartParams"), "MTROperationalStateClusterStartParams desc")
}

func testMTROperationalStateClusterStopParamsParamsWave11() {
    let _MTROperationalStateClusterStopParams = MTROperationalStateClusterStopParams()
    _MTROperationalStateClusterStopParams.serverSideProcessingTimeout = n(1)
    _ = _MTROperationalStateClusterStopParams.serverSideProcessingTimeout
    _MTROperationalStateClusterStopParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROperationalStateClusterStopParams.timedInvokeTimeoutMs
    mtrRequire(_MTROperationalStateClusterStopParams.description.contains("MTROperationalStateClusterStopParams"), "MTROperationalStateClusterStopParams desc")
}

func testMTROtaSoftwareUpdateProviderClusterApplyUpdateRequestParamsParamsWave11() {
    let _MTROtaSoftwareUpdateProviderClusterApplyUpdateRequestParams = MTROtaSoftwareUpdateProviderClusterApplyUpdateRequestParams()
    _MTROtaSoftwareUpdateProviderClusterApplyUpdateRequestParams.newVersion = n(1)
    _ = _MTROtaSoftwareUpdateProviderClusterApplyUpdateRequestParams.newVersion
    _MTROtaSoftwareUpdateProviderClusterApplyUpdateRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTROtaSoftwareUpdateProviderClusterApplyUpdateRequestParams.serverSideProcessingTimeout
    _MTROtaSoftwareUpdateProviderClusterApplyUpdateRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROtaSoftwareUpdateProviderClusterApplyUpdateRequestParams.timedInvokeTimeoutMs
    _MTROtaSoftwareUpdateProviderClusterApplyUpdateRequestParams.updateToken = Data([1])
    _ = _MTROtaSoftwareUpdateProviderClusterApplyUpdateRequestParams.updateToken
    mtrRequire(!_MTROtaSoftwareUpdateProviderClusterApplyUpdateRequestParams.description.isEmpty, "MTROtaSoftwareUpdateProviderClusterApplyUpdateRequestParams desc")
}

func testMTROtaSoftwareUpdateProviderClusterApplyUpdateResponseParamsParamsWave11() {
    let _MTROtaSoftwareUpdateProviderClusterApplyUpdateResponseParams = MTROtaSoftwareUpdateProviderClusterApplyUpdateResponseParams()
    _MTROtaSoftwareUpdateProviderClusterApplyUpdateResponseParams.action = n(1)
    _ = _MTROtaSoftwareUpdateProviderClusterApplyUpdateResponseParams.action
    _MTROtaSoftwareUpdateProviderClusterApplyUpdateResponseParams.delayedActionTime = n(1)
    _ = _MTROtaSoftwareUpdateProviderClusterApplyUpdateResponseParams.delayedActionTime
    _MTROtaSoftwareUpdateProviderClusterApplyUpdateResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROtaSoftwareUpdateProviderClusterApplyUpdateResponseParams.timedInvokeTimeoutMs
    mtrRequire(!_MTROtaSoftwareUpdateProviderClusterApplyUpdateResponseParams.description.isEmpty, "MTROtaSoftwareUpdateProviderClusterApplyUpdateResponseParams desc")
}

func testMTROtaSoftwareUpdateProviderClusterNotifyUpdateAppliedParamsParamsWave11() {
    let _MTROtaSoftwareUpdateProviderClusterNotifyUpdateAppliedParams = MTROtaSoftwareUpdateProviderClusterNotifyUpdateAppliedParams()
    _MTROtaSoftwareUpdateProviderClusterNotifyUpdateAppliedParams.serverSideProcessingTimeout = n(1)
    _ = _MTROtaSoftwareUpdateProviderClusterNotifyUpdateAppliedParams.serverSideProcessingTimeout
    _MTROtaSoftwareUpdateProviderClusterNotifyUpdateAppliedParams.softwareVersion = n(1)
    _ = _MTROtaSoftwareUpdateProviderClusterNotifyUpdateAppliedParams.softwareVersion
    _MTROtaSoftwareUpdateProviderClusterNotifyUpdateAppliedParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROtaSoftwareUpdateProviderClusterNotifyUpdateAppliedParams.timedInvokeTimeoutMs
    _MTROtaSoftwareUpdateProviderClusterNotifyUpdateAppliedParams.updateToken = Data([1])
    _ = _MTROtaSoftwareUpdateProviderClusterNotifyUpdateAppliedParams.updateToken
    mtrRequire(!_MTROtaSoftwareUpdateProviderClusterNotifyUpdateAppliedParams.description.isEmpty, "MTROtaSoftwareUpdateProviderClusterNotifyUpdateAppliedParams desc")
}

func testMTROtaSoftwareUpdateProviderClusterQueryImageParamsParamsWave11() {
    let _MTROtaSoftwareUpdateProviderClusterQueryImageParams = MTROtaSoftwareUpdateProviderClusterQueryImageParams()
    _MTROtaSoftwareUpdateProviderClusterQueryImageParams.hardwareVersion = n(1)
    _ = _MTROtaSoftwareUpdateProviderClusterQueryImageParams.hardwareVersion
    _MTROtaSoftwareUpdateProviderClusterQueryImageParams.location = "x"
    _ = _MTROtaSoftwareUpdateProviderClusterQueryImageParams.location
    _MTROtaSoftwareUpdateProviderClusterQueryImageParams.metadataForProvider = Data([1])
    _ = _MTROtaSoftwareUpdateProviderClusterQueryImageParams.metadataForProvider
    _MTROtaSoftwareUpdateProviderClusterQueryImageParams.protocolsSupported = [n(1)] as [Any]
    _ = _MTROtaSoftwareUpdateProviderClusterQueryImageParams.protocolsSupported
    _MTROtaSoftwareUpdateProviderClusterQueryImageParams.requestorCanConsent = n(1)
    _ = _MTROtaSoftwareUpdateProviderClusterQueryImageParams.requestorCanConsent
    _MTROtaSoftwareUpdateProviderClusterQueryImageParams.serverSideProcessingTimeout = n(1)
    _ = _MTROtaSoftwareUpdateProviderClusterQueryImageParams.serverSideProcessingTimeout
    _MTROtaSoftwareUpdateProviderClusterQueryImageParams.softwareVersion = n(1)
    _ = _MTROtaSoftwareUpdateProviderClusterQueryImageParams.softwareVersion
    _MTROtaSoftwareUpdateProviderClusterQueryImageParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROtaSoftwareUpdateProviderClusterQueryImageParams.timedInvokeTimeoutMs
    mtrRequire(!_MTROtaSoftwareUpdateProviderClusterQueryImageParams.description.isEmpty, "MTROtaSoftwareUpdateProviderClusterQueryImageParams desc")
}

func testMTROtaSoftwareUpdateProviderClusterQueryImageResponseParamsParamsWave11() {
    let _MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams = MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams()
    _MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams.delayedActionTime = n(1)
    _ = _MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams.delayedActionTime
    _MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams.imageURI = "x"
    _ = _MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams.imageURI
    _MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams.metadataForRequestor = Data([1])
    _ = _MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams.metadataForRequestor
    _MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams.softwareVersion = n(1)
    _ = _MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams.softwareVersion
    _MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams.softwareVersionString = "x"
    _ = _MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams.softwareVersionString
    _MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams.status = n(1)
    _ = _MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams.status
    _MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams.timedInvokeTimeoutMs
    _MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams.updateToken = Data([1])
    _ = _MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams.updateToken
    _MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams.userConsentNeeded = n(1)
    _ = _MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams.userConsentNeeded
    mtrRequire(!_MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams.description.isEmpty, "MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams desc")
}

func testMTROtaSoftwareUpdateRequestorClusterAnnounceOtaProviderParamsParamsWave11() {
    let _MTROtaSoftwareUpdateRequestorClusterAnnounceOtaProviderParams = MTROtaSoftwareUpdateRequestorClusterAnnounceOtaProviderParams()
    _MTROtaSoftwareUpdateRequestorClusterAnnounceOtaProviderParams.announcementReason = n(1)
    _ = _MTROtaSoftwareUpdateRequestorClusterAnnounceOtaProviderParams.announcementReason
    _MTROtaSoftwareUpdateRequestorClusterAnnounceOtaProviderParams.endpoint = n(1)
    _ = _MTROtaSoftwareUpdateRequestorClusterAnnounceOtaProviderParams.endpoint
    _MTROtaSoftwareUpdateRequestorClusterAnnounceOtaProviderParams.metadataForNode = Data([1])
    _ = _MTROtaSoftwareUpdateRequestorClusterAnnounceOtaProviderParams.metadataForNode
    _MTROtaSoftwareUpdateRequestorClusterAnnounceOtaProviderParams.serverSideProcessingTimeout = n(1)
    _ = _MTROtaSoftwareUpdateRequestorClusterAnnounceOtaProviderParams.serverSideProcessingTimeout
    _MTROtaSoftwareUpdateRequestorClusterAnnounceOtaProviderParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROtaSoftwareUpdateRequestorClusterAnnounceOtaProviderParams.timedInvokeTimeoutMs
    mtrRequire(!_MTROtaSoftwareUpdateRequestorClusterAnnounceOtaProviderParams.description.isEmpty, "MTROtaSoftwareUpdateRequestorClusterAnnounceOtaProviderParams desc")
}

func testMTROtaSoftwareUpdateRequestorClusterDownloadErrorEventParamsWave11() {
    let _MTROtaSoftwareUpdateRequestorClusterDownloadErrorEvent = MTROtaSoftwareUpdateRequestorClusterDownloadErrorEvent()
    _MTROtaSoftwareUpdateRequestorClusterDownloadErrorEvent.bytesDownloaded = n(1)
    _ = _MTROtaSoftwareUpdateRequestorClusterDownloadErrorEvent.bytesDownloaded
    _MTROtaSoftwareUpdateRequestorClusterDownloadErrorEvent.platformCode = n(1)
    _ = _MTROtaSoftwareUpdateRequestorClusterDownloadErrorEvent.platformCode
    _MTROtaSoftwareUpdateRequestorClusterDownloadErrorEvent.progressPercent = n(1)
    _ = _MTROtaSoftwareUpdateRequestorClusterDownloadErrorEvent.progressPercent
    _MTROtaSoftwareUpdateRequestorClusterDownloadErrorEvent.softwareVersion = n(1)
    _ = _MTROtaSoftwareUpdateRequestorClusterDownloadErrorEvent.softwareVersion
    mtrRequire(!_MTROtaSoftwareUpdateRequestorClusterDownloadErrorEvent.description.isEmpty, "MTROtaSoftwareUpdateRequestorClusterDownloadErrorEvent desc")
}

func testMTROtaSoftwareUpdateRequestorClusterProviderLocationParamsWave11() {
    let _MTROtaSoftwareUpdateRequestorClusterProviderLocation = MTROtaSoftwareUpdateRequestorClusterProviderLocation()
    _MTROtaSoftwareUpdateRequestorClusterProviderLocation.endpoint = n(1)
    _ = _MTROtaSoftwareUpdateRequestorClusterProviderLocation.endpoint
    _MTROtaSoftwareUpdateRequestorClusterProviderLocation.fabricIndex = n(1)
    _ = _MTROtaSoftwareUpdateRequestorClusterProviderLocation.fabricIndex
    _MTROtaSoftwareUpdateRequestorClusterProviderLocation.providerNodeID = n(1)
    _ = _MTROtaSoftwareUpdateRequestorClusterProviderLocation.providerNodeID
    mtrRequire(!_MTROtaSoftwareUpdateRequestorClusterProviderLocation.description.isEmpty, "MTROtaSoftwareUpdateRequestorClusterProviderLocation desc")
}

func testMTROtaSoftwareUpdateRequestorClusterStateTransitionEventParamsWave11() {
    let _MTROtaSoftwareUpdateRequestorClusterStateTransitionEvent = MTROtaSoftwareUpdateRequestorClusterStateTransitionEvent()
    _MTROtaSoftwareUpdateRequestorClusterStateTransitionEvent.newState = n(1)
    _ = _MTROtaSoftwareUpdateRequestorClusterStateTransitionEvent.newState
    _MTROtaSoftwareUpdateRequestorClusterStateTransitionEvent.previousState = n(1)
    _ = _MTROtaSoftwareUpdateRequestorClusterStateTransitionEvent.previousState
    _MTROtaSoftwareUpdateRequestorClusterStateTransitionEvent.reason = n(1)
    _ = _MTROtaSoftwareUpdateRequestorClusterStateTransitionEvent.reason
    _MTROtaSoftwareUpdateRequestorClusterStateTransitionEvent.targetSoftwareVersion = n(1)
    _ = _MTROtaSoftwareUpdateRequestorClusterStateTransitionEvent.targetSoftwareVersion
    mtrRequire(!_MTROtaSoftwareUpdateRequestorClusterStateTransitionEvent.description.isEmpty, "MTROtaSoftwareUpdateRequestorClusterStateTransitionEvent desc")
}

func testMTROtaSoftwareUpdateRequestorClusterVersionAppliedEventParamsWave11() {
    let _MTROtaSoftwareUpdateRequestorClusterVersionAppliedEvent = MTROtaSoftwareUpdateRequestorClusterVersionAppliedEvent()
    _MTROtaSoftwareUpdateRequestorClusterVersionAppliedEvent.productID = n(1)
    _ = _MTROtaSoftwareUpdateRequestorClusterVersionAppliedEvent.productID
    _MTROtaSoftwareUpdateRequestorClusterVersionAppliedEvent.softwareVersion = n(1)
    _ = _MTROtaSoftwareUpdateRequestorClusterVersionAppliedEvent.softwareVersion
    mtrRequire(!_MTROtaSoftwareUpdateRequestorClusterVersionAppliedEvent.description.isEmpty, "MTROtaSoftwareUpdateRequestorClusterVersionAppliedEvent desc")
}

func testMTROvenCavityOperationalStateClusterErrorStateStructParamsWave11() {
    let _MTROvenCavityOperationalStateClusterErrorStateStruct = MTROvenCavityOperationalStateClusterErrorStateStruct()
    _MTROvenCavityOperationalStateClusterErrorStateStruct.errorStateDetails = "x"
    _ = _MTROvenCavityOperationalStateClusterErrorStateStruct.errorStateDetails
    _MTROvenCavityOperationalStateClusterErrorStateStruct.errorStateID = n(1)
    _ = _MTROvenCavityOperationalStateClusterErrorStateStruct.errorStateID
    _MTROvenCavityOperationalStateClusterErrorStateStruct.errorStateLabel = "x"
    _ = _MTROvenCavityOperationalStateClusterErrorStateStruct.errorStateLabel
    mtrRequire(_MTROvenCavityOperationalStateClusterErrorStateStruct.description.contains("MTROvenCavityOperationalStateClusterErrorStateStruct"), "MTROvenCavityOperationalStateClusterErrorStateStruct desc")
}

func testMTROvenCavityOperationalStateClusterOperationCompletionEventParamsWave11() {
    let _MTROvenCavityOperationalStateClusterOperationCompletionEvent = MTROvenCavityOperationalStateClusterOperationCompletionEvent()
    _MTROvenCavityOperationalStateClusterOperationCompletionEvent.completionErrorCode = n(1)
    _ = _MTROvenCavityOperationalStateClusterOperationCompletionEvent.completionErrorCode
    _MTROvenCavityOperationalStateClusterOperationCompletionEvent.pausedTime = n(1)
    _ = _MTROvenCavityOperationalStateClusterOperationCompletionEvent.pausedTime
    _MTROvenCavityOperationalStateClusterOperationCompletionEvent.totalOperationalTime = n(1)
    _ = _MTROvenCavityOperationalStateClusterOperationCompletionEvent.totalOperationalTime
    mtrRequire(_MTROvenCavityOperationalStateClusterOperationCompletionEvent.description.contains("MTROvenCavityOperationalStateClusterOperationCompletionEvent"), "MTROvenCavityOperationalStateClusterOperationCompletionEvent desc")
}

func testMTROvenCavityOperationalStateClusterOperationalCommandResponseParamsParamsWave11() {
    let _MTROvenCavityOperationalStateClusterOperationalCommandResponseParams = (try? MTROvenCavityOperationalStateClusterOperationalCommandResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTROvenCavityOperationalStateClusterOperationalCommandResponseParams()
    _MTROvenCavityOperationalStateClusterOperationalCommandResponseParams.commandResponseState = MTROvenCavityOperationalStateClusterErrorStateStruct()
    _ = _MTROvenCavityOperationalStateClusterOperationalCommandResponseParams.commandResponseState
    mtrRequire(_MTROvenCavityOperationalStateClusterOperationalCommandResponseParams.description.contains("MTROvenCavityOperationalStateClusterOperationalCommandResponseParams"), "MTROvenCavityOperationalStateClusterOperationalCommandResponseParams desc")
}

func testMTROvenCavityOperationalStateClusterOperationalErrorEventParamsWave11() {
    let _MTROvenCavityOperationalStateClusterOperationalErrorEvent = MTROvenCavityOperationalStateClusterOperationalErrorEvent()
    _MTROvenCavityOperationalStateClusterOperationalErrorEvent.errorState = MTROvenCavityOperationalStateClusterErrorStateStruct()
    _ = _MTROvenCavityOperationalStateClusterOperationalErrorEvent.errorState
    mtrRequire(_MTROvenCavityOperationalStateClusterOperationalErrorEvent.description.contains("MTROvenCavityOperationalStateClusterOperationalErrorEvent"), "MTROvenCavityOperationalStateClusterOperationalErrorEvent desc")
}

func testMTROvenCavityOperationalStateClusterOperationalStateStructParamsWave11() {
    let _MTROvenCavityOperationalStateClusterOperationalStateStruct = MTROvenCavityOperationalStateClusterOperationalStateStruct()
    _MTROvenCavityOperationalStateClusterOperationalStateStruct.operationalStateID = n(1)
    _ = _MTROvenCavityOperationalStateClusterOperationalStateStruct.operationalStateID
    _MTROvenCavityOperationalStateClusterOperationalStateStruct.operationalStateLabel = "x"
    _ = _MTROvenCavityOperationalStateClusterOperationalStateStruct.operationalStateLabel
    mtrRequire(_MTROvenCavityOperationalStateClusterOperationalStateStruct.description.contains("MTROvenCavityOperationalStateClusterOperationalStateStruct"), "MTROvenCavityOperationalStateClusterOperationalStateStruct desc")
}

func testMTROvenCavityOperationalStateClusterStartParamsParamsWave11() {
    let _MTROvenCavityOperationalStateClusterStartParams = MTROvenCavityOperationalStateClusterStartParams()
    _MTROvenCavityOperationalStateClusterStartParams.serverSideProcessingTimeout = n(1)
    _ = _MTROvenCavityOperationalStateClusterStartParams.serverSideProcessingTimeout
    _MTROvenCavityOperationalStateClusterStartParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROvenCavityOperationalStateClusterStartParams.timedInvokeTimeoutMs
    mtrRequire(_MTROvenCavityOperationalStateClusterStartParams.description.contains("MTROvenCavityOperationalStateClusterStartParams"), "MTROvenCavityOperationalStateClusterStartParams desc")
}

func testMTROvenCavityOperationalStateClusterStopParamsParamsWave11() {
    let _MTROvenCavityOperationalStateClusterStopParams = MTROvenCavityOperationalStateClusterStopParams()
    _MTROvenCavityOperationalStateClusterStopParams.serverSideProcessingTimeout = n(1)
    _ = _MTROvenCavityOperationalStateClusterStopParams.serverSideProcessingTimeout
    _MTROvenCavityOperationalStateClusterStopParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROvenCavityOperationalStateClusterStopParams.timedInvokeTimeoutMs
    mtrRequire(_MTROvenCavityOperationalStateClusterStopParams.description.contains("MTROvenCavityOperationalStateClusterStopParams"), "MTROvenCavityOperationalStateClusterStopParams desc")
}

func testMTROvenModeClusterChangeToModeParamsParamsWave11() {
    let _MTROvenModeClusterChangeToModeParams = MTROvenModeClusterChangeToModeParams()
    _MTROvenModeClusterChangeToModeParams.newMode = n(1)
    _ = _MTROvenModeClusterChangeToModeParams.newMode
    _MTROvenModeClusterChangeToModeParams.serverSideProcessingTimeout = n(1)
    _ = _MTROvenModeClusterChangeToModeParams.serverSideProcessingTimeout
    _MTROvenModeClusterChangeToModeParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROvenModeClusterChangeToModeParams.timedInvokeTimeoutMs
    mtrRequire(_MTROvenModeClusterChangeToModeParams.description.contains("MTROvenModeClusterChangeToModeParams"), "MTROvenModeClusterChangeToModeParams desc")
}

func testMTROvenModeClusterChangeToModeResponseParamsParamsWave11() {
    let _MTROvenModeClusterChangeToModeResponseParams = (try? MTROvenModeClusterChangeToModeResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTROvenModeClusterChangeToModeResponseParams()
    _MTROvenModeClusterChangeToModeResponseParams.status = n(1)
    _ = _MTROvenModeClusterChangeToModeResponseParams.status
    _MTROvenModeClusterChangeToModeResponseParams.statusText = "x"
    _ = _MTROvenModeClusterChangeToModeResponseParams.statusText
    mtrRequire(_MTROvenModeClusterChangeToModeResponseParams.description.contains("MTROvenModeClusterChangeToModeResponseParams"), "MTROvenModeClusterChangeToModeResponseParams desc")
}

func testMTROvenModeClusterModeOptionStructParamsWave11() {
    let _MTROvenModeClusterModeOptionStruct = MTROvenModeClusterModeOptionStruct()
    _MTROvenModeClusterModeOptionStruct.label = "x"
    _ = _MTROvenModeClusterModeOptionStruct.label
    _MTROvenModeClusterModeOptionStruct.mode = n(1)
    _ = _MTROvenModeClusterModeOptionStruct.mode
    _MTROvenModeClusterModeOptionStruct.modeTags = [n(1)] as [Any]
    _ = _MTROvenModeClusterModeOptionStruct.modeTags
    mtrRequire(_MTROvenModeClusterModeOptionStruct.description.contains("MTROvenModeClusterModeOptionStruct"), "MTROvenModeClusterModeOptionStruct desc")
}

func testMTROvenModeClusterModeTagStructParamsWave11() {
    let _MTROvenModeClusterModeTagStruct = MTROvenModeClusterModeTagStruct()
    _MTROvenModeClusterModeTagStruct.mfgCode = n(1)
    _ = _MTROvenModeClusterModeTagStruct.mfgCode
    _MTROvenModeClusterModeTagStruct.value = n(1)
    _ = _MTROvenModeClusterModeTagStruct.value
    mtrRequire(_MTROvenModeClusterModeTagStruct.description.contains("MTROvenModeClusterModeTagStruct"), "MTROvenModeClusterModeTagStruct desc")
}

func testMTRRVCCleanModeClusterChangeToModeParamsParamsWave11() {
    let _MTRRVCCleanModeClusterChangeToModeParams = MTRRVCCleanModeClusterChangeToModeParams()
    _MTRRVCCleanModeClusterChangeToModeParams.newMode = n(1)
    _ = _MTRRVCCleanModeClusterChangeToModeParams.newMode
    _MTRRVCCleanModeClusterChangeToModeParams.serverSideProcessingTimeout = n(1)
    _ = _MTRRVCCleanModeClusterChangeToModeParams.serverSideProcessingTimeout
    _MTRRVCCleanModeClusterChangeToModeParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRRVCCleanModeClusterChangeToModeParams.timedInvokeTimeoutMs
    mtrRequire(_MTRRVCCleanModeClusterChangeToModeParams.description.contains("MTRRVCCleanModeClusterChangeToModeParams"), "MTRRVCCleanModeClusterChangeToModeParams desc")
}

func testMTRRVCCleanModeClusterChangeToModeResponseParamsParamsWave11() {
    let _MTRRVCCleanModeClusterChangeToModeResponseParams = (try? MTRRVCCleanModeClusterChangeToModeResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRRVCCleanModeClusterChangeToModeResponseParams()
    _MTRRVCCleanModeClusterChangeToModeResponseParams.status = n(1)
    _ = _MTRRVCCleanModeClusterChangeToModeResponseParams.status
    _MTRRVCCleanModeClusterChangeToModeResponseParams.statusText = "x"
    _ = _MTRRVCCleanModeClusterChangeToModeResponseParams.statusText
    mtrRequire(_MTRRVCCleanModeClusterChangeToModeResponseParams.description.contains("MTRRVCCleanModeClusterChangeToModeResponseParams"), "MTRRVCCleanModeClusterChangeToModeResponseParams desc")
}

func testMTRRVCCleanModeClusterModeOptionStructParamsWave11() {
    let _MTRRVCCleanModeClusterModeOptionStruct = MTRRVCCleanModeClusterModeOptionStruct()
    _MTRRVCCleanModeClusterModeOptionStruct.label = "x"
    _ = _MTRRVCCleanModeClusterModeOptionStruct.label
    _MTRRVCCleanModeClusterModeOptionStruct.mode = n(1)
    _ = _MTRRVCCleanModeClusterModeOptionStruct.mode
    _MTRRVCCleanModeClusterModeOptionStruct.modeTags = [n(1)] as [Any]
    _ = _MTRRVCCleanModeClusterModeOptionStruct.modeTags
    mtrRequire(_MTRRVCCleanModeClusterModeOptionStruct.description.contains("MTRRVCCleanModeClusterModeOptionStruct"), "MTRRVCCleanModeClusterModeOptionStruct desc")
}

func testMTRRVCCleanModeClusterModeTagStructParamsWave11() {
    let _MTRRVCCleanModeClusterModeTagStruct = MTRRVCCleanModeClusterModeTagStruct()
    _MTRRVCCleanModeClusterModeTagStruct.mfgCode = n(1)
    _ = _MTRRVCCleanModeClusterModeTagStruct.mfgCode
    _MTRRVCCleanModeClusterModeTagStruct.value = n(1)
    _ = _MTRRVCCleanModeClusterModeTagStruct.value
    mtrRequire(_MTRRVCCleanModeClusterModeTagStruct.description.contains("MTRRVCCleanModeClusterModeTagStruct"), "MTRRVCCleanModeClusterModeTagStruct desc")
}

func testMTRRVCOperationalStateClusterErrorStateStructParamsWave11() {
    let _MTRRVCOperationalStateClusterErrorStateStruct = MTRRVCOperationalStateClusterErrorStateStruct()
    _MTRRVCOperationalStateClusterErrorStateStruct.errorStateDetails = "x"
    _ = _MTRRVCOperationalStateClusterErrorStateStruct.errorStateDetails
    _MTRRVCOperationalStateClusterErrorStateStruct.errorStateID = n(1)
    _ = _MTRRVCOperationalStateClusterErrorStateStruct.errorStateID
    _MTRRVCOperationalStateClusterErrorStateStruct.errorStateLabel = "x"
    _ = _MTRRVCOperationalStateClusterErrorStateStruct.errorStateLabel
    mtrRequire(_MTRRVCOperationalStateClusterErrorStateStruct.description.contains("MTRRVCOperationalStateClusterErrorStateStruct"), "MTRRVCOperationalStateClusterErrorStateStruct desc")
}

func testMTRRVCOperationalStateClusterGoHomeParamsParamsWave11() {
    let _MTRRVCOperationalStateClusterGoHomeParams = MTRRVCOperationalStateClusterGoHomeParams()
    _MTRRVCOperationalStateClusterGoHomeParams.serverSideProcessingTimeout = n(1)
    _ = _MTRRVCOperationalStateClusterGoHomeParams.serverSideProcessingTimeout
    _MTRRVCOperationalStateClusterGoHomeParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRRVCOperationalStateClusterGoHomeParams.timedInvokeTimeoutMs
    mtrRequire(_MTRRVCOperationalStateClusterGoHomeParams.description.contains("MTRRVCOperationalStateClusterGoHomeParams"), "MTRRVCOperationalStateClusterGoHomeParams desc")
}

func testMTRRVCOperationalStateClusterOperationCompletionEventParamsWave11() {
    let _MTRRVCOperationalStateClusterOperationCompletionEvent = MTRRVCOperationalStateClusterOperationCompletionEvent()
    _MTRRVCOperationalStateClusterOperationCompletionEvent.completionErrorCode = n(1)
    _ = _MTRRVCOperationalStateClusterOperationCompletionEvent.completionErrorCode
    _MTRRVCOperationalStateClusterOperationCompletionEvent.pausedTime = n(1)
    _ = _MTRRVCOperationalStateClusterOperationCompletionEvent.pausedTime
    _MTRRVCOperationalStateClusterOperationCompletionEvent.totalOperationalTime = n(1)
    _ = _MTRRVCOperationalStateClusterOperationCompletionEvent.totalOperationalTime
    mtrRequire(_MTRRVCOperationalStateClusterOperationCompletionEvent.description.contains("MTRRVCOperationalStateClusterOperationCompletionEvent"), "MTRRVCOperationalStateClusterOperationCompletionEvent desc")
}

func testMTRRVCOperationalStateClusterOperationalCommandResponseParamsParamsWave11() {
    let _MTRRVCOperationalStateClusterOperationalCommandResponseParams = (try? MTRRVCOperationalStateClusterOperationalCommandResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRRVCOperationalStateClusterOperationalCommandResponseParams()
    _MTRRVCOperationalStateClusterOperationalCommandResponseParams.commandResponseState = MTRRVCOperationalStateClusterErrorStateStruct()
    _ = _MTRRVCOperationalStateClusterOperationalCommandResponseParams.commandResponseState
    mtrRequire(_MTRRVCOperationalStateClusterOperationalCommandResponseParams.description.contains("MTRRVCOperationalStateClusterOperationalCommandResponseParams"), "MTRRVCOperationalStateClusterOperationalCommandResponseParams desc")
}

func testMTRRVCOperationalStateClusterOperationalErrorEventParamsWave11() {
    let _MTRRVCOperationalStateClusterOperationalErrorEvent = MTRRVCOperationalStateClusterOperationalErrorEvent()
    _MTRRVCOperationalStateClusterOperationalErrorEvent.errorState = MTRRVCOperationalStateClusterErrorStateStruct()
    _ = _MTRRVCOperationalStateClusterOperationalErrorEvent.errorState
    mtrRequire(_MTRRVCOperationalStateClusterOperationalErrorEvent.description.contains("MTRRVCOperationalStateClusterOperationalErrorEvent"), "MTRRVCOperationalStateClusterOperationalErrorEvent desc")
}

func testMTRRVCOperationalStateClusterOperationalStateStructParamsWave11() {
    let _MTRRVCOperationalStateClusterOperationalStateStruct = MTRRVCOperationalStateClusterOperationalStateStruct()
    _MTRRVCOperationalStateClusterOperationalStateStruct.operationalStateID = n(1)
    _ = _MTRRVCOperationalStateClusterOperationalStateStruct.operationalStateID
    _MTRRVCOperationalStateClusterOperationalStateStruct.operationalStateLabel = "x"
    _ = _MTRRVCOperationalStateClusterOperationalStateStruct.operationalStateLabel
    mtrRequire(_MTRRVCOperationalStateClusterOperationalStateStruct.description.contains("MTRRVCOperationalStateClusterOperationalStateStruct"), "MTRRVCOperationalStateClusterOperationalStateStruct desc")
}

func testMTRRVCOperationalStateClusterPauseParamsParamsWave11() {
    let _MTRRVCOperationalStateClusterPauseParams = MTRRVCOperationalStateClusterPauseParams()
    _MTRRVCOperationalStateClusterPauseParams.serverSideProcessingTimeout = n(1)
    _ = _MTRRVCOperationalStateClusterPauseParams.serverSideProcessingTimeout
    _MTRRVCOperationalStateClusterPauseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRRVCOperationalStateClusterPauseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRRVCOperationalStateClusterPauseParams.description.contains("MTRRVCOperationalStateClusterPauseParams"), "MTRRVCOperationalStateClusterPauseParams desc")
}

func testMTRRVCOperationalStateClusterResumeParamsParamsWave11() {
    let _MTRRVCOperationalStateClusterResumeParams = MTRRVCOperationalStateClusterResumeParams()
    _MTRRVCOperationalStateClusterResumeParams.serverSideProcessingTimeout = n(1)
    _ = _MTRRVCOperationalStateClusterResumeParams.serverSideProcessingTimeout
    _MTRRVCOperationalStateClusterResumeParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRRVCOperationalStateClusterResumeParams.timedInvokeTimeoutMs
    mtrRequire(_MTRRVCOperationalStateClusterResumeParams.description.contains("MTRRVCOperationalStateClusterResumeParams"), "MTRRVCOperationalStateClusterResumeParams desc")
}

func testMTRRVCRunModeClusterChangeToModeParamsParamsWave11() {
    let _MTRRVCRunModeClusterChangeToModeParams = MTRRVCRunModeClusterChangeToModeParams()
    _MTRRVCRunModeClusterChangeToModeParams.newMode = n(1)
    _ = _MTRRVCRunModeClusterChangeToModeParams.newMode
    _MTRRVCRunModeClusterChangeToModeParams.serverSideProcessingTimeout = n(1)
    _ = _MTRRVCRunModeClusterChangeToModeParams.serverSideProcessingTimeout
    _MTRRVCRunModeClusterChangeToModeParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRRVCRunModeClusterChangeToModeParams.timedInvokeTimeoutMs
    mtrRequire(_MTRRVCRunModeClusterChangeToModeParams.description.contains("MTRRVCRunModeClusterChangeToModeParams"), "MTRRVCRunModeClusterChangeToModeParams desc")
}

func testMTRRVCRunModeClusterChangeToModeResponseParamsParamsWave11() {
    let _MTRRVCRunModeClusterChangeToModeResponseParams = (try? MTRRVCRunModeClusterChangeToModeResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRRVCRunModeClusterChangeToModeResponseParams()
    _MTRRVCRunModeClusterChangeToModeResponseParams.status = n(1)
    _ = _MTRRVCRunModeClusterChangeToModeResponseParams.status
    _MTRRVCRunModeClusterChangeToModeResponseParams.statusText = "x"
    _ = _MTRRVCRunModeClusterChangeToModeResponseParams.statusText
    mtrRequire(_MTRRVCRunModeClusterChangeToModeResponseParams.description.contains("MTRRVCRunModeClusterChangeToModeResponseParams"), "MTRRVCRunModeClusterChangeToModeResponseParams desc")
}

func testMTRRVCRunModeClusterModeOptionStructParamsWave11() {
    let _MTRRVCRunModeClusterModeOptionStruct = MTRRVCRunModeClusterModeOptionStruct()
    _MTRRVCRunModeClusterModeOptionStruct.label = "x"
    _ = _MTRRVCRunModeClusterModeOptionStruct.label
    _MTRRVCRunModeClusterModeOptionStruct.mode = n(1)
    _ = _MTRRVCRunModeClusterModeOptionStruct.mode
    _MTRRVCRunModeClusterModeOptionStruct.modeTags = [n(1)] as [Any]
    _ = _MTRRVCRunModeClusterModeOptionStruct.modeTags
    mtrRequire(_MTRRVCRunModeClusterModeOptionStruct.description.contains("MTRRVCRunModeClusterModeOptionStruct"), "MTRRVCRunModeClusterModeOptionStruct desc")
}

func testMTRRVCRunModeClusterModeTagStructParamsWave11() {
    let _MTRRVCRunModeClusterModeTagStruct = MTRRVCRunModeClusterModeTagStruct()
    _MTRRVCRunModeClusterModeTagStruct.mfgCode = n(1)
    _ = _MTRRVCRunModeClusterModeTagStruct.mfgCode
    _MTRRVCRunModeClusterModeTagStruct.value = n(1)
    _ = _MTRRVCRunModeClusterModeTagStruct.value
    mtrRequire(_MTRRVCRunModeClusterModeTagStruct.description.contains("MTRRVCRunModeClusterModeTagStruct"), "MTRRVCRunModeClusterModeTagStruct desc")
}

func testMTRRefrigeratorAlarmClusterNotifyEventParamsWave11() {
    let _MTRRefrigeratorAlarmClusterNotifyEvent = MTRRefrigeratorAlarmClusterNotifyEvent()
    _MTRRefrigeratorAlarmClusterNotifyEvent.active = n(1)
    _ = _MTRRefrigeratorAlarmClusterNotifyEvent.active
    _MTRRefrigeratorAlarmClusterNotifyEvent.inactive = n(1)
    _ = _MTRRefrigeratorAlarmClusterNotifyEvent.inactive
    _MTRRefrigeratorAlarmClusterNotifyEvent.mask = n(1)
    _ = _MTRRefrigeratorAlarmClusterNotifyEvent.mask
    _MTRRefrigeratorAlarmClusterNotifyEvent.state = n(1)
    _ = _MTRRefrigeratorAlarmClusterNotifyEvent.state
    mtrRequire(_MTRRefrigeratorAlarmClusterNotifyEvent.description.contains("MTRRefrigeratorAlarmClusterNotifyEvent"), "MTRRefrigeratorAlarmClusterNotifyEvent desc")
}

func testMTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeParamsParamsWave11() {
    let _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeParams = MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeParams()
    _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeParams.newMode = n(1)
    _ = _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeParams.newMode
    _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeParams.serverSideProcessingTimeout = n(1)
    _ = _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeParams.serverSideProcessingTimeout
    _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeParams.timedInvokeTimeoutMs
    mtrRequire(_MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeParams.description.contains("MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeParams"), "MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeParams desc")
}

func testMTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeResponseParamsParamsWave11() {
    let _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeResponseParams = (try? MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeResponseParams()
    _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeResponseParams.status = n(1)
    _ = _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeResponseParams.status
    _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeResponseParams.statusText = "x"
    _ = _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeResponseParams.statusText
    mtrRequire(_MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeResponseParams.description.contains("MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeResponseParams"), "MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeResponseParams desc")
}

func testMTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeOptionStructParamsWave11() {
    let _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeOptionStruct = MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeOptionStruct()
    _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeOptionStruct.label = "x"
    _ = _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeOptionStruct.label
    _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeOptionStruct.mode = n(1)
    _ = _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeOptionStruct.mode
    _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeOptionStruct.modeTags = [n(1)] as [Any]
    _ = _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeOptionStruct.modeTags
    mtrRequire(_MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeOptionStruct.description.contains("MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeOptionStruct"), "MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeOptionStruct desc")
}

func testMTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeTagStructParamsWave11() {
    let _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeTagStruct = MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeTagStruct()
    _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeTagStruct.mfgCode = n(1)
    _ = _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeTagStruct.mfgCode
    _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeTagStruct.value = n(1)
    _ = _MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeTagStruct.value
    mtrRequire(_MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeTagStruct.description.contains("MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeTagStruct"), "MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeTagStruct desc")
}

func testMTRServiceAreaClusterAreaInfoStructParamsWave11() {
    let _MTRServiceAreaClusterAreaInfoStruct = MTRServiceAreaClusterAreaInfoStruct()
    _MTRServiceAreaClusterAreaInfoStruct.landmarkInfo = MTRServiceAreaClusterLandmarkInfoStruct()
    _ = _MTRServiceAreaClusterAreaInfoStruct.landmarkInfo
    _MTRServiceAreaClusterAreaInfoStruct.locationInfo = MTRDataTypeLocationDescriptorStruct()
    _ = _MTRServiceAreaClusterAreaInfoStruct.locationInfo
    mtrRequire(_MTRServiceAreaClusterAreaInfoStruct.description.contains("MTRServiceAreaClusterAreaInfoStruct"), "MTRServiceAreaClusterAreaInfoStruct desc")
}

func testMTRServiceAreaClusterAreaStructParamsWave11() {
    let _MTRServiceAreaClusterAreaStruct = MTRServiceAreaClusterAreaStruct()
    _MTRServiceAreaClusterAreaStruct.areaID = n(1)
    _ = _MTRServiceAreaClusterAreaStruct.areaID
    _MTRServiceAreaClusterAreaStruct.areaInfo = MTRServiceAreaClusterAreaInfoStruct()
    _ = _MTRServiceAreaClusterAreaStruct.areaInfo
    _MTRServiceAreaClusterAreaStruct.mapID = n(1)
    _ = _MTRServiceAreaClusterAreaStruct.mapID
    mtrRequire(_MTRServiceAreaClusterAreaStruct.description.contains("MTRServiceAreaClusterAreaStruct"), "MTRServiceAreaClusterAreaStruct desc")
}

func testMTRServiceAreaClusterLandmarkInfoStructParamsWave11() {
    let _MTRServiceAreaClusterLandmarkInfoStruct = MTRServiceAreaClusterLandmarkInfoStruct()
    _MTRServiceAreaClusterLandmarkInfoStruct.landmarkTag = n(1)
    _ = _MTRServiceAreaClusterLandmarkInfoStruct.landmarkTag
    _MTRServiceAreaClusterLandmarkInfoStruct.relativePositionTag = n(1)
    _ = _MTRServiceAreaClusterLandmarkInfoStruct.relativePositionTag
    mtrRequire(_MTRServiceAreaClusterLandmarkInfoStruct.description.contains("MTRServiceAreaClusterLandmarkInfoStruct"), "MTRServiceAreaClusterLandmarkInfoStruct desc")
}

func testMTRServiceAreaClusterMapStructParamsWave11() {
    let _MTRServiceAreaClusterMapStruct = MTRServiceAreaClusterMapStruct()
    _MTRServiceAreaClusterMapStruct.mapID = n(1)
    _ = _MTRServiceAreaClusterMapStruct.mapID
    _MTRServiceAreaClusterMapStruct.name = "x"
    _ = _MTRServiceAreaClusterMapStruct.name
    mtrRequire(_MTRServiceAreaClusterMapStruct.description.contains("MTRServiceAreaClusterMapStruct"), "MTRServiceAreaClusterMapStruct desc")
}

func testMTRServiceAreaClusterProgressStructParamsWave11() {
    let _MTRServiceAreaClusterProgressStruct = MTRServiceAreaClusterProgressStruct()
    _MTRServiceAreaClusterProgressStruct.areaID = n(1)
    _ = _MTRServiceAreaClusterProgressStruct.areaID
    _MTRServiceAreaClusterProgressStruct.status = n(1)
    _ = _MTRServiceAreaClusterProgressStruct.status
    _MTRServiceAreaClusterProgressStruct.totalOperationalTime = n(1)
    _ = _MTRServiceAreaClusterProgressStruct.totalOperationalTime
    mtrRequire(_MTRServiceAreaClusterProgressStruct.description.contains("MTRServiceAreaClusterProgressStruct"), "MTRServiceAreaClusterProgressStruct desc")
}

func testMTRServiceAreaClusterSelectAreasParamsParamsWave11() {
    let _MTRServiceAreaClusterSelectAreasParams = MTRServiceAreaClusterSelectAreasParams()
    _MTRServiceAreaClusterSelectAreasParams.newAreas = [n(1)] as [Any]
    _ = _MTRServiceAreaClusterSelectAreasParams.newAreas
    _MTRServiceAreaClusterSelectAreasParams.serverSideProcessingTimeout = n(1)
    _ = _MTRServiceAreaClusterSelectAreasParams.serverSideProcessingTimeout
    _MTRServiceAreaClusterSelectAreasParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRServiceAreaClusterSelectAreasParams.timedInvokeTimeoutMs
    mtrRequire(_MTRServiceAreaClusterSelectAreasParams.description.contains("MTRServiceAreaClusterSelectAreasParams"), "MTRServiceAreaClusterSelectAreasParams desc")
}

func testMTRServiceAreaClusterSelectAreasResponseParamsParamsWave11() {
    let _MTRServiceAreaClusterSelectAreasResponseParams = (try? MTRServiceAreaClusterSelectAreasResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRServiceAreaClusterSelectAreasResponseParams()
    _MTRServiceAreaClusterSelectAreasResponseParams.status = n(1)
    _ = _MTRServiceAreaClusterSelectAreasResponseParams.status
    _MTRServiceAreaClusterSelectAreasResponseParams.statusText = "x"
    _ = _MTRServiceAreaClusterSelectAreasResponseParams.statusText
    mtrRequire(_MTRServiceAreaClusterSelectAreasResponseParams.description.contains("MTRServiceAreaClusterSelectAreasResponseParams"), "MTRServiceAreaClusterSelectAreasResponseParams desc")
}

func testMTRServiceAreaClusterSkipAreaParamsParamsWave11() {
    let _MTRServiceAreaClusterSkipAreaParams = MTRServiceAreaClusterSkipAreaParams()
    _MTRServiceAreaClusterSkipAreaParams.serverSideProcessingTimeout = n(1)
    _ = _MTRServiceAreaClusterSkipAreaParams.serverSideProcessingTimeout
    _MTRServiceAreaClusterSkipAreaParams.skippedArea = n(1)
    _ = _MTRServiceAreaClusterSkipAreaParams.skippedArea
    _MTRServiceAreaClusterSkipAreaParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRServiceAreaClusterSkipAreaParams.timedInvokeTimeoutMs
    mtrRequire(_MTRServiceAreaClusterSkipAreaParams.description.contains("MTRServiceAreaClusterSkipAreaParams"), "MTRServiceAreaClusterSkipAreaParams desc")
}

func testMTRServiceAreaClusterSkipAreaResponseParamsParamsWave11() {
    let _MTRServiceAreaClusterSkipAreaResponseParams = (try? MTRServiceAreaClusterSkipAreaResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRServiceAreaClusterSkipAreaResponseParams()
    _MTRServiceAreaClusterSkipAreaResponseParams.status = n(1)
    _ = _MTRServiceAreaClusterSkipAreaResponseParams.status
    _MTRServiceAreaClusterSkipAreaResponseParams.statusText = "x"
    _ = _MTRServiceAreaClusterSkipAreaResponseParams.statusText
    mtrRequire(_MTRServiceAreaClusterSkipAreaResponseParams.description.contains("MTRServiceAreaClusterSkipAreaResponseParams"), "MTRServiceAreaClusterSkipAreaResponseParams desc")
}

func testMTRSmokeCOAlarmClusterCOAlarmEventParamsWave11() {
    let _MTRSmokeCOAlarmClusterCOAlarmEvent = MTRSmokeCOAlarmClusterCOAlarmEvent()
    _MTRSmokeCOAlarmClusterCOAlarmEvent.alarmSeverityLevel = n(1)
    _ = _MTRSmokeCOAlarmClusterCOAlarmEvent.alarmSeverityLevel
    mtrRequire(_MTRSmokeCOAlarmClusterCOAlarmEvent.description.contains("MTRSmokeCOAlarmClusterCOAlarmEvent"), "MTRSmokeCOAlarmClusterCOAlarmEvent desc")
}

func testMTRSmokeCOAlarmClusterInterconnectCOAlarmEventParamsWave11() {
    let _MTRSmokeCOAlarmClusterInterconnectCOAlarmEvent = MTRSmokeCOAlarmClusterInterconnectCOAlarmEvent()
    _MTRSmokeCOAlarmClusterInterconnectCOAlarmEvent.alarmSeverityLevel = n(1)
    _ = _MTRSmokeCOAlarmClusterInterconnectCOAlarmEvent.alarmSeverityLevel
    mtrRequire(_MTRSmokeCOAlarmClusterInterconnectCOAlarmEvent.description.contains("MTRSmokeCOAlarmClusterInterconnectCOAlarmEvent"), "MTRSmokeCOAlarmClusterInterconnectCOAlarmEvent desc")
}

func testMTRSmokeCOAlarmClusterInterconnectSmokeAlarmEventParamsWave11() {
    let _MTRSmokeCOAlarmClusterInterconnectSmokeAlarmEvent = MTRSmokeCOAlarmClusterInterconnectSmokeAlarmEvent()
    _MTRSmokeCOAlarmClusterInterconnectSmokeAlarmEvent.alarmSeverityLevel = n(1)
    _ = _MTRSmokeCOAlarmClusterInterconnectSmokeAlarmEvent.alarmSeverityLevel
    mtrRequire(_MTRSmokeCOAlarmClusterInterconnectSmokeAlarmEvent.description.contains("MTRSmokeCOAlarmClusterInterconnectSmokeAlarmEvent"), "MTRSmokeCOAlarmClusterInterconnectSmokeAlarmEvent desc")
}

func testMTRSmokeCOAlarmClusterLowBatteryEventParamsWave11() {
    let _MTRSmokeCOAlarmClusterLowBatteryEvent = MTRSmokeCOAlarmClusterLowBatteryEvent()
    _MTRSmokeCOAlarmClusterLowBatteryEvent.alarmSeverityLevel = n(1)
    _ = _MTRSmokeCOAlarmClusterLowBatteryEvent.alarmSeverityLevel
    mtrRequire(_MTRSmokeCOAlarmClusterLowBatteryEvent.description.contains("MTRSmokeCOAlarmClusterLowBatteryEvent"), "MTRSmokeCOAlarmClusterLowBatteryEvent desc")
}

func testMTRSmokeCOAlarmClusterSelfTestRequestParamsParamsWave11() {
    let _MTRSmokeCOAlarmClusterSelfTestRequestParams = MTRSmokeCOAlarmClusterSelfTestRequestParams()
    _MTRSmokeCOAlarmClusterSelfTestRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRSmokeCOAlarmClusterSelfTestRequestParams.serverSideProcessingTimeout
    _MTRSmokeCOAlarmClusterSelfTestRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRSmokeCOAlarmClusterSelfTestRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRSmokeCOAlarmClusterSelfTestRequestParams.description.contains("MTRSmokeCOAlarmClusterSelfTestRequestParams"), "MTRSmokeCOAlarmClusterSelfTestRequestParams desc")
}

func testMTRSmokeCOAlarmClusterSmokeAlarmEventParamsWave11() {
    let _MTRSmokeCOAlarmClusterSmokeAlarmEvent = MTRSmokeCOAlarmClusterSmokeAlarmEvent()
    _MTRSmokeCOAlarmClusterSmokeAlarmEvent.alarmSeverityLevel = n(1)
    _ = _MTRSmokeCOAlarmClusterSmokeAlarmEvent.alarmSeverityLevel
    mtrRequire(_MTRSmokeCOAlarmClusterSmokeAlarmEvent.description.contains("MTRSmokeCOAlarmClusterSmokeAlarmEvent"), "MTRSmokeCOAlarmClusterSmokeAlarmEvent desc")
}

func testMTRSoftwareDiagnosticsClusterResetWatermarksParamsParamsWave11() {
    let _MTRSoftwareDiagnosticsClusterResetWatermarksParams = MTRSoftwareDiagnosticsClusterResetWatermarksParams()
    _MTRSoftwareDiagnosticsClusterResetWatermarksParams.serverSideProcessingTimeout = n(1)
    _ = _MTRSoftwareDiagnosticsClusterResetWatermarksParams.serverSideProcessingTimeout
    _MTRSoftwareDiagnosticsClusterResetWatermarksParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRSoftwareDiagnosticsClusterResetWatermarksParams.timedInvokeTimeoutMs
    mtrRequire(_MTRSoftwareDiagnosticsClusterResetWatermarksParams.description.contains("MTRSoftwareDiagnosticsClusterResetWatermarksParams"), "MTRSoftwareDiagnosticsClusterResetWatermarksParams desc")
}

func testMTRSoftwareDiagnosticsClusterSoftwareFaultEventParamsWave11() {
    let _MTRSoftwareDiagnosticsClusterSoftwareFaultEvent = MTRSoftwareDiagnosticsClusterSoftwareFaultEvent()
    _MTRSoftwareDiagnosticsClusterSoftwareFaultEvent.faultRecording = Data([1])
    _ = _MTRSoftwareDiagnosticsClusterSoftwareFaultEvent.faultRecording
    _MTRSoftwareDiagnosticsClusterSoftwareFaultEvent.id = n(1)
    _ = _MTRSoftwareDiagnosticsClusterSoftwareFaultEvent.id
    _MTRSoftwareDiagnosticsClusterSoftwareFaultEvent.name = "x"
    _ = _MTRSoftwareDiagnosticsClusterSoftwareFaultEvent.name
    mtrRequire(_MTRSoftwareDiagnosticsClusterSoftwareFaultEvent.description.contains("MTRSoftwareDiagnosticsClusterSoftwareFaultEvent"), "MTRSoftwareDiagnosticsClusterSoftwareFaultEvent desc")
}

func testMTRSoftwareDiagnosticsClusterThreadMetricsParamsWave11() {
    let _MTRSoftwareDiagnosticsClusterThreadMetrics = MTRSoftwareDiagnosticsClusterThreadMetrics()
    _MTRSoftwareDiagnosticsClusterThreadMetrics.id = n(1)
    _ = _MTRSoftwareDiagnosticsClusterThreadMetrics.id
    _MTRSoftwareDiagnosticsClusterThreadMetrics.name = "x"
    _ = _MTRSoftwareDiagnosticsClusterThreadMetrics.name
    _MTRSoftwareDiagnosticsClusterThreadMetrics.stackFreeCurrent = n(1)
    _ = _MTRSoftwareDiagnosticsClusterThreadMetrics.stackFreeCurrent
    _MTRSoftwareDiagnosticsClusterThreadMetrics.stackFreeMinimum = n(1)
    _ = _MTRSoftwareDiagnosticsClusterThreadMetrics.stackFreeMinimum
    _MTRSoftwareDiagnosticsClusterThreadMetrics.stackSize = n(1)
    _ = _MTRSoftwareDiagnosticsClusterThreadMetrics.stackSize
    mtrRequire(!_MTRSoftwareDiagnosticsClusterThreadMetrics.description.isEmpty, "MTRSoftwareDiagnosticsClusterThreadMetrics desc")
}

func testMTRSoftwareDiagnosticsClusterThreadMetricsStructParamsWave11() {
    let _MTRSoftwareDiagnosticsClusterThreadMetricsStruct = MTRSoftwareDiagnosticsClusterThreadMetricsStruct()
    _MTRSoftwareDiagnosticsClusterThreadMetricsStruct.id = n(1)
    _ = _MTRSoftwareDiagnosticsClusterThreadMetricsStruct.id
    _MTRSoftwareDiagnosticsClusterThreadMetricsStruct.name = "x"
    _ = _MTRSoftwareDiagnosticsClusterThreadMetricsStruct.name
    _MTRSoftwareDiagnosticsClusterThreadMetricsStruct.stackFreeCurrent = n(1)
    _ = _MTRSoftwareDiagnosticsClusterThreadMetricsStruct.stackFreeCurrent
    _MTRSoftwareDiagnosticsClusterThreadMetricsStruct.stackFreeMinimum = n(1)
    _ = _MTRSoftwareDiagnosticsClusterThreadMetricsStruct.stackFreeMinimum
    _MTRSoftwareDiagnosticsClusterThreadMetricsStruct.stackSize = n(1)
    _ = _MTRSoftwareDiagnosticsClusterThreadMetricsStruct.stackSize
    mtrRequire(_MTRSoftwareDiagnosticsClusterThreadMetricsStruct.description.contains("MTRSoftwareDiagnosticsClusterThreadMetricsStruct"), "MTRSoftwareDiagnosticsClusterThreadMetricsStruct desc")
}

