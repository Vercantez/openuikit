import XCTest
@testable import OpenUIKit

// UIViewController.init?(coder:) and the required initializers it forces
// on the port's container subclasses. Every expected value is a row of
// Tools/oracle2/viewcontrollercoderprobe/ios-26.1-iphone16.json (iPhone 16,
// iOS 26.1) measured on an EMPTY keyed archive; the port has no archive
// reader, so the coder handed in here is a bare `NSCoder()` and is never
// consulted. Rows that Apple round-trips (title, restorationIdentifier)
// are documented as limits, not asserted.
#if !os(Linux)
@MainActor
#endif
final class ViewControllerCoderTests: XCTestCase {

    // base.coder: nonNil, loadedBefore false, viewIfLoadedNil true,
    // nibName nil, nibBundleIsMain true, title nil.
    func testEmptyArchiveBaseIsNonNilUnloadedWithNilNibAndTitle() throws {
        let vc = try XCTUnwrap(UIViewController(coder: NSCoder()))
        XCTAssertFalse(vc.isViewLoaded)
        XCTAssertNil(vc.viewIfLoaded)
        XCTAssertNil(vc.nibName)
        XCTAssertTrue(vc.nibBundle === Bundle.main)
        XCTAssertNil(vc.title)
    }

    // base.coder vs base.programmatic / base.nilnil: identical rows. The
    // first `view` access loads a plain UIView (viewClass "UIView",
    // viewBackground nil, viewSubviews 0, loadedAfter true) exactly as the
    // nil/nil initializer does; the frame is compared to the programmatic
    // controller because the port's default loadView frame is its own.
    func testEmptyArchiveBaseLoadsTheSameViewAsProgrammaticInit() throws {
        let coded = try XCTUnwrap(UIViewController(coder: NSCoder()))
        let programmatic = UIViewController(nibName: nil, bundle: nil)
        let codedView = try XCTUnwrap(coded.view)
        let plainView = try XCTUnwrap(programmatic.view)
        XCTAssertTrue(coded.isViewLoaded)
        XCTAssertTrue(type(of: codedView) == UIView.self)
        XCTAssertNil(codedView.backgroundColor)
        XCTAssertEqual(codedView.subviews.count, 0)
        XCTAssertEqual(codedView.frame, plainView.frame)
        XCTAssertEqual(codedView.autoresizingMask, plainView.autoresizingMask)
        XCTAssertEqual(coded.nibName, programmatic.nibName)
        XCTAssertTrue(coded.nibBundle === programmatic.nibBundle)
    }

    // subclass.coder: a subclass with its own designated initializer plus
    // `required init?(coder:)` chaining to super keeps the state it set
    // before chaining (frame [1,2,3,4]), is non-nil, unloaded, title nil,
    // and viewDidLoad runs once, only on the first view access.
    func testSubclassDesignatedInitPlusRequiredCoderChainsToBase() throws {
        let vc = try XCTUnwrap(FramedController(coder: NSCoder()))
        XCTAssertEqual(vc.frame, CGRect(x: 1, y: 2, width: 3, height: 4))
        XCTAssertFalse(vc.isViewLoaded)
        XCTAssertNil(vc.title)
        XCTAssertNil(vc.nibName)
        XCTAssertEqual(vc.loadCount, 0)
        _ = vc.view
        XCTAssertTrue(vc.isViewLoaded)
        XCTAssertEqual(vc.loadCount, 1)
        // subclass.titled.coder: the coder path never runs the programmatic
        // initializer's body, so a title set there stays nil.
        let titled = try XCTUnwrap(TitledController(coder: NSCoder()))
        XCTAssertNil(titled.title)
        XCTAssertEqual(TitledController(frame: .zero).title, "programmatic")
    }

