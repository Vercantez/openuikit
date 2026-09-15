import Foundation
import Dispatch
import Matter

func testMTRKeypadInputClusterSendKeyParamsParamsWave11() {
    let _MTRKeypadInputClusterSendKeyParams = MTRKeypadInputClusterSendKeyParams()
    _MTRKeypadInputClusterSendKeyParams.keyCode = n(1)
    _ = _MTRKeypadInputClusterSendKeyParams.keyCode
    _MTRKeypadInputClusterSendKeyParams.serverSideProcessingTimeout = n(1)
    _ = _MTRKeypadInputClusterSendKeyParams.serverSideProcessingTimeout
    _MTRKeypadInputClusterSendKeyParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRKeypadInputClusterSendKeyParams.timedInvokeTimeoutMs
    mtrRequire(_MTRKeypadInputClusterSendKeyParams.description.contains("MTRKeypadInputClusterSendKeyParams"), "MTRKeypadInputClusterSendKeyParams desc")
}

func testMTRKeypadInputClusterSendKeyResponseParamsParamsWave11() {
    let _MTRKeypadInputClusterSendKeyResponseParams = (try? MTRKeypadInputClusterSendKeyResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRKeypadInputClusterSendKeyResponseParams()
    _MTRKeypadInputClusterSendKeyResponseParams.status = n(1)
    _ = _MTRKeypadInputClusterSendKeyResponseParams.status
    _MTRKeypadInputClusterSendKeyResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRKeypadInputClusterSendKeyResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRKeypadInputClusterSendKeyResponseParams.description.contains("MTRKeypadInputClusterSendKeyResponseParams"), "MTRKeypadInputClusterSendKeyResponseParams desc")
}

func testMTRLaundryWasherModeClusterChangeToModeParamsParamsWave11() {
    let _MTRLaundryWasherModeClusterChangeToModeParams = MTRLaundryWasherModeClusterChangeToModeParams()
    _MTRLaundryWasherModeClusterChangeToModeParams.newMode = n(1)
    _ = _MTRLaundryWasherModeClusterChangeToModeParams.newMode
    _MTRLaundryWasherModeClusterChangeToModeParams.serverSideProcessingTimeout = n(1)
    _ = _MTRLaundryWasherModeClusterChangeToModeParams.serverSideProcessingTimeout
    _MTRLaundryWasherModeClusterChangeToModeParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRLaundryWasherModeClusterChangeToModeParams.timedInvokeTimeoutMs
    mtrRequire(_MTRLaundryWasherModeClusterChangeToModeParams.description.contains("MTRLaundryWasherModeClusterChangeToModeParams"), "MTRLaundryWasherModeClusterChangeToModeParams desc")
}

func testMTRLaundryWasherModeClusterChangeToModeResponseParamsParamsWave11() {
    let _MTRLaundryWasherModeClusterChangeToModeResponseParams = (try? MTRLaundryWasherModeClusterChangeToModeResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRLaundryWasherModeClusterChangeToModeResponseParams()
    _MTRLaundryWasherModeClusterChangeToModeResponseParams.status = n(1)
    _ = _MTRLaundryWasherModeClusterChangeToModeResponseParams.status
    _MTRLaundryWasherModeClusterChangeToModeResponseParams.statusText = "x"
    _ = _MTRLaundryWasherModeClusterChangeToModeResponseParams.statusText
    mtrRequire(_MTRLaundryWasherModeClusterChangeToModeResponseParams.description.contains("MTRLaundryWasherModeClusterChangeToModeResponseParams"), "MTRLaundryWasherModeClusterChangeToModeResponseParams desc")
}

func testMTRLaundryWasherModeClusterModeOptionStructParamsWave11() {
    let _MTRLaundryWasherModeClusterModeOptionStruct = MTRLaundryWasherModeClusterModeOptionStruct()
    _MTRLaundryWasherModeClusterModeOptionStruct.label = "x"
    _ = _MTRLaundryWasherModeClusterModeOptionStruct.label
    _MTRLaundryWasherModeClusterModeOptionStruct.mode = n(1)
    _ = _MTRLaundryWasherModeClusterModeOptionStruct.mode
    _MTRLaundryWasherModeClusterModeOptionStruct.modeTags = [n(1)] as [Any]
    _ = _MTRLaundryWasherModeClusterModeOptionStruct.modeTags
    mtrRequire(_MTRLaundryWasherModeClusterModeOptionStruct.description.contains("MTRLaundryWasherModeClusterModeOptionStruct"), "MTRLaundryWasherModeClusterModeOptionStruct desc")
}

func testMTRLaundryWasherModeClusterModeTagStructParamsWave11() {
    let _MTRLaundryWasherModeClusterModeTagStruct = MTRLaundryWasherModeClusterModeTagStruct()
    _MTRLaundryWasherModeClusterModeTagStruct.mfgCode = n(1)
    _ = _MTRLaundryWasherModeClusterModeTagStruct.mfgCode
    _MTRLaundryWasherModeClusterModeTagStruct.value = n(1)
    _ = _MTRLaundryWasherModeClusterModeTagStruct.value
    mtrRequire(_MTRLaundryWasherModeClusterModeTagStruct.description.contains("MTRLaundryWasherModeClusterModeTagStruct"), "MTRLaundryWasherModeClusterModeTagStruct desc")
}

func testMTRLowPowerClusterSleepParamsParamsWave11() {
    let _MTRLowPowerClusterSleepParams = MTRLowPowerClusterSleepParams()
    _MTRLowPowerClusterSleepParams.serverSideProcessingTimeout = n(1)
    _ = _MTRLowPowerClusterSleepParams.serverSideProcessingTimeout
    _MTRLowPowerClusterSleepParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRLowPowerClusterSleepParams.timedInvokeTimeoutMs
    mtrRequire(_MTRLowPowerClusterSleepParams.description.contains("MTRLowPowerClusterSleepParams"), "MTRLowPowerClusterSleepParams desc")
}

func testMTRMediaInputClusterHideInputStatusParamsParamsWave11() {
    let _MTRMediaInputClusterHideInputStatusParams = MTRMediaInputClusterHideInputStatusParams()
    _MTRMediaInputClusterHideInputStatusParams.serverSideProcessingTimeout = n(1)
    _ = _MTRMediaInputClusterHideInputStatusParams.serverSideProcessingTimeout
    _MTRMediaInputClusterHideInputStatusParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMediaInputClusterHideInputStatusParams.timedInvokeTimeoutMs
    mtrRequire(_MTRMediaInputClusterHideInputStatusParams.description.contains("MTRMediaInputClusterHideInputStatusParams"), "MTRMediaInputClusterHideInputStatusParams desc")
}

func testMTRMediaInputClusterInputInfoParamsWave11() {
    let _MTRMediaInputClusterInputInfo = MTRMediaInputClusterInputInfo()
    _MTRMediaInputClusterInputInfo.descriptionString = "x"
    _ = _MTRMediaInputClusterInputInfo.descriptionString
    _MTRMediaInputClusterInputInfo.index = n(1)
    _ = _MTRMediaInputClusterInputInfo.index
    _MTRMediaInputClusterInputInfo.inputType = n(1)
    _ = _MTRMediaInputClusterInputInfo.inputType
    _MTRMediaInputClusterInputInfo.name = "x"
    _ = _MTRMediaInputClusterInputInfo.name
    mtrRequire(!_MTRMediaInputClusterInputInfo.description.isEmpty, "MTRMediaInputClusterInputInfo desc")
}

func testMTRMediaInputClusterInputInfoStructParamsWave11() {
    let _MTRMediaInputClusterInputInfoStruct = MTRMediaInputClusterInputInfoStruct()
    _MTRMediaInputClusterInputInfoStruct.descriptionString = "x"
    _ = _MTRMediaInputClusterInputInfoStruct.descriptionString
    _MTRMediaInputClusterInputInfoStruct.index = n(1)
    _ = _MTRMediaInputClusterInputInfoStruct.index
    _MTRMediaInputClusterInputInfoStruct.inputType = n(1)
    _ = _MTRMediaInputClusterInputInfoStruct.inputType
    _MTRMediaInputClusterInputInfoStruct.name = "x"
    _ = _MTRMediaInputClusterInputInfoStruct.name
    mtrRequire(_MTRMediaInputClusterInputInfoStruct.description.contains("MTRMediaInputClusterInputInfoStruct"), "MTRMediaInputClusterInputInfoStruct desc")
}

func testMTRMediaInputClusterRenameInputParamsParamsWave11() {
    let _MTRMediaInputClusterRenameInputParams = MTRMediaInputClusterRenameInputParams()
    _MTRMediaInputClusterRenameInputParams.index = n(1)
    _ = _MTRMediaInputClusterRenameInputParams.index
    _MTRMediaInputClusterRenameInputParams.name = "x"
    _ = _MTRMediaInputClusterRenameInputParams.name
    _MTRMediaInputClusterRenameInputParams.serverSideProcessingTimeout = n(1)
    _ = _MTRMediaInputClusterRenameInputParams.serverSideProcessingTimeout
    _MTRMediaInputClusterRenameInputParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMediaInputClusterRenameInputParams.timedInvokeTimeoutMs
    mtrRequire(_MTRMediaInputClusterRenameInputParams.description.contains("MTRMediaInputClusterRenameInputParams"), "MTRMediaInputClusterRenameInputParams desc")
}

func testMTRMediaInputClusterSelectInputParamsParamsWave11() {
    let _MTRMediaInputClusterSelectInputParams = MTRMediaInputClusterSelectInputParams()
    _MTRMediaInputClusterSelectInputParams.index = n(1)
    _ = _MTRMediaInputClusterSelectInputParams.index
    _MTRMediaInputClusterSelectInputParams.serverSideProcessingTimeout = n(1)
    _ = _MTRMediaInputClusterSelectInputParams.serverSideProcessingTimeout
    _MTRMediaInputClusterSelectInputParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMediaInputClusterSelectInputParams.timedInvokeTimeoutMs
    mtrRequire(_MTRMediaInputClusterSelectInputParams.description.contains("MTRMediaInputClusterSelectInputParams"), "MTRMediaInputClusterSelectInputParams desc")
}

func testMTRMediaInputClusterShowInputStatusParamsParamsWave11() {
    let _MTRMediaInputClusterShowInputStatusParams = MTRMediaInputClusterShowInputStatusParams()
    _MTRMediaInputClusterShowInputStatusParams.serverSideProcessingTimeout = n(1)
    _ = _MTRMediaInputClusterShowInputStatusParams.serverSideProcessingTimeout
    _MTRMediaInputClusterShowInputStatusParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMediaInputClusterShowInputStatusParams.timedInvokeTimeoutMs
    mtrRequire(_MTRMediaInputClusterShowInputStatusParams.description.contains("MTRMediaInputClusterShowInputStatusParams"), "MTRMediaInputClusterShowInputStatusParams desc")
}

func testMTRMediaPlaybackClusterActivateAudioTrackParamsParamsWave11() {
    let _MTRMediaPlaybackClusterActivateAudioTrackParams = MTRMediaPlaybackClusterActivateAudioTrackParams()
    _MTRMediaPlaybackClusterActivateAudioTrackParams.audioOutputIndex = n(1)
    _ = _MTRMediaPlaybackClusterActivateAudioTrackParams.audioOutputIndex
    _MTRMediaPlaybackClusterActivateAudioTrackParams.serverSideProcessingTimeout = n(1)
    _ = _MTRMediaPlaybackClusterActivateAudioTrackParams.serverSideProcessingTimeout
    _MTRMediaPlaybackClusterActivateAudioTrackParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMediaPlaybackClusterActivateAudioTrackParams.timedInvokeTimeoutMs
    _MTRMediaPlaybackClusterActivateAudioTrackParams.trackID = "x"
    _ = _MTRMediaPlaybackClusterActivateAudioTrackParams.trackID
    mtrRequire(_MTRMediaPlaybackClusterActivateAudioTrackParams.description.contains("MTRMediaPlaybackClusterActivateAudioTrackParams"), "MTRMediaPlaybackClusterActivateAudioTrackParams desc")
}

func testMTRMediaPlaybackClusterActivateTextTrackParamsParamsWave11() {
    let _MTRMediaPlaybackClusterActivateTextTrackParams = MTRMediaPlaybackClusterActivateTextTrackParams()
    _MTRMediaPlaybackClusterActivateTextTrackParams.serverSideProcessingTimeout = n(1)
    _ = _MTRMediaPlaybackClusterActivateTextTrackParams.serverSideProcessingTimeout
    _MTRMediaPlaybackClusterActivateTextTrackParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMediaPlaybackClusterActivateTextTrackParams.timedInvokeTimeoutMs
    _MTRMediaPlaybackClusterActivateTextTrackParams.trackID = "x"
    _ = _MTRMediaPlaybackClusterActivateTextTrackParams.trackID
    mtrRequire(_MTRMediaPlaybackClusterActivateTextTrackParams.description.contains("MTRMediaPlaybackClusterActivateTextTrackParams"), "MTRMediaPlaybackClusterActivateTextTrackParams desc")
}

func testMTRMediaPlaybackClusterDeactivateTextTrackParamsParamsWave11() {
    let _MTRMediaPlaybackClusterDeactivateTextTrackParams = MTRMediaPlaybackClusterDeactivateTextTrackParams()
    _MTRMediaPlaybackClusterDeactivateTextTrackParams.serverSideProcessingTimeout = n(1)
    _ = _MTRMediaPlaybackClusterDeactivateTextTrackParams.serverSideProcessingTimeout
    _MTRMediaPlaybackClusterDeactivateTextTrackParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMediaPlaybackClusterDeactivateTextTrackParams.timedInvokeTimeoutMs
    mtrRequire(_MTRMediaPlaybackClusterDeactivateTextTrackParams.description.contains("MTRMediaPlaybackClusterDeactivateTextTrackParams"), "MTRMediaPlaybackClusterDeactivateTextTrackParams desc")
}

func testMTRMediaPlaybackClusterFastForwardParamsParamsWave11() {
    let _MTRMediaPlaybackClusterFastForwardParams = MTRMediaPlaybackClusterFastForwardParams()
    _MTRMediaPlaybackClusterFastForwardParams.audioAdvanceUnmuted = n(1)
    _ = _MTRMediaPlaybackClusterFastForwardParams.audioAdvanceUnmuted
    _MTRMediaPlaybackClusterFastForwardParams.serverSideProcessingTimeout = n(1)
    _ = _MTRMediaPlaybackClusterFastForwardParams.serverSideProcessingTimeout
    _MTRMediaPlaybackClusterFastForwardParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMediaPlaybackClusterFastForwardParams.timedInvokeTimeoutMs
    mtrRequire(_MTRMediaPlaybackClusterFastForwardParams.description.contains("MTRMediaPlaybackClusterFastForwardParams"), "MTRMediaPlaybackClusterFastForwardParams desc")
}

func testMTRMediaPlaybackClusterNextParamsParamsWave11() {
    let _MTRMediaPlaybackClusterNextParams = MTRMediaPlaybackClusterNextParams()
    _MTRMediaPlaybackClusterNextParams.serverSideProcessingTimeout = n(1)
    _ = _MTRMediaPlaybackClusterNextParams.serverSideProcessingTimeout
    _MTRMediaPlaybackClusterNextParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMediaPlaybackClusterNextParams.timedInvokeTimeoutMs
    mtrRequire(_MTRMediaPlaybackClusterNextParams.description.contains("MTRMediaPlaybackClusterNextParams"), "MTRMediaPlaybackClusterNextParams desc")
}

func testMTRMediaPlaybackClusterPauseParamsParamsWave11() {
    let _MTRMediaPlaybackClusterPauseParams = MTRMediaPlaybackClusterPauseParams()
    _MTRMediaPlaybackClusterPauseParams.serverSideProcessingTimeout = n(1)
    _ = _MTRMediaPlaybackClusterPauseParams.serverSideProcessingTimeout
    _MTRMediaPlaybackClusterPauseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMediaPlaybackClusterPauseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRMediaPlaybackClusterPauseParams.description.contains("MTRMediaPlaybackClusterPauseParams"), "MTRMediaPlaybackClusterPauseParams desc")
}

