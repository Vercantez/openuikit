import XCTest
import Foundation
@testable import OpenUIKit

// Rows from Tools/oracle2/collectioncontrollerprobe/ios-26.1-iphone16.json
// (iPhone 16, iOS 26.1). Every expected value below is copied from that
// transcript; see docs/agent_reports/uicollectionviewcontroller.md.
#if !os(Linux)
@MainActor
#endif
final class CollectionViewControllerTests: XCTestCase {
    // bare: background systemBackgroundColor, translates true, bounceV false.
    // viewFirst: viewAutoresize 18, wrapperBackground nil, wrapperTranslates
    // true, collectionTranslates true, collectionBackground systemBackground.
    func testBareCollectionAndWrapperDefaults() {
        let bare = UICollectionView(frame: CGRect(x: 0, y: 0, width: 100, height: 100),
                                    collectionViewLayout: UICollectionViewFlowLayout())
        XCTAssertEqual(bare.backgroundColor, .systemBackground)
        XCTAssertTrue(bare.translatesAutoresizingMaskIntoConstraints)
        XCTAssertFalse(bare.alwaysBounceVertical)

        let controller = CountingController(collectionViewLayout: UICollectionViewFlowLayout())
        let wrapper = controller.view!
        XCTAssertEqual(wrapper.autoresizingMask, [.flexibleWidth, .flexibleHeight])
        XCTAssertNil(wrapper.backgroundColor)
        XCTAssertTrue(wrapper.translatesAutoresizingMaskIntoConstraints)
        XCTAssertEqual(controller.collectionView.backgroundColor, .systemBackground)
        XCTAssertTrue(controller.collectionView.translatesAutoresizingMaskIntoConstraints)
    }

    // lazy: afterLayoutGetter false, afterFlagSetters false.
    func testLayoutGetterAndPreferenceSettersDoNotLoadTheView() {
        let layout = UICollectionViewFlowLayout()
        let controller = CountingController(collectionViewLayout: layout)
        XCTAssertTrue(controller.collectionViewLayout === layout)
        XCTAssertFalse(controller.isViewLoaded)
        controller.clearsSelectionOnViewWillAppear = false
        controller.installsStandardGestureForInteractiveMovement = false
        controller.useLayoutToLayoutNavigationTransitions = true
        XCTAssertFalse(controller.isViewLoaded)
        XCTAssertFalse(controller.clearsSelectionOnViewWillAppear)
        XCTAssertFalse(controller.installsStandardGestureForInteractiveMovement)
        XCTAssertTrue(controller.useLayoutToLayoutNavigationTransitions)
    }

    // viewFirst: subviews ["UICollectionView"], collectionFrame == viewFrame.
    // viewDidLoad: collectionNil false, superviewIsView true, frame == viewFrame.
    func testViewAccessCreatesTheCollectionBeforeViewDidLoad() {
        let controller = CountingController(collectionViewLayout: UICollectionViewFlowLayout())
        let view = controller.view!
        XCTAssertTrue(controller.isViewLoaded)
        XCTAssertEqual(view.subviews.count, 1)
        XCTAssertTrue(view.subviews.first is UICollectionView)
        XCTAssertEqual(controller.collectionView.frame, view.frame)
        XCTAssertTrue(controller.sawCollectionInViewDidLoad)
        XCTAssertTrue(controller.collectionSuperviewWasViewInViewDidLoad)
        XCTAssertEqual(controller.collectionFrameInViewDidLoad, view.frame)
    }

    // loadView.plain: collectionNil true, subviews []. loadView.collection:
    // sameView false, collectionNil true, datasource/delegate false,
    // layoutIsOwn false, autoresize 0. loadView.subview: collectionNil true,
    // datasource false.
    func testCustomLoadViewNeverAdoptsACollectionView() {
        let initial = UICollectionViewFlowLayout()
        let plain = PlainLoadViewController(collectionViewLayout: initial)
        _ = plain.view
        XCTAssertTrue(plain.isViewLoaded)
        XCTAssertEqual(plain.view.subviews.count, 0)
        XCTAssertNil(plain.collectionView)
        XCTAssertEqual(plain.view.frame, CGRect(x: 0, y: 0, width: 50, height: 60))

        let asView = CollectionLoadViewController(collectionViewLayout: initial)
        _ = asView.view
        XCTAssertTrue(asView.view is UICollectionView)
        XCTAssertNil(asView.collectionView)
        XCTAssertNil((asView.view as? UICollectionView)?.dataSource)
        XCTAssertNil((asView.view as? UICollectionView)?.delegate)
        XCTAssertTrue(asView.collectionViewLayout === initial)
        XCTAssertEqual(asView.view.autoresizingMask, [])
        XCTAssertEqual(asView.view.frame, CGRect(x: 0, y: 0, width: 70, height: 80))

        let subview = SubviewLoadViewController(collectionViewLayout: initial)
        _ = subview.view
        XCTAssertNil(subview.collectionView)
        XCTAssertEqual(subview.view.subviews.count, 1)
        XCTAssertNil((subview.view.subviews.first as? UICollectionView)?.dataSource)
    }