    // table.coder: nonNil, loadedBefore false, style 0 (plain),
    // tableIsView true, viewClass "UITableView", title nil.
    func testTableViewControllerCoderIsPlainStyleAndUnloaded() throws {
        let vc = try XCTUnwrap(UITableViewController(coder: NSCoder()))
        XCTAssertFalse(vc.isViewLoaded)
        XCTAssertNil(vc.title)
        XCTAssertNil(vc.nibName)
        XCTAssertEqual(vc.tableView.style, .plain)
        XCTAssertTrue(vc.tableView === vc.view)
        XCTAssertTrue(vc.isViewLoaded)
    }

    // collection.coder: nonNil, loadedBefore false, nibName nil, title nil
    // (layoutNil is asserted by CollectionViewControllerCoderTests).
    func testCollectionViewControllerCoderChainsToBase() throws {
        let vc = try XCTUnwrap(UICollectionViewController(coder: NSCoder()))
        XCTAssertFalse(vc.isViewLoaded)
        XCTAssertNil(vc.nibName)
        XCTAssertNil(vc.title)
        XCTAssertTrue(vc.nibBundle === Bundle.main)
    }

    // navigation.coder: viewControllers 0, isNavigationBarHidden false,
    // unloaded. tab.coder: viewControllersNil true, unloaded.
    // split.coder: style 0 (unspecified), viewControllers 0.
    // page.coder: viewControllersNil false, transitionStyle 0,
    // orientation 0. search.coder: resultsNil true, unloaded.
    func testContainerControllersCoderMatchEmptyArchiveRows() throws {
        let nav = try XCTUnwrap(UINavigationController(coder: NSCoder()))
        XCTAssertFalse(nav.isViewLoaded)
        XCTAssertEqual(nav.viewControllers.count, 0)
        XCTAssertFalse(nav.isNavigationBarHidden)

        let tab = try XCTUnwrap(UITabBarController(coder: NSCoder()))
        XCTAssertFalse(tab.isViewLoaded)
        XCTAssertNil(tab.viewControllers)

        let split = try XCTUnwrap(UISplitViewController(coder: NSCoder()))
        XCTAssertFalse(split.isViewLoaded)
        XCTAssertEqual(split.style, .unspecified)
        XCTAssertEqual(split.viewControllers.count, 0)

        let page = try XCTUnwrap(UIPageViewController(coder: NSCoder()))
        XCTAssertFalse(page.isViewLoaded)
        XCTAssertNotNil(page.viewControllers)
        XCTAssertEqual(page.transitionStyle.rawValue, 0)
        XCTAssertEqual(page.navigationOrientation.rawValue, 0)

        let search = try XCTUnwrap(UISearchController(coder: NSCoder()))
        XCTAssertFalse(search.isViewLoaded)
        XCTAssertNil(search.searchResultsController)
    }

    // alert.coder: nonNil, unloaded, title nil, message nil, actions 0,
    // style 0 = actionSheet (NOT the `.alert` the port stores by default).
    func testAlertControllerCoderIsAnEmptyActionSheet() throws {
        let alert = try XCTUnwrap(UIAlertController(coder: NSCoder()))
        XCTAssertFalse(alert.isViewLoaded)
        XCTAssertNil(alert.title)
        XCTAssertNil(alert.message)
        XCTAssertEqual(alert.actions.count, 0)
        XCTAssertEqual(alert.preferredStyle, .actionSheet)
        XCTAssertEqual(alert.preferredStyle.rawValue, 0)
    }
}

/// The probe's FramedController: one designated initializer of its own
/// plus the required coder initializer chaining up.
private class FramedController: UIViewController {
    let frame: CGRect
    var loadCount = 0
    init(frame: CGRect) {
        self.frame = frame
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        frame = CGRect(x: 1, y: 2, width: 3, height: 4)
        super.init(coder: coder)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        loadCount += 1
    }
}

private final class TitledController: FramedController {
    override init(frame: CGRect) {
        super.init(frame: frame)
        title = "programmatic"
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
