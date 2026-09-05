# Present axes — dark, compact, Dynamic Type, RTL

Round-15 board (`scoreboard/latest.md` at 45f6395b) had Present light and
iPad above the bar, but the DARK axis was a whole-surface miss and t1200
missed on every other axis. Goldens restored from `goldens/ios` into
`/tmp/conformance-Present*` (never `/tmp/hc-conformance-*`). Device:
iPhone SE 2x / iOS 26.1, `SIM_DEVICE_SUFFIX=-present-axes`.

Iterated with `SKIP_CAPTURE=1 scripts/conformance_flow.sh`.

## Before (round 15)

| capture | pixels | blob pt² | notes |
|---|---|---|---|
| t200 / t2100 | 99.606 | 3 | already green |
| t1200 | 98.032 | ~89 | already green |
| t200.dark / t2100.dark | **92.694** | **16654** | LPLinkView `[16, 88, 343, 53]` light fill on a dark root |
| t1200.dark | **2.996** | **236789** | Safari page painted white over a black golden |
| t200.ax1 / t2100.ax1 | 99.166 | 46.2 | already green |
| t1200.ax1 | **94.451** | 94.5 | 5 layout misses |
| t200.xxxl / t2100.xxxl | 98.937 | 128.2 | already green |
| t1200.xxxl | **94.475** | 95.5 | 5 layout misses |
| t200.rtl / t2100.rtl | 99.456 | 9 | already green |
| t1200.rtl | **94.696** | 98.8 | 5 layout misses |
| t200.landscape / t2100.landscape | 99.606 | 3 | already green |
| t1200.landscape | **95.170** | 119.8 | 5 layout misses |
| iPad t200 / t2100 | 99.898 | 3 | already green |
| iPad t1200 | 99.418 | 189 | already green |

## Measurements (pixels, not dumps)

### LPLinkView plain card

Present t200 / t200.dark card interior, constrained width 343:

| style | interior RGB | mix |
|---|---|---|
| light | **(233, 233, 235)** | 0.16·(120,120,128) + 0.84·white |
| dark | **(38, 38, 41)** | 0.32·(120,120,128) + 0.68·black |

That pair is opaque `secondarySystemFill` over `systemBackground`. The
dump still reports `LPFlippedView` bg 0.915 in dark (unresolved light);
pixels are the oracle. Title `.label`; host `.secondaryLabel` over the
fill was already wired (light (129,129,134), dark (156,156,163)).

### SFSafariViewController

`http://127.0.0.1/` fails to load; chrome still paints. Mail compose is
not presented (`canSendMail` false) — unchanged.

| what | light t1200 LTR | dark / rtl / ax1 / landscape |
|---|---|---|
| page fill | 255 = `systemBackground` | 0 = `systemBackground` (was `.white`) |
| dismiss | `xmark` bbox `[29.5, 16.5, 17, 17]` | X in 44 pt platter at `(16, 8)` |
| RTL chrome | — | does **not** mirror; X stays x=16 |
| address | centre band all 255 | **"127.0.0.1"** (`URL.host`), ~13 pt semibold |
| lock | — | `[154.5, 13, 5.5, 12]`; `lock` is not harvested |
| page-menu | trailing-top all 255 | 44 pt circle at `W−16−44`; glyph is rounded-rect + two lines, not harvested `doc.text` |
| failed-load body | y=150–250 all 255 | dark: `[54, 181.5, 267.5, 34.5]` ink **(133,133,133)**; rtl/ax1/xxxl/landscape light **present** (min ~126); iPad **absent** |
| back | 48 pt at `y = H − max(16, SA.bottom − 16) − 48` (SE 603) | dimmed `.tertiaryLabel` |
| reload | — | dimmed / spinning (clock) |
| share + safari | — | `.label` |
| progress | — | blue left cap, clock-dependent; not painted |

**Compact height** (Present t1200.landscape, window 667×375):

| | fill bbox |
|---|---|
| capsule | `[520, 4, 130, 42]` → width **130**, trailing 16, interiors **(198, 198, 198)** |
| page-menu | `[117, 4, 42, 42]` = `16+44+57` |
| bottom toolbar | absent |
| back | chevron without platter, between dismiss and page-menu |

**ax1 vs xxxl:** dismiss glass / X bbox / address ink **identical**, so
every category above `extraExtraLarge` caps there (tighter than nav
`iOSBarCapped`, which leaves xxxl uncapped).

Glass mix on platters remains OPEN (`_UIBarMetrics.platterFill` flats).

A guessed failed-load string (dark-only) dropped t1200.dark
**95.279 → 94.781** and was reverted. No single visibility rule fits
the samples.

## After (`SKIP_CAPTURE=1`)

| capture | before | after | bar |
|---|---|---|---|
| t200 | 99.606 | **99.606** | held |
| t1200 | 98.032 | **97.836** | ≥97.5 |
| t2100 | 99.606 | **99.606** | held |
| t200.dark | 92.694 | **99.430** | closed |
| t1200.dark | 2.996 | **95.279** | OPEN (blob 98, reload) |
| t2100.dark | 92.694 | **99.430** | closed |
| t200.ax1 | 99.166 | **99.166** | held |
| t1200.ax1 | 94.451 | **94.287** | OPEN |
| t2100.ax1 | 99.166 | **99.166** | held |
| t200.xxxl | 98.937 | **98.937** | held |
| t1200.xxxl | 94.475 | **94.312** | OPEN |
| t2100.xxxl | 98.937 | **98.937** | held |
| t200.rtl | 99.456 | **99.456** | held |
| t1200.rtl | 94.696 | **94.524** | OPEN |
| t2100.rtl | 99.456 | **99.456** | held |
| t200.landscape | 99.606 | **99.606** | held |
| t1200.landscape | 95.170 | **96.978** | OPEN (blob 82, capsule icon) |
| t2100.landscape | 99.606 | **99.606** | held |
| iPad t200 / t2100 | 99.898 | **99.898** | held |
| iPad t1200 | 99.418 | **99.384** | held above bar |

Light t1200 dropped 0.196 because the iOS-cut chrome (xmark / page-menu)
is painted on an LTR light golden whose centre/trailing-top is all-255.
Still above 97.5. iPad t1200 dropped 0.034 the same way.

## OPEN

`scoreboard/open.txt` `Present-t1200-safari-remote`. The remaining miss
is the remote `_UISceneHostingView` (failed-load copy visibility, lock
and page-menu glyphs, reload spinner, clocked progress, presenting-VC
labels in our dump). No single rule fits every sample.

## Gates

- `PresentableFrameworksTests` 11/11
- Catalyst **124/124** (iOS-cut only; fixture scenes have no Safari/LPLink)
- iOS suite **112/113** (known `corner_radius` 99.411)
- real-app floors **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 / 82.170 / 99.760 / 99.689 / 85.393**
- Linux `swift:6.2-noble` `openrender` green (182.41 s)
- no `Package.resolved`
