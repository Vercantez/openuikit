# WordPress-iOS: `UITextItem` and `UIPopoverPresentationControllerSourceItem`, measured

Branch `agent/wordpress-textitem-popover`, 2026-09-10. Task: the two
BLOCKING UIKit rows APP_LADDER §9.6 lists for WordPress-iOS (route (b)
MID) — `UITextItem` (12 uses) and `UIPopoverPresentationControllerSourceItem`
(10 uses) — plus firefox-blocking-rows.md's leftover `UITextItem` (1);
checked for staleness first, then measured on iOS 26.1 and built.

## Stale-row check

| row | verdict | evidence |
| --- | --- | --- |
| `UITextItem` 12 | **real** | no declaration under `uikit/Sources/OpenUIKit` (only the `UITextItemInteraction` enum); `gap-classes-2026-09-16.json` lists it for WordPress-iOS (12), wikipedia-ios (8), firefox-ios (1). |
| `UIPopoverPresentationControllerSourceItem` 10 | **real** | no declaration; `UIPopoverPresentationController` had `sourceView` / `sourceRect` / `barButtonItem` only, and drew every pad popover at the trailing corner regardless of anchor. JSON lists it for WordPress-iOS (10) and signal-ios (1). |

Corpus read from `~/openuikit/scratch/ladder-corpus/WordPress-iOS` (and
firefox-ios), read-only. What the uses touch — the bound of the work:

- `UITextItem`: four `UITextViewDelegate` conformers (`ExpandableCell`,
  `ActivityFormattableContentView`, `RichTextView`,
  `NoteBlockTextTableViewCell`) implement
  `textView(_:primaryActionFor:defaultAction:)` and
  `textView(_:menuConfigurationFor:defaultMenu:)`, pattern-match
  `case let .link(URL) = textItem.content`, return `defaultAction`, `nil`
  or a `UIAction { }`, and build `UITextItem.MenuConfiguration(menu:)` /
  `.init(menu: defaultMenu)`. `RichTextView` forwards through
  `delegate?.textView?(…)` (the methods must be optional). firefox's one use
  is the same `primaryActionFor` + the iOS 10 `shouldInteractWith URL`
  fallback. Nothing names `.tag`, `.textAttachment`, `MenuPreview`, or the
  ObjC-only `contentType` / `link` / `tagIdentifier` (which are hidden from
  Swift by API notes anyway — the probe would not compile against them).
- `UIPopoverPresentationControllerSourceItem`: `popoverPresentationController?.sourceItem = sourceBarButtonItem ?? sourceView`
  (a `UIBarButtonItem?` / `UIView?` pair), `= sender`, `= anchor`; function
  parameters typed `any UIPopoverPresentationControllerSourceItem`; a
  `weak var anchor: UIPopoverPresentationControllerSourceItem?` (so the
  protocol must be class-bound); `permittedArrowDirections = .any`;
  `adaptiveSheetPresentationController.detents = [.medium()]` on the same
  popover controller. No custom conformer; no `frame(in:)` call.

## Probe recipe

`Tools/oracle2/wordpressrowsprobe/main.swift` — one file, no Xcode project,
`swiftc -target arm64-apple-ios26.0-simulator`, an Info.plist that also
registers `wpprobe://` so the app delegate can OBSERVE a link opening.
Touches are synthesised through swipeprobe's private `UITouch` selectors;
a tap is began/ended 60 ms apart, a press holds 0.9 s. Three transcripts
(iPhone 16 `textitem`, iPad A16 `popover`, iPhone 16 `popover`) are
committed unedited next to the README, which lists every row. From `uikit/`:

```sh
SIM_DEVICE_SUFFIX=-x PHASE=textitem KIND=iphone scripts/wordpress_rows_probe_sim.sh /tmp/wp
SIM_DEVICE_SUFFIX=-x PHASE=popover  KIND=ipad   scripts/wordpress_rows_probe_sim.sh /tmp/wp
SIM_DEVICE_SUFFIX=-x PHASE=popover  KIND=iphone scripts/wordpress_rows_probe_sim.sh /tmp/wp
```