func testMTRMediaPlaybackClusterPlayParamsParamsWave11() {
    let _MTRMediaPlaybackClusterPlayParams = MTRMediaPlaybackClusterPlayParams()
    _MTRMediaPlaybackClusterPlayParams.serverSideProcessingTimeout = n(1)
    _ = _MTRMediaPlaybackClusterPlayParams.serverSideProcessingTimeout
    _MTRMediaPlaybackClusterPlayParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMediaPlaybackClusterPlayParams.timedInvokeTimeoutMs
    mtrRequire(_MTRMediaPlaybackClusterPlayParams.description.contains("MTRMediaPlaybackClusterPlayParams"), "MTRMediaPlaybackClusterPlayParams desc")
}

func testMTRMediaPlaybackClusterPlaybackPositionParamsWave11() {
    let _MTRMediaPlaybackClusterPlaybackPosition = MTRMediaPlaybackClusterPlaybackPosition()
    _MTRMediaPlaybackClusterPlaybackPosition.position = n(1)
    _ = _MTRMediaPlaybackClusterPlaybackPosition.position
    _MTRMediaPlaybackClusterPlaybackPosition.updatedAt = n(1)
    _ = _MTRMediaPlaybackClusterPlaybackPosition.updatedAt
    mtrRequire(!_MTRMediaPlaybackClusterPlaybackPosition.description.isEmpty, "MTRMediaPlaybackClusterPlaybackPosition desc")
}

func testMTRMediaPlaybackClusterPlaybackPositionStructParamsWave11() {
    let _MTRMediaPlaybackClusterPlaybackPositionStruct = MTRMediaPlaybackClusterPlaybackPositionStruct()
    _MTRMediaPlaybackClusterPlaybackPositionStruct.position = n(1)
    _ = _MTRMediaPlaybackClusterPlaybackPositionStruct.position
    _MTRMediaPlaybackClusterPlaybackPositionStruct.updatedAt = n(1)
    _ = _MTRMediaPlaybackClusterPlaybackPositionStruct.updatedAt
    mtrRequire(_MTRMediaPlaybackClusterPlaybackPositionStruct.description.contains("MTRMediaPlaybackClusterPlaybackPositionStruct"), "MTRMediaPlaybackClusterPlaybackPositionStruct desc")
}

func testMTRMediaPlaybackClusterPlaybackResponseParamsParamsWave11() {
    let _MTRMediaPlaybackClusterPlaybackResponseParams = (try? MTRMediaPlaybackClusterPlaybackResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRMediaPlaybackClusterPlaybackResponseParams()
    _MTRMediaPlaybackClusterPlaybackResponseParams.data = "x"
    _ = _MTRMediaPlaybackClusterPlaybackResponseParams.data
    _MTRMediaPlaybackClusterPlaybackResponseParams.status = n(1)
    _ = _MTRMediaPlaybackClusterPlaybackResponseParams.status
    _MTRMediaPlaybackClusterPlaybackResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMediaPlaybackClusterPlaybackResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRMediaPlaybackClusterPlaybackResponseParams.description.contains("MTRMediaPlaybackClusterPlaybackResponseParams"), "MTRMediaPlaybackClusterPlaybackResponseParams desc")
}

func testMTRMediaPlaybackClusterPreviousParamsParamsWave11() {
    let _MTRMediaPlaybackClusterPreviousParams = MTRMediaPlaybackClusterPreviousParams()
    _MTRMediaPlaybackClusterPreviousParams.serverSideProcessingTimeout = n(1)
    _ = _MTRMediaPlaybackClusterPreviousParams.serverSideProcessingTimeout
    _MTRMediaPlaybackClusterPreviousParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMediaPlaybackClusterPreviousParams.timedInvokeTimeoutMs
    mtrRequire(_MTRMediaPlaybackClusterPreviousParams.description.contains("MTRMediaPlaybackClusterPreviousParams"), "MTRMediaPlaybackClusterPreviousParams desc")
}

func testMTRMediaPlaybackClusterRewindParamsParamsWave11() {
    let _MTRMediaPlaybackClusterRewindParams = MTRMediaPlaybackClusterRewindParams()
    _MTRMediaPlaybackClusterRewindParams.audioAdvanceUnmuted = n(1)
    _ = _MTRMediaPlaybackClusterRewindParams.audioAdvanceUnmuted
    _MTRMediaPlaybackClusterRewindParams.serverSideProcessingTimeout = n(1)
    _ = _MTRMediaPlaybackClusterRewindParams.serverSideProcessingTimeout
    _MTRMediaPlaybackClusterRewindParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMediaPlaybackClusterRewindParams.timedInvokeTimeoutMs
    mtrRequire(_MTRMediaPlaybackClusterRewindParams.description.contains("MTRMediaPlaybackClusterRewindParams"), "MTRMediaPlaybackClusterRewindParams desc")
}

