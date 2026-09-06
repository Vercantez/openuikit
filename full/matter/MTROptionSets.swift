import Foundation

public struct MTRAccessControlFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let `extension` = MTRAccessControlFeature(rawValue: 1)
    public static let managedDevice = MTRAccessControlFeature(rawValue: 2)
}

public struct MTRActionsCommandBits: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let instantAction = MTRActionsCommandBits(rawValue: 1)
    public static let instantActionWithTransition = MTRActionsCommandBits(rawValue: 2)
    public static let startAction = MTRActionsCommandBits(rawValue: 4)
    public static let startActionWithDuration = MTRActionsCommandBits(rawValue: 8)
    public static let stopAction = MTRActionsCommandBits(rawValue: 16)
    public static let pauseAction = MTRActionsCommandBits(rawValue: 32)
    public static let pauseActionWithDuration = MTRActionsCommandBits(rawValue: 64)
    public static let resumeAction = MTRActionsCommandBits(rawValue: 128)
    public static let enableAction = MTRActionsCommandBits(rawValue: 256)
    public static let enableActionWithDuration = MTRActionsCommandBits(rawValue: 512)
    public static let disableAction = MTRActionsCommandBits(rawValue: 1024)
    public static let disableActionWithDuration = MTRActionsCommandBits(rawValue: 2048)
}

public struct MTRActivatedCarbonFilterMonitoringFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let condition = MTRActivatedCarbonFilterMonitoringFeature(rawValue: 1)
    public static let warning = MTRActivatedCarbonFilterMonitoringFeature(rawValue: 2)
    public static let replacementProductList = MTRActivatedCarbonFilterMonitoringFeature(rawValue: 4)
}

public struct MTRAdministratorCommissioningFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let basic = MTRAdministratorCommissioningFeature(rawValue: 1)
}

public struct MTRAirQualityFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let fair = MTRAirQualityFeature(rawValue: 1)
    public static let moderate = MTRAirQualityFeature(rawValue: 2)
    public static let veryPoor = MTRAirQualityFeature(rawValue: 4)
    public static let extremelyPoor = MTRAirQualityFeature(rawValue: 8)
}

public struct MTRApplicationLauncherFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let applicationPlatform = MTRApplicationLauncherFeature(rawValue: 1)
}

public struct MTRAudioOutputFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let nameUpdates = MTRAudioOutputFeature(rawValue: 1)
}

public struct MTRBooleanStateConfigurationAlarmModeBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let visual = MTRBooleanStateConfigurationAlarmModeBitmap(rawValue: 1)
    public static let audible = MTRBooleanStateConfigurationAlarmModeBitmap(rawValue: 2)
}

public struct MTRBooleanStateConfigurationFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let visual = MTRBooleanStateConfigurationFeature(rawValue: 1)
    public static let audible = MTRBooleanStateConfigurationFeature(rawValue: 2)
    public static let alarmSuppress = MTRBooleanStateConfigurationFeature(rawValue: 4)
    public static let sensitivityLevel = MTRBooleanStateConfigurationFeature(rawValue: 8)
}

public struct MTRBooleanStateConfigurationSensorFaultBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let generalFault = MTRBooleanStateConfigurationSensorFaultBitmap(rawValue: 1)
}

public struct MTRBridgedDeviceBasicInformationFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let bridgedICDSupport = MTRBridgedDeviceBasicInformationFeature(rawValue: 1)
}

public struct MTRCarbonDioxideConcentrationMeasurementFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let numericMeasurement = MTRCarbonDioxideConcentrationMeasurementFeature(rawValue: 1)
    public static let levelIndication = MTRCarbonDioxideConcentrationMeasurementFeature(rawValue: 2)
    public static let mediumLevel = MTRCarbonDioxideConcentrationMeasurementFeature(rawValue: 4)
    public static let criticalLevel = MTRCarbonDioxideConcentrationMeasurementFeature(rawValue: 8)
    public static let peakMeasurement = MTRCarbonDioxideConcentrationMeasurementFeature(rawValue: 16)
    public static let averageMeasurement = MTRCarbonDioxideConcentrationMeasurementFeature(rawValue: 32)
}

public struct MTRCarbonMonoxideConcentrationMeasurementFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let numericMeasurement = MTRCarbonMonoxideConcentrationMeasurementFeature(rawValue: 1)
    public static let levelIndication = MTRCarbonMonoxideConcentrationMeasurementFeature(rawValue: 2)
    public static let mediumLevel = MTRCarbonMonoxideConcentrationMeasurementFeature(rawValue: 4)
    public static let criticalLevel = MTRCarbonMonoxideConcentrationMeasurementFeature(rawValue: 8)
    public static let peakMeasurement = MTRCarbonMonoxideConcentrationMeasurementFeature(rawValue: 16)
    public static let averageMeasurement = MTRCarbonMonoxideConcentrationMeasurementFeature(rawValue: 32)
}

public struct MTRChannelFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let channelList = MTRChannelFeature(rawValue: 1)
    public static let lineupInfo = MTRChannelFeature(rawValue: 2)
    public static let electronicGuide = MTRChannelFeature(rawValue: 4)
    public static let recordProgram = MTRChannelFeature(rawValue: 8)
}

public struct MTRChannelRecordingFlagBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let scheduled = MTRChannelRecordingFlagBitmap(rawValue: 1)
    public static let recordSeries = MTRChannelRecordingFlagBitmap(rawValue: 2)
    public static let recorded = MTRChannelRecordingFlagBitmap(rawValue: 4)
}

public struct MTRColorControlColorCapabilities: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let hueSaturationSupported = MTRColorControlColorCapabilities(rawValue: 1)
    public static let enhancedHueSupported = MTRColorControlColorCapabilities(rawValue: 2)
    public static let colorLoopSupported = MTRColorControlColorCapabilities(rawValue: 4)
    public static let xyAttributesSupported = MTRColorControlColorCapabilities(rawValue: 8)
    public static let colorTemperatureSupported = MTRColorControlColorCapabilities(rawValue: 16)
}

public struct MTRColorControlColorCapabilitiesBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let hueSaturation = MTRColorControlColorCapabilitiesBitmap(rawValue: 1)
    public static let enhancedHue = MTRColorControlColorCapabilitiesBitmap(rawValue: 2)
    public static let colorLoop = MTRColorControlColorCapabilitiesBitmap(rawValue: 4)
    public static let XY = MTRColorControlColorCapabilitiesBitmap(rawValue: 8)
    public static let colorTemperature = MTRColorControlColorCapabilitiesBitmap(rawValue: 16)
}

public struct MTRColorControlColorLoopUpdateFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let updateAction = MTRColorControlColorLoopUpdateFlags(rawValue: 1)
    public static let updateDirection = MTRColorControlColorLoopUpdateFlags(rawValue: 2)
    public static let updateTime = MTRColorControlColorLoopUpdateFlags(rawValue: 4)
    public static let updateStartHue = MTRColorControlColorLoopUpdateFlags(rawValue: 8)
}

public struct MTRColorControlFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let hueAndSaturation = MTRColorControlFeature(rawValue: 1)
    public static let enhancedHue = MTRColorControlFeature(rawValue: 2)
    public static let colorLoop = MTRColorControlFeature(rawValue: 4)
    public static let XY = MTRColorControlFeature(rawValue: 8)
    public static let colorTemperature = MTRColorControlFeature(rawValue: 16)
}

public struct MTRColorControlOptionsBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let executeIfOff = MTRColorControlOptionsBitmap(rawValue: 1)
}

public struct MTRColorControlUpdateFlagsBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let updateAction = MTRColorControlUpdateFlagsBitmap(rawValue: 1)
    public static let updateDirection = MTRColorControlUpdateFlagsBitmap(rawValue: 2)
    public static let updateTime = MTRColorControlUpdateFlagsBitmap(rawValue: 4)
    public static let updateStartHue = MTRColorControlUpdateFlagsBitmap(rawValue: 8)
}

public struct MTRCommissionerControlSupportedDeviceCategoryBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let fabricSynchronization = MTRCommissionerControlSupportedDeviceCategoryBitmap(rawValue: 1)
}

