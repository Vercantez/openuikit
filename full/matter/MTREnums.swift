import Foundation

public enum MTRStorageSecurityLevel: UInt, Sendable, Hashable {
    case secure = 0
    case notSecure = 1
}

public enum MTRStorageSharingType: UInt, Sendable, Hashable {
    case notShared = 0
    case sameIdentity = 1
    case sameACLs = 2
    case sameFabric = 3
}

public enum MTRCommissioningStatus: UInt, Sendable, Hashable {
    case unknown = 0
    case success = 1
    case failed = 2
    case discoveringMoreDevices = 3
}

public enum MTRPairingStatus: UInt, Sendable, Hashable {
    case unknown = 0
    case success = 1
    case failed = 2
    case discoveringMoreDevices = 3
}

public enum MTRColorControlSaturationMoveMode: UInt, Sendable, Hashable {
    case stop = 0
    case up = 1
    case down = 2
}

public enum MTRColorControlSaturationStepMode: UInt, Sendable, Hashable {
    case up = 0
    case down = 1
}

public enum MTROTASoftwareUpdateProviderOTAApplyUpdateAction: UInt, Sendable, Hashable {
    case proceed = 0
    case awaitNextAction = 1
    case discontinue = 2
}

public enum MTROTASoftwareUpdateProviderOTADownloadProtocol: UInt, Sendable, Hashable {
    case bdxSynchronous = 0
    case bdxAsynchronous = 1
    case HTTPS = 2
    case vendorSpecific = 3
}

public enum MTROTASoftwareUpdateProviderOTAQueryStatus: UInt, Sendable, Hashable {
    case updateAvailable = 0
    case busy = 1
    case notAvailable = 2
    case downloadProtocolNotSupported = 3
}

public enum MTROTASoftwareUpdateRequestorOTAAnnouncementReason: UInt, Sendable, Hashable {
    case simpleAnnouncement = 0
    case updateAvailable = 1
    case urgentUpdateAvailable = 2
}

public enum MTROTASoftwareUpdateRequestorOTAChangeReason: UInt, Sendable, Hashable {
    case unknown = 0
    case success = 1
    case failure = 2
    case timeOut = 3
    case delayByProvider = 4
}

public enum MTROTASoftwareUpdateRequestorOTAUpdateState: UInt, Sendable, Hashable {
    case unknown = 0
    case idle = 1
    case querying = 2
    case delayedOnQuery = 3
    case downloading = 4
    case applying = 5
    case delayedOnApply = 6
    case rollingBack = 7
    case delayedOnUserConsent = 8
}

public enum MTREventPriority: UInt, Sendable, Hashable {
    case debug = 0
    case info = 1
    case critical = 2
}

public enum MTREventTimeType: UInt, Sendable, Hashable {
    case systemUpTime = 0
    case timestampDate = 1
}

public enum MTRTransportType: UInt, Sendable, Hashable {
    case undefined = 0
    case UDP = 1
    case BLE = 2
    case TCP = 3
}

public enum MTRLogType: UInt, Sendable, Hashable {
    case error = 0
    case progress = 1
    case detail = 2
}

public enum MTRDiagnosticLogType: UInt, Sendable, Hashable {
    case endUserSupport = 0
    case networkDiagnostics = 1
    case crash = 2
}

public enum MTROnboardingPayloadType: UInt, Sendable, Hashable {
    case qrCode = 0
    case manualCode = 1
    case NFC = 2
}

public enum MTRDeviceState: UInt, Sendable, Hashable {
    case unknown = 0
    case reachable = 1
    case unreachable = 2
}

public enum MTROTAImageDigestType: UInt, Sendable, Hashable {
    case sha256 = 0
    case sha256_128 = 1
    case sha256_120 = 2
    case sha256_96 = 3
    case sha256_64 = 4
    case sha256_32 = 5
    case sha384 = 6
    case sha512 = 7
    case sha3_224 = 8
    case sha3_256 = 9
    case sha3_384 = 10
    case sha3_512 = 11
}

public enum MTRAccessControlAccessRestrictionType: UInt, Sendable, Hashable {
    case attributeAccessForbidden = 0
    case attributeWriteForbidden = 1
    case commandForbidden = 2
    case eventForbidden = 3
}

public enum MTRAccessControlAuthMode: UInt, Sendable, Hashable {
    case PASE = 1
    case CASE = 2
    case group = 3
}

public enum MTRAccessControlChangeType: UInt, Sendable, Hashable {
    case changed = 0
    case added = 1
    case removed = 2
}

public enum MTRAccessControlEntryAuthMode: UInt, Sendable, Hashable {
    case PASE = 1
    case CASE = 2
    case group = 3
}

public enum MTRAccessControlEntryPrivilege: UInt, Sendable, Hashable {
    case view = 1
    case proxyView = 2
    case operate = 3
    case manage = 4
    case administer = 5
}

public enum MTRAccessControlPrivilege: UInt, Sendable, Hashable {
    case view = 1
    case proxyView = 2
    case operate = 3
    case manage = 4
    case administer = 5
}

public enum MTRActionsActionError: UInt, Sendable, Hashable {
    case unknown = 0
    case interrupted = 1
}

public enum MTRActionsActionState: UInt, Sendable, Hashable {
    case inactive = 0
    case active = 1
    case paused = 2
    case disabled = 3
}

public enum MTRActionsActionType: UInt, Sendable, Hashable {
    case other = 0
    case scene = 1
    case sequence = 2
    case automation = 3
    case exception = 4
    case notification = 5
    case alarm = 6
}

public enum MTRActionsEndpointListType: UInt, Sendable, Hashable {
    case other = 0
    case room = 1
    case zone = 2
}

public enum MTRActivatedCarbonFilterMonitoringChangeIndication: UInt, Sendable, Hashable {
    case OK = 0
    case warning = 1
    case critical = 2
}

public enum MTRActivatedCarbonFilterMonitoringDegradationDirection: UInt, Sendable, Hashable {
    case up = 0
    case down = 1
}

public enum MTRActivatedCarbonFilterMonitoringProductIdentifierType: UInt, Sendable, Hashable {
    case UPC = 0
    case GTIN8 = 1
    case EAN = 2
    case GTIN14 = 3
    case OEM = 4
}

public enum MTRAdministratorCommissioningCommissioningWindowStatus: UInt, Sendable, Hashable {
    case windowNotOpen = 0
    case enhancedWindowOpen = 1
    case basicWindowOpen = 2
}

public enum MTRAdministratorCommissioningStatusCode: UInt, Sendable, Hashable {
    case busy = 0
    case pakeParameterError = 1
    case windowNotOpen = 2
}

public enum MTRAirQuality: UInt, Sendable, Hashable {
    case unknown = 0
    case good = 1
    case fair = 2
    case moderate = 3
    case poor = 4
    case veryPoor = 5
    case extremelyPoor = 6
}

public enum MTRApplicationBasicApplicationStatus: UInt, Sendable, Hashable {
    case stopped = 0
    case activeVisibleFocus = 1
    case activeHidden = 2
    case activeVisibleNotFocus = 3
}

public enum MTRApplicationLauncherStatus: UInt, Sendable, Hashable {
    case success = 0
    case appNotAvailable = 1
    case systemBusy = 2
    case pendingUserApproval = 3
    case downloading = 4
    case installing = 5
}

public enum MTRAudioOutputOutputType: UInt, Sendable, Hashable {
    case HDMI = 0
    case BT = 1
    case optical = 2
    case headphone = 3
    case `internal` = 4
    case other = 5
}

public enum MTRBasicInformationColor: UInt, Sendable, Hashable {
    case black = 0
    case navy = 1
    case green = 2
    case teal = 3
    case maroon = 4
    case purple = 5
    case olive = 6
    case gray = 7
    case blue = 8
    case lime = 9
    case aqua = 10
    case red = 11
    case fuchsia = 12
    case yellow = 13
    case white = 14
    case nickel = 15
    case chrome = 16
    case brass = 17
    case copper = 18
    case silver = 19
    case gold = 20
}

public enum MTRBasicInformationProductFinish: UInt, Sendable, Hashable {
    case other = 0
    case matte = 1
    case satin = 2
    case polished = 3
    case rugged = 4
    case fabric = 5
}

public enum MTRBridgedDeviceBasicInformationColor: UInt, Sendable, Hashable {
    case black = 0
    case navy = 1
    case green = 2
    case teal = 3
    case maroon = 4
    case purple = 5
    case olive = 6
    case gray = 7
    case blue = 8
    case lime = 9
    case aqua = 10
    case red = 11
    case fuchsia = 12
    case yellow = 13
    case white = 14
    case nickel = 15
    case chrome = 16
    case brass = 17
    case copper = 18
    case silver = 19
    case gold = 20
}

public enum MTRBridgedDeviceBasicInformationProductFinish: UInt, Sendable, Hashable {
    case other = 0
    case matte = 1
    case satin = 2
    case polished = 3
    case rugged = 4
    case fabric = 5
}

public enum MTRCarbonDioxideConcentrationMeasurementLevelValue: UInt, Sendable, Hashable {
    case unknown = 0
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
}

public enum MTRCarbonDioxideConcentrationMeasurementMeasurementMedium: UInt, Sendable, Hashable {
    case air = 0
    case water = 1
    case soil = 2
}

public enum MTRCarbonDioxideConcentrationMeasurementMeasurementUnit: UInt, Sendable, Hashable {
    case PPM = 0
    case PPB = 1
    case PPT = 2
    case MGM3 = 3
    case UGM3 = 4
    case NGM3 = 5
    case PM3 = 6
    case BQM3 = 7
}

public enum MTRCarbonMonoxideConcentrationMeasurementLevelValue: UInt, Sendable, Hashable {
    case unknown = 0
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
}