func testMTRMediaPlaybackClusterSeekParamsParamsWave11() {
    let _MTRMediaPlaybackClusterSeekParams = MTRMediaPlaybackClusterSeekParams()
    _MTRMediaPlaybackClusterSeekParams.position = n(1)
    _ = _MTRMediaPlaybackClusterSeekParams.position
    _MTRMediaPlaybackClusterSeekParams.serverSideProcessingTimeout = n(1)
    _ = _MTRMediaPlaybackClusterSeekParams.serverSideProcessingTimeout
    _MTRMediaPlaybackClusterSeekParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMediaPlaybackClusterSeekParams.timedInvokeTimeoutMs
    mtrRequire(_MTRMediaPlaybackClusterSeekParams.description.contains("MTRMediaPlaybackClusterSeekParams"), "MTRMediaPlaybackClusterSeekParams desc")
}

func testMTRMediaPlaybackClusterSkipBackwardParamsParamsWave11() {
    let _MTRMediaPlaybackClusterSkipBackwardParams = MTRMediaPlaybackClusterSkipBackwardParams()
    _MTRMediaPlaybackClusterSkipBackwardParams.deltaPositionMilliseconds = n(1)
    _ = _MTRMediaPlaybackClusterSkipBackwardParams.deltaPositionMilliseconds
    _MTRMediaPlaybackClusterSkipBackwardParams.serverSideProcessingTimeout = n(1)
    _ = _MTRMediaPlaybackClusterSkipBackwardParams.serverSideProcessingTimeout
    _MTRMediaPlaybackClusterSkipBackwardParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMediaPlaybackClusterSkipBackwardParams.timedInvokeTimeoutMs
    mtrRequire(_MTRMediaPlaybackClusterSkipBackwardParams.description.contains("MTRMediaPlaybackClusterSkipBackwardParams"), "MTRMediaPlaybackClusterSkipBackwardParams desc")
}

func testMTRMediaPlaybackClusterSkipForwardParamsParamsWave11() {
    let _MTRMediaPlaybackClusterSkipForwardParams = MTRMediaPlaybackClusterSkipForwardParams()
    _MTRMediaPlaybackClusterSkipForwardParams.deltaPositionMilliseconds = n(1)
    _ = _MTRMediaPlaybackClusterSkipForwardParams.deltaPositionMilliseconds
    _MTRMediaPlaybackClusterSkipForwardParams.serverSideProcessingTimeout = n(1)
    _ = _MTRMediaPlaybackClusterSkipForwardParams.serverSideProcessingTimeout
    _MTRMediaPlaybackClusterSkipForwardParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMediaPlaybackClusterSkipForwardParams.timedInvokeTimeoutMs
    mtrRequire(_MTRMediaPlaybackClusterSkipForwardParams.description.contains("MTRMediaPlaybackClusterSkipForwardParams"), "MTRMediaPlaybackClusterSkipForwardParams desc")
}

func testMTRMediaPlaybackClusterStartOverParamsParamsWave11() {
    let _MTRMediaPlaybackClusterStartOverParams = MTRMediaPlaybackClusterStartOverParams()
    _MTRMediaPlaybackClusterStartOverParams.serverSideProcessingTimeout = n(1)
    _ = _MTRMediaPlaybackClusterStartOverParams.serverSideProcessingTimeout
    _MTRMediaPlaybackClusterStartOverParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMediaPlaybackClusterStartOverParams.timedInvokeTimeoutMs
    mtrRequire(_MTRMediaPlaybackClusterStartOverParams.description.contains("MTRMediaPlaybackClusterStartOverParams"), "MTRMediaPlaybackClusterStartOverParams desc")
}

func testMTRMediaPlaybackClusterStateChangedEventParamsWave11() {
    let _MTRMediaPlaybackClusterStateChangedEvent = MTRMediaPlaybackClusterStateChangedEvent()
    _MTRMediaPlaybackClusterStateChangedEvent.audioAdvanceUnmuted = n(1)
    _ = _MTRMediaPlaybackClusterStateChangedEvent.audioAdvanceUnmuted
    _MTRMediaPlaybackClusterStateChangedEvent.currentState = n(1)
    _ = _MTRMediaPlaybackClusterStateChangedEvent.currentState
    _MTRMediaPlaybackClusterStateChangedEvent.data = Data([1])
    _ = _MTRMediaPlaybackClusterStateChangedEvent.data
    _MTRMediaPlaybackClusterStateChangedEvent.duration = n(1)
    _ = _MTRMediaPlaybackClusterStateChangedEvent.duration
    _MTRMediaPlaybackClusterStateChangedEvent.playbackSpeed = n(1)
    _ = _MTRMediaPlaybackClusterStateChangedEvent.playbackSpeed
    _MTRMediaPlaybackClusterStateChangedEvent.sampledPosition = MTRMediaPlaybackClusterPlaybackPositionStruct()
    _ = _MTRMediaPlaybackClusterStateChangedEvent.sampledPosition
    _MTRMediaPlaybackClusterStateChangedEvent.seekRangeEnd = n(1)
    _ = _MTRMediaPlaybackClusterStateChangedEvent.seekRangeEnd
    _MTRMediaPlaybackClusterStateChangedEvent.seekRangeStart = n(1)
    _ = _MTRMediaPlaybackClusterStateChangedEvent.seekRangeStart
    _MTRMediaPlaybackClusterStateChangedEvent.startTime = n(1)
    _ = _MTRMediaPlaybackClusterStateChangedEvent.startTime
    mtrRequire(_MTRMediaPlaybackClusterStateChangedEvent.description.contains("MTRMediaPlaybackClusterStateChangedEvent"), "MTRMediaPlaybackClusterStateChangedEvent desc")
}

func testMTRMediaPlaybackClusterStopParamsParamsWave11() {
    let _MTRMediaPlaybackClusterStopParams = MTRMediaPlaybackClusterStopParams()
    _MTRMediaPlaybackClusterStopParams.serverSideProcessingTimeout = n(1)
    _ = _MTRMediaPlaybackClusterStopParams.serverSideProcessingTimeout
    _MTRMediaPlaybackClusterStopParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMediaPlaybackClusterStopParams.timedInvokeTimeoutMs
    mtrRequire(_MTRMediaPlaybackClusterStopParams.description.contains("MTRMediaPlaybackClusterStopParams"), "MTRMediaPlaybackClusterStopParams desc")
}

func testMTRMediaPlaybackClusterStopPlaybackParamsParamsWave11() {
    let _MTRMediaPlaybackClusterStopPlaybackParams = MTRMediaPlaybackClusterStopPlaybackParams()
    _MTRMediaPlaybackClusterStopPlaybackParams.serverSideProcessingTimeout = n(1)
    _ = _MTRMediaPlaybackClusterStopPlaybackParams.serverSideProcessingTimeout
    _MTRMediaPlaybackClusterStopPlaybackParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMediaPlaybackClusterStopPlaybackParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRMediaPlaybackClusterStopPlaybackParams.description.isEmpty, "MTRMediaPlaybackClusterStopPlaybackParams desc")
}

func testMTRMessagesClusterCancelMessagesRequestParamsParamsWave11() {
    let _MTRMessagesClusterCancelMessagesRequestParams = MTRMessagesClusterCancelMessagesRequestParams()
    _MTRMessagesClusterCancelMessagesRequestParams.messageIDs = [n(1)] as [Any]
    _ = _MTRMessagesClusterCancelMessagesRequestParams.messageIDs
    _MTRMessagesClusterCancelMessagesRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRMessagesClusterCancelMessagesRequestParams.serverSideProcessingTimeout
    _MTRMessagesClusterCancelMessagesRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMessagesClusterCancelMessagesRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRMessagesClusterCancelMessagesRequestParams.description.contains("MTRMessagesClusterCancelMessagesRequestParams"), "MTRMessagesClusterCancelMessagesRequestParams desc")
}

func testMTRMessagesClusterMessageCompleteEventParamsWave11() {
    let _MTRMessagesClusterMessageCompleteEvent = MTRMessagesClusterMessageCompleteEvent()
    _MTRMessagesClusterMessageCompleteEvent.futureMessagesPreference = n(1)
    _ = _MTRMessagesClusterMessageCompleteEvent.futureMessagesPreference
    _MTRMessagesClusterMessageCompleteEvent.messageID = Data([1])
    _ = _MTRMessagesClusterMessageCompleteEvent.messageID
    _MTRMessagesClusterMessageCompleteEvent.reply = "x"
    _ = _MTRMessagesClusterMessageCompleteEvent.reply
    _MTRMessagesClusterMessageCompleteEvent.responseID = n(1)
    _ = _MTRMessagesClusterMessageCompleteEvent.responseID
    mtrRequire(_MTRMessagesClusterMessageCompleteEvent.description.contains("MTRMessagesClusterMessageCompleteEvent"), "MTRMessagesClusterMessageCompleteEvent desc")
}

func testMTRMessagesClusterMessagePresentedEventParamsWave11() {
    let _MTRMessagesClusterMessagePresentedEvent = MTRMessagesClusterMessagePresentedEvent()
    _MTRMessagesClusterMessagePresentedEvent.messageID = Data([1])
    _ = _MTRMessagesClusterMessagePresentedEvent.messageID
    mtrRequire(_MTRMessagesClusterMessagePresentedEvent.description.contains("MTRMessagesClusterMessagePresentedEvent"), "MTRMessagesClusterMessagePresentedEvent desc")
}

func testMTRMessagesClusterMessageQueuedEventParamsWave11() {
    let _MTRMessagesClusterMessageQueuedEvent = MTRMessagesClusterMessageQueuedEvent()
    _MTRMessagesClusterMessageQueuedEvent.messageID = Data([1])
    _ = _MTRMessagesClusterMessageQueuedEvent.messageID
    mtrRequire(_MTRMessagesClusterMessageQueuedEvent.description.contains("MTRMessagesClusterMessageQueuedEvent"), "MTRMessagesClusterMessageQueuedEvent desc")
}

func testMTRMessagesClusterMessageResponseOptionStructParamsWave11() {
    let _MTRMessagesClusterMessageResponseOptionStruct = MTRMessagesClusterMessageResponseOptionStruct()
    _MTRMessagesClusterMessageResponseOptionStruct.label = "x"
    _ = _MTRMessagesClusterMessageResponseOptionStruct.label
    _MTRMessagesClusterMessageResponseOptionStruct.messageResponseID = n(1)
    _ = _MTRMessagesClusterMessageResponseOptionStruct.messageResponseID
    mtrRequire(_MTRMessagesClusterMessageResponseOptionStruct.description.contains("MTRMessagesClusterMessageResponseOptionStruct"), "MTRMessagesClusterMessageResponseOptionStruct desc")
}

