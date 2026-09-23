import XCTest
@testable import OpenUIKit

/// NetNewsWire's Feeds toolbar on the iOS 26 cut. MEASURED iPhone 16 /
/// iOS 26.1: Tools/oracle2/toolbaritemsprobe (item frames, symbol
/// configuration), Tools/oracle2/toolbaredgeprobe (the automatic bottom
/// material), Tools/oracle2/listheaderprobe ROWS=10 (safe area of scrolled
/// content).
#if !os(Linux)
@MainActor
#endif
final class ToolbarItemsTests: XCTestCase {
    private var saved: (FontEngine.SystemFontCut, UIUserInterfaceIdiom, UITraitCollection, CGRect, CGFloat)!
    private var savedImageScale: CGFloat = 0
    private var savedResourceRoot = ""

    override func setUp() {
        super.setUp()
        saved = (OpenUIKitRuntime.systemFontCut, UIDevice.current.userInterfaceIdiom,
                 UITraitCollection.current, UIScreen.main.bounds, UIScreen.main.scale)
        savedImageScale = OpenUIKitRuntime.imageScreenScale
        savedResourceRoot = OpenUIKitRuntime.resourceRoot
        OpenUIKitRuntime.imageScreenScale = 3
        OpenUIKitRuntime.resourceRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/OpenUIKit/Resources").path
        OpenUIKitRuntime.systemFontCut = .iOS
        UIDevice.current.userInterfaceIdiom = .phone
        UIScreen.main._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 393, height: 852), scale: 3)
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light, displayScale: 3,
                                                      preferredContentSizeCategory: .large,
                                                      userInterfaceIdiom: .phone)
    }

    override func tearDown() {
        OpenUIKitRuntime.systemFontCut = saved.0
        OpenUIKitRuntime.imageScreenScale = savedImageScale
        OpenUIKitRuntime.resourceRoot = savedResourceRoot
        UIDevice.current.userInterfaceIdiom = saved.1
        UITraitCollection.current = saved.2
        UIScreen.main._hostConfigure(bounds: saved.3, scale: saved.4)
        super.tearDown()
    }

    /// A window-hosted navigation controller with the toolbar shown.
    private func makeNav(root: UIViewController, items: [UIBarButtonItem]) -> (UIWindow, UINavigationController) {
        root.toolbarItems = items
        let nav = UINavigationController(rootViewController: root)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window._setSafeAreaInsets(UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0))
        window.rootViewController = nav
        window.makeKeyAndVisible()
        nav.setToolbarHidden(false, animated: false)
        for _ in 0..<3 { window.layoutIfNeeded() }
        return (window, nav)
    }

    private func feedsItems() -> [UIBarButtonItem] {
        let settings = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: nil, action: nil)
        settings.title = "Settings"
        let activity = UIBarButtonItem(image: UIImage(systemName: "text.pad.header"), style: .plain,
                                       target: nil, action: nil)
        let add = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: nil, action: nil)
        add.title = "Add"
        return [settings, activity, .flexibleSpace(), add]
    }

    /// toolbaritemsprobe VARIANT=A: the titled "gear" and the "text.pad.header"
    /// item share one glass platter [28, 776, 106.67, 48]; item views
    /// [28, 776, 51.67, 48] and [83.67, 776, 51, 48]; Add [317, 776, 48, 48].
    /// Every image view shows the symbol at body/medium/large — gear
    /// [40, 786.33, 27.67, 27.67], text.pad.header [95.67, 788.33, 27, 24],
    /// plus [329.33, 789.33, 23.33, 22] — and no title is drawn.
    func testTitledSymbolItemsDrawOnlyTheirImageAndShareAPlatter() throws {
        let (window, nav) = makeNav(root: UIViewController(), items: feedsItems())
        defer { window.isHidden = true }
        let views = nav.toolbar.itemViews
        func frame(_ v: UIView) -> CGRect { v.convert(v.bounds, to: window) }
        func near(_ a: CGRect, _ b: CGRect, _ what: String) {
            for (x, y) in [(a.minX, b.minX), (a.minY, b.minY), (a.width, b.width), (a.height, b.height)] {
                XCTAssertEqual(x, y, accuracy: 0.01, "\(what): \(a) vs \(b)")
            }
        }
        near(frame(views[0]), CGRect(x: 28, y: 776, width: 51.667, height: 48), "settings")
        near(frame(views[1]), CGRect(x: 83.667, y: 776, width: 51, height: 48), "activity")
        near(frame(views[3]), CGRect(x: 317, y: 776, width: 48, height: 48), "add")
        let shared = try XCTUnwrap(nav.toolbar.sharedPlatterViews.first)
        XCTAssertEqual(nav.toolbar.sharedPlatterViews.count, 1)
        near(frame(shared), CGRect(x: 28, y: 776, width: 106.667, height: 48), "shared platter")
        near(frame(views[0].imageView), CGRect(x: 40, y: 786.333, width: 27.667, height: 27.667), "gear")
        near(frame(views[1].imageView), CGRect(x: 95.667, y: 788.333, width: 27, height: 24), "text.pad.header")
        near(frame(views[3].imageView), CGRect(x: 329.333, y: 789.333, width: 23.333, height: 22), "plus")
        XCTAssertTrue(views[0].titleLabel.isHidden)
        XCTAssertTrue(views[3].titleLabel.isHidden)
    }

    /// VARIANT=B: a title-only item ("Edit") still draws its title.
    func testTitleOnlyItemKeepsItsTitle() {
        let edit = UIBarButtonItem(title: "Edit", style: .plain, target: nil, action: nil)
        let (window, nav) = makeNav(root: UIViewController(), items: [edit, .flexibleSpace()])
        defer { window.isHidden = true }
        XCTAssertFalse(nav.toolbar.itemViews[0].titleLabel.isHidden)
        XCTAssertEqual(nav.toolbar.itemViews[0].titleLabel.text, "Edit")
    }

    /// The navigation bar's titled "line.3.horizontal.decrease" (NetNewsWire's
    /// filter button) draws the symbol only, [341.33, 72.67, 27.33, 17] in
    /// its 44 pt platter at [333, 59].
    func testNavigationBarTitledSymbolItemDrawsOnlyTheImage() throws {
        let root = UIViewController()
        root.title = "Feeds"
        let filter = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease"), style: .plain,
                                     target: nil, action: nil)
        filter.title = "Filter"
        root.navigationItem.rightBarButtonItem = filter
        let (window, nav) = makeNav(root: root, items: feedsItems())
        defer { window.isHidden = true }
        let view = try XCTUnwrap(nav.navigationBar.rightItemViews.first)
        XCTAssertTrue(view.titleLabel.isHidden)
        let f = view.imageView.convert(view.imageView.bounds, to: view)
        XCTAssertEqual(f.minX, 8.333, accuracy: 0.01)
        XCTAssertEqual(f.minY, 13.667, accuracy: 0.01)
        XCTAssertEqual(f.width, 27.333, accuracy: 0.01)
        XCTAssertEqual(f.height, 17, accuracy: 0.01)
    }

    /// toolbaredgeprobe: at rest, content running under the toolbar gets the
    /// automatic material [0, 711.2, 393, 140.8]: out = in·(1 − a) + 0.98·B·a
    /// with B the scroll view's background. Over a white backdrop a black
    /// column reads 204 at y 831 (a 0.814) and 123 at 791 (a 0.51); rows
    /// above y 726 are untouched.
    func testAutomaticToolbarMaterialBlendsTowardTheScrollViewBackground() throws {
        final class Root: UIViewController {
            let scroll = UIScrollView()
            override func loadView() { view = scroll }
        }
        let root = Root()
        root.scroll.backgroundColor = .white
        root.scroll.contentSize = CGSize(width: 393, height: 2400)
        let black = UIView(frame: CGRect(x: 230, y: 0, width: 20, height: 2400))
        black.backgroundColor = .black
        root.scroll.addSubview(black)
        let (window, _) = makeNav(root: root, items: feedsItems())
        defer { window.isHidden = true }
        root.scroll.layoutIfNeeded()
        let material = try XCTUnwrap(root.scroll._bottomToolbarMaterial)
        XCTAssertFalse(material.isHidden)
        let f = material.convert(material.bounds, to: window)
        // [0, 711.2, 393, 140.8], snapped to the pixel row the table starts on
        XCTAssertEqual(f.minY, 711.333, accuracy: 0.01)
        XCTAssertEqual(f.maxY, 852, accuracy: 0.01)
        XCTAssertEqual(f.width, 393)
        XCTAssertEqual(_UIScrollEdgeToolbarMaterialView.alpha(at: 831.333 - 711.2), 0.814, accuracy: 0.005)

        let bitmap = UIRenderer.render(window, scale: 3)
        func gray(_ x: CGFloat, _ y: CGFloat) -> Int {
            Int(bitmap.pixels[(Int(y * 3) * bitmap.width + Int(x * 3)) * 4])
        }
        XCTAssertEqual(gray(240, 700), 0)
        XCTAssertEqual(gray(240, 831.333), 204, accuracy: 3)
        XCTAssertEqual(gray(240, 791.333), 123, accuracy: 3)

        // An explicit `.hard` or hidden bottom effect removes it.
        root.scroll.bottomEdgeEffect.isHidden = true
        root.scroll.layoutIfNeeded()
        XCTAssertTrue(material.isHidden)
    }

    /// listheaderprobe ROWS=10: a list cell scrolled under the 34 pt
    /// home-indicator inset reads safeAreaInsets 0 (cell and content view),
    /// while the collection view's own are [59, 0, 34, 0].
    func testScrolledContentGetsNoVerticalSafeArea() {
        let cv = UIScrollView(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let window = UIWindow(frame: cv.frame)
        window._setSafeAreaInsets(UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0))
        window.addSubview(cv)
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        cv.contentSize = CGSize(width: 393, height: 2000)
        let underBottom = UIView(frame: CGRect(x: 16, y: 800, width: 361, height: 50.33))
        let underTop = UIView(frame: CGRect(x: 16, y: 0, width: 361, height: 50.33))
        cv.addSubview(underBottom)
        cv.addSubview(underTop)
        window.layoutIfNeeded()
        XCTAssertEqual(cv.safeAreaInsets, UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0))
        XCTAssertEqual(underBottom.safeAreaInsets, .zero)
        XCTAssertEqual(underTop.safeAreaInsets, .zero)
    }
}
