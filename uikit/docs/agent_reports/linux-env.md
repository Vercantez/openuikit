# Linux-env — four environment faults a Linux VM could not pass

Follow-up to `docs/agent_reports/linux-trial.md` (origin/agent/linux-trial).
This round did **not** close an iOS-oracle pixel gap. It makes the agent
loop runnable inside `docker exec uikit-linux` (`swift:6.2-noble`, Swift
**6.2.4**, `aarch64-unknown-linux-gnu`) without zsh, without PIL/numpy
preinstalled, without `/System/Library/Fonts/SFNS*.ttf`, and with
`swift build --build-tests` linking.

`/src` in the container is still a read-only mount of a **different**
tree. Every proof below used `tar --exclude=.build --exclude=Package.resolved`
into `/agent` (not `/src`). `SIM_DEVICE_SUFFIX=-linux-env`.

## Gates (must not drop)

| gate | before (trial / main) | after |
|---|---|---|
| Catalyst `compare.py` Mac | 124/124 | **124/124** (`/tmp/gate-linux-env`) |
| Catalyst in `uikit-linux` + SFNS | trial 124/124 with `docker cp` fonts | **124/124** (`OPENUIKIT_FONT_DIR=/agent/fonts`) |
| iOS suite `SKIP_CAPTURE=1 /tmp/ios_suite` | 112/113 (`corner_radius`) | **112/113** (`corner_radius` 99.411, blob 1.0) |
| real-app iPhone 16 @3x | 99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 / 82.192 / 99.760 / 99.689 / **85.393** | same (no drop) |

## Fault 1 — five agent scripts were zsh

**Trial:** `bash scripts/gen_conformance_registry.sh` died at zsh glob
`*(/N)` (line 19). The image has no zsh. Registry was hand-written.

**Fix:** `gen_conformance_registry.sh`, `ios_suite.sh`,
`conformance_flow.sh`, `hillclimb.sh`, `agent_merge.sh` are
`#!/usr/bin/env bash` (directory scan instead of `*(/N)`; bash arrays;
`if [ ! -f ]` instead of a brace-group that `bash -n` rejected). Capture
still shells out to zsh simulator probes. `SKIP_CAPTURE=1` is the Linux
replay. `hillclimb.sh` still `exec zsh scripts/agent_fanout.sh` (Mac
launch). `ConformanceRegistryTests` invokes `/usr/bin/env bash`. On
Linux, Foundation `Process` hangs (measured: 60 s `timeout` at
`waitUntilExit` even with stdin=`nullDevice`); the regenerating test
uses `Glibc.system("bash '…' '…'")` instead.

**Prove** (`docker exec -w /agent uikit-linux`):

```
bash -n scripts/gen_conformance_registry.sh scripts/ios_suite.sh \
  scripts/conformance_flow.sh scripts/hillclimb.sh scripts/agent_merge.sh
bash scripts/gen_conformance_registry.sh /tmp/Registry.swift
diff -u Sources/ConformanceApps/Registry.swift /tmp/Registry.swift
# wrote 7 app(s): Feed, Forms, Modal, NavFlow, Pager, TableEditor, Tabs
# byte-identical

SKIP_CAPTURE=1 OPENUIKIT_FONT_DIR=/agent/fonts \
  bash scripts/conformance_flow.sh /tmp/conformance-NavFlow NavFlow
# NavFlow mean 98.969, worst 98.196 (6 captures)
```

Without `OPENUIKIT_FONT_DIR`, openhost aborts on the first unharvested
glyph (`OPENUIKIT_IOS_INK_MISS`) — that is fault 3, not a script bug.

## Fault 2 — Tools/compare needs PIL + numpy; image has neither

**Trial:** `ModuleNotFoundError: No module named 'PIL'`. Apt-get inside
the running container (PIL 10.2.0, numpy 1.26.4).

