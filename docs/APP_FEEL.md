# M7.5 — "Real UIKit feel" demo app (USER PRIORITY)

> **STATUS (2026-08-24): SHIPPED.** Everything below is implemented,
> including the back-swipe stretch goal. Launch:
>
>     swift run -c release openhost --app demo
>
> (from the repo root; `OPENUIKIT_BACKEND=quartz` optional — quartz is the
> default. `--scale 2` for crisp HiDPI at lower frame rates, see
> "Performance" at the bottom.) Scripted acceptance capture:
>
>     swift run -c release openhost --app demo --scale 2 \
>         --script scripts/appfeel_demo.json --record out_host
>
> Result GIF: scripts/appfeel_demo.gif. What shipped vs the spec, plus
> measured performance, is summarized at the end of this file.

The user's goal: an app built ON OpenUIKit that feels like a genuine iOS app.
Feel-first milestone; oracle fidelity for these behaviors follows where
measurable. Prerequisite: M7 host + events (openhost, hit testing, controls).

## The demo app

`Sources/DemoApp` — a real multi-screen Settings-style app written against
OpenUIKit like a normal UIKit app (UIViewController subclasses), launched with
`swift run openhost --app demo` (openhost gains an app-hosting mode: instead of
a scene JSON, it boots a UIApplication-lite with a root view controller).

Screens:
1. **Root**: nav bar ("Settings"), SCROLLABLE list of grouped rows (more rows
   than fit on screen), profile card, toggles, disclosure rows.
2. **Display & Brightness**: slider-ish control (progress-style drag), toggle
   group, back navigation.
3. **About**: static labels, long scrollable text block.
Tap a disclosure row → push with slide transition; back button (and back-swipe
if feasible) → pop.

## The physics that make it feel real (implement EXACTLY)

### UIScrollView (the single biggest feel factor)

> **M8 UPDATE (2026-08-24): every constant below is now MEASURED against
> real iOS UIKit** — see "Measured scroll physics" at the end of this file.
> Values that survived measurement unchanged: 0.998/ms deceleration rate,
> rubber-band c = 0.55. Values corrected by measurement: deceleration stop
> threshold (0.1 → **10 pt/s**), position curve factor (continuous integral
> 0.4995 → per-ms geometric sum **0.499**), bounce spring (single 0.5 s
> critically-damped ω = 18.47 → **two regimes: ω = 11 critically damped
> with velocity; λ = 9/46 overdamped from rest**), and slop handling (the
> recognizing event applies travel − 10 pt immediately).

- Tracking: content follows the finger 1:1 while dragging.
- Velocity: from the last ~100ms of touch samples at release.
- Deceleration: UIKit's `decelerationRate = .normal` = **0.998 per millisecond**
  (v(t) = v0 * 0.998^t_ms; stops dead at 10 pt/s). Position:
  x(t) = x0 + v0·0.499·(1 − 0.998^t_ms).
