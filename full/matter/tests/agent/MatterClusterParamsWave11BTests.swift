import Foundation
import Dispatch
import Matter

func testMTRBridgedDeviceBasicClusterReachableChangedEventParamsWave11() {
    let _MTRBridgedDeviceBasicClusterReachableChangedEvent = MTRBridgedDeviceBasicClusterReachableChangedEvent()
    _MTRBridgedDeviceBasicClusterReachableChangedEvent.reachableNewValue = n(1)
    _ = _MTRBridgedDeviceBasicClusterReachableChangedEvent.reachableNewValue
    mtrRequire(!_MTRBridgedDeviceBasicClusterReachableChangedEvent.description.isEmpty, "MTRBridgedDeviceBasicClusterReachableChangedEvent desc")
}

func testMTRBridgedDeviceBasicClusterStartUpEventParamsWave11() {
    let _MTRBridgedDeviceBasicClusterStartUpEvent = MTRBridgedDeviceBasicClusterStartUpEvent()
    _MTRBridgedDeviceBasicClusterStartUpEvent.softwareVersion = n(1)
    _ = _MTRBridgedDeviceBasicClusterStartUpEvent.softwareVersion
    mtrRequire(!_MTRBridgedDeviceBasicClusterStartUpEvent.description.isEmpty, "MTRBridgedDeviceBasicClusterStartUpEvent desc")
}

func testMTRBridgedDeviceBasicInformationClusterActiveChangedEventParamsWave11() {
    let _MTRBridgedDeviceBasicInformationClusterActiveChangedEvent = MTRBridgedDeviceBasicInformationClusterActiveChangedEvent()
    _MTRBridgedDeviceBasicInformationClusterActiveChangedEvent.promisedActiveDuration = n(1)
    _ = _MTRBridgedDeviceBasicInformationClusterActiveChangedEvent.promisedActiveDuration
    mtrRequire(_MTRBridgedDeviceBasicInformationClusterActiveChangedEvent.description.contains("MTRBridgedDeviceBasicInformationClusterActiveChangedEvent"), "MTRBridgedDeviceBasicInformationClusterActiveChangedEvent desc")
}

func testMTRBridgedDeviceBasicInformationClusterKeepActiveParamsParamsWave11() {
    let _MTRBridgedDeviceBasicInformationClusterKeepActiveParams = MTRBridgedDeviceBasicInformationClusterKeepActiveParams()
    _MTRBridgedDeviceBasicInformationClusterKeepActiveParams.serverSideProcessingTimeout = n(1)
    _ = _MTRBridgedDeviceBasicInformationClusterKeepActiveParams.serverSideProcessingTimeout
    _MTRBridgedDeviceBasicInformationClusterKeepActiveParams.stayActiveDuration = n(1)
    _ = _MTRBridgedDeviceBasicInformationClusterKeepActiveParams.stayActiveDuration
    _MTRBridgedDeviceBasicInformationClusterKeepActiveParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRBridgedDeviceBasicInformationClusterKeepActiveParams.timedInvokeTimeoutMs
    _MTRBridgedDeviceBasicInformationClusterKeepActiveParams.timeoutMs = n(1)
    _ = _MTRBridgedDeviceBasicInformationClusterKeepActiveParams.timeoutMs
    mtrRequire(_MTRBridgedDeviceBasicInformationClusterKeepActiveParams.description.contains("MTRBridgedDeviceBasicInformationClusterKeepActiveParams"), "MTRBridgedDeviceBasicInformationClusterKeepActiveParams desc")
}

func testMTRBridgedDeviceBasicInformationClusterProductAppearanceStructParamsWave11() {
    let _MTRBridgedDeviceBasicInformationClusterProductAppearanceStruct = MTRBridgedDeviceBasicInformationClusterProductAppearanceStruct()
    _MTRBridgedDeviceBasicInformationClusterProductAppearanceStruct.finish = n(1)
    _ = _MTRBridgedDeviceBasicInformationClusterProductAppearanceStruct.finish
    _MTRBridgedDeviceBasicInformationClusterProductAppearanceStruct.primaryColor = n(1)
    _ = _MTRBridgedDeviceBasicInformationClusterProductAppearanceStruct.primaryColor
    mtrRequire(_MTRBridgedDeviceBasicInformationClusterProductAppearanceStruct.description.contains("MTRBridgedDeviceBasicInformationClusterProductAppearanceStruct"), "MTRBridgedDeviceBasicInformationClusterProductAppearanceStruct desc")
}

func testMTRBridgedDeviceBasicInformationClusterReachableChangedEventParamsWave11() {
    let _MTRBridgedDeviceBasicInformationClusterReachableChangedEvent = MTRBridgedDeviceBasicInformationClusterReachableChangedEvent()
    _MTRBridgedDeviceBasicInformationClusterReachableChangedEvent.reachableNewValue = n(1)
    _ = _MTRBridgedDeviceBasicInformationClusterReachableChangedEvent.reachableNewValue
    mtrRequire(_MTRBridgedDeviceBasicInformationClusterReachableChangedEvent.description.contains("MTRBridgedDeviceBasicInformationClusterReachableChangedEvent"), "MTRBridgedDeviceBasicInformationClusterReachableChangedEvent desc")
}

func testMTRBridgedDeviceBasicInformationClusterStartUpEventParamsWave11() {
    let _MTRBridgedDeviceBasicInformationClusterStartUpEvent = MTRBridgedDeviceBasicInformationClusterStartUpEvent()
    _MTRBridgedDeviceBasicInformationClusterStartUpEvent.softwareVersion = n(1)
    _ = _MTRBridgedDeviceBasicInformationClusterStartUpEvent.softwareVersion
    mtrRequire(_MTRBridgedDeviceBasicInformationClusterStartUpEvent.description.contains("MTRBridgedDeviceBasicInformationClusterStartUpEvent"), "MTRBridgedDeviceBasicInformationClusterStartUpEvent desc")
}

func testMTRChannelClusterCancelRecordProgramParamsParamsWave11() {
    let _MTRChannelClusterCancelRecordProgramParams = MTRChannelClusterCancelRecordProgramParams()
    _MTRChannelClusterCancelRecordProgramParams.data = Data([1])
    _ = _MTRChannelClusterCancelRecordProgramParams.data
    _MTRChannelClusterCancelRecordProgramParams.programIdentifier = "x"
    _ = _MTRChannelClusterCancelRecordProgramParams.programIdentifier
    _MTRChannelClusterCancelRecordProgramParams.serverSideProcessingTimeout = n(1)
    _ = _MTRChannelClusterCancelRecordProgramParams.serverSideProcessingTimeout
    _MTRChannelClusterCancelRecordProgramParams.shouldRecordSeries = n(1)
    _ = _MTRChannelClusterCancelRecordProgramParams.shouldRecordSeries
    _MTRChannelClusterCancelRecordProgramParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRChannelClusterCancelRecordProgramParams.timedInvokeTimeoutMs
    mtrRequire(_MTRChannelClusterCancelRecordProgramParams.description.contains("MTRChannelClusterCancelRecordProgramParams"), "MTRChannelClusterCancelRecordProgramParams desc")
}

func testMTRChannelClusterChangeChannelByNumberParamsParamsWave11() {
    let _MTRChannelClusterChangeChannelByNumberParams = MTRChannelClusterChangeChannelByNumberParams()
    _MTRChannelClusterChangeChannelByNumberParams.majorNumber = n(1)
    _ = _MTRChannelClusterChangeChannelByNumberParams.majorNumber
    _MTRChannelClusterChangeChannelByNumberParams.minorNumber = n(1)
    _ = _MTRChannelClusterChangeChannelByNumberParams.minorNumber
    _MTRChannelClusterChangeChannelByNumberParams.serverSideProcessingTimeout = n(1)
    _ = _MTRChannelClusterChangeChannelByNumberParams.serverSideProcessingTimeout
    _MTRChannelClusterChangeChannelByNumberParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRChannelClusterChangeChannelByNumberParams.timedInvokeTimeoutMs
    mtrRequire(_MTRChannelClusterChangeChannelByNumberParams.description.contains("MTRChannelClusterChangeChannelByNumberParams"), "MTRChannelClusterChangeChannelByNumberParams desc")
}

func testMTRChannelClusterChangeChannelParamsParamsWave11() {
    let _MTRChannelClusterChangeChannelParams = MTRChannelClusterChangeChannelParams()
    _MTRChannelClusterChangeChannelParams.match = "x"
    _ = _MTRChannelClusterChangeChannelParams.match
    _MTRChannelClusterChangeChannelParams.serverSideProcessingTimeout = n(1)
    _ = _MTRChannelClusterChangeChannelParams.serverSideProcessingTimeout
    _MTRChannelClusterChangeChannelParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRChannelClusterChangeChannelParams.timedInvokeTimeoutMs
    mtrRequire(_MTRChannelClusterChangeChannelParams.description.contains("MTRChannelClusterChangeChannelParams"), "MTRChannelClusterChangeChannelParams desc")
}

func testMTRChannelClusterChangeChannelResponseParamsParamsWave11() {
    let _MTRChannelClusterChangeChannelResponseParams = (try? MTRChannelClusterChangeChannelResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRChannelClusterChangeChannelResponseParams()
    _MTRChannelClusterChangeChannelResponseParams.data = "x"
    _ = _MTRChannelClusterChangeChannelResponseParams.data
    _MTRChannelClusterChangeChannelResponseParams.status = n(1)
    _ = _MTRChannelClusterChangeChannelResponseParams.status
    _MTRChannelClusterChangeChannelResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRChannelClusterChangeChannelResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRChannelClusterChangeChannelResponseParams.description.contains("MTRChannelClusterChangeChannelResponseParams"), "MTRChannelClusterChangeChannelResponseParams desc")
}

func testMTRChannelClusterChannelInfoParamsWave11() {
    let _MTRChannelClusterChannelInfo = MTRChannelClusterChannelInfo()
    _MTRChannelClusterChannelInfo.affiliateCallSign = "x"
    _ = _MTRChannelClusterChannelInfo.affiliateCallSign
    _MTRChannelClusterChannelInfo.callSign = "x"
    _ = _MTRChannelClusterChannelInfo.callSign
    _MTRChannelClusterChannelInfo.majorNumber = n(1)
    _ = _MTRChannelClusterChannelInfo.majorNumber
    _MTRChannelClusterChannelInfo.minorNumber = n(1)
    _ = _MTRChannelClusterChannelInfo.minorNumber
    _MTRChannelClusterChannelInfo.name = "x"
    _ = _MTRChannelClusterChannelInfo.name
    mtrRequire(!_MTRChannelClusterChannelInfo.description.isEmpty, "MTRChannelClusterChannelInfo desc")
}

