# Known gaps (living document — fixers: read this)

## App compatibility (M12, 2026-08-25): what a real app still cannot do

Effective coverage is **88.5%** of what four real open-source apps reference
(docs/APP_COMPAT.md). The honest headline is the other one: **no corpus app
compiles end to end yet**, and the reasons are structural rather than
long-tail.

- **Delegate protocols that do not exist stop compilation before behaviour
  does.** `UITextFieldDelegate`, `UITextViewDelegate`,
  `UIGestureRecognizerDelegate`, the `UICollectionView` trio and the
  presentation-controller delegates are all referenced by the corpus (144
  uses, some in all four apps) and are simply absent — a `class Foo: UIView,
  UITextFieldDelegate` fails on the conformance name. These are the cheapest
  points on the whole punch list and the first thing a fixer should take.
- **No `UIBarButtonItem`, therefore no real `UINavigationItem`.** 270 uses,
  every app. The nav bar shows `vc.title` plus a back button and nothing else;
  there is no way to put a button in a bar.
- **No `UICollectionView`** (498 uses across 23 types, every app). The reuse
  machinery — per-identifier pools, `dequeueReusableCell`, tiled visible-rect
  layout — exists only inside `UITableView` and has to be lifted into a shared
  layer first.
- **No notifications, anywhere.** `NotificationCenter` is Foundation, which
  the library may not import, so `UIApplication.didBecomeActiveNotification`,
  the keyboard notifications and `UIDevice.orientationDidChangeNotification`
  do not exist (~90 uses). An app that observes instead of implementing the
  delegate hears nothing. Closing this needs a portable notification center.
- **No `UIVisualEffectView`, so nothing in the framework blurs** — see the
  alerts section below for the fitted flat model and exactly where it is
  wrong. This is now a cross-cutting divergence, not an alert detail: it
  covers the alert card and pills, the sheet grabber, the tab-bar platter,
  the `UIPageControl` background and (M13) every **bar-button platter** in a
  navigation bar or toolbar.
- **No SF Symbols.** `UIBarButtonItem(barButtonSystemItem:)` draws one for
  most of its cases on iOS 26; OpenUIKit substitutes hand-fitted vectors of
  the measured size. See the bars section below.
- **No Dynamic Type.** `UIFontMetrics` (66 uses), `UIFont.preferredFont` (21)
  and `UITraitPreferredContentSizeCategory` (55) are all missing; text sizes
  are absolute.
- **No `UIAppearance` proxies** (`UINavigationBar.appearance()` etc., ~20
  uses) and no `UIView.setAnimationsEnabled` (92 uses — the single most-used
  missing member on a type we do implement).
- **Selectors: `addTarget(_:action:for:)` still takes a closure.** Not because
  it cannot be otherwise — the M12 measurement retracted the earlier verdict
  and showed `@objc`/`#selector` compile, link and run on stock Linux Swift
  with a ~10-line shim (`Tools/objcshim/verify.sh`). It simply was not
  adopted. `UIApplication.sendAction`'s nil-target chain walk is faithful; the
  spelling is not.

## Two cuts of San Francisco (2026-08-25): the fixture suite has two oracles

**RESOLVED** — this section used to read "`alert_dark` fails the absence gate
… OWNER: text", diagnosed as real iOS "tightening alert label advances" and
needing a per-alert tracking model. That diagnosis was wrong. The defect was
neither alert-specific nor tracking: **Apple ships two different builds of
San Francisco and UIKit picks one by platform.**

    Mac Catalyst   UIFont.systemFont -> .SFNS-*   (macOS cut)
    iOS 26.1       UIFont.systemFont -> .SFUI-*   (iOS cut)

Same outlines, same `wght`, same clamped `opsz`, same pair kerning — but the
iOS cut is spaced TIGHTER below 20 pt. Re-taking the whole `oracle
fontmetrics` dump on iOS (`Tools/oracle2/fontprobe`,
`scripts/font_probe_sim.sh`, vendored as `golden/font_metrics_ios.json`) and
diffing it against the Catalyst one (`golden/font_metrics.json`) gives an
exact law over all 432 font entries x 95 printable ASCII glyphs — maximum
deviation **0.000000000 pt**:

    advance_macOS(c, size) - advance_iOS(c, size) = T(size) * size / 2048

| size | 8 | 9 | 10 | 11 | 11.5 | 12 | 13 | 13.5 | 14 | 15 | 16 | 17 | 17.5 | 18 | 19 | >=20 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| T (font units) | 50 | 50 | 50 | 46 | 45 | 44 | 41 | 41 | 40 | 38 | 37 | 37 | 31 | 25 | 12 | **0** |

T does not depend on the glyph or the weight — only on the point size, the
signature of a spacing difference rather than different outlines. It is zero
at every size >= 20 pt (exactly where SF switches from the Text optical face
to Display) and zero for the monospaced family at every size (SF Mono has no
optical-size axis). Italic tracks system. Pair kerning is IDENTICAL: feeding
the Catalyst kerning table the iOS advances reproduces the iOS
`stringWidths` with residual **0** over all 432 x 6 reference strings.

Why it surfaced as one alert scene: `scripts/regen_goldens.sh` routes scenes
with an `"alert"` or a `"modal"` key — and only those — through the iOS
Simulator, because Catalyst bridges `UIAlertController` into an AppKit panel
and a pageSheet into an AppKit sheet window. Those six goldens are set in
`.SFUI`; every other golden is set in `.SFNS`, which is what the vendored
table describes and what the rasterizer's `SFNS.ttf` draws. Laying an
`.SFUI` golden out with `.SFNS` advances accumulates ~0.31 pt per character
at 17 pt, so the 12-glyph alert title "Delete File?" ended 3.7 pt wide and
its "?" left the golden's ink behind — the 2.5 x 2.0 pt hole the absence
gate reported. The absence gate was right; the metrics were wrong.

Fix: `FontEngine.SystemFontCut` (`OpenUIKitRuntime.systemFontCut`, default
`.macOS`) subtracts the measured T(size) when the iOS cut is selected, and
`runScene` selects it for the Simulator-routed scenes. Every one of the six
improved — nothing else moved:

| scene | pixels | worst blob (pt^2) |
|---|---|---|
| `alert_dark` | 98.475 **FAIL** -> 98.569 PASS | 30.8 -> 5.0 |
| `alert_destructive` | 98.602 -> 98.726 | 42.2 -> 3.0 |
| `alert_actionsheet` | 98.105 -> 98.228 | 36.8 -> 5.0 |
| `alert_basic` | 98.917 -> 98.999 | 7.5 -> 11.8 |
| `modal_sheet` | 99.324 -> 99.347 | 33.0 -> 3.0 |
| `modal_sheet_grabber` | 99.314 -> 99.338 | 33.0 -> 3.0 |

Note the third column: `compare.py`'s blob threshold is calibrated against
"worst legitimate component 33.2 pt^2 (`modal_sheet` — one stem of the 22 pt
bold title)". That residual was this bug, not a rasterization limit, and it
is now 3.0. Measured over all 96 passing scenes at the M12 tip, the worst
legitimate component is now **20.0 pt^2** (`stack_alignment`,
`anim_concurrent`) against an 80 pt^2 gate, so the gate could be tightened
considerably; that is `compare.py`'s call, not the text module's, and the
calibration comment is now stale.

### What is still NOT modelled

- **Vertical metrics also differ between the cuts** and the selector does not
  switch them. `golden/font_metrics_ios.json` vs `golden/font_metrics.json`:
  `capHeight`, `xHeight` and `leading` are identical everywhere, but
  `ascender` / `descender` / `lineHeight` differ at EVERY size, e.g. 17 pt
  semibold `lineHeight` 20 (Catalyst, a whole number) vs 20.28711 (iOS,
  unrounded), and 15 pt regular 18 vs 17.90039. iOS then puts a UILabel's
  line box at `ceil(lineHeight)` on the device's 1/3 pt grid — which is
  exactly where `UIAlertMetrics.titleLineHeight` = 20.333 and
  `messageLineHeight` = 18 came from when the alerts cluster measured them
  off the live view tree. The chrome that needs those numbers therefore
  already carries them as measured constants, `labelLineHeight`'s
  Catalyst-fitted bonus bands stay correct for the Catalyst goldens, and no
  scene currently needs the iOS line box in the general path. Modelling it
  properly means an iOS-cut branch of `labelLineHeight` with its own
  oracle-measured band table.
