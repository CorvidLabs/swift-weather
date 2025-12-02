import Foundation
import Weather

/// 8-bit pixel art color palette.
enum PixelPalette {
    static let sunYellow = "#FFD800"
    static let sunOrange = "#FF8C00"
    static let moonWhite = "#FFFACD"
    static let moonGray = "#C0C0A0"
    static let starYellow = "#FFFF80"
    static let cloudWhite = "#F0F0F0"
    static let cloudLight = "#D0D0D0"
    static let cloudGray = "#A0A0A0"
    static let cloudDark = "#606060"
    static let rainBlue = "#00BFFF"
    static let rainDark = "#0080C0"
    static let snowWhite = "#FFFFFF"
    static let lightning = "#FFFF00"
    static let fogGray = "#B0B0B0"
}

/// Renders weather condition icons as 8-bit pixel art.
public enum PixelIcons {
    /// Renders a pixel art icon for the given weather condition.
    ///
    /// - Parameters:
    ///   - condition: The weather condition to render.
    ///   - isDaytime: Whether it's currently daytime.
    ///   - centerX: Center X position for the icon.
    ///   - centerY: Center Y position for the icon.
    ///   - size: Icon size (width and height).
    /// - Returns: SVG elements for the pixel art icon.
    public static func render(
        for condition: WeatherCondition,
        isDaytime: Bool,
        centerX: Double,
        centerY: Double,
        size: Double
    ) -> String {
        let pixelSize = size / 16 // 16x16 grid
        let startX = centerX - size / 2
        let startY = centerY - size / 2

        switch condition {
        case .clear:
            return isDaytime
                ? renderPixelSun(startX: startX, startY: startY, pixelSize: pixelSize)
                : renderPixelMoon(startX: startX, startY: startY, pixelSize: pixelSize)
        case .partlyCloudy:
            return isDaytime
                ? renderPixelSunCloud(startX: startX, startY: startY, pixelSize: pixelSize)
                : renderPixelMoonCloud(startX: startX, startY: startY, pixelSize: pixelSize)
        case .cloudy:
            return renderPixelCloud(startX: startX, startY: startY, pixelSize: pixelSize, dark: !isDaytime)
        case .fog:
            return renderPixelFog(startX: startX, startY: startY, pixelSize: pixelSize)
        case .drizzle:
            return renderPixelRain(startX: startX, startY: startY, pixelSize: pixelSize, heavy: false)
        case .rain:
            return renderPixelRain(startX: startX, startY: startY, pixelSize: pixelSize, heavy: true)
        case .freezingRain:
            return renderPixelFreezingRain(startX: startX, startY: startY, pixelSize: pixelSize)
        case .snow:
            return renderPixelSnow(startX: startX, startY: startY, pixelSize: pixelSize)
        case .sleet:
            return renderPixelSleet(startX: startX, startY: startY, pixelSize: pixelSize)
        case .thunderstorm:
            return renderPixelThunderstorm(startX: startX, startY: startY, pixelSize: pixelSize)
        case .unknown:
            return renderPixelCloud(startX: startX, startY: startY, pixelSize: pixelSize, dark: true)
        }
    }

    // MARK: - Pixel Rendering Helper

    private static func pixel(x: Int, y: Int, color: String, startX: Double, startY: Double, pixelSize: Double) -> String {
        SVGBuilder.rect(
            x: startX + Double(x) * pixelSize,
            y: startY + Double(y) * pixelSize,
            width: pixelSize,
            height: pixelSize,
            fill: color
        )
    }

    private static func pixels(_ coords: [(x: Int, y: Int)], color: String, startX: Double, startY: Double, pixelSize: Double) -> String {
        coords.map { pixel(x: $0.x, y: $0.y, color: color, startX: startX, startY: startY, pixelSize: pixelSize) }
            .joined(separator: "\n")
    }

    // MARK: - Sun (16x16)

