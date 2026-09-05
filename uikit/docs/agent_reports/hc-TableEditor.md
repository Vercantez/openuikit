# TableEditor t1350 / t2350 — delete-control fill

## What was below the bar

TableEditor mid-flight captures scored **97.16 / 97.08** against the 97.5
bar (blob 13.5 / 12.0 pt², 0 layout issues). Rest captures that are *not*
in edit mode still passed (t200 99.057, t4800 99.561). Every edit-mode rest
capture had dropped in lockstep (t900/t1900 97.843, t2900 97.822, t3800
97.811) with the same 12 pt² largest-wrong-region bbox as the title strip
— the extra ~1.15 score came from the red minus discs, not remaining spring
travel (clock-lock remaining 0.1790 is unchanged).

## Probe

`/tmp/editredprobe` on the iPhone SE 2x / iOS 26.1, same capture path as
confprobe (`.extended` + untagged sRGB). Four one-row editing tables on
white / 50 % gray / black / blue, plus swatches of `UIColor.systemRed`,
`UIColor.red`, RGB(255,56,60), the old (235,75,70), and colorprobe's
getRed() of systemRed (255,66,69).

- Disc solid fill is **(255, 56, 60)** on every backdrop (opaque, 1400 px).
- `UIColor.systemRed` swatch is byte-identical to that fill.
- getRed() (255, 66, 69) captures as itself, 10/9 counts high.
- Old (235, 75, 70) was the Display-P3-raw reading from before confprobe
  re-encoded through sRGB.

TableEditor t900 dump: `UITableViewCellEditControl` `[15, 17, 26, 26]`,
inner `UIImageView` at y 18; 22 pt disc, 10.5×1.5 pt white minus. Unchanged.

## Rule

iOS-cut `UITableViewCellEditControl.fill` is (255, 56, 60). Catalyst keeps
(235, 75, 70). Guard: `UITableView.isIOSChrome`.

## Before / after (SKIP_CAPTURE=1, same goldens)

| capture | before | after | blob | layout |
|---|---|---|---|---|
| t200 | 99.057 | 99.057 | 12 | 0 |
| t900 | 97.843 | **98.986** | 12 | 0 |
| t1350 | 97.158 | **98.266** | 13.5 | 0 |
| t1900 | 97.843 | **98.986** | 12 | 0 |
| t2350 | 97.078 | **98.208** | 12 | 0 |
| t2900 | 97.822 | **98.966** | 12 | 0 |
| t3800 | 97.811 | **98.954** | 12 | 0 |
| t4800 | 99.561 | 99.561 | 12 | 0 |

Mean 98.022 → **98.873**, worst 97.078 → **98.208**. Both named fails now
clear 97.5.

## Gates

Catalyst 124/124; real app 99.137 / 98.535 / 98.548 / 99.469 / 98.639 /
98.133 / 97.516 / 99.511 (no drop); Linux `swift:6.2-noble` openrender
green; `swift test --filter TableViewIOSEditChromeTests` 2/2.
