import Foundation
import Retry

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
 Open-Meteo API weather provider.

 Provides global weather data. Free for non-commercial use,
 requires subscription for commercial use.

 API Documentation: https://open-meteo.com/en/docs
 */
public actor OpenMeteoProvider: WeatherProvider {
    /// Provider information.
    public let info = WeatherProviderInfo.openMeteo

    /// The URL session for requests.
    private let session: URLSession

    /// JSON decoder for responses.
    private let decoder: JSONDecoder

    /// Base URL for the forecast API.
    private static let forecastBaseURL = URL(string: "https://api.open-meteo.com/v1/forecast")!

    /// Creates a new Open-Meteo provider.
    /// - Parameter session: The URL session to use. Defaults to `.shared`.
    public init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    /// Open-Meteo supports all locations globally.
    public func supports(location: Location) async -> Bool {
        true
    }

    /// Fetches current weather from Open-Meteo.
    public func currentWeather(for location: Location) async throws -> CurrentWeather {
        let (latitude, longitude, locationName) = try await resolveLocation(location)

        guard var components = URLComponents(url: Self.forecastBaseURL, resolvingAgainstBaseURL: false) else {
            throw WeatherError.invalidURL(Self.forecastBaseURL.absoluteString)
        }

        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,wind_direction_10m,is_day"),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        guard let url = components.url else {
            throw WeatherError.invalidURL(components.description)
        }

        let request = URLRequest(url: url)
        let response: OpenMeteoResponse = try await perform(request)

        return CurrentWeather(
            temperature: Temperature(celsius: response.current.temperature2m),
            condition: WeatherCondition.fromWMOCode(response.current.weatherCode),
            conditionDescription: WeatherCondition.fromWMOCode(response.current.weatherCode).description,
            humidity: response.current.relativeHumidity2m,
            windSpeed: response.current.windSpeed10m,
            windDirection: response.current.windDirection10m,
            isDaytime: response.current.isDay == 1,
            location: ResolvedLocation(
                latitude: response.latitude,
                longitude: response.longitude,
                name: locationName,
                timezone: response.timezone
            ),
            observationTime: parseISO8601Date(response.current.time) ?? Date(),
            provider: info
        )
    }

    /// Fetches a multi-day forecast from Open-Meteo.
    public func forecast(for location: Location, days: Int) async throws -> Forecast {
        let (latitude, longitude, locationName) = try await resolveLocation(location)
        let clampedDays = max(1, min(16, days))

        guard var components = URLComponents(url: Self.forecastBaseURL, resolvingAgainstBaseURL: false) else {
            throw WeatherError.invalidURL(Self.forecastBaseURL.absoluteString)
        }

        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,sunrise,sunset,uv_index_max"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: String(clampedDays))
        ]

        guard let url = components.url else {
            throw WeatherError.invalidURL(components.description)
        }

        let request = URLRequest(url: url)
        let response: OpenMeteoForecastResponse = try await perform(request)

        let dailyForecasts = (0..<response.daily.time.count).compactMap { index -> DailyForecast? in
            guard index < response.daily.weatherCode.count,
                  index < response.daily.temperature2mMax.count,
                  index < response.daily.temperature2mMin.count else {
                return nil
            }

            let date = parseDateOnly(response.daily.time[index]) ?? Date()
            let condition = WeatherCondition.fromWMOCode(response.daily.weatherCode[index])

            return DailyForecast(
                date: date,
                highTemperature: Temperature(celsius: response.daily.temperature2mMax[index]),
                lowTemperature: Temperature(celsius: response.daily.temperature2mMin[index]),
                condition: condition,
                conditionDescription: condition.description,
                precipitationProbability: index < response.daily.precipitationProbabilityMax.count ? response.daily.precipitationProbabilityMax[index] : nil,
                precipitationAmount: index < response.daily.precipitationSum.count ? response.daily.precipitationSum[index] : nil,
                sunrise: index < response.daily.sunrise.count ? parseISO8601Date(response.daily.sunrise[index]) : nil,
                sunset: index < response.daily.sunset.count ? parseISO8601Date(response.daily.sunset[index]) : nil,
                uvIndex: index < response.daily.uvIndexMax.count ? response.daily.uvIndexMax[index] : nil
            )
        }

        return Forecast(
            location: ResolvedLocation(
                latitude: response.latitude,
                longitude: response.longitude,
                name: locationName,
                timezone: response.timezone
            ),
            daily: dailyForecasts,
            provider: info
        )
    }

    /// Fetches hourly forecast from Open-Meteo.
    public func hourlyForecast(for location: Location, hours: Int) async throws -> [HourlyForecast] {
        let (latitude, longitude, _) = try await resolveLocation(location)
        let clampedHours = max(1, min(168, hours))
        let forecastDays = (clampedHours + 23) / 24

        guard var components = URLComponents(url: Self.forecastBaseURL, resolvingAgainstBaseURL: false) else {
            throw WeatherError.invalidURL(Self.forecastBaseURL.absoluteString)
        }

        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "hourly", value: "temperature_2m,apparent_temperature,weather_code,precipitation_probability,relative_humidity_2m,wind_speed_10m,wind_direction_10m,is_day"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: String(forecastDays))
        ]

        guard let url = components.url else {
            throw WeatherError.invalidURL(components.description)
        }

        let request = URLRequest(url: url)
        let response: OpenMeteoHourlyResponse = try await perform(request)

        let hourlyForecasts = (0..<min(clampedHours, response.hourly.time.count)).compactMap { index -> HourlyForecast? in
            guard index < response.hourly.temperature2m.count,
                  index < response.hourly.weatherCode.count else {
                return nil
            }

            let time = parseISO8601Date(response.hourly.time[index]) ?? Date()
            let condition = WeatherCondition.fromWMOCode(response.hourly.weatherCode[index])

            return HourlyForecast(
                time: time,
                temperature: Temperature(celsius: response.hourly.temperature2m[index]),
                apparentTemperature: index < response.hourly.apparentTemperature.count ? Temperature(celsius: response.hourly.apparentTemperature[index]) : nil,
                condition: condition,
                conditionDescription: condition.description,
                precipitationProbability: index < response.hourly.precipitationProbability.count ? Double(response.hourly.precipitationProbability[index]) : nil,
                humidity: index < response.hourly.relativeHumidity2m.count ? Double(response.hourly.relativeHumidity2m[index]) : nil,
                windSpeed: index < response.hourly.windSpeed10m.count ? response.hourly.windSpeed10m[index] : nil,
                windDirection: index < response.hourly.windDirection10m.count ? Double(response.hourly.windDirection10m[index]) : nil,
                isDaytime: index < response.hourly.isDay.count ? response.hourly.isDay[index] == 1 : true
            )
        }

        return hourlyForecasts
    }

    // MARK: - Private

    private func resolveLocation(_ location: Location) async throws -> (Double, Double, String?) {
        switch location {
        case .coordinates(let latitude, let longitude):
            return (latitude, longitude, nil)
        case .city(let name):
            let result = try await GeocodingService.shared.geocode(city: name)
            return (result.latitude, result.longitude, result.name)
        }
    }

    private func perform<T: Decodable & Sendable>(_ request: URLRequest) async throws -> T {
        try await Retry.execute(
            maxAttempts: 3,
            strategy: ExponentialStrategy(base: 1.0, multiplier: 2.0),
            configuration: RetryConfiguration(
                maxAttempts: 3,
                shouldRetry: { error in
                    guard let weatherError = error as? WeatherError else { return true }
                    switch weatherError {
                    case .rateLimited, .apiError, .networkError:
                        return true
                    case .unsupportedLocation, .decodingFailed, .noDataAvailable, .unknown, .locationNotFound, .noProviderAvailable, .invalidURL:
                        return false
                    }
                }
            )
        ) { [session, decoder] in
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw WeatherError.unknown("Invalid response type")
            }

            switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw WeatherError.decodingFailed(error)
                }
            case 400:
                throw WeatherError.apiError(statusCode: 400, message: "Bad request")
            case 429:
                throw WeatherError.rateLimited
            default:
                throw WeatherError.apiError(statusCode: httpResponse.statusCode, message: nil)
            }
        }
    }

    private func parseISO8601Date(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]

        if let date = formatter.date(from: string) {
            return date
        }

        // Try without time zone
        formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate]
        return formatter.date(from: string)
    }

    private func parseDateOnly(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.date(from: string)
    }
}

