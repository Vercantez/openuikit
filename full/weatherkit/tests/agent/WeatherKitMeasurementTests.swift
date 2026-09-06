import Foundation
import WeatherKit

func testTemperatureMeasurementConversions() {
    let celsius = Measurement(value: 20, unit: UnitTemperature.celsius)
    let fahrenheit = celsius.converted(to: .fahrenheit)
    let kelvin = celsius.converted(to: .kelvin)
    precondition(abs(fahrenheit.value - 68) < 0.001)
    precondition(abs(kelvin.value - 293.15) < 0.001)
    let current = CurrentWeather(
        date: weatherKitDate(),
        cloudCover: 0,
        isDaylight: true,
        symbolName: "sun.max",
        visibility: Measurement(value: 16, unit: .kilometers),
        temperature: celsius,
        apparentTemperature: celsius,
        dewPoint: Measurement(value: 8, unit: .celsius),
        humidity: 0.4,
        pressure: Measurement(value: 1013.25, unit: .hectopascals),
        pressureTrend: .steady,
        wind: weatherKitWind(),
        uvIndex: UVIndex(value: 4),
        condition: .clear,
        cloudCoverByAltitude: weatherKitCloudCover(),
        precipitationIntensity: weatherKitZeroSpeed(),
        metadata: weatherKitMetadata()
    )
    precondition(abs(current.temperature.converted(to: .fahrenheit).value - 68) < 0.001)
}

func testWindSpeedAndAngleConversions() {
    let wind = Wind(
        direction: Measurement(value: Double.pi / 2, unit: .radians),
        speed: Measurement(value: 10, unit: .metersPerSecond),
        gust: Measurement(value: 36, unit: .kilometersPerHour)
    )
    precondition(abs(wind.direction.converted(to: .degrees).value - 90) < 0.001)
    precondition(wind.compassDirection == .east)
    precondition(abs(wind.speed.converted(to: .kilometersPerHour).value - 36) < 0.05)
    precondition(abs(wind.gust!.converted(to: .metersPerSecond).value - 10) < 0.05)
}

func testPressureAndLengthConversions() {
    let pressure = Measurement(value: 1013.25, unit: UnitPressure.hectopascals)
    precondition(abs(pressure.converted(to: .millibars).value - 1013.25) < 0.001)
    let rain = Measurement(value: 5, unit: UnitLength.millimeters)
    precondition(abs(rain.converted(to: .inches).value - 5 / 25.4) < 0.001)
    let visibility = Measurement(value: 16, unit: UnitLength.kilometers)
    precondition(abs(visibility.converted(to: .meters).value - 16_000) < 0.001)
}
