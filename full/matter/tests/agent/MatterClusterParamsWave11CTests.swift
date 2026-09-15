import Foundation
import Dispatch
import Matter

func testMTRElectricalEnergyMeasurementClusterCumulativeEnergyMeasuredEventParamsWave11() {
    let _MTRElectricalEnergyMeasurementClusterCumulativeEnergyMeasuredEvent = MTRElectricalEnergyMeasurementClusterCumulativeEnergyMeasuredEvent()
    _MTRElectricalEnergyMeasurementClusterCumulativeEnergyMeasuredEvent.energyExported = MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct()
    _ = _MTRElectricalEnergyMeasurementClusterCumulativeEnergyMeasuredEvent.energyExported
    _MTRElectricalEnergyMeasurementClusterCumulativeEnergyMeasuredEvent.energyImported = MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct()
    _ = _MTRElectricalEnergyMeasurementClusterCumulativeEnergyMeasuredEvent.energyImported
    mtrRequire(_MTRElectricalEnergyMeasurementClusterCumulativeEnergyMeasuredEvent.description.contains("MTRElectricalEnergyMeasurementClusterCumulativeEnergyMeasuredEvent"), "MTRElectricalEnergyMeasurementClusterCumulativeEnergyMeasuredEvent desc")
}

func testMTRElectricalEnergyMeasurementClusterCumulativeEnergyResetStructParamsWave11() {
    let _MTRElectricalEnergyMeasurementClusterCumulativeEnergyResetStruct = MTRElectricalEnergyMeasurementClusterCumulativeEnergyResetStruct()
    _MTRElectricalEnergyMeasurementClusterCumulativeEnergyResetStruct.exportedResetSystime = n(1)
    _ = _MTRElectricalEnergyMeasurementClusterCumulativeEnergyResetStruct.exportedResetSystime
    _MTRElectricalEnergyMeasurementClusterCumulativeEnergyResetStruct.exportedResetTimestamp = n(1)
    _ = _MTRElectricalEnergyMeasurementClusterCumulativeEnergyResetStruct.exportedResetTimestamp
    _MTRElectricalEnergyMeasurementClusterCumulativeEnergyResetStruct.importedResetSystime = n(1)
    _ = _MTRElectricalEnergyMeasurementClusterCumulativeEnergyResetStruct.importedResetSystime
    _MTRElectricalEnergyMeasurementClusterCumulativeEnergyResetStruct.importedResetTimestamp = n(1)
    _ = _MTRElectricalEnergyMeasurementClusterCumulativeEnergyResetStruct.importedResetTimestamp
    mtrRequire(_MTRElectricalEnergyMeasurementClusterCumulativeEnergyResetStruct.description.contains("MTRElectricalEnergyMeasurementClusterCumulativeEnergyResetStruct"), "MTRElectricalEnergyMeasurementClusterCumulativeEnergyResetStruct desc")
}

func testMTRElectricalEnergyMeasurementClusterEnergyMeasurementStructParamsWave11() {
    let _MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct = MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct()
    _MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct.endSystime = n(1)
    _ = _MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct.endSystime
    _MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct.endTimestamp = n(1)
    _ = _MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct.endTimestamp
    _MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct.energy = n(1)
    _ = _MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct.energy
    _MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct.startSystime = n(1)
    _ = _MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct.startSystime
    _MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct.startTimestamp = n(1)
    _ = _MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct.startTimestamp
    mtrRequire(_MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct.description.contains("MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct"), "MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct desc")
}

func testMTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStructParamsWave11() {
    let _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStruct = MTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStruct()
    _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStruct.fixedMax = n(1)
    _ = _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStruct.fixedMax
    _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStruct.fixedMin = n(1)
    _ = _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStruct.fixedMin
    _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStruct.fixedTypical = n(1)
    _ = _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStruct.fixedTypical
    _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStruct.percentMax = n(1)
    _ = _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStruct.percentMax
    _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStruct.percentMin = n(1)
    _ = _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStruct.percentMin
    _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStruct.percentTypical = n(1)
    _ = _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStruct.percentTypical
    _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStruct.rangeMax = n(1)
    _ = _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStruct.rangeMax
    _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStruct.rangeMin = n(1)
    _ = _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStruct.rangeMin
    mtrRequire(_MTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStruct.description.contains("MTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStruct"), "MTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStruct desc")
}

func testMTRElectricalEnergyMeasurementClusterMeasurementAccuracyStructParamsWave11() {
    let _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyStruct = MTRElectricalEnergyMeasurementClusterMeasurementAccuracyStruct()
    _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyStruct.accuracyRanges = [n(1)] as [Any]
    _ = _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyStruct.accuracyRanges
    _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyStruct.maxMeasuredValue = n(1)
    _ = _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyStruct.maxMeasuredValue
    _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyStruct.measured = n(1)
    _ = _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyStruct.measured
    _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyStruct.measurementType = n(1)
    _ = _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyStruct.measurementType
    _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyStruct.minMeasuredValue = n(1)
    _ = _MTRElectricalEnergyMeasurementClusterMeasurementAccuracyStruct.minMeasuredValue
    mtrRequire(_MTRElectricalEnergyMeasurementClusterMeasurementAccuracyStruct.description.contains("MTRElectricalEnergyMeasurementClusterMeasurementAccuracyStruct"), "MTRElectricalEnergyMeasurementClusterMeasurementAccuracyStruct desc")
}

func testMTRElectricalEnergyMeasurementClusterPeriodicEnergyMeasuredEventParamsWave11() {
    let _MTRElectricalEnergyMeasurementClusterPeriodicEnergyMeasuredEvent = MTRElectricalEnergyMeasurementClusterPeriodicEnergyMeasuredEvent()
    _MTRElectricalEnergyMeasurementClusterPeriodicEnergyMeasuredEvent.energyExported = MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct()
    _ = _MTRElectricalEnergyMeasurementClusterPeriodicEnergyMeasuredEvent.energyExported
    _MTRElectricalEnergyMeasurementClusterPeriodicEnergyMeasuredEvent.energyImported = MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct()
    _ = _MTRElectricalEnergyMeasurementClusterPeriodicEnergyMeasuredEvent.energyImported
    mtrRequire(_MTRElectricalEnergyMeasurementClusterPeriodicEnergyMeasuredEvent.description.contains("MTRElectricalEnergyMeasurementClusterPeriodicEnergyMeasuredEvent"), "MTRElectricalEnergyMeasurementClusterPeriodicEnergyMeasuredEvent desc")
}

func testMTRElectricalPowerMeasurementClusterHarmonicMeasurementStructParamsWave11() {
    let _MTRElectricalPowerMeasurementClusterHarmonicMeasurementStruct = MTRElectricalPowerMeasurementClusterHarmonicMeasurementStruct()
    _MTRElectricalPowerMeasurementClusterHarmonicMeasurementStruct.measurement = n(1)
    _ = _MTRElectricalPowerMeasurementClusterHarmonicMeasurementStruct.measurement
    _MTRElectricalPowerMeasurementClusterHarmonicMeasurementStruct.order = n(1)
    _ = _MTRElectricalPowerMeasurementClusterHarmonicMeasurementStruct.order
    mtrRequire(_MTRElectricalPowerMeasurementClusterHarmonicMeasurementStruct.description.contains("MTRElectricalPowerMeasurementClusterHarmonicMeasurementStruct"), "MTRElectricalPowerMeasurementClusterHarmonicMeasurementStruct desc")
}

func testMTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStructParamsWave11() {
    let _MTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStruct = MTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStruct()
    _MTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStruct.fixedMax = n(1)
    _ = _MTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStruct.fixedMax
    _MTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStruct.fixedMin = n(1)
    _ = _MTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStruct.fixedMin
    _MTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStruct.fixedTypical = n(1)
    _ = _MTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStruct.fixedTypical
    _MTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStruct.percentMax = n(1)
    _ = _MTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStruct.percentMax
    _MTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStruct.percentMin = n(1)
    _ = _MTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStruct.percentMin
    _MTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStruct.percentTypical = n(1)
    _ = _MTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStruct.percentTypical
    _MTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStruct.rangeMax = n(1)
    _ = _MTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStruct.rangeMax
    _MTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStruct.rangeMin = n(1)
    _ = _MTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStruct.rangeMin
    mtrRequire(_MTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStruct.description.contains("MTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStruct"), "MTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStruct desc")
}

func testMTRElectricalPowerMeasurementClusterMeasurementAccuracyStructParamsWave11() {
    let _MTRElectricalPowerMeasurementClusterMeasurementAccuracyStruct = MTRElectricalPowerMeasurementClusterMeasurementAccuracyStruct()
    _MTRElectricalPowerMeasurementClusterMeasurementAccuracyStruct.accuracyRanges = [n(1)] as [Any]
    _ = _MTRElectricalPowerMeasurementClusterMeasurementAccuracyStruct.accuracyRanges
    _MTRElectricalPowerMeasurementClusterMeasurementAccuracyStruct.maxMeasuredValue = n(1)
    _ = _MTRElectricalPowerMeasurementClusterMeasurementAccuracyStruct.maxMeasuredValue
    _MTRElectricalPowerMeasurementClusterMeasurementAccuracyStruct.measured = n(1)
    _ = _MTRElectricalPowerMeasurementClusterMeasurementAccuracyStruct.measured
    _MTRElectricalPowerMeasurementClusterMeasurementAccuracyStruct.measurementType = n(1)
    _ = _MTRElectricalPowerMeasurementClusterMeasurementAccuracyStruct.measurementType
    _MTRElectricalPowerMeasurementClusterMeasurementAccuracyStruct.minMeasuredValue = n(1)
    _ = _MTRElectricalPowerMeasurementClusterMeasurementAccuracyStruct.minMeasuredValue
    mtrRequire(_MTRElectricalPowerMeasurementClusterMeasurementAccuracyStruct.description.contains("MTRElectricalPowerMeasurementClusterMeasurementAccuracyStruct"), "MTRElectricalPowerMeasurementClusterMeasurementAccuracyStruct desc")
}

func testMTRElectricalPowerMeasurementClusterMeasurementPeriodRangesEventParamsWave11() {
    let _MTRElectricalPowerMeasurementClusterMeasurementPeriodRangesEvent = MTRElectricalPowerMeasurementClusterMeasurementPeriodRangesEvent()
    _MTRElectricalPowerMeasurementClusterMeasurementPeriodRangesEvent.ranges = [n(1)] as [Any]
    _ = _MTRElectricalPowerMeasurementClusterMeasurementPeriodRangesEvent.ranges
    mtrRequire(_MTRElectricalPowerMeasurementClusterMeasurementPeriodRangesEvent.description.contains("MTRElectricalPowerMeasurementClusterMeasurementPeriodRangesEvent"), "MTRElectricalPowerMeasurementClusterMeasurementPeriodRangesEvent desc")
}

