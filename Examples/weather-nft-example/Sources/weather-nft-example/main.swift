import Foundation
import Weather
import SVG

/// Weather NFT Example CLI
///
/// Demonstrates fetching weather data and creating/updating ARC-19 NFTs
/// with dynamic weather metadata.
///
/// Usage:
///   weather-nft-example fetch <location>     - Fetch current weather
///   weather-nft-example mint <location>      - Mint a new Weather NFT
///   weather-nft-example update <asset-id>    - Update an existing NFT
///
/// Environment Variables:
///   WEATHER_USER_AGENT  - User-Agent for NWS API
///   PINATA_JWT          - Pinata JWT token
///   PINATA_GATEWAY      - Pinata gateway domain (optional)
///   ALGOD_URL           - Algorand node URL
///   ALGOD_TOKEN         - Algorand node token (optional)
///   ACCOUNT_MNEMONIC    - Account mnemonic for signing

// MARK: - Main Entry Point

let args = CommandLine.arguments.dropFirst()

if let command = args.first {
    Task {
        do {
            switch command {
            case "fetch":
                try await handleFetch(Array(args.dropFirst()))
            case "mint":
                try await handleMint(Array(args.dropFirst()))
            case "update":
                try await handleUpdate(Array(args.dropFirst()))
            case "svg":
                try await handleSVG(Array(args.dropFirst()))
            case "gallery":
                try await handleGallery(Array(args.dropFirst()))
            case "demo":
                try await handleDemo()
            case "help", "--help", "-h":
                printUsage()
            default:
                print("Unknown command: \(command)")
                printUsage()
            }
        } catch {
            print("Error: \(error)")
        }
        exit(0)
    }
    RunLoop.main.run()
} else {
    printUsage()
}

// MARK: - Commands

func handleFetch(_ args: [String]) async throws {
    guard !args.isEmpty else {
        print("Usage: weather-nft-example fetch <location>")
        print("Example: weather-nft-example fetch \"Seattle, WA\"")
        return
    }

    let locationString = args.joined(separator: " ")
    let location = parseLocation(locationString)

    print("Fetching weather for: \(locationString)")
    print()

    let weather = Weather(userAgent: Config.weatherUserAgent)
    let current = try await weather.current(at: location)

    printWeather(current)
}

func handleMint(_ args: [String]) async throws {
    guard !args.isEmpty else {
        print("Usage: weather-nft-example mint <location>")
        print("Example: weather-nft-example mint \"Seattle, WA\"")
        return
    }

    // Validate configuration
    guard !Config.pinataJWT.isEmpty else {
        print("Error: PINATA_JWT environment variable is required")
        return
    }
    guard !Config.accountMnemonic.isEmpty else {
        print("Error: ACCOUNT_MNEMONIC environment variable is required")
        return
    }

    let locationString = args.joined(separator: " ")
    let location = parseLocation(locationString)

    print("Creating Weather NFT for: \(locationString)")
    print()

    let weatherNFT = try WeatherNFT(
        location: location,
        userAgent: Config.weatherUserAgent,
        pinataJWT: Config.pinataJWT,
        pinataGateway: Config.pinataGateway,
        algodURL: Config.algodURL,
        algodToken: Config.algodToken,
        mnemonic: Config.accountMnemonic
    )

    let assetID = try await weatherNFT.mint()

    print()
    print("Success! Asset ID: \(assetID)")
    print()
    print("View on explorer:")
    print("  https://testnet.explorer.perawallet.app/asset/\(assetID)")
}

func handleUpdate(_ args: [String]) async throws {
    guard let assetIDString = args.first,
          let assetID = UInt64(assetIDString) else {
        print("Usage: weather-nft-example update <asset-id> [location]")
        print("Example: weather-nft-example update 123456789 \"Seattle, WA\"")
        return
    }

    // Validate configuration
    guard !Config.pinataJWT.isEmpty else {
        print("Error: PINATA_JWT environment variable is required")
        return
    }
    guard !Config.accountMnemonic.isEmpty else {
        print("Error: ACCOUNT_MNEMONIC environment variable is required")
        return
    }

    // Use provided location or default
    let locationString = args.dropFirst().joined(separator: " ")
    let location: Location = locationString.isEmpty
        ? .city("Seattle, WA")
        : parseLocation(locationString)

    print("Updating Weather NFT \(assetID)")
    print()

    let weatherNFT = try WeatherNFT(
        assetID: assetID,
        location: location,
        userAgent: Config.weatherUserAgent,
        pinataJWT: Config.pinataJWT,
        pinataGateway: Config.pinataGateway,
        algodURL: Config.algodURL,
        algodToken: Config.algodToken,
        mnemonic: Config.accountMnemonic
    )

    let txID = try await weatherNFT.update()

    print()
    print("Success! Transaction: \(txID)")
}