public enum MTRCarbonMonoxideConcentrationMeasurementMeasurementMedium: UInt, Sendable, Hashable {
    case air = 0
    case water = 1
    case soil = 2
}

public enum MTRCarbonMonoxideConcentrationMeasurementMeasurementUnit: UInt, Sendable, Hashable {
    case PPM = 0
    case PPB = 1
    case PPT = 2
    case MGM3 = 3
    case UGM3 = 4
    case NGM3 = 5
    case PM3 = 6
    case BQM3 = 7
}

public enum MTRChannelLineupInfoType: UInt, Sendable, Hashable {
    case MSO = 0
}

public enum MTRChannelStatus: UInt, Sendable, Hashable {
    case success = 0
    case multipleMatches = 1
    case noMatches = 2
}

public enum MTRChannelType: UInt, Sendable, Hashable {
    case satellite = 0
    case cable = 1
    case terrestrial = 2
    case OTT = 3
}

public enum MTRColorControlColorLoopAction: UInt, Sendable, Hashable {
    case deactivate = 0
    case activateFromColorLoopStartEnhancedHue = 1
    case activateFromEnhancedCurrentHue = 2
}

public enum MTRColorControlColorLoopDirection: UInt, Sendable, Hashable {
    case decrement = 0
    case increment = 1
}

public enum MTRColorControlColorMode: UInt, Sendable, Hashable {
    case currentHueAndCurrentSaturation = 0
    case currentXAndCurrentY = 1
    case colorTemperatureMireds = 2
}

public enum MTRColorControlDirection: UInt, Sendable, Hashable {
    case shortest = 0
    case longest = 1
    case up = 2
    case down = 3
}

public enum MTRColorControlDriftCompensation: UInt, Sendable, Hashable {
    case none = 0
    case otherOrUnknown = 1
    case temperatureMonitoring = 2
    case opticalLuminanceMonitoringAndFeedback = 3
    case opticalColorMonitoringAndFeedback = 4
}

public enum MTRColorControlEnhancedColorMode: UInt, Sendable, Hashable {
    case currentHueAndCurrentSaturation = 0
    case currentXAndCurrentY = 1
    case colorTemperatureMireds = 2
    case enhancedCurrentHueAndCurrentSaturation = 3
}

public enum MTRColorControlHueDirection: UInt, Sendable, Hashable {
    case shortestDistance = 0
    case longestDistance = 1
    case up = 2
    case down = 3
}

public enum MTRColorControlHueMoveMode: UInt, Sendable, Hashable {
    case stop = 0
    case up = 1
    case down = 2
}

public enum MTRColorControlHueStepMode: UInt, Sendable, Hashable {
    case up = 0
    case down = 1
}

public enum MTRColorControlMoveMode: UInt, Sendable, Hashable {
    case stop = 0
    case up = 1
    case down = 2
}

public enum MTRColorControlStepMode: UInt, Sendable, Hashable {
    case up = 0
    case down = 1
}

public enum MTRContentAppObserverStatus: UInt, Sendable, Hashable {
    case success = 0
    case unexpectedData = 1
}

public enum MTRContentLauncherContentLaunchStatus: UInt, Sendable, Hashable {
    case success = 0
    case urlNotAvailable = 1
    case authFailed = 2
}

public enum MTRContentLauncherMetricType: UInt, Sendable, Hashable {
    case pixels = 0
    case percentage = 1
}

public enum MTRContentLauncherParameter: UInt, Sendable, Hashable {
    case actor = 0
    case channel = 1
    case character = 2
    case director = 3
    case event = 4
    case franchise = 5
    case genre = 6
    case league = 7
    case popularity = 8
    case provider = 9
    case sport = 10
    case sportsTeam = 11
    case type = 12
    case video = 13
    case season = 14
    case episode = 15
    case `any` = 16
}

public enum MTRContentLauncherStatus: UInt, Sendable, Hashable {
    case success = 0
    case urlNotAvailable = 1
    case authFailed = 2
    case textTrackNotAvailable = 3
    case audioTrackNotAvailable = 4
}

public enum MTRDataTypeAtomicRequestTypeEnum: UInt, Sendable, Hashable {
    case beginWrite = 0
    case commitWrite = 1
    case rollbackWrite = 2
}

public enum MTRDataTypeLandmarkTag: UInt, Sendable, Hashable {
    case airConditioner = 0
    case airPurifier = 1
    case backDoor = 2
    case barStool = 3
    case bathMat = 4
    case bathtub = 5
    case bed = 6
    case bookshelf = 7
    case chair = 8
    case christmasTree = 9
    case coatRack = 10
    case coffeeTable = 11
    case cookingRange = 12
    case couch = 13
    case countertop = 14
    case cradle = 15
    case crib = 16
    case desk = 17
    case diningTable = 18
    case dishwasher = 19
    case door = 20
    case dresser = 21
    case laundryDryer = 22
    case fan = 23
    case fireplace = 24
    case freezer = 25
    case frontDoor = 26
    case highChair = 27
    case kitchenIsland = 28
    case lamp = 29
    case litterBox = 30
    case mirror = 31
    case nightstand = 32
    case oven = 33
    case petBed = 34
    case petBowl = 35
    case petCrate = 36
    case refrigerator = 37
    case scratchingPost = 38
    case shoeRack = 39
    case shower = 40
    case sideDoor = 41
    case sink = 42
    case sofa = 43
    case stove = 44
    case table = 45
    case toilet = 46
    case trashCan = 47
    case laundryWasher = 48
    case window = 49
    case wineCooler = 50
}

public enum MTRDataTypePositionTag: UInt, Sendable, Hashable {
    case left = 0
    case right = 1
    case top = 2
    case bottom = 3
    case middle = 4
    case row = 5
    case column = 6
}

public enum MTRDataTypeRelativePositionTag: UInt, Sendable, Hashable {
    case under = 0
    case nextTo = 1
    case around = 2
    case on = 3
    case above = 4
    case frontOf = 5
    case behind = 6
}

public enum MTRDeviceEnergyManagementAdjustmentCause: UInt, Sendable, Hashable {
    case localOptimization = 0
    case gridOptimization = 1
}

public enum MTRDeviceEnergyManagementCause: UInt, Sendable, Hashable {
    case normalCompletion = 0
    case offline = 1
    case fault = 2
    case userOptOut = 3
    case cancelled = 4
}

public enum MTRDeviceEnergyManagementCostType: UInt, Sendable, Hashable {
    case financial = 0
    case ghgEmissions = 1
    case comfort = 2
    case temperature = 3
}

public enum MTRDeviceEnergyManagementESAState: UInt, Sendable, Hashable {
    case offline = 0
    case online = 1
    case fault = 2
    case powerAdjustActive = 3
    case paused = 4
}

public enum MTRDeviceEnergyManagementESAType: UInt, Sendable, Hashable {
    case EVSE = 0
    case spaceHeating = 1
    case waterHeating = 2
    case spaceCooling = 3
    case spaceHeatingCooling = 4
    case batteryStorage = 5
    case solarPV = 6
    case fridgeFreezer = 7
    case washingMachine = 8
    case dishwasher = 9
    case cooking = 10
    case homeWaterPump = 11
    case irrigationWaterPump = 12
    case poolPump = 13
    case other = 14
}

public enum MTRDeviceEnergyManagementForecastUpdateReason: UInt, Sendable, Hashable {
    case internalOptimization = 0
    case localOptimization = 1
    case gridOptimization = 2
}

public enum MTRDeviceEnergyManagementModeModeTag: UInt8, Sendable, Hashable {
    case auto = 0
    case quick = 1
    case quiet = 2
    case lowNoise = 3
    case lowEnergy = 4
    case vacation = 5
    case min = 6
    case max = 7
    case night = 8
    case day = 9
    case noOptimization = 10
    case deviceOptimization = 11
    case localOptimization = 12
    case gridOptimization = 13
}

public enum MTRDeviceEnergyManagementOptOutState: UInt, Sendable, Hashable {
    case noOptOut = 0
    case localOptOut = 1
    case gridOptOut = 2
    case optOut = 3
}

public enum MTRDeviceEnergyManagementPowerAdjustReason: UInt, Sendable, Hashable {
    case noAdjustment = 0
    case localOptimizationAdjustment = 1
    case gridOptimizationAdjustment = 2
}

public enum MTRDiagnosticLogsIntent: UInt, Sendable, Hashable {
    case endUserSupport = 0
    case networkDiag = 1
    case crashLogs = 2
}

public enum MTRDiagnosticLogsLogsIntent: UInt, Sendable, Hashable {
    case endUserSupport = 0
    case networkDiag = 1
    case crashLogs = 2
}

public enum MTRDiagnosticLogsLogsStatus: UInt, Sendable, Hashable {
    case success = 0
    case exhausted = 1
    case noLogs = 2
    case busy = 3
    case denied = 4
}

public enum MTRDiagnosticLogsLogsTransferProtocol: UInt, Sendable, Hashable {
    case responsePayload = 0
    case BDX = 1
}

public enum MTRDiagnosticLogsStatus: UInt, Sendable, Hashable {
    case success = 0
    case exhausted = 1
    case noLogs = 2
    case busy = 3
    case denied = 4
}

public enum MTRDiagnosticLogsTransferProtocol: UInt, Sendable, Hashable {
    case responsePayload = 0
    case BDX = 1
}

public enum MTRDishwasherModeModeTag: UInt8, Sendable, Hashable {
    case auto = 0
    case quick = 1
    case quiet = 2
    case lowNoise = 3
    case lowEnergy = 4
    case vacation = 5
    case min = 6
    case max = 7
    case night = 8
    case day = 9
    case normal = 10
    case heavy = 11
    case light = 12
}