func testMTRElectricalPowerMeasurementClusterMeasurementRangeStructParamsWave11() {
    let _MTRElectricalPowerMeasurementClusterMeasurementRangeStruct = MTRElectricalPowerMeasurementClusterMeasurementRangeStruct()
    _MTRElectricalPowerMeasurementClusterMeasurementRangeStruct.endSystime = n(1)
    _ = _MTRElectricalPowerMeasurementClusterMeasurementRangeStruct.endSystime
    _MTRElectricalPowerMeasurementClusterMeasurementRangeStruct.endTimestamp = n(1)
    _ = _MTRElectricalPowerMeasurementClusterMeasurementRangeStruct.endTimestamp
    _MTRElectricalPowerMeasurementClusterMeasurementRangeStruct.max = n(1)
    _ = _MTRElectricalPowerMeasurementClusterMeasurementRangeStruct.max
    _MTRElectricalPowerMeasurementClusterMeasurementRangeStruct.maxSystime = n(1)
    _ = _MTRElectricalPowerMeasurementClusterMeasurementRangeStruct.maxSystime
    _MTRElectricalPowerMeasurementClusterMeasurementRangeStruct.maxTimestamp = n(1)
    _ = _MTRElectricalPowerMeasurementClusterMeasurementRangeStruct.maxTimestamp
    _MTRElectricalPowerMeasurementClusterMeasurementRangeStruct.measurementType = n(1)
    _ = _MTRElectricalPowerMeasurementClusterMeasurementRangeStruct.measurementType
    _MTRElectricalPowerMeasurementClusterMeasurementRangeStruct.min = n(1)
    _ = _MTRElectricalPowerMeasurementClusterMeasurementRangeStruct.min
    _MTRElectricalPowerMeasurementClusterMeasurementRangeStruct.minSystime = n(1)
    _ = _MTRElectricalPowerMeasurementClusterMeasurementRangeStruct.minSystime
    _MTRElectricalPowerMeasurementClusterMeasurementRangeStruct.minTimestamp = n(1)
    _ = _MTRElectricalPowerMeasurementClusterMeasurementRangeStruct.minTimestamp
    _MTRElectricalPowerMeasurementClusterMeasurementRangeStruct.startSystime = n(1)
    _ = _MTRElectricalPowerMeasurementClusterMeasurementRangeStruct.startSystime
    _MTRElectricalPowerMeasurementClusterMeasurementRangeStruct.startTimestamp = n(1)
    _ = _MTRElectricalPowerMeasurementClusterMeasurementRangeStruct.startTimestamp
    mtrRequire(_MTRElectricalPowerMeasurementClusterMeasurementRangeStruct.description.contains("MTRElectricalPowerMeasurementClusterMeasurementRangeStruct"), "MTRElectricalPowerMeasurementClusterMeasurementRangeStruct desc")
}

func testMTREnergyEVSEClusterChargingTargetScheduleStructParamsWave11() {
    let _MTREnergyEVSEClusterChargingTargetScheduleStruct = MTREnergyEVSEClusterChargingTargetScheduleStruct()
    _MTREnergyEVSEClusterChargingTargetScheduleStruct.chargingTargets = [n(1)] as [Any]
    _ = _MTREnergyEVSEClusterChargingTargetScheduleStruct.chargingTargets
    _MTREnergyEVSEClusterChargingTargetScheduleStruct.dayOfWeekForSequence = n(1)
    _ = _MTREnergyEVSEClusterChargingTargetScheduleStruct.dayOfWeekForSequence
    mtrRequire(_MTREnergyEVSEClusterChargingTargetScheduleStruct.description.contains("MTREnergyEVSEClusterChargingTargetScheduleStruct"), "MTREnergyEVSEClusterChargingTargetScheduleStruct desc")
}

func testMTREnergyEVSEClusterChargingTargetStructParamsWave11() {
    let _MTREnergyEVSEClusterChargingTargetStruct = MTREnergyEVSEClusterChargingTargetStruct()
    _MTREnergyEVSEClusterChargingTargetStruct.addedEnergy = n(1)
    _ = _MTREnergyEVSEClusterChargingTargetStruct.addedEnergy
    _MTREnergyEVSEClusterChargingTargetStruct.targetSoC = n(1)
    _ = _MTREnergyEVSEClusterChargingTargetStruct.targetSoC
    _MTREnergyEVSEClusterChargingTargetStruct.targetTimeMinutesPastMidnight = n(1)
    _ = _MTREnergyEVSEClusterChargingTargetStruct.targetTimeMinutesPastMidnight
    mtrRequire(_MTREnergyEVSEClusterChargingTargetStruct.description.contains("MTREnergyEVSEClusterChargingTargetStruct"), "MTREnergyEVSEClusterChargingTargetStruct desc")
}

func testMTREnergyEVSEClusterClearTargetsParamsParamsWave11() {
    let _MTREnergyEVSEClusterClearTargetsParams = MTREnergyEVSEClusterClearTargetsParams()
    _MTREnergyEVSEClusterClearTargetsParams.serverSideProcessingTimeout = n(1)
    _ = _MTREnergyEVSEClusterClearTargetsParams.serverSideProcessingTimeout
    _MTREnergyEVSEClusterClearTargetsParams.timedInvokeTimeoutMs = n(1)
    _ = _MTREnergyEVSEClusterClearTargetsParams.timedInvokeTimeoutMs
    mtrRequire(_MTREnergyEVSEClusterClearTargetsParams.description.contains("MTREnergyEVSEClusterClearTargetsParams"), "MTREnergyEVSEClusterClearTargetsParams desc")
}

func testMTREnergyEVSEClusterDisableParamsParamsWave11() {
    let _MTREnergyEVSEClusterDisableParams = MTREnergyEVSEClusterDisableParams()
    _MTREnergyEVSEClusterDisableParams.serverSideProcessingTimeout = n(1)
    _ = _MTREnergyEVSEClusterDisableParams.serverSideProcessingTimeout
    _MTREnergyEVSEClusterDisableParams.timedInvokeTimeoutMs = n(1)
    _ = _MTREnergyEVSEClusterDisableParams.timedInvokeTimeoutMs
    mtrRequire(_MTREnergyEVSEClusterDisableParams.description.contains("MTREnergyEVSEClusterDisableParams"), "MTREnergyEVSEClusterDisableParams desc")
}

func testMTREnergyEVSEClusterEVConnectedEventParamsWave11() {
    let _MTREnergyEVSEClusterEVConnectedEvent = MTREnergyEVSEClusterEVConnectedEvent()
    _MTREnergyEVSEClusterEVConnectedEvent.sessionID = n(1)
    _ = _MTREnergyEVSEClusterEVConnectedEvent.sessionID
    mtrRequire(_MTREnergyEVSEClusterEVConnectedEvent.description.contains("MTREnergyEVSEClusterEVConnectedEvent"), "MTREnergyEVSEClusterEVConnectedEvent desc")
}

func testMTREnergyEVSEClusterEVNotDetectedEventParamsWave11() {
    let _MTREnergyEVSEClusterEVNotDetectedEvent = MTREnergyEVSEClusterEVNotDetectedEvent()
    _MTREnergyEVSEClusterEVNotDetectedEvent.sessionDuration = n(1)
    _ = _MTREnergyEVSEClusterEVNotDetectedEvent.sessionDuration
    _MTREnergyEVSEClusterEVNotDetectedEvent.sessionEnergyCharged = n(1)
    _ = _MTREnergyEVSEClusterEVNotDetectedEvent.sessionEnergyCharged
    _MTREnergyEVSEClusterEVNotDetectedEvent.sessionID = n(1)
    _ = _MTREnergyEVSEClusterEVNotDetectedEvent.sessionID
    _MTREnergyEVSEClusterEVNotDetectedEvent.state = n(1)
    _ = _MTREnergyEVSEClusterEVNotDetectedEvent.state
    mtrRequire(_MTREnergyEVSEClusterEVNotDetectedEvent.description.contains("MTREnergyEVSEClusterEVNotDetectedEvent"), "MTREnergyEVSEClusterEVNotDetectedEvent desc")
}

func testMTREnergyEVSEClusterEnableChargingParamsParamsWave11() {
    let _MTREnergyEVSEClusterEnableChargingParams = MTREnergyEVSEClusterEnableChargingParams()
    _MTREnergyEVSEClusterEnableChargingParams.chargingEnabledUntil = n(1)
    _ = _MTREnergyEVSEClusterEnableChargingParams.chargingEnabledUntil
    _MTREnergyEVSEClusterEnableChargingParams.maximumChargeCurrent = n(1)
    _ = _MTREnergyEVSEClusterEnableChargingParams.maximumChargeCurrent
    _MTREnergyEVSEClusterEnableChargingParams.minimumChargeCurrent = n(1)
    _ = _MTREnergyEVSEClusterEnableChargingParams.minimumChargeCurrent
    _MTREnergyEVSEClusterEnableChargingParams.serverSideProcessingTimeout = n(1)
    _ = _MTREnergyEVSEClusterEnableChargingParams.serverSideProcessingTimeout
    _MTREnergyEVSEClusterEnableChargingParams.timedInvokeTimeoutMs = n(1)
    _ = _MTREnergyEVSEClusterEnableChargingParams.timedInvokeTimeoutMs
    mtrRequire(_MTREnergyEVSEClusterEnableChargingParams.description.contains("MTREnergyEVSEClusterEnableChargingParams"), "MTREnergyEVSEClusterEnableChargingParams desc")
}

func testMTREnergyEVSEClusterEnergyTransferStartedEventParamsWave11() {
    let _MTREnergyEVSEClusterEnergyTransferStartedEvent = MTREnergyEVSEClusterEnergyTransferStartedEvent()
    _MTREnergyEVSEClusterEnergyTransferStartedEvent.maximumCurrent = n(1)
    _ = _MTREnergyEVSEClusterEnergyTransferStartedEvent.maximumCurrent
    _MTREnergyEVSEClusterEnergyTransferStartedEvent.sessionID = n(1)
    _ = _MTREnergyEVSEClusterEnergyTransferStartedEvent.sessionID
    _MTREnergyEVSEClusterEnergyTransferStartedEvent.state = n(1)
    _ = _MTREnergyEVSEClusterEnergyTransferStartedEvent.state
    mtrRequire(_MTREnergyEVSEClusterEnergyTransferStartedEvent.description.contains("MTREnergyEVSEClusterEnergyTransferStartedEvent"), "MTREnergyEVSEClusterEnergyTransferStartedEvent desc")
}

