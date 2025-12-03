import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
 A client for fetching weather data from multiple providers.

 `Weather` provides a unified interface for weather data, automatically
 selecting the best provider based on location. For US locations, it uses
 the NWS API (free for commercial use). For international locations or
 as a fallback, it uses Open-Meteo.

 Example usage:

 ```swift
 let weather = Weather(userAgent: "(MyApp, me@example.com)")

 // By coordinates (US - uses NWS)
 let seattle = try await weather.current(latitude: 47.6, longitude: -122.3)
 print("\(seattle.temperature.formatted()) - \(seattle.condition.description)")

 // By city (international - uses Open-Meteo)
 let paris = try await weather.current(city: "Paris, France")

 // Stream weather updates every hour
 for await update in weather.weatherUpdates(at: .city("Seattle, WA"), intervalSeconds: 3600) {
     print("Update: \(update.temperature.formatted())")
 }
 ```
 */
public actor Weather {
    /// The configuration for this client.
    public let configuration: WeatherConfiguration

    /// The available weather providers.
    private let providers: [any WeatherProvider]

    /// The URL session for requests.
    private let session: URLSession

    /**
     Creates a new Weather client.
     - Parameters:
       - configuration: The configuration for this client.
       - session: The URL session to use. Defaults to `.shared`.
     */
    public init(
        configuration: WeatherConfiguration,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session
        self.providers = configuration.providerStrategy.providers(
            userAgent: configuration.userAgent,
            session: session
        )
    }

    /**
     Creates a new Weather client with default configuration.
     - Parameters:
       - userAgent: User-Agent string for NWS API. Format: "(AppName, contact@email.com)"
       - session: The URL session to use. Defaults to `.shared`.
     */
    public init(
        userAgent: String,
        session: URLSession = .shared
    ) {
        self.init(
            configuration: WeatherConfiguration(userAgent: userAgent),
            session: session
        )
    }

    // MARK: - Public API

    /**
     Fetches current weather for the given location.
     - Parameter location: The location to fetch weather for.
     - Returns: The current weather conditions.
     - Throws: `WeatherError` if the request fails.
     */
    public func current(at location: Location) async throws -> CurrentWeather {
        try await firstSuccessfulProvider(for: location)
    }

    /**
     Fetches current weather for the given coordinates.
     - Parameters:
       - latitude: The latitude.
       - longitude: The longitude.
     - Returns: The current weather conditions.
     - Throws: `WeatherError` if the request fails.
     */
    public func current(latitude: Double, longitude: Double) async throws -> CurrentWeather {
        try await current(at: .coordinates(latitude: latitude, longitude: longitude))
    }

    /**
     Fetches current weather for the given city.
     - Parameter city: The city name (e.g., "Seattle, WA" or "Paris, France").
     - Returns: The current weather conditions.
     - Throws: `WeatherError` if the request fails.
     */
    public func current(city: String) async throws -> CurrentWeather {
        try await current(at: .city(city))
    }

    /**
     Creates an async stream of weather updates for a location.

     The stream fetches weather at the specified interval until cancelled.

     - Parameters:
       - location: The location to fetch weather for.
       - intervalSeconds: The interval between updates in seconds. Defaults to 3600 (1 hour).
     - Returns: An `AsyncStream` yielding weather updates.
     */
    public func weatherUpdates(
        at location: Location,
        intervalSeconds: UInt64 = 3600
    ) -> AsyncStream<CurrentWeather> {
        let nanoseconds = intervalSeconds * 1_000_000_000

        return AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled {
                    if let weather = try? await self.current(at: location) {
                        continuation.yield(weather)
                    }
                    try? await Task.sleep(nanoseconds: nanoseconds)
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Private

    /// Tries each provider in order until one succeeds.
    private func firstSuccessfulProvider(for location: Location) async throws -> CurrentWeather {
        var lastError: Error?

        for provider in providers {
            guard await provider.supports(location: location) else { continue }

            do {
                return try await provider.currentWeather(for: location)
            } catch {
                lastError = error
            }
        }

        if let error = lastError {
            throw error
        }
        throw WeatherError.noProviderAvailable
    }
}