public struct MTRContentLauncherFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let contentSearch = MTRContentLauncherFeature(rawValue: 1)
    public static let urlPlayback = MTRContentLauncherFeature(rawValue: 2)
    public static let advancedSeek = MTRContentLauncherFeature(rawValue: 4)
    public static let textTracks = MTRContentLauncherFeature(rawValue: 8)
    public static let audioTracks = MTRContentLauncherFeature(rawValue: 16)
}

public struct MTRContentLauncherSupportedProtocolsBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let DASH = MTRContentLauncherSupportedProtocolsBitmap(rawValue: 1)
    public static let HLS = MTRContentLauncherSupportedProtocolsBitmap(rawValue: 2)
}

public struct MTRContentLauncherSupportedStreamingProtocol: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let DASH = MTRContentLauncherSupportedStreamingProtocol(rawValue: 1)
    public static let HLS = MTRContentLauncherSupportedStreamingProtocol(rawValue: 2)
}

public struct MTRDeviceEnergyManagementFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let powerAdjustment = MTRDeviceEnergyManagementFeature(rawValue: 1)
    public static let powerForecastReporting = MTRDeviceEnergyManagementFeature(rawValue: 2)
    public static let stateForecastReporting = MTRDeviceEnergyManagementFeature(rawValue: 4)
    public static let startTimeAdjustment = MTRDeviceEnergyManagementFeature(rawValue: 8)
    public static let pausable = MTRDeviceEnergyManagementFeature(rawValue: 16)
    public static let forecastAdjustment = MTRDeviceEnergyManagementFeature(rawValue: 32)
    public static let constraintBasedAdjustment = MTRDeviceEnergyManagementFeature(rawValue: 64)
}

public struct MTRDishwasherAlarmAlarmBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let doorError = MTRDishwasherAlarmAlarmBitmap(rawValue: 1)
}

public struct MTRDishwasherAlarmFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let reset = MTRDishwasherAlarmFeature(rawValue: 1)
}

public struct MTRDoorLockDayOfWeek: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let sunday = MTRDoorLockDayOfWeek(rawValue: 1)
    public static let monday = MTRDoorLockDayOfWeek(rawValue: 2)
    public static let tuesday = MTRDoorLockDayOfWeek(rawValue: 4)
    public static let wednesday = MTRDoorLockDayOfWeek(rawValue: 8)
    public static let thursday = MTRDoorLockDayOfWeek(rawValue: 16)
    public static let friday = MTRDoorLockDayOfWeek(rawValue: 32)
    public static let saturday = MTRDoorLockDayOfWeek(rawValue: 64)
}

public struct MTRDoorLockDaysMaskMap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let sunday = MTRDoorLockDaysMaskMap(rawValue: 1)
    public static let monday = MTRDoorLockDaysMaskMap(rawValue: 2)
    public static let tuesday = MTRDoorLockDaysMaskMap(rawValue: 4)
    public static let wednesday = MTRDoorLockDaysMaskMap(rawValue: 8)
    public static let thursday = MTRDoorLockDaysMaskMap(rawValue: 16)
    public static let friday = MTRDoorLockDaysMaskMap(rawValue: 32)
    public static let saturday = MTRDoorLockDaysMaskMap(rawValue: 64)
}

public struct MTRDoorLockDlCredentialRuleMask: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let single = MTRDoorLockDlCredentialRuleMask(rawValue: 1)
    public static let dual = MTRDoorLockDlCredentialRuleMask(rawValue: 2)
    public static let tri = MTRDoorLockDlCredentialRuleMask(rawValue: 4)
}

public struct MTRDoorLockDlCredentialRulesSupport: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let single = MTRDoorLockDlCredentialRulesSupport(rawValue: 1)
    public static let dual = MTRDoorLockDlCredentialRulesSupport(rawValue: 2)
    public static let tri = MTRDoorLockDlCredentialRulesSupport(rawValue: 4)
}

public struct MTRDoorLockDlDaysMaskMap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let sunday = MTRDoorLockDlDaysMaskMap(rawValue: 1)
    public static let monday = MTRDoorLockDlDaysMaskMap(rawValue: 2)
    public static let tuesday = MTRDoorLockDlDaysMaskMap(rawValue: 4)
    public static let wednesday = MTRDoorLockDlDaysMaskMap(rawValue: 8)
    public static let thursday = MTRDoorLockDlDaysMaskMap(rawValue: 16)
    public static let friday = MTRDoorLockDlDaysMaskMap(rawValue: 32)
    public static let saturday = MTRDoorLockDlDaysMaskMap(rawValue: 64)
}

public struct MTRDoorLockDlDefaultConfigurationRegister: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let enableLocalProgrammingEnabled = MTRDoorLockDlDefaultConfigurationRegister(rawValue: 1)
    public static let keypadInterfaceDefaultAccessEnabled = MTRDoorLockDlDefaultConfigurationRegister(rawValue: 2)
    public static let remoteInterfaceDefaultAccessIsEnabled = MTRDoorLockDlDefaultConfigurationRegister(rawValue: 4)
    public static let soundEnabled = MTRDoorLockDlDefaultConfigurationRegister(rawValue: 8)
    public static let autoRelockTimeSet = MTRDoorLockDlDefaultConfigurationRegister(rawValue: 16)
    public static let ledSettingsSet = MTRDoorLockDlDefaultConfigurationRegister(rawValue: 32)
}

public struct MTRDoorLockDlKeypadOperationEventMask: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let unknown: MTRDoorLockDlKeypadOperationEventMask = []
    public static let lock = MTRDoorLockDlKeypadOperationEventMask(rawValue: 1)
    public static let unlock = MTRDoorLockDlKeypadOperationEventMask(rawValue: 2)
    public static let lockInvalidPIN = MTRDoorLockDlKeypadOperationEventMask(rawValue: 4)
    public static let lockInvalidSchedule = MTRDoorLockDlKeypadOperationEventMask(rawValue: 8)
    public static let unlockInvalidCode = MTRDoorLockDlKeypadOperationEventMask(rawValue: 16)
    public static let unlockInvalidSchedule = MTRDoorLockDlKeypadOperationEventMask(rawValue: 32)
    public static let nonAccessUserOpEvent = MTRDoorLockDlKeypadOperationEventMask(rawValue: 64)
}

public struct MTRDoorLockDlKeypadProgrammingEventMask: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let unknown: MTRDoorLockDlKeypadProgrammingEventMask = []
    public static let programmingPINChanged = MTRDoorLockDlKeypadProgrammingEventMask(rawValue: 1)
    public static let pinAdded = MTRDoorLockDlKeypadProgrammingEventMask(rawValue: 2)
    public static let pinCleared = MTRDoorLockDlKeypadProgrammingEventMask(rawValue: 4)
    public static let pinChanged = MTRDoorLockDlKeypadProgrammingEventMask(rawValue: 8)
}

public struct MTRDoorLockDlLocalProgrammingFeatures: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let addUsersCredentialsSchedulesLocally = MTRDoorLockDlLocalProgrammingFeatures(rawValue: 1)
    public static let modifyUsersCredentialsSchedulesLocally = MTRDoorLockDlLocalProgrammingFeatures(rawValue: 2)
    public static let clearUsersCredentialsSchedulesLocally = MTRDoorLockDlLocalProgrammingFeatures(rawValue: 4)
    public static let adjustLockSettingsLocally = MTRDoorLockDlLocalProgrammingFeatures(rawValue: 8)
}

public struct MTRDoorLockDlManualOperationEventMask: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let unknown: MTRDoorLockDlManualOperationEventMask = []
    public static let thumbturnLock = MTRDoorLockDlManualOperationEventMask(rawValue: 1)
    public static let thumbturnUnlock = MTRDoorLockDlManualOperationEventMask(rawValue: 2)
    public static let oneTouchLock = MTRDoorLockDlManualOperationEventMask(rawValue: 4)
    public static let keyLock = MTRDoorLockDlManualOperationEventMask(rawValue: 8)
    public static let keyUnlock = MTRDoorLockDlManualOperationEventMask(rawValue: 16)
    public static let autoLock = MTRDoorLockDlManualOperationEventMask(rawValue: 32)
    public static let scheduleLock = MTRDoorLockDlManualOperationEventMask(rawValue: 64)
    public static let scheduleUnlock = MTRDoorLockDlManualOperationEventMask(rawValue: 128)
    public static let manualLock = MTRDoorLockDlManualOperationEventMask(rawValue: 256)
    public static let manualUnlock = MTRDoorLockDlManualOperationEventMask(rawValue: 512)
}

