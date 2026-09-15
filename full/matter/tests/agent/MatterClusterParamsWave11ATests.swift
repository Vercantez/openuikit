import Foundation
import Dispatch
import Matter

func testMTRAccessControlClusterAccessControlEntryParamsWave11() {
    let _MTRAccessControlClusterAccessControlEntry = MTRAccessControlClusterAccessControlEntry()
    _MTRAccessControlClusterAccessControlEntry.authMode = n(1)
    _ = _MTRAccessControlClusterAccessControlEntry.authMode
    _MTRAccessControlClusterAccessControlEntry.fabricIndex = n(1)
    _ = _MTRAccessControlClusterAccessControlEntry.fabricIndex
    _MTRAccessControlClusterAccessControlEntry.privilege = n(1)
    _ = _MTRAccessControlClusterAccessControlEntry.privilege
    _MTRAccessControlClusterAccessControlEntry.subjects = [n(1)] as [Any]
    _ = _MTRAccessControlClusterAccessControlEntry.subjects
    _MTRAccessControlClusterAccessControlEntry.targets = [n(1)] as [Any]
    _ = _MTRAccessControlClusterAccessControlEntry.targets
    mtrRequire(!_MTRAccessControlClusterAccessControlEntry.description.isEmpty, "MTRAccessControlClusterAccessControlEntry desc")
}

func testMTRAccessControlClusterAccessControlEntryChangedEventParamsWave11() {
    let _MTRAccessControlClusterAccessControlEntryChangedEvent = MTRAccessControlClusterAccessControlEntryChangedEvent()
    _MTRAccessControlClusterAccessControlEntryChangedEvent.adminNodeID = n(1)
    _ = _MTRAccessControlClusterAccessControlEntryChangedEvent.adminNodeID
    _MTRAccessControlClusterAccessControlEntryChangedEvent.adminPasscodeID = n(1)
    _ = _MTRAccessControlClusterAccessControlEntryChangedEvent.adminPasscodeID
    _MTRAccessControlClusterAccessControlEntryChangedEvent.changeType = n(1)
    _ = _MTRAccessControlClusterAccessControlEntryChangedEvent.changeType
    _MTRAccessControlClusterAccessControlEntryChangedEvent.fabricIndex = n(1)
    _ = _MTRAccessControlClusterAccessControlEntryChangedEvent.fabricIndex
    _MTRAccessControlClusterAccessControlEntryChangedEvent.latestValue = MTRAccessControlClusterAccessControlEntryStruct()
    _ = _MTRAccessControlClusterAccessControlEntryChangedEvent.latestValue
    mtrRequire(_MTRAccessControlClusterAccessControlEntryChangedEvent.description.contains("MTRAccessControlClusterAccessControlEntryChangedEvent"), "MTRAccessControlClusterAccessControlEntryChangedEvent desc")
}

func testMTRAccessControlClusterAccessControlEntryStructParamsWave11() {
    let _MTRAccessControlClusterAccessControlEntryStruct = MTRAccessControlClusterAccessControlEntryStruct()
    _MTRAccessControlClusterAccessControlEntryStruct.authMode = n(1)
    _ = _MTRAccessControlClusterAccessControlEntryStruct.authMode
    _MTRAccessControlClusterAccessControlEntryStruct.fabricIndex = n(1)
    _ = _MTRAccessControlClusterAccessControlEntryStruct.fabricIndex
    _MTRAccessControlClusterAccessControlEntryStruct.privilege = n(1)
    _ = _MTRAccessControlClusterAccessControlEntryStruct.privilege
    _MTRAccessControlClusterAccessControlEntryStruct.subjects = [n(1)] as [Any]
    _ = _MTRAccessControlClusterAccessControlEntryStruct.subjects
    _MTRAccessControlClusterAccessControlEntryStruct.targets = [n(1)] as [Any]
    _ = _MTRAccessControlClusterAccessControlEntryStruct.targets
    mtrRequire(_MTRAccessControlClusterAccessControlEntryStruct.description.contains("MTRAccessControlClusterAccessControlEntryStruct"), "MTRAccessControlClusterAccessControlEntryStruct desc")
}

func testMTRAccessControlClusterAccessControlExtensionChangedEventParamsWave11() {
    let _MTRAccessControlClusterAccessControlExtensionChangedEvent = MTRAccessControlClusterAccessControlExtensionChangedEvent()
    _MTRAccessControlClusterAccessControlExtensionChangedEvent.adminNodeID = n(1)
    _ = _MTRAccessControlClusterAccessControlExtensionChangedEvent.adminNodeID
    _MTRAccessControlClusterAccessControlExtensionChangedEvent.adminPasscodeID = n(1)
    _ = _MTRAccessControlClusterAccessControlExtensionChangedEvent.adminPasscodeID
    _MTRAccessControlClusterAccessControlExtensionChangedEvent.changeType = n(1)
    _ = _MTRAccessControlClusterAccessControlExtensionChangedEvent.changeType
    _MTRAccessControlClusterAccessControlExtensionChangedEvent.fabricIndex = n(1)
    _ = _MTRAccessControlClusterAccessControlExtensionChangedEvent.fabricIndex
    _MTRAccessControlClusterAccessControlExtensionChangedEvent.latestValue = MTRAccessControlClusterAccessControlExtensionStruct()
    _ = _MTRAccessControlClusterAccessControlExtensionChangedEvent.latestValue
    mtrRequire(_MTRAccessControlClusterAccessControlExtensionChangedEvent.description.contains("MTRAccessControlClusterAccessControlExtensionChangedEvent"), "MTRAccessControlClusterAccessControlExtensionChangedEvent desc")
}

func testMTRAccessControlClusterAccessControlExtensionStructParamsWave11() {
    let _MTRAccessControlClusterAccessControlExtensionStruct = MTRAccessControlClusterAccessControlExtensionStruct()
    _MTRAccessControlClusterAccessControlExtensionStruct.data = Data([1])
    _ = _MTRAccessControlClusterAccessControlExtensionStruct.data
    _MTRAccessControlClusterAccessControlExtensionStruct.fabricIndex = n(1)
    _ = _MTRAccessControlClusterAccessControlExtensionStruct.fabricIndex
    mtrRequire(_MTRAccessControlClusterAccessControlExtensionStruct.description.contains("MTRAccessControlClusterAccessControlExtensionStruct"), "MTRAccessControlClusterAccessControlExtensionStruct desc")
}

func testMTRAccessControlClusterAccessControlTargetStructParamsWave11() {
    let _MTRAccessControlClusterAccessControlTargetStruct = MTRAccessControlClusterAccessControlTargetStruct()
    _MTRAccessControlClusterAccessControlTargetStruct.cluster = n(1)
    _ = _MTRAccessControlClusterAccessControlTargetStruct.cluster
    _MTRAccessControlClusterAccessControlTargetStruct.deviceType = n(1)
    _ = _MTRAccessControlClusterAccessControlTargetStruct.deviceType
    _MTRAccessControlClusterAccessControlTargetStruct.endpoint = n(1)
    _ = _MTRAccessControlClusterAccessControlTargetStruct.endpoint
    mtrRequire(_MTRAccessControlClusterAccessControlTargetStruct.description.contains("MTRAccessControlClusterAccessControlTargetStruct"), "MTRAccessControlClusterAccessControlTargetStruct desc")
}

func testMTRAccessControlClusterAccessRestrictionEntryStructParamsWave11() {
    let _MTRAccessControlClusterAccessRestrictionEntryStruct = MTRAccessControlClusterAccessRestrictionEntryStruct()
    _MTRAccessControlClusterAccessRestrictionEntryStruct.cluster = n(1)
    _ = _MTRAccessControlClusterAccessRestrictionEntryStruct.cluster
    _MTRAccessControlClusterAccessRestrictionEntryStruct.endpoint = n(1)
    _ = _MTRAccessControlClusterAccessRestrictionEntryStruct.endpoint
    _MTRAccessControlClusterAccessRestrictionEntryStruct.fabricIndex = n(1)
    _ = _MTRAccessControlClusterAccessRestrictionEntryStruct.fabricIndex
    _MTRAccessControlClusterAccessRestrictionEntryStruct.restrictions = [n(1)] as [Any]
    _ = _MTRAccessControlClusterAccessRestrictionEntryStruct.restrictions
    mtrRequire(_MTRAccessControlClusterAccessRestrictionEntryStruct.description.contains("MTRAccessControlClusterAccessRestrictionEntryStruct"), "MTRAccessControlClusterAccessRestrictionEntryStruct desc")
}

