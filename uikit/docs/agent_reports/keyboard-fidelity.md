# Keyboard fidelity: at-rest portrait + compact-height landscape

Round-17 (`uikit/scoreboard/latest.md` at 25f6d2b5) showed two gaps the
keyboard-chrome / keyboard-state merges could not see: portrait keyboard-up
Forms rows at ~60 against freshly captured goldens, and landscape
keyboard-up frames with a size mismatch (numpy `(h,w,c)` reported as
`golden=(1334, 750, 4) ours=(750, 1334, 4)`).

Device: iPhone SE 3rd gen 2x, iOS 26.1, `OpenUIKit-2x-keyboard-fidelity`.
Work dirs `/tmp/conformance-Forms` / `-dark` / `-landscape` (and Tabs,
Notes). Round-17 goldens in `/tmp/hc-conformance-*` were read-only.

## (1) Portrait ~60: Slide to Type, not mid-flight

Forms t1200 sheet (hc-conformance-Forms): golden has the "Speed up your
typing by sliding your finger…" card + Continue; ours draws the at-rest
keyboard. Report: blob 131 at [21.5, 579, 15.5, 18], "content missing at
[150.5, 627, 11, 13.5] (golden std 49, ours 0)", "NOT AT REST … 1 view
animating" at clock frame 72.

That is the Continuous Path onboarding (merge-keyboard.md already hit it
on a fresh UDID). The animating view is the tutorial illustration, not
the 23/60 keyboard appear (t=1.20 is 72 frames = 1.20 s after start;
focus-name is at t=0.40, so 0.80 s ≥ 0.383 s rest). Waiting longer does
not dismiss the card.

`conformance_probe_sim.sh` now writes, after boot, the four flags
Chromium `iossim_util.disable_simulator_keyboard_tutorial` uses in
`com.apple.keyboard.preferences`:

- `DidShowContinuousPathIntroduction`
- `KeyboardDidShowProductivityTutorial`
- `DidShowGestureKeyboardIntroduction`
- `UIKeyboardDidShowInternationalInfoIntroduction`

Recapture `/tmp/conformance-Forms` (fresh device + flags before launch):
no card. "NOT AT REST 1 view" on the new goldens is the caret blink.

## (2) Landscape size mismatch: framebuffer vs interface

Layout dumps were already 667×375 on both sides. The PNG size clash was
the NEED_SHOT path: `simctl io screenshot` of landscapeLeft is the
**portrait framebuffer** 750×1334 with the landscape UI rotated 90° CCW
(Form title on the left edge). Unfocused captures stay `drawHierarchy`
(1334×750) so t200.landscape / t5700.landscape never mismatched.

MEASURED Forms t1200.landscape golden vs t200.landscape: PIL
`Image.ROTATE_270` (90° CW) yields 1334×750 with the form on top and the
keyboard at the bottom. confprobe now rotates a landscape screenshot
whose `cgImage.width < height` before the sRGB re-encode.

## Compact-height keyboard (iOS cut)

Rotated golden + dump `adjustedContentInset.bottom` **206**:

| | sample (Forms t1200.landscape, SE 2x) |
|---|---|
| window | 667×375 |
| panel | `[0, 169, 667, 206]` (375 − 169); r=26 (left edge at y=180 is 5.5 pt) |
| QuickType | 50 pt (row 1 at window y 219); dividers x **221.5 / 443.5**, y 183–205 (panel-local 14–36, h=22) |
| letter | **47×32**, h-gap 6, v-gap 8, left **72** |
| row 1 | y 219  QWERTYUIOP at xs 72 / 125 / 178 / 230.5 / 283.5 / 336.5 / 389.5 / 442.5 / 495 / 548 |
| row 2 | y 259  ASDFGHJKL at x0 98.5 |
| row 3 | y 299  shift **63** @72, ZXCVBNM, delete **63** @532 |
| row 4 | y 339  123 **47**, emoji **47**, mic **36**, space **269**, return **100** |
| bottom pad | 4 (339+32=371, 375−371=4) |

`_UIKeyboardResolved.isCompactHeight` (vclass compact, or screen width >
height, not pad) sets overlap 206 and `buildPhoneLandscapeAlphabetic`.
Portrait 260 / pad 337 / numberPad 233 unchanged.

