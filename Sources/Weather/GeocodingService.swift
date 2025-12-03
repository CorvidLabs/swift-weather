import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
 A shared service for geocoding city names to coordinates.

 Uses the Open-Meteo geocoding API which is free and requires no authentication.
 */
public actor GeocodingService {
    /// Shared singleton instance.
    public static let shared = GeocodingService()

    /// The URL session for requests.
    private let session: URLSession

    /// JSON decoder for responses.
    private let decoder: JSONDecoder

    /// Base URL for the geocoding API.
    private static let baseURL = URL(string: "https://geocoding-api.open-meteo.com/v1/search")!

    /// Creates a new geocoding service.
    /// - Parameter session: The URL session to use. Defaults to `.shared`.
    public init(session: URLSession = .shared) {
        self.session = session

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    /**
     Geocodes a city name to coordinates.
     - Parameter city: The city name (e.g., "Seattle, WA" or "Paris, France").
     - Returns: A tuple of (latitude, longitude, resolved name).
     - Throws: `WeatherError.locationNotFound` if the city cannot be found.
     */
    public func geocode(city: String) async throws -> (latitude: Double, longitude: Double, name: String?) {
        guard var components = URLComponents(url: Self.baseURL, resolvingAgainstBaseURL: false) else {
            throw WeatherError.invalidURL(Self.baseURL.absoluteString)
        }

        components.queryItems = [
            URLQueryItem(name: "name", value: city),
            URLQueryItem(name: "count", value: "1")
        ]

        guard let url = components.url else {
            throw WeatherError.invalidURL(components.description)
        }

        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherError.unknown("Invalid response type")
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 429:
            throw WeatherError.rateLimited
        default:
            throw WeatherError.apiError(statusCode: httpResponse.statusCode, message: nil)
        }

        let geocodingResponse: GeocodingResponse
        do {
            geocodingResponse = try decoder.decode(GeocodingResponse.self, from: data)
        } catch {
            throw WeatherError.decodingFailed(error)
        }

        guard let result = geocodingResponse.results?.first else {
            throw WeatherError.locationNotFound(city)
        }

        let name = [result.name, result.admin1, result.country]
            .compactMap { $0 }
            .joined(separator: ", ")

        return (result.latitude, result.longitude, name.isEmpty ? nil : name)
    }
}

// MARK: - Response Models

private struct GeocodingResponse: Decodable {
    let results: [GeocodingResult]?
}

private struct GeocodingResult: Decodable {
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
    let admin1: String?
}
