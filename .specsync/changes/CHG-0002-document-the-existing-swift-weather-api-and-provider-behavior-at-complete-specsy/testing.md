---
change: CHG-0002-document-the-existing-swift-weather-api-and-provider-behavior-at-complete-specsy
artifact: testing
---
# Testing
| Requirements | Evidence |
|--------------|----------|
| `REQ-weather-001` | Deterministic suites cover temperatures, conditions, locations, regions, states, current/daily/hourly models, and provider info. |
| `REQ-weather-002` | Configuration tests cover defaults, US, and international strategy; provider arrays are source-reviewed. |
| `REQ-weather-003` | Geocoding URL, HTTP, decode, and no-result branches are source-reviewed; no live success is claimed. |
| `REQ-weather-004` | Open-Meteo support, URL, normalization, and error branches are source-reviewed. |
| `REQ-weather-005` | NWS eligibility, points/stations/forecast normalization, and retry branches are source-reviewed. |
| `REQ-weather-006` | Weather fallback/current/daily/hourly overloads are source-reviewed. |
| `REQ-weather-007` | Update stream loop, suppressed failure, termination, and cancellation are source-reviewed. |
| `REQ-weather-008` | Error description/equality tests plus provider mappings. |
| `REQ-weather-009` | `fledge lanes run verify` builds SwiftPM and passes 57 tests across 14 suites without live probes. |
