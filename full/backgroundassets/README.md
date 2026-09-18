# BackgroundAssets (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`BackgroundAssets` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol
graph, API digester, TBD exports, and pinned `dotnet/macios` bindings. It is
not wired into the shared guest package.

Linux has no Apple Background Assets daemon, app-group container, ExtensionKit
host, or CDN. Manager APIs that would talk to those services fail closed.

## What is real

- `BAContentRequest` raw values: `install = 1`, `update = 2`, `periodic = 3`
  (pinned macios `BAContentRequest`).
- `BADownload.State`: `failed = -1`, `created = 0`, `waiting = 1`,
  `downloading = 2`, `finished = 3`.
- `BAErrorCode` raw values match pinned macios (`downloadInvalid = 0`,
  `callFromExtensionNotAllowed = 50`, through
  `sessionDownloadNotPermittedBeforeAppLaunch = 206`). `BAErrorDomain` is
  `BAErrorDomain`.
- `BADownload.Priority` is a typed integer. Linux uses `min = 0`,
  `default = 5`, `max = 10` until an Apple-oracle observation of the Darwin
  constants lands.
- `AssetPack.Status` is an `OptionSet` with macios `BAAssetPackStatus` bits
  (`downloadAvailable = 1 << 0` through `downloaded = 1 << 6`). SetAlgebra
  arithmetic is real.
- `AssetPack` stores `id`, `downloadSize`, `version`, and `userInfo`, hashes
  those fields, and builds a `BAURLDownload` via `download(for:)`.
- `AssetPackManifest` parses JSON objects (`assetPacks`) or arrays, accepting
  `id` / `identifier` / `assetPackID` aliases, and round-trips through
  `Encodable`.
- `BAURLDownload` convenience and designated initializers store identifier,
  request, essential flag, file size, group, and priority. `state` starts at
  `.created`. `removingEssential()` returns a non-essential copy.
  `NSSecureCoding` round-trips top-level download and extension-info objects.
- `BADownloadManager.shared` exists. `fetchCurrentDownloads` returns an empty
  list (and the completion-handler overlay runs synchronously).
- `ManagedBackgroundAssetsError` carries `assetPackNotFound(withID:)` and
  `fileNotFound(at:)` with `LocalizedError` fields.
- Extension protocol defaults: `downloads` returns `[]`, `shouldDownload`
  returns `true` (matching Apple's documented managed default).

## Fail-closed boundaries

- `scheduleDownload` throws `callerConnectionInvalid` (or `downloadInvalid` for
  a non-https URL). No daemon accepts work.
- `startForegroundDownload` throws `downloadFailedToStart`.
- `cancel` throws `downloadNotScheduled`.
- `withExclusiveControl` (both overloads) invokes the handler immediately with
  `(false, callerConnectionInvalid)`.
- `AssetPackManager` file accessors (`contents`, `descriptor`, `url`) throw
  `fileNotFound`. Isolated async members throw `assetPackNotFound` or
  `callerConnectionInvalid` and are covered by `await`ed fail-closed tests.
- Actor isolation helpers (`assertIsolated` / `assumeIsolated` /
  `preconditionIsolated`) are exercised on-executor via `await`ed isolated
  helpers (`tests/agent/BackgroundAssetsActorIsolationTests.swift`); direct
  off-executor calls trap and direct `assumeIsolated` calls from `async`
  contexts are unavailable in Swift 6 language mode.
- Async authentication-challenge methods return
  `(.performDefaultHandling, nil)` and are covered by `await`ed tests that
  construct a `URLAuthenticationChallenge` with a test sender.
- `System.FilePath` / `FileDescriptor` are not importable on this Swift 6.2.4
  Linux toolchain. The module vends portable `FilePath` / `FileDescriptor`
  values used by the overlay signatures. ExtensionKit `AppExtension` is not a
  declared dependency; `BADownloaderExtension` does not inherit it.

## Depth pass 2026-09 (wave 14)

Implemented rows: **198**. Declared: **0**. Nondeferred: **198 / 198**.

Wave 14 converted the 3 remaining declared rows (synthesized
`AssetPackManager` actor-isolation helpers) with the sealed `@main async`
runner: `tests/agent/BackgroundAssetsActorIsolationTests.swift` drives
`assertIsolated` / `preconditionIsolated` on-executor through an isolated
`agentWithIsolatedCheck` helper and `assumeIsolated` on-executor inside an
isolated `agentVerifyAssumeIsolated` helper. Before: 195 implemented / 3
declared / 0 deferred. After: 198 implemented / 0 declared / 0 deferred.

## Depth pass 2026-09 (wave 13)

Implemented rows at the time: **195**. Declared: **3**. Nondeferred: **198 / 198**.

Wave 13 used the sealed `@main async` runner, which `await`s top-level
`func test*() async`, to convert 10 in-process async leftovers
(`tests/agent/BackgroundAssetsAsyncTests.swift`): the six isolated
`AssetPackManager` async members (immediate fail-closed throws) and the four
async `backgroundDownload` / `download` challenge overlays (immediate
`(.performDefaultHandling, nil)` via a test-constructed
`URLAuthenticationChallenge`). The 3 actor-isolation helpers were converted
in wave 14 (see above).

## Depth pass 2026-09 (wave 12)

Wave 12 re-examined the 13 leftover declared rows: 0 convertible. Six are
`AssetPackManager` isolated `async` members, three are async
`backgroundDownload(_:didReceive:)` challenge overlays, one is the async
`BADownloadManagerDelegate` challenge overlay, and three are synthesized
actor-isolation helpers that trap off the actor. The sealed runner only
invokes top-level synchronous no-argument `test*` functions with no `await`,
so async members stay `declared` and fail closed.

Top-5 evidence distribution (implemented rows):

1. `testAssetPackStatusSetAlgebra` — 24 (SetAlgebra / OptionSet methods)
2. `testErrorCodeRawValues` — 20 (enum members; table-driven exempt)
3. `testAssetPackStatusMembers` — 11 (option-set members; table-driven exempt)
4. `testAssetPackValueAndHashable` — 11
5. `testDownloaderExtensionDefaults` — 11

No non-enum/option-set/constant test exceeds 40% of the remaining implemented
rows after those table-driven families are excluded.