func testMTRChannelClusterChannelInfoStructParamsWave11() {
    let _MTRChannelClusterChannelInfoStruct = MTRChannelClusterChannelInfoStruct()
    _MTRChannelClusterChannelInfoStruct.affiliateCallSign = "x"
    _ = _MTRChannelClusterChannelInfoStruct.affiliateCallSign
    _MTRChannelClusterChannelInfoStruct.callSign = "x"
    _ = _MTRChannelClusterChannelInfoStruct.callSign
    _MTRChannelClusterChannelInfoStruct.identifier = "x"
    _ = _MTRChannelClusterChannelInfoStruct.identifier
    _MTRChannelClusterChannelInfoStruct.majorNumber = n(1)
    _ = _MTRChannelClusterChannelInfoStruct.majorNumber
    _MTRChannelClusterChannelInfoStruct.minorNumber = n(1)
    _ = _MTRChannelClusterChannelInfoStruct.minorNumber
    _MTRChannelClusterChannelInfoStruct.name = "x"
    _ = _MTRChannelClusterChannelInfoStruct.name
    _MTRChannelClusterChannelInfoStruct.`type` = n(1)
    _ = _MTRChannelClusterChannelInfoStruct.`type`
    mtrRequire(_MTRChannelClusterChannelInfoStruct.description.contains("MTRChannelClusterChannelInfoStruct"), "MTRChannelClusterChannelInfoStruct desc")
}

func testMTRChannelClusterChannelPagingStructParamsWave11() {
    let _MTRChannelClusterChannelPagingStruct = MTRChannelClusterChannelPagingStruct()
    _MTRChannelClusterChannelPagingStruct.nextToken = MTRChannelClusterPageTokenStruct()
    _ = _MTRChannelClusterChannelPagingStruct.nextToken
    _MTRChannelClusterChannelPagingStruct.previousToken = MTRChannelClusterPageTokenStruct()
    _ = _MTRChannelClusterChannelPagingStruct.previousToken
    mtrRequire(_MTRChannelClusterChannelPagingStruct.description.contains("MTRChannelClusterChannelPagingStruct"), "MTRChannelClusterChannelPagingStruct desc")
}

func testMTRChannelClusterGetProgramGuideParamsParamsWave11() {
    let _MTRChannelClusterGetProgramGuideParams = MTRChannelClusterGetProgramGuideParams()
    _MTRChannelClusterGetProgramGuideParams.channelList = [n(1)] as [Any]
    _ = _MTRChannelClusterGetProgramGuideParams.channelList
    _MTRChannelClusterGetProgramGuideParams.data = Data([1])
    _ = _MTRChannelClusterGetProgramGuideParams.data
    _MTRChannelClusterGetProgramGuideParams.endTime = n(1)
    _ = _MTRChannelClusterGetProgramGuideParams.endTime
    _MTRChannelClusterGetProgramGuideParams.pageToken = MTRChannelClusterPageTokenStruct()
    _ = _MTRChannelClusterGetProgramGuideParams.pageToken
    _MTRChannelClusterGetProgramGuideParams.recordingFlag = n(1)
    _ = _MTRChannelClusterGetProgramGuideParams.recordingFlag
    _MTRChannelClusterGetProgramGuideParams.serverSideProcessingTimeout = n(1)
    _ = _MTRChannelClusterGetProgramGuideParams.serverSideProcessingTimeout
    _MTRChannelClusterGetProgramGuideParams.startTime = n(1)
    _ = _MTRChannelClusterGetProgramGuideParams.startTime
    _MTRChannelClusterGetProgramGuideParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRChannelClusterGetProgramGuideParams.timedInvokeTimeoutMs
    mtrRequire(_MTRChannelClusterGetProgramGuideParams.description.contains("MTRChannelClusterGetProgramGuideParams"), "MTRChannelClusterGetProgramGuideParams desc")
}

func testMTRChannelClusterLineupInfoParamsWave11() {
    let _MTRChannelClusterLineupInfo = MTRChannelClusterLineupInfo()
    _MTRChannelClusterLineupInfo.lineupInfoType = n(1)
    _ = _MTRChannelClusterLineupInfo.lineupInfoType
    _MTRChannelClusterLineupInfo.lineupName = "x"
    _ = _MTRChannelClusterLineupInfo.lineupName
    _MTRChannelClusterLineupInfo.operatorName = "x"
    _ = _MTRChannelClusterLineupInfo.operatorName
    _MTRChannelClusterLineupInfo.postalCode = "x"
    _ = _MTRChannelClusterLineupInfo.postalCode
    mtrRequire(!_MTRChannelClusterLineupInfo.description.isEmpty, "MTRChannelClusterLineupInfo desc")
}

func testMTRChannelClusterLineupInfoStructParamsWave11() {
    let _MTRChannelClusterLineupInfoStruct = MTRChannelClusterLineupInfoStruct()
    _MTRChannelClusterLineupInfoStruct.lineupInfoType = n(1)
    _ = _MTRChannelClusterLineupInfoStruct.lineupInfoType
    _MTRChannelClusterLineupInfoStruct.lineupName = "x"
    _ = _MTRChannelClusterLineupInfoStruct.lineupName
    _MTRChannelClusterLineupInfoStruct.operatorName = "x"
    _ = _MTRChannelClusterLineupInfoStruct.operatorName
    _MTRChannelClusterLineupInfoStruct.postalCode = "x"
    _ = _MTRChannelClusterLineupInfoStruct.postalCode
    mtrRequire(_MTRChannelClusterLineupInfoStruct.description.contains("MTRChannelClusterLineupInfoStruct"), "MTRChannelClusterLineupInfoStruct desc")
}

func testMTRChannelClusterPageTokenStructParamsWave11() {
    let _MTRChannelClusterPageTokenStruct = MTRChannelClusterPageTokenStruct()
    _MTRChannelClusterPageTokenStruct.after = "x"
    _ = _MTRChannelClusterPageTokenStruct.after
    _MTRChannelClusterPageTokenStruct.before = "x"
    _ = _MTRChannelClusterPageTokenStruct.before
    _MTRChannelClusterPageTokenStruct.limit = n(1)
    _ = _MTRChannelClusterPageTokenStruct.limit
    mtrRequire(_MTRChannelClusterPageTokenStruct.description.contains("MTRChannelClusterPageTokenStruct"), "MTRChannelClusterPageTokenStruct desc")
}

func testMTRChannelClusterProgramCastStructParamsWave11() {
    let _MTRChannelClusterProgramCastStruct = MTRChannelClusterProgramCastStruct()
    _MTRChannelClusterProgramCastStruct.name = "x"
    _ = _MTRChannelClusterProgramCastStruct.name
    _MTRChannelClusterProgramCastStruct.role = "x"
    _ = _MTRChannelClusterProgramCastStruct.role
    mtrRequire(_MTRChannelClusterProgramCastStruct.description.contains("MTRChannelClusterProgramCastStruct"), "MTRChannelClusterProgramCastStruct desc")
}

func testMTRChannelClusterProgramCategoryStructParamsWave11() {
    let _MTRChannelClusterProgramCategoryStruct = MTRChannelClusterProgramCategoryStruct()
    _MTRChannelClusterProgramCategoryStruct.category = "x"
    _ = _MTRChannelClusterProgramCategoryStruct.category
    _MTRChannelClusterProgramCategoryStruct.subCategory = "x"
    _ = _MTRChannelClusterProgramCategoryStruct.subCategory
    mtrRequire(_MTRChannelClusterProgramCategoryStruct.description.contains("MTRChannelClusterProgramCategoryStruct"), "MTRChannelClusterProgramCategoryStruct desc")
}