func testMTREnergyEVSEClusterEnergyTransferStoppedEventParamsWave11() {
    let _MTREnergyEVSEClusterEnergyTransferStoppedEvent = MTREnergyEVSEClusterEnergyTransferStoppedEvent()
    _MTREnergyEVSEClusterEnergyTransferStoppedEvent.energyTransferred = n(1)
    _ = _MTREnergyEVSEClusterEnergyTransferStoppedEvent.energyTransferred
    _MTREnergyEVSEClusterEnergyTransferStoppedEvent.reason = n(1)
    _ = _MTREnergyEVSEClusterEnergyTransferStoppedEvent.reason
    _MTREnergyEVSEClusterEnergyTransferStoppedEvent.sessionID = n(1)
    _ = _MTREnergyEVSEClusterEnergyTransferStoppedEvent.sessionID
    _MTREnergyEVSEClusterEnergyTransferStoppedEvent.state = n(1)
    _ = _MTREnergyEVSEClusterEnergyTransferStoppedEvent.state
    mtrRequire(_MTREnergyEVSEClusterEnergyTransferStoppedEvent.description.contains("MTREnergyEVSEClusterEnergyTransferStoppedEvent"), "MTREnergyEVSEClusterEnergyTransferStoppedEvent desc")
}

func testMTREnergyEVSEClusterFaultEventParamsWave11() {
    let _MTREnergyEVSEClusterFaultEvent = MTREnergyEVSEClusterFaultEvent()
    _MTREnergyEVSEClusterFaultEvent.faultStateCurrentState = n(1)
    _ = _MTREnergyEVSEClusterFaultEvent.faultStateCurrentState
    _MTREnergyEVSEClusterFaultEvent.faultStatePreviousState = n(1)
    _ = _MTREnergyEVSEClusterFaultEvent.faultStatePreviousState
    _MTREnergyEVSEClusterFaultEvent.sessionID = n(1)
    _ = _MTREnergyEVSEClusterFaultEvent.sessionID
    _MTREnergyEVSEClusterFaultEvent.state = n(1)
    _ = _MTREnergyEVSEClusterFaultEvent.state
    mtrRequire(_MTREnergyEVSEClusterFaultEvent.description.contains("MTREnergyEVSEClusterFaultEvent"), "MTREnergyEVSEClusterFaultEvent desc")
}

func testMTREnergyEVSEClusterGetTargetsParamsParamsWave11() {
    let _MTREnergyEVSEClusterGetTargetsParams = MTREnergyEVSEClusterGetTargetsParams()
    _MTREnergyEVSEClusterGetTargetsParams.serverSideProcessingTimeout = n(1)
    _ = _MTREnergyEVSEClusterGetTargetsParams.serverSideProcessingTimeout
    _MTREnergyEVSEClusterGetTargetsParams.timedInvokeTimeoutMs = n(1)
    _ = _MTREnergyEVSEClusterGetTargetsParams.timedInvokeTimeoutMs
    mtrRequire(_MTREnergyEVSEClusterGetTargetsParams.description.contains("MTREnergyEVSEClusterGetTargetsParams"), "MTREnergyEVSEClusterGetTargetsParams desc")
}

func testMTREnergyEVSEClusterGetTargetsResponseParamsParamsWave11() {
    let _MTREnergyEVSEClusterGetTargetsResponseParams = (try? MTREnergyEVSEClusterGetTargetsResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTREnergyEVSEClusterGetTargetsResponseParams()
    _MTREnergyEVSEClusterGetTargetsResponseParams.chargingTargetSchedules = [n(1)] as [Any]
    _ = _MTREnergyEVSEClusterGetTargetsResponseParams.chargingTargetSchedules
    mtrRequire(_MTREnergyEVSEClusterGetTargetsResponseParams.description.contains("MTREnergyEVSEClusterGetTargetsResponseParams"), "MTREnergyEVSEClusterGetTargetsResponseParams desc")
}

func testMTREnergyEVSEClusterRFIDEventParamsWave11() {
    let _MTREnergyEVSEClusterRFIDEvent = MTREnergyEVSEClusterRFIDEvent()
    _MTREnergyEVSEClusterRFIDEvent.uid = Data([1])
    _ = _MTREnergyEVSEClusterRFIDEvent.uid
    mtrRequire(_MTREnergyEVSEClusterRFIDEvent.description.contains("MTREnergyEVSEClusterRFIDEvent"), "MTREnergyEVSEClusterRFIDEvent desc")
}

func testMTREnergyEVSEClusterSetTargetsParamsParamsWave11() {
    let _MTREnergyEVSEClusterSetTargetsParams = MTREnergyEVSEClusterSetTargetsParams()
    _MTREnergyEVSEClusterSetTargetsParams.chargingTargetSchedules = [n(1)] as [Any]
    _ = _MTREnergyEVSEClusterSetTargetsParams.chargingTargetSchedules
    _MTREnergyEVSEClusterSetTargetsParams.serverSideProcessingTimeout = n(1)
    _ = _MTREnergyEVSEClusterSetTargetsParams.serverSideProcessingTimeout
    _MTREnergyEVSEClusterSetTargetsParams.timedInvokeTimeoutMs = n(1)
    _ = _MTREnergyEVSEClusterSetTargetsParams.timedInvokeTimeoutMs
    mtrRequire(_MTREnergyEVSEClusterSetTargetsParams.description.contains("MTREnergyEVSEClusterSetTargetsParams"), "MTREnergyEVSEClusterSetTargetsParams desc")
}

func testMTREnergyEVSEClusterStartDiagnosticsParamsParamsWave11() {
    let _MTREnergyEVSEClusterStartDiagnosticsParams = MTREnergyEVSEClusterStartDiagnosticsParams()
    _MTREnergyEVSEClusterStartDiagnosticsParams.serverSideProcessingTimeout = n(1)
    _ = _MTREnergyEVSEClusterStartDiagnosticsParams.serverSideProcessingTimeout
    _MTREnergyEVSEClusterStartDiagnosticsParams.timedInvokeTimeoutMs = n(1)
    _ = _MTREnergyEVSEClusterStartDiagnosticsParams.timedInvokeTimeoutMs
    mtrRequire(_MTREnergyEVSEClusterStartDiagnosticsParams.description.contains("MTREnergyEVSEClusterStartDiagnosticsParams"), "MTREnergyEVSEClusterStartDiagnosticsParams desc")
}

func testMTREnergyEVSEModeClusterChangeToModeParamsParamsWave11() {
    let _MTREnergyEVSEModeClusterChangeToModeParams = MTREnergyEVSEModeClusterChangeToModeParams()
    _MTREnergyEVSEModeClusterChangeToModeParams.newMode = n(1)
    _ = _MTREnergyEVSEModeClusterChangeToModeParams.newMode
    _MTREnergyEVSEModeClusterChangeToModeParams.serverSideProcessingTimeout = n(1)
    _ = _MTREnergyEVSEModeClusterChangeToModeParams.serverSideProcessingTimeout
    _MTREnergyEVSEModeClusterChangeToModeParams.timedInvokeTimeoutMs = n(1)
    _ = _MTREnergyEVSEModeClusterChangeToModeParams.timedInvokeTimeoutMs
    mtrRequire(_MTREnergyEVSEModeClusterChangeToModeParams.description.contains("MTREnergyEVSEModeClusterChangeToModeParams"), "MTREnergyEVSEModeClusterChangeToModeParams desc")
}

func testMTREnergyEVSEModeClusterChangeToModeResponseParamsParamsWave11() {
    let _MTREnergyEVSEModeClusterChangeToModeResponseParams = (try? MTREnergyEVSEModeClusterChangeToModeResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTREnergyEVSEModeClusterChangeToModeResponseParams()
    _MTREnergyEVSEModeClusterChangeToModeResponseParams.status = n(1)
    _ = _MTREnergyEVSEModeClusterChangeToModeResponseParams.status
    _MTREnergyEVSEModeClusterChangeToModeResponseParams.statusText = "x"
    _ = _MTREnergyEVSEModeClusterChangeToModeResponseParams.statusText
    mtrRequire(_MTREnergyEVSEModeClusterChangeToModeResponseParams.description.contains("MTREnergyEVSEModeClusterChangeToModeResponseParams"), "MTREnergyEVSEModeClusterChangeToModeResponseParams desc")
}

func testMTREnergyEVSEModeClusterModeOptionStructParamsWave11() {
    let _MTREnergyEVSEModeClusterModeOptionStruct = MTREnergyEVSEModeClusterModeOptionStruct()
    _MTREnergyEVSEModeClusterModeOptionStruct.label = "x"
    _ = _MTREnergyEVSEModeClusterModeOptionStruct.label
    _MTREnergyEVSEModeClusterModeOptionStruct.mode = n(1)
    _ = _MTREnergyEVSEModeClusterModeOptionStruct.mode
    _MTREnergyEVSEModeClusterModeOptionStruct.modeTags = [n(1)] as [Any]
    _ = _MTREnergyEVSEModeClusterModeOptionStruct.modeTags
    mtrRequire(_MTREnergyEVSEModeClusterModeOptionStruct.description.contains("MTREnergyEVSEModeClusterModeOptionStruct"), "MTREnergyEVSEModeClusterModeOptionStruct desc")
}

func testMTREnergyEVSEModeClusterModeTagStructParamsWave11() {
    let _MTREnergyEVSEModeClusterModeTagStruct = MTREnergyEVSEModeClusterModeTagStruct()
    _MTREnergyEVSEModeClusterModeTagStruct.mfgCode = n(1)
    _ = _MTREnergyEVSEModeClusterModeTagStruct.mfgCode
    _MTREnergyEVSEModeClusterModeTagStruct.value = n(1)
    _ = _MTREnergyEVSEModeClusterModeTagStruct.value
    mtrRequire(_MTREnergyEVSEModeClusterModeTagStruct.description.contains("MTREnergyEVSEModeClusterModeTagStruct"), "MTREnergyEVSEModeClusterModeTagStruct desc")
}

func testMTREthernetNetworkDiagnosticsClusterResetCountsParamsParamsWave11() {
    let _MTREthernetNetworkDiagnosticsClusterResetCountsParams = MTREthernetNetworkDiagnosticsClusterResetCountsParams()
    _MTREthernetNetworkDiagnosticsClusterResetCountsParams.serverSideProcessingTimeout = n(1)
    _ = _MTREthernetNetworkDiagnosticsClusterResetCountsParams.serverSideProcessingTimeout
    _MTREthernetNetworkDiagnosticsClusterResetCountsParams.timedInvokeTimeoutMs = n(1)
    _ = _MTREthernetNetworkDiagnosticsClusterResetCountsParams.timedInvokeTimeoutMs
    mtrRequire(_MTREthernetNetworkDiagnosticsClusterResetCountsParams.description.contains("MTREthernetNetworkDiagnosticsClusterResetCountsParams"), "MTREthernetNetworkDiagnosticsClusterResetCountsParams desc")
}

func testMTRFanControlClusterStepParamsParamsWave11() {
    let _MTRFanControlClusterStepParams = MTRFanControlClusterStepParams()
    _MTRFanControlClusterStepParams.direction = n(1)
    _ = _MTRFanControlClusterStepParams.direction
    _MTRFanControlClusterStepParams.lowestOff = n(1)
    _ = _MTRFanControlClusterStepParams.lowestOff
    _MTRFanControlClusterStepParams.serverSideProcessingTimeout = n(1)
    _ = _MTRFanControlClusterStepParams.serverSideProcessingTimeout
    _MTRFanControlClusterStepParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRFanControlClusterStepParams.timedInvokeTimeoutMs
    _MTRFanControlClusterStepParams.wrap = n(1)
    _ = _MTRFanControlClusterStepParams.wrap
    mtrRequire(_MTRFanControlClusterStepParams.description.contains("MTRFanControlClusterStepParams"), "MTRFanControlClusterStepParams desc")
}

func testMTRFixedLabelClusterLabelStructParamsWave11() {
    let _MTRFixedLabelClusterLabelStruct = MTRFixedLabelClusterLabelStruct()
    _MTRFixedLabelClusterLabelStruct.label = "x"
    _ = _MTRFixedLabelClusterLabelStruct.label
    _MTRFixedLabelClusterLabelStruct.value = "x"
    _ = _MTRFixedLabelClusterLabelStruct.value
    mtrRequire(_MTRFixedLabelClusterLabelStruct.description.contains("MTRFixedLabelClusterLabelStruct"), "MTRFixedLabelClusterLabelStruct desc")
}

func testMTRGeneralCommissioningClusterArmFailSafeParamsParamsWave11() {
    let _MTRGeneralCommissioningClusterArmFailSafeParams = MTRGeneralCommissioningClusterArmFailSafeParams()
    _MTRGeneralCommissioningClusterArmFailSafeParams.breadcrumb = n(1)
    _ = _MTRGeneralCommissioningClusterArmFailSafeParams.breadcrumb
    _MTRGeneralCommissioningClusterArmFailSafeParams.expiryLengthSeconds = n(1)
    _ = _MTRGeneralCommissioningClusterArmFailSafeParams.expiryLengthSeconds
    _MTRGeneralCommissioningClusterArmFailSafeParams.serverSideProcessingTimeout = n(1)
    _ = _MTRGeneralCommissioningClusterArmFailSafeParams.serverSideProcessingTimeout
    _MTRGeneralCommissioningClusterArmFailSafeParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGeneralCommissioningClusterArmFailSafeParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGeneralCommissioningClusterArmFailSafeParams.description.contains("MTRGeneralCommissioningClusterArmFailSafeParams"), "MTRGeneralCommissioningClusterArmFailSafeParams desc")
}

func testMTRGeneralCommissioningClusterArmFailSafeResponseParamsParamsWave11() {
    let _MTRGeneralCommissioningClusterArmFailSafeResponseParams = (try? MTRGeneralCommissioningClusterArmFailSafeResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRGeneralCommissioningClusterArmFailSafeResponseParams()
    _MTRGeneralCommissioningClusterArmFailSafeResponseParams.debugText = "x"
    _ = _MTRGeneralCommissioningClusterArmFailSafeResponseParams.debugText
    _MTRGeneralCommissioningClusterArmFailSafeResponseParams.errorCode = n(1)
    _ = _MTRGeneralCommissioningClusterArmFailSafeResponseParams.errorCode
    _MTRGeneralCommissioningClusterArmFailSafeResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGeneralCommissioningClusterArmFailSafeResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGeneralCommissioningClusterArmFailSafeResponseParams.description.contains("MTRGeneralCommissioningClusterArmFailSafeResponseParams"), "MTRGeneralCommissioningClusterArmFailSafeResponseParams desc")
}

func testMTRGeneralCommissioningClusterBasicCommissioningInfoParamsWave11() {
    let _MTRGeneralCommissioningClusterBasicCommissioningInfo = MTRGeneralCommissioningClusterBasicCommissioningInfo()
    _MTRGeneralCommissioningClusterBasicCommissioningInfo.failSafeExpiryLengthSeconds = n(1)
    _ = _MTRGeneralCommissioningClusterBasicCommissioningInfo.failSafeExpiryLengthSeconds
    _MTRGeneralCommissioningClusterBasicCommissioningInfo.maxCumulativeFailsafeSeconds = n(1)
    _ = _MTRGeneralCommissioningClusterBasicCommissioningInfo.maxCumulativeFailsafeSeconds
    mtrRequire(_MTRGeneralCommissioningClusterBasicCommissioningInfo.description.contains("MTRGeneralCommissioningClusterBasicCommissioningInfo"), "MTRGeneralCommissioningClusterBasicCommissioningInfo desc")
}

func testMTRGeneralCommissioningClusterCommissioningCompleteParamsParamsWave11() {
    let _MTRGeneralCommissioningClusterCommissioningCompleteParams = MTRGeneralCommissioningClusterCommissioningCompleteParams()
    _MTRGeneralCommissioningClusterCommissioningCompleteParams.serverSideProcessingTimeout = n(1)
    _ = _MTRGeneralCommissioningClusterCommissioningCompleteParams.serverSideProcessingTimeout
    _MTRGeneralCommissioningClusterCommissioningCompleteParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGeneralCommissioningClusterCommissioningCompleteParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGeneralCommissioningClusterCommissioningCompleteParams.description.contains("MTRGeneralCommissioningClusterCommissioningCompleteParams"), "MTRGeneralCommissioningClusterCommissioningCompleteParams desc")
}

