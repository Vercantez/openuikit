# ScreenTime

Linux starting point for Apple's public `ScreenTime` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS symbol graph. Isolated host-gate success
is not integrated Linux / Screen Time daemon success.

## Depth pass 2026-09

Coverage of the 30 exact public identifiers:

- **before:** 0 implemented / 0 declared / 0 deferred (fresh seed)
- **after:** 30 implemented / 0 declared / 0 deferred / 0 unavailable / 0 not-applicable

Every public precise ID is `implemented` with a dedicated top-level
`func test*()` (30 tests, 30 rows). The 20-app corpus does not rank this
module (`roadmap: none (operator override)`). This pass implements the
value type, observer state machine, bundle-identifier validation, local
webpage-usage flags, and fail-closed fetch/configuration/blocking
boundaries the headers describe.

Top-5 evidence distribution (share of the 30 implemented rows):

1. `ProfileIdentifierTests.swift#testProfileIdentifierType` — 1 (3.3%)
2. `ConfigurationTests.swift#testScreenTimeConfigurationType` — 1 (3.3%)
3. `ObserverTests.swift#testConfigurationObserverType` — 1 (3.3%)
4. `WebHistoryTests.swift#testWebHistoryType` — 1 (3.3%)
5. `WebpageControllerTests.swift#testWebpageControllerType` — 1 (3.3%)

No test is cited by more than one implemented row. There are no public
enum/option-set members or C `k…`/`err…` constants in this surface.

Environment: `git rev-parse HEAD` was
`2abc9defd72942e7a24dcc79779ea5c50e67d75c`. `swiftc` is Swift 6.2.4,
target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit the campaign
`products=clean` line because `scratch/ladder-corpus/focus-ios` is absent
from this snapshot; the sealed framework gate does not require that
checkout. The pod booted from
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` rather than campaign
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`.

## What is real

The public Foundation surface compiles to `libScreenTime.dylib`.

- `STWebHistory.ProfileIdentifier` is a `String` `RawRepresentable` /
  `Hashable` / `Sendable` newtype. `init(rawValue:)`, `init(_:)`, `!=`,
  `hashValue`, and `hash(into:)` are exercised. The raw string is stored
  unchanged.
- `STWebHistory` constructs a local handle. `init(bundleIdentifier:)` and
  `init(bundleIdentifier:profileIdentifier:)` throw
  `STScreenTimeError.invalidBundleIdentifier` for empty or whitespace
  identifiers and otherwise succeed. `init(profileIdentifier:)` never
  throws.
- `deleteAllHistory()`, `deleteHistory(during:)`, and `deleteHistory(for:)`
  are inert: they do not throw and do not invent a daemon round-trip.
- `STScreenTimeConfigurationObserver` stores `updateQueue` and tracks
  `startObserving` / `stopObserving` locally (`isObserving` via
  `@_spi(OpenUIKitHost)`).
- `STWebpageController` stores `url`, `urlIsPlayingVideo`,
  `urlIsPictureInPicture`, `suppressUsageRecording`, `profileIdentifier`,
  and the last accepted `bundleIdentifier` from `setBundleIdentifier(_:)`.

## Fail-closed boundaries

- `STScreenTimeConfiguration.enforcesChildRestrictions` is always `false`.
  `STScreenTimeConfigurationObserver.configuration` is always `nil`. Linux
  has no Screen Time agent (`STScreenTimeAgentConnection` /
  `_STMachServiceNameScreenTime` are TBD-only).
- `fetchAllHistory` and `fetchHistory(during:)` fail with
  `STScreenTimeError.unavailable`. Completions run inline; the async fetch
  never suspends. Empty-set success is not invented.
- `STWebpageController.urlIsBlocked` is always `false`. Setting `url` does
  not consult a web-content filter.
- `STWebpageController` is an `@MainActor` `NSObject`, not a
  `UIViewController`. UIKit is not a declared dependency.

`STScreenTimeError` is a local Swift error. Apple's NSError domain and
integer codes are unobserved.

## Still deferred / unobserved

See `oracle-questions.tsv` for Apple-oracle probes: configuration delivery
timing and queue, history-fetch empty-success vs error, Darwin error
codes, `urlIsBlocked` update timing, and ProfileIdentifier
canonicalization.
