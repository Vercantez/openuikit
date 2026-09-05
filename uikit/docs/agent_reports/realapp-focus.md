# Firefox Focus Settings real-app oracle

## Screen

Second real-app oracle, beside Pocket Casts: Firefox Focus Settings
(`realapp_focus_settings_light`). mozilla-mobile/focus-ios at
`a2832521c1daa0c23419c73705ae043ed60c9791` (the Focus widget gate pin).
`SettingsViewController` and the cells/footer it needs are vendored
under `Sources/RealAppProbe/Vendored/Focus/` (cells/footer unmodified;
SettingsViewController `ADAPTED(objc-runtime)` `#selector`/`@objc` →
`Selector.named` + SelectorTables.swift so native ELF compiles; the Darwin
oracle compile restores the upstream spelling). App types
(strings, DesignSystem colours from xcassets, telemetry no-ops) live in
`FocusShims.swift`. Captured on the iPhone 16 @3x as the window root
(Focus presents Settings in a `UINavigationController`; `viewDidLoad`
force-unwraps `navigationController!`).

## Frames before pixels (iPhone 16 / iOS 26.1)

Golden dump:

- Nav bar `[0, 59, 393, 54]`; `_UIBarBackground` `[0, −59, 393, 113]`.
- Child view `[0, 113, 393, 739]`; table `[0, 0, 393, 739]`,
  `contentOffset` 0, `adjustedContentInset` `[0,0,34,0]`.
- `UILayoutContainerView.backgroundColor` absent (nil).
- Custom footer `ActionFooterView` `[20, 87, 353, 71.667]`; footnote
  label h 28.667 (two 14.333 lines of 12 pt).
- Cells 52 pt; inset-grouped card inset 20.

The port underlapped the table (`contentOffset` −113, child full window)
because the iOS cut always filled the container, and painted
`.systemBackground` (255) through the 113 pt strip.

## Rules (iOS cut)

1. **Opaque bar insets content.** `navigationBar.isTranslucent == false`
   places `contentView` at y = pad+barH (113) with child
   `safeAreaInsets.top` 0. Default iOS 26 glass bars stay translucent and
   still underlap (Forms / NavFlow). Guard: `UINavigationBar.isIOS`.
2. **Container background is nil**, not `.systemBackground`. Combined with
   `setBackgroundImage(UIImage(), for: .default)` the 113 pt strip is
   unpainted. The probe captures with `UIGraphicsImageRendererFormat.opaque
   = true`, so those pixels are (0,0,0,255); `openrender realapp` fills
   zero-alpha the same way. Catalyst keeps `.systemBackground`.
3. **Inset-grouped custom footers use the card inset** (`[20, y, 353, h]`)
   and are fitted at that width. A vertical `UIStackView` wraps
   `numberOfLines != 1` labels at the stack width (Focus footnote 28.667 /
   footer 71.667). Catalyst and `numberOfLines == 1` stay one-line.

## Before / after

| screen | before | after | blob |
|---|---|---|---|
| realapp_focus_settings_light | 58.476 | **80.345** | 41234 → 3668.9 |
| realapp_history_light | 99.137 | 99.137 | 2.6 |
| realapp_settings_light | 98.535 | 98.535 | 2.0 |
| realapp_settings_dark | 98.548 | 98.548 | 2.0 |
| realapp_storage_light | 99.469 | 99.469 | 3.9 |
| realapp_settings_light_xs | 98.639 | 98.639 | 2.6 |
| realapp_settings_light_xxxl | 98.133 | 98.133 | 3.4 |
| realapp_settings_light_ax1 | 97.516 | 97.516 | 7.3 |
| realapp_settings_light_ipad | 99.511 | 99.511 | 1.8 |

Floor 80.2 (measured − 0.1). Largest remaining blob is the Done platter
`[286, 44, 107, 69]`.

## Open

- Done glass over the unpainted bar reads (220,220,220); the port's
  `platterFill` is opaque white (255). The portable renderer cannot sample
  the backdrop (docs/KNOWN_GAPS.md). Not modelled.
- Row height 52 vs `defaultRowHeight` 53 (tableview_grouped is 53).
- `UIImage(systemName: "chevron.right")` is not in `_UISystemImageRenderer`.
- First untitled header is 35 pt in the dump vs the delegate's 30.
- Focus sets `contentView.layoutMargins.left = 20`; stock grouped text is
  16 inside the card. The port hardcodes 16.

## Gates

Catalyst **124/124**. iOS suite **112/113** (known `corner_radius` 99.411).
Eight Pocket Casts screens unchanged. Linux `swift:6.2-noble` openrender
green: RealAppProbe's SwiftUI dependency compiles `AppLifecycle.swift`,
and Linux 6.2.4 refuses `DelegateType.init()` because Foundation's
`NSObject.init()` is not `required`. The adaptor is `#if !os(Linux)`
(Focus Settings only needs views / `UIHostingController` on that path).
SettingsViewController's `#selector` / `@objc` lines are
`ADAPTED(objc-runtime)` (`Selector.named` + SelectorTables.swift); the
Darwin oracle compile restores the upstream spelling. Unit tests
`IOSNavigationBarTransitionTests` (opaque-bar inset),
`TableViewMetricsTests`, `StackViewTests`, `TableViewIOSEditChromeTests`.