func testMTRAccessControlClusterAccessRestrictionStructParamsWave11() {
    let _MTRAccessControlClusterAccessRestrictionStruct = MTRAccessControlClusterAccessRestrictionStruct()
    _MTRAccessControlClusterAccessRestrictionStruct.id = n(1)
    _ = _MTRAccessControlClusterAccessRestrictionStruct.id
    _MTRAccessControlClusterAccessRestrictionStruct.`type` = n(1)
    _ = _MTRAccessControlClusterAccessRestrictionStruct.`type`
    mtrRequire(_MTRAccessControlClusterAccessRestrictionStruct.description.contains("MTRAccessControlClusterAccessRestrictionStruct"), "MTRAccessControlClusterAccessRestrictionStruct desc")
}

func testMTRAccessControlClusterCommissioningAccessRestrictionEntryStructParamsWave11() {
    let _MTRAccessControlClusterCommissioningAccessRestrictionEntryStruct = MTRAccessControlClusterCommissioningAccessRestrictionEntryStruct()
    _MTRAccessControlClusterCommissioningAccessRestrictionEntryStruct.cluster = n(1)
    _ = _MTRAccessControlClusterCommissioningAccessRestrictionEntryStruct.cluster
    _MTRAccessControlClusterCommissioningAccessRestrictionEntryStruct.endpoint = n(1)
    _ = _MTRAccessControlClusterCommissioningAccessRestrictionEntryStruct.endpoint
    _MTRAccessControlClusterCommissioningAccessRestrictionEntryStruct.restrictions = [n(1)] as [Any]
    _ = _MTRAccessControlClusterCommissioningAccessRestrictionEntryStruct.restrictions
    mtrRequire(_MTRAccessControlClusterCommissioningAccessRestrictionEntryStruct.description.contains("MTRAccessControlClusterCommissioningAccessRestrictionEntryStruct"), "MTRAccessControlClusterCommissioningAccessRestrictionEntryStruct desc")
}

func testMTRAccessControlClusterExtensionEntryParamsWave11() {
    let _MTRAccessControlClusterExtensionEntry = MTRAccessControlClusterExtensionEntry()
    _MTRAccessControlClusterExtensionEntry.data = Data([1])
    _ = _MTRAccessControlClusterExtensionEntry.data
    _MTRAccessControlClusterExtensionEntry.fabricIndex = n(1)
    _ = _MTRAccessControlClusterExtensionEntry.fabricIndex
    mtrRequire(!_MTRAccessControlClusterExtensionEntry.description.isEmpty, "MTRAccessControlClusterExtensionEntry desc")
}

func testMTRAccessControlClusterFabricRestrictionReviewUpdateEventParamsWave11() {
    let _MTRAccessControlClusterFabricRestrictionReviewUpdateEvent = MTRAccessControlClusterFabricRestrictionReviewUpdateEvent()
    _MTRAccessControlClusterFabricRestrictionReviewUpdateEvent.fabricIndex = n(1)
    _ = _MTRAccessControlClusterFabricRestrictionReviewUpdateEvent.fabricIndex
    _MTRAccessControlClusterFabricRestrictionReviewUpdateEvent.instruction = "x"
    _ = _MTRAccessControlClusterFabricRestrictionReviewUpdateEvent.instruction
    _MTRAccessControlClusterFabricRestrictionReviewUpdateEvent.token = n(1)
    _ = _MTRAccessControlClusterFabricRestrictionReviewUpdateEvent.token
    mtrRequire(_MTRAccessControlClusterFabricRestrictionReviewUpdateEvent.description.contains("MTRAccessControlClusterFabricRestrictionReviewUpdateEvent"), "MTRAccessControlClusterFabricRestrictionReviewUpdateEvent desc")
}

func testMTRAccessControlClusterReviewFabricRestrictionsParamsParamsWave11() {
    let _MTRAccessControlClusterReviewFabricRestrictionsParams = MTRAccessControlClusterReviewFabricRestrictionsParams()
    _MTRAccessControlClusterReviewFabricRestrictionsParams.arl = [n(1)] as [Any]
    _ = _MTRAccessControlClusterReviewFabricRestrictionsParams.arl
    _MTRAccessControlClusterReviewFabricRestrictionsParams.serverSideProcessingTimeout = n(1)
    _ = _MTRAccessControlClusterReviewFabricRestrictionsParams.serverSideProcessingTimeout
    _MTRAccessControlClusterReviewFabricRestrictionsParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRAccessControlClusterReviewFabricRestrictionsParams.timedInvokeTimeoutMs
    mtrRequire(_MTRAccessControlClusterReviewFabricRestrictionsParams.description.contains("MTRAccessControlClusterReviewFabricRestrictionsParams"), "MTRAccessControlClusterReviewFabricRestrictionsParams desc")
}

