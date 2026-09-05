// UIPageViewController. Owner: view-controller compatibility (Focus Pro Tips).
//
// Public API shape and programmatic transition behavior were measured on an
// iPhone 17 Pro simulator running iOS 26.1. The Focus-shaped path is a
// horizontal `.scroll` controller whose datasource implements both page-
// indicator methods and whose first page is installed with `animated: true`.
// UIKit makes that first install synchronous (there is no outgoing page),
// contains the child before loading its view, and places a UIPageControl
// directly in the page controller's view.
//
// The portable runtime implements that path plus horizontal/vertical swipe
// navigation through the existing UIScrollView physics. `.pageCurl` retains
// UIKit's public configuration and required controller-count validation, but
// contains/renders only the first retained page as a flat swap; there is no
// portable 3-D paper mesh or two-page containment lifecycle.

/// UIKit's private root class name. Keeping the name also lets layout dumps
/// prune the same container boundary when a page controller enters a scene.
@preconcurrency @MainActor
final class _UIPageViewControllerContentView: UIView {}

/// The scroll-style controller's three-slot queue. The middle slot is the
/// visible page; its siblings stage an interactive predecessor/successor.
@preconcurrency @MainActor
final class _UIQueuingScrollView: UIScrollView {}

/// UIKit keeps its queuing scroll view's delegate private. In particular,
/// `UIPageViewController` does not publicly conform to UIScrollViewDelegate,
/// so an app subclass remains free to declare identically named methods.
@preconcurrency @MainActor
private final class _UIPageViewControllerScrollDelegate: UIScrollViewDelegate {
    weak var owner: UIPageViewController?

    init(owner: UIPageViewController) { self.owner = owner }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        owner?._pageScrollViewDidScroll(scrollView)
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        owner?._pageScrollViewWillEndDragging(
            scrollView, withVelocity: velocity,
            targetContentOffset: targetContentOffset)
    }

    func scrollViewDidEndDragging(
        _ scrollView: UIScrollView,
        willDecelerate: Bool
    ) {
        owner?._pageScrollViewDidEndDragging(
            scrollView, willDecelerate: willDecelerate)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        owner?._pageScrollViewDidEndDecelerating(scrollView)
    }
}

@preconcurrency @MainActor
public protocol UIPageViewControllerDataSource: AnyObject {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController?

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController?

    func presentationCount(for pageViewController: UIPageViewController) -> Int
    func presentationIndex(for pageViewController: UIPageViewController) -> Int
}

public extension UIPageViewControllerDataSource {
    /// Pure Swift has no Objective-C optional requirements. Zero is the
    /// behavior-preserving default: it creates no visible indicator and
    /// reserves no content height.
    func presentationCount(for pageViewController: UIPageViewController) -> Int { 0 }
    func presentationIndex(for pageViewController: UIPageViewController) -> Int { 0 }
}

@preconcurrency @MainActor
public protocol UIPageViewControllerDelegate: AnyObject {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        willTransitionTo pendingViewControllers: [UIViewController]
    )

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    )

    func pageViewController(
        _ pageViewController: UIPageViewController,
        spineLocationFor orientation: UIInterfaceOrientation
    ) -> UIPageViewController.SpineLocation

    func pageViewControllerSupportedInterfaceOrientations(
        _ pageViewController: UIPageViewController
    ) -> UIInterfaceOrientationMask

    func pageViewControllerPreferredInterfaceOrientationForPresentation(
        _ pageViewController: UIPageViewController
    ) -> UIInterfaceOrientation
}

public extension UIPageViewControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        willTransitionTo pendingViewControllers: [UIViewController]
    ) {}

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {}

    func pageViewController(
        _ pageViewController: UIPageViewController,
        spineLocationFor orientation: UIInterfaceOrientation
    ) -> UIPageViewController.SpineLocation { pageViewController.spineLocation }

    func pageViewControllerSupportedInterfaceOrientations(
        _ pageViewController: UIPageViewController
    ) -> UIInterfaceOrientationMask { pageViewController.supportedInterfaceOrientations }

    func pageViewControllerPreferredInterfaceOrientationForPresentation(
        _ pageViewController: UIPageViewController
    ) -> UIInterfaceOrientation { .portrait }
}