public struct MTRDoorLockDlRFIDOperationEventMask: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let unknown: MTRDoorLockDlRFIDOperationEventMask = []
    public static let lock = MTRDoorLockDlRFIDOperationEventMask(rawValue: 1)
    public static let unlock = MTRDoorLockDlRFIDOperationEventMask(rawValue: 2)
    public static let lockInvalidRFID = MTRDoorLockDlRFIDOperationEventMask(rawValue: 4)
    public static let lockInvalidSchedule = MTRDoorLockDlRFIDOperationEventMask(rawValue: 8)
    public static let unlockInvalidRFID = MTRDoorLockDlRFIDOperationEventMask(rawValue: 16)
    public static let unlockInvalidSchedule = MTRDoorLockDlRFIDOperationEventMask(rawValue: 32)
}

public struct MTRDoorLockDlRFIDProgrammingEventMask: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let unknown: MTRDoorLockDlRFIDProgrammingEventMask = []
    public static let rfidCodeAdded = MTRDoorLockDlRFIDProgrammingEventMask(rawValue: 1)
    public static let rfidCodeCleared = MTRDoorLockDlRFIDProgrammingEventMask(rawValue: 2)
}

public struct MTRDoorLockDlRemoteOperationEventMask: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let unknown: MTRDoorLockDlRemoteOperationEventMask = []
    public static let lock = MTRDoorLockDlRemoteOperationEventMask(rawValue: 1)
    public static let unlock = MTRDoorLockDlRemoteOperationEventMask(rawValue: 2)
    public static let lockInvalidCode = MTRDoorLockDlRemoteOperationEventMask(rawValue: 4)
    public static let lockInvalidSchedule = MTRDoorLockDlRemoteOperationEventMask(rawValue: 8)
    public static let unlockInvalidCode = MTRDoorLockDlRemoteOperationEventMask(rawValue: 16)
    public static let unlockInvalidSchedule = MTRDoorLockDlRemoteOperationEventMask(rawValue: 32)
}

public struct MTRDoorLockDlRemoteProgrammingEventMask: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let unknown: MTRDoorLockDlRemoteProgrammingEventMask = []
    public static let programmingPINChanged = MTRDoorLockDlRemoteProgrammingEventMask(rawValue: 1)
    public static let pinAdded = MTRDoorLockDlRemoteProgrammingEventMask(rawValue: 2)
    public static let pinCleared = MTRDoorLockDlRemoteProgrammingEventMask(rawValue: 4)
    public static let pinChanged = MTRDoorLockDlRemoteProgrammingEventMask(rawValue: 8)
    public static let rfidCodeAdded = MTRDoorLockDlRemoteProgrammingEventMask(rawValue: 16)
    public static let rfidCodeCleared = MTRDoorLockDlRemoteProgrammingEventMask(rawValue: 32)
}

public struct MTRDoorLockDlSupportedOperatingModes: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let normal = MTRDoorLockDlSupportedOperatingModes(rawValue: 1)
    public static let vacation = MTRDoorLockDlSupportedOperatingModes(rawValue: 2)
    public static let privacy = MTRDoorLockDlSupportedOperatingModes(rawValue: 4)
    public static let noRemoteLockUnlock = MTRDoorLockDlSupportedOperatingModes(rawValue: 8)
    public static let passage = MTRDoorLockDlSupportedOperatingModes(rawValue: 16)
}

public struct MTRDoorLockFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let pinCredential = MTRDoorLockFeature(rawValue: 1)
    public static let pinCredentials = MTRDoorLockFeature(rawValue: 2)
    public static let rfidCredential = MTRDoorLockFeature(rawValue: 4)
    public static let rfidCredentials = MTRDoorLockFeature(rawValue: 8)
    public static let fingerCredentials = MTRDoorLockFeature(rawValue: 16)
    public static let logging = MTRDoorLockFeature(rawValue: 32)
    public static let weekDayAccessSchedules = MTRDoorLockFeature(rawValue: 64)
    public static let weekDaySchedules = MTRDoorLockFeature(rawValue: 128)
    public static let doorPositionSensor = MTRDoorLockFeature(rawValue: 256)
    public static let faceCredentials = MTRDoorLockFeature(rawValue: 512)
    public static let credentialsOverTheAirAccess = MTRDoorLockFeature(rawValue: 1024)
    public static let credentialsOTA = MTRDoorLockFeature(rawValue: 2048)
    public static let user = MTRDoorLockFeature(rawValue: 4096)
    public static let usersManagement = MTRDoorLockFeature(rawValue: 8192)
    public static let notification = MTRDoorLockFeature(rawValue: 16384)
    public static let notifications = MTRDoorLockFeature(rawValue: 32768)
    public static let yearDayAccessSchedules = MTRDoorLockFeature(rawValue: 65536)
    public static let yearDaySchedules = MTRDoorLockFeature(rawValue: 131072)
    public static let holidaySchedules = MTRDoorLockFeature(rawValue: 262144)
    public static let unbolt = MTRDoorLockFeature(rawValue: 524288)
    public static let aliroProvisioning = MTRDoorLockFeature(rawValue: 1048576)
    public static let aliroBLEUWB = MTRDoorLockFeature(rawValue: 2097152)
}

public struct MTRElectricalEnergyMeasurementFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let importedEnergy = MTRElectricalEnergyMeasurementFeature(rawValue: 1)
    public static let exportedEnergy = MTRElectricalEnergyMeasurementFeature(rawValue: 2)
    public static let cumulativeEnergy = MTRElectricalEnergyMeasurementFeature(rawValue: 4)
    public static let periodicEnergy = MTRElectricalEnergyMeasurementFeature(rawValue: 8)
}

public struct MTRElectricalPowerMeasurementFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let directCurrent = MTRElectricalPowerMeasurementFeature(rawValue: 1)
    public static let alternatingCurrent = MTRElectricalPowerMeasurementFeature(rawValue: 2)
    public static let polyphasePower = MTRElectricalPowerMeasurementFeature(rawValue: 4)
    public static let harmonics = MTRElectricalPowerMeasurementFeature(rawValue: 8)
    public static let powerQuality = MTRElectricalPowerMeasurementFeature(rawValue: 16)
}

public struct MTREnergyEVSEFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let chargingPreferences = MTREnergyEVSEFeature(rawValue: 1)
    public static let RFID = MTREnergyEVSEFeature(rawValue: 2)
}

public struct MTREnergyEVSETargetDayOfWeekBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let sunday = MTREnergyEVSETargetDayOfWeekBitmap(rawValue: 1)
    public static let monday = MTREnergyEVSETargetDayOfWeekBitmap(rawValue: 2)
    public static let tuesday = MTREnergyEVSETargetDayOfWeekBitmap(rawValue: 4)
    public static let wednesday = MTREnergyEVSETargetDayOfWeekBitmap(rawValue: 8)
    public static let thursday = MTREnergyEVSETargetDayOfWeekBitmap(rawValue: 16)
    public static let friday = MTREnergyEVSETargetDayOfWeekBitmap(rawValue: 32)
    public static let saturday = MTREnergyEVSETargetDayOfWeekBitmap(rawValue: 64)
}

public struct MTREthernetNetworkDiagnosticsFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let packetCounts = MTREthernetNetworkDiagnosticsFeature(rawValue: 1)
    public static let errorCounts = MTREthernetNetworkDiagnosticsFeature(rawValue: 2)
}

public struct MTRFanControlFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let multiSpeed = MTRFanControlFeature(rawValue: 1)
    public static let auto = MTRFanControlFeature(rawValue: 2)
    public static let rocking = MTRFanControlFeature(rawValue: 4)
    public static let wind = MTRFanControlFeature(rawValue: 8)
    public static let step = MTRFanControlFeature(rawValue: 16)
    public static let airflowDirection = MTRFanControlFeature(rawValue: 32)
}

