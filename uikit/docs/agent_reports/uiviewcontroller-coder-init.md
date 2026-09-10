# UIViewController.init?(coder:): the base row, measured and added

2026-09-09 — `agent/uiviewcontroller-coder-init`, base `c7130364` (main).
Oracle: private iPhone 16 simulator, iOS 26.1 (23B86), 393×852 pt @3x,
device `OpenUIKit-ViewControllerCoder-uiviewcontroller-coder-init` (deleted).
No app source, golden, pin file, `Package.resolved` or `.app` changed.

## Result

`uicollectionviewcontroller.md` (2026-09-09) carried one base row it could
not close: `UIViewController.init?(coder:)` did not exist, so every app
subclass's `required init?(coder:)` (the spelling every storyboard/nib-backed
controller carries) and the coder initializers added to
`UITableViewController` / `UICollectionViewController` had no base to chain
to; the collection controller's coder initializer called `super.init()`.

The initializer now exists with UIKit's shape, `public required
init?(coder: NSCoder)` on `UIViewController`, and it is measured: on an empty
keyed archive Apple's result is indistinguishable from `init(nibName: nil,
bundle: nil)`, field for field. Fourteen port subclasses with designated
initializers of their own gained the required initializer the compiler then
demanded; the six container ones are pinned to transcript rows, the rest
mirror their own programmatic initializer and say so.

| row | Apple iOS 26.1 | port before | port after |
| --- | --- | --- | --- |
| `UIViewController(coder:)` on an empty keyed archive | non-nil; `isViewLoaded` false; `viewIfLoaded` nil; `nibName` nil; `nibBundle === Bundle.main`; `title` nil; `storyboard` / `restorationIdentifier` nil | does not compile (`extra argument 'coder'`) | non-nil, unloaded, nibName nil, nibBundle main, title nil |
| first `view` access after coder init | plain `UIView` [0,0,393,852], autoresizing 18, nil background, 0 subviews; `viewDidLoad` once, only then | — | plain `UIView`, nil background, 0 subviews, same frame and mask as the port's nil/nil initializer (its frame is 390×844, a pre-existing row) |
| `base.coder` vs `base.programmatic` vs `base.nilnil` | three identical rows | — | one code path: the coder initializer stores exactly what nil/nil stores |
| subclass with `init(frame:)` + `required init?(coder:)` calling super | non-nil; state set before chaining kept ([1,2,3,4]); unloaded; title nil; `viewDidLoad` count 0 then 1 | does not compile | same, tested |
| subclass whose designated initializer sets `title` | coder path leaves `title` nil | — | same, tested |
| `UITableViewController(coder:)` | style 0 (plain), `tableView === view`, unloaded, `clearsSelectionOnViewWillAppear` true, `refreshControl` nil | does not compile (no required initializer) | plain, `tableView === view`, unloaded (the two preferences do not exist on the port's class) |
| `UICollectionViewController(coder:)` | non-nil, unloaded, layout nil, nibName nil, title nil | non-nil, unloaded, layout nil (chained to `super.init()`) | chains to `super.init(coder:)`; its 3 tests keep passing |
| `UINavigationController(coder:)` | 0 view controllers, bar not hidden, unloaded | does not compile | same |
| `UITabBarController(coder:)` | `viewControllers` nil, `selectedIndex` NSNotFound, unloaded | does not compile | `viewControllers` nil, unloaded |
| `UISplitViewController(coder:)` | style 0 (unspecified), 0 view controllers | does not compile | same |
| `UIPageViewController(coder:)` | `transitionStyle` 0 (pageCurl), `navigationOrientation` 0, `viewControllers` non-nil | compiled but chose `.scroll` (1) and called `super.init()` | pageCurl / horizontal, chains to the base |
| `UIAlertController(coder:)` | `preferredStyle` 0 (actionSheet), title / message nil, 0 actions, unloaded | inherited the nib initializer: `.alert` (1) | actionSheet, tested |
| `UISearchController(coder:)` | non-nil, unloaded, `searchResultsController` nil | does not compile | same |
| `NSKeyedArchiver` round trip of a titled controller | `title` and `restorationIdentifier` decode back (483 bytes) | no archive reader | no archive reader (limit below) |

## What the coder path does in the port

Nothing with the coder. `UIViewController.init?(coder:)` stores `nibName`
nil, `nibBundle` `Bundle.main`, no explicit nib request, and calls
`super.init()`; it is the nil/nil programmatic initializer under UIKit's
required spelling, which is exactly what the `base.*` rows say Apple does
for an empty archive. The reason it cannot do more is the port's `NSCoder`:

- With Foundation visible (every Darwin and Linux package build),
  `OpenUIKit.NSCoder` is `Foundation.NSCoder` (`FoundationTypes.swift`).
  Every existing coder initializer in the port (`UIView`, `UIScrollView`,
  `UICollectionViewController`, `UIPageViewController`, the WebKit and
  LinkPresentation classes) ignores it, and the tests construct a bare
  `NSCoder()`. That object is abstract: on Darwin any `decodeObject(forKey:)`
  raises `NSInvalidArgumentException`, and swift-corelibs-foundation's base
  class traps with `NSRequiresConcreteImplementation`. Reading keys would
  turn every existing test and every app fixture into a crash.
- Without Foundation (the Mach-O renderer / guest builds), `NSCoder` is the
  port's own empty class with no decoding surface at all.
- No `NSKeyedUnarchiver` reaches UIKit: the vendored swift-foundation port
  (`FoundationEssentials`) does not carry keyed archiving, and the port has
  no nib/storyboard decoder (`UINib` loads the port's own XML nibs through
  `loadView`, not through `init?(coder:)`).

So the archive keys Apple round-trips for this class (`UITitle`,
`UIRestorationIdentifier`, `base.roundTrip`) are not read; a subclass that
decodes its own keys against a real `NSKeyedUnarchiver` still works because
the base only requires the coder to exist.

## Subclasses the compiler forced

Swift stops inheriting a required initializer the moment a subclass
declares a designated one, so adding it to the base surfaced every port
class with its own `init`:

- OpenUIKit: `UITableViewController` (plain), `UINavigationController`,
  `UITabBarController`, `UISplitViewController` (unspecified),
  `UISearchController` (nil results, wired search bar), `UIAlertController`
  (actionSheet, plus an explicit nib-initializer passthrough so
  `self.init()` still resolves), `UIPageViewController` (now pageCurl and
  chained), `UIImagePickerController`, `UIActivityViewController`,
  `UIColorPickerViewController`, `UIDocumentBrowserViewController`,
  `UIDocumentPickerViewController`, `UIFontPickerViewController`. The last
  six are unmeasured and mirror their designated initializer's defaults;
  each says so in a comment.
- Sibling frameworks: `MFMailComposeViewController` (pushes its form as
  `init()` does), `MFMessageComposeViewController`, `PHPickerViewController`,
  `PKAddPassesViewController`, the `IntentsUI` stand-in controllers, and
  `SFSafariViewController`, whose initializer is `@available(*, unavailable)`
  because SafariServices marks `initWithCoder:` `NS_UNAVAILABLE`.
- SwiftUI: `_OpenUIHostingController` gains SwiftUI's
  `init?(coder:rootView:)` and a trapping `init?(coder:)`, the shape Apple
  ships (a storyboard subclass overrides the latter to call the former).
- Port-owned demo / harness controllers (8 in `Sources/DemoApp`, one in
  `RealAppProbe/RealAppScreen.swift`) and 8 test fixtures take the
  `required init?(coder: NSCoder) { fatalError() }` idiom the same files
  already use for their views. No vendored app source needed a change:
  Blockzilla, Eidolon and the pocket-casts files already carry the
  initializer because they compile against UIKit.

## Oracle

`Tools/oracle2/viewcontrollercoderprobe/main.swift`, one file, no Xcode
project, built and run by `scripts/view_controller_coder_probe_sim.sh`
(the `collection_controller_probe_sim.sh` recipe):

```sh
SIM_DEVICE_SUFFIX=-uiviewcontroller-coder-init scripts/view_controller_coder_probe_sim.sh /tmp/vc-coder
```

Every coder row builds an EMPTY keyed archive
(`NSKeyedArchiver(requiringSecureCoding:false)` + `finishEncoding`) and
decodes with `requiresSecureCoding = false`; `describe()` reads each field
before the first `view` access and then reads the view once. The unedited
transcript is `ios-26.1-iphone16.json`; its README lists every row.

## Tests

`Tests/OpenUIKitTests/ViewControllerCoderTests.swift` (7); every expected
value is a transcript row and each test names it. Failing-first against the
main sources (`git stash` of `Sources/`): the file does not compile — eight
`extra argument 'coder' in call` / `argument passed to call that takes no
arguments` errors, one per controller class the tests construct, plus
`type 'Equatable' has no member 'unspecified' / 'actionSheet'` downstream.
After: the page-controller row failed first (`1` for `0`, the old `.scroll`
choice) and passes with the measured pageCurl.

```text
swift test --filter ViewControllerCoderTests
  ViewControllerCoderTests            7 tests, 0 failures
  CollectionViewControllerCoderTests  3 tests, 0 failures (filter overlap)
