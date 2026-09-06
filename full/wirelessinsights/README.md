# WirelessInsights (Linux starting point)

This directory is a fail-closed portable `WirelessInsights` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS
Swift overlay from the sealed symbol graph and API digester. Isolated
host-gate success is not integrated Linux / cellular-modem success, and
this module is not wired into the shared guest package.

Coverage: **75 implemented / 0 declared / 0 deferred / 75 total**
(fully nondeferred, above the leaf-full floor of 60).

## Depth pass 2026-09

Fresh seed: no prior implemented/declared split. After this pass:
**75 implemented / 0 declared / 0 deferred**.

Every public precise ID is `implemented` with a dedicated top-level
`func test*()` (75 tests, 75 rows). Enum/option-set members do not share a
table-driven test here; each identifier has its own function.

Top-5 evidence distribution (share of the 75 implemented rows):

| Citations | Evidence |
| ---: | --- |
| 1 | `ServicePredictionTests.swift#testServicePredictionType` |
| 1 | `ServicePredictionTests.swift#testServicePredictionInitFromDecoder` |
| 1 | `ServicePredictionConfidenceTests.swift#testServicePredictionConfidenceLow` |
| 1 | `ServicePredictionQuantizedIntervalTests.swift#testServicePredictionQuantizedIntervalMinimal` |
| 1 | `ServicePredictionProviderTests.swift#testServicePredictionProviderServicePredictions` |

No test is cited by more than one implemented row (40% of remaining
rows would be 30).

## What is real

- `ServicePrediction` stores `impact`, `predictedStartTime`,
  `predictedInterval`, and `confidenceScore`. Equality and hashing are
  value-based. Codable round-trips those fields using property-name keys
  and `JSONEncoder.deferredToDate`.
- `ServicePrediction.Impact` and `.Confidence` are `low < medium < high`
  (`Comparable` + synthesized `>`, `>=`, `<=`, range operators). Synthesized
  Codable encodes cases as `{"caseName":{}}`.
- `ServicePrediction.ConfidenceScore` stores independent confidence for
  `prediction`, `startTime`, and `duration`.
- `ServicePrediction.QuantizedInterval` is a namespace of `Double`
  duration buckets: `minimal` = 10, `short` = 60, `medium` = 300,
  `long` = 600. Apple's docs describe those approximations; Darwin's exact
  payloads are unobserved.
- `ServicePredictionError.unsupportedDevice` and `.connectionError` are
  distinct `Hashable` / `Error` cases with distinct
  `localizedDescription` strings taken from Apple's articles.
- `ServicePredictionProvider.init()` constructs a local handle.
  Memberwise inits for `ServicePrediction` and `ConfidenceScore` match
  pinned TBD exports (not census IDs).

## Fail-closed boundaries

Linux has no cellular modem metrics daemon, WirelessInsights XPC service,
or `com.apple.developer.wireless-insights.service-predictions`
entitlement.

- `servicePredictions` never yields a (possibly empty) success snapshot.
  The first pull throws `ServicePredictionError.unsupportedDevice`, matching
  Apple's documented Catalyst / visionOS / macOS-Apple-silicon /
  Wi-Fi-only iPad behavior.
- `connectionError` is declared and tested as a value, but Linux never
  produces it from the provider (it is a recoverable stream-setup failure
  on a *supported* device).
- `predictedInterval` is not quantized on write; any `TimeInterval` the
  client constructs is stored. Live Apple quantization is unobserved.
- Private TBD types (`PrivateServicePrediction`, WIS XPC containers)
  are not declared.
- Apple's Codable key names, Date strategy, sequence executor, and
  exact QuantizedInterval binary values are unobserved (see
  `oracle-questions.tsv`).

## Environment and gate

`git rev-parse HEAD` at the start of this seed was
`26f5086c5b31ba816742f18d3096152cd32280f4`. `swiftc` is Swift 6.2.4,
target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
because `scratch/ladder-corpus/focus-ios` is absent from this snapshot.
The sealed framework gate does not require that checkout. The pod
booted from `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` rather
than campaign `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`.

Expected standalone markers:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_DELIVERABLE_OK module=WirelessInsights lane=leaf-full symbols=75
FRAMEWORK_FANOUT_REFERENCE_OK
WIRELESSINSIGHTS_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=WirelessInsights dylib=libWirelessInsights.dylib
```

`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token. The sealed gate compiles with a clean product
tree (`products=clean`).
