# Catalyst pointer-scroll traces (NOT the physics OpenUIKit implements)

Recorded by `Tools/oracle2/run.sh scroll <outdir>` — real UIKit in the Mac
Catalyst oracle window, driven by synthetic trackpad-style scroll-phase
NSEvents (scrollprobe.swift; events are delivered straight to our own
NSWindow, nothing touches the system event stream).

Findings (2026-08-24, macOS host, iOS-26.1 macabi UIKit):
- Catalyst UIScrollView scrolls ONLY via the pointer path. Synthetic touch
  drags recognize on its pan gesture (state/translation/velocity all
  correct, willBeginDragging fires) but the translation is never applied to
  contentOffset — Mac behavioral gating.
- Pointer deceleration is NOT the iOS curve: landing distance grows ~v^1.37
  (fitted per-ms rate drifts 0.9914 → 0.9943 across 800–6200 pt/s), unlike
  the iOS touch curve's fixed 0.998/ms.
- Pointer rubber-band is far stiffer than iOS: displayed overshoot ≈ 0.07 ×
  raw (vs the touch formula's c = 0.55).

These traces exist to document that divergence; the authoritative traces
for OpenUIKit's touch physics are the simulator ones one directory up.
File schema matches SCHEMA.md except: `input` entries are scroll events
(`dyPx`, `phase`, `momentum`), and `unitsPerPx` gives UIKit pt per injected
AppKit px (700/539 — the 0.77 Catalyst window scaling).
