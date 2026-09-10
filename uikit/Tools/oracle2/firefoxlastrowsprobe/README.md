# firefoxlastrowsprobe — UIMenuBuilder and UICommandAlternate

Measures firefox-ios' last two blocking UIKit rows
(`full/ladder/gap-classes-nextrungs-2026-09-10.json`, 437-name list):
`UIMenuBuilder` (2 uses: `AppDelegate.buildMenu(with:)` override and
`MenuBuilderHelper.mainMenu(for:)`) and `UICommandAlternate` (1 use: the
`.shift` alternate on the Cmd-T "New Tab" key command). Transcripts, unedited:

| file | device | what |
| --- | --- | --- |
| `ios-26.1-iphone16.json` | iPhone 16, iOS 26.1 (393×852) | full timeline, defaults, firefox sequence, key presses |
| `ios-26.1-ipad-a16.json` | iPad (A16), iOS 26.1 (820×1180) | the same run; every row below is identical |
| `ios-26.1-iphone16-edge.json` | iPhone 16 | `--edge`: builder calls on missing / duplicate identifiers |
| `ios-26.1-iphone16-run1-launchbuild.json` | iPhone 16 | the one launch (of eight) that built the main menu at launch; see "When" |

Run from `uikit/`:

```sh
SIM_DEVICE_SUFFIX=-x scripts/firefox_last_rows_probe_sim.sh /tmp/ff iphone
SIM_DEVICE_SUFFIX=-x scripts/firefox_last_rows_probe_sim.sh /tmp/ff ipad
SIM_DEVICE_SUFFIX=-x scripts/firefox_last_rows_probe_sim.sh /tmp/ff iphone --edge
```

`swiftc -target arm64-apple-ios26.0-simulator`, minimal Info.plist, a device
`OpenUIKit-FirefoxLastRows-<kind><suffix>` created/booted/shut down by the
script, `simctl launch --console-pty`, JSON copied out of `Documents/`. Every
`mark` rewrites the JSON (a trap keeps the rows before it).

The app: `MyApp: UIApplication`, `App: UIResponder, UIApplicationDelegate`,
`Win: UIWindow`, `RootVC`, `RootView`, `TF: UITextField` — every one
overrides `buildMenu(with:)` and `validate(_:)` and logs who/system/phase.

## How keys were pressed