public struct MTRFanControlRockBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let rockLeftRight = MTRFanControlRockBitmap(rawValue: 1)
    public static let rockUpDown = MTRFanControlRockBitmap(rawValue: 2)
    public static let rockRound = MTRFanControlRockBitmap(rawValue: 4)
}

public struct MTRFanControlRockSupportMask: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let rockLeftRight = MTRFanControlRockSupportMask(rawValue: 1)
    public static let rockUpDown = MTRFanControlRockSupportMask(rawValue: 2)
    public static let rockRound = MTRFanControlRockSupportMask(rawValue: 4)
}

public struct MTRFanControlWindBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let sleepWind = MTRFanControlWindBitmap(rawValue: 1)
    public static let naturalWind = MTRFanControlWindBitmap(rawValue: 2)
}

public struct MTRFanControlWindSettingMask: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let sleepWind = MTRFanControlWindSettingMask(rawValue: 1)
    public static let naturalWind = MTRFanControlWindSettingMask(rawValue: 2)
}

public struct MTRFanControlWindSupportMask: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let sleepWind = MTRFanControlWindSupportMask(rawValue: 1)
    public static let naturalWind = MTRFanControlWindSupportMask(rawValue: 2)
}

public struct MTRFormaldehydeConcentrationMeasurementFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let numericMeasurement = MTRFormaldehydeConcentrationMeasurementFeature(rawValue: 1)
    public static let levelIndication = MTRFormaldehydeConcentrationMeasurementFeature(rawValue: 2)
    public static let mediumLevel = MTRFormaldehydeConcentrationMeasurementFeature(rawValue: 4)
    public static let criticalLevel = MTRFormaldehydeConcentrationMeasurementFeature(rawValue: 8)
    public static let peakMeasurement = MTRFormaldehydeConcentrationMeasurementFeature(rawValue: 16)
    public static let averageMeasurement = MTRFormaldehydeConcentrationMeasurementFeature(rawValue: 32)
}

public struct MTRGeneralDiagnosticsFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let dataModelTest = MTRGeneralDiagnosticsFeature(rawValue: 1)
}

public struct MTRGroupsFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let groupNames = MTRGroupsFeature(rawValue: 1)
}

public struct MTRGroupsGroupClusterFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let groupNames = MTRGroupsGroupClusterFeature(rawValue: 1)
}

public struct MTRGroupsNameSupportBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let groupNames = MTRGroupsNameSupportBitmap(rawValue: 1)
}

public struct MTRHEPAFilterMonitoringFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let condition = MTRHEPAFilterMonitoringFeature(rawValue: 1)
    public static let warning = MTRHEPAFilterMonitoringFeature(rawValue: 2)
    public static let replacementProductList = MTRHEPAFilterMonitoringFeature(rawValue: 4)
}

public struct MTRICDManagementFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let checkInProtocolSupport = MTRICDManagementFeature(rawValue: 1)
    public static let userActiveModeTrigger = MTRICDManagementFeature(rawValue: 2)
    public static let longIdleTimeSupport = MTRICDManagementFeature(rawValue: 4)
    public static let dynamicSitLitSupport = MTRICDManagementFeature(rawValue: 8)
}

public struct MTRICDManagementUserActiveModeTriggerBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let powerCycle = MTRICDManagementUserActiveModeTriggerBitmap(rawValue: 1)
    public static let settingsMenu = MTRICDManagementUserActiveModeTriggerBitmap(rawValue: 2)
    public static let customInstruction = MTRICDManagementUserActiveModeTriggerBitmap(rawValue: 4)
    public static let deviceManual = MTRICDManagementUserActiveModeTriggerBitmap(rawValue: 8)
    public static let actuateSensor = MTRICDManagementUserActiveModeTriggerBitmap(rawValue: 16)
    public static let actuateSensorSeconds = MTRICDManagementUserActiveModeTriggerBitmap(rawValue: 32)
    public static let actuateSensorTimes = MTRICDManagementUserActiveModeTriggerBitmap(rawValue: 64)
    public static let actuateSensorLightsBlink = MTRICDManagementUserActiveModeTriggerBitmap(rawValue: 128)
    public static let resetButton = MTRICDManagementUserActiveModeTriggerBitmap(rawValue: 256)
    public static let resetButtonLightsBlink = MTRICDManagementUserActiveModeTriggerBitmap(rawValue: 512)
    public static let resetButtonSeconds = MTRICDManagementUserActiveModeTriggerBitmap(rawValue: 1024)
    public static let resetButtonTimes = MTRICDManagementUserActiveModeTriggerBitmap(rawValue: 2048)
    public static let setupButton = MTRICDManagementUserActiveModeTriggerBitmap(rawValue: 4096)
    public static let setupButtonSeconds = MTRICDManagementUserActiveModeTriggerBitmap(rawValue: 8192)
    public static let setupButtonLightsBlink = MTRICDManagementUserActiveModeTriggerBitmap(rawValue: 16384)
    public static let setupButtonTimes = MTRICDManagementUserActiveModeTriggerBitmap(rawValue: 32768)
    public static let appDefinedButton = MTRICDManagementUserActiveModeTriggerBitmap(rawValue: 65536)
}

public struct MTRKeypadInputFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let navigationKeyCodes = MTRKeypadInputFeature(rawValue: 1)
    public static let locationKeys = MTRKeypadInputFeature(rawValue: 2)
    public static let numberKeys = MTRKeypadInputFeature(rawValue: 4)
}

public struct MTRLaundryWasherControlsFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let spin = MTRLaundryWasherControlsFeature(rawValue: 1)
    public static let rinse = MTRLaundryWasherControlsFeature(rawValue: 2)
}

public struct MTRLevelControlFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let onOff = MTRLevelControlFeature(rawValue: 1)
    public static let lighting = MTRLevelControlFeature(rawValue: 2)
    public static let frequency = MTRLevelControlFeature(rawValue: 4)
}

public struct MTRLevelControlOptions: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let executeIfOff = MTRLevelControlOptions(rawValue: 1)
    public static let coupleColorTempToLevel = MTRLevelControlOptions(rawValue: 2)
}

public struct MTRLevelControlOptionsBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let executeIfOff = MTRLevelControlOptionsBitmap(rawValue: 1)
    public static let coupleColorTempToLevel = MTRLevelControlOptionsBitmap(rawValue: 2)
}

public struct MTRMediaInputFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let nameUpdates = MTRMediaInputFeature(rawValue: 1)
}

public struct MTRMediaPlaybackFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let advancedSeek = MTRMediaPlaybackFeature(rawValue: 1)
    public static let variableSpeed = MTRMediaPlaybackFeature(rawValue: 2)
    public static let textTracks = MTRMediaPlaybackFeature(rawValue: 4)
    public static let audioTracks = MTRMediaPlaybackFeature(rawValue: 8)
    public static let audioAdvance = MTRMediaPlaybackFeature(rawValue: 16)
}

public struct MTRMessagesFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let receivedConfirmation = MTRMessagesFeature(rawValue: 1)
    public static let confirmationResponse = MTRMessagesFeature(rawValue: 2)
    public static let confirmationReply = MTRMessagesFeature(rawValue: 4)
    public static let protectedMessages = MTRMessagesFeature(rawValue: 8)
}

public struct MTRMessagesMessageControlBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let confirmationRequired = MTRMessagesMessageControlBitmap(rawValue: 1)
    public static let responseRequired = MTRMessagesMessageControlBitmap(rawValue: 2)
    public static let replyMessage = MTRMessagesMessageControlBitmap(rawValue: 4)
    public static let messageConfirmed = MTRMessagesMessageControlBitmap(rawValue: 8)
    public static let messageProtected = MTRMessagesMessageControlBitmap(rawValue: 16)
}

public struct MTRMicrowaveOvenControlFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let powerAsNumber = MTRMicrowaveOvenControlFeature(rawValue: 1)
    public static let powerNumberLimits = MTRMicrowaveOvenControlFeature(rawValue: 2)
}

public struct MTRModeSelectFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let onOff = MTRModeSelectFeature(rawValue: 1)
    public static let DEPONOFF = MTRModeSelectFeature(rawValue: 2)
}

public struct MTRNetworkCommissioningFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let wiFiNetworkInterface = MTRNetworkCommissioningFeature(rawValue: 1)
    public static let threadNetworkInterface = MTRNetworkCommissioningFeature(rawValue: 2)
    public static let ethernetNetworkInterface = MTRNetworkCommissioningFeature(rawValue: 4)
}

public struct MTRNetworkCommissioningThreadCapabilitiesBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let isBorderRouterCapable = MTRNetworkCommissioningThreadCapabilitiesBitmap(rawValue: 1)
    public static let isRouterCapable = MTRNetworkCommissioningThreadCapabilitiesBitmap(rawValue: 2)
    public static let isSleepyEndDeviceCapable = MTRNetworkCommissioningThreadCapabilitiesBitmap(rawValue: 4)
    public static let isFullThreadDevice = MTRNetworkCommissioningThreadCapabilitiesBitmap(rawValue: 8)
    public static let isSynchronizedSleepyEndDeviceCapable = MTRNetworkCommissioningThreadCapabilitiesBitmap(rawValue: 16)
}

public struct MTRNetworkCommissioningWiFiSecurity: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let unencrypted = MTRNetworkCommissioningWiFiSecurity(rawValue: 1)
    public static let WEP = MTRNetworkCommissioningWiFiSecurity(rawValue: 2)
    public static let wepPersonal = MTRNetworkCommissioningWiFiSecurity(rawValue: 4)
    public static let wpaPersonal = MTRNetworkCommissioningWiFiSecurity(rawValue: 8)
    public static let wpa2Personal = MTRNetworkCommissioningWiFiSecurity(rawValue: 16)
    public static let wpa3Personal = MTRNetworkCommissioningWiFiSecurity(rawValue: 32)
}

public struct MTRNetworkCommissioningWiFiSecurityBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let unencrypted = MTRNetworkCommissioningWiFiSecurityBitmap(rawValue: 1)
    public static let WEP = MTRNetworkCommissioningWiFiSecurityBitmap(rawValue: 2)
    public static let wpaPersonal = MTRNetworkCommissioningWiFiSecurityBitmap(rawValue: 4)
    public static let wpa2Personal = MTRNetworkCommissioningWiFiSecurityBitmap(rawValue: 8)
    public static let wpa3Personal = MTRNetworkCommissioningWiFiSecurityBitmap(rawValue: 16)
}

public struct MTRNitrogenDioxideConcentrationMeasurementFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let numericMeasurement = MTRNitrogenDioxideConcentrationMeasurementFeature(rawValue: 1)
    public static let levelIndication = MTRNitrogenDioxideConcentrationMeasurementFeature(rawValue: 2)
    public static let mediumLevel = MTRNitrogenDioxideConcentrationMeasurementFeature(rawValue: 4)
    public static let criticalLevel = MTRNitrogenDioxideConcentrationMeasurementFeature(rawValue: 8)
    public static let peakMeasurement = MTRNitrogenDioxideConcentrationMeasurementFeature(rawValue: 16)
    public static let averageMeasurement = MTRNitrogenDioxideConcentrationMeasurementFeature(rawValue: 32)
}

public struct MTROccupancySensingFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let other = MTROccupancySensingFeature(rawValue: 1)
    public static let passiveInfrared = MTROccupancySensingFeature(rawValue: 2)
    public static let ultrasonic = MTROccupancySensingFeature(rawValue: 4)
    public static let physicalContact = MTROccupancySensingFeature(rawValue: 8)
    public static let activeInfrared = MTROccupancySensingFeature(rawValue: 16)
    public static let radar = MTROccupancySensingFeature(rawValue: 32)
    public static let rfSensing = MTROccupancySensingFeature(rawValue: 64)
    public static let vision = MTROccupancySensingFeature(rawValue: 128)
}

public struct MTROccupancySensingOccupancyBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let occupied = MTROccupancySensingOccupancyBitmap(rawValue: 1)
}

public struct MTROccupancySensingOccupancySensorTypeBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let PIR = MTROccupancySensingOccupancySensorTypeBitmap(rawValue: 1)
    public static let ultrasonic = MTROccupancySensingOccupancySensorTypeBitmap(rawValue: 2)
    public static let physicalContact = MTROccupancySensingOccupancySensorTypeBitmap(rawValue: 4)
}

public struct MTROnOffControl: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let acceptOnlyWhenOn = MTROnOffControl(rawValue: 1)
}

public struct MTROnOffControlBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let acceptOnlyWhenOn = MTROnOffControlBitmap(rawValue: 1)
}

public struct MTROnOffFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let lighting = MTROnOffFeature(rawValue: 1)
    public static let deadFrontBehavior = MTROnOffFeature(rawValue: 2)
    public static let deadFront = MTROnOffFeature(rawValue: 4)
    public static let offOnly = MTROnOffFeature(rawValue: 8)
}

public struct MTROzoneConcentrationMeasurementFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let numericMeasurement = MTROzoneConcentrationMeasurementFeature(rawValue: 1)
    public static let levelIndication = MTROzoneConcentrationMeasurementFeature(rawValue: 2)
    public static let mediumLevel = MTROzoneConcentrationMeasurementFeature(rawValue: 4)
    public static let criticalLevel = MTROzoneConcentrationMeasurementFeature(rawValue: 8)
    public static let peakMeasurement = MTROzoneConcentrationMeasurementFeature(rawValue: 16)
    public static let averageMeasurement = MTROzoneConcentrationMeasurementFeature(rawValue: 32)
}

public struct MTRPM10ConcentrationMeasurementFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let numericMeasurement = MTRPM10ConcentrationMeasurementFeature(rawValue: 1)
    public static let levelIndication = MTRPM10ConcentrationMeasurementFeature(rawValue: 2)
    public static let mediumLevel = MTRPM10ConcentrationMeasurementFeature(rawValue: 4)
    public static let criticalLevel = MTRPM10ConcentrationMeasurementFeature(rawValue: 8)
    public static let peakMeasurement = MTRPM10ConcentrationMeasurementFeature(rawValue: 16)
    public static let averageMeasurement = MTRPM10ConcentrationMeasurementFeature(rawValue: 32)
}

public struct MTRPM1ConcentrationMeasurementFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let numericMeasurement = MTRPM1ConcentrationMeasurementFeature(rawValue: 1)
    public static let levelIndication = MTRPM1ConcentrationMeasurementFeature(rawValue: 2)
    public static let mediumLevel = MTRPM1ConcentrationMeasurementFeature(rawValue: 4)
    public static let criticalLevel = MTRPM1ConcentrationMeasurementFeature(rawValue: 8)
    public static let peakMeasurement = MTRPM1ConcentrationMeasurementFeature(rawValue: 16)
    public static let averageMeasurement = MTRPM1ConcentrationMeasurementFeature(rawValue: 32)
}

public struct MTRPM25ConcentrationMeasurementFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let numericMeasurement = MTRPM25ConcentrationMeasurementFeature(rawValue: 1)
    public static let levelIndication = MTRPM25ConcentrationMeasurementFeature(rawValue: 2)
    public static let mediumLevel = MTRPM25ConcentrationMeasurementFeature(rawValue: 4)
    public static let criticalLevel = MTRPM25ConcentrationMeasurementFeature(rawValue: 8)
    public static let peakMeasurement = MTRPM25ConcentrationMeasurementFeature(rawValue: 16)
    public static let averageMeasurement = MTRPM25ConcentrationMeasurementFeature(rawValue: 32)
}

public struct MTRPowerSourceFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let wired = MTRPowerSourceFeature(rawValue: 1)
    public static let battery = MTRPowerSourceFeature(rawValue: 2)
    public static let rechargeable = MTRPowerSourceFeature(rawValue: 4)
    public static let replaceable = MTRPowerSourceFeature(rawValue: 8)
}

public struct MTRPowerTopologyFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let nodeTopology = MTRPowerTopologyFeature(rawValue: 1)
    public static let treeTopology = MTRPowerTopologyFeature(rawValue: 2)
    public static let setTopology = MTRPowerTopologyFeature(rawValue: 4)
    public static let dynamicPowerFlow = MTRPowerTopologyFeature(rawValue: 8)
}

