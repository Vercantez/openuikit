// UIPageViewController compatibility and containment behavior. Public raw
// values, defaults, hierarchy shape, callback order, and completion timing
// are pinned from the real iOS 26.1 probe described in docs/KNOWN_GAPS.md.
import XCTest
@testable import OpenUIKit

@MainActor
private final class PageLog {
    var entries: [String] = []
}

@MainActor
private final class PageChild: UIViewController {
    let name: String
    let log: PageLog

    init(_ name: String, log: PageLog) {
        self.name = name
        self.log = log
        super.init()
    }

    override func loadView() {
        log.entries.append("\(name).loadView")
        view = UIView()
    }

    override func viewDidLoad() { log.entries.append("\(name).viewDidLoad") }
    override func willMove(toParent parent: UIViewController?) {
        log.entries.append("\(name).willMove:\(parent == nil ? "nil" : "page")")
    }
    override func didMove(toParent parent: UIViewController?) {
        log.entries.append("\(name).didMove:\(parent == nil ? "nil" : "page")")
    }
    override func viewWillAppear(_ animated: Bool) {
        log.entries.append("\(name).willAppear:\(animated)")
    }
    override func viewDidAppear(_ animated: Bool) {
        log.entries.append("\(name).didAppear:\(animated)")
    }
    override func viewWillDisappear(_ animated: Bool) {
        log.entries.append("\(name).willDisappear:\(animated)")
    }
    override func viewDidDisappear(_ animated: Bool) {
        log.entries.append("\(name).didDisappear:\(animated)")
    }
}

@MainActor
private final class PageSource: UIPageViewControllerDataSource {
    let pages: [UIViewController]
    var count: Int
    var index: Int
    var queries: [String] = []
    var presentationQueries: [String] = []
    let eventLog: PageLog?

    init(_ pages: [UIViewController], count: Int, index: Int,
         eventLog: PageLog? = nil) {
        self.pages = pages
        self.count = count
        self.index = index
        self.eventLog = eventLog
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController)
        -> UIViewController? {
        queries.append("before")
        guard let i = pages.firstIndex(where: { $0 === viewController }), i > 0 else {
            return nil
        }
        return pages[i - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController)
        -> UIViewController? {
        queries.append("after")
        guard let i = pages.firstIndex(where: { $0 === viewController }),
              i + 1 < pages.count else { return nil }
        return pages[i + 1]
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        presentationQueries.append("count")
        eventLog?.entries.append("source.count")
        return count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        presentationQueries.append("index")
        eventLog?.entries.append("source.index")
        return index
    }
}

@MainActor
private final class PageDelegate: UIPageViewControllerDelegate {
    var entries: [String] = []
    func pageViewController(_ pageViewController: UIPageViewController,
                            willTransitionTo pendingViewControllers: [UIViewController]) {
        entries.append("will:\(pendingViewControllers.count)")
    }
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        entries.append("did:\(finished):\(previousViewControllers.count):\(completed)")
    }
}

@MainActor
private final class OverridingPageViewController: UIPageViewController {
    private weak var overriddenDelegate: UIPageViewControllerDelegate?
    private weak var overriddenDataSource: UIPageViewControllerDataSource?
    private var overriddenDoubleSided = false
    let overriddenChild = UIViewController()
    let overriddenGesture = UITapGestureRecognizer()

    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    override var delegate: UIPageViewControllerDelegate? {
        get { overriddenDelegate }
        set { overriddenDelegate = newValue }
    }
    override var dataSource: UIPageViewControllerDataSource? {
        get { overriddenDataSource }
        set { overriddenDataSource = newValue }
    }
    override var transitionStyle: UIPageViewController.TransitionStyle { .pageCurl }
    override var navigationOrientation: UIPageViewController.NavigationOrientation { .vertical }
    override var spineLocation: UIPageViewController.SpineLocation { .max }
    override var isDoubleSided: Bool {
        get { overriddenDoubleSided }
        set { overriddenDoubleSided = newValue }
    }
    override var viewControllers: [UIViewController]? { [overriddenChild] }
    override var gestureRecognizers: [UIGestureRecognizer] { [overriddenGesture] }

    // UIKit's superclass does not expose UIScrollViewDelegate methods. This
    // deliberately has no `override`; it must remain an independent app hook.
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        _ = scrollView
    }
}

