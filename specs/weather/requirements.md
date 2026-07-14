---
spec: weather.spec.md
---
## User Stories
- Query current, daily, hourly, and streamed weather by coordinates or city.
- Select NWS/Open-Meteo explicitly or automatically while retaining provider attribution.
- Consume normalized Sendable models, units, locations, conditions, and typed errors.
## Acceptance Criteria
- All 12 source files and 2,127 LOC have 100% coverage.
- Nine stable requirements map implementation behavior to truthful deterministic or source-review evidence.
- Strict SpecSync scores A/100; `Sources/` and `Tests/` remain unchanged.
## Constraints
- Preserve Swift 6 and declared Apple platforms, Linux compatibility, public APIs, retry dependency, no-auth Open-Meteo use, NWS user agent, CI, DocC, and release boundaries.
## Out of Scope
- Live probes, API redesign, dependency changes, caching, persistence, or remote-service fixes.

### REQ-weather-001

Weather models SHALL preserve Celsius-canonical temperatures, normalized conditions, resolved locations, provider attribution, and optional current/daily/hourly fields.
Acceptance Criteria
- Deterministic temperature, condition, location, model, forecast, and provider-info tests pass.

### REQ-weather-002

Configuration SHALL construct automatic NWS-then-Open-Meteo, NWS-only, or Open-Meteo-only provider order with US/international unit defaults.
Acceptance Criteria
- Configuration tests pass and strategy ordering matches source.

### REQ-weather-003

Geocoding SHALL query Open-Meteo, compose an optional resolved name, and map HTTP, decoding, and missing-result failures to WeatherError.
Acceptance Criteria
- Every branch is source-reviewed without claiming a live probe.

### REQ-weather-004

Open-Meteo SHALL support global locations and normalize current, daily, and hourly responses into public models.
Acceptance Criteria
- URL, decode, limits, timezone, condition, unit, and error branches match source.

### REQ-weather-005

NWS SHALL support likely-US locations, send the user agent, resolve points/stations/observations/forecasts, and retry only eligible failures.
Acceptance Criteria
- Location heuristics are tested; request, transformation, retry, and error branches match source.

### REQ-weather-006

Weather SHALL expose current/daily/hourly overloads and try supported providers in order, returning first success, last attempted error, or no-provider error.
Acceptance Criteria
- All overload and fallback branches match actor source.

### REQ-weather-007

Update streams SHALL poll at the requested interval, suppress individual fetch failures, and finish after termination cancels the task.
Acceptance Criteria
- Cancellation, yield, sleep, failure, and finish branches match source.

### REQ-weather-008

WeatherError SHALL preserve typed cases, localized descriptions, and case-specific equality.
Acceptance Criteria
- Error description and equality tests pass.

### REQ-weather-009

Verification SHALL preserve Swift 6/platforms, macOS/Ubuntu CI, 57 deterministic tests, DocC, releases, and no-live-network boundary.
Acceptance Criteria
- Native and exact-head Trust pass while `Sources/` and `Tests/` remain unchanged.

