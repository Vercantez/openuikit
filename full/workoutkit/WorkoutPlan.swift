import Foundation

#if canImport(HealthKit)
import HealthKit
#endif

/// A named, identifiable workout that can be encoded for preview or
/// scheduling. The Linux codec is `OpenUIKit.WorkoutKit.WorkoutPlan.v1`
/// JSON and is not Apple's on-watch binary layout.
public struct WorkoutPlan: Hashable, Sendable, Identifiable {
    public typealias ID = UUID

    public enum Workout: Hashable, Sendable {
        case goal(SingleGoalWorkout)
        case pacer(PacerWorkout)
        case custom(CustomWorkout)
        case swimBikeRun(SwimBikeRunWorkout)

        public var activity: HKWorkoutActivityType {
            switch self {
            case .goal(let workout):
                return workout.activity
            case .pacer(let workout):
                return workout.activity
            case .custom(let workout):
                return workout.activity
            case .swimBikeRun:
                return .swimBikeRun
            }
        }
    }

    public var id: UUID
    public var workout: Workout

    public init(_ workout: Workout, id: UUID = UUID()) {
        self.workout = workout
        self.id = id
    }

    public var dataRepresentation: Data {
        get throws {
            try WorkoutPlanCodec.encode(self)
        }
    }

    public init(from data: Data) throws {
        self = try WorkoutPlanCodec.decode(data)
    }
}

/// A workout plan scheduled for a calendar date. Linux never delivers
/// these to a Watch; `WorkoutScheduler` keeps an empty list.
public struct ScheduledWorkoutPlan: Hashable, Sendable {
    public var plan: WorkoutPlan
    public var date: DateComponents
    public var complete: Bool

    public init(_ plan: WorkoutPlan, date: DateComponents) {
        self.plan = plan
        self.date = date
        self.complete = false
    }
}

extension HKWorkout {
    /// Linux has no HealthKit workout store and no paired Watch, so this
    /// always throws `StateError.watchNotPaired`.
    public var workoutPlan: WorkoutPlan? {
        get async throws {
            throw StateError.watchNotPaired
        }
    }
}

enum WorkoutPlanCodec {
    enum Error: Swift.Error {
        case invalidData
        case unsupportedFormat
    }

    static func encode(_ plan: WorkoutPlan) throws -> Data {
        let object: [String: Any] = [
            "format": WorkoutKitModule.planFormat,
            "id": plan.id.uuidString,
            "workout": encodeWorkout(plan.workout),
        ]
        return try JSONSerialization.data(
            withJSONObject: object,
            options: [.sortedKeys]
        )
    }

    static func decode(_ data: Data) throws -> WorkoutPlan {
        guard
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let format = object["format"] as? String
        else {
            throw Error.invalidData
        }
        guard format == WorkoutKitModule.planFormat else {
            throw Error.unsupportedFormat
        }
        guard
            let idString = object["id"] as? String,
            let id = UUID(uuidString: idString),
            let workoutObject = object["workout"] as? [String: Any],
            let workout = decodeWorkout(workoutObject)
        else {
            throw Error.invalidData
        }
        return WorkoutPlan(workout, id: id)
    }

    private static func encodeWorkout(_ workout: WorkoutPlan.Workout) -> [String: Any] {
        switch workout {
        case .goal(let value):
            return [
                "kind": "goal",
                "activity": activityRaw(value.activity),
                "location": value.location.rawValue,
                "swimmingLocation": value.swimmingLocation.rawValue,
                "goal": encodeGoal(value.goal),
            ]
        case .pacer(let value):
            return [
                "kind": "pacer",
                "activity": activityRaw(value.activity),
                "location": value.location.rawValue,
                "distance": encodeMeasurement(value.distance),
                "time": encodeMeasurement(value.time),
            ]
        case .custom(let value):
            return [
                "kind": "custom",
                "activity": activityRaw(value.activity),
                "location": value.location.rawValue,
                "displayName": value.displayName as Any,
                "warmup": value.warmup.map(encodeStep) as Any,
                "blocks": value.blocks.map(encodeBlock),
                "cooldown": value.cooldown.map(encodeStep) as Any,
            ]
        case .swimBikeRun(let value):
            return [
                "kind": "swimBikeRun",
                "displayName": value.displayName as Any,
                "activities": value.activities.map(encodeSBRActivity),
            ]
        }
    }

