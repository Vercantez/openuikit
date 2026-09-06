# APP LADDER rows 11–12 — search controller + system pickers

Worktree `agent/uikit-pickers-search`. Compile-and-fail-closed types so the
10/128 search-controller and 10/51+9/75 picker use sites type-check. No
new pixel rule: Ledger/Tabs search chrome stays the already-measured
`usesBottomSearch` / overlay dock (Ledger t200, iPhone SE 2x / iOS 26.1).

## Use sites unblocked (census in `full/ladder/APP_LADDER.md` §4)

| type | apps / uses | surface landed |
|---|---|---|
| `UISearchController` | 10 / 128 | delegate will/did present/dismiss, `presentSearchController`, placement callbacks, results-controller auto-show, suggestions, `scopeBarActivation` |
| `UISearchResultsUpdating` | 9 / 35 | `updateSearchResults(for:)` + `updateSearchResults(for:selecting:)` |
| `UISearchControllerDelegate` | 8 / 20 | all optional methods from the iOS 26.1 header + UIKit.apinotes names |
| `UIDocumentPickerViewController` | 10 / 51 | `forOpeningContentTypes:` / `forExporting:` / `forExportingURLs:` + UTI/URL inits |
| `UIDocumentPickerDelegate` | 10 / 22 | `didPickDocumentsAt` / `documentPickerWasCancelled` / deprecated single-URL |
| `UIImagePickerController` | 9 / 75 | source/media/camera properties, `isSourceTypeAvailable` **false**, InfoKey, delegate, video-save C entries |
| `PHPickerViewController` | PhotosUI module | configuration/filter/result/delegate; fail-closed `[]` |
| `UIDocumentBrowserViewController` | stub | `init(forOpening:)`, reveal/import/rename fail with `UIDocumentBrowserErrorDomain` |
| `UIPrintInteractionController` / `UIPrinterPickerController` | stub | `isPrintingAvailable == false`; present returns false |
| `UIActivityViewController` | already present | extra `ActivityType`s (SharePlay, collaboration, addToHomeScreen) |
| `UIFontPickerViewController` | stub | configuration copy-at-init, cancel / `_hostPick` |
| `UIColorPickerViewController` | **real picker** | `selectedColor` + iOS 15 `didSelect:continuously:` / `didFinish` |
| `SFSafariViewControllerDelegate` | already painted | `activityItemsFor` / `excludedActivityTypesFor` / redirect / `willOpenInBrowser` |

## What was measured

- **Search chrome (pixels held, not re-modelled).** Ledger t200, iPhone SE 2x /
  iOS 26.1: phone-without-tab-bar search is the bottom dock
  (`usesBottomSearch`), not `UINavigationItem.SearchBarPlacement`. Setting
  `preferredSearchBarPlacement` stores the enum and notifies the delegate;
  `.automatic` stays `.automatic`. Tabs overlay / cancel-slot heights are
  unchanged: `sizeThatFits` is still `(width, 44)` and the scope bar is not
  drawn (no measured height).
- **Camera availability.** iPhone SE simulator / iOS 26.1:
  `isSourceTypeAvailable(.camera)` is false. Photo library is true on the
  simulator; this port has no Photos service, so every source fails closed.
- **Print / document / font / PHPicker.** No host service. Completions are
  cancel or empty. Document-picker `_hostPick(urls:)` is the only success
  path (unit-tested).
- **Color picker.** HSB sliders over the measured page sheet (`UISlider`
  from `control_slider`) and `UIColor.getHue` / `init(hue:saturation:brightness:alpha:)`
  (sRGB math, not a pixel rule). Chrome is **not** the iOS 26 colour-well.

SDK names from iPhoneSimulator 26.1 headers + `UIKit.apinotes`
(`searchController(_:willChangeTo:)`, `UINavigationItem.SearchBarPlacement`,
`UIFontPickerViewController.Configuration`, `init(forOpening:)`).

## Gates

| gate | before | after |
|---|---|---|
| Catalyst | 124/124 | **124/124** |
| iOS suite | 112/113 (`corner_radius`) | **112/113** (`corner_radius` 99.411) |
| Real-app floors | 99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.65 / 82.170 / 99.86 / 99.734 / 85.393 | unchanged |
| Unit tests | — | `SystemPickerTests` 14, `UISearchControllerTests` 14, `ActivityViewControllerTests` held |
| Linux `swift:6.2-noble` | openrender | **openrender** green (211 s); `--target PhotosUI` green (184 s, Linux `NSItemProvider` stub) |
| `Package.resolved` | — | not committed |

## OPEN

- Dim overlay for `obscuresBackgroundDuringPresentation` — would move Tabs t4000.
- Scope-bar drawing / `sizeThatFits` height (unmeasured).
- Colour-well chrome vs HSB sliders.
- Remote document / image / font / print / PHPicker UI.
- `searchBarPlacement == .automatic` does not resolve to stacked/integrated
  (Ledger dock is a separate rule).
- `UIImagePickerController.isSourceTypeAvailable(.photoLibrary)` is false
  here even though the simulator reports true.
- Nested `UIDocumentBrowserViewController.Error` was not declared: a
  `typealias Error` inside the class shadows `Swift.Error` in the
  reveal/import/rename completions. `UIDocumentBrowserErrorCode` is the
  NS_ERROR_ENUM code type.
