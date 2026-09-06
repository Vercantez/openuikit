import Foundation
import WeatherKit

func testWeatherQueryDateRangeValidation() {
    let start = weatherKitDate()
    let end = weatherKitDate(86_400)
    let validDaily = WeatherQuery<Forecast<DayWeather>>.daily(startDate: start, endDate: end)
    let invalidDaily = WeatherQuery<Forecast<DayWeather>>.daily(startDate: end, endDate: start)
    let equalDaily = WeatherQuery<Forecast<DayWeather>>.daily(startDate: start, endDate: start)
    precondition(validDaily.isValid)
    precondition(!invalidDaily.isValid)
    precondition(!equalDaily.isValid)
    try! validDaily.validate()
    do {
        try invalidDaily.validate()
        preconditionFailure("inverted daily range must throw")
    } catch let error as WeatherError {
        precondition(error == .unknown)
    } catch {
        preconditionFailure("expected WeatherError")
    }
    let validHourly = WeatherQuery<Forecast<HourWeather>>.hourly(startDate: start, endDate: end)
    let invalidHourly = WeatherQuery<Forecast<HourWeather>>.hourly(startDate: end, endDate: start)
    precondition(validHourly.isValid)
    precondition(!invalidHourly.isValid)
    precondition(WeatherQuery<CurrentWeather>.current.isValid)
}

func testWeatherServiceFailClosedValidLocation() {
    do {
        let _: CurrentWeather = try WeatherService.shared.weather(
            latitude: 37.3349,
            longitude: -122.009,
            including: .current
        )
        preconditionFailure("Linux host must not fabricate a forecast")
    } catch let error as WeatherError {
        precondition(error == .unknown)
    } catch {
        preconditionFailure("expected WeatherError.unknown")
    }
}

func testWeatherServiceRejectsInvalidCoordinates() {
    let samples: [(Double, Double)] = [
        (91, 0),
        (-91, 0),
        (0, 181),
        (0, -181),
        (Double.nan, 0),
        (0, Double.infinity)
    ]
    for (latitude, longitude) in samples {
        do {
            let _: CurrentWeather = try WeatherService().weather(
                latitude: latitude,
                longitude: longitude,
                including: .current
            )
            preconditionFailure("invalid coordinate must throw \(latitude) \(longitude)")
        } catch let error as WeatherError {
            precondition(error == .unknown)
        } catch {
            preconditionFailure("expected WeatherError")
        }
    }
}

func testWeatherServiceRejectsInvalidQueryRange() {
    let start = weatherKitDate()
    let end = weatherKitDate(3600)
    do {
        let _: Forecast<DayWeather> = try WeatherService.shared.weather(
            latitude: 0,
            longitude: 0,
            including: .daily(startDate: end, endDate: start)
        )
        preconditionFailure("invalid query range must throw")
    } catch let error as WeatherError {
        precondition(error == .unknown)
    } catch {
        preconditionFailure("expected WeatherError")
    }
}

func testWeatherServicePermissionDeniedIsNotGuessed() {
    precondition(WeatherError.permissionDenied != WeatherError.unknown)
    do {
        let _: WeatherAvailability = try WeatherService.shared.weather(
            latitude: 51.5,
            longitude: -0.12,
            including: .availability
        )
        preconditionFailure("availability fetch must fail closed")
    } catch let error as WeatherError {
        precondition(error == .unknown)
        precondition(error != .permissionDenied)
    } catch {
        preconditionFailure("expected WeatherError")
    }
}
