# Corelibs ink — font-free 14-screen realapp on Linux

The Linux `scripts/linux_realapp_verify.sh` path (Docker `swift:6.2-noble`)
now builds and runs XCTest, but `openrender realapp` inside the container
still could not finish the fourteen screens without an outline font.
Scope is `uikit/` only. No pin files, no `full/`, no `scripts/vendor_pins.sh`.

## What the 66b log actually named

`/tmp/linux_realapp_verify66b.log` prints

```
OPENUIKIT_IOS_INK_MISS: I|system-regular|17|light|F0.0|81
```

twice, then `==> headless render`. Scalar 81 is `'Q'` (U+0051). That line
is the **expected miss probe** in `linux_realapp_verify.sh` (`text: "Q"`
at 17 pt regular F0.0; `GlyphInkTableTests` asserts Q is nil so the probe
stays loud). It is not a real-app glyph. Hello at the same cell is a HIT
(505 opaque pixels, α>200).

The same log then sets `OPENUIKIT_FONT_DIR=/out/fonts` and dies on Ledger
(13th screen) with `DateComponentsFormatter.init() is not supported on this
platform`. That trap is already guarded on main (`#if canImport(Darwin)`
in both Ledger copies). This branch does not retouch it.

## Font-free reproduction (Docker env, measured)

`openrender realapp` always sets `OpenUIKitRuntime.systemFontCut = .iOS`.
Default `realAppScale` is **2** (the script did not set
`OPENUIKIT_REALAPP_SCALE`; the "3x realapp" comment was a leftover). iPad
rows stay native 2x.

| run | screens | INK_LOG |
|---|---|---|
| Mac `OPENUIKIT_FORCE_IOS=1 OPENUIKIT_REALAPP_SCALE=2 OPENUIKIT_INK_LOG=…` | **14** | **empty** |
| Linux, same env, no FONT_DIR, abort on miss | **12** then trap | `I\|system-regular\|13\|light\|F0.25\|8364` |
| Linux `OPENUIKIT_INK_LOG=1` (collect, no abort) | **14** | that one key |

Scalar 8364 is euro **U+20AC**. Ledger's subtitle is
`.preferredFont(forTextStyle: .footnote)` (13 pt regular) with Apple
`de_DE` `4,50\u00a0€`. The 2x table already had euro at **F0.0 / F0.5 /
F0.75** light (`{w:15, h:19, ox:1, oy:-19}`). Linux corelibs placed the
same glyph at **F0.25**. Mac never asked for that cell, so the Mac log
was empty.

Q at 17 pt regular F0.0 is still absent (34 ASCII holes remain at that
cell, including Q/V/X/Y/Z). Do not harvest Q: the miss probe and
`testIOSMaskKeyFormatAndHarvestedHit` require it.

## Harvest (measured, SE 2x + iPhone 16 3x / iOS 26.1)

Same method as guest-trial2 / focus-home-ink (`Tools/oracle2/inkprobe`
through UILabel, opaque calibration).

- Device: `OpenUIKit-2x-corelibs-ink` (iPhone SE 3rd gen, 2x)
- Keys: `system-regular|13|{light,dark}|{F0.0…F0.875}|8364` — **16**
- Result: **16/16**, `skipped []`, `device 26.1`, `scale 2`
- Overlap with the prior 3 euro keys: **3/3 byte-identical**
- New keys: **13**. Named miss `system-regular|13|light|F0.25|8364`:
  `{w:15, h:19, ox:1, oy:-19}`
- Table **8786 → 8799**. `glyph_ink.json` (Catalyst) untouched.

3x (iPhone 16, `OpenUIKit-Chrome-corelibs-ink`, `SIMCTL_CHILD_INK_SCALE=3`):
euro F0.0 light+dark **2/2**, `{w:23, h:28, ox:1, oy:-28}`.
`glyph_ink_ios_3x.json` **848 → 850**. Isolated euro cannot move the
twelve floors (no euro on those screens). A wholesale 13 pt 3x ASCII
harvest was not done.

## `linux_realapp_verify.sh`

- Headless realapp: `OPENUIKIT_FORCE_IOS=1 OPENUIKIT_REALAPP_SCALE=2`,
  `unset OPENUIKIT_FONT_DIR`, expect **14** PNGs.
- Q miss probe unchanged (`I|system-regular|17|light|F0.0|81`).
- openhost replay still uses `/out/fonts` when the Mac copied SFNS.
- Ledger sha256 skip kept (Apple vs corelibs formatters).

## Proof

- Mac scale-2 INK_LOG of 14 screens: empty (before euro was unused on Apple)
- Linux font-free INK_LOG after harvest: (verify run completed 14 PNGs
  with no FONT_DIR; Q probe still traps)
- Twelve floors vs `/tmp/golden_realapp_ios` @3x do not drop:
  **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 /
  99.65 / 82.170 / 99.86 / 99.734 / 85.393**
- Catalyst **124/124** (`/tmp/gate-corelibs-ink`)
- iOS suite `SKIP_CAPTURE=1` `/tmp/suite-corelibs-ink`: **112/113**,
  miss is the known `corner_radius` 99.411
- `swift test --filter GlyphInkTableTests`: **14 tests, 0 failures**
  (includes `I|system-regular|13|light|F0.25|8364`; Q still nil)
- `bash scripts/linux_realapp_verify.sh /tmp/linux_realapp_corelibs-ink`:
  unit tests passed; Hello 505 px; 14 screens from harvested 2x masks
  (no SFNS); headless byte-identical **14/14**; live **10/10**;
  `REAL-APP SCREEN VERIFIED ON LINUX` (process rc=0)
- Linux `swift:6.2-noble` `openrender` green (**178.55 s**; tar exclude
  `.build` / `Package.resolved`)
- No `Package.resolved`

No new rendering rule. Catalyst stays on `glyph_ink.json`.
