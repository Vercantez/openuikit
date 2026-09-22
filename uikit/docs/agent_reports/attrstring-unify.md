# attrstring-unify: UIKit's attributed strings are Foundation's on the Apple toolchain

**Date:** 2026-09-22
**Branch:** `agent/attrstring-unify`. It starts from `agent/simplenote-objc-core` and merges `origin/main` (last 1b10648d, which includes ios-oss-walls).
**Routes:** Apple toolchain (the macOS host, and route (b)'s iOS triple once `ios-target` lands). The portable path is unchanged.
**Status:** done for both apps' walls.
* **Kickstarter Library:** the `'NSAttributedString' is ambiguous` errors went 18 → 0 (6 files), and no other error changed. NumberFormatter.swift:14's `Formatter` override now compiles without the module-local alias.
* **Simplenote:** the bridging-header PCH went from 1 error to 0. Its Swift half now reaches type checking, with 0 NSAttributedString ambiguity errors.
* **Pixels and gate:** all 178 Catalyst scene PNGs and all 15 real-app PNGs are byte-identical to the branch point (release `openrender`). Gate: 124/124.

## What changed

**Selection.** The switch is `#if canImport(ObjectiveC) && canImport(Foundation)`, the same split `UIView.swift` already uses.

| build | Foundation | ObjC runtime | attributed-string types |
|---|---|---|---|
| macOS host (gate, tests, `openrender`) | yes | yes | **Foundation's** |
| route (b), iOS triple (`ios-target`) | yes | yes | **Foundation's** |
| native Linux ELF (`swift:6.2-noble`) | corelibs | no | OpenUIKit's portable run list |
| guest library route (`build_full.sh`, Foundation hidden) | no | yes | OpenUIKit's portable run list |

**`NSAttributedString.swift`**
* `NSAttributedString` and `NSMutableAttributedString` are typealiases of Foundation's classes.
* UIKit's 15 attribute keys are declared as an extension on Foundation's `NSAttributedString.Key`, with iOS raw values, but only where AppKit is not visible. On the macOS host AppKit already declares the same 15 with the same raw values, and a second declaration makes `.font` ambiguous for every client. The gate on `canImport(AppKit)` was agreed with `ios-target`.
* Two internal helpers keep the text layout source-identical: `runs`, which reads Foundation's effective ranges, and `fullRange`.

**`NSTextStorage.swift`**
* `NSTextStorage` is now an `@objc` subclass of Foundation's `NSMutableAttributedString`, over a concrete backing store.
* It follows the simplenote-objc-core vtable-free rule. Every overridable member is `@objc dynamic` or an override of an Objective-C method, and everything else is `final`. A test reads the type descriptor to check this.
* Runtime and Objective-C names:
  * On the iOS triple, the class is `NSTextStorage` and the protocol is `NSTextStorageDelegate`.
  * On the macOS host, the process also loads AppKit's (UIFoundation's) classes, and every Clang context that sees AppKit declares them too. There the names are `OUKTextStorage` and `OUKTextStorageDelegate`. `UIKitObjCSupport.h` gives Objective-C the UIKit spelling through `@compatibility_alias` and a `#define`.
* `NSTextStorage.EditActions` is an Objective-C option set, `OUKTextStorageEditActions` in `cportableio.h`, with iOS raw values. Swift cannot declare an Objective-C option set itself.
* The delegate is an `@objc` protocol with optional methods, as on iOS. `UITextView` conforms to it unchanged.
* The macOS host needs four AppKit-typed initializers: the `required` pasteboard initializer plus `html:`, `url:` and `data:`. They are `@nonobjc`, so `OpenUIKit-Swift.h` does not `@import AppKit`; that header's UIKit interfaces collide with AppKit's. These four are the only Swift vtable slots the class introduces. OpenUIKit never calls them, and the test allows exactly these four.
* Foundation's cluster initializers are unimplemented on a subclass (measured: `-[OUKTextStorage initWithString:]: unrecognized selector`). Each initializer therefore fills the backing store itself.

