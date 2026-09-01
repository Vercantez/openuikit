// Public HealthKit enumerations. Raw values follow the documented
// NS_ENUM layout from the iPhoneOS 26.1 HealthKit headers.

import Foundation

public enum HKActivityMoveMode: Int, Sendable, Hashable {
    case activeEnergy = 1
    case appleMoveTime = 2
}

public enum HKAppleECGAlgorithmVersion: Int, Sendable, Hashable {
    case version1 = 1
    case version2 = 2
}

public enum HKAppleSleepingBreathingDisturbancesClassification: Int, Sendable, Hashable {
    case elevated = 2
    case notElevated = 1
    public static var allCases: [HKAppleSleepingBreathingDisturbancesClassification] { [.notElevated, .elevated] }
}

public enum HKAppleWalkingSteadinessClassification: Int, Sendable, Hashable {
    case low = 2
    case ok = 1
    case veryLow = 3
    public static var allCases: [HKAppleWalkingSteadinessClassification] { [.ok, .low, .veryLow] }
}

public enum HKAudiogramConductionType: Int, Sendable, Hashable {
    case air = 0
}

public enum HKAudiogramSensitivityTestSide: Int, Sendable, Hashable {
    case left = 0
    case right = 1
}

public enum HKAuthorizationRequestStatus: Int, Sendable, Hashable {
    case shouldRequest = 1
    case unknown = 0
    case unnecessary = 2
}

public enum HKAuthorizationStatus: Int, Sendable, Hashable {
    case notDetermined = 0
    case sharingAuthorized = 2
    case sharingDenied = 1
}

public enum HKBiologicalSex: Int, Sendable, Hashable {
    case female = 1
    case male = 2
    case notSet = 0
    case other = 3
}

public enum HKBloodGlucoseMealTime: Int, Sendable, Hashable {
    case postprandial = 2
    case preprandial = 1
}

public enum HKBloodType: Int, Sendable, Hashable {
    case abNegative = 6
    case abPositive = 5
    case aNegative = 2
    case aPositive = 1
    case bNegative = 4
    case bPositive = 3
    case notSet = 0
    case oNegative = 8
    case oPositive = 7
}

public enum HKBodyTemperatureSensorLocation: Int, Sendable, Hashable {
    case armpit = 1
    case body = 2
    case ear = 3
    case earDrum = 9
    case finger = 4
    case forehead = 11
    case gastroIntestinal = 5
    case mouth = 6
    case other = 0
    case rectum = 7
    case temporalArtery = 10
    case toe = 8
}

public enum HKCategoryValue: Int, Sendable, Hashable {
    case notApplicable = 0
}

public enum HKCategoryValueAppetiteChanges: Int, Sendable, Hashable {
    case decreased = 2
    case increased = 3
    case noChange = 1
    case unspecified = 0
}

public enum HKCategoryValueAppleStandHour: Int, Sendable, Hashable {
    case idle = 0
    case stood = 1
}

public enum HKCategoryValueAppleWalkingSteadinessEvent: Int, Sendable, Hashable {
    case initialLow = 1
    case initialVeryLow = 2
    case repeatLow = 3
    case repeatVeryLow = 4
}

public enum HKCategoryValueAudioExposureEvent: Int, Sendable, Hashable {
    case loudEnvironment = 1
}

public enum HKCategoryValueCervicalMucusQuality: Int, Sendable, Hashable {
    case creamy = 3
    case dry = 1
    case eggWhite = 5
    case sticky = 2
    case watery = 4
}

public enum HKCategoryValueContraceptive: Int, Sendable, Hashable {
    case implant = 1
    case injection = 2
    case intrauterineDevice = 3
    case intravaginalRing = 4
    case oral = 5
    case patch = 6
    case unspecified = 0
}

public enum HKCategoryValueEnvironmentalAudioExposureEvent: Int, Sendable, Hashable {
    case momentaryLimit = 1
}

public enum HKCategoryValueHeadphoneAudioExposureEvent: Int, Sendable, Hashable {
    case sevenDayLimit = 1
}

public enum HKCategoryValueLowCardioFitnessEvent: Int, Sendable, Hashable {
    case lowFitness = 1
}

public enum HKCategoryValueMenstrualFlow: Int, Sendable, Hashable {
    case heavy = 4
    case light = 2
    case medium = 3
    case none = 1
    case unspecified = 0
}

public enum HKCategoryValueOvulationTestResult: Int, Sendable, Hashable {
    case estrogenSurge = 4
    case indeterminate = 3
    case luteinizingHormoneSurge = 2
    case negative = 1
    public static var positive: HKCategoryValueOvulationTestResult { .luteinizingHormoneSurge }
}