func testMTRChannelClusterProgramGuideResponseParamsParamsWave11() {
    let _MTRChannelClusterProgramGuideResponseParams = (try? MTRChannelClusterProgramGuideResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRChannelClusterProgramGuideResponseParams()
    _MTRChannelClusterProgramGuideResponseParams.paging = MTRChannelClusterChannelPagingStruct()
    _ = _MTRChannelClusterProgramGuideResponseParams.paging
    _MTRChannelClusterProgramGuideResponseParams.programList = [n(1)] as [Any]
    _ = _MTRChannelClusterProgramGuideResponseParams.programList
    mtrRequire(_MTRChannelClusterProgramGuideResponseParams.description.contains("MTRChannelClusterProgramGuideResponseParams"), "MTRChannelClusterProgramGuideResponseParams desc")
}

func testMTRChannelClusterProgramStructParamsWave11() {
    let _MTRChannelClusterProgramStruct = MTRChannelClusterProgramStruct()
    _MTRChannelClusterProgramStruct.audioLanguages = [n(1)] as [Any]
    _ = _MTRChannelClusterProgramStruct.audioLanguages
    _MTRChannelClusterProgramStruct.castList = [n(1)] as [Any]
    _ = _MTRChannelClusterProgramStruct.castList
    _MTRChannelClusterProgramStruct.categoryList = [n(1)] as [Any]
    _ = _MTRChannelClusterProgramStruct.categoryList
    _MTRChannelClusterProgramStruct.channel = MTRChannelClusterChannelInfoStruct()
    _ = _MTRChannelClusterProgramStruct.channel
    _MTRChannelClusterProgramStruct.descriptionString = "x"
    _ = _MTRChannelClusterProgramStruct.descriptionString
    _MTRChannelClusterProgramStruct.endTime = n(1)
    _ = _MTRChannelClusterProgramStruct.endTime
    _MTRChannelClusterProgramStruct.identifier = "x"
    _ = _MTRChannelClusterProgramStruct.identifier
    _MTRChannelClusterProgramStruct.parentalGuidanceText = "x"
    _ = _MTRChannelClusterProgramStruct.parentalGuidanceText
    _MTRChannelClusterProgramStruct.ratings = [n(1)] as [Any]
    _ = _MTRChannelClusterProgramStruct.ratings
    _MTRChannelClusterProgramStruct.recordingFlag = n(1)
    _ = _MTRChannelClusterProgramStruct.recordingFlag
    _MTRChannelClusterProgramStruct.releaseDate = "x"
    _ = _MTRChannelClusterProgramStruct.releaseDate
    _MTRChannelClusterProgramStruct.seriesInfo = MTRChannelClusterSeriesInfoStruct()
    _ = _MTRChannelClusterProgramStruct.seriesInfo
    _MTRChannelClusterProgramStruct.startTime = n(1)
    _ = _MTRChannelClusterProgramStruct.startTime
    _MTRChannelClusterProgramStruct.subtitle = "x"
    _ = _MTRChannelClusterProgramStruct.subtitle
    _MTRChannelClusterProgramStruct.title = "x"
    _ = _MTRChannelClusterProgramStruct.title
    mtrRequire(_MTRChannelClusterProgramStruct.description.contains("MTRChannelClusterProgramStruct"), "MTRChannelClusterProgramStruct desc")
}

func testMTRChannelClusterRecordProgramParamsParamsWave11() {
    let _MTRChannelClusterRecordProgramParams = MTRChannelClusterRecordProgramParams()
    _MTRChannelClusterRecordProgramParams.data = Data([1])
    _ = _MTRChannelClusterRecordProgramParams.data
    _MTRChannelClusterRecordProgramParams.programIdentifier = "x"
    _ = _MTRChannelClusterRecordProgramParams.programIdentifier
    _MTRChannelClusterRecordProgramParams.serverSideProcessingTimeout = n(1)
    _ = _MTRChannelClusterRecordProgramParams.serverSideProcessingTimeout
    _MTRChannelClusterRecordProgramParams.shouldRecordSeries = n(1)
    _ = _MTRChannelClusterRecordProgramParams.shouldRecordSeries
    _MTRChannelClusterRecordProgramParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRChannelClusterRecordProgramParams.timedInvokeTimeoutMs
    mtrRequire(_MTRChannelClusterRecordProgramParams.description.contains("MTRChannelClusterRecordProgramParams"), "MTRChannelClusterRecordProgramParams desc")
}

func testMTRChannelClusterSeriesInfoStructParamsWave11() {
    let _MTRChannelClusterSeriesInfoStruct = MTRChannelClusterSeriesInfoStruct()
    _MTRChannelClusterSeriesInfoStruct.episode = "x"
    _ = _MTRChannelClusterSeriesInfoStruct.episode
    _MTRChannelClusterSeriesInfoStruct.season = "x"
    _ = _MTRChannelClusterSeriesInfoStruct.season
    mtrRequire(_MTRChannelClusterSeriesInfoStruct.description.contains("MTRChannelClusterSeriesInfoStruct"), "MTRChannelClusterSeriesInfoStruct desc")
}

func testMTRChannelClusterSkipChannelParamsParamsWave11() {
    let _MTRChannelClusterSkipChannelParams = MTRChannelClusterSkipChannelParams()
    _MTRChannelClusterSkipChannelParams.count = n(1)
    _ = _MTRChannelClusterSkipChannelParams.count
    _MTRChannelClusterSkipChannelParams.serverSideProcessingTimeout = n(1)
    _ = _MTRChannelClusterSkipChannelParams.serverSideProcessingTimeout
    _MTRChannelClusterSkipChannelParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRChannelClusterSkipChannelParams.timedInvokeTimeoutMs
    mtrRequire(_MTRChannelClusterSkipChannelParams.description.contains("MTRChannelClusterSkipChannelParams"), "MTRChannelClusterSkipChannelParams desc")
}

func testMTRCommissionerControlClusterCommissionNodeParamsParamsWave11() {
    let _MTRCommissionerControlClusterCommissionNodeParams = MTRCommissionerControlClusterCommissionNodeParams()
    _MTRCommissionerControlClusterCommissionNodeParams.requestID = n(1)
    _ = _MTRCommissionerControlClusterCommissionNodeParams.requestID
    _MTRCommissionerControlClusterCommissionNodeParams.responseTimeoutSeconds = n(1)
    _ = _MTRCommissionerControlClusterCommissionNodeParams.responseTimeoutSeconds
    _MTRCommissionerControlClusterCommissionNodeParams.serverSideProcessingTimeout = n(1)
    _ = _MTRCommissionerControlClusterCommissionNodeParams.serverSideProcessingTimeout
    _MTRCommissionerControlClusterCommissionNodeParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRCommissionerControlClusterCommissionNodeParams.timedInvokeTimeoutMs
    mtrRequire(_MTRCommissionerControlClusterCommissionNodeParams.description.contains("MTRCommissionerControlClusterCommissionNodeParams"), "MTRCommissionerControlClusterCommissionNodeParams desc")
}

func testMTRCommissionerControlClusterCommissioningRequestResultEventParamsWave11() {
    let _MTRCommissionerControlClusterCommissioningRequestResultEvent = MTRCommissionerControlClusterCommissioningRequestResultEvent()
    _MTRCommissionerControlClusterCommissioningRequestResultEvent.clientNodeID = n(1)
    _ = _MTRCommissionerControlClusterCommissioningRequestResultEvent.clientNodeID
    _MTRCommissionerControlClusterCommissioningRequestResultEvent.fabricIndex = n(1)
    _ = _MTRCommissionerControlClusterCommissioningRequestResultEvent.fabricIndex
    _MTRCommissionerControlClusterCommissioningRequestResultEvent.requestID = n(1)
    _ = _MTRCommissionerControlClusterCommissioningRequestResultEvent.requestID
    _MTRCommissionerControlClusterCommissioningRequestResultEvent.statusCode = n(1)
    _ = _MTRCommissionerControlClusterCommissioningRequestResultEvent.statusCode
    mtrRequire(_MTRCommissionerControlClusterCommissioningRequestResultEvent.description.contains("MTRCommissionerControlClusterCommissioningRequestResultEvent"), "MTRCommissionerControlClusterCommissioningRequestResultEvent desc")
}

func testMTRCommissionerControlClusterRequestCommissioningApprovalParamsParamsWave11() {
    let _MTRCommissionerControlClusterRequestCommissioningApprovalParams = MTRCommissionerControlClusterRequestCommissioningApprovalParams()
    _MTRCommissionerControlClusterRequestCommissioningApprovalParams.label = "x"
    _ = _MTRCommissionerControlClusterRequestCommissioningApprovalParams.label
    _MTRCommissionerControlClusterRequestCommissioningApprovalParams.productID = n(1)
    _ = _MTRCommissionerControlClusterRequestCommissioningApprovalParams.productID
    _MTRCommissionerControlClusterRequestCommissioningApprovalParams.requestID = n(1)
    _ = _MTRCommissionerControlClusterRequestCommissioningApprovalParams.requestID
    _MTRCommissionerControlClusterRequestCommissioningApprovalParams.serverSideProcessingTimeout = n(1)
    _ = _MTRCommissionerControlClusterRequestCommissioningApprovalParams.serverSideProcessingTimeout
    _MTRCommissionerControlClusterRequestCommissioningApprovalParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRCommissionerControlClusterRequestCommissioningApprovalParams.timedInvokeTimeoutMs
    _MTRCommissionerControlClusterRequestCommissioningApprovalParams.vendorID = n(1)
    _ = _MTRCommissionerControlClusterRequestCommissioningApprovalParams.vendorID
    mtrRequire(_MTRCommissionerControlClusterRequestCommissioningApprovalParams.description.contains("MTRCommissionerControlClusterRequestCommissioningApprovalParams"), "MTRCommissionerControlClusterRequestCommissioningApprovalParams desc")
}

func testMTRCommissionerControlClusterReverseOpenCommissioningWindowParamsParamsWave11() {
    let _MTRCommissionerControlClusterReverseOpenCommissioningWindowParams = (try? MTRCommissionerControlClusterReverseOpenCommissioningWindowParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRCommissionerControlClusterReverseOpenCommissioningWindowParams()
    _MTRCommissionerControlClusterReverseOpenCommissioningWindowParams.commissioningTimeout = n(1)
    _ = _MTRCommissionerControlClusterReverseOpenCommissioningWindowParams.commissioningTimeout
    _MTRCommissionerControlClusterReverseOpenCommissioningWindowParams.discriminator = n(1)
    _ = _MTRCommissionerControlClusterReverseOpenCommissioningWindowParams.discriminator
    _MTRCommissionerControlClusterReverseOpenCommissioningWindowParams.iterations = n(1)
    _ = _MTRCommissionerControlClusterReverseOpenCommissioningWindowParams.iterations
    _MTRCommissionerControlClusterReverseOpenCommissioningWindowParams.pakePasscodeVerifier = Data([1])
    _ = _MTRCommissionerControlClusterReverseOpenCommissioningWindowParams.pakePasscodeVerifier
    _MTRCommissionerControlClusterReverseOpenCommissioningWindowParams.salt = Data([1])
    _ = _MTRCommissionerControlClusterReverseOpenCommissioningWindowParams.salt
    mtrRequire(_MTRCommissionerControlClusterReverseOpenCommissioningWindowParams.description.contains("MTRCommissionerControlClusterReverseOpenCommissioningWindowParams"), "MTRCommissionerControlClusterReverseOpenCommissioningWindowParams desc")
}

func testMTRContentAppObserverClusterContentAppMessageParamsParamsWave11() {
    let _MTRContentAppObserverClusterContentAppMessageParams = MTRContentAppObserverClusterContentAppMessageParams()
    _MTRContentAppObserverClusterContentAppMessageParams.data = "x"
    _ = _MTRContentAppObserverClusterContentAppMessageParams.data
    _MTRContentAppObserverClusterContentAppMessageParams.encodingHint = "x"
    _ = _MTRContentAppObserverClusterContentAppMessageParams.encodingHint
    _MTRContentAppObserverClusterContentAppMessageParams.serverSideProcessingTimeout = n(1)
    _ = _MTRContentAppObserverClusterContentAppMessageParams.serverSideProcessingTimeout
    _MTRContentAppObserverClusterContentAppMessageParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRContentAppObserverClusterContentAppMessageParams.timedInvokeTimeoutMs
    mtrRequire(_MTRContentAppObserverClusterContentAppMessageParams.description.contains("MTRContentAppObserverClusterContentAppMessageParams"), "MTRContentAppObserverClusterContentAppMessageParams desc")
}

func testMTRContentAppObserverClusterContentAppMessageResponseParamsParamsWave11() {
    let _MTRContentAppObserverClusterContentAppMessageResponseParams = (try? MTRContentAppObserverClusterContentAppMessageResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRContentAppObserverClusterContentAppMessageResponseParams()
    _MTRContentAppObserverClusterContentAppMessageResponseParams.data = "x"
    _ = _MTRContentAppObserverClusterContentAppMessageResponseParams.data
    _MTRContentAppObserverClusterContentAppMessageResponseParams.encodingHint = "x"
    _ = _MTRContentAppObserverClusterContentAppMessageResponseParams.encodingHint
    _MTRContentAppObserverClusterContentAppMessageResponseParams.status = n(1)
    _ = _MTRContentAppObserverClusterContentAppMessageResponseParams.status
    mtrRequire(_MTRContentAppObserverClusterContentAppMessageResponseParams.description.contains("MTRContentAppObserverClusterContentAppMessageResponseParams"), "MTRContentAppObserverClusterContentAppMessageResponseParams desc")
}

func testMTRContentLauncherClusterAdditionalInfoParamsWave11() {
    let _MTRContentLauncherClusterAdditionalInfo = MTRContentLauncherClusterAdditionalInfo()
    _MTRContentLauncherClusterAdditionalInfo.name = "x"
    _ = _MTRContentLauncherClusterAdditionalInfo.name
    _MTRContentLauncherClusterAdditionalInfo.value = "x"
    _ = _MTRContentLauncherClusterAdditionalInfo.value
    mtrRequire(!_MTRContentLauncherClusterAdditionalInfo.description.isEmpty, "MTRContentLauncherClusterAdditionalInfo desc")
}

func testMTRContentLauncherClusterAdditionalInfoStructParamsWave11() {
    let _MTRContentLauncherClusterAdditionalInfoStruct = MTRContentLauncherClusterAdditionalInfoStruct()
    _MTRContentLauncherClusterAdditionalInfoStruct.name = "x"
    _ = _MTRContentLauncherClusterAdditionalInfoStruct.name
    _MTRContentLauncherClusterAdditionalInfoStruct.value = "x"
    _ = _MTRContentLauncherClusterAdditionalInfoStruct.value
    mtrRequire(_MTRContentLauncherClusterAdditionalInfoStruct.description.contains("MTRContentLauncherClusterAdditionalInfoStruct"), "MTRContentLauncherClusterAdditionalInfoStruct desc")
}

func testMTRContentLauncherClusterBrandingInformationParamsWave11() {
    let _MTRContentLauncherClusterBrandingInformation = MTRContentLauncherClusterBrandingInformation()
    _MTRContentLauncherClusterBrandingInformation.background = MTRContentLauncherClusterStyleInformationStruct()
    _ = _MTRContentLauncherClusterBrandingInformation.background
    _MTRContentLauncherClusterBrandingInformation.logo = MTRContentLauncherClusterStyleInformationStruct()
    _ = _MTRContentLauncherClusterBrandingInformation.logo
    _MTRContentLauncherClusterBrandingInformation.progressBar = MTRContentLauncherClusterStyleInformationStruct()
    _ = _MTRContentLauncherClusterBrandingInformation.progressBar
    _MTRContentLauncherClusterBrandingInformation.providerName = "x"
    _ = _MTRContentLauncherClusterBrandingInformation.providerName
    _MTRContentLauncherClusterBrandingInformation.splash = MTRContentLauncherClusterStyleInformationStruct()
    _ = _MTRContentLauncherClusterBrandingInformation.splash
    _MTRContentLauncherClusterBrandingInformation.waterMark = MTRContentLauncherClusterStyleInformationStruct()
    _ = _MTRContentLauncherClusterBrandingInformation.waterMark
    mtrRequire(!_MTRContentLauncherClusterBrandingInformation.description.isEmpty, "MTRContentLauncherClusterBrandingInformation desc")
}

func testMTRContentLauncherClusterBrandingInformationStructParamsWave11() {
    let _MTRContentLauncherClusterBrandingInformationStruct = MTRContentLauncherClusterBrandingInformationStruct()
    _MTRContentLauncherClusterBrandingInformationStruct.background = MTRContentLauncherClusterStyleInformationStruct()
    _ = _MTRContentLauncherClusterBrandingInformationStruct.background
    _MTRContentLauncherClusterBrandingInformationStruct.logo = MTRContentLauncherClusterStyleInformationStruct()
    _ = _MTRContentLauncherClusterBrandingInformationStruct.logo
    _MTRContentLauncherClusterBrandingInformationStruct.progressBar = MTRContentLauncherClusterStyleInformationStruct()
    _ = _MTRContentLauncherClusterBrandingInformationStruct.progressBar
    _MTRContentLauncherClusterBrandingInformationStruct.providerName = "x"
    _ = _MTRContentLauncherClusterBrandingInformationStruct.providerName
    _MTRContentLauncherClusterBrandingInformationStruct.splash = MTRContentLauncherClusterStyleInformationStruct()
    _ = _MTRContentLauncherClusterBrandingInformationStruct.splash
    _MTRContentLauncherClusterBrandingInformationStruct.waterMark = MTRContentLauncherClusterStyleInformationStruct()
    _ = _MTRContentLauncherClusterBrandingInformationStruct.waterMark
    mtrRequire(_MTRContentLauncherClusterBrandingInformationStruct.description.contains("MTRContentLauncherClusterBrandingInformationStruct"), "MTRContentLauncherClusterBrandingInformationStruct desc")
}

func testMTRContentLauncherClusterContentSearchParamsWave11() {
    let _MTRContentLauncherClusterContentSearch = MTRContentLauncherClusterContentSearch()
    _MTRContentLauncherClusterContentSearch.parameterList = [n(1)] as [Any]
    _ = _MTRContentLauncherClusterContentSearch.parameterList
    mtrRequire(!_MTRContentLauncherClusterContentSearch.description.isEmpty, "MTRContentLauncherClusterContentSearch desc")
}

func testMTRContentLauncherClusterContentSearchStructParamsWave11() {
    let _MTRContentLauncherClusterContentSearchStruct = MTRContentLauncherClusterContentSearchStruct()
    _MTRContentLauncherClusterContentSearchStruct.parameterList = [n(1)] as [Any]
    _ = _MTRContentLauncherClusterContentSearchStruct.parameterList
    mtrRequire(_MTRContentLauncherClusterContentSearchStruct.description.contains("MTRContentLauncherClusterContentSearchStruct"), "MTRContentLauncherClusterContentSearchStruct desc")
}

func testMTRContentLauncherClusterDimensionParamsWave11() {
    let _MTRContentLauncherClusterDimension = MTRContentLauncherClusterDimension()
    _MTRContentLauncherClusterDimension.height = n(1)
    _ = _MTRContentLauncherClusterDimension.height
    _MTRContentLauncherClusterDimension.metric = n(1)
    _ = _MTRContentLauncherClusterDimension.metric
    _MTRContentLauncherClusterDimension.width = n(1)
    _ = _MTRContentLauncherClusterDimension.width
    mtrRequire(!_MTRContentLauncherClusterDimension.description.isEmpty, "MTRContentLauncherClusterDimension desc")
}

func testMTRContentLauncherClusterDimensionStructParamsWave11() {
    let _MTRContentLauncherClusterDimensionStruct = MTRContentLauncherClusterDimensionStruct()
    _MTRContentLauncherClusterDimensionStruct.height = n(1)
    _ = _MTRContentLauncherClusterDimensionStruct.height
    _MTRContentLauncherClusterDimensionStruct.metric = n(1)
    _ = _MTRContentLauncherClusterDimensionStruct.metric
    _MTRContentLauncherClusterDimensionStruct.width = n(1)
    _ = _MTRContentLauncherClusterDimensionStruct.width
    mtrRequire(_MTRContentLauncherClusterDimensionStruct.description.contains("MTRContentLauncherClusterDimensionStruct"), "MTRContentLauncherClusterDimensionStruct desc")
}

func testMTRContentLauncherClusterLaunchContentParamsParamsWave11() {
    let _MTRContentLauncherClusterLaunchContentParams = MTRContentLauncherClusterLaunchContentParams()
    _MTRContentLauncherClusterLaunchContentParams.autoPlay = n(1)
    _ = _MTRContentLauncherClusterLaunchContentParams.autoPlay
    _MTRContentLauncherClusterLaunchContentParams.data = "x"
    _ = _MTRContentLauncherClusterLaunchContentParams.data
    _MTRContentLauncherClusterLaunchContentParams.search = MTRContentLauncherClusterContentSearchStruct()
    _ = _MTRContentLauncherClusterLaunchContentParams.search
    _MTRContentLauncherClusterLaunchContentParams.serverSideProcessingTimeout = n(1)
    _ = _MTRContentLauncherClusterLaunchContentParams.serverSideProcessingTimeout
    _MTRContentLauncherClusterLaunchContentParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRContentLauncherClusterLaunchContentParams.timedInvokeTimeoutMs
    _MTRContentLauncherClusterLaunchContentParams.useCurrentContext = n(1)
    _ = _MTRContentLauncherClusterLaunchContentParams.useCurrentContext
    mtrRequire(_MTRContentLauncherClusterLaunchContentParams.description.contains("MTRContentLauncherClusterLaunchContentParams"), "MTRContentLauncherClusterLaunchContentParams desc")
}

func testMTRContentLauncherClusterLaunchResponseParamsParamsWave11() {
    let _MTRContentLauncherClusterLaunchResponseParams = MTRContentLauncherClusterLaunchResponseParams()
    _MTRContentLauncherClusterLaunchResponseParams.data = "x"
    _ = _MTRContentLauncherClusterLaunchResponseParams.data
    _MTRContentLauncherClusterLaunchResponseParams.status = n(1)
    _ = _MTRContentLauncherClusterLaunchResponseParams.status
    _MTRContentLauncherClusterLaunchResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRContentLauncherClusterLaunchResponseParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRContentLauncherClusterLaunchResponseParams.description.isEmpty, "MTRContentLauncherClusterLaunchResponseParams desc")
}

func testMTRContentLauncherClusterLaunchURLParamsParamsWave11() {
    let _MTRContentLauncherClusterLaunchURLParams = MTRContentLauncherClusterLaunchURLParams()
    _MTRContentLauncherClusterLaunchURLParams.brandingInformation = MTRContentLauncherClusterBrandingInformationStruct()
    _ = _MTRContentLauncherClusterLaunchURLParams.brandingInformation
    _MTRContentLauncherClusterLaunchURLParams.contentURL = "x"
    _ = _MTRContentLauncherClusterLaunchURLParams.contentURL
    _MTRContentLauncherClusterLaunchURLParams.displayString = "x"
    _ = _MTRContentLauncherClusterLaunchURLParams.displayString
    _MTRContentLauncherClusterLaunchURLParams.serverSideProcessingTimeout = n(1)
    _ = _MTRContentLauncherClusterLaunchURLParams.serverSideProcessingTimeout
    _MTRContentLauncherClusterLaunchURLParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRContentLauncherClusterLaunchURLParams.timedInvokeTimeoutMs
    mtrRequire(_MTRContentLauncherClusterLaunchURLParams.description.contains("MTRContentLauncherClusterLaunchURLParams"), "MTRContentLauncherClusterLaunchURLParams desc")
}

func testMTRContentLauncherClusterLauncherResponseParamsParamsWave11() {
    let _MTRContentLauncherClusterLauncherResponseParams = (try? MTRContentLauncherClusterLauncherResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRContentLauncherClusterLauncherResponseParams()
    _MTRContentLauncherClusterLauncherResponseParams.data = "x"
    _ = _MTRContentLauncherClusterLauncherResponseParams.data
    _MTRContentLauncherClusterLauncherResponseParams.status = n(1)
    _ = _MTRContentLauncherClusterLauncherResponseParams.status
    _MTRContentLauncherClusterLauncherResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRContentLauncherClusterLauncherResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRContentLauncherClusterLauncherResponseParams.description.contains("MTRContentLauncherClusterLauncherResponseParams"), "MTRContentLauncherClusterLauncherResponseParams desc")
}

func testMTRContentLauncherClusterParameterParamsWave11() {
    let _MTRContentLauncherClusterParameter = MTRContentLauncherClusterParameter()
    _MTRContentLauncherClusterParameter.externalIDList = [n(1)] as [Any]
    _ = _MTRContentLauncherClusterParameter.externalIDList
    _MTRContentLauncherClusterParameter.`type` = n(1)
    _ = _MTRContentLauncherClusterParameter.`type`
    _MTRContentLauncherClusterParameter.value = "x"
    _ = _MTRContentLauncherClusterParameter.value
    mtrRequire(!_MTRContentLauncherClusterParameter.description.isEmpty, "MTRContentLauncherClusterParameter desc")
}

func testMTRContentLauncherClusterParameterStructParamsWave11() {
    let _MTRContentLauncherClusterParameterStruct = MTRContentLauncherClusterParameterStruct()
    _MTRContentLauncherClusterParameterStruct.externalIDList = [n(1)] as [Any]
    _ = _MTRContentLauncherClusterParameterStruct.externalIDList
    _MTRContentLauncherClusterParameterStruct.`type` = n(1)
    _ = _MTRContentLauncherClusterParameterStruct.`type`
    _MTRContentLauncherClusterParameterStruct.value = "x"
    _ = _MTRContentLauncherClusterParameterStruct.value
    mtrRequire(_MTRContentLauncherClusterParameterStruct.description.contains("MTRContentLauncherClusterParameterStruct"), "MTRContentLauncherClusterParameterStruct desc")
}

func testMTRContentLauncherClusterStyleInformationParamsWave11() {
    let _MTRContentLauncherClusterStyleInformation = MTRContentLauncherClusterStyleInformation()
    _MTRContentLauncherClusterStyleInformation.color = "x"
    _ = _MTRContentLauncherClusterStyleInformation.color
    _MTRContentLauncherClusterStyleInformation.size = MTRContentLauncherClusterDimensionStruct()
    _ = _MTRContentLauncherClusterStyleInformation.size
    mtrRequire(!_MTRContentLauncherClusterStyleInformation.description.isEmpty, "MTRContentLauncherClusterStyleInformation desc")
}

func testMTRContentLauncherClusterStyleInformationStructParamsWave11() {
    let _MTRContentLauncherClusterStyleInformationStruct = MTRContentLauncherClusterStyleInformationStruct()
    _MTRContentLauncherClusterStyleInformationStruct.color = "x"
    _ = _MTRContentLauncherClusterStyleInformationStruct.color
    _MTRContentLauncherClusterStyleInformationStruct.imageURL = "x"
    _ = _MTRContentLauncherClusterStyleInformationStruct.imageURL
    _MTRContentLauncherClusterStyleInformationStruct.imageUrl = "x"
    _ = _MTRContentLauncherClusterStyleInformationStruct.imageUrl
    _MTRContentLauncherClusterStyleInformationStruct.size = MTRContentLauncherClusterDimensionStruct()
    _ = _MTRContentLauncherClusterStyleInformationStruct.size
    mtrRequire(_MTRContentLauncherClusterStyleInformationStruct.description.contains("MTRContentLauncherClusterStyleInformationStruct"), "MTRContentLauncherClusterStyleInformationStruct desc")
}

func testMTRDataTypeAtomicAttributeStatusStructParamsWave11() {
    let _MTRDataTypeAtomicAttributeStatusStruct = MTRDataTypeAtomicAttributeStatusStruct()
    _MTRDataTypeAtomicAttributeStatusStruct.attributeID = n(1)
    _ = _MTRDataTypeAtomicAttributeStatusStruct.attributeID
    _MTRDataTypeAtomicAttributeStatusStruct.statusCode = n(1)
    _ = _MTRDataTypeAtomicAttributeStatusStruct.statusCode
    mtrRequire(_MTRDataTypeAtomicAttributeStatusStruct.description.contains("MTRDataTypeAtomicAttributeStatusStruct"), "MTRDataTypeAtomicAttributeStatusStruct desc")
}

func testMTRDataTypeLocationDescriptorStructParamsWave11() {
    let _MTRDataTypeLocationDescriptorStruct = MTRDataTypeLocationDescriptorStruct()
    _MTRDataTypeLocationDescriptorStruct.areaType = n(1)
    _ = _MTRDataTypeLocationDescriptorStruct.areaType
    _MTRDataTypeLocationDescriptorStruct.floorNumber = n(1)
    _ = _MTRDataTypeLocationDescriptorStruct.floorNumber
    _MTRDataTypeLocationDescriptorStruct.locationName = "x"
    _ = _MTRDataTypeLocationDescriptorStruct.locationName
    mtrRequire(_MTRDataTypeLocationDescriptorStruct.description.contains("MTRDataTypeLocationDescriptorStruct"), "MTRDataTypeLocationDescriptorStruct desc")
}

func testMTRDescriptorClusterDeviceTypeParamsWave11() {
    let _MTRDescriptorClusterDeviceType = MTRDescriptorClusterDeviceType()
    _MTRDescriptorClusterDeviceType.revision = n(1)
    _ = _MTRDescriptorClusterDeviceType.revision
    mtrRequire(!_MTRDescriptorClusterDeviceType.description.isEmpty, "MTRDescriptorClusterDeviceType desc")
}

func testMTRDescriptorClusterDeviceTypeStructParamsWave11() {
    let _MTRDescriptorClusterDeviceTypeStruct = MTRDescriptorClusterDeviceTypeStruct()
    _MTRDescriptorClusterDeviceTypeStruct.deviceType = n(1)
    _ = _MTRDescriptorClusterDeviceTypeStruct.deviceType
    _MTRDescriptorClusterDeviceTypeStruct.revision = n(1)
    _ = _MTRDescriptorClusterDeviceTypeStruct.revision
    _MTRDescriptorClusterDeviceTypeStruct.`type` = n(1)
    _ = _MTRDescriptorClusterDeviceTypeStruct.`type`
    mtrRequire(_MTRDescriptorClusterDeviceTypeStruct.description.contains("MTRDescriptorClusterDeviceTypeStruct"), "MTRDescriptorClusterDeviceTypeStruct desc")
}

func testMTRDeviceEnergyManagementClusterCancelPowerAdjustRequestParamsParamsWave11() {
    let _MTRDeviceEnergyManagementClusterCancelPowerAdjustRequestParams = MTRDeviceEnergyManagementClusterCancelPowerAdjustRequestParams()
    _MTRDeviceEnergyManagementClusterCancelPowerAdjustRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDeviceEnergyManagementClusterCancelPowerAdjustRequestParams.serverSideProcessingTimeout
    _MTRDeviceEnergyManagementClusterCancelPowerAdjustRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDeviceEnergyManagementClusterCancelPowerAdjustRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRDeviceEnergyManagementClusterCancelPowerAdjustRequestParams.description.contains("MTRDeviceEnergyManagementClusterCancelPowerAdjustRequestParams"), "MTRDeviceEnergyManagementClusterCancelPowerAdjustRequestParams desc")
}

func testMTRDeviceEnergyManagementClusterCancelRequestParamsParamsWave11() {
    let _MTRDeviceEnergyManagementClusterCancelRequestParams = MTRDeviceEnergyManagementClusterCancelRequestParams()
    _MTRDeviceEnergyManagementClusterCancelRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDeviceEnergyManagementClusterCancelRequestParams.serverSideProcessingTimeout
    _MTRDeviceEnergyManagementClusterCancelRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDeviceEnergyManagementClusterCancelRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRDeviceEnergyManagementClusterCancelRequestParams.description.contains("MTRDeviceEnergyManagementClusterCancelRequestParams"), "MTRDeviceEnergyManagementClusterCancelRequestParams desc")
}

