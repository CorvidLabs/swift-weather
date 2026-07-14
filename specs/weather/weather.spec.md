---
module: weather
version: 3
status: active
files:
  - Sources/Weather/GeocodingService.swift
  - Sources/Weather/Models/CurrentWeather.swift
  - Sources/Weather/Models/Forecast.swift
  - Sources/Weather/Models/Location.swift
  - Sources/Weather/Models/Temperature.swift
  - Sources/Weather/Models/WeatherCondition.swift
  - Sources/Weather/Providers/NWSProvider.swift
  - Sources/Weather/Providers/OpenMeteoProvider.swift
  - Sources/Weather/Providers/WeatherProvider.swift
  - Sources/Weather/Weather.swift
  - Sources/Weather/WeatherConfiguration.swift
  - Sources/Weather/WeatherError.swift
db_tables: []
depends_on: []
---

# Weather

## Purpose

Swift Weather provides a Sendable Swift 6 model and actor API for current, daily, hourly, and streamed weather. It selects NWS or Open-Meteo providers, geocodes city names, retries eligible remote failures, normalizes provider payloads, and preserves attribution. It does not own remote availability, API contents, or live-network verification.

## Public API

| Export | Contract |
|--------|----------|
| `Weather` | Actor orchestrating providers, current conditions, forecasts, and update streams. |
| `GeocodingService` | Actor resolving city names through Open-Meteo geocoding. |
| `WeatherError` | Sendable, localized, equatable error taxonomy. |
| `WeatherConfiguration` | User agent, display unit, and provider strategy. |
| `ProviderStrategy` | Automatic, NWS-only, or Open-Meteo-only provider construction. |
| `WeatherProvider` | Sendable async provider protocol for support/current/daily/hourly operations. |
| `NWSProvider` | US-focused NWS actor with retries and normalized output. |
| `OpenMeteoProvider` | Global Open-Meteo actor with normalized output. |
| `Temperature` | Celsius-canonical Codable value with Fahrenheit/Kelvin conversion and formatting. |
| `TemperatureUnit` | Celsius/Fahrenheit display unit and symbol. |
| `WeatherCondition` | Normalized condition category derived from WMO codes or NWS text. |
| `Location` | Coordinate or city query with likely-US classification. |
| `USRegion` | Contiguous, Alaska, Hawaii, and Caribbean coordinate bounds. |
| `USState` | State/territory name recognition for city classification. |
| `CurrentWeather` | Normalized current observation. |
| `ResolvedLocation` | Coordinates plus optional name and timezone. |
| `WeatherProviderInfo` | Provider name and attribution, including NWS/Open-Meteo constants. |
| `Forecast` | Generated daily forecast collection with today/tomorrow access. |
| `DailyForecast` | Daily high/low, condition, precipitation, sun, and UV values. |
| `HourlyForecast` | Hourly temperature, condition, precipitation, humidity, wind, and daytime values. |
| `configuration` | Immutable Weather client configuration. |
| `init` | Public construction for clients, services, providers, configurations, and models. |
| `current` | Current conditions by Location, coordinates, or city. |
| `forecast` | Multi-day forecast by Location, coordinates, or city. |
| `hourlyForecast` | Hourly forecast by Location, coordinates, or city. |
| `weatherUpdates` | Cancellation-aware async stream that suppresses individual fetch failures. |
| `shared` | Shared geocoding actor. |
| `geocode` | Resolve a city to coordinates and a composed optional name. |
| `errorDescription` | Localized message for each WeatherError. |
| `==` | Case-specific WeatherError equality. |
| `userAgent` | NWS request identity. |
| `temperatureUnit` | Preferred display unit. |
| `providerStrategy` | Provider selection policy. |
| `us` | Fahrenheit automatic configuration. |
| `international` | Celsius Open-Meteo-only configuration. |
| `providers` | Providers in strategy priority order. |
| `info` | Provider identity exposed by provider actors. |
| `supports` | Async provider location-support decision. |
| `currentWeather` | Provider-level current observation request. |
| `celsius` | Canonical temperature storage. |
| `fahrenheit` | Converted value or Fahrenheit factory. |
| `kelvin` | Converted value or Kelvin factory. |
| `formatted` | Unit-aware decimal temperature string. |
| `symbol` | Display-unit symbol. |
| `temperature` | Observation or forecast temperature. |
| `condition` | Normalized condition category. |
| `conditionDescription` | Original provider description. |
| `humidity` | Optional relative humidity percentage. |
| `windSpeed` | Optional normalized km/h wind speed. |
| `windDirection` | Optional degree heading. |
| `isDaytime` | Provider-derived day/night flag. |
| `location` | Resolved location attached to output. |
| `observationTime` | Current observation timestamp. |
| `provider` | Output provider identity. |
| `latitude` | Resolved latitude. |
| `longitude` | Resolved longitude. |
| `name` | Optional resolved name or provider name. |
| `timezone` | Optional timezone identifier. |
| `attribution` | Optional provider attribution. |
| `nws` | NWS provider-info constant. |
| `openMeteo` | Open-Meteo provider-info constant. |
| `description` | Human-readable condition. |
| `fromWMOCode` | WMO-to-condition mapping. |
| `fromNWSText` | Case-insensitive NWS-text mapping. |
| `daily` | Daily forecast values. |
| `generatedAt` | Forecast generation timestamp. |
| `today` | First daily value, if present. |
| `tomorrow` | Second daily value, if present. |
| `date` | Daily forecast date. |
| `highTemperature` | Daily high. |
| `lowTemperature` | Daily low. |
| `precipitationProbability` | Optional provider probability. |
| `precipitationAmount` | Optional precipitation amount. |
| `sunrise` | Optional sunrise. |
| `sunset` | Optional sunset. |
| `uvIndex` | Optional UV index. |
| `time` | Hourly timestamp. |
| `apparentTemperature` | Optional feels-like temperature. |
| `isLikelyUS` | Heuristic NWS eligibility. |
| `latitudeRange` | Region latitude bounds. |
| `longitudeRange` | Region longitude bounds. |
| `contains` | Instance/static US coordinate containment. |
| `isUSCity` | State/country-token city heuristic. |
| `coordinates` | Coordinate Location case. |
| `city` | City-name Location case. |
| `contiguousUS` | Contiguous-US region case. |
| `alaska` | Alaska region/state case. |
| `hawaii` | Hawaii region/state case. |
| `caribbean` | Puerto Rico/USVI region case. |
| `automatic` | NWS-first automatic strategy. |
| `nwsOnly` | NWS-only strategy. |
| `openMeteoOnly` | Open-Meteo-only strategy. |
| `clear` | Clear condition case. |
| `partlyCloudy` | Partly-cloudy condition case. |
| `cloudy` | Cloudy condition case. |
| `fog` | Fog condition case. |
| `drizzle` | Drizzle condition case. |
| `rain` | Rain condition case. |
| `freezingRain` | Freezing-rain condition case. |
| `snow` | Snow condition case. |
| `sleet` | Sleet condition case. |
| `thunderstorm` | Thunderstorm condition case. |
| `unknown` | Unknown condition/error case. |
| `locationNotFound` | Missing geocoding result error. |
| `unsupportedLocation` | Provider-ineligible location error. |
| `networkError` | Wrapped transport error. |
| `decodingFailed` | Wrapped decoding error. |
| `apiError` | HTTP status and optional message error. |
| `noDataAvailable` | Missing required weather value error. |
| `rateLimited` | HTTP rate-limit error. |
| `noProviderAvailable` | No eligible provider error. |
| `invalidURL` | URL construction error. |
| `alabama` | US state token. |
| `arizona` | US state token. |
| `arkansas` | US state token. |
| `california` | US state token. |
| `colorado` | US state token. |
| `connecticut` | US state token. |
| `delaware` | US state token. |
| `florida` | US state token. |
| `georgia` | US state token. |
| `idaho` | US state token. |
| `illinois` | US state token. |
| `indiana` | US state token. |
| `iowa` | US state token. |
| `kansas` | US state token. |
| `kentucky` | US state token. |
| `louisiana` | US state token. |
| `maine` | US state token. |
| `maryland` | US state token. |
| `massachusetts` | US state token. |
| `michigan` | US state token. |
| `minnesota` | US state token. |
| `mississippi` | US state token. |
| `missouri` | US state token. |
| `montana` | US state token. |
| `nebraska` | US state token. |
| `nevada` | US state token. |
| `newHampshire` | US state token. |
| `newJersey` | US state token. |
| `newMexico` | US state token. |
| `newYork` | US state token. |
| `northCarolina` | US state token. |
| `northDakota` | US state token. |
| `ohio` | US state token. |
| `oklahoma` | US state token. |
| `oregon` | US state token. |
| `pennsylvania` | US state token. |
| `rhodeIsland` | US state token. |
| `southCarolina` | US state token. |
| `southDakota` | US state token. |
| `tennessee` | US state token. |
| `texas` | US state token. |
| `utah` | US state token. |
| `vermont` | US state token. |
| `virginia` | US state token. |
| `washington` | US state token. |
| `westVirginia` | US state token. |
| `wisconsin` | US state token. |
| `wyoming` | US state token. |
| `districtOfColumbia` | District token. |
| `puertoRico` | Territory token. |

