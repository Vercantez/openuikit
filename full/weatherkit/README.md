# WeatherKit

Linux starting point for Apple's public `WeatherKit` module, seeded from the
Xcode 26.1 iPhoneOS 26.1 symbol graph. There is no Apple weather daemon,
WeatherKit entitlement, or weather network on this host: value types match
the pinned overlay, and every `WeatherService` fetch fails closed with
`WeatherError.unknown`. Isolated `test_host.sh` success is not Apple WeatherKit
behavioral parity.

## What is real

Deterministic Linux behaviour for documented value types, enums, and
arithmetic:

- String-raw enums with api-digester case order: `WeatherCondition`,
  `Precipitation`, `PressureTrend`, `WeatherSeverity`, `MoonPhase`,
  `Wind.CompassDirection`, `UVIndex.ExposureCategory`,
  `WeatherAvailability.AvailabilityKind`
- `UVIndex.category` from WHO ranges (0–2 low, 3–5 moderate, 6–7 high,
  8–10 very high, 11+ extreme) and `Comparable` ordering on exposure
  categories
- `Wind.compassDirection` from 16-wind 22.5° sectors; abbreviation and
  description tables
- `MoonPhase.symbolName` SF Symbol identifiers (`moonphase.*`)
- Codable/Equatable round trips for timeline types (`CurrentWeather`,
  `HourWeather`, `DayWeather`, `MinuteWeather`, `DayPartForecast`,
  `Weather`), amounts, sun/moon events, statistics rows, alerts, and
  attribution records
- `DayWeather.precipitationAmount` reads `precipitationAmountByType.precipitation`
- `Forecast`, daily/hourly/monthly statistics, `DailyWeatherSummary`,
  `WeatherChanges`, and `HistoricalComparisons` as `RandomAccessCollection`
- `WeatherQuery` data-set tokens and dated daily/hourly range queries
- `WeatherService.shared` / `init()` identity; `attribution` and location
  fetches throw `WeatherError.unknown`

## Fail-closed Apple boundary

Linux has no WeatherKit entitlement and no Apple weather network.
`WeatherService` never fabricates a forecast, alert list, attribution
artwork, or statistics payload. `WeatherError.permissionDenied` is
available for callers but is not guessed as the host default.

`CLLocation`-taking APIs compile only when CoreLocation is importable
(EC2 integration). The isolated host gate cannot import CoreLocation, so
those methods are omitted from the Linux dylib and marked `deferred`.

## Deferred / unavailable

- Swift Sequence/Collection protocol witnesses not uniquely implemented
  (`filter`, `reduce`, Combine `publisher`, `FormatStyle`, `SortComparator`)
- `WeatherMetadata.location` and all `WeatherService` methods that require
  `CLLocation` until CoreLocation is on the module path
- Apple weather JSON wire format, SF Symbol mapping for conditions, and
  exact LocalizedError copy (see `oracle-questions.tsv`)

## Tests

- `tests/agent/WeatherKitLoadSmoke.swift` — schema-v2 import/marker probe
- `tests/agent/*Tests.swift` — focused family tests; each `implemented`
  coverage row cites one top-level synchronous `test*` function
- `tests/agent/WeatherKitDependencyIdentity.swift` — CoreLocation +
  Foundation import probe for the clean integration build

## Depth pass 2026-09

Implemented coverage rows: **697** (plus 1 `declared` `WeatherService.attribution`;
698 nondeferred of 1264, floor 632).

Top-5 evidence distribution among `implemented` rows:

1. `WeatherKitEnumTests.swift#testWeatherConditionRawValuesAndDescriptions` — 47
   (enum/option-set table-driven; allowed to share)
2. `WeatherKitValueTests.swift#testDayWeatherRoundTrip` — 30
3. `WeatherKitCoreTests.swift#testWindCompassDirectionRawValuesAndAbbreviations` — 27
4. `WeatherKitCollectionTests.swift#testForecastCollectionAndCodable` — 27
5. `WeatherKitCollectionTests.swift#testWeatherChangesCollection` — 26

No non-enum test exceeds 40% of the remaining implemented rows.