public struct MTRPressureMeasurementFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let extended = MTRPressureMeasurementFeature(rawValue: 1)
}

public struct MTRPressureMeasurementPressureFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let extended = MTRPressureMeasurementPressureFeature(rawValue: 1)
    public static let EXT = MTRPressureMeasurementPressureFeature(rawValue: 2)
}

public struct MTRPumpConfigurationAndControlFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let constantPressure = MTRPumpConfigurationAndControlFeature(rawValue: 1)
    public static let compensatedPressure = MTRPumpConfigurationAndControlFeature(rawValue: 2)
    public static let constantFlow = MTRPumpConfigurationAndControlFeature(rawValue: 4)
    public static let constantSpeed = MTRPumpConfigurationAndControlFeature(rawValue: 8)
    public static let constantTemperature = MTRPumpConfigurationAndControlFeature(rawValue: 16)
    public static let automatic = MTRPumpConfigurationAndControlFeature(rawValue: 32)
    public static let localOperation = MTRPumpConfigurationAndControlFeature(rawValue: 64)
}

public struct MTRPumpConfigurationAndControlPumpFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let constantPressure = MTRPumpConfigurationAndControlPumpFeature(rawValue: 1)
    public static let compensatedPressure = MTRPumpConfigurationAndControlPumpFeature(rawValue: 2)
    public static let constantFlow = MTRPumpConfigurationAndControlPumpFeature(rawValue: 4)
    public static let constantSpeed = MTRPumpConfigurationAndControlPumpFeature(rawValue: 8)
    public static let constantTemperature = MTRPumpConfigurationAndControlPumpFeature(rawValue: 16)
    public static let automatic = MTRPumpConfigurationAndControlPumpFeature(rawValue: 32)
    public static let localOperation = MTRPumpConfigurationAndControlPumpFeature(rawValue: 64)
    public static let local = MTRPumpConfigurationAndControlPumpFeature(rawValue: 128)
}

public struct MTRPumpConfigurationAndControlPumpStatus: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let deviceFault = MTRPumpConfigurationAndControlPumpStatus(rawValue: 1)
    public static let supplyfault = MTRPumpConfigurationAndControlPumpStatus(rawValue: 2)
    public static let speedLow = MTRPumpConfigurationAndControlPumpStatus(rawValue: 4)
    public static let speedHigh = MTRPumpConfigurationAndControlPumpStatus(rawValue: 8)
    public static let localOverride = MTRPumpConfigurationAndControlPumpStatus(rawValue: 16)
    public static let running = MTRPumpConfigurationAndControlPumpStatus(rawValue: 32)
    public static let remotePressure = MTRPumpConfigurationAndControlPumpStatus(rawValue: 64)
    public static let remoteFlow = MTRPumpConfigurationAndControlPumpStatus(rawValue: 128)
    public static let remoteTemperature = MTRPumpConfigurationAndControlPumpStatus(rawValue: 256)
}

public struct MTRPumpConfigurationAndControlPumpStatusBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let deviceFault = MTRPumpConfigurationAndControlPumpStatusBitmap(rawValue: 1)
    public static let supplyFault = MTRPumpConfigurationAndControlPumpStatusBitmap(rawValue: 2)
    public static let supplyfault = MTRPumpConfigurationAndControlPumpStatusBitmap(rawValue: 4)
    public static let speedLow = MTRPumpConfigurationAndControlPumpStatusBitmap(rawValue: 8)
    public static let speedHigh = MTRPumpConfigurationAndControlPumpStatusBitmap(rawValue: 16)
    public static let localOverride = MTRPumpConfigurationAndControlPumpStatusBitmap(rawValue: 32)
    public static let running = MTRPumpConfigurationAndControlPumpStatusBitmap(rawValue: 64)
    public static let remotePressure = MTRPumpConfigurationAndControlPumpStatusBitmap(rawValue: 128)
    public static let remoteFlow = MTRPumpConfigurationAndControlPumpStatusBitmap(rawValue: 256)
    public static let remoteTemperature = MTRPumpConfigurationAndControlPumpStatusBitmap(rawValue: 512)
}

public struct MTRRVCCleanModeFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
}

public struct MTRRVCRunModeFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
}

public struct MTRRadonConcentrationMeasurementFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let numericMeasurement = MTRRadonConcentrationMeasurementFeature(rawValue: 1)
    public static let levelIndication = MTRRadonConcentrationMeasurementFeature(rawValue: 2)
    public static let mediumLevel = MTRRadonConcentrationMeasurementFeature(rawValue: 4)
    public static let criticalLevel = MTRRadonConcentrationMeasurementFeature(rawValue: 8)
    public static let peakMeasurement = MTRRadonConcentrationMeasurementFeature(rawValue: 16)
    public static let averageMeasurement = MTRRadonConcentrationMeasurementFeature(rawValue: 32)
}

public struct MTRRefrigeratorAlarmAlarmBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let doorOpen = MTRRefrigeratorAlarmAlarmBitmap(rawValue: 1)
}

public struct MTRServiceAreaFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let selectWhileRunning = MTRServiceAreaFeature(rawValue: 1)
    public static let progressReporting = MTRServiceAreaFeature(rawValue: 2)
    public static let maps = MTRServiceAreaFeature(rawValue: 4)
}

public struct MTRSmokeCOAlarmFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let smokeAlarm = MTRSmokeCOAlarmFeature(rawValue: 1)
    public static let coAlarm = MTRSmokeCOAlarmFeature(rawValue: 2)
}

public struct MTRSoftwareDiagnosticsFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let watermarks = MTRSoftwareDiagnosticsFeature(rawValue: 1)
    public static let waterMarks = MTRSoftwareDiagnosticsFeature(rawValue: 2)
}

public struct MTRSwitchFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let latchingSwitch = MTRSwitchFeature(rawValue: 1)
    public static let momentarySwitch = MTRSwitchFeature(rawValue: 2)
    public static let momentarySwitchRelease = MTRSwitchFeature(rawValue: 4)
    public static let momentarySwitchLongPress = MTRSwitchFeature(rawValue: 8)
    public static let momentarySwitchMultiPress = MTRSwitchFeature(rawValue: 16)
    public static let actionSwitch = MTRSwitchFeature(rawValue: 32)
}

public struct MTRTemperatureControlFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let temperatureNumber = MTRTemperatureControlFeature(rawValue: 1)
    public static let temperatureLevel = MTRTemperatureControlFeature(rawValue: 2)
    public static let temperatureStep = MTRTemperatureControlFeature(rawValue: 4)
}

public struct MTRTestClusterBitmap16MaskMap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let maskVal1 = MTRTestClusterBitmap16MaskMap(rawValue: 1)
    public static let maskVal2 = MTRTestClusterBitmap16MaskMap(rawValue: 2)
    public static let maskVal3 = MTRTestClusterBitmap16MaskMap(rawValue: 4)
    public static let maskVal4 = MTRTestClusterBitmap16MaskMap(rawValue: 8)
}

public struct MTRTestClusterBitmap32MaskMap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let maskVal1 = MTRTestClusterBitmap32MaskMap(rawValue: 1)
    public static let maskVal2 = MTRTestClusterBitmap32MaskMap(rawValue: 2)
    public static let maskVal3 = MTRTestClusterBitmap32MaskMap(rawValue: 4)
    public static let maskVal4 = MTRTestClusterBitmap32MaskMap(rawValue: 8)
}

public struct MTRTestClusterBitmap64MaskMap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt64
    public init(rawValue: UInt64) { self.rawValue = rawValue }
    public static let maskVal1 = MTRTestClusterBitmap64MaskMap(rawValue: 1)
    public static let maskVal2 = MTRTestClusterBitmap64MaskMap(rawValue: 2)
    public static let maskVal3 = MTRTestClusterBitmap64MaskMap(rawValue: 4)
    public static let maskVal4 = MTRTestClusterBitmap64MaskMap(rawValue: 8)
}