public enum MTRDoorLockAlarmCode: UInt, Sendable, Hashable {
    case lockJammed = 0
    case lockFactoryReset = 1
    case lockRadioPowerCycled = 2
    case wrongCodeEntryLimit = 3
    case frontEsceutcheonRemoved = 4
    case doorForcedOpen = 5
    case doorAjar = 6
    case forcedUser = 7
}

public enum MTRDoorLockCredentialRule: UInt, Sendable, Hashable {
    case single = 0
    case dual = 1
    case tri = 2
}

public enum MTRDoorLockCredentialType: UInt, Sendable, Hashable {
    case programmingPIN = 0
    case PIN = 1
    case RFID = 2
    case fingerprint = 3
    case fingerVein = 4
    case face = 5
    case aliroCredentialIssuerKey = 6
    case aliroEvictableEndpointKey = 7
    case aliroNonEvictableEndpointKey = 8
}

public enum MTRDoorLockDataOperationType: UInt, Sendable, Hashable {
    case add = 0
    case clear = 1
    case modify = 2
}

public enum MTRDoorLockDlAlarmCode: UInt, Sendable, Hashable {
    case lockJammed = 0
    case lockFactoryReset = 1
    case lockRadioPowerCycled = 2
    case wrongCodeEntryLimit = 3
    case frontEsceutcheonRemoved = 4
    case doorForcedOpen = 5
    case doorAjar = 6
    case forcedUser = 7
}

public enum MTRDoorLockDlCredentialRule: UInt, Sendable, Hashable {
    case single = 0
    case tri = 1
}

public enum MTRDoorLockDlCredentialType: UInt, Sendable, Hashable {
    case programmingPIN = 0
    case PIN = 1
    case RFID = 2
    case fingerprint = 3
    case fingerVein = 4
    case face = 5
}

public enum MTRDoorLockDlDataOperationType: UInt, Sendable, Hashable {
    case add = 0
    case clear = 1
    case modify = 2
}

public enum MTRDoorLockDlDoorState: UInt, Sendable, Hashable {
    case doorOpen = 0
    case doorClosed = 1
    case doorJammed = 2
    case doorForcedOpen = 3
    case doorUnspecifiedError = 4
    case doorAjar = 5
}

public enum MTRDoorLockDlLockDataType: UInt, Sendable, Hashable {
    case unspecified = 0
    case programmingCode = 1
    case userIndex = 2
    case weekDaySchedule = 3
    case yearDaySchedule = 4
    case holidaySchedule = 5
    case PIN = 6
    case RFID = 7
    case fingerprint = 8
}

public enum MTRDoorLockDlLockOperationType: UInt, Sendable, Hashable {
    case lock = 0
    case unlock = 1
    case nonAccessUserEvent = 2
    case forcedUserEvent = 3
}

public enum MTRDoorLockDlLockState: UInt, Sendable, Hashable {
    case notFullyLocked = 0
    case locked = 1
    case unlocked = 2
    case unlatched = 3
}

public enum MTRDoorLockDlLockType: UInt, Sendable, Hashable {
    case deadBolt = 0
    case magnetic = 1
    case other = 2
    case mortise = 3
    case rim = 4
    case latchBolt = 5
    case cylindricalLock = 6
    case tubularLock = 7
    case interconnectedLock = 8
    case deadLatch = 9
    case doorFurniture = 10
    case eurocylinder = 11
}

public enum MTRDoorLockDlOperatingMode: UInt, Sendable, Hashable {
    case normal = 0
    case vacation = 1
    case privacy = 2
    case noRemoteLockUnlock = 3
    case passage = 4
}

public enum MTRDoorLockDlOperationError: UInt, Sendable, Hashable {
    case unspecified = 0
    case invalidCredential = 1
    case disabledUserDenied = 2
    case restricted = 3
    case insufficientBattery = 4
}

public enum MTRDoorLockDlOperationSource: UInt, Sendable, Hashable {
    case unspecified = 0
    case manual = 1
    case proprietaryRemote = 2
    case keypad = 3
    case auto = 4
    case button = 5
    case schedule = 6
    case remote = 7
    case RFID = 8
    case biometric = 9
}

public enum MTRDoorLockDlStatus: UInt, Sendable, Hashable {
    case success = 0
    case failure = 1
    case duplicate = 2
    case occupied = 3
    case invalidField = 4
    case resourceExhausted = 5
    case notFound = 6
}

public enum MTRDoorLockDlUserStatus: UInt, Sendable, Hashable {
    case available = 0
    case occupiedEnabled = 1
    case occupiedDisabled = 2
}

public enum MTRDoorLockDlUserType: UInt, Sendable, Hashable {
    case unrestrictedUser = 0
    case yearDayScheduleUser = 1
    case weekDayScheduleUser = 2
    case programmingUser = 3
    case nonAccessUser = 4
    case forcedUser = 5
    case disposableUser = 6
    case expiringUser = 7
    case scheduleRestrictedUser = 8
    case remoteOnlyUser = 9
}

public enum MTRDoorLockDoorState: UInt, Sendable, Hashable {
    case doorOpen = 0
    case doorClosed = 1
    case doorJammed = 2
    case doorForcedOpen = 3
    case doorUnspecifiedError = 4
    case doorAjar = 5
}

public enum MTRDoorLockLockDataType: UInt, Sendable, Hashable {
    case unspecified = 0
    case programmingCode = 1
    case userIndex = 2
    case weekDaySchedule = 3
    case yearDaySchedule = 4
    case holidaySchedule = 5
    case PIN = 6
    case RFID = 7
    case fingerprint = 8
    case fingerVein = 9
    case face = 10
    case aliroCredentialIssuerKey = 11
    case aliroEvictableEndpointKey = 12
    case aliroNonEvictableEndpointKey = 13
}

public enum MTRDoorLockLockOperationType: UInt, Sendable, Hashable {
    case lock = 0
    case unlock = 1
    case nonAccessUserEvent = 2
    case forcedUserEvent = 3
    case unlatch = 4
}

public enum MTRDoorLockOperatingMode: UInt, Sendable, Hashable {
    case normal = 0
    case vacation = 1
    case privacy = 2
    case noRemoteLockUnlock = 3
    case passage = 4
}

public enum MTRDoorLockOperationError: UInt, Sendable, Hashable {
    case unspecified = 0
    case invalidCredential = 1
    case disabledUserDenied = 2
    case restricted = 3
    case insufficientBattery = 4
}

public enum MTRDoorLockOperationEventCode: UInt, Sendable, Hashable {
    case unknownOrMfgSpecific = 0
    case lock = 1
    case unlock = 2
    case lockInvalidPinOrId = 3
    case lockInvalidSchedule = 4
    case unlockInvalidPinOrId = 5
    case unlockInvalidSchedule = 6
    case oneTouchLock = 7
    case keyLock = 8
    case keyUnlock = 9
    case autoLock = 10
    case scheduleLock = 11
    case scheduleUnlock = 12
    case manualLock = 13
    case manualUnlock = 14
}

public enum MTRDoorLockOperationSource: UInt, Sendable, Hashable {
    case unspecified = 0
    case manual = 1
    case proprietaryRemote = 2
    case keypad = 3
    case auto = 4
    case button = 5
    case schedule = 6
    case remote = 7
    case RFID = 8
    case biometric = 9
    case aliro = 10
}

public enum MTRDoorLockProgrammingEventCode: UInt, Sendable, Hashable {
    case unknownOrMfgSpecific = 0
    case masterCodeChanged = 1
    case pinAdded = 2
    case pinDeleted = 3
    case pinChanged = 4
    case idAdded = 5
    case idDeleted = 6
}

public enum MTRDoorLockSetPinOrIdStatus: UInt, Sendable, Hashable {
    case success = 0
    case generalFailure = 1
    case memoryFull = 2
    case duplicateCodeError = 3
}

public enum MTRDoorLockUserStatus: UInt, Sendable, Hashable {
    case available = 0
    case occupiedEnabled = 1
    case occupiedDisabled = 2
    case notSupported = 3
}

public enum MTRDoorLockUserType: UInt, Sendable, Hashable {
    case unrestrictedUser = 0
    case yearDayScheduleUser = 1
    case weekDayScheduleUser = 2
    case programmingUser = 3
    case nonAccessUser = 4
    case forcedUser = 5
    case disposableUser = 6
    case expiringUser = 7
    case scheduleRestrictedUser = 8
    case remoteOnlyUser = 9
    case notSupported = 10
}

public enum MTRElectricalEnergyMeasurementMeasurementType: UInt, Sendable, Hashable {
    case unspecified = 0
    case voltage = 1
    case activeCurrent = 2
    case reactiveCurrent = 3
    case apparentCurrent = 4
    case activePower = 5
    case reactivePower = 6
    case apparentPower = 7
    case rmsVoltage = 8
    case rmsCurrent = 9
    case rmsPower = 10
    case frequency = 11
    case powerFactor = 12
    case neutralCurrent = 13
    case electricalEnergy = 14
}

public enum MTRElectricalPowerMeasurementMeasurementType: UInt, Sendable, Hashable {
    case unspecified = 0
    case voltage = 1
    case activeCurrent = 2
    case reactiveCurrent = 3
    case apparentCurrent = 4
    case activePower = 5
    case reactivePower = 6
    case apparentPower = 7
    case rmsVoltage = 8
    case rmsCurrent = 9
    case rmsPower = 10
    case frequency = 11
    case powerFactor = 12
    case neutralCurrent = 13
    case electricalEnergy = 14
}

public enum MTRElectricalPowerMeasurementPowerMode: UInt, Sendable, Hashable {
    case unknown = 0
    case DC = 1
    case AC = 2
}