func testMTRDeviceEnergyManagementClusterConstraintsStructParamsWave11() {
    let _MTRDeviceEnergyManagementClusterConstraintsStruct = MTRDeviceEnergyManagementClusterConstraintsStruct()
    _MTRDeviceEnergyManagementClusterConstraintsStruct.duration = n(1)
    _ = _MTRDeviceEnergyManagementClusterConstraintsStruct.duration
    _MTRDeviceEnergyManagementClusterConstraintsStruct.loadControl = n(1)
    _ = _MTRDeviceEnergyManagementClusterConstraintsStruct.loadControl
    _MTRDeviceEnergyManagementClusterConstraintsStruct.maximumEnergy = n(1)
    _ = _MTRDeviceEnergyManagementClusterConstraintsStruct.maximumEnergy
    _MTRDeviceEnergyManagementClusterConstraintsStruct.nominalPower = n(1)
    _ = _MTRDeviceEnergyManagementClusterConstraintsStruct.nominalPower
    _MTRDeviceEnergyManagementClusterConstraintsStruct.startTime = n(1)
    _ = _MTRDeviceEnergyManagementClusterConstraintsStruct.startTime
    mtrRequire(_MTRDeviceEnergyManagementClusterConstraintsStruct.description.contains("MTRDeviceEnergyManagementClusterConstraintsStruct"), "MTRDeviceEnergyManagementClusterConstraintsStruct desc")
}

