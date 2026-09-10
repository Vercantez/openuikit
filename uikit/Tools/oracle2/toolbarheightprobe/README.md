# toolbarheightprobe — UIToolbar height oracle (iOS 26.1)

One-file probe app (`main.swift`, no Xcode project). From `uikit/`:

```sh
SIM_DEVICE_SUFFIX=-mybranch scripts/toolbar_height_probe_sim.sh /tmp/tb            # iphone16 se ipad
SIM_DEVICE_SUFFIX=-mybranch scripts/toolbar_height_probe_sim.sh /tmp/tb iphone16   # one device
```

Builds with `swiftc -target arm64-apple-ios26.0-simulator`, creates
`OpenUIKit-ToolbarHeight-<device><suffix>` (iPhone 16 / iPhone SE 3rd gen /
iPad A16, iOS 26.1), installs, launches with `--console-pty`, waits for a
`DONE` marker, copies `toolbarheight.json` out of `Documents/` as
`<outdir>/toolbarheight-<device>.json`, then shuts the device down and
deletes it. The app measures portrait, rotates itself with
`UIWindowScene.requestGeometryUpdate(.iOS(interfaceOrientations:
.landscapeLeft))` (iPad: same numbers, regular × regular), measures again,
writes `DONE` and exits. Each phase rewrites the JSON so a late crash keeps
the earlier rows.

Unedited transcripts: `ios-26.1-iphone16.json`, `ios-26.1-se.json`,
`ios-26.1-ipad.json` (2026-09-10).

## Rows

Top level: `os`, `device`, `idiom`, `screen`, `scale`, `cold.*` (a bar made
before any window exists — what a unit test sees), then `portrait` and
`landscape`, each with:

- `window`, `windowSafeArea`, `traits` (`horizontal`/`vertical` size class
  raw values: 1 compact, 2 regular; `idiom` 0 phone, 1 pad), `hostSafeArea`.
- `frame.<style>.<items|noItems>` — `detached` (never hosted), `hosted44`
  / `hosted54` / `hosted64` (frame-based bar of that height in a live view,
  with `.tree`), `zeroFrame.sizeToFit`. Every entry is a `sizes` block:
  `intrinsic`, `sizeThatFits.w0` (width × 0), `sizeThatFits.w100`,
  `sizeThatFits.zero`, `systemLayout.compressed` / `.expanded` /
  `.wRequired`, `frame`, `traits`.
- `autoLayout.<style>.<items|noItems>.<viewBottom|safeAreaBottom>` — a bar
  pinned leading / trailing / bottom with NO height constraint, read in the
  turn that added it; `autoLayout.later.*` the same bars one run-loop turn
  later; `autoLayout.deferred.*` app-like paths: `addedThenWaited.*` (no
  synchronous layout in the adding turn), `viewDidLoad.viewBottom` (bar
  constrained inside a controller's `viewDidLoad`, controller made the
  window root), `viewDidLoad.afterInvalidate` (after
  `invalidateIntrinsicContentSize` + layout).
- `navigation.<style>.<items|noItems>` — a `UINavigationController` made
  the window root with `isToolbarHidden = false`; `toolbarFrame`,
  `toolbarSuperview` (**nil on iOS 26.1** — the `toolbar` object is not in
  the hierarchy and its `items` stay nil), `sizes`, `rootViewFrame`,
  `rootSafeArea`, `rootSafeAreaLayoutFrame`, `navBarFrame`, and
  `bottomViews`: every view at any depth whose window-space frame reaches
  into the bottom 140 pt — the bar UIKit really shows (an
  `_UIInheritedView` slot with `UIPlatformGlassInteractionView` platters).

`<style>` is `default` / `black` (`UIBarStyle`); no number differs between
them or between items / no items except the platter row's existence.

## Table (all three devices)

| | intrinsic / sizeThatFits | Auto Layout frame h | platter row | free margin | nav slot (window) | child SA.bottom |
| --- | --- | --- | --- | --- | --- | --- |
| iPhone 16 portrait (393×852, SA 59/34) | 48 | 48 | 48, y 0 (y −2 in a 44 bar) | 16 | `[0, 766, 393, 86]`, platters y 776 x 28 | 86 (34 without items) |
| iPhone 16 landscape (852×393, SA 59 sides / 20) | 48 detached, **44 hosted** | **48** (44 only after invalidate) | 44 | 126 (600 pt row) | `[59, 311, 734, 82]`, platters y 321 x 87 | 82 (20) |
| iPhone SE 3 portrait (375×667, SA 20/0) | 48 | 48 | 48 | 16 | `[0, 581, 375, 86]`, platters y 591 x 28 | 86 (0) |
| iPhone SE 3 landscape (667×375, SA 0) | 48 detached, 44 hosted | 48 | 44 | 20 | `[0, 293, 667, 82]`, platters y 303 x 28 | 82 (0) |
| iPad A16 either (820×1180, SA 32/25) | 44 (cold too) | 44 | 44 | 20 | `[0, 1101, 820, 79]`, platters y 1111 x 10 | 79 (25) |

Slot = 10 + platter + 28 on a phone regardless of the home-indicator inset;
10 + 44 + 25 on the pad. `systemLayoutSizeFitting(compressed)` reads
`[0, 0]` for a hosted bar WITH items and `[W, 48]` without — recorded, not
modelled.
