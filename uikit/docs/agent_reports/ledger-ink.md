# Ledger ink — 17 pt medium `'R'` after ledger37 search chrome

Linux `scripts/linux_realapp_verify.sh` (log `/tmp/linux_realapp_verify78.log`)
ended with `openrender realapp` trapping after the Q miss probe. Scope is
`uikit/` only. No pin files, no `full/`, no `scripts/vendor_pins.sh`. No
rendering rule: harvested masks only.

## What the 78 log actually named

```
OPENUIKIT_IOS_INK_MISS: I|system-regular|17|light|F0.0|81
OPENUIKIT_IOS_INK_MISS: I|system-medium|17|light|F0.0|82
```

`I|` is the 2x iOS table prefix, not a capital I glyph. Scalar **81** is
`'Q'` (U+0051): the **expected miss probe** in `linux_realapp_verify.sh`
(`text: "Q"` at 17 pt regular F0.0; `GlyphInkTableTests` asserts Q is nil).
Hello at the same cell is a HIT (505 opaque pixels, α>200). Do not harvest
Q.

Scalar **82** is `'R'` (U+0052). That line is the real-app trap
(`DOCKER_DONE rc=133` after 12 PNGs would have been the old pattern; this
run died on the 13th screen, Ledger).

## Which screen and string draws the `'R'`

MEASURED this Mac, `openrender realapp` scale 2 iOS cut, layout dump
`/tmp/app-ledger-ink-s2/realapp_ledger_light.layout.json`:

| view | frame / intrinsic |
|---|---|
| bottom-dock slot | `[0, 766, 393, 86]` |
| glass platter | `[28, 10, 337, 48]` (slot-local) |
| `UISearchBar` | `[5, 5, 327, 38]` |
| placeholder `UITextFieldLabel` | intrinsic **48.5×20.5** (golden t200 `"Regex"` was 48.5×20.5) |

`LedgerListViewController` sets `search.searchBar.placeholder = "Regex"`.
`UISearchBar.configureSearchField` uses `.systemFont(ofSize: 17, weight:
.medium)`. `'R'` is the first letter of that placeholder, phase F0.0
light. The nav-bar `"Export"` title is the same medium 17; its `'p'`/`'r'`
already existed at F0.5 and were not in the 14-screen miss log. Nav title
`"Ledger"` is not medium (no `L` miss).

## Miss list (probe over all 14 guest screens)

`OPENUIKIT_FORCE_IOS=1 OPENUIKIT_REALAPP_SCALE=2 OPENUIKIT_INK_LOG=…`
`openrender realapp` of all 14 screens, no `FONT_DIR`. One miss hides the
next, so this is the harvest input, not the Q probe scene.

| run | screens | INK_LOG |
|---|---|---|
| Mac, before harvest | **14** | **`I\|system-medium\|17\|light\|F0.0\|82`** (one key) |
| Linux `uikit-linux` 6.2.4, same env | **14** | **that same one key** (no extra corelibs phase) |
| Mac, after harvest | **14** | **empty** |
| Linux, after harvest | **14** | **empty** |

Q at 17 pt regular F0.0 is still absent. The 3x table is untouched (guest
realapp is scale 2; a 3x medium-17 harvest would switch SFNS-fallback
screens the way focus-home-ink's 12 pt 3x harvest DIFF'd Settings/Hackers).

## Harvest (measured, SE 2x / iOS 26.1)

Same method as guest-trial2 / focus-home-ink / corelibs-ink
(`Tools/oracle2/inkprobe` through UILabel, opaque calibration).

- Device: `OpenUIKit-2x-ledger-ink` (iPhone SE 3rd gen, 2x)
- Keys: `system-medium|17|{light,dark}|{F0.0,F0.5}|{33…126}` — **376**
  (ASCII × both appearances × the 17 pt iOS pen grid). Named miss
  `system-medium|17|light|F0.0|82` is in that set.
- Result: **376/376**, `skipped []`, `device 26.1`, `scale 2`,
  `calibration opaque`
- Overlap with the prior 330 `system-medium|17` keys: **84/84
  byte-identical**
- New keys: **292**. Named miss `{w:19, h:24, ox:3, oy:-25}`
- Table **8799 → 9091**. `glyph_ink.json` (Catalyst) and
  `glyph_ink_ios_3x.json` untouched.

## Proof

- Mac scale-2 INK_LOG of 14 screens: empty (after); one key (before)
- Linux font-free INK_LOG after harvest: empty; Q probe still traps
  `I|system-regular|17|light|F0.0|81`
- Twelve floors vs `/tmp/golden_realapp_ios` @3x do not drop:
  **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 /
  99.65 / 82.170 / 99.86 / 99.734 / 85.393**
- Catalyst **124/124** (`/tmp/gate-ledger-ink`)
- iOS suite `SKIP_CAPTURE=1` `/tmp/suite-ledger-ink`: **112/113**,
  miss is the known `corner_radius` 99.411
- `swift test --filter GlyphInkTableTests`: **14 tests, 0 failures**
  (includes `I|system-medium|17|light|F0.0|82`; Q still nil)
- `docker exec uikit-linux` inner steps of `linux_realapp_verify.sh`
  (`/tmp/ledger-ink`, Swift 6.2.4): unit tests passed (selector 35,
  ink 90); Hello **505** px; Q miss probe; **14** screens from harvested
  2x masks (no SFNS); live **10** frames; `DOCKER_DONE rc=0`
- Mac vs that Linux render: headless **14/14** (Ledger sha256 skip
  kept), live **10/10**; `REAL-APP SCREEN VERIFIED ON LINUX`
- Linux `swift:6.2-noble` `openrender` green (**188.98 s**;
  `cp -r /src /work`)
- No `Package.resolved`

No new rendering rule. Catalyst stays on `glyph_ink.json`.
