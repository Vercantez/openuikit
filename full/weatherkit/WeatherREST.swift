import Foundation

/// Apple WeatherKit REST API document shapes (weatherkitrestapi). Decoding is
/// local JSON mapping only: it never contacts a weather endpoint.
public enum WeatherKitREST {
    public struct Metadata: Decodable, Equatable, Sendable {
        public var latitude: Double
        public var longitude: Double
        public var readTime: Date
        public var expireTime: Date
        public var units: String?

        enum CodingKeys: String, CodingKey {
            case latitude, longitude, readTime, expireTime, units
        }
    }

    public struct CurrentWeather: Decodable, Equatable, Sendable {
        public var asOf: Date
        public var cloudCover: Double
        public var cloudCoverLowAltPct: Double?
        public var cloudCoverMidAltPct: Double?
        public var cloudCoverHighAltPct: Double?
        public var conditionCode: String
        public var daylight: Bool
        public var humidity: Double
        public var precipitationIntensity: Double
        public var pressure: Double
        public var pressureTrend: String
        public var temperature: Double
        public var temperatureApparent: Double
        public var temperatureDewPoint: Double
        public var uvIndex: Int
        public var visibility: Double
        public var windDirection: Double
        public var windGust: Double?
        public var windSpeed: Double
        public var metadata: Metadata
    }

    public struct HourWeather: Decodable, Equatable, Sendable {
        public var forecastStart: Date
        public var cloudCover: Double
        public var conditionCode: String
        public var daylight: Bool
        public var humidity: Double
        public var precipitationAmount: Double
        public var precipitationChance: Double
        public var precipitationType: String
        public var pressure: Double
        public var pressureTrend: String
        public var snowfallAmount: Double?
        public var temperature: Double
        public var temperatureApparent: Double
        public var temperatureDewPoint: Double
        public var uvIndex: Int
        public var visibility: Double
        public var windDirection: Double
        public var windGust: Double?
        public var windSpeed: Double
    }

    public struct DayWeather: Decodable, Equatable, Sendable {
        public var forecastStart: Date
        public var conditionCode: String
        public var maxUvIndex: Int
        public var moonPhase: String
        public var moonrise: Date?
        public var moonset: Date?
        public var precipitationAmount: Double
        public var precipitationChance: Double
        public var precipitationType: String
        public var snowfallAmount: Double?
        public var sunrise: Date?
        public var sunset: Date?
        public var temperatureMax: Double
        public var temperatureMin: Double
        public var windGustSpeedMax: Double?
        public var windSpeedAvg: Double
        public var windDirection: Double?
    }

    public struct ForecastDaily: Decodable, Equatable, Sendable {
        public var name: String?
        public var metadata: Metadata
        public var days: [DayWeather]
    }

    public struct ForecastHourly: Decodable, Equatable, Sendable {
        public var name: String?
        public var metadata: Metadata
        public var hours: [HourWeather]
    }

    public struct Weather: Decodable, Equatable, Sendable {
        public var currentWeather: CurrentWeather?
        public var forecastDaily: ForecastDaily?
        public var forecastHourly: ForecastHourly?
    }

    public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }

    public static func condition(from code: String) throws -> WeatherCondition {
        if let value = WeatherCondition(rawValue: code) {
            return value
        }
        let camel = code.prefix(1).lowercased() + code.dropFirst()
        if let value = WeatherCondition(rawValue: String(camel)) {
            return value
        }
        throw DecodingError.dataCorrupted(
            .init(codingPath: [], debugDescription: "unknown WeatherKit REST conditionCode \(code)")
        )
    }

    public static func precipitation(from type: String) throws -> Precipitation {
        switch type {
        case "clear", "none":
            return .none
        default:
            if let value = Precipitation(rawValue: type) {
                return value
            }
            let camel = type.prefix(1).lowercased() + type.dropFirst()
            if let value = Precipitation(rawValue: String(camel)) {
                return value
            }
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "unknown WeatherKit REST precipitationType \(type)")
            )
        }
    }

    public static func pressureTrend(from raw: String) throws -> PressureTrend {
        if let value = PressureTrend(rawValue: raw) {
            return value
        }
        throw DecodingError.dataCorrupted(
            .init(codingPath: [], debugDescription: "unknown WeatherKit REST pressureTrend \(raw)")
        )
    }

    public static func moonPhase(from raw: String) throws -> MoonPhase {
        if let value = MoonPhase(rawValue: raw) {
            return value
        }
        let camel = raw.prefix(1).lowercased() + raw.dropFirst()
        if let value = MoonPhase(rawValue: String(camel)) {
            return value
        }
        throw DecodingError.dataCorrupted(
            .init(codingPath: [], debugDescription: "unknown WeatherKit REST moonPhase \(raw)")
        )
    }

    public static func metadata(_ rest: Metadata) -> WeatherMetadata {
        WeatherMetadata(
            date: rest.readTime,
            expirationDate: rest.expireTime,
            latitude: rest.latitude,
            longitude: rest.longitude,
            altitude: 0
        )
    }

    public static func currentWeather(_ rest: CurrentWeather) throws -> WeatherKit.CurrentWeather {
        let cover = CloudCoverByAltitude(
            low: rest.cloudCoverLowAltPct ?? 0,
            medium: rest.cloudCoverMidAltPct ?? 0,
            high: rest.cloudCoverHighAltPct ?? 0
        )
        let gust: Measurement<UnitSpeed>? = rest.windGust.map {
            Measurement(value: $0, unit: .kilometersPerHour)
        }
        return WeatherKit.CurrentWeather(
            date: rest.asOf,
            cloudCover: rest.cloudCover,
            isDaylight: rest.daylight,
            symbolName: rest.conditionCode,
            visibility: Measurement(value: rest.visibility, unit: .meters),
            temperature: Measurement(value: rest.temperature, unit: .celsius),
            apparentTemperature: Measurement(value: rest.temperatureApparent, unit: .celsius),
            dewPoint: Measurement(value: rest.temperatureDewPoint, unit: .celsius),
            humidity: rest.humidity,
            pressure: Measurement(value: rest.pressure, unit: .hectopascals),
            pressureTrend: try pressureTrend(from: rest.pressureTrend),
            wind: Wind(
                direction: Measurement(value: rest.windDirection, unit: .degrees),
                speed: Measurement(value: rest.windSpeed, unit: .kilometersPerHour),
                gust: gust
            ),
            uvIndex: UVIndex(value: rest.uvIndex),
            condition: try condition(from: rest.conditionCode),
            cloudCoverByAltitude: cover,
            precipitationIntensity: Measurement(
                value: rest.precipitationIntensity / 3_600_000.0,
                unit: .metersPerSecond
            ),
            metadata: metadata(rest.metadata)
        )
    }
}
