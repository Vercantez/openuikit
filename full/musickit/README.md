# MusicKit (Linux starting point)

Clean-room Linux port of Apple's public `MusicKit` module from the pinned
Xcode 26.1 iPhoneOS graphs (2534 exact IDs, medium-full lane). Isolated host
compilation produces `libMusicKit.dylib`. This is not Apple Music catalog,
library, or hardware playback parity.

## Depth pass 2026-09

Coverage after this seed+depth run:

- **implemented:** 905
- **declared:** 460
- **nondeferred:** 1365 (floor 1267)
- **not-applicable:** 1169
- **deferred / unavailable:** 0 / 0

Top-5 implemented evidence distribution (905 implemented rows):

1. `test:full/musickit/tests/agent/MusicKitItemTests.swift#testPlaylistAndVideo` — 164 (18.1%)
2. `test:full/musickit/tests/agent/MusicKitEnumTests.swift#testEnumRawValues` — 148 (16.4%)
3. `test:full/musickit/tests/agent/MusicKitItemTests.swift#testSupportingTypes` — 94 (10.4%)
4. `test:full/musickit/tests/agent/MusicKitBehaviorTests.swift#testPlayerQueue` — 71 (7.8%)
5. `test:full/musickit/tests/agent/MusicKitItemTests.swift#testArtistGenreStation` — 69 (7.6%)

Enum / option-set members share `testEnumRawValues`. No other single test is
cited by more than 40% of the remaining implemented rows
(40% cap after the enum table = 302.8).

## Depth pass 2026-09 (wave 8)

Second pass keeps the first-pass sources and tests, then adds Apple Music
JSON parsing and local state for the largest remaining declared families.

| status | before | after |
| --- | --- | --- |
| implemented | 905 | 1171 |
| declared | 460 | 194 |
| deferred | 0 | 0 |
| unavailable | 0 | 0 |
| not-applicable | 1169 | 1169 |

Nondeferred stays 1365 (floor 1267). Gain is **+266 implemented** rows by
exercising value types that were previously declaration-only.

This pass adds:

- **MusicCatalogSearchResponse** kebab-case Apple Music search JSON
  (`music-videos`, `record-labels`, `apple-curators`, `radio-shows`, `top`)
  plus `TopResult` type-discriminator decoding.
- **MusicPersonalRecommendation** `stringForDisplay` attributes,
  `nextRefreshDate`, `relationships.contents`, and `Item` cases
  (`album` / `station` / `playlist` / `song`). `types` is derived from
  decoded items.
- **MusicLibrarySearchResponse** and **MusicCatalogSearchSuggestionsResponse**
  (`Suggestion.displayTerm` / `searchTerm`, `TopResult` alias).
- **MusicCatalogChartsResponse** / **MusicCatalogChart** parse `results` +
  `chart` kind strings `most-played` / `city-top` / `daily-global-top`.
- **MusicLibrarySectionedRequest** stores filter/sort state on
  `LibraryFilter` / `LibrarySortProperties` key paths (inspectable via
  `_openuikit_*` hooks). **MusicLibrarySection** dynamic-member lookup.
- **MusicDataRequest.Error** / **MusicDataResponse** constructible HTTP
  values (status, code, source parameter).
- Library filter/sort protocol probes with exact optional vs non-optional
  graph types.

Still fail-closed (declared, not invented): `response()`,
`MusicDataRequest.currentCountryCode`, `MusicSubscription.current`,
`Updates.Iterator.next()`, `MusicPlayer.play` / `prepareToPlay` / skip,
and async `Queue.insert`.

Top-5 evidence distribution (1171 implemented rows):

1. `test:full/musickit/tests/agent/MusicKitItemTests.swift#testPlaylistAndVideo` — 164 (14.0%)
2. `test:full/musickit/tests/agent/MusicKitEnumTests.swift#testEnumRawValues` — 148 (12.6%)
3. `test:full/musickit/tests/agent/MusicKitItemTests.swift#testSupportingTypes` — 94 (8.0%)
4. `test:full/musickit/tests/agent/MusicKitBehaviorTests.swift#testPlayerQueue` — 71 (6.1%)
5. `test:full/musickit/tests/agent/MusicKitItemTests.swift#testArtistGenreStation` — 69 (5.9%)

Largest new tests are `testChartsResponse` (24) and
`testSectionedRequestFilters` (22). No non-enum test exceeds the 40%
bulk-relabel ceiling (40% of 1171 = 468).

## Depth pass 2026-09 (wave 8, hashValue ledger repair)

Checked merge of `d959fd546b56` refused the branch because **59
not-applicable rows are not SwiftUI cross-import overlay IDs** (example:
`s:8MusicKit011ApplicationA6PlayerC5QueueC7EntriesV9hashValueSivp`).
Those are MusicKit-owned synthesized `Hashable.hashValue` properties.
Swift 6.2.4 on this host compiles `.hashValue` under `-warnings-as-errors`,
so focused tests now read it.

`MusicKitDepthTests.swift` is split into family files. Each `implemented`
row cites `test:full/musickit/tests/agent/<File>Tests.swift#testName` for a
real top-level synchronous `func testName()` that exercises that identifier.
`MusicLibraryResponse` / `MusicRecentlyPlayedResponse` /
`MusicCatalogResourceResponse` Hashable surface is constructed locally
(no Apple catalog fetch). `_MusicKit_SwiftUI` `Options.hashValue` stays
`not-applicable` (SwiftUI overlay). Stdlib `::SYNTHESIZED::` witnesses and
ArtworkImage `View` overlays stay `not-applicable`.

| status | before (refused merge) | after |
| --- | ---: | ---: |
| implemented | 1171 | 1248 |
| declared | 194 | 176 |
| deferred | 0 | 0 |
| unavailable | 0 | 0 |
| not-applicable | 1169 | 1110 |

Nondeferred: **1424** (floor 1267). Gain is **+77 implemented** (59
`hashValue` + 18 Hashable members of the three leftover response types).

Top-5 evidence distribution (1248 implemented rows):

1. `test:full/musickit/tests/agent/MusicKitItemTests.swift#testPlaylistAndVideo` — 169 (13.5%)
2. `test:full/musickit/tests/agent/MusicKitEnumTests.swift#testEnumRawValues` — 158 (12.7%)
3. `test:full/musickit/tests/agent/MusicKitItemTests.swift#testSupportingTypes` — 99 (7.9%)
4. `test:full/musickit/tests/agent/MusicKitBehaviorTests.swift#testPlayerQueue` — 75 (6.0%)
5. `test:full/musickit/tests/agent/MusicKitItemTests.swift#testArtistGenreStation` — 72 (5.8%)

Enum / option-set members share `testEnumRawValues`. No other single test
is cited by more than 40% of the remaining implemented rows
(40% cap after the enum table = 436.0; largest non-enum is 169).

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
  `subscriptionUnavailable`. `subscriptionUpdates` iterators yield `nil`.

## Tests

Focused `tests/agent/*Tests.swift` functions are invoked by the sealed
schema-v2 runner derived from `implemented` coverage. Load smoke prints
`MUSICKIT_AGENT_RUNTIME_OK`.

Environment: Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios`
is absent. The sealed gate compiles a clean product tree (`products=clean`).
