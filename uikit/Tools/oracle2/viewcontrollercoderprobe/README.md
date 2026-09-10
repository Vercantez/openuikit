# UIViewController coder-init oracle (`init?(coder:)` on an empty archive)

Measured 2026-09-09 on a private iPhone 16 simulator, iOS 26.1 / 23B86,
393×852 @3x, device `OpenUIKit-ViewControllerCoder-uiviewcontroller-coder-init`
(deleted after the run). Run from `uikit/`:

```sh
SIM_DEVICE_SUFFIX=-mine scripts/view_controller_coder_probe_sim.sh /tmp/vc-coder
```

`ios-26.1-iphone16.json` is the unedited transcript. It pins the base row
`uicollectionviewcontroller.md` carried as `coder.empty.base`, and what the
same empty keyed archive (`NSKeyedArchiver(requiringSecureCoding:false)` +
`finishEncoding`, decoded with `requiresSecureCoding = false`) yields for an
app-shaped subclass and for every container subclass whose `required
init?(coder:)` must chain to the new base. `describe()` reads each field
BEFORE the first `view` access, then reads the view once.

| row | what it pins |
| --- | --- |
| `base.coder` | `UIViewController(coder:)`: non-nil, `isViewLoaded` false, `viewIfLoaded` nil, `nibName` nil, `nibBundle === Bundle.main`, `title` nil, `storyboard` nil, `restorationIdentifier` nil; first `view` access loads a plain `UIView` [0,0,393,852], autoresizing 18, nil background, no subviews |
| `base.programmatic` / `base.nilnil` | `UIViewController()` and `(nibName: nil, bundle: nil)`: byte-identical rows to `base.coder` |
| `subclass.coder` | a subclass with `init(frame:)` plus `required init?(coder:)` calling super keeps the state it set before chaining (frame [1,2,3,4]), is non-nil, unloaded, title nil; `viewDidLoad` runs once, on the first `view` access |
| `subclass.programmatic` | the same subclass through its designated initializer (frame [5,6,7,8]); otherwise identical |
| `subclass.titled.coder` | a subclass whose designated initializer sets `title` keeps `title` nil on the coder path |
| `table.coder` / `table.programmatic` | `UITableViewController(coder:)`: style 0 (plain), `tableView === view`, `clearsSelectionOnViewWillAppear` true, `refreshControl` nil, view `UITableView` [0,0,0,0] (also [0,0,0,0] programmatically), `tableBackgroundColor` |
| `collection.coder` | `UICollectionViewController(coder:)`: non-nil, unloaded, layout nil, nibName nil, title nil (repeat of `collectioncontrollerprobe` `coder.empty`) |
| `navigation.coder` | `UINavigationController(coder:)`: 0 view controllers, bar not hidden, view `UILayoutContainerView` with 3 subviews, `toolbar` non-nil |
| `tab.coder` | `UITabBarController(coder:)`: `viewControllers` nil, `selectedIndex` NSNotFound, view `UILayoutContainerView` with 2 subviews, `systemBackgroundColor` |
| `split.coder` | `UISplitViewController(coder:)`: style 0 (unspecified), 0 view controllers, view `UIView` with 2 subviews, `systemBackgroundColor` |
| `page.coder` | `UIPageViewController(coder:)`: `transitionStyle` 0 (pageCurl), `navigationOrientation` 0, `viewControllers` non-nil, view `_UIPageViewControllerContentView` |
| `alert.coder` | `UIAlertController(coder:)`: non-nil, unloaded, title / message nil, 0 actions, `preferredStyle` 0 (actionSheet) |
| `search.coder` | `UISearchController(coder:)`: non-nil, unloaded, `searchResultsController` nil |
| `base.roundTrip` | `NSKeyedArchiver` of a programmatic controller with `title` and `restorationIdentifier` (483 bytes) decodes both back; the view is still lazy |

The probe writes the JSON after each phase so a late crash keeps earlier
rows; no phase crashed.
