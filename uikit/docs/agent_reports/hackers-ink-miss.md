# Hackers feed: the "one remaining 3x ink miss" is a newline, not a key

2026-09-09 — `agent/hackers-ink-miss`.
Oracle for the score: carried iPhone 16 / iOS 26.1 golden, 1179×2556 px @3x.
Starting point: [hackers-feed-pills](hackers-feed-pills.md) (98.235).
No app source, golden, pin, or ink table changed. No simulator was created.

## Result

There is no missing key. The Linux guest render of
`realapp_hackers_feed_light` at scale 3 has **zero** iOS ink-table misses.
The "1" came from `wc -l` on a log that held a single `0x0a` byte:
`openrender` wrote `lines + "\n"` even when the miss set was empty, so an
empty set produced a one-line file. The 2026-09-07 guest rescore's
"ink misses 238 → 1" (focus-score.md) was the same byte.

| Measurement | Value |
|---|---:|
| `/tmp/guest-score-68527/ink-miss.log` (operator run) | 1 byte, `0a` |
| `/tmp/guest-score-68860/ink-miss.log` (operator run) | 1 byte, `0a` |
| `uikit-linux:/work-fbse/guest-score/ink-miss.log` | 1 byte |
| Fresh guest re-render (`/tmp/guest-score-17666`, prebuilt `/work-fbse`) | 1 byte, `0a`; `wc -l` = 1 |
| `OPENUIKIT_IOS_INK_MISS` / `Fatal` lines in `guest.log` | 0 |
| Guest score before / after (nothing to merge) | 98.235 / 98.235 |
| `glyph_ink_ios_3x.json` | unchanged |

## What the scorer's missing region is

The comparator's `missing` region `[190.7, 78, 8.7, 12.3]` (golden std 116.55,
ours 0.0) is inside the navigation title menu. In the golden the glass
capsule `[20, −4, 79.333, 44]` holds the **"Top"** label and a
`chevron.down.circle.fill` symbol; the port paints the capsule and nothing
inside it. The layout tree has both children at the right frames
(`UILabel [14, 11.833, 29.333, 20.333]`, `_SystemSymbolView [51.333, 13, 18, 18]`
under `_SwiftUIMenuControl [0, 0, 119.333, 36]`), so this is a SwiftUI `Menu`
label draw gap, already recorded as "title-menu ink" open in
[hackers-feed-rows](hackers-feed-rows.md) and [hackers-feed-pills](hackers-feed-pills.md).
It is not a table miss: the label draws no glyphs at all, so no lookup
happens and nothing can be harvested for it. A Mac host render at 3x with
`OPENUIKIT_FORCE_IOS=1` is **byte-identical** to the guest PNG (numpy
`array_equal` on the full 1179×2556 image) and scores the same 98.235, so
the gap is port-wide, not guest-specific. Out of scope here.

## Change

`Sources/openrender/main.swift`: the `OPENUIKIT_INK_LOG` dump now writes one
newline-terminated key per line and an **empty file for an empty set**
(`writeInkLog`), replacing the two copies of `lines + "\n"`. No reader
depended on the trailing newline: `scripts/linux_realapp_verify.sh` and
`scripts/linux_guest_realapp_verify.sh` only set or unset the variable, and
`docs/KNOWN_GAPS.md` describes the file as "one key per line".

Proof on the host build (`swift build --product openrender`, debug, 26.8 s):

| Run | Log |
|---|---|
| `openrender realapp` iOS cut, scale 3, `OPENUIKIT_REALAPP_ONLY=realapp_hackers_feed_light` | **0 bytes, 0 lines** |
| `openrender render` of a 17 pt regular label `"Ωß∂ƒ"`, iOS cut, scale 2 | 141 bytes, **4 lines**: `I\|system-regular\|17\|light\|F0.0\|223`, `…\|402`, `…\|8706`, `…\|937`, last byte `0a` |

The prebuilt container tree `/work-fbse` was not rebuilt (task rule), so
the guest helper still prints "ink misses: 1" until the next container
build picks up this commit; the byte dump above is the guest evidence.

## Reproduce

```
# guest render + score (prebuilt /work-fbse), from uikit/
zsh <scratchpad>/guest_render_score.sh /work-fbse realapp_hackers_feed_light 3
xxd /tmp/guest-score-<pid>/ink-miss.log          # 00000000: 0a
# host proof of the log fix
swift build --product openrender
OPENUIKIT_FORCE_IOS=1 OPENUIKIT_REALAPP_SCALE=3 OPENUIKIT_BACKEND=quartz \
  OPENUIKIT_REALAPP_ONLY=realapp_hackers_feed_light OPENUIKIT_INK_LOG=/tmp/zero.log \
  ./.build/debug/openrender realapp /tmp/out fixtures/realapp/assets
wc -c /tmp/zero.log                              # 0
```
