# ShazamKit Linux starting point

This directory is a fail-closed portable `ShazamKit` module for the OpenUIKit
Linux platform, reconstructed from the sealed Xcode 26.1 iPhoneOS symbol graph
(219 exact public identifiers). It is not Apple behavioral parity and is not
wired into the shared guest package.

Product sources `import Foundation` only. `AVAudioPCMBuffer`, `AVAudioTime`,
`AVAsset`, `Song`, and `UTType` belong to other modules and stay deferred.

## What is real

- **Errors.** `SHError.Code` uses the pinned macios integers (100, 101, 200,
  201, 202, 300, 301, 400, 500, 600). `SHErrorDomain` is the literal
  `SHErrorDomain`. `CustomNSError`, equality, hashing, and `Code ~= error`
  work in-process. Localized copy is host English.
- **Media items.** `SHMediaItem(properties:)` stores a dictionary. Typed
  accessors, subscript, UUID `Identifiable`, genres/time-range defaults, and
  `init(coder:)` returning `nil` are exercised. `SHMatchedMediaItem` carries
  confidence / frequency skew / match offset; `predictedCurrentMatchOffset`
  is `matchOffset` plus elapsed time since the match was recorded.
- **Custom catalog.** `SHCustomCatalog` stores reference signatures and media
  items, round-trips a host-local `OpenUIKit.SHCustomCatalog.v1` property list,
  and matches by exact `dataRepresentation` bytes. Invalid bytes throw
  `customCatalogInvalid`; missing URLs throw `customCatalogInvalidURL`.
- **Sessions.** `SHSession.match(_:)` notifies the weak delegate
  synchronously. Custom-catalog hits produce `SHMatch`; misses call
  `didNotFindMatch` with a `nil` error. The default Apple catalog always
  reports `matchAttemptFailed`. `SHSession.Result` cases construct. `Results`
  is an empty `AsyncSequence` (no microphone); `result(from:)`,
  `Results.Iterator.next()` / `next(isolation:)`, and the `AsyncSequence`
  consumers (`allSatisfy`, `max`, `min`, `first`, `reduce`, `reduce(into:)`,
  `contains(where:)`) are awaited on empty/local data. `SHSignature.Slices`
  likewise: `Slices.Iterator.next()` / `next(isolation:)`, `contains`, and
  the same consumers are awaited on empty slices.
- **Managed session / library.** `SHManagedSession` starts `.idle`; `cancel()`
  returns to `.idle`; `prepare()` enters `.prerecording` and `result()`
  fail-closes with `matchAttemptFailed`, both awaited. `SHLibrary.default.items`
  is empty; `addItems` / `removeItems`, `SHMediaLibrary.add`, and
  `SHMediaItem.fetch` throw their fail-closed errors under `await`.

## Fail-closed boundaries

| Surface | Linux behavior |
| --- | --- |
| Apple Shazam catalog | `matchAttemptFailed`; never a fabricated hit |
| `SHMediaItem.fetch` | throws `mediaItemFetchFailed` |
| `SHLibrary` / `SHMediaLibrary` mutations | throw `mediaLibrarySyncFailed` |
| Signature slicing | non-empty windows throw `signatureDurationInvalid` |
| Empty signature data | `signatureInvalid` |
| PCM / `AVAsset` ingest | deferred (no AVFoundation) |
| `songs` / `UTType` overlays | deferred (MusicKit / UniformTypeIdentifiers) |
| `init(coder:)` | returns `nil`; `supportsSecureCoding` is false |

## Tests

`tests/agent/ShazamKitLoadSmoke.swift` is the schema-v2 marker probe.
Focused `*Tests.swift` functions are the coverage evidence. The sealed runner
is `@main async` and `await`s each cited `async test*` once with no run loop;
no `DispatchQueue.main`, `RunLoop`, or semaphore waits.

## Depth pass 2026-09