public enum HKCategoryValuePregnancyTestResult: Int, Sendable, Hashable {
    case indeterminate = 3
    case negative = 1
    case positive = 2
}

public enum HKCategoryValuePresence: Int, Sendable, Hashable {
    case notPresent = 1
    case present = 0
}

public enum HKCategoryValueProgesteroneTestResult: Int, Sendable, Hashable {
    case indeterminate = 3
    case negative = 1
    case positive = 2
}

public enum HKCategoryValueSeverity: Int, Sendable, Hashable {
    case mild = 2
    case moderate = 3
    case notPresent = 1
    case severe = 4
    case unspecified = 0
}

public enum HKCategoryValueSleepAnalysis: Int, Sendable, Hashable {
    case asleepCore = 3
    case asleepDeep = 4
    case asleepREM = 5
    case asleepUnspecified = 1
    case awake = 2
    case inBed = 0
    public static var asleep: HKCategoryValueSleepAnalysis { .asleepUnspecified }
    public static var allAsleepValues: Set<HKCategoryValueSleepAnalysis> {
        [.asleepUnspecified, .asleepCore, .asleepDeep, .asleepREM]
    }
}

public enum HKCategoryValueVaginalBleeding: Int, Sendable, Hashable {
    case heavy = 4
    case light = 2
    case medium = 3
    case none = 1
    case unspecified = 0
}

public enum HKCyclingFunctionalThresholdPowerTestType: Int, Sendable, Hashable {
    case maxExercise20Minute = 2
    case maxExercise60Minute = 1
    case predictionExercise = 4
    case rampTest = 3
}

public enum HKDevicePlacementSide: Int, Sendable, Hashable {
    case central = 3
    case left = 1
    case right = 2
    case unknown = 0
}

public enum HKFitzpatrickSkinType: Int, Sendable, Hashable {
    case I = 1
    case II = 2
    case III = 3
    case IV = 4
    case notSet = 0
    case V = 5
    case VI = 6
}

public enum HKHeartRateMotionContext: Int, Sendable, Hashable {
    case active = 2
    case notSet = 0
    case sedentary = 1
}

public enum HKHeartRateRecoveryTestType: Int, Sendable, Hashable {
    case maxExercise = 1
    case predictionNonExercise = 3
    case predictionSubMaxExercise = 2
}

public enum HKHeartRateSensorLocation: Int, Sendable, Hashable {
    case chest = 1
    case earLobe = 5
    case finger = 3
    case foot = 6
    case hand = 4
    case other = 0
    case wrist = 2
}

public enum HKInsulinDeliveryReason: Int, Sendable, Hashable {
    case basal = 1
    case bolus = 2
}

public enum HKMetricPrefix: Int, Sendable, Hashable {
    case centi = 5
    case deca = 7
    case deci = 6
    case femto = 13
    case giga = 11
    case hecto = 8
    case kilo = 9
    case mega = 10
    case micro = 3
    case milli = 4
    case nano = 2
    case none = 0
    case pico = 1
    case tera = 12
}

public enum HKPhysicalEffortEstimationType: Int, Sendable, Hashable {
    case activityLookup = 1
    case deviceSensed = 2
}

public enum HKPrismBase: Int, Sendable, Hashable {
    case down = 2
    case `in` = 3
    case none = 0
    case out = 4
    case up = 1
}

public enum HKQuantityAggregationStyle: Int, Sendable, Hashable {
    case cumulative = 0
    case discreteArithmetic = 1
    case discreteEquivalentContinuousLevel = 3
    case discreteTemporallyWeighted = 2
    public static var discrete: HKQuantityAggregationStyle { .discreteArithmetic }
}

public enum HKSwimmingStrokeStyle: Int, Sendable, Hashable {
    case backstroke = 3
    case breaststroke = 4
    case butterfly = 5
    case freestyle = 2
    case kickboard = 6
    case mixed = 1
    case unknown = 0
}

public enum HKUpdateFrequency: Int, Sendable, Hashable {
    case daily = 3
    case hourly = 2
    case immediate = 1
    case weekly = 4
}

public enum HKUserMotionContext: Int, Sendable, Hashable {
    case active = 2
    case notSet = 0
    case stationary = 1
}

public enum HKVO2MaxTestType: Int, Sendable, Hashable {
    case maxExercise = 1
    case predictionNonExercise = 3
    case predictionStepTest = 4
    case predictionSubMaxExercise = 2
}

public enum HKVisionEye: Int, Sendable, Hashable {
    case left = 0
    case right = 1
}

