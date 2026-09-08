import XCTest
import Foundation
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
final class CollectionBlockingTypesTests: XCTestCase {
    func testContextDefaultsAndEmptyItems() {
        let context = UICollectionViewLayoutInvalidationContext()
        XCTAssertFalse(context.invalidateEverything)
        XCTAssertFalse(context.invalidateDataSourceCounts)
        XCTAssertNil(context.invalidatedItemIndexPaths)
        XCTAssertNil(context.invalidatedSupplementaryIndexPaths)
        XCTAssertNil(context.invalidatedDecorationIndexPaths)
        XCTAssertEqual(context.contentOffsetAdjustment, .zero)
        XCTAssertEqual(context.contentSizeAdjustment, .zero)
        context.invalidateItems(at: [])
        XCTAssertNil(context.invalidatedItemIndexPaths)
    }

    func testItemInvalidationAccumulatesUniquePathsInInsertionOrder() {
        let context = UICollectionViewLayoutInvalidationContext()
        let a = IndexPath(item: 2, section: 1), b = IndexPath(item: 0, section: 0)
        context.invalidateItems(at: [a, b, a])
        XCTAssertEqual(context.invalidatedItemIndexPaths, [a, b])
        let c = IndexPath(item: 3, section: 1)
        context.invalidateItems(at: [a, c])
        XCTAssertEqual(context.invalidatedItemIndexPaths, [a, b, c])
        XCTAssertFalse(context.invalidateEverything)
    }

    func testKindsAccumulateIndependentlyIncludingEmptyEntries() {
        let context = UICollectionViewLayoutInvalidationContext()
        let a = IndexPath(item: 2, section: 1), b = IndexPath(item: 0, section: 0)
        context.invalidateSupplementaryElements(ofKind: "header", at: [a, b, a])
        context.invalidateSupplementaryElements(ofKind: "header", at: [a])
        context.invalidateSupplementaryElements(ofKind: "footer", at: [])
        context.invalidateDecorationElements(ofKind: "background", at: [b])
        XCTAssertEqual(context.invalidatedSupplementaryIndexPaths, ["header": [a, b], "footer": []])
        XCTAssertEqual(context.invalidatedDecorationIndexPaths, ["background": [b]])
    }

    func testFlowContextAndBoundsContextFlags() {
        let context = UICollectionViewFlowLayoutInvalidationContext()
        XCTAssertTrue(context.invalidateFlowLayoutAttributes)
        XCTAssertTrue(context.invalidateFlowLayoutDelegateMetrics)
        context.invalidateFlowLayoutAttributes = false
        context.invalidateFlowLayoutDelegateMetrics = false
        XCTAssertFalse(context.invalidateFlowLayoutAttributes)
        XCTAssertFalse(context.invalidateFlowLayoutDelegateMetrics)
        let layout = UICollectionViewFlowLayout()
        let collection = UICollectionView(frame: CGRect(x: 0, y: 0, width: 200, height: 300), collectionViewLayout: layout)
        for (rect, changed) in [(collection.bounds, false), (CGRect(x: 3, y: 4, width: 200, height: 300), true), (CGRect(x: 0, y: 0, width: 220, height: 300), true)] {
            let generated = layout.invalidationContext(forBoundsChange: rect) as! UICollectionViewFlowLayoutInvalidationContext
            XCTAssertEqual(generated.invalidateFlowLayoutAttributes, changed)
            XCTAssertFalse(generated.invalidateFlowLayoutDelegateMetrics)
        }
    }

    func testInvalidationDispatchesToSubclassEvenWhenDetached() {
        let layout = RecordingLayout()
        layout.invalidateLayout()
        XCTAssertEqual(layout.contexts.count, 1)
        XCTAssertFalse(layout.contexts[0].invalidateEverything)
        XCTAssertFalse(layout.contexts[0].invalidateDataSourceCounts)
        XCTAssertTrue(type(of: layout.invalidationContext(forBoundsChange: .zero)) == UICollectionViewLayoutInvalidationContext.self)
    }

    func testInvalidationAdjustsImmediatelyAndLayoutRestoresContentSize() {
        let layout = RecordingLayout()
        let controller = ItemController(collectionViewLayout: layout)
        let collection = controller.collectionView!
        controller.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        controller.view.layoutIfNeeded()
        collection.contentOffset = CGPoint(x: 20, y: 30)
        let context = UICollectionViewLayoutInvalidationContext()
        context.contentOffsetAdjustment = CGPoint(x: 3, y: 4)
        context.contentSizeAdjustment = CGSize(width: 10, height: 20)
        layout.invalidateLayout(with: context)
        XCTAssertEqual(collection.contentOffset, CGPoint(x: 23, y: 34))
        XCTAssertEqual(collection.contentSize, CGSize(width: 510, height: 1220))
        collection.layoutIfNeeded()
        XCTAssertEqual(collection.contentSize, CGSize(width: 500, height: 1200))
        XCTAssertEqual(collection.contentOffset, CGPoint(x: 23, y: 34))
    }

    func testNilAssignmentPreservesUnloadedStateAndLoadedNilStaysNil() {
        let controller = ItemController(collectionViewLayout: UICollectionViewFlowLayout())
        controller.collectionView = nil
        XCTAssertFalse(controller.isViewLoaded)
        let old = controller.collectionView!
        controller.collectionView = nil
        XCTAssertTrue(controller.isViewLoaded)
        XCTAssertNil(controller.collectionView)
        XCTAssertNil(old.superview)
        XCTAssertNil(old.dataSource)
        XCTAssertNil(old.delegate)
    }