public enum MTREnergyEVSEEnergyTransferStoppedReason: UInt, Sendable, Hashable {
    case evStopped = 0
    case evseStopped = 1
    case other = 2
}

public enum MTREnergyEVSEFaultState: UInt, Sendable, Hashable {
    case noError = 0
    case meterFailure = 1
    case overVoltage = 2
    case underVoltage = 3
    case overCurrent = 4
    case contactWetFailure = 5
    case contactDryFailure = 6
    case groundFault = 7
    case powerLoss = 8
    case powerQuality = 9
    case pilotShortCircuit = 10
    case emergencyStop = 11
    case evDisconnected = 12
    case wrongPowerSupply = 13
    case liveNeutralSwap = 14
    case overTemperature = 15
    case other = 16
}

public enum MTREnergyEVSEModeModeTag: UInt8, Sendable, Hashable {
    case auto = 0
    case quick = 1
    case quiet = 2
    case lowNoise = 3
    case lowEnergy = 4
    case vacation = 5
    case min = 6
    case max = 7
    case night = 8
    case day = 9
    case manual = 10
    case timeOfUse = 11
    case solarCharging = 12
    case V2X = 13
}

public enum MTREnergyEVSEState: UInt, Sendable, Hashable {
    case notPluggedIn = 0
    case pluggedInNoDemand = 1
    case pluggedInDemand = 2
    case pluggedInCharging = 3
    case sessionEnding = 4
    case fault = 5
}

public enum MTREnergyEVSESupplyState: UInt, Sendable, Hashable {
    case disabled = 0
    case chargingEnabled = 1
    case disabledError = 2
    case disabledDiagnostics = 3
}

public enum MTREthernetNetworkDiagnosticsPHYRate: UInt, Sendable, Hashable {
    case rate10M = 0
    case rate100M = 1
    case rate1G = 2
    case rate25G = 3
    case rate5G = 4
    case rate10G = 5
    case rate40G = 6
    case rate100G = 7
    case rate200G = 8
    case rate400G = 9
}

public enum MTREthernetNetworkDiagnosticsPHYRateType: UInt, Sendable, Hashable {
    case type10M = 0
    case type100M = 1
    case type1000M = 2
    case type25G = 3
    case type5G = 4
    case type10G = 5
    case type40G = 6
    case type100G = 7
    case type200G = 8
    case type400G = 9
}

public enum MTRFanControlAirflowDirection: UInt, Sendable, Hashable {
    case forward = 0
    case reverse = 1
}

public enum MTRFanControlFanMode: UInt, Sendable, Hashable {
    case off = 0
    case low = 1
    case medium = 2
    case high = 3
    case on = 4
    case auto = 5
    case smart = 6
}

public enum MTRFanControlFanModeSequence: UInt, Sendable, Hashable {
    case offLowMedHigh = 0
    case offLowHigh = 1
    case offLowMedHighAuto = 2
    case offLowHighAuto = 3
    case offHighAuto = 4
    case offHigh = 5
}

public enum MTRFanControlFanModeSequenceType: UInt, Sendable, Hashable {
    case offLowMedHigh = 0
    case offLowHigh = 1
    case offLowMedHighAuto = 2
    case offLowHighAuto = 3
    case offOnAuto = 4
    case offOn = 5
}

public enum MTRFanControlFanModeType: UInt, Sendable, Hashable {
    case off = 0
    case low = 1
    case medium = 2
    case high = 3
    case on = 4
    case auto = 5
    case smart = 6
}

public enum MTRFanControlStepDirection: UInt, Sendable, Hashable {
    case increase = 0
    case decrease = 1
}

public enum MTRFormaldehydeConcentrationMeasurementLevelValue: UInt, Sendable, Hashable {
    case unknown = 0
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
}

public enum MTRFormaldehydeConcentrationMeasurementMeasurementMedium: UInt, Sendable, Hashable {
    case air = 0
    case water = 1
    case soil = 2
}

public enum MTRFormaldehydeConcentrationMeasurementMeasurementUnit: UInt, Sendable, Hashable {
    case PPM = 0
    case PPB = 1
    case PPT = 2
    case MGM3 = 3
    case UGM3 = 4
    case NGM3 = 5
    case PM3 = 6
    case BQM3 = 7
}

public enum MTRGeneralCommissioningCommissioningError: UInt, Sendable, Hashable {
    case OK = 0
    case valueOutsideRange = 1
    case invalidAuthentication = 2
    case noFailSafe = 3
    case busyWithOtherAdmin = 4
}

public enum MTRGeneralCommissioningRegulatoryLocationType: UInt, Sendable, Hashable {
    case indoor = 0
    case outdoor = 1
    case indoorOutdoor = 2
}

public enum MTRGeneralDiagnosticsBootReason: UInt, Sendable, Hashable {
    case unspecified = 0
    case powerOnReboot = 1
    case brownOutReset = 2
    case softwareWatchdogReset = 3
    case hardwareWatchdogReset = 4
    case softwareUpdateCompleted = 5
    case softwareReset = 6
}

public enum MTRGeneralDiagnosticsBootReasonType: UInt, Sendable, Hashable {
    case unspecified = 0
    case powerOnReboot = 1
    case brownOutReset = 2
    case softwareWatchdogReset = 3
    case hardwareWatchdogReset = 4
    case softwareUpdateCompleted = 5
    case softwareReset = 6
}

public enum MTRGeneralDiagnosticsHardwareFault: UInt, Sendable, Hashable {
    case unspecified = 0
    case radio = 1
    case sensor = 2
    case resettableOverTemp = 3
    case nonResettableOverTemp = 4
    case powerSource = 5
    case visualDisplayFault = 6
    case audioOutputFault = 7
    case userInterfaceFault = 8
    case nonVolatileMemoryError = 9
    case tamperDetected = 10
}

public enum MTRGeneralDiagnosticsHardwareFaultType: UInt, Sendable, Hashable {
    case unspecified = 0
    case radio = 1
    case sensor = 2
    case resettableOverTemp = 3
    case nonResettableOverTemp = 4
    case powerSource = 5
    case visualDisplayFault = 6
    case audioOutputFault = 7
    case userInterfaceFault = 8
    case nonVolatileMemoryError = 9
    case tamperDetected = 10
}

public enum MTRGeneralDiagnosticsInterfaceType: UInt, Sendable, Hashable {
    case unspecified = 0
    case wiFi = 1
    case ethernet = 2
    case cellular = 3
    case thread = 4
}

public enum MTRGeneralDiagnosticsNetworkFault: UInt, Sendable, Hashable {
    case unspecified = 0
    case hardwareFailure = 1
    case networkJammed = 2
    case connectionFailed = 3
}

public enum MTRGeneralDiagnosticsNetworkFaultType: UInt, Sendable, Hashable {
    case unspecified = 0
    case hardwareFailure = 1
    case networkJammed = 2
    case connectionFailed = 3
}

public enum MTRGeneralDiagnosticsRadioFault: UInt, Sendable, Hashable {
    case unspecified = 0
    case wiFiFault = 1
    case cellularFault = 2
    case threadFault = 3
    case nfcFault = 4
    case bleFault = 5
    case ethernetFault = 6
}

public enum MTRGeneralDiagnosticsRadioFaultType: UInt, Sendable, Hashable {
    case unspecified = 0
    case wiFiFault = 1
    case cellularFault = 2
    case threadFault = 3
    case nfcFault = 4
    case bleFault = 5
    case ethernetFault = 6
}

public enum MTRGroupKeyManagementGroupKeySecurityPolicy: UInt, Sendable, Hashable {
    case trustFirst = 0
    case cacheAndSync = 1
}

public enum MTRHEPAFilterMonitoringChangeIndication: UInt, Sendable, Hashable {
    case OK = 0
    case warning = 1
    case critical = 2
}

public enum MTRHEPAFilterMonitoringDegradationDirection: UInt, Sendable, Hashable {
    case up = 0
    case down = 1
}

public enum MTRHEPAFilterMonitoringProductIdentifierType: UInt, Sendable, Hashable {
    case UPC = 0
    case GTIN8 = 1
    case EAN = 2
    case GTIN14 = 3
    case OEM = 4
}

public enum MTRICDManagementClientType: UInt, Sendable, Hashable {
    case permanent = 0
    case ephemeral = 1
}

public enum MTRICDManagementOperatingMode: UInt, Sendable, Hashable {
    case SIT = 0
    case LIT = 1
}

public enum MTRIdentifyEffectIdentifier: UInt, Sendable, Hashable {
    case blink = 0
    case breathe = 1
    case okay = 2
    case channelChange = 3
    case finishEffect = 4
    case stopEffect = 5
}

public enum MTRIdentifyEffectVariant: UInt, Sendable, Hashable {
    case `default` = 0
}

public enum MTRIdentifyType: UInt, Sendable, Hashable {
    case none = 0
    case lightOutput = 1
    case visibleIndicator = 2
    case audibleBeep = 3
    case display = 4
    case actuator = 5
}

public enum MTRIlluminanceMeasurementLightSensorType: UInt, Sendable, Hashable {
    case photodiode = 0
    case CMOS = 1
}

