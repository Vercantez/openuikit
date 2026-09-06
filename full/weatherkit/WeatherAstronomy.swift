import Foundation

/// NOAA solar-calculator equations (GML solareqns) and a Meeus-style lunar age.
/// These are host-local astronomical formulas, not Apple weather-service results.
enum WeatherKitAstronomy {
    static let synodicMonthDays = 29.530588853
    /// Meeus-adjacent new-moon epoch: 2000-01-06 18:14 UTC.
    static let newMoonEpoch = Date(timeIntervalSince1970: 947_182_440)
    static let officialZenithDegrees = 90.833
    static let civilZenithDegrees = 96.0
    static let nauticalZenithDegrees = 102.0
    static let astronomicalZenithDegrees = 108.0

    static func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    static func dayOfYearAndHour(_ date: Date) -> (Double, Double) {
        let calendar = utcCalendar()
        let day = Double(calendar.ordinality(of: .day, in: .year, for: date) ?? 1)
        let comps = calendar.dateComponents([.hour, .minute, .second], from: date)
        let hour = Double(comps.hour ?? 0)
            + Double(comps.minute ?? 0) / 60
            + Double(comps.second ?? 0) / 3600
        return (day, hour)
    }

    static func fractionalYear(dayOfYear: Double, hour: Double) -> Double {
        (2 * Double.pi / 365.0) * (dayOfYear - 1 + (hour - 12) / 24)
    }

    static func equationOfTimeMinutes(gamma: Double) -> Double {
        229.18 * (
            0.000075
                + 0.001868 * cos(gamma)
                - 0.032077 * sin(gamma)
                - 0.014615 * cos(2 * gamma)
                - 0.040849 * sin(2 * gamma)
        )
    }

    static func solarDeclinationRadians(gamma: Double) -> Double {
        0.006918
            - 0.399912 * cos(gamma)
            + 0.070257 * sin(gamma)
            - 0.006758 * cos(2 * gamma)
            + 0.000907 * sin(2 * gamma)
            - 0.002697 * cos(3 * gamma)
            + 0.00148 * sin(3 * gamma)
    }

    static func hourAngleDegrees(latitude: Double, declination: Double, zenithDegrees: Double) -> Double? {
        let lat = latitude * Double.pi / 180
        let zenith = zenithDegrees * Double.pi / 180
        let cosHA = (
            cos(zenith) / (cos(lat) * cos(declination))
                - tan(lat) * tan(declination)
        )
        guard cosHA >= -1, cosHA <= 1 else { return nil }
        return acos(cosHA) * 180 / Double.pi
    }

    static func utcDate(dayStart: Date, minutesFromMidnight: Double) -> Date {
        let calendar = utcCalendar()
        let start = calendar.startOfDay(for: dayStart)
        return start.addingTimeInterval(minutesFromMidnight * 60)
    }

    static func eventMinutes(
        longitude: Double,
        equationOfTime: Double,
        hourAngle: Double?,
        rising: Bool
    ) -> Double? {
        guard let hourAngle else { return nil }
        let signed = rising ? hourAngle : -hourAngle
        return 720 - 4 * (longitude + signed) - equationOfTime
    }
}

public extension MoonPhase {
    /// Eight-phase lunar age using a 29.530588853-day synodic month measured
    /// from the 2000-01-06 18:14 UTC new-moon epoch.
    init(date: Date) {
        let age = date.timeIntervalSince(WeatherKitAstronomy.newMoonEpoch) / 86_400
        let cycle = age.truncatingRemainder(dividingBy: WeatherKitAstronomy.synodicMonthDays)
        let normalized = cycle < 0 ? cycle + WeatherKitAstronomy.synodicMonthDays : cycle
        let step = WeatherKitAstronomy.synodicMonthDays / 8
        let index = Int((normalized + step / 2) / step) % 8
        self = MoonPhase.allCases[index]
    }
}

