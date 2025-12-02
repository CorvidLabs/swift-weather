import Foundation

/// Errors that can occur when fetching weather data.
public enum WeatherError: Error, Sendable {
    /// The location could not be found or geocoded.
    case locationNotFound(String)

    /// The location is not supported by the selected provider.
    case unsupportedLocation(String)

    /// A network error occurred.
    case networkError(Error)

    /// Failed to decode the API response.
    case decodingFailed(Error)

    /// The API returned an error.
    case apiError(statusCode: Int, message: String?)

    /// No weather data available for this location.
    case noDataAvailable

    /// Rate limited by the API.
    case rateLimited

    /// No provider available for this location.
    case noProviderAvailable

    /// Invalid URL.
    case invalidURL(String)

    /// Unknown error.
    case unknown(String)
}

extension WeatherError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .locationNotFound(let location):
            return "Location not found: \(location)"
        case .unsupportedLocation(let reason):
            return "Location not supported: \(reason)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .apiError(let code, let message):
            return "API error \(code): \(message ?? "Unknown")"
        case .noDataAvailable:
            return "No weather data available for this location"
        case .rateLimited:
            return "Rate limited - please try again later"
        case .noProviderAvailable:
            return "No weather provider available for this location"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

extension WeatherError: Equatable {
    public static func == (lhs: WeatherError, rhs: WeatherError) -> Bool {
        switch (lhs, rhs) {
        case (.locationNotFound(let a), .locationNotFound(let b)):
            return a == b
        case (.unsupportedLocation(let a), .unsupportedLocation(let b)):
            return a == b
        case (.networkError, .networkError):
            return true
        case (.decodingFailed, .decodingFailed):
            return true
        case (.apiError(let codeA, let msgA), .apiError(let codeB, let msgB)):
            return codeA == codeB && msgA == msgB
        case (.noDataAvailable, .noDataAvailable):
            return true
        case (.rateLimited, .rateLimited):
            return true
        case (.noProviderAvailable, .noProviderAvailable):
            return true
        case (.invalidURL(let a), .invalidURL(let b)):
            return a == b
        case (.unknown(let a), .unknown(let b)):
            return a == b
        default:
            return false
        }
    }
}