Coverage: **211 implemented** / 0 declared / 6 deferred / 0 unavailable /
2 not-applicable (213 nondeferred, floor 176). Wave 2026-09-15 recount: counts
unchanged (183/28/6/2 of 219). pi-wave6 2026-09-15 recount: before 183/28/6/2,
after 183/28/6/2 (gain 0). pi-wave8 2026-09-15 recount: before 183/28/6/2,
after 183/28/6/2 (gain 0). pi-wave9 2026-09-15 recount: before 183/28/6/2,
after 183/28/6/2 (gain 0; compiler probe confirms sync tests cannot call the
async APIs: `'async' call in a function that does not support concurrency`). pi-wave10 2026-09-15 recount: before 183/28/6/2,
after 183/28/6/2 (gain 0; fresh swiftc probes re-confirm: sync callers of `result(from:)`, `addItems`, `Iterator.next`, and `contains(where:)` fail with `'async' call in a function that does not support concurrency`, and the ObjC completion-handler spellings `fetchMediaItem`/`addMediaItems` have no Swift member since Apple surfaces those IDs async-only, so no sync `test*` can cite them). pi-wave11 2026-09-15 recount: before 183/28/6/2,
after 183/28/6/2 (gain 0; re-verified: all 9 product-level declared symbols are `async` in source, the other 19 are stdlib `AsyncSequence` consumers/iterators whose mangled names contain `Ya` (async), product `swiftc -emit-library` build clean, all 183 implemented test anchors resolve, no banned `await`/semaphore/RunLoop patterns in cited tests; host gate's shared validator refuses on missing `full/framework-roadmap/framework-roadmap.json`, a pre-existing worktree-level issue unrelated to this framework). pi-wave12 2026-09-15 recount: before 183/28/6/2,
after 183/28/6/2 (gain 0; re-probed `result(from:)` in sync context -> `'async' call in a function that does not support concurrency`, manual @main runner over all 137 unique cited tests prints RUNNER_OK, product emit-library clean, no SwiftUI overlay rows in this framework so the overlay OVERRIDE is vacuous). All 28 declared rows are `async` product APIs
(`fetch`, library `add`/`addItems`/`removeItems`, `prepare`/`result`,
`SHSession.result(from:)`, both `Iterator.next` variants) or `async`
`AsyncSequence` consumers, so none converts to implemented under the
no-`await` sealed gate. The 6 deferred rows need AVFoundation / MusicKit /
UniformTypeIdentifiers outside this seed's Foundation-only dependencies. pi-wave13 2026-09-18 recount: before 183/28/6/2,
after 211/0/6/2 (gain +28; the sealed runner is now `@main async` and awaits
`async test*`, so all 28 formerly-declared `async` rows convert: 9 product
`async` APIs (`fetch`, library `add`/`addItems`/`removeItems`,
`prepare`/`result`, `SHSession.result(from:)`, both `Iterator.next` variants)
plus 4 protocol `next`/`next(isolation:)` witnesses plus 15 `AsyncSequence`
consumers (`allSatisfy`, `max`, `min`, `first`, `reduce`, `reduce(into:)`,
`contains(where:)`, `contains`), each awaited on empty/local data in the new
`tests/agent/SHAsyncAwaitTests.swift` (28 async tests, all complete without
microphone/network/daemons); manual @main-async runner over all 165 unique
cited tests prints RUNNER_OK, product `swiftc -emit-library` build clean,
no SwiftUI overlay rows in this framework so the overlay OVERRIDE is vacuous).
The 6 deferred rows still need AVFoundation / MusicKit /

Top-5 evidence distribution (implemented rows):

1. `testSHErrorCodeRawValues` — 22 (enum cases, static Code aliases, `init(rawValue:)`)
2. `testSHMediaItemPropertyConstants` — 18 (C `SHMediaItem*` constants)
3. `testSHManagedSessionStateCases` — 4 (enum members)
4. `testSHErrorErrorDomain` / `testSHErrorErrorUserInfo` / `testSHErrorErrorCode` — 2 each (bridged + CustomNSError witnesses)
5. All remaining implemented tests — 1 or 2 rows each

No non-enum test exceeds 40% of the remaining implemented rows (cap 55).