func testMTRGeneralCommissioningClusterCommissioningCompleteResponseParamsParamsWave11() {
    let _MTRGeneralCommissioningClusterCommissioningCompleteResponseParams = (try? MTRGeneralCommissioningClusterCommissioningCompleteResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRGeneralCommissioningClusterCommissioningCompleteResponseParams()
    _MTRGeneralCommissioningClusterCommissioningCompleteResponseParams.debugText = "x"
    _ = _MTRGeneralCommissioningClusterCommissioningCompleteResponseParams.debugText
    _MTRGeneralCommissioningClusterCommissioningCompleteResponseParams.errorCode = n(1)
    _ = _MTRGeneralCommissioningClusterCommissioningCompleteResponseParams.errorCode
    _MTRGeneralCommissioningClusterCommissioningCompleteResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGeneralCommissioningClusterCommissioningCompleteResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGeneralCommissioningClusterCommissioningCompleteResponseParams.description.contains("MTRGeneralCommissioningClusterCommissioningCompleteResponseParams"), "MTRGeneralCommissioningClusterCommissioningCompleteResponseParams desc")
}

func testMTRGeneralCommissioningClusterSetRegulatoryConfigParamsParamsWave11() {
    let _MTRGeneralCommissioningClusterSetRegulatoryConfigParams = MTRGeneralCommissioningClusterSetRegulatoryConfigParams()
    _MTRGeneralCommissioningClusterSetRegulatoryConfigParams.breadcrumb = n(1)
    _ = _MTRGeneralCommissioningClusterSetRegulatoryConfigParams.breadcrumb
    _MTRGeneralCommissioningClusterSetRegulatoryConfigParams.countryCode = "x"
    _ = _MTRGeneralCommissioningClusterSetRegulatoryConfigParams.countryCode
    _MTRGeneralCommissioningClusterSetRegulatoryConfigParams.newRegulatoryConfig = n(1)
    _ = _MTRGeneralCommissioningClusterSetRegulatoryConfigParams.newRegulatoryConfig
    _MTRGeneralCommissioningClusterSetRegulatoryConfigParams.serverSideProcessingTimeout = n(1)
    _ = _MTRGeneralCommissioningClusterSetRegulatoryConfigParams.serverSideProcessingTimeout
    _MTRGeneralCommissioningClusterSetRegulatoryConfigParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGeneralCommissioningClusterSetRegulatoryConfigParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGeneralCommissioningClusterSetRegulatoryConfigParams.description.contains("MTRGeneralCommissioningClusterSetRegulatoryConfigParams"), "MTRGeneralCommissioningClusterSetRegulatoryConfigParams desc")
}

func testMTRGeneralCommissioningClusterSetRegulatoryConfigResponseParamsParamsWave11() {
    let _MTRGeneralCommissioningClusterSetRegulatoryConfigResponseParams = (try? MTRGeneralCommissioningClusterSetRegulatoryConfigResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRGeneralCommissioningClusterSetRegulatoryConfigResponseParams()
    _MTRGeneralCommissioningClusterSetRegulatoryConfigResponseParams.debugText = "x"
    _ = _MTRGeneralCommissioningClusterSetRegulatoryConfigResponseParams.debugText
    _MTRGeneralCommissioningClusterSetRegulatoryConfigResponseParams.errorCode = n(1)
    _ = _MTRGeneralCommissioningClusterSetRegulatoryConfigResponseParams.errorCode
    _MTRGeneralCommissioningClusterSetRegulatoryConfigResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGeneralCommissioningClusterSetRegulatoryConfigResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGeneralCommissioningClusterSetRegulatoryConfigResponseParams.description.contains("MTRGeneralCommissioningClusterSetRegulatoryConfigResponseParams"), "MTRGeneralCommissioningClusterSetRegulatoryConfigResponseParams desc")
}

func testMTRGeneralDiagnosticsClusterBootReasonEventParamsWave11() {
    let _MTRGeneralDiagnosticsClusterBootReasonEvent = MTRGeneralDiagnosticsClusterBootReasonEvent()
    _MTRGeneralDiagnosticsClusterBootReasonEvent.bootReason = n(1)
    _ = _MTRGeneralDiagnosticsClusterBootReasonEvent.bootReason
    mtrRequire(_MTRGeneralDiagnosticsClusterBootReasonEvent.description.contains("MTRGeneralDiagnosticsClusterBootReasonEvent"), "MTRGeneralDiagnosticsClusterBootReasonEvent desc")
}

