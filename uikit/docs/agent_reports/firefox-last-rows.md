# firefox-ios: the last two blocking rows — UIMenuBuilder and UICommandAlternate

Branch `agent/firefox-last-rows`, 2026-09-10, from `origin/main` `488e8bf3`.
The regenerated ladder table (`ladder-table-regen.md`, 437-name list,
`full/ladder/gap-classes-nextrungs-2026-09-10.json`) leaves firefox-ios two
blocking UIKit rows: `UIMenuBuilder` (2 uses) and `UICommandAlternate` (1).
Both are measured on the iPhone 16 / iOS 26.1 simulator (and the iPad A16
for the iPad-vs-iPhone question), implemented from the transcript, and the
classifier re-run reads **0 blocking rows** for firefox-ios.

Nothing outside `uikit/` was written. No pin file, `Package.resolved`,
`.app` bundle, app source or corpus clone was touched. Simulators
`OpenUIKit-FirefoxLastRows-{iphone,ipad}-firefox-last-rows` were created and
deleted.

## What firefox uses (corpus clone, read-only)

- `Client/Application/AppDelegate.swift:421`: `override func buildMenu(with
  builder: UIMenuBuilder)` on `AppDelegate: UIResponder, UIApplicationDelegate`;
  calls `super`, `guard builder.system == .main`, then the helper.
- `Client/Helpers/MenuBuilderHelper.swift`: `insertChild(_:atStartOfMenu:)`
  on `.application .file .view .window`, `replace(menu: .find, with:)`,
  `remove(menu: .font)`, `insertSibling(_:afterMenu:)` after `.view` and
  after its own `com.mozilla.firefox.menus.history` / `.bookmarks`
  identifiers; menus are `.displayInline` `UIMenu`s of `UIKeyCommand`s with
  `wantsPriorityOverSystemBehavior = true`; the identifiers `.find` and
  `.font` had no declaration in the port.
- `UICommandAlternate(title:action:modifierFlags: [.shift])` passed as
  `alternates:` of the Cmd-T "New Tab" key command (the port's `alternates:`
  parameter was typed `[UICommand]` and discarded). A separate Cmd-Shift-P
  "New Private Tab" command exists too.
- firefox's BrowserViewController does not return these from `keyCommands`;
  the main menu is the only place its shortcuts live.

## Probe recipe

`Tools/oracle2/firefoxlastrowsprobe/main.swift` (one file, no Xcode project),
`scripts/firefox_last_rows_probe_sim.sh /tmp/ff {iphone|ipad} [--edge]`.
Transcripts committed: `ios-26.1-iphone16.json`, `ios-26.1-ipad-a16.json`,
`ios-26.1-iphone16-edge.json`, `ios-26.1-iphone16-run1-launchbuild.json`;
the README lists every row. Hardware keys: the host route (System Events
into Simulator.app) delivered nothing — no device window, hardware
keyboard disconnected globally, left alone — so the probe builds the press
through UIKit's own `UIPhysicalKeyboardEvent` + IOKit HID event and hands it
to `handleKeyUIEvent:`; two other private resolution routes agree on every
press, and the public `sendEvent(_:)` routes no key events.

## Oracle table

| question | iPhone 16 | iPad A16 |
| --- | --- | --- |
| `buildMenu` at launch / didBecomeActive | none | none |
| `setNeedsRebuild()` | nothing inside the call, nothing within 8 s | same |
| first-responder change, `setNeedsRevalidate()` | nothing | same |
| first hardware key event | main build: UIApplication → AppDelegate (never the window / VC / view) | same |
| later key events | no rebuild | same |
| `presentEditMenu` | context build: view → VC → window → app → delegate, before `menuFor`; a VC skipping `super` does not stop the walk | same |
| default `.root` children | application, file, edit, format, view, window, help | identical tree |
| nil identifiers | autoFill, learn, lookup, openRecent, replace, share | same |
| `menu(for:)` | a COPY of the inserted menu | same |
| `replace(.find)` / `remove(.font)` / inserts | in place, nil afterwards / gone / index 0, append, after-sibling | same |
| missing identifiers, duplicates, same object twice | silent no-ops / accepted, no trap | — |
| `UICommandAlternate ==` | iff `modifierFlags` equal; `alternates` returns the given objects | same |
| ⌘J / ⌘⇧J / ⌘⌥J with `.shift`/`.alternate` alternates | base / alternate / alternate; sender for an alternate is a NEW `UIKeyCommand` (alternate's title+action, the command's input, the pressed flags, no alternates) | same |
| ⌘⌃J, ⌘⇧⌥J, plain J | nothing | same |
| `[base, direct ⌘⇧J]` vs `[direct, base]` | alternate wins / direct wins — list order | same |
| `validate(_:)` | once per performed press, on the chain-start responder, with the resolved command | same |
| menu-only shortcuts (⌘T, ⌘⇧T, ⌘⇧P, ⌘W, ⌘⌥,) | fire through the chain; ⌘⇧T via the alternate; firefox's Close Tab beats UIKit's Close | same |
| ⌘J vended by a responder AND in Tools | the responder's wins | same |

