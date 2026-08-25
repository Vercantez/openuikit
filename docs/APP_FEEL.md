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
- Tracking: content follows the finger 1:1 while dragging.
- Velocity: from the last ~100ms of touch samples at release.
- Deceleration: UIKit's `decelerationRate = .normal` = **0.998 per millisecond**
  (v(t) = v0 * 0.998^t_ms; stop below ~0.1 pt/s). Position integrates that curve.
- Rubber-band overscroll (Apple's formula):
  `offset' = (1 - 1/(c*|offset|/dim + 1)) * dim * sign(offset)` with c = 0.55,
  dim = scroll view dimension. Applies while dragging past the edge.
- Bounce-back: spring to the boundary on release, ~0.5s critically-damped
  (UIKit uses a spring with the current velocity as initial velocity).
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
- Scroll deceleration/rubber-band ARE oracle-measurable later (M8): drive a
  real UIScrollView in oracle2 with `setContentOffset` + pan simulation and
  time-sample; until then, the constants above are UIKit's documented/
  well-established values — implement them exactly, no "close enough" easing.
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
  after touchesBegan has painted the highlight.
- Interactive back-swipe (the stretch goal) shipped in the navigation
  milestone and works on every pushed screen of the demo.
- Host improvements that came out of this milestone: `openhost --app demo`
  (UIApplication-lite boot), layout-before-draw (window.layoutIfNeeded()
  before every rendered frame, matching UIKit's commit), and dirty-flag
  rendering (below).

Not done (honest list): no large-title nav bar (fixed 64pt bar), no status
bar content, no blur behind the bar, row press states don't cancel on
significant vertical finger travel within the slop window (UIKit is
slightly stricter), slider has no tap-to-jump (drag only, as specced),
About value rows use a plain static style rather than UIKit's exact
About-table metrics.

## Performance (measured 2026-08-24, Apple M3 Max, release build)

Dirty-flag rendering: the live loop renders ONLY when an input event
arrived, a finger is down, a scroll is decelerating/bouncing, a navigation
transition is in flight, or the host clock is before
`OpenUIKitRuntime.animationWorkDeadline` (a new runtime hint fed by
UIView.animate recording and UISwitch.setOn). An idle app renders zero
frames.

But during a sustained scroll every frame is dirty, and a full-frame
re-render of the Settings root costs (60-frame scripted average):

| scale | avg render | sustained  |
|-------|-----------|-------------|
| 2     | ≈ 144 ms  | ≈ 7 fps     |
| 1     | ≈ 39 ms   | ≈ 25 fps    |

That is far from 60 fps, so **--app mode defaults to --scale 1** (pass
--scale 2 for crisp stills/captures). Profiling (`sample`) shows the time
goes to quartz path rasterization — mostly re-rasterizing every label's
glyph ink and every icon's vector paths from scratch each frame — plus the
per-frame offscreen allocations for drawContent layers. Sustained 60 fps
needs per-layer contents caching (CA-style: re-render a layer's content
only on setNeedsDisplay, reuse the bitmap otherwise) and/or dirty-rect
partial redraw in the compositor. That is compositor-side work — flagged
as an M8 candidate for the quartz backend.