public enum MTRKeypadInputCECKeyCode: UInt, Sendable, Hashable {
    case select = 0
    case up = 1
    case down = 2
    case left = 3
    case right = 4
    case rightUp = 5
    case rightDown = 6
    case leftUp = 7
    case leftDown = 8
    case rootMenu = 9
    case setupMenu = 10
    case contentsMenu = 11
    case favoriteMenu = 12
    case exit = 13
    case mediaTopMenu = 14
    case mediaContextSensitiveMenu = 15
    case numberEntryMode = 16
    case number11 = 17
    case number12 = 18
    case number0OrNumber10 = 19
    case numbers1 = 20
    case numbers2 = 21
    case numbers3 = 22
    case numbers4 = 23
    case numbers5 = 24
    case numbers6 = 25
    case numbers7 = 26
    case numbers8 = 27
    case numbers9 = 28
    case dot = 29
    case enter = 30
    case clear = 31
    case nextFavorite = 32
    case channelUp = 33
    case channelDown = 34
    case previousChannel = 35
    case soundSelect = 36
    case inputSelect = 37
    case displayInformation = 38
    case help = 39
    case pageUp = 40
    case pageDown = 41
    case power = 42
    case volumeUp = 43
    case volumeDown = 44
    case mute = 45
    case play = 46
    case stop = 47
    case pause = 48
    case record = 49
    case rewind = 50
    case fastForward = 51
    case eject = 52
    case forward = 53
    case backward = 54
    case stopRecord = 55
    case pauseRecord = 56
    case reserved = 57
    case angle = 58
    case subPicture = 59
    case videoOnDemand = 60
    case electronicProgramGuide = 61
    case timerProgramming = 62
    case initialConfiguration = 63
    case selectBroadcastType = 64
    case selectSoundPresentation = 65
    case playFunction = 66
    case pausePlayFunction = 67
    case recordFunction = 68
    case pauseRecordFunction = 69
    case stopFunction = 70
    case muteFunction = 71
    case restoreVolumeFunction = 72
    case tuneFunction = 73
    case selectMediaFunction = 74
    case selectAvInputFunction = 75
    case selectAudioInputFunction = 76
    case powerToggleFunction = 77
    case powerOffFunction = 78
    case powerOnFunction = 79
    case f1Blue = 80
    case f2Red = 81
    case f3Green = 82
    case f4Yellow = 83
    case F5 = 84
    case data = 85
}

public enum MTRKeypadInputCecKeyCode: UInt, Sendable, Hashable {
    case select = 0
    case up = 1
    case down = 2
    case left = 3
    case right = 4
    case rightUp = 5
    case rightDown = 6
    case leftUp = 7
    case leftDown = 8
    case rootMenu = 9
    case setupMenu = 10
    case contentsMenu = 11
    case favoriteMenu = 12
    case exit = 13
    case mediaTopMenu = 14
    case mediaContextSensitiveMenu = 15
    case numberEntryMode = 16
    case number11 = 17
    case number12 = 18
    case number0OrNumber10 = 19
    case numbers1 = 20
    case numbers2 = 21
    case numbers3 = 22
    case numbers4 = 23
    case numbers5 = 24
    case numbers6 = 25
    case numbers7 = 26
    case numbers8 = 27
    case numbers9 = 28
    case dot = 29
    case enter = 30
    case clear = 31
    case nextFavorite = 32
    case channelUp = 33
    case channelDown = 34
    case previousChannel = 35
    case soundSelect = 36
    case inputSelect = 37
    case displayInformation = 38
    case help = 39
    case pageUp = 40
    case pageDown = 41
    case power = 42
    case volumeUp = 43
    case volumeDown = 44
    case mute = 45
    case play = 46
    case stop = 47
    case pause = 48
    case record = 49
    case rewind = 50
    case fastForward = 51
    case eject = 52
    case forward = 53
    case backward = 54
    case stopRecord = 55
    case pauseRecord = 56
    case reserved = 57
    case angle = 58
    case subPicture = 59
    case videoOnDemand = 60
    case electronicProgramGuide = 61
    case timerProgramming = 62
    case initialConfiguration = 63
    case selectBroadcastType = 64
    case selectSoundPresentation = 65
    case playFunction = 66
    case pausePlayFunction = 67
    case recordFunction = 68
    case pauseRecordFunction = 69
    case stopFunction = 70
    case muteFunction = 71
    case restoreVolumeFunction = 72
    case tuneFunction = 73
    case selectMediaFunction = 74
    case selectAvInputFunction = 75
    case selectAudioInputFunction = 76
    case powerToggleFunction = 77
    case powerOffFunction = 78
    case powerOnFunction = 79
    case f1Blue = 80
    case f2Red = 81
    case f3Green = 82
    case f4Yellow = 83
    case F5 = 84
    case data = 85
}

public enum MTRKeypadInputStatus: UInt, Sendable, Hashable {
    case success = 0
    case unsupportedKey = 1
    case invalidKeyInCurrentState = 2
}

public enum MTRLaundryDryerControlsDrynessLevel: UInt, Sendable, Hashable {
    case low = 0
    case normal = 1
    case extra = 2
    case max = 3
}

public enum MTRLaundryWasherControlsNumberOfRinses: UInt, Sendable, Hashable {
    case none = 0
    case normal = 1
    case extra = 2
    case max = 3
}

public enum MTRLaundryWasherModeModeTag: UInt8, Sendable, Hashable {
    case auto = 0
    case quick = 1
    case quiet = 2
    case lowNoise = 3
    case lowEnergy = 4
    case vacation = 5
    case min = 6
    case max = 7
    case night = 8
    case day = 9
    case normal = 10
    case delicate = 11
    case heavy = 12
    case whites = 13
}

public enum MTRLevelControlMoveMode: UInt, Sendable, Hashable {
    case up = 0
    case down = 1
}

public enum MTRLevelControlStepMode: UInt, Sendable, Hashable {
    case up = 0
    case down = 1
}

public enum MTRMediaInputInputType: UInt, Sendable, Hashable {
    case `internal` = 0
    case aux = 1
    case coax = 2
    case composite = 3
    case HDMI = 4
    case input = 5
    case line = 6
    case optical = 7
    case video = 8
    case SCART = 9
    case USB = 10
    case other = 11
}

public enum MTRMediaPlaybackCharacteristic: UInt, Sendable, Hashable {
    case forcedSubtitles = 0
    case describesVideo = 1
    case easyToRead = 2
    case frameBased = 3
    case mainProgram = 4
    case originalContent = 5
    case voiceOverTranslation = 6
    case caption = 7
    case subtitle = 8
    case alternate = 9
    case supplementary = 10
    case commentary = 11
    case dubbedTranslation = 12
    case description = 13
    case metadata = 14
    case enhancedAudioIntelligibility = 15
    case emergency = 16
    case karaoke = 17
}

public enum MTRMediaPlaybackPlaybackState: UInt, Sendable, Hashable {
    case playing = 0
    case paused = 1
    case notPlaying = 2
    case buffering = 3
}

public enum MTRMediaPlaybackStatus: UInt, Sendable, Hashable {
    case success = 0
    case invalidStateForCommand = 1
    case notAllowed = 2
    case notActive = 3
    case speedOutOfRange = 4
    case seekOutOfRange = 5
}

public enum MTRMessagesFutureMessagePreference: UInt, Sendable, Hashable {
    case allowed = 0
    case increased = 1
    case reduced = 2
    case disallowed = 3
    case banned = 4
}

public enum MTRMessagesMessagePriority: UInt, Sendable, Hashable {
    case low = 0
    case medium = 1
    case high = 2
    case critical = 3
}

public enum MTRMicrowaveOvenModeModeTag: UInt8, Sendable, Hashable {
    case auto = 0
    case quick = 1
    case quiet = 2
    case lowNoise = 3
    case lowEnergy = 4
    case vacation = 5
    case min = 6
    case max = 7
    case night = 8
    case day = 9
    case normal = 10
    case defrost = 11
}

public enum MTRNetworkCommissioningStatus: UInt, Sendable, Hashable {
    case success = 0
    case outOfRange = 1
    case boundsExceeded = 2
    case networkIDNotFound = 3
    case duplicateNetworkID = 4
    case networkNotFound = 5
    case regulatoryError = 6
    case authFailure = 7
    case unsupportedSecurity = 8
    case otherConnectionFailure = 9
    case ipv6Failed = 10
    case ipBindFailed = 11
    case unknownError = 12
}

public enum MTRNetworkCommissioningWiFiBand: UInt, Sendable, Hashable {
    case band2G4 = 0
    case band3G65 = 1
    case band5G = 2
    case band6G = 3
    case band60G = 4
    case band1G = 5
}

public enum MTRNitrogenDioxideConcentrationMeasurementLevelValue: UInt, Sendable, Hashable {
    case unknown = 0
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
}

public enum MTRNitrogenDioxideConcentrationMeasurementMeasurementMedium: UInt, Sendable, Hashable {
    case air = 0
    case water = 1
    case soil = 2
}

public enum MTRNitrogenDioxideConcentrationMeasurementMeasurementUnit: UInt, Sendable, Hashable {
    case PPM = 0
    case PPB = 1
    case PPT = 2
    case MGM3 = 3
    case UGM3 = 4
    case NGM3 = 5
    case PM3 = 6
    case BQM3 = 7
}

public enum MTROTASoftwareUpdateProviderApplyUpdateAction: UInt, Sendable, Hashable {
    case proceed = 0
    case awaitNextAction = 1
    case discontinue = 2
}

public enum MTROTASoftwareUpdateProviderDownloadProtocol: UInt, Sendable, Hashable {
    case bdxSynchronous = 0
    case bdxAsynchronous = 1
    case HTTPS = 2
    case vendorSpecific = 3
}

public enum MTROTASoftwareUpdateProviderStatus: UInt, Sendable, Hashable {
    case updateAvailable = 0
    case busy = 1
    case notAvailable = 2
    case downloadProtocolNotSupported = 3
}

public enum MTROTASoftwareUpdateRequestorAnnouncementReason: UInt, Sendable, Hashable {
    case simpleAnnouncement = 0
    case updateAvailable = 1
    case urgentUpdateAvailable = 2
}

public enum MTROTASoftwareUpdateRequestorChangeReason: UInt, Sendable, Hashable {
    case unknown = 0
    case success = 1
    case failure = 2
    case timeOut = 3
    case delayByProvider = 4
}

