# iOS software-keyboard chrome (default alphabetic)

Focusing a text field or text view on iOS 26.1 puts a real keyboard on
screen (`UITextEffectsWindow` / `UIRemoteKeyboardWindow`). The port already
applied the SE overlap inset (`UIScrollView.iOSKeyboardOverlap` = 260) but
drew nothing, so a capture with a first responder was missing the keyboard
(the Linux trial's Forms t2100 was byte-identical to t1200). This branch
draws a measured default alphabetic keyboard under the iOS cut and
composites it above the app window at capture time.

Catalyst does not install the window. Layout dumps stay the app window
only (extra `"Q"` labels would create `layout_issues`).

## Oracle

`drawHierarchy` of the app window has **no keyboard**. kbprobe
(`/tmp/kb-se`, not in the repo): `UITextEffectsWindow` snapOpaquePixels = 0.
Focused goldens are therefore a `simctl io screenshot` via a NEED_SHOT /
GOT_SHOT handshake in `scripts/conformance_probe_sim.sh`; unfocused
captures stay `drawHierarchy` so they do not move. One confprobe process
per run; watcher starts **before** `--console-pty`.

Device: iPhone SE 3rd gen 2x, iOS 26.1, status bar hidden, window 375×667
(`OpenUIKit-2x-keyboard-chrome`). iPhone 16 3x (`/tmp/kb-16`) is recorded
but not drawn — conformance apps run on the SE.

## Measurements (kbprobe + Forms / Notes t1200)

`keyboardWillShow` `frameEnd` **`[0, 407, 375, 260]`**, duration **0.3833 s
= 23/60**, curve **7** (public easeInOut). `UITextEffectsWindow` level **1**,
full-screen. Placeholder `_UIRemoteKeyboardPlaceholderView`
`[4.5, 407, 366, 260]`.

Panel (full-width, top corners only):

| | sample |
|---|---|
| frame | `[0, 407, 375, 260]` (667 − 260 = 407) |
| top-corner r | **26** (left edge at y=407 is 26 pt) |
| light mix | over white **(226, 228, 232)**, over black **(156, 158, 161)** → **α = 185/255**, T = (156, 158, 161)/185 |
| dark mix | over black **(23, 23, 23)**, over white **(66, 66, 67)** → **α = 212/255**, T = 23/212 |
| letter / special / space caps | light **opaque 255**, dark **(61, 61, 61)** |
| letters | black / white; 22 pt regular UILabel (brief: label path). Q golden ink bbox **12×17**; UILabel 22 pt is **14.5×17.5**, corr 0.80 at best 1 px shift |
| `"123"` | 16 pt regular |
| QuickType | **52 pt**. Empty: no suggestion ink. Two 1 pt (2 device-px) dividers at x **125.5 / 247.5**, y 420–443.5. Light RGB **(208, 210, 214)** vs panel 226. Dark mid **(54, 54, 58)** over panel ~27 = 0.12 white over 28 |

Key rows (window y; letter 30.5×42, r=7, h-gap 6, v-gap 12, left 8.5):

| row | y | keys |
|---|---|---|
| 1 | 459 | QWERTYUIOP at xs `8.5, 45, 81.5, 117.5, 154, 190.5, 227, 263.5, 299.5, 336` (two keys width 30.0) |
| 2 | 513 | ASDFGHJKL at x0 **26.5** |
| 3 | 567 | shift **41.5** @8.5, ZXCVBNM, delete **41.5** @325 |
| 4 | 621 | 123 **39.5**, emoji **39.5**, mic **30.5**, space **139.5**, return **85** |

Bottom pad 4 (621+42 = 663). Empty field = uppercase + return arrow (Forms
`focus-name`, Notes `focus-body`). Appear animates 23/60 s; rest captures
sit ≥ 0.6 s after focus so the model is at rest.

iPhone 16 3x: window 393×852, `frameEnd` **`[0, 517, 393, 335]`** (335 = 260
+ home-indicator band), same duration / curve / level. Not modelled.

## Rule (iOS cut only)

`OpenUIKitRuntime.systemFontCut == .iOS`. `_UIKeyboardWindow` at level 1
(do not `makeKey()`, do not set `windowScene`). Show/hide from
`UIResponder.becomeFirstResponder` / `resignFirstResponder` when `self is
UIKeyInput`. `renderCapture` composites the overlay with straight-alpha
source-over **only if** `appWindow.firstResponder is UIKeyInput`. Letters /
`"123"` are `UILabel`s; shift / delete / emoji / mic / return are stroked
or filled `drawContent` stand-ins (SF Symbols are private). Sample table
is in `Sources/OpenUIKit/UIKeyboardChrome.swift`.

Notes conformance app (`Sources/ConformanceApps/Notes`): empty
`UITextView`, `focus-body` / `blur`, captures 0.20 / 1.20 / 2.10. Tabs
`focusSearch()` also `searchBar.becomeFirstResponder()` (comment already
said “tapping the search field”; `isActive` alone can leave
`UISearchBarTextField.isEditing` false while the remote keyboard is up).

## Before / after

Unfocused captures must not move. They did not.

### Forms light (`/tmp/flow-keyboard-chrome-Forms`)

| capture | first responder | before (no keyboard pixels) | after | blob |
|---|---|---|---|---|
| t200 | no | 98.910 | **98.910** | 17.8 date capsule |
| t1200 | name field, empty | ~98.9 (blank band both sides) | **96.811** | 137 at delete `[333.5, 579, 24.5, 18]` |
| t2100 | + typed text | ~98.9 | **96.313** | 159 at shift `[19.5, 579.5, 20, 17]` |
| t3000 | yes | ~98.9 | **96.277** | 159 |
| t3900 | yes | ~98.9 | **96.274** | 159 |
| t4800 | yes | ~98.9 | **96.264** | 159 |
| t5700 | no (blur) | 98.966 | **98.966** | 17.8 |

Mean **97.116**, worst **96.264**. t200 / t5700 byte-score identical to
the pre-keyboard rest floors.

### Forms dark

t200.dark **97.633** / t5700.dark **97.654** — exact match to conf-dark rest.
Focused t1200.dark **95.362**, t2100–t4800.dark **94.875–94.824**, blob 213
at emoji `[64.5, 632, 19, 19]`. Mean **95.721**.

### Tabs light (`/tmp/flow-keyboard-chrome-Tabs`)

Unfocused unchanged vs tabs-rows: t200 **96.652**, t1000 **99.402**,
t2000 **84.634** (was 84.643), t3000 **96.892**, t6000 **87.482**, t7000
**92.529**.

| capture | before (tabs-rows, no keyboard pixels) | after | blob |
|---|---|---|---|
| t4000 focus-search | 96.341 | **93.665** | 137, same delete as Forms t1200 |
| t5000 type-search | 96.623 | **93.246** | 3443 at return `[281.5, 621, 85, 42]` |

t5000's return key is a **search glyph** on iOS, not the default return
arrow. The default alphabetic layout is the measured rule; it is not
retuned for search.

### Tabs dark

Unfocused: t200.dark **97.245**, t2000.dark **84.848**, t6000.dark
**88.218**, t7000.dark **93.016**. Focused t4000.dark **92.351** (emoji
blob 213), t5000.dark **91.959** (return 3505).

### Notes (new app)

| capture | light | dark |
|---|---|---|
| t200 | **99.904** | **99.866** |
| t1200 focus-body | **98.306** | **98.273** |
| t2100 blur | **99.904** | **99.866** |

t1200 is above the 97.5 bar both styles (same delete/emoji blob as Forms,
less leftover elsewhere). Mean light **99.371**, dark **99.335**.

## Open (not modelled)

1. **Letter caps.** Private key-cap font ≠ UILabel 22 pt regular. Brief
   requires the label path. Residual is in every focused light capture.
2. **Special-key SF Symbols** (outline delete, emoji face, globe/mic,
   return / search-return). Stroke stand-ins. Samples in
   `scoreboard/open.txt`.
3. **QuickType with typed text.** Suggestions appear in some goldens;
   empty bar is material + two dividers only.
4. **iPhone 16 keyboard height 335.** Conformance is SE 260.
5. **Appear animation frames 0..20.** Duration and curve measured;
   rest captures do not sample mid-flight.

## Gates

- Catalyst **124/124** (keyboard window is iOS-cut; unfocused composite is
  a no-op).
- iOS suite **112/113** (`corner_radius` 99.411, known).
- Real app unchanged **99.137 / 98.535 / 98.548 / 99.469 / 98.639 /
  98.133 / 97.516 / 99.511 / 82.192 / 99.760 / 99.689 / 85.393**.
- Linux `swift:6.2-noble` `openrender` green.
- `KeyboardChromeTests` + `KeyboardAvoidanceInsetTests` +
  `ConformanceRegistryTests` + `SwiftUIAppLifecycleTests` pass.