func testMTRDeviceEnergyManagementClusterCostStructParamsWave11() {
    let _MTRDeviceEnergyManagementClusterCostStruct = MTRDeviceEnergyManagementClusterCostStruct()
    _MTRDeviceEnergyManagementClusterCostStruct.costType = n(1)
    _ = _MTRDeviceEnergyManagementClusterCostStruct.costType
    _MTRDeviceEnergyManagementClusterCostStruct.currency = n(1)
    _ = _MTRDeviceEnergyManagementClusterCostStruct.currency
    _MTRDeviceEnergyManagementClusterCostStruct.decimalPoints = n(1)
    _ = _MTRDeviceEnergyManagementClusterCostStruct.decimalPoints
    _MTRDeviceEnergyManagementClusterCostStruct.value = n(1)
    _ = _MTRDeviceEnergyManagementClusterCostStruct.value
    mtrRequire(_MTRDeviceEnergyManagementClusterCostStruct.description.contains("MTRDeviceEnergyManagementClusterCostStruct"), "MTRDeviceEnergyManagementClusterCostStruct desc")
}

func testMTRDeviceEnergyManagementClusterForecastStructParamsWave11() {
    let _MTRDeviceEnergyManagementClusterForecastStruct = MTRDeviceEnergyManagementClusterForecastStruct()
    _MTRDeviceEnergyManagementClusterForecastStruct.activeSlotNumber = n(1)
    _ = _MTRDeviceEnergyManagementClusterForecastStruct.activeSlotNumber
    _MTRDeviceEnergyManagementClusterForecastStruct.earliestStartTime = n(1)
    _ = _MTRDeviceEnergyManagementClusterForecastStruct.earliestStartTime
    _MTRDeviceEnergyManagementClusterForecastStruct.endTime = n(1)
    _ = _MTRDeviceEnergyManagementClusterForecastStruct.endTime
    _MTRDeviceEnergyManagementClusterForecastStruct.forecastID = n(1)
    _ = _MTRDeviceEnergyManagementClusterForecastStruct.forecastID
    _MTRDeviceEnergyManagementClusterForecastStruct.forecastUpdateReason = n(1)
    _ = _MTRDeviceEnergyManagementClusterForecastStruct.forecastUpdateReason
    _MTRDeviceEnergyManagementClusterForecastStruct.isPausable = n(1)
    _ = _MTRDeviceEnergyManagementClusterForecastStruct.isPausable
    _MTRDeviceEnergyManagementClusterForecastStruct.latestEndTime = n(1)
    _ = _MTRDeviceEnergyManagementClusterForecastStruct.latestEndTime
    _MTRDeviceEnergyManagementClusterForecastStruct.slots = [n(1)] as [Any]
    _ = _MTRDeviceEnergyManagementClusterForecastStruct.slots
    _MTRDeviceEnergyManagementClusterForecastStruct.startTime = n(1)
    _ = _MTRDeviceEnergyManagementClusterForecastStruct.startTime
    mtrRequire(_MTRDeviceEnergyManagementClusterForecastStruct.description.contains("MTRDeviceEnergyManagementClusterForecastStruct"), "MTRDeviceEnergyManagementClusterForecastStruct desc")
}