- Rubber-band overscroll (Apple's formula):
  `offset' = (1 - 1/(c*|offset|/dim + 1)) * dim * sign(offset)` with c = 0.55,
  dim = scroll view dimension. Applies while dragging past the edge.
- Bounce-back: spring to the boundary on release — critically damped ω = 11
  seeded with the release velocity; overdamped λ = 9/46 when released from
  a held (velocity ≈ 0) overscroll.
- Deceleration into an edge → bounce with carried velocity.
- Scroll indicator: 2.5pt rounded bar, appears while scrolling, fades ~0.4s
  after settle, insets 3pt from edge.
- contentOffset/contentSize/contentInset API like UIKit; touch delay: a
  touch-down inside a scroll view waits ~150ms (or until movement > slop)
  before delivering touch-down to subviews (UIScrollView delaysContentTouches);
  movement cancels subview touches and starts the pan.

### Navigation transitions
- Push (0.35s, UIKit's transition curve ≈ easeInOut): incoming VC slides from
  +width → 0; outgoing slides 0 → **−30% width** underneath with a subtle
  darkening scrim (black 0→8% alpha) and a 9pt soft shadow on the incoming
  edge. Pop = exact reverse.
- Nav bar: 44pt content bar; title crossfades/slides with the push; back
  chevron ("‹" style, tintColor) + previous title as the back button label.
- Interactive back-swipe (stretch goal): left-edge pan (start < 20pt from
  edge) scrubs the pop transition; release beyond 50% or with velocity
  completes, else cancels.

### Row/touch feel
- Table-style rows highlight on touch-down (after the content-touch delay)
  with systemGray4 flash; fade out ~0.3s after touch-up; tap fires after
  highlight is visible (UIKit lets the highlight paint first).
- Buttons: pressed title alpha per the M7 measured value.
- All state changes animate with UIView.animate (already exact vs oracle).

## Oracle strategy (fidelity second pass, feel first)
- Scroll deceleration/rubber-band: **DONE (M8)** — measured for real, from
  synthetic-touch traces of real iOS UIKit (see "Measured scroll physics"
  below); the constants above are the measured ones and the trace gates run
  in Tools/compare/compare_scroll.py.
- Nav transition curves: capture a real UINavigationController push in oracle2
  with the M6 time-sampling mechanism if feasible; otherwise match the spec
  above and refine later.

## Acceptance
- `swift run openhost --app demo` opens the app; scrolling feels iOS-native
  (finger-tracking, momentum, bounce), rows highlight, pushes/pops slide with
  parallax + scrim, switches animate, back button works.
- A scripted-event capture (openhost --script) records a GIF of: scroll flick
  with bounce, row tap → push, toggle a switch, pop back. Frames verified.
- Static/animation suite (52+ scenes) stays green throughout.

## What shipped (2026-08-24)

Everything in this spec, plus:

- **Sources/DemoApp** is its own library target under the same
  no-Foundation rules as OpenUIKit — it doubles as the reference for what
  idiomatic OpenUIKit app code looks like (UIViewController subclasses,
  addTarget closures, UIView.animate for every state change).
- Settings root: profile card + 16 rows in 4 inset-grouped cards
  (row-component helper `SettingsRow`: 29pt icon tile / title / accessory
  = chevron | value+chevron | static detail | UISwitch), content ≈ 910pt
  vs a 716pt viewport so flick physics always engage.
- Icon tiles are hand-drawn Canvas paths (airplane, wifi, bluetooth,
  cellular, battery, bell, speaker, moon, hourglass, gear, toggles, sun,
  grid, person, shield, info) — there are no SF Symbols in the portable
  stack.
- Display & Brightness: True Tone / Night Shift / Raise to Wake switch
  rows + a UISlider-look brightness slider (4pt track, tint fill, 28pt
  shadowed thumb) dragged by a UIPanGestureRecognizer, with a live
  percentage footnote.
- About: static value rows + a 7-paragraph scrollable colophon.
- Row highlight ships exactly as specced: systemGray4 on touch-down
  (post-delaysContentTouches; a quick tap gets it on the touch-up flush,
  like UIKit), 0.3s UIView.animate fade after up/cancel, tap action firing
  after touchesBegan has painted the highlight. Finger travel past
  `UIScrollView.contentTouchCancelDistance` (5pt) along a scrollable axis
  cancels the press in that very event — before the pan crosses its own
  10pt slop, so the row is already fading when the content starts to move
  (M8.1; travel along a non-scrollable axis keeps the press).
- Interactive back-swipe (the stretch goal) shipped in the navigation
  milestone and works on every pushed screen of the demo.
- Host improvements that came out of this milestone: `openhost --app demo`
  (UIApplication-lite boot), layout-before-draw (window.layoutIfNeeded()
  before every rendered frame, matching UIKit's commit), and dirty-flag
  rendering (below).

Not done (honest list): no large-title nav bar (fixed 64pt bar), no status
bar content, no blur behind the bar, slider has no tap-to-jump (drag only,
as specced),
About value rows use a plain static style rather than UIKit's exact
About-table metrics.

## Performance (measured 2026-08-24, Apple M3 Max, release build)

Dirty-flag rendering: the live loop renders ONLY when an input event
arrived, a finger is down, a scroll is decelerating/bouncing, a navigation
transition is in flight, or the host clock is before
`OpenUIKitRuntime.animationWorkDeadline` (a new runtime hint fed by
UIView.animate recording and UISwitch.setOn). An idle app renders zero
frames.

During a sustained scroll every frame is dirty. M8 layer-contents caching
(LayerBridge.swift + quartz patch 004) makes those frames cheap:

- **Content-image cache**: each view's drawContent offscreen (glyph ink,
  icon paths, control chrome) is kept on the view and reused while its
  content fingerprint is unchanged. Custom views must call
  `setNeedsDisplay()` when their drawContent inputs change (UIKit's own
  contract); OpenUIKit's views are fingerprinted property-by-property.
- **Subtree composite cache**: a subtree whose visual fingerprint stays
  stable for two consecutive frames is flattened once into a premultiplied
  composite; scrolling then blits cached card/screen bitmaps (snapped to
  the device grid, 1-tap unit-scale image path). Navigation transitions
  become two screen-composite blits after their first ~2 frames.
- **Offscreen culling**: subtrees fully outside the viewport are skipped.
- **quartz patch 004**: unit-scale (±mirrored) image blit fast path,
  axis-aligned rect fill/clip fast paths (docs/QUARTZ_PATCHES.md).

Sustained-scroll cost, Settings root, 60-frame scripted deceleration
(scripts/perf_scroll.json; `captured … render X ms` lines):

| scale | before (M7.5) | after (M8 caching) | sustained |
|-------|---------------|--------------------|-----------|
| 2     | ≈ 145 ms avg  | ≈ 8.7 avg / 6.9 p50 ms | 60 fps |
| 1     | ≈ 39 ms avg   | ≈ 3.0 avg / 2.2 p50 ms | 60 fps |

**--app mode now defaults to --scale 2** (crisp) again. Known remaining
spikes: the first 1–2 frames after a hierarchy change (fresh screen push,
cold caches) re-render and flatten at full cost (~40–80 ms at scale 2);
frames whose fingerprints change every frame (slider drag, switch toggle
row) render direct — both bounded to small subtrees or short bursts.
Fidelity: settled frames are bit-identical with caching on/off
(`OPENUIKIT_LAYER_CACHE=off` to A/B); mid-flight scroll frames differ only
in that cached blits are snapped to the device pixel grid (≤ half-pixel,
crisper than the resampled uncached path). The 56-scene golden suite is
unaffected (single-frame renders never reach two stable frames).

### Push transition cost, measured 2026-08-24 (scripts/perf_push.json)

A fresh push at scale 2 (`--app demo`, tap "Display & Brightness", capture
every frame at 60 fps) costs, per frame of the 0.35 s transition:

| transition frame | render | what it does |
|------------------|--------|--------------|
| 1 (+7 ms)  | ≈ 62 ms | both screens direct; incoming caches cold |
| 2 (+23 ms) | ≈ 55 ms | incoming re-rendered again to BUILD its composite |
| 3 … end    | ≈ 24 ms | incoming is one blit; **outgoing still direct** |
| after the highlight fade ends | ≈ 3 ms | everything cached |

The interesting number is the third row. The steady 24 ms is not the
incoming screen at all — it is the OUTGOING one: the tapped row runs its
0.3 s highlight fade, an animating `backgroundColor` salts the row's
fingerprint every frame, and that invalidates its whole ancestor chain
(row → GroupCard → UIScrollView → screen root), so the settings screen
re-composites its 11 cached cards at the fractional parallax offset for
the entire transition. Fixing that (partial subtree composites, so a card
can flatten the rows that are NOT animating) is worth more than anything
left on the incoming side.

**Pre-warming the incoming screen at push time was measured and
rejected** (2026-08-24). Building its composite inside
`pushViewController` moves ~53 ms into the event step to save ~37 ms on
frame 1 and ~34 ms on frame 2 — in a live host, where the push and the
first frame share one loop iteration, that makes the first displayed
frame WORSE (62 → 77 ms). The cheaper variant (mark the fresh subtree
flatten-eligible so frame 1 builds the composite instead of frame 2)
costs nothing at push time and does take frames 1+2 from 117 ms to 84 ms,
but it turns the first post-push frame into a composite blit, which moved
0.9 % of the acceptance capture's mid-transition pixels (mean 1.28, max
42 of 255, all on AA edges — visually identical, not byte-identical). It
is parked on the byte-stability gate, not on the numbers; note that a
blit is arguably what real CA does mid-transition, so an oracle-sampled
push (still open, see KNOWN_GAPS) could settle which one is correct.
Either way the first frame's ~35 ms of fresh rasterization is irreducible
work, not redundant work — pre-warming can only move it.

### Inset-grouped table scroll cost, measured 2026-08-25

The M10 showcase app (`--app showcase`, scripts/perf_showcase_table.json)
does NOT hold 60 fps at scale 2:

| screen (scale 2, M3 Max) | ms/frame | notes |
|---|---|---|
| demo Settings (M8 baseline) | 7.0 | 5 composite hits / 6 direct layers |
| showcase Settings (large title + tab bar) | 17.9 | the scroll-edge pocket is a Gaussian blur recomputed per observed offset |
| showcase Tasks table | 22.5 (6.2 at scale 1) | 15 hits / 9 direct |

Two findings, one fixed and one not:

- **FIXED — a scaled-down subview poisons its whole cell.** The Tasks
  checkbox used to rest its "unchecked" fill at `scale(0.01)`. A
  non-translation transform anywhere in a subtree makes that subtree
  ineligible for the layer composite cache, so every visible row
  re-rasterized from scratch on every scrolled frame (74 direct layers,
  28.9 ms). The rest state now HIDES the fill instead (hidden subtrees are
  skipped outright): 12 direct layers, 21.5 ms. This is a general trap for
  app code — animate a scale, but do not *rest* at one.
- **NOT FIXED — an empty section card is a single view, and single views
  never flatten.** `compositeLayer` requires `viewCount >= 2`, so the
  inset-grouped section backgrounds (358 pt wide, up to 412 pt tall,
  26 pt corner radius) are re-rasterized as antialiased rounded rects every
  frame. The demo Settings screen is fast precisely because its cards
  CONTAIN their rows, so each card is a cached composite. Relaxing the
  guard to `viewCount >= 2 || v.layer.cornerRadius > 0` was measured: the
  table drops from 20.0 to 9.2 ms/frame (2.2x, comfortably 60 fps) and the
  golden suite still passes 80/80. It is **parked on byte-stability**, the
  same gate that parked the M7.6 push pre-warm: 11 animation-golden frames
  (anim_delay, anim_spring_bounce, anim_spring_move) stop being
  bit-identical with `OPENUIKIT_LAYER_CACHE=off`, because a flattened leaf
  blits snapped to the device pixel grid while a direct render rasterizes
  at the fractional presentation position. A rounded-rect fill fast path in
  quartz (patch 004 only covers axis-aligned rects) would buy the same win
  with no fidelity question, and is the better fix. Owner: perf/quartz.

## Measured sheet interaction (M11, 2026-08-25)

The M10 modal presentation shipped the sheet's *mechanics* (slide-up, dim,
geometry) but none of its *behaviour*. That behaviour is now implemented, and
like the scroll physics before it, **every constant is measured from real iOS
UIKit rather than guessed**.