func testMTRAccessControlClusterReviewFabricRestrictionsResponseParamsParamsWave11() {
    let _MTRAccessControlClusterReviewFabricRestrictionsResponseParams = (try? MTRAccessControlClusterReviewFabricRestrictionsResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRAccessControlClusterReviewFabricRestrictionsResponseParams()
    _MTRAccessControlClusterReviewFabricRestrictionsResponseParams.token = n(1)
    _ = _MTRAccessControlClusterReviewFabricRestrictionsResponseParams.token
    mtrRequire(_MTRAccessControlClusterReviewFabricRestrictionsResponseParams.description.contains("MTRAccessControlClusterReviewFabricRestrictionsResponseParams"), "MTRAccessControlClusterReviewFabricRestrictionsResponseParams desc")
}

func testMTRAccessControlClusterTargetParamsWave11() {
    let _MTRAccessControlClusterTarget = MTRAccessControlClusterTarget()
    _MTRAccessControlClusterTarget.cluster = n(1)
    _ = _MTRAccessControlClusterTarget.cluster
    _MTRAccessControlClusterTarget.deviceType = n(1)
    _ = _MTRAccessControlClusterTarget.deviceType
    _MTRAccessControlClusterTarget.endpoint = n(1)
    _ = _MTRAccessControlClusterTarget.endpoint
    mtrRequire(!_MTRAccessControlClusterTarget.description.isEmpty, "MTRAccessControlClusterTarget desc")
}

func testMTRAccountLoginClusterGetSetupPINParamsParamsWave11() {
    let _MTRAccountLoginClusterGetSetupPINParams = MTRAccountLoginClusterGetSetupPINParams()
    _MTRAccountLoginClusterGetSetupPINParams.serverSideProcessingTimeout = n(1)
    _ = _MTRAccountLoginClusterGetSetupPINParams.serverSideProcessingTimeout
    _MTRAccountLoginClusterGetSetupPINParams.tempAccountIdentifier = "x"
    _ = _MTRAccountLoginClusterGetSetupPINParams.tempAccountIdentifier
    _MTRAccountLoginClusterGetSetupPINParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRAccountLoginClusterGetSetupPINParams.timedInvokeTimeoutMs
    mtrRequire(_MTRAccountLoginClusterGetSetupPINParams.description.contains("MTRAccountLoginClusterGetSetupPINParams"), "MTRAccountLoginClusterGetSetupPINParams desc")
}

func testMTRAccountLoginClusterGetSetupPINResponseParamsParamsWave11() {
    let _MTRAccountLoginClusterGetSetupPINResponseParams = (try? MTRAccountLoginClusterGetSetupPINResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRAccountLoginClusterGetSetupPINResponseParams()
    _MTRAccountLoginClusterGetSetupPINResponseParams.setupPIN = "x"
    _ = _MTRAccountLoginClusterGetSetupPINResponseParams.setupPIN
    _MTRAccountLoginClusterGetSetupPINResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRAccountLoginClusterGetSetupPINResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRAccountLoginClusterGetSetupPINResponseParams.description.contains("MTRAccountLoginClusterGetSetupPINResponseParams"), "MTRAccountLoginClusterGetSetupPINResponseParams desc")
}

func testMTRAccountLoginClusterLoggedOutEventParamsWave11() {
    let _MTRAccountLoginClusterLoggedOutEvent = MTRAccountLoginClusterLoggedOutEvent()
    _MTRAccountLoginClusterLoggedOutEvent.node = n(1)
    _ = _MTRAccountLoginClusterLoggedOutEvent.node
    mtrRequire(_MTRAccountLoginClusterLoggedOutEvent.description.contains("MTRAccountLoginClusterLoggedOutEvent"), "MTRAccountLoginClusterLoggedOutEvent desc")
}

func testMTRAccountLoginClusterLoginParamsParamsWave11() {
    let _MTRAccountLoginClusterLoginParams = MTRAccountLoginClusterLoginParams()
    _MTRAccountLoginClusterLoginParams.node = n(1)
    _ = _MTRAccountLoginClusterLoginParams.node
    _MTRAccountLoginClusterLoginParams.serverSideProcessingTimeout = n(1)
    _ = _MTRAccountLoginClusterLoginParams.serverSideProcessingTimeout
    _MTRAccountLoginClusterLoginParams.setupPIN = "x"
    _ = _MTRAccountLoginClusterLoginParams.setupPIN
    _MTRAccountLoginClusterLoginParams.tempAccountIdentifier = "x"
    _ = _MTRAccountLoginClusterLoginParams.tempAccountIdentifier
    _MTRAccountLoginClusterLoginParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRAccountLoginClusterLoginParams.timedInvokeTimeoutMs
    mtrRequire(_MTRAccountLoginClusterLoginParams.description.contains("MTRAccountLoginClusterLoginParams"), "MTRAccountLoginClusterLoginParams desc")
}

func testMTRAccountLoginClusterLogoutParamsParamsWave11() {
    let _MTRAccountLoginClusterLogoutParams = MTRAccountLoginClusterLogoutParams()
    _MTRAccountLoginClusterLogoutParams.node = n(1)
    _ = _MTRAccountLoginClusterLogoutParams.node
    _MTRAccountLoginClusterLogoutParams.serverSideProcessingTimeout = n(1)
    _ = _MTRAccountLoginClusterLogoutParams.serverSideProcessingTimeout
    _MTRAccountLoginClusterLogoutParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRAccountLoginClusterLogoutParams.timedInvokeTimeoutMs
    mtrRequire(_MTRAccountLoginClusterLogoutParams.description.contains("MTRAccountLoginClusterLogoutParams"), "MTRAccountLoginClusterLogoutParams desc")
}

func testMTRActionsClusterActionFailedEventParamsWave11() {
    let _MTRActionsClusterActionFailedEvent = MTRActionsClusterActionFailedEvent()
    _MTRActionsClusterActionFailedEvent.actionID = n(1)
    _ = _MTRActionsClusterActionFailedEvent.actionID
    _MTRActionsClusterActionFailedEvent.error = n(1)
    _ = _MTRActionsClusterActionFailedEvent.error
    _MTRActionsClusterActionFailedEvent.invokeID = n(1)
    _ = _MTRActionsClusterActionFailedEvent.invokeID
    _MTRActionsClusterActionFailedEvent.newState = n(1)
    _ = _MTRActionsClusterActionFailedEvent.newState
    mtrRequire(_MTRActionsClusterActionFailedEvent.description.contains("MTRActionsClusterActionFailedEvent"), "MTRActionsClusterActionFailedEvent desc")
}

func testMTRActionsClusterActionStructParamsWave11() {
    let _MTRActionsClusterActionStruct = MTRActionsClusterActionStruct()
    _MTRActionsClusterActionStruct.actionID = n(1)
    _ = _MTRActionsClusterActionStruct.actionID
    _MTRActionsClusterActionStruct.endpointListID = n(1)
    _ = _MTRActionsClusterActionStruct.endpointListID
    _MTRActionsClusterActionStruct.name = "x"
    _ = _MTRActionsClusterActionStruct.name
    _MTRActionsClusterActionStruct.state = n(1)
    _ = _MTRActionsClusterActionStruct.state
    _MTRActionsClusterActionStruct.supportedCommands = n(1)
    _ = _MTRActionsClusterActionStruct.supportedCommands
    _MTRActionsClusterActionStruct.`type` = n(1)
    _ = _MTRActionsClusterActionStruct.`type`
    mtrRequire(_MTRActionsClusterActionStruct.description.contains("MTRActionsClusterActionStruct"), "MTRActionsClusterActionStruct desc")
}

func testMTRActionsClusterDisableActionParamsParamsWave11() {
    let _MTRActionsClusterDisableActionParams = MTRActionsClusterDisableActionParams()
    _MTRActionsClusterDisableActionParams.actionID = n(1)
    _ = _MTRActionsClusterDisableActionParams.actionID
    _MTRActionsClusterDisableActionParams.invokeID = n(1)
    _ = _MTRActionsClusterDisableActionParams.invokeID
    _MTRActionsClusterDisableActionParams.serverSideProcessingTimeout = n(1)
    _ = _MTRActionsClusterDisableActionParams.serverSideProcessingTimeout
    _MTRActionsClusterDisableActionParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRActionsClusterDisableActionParams.timedInvokeTimeoutMs
    mtrRequire(_MTRActionsClusterDisableActionParams.description.contains("MTRActionsClusterDisableActionParams"), "MTRActionsClusterDisableActionParams desc")
}

func testMTRActionsClusterDisableActionWithDurationParamsParamsWave11() {
    let _MTRActionsClusterDisableActionWithDurationParams = MTRActionsClusterDisableActionWithDurationParams()
    _MTRActionsClusterDisableActionWithDurationParams.actionID = n(1)
    _ = _MTRActionsClusterDisableActionWithDurationParams.actionID
    _MTRActionsClusterDisableActionWithDurationParams.duration = n(1)
    _ = _MTRActionsClusterDisableActionWithDurationParams.duration
    _MTRActionsClusterDisableActionWithDurationParams.invokeID = n(1)
    _ = _MTRActionsClusterDisableActionWithDurationParams.invokeID
    _MTRActionsClusterDisableActionWithDurationParams.serverSideProcessingTimeout = n(1)
    _ = _MTRActionsClusterDisableActionWithDurationParams.serverSideProcessingTimeout
    _MTRActionsClusterDisableActionWithDurationParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRActionsClusterDisableActionWithDurationParams.timedInvokeTimeoutMs
    mtrRequire(_MTRActionsClusterDisableActionWithDurationParams.description.contains("MTRActionsClusterDisableActionWithDurationParams"), "MTRActionsClusterDisableActionWithDurationParams desc")
}

func testMTRActionsClusterEnableActionParamsParamsWave11() {
    let _MTRActionsClusterEnableActionParams = MTRActionsClusterEnableActionParams()
    _MTRActionsClusterEnableActionParams.actionID = n(1)
    _ = _MTRActionsClusterEnableActionParams.actionID
    _MTRActionsClusterEnableActionParams.invokeID = n(1)
    _ = _MTRActionsClusterEnableActionParams.invokeID
    _MTRActionsClusterEnableActionParams.serverSideProcessingTimeout = n(1)
    _ = _MTRActionsClusterEnableActionParams.serverSideProcessingTimeout
    _MTRActionsClusterEnableActionParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRActionsClusterEnableActionParams.timedInvokeTimeoutMs
    mtrRequire(_MTRActionsClusterEnableActionParams.description.contains("MTRActionsClusterEnableActionParams"), "MTRActionsClusterEnableActionParams desc")
}

func testMTRActionsClusterEnableActionWithDurationParamsParamsWave11() {
    let _MTRActionsClusterEnableActionWithDurationParams = MTRActionsClusterEnableActionWithDurationParams()
    _MTRActionsClusterEnableActionWithDurationParams.actionID = n(1)
    _ = _MTRActionsClusterEnableActionWithDurationParams.actionID
    _MTRActionsClusterEnableActionWithDurationParams.duration = n(1)
    _ = _MTRActionsClusterEnableActionWithDurationParams.duration
    _MTRActionsClusterEnableActionWithDurationParams.invokeID = n(1)
    _ = _MTRActionsClusterEnableActionWithDurationParams.invokeID
    _MTRActionsClusterEnableActionWithDurationParams.serverSideProcessingTimeout = n(1)
    _ = _MTRActionsClusterEnableActionWithDurationParams.serverSideProcessingTimeout
    _MTRActionsClusterEnableActionWithDurationParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRActionsClusterEnableActionWithDurationParams.timedInvokeTimeoutMs
    mtrRequire(_MTRActionsClusterEnableActionWithDurationParams.description.contains("MTRActionsClusterEnableActionWithDurationParams"), "MTRActionsClusterEnableActionWithDurationParams desc")
}

func testMTRActionsClusterEndpointListStructParamsWave11() {
    let _MTRActionsClusterEndpointListStruct = MTRActionsClusterEndpointListStruct()
    _MTRActionsClusterEndpointListStruct.endpointListID = n(1)
    _ = _MTRActionsClusterEndpointListStruct.endpointListID
    _MTRActionsClusterEndpointListStruct.endpoints = [n(1)] as [Any]
    _ = _MTRActionsClusterEndpointListStruct.endpoints
    _MTRActionsClusterEndpointListStruct.name = "x"
    _ = _MTRActionsClusterEndpointListStruct.name
    _MTRActionsClusterEndpointListStruct.`type` = n(1)
    _ = _MTRActionsClusterEndpointListStruct.`type`
    mtrRequire(_MTRActionsClusterEndpointListStruct.description.contains("MTRActionsClusterEndpointListStruct"), "MTRActionsClusterEndpointListStruct desc")
}

func testMTRActionsClusterInstantActionParamsParamsWave11() {
    let _MTRActionsClusterInstantActionParams = MTRActionsClusterInstantActionParams()
    _MTRActionsClusterInstantActionParams.actionID = n(1)
    _ = _MTRActionsClusterInstantActionParams.actionID
    _MTRActionsClusterInstantActionParams.invokeID = n(1)
    _ = _MTRActionsClusterInstantActionParams.invokeID
    _MTRActionsClusterInstantActionParams.serverSideProcessingTimeout = n(1)
    _ = _MTRActionsClusterInstantActionParams.serverSideProcessingTimeout
    _MTRActionsClusterInstantActionParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRActionsClusterInstantActionParams.timedInvokeTimeoutMs
    mtrRequire(_MTRActionsClusterInstantActionParams.description.contains("MTRActionsClusterInstantActionParams"), "MTRActionsClusterInstantActionParams desc")
}

func testMTRActionsClusterInstantActionWithTransitionParamsParamsWave11() {
    let _MTRActionsClusterInstantActionWithTransitionParams = MTRActionsClusterInstantActionWithTransitionParams()
    _MTRActionsClusterInstantActionWithTransitionParams.actionID = n(1)
    _ = _MTRActionsClusterInstantActionWithTransitionParams.actionID
    _MTRActionsClusterInstantActionWithTransitionParams.invokeID = n(1)
    _ = _MTRActionsClusterInstantActionWithTransitionParams.invokeID
    _MTRActionsClusterInstantActionWithTransitionParams.serverSideProcessingTimeout = n(1)
    _ = _MTRActionsClusterInstantActionWithTransitionParams.serverSideProcessingTimeout
    _MTRActionsClusterInstantActionWithTransitionParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRActionsClusterInstantActionWithTransitionParams.timedInvokeTimeoutMs
    _MTRActionsClusterInstantActionWithTransitionParams.transitionTime = n(1)
    _ = _MTRActionsClusterInstantActionWithTransitionParams.transitionTime
    mtrRequire(_MTRActionsClusterInstantActionWithTransitionParams.description.contains("MTRActionsClusterInstantActionWithTransitionParams"), "MTRActionsClusterInstantActionWithTransitionParams desc")
}

func testMTRActionsClusterPauseActionParamsParamsWave11() {
    let _MTRActionsClusterPauseActionParams = MTRActionsClusterPauseActionParams()
    _MTRActionsClusterPauseActionParams.actionID = n(1)
    _ = _MTRActionsClusterPauseActionParams.actionID
    _MTRActionsClusterPauseActionParams.invokeID = n(1)
    _ = _MTRActionsClusterPauseActionParams.invokeID
    _MTRActionsClusterPauseActionParams.serverSideProcessingTimeout = n(1)
    _ = _MTRActionsClusterPauseActionParams.serverSideProcessingTimeout
    _MTRActionsClusterPauseActionParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRActionsClusterPauseActionParams.timedInvokeTimeoutMs
    mtrRequire(_MTRActionsClusterPauseActionParams.description.contains("MTRActionsClusterPauseActionParams"), "MTRActionsClusterPauseActionParams desc")
}

func testMTRActionsClusterPauseActionWithDurationParamsParamsWave11() {
    let _MTRActionsClusterPauseActionWithDurationParams = MTRActionsClusterPauseActionWithDurationParams()
    _MTRActionsClusterPauseActionWithDurationParams.actionID = n(1)
    _ = _MTRActionsClusterPauseActionWithDurationParams.actionID
    _MTRActionsClusterPauseActionWithDurationParams.duration = n(1)
    _ = _MTRActionsClusterPauseActionWithDurationParams.duration
    _MTRActionsClusterPauseActionWithDurationParams.invokeID = n(1)
    _ = _MTRActionsClusterPauseActionWithDurationParams.invokeID
    _MTRActionsClusterPauseActionWithDurationParams.serverSideProcessingTimeout = n(1)
    _ = _MTRActionsClusterPauseActionWithDurationParams.serverSideProcessingTimeout
    _MTRActionsClusterPauseActionWithDurationParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRActionsClusterPauseActionWithDurationParams.timedInvokeTimeoutMs
    mtrRequire(_MTRActionsClusterPauseActionWithDurationParams.description.contains("MTRActionsClusterPauseActionWithDurationParams"), "MTRActionsClusterPauseActionWithDurationParams desc")
}

func testMTRActionsClusterResumeActionParamsParamsWave11() {
    let _MTRActionsClusterResumeActionParams = MTRActionsClusterResumeActionParams()
    _MTRActionsClusterResumeActionParams.actionID = n(1)
    _ = _MTRActionsClusterResumeActionParams.actionID
    _MTRActionsClusterResumeActionParams.invokeID = n(1)
    _ = _MTRActionsClusterResumeActionParams.invokeID
    _MTRActionsClusterResumeActionParams.serverSideProcessingTimeout = n(1)
    _ = _MTRActionsClusterResumeActionParams.serverSideProcessingTimeout
    _MTRActionsClusterResumeActionParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRActionsClusterResumeActionParams.timedInvokeTimeoutMs
    mtrRequire(_MTRActionsClusterResumeActionParams.description.contains("MTRActionsClusterResumeActionParams"), "MTRActionsClusterResumeActionParams desc")
}

func testMTRActionsClusterStartActionParamsParamsWave11() {
    let _MTRActionsClusterStartActionParams = MTRActionsClusterStartActionParams()
    _MTRActionsClusterStartActionParams.actionID = n(1)
    _ = _MTRActionsClusterStartActionParams.actionID
    _MTRActionsClusterStartActionParams.invokeID = n(1)
    _ = _MTRActionsClusterStartActionParams.invokeID
    _MTRActionsClusterStartActionParams.serverSideProcessingTimeout = n(1)
    _ = _MTRActionsClusterStartActionParams.serverSideProcessingTimeout
    _MTRActionsClusterStartActionParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRActionsClusterStartActionParams.timedInvokeTimeoutMs
    mtrRequire(_MTRActionsClusterStartActionParams.description.contains("MTRActionsClusterStartActionParams"), "MTRActionsClusterStartActionParams desc")
}

func testMTRActionsClusterStartActionWithDurationParamsParamsWave11() {
    let _MTRActionsClusterStartActionWithDurationParams = MTRActionsClusterStartActionWithDurationParams()
    _MTRActionsClusterStartActionWithDurationParams.actionID = n(1)
    _ = _MTRActionsClusterStartActionWithDurationParams.actionID
    _MTRActionsClusterStartActionWithDurationParams.duration = n(1)
    _ = _MTRActionsClusterStartActionWithDurationParams.duration
    _MTRActionsClusterStartActionWithDurationParams.invokeID = n(1)
    _ = _MTRActionsClusterStartActionWithDurationParams.invokeID
    _MTRActionsClusterStartActionWithDurationParams.serverSideProcessingTimeout = n(1)
    _ = _MTRActionsClusterStartActionWithDurationParams.serverSideProcessingTimeout
    _MTRActionsClusterStartActionWithDurationParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRActionsClusterStartActionWithDurationParams.timedInvokeTimeoutMs
    mtrRequire(_MTRActionsClusterStartActionWithDurationParams.description.contains("MTRActionsClusterStartActionWithDurationParams"), "MTRActionsClusterStartActionWithDurationParams desc")
}

func testMTRActionsClusterStateChangedEventParamsWave11() {
    let _MTRActionsClusterStateChangedEvent = MTRActionsClusterStateChangedEvent()
    _MTRActionsClusterStateChangedEvent.actionID = n(1)
    _ = _MTRActionsClusterStateChangedEvent.actionID
    _MTRActionsClusterStateChangedEvent.invokeID = n(1)
    _ = _MTRActionsClusterStateChangedEvent.invokeID
    _MTRActionsClusterStateChangedEvent.newState = n(1)
    _ = _MTRActionsClusterStateChangedEvent.newState
    mtrRequire(_MTRActionsClusterStateChangedEvent.description.contains("MTRActionsClusterStateChangedEvent"), "MTRActionsClusterStateChangedEvent desc")
}

func testMTRActionsClusterStopActionParamsParamsWave11() {
    let _MTRActionsClusterStopActionParams = MTRActionsClusterStopActionParams()
    _MTRActionsClusterStopActionParams.actionID = n(1)
    _ = _MTRActionsClusterStopActionParams.actionID
    _MTRActionsClusterStopActionParams.invokeID = n(1)
    _ = _MTRActionsClusterStopActionParams.invokeID
    _MTRActionsClusterStopActionParams.serverSideProcessingTimeout = n(1)
    _ = _MTRActionsClusterStopActionParams.serverSideProcessingTimeout
    _MTRActionsClusterStopActionParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRActionsClusterStopActionParams.timedInvokeTimeoutMs
    mtrRequire(_MTRActionsClusterStopActionParams.description.contains("MTRActionsClusterStopActionParams"), "MTRActionsClusterStopActionParams desc")
}

func testMTRActivatedCarbonFilterMonitoringClusterReplacementProductStructParamsWave11() {
    let _MTRActivatedCarbonFilterMonitoringClusterReplacementProductStruct = MTRActivatedCarbonFilterMonitoringClusterReplacementProductStruct()
    _MTRActivatedCarbonFilterMonitoringClusterReplacementProductStruct.productIdentifierType = n(1)
    _ = _MTRActivatedCarbonFilterMonitoringClusterReplacementProductStruct.productIdentifierType
    _MTRActivatedCarbonFilterMonitoringClusterReplacementProductStruct.productIdentifierValue = "x"
    _ = _MTRActivatedCarbonFilterMonitoringClusterReplacementProductStruct.productIdentifierValue
    mtrRequire(_MTRActivatedCarbonFilterMonitoringClusterReplacementProductStruct.description.contains("MTRActivatedCarbonFilterMonitoringClusterReplacementProductStruct"), "MTRActivatedCarbonFilterMonitoringClusterReplacementProductStruct desc")
}

func testMTRActivatedCarbonFilterMonitoringClusterResetConditionParamsParamsWave11() {
    let _MTRActivatedCarbonFilterMonitoringClusterResetConditionParams = MTRActivatedCarbonFilterMonitoringClusterResetConditionParams()
    _MTRActivatedCarbonFilterMonitoringClusterResetConditionParams.serverSideProcessingTimeout = n(1)
    _ = _MTRActivatedCarbonFilterMonitoringClusterResetConditionParams.serverSideProcessingTimeout
    _MTRActivatedCarbonFilterMonitoringClusterResetConditionParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRActivatedCarbonFilterMonitoringClusterResetConditionParams.timedInvokeTimeoutMs
    mtrRequire(_MTRActivatedCarbonFilterMonitoringClusterResetConditionParams.description.contains("MTRActivatedCarbonFilterMonitoringClusterResetConditionParams"), "MTRActivatedCarbonFilterMonitoringClusterResetConditionParams desc")
}

func testMTRAdministratorCommissioningClusterOpenBasicCommissioningWindowParamsParamsWave11() {
    let _MTRAdministratorCommissioningClusterOpenBasicCommissioningWindowParams = MTRAdministratorCommissioningClusterOpenBasicCommissioningWindowParams()
    _MTRAdministratorCommissioningClusterOpenBasicCommissioningWindowParams.commissioningTimeout = n(1)
    _ = _MTRAdministratorCommissioningClusterOpenBasicCommissioningWindowParams.commissioningTimeout
    _MTRAdministratorCommissioningClusterOpenBasicCommissioningWindowParams.serverSideProcessingTimeout = n(1)
    _ = _MTRAdministratorCommissioningClusterOpenBasicCommissioningWindowParams.serverSideProcessingTimeout
    _MTRAdministratorCommissioningClusterOpenBasicCommissioningWindowParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRAdministratorCommissioningClusterOpenBasicCommissioningWindowParams.timedInvokeTimeoutMs
    mtrRequire(_MTRAdministratorCommissioningClusterOpenBasicCommissioningWindowParams.description.contains("MTRAdministratorCommissioningClusterOpenBasicCommissioningWindowParams"), "MTRAdministratorCommissioningClusterOpenBasicCommissioningWindowParams desc")
}

func testMTRAdministratorCommissioningClusterOpenCommissioningWindowParamsParamsWave11() {
    let _MTRAdministratorCommissioningClusterOpenCommissioningWindowParams = MTRAdministratorCommissioningClusterOpenCommissioningWindowParams()
    _MTRAdministratorCommissioningClusterOpenCommissioningWindowParams.commissioningTimeout = n(1)
    _ = _MTRAdministratorCommissioningClusterOpenCommissioningWindowParams.commissioningTimeout
    _MTRAdministratorCommissioningClusterOpenCommissioningWindowParams.discriminator = n(1)
    _ = _MTRAdministratorCommissioningClusterOpenCommissioningWindowParams.discriminator
    _MTRAdministratorCommissioningClusterOpenCommissioningWindowParams.iterations = n(1)
    _ = _MTRAdministratorCommissioningClusterOpenCommissioningWindowParams.iterations
    _MTRAdministratorCommissioningClusterOpenCommissioningWindowParams.pakePasscodeVerifier = Data([1])
    _ = _MTRAdministratorCommissioningClusterOpenCommissioningWindowParams.pakePasscodeVerifier
    _MTRAdministratorCommissioningClusterOpenCommissioningWindowParams.pakeVerifier = Data([1])
    _ = _MTRAdministratorCommissioningClusterOpenCommissioningWindowParams.pakeVerifier
    _MTRAdministratorCommissioningClusterOpenCommissioningWindowParams.salt = Data([1])
    _ = _MTRAdministratorCommissioningClusterOpenCommissioningWindowParams.salt
    _MTRAdministratorCommissioningClusterOpenCommissioningWindowParams.serverSideProcessingTimeout = n(1)
    _ = _MTRAdministratorCommissioningClusterOpenCommissioningWindowParams.serverSideProcessingTimeout
    _MTRAdministratorCommissioningClusterOpenCommissioningWindowParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRAdministratorCommissioningClusterOpenCommissioningWindowParams.timedInvokeTimeoutMs
    mtrRequire(_MTRAdministratorCommissioningClusterOpenCommissioningWindowParams.description.contains("MTRAdministratorCommissioningClusterOpenCommissioningWindowParams"), "MTRAdministratorCommissioningClusterOpenCommissioningWindowParams desc")
}

func testMTRAdministratorCommissioningClusterRevokeCommissioningParamsParamsWave11() {
    let _MTRAdministratorCommissioningClusterRevokeCommissioningParams = MTRAdministratorCommissioningClusterRevokeCommissioningParams()
    _MTRAdministratorCommissioningClusterRevokeCommissioningParams.serverSideProcessingTimeout = n(1)
    _ = _MTRAdministratorCommissioningClusterRevokeCommissioningParams.serverSideProcessingTimeout
    _MTRAdministratorCommissioningClusterRevokeCommissioningParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRAdministratorCommissioningClusterRevokeCommissioningParams.timedInvokeTimeoutMs
    mtrRequire(_MTRAdministratorCommissioningClusterRevokeCommissioningParams.description.contains("MTRAdministratorCommissioningClusterRevokeCommissioningParams"), "MTRAdministratorCommissioningClusterRevokeCommissioningParams desc")
}

func testMTRApplicationBasicClusterApplicationStructParamsWave11() {
    let _MTRApplicationBasicClusterApplicationStruct = MTRApplicationBasicClusterApplicationStruct()
    _MTRApplicationBasicClusterApplicationStruct.applicationID = "x"
    _ = _MTRApplicationBasicClusterApplicationStruct.applicationID
    _MTRApplicationBasicClusterApplicationStruct.applicationId = "x"
    _ = _MTRApplicationBasicClusterApplicationStruct.applicationId
    _MTRApplicationBasicClusterApplicationStruct.catalogVendorID = n(1)
    _ = _MTRApplicationBasicClusterApplicationStruct.catalogVendorID
    _MTRApplicationBasicClusterApplicationStruct.catalogVendorId = n(1)
    _ = _MTRApplicationBasicClusterApplicationStruct.catalogVendorId
    mtrRequire(_MTRApplicationBasicClusterApplicationStruct.description.contains("MTRApplicationBasicClusterApplicationStruct"), "MTRApplicationBasicClusterApplicationStruct desc")
}

func testMTRApplicationLauncherClusterApplicationEPParamsWave11() {
    let _MTRApplicationLauncherClusterApplicationEP = MTRApplicationLauncherClusterApplicationEP()
    _MTRApplicationLauncherClusterApplicationEP.application = MTRApplicationLauncherClusterApplicationStruct()
    _ = _MTRApplicationLauncherClusterApplicationEP.application
    _MTRApplicationLauncherClusterApplicationEP.endpoint = n(1)
    _ = _MTRApplicationLauncherClusterApplicationEP.endpoint
    mtrRequire(!_MTRApplicationLauncherClusterApplicationEP.description.isEmpty, "MTRApplicationLauncherClusterApplicationEP desc")
}

func testMTRApplicationLauncherClusterApplicationEPStructParamsWave11() {
    let _MTRApplicationLauncherClusterApplicationEPStruct = MTRApplicationLauncherClusterApplicationEPStruct()
    _MTRApplicationLauncherClusterApplicationEPStruct.application = MTRApplicationLauncherClusterApplicationStruct()
    _ = _MTRApplicationLauncherClusterApplicationEPStruct.application
    _MTRApplicationLauncherClusterApplicationEPStruct.endpoint = n(1)
    _ = _MTRApplicationLauncherClusterApplicationEPStruct.endpoint
    mtrRequire(_MTRApplicationLauncherClusterApplicationEPStruct.description.contains("MTRApplicationLauncherClusterApplicationEPStruct"), "MTRApplicationLauncherClusterApplicationEPStruct desc")
}

func testMTRApplicationLauncherClusterApplicationStructParamsWave11() {
    let _MTRApplicationLauncherClusterApplicationStruct = MTRApplicationLauncherClusterApplicationStruct()
    _MTRApplicationLauncherClusterApplicationStruct.applicationID = "x"
    _ = _MTRApplicationLauncherClusterApplicationStruct.applicationID
    _MTRApplicationLauncherClusterApplicationStruct.applicationId = "x"
    _ = _MTRApplicationLauncherClusterApplicationStruct.applicationId
    _MTRApplicationLauncherClusterApplicationStruct.catalogVendorID = n(1)
    _ = _MTRApplicationLauncherClusterApplicationStruct.catalogVendorID
    _MTRApplicationLauncherClusterApplicationStruct.catalogVendorId = n(1)
    _ = _MTRApplicationLauncherClusterApplicationStruct.catalogVendorId
    mtrRequire(_MTRApplicationLauncherClusterApplicationStruct.description.contains("MTRApplicationLauncherClusterApplicationStruct"), "MTRApplicationLauncherClusterApplicationStruct desc")
}

func testMTRApplicationLauncherClusterHideAppParamsParamsWave11() {
    let _MTRApplicationLauncherClusterHideAppParams = MTRApplicationLauncherClusterHideAppParams()
    _MTRApplicationLauncherClusterHideAppParams.application = MTRApplicationLauncherClusterApplicationStruct()
    _ = _MTRApplicationLauncherClusterHideAppParams.application
    _MTRApplicationLauncherClusterHideAppParams.serverSideProcessingTimeout = n(1)
    _ = _MTRApplicationLauncherClusterHideAppParams.serverSideProcessingTimeout
    _MTRApplicationLauncherClusterHideAppParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRApplicationLauncherClusterHideAppParams.timedInvokeTimeoutMs
    mtrRequire(_MTRApplicationLauncherClusterHideAppParams.description.contains("MTRApplicationLauncherClusterHideAppParams"), "MTRApplicationLauncherClusterHideAppParams desc")
}

func testMTRApplicationLauncherClusterLaunchAppParamsParamsWave11() {
    let _MTRApplicationLauncherClusterLaunchAppParams = MTRApplicationLauncherClusterLaunchAppParams()
    _MTRApplicationLauncherClusterLaunchAppParams.application = MTRApplicationLauncherClusterApplicationStruct()
    _ = _MTRApplicationLauncherClusterLaunchAppParams.application
    _MTRApplicationLauncherClusterLaunchAppParams.data = Data([1])
    _ = _MTRApplicationLauncherClusterLaunchAppParams.data
    _MTRApplicationLauncherClusterLaunchAppParams.serverSideProcessingTimeout = n(1)
    _ = _MTRApplicationLauncherClusterLaunchAppParams.serverSideProcessingTimeout
    _MTRApplicationLauncherClusterLaunchAppParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRApplicationLauncherClusterLaunchAppParams.timedInvokeTimeoutMs
    mtrRequire(_MTRApplicationLauncherClusterLaunchAppParams.description.contains("MTRApplicationLauncherClusterLaunchAppParams"), "MTRApplicationLauncherClusterLaunchAppParams desc")
}

func testMTRApplicationLauncherClusterLauncherResponseParamsParamsWave11() {
    let _MTRApplicationLauncherClusterLauncherResponseParams = (try? MTRApplicationLauncherClusterLauncherResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRApplicationLauncherClusterLauncherResponseParams()
    _MTRApplicationLauncherClusterLauncherResponseParams.data = Data([1])
    _ = _MTRApplicationLauncherClusterLauncherResponseParams.data
    _MTRApplicationLauncherClusterLauncherResponseParams.status = n(1)
    _ = _MTRApplicationLauncherClusterLauncherResponseParams.status
    _MTRApplicationLauncherClusterLauncherResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRApplicationLauncherClusterLauncherResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRApplicationLauncherClusterLauncherResponseParams.description.contains("MTRApplicationLauncherClusterLauncherResponseParams"), "MTRApplicationLauncherClusterLauncherResponseParams desc")
}

func testMTRApplicationLauncherClusterStopAppParamsParamsWave11() {
    let _MTRApplicationLauncherClusterStopAppParams = MTRApplicationLauncherClusterStopAppParams()
    _MTRApplicationLauncherClusterStopAppParams.application = MTRApplicationLauncherClusterApplicationStruct()
    _ = _MTRApplicationLauncherClusterStopAppParams.application
    _MTRApplicationLauncherClusterStopAppParams.serverSideProcessingTimeout = n(1)
    _ = _MTRApplicationLauncherClusterStopAppParams.serverSideProcessingTimeout
    _MTRApplicationLauncherClusterStopAppParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRApplicationLauncherClusterStopAppParams.timedInvokeTimeoutMs
    mtrRequire(_MTRApplicationLauncherClusterStopAppParams.description.contains("MTRApplicationLauncherClusterStopAppParams"), "MTRApplicationLauncherClusterStopAppParams desc")
}

func testMTRAudioOutputClusterOutputInfoParamsWave11() {
    let _MTRAudioOutputClusterOutputInfo = MTRAudioOutputClusterOutputInfo()
    _MTRAudioOutputClusterOutputInfo.index = n(1)
    _ = _MTRAudioOutputClusterOutputInfo.index
    _MTRAudioOutputClusterOutputInfo.name = "x"
    _ = _MTRAudioOutputClusterOutputInfo.name
    _MTRAudioOutputClusterOutputInfo.outputType = n(1)
    _ = _MTRAudioOutputClusterOutputInfo.outputType
    mtrRequire(!_MTRAudioOutputClusterOutputInfo.description.isEmpty, "MTRAudioOutputClusterOutputInfo desc")
}

func testMTRAudioOutputClusterOutputInfoStructParamsWave11() {
    let _MTRAudioOutputClusterOutputInfoStruct = MTRAudioOutputClusterOutputInfoStruct()
    _MTRAudioOutputClusterOutputInfoStruct.index = n(1)
    _ = _MTRAudioOutputClusterOutputInfoStruct.index
    _MTRAudioOutputClusterOutputInfoStruct.name = "x"
    _ = _MTRAudioOutputClusterOutputInfoStruct.name
    _MTRAudioOutputClusterOutputInfoStruct.outputType = n(1)
    _ = _MTRAudioOutputClusterOutputInfoStruct.outputType
    mtrRequire(_MTRAudioOutputClusterOutputInfoStruct.description.contains("MTRAudioOutputClusterOutputInfoStruct"), "MTRAudioOutputClusterOutputInfoStruct desc")
}

func testMTRAudioOutputClusterRenameOutputParamsParamsWave11() {
    let _MTRAudioOutputClusterRenameOutputParams = MTRAudioOutputClusterRenameOutputParams()
    _MTRAudioOutputClusterRenameOutputParams.index = n(1)
    _ = _MTRAudioOutputClusterRenameOutputParams.index
    _MTRAudioOutputClusterRenameOutputParams.name = "x"
    _ = _MTRAudioOutputClusterRenameOutputParams.name
    _MTRAudioOutputClusterRenameOutputParams.serverSideProcessingTimeout = n(1)
    _ = _MTRAudioOutputClusterRenameOutputParams.serverSideProcessingTimeout
    _MTRAudioOutputClusterRenameOutputParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRAudioOutputClusterRenameOutputParams.timedInvokeTimeoutMs
    mtrRequire(_MTRAudioOutputClusterRenameOutputParams.description.contains("MTRAudioOutputClusterRenameOutputParams"), "MTRAudioOutputClusterRenameOutputParams desc")
}

func testMTRAudioOutputClusterSelectOutputParamsParamsWave11() {
    let _MTRAudioOutputClusterSelectOutputParams = MTRAudioOutputClusterSelectOutputParams()
    _MTRAudioOutputClusterSelectOutputParams.index = n(1)
    _ = _MTRAudioOutputClusterSelectOutputParams.index
    _MTRAudioOutputClusterSelectOutputParams.serverSideProcessingTimeout = n(1)
    _ = _MTRAudioOutputClusterSelectOutputParams.serverSideProcessingTimeout
    _MTRAudioOutputClusterSelectOutputParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRAudioOutputClusterSelectOutputParams.timedInvokeTimeoutMs
    mtrRequire(_MTRAudioOutputClusterSelectOutputParams.description.contains("MTRAudioOutputClusterSelectOutputParams"), "MTRAudioOutputClusterSelectOutputParams desc")
}

func testMTRBarrierControlClusterBarrierControlGoToPercentParamsParamsWave11() {
    let _MTRBarrierControlClusterBarrierControlGoToPercentParams = MTRBarrierControlClusterBarrierControlGoToPercentParams()
    _MTRBarrierControlClusterBarrierControlGoToPercentParams.percentOpen = n(1)
    _ = _MTRBarrierControlClusterBarrierControlGoToPercentParams.percentOpen
    _MTRBarrierControlClusterBarrierControlGoToPercentParams.serverSideProcessingTimeout = n(1)
    _ = _MTRBarrierControlClusterBarrierControlGoToPercentParams.serverSideProcessingTimeout
    _MTRBarrierControlClusterBarrierControlGoToPercentParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRBarrierControlClusterBarrierControlGoToPercentParams.timedInvokeTimeoutMs
    mtrRequire(_MTRBarrierControlClusterBarrierControlGoToPercentParams.description.contains("MTRBarrierControlClusterBarrierControlGoToPercentParams"), "MTRBarrierControlClusterBarrierControlGoToPercentParams desc")
}

func testMTRBarrierControlClusterBarrierControlStopParamsParamsWave11() {
    let _MTRBarrierControlClusterBarrierControlStopParams = MTRBarrierControlClusterBarrierControlStopParams()
    _MTRBarrierControlClusterBarrierControlStopParams.serverSideProcessingTimeout = n(1)
    _ = _MTRBarrierControlClusterBarrierControlStopParams.serverSideProcessingTimeout
    _MTRBarrierControlClusterBarrierControlStopParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRBarrierControlClusterBarrierControlStopParams.timedInvokeTimeoutMs
    mtrRequire(_MTRBarrierControlClusterBarrierControlStopParams.description.contains("MTRBarrierControlClusterBarrierControlStopParams"), "MTRBarrierControlClusterBarrierControlStopParams desc")
}

func testMTRBasicClusterCapabilityMinimaStructParamsWave11() {
    let _MTRBasicClusterCapabilityMinimaStruct = MTRBasicClusterCapabilityMinimaStruct()
    _MTRBasicClusterCapabilityMinimaStruct.caseSessionsPerFabric = n(1)
    _ = _MTRBasicClusterCapabilityMinimaStruct.caseSessionsPerFabric
    _MTRBasicClusterCapabilityMinimaStruct.subscriptionsPerFabric = n(1)
    _ = _MTRBasicClusterCapabilityMinimaStruct.subscriptionsPerFabric
    mtrRequire(!_MTRBasicClusterCapabilityMinimaStruct.description.isEmpty, "MTRBasicClusterCapabilityMinimaStruct desc")
}

func testMTRBasicClusterLeaveEventParamsWave11() {
    let _MTRBasicClusterLeaveEvent = MTRBasicClusterLeaveEvent()
    _MTRBasicClusterLeaveEvent.fabricIndex = n(1)
    _ = _MTRBasicClusterLeaveEvent.fabricIndex
    mtrRequire(!_MTRBasicClusterLeaveEvent.description.isEmpty, "MTRBasicClusterLeaveEvent desc")
}

func testMTRBasicClusterMfgSpecificPingParamsParamsWave11() {
    let _MTRBasicClusterMfgSpecificPingParams = MTRBasicClusterMfgSpecificPingParams()
    _MTRBasicClusterMfgSpecificPingParams.serverSideProcessingTimeout = n(1)
    _ = _MTRBasicClusterMfgSpecificPingParams.serverSideProcessingTimeout
    _MTRBasicClusterMfgSpecificPingParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRBasicClusterMfgSpecificPingParams.timedInvokeTimeoutMs
    mtrRequire(_MTRBasicClusterMfgSpecificPingParams.description.contains("MTRBasicClusterMfgSpecificPingParams"), "MTRBasicClusterMfgSpecificPingParams desc")
}

func testMTRBasicClusterReachableChangedEventParamsWave11() {
    let _MTRBasicClusterReachableChangedEvent = MTRBasicClusterReachableChangedEvent()
    _MTRBasicClusterReachableChangedEvent.reachableNewValue = n(1)
    _ = _MTRBasicClusterReachableChangedEvent.reachableNewValue
    mtrRequire(!_MTRBasicClusterReachableChangedEvent.description.isEmpty, "MTRBasicClusterReachableChangedEvent desc")
}

func testMTRBasicClusterStartUpEventParamsWave11() {
    let _MTRBasicClusterStartUpEvent = MTRBasicClusterStartUpEvent()
    _MTRBasicClusterStartUpEvent.softwareVersion = n(1)
    _ = _MTRBasicClusterStartUpEvent.softwareVersion
    mtrRequire(!_MTRBasicClusterStartUpEvent.description.isEmpty, "MTRBasicClusterStartUpEvent desc")
}

func testMTRBasicInformationClusterCapabilityMinimaStructParamsWave11() {
    let _MTRBasicInformationClusterCapabilityMinimaStruct = MTRBasicInformationClusterCapabilityMinimaStruct()
    _MTRBasicInformationClusterCapabilityMinimaStruct.caseSessionsPerFabric = n(1)
    _ = _MTRBasicInformationClusterCapabilityMinimaStruct.caseSessionsPerFabric
    _MTRBasicInformationClusterCapabilityMinimaStruct.subscriptionsPerFabric = n(1)
    _ = _MTRBasicInformationClusterCapabilityMinimaStruct.subscriptionsPerFabric
    mtrRequire(_MTRBasicInformationClusterCapabilityMinimaStruct.description.contains("MTRBasicInformationClusterCapabilityMinimaStruct"), "MTRBasicInformationClusterCapabilityMinimaStruct desc")
}

func testMTRBasicInformationClusterLeaveEventParamsWave11() {
    let _MTRBasicInformationClusterLeaveEvent = MTRBasicInformationClusterLeaveEvent()
    _MTRBasicInformationClusterLeaveEvent.fabricIndex = n(1)
    _ = _MTRBasicInformationClusterLeaveEvent.fabricIndex
    mtrRequire(_MTRBasicInformationClusterLeaveEvent.description.contains("MTRBasicInformationClusterLeaveEvent"), "MTRBasicInformationClusterLeaveEvent desc")
}

func testMTRBasicInformationClusterProductAppearanceStructParamsWave11() {
    let _MTRBasicInformationClusterProductAppearanceStruct = MTRBasicInformationClusterProductAppearanceStruct()
    _MTRBasicInformationClusterProductAppearanceStruct.finish = n(1)
    _ = _MTRBasicInformationClusterProductAppearanceStruct.finish
    _MTRBasicInformationClusterProductAppearanceStruct.primaryColor = n(1)
    _ = _MTRBasicInformationClusterProductAppearanceStruct.primaryColor
    mtrRequire(_MTRBasicInformationClusterProductAppearanceStruct.description.contains("MTRBasicInformationClusterProductAppearanceStruct"), "MTRBasicInformationClusterProductAppearanceStruct desc")
}

func testMTRBasicInformationClusterReachableChangedEventParamsWave11() {
    let _MTRBasicInformationClusterReachableChangedEvent = MTRBasicInformationClusterReachableChangedEvent()
    _MTRBasicInformationClusterReachableChangedEvent.reachableNewValue = n(1)
    _ = _MTRBasicInformationClusterReachableChangedEvent.reachableNewValue
    mtrRequire(_MTRBasicInformationClusterReachableChangedEvent.description.contains("MTRBasicInformationClusterReachableChangedEvent"), "MTRBasicInformationClusterReachableChangedEvent desc")
}

func testMTRBasicInformationClusterStartUpEventParamsWave11() {
    let _MTRBasicInformationClusterStartUpEvent = MTRBasicInformationClusterStartUpEvent()
    _MTRBasicInformationClusterStartUpEvent.softwareVersion = n(1)
    _ = _MTRBasicInformationClusterStartUpEvent.softwareVersion
    mtrRequire(_MTRBasicInformationClusterStartUpEvent.description.contains("MTRBasicInformationClusterStartUpEvent"), "MTRBasicInformationClusterStartUpEvent desc")
}

func testMTRBindingClusterTargetStructParamsWave11() {
    let _MTRBindingClusterTargetStruct = MTRBindingClusterTargetStruct()
    _MTRBindingClusterTargetStruct.cluster = n(1)
    _ = _MTRBindingClusterTargetStruct.cluster
    _MTRBindingClusterTargetStruct.endpoint = n(1)
    _ = _MTRBindingClusterTargetStruct.endpoint
    _MTRBindingClusterTargetStruct.fabricIndex = n(1)
    _ = _MTRBindingClusterTargetStruct.fabricIndex
    _MTRBindingClusterTargetStruct.group = n(1)
    _ = _MTRBindingClusterTargetStruct.group
    _MTRBindingClusterTargetStruct.node = n(1)
    _ = _MTRBindingClusterTargetStruct.node
    mtrRequire(_MTRBindingClusterTargetStruct.description.contains("MTRBindingClusterTargetStruct"), "MTRBindingClusterTargetStruct desc")
}

func testMTRBooleanStateClusterStateChangeEventParamsWave11() {
    let _MTRBooleanStateClusterStateChangeEvent = MTRBooleanStateClusterStateChangeEvent()
    _MTRBooleanStateClusterStateChangeEvent.stateValue = n(1)
    _ = _MTRBooleanStateClusterStateChangeEvent.stateValue
    mtrRequire(_MTRBooleanStateClusterStateChangeEvent.description.contains("MTRBooleanStateClusterStateChangeEvent"), "MTRBooleanStateClusterStateChangeEvent desc")
}

func testMTRBooleanStateConfigurationClusterAlarmsStateChangedEventParamsWave11() {
    let _MTRBooleanStateConfigurationClusterAlarmsStateChangedEvent = MTRBooleanStateConfigurationClusterAlarmsStateChangedEvent()
    _MTRBooleanStateConfigurationClusterAlarmsStateChangedEvent.alarmsActive = n(1)
    _ = _MTRBooleanStateConfigurationClusterAlarmsStateChangedEvent.alarmsActive
    _MTRBooleanStateConfigurationClusterAlarmsStateChangedEvent.alarmsSuppressed = n(1)
    _ = _MTRBooleanStateConfigurationClusterAlarmsStateChangedEvent.alarmsSuppressed
    mtrRequire(_MTRBooleanStateConfigurationClusterAlarmsStateChangedEvent.description.contains("MTRBooleanStateConfigurationClusterAlarmsStateChangedEvent"), "MTRBooleanStateConfigurationClusterAlarmsStateChangedEvent desc")
}

func testMTRBooleanStateConfigurationClusterEnableDisableAlarmParamsParamsWave11() {
    let _MTRBooleanStateConfigurationClusterEnableDisableAlarmParams = MTRBooleanStateConfigurationClusterEnableDisableAlarmParams()
    _MTRBooleanStateConfigurationClusterEnableDisableAlarmParams.alarmsToEnableDisable = n(1)
    _ = _MTRBooleanStateConfigurationClusterEnableDisableAlarmParams.alarmsToEnableDisable
    _MTRBooleanStateConfigurationClusterEnableDisableAlarmParams.serverSideProcessingTimeout = n(1)
    _ = _MTRBooleanStateConfigurationClusterEnableDisableAlarmParams.serverSideProcessingTimeout
    _MTRBooleanStateConfigurationClusterEnableDisableAlarmParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRBooleanStateConfigurationClusterEnableDisableAlarmParams.timedInvokeTimeoutMs
    mtrRequire(_MTRBooleanStateConfigurationClusterEnableDisableAlarmParams.description.contains("MTRBooleanStateConfigurationClusterEnableDisableAlarmParams"), "MTRBooleanStateConfigurationClusterEnableDisableAlarmParams desc")
}

func testMTRBooleanStateConfigurationClusterSensorFaultEventParamsWave11() {
    let _MTRBooleanStateConfigurationClusterSensorFaultEvent = MTRBooleanStateConfigurationClusterSensorFaultEvent()
    _MTRBooleanStateConfigurationClusterSensorFaultEvent.sensorFault = n(1)
    _ = _MTRBooleanStateConfigurationClusterSensorFaultEvent.sensorFault
    mtrRequire(_MTRBooleanStateConfigurationClusterSensorFaultEvent.description.contains("MTRBooleanStateConfigurationClusterSensorFaultEvent"), "MTRBooleanStateConfigurationClusterSensorFaultEvent desc")
}

func testMTRBooleanStateConfigurationClusterSuppressAlarmParamsParamsWave11() {
    let _MTRBooleanStateConfigurationClusterSuppressAlarmParams = MTRBooleanStateConfigurationClusterSuppressAlarmParams()
    _MTRBooleanStateConfigurationClusterSuppressAlarmParams.alarmsToSuppress = n(1)
    _ = _MTRBooleanStateConfigurationClusterSuppressAlarmParams.alarmsToSuppress
    _MTRBooleanStateConfigurationClusterSuppressAlarmParams.serverSideProcessingTimeout = n(1)
    _ = _MTRBooleanStateConfigurationClusterSuppressAlarmParams.serverSideProcessingTimeout
    _MTRBooleanStateConfigurationClusterSuppressAlarmParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRBooleanStateConfigurationClusterSuppressAlarmParams.timedInvokeTimeoutMs
    mtrRequire(_MTRBooleanStateConfigurationClusterSuppressAlarmParams.description.contains("MTRBooleanStateConfigurationClusterSuppressAlarmParams"), "MTRBooleanStateConfigurationClusterSuppressAlarmParams desc")
}