func testMTRMessagesClusterMessageStructParamsWave11() {
    let _MTRMessagesClusterMessageStruct = MTRMessagesClusterMessageStruct()
    _MTRMessagesClusterMessageStruct.duration = n(1)
    _ = _MTRMessagesClusterMessageStruct.duration
    _MTRMessagesClusterMessageStruct.messageControl = n(1)
    _ = _MTRMessagesClusterMessageStruct.messageControl
    _MTRMessagesClusterMessageStruct.messageID = Data([1])
    _ = _MTRMessagesClusterMessageStruct.messageID
    _MTRMessagesClusterMessageStruct.messageText = "x"
    _ = _MTRMessagesClusterMessageStruct.messageText
    _MTRMessagesClusterMessageStruct.priority = n(1)
    _ = _MTRMessagesClusterMessageStruct.priority
    _MTRMessagesClusterMessageStruct.responses = [n(1)] as [Any]
    _ = _MTRMessagesClusterMessageStruct.responses
    _MTRMessagesClusterMessageStruct.startTime = n(1)
    _ = _MTRMessagesClusterMessageStruct.startTime
    mtrRequire(_MTRMessagesClusterMessageStruct.description.contains("MTRMessagesClusterMessageStruct"), "MTRMessagesClusterMessageStruct desc")
}

func testMTRMessagesClusterPresentMessagesRequestParamsParamsWave11() {
    let _MTRMessagesClusterPresentMessagesRequestParams = MTRMessagesClusterPresentMessagesRequestParams()
    _MTRMessagesClusterPresentMessagesRequestParams.duration = n(1)
    _ = _MTRMessagesClusterPresentMessagesRequestParams.duration
    _MTRMessagesClusterPresentMessagesRequestParams.messageControl = n(1)
    _ = _MTRMessagesClusterPresentMessagesRequestParams.messageControl
    _MTRMessagesClusterPresentMessagesRequestParams.messageID = Data([1])
    _ = _MTRMessagesClusterPresentMessagesRequestParams.messageID
    _MTRMessagesClusterPresentMessagesRequestParams.messageText = "x"
    _ = _MTRMessagesClusterPresentMessagesRequestParams.messageText
    _MTRMessagesClusterPresentMessagesRequestParams.priority = n(1)
    _ = _MTRMessagesClusterPresentMessagesRequestParams.priority
    _MTRMessagesClusterPresentMessagesRequestParams.responses = [n(1)] as [Any]
    _ = _MTRMessagesClusterPresentMessagesRequestParams.responses
    _MTRMessagesClusterPresentMessagesRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRMessagesClusterPresentMessagesRequestParams.serverSideProcessingTimeout
    _MTRMessagesClusterPresentMessagesRequestParams.startTime = n(1)
    _ = _MTRMessagesClusterPresentMessagesRequestParams.startTime
    _MTRMessagesClusterPresentMessagesRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMessagesClusterPresentMessagesRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRMessagesClusterPresentMessagesRequestParams.description.contains("MTRMessagesClusterPresentMessagesRequestParams"), "MTRMessagesClusterPresentMessagesRequestParams desc")
}

func testMTRMicrowaveOvenControlClusterAddMoreTimeParamsParamsWave11() {
    let _MTRMicrowaveOvenControlClusterAddMoreTimeParams = MTRMicrowaveOvenControlClusterAddMoreTimeParams()
    _MTRMicrowaveOvenControlClusterAddMoreTimeParams.serverSideProcessingTimeout = n(1)
    _ = _MTRMicrowaveOvenControlClusterAddMoreTimeParams.serverSideProcessingTimeout
    _MTRMicrowaveOvenControlClusterAddMoreTimeParams.timeToAdd = n(1)
    _ = _MTRMicrowaveOvenControlClusterAddMoreTimeParams.timeToAdd
    _MTRMicrowaveOvenControlClusterAddMoreTimeParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMicrowaveOvenControlClusterAddMoreTimeParams.timedInvokeTimeoutMs
    mtrRequire(_MTRMicrowaveOvenControlClusterAddMoreTimeParams.description.contains("MTRMicrowaveOvenControlClusterAddMoreTimeParams"), "MTRMicrowaveOvenControlClusterAddMoreTimeParams desc")
}

func testMTRMicrowaveOvenControlClusterSetCookingParametersParamsParamsWave11() {
    let _MTRMicrowaveOvenControlClusterSetCookingParametersParams = MTRMicrowaveOvenControlClusterSetCookingParametersParams()
    _MTRMicrowaveOvenControlClusterSetCookingParametersParams.cookMode = n(1)
    _ = _MTRMicrowaveOvenControlClusterSetCookingParametersParams.cookMode
    _MTRMicrowaveOvenControlClusterSetCookingParametersParams.cookTime = n(1)
    _ = _MTRMicrowaveOvenControlClusterSetCookingParametersParams.cookTime
    _MTRMicrowaveOvenControlClusterSetCookingParametersParams.powerSetting = n(1)
    _ = _MTRMicrowaveOvenControlClusterSetCookingParametersParams.powerSetting
    _MTRMicrowaveOvenControlClusterSetCookingParametersParams.serverSideProcessingTimeout = n(1)
    _ = _MTRMicrowaveOvenControlClusterSetCookingParametersParams.serverSideProcessingTimeout
    _MTRMicrowaveOvenControlClusterSetCookingParametersParams.startAfterSetting = n(1)
    _ = _MTRMicrowaveOvenControlClusterSetCookingParametersParams.startAfterSetting
    _MTRMicrowaveOvenControlClusterSetCookingParametersParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRMicrowaveOvenControlClusterSetCookingParametersParams.timedInvokeTimeoutMs
    mtrRequire(_MTRMicrowaveOvenControlClusterSetCookingParametersParams.description.contains("MTRMicrowaveOvenControlClusterSetCookingParametersParams"), "MTRMicrowaveOvenControlClusterSetCookingParametersParams desc")
}

func testMTRMicrowaveOvenModeClusterModeOptionStructParamsWave11() {
    let _MTRMicrowaveOvenModeClusterModeOptionStruct = MTRMicrowaveOvenModeClusterModeOptionStruct()
    _MTRMicrowaveOvenModeClusterModeOptionStruct.label = "x"
    _ = _MTRMicrowaveOvenModeClusterModeOptionStruct.label
    _MTRMicrowaveOvenModeClusterModeOptionStruct.mode = n(1)
    _ = _MTRMicrowaveOvenModeClusterModeOptionStruct.mode
    _MTRMicrowaveOvenModeClusterModeOptionStruct.modeTags = [n(1)] as [Any]
    _ = _MTRMicrowaveOvenModeClusterModeOptionStruct.modeTags
    mtrRequire(_MTRMicrowaveOvenModeClusterModeOptionStruct.description.contains("MTRMicrowaveOvenModeClusterModeOptionStruct"), "MTRMicrowaveOvenModeClusterModeOptionStruct desc")
}

func testMTRMicrowaveOvenModeClusterModeTagStructParamsWave11() {
    let _MTRMicrowaveOvenModeClusterModeTagStruct = MTRMicrowaveOvenModeClusterModeTagStruct()
    _MTRMicrowaveOvenModeClusterModeTagStruct.mfgCode = n(1)
    _ = _MTRMicrowaveOvenModeClusterModeTagStruct.mfgCode
    _MTRMicrowaveOvenModeClusterModeTagStruct.value = n(1)
    _ = _MTRMicrowaveOvenModeClusterModeTagStruct.value
    mtrRequire(_MTRMicrowaveOvenModeClusterModeTagStruct.description.contains("MTRMicrowaveOvenModeClusterModeTagStruct"), "MTRMicrowaveOvenModeClusterModeTagStruct desc")
}

func testMTRModeSelectClusterChangeToModeParamsParamsWave11() {
    let _MTRModeSelectClusterChangeToModeParams = MTRModeSelectClusterChangeToModeParams()
    _MTRModeSelectClusterChangeToModeParams.newMode = n(1)
    _ = _MTRModeSelectClusterChangeToModeParams.newMode
    _MTRModeSelectClusterChangeToModeParams.serverSideProcessingTimeout = n(1)
    _ = _MTRModeSelectClusterChangeToModeParams.serverSideProcessingTimeout
    _MTRModeSelectClusterChangeToModeParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRModeSelectClusterChangeToModeParams.timedInvokeTimeoutMs
    mtrRequire(_MTRModeSelectClusterChangeToModeParams.description.contains("MTRModeSelectClusterChangeToModeParams"), "MTRModeSelectClusterChangeToModeParams desc")
}

func testMTRModeSelectClusterModeOptionStructParamsWave11() {
    let _MTRModeSelectClusterModeOptionStruct = MTRModeSelectClusterModeOptionStruct()
    _MTRModeSelectClusterModeOptionStruct.label = "x"
    _ = _MTRModeSelectClusterModeOptionStruct.label
    _MTRModeSelectClusterModeOptionStruct.mode = n(1)
    _ = _MTRModeSelectClusterModeOptionStruct.mode
    _MTRModeSelectClusterModeOptionStruct.semanticTags = [n(1)] as [Any]
    _ = _MTRModeSelectClusterModeOptionStruct.semanticTags
    mtrRequire(_MTRModeSelectClusterModeOptionStruct.description.contains("MTRModeSelectClusterModeOptionStruct"), "MTRModeSelectClusterModeOptionStruct desc")
}

func testMTRModeSelectClusterSemanticTagParamsWave11() {
    let _MTRModeSelectClusterSemanticTag = MTRModeSelectClusterSemanticTag()
    _MTRModeSelectClusterSemanticTag.mfgCode = n(1)
    _ = _MTRModeSelectClusterSemanticTag.mfgCode
    _MTRModeSelectClusterSemanticTag.value = n(1)
    _ = _MTRModeSelectClusterSemanticTag.value
    mtrRequire(!_MTRModeSelectClusterSemanticTag.description.isEmpty, "MTRModeSelectClusterSemanticTag desc")
}

func testMTRModeSelectClusterSemanticTagStructParamsWave11() {
    let _MTRModeSelectClusterSemanticTagStruct = MTRModeSelectClusterSemanticTagStruct()
    _MTRModeSelectClusterSemanticTagStruct.mfgCode = n(1)
    _ = _MTRModeSelectClusterSemanticTagStruct.mfgCode
    _MTRModeSelectClusterSemanticTagStruct.value = n(1)
    _ = _MTRModeSelectClusterSemanticTagStruct.value
    mtrRequire(_MTRModeSelectClusterSemanticTagStruct.description.contains("MTRModeSelectClusterSemanticTagStruct"), "MTRModeSelectClusterSemanticTagStruct desc")
}

