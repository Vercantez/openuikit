# iOS 26 liquid-glass platter material

One measured mix, one function (`_UIGlassMaterial`), wired under the iOS
cut to the tab-bar platter, toolbar / bar-button platters, and the
floating `systemBackground` sheet. Catalyst and dark iOS keep the
measured flats.

## Probe family (not in the repo)

`scripts/render_sim_scenes.sh`, iPhone SE 3rd gen 2x and iPhone 16 3x /
iOS 26.1. Four backdrops (white, black, captured systemRed (255, 56, 60),
horizontal white→black gradient) behind a `UIToolbar` with two items, a
`UITabBar` with three items (one selected), and a `UINavigationBar` with
a back item. Split-edge probe `glass_sigma_edge_se` (white|black through
the first grouped toolbar platter). Glyph-free interiors, 1–2 px ring,
capsule `r = height/2`.

## Samples (SE 2x = iPhone 16 3x for interiors)

| backdrop | toolbar / tab unselected | selected tab capsule |
|---|---|---|
| white (255,255,255) | (253,253,253) | 235 |
| black (0,0,0) | (220,220,220) | 198 |
| systemRed (255,56,60) | (255,201,204) | (240,175,179) |
| white→black gradient | dL 6.7 over 76.5 pt | — |

Nav back platter over white is 255 (refraction wash); Focus Done over
the unpainted bar is 220. Floating systemBackground sheet interior 245
is the same mix over the 20 % dim (k·204 + 220 = 246.4, residual 1.4).

## Two-unknown mix

`out = (1 − α) · blur(B, σ) + α · T` with T gray.

White 253 and black 220 ⇒ **α = 222/255**, **T = 220/α = 252.703/255**
(equivalently k = 33/255, c = 220). Gradient flatten predicted 6.76 vs
measured 6.7.

**Red residual (not fitted — a third saturation unknown):** predicted
(253.0, 227.2, 227.8) vs measured (255, 201, 204). Fixtures stay on
white / black / #F2F2F7.

**σ:** erf fit on the split-edge scan at platter-local y = 8, x = 140…160:
**σ = 2.25 pt**, μ = 149.20, rms 1.04 (10–90 % = 6.0 pt → 2.34). Same
method as the scroll-edge pocket's σ = 1.85 (rms 1.1).

**Ring:** 2 device px (= 1 pt at 2x) inside the geometric edge. Black:
dx=0,1 are 240/233, dx=2 is 220. Second-pixel
`233 = (1−a)·220 + a·255` ⇒ **a = 13/35**. Stroke 2 pt under the clip
so only the inner 1 pt remains.

**Selected-tab capsule:** black overlay **18/253** on the glass (white
253→235). Over black: predicted 204 vs measured 198 (residual 6) —
reported, not a third unknown.

## Implementation

`_UIGlassMaterial.apply` is the Canvas backdrop-filter path (same kernel
as `UIVisualEffectView`). CQuartz has no destination-sampling node;
`containsRenderPassOnlyEffect` selects RenderPass when `_usesIOSGlass`
is set. Guard: `OpenUIKitRuntime.systemFontCut == .iOS` and light style.
`.done` / prominent platters stay tint-filled.

`openrender realapp` paints the window black before sampling: the iOS
probe uses `UIGraphicsImageRendererFormat.opaque = true`, so unpainted
pixels are (0,0,0,255) *at sample time*. A post-pass on zero-alpha
cannot repair a translucent frost already written over a transparent
Bitmap. Pocket Casts screens are fully painted and did not move.

## Before / after

### Tabs (`scripts/conformance_flow.sh`, SE 2x)

| capture | before | after | notes |
|---|---|---|---|
| t200 | 92.929 | 92.904 | selected SF Symbol blob remains |
| t1000 | 97.794 | **99.218** | toolbar glass over content |
| t2000 | 84.570 | **84.643** | worst |
| t3000 | 93.169 | 93.145 | |
| t4000 | 92.658 | 92.633 | |
| t5000 | 92.895 | 92.845 | |
| t6000 | 88.172 | 88.167 | |
| t7000 | 92.262 | 92.200 | |
| **mean** | **91.806** | **91.969** | |
| **worst** | **84.570** | **84.643** | |

### NavFlow

| capture | before | after |
|---|---|---|
| t200 | 99.624 | 99.622 |
| t1200 | 98.806 | **99.248** |
| t2100 | 99.624 | 99.622 |
| t3000 | 98.196 | 98.196 |
| t3900 | 98.796 | 98.796 |
| t4800 | 98.336 | 98.333 |
| **mean** | **98.897** | **98.969** |
| **worst** | **98.196** | **98.196** |

### Modal

| capture | before | after |
|---|---|---|
| t600 | 97.588 | **97.639** |
| t1200 | 97.805 | **97.937** |
| t5200 | 97.902 | 97.842 |
| **mean** | **99.091** | **99.099** |
| **worst** | **97.588** | **97.639** |

Rest captures 99.8xx unchanged to 0.01. t1200 leftover is still presenter
dim of button ink (~2 %), not the card fill.

### Focus Settings

| screen | before | after | blob |
|---|---|---|---|
| realapp_focus_settings_light | 80.345 | **82.192** | 3668.9 at Done `[286, 44, 107, 69]` → **481.7** at `[290, 733, 63, 19]` |
| Done interior (3x, unpainted bar) | 255 | **220** | matches golden 220 |
| eight Pocket Casts + three iPad | unchanged | 99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 / 99.760 / 99.689 | |

### Suite bar chrome (SKIP_CAPTURE=1 `/tmp/ios_suite`)

tabbar_basic 99.806, tabbar_tinted 99.495, tabbar_dark 99.113 (flat dark,
unmeasured mix), toolbar_basic 98.997, navitem_buttons 98.908,
navbar_appearance 99.342.

## Open

- Two-unknown mix's red residual (G −26, B −24). Not a fixture backdrop.
- Selected-tab capsule over black: pred 204 vs meas 198 (residual 6).
- 3x ring is slightly brighter on the golden (247 vs our 233 at one edge
  sample); σ and α were fit at 2x. Not retuned to the 3x score.
- Search-bar field pill and `UISearchBarBackground` are still the older
  flat-glass stand-in (not this function).
- System back-chevron control still has no platter of its own (probe used
  a `leftItems` title item, which does).

## Gates

Catalyst **124/124**. iOS suite **112/113** (known `corner_radius` 99.411).
Linux `swift:6.2-noble` openrender green. Unit tests
`GlassMaterialTests` (mix 253/220, Catalyst flat, `.done` not glass),
`BarButtonItemTests`, `SheetDetentTests.testFloatingSystemBackgroundGlassFillOnIOS`
(paintedFillColor 245 property kept).
