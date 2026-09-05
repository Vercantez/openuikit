# Guest trial — a new app through the arm64-apple-macos guest Foundation

Ninth conformance app `Sources/ConformanceApps/Ledger/`. Same UIKit source as
the others (UIKit + Foundation). This round does **not** close an iOS-oracle
pixel gap: it asks whether a **new** app that uses the Foundation the guest
just gained compiles and renders on the real Linux authority with no Mac
in the build/run loop.

Window 375×667 scale 2 (conformance / iPhone SE). Guest realapp capture is
the first screen at iPhone 16 393×852 @3x (`realapp_ledger_light`), the
13th `GUEST_REALAPP_SCREENS` row.

## What the app exercises

| API | Where it shows |
|---|---|
| `NumberFormatter` currency `en_US` | trailing amount (`$1,234.50`) |
| `NumberFormatter` currency `de_DE` | subtitle (`1.234,50` + U+00A0 + `€`) |
| `DateFormatter` `dateStyle = .medium` | subtitle date (`Sep 4, 2026`) |
| `ISO8601DateFormatter` `.withInternetDateTime` | section header + Export alert (`2026-09-04T10:30:00Z`) |
| `DateComponentsFormatter` abbreviated h+m | Payroll `2h 15m`, Bookshop `45m` |
| `JSONSerialization` round trip via `UserDefaults` Data | header `json ok` |
| `NSRegularExpression` case-insensitive | search query `Coff` → one row, Coffee Lab |
| `URLSession.data(for:)` vs 127.0.0.1 | sixth row `Loopback FX` / `$12.50` / `· fx` |

The HTTP server is POSIX `socket`/`bind`/`listen`/`accept` on `127.0.0.1:0`
inside the app (`LedgerLoopbackServer`). No external network. Guest
`Stream.swift` has no socket destination — that is measured, not guessed.

Guest `URLSession` has async `data(for:)` and **no** `URLSessionDataTask`
(`full/foundation/URLSession.swift`). Apple and corelibs have both. The
app uses `data(for:)` plus a `DispatchSemaphore` wait so `openrender`
(no run loop) still fills the row before first layout.

## Why Ledger sources are duplicated

`full/scripts/build_full.sh` globs

```
RealAppProbe/*.swift
RealAppProbe/Vendored/*.swift
RealAppProbe/Vendored/*/*.swift
RealAppProbe/Focus/*.swift
RealAppProbe/Hackers/*.swift
```

and lives **outside** `uikit/`. This branch must not edit it. Ledger's
first-screen sources therefore exist twice, byte-identical:

* `Sources/ConformanceApps/Ledger/LedgerStore.swift` + `LedgerListViewController.swift`
  (confprobe / `openhost --app Ledger`)
* `Sources/RealAppProbe/LedgerStore.swift` + `LedgerListViewController.swift`
  (guest `render_full realapp` + SwiftPM `openrender realapp`)

`LedgerScreens.swift` is harness-only (the Focus/Hackers pattern): it
appends `realapp_ledger_light` to `RealAppScreen.screens`.

## Mac measurements (Apple Foundation, this worktree)

`openhost --app Ledger --script --record /tmp/ledger-mac`, window 375×667
scale 2, `SDL_VIDEODRIVER=dummy`. 8/8 captures.

| capture | action | layout fact |
|---|---|---|
| t200 | (rest) | 6 rows; header **`2026-09-04T10:30:00Z · json ok`**; Coffee Lab **`$4.50`** / **`Sep 4, 2026 · 4,50\u00a0€`**; Payroll **`$1,234.50`** / **`2h 15m`** / **`1.234,50\u00a0€`**; sixth row **Loopback FX `$12.50`** |
| t1200 | push | detail body includes USD/EUR, medium date, ISO8601 |
| t2100 | done | 6 rows again |
| t4000 | type-search `Coff` | **1** row, Coffee Lab (NSRegularExpression) |
| t5000 | cancel-search | 6 rows |
| t6000 | export | alert message **`2026-09-04T10:30:00Z`** |
| t7000 | confirm-export | alert dismissed |