func testMTRGeneralDiagnosticsClusterHardwareFaultChangeEventParamsWave11() {
    let _MTRGeneralDiagnosticsClusterHardwareFaultChangeEvent = MTRGeneralDiagnosticsClusterHardwareFaultChangeEvent()
    _MTRGeneralDiagnosticsClusterHardwareFaultChangeEvent.current = [n(1)] as [Any]
    _ = _MTRGeneralDiagnosticsClusterHardwareFaultChangeEvent.current
    _MTRGeneralDiagnosticsClusterHardwareFaultChangeEvent.previous = [n(1)] as [Any]
    _ = _MTRGeneralDiagnosticsClusterHardwareFaultChangeEvent.previous
    mtrRequire(_MTRGeneralDiagnosticsClusterHardwareFaultChangeEvent.description.contains("MTRGeneralDiagnosticsClusterHardwareFaultChangeEvent"), "MTRGeneralDiagnosticsClusterHardwareFaultChangeEvent desc")
}

func testMTRGeneralDiagnosticsClusterNetworkFaultChangeEventParamsWave11() {
    let _MTRGeneralDiagnosticsClusterNetworkFaultChangeEvent = MTRGeneralDiagnosticsClusterNetworkFaultChangeEvent()
    _MTRGeneralDiagnosticsClusterNetworkFaultChangeEvent.current = [n(1)] as [Any]
    _ = _MTRGeneralDiagnosticsClusterNetworkFaultChangeEvent.current
    _MTRGeneralDiagnosticsClusterNetworkFaultChangeEvent.previous = [n(1)] as [Any]
    _ = _MTRGeneralDiagnosticsClusterNetworkFaultChangeEvent.previous
    mtrRequire(_MTRGeneralDiagnosticsClusterNetworkFaultChangeEvent.description.contains("MTRGeneralDiagnosticsClusterNetworkFaultChangeEvent"), "MTRGeneralDiagnosticsClusterNetworkFaultChangeEvent desc")
}

func testMTRGeneralDiagnosticsClusterNetworkInterfaceParamsWave11() {
    let _MTRGeneralDiagnosticsClusterNetworkInterface = MTRGeneralDiagnosticsClusterNetworkInterface()
    _MTRGeneralDiagnosticsClusterNetworkInterface.hardwareAddress = Data([1])
    _ = _MTRGeneralDiagnosticsClusterNetworkInterface.hardwareAddress
    _MTRGeneralDiagnosticsClusterNetworkInterface.iPv4Addresses = [n(1)] as [Any]
    _ = _MTRGeneralDiagnosticsClusterNetworkInterface.iPv4Addresses
    _MTRGeneralDiagnosticsClusterNetworkInterface.iPv6Addresses = [n(1)] as [Any]
    _ = _MTRGeneralDiagnosticsClusterNetworkInterface.iPv6Addresses
    _MTRGeneralDiagnosticsClusterNetworkInterface.isOperational = n(1)
    _ = _MTRGeneralDiagnosticsClusterNetworkInterface.isOperational
    _MTRGeneralDiagnosticsClusterNetworkInterface.name = "x"
    _ = _MTRGeneralDiagnosticsClusterNetworkInterface.name
    _MTRGeneralDiagnosticsClusterNetworkInterface.offPremiseServicesReachableIPv4 = n(1)
    _ = _MTRGeneralDiagnosticsClusterNetworkInterface.offPremiseServicesReachableIPv4
    _MTRGeneralDiagnosticsClusterNetworkInterface.offPremiseServicesReachableIPv6 = n(1)
    _ = _MTRGeneralDiagnosticsClusterNetworkInterface.offPremiseServicesReachableIPv6
    _MTRGeneralDiagnosticsClusterNetworkInterface.`type` = n(1)
    _ = _MTRGeneralDiagnosticsClusterNetworkInterface.`type`
    mtrRequire(_MTRGeneralDiagnosticsClusterNetworkInterface.description.contains("MTRGeneralDiagnosticsClusterNetworkInterface"), "MTRGeneralDiagnosticsClusterNetworkInterface desc")
}

func testMTRGeneralDiagnosticsClusterNetworkInterfaceTypeParamsWave11() {
    let _MTRGeneralDiagnosticsClusterNetworkInterfaceType = MTRGeneralDiagnosticsClusterNetworkInterfaceType()
    _MTRGeneralDiagnosticsClusterNetworkInterfaceType.hardwareAddress = Data([1])
    _ = _MTRGeneralDiagnosticsClusterNetworkInterfaceType.hardwareAddress
    _MTRGeneralDiagnosticsClusterNetworkInterfaceType.iPv4Addresses = [n(1)] as [Any]
    _ = _MTRGeneralDiagnosticsClusterNetworkInterfaceType.iPv4Addresses
    _MTRGeneralDiagnosticsClusterNetworkInterfaceType.iPv6Addresses = [n(1)] as [Any]
    _ = _MTRGeneralDiagnosticsClusterNetworkInterfaceType.iPv6Addresses
    _MTRGeneralDiagnosticsClusterNetworkInterfaceType.isOperational = n(1)
    _ = _MTRGeneralDiagnosticsClusterNetworkInterfaceType.isOperational
    _MTRGeneralDiagnosticsClusterNetworkInterfaceType.name = "x"
    _ = _MTRGeneralDiagnosticsClusterNetworkInterfaceType.name
    _MTRGeneralDiagnosticsClusterNetworkInterfaceType.offPremiseServicesReachableIPv4 = n(1)
    _ = _MTRGeneralDiagnosticsClusterNetworkInterfaceType.offPremiseServicesReachableIPv4
    _MTRGeneralDiagnosticsClusterNetworkInterfaceType.offPremiseServicesReachableIPv6 = n(1)
    _ = _MTRGeneralDiagnosticsClusterNetworkInterfaceType.offPremiseServicesReachableIPv6
    _MTRGeneralDiagnosticsClusterNetworkInterfaceType.`type` = n(1)
    _ = _MTRGeneralDiagnosticsClusterNetworkInterfaceType.`type`
    mtrRequire(!_MTRGeneralDiagnosticsClusterNetworkInterfaceType.description.isEmpty, "MTRGeneralDiagnosticsClusterNetworkInterfaceType desc")
}

func testMTRGeneralDiagnosticsClusterPayloadTestRequestParamsParamsWave11() {
    let _MTRGeneralDiagnosticsClusterPayloadTestRequestParams = MTRGeneralDiagnosticsClusterPayloadTestRequestParams()
    _MTRGeneralDiagnosticsClusterPayloadTestRequestParams.count = n(1)
    _ = _MTRGeneralDiagnosticsClusterPayloadTestRequestParams.count
    _MTRGeneralDiagnosticsClusterPayloadTestRequestParams.enableKey = Data([1])
    _ = _MTRGeneralDiagnosticsClusterPayloadTestRequestParams.enableKey
    _MTRGeneralDiagnosticsClusterPayloadTestRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRGeneralDiagnosticsClusterPayloadTestRequestParams.serverSideProcessingTimeout
    _MTRGeneralDiagnosticsClusterPayloadTestRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGeneralDiagnosticsClusterPayloadTestRequestParams.timedInvokeTimeoutMs
    _MTRGeneralDiagnosticsClusterPayloadTestRequestParams.value = n(1)
    _ = _MTRGeneralDiagnosticsClusterPayloadTestRequestParams.value
    mtrRequire(_MTRGeneralDiagnosticsClusterPayloadTestRequestParams.description.contains("MTRGeneralDiagnosticsClusterPayloadTestRequestParams"), "MTRGeneralDiagnosticsClusterPayloadTestRequestParams desc")
}

func testMTRGeneralDiagnosticsClusterPayloadTestResponseParamsParamsWave11() {
    let _MTRGeneralDiagnosticsClusterPayloadTestResponseParams = (try? MTRGeneralDiagnosticsClusterPayloadTestResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRGeneralDiagnosticsClusterPayloadTestResponseParams()
    _MTRGeneralDiagnosticsClusterPayloadTestResponseParams.payload = Data([1])
    _ = _MTRGeneralDiagnosticsClusterPayloadTestResponseParams.payload
    mtrRequire(_MTRGeneralDiagnosticsClusterPayloadTestResponseParams.description.contains("MTRGeneralDiagnosticsClusterPayloadTestResponseParams"), "MTRGeneralDiagnosticsClusterPayloadTestResponseParams desc")
}

func testMTRGeneralDiagnosticsClusterRadioFaultChangeEventParamsWave11() {
    let _MTRGeneralDiagnosticsClusterRadioFaultChangeEvent = MTRGeneralDiagnosticsClusterRadioFaultChangeEvent()
    _MTRGeneralDiagnosticsClusterRadioFaultChangeEvent.current = [n(1)] as [Any]
    _ = _MTRGeneralDiagnosticsClusterRadioFaultChangeEvent.current
    _MTRGeneralDiagnosticsClusterRadioFaultChangeEvent.previous = [n(1)] as [Any]
    _ = _MTRGeneralDiagnosticsClusterRadioFaultChangeEvent.previous
    mtrRequire(_MTRGeneralDiagnosticsClusterRadioFaultChangeEvent.description.contains("MTRGeneralDiagnosticsClusterRadioFaultChangeEvent"), "MTRGeneralDiagnosticsClusterRadioFaultChangeEvent desc")
}

func testMTRGeneralDiagnosticsClusterTestEventTriggerParamsParamsWave11() {
    let _MTRGeneralDiagnosticsClusterTestEventTriggerParams = MTRGeneralDiagnosticsClusterTestEventTriggerParams()
    _MTRGeneralDiagnosticsClusterTestEventTriggerParams.enableKey = Data([1])
    _ = _MTRGeneralDiagnosticsClusterTestEventTriggerParams.enableKey
    _MTRGeneralDiagnosticsClusterTestEventTriggerParams.eventTrigger = n(1)
    _ = _MTRGeneralDiagnosticsClusterTestEventTriggerParams.eventTrigger
    _MTRGeneralDiagnosticsClusterTestEventTriggerParams.serverSideProcessingTimeout = n(1)
    _ = _MTRGeneralDiagnosticsClusterTestEventTriggerParams.serverSideProcessingTimeout
    _MTRGeneralDiagnosticsClusterTestEventTriggerParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGeneralDiagnosticsClusterTestEventTriggerParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGeneralDiagnosticsClusterTestEventTriggerParams.description.contains("MTRGeneralDiagnosticsClusterTestEventTriggerParams"), "MTRGeneralDiagnosticsClusterTestEventTriggerParams desc")
}

