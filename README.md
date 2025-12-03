# SwiftWeather

[![macOS](https://img.shields.io/github/actions/workflow/status/CorvidLabs/swift-weather/macOS.yml?label=macOS&branch=main)](https://github.com/CorvidLabs/swift-weather/actions/workflows/macOS.yml)
[![Ubuntu](https://img.shields.io/github/actions/workflow/status/CorvidLabs/swift-weather/ubuntu.yml?label=Ubuntu&branch=main)](https://github.com/CorvidLabs/swift-weather/actions/workflows/ubuntu.yml)
[![License](https://img.shields.io/github/license/CorvidLabs/swift-weather)](https://github.com/CorvidLabs/swift-weather/blob/main/LICENSE)
[![Version](https://img.shields.io/github/v/release/CorvidLabs/swift-weather)](https://github.com/CorvidLabs/swift-weather/releases)

A Swift library for fetching weather data from multiple providers.

## Features

- **Multiple Providers** - NWS (US) and Open-Meteo (international)
- **Automatic Selection** - Uses best provider based on location
- **Swift 6 Concurrency** - Full async/await support
- **Cross-Platform** - iOS, macOS, tvOS, watchOS, visionOS

## Installation

Add SwiftWeather as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/CorvidLabs/swift-weather.git", from: "0.1.0")
]
```

Then add the target dependency:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Weather", package: "swift-weather")
    ]
)
```

## Quick Start

```swift
import Weather

let config = WeatherConfiguration(
    userAgent: "(MyApp, contact@example.com)"
)
let weather = Weather(configuration: config)

let current = try await weather.current(
    latitude: 47.6062,
    longitude: -122.3321
)

print("Temperature: \(current.temperature.fahrenheit)°F")
print("Condition: \(current.conditionDescription)")
```

## Configuration

```swift
// US locations (uses NWS with Open-Meteo fallback)
let usConfig = WeatherConfiguration.us(userAgent: "(MyApp, email@example.com)")

// International locations (uses Open-Meteo only)
let intlConfig = WeatherConfiguration.international(userAgent: "(MyApp, email@example.com)")

// Custom configuration
let config = WeatherConfiguration(
    userAgent: "(MyApp, email@example.com)",
    temperatureUnit: .celsius,
    providerStrategy: .automatic
)
```

## Weather Conditions

The library supports these weather conditions:

- `clear` - Clear skies
- `partlyCloudy` - Partly cloudy
- `cloudy` - Overcast
- `fog` - Foggy conditions
- `drizzle` - Light rain
- `rain` - Rain
- `freezingRain` - Freezing rain
- `snow` - Snow
- `sleet` - Sleet/ice pellets
- `thunderstorm` - Thunderstorms
- `unknown` - Unknown condition

## Examples

See `Examples/` for complete sample applications:

- **weather-nft-example** - Generate SVG weather images for NFTs
- **weather-tui-demo** - Interactive terminal weather dashboard

## License

MIT License - see [LICENSE](LICENSE) for details.
