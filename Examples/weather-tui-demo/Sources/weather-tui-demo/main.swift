import CLI
import Weather
import ASCIIPixelArt
import Foundation

// MARK: - Locations

struct DemoLocation: Sendable {
    let name: String
    let latitude: Double
    let longitude: Double
}

let locations: [DemoLocation] = [
    DemoLocation(name: "Seattle, WA", latitude: 47.6062, longitude: -122.3321),
    DemoLocation(name: "New York, NY", latitude: 40.7128, longitude: -74.0060),
    DemoLocation(name: "London, UK", latitude: 51.5074, longitude: -0.1278),
    DemoLocation(name: "Tokyo, Japan", latitude: 35.6762, longitude: 139.6503)
]

// MARK: - Weather App

@main
struct WeatherTUIDemo {
    static func main() async throws {
        try await runApp(WeatherDashboardApp())
    }
}

/// Main weather dashboard TUI app
final class WeatherDashboardApp: App, @unchecked Sendable {
    enum LoadState: Sendable {
        case loading
        case loaded(CurrentWeather)
        case error(String)
    }

    // State
    private var loadState: LoadState = .loading
    private var locationIndex: Int = 0
    private var lastUpdate: String = ""

    init() {}

    var updateInterval: TimeInterval {
        if case .loading = loadState { return 0.1 }
        return 60.0  // Refresh every minute
    }

