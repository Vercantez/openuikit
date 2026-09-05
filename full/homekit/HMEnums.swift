import Foundation

// Native raw values come from the pinned dotnet/macios HomeKit/HMEnums.cs
// `[Native]` enumerations (Xcode-era HMErrorCode / HAP characteristic values).

public enum HMCameraAudioStreamSetting: UInt, Sendable, Hashable {
    case bidirectionalAudioAllowed = 3
    case incomingAudioAllowed = 2
    case muted = 1
}

public enum HMCameraStreamState: UInt, Sendable, Hashable {
    case notStreaming = 4
    case starting = 1
    case stopping = 3
    case streaming = 2
}

public enum HMCharacteristicValueActivationState: Int, Sendable, Hashable {
    case active = 1
    case inactive = 0
}

public enum HMCharacteristicValueAirParticulateSize: Int, Sendable, Hashable {
    case size10 = 1
    case size2_5 = 0
}

public enum HMCharacteristicValueAirQuality: Int, Sendable, Hashable {
    case excellent = 1
    case fair = 3
    case good = 2
    case inferior = 4
    case poor = 5
    case unknown = 0
}

public enum HMCharacteristicValueBatteryStatus: Int, Sendable, Hashable {
    case low = 1
    case normal = 0
}

public enum HMCharacteristicValueCarbonDioxideDetectionStatus: Int, Sendable, Hashable {
    case detected = 1
    case notDetected = 0
}

public enum HMCharacteristicValueCarbonMonoxideDetectionStatus: Int, Sendable, Hashable {
    case detected = 1
    case notDetected = 0
}

public enum HMCharacteristicValueChargingState: Int, Sendable, Hashable {
    case inProgress = 1
    case `none` = 0
    case notChargeable = 2
}

public enum HMCharacteristicValueClosedCaptions: Int, Sendable, Hashable {
    case disabled = 0
    case enabled = 1
}

public enum HMCharacteristicValueConfigurationState: Int, Sendable, Hashable {
    case configured = 1
    case notConfigured = 0
}

public enum HMCharacteristicValueContactState: Int, Sendable, Hashable {
    case detected = 0
    case `none` = 1
}

public enum HMCharacteristicValueCurrentAirPurifierState: Int, Sendable, Hashable {
    case active = 2
    case idle = 1
    case inactive = 0
}

public enum HMCharacteristicValueCurrentFanState: Int, Sendable, Hashable {
    case active = 2
    case idle = 1
    case inactive = 0
}

public enum HMCharacteristicValueCurrentHeaterCoolerState: Int, Sendable, Hashable {
    case cooling = 3
    case heating = 2
    case idle = 1
    case inactive = 0
}

public enum HMCharacteristicValueCurrentHeatingCooling: Int, Sendable, Hashable {
    case cool = 2
    case heat = 1
    case off = 0
}

public enum HMCharacteristicValueCurrentHumidifierDehumidifierState: Int, Sendable, Hashable {
    case dehumidifying = 3
    case humidifying = 2
    case idle = 1
    case inactive = 0
}

public enum HMCharacteristicValueCurrentMediaState: Int, Sendable, Hashable {
    case interrupted = 5
    case loading = 4
    case paused = 1
    case playing = 0
    case stopped = 2
    case unknown = 3
}

public enum HMCharacteristicValueCurrentSecuritySystemState: Int, Sendable, Hashable {
    case awayArm = 1
    case disarmed = 3
    case nightArm = 2
    case stayArm = 0
    case triggered = 4
}

public enum HMCharacteristicValueCurrentSlatState: Int, Sendable, Hashable {
    case jammed = 1
    case oscillating = 2
    case stationary = 0
}

public enum HMCharacteristicValueCurrentVisibilityState: Int, Sendable, Hashable {
    case alwaysShown = 3
    case connected = 2
    case hidden = 1
    case shown = 0
}

public enum HMCharacteristicValueDoorState: Int, Sendable, Hashable {
    case closed = 1
    case closing = 3
    case `open` = 0
    case opening = 2
    case stopped = 4
}

public enum HMCharacteristicValueFilterChange: Int, Sendable, Hashable {
    case needed = 1
    case notNeeded = 0
}

