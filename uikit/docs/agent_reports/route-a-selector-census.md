# Route (a) selector census — 2026-09-07

This is a code inventory, not a Linux compilation claim. All `#if` branches
are counted. The scanner masks line comments, nested block comments and
string text, retaining code inside string interpolation. It is a bounded
lexical scanner, not a Swift semantic parser. Every file has SHA-256,
per-file counts, occurrence line/text/expression, and class declarations in
[`route-a-selector-census.json`](route-a-selector-census.json).

**NSObject counts below mean iOS SDK ancestry.** Direct means `: NSObject`;
transitive means a source/SDK superclass chain reaches NSObject. Ancestry is
measured from iPhoneSimulator26.1.sdk UIKit/Foundation headers and the
SwiftUI arm64 simulator interface, with each consumed declaration's SDK
path, line and text carried in JSON. This does not imply the same superclass
chain in Linux OpenUIKit. Unresolved inherited names are emitted rather than
assigned an NSObject ancestry; these include source and SDK protocols.

## Scope and totals

| Checked-in source family | Swift files | #selector | @objc | @objcMembers | perform calls | Direct NSObject | Transitive NSObject (iOS SDK) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Blockzilla | 131 | 74 | 82 | 0 | 4 | 3 | 59 |
| FocusLocalPackages | 51 | 3 | 3 | 0 | 0 | 0 | 7 |
| SnapKitVendored | 37 | 0 | 0 | 0 | 0 | 0 | 1 |
| FuziVendored | 8 | 0 | 0 | 0 | 0 | 0 | 0 |
| FocusDependencyAdapters | 14 | 0 | 0 | 0 | 0 | 11 | 2 |

`Blockzilla` is 129 ingested upstream Swift files plus `OpenUIKitLaunch.swift`
and `OpenUIKitGenerated.swift` (both have zero selector/objc/perform sites).
All 129 relative paths exist in the frozen Focus a2832521c1daa0c23419c73705ae043ed60c9791
corpus. `FocusLocalPackages` is all 51 Swift files under
`Sources/BlockzillaPackage`, including the original Onboarding and AppShortcuts.
`SnapKitVendored` is all 37 checked-in files, including Darwin's
Debugging.swift even though the Linux package excludes it; `FuziVendored`
is all eight checked-in Swift files.

`FocusDependencyAdapters` is deliberately separate: `Sources/Sentry` (one
file), `Sources/FocusAppServices` (one, the Nimbus adapter), and the 12 files
in `Sources/RealAppProbe/FocusModules` (Glean, Intents, IntentsUI, Licenses,
DesignSystem and the Linux Onboarding adapters). This includes inactive or
excluded files in those directories. These are the checked-in adapters,
not the upstream Sentry, Glean or Rust-components implementations.
OpenUIKit, UIKitShim, SwiftUI, Combine, Apple-framework port modules, C
libraries, and resolved-but-unvendored OpenCombine/swift-syntax checkouts
are outside this **Focus app + vendored dependency** denominator. Their
runtime/compiler obligations are not erased by the zero adapter count.

The current app/package total is **77 selectors and 85 @objc attributes**;
SnapKit/Fuzi/adapters add zero. There are **four perform calls** in three
Blockzilla files:

| File | Line | Expression | Obligation |
| --- | ---: | --- | --- |
| Blockzilla/Settings/Controller/AutocompleteCustomUrlViewController.swift | 178 | `perform(#selector(updateEmptyStateView), with: nil, afterDelay: …)` | delayed instance invocation |
| Blockzilla/Utilities/KeyboardType.swift | 24 | `perform(NSSelectorFromString("identifier"))` | dynamic private selector and unretained return |
| Blockzilla/Utilities/WebCacheUtils.swift | 64 | `clazz.perform(Selector(("optional" + "Shared" + "History")))` | dynamically found class and object return |
| Blockzilla/Utilities/WebCacheUtils.swift | 66 | `o.perform(Selector(("remove" + "All" + "Items")))` | dynamic instance invocation |

The three direct Blockzilla NSObject subclasses are `SearchEngine`
(Search/SearchEngine.swift:7), `OpenUtils` (Utilities/OpenUtils.swift:7),
and `KeyboardHelper` (Utilities/KeyboardHelper.swift:53). All 59 transitive
Blockzilla subclasses, seven package subclasses and one SnapKit subclass
are listed with their complete measured chains in JSON.

