import Foundation

public struct CurrentWeather: Equatable, Codable, Sendable {
    public var date: Date
    public var cloudCover: Double
    public var isDaylight: Bool
    public var symbolName: String
    public var visibility: Measurement<UnitLength>
    public var temperature: Measurement<UnitTemperature>
    public var apparentTemperature: Measurement<UnitTemperature>
    public var dewPoint: Measurement<UnitTemperature>
    public var humidity: Double
    public var pressure: Measurement<UnitPressure>
    public var pressureTrend: PressureTrend
    public var wind: Wind
    public var uvIndex: UVIndex
    public var condition: WeatherCondition
    public var cloudCoverByAltitude: CloudCoverByAltitude
    public var precipitationIntensity: Measurement<UnitSpeed>
    public var metadata: WeatherMetadata

    public init(
        date: Date,
        cloudCover: Double,
        isDaylight: Bool,
        symbolName: String,
        visibility: Measurement<UnitLength>,
        temperature: Measurement<UnitTemperature>,
        apparentTemperature: Measurement<UnitTemperature>,
        dewPoint: Measurement<UnitTemperature>,
        humidity: Double,
        pressure: Measurement<UnitPressure>,
        pressureTrend: PressureTrend,
        wind: Wind,
        uvIndex: UVIndex,
        condition: WeatherCondition,
        cloudCoverByAltitude: CloudCoverByAltitude,
        precipitationIntensity: Measurement<UnitSpeed>,
        metadata: WeatherMetadata
    ) {
        self.date = date
        self.cloudCover = cloudCover
        self.isDaylight = isDaylight
        self.symbolName = symbolName
        self.visibility = visibility
        self.temperature = temperature
        self.apparentTemperature = apparentTemperature
        self.dewPoint = dewPoint
        self.humidity = humidity
        self.pressure = pressure
        self.pressureTrend = pressureTrend
        self.wind = wind
        self.uvIndex = uvIndex
        self.condition = condition
        self.cloudCoverByAltitude = cloudCoverByAltitude
        self.precipitationIntensity = precipitationIntensity
        self.metadata = metadata
    }
}

public struct HourWeather: Equatable, Codable, Sendable {
    public var date: Date
    public var cloudCover: Double
    public var isDaylight: Bool
    public var symbolName: String
    public var visibility: Measurement<UnitLength>
    public var temperature: Measurement<UnitTemperature>
    public var apparentTemperature: Measurement<UnitTemperature>
    public var dewPoint: Measurement<UnitTemperature>
    public var humidity: Double
    public var pressure: Measurement<UnitPressure>
    public var pressureTrend: PressureTrend
    public var precipitation: Precipitation
    public var precipitationAmount: Measurement<UnitLength>
    public var precipitationChance: Double
    public var snowfallAmount: Measurement<UnitLength>
    public var wind: Wind
    public var uvIndex: UVIndex
    public var condition: WeatherCondition
    public var cloudCoverByAltitude: CloudCoverByAltitude

    public init(
        date: Date,
        cloudCover: Double,
        isDaylight: Bool,
        symbolName: String,
        visibility: Measurement<UnitLength>,
        temperature: Measurement<UnitTemperature>,
        apparentTemperature: Measurement<UnitTemperature>,
        dewPoint: Measurement<UnitTemperature>,
        humidity: Double,
        pressure: Measurement<UnitPressure>,
        pressureTrend: PressureTrend,
        precipitation: Precipitation,
        precipitationAmount: Measurement<UnitLength>,
        precipitationChance: Double,
        snowfallAmount: Measurement<UnitLength>,
        wind: Wind,
        uvIndex: UVIndex,
        condition: WeatherCondition,
        cloudCoverByAltitude: CloudCoverByAltitude
    ) {
        self.date = date
        self.cloudCover = cloudCover
        self.isDaylight = isDaylight
        self.symbolName = symbolName
        self.visibility = visibility
        self.temperature = temperature
        self.apparentTemperature = apparentTemperature
        self.dewPoint = dewPoint
        self.humidity = humidity
        self.pressure = pressure
        self.pressureTrend = pressureTrend
        self.precipitation = precipitation
        self.precipitationAmount = precipitationAmount
        self.precipitationChance = precipitationChance
        self.snowfallAmount = snowfallAmount
        self.wind = wind
        self.uvIndex = uvIndex
        self.condition = condition
        self.cloudCoverByAltitude = cloudCoverByAltitude
    }
}

public struct MinuteWeather: Equatable, Codable, Sendable {
    public var date: Date
    public var precipitation: Precipitation
    public var precipitationChance: Double
    public var precipitationIntensity: Measurement<UnitSpeed>

    public init(
        date: Date,
        precipitation: Precipitation,
        precipitationChance: Double,
        precipitationIntensity: Measurement<UnitSpeed>
    ) {
        self.date = date
        self.precipitation = precipitation
        self.precipitationChance = precipitationChance
        self.precipitationIntensity = precipitationIntensity
    }
}

public struct DayPartForecast: Equatable, Codable, Sendable {
    public var cloudCover: Double
    public var highWindSpeed: Measurement<UnitSpeed>
    public var precipitation: Precipitation
    public var lowTemperature: Measurement<UnitTemperature>
    public var highTemperature: Measurement<UnitTemperature>
    public var maximumHumidity: Double
    public var minimumHumidity: Double
    public var maximumVisibility: Measurement<UnitLength>
    public var minimumVisibility: Measurement<UnitLength>
    public var precipitationChance: Double
    public var cloudCoverByAltitude: CloudCoverByAltitude
    public var precipitationAmountByType: PrecipitationAmountByType
    public var wind: Wind
    public var condition: WeatherCondition

