import Foundation
import Matter

func testClusterParamsInitCodingDescription() {
    let _MTRColorControlClusterColorLoopSetParams = MTRColorControlClusterColorLoopSetParams()
    mtrRequire(_MTRColorControlClusterColorLoopSetParams.description.contains("MTRColorControlClusterColorLoopSetParams"), "MTRColorControlClusterColorLoopSetParams desc")
    _ = _MTRColorControlClusterColorLoopSetParams.action
    let _MTRColorControlClusterEnhancedMoveHueParams = MTRColorControlClusterEnhancedMoveHueParams()
    mtrRequire(_MTRColorControlClusterEnhancedMoveHueParams.description.contains("MTRColorControlClusterEnhancedMoveHueParams"), "MTRColorControlClusterEnhancedMoveHueParams desc")
    _ = _MTRColorControlClusterEnhancedMoveHueParams.moveMode
    let _MTRColorControlClusterEnhancedMoveToHueAndSaturationParams = MTRColorControlClusterEnhancedMoveToHueAndSaturationParams()
    mtrRequire(_MTRColorControlClusterEnhancedMoveToHueAndSaturationParams.description.contains("MTRColorControlClusterEnhancedMoveToHueAndSaturationParams"), "MTRColorControlClusterEnhancedMoveToHueAndSaturationParams desc")
    _ = _MTRColorControlClusterEnhancedMoveToHueAndSaturationParams.enhancedHue
    let _MTRColorControlClusterEnhancedMoveToHueParams = MTRColorControlClusterEnhancedMoveToHueParams()
    mtrRequire(_MTRColorControlClusterEnhancedMoveToHueParams.description.contains("MTRColorControlClusterEnhancedMoveToHueParams"), "MTRColorControlClusterEnhancedMoveToHueParams desc")
    _ = _MTRColorControlClusterEnhancedMoveToHueParams.direction
    let _MTRColorControlClusterEnhancedStepHueParams = MTRColorControlClusterEnhancedStepHueParams()
    mtrRequire(_MTRColorControlClusterEnhancedStepHueParams.description.contains("MTRColorControlClusterEnhancedStepHueParams"), "MTRColorControlClusterEnhancedStepHueParams desc")
    _ = _MTRColorControlClusterEnhancedStepHueParams.optionsMask
    let _MTRColorControlClusterMoveColorParams = MTRColorControlClusterMoveColorParams()
    mtrRequire(_MTRColorControlClusterMoveColorParams.description.contains("MTRColorControlClusterMoveColorParams"), "MTRColorControlClusterMoveColorParams desc")
    _ = _MTRColorControlClusterMoveColorParams.optionsMask
    let _MTRColorControlClusterMoveColorTemperatureParams = MTRColorControlClusterMoveColorTemperatureParams()
    mtrRequire(_MTRColorControlClusterMoveColorTemperatureParams.description.contains("MTRColorControlClusterMoveColorTemperatureParams"), "MTRColorControlClusterMoveColorTemperatureParams desc")
    _ = _MTRColorControlClusterMoveColorTemperatureParams.colorTemperatureMaximumMireds
    let _MTRColorControlClusterMoveHueParams = MTRColorControlClusterMoveHueParams()
    mtrRequire(_MTRColorControlClusterMoveHueParams.description.contains("MTRColorControlClusterMoveHueParams"), "MTRColorControlClusterMoveHueParams desc")
    _ = _MTRColorControlClusterMoveHueParams.moveMode
    let _MTRColorControlClusterMoveSaturationParams = MTRColorControlClusterMoveSaturationParams()
    mtrRequire(_MTRColorControlClusterMoveSaturationParams.description.contains("MTRColorControlClusterMoveSaturationParams"), "MTRColorControlClusterMoveSaturationParams desc")
    _ = _MTRColorControlClusterMoveSaturationParams.moveMode
    let _MTRColorControlClusterMoveToColorParams = MTRColorControlClusterMoveToColorParams()
    mtrRequire(_MTRColorControlClusterMoveToColorParams.description.contains("MTRColorControlClusterMoveToColorParams"), "MTRColorControlClusterMoveToColorParams desc")
    _ = _MTRColorControlClusterMoveToColorParams.colorX
    let _MTRColorControlClusterMoveToColorTemperatureParams = MTRColorControlClusterMoveToColorTemperatureParams()
    mtrRequire(_MTRColorControlClusterMoveToColorTemperatureParams.description.contains("MTRColorControlClusterMoveToColorTemperatureParams"), "MTRColorControlClusterMoveToColorTemperatureParams desc")
    _ = _MTRColorControlClusterMoveToColorTemperatureParams.colorTemperature
    let _MTRColorControlClusterMoveToHueAndSaturationParams = MTRColorControlClusterMoveToHueAndSaturationParams()
    mtrRequire(_MTRColorControlClusterMoveToHueAndSaturationParams.description.contains("MTRColorControlClusterMoveToHueAndSaturationParams"), "MTRColorControlClusterMoveToHueAndSaturationParams desc")
    _ = _MTRColorControlClusterMoveToHueAndSaturationParams.hue
    let _MTRColorControlClusterMoveToHueParams = MTRColorControlClusterMoveToHueParams()
    mtrRequire(_MTRColorControlClusterMoveToHueParams.description.contains("MTRColorControlClusterMoveToHueParams"), "MTRColorControlClusterMoveToHueParams desc")
    _ = _MTRColorControlClusterMoveToHueParams.direction
    let _MTRColorControlClusterMoveToSaturationParams = MTRColorControlClusterMoveToSaturationParams()
    mtrRequire(_MTRColorControlClusterMoveToSaturationParams.description.contains("MTRColorControlClusterMoveToSaturationParams"), "MTRColorControlClusterMoveToSaturationParams desc")
    _ = _MTRColorControlClusterMoveToSaturationParams.optionsMask
    let _MTRColorControlClusterStepColorParams = MTRColorControlClusterStepColorParams()
    mtrRequire(_MTRColorControlClusterStepColorParams.description.contains("MTRColorControlClusterStepColorParams"), "MTRColorControlClusterStepColorParams desc")
    _ = _MTRColorControlClusterStepColorParams.optionsMask
    let _MTRColorControlClusterStepColorTemperatureParams = MTRColorControlClusterStepColorTemperatureParams()
    mtrRequire(_MTRColorControlClusterStepColorTemperatureParams.description.contains("MTRColorControlClusterStepColorTemperatureParams"), "MTRColorControlClusterStepColorTemperatureParams desc")
    _ = _MTRColorControlClusterStepColorTemperatureParams.colorTemperatureMaximumMireds
    let _MTRColorControlClusterStepHueParams = MTRColorControlClusterStepHueParams()
    mtrRequire(_MTRColorControlClusterStepHueParams.description.contains("MTRColorControlClusterStepHueParams"), "MTRColorControlClusterStepHueParams desc")
    _ = _MTRColorControlClusterStepHueParams.optionsMask
    let _MTRColorControlClusterStepSaturationParams = MTRColorControlClusterStepSaturationParams()
    mtrRequire(_MTRColorControlClusterStepSaturationParams.description.contains("MTRColorControlClusterStepSaturationParams"), "MTRColorControlClusterStepSaturationParams desc")
    _ = _MTRColorControlClusterStepSaturationParams.optionsMask
    let _MTRColorControlClusterStopMoveStepParams = MTRColorControlClusterStopMoveStepParams()
    mtrRequire(_MTRColorControlClusterStopMoveStepParams.description.contains("MTRColorControlClusterStopMoveStepParams"), "MTRColorControlClusterStopMoveStepParams desc")
    _ = _MTRColorControlClusterStopMoveStepParams.optionsMask
    let _MTRDoorLockClusterClearAliroReaderConfigParams = MTRDoorLockClusterClearAliroReaderConfigParams()
    mtrRequire(_MTRDoorLockClusterClearAliroReaderConfigParams.description.contains("MTRDoorLockClusterClearAliroReaderConfigParams"), "MTRDoorLockClusterClearAliroReaderConfigParams desc")
    _ = _MTRDoorLockClusterClearAliroReaderConfigParams.serverSideProcessingTimeout
    let _MTRDoorLockClusterClearCredentialParams = MTRDoorLockClusterClearCredentialParams()
    mtrRequire(_MTRDoorLockClusterClearCredentialParams.description.contains("MTRDoorLockClusterClearCredentialParams"), "MTRDoorLockClusterClearCredentialParams desc")
    _ = _MTRDoorLockClusterClearCredentialParams.credential
    let _MTRDoorLockClusterClearHolidayScheduleParams = MTRDoorLockClusterClearHolidayScheduleParams()
    mtrRequire(_MTRDoorLockClusterClearHolidayScheduleParams.description.contains("MTRDoorLockClusterClearHolidayScheduleParams"), "MTRDoorLockClusterClearHolidayScheduleParams desc")
    _ = _MTRDoorLockClusterClearHolidayScheduleParams.holidayIndex
    let _MTRDoorLockClusterClearUserParams = MTRDoorLockClusterClearUserParams()
    mtrRequire(_MTRDoorLockClusterClearUserParams.description.contains("MTRDoorLockClusterClearUserParams"), "MTRDoorLockClusterClearUserParams desc")
    _ = _MTRDoorLockClusterClearUserParams.serverSideProcessingTimeout
    let _MTRDoorLockClusterClearWeekDayScheduleParams = MTRDoorLockClusterClearWeekDayScheduleParams()
    mtrRequire(_MTRDoorLockClusterClearWeekDayScheduleParams.description.contains("MTRDoorLockClusterClearWeekDayScheduleParams"), "MTRDoorLockClusterClearWeekDayScheduleParams desc")
    _ = _MTRDoorLockClusterClearWeekDayScheduleParams.serverSideProcessingTimeout
    let _MTRDoorLockClusterClearYearDayScheduleParams = MTRDoorLockClusterClearYearDayScheduleParams()
    mtrRequire(_MTRDoorLockClusterClearYearDayScheduleParams.description.contains("MTRDoorLockClusterClearYearDayScheduleParams"), "MTRDoorLockClusterClearYearDayScheduleParams desc")
    _ = _MTRDoorLockClusterClearYearDayScheduleParams.serverSideProcessingTimeout
    let _MTRDoorLockClusterCredentialStruct = MTRDoorLockClusterCredentialStruct()
    mtrRequire(_MTRDoorLockClusterCredentialStruct.description.contains("MTRDoorLockClusterCredentialStruct"), "MTRDoorLockClusterCredentialStruct desc")
    _ = _MTRDoorLockClusterCredentialStruct.credentialIndex
    let _MTRDoorLockClusterDlCredential = MTRDoorLockClusterDlCredential()
    mtrRequire(_MTRDoorLockClusterDlCredential.description.contains("MTRDoorLockClusterDlCredential"), "MTRDoorLockClusterDlCredential desc")
    let _MTRDoorLockClusterDoorLockAlarmEvent = MTRDoorLockClusterDoorLockAlarmEvent()
    mtrRequire(_MTRDoorLockClusterDoorLockAlarmEvent.description.contains("MTRDoorLockClusterDoorLockAlarmEvent"), "MTRDoorLockClusterDoorLockAlarmEvent desc")
    _ = _MTRDoorLockClusterDoorLockAlarmEvent.alarmCode
    let _MTRDoorLockClusterDoorStateChangeEvent = MTRDoorLockClusterDoorStateChangeEvent()
    mtrRequire(_MTRDoorLockClusterDoorStateChangeEvent.description.contains("MTRDoorLockClusterDoorStateChangeEvent"), "MTRDoorLockClusterDoorStateChangeEvent desc")
    _ = _MTRDoorLockClusterDoorStateChangeEvent.doorState
    let _MTRDoorLockClusterGetCredentialStatusParams = MTRDoorLockClusterGetCredentialStatusParams()
    mtrRequire(_MTRDoorLockClusterGetCredentialStatusParams.description.contains("MTRDoorLockClusterGetCredentialStatusParams"), "MTRDoorLockClusterGetCredentialStatusParams desc")
    _ = _MTRDoorLockClusterGetCredentialStatusParams.credential
    let _MTRDoorLockClusterGetCredentialStatusResponseParams = MTRDoorLockClusterGetCredentialStatusResponseParams()
    mtrRequire(_MTRDoorLockClusterGetCredentialStatusResponseParams.description.contains("MTRDoorLockClusterGetCredentialStatusResponseParams"), "MTRDoorLockClusterGetCredentialStatusResponseParams desc")
    _ = _MTRDoorLockClusterGetCredentialStatusResponseParams.creatorFabricIndex
    _ = try? MTRDoorLockClusterGetCredentialStatusResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])
    let _MTRDoorLockClusterGetHolidayScheduleParams = MTRDoorLockClusterGetHolidayScheduleParams()
    mtrRequire(_MTRDoorLockClusterGetHolidayScheduleParams.description.contains("MTRDoorLockClusterGetHolidayScheduleParams"), "MTRDoorLockClusterGetHolidayScheduleParams desc")
    _ = _MTRDoorLockClusterGetHolidayScheduleParams.holidayIndex
    let _MTRDoorLockClusterGetHolidayScheduleResponseParams = MTRDoorLockClusterGetHolidayScheduleResponseParams()
    mtrRequire(_MTRDoorLockClusterGetHolidayScheduleResponseParams.description.contains("MTRDoorLockClusterGetHolidayScheduleResponseParams"), "MTRDoorLockClusterGetHolidayScheduleResponseParams desc")
    _ = _MTRDoorLockClusterGetHolidayScheduleResponseParams.holidayIndex
    _ = try? MTRDoorLockClusterGetHolidayScheduleResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])
    let _MTRDoorLockClusterGetUserParams = MTRDoorLockClusterGetUserParams()
    mtrRequire(_MTRDoorLockClusterGetUserParams.description.contains("MTRDoorLockClusterGetUserParams"), "MTRDoorLockClusterGetUserParams desc")
    _ = _MTRDoorLockClusterGetUserParams.serverSideProcessingTimeout
    let _MTRDoorLockClusterGetUserResponseParams = MTRDoorLockClusterGetUserResponseParams()
    mtrRequire(_MTRDoorLockClusterGetUserResponseParams.description.contains("MTRDoorLockClusterGetUserResponseParams"), "MTRDoorLockClusterGetUserResponseParams desc")
    _ = _MTRDoorLockClusterGetUserResponseParams.creatorFabricIndex
    _ = try? MTRDoorLockClusterGetUserResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])
    let _MTRDoorLockClusterGetWeekDayScheduleParams = MTRDoorLockClusterGetWeekDayScheduleParams()
    mtrRequire(_MTRDoorLockClusterGetWeekDayScheduleParams.description.contains("MTRDoorLockClusterGetWeekDayScheduleParams"), "MTRDoorLockClusterGetWeekDayScheduleParams desc")
    _ = _MTRDoorLockClusterGetWeekDayScheduleParams.serverSideProcessingTimeout
    let _MTRDoorLockClusterGetWeekDayScheduleResponseParams = MTRDoorLockClusterGetWeekDayScheduleResponseParams()
    mtrRequire(_MTRDoorLockClusterGetWeekDayScheduleResponseParams.description.contains("MTRDoorLockClusterGetWeekDayScheduleResponseParams"), "MTRDoorLockClusterGetWeekDayScheduleResponseParams desc")
    _ = _MTRDoorLockClusterGetWeekDayScheduleResponseParams.daysMask
    _ = try? MTRDoorLockClusterGetWeekDayScheduleResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])
    let _MTRDoorLockClusterGetYearDayScheduleParams = MTRDoorLockClusterGetYearDayScheduleParams()
    mtrRequire(_MTRDoorLockClusterGetYearDayScheduleParams.description.contains("MTRDoorLockClusterGetYearDayScheduleParams"), "MTRDoorLockClusterGetYearDayScheduleParams desc")
    _ = _MTRDoorLockClusterGetYearDayScheduleParams.serverSideProcessingTimeout
    let _MTRDoorLockClusterGetYearDayScheduleResponseParams = MTRDoorLockClusterGetYearDayScheduleResponseParams()
    mtrRequire(_MTRDoorLockClusterGetYearDayScheduleResponseParams.description.contains("MTRDoorLockClusterGetYearDayScheduleResponseParams"), "MTRDoorLockClusterGetYearDayScheduleResponseParams desc")
    _ = _MTRDoorLockClusterGetYearDayScheduleResponseParams.localEndTime
    _ = try? MTRDoorLockClusterGetYearDayScheduleResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])
    let _MTRDoorLockClusterLockDoorParams = MTRDoorLockClusterLockDoorParams()
    mtrRequire(_MTRDoorLockClusterLockDoorParams.description.contains("MTRDoorLockClusterLockDoorParams"), "MTRDoorLockClusterLockDoorParams desc")
    _ = _MTRDoorLockClusterLockDoorParams.pinCode
    let _MTRDoorLockClusterLockOperationErrorEvent = MTRDoorLockClusterLockOperationErrorEvent()
    mtrRequire(_MTRDoorLockClusterLockOperationErrorEvent.description.contains("MTRDoorLockClusterLockOperationErrorEvent"), "MTRDoorLockClusterLockOperationErrorEvent desc")
    _ = _MTRDoorLockClusterLockOperationErrorEvent.credentials
    let _MTRDoorLockClusterLockOperationEvent = MTRDoorLockClusterLockOperationEvent()
    mtrRequire(_MTRDoorLockClusterLockOperationEvent.description.contains("MTRDoorLockClusterLockOperationEvent"), "MTRDoorLockClusterLockOperationEvent desc")
    _ = _MTRDoorLockClusterLockOperationEvent.credentials
    let _MTRDoorLockClusterLockUserChangeEvent = MTRDoorLockClusterLockUserChangeEvent()
    mtrRequire(_MTRDoorLockClusterLockUserChangeEvent.description.contains("MTRDoorLockClusterLockUserChangeEvent"), "MTRDoorLockClusterLockUserChangeEvent desc")
    _ = _MTRDoorLockClusterLockUserChangeEvent.dataIndex
    let _MTRDoorLockClusterSetAliroReaderConfigParams = MTRDoorLockClusterSetAliroReaderConfigParams()
    mtrRequire(_MTRDoorLockClusterSetAliroReaderConfigParams.description.contains("MTRDoorLockClusterSetAliroReaderConfigParams"), "MTRDoorLockClusterSetAliroReaderConfigParams desc")
    _ = _MTRDoorLockClusterSetAliroReaderConfigParams.groupIdentifier
    let _MTRDoorLockClusterSetCredentialParams = MTRDoorLockClusterSetCredentialParams()
    mtrRequire(_MTRDoorLockClusterSetCredentialParams.description.contains("MTRDoorLockClusterSetCredentialParams"), "MTRDoorLockClusterSetCredentialParams desc")
    _ = _MTRDoorLockClusterSetCredentialParams.credential
    let _MTRDoorLockClusterSetCredentialResponseParams = MTRDoorLockClusterSetCredentialResponseParams()
    mtrRequire(_MTRDoorLockClusterSetCredentialResponseParams.description.contains("MTRDoorLockClusterSetCredentialResponseParams"), "MTRDoorLockClusterSetCredentialResponseParams desc")
    _ = _MTRDoorLockClusterSetCredentialResponseParams.nextCredentialIndex
    _ = try? MTRDoorLockClusterSetCredentialResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])
    let _MTRDoorLockClusterSetHolidayScheduleParams = MTRDoorLockClusterSetHolidayScheduleParams()
    mtrRequire(_MTRDoorLockClusterSetHolidayScheduleParams.description.contains("MTRDoorLockClusterSetHolidayScheduleParams"), "MTRDoorLockClusterSetHolidayScheduleParams desc")
    _ = _MTRDoorLockClusterSetHolidayScheduleParams.holidayIndex
    let _MTRDoorLockClusterSetUserParams = MTRDoorLockClusterSetUserParams()
    mtrRequire(_MTRDoorLockClusterSetUserParams.description.contains("MTRDoorLockClusterSetUserParams"), "MTRDoorLockClusterSetUserParams desc")
    _ = _MTRDoorLockClusterSetUserParams.credentialRule
    let _MTRDoorLockClusterSetWeekDayScheduleParams = MTRDoorLockClusterSetWeekDayScheduleParams()
    mtrRequire(_MTRDoorLockClusterSetWeekDayScheduleParams.description.contains("MTRDoorLockClusterSetWeekDayScheduleParams"), "MTRDoorLockClusterSetWeekDayScheduleParams desc")
    _ = _MTRDoorLockClusterSetWeekDayScheduleParams.daysMask
    let _MTRDoorLockClusterSetYearDayScheduleParams = MTRDoorLockClusterSetYearDayScheduleParams()
    mtrRequire(_MTRDoorLockClusterSetYearDayScheduleParams.description.contains("MTRDoorLockClusterSetYearDayScheduleParams"), "MTRDoorLockClusterSetYearDayScheduleParams desc")
    _ = _MTRDoorLockClusterSetYearDayScheduleParams.localEndTime
    let _MTRDoorLockClusterUnboltDoorParams = MTRDoorLockClusterUnboltDoorParams()
    mtrRequire(_MTRDoorLockClusterUnboltDoorParams.description.contains("MTRDoorLockClusterUnboltDoorParams"), "MTRDoorLockClusterUnboltDoorParams desc")
    _ = _MTRDoorLockClusterUnboltDoorParams.pinCode
    let _MTRDoorLockClusterUnlockDoorParams = MTRDoorLockClusterUnlockDoorParams()
    mtrRequire(_MTRDoorLockClusterUnlockDoorParams.description.contains("MTRDoorLockClusterUnlockDoorParams"), "MTRDoorLockClusterUnlockDoorParams desc")
    _ = _MTRDoorLockClusterUnlockDoorParams.pinCode
    let _MTRDoorLockClusterUnlockWithTimeoutParams = MTRDoorLockClusterUnlockWithTimeoutParams()
    mtrRequire(_MTRDoorLockClusterUnlockWithTimeoutParams.description.contains("MTRDoorLockClusterUnlockWithTimeoutParams"), "MTRDoorLockClusterUnlockWithTimeoutParams desc")
    _ = _MTRDoorLockClusterUnlockWithTimeoutParams.pinCode
    let _MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams = MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams()
    mtrRequire(_MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams.description.contains("MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams"), "MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams desc")
    _ = _MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams.attributeId
    let _MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams = MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams()
    mtrRequire(_MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams.description.contains("MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams"), "MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams desc")
    _ = _MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams.attributeId
    _ = try? MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])
    let _MTRElectricalMeasurementClusterGetProfileInfoCommandParams = MTRElectricalMeasurementClusterGetProfileInfoCommandParams()
    mtrRequire(_MTRElectricalMeasurementClusterGetProfileInfoCommandParams.description.contains("MTRElectricalMeasurementClusterGetProfileInfoCommandParams"), "MTRElectricalMeasurementClusterGetProfileInfoCommandParams desc")
    _ = _MTRElectricalMeasurementClusterGetProfileInfoCommandParams.serverSideProcessingTimeout
    let _MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams = MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams()
    mtrRequire(_MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams.description.contains("MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams"), "MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams desc")
    _ = _MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams.listOfAttributes
    _ = try? MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])
    let _MTRLevelControlClusterMoveParams = MTRLevelControlClusterMoveParams()
    mtrRequire(_MTRLevelControlClusterMoveParams.description.contains("MTRLevelControlClusterMoveParams"), "MTRLevelControlClusterMoveParams desc")
    _ = _MTRLevelControlClusterMoveParams.moveMode
    let _MTRLevelControlClusterMoveToClosestFrequencyParams = MTRLevelControlClusterMoveToClosestFrequencyParams()
    mtrRequire(_MTRLevelControlClusterMoveToClosestFrequencyParams.description.contains("MTRLevelControlClusterMoveToClosestFrequencyParams"), "MTRLevelControlClusterMoveToClosestFrequencyParams desc")
    _ = _MTRLevelControlClusterMoveToClosestFrequencyParams.frequency
    let _MTRLevelControlClusterMoveToLevelParams = MTRLevelControlClusterMoveToLevelParams()
    mtrRequire(_MTRLevelControlClusterMoveToLevelParams.description.contains("MTRLevelControlClusterMoveToLevelParams"), "MTRLevelControlClusterMoveToLevelParams desc")
    _ = _MTRLevelControlClusterMoveToLevelParams.level
    let _MTRLevelControlClusterMoveToLevelWithOnOffParams = MTRLevelControlClusterMoveToLevelWithOnOffParams()
    mtrRequire(_MTRLevelControlClusterMoveToLevelWithOnOffParams.description.contains("MTRLevelControlClusterMoveToLevelWithOnOffParams"), "MTRLevelControlClusterMoveToLevelWithOnOffParams desc")
    _ = _MTRLevelControlClusterMoveToLevelWithOnOffParams.level
    let _MTRLevelControlClusterMoveWithOnOffParams = MTRLevelControlClusterMoveWithOnOffParams()
    mtrRequire(_MTRLevelControlClusterMoveWithOnOffParams.description.contains("MTRLevelControlClusterMoveWithOnOffParams"), "MTRLevelControlClusterMoveWithOnOffParams desc")
    _ = _MTRLevelControlClusterMoveWithOnOffParams.moveMode
    let _MTRLevelControlClusterStepParams = MTRLevelControlClusterStepParams()
    mtrRequire(_MTRLevelControlClusterStepParams.description.contains("MTRLevelControlClusterStepParams"), "MTRLevelControlClusterStepParams desc")
    _ = _MTRLevelControlClusterStepParams.optionsMask
    let _MTRLevelControlClusterStepWithOnOffParams = MTRLevelControlClusterStepWithOnOffParams()
    mtrRequire(_MTRLevelControlClusterStepWithOnOffParams.description.contains("MTRLevelControlClusterStepWithOnOffParams"), "MTRLevelControlClusterStepWithOnOffParams desc")
    _ = _MTRLevelControlClusterStepWithOnOffParams.optionsMask
    let _MTRLevelControlClusterStopParams = MTRLevelControlClusterStopParams()
    mtrRequire(_MTRLevelControlClusterStopParams.description.contains("MTRLevelControlClusterStopParams"), "MTRLevelControlClusterStopParams desc")
    _ = _MTRLevelControlClusterStopParams.optionsMask
    let _MTRLevelControlClusterStopWithOnOffParams = MTRLevelControlClusterStopWithOnOffParams()
    mtrRequire(_MTRLevelControlClusterStopWithOnOffParams.description.contains("MTRLevelControlClusterStopWithOnOffParams"), "MTRLevelControlClusterStopWithOnOffParams desc")
    _ = _MTRLevelControlClusterStopWithOnOffParams.optionsMask
    let _MTRPowerSourceClusterBatChargeFaultChangeEvent = MTRPowerSourceClusterBatChargeFaultChangeEvent()
    mtrRequire(_MTRPowerSourceClusterBatChargeFaultChangeEvent.description.contains("MTRPowerSourceClusterBatChargeFaultChangeEvent"), "MTRPowerSourceClusterBatChargeFaultChangeEvent desc")
    _ = _MTRPowerSourceClusterBatChargeFaultChangeEvent.current
    let _MTRPowerSourceClusterBatChargeFaultChangeType = MTRPowerSourceClusterBatChargeFaultChangeType()
    mtrRequire(_MTRPowerSourceClusterBatChargeFaultChangeType.description.contains("MTRPowerSourceClusterBatChargeFaultChangeType"), "MTRPowerSourceClusterBatChargeFaultChangeType desc")
    _ = _MTRPowerSourceClusterBatChargeFaultChangeType.current
    let _MTRPowerSourceClusterBatFaultChangeEvent = MTRPowerSourceClusterBatFaultChangeEvent()
    mtrRequire(_MTRPowerSourceClusterBatFaultChangeEvent.description.contains("MTRPowerSourceClusterBatFaultChangeEvent"), "MTRPowerSourceClusterBatFaultChangeEvent desc")
    _ = _MTRPowerSourceClusterBatFaultChangeEvent.current
    let _MTRPowerSourceClusterBatFaultChangeType = MTRPowerSourceClusterBatFaultChangeType()
    mtrRequire(_MTRPowerSourceClusterBatFaultChangeType.description.contains("MTRPowerSourceClusterBatFaultChangeType"), "MTRPowerSourceClusterBatFaultChangeType desc")
    _ = _MTRPowerSourceClusterBatFaultChangeType.current
    let _MTRPowerSourceClusterWiredFaultChangeEvent = MTRPowerSourceClusterWiredFaultChangeEvent()
    mtrRequire(_MTRPowerSourceClusterWiredFaultChangeEvent.description.contains("MTRPowerSourceClusterWiredFaultChangeEvent"), "MTRPowerSourceClusterWiredFaultChangeEvent desc")
    _ = _MTRPowerSourceClusterWiredFaultChangeEvent.current
    let _MTRPowerSourceClusterWiredFaultChangeType = MTRPowerSourceClusterWiredFaultChangeType()
    mtrRequire(_MTRPowerSourceClusterWiredFaultChangeType.description.contains("MTRPowerSourceClusterWiredFaultChangeType"), "MTRPowerSourceClusterWiredFaultChangeType desc")
    _ = _MTRPowerSourceClusterWiredFaultChangeType.current
    let _MTRPumpConfigurationAndControlClusterAirDetectionEvent = MTRPumpConfigurationAndControlClusterAirDetectionEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterAirDetectionEvent.description.contains("MTRPumpConfigurationAndControlClusterAirDetectionEvent"), "MTRPumpConfigurationAndControlClusterAirDetectionEvent desc")
    let _MTRPumpConfigurationAndControlClusterDryRunningEvent = MTRPumpConfigurationAndControlClusterDryRunningEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterDryRunningEvent.description.contains("MTRPumpConfigurationAndControlClusterDryRunningEvent"), "MTRPumpConfigurationAndControlClusterDryRunningEvent desc")
    let _MTRPumpConfigurationAndControlClusterElectronicFatalFailureEvent = MTRPumpConfigurationAndControlClusterElectronicFatalFailureEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterElectronicFatalFailureEvent.description.contains("MTRPumpConfigurationAndControlClusterElectronicFatalFailureEvent"), "MTRPumpConfigurationAndControlClusterElectronicFatalFailureEvent desc")
    let _MTRPumpConfigurationAndControlClusterElectronicNonFatalFailureEvent = MTRPumpConfigurationAndControlClusterElectronicNonFatalFailureEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterElectronicNonFatalFailureEvent.description.contains("MTRPumpConfigurationAndControlClusterElectronicNonFatalFailureEvent"), "MTRPumpConfigurationAndControlClusterElectronicNonFatalFailureEvent desc")
    let _MTRPumpConfigurationAndControlClusterElectronicTemperatureHighEvent = MTRPumpConfigurationAndControlClusterElectronicTemperatureHighEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterElectronicTemperatureHighEvent.description.contains("MTRPumpConfigurationAndControlClusterElectronicTemperatureHighEvent"), "MTRPumpConfigurationAndControlClusterElectronicTemperatureHighEvent desc")
    let _MTRPumpConfigurationAndControlClusterGeneralFaultEvent = MTRPumpConfigurationAndControlClusterGeneralFaultEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterGeneralFaultEvent.description.contains("MTRPumpConfigurationAndControlClusterGeneralFaultEvent"), "MTRPumpConfigurationAndControlClusterGeneralFaultEvent desc")
    let _MTRPumpConfigurationAndControlClusterLeakageEvent = MTRPumpConfigurationAndControlClusterLeakageEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterLeakageEvent.description.contains("MTRPumpConfigurationAndControlClusterLeakageEvent"), "MTRPumpConfigurationAndControlClusterLeakageEvent desc")
    let _MTRPumpConfigurationAndControlClusterMotorTemperatureHighEvent = MTRPumpConfigurationAndControlClusterMotorTemperatureHighEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterMotorTemperatureHighEvent.description.contains("MTRPumpConfigurationAndControlClusterMotorTemperatureHighEvent"), "MTRPumpConfigurationAndControlClusterMotorTemperatureHighEvent desc")
    let _MTRPumpConfigurationAndControlClusterPowerMissingPhaseEvent = MTRPumpConfigurationAndControlClusterPowerMissingPhaseEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterPowerMissingPhaseEvent.description.contains("MTRPumpConfigurationAndControlClusterPowerMissingPhaseEvent"), "MTRPumpConfigurationAndControlClusterPowerMissingPhaseEvent desc")
    let _MTRPumpConfigurationAndControlClusterPumpBlockedEvent = MTRPumpConfigurationAndControlClusterPumpBlockedEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterPumpBlockedEvent.description.contains("MTRPumpConfigurationAndControlClusterPumpBlockedEvent"), "MTRPumpConfigurationAndControlClusterPumpBlockedEvent desc")
    let _MTRPumpConfigurationAndControlClusterPumpMotorFatalFailureEvent = MTRPumpConfigurationAndControlClusterPumpMotorFatalFailureEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterPumpMotorFatalFailureEvent.description.contains("MTRPumpConfigurationAndControlClusterPumpMotorFatalFailureEvent"), "MTRPumpConfigurationAndControlClusterPumpMotorFatalFailureEvent desc")
    let _MTRPumpConfigurationAndControlClusterSensorFailureEvent = MTRPumpConfigurationAndControlClusterSensorFailureEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterSensorFailureEvent.description.contains("MTRPumpConfigurationAndControlClusterSensorFailureEvent"), "MTRPumpConfigurationAndControlClusterSensorFailureEvent desc")
    let _MTRPumpConfigurationAndControlClusterSupplyVoltageHighEvent = MTRPumpConfigurationAndControlClusterSupplyVoltageHighEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterSupplyVoltageHighEvent.description.contains("MTRPumpConfigurationAndControlClusterSupplyVoltageHighEvent"), "MTRPumpConfigurationAndControlClusterSupplyVoltageHighEvent desc")
    let _MTRPumpConfigurationAndControlClusterSupplyVoltageLowEvent = MTRPumpConfigurationAndControlClusterSupplyVoltageLowEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterSupplyVoltageLowEvent.description.contains("MTRPumpConfigurationAndControlClusterSupplyVoltageLowEvent"), "MTRPumpConfigurationAndControlClusterSupplyVoltageLowEvent desc")
    let _MTRPumpConfigurationAndControlClusterSystemPressureHighEvent = MTRPumpConfigurationAndControlClusterSystemPressureHighEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterSystemPressureHighEvent.description.contains("MTRPumpConfigurationAndControlClusterSystemPressureHighEvent"), "MTRPumpConfigurationAndControlClusterSystemPressureHighEvent desc")
    let _MTRPumpConfigurationAndControlClusterSystemPressureLowEvent = MTRPumpConfigurationAndControlClusterSystemPressureLowEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterSystemPressureLowEvent.description.contains("MTRPumpConfigurationAndControlClusterSystemPressureLowEvent"), "MTRPumpConfigurationAndControlClusterSystemPressureLowEvent desc")
    let _MTRPumpConfigurationAndControlClusterTurbineOperationEvent = MTRPumpConfigurationAndControlClusterTurbineOperationEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterTurbineOperationEvent.description.contains("MTRPumpConfigurationAndControlClusterTurbineOperationEvent"), "MTRPumpConfigurationAndControlClusterTurbineOperationEvent desc")
    let _MTRThermostatClusterAtomicRequestParams = MTRThermostatClusterAtomicRequestParams()
    mtrRequire(_MTRThermostatClusterAtomicRequestParams.description.contains("MTRThermostatClusterAtomicRequestParams"), "MTRThermostatClusterAtomicRequestParams desc")
    _ = _MTRThermostatClusterAtomicRequestParams.attributeRequests
    let _MTRThermostatClusterAtomicResponseParams = MTRThermostatClusterAtomicResponseParams()
    mtrRequire(_MTRThermostatClusterAtomicResponseParams.description.contains("MTRThermostatClusterAtomicResponseParams"), "MTRThermostatClusterAtomicResponseParams desc")
    _ = _MTRThermostatClusterAtomicResponseParams.attributeStatus
    _ = try? MTRThermostatClusterAtomicResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])
    let _MTRThermostatClusterClearWeeklyScheduleParams = MTRThermostatClusterClearWeeklyScheduleParams()
    mtrRequire(_MTRThermostatClusterClearWeeklyScheduleParams.description.contains("MTRThermostatClusterClearWeeklyScheduleParams"), "MTRThermostatClusterClearWeeklyScheduleParams desc")
    _ = _MTRThermostatClusterClearWeeklyScheduleParams.serverSideProcessingTimeout
    let _MTRThermostatClusterGetWeeklyScheduleParams = MTRThermostatClusterGetWeeklyScheduleParams()
    mtrRequire(_MTRThermostatClusterGetWeeklyScheduleParams.description.contains("MTRThermostatClusterGetWeeklyScheduleParams"), "MTRThermostatClusterGetWeeklyScheduleParams desc")
    _ = _MTRThermostatClusterGetWeeklyScheduleParams.daysToReturn
    let _MTRThermostatClusterGetWeeklyScheduleResponseParams = MTRThermostatClusterGetWeeklyScheduleResponseParams()
    mtrRequire(_MTRThermostatClusterGetWeeklyScheduleResponseParams.description.contains("MTRThermostatClusterGetWeeklyScheduleResponseParams"), "MTRThermostatClusterGetWeeklyScheduleResponseParams desc")
    _ = _MTRThermostatClusterGetWeeklyScheduleResponseParams.dayOfWeekForSequence
    _ = try? MTRThermostatClusterGetWeeklyScheduleResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])
    let _MTRThermostatClusterPresetStruct = MTRThermostatClusterPresetStruct()
    mtrRequire(_MTRThermostatClusterPresetStruct.description.contains("MTRThermostatClusterPresetStruct"), "MTRThermostatClusterPresetStruct desc")
    _ = _MTRThermostatClusterPresetStruct.builtIn
    let _MTRThermostatClusterPresetTypeStruct = MTRThermostatClusterPresetTypeStruct()
    mtrRequire(_MTRThermostatClusterPresetTypeStruct.description.contains("MTRThermostatClusterPresetTypeStruct"), "MTRThermostatClusterPresetTypeStruct desc")
    _ = _MTRThermostatClusterPresetTypeStruct.numberOfPresets
    let _MTRThermostatClusterScheduleStruct = MTRThermostatClusterScheduleStruct()
    mtrRequire(_MTRThermostatClusterScheduleStruct.description.contains("MTRThermostatClusterScheduleStruct"), "MTRThermostatClusterScheduleStruct desc")
    _ = _MTRThermostatClusterScheduleStruct.builtIn
    let _MTRThermostatClusterScheduleTransitionStruct = MTRThermostatClusterScheduleTransitionStruct()
    mtrRequire(_MTRThermostatClusterScheduleTransitionStruct.description.contains("MTRThermostatClusterScheduleTransitionStruct"), "MTRThermostatClusterScheduleTransitionStruct desc")
    _ = _MTRThermostatClusterScheduleTransitionStruct.coolingSetpoint
    let _MTRThermostatClusterScheduleTypeStruct = MTRThermostatClusterScheduleTypeStruct()
    mtrRequire(_MTRThermostatClusterScheduleTypeStruct.description.contains("MTRThermostatClusterScheduleTypeStruct"), "MTRThermostatClusterScheduleTypeStruct desc")
    _ = _MTRThermostatClusterScheduleTypeStruct.numberOfSchedules
    let _MTRThermostatClusterSetActivePresetRequestParams = MTRThermostatClusterSetActivePresetRequestParams()
    mtrRequire(_MTRThermostatClusterSetActivePresetRequestParams.description.contains("MTRThermostatClusterSetActivePresetRequestParams"), "MTRThermostatClusterSetActivePresetRequestParams desc")
    _ = _MTRThermostatClusterSetActivePresetRequestParams.presetHandle
    let _MTRThermostatClusterSetActiveScheduleRequestParams = MTRThermostatClusterSetActiveScheduleRequestParams()
    mtrRequire(_MTRThermostatClusterSetActiveScheduleRequestParams.description.contains("MTRThermostatClusterSetActiveScheduleRequestParams"), "MTRThermostatClusterSetActiveScheduleRequestParams desc")
    _ = _MTRThermostatClusterSetActiveScheduleRequestParams.scheduleHandle
    let _MTRThermostatClusterSetWeeklyScheduleParams = MTRThermostatClusterSetWeeklyScheduleParams()
    mtrRequire(_MTRThermostatClusterSetWeeklyScheduleParams.description.contains("MTRThermostatClusterSetWeeklyScheduleParams"), "MTRThermostatClusterSetWeeklyScheduleParams desc")
    _ = _MTRThermostatClusterSetWeeklyScheduleParams.dayOfWeekForSequence
    let _MTRThermostatClusterSetpointRaiseLowerParams = MTRThermostatClusterSetpointRaiseLowerParams()
    mtrRequire(_MTRThermostatClusterSetpointRaiseLowerParams.description.contains("MTRThermostatClusterSetpointRaiseLowerParams"), "MTRThermostatClusterSetpointRaiseLowerParams desc")
    _ = _MTRThermostatClusterSetpointRaiseLowerParams.amount
    let _MTRThermostatClusterWeeklyScheduleTransitionStruct = MTRThermostatClusterWeeklyScheduleTransitionStruct()
    mtrRequire(_MTRThermostatClusterWeeklyScheduleTransitionStruct.description.contains("MTRThermostatClusterWeeklyScheduleTransitionStruct"), "MTRThermostatClusterWeeklyScheduleTransitionStruct desc")
    _ = _MTRThermostatClusterWeeklyScheduleTransitionStruct.coolSetpoint
    let _MTRThermostatClusterThermostatScheduleTransition = MTRThermostatClusterThermostatScheduleTransition()
    mtrRequire(_MTRThermostatClusterThermostatScheduleTransition.description.contains("MTRThermostatClusterThermostatScheduleTransition"), "MTRThermostatClusterThermostatScheduleTransition desc")
    let _MTRThreadNetworkDiagnosticsClusterConnectionStatusEvent = MTRThreadNetworkDiagnosticsClusterConnectionStatusEvent()
    mtrRequire(_MTRThreadNetworkDiagnosticsClusterConnectionStatusEvent.description.contains("MTRThreadNetworkDiagnosticsClusterConnectionStatusEvent"), "MTRThreadNetworkDiagnosticsClusterConnectionStatusEvent desc")
    _ = _MTRThreadNetworkDiagnosticsClusterConnectionStatusEvent.connectionStatus
    let _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct = MTRThreadNetworkDiagnosticsClusterNeighborTableStruct()
    mtrRequire(_MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.description.contains("MTRThreadNetworkDiagnosticsClusterNeighborTableStruct"), "MTRThreadNetworkDiagnosticsClusterNeighborTableStruct desc")
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.age
    let _MTRThreadNetworkDiagnosticsClusterNeighborTable = MTRThreadNetworkDiagnosticsClusterNeighborTable()
    mtrRequire(_MTRThreadNetworkDiagnosticsClusterNeighborTable.description.contains("MTRThreadNetworkDiagnosticsClusterNeighborTable"), "MTRThreadNetworkDiagnosticsClusterNeighborTable desc")
    let _MTRThreadNetworkDiagnosticsClusterNetworkFaultChangeEvent = MTRThreadNetworkDiagnosticsClusterNetworkFaultChangeEvent()
    mtrRequire(_MTRThreadNetworkDiagnosticsClusterNetworkFaultChangeEvent.description.contains("MTRThreadNetworkDiagnosticsClusterNetworkFaultChangeEvent"), "MTRThreadNetworkDiagnosticsClusterNetworkFaultChangeEvent desc")
    _ = _MTRThreadNetworkDiagnosticsClusterNetworkFaultChangeEvent.current
    let _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents = MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents()
    mtrRequire(_MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.description.contains("MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents"), "MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents desc")
    _ = _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.activeTimestampPresent
    let _MTRThreadNetworkDiagnosticsClusterResetCountsParams = MTRThreadNetworkDiagnosticsClusterResetCountsParams()
    mtrRequire(_MTRThreadNetworkDiagnosticsClusterResetCountsParams.description.contains("MTRThreadNetworkDiagnosticsClusterResetCountsParams"), "MTRThreadNetworkDiagnosticsClusterResetCountsParams desc")
    _ = _MTRThreadNetworkDiagnosticsClusterResetCountsParams.serverSideProcessingTimeout
    let _MTRThreadNetworkDiagnosticsClusterRouteTableStruct = MTRThreadNetworkDiagnosticsClusterRouteTableStruct()
    mtrRequire(_MTRThreadNetworkDiagnosticsClusterRouteTableStruct.description.contains("MTRThreadNetworkDiagnosticsClusterRouteTableStruct"), "MTRThreadNetworkDiagnosticsClusterRouteTableStruct desc")
    _ = _MTRThreadNetworkDiagnosticsClusterRouteTableStruct.age
    let _MTRThreadNetworkDiagnosticsClusterRouteTable = MTRThreadNetworkDiagnosticsClusterRouteTable()
    mtrRequire(_MTRThreadNetworkDiagnosticsClusterRouteTable.description.contains("MTRThreadNetworkDiagnosticsClusterRouteTable"), "MTRThreadNetworkDiagnosticsClusterRouteTable desc")
    let _MTRThreadNetworkDiagnosticsClusterSecurityPolicy = MTRThreadNetworkDiagnosticsClusterSecurityPolicy()
    mtrRequire(_MTRThreadNetworkDiagnosticsClusterSecurityPolicy.description.contains("MTRThreadNetworkDiagnosticsClusterSecurityPolicy"), "MTRThreadNetworkDiagnosticsClusterSecurityPolicy desc")
    _ = _MTRThreadNetworkDiagnosticsClusterSecurityPolicy.flags
    let _MTRUnitTestingClusterBooleanResponseParams = MTRUnitTestingClusterBooleanResponseParams()
    mtrRequire(_MTRUnitTestingClusterBooleanResponseParams.description.contains("MTRUnitTestingClusterBooleanResponseParams"), "MTRUnitTestingClusterBooleanResponseParams desc")
    _ = _MTRUnitTestingClusterBooleanResponseParams.timedInvokeTimeoutMs
    _ = try? MTRUnitTestingClusterBooleanResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])
    let _MTRUnitTestingClusterDoubleNestedStructList = MTRUnitTestingClusterDoubleNestedStructList()
    mtrRequire(_MTRUnitTestingClusterDoubleNestedStructList.description.contains("MTRUnitTestingClusterDoubleNestedStructList"), "MTRUnitTestingClusterDoubleNestedStructList desc")
    _ = _MTRUnitTestingClusterDoubleNestedStructList.a
    let _MTRUnitTestingClusterNestedStruct = MTRUnitTestingClusterNestedStruct()
    mtrRequire(_MTRUnitTestingClusterNestedStruct.description.contains("MTRUnitTestingClusterNestedStruct"), "MTRUnitTestingClusterNestedStruct desc")
    _ = _MTRUnitTestingClusterNestedStruct.a
    let _MTRUnitTestingClusterNestedStructList = MTRUnitTestingClusterNestedStructList()
    mtrRequire(_MTRUnitTestingClusterNestedStructList.description.contains("MTRUnitTestingClusterNestedStructList"), "MTRUnitTestingClusterNestedStructList desc")
    _ = _MTRUnitTestingClusterNestedStructList.a
    let _MTRUnitTestingClusterNullablesAndOptionalsStruct = MTRUnitTestingClusterNullablesAndOptionalsStruct()
    mtrRequire(_MTRUnitTestingClusterNullablesAndOptionalsStruct.description.contains("MTRUnitTestingClusterNullablesAndOptionalsStruct"), "MTRUnitTestingClusterNullablesAndOptionalsStruct desc")
    _ = _MTRUnitTestingClusterNullablesAndOptionalsStruct.nullableInt
    let _MTRUnitTestingClusterSimpleStruct = MTRUnitTestingClusterSimpleStruct()
    mtrRequire(_MTRUnitTestingClusterSimpleStruct.description.contains("MTRUnitTestingClusterSimpleStruct"), "MTRUnitTestingClusterSimpleStruct desc")
    _ = _MTRUnitTestingClusterSimpleStruct.a
    let _MTRUnitTestingClusterSimpleStructEchoRequestParams = MTRUnitTestingClusterSimpleStructEchoRequestParams()
    mtrRequire(_MTRUnitTestingClusterSimpleStructEchoRequestParams.description.contains("MTRUnitTestingClusterSimpleStructEchoRequestParams"), "MTRUnitTestingClusterSimpleStructEchoRequestParams desc")
    _ = _MTRUnitTestingClusterSimpleStructEchoRequestParams.arg1
    let _MTRUnitTestingClusterSimpleStructResponseParams = MTRUnitTestingClusterSimpleStructResponseParams()
    mtrRequire(_MTRUnitTestingClusterSimpleStructResponseParams.description.contains("MTRUnitTestingClusterSimpleStructResponseParams"), "MTRUnitTestingClusterSimpleStructResponseParams desc")
    _ = _MTRUnitTestingClusterSimpleStructResponseParams.arg1
    _ = try? MTRUnitTestingClusterSimpleStructResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])
    let _MTRUnitTestingClusterTestAddArgumentsParams = MTRUnitTestingClusterTestAddArgumentsParams()
    mtrRequire(_MTRUnitTestingClusterTestAddArgumentsParams.description.contains("MTRUnitTestingClusterTestAddArgumentsParams"), "MTRUnitTestingClusterTestAddArgumentsParams desc")
    _ = _MTRUnitTestingClusterTestAddArgumentsParams.arg1
    let _MTRUnitTestingClusterTestAddArgumentsResponseParams = MTRUnitTestingClusterTestAddArgumentsResponseParams()
    mtrRequire(_MTRUnitTestingClusterTestAddArgumentsResponseParams.description.contains("MTRUnitTestingClusterTestAddArgumentsResponseParams"), "MTRUnitTestingClusterTestAddArgumentsResponseParams desc")
    _ = _MTRUnitTestingClusterTestAddArgumentsResponseParams.returnValue
    _ = try? MTRUnitTestingClusterTestAddArgumentsResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])
    let _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams = MTRUnitTestingClusterTestComplexNullableOptionalRequestParams()
    mtrRequire(_MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.description.contains("MTRUnitTestingClusterTestComplexNullableOptionalRequestParams"), "MTRUnitTestingClusterTestComplexNullableOptionalRequestParams desc")
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.nullableInt
    let _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams = MTRUnitTestingClusterTestComplexNullableOptionalResponseParams()
    mtrRequire(_MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.description.contains("MTRUnitTestingClusterTestComplexNullableOptionalResponseParams"), "MTRUnitTestingClusterTestComplexNullableOptionalResponseParams desc")
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableIntValue
    _ = try? MTRUnitTestingClusterTestComplexNullableOptionalResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])
    let _MTRUnitTestingClusterTestEmitTestEventRequestParams = MTRUnitTestingClusterTestEmitTestEventRequestParams()
    mtrRequire(_MTRUnitTestingClusterTestEmitTestEventRequestParams.description.contains("MTRUnitTestingClusterTestEmitTestEventRequestParams"), "MTRUnitTestingClusterTestEmitTestEventRequestParams desc")
    _ = _MTRUnitTestingClusterTestEmitTestEventRequestParams.arg1
    let _MTRUnitTestingClusterTestEmitTestEventResponseParams = MTRUnitTestingClusterTestEmitTestEventResponseParams()
    mtrRequire(_MTRUnitTestingClusterTestEmitTestEventResponseParams.description.contains("MTRUnitTestingClusterTestEmitTestEventResponseParams"), "MTRUnitTestingClusterTestEmitTestEventResponseParams desc")
    _ = _MTRUnitTestingClusterTestEmitTestEventResponseParams.timedInvokeTimeoutMs
    _ = try? MTRUnitTestingClusterTestEmitTestEventResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])
    let _MTRUnitTestingClusterTestEmitTestFabricScopedEventRequestParams = MTRUnitTestingClusterTestEmitTestFabricScopedEventRequestParams()
    mtrRequire(_MTRUnitTestingClusterTestEmitTestFabricScopedEventRequestParams.description.contains("MTRUnitTestingClusterTestEmitTestFabricScopedEventRequestParams"), "MTRUnitTestingClusterTestEmitTestFabricScopedEventRequestParams desc")
    _ = _MTRUnitTestingClusterTestEmitTestFabricScopedEventRequestParams.arg1
    let _MTRUnitTestingClusterTestEmitTestFabricScopedEventResponseParams = MTRUnitTestingClusterTestEmitTestFabricScopedEventResponseParams()
    mtrRequire(_MTRUnitTestingClusterTestEmitTestFabricScopedEventResponseParams.description.contains("MTRUnitTestingClusterTestEmitTestFabricScopedEventResponseParams"), "MTRUnitTestingClusterTestEmitTestFabricScopedEventResponseParams desc")
    _ = _MTRUnitTestingClusterTestEmitTestFabricScopedEventResponseParams.timedInvokeTimeoutMs
    _ = try? MTRUnitTestingClusterTestEmitTestFabricScopedEventResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])
    let _MTRUnitTestingClusterTestEnumsRequestParams = MTRUnitTestingClusterTestEnumsRequestParams()
    mtrRequire(_MTRUnitTestingClusterTestEnumsRequestParams.description.contains("MTRUnitTestingClusterTestEnumsRequestParams"), "MTRUnitTestingClusterTestEnumsRequestParams desc")
    _ = _MTRUnitTestingClusterTestEnumsRequestParams.arg1
    let _MTRUnitTestingClusterTestEnumsResponseParams = MTRUnitTestingClusterTestEnumsResponseParams()
    mtrRequire(_MTRUnitTestingClusterTestEnumsResponseParams.description.contains("MTRUnitTestingClusterTestEnumsResponseParams"), "MTRUnitTestingClusterTestEnumsResponseParams desc")
    _ = _MTRUnitTestingClusterTestEnumsResponseParams.arg1
    _ = try? MTRUnitTestingClusterTestEnumsResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])
    let _MTRUnitTestingClusterTestEventEvent = MTRUnitTestingClusterTestEventEvent()
    mtrRequire(_MTRUnitTestingClusterTestEventEvent.description.contains("MTRUnitTestingClusterTestEventEvent"), "MTRUnitTestingClusterTestEventEvent desc")
    _ = _MTRUnitTestingClusterTestEventEvent.arg1
    let _MTRUnitTestingClusterTestFabricScoped = MTRUnitTestingClusterTestFabricScoped()
    mtrRequire(_MTRUnitTestingClusterTestFabricScoped.description.contains("MTRUnitTestingClusterTestFabricScoped"), "MTRUnitTestingClusterTestFabricScoped desc")
    _ = _MTRUnitTestingClusterTestFabricScoped.fabricIndex
    let _MTRUnitTestingClusterTestFabricScopedEventEvent = MTRUnitTestingClusterTestFabricScopedEventEvent()
    mtrRequire(_MTRUnitTestingClusterTestFabricScopedEventEvent.description.contains("MTRUnitTestingClusterTestFabricScopedEventEvent"), "MTRUnitTestingClusterTestFabricScopedEventEvent desc")
    _ = _MTRUnitTestingClusterTestFabricScopedEventEvent.fabricIndex
    let _MTRUnitTestingClusterTestListInt8UArgumentRequestParams = MTRUnitTestingClusterTestListInt8UArgumentRequestParams()
    mtrRequire(_MTRUnitTestingClusterTestListInt8UArgumentRequestParams.description.contains("MTRUnitTestingClusterTestListInt8UArgumentRequestParams"), "MTRUnitTestingClusterTestListInt8UArgumentRequestParams desc")
    _ = _MTRUnitTestingClusterTestListInt8UArgumentRequestParams.arg1
    let _MTRUnitTestingClusterTestListInt8UReverseRequestParams = MTRUnitTestingClusterTestListInt8UReverseRequestParams()
    mtrRequire(_MTRUnitTestingClusterTestListInt8UReverseRequestParams.description.contains("MTRUnitTestingClusterTestListInt8UReverseRequestParams"), "MTRUnitTestingClusterTestListInt8UReverseRequestParams desc")
    _ = _MTRUnitTestingClusterTestListInt8UReverseRequestParams.arg1
    let _MTRUnitTestingClusterTestListInt8UReverseResponseParams = MTRUnitTestingClusterTestListInt8UReverseResponseParams()
    mtrRequire(_MTRUnitTestingClusterTestListInt8UReverseResponseParams.description.contains("MTRUnitTestingClusterTestListInt8UReverseResponseParams"), "MTRUnitTestingClusterTestListInt8UReverseResponseParams desc")
    _ = _MTRUnitTestingClusterTestListInt8UReverseResponseParams.arg1
    _ = try? MTRUnitTestingClusterTestListInt8UReverseResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])
    let _MTRUnitTestingClusterTestListNestedStructListArgumentRequestParams = MTRUnitTestingClusterTestListNestedStructListArgumentRequestParams()
    mtrRequire(_MTRUnitTestingClusterTestListNestedStructListArgumentRequestParams.description.contains("MTRUnitTestingClusterTestListNestedStructListArgumentRequestParams"), "MTRUnitTestingClusterTestListNestedStructListArgumentRequestParams desc")
    _ = _MTRUnitTestingClusterTestListNestedStructListArgumentRequestParams.arg1
    let _MTRUnitTestingClusterTestListStructArgumentRequestParams = MTRUnitTestingClusterTestListStructArgumentRequestParams()
    mtrRequire(_MTRUnitTestingClusterTestListStructArgumentRequestParams.description.contains("MTRUnitTestingClusterTestListStructArgumentRequestParams"), "MTRUnitTestingClusterTestListStructArgumentRequestParams desc")
    _ = _MTRUnitTestingClusterTestListStructArgumentRequestParams.arg1
    let _MTRUnitTestingClusterTestListStructOctet = MTRUnitTestingClusterTestListStructOctet()
    mtrRequire(_MTRUnitTestingClusterTestListStructOctet.description.contains("MTRUnitTestingClusterTestListStructOctet"), "MTRUnitTestingClusterTestListStructOctet desc")
    _ = _MTRUnitTestingClusterTestListStructOctet.member1
    let _MTRUnitTestingClusterTestNestedStructArgumentRequestParams = MTRUnitTestingClusterTestNestedStructArgumentRequestParams()
    mtrRequire(_MTRUnitTestingClusterTestNestedStructArgumentRequestParams.description.contains("MTRUnitTestingClusterTestNestedStructArgumentRequestParams"), "MTRUnitTestingClusterTestNestedStructArgumentRequestParams desc")
    _ = _MTRUnitTestingClusterTestNestedStructArgumentRequestParams.arg1
    let _MTRUnitTestingClusterTestNestedStructListArgumentRequestParams = MTRUnitTestingClusterTestNestedStructListArgumentRequestParams()
    mtrRequire(_MTRUnitTestingClusterTestNestedStructListArgumentRequestParams.description.contains("MTRUnitTestingClusterTestNestedStructListArgumentRequestParams"), "MTRUnitTestingClusterTestNestedStructListArgumentRequestParams desc")
    _ = _MTRUnitTestingClusterTestNestedStructListArgumentRequestParams.arg1
    let _MTRUnitTestingClusterTestNotHandledParams = MTRUnitTestingClusterTestNotHandledParams()
    mtrRequire(_MTRUnitTestingClusterTestNotHandledParams.description.contains("MTRUnitTestingClusterTestNotHandledParams"), "MTRUnitTestingClusterTestNotHandledParams desc")
    _ = _MTRUnitTestingClusterTestNotHandledParams.serverSideProcessingTimeout
    let _MTRUnitTestingClusterTestNullableOptionalRequestParams = MTRUnitTestingClusterTestNullableOptionalRequestParams()
    mtrRequire(_MTRUnitTestingClusterTestNullableOptionalRequestParams.description.contains("MTRUnitTestingClusterTestNullableOptionalRequestParams"), "MTRUnitTestingClusterTestNullableOptionalRequestParams desc")
    _ = _MTRUnitTestingClusterTestNullableOptionalRequestParams.arg1
    let _MTRUnitTestingClusterTestNullableOptionalResponseParams = MTRUnitTestingClusterTestNullableOptionalResponseParams()
    mtrRequire(_MTRUnitTestingClusterTestNullableOptionalResponseParams.description.contains("MTRUnitTestingClusterTestNullableOptionalResponseParams"), "MTRUnitTestingClusterTestNullableOptionalResponseParams desc")
    _ = _MTRUnitTestingClusterTestNullableOptionalResponseParams.originalValue
    _ = try? MTRUnitTestingClusterTestNullableOptionalResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])
    let _MTRUnitTestingClusterTestParams = MTRUnitTestingClusterTestParams()
    mtrRequire(_MTRUnitTestingClusterTestParams.description.contains("MTRUnitTestingClusterTestParams"), "MTRUnitTestingClusterTestParams desc")
    _ = _MTRUnitTestingClusterTestParams.serverSideProcessingTimeout
    let _MTRUnitTestingClusterTestSimpleArgumentRequestParams = MTRUnitTestingClusterTestSimpleArgumentRequestParams()
    mtrRequire(_MTRUnitTestingClusterTestSimpleArgumentRequestParams.description.contains("MTRUnitTestingClusterTestSimpleArgumentRequestParams"), "MTRUnitTestingClusterTestSimpleArgumentRequestParams desc")
    _ = _MTRUnitTestingClusterTestSimpleArgumentRequestParams.arg1
    let _MTRUnitTestingClusterTestSimpleArgumentResponseParams = MTRUnitTestingClusterTestSimpleArgumentResponseParams()
    mtrRequire(_MTRUnitTestingClusterTestSimpleArgumentResponseParams.description.contains("MTRUnitTestingClusterTestSimpleArgumentResponseParams"), "MTRUnitTestingClusterTestSimpleArgumentResponseParams desc")
    _ = _MTRUnitTestingClusterTestSimpleArgumentResponseParams.returnValue
    _ = try? MTRUnitTestingClusterTestSimpleArgumentResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])
    let _MTRUnitTestingClusterTestSimpleOptionalArgumentRequestParams = MTRUnitTestingClusterTestSimpleOptionalArgumentRequestParams()
    mtrRequire(_MTRUnitTestingClusterTestSimpleOptionalArgumentRequestParams.description.contains("MTRUnitTestingClusterTestSimpleOptionalArgumentRequestParams"), "MTRUnitTestingClusterTestSimpleOptionalArgumentRequestParams desc")
    _ = _MTRUnitTestingClusterTestSimpleOptionalArgumentRequestParams.arg1
    let _MTRUnitTestingClusterTestSpecificParams = MTRUnitTestingClusterTestSpecificParams()
    mtrRequire(_MTRUnitTestingClusterTestSpecificParams.description.contains("MTRUnitTestingClusterTestSpecificParams"), "MTRUnitTestingClusterTestSpecificParams desc")
    _ = _MTRUnitTestingClusterTestSpecificParams.serverSideProcessingTimeout
    let _MTRUnitTestingClusterTestSpecificResponseParams = MTRUnitTestingClusterTestSpecificResponseParams()
    mtrRequire(_MTRUnitTestingClusterTestSpecificResponseParams.description.contains("MTRUnitTestingClusterTestSpecificResponseParams"), "MTRUnitTestingClusterTestSpecificResponseParams desc")
    _ = _MTRUnitTestingClusterTestSpecificResponseParams.returnValue
    _ = try? MTRUnitTestingClusterTestSpecificResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])
    let _MTRUnitTestingClusterTestStructArgumentRequestParams = MTRUnitTestingClusterTestStructArgumentRequestParams()
    mtrRequire(_MTRUnitTestingClusterTestStructArgumentRequestParams.description.contains("MTRUnitTestingClusterTestStructArgumentRequestParams"), "MTRUnitTestingClusterTestStructArgumentRequestParams desc")
    _ = _MTRUnitTestingClusterTestStructArgumentRequestParams.arg1
    let _MTRUnitTestingClusterTestStructArrayArgumentRequestParams = MTRUnitTestingClusterTestStructArrayArgumentRequestParams()
    mtrRequire(_MTRUnitTestingClusterTestStructArrayArgumentRequestParams.description.contains("MTRUnitTestingClusterTestStructArrayArgumentRequestParams"), "MTRUnitTestingClusterTestStructArrayArgumentRequestParams desc")
    _ = _MTRUnitTestingClusterTestStructArrayArgumentRequestParams.arg1
    let _MTRUnitTestingClusterTestStructArrayArgumentResponseParams = MTRUnitTestingClusterTestStructArrayArgumentResponseParams()
    mtrRequire(_MTRUnitTestingClusterTestStructArrayArgumentResponseParams.description.contains("MTRUnitTestingClusterTestStructArrayArgumentResponseParams"), "MTRUnitTestingClusterTestStructArrayArgumentResponseParams desc")
    _ = _MTRUnitTestingClusterTestStructArrayArgumentResponseParams.arg1
    _ = try? MTRUnitTestingClusterTestStructArrayArgumentResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])
    let _MTRUnitTestingClusterTestUnknownCommandParams = MTRUnitTestingClusterTestUnknownCommandParams()
    mtrRequire(_MTRUnitTestingClusterTestUnknownCommandParams.description.contains("MTRUnitTestingClusterTestUnknownCommandParams"), "MTRUnitTestingClusterTestUnknownCommandParams desc")
    _ = _MTRUnitTestingClusterTestUnknownCommandParams.serverSideProcessingTimeout
    let _MTRUnitTestingClusterTimedInvokeRequestParams = MTRUnitTestingClusterTimedInvokeRequestParams()
    mtrRequire(_MTRUnitTestingClusterTimedInvokeRequestParams.description.contains("MTRUnitTestingClusterTimedInvokeRequestParams"), "MTRUnitTestingClusterTimedInvokeRequestParams desc")
    _ = _MTRUnitTestingClusterTimedInvokeRequestParams.serverSideProcessingTimeout
    let _MTRWindowCoveringClusterDownOrCloseParams = MTRWindowCoveringClusterDownOrCloseParams()
    mtrRequire(_MTRWindowCoveringClusterDownOrCloseParams.description.contains("MTRWindowCoveringClusterDownOrCloseParams"), "MTRWindowCoveringClusterDownOrCloseParams desc")
    _ = _MTRWindowCoveringClusterDownOrCloseParams.serverSideProcessingTimeout
    let _MTRWindowCoveringClusterGoToLiftPercentageParams = MTRWindowCoveringClusterGoToLiftPercentageParams()
    mtrRequire(_MTRWindowCoveringClusterGoToLiftPercentageParams.description.contains("MTRWindowCoveringClusterGoToLiftPercentageParams"), "MTRWindowCoveringClusterGoToLiftPercentageParams desc")
    _ = _MTRWindowCoveringClusterGoToLiftPercentageParams.liftPercent100thsValue
    let _MTRWindowCoveringClusterGoToLiftValueParams = MTRWindowCoveringClusterGoToLiftValueParams()
    mtrRequire(_MTRWindowCoveringClusterGoToLiftValueParams.description.contains("MTRWindowCoveringClusterGoToLiftValueParams"), "MTRWindowCoveringClusterGoToLiftValueParams desc")
    _ = _MTRWindowCoveringClusterGoToLiftValueParams.liftValue
    let _MTRWindowCoveringClusterGoToTiltPercentageParams = MTRWindowCoveringClusterGoToTiltPercentageParams()
    mtrRequire(_MTRWindowCoveringClusterGoToTiltPercentageParams.description.contains("MTRWindowCoveringClusterGoToTiltPercentageParams"), "MTRWindowCoveringClusterGoToTiltPercentageParams desc")
    _ = _MTRWindowCoveringClusterGoToTiltPercentageParams.serverSideProcessingTimeout
    let _MTRWindowCoveringClusterGoToTiltValueParams = MTRWindowCoveringClusterGoToTiltValueParams()
    mtrRequire(_MTRWindowCoveringClusterGoToTiltValueParams.description.contains("MTRWindowCoveringClusterGoToTiltValueParams"), "MTRWindowCoveringClusterGoToTiltValueParams desc")
    _ = _MTRWindowCoveringClusterGoToTiltValueParams.serverSideProcessingTimeout
    let _MTRWindowCoveringClusterStopMotionParams = MTRWindowCoveringClusterStopMotionParams()
    mtrRequire(_MTRWindowCoveringClusterStopMotionParams.description.contains("MTRWindowCoveringClusterStopMotionParams"), "MTRWindowCoveringClusterStopMotionParams desc")
    _ = _MTRWindowCoveringClusterStopMotionParams.serverSideProcessingTimeout
    let _MTRWindowCoveringClusterUpOrOpenParams = MTRWindowCoveringClusterUpOrOpenParams()
    mtrRequire(_MTRWindowCoveringClusterUpOrOpenParams.description.contains("MTRWindowCoveringClusterUpOrOpenParams"), "MTRWindowCoveringClusterUpOrOpenParams desc")
    _ = _MTRWindowCoveringClusterUpOrOpenParams.serverSideProcessingTimeout
}

