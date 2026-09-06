import Foundation

#if canImport(HealthKit)
import HealthKit
#endif

/// Metric used by a `WorkoutAlert`. Cadence and heart-rate alerts use
/// `countPerMinute`.
public enum WorkoutAlertMetric: Hashable, Sendable {
    case current
    case average

    /// Unit for cadence and heart-rate alerts (`count/min` → hertz / 60).
    public static var countPerMinute: UnitFrequency {
        WorkoutKitDimension.countPerMinute
    }
}

/// Goal attached to a workout or step.
public enum WorkoutGoal: Hashable, Sendable {
    case open
    case time(Double, UnitDuration)
    case energy(Double, UnitEnergy)
    case distance(Double, UnitLength)
    case poolSwimDistanceWithTime(Measurement<UnitLength>, Measurement<UnitDuration>)

    public static func == (lhs: WorkoutGoal, rhs: WorkoutGoal) -> Bool {
        switch (lhs, rhs) {
        case (.open, .open):
            return true
        case (.time(let leftValue, let leftUnit), .time(let rightValue, let rightUnit)):
            return leftValue == rightValue && leftUnit == rightUnit
        case (.energy(let leftValue, let leftUnit), .energy(let rightValue, let rightUnit)):
            return leftValue == rightValue && leftUnit == rightUnit
        case (.distance(let leftValue, let leftUnit), .distance(let rightValue, let rightUnit)):
            return leftValue == rightValue && leftUnit == rightUnit
        case (
            .poolSwimDistanceWithTime(let leftDistance, let leftTime),
            .poolSwimDistanceWithTime(let rightDistance, let rightTime)
        ):
            return leftDistance == rightDistance && leftTime == rightTime
        default:
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .open:
            hasher.combine(0)
        case .time(let value, let unit):
            hasher.combine(1)
            hasher.combine(value)
            hasher.combine(unit.symbol)
        case .energy(let value, let unit):
            hasher.combine(2)
            hasher.combine(value)
            hasher.combine(unit.symbol)
        case .distance(let value, let unit):
            hasher.combine(3)
            hasher.combine(value)
            hasher.combine(unit.symbol)
        case .poolSwimDistanceWithTime(let distance, let time):
            hasher.combine(4)
            hasher.combine(distance.value)
            hasher.combine(distance.unit.symbol)
            hasher.combine(time.value)
            hasher.combine(time.unit.symbol)
        }
    }
}

/// Linux Foundation `Dimension` types must use `init(symbol:converter:)`.
/// Known Apple/Foundation symbols are remapped so plan round-trips keep
/// the same SI coefficient as the original `Measurement`.
enum WorkoutKitDimension {
    static var countPerMinute: UnitFrequency {
        UnitFrequency(
            symbol: "count/min",
            converter: UnitConverterLinear(coefficient: 1.0 / 60.0)
        )
    }

    static func length(_ symbol: String) -> UnitLength {
        switch symbol {
        case UnitLength.meters.symbol: return .meters
        case UnitLength.kilometers.symbol: return .kilometers
        case UnitLength.centimeters.symbol: return .centimeters
        case UnitLength.millimeters.symbol: return .millimeters
        case UnitLength.miles.symbol: return .miles
        case UnitLength.yards.symbol: return .yards
        case UnitLength.feet.symbol: return .feet
        case UnitLength.inches.symbol: return .inches
        default:
            return UnitLength(symbol: symbol, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    static func duration(_ symbol: String) -> UnitDuration {
        switch symbol {
        case UnitDuration.seconds.symbol: return .seconds
        case UnitDuration.minutes.symbol: return .minutes
        case UnitDuration.hours.symbol: return .hours
        case UnitDuration.milliseconds.symbol: return .milliseconds
        default:
            return UnitDuration(symbol: symbol, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    static func energy(_ symbol: String) -> UnitEnergy {
        switch symbol {
        case UnitEnergy.joules.symbol: return .joules
        case UnitEnergy.kilojoules.symbol: return .kilojoules
        case UnitEnergy.kilocalories.symbol: return .kilocalories
        case UnitEnergy.calories.symbol: return .calories
        default:
            return UnitEnergy(symbol: symbol, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    static func power(_ symbol: String) -> UnitPower {
        switch symbol {
        case UnitPower.watts.symbol: return .watts
        case UnitPower.kilowatts.symbol: return .kilowatts
        case UnitPower.milliwatts.symbol: return .milliwatts
        case UnitPower.horsepower.symbol: return .horsepower
        default:
            return UnitPower(symbol: symbol, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    static func speed(_ symbol: String) -> UnitSpeed {
        switch symbol {
        case UnitSpeed.metersPerSecond.symbol: return .metersPerSecond
        case UnitSpeed.kilometersPerHour.symbol: return .kilometersPerHour
        case UnitSpeed.milesPerHour.symbol: return .milesPerHour
        case UnitSpeed.knots.symbol: return .knots
        default:
            return UnitSpeed(symbol: symbol, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    static func frequency(_ symbol: String) -> UnitFrequency {
        if symbol == countPerMinute.symbol { return countPerMinute }
        switch symbol {
        case UnitFrequency.hertz.symbol: return .hertz
        case UnitFrequency.kilohertz.symbol: return .kilohertz
        default:
            return UnitFrequency(symbol: symbol, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    static func hashMeasurement<UnitType: Dimension>(
        _ measurement: Measurement<UnitType>,
        into hasher: inout Hasher
    ) {
        hasher.combine(measurement.value)
        hasher.combine(measurement.unit.symbol)
    }
}