public enum HKVisionPrescriptionType: UInt, Sendable, Hashable {
    case contacts = 2
    case glasses = 1
}

public enum HKWaterSalinity: Int, Sendable, Hashable {
    case freshWater = 1
    case saltWater = 2
}

public enum HKWeatherCondition: Int, Sendable, Hashable {
    case blustery = 9
    case clear = 1
    case cloudy = 5
    case drizzle = 18
    case dust = 11
    case fair = 2
    case foggy = 6
    case freezingDrizzle = 14
    case freezingRain = 15
    case hail = 17
    case haze = 7
    case hurricane = 23
    case mixedRainAndHail = 16
    case mixedRainAndSleet = 26
    case mixedRainAndSnow = 25
    case mixedSnowAndSleet = 27
    case mostlyCloudy = 4
    case none = 0
    case partlyCloudy = 3
    case scatteredShowers = 19
    case showers = 20
    case sleet = 13
    case smoky = 10
    case snow = 12
    case thunderstorms = 21
    case tornado = 24
    case tropicalStorm = 22
    case windy = 8
}

public enum HKWheelchairUse: Int, Sendable, Hashable {
    case no = 1
    case notSet = 0
    case yes = 2
}

public enum HKWorkoutActivityType: UInt, Sendable, Hashable {
    case americanFootball = 1
    case archery = 2
    case australianFootball = 3
    case badminton = 4
    case barre = 58
    case baseball = 5
    case basketball = 6
    case bowling = 7
    case boxing = 8
    case cardioDance = 77
    case climbing = 9
    case cooldown = 80
    case coreTraining = 59
    case cricket = 10
    case crossCountrySkiing = 60
    case crossTraining = 11
    case curling = 12
    case cycling = 13
    case dance = 14
    case danceInspiredTraining = 15
    case discSports = 75
    case downhillSkiing = 61
    case elliptical = 16
    case equestrianSports = 17
    case fencing = 18
    case fishing = 19
    case fitnessGaming = 76
    case flexibility = 62
    case functionalStrengthTraining = 20
    case golf = 21
    case gymnastics = 22
    case handCycling = 74
    case handball = 23
    case highIntensityIntervalTraining = 63
    case hiking = 24
    case hockey = 25
    case hunting = 26
    case jumpRope = 64
    case kickboxing = 65
    case lacrosse = 27
    case martialArts = 28
    case mindAndBody = 29
    case mixedCardio = 73
    case mixedMetabolicCardioTraining = 30
    case other = 3000
    case paddleSports = 31
    case pickleball = 79
    case pilates = 66
    case play = 32
    case preparationAndRecovery = 33
    case racquetball = 34
    case rowing = 35
    case rugby = 36
    case running = 37
    case sailing = 38
    case skatingSports = 39
    case snowSports = 40
    case snowboarding = 67
    case soccer = 41
    case socialDance = 78
    case softball = 42
    case squash = 43
    case stairClimbing = 44
    case stairs = 68
    case stepTraining = 69
    case surfingSports = 45
    case swimBikeRun = 82
    case swimming = 46
    case tableTennis = 47
    case taiChi = 72
    case tennis = 48
    case trackAndField = 49
    case traditionalStrengthTraining = 50
    case transition = 83
    case underwaterDiving = 84
    case volleyball = 51
    case walking = 52
    case waterFitness = 53
    case waterPolo = 54
    case waterSports = 55
    case wheelchairRunPace = 71
    case wheelchairWalkPace = 70
    case wrestling = 56
    case yoga = 57
}

public enum HKWorkoutEffortRelationshipQueryOptions: Int, Sendable, Hashable {
    case `default` = 0
    case mostRelevant = 1
}

public enum HKWorkoutEventType: Int, Sendable, Hashable {
    case lap = 3
    case marker = 4
    case motionPaused = 5
    case motionResumed = 6
    case pause = 1
    case pauseOrResumeRequest = 8
    case resume = 2
    case segment = 7
}

public enum HKWorkoutSessionLocationType: Int, Sendable, Hashable {
    case indoor = 2
    case outdoor = 3
    case unknown = 1
}

public enum HKWorkoutSessionState: Int, Sendable, Hashable {
    case ended = 3
    case notStarted = 1
    case paused = 4
    case prepared = 5
    case running = 2
    case stopped = 6
}

public enum HKWorkoutSessionType: Int, Sendable, Hashable {
    case mirrored = 1
    case primary = 0
}

public enum HKWorkoutSwimmingLocationType: Int, Sendable, Hashable {
    case openWater = 2
    case pool = 1
    case unknown = 0
}

