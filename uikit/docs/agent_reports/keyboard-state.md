# Keyboard state from the first responder

The measured default alphabetic keyboard (docs/agent_reports/keyboard-chrome.md)
always drew uppercase keys, a filled shift, an empty QuickType bar, and a
return arrow. Real iOS 26.1 varies that chrome from the first responder's
traits and text.

## Oracle

Probe: `/tmp/kbstateprobe` (not in the repo). Captures:
`/tmp/kbstate-se-light`, `/tmp/kbstate-se-dark`, `/tmp/kbstate-ipad-light`.
Device: iPhone SE 3rd gen 2x (`OpenUIKit-2x-keyboard-state`) and iPad (A16)
820×1180 @2x (`OpenUIKit-iPad-A16-keyboard-state`), iOS 26.1. Conformance
replays: `/tmp/ks-Forms`, `/tmp/ks-Tabs`, `/tmp/ks-Notes` (+ `-dark`,
`-ipad`, Notes `-ax1`/`-xxxl`).

`drawHierarchy` of the app window still has no keyboard; focused goldens
are `simctl io screenshot` via NEED_SHOT.

## Measurements (kbstateprobe, SE 2x light)

| case | keys | shift | return | QuickType | height |
|---|---|---|---|---|---|
| empty UITextField `.sentences` | uppercase | filled | white arrow | empty dividers | 260 |
| `"Alex Rivera"` caret at end (sel 11/11) | lowercase | outline | white arrow | `"Rivera"` left | 260 |
| empty `.none` | lowercase | outline | arrow | I / The / I'm | 260 |
| `"hello"` + `.none` | lowercase | outline | arrow | hello / hey / he | 260 |
| UISearchBar empty | uppercase | filled | **gray** mag | empty (autocorr `.no`) | 260 |
| search `"Meet"` | lowercase | outline | **blue** mag | empty | 260 |
| UITextView `"…lunch."` | lowercase | outline | arrow | I / I'm / I'll | 260 |
| empty UITextView | uppercase | filled | arrow | I / The / I'm | 260 |
| `.numberPad` | 3×4 1–9, 0, delete | — | none | none | **233** `[0, 434, 375, 233]` |
| `returnKeyType .search` empty field | uppercase | filled | **blue** mag | I/The/I'm | 260 |
| `.go` | — | — | blue right-arrow | — | 260 |
| `.done` | — | — | blue checkmark | — | 260 |

Caps rule (fits every sample): `.none` → never; `.allCharacters` → always;
`.sentences`/`.words` at document start or after `.?!` **followed by
whitespace**. Trailing `.` with no space stays lowercase.

Shift fill ink fraction ~0.108 vs outline ~0.045 (empty_sentences vs
has_text). Search empty return interior **(190, 192, 195)**; with text
`systemBlue` `(0, 122, 255)` + white glass. UISearchBar.searchTextField:
`returnKeyType=6`, `autocorrectionType=1`.

Number pad SE: keys 113.5×47, xs `7.5 / 129 / 250`, row y panel-local
`24 / 78 / 132 / 186`, pitch 54. No QuickType.

iPad A16 docked alphabetic: `frameEnd [0, 843, 820, 337]`. Shortcut bar
64 pt. Letter keys 51×52, pitch 65, key height 52, v-gap 12. Row y
64 / 128 / 192 / 256. Same caps / search-return state machine. `.numberPad`
on pad is the numbers/symbols plane at height 337, not the phone 3×4
(OPEN). Scroll overlap stays **312** (= 337 − 25 SA.bottom).

SF Symbol harvest (`shift`, `delete.left`, `globe`, `mic`,
`magnifyingglass`, …) did not match the private key-cap glyphs; stroke /
fill stand-ins stay.

## Rule (iOS cut only)

`_UIKeyboardResolved.resolve(from:)` reads UITextField / UISearchTextField
/ UITextView. Phone alphabetic overlap 260, number pad 233, pad 337.
UISearchBar.configureSearchField sets `.search` + `.no`.
UISearchController.isActive does **not** become first responder (Notes
`focusSearch` is `isActive` only; Tabs still calls
`searchBar.becomeFirstResponder()`). Keyboard sync after
`becomeFirstResponder` moves the caret to document end (has_text sel
11/11) and after `.text` assignment while editing (Forms `typeName`).

## Before / after

Before = merge-keyboard.md (always-uppercase empty-bar model). After =
`/tmp/ks-*` on `OpenUIKit-2x-keyboard-state` / `-iPad-A16-keyboard-state`.

### Forms light

| capture | first responder | before | after |
|---|---|---|---|
| t200 | no | 98.910 | **98.930** |
| t1200 | empty name | 96.811 | **96.808** blob 137 delete |
| t2100 | `"Alex Rivera"` | 96.313 blob 159 shift | **96.769** blob 137 delete |
| t3000 | yes | 96.277 | **96.733** |
| t3900 | yes | 96.257 | **96.721** |
| t4800 | yes | 96.264 | **96.728** |
| t5700 | no | 98.966 | **98.985** |

### Tabs light

Unfocused held (t200 **96.657**, t6000 **87.496**, t7000 **92.542**).
t4000 **93.665 → 95.006**, t5000 **93.246 → 93.709** (search return closed;
leftover delete).

### Notes light

| capture | before | after |
|---|---|---|
| t200 | 77.714 | **77.822** |
| t1200 | 96.832 | **96.834** |
| t2100 focus-body | 94.593 | **95.362** blob 137 delete + QuickType words |
| t4000 isActive | 61.662 | **77.815** (no keyboard; golden has none) |
| t5000 type-search | 61.933 | **98.737** |
| t7000 | 99.111 | **99.111** |
| t4000.ax1 | 54.2 | **70.025** |
| t5000.xxxl | 53.6 | **90.378** |

### Dark

Forms t200.dark / t5700.dark **97.674 / 97.686** held. Focused
**95.404–95.309** (emoji blob 213). Tabs t4000.dark / t5000.dark
**92.353 / 92.416**. Notes t2100.dark **93.174 → 93.937**; t4000.dark
**63.133 → 75.783**; t5000.dark **61.498 → 98.156**.

### iPad

Phone keyboard on the pad had dropped focused rows to ~81. Docked pad
layout: Forms t1200 **96.347**, t2100–t4800 **~96.45**; Tabs t4000/t5000
**96.259 / 96.413**; Notes t2100 **95.646**; Notes t4000/t5000
**99.462 / 99.660**. Unfocused Forms t200 **99.228**.

## Open

1. **Letter caps.** UILabel 22 pt vs private key-cap font. Every focused
   phone capture.
2. **Special-key SF Symbols** (delete, emoji, globe/mic, pad flick,
   undock, shortcut undo/redo/paste). Stroke stand-ins. Samples in
   `scoreboard/open.txt`.
3. **QuickType suggestion text.** I/The/I'm vs `"Rivera"` vs
   AM/AMAZING/AMOUNT. Empty bar + two dividers is the alphabetic rule when
   we have no completer.
4. **Pad numbers/symbols plane** (not the phone 3×4). **iPhone 16 height
   335** still not drawn; conformance is SE 260.

## Gates

- Catalyst **124/124**.
- iOS suite **112/113** (`corner_radius` 99.411).
- Real app **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 /
  97.516 / 99.650 / 82.170 / 99.860 / 99.734 / 85.393**.
- Linux `swift:6.2-noble` `openrender` green.
- `KeyboardChromeTests` + `UISearchControllerTests` + `TextInput*` pass.
- No `Package.resolved`.
