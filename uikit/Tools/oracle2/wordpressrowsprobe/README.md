# wordpressrowsprobe — UITextItem and UIPopoverPresentationControllerSourceItem

Measures the two top BLOCKING UIKit rows of WordPress-iOS
(`full/ladder/gap-classes-2026-09-16.json`): `UITextItem` (12 uses; also
wikipedia-ios 8, firefox-ios 1) and `UIPopoverPresentationControllerSourceItem`
(10 uses; also signal-ios 1). Three unedited transcripts, iOS 26.1:

| file | device | phase |
| --- | --- | --- |
| `ios-26.1-iphone16-textitem.json` | iPhone 16 (3x, 393×852) | `textitem` |
| `ios-26.1-ipad-popover.json` | iPad (A16) (2x, 820×1180) | `popover` |
| `ios-26.1-iphone16-popover.json` | iPhone 16 | `popover` |

Run from `uikit/`:

```sh
SIM_DEVICE_SUFFIX=-mine PHASE=textitem KIND=iphone scripts/wordpress_rows_probe_sim.sh /tmp/wp
SIM_DEVICE_SUFFIX=-mine PHASE=popover  KIND=ipad   scripts/wordpress_rows_probe_sim.sh /tmp/wp
SIM_DEVICE_SUFFIX=-mine PHASE=popover  KIND=iphone scripts/wordpress_rows_probe_sim.sh /tmp/wp
```

One `main.swift`, no Xcode project; `swiftc -target arm64-apple-ios26.0-simulator`,
minimal Info.plist that also registers the `wpprobe://` URL scheme so the
probe can OBSERVE a link being opened (the app delegate's
`application(_:open:options:)` records it). Touches are synthesised with
swipeprobe's private-selector `UITouch` path. Every case rewrites the JSON,
so a late crash keeps earlier rows (the iPad run ends in one, below).

## `textitem` rows (iPhone 16)

A 353×120 non-editable, selectable `UITextView` at (20, 200), 17 pt system
font, string `"Read Apple or tagword here \u{FFFC} end web"`: "Apple" is a
`.link` to `wpprobe://open?item=link`, "tagword" carries
`.textItemTag` = "wp-tag", U+FFFC is a 24×24 `NSTextAttachment`, "web" is an
https link. Base rows: link range `[5, 5]` rect `[68.015, 208, 44.061, 24.101]`,
tag `[14, 7]` at `[136.43, 208, 62.438, 24.101]`, attachment `[27, 1]` at
`[241.493, 208, 24, 24.101]`; `linkTextAttributes` default = systemBlue only;
`UITextItemTagAttributeName` = "UITextItemTagAttribute". A tap is
began/ended 60 ms apart at the run's midpoint; a press holds 0.9 s.

| case | delegate | events (in order) | opened |
| --- | --- | --- | --- |
| `tap.link.new.default` | iOS 17 methods only, returns `defaultAction` | `primaryActionFor` (item .link, [5, 5]; default action title "", id `UITextInteractableItemDefaultAction`, attrs 0, no image) | yes |
| `tap.link.new.nil` | returns nil | `primaryActionFor`, `menuConfigurationFor` (menu title = URL string, id `UITextItemDefaultMenuIdentifier`, Open / Copy / Share…), `textItemMenuWillDisplay`; `_UIContextMenuView [39.667, 234.667, 250, 186.333]` on screen; selectedRange = [5, 5] | no |
| `tap.link.new.custom` | returns a custom action | `primaryActionFor`, `customActionFired` | no |
| `tap.link.old` | iOS 10 `shouldInteractWith URL` only | `shouldInteractWithURL` range [5, 5] interaction 0 | yes |
| `tap.link.both` | both | `primaryActionFor` only | yes |
| `tap.link.noDelegate` / `noneImplemented` | — | none | yes |
| `tap.tag.new` / `.both` | | `primaryActionFor` (.tag "wp-tag", [14, 7]), `menuConfigurationFor` (title "", dynamic id, NO children); nothing shown | no |
| `tap.attachment.new` | | `primaryActionFor` (.textAttachment, [27, 1]) — twice in this run, once in `.both`; no menu | no |
| `tap.plain.new` | | none | no |
| `tap.link.new.notSelectable` | `isSelectable = false` | none | no |
| `tap.link.new.editable` | `isEditable = true` | `primaryActionFor`; `isFirstResponder` false | yes |
| `press.link.new.default` | | `primaryActionFor`, `menuConfigurationFor`, `textItemMenuWillDisplay`; menu at `[48.333, 262.333, 250, 186.333]`; selectedRange [5, 5] | no |
| `press.link.new.nilMenu` | menu config nil | `primaryActionFor`, `menuConfigurationFor`; nothing shown | no |
| `press.link.both` | both | `menuConfigurationFor`, `textItemMenuWillDisplay` (no `primaryActionFor`) | no |
| `press.tag.new` | | `primaryActionFor`, `menuConfigurationFor` (empty), then `textItemMenuWillEnd` with nothing shown | no |
| `press.attachment.new` | | `primaryActionFor`, `menuConfigurationFor` (title "", id `UITextItemDefaultMenuIdentifier`, Copy Image / Save to Camera Roll), `textItemMenuWillDisplay`; menu `[33.333, 262.333, 250, 104]` | no |

