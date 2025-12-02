import Foundation
import Weather

/// Temperature display unit.
public enum TemperatureUnit: String, Sendable {
    case celsius = "C"
    case fahrenheit = "F"
}

/// Configuration for SVG weather image generation.
public struct WeatherSVGConfig: Sendable {
    /// Canvas width in pixels.
    public let width: Int

    /// Canvas height in pixels.
    public let height: Int

    /// Temperature display unit.
    public let temperatureUnit: TemperatureUnit

    /// Default configuration (400x400 pixel art).
    public static let `default` = WeatherSVGConfig(
        width: 400,
        height: 400,
        temperatureUnit: .fahrenheit
    )

    /// Creates a new SVG configuration.
    public init(
        width: Int = 400,
        height: Int = 400,
        temperatureUnit: TemperatureUnit = .fahrenheit
    ) {
        self.width = width
        self.height = height
        self.temperatureUnit = temperatureUnit
    }
}

/// Generates SVG weather images from weather data.
///
/// Creates multi-panel pixel art graphics with:
/// - Large weather icon (top panel)
/// - Data grid with stats (middle panel)
/// - Location and time (footer)
public enum WeatherSVGGenerator {
    // MARK: - Public API

    /// Generates an SVG image from weather data.
    ///
    /// - Parameters:
    ///   - weather: The current weather data.
    ///   - config: SVG generation configuration.
    /// - Returns: Complete SVG document as a string.
    public static func generate(
        from weather: CurrentWeather,
        config: WeatherSVGConfig = .default
    ) -> String {
        let width = Double(config.width)
        let height = Double(config.height)
        let centerX = width / 2

        var contentParts: [String] = []

        // 1. Banded background
        contentParts.append(createBandedBackground(for: weather, width: width, height: height))

        // 2. Large weather icon (top 50%, centered at y=25%)
        let iconY = height * 0.25
        let iconSize = min(width, height) * 0.45

        contentParts.append(WeatherIcons.render(
            for: weather.condition,
            isDaytime: weather.isDaytime,
            centerX: centerX,
            centerY: iconY,
            size: iconSize
        ))

        // 3. Condition description (at y=52%)
        let fontFamily = "'Press Start 2P', 'Courier New', monospace"
        let bgColor = lightestBackground(for: weather.condition, isDaytime: weather.isDaytime)
        let primaryText = textColor(for: bgColor)
        let secondaryText = secondaryTextColor(for: bgColor)

        contentParts.append(SVGBuilder.text(
            weather.conditionDescription,
            x: centerX,
            y: height * 0.52,
            fontSize: height * 0.035,
            fill: primaryText,
            fontFamily: fontFamily
        ))

        // 4. Data grid (y=58% to y=82%)
        // Data boxes have rgba(0,0,0,0.4) overlay - always use white text for contrast
        contentParts.append(renderDataGrid(
            weather: weather,
            config: config,
            width: width,
            height: height,
            primaryTextColor: "#FFFFFF",
            secondaryTextColor: "rgba(255,255,255,0.7)"
        ))

        // 5. Footer: Location (y=88%)
        let locationName = weather.location.name ?? formatCoordinates(
            latitude: weather.location.latitude,
            longitude: weather.location.longitude
        )
        contentParts.append(SVGBuilder.text(
            locationName,
            x: centerX,
            y: height * 0.90,
            fontSize: height * 0.028,
            fill: primaryText,
            fontFamily: fontFamily
        ))

        // 6. Footer: Time (y=95%)
        let timeString = formatTime(weather.observationTime)
        contentParts.append(SVGBuilder.text(
            timeString,
            x: centerX,
            y: height * 0.96,
            fontSize: height * 0.022,
            fill: secondaryText,
            fontFamily: fontFamily
        ))

        return SVGBuilder.document(
            width: config.width,
            height: config.height,
            content: contentParts.joined(separator: "\n")
        )
    }

    /// Converts an SVG string to Data for IPFS upload.
    public static func toData(_ svg: String) -> Data {
        Data(svg.utf8)
    }

    // MARK: - Data Grid