- **Truncation under the iOS cut is untested.** `tightTable` (the trak-based
  ellipsis / tight-tracking model) was generated offline from macOS's
  `SFNS.ttf`; `ellipsisAdvance` and `measureTight` get the cut delta applied
  on top, but no Simulator-routed fixture truncates a label, so the
  combination has no golden behind it.
- **Glyph OUTLINES still come from `SFNS.ttf`** — the rasterizer has no
  `.SFUI` font file to load (iOS's is inside the Simulator runtime). The
  residual left in the alert goldens after this fix is mostly that: our
  17 pt "D" inks about 0.5 pt left of the golden's, and stems land within
  half a point of the iOS ones rather than on them.
- The alert card sits at x = 36.5 while iOS puts it at 36.667 (UIKit rounds
  the card origin onto the 1/3 pt grid); that is 0.167 pt of the remaining
  horizontal residual and belongs to the alerts cluster, not to text.

Re-derive the iOS dump with `scripts/font_probe_sim.sh <outdir>` (needs a
booted iOS 26 simulator); `Tools/oracle2/alerttextprobe` is the narrower
probe that found the split, dumping the alert labels' fonts, attributes and
CoreText glyph positions.

## App lifecycle / environment (M12, 2026-08-25): scope notes

The cluster is `UIResponder` as a real base class + `UIApplication` /
`UIApplicationDelegate` / `UIScreen` / `UIDevice`
(docs/APP_COMPAT.md, 543 uses). Shipped: the exact UIKit responder chain
(`UIResponder.swift`), first-responder state moved off UIView onto
UIResponder (so a view controller can hold focus), touches/presses
defaulting to forwarding up the chain, `UIWindow.rootViewController` /
`makeKeyAndVisible`, and openhost booting `--app` through
`UIApplicationMain` + a real `HostAppDelegate`. What did **not** ship, and
why:

- **No run loop, therefore no self-driving lifecycle.** `UIApplicationMain`
  performs the launch sequence and RETURNS; the host drives the rest with
  five `_host…` methods (`_hostDidBecomeActive`, `_hostWillResignActive`,
  `_hostDidEnterBackground`, `_hostWillEnterForeground`,
  `_hostWillTerminate`). This is not a gap that can be closed without giving
  the portable core a run loop and a wall clock, which the architecture
  forbids. The ORDER and the `applicationState` an app observes are UIKit's;
  only the trigger differs.
- **No notifications.** UIKit posts `UIApplication.didBecomeActiveNotification`
  and friends. `NotificationCenter` is Foundation, which the library may not
  import, so the delegate callbacks are the only observation point. An app
  that observes the notifications instead of implementing the delegate
  hears nothing. Closing this needs a portable notification center.
- **`sendAction` takes a closure, not a `Selector`.** Portable Swift has no
  selectors. The nil-target chain walk — the part that actually matters — is
  faithful; the spelling is not.
- **`open(_:)`/`canOpenURL` take a `String`, not a `URL`,** for the same
  Foundation reason, and do nothing unless a host installs
  `UIApplication.urlOpenHandler`.
- **`UIDevice` values are declared, not measured** (`.phone`, "iOS",
  "26.1", "iPhone"). There is no device to interrogate and the library may
  be running on Linux; the header of `UIDevice.swift` says so explicitly.
  `UIScreen`, by contrast, IS driven by the host's real surface.
- **Scenes are minimal.** `UIScene`/`UIWindowScene`/`UISceneSession`/
  `UISceneDelegate`/`UIWindowSceneDelegate` exist so scene-shaped app code
  compiles and receives activation callbacks. There is no session
  persistence, no state restoration, no multi-window management, and
  `connectedScenes` is empty unless an app opts in — which is what keeps a
  window's next responder the application, the pre-scene shape the hosts
  boot.
- **`UIApplication.windows` counts every live window, not every VISIBLE
  one.** There is no window server to ask about visibility.
- **A first responder removed from its window does not auto-resign.** UIKit
  resigns it; here `isFirstResponder` simply goes false while the window
  still holds a weak reference. Pre-existing behavior, carried over
  unchanged by the migration.
- **A DISABLED `UIControl` still swallows touches** instead of forwarding
  them up the chain (UIKit forwards). Pre-existing; the new forwarding
  default made it visible but did not change it.
## Attributed text (M12, 2026-08-25): shadows Foundation, and what is not modelled

### The types SHADOW Foundation's — a deliberate, documented tradeoff

`NSAttributedString`, `NSMutableAttributedString`, `NSAttributedString.Key`,
`NSRange`, `NSParagraphStyle` and `NSMutableParagraphStyle` are declared **in
OpenUIKit** (`Sources/OpenUIKit/NSAttributedString.swift`,
`NSParagraphStyle.swift`). They do **not** bridge to Foundation's types and
never will: the library target imports no Foundation at all
(docs/PORTABILITY.md), which is the property that makes it build and behave
identically on Linux. Consequences a caller must know:

- An app (or test) that imports **both** OpenUIKit and Foundation sees two
  types with each of those names and the compiler reports
  `'NSAttributedString' is ambiguous for type lookup in this context`. The fix
  is a file-scope disambiguation, e.g.
  `private typealias NSAttributedString = OpenUIKit.NSAttributedString`
  (the same pattern the repo already uses for `CGFloat`/`CGRect`).
  `Tests/OpenUIKitTests/AttributedStringTests.swift` is the worked example.
- A Foundation `NSAttributedString` cannot be handed to `UILabel`; it has to
  be rebuilt. There is no conversion helper — adding one would require the
  library to import Foundation.
- Attribute values are `Any`, like Foundation's. Run coalescing compares
  values with `attributeValuesEqual`, which understands `UIFont`, `UIColor`,
  `CGFloat`/`Double`/`Int`/`Bool`/`String` and `NSParagraphStyle`; any other
  value type compares as *unequal*, so adjacent runs carrying it never merge.
  That is conservative (an extra run, never a wrong one), but
  `effectiveRange` can therefore report a shorter range than Foundation would.
- `NSMutableAttributedString.mutableString` is a plain `String` accessor, not
  a live-editing proxy.

### Measured behavior that IS modelled

All of it comes from Catalyst probes (`Tools/attrprobe/run.sh
measure|geometry|decorations`) and is pinned by the `attrtext_*` goldens:
per-character `.kern` including the last character, `.kern == 0` disabling
pair kerning, pair kerning across run boundaries but never across fonts,
the per-run ascent/descent line box (see AttributedTextLayout's header),
`lineSpacing`/`paragraphSpacing`/`lineHeightMultiple`/min/max line heights,
head and tail indents, and the underline/strikethrough rects, which are
vendored measurements (`Resources/text_decorations.json`) because no closed
form fit the size sweep: the rect top is weight-dependent at 34 pt but not at
17 pt, and the thickness steps at sizes CTFontGetUnderlineThickness does not
predict.

### Not modelled

- **Attributed truncation.** A single-line attributed label that overflows is
  clipped, not ellipsised: the plain path's tight-tracking truncation model
  (`TextLayout.truncate`) is per-font and has no multi-run equivalent yet. No
  fixture overflows; an app that truncates attributed text will see a clipped
  last glyph instead of "…".
- **`.backgroundColor` rect.** Drawn as the run's advance width × the line
  box. Probed once (real UIKit's rect was ~1 pt shorter than the line box at
  17 pt) but not fitted, and no fixture exercises it.
- **Underline patterns and `.double`/`.thick`.** Every non-empty style draws
  the same single rule; `patternDot`/`patternDash`/`byWord` are accepted and
  ignored. Real UIKit's `.thick` and `.double` were measured (rows
  73–78 / 73–80 at 17 pt vs 75–78 for `.single`) but are not implemented.
- **`.strokeColor` / `.strokeWidth` / `.link` / attachments.** The keys exist
  so app code compiles; nothing reads them (no stroking, no
  `NSTextAttachment`).
- **`UITextField` / `UITextView` editing drops attributes.** Typing rewrites
  the plain string and clears the attributed storage; real UIKit keeps
  `typingAttributes`, which we do not model.
- **`hyphenationFactor`, `baseWritingDirection`, tab stops** are absent from
  `NSParagraphStyle` (or present and ignored, for `hyphenationFactor`).
- **`lineHeightMultiple` / min / max baselines.** The heights are golden-
  correct, but the extra space is added entirely above the baseline; only
  `lineSpacing` (which does not move the baseline) is pixel-validated by a
  fixture.

### Glyph-ink coverage: 23 misses, NOT harvested (measured decision)

`OPENUIKIT_INK_LOG` over the six `attrtext_*` scenes reports **23** table
misses — glyphs the harvested-mask fast path does not have, which fall
through to the computed GlyphSmoothing rasterizer (system-regular 13/15/20/24/34,
system-semibold 17, system-bold 17, plus one dark 13 pt cell). They were left
unharvested on purpose: every scene passes with margin anyway
(`attrtext_runs` 98.6, `attrtext_paragraph` 99.3, `attrtext_underline_strike`
99.3, `attrtext_kern_baseline` 99.99, `attrtext_dark` 99.9,
`attrtext_fields` 99.1 against a 97 % text / 96 % control threshold, largest
severe blob 17.8 pt² against an 80 pt² gate). Harvesting those cells is the
next fidelity step if a future fixture in these sizes runs tight; the recipe
is the "Glyph ink harvest" section below.
## Bars & appearance (M13, 2026-08-25)

`UIBarButtonItem` (270 uses), `UINavigationItem`, `UIToolbar` and the
`UIBarAppearance` family are measured from real iOS 26.1 (iPhone 16, compact)
through `Tools/oracle2/simscene` — the fixtures `navitem_buttons`,
`navitem_titleview`, `navitem_dark`, `navbar_appearance` and `toolbar_basic`.
Re-probe any of it with

    SIMCTL_CHILD_SIMSCENE_DEBUG=1 scripts/render_sim_scenes.sh <outdir> <scene.json>

which prints the full private view tree (frames, fonts, colors) for every
scene it renders. What is NOT faithful:

- **The platters are glass; ours are flat.** iOS 26 puts every bar button in
  its own capsule that samples, blurs and refracts the backdrop. We draw the
  measured flat equivalent (white in light mode, (25, 25, 25) in dark) plus a
  shadow whose (opacity 0.075, sigma 10, offset (0, 4)) are a least-squares
  fit to the golden's own falloff — `python3 Tools/compare/fit_bar_shadow.py`,
  rms 2.3 counts. Over a flat neutral backdrop that is what the golden shows
  (over white the platter is literally invisible apart from its shadow). Over
  a **saturated** backdrop it is wrong in hue exactly like the alert card:
  probed over #FF0000 the real platter renders pink and the labels lose their
  tint entirely, and probed over a #FFCC00 opaque bar the whole bar reads
  (247, 206, 70) rather than the (255, 204, 0) that was set — the edge effect
  and the glass both recolor it. **A fixture must not put bar items over a
  saturated backdrop**; the shipped ones use white, black and #F2F2F7.
- **The refractive band is a fitted approximation.** Measured on two goldens,
  the top **14.5 pt** of a 44 pt navigation-bar platter shows the backdrop
  unchanged instead of the frosted fill. We reproduce it by washing that band
  back to the bar's own background color, which only works when the bar HAS a
  flat background; over a transparent bar the band stays frosted. A
  standalone `UIToolbar` platter probed over a saturated backdrop shows a
  UNIFORM fill with no band at all, so toolbars do not apply it — the reason
  for that difference is not understood, it is simply what both probes show.
- **No SF Symbols, so most system items are approximations.** Measured:
  exactly `.edit` and `.save` render as TEXT ("Edit" / "Save") on iOS 26 and
  are therefore exact; `.done` is the PROMINENT style (a tint-filled capsule
  with a white checkmark, and `UIBarButtonItem.Style.done` was literally
  renamed `.prominent`); everything else is an SF Symbol. `_BarSymbol` draws
  a hand-fitted vector of the MEASURED bounding box and stroke weight for
  each one — recognizable, correctly sized and correctly colored, but not the
  same outline. **No golden gates them and no fixture uses one**; the
  fixtures use `.edit`/`.save`, custom titles and synthesized template images.
- **Untinted bar buttons render `label`-colored, not tinted.** This surprises
  people, so it is worth restating: it is MEASURED, twice. Setting
  `navigationBar.tintColor = .systemBlue` still produces black glyphs on
  iOS 26; only an item's OWN `tintColor` is honored. Apps that expect blue
  bar buttons will see black — and so will they on real iOS 26.
- **No item cross-fade during push/pop.** The title and back button animate
  (M7.5), the item platters swap instantly.
- **Toolbars do not merge adjacent image items.** A run of image-only items
  in a real toolbar sometimes shares ONE long platter (measured: six symbol
  items did, a mixed text/symbol row did not, and two symbol items in a
  navigation bar did not). The rule was not pinned down; OpenUIKit always
  gives each item its own platter, which is what every measured *navigation
  bar* does. `toolbar_basic` therefore uses title items only.
- **`isTranslucent` is stored and ignored** (no blur to be translucent with),
  and `UIBarAppearance.backgroundEffect` is accepted and ignored.
- **`configureWithDefaultBackground()` == transparent for a static bar.**
  iOS 26's default bar is transparent at rest and gets its material from the
  scroll-edge effect once content passes under it; that effect is modelled
  only in the large-title path (`UINavigationBar.updatePocket`).
- **`UINavigationBar`'s default appearance is OPAQUE, not iOS 26's default.**
  A deliberate compatibility choice: it keeps the inline bar looking like it
  did before M13 for hosts and demos. Set `standardAppearance` explicitly for
  the iOS 26 look. No golden covers the default.

One guessed constant was **replaced** by measurement in M13: the inline
navigation bar's zone split was a 20 pt "status inset" + a 44 pt content bar
(title centre 42). Real iOS 26 is 10 + 54 with the title centre at **32**,
which is the same 64 pt total M10 already measured for the large-title bar's
inline zone. `UINavigationBar.barHeight` is unchanged, so nothing below the
bar moved.

## Alerts + custom transitions (M12, 2026-08-25)

Everything in `Sources/OpenUIKit/UIAlertController.swift` is measured from
real iOS 26.1 by `Tools/oracle2/alertprobe` (20 configurations, full private
view-tree dumps + window snapshots + a display-link sampling of the present
animation; `scripts/alert_probe_sim.sh`). What is NOT faithful:

- **No `UIVisualEffectView`, so nothing actually blurs.** The alert card and
  the button pills are live blurs in real UIKit. Here they are the measured
  FLAT equivalents: a least-squares fit of `out = k·base + m` over four
  neutral bases per appearance, giving alpha 0.7143 of 0.9937-white over the
  backdrop (light) / alpha 0.6506 of 0.0989-black (dark) for the card, and
  alpha 0.1372 of 0.109-black / alpha 0.1097 of white for the pills, applied
  over the card. Residual under 1.5 counts over the whole measured range on
  a FLAT backdrop — but a patterned backdrop shows through unsmeared, and a
  saturated one is wrong in hue: the real material desaturates (measured: a
  pure-red base gives (242, 168, 166) under the card where the flat model
  predicts (234, 193, 189)). Same limitation as the sheet grabber and the
  tab-bar platter.
- **The card's corners are CIRCULAR, real UIKit's are `continuous`.** A
  superellipse fit of the golden's corner profile is r = 41.5 with exponent
  2.6 (rms 0.36 pt) against 0.81 pt rms for the best circular fit (r = 32.3).
  We draw `layer.cornerRadius = 34` circular; the four corner regions
  disagree by up to ~2 pt over a few pt² each — far below the structural
  gate's 150-count severity threshold, and worth ~0.02 % of the scene.
- **The card's shadow is drawn as a RING, not as a layer shadow.** Core
  Animation draws a layer's shadow under the whole layer tree without
  occluding it (measured — golden/alpha_shadow_group), so a layer shadow on
  a 71 %-opaque card bleeds 4–7 counts into its interior, unevenly. Real iOS
  keeps the interior perfectly flat, so `_UIAlertShadowView` clips the
  blurred silhouette to the outside of the card's shape (non-zero winding
  ring). Its parameters (blur 22, offset (0, 8), alpha 0.085) are fitted to
  the measured edge profiles, not to a UIKit API.
