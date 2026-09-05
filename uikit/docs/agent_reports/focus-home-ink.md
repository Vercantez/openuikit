# Focus home 12 pt regular ink (guest 14th screen)

Base: `origin/agent/focus-merged5` (`f929c82d`, Ledger 13th + Focus home
14th last; report `merge-focus3.md`). Arm64 verify of `f75875cc` rendered
13 screens and died on the 14th:

```
OPENUIKIT_IOS_INK_MISS: I|system-regular|12|light|F0.25|107
```

`I|` is the 2x iOS table. Scalar 107 is `'k'`. Guest `realapp` is scale 2
with no SFNS; a miss with `glyphFont == nil` is fatal.

Scope is `uikit/` only. No pin files, no `full/`, no `scripts/vendor_pins.sh`.

## What draws the 12 pt `'k'`

MEASURED this Mac, `openrender realapp` scale 2 iOS cut, home layout dump
`/tmp/app-inklog-s2-focus-home-ink/realapp_focus_home_light.layout.json`:
one `UILabel` at `[126, 67, 141, 14.5]`. `14.5` is the harvested
`system-regular|12` `labelHeight` (SE 2x baseline in `glyph_ink_ios.json`).

That label is `ShareTrackersViewController` in `FocusShims.swift`:
`label.font = .footnote12` (`UIFont.systemFont(ofSize: 12)`) and
`tipManager.shareTrackersDescription()` = `"0 trackers blocked so far"`
(TipManager.shareTrackersTipDescription at focus-ios `a2832521` with 0
blocked). `'k'` is in `trackers` / `blocked`.

The 2x table already had **251** `system-regular|12` keys (light only,
incomplete ASCII / phases). `'k'` existed at `F0.0` but **not** at
`F0.25` — the exact miss.

## Harvest (2x, SE, measured)

Same method as guest-trial2's 13 pt regular ASCII (`Tools/oracle2/inkprobe`
through UILabel, `SIM_DEVICE=2x`, opaque calibration).

- Device: `OpenUIKit-2x-focus-home-ink` (iPhone SE 3rd gen, 2x) / iOS 26.1
- Keys: `system-regular|12|{light,dark}|{F0.0,F0.125,F0.25,F0.375,F0.5,F0.625,F0.75,F0.875}|{33…126}`
  (every ASCII glyph × every phase the 2x iOS table format carries × both
  appearances) — **1504** keys in `/tmp/ink_keys_focus_home_12.txt`
- Result: **1504/1504**, `skipped []`, `device 26.1`, `scale 2`,
  `calibration opaque`
- Overlap with the prior 251 keys: **251/251 byte-identical** (same probe,
  same device class)
- New keys: **1253**. Miss key `system-regular|12|light|F0.25|107`:
  `{w:11, h:18, ox:2, oy:-18}`
- Table **7533 → 8786**. `glyph_ink.json` (Catalyst) untouched.

Existing 13 pt regular ASCII in the same file is 94 glyphs × 8 phases ×
light (and dark) — this harvest matches that family shape at 12 pt.

## Scale-2 INK_LOG (14th screen and the 13 before it)

`OPENUIKIT_FORCE_IOS=1 OPENUIKIT_REALAPP_SCALE=2 OPENUIKIT_INK_LOG=…`
`openrender realapp` wrote **14** PNGs including
`realapp_focus_home_light`. Miss log: **empty**. The named `F0.25|107`
cell is a hit; no other 2x family remains for these screens.

## 3x harvest (measured, reverted)

The brief also asked for a clean scale-3 log of the 14th screen.
`glyph_ink_ios_3x.json` had **19** `system-regular|12` light F0.0 keys
(not `'k'` / `'0'` / `'b'` / `'d'` from the home string).

Harvested ASCII 33–126 at 12 pt regular, light+dark, F0.0 only (the 3x
table format: one mask per glyph, whole device pixel) on
`OpenUIKit-Chrome-focus-home-ink` (iPhone 16) /
`SIMCTL_CHILD_INK_SCALE=3`: **188/188**, skipped [], overlap with the
prior 19 keys **19/19 identical**. Merging 169 new keys (848 → 1017)
then:

| PNG vs pre-3x (same 2x table) | result |
|---|---|
| `realapp_focus_home_light` | DIFF (expected: home's 12 pt now harvested) |
| `realapp_focus_settings_light` | DIFF (`ActionFooterView` `.footnote12`, e.g. "links") |
| `realapp_hackers_feed_light` | DIFF |
| other 11 screens | IDENT |

Guest realapp is scale 2. Mac scale-3 compare uses SFNS fallback for
unharvested 3x keys. Adding those 3x 12 pt masks switched Settings and
Hackers from font fallback to harvested coverage and would have broken
byte-identity of the 13 earlier screens. **Reverted**
`glyph_ink_ios_3x.json` to 848 keys (matches HEAD).

Scale-3 `OPENUIKIT_INK_LOG` of all 14 screens still has **202** `I3|`
misses (pre-existing 3x-table holes at 13/16/17/21/24/30/33 pt etc.).
Those are not the named guest miss. Home's only text run is 12 pt
regular; cleaning it at 3x collides with Settings/Hackers as above.

## Proof (this Mac)

- Scale-2 INK_LOG of 14 screens: **empty**
- 13 earlier screens at scale 3 **byte-identical** to `/tmp/app-gt2-s3`
  (main's post-harvest render). Ledger sha256
  `aeee639f7efdce37ce1a2cb30fcff23554073aaf9c1bebce433094b8a19683fa`
- Twelve floors vs `/tmp/golden_realapp_ios` do not drop:
  **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 /
  99.65 / 82.170 / 99.86 / 99.734 / 85.393**
  (same PNGs as gt2; ipad figures are this golden dir's
  `compare_realapp.py --scale 3` numbers)
- Catalyst **124/124** (`/tmp/gate-focus-home-ink`)
- iOS suite `SKIP_CAPTURE=1` `/tmp/suite-focus-home-ink`: **112/113**,
  miss is the known `corner_radius` 99.411
- `swift test --filter GlyphInkTableTests`: **14 tests, 0 failures**
  (includes `I|system-regular|12|light|F0.25|107`)
- `docker run --rm -v "$PWD":/src:ro swift:6.2-noble` (tree tarred to
  `/work`, exclude `.build` / `Package.resolved`):
  `swift build -c release --product openrender` **complete (211.07 s)**

No new rendering rule. Catalyst stays on `glyph_ink.json`. No
`Package.resolved`.

## Guest verify (arm64 box)

Graded only by `queue_box.sh arm64 verify e4ea0f79` log lines.
Instance `i-00da4d9ca172eb1ff`. Command
`23615645-cdfe-4653-bbd3-987faf8142da`.

| line | value |
|---|---|
| `BUILD_OK` | yes |
| `TBD_CHECK_OK` | yes |
| `difftest rc=0` | yes |
| `build_full rc=0` | **yes** |
| `GATE_B_PASS` | **yes** |
| `GUEST_REALAPP_RC` | **0** |
| `GUEST_REALAPP_SCREENS` | **14** |
| `[render_full] realapp rendered` | **14 failed=0** including `realapp_focus_home_light` |

`OPENUIKIT_FONT_DIR=/opt/openuikit/verify-20260902/openuikit/scratch/fonts`
has **no SFNS*.ttf** — the 14th screen drew from harvested iOS masks
only. The 12 pt `'k'` at F0.25 is no longer a miss.
