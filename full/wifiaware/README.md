# WiFiAware (Linux starting point)

This directory is a fail-closed portable `WiFiAware` module for the OpenUIKit
Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS Swift surface
from the sealed symbol graph. It is not wired into the shared guest package;
that integration is a separate central review step.

The GitHub App installation for this run cannot read
`github.com/Vercantez/openuikit-linux-platform` (fetch returned 404), so the
1078-line fan-out PR #31 tree could not be copied by content. The lane is
implemented from the sealed monorepo seed (`reference/public-surface.tsv` and
the exact graphs). The monorepo `reference/` dossier is kept
(`generatorSHA256=2b8230ced5a3ed78f070607346f6a684d9e0fb74a8932b92bc0f5e38f46f0a8e`).

## What is real

- `WAParameters` public `init(performanceMode:)` plus `.defaults` (bulk) and
  `.realtime`. `performanceMode` is readable and writable.
- `WAPerformanceMode`, `WAAccessCategory`, and `WACapabilities.Feature` are
  `Hashable` / `Codable` / `CaseIterable`. Linux JSON uses the synthesized
  no-raw-value enum layout; Apple's on-wire keys are unobserved.
- `WACapabilities.supportedFeatures` is `[]`. The three maxima are `0`. Linux
  has no NAN radio.
- `WAError` cases are constructible by decoding empty `{}` details, matching
  Apple's documented empty keyed-container encoding. `LocalizedError`
  optionals stay `nil` (Apple string payloads unobserved).
- `WAPairedDevice.allDevices` / `allDevices(matching:)` yield one empty
  snapshot and finish. There is no pairing daemon.
- `WAPublishableService.allServices` and `WASubscribableService.allServices`
  are empty (no `Info.plist` `WiFiAwareServices` inventory).
- Publisher/subscriber `Action.connecting`, `Devices` factories, and
  `DatapathParameters` presets exist as in-process values. They do not start
  a listener or browser.
- `WAPerformanceReport` and `TransmitLatencyMetrics` round-trip through
  `Codable`. `throughputCapacityRatio` is `capacity / ceiling` when both are
  present and `ceiling != 0`.

## Fail-closed boundaries

- Isolated host Swift 6.2.4 has no `Network` or `OSLog` module.
  `NWParameters.wifiAware`, `NWPath.wifiAware`, `NWError.wifiAware`,
  `NWParametersBuilder.wifiAware`, `ListenerProvider.wifiAware`,
  `BrowserProvider.wifiAware`, `WAPublisherListener.service` /
  `configureParameters`, and `WASubscriberBrowser.makeDescriptor` /
  `makeEndpoint` / `configureParameters` are **not compiled** here and are
  `deferred`.
- `WAPublisherListener` does not conform to `Network.ListenerProvider`.
  `WASubscriberBrowser` does not conform to `Network.BrowserProvider`.
  `WAEndpoint` does not conform to `Network.Connectable`. Those protocols are
  absent from the guest `Network` module as well.
- `isApplicationService` is `false`. Linux never publishes.
- No public convenience constructors were added for system-produced
  `WAEndpoint` / `WAPath` values. Host tests construct them through
  `@_spi(OpenUIKitHost)` and treat the values as fail-closed snapshots.
- `hashValue` is the synthesized `Hashable` witness. Swift 6.2.4 on this host
  compiles `.hashValue` under `-warnings-as-errors`, so focused tests read it.

## Tests

`tests/agent/WiFiAwareRuntime.swift` is the host-gate probe and prints
`WIFIAWARE_AGENT_RUNTIME_OK`.

Focused family tests live under `tests/agent/*Tests.swift` as top-level
synchronous `func testName()` functions. Coverage evidence cites those tests
in `test:full/wifiaware/tests/agent/<File>Tests.swift#testName` form.

`tests/agent/WiFiAwareDependencyIdentity.swift` is a future EC2 identity
probe: it requires real `Foundation`, `Network`, and `OSLog` modules. It is
not part of the isolated host gate.

## Depth pass 2026-09

Implemented before: **223** / declared 23 / deferred 14 / unavailable 0 /
not-applicable 0 (260 exact IDs).

Implemented after: **245** / declared 1 / deferred 14 / unavailable 0 /
not-applicable 0.

Raised from `declared` to `implemented`: `WAEndpoint`, `WAPath`,
`WAPublisherListener` / `isApplicationService`, `WASubscriberBrowser`, and
synthesized `hashValue` witnesses. Those are exercised by host SPI or by
reading `hashValue`. The 14 `Network` overlay / provider members stay
`deferred` (no `Network` module; no lookalike stubs). One
`AsyncSequence.flatMap` overload remains `declared`: the graph synthesizes
the `Self.Failure == Never` variant onto `DevicesSequence`, but
`DevicesSequence.Failure` is `Error`, so that overload is not callable.

The 20-app corpus summary lists WiFiAware only in Signal-iOS device-transfer
files (`WAPublisherListener` / `WASubscriberBrowser` / paired devices /
services). `scratch/ladder-corpus/focus-ios` contains no WiFiAware symbols.

Top-5 evidence distribution (of 245 implemented rows; 40% cap = 98):

1. `WAErrorTests.swift#testErrorDetailsEmptyCodable` — 45 rows (18.4%)
2. `WAErrorTests.swift#testErrorCasesTableDriven` — 16 rows (6.5%)
3. `WAParametersTests.swift#testAccessCategoryCases` — 14 rows (5.7%)
4. `WAPairedDeviceTests.swift#testPairedDeviceCodable` — 13 rows (5.3%)
5. `WAServiceTests.swift#testPublishableService` — 12 rows (4.9%)

