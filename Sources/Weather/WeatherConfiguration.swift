import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Configuration for the Weather client.
public struct WeatherConfiguration: Sendable {
    /**
     User-Agent string for NWS API.

     Required by NWS. Format: "(AppName, contact@email.com)"
     */
    public let userAgent: String

    /// Preferred temperature unit for display.
    public let temperatureUnit: TemperatureUnit

    /// Provider selection strategy.
    public let providerStrategy: ProviderStrategy

    /**
     Creates a new configuration.
     - Parameters:
       - userAgent: User-Agent string for NWS API. Required format: "(AppName, contact@email.com)"
       - temperatureUnit: Preferred temperature unit. Defaults to `.fahrenheit`.
       - providerStrategy: Provider selection strategy. Defaults to `.automatic`.
     */
    public init(
        userAgent: String,
        temperatureUnit: TemperatureUnit = .fahrenheit,
        providerStrategy: ProviderStrategy = .automatic
    ) {
        self.userAgent = userAgent
        self.temperatureUnit = temperatureUnit
        self.providerStrategy = providerStrategy
    }

    /**
     Creates a configuration optimized for US locations.

     Uses NWS as the primary provider with Open-Meteo fallback.
     - Parameter userAgent: User-Agent string for NWS API.
     - Returns: A configuration for US-focused apps.
     */
    public static func us(userAgent: String) -> WeatherConfiguration {
        WeatherConfiguration(
            userAgent: userAgent,
            temperatureUnit: .fahrenheit,
            providerStrategy: .automatic
        )
    }

    /**
     Creates a configuration for international locations.

     Uses Open-Meteo only (global coverage).
     - Parameter userAgent: User-Agent string (still required for consistency).
     - Returns: A configuration for international apps.
     */
    public static func international(userAgent: String) -> WeatherConfiguration {
        WeatherConfiguration(
            userAgent: userAgent,
            temperatureUnit: .celsius,
            providerStrategy: .openMeteoOnly
        )
    }
}

/// Strategy for selecting weather data providers.
public enum ProviderStrategy: Sendable, Equatable {
    /**
     Automatically select the best provider based on location.

     Uses NWS for US locations, Open-Meteo for international.
     */
    case automatic

    /**
     Use only the National Weather Service.

     Will fail for non-US locations.
     */
    case nwsOnly

    /**
     Use only Open-Meteo.

     Works globally.
     */
    case openMeteoOnly

    /**
     Creates the appropriate providers for this strategy.
     - Parameters:
       - userAgent: User-Agent string for NWS API.
       - session: The URL session to use.
     - Returns: An array of weather providers in priority order.
     */
    public func providers(userAgent: String, session: URLSession) -> [any WeatherProvider] {
        switch self {
        case .automatic:
            [
                NWSProvider(userAgent: userAgent, session: session),
                OpenMeteoProvider(session: session)
            ]
        case .nwsOnly:
            [NWSProvider(userAgent: userAgent, session: session)]
        case .openMeteoOnly:
            [OpenMeteoProvider(session: session)]
        }
    }
}
