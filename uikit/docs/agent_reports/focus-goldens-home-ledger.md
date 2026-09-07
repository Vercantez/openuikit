# Focus home + Ledger iOS goldens — agent/focus-goldens-home-ledger

Date: 2026-09-07. Base: `f0e0382f` (`origin/main`). Task: the two
`CANNOT` rows of `focus-score.md` (`realapp_focus_home_light`,
`realapp_ledger_light`) had no carried iOS golden. Capture them the way the
sibling phone goldens were captured, carry and register them, score the
Linux Mach-O guest against them. Full numbers and frames are in the
addendum of [focus-score.md](focus-score.md); this file is the short form.

## What was measured

| step | result |
|---|---|
| `REALAPP_DEVICE=iPhone-16 SIM_DEVICE_SUFFIX=-focus-goldens-home-ledger scripts/realapp_probe_sim.sh` | iOS 26.1 (23B86), 393×852 @3 → 1179×2556, light, `UICTContentSizeCategoryL`; 69 files, both screens present |
| same-family proof | `realapp_settings_light`, `_history_light`, `_storage_light`, `_focus_settings_light`, `_hackers_feed_light`, `_settings_light_ax1` from this run are **byte-identical** to the carried goldens |
| rest proof | second fresh launch: both PNGs and both layout dumps **byte-identical** |
| carried | `goldens/ios/golden_realapp_ios/realapp_focus_home_light.*` (3 files), `realapp_ledger_light.*` (11 files); `manifest.json` sha256 rows; `FORCE=1 scripts/goldens_restore.sh golden_realapp_ios` → 85 files verified |
| guest build | `/work-focus-goldens` snapshot of this branch in `uikit-linux`, `full/scripts/build_full.sh` rc=0, `FOCUS_GUEST_BUILT`, both success stamps |
| guest render | `machorun render_full realapp`, `rendered=15 failed=0`, phones 1179×2556 |
| `realapp_focus_home_light` | **99.325 PASS** (bar 97.5); blob `[187.7,701.7,5.7,8.7]` = one blank 12 pt glyph (3x misses `I3\|system-regular\|12\|light\|F0.0\|{48,98,100,107}`) |
| `realapp_ledger_light` | **87.915 FAIL**; 28 unharvested 3x ink keys (15 semibold 17, 6 regular 13, 4 regular 17, 3 medium 17), `Loopback FX` row absent (5 cells vs 6), title/subtitle x 40 vs 36 |

## Honest boundaries

- The unmodified full guest driver never sets `realAppScale`: on main it
  renders phones at 786×1704 @2, and the first scale-3 run traps on
  `I3|system-regular|13|light|F0.0|71` in `realapp_storage_light`. The
  scores above come from a container-only scoring copy that sets the scale
  to 3 and enables the miss-log fallback — the same two temporary changes
  focus-score.md's own run made. Nothing of that is committed here.
- `scripts/realapp_probe_sim.sh` had drifted from the RealAppProbe sources
  (multi-file Onboarding stub, DesignSystem surface, `OpenUIKitRuntime`
  guard); the three fixes are Darwin-compile-only and touch no app source.
- The browser golden (`realapp_focus_browser_light.*`, commit `e96bcabb`)
  is still not listed in `goldens/ios/manifest.json`, so
  `goldens_restore.sh` does not copy it to `/tmp`; unchanged here, out of
  scope.
- No OpenUIKit rule, ink table or golden PNG was edited.

## Reproduce

```sh
# Mac, from uikit/
REALAPP_DEVICE=iPhone-16 SIM_DEVICE_SUFFIX=-<you> scripts/realapp_probe_sim.sh /tmp/cap-<you>
python3 Tools/compare/compare_realapp.py --golden goldens/ios/golden_realapp_ios \
  --out <guest render dir> --scale 3 --golden-straight-alpha
```