// MARK: - Response Models

private struct OpenMeteoResponse: Decodable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let current: CurrentData

    struct CurrentData: Decodable {
        let time: String
        let temperature2m: Double
        let relativeHumidity2m: Double
        let weatherCode: Int
        let windSpeed10m: Double
        let windDirection10m: Double
        let isDay: Int

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case relativeHumidity2m = "relative_humidity_2m"
            case weatherCode = "weather_code"
            case windSpeed10m = "wind_speed_10m"
            case windDirection10m = "wind_direction_10m"
            case isDay = "is_day"
        }
    }
}

private struct OpenMeteoForecastResponse: Decodable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let daily: DailyData

    struct DailyData: Decodable {
        let time: [String]
        let weatherCode: [Int]
        let temperature2mMax: [Double]
        let temperature2mMin: [Double]
        let precipitationSum: [Double]
        let precipitationProbabilityMax: [Double]
        let sunrise: [String]
        let sunset: [String]
        let uvIndexMax: [Double]

        enum CodingKeys: String, CodingKey {
            case time
            case weatherCode = "weather_code"
            case temperature2mMax = "temperature_2m_max"
            case temperature2mMin = "temperature_2m_min"
            case precipitationSum = "precipitation_sum"
            case precipitationProbabilityMax = "precipitation_probability_max"
            case sunrise
            case sunset
            case uvIndexMax = "uv_index_max"
        }
    }
}

private struct OpenMeteoHourlyResponse: Decodable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let hourly: HourlyData

    struct HourlyData: Decodable {
        let time: [String]
        let temperature2m: [Double]
        let apparentTemperature: [Double]
        let weatherCode: [Int]
        let precipitationProbability: [Int]
        let relativeHumidity2m: [Int]
        let windSpeed10m: [Double]
        let windDirection10m: [Int]
        let isDay: [Int]

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case apparentTemperature = "apparent_temperature"
            case weatherCode = "weather_code"
            case precipitationProbability = "precipitation_probability"
            case relativeHumidity2m = "relative_humidity_2m"
            case windSpeed10m = "wind_speed_10m"
            case windDirection10m = "wind_direction_10m"
            case isDay = "is_day"
        }
    }
}

