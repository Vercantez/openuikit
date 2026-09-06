import Foundation
import WeatherKit

func testWeatherKitRESTCurrentWeatherDocumentedJSON() {
    let json = """
    {
      "asOf": "2024-03-20T12:00:00Z",
      "cloudCover": 0.2,
      "cloudCoverLowAltPct": 0.1,
      "cloudCoverMidAltPct": 0.15,
      "cloudCoverHighAltPct": 0.05,
      "conditionCode": "MostlyClear",
      "daylight": true,
      "humidity": 0.45,
      "precipitationIntensity": 0,
      "pressure": 1013.25,
      "pressureTrend": "steady",
      "temperature": 18.5,
      "temperatureApparent": 17.8,
      "temperatureDewPoint": 6.2,
      "uvIndex": 5,
      "visibility": 16000,
      "windDirection": 270,
      "windGust": 24,
      "windSpeed": 12,
      "metadata": {
        "latitude": 37.3349,
        "longitude": -122.009,
        "readTime": "2024-03-20T12:00:00Z",
        "expireTime": "2024-03-20T13:00:00Z",
        "units": "m"
      }
    }
    """
    let rest = try! WeatherKitREST.decode(WeatherKitREST.CurrentWeather.self, from: Data(json.utf8))
    precondition(rest.conditionCode == "MostlyClear")
    precondition(rest.daylight)
    precondition(rest.uvIndex == 5)
    precondition(rest.pressureTrend == "steady")
    precondition(rest.windDirection == 270)
    precondition(rest.metadata.units == "m")
    let current = try! WeatherKitREST.currentWeather(rest)
    precondition(current.condition == .mostlyClear)
    precondition(current.isDaylight)
    precondition(current.pressureTrend == .steady)
    precondition(current.uvIndex.value == 5)
    precondition(current.uvIndex.category == .moderate)
    precondition(current.temperature.unit == .celsius)
    precondition(current.temperature.value == 18.5)
    precondition(current.wind.compassDirection == .west)
    precondition(current.visibility.converted(to: .meters).value == 16000)
    precondition(abs(current.wind.speed.converted(to: .kilometersPerHour).value - 12) < 0.001)
}

func testWeatherKitRESTWeatherBundleDocumentedJSON() {
    let json = """
    {
      "currentWeather": {
        "asOf": "2024-03-20T12:00:00Z",
        "cloudCover": 0.4,
        "conditionCode": "Rain",
        "daylight": false,
        "humidity": 0.8,
        "precipitationIntensity": 2.5,
        "pressure": 1001,
        "pressureTrend": "falling",
        "temperature": 11,
        "temperatureApparent": 9,
        "temperatureDewPoint": 8,
        "uvIndex": 0,
        "visibility": 4000,
        "windDirection": 90,
        "windSpeed": 20,
        "metadata": {
          "latitude": 51.5,
          "longitude": -0.12,
          "readTime": "2024-03-20T12:00:00Z",
          "expireTime": "2024-03-20T13:00:00Z"
        }
      },
      "forecastHourly": {
        "name": "HourlyForecast",
        "metadata": {
          "latitude": 51.5,
          "longitude": -0.12,
          "readTime": "2024-03-20T12:00:00Z",
          "expireTime": "2024-03-20T13:00:00Z"
        },
        "hours": [
          {
            "forecastStart": "2024-03-20T12:00:00Z",
            "cloudCover": 0.9,
            "conditionCode": "rain",
            "daylight": true,
            "humidity": 0.85,
            "precipitationAmount": 1.2,
            "precipitationChance": 0.7,
            "precipitationType": "rain",
            "pressure": 1001,
            "pressureTrend": "falling",
            "snowfallAmount": 0,
            "temperature": 11,
            "temperatureApparent": 9,
            "temperatureDewPoint": 8,
            "uvIndex": 1,
            "visibility": 4000,
            "windDirection": 90,
            "windSpeed": 20
          }
        ]
      },
      "forecastDaily": {
        "metadata": {
          "latitude": 51.5,
          "longitude": -0.12,
          "readTime": "2024-03-20T12:00:00Z",
          "expireTime": "2024-03-20T13:00:00Z"
        },
        "days": [
          {
            "forecastStart": "2024-03-20T00:00:00Z",
            "conditionCode": "rain",
            "maxUvIndex": 3,
            "moonPhase": "waxingCrescent",
            "precipitationAmount": 8,
            "precipitationChance": 0.6,
            "precipitationType": "rain",
            "snowfallAmount": 0,
            "sunrise": "2024-03-20T06:07:00Z",
            "sunset": "2024-03-20T18:15:00Z",
            "temperatureMax": 14,
            "temperatureMin": 7,
            "windSpeedAvg": 18,
            "windDirection": 90
          }
        ]
      }
    }
    """
    let bundle = try! WeatherKitREST.decode(WeatherKitREST.Weather.self, from: Data(json.utf8))
    precondition(bundle.currentWeather?.conditionCode == "Rain")
    precondition(bundle.forecastHourly?.hours.count == 1)
    precondition(bundle.forecastDaily?.days.first?.moonPhase == "waxingCrescent")
    let current = try! WeatherKitREST.currentWeather(bundle.currentWeather!)
    precondition(current.condition == .rain)
    precondition(current.pressureTrend == .falling)
    let hourPrecip = try! WeatherKitREST.precipitation(from: bundle.forecastHourly!.hours[0].precipitationType)
    precondition(hourPrecip == .rain)
    let phase = try! WeatherKitREST.moonPhase(from: bundle.forecastDaily!.days[0].moonPhase)
    precondition(phase == .waxingCrescent)
}

func testWeatherKitRESTUnknownConditionFailsClosed() {
    do {
        _ = try WeatherKitREST.condition(from: "NotARealSky")
        preconditionFailure("unknown condition must not be invented")
    } catch {
        precondition(error is DecodingError)
    }
}
