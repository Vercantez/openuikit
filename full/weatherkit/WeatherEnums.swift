import Foundation

func weatherKitTitleCase(_ raw: String) -> String {
    var result = ""
    for (index, character) in raw.enumerated() {
        if index > 0, character.isUppercase {
            result.append(" ")
        }
        if index == 0 {
            result.append(contentsOf: character.uppercased())
        } else {
            result.append(character)
        }
    }
    return result
}

/// Observed sky / precipitation condition. Raw values match the case names.
public enum WeatherCondition: String, Codable, CaseIterable, Sendable, Hashable {
    case blizzard
    case blowingDust
    case blowingSnow
    case breezy
    case clear
    case cloudy
    case drizzle
    case flurries
    case foggy
    case freezingDrizzle
    case freezingRain
    case frigid
    case hail
    case haze
    case heavyRain
    case heavySnow
    case hot
    case hurricane
    case isolatedThunderstorms
    case mostlyClear
    case mostlyCloudy
    case partlyCloudy
    case rain
    case scatteredThunderstorms
    case sleet
    case smoky
    case snow
    case strongStorms
    case sunFlurries
    case sunShowers
    case thunderstorms
    case tropicalStorm
    case windy
    case wintryMix

    public var description: String { weatherKitTitleCase(rawValue) }

    public var accessibilityDescription: String { description }
}

public enum Precipitation: String, Codable, CaseIterable, Sendable, Hashable {
    case none
    case hail
    case mixed
    case rain
    case sleet
    case snow

    public var description: String { weatherKitTitleCase(rawValue) }

    public var accessibilityDescription: String { description }
}

public enum PressureTrend: String, Codable, CaseIterable, Sendable, Hashable {
    case rising
    case falling
    case steady

    public var description: String { weatherKitTitleCase(rawValue) }

    public var accessibilityDescription: String { description }
}

public enum WeatherSeverity: String, Codable, CaseIterable, Sendable, Hashable {
    case minor
    case moderate
    case severe
    case extreme
    case unknown

    public var description: String { weatherKitTitleCase(rawValue) }

    public var accessibilityDescription: String { description }
}

@frozen
public enum MoonPhase: String, Codable, CaseIterable, Sendable, Hashable {
    case new
    case waxingCrescent
    case firstQuarter
    case waxingGibbous
    case full
    case waningGibbous
    case lastQuarter
    case waningCrescent

    public var description: String {
        switch self {
        case .new: return "New"
        case .waxingCrescent: return "Waxing Crescent"
        case .firstQuarter: return "First Quarter"
        case .waxingGibbous: return "Waxing Gibbous"
        case .full: return "Full"
        case .waningGibbous: return "Waning Gibbous"
        case .lastQuarter: return "Last Quarter"
        case .waningCrescent: return "Waning Crescent"
        }
    }

    public var accessibilityDescription: String { description }

    public var symbolName: String {
        switch self {
        case .new: return "moonphase.new.moon"
        case .waxingCrescent: return "moonphase.waxing.crescent"
        case .firstQuarter: return "moonphase.first.quarter"
        case .waxingGibbous: return "moonphase.waxing.gibbous"
        case .full: return "moonphase.full.moon"
        case .waningGibbous: return "moonphase.waning.gibbous"
        case .lastQuarter: return "moonphase.last.quarter"
        case .waningCrescent: return "moonphase.waning.crescent"
        }
    }
}

public enum Deviation: Codable, Equatable, Hashable, Sendable {
    case muchHigher
    case higher
    case normal
    case lower
    case muchLower
}