public enum MTROTASoftwareUpdateRequestorUpdateState: UInt, Sendable, Hashable {
    case unknown = 0
    case idle = 1
    case querying = 2
    case delayedOnQuery = 3
    case downloading = 4
    case applying = 5
    case delayedOnApply = 6
    case rollingBack = 7
    case delayedOnUserConsent = 8
}

public enum MTROccupancySensingOccupancySensorType: UInt, Sendable, Hashable {
    case PIR = 0
    case ultrasonic = 1
    case pirAndUltrasonic = 2
    case physicalContact = 3
}

public enum MTROnOffDelayedAllOffEffectVariant: UInt, Sendable, Hashable {
    case delayedOffFastFade = 0
    case noFade = 1
    case delayedOffSlowFade = 2
}

public enum MTROnOffDyingLightEffectVariant: UInt, Sendable, Hashable {
    case dyingLightFadeOff = 0
}

public enum MTROnOffEffectIdentifier: UInt, Sendable, Hashable {
    case delayedAllOff = 0
    case dyingLight = 1
}

public enum MTROnOffStartUpOnOff: UInt, Sendable, Hashable {
    case off = 0
    case on = 1
    case toggle = 2
}

public enum MTROperationalCredentialsCertificateChainType: UInt, Sendable, Hashable {
    case dacCertificate = 0
    case paiCertificate = 1
}

public enum MTROperationalCredentialsNodeOperationalCertStatus: UInt, Sendable, Hashable {
    case OK = 0
    case invalidPublicKey = 1
    case invalidNodeOpId = 2
    case invalidNOC = 3
    case missingCsr = 4
    case tableFull = 5
    case invalidAdminSubject = 6
    case fabricConflict = 7
    case labelConflict = 8
    case invalidFabricIndex = 9
}

public enum MTROperationalCredentialsOperationalCertStatus: UInt, Sendable, Hashable {
    case SUCCESS = 0
    case invalidPublicKey = 1
    case invalidNodeOpId = 2
    case invalidNOC = 3
    case missingCsr = 4
    case tableFull = 5
    case invalidAdminSubject = 6
    case fabricConflict = 7
    case labelConflict = 8
    case invalidFabricIndex = 9
}

public enum MTROperationalState: UInt, Sendable, Hashable {
    case stopped = 0
    case running = 1
    case paused = 2
    case error = 3
}

public enum MTROperationalStateErrorState: UInt, Sendable, Hashable {
    case noError = 0
    case unableToStartOrResume = 1
    case unableToCompleteOperation = 2
    case commandInvalidInState = 3
}

public enum MTROtaSoftwareUpdateProviderOTAApplyUpdateAction: UInt, Sendable, Hashable {
    case proceed = 0
    case awaitNextAction = 1
    case discontinue = 2
}

public enum MTROtaSoftwareUpdateProviderOTADownloadProtocol: UInt, Sendable, Hashable {
    case bdxSynchronous = 0
    case bdxAsynchronous = 1
    case HTTPS = 2
    case vendorSpecific = 3
}

public enum MTROtaSoftwareUpdateProviderOTAQueryStatus: UInt, Sendable, Hashable {
    case updateAvailable = 0
    case busy = 1
    case notAvailable = 2
    case downloadProtocolNotSupported = 3
}

public enum MTROtaSoftwareUpdateRequestorOTAAnnouncementReason: UInt, Sendable, Hashable {
    case simpleAnnouncement = 0
    case updateAvailable = 1
    case urgentUpdateAvailable = 2
}

public enum MTROtaSoftwareUpdateRequestorOTAChangeReason: UInt, Sendable, Hashable {
    case unknown = 0
    case success = 1
    case failure = 2
    case timeOut = 3
    case delayByProvider = 4
}

public enum MTROtaSoftwareUpdateRequestorOTAUpdateState: UInt, Sendable, Hashable {
    case unknown = 0
    case idle = 1
    case querying = 2
    case delayedOnQuery = 3
    case downloading = 4
    case applying = 5
    case delayedOnApply = 6
    case rollingBack = 7
    case delayedOnUserConsent = 8
}

public enum MTROvenCavityOperationalStateErrorState: UInt, Sendable, Hashable {
    case noError = 0
    case unableToStartOrResume = 1
    case unableToCompleteOperation = 2
    case commandInvalidInState = 3
}

public enum MTROvenCavityOperationalStateOperationalState: UInt, Sendable, Hashable {
    case stopped = 0
    case running = 1
    case paused = 2
    case error = 3
}

public enum MTROvenModeModeTag: UInt8, Sendable, Hashable {
    case auto = 0
    case quick = 1
    case quiet = 2
    case lowNoise = 3
    case lowEnergy = 4
    case vacation = 5
    case min = 6
    case max = 7
    case night = 8
    case day = 9
    case bake = 10
    case convection = 11
    case grill = 12
    case roast = 13
    case clean = 14
    case convectionBake = 15
    case convectionRoast = 16
    case warming = 17
    case proofing = 18
}

public enum MTROzoneConcentrationMeasurementLevelValue: UInt, Sendable, Hashable {
    case unknown = 0
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
}

public enum MTROzoneConcentrationMeasurementMeasurementMedium: UInt, Sendable, Hashable {
    case air = 0
    case water = 1
    case soil = 2
}

public enum MTROzoneConcentrationMeasurementMeasurementUnit: UInt, Sendable, Hashable {
    case PPM = 0
    case PPB = 1
    case PPT = 2
    case MGM3 = 3
    case UGM3 = 4
    case NGM3 = 5
    case PM3 = 6
    case BQM3 = 7
}

public enum MTRPM10ConcentrationMeasurementLevelValue: UInt, Sendable, Hashable {
    case unknown = 0
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
}

public enum MTRPM10ConcentrationMeasurementMeasurementMedium: UInt, Sendable, Hashable {
    case air = 0
    case water = 1
    case soil = 2
}

public enum MTRPM10ConcentrationMeasurementMeasurementUnit: UInt, Sendable, Hashable {
    case PPM = 0
    case PPB = 1
    case PPT = 2
    case MGM3 = 3
    case UGM3 = 4
    case NGM3 = 5
    case PM3 = 6
    case BQM3 = 7
}

public enum MTRPM1ConcentrationMeasurementLevelValue: UInt, Sendable, Hashable {
    case unknown = 0
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
}

public enum MTRPM1ConcentrationMeasurementMeasurementMedium: UInt, Sendable, Hashable {
    case air = 0
    case water = 1
    case soil = 2
}

public enum MTRPM1ConcentrationMeasurementMeasurementUnit: UInt, Sendable, Hashable {
    case PPM = 0
    case PPB = 1
    case PPT = 2
    case MGM3 = 3
    case UGM3 = 4
    case NGM3 = 5
    case PM3 = 6
    case BQM3 = 7
}

public enum MTRPM25ConcentrationMeasurementLevelValue: UInt, Sendable, Hashable {
    case unknown = 0
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
}

public enum MTRPM25ConcentrationMeasurementMeasurementMedium: UInt, Sendable, Hashable {
    case air = 0
    case water = 1
    case soil = 2
}

public enum MTRPM25ConcentrationMeasurementMeasurementUnit: UInt, Sendable, Hashable {
    case PPM = 0
    case PPB = 1
    case PPT = 2
    case MGM3 = 3
    case UGM3 = 4
    case NGM3 = 5
    case PM3 = 6
    case BQM3 = 7
}

public enum MTRPowerSourceBatApprovedChemistry: UInt, Sendable, Hashable {
    case unspecified = 0
    case alkaline = 1
    case lithiumCarbonFluoride = 2
    case lithiumChromiumOxide = 3
    case lithiumCopperOxide = 4
    case lithiumIronDisulfide = 5
    case lithiumManganeseDioxide = 6
    case lithiumThionylChloride = 7
    case magnesium = 8
    case mercuryOxide = 9
    case nickelOxyhydride = 10
    case silverOxide = 11
    case zincAir = 12
    case zincCarbon = 13
    case zincChloride = 14
    case zincManganeseDioxide = 15
    case leadAcid = 16
    case lithiumCobaltOxide = 17
    case lithiumIon = 18
    case lithiumIonPolymer = 19
    case lithiumIronPhosphate = 20
    case lithiumSulfur = 21
    case lithiumTitanate = 22
    case nickelCadmium = 23
    case nickelHydrogen = 24
    case nickelIron = 25
    case nickelMetalHydride = 26
    case nickelZinc = 27
    case silverZinc = 28
    case sodiumIon = 29
    case sodiumSulfur = 30
    case zincBromide = 31
    case zincCerium = 32
}

public enum MTRPowerSourceBatChargeFault: UInt, Sendable, Hashable {
    case unspecified = 0
    case ambientTooHot = 1
    case ambientTooCold = 2
    case batteryTooHot = 3
    case batteryTooCold = 4
    case batteryAbsent = 5
    case batteryOverVoltage = 6
    case batteryUnderVoltage = 7
    case chargerOverVoltage = 8
    case chargerUnderVoltage = 9
    case safetyTimeout = 10
}

public enum MTRPowerSourceBatChargeLevel: UInt, Sendable, Hashable {
    case OK = 0
    case warning = 1
    case critical = 2
}

public enum MTRPowerSourceBatChargeState: UInt, Sendable, Hashable {
    case unknown = 0
    case isCharging = 1
    case isAtFullCharge = 2
    case isNotCharging = 3
}

