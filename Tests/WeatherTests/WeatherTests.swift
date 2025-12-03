import Foundation
import Testing
@testable import Weather

@Suite("Weather Tests")
struct WeatherTests {
    @Suite("Temperature")
    struct TemperatureTests {
        @Test("Celsius initialization")
        func celsiusInit() {
            let temp = Temperature(celsius: 20)
            #expect(temp.celsius == 20)
        }

        @Test("Fahrenheit conversion")
        func fahrenheitConversion() {
            let temp = Temperature(celsius: 0)
            #expect(temp.fahrenheit == 32)

            let boiling = Temperature(celsius: 100)
            #expect(boiling.fahrenheit == 212)
        }

        @Test("Fahrenheit initialization")
        func fahrenheitInit() {
            let temp = Temperature.fahrenheit(68)
            #expect(temp.celsius == 20)
        }

        @Test("Kelvin conversion")
        func kelvinConversion() {
            let temp = Temperature(celsius: 0)
            #expect(temp.kelvin == 273.15)
        }

        @Test("Formatting")
        func formatting() {
            let temp = Temperature(celsius: 20)
            #expect(temp.formatted(unit: .celsius) == "20°C")
            #expect(temp.formatted(unit: .fahrenheit) == "68°F")
            #expect(temp.formatted(unit: .celsius, decimalPlaces: 1) == "20.0°C")
        }
    }

    @Suite("WeatherCondition")
    struct WeatherConditionTests {
        @Test("WMO code mapping - clear")
        func wmoCodeClear() {
            #expect(WeatherCondition.fromWMOCode(0) == .clear)
        }

        @Test("WMO code mapping - partly cloudy")
        func wmoCodePartlyCloudy() {
            #expect(WeatherCondition.fromWMOCode(1) == .partlyCloudy)
            #expect(WeatherCondition.fromWMOCode(2) == .partlyCloudy)
        }

        @Test("WMO code mapping - cloudy")
        func wmoCodeCloudy() {
            #expect(WeatherCondition.fromWMOCode(3) == .cloudy)
        }

        @Test("WMO code mapping - rain")
        func wmoCodeRain() {
            #expect(WeatherCondition.fromWMOCode(61) == .rain)
            #expect(WeatherCondition.fromWMOCode(63) == .rain)
            #expect(WeatherCondition.fromWMOCode(80) == .rain)
        }

        @Test("WMO code mapping - snow")
        func wmoCodeSnow() {
            #expect(WeatherCondition.fromWMOCode(71) == .snow)
            #expect(WeatherCondition.fromWMOCode(85) == .snow)
        }

        @Test("WMO code mapping - thunderstorm")
        func wmoCodeThunderstorm() {
            #expect(WeatherCondition.fromWMOCode(95) == .thunderstorm)
            #expect(WeatherCondition.fromWMOCode(99) == .thunderstorm)
        }

        @Test("WMO code mapping - unknown")
        func wmoCodeUnknown() {
            #expect(WeatherCondition.fromWMOCode(999) == .unknown)
        }

        @Test("NWS text mapping")
        func nwsTextMapping() {
            #expect(WeatherCondition.fromNWSText("Clear") == .clear)
            #expect(WeatherCondition.fromNWSText("Sunny") == .clear)
            #expect(WeatherCondition.fromNWSText("Partly Cloudy") == .partlyCloudy)
            #expect(WeatherCondition.fromNWSText("Rain") == .rain)
            #expect(WeatherCondition.fromNWSText("Light Rain Showers") == .rain)
            #expect(WeatherCondition.fromNWSText("Snow") == .snow)
            #expect(WeatherCondition.fromNWSText("Thunderstorm") == .thunderstorm)
        }

        @Test("Condition descriptions")
        func descriptions() {
            #expect(WeatherCondition.clear.description == "Clear")
            #expect(WeatherCondition.partlyCloudy.description == "Partly Cloudy")
            #expect(WeatherCondition.thunderstorm.description == "Thunderstorm")
        }
    }

    @Suite("Location")
    struct LocationTests {
        @Test("US coordinates detection - Seattle")
        func usCoordinatesSeattle() {
            let location = Location.coordinates(latitude: 47.6, longitude: -122.3)
            #expect(location.isLikelyUS == true)
        }

        @Test("US coordinates detection - New York")
        func usCoordinatesNewYork() {
            let location = Location.coordinates(latitude: 40.7, longitude: -74.0)
            #expect(location.isLikelyUS == true)
        }

