import Foundation

public enum MTRAttributeIDType: UInt32, Sendable, Hashable {
    case MTRClusterGlobalAttributeGeneratedCommandListID = 65528
    case MTRClusterGlobalAttributeAcceptedCommandListID = 65529
    case MTRClusterGlobalAttributeAttributeListID = 65531
    case MTRClusterGlobalAttributeFeatureMapID = 65532
    case MTRClusterGlobalAttributeClusterRevisionID = 65533
    case MTRClusterIdentifyAttributeIdentifyTimeID = 0
    case MTRClusterIdentifyAttributeIdentifyTypeID = 1
    case MTRClusterOnOffAttributeGlobalSceneControlID = 16384
    case MTRClusterOnOffAttributeOnTimeID = 16385
    case MTRClusterOnOffAttributeOffWaitTimeID = 16386
    case MTRClusterOnOffAttributeStartUpOnOffID = 16387
    case MTRClusterLevelControlAttributeMinLevelID = 2
    case MTRClusterLevelControlAttributeMaxLevelID = 3
    case MTRClusterLevelControlAttributeCurrentFrequencyID = 4
    case MTRClusterLevelControlAttributeMinFrequencyID = 5
    case MTRClusterLevelControlAttributeMaxFrequencyID = 6
    case MTRClusterLevelControlAttributeOptionsID = 15
    case MTRClusterLevelControlAttributeOnOffTransitionTimeID = 16
    case MTRClusterLevelControlAttributeOnLevelID = 17
    case MTRClusterLevelControlAttributeOnTransitionTimeID = 18
    case MTRClusterLevelControlAttributeOffTransitionTimeID = 19
    case MTRClusterLevelControlAttributeDefaultMoveRateID = 20
    case MTRClusterBasicAttributeHardwareVersionID = 7
    case MTRClusterBasicAttributeHardwareVersionStringID = 8
    case MTRClusterBasicAttributeSoftwareVersionID = 9
    case MTRClusterBasicAttributeSoftwareVersionStringID = 10
    case MTRClusterBasicAttributeManufacturingDateID = 11
    case MTRClusterBasicAttributePartNumberID = 12
    case MTRClusterBasicAttributeProductURLID = 13
    case MTRClusterBasicAttributeProductLabelID = 14
    case clusterBasicInformationAttributeSpecificationVersionID = 21
    case clusterBasicInformationAttributeMaxPathsPerInvokeID = 22
    case MTRClusterPowerSourceAttributeBatApprovedChemistryID = 23
    case MTRClusterPowerSourceAttributeBatCapacityID = 24
    case MTRClusterPowerSourceAttributeBatQuantityID = 25
    case MTRClusterPowerSourceAttributeBatChargeStateID = 26
    case MTRClusterPowerSourceAttributeBatTimeToFullChargeID = 27
    case MTRClusterPowerSourceAttributeBatFunctionalWhileChargingID = 28
    case MTRClusterPowerSourceAttributeBatChargingCurrentID = 29
    case MTRClusterPowerSourceAttributeActiveBatChargeFaultsID = 30
    case clusterPowerSourceAttributeEndpointListID = 31
    case MTRClusterThreadNetworkDiagnosticsAttributeTxOtherCountID = 32
    case MTRClusterThreadNetworkDiagnosticsAttributeTxRetryCountID = 33
    case MTRClusterThreadNetworkDiagnosticsAttributeTxDirectMaxRetryExpiryCountID = 34
    case MTRClusterThreadNetworkDiagnosticsAttributeTxIndirectMaxRetryExpiryCountID = 35
    case MTRClusterThreadNetworkDiagnosticsAttributeTxErrCcaCountID = 36
    case MTRClusterThreadNetworkDiagnosticsAttributeTxErrAbortCountID = 37
    case MTRClusterThreadNetworkDiagnosticsAttributeTxErrBusyChannelCountID = 38
    case MTRClusterThreadNetworkDiagnosticsAttributeRxTotalCountID = 39
    case MTRClusterThreadNetworkDiagnosticsAttributeRxUnicastCountID = 40
    case MTRClusterThreadNetworkDiagnosticsAttributeRxBroadcastCountID = 41
    case MTRClusterThreadNetworkDiagnosticsAttributeRxDataCountID = 42
    case MTRClusterThreadNetworkDiagnosticsAttributeRxDataPollCountID = 43
    case MTRClusterThreadNetworkDiagnosticsAttributeRxBeaconCountID = 44
    case MTRClusterThreadNetworkDiagnosticsAttributeRxBeaconRequestCountID = 45
    case MTRClusterThreadNetworkDiagnosticsAttributeRxOtherCountID = 46
    case MTRClusterThreadNetworkDiagnosticsAttributeRxAddressFilteredCountID = 47
    case MTRClusterThreadNetworkDiagnosticsAttributeRxDestAddrFilteredCountID = 48
    case MTRClusterThreadNetworkDiagnosticsAttributeRxDuplicatedCountID = 49
    case MTRClusterThreadNetworkDiagnosticsAttributeRxErrNoFrameCountID = 50
    case MTRClusterThreadNetworkDiagnosticsAttributeRxErrUnknownNeighborCountID = 51
    case MTRClusterThreadNetworkDiagnosticsAttributeRxErrInvalidSrcAddrCountID = 52
    case MTRClusterThreadNetworkDiagnosticsAttributeRxErrSecCountID = 53
    case MTRClusterThreadNetworkDiagnosticsAttributeRxErrFcsCountID = 54
    case MTRClusterThreadNetworkDiagnosticsAttributeRxErrOtherCountID = 55
    case MTRClusterThreadNetworkDiagnosticsAttributeActiveTimestampID = 56
    case MTRClusterThreadNetworkDiagnosticsAttributePendingTimestampID = 57
    case MTRClusterThreadNetworkDiagnosticsAttributeDelayID = 58
    case MTRClusterThreadNetworkDiagnosticsAttributeSecurityPolicyID = 59
    case MTRClusterThreadNetworkDiagnosticsAttributeChannelPage0MaskID = 60
    case MTRClusterThreadNetworkDiagnosticsAttributeOperationalDatasetComponentsID = 61
    case MTRClusterThreadNetworkDiagnosticsAttributeActiveNetworkFaultsListID = 62
    case clusterEnergyEVSEAttributeSessionIDID = 64
    case clusterEnergyEVSEAttributeSessionDurationID = 65
    case clusterEnergyEVSEAttributeSessionEnergyChargedID = 66
    case clusterDoorLockAttributeAliroReaderVerificationKeyID = 128
    case clusterDoorLockAttributeAliroReaderGroupIdentifierID = 129
    case clusterDoorLockAttributeAliroReaderGroupSubIdentifierID = 130
    case clusterDoorLockAttributeAliroExpeditedTransactionSupportedProtocolVersionsID = 131
    case clusterDoorLockAttributeAliroGroupResolvingKeyID = 132
    case clusterDoorLockAttributeAliroSupportedBLEUWBProtocolVersionsID = 133
    case clusterDoorLockAttributeAliroBLEAdvertisingVersionID = 134
    case clusterDoorLockAttributeNumberOfAliroCredentialIssuerKeysSupportedID = 135
    case clusterDoorLockAttributeNumberOfAliroEndpointKeysSupportedID = 136
    case MTRClusterThermostatAttributeACCompressorTypeID = 67
    case MTRClusterThermostatAttributeACErrorCodeID = 68
    case MTRClusterThermostatAttributeACLouverPositionID = 69
    case MTRClusterThermostatAttributeACCoilTemperatureID = 70
    case MTRClusterThermostatAttributeACCapacityformatID = 71
    case clusterThermostatAttributePresetTypesID = 72
    case clusterThermostatAttributeScheduleTypesID = 73
    case clusterThermostatAttributeNumberOfPresetsID = 74
    case clusterThermostatAttributeNumberOfSchedulesID = 75
    case clusterThermostatAttributeNumberOfScheduleTransitionsID = 76
    case clusterThermostatAttributeNumberOfScheduleTransitionPerDayID = 77
    case clusterThermostatAttributeActivePresetHandleID = 78
    case clusterThermostatAttributeActiveScheduleHandleID = 79
    case clusterThermostatAttributePresetsID = 80
    case clusterThermostatAttributeSchedulesID = 81
    case clusterThermostatAttributeSetpointHoldExpiryTimestampID = 82
    case MTRClusterColorControlAttributeColorLoopTimeID = 16388
    case MTRClusterColorControlAttributeColorLoopStartEnhancedHueID = 16389
    case MTRClusterColorControlAttributeColorLoopStoredEnhancedHueID = 16390
    case MTRClusterColorControlAttributeColorCapabilitiesID = 16394
    case MTRClusterColorControlAttributeColorTempPhysicalMinMiredsID = 16395
    case MTRClusterColorControlAttributeColorTempPhysicalMaxMiredsID = 16396
    case MTRClusterColorControlAttributeCoupleColorTempToLevelMinMiredsID = 16397
    case MTRClusterColorControlAttributeStartUpColorTemperatureMiredsID = 16400
    case MTRClusterTestClusterAttributeUnsupportedID = 255
    case MTRClusterTestClusterAttributeNullableInt24uID = 16391
    case MTRClusterTestClusterAttributeNullableInt32uID = 16392
    case MTRClusterTestClusterAttributeNullableInt40uID = 16393
    case MTRClusterTestClusterAttributeNullableInt16sID = 16398
    case MTRClusterTestClusterAttributeNullableInt24sID = 16399
    case MTRClusterTestClusterAttributeNullableInt40sID = 16401
    case MTRClusterTestClusterAttributeNullableInt48sID = 16402
    case MTRClusterTestClusterAttributeNullableInt56sID = 16403
    case MTRClusterTestClusterAttributeNullableInt64sID = 16404
    case MTRClusterTestClusterAttributeNullableEnum8ID = 16405
    case MTRClusterTestClusterAttributeNullableEnum16ID = 16406
    case MTRClusterTestClusterAttributeNullableFloatSingleID = 16407
    case MTRClusterTestClusterAttributeNullableFloatDoubleID = 16408
    case MTRClusterTestClusterAttributeNullableOctetStringID = 16409
    case MTRClusterTestClusterAttributeNullableCharStringID = 16414
    case MTRClusterTestClusterAttributeNullableEnumAttrID = 16420
    case MTRClusterTestClusterAttributeNullableStructID = 16421
    case MTRClusterTestClusterAttributeNullableRangeRestrictedInt8uID = 16422
    case MTRClusterTestClusterAttributeNullableRangeRestrictedInt8sID = 16423
    case MTRClusterTestClusterAttributeNullableRangeRestrictedInt16uID = 16424
    case MTRClusterTestClusterAttributeNullableRangeRestrictedInt16sID = 16425
    case MTRClusterTestClusterAttributeWriteOnlyInt8uID = 16426
    case MTRClusterBinaryInputBasicAttributePolarityID = 84
    case MTRClusterBinaryInputBasicAttributePresentValueID = 85
    case MTRClusterBinaryInputBasicAttributeReliabilityID = 103
    case MTRClusterBinaryInputBasicAttributeStatusFlagsID = 111
    case MTRClusterBinaryInputBasicAttributeApplicationTypeID = 256
    case MTRClusterElectricalMeasurementAttributeDcVoltageMinID = 257
    case MTRClusterElectricalMeasurementAttributeDcVoltageMaxID = 258
    case MTRClusterElectricalMeasurementAttributeDcCurrentID = 259
    case MTRClusterElectricalMeasurementAttributeDcCurrentMinID = 260
    case MTRClusterElectricalMeasurementAttributeDcCurrentMaxID = 261
    case MTRClusterElectricalMeasurementAttributeDcPowerID = 262
    case MTRClusterElectricalMeasurementAttributeDcPowerMinID = 263
    case MTRClusterElectricalMeasurementAttributeDcPowerMaxID = 264
    case MTRClusterElectricalMeasurementAttributeDcVoltageMultiplierID = 512
    case MTRClusterElectricalMeasurementAttributeDcVoltageDivisorID = 513
    case MTRClusterElectricalMeasurementAttributeDcCurrentMultiplierID = 514
    case MTRClusterElectricalMeasurementAttributeDcCurrentDivisorID = 515
    case MTRClusterElectricalMeasurementAttributeDcPowerMultiplierID = 516
    case MTRClusterElectricalMeasurementAttributeDcPowerDivisorID = 517
    case MTRClusterElectricalMeasurementAttributeAcFrequencyID = 768
    case MTRClusterElectricalMeasurementAttributeAcFrequencyMinID = 769
    case MTRClusterElectricalMeasurementAttributeAcFrequencyMaxID = 770
    case MTRClusterElectricalMeasurementAttributeNeutralCurrentID = 771
    case MTRClusterElectricalMeasurementAttributeTotalActivePowerID = 772
    case MTRClusterElectricalMeasurementAttributeTotalReactivePowerID = 773
    case MTRClusterElectricalMeasurementAttributeTotalApparentPowerID = 774
    case MTRClusterElectricalMeasurementAttributeMeasured1stHarmonicCurrentID = 775
    case MTRClusterElectricalMeasurementAttributeMeasured3rdHarmonicCurrentID = 776
    case MTRClusterElectricalMeasurementAttributeMeasured5thHarmonicCurrentID = 777
    case MTRClusterElectricalMeasurementAttributeMeasured7thHarmonicCurrentID = 778
    case MTRClusterElectricalMeasurementAttributeMeasured9thHarmonicCurrentID = 779
    case MTRClusterElectricalMeasurementAttributeMeasured11thHarmonicCurrentID = 780
    case MTRClusterElectricalMeasurementAttributeMeasuredPhase1stHarmonicCurrentID = 781
    case MTRClusterElectricalMeasurementAttributeMeasuredPhase3rdHarmonicCurrentID = 782
    case MTRClusterElectricalMeasurementAttributeMeasuredPhase5thHarmonicCurrentID = 783
    case MTRClusterElectricalMeasurementAttributeMeasuredPhase7thHarmonicCurrentID = 784
    case MTRClusterElectricalMeasurementAttributeMeasuredPhase9thHarmonicCurrentID = 785
    case MTRClusterElectricalMeasurementAttributeMeasuredPhase11thHarmonicCurrentID = 786
    case MTRClusterElectricalMeasurementAttributeAcFrequencyMultiplierID = 1024
    case MTRClusterElectricalMeasurementAttributeAcFrequencyDivisorID = 1025
    case MTRClusterElectricalMeasurementAttributePowerMultiplierID = 1026
    case MTRClusterElectricalMeasurementAttributePowerDivisorID = 1027
    case MTRClusterElectricalMeasurementAttributeHarmonicCurrentMultiplierID = 1028
    case MTRClusterElectricalMeasurementAttributePhaseHarmonicCurrentMultiplierID = 1029
    case MTRClusterElectricalMeasurementAttributeInstantaneousVoltageID = 1280
    case MTRClusterElectricalMeasurementAttributeInstantaneousLineCurrentID = 1281
    case MTRClusterElectricalMeasurementAttributeInstantaneousActiveCurrentID = 1282
    case MTRClusterElectricalMeasurementAttributeInstantaneousReactiveCurrentID = 1283
    case MTRClusterElectricalMeasurementAttributeInstantaneousPowerID = 1284
    case MTRClusterElectricalMeasurementAttributeRmsVoltageID = 1285
    case MTRClusterElectricalMeasurementAttributeRmsVoltageMinID = 1286
    case MTRClusterElectricalMeasurementAttributeRmsVoltageMaxID = 1287
    case MTRClusterElectricalMeasurementAttributeRmsCurrentID = 1288
    case MTRClusterElectricalMeasurementAttributeRmsCurrentMinID = 1289
    case MTRClusterElectricalMeasurementAttributeRmsCurrentMaxID = 1290
    case MTRClusterElectricalMeasurementAttributeActivePowerID = 1291
    case MTRClusterElectricalMeasurementAttributeActivePowerMinID = 1292
    case MTRClusterElectricalMeasurementAttributeActivePowerMaxID = 1293
    case MTRClusterElectricalMeasurementAttributeReactivePowerID = 1294
    case MTRClusterElectricalMeasurementAttributeApparentPowerID = 1295
    case MTRClusterElectricalMeasurementAttributePowerFactorID = 1296
    case MTRClusterElectricalMeasurementAttributeAverageRmsVoltageMeasurementPeriodID = 1297
    case MTRClusterElectricalMeasurementAttributeAverageRmsUnderVoltageCounterID = 1299
    case MTRClusterElectricalMeasurementAttributeRmsExtremeOverVoltagePeriodID = 1300
    case MTRClusterElectricalMeasurementAttributeRmsExtremeUnderVoltagePeriodID = 1301
    case MTRClusterElectricalMeasurementAttributeRmsVoltageSagPeriodID = 1302
    case MTRClusterElectricalMeasurementAttributeRmsVoltageSwellPeriodID = 1303
    case MTRClusterElectricalMeasurementAttributeAcVoltageMultiplierID = 1536
    case MTRClusterElectricalMeasurementAttributeAcVoltageDivisorID = 1537
    case MTRClusterElectricalMeasurementAttributeAcCurrentMultiplierID = 1538
    case MTRClusterElectricalMeasurementAttributeAcCurrentDivisorID = 1539
    case MTRClusterElectricalMeasurementAttributeAcPowerMultiplierID = 1540
    case MTRClusterElectricalMeasurementAttributeAcPowerDivisorID = 1541
    case MTRClusterElectricalMeasurementAttributeOverloadAlarmsMaskID = 1792
    case MTRClusterElectricalMeasurementAttributeVoltageOverloadID = 1793
    case MTRClusterElectricalMeasurementAttributeCurrentOverloadID = 1794
    case MTRClusterElectricalMeasurementAttributeAcOverloadAlarmsMaskID = 2048
    case MTRClusterElectricalMeasurementAttributeAcVoltageOverloadID = 2049
    case MTRClusterElectricalMeasurementAttributeAcCurrentOverloadID = 2050
    case MTRClusterElectricalMeasurementAttributeAcActivePowerOverloadID = 2051
    case MTRClusterElectricalMeasurementAttributeAcReactivePowerOverloadID = 2052
    case MTRClusterElectricalMeasurementAttributeAverageRmsOverVoltageID = 2053
    case MTRClusterElectricalMeasurementAttributeAverageRmsUnderVoltageID = 2054
    case MTRClusterElectricalMeasurementAttributeRmsExtremeOverVoltageID = 2055
    case MTRClusterElectricalMeasurementAttributeRmsExtremeUnderVoltageID = 2056
    case MTRClusterElectricalMeasurementAttributeRmsVoltageSagID = 2057
    case MTRClusterElectricalMeasurementAttributeRmsVoltageSwellID = 2058
    case MTRClusterElectricalMeasurementAttributeLineCurrentPhaseBID = 2305
    case MTRClusterElectricalMeasurementAttributeActiveCurrentPhaseBID = 2306
    case MTRClusterElectricalMeasurementAttributeReactiveCurrentPhaseBID = 2307
    case MTRClusterElectricalMeasurementAttributeRmsVoltagePhaseBID = 2309
    case MTRClusterElectricalMeasurementAttributeRmsVoltageMinPhaseBID = 2310
    case MTRClusterElectricalMeasurementAttributeRmsVoltageMaxPhaseBID = 2311
    case MTRClusterElectricalMeasurementAttributeRmsCurrentPhaseBID = 2312
    case MTRClusterElectricalMeasurementAttributeRmsCurrentMinPhaseBID = 2313
    case MTRClusterElectricalMeasurementAttributeRmsCurrentMaxPhaseBID = 2314
    case MTRClusterElectricalMeasurementAttributeActivePowerPhaseBID = 2315
    case MTRClusterElectricalMeasurementAttributeActivePowerMinPhaseBID = 2316
    case MTRClusterElectricalMeasurementAttributeActivePowerMaxPhaseBID = 2317
    case MTRClusterElectricalMeasurementAttributeReactivePowerPhaseBID = 2318
    case MTRClusterElectricalMeasurementAttributeApparentPowerPhaseBID = 2319
    case MTRClusterElectricalMeasurementAttributePowerFactorPhaseBID = 2320
    case MTRClusterElectricalMeasurementAttributeAverageRmsVoltageMeasurementPeriodPhaseBID = 2321
    case MTRClusterElectricalMeasurementAttributeAverageRmsOverVoltageCounterPhaseBID = 2322
    case MTRClusterElectricalMeasurementAttributeAverageRmsUnderVoltageCounterPhaseBID = 2323
    case MTRClusterElectricalMeasurementAttributeRmsExtremeOverVoltagePeriodPhaseBID = 2324
    case MTRClusterElectricalMeasurementAttributeRmsExtremeUnderVoltagePeriodPhaseBID = 2325
    case MTRClusterElectricalMeasurementAttributeRmsVoltageSagPeriodPhaseBID = 2326
    case MTRClusterElectricalMeasurementAttributeRmsVoltageSwellPeriodPhaseBID = 2327
    case MTRClusterElectricalMeasurementAttributeLineCurrentPhaseCID = 2561
    case MTRClusterElectricalMeasurementAttributeActiveCurrentPhaseCID = 2562
    case MTRClusterElectricalMeasurementAttributeReactiveCurrentPhaseCID = 2563
    case MTRClusterElectricalMeasurementAttributeRmsVoltagePhaseCID = 2565
    case MTRClusterElectricalMeasurementAttributeRmsVoltageMinPhaseCID = 2566
    case MTRClusterElectricalMeasurementAttributeRmsVoltageMaxPhaseCID = 2567
    case MTRClusterElectricalMeasurementAttributeRmsCurrentPhaseCID = 2568
    case MTRClusterElectricalMeasurementAttributeRmsCurrentMinPhaseCID = 2569
    case MTRClusterElectricalMeasurementAttributeRmsCurrentMaxPhaseCID = 2570
    case MTRClusterElectricalMeasurementAttributeActivePowerPhaseCID = 2571
    case MTRClusterElectricalMeasurementAttributeActivePowerMinPhaseCID = 2572
    case MTRClusterElectricalMeasurementAttributeActivePowerMaxPhaseCID = 2573
    case MTRClusterElectricalMeasurementAttributeReactivePowerPhaseCID = 2574
    case MTRClusterElectricalMeasurementAttributeApparentPowerPhaseCID = 2575
    case MTRClusterElectricalMeasurementAttributePowerFactorPhaseCID = 2576
    case MTRClusterElectricalMeasurementAttributeAverageRmsVoltageMeasurementPeriodPhaseCID = 2577
    case MTRClusterElectricalMeasurementAttributeAverageRmsOverVoltageCounterPhaseCID = 2578
    case MTRClusterElectricalMeasurementAttributeAverageRmsUnderVoltageCounterPhaseCID = 2579
    case MTRClusterElectricalMeasurementAttributeRmsExtremeOverVoltagePeriodPhaseCID = 2580
    case MTRClusterElectricalMeasurementAttributeRmsExtremeUnderVoltagePeriodPhaseCID = 2581
    case MTRClusterElectricalMeasurementAttributeRmsVoltageSagPeriodPhaseCID = 2582
    case MTRClusterElectricalMeasurementAttributeRmsVoltageSwellPeriodPhaseCID = 2583
    public static var globalAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var globalAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var globalAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var globalAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var globalAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterIdentifyAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterIdentifyAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterIdentifyAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterIdentifyAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterIdentifyAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterIdentifyAttributeIdentifyTimeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterIdentifyAttributeIdentifyTypeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterIdentifyAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterIdentifyAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterIdentifyAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterIdentifyAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterIdentifyAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterGroupsAttributeNameSupportID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterGroupsAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterGroupsAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterGroupsAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterGroupsAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterGroupsAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterGroupsAttributeNameSupportID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterGroupsAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterGroupsAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterGroupsAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterGroupsAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterGroupsAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterOnOffAttributeOnOffID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterOnOffAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterOnOffAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterOnOffAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterOnOffAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterOnOffAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterOnOffAttributeOnOffID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterOnOffAttributeGlobalSceneControlID: MTRAttributeIDType { .MTRClusterOnOffAttributeGlobalSceneControlID }
    public static var clusterOnOffAttributeOnTimeID: MTRAttributeIDType { .MTRClusterOnOffAttributeOnTimeID }
    public static var clusterOnOffAttributeOffWaitTimeID: MTRAttributeIDType { .MTRClusterOnOffAttributeOffWaitTimeID }
    public static var clusterOnOffAttributeStartUpOnOffID: MTRAttributeIDType { .MTRClusterOnOffAttributeStartUpOnOffID }
    public static var clusterOnOffAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterOnOffAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterOnOffAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterOnOffAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterOnOffAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterLevelControlAttributeCurrentLevelID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterLevelControlAttributeRemainingTimeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterLevelControlAttributeStartUpCurrentLevelID: MTRAttributeIDType { .MTRClusterOnOffAttributeGlobalSceneControlID }
    public static var MTRClusterLevelControlAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterLevelControlAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterLevelControlAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterLevelControlAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterLevelControlAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterLevelControlAttributeCurrentLevelID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterLevelControlAttributeRemainingTimeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterLevelControlAttributeMinLevelID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterLevelControlAttributeMaxLevelID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterLevelControlAttributeCurrentFrequencyID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterLevelControlAttributeMinFrequencyID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterLevelControlAttributeMaxFrequencyID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterLevelControlAttributeOptionsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOptionsID }
    public static var clusterLevelControlAttributeOnOffTransitionTimeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var clusterLevelControlAttributeOnLevelID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var clusterLevelControlAttributeOnTransitionTimeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var clusterLevelControlAttributeOffTransitionTimeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOffTransitionTimeID }
    public static var clusterLevelControlAttributeDefaultMoveRateID: MTRAttributeIDType { .MTRClusterLevelControlAttributeDefaultMoveRateID }
    public static var clusterLevelControlAttributeStartUpCurrentLevelID: MTRAttributeIDType { .MTRClusterOnOffAttributeGlobalSceneControlID }
    public static var clusterLevelControlAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterLevelControlAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterLevelControlAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterLevelControlAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterLevelControlAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterPulseWidthModulationAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterPulseWidthModulationAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterPulseWidthModulationAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterPulseWidthModulationAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterPulseWidthModulationAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterPulseWidthModulationAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterPulseWidthModulationAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterPulseWidthModulationAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterPulseWidthModulationAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterPulseWidthModulationAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterDescriptorAttributeDeviceTypeListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterDescriptorAttributeDeviceListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterDescriptorAttributeServerListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterDescriptorAttributeClientListID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterDescriptorAttributePartsListID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterDescriptorAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterDescriptorAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterDescriptorAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterDescriptorAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterDescriptorAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterDescriptorAttributeDeviceTypeListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterDescriptorAttributeServerListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterDescriptorAttributeClientListID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterDescriptorAttributePartsListID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterDescriptorAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterDescriptorAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterDescriptorAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterDescriptorAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterDescriptorAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterBindingAttributeBindingID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterBindingAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterBindingAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterBindingAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterBindingAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterBindingAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterBindingAttributeBindingID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterBindingAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterBindingAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterBindingAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterBindingAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterBindingAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterAccessControlAttributeAclID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterAccessControlAttributeExtensionID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterAccessControlAttributeSubjectsPerAccessControlEntryID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterAccessControlAttributeTargetsPerAccessControlEntryID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterAccessControlAttributeAccessControlEntriesPerFabricID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterAccessControlAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterAccessControlAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterAccessControlAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterAccessControlAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterAccessControlAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterAccessControlAttributeACLID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterAccessControlAttributeExtensionID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterAccessControlAttributeSubjectsPerAccessControlEntryID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterAccessControlAttributeTargetsPerAccessControlEntryID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterAccessControlAttributeAccessControlEntriesPerFabricID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterAccessControlAttributeCommissioningARLID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterAccessControlAttributeARLID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterAccessControlAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterAccessControlAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterAccessControlAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterAccessControlAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterAccessControlAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterActionsAttributeActionListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterActionsAttributeEndpointListsID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterActionsAttributeSetupURLID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterActionsAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterActionsAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterActionsAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterActionsAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterActionsAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterActionsAttributeActionListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterActionsAttributeEndpointListsID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterActionsAttributeSetupURLID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterActionsAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterActionsAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterActionsAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterActionsAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterActionsAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterBasicAttributeDataModelRevisionID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterBasicAttributeVendorNameID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterBasicAttributeVendorIDID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterBasicAttributeProductNameID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterBasicAttributeProductIDID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterBasicAttributeNodeLabelID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var MTRClusterBasicAttributeLocationID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var MTRClusterBasicAttributeSerialNumberID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOptionsID }
    public static var MTRClusterBasicAttributeLocalConfigDisabledID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var MTRClusterBasicAttributeReachableID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var MTRClusterBasicAttributeUniqueIDID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var MTRClusterBasicAttributeCapabilityMinimaID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOffTransitionTimeID }
    public static var MTRClusterBasicAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterBasicAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterBasicAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterBasicAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterBasicAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterBasicInformationAttributeDataModelRevisionID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterBasicInformationAttributeVendorNameID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterBasicInformationAttributeVendorIDID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterBasicInformationAttributeProductNameID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterBasicInformationAttributeProductIDID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterBasicInformationAttributeNodeLabelID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterBasicInformationAttributeLocationID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterBasicInformationAttributeHardwareVersionID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterBasicInformationAttributeHardwareVersionStringID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterBasicInformationAttributeSoftwareVersionID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterBasicInformationAttributeSoftwareVersionStringID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterBasicInformationAttributeManufacturingDateID: MTRAttributeIDType { .MTRClusterBasicAttributeManufacturingDateID }
    public static var clusterBasicInformationAttributePartNumberID: MTRAttributeIDType { .MTRClusterBasicAttributePartNumberID }
    public static var clusterBasicInformationAttributeProductURLID: MTRAttributeIDType { .MTRClusterBasicAttributeProductURLID }
    public static var clusterBasicInformationAttributeProductLabelID: MTRAttributeIDType { .MTRClusterBasicAttributeProductLabelID }
    public static var clusterBasicInformationAttributeSerialNumberID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOptionsID }
    public static var clusterBasicInformationAttributeLocalConfigDisabledID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var clusterBasicInformationAttributeReachableID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var clusterBasicInformationAttributeUniqueIDID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var clusterBasicInformationAttributeCapabilityMinimaID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOffTransitionTimeID }
    public static var clusterBasicInformationAttributeProductAppearanceID: MTRAttributeIDType { .MTRClusterLevelControlAttributeDefaultMoveRateID }
    public static var clusterBasicInformationAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterBasicInformationAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterBasicInformationAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterBasicInformationAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterBasicInformationAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterOtaSoftwareUpdateProviderAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterOtaSoftwareUpdateProviderAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterOtaSoftwareUpdateProviderAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterOtaSoftwareUpdateProviderAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterOtaSoftwareUpdateProviderAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterOTASoftwareUpdateProviderAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterOTASoftwareUpdateProviderAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterOTASoftwareUpdateProviderAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterOTASoftwareUpdateProviderAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterOTASoftwareUpdateProviderAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterOtaSoftwareUpdateRequestorAttributeDefaultOtaProvidersID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterOtaSoftwareUpdateRequestorAttributeUpdatePossibleID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterOtaSoftwareUpdateRequestorAttributeUpdateStateID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterOtaSoftwareUpdateRequestorAttributeUpdateStateProgressID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterOtaSoftwareUpdateRequestorAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterOtaSoftwareUpdateRequestorAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterOtaSoftwareUpdateRequestorAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterOtaSoftwareUpdateRequestorAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterOtaSoftwareUpdateRequestorAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterOTASoftwareUpdateRequestorAttributeDefaultOTAProvidersID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterOTASoftwareUpdateRequestorAttributeUpdatePossibleID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterOTASoftwareUpdateRequestorAttributeUpdateStateID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterOTASoftwareUpdateRequestorAttributeUpdateStateProgressID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterOTASoftwareUpdateRequestorAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterOTASoftwareUpdateRequestorAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterOTASoftwareUpdateRequestorAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterOTASoftwareUpdateRequestorAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterOTASoftwareUpdateRequestorAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterLocalizationConfigurationAttributeActiveLocaleID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterLocalizationConfigurationAttributeSupportedLocalesID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterLocalizationConfigurationAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterLocalizationConfigurationAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterLocalizationConfigurationAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterLocalizationConfigurationAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterLocalizationConfigurationAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterLocalizationConfigurationAttributeActiveLocaleID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterLocalizationConfigurationAttributeSupportedLocalesID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterLocalizationConfigurationAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterLocalizationConfigurationAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterLocalizationConfigurationAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterLocalizationConfigurationAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterLocalizationConfigurationAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterTimeFormatLocalizationAttributeHourFormatID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterTimeFormatLocalizationAttributeActiveCalendarTypeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterTimeFormatLocalizationAttributeSupportedCalendarTypesID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterTimeFormatLocalizationAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterTimeFormatLocalizationAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterTimeFormatLocalizationAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterTimeFormatLocalizationAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterTimeFormatLocalizationAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterTimeFormatLocalizationAttributeHourFormatID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterTimeFormatLocalizationAttributeActiveCalendarTypeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterTimeFormatLocalizationAttributeSupportedCalendarTypesID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterTimeFormatLocalizationAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterTimeFormatLocalizationAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterTimeFormatLocalizationAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterTimeFormatLocalizationAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterTimeFormatLocalizationAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterUnitLocalizationAttributeTemperatureUnitID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterUnitLocalizationAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterUnitLocalizationAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterUnitLocalizationAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterUnitLocalizationAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterUnitLocalizationAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterUnitLocalizationAttributeTemperatureUnitID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterUnitLocalizationAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterUnitLocalizationAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterUnitLocalizationAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterUnitLocalizationAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterUnitLocalizationAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterPowerSourceConfigurationAttributeSourcesID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterPowerSourceConfigurationAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterPowerSourceConfigurationAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterPowerSourceConfigurationAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterPowerSourceConfigurationAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterPowerSourceConfigurationAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterPowerSourceConfigurationAttributeSourcesID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterPowerSourceConfigurationAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterPowerSourceConfigurationAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterPowerSourceConfigurationAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterPowerSourceConfigurationAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterPowerSourceConfigurationAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterPowerSourceAttributeStatusID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterPowerSourceAttributeOrderID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterPowerSourceAttributeDescriptionID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterPowerSourceAttributeWiredAssessedInputVoltageID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterPowerSourceAttributeWiredAssessedInputFrequencyID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterPowerSourceAttributeWiredCurrentTypeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var MTRClusterPowerSourceAttributeWiredAssessedCurrentID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var MTRClusterPowerSourceAttributeWiredNominalVoltageID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var MTRClusterPowerSourceAttributeWiredMaximumCurrentID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var MTRClusterPowerSourceAttributeWiredPresentID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var MTRClusterPowerSourceAttributeActiveWiredFaultsID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var MTRClusterPowerSourceAttributeBatVoltageID: MTRAttributeIDType { .MTRClusterBasicAttributeManufacturingDateID }
    public static var MTRClusterPowerSourceAttributeBatPercentRemainingID: MTRAttributeIDType { .MTRClusterBasicAttributePartNumberID }
    public static var MTRClusterPowerSourceAttributeBatTimeRemainingID: MTRAttributeIDType { .MTRClusterBasicAttributeProductURLID }
    public static var MTRClusterPowerSourceAttributeBatChargeLevelID: MTRAttributeIDType { .MTRClusterBasicAttributeProductLabelID }
    public static var MTRClusterPowerSourceAttributeBatReplacementNeededID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOptionsID }
    public static var MTRClusterPowerSourceAttributeBatReplaceabilityID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var MTRClusterPowerSourceAttributeBatPresentID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var MTRClusterPowerSourceAttributeActiveBatFaultsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var MTRClusterPowerSourceAttributeBatReplacementDescriptionID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOffTransitionTimeID }
    public static var MTRClusterPowerSourceAttributeBatCommonDesignationID: MTRAttributeIDType { .MTRClusterLevelControlAttributeDefaultMoveRateID }
    public static var MTRClusterPowerSourceAttributeBatANSIDesignationID: MTRAttributeIDType { .clusterBasicInformationAttributeSpecificationVersionID }
    public static var MTRClusterPowerSourceAttributeBatIECDesignationID: MTRAttributeIDType { .clusterBasicInformationAttributeMaxPathsPerInvokeID }
    public static var MTRClusterPowerSourceAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterPowerSourceAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterPowerSourceAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterPowerSourceAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterPowerSourceAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterPowerSourceAttributeStatusID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterPowerSourceAttributeOrderID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterPowerSourceAttributeDescriptionID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterPowerSourceAttributeWiredAssessedInputVoltageID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterPowerSourceAttributeWiredAssessedInputFrequencyID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterPowerSourceAttributeWiredCurrentTypeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterPowerSourceAttributeWiredAssessedCurrentID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterPowerSourceAttributeWiredNominalVoltageID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterPowerSourceAttributeWiredMaximumCurrentID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterPowerSourceAttributeWiredPresentID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterPowerSourceAttributeActiveWiredFaultsID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterPowerSourceAttributeBatVoltageID: MTRAttributeIDType { .MTRClusterBasicAttributeManufacturingDateID }
    public static var clusterPowerSourceAttributeBatPercentRemainingID: MTRAttributeIDType { .MTRClusterBasicAttributePartNumberID }
    public static var clusterPowerSourceAttributeBatTimeRemainingID: MTRAttributeIDType { .MTRClusterBasicAttributeProductURLID }
    public static var clusterPowerSourceAttributeBatChargeLevelID: MTRAttributeIDType { .MTRClusterBasicAttributeProductLabelID }
    public static var clusterPowerSourceAttributeBatReplacementNeededID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOptionsID }
    public static var clusterPowerSourceAttributeBatReplaceabilityID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var clusterPowerSourceAttributeBatPresentID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var clusterPowerSourceAttributeActiveBatFaultsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var clusterPowerSourceAttributeBatReplacementDescriptionID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOffTransitionTimeID }
    public static var clusterPowerSourceAttributeBatCommonDesignationID: MTRAttributeIDType { .MTRClusterLevelControlAttributeDefaultMoveRateID }
    public static var clusterPowerSourceAttributeBatANSIDesignationID: MTRAttributeIDType { .clusterBasicInformationAttributeSpecificationVersionID }
    public static var clusterPowerSourceAttributeBatIECDesignationID: MTRAttributeIDType { .clusterBasicInformationAttributeMaxPathsPerInvokeID }
    public static var clusterPowerSourceAttributeBatApprovedChemistryID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatApprovedChemistryID }
    public static var clusterPowerSourceAttributeBatCapacityID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatCapacityID }
    public static var clusterPowerSourceAttributeBatQuantityID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatQuantityID }
    public static var clusterPowerSourceAttributeBatChargeStateID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatChargeStateID }
    public static var clusterPowerSourceAttributeBatTimeToFullChargeID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatTimeToFullChargeID }
    public static var clusterPowerSourceAttributeBatFunctionalWhileChargingID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatFunctionalWhileChargingID }
    public static var clusterPowerSourceAttributeBatChargingCurrentID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatChargingCurrentID }
    public static var clusterPowerSourceAttributeActiveBatChargeFaultsID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeActiveBatChargeFaultsID }
    public static var clusterPowerSourceAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterPowerSourceAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterPowerSourceAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterPowerSourceAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterPowerSourceAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterGeneralCommissioningAttributeBreadcrumbID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterGeneralCommissioningAttributeBasicCommissioningInfoID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterGeneralCommissioningAttributeRegulatoryConfigID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterGeneralCommissioningAttributeLocationCapabilityID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterGeneralCommissioningAttributeSupportsConcurrentConnectionID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterGeneralCommissioningAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterGeneralCommissioningAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterGeneralCommissioningAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterGeneralCommissioningAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterGeneralCommissioningAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterGeneralCommissioningAttributeBreadcrumbID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterGeneralCommissioningAttributeBasicCommissioningInfoID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterGeneralCommissioningAttributeRegulatoryConfigID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterGeneralCommissioningAttributeLocationCapabilityID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterGeneralCommissioningAttributeSupportsConcurrentConnectionID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterGeneralCommissioningAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterGeneralCommissioningAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterGeneralCommissioningAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterGeneralCommissioningAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterGeneralCommissioningAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterNetworkCommissioningAttributeMaxNetworksID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterNetworkCommissioningAttributeNetworksID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterNetworkCommissioningAttributeScanMaxTimeSecondsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterNetworkCommissioningAttributeConnectMaxTimeSecondsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterNetworkCommissioningAttributeInterfaceEnabledID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterNetworkCommissioningAttributeLastNetworkingStatusID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var MTRClusterNetworkCommissioningAttributeLastNetworkIDID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var MTRClusterNetworkCommissioningAttributeLastConnectErrorValueID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var MTRClusterNetworkCommissioningAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterNetworkCommissioningAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterNetworkCommissioningAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterNetworkCommissioningAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterNetworkCommissioningAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterNetworkCommissioningAttributeMaxNetworksID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterNetworkCommissioningAttributeNetworksID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterNetworkCommissioningAttributeScanMaxTimeSecondsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterNetworkCommissioningAttributeConnectMaxTimeSecondsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterNetworkCommissioningAttributeInterfaceEnabledID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterNetworkCommissioningAttributeLastNetworkingStatusID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterNetworkCommissioningAttributeLastNetworkIDID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterNetworkCommissioningAttributeLastConnectErrorValueID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterNetworkCommissioningAttributeSupportedWiFiBandsID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterNetworkCommissioningAttributeSupportedThreadFeaturesID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterNetworkCommissioningAttributeThreadVersionID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterNetworkCommissioningAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterNetworkCommissioningAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterNetworkCommissioningAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterNetworkCommissioningAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterNetworkCommissioningAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterDiagnosticLogsAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterDiagnosticLogsAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterDiagnosticLogsAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterDiagnosticLogsAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterDiagnosticLogsAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterDiagnosticLogsAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterDiagnosticLogsAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterDiagnosticLogsAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterDiagnosticLogsAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterDiagnosticLogsAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterGeneralDiagnosticsAttributeNetworkInterfacesID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterGeneralDiagnosticsAttributeRebootCountID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterGeneralDiagnosticsAttributeUpTimeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterGeneralDiagnosticsAttributeTotalOperationalHoursID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterGeneralDiagnosticsAttributeBootReasonsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterGeneralDiagnosticsAttributeActiveHardwareFaultsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var MTRClusterGeneralDiagnosticsAttributeActiveRadioFaultsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var MTRClusterGeneralDiagnosticsAttributeActiveNetworkFaultsID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var MTRClusterGeneralDiagnosticsAttributeTestEventTriggersEnabledID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var MTRClusterGeneralDiagnosticsAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterGeneralDiagnosticsAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterGeneralDiagnosticsAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterGeneralDiagnosticsAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterGeneralDiagnosticsAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterGeneralDiagnosticsAttributeNetworkInterfacesID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterGeneralDiagnosticsAttributeRebootCountID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterGeneralDiagnosticsAttributeUpTimeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterGeneralDiagnosticsAttributeTotalOperationalHoursID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterGeneralDiagnosticsAttributeBootReasonID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterGeneralDiagnosticsAttributeActiveHardwareFaultsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterGeneralDiagnosticsAttributeActiveRadioFaultsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterGeneralDiagnosticsAttributeActiveNetworkFaultsID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterGeneralDiagnosticsAttributeTestEventTriggersEnabledID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterGeneralDiagnosticsAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterGeneralDiagnosticsAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterGeneralDiagnosticsAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterGeneralDiagnosticsAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterGeneralDiagnosticsAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterSoftwareDiagnosticsAttributeThreadMetricsID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterSoftwareDiagnosticsAttributeCurrentHeapFreeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterSoftwareDiagnosticsAttributeCurrentHeapUsedID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterSoftwareDiagnosticsAttributeCurrentHeapHighWatermarkID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterSoftwareDiagnosticsAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterSoftwareDiagnosticsAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterSoftwareDiagnosticsAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterSoftwareDiagnosticsAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterSoftwareDiagnosticsAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterSoftwareDiagnosticsAttributeThreadMetricsID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterSoftwareDiagnosticsAttributeCurrentHeapFreeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterSoftwareDiagnosticsAttributeCurrentHeapUsedID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterSoftwareDiagnosticsAttributeCurrentHeapHighWatermarkID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterSoftwareDiagnosticsAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterSoftwareDiagnosticsAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterSoftwareDiagnosticsAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterSoftwareDiagnosticsAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterSoftwareDiagnosticsAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeChannelID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeRoutingRoleID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeNetworkNameID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributePanIdID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeExtendedPanIdID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeMeshLocalPrefixID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeOverrunCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeNeighborTableListID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeRouteTableListID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributePartitionIdID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeWeightingID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeDataVersionID: MTRAttributeIDType { .MTRClusterBasicAttributeManufacturingDateID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeStableDataVersionID: MTRAttributeIDType { .MTRClusterBasicAttributePartNumberID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeLeaderRouterIdID: MTRAttributeIDType { .MTRClusterBasicAttributeProductURLID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeDetachedRoleCountID: MTRAttributeIDType { .MTRClusterBasicAttributeProductLabelID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeChildRoleCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOptionsID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeRouterRoleCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeLeaderRoleCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeAttachAttemptCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributePartitionIdChangeCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOffTransitionTimeID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeBetterPartitionAttachAttemptCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeDefaultMoveRateID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeParentChangeCountID: MTRAttributeIDType { .clusterBasicInformationAttributeSpecificationVersionID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeTxTotalCountID: MTRAttributeIDType { .clusterBasicInformationAttributeMaxPathsPerInvokeID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeTxUnicastCountID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatApprovedChemistryID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeTxBroadcastCountID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatCapacityID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeTxAckRequestedCountID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatQuantityID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeTxAckedCountID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatChargeStateID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeTxNoAckRequestedCountID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatTimeToFullChargeID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeTxDataCountID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatFunctionalWhileChargingID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeTxDataPollCountID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatChargingCurrentID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeTxBeaconCountID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeActiveBatChargeFaultsID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeTxBeaconRequestCountID: MTRAttributeIDType { .clusterPowerSourceAttributeEndpointListID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterThreadNetworkDiagnosticsAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterThreadNetworkDiagnosticsAttributeChannelID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterThreadNetworkDiagnosticsAttributeRoutingRoleID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterThreadNetworkDiagnosticsAttributeNetworkNameID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterThreadNetworkDiagnosticsAttributePanIdID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterThreadNetworkDiagnosticsAttributeExtendedPanIdID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterThreadNetworkDiagnosticsAttributeMeshLocalPrefixID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterThreadNetworkDiagnosticsAttributeOverrunCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterThreadNetworkDiagnosticsAttributeNeighborTableID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterThreadNetworkDiagnosticsAttributeRouteTableID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterThreadNetworkDiagnosticsAttributePartitionIdID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterThreadNetworkDiagnosticsAttributeWeightingID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterThreadNetworkDiagnosticsAttributeDataVersionID: MTRAttributeIDType { .MTRClusterBasicAttributeManufacturingDateID }
    public static var clusterThreadNetworkDiagnosticsAttributeStableDataVersionID: MTRAttributeIDType { .MTRClusterBasicAttributePartNumberID }
    public static var clusterThreadNetworkDiagnosticsAttributeLeaderRouterIdID: MTRAttributeIDType { .MTRClusterBasicAttributeProductURLID }
    public static var clusterThreadNetworkDiagnosticsAttributeDetachedRoleCountID: MTRAttributeIDType { .MTRClusterBasicAttributeProductLabelID }
    public static var clusterThreadNetworkDiagnosticsAttributeChildRoleCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOptionsID }
    public static var clusterThreadNetworkDiagnosticsAttributeRouterRoleCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var clusterThreadNetworkDiagnosticsAttributeLeaderRoleCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var clusterThreadNetworkDiagnosticsAttributeAttachAttemptCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var clusterThreadNetworkDiagnosticsAttributePartitionIdChangeCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOffTransitionTimeID }
    public static var clusterThreadNetworkDiagnosticsAttributeBetterPartitionAttachAttemptCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeDefaultMoveRateID }
    public static var clusterThreadNetworkDiagnosticsAttributeParentChangeCountID: MTRAttributeIDType { .clusterBasicInformationAttributeSpecificationVersionID }
    public static var clusterThreadNetworkDiagnosticsAttributeTxTotalCountID: MTRAttributeIDType { .clusterBasicInformationAttributeMaxPathsPerInvokeID }
    public static var clusterThreadNetworkDiagnosticsAttributeTxUnicastCountID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatApprovedChemistryID }
    public static var clusterThreadNetworkDiagnosticsAttributeTxBroadcastCountID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatCapacityID }
    public static var clusterThreadNetworkDiagnosticsAttributeTxAckRequestedCountID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatQuantityID }
    public static var clusterThreadNetworkDiagnosticsAttributeTxAckedCountID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatChargeStateID }
    public static var clusterThreadNetworkDiagnosticsAttributeTxNoAckRequestedCountID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatTimeToFullChargeID }
    public static var clusterThreadNetworkDiagnosticsAttributeTxDataCountID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatFunctionalWhileChargingID }
    public static var clusterThreadNetworkDiagnosticsAttributeTxDataPollCountID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatChargingCurrentID }
    public static var clusterThreadNetworkDiagnosticsAttributeTxBeaconCountID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeActiveBatChargeFaultsID }
    public static var clusterThreadNetworkDiagnosticsAttributeTxBeaconRequestCountID: MTRAttributeIDType { .clusterPowerSourceAttributeEndpointListID }
    public static var clusterThreadNetworkDiagnosticsAttributeTxOtherCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxOtherCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeTxRetryCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxRetryCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeTxDirectMaxRetryExpiryCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxDirectMaxRetryExpiryCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeTxIndirectMaxRetryExpiryCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxIndirectMaxRetryExpiryCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeTxErrCcaCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrCcaCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeTxErrAbortCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrAbortCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeTxErrBusyChannelCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrBusyChannelCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeRxTotalCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxTotalCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeRxUnicastCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxUnicastCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeRxBroadcastCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxBroadcastCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeRxDataCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDataCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeRxDataPollCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDataPollCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeRxBeaconCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxBeaconCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeRxBeaconRequestCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxBeaconRequestCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeRxOtherCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxOtherCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeRxAddressFilteredCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxAddressFilteredCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeRxDestAddrFilteredCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDestAddrFilteredCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeRxDuplicatedCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDuplicatedCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeRxErrNoFrameCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrNoFrameCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeRxErrUnknownNeighborCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrUnknownNeighborCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeRxErrInvalidSrcAddrCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrInvalidSrcAddrCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeRxErrSecCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrSecCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeRxErrFcsCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrFcsCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeRxErrOtherCountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrOtherCountID }
    public static var clusterThreadNetworkDiagnosticsAttributeActiveTimestampID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeActiveTimestampID }
    public static var clusterThreadNetworkDiagnosticsAttributePendingTimestampID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributePendingTimestampID }
    public static var clusterThreadNetworkDiagnosticsAttributeDelayID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeDelayID }
    public static var clusterThreadNetworkDiagnosticsAttributeSecurityPolicyID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeSecurityPolicyID }
    public static var clusterThreadNetworkDiagnosticsAttributeChannelPage0MaskID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeChannelPage0MaskID }
    public static var clusterThreadNetworkDiagnosticsAttributeOperationalDatasetComponentsID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeOperationalDatasetComponentsID }
    public static var clusterThreadNetworkDiagnosticsAttributeActiveNetworkFaultsListID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeActiveNetworkFaultsListID }
    public static var clusterThreadNetworkDiagnosticsAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterThreadNetworkDiagnosticsAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterThreadNetworkDiagnosticsAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterThreadNetworkDiagnosticsAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterThreadNetworkDiagnosticsAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterWiFiNetworkDiagnosticsAttributeBssidID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterWiFiNetworkDiagnosticsAttributeSecurityTypeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterWiFiNetworkDiagnosticsAttributeWiFiVersionID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterWiFiNetworkDiagnosticsAttributeChannelNumberID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterWiFiNetworkDiagnosticsAttributeRssiID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterWiFiNetworkDiagnosticsAttributeBeaconLostCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var MTRClusterWiFiNetworkDiagnosticsAttributeBeaconRxCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var MTRClusterWiFiNetworkDiagnosticsAttributePacketMulticastRxCountID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var MTRClusterWiFiNetworkDiagnosticsAttributePacketMulticastTxCountID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var MTRClusterWiFiNetworkDiagnosticsAttributePacketUnicastRxCountID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var MTRClusterWiFiNetworkDiagnosticsAttributePacketUnicastTxCountID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var MTRClusterWiFiNetworkDiagnosticsAttributeCurrentMaxRateID: MTRAttributeIDType { .MTRClusterBasicAttributeManufacturingDateID }
    public static var MTRClusterWiFiNetworkDiagnosticsAttributeOverrunCountID: MTRAttributeIDType { .MTRClusterBasicAttributePartNumberID }
    public static var MTRClusterWiFiNetworkDiagnosticsAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterWiFiNetworkDiagnosticsAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterWiFiNetworkDiagnosticsAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterWiFiNetworkDiagnosticsAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterWiFiNetworkDiagnosticsAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterWiFiNetworkDiagnosticsAttributeBSSIDID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterWiFiNetworkDiagnosticsAttributeSecurityTypeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterWiFiNetworkDiagnosticsAttributeWiFiVersionID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterWiFiNetworkDiagnosticsAttributeChannelNumberID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterWiFiNetworkDiagnosticsAttributeRSSIID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterWiFiNetworkDiagnosticsAttributeBeaconLostCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterWiFiNetworkDiagnosticsAttributeBeaconRxCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterWiFiNetworkDiagnosticsAttributePacketMulticastRxCountID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterWiFiNetworkDiagnosticsAttributePacketMulticastTxCountID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterWiFiNetworkDiagnosticsAttributePacketUnicastRxCountID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterWiFiNetworkDiagnosticsAttributePacketUnicastTxCountID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterWiFiNetworkDiagnosticsAttributeCurrentMaxRateID: MTRAttributeIDType { .MTRClusterBasicAttributeManufacturingDateID }
    public static var clusterWiFiNetworkDiagnosticsAttributeOverrunCountID: MTRAttributeIDType { .MTRClusterBasicAttributePartNumberID }
    public static var clusterWiFiNetworkDiagnosticsAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterWiFiNetworkDiagnosticsAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterWiFiNetworkDiagnosticsAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterWiFiNetworkDiagnosticsAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterWiFiNetworkDiagnosticsAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterEthernetNetworkDiagnosticsAttributePHYRateID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterEthernetNetworkDiagnosticsAttributeFullDuplexID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterEthernetNetworkDiagnosticsAttributePacketRxCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterEthernetNetworkDiagnosticsAttributePacketTxCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterEthernetNetworkDiagnosticsAttributeTxErrCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterEthernetNetworkDiagnosticsAttributeCollisionCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var MTRClusterEthernetNetworkDiagnosticsAttributeOverrunCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var MTRClusterEthernetNetworkDiagnosticsAttributeCarrierDetectID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var MTRClusterEthernetNetworkDiagnosticsAttributeTimeSinceResetID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var MTRClusterEthernetNetworkDiagnosticsAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterEthernetNetworkDiagnosticsAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterEthernetNetworkDiagnosticsAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterEthernetNetworkDiagnosticsAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterEthernetNetworkDiagnosticsAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterEthernetNetworkDiagnosticsAttributePHYRateID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterEthernetNetworkDiagnosticsAttributeFullDuplexID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterEthernetNetworkDiagnosticsAttributePacketRxCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterEthernetNetworkDiagnosticsAttributePacketTxCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterEthernetNetworkDiagnosticsAttributeTxErrCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterEthernetNetworkDiagnosticsAttributeCollisionCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterEthernetNetworkDiagnosticsAttributeOverrunCountID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterEthernetNetworkDiagnosticsAttributeCarrierDetectID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterEthernetNetworkDiagnosticsAttributeTimeSinceResetID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterEthernetNetworkDiagnosticsAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterEthernetNetworkDiagnosticsAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterEthernetNetworkDiagnosticsAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterEthernetNetworkDiagnosticsAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterEthernetNetworkDiagnosticsAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterTimeSynchronizationAttributeUTCTimeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterTimeSynchronizationAttributeGranularityID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterTimeSynchronizationAttributeTimeSourceID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterTimeSynchronizationAttributeTrustedTimeNodeIdID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterTimeSynchronizationAttributeDefaultNtpID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterTimeSynchronizationAttributeTimeZoneID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var MTRClusterTimeSynchronizationAttributeDstOffsetID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var MTRClusterTimeSynchronizationAttributeLocalTimeID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var MTRClusterTimeSynchronizationAttributeTimeZoneDatabaseID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var MTRClusterTimeSynchronizationAttributeNtpServerPortID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var MTRClusterTimeSynchronizationAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterTimeSynchronizationAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterTimeSynchronizationAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterTimeSynchronizationAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterTimeSynchronizationAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterTimeSynchronizationAttributeUTCTimeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterTimeSynchronizationAttributeGranularityID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterTimeSynchronizationAttributeTimeSourceID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterTimeSynchronizationAttributeTrustedTimeSourceID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterTimeSynchronizationAttributeTrustedTimeNodeIdID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterTimeSynchronizationAttributeDefaultNTPID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterTimeSynchronizationAttributeDefaultNtpID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterTimeSynchronizationAttributeTimeZoneID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterTimeSynchronizationAttributeDSTOffsetID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterTimeSynchronizationAttributeDstOffsetID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterTimeSynchronizationAttributeLocalTimeID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterTimeSynchronizationAttributeTimeZoneDatabaseID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterTimeSynchronizationAttributeNTPServerAvailableID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterTimeSynchronizationAttributeNtpServerPortID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterTimeSynchronizationAttributeTimeZoneListMaxSizeID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterTimeSynchronizationAttributeDSTOffsetListMaxSizeID: MTRAttributeIDType { .MTRClusterBasicAttributeManufacturingDateID }
    public static var clusterTimeSynchronizationAttributeSupportsDNSResolveID: MTRAttributeIDType { .MTRClusterBasicAttributePartNumberID }
    public static var clusterTimeSynchronizationAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterTimeSynchronizationAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterTimeSynchronizationAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterTimeSynchronizationAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterTimeSynchronizationAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterBridgedDeviceBasicAttributeVendorNameID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterBridgedDeviceBasicAttributeVendorIDID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterBridgedDeviceBasicAttributeProductNameID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterBridgedDeviceBasicAttributeNodeLabelID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var MTRClusterBridgedDeviceBasicAttributeHardwareVersionID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var MTRClusterBridgedDeviceBasicAttributeHardwareVersionStringID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var MTRClusterBridgedDeviceBasicAttributeSoftwareVersionID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var MTRClusterBridgedDeviceBasicAttributeSoftwareVersionStringID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var MTRClusterBridgedDeviceBasicAttributeManufacturingDateID: MTRAttributeIDType { .MTRClusterBasicAttributeManufacturingDateID }
    public static var MTRClusterBridgedDeviceBasicAttributePartNumberID: MTRAttributeIDType { .MTRClusterBasicAttributePartNumberID }
    public static var MTRClusterBridgedDeviceBasicAttributeProductURLID: MTRAttributeIDType { .MTRClusterBasicAttributeProductURLID }
    public static var MTRClusterBridgedDeviceBasicAttributeProductLabelID: MTRAttributeIDType { .MTRClusterBasicAttributeProductLabelID }
    public static var MTRClusterBridgedDeviceBasicAttributeSerialNumberID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOptionsID }
    public static var MTRClusterBridgedDeviceBasicAttributeReachableID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var MTRClusterBridgedDeviceBasicAttributeUniqueIDID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var MTRClusterBridgedDeviceBasicAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterBridgedDeviceBasicAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterBridgedDeviceBasicAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterBridgedDeviceBasicAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterBridgedDeviceBasicAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterBridgedDeviceBasicInformationAttributeVendorNameID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterBridgedDeviceBasicInformationAttributeVendorIDID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterBridgedDeviceBasicInformationAttributeProductNameID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterBridgedDeviceBasicInformationAttributeProductIDID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterBridgedDeviceBasicInformationAttributeNodeLabelID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterBridgedDeviceBasicInformationAttributeHardwareVersionID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterBridgedDeviceBasicInformationAttributeHardwareVersionStringID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterBridgedDeviceBasicInformationAttributeSoftwareVersionID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterBridgedDeviceBasicInformationAttributeSoftwareVersionStringID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterBridgedDeviceBasicInformationAttributeManufacturingDateID: MTRAttributeIDType { .MTRClusterBasicAttributeManufacturingDateID }
    public static var clusterBridgedDeviceBasicInformationAttributePartNumberID: MTRAttributeIDType { .MTRClusterBasicAttributePartNumberID }
    public static var clusterBridgedDeviceBasicInformationAttributeProductURLID: MTRAttributeIDType { .MTRClusterBasicAttributeProductURLID }
    public static var clusterBridgedDeviceBasicInformationAttributeProductLabelID: MTRAttributeIDType { .MTRClusterBasicAttributeProductLabelID }
    public static var clusterBridgedDeviceBasicInformationAttributeSerialNumberID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOptionsID }
    public static var clusterBridgedDeviceBasicInformationAttributeReachableID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var clusterBridgedDeviceBasicInformationAttributeUniqueIDID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var clusterBridgedDeviceBasicInformationAttributeProductAppearanceID: MTRAttributeIDType { .MTRClusterLevelControlAttributeDefaultMoveRateID }
    public static var clusterBridgedDeviceBasicInformationAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterBridgedDeviceBasicInformationAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterBridgedDeviceBasicInformationAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterBridgedDeviceBasicInformationAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterBridgedDeviceBasicInformationAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterSwitchAttributeNumberOfPositionsID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterSwitchAttributeCurrentPositionID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterSwitchAttributeMultiPressMaxID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterSwitchAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterSwitchAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterSwitchAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterSwitchAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterSwitchAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterSwitchAttributeNumberOfPositionsID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterSwitchAttributeCurrentPositionID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterSwitchAttributeMultiPressMaxID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterSwitchAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterSwitchAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterSwitchAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterSwitchAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterSwitchAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterAdministratorCommissioningAttributeWindowStatusID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterAdministratorCommissioningAttributeAdminFabricIndexID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterAdministratorCommissioningAttributeAdminVendorIdID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterAdministratorCommissioningAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterAdministratorCommissioningAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterAdministratorCommissioningAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterAdministratorCommissioningAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterAdministratorCommissioningAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterAdministratorCommissioningAttributeWindowStatusID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterAdministratorCommissioningAttributeAdminFabricIndexID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterAdministratorCommissioningAttributeAdminVendorIdID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterAdministratorCommissioningAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterAdministratorCommissioningAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterAdministratorCommissioningAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterAdministratorCommissioningAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterAdministratorCommissioningAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterOperationalCredentialsAttributeNOCsID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterOperationalCredentialsAttributeFabricsID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterOperationalCredentialsAttributeSupportedFabricsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterOperationalCredentialsAttributeCommissionedFabricsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterOperationalCredentialsAttributeTrustedRootCertificatesID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterOperationalCredentialsAttributeCurrentFabricIndexID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var MTRClusterOperationalCredentialsAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterOperationalCredentialsAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterOperationalCredentialsAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterOperationalCredentialsAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterOperationalCredentialsAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterOperationalCredentialsAttributeNOCsID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterOperationalCredentialsAttributeFabricsID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterOperationalCredentialsAttributeSupportedFabricsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterOperationalCredentialsAttributeCommissionedFabricsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterOperationalCredentialsAttributeTrustedRootCertificatesID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterOperationalCredentialsAttributeCurrentFabricIndexID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterOperationalCredentialsAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterOperationalCredentialsAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterOperationalCredentialsAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterOperationalCredentialsAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterOperationalCredentialsAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterGroupKeyManagementAttributeGroupKeyMapID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterGroupKeyManagementAttributeGroupTableID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterGroupKeyManagementAttributeMaxGroupsPerFabricID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterGroupKeyManagementAttributeMaxGroupKeysPerFabricID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterGroupKeyManagementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterGroupKeyManagementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterGroupKeyManagementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterGroupKeyManagementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterGroupKeyManagementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterGroupKeyManagementAttributeGroupKeyMapID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterGroupKeyManagementAttributeGroupTableID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterGroupKeyManagementAttributeMaxGroupsPerFabricID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterGroupKeyManagementAttributeMaxGroupKeysPerFabricID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterGroupKeyManagementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterGroupKeyManagementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterGroupKeyManagementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterGroupKeyManagementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterGroupKeyManagementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterFixedLabelAttributeLabelListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterFixedLabelAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterFixedLabelAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterFixedLabelAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterFixedLabelAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterFixedLabelAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterFixedLabelAttributeLabelListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterFixedLabelAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterFixedLabelAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterFixedLabelAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterFixedLabelAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterFixedLabelAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterUserLabelAttributeLabelListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterUserLabelAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterUserLabelAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterUserLabelAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterUserLabelAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterUserLabelAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterUserLabelAttributeLabelListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterUserLabelAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterUserLabelAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterUserLabelAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterUserLabelAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterUserLabelAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterBooleanStateAttributeStateValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterBooleanStateAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterBooleanStateAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterBooleanStateAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterBooleanStateAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterBooleanStateAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterBooleanStateAttributeStateValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterBooleanStateAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterBooleanStateAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterBooleanStateAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterBooleanStateAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterBooleanStateAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterICDManagementAttributeIdleModeDurationID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterICDManagementAttributeActiveModeDurationID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterICDManagementAttributeActiveModeThresholdID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterICDManagementAttributeRegisteredClientsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterICDManagementAttributeICDCounterID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterICDManagementAttributeClientsSupportedPerFabricID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterICDManagementAttributeUserActiveModeTriggerHintID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterICDManagementAttributeUserActiveModeTriggerInstructionID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterICDManagementAttributeOperatingModeID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterICDManagementAttributeMaximumCheckInBackOffID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterICDManagementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterICDManagementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterICDManagementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterICDManagementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterICDManagementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterOvenCavityOperationalStateAttributePhaseListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterOvenCavityOperationalStateAttributeCurrentPhaseID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterOvenCavityOperationalStateAttributeCountdownTimeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterOvenCavityOperationalStateAttributeOperationalStateListID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterOvenCavityOperationalStateAttributeOperationalStateID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterOvenCavityOperationalStateAttributeOperationalErrorID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterOvenCavityOperationalStateAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterOvenCavityOperationalStateAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterOvenCavityOperationalStateAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterOvenCavityOperationalStateAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterOvenCavityOperationalStateAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterOvenModeAttributeSupportedModesID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterOvenModeAttributeCurrentModeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterOvenModeAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterOvenModeAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterOvenModeAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterOvenModeAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterOvenModeAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterLaundryDryerControlsAttributeSupportedDrynessLevelsID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterLaundryDryerControlsAttributeSelectedDrynessLevelID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterLaundryDryerControlsAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterLaundryDryerControlsAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterLaundryDryerControlsAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterLaundryDryerControlsAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterLaundryDryerControlsAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterModeSelectAttributeDescriptionID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterModeSelectAttributeStandardNamespaceID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterModeSelectAttributeSupportedModesID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterModeSelectAttributeCurrentModeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterModeSelectAttributeStartUpModeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterModeSelectAttributeOnModeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var MTRClusterModeSelectAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterModeSelectAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterModeSelectAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterModeSelectAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterModeSelectAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterModeSelectAttributeDescriptionID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterModeSelectAttributeStandardNamespaceID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterModeSelectAttributeSupportedModesID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterModeSelectAttributeCurrentModeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterModeSelectAttributeStartUpModeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterModeSelectAttributeOnModeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterModeSelectAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterModeSelectAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterModeSelectAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterModeSelectAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterModeSelectAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterLaundryWasherModeAttributeSupportedModesID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterLaundryWasherModeAttributeCurrentModeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterLaundryWasherModeAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterLaundryWasherModeAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterLaundryWasherModeAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterLaundryWasherModeAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterLaundryWasherModeAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterRefrigeratorAndTemperatureControlledCabinetModeAttributeSupportedModesID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterRefrigeratorAndTemperatureControlledCabinetModeAttributeCurrentModeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterRefrigeratorAndTemperatureControlledCabinetModeAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterRefrigeratorAndTemperatureControlledCabinetModeAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterRefrigeratorAndTemperatureControlledCabinetModeAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterRefrigeratorAndTemperatureControlledCabinetModeAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterRefrigeratorAndTemperatureControlledCabinetModeAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterLaundryWasherControlsAttributeSpinSpeedsID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterLaundryWasherControlsAttributeSpinSpeedCurrentID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterLaundryWasherControlsAttributeNumberOfRinsesID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterLaundryWasherControlsAttributeSupportedRinsesID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterLaundryWasherControlsAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterLaundryWasherControlsAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterLaundryWasherControlsAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterLaundryWasherControlsAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterLaundryWasherControlsAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterRVCRunModeAttributeSupportedModesID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterRVCRunModeAttributeCurrentModeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterRVCRunModeAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterRVCRunModeAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterRVCRunModeAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterRVCRunModeAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterRVCRunModeAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterRVCCleanModeAttributeSupportedModesID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterRVCCleanModeAttributeCurrentModeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterRVCCleanModeAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterRVCCleanModeAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterRVCCleanModeAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterRVCCleanModeAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterRVCCleanModeAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterTemperatureControlAttributeTemperatureSetpointID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterTemperatureControlAttributeMinTemperatureID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterTemperatureControlAttributeMaxTemperatureID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterTemperatureControlAttributeStepID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterTemperatureControlAttributeSelectedTemperatureLevelID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterTemperatureControlAttributeSupportedTemperatureLevelsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterTemperatureControlAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterTemperatureControlAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterTemperatureControlAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterTemperatureControlAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterTemperatureControlAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterRefrigeratorAlarmAttributeMaskID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterRefrigeratorAlarmAttributeStateID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterRefrigeratorAlarmAttributeSupportedID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterRefrigeratorAlarmAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterRefrigeratorAlarmAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterRefrigeratorAlarmAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterRefrigeratorAlarmAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterRefrigeratorAlarmAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterDishwasherModeAttributeSupportedModesID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterDishwasherModeAttributeCurrentModeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterDishwasherModeAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterDishwasherModeAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterDishwasherModeAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterDishwasherModeAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterDishwasherModeAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterAirQualityAttributeAirQualityID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterAirQualityAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterAirQualityAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterAirQualityAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterAirQualityAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterAirQualityAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterSmokeCOAlarmAttributeExpressedStateID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterSmokeCOAlarmAttributeSmokeStateID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterSmokeCOAlarmAttributeCOStateID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterSmokeCOAlarmAttributeBatteryAlertID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterSmokeCOAlarmAttributeDeviceMutedID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterSmokeCOAlarmAttributeTestInProgressID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterSmokeCOAlarmAttributeHardwareFaultAlertID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterSmokeCOAlarmAttributeEndOfServiceAlertID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterSmokeCOAlarmAttributeInterconnectSmokeAlarmID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterSmokeCOAlarmAttributeInterconnectCOAlarmID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterSmokeCOAlarmAttributeContaminationStateID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterSmokeCOAlarmAttributeSmokeSensitivityLevelID: MTRAttributeIDType { .MTRClusterBasicAttributeManufacturingDateID }
    public static var clusterSmokeCOAlarmAttributeExpiryDateID: MTRAttributeIDType { .MTRClusterBasicAttributePartNumberID }
    public static var clusterSmokeCOAlarmAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterSmokeCOAlarmAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterSmokeCOAlarmAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterSmokeCOAlarmAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterSmokeCOAlarmAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterDishwasherAlarmAttributeMaskID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterDishwasherAlarmAttributeLatchID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterDishwasherAlarmAttributeStateID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterDishwasherAlarmAttributeSupportedID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterDishwasherAlarmAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterDishwasherAlarmAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterDishwasherAlarmAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterDishwasherAlarmAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterDishwasherAlarmAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterMicrowaveOvenModeAttributeSupportedModesID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterMicrowaveOvenModeAttributeCurrentModeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterMicrowaveOvenModeAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterMicrowaveOvenModeAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterMicrowaveOvenModeAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterMicrowaveOvenModeAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterMicrowaveOvenModeAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterMicrowaveOvenControlAttributeCookTimeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterMicrowaveOvenControlAttributeMaxCookTimeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterMicrowaveOvenControlAttributePowerSettingID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterMicrowaveOvenControlAttributeMinPowerID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterMicrowaveOvenControlAttributeMaxPowerID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterMicrowaveOvenControlAttributePowerStepID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterMicrowaveOvenControlAttributeWattRatingID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterMicrowaveOvenControlAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterMicrowaveOvenControlAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterMicrowaveOvenControlAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterMicrowaveOvenControlAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterMicrowaveOvenControlAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterOperationalStateAttributePhaseListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterOperationalStateAttributeCurrentPhaseID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterOperationalStateAttributeCountdownTimeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterOperationalStateAttributeOperationalStateListID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterOperationalStateAttributeOperationalStateID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterOperationalStateAttributeOperationalErrorID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterOperationalStateAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterOperationalStateAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterOperationalStateAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterOperationalStateAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterOperationalStateAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterRVCOperationalStateAttributePhaseListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterRVCOperationalStateAttributeCurrentPhaseID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterRVCOperationalStateAttributeCountdownTimeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterRVCOperationalStateAttributeOperationalStateListID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterRVCOperationalStateAttributeOperationalStateID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterRVCOperationalStateAttributeOperationalErrorID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterRVCOperationalStateAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterRVCOperationalStateAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterRVCOperationalStateAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterRVCOperationalStateAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterRVCOperationalStateAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterHEPAFilterMonitoringAttributeConditionID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterHEPAFilterMonitoringAttributeDegradationDirectionID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterHEPAFilterMonitoringAttributeChangeIndicationID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterHEPAFilterMonitoringAttributeInPlaceIndicatorID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterHEPAFilterMonitoringAttributeLastChangedTimeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterHEPAFilterMonitoringAttributeReplacementProductListID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterHEPAFilterMonitoringAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterHEPAFilterMonitoringAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterHEPAFilterMonitoringAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterHEPAFilterMonitoringAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterHEPAFilterMonitoringAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterActivatedCarbonFilterMonitoringAttributeConditionID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterActivatedCarbonFilterMonitoringAttributeDegradationDirectionID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterActivatedCarbonFilterMonitoringAttributeChangeIndicationID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterActivatedCarbonFilterMonitoringAttributeInPlaceIndicatorID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterActivatedCarbonFilterMonitoringAttributeLastChangedTimeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterActivatedCarbonFilterMonitoringAttributeReplacementProductListID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterActivatedCarbonFilterMonitoringAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterActivatedCarbonFilterMonitoringAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterActivatedCarbonFilterMonitoringAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterActivatedCarbonFilterMonitoringAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterActivatedCarbonFilterMonitoringAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterBooleanStateConfigurationAttributeCurrentSensitivityLevelID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterBooleanStateConfigurationAttributeSupportedSensitivityLevelsID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterBooleanStateConfigurationAttributeDefaultSensitivityLevelID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterBooleanStateConfigurationAttributeAlarmsActiveID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterBooleanStateConfigurationAttributeAlarmsSuppressedID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterBooleanStateConfigurationAttributeAlarmsEnabledID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterBooleanStateConfigurationAttributeAlarmsSupportedID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterBooleanStateConfigurationAttributeSensorFaultID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterBooleanStateConfigurationAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterBooleanStateConfigurationAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterBooleanStateConfigurationAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterBooleanStateConfigurationAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterBooleanStateConfigurationAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterValveConfigurationAndControlAttributeOpenDurationID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterValveConfigurationAndControlAttributeDefaultOpenDurationID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterValveConfigurationAndControlAttributeAutoCloseTimeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterValveConfigurationAndControlAttributeRemainingDurationID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterValveConfigurationAndControlAttributeCurrentStateID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterValveConfigurationAndControlAttributeTargetStateID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterValveConfigurationAndControlAttributeCurrentLevelID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterValveConfigurationAndControlAttributeTargetLevelID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterValveConfigurationAndControlAttributeDefaultOpenLevelID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterValveConfigurationAndControlAttributeValveFaultID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterValveConfigurationAndControlAttributeLevelStepID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterValveConfigurationAndControlAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterValveConfigurationAndControlAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterValveConfigurationAndControlAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterValveConfigurationAndControlAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterValveConfigurationAndControlAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterElectricalPowerMeasurementAttributePowerModeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterElectricalPowerMeasurementAttributeNumberOfMeasurementTypesID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterElectricalPowerMeasurementAttributeAccuracyID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterElectricalPowerMeasurementAttributeRangesID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterElectricalPowerMeasurementAttributeVoltageID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterElectricalPowerMeasurementAttributeActiveCurrentID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterElectricalPowerMeasurementAttributeReactiveCurrentID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterElectricalPowerMeasurementAttributeApparentCurrentID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterElectricalPowerMeasurementAttributeActivePowerID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterElectricalPowerMeasurementAttributeReactivePowerID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterElectricalPowerMeasurementAttributeApparentPowerID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterElectricalPowerMeasurementAttributeRMSVoltageID: MTRAttributeIDType { .MTRClusterBasicAttributeManufacturingDateID }
    public static var clusterElectricalPowerMeasurementAttributeRMSCurrentID: MTRAttributeIDType { .MTRClusterBasicAttributePartNumberID }
    public static var clusterElectricalPowerMeasurementAttributeRMSPowerID: MTRAttributeIDType { .MTRClusterBasicAttributeProductURLID }
    public static var clusterElectricalPowerMeasurementAttributeFrequencyID: MTRAttributeIDType { .MTRClusterBasicAttributeProductLabelID }
    public static var clusterElectricalPowerMeasurementAttributeHarmonicCurrentsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOptionsID }
    public static var clusterElectricalPowerMeasurementAttributeHarmonicPhasesID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var clusterElectricalPowerMeasurementAttributePowerFactorID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var clusterElectricalPowerMeasurementAttributeNeutralCurrentID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var clusterElectricalPowerMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterElectricalPowerMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterElectricalPowerMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterElectricalPowerMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterElectricalPowerMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterElectricalEnergyMeasurementAttributeAccuracyID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterElectricalEnergyMeasurementAttributeCumulativeEnergyImportedID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterElectricalEnergyMeasurementAttributeCumulativeEnergyExportedID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterElectricalEnergyMeasurementAttributePeriodicEnergyImportedID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterElectricalEnergyMeasurementAttributePeriodicEnergyExportedID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterElectricalEnergyMeasurementAttributeCumulativeEnergyResetID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterElectricalEnergyMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterElectricalEnergyMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterElectricalEnergyMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterElectricalEnergyMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterElectricalEnergyMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterWaterHeaterManagementAttributeHeaterTypesID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterWaterHeaterManagementAttributeHeatDemandID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterWaterHeaterManagementAttributeTankVolumeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterWaterHeaterManagementAttributeEstimatedHeatRequiredID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterWaterHeaterManagementAttributeTankPercentageID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterWaterHeaterManagementAttributeBoostStateID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterWaterHeaterManagementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterWaterHeaterManagementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterWaterHeaterManagementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterWaterHeaterManagementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterWaterHeaterManagementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterMessagesAttributeMessagesID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterMessagesAttributeActiveMessageIDsID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterMessagesAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterMessagesAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterMessagesAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterMessagesAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterMessagesAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterDeviceEnergyManagementAttributeESATypeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterDeviceEnergyManagementAttributeESACanGenerateID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterDeviceEnergyManagementAttributeESAStateID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterDeviceEnergyManagementAttributeAbsMinPowerID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterDeviceEnergyManagementAttributeAbsMaxPowerID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterDeviceEnergyManagementAttributePowerAdjustmentCapabilityID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterDeviceEnergyManagementAttributeForecastID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterDeviceEnergyManagementAttributeOptOutStateID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterDeviceEnergyManagementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterDeviceEnergyManagementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterDeviceEnergyManagementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterDeviceEnergyManagementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterDeviceEnergyManagementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterEnergyEVSEAttributeStateID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterEnergyEVSEAttributeSupplyStateID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterEnergyEVSEAttributeFaultStateID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterEnergyEVSEAttributeChargingEnabledUntilID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterEnergyEVSEAttributeCircuitCapacityID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterEnergyEVSEAttributeMinimumChargeCurrentID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterEnergyEVSEAttributeMaximumChargeCurrentID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterEnergyEVSEAttributeUserMaximumChargeCurrentID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterEnergyEVSEAttributeRandomizationDelayWindowID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterEnergyEVSEAttributeNextChargeStartTimeID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxIndirectMaxRetryExpiryCountID }
    public static var clusterEnergyEVSEAttributeNextChargeTargetTimeID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrCcaCountID }
    public static var clusterEnergyEVSEAttributeNextChargeRequiredEnergyID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrAbortCountID }
    public static var clusterEnergyEVSEAttributeNextChargeTargetSoCID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrBusyChannelCountID }
    public static var clusterEnergyEVSEAttributeApproximateEVEfficiencyID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxTotalCountID }
    public static var clusterEnergyEVSEAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterEnergyEVSEAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterEnergyEVSEAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterEnergyEVSEAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterEnergyEVSEAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterPowerTopologyAttributeAvailableEndpointsID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterPowerTopologyAttributeActiveEndpointsID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterPowerTopologyAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterPowerTopologyAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterPowerTopologyAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterPowerTopologyAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterPowerTopologyAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterEnergyEVSEModeAttributeSupportedModesID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterEnergyEVSEModeAttributeCurrentModeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterEnergyEVSEModeAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterEnergyEVSEModeAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterEnergyEVSEModeAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterEnergyEVSEModeAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterEnergyEVSEModeAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterWaterHeaterModeAttributeSupportedModesID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterWaterHeaterModeAttributeCurrentModeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterWaterHeaterModeAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterWaterHeaterModeAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterWaterHeaterModeAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterWaterHeaterModeAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterWaterHeaterModeAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterDeviceEnergyManagementModeAttributeSupportedModesID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterDeviceEnergyManagementModeAttributeCurrentModeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterDeviceEnergyManagementModeAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterDeviceEnergyManagementModeAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterDeviceEnergyManagementModeAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterDeviceEnergyManagementModeAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterDeviceEnergyManagementModeAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterDoorLockAttributeLockStateID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterDoorLockAttributeLockTypeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterDoorLockAttributeActuatorEnabledID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterDoorLockAttributeDoorStateID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterDoorLockAttributeDoorOpenEventsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterDoorLockAttributeDoorClosedEventsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var MTRClusterDoorLockAttributeOpenPeriodID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var MTRClusterDoorLockAttributeNumberOfTotalUsersSupportedID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var MTRClusterDoorLockAttributeNumberOfPINUsersSupportedID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var MTRClusterDoorLockAttributeNumberOfRFIDUsersSupportedID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOffTransitionTimeID }
    public static var MTRClusterDoorLockAttributeNumberOfWeekDaySchedulesSupportedPerUserID: MTRAttributeIDType { .MTRClusterLevelControlAttributeDefaultMoveRateID }
    public static var MTRClusterDoorLockAttributeNumberOfYearDaySchedulesSupportedPerUserID: MTRAttributeIDType { .clusterBasicInformationAttributeSpecificationVersionID }
    public static var MTRClusterDoorLockAttributeNumberOfHolidaySchedulesSupportedID: MTRAttributeIDType { .clusterBasicInformationAttributeMaxPathsPerInvokeID }
    public static var MTRClusterDoorLockAttributeMaxPINCodeLengthID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatApprovedChemistryID }
    public static var MTRClusterDoorLockAttributeMinPINCodeLengthID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatCapacityID }
    public static var MTRClusterDoorLockAttributeMaxRFIDCodeLengthID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatQuantityID }
    public static var MTRClusterDoorLockAttributeMinRFIDCodeLengthID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatChargeStateID }
    public static var MTRClusterDoorLockAttributeCredentialRulesSupportID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatTimeToFullChargeID }
    public static var MTRClusterDoorLockAttributeNumberOfCredentialsSupportedPerUserID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatFunctionalWhileChargingID }
    public static var MTRClusterDoorLockAttributeLanguageID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxRetryCountID }
    public static var MTRClusterDoorLockAttributeLEDSettingsID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxDirectMaxRetryExpiryCountID }
    public static var MTRClusterDoorLockAttributeAutoRelockTimeID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxIndirectMaxRetryExpiryCountID }
    public static var MTRClusterDoorLockAttributeSoundVolumeID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrCcaCountID }
    public static var MTRClusterDoorLockAttributeOperatingModeID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrAbortCountID }
    public static var MTRClusterDoorLockAttributeSupportedOperatingModesID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrBusyChannelCountID }
    public static var MTRClusterDoorLockAttributeDefaultConfigurationRegisterID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxTotalCountID }
    public static var MTRClusterDoorLockAttributeEnableLocalProgrammingID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxUnicastCountID }
    public static var MTRClusterDoorLockAttributeEnableOneTouchLockingID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxBroadcastCountID }
    public static var MTRClusterDoorLockAttributeEnableInsideStatusLEDID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDataCountID }
    public static var MTRClusterDoorLockAttributeEnablePrivacyModeButtonID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDataPollCountID }
    public static var MTRClusterDoorLockAttributeLocalProgrammingFeaturesID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxBeaconCountID }
    public static var MTRClusterDoorLockAttributeWrongCodeEntryLimitID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDestAddrFilteredCountID }
    public static var MTRClusterDoorLockAttributeUserCodeTemporaryDisableTimeID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDuplicatedCountID }
    public static var MTRClusterDoorLockAttributeSendPINOverTheAirID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrNoFrameCountID }
    public static var MTRClusterDoorLockAttributeRequirePINforRemoteOperationID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrUnknownNeighborCountID }
    public static var MTRClusterDoorLockAttributeExpiringUserTimeoutID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrSecCountID }
    public static var MTRClusterDoorLockAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterDoorLockAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterDoorLockAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterDoorLockAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterDoorLockAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterDoorLockAttributeLockStateID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterDoorLockAttributeLockTypeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterDoorLockAttributeActuatorEnabledID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterDoorLockAttributeDoorStateID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterDoorLockAttributeDoorOpenEventsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterDoorLockAttributeDoorClosedEventsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterDoorLockAttributeOpenPeriodID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterDoorLockAttributeNumberOfTotalUsersSupportedID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var clusterDoorLockAttributeNumberOfPINUsersSupportedID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var clusterDoorLockAttributeNumberOfRFIDUsersSupportedID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOffTransitionTimeID }
    public static var clusterDoorLockAttributeNumberOfWeekDaySchedulesSupportedPerUserID: MTRAttributeIDType { .MTRClusterLevelControlAttributeDefaultMoveRateID }
    public static var clusterDoorLockAttributeNumberOfYearDaySchedulesSupportedPerUserID: MTRAttributeIDType { .clusterBasicInformationAttributeSpecificationVersionID }
    public static var clusterDoorLockAttributeNumberOfHolidaySchedulesSupportedID: MTRAttributeIDType { .clusterBasicInformationAttributeMaxPathsPerInvokeID }
    public static var clusterDoorLockAttributeMaxPINCodeLengthID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatApprovedChemistryID }
    public static var clusterDoorLockAttributeMinPINCodeLengthID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatCapacityID }
    public static var clusterDoorLockAttributeMaxRFIDCodeLengthID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatQuantityID }
    public static var clusterDoorLockAttributeMinRFIDCodeLengthID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatChargeStateID }
    public static var clusterDoorLockAttributeCredentialRulesSupportID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatTimeToFullChargeID }
    public static var clusterDoorLockAttributeNumberOfCredentialsSupportedPerUserID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatFunctionalWhileChargingID }
    public static var clusterDoorLockAttributeLanguageID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxRetryCountID }
    public static var clusterDoorLockAttributeLEDSettingsID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxDirectMaxRetryExpiryCountID }
    public static var clusterDoorLockAttributeAutoRelockTimeID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxIndirectMaxRetryExpiryCountID }
    public static var clusterDoorLockAttributeSoundVolumeID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrCcaCountID }
    public static var clusterDoorLockAttributeOperatingModeID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrAbortCountID }
    public static var clusterDoorLockAttributeSupportedOperatingModesID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrBusyChannelCountID }
    public static var clusterDoorLockAttributeDefaultConfigurationRegisterID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxTotalCountID }
    public static var clusterDoorLockAttributeEnableLocalProgrammingID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxUnicastCountID }
    public static var clusterDoorLockAttributeEnableOneTouchLockingID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxBroadcastCountID }
    public static var clusterDoorLockAttributeEnableInsideStatusLEDID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDataCountID }
    public static var clusterDoorLockAttributeEnablePrivacyModeButtonID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDataPollCountID }
    public static var clusterDoorLockAttributeLocalProgrammingFeaturesID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxBeaconCountID }
    public static var clusterDoorLockAttributeWrongCodeEntryLimitID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDestAddrFilteredCountID }
    public static var clusterDoorLockAttributeUserCodeTemporaryDisableTimeID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDuplicatedCountID }
    public static var clusterDoorLockAttributeSendPINOverTheAirID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrNoFrameCountID }
    public static var clusterDoorLockAttributeRequirePINforRemoteOperationID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrUnknownNeighborCountID }
    public static var clusterDoorLockAttributeExpiringUserTimeoutID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrSecCountID }
    public static var clusterDoorLockAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterDoorLockAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterDoorLockAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterDoorLockAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterDoorLockAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterWindowCoveringAttributeTypeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterWindowCoveringAttributePhysicalClosedLimitLiftID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterWindowCoveringAttributePhysicalClosedLimitTiltID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterWindowCoveringAttributeCurrentPositionLiftID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterWindowCoveringAttributeCurrentPositionTiltID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterWindowCoveringAttributeNumberOfActuationsLiftID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var MTRClusterWindowCoveringAttributeNumberOfActuationsTiltID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var MTRClusterWindowCoveringAttributeConfigStatusID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var MTRClusterWindowCoveringAttributeCurrentPositionLiftPercentageID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var MTRClusterWindowCoveringAttributeCurrentPositionTiltPercentageID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var MTRClusterWindowCoveringAttributeOperationalStatusID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var MTRClusterWindowCoveringAttributeTargetPositionLiftPercent100thsID: MTRAttributeIDType { .MTRClusterBasicAttributeManufacturingDateID }
    public static var MTRClusterWindowCoveringAttributeTargetPositionTiltPercent100thsID: MTRAttributeIDType { .MTRClusterBasicAttributePartNumberID }
    public static var MTRClusterWindowCoveringAttributeEndProductTypeID: MTRAttributeIDType { .MTRClusterBasicAttributeProductURLID }
    public static var MTRClusterWindowCoveringAttributeCurrentPositionLiftPercent100thsID: MTRAttributeIDType { .MTRClusterBasicAttributeProductLabelID }
    public static var MTRClusterWindowCoveringAttributeCurrentPositionTiltPercent100thsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOptionsID }
    public static var MTRClusterWindowCoveringAttributeInstalledOpenLimitLiftID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var MTRClusterWindowCoveringAttributeInstalledClosedLimitLiftID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var MTRClusterWindowCoveringAttributeInstalledOpenLimitTiltID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var MTRClusterWindowCoveringAttributeInstalledClosedLimitTiltID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOffTransitionTimeID }
    public static var MTRClusterWindowCoveringAttributeModeID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatApprovedChemistryID }
    public static var MTRClusterWindowCoveringAttributeSafetyStatusID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatChargeStateID }
    public static var MTRClusterWindowCoveringAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterWindowCoveringAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterWindowCoveringAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterWindowCoveringAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterWindowCoveringAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterWindowCoveringAttributeTypeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterWindowCoveringAttributePhysicalClosedLimitLiftID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterWindowCoveringAttributePhysicalClosedLimitTiltID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterWindowCoveringAttributeCurrentPositionLiftID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterWindowCoveringAttributeCurrentPositionTiltID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterWindowCoveringAttributeNumberOfActuationsLiftID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterWindowCoveringAttributeNumberOfActuationsTiltID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterWindowCoveringAttributeConfigStatusID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterWindowCoveringAttributeCurrentPositionLiftPercentageID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterWindowCoveringAttributeCurrentPositionTiltPercentageID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterWindowCoveringAttributeOperationalStatusID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterWindowCoveringAttributeTargetPositionLiftPercent100thsID: MTRAttributeIDType { .MTRClusterBasicAttributeManufacturingDateID }
    public static var clusterWindowCoveringAttributeTargetPositionTiltPercent100thsID: MTRAttributeIDType { .MTRClusterBasicAttributePartNumberID }
    public static var clusterWindowCoveringAttributeEndProductTypeID: MTRAttributeIDType { .MTRClusterBasicAttributeProductURLID }
    public static var clusterWindowCoveringAttributeCurrentPositionLiftPercent100thsID: MTRAttributeIDType { .MTRClusterBasicAttributeProductLabelID }
    public static var clusterWindowCoveringAttributeCurrentPositionTiltPercent100thsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOptionsID }
    public static var clusterWindowCoveringAttributeInstalledOpenLimitLiftID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var clusterWindowCoveringAttributeInstalledClosedLimitLiftID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var clusterWindowCoveringAttributeInstalledOpenLimitTiltID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var clusterWindowCoveringAttributeInstalledClosedLimitTiltID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOffTransitionTimeID }
    public static var clusterWindowCoveringAttributeModeID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatApprovedChemistryID }
    public static var clusterWindowCoveringAttributeSafetyStatusID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatChargeStateID }
    public static var clusterWindowCoveringAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterWindowCoveringAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterWindowCoveringAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterWindowCoveringAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterWindowCoveringAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterServiceAreaAttributeSupportedAreasID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterServiceAreaAttributeSupportedMapsID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterServiceAreaAttributeSelectedAreasID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterServiceAreaAttributeCurrentAreaID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterServiceAreaAttributeEstimatedEndTimeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterServiceAreaAttributeProgressID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterServiceAreaAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterServiceAreaAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterServiceAreaAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterServiceAreaAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterServiceAreaAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterPumpConfigurationAndControlAttributeMaxPressureID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterPumpConfigurationAndControlAttributeMaxSpeedID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterPumpConfigurationAndControlAttributeMaxFlowID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterPumpConfigurationAndControlAttributeMinConstPressureID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterPumpConfigurationAndControlAttributeMaxConstPressureID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterPumpConfigurationAndControlAttributeMinCompPressureID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var MTRClusterPumpConfigurationAndControlAttributeMaxCompPressureID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var MTRClusterPumpConfigurationAndControlAttributeMinConstSpeedID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var MTRClusterPumpConfigurationAndControlAttributeMaxConstSpeedID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var MTRClusterPumpConfigurationAndControlAttributeMinConstFlowID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var MTRClusterPumpConfigurationAndControlAttributeMaxConstFlowID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var MTRClusterPumpConfigurationAndControlAttributeMinConstTempID: MTRAttributeIDType { .MTRClusterBasicAttributeManufacturingDateID }
    public static var MTRClusterPumpConfigurationAndControlAttributeMaxConstTempID: MTRAttributeIDType { .MTRClusterBasicAttributePartNumberID }
    public static var MTRClusterPumpConfigurationAndControlAttributePumpStatusID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var MTRClusterPumpConfigurationAndControlAttributeEffectiveOperationModeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var MTRClusterPumpConfigurationAndControlAttributeEffectiveControlModeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var MTRClusterPumpConfigurationAndControlAttributeCapacityID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOffTransitionTimeID }
    public static var MTRClusterPumpConfigurationAndControlAttributeSpeedID: MTRAttributeIDType { .MTRClusterLevelControlAttributeDefaultMoveRateID }
    public static var MTRClusterPumpConfigurationAndControlAttributeLifetimeRunningHoursID: MTRAttributeIDType { .clusterBasicInformationAttributeSpecificationVersionID }
    public static var MTRClusterPumpConfigurationAndControlAttributePowerID: MTRAttributeIDType { .clusterBasicInformationAttributeMaxPathsPerInvokeID }
    public static var MTRClusterPumpConfigurationAndControlAttributeLifetimeEnergyConsumedID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatApprovedChemistryID }
    public static var MTRClusterPumpConfigurationAndControlAttributeOperationModeID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxOtherCountID }
    public static var MTRClusterPumpConfigurationAndControlAttributeControlModeID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxRetryCountID }
    public static var MTRClusterPumpConfigurationAndControlAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterPumpConfigurationAndControlAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterPumpConfigurationAndControlAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterPumpConfigurationAndControlAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterPumpConfigurationAndControlAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterPumpConfigurationAndControlAttributeMaxPressureID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterPumpConfigurationAndControlAttributeMaxSpeedID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterPumpConfigurationAndControlAttributeMaxFlowID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterPumpConfigurationAndControlAttributeMinConstPressureID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterPumpConfigurationAndControlAttributeMaxConstPressureID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterPumpConfigurationAndControlAttributeMinCompPressureID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterPumpConfigurationAndControlAttributeMaxCompPressureID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterPumpConfigurationAndControlAttributeMinConstSpeedID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterPumpConfigurationAndControlAttributeMaxConstSpeedID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterPumpConfigurationAndControlAttributeMinConstFlowID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterPumpConfigurationAndControlAttributeMaxConstFlowID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterPumpConfigurationAndControlAttributeMinConstTempID: MTRAttributeIDType { .MTRClusterBasicAttributeManufacturingDateID }
    public static var clusterPumpConfigurationAndControlAttributeMaxConstTempID: MTRAttributeIDType { .MTRClusterBasicAttributePartNumberID }
    public static var clusterPumpConfigurationAndControlAttributePumpStatusID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var clusterPumpConfigurationAndControlAttributeEffectiveOperationModeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var clusterPumpConfigurationAndControlAttributeEffectiveControlModeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var clusterPumpConfigurationAndControlAttributeCapacityID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOffTransitionTimeID }
    public static var clusterPumpConfigurationAndControlAttributeSpeedID: MTRAttributeIDType { .MTRClusterLevelControlAttributeDefaultMoveRateID }
    public static var clusterPumpConfigurationAndControlAttributeLifetimeRunningHoursID: MTRAttributeIDType { .clusterBasicInformationAttributeSpecificationVersionID }
    public static var clusterPumpConfigurationAndControlAttributePowerID: MTRAttributeIDType { .clusterBasicInformationAttributeMaxPathsPerInvokeID }
    public static var clusterPumpConfigurationAndControlAttributeLifetimeEnergyConsumedID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatApprovedChemistryID }
    public static var clusterPumpConfigurationAndControlAttributeOperationModeID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxOtherCountID }
    public static var clusterPumpConfigurationAndControlAttributeControlModeID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxRetryCountID }
    public static var clusterPumpConfigurationAndControlAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterPumpConfigurationAndControlAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterPumpConfigurationAndControlAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterPumpConfigurationAndControlAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterPumpConfigurationAndControlAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterThermostatAttributeLocalTemperatureID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterThermostatAttributeOutdoorTemperatureID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterThermostatAttributeOccupancyID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterThermostatAttributeAbsMinHeatSetpointLimitID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterThermostatAttributeAbsMaxHeatSetpointLimitID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterThermostatAttributeAbsMinCoolSetpointLimitID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var MTRClusterThermostatAttributeAbsMaxCoolSetpointLimitID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var MTRClusterThermostatAttributePICoolingDemandID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var MTRClusterThermostatAttributePIHeatingDemandID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var MTRClusterThermostatAttributeHVACSystemTypeConfigurationID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var MTRClusterThermostatAttributeLocalTemperatureCalibrationID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var MTRClusterThermostatAttributeOccupiedCoolingSetpointID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var MTRClusterThermostatAttributeOccupiedHeatingSetpointID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var MTRClusterThermostatAttributeUnoccupiedCoolingSetpointID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOffTransitionTimeID }
    public static var MTRClusterThermostatAttributeUnoccupiedHeatingSetpointID: MTRAttributeIDType { .MTRClusterLevelControlAttributeDefaultMoveRateID }
    public static var MTRClusterThermostatAttributeMinHeatSetpointLimitID: MTRAttributeIDType { .clusterBasicInformationAttributeSpecificationVersionID }
    public static var MTRClusterThermostatAttributeMaxHeatSetpointLimitID: MTRAttributeIDType { .clusterBasicInformationAttributeMaxPathsPerInvokeID }
    public static var MTRClusterThermostatAttributeMinCoolSetpointLimitID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatApprovedChemistryID }
    public static var MTRClusterThermostatAttributeMaxCoolSetpointLimitID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatCapacityID }
    public static var MTRClusterThermostatAttributeMinSetpointDeadBandID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatQuantityID }
    public static var MTRClusterThermostatAttributeRemoteSensingID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatChargeStateID }
    public static var MTRClusterThermostatAttributeControlSequenceOfOperationID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatTimeToFullChargeID }
    public static var MTRClusterThermostatAttributeSystemModeID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatFunctionalWhileChargingID }
    public static var MTRClusterThermostatAttributeThermostatRunningModeID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeActiveBatChargeFaultsID }
    public static var MTRClusterThermostatAttributeStartOfWeekID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxOtherCountID }
    public static var MTRClusterThermostatAttributeNumberOfWeeklyTransitionsID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxRetryCountID }
    public static var MTRClusterThermostatAttributeNumberOfDailyTransitionsID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxDirectMaxRetryExpiryCountID }
    public static var MTRClusterThermostatAttributeTemperatureSetpointHoldID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxIndirectMaxRetryExpiryCountID }
    public static var MTRClusterThermostatAttributeTemperatureSetpointHoldDurationID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrCcaCountID }
    public static var MTRClusterThermostatAttributeThermostatProgrammingOperationModeID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrAbortCountID }
    public static var MTRClusterThermostatAttributeThermostatRunningStateID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxBroadcastCountID }
    public static var MTRClusterThermostatAttributeSetpointChangeSourceID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDestAddrFilteredCountID }
    public static var MTRClusterThermostatAttributeSetpointChangeAmountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDuplicatedCountID }
    public static var MTRClusterThermostatAttributeSetpointChangeSourceTimestampID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrNoFrameCountID }
    public static var MTRClusterThermostatAttributeOccupiedSetbackID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrInvalidSrcAddrCountID }
    public static var MTRClusterThermostatAttributeOccupiedSetbackMinID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrSecCountID }
    public static var MTRClusterThermostatAttributeOccupiedSetbackMaxID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrFcsCountID }
    public static var MTRClusterThermostatAttributeUnoccupiedSetbackID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrOtherCountID }
    public static var MTRClusterThermostatAttributeUnoccupiedSetbackMinID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeActiveTimestampID }
    public static var MTRClusterThermostatAttributeUnoccupiedSetbackMaxID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributePendingTimestampID }
    public static var MTRClusterThermostatAttributeEmergencyHeatDeltaID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeDelayID }
    public static var MTRClusterThermostatAttributeACTypeID: MTRAttributeIDType { .clusterEnergyEVSEAttributeSessionIDID }
    public static var MTRClusterThermostatAttributeACCapacityID: MTRAttributeIDType { .clusterEnergyEVSEAttributeSessionDurationID }
    public static var MTRClusterThermostatAttributeACRefrigerantTypeID: MTRAttributeIDType { .clusterEnergyEVSEAttributeSessionEnergyChargedID }
    public static var MTRClusterThermostatAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterThermostatAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterThermostatAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterThermostatAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterThermostatAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterThermostatAttributeLocalTemperatureID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterThermostatAttributeOutdoorTemperatureID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterThermostatAttributeOccupancyID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterThermostatAttributeAbsMinHeatSetpointLimitID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterThermostatAttributeAbsMaxHeatSetpointLimitID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterThermostatAttributeAbsMinCoolSetpointLimitID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterThermostatAttributeAbsMaxCoolSetpointLimitID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterThermostatAttributePICoolingDemandID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterThermostatAttributePIHeatingDemandID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterThermostatAttributeHVACSystemTypeConfigurationID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterThermostatAttributeLocalTemperatureCalibrationID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var clusterThermostatAttributeOccupiedCoolingSetpointID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var clusterThermostatAttributeOccupiedHeatingSetpointID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var clusterThermostatAttributeUnoccupiedCoolingSetpointID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOffTransitionTimeID }
    public static var clusterThermostatAttributeUnoccupiedHeatingSetpointID: MTRAttributeIDType { .MTRClusterLevelControlAttributeDefaultMoveRateID }
    public static var clusterThermostatAttributeMinHeatSetpointLimitID: MTRAttributeIDType { .clusterBasicInformationAttributeSpecificationVersionID }
    public static var clusterThermostatAttributeMaxHeatSetpointLimitID: MTRAttributeIDType { .clusterBasicInformationAttributeMaxPathsPerInvokeID }
    public static var clusterThermostatAttributeMinCoolSetpointLimitID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatApprovedChemistryID }
    public static var clusterThermostatAttributeMaxCoolSetpointLimitID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatCapacityID }
    public static var clusterThermostatAttributeMinSetpointDeadBandID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatQuantityID }
    public static var clusterThermostatAttributeRemoteSensingID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatChargeStateID }
    public static var clusterThermostatAttributeControlSequenceOfOperationID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatTimeToFullChargeID }
    public static var clusterThermostatAttributeSystemModeID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatFunctionalWhileChargingID }
    public static var clusterThermostatAttributeThermostatRunningModeID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeActiveBatChargeFaultsID }
    public static var clusterThermostatAttributeStartOfWeekID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxOtherCountID }
    public static var clusterThermostatAttributeNumberOfWeeklyTransitionsID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxRetryCountID }
    public static var clusterThermostatAttributeNumberOfDailyTransitionsID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxDirectMaxRetryExpiryCountID }
    public static var clusterThermostatAttributeTemperatureSetpointHoldID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxIndirectMaxRetryExpiryCountID }
    public static var clusterThermostatAttributeTemperatureSetpointHoldDurationID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrCcaCountID }
    public static var clusterThermostatAttributeThermostatProgrammingOperationModeID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrAbortCountID }
    public static var clusterThermostatAttributeThermostatRunningStateID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxBroadcastCountID }
    public static var clusterThermostatAttributeSetpointChangeSourceID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDestAddrFilteredCountID }
    public static var clusterThermostatAttributeSetpointChangeAmountID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDuplicatedCountID }
    public static var clusterThermostatAttributeSetpointChangeSourceTimestampID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrNoFrameCountID }
    public static var clusterThermostatAttributeOccupiedSetbackID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrInvalidSrcAddrCountID }
    public static var clusterThermostatAttributeOccupiedSetbackMinID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrSecCountID }
    public static var clusterThermostatAttributeOccupiedSetbackMaxID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrFcsCountID }
    public static var clusterThermostatAttributeUnoccupiedSetbackID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrOtherCountID }
    public static var clusterThermostatAttributeUnoccupiedSetbackMinID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeActiveTimestampID }
    public static var clusterThermostatAttributeUnoccupiedSetbackMaxID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributePendingTimestampID }
    public static var clusterThermostatAttributeEmergencyHeatDeltaID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeDelayID }
    public static var clusterThermostatAttributeACTypeID: MTRAttributeIDType { .clusterEnergyEVSEAttributeSessionIDID }
    public static var clusterThermostatAttributeACCapacityID: MTRAttributeIDType { .clusterEnergyEVSEAttributeSessionDurationID }
    public static var clusterThermostatAttributeACRefrigerantTypeID: MTRAttributeIDType { .clusterEnergyEVSEAttributeSessionEnergyChargedID }
    public static var clusterThermostatAttributeACCompressorTypeID: MTRAttributeIDType { .MTRClusterThermostatAttributeACCompressorTypeID }
    public static var clusterThermostatAttributeACErrorCodeID: MTRAttributeIDType { .MTRClusterThermostatAttributeACErrorCodeID }
    public static var clusterThermostatAttributeACLouverPositionID: MTRAttributeIDType { .MTRClusterThermostatAttributeACLouverPositionID }
    public static var clusterThermostatAttributeACCoilTemperatureID: MTRAttributeIDType { .MTRClusterThermostatAttributeACCoilTemperatureID }
    public static var clusterThermostatAttributeACCapacityformatID: MTRAttributeIDType { .MTRClusterThermostatAttributeACCapacityformatID }
    public static var clusterThermostatAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterThermostatAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterThermostatAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterThermostatAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterThermostatAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterFanControlAttributeFanModeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterFanControlAttributeFanModeSequenceID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterFanControlAttributePercentSettingID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterFanControlAttributePercentCurrentID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterFanControlAttributeSpeedMaxID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterFanControlAttributeSpeedSettingID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var MTRClusterFanControlAttributeSpeedCurrentID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var MTRClusterFanControlAttributeRockSupportID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var MTRClusterFanControlAttributeRockSettingID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var MTRClusterFanControlAttributeWindSupportID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var MTRClusterFanControlAttributeWindSettingID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var MTRClusterFanControlAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterFanControlAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterFanControlAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterFanControlAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterFanControlAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterFanControlAttributeFanModeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterFanControlAttributeFanModeSequenceID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterFanControlAttributePercentSettingID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterFanControlAttributePercentCurrentID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterFanControlAttributeSpeedMaxID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterFanControlAttributeSpeedSettingID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterFanControlAttributeSpeedCurrentID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterFanControlAttributeRockSupportID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterFanControlAttributeRockSettingID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterFanControlAttributeWindSupportID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterFanControlAttributeWindSettingID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterFanControlAttributeAirflowDirectionID: MTRAttributeIDType { .MTRClusterBasicAttributeManufacturingDateID }
    public static var clusterFanControlAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterFanControlAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterFanControlAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterFanControlAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterFanControlAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterThermostatUserInterfaceConfigurationAttributeTemperatureDisplayModeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterThermostatUserInterfaceConfigurationAttributeKeypadLockoutID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterThermostatUserInterfaceConfigurationAttributeScheduleProgrammingVisibilityID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterThermostatUserInterfaceConfigurationAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterThermostatUserInterfaceConfigurationAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterThermostatUserInterfaceConfigurationAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterThermostatUserInterfaceConfigurationAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterThermostatUserInterfaceConfigurationAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterThermostatUserInterfaceConfigurationAttributeTemperatureDisplayModeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterThermostatUserInterfaceConfigurationAttributeKeypadLockoutID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterThermostatUserInterfaceConfigurationAttributeScheduleProgrammingVisibilityID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterThermostatUserInterfaceConfigurationAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterThermostatUserInterfaceConfigurationAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterThermostatUserInterfaceConfigurationAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterThermostatUserInterfaceConfigurationAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterThermostatUserInterfaceConfigurationAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterColorControlAttributeCurrentHueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterColorControlAttributeCurrentSaturationID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterColorControlAttributeRemainingTimeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterColorControlAttributeCurrentXID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterColorControlAttributeCurrentYID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterColorControlAttributeDriftCompensationID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var MTRClusterColorControlAttributeCompensationTextID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var MTRClusterColorControlAttributeColorTemperatureMiredsID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var MTRClusterColorControlAttributeColorModeID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var MTRClusterColorControlAttributeOptionsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOptionsID }
    public static var MTRClusterColorControlAttributeNumberOfPrimariesID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var MTRClusterColorControlAttributePrimary1XID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var MTRClusterColorControlAttributePrimary1YID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var MTRClusterColorControlAttributePrimary1IntensityID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOffTransitionTimeID }
    public static var MTRClusterColorControlAttributePrimary2XID: MTRAttributeIDType { .clusterBasicInformationAttributeSpecificationVersionID }
    public static var MTRClusterColorControlAttributePrimary2YID: MTRAttributeIDType { .clusterBasicInformationAttributeMaxPathsPerInvokeID }
    public static var MTRClusterColorControlAttributePrimary2IntensityID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatApprovedChemistryID }
    public static var MTRClusterColorControlAttributePrimary3XID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatQuantityID }
    public static var MTRClusterColorControlAttributePrimary3YID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatChargeStateID }
    public static var MTRClusterColorControlAttributePrimary3IntensityID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatTimeToFullChargeID }
    public static var MTRClusterColorControlAttributePrimary4XID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxOtherCountID }
    public static var MTRClusterColorControlAttributePrimary4YID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxRetryCountID }
    public static var MTRClusterColorControlAttributePrimary4IntensityID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxDirectMaxRetryExpiryCountID }
    public static var MTRClusterColorControlAttributePrimary5XID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrCcaCountID }
    public static var MTRClusterColorControlAttributePrimary5YID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrAbortCountID }
    public static var MTRClusterColorControlAttributePrimary5IntensityID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrBusyChannelCountID }
    public static var MTRClusterColorControlAttributePrimary6XID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxUnicastCountID }
    public static var MTRClusterColorControlAttributePrimary6YID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxBroadcastCountID }
    public static var MTRClusterColorControlAttributePrimary6IntensityID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDataCountID }
    public static var MTRClusterColorControlAttributeWhitePointXID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDestAddrFilteredCountID }
    public static var MTRClusterColorControlAttributeWhitePointYID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDuplicatedCountID }
    public static var MTRClusterColorControlAttributeColorPointRXID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrNoFrameCountID }
    public static var MTRClusterColorControlAttributeColorPointRYID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrUnknownNeighborCountID }
    public static var MTRClusterColorControlAttributeColorPointRIntensityID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrInvalidSrcAddrCountID }
    public static var MTRClusterColorControlAttributeColorPointGXID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrFcsCountID }
    public static var MTRClusterColorControlAttributeColorPointGYID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrOtherCountID }
    public static var MTRClusterColorControlAttributeColorPointGIntensityID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeActiveTimestampID }
    public static var MTRClusterColorControlAttributeColorPointBXID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeDelayID }
    public static var MTRClusterColorControlAttributeColorPointBYID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeSecurityPolicyID }
    public static var MTRClusterColorControlAttributeColorPointBIntensityID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeChannelPage0MaskID }
    public static var MTRClusterColorControlAttributeEnhancedCurrentHueID: MTRAttributeIDType { .MTRClusterOnOffAttributeGlobalSceneControlID }
    public static var MTRClusterColorControlAttributeEnhancedColorModeID: MTRAttributeIDType { .MTRClusterOnOffAttributeOnTimeID }
    public static var MTRClusterColorControlAttributeColorLoopActiveID: MTRAttributeIDType { .MTRClusterOnOffAttributeOffWaitTimeID }
    public static var MTRClusterColorControlAttributeColorLoopDirectionID: MTRAttributeIDType { .MTRClusterOnOffAttributeStartUpOnOffID }
    public static var MTRClusterColorControlAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterColorControlAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterColorControlAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterColorControlAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterColorControlAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterColorControlAttributeCurrentHueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterColorControlAttributeCurrentSaturationID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterColorControlAttributeRemainingTimeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterColorControlAttributeCurrentXID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterColorControlAttributeCurrentYID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterColorControlAttributeDriftCompensationID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterColorControlAttributeCompensationTextID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterColorControlAttributeColorTemperatureMiredsID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterColorControlAttributeColorModeID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterColorControlAttributeOptionsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOptionsID }
    public static var clusterColorControlAttributeNumberOfPrimariesID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var clusterColorControlAttributePrimary1XID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var clusterColorControlAttributePrimary1YID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var clusterColorControlAttributePrimary1IntensityID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOffTransitionTimeID }
    public static var clusterColorControlAttributePrimary2XID: MTRAttributeIDType { .clusterBasicInformationAttributeSpecificationVersionID }
    public static var clusterColorControlAttributePrimary2YID: MTRAttributeIDType { .clusterBasicInformationAttributeMaxPathsPerInvokeID }
    public static var clusterColorControlAttributePrimary2IntensityID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatApprovedChemistryID }
    public static var clusterColorControlAttributePrimary3XID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatQuantityID }
    public static var clusterColorControlAttributePrimary3YID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatChargeStateID }
    public static var clusterColorControlAttributePrimary3IntensityID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatTimeToFullChargeID }
    public static var clusterColorControlAttributePrimary4XID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxOtherCountID }
    public static var clusterColorControlAttributePrimary4YID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxRetryCountID }
    public static var clusterColorControlAttributePrimary4IntensityID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxDirectMaxRetryExpiryCountID }
    public static var clusterColorControlAttributePrimary5XID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrCcaCountID }
    public static var clusterColorControlAttributePrimary5YID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrAbortCountID }
    public static var clusterColorControlAttributePrimary5IntensityID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrBusyChannelCountID }
    public static var clusterColorControlAttributePrimary6XID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxUnicastCountID }
    public static var clusterColorControlAttributePrimary6YID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxBroadcastCountID }
    public static var clusterColorControlAttributePrimary6IntensityID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDataCountID }
    public static var clusterColorControlAttributeWhitePointXID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDestAddrFilteredCountID }
    public static var clusterColorControlAttributeWhitePointYID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDuplicatedCountID }
    public static var clusterColorControlAttributeColorPointRXID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrNoFrameCountID }
    public static var clusterColorControlAttributeColorPointRYID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrUnknownNeighborCountID }
    public static var clusterColorControlAttributeColorPointRIntensityID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrInvalidSrcAddrCountID }
    public static var clusterColorControlAttributeColorPointGXID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrFcsCountID }
    public static var clusterColorControlAttributeColorPointGYID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrOtherCountID }
    public static var clusterColorControlAttributeColorPointGIntensityID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeActiveTimestampID }
    public static var clusterColorControlAttributeColorPointBXID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeDelayID }
    public static var clusterColorControlAttributeColorPointBYID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeSecurityPolicyID }
    public static var clusterColorControlAttributeColorPointBIntensityID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeChannelPage0MaskID }
    public static var clusterColorControlAttributeEnhancedCurrentHueID: MTRAttributeIDType { .MTRClusterOnOffAttributeGlobalSceneControlID }
    public static var clusterColorControlAttributeEnhancedColorModeID: MTRAttributeIDType { .MTRClusterOnOffAttributeOnTimeID }
    public static var clusterColorControlAttributeColorLoopActiveID: MTRAttributeIDType { .MTRClusterOnOffAttributeOffWaitTimeID }
    public static var clusterColorControlAttributeColorLoopDirectionID: MTRAttributeIDType { .MTRClusterOnOffAttributeStartUpOnOffID }
    public static var clusterColorControlAttributeColorLoopTimeID: MTRAttributeIDType { .MTRClusterColorControlAttributeColorLoopTimeID }
    public static var clusterColorControlAttributeColorLoopStartEnhancedHueID: MTRAttributeIDType { .MTRClusterColorControlAttributeColorLoopStartEnhancedHueID }
    public static var clusterColorControlAttributeColorLoopStoredEnhancedHueID: MTRAttributeIDType { .MTRClusterColorControlAttributeColorLoopStoredEnhancedHueID }
    public static var clusterColorControlAttributeColorCapabilitiesID: MTRAttributeIDType { .MTRClusterColorControlAttributeColorCapabilitiesID }
    public static var clusterColorControlAttributeColorTempPhysicalMinMiredsID: MTRAttributeIDType { .MTRClusterColorControlAttributeColorTempPhysicalMinMiredsID }
    public static var clusterColorControlAttributeColorTempPhysicalMaxMiredsID: MTRAttributeIDType { .MTRClusterColorControlAttributeColorTempPhysicalMaxMiredsID }
    public static var clusterColorControlAttributeCoupleColorTempToLevelMinMiredsID: MTRAttributeIDType { .MTRClusterColorControlAttributeCoupleColorTempToLevelMinMiredsID }
    public static var clusterColorControlAttributeStartUpColorTemperatureMiredsID: MTRAttributeIDType { .MTRClusterColorControlAttributeStartUpColorTemperatureMiredsID }
    public static var clusterColorControlAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterColorControlAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterColorControlAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterColorControlAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterColorControlAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterBallastConfigurationAttributePhysicalMinLevelID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterBallastConfigurationAttributePhysicalMaxLevelID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterBallastConfigurationAttributeBallastStatusID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterBallastConfigurationAttributeMinLevelID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var MTRClusterBallastConfigurationAttributeMaxLevelID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var MTRClusterBallastConfigurationAttributeIntrinsicBalanceFactorID: MTRAttributeIDType { .MTRClusterLevelControlAttributeDefaultMoveRateID }
    public static var MTRClusterBallastConfigurationAttributeBallastFactorAdjustmentID: MTRAttributeIDType { .clusterBasicInformationAttributeSpecificationVersionID }
    public static var MTRClusterBallastConfigurationAttributeLampQuantityID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxOtherCountID }
    public static var MTRClusterBallastConfigurationAttributeLampTypeID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDestAddrFilteredCountID }
    public static var MTRClusterBallastConfigurationAttributeLampManufacturerID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDuplicatedCountID }
    public static var MTRClusterBallastConfigurationAttributeLampRatedHoursID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrNoFrameCountID }
    public static var MTRClusterBallastConfigurationAttributeLampBurnHoursID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrUnknownNeighborCountID }
    public static var MTRClusterBallastConfigurationAttributeLampAlarmModeID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrInvalidSrcAddrCountID }
    public static var MTRClusterBallastConfigurationAttributeLampBurnHoursTripPointID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrSecCountID }
    public static var MTRClusterBallastConfigurationAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterBallastConfigurationAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterBallastConfigurationAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterBallastConfigurationAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterBallastConfigurationAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterBallastConfigurationAttributePhysicalMinLevelID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterBallastConfigurationAttributePhysicalMaxLevelID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterBallastConfigurationAttributeBallastStatusID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterBallastConfigurationAttributeMinLevelID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var clusterBallastConfigurationAttributeMaxLevelID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var clusterBallastConfigurationAttributeIntrinsicBallastFactorID: MTRAttributeIDType { .MTRClusterLevelControlAttributeDefaultMoveRateID }
    public static var clusterBallastConfigurationAttributeBallastFactorAdjustmentID: MTRAttributeIDType { .clusterBasicInformationAttributeSpecificationVersionID }
    public static var clusterBallastConfigurationAttributeLampQuantityID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxOtherCountID }
    public static var clusterBallastConfigurationAttributeLampTypeID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDestAddrFilteredCountID }
    public static var clusterBallastConfigurationAttributeLampManufacturerID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDuplicatedCountID }
    public static var clusterBallastConfigurationAttributeLampRatedHoursID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrNoFrameCountID }
    public static var clusterBallastConfigurationAttributeLampBurnHoursID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrUnknownNeighborCountID }
    public static var clusterBallastConfigurationAttributeLampAlarmModeID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrInvalidSrcAddrCountID }
    public static var clusterBallastConfigurationAttributeLampBurnHoursTripPointID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrSecCountID }
    public static var clusterBallastConfigurationAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterBallastConfigurationAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterBallastConfigurationAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterBallastConfigurationAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterBallastConfigurationAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterIlluminanceMeasurementAttributeMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterIlluminanceMeasurementAttributeMinMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterIlluminanceMeasurementAttributeMaxMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterIlluminanceMeasurementAttributeToleranceID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterIlluminanceMeasurementAttributeLightSensorTypeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterIlluminanceMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterIlluminanceMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterIlluminanceMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterIlluminanceMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterIlluminanceMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterIlluminanceMeasurementAttributeMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterIlluminanceMeasurementAttributeMinMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterIlluminanceMeasurementAttributeMaxMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterIlluminanceMeasurementAttributeToleranceID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterIlluminanceMeasurementAttributeLightSensorTypeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterIlluminanceMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterIlluminanceMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterIlluminanceMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterIlluminanceMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterIlluminanceMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterTemperatureMeasurementAttributeMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterTemperatureMeasurementAttributeMinMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterTemperatureMeasurementAttributeMaxMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterTemperatureMeasurementAttributeToleranceID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterTemperatureMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterTemperatureMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterTemperatureMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterTemperatureMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterTemperatureMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterTemperatureMeasurementAttributeMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterTemperatureMeasurementAttributeMinMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterTemperatureMeasurementAttributeMaxMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterTemperatureMeasurementAttributeToleranceID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterTemperatureMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterTemperatureMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterTemperatureMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterTemperatureMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterTemperatureMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterPressureMeasurementAttributeMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterPressureMeasurementAttributeMinMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterPressureMeasurementAttributeMaxMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterPressureMeasurementAttributeToleranceID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterPressureMeasurementAttributeScaledValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var MTRClusterPressureMeasurementAttributeMinScaledValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var MTRClusterPressureMeasurementAttributeMaxScaledValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var MTRClusterPressureMeasurementAttributeScaledToleranceID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOffTransitionTimeID }
    public static var MTRClusterPressureMeasurementAttributeScaleID: MTRAttributeIDType { .MTRClusterLevelControlAttributeDefaultMoveRateID }
    public static var MTRClusterPressureMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterPressureMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterPressureMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterPressureMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterPressureMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterPressureMeasurementAttributeMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterPressureMeasurementAttributeMinMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterPressureMeasurementAttributeMaxMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterPressureMeasurementAttributeToleranceID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterPressureMeasurementAttributeScaledValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var clusterPressureMeasurementAttributeMinScaledValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var clusterPressureMeasurementAttributeMaxScaledValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var clusterPressureMeasurementAttributeScaledToleranceID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOffTransitionTimeID }
    public static var clusterPressureMeasurementAttributeScaleID: MTRAttributeIDType { .MTRClusterLevelControlAttributeDefaultMoveRateID }
    public static var clusterPressureMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterPressureMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterPressureMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterPressureMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterPressureMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterFlowMeasurementAttributeMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterFlowMeasurementAttributeMinMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterFlowMeasurementAttributeMaxMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterFlowMeasurementAttributeToleranceID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterFlowMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterFlowMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterFlowMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterFlowMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterFlowMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterFlowMeasurementAttributeMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterFlowMeasurementAttributeMinMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterFlowMeasurementAttributeMaxMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterFlowMeasurementAttributeToleranceID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterFlowMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterFlowMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterFlowMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterFlowMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterFlowMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterRelativeHumidityMeasurementAttributeMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterRelativeHumidityMeasurementAttributeMinMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterRelativeHumidityMeasurementAttributeMaxMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterRelativeHumidityMeasurementAttributeToleranceID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterRelativeHumidityMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterRelativeHumidityMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterRelativeHumidityMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterRelativeHumidityMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterRelativeHumidityMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterRelativeHumidityMeasurementAttributeMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterRelativeHumidityMeasurementAttributeMinMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterRelativeHumidityMeasurementAttributeMaxMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterRelativeHumidityMeasurementAttributeToleranceID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterRelativeHumidityMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterRelativeHumidityMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterRelativeHumidityMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterRelativeHumidityMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterRelativeHumidityMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterOccupancySensingAttributeOccupancyID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterOccupancySensingAttributeOccupancySensorTypeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterOccupancySensingAttributeOccupancySensorTypeBitmapID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterOccupancySensingAttributePirOccupiedToUnoccupiedDelayID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var MTRClusterOccupancySensingAttributePirUnoccupiedToOccupiedDelayID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var MTRClusterOccupancySensingAttributePirUnoccupiedToOccupiedThresholdID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var MTRClusterOccupancySensingAttributeUltrasonicOccupiedToUnoccupiedDelayID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxOtherCountID }
    public static var MTRClusterOccupancySensingAttributeUltrasonicUnoccupiedToOccupiedDelayID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxRetryCountID }
    public static var MTRClusterOccupancySensingAttributeUltrasonicUnoccupiedToOccupiedThresholdID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxDirectMaxRetryExpiryCountID }
    public static var MTRClusterOccupancySensingAttributePhysicalContactOccupiedToUnoccupiedDelayID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDestAddrFilteredCountID }
    public static var MTRClusterOccupancySensingAttributePhysicalContactUnoccupiedToOccupiedDelayID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDuplicatedCountID }
    public static var MTRClusterOccupancySensingAttributePhysicalContactUnoccupiedToOccupiedThresholdID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrNoFrameCountID }
    public static var MTRClusterOccupancySensingAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterOccupancySensingAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterOccupancySensingAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterOccupancySensingAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterOccupancySensingAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterOccupancySensingAttributeOccupancyID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterOccupancySensingAttributeOccupancySensorTypeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterOccupancySensingAttributeOccupancySensorTypeBitmapID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterOccupancySensingAttributeHoldTimeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterOccupancySensingAttributeHoldTimeLimitsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterOccupancySensingAttributePIROccupiedToUnoccupiedDelayID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var clusterOccupancySensingAttributePIRUnoccupiedToOccupiedDelayID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var clusterOccupancySensingAttributePIRUnoccupiedToOccupiedThresholdID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var clusterOccupancySensingAttributeUltrasonicOccupiedToUnoccupiedDelayID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxOtherCountID }
    public static var clusterOccupancySensingAttributeUltrasonicUnoccupiedToOccupiedDelayID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxRetryCountID }
    public static var clusterOccupancySensingAttributeUltrasonicUnoccupiedToOccupiedThresholdID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxDirectMaxRetryExpiryCountID }
    public static var clusterOccupancySensingAttributePhysicalContactOccupiedToUnoccupiedDelayID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDestAddrFilteredCountID }
    public static var clusterOccupancySensingAttributePhysicalContactUnoccupiedToOccupiedDelayID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDuplicatedCountID }
    public static var clusterOccupancySensingAttributePhysicalContactUnoccupiedToOccupiedThresholdID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrNoFrameCountID }
    public static var clusterOccupancySensingAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterOccupancySensingAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterOccupancySensingAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterOccupancySensingAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterOccupancySensingAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterCarbonMonoxideConcentrationMeasurementAttributeMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterCarbonMonoxideConcentrationMeasurementAttributeMinMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterCarbonMonoxideConcentrationMeasurementAttributeMaxMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterCarbonMonoxideConcentrationMeasurementAttributePeakMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterCarbonMonoxideConcentrationMeasurementAttributePeakMeasuredValueWindowID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterCarbonMonoxideConcentrationMeasurementAttributeAverageMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterCarbonMonoxideConcentrationMeasurementAttributeAverageMeasuredValueWindowID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterCarbonMonoxideConcentrationMeasurementAttributeUncertaintyID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterCarbonMonoxideConcentrationMeasurementAttributeMeasurementUnitID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterCarbonMonoxideConcentrationMeasurementAttributeMeasurementMediumID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterCarbonMonoxideConcentrationMeasurementAttributeLevelValueID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterCarbonMonoxideConcentrationMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterCarbonMonoxideConcentrationMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterCarbonMonoxideConcentrationMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterCarbonMonoxideConcentrationMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterCarbonMonoxideConcentrationMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterCarbonDioxideConcentrationMeasurementAttributeMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterCarbonDioxideConcentrationMeasurementAttributeMinMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterCarbonDioxideConcentrationMeasurementAttributeMaxMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterCarbonDioxideConcentrationMeasurementAttributePeakMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterCarbonDioxideConcentrationMeasurementAttributePeakMeasuredValueWindowID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterCarbonDioxideConcentrationMeasurementAttributeAverageMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterCarbonDioxideConcentrationMeasurementAttributeAverageMeasuredValueWindowID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterCarbonDioxideConcentrationMeasurementAttributeUncertaintyID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterCarbonDioxideConcentrationMeasurementAttributeMeasurementUnitID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterCarbonDioxideConcentrationMeasurementAttributeMeasurementMediumID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterCarbonDioxideConcentrationMeasurementAttributeLevelValueID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterCarbonDioxideConcentrationMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterCarbonDioxideConcentrationMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterCarbonDioxideConcentrationMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterCarbonDioxideConcentrationMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterCarbonDioxideConcentrationMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterNitrogenDioxideConcentrationMeasurementAttributeMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterNitrogenDioxideConcentrationMeasurementAttributeMinMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterNitrogenDioxideConcentrationMeasurementAttributeMaxMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterNitrogenDioxideConcentrationMeasurementAttributePeakMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterNitrogenDioxideConcentrationMeasurementAttributePeakMeasuredValueWindowID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterNitrogenDioxideConcentrationMeasurementAttributeAverageMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterNitrogenDioxideConcentrationMeasurementAttributeAverageMeasuredValueWindowID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterNitrogenDioxideConcentrationMeasurementAttributeUncertaintyID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterNitrogenDioxideConcentrationMeasurementAttributeMeasurementUnitID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterNitrogenDioxideConcentrationMeasurementAttributeMeasurementMediumID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterNitrogenDioxideConcentrationMeasurementAttributeLevelValueID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterNitrogenDioxideConcentrationMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterNitrogenDioxideConcentrationMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterNitrogenDioxideConcentrationMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterNitrogenDioxideConcentrationMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterNitrogenDioxideConcentrationMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterOzoneConcentrationMeasurementAttributeMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterOzoneConcentrationMeasurementAttributeMinMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterOzoneConcentrationMeasurementAttributeMaxMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterOzoneConcentrationMeasurementAttributePeakMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterOzoneConcentrationMeasurementAttributePeakMeasuredValueWindowID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterOzoneConcentrationMeasurementAttributeAverageMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterOzoneConcentrationMeasurementAttributeAverageMeasuredValueWindowID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterOzoneConcentrationMeasurementAttributeUncertaintyID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterOzoneConcentrationMeasurementAttributeMeasurementUnitID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterOzoneConcentrationMeasurementAttributeMeasurementMediumID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterOzoneConcentrationMeasurementAttributeLevelValueID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterOzoneConcentrationMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterOzoneConcentrationMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterOzoneConcentrationMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterOzoneConcentrationMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterOzoneConcentrationMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterPM25ConcentrationMeasurementAttributeMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterPM25ConcentrationMeasurementAttributeMinMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterPM25ConcentrationMeasurementAttributeMaxMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterPM25ConcentrationMeasurementAttributePeakMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterPM25ConcentrationMeasurementAttributePeakMeasuredValueWindowID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterPM25ConcentrationMeasurementAttributeAverageMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterPM25ConcentrationMeasurementAttributeAverageMeasuredValueWindowID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterPM25ConcentrationMeasurementAttributeUncertaintyID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterPM25ConcentrationMeasurementAttributeMeasurementUnitID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterPM25ConcentrationMeasurementAttributeMeasurementMediumID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterPM25ConcentrationMeasurementAttributeLevelValueID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterPM25ConcentrationMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterPM25ConcentrationMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterPM25ConcentrationMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterPM25ConcentrationMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterPM25ConcentrationMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterFormaldehydeConcentrationMeasurementAttributeMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterFormaldehydeConcentrationMeasurementAttributeMinMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterFormaldehydeConcentrationMeasurementAttributeMaxMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterFormaldehydeConcentrationMeasurementAttributePeakMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterFormaldehydeConcentrationMeasurementAttributePeakMeasuredValueWindowID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterFormaldehydeConcentrationMeasurementAttributeAverageMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterFormaldehydeConcentrationMeasurementAttributeAverageMeasuredValueWindowID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterFormaldehydeConcentrationMeasurementAttributeUncertaintyID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterFormaldehydeConcentrationMeasurementAttributeMeasurementUnitID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterFormaldehydeConcentrationMeasurementAttributeMeasurementMediumID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterFormaldehydeConcentrationMeasurementAttributeLevelValueID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterFormaldehydeConcentrationMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterFormaldehydeConcentrationMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterFormaldehydeConcentrationMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterFormaldehydeConcentrationMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterFormaldehydeConcentrationMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterPM1ConcentrationMeasurementAttributeMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterPM1ConcentrationMeasurementAttributeMinMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterPM1ConcentrationMeasurementAttributeMaxMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterPM1ConcentrationMeasurementAttributePeakMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterPM1ConcentrationMeasurementAttributePeakMeasuredValueWindowID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterPM1ConcentrationMeasurementAttributeAverageMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterPM1ConcentrationMeasurementAttributeAverageMeasuredValueWindowID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterPM1ConcentrationMeasurementAttributeUncertaintyID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterPM1ConcentrationMeasurementAttributeMeasurementUnitID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterPM1ConcentrationMeasurementAttributeMeasurementMediumID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterPM1ConcentrationMeasurementAttributeLevelValueID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterPM1ConcentrationMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterPM1ConcentrationMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterPM1ConcentrationMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterPM1ConcentrationMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterPM1ConcentrationMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterPM10ConcentrationMeasurementAttributeMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterPM10ConcentrationMeasurementAttributeMinMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterPM10ConcentrationMeasurementAttributeMaxMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterPM10ConcentrationMeasurementAttributePeakMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterPM10ConcentrationMeasurementAttributePeakMeasuredValueWindowID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterPM10ConcentrationMeasurementAttributeAverageMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterPM10ConcentrationMeasurementAttributeAverageMeasuredValueWindowID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterPM10ConcentrationMeasurementAttributeUncertaintyID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterPM10ConcentrationMeasurementAttributeMeasurementUnitID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterPM10ConcentrationMeasurementAttributeMeasurementMediumID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterPM10ConcentrationMeasurementAttributeLevelValueID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterPM10ConcentrationMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterPM10ConcentrationMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterPM10ConcentrationMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterPM10ConcentrationMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterPM10ConcentrationMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterTotalVolatileOrganicCompoundsConcentrationMeasurementAttributeMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterTotalVolatileOrganicCompoundsConcentrationMeasurementAttributeMinMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterTotalVolatileOrganicCompoundsConcentrationMeasurementAttributeMaxMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterTotalVolatileOrganicCompoundsConcentrationMeasurementAttributePeakMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterTotalVolatileOrganicCompoundsConcentrationMeasurementAttributePeakMeasuredValueWindowID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterTotalVolatileOrganicCompoundsConcentrationMeasurementAttributeAverageMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterTotalVolatileOrganicCompoundsConcentrationMeasurementAttributeAverageMeasuredValueWindowID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterTotalVolatileOrganicCompoundsConcentrationMeasurementAttributeUncertaintyID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterTotalVolatileOrganicCompoundsConcentrationMeasurementAttributeMeasurementUnitID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterTotalVolatileOrganicCompoundsConcentrationMeasurementAttributeMeasurementMediumID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterTotalVolatileOrganicCompoundsConcentrationMeasurementAttributeLevelValueID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterTotalVolatileOrganicCompoundsConcentrationMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterTotalVolatileOrganicCompoundsConcentrationMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterTotalVolatileOrganicCompoundsConcentrationMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterTotalVolatileOrganicCompoundsConcentrationMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterTotalVolatileOrganicCompoundsConcentrationMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterRadonConcentrationMeasurementAttributeMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterRadonConcentrationMeasurementAttributeMinMeasuredValueID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterRadonConcentrationMeasurementAttributeMaxMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterRadonConcentrationMeasurementAttributePeakMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterRadonConcentrationMeasurementAttributePeakMeasuredValueWindowID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterRadonConcentrationMeasurementAttributeAverageMeasuredValueID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterRadonConcentrationMeasurementAttributeAverageMeasuredValueWindowID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterRadonConcentrationMeasurementAttributeUncertaintyID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterRadonConcentrationMeasurementAttributeMeasurementUnitID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterRadonConcentrationMeasurementAttributeMeasurementMediumID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterRadonConcentrationMeasurementAttributeLevelValueID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterRadonConcentrationMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterRadonConcentrationMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterRadonConcentrationMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterRadonConcentrationMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterRadonConcentrationMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterWiFiNetworkManagementAttributeSSIDID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterWiFiNetworkManagementAttributePassphraseSurrogateID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterWiFiNetworkManagementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterWiFiNetworkManagementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterWiFiNetworkManagementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterWiFiNetworkManagementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterWiFiNetworkManagementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterThreadBorderRouterManagementAttributeBorderRouterNameID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterThreadBorderRouterManagementAttributeBorderAgentIDID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterThreadBorderRouterManagementAttributeThreadVersionID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterThreadBorderRouterManagementAttributeInterfaceEnabledID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterThreadBorderRouterManagementAttributeActiveDatasetTimestampID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterThreadBorderRouterManagementAttributePendingDatasetTimestampID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterThreadBorderRouterManagementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterThreadBorderRouterManagementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterThreadBorderRouterManagementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterThreadBorderRouterManagementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterThreadBorderRouterManagementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterThreadNetworkDirectoryAttributePreferredExtendedPanIDID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterThreadNetworkDirectoryAttributeThreadNetworksID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterThreadNetworkDirectoryAttributeThreadNetworkTableSizeID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterThreadNetworkDirectoryAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterThreadNetworkDirectoryAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterThreadNetworkDirectoryAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterThreadNetworkDirectoryAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterThreadNetworkDirectoryAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterWakeOnLanAttributeMACAddressID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterWakeOnLanAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterWakeOnLanAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterWakeOnLanAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterWakeOnLanAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterWakeOnLanAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterWakeOnLANAttributeMACAddressID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterWakeOnLANAttributeLinkLocalAddressID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterWakeOnLANAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterWakeOnLANAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterWakeOnLANAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterWakeOnLANAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterWakeOnLANAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterChannelAttributeChannelListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterChannelAttributeLineupID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterChannelAttributeCurrentChannelID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterChannelAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterChannelAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterChannelAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterChannelAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterChannelAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterChannelAttributeChannelListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterChannelAttributeLineupID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterChannelAttributeCurrentChannelID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterChannelAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterChannelAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterChannelAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterChannelAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterChannelAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterTargetNavigatorAttributeTargetListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterTargetNavigatorAttributeCurrentTargetID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterTargetNavigatorAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterTargetNavigatorAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterTargetNavigatorAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterTargetNavigatorAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterTargetNavigatorAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterTargetNavigatorAttributeTargetListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterTargetNavigatorAttributeCurrentTargetID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterTargetNavigatorAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterTargetNavigatorAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterTargetNavigatorAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterTargetNavigatorAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterTargetNavigatorAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterMediaPlaybackAttributeCurrentStateID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterMediaPlaybackAttributeStartTimeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterMediaPlaybackAttributeDurationID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterMediaPlaybackAttributeSampledPositionID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterMediaPlaybackAttributePlaybackSpeedID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterMediaPlaybackAttributeSeekRangeEndID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var MTRClusterMediaPlaybackAttributeSeekRangeStartID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var MTRClusterMediaPlaybackAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterMediaPlaybackAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterMediaPlaybackAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterMediaPlaybackAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterMediaPlaybackAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterMediaPlaybackAttributeCurrentStateID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterMediaPlaybackAttributeStartTimeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterMediaPlaybackAttributeDurationID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterMediaPlaybackAttributeSampledPositionID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterMediaPlaybackAttributePlaybackSpeedID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterMediaPlaybackAttributeSeekRangeEndID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterMediaPlaybackAttributeSeekRangeStartID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterMediaPlaybackAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterMediaPlaybackAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterMediaPlaybackAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterMediaPlaybackAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterMediaPlaybackAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterMediaInputAttributeInputListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterMediaInputAttributeCurrentInputID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterMediaInputAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterMediaInputAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterMediaInputAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterMediaInputAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterMediaInputAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterMediaInputAttributeInputListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterMediaInputAttributeCurrentInputID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterMediaInputAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterMediaInputAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterMediaInputAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterMediaInputAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterMediaInputAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterLowPowerAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterLowPowerAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterLowPowerAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterLowPowerAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterLowPowerAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterLowPowerAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterLowPowerAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterLowPowerAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterLowPowerAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterLowPowerAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterKeypadInputAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterKeypadInputAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterKeypadInputAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterKeypadInputAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterKeypadInputAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterKeypadInputAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterKeypadInputAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterKeypadInputAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterKeypadInputAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterKeypadInputAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterContentLauncherAttributeAcceptHeaderID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterContentLauncherAttributeSupportedStreamingProtocolsID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterContentLauncherAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterContentLauncherAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterContentLauncherAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterContentLauncherAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterContentLauncherAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterContentLauncherAttributeAcceptHeaderID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterContentLauncherAttributeSupportedStreamingProtocolsID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterContentLauncherAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterContentLauncherAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterContentLauncherAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterContentLauncherAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterContentLauncherAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterAudioOutputAttributeOutputListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterAudioOutputAttributeCurrentOutputID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterAudioOutputAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterAudioOutputAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterAudioOutputAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterAudioOutputAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterAudioOutputAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterAudioOutputAttributeOutputListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterAudioOutputAttributeCurrentOutputID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterAudioOutputAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterAudioOutputAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterAudioOutputAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterAudioOutputAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterAudioOutputAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterApplicationLauncherAttributeCatalogListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterApplicationLauncherAttributeCurrentAppID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterApplicationLauncherAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterApplicationLauncherAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterApplicationLauncherAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterApplicationLauncherAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterApplicationLauncherAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterApplicationLauncherAttributeCatalogListID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterApplicationLauncherAttributeCurrentAppID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterApplicationLauncherAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterApplicationLauncherAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterApplicationLauncherAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterApplicationLauncherAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterApplicationLauncherAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterApplicationBasicAttributeVendorNameID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterApplicationBasicAttributeVendorIDID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterApplicationBasicAttributeApplicationNameID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterApplicationBasicAttributeProductIDID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterApplicationBasicAttributeApplicationID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterApplicationBasicAttributeStatusID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var MTRClusterApplicationBasicAttributeApplicationVersionID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var MTRClusterApplicationBasicAttributeAllowedVendorListID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var MTRClusterApplicationBasicAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterApplicationBasicAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterApplicationBasicAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterApplicationBasicAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterApplicationBasicAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterApplicationBasicAttributeVendorNameID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterApplicationBasicAttributeVendorIDID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterApplicationBasicAttributeApplicationNameID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterApplicationBasicAttributeProductIDID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterApplicationBasicAttributeApplicationID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterApplicationBasicAttributeStatusID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterApplicationBasicAttributeApplicationVersionID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterApplicationBasicAttributeAllowedVendorListID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterApplicationBasicAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterApplicationBasicAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterApplicationBasicAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterApplicationBasicAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterApplicationBasicAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterAccountLoginAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterAccountLoginAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterAccountLoginAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterAccountLoginAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterAccountLoginAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterAccountLoginAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterAccountLoginAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterAccountLoginAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterAccountLoginAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterAccountLoginAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterContentAppObserverAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterContentAppObserverAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterContentAppObserverAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterContentAppObserverAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterContentAppObserverAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterCommissionerControlAttributeSupportedDeviceCategoriesID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterCommissionerControlAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterCommissionerControlAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterCommissionerControlAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterCommissionerControlAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterCommissionerControlAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterTestClusterAttributeBooleanID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterTestClusterAttributeBitmap8ID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterTestClusterAttributeBitmap16ID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterTestClusterAttributeBitmap32ID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterTestClusterAttributeBitmap64ID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterTestClusterAttributeInt8uID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var MTRClusterTestClusterAttributeInt16uID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var MTRClusterTestClusterAttributeInt24uID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var MTRClusterTestClusterAttributeInt32uID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var MTRClusterTestClusterAttributeInt40uID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var MTRClusterTestClusterAttributeInt48uID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var MTRClusterTestClusterAttributeInt56uID: MTRAttributeIDType { .MTRClusterBasicAttributeManufacturingDateID }
    public static var MTRClusterTestClusterAttributeInt64uID: MTRAttributeIDType { .MTRClusterBasicAttributePartNumberID }
    public static var MTRClusterTestClusterAttributeInt8sID: MTRAttributeIDType { .MTRClusterBasicAttributeProductURLID }
    public static var MTRClusterTestClusterAttributeInt16sID: MTRAttributeIDType { .MTRClusterBasicAttributeProductLabelID }
    public static var MTRClusterTestClusterAttributeInt24sID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOptionsID }
    public static var MTRClusterTestClusterAttributeInt32sID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var MTRClusterTestClusterAttributeInt40sID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var MTRClusterTestClusterAttributeInt48sID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var MTRClusterTestClusterAttributeInt56sID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOffTransitionTimeID }
    public static var MTRClusterTestClusterAttributeInt64sID: MTRAttributeIDType { .MTRClusterLevelControlAttributeDefaultMoveRateID }
    public static var MTRClusterTestClusterAttributeEnum8ID: MTRAttributeIDType { .clusterBasicInformationAttributeSpecificationVersionID }
    public static var MTRClusterTestClusterAttributeEnum16ID: MTRAttributeIDType { .clusterBasicInformationAttributeMaxPathsPerInvokeID }
    public static var MTRClusterTestClusterAttributeFloatSingleID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatApprovedChemistryID }
    public static var MTRClusterTestClusterAttributeFloatDoubleID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatCapacityID }
    public static var MTRClusterTestClusterAttributeOctetStringID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatQuantityID }
    public static var MTRClusterTestClusterAttributeListInt8uID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatChargeStateID }
    public static var MTRClusterTestClusterAttributeListOctetStringID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatTimeToFullChargeID }
    public static var MTRClusterTestClusterAttributeListStructOctetStringID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatFunctionalWhileChargingID }
    public static var MTRClusterTestClusterAttributeLongOctetStringID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatChargingCurrentID }
    public static var MTRClusterTestClusterAttributeCharStringID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeActiveBatChargeFaultsID }
    public static var MTRClusterTestClusterAttributeLongCharStringID: MTRAttributeIDType { .clusterPowerSourceAttributeEndpointListID }
    public static var MTRClusterTestClusterAttributeEpochUsID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxOtherCountID }
    public static var MTRClusterTestClusterAttributeEpochSID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxRetryCountID }
    public static var MTRClusterTestClusterAttributeVendorIdID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxDirectMaxRetryExpiryCountID }
    public static var MTRClusterTestClusterAttributeListNullablesAndOptionalsStructID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxIndirectMaxRetryExpiryCountID }
    public static var MTRClusterTestClusterAttributeEnumAttrID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrCcaCountID }
    public static var MTRClusterTestClusterAttributeStructAttrID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrAbortCountID }
    public static var MTRClusterTestClusterAttributeRangeRestrictedInt8uID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrBusyChannelCountID }
    public static var MTRClusterTestClusterAttributeRangeRestrictedInt8sID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxTotalCountID }
    public static var MTRClusterTestClusterAttributeRangeRestrictedInt16uID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxUnicastCountID }
    public static var MTRClusterTestClusterAttributeRangeRestrictedInt16sID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxBroadcastCountID }
    public static var MTRClusterTestClusterAttributeListLongOctetStringID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDataCountID }
    public static var MTRClusterTestClusterAttributeListFabricScopedID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDataPollCountID }
    public static var MTRClusterTestClusterAttributeTimedWriteBooleanID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDestAddrFilteredCountID }
    public static var MTRClusterTestClusterAttributeGeneralErrorBooleanID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDuplicatedCountID }
    public static var MTRClusterTestClusterAttributeClusterErrorBooleanID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrNoFrameCountID }
    public static var MTRClusterTestClusterAttributeNullableBooleanID: MTRAttributeIDType { .MTRClusterOnOffAttributeGlobalSceneControlID }
    public static var MTRClusterTestClusterAttributeNullableBitmap8ID: MTRAttributeIDType { .MTRClusterOnOffAttributeOnTimeID }
    public static var MTRClusterTestClusterAttributeNullableBitmap16ID: MTRAttributeIDType { .MTRClusterOnOffAttributeOffWaitTimeID }
    public static var MTRClusterTestClusterAttributeNullableBitmap32ID: MTRAttributeIDType { .MTRClusterOnOffAttributeStartUpOnOffID }
    public static var MTRClusterTestClusterAttributeNullableBitmap64ID: MTRAttributeIDType { .MTRClusterColorControlAttributeColorLoopTimeID }
    public static var MTRClusterTestClusterAttributeNullableInt8uID: MTRAttributeIDType { .MTRClusterColorControlAttributeColorLoopStartEnhancedHueID }
    public static var MTRClusterTestClusterAttributeNullableInt16uID: MTRAttributeIDType { .MTRClusterColorControlAttributeColorLoopStoredEnhancedHueID }
    public static var MTRClusterTestClusterAttributeNullableInt48uID: MTRAttributeIDType { .MTRClusterColorControlAttributeColorCapabilitiesID }
    public static var MTRClusterTestClusterAttributeNullableInt56uID: MTRAttributeIDType { .MTRClusterColorControlAttributeColorTempPhysicalMinMiredsID }
    public static var MTRClusterTestClusterAttributeNullableInt64uID: MTRAttributeIDType { .MTRClusterColorControlAttributeColorTempPhysicalMaxMiredsID }
    public static var MTRClusterTestClusterAttributeNullableInt8sID: MTRAttributeIDType { .MTRClusterColorControlAttributeCoupleColorTempToLevelMinMiredsID }
    public static var MTRClusterTestClusterAttributeNullableInt32sID: MTRAttributeIDType { .MTRClusterColorControlAttributeStartUpColorTemperatureMiredsID }
    public static var MTRClusterTestClusterAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterTestClusterAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterTestClusterAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterTestClusterAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterTestClusterAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterUnitTestingAttributeBooleanID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterUnitTestingAttributeBitmap8ID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterUnitTestingAttributeBitmap16ID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterUnitTestingAttributeBitmap32ID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterUnitTestingAttributeBitmap64ID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterUnitTestingAttributeInt8uID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterUnitTestingAttributeInt16uID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterUnitTestingAttributeInt24uID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterUnitTestingAttributeInt32uID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterUnitTestingAttributeInt40uID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterUnitTestingAttributeInt48uID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterUnitTestingAttributeInt56uID: MTRAttributeIDType { .MTRClusterBasicAttributeManufacturingDateID }
    public static var clusterUnitTestingAttributeInt64uID: MTRAttributeIDType { .MTRClusterBasicAttributePartNumberID }
    public static var clusterUnitTestingAttributeInt8sID: MTRAttributeIDType { .MTRClusterBasicAttributeProductURLID }
    public static var clusterUnitTestingAttributeInt16sID: MTRAttributeIDType { .MTRClusterBasicAttributeProductLabelID }
    public static var clusterUnitTestingAttributeInt24sID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOptionsID }
    public static var clusterUnitTestingAttributeInt32sID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var clusterUnitTestingAttributeInt40sID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnLevelID }
    public static var clusterUnitTestingAttributeInt48sID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnTransitionTimeID }
    public static var clusterUnitTestingAttributeInt56sID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOffTransitionTimeID }
    public static var clusterUnitTestingAttributeInt64sID: MTRAttributeIDType { .MTRClusterLevelControlAttributeDefaultMoveRateID }
    public static var clusterUnitTestingAttributeEnum8ID: MTRAttributeIDType { .clusterBasicInformationAttributeSpecificationVersionID }
    public static var clusterUnitTestingAttributeEnum16ID: MTRAttributeIDType { .clusterBasicInformationAttributeMaxPathsPerInvokeID }
    public static var clusterUnitTestingAttributeFloatSingleID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatApprovedChemistryID }
    public static var clusterUnitTestingAttributeFloatDoubleID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatCapacityID }
    public static var clusterUnitTestingAttributeOctetStringID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatQuantityID }
    public static var clusterUnitTestingAttributeListInt8uID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatChargeStateID }
    public static var clusterUnitTestingAttributeListOctetStringID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatTimeToFullChargeID }
    public static var clusterUnitTestingAttributeListStructOctetStringID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatFunctionalWhileChargingID }
    public static var clusterUnitTestingAttributeLongOctetStringID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatChargingCurrentID }
    public static var clusterUnitTestingAttributeCharStringID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeActiveBatChargeFaultsID }
    public static var clusterUnitTestingAttributeLongCharStringID: MTRAttributeIDType { .clusterPowerSourceAttributeEndpointListID }
    public static var clusterUnitTestingAttributeEpochUsID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxOtherCountID }
    public static var clusterUnitTestingAttributeEpochSID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxRetryCountID }
    public static var clusterUnitTestingAttributeVendorIdID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxDirectMaxRetryExpiryCountID }
    public static var clusterUnitTestingAttributeListNullablesAndOptionalsStructID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxIndirectMaxRetryExpiryCountID }
    public static var clusterUnitTestingAttributeEnumAttrID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrCcaCountID }
    public static var clusterUnitTestingAttributeStructAttrID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrAbortCountID }
    public static var clusterUnitTestingAttributeRangeRestrictedInt8uID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeTxErrBusyChannelCountID }
    public static var clusterUnitTestingAttributeRangeRestrictedInt8sID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxTotalCountID }
    public static var clusterUnitTestingAttributeRangeRestrictedInt16uID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxUnicastCountID }
    public static var clusterUnitTestingAttributeRangeRestrictedInt16sID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxBroadcastCountID }
    public static var clusterUnitTestingAttributeListLongOctetStringID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDataCountID }
    public static var clusterUnitTestingAttributeListFabricScopedID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDataPollCountID }
    public static var clusterUnitTestingAttributeTimedWriteBooleanID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDestAddrFilteredCountID }
    public static var clusterUnitTestingAttributeGeneralErrorBooleanID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxDuplicatedCountID }
    public static var clusterUnitTestingAttributeClusterErrorBooleanID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxErrNoFrameCountID }
    public static var clusterUnitTestingAttributeUnsupportedID: MTRAttributeIDType { .MTRClusterTestClusterAttributeUnsupportedID }
    public static var clusterUnitTestingAttributeNullableBooleanID: MTRAttributeIDType { .MTRClusterOnOffAttributeGlobalSceneControlID }
    public static var clusterUnitTestingAttributeNullableBitmap8ID: MTRAttributeIDType { .MTRClusterOnOffAttributeOnTimeID }
    public static var clusterUnitTestingAttributeNullableBitmap16ID: MTRAttributeIDType { .MTRClusterOnOffAttributeOffWaitTimeID }
    public static var clusterUnitTestingAttributeNullableBitmap32ID: MTRAttributeIDType { .MTRClusterOnOffAttributeStartUpOnOffID }
    public static var clusterUnitTestingAttributeNullableBitmap64ID: MTRAttributeIDType { .MTRClusterColorControlAttributeColorLoopTimeID }
    public static var clusterUnitTestingAttributeNullableInt8uID: MTRAttributeIDType { .MTRClusterColorControlAttributeColorLoopStartEnhancedHueID }
    public static var clusterUnitTestingAttributeNullableInt16uID: MTRAttributeIDType { .MTRClusterColorControlAttributeColorLoopStoredEnhancedHueID }
    public static var clusterUnitTestingAttributeNullableInt24uID: MTRAttributeIDType { .MTRClusterTestClusterAttributeNullableInt24uID }
    public static var clusterUnitTestingAttributeNullableInt32uID: MTRAttributeIDType { .MTRClusterTestClusterAttributeNullableInt32uID }
    public static var clusterUnitTestingAttributeNullableInt40uID: MTRAttributeIDType { .MTRClusterTestClusterAttributeNullableInt40uID }
    public static var clusterUnitTestingAttributeNullableInt48uID: MTRAttributeIDType { .MTRClusterColorControlAttributeColorCapabilitiesID }
    public static var clusterUnitTestingAttributeNullableInt56uID: MTRAttributeIDType { .MTRClusterColorControlAttributeColorTempPhysicalMinMiredsID }
    public static var clusterUnitTestingAttributeNullableInt64uID: MTRAttributeIDType { .MTRClusterColorControlAttributeColorTempPhysicalMaxMiredsID }
    public static var clusterUnitTestingAttributeNullableInt8sID: MTRAttributeIDType { .MTRClusterColorControlAttributeCoupleColorTempToLevelMinMiredsID }
    public static var clusterUnitTestingAttributeNullableInt16sID: MTRAttributeIDType { .MTRClusterTestClusterAttributeNullableInt16sID }
    public static var clusterUnitTestingAttributeNullableInt24sID: MTRAttributeIDType { .MTRClusterTestClusterAttributeNullableInt24sID }
    public static var clusterUnitTestingAttributeNullableInt32sID: MTRAttributeIDType { .MTRClusterColorControlAttributeStartUpColorTemperatureMiredsID }
    public static var clusterUnitTestingAttributeNullableInt40sID: MTRAttributeIDType { .MTRClusterTestClusterAttributeNullableInt40sID }
    public static var clusterUnitTestingAttributeNullableInt48sID: MTRAttributeIDType { .MTRClusterTestClusterAttributeNullableInt48sID }
    public static var clusterUnitTestingAttributeNullableInt56sID: MTRAttributeIDType { .MTRClusterTestClusterAttributeNullableInt56sID }
    public static var clusterUnitTestingAttributeNullableInt64sID: MTRAttributeIDType { .MTRClusterTestClusterAttributeNullableInt64sID }
    public static var clusterUnitTestingAttributeNullableEnum8ID: MTRAttributeIDType { .MTRClusterTestClusterAttributeNullableEnum8ID }
    public static var clusterUnitTestingAttributeNullableEnum16ID: MTRAttributeIDType { .MTRClusterTestClusterAttributeNullableEnum16ID }
    public static var clusterUnitTestingAttributeNullableFloatSingleID: MTRAttributeIDType { .MTRClusterTestClusterAttributeNullableFloatSingleID }
    public static var clusterUnitTestingAttributeNullableFloatDoubleID: MTRAttributeIDType { .MTRClusterTestClusterAttributeNullableFloatDoubleID }
    public static var clusterUnitTestingAttributeNullableOctetStringID: MTRAttributeIDType { .MTRClusterTestClusterAttributeNullableOctetStringID }
    public static var clusterUnitTestingAttributeNullableCharStringID: MTRAttributeIDType { .MTRClusterTestClusterAttributeNullableCharStringID }
    public static var clusterUnitTestingAttributeNullableEnumAttrID: MTRAttributeIDType { .MTRClusterTestClusterAttributeNullableEnumAttrID }
    public static var clusterUnitTestingAttributeNullableStructID: MTRAttributeIDType { .MTRClusterTestClusterAttributeNullableStructID }
    public static var clusterUnitTestingAttributeNullableRangeRestrictedInt8uID: MTRAttributeIDType { .MTRClusterTestClusterAttributeNullableRangeRestrictedInt8uID }
    public static var clusterUnitTestingAttributeNullableRangeRestrictedInt8sID: MTRAttributeIDType { .MTRClusterTestClusterAttributeNullableRangeRestrictedInt8sID }
    public static var clusterUnitTestingAttributeNullableRangeRestrictedInt16uID: MTRAttributeIDType { .MTRClusterTestClusterAttributeNullableRangeRestrictedInt16uID }
    public static var clusterUnitTestingAttributeNullableRangeRestrictedInt16sID: MTRAttributeIDType { .MTRClusterTestClusterAttributeNullableRangeRestrictedInt16sID }
    public static var clusterUnitTestingAttributeWriteOnlyInt8uID: MTRAttributeIDType { .MTRClusterTestClusterAttributeWriteOnlyInt8uID }
    public static var clusterUnitTestingAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterUnitTestingAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterUnitTestingAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterUnitTestingAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterUnitTestingAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterBarrierControlAttributeBarrierMovingStateID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var MTRClusterBarrierControlAttributeBarrierSafetyStatusID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var MTRClusterBarrierControlAttributeBarrierCapabilitiesID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var MTRClusterBarrierControlAttributeBarrierOpenEventsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterBarrierControlAttributeBarrierCloseEventsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var MTRClusterBarrierControlAttributeBarrierCommandOpenEventsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var MTRClusterBarrierControlAttributeBarrierCommandCloseEventsID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var MTRClusterBarrierControlAttributeBarrierOpenPeriodID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var MTRClusterBarrierControlAttributeBarrierClosePeriodID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var MTRClusterBarrierControlAttributeBarrierPositionID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var MTRClusterBarrierControlAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterBarrierControlAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterBarrierControlAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterBarrierControlAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterBarrierControlAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterBarrierControlAttributeBarrierMovingStateID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTypeID }
    public static var clusterBarrierControlAttributeBarrierSafetyStatusID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinLevelID }
    public static var clusterBarrierControlAttributeBarrierCapabilitiesID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxLevelID }
    public static var clusterBarrierControlAttributeBarrierOpenEventsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterBarrierControlAttributeBarrierCloseEventsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMinFrequencyID }
    public static var clusterBarrierControlAttributeBarrierCommandOpenEventsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeMaxFrequencyID }
    public static var clusterBarrierControlAttributeBarrierCommandCloseEventsID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionID }
    public static var clusterBarrierControlAttributeBarrierOpenPeriodID: MTRAttributeIDType { .MTRClusterBasicAttributeHardwareVersionStringID }
    public static var clusterBarrierControlAttributeBarrierClosePeriodID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionID }
    public static var clusterBarrierControlAttributeBarrierPositionID: MTRAttributeIDType { .MTRClusterBasicAttributeSoftwareVersionStringID }
    public static var clusterBarrierControlAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterBarrierControlAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterBarrierControlAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterBarrierControlAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterBarrierControlAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterBinaryInputBasicAttributeActiveTextID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var MTRClusterBinaryInputBasicAttributeDescriptionID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatFunctionalWhileChargingID }
    public static var MTRClusterBinaryInputBasicAttributeInactiveTextID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxOtherCountID }
    public static var MTRClusterBinaryInputBasicAttributeOutOfServiceID: MTRAttributeIDType { .clusterThermostatAttributeSchedulesID }
    public static var MTRClusterBinaryInputBasicAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterBinaryInputBasicAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterBinaryInputBasicAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterBinaryInputBasicAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterBinaryInputBasicAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterBinaryInputBasicAttributeActiveTextID: MTRAttributeIDType { .MTRClusterLevelControlAttributeCurrentFrequencyID }
    public static var clusterBinaryInputBasicAttributeDescriptionID: MTRAttributeIDType { .MTRClusterPowerSourceAttributeBatFunctionalWhileChargingID }
    public static var clusterBinaryInputBasicAttributeInactiveTextID: MTRAttributeIDType { .MTRClusterThreadNetworkDiagnosticsAttributeRxOtherCountID }
    public static var clusterBinaryInputBasicAttributeOutOfServiceID: MTRAttributeIDType { .clusterThermostatAttributeSchedulesID }
    public static var clusterBinaryInputBasicAttributePolarityID: MTRAttributeIDType { .MTRClusterBinaryInputBasicAttributePolarityID }
    public static var clusterBinaryInputBasicAttributePresentValueID: MTRAttributeIDType { .MTRClusterBinaryInputBasicAttributePresentValueID }
    public static var clusterBinaryInputBasicAttributeReliabilityID: MTRAttributeIDType { .MTRClusterBinaryInputBasicAttributeReliabilityID }
    public static var clusterBinaryInputBasicAttributeStatusFlagsID: MTRAttributeIDType { .MTRClusterBinaryInputBasicAttributeStatusFlagsID }
    public static var clusterBinaryInputBasicAttributeApplicationTypeID: MTRAttributeIDType { .MTRClusterBinaryInputBasicAttributeApplicationTypeID }
    public static var clusterBinaryInputBasicAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterBinaryInputBasicAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterBinaryInputBasicAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterBinaryInputBasicAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterBinaryInputBasicAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterElectricalMeasurementAttributeMeasurementTypeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterElectricalMeasurementAttributeDcVoltageID: MTRAttributeIDType { .MTRClusterBinaryInputBasicAttributeApplicationTypeID }
    public static var MTRClusterElectricalMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterElectricalMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterElectricalMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterElectricalMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterElectricalMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterElectricalMeasurementAttributeMeasurementTypeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterElectricalMeasurementAttributeDcVoltageID: MTRAttributeIDType { .MTRClusterBinaryInputBasicAttributeApplicationTypeID }
    public static var clusterElectricalMeasurementAttributeDcVoltageMinID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeDcVoltageMinID }
    public static var clusterElectricalMeasurementAttributeDcVoltageMaxID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeDcVoltageMaxID }
    public static var clusterElectricalMeasurementAttributeDcCurrentID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeDcCurrentID }
    public static var clusterElectricalMeasurementAttributeDcCurrentMinID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeDcCurrentMinID }
    public static var clusterElectricalMeasurementAttributeDcCurrentMaxID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeDcCurrentMaxID }
    public static var clusterElectricalMeasurementAttributeDcPowerID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeDcPowerID }
    public static var clusterElectricalMeasurementAttributeDcPowerMinID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeDcPowerMinID }
    public static var clusterElectricalMeasurementAttributeDcPowerMaxID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeDcPowerMaxID }
    public static var clusterElectricalMeasurementAttributeDcVoltageMultiplierID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeDcVoltageMultiplierID }
    public static var clusterElectricalMeasurementAttributeDcVoltageDivisorID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeDcVoltageDivisorID }
    public static var clusterElectricalMeasurementAttributeDcCurrentMultiplierID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeDcCurrentMultiplierID }
    public static var clusterElectricalMeasurementAttributeDcCurrentDivisorID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeDcCurrentDivisorID }
    public static var clusterElectricalMeasurementAttributeDcPowerMultiplierID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeDcPowerMultiplierID }
    public static var clusterElectricalMeasurementAttributeDcPowerDivisorID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeDcPowerDivisorID }
    public static var clusterElectricalMeasurementAttributeAcFrequencyID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAcFrequencyID }
    public static var clusterElectricalMeasurementAttributeAcFrequencyMinID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAcFrequencyMinID }
    public static var clusterElectricalMeasurementAttributeAcFrequencyMaxID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAcFrequencyMaxID }
    public static var clusterElectricalMeasurementAttributeNeutralCurrentID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeNeutralCurrentID }
    public static var clusterElectricalMeasurementAttributeTotalActivePowerID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeTotalActivePowerID }
    public static var clusterElectricalMeasurementAttributeTotalReactivePowerID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeTotalReactivePowerID }
    public static var clusterElectricalMeasurementAttributeTotalApparentPowerID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeTotalApparentPowerID }
    public static var clusterElectricalMeasurementAttributeMeasured1stHarmonicCurrentID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeMeasured1stHarmonicCurrentID }
    public static var clusterElectricalMeasurementAttributeMeasured3rdHarmonicCurrentID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeMeasured3rdHarmonicCurrentID }
    public static var clusterElectricalMeasurementAttributeMeasured5thHarmonicCurrentID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeMeasured5thHarmonicCurrentID }
    public static var clusterElectricalMeasurementAttributeMeasured7thHarmonicCurrentID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeMeasured7thHarmonicCurrentID }
    public static var clusterElectricalMeasurementAttributeMeasured9thHarmonicCurrentID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeMeasured9thHarmonicCurrentID }
    public static var clusterElectricalMeasurementAttributeMeasured11thHarmonicCurrentID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeMeasured11thHarmonicCurrentID }
    public static var clusterElectricalMeasurementAttributeMeasuredPhase1stHarmonicCurrentID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeMeasuredPhase1stHarmonicCurrentID }
    public static var clusterElectricalMeasurementAttributeMeasuredPhase3rdHarmonicCurrentID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeMeasuredPhase3rdHarmonicCurrentID }
    public static var clusterElectricalMeasurementAttributeMeasuredPhase5thHarmonicCurrentID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeMeasuredPhase5thHarmonicCurrentID }
    public static var clusterElectricalMeasurementAttributeMeasuredPhase7thHarmonicCurrentID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeMeasuredPhase7thHarmonicCurrentID }
    public static var clusterElectricalMeasurementAttributeMeasuredPhase9thHarmonicCurrentID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeMeasuredPhase9thHarmonicCurrentID }
    public static var clusterElectricalMeasurementAttributeMeasuredPhase11thHarmonicCurrentID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeMeasuredPhase11thHarmonicCurrentID }
    public static var clusterElectricalMeasurementAttributeAcFrequencyMultiplierID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAcFrequencyMultiplierID }
    public static var clusterElectricalMeasurementAttributeAcFrequencyDivisorID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAcFrequencyDivisorID }
    public static var clusterElectricalMeasurementAttributePowerMultiplierID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributePowerMultiplierID }
    public static var clusterElectricalMeasurementAttributePowerDivisorID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributePowerDivisorID }
    public static var clusterElectricalMeasurementAttributeHarmonicCurrentMultiplierID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeHarmonicCurrentMultiplierID }
    public static var clusterElectricalMeasurementAttributePhaseHarmonicCurrentMultiplierID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributePhaseHarmonicCurrentMultiplierID }
    public static var clusterElectricalMeasurementAttributeInstantaneousVoltageID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeInstantaneousVoltageID }
    public static var clusterElectricalMeasurementAttributeInstantaneousLineCurrentID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeInstantaneousLineCurrentID }
    public static var clusterElectricalMeasurementAttributeInstantaneousActiveCurrentID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeInstantaneousActiveCurrentID }
    public static var clusterElectricalMeasurementAttributeInstantaneousReactiveCurrentID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeInstantaneousReactiveCurrentID }
    public static var clusterElectricalMeasurementAttributeInstantaneousPowerID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeInstantaneousPowerID }
    public static var clusterElectricalMeasurementAttributeRmsVoltageID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsVoltageID }
    public static var clusterElectricalMeasurementAttributeRmsVoltageMinID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsVoltageMinID }
    public static var clusterElectricalMeasurementAttributeRmsVoltageMaxID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsVoltageMaxID }
    public static var clusterElectricalMeasurementAttributeRmsCurrentID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsCurrentID }
    public static var clusterElectricalMeasurementAttributeRmsCurrentMinID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsCurrentMinID }
    public static var clusterElectricalMeasurementAttributeRmsCurrentMaxID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsCurrentMaxID }
    public static var clusterElectricalMeasurementAttributeActivePowerID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeActivePowerID }
    public static var clusterElectricalMeasurementAttributeActivePowerMinID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeActivePowerMinID }
    public static var clusterElectricalMeasurementAttributeActivePowerMaxID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeActivePowerMaxID }
    public static var clusterElectricalMeasurementAttributeReactivePowerID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeReactivePowerID }
    public static var clusterElectricalMeasurementAttributeApparentPowerID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeApparentPowerID }
    public static var clusterElectricalMeasurementAttributePowerFactorID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributePowerFactorID }
    public static var clusterElectricalMeasurementAttributeAverageRmsVoltageMeasurementPeriodID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAverageRmsVoltageMeasurementPeriodID }
    public static var clusterElectricalMeasurementAttributeAverageRmsUnderVoltageCounterID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAverageRmsUnderVoltageCounterID }
    public static var clusterElectricalMeasurementAttributeRmsExtremeOverVoltagePeriodID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsExtremeOverVoltagePeriodID }
    public static var clusterElectricalMeasurementAttributeRmsExtremeUnderVoltagePeriodID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsExtremeUnderVoltagePeriodID }
    public static var clusterElectricalMeasurementAttributeRmsVoltageSagPeriodID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsVoltageSagPeriodID }
    public static var clusterElectricalMeasurementAttributeRmsVoltageSwellPeriodID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsVoltageSwellPeriodID }
    public static var clusterElectricalMeasurementAttributeAcVoltageMultiplierID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAcVoltageMultiplierID }
    public static var clusterElectricalMeasurementAttributeAcVoltageDivisorID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAcVoltageDivisorID }
    public static var clusterElectricalMeasurementAttributeAcCurrentMultiplierID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAcCurrentMultiplierID }
    public static var clusterElectricalMeasurementAttributeAcCurrentDivisorID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAcCurrentDivisorID }
    public static var clusterElectricalMeasurementAttributeAcPowerMultiplierID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAcPowerMultiplierID }
    public static var clusterElectricalMeasurementAttributeAcPowerDivisorID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAcPowerDivisorID }
    public static var clusterElectricalMeasurementAttributeOverloadAlarmsMaskID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeOverloadAlarmsMaskID }
    public static var clusterElectricalMeasurementAttributeVoltageOverloadID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeVoltageOverloadID }
    public static var clusterElectricalMeasurementAttributeCurrentOverloadID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeCurrentOverloadID }
    public static var clusterElectricalMeasurementAttributeAcOverloadAlarmsMaskID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAcOverloadAlarmsMaskID }
    public static var clusterElectricalMeasurementAttributeAcVoltageOverloadID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAcVoltageOverloadID }
    public static var clusterElectricalMeasurementAttributeAcCurrentOverloadID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAcCurrentOverloadID }
    public static var clusterElectricalMeasurementAttributeAcActivePowerOverloadID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAcActivePowerOverloadID }
    public static var clusterElectricalMeasurementAttributeAcReactivePowerOverloadID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAcReactivePowerOverloadID }
    public static var clusterElectricalMeasurementAttributeAverageRmsOverVoltageID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAverageRmsOverVoltageID }
    public static var clusterElectricalMeasurementAttributeAverageRmsUnderVoltageID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAverageRmsUnderVoltageID }
    public static var clusterElectricalMeasurementAttributeRmsExtremeOverVoltageID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsExtremeOverVoltageID }
    public static var clusterElectricalMeasurementAttributeRmsExtremeUnderVoltageID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsExtremeUnderVoltageID }
    public static var clusterElectricalMeasurementAttributeRmsVoltageSagID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsVoltageSagID }
    public static var clusterElectricalMeasurementAttributeRmsVoltageSwellID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsVoltageSwellID }
    public static var clusterElectricalMeasurementAttributeLineCurrentPhaseBID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeLineCurrentPhaseBID }
    public static var clusterElectricalMeasurementAttributeActiveCurrentPhaseBID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeActiveCurrentPhaseBID }
    public static var clusterElectricalMeasurementAttributeReactiveCurrentPhaseBID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeReactiveCurrentPhaseBID }
    public static var clusterElectricalMeasurementAttributeRmsVoltagePhaseBID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsVoltagePhaseBID }
    public static var clusterElectricalMeasurementAttributeRmsVoltageMinPhaseBID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsVoltageMinPhaseBID }
    public static var clusterElectricalMeasurementAttributeRmsVoltageMaxPhaseBID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsVoltageMaxPhaseBID }
    public static var clusterElectricalMeasurementAttributeRmsCurrentPhaseBID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsCurrentPhaseBID }
    public static var clusterElectricalMeasurementAttributeRmsCurrentMinPhaseBID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsCurrentMinPhaseBID }
    public static var clusterElectricalMeasurementAttributeRmsCurrentMaxPhaseBID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsCurrentMaxPhaseBID }
    public static var clusterElectricalMeasurementAttributeActivePowerPhaseBID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeActivePowerPhaseBID }
    public static var clusterElectricalMeasurementAttributeActivePowerMinPhaseBID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeActivePowerMinPhaseBID }
    public static var clusterElectricalMeasurementAttributeActivePowerMaxPhaseBID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeActivePowerMaxPhaseBID }
    public static var clusterElectricalMeasurementAttributeReactivePowerPhaseBID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeReactivePowerPhaseBID }
    public static var clusterElectricalMeasurementAttributeApparentPowerPhaseBID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeApparentPowerPhaseBID }
    public static var clusterElectricalMeasurementAttributePowerFactorPhaseBID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributePowerFactorPhaseBID }
    public static var clusterElectricalMeasurementAttributeAverageRmsVoltageMeasurementPeriodPhaseBID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAverageRmsVoltageMeasurementPeriodPhaseBID }
    public static var clusterElectricalMeasurementAttributeAverageRmsOverVoltageCounterPhaseBID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAverageRmsOverVoltageCounterPhaseBID }
    public static var clusterElectricalMeasurementAttributeAverageRmsUnderVoltageCounterPhaseBID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAverageRmsUnderVoltageCounterPhaseBID }
    public static var clusterElectricalMeasurementAttributeRmsExtremeOverVoltagePeriodPhaseBID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsExtremeOverVoltagePeriodPhaseBID }
    public static var clusterElectricalMeasurementAttributeRmsExtremeUnderVoltagePeriodPhaseBID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsExtremeUnderVoltagePeriodPhaseBID }
    public static var clusterElectricalMeasurementAttributeRmsVoltageSagPeriodPhaseBID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsVoltageSagPeriodPhaseBID }
    public static var clusterElectricalMeasurementAttributeRmsVoltageSwellPeriodPhaseBID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsVoltageSwellPeriodPhaseBID }
    public static var clusterElectricalMeasurementAttributeLineCurrentPhaseCID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeLineCurrentPhaseCID }
    public static var clusterElectricalMeasurementAttributeActiveCurrentPhaseCID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeActiveCurrentPhaseCID }
    public static var clusterElectricalMeasurementAttributeReactiveCurrentPhaseCID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeReactiveCurrentPhaseCID }
    public static var clusterElectricalMeasurementAttributeRmsVoltagePhaseCID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsVoltagePhaseCID }
    public static var clusterElectricalMeasurementAttributeRmsVoltageMinPhaseCID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsVoltageMinPhaseCID }
    public static var clusterElectricalMeasurementAttributeRmsVoltageMaxPhaseCID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsVoltageMaxPhaseCID }
    public static var clusterElectricalMeasurementAttributeRmsCurrentPhaseCID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsCurrentPhaseCID }
    public static var clusterElectricalMeasurementAttributeRmsCurrentMinPhaseCID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsCurrentMinPhaseCID }
    public static var clusterElectricalMeasurementAttributeRmsCurrentMaxPhaseCID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsCurrentMaxPhaseCID }
    public static var clusterElectricalMeasurementAttributeActivePowerPhaseCID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeActivePowerPhaseCID }
    public static var clusterElectricalMeasurementAttributeActivePowerMinPhaseCID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeActivePowerMinPhaseCID }
    public static var clusterElectricalMeasurementAttributeActivePowerMaxPhaseCID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeActivePowerMaxPhaseCID }
    public static var clusterElectricalMeasurementAttributeReactivePowerPhaseCID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeReactivePowerPhaseCID }
    public static var clusterElectricalMeasurementAttributeApparentPowerPhaseCID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeApparentPowerPhaseCID }
    public static var clusterElectricalMeasurementAttributePowerFactorPhaseCID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributePowerFactorPhaseCID }
    public static var clusterElectricalMeasurementAttributeAverageRmsVoltageMeasurementPeriodPhaseCID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAverageRmsVoltageMeasurementPeriodPhaseCID }
    public static var clusterElectricalMeasurementAttributeAverageRmsOverVoltageCounterPhaseCID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAverageRmsOverVoltageCounterPhaseCID }
    public static var clusterElectricalMeasurementAttributeAverageRmsUnderVoltageCounterPhaseCID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeAverageRmsUnderVoltageCounterPhaseCID }
    public static var clusterElectricalMeasurementAttributeRmsExtremeOverVoltagePeriodPhaseCID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsExtremeOverVoltagePeriodPhaseCID }
    public static var clusterElectricalMeasurementAttributeRmsExtremeUnderVoltagePeriodPhaseCID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsExtremeUnderVoltagePeriodPhaseCID }
    public static var clusterElectricalMeasurementAttributeRmsVoltageSagPeriodPhaseCID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsVoltageSagPeriodPhaseCID }
    public static var clusterElectricalMeasurementAttributeRmsVoltageSwellPeriodPhaseCID: MTRAttributeIDType { .MTRClusterElectricalMeasurementAttributeRmsVoltageSwellPeriodPhaseCID }
    public static var clusterElectricalMeasurementAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterElectricalMeasurementAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterElectricalMeasurementAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterElectricalMeasurementAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterElectricalMeasurementAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var MTRClusterOnOffSwitchConfigurationAttributeSwitchTypeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var MTRClusterOnOffSwitchConfigurationAttributeSwitchActionsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var MTRClusterOnOffSwitchConfigurationAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var MTRClusterOnOffSwitchConfigurationAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var MTRClusterOnOffSwitchConfigurationAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var MTRClusterOnOffSwitchConfigurationAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var MTRClusterOnOffSwitchConfigurationAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
    public static var clusterOnOffSwitchConfigurationAttributeSwitchTypeID: MTRAttributeIDType { .MTRClusterIdentifyAttributeIdentifyTimeID }
    public static var clusterOnOffSwitchConfigurationAttributeSwitchActionsID: MTRAttributeIDType { .MTRClusterLevelControlAttributeOnOffTransitionTimeID }
    public static var clusterOnOffSwitchConfigurationAttributeGeneratedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeGeneratedCommandListID }
    public static var clusterOnOffSwitchConfigurationAttributeAcceptedCommandListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAcceptedCommandListID }
    public static var clusterOnOffSwitchConfigurationAttributeAttributeListID: MTRAttributeIDType { .MTRClusterGlobalAttributeAttributeListID }
    public static var clusterOnOffSwitchConfigurationAttributeFeatureMapID: MTRAttributeIDType { .MTRClusterGlobalAttributeFeatureMapID }
    public static var clusterOnOffSwitchConfigurationAttributeClusterRevisionID: MTRAttributeIDType { .MTRClusterGlobalAttributeClusterRevisionID }
}