    private static func renderPixelSun(startX: Double, startY: Double, pixelSize: Double) -> String {
        // Sun center (yellow circle)
        let sunCenter: [(Int, Int)] = [
            (6, 5), (7, 5), (8, 5), (9, 5),
            (5, 6), (6, 6), (7, 6), (8, 6), (9, 6), (10, 6),
            (5, 7), (6, 7), (7, 7), (8, 7), (9, 7), (10, 7),
            (5, 8), (6, 8), (7, 8), (8, 8), (9, 8), (10, 8),
            (5, 9), (6, 9), (7, 9), (8, 9), (9, 9), (10, 9),
            (6, 10), (7, 10), (8, 10), (9, 10)
        ]

        // Sun rays
        let rays: [(Int, Int)] = [
            (7, 2), (8, 2),  // Top
            (7, 13), (8, 13), // Bottom
            (2, 7), (2, 8),  // Left
            (13, 7), (13, 8), // Right
            (4, 4), // Top-left
            (11, 4), // Top-right
            (4, 11), // Bottom-left
            (11, 11) // Bottom-right
        ]

        // Orange inner glow
        let innerGlow: [(Int, Int)] = [
            (7, 6), (8, 6),
            (6, 7), (7, 7), (8, 7), (9, 7),
            (6, 8), (7, 8), (8, 8), (9, 8),
            (7, 9), (8, 9)
        ]

        var elements: [String] = []
        elements.append(pixels(sunCenter, color: PixelPalette.sunYellow, startX: startX, startY: startY, pixelSize: pixelSize))
        elements.append(pixels(innerGlow, color: PixelPalette.sunOrange, startX: startX, startY: startY, pixelSize: pixelSize))
        elements.append(pixels(rays, color: PixelPalette.sunYellow, startX: startX, startY: startY, pixelSize: pixelSize))

        return elements.joined(separator: "\n")
    }

    // MARK: - Moon (16x16)

    private static func renderPixelMoon(startX: Double, startY: Double, pixelSize: Double) -> String {
        // Crescent moon shape
        let moonOuter: [(Int, Int)] = [
            (8, 3), (9, 3), (10, 3),
            (7, 4), (8, 4), (9, 4), (10, 4), (11, 4),
            (6, 5), (7, 5), (8, 5), (11, 5),
            (6, 6), (7, 6), (11, 6),
            (5, 7), (6, 7), (11, 7),
            (5, 8), (6, 8), (11, 8),
            (5, 9), (6, 9), (11, 9),
            (6, 10), (7, 10), (11, 10),
            (6, 11), (7, 11), (8, 11), (10, 11), (11, 11),
            (7, 12), (8, 12), (9, 12), (10, 12)
        ]

        // Stars
        let stars: [(Int, Int)] = [
            (3, 4), (12, 6), (2, 9), (4, 13)
        ]

        var elements: [String] = []
        elements.append(pixels(moonOuter, color: PixelPalette.moonWhite, startX: startX, startY: startY, pixelSize: pixelSize))
        elements.append(pixels(stars, color: PixelPalette.starYellow, startX: startX, startY: startY, pixelSize: pixelSize))

        return elements.joined(separator: "\n")
    }

    // MARK: - Cloud (16x16)

    private static func renderPixelCloud(startX: Double, startY: Double, pixelSize: Double, dark: Bool) -> String {
        let mainColor = dark ? PixelPalette.cloudGray : PixelPalette.cloudWhite
        let shadowColor = dark ? PixelPalette.cloudDark : PixelPalette.cloudLight

        let cloudTop: [(Int, Int)] = [
            (5, 4), (6, 4), (7, 4),
            (4, 5), (5, 5), (6, 5), (7, 5), (8, 5), (9, 5), (10, 5),
            (3, 6), (4, 6), (5, 6), (6, 6), (7, 6), (8, 6), (9, 6), (10, 6), (11, 6),
            (2, 7), (3, 7), (4, 7), (5, 7), (6, 7), (7, 7), (8, 7), (9, 7), (10, 7), (11, 7), (12, 7)
        ]

        let cloudBottom: [(Int, Int)] = [
            (2, 8), (3, 8), (4, 8), (5, 8), (6, 8), (7, 8), (8, 8), (9, 8), (10, 8), (11, 8), (12, 8),
            (3, 9), (4, 9), (5, 9), (6, 9), (7, 9), (8, 9), (9, 9), (10, 9), (11, 9)
        ]

        var elements: [String] = []
        elements.append(pixels(cloudTop, color: mainColor, startX: startX, startY: startY, pixelSize: pixelSize))
        elements.append(pixels(cloudBottom, color: shadowColor, startX: startX, startY: startY, pixelSize: pixelSize))

        return elements.joined(separator: "\n")
    }

