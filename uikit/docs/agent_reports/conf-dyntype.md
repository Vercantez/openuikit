# Conformance Dynamic Type axis (Forms / Feed / TableEditor at ax1)

Dynamic Type on the conformance harness was previously only the Pocket
Casts Settings real-app variants (`xs` / `xxxl` / `ax1`). This branch
adds a content-size axis to `conformance_flow.sh` and closes the two
largest measured misses on Forms, Feed and TableEditor at
`.accessibilityLarge` on the iPhone SE 2x / iOS 26.1.

## Harness

`scripts/conformance_flow.sh <dir> <App> --ax1` / `--xxxl` sets
`CONFPROBE_CONTENT_SIZE` / `OPENUIKIT_APP_CONTENT_SIZE`. Both confprobe
and openhost set `window.traitOverrides.preferredContentSizeCategory`
**before** `makeRoot()`, matching how Settings was captured. Capture
names suffix `.ax1` / `.xxxl`; default `.large` stays unsuffixed
(`t200`) so existing goldens do not move.

Work dirs `/tmp/hc-conformance-<App>-ax1` and `-xxxl` are registered in
`hillclimb.sh` and `agent_merge.sh`. `scoreboard.py` keys `Forms.ax1`
separately.

**Measured harness fact:** confprobe only sets the window override, not
`UITraitCollection.current`. Forms/Feed labels that call
`UIFont.preferredFont(forTextStyle:)` at construction stay **17 pt** on
real iOS. Default `UITableViewCell` labels and nav chrome follow the
window at layout. openhost must not pin `current` to ax1 or those
construction fonts over-scale (Forms body 33 vs golden 17).

## Baseline (ax1, SE 2x / iOS 26.1, before the rules)

| app | worst | mean | notes |
|---|---|---|---|
| Forms | **95.084** | 95.160 | blob 396; construction body 33 vs golden 17 |
| Feed | **84.212** | 85.702 | blob ~3250; large title 34 vs 48; cards over-scaled |
| TableEditor | **65.092** (t3800) | 86.206 | cells 62 vs **117**; fonts 17/15 vs **33/30** |

## Frames (t200.ax1 golden, SE 2x)

**TableEditor.** Plain subtitle cell **117** (`[0, 125.5, 375, 117]`),
stride 117. Primary “Alpha” **33 pt** body, h=39.5 at y **15**. Detail
“First item” **30 pt** subheadline, h=36 at y **60.5** (15+39.5+**6**).
Bottom pad **20.5**. `.large` stays 62 / y 9 / 32.5. Edit
`UIButtonLabel` **21 pt**, `[306.215, 18.817, 36.5, 25.5]` (capped, not
33). Inline “Reminders” **21 pt** headline h=26; large title **48 pt
bold**, `[16, 64, 238.5, 57.5]`. Bar `[0, 10, 375, 115.5]`; table y
**125.5**. Edit mode (t2350.ax1): delete control
`[16, cellY+33, 39, 38]`, content view x **55**, reorder
`[318, cellY, 41, 117]`, labels x **71**. `.large` stays 15/26/40/27.

**Feed.** Custom labels (stories, card title/body, “Stories”) stay
**17 pt**. Large title “Feed” **48 pt bold** / h=57.5 / abs y 64; inline
**21 pt**. Collection y 125.5. Card body two lines h=**38** at 15 pt
subheadline. Zone `NavigationBarLargeTitleView [0, 64, 375, 61.5]` =
max(52, 57.5+4).

**Forms.** Body labels **17 pt** / 20.5. Nav title “Form” **21 pt**
`[162.5, 19, 50, 26]`. Date capsule still **34 pt**; inner `UILabel`
**20 pt** tall at abs y 407.5 (capsule 400.5 + 7) with short numeric
**“9/4/26”**, not medium “Sep 4, 2026”. Text field placeholder 17 pt,
field h=22.

Bar/nav cap: accessibility categories cap **inline title + bar buttons**
at `.extraExtraLarge` (21 pt). Large title is **uncapped** (48 pt at
ax1). `scaledValue(for: 17)` at extraExtraLarge is **20**; the golden
Edit label is **21** = `preferredFont(.body)` at that cap.

## Rules (iOS cut)

1. **`UIContentSizeCategory.iOSBarCapped`** — accessibility →
   `.extraExtraLarge`. Inline headline + bar-button body use the cap;
   large title does not.
2. **Nav chrome restyles at layout** from the window override.
   `makeRoot()` builds the bar before it joins the window, so
   construction `preferredFont` still reads process `.large`. Layout
   after `rootViewController =` applies 21 / 48. Large-title size from
   `preferredFont(.largeTitle)`, **weight bold** (main’s 34 bold face;
   regular 48 laid out Reminders at 219.5 vs golden 238.5). Zone
   `max(52, labelH+4)`; label y pins to zone origin when
   `labelH+3.5+4 > zone` (ax1 abs y 64; `.large` stays 57.5).
3. **Plain subtitle cells** follow window traits at layout: body 33 /
   subheadline 30; fitting height 15+pH+6+dH+20.5 (**117** at ax1).
4. **Compact date title** shortens to `"\(m)/\(d)/\(yy)"` at
   accessibility. Font stays **17 pt** (inner label h=20); a 33 pt
   reading was the table cell’s body, not this label.
5. **Edit chrome at accessibility:** control **39×38** at x **16**,
   y **33**, gutter **55**, reorder width **41**. `.large` unchanged.

Catalyst paths are unchanged (`OpenUIKitRuntime.systemFontCut == .iOS`,
`UITableView.isIOSChrome`).

## After (SKIP_CAPTURE=1, same goldens)

| app | worst | mean | notes |
|---|---|---|---|
| Forms | **98.176** | 98.214 | was 95.084 / 95.160 |
| Feed | **99.313** | 99.420 | was 84.212 / 85.702; layout 0 |
| TableEditor | **96.287** | 97.186 | was 65.092 / 86.206; rest t200 **97.775** blob 24.5 |

Default-size Forms `/tmp/hc-conformance-Forms` scores are **identical**
to the pre-change summary (t200 **98.910**, worst **98.895**, mean
**98.933**). Default TableEditor t200 **98.411** / worst **96.938**.

## Open

- Forms compact date inner label is 20×100.5 at y+7 inside the 34 pt
  capsule; the port still uses the label as the 34 pt capsule, so
  “9/4/26” is 74.5×34. Segmented control 33 vs golden 34.
- TableEditor large title “Reminders” 239.5 vs 238.5 (1 pt). Edit-mode
  t2350.ax1 blob 37.5 (minus glyph inside the 39×38 box unmeasured).
- `--xxxl` is wired in the harness; this brief ran the three apps at
  ax1 only.

## Gates

Catalyst **124/124**. Linux `swift:6.2-noble` openrender green. Real-app
floors held (storage iPad **99.689** after keeping large-title **bold**
at `.large`). iOS suite **112/113** (known `corner_radius` 99.411).