public enum MTRClusterIDType: UInt32, Sendable, Hashable {
    case MTRClusterIdentifyID = 3
    case MTRClusterGroupsID = 4
    case MTRClusterOnOffID = 6
    case MTRClusterLevelControlID = 8
    case MTRClusterPulseWidthModulationID = 28
    case MTRClusterDescriptorID = 29
    case MTRClusterBindingID = 30
    case MTRClusterAccessControlID = 31
    case MTRClusterActionsID = 37
    case MTRClusterBasicID = 40
    case MTRClusterOtaSoftwareUpdateProviderID = 41
    case MTRClusterOtaSoftwareUpdateRequestorID = 42
    case MTRClusterLocalizationConfigurationID = 43
    case MTRClusterTimeFormatLocalizationID = 44
    case MTRClusterUnitLocalizationID = 45
    case MTRClusterPowerSourceConfigurationID = 46
    case MTRClusterPowerSourceID = 47
    case MTRClusterGeneralCommissioningID = 48
    case MTRClusterNetworkCommissioningID = 49
    case MTRClusterDiagnosticLogsID = 50
    case MTRClusterGeneralDiagnosticsID = 51
    case MTRClusterSoftwareDiagnosticsID = 52
    case MTRClusterThreadNetworkDiagnosticsID = 53
    case MTRClusterWiFiNetworkDiagnosticsID = 54
    case MTRClusterEthernetNetworkDiagnosticsID = 55
    case MTRClusterTimeSynchronizationID = 56
    case MTRClusterBridgedDeviceBasicID = 57
    case MTRClusterSwitchID = 59
    case MTRClusterAdministratorCommissioningID = 60
    case MTRClusterOperationalCredentialsID = 62
    case MTRClusterGroupKeyManagementID = 63
    case MTRClusterFixedLabelID = 64
    case MTRClusterUserLabelID = 65
    case MTRClusterBooleanStateID = 69
    case MTRClusterModeSelectID = 80
    case MTRClusterDoorLockID = 257
    case MTRClusterWindowCoveringID = 258
    case MTRClusterPumpConfigurationAndControlID = 512
    case MTRClusterThermostatID = 513
    case MTRClusterFanControlID = 514
    case MTRClusterThermostatUserInterfaceConfigurationID = 516
    case MTRClusterColorControlID = 768
    case MTRClusterBallastConfigurationID = 769
    case MTRClusterIlluminanceMeasurementID = 1024
    case MTRClusterTemperatureMeasurementID = 1026
    case MTRClusterPressureMeasurementID = 1027
    case MTRClusterFlowMeasurementID = 1028
    case MTRClusterRelativeHumidityMeasurementID = 1029
    case MTRClusterOccupancySensingID = 1030
    case MTRClusterWakeOnLanID = 1283
    case MTRClusterChannelID = 1284
    case MTRClusterTargetNavigatorID = 1285
    case MTRClusterMediaPlaybackID = 1286
    case MTRClusterMediaInputID = 1287
    case MTRClusterLowPowerID = 1288
    case MTRClusterKeypadInputID = 1289
    case MTRClusterContentLauncherID = 1290
    case MTRClusterAudioOutputID = 1291
    case MTRClusterApplicationLauncherID = 1292
    case MTRClusterApplicationBasicID = 1293
    case MTRClusterAccountLoginID = 1294
    case MTRClusterTestClusterID = 4294048773
    case icdManagementID = 70
    case ovenCavityOperationalStateID = 72
    case ovenModeID = 73
    case laundryDryerControlsID = 74
    case laundryWasherModeID = 81
    case refrigeratorAndTemperatureControlledCabinetModeID = 82
    case laundryWasherControlsID = 83
    case rvcRunModeID = 84
    case rvcCleanModeID = 85
    case temperatureControlID = 86
    case refrigeratorAlarmID = 87
    case dishwasherModeID = 89
    case airQualityID = 91
    case smokeCOAlarmID = 92
    case dishwasherAlarmID = 93
    case microwaveOvenModeID = 94
    case microwaveOvenControlID = 95
    case operationalStateID = 96
    case rvcOperationalStateID = 97
    case hepaFilterMonitoringID = 113
    case activatedCarbonFilterMonitoringID = 114
    case booleanStateConfigurationID = 128
    case valveConfigurationAndControlID = 129
    case electricalPowerMeasurementID = 144
    case electricalEnergyMeasurementID = 145
    case waterHeaterManagementID = 148
    case messagesID = 151
    case deviceEnergyManagementID = 152
    case energyEVSEID = 153
    case powerTopologyID = 156
    case energyEVSEModeID = 157
    case waterHeaterModeID = 158
    case deviceEnergyManagementModeID = 159
    case serviceAreaID = 336
    case carbonMonoxideConcentrationMeasurementID = 1036
    case carbonDioxideConcentrationMeasurementID = 1037
    case nitrogenDioxideConcentrationMeasurementID = 1043
    case ozoneConcentrationMeasurementID = 1045
    case pm25ConcentrationMeasurementID = 1066
    case formaldehydeConcentrationMeasurementID = 1067
    case pm1ConcentrationMeasurementID = 1068
    case pm10ConcentrationMeasurementID = 1069
    case totalVolatileOrganicCompoundsConcentrationMeasurementID = 1070
    case radonConcentrationMeasurementID = 1071
    case wiFiNetworkManagementID = 1105
    case threadBorderRouterManagementID = 1106
    case threadNetworkDirectoryID = 1107
    case contentAppObserverID = 1296
    case commissionerControlID = 1873
    case MTRClusterBarrierControlID = 259
    case MTRClusterBinaryInputBasicID = 15
    case MTRClusterElectricalMeasurementID = 2820
    case MTRClusterOnOffSwitchConfigurationID = 7
    public static var identifyID: MTRClusterIDType { .MTRClusterIdentifyID }
    public static var groupsID: MTRClusterIDType { .MTRClusterGroupsID }
    public static var onOffID: MTRClusterIDType { .MTRClusterOnOffID }
    public static var levelControlID: MTRClusterIDType { .MTRClusterLevelControlID }
    public static var pulseWidthModulationID: MTRClusterIDType { .MTRClusterPulseWidthModulationID }
    public static var descriptorID: MTRClusterIDType { .MTRClusterDescriptorID }
    public static var bindingID: MTRClusterIDType { .MTRClusterBindingID }
    public static var accessControlID: MTRClusterIDType { .MTRClusterAccessControlID }
    public static var actionsID: MTRClusterIDType { .MTRClusterActionsID }
    public static var basicInformationID: MTRClusterIDType { .MTRClusterBasicID }
    public static var otaSoftwareUpdateProviderID: MTRClusterIDType { .MTRClusterOtaSoftwareUpdateProviderID }
    public static var otaSoftwareUpdateRequestorID: MTRClusterIDType { .MTRClusterOtaSoftwareUpdateRequestorID }
    public static var localizationConfigurationID: MTRClusterIDType { .MTRClusterLocalizationConfigurationID }
    public static var timeFormatLocalizationID: MTRClusterIDType { .MTRClusterTimeFormatLocalizationID }
    public static var unitLocalizationID: MTRClusterIDType { .MTRClusterUnitLocalizationID }
    public static var powerSourceConfigurationID: MTRClusterIDType { .MTRClusterPowerSourceConfigurationID }
    public static var powerSourceID: MTRClusterIDType { .MTRClusterPowerSourceID }
    public static var generalCommissioningID: MTRClusterIDType { .MTRClusterGeneralCommissioningID }
    public static var networkCommissioningID: MTRClusterIDType { .MTRClusterNetworkCommissioningID }
    public static var diagnosticLogsID: MTRClusterIDType { .MTRClusterDiagnosticLogsID }
    public static var generalDiagnosticsID: MTRClusterIDType { .MTRClusterGeneralDiagnosticsID }
    public static var softwareDiagnosticsID: MTRClusterIDType { .MTRClusterSoftwareDiagnosticsID }
    public static var threadNetworkDiagnosticsID: MTRClusterIDType { .MTRClusterThreadNetworkDiagnosticsID }
    public static var wiFiNetworkDiagnosticsID: MTRClusterIDType { .MTRClusterWiFiNetworkDiagnosticsID }
    public static var ethernetNetworkDiagnosticsID: MTRClusterIDType { .MTRClusterEthernetNetworkDiagnosticsID }
    public static var timeSynchronizationID: MTRClusterIDType { .MTRClusterTimeSynchronizationID }
    public static var bridgedDeviceBasicInformationID: MTRClusterIDType { .MTRClusterBridgedDeviceBasicID }
    public static var switchID: MTRClusterIDType { .MTRClusterSwitchID }
    public static var administratorCommissioningID: MTRClusterIDType { .MTRClusterAdministratorCommissioningID }
    public static var operationalCredentialsID: MTRClusterIDType { .MTRClusterOperationalCredentialsID }
    public static var groupKeyManagementID: MTRClusterIDType { .MTRClusterGroupKeyManagementID }
    public static var fixedLabelID: MTRClusterIDType { .MTRClusterFixedLabelID }
    public static var userLabelID: MTRClusterIDType { .MTRClusterUserLabelID }
    public static var booleanStateID: MTRClusterIDType { .MTRClusterBooleanStateID }
    public static var modeSelectID: MTRClusterIDType { .MTRClusterModeSelectID }
    public static var doorLockID: MTRClusterIDType { .MTRClusterDoorLockID }
    public static var windowCoveringID: MTRClusterIDType { .MTRClusterWindowCoveringID }
    public static var pumpConfigurationAndControlID: MTRClusterIDType { .MTRClusterPumpConfigurationAndControlID }
    public static var thermostatID: MTRClusterIDType { .MTRClusterThermostatID }
    public static var fanControlID: MTRClusterIDType { .MTRClusterFanControlID }
    public static var thermostatUserInterfaceConfigurationID: MTRClusterIDType { .MTRClusterThermostatUserInterfaceConfigurationID }
    public static var colorControlID: MTRClusterIDType { .MTRClusterColorControlID }
    public static var ballastConfigurationID: MTRClusterIDType { .MTRClusterBallastConfigurationID }
    public static var illuminanceMeasurementID: MTRClusterIDType { .MTRClusterIlluminanceMeasurementID }
    public static var temperatureMeasurementID: MTRClusterIDType { .MTRClusterTemperatureMeasurementID }
    public static var pressureMeasurementID: MTRClusterIDType { .MTRClusterPressureMeasurementID }
    public static var flowMeasurementID: MTRClusterIDType { .MTRClusterFlowMeasurementID }
    public static var relativeHumidityMeasurementID: MTRClusterIDType { .MTRClusterRelativeHumidityMeasurementID }
    public static var occupancySensingID: MTRClusterIDType { .MTRClusterOccupancySensingID }
    public static var wakeOnLANID: MTRClusterIDType { .MTRClusterWakeOnLanID }
    public static var channelID: MTRClusterIDType { .MTRClusterChannelID }
    public static var targetNavigatorID: MTRClusterIDType { .MTRClusterTargetNavigatorID }
    public static var mediaPlaybackID: MTRClusterIDType { .MTRClusterMediaPlaybackID }
    public static var mediaInputID: MTRClusterIDType { .MTRClusterMediaInputID }
    public static var lowPowerID: MTRClusterIDType { .MTRClusterLowPowerID }
    public static var keypadInputID: MTRClusterIDType { .MTRClusterKeypadInputID }
    public static var contentLauncherID: MTRClusterIDType { .MTRClusterContentLauncherID }
    public static var audioOutputID: MTRClusterIDType { .MTRClusterAudioOutputID }
    public static var applicationLauncherID: MTRClusterIDType { .MTRClusterApplicationLauncherID }
    public static var applicationBasicID: MTRClusterIDType { .MTRClusterApplicationBasicID }
    public static var accountLoginID: MTRClusterIDType { .MTRClusterAccountLoginID }
    public static var unitTestingID: MTRClusterIDType { .MTRClusterTestClusterID }
    public static var barrierControlID: MTRClusterIDType { .MTRClusterBarrierControlID }
    public static var binaryInputBasicID: MTRClusterIDType { .MTRClusterBinaryInputBasicID }
    public static var electricalMeasurementID: MTRClusterIDType { .MTRClusterElectricalMeasurementID }
    public static var onOffSwitchConfigurationID: MTRClusterIDType { .MTRClusterOnOffSwitchConfigurationID }
}

