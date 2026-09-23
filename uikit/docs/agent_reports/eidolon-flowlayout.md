# eidolon-flowlayout — Objective-C UICollectionViewFlowLayout subclasses

Eidolon's first screen (the listings grid) is laid out by
ARCollectionViewMasonryLayout 2.0.0, an Objective-C
`UICollectionViewFlowLayout` subclass.

## What changed

- `UICollectionViewLayout`, `UICollectionViewFlowLayout`,
  `UICollectionViewLayoutAttributes` and the two invalidation contexts derive
  from NSObject (as UIKit's do: flowlayoutprobe section 1) and, under
  OPENUIKIT_OBJC_SUBCLASSING, carry UIKit's runtime names and are vtable-free
  (ObjCSubclassingTests). Override points are `@objc(<SDK selector>) dynamic`.
- UIKitObjCSupport.h: UICollectionViewScrollDirection,
  UICollectionElementCategory, and the UICollectionViewDataSource / Delegate /
  DelegateFlowLayout protocols (`…ObjC` Swift names).
- OpenUIKitObjCBridge/UICollectionViewObjCBridge.swift: UICollectionView's
  Objective-C surface; an Objective-C data source or delegate is wrapped for
  the Swift protocols and `-delegate` / `-dataSource` return the original.

## Measured (Tools/oracle2/flowlayoutprobe, iPhone 16 / iOS 26.1)

The shared scenario drives a masonry-shaped subclass in a window. OpenUIKit
now matches the whole transcript (FlowLayoutObjCTests):

- `-setSize:` on attributes keeps the center.
- `-initWithFrame:collectionViewLayout:` sends the layout nothing; a reload's
  `-invalidateLayout` arrives at the next layout pass.
- A pass: `-prepareLayout` (data-source counts fetched lazily inside it),
  `-collectionViewContentSize`, `-layoutAttributesForElementsInRect:`,
  `-collectionViewContentSize`. The rect is the visible bounds widened to the
  bounds-size grid (`{0,0,320,480}` at y 0, `{0,0,300,960}` at y 100). The
  signalrowsprobe offset oracle shows the same thing in all 17 of its cases, and
  ContentOffsetInvalidationOrderTests now expects it.
- Views are created only for elements that intersect the visible bounds and for
  items within the counts, which an invalidation does not refetch.
- `-[UICollectionView layoutAttributesForItemAtIndexPath:]` answers from the
  last query and does not reach the layout.
- When a content-size change leaves the offset out of range, or the view
  leaves the window with the offset out of range, UIKit asks
  `-shouldInvalidateLayoutForBoundsChange:` with the clamped bounds.
  The offset does not move.

## ARCollectionViewMasonryLayout.m, iOS triple (objc_pod_census.py --ios-sdk)

64 errors before, 0 after. The pod's IntegrationTests TU still fails, with 1
error: `ARCollectionViewController.h` is missing because the pod's demo app is
not checked out.

## Still open

- UICollectionView keeps its mangled runtime name (it is not vtable-free), so
  `NSStringFromClass` differs and Objective-C cannot subclass it.
- There is no `contentInsetAdjustmentBehavior`. OpenUIKit behaves as if it were
  Never, and the oracle pins Never.
- `transform` on attributes: CGAffineTransform has no Objective-C spelling here.
  This is CA/CG unification, which belongs to cg-unify.
- Not implemented: `+layoutAttributesClass`, `estimatedItemSize`, decoration
  views.
- OpenUIKit's own flow layout passes element kinds as Swift strings. An
  Objective-C layout that compares a kind by pointer
  (`kind == UICollectionElementKindSectionHeader`, as the pod does in
  `-layoutAttributesForSupplementaryViewOfKind:atIndexPath:`) only sees the
  constant when the kind came from its own attributes.
