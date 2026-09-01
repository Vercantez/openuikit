import Foundation

/// Dimensional HealthKit unit. Compatible units convert through SI scale
/// (and an affine offset for temperature). Composite units preserve a
/// synthesized `unitString` in Apple's common `num/den` form.
open class HKUnit: NSObject, NSCopying {
    public let unitString: String

    let dimension: HKUnitDimension
    let scale: Double
    let offset: Double

    init(unitString: String, dimension: HKUnitDimension, scale: Double, offset: Double = 0) {
        self.unitString = unitString
        self.dimension = dimension
        self.scale = scale
        self.offset = offset
        super.init()
    }

    public convenience init(from string: String) {
        self.init(fromString: string)
    }

    public convenience init(fromString string: String) {
        if let parsed = HKUnit.parse(string) {
            self.init(
                unitString: parsed.unitString,
                dimension: parsed.dimension,
                scale: parsed.scale,
                offset: parsed.offset
            )
        } else {
            self.init(unitString: string, dimension: .none, scale: 1, offset: 0)
        }
    }

    public convenience init(from energyFormatterUnit: EnergyFormatter.Unit) {
        self.init(fromEnergyFormatterUnit: energyFormatterUnit)
    }

    public convenience init(fromEnergyFormatterUnit energyFormatterUnit: EnergyFormatter.Unit) {
        switch energyFormatterUnit {
        case .calorie:
            self.init(unitString: "cal", dimension: .energy, scale: 4.184)
        case .kilocalorie:
            self.init(unitString: "kcal", dimension: .energy, scale: 4184)
        case .joule:
            self.init(unitString: "J", dimension: .energy, scale: 1)
        case .kilojoule:
            self.init(unitString: "kJ", dimension: .energy, scale: 1000)
        @unknown default:
            self.init(unitString: "J", dimension: .energy, scale: 1)
        }
    }

    public convenience init(from lengthFormatterUnit: LengthFormatter.Unit) {
        self.init(fromLengthFormatterUnit: lengthFormatterUnit)
    }

    public convenience init(fromLengthFormatterUnit lengthFormatterUnit: LengthFormatter.Unit) {
        switch lengthFormatterUnit {
        case .millimeter:
            self.init(unitString: "mm", dimension: .length, scale: 0.001)
        case .centimeter:
            self.init(unitString: "cm", dimension: .length, scale: 0.01)
        case .meter:
            self.init(unitString: "m", dimension: .length, scale: 1)
        case .kilometer:
            self.init(unitString: "km", dimension: .length, scale: 1000)
        case .inch:
            self.init(unitString: "in", dimension: .length, scale: 0.0254)
        case .foot:
            self.init(unitString: "ft", dimension: .length, scale: 0.3048)
        case .yard:
            self.init(unitString: "yd", dimension: .length, scale: 0.9144)
        case .mile:
            self.init(unitString: "mi", dimension: .length, scale: 1609.344)
        @unknown default:
            self.init(unitString: "m", dimension: .length, scale: 1)
        }
    }

    public convenience init(from massFormatterUnit: MassFormatter.Unit) {
        self.init(fromMassFormatterUnit: massFormatterUnit)
    }

    public convenience init(fromMassFormatterUnit massFormatterUnit: MassFormatter.Unit) {
        switch massFormatterUnit {
        case .gram:
            self.init(unitString: "g", dimension: .mass, scale: 0.001)
        case .kilogram:
            self.init(unitString: "kg", dimension: .mass, scale: 1)
        case .ounce:
            self.init(unitString: "oz", dimension: .mass, scale: 0.028349523125)
        case .pound:
            self.init(unitString: "lb", dimension: .mass, scale: 0.45359237)
        case .stone:
            self.init(unitString: "st", dimension: .mass, scale: 6.35029318)
        @unknown default:
            self.init(unitString: "g", dimension: .mass, scale: 0.001)
        }
    }

