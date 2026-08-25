# golden/scroll_traces — real-UIKit scroll physics traces

Ground-truth contentOffset timelines recorded from **real iOS UIKit**
(iOS 26.1, iPhone 16 simulator, UIScrollView defaults, 393×852 pt viewport,
40 000 pt content height) by the SimProbe oracle
(`Tools/oracle2/simprobe/`, run end-to-end with
`scripts/scroll_probe_sim.sh <outdir>`).

How they were recorded: SimProbe synthesizes UITouch drags in-process
(KIF-style private-API delivery through `UIApplication.sendEvent`,
`Tools/oracle2/scrollshared.swift`) against a plain UIScrollView, with every
touch stamped on an ideal 8 ms (calibration: 16 ms) time grid so UIKit's
velocity estimator sees exactly the scripted velocity. contentOffset is
sampled by a CADisplayLink **and** in `scrollViewDidScroll` (so each frame
appears twice: a stale pre-frame sample and the fresh post-update value
~0.1 ms later — consumers must keep the LATER value at near-equal times,
see `Tools/compare/compare_scroll.py:series`). Offsets are quantized by
UIKit to the device pixel grid (1/3 pt at 3×).

Why the simulator and not the Mac Catalyst oracle: Catalyst UIScrollView
only scrolls via the POINTER path, whose physics are the Mac feel
(velocity-dependent decay rate, ~0.07 stiff rubber band) and it refuses to
apply touch-pan translation at all — measured, see
`catalyst_pointer/README.md`. The simulator runs the genuine iOS touch
physics that OpenUIKit implements.

## Files

| trace | kind | gesture |
|---|---|---|
| touch_calib | calibration | slow drag (3 pt/16 ms), held still, lifted — 1:1 tracking + slop |
| decel_v750/1500/3000/4875 | deceleration | 14-move flick at that pt/s, mid-content free deceleration |
| rubberband_top/bottom | rubber_band | slow drag ~590 pt past the edge, hold, lift — band curve + rest bounce |
| bounce_release_vel | bounce_release | fast overscroll released still moving — velocity-seeded bounce |
| edge_impact | edge_impact | flick decelerating INTO the bottom edge — impact bounce |

## JSON schema (per trace)

```
{
  "name":        "decel_v1500",
  "kind":        "calibration | deceleration | rubber_band | bounce_release | edge_impact",
  "source":      human-readable provenance string,
  "input_type":  "touch",
  "interval":    seconds between input events (ideal grid),
  "viewport":    {"w", "h"},          // scroll view bounds, pt
  "contentSize": {"w", "h"},
  "startOffsetY": offset before the gesture,
  "decelerationRate": UIScrollView.decelerationRate (0.998),
  "input":  [ {"t", "x", "y", "phase": "began|moved|stationary|ended"} ],
             // the synthetic finger path, window coords, CACurrentMediaTime
  "samples": [ [t, offsetX, offsetY], ... ],   // display-link + didScroll
  "delegate": [ {"t", "name", "detail"} ],     // delegate callback log
  "willEndDragging": {"t","vx","vy","targetX","targetY"},
             // UIKit's OWN reported velocity (pt/ms) and landing offset
  "finalOffsetY": settled offset
}
```

All timestamps share one clock (CACurrentMediaTime at record time; the
`input` events' `t` are the timestamps STAMPED on the touches).

## Consuming

`Tools/compare/compare_scroll.py` replays each trace's `input` through
OpenUIKit (`openrender scrolltrace golden/scroll_traces/X.json out.json`)
and gates the offset timelines: drag/rubber-band ≤ 1 pt, deceleration
≤ 2 pt (after a ±20 ms alignment shift — UIKit starts the decel animation
about a frame after the lift), bounce settle time within 10%.

The measured constants derived from these traces are documented in
docs/APP_FEEL.md ("Measured scroll physics") and implemented in
`Sources/OpenUIKit/UIScrollView.swift` (`UIScrollPhysics`).

## catalyst_pointer/

Traces of the SAME experiments driven through the Mac Catalyst
pointer-scroll path (oracle2 `scroll` mode, synthetic scroll-phase NSEvents
delivered to our own NSWindow). Kept for provenance: they document that the
Catalyst pointer physics differ from iOS touch physics (deceleration
distance ∝ v^1.37 rather than linear; rubber-band factor ~0.07 vs 0.55) —
OpenUIKit deliberately implements the iOS touch feel, not these. Extra
field: `unitsPerPx` (UIKit pt per injected AppKit px, 700/539) and `input`
entries carry `dyPx` scroll deltas instead of finger positions.