public enum MTRCommandIDType: UInt32, Sendable, Hashable {
    case MTRClusterIdentifyCommandIdentifyID = 0
    case MTRClusterIdentifyCommandTriggerEffectID = 64
    case MTRClusterGroupsCommandViewGroupID = 1
    case MTRClusterGroupsCommandGetGroupMembershipID = 2
    case MTRClusterGroupsCommandRemoveGroupID = 3
    case MTRClusterGroupsCommandRemoveAllGroupsID = 4
    case MTRClusterGroupsCommandAddGroupIfIdentifyingID = 5
    case MTRClusterOnOffCommandOnWithRecallGlobalSceneID = 65
    case MTRClusterOnOffCommandOnWithTimedOffID = 66
    case MTRClusterLevelControlCommandStepWithOnOffID = 6
    case MTRClusterLevelControlCommandStopWithOnOffID = 7
    case MTRClusterLevelControlCommandMoveToClosestFrequencyID = 8
    case MTRClusterActionsCommandEnableActionWithDurationID = 9
    case MTRClusterActionsCommandDisableActionID = 10
    case MTRClusterActionsCommandDisableActionWithDurationID = 11
    case MTRClusterBasicCommandMfgSpecificPingID = 268566528
    case clusterBridgedDeviceBasicInformationCommandKeepActiveID = 128
    case MTRClusterDoorLockCommandGetWeekDayScheduleID = 12
    case MTRClusterDoorLockCommandClearWeekDayScheduleID = 13
    case MTRClusterDoorLockCommandSetYearDayScheduleID = 14
    case MTRClusterDoorLockCommandGetYearDayScheduleID = 15
    case MTRClusterDoorLockCommandClearYearDayScheduleID = 16
    case MTRClusterDoorLockCommandSetHolidayScheduleID = 17
    case MTRClusterDoorLockCommandGetHolidayScheduleID = 18
    case MTRClusterDoorLockCommandClearHolidayScheduleID = 19
    case MTRClusterDoorLockCommandSetUserID = 26
    case MTRClusterDoorLockCommandGetUserID = 27
    case MTRClusterDoorLockCommandGetUserResponseID = 28
    case MTRClusterDoorLockCommandClearUserID = 29
    case MTRClusterDoorLockCommandSetCredentialID = 34
    case MTRClusterDoorLockCommandSetCredentialResponseID = 35
    case MTRClusterDoorLockCommandGetCredentialStatusID = 36
    case MTRClusterDoorLockCommandGetCredentialStatusResponseID = 37
    case MTRClusterDoorLockCommandClearCredentialID = 38
    case clusterDoorLockCommandUnboltDoorID = 39
    case clusterDoorLockCommandSetAliroReaderConfigID = 40
    case clusterDoorLockCommandClearAliroReaderConfigID = 41
    case clusterThermostatCommandAtomicResponseID = 253
    case clusterThermostatCommandAtomicRequestID = 254
    case MTRClusterColorControlCommandEnhancedMoveToHueAndSaturationID = 67
    case MTRClusterColorControlCommandColorLoopSetID = 68
    case MTRClusterColorControlCommandStopMoveStepID = 71
    case MTRClusterColorControlCommandMoveColorTemperatureID = 75
    case MTRClusterColorControlCommandStepColorTemperatureID = 76
    case MTRClusterTestClusterCommandTestEmitTestEventRequestID = 20
    case MTRClusterTestClusterCommandTestEmitTestFabricScopedEventRequestID = 21
    public static var clusterIdentifyCommandIdentifyID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterIdentifyCommandTriggerEffectID: MTRCommandIDType { .MTRClusterIdentifyCommandTriggerEffectID }
    public static var MTRClusterGroupsCommandAddGroupID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterGroupsCommandAddGroupResponseID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterGroupsCommandViewGroupResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterGroupsCommandGetGroupMembershipResponseID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var MTRClusterGroupsCommandRemoveGroupResponseID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterGroupsCommandAddGroupID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterGroupsCommandAddGroupResponseID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterGroupsCommandViewGroupID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterGroupsCommandViewGroupResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterGroupsCommandGetGroupMembershipID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterGroupsCommandGetGroupMembershipResponseID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterGroupsCommandRemoveGroupID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterGroupsCommandRemoveGroupResponseID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterGroupsCommandRemoveAllGroupsID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var clusterGroupsCommandAddGroupIfIdentifyingID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var MTRClusterOnOffCommandOffID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterOnOffCommandOnID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterOnOffCommandToggleID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var MTRClusterOnOffCommandOffWithEffectID: MTRCommandIDType { .MTRClusterIdentifyCommandTriggerEffectID }
    public static var clusterOnOffCommandOffID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterOnOffCommandOnID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterOnOffCommandToggleID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterOnOffCommandOffWithEffectID: MTRCommandIDType { .MTRClusterIdentifyCommandTriggerEffectID }
    public static var clusterOnOffCommandOnWithRecallGlobalSceneID: MTRCommandIDType { .MTRClusterOnOffCommandOnWithRecallGlobalSceneID }
    public static var clusterOnOffCommandOnWithTimedOffID: MTRCommandIDType { .MTRClusterOnOffCommandOnWithTimedOffID }
    public static var MTRClusterLevelControlCommandMoveToLevelID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterLevelControlCommandMoveID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterLevelControlCommandStepID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var MTRClusterLevelControlCommandStopID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var MTRClusterLevelControlCommandMoveToLevelWithOnOffID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var MTRClusterLevelControlCommandMoveWithOnOffID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var clusterLevelControlCommandMoveToLevelID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterLevelControlCommandMoveID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterLevelControlCommandStepID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterLevelControlCommandStopID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterLevelControlCommandMoveToLevelWithOnOffID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var clusterLevelControlCommandMoveWithOnOffID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var clusterLevelControlCommandStepWithOnOffID: MTRCommandIDType { .MTRClusterLevelControlCommandStepWithOnOffID }
    public static var clusterLevelControlCommandStopWithOnOffID: MTRCommandIDType { .MTRClusterLevelControlCommandStopWithOnOffID }
    public static var clusterLevelControlCommandMoveToClosestFrequencyID: MTRCommandIDType { .MTRClusterLevelControlCommandMoveToClosestFrequencyID }
    public static var clusterAccessControlCommandReviewFabricRestrictionsID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterAccessControlCommandReviewFabricRestrictionsResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterActionsCommandInstantActionID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterActionsCommandInstantActionWithTransitionID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterActionsCommandStartActionID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var MTRClusterActionsCommandStartActionWithDurationID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var MTRClusterActionsCommandStopActionID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var MTRClusterActionsCommandPauseActionID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var MTRClusterActionsCommandPauseActionWithDurationID: MTRCommandIDType { .MTRClusterLevelControlCommandStepWithOnOffID }
    public static var MTRClusterActionsCommandResumeActionID: MTRCommandIDType { .MTRClusterLevelControlCommandStopWithOnOffID }
    public static var MTRClusterActionsCommandEnableActionID: MTRCommandIDType { .MTRClusterLevelControlCommandMoveToClosestFrequencyID }
    public static var clusterActionsCommandInstantActionID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterActionsCommandInstantActionWithTransitionID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterActionsCommandStartActionID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterActionsCommandStartActionWithDurationID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterActionsCommandStopActionID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var clusterActionsCommandPauseActionID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var clusterActionsCommandPauseActionWithDurationID: MTRCommandIDType { .MTRClusterLevelControlCommandStepWithOnOffID }
    public static var clusterActionsCommandResumeActionID: MTRCommandIDType { .MTRClusterLevelControlCommandStopWithOnOffID }
    public static var clusterActionsCommandEnableActionID: MTRCommandIDType { .MTRClusterLevelControlCommandMoveToClosestFrequencyID }
    public static var clusterActionsCommandEnableActionWithDurationID: MTRCommandIDType { .MTRClusterActionsCommandEnableActionWithDurationID }
    public static var clusterActionsCommandDisableActionID: MTRCommandIDType { .MTRClusterActionsCommandDisableActionID }
    public static var clusterActionsCommandDisableActionWithDurationID: MTRCommandIDType { .MTRClusterActionsCommandDisableActionWithDurationID }
    public static var MTRClusterOtaSoftwareUpdateProviderCommandQueryImageID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterOtaSoftwareUpdateProviderCommandQueryImageResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterOtaSoftwareUpdateProviderCommandApplyUpdateRequestID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var MTRClusterOtaSoftwareUpdateProviderCommandApplyUpdateResponseID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var MTRClusterOtaSoftwareUpdateProviderCommandNotifyUpdateAppliedID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var clusterOTASoftwareUpdateProviderCommandQueryImageID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterOTASoftwareUpdateProviderCommandQueryImageResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterOTASoftwareUpdateProviderCommandApplyUpdateRequestID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterOTASoftwareUpdateProviderCommandApplyUpdateResponseID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterOTASoftwareUpdateProviderCommandNotifyUpdateAppliedID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var MTRClusterOtaSoftwareUpdateRequestorCommandAnnounceOtaProviderID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterOTASoftwareUpdateRequestorCommandAnnounceOTAProviderID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterGeneralCommissioningCommandArmFailSafeID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterGeneralCommissioningCommandArmFailSafeResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterGeneralCommissioningCommandSetRegulatoryConfigID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var MTRClusterGeneralCommissioningCommandSetRegulatoryConfigResponseID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var MTRClusterGeneralCommissioningCommandCommissioningCompleteID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var MTRClusterGeneralCommissioningCommandCommissioningCompleteResponseID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var clusterGeneralCommissioningCommandArmFailSafeID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterGeneralCommissioningCommandArmFailSafeResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterGeneralCommissioningCommandSetRegulatoryConfigID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterGeneralCommissioningCommandSetRegulatoryConfigResponseID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterGeneralCommissioningCommandCommissioningCompleteID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var clusterGeneralCommissioningCommandCommissioningCompleteResponseID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var MTRClusterNetworkCommissioningCommandScanNetworksID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterNetworkCommissioningCommandScanNetworksResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterNetworkCommissioningCommandAddOrUpdateWiFiNetworkID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var MTRClusterNetworkCommissioningCommandAddOrUpdateThreadNetworkID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var MTRClusterNetworkCommissioningCommandRemoveNetworkID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var MTRClusterNetworkCommissioningCommandNetworkConfigResponseID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var MTRClusterNetworkCommissioningCommandConnectNetworkID: MTRCommandIDType { .MTRClusterLevelControlCommandStepWithOnOffID }
    public static var MTRClusterNetworkCommissioningCommandConnectNetworkResponseID: MTRCommandIDType { .MTRClusterLevelControlCommandStopWithOnOffID }
    public static var MTRClusterNetworkCommissioningCommandReorderNetworkID: MTRCommandIDType { .MTRClusterLevelControlCommandMoveToClosestFrequencyID }
    public static var clusterNetworkCommissioningCommandScanNetworksID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterNetworkCommissioningCommandScanNetworksResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterNetworkCommissioningCommandAddOrUpdateWiFiNetworkID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterNetworkCommissioningCommandAddOrUpdateThreadNetworkID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterNetworkCommissioningCommandRemoveNetworkID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var clusterNetworkCommissioningCommandNetworkConfigResponseID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var clusterNetworkCommissioningCommandConnectNetworkID: MTRCommandIDType { .MTRClusterLevelControlCommandStepWithOnOffID }
    public static var clusterNetworkCommissioningCommandConnectNetworkResponseID: MTRCommandIDType { .MTRClusterLevelControlCommandStopWithOnOffID }
    public static var clusterNetworkCommissioningCommandReorderNetworkID: MTRCommandIDType { .MTRClusterLevelControlCommandMoveToClosestFrequencyID }
    public static var MTRClusterDiagnosticLogsCommandRetrieveLogsRequestID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterDiagnosticLogsCommandRetrieveLogsResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterDiagnosticLogsCommandRetrieveLogsRequestID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterDiagnosticLogsCommandRetrieveLogsResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterGeneralDiagnosticsCommandTestEventTriggerID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterGeneralDiagnosticsCommandTestEventTriggerID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterGeneralDiagnosticsCommandTimeSnapshotID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterGeneralDiagnosticsCommandTimeSnapshotResponseID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterGeneralDiagnosticsCommandPayloadTestRequestID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterGeneralDiagnosticsCommandPayloadTestResponseID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var MTRClusterSoftwareDiagnosticsCommandResetWatermarksID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterSoftwareDiagnosticsCommandResetWatermarksID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterThreadNetworkDiagnosticsCommandResetCountsID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterThreadNetworkDiagnosticsCommandResetCountsID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterWiFiNetworkDiagnosticsCommandResetCountsID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterWiFiNetworkDiagnosticsCommandResetCountsID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterEthernetNetworkDiagnosticsCommandResetCountsID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterEthernetNetworkDiagnosticsCommandResetCountsID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterTimeSynchronizationCommandSetUtcTimeID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterTimeSynchronizationCommandSetUTCTimeID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterTimeSynchronizationCommandSetUtcTimeID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterTimeSynchronizationCommandSetTrustedTimeSourceID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterTimeSynchronizationCommandSetTimeZoneID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterTimeSynchronizationCommandSetTimeZoneResponseID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterTimeSynchronizationCommandSetDSTOffsetID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var clusterTimeSynchronizationCommandSetDefaultNTPID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var MTRClusterAdministratorCommissioningCommandOpenCommissioningWindowID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterAdministratorCommissioningCommandOpenBasicCommissioningWindowID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterAdministratorCommissioningCommandRevokeCommissioningID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterAdministratorCommissioningCommandOpenCommissioningWindowID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterAdministratorCommissioningCommandOpenBasicCommissioningWindowID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterAdministratorCommissioningCommandRevokeCommissioningID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var MTRClusterOperationalCredentialsCommandAttestationRequestID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterOperationalCredentialsCommandAttestationResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterOperationalCredentialsCommandCertificateChainRequestID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var MTRClusterOperationalCredentialsCommandCertificateChainResponseID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var MTRClusterOperationalCredentialsCommandCSRRequestID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var MTRClusterOperationalCredentialsCommandCSRResponseID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var MTRClusterOperationalCredentialsCommandAddNOCID: MTRCommandIDType { .MTRClusterLevelControlCommandStepWithOnOffID }
    public static var MTRClusterOperationalCredentialsCommandUpdateNOCID: MTRCommandIDType { .MTRClusterLevelControlCommandStopWithOnOffID }
    public static var MTRClusterOperationalCredentialsCommandNOCResponseID: MTRCommandIDType { .MTRClusterLevelControlCommandMoveToClosestFrequencyID }
    public static var MTRClusterOperationalCredentialsCommandUpdateFabricLabelID: MTRCommandIDType { .MTRClusterActionsCommandEnableActionWithDurationID }
    public static var MTRClusterOperationalCredentialsCommandRemoveFabricID: MTRCommandIDType { .MTRClusterActionsCommandDisableActionID }
    public static var MTRClusterOperationalCredentialsCommandAddTrustedRootCertificateID: MTRCommandIDType { .MTRClusterActionsCommandDisableActionWithDurationID }
    public static var clusterOperationalCredentialsCommandAttestationRequestID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterOperationalCredentialsCommandAttestationResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterOperationalCredentialsCommandCertificateChainRequestID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterOperationalCredentialsCommandCertificateChainResponseID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterOperationalCredentialsCommandCSRRequestID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var clusterOperationalCredentialsCommandCSRResponseID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var clusterOperationalCredentialsCommandAddNOCID: MTRCommandIDType { .MTRClusterLevelControlCommandStepWithOnOffID }
    public static var clusterOperationalCredentialsCommandUpdateNOCID: MTRCommandIDType { .MTRClusterLevelControlCommandStopWithOnOffID }
    public static var clusterOperationalCredentialsCommandNOCResponseID: MTRCommandIDType { .MTRClusterLevelControlCommandMoveToClosestFrequencyID }
    public static var clusterOperationalCredentialsCommandUpdateFabricLabelID: MTRCommandIDType { .MTRClusterActionsCommandEnableActionWithDurationID }
    public static var clusterOperationalCredentialsCommandRemoveFabricID: MTRCommandIDType { .MTRClusterActionsCommandDisableActionID }
    public static var clusterOperationalCredentialsCommandAddTrustedRootCertificateID: MTRCommandIDType { .MTRClusterActionsCommandDisableActionWithDurationID }
    public static var MTRClusterGroupKeyManagementCommandKeySetWriteID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterGroupKeyManagementCommandKeySetReadID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterGroupKeyManagementCommandKeySetReadResponseID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var MTRClusterGroupKeyManagementCommandKeySetRemoveID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var MTRClusterGroupKeyManagementCommandKeySetReadAllIndicesID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var MTRClusterGroupKeyManagementCommandKeySetReadAllIndicesResponseID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var clusterGroupKeyManagementCommandKeySetWriteID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterGroupKeyManagementCommandKeySetReadID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterGroupKeyManagementCommandKeySetReadResponseID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterGroupKeyManagementCommandKeySetRemoveID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterGroupKeyManagementCommandKeySetReadAllIndicesID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var clusterGroupKeyManagementCommandKeySetReadAllIndicesResponseID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var clusterICDManagementCommandRegisterClientID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterICDManagementCommandRegisterClientResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterICDManagementCommandUnregisterClientID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterICDManagementCommandStayActiveRequestID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterICDManagementCommandStayActiveResponseID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var clusterOvenCavityOperationalStateCommandStopID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterOvenCavityOperationalStateCommandStartID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterOvenCavityOperationalStateCommandOperationalCommandResponseID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var clusterOvenModeCommandChangeToModeID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterOvenModeCommandChangeToModeResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterModeSelectCommandChangeToModeID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterModeSelectCommandChangeToModeID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterLaundryWasherModeCommandChangeToModeID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterLaundryWasherModeCommandChangeToModeResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterRefrigeratorAndTemperatureControlledCabinetModeCommandChangeToModeID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterRefrigeratorAndTemperatureControlledCabinetModeCommandChangeToModeResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterRVCRunModeCommandChangeToModeID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterRVCRunModeCommandChangeToModeResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterRVCCleanModeCommandChangeToModeID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterRVCCleanModeCommandChangeToModeResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterTemperatureControlCommandSetTemperatureID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterDishwasherModeCommandChangeToModeID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterDishwasherModeCommandChangeToModeResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterSmokeCOAlarmCommandSelfTestRequestID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterDishwasherAlarmCommandResetID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterDishwasherAlarmCommandModifyEnabledAlarmsID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterMicrowaveOvenControlCommandSetCookingParametersID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterMicrowaveOvenControlCommandAddMoreTimeID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterOperationalStateCommandPauseID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterOperationalStateCommandStopID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterOperationalStateCommandStartID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterOperationalStateCommandResumeID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterOperationalStateCommandOperationalCommandResponseID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var clusterRVCOperationalStateCommandPauseID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterRVCOperationalStateCommandResumeID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterRVCOperationalStateCommandOperationalCommandResponseID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var clusterRVCOperationalStateCommandGoHomeID: MTRCommandIDType { .clusterBridgedDeviceBasicInformationCommandKeepActiveID }
    public static var clusterHEPAFilterMonitoringCommandResetConditionID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterActivatedCarbonFilterMonitoringCommandResetConditionID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterBooleanStateConfigurationCommandSuppressAlarmID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterBooleanStateConfigurationCommandEnableDisableAlarmID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterValveConfigurationAndControlCommandOpenID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterValveConfigurationAndControlCommandCloseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterWaterHeaterManagementCommandBoostID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterWaterHeaterManagementCommandCancelBoostID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterMessagesCommandPresentMessagesRequestID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterMessagesCommandCancelMessagesRequestID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterDeviceEnergyManagementCommandPowerAdjustRequestID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterDeviceEnergyManagementCommandCancelPowerAdjustRequestID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterDeviceEnergyManagementCommandStartTimeAdjustRequestID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterDeviceEnergyManagementCommandPauseRequestID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterDeviceEnergyManagementCommandResumeRequestID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var clusterDeviceEnergyManagementCommandModifyForecastRequestID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var clusterDeviceEnergyManagementCommandRequestConstraintBasedForecastID: MTRCommandIDType { .MTRClusterLevelControlCommandStepWithOnOffID }
    public static var clusterDeviceEnergyManagementCommandCancelRequestID: MTRCommandIDType { .MTRClusterLevelControlCommandStopWithOnOffID }
    public static var clusterEnergyEVSECommandGetTargetsResponseID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterEnergyEVSECommandDisableID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterEnergyEVSECommandEnableChargingID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterEnergyEVSECommandStartDiagnosticsID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var clusterEnergyEVSECommandSetTargetsID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var clusterEnergyEVSECommandGetTargetsID: MTRCommandIDType { .MTRClusterLevelControlCommandStepWithOnOffID }
    public static var clusterEnergyEVSECommandClearTargetsID: MTRCommandIDType { .MTRClusterLevelControlCommandStopWithOnOffID }
    public static var clusterEnergyEVSEModeCommandChangeToModeID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterEnergyEVSEModeCommandChangeToModeResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterWaterHeaterModeCommandChangeToModeID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterWaterHeaterModeCommandChangeToModeResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterDeviceEnergyManagementModeCommandChangeToModeID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterDeviceEnergyManagementModeCommandChangeToModeResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterDoorLockCommandLockDoorID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterDoorLockCommandUnlockDoorID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterDoorLockCommandUnlockWithTimeoutID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var MTRClusterDoorLockCommandSetWeekDayScheduleID: MTRCommandIDType { .MTRClusterActionsCommandDisableActionWithDurationID }
    public static var MTRClusterDoorLockCommandGetWeekDayScheduleResponseID: MTRCommandIDType { .MTRClusterDoorLockCommandGetWeekDayScheduleID }
    public static var MTRClusterDoorLockCommandGetYearDayScheduleResponseID: MTRCommandIDType { .MTRClusterDoorLockCommandGetYearDayScheduleID }
    public static var MTRClusterDoorLockCommandGetHolidayScheduleResponseID: MTRCommandIDType { .MTRClusterDoorLockCommandGetHolidayScheduleID }
    public static var clusterDoorLockCommandLockDoorID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterDoorLockCommandUnlockDoorID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterDoorLockCommandUnlockWithTimeoutID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterDoorLockCommandSetWeekDayScheduleID: MTRCommandIDType { .MTRClusterActionsCommandDisableActionWithDurationID }
    public static var clusterDoorLockCommandGetWeekDayScheduleID: MTRCommandIDType { .MTRClusterDoorLockCommandGetWeekDayScheduleID }
    public static var clusterDoorLockCommandGetWeekDayScheduleResponseID: MTRCommandIDType { .MTRClusterDoorLockCommandGetWeekDayScheduleID }
    public static var clusterDoorLockCommandClearWeekDayScheduleID: MTRCommandIDType { .MTRClusterDoorLockCommandClearWeekDayScheduleID }
    public static var clusterDoorLockCommandSetYearDayScheduleID: MTRCommandIDType { .MTRClusterDoorLockCommandSetYearDayScheduleID }
    public static var clusterDoorLockCommandGetYearDayScheduleID: MTRCommandIDType { .MTRClusterDoorLockCommandGetYearDayScheduleID }
    public static var clusterDoorLockCommandGetYearDayScheduleResponseID: MTRCommandIDType { .MTRClusterDoorLockCommandGetYearDayScheduleID }
    public static var clusterDoorLockCommandClearYearDayScheduleID: MTRCommandIDType { .MTRClusterDoorLockCommandClearYearDayScheduleID }
    public static var clusterDoorLockCommandSetHolidayScheduleID: MTRCommandIDType { .MTRClusterDoorLockCommandSetHolidayScheduleID }
    public static var clusterDoorLockCommandGetHolidayScheduleID: MTRCommandIDType { .MTRClusterDoorLockCommandGetHolidayScheduleID }
    public static var clusterDoorLockCommandGetHolidayScheduleResponseID: MTRCommandIDType { .MTRClusterDoorLockCommandGetHolidayScheduleID }
    public static var clusterDoorLockCommandClearHolidayScheduleID: MTRCommandIDType { .MTRClusterDoorLockCommandClearHolidayScheduleID }
    public static var clusterDoorLockCommandSetUserID: MTRCommandIDType { .MTRClusterDoorLockCommandSetUserID }
    public static var clusterDoorLockCommandGetUserID: MTRCommandIDType { .MTRClusterDoorLockCommandGetUserID }
    public static var clusterDoorLockCommandGetUserResponseID: MTRCommandIDType { .MTRClusterDoorLockCommandGetUserResponseID }
    public static var clusterDoorLockCommandClearUserID: MTRCommandIDType { .MTRClusterDoorLockCommandClearUserID }
    public static var clusterDoorLockCommandSetCredentialID: MTRCommandIDType { .MTRClusterDoorLockCommandSetCredentialID }
    public static var clusterDoorLockCommandSetCredentialResponseID: MTRCommandIDType { .MTRClusterDoorLockCommandSetCredentialResponseID }
    public static var clusterDoorLockCommandGetCredentialStatusID: MTRCommandIDType { .MTRClusterDoorLockCommandGetCredentialStatusID }
    public static var clusterDoorLockCommandGetCredentialStatusResponseID: MTRCommandIDType { .MTRClusterDoorLockCommandGetCredentialStatusResponseID }
    public static var clusterDoorLockCommandClearCredentialID: MTRCommandIDType { .MTRClusterDoorLockCommandClearCredentialID }
    public static var MTRClusterWindowCoveringCommandUpOrOpenID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterWindowCoveringCommandDownOrCloseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterWindowCoveringCommandStopMotionID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var MTRClusterWindowCoveringCommandGoToLiftValueID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var MTRClusterWindowCoveringCommandGoToLiftPercentageID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var MTRClusterWindowCoveringCommandGoToTiltValueID: MTRCommandIDType { .MTRClusterLevelControlCommandStopWithOnOffID }
    public static var MTRClusterWindowCoveringCommandGoToTiltPercentageID: MTRCommandIDType { .MTRClusterLevelControlCommandMoveToClosestFrequencyID }
    public static var clusterWindowCoveringCommandUpOrOpenID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterWindowCoveringCommandDownOrCloseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterWindowCoveringCommandStopMotionID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterWindowCoveringCommandGoToLiftValueID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var clusterWindowCoveringCommandGoToLiftPercentageID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var clusterWindowCoveringCommandGoToTiltValueID: MTRCommandIDType { .MTRClusterLevelControlCommandStopWithOnOffID }
    public static var clusterWindowCoveringCommandGoToTiltPercentageID: MTRCommandIDType { .MTRClusterLevelControlCommandMoveToClosestFrequencyID }
    public static var clusterServiceAreaCommandSelectAreasID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterServiceAreaCommandSelectAreasResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterServiceAreaCommandSkipAreaID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterServiceAreaCommandSkipAreaResponseID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var MTRClusterThermostatCommandSetpointRaiseLowerID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterThermostatCommandGetWeeklyScheduleResponseID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterThermostatCommandSetWeeklyScheduleID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterThermostatCommandGetWeeklyScheduleID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var MTRClusterThermostatCommandClearWeeklyScheduleID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterThermostatCommandSetpointRaiseLowerID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterThermostatCommandGetWeeklyScheduleResponseID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterThermostatCommandSetWeeklyScheduleID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterThermostatCommandGetWeeklyScheduleID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterThermostatCommandClearWeeklyScheduleID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterThermostatCommandSetActiveScheduleRequestID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var clusterThermostatCommandSetActivePresetRequestID: MTRCommandIDType { .MTRClusterLevelControlCommandStepWithOnOffID }
    public static var clusterFanControlCommandStepID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterColorControlCommandMoveToHueID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterColorControlCommandMoveHueID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterColorControlCommandStepHueID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var MTRClusterColorControlCommandMoveToSaturationID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var MTRClusterColorControlCommandMoveSaturationID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var MTRClusterColorControlCommandStepSaturationID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var MTRClusterColorControlCommandMoveToHueAndSaturationID: MTRCommandIDType { .MTRClusterLevelControlCommandStepWithOnOffID }
    public static var MTRClusterColorControlCommandMoveToColorID: MTRCommandIDType { .MTRClusterLevelControlCommandStopWithOnOffID }
    public static var MTRClusterColorControlCommandMoveColorID: MTRCommandIDType { .MTRClusterLevelControlCommandMoveToClosestFrequencyID }
    public static var MTRClusterColorControlCommandStepColorID: MTRCommandIDType { .MTRClusterActionsCommandEnableActionWithDurationID }
    public static var MTRClusterColorControlCommandMoveToColorTemperatureID: MTRCommandIDType { .MTRClusterActionsCommandDisableActionID }
    public static var MTRClusterColorControlCommandEnhancedMoveToHueID: MTRCommandIDType { .MTRClusterIdentifyCommandTriggerEffectID }
    public static var MTRClusterColorControlCommandEnhancedMoveHueID: MTRCommandIDType { .MTRClusterOnOffCommandOnWithRecallGlobalSceneID }
    public static var MTRClusterColorControlCommandEnhancedStepHueID: MTRCommandIDType { .MTRClusterOnOffCommandOnWithTimedOffID }
    public static var clusterColorControlCommandMoveToHueID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterColorControlCommandMoveHueID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterColorControlCommandStepHueID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterColorControlCommandMoveToSaturationID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterColorControlCommandMoveSaturationID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var clusterColorControlCommandStepSaturationID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var clusterColorControlCommandMoveToHueAndSaturationID: MTRCommandIDType { .MTRClusterLevelControlCommandStepWithOnOffID }
    public static var clusterColorControlCommandMoveToColorID: MTRCommandIDType { .MTRClusterLevelControlCommandStopWithOnOffID }
    public static var clusterColorControlCommandMoveColorID: MTRCommandIDType { .MTRClusterLevelControlCommandMoveToClosestFrequencyID }
    public static var clusterColorControlCommandStepColorID: MTRCommandIDType { .MTRClusterActionsCommandEnableActionWithDurationID }
    public static var clusterColorControlCommandMoveToColorTemperatureID: MTRCommandIDType { .MTRClusterActionsCommandDisableActionID }
    public static var clusterColorControlCommandEnhancedMoveToHueID: MTRCommandIDType { .MTRClusterIdentifyCommandTriggerEffectID }
    public static var clusterColorControlCommandEnhancedMoveHueID: MTRCommandIDType { .MTRClusterOnOffCommandOnWithRecallGlobalSceneID }
    public static var clusterColorControlCommandEnhancedStepHueID: MTRCommandIDType { .MTRClusterOnOffCommandOnWithTimedOffID }
    public static var clusterColorControlCommandEnhancedMoveToHueAndSaturationID: MTRCommandIDType { .MTRClusterColorControlCommandEnhancedMoveToHueAndSaturationID }
    public static var clusterColorControlCommandColorLoopSetID: MTRCommandIDType { .MTRClusterColorControlCommandColorLoopSetID }
    public static var clusterColorControlCommandStopMoveStepID: MTRCommandIDType { .MTRClusterColorControlCommandStopMoveStepID }
    public static var clusterColorControlCommandMoveColorTemperatureID: MTRCommandIDType { .MTRClusterColorControlCommandMoveColorTemperatureID }
    public static var clusterColorControlCommandStepColorTemperatureID: MTRCommandIDType { .MTRClusterColorControlCommandStepColorTemperatureID }
    public static var clusterWiFiNetworkManagementCommandNetworkPassphraseRequestID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterWiFiNetworkManagementCommandNetworkPassphraseResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterThreadBorderRouterManagementCommandGetActiveDatasetRequestID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterThreadBorderRouterManagementCommandGetPendingDatasetRequestID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterThreadBorderRouterManagementCommandDatasetResponseID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterThreadBorderRouterManagementCommandSetActiveDatasetRequestID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterThreadBorderRouterManagementCommandSetPendingDatasetRequestID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var clusterThreadNetworkDirectoryCommandAddNetworkID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterThreadNetworkDirectoryCommandRemoveNetworkID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterThreadNetworkDirectoryCommandGetOperationalDatasetID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterThreadNetworkDirectoryCommandOperationalDatasetResponseID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var MTRClusterChannelCommandChangeChannelID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterChannelCommandChangeChannelResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterChannelCommandChangeChannelByNumberID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var MTRClusterChannelCommandSkipChannelID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterChannelCommandChangeChannelID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterChannelCommandChangeChannelResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterChannelCommandChangeChannelByNumberID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterChannelCommandSkipChannelID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterChannelCommandGetProgramGuideID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var clusterChannelCommandProgramGuideResponseID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var clusterChannelCommandRecordProgramID: MTRCommandIDType { .MTRClusterLevelControlCommandStepWithOnOffID }
    public static var clusterChannelCommandCancelRecordProgramID: MTRCommandIDType { .MTRClusterLevelControlCommandStopWithOnOffID }
    public static var MTRClusterTargetNavigatorCommandNavigateTargetID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterTargetNavigatorCommandNavigateTargetResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterTargetNavigatorCommandNavigateTargetID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterTargetNavigatorCommandNavigateTargetResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterMediaPlaybackCommandPlayID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterMediaPlaybackCommandPauseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterMediaPlaybackCommandStopPlaybackID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var MTRClusterMediaPlaybackCommandStartOverID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var MTRClusterMediaPlaybackCommandPreviousID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var MTRClusterMediaPlaybackCommandNextID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var MTRClusterMediaPlaybackCommandRewindID: MTRCommandIDType { .MTRClusterLevelControlCommandStepWithOnOffID }
    public static var MTRClusterMediaPlaybackCommandFastForwardID: MTRCommandIDType { .MTRClusterLevelControlCommandStopWithOnOffID }
    public static var MTRClusterMediaPlaybackCommandSkipForwardID: MTRCommandIDType { .MTRClusterLevelControlCommandMoveToClosestFrequencyID }
    public static var MTRClusterMediaPlaybackCommandSkipBackwardID: MTRCommandIDType { .MTRClusterActionsCommandEnableActionWithDurationID }
    public static var MTRClusterMediaPlaybackCommandPlaybackResponseID: MTRCommandIDType { .MTRClusterActionsCommandDisableActionID }
    public static var MTRClusterMediaPlaybackCommandSeekID: MTRCommandIDType { .MTRClusterActionsCommandDisableActionWithDurationID }
    public static var clusterMediaPlaybackCommandPlayID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterMediaPlaybackCommandPauseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterMediaPlaybackCommandStopID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterMediaPlaybackCommandStartOverID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterMediaPlaybackCommandPreviousID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var clusterMediaPlaybackCommandNextID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var clusterMediaPlaybackCommandRewindID: MTRCommandIDType { .MTRClusterLevelControlCommandStepWithOnOffID }
    public static var clusterMediaPlaybackCommandFastForwardID: MTRCommandIDType { .MTRClusterLevelControlCommandStopWithOnOffID }
    public static var clusterMediaPlaybackCommandSkipForwardID: MTRCommandIDType { .MTRClusterLevelControlCommandMoveToClosestFrequencyID }
    public static var clusterMediaPlaybackCommandSkipBackwardID: MTRCommandIDType { .MTRClusterActionsCommandEnableActionWithDurationID }
    public static var clusterMediaPlaybackCommandPlaybackResponseID: MTRCommandIDType { .MTRClusterActionsCommandDisableActionID }
    public static var clusterMediaPlaybackCommandSeekID: MTRCommandIDType { .MTRClusterActionsCommandDisableActionWithDurationID }
    public static var clusterMediaPlaybackCommandActivateAudioTrackID: MTRCommandIDType { .MTRClusterDoorLockCommandGetWeekDayScheduleID }
    public static var clusterMediaPlaybackCommandActivateTextTrackID: MTRCommandIDType { .MTRClusterDoorLockCommandClearWeekDayScheduleID }
    public static var clusterMediaPlaybackCommandDeactivateTextTrackID: MTRCommandIDType { .MTRClusterDoorLockCommandSetYearDayScheduleID }
    public static var MTRClusterMediaInputCommandSelectInputID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterMediaInputCommandShowInputStatusID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterMediaInputCommandHideInputStatusID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var MTRClusterMediaInputCommandRenameInputID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterMediaInputCommandSelectInputID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterMediaInputCommandShowInputStatusID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterMediaInputCommandHideInputStatusID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterMediaInputCommandRenameInputID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var MTRClusterLowPowerCommandSleepID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterLowPowerCommandSleepID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterKeypadInputCommandSendKeyID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterKeypadInputCommandSendKeyResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterKeypadInputCommandSendKeyID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterKeypadInputCommandSendKeyResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterContentLauncherCommandLaunchContentID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterContentLauncherCommandLaunchURLID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterContentLauncherCommandLaunchResponseID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterContentLauncherCommandLaunchContentID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterContentLauncherCommandLaunchURLID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterContentLauncherCommandLauncherResponseID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var MTRClusterAudioOutputCommandSelectOutputID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterAudioOutputCommandRenameOutputID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterAudioOutputCommandSelectOutputID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterAudioOutputCommandRenameOutputID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterApplicationLauncherCommandLaunchAppID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterApplicationLauncherCommandStopAppID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterApplicationLauncherCommandHideAppID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var MTRClusterApplicationLauncherCommandLauncherResponseID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterApplicationLauncherCommandLaunchAppID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterApplicationLauncherCommandStopAppID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterApplicationLauncherCommandHideAppID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterApplicationLauncherCommandLauncherResponseID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var MTRClusterAccountLoginCommandGetSetupPINID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterAccountLoginCommandGetSetupPINResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterAccountLoginCommandLoginID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var MTRClusterAccountLoginCommandLogoutID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterAccountLoginCommandGetSetupPINID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterAccountLoginCommandGetSetupPINResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterAccountLoginCommandLoginID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterAccountLoginCommandLogoutID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterContentAppObserverCommandContentAppMessageID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterContentAppObserverCommandContentAppMessageResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterCommissionerControlCommandRequestCommissioningApprovalID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterCommissionerControlCommandCommissionNodeID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterCommissionerControlCommandReverseOpenCommissioningWindowID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var MTRClusterTestClusterCommandTestID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterTestClusterCommandTestSpecificResponseID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterTestClusterCommandTestNotHandledID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterTestClusterCommandTestAddArgumentsResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterTestClusterCommandTestSpecificID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var MTRClusterTestClusterCommandTestSimpleArgumentResponseID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var MTRClusterTestClusterCommandTestUnknownCommandID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var MTRClusterTestClusterCommandTestStructArrayArgumentResponseID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var MTRClusterTestClusterCommandTestAddArgumentsID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var MTRClusterTestClusterCommandTestListInt8UReverseResponseID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var MTRClusterTestClusterCommandTestSimpleArgumentRequestID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var MTRClusterTestClusterCommandTestEnumsResponseID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var MTRClusterTestClusterCommandTestStructArrayArgumentRequestID: MTRCommandIDType { .MTRClusterLevelControlCommandStepWithOnOffID }
    public static var MTRClusterTestClusterCommandTestNullableOptionalResponseID: MTRCommandIDType { .MTRClusterLevelControlCommandStepWithOnOffID }
    public static var MTRClusterTestClusterCommandTestStructArgumentRequestID: MTRCommandIDType { .MTRClusterLevelControlCommandStopWithOnOffID }
    public static var MTRClusterTestClusterCommandTestComplexNullableOptionalResponseID: MTRCommandIDType { .MTRClusterLevelControlCommandStopWithOnOffID }
    public static var MTRClusterTestClusterCommandTestNestedStructArgumentRequestID: MTRCommandIDType { .MTRClusterLevelControlCommandMoveToClosestFrequencyID }
    public static var MTRClusterTestClusterCommandBooleanResponseID: MTRCommandIDType { .MTRClusterLevelControlCommandMoveToClosestFrequencyID }
    public static var MTRClusterTestClusterCommandTestListStructArgumentRequestID: MTRCommandIDType { .MTRClusterActionsCommandEnableActionWithDurationID }
    public static var MTRClusterTestClusterCommandSimpleStructResponseID: MTRCommandIDType { .MTRClusterActionsCommandEnableActionWithDurationID }
    public static var MTRClusterTestClusterCommandTestListInt8UArgumentRequestID: MTRCommandIDType { .MTRClusterActionsCommandDisableActionID }
    public static var MTRClusterTestClusterCommandTestEmitTestEventResponseID: MTRCommandIDType { .MTRClusterActionsCommandDisableActionID }
    public static var MTRClusterTestClusterCommandTestNestedStructListArgumentRequestID: MTRCommandIDType { .MTRClusterActionsCommandDisableActionWithDurationID }
    public static var MTRClusterTestClusterCommandTestEmitTestFabricScopedEventResponseID: MTRCommandIDType { .MTRClusterActionsCommandDisableActionWithDurationID }
    public static var MTRClusterTestClusterCommandTestListNestedStructListArgumentRequestID: MTRCommandIDType { .MTRClusterDoorLockCommandGetWeekDayScheduleID }
    public static var MTRClusterTestClusterCommandTestListInt8UReverseRequestID: MTRCommandIDType { .MTRClusterDoorLockCommandClearWeekDayScheduleID }
    public static var MTRClusterTestClusterCommandTestEnumsRequestID: MTRCommandIDType { .MTRClusterDoorLockCommandSetYearDayScheduleID }
    public static var MTRClusterTestClusterCommandTestNullableOptionalRequestID: MTRCommandIDType { .MTRClusterDoorLockCommandGetYearDayScheduleID }
    public static var MTRClusterTestClusterCommandTestComplexNullableOptionalRequestID: MTRCommandIDType { .MTRClusterDoorLockCommandClearYearDayScheduleID }
    public static var MTRClusterTestClusterCommandSimpleStructEchoRequestID: MTRCommandIDType { .MTRClusterDoorLockCommandSetHolidayScheduleID }
    public static var MTRClusterTestClusterCommandTimedInvokeRequestID: MTRCommandIDType { .MTRClusterDoorLockCommandGetHolidayScheduleID }
    public static var MTRClusterTestClusterCommandTestSimpleOptionalArgumentRequestID: MTRCommandIDType { .MTRClusterDoorLockCommandClearHolidayScheduleID }
    public static var clusterUnitTestingCommandTestID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterUnitTestingCommandTestSpecificResponseID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterUnitTestingCommandTestNotHandledID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterUnitTestingCommandTestAddArgumentsResponseID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterUnitTestingCommandTestSpecificID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterUnitTestingCommandTestSimpleArgumentResponseID: MTRCommandIDType { .MTRClusterGroupsCommandGetGroupMembershipID }
    public static var clusterUnitTestingCommandTestUnknownCommandID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterUnitTestingCommandTestStructArrayArgumentResponseID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveGroupID }
    public static var clusterUnitTestingCommandTestAddArgumentsID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var clusterUnitTestingCommandTestListInt8UReverseResponseID: MTRCommandIDType { .MTRClusterGroupsCommandRemoveAllGroupsID }
    public static var clusterUnitTestingCommandTestSimpleArgumentRequestID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var clusterUnitTestingCommandTestEnumsResponseID: MTRCommandIDType { .MTRClusterGroupsCommandAddGroupIfIdentifyingID }
    public static var clusterUnitTestingCommandTestStructArrayArgumentRequestID: MTRCommandIDType { .MTRClusterLevelControlCommandStepWithOnOffID }
    public static var clusterUnitTestingCommandTestNullableOptionalResponseID: MTRCommandIDType { .MTRClusterLevelControlCommandStepWithOnOffID }
    public static var clusterUnitTestingCommandTestStructArgumentRequestID: MTRCommandIDType { .MTRClusterLevelControlCommandStopWithOnOffID }
    public static var clusterUnitTestingCommandTestComplexNullableOptionalResponseID: MTRCommandIDType { .MTRClusterLevelControlCommandStopWithOnOffID }
    public static var clusterUnitTestingCommandTestNestedStructArgumentRequestID: MTRCommandIDType { .MTRClusterLevelControlCommandMoveToClosestFrequencyID }
    public static var clusterUnitTestingCommandBooleanResponseID: MTRCommandIDType { .MTRClusterLevelControlCommandMoveToClosestFrequencyID }
    public static var clusterUnitTestingCommandTestListStructArgumentRequestID: MTRCommandIDType { .MTRClusterActionsCommandEnableActionWithDurationID }
    public static var clusterUnitTestingCommandSimpleStructResponseID: MTRCommandIDType { .MTRClusterActionsCommandEnableActionWithDurationID }
    public static var clusterUnitTestingCommandTestListInt8UArgumentRequestID: MTRCommandIDType { .MTRClusterActionsCommandDisableActionID }
    public static var clusterUnitTestingCommandTestEmitTestEventResponseID: MTRCommandIDType { .MTRClusterActionsCommandDisableActionID }
    public static var clusterUnitTestingCommandTestNestedStructListArgumentRequestID: MTRCommandIDType { .MTRClusterActionsCommandDisableActionWithDurationID }
    public static var clusterUnitTestingCommandTestEmitTestFabricScopedEventResponseID: MTRCommandIDType { .MTRClusterActionsCommandDisableActionWithDurationID }
    public static var clusterUnitTestingCommandTestListNestedStructListArgumentRequestID: MTRCommandIDType { .MTRClusterDoorLockCommandGetWeekDayScheduleID }
    public static var clusterUnitTestingCommandTestListInt8UReverseRequestID: MTRCommandIDType { .MTRClusterDoorLockCommandClearWeekDayScheduleID }
    public static var clusterUnitTestingCommandTestEnumsRequestID: MTRCommandIDType { .MTRClusterDoorLockCommandSetYearDayScheduleID }
    public static var clusterUnitTestingCommandTestNullableOptionalRequestID: MTRCommandIDType { .MTRClusterDoorLockCommandGetYearDayScheduleID }
    public static var clusterUnitTestingCommandTestComplexNullableOptionalRequestID: MTRCommandIDType { .MTRClusterDoorLockCommandClearYearDayScheduleID }
    public static var clusterUnitTestingCommandSimpleStructEchoRequestID: MTRCommandIDType { .MTRClusterDoorLockCommandSetHolidayScheduleID }
    public static var clusterUnitTestingCommandTimedInvokeRequestID: MTRCommandIDType { .MTRClusterDoorLockCommandGetHolidayScheduleID }
    public static var clusterUnitTestingCommandTestSimpleOptionalArgumentRequestID: MTRCommandIDType { .MTRClusterDoorLockCommandClearHolidayScheduleID }
    public static var clusterUnitTestingCommandTestEmitTestEventRequestID: MTRCommandIDType { .MTRClusterTestClusterCommandTestEmitTestEventRequestID }
    public static var clusterUnitTestingCommandTestEmitTestFabricScopedEventRequestID: MTRCommandIDType { .MTRClusterTestClusterCommandTestEmitTestFabricScopedEventRequestID }
    public static var MTRClusterBarrierControlCommandBarrierControlGoToPercentID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterBarrierControlCommandBarrierControlStopID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterBarrierControlCommandBarrierControlGoToPercentID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterBarrierControlCommandBarrierControlStopID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterElectricalMeasurementCommandGetProfileInfoResponseCommandID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterElectricalMeasurementCommandGetProfileInfoCommandID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var MTRClusterElectricalMeasurementCommandGetMeasurementProfileResponseCommandID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var MTRClusterElectricalMeasurementCommandGetMeasurementProfileCommandID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterElectricalMeasurementCommandGetProfileInfoResponseCommandID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterElectricalMeasurementCommandGetProfileInfoCommandID: MTRCommandIDType { .MTRClusterIdentifyCommandIdentifyID }
    public static var clusterElectricalMeasurementCommandGetMeasurementProfileResponseCommandID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
    public static var clusterElectricalMeasurementCommandGetMeasurementProfileCommandID: MTRCommandIDType { .MTRClusterGroupsCommandViewGroupID }
}