Ground truth: `Tools/oracle2/sheetprobe`, run by
`scripts/sheet_probe_sim.sh <outdir>`. It is the sibling of SimProbe (scroll):
a real iOS app in a headless iPhone 16 / iOS 26.1 simulator that presents a
live `UISheetPresentationController`, drives it with synthetic UITouch drags
(the same KIF-style delivery as the scroll traces, `scrollshared.swift`), and
samples the sheet's frame and the dimming view's presentation opacity every
display-link frame. Mac Catalyst cannot do this at all — it bridges a
pageSheet into an AppKit sheet window (see `Tools/oracle2/simscene/main.swift`).

Implementation: `UISheetPhysics` in Sources/OpenUIKit/UIPresentation.swift.
Regression gate: `Tests/OpenUIKitTests/SheetInteractionTests.swift` (15 tests,
each asserting a measured number).

### Measured values (iOS 26.1, iPhone 16, 393 x 852)

| quantity | MEASURED | evidence |
|---|---|---|
| sheet rest frame | **(0, 59, 393, 793)** | live frame read off the presentation; the M10 golden fit said 59.5, and switching to 59 improved `modal_sheet` 99.233 → 99.324 |
| dim | `UIDimmingView`, black at **alpha 0.2** exactly | view-hierarchy dump |
| drag tracking | **1:1 after exactly 10 pt of slop** | 180/240/320/360/380 pt of finger travel → 170/230/310/350/370 pt of sheet, at every distance. Same rule as UIScrollView's pan |
| upward drag | **nothing happens — no rubber band** | 180 pt of upward drag on a large-detent sheet: frame unchanged, dim unchanged. This contradicts the natural guess; iOS simply refuses to move a sheet above its detent |
| dim vs. drag | **alpha = 0.2·(1 − offset/height)**, linear | residual vs. that model ≤ 0.0025 over four full drags (display-link sampling lag) |
| dismiss distance | **> 50 % of the sheet's height** | 370 pt springs back, 398/402 pt dismiss on a 793 pt sheet (50 % = 396.5) |
| ...and it is PROPORTIONAL | **yes, not a fixed distance** | a 400 pt custom detent springs back from 170 pt and dismisses from 210 pt — a fixed ~396 pt rule would never dismiss it |
| dismiss velocity | **≥ 1000 pt/s** downward | at 64 pt of travel (8 % — far under the distance rule): 875/900/925/950/975 pt/s all spring back, 1000 pt/s dismisses |
| release spring | **critically damped, ω = √(1000/3) = 18.2574** | free fits of three independent releases: 18.251 / 18.256 / 18.258, rms error **0.02–0.05 pt** over the whole curve. Both outcomes — spring-back and completing dismissal — use the same spring, seeded with the release velocity |
| grabber | **36 × 5 pt, corner radius 2.5, 5 pt below the sheet top, centred at x 178.5 (no rounding)** | agreed by two independent routes: the live hierarchy reports `_UIGrabber [178.5, 64.0, 36.0, 5.0] r=2.5`, and the rendered golden's ink spans exactly x 178.5…214.5, y 64.0…69.0 |
| grabber colour | **(197, 197, 200)** over white = systemFill's base gray (120, 120, 128) at **alpha 0.4295** | solved per channel from `golden/modal_sheet_grabber`; the blue channel independently confirms it (predicted 200.4, measured 200.0) |
| grabber default | **hidden** (`prefersGrabberVisible` defaults to false) | which is why `golden/modal_sheet` has none and `golden/modal_sheet_grabber` does |
| sheet ↔ inner scroll view | at contentOffset.top, a **downward** drag moves the SHEET (contentOffset stays 0); otherwise the CONTENT scrolls and the sheet stays put | two mirrored traces, each showing the other party unmoved |