    var body: some View {
        VStack {
            // Title bar
            Text("  Weather Dashboard  ").bold()
                .border(.heavy, color: .cyan)

            // Main content
            contentView

            // Footer
            footerView
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch loadState {
        case .loading:
            VStack {
                SpinnerView(style: .dots, message: "Fetching weather data...")
            }
            .padding(2)
            .border(.rounded)

        case .loaded(let weather):
            VStack {
                // Weather icon (ASCII art)
                iconView(for: weather)

                // Condition description
                Text("  \(weather.conditionDescription)  ").bold()

                // Stats grid
                statsView(for: weather)

                // Location and time
                locationView(for: weather)
            }

        case .error(let message):
            VStack {
                Text("  Error  ").bold().red
                Text("  \(message)  ").dim()
                Text("  Press 'r' to retry  ").dim()
            }
            .padding(2)
            .border(.rounded, color: .red)
        }
    }

    @ViewBuilder
    private func iconView(for weather: CurrentWeather) -> some View {
        let icon = asciiIcon(for: weather.condition, isDaytime: weather.isDaytime)
        let color = iconColor(for: weather.condition, isDaytime: weather.isDaytime)

        VStack {
            ForEach(0..<icon.count) { i in
                switch color {
                case "yellow":
                    Text("  \(icon[i])  ").yellow
                case "cyan":
                    Text("  \(icon[i])  ").cyan
                case "white":
                    Text("  \(icon[i])  ").bold()
                case "blue":
                    Text("  \(icon[i])  ").blue
                case "gray":
                    Text("  \(icon[i])  ").dim()
                default:
                    Text("  \(icon[i])  ")
                }
            }
        }
        .padding(1)
    }

    @ViewBuilder
    private func statsView(for weather: CurrentWeather) -> some View {
        HStack(spacing: 1) {
            // Temperature
            VStack {
                Text("  TEMP  ").dim()
                Text("  \(Int(weather.temperature.fahrenheit))°F  ").bold()
            }
            .padding(1)
            .border(.rounded)

            // Humidity
            VStack {
                Text("  HUMIDITY  ").dim()
                if let humidity = weather.humidity {
                    Text("  \(Int(humidity))%  ").bold()
                } else {
                    Text("  --  ").dim()
                }
            }
            .padding(1)
            .border(.rounded)

            // Wind
            VStack {
                Text("  WIND  ").dim()
                if let wind = weather.windSpeed {
                    Text("  \(Int(wind)) km/h  ").bold()
                } else {
                    Text("  --  ").dim()
                }
            }
            .padding(1)
            .border(.rounded)
        }
    }

    @ViewBuilder
    private func locationView(for weather: CurrentWeather) -> some View {
        let loc = locations[locationIndex]
        Text("  \(loc.name)  ").cyan
        Text("  \(formatTime(weather.observationTime))  ").dim()
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }

    private var footerView: some View {
        VStack {
            Text("  [\(locationIndex + 1)/\(locations.count)] \(locations[locationIndex].name)  ").dim()
            Text("  [R] Refresh  [<-/->] Location  [Q] Quit  ").dim()
        }
    }

    func onAppear() async {
        Task {
            await fetchWeather()
        }
    }

    func onKeyPress(_ key: KeyCode) async -> Bool {
        switch key {
        case .arrow(.left):
            locationIndex = (locationIndex - 1 + locations.count) % locations.count
            await fetchWeather()
            return true
        case .arrow(.right):
            locationIndex = (locationIndex + 1) % locations.count
            await fetchWeather()
            return true
        case .character("r"), .character("R"):
            await fetchWeather()
            return true
        default:
            return false
        }
    }

    private func fetchWeather() async {
        loadState = .loading

        let loc = locations[locationIndex]
        let config = WeatherConfiguration(
            userAgent: "(WeatherTUIDemo, demo@corvidlabs.com)"
        )
        let weather = Weather(configuration: config)

        do {
            let current = try await weather.current(
                latitude: loc.latitude,
                longitude: loc.longitude
            )
            loadState = .loaded(current)

            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            lastUpdate = formatter.string(from: Date())
        } catch {
            loadState = .error(error.localizedDescription)
        }
    }

    // MARK: - ASCII Icons

    private func asciiIcon(for condition: WeatherCondition, isDaytime: Bool) -> [String] {
        switch condition {
        case .clear:
            return isDaytime ? sunIcon : moonIcon
        case .partlyCloudy:
            return isDaytime ? sunCloudIcon : moonCloudIcon
        case .cloudy:
            return cloudIcon
        case .fog:
            return fogIcon
        case .drizzle, .rain:
            return rainIcon
        case .freezingRain:
            return rainIcon
        case .snow:
            return snowIcon
        case .sleet:
            return sleetIcon
        case .thunderstorm:
            return thunderIcon
        case .unknown:
            return unknownIcon
        }
    }

    private func iconColor(for condition: WeatherCondition, isDaytime: Bool) -> String {
        switch condition {
        case .clear:
            return isDaytime ? "yellow" : "white"
        case .partlyCloudy:
            return isDaytime ? "yellow" : "white"
        case .cloudy:
            return "gray"
        case .fog:
            return "gray"
        case .drizzle, .rain, .freezingRain:
            return "cyan"
        case .snow, .sleet:
            return "white"
        case .thunderstorm:
            return "yellow"
        case .unknown:
            return "gray"
        }
    }

    // Simple ASCII icons
    private let sunIcon = [
        "    \\   |   /    ",
        "     .---.       ",
        "--- (     ) ---  ",
        "     `---'       ",
        "    /   |   \\    "
    ]

    private let moonIcon = [
        "       _.._       ",
        "     .' .-'`      ",
        "    /  /          ",
        "    |  |          ",
        "     \\  \\         ",
        "      '._'-._     "
    ]

    private let sunCloudIcon = [
        "   \\  /          ",
        " _ /\"\".-.        ",
        "   \\_  (   ).    ",
        "   /(___(____)   "
    ]

    private let moonCloudIcon = [
        "    _.._         ",
        "  .' .-'`.-.     ",
        "    (   ).  )    ",
        "   (___(_____)   "
    ]

    private let cloudIcon = [
        "               ",
        "     .--.      ",
        "  .-(    ).    ",
        " (___.__)__)   "
    ]

    private let fogIcon = [
        "               ",
        " _ - _ - _ -   ",
        "  _ - _ - _    ",
        " _ - _ - _ -   "
    ]

    private let rainIcon = [
        "     .-.       ",
        "    (   ).     ",
        "   (___(__)    ",
        "    ' ' ' '    ",
        "   ' ' ' '     "
    ]

    private let snowIcon = [
        "     .-.       ",
        "    (   ).     ",
        "   (___(__)    ",
        "    * * * *    ",
        "   * * * *     "
    ]

    private let sleetIcon = [
        "     .-.       ",
        "    (   ).     ",
        "   (___(__)    ",
        "    ' * ' *    ",
        "   * ' * '     "
    ]

    private let thunderIcon = [
        "     .-.       ",
        "    (   ).     ",
        "   (___(__)    ",
        "     /_/       ",
        "      /        "
    ]

    private let unknownIcon = [
        "               ",
        "      ?        ",
        "     ???       ",
        "      ?        "
    ]
}