- **The present transition animates ONLY the dim.** Sampling every layer's
  `presentation()` per display-link frame across an animated present found a
  critically damped opacity spring on the dimming view (ω = 22.88 rad/s,
  converged over 24 frames) and NO animation whatsoever on the card's layer
  or on any ancestor up to the window — no scale, no fade. If UIKit fades the
  card through a private portal/snapshot layer, this probe cannot see it. The
  DISMISS animation could not be measured at all (the dim's presentation
  opacity stayed pinned at 1 for the whole dismissal), so we play the present
  in reverse.
- ~~**Alert labels are TIGHTER than plain labels.**~~ **FIXED, and it was
  not an alert property.** The alert's title/message did render with wider
  advances than the golden's ("Delete File?" at 17 pt semibold +3.8 %,
  "This cannot be undone." at 15 pt +1.4 %), and the same golden's plain
  20 pt semibold label really did match byte for byte — but only because the
  divergence is ZERO at 20 pt. Mac Catalyst and iOS use different cuts of San
  Francisco (`.SFNS` vs `.SFUI`) that differ by a measured per-size constant
  below 20 pt, and the alert goldens are the ones rendered by iOS. See "Two
  cuts of San Francisco" at the top of this file. Alert wrap points now use
  the iOS advances like the rest of the alert layout.
