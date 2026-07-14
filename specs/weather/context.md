---
spec: weather.spec.md
---
## Key Decisions
- Preserve actor isolation, Sendable models/providers, NWS/Open-Meteo priority, retry semantics, and no-live-network test boundary.
- Preserve macOS, Swift 6 Ubuntu, DocC Pages, and release workflows independently.
## Files to Read First
- `Weather.swift`, both provider files, `Forecast.swift`, `Location.swift`, `WeatherError.swift`, and `WeatherTests.swift`.
## Current Status
Twelve implementation files are protected by 57 deterministic tests across 14 suites; native verification performs no live network probe.
## Notes
Provider request/decoding branches are source-reviewed; existing tests focus on deterministic models, mappings, configuration, locations, and errors.
