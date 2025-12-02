import Foundation

/// A temperature value with unit conversion support.
public struct Temperature: Codable, Sendable, Equatable, Hashable {
    /// The temperature value in Celsius (canonical storage).
    public let celsius: Double

    /// The temperature value in Fahrenheit.
    public var fahrenheit: Double {
        celsius * 9.0 / 5.0 + 32.0
    }

    /// The temperature value in Kelvin.
    public var kelvin: Double {
        celsius + 273.15
    }

    /// Creates a temperature from a Celsius value.
    /// - Parameter celsius: The temperature in Celsius.
    public init(celsius: Double) {
        self.celsius = celsius
    }

    /// Creates a temperature from a Fahrenheit value.
    /// - Parameter fahrenheit: The temperature in Fahrenheit.
    /// - Returns: A new `Temperature` instance.
    public static func fahrenheit(_ fahrenheit: Double) -> Temperature {
        Temperature(celsius: (fahrenheit - 32.0) * 5.0 / 9.0)
    }

    /// Creates a temperature from a Kelvin value.
    /// - Parameter kelvin: The temperature in Kelvin.
    /// - Returns: A new `Temperature` instance.
    public static func kelvin(_ kelvin: Double) -> Temperature {
        Temperature(celsius: kelvin - 273.15)
    }

    /// Returns a formatted string representation of the temperature.
    /// - Parameters:
    ///   - unit: The temperature unit to display. Defaults to `.fahrenheit`.
    ///   - decimalPlaces: The number of decimal places. Defaults to 0.
    /// - Returns: A formatted temperature string (e.g., "72°F").
    public func formatted(unit: TemperatureUnit = .fahrenheit, decimalPlaces: Int = 0) -> String {
        let value: Double
        switch unit {
        case .celsius:
            value = celsius
        case .fahrenheit:
            value = fahrenheit
        }
        return String(format: "%.\(decimalPlaces)f°\(unit.symbol)", value)
    }
}

/// Temperature unit for display.
public enum TemperatureUnit: String, Codable, Sendable, CaseIterable {
    case celsius
    case fahrenheit

    /// The symbol for this unit.
    public var symbol: String {
        switch self {
        case .celsius: return "C"
        case .fahrenheit: return "F"
        }
    }
}