One of eight iPhone launches (the first ever on a fresh device with
Simulator.app pointed at it) built the main menu at launch, 10 ms after
`didFinishLaunching` returned; a fresh device again did not reproduce it.
The port implements the lazy rule the other seven and both iPad launches
showed.

## What changed in the port

- `Sources/OpenUIKit/UIMenuBuilder.swift` (new): `UIMenuSystem`
  (`main`/`context`, `setNeedsRebuild` = dirty flag, `setNeedsRevalidate` =
  store-only), the `UIMenuBuilder` protocol, the private tree builder
  (copy-on-insert, copy-on-query, silent no-ops), the measured default
  main tree, `_currentMenu()` for a host with a menu bar.
- `UIResponder.buildMenu(with:)` / `validate(_:)` (no-op defaults; UIKit
  walks the chain itself).
- `UIMenu.swift`: `UICommandAlternate`; `UICommand.alternates` and the
  `alternates:` parameter on both inits; `UIKeyCommand._match` (alternate
  resolution with the synthesized sender); the 43 missing standard
  `UIMenu.Identifier`s with measured raw strings; a menu without an
  identifier now gets `com.apple.menu.dynamic.<n>` (measured: never its
  title); `UIWindow.performKeyCommand` builds the main system on the first
  press, validates, then falls back to the built main menu.
- `UIEditMenuInteraction.presentEditMenu` builds the context system from
  the source view up (measured order) before asking the delegate.

## Tests

`Tests/OpenUIKitTests/FirefoxLastRowsTests.swift`: `CommandAlternateTests`
(4) and `MenuBuilderTests` (9), every expectation a transcript row.
Failing-first: the file does not compile against main's sources (`cannot
find 'UIMenuSystem' in scope`, `UIResponder has no member 'buildMenu'`,
`cannot find type 'UIMenuBuilder'`), verified by stashing the source
changes and building the tests.

```
swift test --filter "CommandAlternateTests|MenuBuilderTests"
  13 tests, 0 failures
swift test --filter "CommandAlternateTests|ContextMenuInteractionTests|FirstResponderTests|KeyCommandTests|MenuBuilderTests|MenuLayoutTests|MenuRenderTests|ResponderChainTests|ResponderFirstResponderTests|ResponderTouchForwardingTests|UIEditMenuInteractionTests"
  72 tests, 0 failures (13 new + 59 existing: key commands 9, menu layout 10, menu render 4, context menu 3, edit menu 10, responder 23)
```

Merge check: `CHECK_ONLY=1 uikit/scripts/agent_merge.sh agent/firefox-last-rows`
after `git merge origin/main` (clean; the ladder-table-regen landing was
already on main). First run on `4c48ade6` stopped in the guest library
route (Foundation hidden): `UIMenuBuilder.swift` named `NSObject` without
UIMenu.swift's conditional import. `fd0c88e2` mirrors the import
(`scripts/guest_route_check.sh` → `GUEST_ROUTE_CHECK_OK` locally); on it:

```
checks passed (CHECK_ONLY)
```

(macOS build + Catalyst gate, guest route, test bundle, real-app screens,
conformance re-render, Linux `openrender` build; no REFUSED.)

## Classifier

The `remeasure` regex over this worktree's `Sources/OpenUIKit` gives 440
names = the committed 437 + `UICommandAlternate`, `UIMenuBuilder`,
`UIMenuSystem`, nothing removed. `ladder_census.py` on the frozen corpus
clone (mini-corpus of one symlink, the way `ladder-table-regen.md`
documents) → `classify_gaps.py` with `uikit-union-2026-09-16.json`:

| firefox-ios | 437 list (reproduces the committed JSON) | worktree list (440) |
| --- | --- | --- |
| blocking | 2 types / 3 uses: `UIMenuBuilder 2 · UICommandAlternate 1` | **0 / 0** (no blocking key) |
| stub-able | 9 / 24 | 9 / 24, unchanged |

Declaration coverage is textual (the regen report's caveat stands): the
build, launch and behaviour claims are the tests above, not the row.

## Walls and leftovers

- The launch-time main build seen once is unexplained; the port builds on
  the first key event, which is what every other launch did.
- The context system's default tree (eight groups of private edit actions
  on a plain view) is recorded, not modelled; this port's edit menu passes
  no system actions, so the context builder starts from an empty root.
- Default menu commands with no target in the chain (UIKit's `performClose:`
  for ⌘W once firefox's menu is gone) return false from
  `performKeyCommand`; whether UIKit would try the next matching command is
  unmeasured.
- Nothing draws a menu bar or the shortcut HUD; `UIMenuSystem.main._currentMenu()`
  is the host's hook.
- `full/` is outside this branch's write scope; the §9.6 firefox row and
  the JSON are not edited here.
