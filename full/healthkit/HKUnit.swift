import Foundation

/// Local unit algebra. Scale is the multiplier that converts one unit of this
/// type into SI (kg, m, s, A, K, mol, cd) plus a dimensionless `count` axis
/// and an affine offset used only for temperature.

public struct HKMetricPrefixFactors {
    private init() {}

    public static func factor(_ prefix: HKMetricPrefix) -> Double {
        switch prefix {
        case .none: return 1
        case .femto: return 1e-15
        case .pico: return 1e-12
        case .nano: return 1e-9
        case .micro: return 1e-6
        case .milli: return 1e-3
        case .centi: return 1e-2
        case .deci: return 1e-1
        case .deca: return 1e1
        case .hecto: return 1e2
        case .kilo: return 1e3
        case .mega: return 1e6
        case .giga: return 1e9
        case .tera: return 1e12
        }
    }

    public static func symbol(_ prefix: HKMetricPrefix) -> String {
        switch prefix {
        case .none: return ""
        case .femto: return "f"
        case .pico: return "p"
        case .nano: return "n"
        case .micro: return "µ"
        case .milli: return "m"
        case .centi: return "c"
        case .deci: return "d"
        case .deca: return "da"
        case .hecto: return "h"
        case .kilo: return "k"
        case .mega: return "M"
        case .giga: return "G"
        case .tera: return "T"
        }
    }
}

public final class HKUnit: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public struct Dimension: Hashable, Sendable {
        public var mass: Int
        public var length: Int
        public var time: Int
        public var current: Int
        public var temperature: Int
        public var amount: Int
        public var luminous: Int
        public var count: Int

        public init(
            mass: Int = 0,
            length: Int = 0,
            time: Int = 0,
            current: Int = 0,
            temperature: Int = 0,
            amount: Int = 0,
            luminous: Int = 0,
            count: Int = 0
        ) {
            self.mass = mass
            self.length = length
            self.time = time
            self.current = current
            self.temperature = temperature
            self.amount = amount
            self.luminous = luminous
            self.count = count
        }