func handleDemo() async throws {
    print("Weather NFT Demo")
    print("================")
    print()
    print("This demo shows how the Weather package fetches data from")
    print("multiple providers (NWS for US, Open-Meteo for international).")
    print()

    let weather = Weather(userAgent: Config.weatherUserAgent)

    // US location (uses NWS) - using coordinates for reliable results
    print("US Location (Seattle) - Uses NWS API:")
    print(String(repeating: "-", count: 40))
    let seattle = try await weather.current(latitude: 47.6062, longitude: -122.3321)
    printWeather(seattle)

    print()

    // International location (uses Open-Meteo) - using coordinates
    print("International (Tokyo) - Uses Open-Meteo:")
    print(String(repeating: "-", count: 40))
    let tokyo = try await weather.current(latitude: 35.6762, longitude: 139.6503)
    printWeather(tokyo)

    print()
    print("To mint an NFT, set environment variables and run:")
    print("  weather-nft-example mint \"47.6062,-122.3321\"")
}

func handleSVG(_ args: [String]) async throws {
    // Parse arguments
    var outputPath: String?
    var locationParts: [String] = []

    var i = 0
    while i < args.count {
        let arg = args[i]
        if arg == "-o" || arg == "--output" {
            if i + 1 < args.count {
                outputPath = args[i + 1]
                i += 2
                continue
            }
        } else if !arg.hasPrefix("-") {
            locationParts.append(arg)
        }
        i += 1
    }

    // Parse location (default to Seattle)
    let locationString = locationParts.isEmpty ? "47.6062,-122.3321" : locationParts.joined(separator: " ")
    let location = parseLocation(locationString)

    print("Generating pixel art SVG for: \(locationString)")
    print()

    // Fetch weather
    let weather = Weather(userAgent: Config.weatherUserAgent)
    let current = try await weather.current(at: location)

    printWeather(current)
    print()

    // Generate SVG
    let svg = WeatherSVGGenerator.generate(from: current)

    if let path = outputPath {
        // Write to file
        let url = URL(fileURLWithPath: path)
        try svg.write(to: url, atomically: true, encoding: .utf8)
        print("SVG written to: \(path)")
        print()
        print("Open in browser or image viewer to preview.")
    } else {
        // Print to stdout
        print("Generated SVG (\(svg.count) bytes):")
        print(String(repeating: "-", count: 40))
        print(svg)
        print(String(repeating: "-", count: 40))
        print()
        print("Tip: Use -o <file.svg> to save to a file")
    }
}

