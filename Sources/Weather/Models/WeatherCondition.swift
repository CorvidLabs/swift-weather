import Foundation

/// Weather condition categories.
public enum WeatherCondition: String, Codable, Sendable, CaseIterable {
    case clear
    case partlyCloudy
    case cloudy
    case fog
    case drizzle
    case rain
    case freezingRain
    case snow
    case sleet
    case thunderstorm
    case unknown

    /// Human-readable description of the condition.
    public var description: String {
        switch self {
        case .clear:
            return "Clear"
        case .partlyCloudy:
            return "Partly Cloudy"
        case .cloudy:
            return "Cloudy"
        case .fog:
            return "Fog"
        case .drizzle:
            return "Drizzle"
        case .rain:
            return "Rain"
        case .freezingRain:
            return "Freezing Rain"
        case .snow:
            return "Snow"
        case .sleet:
            return "Sleet"
        case .thunderstorm:
            return "Thunderstorm"
        case .unknown:
            return "Unknown"
        }
    }

    /**
     Creates a condition from a WMO weather code.
     - Parameter code: The WMO weather code (0-99).
     - Returns: The corresponding `WeatherCondition`.
     */
    public static func fromWMOCode(_ code: Int) -> WeatherCondition {
        switch code {
        case 0:
            return .clear
        case 1, 2:
            return .partlyCloudy
        case 3:
            return .cloudy
        case 45, 48:
            return .fog
        case 51, 53, 55:
            return .drizzle
        case 56, 57:
            return .freezingRain
        case 61, 63, 65, 80, 81, 82:
            return .rain
        case 66, 67:
            return .freezingRain
        case 71, 73, 75, 77, 85, 86:
            return .snow
        case 79:
            return .sleet
        case 95, 96, 99:
            return .thunderstorm
        default:
            return .unknown
        }
    }

    /**
     Creates a condition from NWS text description.
     - Parameter text: The NWS text description.
     - Returns: The corresponding `WeatherCondition`.
     */
    public static func fromNWSText(_ text: String) -> WeatherCondition {
        let lower = text.lowercased()

        if lower.contains("thunder") {
            return .thunderstorm
        }
        if lower.contains("freezing rain") || lower.contains("ice") {
            return .freezingRain
        }
        if lower.contains("sleet") {
            return .sleet
        }
        if lower.contains("snow") || lower.contains("flurr") {
            return .snow
        }
        if lower.contains("drizzle") {
            return .drizzle
        }
        if lower.contains("rain") || lower.contains("shower") {
            return .rain
        }
        if lower.contains("fog") || lower.contains("mist") || lower.contains("haze") {
            return .fog
        }
        if lower.contains("overcast") {
            return .cloudy
        }
        if lower.contains("cloud") || lower.contains("partly") {
            return .partlyCloudy
        }
        if lower.contains("clear") || lower.contains("sunny") || lower.contains("fair") {
            return .clear
        }

        return .unknown
    }
}