public enum HMCharacteristicValueHeatingCooling: Int, Sendable, Hashable {
    case auto = 3
    case cool = 2
    case heat = 1
    case off = 0
}

public enum HMCharacteristicValueInputDeviceType: Int, Sendable, Hashable {
    case audioSystem = 5
    case `none` = 6
    case other = 0
    case playback = 4
    case recording = 2
    case tv = 1
    case tuner = 3
}

public enum HMCharacteristicValueInputEvent: Int, Sendable, Hashable {
    case doublePress = 1
    case longPress = 2
    case singlePress = 0
}

public enum HMCharacteristicValueInputSourceType: Int, Sendable, Hashable {
    case airPlay = 8
    case application = 10
    case componentVideo = 6
    case compositeVideo = 4
    case dvi = 7
    case hdmi = 3
    case homeScreen = 1
    case other = 0
    case sVideo = 5
    case tuner = 2
    case usb = 9
}

public enum HMCharacteristicValueJammedStatus: Int, Sendable, Hashable {
    case jammed = 1
    case `none` = 0
}

public enum HMCharacteristicValueLabelNamespace: Int, Sendable, Hashable {
    case dot = 0
    case numeral = 1
}

public enum HMCharacteristicValueLeakStatus: Int, Sendable, Hashable {
    case detected = 1
    case `none` = 0
}

public enum HMCharacteristicValueLockMechanismLastKnownAction: Int, Sendable, Hashable {
    case securedRemotely = 6
    case securedUsingPhysicalMovement = 9
    case securedUsingPhysicalMovementExterior = 2
    case securedUsingPhysicalMovementInterior = 0
    case securedWithAutomaticSecureTimeout = 8
    case securedWithKeypad = 4
    case unsecuredRemotely = 7
    case unsecuredUsingPhysicalMovement = 10
    case unsecuredUsingPhysicalMovementExterior = 3
    case unsecuredUsingPhysicalMovementInterior = 1
    case unsecuredWithKeypad = 5
}

public enum HMCharacteristicValueLockMechanismState: Int, Sendable, Hashable {
    case jammed = 2
    case secured = 1
    case unknown = 3
    case unsecured = 0
}

public enum HMCharacteristicValueLockPhysicalControlsState: Int, Sendable, Hashable {
    case locked = 1
    case notLocked = 0
}

public enum HMCharacteristicValueOccupancyStatus: Int, Sendable, Hashable {
    case notOccupied = 0
    case occupied = 1
}

public enum HMCharacteristicValuePictureMode: Int, Sendable, Hashable {
    case bright = 7
    case calibrated = 10
    case computer = 8
    case custom1 = 11
    case custom2 = 12
    case custom3 = 13
    case dark = 6
    case game = 3
    case movie = 1
    case night = 9
    case photo = 4
    case sport = 2
    case standard = 0
    case vivid = 5
}

public enum HMCharacteristicValuePositionState: Int, Sendable, Hashable {
    case closing = 0
    case opening = 1
    case stopped = 2
}

public enum HMCharacteristicValuePowerModeSelection: Int, Sendable, Hashable {
    case hide = 1
    case show = 0
}

public enum HMCharacteristicValueProgramMode: Int, Sendable, Hashable {
    case notScheduled = 0
    case scheduleOverriddenToManual = 2
    case scheduled = 1
}

public enum HMCharacteristicValueRemoteKey: Int, Sendable, Hashable {
    case arrowDown = 5
    case arrowLeft = 6
    case arrowRight = 7
    case arrowUp = 4
    case back = 9
    case exit = 10
    case fastForward = 1
    case home = 16
    case info = 15
    case menu = 14
    case nextTrack = 2
    case pause = 13
    case play = 12
    case playPause = 11
    case previousTrack = 3
    case rewind = 0
    case select = 8
}

public enum HMCharacteristicValueRotationDirection: Int, Sendable, Hashable {
    case clockwise = 0
    case counterClockwise = 1
}

public enum HMCharacteristicValueRouterStatus: Int, Sendable, Hashable {
    case notReady = 1
    case ready = 0
}

