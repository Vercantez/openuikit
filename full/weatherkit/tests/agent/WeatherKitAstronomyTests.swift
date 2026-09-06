import Foundation
import WeatherKit

func testSunEventsNOAAGreenwichEquinox() {
    let calendar = WeatherKitAstronomyTestDates.utcCalendar()
    let equinox = calendar.date(from: DateComponents(year: 2024, month: 3, day: 20, hour: 12))!
    let events = SunEvents(date: equinox, latitude: 51.4778, longitude: 0)
    let sunrise = events.sunrise
    let sunset = events.sunset
    let noon = events.solarNoon
    precondition(sunrise != nil)
    precondition(sunset != nil)
    precondition(noon != nil)
    let sunriseHour = calendar.component(.hour, from: sunrise!)
    let sunsetHour = calendar.component(.hour, from: sunset!)
    let noonHour = calendar.component(.hour, from: noon!)
    precondition((5...7).contains(sunriseHour), "Greenwich equinox sunrise UTC hour \(sunriseHour)")
    precondition((17...19).contains(sunsetHour), "Greenwich equinox sunset UTC hour \(sunsetHour)")
    precondition((11...13).contains(noonHour), "Greenwich equinox solar noon UTC hour \(noonHour)")
    precondition(events.civilDawn! < sunrise!)
    precondition(events.civilDusk! > sunset!)
    precondition(events.nauticalDawn! < events.civilDawn!)
    precondition(events.nauticalDusk! > events.civilDusk!)
    precondition(events.astronomicalDawn! < events.nauticalDawn!)
    precondition(events.astronomicalDusk! > events.nauticalDusk!)
    precondition(events.solarMidnight != nil)
}

func testSunEventsNOAAEquatorEquinoxNearSixAndEighteen() {
    let calendar = WeatherKitAstronomyTestDates.utcCalendar()
    let equinox = calendar.date(from: DateComponents(year: 2024, month: 3, day: 20, hour: 12))!
    let events = SunEvents(date: equinox, latitude: 0, longitude: 0)
    let sunrise = events.sunrise!
    let sunset = events.sunset!
    let sunriseMinutes = calendar.component(.hour, from: sunrise) * 60 + calendar.component(.minute, from: sunrise)
    let sunsetMinutes = calendar.component(.hour, from: sunset) * 60 + calendar.component(.minute, from: sunset)
    precondition(abs(sunriseMinutes - 6 * 60) < 25, "equator sunrise minutes \(sunriseMinutes)")
    precondition(abs(sunsetMinutes - 18 * 60) < 25, "equator sunset minutes \(sunsetMinutes)")
}

func testSunEventsPolarNightLeavesSunriseNil() {
    let calendar = WeatherKitAstronomyTestDates.utcCalendar()
    let december = calendar.date(from: DateComponents(year: 2024, month: 12, day: 21, hour: 12))!
    let events = SunEvents(date: december, latitude: 90, longitude: 0)
    precondition(events.sunrise == nil)
    precondition(events.sunset == nil)
    precondition(events.solarNoon != nil)
}

func testMoonPhaseMeeusKnownDates() {
    let calendar = WeatherKitAstronomyTestDates.utcCalendar()
    let newMoon = calendar.date(from: DateComponents(year: 2024, month: 4, day: 8, hour: 18, minute: 21))!
    let fullMoon = calendar.date(from: DateComponents(year: 2024, month: 3, day: 25, hour: 7, minute: 0))!
    let firstQuarter = calendar.date(from: DateComponents(year: 2024, month: 4, day: 15, hour: 19, minute: 13))!
    precondition(MoonPhase(date: newMoon) == .new)
    precondition(MoonPhase(date: fullMoon) == .full)
    precondition(MoonPhase(date: firstQuarter) == .firstQuarter)
    let events = MoonEvents(date: fullMoon)
    precondition(events.phase == .full)
    precondition(events.moonrise == nil)
    precondition(events.moonset == nil)
}

enum WeatherKitAstronomyTestDates {
    static func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
