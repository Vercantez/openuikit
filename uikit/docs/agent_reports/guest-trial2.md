# Guest trial 2 — Ledger on the Linux guest, no Mac in the loop

Continuation of `origin/agent/guest-trial` (214fc803,
`docs/agent_reports/guest-trial.md`). That branch added the ninth
conformance app Ledger and duplicated its first screen onto the
`RealAppProbe/*.swift` glob so `GUEST_REALAPP_SCREENS` becomes 13, but
every arm64 box run died on the Foundation guest manifest pin
(**41 vs 38**). Main has since fixed that in `full/scripts/build_full.sh`
(`c858e1f5`: app path expects 41). Ledger had not landed on main, so this
branch cherry-picks `16ee0569` onto current main and finishes the trial.

Scope is `uikit/` only. No pin files, no `full/`, no `scripts/vendor_pins.sh`.

## What this round asks

Whether Ledger's first screen (`realapp_ledger_light`) compiles and
renders on the arm64-apple-macos guest with **no Mac in the build/run
loop**, and which of these Foundation families actually produce their
on-screen strings there:

| API | Where it shows (Apple / SwiftPM, this Mac) |
|---|---|
| `NumberFormatter` currency `en_US` | `$4.50`, `$1,234.50` |
| `NumberFormatter` currency `de_DE` | `4,50\u00a0€`, `1.234,50\u00a0€` |
| `DateFormatter` `dateStyle = .medium` | `Sep 4, 2026` |
| `ISO8601DateFormatter` `.withInternetDateTime` | header / Export `2026-09-04T10:30:00Z` |
| `DateComponentsFormatter` abbreviated h+m | Payroll `2h 15m`, Bookshop `45m` |
| `JSONSerialization` + `UserDefaults` Data | header `json ok` |
| `NSRegularExpression` case-insensitive | t4000 query `Coff` → 1 row |
| `URLSession.data(for:)` vs 127.0.0.1 POSIX server | sixth row `Loopback FX` `$12.50` `· fx` |

Guest `URLSession` (`full/foundation/URLSession.swift`) has async
`data(for:)` / `data(from:)` and **no** `URLSessionDataTask`. The host
transport is curl (`openui_url_transport_v1_perform`). The loopback
server is POSIX `socket`/`bind`/`listen`/`accept` inside the app
(`LedgerLoopbackServer`). Whether those two meet on the guest is a
runtime measurement, not a guess.

## Wiring (unchanged from guest-trial; still the only in-scope path)

`full/scripts/build_full.sh` globs `RealAppProbe/*.swift` + Vendored +
Focus/ + Hackers/ and lives outside `uikit/`. Ledger first-screen
sources are therefore byte-identical in two places:

* `Sources/ConformanceApps/Ledger/` — `openhost --app Ledger` / confprobe
* `Sources/RealAppProbe/LedgerStore.swift` + `LedgerListViewController.swift`
  + `LedgerScreens.swift` — guest `render_full realapp` and SwiftPM
  `openrender realapp`

`RealAppScreen.screens` is the previous 12 plus `ledgerScreenTable`.

## Local measurements (this worktree, Apple Foundation)

`openhost --app Ledger --script --record /tmp/ledger-mac-gt2`, window
375×667 scale 2, `SDL_VIDEODRIVER=dummy`. 8/8 captures.

| capture | action | layout fact |
|---|---|---|
| t200 | (rest) | 6 rows; header **`2026-09-04T10:30:00Z · json ok`**; Coffee Lab **`$4.50`** / **`Sep 4, 2026 · 4,50\u00a0€`**; Payroll **`$1,234.50`** / **`2h 15m`**; sixth row **Loopback FX `$12.50`** / **`· fx`** |
| t1200 | push | detail `$4.50 / 4,50\u00a0€` + `Sep 4, 2026` + ISO8601 + `seed` |
| t4000 | type-search `Coff` | **1** row, Coffee Lab |
| t6000 | export | alert message **`2026-09-04T10:30:00Z`** |

`openrender realapp /tmp/app-guest-trial2` emitted **13** PNGs including
`realapp_ledger_light` (6 `LedgerTableCell`s).

Existing real-app floors held (no Ledger golden; operator captures):

99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 /
82.170 / 99.760 / 99.689 / 85.393.