- **Wrapped alert text uses the wrong line pitch.** Measured pitches are 22 pt
  for the title and 20 pt for the message (against 20.333/18 for the first
  line), which the card HEIGHT reproduces exactly — but the labels themselves
  draw with UILabel's own uniform pitch, so the second and later lines sit a
  point or two off. Single-line alerts (every alert_* fixture) are exact.
- **Text fields are laid out but never focused.** `addTextField` builds the
  measured 48 pt pill and places the field, and real iOS makes the first
  field first responder on presentation (with a blinking caret), which is why
  no fixture covers it — the golden would not be deterministic.
- **`preferredAction` styling is measured but ungoldened.** The filled pill
  ((55, 126, 239) with a white semibold title) was read off probe pixels; no
  fixture exercises it.
- **`UIPresentationController` holds `presentedViewController` `unowned`.**
  UIKit holds it strongly; here the presented controller owns its
  presentation controller (`vc.sheetPresentationController` is configured
  before a presentation exists), so the back reference has to be weak to
  avoid a cycle.
- **No `UIViewControllerInteractiveTransitioning`.** The interactive back
  swipe and the interactive sheet drag are scrubbed against the host clock by
  the controllers themselves, from measured physics; routing them through a
  percent-driven interactive protocol would change the feel. A custom
  animator therefore always runs non-interactively, and the built-in
  navigation slide stays scrubbable by living in
  `_UINavigationSlideAnimator` + `UINavigationController.applyTransition`
  rather than finishing through `context.completeTransition`.
- **A custom navigation animator gets no bar cross-fade.** `_runTransition`
  sets the bar's state directly instead of running
  `beginTransition`/`setTransitionProgress`, because the bar's cross-fade is
  driven by the same coverage function the built-in slide owns.
- **The alert centres in a HARD-CODED safe area.** `UIScreenMetrics`
  (`safeAreaTop` 59, `safeAreaBottom` 34) are the reference device's measured
  window insets — the portable core still has no safe-area model, and the
  page sheet's 59 pt top inset is the same constant. On a window that is not
  an iPhone 16 the card is centred as if it were.
## App-compat cluster: image loading, drawing, controls (2026-08-25)

What shipped (all oracle-backed): PNG/JPEG decode+encode and
`UIImage(named:/contentsOfFile:/data:)`, `UIBezierPath`, app-side drawing
(`UIView.draw(_:)`, `UIGraphicsImageRenderer`), and four controls —
`UIActivityIndicatorView`, `UISlider`, `UISegmentedControl`,
`UIPageControl` (fixtures `control_activity`, `control_slider`,
`control_segmented`, `control_pagecontrol`, `control_dark`).

**Deferred, with the reason:**

- **`UIStepper`** — measurable but not done. Real UIKit draws it through a
  SwiftUI hosting view (`UICoreHostingView<DesignLibraryStepper>`), so it
  renders ONLY in the windowed oracle. Probed metrics for whoever picks it
  up (94 x 32 control over white, Catalyst iOS 26.1): capsule background
  ≈ (243,243,243) over white (quaternarySystemFill-like), minus bar
  x 37..50 of a control at x=20 (13 pt long) in near-black (37,37,37), a
  1 pt divider at the centre (colour ≈ 180), and a matching 13 pt plus bar
  centred in the right half. Nothing else about the glyph strokes has been
  fitted.
- **Operational note**: regenerating a `"window": true` golden needs an
  ACTIVE, unlocked display session — `Tools/oracle2` composites through the
  real render server and otherwise fails with "window never became
  renderable" (this is what stopped `UIStepper` from being finished in this
  pass; the offscreen v1 oracle keeps working regardless).
- **`UIRefreshControl`** — needs scroll-view integration (pull-to-refresh
  offset behavior) that no static scene can validate, plus edits to
  `UIScrollView.swift`, which this cluster does not own. The visual is the
  spinner that already ships here.
- **`UISearchBar` / `UIPickerView`** — not attempted (they were not in this
  cluster's list).

**Fidelity notes on what did ship:**

- The activity indicator's ROTATION TIMING is not oracle-validated: Core
  Animation discards the spin offscreen and the windowed oracle can only
  sample it on the wall clock. The goldens pin the rest pose; the
  implementation advances one blade (45°) every 1/8 s, i.e. UIKit's
  classic one-revolution-per-second discrete step.
- `UISegmentedControl.intrinsicContentSize` is NOT reproduced (the oracle
  no longer dumps `intrinsic` for it). Real UIKit's per-segment width mixes
  the widest title, a 32 pt floor and ~18.5 pt of padding in a way that no
  probe set fit; scenes therefore give segmented controls explicit frames.
  Segment SPLITTING inside a given width is exact (integer-floor
  boundaries).
- `UISegmentedControl` disabled rendering uses a measured 0.5 alpha on the
  background and the titles (probe: 246 background and 146 ink over white
  against 238/39 enabled). No fixture covers the disabled state.
- Track-tap behavior on `UISlider` and tap-to-advance on `UIPageControl`
  are plausible UIKit behavior, not oracle-measured (no static scene can
  express them).
- `UIPageControl`'s glass background (real UIKit puts a
  `UIVisualEffectView` behind the dots) is not drawn: it composites to
  nothing in every capture probed, over white, black and red.
- The pure-Swift rasterizer backend ignores `UIBezierPath.lineCapStyle` /
  `lineJoinStyle` (it keeps its butt-cap / round-join model); the quartz
  backend — the default, and the one every golden uses — honors them via
  the additive `Canvas.stroke(_:color:lineWidth:cap:join:miterLimit:)`.
- `UIBezierPath.bounds` returns the FLATTENED (drawn) extent, not UIKit's
  control-point box.
- A view's custom content is rendered into an offscreen extent of
  `bounds` inset by −2 pt (LayerBridge.contentExtent), so app drawing —
  or a control shadow, e.g. the slider thumb's — that spills further than
  2 pt outside the bounds is clipped. UIKit clips `draw(_:)` to the view
  too, but its layer shadows are not clipped.
- `UIImage.withTintColor` recolors pixels immediately (CG `.sourceIn` of a
  flat color over the silhouette). `renderingMode` is stored and honored by
  that call, but `.automatic` behaves as `.alwaysOriginal` — there is no
  asset catalog to carry a template flag.


