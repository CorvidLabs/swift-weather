import Foundation
import Retry

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Open-Meteo API weather provider.
///
/// Provides global weather data. Free for non-commercial use,
/// requires subscription for commercial use.
///
/// API Documentation: https://open-meteo.com/en/docs
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

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
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

