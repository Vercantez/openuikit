# Combine and os package products

17 of 20 ladder apps `import Combine` from packages outside
`Sources/RealAppProbe`, and 13 `import os` for `Logger`. On Linux
corelibs an ingested SwiftPM package could not resolve either as a
product of OpenUIKit. This branch publishes both.

No rendering rule changed. Catalyst **124/124**, iOS suite **112/113**
(known `corner_radius` 99.411), real-app screens unchanged.

## What was measured (`scratch/ladder-corpus`, 2026-09-05)

20 apps: duckduckgo-ios, eidolon, eigen, element-ios, firefox-ios,
focus-ios, Hackers, home-assistant-ios, ios-oss, mastodon-ios,
NetNewsWire, nextcloud-ios, pocket-casts-ios, ProtonMail-ios,
Signal-iOS, simplenote-ios, Telegram-iOS, vlc-ios, wikipedia-ios,
WordPress-iOS.

### Combine

| | count |
|---|---|
| apps with `import Combine` | **17/20** (not eidolon, NetNewsWire, simplenote-ios) |
| those files under a local `Package.swift` tree | **357** files in 10 apps |

Most common symbols in those 357 files: `AnyPublisher` (325),
`eraseToAnyPublisher` (186), `AnyCancellable` (154),
`ObservableObject` (63), `PassthroughSubject` (57),
`CurrentValueSubject` (47), `sink` (29), `Future` (27), `Fail` (23),
`Just` (10).

Before: `Package.swift` had a `Combine` *target* (OpenCombine re-export)
used only as `.target(name: "Combine", condition: .when(platforms: [.linux]))`
by SwiftUI / RealAppProbe. `Tools/ingest/xcodeproj_to_package.py`
classified `import Combine` as `port: None` ("OpenUIKit's Combine target
is not a package product"). Focus Blockzilla's ingest `no_port` list
included Combine.

After: `.library(name: "Combine", targets: ["Combine"])`. Linux compiles
the existing OpenCombine aliases (`Sources/Combine/Combine.swift` under
`#if os(Linux)`). Darwin dependents keep the SDK module —
generated packages list
`.product(name: "Combine", package: "OpenUIKit", condition: .when(platforms: [.linux]))`.
Unconditional Darwin use of the product would import an empty module;
the ingest condition is the guard.

### os

| | count |
|---|---|
| apps with `import os` | **13/20** (202 files) |
| files with `import os.log` | 94 |
| files with `import OSLog` | 22 |
| files with `import os.signpost` | 3 |

Call shapes covered (accepted and ignored, except the lock which is real):

* `Logger(subsystem:category:)` — Hackers
  `Data/Sources/Data/PostRepository+Parsing.swift:14`, NetNewsWire
  `Account.swift:94`, DuckDuckGo `Logger+Multiple.swift`
* `Logger()` — Pocket Casts `FileLog.swift:28`, `TracksAdapter.swift:245`
* methods: `.log` 787, `.info` 499, `.debug` 336, `.error` 206,
  `.warning` 51, `.notice` 6, `.fault` 2; `.log(level: .error, …)`
  (WordPress `CustomPostSettingsViewModel.swift:469`)
* interpolation `privacy: .public` (451) / `.private` (3) —
  NetNewsWire `Account.swift:366`
* `OSLog(subsystem:category:)` + `os_log("%@", log:type:)` and
  `os_log("%{private}@", …)` — Focus `NimbusWrapper.swift:57–68`
  (types `.debug` / `.info` / `.fault` / `.error`); `os_log("…")`
  without an OSLog — DuckDuckGo Autofill
* `OSAllocatedUnfairLock(initialState:)` — NetNewsWire `Cache.swift:24`,
  Hackers `DependencyContainer.swift:85`; `OSAllocatedUnfairLock()`
  (State == Void) then no-argument `withLock { … }` — nextcloud
  `NotificationService.swift:31, 127`; `withLock { $0 }` /
  `withLock { $0 = newValue }`
* `os_signpost(.begin/.end, log:name:signpostID:format, args…)` +
  `OSSignpostID(log:)` — DuckDuckGo `Core/Instruments.swift:46–63`

`withLockUnchecked` is not called in the corpus; it is Apple's
unchecked sibling of `withLock` and is implemented as the same mutex.

The lock is a `pthread_mutex`, not a no-op: 1000
`DispatchQueue.concurrentPerform` increments end at **1000** on Darwin
and on Linux Swift 6.2.4 (`OSAllocatedUnfairLockTests`).

## Prove

Throwaway `/tmp/combine-os-probe` depends on the OpenUIKit package and
`import Combine` / `import os`, compiling the call shapes above.

| host | Combine / os resolved to | result |
|---|---|---|
| macOS (Apple 6.2.1) | SDK (`condition: .linux` skips the products) | `combine-os-probe ok` (5.36 s) |
| `docker exec uikit-linux` (Swift 6.2.4) | OpenCombine + `Sources/os` | compiled Combine.swift + os + probe; `combine-os-probe ok` (7.21 s) |

Unit tests `swift test --filter OSTests`: 10/10 Darwin, 10/10
`docker exec -w /tmp/uikit-combine-product uikit-linux`.

Ingest MiniApp fixture: generated `Package.swift` lists Combine and os
with the Linux condition; `classify_module("Combine")` / `"os"` return
those product names (Foundation-heavy). `python3 Tools/ingest/test_xcodeproj_to_package.py`
34 ran, 20 skipped (corpus not in this worktree), 0 failed.

## Gates

| gate | result |
|---|---|
| Catalyst `compare.py` | **124/124** (`/tmp/gate-combine-product`) |
| iOS suite `SKIP_CAPTURE=1` | **112/113** (`corner_radius` 99.411, blob 1.0) |
| real-app iPhone 16 @3x | **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 / 82.170 / 99.760 / 99.689 / 85.393** |
| `docker run --rm -v … swift:6.2-noble` openrender | green (205.91 s) |
| `docker exec uikit-linux` probe + OSTests | green |

No `Package.resolved`. Nothing outside `uikit/`.

## Open (measured, not guessed)

* 94 files `import os.log` and 3 `import os.signpost`. Those are Darwin
  clang submodules. The SwiftPM product is the Swift module `os`;
  `import os` (202 files / 13 apps) is the contract. The ingest does
  not rewrite submodule imports.
* 22 files `import OSLog` (a separate Apple module). Not a product.
* Darwin `swift build --product Combine` builds the empty `#if os(Linux)`
  module. Dependents must keep the Linux condition so `import Combine`
  stays the SDK on macOS.
