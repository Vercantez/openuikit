# Swipe oracle — iOS 26.1

Captured 2026-09-07 on the private iPhone SE (3rd generation), 375×667 pt
at 2x, iOS 26.1 (23B86). Reproduce from `uikit/`:

```sh
SIM_DEVICE_SUFFIX=-uikit-blocking-types-swipe scripts/swipe_probe_sim.sh /tmp/swipe-oracle
```

`ios-26.1.txt` is the unmodified `Documents/swipe.txt` transcript. The app
and build products live only in the supplied output directory. The touch
synthesizer follows the existing `Tools/oracle2/scrollshared.swift` approach:
private touch setters feed real `UIApplication.sendEvent`, with explicit
monotonic event timestamps. The transcript records the input step that
invoked the real target/action callback. UIKit has already reset this
recognizer to `.possible` when `sendEvent` returns; inspect `action=ended`
entries, not the after-send state alone.

The default public direction is right (raw 1), and the required touch count
is 1. Left/up/down are 2/4/8. Setter readback retains unknown direction bits
and arbitrary touch counts. The private readbacks identify the initial
primary/secondary displacement bounds (50 pt), their decay rates (.06/.02),
maximum duration (.5 s), and opposite movement allowance (0 pt).

Independent ±.001 pt probes bracket the following displacement limits:

| Elapsed seconds | Minimum primary pt | Maximum secondary pt |
| --- | --- | --- |
| 0 | 50 | 50 |
| .1 | 45.3 | 45.1 |
| .2 | 40.6 | 40.2 |
| .3 | 35.9 | 35.3 |
| .4 | 31.2 | 30.4 |
| .5 | 26.5 | 25.5 |

All 24 bracket samples agree with `50 * (1 - t * (1 - decay))`.
Recognition happens during movement and fires once. At .500 s a 100 pt
swipe recognizes; at .501 s it does not. Every required touch must qualify:
100/50 pt recognizes for two fingers, while 100/0 and 100/-100 do not.
Crossing .1 pt behind the starting point prevents a right swipe; a
20→10→100 pt retreat on the positive side still recognizes. The mixed-axis
mask samples record UIKit's horizontal preference when horizontal bits are
present.

This closes the missing type and measured touch-recognition behavior. The
synthetic action callback reports location `(0,0)` even with nonzero touch
coordinates; this probe does not establish real-input location semantics,
so the implementation retains the base recognizer's location behavior.
Trackpad/scroll-generated swipes and dynamically changing the required
finger count during a gesture have not been measured.