    private static func decodeWorkout(_ object: [String: Any]) -> WorkoutPlan.Workout? {
        guard let kind = object["kind"] as? String else { return nil }
        switch kind {
        case "goal":
            guard
                let activity = activity(from: object["activity"]),
                let locationRaw = object["location"] as? Int,
                let location = HKWorkoutSessionLocationType(rawValue: locationRaw),
                let swimRaw = object["swimmingLocation"] as? Int,
                let swimming = HKWorkoutSwimmingLocationType(rawValue: swimRaw),
                let goalObject = object["goal"] as? [String: Any],
                let goal = decodeGoal(goalObject)
            else { return nil }
            return .goal(
                SingleGoalWorkout(
                    activity: activity,
                    location: location,
                    swimmingLocation: swimming,
                    goal: goal
                )
            )
        case "pacer":
            guard
                let activity = activity(from: object["activity"]),
                let locationRaw = object["location"] as? Int,
                let location = HKWorkoutSessionLocationType(rawValue: locationRaw),
                let distance = decodeLength(object["distance"]),
                let time = decodeDuration(object["time"])
            else { return nil }
            return .pacer(
                PacerWorkout(
                    activity: activity,
                    location: location,
                    distance: distance,
                    time: time
                )
            )
        case "custom":
            guard
                let activity = activity(from: object["activity"]),
                let locationRaw = object["location"] as? Int,
                let location = HKWorkoutSessionLocationType(rawValue: locationRaw)
            else { return nil }
            let displayName = object["displayName"] as? String
            let warmup = (object["warmup"] as? [String: Any]).flatMap(decodeStep)
            let cooldown = (object["cooldown"] as? [String: Any]).flatMap(decodeStep)
            let blocks = (object["blocks"] as? [[String: Any]] ?? []).compactMap(decodeBlock)
            return .custom(
                CustomWorkout(
                    activity: activity,
                    location: location,
                    displayName: displayName,
                    warmup: warmup,
                    blocks: blocks,
                    cooldown: cooldown
                )
            )
        case "swimBikeRun":
            let displayName = object["displayName"] as? String
            let activities = (object["activities"] as? [[String: Any]] ?? [])
                .compactMap(decodeSBRActivity)
            return .swimBikeRun(
                SwimBikeRunWorkout(activities: activities, displayName: displayName)
            )
        default:
            return nil
        }
    }

    private static func encodeGoal(_ goal: WorkoutGoal) -> [String: Any] {
        switch goal {
        case .open:
            return ["kind": "open"]
        case .time(let value, let unit):
            return ["kind": "time", "value": value, "unit": unit.symbol]
        case .energy(let value, let unit):
            return ["kind": "energy", "value": value, "unit": unit.symbol]
        case .distance(let value, let unit):
            return ["kind": "distance", "value": value, "unit": unit.symbol]
        case .poolSwimDistanceWithTime(let distance, let time):
            return [
                "kind": "poolSwimDistanceWithTime",
                "distance": encodeMeasurement(distance),
                "time": encodeMeasurement(time),
            ]
        }
    }

    private static func decodeGoal(_ object: [String: Any]) -> WorkoutGoal? {
        guard let kind = object["kind"] as? String else { return nil }
        switch kind {
        case "open":
            return .open
        case "time":
            guard
                let value = object["value"] as? Double,
                let symbol = object["unit"] as? String
            else { return nil }
            return .time(value, WorkoutKitDimension.duration(symbol))
        case "energy":
            guard
                let value = object["value"] as? Double,
                let symbol = object["unit"] as? String
            else { return nil }
            return .energy(value, WorkoutKitDimension.energy(symbol))
        case "distance":
            guard
                let value = object["value"] as? Double,
                let symbol = object["unit"] as? String
            else { return nil }
            return .distance(value, WorkoutKitDimension.length(symbol))
        case "poolSwimDistanceWithTime":
            guard
                let distance = decodeLength(object["distance"]),
                let time = decodeDuration(object["time"])
            else { return nil }
            return .poolSwimDistanceWithTime(distance, time)
        default:
            return nil
        }
    }

    private static func encodeStep(_ step: WorkoutStep) -> [String: Any] {
        var object: [String: Any] = [
            "goal": encodeGoal(step.goal),
        ]
        if let displayName = step.displayName {
            object["displayName"] = displayName
        }
        if let alert = step.alert, let box = WorkoutAlertBox(alert) {
            object["alert"] = encodeAlert(box)
        }
        return object
    }

    private static func decodeStep(_ object: [String: Any]) -> WorkoutStep? {
        guard
            let goalObject = object["goal"] as? [String: Any],
            let goal = decodeGoal(goalObject)
        else { return nil }
        let displayName = object["displayName"] as? String
        let alert = (object["alert"] as? [String: Any]).flatMap(decodeAlert)
        return WorkoutStep(goal: goal, alert: alert, displayName: displayName)
    }