### Notes

- The two recognizers gate themselves on that hand-off condition from
  opposite sides. OpenUIKit has no `require(toFail:)` dependency system
  (docs/KNOWN_GAPS.md), so the rule is written twice — once in
  `_UISheetPanGestureRecognizer.allowBegin`, once in
  `UIScrollViewPanGestureRecognizer.allowBegin` — rather than expressed once.
- ω = √(1000/3) is a mass-3 / stiffness-1000 critically damped spring. The
  closed form is evaluated directly (like UIScrollView's bounce) rather than
  routed through `UIView.animate`'s duration-fit solver, which cannot express
  a fixed ω once the release carries velocity.
- The release velocity uses UIScrollView's measured 100 ms trailing window.
  That window is **not** separately measured for sheets: the probe's drags run
  at constant velocity, so every estimator agrees and the traces cannot
  distinguish them.
- Detents were measured but **not implemented** — see docs/KNOWN_GAPS.md for
  what the probe found and why it was deferred.

## Measured scroll physics (M8, 2026-08-24)

The UIScrollView constants were originally "documented/well-established"
values. They are now **measured from real UIKit** and corrected where they
diverged. Ground truth: golden/scroll_traces/*.json (schema + provenance in
golden/scroll_traces/SCHEMA.md); regression gate:

    python3 Tools/compare/compare_scroll.py        # 9/9 traces pass

which replays each trace's input stream through OpenUIKit headlessly
(`openrender scrolltrace`) and diffs offset timelines. Gates: drag /
rubber-band ≤ 1 pt, deceleration ≤ 2 pt over the full trace (after a
±20 ms alignment — real UIKit starts the decel animation ~1 frame after
the lift; the one oracle frame straddling the lift is excluded because its
recorded timestamp lags its animation evaluation by ~0.5 ms, which alone
reads as ~2.4 pt at 4875 pt/s), bounce settle time within 10%.

### How the measurement works

- **Oracle**: `scripts/scroll_probe_sim.sh` builds
  Tools/oracle2/simprobe (a tiny iOS app sharing
  Tools/oracle2/scrollshared.swift), boots a headless iPhone 16 / iOS 26.1
  simulator — **real iOS UIKit**, not Catalyst — and synthesizes UITouch
  drags in-process (KIF-style private setters +
  `UIApplication.sendEvent`). Touch timestamps are stamped on an ideal
  8 ms grid, so UIKit's velocity estimator sees exactly the scripted
  velocity (willEndDragging reports it to 7 significant digits).
  contentOffset is sampled per frame (CADisplayLink + scrollViewDidScroll).
- **Why not the Mac Catalyst oracle**: measured first and rejected —
  Catalyst UIScrollView only scrolls via the POINTER path (Mac feel:
  landing distance ∝ v^1.37, rubber-band factor ~0.07) and never applies
  touch-pan translation. Those traces are kept in
  golden/scroll_traces/catalyst_pointer/ as documentation of the
  divergence. `Tools/oracle2/run.sh scroll <outdir>` reproduces them.

### Measured values (iOS 26.1)

| quantity | old (documented) | MEASURED | evidence |
|---|---|---|---|
| pan slop | ~10 pt, zeroed at recognition | 10 pt, recognizing event applies travel − 10 immediately | touch_calib: 180 pt travel → 170 pt offset, every decel release offset |
| release velocity | trailing ~100 ms of samples | confirmed (offset-space; also seeds the bounce) | bounce_release_vel spring seed ≈ −900 pt/s = trailing-window offset velocity, not the −1750 pt/s finger velocity |
| deceleration rate | 0.998/ms | **0.998/ms exact** | v(t) fits all four flicks 750–4875 pt/s; duration = ln(v0/10)/\|k\| within 1.5% |
| decel position curve | v0·(e^{kt}−1)/k (factor 0.49950) | **v0·0.499·(1−e^{kt})** (per-ms geometric sum r/(1−r)/1000) | all four targetContentOffsets match (v0−10)·0.499 within 0.3 pt; integral form misses by ~5 pt |
| decel stop | below 0.1 pt/s | **at 10 pt/s, tail never delivered** | constant ~4.99 pt shortfall vs full integral across velocities |
| rubber band | c = 0.55, dim = viewport | **confirmed exact** | pointwise fits converge to c = 0.5522…0.550 out to 590 pt overshoot; both edges identical |
| bounce (with velocity) | critically damped, ω = 18.47 (0.5 s settle eq.) | **critically damped, ω = 11.0** | edge_impact overshoot peak v/(ωe): predicted 100.5 pt vs measured 99.7 pt at v = 3005 pt/s; settle times within 5% |
| bounce (from rest) | same spring | **overdamped, λ = 9.0 / 46.0 s⁻¹** | 235 pt rest releases: tail decays at a constant 9.0/s (a critical spring's decay keeps accelerating — cannot fit); rms 4 pt over the full curve, settle within 3% |

Notes:
- The two bounce regimes are selected at |v₀| = 50 pt/s
  (`UIScrollPhysics.bounceRestVelocityThreshold`). A single linear spring
  provably cannot fit both measured curves; whatever UIKit does internally,
  these two closed forms reproduce it within the gates (rest-release
  mid-curve is the loosest at ~±14 pt of 235 pt; settle time and both
  velocity-seeded curves are within a few pt).
- The oracle quantizes contentOffset to the device pixel grid (1/3 pt at
  3×); OpenUIKit does not quantize. That bounds several gates (drag err
  0.16 pt = half a device pixel).
- willEndDragging velocity is in pt/ms and equals the finger velocity; the
  deceleration integrates the release velocity measured from the trailing
  ~100 ms of applied offsets (equal for steady drags).

Implementation: `UIScrollPhysics` in Sources/OpenUIKit/UIScrollView.swift.
Unit tests assert the measured constants (Tests/OpenUIKitTests/
UIScrollViewTests.swift); the trace gate is the source of truth.