public enum MTRPowerSourceBatCommonDesignation: UInt, Sendable, Hashable {
    case designationUnspecified = 0
    case designationAAA = 1
    case designationAA = 2
    case designationC = 3
    case designationD = 4
    case designation4v5 = 5
    case designation6v0 = 6
    case designation9v0 = 7
    case designation12AA = 8
    case designationAAAA = 9
    case designationA = 10
    case designationB = 11
    case designationF = 12
    case designationN = 13
    case designationNo6 = 14
    case designationSubC = 15
    case designationA23 = 16
    case designationA27 = 17
    case designationBA5800 = 18
    case designationDuplex = 19
    case designation4SR44 = 20
    case designation523 = 21
    case designation531 = 22
    case designation15v0 = 23
    case designation22v5 = 24
    case designation30v0 = 25
    case designation45v0 = 26
    case designation67v5 = 27
    case designationJ = 28
    case designationCR123A = 29
    case designationCR2 = 30
    case designation2CR5 = 31
    case designationCRP2 = 32
    case designationCRV3 = 33
    case designationSR41 = 34
    case designationSR43 = 35
    case designationSR44 = 36
    case designationSR45 = 37
    case designationSR48 = 38
    case designationSR54 = 39
    case designationSR55 = 40
    case designationSR57 = 41
    case designationSR58 = 42
    case designationSR59 = 43
    case designationSR60 = 44
    case designationSR63 = 45
    case designationSR64 = 46
    case designationSR65 = 47
    case designationSR66 = 48
    case designationSR67 = 49
    case designationSR68 = 50
    case designationSR69 = 51
    case designationSR516 = 52
    case designationSR731 = 53
    case designationSR712 = 54
    case designationLR932 = 55
    case designationA5 = 56
    case designationA10 = 57
    case designationA13 = 58
    case designationA312 = 59
    case designationA675 = 60
    case designationAC41E = 61
    case designation10180 = 62
    case designation10280 = 63
    case designation10440 = 64
    case designation14250 = 65
    case designation14430 = 66
    case designation14500 = 67
    case designation14650 = 68
    case designation15270 = 69
    case designation16340 = 70
    case designationRCR123A = 71
    case designation17500 = 72
    case designation17670 = 73
    case designation18350 = 74
    case designation18500 = 75
    case designation18650 = 76
    case designation19670 = 77
    case designation25500 = 78
    case designation26650 = 79
    case designation32600 = 80
}

public enum MTRPowerSourceBatFault: UInt, Sendable, Hashable {
    case unspecified = 0
    case overTemp = 1
    case underTemp = 2
}

public enum MTRPowerSourceBatReplaceability: UInt, Sendable, Hashable {
    case unspecified = 0
    case notReplaceable = 1
    case userReplaceable = 2
    case factoryReplaceable = 3
}

public enum MTRPowerSourceStatus: UInt, Sendable, Hashable {
    case unspecified = 0
    case active = 1
    case standby = 2
    case unavailable = 3
}

public enum MTRPowerSourceWiredCurrentType: UInt, Sendable, Hashable {
    case AC = 0
    case DC = 1
}

public enum MTRPowerSourceWiredFault: UInt, Sendable, Hashable {
    case unspecified = 0
    case overVoltage = 1
    case underVoltage = 2
}

public enum MTRPumpConfigurationAndControlControlMode: UInt, Sendable, Hashable {
    case constantSpeed = 0
    case constantPressure = 1
    case proportionalPressure = 2
    case constantFlow = 3
    case constantTemperature = 4
    case automatic = 5
}

public enum MTRPumpConfigurationAndControlOperationMode: UInt, Sendable, Hashable {
    case normal = 0
    case minimum = 1
    case maximum = 2
    case local = 3
}

public enum MTRPumpConfigurationAndControlPumpControlMode: UInt, Sendable, Hashable {
    case constantSpeed = 0
    case constantPressure = 1
    case proportionalPressure = 2
    case constantFlow = 3
    case constantTemperature = 4
    case automatic = 5
}

public enum MTRPumpConfigurationAndControlPumpOperationMode: UInt, Sendable, Hashable {
    case normal = 0
    case minimum = 1
    case maximum = 2
    case local = 3
}

public enum MTRRVCCleanModeModeTag: UInt8, Sendable, Hashable {
    case auto = 0
    case quick = 1
    case quiet = 2
    case lowNoise = 3
    case lowEnergy = 4
    case vacation = 5
    case min = 6
    case max = 7
    case night = 8
    case day = 9
    case deepClean = 10
    case vacuum = 11
    case mop = 12
}

public enum MTRRVCCleanModeStatusCode: UInt, Sendable, Hashable {
    case cleaningInProgress = 0
}

public enum MTRRVCOperationalStateErrorState: UInt, Sendable, Hashable {
    case noError = 0
    case unableToStartOrResume = 1
    case unableToCompleteOperation = 2
    case commandInvalidInState = 3
    case failedToFindChargingDock = 4
    case stuck = 5
    case dustBinMissing = 6
    case dustBinFull = 7
    case waterTankEmpty = 8
    case waterTankMissing = 9
    case waterTankLidOpen = 10
    case mopCleaningPadMissing = 11
}

public enum MTRRVCOperationalStateOperationalState: UInt, Sendable, Hashable {
    case stopped = 0
    case running = 1
    case paused = 2
    case error = 3
    case seekingCharger = 4
    case charging = 5
    case docked = 6
}

public enum MTRRVCRunModeModeTag: UInt8, Sendable, Hashable {
    case auto = 0
    case quick = 1
    case quiet = 2
    case lowNoise = 3
    case lowEnergy = 4
    case vacation = 5
    case min = 6
    case max = 7
    case night = 8
    case day = 9
    case idle = 10
    case cleaning = 11
    case mapping = 12
}

public enum MTRRVCRunModeStatusCode: UInt, Sendable, Hashable {
    case stuck = 0
    case dustBinMissing = 1
    case dustBinFull = 2
    case waterTankEmpty = 3
    case waterTankMissing = 4
    case waterTankLidOpen = 5
    case mopCleaningPadMissing = 6
    case batteryLow = 7
}

public enum MTRRadonConcentrationMeasurementLevelValue: UInt, Sendable, Hashable {
    case unknown = 0
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
}

public enum MTRRadonConcentrationMeasurementMeasurementMedium: UInt, Sendable, Hashable {
    case air = 0
    case water = 1
    case soil = 2
}

public enum MTRRadonConcentrationMeasurementMeasurementUnit: UInt, Sendable, Hashable {
    case PPM = 0
    case PPB = 1
    case PPT = 2
    case MGM3 = 3
    case UGM3 = 4
    case NGM3 = 5
    case PM3 = 6
    case BQM3 = 7
}

public enum MTRRefrigeratorAndTemperatureControlledCabinetModeModeTag: UInt8, Sendable, Hashable {
    case auto = 0
    case quick = 1
    case quiet = 2
    case lowNoise = 3
    case lowEnergy = 4
    case vacation = 5
    case min = 6
    case max = 7
    case night = 8
    case day = 9
    case rapidCool = 10
    case rapidFreeze = 11
}

public enum MTRServiceAreaOperationalStatus: UInt, Sendable, Hashable {
    case pending = 0
    case operating = 1
    case skipped = 2
    case completed = 3
}

public enum MTRServiceAreaSelectAreasStatus: UInt, Sendable, Hashable {
    case success = 0
    case unsupportedArea = 1
    case invalidInMode = 2
    case invalidSet = 3
}

public enum MTRServiceAreaSkipAreaStatus: UInt, Sendable, Hashable {
    case success = 0
    case invalidAreaList = 1
    case invalidInMode = 2
    case invalidSkippedArea = 3
}

public enum MTRSmokeCOAlarmAlarmState: UInt, Sendable, Hashable {
    case normal = 0
    case warning = 1
    case critical = 2
}

public enum MTRSmokeCOAlarmContaminationState: UInt, Sendable, Hashable {
    case normal = 0
    case low = 1
    case warning = 2
    case critical = 3
}

public enum MTRSmokeCOAlarmEndOfService: UInt, Sendable, Hashable {
    case normal = 0
    case expired = 1
}

public enum MTRSmokeCOAlarmExpressedState: UInt, Sendable, Hashable {
    case normal = 0
    case smokeAlarm = 1
    case coAlarm = 2
    case batteryAlert = 3
    case testing = 4
    case hardwareFault = 5
    case endOfService = 6
    case interconnectSmoke = 7
    case interconnectCO = 8
}

public enum MTRSmokeCOAlarmMuteState: UInt, Sendable, Hashable {
    case notMuted = 0
    case muted = 1
}

public enum MTRSmokeCOAlarmSensitivity: UInt, Sendable, Hashable {
    case high = 0
    case standard = 1
    case low = 2
}

public enum MTRTargetNavigatorStatus: UInt, Sendable, Hashable {
    case success = 0
    case targetNotFound = 1
    case notAllowed = 2
}

public enum MTRTestClusterSimple: UInt, Sendable, Hashable {
    case unspecified = 0
    case valueA = 1
    case valueB = 2
    case valueC = 3
}

public enum MTRThermostatACCapacityFormat: UInt, Sendable, Hashable {
    case btUh = 0
}

public enum MTRThermostatACCompressorType: UInt, Sendable, Hashable {
    case unknown = 0
    case T1 = 1
    case T2 = 2
    case T3 = 3
}

public enum MTRThermostatACLouverPosition: UInt, Sendable, Hashable {
    case closed = 0
    case `open` = 1
    case quarter = 2
    case half = 3
    case threeQuarters = 4
}

public enum MTRThermostatACRefrigerantType: UInt, Sendable, Hashable {
    case unknown = 0
    case R22 = 1
    case r410a = 2
    case r407c = 3
}

public enum MTRThermostatACType: UInt, Sendable, Hashable {
    case unknown = 0
    case coolingFixed = 1
    case heatPumpFixed = 2
    case coolingInverter = 3
    case heatPumpInverter = 4
}