    // gesture.detached: identical recognizer lists whatever the preference.
    // The in-window `_UICollectionViewLegacyReorderingGestureRecognizer` is
    // a documented gap (the port has no interactive movement); the value is
    // stored and toggling it adds nothing.
    func testInstallsStandardGestureIsStoredWithoutARecognizer() {
        let controller = CountingController(collectionViewLayout: UICollectionViewFlowLayout())
        controller.view.layoutIfNeeded()
        let before = controller.collectionView.gestureRecognizers?.count ?? 0
        controller.installsStandardGestureForInteractiveMovement = false
        XCTAssertEqual(controller.collectionView.gestureRecognizers?.count ?? 0, before)
        XCTAssertFalse(controller.installsStandardGestureForInteractiveMovement)
        controller.installsStandardGestureForInteractiveMovement = true
        XCTAssertEqual(controller.collectionView.gestureRecognizers?.count ?? 0, before)
        XCTAssertTrue(controller.installsStandardGestureForInteractiveMovement)
    }

    // Apple's class lets subclasses write `override func` for the optional
    // delegate members (Xcode template; ladder corpus: 11 didSelectItemAt,
    // 31 scrollViewDidScroll, 3 willDisplay). The overrides must be reached
    // through the collection view's dispatch, not only compile.
    func testDelegateOverridesAreDispatchedByTheCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 100)
        let controller = OverridingController(collectionViewLayout: layout)
        controller.view.frame = CGRect(x: 0, y: 0, width: 100, height: 150)
        let collection = controller.collectionView!
        collection.layoutIfNeeded()
        XCTAssertEqual(controller.displayed, [IndexPath(item: 0, section: 0), IndexPath(item: 1, section: 0)])
        guard let cell = collection.cellForItem(at: IndexPath(item: 1, section: 0)) else {
            return XCTFail("cells not tiled")
        }
        cell.touchesBegan([], with: nil)
        cell.touchesEnded([], with: nil)
        XCTAssertEqual(controller.selected, [IndexPath(item: 1, section: 0)])
        XCTAssertGreaterThan(collection.contentSize.height, collection.bounds.height)
        collection.contentOffset = CGPoint(x: 0, y: 40)
        XCTAssertEqual(controller.scrolled, 1)
    }
}

#if !os(Linux)
@MainActor
#endif
private final class OverridingController: CountingController {
    var displayed: [IndexPath] = []
    var selected: [IndexPath] = []
    var scrolled = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    }
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        displayed.append(indexPath)
    }
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selected.append(indexPath)
    }
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrolled += 1
    }
}

#if !os(Linux)
@MainActor
#endif
private class CountingController: UICollectionViewController {
    var sawCollectionInViewDidLoad = false
    var collectionSuperviewWasViewInViewDidLoad = false
    var collectionFrameInViewDidLoad = CGRect.null
    override func viewDidLoad() {
        super.viewDidLoad()
        sawCollectionInViewDidLoad = collectionView != nil
        collectionSuperviewWasViewInViewDidLoad = collectionView?.superview === view
        collectionFrameInViewDidLoad = collectionView?.frame ?? .null
    }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 2 }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell { UICollectionViewCell() }
}

#if !os(Linux)
@MainActor
#endif
private final class PlainLoadViewController: CountingController {
    override func loadView() { view = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 60)) }
}

#if !os(Linux)
@MainActor
#endif
private final class CollectionLoadViewController: CountingController {
    let own = UICollectionViewFlowLayout()
    override func loadView() {
        view = UICollectionView(frame: CGRect(x: 0, y: 0, width: 70, height: 80), collectionViewLayout: own)
    }
}

#if !os(Linux)
@MainActor
#endif
private final class SubviewLoadViewController: CountingController {
    override func loadView() {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 60))
        host.addSubview(UICollectionView(frame: host.bounds, collectionViewLayout: UICollectionViewFlowLayout()))
        view = host
    }
}