public struct MTRTestClusterBitmap8MaskMap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let maskVal1 = MTRTestClusterBitmap8MaskMap(rawValue: 1)
    public static let maskVal2 = MTRTestClusterBitmap8MaskMap(rawValue: 2)
    public static let maskVal3 = MTRTestClusterBitmap8MaskMap(rawValue: 4)
    public static let maskVal4 = MTRTestClusterBitmap8MaskMap(rawValue: 8)
}

public struct MTRTestClusterSimpleBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let valueA = MTRTestClusterSimpleBitmap(rawValue: 1)
    public static let valueB = MTRTestClusterSimpleBitmap(rawValue: 2)
    public static let valueC = MTRTestClusterSimpleBitmap(rawValue: 4)
}

public struct MTRThermostatACErrorCodeBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let compressorFail = MTRThermostatACErrorCodeBitmap(rawValue: 1)
    public static let roomSensorFail = MTRThermostatACErrorCodeBitmap(rawValue: 2)
    public static let outdoorSensorFail = MTRThermostatACErrorCodeBitmap(rawValue: 4)
    public static let coilSensorFail = MTRThermostatACErrorCodeBitmap(rawValue: 8)
    public static let fanFail = MTRThermostatACErrorCodeBitmap(rawValue: 16)
}

public struct MTRThermostatDayOfWeek: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let sunday = MTRThermostatDayOfWeek(rawValue: 1)
    public static let monday = MTRThermostatDayOfWeek(rawValue: 2)
    public static let tuesday = MTRThermostatDayOfWeek(rawValue: 4)
    public static let wednesday = MTRThermostatDayOfWeek(rawValue: 8)
    public static let thursday = MTRThermostatDayOfWeek(rawValue: 16)
    public static let friday = MTRThermostatDayOfWeek(rawValue: 32)
    public static let saturday = MTRThermostatDayOfWeek(rawValue: 64)
    public static let away = MTRThermostatDayOfWeek(rawValue: 128)
    public static let awayOrVacation = MTRThermostatDayOfWeek(rawValue: 128)
}

public struct MTRThermostatFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let heating = MTRThermostatFeature(rawValue: 1)
    public static let cooling = MTRThermostatFeature(rawValue: 2)
    public static let occupancy = MTRThermostatFeature(rawValue: 4)
    public static let scheduleConfiguration = MTRThermostatFeature(rawValue: 8)
    public static let schedule = MTRThermostatFeature(rawValue: 16)
    public static let setback = MTRThermostatFeature(rawValue: 32)
    public static let autoMode = MTRThermostatFeature(rawValue: 64)
    public static let automode = MTRThermostatFeature(rawValue: 128)
    public static let localTemperatureNotExposed = MTRThermostatFeature(rawValue: 256)
    public static let matterScheduleConfiguration = MTRThermostatFeature(rawValue: 512)
    public static let presets = MTRThermostatFeature(rawValue: 1024)
}

public struct MTRThermostatHVACSystemTypeBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let coolingStage = MTRThermostatHVACSystemTypeBitmap(rawValue: 1)
    public static let heatingStage = MTRThermostatHVACSystemTypeBitmap(rawValue: 2)
    public static let heatingIsHeatPump = MTRThermostatHVACSystemTypeBitmap(rawValue: 4)
    public static let heatingUsesFuel = MTRThermostatHVACSystemTypeBitmap(rawValue: 8)
}

public struct MTRThermostatModeForSequence: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let heatSetpointPresent = MTRThermostatModeForSequence(rawValue: 1)
    public static let heatSetpointFieldPresent = MTRThermostatModeForSequence(rawValue: 2)
    public static let coolSetpointPresent = MTRThermostatModeForSequence(rawValue: 4)
    public static let coolSetpointFieldPresent = MTRThermostatModeForSequence(rawValue: 8)
}

public struct MTRThermostatOccupancyBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let occupied = MTRThermostatOccupancyBitmap(rawValue: 1)
}

public struct MTRThermostatPresetTypeFeaturesBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let automatic = MTRThermostatPresetTypeFeaturesBitmap(rawValue: 1)
    public static let supportsNames = MTRThermostatPresetTypeFeaturesBitmap(rawValue: 2)
}

public struct MTRThermostatProgrammingOperationModeBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let scheduleActive = MTRThermostatProgrammingOperationModeBitmap(rawValue: 1)
    public static let autoRecovery = MTRThermostatProgrammingOperationModeBitmap(rawValue: 2)
    public static let economy = MTRThermostatProgrammingOperationModeBitmap(rawValue: 4)
}

public struct MTRThermostatRelayStateBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let heat = MTRThermostatRelayStateBitmap(rawValue: 1)
    public static let cool = MTRThermostatRelayStateBitmap(rawValue: 2)
    public static let fan = MTRThermostatRelayStateBitmap(rawValue: 4)
    public static let heatStage2 = MTRThermostatRelayStateBitmap(rawValue: 8)
    public static let coolStage2 = MTRThermostatRelayStateBitmap(rawValue: 16)
    public static let fanStage2 = MTRThermostatRelayStateBitmap(rawValue: 32)
    public static let fanStage3 = MTRThermostatRelayStateBitmap(rawValue: 64)
}

public struct MTRThermostatRemoteSensingBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let localTemperature = MTRThermostatRemoteSensingBitmap(rawValue: 1)
    public static let outdoorTemperature = MTRThermostatRemoteSensingBitmap(rawValue: 2)
    public static let occupancy = MTRThermostatRemoteSensingBitmap(rawValue: 4)
}

public struct MTRThermostatScheduleDayOfWeekBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let sunday = MTRThermostatScheduleDayOfWeekBitmap(rawValue: 1)
    public static let monday = MTRThermostatScheduleDayOfWeekBitmap(rawValue: 2)
    public static let tuesday = MTRThermostatScheduleDayOfWeekBitmap(rawValue: 4)
    public static let wednesday = MTRThermostatScheduleDayOfWeekBitmap(rawValue: 8)
    public static let thursday = MTRThermostatScheduleDayOfWeekBitmap(rawValue: 16)
    public static let friday = MTRThermostatScheduleDayOfWeekBitmap(rawValue: 32)
    public static let saturday = MTRThermostatScheduleDayOfWeekBitmap(rawValue: 64)
    public static let away = MTRThermostatScheduleDayOfWeekBitmap(rawValue: 128)
}

public struct MTRThermostatScheduleModeBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let heatSetpointPresent = MTRThermostatScheduleModeBitmap(rawValue: 1)
    public static let coolSetpointPresent = MTRThermostatScheduleModeBitmap(rawValue: 2)
}

public struct MTRThermostatScheduleTypeFeaturesBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let supportsPresets = MTRThermostatScheduleTypeFeaturesBitmap(rawValue: 1)
    public static let supportsSetpoints = MTRThermostatScheduleTypeFeaturesBitmap(rawValue: 2)
    public static let supportsNames = MTRThermostatScheduleTypeFeaturesBitmap(rawValue: 4)
    public static let supportsOff = MTRThermostatScheduleTypeFeaturesBitmap(rawValue: 8)
}

public struct MTRThreadBorderRouterManagementFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let panChange = MTRThreadBorderRouterManagementFeature(rawValue: 1)
}

public struct MTRThreadNetworkDiagnosticsFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let packetCounts = MTRThreadNetworkDiagnosticsFeature(rawValue: 1)
    public static let errorCounts = MTRThreadNetworkDiagnosticsFeature(rawValue: 2)
    public static let mleCounts = MTRThreadNetworkDiagnosticsFeature(rawValue: 4)
    public static let macCounts = MTRThreadNetworkDiagnosticsFeature(rawValue: 8)
}

public struct MTRTimeFormatLocalizationFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let calendarFormat = MTRTimeFormatLocalizationFeature(rawValue: 1)
}

public struct MTRTimeSynchronizationFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let timeZone = MTRTimeSynchronizationFeature(rawValue: 1)
    public static let ntpClient = MTRTimeSynchronizationFeature(rawValue: 2)
    public static let ntpServer = MTRTimeSynchronizationFeature(rawValue: 4)
    public static let timeSyncClient = MTRTimeSynchronizationFeature(rawValue: 8)
}

