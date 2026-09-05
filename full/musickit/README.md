# MusicKit (Linux starting point)

Clean-room Linux port of Apple's public `MusicKit` module from the pinned
Xcode 26.1 iPhoneOS graphs (2534 exact IDs, medium-full lane). Isolated host
compilation produces `libMusicKit.dylib`. This is not Apple Music catalog,
library, or hardware playback parity.

## Depth pass 2026-09

Coverage after this seed+depth run:

- **implemented:** 947
- **declared:** 478
- **nondeferred:** 1425 (floor 1267)
- **not-applicable:** 1109
- **deferred / unavailable:** 0 / 0

Top-5 implemented evidence distribution (947 implemented rows):

1. `test:full/musickit/tests/agent/MusicKitItemTests.swift#testPlaylistAndVideo` — 169 (17.8%)
2. `test:full/musickit/tests/agent/MusicKitEnumTests.swift#testEnumRawValues` — 158 (16.7%)
3. `test:full/musickit/tests/agent/MusicKitItemTests.swift#testSupportingTypes` — 99 (10.5%)
4. `test:full/musickit/tests/agent/MusicKitBehaviorTests.swift#testPlayerQueue` — 75 (7.9%)
5. `test:full/musickit/tests/agent/MusicKitItemTests.swift#testArtistGenreStation` — 72 (7.6%)

Enum / option-set members share `testEnumRawValues`. No other single test is
cited by more than 40% of the remaining implemented rows
(40% cap after the enum table = 315.6).

## Public surface implemented

- **MusicItemID** string wrapper: `init(_:)`, `init(rawValue:)`, string
  literals, Codable round-trip, Hashable.
- **Artwork** Apple Music URL templates: `url(width:height:)` substitutes
  `{w}`/`{h}`; hex `bgColor`/`textColor*` decode to `CGColor`.
- **Song / Album / Artist / …** decode the Apple Music API resource shape
  (`id` + `attributes.name` / `artistName` / `durationInMillis` / `artwork`).
- **MusicItemCollection** is a real `RandomAccessCollection` over an array,
  including `+=` batch append.
- **MusicPlayer** in-process state machine: `pause` / `stop` / seek /
  `restartCurrentEntry` / `playbackTime`. `play()` / `prepareToPlay()` stay
  fail-closed (`MusicKitPortableError.playbackUnavailable`).
- **ApplicationMusicPlayer.shared** / **SystemMusicPlayer.shared** singletons
  and queue entry construction from `PlayableMusicItem` values.
- **MusicAuthorization.Status** String raw values; `currentStatus` starts
  `.notDetermined` (test hook `_openuikit_setCurrentStatus`).
- **Catalog / library request builders** store term, types, limit, offset, and
  filters locally. `response()` throws the documented fail-closed error.
- **MusicSubscriptionOffer** value types (`join` / `playMusic` / `addMusic`,
  `subscribe`, default options).
- **MusicTokenRequestOptions.ignoreCache** option set (raw value `1 << 0`).
- Error enums (`MusicLibrary.Error`, `MusicTokenRequestError`,
  `MusicSubscription.Error`) use the case name as the String raw value.

## Fail-closed boundaries

- **network:** Catalog search, charts, resource, suggestions, data, and
  personal-recommendation `response()` throw
  `MusicKitPortableError.catalogUnavailable`. Tokens throw
  `MusicTokenRequestError.userNotSignedIn` /
  `developerTokenRequestFailed`.
- **os-service:** `play()` / `prepareToPlay()` / skip throw
  `MusicKitPortableError.playbackUnavailable`. There is no Apple Music
  daemon or AirPlay route.
- **fail-closed:** `MusicAuthorization.request()` becomes `.denied`.
  `MusicLibrary.add` / `createPlaylist` / `edit` throw
  `.permissionDenied`. `MusicSubscription.current` throws
  `.permissionDenied`. SwiftUI `musicSubscriptionOffer` reports
  `subscriptionUnavailable`.

## Tests

Focused `tests/agent/*Tests.swift` functions are invoked by the sealed
schema-v2 runner derived from `implemented` coverage. Load smoke prints
`MUSICKIT_AGENT_RUNTIME_OK`.

Environment: Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios`
is absent. The sealed gate compiles a clean product tree (`products=clean`).