    private static func renderDataGrid(
        weather: CurrentWeather,
        config: WeatherSVGConfig,
        width: Double,
        height: Double,
        primaryTextColor: String,
        secondaryTextColor: String
    ) -> String {
        let gridY = height * 0.56
        let gridHeight = height * 0.28
        let boxWidth = width * 0.42
        let boxHeight = gridHeight * 0.45
        let padding = width * 0.04
        let leftX = padding
        let rightX = width - boxWidth - padding

        var elements: [String] = []

        // Temperature value
        let tempValue = config.temperatureUnit == .fahrenheit
            ? weather.temperature.fahrenheit
            : weather.temperature.celsius
        let tempText = "\(Int(round(tempValue)))°\(config.temperatureUnit.rawValue)"

        // Humidity value
        let humidityText = weather.humidity.map { "\(Int($0))%" } ?? "--"

        // Wind value
        let windText = weather.windSpeed.map { "\(Int($0)) km/h" } ?? "--"

        // Feels like (estimate based on humidity and wind)
        let feelsLike = calculateFeelsLike(temp: tempValue, humidity: weather.humidity, wind: weather.windSpeed)
        let feelsText = "\(Int(round(feelsLike)))°\(config.temperatureUnit.rawValue)"

        // Row 1: Temperature | Humidity
        elements.append(renderDataBox(
            x: leftX, y: gridY,
            width: boxWidth, height: boxHeight,
            value: tempText, label: "TEMP",
            valueColor: primaryTextColor, labelColor: secondaryTextColor
        ))
        elements.append(renderDataBox(
            x: rightX, y: gridY,
            width: boxWidth, height: boxHeight,
            value: humidityText, label: "HUMIDITY",
            valueColor: primaryTextColor, labelColor: secondaryTextColor
        ))

        // Row 2: Wind | Feels Like
        let row2Y = gridY + boxHeight + padding * 0.5
        elements.append(renderDataBox(
            x: leftX, y: row2Y,
            width: boxWidth, height: boxHeight,
            value: windText, label: "WIND",
            valueColor: primaryTextColor, labelColor: secondaryTextColor
        ))
        elements.append(renderDataBox(
            x: rightX, y: row2Y,
            width: boxWidth, height: boxHeight,
            value: feelsText, label: "FEELS",
            valueColor: primaryTextColor, labelColor: secondaryTextColor
        ))

        return elements.joined(separator: "\n")
    }

    private static func renderDataBox(
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        value: String,
        label: String,
        valueColor: String,
        labelColor: String
    ) -> String {
        let fontFamily = "'Press Start 2P', 'Courier New', monospace"
        let borderWidth = 2.0
        let cornerRadius = 4.0

        var elements: [String] = []

        // Box background
        elements.append(SVGBuilder.rect(
            x: x, y: y,
            width: width, height: height,
            fill: "rgba(0,0,0,0.4)",
            rx: cornerRadius
        ))

        // Box border
        elements.append(SVGBuilder.rect(
            x: x + borderWidth/2, y: y + borderWidth/2,
            width: width - borderWidth, height: height - borderWidth,
            fill: "none",
            rx: cornerRadius
        ).replacingOccurrences(of: "fill=\"none\"", with: "fill=\"none\" stroke=\"#505050\" stroke-width=\"\(borderWidth)\""))

        // Value text (large)
        elements.append(SVGBuilder.text(
            value,
            x: x + width / 2,
            y: y + height * 0.50,
            fontSize: height * 0.35,
            fill: valueColor,
            fontWeight: "bold",
            fontFamily: fontFamily
        ))

        // Label text (small)
        elements.append(SVGBuilder.text(
            label,
            x: x + width / 2,
            y: y + height * 0.80,
            fontSize: height * 0.18,
            fill: labelColor,
            fontFamily: fontFamily
        ))

        return elements.joined(separator: "\n")
    }

    private static func calculateFeelsLike(temp: Double, humidity: Double?, wind: Double?) -> Double {
        // Simple feels-like calculation
        var feelsLike = temp

        // Wind chill effect (cold temps)
        if temp < 50, let wind = wind, wind > 5 {
            feelsLike -= (wind / 10) * 2
        }

        // Heat index effect (hot temps with humidity)
        if temp > 80, let humidity = humidity, humidity > 40 {
            feelsLike += (humidity - 40) / 20 * 3
        }

        return feelsLike
    }

    // MARK: - Banded Background

    private static func createBandedBackground(
        for weather: CurrentWeather,
        width: Double,
        height: Double
    ) -> String {
        let colors = bandColors(for: weather.condition, isDaytime: weather.isDaytime)
        let bandHeight = height / Double(colors.count)

        var bands: [String] = []
        for (index, color) in colors.enumerated() {
            bands.append(SVGBuilder.rect(
                x: 0,
                y: Double(index) * bandHeight,
                width: width,
                height: bandHeight + 1,
                fill: color
            ))
        }

        return bands.joined(separator: "\n")
    }