    func testSelectionClearsOutsideCallbacksAtMeasuredAppearancePhase() {
        let oldCut = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = oldCut }
        for animated in [false, true] {
            for clears in [false, true] {
                let controller = LifecycleController(collectionViewLayout: UICollectionViewFlowLayout())
                controller.clearsSelectionOnViewWillAppear = clears
                let collection = controller.collectionView!
                collection.selectItem(at: IndexPath(item: 0, section: 0), animated: false)
                // Direct callbacks do not drive a container appearance.
                controller.viewWillAppear(animated)
                XCTAssertNotNil(collection.indexPathsForSelectedItems)
                controller.beginAppearanceTransition(true, animated: animated)
                XCTAssertTrue(controller.selectedAfterSuperWillAppear)
                XCTAssertEqual(collection.indexPathsForSelectedItems != nil, animated || !clears)
                controller.endAppearanceTransition()
                XCTAssertEqual(controller.selectedAtDidAppearEntry, !clears)
                XCTAssertEqual(collection.indexPathsForSelectedItems != nil, !clears)
                // Exercise return appearances as well as the first one.
                controller.beginAppearanceTransition(false, animated: animated)
                controller.endAppearanceTransition()
                collection.selectItem(at: IndexPath(item: 0, section: 0), animated: false)
                controller.beginAppearanceTransition(true, animated: animated)
                controller.endAppearanceTransition()
                XCTAssertEqual(collection.indexPathsForSelectedItems != nil, !clears)
            }
        }
    }

    func testControllerLazyWrapperAndPreferences() {
        let layout = UICollectionViewFlowLayout()
        let controller = ItemController(collectionViewLayout: layout)
        XCTAssertFalse(controller.isViewLoaded)
        XCTAssertTrue(controller.collectionViewLayout === layout)
        XCTAssertFalse(controller.isViewLoaded)
        XCTAssertTrue(controller.clearsSelectionOnViewWillAppear)
        XCTAssertFalse(controller.useLayoutToLayoutNavigationTransitions)
        XCTAssertTrue(controller.installsStandardGestureForInteractiveMovement)
        let collection = controller.collectionView!
        XCTAssertFalse(controller.view === collection)
        XCTAssertTrue(collection.superview === controller.view)
        XCTAssertTrue(collection.dataSource === controller)
        XCTAssertTrue(collection.delegate === controller)
        XCTAssertEqual(collection.frame, UIScreen.main.bounds)
        XCTAssertEqual(collection.autoresizingMask, [.flexibleWidth, .flexibleHeight])
        XCTAssertFalse(collection.alwaysBounceVertical)
        XCTAssertEqual(controller.numberOfSections(in: collection), 1)
        XCTAssertEqual(collection.numberOfItems(inSection: 0), 2)
        controller.view.frame.size = CGSize(width: 200, height: 300)
        controller.view.layoutIfNeeded()
        XCTAssertEqual(collection.frame, controller.view.bounds)
    }

    func testCollectionReplacementLoadsWrapperDetachesOldAndRetainsInitialLayout() {
        let layout = UICollectionViewFlowLayout()
        let controller = ItemController(collectionViewLayout: layout)
        let first = controller.collectionView!
        let next = UICollectionView(frame: CGRect(x: 1, y: 2, width: 100, height: 200), collectionViewLayout: UICollectionViewLayout())
        controller.collectionView = next
        XCTAssertNil(first.superview)
        XCTAssertNil(first.dataSource)
        XCTAssertNil(first.delegate)
        XCTAssertTrue(next.dataSource === controller)
        XCTAssertTrue(next.delegate === controller)
        XCTAssertEqual(next.frame, controller.view.bounds)
        XCTAssertTrue(controller.collectionViewLayout === layout)
        let fresh = ItemController(collectionViewLayout: UICollectionViewLayout())
        let replacement = UICollectionView()
        fresh.collectionView = replacement
        XCTAssertTrue(fresh.isViewLoaded)
        XCTAssertTrue(fresh.collectionView === replacement)
        XCTAssertTrue(replacement.superview === fresh.view)
    }
}

#if !os(Linux)
@MainActor
#endif
private final class RecordingLayout: UICollectionViewLayout {
    var contexts: [UICollectionViewLayoutInvalidationContext] = []
    override var collectionViewContentSize: CGSize { CGSize(width: 500, height: 1200) }
    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        contexts.append(context)
        super.invalidateLayout(with: context)
    }
}

#if !os(Linux)
@MainActor
#endif
private final class ItemController: UICollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 2 }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell { UICollectionViewCell() }
}

#if !os(Linux)
@MainActor
#endif
private final class LifecycleController: UICollectionViewController {
    var selectedAfterSuperWillAppear = false
    var selectedAtDidAppearEntry = false
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 2 }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell { UICollectionViewCell() }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        selectedAfterSuperWillAppear = collectionView.indexPathsForSelectedItems != nil
    }
    override func viewDidAppear(_ animated: Bool) {
        selectedAtDidAppearEntry = collectionView.indexPathsForSelectedItems != nil
        super.viewDidAppear(animated)
    }
}
