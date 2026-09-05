import Foundation

public struct UVIndex: Equatable, Codable, Sendable {
    @frozen
    public enum ExposureCategory: String, Codable, CaseIterable, Sendable, Hashable, Comparable {
        case low
        case moderate
        case high
        case veryHigh
        case extreme

        public static func < (lhs: ExposureCategory, rhs: ExposureCategory) -> Bool {
            lhs.rank < rhs.rank
        }

        var rank: Int {
            switch self {
            case .low: return 0
            case .moderate: return 1
            case .high: return 2
            case .veryHigh: return 3
            case .extreme: return 4
            }
        }

        public var rangeValue: ClosedRange<Int> {
            switch self {
            case .low: return 0...2
            case .moderate: return 3...5
            case .high: return 6...7
            case .veryHigh: return 8...10
            case .extreme: return 11...Int.max
            }
        }

        public var description: String { weatherKitTitleCase(rawValue) }

        public var accessibilityDescription: String { description }
    }

    public var value: Int

    public init(value: Int) {
        self.value = value
    }

    public var category: ExposureCategory {
        switch value {
        case ...2: return .low
        case 3...5: return .moderate
        case 6...7: return .high
        case 8...10: return .veryHigh
        default: return value < 0 ? .low : .extreme
        }
    }
}

public struct Wind: Equatable, Codable, Sendable {
    @frozen
    public enum CompassDirection: String, Codable, CaseIterable, Sendable, Hashable {
        case north
        case northNortheast
        case northeast
        case eastNortheast
        case east
        case eastSoutheast
        case southeast
        case southSoutheast
        case south
        case southSouthwest
        case southwest
        case westSouthwest
        case west
        case westNorthwest
        case northwest
        case northNorthwest

        public var abbreviation: String {
            switch self {
            case .north: return "N"
            case .northNortheast: return "NNE"
            case .northeast: return "NE"
            case .eastNortheast: return "ENE"
            case .east: return "E"
            case .eastSoutheast: return "ESE"
            case .southeast: return "SE"
            case .southSoutheast: return "SSE"
            case .south: return "S"
            case .southSouthwest: return "SSW"
            case .southwest: return "SW"
            case .westSouthwest: return "WSW"
            case .west: return "W"
            case .westNorthwest: return "WNW"
            case .northwest: return "NW"
            case .northNorthwest: return "NNW"
            }
        }

        public var description: String {
            switch self {
            case .north: return "North"
            case .northNortheast: return "North Northeast"
            case .northeast: return "Northeast"
            case .eastNortheast: return "East Northeast"
            case .east: return "East"
            case .eastSoutheast: return "East Southeast"
            case .southeast: return "Southeast"
            case .southSoutheast: return "South Southeast"
            case .south: return "South"
            case .southSouthwest: return "South Southwest"
            case .southwest: return "Southwest"
            case .westSouthwest: return "West Southwest"
            case .west: return "West"
            case .westNorthwest: return "West Northwest"
            case .northwest: return "Northwest"
            case .northNorthwest: return "North Northwest"
            }
        }

        public var accessibilityDescription: String { description }

        public init(degrees: Double) {
            let normalized = (degrees.truncatingRemainder(dividingBy: 360) + 360)
                .truncatingRemainder(dividingBy: 360)
            let index = Int((normalized + 11.25) / 22.5) % CompassDirection.allCases.count
            self = CompassDirection.allCases[index]
        }
    }

    public var direction: Measurement<UnitAngle>
    public var speed: Measurement<UnitSpeed>
    public var gust: Measurement<UnitSpeed>?

    public init(
        direction: Measurement<UnitAngle>,
        speed: Measurement<UnitSpeed>,
        gust: Measurement<UnitSpeed>? = nil
    ) {
        self.direction = direction
        self.speed = speed
        self.gust = gust
    }

    public var compassDirection: CompassDirection {
        CompassDirection(degrees: direction.converted(to: .degrees).value)
    }
}

public struct CloudCoverByAltitude: Equatable, Codable, Sendable {
    public var low: Double
    public var medium: Double
    public var high: Double

    public init(low: Double, medium: Double, high: Double) {
        self.low = low
        self.medium = medium
        self.high = high
    }
}

public struct SnowfallAmount: Equatable, Codable, Sendable {
    public var amount: Measurement<UnitLength>
    public var amountLiquidEquivalent: Measurement<UnitLength>
    public var maximum: Measurement<UnitLength>
    public var maximumLiquidEquivalent: Measurement<UnitLength>
    public var minimum: Measurement<UnitLength>
    public var minimumLiquidEquivalent: Measurement<UnitLength>