func testMTRGeneralDiagnosticsClusterTimeSnapshotParamsParamsWave11() {
    let _MTRGeneralDiagnosticsClusterTimeSnapshotParams = MTRGeneralDiagnosticsClusterTimeSnapshotParams()
    _MTRGeneralDiagnosticsClusterTimeSnapshotParams.serverSideProcessingTimeout = n(1)
    _ = _MTRGeneralDiagnosticsClusterTimeSnapshotParams.serverSideProcessingTimeout
    _MTRGeneralDiagnosticsClusterTimeSnapshotParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGeneralDiagnosticsClusterTimeSnapshotParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGeneralDiagnosticsClusterTimeSnapshotParams.description.contains("MTRGeneralDiagnosticsClusterTimeSnapshotParams"), "MTRGeneralDiagnosticsClusterTimeSnapshotParams desc")
}

func testMTRGeneralDiagnosticsClusterTimeSnapshotResponseParamsParamsWave11() {
    let _MTRGeneralDiagnosticsClusterTimeSnapshotResponseParams = (try? MTRGeneralDiagnosticsClusterTimeSnapshotResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRGeneralDiagnosticsClusterTimeSnapshotResponseParams()
    _MTRGeneralDiagnosticsClusterTimeSnapshotResponseParams.posixTimeMs = n(1)
    _ = _MTRGeneralDiagnosticsClusterTimeSnapshotResponseParams.posixTimeMs
    _MTRGeneralDiagnosticsClusterTimeSnapshotResponseParams.systemTimeMs = n(1)
    _ = _MTRGeneralDiagnosticsClusterTimeSnapshotResponseParams.systemTimeMs
    mtrRequire(_MTRGeneralDiagnosticsClusterTimeSnapshotResponseParams.description.contains("MTRGeneralDiagnosticsClusterTimeSnapshotResponseParams"), "MTRGeneralDiagnosticsClusterTimeSnapshotResponseParams desc")
}

func testMTRGroupKeyManagementClusterGroupInfoMapStructParamsWave11() {
    let _MTRGroupKeyManagementClusterGroupInfoMapStruct = MTRGroupKeyManagementClusterGroupInfoMapStruct()
    _MTRGroupKeyManagementClusterGroupInfoMapStruct.endpoints = [n(1)] as [Any]
    _ = _MTRGroupKeyManagementClusterGroupInfoMapStruct.endpoints
    _MTRGroupKeyManagementClusterGroupInfoMapStruct.fabricIndex = n(1)
    _ = _MTRGroupKeyManagementClusterGroupInfoMapStruct.fabricIndex
    _MTRGroupKeyManagementClusterGroupInfoMapStruct.groupId = n(1)
    _ = _MTRGroupKeyManagementClusterGroupInfoMapStruct.groupId
    _MTRGroupKeyManagementClusterGroupInfoMapStruct.groupName = "x"
    _ = _MTRGroupKeyManagementClusterGroupInfoMapStruct.groupName
    mtrRequire(_MTRGroupKeyManagementClusterGroupInfoMapStruct.description.contains("MTRGroupKeyManagementClusterGroupInfoMapStruct"), "MTRGroupKeyManagementClusterGroupInfoMapStruct desc")
}

func testMTRGroupKeyManagementClusterGroupKeyMapStructParamsWave11() {
    let _MTRGroupKeyManagementClusterGroupKeyMapStruct = MTRGroupKeyManagementClusterGroupKeyMapStruct()
    _MTRGroupKeyManagementClusterGroupKeyMapStruct.fabricIndex = n(1)
    _ = _MTRGroupKeyManagementClusterGroupKeyMapStruct.fabricIndex
    _MTRGroupKeyManagementClusterGroupKeyMapStruct.groupId = n(1)
    _ = _MTRGroupKeyManagementClusterGroupKeyMapStruct.groupId
    _MTRGroupKeyManagementClusterGroupKeyMapStruct.groupKeySetID = n(1)
    _ = _MTRGroupKeyManagementClusterGroupKeyMapStruct.groupKeySetID
    mtrRequire(_MTRGroupKeyManagementClusterGroupKeyMapStruct.description.contains("MTRGroupKeyManagementClusterGroupKeyMapStruct"), "MTRGroupKeyManagementClusterGroupKeyMapStruct desc")
}

func testMTRGroupKeyManagementClusterGroupKeySetStructParamsWave11() {
    let _MTRGroupKeyManagementClusterGroupKeySetStruct = MTRGroupKeyManagementClusterGroupKeySetStruct()
    _MTRGroupKeyManagementClusterGroupKeySetStruct.epochKey0 = Data([1])
    _ = _MTRGroupKeyManagementClusterGroupKeySetStruct.epochKey0
    _MTRGroupKeyManagementClusterGroupKeySetStruct.epochKey1 = Data([1])
    _ = _MTRGroupKeyManagementClusterGroupKeySetStruct.epochKey1
    _MTRGroupKeyManagementClusterGroupKeySetStruct.epochKey2 = Data([1])
    _ = _MTRGroupKeyManagementClusterGroupKeySetStruct.epochKey2
    _MTRGroupKeyManagementClusterGroupKeySetStruct.epochStartTime0 = n(1)
    _ = _MTRGroupKeyManagementClusterGroupKeySetStruct.epochStartTime0
    _MTRGroupKeyManagementClusterGroupKeySetStruct.epochStartTime1 = n(1)
    _ = _MTRGroupKeyManagementClusterGroupKeySetStruct.epochStartTime1
    _MTRGroupKeyManagementClusterGroupKeySetStruct.epochStartTime2 = n(1)
    _ = _MTRGroupKeyManagementClusterGroupKeySetStruct.epochStartTime2
    _MTRGroupKeyManagementClusterGroupKeySetStruct.groupKeySecurityPolicy = n(1)
    _ = _MTRGroupKeyManagementClusterGroupKeySetStruct.groupKeySecurityPolicy
    _MTRGroupKeyManagementClusterGroupKeySetStruct.groupKeySetID = n(1)
    _ = _MTRGroupKeyManagementClusterGroupKeySetStruct.groupKeySetID
    mtrRequire(_MTRGroupKeyManagementClusterGroupKeySetStruct.description.contains("MTRGroupKeyManagementClusterGroupKeySetStruct"), "MTRGroupKeyManagementClusterGroupKeySetStruct desc")
}

func testMTRGroupKeyManagementClusterKeySetReadAllIndicesParamsParamsWave11() {
    let _MTRGroupKeyManagementClusterKeySetReadAllIndicesParams = MTRGroupKeyManagementClusterKeySetReadAllIndicesParams()
    _MTRGroupKeyManagementClusterKeySetReadAllIndicesParams.groupKeySetIDs = [n(1)] as [Any]
    _ = _MTRGroupKeyManagementClusterKeySetReadAllIndicesParams.groupKeySetIDs
    _MTRGroupKeyManagementClusterKeySetReadAllIndicesParams.serverSideProcessingTimeout = n(1)
    _ = _MTRGroupKeyManagementClusterKeySetReadAllIndicesParams.serverSideProcessingTimeout
    _MTRGroupKeyManagementClusterKeySetReadAllIndicesParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGroupKeyManagementClusterKeySetReadAllIndicesParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGroupKeyManagementClusterKeySetReadAllIndicesParams.description.contains("MTRGroupKeyManagementClusterKeySetReadAllIndicesParams"), "MTRGroupKeyManagementClusterKeySetReadAllIndicesParams desc")
}

func testMTRGroupKeyManagementClusterKeySetReadAllIndicesResponseParamsParamsWave11() {
    let _MTRGroupKeyManagementClusterKeySetReadAllIndicesResponseParams = (try? MTRGroupKeyManagementClusterKeySetReadAllIndicesResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRGroupKeyManagementClusterKeySetReadAllIndicesResponseParams()
    _MTRGroupKeyManagementClusterKeySetReadAllIndicesResponseParams.groupKeySetIDs = [n(1)] as [Any]
    _ = _MTRGroupKeyManagementClusterKeySetReadAllIndicesResponseParams.groupKeySetIDs
    _MTRGroupKeyManagementClusterKeySetReadAllIndicesResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGroupKeyManagementClusterKeySetReadAllIndicesResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGroupKeyManagementClusterKeySetReadAllIndicesResponseParams.description.contains("MTRGroupKeyManagementClusterKeySetReadAllIndicesResponseParams"), "MTRGroupKeyManagementClusterKeySetReadAllIndicesResponseParams desc")
}

func testMTRGroupKeyManagementClusterKeySetReadParamsParamsWave11() {
    let _MTRGroupKeyManagementClusterKeySetReadParams = MTRGroupKeyManagementClusterKeySetReadParams()
    _MTRGroupKeyManagementClusterKeySetReadParams.groupKeySetID = n(1)
    _ = _MTRGroupKeyManagementClusterKeySetReadParams.groupKeySetID
    _MTRGroupKeyManagementClusterKeySetReadParams.serverSideProcessingTimeout = n(1)
    _ = _MTRGroupKeyManagementClusterKeySetReadParams.serverSideProcessingTimeout
    _MTRGroupKeyManagementClusterKeySetReadParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGroupKeyManagementClusterKeySetReadParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGroupKeyManagementClusterKeySetReadParams.description.contains("MTRGroupKeyManagementClusterKeySetReadParams"), "MTRGroupKeyManagementClusterKeySetReadParams desc")
}

func testMTRGroupKeyManagementClusterKeySetReadResponseParamsParamsWave11() {
    let _MTRGroupKeyManagementClusterKeySetReadResponseParams = (try? MTRGroupKeyManagementClusterKeySetReadResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRGroupKeyManagementClusterKeySetReadResponseParams()
    _MTRGroupKeyManagementClusterKeySetReadResponseParams.groupKeySet = MTRGroupKeyManagementClusterGroupKeySetStruct()
    _ = _MTRGroupKeyManagementClusterKeySetReadResponseParams.groupKeySet
    _MTRGroupKeyManagementClusterKeySetReadResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGroupKeyManagementClusterKeySetReadResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGroupKeyManagementClusterKeySetReadResponseParams.description.contains("MTRGroupKeyManagementClusterKeySetReadResponseParams"), "MTRGroupKeyManagementClusterKeySetReadResponseParams desc")
}