The Swift surface of `UITextItem` is `content` + `range`; the ObjC
`contentType` / `link` / `tagIdentifier` / `textAttachment` are hidden by
API notes (`__contentType` …) and do not compile.

## `popover` rows

Root is a `UINavigationController` with "Back" / "More" bar buttons, a
60×40 view at (100, 300), one at (100, H−200), and a two-item `UITabBar`;
each case presents a 240×180 `preferredContentSize` controller with
`modalPresentationStyle = .popover`, animated false, reads after 0.5 s.

### iPad (A16) 820×1180, safe area 32 / 25

Base: `frame(in: window)` — view `[100, 300, 60, 40]`, detached view
`[1, 2, 3, 4]` (its frame), layout guide `[10, 400, 50, 30]`, right item
`[741.5, 36, 64.5, 36]` (`[741.5, 4, 64.5, 36]` in the 54 pt bar), left item
`[14, 36, 63, 36]`, detached bar button `[0, 0, 0, 0]`, tab items
`[342, 1101, 66, 36]` / `[412, 1101, 66, 36]`. `sourceRect` default is
`CGRect.null`; `arrowDirection` before presenting is NSUIntegerMax.

| case | `_UIPopoverView` | arrow | readbacks |
| --- | --- | --- | --- |
| `sourceItem.barButton` (right) | `[561, 62, 240, 180]` | 0 | `barButtonItem` = the item, `sourceView` nil; no chrome/shadow views |
| `sourceItem.barButton.left` | `[19, 62, 240, 180]` | 0 | |
| `sourceItem.view` | `[160, 230, 253, 180]` | 4 (.left) | `sourceView` nil; `_UIPopoverShapeLayerChromeView`, `_UIRoundedRectShadowView [−137, −150, 540, 480]` |
| `sourceItem.lowView` (y 980) | `[160, 910, 253, 180]` | 4 | |
| `sourceItem.tabItem` | `[325, 908, 240, 193]` | 2 (.down) | |
| `sourceView.view` | `[160, 230, 253, 180]` | 4 | `sourceItem` nil |
| `sourceView.view.rect` (0,0,10,10) | `[110, 215, 253, 180]` | 4 | |
| `sourceItem.view.rect` | `[110, 215, 253, 180]` | 4 | sourceRect applies to a view sourceItem |
| `barButtonItem.prop` | `[561, 62, 240, 180]` | 0 | `sourceItem` = the item |
| `sourceItem.barButton.arrowsDown` | `[561, 62, 240, 180]` | 0 | permitted mask ignored |
| `sourceItem.view.arrowsLeft` | `[160, 230, 253, 180]` | 4 | |
| `sourceItem.view.arrowsRight` | `[19, 230, 111, 180]` | 8 | squeezed to 111 wide (not modelled) |
| `sourceItem.view.arrowsDown` | `[19, 107, 240, 193]` | 2 | x clamped to 19 |
| `sourceItem.none` | — | — | **throws** `NSGenericException` "should have a non-nil sourceView or barButtonItem set before the presentation occurs" — the run ends here, so `view.big` and `mediumDetent` are iPhone-only |

Presentation controller class is `UIPopoverPresentationController`;
`adaptivePresentationStyle` raw 2; the presented view's own frame equals
the `_UIPopoverView` frame including the 13 pt arrow (`UIView [0, 0, 253, 180]`).

### iPhone 16 393×852, safe area 59 / 34

Every case (bar button, view, tab item, sourceView, sourceRect, any arrow
mask, no source, 320×600) adapts to the same sheet: `UIDropShadowView
[0, 59, 393, 793]`, presentation controller still `UIPopoverPresentationController`,
`arrowDirection` stays NSUIntegerMax, `adaptiveSheetPresentationController`
is a `_UIFormSheetPresentationController` with `[large]`;
`sourceItem.view.mediumDetent` (`adaptiveSheetPresentationController.detents = [.medium()]`,
WordPress's line) → `UIDropShadowView [8, 403.687, 377, 440.313]` holding a
393×459 content view. No exception for a missing source on the phone.
