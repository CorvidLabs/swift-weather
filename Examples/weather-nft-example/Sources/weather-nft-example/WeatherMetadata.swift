import Foundation
import Mint
import Weather

/// Builds ARC-3 compliant metadata from weather data.
enum WeatherMetadata {
    /// Creates ARC-3 metadata from current weather conditions.
    ///
    /// - Parameters:
    ///   - weather: The current weather data.
    ///   - imageCID: The IPFS CID of the weather condition image.
    ///   - imageMimetype: The MIME type of the image (e.g., "image/svg+xml").
    /// - Returns: ARC-3 compliant metadata for the NFT.
    static func build(
        from weather: CurrentWeather,
        imageCID: String?,
        imageMimetype: String = "image/svg+xml"
    ) -> ARC3Metadata {
        let locationName = weather.location.name ?? "Unknown Location"
        let timestamp = ISO8601DateFormatter().string(from: weather.observationTime)

        // Build properties dictionary
        var properties: [String: AnyCodable] = [
            "temperature_celsius": AnyCodable(weather.temperature.celsius),
            "temperature_fahrenheit": AnyCodable(weather.temperature.fahrenheit),
            "condition": AnyCodable(weather.condition.rawValue),
            "condition_description": AnyCodable(weather.conditionDescription),
            "is_daytime": AnyCodable(weather.isDaytime),
            "latitude": AnyCodable(weather.location.latitude),
            "longitude": AnyCodable(weather.location.longitude),
            "observation_time": AnyCodable(timestamp),
            "provider": AnyCodable(weather.provider.name)
        ]

        if let humidity = weather.humidity {
            properties["humidity"] = AnyCodable(humidity)
        }

        if let windSpeed = weather.windSpeed {
            properties["wind_speed"] = AnyCodable(windSpeed)
        }

        if let windDirection = weather.windDirection {
            properties["wind_direction"] = AnyCodable(windDirection)
        }

        if let timezone = weather.location.timezone {
            properties["timezone"] = AnyCodable(timezone)
        }

        // Build image URL if CID provided
        let imageURL: String? = imageCID.map { "ipfs://\($0)" }

        return ARC3Metadata(
            name: "Weather: \(locationName)",
            description: buildDescription(from: weather),
            image: imageURL,
            imageMimetype: imageCID != nil ? imageMimetype : nil,
            externalUrl: nil,
            backgroundColor: backgroundColor(for: weather),
            properties: properties
        )
    }

    /// Encodes metadata to JSON data for IPFS upload.
    ///
    /// - Parameter metadata: The ARC-3 metadata to encode.
    /// - Returns: JSON data representation.
    static func encode(_ metadata: ARC3Metadata) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(metadata)
    }

    // MARK: - Private

    private static func buildDescription(from weather: CurrentWeather) -> String {
        let location = weather.location.name ?? "\(weather.location.latitude), \(weather.location.longitude)"
        let temp = String(format: "%.1f", weather.temperature.fahrenheit)

        var parts = [
            "\(weather.conditionDescription) in \(location).",
            "Temperature: \(temp)°F."
        ]

        if let humidity = weather.humidity {
            parts.append("Humidity: \(Int(humidity))%.")
        }

        if let windSpeed = weather.windSpeed {
            parts.append("Wind: \(Int(windSpeed)) km/h.")
        }

        return parts.joined(separator: " ")
    }

    private static func backgroundColor(for weather: CurrentWeather) -> String {
        // Return hex color based on condition and time
        if !weather.isDaytime {
            return "1a1a2e" // Dark blue for night
        }

        switch weather.condition {
        case .clear:
            return "87ceeb" // Sky blue
        case .partlyCloudy:
            return "b0c4de" // Light steel blue
        case .cloudy:
            return "778899" // Light slate gray
        case .rain, .drizzle:
            return "4682b4" // Steel blue
        case .snow:
            return "e0e0e0" // Light gray
        case .thunderstorm:
            return "2f4f4f" // Dark slate gray
        case .fog:
            return "c0c0c0" // Silver
        case .freezingRain, .sleet:
            return "b0e0e6" // Powder blue
        case .unknown:
            return "808080" // Gray
        }
    }
}