    private static func bandColors(for condition: WeatherCondition, isDaytime: Bool) -> [String] {
        isDaytime ? dayBandColors(for: condition) : nightBandColors(for: condition)
    }

    private static func dayBandColors(for condition: WeatherCondition) -> [String] {
        switch condition {
        case .clear:
            return ["#87CEEB", "#6BB3D9", "#4A9AC7", "#4682B4"]
        case .partlyCloudy:
            return ["#87CEEB", "#7BAED4", "#6F9FBF", "#6495ED"]
        case .cloudy:
            return ["#909090", "#808080", "#707070", "#606060"]
        case .fog:
            return ["#C8C8C8", "#B8B8B8", "#A8A8A8", "#989898"]
        case .drizzle, .rain:
            return ["#5080A0", "#406080", "#305060", "#204050"]
        case .freezingRain:
            return ["#A0C0D8", "#80A0C0", "#6080A0", "#405080"]
        case .snow:
            return ["#E8E8E8", "#D8D8D8", "#C8C8C8", "#B8B8B8"]
        case .sleet:
            return ["#A0B8C8", "#8098A8", "#607888", "#506070"]
        case .thunderstorm:
            return ["#404040", "#303030", "#202020", "#101010"]
        case .unknown:
            return ["#808080", "#707070", "#606060", "#505050"]
        }
    }

    private static func nightBandColors(for condition: WeatherCondition) -> [String] {
        switch condition {
        case .clear:
            return ["#1A1A2E", "#181830", "#161838", "#14163E"]
        case .partlyCloudy:
            return ["#1A1A2E", "#202038", "#282840", "#303050"]
        case .cloudy:
            return ["#383848", "#303040", "#282838", "#202030"]
        case .fog:
            return ["#404040", "#383838", "#303030", "#282828"]
        case .drizzle, .rain:
            return ["#1A3040", "#183038", "#162830", "#142028"]
        case .freezingRain:
            return ["#1A3050", "#183048", "#162840", "#142038"]
        case .snow:
            return ["#383848", "#303040", "#282838", "#202030"]
        case .sleet:
            return ["#283040", "#203038", "#182830", "#102028"]
        case .thunderstorm:
            return ["#0A0A10", "#080810", "#060608", "#040408"]
        case .unknown:
            return ["#282828", "#242424", "#202020", "#1C1C1C"]
        }
    }

    // MARK: - Color Accessibility

    /// Calculates relative luminance of a hex color per WCAG 2.1 formula.
    /// Returns value between 0 (black) and 1 (white).
    private static func luminance(of hex: String) -> Double {
        let cleanHex = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard cleanHex.count == 6,
              let r = Int(cleanHex.prefix(2), radix: 16),
              let g = Int(cleanHex.dropFirst(2).prefix(2), radix: 16),
              let b = Int(cleanHex.dropFirst(4).prefix(2), radix: 16) else {
            return 0.5 // Default to mid-range if parsing fails
        }

        func linearize(_ channel: Int) -> Double {
            let sRGB = Double(channel) / 255.0
            return sRGB <= 0.03928 ? sRGB / 12.92 : pow((sRGB + 0.055) / 1.055, 2.4)
        }

        return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)
    }

    /// Returns appropriate text color (pure black or white) based on background luminance.
    /// Uses 0.5 threshold for maximum contrast.
    private static func textColor(for background: String) -> String {
        luminance(of: background) > 0.5 ? "#000000" : "#FFFFFF"
    }

    /// Returns appropriate secondary text color using opacity for dimming.
    /// This ensures the color always has good contrast while being visually subdued.
    private static func secondaryTextColor(for background: String) -> String {
        luminance(of: background) > 0.5 ? "rgba(0,0,0,0.6)" : "rgba(255,255,255,0.6)"
    }

    /// Gets the lightest background color for a weather condition.
    private static func lightestBackground(for condition: WeatherCondition, isDaytime: Bool) -> String {
        let colors = isDaytime ? dayBandColors(for: condition) : nightBandColors(for: condition)
        // Return the color with highest luminance
        return colors.max(by: { luminance(of: $0) < luminance(of: $1) }) ?? "#808080"
    }

    // MARK: - Formatting

    private static func formatCoordinates(latitude: Double, longitude: Double) -> String {
        let latDir = latitude >= 0 ? "N" : "S"
        let lonDir = longitude >= 0 ? "E" : "W"
        return String(format: "%.2f°%@ %.2f°%@", abs(latitude), latDir, abs(longitude), lonDir)
    }

    private static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy h:mm a"
        formatter.timeZone = .current
        return formatter.string(from: date)
    }
}