func testMTRNetworkCommissioningClusterAddOrUpdateThreadNetworkParamsParamsWave11() {
    let _MTRNetworkCommissioningClusterAddOrUpdateThreadNetworkParams = MTRNetworkCommissioningClusterAddOrUpdateThreadNetworkParams()
    _MTRNetworkCommissioningClusterAddOrUpdateThreadNetworkParams.breadcrumb = n(1)
    _ = _MTRNetworkCommissioningClusterAddOrUpdateThreadNetworkParams.breadcrumb
    _MTRNetworkCommissioningClusterAddOrUpdateThreadNetworkParams.operationalDataset = Data([1])
    _ = _MTRNetworkCommissioningClusterAddOrUpdateThreadNetworkParams.operationalDataset
    _MTRNetworkCommissioningClusterAddOrUpdateThreadNetworkParams.serverSideProcessingTimeout = n(1)
    _ = _MTRNetworkCommissioningClusterAddOrUpdateThreadNetworkParams.serverSideProcessingTimeout
    _MTRNetworkCommissioningClusterAddOrUpdateThreadNetworkParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRNetworkCommissioningClusterAddOrUpdateThreadNetworkParams.timedInvokeTimeoutMs
    mtrRequire(_MTRNetworkCommissioningClusterAddOrUpdateThreadNetworkParams.description.contains("MTRNetworkCommissioningClusterAddOrUpdateThreadNetworkParams"), "MTRNetworkCommissioningClusterAddOrUpdateThreadNetworkParams desc")
}

func testMTRNetworkCommissioningClusterAddOrUpdateWiFiNetworkParamsParamsWave11() {
    let _MTRNetworkCommissioningClusterAddOrUpdateWiFiNetworkParams = MTRNetworkCommissioningClusterAddOrUpdateWiFiNetworkParams()
    _MTRNetworkCommissioningClusterAddOrUpdateWiFiNetworkParams.breadcrumb = n(1)
    _ = _MTRNetworkCommissioningClusterAddOrUpdateWiFiNetworkParams.breadcrumb
    _MTRNetworkCommissioningClusterAddOrUpdateWiFiNetworkParams.credentials = Data([1])
    _ = _MTRNetworkCommissioningClusterAddOrUpdateWiFiNetworkParams.credentials
    _MTRNetworkCommissioningClusterAddOrUpdateWiFiNetworkParams.serverSideProcessingTimeout = n(1)
    _ = _MTRNetworkCommissioningClusterAddOrUpdateWiFiNetworkParams.serverSideProcessingTimeout
    _MTRNetworkCommissioningClusterAddOrUpdateWiFiNetworkParams.ssid = Data([1])
    _ = _MTRNetworkCommissioningClusterAddOrUpdateWiFiNetworkParams.ssid
    _MTRNetworkCommissioningClusterAddOrUpdateWiFiNetworkParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRNetworkCommissioningClusterAddOrUpdateWiFiNetworkParams.timedInvokeTimeoutMs
    mtrRequire(_MTRNetworkCommissioningClusterAddOrUpdateWiFiNetworkParams.description.contains("MTRNetworkCommissioningClusterAddOrUpdateWiFiNetworkParams"), "MTRNetworkCommissioningClusterAddOrUpdateWiFiNetworkParams desc")
}

func testMTRNetworkCommissioningClusterConnectNetworkParamsParamsWave11() {
    let _MTRNetworkCommissioningClusterConnectNetworkParams = MTRNetworkCommissioningClusterConnectNetworkParams()
    _MTRNetworkCommissioningClusterConnectNetworkParams.breadcrumb = n(1)
    _ = _MTRNetworkCommissioningClusterConnectNetworkParams.breadcrumb
    _MTRNetworkCommissioningClusterConnectNetworkParams.networkID = Data([1])
    _ = _MTRNetworkCommissioningClusterConnectNetworkParams.networkID
    _MTRNetworkCommissioningClusterConnectNetworkParams.serverSideProcessingTimeout = n(1)
    _ = _MTRNetworkCommissioningClusterConnectNetworkParams.serverSideProcessingTimeout
    _MTRNetworkCommissioningClusterConnectNetworkParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRNetworkCommissioningClusterConnectNetworkParams.timedInvokeTimeoutMs
    mtrRequire(_MTRNetworkCommissioningClusterConnectNetworkParams.description.contains("MTRNetworkCommissioningClusterConnectNetworkParams"), "MTRNetworkCommissioningClusterConnectNetworkParams desc")
}

func testMTRNetworkCommissioningClusterConnectNetworkResponseParamsParamsWave11() {
    let _MTRNetworkCommissioningClusterConnectNetworkResponseParams = (try? MTRNetworkCommissioningClusterConnectNetworkResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRNetworkCommissioningClusterConnectNetworkResponseParams()
    _MTRNetworkCommissioningClusterConnectNetworkResponseParams.debugText = "x"
    _ = _MTRNetworkCommissioningClusterConnectNetworkResponseParams.debugText
    _MTRNetworkCommissioningClusterConnectNetworkResponseParams.errorValue = n(1)
    _ = _MTRNetworkCommissioningClusterConnectNetworkResponseParams.errorValue
    _MTRNetworkCommissioningClusterConnectNetworkResponseParams.networkingStatus = n(1)
    _ = _MTRNetworkCommissioningClusterConnectNetworkResponseParams.networkingStatus
    _MTRNetworkCommissioningClusterConnectNetworkResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRNetworkCommissioningClusterConnectNetworkResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRNetworkCommissioningClusterConnectNetworkResponseParams.description.contains("MTRNetworkCommissioningClusterConnectNetworkResponseParams"), "MTRNetworkCommissioningClusterConnectNetworkResponseParams desc")
}

func testMTRNetworkCommissioningClusterNetworkConfigResponseParamsParamsWave11() {
    let _MTRNetworkCommissioningClusterNetworkConfigResponseParams = (try? MTRNetworkCommissioningClusterNetworkConfigResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRNetworkCommissioningClusterNetworkConfigResponseParams()
    _MTRNetworkCommissioningClusterNetworkConfigResponseParams.debugText = "x"
    _ = _MTRNetworkCommissioningClusterNetworkConfigResponseParams.debugText
    _MTRNetworkCommissioningClusterNetworkConfigResponseParams.networkIndex = n(1)
    _ = _MTRNetworkCommissioningClusterNetworkConfigResponseParams.networkIndex
    _MTRNetworkCommissioningClusterNetworkConfigResponseParams.networkingStatus = n(1)
    _ = _MTRNetworkCommissioningClusterNetworkConfigResponseParams.networkingStatus
    _MTRNetworkCommissioningClusterNetworkConfigResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRNetworkCommissioningClusterNetworkConfigResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRNetworkCommissioningClusterNetworkConfigResponseParams.description.contains("MTRNetworkCommissioningClusterNetworkConfigResponseParams"), "MTRNetworkCommissioningClusterNetworkConfigResponseParams desc")
}

func testMTRNetworkCommissioningClusterNetworkInfoParamsWave11() {
    let _MTRNetworkCommissioningClusterNetworkInfo = MTRNetworkCommissioningClusterNetworkInfo()
    _MTRNetworkCommissioningClusterNetworkInfo.connected = n(1)
    _ = _MTRNetworkCommissioningClusterNetworkInfo.connected
    _MTRNetworkCommissioningClusterNetworkInfo.networkID = Data([1])
    _ = _MTRNetworkCommissioningClusterNetworkInfo.networkID
    mtrRequire(!_MTRNetworkCommissioningClusterNetworkInfo.description.isEmpty, "MTRNetworkCommissioningClusterNetworkInfo desc")
}

func testMTRNetworkCommissioningClusterNetworkInfoStructParamsWave11() {
    let _MTRNetworkCommissioningClusterNetworkInfoStruct = MTRNetworkCommissioningClusterNetworkInfoStruct()
    _MTRNetworkCommissioningClusterNetworkInfoStruct.connected = n(1)
    _ = _MTRNetworkCommissioningClusterNetworkInfoStruct.connected
    _MTRNetworkCommissioningClusterNetworkInfoStruct.networkID = Data([1])
    _ = _MTRNetworkCommissioningClusterNetworkInfoStruct.networkID
    mtrRequire(_MTRNetworkCommissioningClusterNetworkInfoStruct.description.contains("MTRNetworkCommissioningClusterNetworkInfoStruct"), "MTRNetworkCommissioningClusterNetworkInfoStruct desc")
}

func testMTRNetworkCommissioningClusterRemoveNetworkParamsParamsWave11() {
    let _MTRNetworkCommissioningClusterRemoveNetworkParams = MTRNetworkCommissioningClusterRemoveNetworkParams()
    _MTRNetworkCommissioningClusterRemoveNetworkParams.breadcrumb = n(1)
    _ = _MTRNetworkCommissioningClusterRemoveNetworkParams.breadcrumb
    _MTRNetworkCommissioningClusterRemoveNetworkParams.networkID = Data([1])
    _ = _MTRNetworkCommissioningClusterRemoveNetworkParams.networkID
    _MTRNetworkCommissioningClusterRemoveNetworkParams.serverSideProcessingTimeout = n(1)
    _ = _MTRNetworkCommissioningClusterRemoveNetworkParams.serverSideProcessingTimeout
    _MTRNetworkCommissioningClusterRemoveNetworkParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRNetworkCommissioningClusterRemoveNetworkParams.timedInvokeTimeoutMs
    mtrRequire(_MTRNetworkCommissioningClusterRemoveNetworkParams.description.contains("MTRNetworkCommissioningClusterRemoveNetworkParams"), "MTRNetworkCommissioningClusterRemoveNetworkParams desc")
}

func testMTRNetworkCommissioningClusterReorderNetworkParamsParamsWave11() {
    let _MTRNetworkCommissioningClusterReorderNetworkParams = MTRNetworkCommissioningClusterReorderNetworkParams()
    _MTRNetworkCommissioningClusterReorderNetworkParams.breadcrumb = n(1)
    _ = _MTRNetworkCommissioningClusterReorderNetworkParams.breadcrumb
    _MTRNetworkCommissioningClusterReorderNetworkParams.networkID = Data([1])
    _ = _MTRNetworkCommissioningClusterReorderNetworkParams.networkID
    _MTRNetworkCommissioningClusterReorderNetworkParams.networkIndex = n(1)
    _ = _MTRNetworkCommissioningClusterReorderNetworkParams.networkIndex
    _MTRNetworkCommissioningClusterReorderNetworkParams.serverSideProcessingTimeout = n(1)
    _ = _MTRNetworkCommissioningClusterReorderNetworkParams.serverSideProcessingTimeout
    _MTRNetworkCommissioningClusterReorderNetworkParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRNetworkCommissioningClusterReorderNetworkParams.timedInvokeTimeoutMs
    mtrRequire(_MTRNetworkCommissioningClusterReorderNetworkParams.description.contains("MTRNetworkCommissioningClusterReorderNetworkParams"), "MTRNetworkCommissioningClusterReorderNetworkParams desc")
}

