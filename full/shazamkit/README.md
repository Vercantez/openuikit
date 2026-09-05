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
  is an empty `AsyncSequence` (no microphone).
- **Managed session / library.** `SHManagedSession` starts `.idle`; `cancel()`
  returns to `.idle`. `SHLibrary.default.items` is empty.

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
calls each cited `test*` once with no run loop; async APIs are `declared`
rather than awaited.

## Depth pass 2026-09

Coverage: **183 implemented** / 28 declared / 6 deferred / 0 unavailable /
2 not-applicable (211 nondeferred, floor 176).

Top-5 evidence distribution (implemented rows):

1. `testSHErrorCodeRawValues` — 22 (enum cases, static Code aliases, `init(rawValue:)`)
2. `testSHMediaItemPropertyConstants` — 18 (C `SHMediaItem*` constants)
3. `testSHManagedSessionStateCases` — 4 (enum members)
4. `testSHErrorErrorDomain` / `testSHErrorErrorUserInfo` / `testSHErrorErrorCode` — 2 each (bridged + CustomNSError witnesses)
5. All remaining implemented tests — 1 or 2 rows each

No non-enum test exceeds 40% of the remaining implemented rows (cap 55).