@MainActor
final class UIPageViewControllerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        OpenUIKitRuntime.animationTime = 0
        UIViewAnimationCompletionQueue.entries.removeAll()
    }

    override func tearDown() {
        OpenUIKitRuntime.animationTime = 0
        UIViewAnimationCompletionQueue.entries.removeAll()
        super.tearDown()
    }

    func testRawValuesOptionKeysAndFreshDefaultsMatchUIKit26() {
        XCTAssertEqual(UIPageViewController.NavigationOrientation.horizontal.rawValue, 0)
        XCTAssertEqual(UIPageViewController.NavigationOrientation.vertical.rawValue, 1)
        XCTAssertEqual(UIPageViewController.NavigationDirection.forward.rawValue, 0)
        XCTAssertEqual(UIPageViewController.NavigationDirection.reverse.rawValue, 1)
        XCTAssertEqual(UIPageViewController.TransitionStyle.pageCurl.rawValue, 0)
        XCTAssertEqual(UIPageViewController.TransitionStyle.scroll.rawValue, 1)
        XCTAssertEqual(UIPageViewController.SpineLocation.none.rawValue, 0)
        XCTAssertEqual(UIPageViewController.SpineLocation.min.rawValue, 1)
        XCTAssertEqual(UIPageViewController.SpineLocation.mid.rawValue, 2)
        XCTAssertEqual(UIPageViewController.SpineLocation.max.rawValue, 3)
        XCTAssertEqual(UIPageViewController.OptionsKey.spineLocation.rawValue,
                       "UIPageViewControllerOptionSpineLocationKey")
        XCTAssertEqual(UIPageViewController.OptionsKey.interPageSpacing.rawValue,
                       "UIPageViewControllerOptionInterPageSpacingKey")

        let page = UIPageViewController(transitionStyle: .scroll,
                                        navigationOrientation: .horizontal)
        XCTAssertEqual(page.transitionStyle, .scroll)
        XCTAssertEqual(page.navigationOrientation, .horizontal)
        XCTAssertEqual(page.spineLocation, .none)
        XCTAssertFalse(page.isDoubleSided)
        XCTAssertEqual(page.viewControllers?.count, 0)
        XCTAssertFalse(page.isViewLoaded)
        XCTAssertTrue(page.gestureRecognizers.isEmpty)
        XCTAssertFalse(page.isViewLoaded, "reading scroll gestures stays lazy")

        let curl = UIPageViewController(
            transitionStyle: .pageCurl, navigationOrientation: .horizontal,
            options: [.spineLocation: UIPageViewController.SpineLocation.mid.rawValue])
        XCTAssertEqual(curl.spineLocation, .mid)
        XCTAssertTrue(curl.isDoubleSided)
        XCTAssertEqual(curl.gestureRecognizers.count, 2)
        XCTAssertTrue(curl.gestureRecognizers[0] is UIPanGestureRecognizer)
        XCTAssertTrue(curl.gestureRecognizers[1] is UITapGestureRecognizer)
        XCTAssertFalse(curl.isViewLoaded, "curl recognizers are also created lazily off-view")
    }

    func testDoubleSidedPropertyPreservesMidSpineInvariant() {
        let scroll = UIPageViewController(transitionStyle: .scroll,
                                          navigationOrientation: .horizontal)
        XCTAssertFalse(scroll.isDoubleSided)
        scroll.isDoubleSided = true
        XCTAssertTrue(scroll.isDoubleSided)
        scroll.isDoubleSided = false
        XCTAssertFalse(scroll.isDoubleSided)

        let curl = UIPageViewController(transitionStyle: .pageCurl,
                                        navigationOrientation: .horizontal)
        XCTAssertEqual(curl.spineLocation, .min)
        XCTAssertFalse(curl.isDoubleSided)
        curl.isDoubleSided = true
        XCTAssertTrue(curl.isDoubleSided)
        curl.isDoubleSided = false
        XCTAssertFalse(curl.isDoubleSided)

        let mid = UIPageViewController(
            transitionStyle: .pageCurl, navigationOrientation: .horizontal,
            options: [.spineLocation: UIPageViewController.SpineLocation.mid.rawValue])
        XCTAssertEqual(mid.spineLocation, .mid)
        XCTAssertTrue(mid.isDoubleSided)
        mid.isDoubleSided = true
        XCTAssertTrue(mid.isDoubleSided)
        // Setting this mid-spine instance to false intentionally exercises a
        // precondition failure, so the crashing branch is documented rather
        // than invoked inside the shared XCTest process.
    }

    func testHorizontalDataSourceCreatesDirectPageControlAndMeasuredLayout() {
        let log = PageLog()
        let child = PageChild("a", log: log)
        let source = PageSource([child], count: 3, index: 1)
        let page = UIPageViewController(
            transitionStyle: .scroll, navigationOrientation: .horizontal,
            options: [.interPageSpacing: 12.0])
        page.dataSource = source
        page.view.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
        page.view.layoutIfNeeded()

        XCTAssertEqual(page.view.subviews.count, 2)
        guard let control = page.view.subviews[0] as? UIPageControl else {
            return XCTFail("page control must be a direct first child for Focus's lookup")
        }
        XCTAssertTrue(page.view.subviews[1] === page.scrollView)
        XCTAssertEqual(control.numberOfPages, 3)
        XCTAssertEqual(control.currentPage, 1)
        XCTAssertEqual(control.frame.height, 26, accuracy: 1e-9)
        XCTAssertEqual(control.frame.maxY, 480, accuracy: 1e-9)
        assertRectEqual(page.scrollView.frame,
                        CGRect(x: -6, y: 0, width: 332, height: 454),
                        accuracy: 1e-9)

        var completion: Bool?
        page.setViewControllers([child], direction: .forward, animated: true) {
            completion = $0
        }
        XCTAssertEqual(completion, true,
                       "an animated first install has no transition and completes inline")
        XCTAssertTrue(child.parent === page)
        XCTAssertEqual(page.children.count, 1)
        XCTAssertTrue(page.viewControllers?.first === child)
        XCTAssertEqual(child.view.frame, CGRect(x: 0, y: 0, width: 320, height: 454))
        XCTAssertEqual(log.entries, [
            "a.willMove:page", "a.didMove:page", "a.loadView", "a.viewDidLoad",
        ])
        XCTAssertTrue(source.queries.isEmpty,
                      "programmatic installs do not ask for neighboring pages")
    }

    func testPageControlDoesNotReserveSpaceAtCountZeroAndVerticalHasNone() {
        let child = UIViewController()
        let zeroSource = PageSource([child], count: 0, index: 0)
        let horizontal = UIPageViewController(transitionStyle: .scroll,
                                              navigationOrientation: .horizontal)
        horizontal.dataSource = zeroSource
        horizontal.view.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
        horizontal.view.layoutIfNeeded()
        let control = horizontal.view.subviews.compactMap { $0 as? UIPageControl }.first
        XCTAssertNotNil(control, "both optional methods produce UIKit's zero-sized control")
        XCTAssertEqual(control?.frame.size, .zero)
        XCTAssertEqual(horizontal.scrollView.frame, horizontal.view.bounds)

        let verticalSource = PageSource([child], count: 3, index: 0)
        let vertical = UIPageViewController(transitionStyle: .scroll,
                                            navigationOrientation: .vertical)
        vertical.dataSource = verticalSource
        _ = vertical.view
        XCTAssertFalse(vertical.view.subviews.contains { $0 is UIPageControl })
    }

    func testHorizontalSwipeQueriesNeighborAndCompletesThroughScrollPhysics() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let log = PageLog()
        let a = PageChild("a", log: log)
        let b = PageChild("b", log: log)
        let source = PageSource([a, b], count: 2, index: 0)
        let delegate = PageDelegate()
        let page = UIPageViewController(transitionStyle: .scroll,
                                        navigationOrientation: .horizontal)
        page.dataSource = source
        page.delegate = delegate
        page.view.frame = window.bounds
        window.addSubview(page.view)
        window.makeKeyAndVisible()
        page.setViewControllers([a], direction: .forward, animated: false)
        window.layoutIfNeeded()
        source.queries.removeAll()
        log.entries.removeAll()

        window.sendTouch(.began, at: CGPoint(x: 280, y: 200), timestamp: 0)
        window.sendTouch(.moved, at: CGPoint(x: 250, y: 200), timestamp: 0.02)
        window.sendTouch(.moved, at: CGPoint(x: 70, y: 200), timestamp: 0.10)
        window.sendTouch(.ended, at: CGPoint(x: 40, y: 200), timestamp: 0.11)

        XCTAssertTrue(page.children.contains { $0 === b })
        XCTAssertEqual(source.queries, ["after"])
        XCTAssertEqual(delegate.entries, ["will:1"])
        window.tick(timestamp: 2)

        XCTAssertTrue(page.viewControllers?.first === b)
        XCTAssertEqual(page.children.count, 1)
        XCTAssertTrue(page.children.first === b)
        XCTAssertEqual(delegate.entries, ["will:1", "did:true:1:true"])
        let control = page.view.subviews.compactMap { $0 as? UIPageControl }.first
        XCTAssertEqual(control?.currentPage, 1)
    }

    func testHorizontalSwipeReversedPastCenterCancelsStagedForwardPage() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let a = UIViewController()
        let b = UIViewController()
        let source = PageSource([a, b], count: 2, index: 0)
        let delegate = PageDelegate()
        let page = UIPageViewController(transitionStyle: .scroll,
                                        navigationOrientation: .horizontal)
        page.dataSource = source
        page.delegate = delegate
        page.view.frame = window.bounds
        window.addSubview(page.view)
        window.makeKeyAndVisible()
        page.setViewControllers([a], direction: .forward, animated: false)
        window.layoutIfNeeded()
        source.queries.removeAll()

        window.sendTouch(.began, at: CGPoint(x: 60, y: 200), timestamp: 0)
        window.sendTouch(.moved, at: CGPoint(x: 20, y: 200), timestamp: 0.02)
        XCTAssertTrue(page.children.contains { $0 === b },
                      "the first leftward movement stages the forward page")
        window.sendTouch(.moved, at: CGPoint(x: 0, y: 200), timestamp: 0.10)
        window.sendTouch(.moved, at: CGPoint(x: 300, y: 200), timestamp: 0.20)
        window.sendTouch(.ended, at: CGPoint(x: 300, y: 200), timestamp: 0.21)

        XCTAssertEqual(source.queries, ["after"])
        XCTAssertEqual(delegate.entries, ["will:1"])
        window.tick(timestamp: 3)

        XCTAssertTrue(page.viewControllers?.first === a)
        XCTAssertEqual(page.children.count, 1)
        XCTAssertTrue(page.children.first === a)
        XCTAssertNil(b.parent)
        XCTAssertEqual(delegate.entries, ["will:1", "did:true:1:false"])
        let control = page.view.subviews.compactMap { $0 as? UIPageControl }.first
        XCTAssertEqual(control?.currentPage, 0)
    }

    func testVerticalReverseSwipeUsesSignedDistanceAndCompletes() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let before = UIViewController()
        let current = UIViewController()
        let source = PageSource([before, current], count: 2, index: 1)
        let delegate = PageDelegate()
        let page = UIPageViewController(transitionStyle: .scroll,
                                        navigationOrientation: .vertical)
        page.dataSource = source
        page.delegate = delegate
        page.view.frame = window.bounds
        window.addSubview(page.view)
        window.makeKeyAndVisible()
        page.setViewControllers([current], direction: .forward, animated: false)
        window.layoutIfNeeded()
        source.queries.removeAll()

        window.sendTouch(.began, at: CGPoint(x: 160, y: 100), timestamp: 0)
        window.sendTouch(.moved, at: CGPoint(x: 160, y: 130), timestamp: 0.02)
        window.sendTouch(.moved, at: CGPoint(x: 160, y: 400), timestamp: 0.12)
        window.sendTouch(.ended, at: CGPoint(x: 160, y: 400), timestamp: 0.13)

        XCTAssertEqual(source.queries, ["before"])
        XCTAssertEqual(delegate.entries, ["will:1"])
        window.tick(timestamp: 3)

        XCTAssertTrue(page.viewControllers?.first === before)
        XCTAssertEqual(page.children.count, 1)
        XCTAssertTrue(page.children.first === before)
        XCTAssertNil(current.parent)
        XCTAssertEqual(delegate.entries, ["will:1", "did:true:1:true"])
    }

    func testPageIndicatorQueriesMatchMeasuredSetCompletionTimingWithoutDuplicates() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let log = PageLog()
        let a = PageChild("a", log: log)
        let b = PageChild("b", log: log)
        let c = PageChild("c", log: log)
        let source = PageSource([a, b, c], count: 3, index: 0, eventLog: log)
        let page = UIPageViewController(transitionStyle: .scroll,
                                        navigationOrientation: .horizontal)
        page.dataSource = source
        page.view.frame = window.bounds
        window.addSubview(page.view)
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        log.entries.removeAll()
        source.presentationQueries.removeAll()

        page.setViewControllers([a], direction: .forward, animated: false) { value in
            log.entries.append("completion.initial:\(value)")
        }
        XCTAssertEqual(log.entries, [
            "a.willMove:page", "a.didMove:page", "a.loadView", "a.viewDidLoad",
            "a.willAppear:false", "a.didAppear:false",
            "completion.initial:true", "source.count", "source.index",
        ])
        XCTAssertEqual(source.presentationQueries, ["count", "index"])

        log.entries.removeAll()
        source.presentationQueries.removeAll()
        source.index = 1
        page.setViewControllers([b], direction: .forward, animated: false) { value in
            log.entries.append("completion.nonanimated:\(value)")
        }
        XCTAssertEqual(log.entries, [
            "a.willMove:nil",
            "b.willMove:page", "b.didMove:page", "b.loadView", "b.viewDidLoad",
            "b.willAppear:false", "a.willDisappear:false",
            "a.didDisappear:false", "a.willMove:nil", "a.didMove:nil",
            "b.didAppear:false", "completion.nonanimated:true",
            "source.count", "source.index",
        ])
        XCTAssertEqual(source.presentationQueries, ["count", "index"])

        log.entries.removeAll()
        source.presentationQueries.removeAll()
        source.index = 2
        var animatedCompletion: Bool?
        page.setViewControllers([c], direction: .forward, animated: true) { value in
            animatedCompletion = value
            log.entries.append("completion.animated:\(value)")
        }
        log.entries.append("probe.afterAnimatedSet")
        XCTAssertEqual(log.entries, [
            "b.willMove:nil",
            "c.willMove:page", "c.didMove:page", "c.loadView", "c.viewDidLoad",
            "source.count", "source.index", "probe.afterAnimatedSet",
        ])
        XCTAssertEqual(source.presentationQueries, ["count", "index"])
        XCTAssertNil(animatedCompletion)

        window.tick(timestamp: 0.31)
        window.tick(timestamp: 0.32)
        XCTAssertEqual(animatedCompletion, true)
        XCTAssertEqual(source.presentationQueries, ["count", "index"],
                       "animated completion must not repeat the synchronous queries")
        XCTAssertEqual(log.entries.filter { $0.hasPrefix("source.") },
                       ["source.count", "source.index"])
    }

    func testAnimatedReplacementPublishesIncomingImmediatelyAndCleansUpOnTick() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let log = PageLog()
        let a = PageChild("a", log: log)
        let b = PageChild("b", log: log)
        let source = PageSource([a, b], count: 2, index: 0)
        let delegate = PageDelegate()
        let page = UIPageViewController(transitionStyle: .scroll,
                                        navigationOrientation: .horizontal)
        page.dataSource = source
        page.delegate = delegate
        page.view.frame = window.bounds
        window.addSubview(page.view)
        window.makeKeyAndVisible()
        page.setViewControllers([a], direction: .forward, animated: false)
        XCTAssertEqual(log.entries, [
            "a.willMove:page", "a.didMove:page", "a.loadView", "a.viewDidLoad",
            "a.willAppear:false", "a.didAppear:false",
        ], "first install contains before loading and completes appearance inline")
        log.entries.removeAll()

        var completion: Bool?
        page.setViewControllers([b], direction: .forward, animated: true) {
            completion = $0
        }

        XCTAssertNil(completion)
        XCTAssertTrue(page.viewControllers?.first === b)
        XCTAssertEqual(page.children.count, 2)
        XCTAssertTrue(a.parent === page)
        XCTAssertTrue(b.parent === page)
        XCTAssertEqual(delegate.entries, [],
                       "programmatic transitions do not call gesture delegate hooks")
        XCTAssertEqual(log.entries, [
            "a.willMove:nil",
            "b.willMove:page", "b.didMove:page", "b.loadView", "b.viewDidLoad",
        ], "animated appearance starts on the next host turn, after set returns")

        window.tick(timestamp: 0.31)
        XCTAssertNil(completion)
        XCTAssertEqual(log.entries.suffix(2), [
            "b.willAppear:true", "a.willDisappear:true",
        ])
        window.tick(timestamp: 0.32)
        XCTAssertEqual(completion, true)
        XCTAssertNil(a.parent)
        XCTAssertTrue(b.parent === page)
        XCTAssertEqual(page.children.count, 1)
        XCTAssertEqual(log.entries.suffix(6), [
            "b.willAppear:true", "a.willDisappear:true",
            "b.didAppear:true", "a.didDisappear:true",
            "a.willMove:nil", "a.didMove:nil",
        ])
        XCTAssertEqual(log.entries.filter { $0 == "a.willMove:nil" }.count, 2,
                       "iOS 26.1 calls outgoing willMove at staging and teardown")
    }

    /// Pager t1200, iPhone SE 2x / iOS 26.1: after an animated
    /// `setViewControllers` the model offset is the center slot with the
    /// incoming page, but a finished bounds animation used to pin
    /// presentation at the destination (empty trailing slot, white).
    func testAnimatedReplacementClearsBoundsPresentationAtRest() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let a = UIViewController()
        a.view.backgroundColor = UIColor(red: 0.85, green: 0.25, blue: 0.25, alpha: 1)
        let b = UIViewController()
        b.view.backgroundColor = UIColor(red: 0.20, green: 0.65, blue: 0.35, alpha: 1)
        let source = PageSource([a, b], count: 2, index: 0)
        let page = UIPageViewController(transitionStyle: .scroll,
                                        navigationOrientation: .horizontal)
        page.dataSource = source
        page.view.frame = window.bounds
        window.addSubview(page.view)
        window.makeKeyAndVisible()
        page.setViewControllers([a], direction: .forward, animated: false)
        window.layoutIfNeeded()
        let center = page.scrollView.bounds.width
        XCTAssertEqual(page.scrollView.contentOffset.x, center, accuracy: 1e-6)

        OpenUIKitRuntime.animationTime = 0
        page.setViewControllers([b], direction: .forward, animated: true)
        window.layoutIfNeeded()
        let atStart = LayerBridge.presentationState(of: page.scrollView, at: 0)
        XCTAssertEqual(atStart.bounds.origin.x, center, accuracy: 1,
                       "frame 0 presentation stays on the outgoing page")

        window.tick(timestamp: 0.32)
        window.tick(timestamp: 0.80)
        XCTAssertEqual(page.scrollView.contentOffset.x, center, accuracy: 1e-6)
        let atRest = LayerBridge.presentationState(of: page.scrollView, at: 0.80)
        XCTAssertEqual(atRest.bounds.origin.x, center, accuracy: 1e-6,
                       "finished bounds animation must not pin the empty slot")
        XCTAssertTrue(page.viewControllers?.first === b)
    }

    /// MEASURED pager-clock probe, iPhone SE 2x / iOS 26.1, 10 live traces:
    /// cosine ease-in-out over 0.3 s, named frame = Nth animator tick after
    /// first motion (local n=1). 375 → 750 then queue reset at n=18:
    /// n=0:375 (t400) n=6:469 (t500) n=12:656.5 (t600) n=18:375 (t700).
    /// Cubic bezier(0.42,0,0.58,1) is 458 / 667 at n=6/12.
    func testIOSProgrammaticScrollSamplesMatchPagerProbe() {
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = saved }

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 280))
        let a = UIViewController()
        a.view.backgroundColor = UIColor(red: 0.85, green: 0.25, blue: 0.25, alpha: 1)
        let b = UIViewController()
        b.view.backgroundColor = UIColor(red: 0.20, green: 0.65, blue: 0.35, alpha: 1)
        let source = PageSource([a, b], count: 2, index: 0)
        let page = UIPageViewController(transitionStyle: .scroll,
                                        navigationOrientation: .horizontal)
        page.dataSource = source
        page.view.frame = window.bounds
        window.addSubview(page.view)
        window.makeKeyAndVisible()
        page.setViewControllers([a], direction: .forward, animated: false)
        window.layoutIfNeeded()
        let center = page.scrollView.bounds.width
        XCTAssertEqual(center, 375, accuracy: 1)

        OpenUIKitRuntime.animationTime = 0
        page.setViewControllers([b], direction: .forward, animated: true)
        window.layoutIfNeeded()

        func origin(at t: Double) -> CGFloat {
            LayerBridge.presentationState(of: page.scrollView, at: t).bounds.origin.x
        }
        XCTAssertEqual(origin(at: 0), center, accuracy: 1)
        XCTAssertEqual(origin(at: 1.0 / 60.0), 378, accuracy: 1)
        XCTAssertEqual(origin(at: 6.0 / 60.0), 469, accuracy: 1)
        XCTAssertEqual(origin(at: 8.0 / 60.0), 530, accuracy: 1)
        XCTAssertEqual(origin(at: 12.0 / 60.0), 656.5, accuracy: 1)
        XCTAssertEqual(origin(at: 17.0 / 60.0), 747, accuracy: 1)

        let bmp = UIRenderer.render(window, scale: 1)
        let o = (100 * bmp.width + 187) * 4
        XCTAssertGreaterThan(Int(bmp.pixels[o]), 180,
                             "frame 0 must paint the outgoing page, not the empty slot")

        window.tick(timestamp: 0.29)
        XCTAssertEqual(page.viewControllers?.first === b, true)
        XCTAssertEqual(page.children.count, 2,
                       "iOS duration 0.3 has not completed at n=17")
        window.tick(timestamp: 0.30)
        XCTAssertEqual(page.children.count, 1)
        XCTAssertEqual(page.scrollView.contentOffset.x, center, accuracy: 1e-6)
        XCTAssertEqual(origin(at: 0.30), center, accuracy: 1,
                       "n=18 queue reset; presentation follows the model")
    }

    func testAnimatedTransitionInterruptedByNonanimatedSetMatchesUIKit26() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let log = PageLog()
        let a = PageChild("a", log: log)
        let b = PageChild("b", log: log)
        let c = PageChild("c", log: log)
        let page = UIPageViewController(transitionStyle: .scroll,
                                        navigationOrientation: .horizontal)
        page.view.frame = window.bounds
        window.addSubview(page.view)
        window.makeKeyAndVisible()
        page.setViewControllers([a], direction: .forward, animated: false)
        log.entries.removeAll()

        var firstCompletion: Bool?
        var secondCompletion: Bool?
        page.setViewControllers([b], direction: .forward, animated: true) { value in
            firstCompletion = value
            log.entries.append("completion.first:\(value)")
        }
        page.setViewControllers([c], direction: .reverse, animated: false) { value in
            secondCompletion = value
            log.entries.append("completion.second:\(value)")
        }

        XCTAssertEqual(firstCompletion, false)
        XCTAssertEqual(secondCompletion, true)
        XCTAssertTrue(page.viewControllers?.first === c)
        XCTAssertEqual(page.children.count, 1)
        XCTAssertTrue(c.parent === page)
        XCTAssertEqual(log.entries, [
            "a.willMove:nil",
            "b.willMove:page", "b.didMove:page", "b.loadView", "b.viewDidLoad",
            "b.willMove:nil",
            "c.willMove:page", "c.didMove:page", "c.loadView", "c.viewDidLoad",
            "b.willAppear:true", "a.willDisappear:true",
            "completion.first:false",
            "c.willAppear:false", "b.willDisappear:false",
            "b.didDisappear:false", "a.didDisappear:true",
            "a.willMove:nil", "a.didMove:nil",
            "b.willMove:nil", "b.didMove:nil",
            "c.didAppear:false", "completion.second:true",
        ])

        let stableEvents = log.entries
        window.tick(timestamp: 0.12)
        window.tick(timestamp: 0.32)
        window.tick(timestamp: 1)
        XCTAssertEqual(log.entries, stableEvents,
                       "the superseded scroll animation cannot mutate the replacement later")
        XCTAssertEqual(firstCompletion, false)
        XCTAssertEqual(secondCompletion, true)
        XCTAssertEqual(page.children.count, 1)
        XCTAssertTrue(page.children.first === c)
    }

    func testAnimatedTransitionInterruptedByAnimatedSetIsDeterministic() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let log = PageLog()
        let a = PageChild("a", log: log)
        let b = PageChild("b", log: log)
        let c = PageChild("c", log: log)
        let page = UIPageViewController(transitionStyle: .scroll,
                                        navigationOrientation: .horizontal)
        page.view.frame = window.bounds
        window.addSubview(page.view)
        window.makeKeyAndVisible()
        page.setViewControllers([a], direction: .forward, animated: false)
        log.entries.removeAll()

        var firstCompletion: Bool?
        var secondCompletion: Bool?
        page.setViewControllers([b], direction: .forward, animated: true) {
            firstCompletion = $0
        }
        page.setViewControllers([c], direction: .reverse, animated: true) {
            secondCompletion = $0
        }

        XCTAssertEqual(firstCompletion, false)
        XCTAssertNil(secondCompletion)
        XCTAssertTrue(page.viewControllers?.first === c)
        XCTAssertEqual(page.children.count, 2)
        XCTAssertTrue(b.parent === page)
        XCTAssertTrue(c.parent === page)

        window.tick(timestamp: 0.31)
        XCTAssertNil(secondCompletion)
        window.tick(timestamp: 0.32)
        XCTAssertEqual(secondCompletion, true)
        XCTAssertEqual(page.children.count, 1)
        XCTAssertTrue(page.children.first === c)
        XCTAssertNil(a.parent)
        XCTAssertNil(b.parent)
        XCTAssertEqual(log.entries.filter { $0 == "a.didMove:nil" }.count, 1)
        XCTAssertEqual(log.entries.filter { $0 == "b.didMove:nil" }.count, 1)
    }

    func testNonanimatedReplacementUsesMeasuredSynchronousOrder() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let log = PageLog()
        let a = PageChild("a", log: log)
        let b = PageChild("b", log: log)
        let page = UIPageViewController(transitionStyle: .scroll,
                                        navigationOrientation: .horizontal)
        page.view.frame = window.bounds
        window.addSubview(page.view)
        window.makeKeyAndVisible()
        page.setViewControllers([a], direction: .forward, animated: false)
        log.entries.removeAll()

        var completion: Bool?
        page.setViewControllers([b], direction: .reverse, animated: false) {
            completion = $0
            log.entries.append("completion:\($0)")
        }

        XCTAssertEqual(completion, true)
        XCTAssertEqual(log.entries, [
            "a.willMove:nil",
            "b.willMove:page", "b.didMove:page", "b.loadView", "b.viewDidLoad",
            "b.willAppear:false", "a.willDisappear:false",
            "a.didDisappear:false", "a.willMove:nil", "a.didMove:nil",
            "b.didAppear:false", "completion:true",
        ])
        XCTAssertNil(a.parent)
        XCTAssertTrue(b.parent === page)
        XCTAssertEqual(page.children.count, 1)
    }

    func testMinimalDelegateUsesOptionalRequirementDefaults() {
        @MainActor final class EmptyDelegate: UIPageViewControllerDelegate {}
        let page = UIPageViewController(transitionStyle: .scroll,
                                        navigationOrientation: .horizontal)
        let delegate = EmptyDelegate()
        XCTAssertEqual(delegate.pageViewController(page, spineLocationFor: .portrait), .none)
        XCTAssertEqual(delegate.pageViewControllerSupportedInterfaceOrientations(page),
                       page.supportedInterfaceOrientations)
        XCTAssertEqual(delegate.pageViewControllerPreferredInterfaceOrientationForPresentation(page),
                       .portrait)
    }

    func testAllUIKitSubclassablePropertiesDynamicallyDispatch() {
        let page: UIPageViewController = OverridingPageViewController()
        let delegate = PageDelegate()
        let source = PageSource([], count: 0, index: 0)
        page.delegate = delegate
        page.dataSource = source
        page.isDoubleSided = true

        XCTAssertTrue(page.delegate === delegate)
        XCTAssertTrue(page.dataSource === source)
        XCTAssertEqual(page.transitionStyle, .pageCurl)
        XCTAssertEqual(page.navigationOrientation, .vertical)
        XCTAssertEqual(page.spineLocation, .max)
        XCTAssertTrue(page.isDoubleSided)
        let subclass = page as! OverridingPageViewController
        XCTAssertTrue(page.viewControllers?.first === subclass.overriddenChild)
        XCTAssertTrue(page.gestureRecognizers.first === subclass.overriddenGesture)
    }
}

private extension XCTestCase {
    func assertRectEqual(_ lhs: CGRect, _ rhs: CGRect, accuracy: CGFloat,
                         file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(lhs.minX, rhs.minX, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(lhs.minY, rhs.minY, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(lhs.width, rhs.width, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(lhs.height, rhs.height, accuracy: accuracy, file: file, line: line)
    }
}
