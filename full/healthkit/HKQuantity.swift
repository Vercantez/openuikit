import Foundation

/// A measured value together with its `HKUnit`. Compatible units convert
/// through the unit's SI scale; incompatible conversions are a programming error.
open class HKQuantity: NSObject, NSCopying {
    let unit: HKUnit
    let value: Double

    public convenience init(unit: HKUnit, doubleValue value: Double) {
        self.init(_unit: unit, value: value)
    }

    init(_unit unit: HKUnit, value: Double) {
        self.unit = unit
        self.value = value
        super.init()
    }

    public convenience init?(coder: NSCoder) {
        return nil
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        HKQuantity(_unit: unit, value: value)
    }

    public func `is`(compatibleWith unit: HKUnit) -> Bool {
        self.unit.isCompatible(with: unit)
    }

    public func doubleValue(for unit: HKUnit) -> Double {
        precondition(
            self.unit.isCompatible(with: unit),
            "HKQuantity.doubleValue(for:) requires a compatible unit"
        )
        return self.unit.convert(value, to: unit)
    }

    public func compare(_ quantity: HKQuantity) -> ComparisonResult {
        precondition(
            unit.isCompatible(with: quantity.unit),
            "HKQuantity.compare requires compatible units"
        )
        let lhs = doubleValue(for: unit)
        let rhs = quantity.doubleValue(for: unit)
        if lhs < rhs { return .orderedAscending }
        if lhs > rhs { return .orderedDescending }
        return .orderedSame
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? HKQuantity else { return false }
        guard unit.isCompatible(with: other.unit) else { return false }
        return doubleValue(for: unit) == other.doubleValue(for: unit)
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(unit.dimension)
        hasher.combine(unit.convert(value, to: unit))
        return hasher.finalize()
    }
}

extension HKAppleWalkingSteadinessClassification {
    public init(for appleWalkingSteadiness: HKQuantity) throws {
        guard appleWalkingSteadiness.is(compatibleWith: .percent()) else {
            throw hkInvalidArgument("Walking steadiness requires a percent quantity.")
        }
        let percent = appleWalkingSteadiness.doubleValue(for: .percent())
        if percent < 0.50 {
            self = .veryLow
        } else if percent < 0.75 {
            self = .low
        } else {
            self = .ok
        }
    }

    public var minimum: HKQuantity {
        switch self {
        case .veryLow: return HKQuantity(unit: .percent(), doubleValue: 0)
        case .low: return HKQuantity(unit: .percent(), doubleValue: 0.50)
        case .ok: return HKQuantity(unit: .percent(), doubleValue: 0.75)
        }
    }

    public var maximum: HKQuantity {
        switch self {
        case .veryLow: return HKQuantity(unit: .percent(), doubleValue: 0.50)
        case .low: return HKQuantity(unit: .percent(), doubleValue: 0.75)
        case .ok: return HKQuantity(unit: .percent(), doubleValue: 1.0)
        }
    }
}

extension HKAppleSleepingBreathingDisturbancesClassification {
    public init?(classifying appleSleepingBreathingDisturbances: HKQuantity) {
        guard appleSleepingBreathingDisturbances.is(compatibleWith: .count().unitDivided(by: .hour()))
            || appleSleepingBreathingDisturbances.is(compatibleWith: .count())
        else {
            return nil
        }
        let unit = HKUnit.count().unitDivided(by: .hour())
        let value: Double
        if appleSleepingBreathingDisturbances.is(compatibleWith: unit) {
            value = appleSleepingBreathingDisturbances.doubleValue(for: unit)
        } else {
            value = appleSleepingBreathingDisturbances.doubleValue(for: .count())
        }
        self = value >= 15 ? .elevated : .notElevated
    }
}

extension HKStateOfMind.ValenceClassification {
    public init?(valence: Double) {
        switch valence {
        case ..<(-0.5): self = valence < -0.75 ? .veryUnpleasant : .unpleasant
        case -0.5..<(-0.15): self = .slightlyUnpleasant
        case -0.15...0.15: self = .neutral
        case 0.15...0.5: self = .slightlyPleasant
        case 0.5...0.75: self = .pleasant
        case 0.75...: self = .veryPleasant
        default: return nil
        }
    }
}
