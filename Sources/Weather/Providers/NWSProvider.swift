import Foundation
import Retry

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
 National Weather Service API weather provider.

 Provides free weather data for US locations only.
 Requires a User-Agent header identifying your application.

 API Documentation: https://www.weather.gov/documentation/services-web-api
 */
public actor NWSProvider: WeatherProvider {
    /// Provider information.
    public let info = WeatherProviderInfo.nws

    /// User-Agent string for API requests.
    private let userAgent: String

    /// The URL session for requests.
    private let session: URLSession

    /// JSON decoder for responses.
    private let decoder: JSONDecoder

    /// Base URL for NWS API.
    private static let baseURL = URL(string: "https://api.weather.gov")!

    /**
     Creates a new NWS provider.
     - Parameters:
       - userAgent: User-Agent string identifying your app. Format: "(AppName, contact@email.com)"
       - session: The URL session to use. Defaults to `.shared`.
     */
    public init(userAgent: String, session: URLSession = .shared) {
        self.userAgent = userAgent
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    /// NWS only supports US locations.
    public func supports(location: Location) async -> Bool {
        location.isLikelyUS
    }

    /// Fetches current weather from NWS.
    public func currentWeather(for location: Location) async throws -> CurrentWeather {
        let (latitude, longitude, locationName) = try await resolveLocation(location)

        // Step 1: Get grid point info
        let gridInfo = try await getGridInfo(latitude: latitude, longitude: longitude)

        // Step 2: Get observation stations
        let stationsURL = try await getObservationStationsURL(from: gridInfo)

        // Step 3: Get latest observation
        let observation = try await getLatestObservation(from: stationsURL)

        return try transformObservation(
            observation,
            latitude: latitude,
            longitude: longitude,
            locationName: locationName ?? gridInfo.properties.relativeLocation?.properties.city
        )
    }

    /// Fetches a multi-day forecast from NWS.
    public func forecast(for location: Location, days: Int) async throws -> Forecast {
        let (latitude, longitude, locationName) = try await resolveLocation(location)
        let clampedDays = max(1, min(7, days)) // NWS provides 7-day forecasts

        // Get grid point info
        let gridInfo = try await getGridInfo(latitude: latitude, longitude: longitude)

        // Get forecast URL from grid info
        guard let forecastURLString = gridInfo.properties.forecast,
              let forecastURL = URL(string: forecastURLString) else {
            throw WeatherError.noDataAvailable
        }

        var request = URLRequest(url: forecastURL)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/geo+json", forHTTPHeaderField: "Accept")

        let forecastResponse: NWSForecastResponse = try await perform(request)

        // NWS returns periods (day/night), combine them into daily forecasts
        let dailyForecasts = parseDailyForecasts(
            from: forecastResponse.properties.periods,
            maxDays: clampedDays
        )

        return Forecast(
            location: ResolvedLocation(
                latitude: latitude,
                longitude: longitude,
                name: locationName ?? gridInfo.properties.relativeLocation?.properties.city
            ),
            daily: dailyForecasts,
            provider: info
        )
    }

    /// Fetches hourly forecast from NWS.
    public func hourlyForecast(for location: Location, hours: Int) async throws -> [HourlyForecast] {
        let (latitude, longitude, _) = try await resolveLocation(location)
        let clampedHours = max(1, min(156, hours)) // NWS provides ~156 hours

        // Get grid point info
        let gridInfo = try await getGridInfo(latitude: latitude, longitude: longitude)

        // Get hourly forecast URL from grid info
        guard let hourlyURLString = gridInfo.properties.forecastHourly,
              let hourlyURL = URL(string: hourlyURLString) else {
            throw WeatherError.noDataAvailable
        }

        var request = URLRequest(url: hourlyURL)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/geo+json", forHTTPHeaderField: "Accept")

        let forecastResponse: NWSForecastResponse = try await perform(request)

        return forecastResponse.properties.periods.prefix(clampedHours).map { period in
            let condition = WeatherCondition.fromNWSText(period.shortForecast)
            return HourlyForecast(
                time: period.startTime,
                temperature: Temperature.fahrenheit(Double(period.temperature)),
                apparentTemperature: nil,
                condition: condition,
                conditionDescription: period.shortForecast,
                precipitationProbability: period.probabilityOfPrecipitation?.value.map { Double($0) },
                humidity: period.relativeHumidity?.value.map { Double($0) },
                windSpeed: parseWindSpeed(period.windSpeed),
                windDirection: parseWindDirection(period.windDirection),
                isDaytime: period.isDaytime
            )
        }
    }

    // MARK: - Private Forecast Helpers

    private func parseDailyForecasts(from periods: [NWSPeriod], maxDays: Int) -> [DailyForecast] {
        var dailyMap: [String: (day: NWSPeriod?, night: NWSPeriod?)] = [:]

        for period in periods {
            let dateKey = formatDateKey(period.startTime)

            if dailyMap[dateKey] == nil {
                dailyMap[dateKey] = (nil, nil)
            }

            if period.isDaytime {
                dailyMap[dateKey]?.day = period
            } else {
                dailyMap[dateKey]?.night = period
            }
        }

        // Sort by date and create daily forecasts
        let sortedDates = dailyMap.keys.sorted()
        return sortedDates.prefix(maxDays).compactMap { dateKey -> DailyForecast? in
            guard let entry = dailyMap[dateKey] else { return nil }

            let dayPeriod = entry.day
            let nightPeriod = entry.night

            // Get high from day period, low from night period
            let highTemp = dayPeriod.map { Temperature.fahrenheit(Double($0.temperature)) }
                ?? nightPeriod.map { Temperature.fahrenheit(Double($0.temperature)) }
            let lowTemp = nightPeriod.map { Temperature.fahrenheit(Double($0.temperature)) }
                ?? dayPeriod.map { Temperature.fahrenheit(Double($0.temperature)) }

            guard let high = highTemp, let low = lowTemp else { return nil }

            let forecastText = dayPeriod?.shortForecast ?? nightPeriod?.shortForecast ?? "Unknown"
            let condition = WeatherCondition.fromNWSText(forecastText)

            // Parse date from the first available period
            let date = dayPeriod?.startTime ?? nightPeriod?.startTime ?? Date()

            // Get precipitation probability (max of day/night)
            let dayPrecip = dayPeriod?.probabilityOfPrecipitation?.value ?? 0
            let nightPrecip = nightPeriod?.probabilityOfPrecipitation?.value ?? 0
            let precipProb = max(dayPrecip, nightPrecip)

            return DailyForecast(
                date: date,
                highTemperature: high,
                lowTemperature: low,
                condition: condition,
                conditionDescription: forecastText,
                precipitationProbability: precipProb > 0 ? Double(precipProb) : nil,
                precipitationAmount: nil,
                sunrise: nil,
                sunset: nil,
                uvIndex: nil
            )
        }
    }

    private func formatDateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func parseWindSpeed(_ windSpeed: String?) -> Double? {
        guard let speed = windSpeed else { return nil }
        // Format: "10 mph" or "10 to 15 mph"
        let components = speed.components(separatedBy: " ")
        if let first = components.first, let value = Double(first) {
            return value * 1.60934 // Convert mph to km/h
        }
        return nil
    }

    private func parseWindDirection(_ direction: String?) -> Double? {
        guard let dir = direction else { return nil }
        let directions: [String: Double] = [
            "N": 0, "NNE": 22.5, "NE": 45, "ENE": 67.5,
            "E": 90, "ESE": 112.5, "SE": 135, "SSE": 157.5,
            "S": 180, "SSW": 202.5, "SW": 225, "WSW": 247.5,
            "W": 270, "WNW": 292.5, "NW": 315, "NNW": 337.5
        ]
        return directions[dir]
    }

    // MARK: - Private

    private func resolveLocation(_ location: Location) async throws -> (Double, Double, String?) {
        switch location {
        case .coordinates(let latitude, let longitude):
            return (latitude, longitude, nil)
        case .city(let name):
            return try await geocode(city: name)
        }
    }

    private func geocode(city: String) async throws -> (Double, Double, String?) {
        let result = try await GeocodingService.shared.geocode(city: city)
        return (result.latitude, result.longitude, result.name)
    }

    private func getGridInfo(latitude: Double, longitude: Double) async throws -> NWSPointsResponse {
        let url = Self.baseURL
            .appendingPathComponent("points")
            .appendingPathComponent("\(latitude),\(longitude)")

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/geo+json", forHTTPHeaderField: "Accept")

        return try await perform(request)
    }

    private func getObservationStationsURL(from gridInfo: NWSPointsResponse) async throws -> URL {
        guard let stationsURLString = gridInfo.properties.observationStations,
              let stationsURL = URL(string: stationsURLString) else {
            throw WeatherError.noDataAvailable
        }

        return stationsURL
    }

    private func getLatestObservation(from stationsURL: URL) async throws -> NWSObservation {
        // First get the list of stations
        var stationsRequest = URLRequest(url: stationsURL)
        stationsRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        stationsRequest.setValue("application/geo+json", forHTTPHeaderField: "Accept")

        let stationsResponse: NWSStationsResponse = try await perform(stationsRequest)

        guard let firstStation = stationsResponse.features.first,
              let stationId = firstStation.properties.stationIdentifier else {
            throw WeatherError.noDataAvailable
        }

        // Get latest observation from the first station
        let observationURL = Self.baseURL
            .appendingPathComponent("stations")
            .appendingPathComponent(stationId)
            .appendingPathComponent("observations")
            .appendingPathComponent("latest")

        var observationRequest = URLRequest(url: observationURL)
        observationRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        observationRequest.setValue("application/geo+json", forHTTPHeaderField: "Accept")

        let observationResponse: NWSObservationResponse = try await perform(observationRequest)
        return observationResponse.properties
    }

    private func transformObservation(
        _ observation: NWSObservation,
        latitude: Double,
        longitude: Double,
        locationName: String?
    ) throws -> CurrentWeather {
        // Get temperature (NWS returns in Celsius)
        let temperature: Temperature
        if let tempValue = observation.temperature.value {
            temperature = Temperature(celsius: tempValue)
        } else {
            throw WeatherError.noDataAvailable
        }

        // Determine condition from text description
        let conditionText = observation.textDescription ?? "Unknown"
        let condition = WeatherCondition.fromNWSText(conditionText)

        // Get humidity
        let humidity = observation.relativeHumidity?.value

        // Get wind speed (NWS returns in km/h)
        let windSpeed = observation.windSpeed?.value

        // Get wind direction
        let windDirection = observation.windDirection?.value

        // Determine if daytime (based on icon URL or time)
        let isDaytime = observation.icon?.contains("day") ?? true

        // Parse observation time
        let observationTime = observation.timestamp ?? Date()

        return CurrentWeather(
            temperature: temperature,
            condition: condition,
            conditionDescription: conditionText,
            humidity: humidity,
            windSpeed: windSpeed,
            windDirection: windDirection,
            isDaytime: isDaytime,
            location: ResolvedLocation(
                latitude: latitude,
                longitude: longitude,
                name: locationName
            ),
            observationTime: observationTime,
            provider: info
        )
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        try await Retry.execute(
            maxAttempts: 3,
            strategy: ExponentialStrategy(base: 1.0, multiplier: 2.0),
            configuration: RetryConfiguration(
                maxAttempts: 3,
                shouldRetry: { error in
                    guard let weatherError = error as? WeatherError else { return true }
                    switch weatherError {
                    case .rateLimited, .apiError, .networkError:
                        return true
                    case .unsupportedLocation, .decodingFailed, .noDataAvailable, .unknown, .locationNotFound, .noProviderAvailable, .invalidURL:
                        return false
                    }
                }
            )
        ) { [session, decoder] in
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw WeatherError.unknown("Invalid response type")
            }

            switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw WeatherError.decodingFailed(error)
                }
            case 404:
                throw WeatherError.unsupportedLocation("Location not supported by NWS")
            case 429:
                throw WeatherError.rateLimited
            case 500, 503:
                throw WeatherError.apiError(statusCode: httpResponse.statusCode, message: "NWS service unavailable")
            default:
                throw WeatherError.apiError(statusCode: httpResponse.statusCode, message: nil)
            }
        }
    }
}