## Interactive sheets (M11, 2026-08-25): what shipped and what did not

Shipped, all measured (docs/APP_FEEL.md "Measured sheet interaction"):
drag-to-dismiss with the 10 pt slop and 1:1 tracking, the linear dim
interpolation, the 50 %-of-height and 1000 pt/s release rules, the
ω = √(1000/3) critically damped settle, the grabber, and the sheet ↔ inner
scroll view hand-off. Not shipped:

- **DETENTS — deferred deliberately, but MEASURED first.** `sheetprobe`
  established what they actually are on iOS 26, and it is a bigger mechanism
  than "another rest position":
  - With `[.medium(), .large()]` the sheet opens at **medium**, not large.
  - A non-large detent is not just shorter — it **floats**. The medium sheet
    reports frame (8, 403.687, 377, 440.313) on a 393×852 window: inset 8 pt
    on the left, right and bottom. Those numbers are one **scale transform of
    0.9593** applied to the ordinary full-width sheet (393 × 0.9593 = 377.0,
    36 × 0.9593 = 34.53, 5 × 0.9593 = 4.796 — the grabber scales with it), so
    the untransformed medium sheet is 393 × 459 and the chrome is a transform
    about the bottom edge, not a different layout.
  - Dragging between detents **RESIZES** the sheet: the bottom stays pinned,
    the top follows the finger and the height grows (measured 459 → 501 → 561
    → 617 → 677 → 689 as the finger travelled 240 pt up), and the scale
    transform is released to 1.0 the moment the drag starts. It does not
    translate the way a dismissal drag does.
  - The dim stays at a **flat 0.2 for the whole detent drag** — it responds
    only to dismissal progress, never to detent progress.
  - Release snaps to the nearest detent (240 pt up from medium landed on
    large: frame back to (0, 59, 393, 793)).
  - The dismissal rule stays proportional to the CURRENT detent's height: a
    400 pt custom detent springs back from 170 pt and dismisses from 210 pt.
  Implementing this needs a resizing sheet (content re-layout per frame), a
  transform-based floating chrome, and a snap-target search — three things
  none of which the dismissal path needed. The measurements above are the
  spec; nothing was built.
- **`isModalInPresentation` only suppresses the dismissal.** The sheet still
  tracks the finger 1:1 and springs back. Real UIKit also stiffens the drag
  itself (it resists rather than following); that resistance was not measured.
- **The grabber's DARK colour is extrapolated, not measured.** Light is exact
  — (197, 197, 200) over white, i.e. systemFill's (120, 120, 128) base at
  alpha 0.4295. `drawHierarchy` renders the dark grabber as *nothing at all*
  (the same private-material capture limitation as the dark textfield border
  and the dark tab bar), so the dark alpha is the light one scaled by the
  ratio UIKit uses for the systemFill family itself (0.2 → 0.36). No dark
  sheet fixture exists to check it against.
- **No tap-outside-to-dismiss — probed, result INCONCLUSIVE, so nothing
  changed.** A synthetic tap on the dim above the sheet did NOT dismiss it in
  the probe (`tap_outside`; `tap_outside_modal` and `tap_inside` likewise),
  which would say OpenUIKit's existing behaviour is already right. But that is
  the one probe result not confidently separable from a limitation of the
  synthetic-touch harness: the same harness demonstrably drives the sheet's
  own pan and the inner scroll view, yet a tap recognizer installed by UIKit
  on a private dimming view is a different delivery path, and common
  understanding of iOS is that a pageSheet DOES dismiss on an outside tap.
  Rather than ship a behaviour change on an ambiguous measurement, M10's
  "the dim swallows every touch" stands. Resolving it needs either a
  non-synthetic tap (a real UI test on a device/simulator) or finding the
  recognizer in the hierarchy dump and asserting on it directly.
- No `UISheetPresentationControllerDelegate`, and
  `UISheetPresentationController` exposes only `prefersGrabberVisible`. The
  detent API surface is deliberately ABSENT rather than present-and-fake.
- **The hand-off rule is written twice.** `_UISheetPanGestureRecognizer` and
  `UIScrollViewPanGestureRecognizer` each gate themselves on "is the scroll
  view at the top and is the drag downward", from opposite sides, because
  there is no `require(toFail:)` (see the event-system notes below). They
  cannot disagree today, but nothing enforces that. A *horizontally* scrolling
  view inside a sheet is untested.
- **A sheet whose content scroll view is not scrollable takes every downward
  drag**, because `dragsY` is false and the scroll pan never contests it.
  That is arguably correct (the content cannot move) and matches what the
  probe saw, but it is not separately measured.
- Only the top-most sheet is interactive: a sheet presented ON a sheet gets
  its own pan, but the stack is collapsed non-animated on dismiss (M10
  behaviour, unchanged).

## Showcase app / M10 completion (2026-08-25): scope notes

- **No UICollectionView.** M10's brief named it; nothing was built. The
  reuse machinery (per-identifier pools, `dequeueReusableCell`, tiled
  visible-rect layout) is all inside UITableView and would have to be
  lifted into a shared layer first.
- **The floating tab bar reserves nothing.** There is no safe-area /
  `additionalSafeAreaInsets` model in the portable core, so every screen
  under a UITabBarController has to be told how much bottom chrome sits
  over it (`BottomInsetAdjustable` in DemoApp, set from
  `UITabBar.barHeight`). A screen that forgets draws under the platter.
  Same for `hidesBottomBarWhenPushed`: not implemented, so the tab bar
  stays over pushed detail screens (which is UIKit's DEFAULT, but real
  apps usually opt out).
