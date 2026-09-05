import Foundation

#if canImport(HealthKit)
import HealthKit
#endif

/// A threshold, range, or zone alert attached to a workout step.
public protocol WorkoutAlert: Hashable, Sendable {
    var metric: WorkoutAlertMetric { get }
    func supports(
        activity: HKWorkoutActivityType,
        location: HKWorkoutSessionLocationType
    ) -> Bool
}

enum WorkoutAlertBox: Hashable, Sendable {
    case heartRateRange(HeartRateRangeAlert)
    case heartRateZone(HeartRateZoneAlert)
    case powerRange(PowerRangeAlert)
    case powerThreshold(PowerThresholdAlert)
    case powerZone(PowerZoneAlert)
    case speedRange(SpeedRangeAlert)
    case speedThreshold(SpeedThresholdAlert)
    case cadenceRange(CadenceRangeAlert)
    case cadenceThreshold(CadenceThresholdAlert)

    init?(_ alert: any WorkoutAlert) {
        switch alert {
        case let value as HeartRateRangeAlert:
            self = .heartRateRange(value)
        case let value as HeartRateZoneAlert:
            self = .heartRateZone(value)
        case let value as PowerRangeAlert:
            self = .powerRange(value)
        case let value as PowerThresholdAlert:
            self = .powerThreshold(value)
        case let value as PowerZoneAlert:
            self = .powerZone(value)
        case let value as SpeedRangeAlert:
            self = .speedRange(value)
        case let value as SpeedThresholdAlert:
            self = .speedThreshold(value)
        case let value as CadenceRangeAlert:
            self = .cadenceRange(value)
        case let value as CadenceThresholdAlert:
            self = .cadenceThreshold(value)
        default:
            return nil
        }
    }

    var alert: any WorkoutAlert {
        switch self {
        case .heartRateRange(let value): return value
        case .heartRateZone(let value): return value
        case .powerRange(let value): return value
        case .powerThreshold(let value): return value
        case .powerZone(let value): return value
        case .speedRange(let value): return value
        case .speedThreshold(let value): return value
        case .cadenceRange(let value): return value
        case .cadenceThreshold(let value): return value
        }
    }
}

public struct HeartRateRangeAlert: WorkoutAlert {
    public let target: ClosedRange<Measurement<UnitFrequency>>
    public var metric: WorkoutAlertMetric { .current }

    public init(target: ClosedRange<Measurement<UnitFrequency>>) {
        self.target = target
    }

    public var targetQuantityLowerBound: HKQuantity {
        WorkoutKitHealthBridge.quantity(from: target.lowerBound)
    }

    public var targetQuantityUpperBound: HKQuantity {
        WorkoutKitHealthBridge.quantity(from: target.upperBound)
    }

    public func hash(into hasher: inout Hasher) {
        WorkoutKitDimension.hashMeasurement(target.lowerBound, into: &hasher)
        WorkoutKitDimension.hashMeasurement(target.upperBound, into: &hasher)
        hasher.combine(metric)
    }

    public func supports(
        activity: HKWorkoutActivityType,
        location: HKWorkoutSessionLocationType
    ) -> Bool {
        _ = location
        return WorkoutSupport.isStructuredActivity(activity)
    }
}

public struct HeartRateZoneAlert: WorkoutAlert {
    public let zone: Int
    public var metric: WorkoutAlertMetric { .current }

    public init(zone: Int) {
        self.zone = zone
    }

    public func supports(
        activity: HKWorkoutActivityType,
        location: HKWorkoutSessionLocationType
    ) -> Bool {
        _ = location
        return WorkoutSupport.isStructuredActivity(activity)
    }
}

public struct PowerRangeAlert: WorkoutAlert {
    public let target: ClosedRange<Measurement<UnitPower>>
    public var metric: WorkoutAlertMetric

    public init(target: ClosedRange<Measurement<UnitPower>>, metric: WorkoutAlertMetric) {
        self.target = target
        self.metric = metric
    }

    public init(target: ClosedRange<Measurement<UnitPower>>) {
        self.init(target: target, metric: .current)
    }

    public var targetQuantityLowerBound: HKQuantity {
        WorkoutKitHealthBridge.quantity(from: target.lowerBound)
    }

    public var targetQuantityUpperBound: HKQuantity {
        WorkoutKitHealthBridge.quantity(from: target.upperBound)
    }