        public static let none = Dimension()
        public static let mass = Dimension(mass: 1)
        public static let length = Dimension(length: 1)
        public static let time = Dimension(time: 1)
        public static let current = Dimension(current: 1)
        public static let temperature = Dimension(temperature: 1)
        public static let amount = Dimension(amount: 1)
        public static let luminous = Dimension(luminous: 1)
        public static let count = Dimension(count: 1)
        public static let energy = Dimension(mass: 1, length: 2, time: -2)
        public static let power = Dimension(mass: 1, length: 2, time: -3)
        public static let pressure = Dimension(mass: 1, length: -1, time: -2)
        public static let frequency = Dimension(time: -1)
        public static let volume = Dimension(length: 3)
        public static let speed = Dimension(length: 1, time: -1)
        public static let acceleration = Dimension(length: 1, time: -2)
        public static let angle = Dimension()
        public static let potential = Dimension(mass: 1, length: 2, time: -3, current: -1)
        public static let conductance = Dimension(mass: -1, length: -2, time: 3, current: 2)
        public static let illuminance = Dimension(length: -2, luminous: 1)
    }

    public let dimension: Dimension
    /// Multiply a value in this unit by `scaleToSI` then add `offsetToSI` to get SI.
    public let scaleToSI: Double
    public let offsetToSI: Double
    public let unitString: String

    public init(dimension: Dimension, scaleToSI: Double, offsetToSI: Double = 0, unitString: String) {
        self.dimension = dimension
        self.scaleToSI = scaleToSI
        self.offsetToSI = offsetToSI
        self.unitString = unitString
        super.init()
    }

    public required init?(coder: NSCoder) {
        let unitString = coder.decodeObject(of: NSString.self, forKey: "unitString") as String? ?? ""
        self.dimension = Dimension()
        self.scaleToSI = 1
        self.offsetToSI = 0
        self.unitString = unitString
        super.init()
        // Decoding an Apple archive is unobserved; keep a named unit if present.
    }

    public func encode(with coder: NSCoder) {
        coder.encode(unitString as NSString, forKey: "unitString")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        HKUnit(
            dimension: dimension,
            scaleToSI: scaleToSI,
            offsetToSI: offsetToSI,
            unitString: unitString
        )
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? HKUnit else { return false }
        return dimension == other.dimension
            && scaleToSI == other.scaleToSI
            && offsetToSI == other.offsetToSI
            && unitString == other.unitString
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(unitString)
        hasher.combine(scaleToSI)
        hasher.combine(offsetToSI)
        return hasher.finalize()
    }

    public func `is`(compatibleWith unit: HKUnit) -> Bool {
        dimension == unit.dimension
    }

    public func unitMultiplied(by unit: HKUnit) -> HKUnit {
        HKUnit(
            dimension: Dimension(
                mass: dimension.mass + unit.dimension.mass,
                length: dimension.length + unit.dimension.length,
                time: dimension.time + unit.dimension.time,
                current: dimension.current + unit.dimension.current,
                temperature: dimension.temperature + unit.dimension.temperature,
                amount: dimension.amount + unit.dimension.amount,
                luminous: dimension.luminous + unit.dimension.luminous,
                count: dimension.count + unit.dimension.count
            ),
            scaleToSI: scaleToSI * unit.scaleToSI,
            unitString: "\(unitString)*\(unit.unitString)"
        )
    }

    public func unitDivided(by unit: HKUnit) -> HKUnit {
        HKUnit(
            dimension: Dimension(
                mass: dimension.mass - unit.dimension.mass,
                length: dimension.length - unit.dimension.length,
                time: dimension.time - unit.dimension.time,
                current: dimension.current - unit.dimension.current,
                temperature: dimension.temperature - unit.dimension.temperature,
                amount: dimension.amount - unit.dimension.amount,
                luminous: dimension.luminous - unit.dimension.luminous,
                count: dimension.count - unit.dimension.count
            ),
            scaleToSI: scaleToSI / unit.scaleToSI,
            unitString: "\(unitString)/\(unit.unitString)"
        )
    }

    public func unitRaised(toPower power: Int) -> HKUnit {
        HKUnit(
            dimension: Dimension(
                mass: dimension.mass * power,
                length: dimension.length * power,
                time: dimension.time * power,
                current: dimension.current * power,
                temperature: dimension.temperature * power,
                amount: dimension.amount * power,
                luminous: dimension.luminous * power,
                count: dimension.count * power
            ),
            scaleToSI: pow(scaleToSI, Double(power)),
            unitString: "\(unitString)\(power)"
        )
    }

    public func reciprocalUnit() -> HKUnit {
        unitRaised(toPower: -1)
    }

    public func reciprocal() -> HKUnit {
        reciprocalUnit()
    }

    public func isNull() -> Bool {
        unitString.isEmpty
    }

    private static func metric(_ prefix: HKMetricPrefix, baseSymbol: String, dimension: Dimension, baseScale: Double) -> HKUnit {
        let factor = HKMetricPrefixFactors.factor(prefix)
        let symbol = HKMetricPrefixFactors.symbol(prefix) + baseSymbol
        return HKUnit(dimension: dimension, scaleToSI: baseScale * factor, unitString: symbol)
    }

    public class func gram() -> HKUnit { gramUnit(with: .none) }
    public class func gramUnit(with prefix: HKMetricPrefix) -> HKUnit {
        metric(prefix, baseSymbol: "g", dimension: .mass, baseScale: 0.001)
    }

    public class func meter() -> HKUnit { meterUnit(with: .none) }
    public class func meterUnit(with prefix: HKMetricPrefix) -> HKUnit {
        metric(prefix, baseSymbol: "m", dimension: .length, baseScale: 1)
    }

    public class func second() -> HKUnit { secondUnit(with: .none) }
    public class func secondUnit(with prefix: HKMetricPrefix) -> HKUnit {
        metric(prefix, baseSymbol: "s", dimension: .time, baseScale: 1)
    }

    public class func liter() -> HKUnit { literUnit(with: .none) }
    public class func literUnit(with prefix: HKMetricPrefix) -> HKUnit {
        metric(prefix, baseSymbol: "L", dimension: .volume, baseScale: 0.001)
    }

    public class func pascal() -> HKUnit { pascalUnit(with: .none) }
    public class func pascalUnit(with prefix: HKMetricPrefix) -> HKUnit {
        metric(prefix, baseSymbol: "Pa", dimension: .pressure, baseScale: 1)
    }

    public class func joule() -> HKUnit { jouleUnit(with: .none) }
    public class func jouleUnit(with prefix: HKMetricPrefix) -> HKUnit {
        metric(prefix, baseSymbol: "J", dimension: .energy, baseScale: 1)
    }

    public class func watt() -> HKUnit { wattUnit(with: .none) }
    public class func wattUnit(with prefix: HKMetricPrefix) -> HKUnit {
        metric(prefix, baseSymbol: "W", dimension: .power, baseScale: 1)
    }

    public class func hertz() -> HKUnit { hertzUnit(with: .none) }
    public class func hertzUnit(with prefix: HKMetricPrefix) -> HKUnit {
        metric(prefix, baseSymbol: "Hz", dimension: .frequency, baseScale: 1)
    }

    public class func volt() -> HKUnit { voltUnit(with: .none) }
    public class func voltUnit(with prefix: HKMetricPrefix) -> HKUnit {
        metric(prefix, baseSymbol: "V", dimension: .potential, baseScale: 1)
    }

    public class func siemen() -> HKUnit { siemenUnit(with: .none) }
    public class func siemenUnit(with prefix: HKMetricPrefix) -> HKUnit {
        metric(prefix, baseSymbol: "S", dimension: .conductance, baseScale: 1)
    }

    public class func lux() -> HKUnit { luxUnit(with: .none) }
    public class func luxUnit(with prefix: HKMetricPrefix) -> HKUnit {
        metric(prefix, baseSymbol: "lx", dimension: .illuminance, baseScale: 1)
    }

    public class func radianAngle() -> HKUnit { radianAngleUnit(with: .none) }
    public class func radianAngleUnit(with prefix: HKMetricPrefix) -> HKUnit {
        metric(prefix, baseSymbol: "rad", dimension: .angle, baseScale: 1)
    }

    public class func kelvin() -> HKUnit {
        HKUnit(dimension: .temperature, scaleToSI: 1, unitString: "K")
    }

    public class func degreeCelsius() -> HKUnit {
        HKUnit(dimension: .temperature, scaleToSI: 1, offsetToSI: 273.15, unitString: "degC")
    }

    public class func degreeFahrenheit() -> HKUnit {
        HKUnit(dimension: .temperature, scaleToSI: 5.0 / 9.0, offsetToSI: 255.37222222222223, unitString: "degF")
    }

    public class func count() -> HKUnit {
        HKUnit(dimension: .count, scaleToSI: 1, unitString: "count")
    }

    public class func percent() -> HKUnit {
        HKUnit(dimension: .count, scaleToSI: 0.01, unitString: "%")
    }

    public class func calorie() -> HKUnit {
        HKUnit(dimension: .energy, scaleToSI: 4.184, unitString: "cal")
    }

    public class func kilocalorie() -> HKUnit {
        HKUnit(dimension: .energy, scaleToSI: 4184, unitString: "kcal")
    }

    public class func largeCalorie() -> HKUnit { kilocalorie() }
    public class func smallCalorie() -> HKUnit { calorie() }

    public class func minute() -> HKUnit {
        HKUnit(dimension: .time, scaleToSI: 60, unitString: "min")
    }

    public class func hour() -> HKUnit {
        HKUnit(dimension: .time, scaleToSI: 3600, unitString: "hr")
    }

    public class func day() -> HKUnit {
        HKUnit(dimension: .time, scaleToSI: 86400, unitString: "d")
    }

    public class func inch() -> HKUnit {
        HKUnit(dimension: .length, scaleToSI: 0.0254, unitString: "in")
    }

    public class func foot() -> HKUnit {
        HKUnit(dimension: .length, scaleToSI: 0.3048, unitString: "ft")
    }

    public class func mile() -> HKUnit {
        HKUnit(dimension: .length, scaleToSI: 1609.344, unitString: "mi")
    }

    public class func yard() -> HKUnit {
        HKUnit(dimension: .length, scaleToSI: 0.9144, unitString: "yd")
    }

    public class func ounce() -> HKUnit {
        HKUnit(dimension: .mass, scaleToSI: 0.028349523125, unitString: "oz")
    }

    public class func pound() -> HKUnit {
        HKUnit(dimension: .mass, scaleToSI: 0.45359237, unitString: "lb")
    }

    public class func stone() -> HKUnit {
        HKUnit(dimension: .mass, scaleToSI: 6.35029318, unitString: "st")
    }

    public class func atmosphere() -> HKUnit {
        HKUnit(dimension: .pressure, scaleToSI: 101325, unitString: "atm")
    }

    public class func millimeterOfMercury() -> HKUnit {
        HKUnit(dimension: .pressure, scaleToSI: 133.322368421, unitString: "mmHg")
    }

    public class func inchesOfMercury() -> HKUnit {
        HKUnit(dimension: .pressure, scaleToSI: 3386.389, unitString: "inHg")
    }

    public class func centimeterOfWater() -> HKUnit {
        HKUnit(dimension: .pressure, scaleToSI: 98.0665, unitString: "cmAq")
    }

    public class func fluidOunceUS() -> HKUnit {
        HKUnit(dimension: .volume, scaleToSI: 2.95735295625e-5, unitString: "fl_oz_us")
    }

    public class func fluidOunceImperial() -> HKUnit {
        HKUnit(dimension: .volume, scaleToSI: 2.84130625e-5, unitString: "fl_oz_imp")
    }

    public class func pintUS() -> HKUnit {
        HKUnit(dimension: .volume, scaleToSI: 0.000473176473, unitString: "pt_us")
    }

    public class func pintImperial() -> HKUnit {
        HKUnit(dimension: .volume, scaleToSI: 0.00056826125, unitString: "pt_imp")
    }

    public class func cupUS() -> HKUnit {
        HKUnit(dimension: .volume, scaleToSI: 0.0002365882365, unitString: "cup_us")
    }

    public class func cupImperial() -> HKUnit {
        HKUnit(dimension: .volume, scaleToSI: 0.000284130625, unitString: "cup_imp")
    }

    public class func degreeAngle() -> HKUnit {
        HKUnit(dimension: .angle, scaleToSI: Double.pi / 180.0, unitString: "deg")
    }

    public class func internationalUnit() -> HKUnit {
        HKUnit(dimension: .count, scaleToSI: 1, unitString: "IU")
    }

    public class func diopter() -> HKUnit {
        HKUnit(dimension: Dimension(length: -1), scaleToSI: 1, unitString: "dpt")
    }

    public class func prismDiopter() -> HKUnit { diopter() }

    public class func decibelAWeightedSoundPressureLevel() -> HKUnit {
        HKUnit(dimension: .count, scaleToSI: 1, unitString: "dBASPL")
    }

    public class func decibelHearingLevel() -> HKUnit {
        HKUnit(dimension: .count, scaleToSI: 1, unitString: "dBHL")
    }

    public class func appleEffortScore() -> HKUnit {
        HKUnit(dimension: .count, scaleToSI: 1, unitString: "appleEffortScore")
    }

    public class func moleUnit(withMolarMass gramsPerMole: Double) -> HKUnit {
        moleUnit(with: .none, molarMass: gramsPerMole)
    }

    public class func moleUnit(with prefix: HKMetricPrefix, molarMass gramsPerMole: Double) -> HKUnit {
        let factor = HKMetricPrefixFactors.factor(prefix)
        let symbol = "\(HKMetricPrefixFactors.symbol(prefix))mol<\(gramsPerMole)>"
        return HKUnit(dimension: .amount, scaleToSI: factor, unitString: symbol)
    }

    public class func unit(_ unitString: String) -> HKUnit? {
        // Only the factories above are a closed Linux conversion table.
        // Arbitrary Apple unit strings are not reverse-engineered here.
        _ = unitString
        return nil
    }

    public class func energyFormatterUnit(from unit: HKUnit) -> EnergyFormatter.Unit {
        if unit.`is`(compatibleWith: kilocalorie()) { return .kilocalorie }
        if unit.`is`(compatibleWith: calorie()) { return .calorie }
        return .joule
    }

    public class func lengthFormatterUnit(from unit: HKUnit) -> LengthFormatter.Unit {
        if unit.isEqual(mile()) { return .mile }
        if unit.isEqual(yard()) { return .yard }
        if unit.isEqual(foot()) { return .foot }
        if unit.isEqual(inch()) { return .inch }
        if unit.isEqual(meterUnit(with: .milli)) { return .millimeter }
        if unit.isEqual(meterUnit(with: .centi)) { return .centimeter }
        if unit.isEqual(meterUnit(with: .kilo)) { return .kilometer }
        return .meter
    }

    public class func massFormatterUnit(from unit: HKUnit) -> MassFormatter.Unit {
        if unit.isEqual(pound()) { return .pound }
        if unit.isEqual(ounce()) { return .ounce }
        if unit.isEqual(stone()) { return .stone }
        if unit.isEqual(gramUnit(with: .kilo)) { return .kilogram }
        return .gram
    }
}