## Reconciliation with the frozen ladder

`full/ladder/ladder-census-2026-09-16.json` is the **20 app** census. Its Focus
row walks 227 Swift files and reports 77 `#selector`, 86 textual `@objc`, one
`@objcMembers`, 73 wiring selectors, one deep selector and three unclassified
selectors. The current app/package slice has 180 upstream files plus two
generated files; the other 47 frozen files contribute **zero selectors**.
Re-running this scanner over the frozen 227 files yields **77 selectors,
85 code @objc attributes, one @objcMembers and four perform calls**.
The 86→85 difference is the block comment in `URLBar.swift:885` containing
`@objc`; `ladder_census.py` documents its textual count. The one
`@objcMembers` belongs to unvendored
`focus-ios-tests/ScreenshotTests/SnapshotHelper.swift:54`, not the app.

`full/ladder/deps-census-2026-09-16.json` is the separate **30 dependency**
repository census. Its SnapKit row is 42 files, zero selectors/objc; our
vendored production subset is 37 files, also zero. Its Sentry row is 545
Swift files, 67 selectors, 1,832 @objc, and 56 @objcMembers. None of those
67 upstream selector sites is present in the one-file local Sentry
adapter. The zero adapter count does not close the upstream Sentry wall.
Fuzi, Glean, OpenCombine and Rust components are not entries in that
30-dependency file. `wall-audit-2026-09-16.json` audits public type
declarations, not selector or compiler support.

## Per-file counts

All paths below are relative to `uikit/`. Files with no counted operation
or NSObject ancestry are omitted here but remain in JSON. `N direct` and
`N indirect` again mean iOS SDK ancestry.

