import XCTest
import Foundation
@testable import OpenUIKit

// coder.* rows from Tools/oracle2/collectioncontrollerprobe (iPhone 16,
// iOS 26.1) plus the ios-oss RewardsCollectionViewController source shape
// that the app ladder's single blocking use compiles against.
#if !os(Linux)
@MainActor
#endif
final class CollectionViewControllerCoderTests: XCTestCase {
    // coder.empty: nonNil, loaded false, clear true, install true,
    // transitions false, layoutNil true. The port substitutes a flow layout
    // when the view loads (documented convention shared with
    // UICollectionView.init?(coder:)); identity is stable across reads.
    func testCoderInitialisationIsUnloadedWithDefaultPreferences() throws {
        let controller = try XCTUnwrap(UICollectionViewController(coder: NSCoder()))
        XCTAssertFalse(controller.isViewLoaded)
        XCTAssertTrue(controller.clearsSelectionOnViewWillAppear)
        XCTAssertTrue(controller.installsStandardGestureForInteractiveMovement)
        XCTAssertFalse(controller.useLayoutToLayoutNavigationTransitions)
        let fallback = controller.collectionViewLayout
        XCTAssertTrue(fallback is UICollectionViewFlowLayout)
        XCTAssertFalse(controller.isViewLoaded)
        XCTAssertTrue(controller.collectionViewLayout === fallback)
        let collection = try XCTUnwrap(RewardsShapedController(coder: NSCoder())?.collectionView)
        XCTAssertTrue(collection.collectionViewLayout is UICollectionViewFlowLayout)
        XCTAssertEqual(collection.frame, UIScreen.main.bounds)
    }

    // ios-oss: `init() { super.init(collectionViewLayout: self.layout) }` and
    // `required init?(coder:) { super.init(coder:) }` on the same subclass.
    func testRewardsShapedSubclassChainsBothInitializers() throws {
        let programmatic = RewardsShapedController()
        XCTAssertTrue(programmatic.collectionViewLayout === programmatic.layout)
        XCTAssertFalse(programmatic.isViewLoaded)
        XCTAssertTrue(programmatic.collectionView.collectionViewLayout === programmatic.layout)
        XCTAssertTrue(programmatic.flowLayout === programmatic.layout)

        let decoded = try XCTUnwrap(RewardsShapedController(coder: NSCoder()))
        XCTAssertFalse(decoded.isViewLoaded)
        XCTAssertFalse(decoded.collectionViewLayout === decoded.layout)
        XCTAssertNotNil(decoded.flowLayout)
    }

    // ios-oss calls flashScrollIndicators() after every reload. No readable
    // state changes; an empty collection has no scrollable axis so no bar
    // is created.
    func testFlashScrollIndicatorsIsCallableWithoutSideEffects() {
        let controller = RewardsShapedController()
        let collection = controller.collectionView!
        collection.layoutIfNeeded()
        let subviews = collection.subviews.count
        collection.flashScrollIndicators()
        XCTAssertEqual(collection.subviews.count, subviews)
        XCTAssertEqual(collection.contentOffset, .zero)
    }
}

#if !os(Linux)
@MainActor
#endif
private final class RewardsShapedController: UICollectionViewController {
    let layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 3
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        return layout
    }()

    var flowLayout: UICollectionViewFlowLayout? {
        collectionView.collectionViewLayout as? UICollectionViewFlowLayout
    }

    init() {
        super.init(collectionViewLayout: self.layout)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 0 }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell { UICollectionViewCell() }
}