    // MARK: - Sun + Cloud

    private static func renderPixelSunCloud(startX: Double, startY: Double, pixelSize: Double) -> String {
        // Mini sun (top-left)
        let sunPixels: [(Int, Int)] = [
            (3, 2), (4, 2),
            (2, 3), (3, 3), (4, 3), (5, 3),
            (2, 4), (3, 4), (4, 4), (5, 4),
            (3, 5), (4, 5)
        ]
        let rays: [(Int, Int)] = [(3, 0), (0, 3), (6, 3), (3, 6)]

        // Cloud (center-right, overlapping)
        let cloudPixels: [(Int, Int)] = [
            (7, 5), (8, 5), (9, 5),
            (6, 6), (7, 6), (8, 6), (9, 6), (10, 6), (11, 6),
            (5, 7), (6, 7), (7, 7), (8, 7), (9, 7), (10, 7), (11, 7), (12, 7),
            (5, 8), (6, 8), (7, 8), (8, 8), (9, 8), (10, 8), (11, 8), (12, 8),
            (6, 9), (7, 9), (8, 9), (9, 9), (10, 9), (11, 9)
        ]

        var elements: [String] = []
        elements.append(pixels(sunPixels, color: PixelPalette.sunYellow, startX: startX, startY: startY, pixelSize: pixelSize))
        elements.append(pixels(rays, color: PixelPalette.sunYellow, startX: startX, startY: startY, pixelSize: pixelSize))
        elements.append(pixels(cloudPixels, color: PixelPalette.cloudWhite, startX: startX, startY: startY, pixelSize: pixelSize))

        return elements.joined(separator: "\n")
    }

    // MARK: - Moon + Cloud

    private static func renderPixelMoonCloud(startX: Double, startY: Double, pixelSize: Double) -> String {
        // Mini moon (top-left)
        let moonPixels: [(Int, Int)] = [
            (3, 2), (4, 2),
            (2, 3), (3, 3), (5, 3),
            (2, 4), (5, 4),
            (2, 5), (3, 5), (4, 5), (5, 5),
            (3, 6), (4, 6)
        ]
        let stars: [(Int, Int)] = [(0, 4), (6, 2)]

        // Cloud (center-right)
        let cloudPixels: [(Int, Int)] = [
            (7, 5), (8, 5), (9, 5),
            (6, 6), (7, 6), (8, 6), (9, 6), (10, 6), (11, 6),
            (5, 7), (6, 7), (7, 7), (8, 7), (9, 7), (10, 7), (11, 7), (12, 7),
            (5, 8), (6, 8), (7, 8), (8, 8), (9, 8), (10, 8), (11, 8), (12, 8),
            (6, 9), (7, 9), (8, 9), (9, 9), (10, 9), (11, 9)
        ]

        var elements: [String] = []
        elements.append(pixels(moonPixels, color: PixelPalette.moonWhite, startX: startX, startY: startY, pixelSize: pixelSize))
        elements.append(pixels(stars, color: PixelPalette.starYellow, startX: startX, startY: startY, pixelSize: pixelSize))
        elements.append(pixels(cloudPixels, color: PixelPalette.cloudGray, startX: startX, startY: startY, pixelSize: pixelSize))

        return elements.joined(separator: "\n")
    }

    // MARK: - Rain

    private static func renderPixelRain(startX: Double, startY: Double, pixelSize: Double, heavy: Bool) -> String {
        var elements: [String] = []

        // Cloud
        elements.append(renderPixelCloud(startX: startX, startY: startY - pixelSize * 2, pixelSize: pixelSize, dark: true))

        // Rain drops
        let lightDrops: [(Int, Int)] = [(4, 11), (7, 12), (10, 11)]
        let heavyDrops: [(Int, Int)] = [(4, 11), (6, 13), (7, 11), (9, 12), (11, 11), (5, 14), (8, 14)]

        let drops = heavy ? heavyDrops : lightDrops
        elements.append(pixels(drops, color: PixelPalette.rainBlue, startX: startX, startY: startY, pixelSize: pixelSize))

        return elements.joined(separator: "\n")
    }

    // MARK: - Snow

