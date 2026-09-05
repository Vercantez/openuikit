#if canImport(HealthKit)
import HealthKit
#else
import Foundation

/// Isolated-host stand-ins for HealthKit types that appear in WorkoutKit's
/// public signatures. Compiled only when `HealthKit` is not on the search
/// path. The EC2 identity probe imports the real `HealthKit` module and
/// must never see these names from WorkoutKit.
///
/// Raw values match the documented `HKWorkoutActivityType` /
/// `HKWorkoutSessionLocationType` / `HKWorkoutSwimmingLocationType`
/// overlays used by the in-tree HealthKit port.

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

public enum HKWorkoutSessionLocationType: Int, Sendable, Hashable {
    case unknown = 1
    case indoor = 2
    case outdoor = 3
}

public enum HKWorkoutSwimmingLocationType: Int, Sendable, Hashable {
    case unknown = 0
    case pool = 1
    case openWater = 2
}

public final class HKQuantity: NSObject, @unchecked Sendable {
    public let unitSymbol: String
    public let doubleValue: Double

    public init(unitSymbol: String, doubleValue: Double) {
        self.unitSymbol = unitSymbol
        self.doubleValue = doubleValue
        super.init()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? HKQuantity else { return false }
        return unitSymbol == other.unitSymbol && doubleValue == other.doubleValue
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(unitSymbol)
        hasher.combine(doubleValue)
        return hasher.finalize()
    }
}

open class HKWorkout: NSObject {
    public override init() {
        super.init()
    }
}
#endif

enum WorkoutKitHealthBridge {
    static func quantity<UnitType: Dimension>(
        from measurement: Measurement<UnitType>
    ) -> HKQuantity {
        #if canImport(HealthKit)
        return HKQuantity(
            unit: HKUnit(from: measurement.unit.symbol),
            doubleValue: measurement.value
        )
        #else
        return HKQuantity(
            unitSymbol: measurement.unit.symbol,
            doubleValue: measurement.value
        )
        #endif
    }
}