    public convenience init?(coder: NSCoder) {
        return nil
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        HKUnit(unitString: unitString, dimension: dimension, scale: scale, offset: offset)
    }

    public func isNull() -> Bool {
        unitString.isEmpty
    }

    public func unitMultiplied(by unit: HKUnit) -> HKUnit {
        HKUnit(
            unitString: HKUnit.composeString(self, "*", unit),
            dimension: dimension.adding(unit.dimension),
            scale: scale * unit.scale,
            offset: 0
        )
    }

    public func unitDivided(by unit: HKUnit) -> HKUnit {
        HKUnit(
            unitString: HKUnit.composeString(self, "/", unit),
            dimension: dimension.subtracting(unit.dimension),
            scale: scale / unit.scale,
            offset: 0
        )
    }

    public func unitRaised(toPower power: Int) -> HKUnit {
        if power == 1 { return self }
        return HKUnit(
            unitString: power == 0 ? "" : "\(unitString)^\((power))",
            dimension: dimension.scaled(by: power),
            scale: pow(scale, Double(power)),
            offset: 0
        )
    }

    public func reciprocal() -> HKUnit {
        unitRaised(toPower: -1)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? HKUnit else { return false }
        return unitString == other.unitString
            && dimension == other.dimension
            && scale == other.scale
            && offset == other.offset
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(unitString)
        hasher.combine(scale)
        hasher.combine(offset)
        return hasher.finalize()
    }

    public func isCompatible(with other: HKUnit) -> Bool {
        dimension == other.dimension && dimension != .none
            || (dimension == other.dimension && unitString == other.unitString)
    }

    func convert(_ value: Double, to other: HKUnit) -> Double {
        let si = value * scale + offset
        return (si - other.offset) / other.scale
    }

    private static func composeString(_ lhs: HKUnit, _ op: String, _ rhs: HKUnit) -> String {
        if op == "/" {
            return "\(lhs.unitString)/\(rhs.unitString)"
        }
        return "\(lhs.unitString)*\(rhs.unitString)"
    }

    private static func built(
        _ unitString: String,
        _ dimension: HKUnitDimension,
        _ scale: Double,
        offset: Double = 0
    ) -> HKUnit {
        HKUnit(unitString: unitString, dimension: dimension, scale: scale, offset: offset)
    }

    private static func typed(_ unit: HKUnit) -> Self {
        unsafeDowncast(unit, to: Self.self)
    }

    open class func gram() -> Self {
        typed(built("g", .mass, 0.001))
    }
    open class func gramUnit(with prefix: HKMetricPrefix) -> Self {
        typed(built(prefix.symbol + "g", .mass, prefix.factor * 0.001))
    }
    open class func meter() -> Self {
        typed(built("m", .length, 1))
    }
    open class func meterUnit(with prefix: HKMetricPrefix) -> Self {
        typed(built(prefix.symbol + "m", .length, prefix.factor))
    }
    open class func liter() -> Self {
        typed(built("L", .volume, 0.001))
    }
    open class func literUnit(with prefix: HKMetricPrefix) -> Self {
        typed(built(prefix.symbol + "L", .volume, prefix.factor * 0.001))
    }
    open class func second() -> Self {
        typed(built("s", .time, 1))
    }
    open class func secondUnit(with prefix: HKMetricPrefix) -> Self {
        typed(built(prefix.symbol + "s", .time, prefix.factor))
    }
    open class func joule() -> Self {
        typed(built("J", .energy, 1))
    }
    open class func jouleUnit(with prefix: HKMetricPrefix) -> Self {
        typed(built(prefix.symbol + "J", .energy, prefix.factor))
    }
    open class func pascal() -> Self {
        typed(built("Pa", .pressure, 1))
    }
    open class func pascalUnit(with prefix: HKMetricPrefix) -> Self {
        typed(built(prefix.symbol + "Pa", .pressure, prefix.factor))
    }
    open class func hertz() -> Self {
        typed(built("Hz", .frequency, 1))
    }
    open class func hertzUnit(with prefix: HKMetricPrefix) -> Self {
        typed(built(prefix.symbol + "Hz", .frequency, prefix.factor))
    }
    open class func volt() -> Self {
        typed(built("V", .voltage, 1))
    }
    open class func voltUnit(with prefix: HKMetricPrefix) -> Self {
        typed(built(prefix.symbol + "V", .voltage, prefix.factor))
    }
    open class func watt() -> Self {
        typed(built("W", .power, 1))
    }
    open class func wattUnit(with prefix: HKMetricPrefix) -> Self {
        typed(built(prefix.symbol + "W", .power, prefix.factor))
    }
    open class func siemen() -> Self {
        typed(built("S", .conductance, 1))
    }
    open class func siemenUnit(with prefix: HKMetricPrefix) -> Self {
        typed(built(prefix.symbol + "S", .conductance, prefix.factor))
    }
    open class func lux() -> Self {
        typed(built("lx", .illuminance, 1))
    }
    open class func luxUnit(with prefix: HKMetricPrefix) -> Self {
        typed(built(prefix.symbol + "lx", .illuminance, prefix.factor))
    }
    open class func radianAngle() -> Self {
        typed(built("rad", .angle, 1))
    }
    open class func radianAngleUnit(with prefix: HKMetricPrefix) -> Self {
        typed(built(prefix.symbol + "rad", .angle, prefix.factor))
    }

