import Foundation

/// Current weather conditions at a location.
public struct CurrentWeather: Codable, Sendable, Equatable {
    /// The temperature.
    public let temperature: Temperature

    /// The weather condition category.
    public let condition: WeatherCondition

    /// The provider's original condition description text.
    public let conditionDescription: String

    /// Relative humidity percentage (0-100), if available.
    public let humidity: Double?

    /// Wind speed in km/h, if available.
    public let windSpeed: Double?

    /// Wind direction in degrees (0-360), if available.
    public let windDirection: Double?

    /// Whether it is currently daytime.
    public let isDaytime: Bool

    /// The resolved location for this weather data.
    public let location: ResolvedLocation

    /// When this observation was taken.
    public let observationTime: Date

    /// Information about the provider that supplied this data.
    public let provider: WeatherProviderInfo

    /// Creates a new `CurrentWeather` instance.
    public init(
        temperature: Temperature,
        condition: WeatherCondition,
        conditionDescription: String,
        humidity: Double? = nil,
        windSpeed: Double? = nil,
        windDirection: Double? = nil,
        isDaytime: Bool,
        location: ResolvedLocation,
        observationTime: Date,
        provider: WeatherProviderInfo
    ) {
        self.temperature = temperature
        self.condition = condition
        self.conditionDescription = conditionDescription
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.isDaytime = isDaytime
        self.location = location
        self.observationTime = observationTime
        self.provider = provider
    }
}

/// Resolved location information from the weather provider.
public struct ResolvedLocation: Codable, Sendable, Equatable, Hashable {
    /// The latitude.
    public let latitude: Double

    /// The longitude.
    public let longitude: Double

    /// The resolved name of the location, if available.
    public let name: String?

    /// The timezone identifier, if available.
    public let timezone: String?

    /// Creates a new `ResolvedLocation` instance.
    public init(
        latitude: Double,
        longitude: Double,
        name: String? = nil,
        timezone: String? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.name = name
        self.timezone = timezone
    }
}

/// Information about a weather data provider.
public struct WeatherProviderInfo: Codable, Sendable, Equatable, Hashable {
    /// The provider's identifier name.
    public let name: String

    /// Attribution text for the provider.
    public let attribution: String?

    /// Creates a new `WeatherProviderInfo` instance.
    public init(name: String, attribution: String? = nil) {
        self.name = name
        self.attribution = attribution
    }

    /// National Weather Service provider info.
    public static let nws = WeatherProviderInfo(
        name: "NWS",
        attribution: "National Weather Service"
    )

    /// Open-Meteo provider info.
    public static let openMeteo = WeatherProviderInfo(
        name: "Open-Meteo",
        attribution: "Open-Meteo.com"
    )
}