**The contract, as measured on iOS 26.1 and implemented:**
* **Callback order.** processEditing runs: will-notification → delegate `willProcessEditing` → `invalidateAttributes(in:)` → did-notification → delegate `didProcessEditing` → each layout manager's `processEditing(for:edited:range:changeInLength:invalidatedRange:)`. The old port called the delegate before the notification and invalidated layout managers between will and did.
* **Clearing.** processEditing does not clear the edit state and does not skip an empty mask. `endEditing` and a top-level `edited` call it only when the mask is non-empty, then clear. After clearing, `editedRange` is `{NSNotFound, <old length>}` and `changeInLength` is 0.
* **Range merging.** `edited` unions the new range into `editedRange`, then applies `length += delta` for a character edit; the deltas add up. Edits made during processEditing join the pending edit rather than recursing.
* **Lazy fixing.** A plain `NSTextStorage` fixes attributes lazily (YES). A subclass does not (NO), so its `fixAttributes(in:)` runs inside processEditing.

**`NSLayoutManager`** gains iOS's `processEditing(for:…)`, which invalidates the edited range.

**`UIKit` shim.** `AttributeContainer.init(_ dictionary:)` is now declared only on the portable path. With Foundation's key type it duplicated Foundation's own initializer, and every `AttributeContainer([...])` became ambiguous.

## The oracle: `Tools/oracle2/textstorageprobe`

`run.sh` compiles `scenario/OUKTextStorageScenario.m` against the iOS 26.1 simulator's UIKit and runs it on a throwaway iPhone 16. It writes `transcript-ios26.1.txt` (443 lines). The same `.m` is compiled against OpenUIKit as the SwiftPM target `OpenUIKitTextStorageFixtures`. The scenario covers:
* **Attributed strings:**
  * run coalescing, including `@1` vs `1.0` and equal but distinct strings;
  * `enumerateAttribute` and `enumerateAttributes`: longest effective range, the not-required option, reverse, stop, clipping, empty range;
  * `longestEffectiveRange` and `effectiveRange`;
  * which attributes replaced or inserted text inherits;
  * `mutableString` edits;
  * UTF-16 length and surrogates;
  * `NSRangeException` past the end;
  * `isEqualToAttributedString:` and copies.
* **NSTextStorage:**
  * 18 edit sequences on the base class and on an Objective-C backing-store subclass shaped like `SPInteractiveTextStorage`;
  * the order of the subclass's primitive calls;
  * a processEditing override that restyles before calling super;
  * edit masks for 13 kinds of insert and delete.
* **Oracle-only facts** (UIFont, NSLayoutManager subclasses and UITextView have no Objective-C face in OpenUIKit):
  * font substitution by `fixAttributes`;
  * the layout-manager ordering;
  * `UITextView.textStorage`.

`Tests/AttributedStringUnifyTests` has 8 tests. Before this branch the target could not compile: there was no `NSTextStorage` interface, and the `Formatter` override did not match.
* The attributed-string section matches the transcript **line for line (47/47)**.
* The NSTextStorage section (342 lines) matches on **all but 9 of its lines**. Those 9 are tolerated explicitly: the test prints them and pins their count, and the only tolerance is an extra `attr` bit on iOS's side, in the base-class blocks only. The subclass's `prim setAttributes:` write-back after `fixAttributesInRange:` is also removed from the expected trace (see the divergence below).
* The layout-manager order matches the oracle. The first edit reports mask 2 where iOS reports 3; the extra `attr` bit is the same font fixing.
* The `Formatter` override compiles and runs. `OpenUIKit.NSAttributedString` is Foundation's type, and the vtable check passes.

### Measured divergence, kept on purpose: attribute fixing

On iOS 26.1, `fixAttributes` substitutes fonts:
* a run with no font gets Helvetica 12;
* over "a😀中z" in Helvetica 17, the emoji gets AppleColorEmoji 17 and the CJK character gets PingFangSC-Regular 17.

`NSConcreteTextStorage` also fixes lazily while edits read attributes. As a result some edit masks gain `attr`, even when the font covers every character (transcript: "edit masks with and without a covering font").