    public func hash(into hasher: inout Hasher) {
        WorkoutKitDimension.hashMeasurement(target.lowerBound, into: &hasher)
        WorkoutKitDimension.hashMeasurement(target.upperBound, into: &hasher)
        hasher.combine(metric)
    }

    public func supports(
        activity: HKWorkoutActivityType,
        location: HKWorkoutSessionLocationType
    ) -> Bool {
        _ = location
        return WorkoutSupport.isPowerActivity(activity)
    }
}

public struct PowerThresholdAlert: WorkoutAlert {
    public let target: Measurement<UnitPower>
    public var metric: WorkoutAlertMetric

    public init(target: Measurement<UnitPower>, metric: WorkoutAlertMetric) {
        self.target = target
        self.metric = metric
    }

    public init(target: Measurement<UnitPower>) {
        self.init(target: target, metric: .current)
    }

    public var targetQuantity: HKQuantity {
        WorkoutKitHealthBridge.quantity(from: target)
    }

    public func hash(into hasher: inout Hasher) {
        WorkoutKitDimension.hashMeasurement(target, into: &hasher)
        hasher.combine(metric)
    }

    public func supports(
        activity: HKWorkoutActivityType,
        location: HKWorkoutSessionLocationType
    ) -> Bool {
        _ = location
        return WorkoutSupport.isPowerActivity(activity)
    }
}

public struct PowerZoneAlert: WorkoutAlert {
    public let zone: Int
    public var metric: WorkoutAlertMetric { .current }

    public init(zone: Int) {
        self.zone = zone
    }

    public func supports(
        activity: HKWorkoutActivityType,
        location: HKWorkoutSessionLocationType
    ) -> Bool {
        _ = location
        return WorkoutSupport.isPowerActivity(activity)
    }
}

public struct SpeedRangeAlert: WorkoutAlert {
    public let target: ClosedRange<Measurement<UnitSpeed>>
    public let metric: WorkoutAlertMetric

    public init(target: ClosedRange<Measurement<UnitSpeed>>, metric: WorkoutAlertMetric) {
        self.target = target
        self.metric = metric
    }

    public var targetQuantityLowerBound: HKQuantity {
        WorkoutKitHealthBridge.quantity(from: target.lowerBound)
    }

    public var targetQuantityUpperBound: HKQuantity {
        WorkoutKitHealthBridge.quantity(from: target.upperBound)
    }

    public func hash(into hasher: inout Hasher) {
        WorkoutKitDimension.hashMeasurement(target.lowerBound, into: &hasher)
        WorkoutKitDimension.hashMeasurement(target.upperBound, into: &hasher)
        hasher.combine(metric)
    }

    public func supports(
        activity: HKWorkoutActivityType,
        location: HKWorkoutSessionLocationType
    ) -> Bool {
        _ = location
        return WorkoutSupport.isSpeedActivity(activity)
    }
}

public struct SpeedThresholdAlert: WorkoutAlert {
    public let target: Measurement<UnitSpeed>
    public let metric: WorkoutAlertMetric

    public init(target: Measurement<UnitSpeed>, metric: WorkoutAlertMetric) {
        self.target = target
        self.metric = metric
    }

    public var targetQuantity: HKQuantity {
        WorkoutKitHealthBridge.quantity(from: target)
    }

    public func hash(into hasher: inout Hasher) {
        WorkoutKitDimension.hashMeasurement(target, into: &hasher)
        hasher.combine(metric)
    }

    public func supports(
        activity: HKWorkoutActivityType,
        location: HKWorkoutSessionLocationType
    ) -> Bool {
        _ = location
        return WorkoutSupport.isSpeedActivity(activity)
    }
}

public struct CadenceRangeAlert: WorkoutAlert {
    public let target: ClosedRange<Measurement<UnitFrequency>>
    public var metric: WorkoutAlertMetric { .current }

    public init(target: ClosedRange<Measurement<UnitFrequency>>) {
        self.target = target
    }

    public var targetQuantityLowerBound: HKQuantity {
        WorkoutKitHealthBridge.quantity(from: target.lowerBound)
    }

    public var targetQuantityUpperBound: HKQuantity {
        WorkoutKitHealthBridge.quantity(from: target.upperBound)
    }

