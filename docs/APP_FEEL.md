# M7.5 — "Real UIKit feel" demo app (USER PRIORITY)

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