func testMTRDeviceEnergyManagementClusterModifyForecastRequestParamsParamsWave11() {
    let _MTRDeviceEnergyManagementClusterModifyForecastRequestParams = MTRDeviceEnergyManagementClusterModifyForecastRequestParams()
    _MTRDeviceEnergyManagementClusterModifyForecastRequestParams.cause = n(1)
    _ = _MTRDeviceEnergyManagementClusterModifyForecastRequestParams.cause
    _MTRDeviceEnergyManagementClusterModifyForecastRequestParams.forecastID = n(1)
    _ = _MTRDeviceEnergyManagementClusterModifyForecastRequestParams.forecastID
    _MTRDeviceEnergyManagementClusterModifyForecastRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDeviceEnergyManagementClusterModifyForecastRequestParams.serverSideProcessingTimeout
    _MTRDeviceEnergyManagementClusterModifyForecastRequestParams.slotAdjustments = [n(1)] as [Any]
    _ = _MTRDeviceEnergyManagementClusterModifyForecastRequestParams.slotAdjustments
    _MTRDeviceEnergyManagementClusterModifyForecastRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDeviceEnergyManagementClusterModifyForecastRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRDeviceEnergyManagementClusterModifyForecastRequestParams.description.contains("MTRDeviceEnergyManagementClusterModifyForecastRequestParams"), "MTRDeviceEnergyManagementClusterModifyForecastRequestParams desc")
}

func testMTRDeviceEnergyManagementClusterPauseRequestParamsParamsWave11() {
    let _MTRDeviceEnergyManagementClusterPauseRequestParams = MTRDeviceEnergyManagementClusterPauseRequestParams()
    _MTRDeviceEnergyManagementClusterPauseRequestParams.cause = n(1)
    _ = _MTRDeviceEnergyManagementClusterPauseRequestParams.cause
    _MTRDeviceEnergyManagementClusterPauseRequestParams.duration = n(1)
    _ = _MTRDeviceEnergyManagementClusterPauseRequestParams.duration
    _MTRDeviceEnergyManagementClusterPauseRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDeviceEnergyManagementClusterPauseRequestParams.serverSideProcessingTimeout
    _MTRDeviceEnergyManagementClusterPauseRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDeviceEnergyManagementClusterPauseRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRDeviceEnergyManagementClusterPauseRequestParams.description.contains("MTRDeviceEnergyManagementClusterPauseRequestParams"), "MTRDeviceEnergyManagementClusterPauseRequestParams desc")
}

func testMTRDeviceEnergyManagementClusterPowerAdjustCapabilityStructParamsWave11() {
    let _MTRDeviceEnergyManagementClusterPowerAdjustCapabilityStruct = MTRDeviceEnergyManagementClusterPowerAdjustCapabilityStruct()
    _MTRDeviceEnergyManagementClusterPowerAdjustCapabilityStruct.cause = n(1)
    _ = _MTRDeviceEnergyManagementClusterPowerAdjustCapabilityStruct.cause
    _MTRDeviceEnergyManagementClusterPowerAdjustCapabilityStruct.powerAdjustCapability = [n(1)] as [Any]
    _ = _MTRDeviceEnergyManagementClusterPowerAdjustCapabilityStruct.powerAdjustCapability
    mtrRequire(_MTRDeviceEnergyManagementClusterPowerAdjustCapabilityStruct.description.contains("MTRDeviceEnergyManagementClusterPowerAdjustCapabilityStruct"), "MTRDeviceEnergyManagementClusterPowerAdjustCapabilityStruct desc")
}

func testMTRDeviceEnergyManagementClusterPowerAdjustEndEventParamsWave11() {
    let _MTRDeviceEnergyManagementClusterPowerAdjustEndEvent = MTRDeviceEnergyManagementClusterPowerAdjustEndEvent()
    _MTRDeviceEnergyManagementClusterPowerAdjustEndEvent.cause = n(1)
    _ = _MTRDeviceEnergyManagementClusterPowerAdjustEndEvent.cause
    _MTRDeviceEnergyManagementClusterPowerAdjustEndEvent.duration = n(1)
    _ = _MTRDeviceEnergyManagementClusterPowerAdjustEndEvent.duration
    _MTRDeviceEnergyManagementClusterPowerAdjustEndEvent.energyUse = n(1)
    _ = _MTRDeviceEnergyManagementClusterPowerAdjustEndEvent.energyUse
    mtrRequire(_MTRDeviceEnergyManagementClusterPowerAdjustEndEvent.description.contains("MTRDeviceEnergyManagementClusterPowerAdjustEndEvent"), "MTRDeviceEnergyManagementClusterPowerAdjustEndEvent desc")
}

func testMTRDeviceEnergyManagementClusterPowerAdjustRequestParamsParamsWave11() {
    let _MTRDeviceEnergyManagementClusterPowerAdjustRequestParams = MTRDeviceEnergyManagementClusterPowerAdjustRequestParams()
    _MTRDeviceEnergyManagementClusterPowerAdjustRequestParams.cause = n(1)
    _ = _MTRDeviceEnergyManagementClusterPowerAdjustRequestParams.cause
    _MTRDeviceEnergyManagementClusterPowerAdjustRequestParams.duration = n(1)
    _ = _MTRDeviceEnergyManagementClusterPowerAdjustRequestParams.duration
    _MTRDeviceEnergyManagementClusterPowerAdjustRequestParams.power = n(1)
    _ = _MTRDeviceEnergyManagementClusterPowerAdjustRequestParams.power
    _MTRDeviceEnergyManagementClusterPowerAdjustRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDeviceEnergyManagementClusterPowerAdjustRequestParams.serverSideProcessingTimeout
    _MTRDeviceEnergyManagementClusterPowerAdjustRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDeviceEnergyManagementClusterPowerAdjustRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRDeviceEnergyManagementClusterPowerAdjustRequestParams.description.contains("MTRDeviceEnergyManagementClusterPowerAdjustRequestParams"), "MTRDeviceEnergyManagementClusterPowerAdjustRequestParams desc")
}

func testMTRDeviceEnergyManagementClusterPowerAdjustStructParamsWave11() {
    let _MTRDeviceEnergyManagementClusterPowerAdjustStruct = MTRDeviceEnergyManagementClusterPowerAdjustStruct()
    _MTRDeviceEnergyManagementClusterPowerAdjustStruct.maxDuration = n(1)
    _ = _MTRDeviceEnergyManagementClusterPowerAdjustStruct.maxDuration
    _MTRDeviceEnergyManagementClusterPowerAdjustStruct.maxPower = n(1)
    _ = _MTRDeviceEnergyManagementClusterPowerAdjustStruct.maxPower
    _MTRDeviceEnergyManagementClusterPowerAdjustStruct.minDuration = n(1)
    _ = _MTRDeviceEnergyManagementClusterPowerAdjustStruct.minDuration
    _MTRDeviceEnergyManagementClusterPowerAdjustStruct.minPower = n(1)
    _ = _MTRDeviceEnergyManagementClusterPowerAdjustStruct.minPower
    mtrRequire(_MTRDeviceEnergyManagementClusterPowerAdjustStruct.description.contains("MTRDeviceEnergyManagementClusterPowerAdjustStruct"), "MTRDeviceEnergyManagementClusterPowerAdjustStruct desc")
}

func testMTRDeviceEnergyManagementClusterRequestConstraintBasedForecastParamsParamsWave11() {
    let _MTRDeviceEnergyManagementClusterRequestConstraintBasedForecastParams = MTRDeviceEnergyManagementClusterRequestConstraintBasedForecastParams()
    _MTRDeviceEnergyManagementClusterRequestConstraintBasedForecastParams.cause = n(1)
    _ = _MTRDeviceEnergyManagementClusterRequestConstraintBasedForecastParams.cause
    _MTRDeviceEnergyManagementClusterRequestConstraintBasedForecastParams.constraints = [n(1)] as [Any]
    _ = _MTRDeviceEnergyManagementClusterRequestConstraintBasedForecastParams.constraints
    _MTRDeviceEnergyManagementClusterRequestConstraintBasedForecastParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDeviceEnergyManagementClusterRequestConstraintBasedForecastParams.serverSideProcessingTimeout
    _MTRDeviceEnergyManagementClusterRequestConstraintBasedForecastParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDeviceEnergyManagementClusterRequestConstraintBasedForecastParams.timedInvokeTimeoutMs
    mtrRequire(_MTRDeviceEnergyManagementClusterRequestConstraintBasedForecastParams.description.contains("MTRDeviceEnergyManagementClusterRequestConstraintBasedForecastParams"), "MTRDeviceEnergyManagementClusterRequestConstraintBasedForecastParams desc")
}

