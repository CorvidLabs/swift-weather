---
spec: weather.spec.md
---
## Automated Testing
| Evidence | Coverage |
|----------|----------|
| `WeatherTests.swift` (57 tests, 14 suites) | Temperature, conditions, locations/US regions/states, models, forecast accessors, configuration, provider info, and errors. |
| `fledge lanes run verify` | Full SwiftPM build and deterministic test suite. |
## Manual Testing
- Source-review geocoding, provider HTTP/decoding/retry transformations, Weather fallback, and update-stream cancellation.
- Require exact-head Trust and CodeQL; preserve macOS, Ubuntu, DocC, and release workflows.
## Edge Cases & Boundary Conditions
| Scenario | Expected Behavior |
|----------|-------------------|
| Empty daily list | Today/tomorrow are nil. |
| Unknown WMO/NWS text | Condition is unknown. |
| Non-US location | Automatic selection falls through to Open-Meteo. |
| Every provider fails | Last provider error is thrown. |
| Stream fetch fails | Skip yield and continue until cancellation. |