public extension SunEvents {
    /// NOAA solar-calculator events for a civil date at `latitude`/`longitude`.
    /// Polar day/night leaves the corresponding rise/set fields `nil`.
    init(date: Date, latitude: Double, longitude: Double) {
        let (dayOfYear, _) = WeatherKitAstronomy.dayOfYearAndHour(date)
        let gamma = WeatherKitAstronomy.fractionalYear(dayOfYear: dayOfYear, hour: 12)
        let eqtime = WeatherKitAstronomy.equationOfTimeMinutes(gamma: gamma)
        let decl = WeatherKitAstronomy.solarDeclinationRadians(gamma: gamma)

        let officialHA = WeatherKitAstronomy.hourAngleDegrees(
            latitude: latitude, declination: decl,
            zenithDegrees: WeatherKitAstronomy.officialZenithDegrees
        )
        let civilHA = WeatherKitAstronomy.hourAngleDegrees(
            latitude: latitude, declination: decl,
            zenithDegrees: WeatherKitAstronomy.civilZenithDegrees
        )
        let nauticalHA = WeatherKitAstronomy.hourAngleDegrees(
            latitude: latitude, declination: decl,
            zenithDegrees: WeatherKitAstronomy.nauticalZenithDegrees
        )
        let astronomicalHA = WeatherKitAstronomy.hourAngleDegrees(
            latitude: latitude, declination: decl,
            zenithDegrees: WeatherKitAstronomy.astronomicalZenithDegrees
        )

        let solarNoonMinutes = 720 - 4 * longitude - eqtime
        let solarNoonDate = WeatherKitAstronomy.utcDate(dayStart: date, minutesFromMidnight: solarNoonMinutes)
        let solarMidnightDate = solarNoonDate.addingTimeInterval(-12 * 3600)

        func stamp(_ minutes: Double?) -> Date? {
            guard let minutes else { return nil }
            return WeatherKitAstronomy.utcDate(dayStart: date, minutesFromMidnight: minutes)
        }

        self.init(
            sunrise: stamp(WeatherKitAstronomy.eventMinutes(
                longitude: longitude, equationOfTime: eqtime, hourAngle: officialHA, rising: true
            )),
            sunset: stamp(WeatherKitAstronomy.eventMinutes(
                longitude: longitude, equationOfTime: eqtime, hourAngle: officialHA, rising: false
            )),
            civilDawn: stamp(WeatherKitAstronomy.eventMinutes(
                longitude: longitude, equationOfTime: eqtime, hourAngle: civilHA, rising: true
            )),
            civilDusk: stamp(WeatherKitAstronomy.eventMinutes(
                longitude: longitude, equationOfTime: eqtime, hourAngle: civilHA, rising: false
            )),
            nauticalDawn: stamp(WeatherKitAstronomy.eventMinutes(
                longitude: longitude, equationOfTime: eqtime, hourAngle: nauticalHA, rising: true
            )),
            nauticalDusk: stamp(WeatherKitAstronomy.eventMinutes(
                longitude: longitude, equationOfTime: eqtime, hourAngle: nauticalHA, rising: false
            )),
            astronomicalDawn: stamp(WeatherKitAstronomy.eventMinutes(
                longitude: longitude, equationOfTime: eqtime, hourAngle: astronomicalHA, rising: true
            )),
            astronomicalDusk: stamp(WeatherKitAstronomy.eventMinutes(
                longitude: longitude, equationOfTime: eqtime, hourAngle: astronomicalHA, rising: false
            )),
            solarNoon: solarNoonDate,
            solarMidnight: solarMidnightDate
        )
    }
}

public extension MoonEvents {
    /// Lunar phase from the synodic-month formula. Rise/set stay `nil` until a
    /// lunar-ephemeris implementation exists; fabricating moonrise would be dishonest.
    init(date: Date) {
        self.init(moonrise: nil, moonset: nil, phase: MoonPhase(date: date))
    }
}