        @Test("US coordinates detection - Hawaii")
        func usCoordinatesHawaii() {
            let location = Location.coordinates(latitude: 21.3, longitude: -157.8)
            #expect(location.isLikelyUS == true)
        }

        @Test("US coordinates detection - Alaska")
        func usCoordinatesAlaska() {
            let location = Location.coordinates(latitude: 64.8, longitude: -147.7)
            #expect(location.isLikelyUS == true)
        }

        @Test("Non-US coordinates - London")
        func nonUSCoordinatesLondon() {
            let location = Location.coordinates(latitude: 51.5, longitude: -0.1)
            #expect(location.isLikelyUS == false)
        }

        @Test("Non-US coordinates - Tokyo")
        func nonUSCoordinatesTokyo() {
            let location = Location.coordinates(latitude: 35.7, longitude: 139.7)
            #expect(location.isLikelyUS == false)
        }

        @Test("US city detection by state abbreviation")
        func usCityByState() {
            let seattle = Location.city("Seattle, WA")
            #expect(seattle.isLikelyUS == true)

            let nyc = Location.city("New York, NY")
            #expect(nyc.isLikelyUS == true)
        }

        @Test("US city detection by country")
        func usCityByCountry() {
            let city = Location.city("Chicago, US")
            #expect(city.isLikelyUS == true)
        }

        @Test("Non-US city detection")
        func nonUSCity() {
            let london = Location.city("London")
            #expect(london.isLikelyUS == false)

            let paris = Location.city("Paris, France")
            #expect(paris.isLikelyUS == false)
        }
    }

    @Suite("Configuration")
    struct ConfigurationTests {
        @Test("Default configuration")
        func defaultConfig() {
            let config = WeatherConfiguration(userAgent: "(TestApp, test@example.com)")
            #expect(config.temperatureUnit == .fahrenheit)
            #expect(config.providerStrategy == .automatic)
        }

        @Test("US configuration")
        func usConfig() {
            let config = WeatherConfiguration.us(userAgent: "(TestApp, test@example.com)")
            #expect(config.temperatureUnit == .fahrenheit)
            #expect(config.providerStrategy == .automatic)
        }

        @Test("International configuration")
        func internationalConfig() {
            let config = WeatherConfiguration.international(userAgent: "(TestApp, test@example.com)")
            #expect(config.temperatureUnit == .celsius)
            #expect(config.providerStrategy == .openMeteoOnly)
        }
    }

    @Suite("WeatherProviderInfo")
    struct ProviderInfoTests {
        @Test("NWS provider info")
        func nwsInfo() {
            let info = WeatherProviderInfo.nws
            #expect(info.name == "NWS")
            #expect(info.attribution == "National Weather Service")
        }

        @Test("Open-Meteo provider info")
        func openMeteoInfo() {
            let info = WeatherProviderInfo.openMeteo
            #expect(info.name == "Open-Meteo")
            #expect(info.attribution == "Open-Meteo.com")
        }
    }

    @Suite("CurrentWeather")
    struct CurrentWeatherTests {
        @Test("CurrentWeather initialization")
        func initialization() {
            let weather = CurrentWeather(
                temperature: Temperature(celsius: 20),
                condition: .clear,
                conditionDescription: "Clear",
                humidity: 50,
                windSpeed: 10,
                windDirection: 180,
                isDaytime: true,
                location: ResolvedLocation(latitude: 47.6, longitude: -122.3, name: "Seattle"),
                observationTime: Date(),
                provider: .nws
            )

            #expect(weather.temperature.celsius == 20)
            #expect(weather.condition == .clear)
            #expect(weather.humidity == 50)
            #expect(weather.isDaytime == true)
            #expect(weather.location.name == "Seattle")
        }
    }

    @Suite("WeatherError")
    struct WeatherErrorTests {
        @Test("Error descriptions")
        func errorDescriptions() {
            let locationError = WeatherError.locationNotFound("Seattle")
            #expect(locationError.errorDescription?.contains("Seattle") == true)

            let rateLimited = WeatherError.rateLimited
            #expect(rateLimited.errorDescription?.contains("Rate") == true)
        }

        @Test("Error equality")
        func errorEquality() {
            #expect(WeatherError.rateLimited == WeatherError.rateLimited)
            #expect(WeatherError.locationNotFound("A") == WeatherError.locationNotFound("A"))
            #expect(WeatherError.locationNotFound("A") != WeatherError.locationNotFound("B"))
        }
    }