**Fix:** `scripts/linux_setup.sh` (root, idempotent: zsh, python3-pil,
python3-numpy, python3-pip, libsdl2-dev, pkg-config).
`Dockerfile.linux-agent` is `FROM swift:6.2-noble` + that script. No
SFNS (not redistributable). `linux_realapp_verify.sh` image default is
`openuikit-linux-agent`; the inner script runs `linux_setup.sh` if PIL
or zsh is missing.

**Prove:**

```
bash scripts/linux_setup.sh
# linux_setup: PIL 10.2.0 numpy 1.26.4
# zsh 5.9 (aarch64-unknown-linux-gnu)

docker build -f Dockerfile.linux-agent -t openuikit-linux-agent .
# linux_setup: ok

OPENUIKIT_FONT_DIR=/agent/fonts OPENUIKIT_BACKEND=quartz \
  ./.build/release/openrender render /tmp/gate-linux-env fixtures/scenes/*.json
python3 Tools/compare/compare.py --out /tmp/gate-linux-env | tail -1
# 124/124 scenes pass
```

## Fault 3 — no SFNS on a Linux VM; iOS cut used to blank labels

**Trial:** `linux_verify.sh` copies `/System/Library/Fonts/SFNS*.ttf`
from the Mac. A Linux VM has none. Missing glyphs drew nothing.

**Fix (iOS cut only):** `UILabel.drawGlyph` / `AttributedTextDraw` select
the iOS table via `GlyphInkTable.hasIOSTable(scale:)` even when Catalyst
`glyph_ink.json` is absent. A mask **hit** draws with no TTF. A mask
**miss** with `glyphFont == nil` is `fatalError("OPENUIKIT_IOS_INK_MISS: \(key)
…")`. Ineligible path (non-integer size / non-axis-aligned CTM) with no
font is the same prefix plus a reason. `OPENUIKIT_INK_LOG=1` still
collects keys without aborting.

Measured tables (2026-09-05): `glyph_ink_ios.json` **6152** keys (2x);
`glyph_ink_ios_3x.json` **848** keys. "Hello" at 17 pt regular F0.0 is a
HIT for H/e/l/o. "Q" (U+0051) has metrics but is **not** in the 2x table
(U+2603 sizeToFits to width 0 and never draws — do not use it as the
miss probe).

**Still requires a font file:** Catalyst goldens; rotated/scaled CTMs;
non-integer point sizes; any (family, size, appearance, phase, scalar)
cell not in those JSON files — the 3x table is not a full alphabet, so
`openrender realapp` at scale 3 still needs `OPENUIKIT_FONT_DIR` for
unharvested glyphs.

**Prove** (no `OPENUIKIT_FONT_DIR`):

```
OPENUIKIT_FORCE_IOS=1 OPENUIKIT_BACKEND=quartz \
  ./.build/release/openrender render /tmp/inkprobe/hit-out /tmp/inkprobe/hit.json
# linux_ink_hit.png: 505 pixels with alpha>200 (Hello 17 pt)

OPENUIKIT_FORCE_IOS=1 OPENUIKIT_BACKEND=quartz \
  ./.build/release/openrender render /tmp/inkprobe/miss-out /tmp/inkprobe/miss.json
# Fatal error: OPENUIKIT_IOS_INK_MISS: I|system-regular|17|light|F0.0|81
```

## Fault 4 — `swift build --build-tests` on Linux 6.2.4

**Trial:** `@MainActor` XCTestCase vs nonisolated `setUp`/`tearDown`
(`CoreAnimationCompatibilityTests.savedTime`). After wrapping only
setUp, discovery still crashed: swift-corelibs-xctest casts methods to
`(T) -> () throws -> Void` and `@MainActor` test methods trap. Linux
6.2.4 also emits `[#ActorIsolatedCall]` as **errors** even with
`-swift-version 5`.

**Fix:**