public enum MTRThermostatControlSequence: UInt, Sendable, Hashable {
    case coolingOnly = 0
    case coolingWithReheat = 1
    case heatingOnly = 2
    case heatingWithReheat = 3
    case coolingAndHeating = 4
    case coolingAndHeatingWithReheat = 5
}

public enum MTRThermostatControlSequenceOfOperation: UInt, Sendable, Hashable {
    case coolingOnly = 0
    case coolingWithReheat = 1
    case heatingOnly = 2
    case heatingWithReheat = 3
    case coolingAndHeating = 4
    case coolingAndHeatingWithReheat = 5
}

public enum MTRThermostatPresetScenario: UInt, Sendable, Hashable {
    case occupied = 0
    case unoccupied = 1
    case sleep = 2
    case wake = 3
    case vacation = 4
    case goingToSleep = 5
    case userDefined = 6
}

public enum MTRThermostatRunningMode: UInt, Sendable, Hashable {
    case off = 0
    case cool = 1
    case heat = 2
}

public enum MTRThermostatSetpointAdjustMode: UInt, Sendable, Hashable {
    case heat = 0
    case cool = 1
    case both = 2
}

public enum MTRThermostatSetpointChangeSource: UInt, Sendable, Hashable {
    case manual = 0
    case schedule = 1
    case external = 2
}

public enum MTRThermostatSetpointRaiseLowerMode: UInt, Sendable, Hashable {
    case heat = 0
    case cool = 1
    case both = 2
}

public enum MTRThermostatStartOfWeek: UInt, Sendable, Hashable {
    case sunday = 0
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
}

public enum MTRThermostatSystemMode: UInt, Sendable, Hashable {
    case off = 0
    case auto = 1
    case cool = 2
    case heat = 3
    case emergencyHeat = 4
    case precooling = 5
    case fanOnly = 6
    case dry = 7
    case sleep = 8
}

public enum MTRThermostatTemperatureSetpointHold: UInt, Sendable, Hashable {
    case setpointHoldOff = 0
    case setpointHoldOn = 1
}

public enum MTRThermostatUserInterfaceConfigurationKeypadLockout: UInt, Sendable, Hashable {
    case noLockout = 0
    case lockout1 = 1
    case lockout2 = 2
    case lockout3 = 3
    case lockout4 = 4
    case lockout5 = 5
}

public enum MTRThermostatUserInterfaceConfigurationScheduleProgrammingVisibility: UInt, Sendable, Hashable {
    case scheduleProgrammingPermitted = 0
    case scheduleProgrammingDenied = 1
}

public enum MTRThermostatUserInterfaceConfigurationTemperatureDisplayMode: UInt, Sendable, Hashable {
    case celsius = 0
    case fahrenheit = 1
}

public enum MTRThreadNetworkDiagnosticsConnectionStatus: UInt, Sendable, Hashable {
    case connected = 0
    case notConnected = 1
}

public enum MTRThreadNetworkDiagnosticsNetworkFault: UInt, Sendable, Hashable {
    case unspecified = 0
    case linkDown = 1
    case hardwareFailure = 2
    case networkJammed = 3
}

public enum MTRThreadNetworkDiagnosticsRoutingRole: UInt, Sendable, Hashable {
    case unspecified = 0
    case unassigned = 1
    case sleepyEndDevice = 2
    case endDevice = 3
    case REED = 4
    case router = 5
    case leader = 6
}

public enum MTRThreadNetworkDiagnosticsThreadConnectionStatus: UInt, Sendable, Hashable {
    case connected = 0
    case notConnected = 1
}

public enum MTRTimeFormatLocalizationCalendarType: UInt, Sendable, Hashable {
    case buddhist = 0
    case chinese = 1
    case coptic = 2
    case ethiopian = 3
    case gregorian = 4
    case hebrew = 5
    case indian = 6
    case islamic = 7
    case japanese = 8
    case korean = 9
    case persian = 10
    case taiwanese = 11
    case useActiveLocale = 12
}

public enum MTRTimeFormatLocalizationHourFormat: UInt, Sendable, Hashable {
    case format12hr = 0
    case format24hr = 1
    case formatUseActiveLocale = 2
}

public enum MTRTimeSynchronizationGranularity: UInt, Sendable, Hashable {
    case noTimeGranularity = 0
    case minutesGranularity = 1
    case secondsGranularity = 2
    case millisecondsGranularity = 3
    case microsecondsGranularity = 4
}

public enum MTRTimeSynchronizationStatusCode: UInt, Sendable, Hashable {
    case timeNotAccepted = 0
}

public enum MTRTimeSynchronizationTimeSource: UInt, Sendable, Hashable {
    case none = 0
    case unknown = 1
    case admin = 2
    case nodeTimeCluster = 3
    case nonMatterSNTP = 4
    case nonMatterNTP = 5
    case matterSNTP = 6
    case matterNTP = 7
    case mixedNTP = 8
    case nonMatterSNTPNTS = 9
    case nonMatterNTPNTS = 10
    case matterSNTPNTS = 11
    case matterNTPNTS = 12
    case mixedNTPNTS = 13
    case cloudSource = 14
    case PTP = 15
    case GNSS = 16
}

public enum MTRTimeSynchronizationTimeZoneDatabase: UInt, Sendable, Hashable {
    case full = 0
    case partial = 1
    case none = 2
}

public enum MTRTotalVolatileOrganicCompoundsConcentrationMeasurementLevelValue: UInt, Sendable, Hashable {
    case unknown = 0
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
}

public enum MTRTotalVolatileOrganicCompoundsConcentrationMeasurementMeasurementMedium: UInt, Sendable, Hashable {
    case air = 0
    case water = 1
    case soil = 2
}

public enum MTRTotalVolatileOrganicCompoundsConcentrationMeasurementMeasurementUnit: UInt, Sendable, Hashable {
    case PPM = 0
    case PPB = 1
    case PPT = 2
    case MGM3 = 3
    case UGM3 = 4
    case NGM3 = 5
    case PM3 = 6
    case BQM3 = 7
}

public enum MTRUnitLocalizationTempUnit: UInt, Sendable, Hashable {
    case fahrenheit = 0
    case celsius = 1
    case kelvin = 2
}

public enum MTRUnitTestingSimple: UInt, Sendable, Hashable {
    case unspecified = 0
    case valueA = 1
    case valueB = 2
    case valueC = 3
}

public enum MTRValveConfigurationAndControlStatusCode: UInt, Sendable, Hashable {
    case failureDueToFault = 0
}

public enum MTRValveConfigurationAndControlValveState: UInt, Sendable, Hashable {
    case closed = 0
    case `open` = 1
    case transitioning = 2
}

public enum MTRWaterHeaterManagementBoostState: UInt, Sendable, Hashable {
    case inactive = 0
    case active = 1
}

public enum MTRWaterHeaterModeModeTag: UInt8, Sendable, Hashable {
    case auto = 0
    case quick = 1
    case quiet = 2
    case lowNoise = 3
    case lowEnergy = 4
    case vacation = 5
    case min = 6
    case max = 7
    case night = 8
    case day = 9
    case off = 10
    case manual = 11
    case timed = 12
}

public enum MTRWiFiNetworkDiagnosticsAssociationFailureCause: UInt, Sendable, Hashable {
    case unknown = 0
    case associationFailed = 1
    case authenticationFailed = 2
    case ssidNotFound = 3
}

public enum MTRWiFiNetworkDiagnosticsConnectionStatus: UInt, Sendable, Hashable {
    case connected = 0
    case notConnected = 1
}

public enum MTRWiFiNetworkDiagnosticsSecurityType: UInt, Sendable, Hashable {
    case unspecified = 0
    case none = 1
    case WEP = 2
    case WPA = 3
    case WPA2 = 4
    case WPA3 = 5
}

public enum MTRWiFiNetworkDiagnosticsWiFiConnectionStatus: UInt, Sendable, Hashable {
    case connected = 0
    case notConnected = 1
}

public enum MTRWiFiNetworkDiagnosticsWiFiVersion: UInt, Sendable, Hashable {
    case a = 0
    case b = 1
    case g = 2
    case n = 3
    case ac = 4
    case ax = 5
    case ah = 6
}

public enum MTRWiFiNetworkDiagnosticsWiFiVersionType: UInt, Sendable, Hashable {
    case A = 0
    case B = 1
    case G = 2
    case N = 3
    case ac = 4
    case ax = 5
}

public enum MTRWindowCoveringEndProductType: UInt, Sendable, Hashable {
    case rollerShade = 0
    case romanShade = 1
    case balloonShade = 2
    case wovenWood = 3
    case pleatedShade = 4
    case cellularShade = 5
    case layeredShade = 6
    case layeredShade2D = 7
    case sheerShade = 8
    case tiltOnlyInteriorBlind = 9
    case interiorBlind = 10
    case verticalBlindStripCurtain = 11
    case interiorVenetianBlind = 12
    case exteriorVenetianBlind = 13
    case lateralLeftCurtain = 14
    case lateralRightCurtain = 15
    case centralCurtain = 16
    case rollerShutter = 17
    case exteriorVerticalScreen = 18
    case awningTerracePatio = 19
    case awningVerticalScreen = 20
    case tiltOnlyPergola = 21
    case swingingShutter = 22
    case slidingShutter = 23
    case unknown = 24
}

public enum MTRWindowCoveringType: UInt, Sendable, Hashable {
    case rollerShade = 0
    case rollerShade2Motor = 1
    case rollerShadeExterior = 2
    case rollerShadeExterior2Motor = 3
    case drapery = 4
    case awning = 5
    case shutter = 6
    case tiltBlindTiltOnly = 7
    case tiltBlindLiftAndTilt = 8
    case projectorScreen = 9
    case unknown = 10
}