- **Sustained scroll is under 60 fps at scale 2** in this app: ≈ 22 ms per
  frame on the Tasks table, ≈ 18 ms on the large-title Settings list
  (60 fps at scale 1). Cause, measurements and the parked fix:
  docs/APP_FEEL.md "Inset-grouped table scroll cost". The large-title
  pocket blur is recomputed per observed offset and is a large part of the
  Settings number — the KNOWN GAP noted below ("unmeasured at sustained
  60 fps with heavy content") is now measured, and it is real.
- ~~The profile sheet has no grabber, no drag-to-dismiss and no detents~~
  **FIXED for grabber + drag-to-dismiss (M11, see the section at the top of
  this file).** The profile sheet now shows the grabber, drags to dismiss,
  and its form scrolls, so the sheet/scroll hand-off is live in the app
  (`scripts/sheet_drag.json` captures all three outcomes). Detents are still
  absent — measured, deferred, spec recorded above.
- Tab selection still jumps rather than sliding the capsule, and switching
  tabs is instantaneous (real iOS crossfades the content). Both are
  UITabBar/UITabBarController gaps listed below, now visible in an app.
- **`OPENUIKIT_APP_STYLE=dark --app showcase` shows a LIGHT tab bar** over a
  correctly dark app: the platter (#FDFDFE), capsule and unselected-item
  colours are hard-coded light constants because the M10 tab-bar goldens
  are light. Every other surface in the three tabs resolves its dynamic
  colours correctly. This is the most visible unmeasured-chrome gap left.

## UITableView animated updates (M10, 2026-08-25): scope notes

- `performUpdates(withDuration:delay:options:identity:updates:completion:)`
  is NOT UIKit's API. UIKit takes an explicit list of moves/inserts/deletes
  (`moveRow(at:to:)`, `insertRows(at:with:)`, `deleteRows(at:with:)` inside
  `performBatchUpdates`); this takes a stable per-index-path identity and
  diffs. It covers moves and inserts; **deletes do not animate** — a row
  whose identity vanishes is retired immediately, because the cell would
  have to be kept alive outside the visible set to fade it out. There is
  no `UITableView.RowAnimation` vocabulary (`.fade`/`.top`/`.left`…);
  inserts always fade in.
- Scrolling DURING an update is not handled: the animation's recorded
  endpoints are the frames computed at update time, so a re-tile triggered
  by a contentOffset change mid-flight assigns model frames the in-flight
  animation still overrides. Nothing in the app can do this today (the
  update is started by a tap, and a tap cancels scrolling).
- A row that moves between sections in a grouped table borrows
  `secondarySystemGroupedBackground` for the flight and dissolves it over
  the last 0.12 s. Until that dissolve finishes the cell is an opaque
  RECTANGLE, so for the two or three frames it spends landing on a card's
  first/last row it covers that card's 26 pt corners. Measured composited
  output is white-on-white in light mode (invisible); in dark mode, or on
  a tinted card, it would show.
- `indexPathForSelectedRow` is re-derived from the identity map and is
  CLEARED if the selected row is not visible after the update (UIKit keeps
  off-screen selection).

## UITableView (M10, 2026-08-25): scope notes

- No real self-sizing: row height resolves delegate `heightForRowAt` →
  `rowHeight` → the measured 51.5 pt default. A data source that builds
  `.subtitle` cells must return `UITableViewCell.subtitleRowHeight`
  (70.5) from the delegate (openrender's scene driver does; real UIKit
  self-sizes). Same for multi-line custom cells.
- Inset-grouped side margin is oracle-dependent:
  `insetGroupedSideInset` defaults to the offscreen-Catalyst 8 pt (the
  light goldens); a real UIWindow measures 16 pt (tableview_dark,
  oracle2) — openrender's SceneBuilder sets 16 for `"window": true`
  scenes. Apps targeting device feel should set 16.
- Selection overlay is a full-bleed rect; on an inset-grouped section's
  first/last row it is NOT clipped to the card's 26 pt corners.
- No editing mode (delete/reorder); animated moves/inserts arrived with
  `performUpdates` (see above) but there is no delete animation and no
  `UITableView.RowAnimation`, no `UITableViewHeaderFooterView` reuse pool
  (headers/footers are rebuilt per section entering the viewport —
  cheap, they're one label), no index titles, no multi-selection.
- `.grouped` style renders with the `.insetGrouped` chrome (no legacy
  full-width grouped look; no fixture covers it).
- Plain footers have no golden: they render with header-like height
  (40.5) and footer typography; plain headers assume an opaque
  `systemBackground` (matches the golden over a white table).
- Dark WINDOW text (e.g. tableview_dark) draws through the smoothed
  rasterizer fallback: glyph_ink_window.json currently carries only
  light-mode masks, so dark window glyphs are slightly softer/heavier
  than the golden (text-module coverage gap, not table-specific;
  tableview_dark still passes at 97.7).

## Modal / tab bar / large-title chrome (M10, 2026-08-25): scope notes

- Modal presentation implements `.pageSheet` (default) and `.fullScreen`
  only — no popover/formSheet/custom transitioning delegates and no
  detents. Drag-to-dismiss, the grabber and `isModalInPresentation` landed
  in M11 (see the top of this file); tap-outside-to-dismiss still does not
  exist (the dim swallows touches). The presenting view is NOT pushed
  back/scaled — the golden shows a flat 20% dim over the base
  (indistinguishable in the fixture); revisit if a fixture ever exposes the
  scaled base edge. Sheet metrics (top inset **59 pt — measured off the live
  frame in M11**, corner radii 37.7/58.2 pt circular fits of iOS 26's
  continuous corners) are the iPhone-16 measurements and are used at every
  window size.
- UITabBar: light-mode platter/capsule/shadow constants only (the M10
  goldens are light); dark-mode glass is unmeasured. No badges, no
  `moreNavigationController` (> 5 items just shrinks the pitch), no
  selection animation (the capsule jumps — real iOS 26 slides it).
- Large titles: the bar tracks ONE explicitly bound scroll view
  (`UIViewController.setContentScrollView(_:)`); there is no automatic
  detection of the topmost scroll view, and `contentInset.top` is owned
  by the binding (an app that sets its own top inset on the tracked
  scroll view will fight it). The scroll-edge pocket is a tuned
  approximation (Gaussian sigma 8 pt + background wash + vertical fade
  vs. iOS's progressive material blur), recomputed per observed offset —
  fine for scripted/interactive rates, unmeasured at sustained 60 fps
  with heavy content. Bar transitions (push/pop title morph) fall back
  to the inline-title choreography in large-title mode — a pushed child
  currently keeps the large-title container layout of its nav controller.

## Auto Layout (M9, 2026-08-24): scope notes

- Priorities minimize a WEIGHTED SUM of violations (weight = priority), not
  a strict lexicographic hierarchy: pairwise battles (750 vs 749, 251 vs
  250, 999 vs required) resolve winner-take-all exactly like UIKit (LP
  vertex optimum, verified by fixtures), but in principle several weaker
  constraints could jointly outweigh one stronger — no fixture or normal
  layout depends on this.
- leading/trailing alias left/right (LTR only; no RTL, no layout margins,
  no safe-area/layout guides).
- Constraint attributes map to FRAME edges in the solve space; a superview's
  bounds.origin (scrolled UIScrollView content) is not modeled, so
  constraint children of a scrolled view anchor to its frame, not its
  visible bounds. No constraint fixture scrolls.
- Baselines: UILabel only (single-line line-box math, offset =
  floor(ascender + 0.5) from top — same rounding as the draw path). Other
  views' baseline attributes alias the bottom edge, like plain UIKit views.
  A label stretched beyond its intrinsic height keeps the top-anchored
  baseline (real UIKit re-centers; no fixture covers it).
- An unsatisfiable REQUIRED constraint is dropped at add time (UIKit
  "breaks" a constraint and logs; the library stays silent).
- UIStackView still lays out by direct frame computation (pre-M9 code,
  golden-exact); it does not generate constraints for arranged subviews.
  Mixing a stack view INSIDE a constraint-sized parent works (the solver
  sets its frame, then layoutSubviews distributes).

## Text input (M8, 2026-08-24): scope notes

- SELECTION is not implemented (no range selection, no select-all/copy/
  paste, no selection handles, no shift+arrows). Caret editing only.
  UIKit's UITextInput/UITextPosition/UITextRange protocol family is not
  reproduced — UIKeyInput plus internal key routing is the whole surface.
- Caret geometry is measured (height = lineHeight + 1.5, TF y from the
  probed caretRect box math, TV y = floor(8 + line·lineH − 0.75)) but the
  BAR IS DRAWN 2 pt WIDE in tint color per the visible iOS caret; real
  caretRect(for:) reports width 1. Blink cadence (0.6 s solid hold,
  0.5 s half-period) is feel-tuned, not measured.
- Dark-mode .roundedRect chrome: the fill's dynamic resolution was probed
  (light white / dark black) but the BORDER's dark resolution is not
  capturable offscreen — implemented as white@20% (light black@20% is
  measured). No dark textfield fixture exists (the offscreen oracle cannot
  resolve the private dynamic chrome color in dark — same trait quirk as
  SceneKit's colorOrDie note).
- UITextField at 15/19–21 pt: the unfocused text/placeholder use the
  UILabel line box (labelLineHeight, +1 in those bands) while real TF
  editing boxes use lineHeight + 2 — baselines can differ by ~0.5 pt at
  those sizes (fixtures/demo use 13/17 pt, where they coincide).
- UITextView with font == nil renders 12 pt system; real UIKit's legacy
  default is Helvetica 12 (lineHeight 14 vs our 15). Always set a font.
- UITextField shows text from offset 0 when not editing (matches UIKit);
  ending editing resets the horizontal scroll to 0 without animation.
- Typing glyphs come from the same UILabel ink-table/stb path as labels;
  TextKit's slightly different rasterization (≈1 px softer tops, seen in
  the golden diffs) is inside the 96-threshold by a wide margin
  (textfield_basic 99.87, textview_basic 99.97) — no TextKit-context
  glyph harvest needed so far.

## Navigation / view controllers (M7.5, 2026-08-24): scope notes

- Transition geometry/timing implements APP_FEEL exactly (0.35 s easeInOut,
  +width→0 slide, −0.3·width parallax, black 0→8 % scrim, soft edge shadow
  sigma 4.5 pt / opacity 0.15) and is verified against the closed forms in
  ViewControllerLifecycleTests (incl. a rendered mid-transition pixel
  probe). Not oracle-captured yet — oracle2 time-sampling of a real
  UINavigationController push (per APP_FEEL "Oracle strategy") is still
  open; the bar title/back crossfade-and-slide parameters (0.35·W title
  slide, fast 40 %-duration back-label fade) are feel approximations.
- Completion model: transition CLEANUP + viewDidAppear/viewDidDisappear
  fire from the host clock via their own registry (they predate the
  clock-driven UIView.animate completions and do not use them) —
  UIWindow.tick calls UINavigationController._stepTransitions
  (same pattern as the scroll hook; one additive line in UIEvent.swift,
  coordinated with the event module). A host that renders without ticking
  shows the settled final frame but never completes the stack/lifecycle;
  `UINavigationController._hasActiveTransition` is the redraw hint.
- Appearance callbacks fire on nav-container install/push/pop only; there
  is no window-attachment notion in the portable core (the root VC gets
  willAppear/didAppear when the nav view loads, not when it joins a
  window). beginAppearanceTransition/endAppearanceTransition are public
  and UIKit-shaped, including the cancelled-interactive-pop reversal.
- Interactive back-swipe: left-edge (< 20 pt) pan scrubs the pop 1:1;
  release completes at > 50 % progress or ≥ 300 pt/s forward fling
  (≤ −300 pt/s always cancels), tail animated with a critically-damped
  0.35 s spring. The 300 pt/s threshold is feel-tuned, not measured. No
  recognizer dependency system exists (M7 note): the edge pan coexists
  with content recognizers and relies on its direction gate (leads
  horizontally away from the edge) — a horizontally scrollable view under
  the edge would fight it; require(toFail:) is the eventual fix.
- No UINavigationItem: the bar shows vc.title and "‹ previous-title"
  ("Back" fallback) only; no rightBarButtonItems, prompts, large titles,
  bar button customization, or bar blur (APP_FEEL allows the hairline
  bar). setViewControllers, hidesBarsOnSwipe, toolbars: not implemented.
  popToRootViewController collapses the middle of the stack instantly and
  animates only the top pop.

## UIScrollView (M7.5, 2026-08-24): scope notes

- Physics constants are MEASURED against real iOS UIKit (M8, 2026-08-24):
  0.998/ms deceleration with a 10 pt/s stop and the 0.499 per-ms-sum
  position factor, c=0.55 rubber band, two-regime bounce spring (ω=11
  critically damped with velocity, λ=9/46 overdamped from rest), ~100 ms
  velocity window, exact 10 pt slop absorption. Ground truth + methodology:
  golden/scroll_traces/SCHEMA.md and docs/APP_FEEL.md "Measured scroll
  physics"; regression gate: Tools/compare/compare_scroll.py (9/9).
  Remaining honest gaps within that: (a) the rest-release bounce is an
  empirical overdamped fit — mid-curve it can deviate up to ~14 pt of a
  235 pt overscroll from the oracle (settle time is within 3%; whatever
  UIKit's true integrator is, no single linear spring fits both measured
  regimes); (b) the ~150 ms content-touch delay and the 50 pt/s regime
  threshold remain feel-tuned, not measured; (c) UIKit quantizes
  contentOffset to the device pixel grid — OpenUIKit doesn't (sub-1/3-pt);
  (d) real UIKit starts the decel animation ~1 frame after the lift;
  OpenUIKit starts it exactly at the lift timestamp (compare_scroll aligns
  ±20 ms); (e) Mac Catalyst's POINTER scroll physics (different decay,
  stiff rubber band — golden/scroll_traces/catalyst_pointer/) are a
  separate input mode OpenUIKit does not implement.
- Deceleration/bounce is stepped by UIWindow.tick(timestamp:), which
  openhost calls every frame/script step. A host that renders without
  ticking sees a frozen scroll (call tick, or
  UIScrollView._stepScrollAnimations(to:), before rendering).
  `UIScrollView._hasActiveScrollAnimations` is the redraw hint.
- Indicator visuals (35 % black/white bar, 36 pt min length, both-axis
  bars flash whenever either axis scrolls) are feel-approximations, not
  oracle-fitted; they are lazily created so static scenes/layout dumps
  never see them. Fade is UIView.animate alpha (model alpha drops to 0
  at settle; presentation fades 0.4 s).
- Content-touch claim (M8.1): travel > 5 pt
  (`UIScrollView.contentTouchCancelDistance`) along a scrollable axis
  cancels a delivered content touch in the same event, ahead of the pan's
  10 pt recognition slop, so a row un-highlights the moment the finger
  starts dragging. The 5 pt is FEEL-TUNED, not oracle-measured (UIKit's
  own content-touch cancellation threshold is private); the axis test uses
  the dominant travel component and honors canCancelContentTouches /
  touchesShouldCancel(in:) exactly like the begin gate.
- touchesShouldCancel(in:) defaults to true for ALL views including
  UIControls (modern-UIKit behavior — scrolling cancels button/row
  tracking); the pre-iOS-8 documented control exception is not
  reproduced. directionalLockEnabled, paging, zooming, scrollsToTop,
  contentInsetAdjustmentBehavior and scroll-to-top/flash APIs are not
  implemented. setContentOffset(animated:) uses 0.25 s easeInOut.
- A touch-down that catches a decelerating scroll consumes the whole
  touch (content never sees it) — matches UIKit's stop-scroll tap.
  Nested scroll views are untested (single scroll view per touch path).

## demo_settings: remaining FAIL is window-capture ALPHA ENCODING, not text

After the text fixes below (2026-08-24), demo_settings measures 95.42 against
golden with compare.py's raw-channel diff, but 99.54 when both images are
composited over white with the golden interpreted as PREMULTIPLIED alpha.
Root cause: oracle2 (drawHierarchy) window captures store semi-transparent
pixels premultiplied — the `tertiarySystemFill` search bar is
(14,14,15,a=30) in golden (= 118·30/255) where our PNG stores straight
(115,115,123,a=31). That one 350x36pt bar is ~4.1% of the scene's pixels,
all counted as mismatches by the raw-channel compare. Owner: fixture
(compare.py could normalize encodings) or rendercli/rasterizer (premultiply
window-scene output). NOT the text module: every text region of the scene
now matches within tolerance. Opaque pixels are unaffected (premultiplied ==
straight at alpha 255), which is why deep_mixed passes.

## Glyph ink harvest: coverage tooling now automated (2026-08-24)

`OPENUIKIT_INK_LOG=<path> openrender render ...` dumps every ink-table miss
("W|family|size|style|tag|codepoint" for window-table misses, "O|..." for
offscreen). Harvest tooling (text-fixer scratchpad `h2/`): gen.py turns the
miss list into space-prefixed single-glyph probe scenes at integer x (all
phase tags per missed char, validation cells included), rendered by BOTH
oracle1 (offscreen entries) and oracle2 (window entries); extract2.py
validates extraction against already-stored entries (geometry byte-exact;
values within ±1 count — the residual of representing each phase BIN by one
mask) and merges only new keys. Dark-mode cells: Catalyst dark
systemBackground renders lum 30, full label ink 221, so masks are
v = round((lum-30)·255/191) with bbox threshold lum > 30.6 (validated ±2
counts against the stored regular-17 dark entries).
Coverage added: all button_states/button_dark/demo_settings combos
(regular 11/13/14/15/17/20/24, light/medium/heavy/bold 17, bold 34,
semibold 17 incl. U+203A, regular-15 dark, semibold-17 dark; window
variants for demo_settings' strings). Regression tests:
GlyphInkTableTests.testOffscreenCoverageForButtonStates /
testWindowCoverageForDemoSettings / testOffscreenDarkCoverageForButtonDark.

## Non-ASCII advances: vendored in font_metrics.json (2026-08-24)

Resources/font_metrics.json "advances" now also carries oracle-measured
non-ASCII advances (– — ‘ ’ “ ” • … ‹ › · × ° →, all families/weights/
sizes; scratchpad advprobe.swift, same NSString.size measurement as the
oracle's fontmetrics dump). FontEngine interpolates them like ASCII ones;
U+2026 keeps its exact label-context (tight-table) advance. This fixed all
14 demo_settings layout failures (U+203A at semibold-17 is 7.5693pt → 8pt
ceiled label width; the old font-file fallback gave 7pt).

## Text in window scenes: SOLVED mechanism, extend coverage as needed

Window scenes (`"window": true`, oracle2/drawHierarchy goldens) rasterize
label glyphs darker/crisper than offscreen `layer.render` — real UIKit's
own offscreen render of deep_mixed mismatches the window golden by the same
~5% the old renderer did, and no pointwise coverage transfer reproduces it
(it is a spatial re-rendering). Fix (text module): window-variant ink masks
in `Sources/OpenUIKit/Resources/glyph_ink_window.json`, harvested with the
SAME probe methodology as glyph_ink.json but rendered through oracle2
(space-prefixed single-glyph labels at integer x; extraction validated
byte-exact against the offscreen table first). Selected via
`GlyphInkTable.windowCompositing`, set by openrender from the scene's
`window` flag; per-glyph fallback to the offscreen table. Coverage today:
deep_mixed's strings (fixed deep_mixed 95.95 → 99.64) plus all of
demo_settings' strings (34pt bold title, 17pt regular/semibold incl. U+203A,
13pt incl. U+2014, 15pt button titles) via the automated miss-log harvest
(`h2/` in the text-fixer scratchpad, successor of `wharvest/`); see
"Glyph ink harvest" above. Window dark mode remains unharvested (no window
dark scene exists yet).

## Text module: glyph_ink.json harvest coverage — RESOLVED 2026-08-24

Item 1 of the old diagnosis (harvest coverage + non-ASCII advances) is fixed;
see the two sections above. button_states 94.90 → 96.60 PASS. Still open:

- **drawMask blend calibration.** Exact for the `.label` color it was fitted
  on; ~9 counts dark at AA edges for pure black and tint-blue titles. All
  diffs on fully-harvested strings are ≤15 counts. Consider color-dependent
  calibration or fitting the blend exponent per ink color family. (Was not
  needed to pass button_states once coverage landed.)
- Button path is NOT the problem: button text renders byte-identically to the
  label path (verified by A/B probe, commit 0d4da17).

## UIButton (fixed, for the record)
Real UIKit gives the title label the FULL bounds width (squeeze to
floor(width)) and truncates button titles MIDDLE, not tail (commit 0d4da17).

## Earlier accepted residuals (within thresholds, from M2/M3)
- Dark-mode saturated-color text (label_dark link row) has a different ink
  profile than the default color — needs color-keyed harvests.
- truncateHead/Middle per-char tight-advance quantization subtlety (≤+0.11pt).
- Light saturated-color glyphs: small mask-shape differences beyond the gamma
  model.

## Event system (M7, 2026-08-24): scope notes

- switch_toggle_anim goldens are WALL-CLOCK captures (the modern UISwitch
  thumb is display-link driven and ignores frozen-clock seeks; see the
  switch-setOn section of docs/SCENE_SPEC.md). Frames carry a few ms of
  scheduling jitter — regenerating that golden produces near- but not
  byte-identical frames. Our fitted model currently scores ≥ 98.3 per
  frame (threshold 96), leaving ~2 points of jitter headroom.
- UISwitch drag-to-toggle (thumb tracking during a pan on the switch) is
  not implemented — tap-to-toggle only. UIControl uses plain
  point(inside:) for isTouchInside (UIKit uses a ~70 pt outset during
  drags on some controls).
- Gesture recognizer dependencies (require(toFail:), delegate methods,
  simultaneous recognition) are not implemented; recognizers observe
  independently. UITouch.tapCount timing constants (0.35 s / 30 pt) are
  host-tunable statics on UIWindow, not oracle-derived.
- Long press with no intervening events fires on the NEXT event/tick at
  or after minimumPressDuration (no run loop in the core — the host's
  `tick(timestamp:)` provides time-only advance).

## Animation engine (M6, 2026-08-24): scope notes

- Presentation sampling requires the DEFAULT pipeline (quartz backend +
  layers compositor). Under `OPENUIKIT_COMPOSITOR=renderpass` or
  `OPENUIKIT_BACKEND=swift` animation scenes render MODEL values only
  (every frame = final state). Owner: view module, only if a host ever
  needs animated rendering on the pure-Swift path.
- `UIView.animate` completion handlers now fire ON THE CLOCK (M8.1, was
  synchronous): they are queued at `begin + delay + duration` and
  delivered by `UIView._stepAnimationCompletions(to:)`, which
  `UIWindow.tick(timestamp:)` calls after the scroll/transition steppers.
  A host that advances `OpenUIKitRuntime.animationTime` without ticking a
  window never delivers them (`UIView._hasPendingAnimationCompletions` is
  the redraw hint; openhost's dirty check includes it). Residual
  divergences: `finished` is always `true` — there is no cancellation
  path, so replacing an in-flight animation on the same property does not
  deliver `false` the way CA's `didStop` does, and `removeAllAnimations()`
  leaves a queued completion to fire at its original end time. A block
  that records no animation completes immediately (matching UIKit, which
  creates no CAAnimation). Handlers due in one tick run as a single batch,
  so a completion that starts a new animation gets its completion on a
  later tick — one run-loop turn per batch.
- Spring initialVelocity: UIKit's internal duration-fit solver picks a
  much softer spring (a different root of the same settling equation —
  see docs/QUARTZ_NOTES.md) once the velocity crosses a threshold
  (measured: between v=1.65 and v=1.7 at ζ=0.5, D=1, scaling roughly with
  1/D; near the crossover UIKit emits unconverged garbage parameters,
  e.g. ζ=0.5 D=2 v=0.9 → stiffness 354.6 with settlingDuration < D). We
  always take the settled (largest) root, which matches UIKit for
  moderate velocities (probed: exact for v ∈ [−2, 1.65] at ζ=0.5 D=1)
  and diverges deliberately in the garbage regime. All fixtures use v=0,
  where the model is exact to 8+ digits.
- Transform interpolation implements CA's decomposition for the 2D affine
  subset (translation/scale/shear/rotation lerp, rotation shortest-path).
  Degenerate (rank-deficient) matrices fall back to componentwise lerp;
  180° rotations are ambiguous (CA's quaternion slerp has the same
  ambiguity). backgroundColor nil endpoints lerp as transparent black
  (CA snaps); no fixture covers either.
- A `bounds`/frame resize animates the layer rect only — a view's CONTENT
  image (glyph ink, image resampling, control chrome) is not re-stretched
  per frame the way CA scales `contents` with the presentation bounds.
  No fixture resizes a content-bearing view; revisit if one does.

## Verification blind spot: localized degradation (top remaining)

The oracle comparison has three gates — layout (0.5 pt), pixel percentage
(category thresholds), and the structural gate (contiguous wrong region +
content absence). Together they catch *missing* and *moved* content well.

They are weakest against content that is **present but subtly wrong in a small
region**: a text run at the wrong weight/hinting/subpixel phase, a gradient
with a slightly wrong ramp, a control drawn with the wrong corner radius.
Absence cannot fire (both sides have structure), and a soft error's per-pixel
deltas fall under the 150-count severity floor, so only the percentage sees it
— and a small region on a large canvas barely moves the percentage. Measured:
a blurred 370×100 px text region scores 99.007 % and passes everything. The
floor is not a tunable here: blur *redistributes* ink rather than removing it,
so the largest per-pixel delta anywhere in that region is **92** and the severe
mask is empty — there are no components for either structural check to look at,
at any threshold above ordinary antialiasing.

This matters because it is exactly the class the M2 text work fought, caught
then only because the error was global. The fix is not another whole-frame
metric (two were measured and rejected — see SCENE_SPEC "Structural diff
gate"): it needs **per-region scoring**, e.g. align text runs via the layout
dump and score each run's ink against its own area rather than the canvas.
Until then, treat a high percentage on a text-dense scene as weak evidence,
and prefer adding a tight fixture (small canvas, one feature) over trusting a
large scene's score.
