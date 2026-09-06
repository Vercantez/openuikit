# uikit-tail-values — APP_LADDER §4 value-type / process-local cluster

Worktree branch `agent/uikit-tail-values`. No pixel scenes: these APIs
compile and carry measured process-local behaviour. Probe sources lived
in `/tmp/valuesprobe-uikit-tail-values/`; device `OpenUIKit-2x-uikit-tail-values`
(iPhone SE 3rd gen / iOS 26.1).

## Before / after

| gate | before | after |
|---|---|---|
| Catalyst | 124/124 | **124/124** |
| iOS suite | 112/113 (`corner_radius`) | **112/113** (`corner_radius` 99.411) |
| Real-app floors | 99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.65 / 82.17 / 99.86 / 99.734 / 85.393 | unchanged (ledger / focus-home goldens absent from `/tmp/golden_realapp_ios` and the committed snapshot; the 12 screens with goldens held) |
| Unit tests | pasteboard + impact + shortcut shape | **+15** `ValueTypeTailTests`; existing Pasteboard / ApplicationShell / ResponderLifecycle / FocusLaunchCore still green |
| Linux `swift:6.2-noble` openrender | green | **green** (220.02 s, no Mac `.build`) |

No `Package.resolved`. No pin files. Nothing outside `uikit/`.

## 20-app use-site counts these APIs now unblock

From `full/ladder/APP_LADDER.md` §4 (census 2026-08-27):

| # | cluster | apps / 20 | uses |
|---|---|---|---|
| 2 | `UIPasteboard` | **17** | 409 |
| 4 | haptics (`UIImpactFeedbackGenerator` 16/100, `UINotificationFeedbackGenerator` 11/75, `UISelectionFeedbackGenerator` 11/21) | **16** | 196 |
| 5 | home-screen shortcuts (`UIApplicationShortcutItem` 16/77, `UIApplicationShortcutIcon` 11/29, `UIMutableApplicationShortcutItem` 3/10) | **16** | ~110 |
| 6 | `NSItemProvider` (+ `UIActivityItemSource` 8/23, `UIActivityItemProvider`) | **13** | 103 |
| 13 | `UIAccessibilityCustomAction` (+ rotors / `accessibilityCustomActions`) | **9** | 87 |
| 14 | scene lifecycle (`UISceneConfiguration` 9/31, `UIUserActivityRestoring` 9/11, `UIOpenURLContext` 7/9) | **9** | 51 |

**956 uses** across those six rows. Overlap between apps is large (the
same 17 pasteboard apps include most of the haptics/shortcut set); the
census ranking is by app-reach, not disjoint union.

## What was measured (iPhone SE 3rd gen / iOS 26.1)

### Pasteboard notifications
Every mutation posts `UIPasteboardChangedNotification` on the **setter's
thread** (including a background queue). First post: `userInfo == nil`.
Second post only if the union of item type keys changed, with
`changedTypesAddedKey` / `changedTypesRemovedKey` = sorted symmetric
difference (empty side omitted). Same-string set twice: only the
nil-userInfo post. `remove(withName:)` posts **one**
`UIPasteboardRemovedNotification` with the live handle as `object` and
**no** changed notification.

`itemProviders = [NSItemProvider(object: "provider-text" as NSString)]`
populates `string` **synchronously**; types become `public.utf8-plain-text`.

### NSItemProvider
String → `public.utf8-plain-text`. URL → `public.url`. UIImage →
`com.apple.uikit.image, public.heic, public.png, public.jpeg`. UIColor →
`com.apple.uikit.color`. `loadObject` / `loadDataRepresentation` complete
on `com.apple.Foundation.NSItemProvider-callback-queue` (not main).
`suggestedName` round-trips.

### Shortcuts / haptics / a11y / scene
- `copy()` → immutable `UIApplicationShortcutItem`; `mutableCopy()` works.
  `targetContentIdentifier` default nil.
- `UIApplication.shared.shortcutItems` default is `[]` not nil; setting
  nil reads back as `[]`.
- `UIImpactFeedbackGenerator(style:view:)` attaches as a `UIInteraction`.
  `FeedbackStyle.medium.rawValue == 1`. Notification types success=0,
  warning=1, error=2.
- Custom action `name` ↔ `attributedName.string` lockstep. Handler
  non-nil. Rotor `systemRotorType` `.none` (0).
- `UISceneActivationConditions` defaults `TRUEPREDICATE` / `FALSEPREDICATE`.

## Rules landed

1. **Pasteboard** posts the measured two-step `changedNotification` after
   the storage mutex unlocks (so a background setter is legal). `remove`
   keeps a weak intern map so the live handle is the notification object.
2. **Haptics** are call-recording no-ops: `UIFeedbackGenerator` is a
   `UIInteraction`; impact / notification / selection generators expose
   the iOS 17 `init(view:)`, `init(style:view:)`, and `…(intensity:at:)` /
   `…(_:at:)` / `selectionChanged(at:)` spellings.
3. **Shortcuts** inherit `NSObject` + `NSCopying`/`NSMutableCopying`.
   `UIApplication.shortcutItems` stores `[]` for nil. Host
   `_hostPerformShortcut` prefers
   `windowScene(_:performActionFor:completionHandler:)`.
4. **NSItemProvider** is Linux-only in OpenUIKit (Darwin/guest Foundation
   already vend the type). UIImage/UIColor helpers live as Darwin
   overloads because those classes are not NSObject.
5. **UIActivityItemProvider** subclasses `Operation` and returns the
   placeholder from `item` unless a subclass overrides.
6. **UIAccessibilityCustomAction / Rotor** plus
   `accessibilityCustomActions` on `UIResponder`.
7. **UIOpenURLContext**, `UISceneOpenURLOptions`,
   `UISceneActivationConditions`, `UISceneConfiguration.storyboard` /
   `NSCopying`, `UIScene.activationConditions`,
   `scene(_:openURLContexts:)`. Foundation-gated where the SDK type is a
   Foundation type (`URL`, `NSPredicate`, `NSUserActivity`).

## OPEN (measured, no rule that fits every sample)

- Unique pasteboard names on iOS are UUIDs; the port keeps
  `OpenUIKit.unique.N` (existing PasteboardTests).
- `UISceneConfiguration(name: "Default Configuration", …)` with no
  Info.plist catalog returns `name == nil` on iOS. The port keeps the
  passed name so `ResponderLifecycleTests` and hosts still work.
- UIImage item-provider identifiers include `public.heic`; bytes written
  here are PNG.
- Color item-provider bytes are UTF-8 `"r,g,b,a"` floats, not UIKit's
  keyed archive.
- `UIImpactFeedbackGenerator(view:)` (no style) stores `.medium`
  (rawValue 1, the iOS 10 default). Hardware style for this spelling
  was not observed.
- `UIActivityItemSource.activityViewControllerLinkMetadata` is omitted:
  returning `LPLinkMetadata` would import LinkPresentation into OpenUIKit.
- Pasteboard `expirationDate` / `localOnly` are accepted; expiration
  cannot fire without a wall clock.