Catalyst **124/124**. iOS suite **112/113** (known `corner_radius` 99.411).
`swift test --filter ConformanceRegistryTests` 8/8 (9 apps).
`swift:6.2-noble` `openrender` green (176.48 s; tar exclude `.build` /
`Package.resolved` because `cp -r` dies on the dangling `.build/release`
symlink). No `Package.resolved` committed.

Linux corelibs compile notes, carried from guest-trial and still true:

1. `SOCK_STREAM` is `__socket_type` on Glibc — `Int32(SOCK_STREAM.rawValue)`
   under `#if os(Linux)`.
2. `URLRequest` / `URLSession` live in `FoundationNetworking` on Linux.

## Guest compile-time gaps (read off `full/foundation/`, not guessed)

* **No `URLSessionDataTask` / `dataTask(with:completionHandler:)`.**
* **No socket `Stream`.** Loopback is POSIX.
* **Formatters are not `NSObject` subclasses** on the guest.
* Locale tables are the six sampled identifiers (foundation-oracles.md).
* App source must still avoid `String.contains(String)` / `Regex` literals
  (GATE_B, 54be0035). Calling `NSRegularExpression` is the allowed path.
* A future `build_full.sh` pin bump could glob `RealAppProbe/Ledger/` and
  drop the duplicate. Do not edit `full/` from this branch.

## Guest verify (arm64 box)

Graded only by `queue_box.sh arm64 verify <sha>` log lines
(`build_full rc=0`, `TBD_CHECK_OK`, `difftest rc=0`, `GATE_B_PASS`,
`GUEST_REALAPP_SCREENS=13`). Filled in after the push.

Attempt 1 (guest-trial, 16ee0569, recorded at 214fc803): `TBD_CHECK_OK`,
`difftest rc=0`, then `die 'Foundation guest source manifest must contain
exactly 38 lines'` (manifest is 41). `GUEST_REALAPP_SCREENS=0`,
`GATE_B_FAIL rc=2`. Fixed on main at `c858e1f5`.

Attempt 2 (`22320ade`): `BUILD_OK`, **`TBD_CHECK_OK`**, `run_linux rc=0`,
**`difftest rc=0`**, then **`build_full rc=1`**. RealAppProbe compiled;
link of `render_full` died on POSIX sockets in `LedgerLoopbackServer.start`:

```
ld64.lld-18: error: undefined symbol: _listen
ld64.lld-18: error: undefined symbol: _setsockopt
ld64.lld-18: error: undefined symbol: _socket
ld64.lld-18: error: undefined symbol: _bind
ld64.lld-18: error: undefined symbol: _getsockname
ld64.lld-18: error: undefined symbol: _accept
```

referenced by `realappprobe.o`. Guest `libSystem.tbd` advertises
`_getsockopt` (the linker suggested it) but not the listen/bind family.
`_close` / `_read` / `_write` were not in the undefined list. Gate B
`GATE_B_FAIL rc=1` (nested `build_full` same link). `GUEST_REALAPP_SCREENS=0`.

Fix (this commit): Darwin no longer calls `socket()` by name. The six
symbols are `dlsym(RTLD_DEFAULT)` lookups (`@_silgen_name("dlsym")`,
handle bitPattern −2 — same as FoundationExtensionHostOracle).
`LedgerStore.swift.o` now has `U _dlsym` / `_close` / `_read` / `_write`
and **no** `U _socket`. Linux corelibs still call Glibc directly.
Apple Mac openhost after the change still has Loopback FX `$12.50` (dlsym
finds Darwin `socket`). If guest `dlsym("socket")` is nil, `start()`
fails and `loopbackItem` still calls `URLSession.data(for:)` against
`http://127.0.0.1:1/quote` so the session is exercised.

Attempt 3 (`4284aa2d`): **`build_full rc=0`**, **`TBD_CHECK_OK`**,
**`difftest rc=0`**, **`GATE_B_PASS`**, then `GUEST_REALAPP_RC=133`
**`GUEST_REALAPP_SCREENS=12`**:

```
Fatal error: OPENUIKIT_IOS_INK_MISS: I|system-semibold|18|light|F0.0|83
```

Guest `realapp` is scale 2; `scratch/fonts` has no SFNS so a miss with
`glyphFont == nil` is fatal. Scalar 83 is `'S'`. `glyph_ink_ios.json` had
**no 18 pt keys** (sizes 10–15, 17, 19…).