public struct MTRTotalVolatileOrganicCompoundsConcentrationMeasurementFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let numericMeasurement = MTRTotalVolatileOrganicCompoundsConcentrationMeasurementFeature(rawValue: 1)
    public static let levelIndication = MTRTotalVolatileOrganicCompoundsConcentrationMeasurementFeature(rawValue: 2)
    public static let mediumLevel = MTRTotalVolatileOrganicCompoundsConcentrationMeasurementFeature(rawValue: 4)
    public static let criticalLevel = MTRTotalVolatileOrganicCompoundsConcentrationMeasurementFeature(rawValue: 8)
    public static let peakMeasurement = MTRTotalVolatileOrganicCompoundsConcentrationMeasurementFeature(rawValue: 16)
    public static let averageMeasurement = MTRTotalVolatileOrganicCompoundsConcentrationMeasurementFeature(rawValue: 32)
}

public struct MTRUnitLocalizationFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let temperatureUnit = MTRUnitLocalizationFeature(rawValue: 1)
}

public struct MTRUnitTestingBitmap16MaskMap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let maskVal1 = MTRUnitTestingBitmap16MaskMap(rawValue: 1)
    public static let maskVal2 = MTRUnitTestingBitmap16MaskMap(rawValue: 2)
    public static let maskVal3 = MTRUnitTestingBitmap16MaskMap(rawValue: 4)
    public static let maskVal4 = MTRUnitTestingBitmap16MaskMap(rawValue: 8)
}

public struct MTRUnitTestingBitmap32MaskMap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let maskVal1 = MTRUnitTestingBitmap32MaskMap(rawValue: 1)
    public static let maskVal2 = MTRUnitTestingBitmap32MaskMap(rawValue: 2)
    public static let maskVal3 = MTRUnitTestingBitmap32MaskMap(rawValue: 4)
    public static let maskVal4 = MTRUnitTestingBitmap32MaskMap(rawValue: 8)
}

public struct MTRUnitTestingBitmap64MaskMap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt64
    public init(rawValue: UInt64) { self.rawValue = rawValue }
    public static let maskVal1 = MTRUnitTestingBitmap64MaskMap(rawValue: 1)
    public static let maskVal2 = MTRUnitTestingBitmap64MaskMap(rawValue: 2)
    public static let maskVal3 = MTRUnitTestingBitmap64MaskMap(rawValue: 4)
    public static let maskVal4 = MTRUnitTestingBitmap64MaskMap(rawValue: 8)
}

public struct MTRUnitTestingBitmap8MaskMap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let maskVal1 = MTRUnitTestingBitmap8MaskMap(rawValue: 1)
    public static let maskVal2 = MTRUnitTestingBitmap8MaskMap(rawValue: 2)
    public static let maskVal3 = MTRUnitTestingBitmap8MaskMap(rawValue: 4)
    public static let maskVal4 = MTRUnitTestingBitmap8MaskMap(rawValue: 8)
}

public struct MTRUnitTestingSimpleBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let valueA = MTRUnitTestingSimpleBitmap(rawValue: 1)
    public static let valueB = MTRUnitTestingSimpleBitmap(rawValue: 2)
    public static let valueC = MTRUnitTestingSimpleBitmap(rawValue: 4)
}

public struct MTRValveConfigurationAndControlFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let timeSync = MTRValveConfigurationAndControlFeature(rawValue: 1)
    public static let level = MTRValveConfigurationAndControlFeature(rawValue: 2)
}

public struct MTRValveConfigurationAndControlValveFaultBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let generalFault = MTRValveConfigurationAndControlValveFaultBitmap(rawValue: 1)
    public static let blocked = MTRValveConfigurationAndControlValveFaultBitmap(rawValue: 2)
    public static let leaking = MTRValveConfigurationAndControlValveFaultBitmap(rawValue: 4)
    public static let notConnected = MTRValveConfigurationAndControlValveFaultBitmap(rawValue: 8)
    public static let shortCircuit = MTRValveConfigurationAndControlValveFaultBitmap(rawValue: 16)
    public static let currentExceeded = MTRValveConfigurationAndControlValveFaultBitmap(rawValue: 32)
}

public struct MTRWaterHeaterManagementFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let energyManagement = MTRWaterHeaterManagementFeature(rawValue: 1)
    public static let tankPercent = MTRWaterHeaterManagementFeature(rawValue: 2)
}

public struct MTRWaterHeaterManagementWaterHeaterHeatSourceBitmap: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let immersionElement1 = MTRWaterHeaterManagementWaterHeaterHeatSourceBitmap(rawValue: 1)
    public static let immersionElement2 = MTRWaterHeaterManagementWaterHeaterHeatSourceBitmap(rawValue: 2)
    public static let heatPump = MTRWaterHeaterManagementWaterHeaterHeatSourceBitmap(rawValue: 4)
    public static let boiler = MTRWaterHeaterManagementWaterHeaterHeatSourceBitmap(rawValue: 8)
    public static let other = MTRWaterHeaterManagementWaterHeaterHeatSourceBitmap(rawValue: 16)
}

public struct MTRWiFiNetworkDiagnosticsFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let packetCounts = MTRWiFiNetworkDiagnosticsFeature(rawValue: 1)
    public static let errorCounts = MTRWiFiNetworkDiagnosticsFeature(rawValue: 2)
}

public struct MTRWindowCoveringConfigStatus: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let operational = MTRWindowCoveringConfigStatus(rawValue: 1)
    public static let onlineReserved = MTRWindowCoveringConfigStatus(rawValue: 2)
    public static let liftMovementReversed = MTRWindowCoveringConfigStatus(rawValue: 4)
    public static let liftPositionAware = MTRWindowCoveringConfigStatus(rawValue: 8)
    public static let tiltPositionAware = MTRWindowCoveringConfigStatus(rawValue: 16)
    public static let liftEncoderControlled = MTRWindowCoveringConfigStatus(rawValue: 32)
    public static let tiltEncoderControlled = MTRWindowCoveringConfigStatus(rawValue: 64)
}

public struct MTRWindowCoveringFeature: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let lift = MTRWindowCoveringFeature(rawValue: 1)
    public static let tilt = MTRWindowCoveringFeature(rawValue: 2)
    public static let positionAwareLift = MTRWindowCoveringFeature(rawValue: 4)
    public static let absolutePosition = MTRWindowCoveringFeature(rawValue: 8)
    public static let positionAwareTilt = MTRWindowCoveringFeature(rawValue: 16)
}

public struct MTRWindowCoveringMode: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let motorDirectionReversed = MTRWindowCoveringMode(rawValue: 1)
    public static let calibrationMode = MTRWindowCoveringMode(rawValue: 2)
    public static let maintenanceMode = MTRWindowCoveringMode(rawValue: 4)
    public static let ledFeedback = MTRWindowCoveringMode(rawValue: 8)
}

public struct MTRWindowCoveringOperationalStatus: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let global = MTRWindowCoveringOperationalStatus(rawValue: 1)
    public static let lift = MTRWindowCoveringOperationalStatus(rawValue: 2)
    public static let tilt = MTRWindowCoveringOperationalStatus(rawValue: 4)
}

public struct MTRWindowCoveringSafetyStatus: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let remoteLockout = MTRWindowCoveringSafetyStatus(rawValue: 1)
    public static let tamperDetection = MTRWindowCoveringSafetyStatus(rawValue: 2)
    public static let failedCommunication = MTRWindowCoveringSafetyStatus(rawValue: 4)
    public static let positionFailure = MTRWindowCoveringSafetyStatus(rawValue: 8)
    public static let thermalProtection = MTRWindowCoveringSafetyStatus(rawValue: 16)
    public static let obstacleDetected = MTRWindowCoveringSafetyStatus(rawValue: 32)
    public static let power = MTRWindowCoveringSafetyStatus(rawValue: 64)
    public static let stopInput = MTRWindowCoveringSafetyStatus(rawValue: 128)
    public static let motorJammed = MTRWindowCoveringSafetyStatus(rawValue: 256)
    public static let hardwareFailure = MTRWindowCoveringSafetyStatus(rawValue: 512)
    public static let manualOperation = MTRWindowCoveringSafetyStatus(rawValue: 1024)
    public static let protection = MTRWindowCoveringSafetyStatus(rawValue: 2048)
}