`openrender realapp /tmp/app-guest-trial` emitted **13** PNGs including
`realapp_ledger_light` (6 `LedgerTableCell`s, card height 552 = 6×92).

Existing real-app floors held (no Ledger golden yet; operator captures):

99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 /
82.170 / 99.760 / 99.689 / 85.393.

Catalyst **124/124**. iOS suite **112/113** (known `corner_radius` 99.411).
`swift test --filter ConformanceRegistryTests` 7/7.

## Linux corelibs (`swift:6.2-noble`, no Mac Swift)

`docker run --rm -v "$PWD":/src:ro` cannot `cp -r /src /work` when `.build`
contains a dangling symlink (`cp: cannot read symbolic link '/src/.build/release'`).
Passed with `tar --exclude=.build --exclude=Package.resolved` as linux-trial.

Then two compile misses, both in `LedgerStore.swift` on the RealAppProbe
copy (openrender does not link ConformanceApps):

1. **`SOCK_STREAM` is `__socket_type` on Glibc**, not `Int32`.
   `socket(AF_INET, SOCK_STREAM, 0)` is a type error. Passed with
   `Int32(SOCK_STREAM.rawValue)` under `#if os(Linux)`. Darwin keeps
   `SOCK_STREAM`.
2. **`URLRequest` / `URLSession` are not in Linux Foundation.** They live
   in `FoundationNetworking`. `import Foundation` is not enough.
   `canImport(FoundationNetworking)` is the split. Apple and the guest
   facade put those types on Foundation itself, so the extra import is a
   no-op there.

After those two, `swift build -c release --product openrender` **green**
(174.92 s). No `Package.resolved` committed.

`linux_realapp_verify.sh` now expects **13** PNGs and skips
`realapp_ledger_light.png` in the Mac-vs-Linux sha256 compare: formatter
pixels are Apple vs corelibs, not a raster identity.

## Guest route — what the app still lacks (compile-time, before the box)

These are read off `full/foundation/`, not guessed:

* **No `URLSessionDataTask` / `dataTask(with:completionHandler:)`.**
  Only async `data(for:)` / `data(from:)`. A UIKit app written against
  Apple's data-task API will not compile on the guest without a rewrite.
* **No socket `Stream` / `InputStream(url:)`.** The loopback server is
  POSIX. An app that uses `CFSocket` or Network.framework `NWListener`
  is a different stack (Network.swift's `NWListener.start` is documented
  as not accepting).
* **`NumberFormatter` / `DateFormatter` / `ISO8601DateFormatter` /
  `DateComponentsFormatter` are not `NSObject` subclasses** on the guest
  (Apple's are). Passing them as `AnyObject` / KVC will not type-check.
* **Locale tables are the six sampled identifiers** (en_US_POSIX / en_US /
  en_GB / de_DE / fr_FR / ja_JP). Other identifiers fall back to English
  names / en_US currency (foundation-oracles.md).
* **`NSRegularExpression` is the `_StringProcessing` engine** already
  linked into `render_full` (`-lswift_StringProcessing`). App source must
  still avoid `String.contains(String)` / `Regex` literals of its own
  (GATE_B, 54be0035). Calling the Foundation type is the allowed path.
* **Cannot add Ledger as `RealAppProbe/Ledger/*.swift`.** The guest glob
  has no `Ledger/` directory. A future pin bump of `build_full.sh` could
  drop the duplicate.

## Guest verify (arm64 box)

Graded only by `queue_box.sh arm64 verify <sha>` log lines
(`TBD_CHECK_OK`, `difftest rc=0`, `build_full rc=0`, `GATE_B_PASS`,
`GUEST_REALAPP_SCREENS`). Filled in after the push.

Attempt 1: *(pending)*

## What the operator captures on the iOS simulator

* `scripts/conformance_probe_sim.sh Ledger /tmp/conformance-Ledger/golden`
  — 8 rest frames vs `openhost --app Ledger`.
* `scripts/realapp_probe_sim.sh` — now compiles `LedgerScreens.swift` +
  the two duplicated sources, so `realapp_ledger_light` lands next to
  the Focus/Hackers goldens. `compare_realapp.py` already has the
  `UITableView` anchor; there is no floor until that golden exists.