swift test --filter 'ViewController|TableView|CollectionView'
  27 suites, 144 tests, 0 failures
swift test (whole package, Darwin)
  branch: 1747 tests, 3 skipped, 31 failures in 9 cases
  main sources, same machine, same full run: 1740 tests, 3 skipped, 31 failures in 10 cases
  the branch's 9 are a subset of main's 10 (KeyboardChromeTests ×4,
  TextFieldDelegateTests ×2, UISearchBarTests, FoundationCoexistenceTests,
  IOSNavigationBarTransitionTests — the last passes in isolation on both);
  main's tenth, ValueTypeTailTests.testShortcutDeliveryPrefersWindowSceneDelegate,
  did not fail on the branch run. None touch a controller initializer.
```

`swift build` (whole package, Darwin): complete. Linux: the merge check
(`CHECK_ONLY=1 agent_merge.sh`), verdict in the REAL_APP_TEST row.

## Limits, stated

- **The coder is never read.** Title, restoration identifier, nib name and
  every subclass key Apple decodes stay at their programmatic defaults; the
  base row is the nil/nil initializer under the required spelling. This
  cannot change until the port has a keyed unarchiver that its own tests
  and app fixtures (bare `NSCoder()`) can survive.
- **Six OpenUIKit subclasses are unmeasured on the coder path**
  (`UIImagePickerController`, activity, color / font picker, the two
  document controllers); their initializers mirror the designated one.
- **Default view frame** stays the port's 390×844 for both spellings;
  Apple's is 393×852 on this device. The test asserts parity between the
  two initializers, not the number. `UITableViewController`'s table is
  [0,0,0,0] on Apple for both spellings and 390×844 in the port; both are
  pre-existing rows outside this task.
- **`UITabBarController.selectedIndex`** after coder init is NSNotFound on
  Apple; the port's getter is not asserted.
- **`UITableViewController`** has no `clearsSelectionOnViewWillAppear` /
  `refreshControl` in the port; the measured true / nil are documented only.