    private static func encodeBlock(_ block: IntervalBlock) -> [String: Any] {
        [
            "iterations": block.iterations,
            "steps": block.steps.map { step -> [String: Any] in
                [
                    "purpose": purposeName(step.purpose),
                    "step": encodeStep(step.step),
                ]
            },
        ]
    }

    private static func decodeBlock(_ object: [String: Any]) -> IntervalBlock? {
        guard let iterations = object["iterations"] as? Int else { return nil }
        let steps = (object["steps"] as? [[String: Any]] ?? []).compactMap { row -> IntervalStep? in
            guard
                let purposeName = row["purpose"] as? String,
                let purpose = purpose(from: purposeName),
                let stepObject = row["step"] as? [String: Any],
                let step = decodeStep(stepObject)
            else { return nil }
            return IntervalStep(purpose, step: step)
        }
        return IntervalBlock(steps: steps, iterations: iterations)
    }

    private static func encodeSBRActivity(
        _ activity: SwimBikeRunWorkout.Activity
    ) -> [String: Any] {
        switch activity {
        case .swimming(let location):
            return ["kind": "swimming", "location": location.rawValue]
        case .cycling(let location):
            return ["kind": "cycling", "location": location.rawValue]
        case .running(let location):
            return ["kind": "running", "location": location.rawValue]
        }
    }

    private static func decodeSBRActivity(
        _ object: [String: Any]
    ) -> SwimBikeRunWorkout.Activity? {
        guard let kind = object["kind"] as? String else { return nil }
        switch kind {
        case "swimming":
            guard
                let raw = object["location"] as? Int,
                let location = HKWorkoutSwimmingLocationType(rawValue: raw)
            else { return nil }
            return .swimming(location)
        case "cycling":
            guard
                let raw = object["location"] as? Int,
                let location = HKWorkoutSessionLocationType(rawValue: raw)
            else { return nil }
            return .cycling(location)
        case "running":
            guard
                let raw = object["location"] as? Int,
                let location = HKWorkoutSessionLocationType(rawValue: raw)
            else { return nil }
            return .running(location)
        default:
            return nil
        }
    }

    private static func encodeAlert(_ box: WorkoutAlertBox) -> [String: Any] {
        switch box {
        case .heartRateRange(let alert):
            return [
                "kind": "heartRateRange",
                "lower": encodeMeasurement(alert.target.lowerBound),
                "upper": encodeMeasurement(alert.target.upperBound),
            ]
        case .heartRateZone(let alert):
            return ["kind": "heartRateZone", "zone": alert.zone]
        case .powerRange(let alert):
            return [
                "kind": "powerRange",
                "lower": encodeMeasurement(alert.target.lowerBound),
                "upper": encodeMeasurement(alert.target.upperBound),
                "metric": metricName(alert.metric),
            ]
        case .powerThreshold(let alert):
            return [
                "kind": "powerThreshold",
                "target": encodeMeasurement(alert.target),
                "metric": metricName(alert.metric),
            ]
        case .powerZone(let alert):
            return ["kind": "powerZone", "zone": alert.zone]
        case .speedRange(let alert):
            return [
                "kind": "speedRange",
                "lower": encodeMeasurement(alert.target.lowerBound),
                "upper": encodeMeasurement(alert.target.upperBound),
                "metric": metricName(alert.metric),
            ]
        case .speedThreshold(let alert):
            return [
                "kind": "speedThreshold",
                "target": encodeMeasurement(alert.target),
                "metric": metricName(alert.metric),
            ]
        case .cadenceRange(let alert):
            return [
                "kind": "cadenceRange",
                "lower": encodeMeasurement(alert.target.lowerBound),
                "upper": encodeMeasurement(alert.target.upperBound),
            ]
        case .cadenceThreshold(let alert):
            return [
                "kind": "cadenceThreshold",
                "target": encodeMeasurement(alert.target),
            ]
        }
    }