func handleGallery(_ args: [String]) async throws {
    // Parse output directory
    var outputDir = "/tmp/weather-gallery"

    var i = 0
    while i < args.count {
        let arg = args[i]
        if arg == "-o" || arg == "--output" {
            if i + 1 < args.count {
                outputDir = args[i + 1]
                i += 2
                continue
            }
        }
        i += 1
    }

    print("Generating Weather Gallery")
    print("==========================")
    print()
    print("Output directory: \(outputDir)")
    print()

    // Create output directories
    let fileManager = FileManager.default
    let byConditionDir = "\(outputDir)/by-condition"
    let byHourDir = "\(outputDir)/by-hour"
    try fileManager.createDirectory(atPath: byConditionDir, withIntermediateDirectories: true)
    try fileManager.createDirectory(atPath: byHourDir, withIntermediateDirectories: true)

    // All weather conditions
    let conditions: [WeatherCondition] = [
        .clear, .partlyCloudy, .cloudy, .fog, .drizzle,
        .rain, .freezingRain, .snow, .sleet, .thunderstorm, .unknown
    ]

    // Generate 24 hours for each condition
    var generated = 0
    let calendar = Calendar.current
    let baseDate = calendar.startOfDay(for: Date())

    for condition in conditions {
        let conditionDir = "\(byConditionDir)/\(condition)"
        try fileManager.createDirectory(atPath: conditionDir, withIntermediateDirectories: true)

        for hour in 0..<24 {
            let isDaytime = hour >= 6 && hour < 18  // Simple 6am-6pm rule
            let hourString = String(format: "%02d-00", hour)
            let observationTime = calendar.date(byAdding: .hour, value: hour, to: baseDate)!

            // Create mock weather for this condition and hour
            let weather = MockWeather.create(
                condition: condition,
                isDaytime: isDaytime,
                observationTime: observationTime
            )

            // Generate SVG
            let svg = WeatherSVGGenerator.generate(from: weather)

            // Write to by-condition directory
            let conditionFilepath = "\(conditionDir)/\(hourString).svg"
            try svg.write(to: URL(fileURLWithPath: conditionFilepath), atomically: true, encoding: .utf8)

            // Also write to by-hour directory
            let hourDir = "\(byHourDir)/\(hourString)"
            try fileManager.createDirectory(atPath: hourDir, withIntermediateDirectories: true)
            let hourFilepath = "\(hourDir)/\(condition).svg"
            try svg.write(to: URL(fileURLWithPath: hourFilepath), atomically: true, encoding: .utf8)

            generated += 1
        }
        print("  ✓ \(condition) (24 hours)")
    }

    // Generate HTML index
    let indexPath = "\(outputDir)/index.html"
    let htmlContent = generateGalleryHTML(conditions: conditions)
    try htmlContent.write(to: URL(fileURLWithPath: indexPath), atomically: true, encoding: .utf8)

    print()
    print("Generated \(generated) SVG files + index.html")
    print()
    print("Open gallery in browser:")
    print("  open \(outputDir)/index.html")
}