MEASURED this Mac, `openrender realapp` scale 2 iOS cut with a temporary
label dump: Ledger's own strings are **17 semibold / 13 regular / 17
regular** (header ISO8601, merchants, `Sep 4, 2026`, amounts). The 18 pt
semibold run is Pocket Casts `SimpleActionView`
`UIFont.font(ofSize: 18, weight: .semibold, scalingWith: .headline)` —
`"Select Episodes"` starts with S at F0.0. `OPENUIKIT_INK_LOG` of all 13
screens named **69** `system-semibold|18` keys (those picker letters,
light+dark, F0.0/F0.5). History/settings/iPad pickers print them;
xxxl/ax1/xs do not (scaled off 18); Ledger's own render does not.

Guest wrote 12 PNGs, so those picker labels were not drawn on the first
12 screens (sheet present is guest-fragile) and the 13th hit the leftover
18 pt S. Two in-scope fixes:

1. `runRealApp` drops prior `realAppRetained` windows before the next
   screen so a leftover picker cannot be sampled.
2. Harvest the 69 keys on `OpenUIKit-2x-guest-trial2` / iOS 26.1
   (`SIM_DEVICE=2x` inkprobe, 69/69, skipped []). Table **6152 → 6221**.
   Catalyst still uses `glyph_ink.json`, not this file.

Attempt 4 (`a43f92cf`): **`build_full rc=0`**, **`TBD_CHECK_OK`**,
**`difftest rc=0`**, **`GATE_B_PASS`**, then `GUEST_REALAPP_RC=133`
**`GUEST_REALAPP_SCREENS=12`** again:

```
Fatal error: OPENUIKIT_IOS_INK_MISS: I|system-bold|13|light|F0.0|82
```

Scalar 82 is `'R'`. MEASURED `OptionsPickerRootController` section title
font `UIFont.font(ofSize: 13, weight: .bold, scalingWith: .footnote)` —
settings picker **"ROW ACTION"**. Same leftover-picker pattern as attempt
3, next unharvested cell.

Fix: harvest every remaining `I|` miss from a scale-2 `OPENUIKIT_INK_LOG`
of the 13 screens (372 keys; 369 masks; 3 skipped `U+00A0` "no ink" —
de_DE currency NBSP). Table **6221 → 6590**. UILabel / attributed draw
skip U+00A0 like SPACE (inkprobe: no coverage).

Attempt 5 (`77ccad18`): **`build_full rc=0`**, **`TBD_CHECK_OK`**,
**`difftest rc=0`**, **`GATE_B_PASS`**, `GUEST_REALAPP_RC=133`
**`GUEST_REALAPP_SCREENS=12`**:

```
Fatal error: OPENUIKIT_IOS_INK_MISS: I|system-regular|13|light|F0.75|36
```

Scalar 36 is `'$'`. On Apple Mac, Ledger USD (`$4.50`) is **17 pt
regular**; 13 pt regular had digits/euro/middot but no `$`. Guest drew
`$` at footnote size (formatter/layout difference, not guessed). Harvest
ASCII 33–126 at 13 pt regular light+dark × 8 phases on SE 2x / iOS 26.1
(943/943). Table **6590 → 7533**.

Attempt 6: *(pending this push)*

## What ran on Apple Foundation (this Mac), still unproven on the guest

Until attempt 4's layout/log, treat these as **Apple-side** facts:

| API | Apple Mac (openhost / openrender) | Guest (box) |
|---|---|---|
| `NumberFormatter` en_US / de_DE | `$4.50` / `4,50\u00a0€` | pending attempt 4 |
| `DateFormatter` `.medium` | `Sep 4, 2026` | pending |
| `ISO8601DateFormatter` | `2026-09-04T10:30:00Z` | pending |
| `DateComponentsFormatter` | `2h 15m` | pending |
| `JSONSerialization` + `UserDefaults` | header `json ok` | pending |
| `NSRegularExpression` | t4000 `Coff` → 1 row | not in first-screen render |
| `URLSession.data(for:)` loopback | `Loopback FX $12.50` · fx | `dlsym("socket")` may be nil; session still called on `:1` |
| BSD `socket` by name | links on Apple | **undefined** on guest tbd (attempt 2) |
| `dlsym("socket")` | finds Darwin | pending attempt 4 |

## x86 cycle

`queue_box.sh x86 cycle <sha>`, graded by `RUNG_SCOREBOARD a=PASS b=PASS
c=PASS`. *(pending)*