func testMTRDeviceEnergyManagementClusterResumeRequestParamsParamsWave11() {
    let _MTRDeviceEnergyManagementClusterResumeRequestParams = MTRDeviceEnergyManagementClusterResumeRequestParams()
    _MTRDeviceEnergyManagementClusterResumeRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDeviceEnergyManagementClusterResumeRequestParams.serverSideProcessingTimeout
    _MTRDeviceEnergyManagementClusterResumeRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDeviceEnergyManagementClusterResumeRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRDeviceEnergyManagementClusterResumeRequestParams.description.contains("MTRDeviceEnergyManagementClusterResumeRequestParams"), "MTRDeviceEnergyManagementClusterResumeRequestParams desc")
}

func testMTRDeviceEnergyManagementClusterResumedEventParamsWave11() {
    let _MTRDeviceEnergyManagementClusterResumedEvent = MTRDeviceEnergyManagementClusterResumedEvent()
    _MTRDeviceEnergyManagementClusterResumedEvent.cause = n(1)
    _ = _MTRDeviceEnergyManagementClusterResumedEvent.cause
    mtrRequire(_MTRDeviceEnergyManagementClusterResumedEvent.description.contains("MTRDeviceEnergyManagementClusterResumedEvent"), "MTRDeviceEnergyManagementClusterResumedEvent desc")
}

func testMTRDeviceEnergyManagementClusterSlotAdjustmentStructParamsWave11() {
    let _MTRDeviceEnergyManagementClusterSlotAdjustmentStruct = MTRDeviceEnergyManagementClusterSlotAdjustmentStruct()
    _MTRDeviceEnergyManagementClusterSlotAdjustmentStruct.duration = n(1)
    _ = _MTRDeviceEnergyManagementClusterSlotAdjustmentStruct.duration
    _MTRDeviceEnergyManagementClusterSlotAdjustmentStruct.nominalPower = n(1)
    _ = _MTRDeviceEnergyManagementClusterSlotAdjustmentStruct.nominalPower
    _MTRDeviceEnergyManagementClusterSlotAdjustmentStruct.slotIndex = n(1)
    _ = _MTRDeviceEnergyManagementClusterSlotAdjustmentStruct.slotIndex
    mtrRequire(_MTRDeviceEnergyManagementClusterSlotAdjustmentStruct.description.contains("MTRDeviceEnergyManagementClusterSlotAdjustmentStruct"), "MTRDeviceEnergyManagementClusterSlotAdjustmentStruct desc")
}

func testMTRDeviceEnergyManagementClusterSlotStructParamsWave11() {
    let _MTRDeviceEnergyManagementClusterSlotStruct = MTRDeviceEnergyManagementClusterSlotStruct()
    _MTRDeviceEnergyManagementClusterSlotStruct.costs = [n(1)] as [Any]
    _ = _MTRDeviceEnergyManagementClusterSlotStruct.costs
    _MTRDeviceEnergyManagementClusterSlotStruct.defaultDuration = n(1)
    _ = _MTRDeviceEnergyManagementClusterSlotStruct.defaultDuration
    _MTRDeviceEnergyManagementClusterSlotStruct.elapsedSlotTime = n(1)
    _ = _MTRDeviceEnergyManagementClusterSlotStruct.elapsedSlotTime
    _MTRDeviceEnergyManagementClusterSlotStruct.manufacturerESAState = n(1)
    _ = _MTRDeviceEnergyManagementClusterSlotStruct.manufacturerESAState
    _MTRDeviceEnergyManagementClusterSlotStruct.maxDuration = n(1)
    _ = _MTRDeviceEnergyManagementClusterSlotStruct.maxDuration
    _MTRDeviceEnergyManagementClusterSlotStruct.maxDurationAdjustment = n(1)
    _ = _MTRDeviceEnergyManagementClusterSlotStruct.maxDurationAdjustment
    _MTRDeviceEnergyManagementClusterSlotStruct.maxPauseDuration = n(1)
    _ = _MTRDeviceEnergyManagementClusterSlotStruct.maxPauseDuration
    _MTRDeviceEnergyManagementClusterSlotStruct.maxPower = n(1)
    _ = _MTRDeviceEnergyManagementClusterSlotStruct.maxPower
    _MTRDeviceEnergyManagementClusterSlotStruct.maxPowerAdjustment = n(1)
    _ = _MTRDeviceEnergyManagementClusterSlotStruct.maxPowerAdjustment
    _MTRDeviceEnergyManagementClusterSlotStruct.minDuration = n(1)
    _ = _MTRDeviceEnergyManagementClusterSlotStruct.minDuration
    _MTRDeviceEnergyManagementClusterSlotStruct.minDurationAdjustment = n(1)
    _ = _MTRDeviceEnergyManagementClusterSlotStruct.minDurationAdjustment
    _MTRDeviceEnergyManagementClusterSlotStruct.minPauseDuration = n(1)
    _ = _MTRDeviceEnergyManagementClusterSlotStruct.minPauseDuration
    _MTRDeviceEnergyManagementClusterSlotStruct.minPower = n(1)
    _ = _MTRDeviceEnergyManagementClusterSlotStruct.minPower
    _MTRDeviceEnergyManagementClusterSlotStruct.minPowerAdjustment = n(1)
    _ = _MTRDeviceEnergyManagementClusterSlotStruct.minPowerAdjustment
    _MTRDeviceEnergyManagementClusterSlotStruct.nominalEnergy = n(1)
    _ = _MTRDeviceEnergyManagementClusterSlotStruct.nominalEnergy
    _MTRDeviceEnergyManagementClusterSlotStruct.nominalPower = n(1)
    _ = _MTRDeviceEnergyManagementClusterSlotStruct.nominalPower
    _MTRDeviceEnergyManagementClusterSlotStruct.remainingSlotTime = n(1)
    _ = _MTRDeviceEnergyManagementClusterSlotStruct.remainingSlotTime
    _MTRDeviceEnergyManagementClusterSlotStruct.slotIsPausable = n(1)
    _ = _MTRDeviceEnergyManagementClusterSlotStruct.slotIsPausable
    mtrRequire(_MTRDeviceEnergyManagementClusterSlotStruct.description.contains("MTRDeviceEnergyManagementClusterSlotStruct"), "MTRDeviceEnergyManagementClusterSlotStruct desc")
}

func testMTRDeviceEnergyManagementClusterStartTimeAdjustRequestParamsParamsWave11() {
    let _MTRDeviceEnergyManagementClusterStartTimeAdjustRequestParams = MTRDeviceEnergyManagementClusterStartTimeAdjustRequestParams()
    _MTRDeviceEnergyManagementClusterStartTimeAdjustRequestParams.cause = n(1)
    _ = _MTRDeviceEnergyManagementClusterStartTimeAdjustRequestParams.cause
    _MTRDeviceEnergyManagementClusterStartTimeAdjustRequestParams.requestedStartTime = n(1)
    _ = _MTRDeviceEnergyManagementClusterStartTimeAdjustRequestParams.requestedStartTime
    _MTRDeviceEnergyManagementClusterStartTimeAdjustRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDeviceEnergyManagementClusterStartTimeAdjustRequestParams.serverSideProcessingTimeout
    _MTRDeviceEnergyManagementClusterStartTimeAdjustRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDeviceEnergyManagementClusterStartTimeAdjustRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRDeviceEnergyManagementClusterStartTimeAdjustRequestParams.description.contains("MTRDeviceEnergyManagementClusterStartTimeAdjustRequestParams"), "MTRDeviceEnergyManagementClusterStartTimeAdjustRequestParams desc")
}

func testMTRDeviceEnergyManagementModeClusterChangeToModeParamsParamsWave11() {
    let _MTRDeviceEnergyManagementModeClusterChangeToModeParams = MTRDeviceEnergyManagementModeClusterChangeToModeParams()
    _MTRDeviceEnergyManagementModeClusterChangeToModeParams.newMode = n(1)
    _ = _MTRDeviceEnergyManagementModeClusterChangeToModeParams.newMode
    _MTRDeviceEnergyManagementModeClusterChangeToModeParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDeviceEnergyManagementModeClusterChangeToModeParams.serverSideProcessingTimeout
    _MTRDeviceEnergyManagementModeClusterChangeToModeParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDeviceEnergyManagementModeClusterChangeToModeParams.timedInvokeTimeoutMs
    mtrRequire(_MTRDeviceEnergyManagementModeClusterChangeToModeParams.description.contains("MTRDeviceEnergyManagementModeClusterChangeToModeParams"), "MTRDeviceEnergyManagementModeClusterChangeToModeParams desc")
}

