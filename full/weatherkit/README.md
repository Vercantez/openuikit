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
- `WeatherQuery` data-set tokens and dated daily/hourly range queries (`isValid` / `validate()`)
- `WeatherService.shared` / `init()` identity; Linux `weather(latitude:longitude:including:)` validates coordinates and query ranges then throws `WeatherError.unknown`
- NOAA solar-calculator `SunEvents(date:latitude:longitude:)` (official/civil/nautical/astronomical zeniths) and Meeus-style `MoonPhase(date:)` synodic-month phases
- WeatherKit REST document decoding (`WeatherKitREST`) for `currentWeather` / `forecastHourly` / `forecastDaily` JSON
- Sequence/Collection/Foundation witnesses on `Forecast`, statistics, summaries, `WeatherChanges`, and `HistoricalComparisons`

## Fail-closed Apple boundary

Linux has no WeatherKit entitlement and no Apple weather network.
`WeatherService` never fabricates a forecast, alert list, attribution
artwork, or statistics payload. `WeatherError.permissionDenied` is
available for callers but is not guessed as the host default.

`CLLocation`-taking APIs compile only when CoreLocation is importable
(EC2 integration). The isolated host gate cannot import CoreLocation, so
those methods are omitted from the Linux dylib and marked `deferred`.

## Deferred / unavailable

- `WeatherMetadata.location` and all `WeatherService` methods that require
  `CLLocation` until CoreLocation is on the module path
- Deprecated Swift 6 `Collection.index(of:)` and optional-returning
  `Sequence.flatMap` (compiler rejects them under warnings-as-errors)
- Combine `publisher` — Combine is not a declared dependency and has no
  Linux daemon/runtime here
- Moon rise/set timestamps, SF Symbol mapping for conditions, and exact
  Apple LocalizedError copy (see `oracle-questions.tsv`)

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

## Depth pass 2026-09 (wave 8)

Coverage of the 1264 iPhoneOS 26.1 public identifiers:

| status | before | after |
| --- | --- | --- |
| implemented | 697 | 1222 |
| declared | 1 | 1 |
| deferred | 559 | 34 |
| unavailable | 7 | 7 |
| not-applicable | 0 | 0 |

This second pass keeps the first-pass sources and tests green, then adds:

- NOAA solar-calculator `SunEvents` and Meeus-style `MoonPhase` constructors,
  tested against the 2024-03-20 Greenwich/equator equinox and known lunations
- Fail-closed `WeatherService.weather(latitude:longitude:including:)` that
  validates finite in-range coordinates and `startDate < endDate` queries,
  then throws `WeatherError.unknown` (never `permissionDenied`, never a
  fabricated forecast)
- `WeatherKitREST` Decodable mapping of the documented weatherkitrestapi
  current/hourly/daily JSON shape onto Linux value types
- Foundation `Measurement` unit conversions for temperature, wind, pressure,
  and length
- Per-identifier Sequence/Collection/Foundation witness tests (`formIndex`,
  `randomElement`, `difference`, `suffix`/`prefix`/`dropLast`, `filter`/
  `reduce`/`flatMap`, `sorted(using:)`, `_StringProcessing` ranges, and
  related members) on the seven WeatherKit `RandomAccessCollection` types

Seven Combine `publisher` rows stay `unavailable` (no Combine daemon/runtime
on this host). `CLLocation` service methods and `WeatherMetadata.location`
stay `deferred`. Deprecated Swift 6 `index(of:)` and optional `flatMap`
stay `deferred` because `-warnings-as-errors` refuses those spellings.

`.cursor/verify-cloud-environment.sh` on this snapshot fails earlier
(`missing corpus checkout: scratch/ladder-corpus/focus-ios`; Cursor Build
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). `swiftc` is Swift
6.2.4 / linux and the sealed gate compiles with a clean product tree
(`products=clean`). Starting commit `2de7152a12f3beb34a4c1e92dc0e849af9a1d88b`
matched.

Top-5 evidence distribution (implemented rows citing each test):

1. `testWeatherConditionRawValuesAndDescriptions` — 47 (3.8% of 1222; enum/option-set table-driven)
2. `testDayWeatherRoundTrip` — 30 (2.5%)
3. `testWindCompassDirectionRawValuesAndAbbreviations` / `testForecastCollectionAndCodable` — 27 each (2.2%)
4. `testWeatherChangesCollection` — 26 (2.1%)
5. `testUVIndexExposureCategoryRawValuesRangesAndOrder` — 25 (2.0%)

No non-enum test exceeds the 40% bulk-relabel ceiling.