func testMTRGroupKeyManagementClusterKeySetRemoveParamsParamsWave11() {
    let _MTRGroupKeyManagementClusterKeySetRemoveParams = MTRGroupKeyManagementClusterKeySetRemoveParams()
    _MTRGroupKeyManagementClusterKeySetRemoveParams.groupKeySetID = n(1)
    _ = _MTRGroupKeyManagementClusterKeySetRemoveParams.groupKeySetID
    _MTRGroupKeyManagementClusterKeySetRemoveParams.serverSideProcessingTimeout = n(1)
    _ = _MTRGroupKeyManagementClusterKeySetRemoveParams.serverSideProcessingTimeout
    _MTRGroupKeyManagementClusterKeySetRemoveParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGroupKeyManagementClusterKeySetRemoveParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGroupKeyManagementClusterKeySetRemoveParams.description.contains("MTRGroupKeyManagementClusterKeySetRemoveParams"), "MTRGroupKeyManagementClusterKeySetRemoveParams desc")
}

func testMTRGroupKeyManagementClusterKeySetWriteParamsParamsWave11() {
    let _MTRGroupKeyManagementClusterKeySetWriteParams = MTRGroupKeyManagementClusterKeySetWriteParams()
    _MTRGroupKeyManagementClusterKeySetWriteParams.groupKeySet = MTRGroupKeyManagementClusterGroupKeySetStruct()
    _ = _MTRGroupKeyManagementClusterKeySetWriteParams.groupKeySet
    _MTRGroupKeyManagementClusterKeySetWriteParams.serverSideProcessingTimeout = n(1)
    _ = _MTRGroupKeyManagementClusterKeySetWriteParams.serverSideProcessingTimeout
    _MTRGroupKeyManagementClusterKeySetWriteParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGroupKeyManagementClusterKeySetWriteParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGroupKeyManagementClusterKeySetWriteParams.description.contains("MTRGroupKeyManagementClusterKeySetWriteParams"), "MTRGroupKeyManagementClusterKeySetWriteParams desc")
}

func testMTRGroupsClusterAddGroupIfIdentifyingParamsParamsWave11() {
    let _MTRGroupsClusterAddGroupIfIdentifyingParams = MTRGroupsClusterAddGroupIfIdentifyingParams()
    _MTRGroupsClusterAddGroupIfIdentifyingParams.groupID = n(1)
    _ = _MTRGroupsClusterAddGroupIfIdentifyingParams.groupID
    _MTRGroupsClusterAddGroupIfIdentifyingParams.groupId = n(1)
    _ = _MTRGroupsClusterAddGroupIfIdentifyingParams.groupId
    _MTRGroupsClusterAddGroupIfIdentifyingParams.groupName = "x"
    _ = _MTRGroupsClusterAddGroupIfIdentifyingParams.groupName
    _MTRGroupsClusterAddGroupIfIdentifyingParams.serverSideProcessingTimeout = n(1)
    _ = _MTRGroupsClusterAddGroupIfIdentifyingParams.serverSideProcessingTimeout
    _MTRGroupsClusterAddGroupIfIdentifyingParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGroupsClusterAddGroupIfIdentifyingParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGroupsClusterAddGroupIfIdentifyingParams.description.contains("MTRGroupsClusterAddGroupIfIdentifyingParams"), "MTRGroupsClusterAddGroupIfIdentifyingParams desc")
}

func testMTRGroupsClusterAddGroupParamsParamsWave11() {
    let _MTRGroupsClusterAddGroupParams = MTRGroupsClusterAddGroupParams()
    _MTRGroupsClusterAddGroupParams.groupID = n(1)
    _ = _MTRGroupsClusterAddGroupParams.groupID
    _MTRGroupsClusterAddGroupParams.groupId = n(1)
    _ = _MTRGroupsClusterAddGroupParams.groupId
    _MTRGroupsClusterAddGroupParams.groupName = "x"
    _ = _MTRGroupsClusterAddGroupParams.groupName
    _MTRGroupsClusterAddGroupParams.serverSideProcessingTimeout = n(1)
    _ = _MTRGroupsClusterAddGroupParams.serverSideProcessingTimeout
    _MTRGroupsClusterAddGroupParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGroupsClusterAddGroupParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGroupsClusterAddGroupParams.description.contains("MTRGroupsClusterAddGroupParams"), "MTRGroupsClusterAddGroupParams desc")
}

func testMTRGroupsClusterAddGroupResponseParamsParamsWave11() {
    let _MTRGroupsClusterAddGroupResponseParams = (try? MTRGroupsClusterAddGroupResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRGroupsClusterAddGroupResponseParams()
    _MTRGroupsClusterAddGroupResponseParams.groupID = n(1)
    _ = _MTRGroupsClusterAddGroupResponseParams.groupID
    _MTRGroupsClusterAddGroupResponseParams.groupId = n(1)
    _ = _MTRGroupsClusterAddGroupResponseParams.groupId
    _MTRGroupsClusterAddGroupResponseParams.status = n(1)
    _ = _MTRGroupsClusterAddGroupResponseParams.status
    _MTRGroupsClusterAddGroupResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGroupsClusterAddGroupResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGroupsClusterAddGroupResponseParams.description.contains("MTRGroupsClusterAddGroupResponseParams"), "MTRGroupsClusterAddGroupResponseParams desc")
}

func testMTRGroupsClusterGetGroupMembershipParamsParamsWave11() {
    let _MTRGroupsClusterGetGroupMembershipParams = MTRGroupsClusterGetGroupMembershipParams()
    _MTRGroupsClusterGetGroupMembershipParams.groupList = [n(1)] as [Any]
    _ = _MTRGroupsClusterGetGroupMembershipParams.groupList
    _MTRGroupsClusterGetGroupMembershipParams.serverSideProcessingTimeout = n(1)
    _ = _MTRGroupsClusterGetGroupMembershipParams.serverSideProcessingTimeout
    _MTRGroupsClusterGetGroupMembershipParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGroupsClusterGetGroupMembershipParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGroupsClusterGetGroupMembershipParams.description.contains("MTRGroupsClusterGetGroupMembershipParams"), "MTRGroupsClusterGetGroupMembershipParams desc")
}

func testMTRGroupsClusterGetGroupMembershipResponseParamsParamsWave11() {
    let _MTRGroupsClusterGetGroupMembershipResponseParams = (try? MTRGroupsClusterGetGroupMembershipResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRGroupsClusterGetGroupMembershipResponseParams()
    _MTRGroupsClusterGetGroupMembershipResponseParams.capacity = n(1)
    _ = _MTRGroupsClusterGetGroupMembershipResponseParams.capacity
    _MTRGroupsClusterGetGroupMembershipResponseParams.groupList = [n(1)] as [Any]
    _ = _MTRGroupsClusterGetGroupMembershipResponseParams.groupList
    _MTRGroupsClusterGetGroupMembershipResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGroupsClusterGetGroupMembershipResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGroupsClusterGetGroupMembershipResponseParams.description.contains("MTRGroupsClusterGetGroupMembershipResponseParams"), "MTRGroupsClusterGetGroupMembershipResponseParams desc")
}

func testMTRGroupsClusterRemoveAllGroupsParamsParamsWave11() {
    let _MTRGroupsClusterRemoveAllGroupsParams = MTRGroupsClusterRemoveAllGroupsParams()
    _MTRGroupsClusterRemoveAllGroupsParams.serverSideProcessingTimeout = n(1)
    _ = _MTRGroupsClusterRemoveAllGroupsParams.serverSideProcessingTimeout
    _MTRGroupsClusterRemoveAllGroupsParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGroupsClusterRemoveAllGroupsParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGroupsClusterRemoveAllGroupsParams.description.contains("MTRGroupsClusterRemoveAllGroupsParams"), "MTRGroupsClusterRemoveAllGroupsParams desc")
}

func testMTRGroupsClusterRemoveGroupParamsParamsWave11() {
    let _MTRGroupsClusterRemoveGroupParams = MTRGroupsClusterRemoveGroupParams()
    _MTRGroupsClusterRemoveGroupParams.groupID = n(1)
    _ = _MTRGroupsClusterRemoveGroupParams.groupID
    _MTRGroupsClusterRemoveGroupParams.groupId = n(1)
    _ = _MTRGroupsClusterRemoveGroupParams.groupId
    _MTRGroupsClusterRemoveGroupParams.serverSideProcessingTimeout = n(1)
    _ = _MTRGroupsClusterRemoveGroupParams.serverSideProcessingTimeout
    _MTRGroupsClusterRemoveGroupParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGroupsClusterRemoveGroupParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGroupsClusterRemoveGroupParams.description.contains("MTRGroupsClusterRemoveGroupParams"), "MTRGroupsClusterRemoveGroupParams desc")
}

func testMTRGroupsClusterRemoveGroupResponseParamsParamsWave11() {
    let _MTRGroupsClusterRemoveGroupResponseParams = (try? MTRGroupsClusterRemoveGroupResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRGroupsClusterRemoveGroupResponseParams()
    _MTRGroupsClusterRemoveGroupResponseParams.groupID = n(1)
    _ = _MTRGroupsClusterRemoveGroupResponseParams.groupID
    _MTRGroupsClusterRemoveGroupResponseParams.groupId = n(1)
    _ = _MTRGroupsClusterRemoveGroupResponseParams.groupId
    _MTRGroupsClusterRemoveGroupResponseParams.status = n(1)
    _ = _MTRGroupsClusterRemoveGroupResponseParams.status
    _MTRGroupsClusterRemoveGroupResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGroupsClusterRemoveGroupResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGroupsClusterRemoveGroupResponseParams.description.contains("MTRGroupsClusterRemoveGroupResponseParams"), "MTRGroupsClusterRemoveGroupResponseParams desc")
}

func testMTRGroupsClusterViewGroupParamsParamsWave11() {
    let _MTRGroupsClusterViewGroupParams = MTRGroupsClusterViewGroupParams()
    _MTRGroupsClusterViewGroupParams.groupID = n(1)
    _ = _MTRGroupsClusterViewGroupParams.groupID
    _MTRGroupsClusterViewGroupParams.groupId = n(1)
    _ = _MTRGroupsClusterViewGroupParams.groupId
    _MTRGroupsClusterViewGroupParams.serverSideProcessingTimeout = n(1)
    _ = _MTRGroupsClusterViewGroupParams.serverSideProcessingTimeout
    _MTRGroupsClusterViewGroupParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGroupsClusterViewGroupParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGroupsClusterViewGroupParams.description.contains("MTRGroupsClusterViewGroupParams"), "MTRGroupsClusterViewGroupParams desc")
}