func testMTRDeviceEnergyManagementModeClusterChangeToModeResponseParamsParamsWave11() {
    let _MTRDeviceEnergyManagementModeClusterChangeToModeResponseParams = (try? MTRDeviceEnergyManagementModeClusterChangeToModeResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRDeviceEnergyManagementModeClusterChangeToModeResponseParams()
    _MTRDeviceEnergyManagementModeClusterChangeToModeResponseParams.status = n(1)
    _ = _MTRDeviceEnergyManagementModeClusterChangeToModeResponseParams.status
    _MTRDeviceEnergyManagementModeClusterChangeToModeResponseParams.statusText = "x"
    _ = _MTRDeviceEnergyManagementModeClusterChangeToModeResponseParams.statusText
    mtrRequire(_MTRDeviceEnergyManagementModeClusterChangeToModeResponseParams.description.contains("MTRDeviceEnergyManagementModeClusterChangeToModeResponseParams"), "MTRDeviceEnergyManagementModeClusterChangeToModeResponseParams desc")
}

func testMTRDeviceEnergyManagementModeClusterModeOptionStructParamsWave11() {
    let _MTRDeviceEnergyManagementModeClusterModeOptionStruct = MTRDeviceEnergyManagementModeClusterModeOptionStruct()
    _MTRDeviceEnergyManagementModeClusterModeOptionStruct.label = "x"
    _ = _MTRDeviceEnergyManagementModeClusterModeOptionStruct.label
    _MTRDeviceEnergyManagementModeClusterModeOptionStruct.mode = n(1)
    _ = _MTRDeviceEnergyManagementModeClusterModeOptionStruct.mode
    _MTRDeviceEnergyManagementModeClusterModeOptionStruct.modeTags = [n(1)] as [Any]
    _ = _MTRDeviceEnergyManagementModeClusterModeOptionStruct.modeTags
    mtrRequire(_MTRDeviceEnergyManagementModeClusterModeOptionStruct.description.contains("MTRDeviceEnergyManagementModeClusterModeOptionStruct"), "MTRDeviceEnergyManagementModeClusterModeOptionStruct desc")
}

func testMTRDeviceEnergyManagementModeClusterModeTagStructParamsWave11() {
    let _MTRDeviceEnergyManagementModeClusterModeTagStruct = MTRDeviceEnergyManagementModeClusterModeTagStruct()
    _MTRDeviceEnergyManagementModeClusterModeTagStruct.mfgCode = n(1)
    _ = _MTRDeviceEnergyManagementModeClusterModeTagStruct.mfgCode
    _MTRDeviceEnergyManagementModeClusterModeTagStruct.value = n(1)
    _ = _MTRDeviceEnergyManagementModeClusterModeTagStruct.value
    mtrRequire(_MTRDeviceEnergyManagementModeClusterModeTagStruct.description.contains("MTRDeviceEnergyManagementModeClusterModeTagStruct"), "MTRDeviceEnergyManagementModeClusterModeTagStruct desc")
}

func testMTRDiagnosticLogsClusterRetrieveLogsRequestParamsParamsWave11() {
    let _MTRDiagnosticLogsClusterRetrieveLogsRequestParams = MTRDiagnosticLogsClusterRetrieveLogsRequestParams()
    _MTRDiagnosticLogsClusterRetrieveLogsRequestParams.intent = n(1)
    _ = _MTRDiagnosticLogsClusterRetrieveLogsRequestParams.intent
    _MTRDiagnosticLogsClusterRetrieveLogsRequestParams.requestedProtocol = n(1)
    _ = _MTRDiagnosticLogsClusterRetrieveLogsRequestParams.requestedProtocol
    _MTRDiagnosticLogsClusterRetrieveLogsRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDiagnosticLogsClusterRetrieveLogsRequestParams.serverSideProcessingTimeout
    _MTRDiagnosticLogsClusterRetrieveLogsRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDiagnosticLogsClusterRetrieveLogsRequestParams.timedInvokeTimeoutMs
    _MTRDiagnosticLogsClusterRetrieveLogsRequestParams.transferFileDesignator = "x"
    _ = _MTRDiagnosticLogsClusterRetrieveLogsRequestParams.transferFileDesignator
    mtrRequire(_MTRDiagnosticLogsClusterRetrieveLogsRequestParams.description.contains("MTRDiagnosticLogsClusterRetrieveLogsRequestParams"), "MTRDiagnosticLogsClusterRetrieveLogsRequestParams desc")
}

func testMTRDiagnosticLogsClusterRetrieveLogsResponseParamsParamsWave11() {
    let _MTRDiagnosticLogsClusterRetrieveLogsResponseParams = (try? MTRDiagnosticLogsClusterRetrieveLogsResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRDiagnosticLogsClusterRetrieveLogsResponseParams()
    _MTRDiagnosticLogsClusterRetrieveLogsResponseParams.content = Data([1])
    _ = _MTRDiagnosticLogsClusterRetrieveLogsResponseParams.content
    _MTRDiagnosticLogsClusterRetrieveLogsResponseParams.logContent = Data([1])
    _ = _MTRDiagnosticLogsClusterRetrieveLogsResponseParams.logContent
    _MTRDiagnosticLogsClusterRetrieveLogsResponseParams.status = n(1)
    _ = _MTRDiagnosticLogsClusterRetrieveLogsResponseParams.status
    _MTRDiagnosticLogsClusterRetrieveLogsResponseParams.timeSinceBoot = n(1)
    _ = _MTRDiagnosticLogsClusterRetrieveLogsResponseParams.timeSinceBoot
    _MTRDiagnosticLogsClusterRetrieveLogsResponseParams.timeStamp = n(1)
    _ = _MTRDiagnosticLogsClusterRetrieveLogsResponseParams.timeStamp
    _MTRDiagnosticLogsClusterRetrieveLogsResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDiagnosticLogsClusterRetrieveLogsResponseParams.timedInvokeTimeoutMs
    _MTRDiagnosticLogsClusterRetrieveLogsResponseParams.utcTimeStamp = n(1)
    _ = _MTRDiagnosticLogsClusterRetrieveLogsResponseParams.utcTimeStamp
    mtrRequire(_MTRDiagnosticLogsClusterRetrieveLogsResponseParams.description.contains("MTRDiagnosticLogsClusterRetrieveLogsResponseParams"), "MTRDiagnosticLogsClusterRetrieveLogsResponseParams desc")
}

func testMTRDishwasherAlarmClusterModifyEnabledAlarmsParamsParamsWave11() {
    let _MTRDishwasherAlarmClusterModifyEnabledAlarmsParams = MTRDishwasherAlarmClusterModifyEnabledAlarmsParams()
    _MTRDishwasherAlarmClusterModifyEnabledAlarmsParams.mask = n(1)
    _ = _MTRDishwasherAlarmClusterModifyEnabledAlarmsParams.mask
    _MTRDishwasherAlarmClusterModifyEnabledAlarmsParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDishwasherAlarmClusterModifyEnabledAlarmsParams.serverSideProcessingTimeout
    _MTRDishwasherAlarmClusterModifyEnabledAlarmsParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDishwasherAlarmClusterModifyEnabledAlarmsParams.timedInvokeTimeoutMs
    mtrRequire(_MTRDishwasherAlarmClusterModifyEnabledAlarmsParams.description.contains("MTRDishwasherAlarmClusterModifyEnabledAlarmsParams"), "MTRDishwasherAlarmClusterModifyEnabledAlarmsParams desc")
}

func testMTRDishwasherAlarmClusterNotifyEventParamsWave11() {
    let _MTRDishwasherAlarmClusterNotifyEvent = MTRDishwasherAlarmClusterNotifyEvent()
    _MTRDishwasherAlarmClusterNotifyEvent.active = n(1)
    _ = _MTRDishwasherAlarmClusterNotifyEvent.active
    _MTRDishwasherAlarmClusterNotifyEvent.inactive = n(1)
    _ = _MTRDishwasherAlarmClusterNotifyEvent.inactive
    _MTRDishwasherAlarmClusterNotifyEvent.mask = n(1)
    _ = _MTRDishwasherAlarmClusterNotifyEvent.mask
    _MTRDishwasherAlarmClusterNotifyEvent.state = n(1)
    _ = _MTRDishwasherAlarmClusterNotifyEvent.state
    mtrRequire(_MTRDishwasherAlarmClusterNotifyEvent.description.contains("MTRDishwasherAlarmClusterNotifyEvent"), "MTRDishwasherAlarmClusterNotifyEvent desc")
}

func testMTRDishwasherAlarmClusterResetParamsParamsWave11() {
    let _MTRDishwasherAlarmClusterResetParams = MTRDishwasherAlarmClusterResetParams()
    _MTRDishwasherAlarmClusterResetParams.alarms = n(1)
    _ = _MTRDishwasherAlarmClusterResetParams.alarms
    _MTRDishwasherAlarmClusterResetParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDishwasherAlarmClusterResetParams.serverSideProcessingTimeout
    _MTRDishwasherAlarmClusterResetParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDishwasherAlarmClusterResetParams.timedInvokeTimeoutMs
    mtrRequire(_MTRDishwasherAlarmClusterResetParams.description.contains("MTRDishwasherAlarmClusterResetParams"), "MTRDishwasherAlarmClusterResetParams desc")
}

func testMTRDishwasherModeClusterChangeToModeParamsParamsWave11() {
    let _MTRDishwasherModeClusterChangeToModeParams = MTRDishwasherModeClusterChangeToModeParams()
    _MTRDishwasherModeClusterChangeToModeParams.newMode = n(1)
    _ = _MTRDishwasherModeClusterChangeToModeParams.newMode
    _MTRDishwasherModeClusterChangeToModeParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDishwasherModeClusterChangeToModeParams.serverSideProcessingTimeout
    _MTRDishwasherModeClusterChangeToModeParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDishwasherModeClusterChangeToModeParams.timedInvokeTimeoutMs
    mtrRequire(_MTRDishwasherModeClusterChangeToModeParams.description.contains("MTRDishwasherModeClusterChangeToModeParams"), "MTRDishwasherModeClusterChangeToModeParams desc")
}

func testMTRDishwasherModeClusterChangeToModeResponseParamsParamsWave11() {
    let _MTRDishwasherModeClusterChangeToModeResponseParams = (try? MTRDishwasherModeClusterChangeToModeResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRDishwasherModeClusterChangeToModeResponseParams()
    _MTRDishwasherModeClusterChangeToModeResponseParams.status = n(1)
    _ = _MTRDishwasherModeClusterChangeToModeResponseParams.status
    _MTRDishwasherModeClusterChangeToModeResponseParams.statusText = "x"
    _ = _MTRDishwasherModeClusterChangeToModeResponseParams.statusText
    mtrRequire(_MTRDishwasherModeClusterChangeToModeResponseParams.description.contains("MTRDishwasherModeClusterChangeToModeResponseParams"), "MTRDishwasherModeClusterChangeToModeResponseParams desc")
}

func testMTRDishwasherModeClusterModeOptionStructParamsWave11() {
    let _MTRDishwasherModeClusterModeOptionStruct = MTRDishwasherModeClusterModeOptionStruct()
    _MTRDishwasherModeClusterModeOptionStruct.label = "x"
    _ = _MTRDishwasherModeClusterModeOptionStruct.label
    _MTRDishwasherModeClusterModeOptionStruct.mode = n(1)
    _ = _MTRDishwasherModeClusterModeOptionStruct.mode
    _MTRDishwasherModeClusterModeOptionStruct.modeTags = [n(1)] as [Any]
    _ = _MTRDishwasherModeClusterModeOptionStruct.modeTags
    mtrRequire(_MTRDishwasherModeClusterModeOptionStruct.description.contains("MTRDishwasherModeClusterModeOptionStruct"), "MTRDishwasherModeClusterModeOptionStruct desc")
}

func testMTRDishwasherModeClusterModeTagStructParamsWave11() {
    let _MTRDishwasherModeClusterModeTagStruct = MTRDishwasherModeClusterModeTagStruct()
    _MTRDishwasherModeClusterModeTagStruct.mfgCode = n(1)
    _ = _MTRDishwasherModeClusterModeTagStruct.mfgCode
    _MTRDishwasherModeClusterModeTagStruct.value = n(1)
    _ = _MTRDishwasherModeClusterModeTagStruct.value
    mtrRequire(_MTRDishwasherModeClusterModeTagStruct.description.contains("MTRDishwasherModeClusterModeTagStruct"), "MTRDishwasherModeClusterModeTagStruct desc")
}