Two probe iterations before the transcripts: the ObjC-only `UITextItem`
members did not compile (API notes hide them — a fifth-artifact-class
case), and the popover phase crashed serialising `CGRect.null` (the
DEFAULT `sourceRect` is infinite; JSON has no infinity) — which is itself
a row: the port said `.zero`.

## Oracle table — UITextItem (iPhone 16 / iOS 26.1)

| observation | iOS 26.1 | port before | port after |
| --- | --- | --- | --- |
| `UITextItem` Swift surface | `content` (.link / .textAttachment / .tag) + `range`; `MenuConfiguration(menu:)`, `(preview:menu:)`; `MenuPreview.default` / `(view:)` | absent | same |
| `NSAttributedString.Key.textItemTag` raw | "UITextItemTagAttribute" | absent | same |
| item ranges (link / tag / attachment) | `[5, 5]` / `[14, 7]` / `[27, 1]` — the attribute run | — | same (hit test over the attributed layout, UTF-16 ranges) |
| default action handed to the delegate | title "", id `UITextInteractableItemDefaultAction`, attrs 0, no image | — | same |
| tap link, iOS 17 delegate returns default | `primaryActionFor` once → URL opens | link taps did nothing (caret only) | same, via `UIApplication.open` |
| … returns nil | nothing opens; `menuConfigurationFor` asked, menu shown, `willDisplay` | — | same (`_UIMenuPresentation`) |
| … returns custom action | only it runs | — | same |
| only the iOS 10 `shouldInteractWith URL` implemented | asked with the run range, `.invokeDefaultAction`; true opens | method absent from the protocol | same — the default `primaryActionFor` routes through the old gate |
| both generations implemented | only `primaryActionFor` | — | same |
| no delegate / conforming-only | opens | — | same |
| tap tag | `primaryActionFor` (.tag), then `menuConfigurationFor` with an EMPTY menu; nothing shown | — | same (default tag action = show menu) |
| tap attachment | `primaryActionFor` (.textAttachment), no menu (asked twice in the new-only run, once in both — one call here) | — | one call |
| `isSelectable = false` | nothing | property absent | same |
| `isEditable = true` | link still opens; NOT first responder | tap focused the caret | same |
| long press link | `primaryActionFor` (not performed), `menuConfigurationFor` (menu titled with the URL, id `UITextItemDefaultMenuIdentifier`, Open / Copy / Share…), `willDisplay`, platter | — | same order; Copy writes the pasteboard, Share… is a declaration |
| … menu config nil | no menu | — | same |
| long press attachment | default menu Copy Image / Save to Camera Roll | — | same titles; Save is a declaration |
| `textItemMenuWillEnd` | on the menu going away (and, oddly, after the tag's empty menu) | — | on dismiss of the platter; the empty-menu quirk not reproduced |
| `linkTextAttributes` default | `[.foregroundColor: systemBlue]` | property absent; links drew in `textColor` | same default, applied to `.link` runs |
| menu platter frame | `[39.667, 234.667, 250, 186.333]` | — | the port's own measured `_UIMenuPresentation` layout; not re-fitted |
| selection highlight while the menu is up (`selectedRange` = item) | yes | no selection model | not modelled |
| long-press threshold | not measured (0.9 s hold used) | — | 0.5 s, UIKit's long-press default, labelled |

## Oracle table — UIPopoverPresentationControllerSourceItem

iPad (A16) 820×1180 @2x, safe area 32 / 25, `preferredContentSize` 240×180:

| observation | iOS 26.1 | port before | port after |
| --- | --- | --- | --- |
| protocol | `UIView`, `UILayoutGuide`, `UIBarButtonItem`, `UITabBarItem` conform; Swift surface `frame(in:) -> CGRect?` (requirement hidden as `__frame(in:)`) | absent | class-bound protocol with `frame(in:)`; the four conformers |
| `frame(in: window)`: view / detached view / layout guide / loose bar button | `[100, 300, 60, 40]` / `[1, 2, 3, 4]` / `[10, 400, 50, 30]` / `[0, 0, 0, 0]` | — | same (detached view walks its own frames — the port's `convert` dropped the origin) |
| bar button in the bar / tab item | 36 pt content box, y 4 in the 54 pt bar `[741.5, 36, 64.5, 36]`; tab `[412, 1101, 66, 36]` | — | the port's item VIEW frame (platter-sized); not fitted to the content box — only clamped placements were measured, so the popover frames below do not depend on it |
| `sourceRect` default | `CGRect.null` | `.zero` | `.null` (UIAlertController's pad action sheet now centres on the view for null) |
| `arrowDirection` before presenting | NSUIntegerMax | property absent; `.unknown` raw 16 | `.unknown` = all bits |
| `sourceItem = view` → `sourceView` | nil (separate stores) | — | nil |
| `sourceItem = item` → `barButtonItem`; `barButtonItem = item` → `sourceItem` | mirrored both ways | — | same |
| right bar button | `[561, 62, 240, 180]`, arrow raw 0, no chrome | `[561, 62, 240, 180]` (fixed trailing rule) | same, from centre-on-item + 19 pt clamp |
| left bar button | `[19, 62, 240, 180]`, 0 | `[561, 62, …]` | `[19, 62, 240, 180]` |
| bar button + `permittedArrowDirections = .down` | unchanged | — | unchanged (mask ignored) |
| view [100, 300, 60, 40] | `[160, 230, 253, 180]`, `.left` (width + 13, centred on midY) | `[561, 62, 240, 180]` | same |
| view at y 980 | `[160, 910, 253, 180]`, `.left` | — | same |
| view + sourceRect (0,0,10,10), via `sourceView` or `sourceItem` | `[110, 215, 253, 180]` | — | same |
| view + `.down` | `[19, 107, 240, 193]` (height + 13, x clamped) | — | same |
| tab bar item | `[325, 908, 240, 193]`, `.down` — maxY = item minY, centred on the item | — | `.down`, 240×193, maxY = item minY, centred (the item's x comes from the port's tab layout) |
| view + `.right` | `[19, 230, 111, 180]` — squeezed to 111 | — | clamped, width kept; recorded, not modelled |
| no source on iPad | `NSGenericException` | trailing layout | unchanged (no throw) |
| direction choice for `.any` | left for both views, down for the tab item | — | first of up/down/left/right that fits the 19 pt margins without a clamp, else the first permitted clamped — fitted from four rows |
| presented view frame | equals the popover frame incl. the 13 pt arrow (253 wide) | — | same |

iPhone 16 393×852 (compact): every source kind adapts to the sheet
`[0, 59, 393, 793]`, `arrowDirection` stays `.unknown`, presentation
controller class stays `UIPopoverPresentationController` (port: the sheet
controller — pre-existing, not this row); WordPress's
`adaptiveSheetPresentationController.detents = [.medium()]` → drop shadow
`[8, 403.687, 377, 440.313]`. Port: `adaptiveSheetPresentationController` is
the presented controller's sheet controller, so the medium detent flows
through and the existing sheet code lands `[8, 403.687, 377, 440.313]`.

## What changed (all under `uikit/`)

- `Sources/OpenUIKit/UITextItem.swift` (new): `UITextItem` (+ `Content`,
  `MenuPreview`, `MenuConfiguration`), `Key.textItemTag`, the measured
  identifiers, `_UITextItemMenuAnimator`.
- `Sources/OpenUIKit/UITextView.swift`: `UITextViewDelegate` gains
  `shouldInteractWith URL`, `primaryActionFor`, `menuConfigurationFor`,
  `textItemMenuWillDisplayFor` / `…WillEndFor` with defaults (the default
  `primaryActionFor` routes through the iOS 10 gates — the measured
  old-only behaviour); `isSelectable`, `linkTextAttributes` (painted over
  `.link` runs); `touchesBegan`/`touchesEnded` split tap vs press, item hit
  test (`textItem(at:)`), default action / default menu / menu
  presentation in the measured order.
- `Sources/OpenUIKit/UIPopoverPresentationControllerSourceItem.swift`
  (new): the protocol and the four conformers.
- `Sources/OpenUIKit/UIAdaptivePresentation.swift`: `sourceItem`,
  `arrowDirection`, `adaptiveSheetPresentationController`, `sourceRect`
  default `.null`, `.unknown` raw, anchor resolution and the arrow/frame
  rule; bar-button popovers centre on the item and clamp.
- `Sources/OpenUIKit/UIBarButtonItem.swift`, `UINavigationBar.swift`,
  `UIToolbar.swift`: `_UIBarItemContainer._view(for:)`.
- `Sources/OpenUIKit/UIAlertController.swift`: null `sourceRect` handling.
- `Tests/OpenUIKitTests/WordPressBlockingRowsTests.swift`: `TextItemTests`
  (12) and `PopoverSourceItemTests` (9), every number a transcript row.
  Failing-first: the file did not compile on main (the types did not
  exist); two expectations I wrote wrong (detached-view frame, medium
  sheet height as the unscaled 459) were corrected FROM the transcript.
- `Tools/oracle2/wordpressrowsprobe/` (probe, README, three transcripts),
  `scripts/wordpress_rows_probe_sim.sh`.

## Gates

```
swift test --filter "TextItemTests|PopoverSourceItemTests"
  21 tests, 0 failures
swift test --filter "TextItemTests|PopoverSourceItemTests|TextViewDelegateTests|TextViewEditingTests|ModalPresentationTests|AdaptivePresentationDelegateTests|PresentationControllerTests|PresentationTableSourceCompatibilityTests|BarButtonItemTests|BarButtonActionTests|DelegateProtocolTests|IOSDevicePixelMetricsTests|DynamicTypeTests|ChromeControllerTests|BarItemsTests|TextView|Popover|Presentation|BarButton"
  129 tests, 0 failures
swift test --filter "UIAlertActionModelTests|UIAlertLayoutTests|IOSDevicePixelMetricsTests|PopoverSourceItemTests"
  after the null-sourceRect guard: 14 + 32 + 9, 0 failures
```

Ladder classifier re-run on a scratch corpus holding symlinks to the
frozen WordPress-iOS and firefox-ios clones, `ours` regenerated from this
branch with `remeasure-2026-09-16.sh`'s regex (437 names), unchanged
`ladder_census.py` → `union_and_imports.py` → `classify_gaps.py`:

| app | before (`gap-classes-2026-09-16.json`) | after |
| --- | --- | --- |
| WordPress-iOS blocking | 5 types / 26 uses: `UITextItem 12 · UIPopoverPresentationControllerSourceItem 10 · NSTextTab 2 · NSTextLayoutManager 1 · NSTextLocation 1` | **3 / 4**: `NSTextTab 2 · NSTextLayoutManager 1 · NSTextLocation 1` |
| firefox-ios blocking | 3 / 4 after firefox-blocking-rows (`UIMenuBuilder 2 · UICommandAlternate 1 · UITextItem 1`) | **2 / 3**: `UIMenuBuilder 2 · UICommandAlternate 1` |
| stub-able | 11 / 18 and 9 / 24 | unchanged |

(The committed `openuikit_types-2026-09-16.txt` is older than the JSON and
reproduces even staler rows — 9 / 51 for WordPress; the JSON figure is the
"before".)

Merge check: `CHECK_ONLY=1 uikit/scripts/agent_merge.sh agent/wordpress-textitem-popover`
on `16068eff` (the one code commit over main):

```
checks passed (CHECK_ONLY)
```

(Catalyst goldens, real-app floors, conformance re-render and the Linux
`openrender` build all inside the script; no REFUSED, no warning in the
new files. This docs-only commit follows it.)

## Walls and leftovers

- WordPress's remaining blocking rows are TextKit 2 (`NSTextTab`,
  `NSTextLayoutManager`, `NSTextLocation`); `UISplitViewController` is
  another agent's branch.
- Not modelled from the transcripts: the link selection highlight while a
  menu is up (no selection model), the `.right`-forced squeeze, the
  bar-button / tab-item CONTENT box for `frame(in:)` (the port answers with
  its item view), the platform activity sheet behind "Share…" and the
  photo library behind "Save to Camera Roll", the iPad exception for a
  missing source, and the exact `_UIContextMenuView` geometry for text-item
  menus (the port's measured context-menu layout is reused).
- `UIMenuLeaf.presentationSourceItem` and
  `UINavigationItem.overflowPresentationSource` (the SDK's other
  `SourceItem`-typed members) are not in any corpus use and were not added.
- Long-press threshold for text items is UIKit's 0.5 s default, not a
  measured number.