    public init(
        amount: Measurement<UnitLength>,
        amountLiquidEquivalent: Measurement<UnitLength>,
        maximum: Measurement<UnitLength>,
        maximumLiquidEquivalent: Measurement<UnitLength>,
        minimum: Measurement<UnitLength>,
        minimumLiquidEquivalent: Measurement<UnitLength>
    ) {
        self.amount = amount
        self.amountLiquidEquivalent = amountLiquidEquivalent
        self.maximum = maximum
        self.maximumLiquidEquivalent = maximumLiquidEquivalent
        self.minimum = minimum
        self.minimumLiquidEquivalent = minimumLiquidEquivalent
    }
}

public struct PrecipitationAmountByType: Equatable, Codable, Sendable {
    public var precipitation: Measurement<UnitLength>
    public var rainfall: Measurement<UnitLength>
    public var snowfallAmount: SnowfallAmount
    public var hail: Measurement<UnitLength>
    public var mixed: Measurement<UnitLength>
    public var sleet: Measurement<UnitLength>

    public init(
        precipitation: Measurement<UnitLength>,
        rainfall: Measurement<UnitLength>,
        snowfallAmount: SnowfallAmount,
        hail: Measurement<UnitLength>,
        mixed: Measurement<UnitLength>,
        sleet: Measurement<UnitLength>
    ) {
        self.precipitation = precipitation
        self.rainfall = rainfall
        self.snowfallAmount = snowfallAmount
        self.hail = hail
        self.mixed = mixed
        self.sleet = sleet
    }
}

public struct Percentiles<Dimension>: Equatable, Codable, Sendable where Dimension: Foundation.Dimension {
    public var p10: Measurement<Dimension>
    public var p50: Measurement<Dimension>
    public var p90: Measurement<Dimension>

    public init(
        p10: Measurement<Dimension>,
        p50: Measurement<Dimension>,
        p90: Measurement<Dimension>
    ) {
        self.p10 = p10
        self.p50 = p50
        self.p90 = p90
    }
}

public struct TrendBaseline<Dimension>: Equatable, Codable, Sendable where Dimension: Foundation.Dimension {
    public enum Kind: Codable, Equatable, Hashable, Sendable {
        case mean
    }

    public let kind: Kind
    public let value: Measurement<Dimension>
    public let startDate: Date

    public init(kind: Kind, value: Measurement<Dimension>, startDate: Date) {
        self.kind = kind
        self.value = value
        self.startDate = startDate
    }
}

public struct Trend<Dimension>: Equatable, Codable, Sendable where Dimension: Foundation.Dimension {
    public var currentValue: Measurement<Dimension>
    public var baseline: TrendBaseline<Dimension>
    public var deviation: Deviation

    public init(
        currentValue: Measurement<Dimension>,
        baseline: TrendBaseline<Dimension>,
        deviation: Deviation
    ) {
        self.currentValue = currentValue
        self.baseline = baseline
        self.deviation = deviation
    }
}

public struct SunEvents: Equatable, Codable, Sendable {
    public var sunrise: Date?
    public var sunset: Date?
    public var civilDawn: Date?
    public var civilDusk: Date?
    public var nauticalDawn: Date?
    public var nauticalDusk: Date?
    public var astronomicalDawn: Date?
    public var astronomicalDusk: Date?
    public var solarNoon: Date?
    public var solarMidnight: Date?

    public init(
        sunrise: Date? = nil,
        sunset: Date? = nil,
        civilDawn: Date? = nil,
        civilDusk: Date? = nil,
        nauticalDawn: Date? = nil,
        nauticalDusk: Date? = nil,
        astronomicalDawn: Date? = nil,
        astronomicalDusk: Date? = nil,
        solarNoon: Date? = nil,
        solarMidnight: Date? = nil
    ) {
        self.sunrise = sunrise
        self.sunset = sunset
        self.civilDawn = civilDawn
        self.civilDusk = civilDusk
        self.nauticalDawn = nauticalDawn
        self.nauticalDusk = nauticalDusk
        self.astronomicalDawn = astronomicalDawn
        self.astronomicalDusk = astronomicalDusk
        self.solarNoon = solarNoon
        self.solarMidnight = solarMidnight
    }
}

public struct MoonEvents: Equatable, Codable, Sendable {
    public var moonrise: Date?
    public var moonset: Date?
    public var phase: MoonPhase

    public init(moonrise: Date? = nil, moonset: Date? = nil, phase: MoonPhase) {
        self.moonrise = moonrise
        self.moonset = moonset
        self.phase = phase
    }
}