func testMTRGroupsClusterViewGroupResponseParamsParamsWave11() {
    let _MTRGroupsClusterViewGroupResponseParams = (try? MTRGroupsClusterViewGroupResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRGroupsClusterViewGroupResponseParams()
    _MTRGroupsClusterViewGroupResponseParams.groupID = n(1)
    _ = _MTRGroupsClusterViewGroupResponseParams.groupID
    _MTRGroupsClusterViewGroupResponseParams.groupId = n(1)
    _ = _MTRGroupsClusterViewGroupResponseParams.groupId
    _MTRGroupsClusterViewGroupResponseParams.groupName = "x"
    _ = _MTRGroupsClusterViewGroupResponseParams.groupName
    _MTRGroupsClusterViewGroupResponseParams.status = n(1)
    _ = _MTRGroupsClusterViewGroupResponseParams.status
    _MTRGroupsClusterViewGroupResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRGroupsClusterViewGroupResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRGroupsClusterViewGroupResponseParams.description.contains("MTRGroupsClusterViewGroupResponseParams"), "MTRGroupsClusterViewGroupResponseParams desc")
}

func testMTRHEPAFilterMonitoringClusterReplacementProductStructParamsWave11() {
    let _MTRHEPAFilterMonitoringClusterReplacementProductStruct = MTRHEPAFilterMonitoringClusterReplacementProductStruct()
    _MTRHEPAFilterMonitoringClusterReplacementProductStruct.productIdentifierType = n(1)
    _ = _MTRHEPAFilterMonitoringClusterReplacementProductStruct.productIdentifierType
    _MTRHEPAFilterMonitoringClusterReplacementProductStruct.productIdentifierValue = "x"
    _ = _MTRHEPAFilterMonitoringClusterReplacementProductStruct.productIdentifierValue
    mtrRequire(_MTRHEPAFilterMonitoringClusterReplacementProductStruct.description.contains("MTRHEPAFilterMonitoringClusterReplacementProductStruct"), "MTRHEPAFilterMonitoringClusterReplacementProductStruct desc")
}

func testMTRHEPAFilterMonitoringClusterResetConditionParamsParamsWave11() {
    let _MTRHEPAFilterMonitoringClusterResetConditionParams = MTRHEPAFilterMonitoringClusterResetConditionParams()
    _MTRHEPAFilterMonitoringClusterResetConditionParams.serverSideProcessingTimeout = n(1)
    _ = _MTRHEPAFilterMonitoringClusterResetConditionParams.serverSideProcessingTimeout
    _MTRHEPAFilterMonitoringClusterResetConditionParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRHEPAFilterMonitoringClusterResetConditionParams.timedInvokeTimeoutMs
    mtrRequire(_MTRHEPAFilterMonitoringClusterResetConditionParams.description.contains("MTRHEPAFilterMonitoringClusterResetConditionParams"), "MTRHEPAFilterMonitoringClusterResetConditionParams desc")
}

func testMTRICDManagementClusterMonitoringRegistrationStructParamsWave11() {
    let _MTRICDManagementClusterMonitoringRegistrationStruct = MTRICDManagementClusterMonitoringRegistrationStruct()
    _MTRICDManagementClusterMonitoringRegistrationStruct.checkInNodeID = n(1)
    _ = _MTRICDManagementClusterMonitoringRegistrationStruct.checkInNodeID
    _MTRICDManagementClusterMonitoringRegistrationStruct.clientType = n(1)
    _ = _MTRICDManagementClusterMonitoringRegistrationStruct.clientType
    _MTRICDManagementClusterMonitoringRegistrationStruct.fabricIndex = n(1)
    _ = _MTRICDManagementClusterMonitoringRegistrationStruct.fabricIndex
    _MTRICDManagementClusterMonitoringRegistrationStruct.monitoredSubject = n(1)
    _ = _MTRICDManagementClusterMonitoringRegistrationStruct.monitoredSubject
    mtrRequire(_MTRICDManagementClusterMonitoringRegistrationStruct.description.contains("MTRICDManagementClusterMonitoringRegistrationStruct"), "MTRICDManagementClusterMonitoringRegistrationStruct desc")
}

func testMTRICDManagementClusterRegisterClientParamsParamsWave11() {
    let _MTRICDManagementClusterRegisterClientParams = MTRICDManagementClusterRegisterClientParams()
    _MTRICDManagementClusterRegisterClientParams.checkInNodeID = n(1)
    _ = _MTRICDManagementClusterRegisterClientParams.checkInNodeID
    _MTRICDManagementClusterRegisterClientParams.clientType = n(1)
    _ = _MTRICDManagementClusterRegisterClientParams.clientType
    _MTRICDManagementClusterRegisterClientParams.key = Data([1])
    _ = _MTRICDManagementClusterRegisterClientParams.key
    _MTRICDManagementClusterRegisterClientParams.monitoredSubject = n(1)
    _ = _MTRICDManagementClusterRegisterClientParams.monitoredSubject
    _MTRICDManagementClusterRegisterClientParams.serverSideProcessingTimeout = n(1)
    _ = _MTRICDManagementClusterRegisterClientParams.serverSideProcessingTimeout
    _MTRICDManagementClusterRegisterClientParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRICDManagementClusterRegisterClientParams.timedInvokeTimeoutMs
    _MTRICDManagementClusterRegisterClientParams.verificationKey = Data([1])
    _ = _MTRICDManagementClusterRegisterClientParams.verificationKey
    mtrRequire(_MTRICDManagementClusterRegisterClientParams.description.contains("MTRICDManagementClusterRegisterClientParams"), "MTRICDManagementClusterRegisterClientParams desc")
}

func testMTRICDManagementClusterRegisterClientResponseParamsParamsWave11() {
    let _MTRICDManagementClusterRegisterClientResponseParams = (try? MTRICDManagementClusterRegisterClientResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRICDManagementClusterRegisterClientResponseParams()
    _MTRICDManagementClusterRegisterClientResponseParams.icdCounter = n(1)
    _ = _MTRICDManagementClusterRegisterClientResponseParams.icdCounter
    mtrRequire(_MTRICDManagementClusterRegisterClientResponseParams.description.contains("MTRICDManagementClusterRegisterClientResponseParams"), "MTRICDManagementClusterRegisterClientResponseParams desc")
}

func testMTRICDManagementClusterStayActiveRequestParamsParamsWave11() {
    let _MTRICDManagementClusterStayActiveRequestParams = MTRICDManagementClusterStayActiveRequestParams()
    _MTRICDManagementClusterStayActiveRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRICDManagementClusterStayActiveRequestParams.serverSideProcessingTimeout
    _MTRICDManagementClusterStayActiveRequestParams.stayActiveDuration = n(1)
    _ = _MTRICDManagementClusterStayActiveRequestParams.stayActiveDuration
    _MTRICDManagementClusterStayActiveRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRICDManagementClusterStayActiveRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRICDManagementClusterStayActiveRequestParams.description.contains("MTRICDManagementClusterStayActiveRequestParams"), "MTRICDManagementClusterStayActiveRequestParams desc")
}

func testMTRICDManagementClusterStayActiveResponseParamsParamsWave11() {
    let _MTRICDManagementClusterStayActiveResponseParams = (try? MTRICDManagementClusterStayActiveResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRICDManagementClusterStayActiveResponseParams()
    _MTRICDManagementClusterStayActiveResponseParams.promisedActiveDuration = n(1)
    _ = _MTRICDManagementClusterStayActiveResponseParams.promisedActiveDuration
    mtrRequire(_MTRICDManagementClusterStayActiveResponseParams.description.contains("MTRICDManagementClusterStayActiveResponseParams"), "MTRICDManagementClusterStayActiveResponseParams desc")
}

func testMTRICDManagementClusterUnregisterClientParamsParamsWave11() {
    let _MTRICDManagementClusterUnregisterClientParams = MTRICDManagementClusterUnregisterClientParams()
    _MTRICDManagementClusterUnregisterClientParams.checkInNodeID = n(1)
    _ = _MTRICDManagementClusterUnregisterClientParams.checkInNodeID
    _MTRICDManagementClusterUnregisterClientParams.serverSideProcessingTimeout = n(1)
    _ = _MTRICDManagementClusterUnregisterClientParams.serverSideProcessingTimeout
    _MTRICDManagementClusterUnregisterClientParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRICDManagementClusterUnregisterClientParams.timedInvokeTimeoutMs
    _MTRICDManagementClusterUnregisterClientParams.verificationKey = Data([1])
    _ = _MTRICDManagementClusterUnregisterClientParams.verificationKey
    mtrRequire(_MTRICDManagementClusterUnregisterClientParams.description.contains("MTRICDManagementClusterUnregisterClientParams"), "MTRICDManagementClusterUnregisterClientParams desc")
}

func testMTRIdentifyClusterIdentifyParamsParamsWave11() {
    let _MTRIdentifyClusterIdentifyParams = MTRIdentifyClusterIdentifyParams()
    _MTRIdentifyClusterIdentifyParams.identifyTime = n(1)
    _ = _MTRIdentifyClusterIdentifyParams.identifyTime
    _MTRIdentifyClusterIdentifyParams.serverSideProcessingTimeout = n(1)
    _ = _MTRIdentifyClusterIdentifyParams.serverSideProcessingTimeout
    _MTRIdentifyClusterIdentifyParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRIdentifyClusterIdentifyParams.timedInvokeTimeoutMs
    mtrRequire(_MTRIdentifyClusterIdentifyParams.description.contains("MTRIdentifyClusterIdentifyParams"), "MTRIdentifyClusterIdentifyParams desc")
}

func testMTRIdentifyClusterTriggerEffectParamsParamsWave11() {
    let _MTRIdentifyClusterTriggerEffectParams = MTRIdentifyClusterTriggerEffectParams()
    _MTRIdentifyClusterTriggerEffectParams.effectIdentifier = n(1)
    _ = _MTRIdentifyClusterTriggerEffectParams.effectIdentifier
    _MTRIdentifyClusterTriggerEffectParams.effectVariant = n(1)
    _ = _MTRIdentifyClusterTriggerEffectParams.effectVariant
    _MTRIdentifyClusterTriggerEffectParams.serverSideProcessingTimeout = n(1)
    _ = _MTRIdentifyClusterTriggerEffectParams.serverSideProcessingTimeout
    _MTRIdentifyClusterTriggerEffectParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRIdentifyClusterTriggerEffectParams.timedInvokeTimeoutMs
    mtrRequire(_MTRIdentifyClusterTriggerEffectParams.description.contains("MTRIdentifyClusterTriggerEffectParams"), "MTRIdentifyClusterTriggerEffectParams desc")
}