- `#if !os(Linux) / @MainActor / #endif` on XCTestCase subclasses and
  remaining test-module `@MainActor` helpers (Darwin keeps isolation).
- Linux test `swiftSettings`: `-swift-version 5`,
  `-strict-concurrency=minimal`, `-warn-concurrency`.
- `Package.swift` evaluates `#if os(Linux)` **before** `Package()`:
  SwiftUITests compiles only `SwiftUILinuxStub.swift` (Darwin still
  compiles the full tree). Discovery of `@MainActor` SwiftUI tests
  crashed the **whole** bundle, including `SelectorNameTests`.
- `CanvasBackdropFilterTests.forEachBackend`: Darwin body is
  `@MainActor (RenderBackend) -> Void`; nested `fixture()` is
  `@MainActor` on Darwin so `setPixel` type-checks.
- Linux-only compile nits already needed for the bundle: bash generator;
  `CGFloat.greatestFiniteMagnitude` / `CGPoint.zero`;
  `AnyClass` identity via `AnyObject`; `@objc` behind
  `canImport(ObjectiveC)`; `@UIApplicationDelegateAdaptor` off Linux.

**Run (not just build):** `swift test` still blocks in `poll()` with no
TTY. The unfiltered `OpenUIKitPackageTests.xctest` process also hangs in
`poll()` (0 CPU) — 3/3 launches this session, at a **different** class
each time (AnimationTests, AdaptivePresentationDelegateTests). That is
the pre-existing Swift 6.2.4 XCTest flake (`docs/PORTABILITY.md`), worse
on the full bundle than on GeometryTests. `linux_realapp_verify.sh`
therefore:

1. `swift build --build-tests` (the trial's red)
2. two small comma-lists under `timeout 60` with 4 retries (selector
   set from `linux_selector_verify.sh`; ink / CA / registry / stub /
   ABITests)

**Prove:**

```
rm -f Package.resolved && swift build --build-tests
# Build complete!

BUNDLE=$(swift build --build-tests --show-bin-path | tail -1)/OpenUIKitPackageTests.xctest
timeout 60 "$BUNDLE" OpenUIKitTests.GlyphInkTableTests,OpenUIKitTests.CoreAnimationCompatibilityTests,OpenUIKitTests.ConformanceRegistryTests,OpenUIKitTests.GeometryTests,OpenUIKitTests.ColorTests,OpenUIKitCTests.ABITests,SwiftUITests.SwiftUILinuxStubTests
# Selected tests: Executed 52 tests, with 0 failures (0.459 s)
```

Mac: `swift test --filter GlyphInkTableTests --filter CoreAnimationCompatibilityTests --filter ConformanceRegistryTests` → 51 tests, 0 failures.

## Open

- Unfiltered Linux XCTest process hang (image flake). Per-class timeout
  still hits it (ActionModelTests hung at `testMenuSectionsSplitOnInlineChildren`
  at 20 s; the same class finishes in isolation on a later launch).
- 3x real-app without SFNS: harvest more `glyph_ink_ios_3x.json` or keep
  `OPENUIKIT_FONT_DIR`.
- Guest DateFormatter / `libswift_StringProcessing` (trial items 5 and
  GATE_B) — unchanged, out of scope.
- `/src` still mounts main, not the agent's worktree.

## Files

- `scripts/gen_conformance_registry.sh`, `ios_suite.sh`,
  `conformance_flow.sh`, `hillclimb.sh`, `agent_merge.sh`
- `scripts/linux_setup.sh`, `Dockerfile.linux-agent`,
  `scripts/linux_realapp_verify.sh`
- `Sources/OpenUIKit/{GlyphInkTable,UILabel,AttributedTextDraw,GlyphRasterizer}.swift`
- `Package.swift`, `Tests/SwiftUITests/SwiftUILinuxStub.swift`,
  Linux isolation wraps under `Tests/`
- `docs/PORTABILITY.md`, `docs/REAL_APP_TEST.md`, this report