public enum MTRDeviceTypeIDType: UInt32, Sendable, Hashable {
    case doorLockID = 10
    case doorLockControllerID = 11
    case aggregatorID = 14
    case genericSwitchID = 15
    case powerSourceID = 17
    case otaRequestorID = 18
    case bridgedNodeID = 19
    case otaProviderID = 20
    case contactSensorID = 21
    case rootNodeID = 22
    case solarPowerID = 23
    case batteryStorageID = 24
    case secondaryNetworkInterfaceID = 25
    case speakerID = 34
    case castingVideoPlayerID = 35
    case contentAppID = 36
    case modeSelectID = 39
    case basicVideoPlayerID = 40
    case castingVideoClientID = 41
    case videoRemoteControlID = 42
    case fanID = 43
    case airQualitySensorID = 44
    case airPurifierID = 45
    case waterFreezeDetectorID = 65
    case waterValveID = 66
    case waterLeakDetectorID = 67
    case rainSensorID = 68
    case refrigeratorID = 112
    case temperatureControlledCabinetID = 113
    case roomAirConditionerID = 114
    case laundryWasherID = 115
    case roboticVacuumCleanerID = 116
    case dishwasherID = 117
    case smokeCOAlarmID = 118
    case cookSurfaceID = 119
    case cooktopID = 120
    case microwaveOvenID = 121
    case extractorHoodID = 122
    case ovenID = 123
    case laundryDryerID = 124
    case networkInfrastructureManagerID = 144
    case threadBorderRouterID = 145
    case onOffLightID = 256
    case dimmableLightID = 257
    case onOffLightSwitchID = 259
    case dimmerSwitchID = 260
    case colorDimmerSwitchID = 261
    case lightSensorID = 262
    case occupancySensorID = 263
    case onOffPlugInUnitID = 266
    case dimmablePlugInUnitID = 267
    case colorTemperatureLightID = 268
    case extendedColorLightID = 269
    case windowCoveringID = 514
    case windowCoveringControllerID = 515
    case thermostatID = 769
    case temperatureSensorID = 770
    case pumpID = 771
    case pumpControllerID = 772
    case pressureSensorID = 773
    case flowSensorID = 774
    case humiditySensorID = 775
    case heatPumpID = 777
    case EVSEID = 1292
    case deviceEnergyManagementID = 1293
    case waterHeaterID = 1295
    case electricalSensorID = 1296
    case controlBridgeID = 2112
    case onOffSensorID = 2128
}