// MARK: - NWS Response Models

private struct NWSPointsResponse: Decodable {
    let properties: PointsProperties

    struct PointsProperties: Decodable {
        let observationStations: String?
        let forecast: String?
        let forecastHourly: String?
        let relativeLocation: RelativeLocation?
    }

    struct RelativeLocation: Decodable {
        let properties: RelativeLocationProperties
    }

    struct RelativeLocationProperties: Decodable {
        let city: String?
        let state: String?
    }
}

private struct NWSStationsResponse: Decodable {
    let features: [StationFeature]

    struct StationFeature: Decodable {
        let properties: StationProperties
    }

    struct StationProperties: Decodable {
        let stationIdentifier: String?
        let name: String?
    }
}

private struct NWSObservationResponse: Decodable {
    let properties: NWSObservation
}

private struct NWSObservation: Decodable {
    let timestamp: Date?
    let textDescription: String?
    let icon: String?
    let temperature: QuantitativeValue
    let relativeHumidity: QuantitativeValue?
    let windSpeed: QuantitativeValue?
    let windDirection: QuantitativeValue?

    struct QuantitativeValue: Decodable {
        let value: Double?
        let unitCode: String?
    }
}

private struct NWSForecastResponse: Decodable {
    let properties: ForecastProperties

    struct ForecastProperties: Decodable {
        let periods: [NWSPeriod]
    }
}

private struct NWSPeriod: Decodable {
    let name: String
    let startTime: Date
    let endTime: Date
    let isDaytime: Bool
    let temperature: Int
    let temperatureUnit: String
    let shortForecast: String
    let detailedForecast: String?
    let windSpeed: String?
    let windDirection: String?
    let probabilityOfPrecipitation: PrecipitationValue?
    let relativeHumidity: HumidityValue?

    struct PrecipitationValue: Decodable {
        let value: Int?
    }

    struct HumidityValue: Decodable {
        let value: Int?
    }
}