    public func hash(into hasher: inout Hasher) {
        WorkoutKitDimension.hashMeasurement(target.lowerBound, into: &hasher)
        WorkoutKitDimension.hashMeasurement(target.upperBound, into: &hasher)
        hasher.combine(metric)
    }

    public func supports(
        activity: HKWorkoutActivityType,
        location: HKWorkoutSessionLocationType
    ) -> Bool {
        _ = location
        return WorkoutSupport.isCadenceActivity(activity)
    }
}

public struct CadenceThresholdAlert: WorkoutAlert {
    public let target: Measurement<UnitFrequency>
    public var metric: WorkoutAlertMetric { .current }

    public init(target: Measurement<UnitFrequency>) {
        self.target = target
    }

    public var targetQuantity: HKQuantity {
        WorkoutKitHealthBridge.quantity(from: target)
    }

    public func hash(into hasher: inout Hasher) {
        WorkoutKitDimension.hashMeasurement(target, into: &hasher)
        hasher.combine(metric)
    }

    public func supports(
        activity: HKWorkoutActivityType,
        location: HKWorkoutSessionLocationType
    ) -> Bool {
        _ = location
        return WorkoutSupport.isCadenceActivity(activity)
    }
}

extension WorkoutAlert where Self == PowerRangeAlert {
    public static func power(
        _ range: ClosedRange<Double>,
        unit: UnitPower,
        metric: WorkoutAlertMetric
    ) -> Self {
        PowerRangeAlert(
            target: Measurement(value: range.lowerBound, unit: unit)
                ... Measurement(value: range.upperBound, unit: unit),
            metric: metric
        )
    }

    public static func power(_ range: ClosedRange<Double>, unit: UnitPower) -> Self {
        .power(range, unit: unit, metric: .current)
    }
}

extension WorkoutAlert where Self == SpeedRangeAlert {
    public static func speed(
        _ range: ClosedRange<Double>,
        unit: UnitSpeed,
        metric: WorkoutAlertMetric = .current
    ) -> Self {
        SpeedRangeAlert(
            target: Measurement(value: range.lowerBound, unit: unit)
                ... Measurement(value: range.upperBound, unit: unit),
            metric: metric
        )
    }
}

extension WorkoutAlert where Self == CadenceRangeAlert {
    public static func cadence(
        _ range: ClosedRange<Double>,
        unit: UnitFrequency = WorkoutAlertMetric.countPerMinute
    ) -> Self {
        CadenceRangeAlert(
            target: Measurement(value: range.lowerBound, unit: unit)
                ... Measurement(value: range.upperBound, unit: unit)
        )
    }
}

extension WorkoutAlert where Self == HeartRateZoneAlert {
    public static func heartRate(zone: Int) -> Self {
        HeartRateZoneAlert(zone: zone)
    }
}

extension WorkoutAlert where Self == HeartRateRangeAlert {
    public static func heartRate(
        _ range: ClosedRange<Double>,
        unit: UnitFrequency = WorkoutAlertMetric.countPerMinute
    ) -> Self {
        HeartRateRangeAlert(
            target: Measurement(value: range.lowerBound, unit: unit)
                ... Measurement(value: range.upperBound, unit: unit)
        )
    }
}

extension WorkoutAlert where Self == PowerThresholdAlert {
    public static func power(
        _ value: Double,
        unit: UnitPower,
        metric: WorkoutAlertMetric
    ) -> Self {
        PowerThresholdAlert(target: Measurement(value: value, unit: unit), metric: metric)
    }

    public static func power(_ value: Double, unit: UnitPower) -> Self {
        .power(value, unit: unit, metric: .current)
    }
}

extension WorkoutAlert where Self == SpeedThresholdAlert {
    public static func speed(
        _ value: Double,
        unit: UnitSpeed,
        metric: WorkoutAlertMetric = .current
    ) -> Self {
        SpeedThresholdAlert(target: Measurement(value: value, unit: unit), metric: metric)
    }
}

extension WorkoutAlert where Self == CadenceThresholdAlert {
    public static func cadence(
        _ value: Double,
        unit: UnitFrequency = WorkoutAlertMetric.countPerMinute
    ) -> Self {
        CadenceThresholdAlert(target: Measurement(value: value, unit: unit))
    }
}

extension WorkoutAlert where Self == PowerZoneAlert {
    public static func power(zone: Int) -> Self {
        PowerZoneAlert(zone: zone)
    }
}