    @Suite("ResolvedLocation")
    struct ResolvedLocationTests {
        @Test("Basic initialization")
        func basicInit() {
            let location = ResolvedLocation(latitude: 47.6, longitude: -122.3)
            #expect(location.latitude == 47.6)
            #expect(location.longitude == -122.3)
            #expect(location.name == nil)
            #expect(location.timezone == nil)
        }

        @Test("Full initialization")
        func fullInit() {
            let location = ResolvedLocation(
                latitude: 47.6,
                longitude: -122.3,
                name: "Seattle, WA",
                timezone: "America/Los_Angeles"
            )
            #expect(location.name == "Seattle, WA")
            #expect(location.timezone == "America/Los_Angeles")
        }

        @Test("Hashable conformance")
        func hashable() {
            let loc1 = ResolvedLocation(latitude: 47.6, longitude: -122.3)
            let loc2 = ResolvedLocation(latitude: 47.6, longitude: -122.3)
            let loc3 = ResolvedLocation(latitude: 40.7, longitude: -74.0)

            var set = Set<ResolvedLocation>()
            set.insert(loc1)
            set.insert(loc2)
            set.insert(loc3)

            #expect(set.count == 2)
        }

        @Test("Equatable conformance")
        func equatable() {
            let loc1 = ResolvedLocation(latitude: 47.6, longitude: -122.3, name: "Seattle")
            let loc2 = ResolvedLocation(latitude: 47.6, longitude: -122.3, name: "Seattle")
            let loc3 = ResolvedLocation(latitude: 47.6, longitude: -122.3, name: "Different")

            #expect(loc1 == loc2)
            #expect(loc1 != loc3)
        }
    }

    @Suite("Forecast")
    struct ForecastTests {
        @Test("Forecast initialization")
        func initialization() {
            let location = ResolvedLocation(latitude: 47.6, longitude: -122.3)
            let daily = [
                DailyForecast(
                    date: Date(),
                    highTemperature: Temperature(celsius: 25),
                    lowTemperature: Temperature(celsius: 15),
                    condition: .clear,
                    conditionDescription: "Sunny"
                )
            ]
            let forecast = Forecast(
                location: location,
                daily: daily,
                provider: .openMeteo
            )

            #expect(forecast.location == location)
            #expect(forecast.daily.count == 1)
            #expect(forecast.provider == .openMeteo)
        }

        @Test("Today property with data")
        func todayWithData() {
            let location = ResolvedLocation(latitude: 47.6, longitude: -122.3)
            let todayForecast = DailyForecast(
                date: Date(),
                highTemperature: Temperature(celsius: 25),
                lowTemperature: Temperature(celsius: 15),
                condition: .clear,
                conditionDescription: "Sunny"
            )
            let forecast = Forecast(
                location: location,
                daily: [todayForecast],
                provider: .openMeteo
            )

            #expect(forecast.today != nil)
            #expect(forecast.today?.condition == .clear)
        }

        @Test("Today property when empty")
        func todayWhenEmpty() {
            let location = ResolvedLocation(latitude: 47.6, longitude: -122.3)
            let forecast = Forecast(
                location: location,
                daily: [],
                provider: .openMeteo
            )

            #expect(forecast.today == nil)
        }

        @Test("Tomorrow property with data")
        func tomorrowWithData() {
            let location = ResolvedLocation(latitude: 47.6, longitude: -122.3)
            let todayForecast = DailyForecast(
                date: Date(),
                highTemperature: Temperature(celsius: 25),
                lowTemperature: Temperature(celsius: 15),
                condition: .clear,
                conditionDescription: "Sunny"
            )
            let tomorrowForecast = DailyForecast(
                date: Date().addingTimeInterval(86400),
                highTemperature: Temperature(celsius: 22),
                lowTemperature: Temperature(celsius: 12),
                condition: .rain,
                conditionDescription: "Rainy"
            )
            let forecast = Forecast(
                location: location,
                daily: [todayForecast, tomorrowForecast],
                provider: .openMeteo
            )

            #expect(forecast.tomorrow != nil)
            #expect(forecast.tomorrow?.condition == .rain)
        }

