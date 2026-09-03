import Foundation

public final class HKQuantity: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public let unit: HKUnit
    public let doubleValue: Double

    public init(unit: HKUnit, doubleValue: Double) {
        self.unit = unit
        self.doubleValue = doubleValue
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.unit = HKUnit.count()
        self.doubleValue = 0
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(doubleValue, forKey: "doubleValue")
        coder.encode(unit.unitString as NSString, forKey: "unitString")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        HKQuantity(unit: unit, doubleValue: doubleValue)
    }

    public func `is`(compatibleWith unit: HKUnit) -> Bool {
        self.unit.`is`(compatibleWith: unit)
    }

    public func doubleValue(for unit: HKUnit) -> Double {
        precondition(self.`is`(compatibleWith: unit), "HKQuantity.doubleValue(for:) requires compatible units")
        let si = doubleValue * self.unit.scaleToSI + self.unit.offsetToSI
        return (si - unit.offsetToSI) / unit.scaleToSI
    }

    public func compare(_ quantity: HKQuantity) -> ComparisonResult {
        precondition(self.`is`(compatibleWith: quantity.unit), "HKQuantity.compare requires compatible units")
        let lhs = doubleValue * unit.scaleToSI + unit.offsetToSI
        let rhs = quantity.doubleValue * quantity.unit.scaleToSI + quantity.unit.offsetToSI
        if lhs < rhs { return .orderedAscending }
        if lhs > rhs { return .orderedDescending }
        return .orderedSame
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? HKQuantity else { return false }
        guard self.`is`(compatibleWith: other.unit) else { return false }
        return compare(other) == .orderedSame
    }
}