| File | #selector | @objc | @objcMembers | perform | N direct | N indirect |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Sources/Blockzilla/Blockzilla/AppDelegate.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/BrowserViewController.swift | 6 | 6 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Declarative DataSource/DataSource.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/HomeViewController.swift | 1 | 1 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Lib/InsetTextField.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Lib/PaddedSwitch.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Menu/Old/PhotonActionSheet.swift | 1 | 2 | 0 | 0 | 0 | 3 |
| Sources/Blockzilla/Blockzilla/Menu/Old/PhotonActionSheetCell.swift | 1 | 1 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Modules/WebView/WebViewController.swift | 1 | 2 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Pro Tips/ShareTrackersViewController.swift | 1 | 1 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Pro Tips/TipViewController.swift | 2 | 2 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Pro Tips/TipsPageViewController.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Search/SearchEngine.swift | 0 | 0 | 0 | 0 | 1 | 0 |
| Sources/Blockzilla/Blockzilla/SearchSuggestions/OverlayView.swift | 5 | 6 | 0 | 0 | 0 | 2 |
| Sources/Blockzilla/Blockzilla/SearchSuggestions/SearchSuggestionsPromptView.swift | 2 | 2 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Settings/Cells/SettingsTableViewAccessoryCell.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Settings/Cells/SettingsTableViewCell.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Settings/Cells/SettingsTableViewToggleCell.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Settings/Controller/AboutViewController.swift | 2 | 2 | 0 | 0 | 0 | 2 |
| Sources/Blockzilla/Blockzilla/Settings/Controller/AddCustomDomainViewController.swift | 2 | 2 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Settings/Controller/AddSearchEngineViewController.swift | 3 | 3 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Settings/Controller/AutocompleteCustomUrlViewController.swift | 2 | 2 | 0 | 1 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Settings/Controller/AutocompleteSettingViewController.swift | 4 | 4 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Settings/Controller/SafariInstructionsViewController.swift | 1 | 1 | 0 | 0 | 0 | 2 |
| Sources/Blockzilla/Blockzilla/Settings/Controller/SearchSettingsViewController.swift | 1 | 1 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Settings/Controller/SettingsContentViewController.swift | 1 | 1 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Settings/Controller/SettingsViewController.swift | 6 | 7 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Settings/View/ActionFooterView.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Settings/View/InstructionsView.swift | 0 | 0 | 0 | 0 | 0 | 2 |
| Sources/Blockzilla/Blockzilla/Siri/SiriFavoriteViewController.swift | 4 | 4 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Theme/ThemeCells/ThemeTableViewAccessoryCell.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Theme/ThemeCells/ThemeTableViewToggleCell.swift | 1 | 1 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Theme/ThemeViewController.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Tracking Protection/Presentation/SheetModalViewController.swift | 2 | 1 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Tracking Protection/TrackingProtectionViewController.swift | 1 | 1 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Tracking Protection/Views/ImageCell.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Tracking Protection/Views/SubtitleCell.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Tracking Protection/Views/SwitchTableViewCell.swift | 1 | 1 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Tracking Protection/Views/TrackingHeaderView.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/UIComponents/AutocompleteTextField.swift | 6 | 5 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/UIComponents/BrowserToolbar.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/UIComponents/EditView.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/UIComponents/GradientBackgroundView.swift | 0 | 0 | 0 | 0 | 0 | 2 |
| Sources/Blockzilla/Blockzilla/UIComponents/GradientProgressBar.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/UIComponents/HomeViewToolbar.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/UIComponents/InsetButton.swift | 0 | 1 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/UIComponents/SmartLabel.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/UIComponents/SplashViewController.swift | 1 | 1 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/UIComponents/URLBar/Combine+UIControl.swift | 1 | 1 | 0 | 0 | 0 | 0 |
| Sources/Blockzilla/Blockzilla/UIComponents/URLBar/URLBar.swift | 6 | 11 | 0 | 0 | 0 | 2 |
| Sources/Blockzilla/Blockzilla/Utilities/Debouncer.swift | 1 | 1 | 0 | 0 | 0 | 0 |
| Sources/Blockzilla/Blockzilla/Utilities/FindInPageBar.swift | 4 | 4 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Utilities/KeyboardHelper.swift | 4 | 4 | 0 | 0 | 1 | 0 |
| Sources/Blockzilla/Blockzilla/Utilities/KeyboardType.swift | 0 | 0 | 0 | 1 | 0 | 0 |
| Sources/Blockzilla/Blockzilla/Utilities/OpenUtils.swift | 0 | 0 | 0 | 0 | 1 | 0 |
| Sources/Blockzilla/Blockzilla/Utilities/TitleActivityItemProvider.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/Blockzilla/Blockzilla/Utilities/WebCacheUtils.swift | 0 | 0 | 0 | 2 | 0 | 0 |
| Sources/Blockzilla/OpenUIKitGenerated.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/BlockzillaPackage/AppShortcuts/ShortcutView.swift | 1 | 1 | 0 | 0 | 0 | 1 |
| Sources/BlockzillaPackage/Onboarding/OnboardingViewController.swift | 1 | 1 | 0 | 0 | 0 | 1 |
| Sources/BlockzillaPackage/Onboarding/PortraitHostingController.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/BlockzillaPackage/Onboarding/Tooltip/TooltipTableViewCell.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/BlockzillaPackage/Onboarding/Tooltip/TooltipView.swift | 1 | 1 | 0 | 0 | 0 | 1 |
| Sources/BlockzillaPackage/Onboarding/Tooltip/TooltipViewController.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/BlockzillaPackage/UIComponents/AsyncImageView.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/SnapKit/LayoutConstraint.swift | 0 | 0 | 0 | 0 | 0 | 1 |
| Sources/RealAppProbe/FocusModules/Intents/Intents.swift | 0 | 0 | 0 | 0 | 4 | 0 |
| Sources/RealAppProbe/FocusModules/IntentsUI/IntentsUI.swift | 0 | 0 | 0 | 0 | 0 | 2 |
| Sources/Sentry/Sentry.swift | 0 | 0 | 0 | 0 | 7 | 0 |

## Reproduce

From `uikit/`:

```sh
python3 Tools/ingest/route_a_selector_census.py --out docs/agent_reports/route-a-selector-census.json
python3 Tools/ingest/test_route_a_selector_census.py
```

`--sdk /path/to/iPhoneSimulator26.1.sdk` selects the recorded SDK explicitly.
The three scanner tests cover nested comments/raw/multiline strings and
interpolation, nested selector arguments, generic inheritance, exclusion of
`func perform` declarations, and direct/transitive/unresolved class ancestry.
No app, library, rendering rule, golden or package manifest changes in this
census step; no runtime gate result is claimed by the inventory itself.
