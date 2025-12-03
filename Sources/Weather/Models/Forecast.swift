import Foundation

/**
 A multi-day weather forecast.

 Contains daily forecast data for a specified number of days.
 */
public struct Forecast: Sendable, Equatable {
    /// The location this forecast is for.
    public let location: ResolvedLocation

    /// The daily forecasts.
    public let daily: [DailyForecast]

    /// The provider that generated this forecast.
    public let provider: WeatherProviderInfo

    /// When this forecast was generated.
    public let generatedAt: Date

    /**
     Creates a new forecast.

     - Parameters:
       - location: The location this forecast is for.
       - daily: The daily forecasts.
       - provider: The provider that generated this forecast.
       - generatedAt: When this forecast was generated.
     */
    public init(
        location: ResolvedLocation,
        daily: [DailyForecast],
        provider: WeatherProviderInfo,
        generatedAt: Date = Date()
    ) {
        self.location = location
        self.daily = daily
        self.provider = provider
        self.generatedAt = generatedAt
    }

    /// The forecast for today, if available.
    public var today: DailyForecast? {
        daily.first
    }

    /// The forecast for tomorrow, if available.
    public var tomorrow: DailyForecast? {
        daily.count > 1 ? daily[1] : nil
    }
}

/**
 A daily weather forecast.

 Contains high/low temperatures and conditions for a single day.
 */
public struct DailyForecast: Sendable, Equatable {
    /// The date of this forecast.
    public let date: Date

    /// The high temperature for the day.
    public let highTemperature: Temperature

    /// The low temperature for the day.
    public let lowTemperature: Temperature

    /// The primary weather condition for the day.
    public let condition: WeatherCondition

    /// A text description of the conditions.
    public let conditionDescription: String

    /// Probability of precipitation (0-100).
    public let precipitationProbability: Double?

    /// Expected precipitation amount in millimeters.
    public let precipitationAmount: Double?

    /// Sunrise time.
    public let sunrise: Date?

    /// Sunset time.
    public let sunset: Date?

    /// UV index (0-11+).
    public let uvIndex: Double?

    /**
     Creates a new daily forecast.

     - Parameters:
       - date: The date of this forecast.
       - highTemperature: The high temperature.
       - lowTemperature: The low temperature.
       - condition: The primary weather condition.
       - conditionDescription: A text description.
       - precipitationProbability: Chance of precipitation (0-100).
       - precipitationAmount: Expected precipitation in mm.
       - sunrise: Sunrise time.
       - sunset: Sunset time.
       - uvIndex: UV index value.
     */
    public init(
        date: Date,
        highTemperature: Temperature,
        lowTemperature: Temperature,
        condition: WeatherCondition,
        conditionDescription: String,
        precipitationProbability: Double? = nil,
        precipitationAmount: Double? = nil,
        sunrise: Date? = nil,
        sunset: Date? = nil,
        uvIndex: Double? = nil
    ) {
        self.date = date
        self.highTemperature = highTemperature
        self.lowTemperature = lowTemperature
        self.condition = condition
        self.conditionDescription = conditionDescription
        self.precipitationProbability = precipitationProbability
        self.precipitationAmount = precipitationAmount
        self.sunrise = sunrise
        self.sunset = sunset
        self.uvIndex = uvIndex
    }
}

/**
 An hourly weather forecast.

 Contains detailed weather data for a specific hour.
 */
public struct HourlyForecast: Sendable, Equatable {
    /// The time of this forecast.
    public let time: Date

    /// The temperature.
    public let temperature: Temperature

    /// The apparent (feels like) temperature.
    public let apparentTemperature: Temperature?

    /// The weather condition.
    public let condition: WeatherCondition

    /// A text description of the conditions.
    public let conditionDescription: String

    /// Probability of precipitation (0-100).
    public let precipitationProbability: Double?

    /// Relative humidity (0-100).
    public let humidity: Double?

    /// Wind speed in km/h.
    public let windSpeed: Double?

    /// Wind direction in degrees.
    public let windDirection: Double?

    /// Whether it's daytime.
    public let isDaytime: Bool

    /**
     Creates a new hourly forecast.

     - Parameters:
       - time: The time of this forecast.
       - temperature: The temperature.
       - apparentTemperature: The feels-like temperature.
       - condition: The weather condition.
       - conditionDescription: A text description.
       - precipitationProbability: Chance of precipitation (0-100).
       - humidity: Relative humidity (0-100).
       - windSpeed: Wind speed in km/h.
       - windDirection: Wind direction in degrees.
       - isDaytime: Whether it's daytime.
     */
    public init(
        time: Date,
        temperature: Temperature,
        apparentTemperature: Temperature? = nil,
        condition: WeatherCondition,
        conditionDescription: String,
        precipitationProbability: Double? = nil,
        humidity: Double? = nil,
        windSpeed: Double? = nil,
        windDirection: Double? = nil,
        isDaytime: Bool = true
    ) {
        self.time = time
        self.temperature = temperature
        self.apparentTemperature = apparentTemperature
        self.condition = condition
        self.conditionDescription = conditionDescription
        self.precipitationProbability = precipitationProbability
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.isDaytime = isDaytime
    }
}