## Before / after

Before = round-17 board (`/tmp/hc-conformance-*`). After = this branch
on `/tmp/conformance-*`.

### Forms light (recaptured; tutorial flags)

| capture | first responder | before | after |
|---|---|---|---|
| t200 | no | 98.91 (board pass) | **98.930** |
| t1200 | empty name | **60.37** tutorial | **96.791** blob 137 delete |
| t2100 | `"Alex Rivera"` | 60.41 | **96.769** |
| t3000 | yes | 60.39 | **96.751** |
| t3900 | yes | 60.36 | **96.721** |
| t4800 | yes | 60.37 | **96.728** |
| t5700 | no | 98.99 | **98.985** |

Mean **97.382**, worst **96.721**. Unfocused held. Residual:
`Forms-keyboard-letter-caps` in `scoreboard/open.txt`.

### Forms dark (SKIP_CAPTURE vs round-17)

t200.dark **97.674** / t5700.dark **97.686** held. Focused
**95.404–95.309** blob 213 emoji (keyboard-state.md).

### Forms landscape (recaptured; 90° CW)

| capture | before | after |
|---|---|---|
| t200.landscape | 99.322 | **99.322** |
| t1200.landscape | **0.00** size mismatch | **93.465** blob 98.8 delete [561.5, 308, 20.5, 14] |
| t2100.landscape | 0.00 | **94.076** |
| t3000.landscape | 0.00 | **93.255** |
| t3900.landscape | 0.00 | **91.426** |
| t4800.landscape | 0.00 | **91.457** |
| t5700.landscape | 99.6 | **99.604** |

PNGs 1334×750 both sides. Residual:
`Forms-t1200-landscape-key-glyphs`.

### Tabs light (SKIP_CAPTURE) / landscape (recaptured)

Unfocused held vs keyboard-state: t200 **96.657**, t2000 **84.623**,
t6000 **87.496**, t7000 **96.600**. Keyboard-up t4000 **95.006**, t5000
**93.709**. Dark t4000.dark / t5000.dark **92.353 / 92.416**.

Landscape: t200.landscape **95.882** (board 95.88). Keyboard-up t4000
**0.00 → 94.768**, t5000 **0.00 → 93.695** (same 98.8 delete blob).
t2000.landscape **77.994** (board 77.89, scroll-glass OPEN).

### Notes light (SKIP_CAPTURE) / landscape (recaptured)

t2100 **95.362** blob 137 (board 95.36). t4000 **77.815** (no keyboard;
`isActive` only). t5000 **98.737**. Dark t2100.dark **93.918**.

Landscape: t200.landscape **76.049** (board 76.05). t2100 **0.00 →
94.289** blob 956 at Done [606.5, 24, 44.5, 44] (nav chrome + glyphs;
t1200.landscape without keyboard is already 94.61). Unfocused
t6000/t10000.landscape 56.48 / 56.44 held vs board 56.62 / 56.44.

## Open

1. **Letter caps.** UILabel 22 pt vs private key-cap font. Portrait Q
   golden 12×17; landscape Q golden **10.5×15**. Brief: label path.
2. **Special-key SF Symbols** (delete, emoji, mic, return). Stroke
   stand-ins. Portrait blob 137; landscape blob 98.8 — same key.
3. **QuickType suggestion text** still empty dividers only.
4. **Caret blink** on focused goldens ("1 view animating"). Not modelled.
5. **iPhone 16 height 335** still not drawn.

## Gates

- Catalyst **124/124** (`/tmp/gate-keyboard-fidelity`).
- iOS suite SKIP_CAPTURE=1 **112/113** (`corner_radius` 99.411).
- Real app **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 /
  97.516 / 99.65 / 82.17 / 99.86 / 99.734 / 85.393**.
- Linux `swift:6.2-noble` `openrender` green (183.99 s; copy excludes
  `.build` because the host `release` symlink is unreadable in the
  container).
- `KeyboardChromeTests` + `KeyboardAvoidanceInsetTests` **12/12**.
- No `Package.resolved`.
