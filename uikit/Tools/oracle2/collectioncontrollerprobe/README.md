# Collection controller oracle (rows the blocking probe does not pin)

Measured 2026-09-09 on a private iPhone 16 simulator, iOS 26.1 / 23B86,
393×852 @3x, device `OpenUIKit-CollectionController-uicollectionviewcontroller`
(deleted after the run). Run from `uikit/`:

```sh
SIM_DEVICE_SUFFIX=-mine scripts/collection_controller_probe_sim.sh /tmp/collection-controller
```

`ios-26.1-iphone16.json` is the unedited transcript. It complements
`../collectionblockingprobe` (`vc.*` rows: lazy wrapper geometry, delegate
wiring, replacement, initial-layout identity) and
`../collectionlifecycleprobe` (nil assignment, appearance-phase selection
clearing) with:

| row | what it pins |
| --- | --- |
| `bare` | a bare `UICollectionView` already has `systemBackgroundColor`, `translatesAutoresizingMaskIntoConstraints` true, `alwaysBounceVertical` false, `contentInsetAdjustmentBehavior` 0 |
| `lazy` | reading `collectionViewLayout` and setting the three preferences do not load the view |
| `viewFirst` / `viewDidLoad` | `view` access creates wrapper + collection together; wrapper autoresizing 18, background nil; `viewDidLoad` sees a non-nil collection whose superview is `view`, both [0,0,393,852] |
| `loadView.plain` / `.collection` / `.subview` | a custom `loadView` never yields a `collectionView`, even when the installed view IS a `UICollectionView` (autoresizing 0, not wired, controller layout unchanged) |
| `gesture.*` | `_UICollectionViewLegacyReorderingGestureRecognizer` appears only in a window, only when the data source implements `moveItemAt`, only while `installsStandardGestureForInteractiveMovement` is true; toggling it on after load installs it immediately |
| `coder.empty.base` / `coder.empty` | `UIViewController(coder:)` and `UICollectionViewController(coder:)` on an empty keyed archive: non-nil, unloaded, nibName nil, layout nil, preferences true / true / false |
| `coder.roundTrip` | NSKeyedArchiver round trip keeps `clearsSelectionOnViewWillAppear` and `installsStandardGestureForInteractiveMovement`, drops `useLayoutToLayoutNavigationTransitions` and the layout (548 bytes) |

The probe writes the JSON after each phase so a late crash keeps earlier
rows; no phase crashed. Fifteen scroll-view/collection recognizers are
listed verbatim for the gesture rows; the port does not reproduce that list
and no test asserts it.