        @Test("Tomorrow property when only today exists")
        func tomorrowWhenOnlyToday() {
            let location = ResolvedLocation(latitude: 47.6, longitude: -122.3)
            let todayForecast = DailyForecast(
                date: Date(),
                highTemperature: Temperature(celsius: 25),
                lowTemperature: Temperature(celsius: 15),
                condition: .clear,
                conditionDescription: "Sunny"
            )
            let forecast = Forecast(
                location: location,
                daily: [todayForecast],
                provider: .openMeteo
            )

            #expect(forecast.tomorrow == nil)
        }
    }

    @Suite("DailyForecast")
    struct DailyForecastTests {
        @Test("Required parameters only")
        func requiredOnly() {
            let forecast = DailyForecast(
                date: Date(),
                highTemperature: Temperature(celsius: 30),
                lowTemperature: Temperature(celsius: 20),
                condition: .clear,
                conditionDescription: "Clear skies"
            )

            #expect(forecast.highTemperature.celsius == 30)
            #expect(forecast.lowTemperature.celsius == 20)
            #expect(forecast.condition == .clear)
            #expect(forecast.precipitationProbability == nil)
            #expect(forecast.precipitationAmount == nil)
            #expect(forecast.sunrise == nil)
            #expect(forecast.sunset == nil)
            #expect(forecast.uvIndex == nil)
        }

        @Test("All optional parameters")
        func allOptionals() {
            let sunrise = Date()
            let sunset = Date().addingTimeInterval(43200)

            let forecast = DailyForecast(
                date: Date(),
                highTemperature: Temperature(celsius: 30),
                lowTemperature: Temperature(celsius: 20),
                condition: .partlyCloudy,
                conditionDescription: "Partly cloudy",
                precipitationProbability: 30,
                precipitationAmount: 2.5,
                sunrise: sunrise,
                sunset: sunset,
                uvIndex: 7
            )

            #expect(forecast.precipitationProbability == 30)
            #expect(forecast.precipitationAmount == 2.5)
            #expect(forecast.sunrise == sunrise)
            #expect(forecast.sunset == sunset)
            #expect(forecast.uvIndex == 7)
        }

        @Test("Equatable conformance")
        func equatable() {
            let date = Date()
            let f1 = DailyForecast(
                date: date,
                highTemperature: Temperature(celsius: 30),
                lowTemperature: Temperature(celsius: 20),
                condition: .clear,
                conditionDescription: "Clear"
            )
            let f2 = DailyForecast(
                date: date,
                highTemperature: Temperature(celsius: 30),
                lowTemperature: Temperature(celsius: 20),
                condition: .clear,
                conditionDescription: "Clear"
            )

            #expect(f1 == f2)
        }
    }

    @Suite("HourlyForecast")
    struct HourlyForecastTests {
        @Test("Required parameters only")
        func requiredOnly() {
            let forecast = HourlyForecast(
                time: Date(),
                temperature: Temperature(celsius: 22),
                condition: .clear,
                conditionDescription: "Clear"
            )

            #expect(forecast.temperature.celsius == 22)
            #expect(forecast.condition == .clear)
            #expect(forecast.isDaytime == true) // default
            #expect(forecast.apparentTemperature == nil)
            #expect(forecast.precipitationProbability == nil)
            #expect(forecast.humidity == nil)
            #expect(forecast.windSpeed == nil)
            #expect(forecast.windDirection == nil)
        }

        @Test("All optional parameters")
        func allOptionals() {
            let forecast = HourlyForecast(
                time: Date(),
                temperature: Temperature(celsius: 22),
                apparentTemperature: Temperature(celsius: 25),
                condition: .rain,
                conditionDescription: "Light rain",
                precipitationProbability: 80,
                humidity: 75,
                windSpeed: 15,
                windDirection: 270,
                isDaytime: false
            )

            #expect(forecast.apparentTemperature?.celsius == 25)
            #expect(forecast.precipitationProbability == 80)
            #expect(forecast.humidity == 75)
            #expect(forecast.windSpeed == 15)
            #expect(forecast.windDirection == 270)
            #expect(forecast.isDaytime == false)
        }

        @Test("Equatable conformance")
        func equatable() {
            let time = Date()
            let h1 = HourlyForecast(
                time: time,
                temperature: Temperature(celsius: 22),
                condition: .clear,
                conditionDescription: "Clear"
            )
            let h2 = HourlyForecast(
                time: time,
                temperature: Temperature(celsius: 22),
                condition: .clear,
                conditionDescription: "Clear"
            )

            #expect(h1 == h2)
        }
    }