OpenUIKit's `fixAttributes(in:)` does nothing:
* its UIFont is a Swift struct, not an object UIKit code could read back as a UIFont;
* fallback fonts are resolved at layout time;
* inserting fonts would change the layout that the gate byte-checks.

On the macOS host the override also stops AppKit's category method from inserting AppKit `NSFont` objects. The trace test pins the consequences (9 lines).

Also measured and not changed: iOS's `UITextView.textStorage.delegate` is nil. OpenUIKit's UITextView sets itself as the delegate to keep `text` and `attributedText` in sync. An app that replaces the storage delegate would break that sync.

## Proof on the apps

Machine-readable file: [attrstring-unify-census.json](attrstring-unify-census.json).

### Simplenote (route (b), macOS triple)

`xcodeproj_to_package.py …/simplenote-ios/Simplenote.xcodeproj --target Simplenote --allow-gaps`, then `swift build --target Simplenote`:

| | main d48096f4 | this branch |
|---|---|---|
| bridging-header PCH | **1 error**: `SPInteractiveTextStorage.h:4:39: cannot find interface declaration for 'NSTextStorage'` | **0**. `SPInteractiveTextStorage : NSTextStorage` compiles against the Objective-C `NSTextStorage` (Foundation's `NSMutableAttributedString` underneath) |
| Swift half | not reached | reaches type checking: 422 unique errors in 73 files, **0** `NSAttributedString` ambiguity (simplenote-objc-core measured 22 of those behind a fake NSTextStorage) |

The remaining groups are the ones simplenote-objc-core listed. The macOS triple accounts for `@IBAction` arity and the AppKit / QuartzCore class-name collisions (`CALayer`, `NSParagraphStyle`, `OUK_NSLayoutConstraint`, …). The rest are API gaps. An `NSTextStorageDelegate` collision that this branch had introduced was measured and removed (`OUKTextStorageDelegate` on the host).

### Kickstarter Library (route (b))

The chain spec and commands are `agent/ios-oss-walls`' (66fbfb82). I merged that branch into scratch worktrees; nothing was committed there. Library is only reachable behind the macOS AppKit leak, so both runs apply **the same scratch-only changes**:
1. **Experiment E**, re-applied by hand: no `import AppKit` in OpenUIKit, IndexPath members `@_disfavoredOverload`, `awakeFromNib` not an override, and the SwiftUI TextAttributes guard removed.
2. **A ServerDrivenUI stub.** `AudioVideoBlock.swift` is replaced by a body-less stub of the same type, because Apple's macOS AVFoundation is unavailable on this triple. iososs-walls confirmed that their earlier "ServerDrivenUI 0" came from stale, uncommitted AV modules.
3. **"After" only:** this branch's `canImport(AppKit)` branches are forced to the no-AppKit (iOS-triple) form, because E removes the AppKit import they assume.

`swift build --target Library -Xswiftc -disable-batch-mode` compiles one file per frontend. Batch mode loses different files' diagnostics to a signal-4 compiler crash on each run.

| Library | before (ios-oss-walls + E) | after (+ attrstring-unify) |
|---|---|---|
| unique errors | 72 in 24 files | **54** in 18 files |
| `'NSAttributedString' is ambiguous` | 18, in SharedFunctions, String+Attributed, String+SimpleHTML, BackerDashboardProjectCellViewModel(+Utilities), ProjectPamphletCreatorHeaderCellViewModel | **0** |
| NumberFormatter.swift:14 `override attributedString(for:withDefaultAttributes:)` | fails once the alias is added (ios-oss-launch3) | **compiles with no alias** |
| any other error | — | **identical set** (removed 18, added 0) |

**Next wall in Library, not attributed-string identity.** Batch mode also shows `heterogeneous collection literal could only be inferred to '[NSAttributedString.Key : Any]'` in 2–3 files, on both sides. `[.font: UIFont, .foregroundColor: UIColor, .paragraphStyle: NSMutableParagraphStyle]` types as `[Key: NSObject]` on iOS only because UIFont is an NSObject there; OpenUIKit's UIFont is a struct.

## Validation

| check | result |
|---|---|
| Catalyst gate (`CHECK_ONLY=1 agent_merge.sh`, after merging main 1b10648d) | `124/124 scenes pass`, real-app floors held, `GUEST_ROUTE_CHECK_OK`, conformance re-render passed (no stale sets allowed), Linux build complete: `==> checks passed (CHECK_ONLY)` |
| pixels (release `openrender`, same inputs, base vs branch) | 178/178 scene PNGs and 15/15 real-app PNGs **byte-identical** |
| real-app 3x | 99.137 / 98.535 / 98.548 / 99.74 / 98.72 / 98.334 / 97.549 / 99.65 / 98.823 / 98.558 / 99.86 / 99.734 / 98.235 / 99.61 (same as main) |
| guest library route (`guest_route_check.sh`) | `GUEST_ROUTE_CHECK_OK` |
| Linux `swift:6.2-noble` | `openrender` builds (portable path) |
| full `swift test` (clean build, macOS) | 1902 tests with the same 10 failing test cases as main d48096f4 (1896 tests), a set-identical diff. Main's failures include `FoundationCoexistenceTests` (UUID in UIEditMenuInteraction), KeyboardChrome, TextFieldDelegate, UISearchBar, UIScrollEdgeEffect and IOSNavigationBarTransition |
| `AttributedStringUnifyTests` | 8/8. The existing `AttributedStringTests` pass on Foundation's type; two assertions of the portable type's clamping and inout-stop behaviour are portable-only |
| guest (`local_guest_verify.sh`, full Mach-O) | `FOCUS_REAL_APPDELEGATE_LAUNCHED root=BrowserViewController`, `rendered 15 screens; existing screens byte-identical 14/14 (including Ledger)`, `REAL-APP SCREEN VERIFIED ON LINUX` (rc 0). This exercises the portable path; the guest build hides Foundation |

## What stayed on OpenUIKit's own types, and why

* **The portable `NSAttributedString` / `NSMutableAttributedString` / `NSTextStorage`** stay wherever Foundation or the Objective-C runtime is absent:
  * **Native Linux ELF.** Corelibs Foundation's `NSMutableAttributedString` traps when run coalescing calls `isEqual` on plain Swift values (measured earlier, FoundationTypes.swift), and OpenUIKit's UIFont is such a value.
  * **Foundation-hidden guest library route.** No Foundation module exists there.
  * **The guest runs** (`build_full.sh`) therefore still exercise the portable text system. The Foundation path is exercised on the macOS host and, later, on the iOS triple.
* **`NSParagraphStyle` / `NSMutableParagraphStyle`, `NSTextAttachment`, `NSLayoutManager`, `NSTextContainer`, `NSUnderlineStyle`** remain OpenUIKit's on every route. On iOS these are UIKit classes, not Foundation's. They were already NSObject-based where it mattered, and Foundation stores them as attribute values unchanged.

## Risks

* **Foundation raises where the portable type clamped.** Attribute reads at or past `length`, and slices past the end, now raise NSRangeException (measured). I audited every OpenUIKit call site and all are bounds-checked. App code that relied on the clamping would now crash on the Apple toolchain, as it does on iOS.
* **`fixAttributes` is a no-op** (the divergence above). Apps that rely on UIKit's font substitution in a text storage's attributes (not in rendering) see no substituted fonts.
* **The macOS host's names differ from iOS's:** `OUKTextStorage` and `OUKTextStorageDelegate` at runtime and in Objective-C interfaces, with the UIKit spellings aliased. `NSStringFromClass` differs there, and on the iOS triple it is UIKit's.
* **AppKit-dependent branches.** They follow ios-target's plan: the macOS host keeps `import AppKit`, and apps move to the iOS triple. If the macOS host ever drops the import, the `canImport(AppKit)` branches must become the iOS form, exactly what the Kickstarter "after" scratch did.
* **`AttributeContainer([NSAttributedString.Key: Any])`** is Foundation's own initializer on the Apple toolchain. On the macOS host it resolves through AppKit's scope, and the shim's UIKit-scope conversion test is portable-only. The iOS triple was not measured here.
* **Message dispatch** on NSTextStorage's members. Pixels are identical; speed was not measured.