func testMTRNetworkCommissioningClusterScanNetworksParamsParamsWave11() {
    let _MTRNetworkCommissioningClusterScanNetworksParams = MTRNetworkCommissioningClusterScanNetworksParams()
    _MTRNetworkCommissioningClusterScanNetworksParams.breadcrumb = n(1)
    _ = _MTRNetworkCommissioningClusterScanNetworksParams.breadcrumb
    _MTRNetworkCommissioningClusterScanNetworksParams.serverSideProcessingTimeout = n(1)
    _ = _MTRNetworkCommissioningClusterScanNetworksParams.serverSideProcessingTimeout
    _MTRNetworkCommissioningClusterScanNetworksParams.ssid = Data([1])
    _ = _MTRNetworkCommissioningClusterScanNetworksParams.ssid
    _MTRNetworkCommissioningClusterScanNetworksParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRNetworkCommissioningClusterScanNetworksParams.timedInvokeTimeoutMs
    mtrRequire(_MTRNetworkCommissioningClusterScanNetworksParams.description.contains("MTRNetworkCommissioningClusterScanNetworksParams"), "MTRNetworkCommissioningClusterScanNetworksParams desc")
}

func testMTRNetworkCommissioningClusterScanNetworksResponseParamsParamsWave11() {
    let _MTRNetworkCommissioningClusterScanNetworksResponseParams = (try? MTRNetworkCommissioningClusterScanNetworksResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRNetworkCommissioningClusterScanNetworksResponseParams()
    _MTRNetworkCommissioningClusterScanNetworksResponseParams.debugText = "x"
    _ = _MTRNetworkCommissioningClusterScanNetworksResponseParams.debugText
    _MTRNetworkCommissioningClusterScanNetworksResponseParams.networkingStatus = n(1)
    _ = _MTRNetworkCommissioningClusterScanNetworksResponseParams.networkingStatus
    _MTRNetworkCommissioningClusterScanNetworksResponseParams.threadScanResults = [n(1)] as [Any]
    _ = _MTRNetworkCommissioningClusterScanNetworksResponseParams.threadScanResults
    _MTRNetworkCommissioningClusterScanNetworksResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRNetworkCommissioningClusterScanNetworksResponseParams.timedInvokeTimeoutMs
    _MTRNetworkCommissioningClusterScanNetworksResponseParams.wiFiScanResults = [n(1)] as [Any]
    _ = _MTRNetworkCommissioningClusterScanNetworksResponseParams.wiFiScanResults
    mtrRequire(_MTRNetworkCommissioningClusterScanNetworksResponseParams.description.contains("MTRNetworkCommissioningClusterScanNetworksResponseParams"), "MTRNetworkCommissioningClusterScanNetworksResponseParams desc")
}

func testMTRNetworkCommissioningClusterThreadInterfaceScanResultParamsWave11() {
    let _MTRNetworkCommissioningClusterThreadInterfaceScanResult = MTRNetworkCommissioningClusterThreadInterfaceScanResult()
    _MTRNetworkCommissioningClusterThreadInterfaceScanResult.channel = n(1)
    _ = _MTRNetworkCommissioningClusterThreadInterfaceScanResult.channel
    _MTRNetworkCommissioningClusterThreadInterfaceScanResult.extendedAddress = Data([1])
    _ = _MTRNetworkCommissioningClusterThreadInterfaceScanResult.extendedAddress
    _MTRNetworkCommissioningClusterThreadInterfaceScanResult.extendedPanId = n(1)
    _ = _MTRNetworkCommissioningClusterThreadInterfaceScanResult.extendedPanId
    _MTRNetworkCommissioningClusterThreadInterfaceScanResult.lqi = n(1)
    _ = _MTRNetworkCommissioningClusterThreadInterfaceScanResult.lqi
    _MTRNetworkCommissioningClusterThreadInterfaceScanResult.networkName = "x"
    _ = _MTRNetworkCommissioningClusterThreadInterfaceScanResult.networkName
    _MTRNetworkCommissioningClusterThreadInterfaceScanResult.panId = n(1)
    _ = _MTRNetworkCommissioningClusterThreadInterfaceScanResult.panId
    _MTRNetworkCommissioningClusterThreadInterfaceScanResult.rssi = n(1)
    _ = _MTRNetworkCommissioningClusterThreadInterfaceScanResult.rssi
    _MTRNetworkCommissioningClusterThreadInterfaceScanResult.version = n(1)
    _ = _MTRNetworkCommissioningClusterThreadInterfaceScanResult.version
    mtrRequire(!_MTRNetworkCommissioningClusterThreadInterfaceScanResult.description.isEmpty, "MTRNetworkCommissioningClusterThreadInterfaceScanResult desc")
}

func testMTRNetworkCommissioningClusterThreadInterfaceScanResultStructParamsWave11() {
    let _MTRNetworkCommissioningClusterThreadInterfaceScanResultStruct = MTRNetworkCommissioningClusterThreadInterfaceScanResultStruct()
    _MTRNetworkCommissioningClusterThreadInterfaceScanResultStruct.channel = n(1)
    _ = _MTRNetworkCommissioningClusterThreadInterfaceScanResultStruct.channel
    _MTRNetworkCommissioningClusterThreadInterfaceScanResultStruct.extendedAddress = Data([1])
    _ = _MTRNetworkCommissioningClusterThreadInterfaceScanResultStruct.extendedAddress
    _MTRNetworkCommissioningClusterThreadInterfaceScanResultStruct.extendedPanId = n(1)
    _ = _MTRNetworkCommissioningClusterThreadInterfaceScanResultStruct.extendedPanId
    _MTRNetworkCommissioningClusterThreadInterfaceScanResultStruct.lqi = n(1)
    _ = _MTRNetworkCommissioningClusterThreadInterfaceScanResultStruct.lqi
    _MTRNetworkCommissioningClusterThreadInterfaceScanResultStruct.networkName = "x"
    _ = _MTRNetworkCommissioningClusterThreadInterfaceScanResultStruct.networkName
    _MTRNetworkCommissioningClusterThreadInterfaceScanResultStruct.panId = n(1)
    _ = _MTRNetworkCommissioningClusterThreadInterfaceScanResultStruct.panId
    _MTRNetworkCommissioningClusterThreadInterfaceScanResultStruct.rssi = n(1)
    _ = _MTRNetworkCommissioningClusterThreadInterfaceScanResultStruct.rssi
    _MTRNetworkCommissioningClusterThreadInterfaceScanResultStruct.version = n(1)
    _ = _MTRNetworkCommissioningClusterThreadInterfaceScanResultStruct.version
    mtrRequire(_MTRNetworkCommissioningClusterThreadInterfaceScanResultStruct.description.contains("MTRNetworkCommissioningClusterThreadInterfaceScanResultStruct"), "MTRNetworkCommissioningClusterThreadInterfaceScanResultStruct desc")
}

func testMTRNetworkCommissioningClusterWiFiInterfaceScanResultParamsWave11() {
    let _MTRNetworkCommissioningClusterWiFiInterfaceScanResult = MTRNetworkCommissioningClusterWiFiInterfaceScanResult()
    _MTRNetworkCommissioningClusterWiFiInterfaceScanResult.bssid = Data([1])
    _ = _MTRNetworkCommissioningClusterWiFiInterfaceScanResult.bssid
    _MTRNetworkCommissioningClusterWiFiInterfaceScanResult.channel = n(1)
    _ = _MTRNetworkCommissioningClusterWiFiInterfaceScanResult.channel
    _MTRNetworkCommissioningClusterWiFiInterfaceScanResult.rssi = n(1)
    _ = _MTRNetworkCommissioningClusterWiFiInterfaceScanResult.rssi
    _MTRNetworkCommissioningClusterWiFiInterfaceScanResult.security = n(1)
    _ = _MTRNetworkCommissioningClusterWiFiInterfaceScanResult.security
    _MTRNetworkCommissioningClusterWiFiInterfaceScanResult.ssid = Data([1])
    _ = _MTRNetworkCommissioningClusterWiFiInterfaceScanResult.ssid
    _MTRNetworkCommissioningClusterWiFiInterfaceScanResult.wiFiBand = n(1)
    _ = _MTRNetworkCommissioningClusterWiFiInterfaceScanResult.wiFiBand
    mtrRequire(!_MTRNetworkCommissioningClusterWiFiInterfaceScanResult.description.isEmpty, "MTRNetworkCommissioningClusterWiFiInterfaceScanResult desc")
}

func testMTRNetworkCommissioningClusterWiFiInterfaceScanResultStructParamsWave11() {
    let _MTRNetworkCommissioningClusterWiFiInterfaceScanResultStruct = MTRNetworkCommissioningClusterWiFiInterfaceScanResultStruct()
    _MTRNetworkCommissioningClusterWiFiInterfaceScanResultStruct.bssid = Data([1])
    _ = _MTRNetworkCommissioningClusterWiFiInterfaceScanResultStruct.bssid
    _MTRNetworkCommissioningClusterWiFiInterfaceScanResultStruct.channel = n(1)
    _ = _MTRNetworkCommissioningClusterWiFiInterfaceScanResultStruct.channel
    _MTRNetworkCommissioningClusterWiFiInterfaceScanResultStruct.rssi = n(1)
    _ = _MTRNetworkCommissioningClusterWiFiInterfaceScanResultStruct.rssi
    _MTRNetworkCommissioningClusterWiFiInterfaceScanResultStruct.security = n(1)
    _ = _MTRNetworkCommissioningClusterWiFiInterfaceScanResultStruct.security
    _MTRNetworkCommissioningClusterWiFiInterfaceScanResultStruct.ssid = Data([1])
    _ = _MTRNetworkCommissioningClusterWiFiInterfaceScanResultStruct.ssid
    _MTRNetworkCommissioningClusterWiFiInterfaceScanResultStruct.wiFiBand = n(1)
    _ = _MTRNetworkCommissioningClusterWiFiInterfaceScanResultStruct.wiFiBand
    mtrRequire(_MTRNetworkCommissioningClusterWiFiInterfaceScanResultStruct.description.contains("MTRNetworkCommissioningClusterWiFiInterfaceScanResultStruct"), "MTRNetworkCommissioningClusterWiFiInterfaceScanResultStruct desc")
}

func testMTROTASoftwareUpdateProviderClusterApplyUpdateRequestParamsParamsWave11() {
    let _MTROTASoftwareUpdateProviderClusterApplyUpdateRequestParams = MTROTASoftwareUpdateProviderClusterApplyUpdateRequestParams()
    _MTROTASoftwareUpdateProviderClusterApplyUpdateRequestParams.newVersion = n(1)
    _ = _MTROTASoftwareUpdateProviderClusterApplyUpdateRequestParams.newVersion
    _MTROTASoftwareUpdateProviderClusterApplyUpdateRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTROTASoftwareUpdateProviderClusterApplyUpdateRequestParams.serverSideProcessingTimeout
    _MTROTASoftwareUpdateProviderClusterApplyUpdateRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROTASoftwareUpdateProviderClusterApplyUpdateRequestParams.timedInvokeTimeoutMs
    _MTROTASoftwareUpdateProviderClusterApplyUpdateRequestParams.updateToken = Data([1])
    _ = _MTROTASoftwareUpdateProviderClusterApplyUpdateRequestParams.updateToken
    mtrRequire(_MTROTASoftwareUpdateProviderClusterApplyUpdateRequestParams.description.contains("MTROTASoftwareUpdateProviderClusterApplyUpdateRequestParams"), "MTROTASoftwareUpdateProviderClusterApplyUpdateRequestParams desc")
}

func testMTROTASoftwareUpdateProviderClusterApplyUpdateResponseParamsParamsWave11() {
    let _MTROTASoftwareUpdateProviderClusterApplyUpdateResponseParams = (try? MTROTASoftwareUpdateProviderClusterApplyUpdateResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTROTASoftwareUpdateProviderClusterApplyUpdateResponseParams()
    _MTROTASoftwareUpdateProviderClusterApplyUpdateResponseParams.action = n(1)
    _ = _MTROTASoftwareUpdateProviderClusterApplyUpdateResponseParams.action
    _MTROTASoftwareUpdateProviderClusterApplyUpdateResponseParams.delayedActionTime = n(1)
    _ = _MTROTASoftwareUpdateProviderClusterApplyUpdateResponseParams.delayedActionTime
    _MTROTASoftwareUpdateProviderClusterApplyUpdateResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROTASoftwareUpdateProviderClusterApplyUpdateResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTROTASoftwareUpdateProviderClusterApplyUpdateResponseParams.description.contains("MTROTASoftwareUpdateProviderClusterApplyUpdateResponseParams"), "MTROTASoftwareUpdateProviderClusterApplyUpdateResponseParams desc")
}

func testMTROTASoftwareUpdateProviderClusterNotifyUpdateAppliedParamsParamsWave11() {
    let _MTROTASoftwareUpdateProviderClusterNotifyUpdateAppliedParams = MTROTASoftwareUpdateProviderClusterNotifyUpdateAppliedParams()
    _MTROTASoftwareUpdateProviderClusterNotifyUpdateAppliedParams.serverSideProcessingTimeout = n(1)
    _ = _MTROTASoftwareUpdateProviderClusterNotifyUpdateAppliedParams.serverSideProcessingTimeout
    _MTROTASoftwareUpdateProviderClusterNotifyUpdateAppliedParams.softwareVersion = n(1)
    _ = _MTROTASoftwareUpdateProviderClusterNotifyUpdateAppliedParams.softwareVersion
    _MTROTASoftwareUpdateProviderClusterNotifyUpdateAppliedParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROTASoftwareUpdateProviderClusterNotifyUpdateAppliedParams.timedInvokeTimeoutMs
    _MTROTASoftwareUpdateProviderClusterNotifyUpdateAppliedParams.updateToken = Data([1])
    _ = _MTROTASoftwareUpdateProviderClusterNotifyUpdateAppliedParams.updateToken
    mtrRequire(_MTROTASoftwareUpdateProviderClusterNotifyUpdateAppliedParams.description.contains("MTROTASoftwareUpdateProviderClusterNotifyUpdateAppliedParams"), "MTROTASoftwareUpdateProviderClusterNotifyUpdateAppliedParams desc")
}

func testMTROTASoftwareUpdateProviderClusterQueryImageParamsParamsWave11() {
    let _MTROTASoftwareUpdateProviderClusterQueryImageParams = MTROTASoftwareUpdateProviderClusterQueryImageParams()
    _MTROTASoftwareUpdateProviderClusterQueryImageParams.hardwareVersion = n(1)
    _ = _MTROTASoftwareUpdateProviderClusterQueryImageParams.hardwareVersion
    _MTROTASoftwareUpdateProviderClusterQueryImageParams.location = "x"
    _ = _MTROTASoftwareUpdateProviderClusterQueryImageParams.location
    _MTROTASoftwareUpdateProviderClusterQueryImageParams.metadataForProvider = Data([1])
    _ = _MTROTASoftwareUpdateProviderClusterQueryImageParams.metadataForProvider
    _MTROTASoftwareUpdateProviderClusterQueryImageParams.productID = n(1)
    _ = _MTROTASoftwareUpdateProviderClusterQueryImageParams.productID
    _MTROTASoftwareUpdateProviderClusterQueryImageParams.productId = n(1)
    _ = _MTROTASoftwareUpdateProviderClusterQueryImageParams.productId
    _MTROTASoftwareUpdateProviderClusterQueryImageParams.protocolsSupported = [n(1)] as [Any]
    _ = _MTROTASoftwareUpdateProviderClusterQueryImageParams.protocolsSupported
    _MTROTASoftwareUpdateProviderClusterQueryImageParams.requestorCanConsent = n(1)
    _ = _MTROTASoftwareUpdateProviderClusterQueryImageParams.requestorCanConsent
    _MTROTASoftwareUpdateProviderClusterQueryImageParams.serverSideProcessingTimeout = n(1)
    _ = _MTROTASoftwareUpdateProviderClusterQueryImageParams.serverSideProcessingTimeout
    _MTROTASoftwareUpdateProviderClusterQueryImageParams.softwareVersion = n(1)
    _ = _MTROTASoftwareUpdateProviderClusterQueryImageParams.softwareVersion
    _MTROTASoftwareUpdateProviderClusterQueryImageParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROTASoftwareUpdateProviderClusterQueryImageParams.timedInvokeTimeoutMs
    _MTROTASoftwareUpdateProviderClusterQueryImageParams.vendorID = n(1)
    _ = _MTROTASoftwareUpdateProviderClusterQueryImageParams.vendorID
    _MTROTASoftwareUpdateProviderClusterQueryImageParams.vendorId = n(1)
    _ = _MTROTASoftwareUpdateProviderClusterQueryImageParams.vendorId
    mtrRequire(_MTROTASoftwareUpdateProviderClusterQueryImageParams.description.contains("MTROTASoftwareUpdateProviderClusterQueryImageParams"), "MTROTASoftwareUpdateProviderClusterQueryImageParams desc")
}

func testMTROTASoftwareUpdateProviderClusterQueryImageResponseParamsParamsWave11() {
    let _MTROTASoftwareUpdateProviderClusterQueryImageResponseParams = (try? MTROTASoftwareUpdateProviderClusterQueryImageResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTROTASoftwareUpdateProviderClusterQueryImageResponseParams()
    _MTROTASoftwareUpdateProviderClusterQueryImageResponseParams.delayedActionTime = n(1)
    _ = _MTROTASoftwareUpdateProviderClusterQueryImageResponseParams.delayedActionTime
    _MTROTASoftwareUpdateProviderClusterQueryImageResponseParams.imageURI = "x"
    _ = _MTROTASoftwareUpdateProviderClusterQueryImageResponseParams.imageURI
    _MTROTASoftwareUpdateProviderClusterQueryImageResponseParams.metadataForRequestor = Data([1])
    _ = _MTROTASoftwareUpdateProviderClusterQueryImageResponseParams.metadataForRequestor
    _MTROTASoftwareUpdateProviderClusterQueryImageResponseParams.softwareVersion = n(1)
    _ = _MTROTASoftwareUpdateProviderClusterQueryImageResponseParams.softwareVersion
    _MTROTASoftwareUpdateProviderClusterQueryImageResponseParams.softwareVersionString = "x"
    _ = _MTROTASoftwareUpdateProviderClusterQueryImageResponseParams.softwareVersionString
    _MTROTASoftwareUpdateProviderClusterQueryImageResponseParams.status = n(1)
    _ = _MTROTASoftwareUpdateProviderClusterQueryImageResponseParams.status
    _MTROTASoftwareUpdateProviderClusterQueryImageResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROTASoftwareUpdateProviderClusterQueryImageResponseParams.timedInvokeTimeoutMs
    _MTROTASoftwareUpdateProviderClusterQueryImageResponseParams.updateToken = Data([1])
    _ = _MTROTASoftwareUpdateProviderClusterQueryImageResponseParams.updateToken
    _MTROTASoftwareUpdateProviderClusterQueryImageResponseParams.userConsentNeeded = n(1)
    _ = _MTROTASoftwareUpdateProviderClusterQueryImageResponseParams.userConsentNeeded
    mtrRequire(_MTROTASoftwareUpdateProviderClusterQueryImageResponseParams.description.contains("MTROTASoftwareUpdateProviderClusterQueryImageResponseParams"), "MTROTASoftwareUpdateProviderClusterQueryImageResponseParams desc")
}

func testMTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParamsParamsWave11() {
    let _MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams = MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams()
    _MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams.announcementReason = n(1)
    _ = _MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams.announcementReason
    _MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams.endpoint = n(1)
    _ = _MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams.endpoint
    _MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams.metadataForNode = Data([1])
    _ = _MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams.metadataForNode
    _MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams.providerNodeID = n(1)
    _ = _MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams.providerNodeID
    _MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams.providerNodeId = n(1)
    _ = _MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams.providerNodeId
    _MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams.serverSideProcessingTimeout = n(1)
    _ = _MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams.serverSideProcessingTimeout
    _MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams.timedInvokeTimeoutMs
    _MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams.vendorID = n(1)
    _ = _MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams.vendorID
    _MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams.vendorId = n(1)
    _ = _MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams.vendorId
    mtrRequire(_MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams.description.contains("MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams"), "MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams desc")
}

func testMTROTASoftwareUpdateRequestorClusterDownloadErrorEventParamsWave11() {
    let _MTROTASoftwareUpdateRequestorClusterDownloadErrorEvent = MTROTASoftwareUpdateRequestorClusterDownloadErrorEvent()
    _MTROTASoftwareUpdateRequestorClusterDownloadErrorEvent.bytesDownloaded = n(1)
    _ = _MTROTASoftwareUpdateRequestorClusterDownloadErrorEvent.bytesDownloaded
    _MTROTASoftwareUpdateRequestorClusterDownloadErrorEvent.platformCode = n(1)
    _ = _MTROTASoftwareUpdateRequestorClusterDownloadErrorEvent.platformCode
    _MTROTASoftwareUpdateRequestorClusterDownloadErrorEvent.progressPercent = n(1)
    _ = _MTROTASoftwareUpdateRequestorClusterDownloadErrorEvent.progressPercent
    _MTROTASoftwareUpdateRequestorClusterDownloadErrorEvent.softwareVersion = n(1)
    _ = _MTROTASoftwareUpdateRequestorClusterDownloadErrorEvent.softwareVersion
    mtrRequire(_MTROTASoftwareUpdateRequestorClusterDownloadErrorEvent.description.contains("MTROTASoftwareUpdateRequestorClusterDownloadErrorEvent"), "MTROTASoftwareUpdateRequestorClusterDownloadErrorEvent desc")
}

func testMTROTASoftwareUpdateRequestorClusterProviderLocationParamsWave11() {
    let _MTROTASoftwareUpdateRequestorClusterProviderLocation = MTROTASoftwareUpdateRequestorClusterProviderLocation()
    _MTROTASoftwareUpdateRequestorClusterProviderLocation.endpoint = n(1)
    _ = _MTROTASoftwareUpdateRequestorClusterProviderLocation.endpoint
    _MTROTASoftwareUpdateRequestorClusterProviderLocation.fabricIndex = n(1)
    _ = _MTROTASoftwareUpdateRequestorClusterProviderLocation.fabricIndex
    _MTROTASoftwareUpdateRequestorClusterProviderLocation.providerNodeID = n(1)
    _ = _MTROTASoftwareUpdateRequestorClusterProviderLocation.providerNodeID
    mtrRequire(_MTROTASoftwareUpdateRequestorClusterProviderLocation.description.contains("MTROTASoftwareUpdateRequestorClusterProviderLocation"), "MTROTASoftwareUpdateRequestorClusterProviderLocation desc")
}

func testMTROTASoftwareUpdateRequestorClusterStateTransitionEventParamsWave11() {
    let _MTROTASoftwareUpdateRequestorClusterStateTransitionEvent = MTROTASoftwareUpdateRequestorClusterStateTransitionEvent()
    _MTROTASoftwareUpdateRequestorClusterStateTransitionEvent.newState = n(1)
    _ = _MTROTASoftwareUpdateRequestorClusterStateTransitionEvent.newState
    _MTROTASoftwareUpdateRequestorClusterStateTransitionEvent.previousState = n(1)
    _ = _MTROTASoftwareUpdateRequestorClusterStateTransitionEvent.previousState
    _MTROTASoftwareUpdateRequestorClusterStateTransitionEvent.reason = n(1)
    _ = _MTROTASoftwareUpdateRequestorClusterStateTransitionEvent.reason
    _MTROTASoftwareUpdateRequestorClusterStateTransitionEvent.targetSoftwareVersion = n(1)
    _ = _MTROTASoftwareUpdateRequestorClusterStateTransitionEvent.targetSoftwareVersion
    mtrRequire(_MTROTASoftwareUpdateRequestorClusterStateTransitionEvent.description.contains("MTROTASoftwareUpdateRequestorClusterStateTransitionEvent"), "MTROTASoftwareUpdateRequestorClusterStateTransitionEvent desc")
}

func testMTROTASoftwareUpdateRequestorClusterVersionAppliedEventParamsWave11() {
    let _MTROTASoftwareUpdateRequestorClusterVersionAppliedEvent = MTROTASoftwareUpdateRequestorClusterVersionAppliedEvent()
    _MTROTASoftwareUpdateRequestorClusterVersionAppliedEvent.productID = n(1)
    _ = _MTROTASoftwareUpdateRequestorClusterVersionAppliedEvent.productID
    _MTROTASoftwareUpdateRequestorClusterVersionAppliedEvent.softwareVersion = n(1)
    _ = _MTROTASoftwareUpdateRequestorClusterVersionAppliedEvent.softwareVersion
    mtrRequire(_MTROTASoftwareUpdateRequestorClusterVersionAppliedEvent.description.contains("MTROTASoftwareUpdateRequestorClusterVersionAppliedEvent"), "MTROTASoftwareUpdateRequestorClusterVersionAppliedEvent desc")
}

func testMTROccupancySensingClusterHoldTimeLimitsStructParamsWave11() {
    let _MTROccupancySensingClusterHoldTimeLimitsStruct = MTROccupancySensingClusterHoldTimeLimitsStruct()
    _MTROccupancySensingClusterHoldTimeLimitsStruct.holdTimeDefault = n(1)
    _ = _MTROccupancySensingClusterHoldTimeLimitsStruct.holdTimeDefault
    _MTROccupancySensingClusterHoldTimeLimitsStruct.holdTimeMax = n(1)
    _ = _MTROccupancySensingClusterHoldTimeLimitsStruct.holdTimeMax
    _MTROccupancySensingClusterHoldTimeLimitsStruct.holdTimeMin = n(1)
    _ = _MTROccupancySensingClusterHoldTimeLimitsStruct.holdTimeMin
    mtrRequire(_MTROccupancySensingClusterHoldTimeLimitsStruct.description.contains("MTROccupancySensingClusterHoldTimeLimitsStruct"), "MTROccupancySensingClusterHoldTimeLimitsStruct desc")
}

func testMTROccupancySensingClusterOccupancyChangedEventParamsWave11() {
    let _MTROccupancySensingClusterOccupancyChangedEvent = MTROccupancySensingClusterOccupancyChangedEvent()
    _MTROccupancySensingClusterOccupancyChangedEvent.occupancy = n(1)
    _ = _MTROccupancySensingClusterOccupancyChangedEvent.occupancy
    mtrRequire(_MTROccupancySensingClusterOccupancyChangedEvent.description.contains("MTROccupancySensingClusterOccupancyChangedEvent"), "MTROccupancySensingClusterOccupancyChangedEvent desc")
}

func testMTROnOffClusterOffParamsParamsWave11() {
    let _MTROnOffClusterOffParams = MTROnOffClusterOffParams()
    _MTROnOffClusterOffParams.serverSideProcessingTimeout = n(1)
    _ = _MTROnOffClusterOffParams.serverSideProcessingTimeout
    _MTROnOffClusterOffParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROnOffClusterOffParams.timedInvokeTimeoutMs
    mtrRequire(_MTROnOffClusterOffParams.description.contains("MTROnOffClusterOffParams"), "MTROnOffClusterOffParams desc")
}

func testMTROnOffClusterOffWithEffectParamsParamsWave11() {
    let _MTROnOffClusterOffWithEffectParams = MTROnOffClusterOffWithEffectParams()
    _MTROnOffClusterOffWithEffectParams.effectId = n(1)
    _ = _MTROnOffClusterOffWithEffectParams.effectId
    _MTROnOffClusterOffWithEffectParams.effectIdentifier = n(1)
    _ = _MTROnOffClusterOffWithEffectParams.effectIdentifier
    _MTROnOffClusterOffWithEffectParams.effectVariant = n(1)
    _ = _MTROnOffClusterOffWithEffectParams.effectVariant
    _MTROnOffClusterOffWithEffectParams.serverSideProcessingTimeout = n(1)
    _ = _MTROnOffClusterOffWithEffectParams.serverSideProcessingTimeout
    _MTROnOffClusterOffWithEffectParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROnOffClusterOffWithEffectParams.timedInvokeTimeoutMs
    mtrRequire(_MTROnOffClusterOffWithEffectParams.description.contains("MTROnOffClusterOffWithEffectParams"), "MTROnOffClusterOffWithEffectParams desc")
}

func testMTROnOffClusterOnParamsParamsWave11() {
    let _MTROnOffClusterOnParams = MTROnOffClusterOnParams()
    _MTROnOffClusterOnParams.serverSideProcessingTimeout = n(1)
    _ = _MTROnOffClusterOnParams.serverSideProcessingTimeout
    _MTROnOffClusterOnParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROnOffClusterOnParams.timedInvokeTimeoutMs
    mtrRequire(_MTROnOffClusterOnParams.description.contains("MTROnOffClusterOnParams"), "MTROnOffClusterOnParams desc")
}

func testMTROnOffClusterOnWithRecallGlobalSceneParamsParamsWave11() {
    let _MTROnOffClusterOnWithRecallGlobalSceneParams = MTROnOffClusterOnWithRecallGlobalSceneParams()
    _MTROnOffClusterOnWithRecallGlobalSceneParams.serverSideProcessingTimeout = n(1)
    _ = _MTROnOffClusterOnWithRecallGlobalSceneParams.serverSideProcessingTimeout
    _MTROnOffClusterOnWithRecallGlobalSceneParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROnOffClusterOnWithRecallGlobalSceneParams.timedInvokeTimeoutMs
    mtrRequire(_MTROnOffClusterOnWithRecallGlobalSceneParams.description.contains("MTROnOffClusterOnWithRecallGlobalSceneParams"), "MTROnOffClusterOnWithRecallGlobalSceneParams desc")
}

func testMTROnOffClusterOnWithTimedOffParamsParamsWave11() {
    let _MTROnOffClusterOnWithTimedOffParams = MTROnOffClusterOnWithTimedOffParams()
    _MTROnOffClusterOnWithTimedOffParams.offWaitTime = n(1)
    _ = _MTROnOffClusterOnWithTimedOffParams.offWaitTime
    _MTROnOffClusterOnWithTimedOffParams.onOffControl = n(1)
    _ = _MTROnOffClusterOnWithTimedOffParams.onOffControl
    _MTROnOffClusterOnWithTimedOffParams.onTime = n(1)
    _ = _MTROnOffClusterOnWithTimedOffParams.onTime
    _MTROnOffClusterOnWithTimedOffParams.serverSideProcessingTimeout = n(1)
    _ = _MTROnOffClusterOnWithTimedOffParams.serverSideProcessingTimeout
    _MTROnOffClusterOnWithTimedOffParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROnOffClusterOnWithTimedOffParams.timedInvokeTimeoutMs
    mtrRequire(_MTROnOffClusterOnWithTimedOffParams.description.contains("MTROnOffClusterOnWithTimedOffParams"), "MTROnOffClusterOnWithTimedOffParams desc")
}

func testMTROnOffClusterToggleParamsParamsWave11() {
    let _MTROnOffClusterToggleParams = MTROnOffClusterToggleParams()
    _MTROnOffClusterToggleParams.serverSideProcessingTimeout = n(1)
    _ = _MTROnOffClusterToggleParams.serverSideProcessingTimeout
    _MTROnOffClusterToggleParams.timedInvokeTimeoutMs = n(1)
    _ = _MTROnOffClusterToggleParams.timedInvokeTimeoutMs
    mtrRequire(_MTROnOffClusterToggleParams.description.contains("MTROnOffClusterToggleParams"), "MTROnOffClusterToggleParams desc")
}

