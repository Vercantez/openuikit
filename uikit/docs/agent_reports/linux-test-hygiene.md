# Linux test-bundle hygiene for three pending ladder branches

LINUX PROGRAM. No new pixel rule. The operator's merge script now builds
`swift build --target OpenUIKitTests` in `swift:6.2-noble` (Linux strict
concurrency: test classes are `@MainActor` only under `#if !os(Linux)` —
project rule in `Tests/OpenUIKitTests/ActorIsolationTests.swift` — so a test
touching main-actor-isolated API must hop with `MainActor.assumeIsolated`;
and a test file that `import Foundation`s must write
`OpenUIKit.NotificationCenter.default`). Three ladder branches were written
before that gate. This round merges current `origin/main` into each,
makes `OpenUIKitTests` compile on Linux, keeps Catalyst **124/124** and
the iOS suite at main's **112/113** (`corner_radius` 99.411), and pushes
to the same branch.

`SIM_DEVICE_SUFFIX=-linux-test-hygiene`. Proofs used `docker exec uikit-linux`
(Swift **6.2.4**, `aarch64-unknown-linux-gnu`). `/src` is still a read-only
mount of a different tree; each branch was tar-copied (excluding `.build` /
`Package.resolved`) to `/work-linux-test-gestures`, `/work-linux-test-lists`,
`/work-linux-test-focus3`.

Fix scope: **test files only**, the two patterns above. No behaviour
changes. No `scripts/vendor_pins.sh`, `env/`, or `scripts/env/`. No
`Package.resolved`.

## `origin/agent/merge-gestures` → `7b1f287d`

Unique OpenUIKitTests files: `UIDragDropTests.swift`,
`PinchRotationHoverTests.swift`.

### Before (`docker exec uikit-linux`, Swift 6.2.4)

`swift build --target OpenUIKitTests` **RED**. Unique errors (same two
sites, reported once per compile job):

```
Tests/OpenUIKitTests/UIDragDropTests.swift:148:43: error: main actor-isolated static property 'active' can not be referenced from a nonisolated autoclosure
Tests/OpenUIKitTests/UIDragDropTests.swift:153:40: error: main actor-isolated static property 'active' can not be referenced from a nonisolated autoclosure
```

That is `XCTAssertNotNil(_UIDragDropCenter.active)` and
`XCTAssertNil(_UIDragDropCenter.active)` in
`testDragInteractionLiftAtMeasuredDuration`. Matches
`~/openuikit/scratch/merge_gestures46-merged.log`. Pinch / rotation / hover
/ edge-pan tests compiled without those two patterns.

### After

`MainActor.assumeIsolated { … }` around those two asserts (comment cites
this measurement). No source-file change.

- `swift build --target OpenUIKitTests`: **Build of target complete (2.29 s
  incremental / first red compile reached the UIDragDropTests errors)**
- `swift build -c release --product openrender`: **239.86 s**
- macOS `swift build --build-tests`: Build complete (24.80 s)
- `swift test --filter 'UIDragDropTests|PinchGestureTests|RotationGestureTests|HoverGestureTests|ScreenEdgePanTests'`:
  **17 tests, 0 failures**
- Catalyst **124/124** (`/tmp/gate-linux-test-hygiene-gestures`)
- iOS suite `SKIP_CAPTURE=1` **112/113** (`corner_radius` 99.411)
- real-app floors held: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 /
  98.133 / 97.516 / 99.65 / 82.17 / 99.86 / 99.734 / 85.393**
  (`realapp_ledger_light` / `realapp_focus_home_light` have no golden in
  `/tmp/golden_realapp_ios`; they were extra renders, not drops)

Pushed `origin/agent/merge-gestures`.

## `origin/agent/merge-lists` → `76987454`

Unique OpenUIKitTests file: `ListCellDiffableTests.swift` (`import Foundation`,
`#if !os(Linux) @MainActor` on the class).

### Before

`merge_lists46-merged.log` reached `==> Linux build` and finished
openrender; it did not print an OpenUIKitTests error list (the log was
still in the Linux step when this round started). After merging
`origin/main`, the unique test file was compiled as-is.

### After (no test-file edit)

`ListCellDiffableTests` does not name `NotificationCenter` and does not
read a main-actor-isolated static from an XCTAssert autoclosure, so
neither pattern applies.

- `swift build --target OpenUIKitTests`: **Build of target complete (37.61 s)**
  — **0** `error:` lines
- `swift build -c release --target ConformanceApps`: **191.42 s**
- `swift build -c release --product openrender`: **42.63 s** (warm)
- macOS `swift build --build-tests`: Build complete (76.01 s)
- `swift test --filter ListCellDiffableTests`: **9 tests, 0 failures**
- Catalyst **124/124** (`/tmp/gate-linux-test-hygiene-lists`)
- iOS suite `SKIP_CAPTURE=1` **112/113** (`corner_radius` 99.411)

Pushed `origin/agent/merge-lists`.

## `origin/agent/merge-focus3` → `20b8c5d2`

OpenUIKitTests delta vs main after the merge: Safari/PHPicker tests
remain behind this branch's `#if !os(Linux)`; `TextKitTests` /
`ValueTypeTailTests` add a `private typealias NotificationCenter =
OpenUIKit.NotificationCenter` on top of main's already-qualified
`OpenUIKit.NotificationCenter.default`. Other new tests (Fuzi, Glean,
Libkern, Sentry, SnapKit) are **other targets**, not `OpenUIKitTests`.
No `merge_focus46-merged.log` was present.

### Before / after (no test-file edit)

After merging `origin/main`, `swift build --target OpenUIKitTests` was
already green. Main's `MainActor.assumeIsolated` hops for Safari/PHPicker
live inside the Darwin-only region; the Linux bundle does not compile
those two tests. The NotificationCenter typealiases are redundant with
main's `OpenUIKit.` qualifications and do not conflict.

- `swift build --target OpenUIKitTests`: **Build of target complete (40.84 s)**
  — **0** `error:` lines
- `swift build -c release --target ConformanceApps`: **191.28 s**
- `swift build -c release --product openrender`: **32.71 s** (warm)
- macOS `swift build --build-tests`: Build complete (25.06 s)
- `swift test --filter 'SystemPickerTests|TextKitTests|ValueTypeTailTests'`:
  **38 tests, 0 failures**
- Catalyst **124/124** (`/tmp/gate-linux-test-hygiene-focus3`)
- iOS suite `SKIP_CAPTURE=1` **112/113** (`corner_radius` 99.411)

Pushed `origin/agent/merge-focus3`.

## What was not changed

- No OpenUIKit / quartz source.
- No Catalyst goldens, no iOS goldens, no layout dumps.
- No pin files. The operator advances the vendor pin on merge.
- `ListCellDiffableTests` and the focus3 extra test targets did not need
  the two patterns; if a later `--build-tests` image grows SDL2 and
  starts compiling SnapKit/Fuzi/Glean as well, that is a different gate.

This report is docs-only on `agent/linux-test-hygiene`.
