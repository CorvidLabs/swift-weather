import Foundation
import Weather
import ASCIIPixelArt

/// Color palette for weather icons - designed for WCAG AA accessibility.
/// Each color is chosen to contrast well against its corresponding background.
enum WeatherPalette {
    // Day colors - must contrast with lighter backgrounds
    static let sunYellow = "#FFD800"        // Gold sun on blue sky
    static let cloudWhiteDay = "#E8E8E8"    // Light cloud on gray
    static let fogDark = "#505050"          // Dark fog on light gray bg
    static let rainCyanDay = "#40E0FF"      // Bright cyan on blue-gray
    static let freezingBlueDay = "#4080C0"  // Dark blue on light blue-gray
    static let snowBlueDay = "#4080C0"      // Blue snowflake on white bg
    static let sleetDarkDay = "#3060A0"     // Dark blue on light gray-blue
    static let unknownLight = "#E0E0E0"     // Light on medium gray

    // Night colors - must contrast with darker backgrounds
    static let moonWhite = "#FFFACD"        // Cream moon on dark blue
    static let cloudGrayNight = "#B0B0B0"   // Gray cloud on dark
    static let fogLight = "#C0C0C0"         // Light fog on dark gray
    static let rainCyanNight = "#60D0FF"    // Cyan on dark blue
    static let freezingBlueNight = "#80C0E0" // Light blue on dark
    static let snowWhiteNight = "#E0E0FF"   // White-blue on dark
    static let sleetLightNight = "#80C0E0"  // Light blue on dark
    static let unknownGray = "#A0A0A0"      // Medium gray on dark

    // Universal colors - work on most backgrounds
    static let lightning = "#FFFF00"        // Yellow lightning (high contrast)
}

/// Loads and renders weather icons from ASCII art files.
public enum WeatherIcons {
    /// Renders a weather icon for the given condition.
    ///
    /// - Parameters:
    ///   - condition: The weather condition to render.
    ///   - isDaytime: Whether it's currently daytime.
    ///   - centerX: Center X position for the icon.
    ///   - centerY: Center Y position for the icon.
    ///   - size: Icon size (width and height).
    /// - Returns: SVG elements for the icon.
    public static func render(
        for condition: WeatherCondition,
        isDaytime: Bool,
        centerX: Double,
        centerY: Double,
        size: Double
    ) -> String {
        let iconName = iconName(for: condition, isDaytime: isDaytime)
        let color = iconColor(for: condition, isDaytime: isDaytime)

        guard let grid = loadIcon(named: iconName) else {
            // Fallback to question mark if icon not found
            return renderFallback(centerX: centerX, centerY: centerY, size: size, color: color)
        }

        return renderGrid(grid, color: color, centerX: centerX, centerY: centerY, size: size)
    }

    // MARK: - Icon Loading

    private static func loadIcon(named name: String) -> PixelGrid? {
        // Try to load from bundle resources
        guard let url = Bundle.module.url(forResource: name, withExtension: "txt", subdirectory: "Icons") else {
            return nil
        }

        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }

        let pixels = ASCIIParser.parse(text)
        let bounds = ASCIIParser.bounds(of: text)

        guard bounds.width > 0, bounds.height > 0 else {
            return nil
        }

        var grid = PixelGrid(width: bounds.width, height: bounds.height)
        for (x, y) in pixels {
            grid[x, y] = "#FFFFFF" // Placeholder, actual color applied during render
        }

        return grid
    }

    // MARK: - Rendering

    private static func renderGrid(
        _ grid: PixelGrid,
        color: String,
        centerX: Double,
        centerY: Double,
        size: Double
    ) -> String {
        let maxDimension = max(grid.width, grid.height)
        let pixelSize = size / Double(maxDimension)
        let startX = centerX - (Double(grid.width) * pixelSize) / 2
        let startY = centerY - (Double(grid.height) * pixelSize) / 2

        var elements: [String] = []

        for (x, y, _) in grid.filledPixels {
            elements.append(SVGBuilder.rect(
                x: startX + Double(x) * pixelSize,
                y: startY + Double(y) * pixelSize,
                width: pixelSize,
                height: pixelSize,
                fill: color
            ))
        }

        return elements.joined(separator: "\n")
    }

    private static func renderFallback(
        centerX: Double,
        centerY: Double,
        size: Double,
        color: String
    ) -> String {
        // Simple question mark fallback
        let pixelSize = size / 16
        let startX = centerX - size / 2
        let startY = centerY - size / 2

        let questionMark: [(Int, Int)] = [
            (6, 3), (7, 3), (8, 3), (9, 3),
            (5, 4), (10, 4),
            (10, 5), (9, 6), (8, 7),
            (8, 8),
            (8, 10), (8, 11)
        ]

        return questionMark.map { (x, y) in
            SVGBuilder.rect(
                x: startX + Double(x) * pixelSize,
                y: startY + Double(y) * pixelSize,
                width: pixelSize,
                height: pixelSize,
                fill: color
            )
        }.joined(separator: "\n")
    }

    // MARK: - Icon Mapping

    private static func iconName(for condition: WeatherCondition, isDaytime: Bool) -> String {
        switch condition {
        case .clear:
            return isDaytime ? "sun" : "moon"
        case .partlyCloudy:
            return isDaytime ? "sun-cloud" : "moon-cloud"
        case .cloudy:
            return "cloud"
        case .fog:
            return "fog"
        case .drizzle, .rain:
            return "rain"
        case .freezingRain:
            return "rain" // Use rain icon with different color
        case .snow:
            return "snow"
        case .sleet:
            return "sleet"
        case .thunderstorm:
            return "thunder"
        case .unknown:
            return "unknown"
        }
    }

    private static func iconColor(for condition: WeatherCondition, isDaytime: Bool) -> String {
        switch condition {
        case .clear:
            return isDaytime ? WeatherPalette.sunYellow : WeatherPalette.moonWhite
        case .partlyCloudy:
            return isDaytime ? WeatherPalette.sunYellow : WeatherPalette.moonWhite
        case .cloudy:
            return isDaytime ? WeatherPalette.cloudWhiteDay : WeatherPalette.cloudGrayNight
        case .fog:
            return isDaytime ? WeatherPalette.fogDark : WeatherPalette.fogLight
        case .drizzle, .rain:
            return isDaytime ? WeatherPalette.rainCyanDay : WeatherPalette.rainCyanNight
        case .freezingRain:
            return isDaytime ? WeatherPalette.freezingBlueDay : WeatherPalette.freezingBlueNight
        case .snow:
            return isDaytime ? WeatherPalette.snowBlueDay : WeatherPalette.snowWhiteNight
        case .sleet:
            return isDaytime ? WeatherPalette.sleetDarkDay : WeatherPalette.sleetLightNight
        case .thunderstorm:
            return WeatherPalette.lightning
        case .unknown:
            return isDaytime ? WeatherPalette.unknownLight : WeatherPalette.unknownGray
        }
    }
}