    private static func decodeAlert(_ object: [String: Any]) -> (any WorkoutAlert)? {
        guard let kind = object["kind"] as? String else { return nil }
        switch kind {
        case "heartRateRange":
            guard
                let lower = decodeFrequency(object["lower"]),
                let upper = decodeFrequency(object["upper"])
            else { return nil }
            return HeartRateRangeAlert(target: lower ... upper)
        case "heartRateZone":
            guard let zone = object["zone"] as? Int else { return nil }
            return HeartRateZoneAlert(zone: zone)
        case "powerRange":
            guard
                let lower = decodePower(object["lower"]),
                let upper = decodePower(object["upper"]),
                let metric = metric(from: object["metric"] as? String)
            else { return nil }
            return PowerRangeAlert(target: lower ... upper, metric: metric)
        case "powerThreshold":
            guard
                let target = decodePower(object["target"]),
                let metric = metric(from: object["metric"] as? String)
            else { return nil }
            return PowerThresholdAlert(target: target, metric: metric)
        case "powerZone":
            guard let zone = object["zone"] as? Int else { return nil }
            return PowerZoneAlert(zone: zone)
        case "speedRange":
            guard
                let lower = decodeSpeed(object["lower"]),
                let upper = decodeSpeed(object["upper"]),
                let metric = metric(from: object["metric"] as? String)
            else { return nil }
            return SpeedRangeAlert(target: lower ... upper, metric: metric)
        case "speedThreshold":
            guard
                let target = decodeSpeed(object["target"]),
                let metric = metric(from: object["metric"] as? String)
            else { return nil }
            return SpeedThresholdAlert(target: target, metric: metric)
        case "cadenceRange":
            guard
                let lower = decodeFrequency(object["lower"]),
                let upper = decodeFrequency(object["upper"])
            else { return nil }
            return CadenceRangeAlert(target: lower ... upper)
        case "cadenceThreshold":
            guard let target = decodeFrequency(object["target"]) else { return nil }
            return CadenceThresholdAlert(target: target)
        default:
            return nil
        }
    }

    private static func encodeMeasurement<UnitType: Dimension>(
        _ measurement: Measurement<UnitType>
    ) -> [String: Any] {
        ["value": measurement.value, "unit": measurement.unit.symbol]
    }

    private static func decodeLength(_ value: Any?) -> Measurement<UnitLength>? {
        guard
            let object = value as? [String: Any],
            let amount = object["value"] as? Double,
            let symbol = object["unit"] as? String
        else { return nil }
        return Measurement(value: amount, unit: WorkoutKitDimension.length(symbol))
    }

    private static func decodeDuration(_ value: Any?) -> Measurement<UnitDuration>? {
        guard
            let object = value as? [String: Any],
            let amount = object["value"] as? Double,
            let symbol = object["unit"] as? String
        else { return nil }
        return Measurement(value: amount, unit: WorkoutKitDimension.duration(symbol))
    }

    private static func decodeFrequency(_ value: Any?) -> Measurement<UnitFrequency>? {
        guard
            let object = value as? [String: Any],
            let amount = object["value"] as? Double,
            let symbol = object["unit"] as? String
        else { return nil }
        return Measurement(value: amount, unit: WorkoutKitDimension.frequency(symbol))
    }

    private static func decodePower(_ value: Any?) -> Measurement<UnitPower>? {
        guard
            let object = value as? [String: Any],
            let amount = object["value"] as? Double,
            let symbol = object["unit"] as? String
        else { return nil }
        return Measurement(value: amount, unit: WorkoutKitDimension.power(symbol))
    }

    private static func decodeSpeed(_ value: Any?) -> Measurement<UnitSpeed>? {
        guard
            let object = value as? [String: Any],
            let amount = object["value"] as? Double,
            let symbol = object["unit"] as? String
        else { return nil }
        return Measurement(value: amount, unit: WorkoutKitDimension.speed(symbol))
    }

    private static func activityRaw(_ activity: HKWorkoutActivityType) -> UInt {
        activity.rawValue
    }

    private static func activity(from value: Any?) -> HKWorkoutActivityType? {
        if let raw = value as? UInt {
            return HKWorkoutActivityType(rawValue: raw)
        }
        if let raw = value as? Int {
            return HKWorkoutActivityType(rawValue: UInt(raw))
        }
        return nil
    }

    private static func purposeName(_ purpose: IntervalStep.Purpose) -> String {
        switch purpose {
        case .work: return "work"
        case .recovery: return "recovery"
        }
    }

    private static func purpose(from name: String) -> IntervalStep.Purpose? {
        switch name {
        case "work": return .work
        case "recovery": return .recovery
        default: return nil
        }
    }

    private static func metricName(_ metric: WorkoutAlertMetric) -> String {
        switch metric {
        case .current: return "current"
        case .average: return "average"
        }
    }

    private static func metric(from name: String?) -> WorkoutAlertMetric? {
        switch name {
        case "current": return .current
        case "average": return .average
        default: return nil
        }
    }
}
