import Foundation

/**
 A protocol for weather data providers.

 Implement this protocol to add custom weather data sources.

 Example:
 ```swift
 public actor MyWeatherProvider: WeatherProvider {
     public let info = WeatherProviderInfo(name: "MyProvider")

     public func supports(location: Location) async -> Bool {
         // Return true if this provider can service the location
         true
     }

     public func currentWeather(for location: Location) async throws -> CurrentWeather {
         // Fetch and return weather data
     }
 }
 ```
 */
public protocol WeatherProvider: Sendable {
    /// Information about this provider.
    var info: WeatherProviderInfo { get }

    /**
     Checks if this provider supports the given location.
     - Parameter location: The location to check.
     - Returns: `true` if this provider can service the location.
     */
    func supports(location: Location) async -> Bool

    /**
     Fetches current weather for the given location.
     - Parameter location: The location to fetch weather for.
     - Returns: The current weather conditions.
     - Throws: `WeatherError` if the request fails.
     */
    func currentWeather(for location: Location) async throws -> CurrentWeather

    /**
     Fetches a multi-day forecast for the given location.
     - Parameters:
       - location: The location to fetch the forecast for.
       - days: Number of days to forecast (1-16, provider dependent).
     - Returns: The forecast.
     - Throws: `WeatherError` if the request fails.
     */
    func forecast(for location: Location, days: Int) async throws -> Forecast

    /**
     Fetches an hourly forecast for the given location.
     - Parameters:
       - location: The location to fetch the forecast for.
       - hours: Number of hours to forecast (1-168, provider dependent).
     - Returns: The hourly forecasts.
     - Throws: `WeatherError` if the request fails.
     */
    func hourlyForecast(for location: Location, hours: Int) async throws -> [HourlyForecast]
}