    open class func moleUnit(withMolarMass gramsPerMole: Double) -> Self {
        moleUnit(with: .none, molarMass: gramsPerMole)
    }

    open class func moleUnit(with prefix: HKMetricPrefix, molarMass gramsPerMole: Double) -> Self {
        let formatted = String(format: "%g", gramsPerMole)
        return typed(
            built(
                "\(prefix.symbol)mol<\(formatted)>",
                .molarConcentration(gramsPerMole),
                prefix.factor
            )
        )
    }

    open class func count() -> Self { typed(built("count", .count, 1)) }
    open class func percent() -> Self { typed(built("%", .scalar, 0.01)) }
    open class func internationalUnit() -> Self { typed(built("IU", .iu, 1)) }
    open class func minute() -> Self { typed(built("min", .time, 60)) }
    open class func hour() -> Self { typed(built("hr", .time, 3600)) }
    open class func day() -> Self { typed(built("d", .time, 86400)) }
    open class func inch() -> Self { typed(built("in", .length, 0.0254)) }
    open class func foot() -> Self { typed(built("ft", .length, 0.3048)) }
    open class func yard() -> Self { typed(built("yd", .length, 0.9144)) }
    open class func mile() -> Self { typed(built("mi", .length, 1609.344)) }
    open class func ounce() -> Self { typed(built("oz", .mass, 0.028349523125)) }
    open class func pound() -> Self { typed(built("lb", .mass, 0.45359237)) }
    open class func stone() -> Self { typed(built("st", .mass, 6.35029318)) }
    open class func fluidOunceUS() -> Self { typed(built("fl_oz_us", .volume, 2.95735295625e-5)) }
    open class func fluidOunceImperial() -> Self { typed(built("fl_oz_imp", .volume, 2.84130625e-5)) }
    open class func pintUS() -> Self { typed(built("pt_us", .volume, 0.000473176473)) }
    open class func pintImperial() -> Self { typed(built("pt_imp", .volume, 0.00056826125)) }
    open class func cupUS() -> Self { typed(built("cup_us", .volume, 0.0002365882365)) }
    open class func cupImperial() -> Self { typed(built("cup_imp", .volume, 0.000284130625)) }
    open class func calorie() -> Self { smallCalorie() }
    open class func smallCalorie() -> Self { typed(built("cal", .energy, 4.184)) }
    open class func largeCalorie() -> Self { kilocalorie() }
    open class func kilocalorie() -> Self { typed(built("kcal", .energy, 4184)) }
    open class func kelvin() -> Self { typed(built("K", .temperature, 1, offset: 0)) }
    open class func degreeCelsius() -> Self { typed(built("degC", .temperature, 1, offset: 273.15)) }
    open class func degreeFahrenheit() -> Self {
        typed(built("degF", .temperature, 5.0 / 9.0, offset: 255.37222222222223))
    }
    open class func atmosphere() -> Self { typed(built("atm", .pressure, 101325)) }
    open class func millimeterOfMercury() -> Self { typed(built("mmHg", .pressure, 133.322387415)) }
    open class func centimeterOfWater() -> Self { typed(built("cmAq", .pressure, 98.0665)) }
    open class func inchesOfMercury() -> Self { typed(built("inHg", .pressure, 3386.389)) }
    open class func degreeAngle() -> Self { typed(built("deg", .angle, Double.pi / 180.0)) }
    open class func diopter() -> Self { typed(built("dpt", .reciprocalLength, 1)) }
    open class func prismDiopter() -> Self { typed(built("prdpt", .scalar, 1)) }
    open class func decibelAWeightedSoundPressureLevel() -> Self {
        typed(built("dBASPL", .soundPressure, 1))
    }
    open class func decibelHearingLevel() -> Self {
        typed(built("dBHL", .soundPressure, 1))
    }
    open class func appleEffortScore() -> Self {
        typed(built("appleEffortScore", .scalar, 1))
    }