public enum MTREventIDType: UInt32, Sendable, Hashable {
    case MTRClusterAccessControlEventAccessControlEntryChangedID = 0
    case MTRClusterAccessControlEventAccessControlExtensionChangedID = 1
    case clusterAccessControlEventFabricRestrictionReviewUpdateID = 2
    case MTRClusterBasicEventReachableChangedID = 3
    case clusterTimeSynchronizationEventMissingTrustedTimeSourceID = 4
    case clusterBridgedDeviceBasicInformationEventActiveChangedID = 128
    case MTRClusterSwitchEventMultiPressOngoingID = 5
    case MTRClusterSwitchEventMultiPressCompleteID = 6
    case clusterSmokeCOAlarmEventMuteEndedID = 7
    case clusterSmokeCOAlarmEventInterconnectSmokeAlarmID = 8
    case clusterSmokeCOAlarmEventInterconnectCOAlarmID = 9
    case clusterSmokeCOAlarmEventAllClearID = 10
    case MTRClusterPumpConfigurationAndControlEventElectronicNonFatalFailureID = 11
    case MTRClusterPumpConfigurationAndControlEventElectronicFatalFailureID = 12
    case MTRClusterPumpConfigurationAndControlEventGeneralFaultID = 13
    case MTRClusterPumpConfigurationAndControlEventLeakageID = 14
    case MTRClusterPumpConfigurationAndControlEventAirDetectionID = 15
    case MTRClusterPumpConfigurationAndControlEventTurbineOperationID = 16
    public static var clusterAccessControlEventAccessControlEntryChangedID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterAccessControlEventAccessControlExtensionChangedID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var MTRClusterActionsEventStateChangedID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var MTRClusterActionsEventActionFailedID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterActionsEventStateChangedID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterActionsEventActionFailedID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var MTRClusterBasicEventStartUpID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var MTRClusterBasicEventShutDownID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var MTRClusterBasicEventLeaveID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
    public static var clusterBasicInformationEventStartUpID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterBasicInformationEventShutDownID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterBasicInformationEventLeaveID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
    public static var clusterBasicInformationEventReachableChangedID: MTREventIDType { .MTRClusterBasicEventReachableChangedID }
    public static var MTRClusterOtaSoftwareUpdateRequestorEventStateTransitionID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var MTRClusterOtaSoftwareUpdateRequestorEventVersionAppliedID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var MTRClusterOtaSoftwareUpdateRequestorEventDownloadErrorID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
    public static var clusterOTASoftwareUpdateRequestorEventStateTransitionID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterOTASoftwareUpdateRequestorEventVersionAppliedID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterOTASoftwareUpdateRequestorEventDownloadErrorID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
    public static var clusterPowerSourceEventWiredFaultChangeID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterPowerSourceEventBatFaultChangeID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterPowerSourceEventBatChargeFaultChangeID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
    public static var MTRClusterGeneralDiagnosticsEventHardwareFaultChangeID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var MTRClusterGeneralDiagnosticsEventRadioFaultChangeID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var MTRClusterGeneralDiagnosticsEventNetworkFaultChangeID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
    public static var MTRClusterGeneralDiagnosticsEventBootReasonID: MTREventIDType { .MTRClusterBasicEventReachableChangedID }
    public static var clusterGeneralDiagnosticsEventHardwareFaultChangeID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterGeneralDiagnosticsEventRadioFaultChangeID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterGeneralDiagnosticsEventNetworkFaultChangeID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
    public static var clusterGeneralDiagnosticsEventBootReasonID: MTREventIDType { .MTRClusterBasicEventReachableChangedID }
    public static var MTRClusterSoftwareDiagnosticsEventSoftwareFaultID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterSoftwareDiagnosticsEventSoftwareFaultID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var MTRClusterThreadNetworkDiagnosticsEventConnectionStatusID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var MTRClusterThreadNetworkDiagnosticsEventNetworkFaultChangeID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterThreadNetworkDiagnosticsEventConnectionStatusID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterThreadNetworkDiagnosticsEventNetworkFaultChangeID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var MTRClusterWiFiNetworkDiagnosticsEventDisconnectionID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var MTRClusterWiFiNetworkDiagnosticsEventAssociationFailureID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var MTRClusterWiFiNetworkDiagnosticsEventConnectionStatusID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
    public static var clusterWiFiNetworkDiagnosticsEventDisconnectionID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterWiFiNetworkDiagnosticsEventAssociationFailureID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterWiFiNetworkDiagnosticsEventConnectionStatusID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
    public static var clusterTimeSynchronizationEventDSTTableEmptyID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterTimeSynchronizationEventDSTStatusID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterTimeSynchronizationEventTimeZoneStatusID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
    public static var clusterTimeSynchronizationEventTimeFailureID: MTREventIDType { .MTRClusterBasicEventReachableChangedID }
    public static var MTRClusterBridgedDeviceBasicEventStartUpID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var MTRClusterBridgedDeviceBasicEventShutDownID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var MTRClusterBridgedDeviceBasicEventLeaveID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
    public static var MTRClusterBridgedDeviceBasicEventReachableChangedID: MTREventIDType { .MTRClusterBasicEventReachableChangedID }
    public static var clusterBridgedDeviceBasicInformationEventStartUpID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterBridgedDeviceBasicInformationEventShutDownID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterBridgedDeviceBasicInformationEventLeaveID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
    public static var clusterBridgedDeviceBasicInformationEventReachableChangedID: MTREventIDType { .MTRClusterBasicEventReachableChangedID }
    public static var MTRClusterSwitchEventSwitchLatchedID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var MTRClusterSwitchEventInitialPressID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var MTRClusterSwitchEventLongPressID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
    public static var MTRClusterSwitchEventShortReleaseID: MTREventIDType { .MTRClusterBasicEventReachableChangedID }
    public static var MTRClusterSwitchEventLongReleaseID: MTREventIDType { .clusterTimeSynchronizationEventMissingTrustedTimeSourceID }
    public static var clusterSwitchEventSwitchLatchedID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterSwitchEventInitialPressID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterSwitchEventLongPressID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
    public static var clusterSwitchEventShortReleaseID: MTREventIDType { .MTRClusterBasicEventReachableChangedID }
    public static var clusterSwitchEventLongReleaseID: MTREventIDType { .clusterTimeSynchronizationEventMissingTrustedTimeSourceID }
    public static var clusterSwitchEventMultiPressOngoingID: MTREventIDType { .MTRClusterSwitchEventMultiPressOngoingID }
    public static var clusterSwitchEventMultiPressCompleteID: MTREventIDType { .MTRClusterSwitchEventMultiPressCompleteID }
    public static var MTRClusterBooleanStateEventStateChangeID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterBooleanStateEventStateChangeID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterOvenCavityOperationalStateEventOperationalErrorID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterOvenCavityOperationalStateEventOperationCompletionID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterRefrigeratorAlarmEventNotifyID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterSmokeCOAlarmEventSmokeAlarmID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterSmokeCOAlarmEventCOAlarmID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterSmokeCOAlarmEventLowBatteryID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
    public static var clusterSmokeCOAlarmEventHardwareFaultID: MTREventIDType { .MTRClusterBasicEventReachableChangedID }
    public static var clusterSmokeCOAlarmEventEndOfServiceID: MTREventIDType { .clusterTimeSynchronizationEventMissingTrustedTimeSourceID }
    public static var clusterSmokeCOAlarmEventSelfTestCompleteID: MTREventIDType { .MTRClusterSwitchEventMultiPressOngoingID }
    public static var clusterSmokeCOAlarmEventAlarmMutedID: MTREventIDType { .MTRClusterSwitchEventMultiPressCompleteID }
    public static var clusterDishwasherAlarmEventNotifyID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterOperationalStateEventOperationalErrorID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterOperationalStateEventOperationCompletionID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterRVCOperationalStateEventOperationalErrorID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterRVCOperationalStateEventOperationCompletionID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterBooleanStateConfigurationEventAlarmsStateChangedID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterBooleanStateConfigurationEventSensorFaultID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterValveConfigurationAndControlEventValveStateChangedID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterValveConfigurationAndControlEventValveFaultID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterElectricalPowerMeasurementEventMeasurementPeriodRangesID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterElectricalEnergyMeasurementEventCumulativeEnergyMeasuredID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterElectricalEnergyMeasurementEventPeriodicEnergyMeasuredID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterWaterHeaterManagementEventBoostStartedID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterWaterHeaterManagementEventBoostEndedID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterMessagesEventMessageQueuedID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterMessagesEventMessagePresentedID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterMessagesEventMessageCompleteID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
    public static var clusterDeviceEnergyManagementEventPowerAdjustStartID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterDeviceEnergyManagementEventPowerAdjustEndID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterDeviceEnergyManagementEventPausedID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
    public static var clusterDeviceEnergyManagementEventResumedID: MTREventIDType { .MTRClusterBasicEventReachableChangedID }
    public static var clusterEnergyEVSEEventEVConnectedID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterEnergyEVSEEventEVNotDetectedID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterEnergyEVSEEventEnergyTransferStartedID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
    public static var clusterEnergyEVSEEventEnergyTransferStoppedID: MTREventIDType { .MTRClusterBasicEventReachableChangedID }
    public static var clusterEnergyEVSEEventFaultID: MTREventIDType { .clusterTimeSynchronizationEventMissingTrustedTimeSourceID }
    public static var clusterEnergyEVSEEventRFIDID: MTREventIDType { .MTRClusterSwitchEventMultiPressOngoingID }
    public static var MTRClusterDoorLockEventDoorLockAlarmID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var MTRClusterDoorLockEventDoorStateChangeID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var MTRClusterDoorLockEventLockOperationID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
    public static var MTRClusterDoorLockEventLockOperationErrorID: MTREventIDType { .MTRClusterBasicEventReachableChangedID }
    public static var MTRClusterDoorLockEventLockUserChangeID: MTREventIDType { .clusterTimeSynchronizationEventMissingTrustedTimeSourceID }
    public static var clusterDoorLockEventDoorLockAlarmID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterDoorLockEventDoorStateChangeID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterDoorLockEventLockOperationID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
    public static var clusterDoorLockEventLockOperationErrorID: MTREventIDType { .MTRClusterBasicEventReachableChangedID }
    public static var clusterDoorLockEventLockUserChangeID: MTREventIDType { .clusterTimeSynchronizationEventMissingTrustedTimeSourceID }
    public static var MTRClusterPumpConfigurationAndControlEventSupplyVoltageLowID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var MTRClusterPumpConfigurationAndControlEventSupplyVoltageHighID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var MTRClusterPumpConfigurationAndControlEventPowerMissingPhaseID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
    public static var MTRClusterPumpConfigurationAndControlEventSystemPressureLowID: MTREventIDType { .MTRClusterBasicEventReachableChangedID }
    public static var MTRClusterPumpConfigurationAndControlEventSystemPressureHighID: MTREventIDType { .clusterTimeSynchronizationEventMissingTrustedTimeSourceID }
    public static var MTRClusterPumpConfigurationAndControlEventDryRunningID: MTREventIDType { .MTRClusterSwitchEventMultiPressOngoingID }
    public static var MTRClusterPumpConfigurationAndControlEventMotorTemperatureHighID: MTREventIDType { .MTRClusterSwitchEventMultiPressCompleteID }
    public static var MTRClusterPumpConfigurationAndControlEventPumpMotorFatalFailureID: MTREventIDType { .clusterSmokeCOAlarmEventMuteEndedID }
    public static var MTRClusterPumpConfigurationAndControlEventElectronicTemperatureHighID: MTREventIDType { .clusterSmokeCOAlarmEventInterconnectSmokeAlarmID }
    public static var MTRClusterPumpConfigurationAndControlEventPumpBlockedID: MTREventIDType { .clusterSmokeCOAlarmEventInterconnectCOAlarmID }
    public static var MTRClusterPumpConfigurationAndControlEventSensorFailureID: MTREventIDType { .clusterSmokeCOAlarmEventAllClearID }
    public static var clusterPumpConfigurationAndControlEventSupplyVoltageLowID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterPumpConfigurationAndControlEventSupplyVoltageHighID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterPumpConfigurationAndControlEventPowerMissingPhaseID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
    public static var clusterPumpConfigurationAndControlEventSystemPressureLowID: MTREventIDType { .MTRClusterBasicEventReachableChangedID }
    public static var clusterPumpConfigurationAndControlEventSystemPressureHighID: MTREventIDType { .clusterTimeSynchronizationEventMissingTrustedTimeSourceID }
    public static var clusterPumpConfigurationAndControlEventDryRunningID: MTREventIDType { .MTRClusterSwitchEventMultiPressOngoingID }
    public static var clusterPumpConfigurationAndControlEventMotorTemperatureHighID: MTREventIDType { .MTRClusterSwitchEventMultiPressCompleteID }
    public static var clusterPumpConfigurationAndControlEventPumpMotorFatalFailureID: MTREventIDType { .clusterSmokeCOAlarmEventMuteEndedID }
    public static var clusterPumpConfigurationAndControlEventElectronicTemperatureHighID: MTREventIDType { .clusterSmokeCOAlarmEventInterconnectSmokeAlarmID }
    public static var clusterPumpConfigurationAndControlEventPumpBlockedID: MTREventIDType { .clusterSmokeCOAlarmEventInterconnectCOAlarmID }
    public static var clusterPumpConfigurationAndControlEventSensorFailureID: MTREventIDType { .clusterSmokeCOAlarmEventAllClearID }
    public static var clusterPumpConfigurationAndControlEventElectronicNonFatalFailureID: MTREventIDType { .MTRClusterPumpConfigurationAndControlEventElectronicNonFatalFailureID }
    public static var clusterPumpConfigurationAndControlEventElectronicFatalFailureID: MTREventIDType { .MTRClusterPumpConfigurationAndControlEventElectronicFatalFailureID }
    public static var clusterPumpConfigurationAndControlEventGeneralFaultID: MTREventIDType { .MTRClusterPumpConfigurationAndControlEventGeneralFaultID }
    public static var clusterPumpConfigurationAndControlEventLeakageID: MTREventIDType { .MTRClusterPumpConfigurationAndControlEventLeakageID }
    public static var clusterPumpConfigurationAndControlEventAirDetectionID: MTREventIDType { .MTRClusterPumpConfigurationAndControlEventAirDetectionID }
    public static var clusterPumpConfigurationAndControlEventTurbineOperationID: MTREventIDType { .MTRClusterPumpConfigurationAndControlEventTurbineOperationID }
    public static var clusterOccupancySensingEventOccupancyChangedID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterTargetNavigatorEventTargetUpdatedID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterMediaPlaybackEventStateChangedID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterAccountLoginEventLoggedOutID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var clusterCommissionerControlEventCommissioningRequestResultID: MTREventIDType { .MTRClusterAccessControlEventAccessControlEntryChangedID }
    public static var MTRClusterTestClusterEventTestEventID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var MTRClusterTestClusterEventTestFabricScopedEventID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
    public static var clusterUnitTestingEventTestEventID: MTREventIDType { .MTRClusterAccessControlEventAccessControlExtensionChangedID }
    public static var clusterUnitTestingEventTestFabricScopedEventID: MTREventIDType { .clusterAccessControlEventFabricRestrictionReviewUpdateID }
}