public enum HMCharacteristicValueSecuritySystemAlarmType: Int, Sendable, Hashable {
    case noAlarm = 0
    case unknown = 1
}

public enum HMCharacteristicValueSlatType: Int, Sendable, Hashable {
    case horizontal = 0
    case vertical = 1
}

public enum HMCharacteristicValueSmokeDetectionStatus: Int, Sendable, Hashable {
    case detected = 1
    case `none` = 0
}

public enum HMCharacteristicValueStatusFault: Int, Sendable, Hashable {
    case generalFault = 1
    case noFault = 0
}

public enum HMCharacteristicValueSwingMode: Int, Sendable, Hashable {
    case disabled = 0
    case enabled = 1
}

public enum HMCharacteristicValueTamperedStatus: Int, Sendable, Hashable {
    case `none` = 0
    case tampered = 1
}

public enum HMCharacteristicValueTargetAirPurifierState: Int, Sendable, Hashable {
    case automatic = 1
    case manual = 0
}

public enum HMCharacteristicValueTargetDoorState: Int, Sendable, Hashable {
    case closed = 1
    case `open` = 0
}

public enum HMCharacteristicValueTargetFanState: Int, Sendable, Hashable {
    case automatic = 1
    case manual = 0
}

public enum HMCharacteristicValueTargetHeaterCoolerState: Int, Sendable, Hashable {
    case automatic = 0
    case cool = 2
    case heat = 1
}

public enum HMCharacteristicValueTargetHumidifierDehumidifierState: Int, Sendable, Hashable {
    case automatic = 0
    case dehumidify = 2
    case humidify = 1
}

public enum HMCharacteristicValueTargetLockMechanismState: Int, Sendable, Hashable {
    case secured = 1
    case unsecured = 0
}

public enum HMCharacteristicValueTargetMediaState: Int, Sendable, Hashable {
    case pause = 1
    case play = 0
    case stop = 2
}

public enum HMCharacteristicValueTargetSecuritySystemState: Int, Sendable, Hashable {
    case awayArm = 1
    case disarm = 3
    case nightArm = 2
    case stayArm = 0
}

public enum HMCharacteristicValueTargetVisibilityState: Int, Sendable, Hashable {
    case hide = 1
    case show = 0
}

public enum HMCharacteristicValueTemperatureUnit: Int, Sendable, Hashable {
    case celsius = 0
    case fahrenheit = 1
}

public enum HMCharacteristicValueUsageState: Int, Sendable, Hashable {
    case inUse = 1
    case notInUse = 0
}

public enum HMCharacteristicValueValveType: Int, Sendable, Hashable {
    case genericValve = 0
    case irrigation = 1
    case showerHead = 2
    case waterFaucet = 3
}

public enum HMCharacteristicValueVolumeControlType: Int, Sendable, Hashable {
    case absolute = 3
    case `none` = 0
    case relative = 1
    case relativeWithCurrent = 2
}

public enum HMCharacteristicValueVolumeSelector: Int, Sendable, Hashable {
    case volumeDecrement = 1
    case volumeIncrement = 0
}

public enum HMCharacteristicValueWiFiSatelliteStatus: Int, Sendable, Hashable {
    case connected = 1
    case notConnected = 2
    case unknown = 0
}

public enum HMEventTriggerActivationState: UInt, Sendable, Hashable {
    case disabled = 0
    case disabledNoCompatibleHomeHub = 2
    case disabledNoHomeHub = 1
    case disabledNoLocationServicesAuthorization = 3
    case enabled = 4
}

public enum HMHomeHubState: UInt, Sendable, Hashable {
    case connected = 1
    case disconnected = 2
    case notAvailable = 0
}

public enum HMPresenceEventType: UInt, Sendable, Hashable {
    case everyEntry = 1
    case everyExit = 2
    case firstEntry = 3
    case lastExit = 4
    public static var atHome: HMPresenceEventType { .firstEntry }
    public static var notAtHome: HMPresenceEventType { .lastExit }
}

public enum HMPresenceEventUserType: UInt, Sendable, Hashable {
    case currentUser = 1
    case customUsers = 3
    case homeUsers = 2
}