    open class func energyFormatterUnit(from unit: HKUnit) -> EnergyFormatter.Unit {
        if unit.unitString == "kcal" || unit.unitString == "Cal" { return .kilocalorie }
        if unit.unitString == "cal" { return .calorie }
        if unit.unitString == "kJ" { return .kilojoule }
        return .joule
    }

    open class func lengthFormatterUnit(from unit: HKUnit) -> LengthFormatter.Unit {
        switch unit.unitString {
        case "mm": return .millimeter
        case "cm": return .centimeter
        case "km": return .kilometer
        case "in": return .inch
        case "ft": return .foot
        case "yd": return .yard
        case "mi": return .mile
        default: return .meter
        }
    }

    open class func massFormatterUnit(from unit: HKUnit) -> MassFormatter.Unit {
        switch unit.unitString {
        case "kg": return .kilogram
        case "oz": return .ounce
        case "lb": return .pound
        case "st": return .stone
        default: return .gram
        }
    }

    private static func parse(_ string: String) -> HKUnit? {
        if string.isEmpty {
            return HKUnit(unitString: "", dimension: .none, scale: 1)
        }
        if let simple = namedUnits[string] {
            return simple
        }
        if string.contains("/") {
            let parts = string.split(separator: "/", maxSplits: 1).map(String.init)
            if parts.count == 2, let num = parse(parts[0]), let den = parse(parts[1]) {
                return num.unitDivided(by: den)
            }
        }
        return nil
    }

    private static let namedUnits: [String: HKUnit] = {
        let samples: [HKUnit] = [
            .gram(), .meter(), .liter(), .second(), .joule(), .pascal(), .hertz(),
            .volt(), .watt(), .siemen(), .lux(), .count(), .percent(),
            .kilocalorie(), .calorie(), .kelvin(), .degreeCelsius(), .degreeFahrenheit(),
            .minute(), .hour(), .day(), .inch(), .foot(), .mile(), .pound(), .ounce(),
            .millimeterOfMercury(), .atmosphere(),
            gramUnit(with: .kilo), gramUnit(with: .milli), gramUnit(with: .micro),
            meterUnit(with: .kilo), meterUnit(with: .centi), meterUnit(with: .milli),
            literUnit(with: .milli),
        ]
        var map: [String: HKUnit] = [:]
        for unit in samples {
            map[unit.unitString] = unit
        }
        map["kg"] = .gramUnit(with: .kilo)
        map["mg"] = .gramUnit(with: .milli)
        map["µg"] = .gramUnit(with: .micro)
        map["cm"] = .meterUnit(with: .centi)
        map["mm"] = .meterUnit(with: .milli)
        map["km"] = .meterUnit(with: .kilo)
        map["mL"] = .literUnit(with: .milli)
        map["ml"] = .literUnit(with: .milli)
        return map
    }()
}