    @Suite("USRegion")
    struct USRegionTests {
        @Test("Contiguous US boundaries")
        func contiguousUS() {
            // Inside contiguous US
            #expect(USRegion.contiguousUS.contains(latitude: 40.0, longitude: -100.0) == true)

            // Southern boundary (just inside)
            #expect(USRegion.contiguousUS.contains(latitude: 24.5, longitude: -100.0) == true)
            // Northern boundary (just inside)
            #expect(USRegion.contiguousUS.contains(latitude: 49.5, longitude: -100.0) == true)
            // Eastern boundary (just inside)
            #expect(USRegion.contiguousUS.contains(latitude: 40.0, longitude: -66.0) == true)
            // Western boundary (just inside)
            #expect(USRegion.contiguousUS.contains(latitude: 40.0, longitude: -125.0) == true)

            // Outside boundaries
            #expect(USRegion.contiguousUS.contains(latitude: 24.4, longitude: -100.0) == false)
            #expect(USRegion.contiguousUS.contains(latitude: 49.6, longitude: -100.0) == false)
        }

        @Test("Alaska boundaries")
        func alaska() {
            // Fairbanks area
            #expect(USRegion.alaska.contains(latitude: 64.8, longitude: -147.7) == true)

            // Boundary tests
            #expect(USRegion.alaska.contains(latitude: 51.0, longitude: -150.0) == true)
            #expect(USRegion.alaska.contains(latitude: 71.5, longitude: -150.0) == true)

            // Outside Alaska
            #expect(USRegion.alaska.contains(latitude: 50.9, longitude: -150.0) == false)
        }

        @Test("Hawaii boundaries")
        func hawaii() {
            // Honolulu area
            #expect(USRegion.hawaii.contains(latitude: 21.3, longitude: -157.8) == true)

            // Boundary tests
            #expect(USRegion.hawaii.contains(latitude: 18.5, longitude: -157.0) == true)
            #expect(USRegion.hawaii.contains(latitude: 22.5, longitude: -157.0) == true)

            // Outside Hawaii
            #expect(USRegion.hawaii.contains(latitude: 18.4, longitude: -157.0) == false)
        }

        @Test("Caribbean boundaries")
        func caribbean() {
            // Puerto Rico
            #expect(USRegion.caribbean.contains(latitude: 18.2, longitude: -66.0) == true)

            // Outside Caribbean
            #expect(USRegion.caribbean.contains(latitude: 17.4, longitude: -66.0) == false)
        }

        @Test("Static contains method")
        func staticContains() {
            // Seattle (contiguous)
            #expect(USRegion.contains(latitude: 47.6, longitude: -122.3) == true)
            // Honolulu (Hawaii)
            #expect(USRegion.contains(latitude: 21.3, longitude: -157.8) == true)
            // Fairbanks (Alaska)
            #expect(USRegion.contains(latitude: 64.8, longitude: -147.7) == true)
            // San Juan (Caribbean)
            #expect(USRegion.contains(latitude: 18.2, longitude: -66.0) == true)
            // London (outside US)
            #expect(USRegion.contains(latitude: 51.5, longitude: -0.1) == false)
        }

        @Test("All cases iterable")
        func allCases() {
            #expect(USRegion.allCases.count == 4)
        }
    }

    @Suite("USState")
    struct USStateTests {
        @Test("All 50 states plus DC and PR")
        func allStates() {
            #expect(USState.allCases.count == 52)
        }

        @Test("State abbreviations lowercase")
        func abbreviationsLowercase() {
            #expect(USState.washington.rawValue == "wa")
            #expect(USState.newYork.rawValue == "ny")
            #expect(USState.california.rawValue == "ca")
        }

        @Test("US city detection with state")
        func cityWithState() {
            #expect(USState.isUSCity("Seattle, wa") == true)
            #expect(USState.isUSCity("Seattle, WA") == true)
            #expect(USState.isUSCity("New York, ny") == true)
        }

        @Test("US city detection with country")
        func cityWithCountry() {
            #expect(USState.isUSCity("Portland, US") == true)
            #expect(USState.isUSCity("Portland, USA") == true)
            #expect(USState.isUSCity("city, United States") == true)
        }

        @Test("Non-US city detection")
        func nonUSCity() {
            #expect(USState.isUSCity("London") == false)
            #expect(USState.isUSCity("Paris, France") == false)
            #expect(USState.isUSCity("Tokyo, Japan") == false)
        }
    }
}
