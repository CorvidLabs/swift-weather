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
}
