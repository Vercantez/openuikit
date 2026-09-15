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

## Depth pass 2026-09 (wave 9, declared filter/model sweep)

Four focused tests already existed in `tests/agent/` but were cited by
zero coverage rows; the protocols they probe were still `declared`, and
two response types lacked the `Codable` members the tests round-trip.
This pass wires them up with no new test files:

- Expanded five under-declared protocols to the graph shape
  (`MusicVideoFilter.isrc`, `LibraryGenreFilter.name`,
  `LibraryPlaylistFilter.name`, all seven `LibraryTrackFilter` members,
  `LibraryGenreSortProperties.libraryAddedDate`,
  `LibraryPlaylistSortProperties.libraryAddedDate`); all digester
  optionality matches. `Track` now witnesses the full
  `LibraryTrackFilter` (`artists` / `genres` added, `artistName`
  widened to `String?`; existing `track.artistName == "Art"` checks
  still pass via Optional comparison).
- Added conditional `Codable` (`where MusicItemType: Codable`) to
  `MusicCatalogResourceResponse` and `MusicRecentlyPlayedResponse`,
  delegating to the `MusicItemCollection` coding already in the repo.
- Re-pointed 96 `declared` rows at their exercising tests; readout of
  `MusicAuthorization.currentStatus` joins the existing
  `testAuthorizationStatus`.

| status | before | after |
| --- | ---: | ---: |
| implemented | 1248 | 1344 |
| declared | 176 | 80 |
| deferred | 0 | 0 |
| unavailable | 0 | 0 |
| not-applicable | 1110 | 1110 |

Nondeferred: **1424** (floor 1267), unchanged in total. Gain is
**+96 implemented** with zero new tests: `testLibraryFilterProtocols`
(47), `testCatalogFilterProtocols` (25), `testMusicItemCoreProtocols`
(15), `testRecentlyPlayedRequestAndResponses` (8), plus `currentStatus`
joining `testAuthorizationStatus`.

Top-5 evidence distribution (1344 implemented rows):

1. `test:full/musickit/tests/agent/MusicKitItemTests.swift#testPlaylistAndVideo` — 169 (12.6%)
2. `test:full/musickit/tests/agent/MusicKitEnumTests.swift#testEnumRawValues` — 158 (11.8%)
3. `test:full/musickit/tests/agent/MusicKitItemTests.swift#testSupportingTypes` — 99 (7.4%)
4. `test:full/musickit/tests/agent/MusicKitBehaviorTests.swift#testPlayerQueue` — 75 (5.6%)
5. `test:full/musickit/tests/agent/MusicKitItemTests.swift#testArtistGenreStation` — 72 (5.4%)

Enum / option-set members share `testEnumRawValues`. No other single test
is cited by more than 40% of the remaining implemented rows
(40% cap after the enum table = 474.4; largest non-enum is 169).

All 45 agent test functions (including the four newly cited ones) were
compiled with `-warnings-as-errors` and executed green locally against
the edited sources.

## Depth pass 2026-09 (wave 10, declared-ceiling audit + host-portability fix)

Audited all 80 remaining `declared` rows identifier by identifier
(demangled via length-prefixed-word scan of each precise ID and checked
against product sources): every one is an `async`/`async throws` API or an
async `PropertyContainer.with` requirement/witness, so none can move to
`implemented` under the sealed-gate rules (no `await`, no semaphore waits,
no invented network/hardware/service success):

- 11× `response()` (catalog/library/charts/search/suggestions/
  resource/recently-played/personal-recommendations/data) — network.
- `MusicPlayer.play` / `prepareToPlay` / `skipToNextEntry` /
  `skipToPreviousEntry` + 4× async `Queue.insert` — playback hardware.
- 6× `MusicLibrary.add` / `createPlaylist` / `edit` — service.
- `DefaultMusicTokenProvider.developerToken`,
  `MusicUserTokenProvider.userToken`, the `DeveloperTokenProvider`
  protocol requirement — service identity.
- `MusicAuthorization.request()`, `MusicItemCollection.nextBatch`,
  `MusicDataRequest.currentCountryCode`, `MusicSubscription.current`,
  `Subscription.Updates.Iterator.next()` — service/async.
- 4× `PropertyContainer.with` requirements + ~42 synthesized `with`
  witnesses — async.

Also verified coverage integrity by script: all 1344 `implemented` rows
cite an existing top-level synchronous `func test*()` (45 distinct tests,
zero missing, zero `await` in cited bodies); all 80 `declared` rows cite
an existing `source:` anchor in the guest manifest; the enum-table test
sits at 158 rows and the largest non-enum test at 169, under the 40% cap
(474.4). Spot-checked the 17 apparent identifier/call mismatches — all
are exercised via helper probes or `Music`-prefixed names, not misses.

Host-portability fix (no coverage change): `MusicKitLookalikes.swift`
stand-ins (`CGColor`, `AnyPublisher`/`ObservableObject`, `View` et al.)
are now also used on Apple hosts (`|| os(macOS)`). Previously the macOS
`swiftc` host build failed because `canImport(CoreGraphics/Combine/
SwiftUI)` is true there while no product file imports those modules —
and the code cannot compile against the real modules (`Artwork: Hashable,
Codable` vs non-Hashable/non-Codable `CGColor`; zero-argument
`AnyPublisher()` vs real Combine). Linux semantics are unchanged. The
sealed `test_host.sh` runner itself is Linux-only (`import Glibc`), so
validation on this Mac ran the gate's exact steps with the mechanical
`Glibc` → `Darwin` substitution: 11 product sources and 17 test files
compile under `-warnings-as-errors`, all 45 cited tests execute, and the
runner prints only `MUSICKIT_AGENT_RUNTIME_OK`.

| status | before | after |
| --- | ---: | ---: |
| implemented | 1344 | 1344 |
| declared | 80 | 80 |
| deferred | 0 | 0 |
| unavailable | 0 | 0 |
| not-applicable | 1110 | 1110 |

Nondeferred: **1424** (floor 1267). Gain is **+0 implemented**: the
sync-testable surface is fully converted; the declared remainder is the
async/network/hardware floor. Files changed: `MusicKitLookalikes.swift`
(3 guard lines + comments), `README.md` (this section).

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