    private static func renderPixelSnow(startX: Double, startY: Double, pixelSize: Double) -> String {
        var elements: [String] = []

        // Cloud
        elements.append(renderPixelCloud(startX: startX, startY: startY - pixelSize * 2, pixelSize: pixelSize, dark: false))

        // Snowflakes (asterisk pattern)
        let flakes: [(Int, Int)] = [
            (4, 11), (7, 12), (10, 11), (5, 14), (9, 13), (12, 14)
        ]
        elements.append(pixels(flakes, color: PixelPalette.snowWhite, startX: startX, startY: startY, pixelSize: pixelSize))

        return elements.joined(separator: "\n")
    }

    // MARK: - Thunderstorm

    private static func renderPixelThunderstorm(startX: Double, startY: Double, pixelSize: Double) -> String {
        var elements: [String] = []

        // Dark cloud
        elements.append(renderPixelCloud(startX: startX, startY: startY - pixelSize * 2, pixelSize: pixelSize, dark: true))

        // Lightning bolt
        let bolt: [(Int, Int)] = [
            (8, 9), (7, 10), (8, 10), (6, 11), (7, 11), (8, 11), (9, 11),
            (7, 12), (8, 12), (6, 13), (7, 13)
        ]
        elements.append(pixels(bolt, color: PixelPalette.lightning, startX: startX, startY: startY, pixelSize: pixelSize))

        return elements.joined(separator: "\n")
    }

    // MARK: - Fog

    private static func renderPixelFog(startX: Double, startY: Double, pixelSize: Double) -> String {
        // Horizontal lines
        let lines: [(Int, Int)] = [
            // Line 1
            (3, 4), (4, 4), (5, 4), (6, 4), (7, 4), (8, 4), (9, 4), (10, 4), (11, 4),
            // Line 2
            (2, 6), (3, 6), (4, 6), (5, 6), (6, 6), (7, 6), (8, 6), (9, 6), (10, 6), (11, 6), (12, 6),
            // Line 3
            (4, 8), (5, 8), (6, 8), (7, 8), (8, 8), (9, 8), (10, 8),
            // Line 4
            (3, 10), (4, 10), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10), (10, 10), (11, 10)
        ]

        return pixels(lines, color: PixelPalette.fogGray, startX: startX, startY: startY, pixelSize: pixelSize)
    }

    // MARK: - Freezing Rain

    private static func renderPixelFreezingRain(startX: Double, startY: Double, pixelSize: Double) -> String {
        var elements: [String] = []

        // Light blue cloud
        let cloudPixels: [(Int, Int)] = [
            (5, 4), (6, 4), (7, 4),
            (4, 5), (5, 5), (6, 5), (7, 5), (8, 5), (9, 5), (10, 5),
            (3, 6), (4, 6), (5, 6), (6, 6), (7, 6), (8, 6), (9, 6), (10, 6), (11, 6),
            (2, 7), (3, 7), (4, 7), (5, 7), (6, 7), (7, 7), (8, 7), (9, 7), (10, 7), (11, 7), (12, 7),
            (3, 8), (4, 8), (5, 8), (6, 8), (7, 8), (8, 8), (9, 8), (10, 8), (11, 8)
        ]
        elements.append(pixels(cloudPixels, color: "#B0D4E8", startX: startX, startY: startY, pixelSize: pixelSize))

        // Ice drops
        let drops: [(Int, Int)] = [(4, 10), (7, 11), (10, 10), (6, 13), (9, 12)]
        elements.append(pixels(drops, color: "#80C0E0", startX: startX, startY: startY, pixelSize: pixelSize))

        return elements.joined(separator: "\n")
    }

    // MARK: - Sleet

    private static func renderPixelSleet(startX: Double, startY: Double, pixelSize: Double) -> String {
        var elements: [String] = []

        // Cloud
        elements.append(renderPixelCloud(startX: startX, startY: startY - pixelSize * 2, pixelSize: pixelSize, dark: true))

        // Mix of rain and snow
        let rainDrops: [(Int, Int)] = [(4, 11), (8, 11), (11, 12)]
        let snowFlakes: [(Int, Int)] = [(6, 12), (9, 13), (5, 14)]

        elements.append(pixels(rainDrops, color: PixelPalette.rainBlue, startX: startX, startY: startY, pixelSize: pixelSize))
        elements.append(pixels(snowFlakes, color: PixelPalette.snowWhite, startX: startX, startY: startY, pixelSize: pixelSize))

        return elements.joined(separator: "\n")
    }
}
