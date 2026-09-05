# DataDetection (Linux starting point)

Clean-room Linux starting point for Apple's public `DataDetection` module,
seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph, API digester, TBD
exports, and pinned `dotnet/macios` `datadetection.cs` bindings. This
directory is not wired into the shared guest package.

`libDataDetection.dylib` compiles with `-warnings-as-errors` under the sealed
host gate.

## What is real

- `DataDetector.MatchType` is an `OptionSet` over `UInt64`. Named flags use
  sequential `1 << n` bits in API-digester child order (`link` through
  `paymentIdentifier`). `all` is the union of those flags. SetAlgebra and
  OptionSet operations are the standard Swift implementations.
- `DataDetector.Options` stores `documentDate`, `documentRegion`,
  `documentTimeZone`, and `documentLanguageCode`. `init()` sets every field to
  `nil`. `documentTimeZone` is applied to ISO and `yyyy-MM-dd` calendar
  matches.
- `DataDetector.Match` and `SemanticDetails` value types are constructible.
  Nested payloads (email, phone, link, money, measurement, flight, calendar,
  postal, payment, shipment) round-trip their stored properties.
  `Measurement.measurement(in:)` converts through Foundation when a source
  unit of the requested `Dimension` subclass is in `possibleDimensions`.
- `HighlightStyle` (`hidden`, `url`, `regular` in digester order) and
  `PaymentSystem.unifiedPaymentsInterface` are `Hashable`.
- `DDMatch` and subclasses match the macios selectors (`matchedString`,
  `isAllDay`, `URL`, …). Linux adds designated inits because Apple disables the
  default constructor and there is no Darwin detector daemon here.
- `StringProtocol.dataDetectorMatches(_:options:)` runs a local scanner
  (email, URL, phone, money, measurement, IATA-like flight numbers, UPS `1Z`
  tracking, `upi://` payment URIs, US postal lines, ISO calendar dates) and
  wraps the snapshot in an `AsyncSequence` whose `next()` never waits.
  `DataDetector.collectMatches(in:types:options:)` is the synchronous Linux
  helper used by tests.

`libDataDetection.dylib` is produced only in a temporary host-gate directory.

## Fail-closed boundaries

- Apple DataDetectors / DataDetection daemon, language models, and
  entitlement-gated services are absent. The scanner is a conservative
  regular-expression grammar, not Apple's result set.
- Payment identifiers other than `upi://` URIs are not invented (VPA/email
  overlap).
- Shipment `trackingURL` is always `nil` on the Linux scanner.
- Calendar `endDate` is `nil` (duration is unobserved). Relative dates
  ("tomorrow") are not parsed.
- Phone and email `label` values are `nil` unless a test constructs them.
- `HighlightStyle.hidden` is never assigned by the scanner.
- `MatchType` integer payloads are Linux sequential flags, not claimed Apple
  ABI bits.

## Deferred / oracle

See `oracle-questions.tsv` for Apple `MatchType` raw values, async delivery
queue, hidden-highlight policy, measurement unit canonicalization, UPI
grammar, tracker URLs, and locale/documentDate effects.

## Tests

- `tests/agent/DataDetectionLoadSmoke.swift` — canonical schema-v2 marker
- `tests/agent/*Tests.swift` — focused `test*` probes (no stdout)
- `tests/agent/DataDetectionDependencyIdentity.swift` — Foundation `URL`,
  `Date`, `Decimal`, `Locale`, and `UnitLength` through public APIs

Keep generated products out of the tree. Run
`bash tests/acceptance/test_host.sh` from this directory or
`bash full/datadetection/tests/acceptance/test_host.sh` from the repo root.

## Depth pass 2026-09

This is a fresh seed: the directory had `AGENTS.md`, `FANOUT_TASK.md`, and
`reference/` only. This pass implements all **147** exact public identifiers
as `implemented` (0 declared / 0 deferred / 0 unavailable / 0 not-applicable).

Top-5 evidence distribution after this pass (of 147 implemented rows):

1. `testMatchTypeNamedCasesAndRawValues` — 16 rows (10.9%)
2. `testSemanticDetailsEnumCases` — 11 rows (7.5%)
3. `testPostalAddressPayload` — 9 rows (6.1%)
4. `testHighlightStyleCasesHashable` — 8 rows (5.4%)
5. `testMatchTypeMutatingSetAlgebra` — 7 rows (4.8%)

Row 1 is the option-set member / typealias table. No other single test is
cited by more than 40% of the remaining implemented rows.