/// Generates HTML gallery index.
func generateGalleryHTML(conditions: [WeatherCondition]) -> String {
    var conditionCards = ""
    for condition in conditions {
        var hourImages = ""
        for hour in 0..<24 {
            let hourString = String(format: "%02d-00", hour)
            let isDaytime = hour >= 6 && hour < 18
            let bgClass = isDaytime ? "day" : "night"
            hourImages += """
                        <div class="hour \(bgClass)">
                            <img src="by-condition/\(condition)/\(hourString).svg" alt="\(condition) at \(hourString)">
                            <span>\(hourString)</span>
                        </div>

            """
        }

        conditionCards += """
                <div class="condition-card">
                    <h2>\(condition)</h2>
                    <div class="hours-grid">
        \(hourImages)            </div>
                </div>

        """
    }

    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Weather SVG Gallery</title>
        <style>
            * { box-sizing: border-box; margin: 0; padding: 0; }
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background: #1a1a2e;
                color: #fff;
                padding: 2rem;
            }
            h1 {
                text-align: center;
                margin-bottom: 2rem;
                font-size: 2rem;
            }
            .stats {
                text-align: center;
                margin-bottom: 2rem;
                color: #888;
            }
            .condition-card {
                background: #2a2a4a;
                border-radius: 12px;
                padding: 1.5rem;
                margin-bottom: 2rem;
            }
            .condition-card h2 {
                margin-bottom: 1rem;
                text-transform: capitalize;
            }
            .hours-grid {
                display: grid;
                grid-template-columns: repeat(auto-fill, minmax(100px, 1fr));
                gap: 0.5rem;
            }
            .hour {
                text-align: center;
                padding: 0.25rem;
                border-radius: 4px;
            }
            .hour.day { background: rgba(135, 206, 235, 0.2); }
            .hour.night { background: rgba(26, 26, 46, 0.5); }
            .hour img {
                width: 100%;
                height: auto;
                border-radius: 4px;
            }
            .hour span {
                display: block;
                font-size: 0.75rem;
                color: #888;
                margin-top: 0.25rem;
            }
        </style>
    </head>
    <body>
        <h1>Weather SVG Gallery</h1>
        <p class="stats">11 conditions × 24 hours = 264 images</p>
        <p class="stats">Day: 6:00-17:59 | Night: 18:00-5:59</p>
    \(conditionCards)
    </body>
    </html>
    """
}

// MARK: - Mock Weather

/// Creates mock weather data for gallery generation.
enum MockWeather {
    static func create(
        condition: WeatherCondition,
        isDaytime: Bool,
        temperature: Double = 72.0,
        humidity: Double = 45.0,
        windSpeed: Double = 12.0,
        observationTime: Date = Date()
    ) -> CurrentWeather {
        // Adjust temperature based on condition for realism
        let adjustedTemp: Double
        switch condition {
        case .snow, .sleet, .freezingRain:
            adjustedTemp = isDaytime ? 28.0 : 22.0
        case .thunderstorm, .rain:
            adjustedTemp = isDaytime ? 65.0 : 58.0
        case .clear:
            adjustedTemp = isDaytime ? 78.0 : 62.0
        case .fog:
            adjustedTemp = isDaytime ? 55.0 : 48.0
        default:
            adjustedTemp = isDaytime ? 68.0 : 55.0
        }

        return CurrentWeather(
            temperature: .fahrenheit(adjustedTemp),
            condition: condition,
            conditionDescription: conditionDescription(for: condition),
            humidity: humidity,
            windSpeed: windSpeed,
            isDaytime: isDaytime,
            location: ResolvedLocation(
                latitude: 47.6062,
                longitude: -122.3321,
                name: "Seattle"
            ),
            observationTime: observationTime,
            provider: .openMeteo
        )
    }

    private static func conditionDescription(for condition: WeatherCondition) -> String {
        switch condition {
        case .clear: return "Clear"
        case .partlyCloudy: return "Partly Cloudy"
        case .cloudy: return "Cloudy"
        case .fog: return "Foggy"
        case .drizzle: return "Drizzle"
        case .rain: return "Rainy"
        case .freezingRain: return "Freezing Rain"
        case .snow: return "Snowy"
        case .sleet: return "Sleet"
        case .thunderstorm: return "Thunderstorm"
        case .unknown: return "Unknown"
        }
    }
}

// MARK: - Helpers

func parseLocation(_ string: String) -> Location {
    // Check for coordinate format: "lat,lon"
    let parts = string.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    if parts.count == 2,
       let lat = Double(parts[0]),
       let lon = Double(parts[1]) {
        return .coordinates(latitude: lat, longitude: lon)
    }

    return .city(string)
}

func printWeather(_ weather: CurrentWeather) {
    let name = weather.location.name ?? "\(weather.location.latitude), \(weather.location.longitude)"

    print("Location:    \(name)")
    print("Provider:    \(weather.provider.name)")
    print("Temperature: \(String(format: "%.1f", weather.temperature.fahrenheit))°F (\(String(format: "%.1f", weather.temperature.celsius))°C)")
    print("Condition:   \(weather.conditionDescription)")

    if let humidity = weather.humidity {
        print("Humidity:    \(Int(humidity))%")
    }

    if let windSpeed = weather.windSpeed {
        print("Wind:        \(Int(windSpeed)) km/h")
    }

    print("Daytime:     \(weather.isDaytime ? "Yes" : "No")")
    print("Observed:    \(weather.observationTime)")
}

func printUsage() {
    print("""
    Weather NFT Example
    ===================

    A proof-of-concept for dynamic ARC-19 NFTs with retro pixel-art weather images.

    Commands:
      fetch <location>           Fetch current weather
      svg [options] [location]   Generate SVG weather image
      gallery [options]          Generate all condition/time variants
      mint <location>            Mint a new Weather NFT
      update <asset-id> [loc]    Update an existing NFT
      demo                       Run a demo showing both providers
      help                       Show this help

    SVG Options:
      -o, --output <file>        Save SVG to file

    Gallery Options:
      -o, --output <dir>         Output directory (default: /tmp/weather-gallery)

    Location Formats:
      "Seattle, WA"              City name with state/country
      "47.6,-122.3"              Latitude,longitude coordinates

    Environment Variables:
      WEATHER_USER_AGENT         User-Agent for NWS API (optional)
      PINATA_JWT                 Pinata JWT token (required for mint/update)
      PINATA_GATEWAY             Pinata gateway domain (optional)
      ALGOD_URL                  Algorand node URL (default: testnet)
      ALGOD_TOKEN                Algorand node token (optional)
      ACCOUNT_MNEMONIC           Account mnemonic (required for mint/update)

    Examples:
      weather-nft-example fetch "Seattle, WA"
      weather-nft-example svg -o weather.svg
      weather-nft-example svg "35.6762,139.6503" -o tokyo.svg
      weather-nft-example gallery
      weather-nft-example gallery -o ./my-gallery
      weather-nft-example demo
      weather-nft-example mint "Seattle, WA"
    """)
}