@preconcurrency @MainActor
open class UIPageViewController: UIViewController {
    public enum NavigationOrientation: Int, Sendable {
        case horizontal = 0
        case vertical = 1
    }

    public enum SpineLocation: Int, Sendable {
        case none = 0
        case min = 1
        case mid = 2
        case max = 3
    }

    public enum NavigationDirection: Int, Sendable {
        case forward = 0
        case reverse = 1
    }

    public enum TransitionStyle: Int, Sendable {
        case pageCurl = 0
        case scroll = 1
    }

    public struct OptionsKey: Hashable, RawRepresentable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let spineLocation = OptionsKey(
            rawValue: "UIPageViewControllerOptionSpineLocationKey")
        public static let interPageSpacing = OptionsKey(
            rawValue: "UIPageViewControllerOptionInterPageSpacingKey")
    }

    open weak var delegate: UIPageViewControllerDelegate?
    open weak var dataSource: UIPageViewControllerDataSource? {
        didSet {
            guard isViewLoaded else { return }
            refreshPageControl()
            updateScrollEnabled()
            layoutPageHierarchy()
        }
    }

    private let _transitionStyle: TransitionStyle
    private let _navigationOrientation: NavigationOrientation
    private var _spineLocation: SpineLocation
    private var _isDoubleSided: Bool

    open var transitionStyle: TransitionStyle { _transitionStyle }
    open var navigationOrientation: NavigationOrientation { _navigationOrientation }
    open var spineLocation: SpineLocation { _spineLocation }
    open var isDoubleSided: Bool {
        get { _isDoubleSided }
        set {
            precondition(
                newValue || spineLocation != .mid,
                "A UIPageViewController with a mid spine must be double-sided")
            _isDoubleSided = newValue
        }
    }

    /// UIKit 26.1 returns an empty (non-nil) array immediately after init.
    open var viewControllers: [UIViewController]? { _viewControllers }
    private var _viewControllers: [UIViewController] = []

    private let interPageSpacing: CGFloat
    private let contentView = _UIPageViewControllerContentView()
    let scrollView = _UIQueuingScrollView()
    private let leadingSlot = UIView()
    private let currentSlot = UIView()
    private let trailingSlot = UIView()
    private lazy var scrollDelegateProxy =
        _UIPageViewControllerScrollDelegate(owner: self)
    private var currentWrapper: UIView?
    private var pendingWrapper: UIView?
    private weak var pendingController: UIViewController?
    private var pendingDirection: NavigationDirection?
    private weak var transitionOutgoing: UIViewController?
    private var programmaticCompletion: ((Bool) -> Void)?
    private var programmaticAppearanceStarted = false
    private var transitionToken: UInt64 = 0
    private var pageControl: UIPageControl?

    /// MEASURED Pager page-next, iPhone SE 2x / iOS 26.1, named 60 Hz
    /// frames (confprobe wait): 375 → 750 then queue reset at n=18:
    /// n=0:375 (t400) n=6:469 (t500) n=12:656.5 (t600) n=18:375 (t700).
    /// Ease-in-out over 0.3 s, no extra delay. Catalyst keeps 0.32 so the
    /// 0.31/0.32 completion ticks stay put.
    static var programmaticScrollDuration: Double {
        OpenUIKitRuntime.systemFontCut == .iOS ? 0.3 : 0.32
    }

    private struct WeakTransitioningPage {
        weak var page: UIPageViewController?
    }
    private static var transitioningPages: [WeakTransitioningPage] = []

    private lazy var curlGestureRecognizers: [UIGestureRecognizer] = {
        [UIPanGestureRecognizer(), UITapGestureRecognizer()]
    }()

    /// UIKit exposes only the page-curl recognizers here. The scroll style's
    /// internal scroll-view pan is intentionally not returned.
    open var gestureRecognizers: [UIGestureRecognizer] {
        transitionStyle == .pageCurl ? curlGestureRecognizers : []
    }

    public init(
        transitionStyle style: TransitionStyle,
        navigationOrientation: NavigationOrientation,
        options: [OptionsKey: Any]? = nil
    ) {
        _transitionStyle = style
        _navigationOrientation = navigationOrientation

        let requestedSpine = Self.integerOption(options?[.spineLocation])
            .flatMap(SpineLocation.init(rawValue:))
        if style == .pageCurl {
            _spineLocation = requestedSpine ?? .min
        } else {
            _spineLocation = .none
        }
        _isDoubleSided = _spineLocation == .mid
        interPageSpacing = max(0, Self.floatingOption(options?[.interPageSpacing]) ?? 0)
        super.init()
    }

    /// OpenUIKit has no storyboard/nib decoder. Keep the initializer surface
    /// and choose UIKit's ordinary scroll/horizontal programmatic shape.
    public required init?(coder: NSCoder) {
        _transitionStyle = .scroll
        _navigationOrientation = .horizontal
        _spineLocation = .none
        _isDoubleSided = false
        interPageSpacing = 0
        _ = coder
        super.init()
    }

    private static func integerOption(_ value: Any?) -> Int? {
        if let value = value as? Int { return value }
        if let value = value as? UInt { return Int(value) }
        if let value = value as? Double { return Int(value) }
        if let value = value as? Float { return Int(value) }
        return nil
    }

    private static func floatingOption(_ value: Any?) -> CGFloat? {
        if let value = value as? CGFloat { return value }
        if let value = value as? Double { return CGFloat(value) }
        if let value = value as? Float { return CGFloat(value) }
        if let value = value as? Int { return CGFloat(value) }
        if let value = value as? UInt { return CGFloat(value) }
        return nil
    }

    open override func loadView() {
        contentView.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        contentView.backgroundColor = nil
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view = contentView

        scrollView.delegate = scrollDelegateProxy
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = false
        scrollView.addSubview(leadingSlot)
        scrollView.addSubview(currentSlot)
        scrollView.addSubview(trailingSlot)

        // Real UIKit inserts the page control before the queuing scroll view,
        // which is why Focus can find it among the root's direct subviews.
        refreshPageControl()
        contentView.addSubview(scrollView)
        if transitionStyle == .pageCurl {
            for recognizer in curlGestureRecognizers {
                contentView.addGestureRecognizer(recognizer)
            }
        }
        updateScrollEnabled()
        layoutPageHierarchy()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutPageHierarchy()
    }

    open func setViewControllers(
        _ viewControllers: [UIViewController]?,
        direction: NavigationDirection,
        animated: Bool,
        completion: ((Bool) -> Void)? = nil
    ) {
        let requiredCount = transitionStyle == .pageCurl
            && (spineLocation == .mid || (isDoubleSided && spineLocation != .mid)) ? 2 : 1
        guard let viewControllers, viewControllers.count == requiredCount else {
            preconditionFailure(
                "The number of view controllers provided does not match the number required for the requested transition")
        }

        // The scroll-style runtime has one visible page. Page-curl accepts
        // the SDK-required pair, retains both publicly, and renders the first
        // because the paper-back mesh is an explicit unsupported surface.
        let incoming = viewControllers[0]

        if transitionOutgoing != nil {
            interruptProgrammaticTransition(
                with: viewControllers, incoming: incoming, direction: direction,
                animated: animated, completion: completion)
            return
        }

        let outgoing = _viewControllers.first
        if outgoing === incoming && _viewControllers.count == viewControllers.count {
            _viewControllers = viewControllers
            completion?(true)
            refreshPageControl()
            return
        }

        _viewControllers = viewControllers

        if let outgoing {
            outgoing.willMove(toParent: nil)
        }
        if incoming.parent !== self {
            addChild(incoming)
            incoming.didMove(toParent: self)
        }
        loadViewIfNeeded()

        let incomingWrapper = makeWrapper(for: incoming)
        let visible = viewIfLoaded?.window != nil

        guard let outgoing, let outgoingWrapper = currentWrapper else {
            replaceCurrentWrapper(with: incomingWrapper)
            if visible {
                incoming.beginAppearanceTransition(true, animated: false)
                incoming.endAppearanceTransition()
            }
            completion?(true)
            refreshPageControl()
            return
        }

        guard animated, transitionStyle == .scroll else {
            if visible {
                incoming.beginAppearanceTransition(true, animated: false)
                outgoing.beginAppearanceTransition(false, animated: false)
            }
            replaceCurrentWrapper(with: incomingWrapper)
            outgoingWrapper.removeFromSuperview()
            if visible {
                outgoing.endAppearanceTransition()
            }
            outgoing.willMove(toParent: nil)
            outgoing.removeFromParent()
            if visible {
                incoming.endAppearanceTransition()
            }
            completion?(true)
            refreshPageControl()
            return
        }

        transitionToken &+= 1
        let token = transitionToken
        transitionOutgoing = outgoing
        pendingController = incoming
        pendingDirection = direction
        pendingWrapper = incomingWrapper
        programmaticCompletion = completion
        programmaticAppearanceStarted = false
        slot(for: direction).addSubview(incomingWrapper)
        fitWrapper(incomingWrapper, in: slot(for: direction))
        Self.registerTransitioning(self)

        // UIKit asks for the page-indicator model synchronously after the
        // incoming view has loaded, before this animated setter returns. It
        // does not repeat those queries when the animation later completes.
        refreshPageControl()

        let destination = offset(for: direction)
        UIView.animate(
            withDuration: Self.programmaticScrollDuration,
            delay: 0,
            options: [.curveEaseInOut],
            animations: { self.scrollView.contentOffset = destination },
            completion: { [weak self] finished in
                guard let self, self.transitionToken == token else { return }
                self.completeProgrammaticTransition(finished: finished)
            })
    }

    // MARK: Page-control model

    private var canShowPageControl: Bool {
        transitionStyle == .scroll
            && navigationOrientation == .horizontal
            && dataSource != nil
    }

    private func refreshPageControl() {
        guard isViewLoaded, canShowPageControl, let dataSource else {
            pageControl?.removeFromSuperview()
            pageControl = nil
            return
        }
        let control: UIPageControl
        if let existing = pageControl {
            control = existing
        } else {
            control = UIPageControl()
            pageControl = control
            contentView.insertSubview(control, at: 0)
        }
        let count = max(0, dataSource.presentationCount(for: self))
        control.numberOfPages = count
        let requested = dataSource.presentationIndex(for: self)
        control.currentPage = count == 0 ? 0 : max(0, min(count - 1, requested))
    }

    private func updateScrollEnabled() {
        scrollView.isScrollEnabled = transitionStyle == .scroll
            && dataSource != nil
            && !_viewControllers.isEmpty
    }

    // MARK: Three-slot geometry

    private var visibleBounds: CGRect {
        let controlHeight: CGFloat
        if let pageControl, pageControl.numberOfPages > 0 {
            controlHeight = UIPageControl.contentHeight
        } else {
            controlHeight = 0
        }
        return CGRect(x: contentView.bounds.minX, y: contentView.bounds.minY,
                      width: contentView.bounds.width,
                      height: max(0, contentView.bounds.height - controlHeight))
    }

    private func layoutPageHierarchy() {
        guard isViewLoaded else { return }
        let visible = visibleBounds
        let spacing = interPageSpacing
        let pageExtent: CGFloat

        switch navigationOrientation {
        case .horizontal:
            scrollView.frame = CGRect(x: visible.minX - spacing / 2, y: visible.minY,
                                      width: visible.width + spacing, height: visible.height)
            pageExtent = scrollView.bounds.width
            leadingSlot.frame = CGRect(x: 0, y: 0, width: pageExtent,
                                       height: scrollView.bounds.height)
            currentSlot.frame = leadingSlot.frame.offsetBy(dx: pageExtent, dy: 0)
            trailingSlot.frame = currentSlot.frame.offsetBy(dx: pageExtent, dy: 0)
            scrollView.contentSize = CGSize(width: pageExtent * 3,
                                            height: scrollView.bounds.height)
            if pendingDirection == nil {
                scrollView.contentOffset = CGPoint(x: pageExtent, y: 0)
            }
        case .vertical:
            scrollView.frame = CGRect(x: visible.minX, y: visible.minY - spacing / 2,
                                      width: visible.width, height: visible.height + spacing)
            pageExtent = scrollView.bounds.height
            leadingSlot.frame = CGRect(x: 0, y: 0, width: scrollView.bounds.width,
                                       height: pageExtent)
            currentSlot.frame = leadingSlot.frame.offsetBy(dx: 0, dy: pageExtent)
            trailingSlot.frame = currentSlot.frame.offsetBy(dx: 0, dy: pageExtent)
            scrollView.contentSize = CGSize(width: scrollView.bounds.width,
                                            height: pageExtent * 3)
            if pendingDirection == nil {
                scrollView.contentOffset = CGPoint(x: 0, y: pageExtent)
            }
        }

        if let control = pageControl {
            if control.numberOfPages == 0 {
                control.frame = CGRect(x: contentView.bounds.midX,
                                       y: contentView.bounds.maxY, width: 0, height: 0)
            } else {
                let size = control.size(forNumberOfPages: control.numberOfPages)
                control.frame = CGRect(x: contentView.bounds.midX - size.width / 2,
                                       y: contentView.bounds.maxY - UIPageControl.contentHeight,
                                       width: size.width, height: UIPageControl.contentHeight)
            }
        }

        if let wrapper = currentWrapper { fitWrapper(wrapper, in: currentSlot) }
        if let wrapper = pendingWrapper, let direction = pendingDirection {
            fitWrapper(wrapper, in: slot(for: direction))
        }
    }

    private func makeWrapper(for controller: UIViewController) -> UIView {
        let wrapper = UIView()
        let childView = controller.view!
        childView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        wrapper.addSubview(childView)
        return wrapper
    }

    private func fitWrapper(_ wrapper: UIView, in slot: UIView) {
        switch navigationOrientation {
        case .horizontal:
            wrapper.frame = CGRect(x: interPageSpacing / 2, y: 0,
                                   width: max(0, slot.bounds.width - interPageSpacing),
                                   height: slot.bounds.height)
        case .vertical:
            wrapper.frame = CGRect(x: 0, y: interPageSpacing / 2,
                                   width: slot.bounds.width,
                                   height: max(0, slot.bounds.height - interPageSpacing))
        }
        wrapper.subviews.first?.frame = wrapper.bounds
    }

    private func replaceCurrentWrapper(with wrapper: UIView) {
        currentWrapper?.removeFromSuperview()
        currentWrapper = wrapper
        currentSlot.addSubview(wrapper)
        fitWrapper(wrapper, in: currentSlot)
        resetScrollToCenter()
        updateScrollEnabled()
    }

    private func slot(for direction: NavigationDirection) -> UIView {
        direction == .forward ? trailingSlot : leadingSlot
    }

    private func centerOffset() -> CGPoint {
        navigationOrientation == .horizontal
            ? CGPoint(x: scrollView.bounds.width, y: 0)
            : CGPoint(x: 0, y: scrollView.bounds.height)
    }

    private func offset(for direction: NavigationDirection) -> CGPoint {
        switch (navigationOrientation, direction) {
        case (.horizontal, .forward): return CGPoint(x: scrollView.bounds.width * 2, y: 0)
        case (.horizontal, .reverse): return .zero
        case (.vertical, .forward): return CGPoint(x: 0, y: scrollView.bounds.height * 2)
        case (.vertical, .reverse): return .zero
        }
    }

    private func resetScrollToCenter() {
        let saved = scrollView.delegate
        scrollView.delegate = nil
        scrollView.contentOffset = centerOffset()
        scrollView.delegate = saved
    }

    // MARK: Programmatic transition cleanup

    private static func registerTransitioning(_ page: UIPageViewController) {
        transitioningPages.removeAll { $0.page == nil }
        if !transitioningPages.contains(where: { $0.page === page }) {
            transitioningPages.append(WeakTransitioningPage(page: page))
        }
    }

    /// Start callbacks on the first host turn after `setViewControllers`
    /// returns. UIKit 26.1 stages containment and publishes `viewControllers`
    /// synchronously, but does not begin an animated replacement's appearance
    /// callbacks until the following run-loop turn.
    static func _stepTransitions(to time: Double) {
        _ = time
        guard !transitioningPages.isEmpty else { return }
        for entry in transitioningPages {
            entry.page?.beginProgrammaticAppearanceIfNeeded()
        }
        transitioningPages.removeAll {
            $0.page == nil || $0.page?.transitionOutgoing == nil
        }
    }

    private func beginProgrammaticAppearanceIfNeeded() {
        guard !programmaticAppearanceStarted,
              let incoming = pendingController,
              let outgoing = transitionOutgoing else { return }
        programmaticAppearanceStarted = true
        guard viewIfLoaded?.window != nil else { return }
        incoming.beginAppearanceTransition(true, animated: true)
        outgoing.beginAppearanceTransition(false, animated: true)
    }

    private func completeProgrammaticTransition(finished: Bool) {
        beginProgrammaticAppearanceIfNeeded()
        let completion = programmaticCompletion
        programmaticCompletion = nil
        guard let incoming = pendingController,
              let incomingWrapper = pendingWrapper,
              let outgoing = transitionOutgoing else {
            completion?(false)
            return
        }
        pendingWrapper = nil
        pendingController = nil
        pendingDirection = nil
        transitionOutgoing = nil
        programmaticAppearanceStarted = false

        currentWrapper?.removeFromSuperview()
        currentWrapper = incomingWrapper
        currentSlot.addSubview(incomingWrapper)
        fitWrapper(incomingWrapper, in: currentSlot)
        // Drop the bounds animation so resetScrollToCenter's model offset
        // is what we paint (Pager t1200, iPhone SE 2x / iOS 26.1).
        cancelProgrammaticScrollAnimation()
        resetScrollToCenter()

        if viewIfLoaded?.window != nil {
            incoming.endAppearanceTransition()
            outgoing.endAppearanceTransition()
        }
        outgoing.willMove(toParent: nil)
        outgoing.removeFromParent()
        updateScrollEnabled()
        completion?(finished)
    }

    /// UIKit's supported, deterministic reentry is an animated replacement
    /// immediately superseded by a nonanimated one. The interrupted
    /// completion fires `false` inside the second call, after the new child's
    /// containment/load staging; the second completion then fires `true`.
    /// We also make animated-on-animated reentry deterministic instead of
    /// reproducing UIKit 26.1's leaked-child/wedged-completion bug.
    private func interruptProgrammaticTransition(
        with viewControllers: [UIViewController],
        incoming: UIViewController,
        direction: NavigationDirection,
        animated: Bool,
        completion: ((Bool) -> Void)?
    ) {
        guard let original = transitionOutgoing,
              let intermediate = pendingController,
              let intermediateWrapper = pendingWrapper else {
            preconditionFailure("UIPageViewController transition state is incomplete")
        }

        _viewControllers = viewControllers
        intermediate.willMove(toParent: nil)
        if incoming.parent !== self {
            addChild(incoming)
            incoming.didMove(toParent: self)
        }
        loadViewIfNeeded()
        let incomingWrapper = makeWrapper(for: incoming)
        let visible = viewIfLoaded?.window != nil

        // UIKit starts the first transition only now, after the second child
        // has been contained and loaded, then reports that first completion
        // as interrupted.
        beginProgrammaticAppearanceIfNeeded()
        transitionToken &+= 1
        cancelProgrammaticScrollAnimation()
        let interruptedCompletion = programmaticCompletion
        programmaticCompletion = nil
        interruptedCompletion?(false)

        if !animated || transitionStyle != .scroll {
            if visible {
                incoming.beginAppearanceTransition(true, animated: false)
                intermediate.beginAppearanceTransition(false, animated: false)
            }

            currentWrapper?.removeFromSuperview()
            intermediateWrapper.removeFromSuperview()
            currentWrapper = incomingWrapper
            currentSlot.addSubview(incomingWrapper)
            fitWrapper(incomingWrapper, in: currentSlot)
            resetScrollToCenter()

            if visible {
                intermediate.endAppearanceTransition()
                original.endAppearanceTransition()
            }
            original.willMove(toParent: nil)
            original.removeFromParent()
            intermediate.willMove(toParent: nil)
            intermediate.removeFromParent()
            if visible { incoming.endAppearanceTransition() }

            pendingWrapper = nil
            pendingController = nil
            pendingDirection = nil
            transitionOutgoing = nil
            programmaticAppearanceStarted = false
            updateScrollEnabled()
            completion?(true)
            refreshPageControl()
            return
        }

        // Deliberate divergence from UIKit 26.1's animated-on-animated bug:
        // retire the original page, make the intermediate page the outgoing
        // page of a fresh transition, and guarantee eventual cleanup.
        if visible {
            incoming.beginAppearanceTransition(true, animated: true)
            intermediate.beginAppearanceTransition(false, animated: true)
            original.endAppearanceTransition()
        }
        original.willMove(toParent: nil)
        original.removeFromParent()

        currentWrapper?.removeFromSuperview()
        intermediateWrapper.removeFromSuperview()
        currentWrapper = intermediateWrapper
        currentSlot.addSubview(intermediateWrapper)
        fitWrapper(intermediateWrapper, in: currentSlot)
        resetScrollToCenter()

        transitionOutgoing = intermediate
        pendingController = incoming
        pendingDirection = direction
        pendingWrapper = incomingWrapper
        programmaticCompletion = completion
        programmaticAppearanceStarted = true
        slot(for: direction).addSubview(incomingWrapper)
        fitWrapper(incomingWrapper, in: slot(for: direction))
        Self.registerTransitioning(self)
        refreshPageControl()

        transitionToken &+= 1
        let token = transitionToken
        UIView.animate(
            withDuration: Self.programmaticScrollDuration,
            delay: 0,
            options: [.curveEaseInOut],
            animations: { self.scrollView.contentOffset = self.offset(for: direction) },
            completion: { [weak self] finished in
                guard let self, self.transitionToken == token else { return }
                self.completeProgrammaticTransition(finished: finished)
            })
    }

    /// Remove the superseded bounds animation and its queued internal
    /// completion. The app-facing completion is delivered explicitly at the
    /// measured point above, so the old host-clock entry must not fire later.
    private func cancelProgrammaticScrollAnimation() {
        var transactionIDs: [Int] = []
        scrollView.animations.removeAll { animation in
            guard case .bounds = animation.property else { return false }
            if !transactionIDs.contains(animation.transactionID) {
                transactionIDs.append(animation.transactionID)
            }
            return true
        }
        for transactionID in transactionIDs {
            _ = UIViewAnimationCompletionQueue.takeInterrupted(
                transactionID: transactionID)
        }
    }

    // MARK: Interactive scroll navigation

    fileprivate func _pageScrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === self.scrollView,
              scrollView.isDragging,
              pendingController == nil,
              transitionOutgoing == nil,
              let current = _viewControllers.first,
              let dataSource else { return }

        let center = centerOffset()
        let delta = navigationOrientation == .horizontal
            ? scrollView.contentOffset.x - center.x
            : scrollView.contentOffset.y - center.y
        guard delta.magnitude > 0.5 else { return }
        let direction: NavigationDirection = delta > 0 ? .forward : .reverse
        let candidate = direction == .forward
            ? dataSource.pageViewController(self, viewControllerAfter: current)
            : dataSource.pageViewController(self, viewControllerBefore: current)
        guard let candidate else { return }

        pendingDirection = direction
        pendingController = candidate
        transitionOutgoing = current
        if candidate.parent !== self {
            addChild(candidate)
            candidate.didMove(toParent: self)
        }
        let wrapper = makeWrapper(for: candidate)
        pendingWrapper = wrapper
        slot(for: direction).addSubview(wrapper)
        fitWrapper(wrapper, in: slot(for: direction))
        delegate?.pageViewController(self, willTransitionTo: [candidate])
        if viewIfLoaded?.window != nil {
            candidate.beginAppearanceTransition(true, animated: true)
            current.beginAppearanceTransition(false, animated: true)
        }
    }

    fileprivate func _pageScrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        guard scrollView === self.scrollView else { return }
        guard let direction = pendingDirection else {
            targetContentOffset.pointee = centerOffset()
            return
        }
        let center = centerOffset()
        let delta = navigationOrientation == .horizontal
            ? scrollView.contentOffset.x - center.x
            : scrollView.contentOffset.y - center.y
        let speed = navigationOrientation == .horizontal ? velocity.x : velocity.y
        let extent = navigationOrientation == .horizontal
            ? scrollView.bounds.width : scrollView.bounds.height
        let directedDelta = direction == .forward ? delta : -delta
        let directedSpeed = direction == .forward ? speed : -speed
        // UIScrollView's will-end-dragging callback reports points per
        // millisecond (unlike UIPanGestureRecognizer's points/second).
        let commits = directedDelta > 0 && (
            directedDelta >= extent / 2 || directedSpeed > 0.25)
        targetContentOffset.pointee = commits ? offset(for: direction) : center
    }

    fileprivate func _pageScrollViewDidEndDragging(
        _ scrollView: UIScrollView,
        willDecelerate: Bool
    ) {
        guard scrollView === self.scrollView, !willDecelerate else { return }
        finishInteractiveTransition()
    }

    fileprivate func _pageScrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === self.scrollView else { return }
        finishInteractiveTransition()
    }

    private func finishInteractiveTransition() {
        guard let incoming = pendingController,
              let incomingWrapper = pendingWrapper,
              let outgoing = transitionOutgoing,
              let direction = pendingDirection else {
            resetScrollToCenter()
            return
        }
        let target = offset(for: direction)
        let current = scrollView.contentOffset
        let completed: Bool
        if navigationOrientation == .horizontal {
            completed = (current.x - target.x).magnitude < 0.5
        } else {
            completed = (current.y - target.y).magnitude < 0.5
        }

        pendingController = nil
        pendingWrapper = nil
        pendingDirection = nil
        transitionOutgoing = nil

        if completed {
            _viewControllers = [incoming]
            currentWrapper?.removeFromSuperview()
            currentWrapper = incomingWrapper
            currentSlot.addSubview(incomingWrapper)
            fitWrapper(incomingWrapper, in: currentSlot)
            outgoing.willMove(toParent: nil)
            outgoing.removeFromParent()
            if let control = pageControl, control.numberOfPages > 0 {
                let delta = direction == .forward ? 1 : -1
                control.currentPage = max(0, min(control.numberOfPages - 1,
                                                  control.currentPage + delta))
            }
        } else {
            incomingWrapper.removeFromSuperview()
            incoming.willMove(toParent: nil)
            incoming.removeFromParent()
        }
        resetScrollToCenter()

        if viewIfLoaded?.window != nil {
            incoming.endAppearanceTransition()
            outgoing.endAppearanceTransition()
            if !completed {
                outgoing.beginAppearanceTransition(true, animated: true)
                incoming.beginAppearanceTransition(false, animated: true)
                outgoing.endAppearanceTransition()
                incoming.endAppearanceTransition()
            }
        }
        delegate?.pageViewController(
            self, didFinishAnimating: true,
            previousViewControllers: [outgoing], transitionCompleted: completed)
    }
}