struct HKUnitDimension: Equatable, Hashable {
    var mass: Int = 0
    var length: Int = 0
    var time: Int = 0
    var current: Int = 0
    var temperature: Int = 0
    var amount: Int = 0
    var luminous: Int = 0
    var angle: Int = 0
    var count: Int = 0
    var scalar: Int = 0
    var iu: Int = 0
    var sound: Int = 0
    var molarMass: Double = 0

    static let none = HKUnitDimension()
    static let mass = HKUnitDimension(mass: 1)
    static let length = HKUnitDimension(length: 1)
    static let time = HKUnitDimension(time: 1)
    static let temperature = HKUnitDimension(temperature: 1)
    static let count = HKUnitDimension()
    static let scalar = HKUnitDimension(scalar: 1)
    static let iu = HKUnitDimension(iu: 1)
    static let angle = HKUnitDimension(angle: 1)
    static let illuminance = HKUnitDimension(length: -2, luminous: 1)
    static let soundPressure = HKUnitDimension(sound: 1)
    static let reciprocalLength = HKUnitDimension(length: -1)
    static let energy = HKUnitDimension(mass: 1, length: 2, time: -2)
    static let volume = HKUnitDimension(length: 3)
    static let pressure = HKUnitDimension(mass: 1, length: -1, time: -2)
    static let frequency = HKUnitDimension(time: -1)
    static let power = HKUnitDimension(mass: 1, length: 2, time: -3)
    static let voltage = HKUnitDimension(mass: 1, length: 2, time: -3, current: -1)
    static let conductance = HKUnitDimension(mass: -1, length: -2, time: 3, current: 2)

    static func molarConcentration(_ gramsPerMole: Double) -> HKUnitDimension {
        HKUnitDimension(amount: 1, molarMass: gramsPerMole)
    }

    func adding(_ other: HKUnitDimension) -> HKUnitDimension {
        var d = self
        d.mass += other.mass
        d.length += other.length
        d.time += other.time
        d.current += other.current
        d.temperature += other.temperature
        d.amount += other.amount
        d.luminous += other.luminous
        d.angle += other.angle
        d.count += other.count
        d.scalar += other.scalar
        d.iu += other.iu
        d.sound += other.sound
        if d.molarMass == 0 { d.molarMass = other.molarMass }
        return d
    }

    func subtracting(_ other: HKUnitDimension) -> HKUnitDimension {
        other.scaled(by: -1).adding(self)
    }

    func scaled(by factor: Int) -> HKUnitDimension {
        var d = self
        d.mass *= factor
        d.length *= factor
        d.time *= factor
        d.current *= factor
        d.temperature *= factor
        d.amount *= factor
        d.luminous *= factor
        d.angle *= factor
        d.count *= factor
        d.scalar *= factor
        d.iu *= factor
        d.sound *= factor
        return d
    }
}

extension HKMetricPrefix {
    var factor: Double {
        switch self {
        case .femto: return 1e-15
        case .pico: return 1e-12
        case .nano: return 1e-9
        case .micro: return 1e-6
        case .milli: return 1e-3
        case .centi: return 1e-2
        case .deci: return 1e-1
        case .none: return 1
        case .deca: return 1e1
        case .hecto: return 1e2
        case .kilo: return 1e3
        case .mega: return 1e6
        case .giga: return 1e9
        case .tera: return 1e12
        }
    }

    var symbol: String {
        switch self {
        case .femto: return "f"
        case .pico: return "p"
        case .nano: return "n"
        case .micro: return "µ"
        case .milli: return "m"
        case .centi: return "c"
        case .deci: return "d"
        case .none: return ""
        case .deca: return "da"
        case .hecto: return "h"
        case .kilo: return "k"
        case .mega: return "M"
        case .giga: return "G"
        case .tera: return "T"
        }
    }
}
