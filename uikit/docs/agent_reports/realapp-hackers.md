# Hackers feed real-app oracle

## Screen

Third real-app oracle, beside Pocket Casts and Firefox Focus: Hackers'
main feed (`realapp_hackers_feed_light`). [weiran/Hackers](https://github.com/weiran/Hackers)
at `83016de256ef5418f76ec53182d25e302a519234` (the ladder pin with zero
blocking missing types). That tree is SwiftUI-majority; the feed is
`Features/Feed` (`FeedView`, `FeedViewModel`, `PostRowView`,
`WhatsNewPanelRow`), vendored unmodified under
`Sources/RealAppProbe/Vendored/Hackers/`.

Harness shims (fixed sample posts, navigation store, theme/settings,
safari SF Symbol thumbnail placeholder — no network, no third-party
dependency compiled in) live under `Sources/RealAppProbe/Hackers/` and
stub SPM targets `Domain` / `Shared` / `DesignSystem` under
`HackersModules/`, registered in `Package.swift` like FocusModules.
`DesignSystem` also exports `FocusDesignSystemStub` so Focus's
`import DesignSystem` still resolves. The guest builder compiles only
top-level `RealAppProbe/*.swift` + `Vendored/*.swift`, so the screen
joins `RealAppScreen.screens` through `#if canImport(Domain)` exactly
like Focus uses `canImport(Onboarding)`.

Captured on the iPhone 16 @3x as a `UINavigationController` +
`UIHostingController` window root (`scripts/realapp_probe_sim.sh`).

## Frames before pixels (iPhone 16 / iOS 26.1)

Golden dump:

- Nav bar `[0, 59, 393, 54]`; `_UIBarBackground` `[0, −59, 393, 113]`.
- `_UIHostingView` and `UpdateCoalescingCollectionView` fill the window
  `[0, 0, 393, 852]`; `contentOffset [0, −113]`;
  `adjustedContentInset [113, 0, 34, 0]` (59 status + 54 bar; 34 home
  indicator).
- `ListCollectionViewCell` full-width `[0, y, 393, h]` with
  **h = 127.333** (two-line title) / **107** (one-line).
- Separator `_UICollectionViewListSeparatorView [83, y, 294, 1]`:
  83 = 16 default `listRowInsets.leading` + 55 thumbnail + 12 HStack
  spacing; 294 = 393 − 83 − 16 trailing; height 1 pt.
- Search is a 44×44 nav platter at `[333, 0]` of the 54 pt bar, not a
  content `UISearchBar`. Principal "Top" is a glass menu, not a
  `UILabel` title.

The port's List is a `UIScrollView` (`accessibilityIdentifier`
`SwiftUI.List`). Class-for-class subtree compare is not 1:1; the pixel
score is the gate.

## Rules

Cited next to the code (scene `realapp_hackers_feed_light`, iPhone 16
@3x / iOS 26.1):

1. **Button/menu host frames are seeded from `bounds` in `init`.**
   `place` runs before `layoutSubviews`; `normalHost` defaulted to
   `.zero`, so every List row `Button` (PostRowView) laid
   `PostDisplayView` into 0×0 (96 `UILabel`s at width 0; thumbnail
   55×55 at origin −27.5).
2. **`.searchable(..., placement: .toolbar)` does not steal 44 pt.**
   Golden has no content search bar. Keep a 0-height `SwiftUI.Searchable`
   so `SwiftUIDesignSystemTests.testFeedSearchMenuListStyle…` still
   finds `UISearchBar`.
3. **Swipe-action chrome is hidden at rest.** The port painted a 96×row
   `systemOrange` strip at x=297 under the clear row (blob 58597 at
   `[282.7, 44, 110.3, 616]`). Golden cells are white until swipe.
   `actionHost.isHidden = true` until a pan reveals it.
4. **`.plain` List default `listRowInsets` are 16 on every edge** (iOS
   cut). Without insets, content measured ~75 and rows were 77 pt;
   16+75+16 = 107 and 16+95.333+16 = 127.333. Separator leading 83 and
   trailing pad 16. Catalyst `.plain` stays un-inset.
5. **Empty ViewBuilder branches are not cells.** `if let whatsNewPanel`
   / `if enableSearchPagination` false → `Optional.none` → `.empty`.
   Real List does not materialize those (no 44 pt spacers).
   `_openFlattenGroup` drops `.empty`.
6. **List rest offset is the nav-bar bottom in list space.** Golden
   offset −113. `_SwiftUIHostingView` rebuilds the scroll view during
   `layoutSubviews` before the new view inherits safe-area insets, so
   `safeAreaInsetsDidChange` never rebases a retained offset. Seed
   `contentOffset.y = −bar.convert(maxY, to: list).y`.
7. **HStack measure recompresses text children to `placeHStack` widths**
   (iOS cut). Measuring every child at the full proposal let the title
   think it had the thumbnail's width too, so two-line titles stayed one
   line in measure (row 109 vs 127.333). Catalyst keeps the old sum.

## Before / after

| screen | before | after | blob |
|---|---|---|---|
| realapp_hackers_feed_light | ~57 (swipe strip) / 68 (zero-width labels) | **84.582** | 58597 → 174.4 |
| realapp_history_light | 99.137 | 99.137 | 2.6 |
| realapp_settings_light | 98.535 | 98.535 | 2.0 |
| realapp_settings_dark | 98.548 | 98.548 | 2.0 |
| realapp_storage_light | 99.469 | 99.469 | 3.9 |
| realapp_settings_light_xs | 98.639 | 98.639 | 2.6 |
| realapp_settings_light_xxxl | 98.133 | 98.133 | 3.4 |
| realapp_settings_light_ax1 | 97.516 | 97.516 | 7.3 |
| realapp_settings_light_ipad | 99.511 | 99.511 | 1.8 |
| realapp_history_light_ipad | 99.760 | 99.760 | 6.5 |
| realapp_storage_light_ipad | 99.689 | 99.689 | 12.0 |
| realapp_focus_settings_light | 82.192 | 82.192 | 481.7 |

Floor 84.4 (measured − 0.1). Largest remaining blob is a text-column
strip `[84.0, 152.3, 11.7, 43.7]`. Missing 135.1 at `[287.3, 70, 23, 23]`
is the trailing search platter.

## Open

- iOS 26 nav chrome: glass "Top" menu, gear, and 44×44 search platter.
  `ToolbarItem` drops placement metadata, so a lumped `rightBarButtonItem`
  120×44 does not match and grew the nav blob when tried. Not modelled.
- Row height residual **+2 pt** (129.333/109 vs 127.333/107). Nameable
  as leftover measure vs `placeHStack` after insets; not fitted.
- Safari thumbnail placeholder vs the app's networked `ThumbnailView`
  (harness by construction — no network).
- List is `UIScrollView`, not `UpdateCoalescingCollectionView`.
- Principal toolbar item replacing the inline title.

## Gates

Catalyst **124/124**. iOS suite **112/113** (known `corner_radius`
99.411). Eleven existing real-app screens unchanged. Linux
`swift:6.2-noble` openrender green (Combine shim exports
OpenCombineDispatch / OpenCombineFoundation so unmodified
`FeedViewModel` `receive(on: DispatchQueue.main)` and
`NotificationCenter.publisher` compile). Unit tests
`SwiftUIDesignSystemTests`, `SwiftUILicensesTests`,
`SwiftUISettingsTests`. No `Package.resolved`. No
DateFormatter / NumberFormatter / NSRegularExpression /
JSONSerialization / `_StringProcessing` in top-level harness files.