The host route was tried first (System Events `keystroke` into
Simulator.app, `keys.log` of the first run): nothing reached the app —
Simulator.app had no window for the device and its hardware keyboard is
disconnected on this Mac (`ConnectHardwareKeyboard = 0`; a global setting
other agents' simulators share, so it was left alone). The probe therefore
builds the press the way UIKit's own keyboard path does:
`+[UIPhysicalKeyboardEvent _eventWithInput:inputFlags:]`, `_setModifierFlags:`,
an IOKit `IOHIDEventCreateKeyboardEvent` (usage page 7) attached with
`_setHIDEvent:keyboard:` so `_keyCode` is the real usage (13 for J — without
it nothing matched, `keyInjector.eventReadback`), then
`-[UIApplication handleKeyUIEvent:]`. Two more routes agree on every press
(`_keyboardShortcutInvocationForKeyboardEvent:` + `_performKeyboardShortcutInvocation:allowsRepeat:`,
and `_handleKeyboardShortcutForKeyboardEvent:allowsRepeat:`); the public
`sendEvent(_:)` does not route key events at all (0 `keyCommands` queries).
`keyCommands` is queried once per press.

## When `buildMenu` runs (`events`)

| row | iPhone 16 | iPad A16 |
| --- | --- | --- |
| launch → didFinishLaunching return → didBecomeActive | no build | no build |
| `UIMenuSystem.main.setNeedsRebuild()` (twice, 1.2 s / 1.8 s) | nothing inside the call, nothing after | same |
| text field becomes / resigns first responder | nothing | nothing |
| `setNeedsRevalidate()` | no `validate` call | same |
| `UIMenuSystem.context.setNeedsRebuild()` | nothing | same |
| `UIEditMenuInteraction.presentEditMenu` | `buildMenu` system=context on RootView → RootVC → UIWindow → UIApplication → AppDelegate, then the delegate's `menuFor` | same |
| second presentation with RootVC NOT calling super | the walk still reaches UIWindow, UIApplication, AppDelegate | same |
| FIRST hardware key event (5.9 s) | `buildMenu` system=main on UIApplication → AppDelegate (never RootVC/window/view) | same |
| later key events | no rebuild | same |

Seven of eight iPhone launches and both iPad launches built the main system
lazily at the first key event. The very first launch on a freshly created
device (`run1-launchbuild.json`, with Simulator.app pointed at it) built at
launch, 10 ms after `didFinishLaunching` returned and before
`applicationDidBecomeActive`, on UIApplication → AppDelegate. Re-creating
the device fresh and pointing Simulator.app at it again did not reproduce
it (`hardwareKeyboardAttached` false in every run); the condition was not
isolated. `UIMenuSystem.main` is a `UIMainMenuSystem`, `.context` a
`UIContextMenuSystem`, builder class `_UIMenuBuilder`.

## What the default builder carries (`builder.main.defaults.*`)

`.root` → application, file, edit, format, view, window, help. Full tree in
the transcript (`defaults.root`): identifiers, titles, `options` (1 =
`.displayInline`), and each key command's selector/input/modifierFlags —
e.g. File > close: "Close" `performClose:` ⌘W; Edit > undo-redo: Undo ⌘Z,
Redo ⌘⇧Z; standard-edit: Cut ⌘X, Copy ⌘C, Paste ⌘V, Paste and Match Style
⌘⌥⇧V, Delete (`UICommand`, attributes 2 = destructive), Select All ⌘A; Find
> find-panel: Find ⌘F, Find & Replace ⌘⌥F, Find Next ⌘G, Find Previous ⌘⇧G,
plus "Use Selection for Find" ⌘E; Format > Font > Text Style Bold/Italic/
Underline ⌘B/⌘I/⌘U, text-size Bigger ⌘+ / Smaller ⌘−; Text > alignment ⌘{ ⌘|
Justify ⌘}; View > sidebar "Show Sidebar" ⌘⌃S; Help: "" `showHelp:` ⌘?.
The application menu is titled with the bundle name and its Preferences
item reads "<name> Settings…" ⌘,. Nil: `.autoFill .learn .lookup .openRecent
.replace .share`. `newScene` and `newItem` are the same raw string
(`com.apple.menu.new-item`); `speech` is `com.apple.command.speech`.
`identifier.raw` lists all 50.

## What the mutations do (`builder.main.1.steps`, `…lookups`, `edge.steps`)

- `insertChild(_, atStartOfMenu:)` → index 0 of the parent; `atEndOfMenu` → last.
- `insertSibling(_, afterMenu:)` → right after the sibling in its parent
  (History after View in the root; Bookmarks after History; Tools after
  Bookmarks — the app's OWN identifiers are found).
- `replace(menu: .find, with: m)` → in place; `.find` then answers nil and
  `m.identifier` answers a copy of m.
- `remove(menu: .font)` → Format keeps only Text; `remove(menu: .file)` →
  `.file` nil, root has six children.
- `menu(for:)` returns a COPY: `=== inserted` false for every inserted menu.
- `command(for:)` finds by selector anywhere (New Tab, Reload, UIKit's own
  `cut:`), nil for an unknown selector; `action(for:)` finds a UIAction by
  identifier, nil otherwise.
- A menu built without an identifier: `com.apple.menu.dynamic.<UUID>`.
- Edge (`--edge`): remove / replace / insertSibling / insertChild on a
  missing identifier, a second replace of an already-replaced identifier,
  two menus with the same identifier, the same object inserted twice — all
  silent no-ops or accepted; no trap (`edge.done` true).

## UICommandAlternate (`model.alternate`, `fired` rows)

Data model: `NSObject` subclass; `title`/`action`/`modifierFlags` read back;
`a1 == a1b` (same flags, different title/action) true, `hash` equal, `a1 ==
a2` false; `copy() === self`; `kc.alternates` returns the given objects
(`=== a1`, `=== a2`), `[]` when none; `UICommand(alternates:)` likewise.

Presses on RootVC with `keyCommands` = [Base ⌘J, alternates .shift → fireAltShift, .alternate → fireAltOption]:

| press | phase A | phase B `[base, direct ⌘⇧J]` | phase C `[direct, base]` |
| --- | --- | --- | --- |
| ⌘J | fireBase, sender = Base (alternates 2) | fireBase | fireBase |
| ⌘⇧J | fireAltShift, sender = NEW UIKeyCommand title "Alt Shift", action fireAltShift:, input j, flags 1179648, alternates 0 | fireAltShift | fireDirect |
| ⌘⌥J | fireAltOption (flags 1572864) | — | — |
| ⌘⌃J, ⌘⇧⌥J, plain J | nothing | — | — |

`validate(_:)` is sent once per performed press, to RootVC only (the chain
start), with the resolved command (the synthesized one for an alternate),
before the action; never for an unmatched press.

Main-menu-only shortcuts (RootVC vends nothing, `menuOnly` rows): ⌘T →
newTab (sender = the menu's New Tab, alternates 1); ⌘⇧T → newPrivateTab via
the alternate (synthesized sender, input t, flags 1179648); ⌘⌥T nothing;
⌘⇧P → newPrivateTab; ⌘W → firefox's Close Tab (inserted at the start of
File, ahead of UIKit's Close); ⌘⌥, → openSettings; ⌘J → Tools > Downloads.
With RootVC vending Base ⌘J again, ⌘J → fireBase: a responder's command
beats a menu command. One unattributed `fireBase` follows the last press in
each run (a deferred perform; not modelled).