    public init(
        cloudCover: Double,
        highWindSpeed: Measurement<UnitSpeed>,
        precipitation: Precipitation,
        lowTemperature: Measurement<UnitTemperature>,
        highTemperature: Measurement<UnitTemperature>,
        maximumHumidity: Double,
        minimumHumidity: Double,
        maximumVisibility: Measurement<UnitLength>,
        minimumVisibility: Measurement<UnitLength>,
        precipitationChance: Double,
        cloudCoverByAltitude: CloudCoverByAltitude,
        precipitationAmountByType: PrecipitationAmountByType,
        wind: Wind,
        condition: WeatherCondition
    ) {
        self.cloudCover = cloudCover
        self.highWindSpeed = highWindSpeed
        self.precipitation = precipitation
        self.lowTemperature = lowTemperature
        self.highTemperature = highTemperature
        self.maximumHumidity = maximumHumidity
        self.minimumHumidity = minimumHumidity
        self.maximumVisibility = maximumVisibility
        self.minimumVisibility = minimumVisibility
        self.precipitationChance = precipitationChance
        self.cloudCoverByAltitude = cloudCoverByAltitude
        self.precipitationAmountByType = precipitationAmountByType
        self.wind = wind
        self.condition = condition
    }
}

public struct DayWeather: Equatable, Codable, Sendable {
    public var date: Date
    public var symbolName: String
    public var highWindSpeed: Measurement<UnitSpeed>?
    public var precipitation: Precipitation
    public var lowTemperature: Measurement<UnitTemperature>
    public var highTemperature: Measurement<UnitTemperature>
    public var rainfallAmount: Measurement<UnitLength>
    public var snowfallAmount: Measurement<UnitLength>
    public var daytimeForecast: DayPartForecast
    public var overnightForecast: DayPartForecast
    public var restOfDayForecast: DayPartForecast?
    public var maximumHumidity: Double
    public var minimumHumidity: Double
    public var maximumVisibility: Double
    public var minimumVisibility: Double
    public var lowTemperatureTime: Date?
    public var highTemperatureTime: Date?
    public var precipitationChance: Double
    public var precipitationAmountByType: PrecipitationAmountByType
    public var sun: SunEvents
    public var moon: MoonEvents
    public var wind: Wind
    public var uvIndex: UVIndex
    public var condition: WeatherCondition

    public init(
        date: Date,
        symbolName: String,
        highWindSpeed: Measurement<UnitSpeed>?,
        precipitation: Precipitation,
        lowTemperature: Measurement<UnitTemperature>,
        highTemperature: Measurement<UnitTemperature>,
        rainfallAmount: Measurement<UnitLength>,
        snowfallAmount: Measurement<UnitLength>,
        daytimeForecast: DayPartForecast,
        overnightForecast: DayPartForecast,
        restOfDayForecast: DayPartForecast?,
        maximumHumidity: Double,
        minimumHumidity: Double,
        maximumVisibility: Double,
        minimumVisibility: Double,
        lowTemperatureTime: Date?,
        highTemperatureTime: Date?,
        precipitationChance: Double,
        precipitationAmountByType: PrecipitationAmountByType,
        sun: SunEvents,
        moon: MoonEvents,
        wind: Wind,
        uvIndex: UVIndex,
        condition: WeatherCondition
    ) {
        self.date = date
        self.symbolName = symbolName
        self.highWindSpeed = highWindSpeed
        self.precipitation = precipitation
        self.lowTemperature = lowTemperature
        self.highTemperature = highTemperature
        self.rainfallAmount = rainfallAmount
        self.snowfallAmount = snowfallAmount
        self.daytimeForecast = daytimeForecast
        self.overnightForecast = overnightForecast
        self.restOfDayForecast = restOfDayForecast
        self.maximumHumidity = maximumHumidity
        self.minimumHumidity = minimumHumidity
        self.maximumVisibility = maximumVisibility
        self.minimumVisibility = minimumVisibility
        self.lowTemperatureTime = lowTemperatureTime
        self.highTemperatureTime = highTemperatureTime
        self.precipitationChance = precipitationChance
        self.precipitationAmountByType = precipitationAmountByType
        self.sun = sun
        self.moon = moon
        self.wind = wind
        self.uvIndex = uvIndex
        self.condition = condition
    }

    public var precipitationAmount: Measurement<UnitLength> {
        precipitationAmountByType.precipitation
    }
}

public struct Weather: Equatable, Codable, Sendable {
    public var currentWeather: CurrentWeather
    public var availability: WeatherAvailability
    public var dailyForecast: Forecast<DayWeather>
    public var hourlyForecast: Forecast<HourWeather>
    public var minuteForecast: Forecast<MinuteWeather>?
    public var weatherAlerts: [WeatherAlert]?

    public init(
        currentWeather: CurrentWeather,
        availability: WeatherAvailability,
        dailyForecast: Forecast<DayWeather>,
        hourlyForecast: Forecast<HourWeather>,
        minuteForecast: Forecast<MinuteWeather>?,
        weatherAlerts: [WeatherAlert]?
    ) {
        self.currentWeather = currentWeather
        self.availability = availability
        self.dailyForecast = dailyForecast
        self.hourlyForecast = hourlyForecast
        self.minuteForecast = minuteForecast
        self.weatherAlerts = weatherAlerts
    }
}