## Invariants

1. Temperatures store Celsius canonically; provider output normalizes wind to km/h where required.
2. Automatic strategy tries NWS then Open-Meteo, skipping unsupported providers and returning the last attempted error.
3. NWS support is limited to likely-US locations; Open-Meteo reports global support.
4. City queries geocode before provider calls; coordinate queries preserve supplied coordinates.
5. Remote responses require HTTP success, map rate limits/API failures/decoding errors, and retry only eligible failures.
6. Forecast and hourly counts are bounded by provider responses and caller limits.
7. Weather update streams stop on cancellation and do not terminate for one failed fetch.

## Behavioral Examples

### Scenario: Automatic US current weather
- **Given** a likely-US location
- **When** current weather is requested
- **Then** NWS is attempted first and Open-Meteo remains fallback

### Scenario: International forecast
- **Given** an international configuration and city
- **When** a forecast is requested
- **Then** the city is geocoded and Open-Meteo supplies normalized daily values

### Scenario: Update stream failure
- **Given** a running update stream and a failed fetch
- **When** the next interval arrives
- **Then** the failure is suppressed and polling continues until cancellation

## Error Cases

| Condition | Behavior |
|-----------|----------|
| City has no geocoding result | Throw location-not-found. |
| Response is non-HTTP | Throw unknown invalid-response error. |
| HTTP 429 | Throw rate-limited. |
| Provider rejects location | Throw unsupported-location. |
| JSON cannot decode | Throw decoding-failed. |
| Required observation/forecast value is absent | Throw no-data-available. |
| No configured provider supports a location | Throw no-provider-available. |
| All attempted providers fail | Throw the last provider error. |

## Dependencies

| Module | Use |
|--------|-----|
| Foundation / FoundationNetworking | Actors, URLSession, dates, JSON, URLs, formatting, and async streams. |
| CorvidLabs swift-retry | Bounded exponential retry for provider transport/API failures. |
| NWS APIs | US points, stations, observations, and forecasts. |
| Open-Meteo APIs | Global geocoding, current, daily, and hourly data. |

## Change Log

| Date | Author | Change |
|------|--------|--------|
| 2026-07-13 | `user:0xLeif` | Documented existing behavior at complete coverage without product-code changes. |
| 2026-07-14 | CHG-0002-document-the-existing-swift-weather-api-and-provider-behavior-at-complete-specsy: Document the existing Swift Weather API and provider behavior at complete SpecSync coverage |
