#if canImport(Foundation)
import Foundation
#endif
import OpenUIKit

@MainActor
private extension Animation {
    func performOpenUIKitTransaction(_ updates: @escaping () -> Void) {
        switch storage {
        case .cubic(let c1x, let c1y, let c2x, let c2y, let duration):
            let timing = UICubicTimingParameters(
                controlPoint1: CGPoint(x: CGFloat(c1x), y: CGFloat(c1y)),
                controlPoint2: CGPoint(x: CGFloat(c2x), y: CGFloat(c2y))
            )
            let animator = UIViewPropertyAnimator(
                duration: duration,
                timingParameters: timing
            )
            animator.addAnimations(updates)
            animator.startAnimation()
        case .spring(let response, let dampingFraction, _):
            UIView.animate(
                withDuration: response,
                delay: 0,
                usingSpringWithDamping: CGFloat(dampingFraction),
                initialSpringVelocity: 0,
                options: [.beginFromCurrentState, .allowUserInteraction],
                animations: updates
            )
        }
    }
}

private enum _OpenAppearanceIdentity: Hashable {
    case graph(_OpenGraphIdentity)
    case ephemeral(ObjectIdentifier)
}

private struct _OpenAppearanceActions {
    var appear: (@MainActor () -> Void)?
    var disappear: (@MainActor () -> Void)?
}

/// Structural SwiftUI wrappers must not become accidental touch targets.
/// They still expose interactive descendants (notably nested Buttons), while
/// their otherwise-transparent surface falls through to the enclosing view.
@MainActor
private class _SwiftUIPassthroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return hit === self ? nil : hit
    }
}

@MainActor
private final class _SwiftUIButtonControl: UIControl {
    let normalHost = _SwiftUIPassthroughView()
    let pressedHost = _SwiftUIPassthroughView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(normalHost)
        addSubview(pressedHost)
        updateAppearance()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        normalHost.frame = bounds
        pressedHost.frame = bounds
    }

    override func stateDidChange() {
        super.stateDidChange()
        updateAppearance()
    }

    func refreshAppearance() { updateAppearance() }

    private func updateAppearance() {
        normalHost.isHidden = isHighlighted && !pressedHost.subviews.isEmpty
        pressedHost.isHidden = !isHighlighted || pressedHost.subviews.isEmpty
    }
}

@MainActor
private final class _SwiftUIMenuControl: UIButton {
    let normalHost = _SwiftUIPassthroughView()
    let pressedHost = _SwiftUIPassthroughView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        showsMenuAsPrimaryAction = true
        addSubview(normalHost)
        addSubview(pressedHost)
        updateAppearance()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        normalHost.frame = bounds
        pressedHost.frame = bounds
    }

    override func stateDidChange() {
        super.stateDidChange()
        updateAppearance()
    }

    func refreshAppearance() { updateAppearance() }

    private func updateAppearance() {
        normalHost.isHidden = isHighlighted && !pressedHost.subviews.isEmpty
        pressedHost.isHidden = !isHighlighted || pressedHost.subviews.isEmpty
    }
}

@MainActor
private final class _SwiftUISearchBar: UISearchBar, UISearchBarDelegate {
    var setText: (@MainActor (String) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        delegate = self
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        _ = searchBar
        setText?(searchText)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        setText?("")
        _ = searchBar.resignFirstResponder()
    }
}

@MainActor
private final class _SwiftUITextField: UITextField {
    var getFocus: (@MainActor () -> Bool)?
    var setFocus: (@MainActor (Bool) -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil, getFocus?() == true {
            _ = becomeFirstResponder()
        }
    }
}

@MainActor
private final class _SwiftUITextView: UITextView, UITextViewDelegate {
    var getFocus: (@MainActor () -> Bool)?
    var setFocus: (@MainActor (Bool) -> Void)?
    var setText: (@MainActor (String) -> Void)?
    var submit: (@MainActor () -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        textViewDelegate = self
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil, getFocus?() == true { _ = becomeFirstResponder() }
    }

    func textViewDidBeginEditing(_ textView: UITextView) { setFocus?(true) }
    func textViewDidEndEditing(_ textView: UITextView) { setFocus?(false) }
    func textViewDidChange(_ textView: UITextView) { setText?(textView.text ?? "") }

    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        _ = textView
        _ = range
        guard text == "\n", let submit else { return true }
        submit()
        return false
    }
}

@MainActor
private final class _SwiftUIScrollView: UIScrollView {
    var retainedCoordinator: _SwiftUIScrollCoordinator?
}

@MainActor
private final class _SwiftUIScrollCoordinator: UIScrollViewDelegate {
    let storage: _OpenScrollProxyStorage
    let geometryObservers: [_OpenScrollGeometryObserver]
    let visibilityObservers: [_OpenScrollVisibilityObserver]
    private var previousGeometryValues: [Any] = []

    init(
        storage: _OpenScrollProxyStorage,
        geometryObservers: [_OpenScrollGeometryObserver],
        visibilityObservers: [_OpenScrollVisibilityObserver]
    ) {
        self.storage = storage
        self.geometryObservers = geometryObservers
        self.visibilityObservers = visibilityObservers
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) { notify(scrollView) }

    func notify(_ scrollView: UIScrollView) {
        let geometry = ScrollGeometry(scrollView: scrollView)
        let newValues = geometryObservers.map { $0.read(geometry) }
        let isInitialDelivery = previousGeometryValues.isEmpty
        if isInitialDelivery { previousGeometryValues = newValues }
        for index in geometryObservers.indices {
            let old = index < previousGeometryValues.count
                ? previousGeometryValues[index]
                : newValues[index]
            if isInitialDelivery || !geometryObservers[index].equals(old, newValues[index]) {
                geometryObservers[index].deliver(old, newValues[index])
            }
        }
        previousGeometryValues = newValues

        let viewport = CGRect(origin: scrollView.contentOffset, size: scrollView.bounds.size)
        for observer in visibilityObservers {
            let visible = storage.targetRects
                .filter { _, rect in
                    let intersection = rect.intersection(viewport)
                    guard !intersection.isNull, rect.width > 0, rect.height > 0 else {
                        return false
                    }
                    let fraction = intersection.width * intersection.height
                        / (rect.width * rect.height)
                    return fraction >= observer.threshold
                }
                .sorted { lhs, rhs in
                    if lhs.value.minY == rhs.value.minY {
                        return lhs.value.minX < rhs.value.minX
                    }
                    return lhs.value.minY < rhs.value.minY
                }
                .map(\.key)
            observer.deliver(visible)
        }
    }
}

@MainActor
private final class _SwiftUIContextMenuHost: _SwiftUIPassthroughView,
    UIContextMenuInteractionDelegate
{
    var menu: UIMenu?

    func installInteraction() {
        addInteraction(UIContextMenuInteraction(delegate: self))
    }

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        _ = interaction
        _ = location
        guard let menu else { return nil }
        return UIContextMenuConfiguration(actionProvider: { _ in menu })
    }
}

@MainActor
private final class _SwiftUIAlertPresentationHost: UIView {
    let configuration: _OpenAlertConfiguration

    init(configuration: _OpenAlertConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        isHidden = true
        isUserInteractionEnabled = false
        accessibilityIdentifier = "SwiftUI.AlertPresentationHost"
    }

    required init?(coder: NSCoder) { nil }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        synchronizePresentation()
    }

    private func synchronizePresentation() {
        guard window != nil,
              let presenter = _enclosingViewController(for: self) else { return }
        if !configuration.getIsPresented() {
            if let alert = presenter.presentedViewController as? UIAlertController,
               alert.title == configuration.title {
                alert.dismiss(animated: true)
            }
            return
        }
        guard presenter.presentedViewController == nil else { return }
        let alert = UIAlertController(
            title: configuration.title,
            message: _openMenuTitle(in: configuration.message),
            preferredStyle: .alert
        )
        let actions = _openAlertActions(
            in: configuration.actions,
            configuration: configuration
        )
        if actions.isEmpty {
            alert.addAction(
                UIAlertAction(title: "OK", style: .cancel) { _ in
                    self.configuration.setIsPresented(false)
                }
            )
        } else {
            actions.forEach(alert.addAction)
        }
        presenter.present(alert, animated: true)
    }
}

@MainActor
private final class _SwiftUIPresentationDismissBridge: @unchecked Sendable {
    var state: _OpenPresentationState

    init(state: _OpenPresentationState) {
        self.state = state
    }

    func dismiss() {
        state.dismiss()
    }
}

/// A non-generic controller gives state-driven SwiftUI presentations a stable
/// UIKit identity while their type-erased root view is updated in place.  It
/// also owns the two-way dismissal bridge used by `EnvironmentValues.dismiss`.
@MainActor
private final class _SwiftUIPresentationContainerController: UIViewController,
    UIAdaptivePresentationControllerDelegate
{
    private(set) var configuration: _OpenPresentationConfiguration
    private let dismissBridge: _SwiftUIPresentationDismissBridge
    private let contentController: UIHostingController<AnyView>
    private var attachedToNavigationStack = false

    init(configuration: _OpenPresentationConfiguration) {
        self.configuration = configuration
        let bridge = _SwiftUIPresentationDismissBridge(state: configuration.state)
        dismissBridge = bridge
        let dismiss = DismissAction { [bridge] in bridge.dismiss() }
        contentController = UIHostingController(
            rootView: configuration.makeDestination(dismiss)
        )
        super.init()
        modalPresentationStyle = configuration.kind == .sheet
            ? .pageSheet : .fullScreen
    }

    required init?(coder: NSCoder) { nil }

    func matches(_ candidate: _OpenPresentationConfiguration) -> Bool {
        configuration.kind == candidate.kind
            && configuration.identity == candidate.identity
    }

    func update(configuration: _OpenPresentationConfiguration) {
        self.configuration = configuration
        dismissBridge.state = configuration.state
        let dismiss = DismissAction { [dismissBridge] in dismissBridge.dismiss() }
        contentController.rootView = configuration.makeDestination(dismiss)
        contentController.loadViewIfNeeded()
        title = contentController.title
        navigationItem.hidesBackButton = contentController.navigationItem.hidesBackButton
        toolbarItems = contentController.toolbarItems
    }

    override func loadView() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        container.backgroundColor = .systemBackground
        container.accessibilityIdentifier = "SwiftUI.PresentationContainer"
        view = container

        addChild(contentController)
        contentController.loadViewIfNeeded()
        contentController.view.frame = container.bounds
        contentController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(contentController.view)
        contentController.didMove(toParent: self)
        title = contentController.title
        navigationItem.hidesBackButton = contentController.navigationItem.hidesBackButton
        toolbarItems = contentController.toolbarItems
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentController.viewIfLoaded?.frame = view.bounds
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if parent is UINavigationController {
            attachedToNavigationStack = true
        } else if parent == nil, attachedToNavigationStack {
            attachedToNavigationStack = false
            configuration.state.dismiss()
        }
    }

    func presentationControllerDidDismiss(
        _ presentationController: UIPresentationController
    ) {
        _ = presentationController
        configuration.state.dismiss()
    }
}

@MainActor
private final class _SwiftUIPresentationHost: UIView {
    let configuration: _OpenPresentationConfiguration

    init(configuration: _OpenPresentationConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        isHidden = true
        isUserInteractionEnabled = false
        accessibilityIdentifier = "SwiftUI.PresentationHost"
    }

    required init?(coder: NSCoder) { nil }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        synchronizePresentation()
    }

    private func synchronizePresentation() {
        guard window != nil,
              let presenter = _enclosingViewController(for: self) else { return }

        let navigationController = (presenter as? UINavigationController)
            ?? presenter.navigationController
        let modal = presenter.presentedViewController
            as? _SwiftUIPresentationContainerController
        let pushed = navigationController?.viewControllers.compactMap {
            $0 as? _SwiftUIPresentationContainerController
        }.first { $0.matches(configuration) }

        if !configuration.state.getIsPresented() {
            if let modal, modal.matches(configuration) {
                modal.dismiss(animated: true)
            } else if let pushed,
                      navigationController?.topViewController === pushed {
                navigationController?.popViewController(animated: true)
            }
            return
        }

        if let existing = (modal?.matches(configuration) == true ? modal : nil)
            ?? pushed {
            existing.update(configuration: configuration)
            return
        }

        let destination = _SwiftUIPresentationContainerController(
            configuration: configuration
        )
        switch configuration.kind {
        case .sheet:
            guard presenter.presentedViewController == nil else { return }
            presenter.present(destination, animated: true)
            destination.presentationController?.delegate = destination
        case .navigationDestination:
            if let navigationController {
                navigationController.pushViewController(destination, animated: true)
            } else {
                guard presenter.presentedViewController == nil else { return }
                presenter.present(destination, animated: true)
                destination.presentationController?.delegate = destination
            }
        }
    }
}

@MainActor
private func _openAccessibilityHost(frame: CGRect, identifier: String) -> UIView {
    let host = _SwiftUIPassthroughView(frame: frame)
    host.backgroundColor = .clear
    host.isOpaque = false
    host.isAccessibilityElement = true
    host.accessibilityElementsHidden = true
    host.accessibilityIdentifier = "SwiftUI.Accessibility\(identifier)"
    return host
}

@MainActor
private func _openMergeAccessibility(from descendants: UIView, into host: UIView) {
    func visit(_ view: UIView) {
        if host.accessibilityLabel == nil { host.accessibilityLabel = view.accessibilityLabel }
        if host.accessibilityHint == nil { host.accessibilityHint = view.accessibilityHint }
        if host.accessibilityValue == nil { host.accessibilityValue = view.accessibilityValue }
        host.accessibilityTraits.formUnion(view.accessibilityTraits)
        view.subviews.forEach(visit)
    }
    descendants.subviews.forEach(visit)
}

private func _openUIKitTraits(_ traits: AccessibilityTraits) -> UIAccessibilityTraits {
    var result: UIAccessibilityTraits = []
    if traits.contains(.isButton) { result.insert(.button) }
    if traits.contains(.isLink) { result.insert(.link) }
    if traits.contains(.isHeader) { result.insert(.header) }
    if traits.contains(.isImage) { result.insert(.image) }
    if traits.contains(.isSelected) { result.insert(.selected) }
    if traits.contains(.updatesFrequently) { result.insert(.updatesFrequently) }
    return result
}

@MainActor
private func _openMenuElements(
    in node: _OpenViewNode,
    enabled: Bool = true
) -> [UIMenuElement] {
    var sections: [[UIMenuElement]] = [[]]
    for token in _openMenuTokens(in: node, enabled: enabled) {
        switch token {
        case .divider:
            if !(sections.last?.isEmpty ?? true) { sections.append([]) }
        case .element(let element):
            sections[sections.count - 1].append(element)
        }
    }
    return sections.enumerated().flatMap { index, elements in
        guard !elements.isEmpty else { return [UIMenuElement]() }
        if index == 0 { return elements }
        return [UIMenu(options: .displayInline, children: elements)]
    }
}

@MainActor
private enum _OpenMenuToken {
    case divider
    case element(UIMenuElement)
}

@MainActor
private func _openMenuTokens(
    in node: _OpenViewNode,
    enabled: Bool
) -> [_OpenMenuToken] {
    switch node.kind {
    case .group(let children), .grid(let children, _, _), .gridRow(let children):
        return children.flatMap { _openMenuTokens(in: $0, enabled: enabled) }
    case .divider:
        return [.divider]
    case .button(let label, _, let role, let action):
        let title = _openMenuTitle(in: label) ?? "Action"
        let attributes: UIMenuElement.Attributes = !enabled
            ? .disabled
            : (role == .destructive ? .destructive : [])
        return [
            .element(UIAction(
                title: title,
                image: _openMenuImage(in: label),
                attributes: attributes
            ) { _ in action() })
        ]
    case .modified(let content, let modification):
        if case .disabled(let disabled) = modification {
            return _openMenuTokens(in: content, enabled: enabled && !disabled)
        }
        return _openMenuTokens(in: content, enabled: enabled)
    default:
        return []
    }
}

@MainActor
private func _openMenuTitle(in node: _OpenViewNode) -> String? {
    switch node.kind {
    case .text(let title): return title
    case .group(let children), .hStack(let children, _, _),
         .vStack(let children, _, _), .zStack(let children, _),
         .grid(let children, _, _), .gridRow(let children):
        return children.lazy.compactMap(_openMenuTitle).first
    case .modified(let content, _): return _openMenuTitle(in: content)
    default: return nil
    }
}

@MainActor
private func _openMenuImage(in node: _OpenViewNode) -> UIImage? {
    switch node.kind {
    case .image(.system(let name)): return UIImage(systemName: name)
    case .group(let children), .hStack(let children, _, _),
         .vStack(let children, _, _), .zStack(let children, _),
         .grid(let children, _, _), .gridRow(let children):
        return children.lazy.compactMap(_openMenuImage).first
    case .modified(let content, _): return _openMenuImage(in: content)
    default: return nil
    }
}

@MainActor
private func _openAlertActions(
    in node: _OpenViewNode,
    configuration: _OpenAlertConfiguration,
    enabled: Bool = true
) -> [UIAlertAction] {
    switch node.kind {
    case .button(let label, _, let role, let action):
        guard let title = _openMenuTitle(in: label) else { return [] }
        let style: UIAlertAction.Style
        switch role {
        case .cancel: style = .cancel
        case .destructive: style = .destructive
        case .none: style = .default
        }
        let result = UIAlertAction(title: title, style: style) { _ in
            configuration.setIsPresented(false)
            action()
        }
        result.isEnabled = enabled
        return [result]
    case .group(let children), .hStack(let children, _, _),
         .vStack(let children, _, _), .zStack(let children, _),
         .grid(let children, _, _), .gridRow(let children):
        return children.flatMap {
            _openAlertActions(in: $0, configuration: configuration, enabled: enabled)
        }
    case .modified(let content, .disabled(let disabled)):
        return _openAlertActions(
            in: content,
            configuration: configuration,
            enabled: enabled && !disabled
        )
    case .modified(let content, _):
        return _openAlertActions(in: content, configuration: configuration, enabled: enabled)
    default:
        return []
    }
}

@MainActor
private func _enclosingViewController(for view: UIView) -> UIViewController? {
    var responder: UIResponder? = view
    while let current = responder {
        if let controller = current as? UIViewController { return controller }
        responder = current.next
    }
    return nil
}

/// OpenUIKit-backed host for the SwiftUI tree and its retained dynamic state.
@preconcurrency @MainActor
open class _OpenUIHostingController<Content: _OpenView>: UIViewController {
    private let graph = _OpenGraphHost()
    private var installedRepresentedControllers: [ObjectIdentifier: UIViewController] = [:]
    private var pendingRepresentedControllerMoves: Set<ObjectIdentifier> = []
    private var appearanceTransitionChildren: Set<ObjectIdentifier> = []
    private var activeAppearanceActions: [
        _OpenAppearanceIdentity: _OpenAppearanceActions
    ] = [:]
    /// Identities whose appearance cycle has begun. This includes nodes that
    /// register only `onDisappear`, so removal and host disappearance remain
    /// paired even when there was no corresponding `onAppear` closure.
    private var visibleAppearanceIdentities: Set<_OpenAppearanceIdentity> = []
    private var hostIsVisible = false
    private var appliedRootNavigationTitle: String?
    private var appliedRootBackButtonHidden = false
    private var lastAppliedAnimation: Animation?

    public var rootView: Content {
        didSet {
            guard viewIfLoaded is _SwiftUIHostingView else { return }
            let node = evaluateRoot()
            install(node, animation: graph.evaluationAnimation)
        }
    }

    public init(rootView: Content) {
        self.rootView = rootView
        super.init()
        graph.invalidate = { [weak self] animation in
            guard let self,
                  self.viewIfLoaded is _SwiftUIHostingView else { return }
            let node = self.evaluateRoot()
            self.install(
                node,
                animation: animation ?? self.graph.evaluationAnimation
            )
        }
    }

    open override func loadView() {
        let node = evaluateRoot()
        let host = _SwiftUIHostingView(node: node)
        host.didCompleteLayout = { [weak self] in
            self?.completeRepresentedControllerMounts()
        }
        view = host
        install(node, animation: nil)
    }

    private func evaluateRoot() -> _OpenViewNode {
        let evaluated = graph.evaluate(rootView)
        let (node, configuration) = _openExtractNavigationConfiguration(evaluated)
        // Remove metadata that SwiftUI previously owned, but do not erase an
        // unrelated title/navigation-item value an embedding UIKit app set.
        if configuration.title != nil || title == appliedRootNavigationTitle {
            title = configuration.title
        }
        appliedRootNavigationTitle = configuration.title
        if configuration.backButtonHidden
            || navigationItem.hidesBackButton == appliedRootBackButtonHidden {
            navigationItem.hidesBackButton = configuration.backButtonHidden
        }
        appliedRootBackButtonHidden = configuration.backButtonHidden
        return node
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        appearanceTransitionChildren.removeAll(keepingCapacity: true)
        for (identity, controller) in installedRepresentedControllers
        where !pendingRepresentedControllerMoves.contains(identity) {
            controller.beginAppearanceTransition(true, animated: animated)
            appearanceTransitionChildren.insert(identity)
        }
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        for identity in appearanceTransitionChildren {
            installedRepresentedControllers[identity]?.endAppearanceTransition()
        }
        appearanceTransitionChildren.removeAll(keepingCapacity: true)
        hostIsVisible = true
        deliverPendingAppearActions()
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        appearanceTransitionChildren.removeAll(keepingCapacity: true)
        for (identity, controller) in installedRepresentedControllers
        where !pendingRepresentedControllerMoves.contains(identity) {
            controller.beginAppearanceTransition(false, animated: animated)
            appearanceTransitionChildren.insert(identity)
        }
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        for identity in appearanceTransitionChildren {
            installedRepresentedControllers[identity]?.endAppearanceTransition()
        }
        appearanceTransitionChildren.removeAll(keepingCapacity: true)
        hostIsVisible = false
        let disappearing = visibleAppearanceIdentities.compactMap {
            activeAppearanceActions[$0]?.disappear
        }
        visibleAppearanceIdentities.removeAll(keepingCapacity: true)
        disappearing.forEach { $0() }
    }

    private func install(_ node: _OpenViewNode, animation: Animation?) {
        guard let host = viewIfLoaded as? _SwiftUIHostingView else { return }
        let controllers = _openContainedControllers(in: node)
        let nextIdentities = Set(controllers.map(ObjectIdentifier.init))

        for (identity, controller) in installedRepresentedControllers
        where !nextIdentities.contains(identity) {
            if hostIsVisible && !pendingRepresentedControllerMoves.contains(identity) {
                controller.beginAppearanceTransition(false, animated: false)
                controller.endAppearanceTransition()
            }
            controller.willMove(toParent: nil)
            controller.viewIfLoaded?.removeFromSuperview()
            controller.removeFromParent()
            installedRepresentedControllers.removeValue(forKey: identity)
            pendingRepresentedControllerMoves.remove(identity)
            appearanceTransitionChildren.remove(identity)
        }

        for controller in controllers {
            let identity = ObjectIdentifier(controller)
            guard installedRepresentedControllers[identity] == nil else { continue }
            addChild(controller)
            installedRepresentedControllers[identity] = controller
            pendingRepresentedControllerMoves.insert(identity)
        }

        let nextAppearanceActions = _openAppearanceActions(in: node)
        if hostIsVisible {
            // A conditional branch or selected page can leave the mounted
            // graph without the hosting controller disappearing. Deliver the
            // old node's action exactly once before forgetting its closure.
            let removed = visibleAppearanceIdentities.subtracting(
                nextAppearanceActions.keys
            )
            let disappearing = removed.compactMap {
                activeAppearanceActions[$0]?.disappear
            }
            visibleAppearanceIdentities.subtract(removed)
            activeAppearanceActions = nextAppearanceActions
            disappearing.forEach { $0() }
        } else {
            activeAppearanceActions = nextAppearanceActions
            visibleAppearanceIdentities.removeAll(keepingCapacity: true)
        }
        lastAppliedAnimation = animation
        guard let animation else {
            host.node = node
            return
        }

        // Commit the rebuilt graph through OpenUIKit's deterministic
        // presentation clock. Existing represented views/controllers retain
        // identity, and structural layout changes participate in the same
        // UIView transaction as native UIKit transitions.
        host.layoutIfNeeded()
        animation.performOpenUIKitTransaction {
            host.node = node
            host.layoutIfNeeded()
        }
    }

    private func completeRepresentedControllerMounts() {
        for controller in children {
            let identity = ObjectIdentifier(controller)
            guard pendingRepresentedControllerMoves.contains(identity),
                  controller.viewIfLoaded?.superview != nil else { continue }
            controller.didMove(toParent: self)
            pendingRepresentedControllerMoves.remove(identity)
            if hostIsVisible {
                controller.beginAppearanceTransition(true, animated: false)
                controller.endAppearanceTransition()
            }
        }
        deliverPendingAppearActions()
    }

    private func deliverPendingAppearActions() {
        guard hostIsVisible else { return }
        for (key, actions) in activeAppearanceActions
        where !visibleAppearanceIdentities.contains(key) {
            // Record before invoking arbitrary app code so a synchronous graph
            // invalidation cannot deliver the same appearance twice.
            visibleAppearanceIdentities.insert(key)
            actions.appear?()
        }
    }

    // Internal behavior probes. These deliberately count graph evaluation and
    // delivered (coalesced) invalidations, not layout passes or publisher
    // sends; @testable clients use them to keep subscription semantics honest.
    var _openGraphRenderCount: Int { graph.renderCount }
    var _openGraphInvalidationCount: Int { graph.invalidationCount }
    var _openGraphStateCount: Int { graph.stateCount }
    var _openGraphObservationCount: Int { graph.observationCount }
    var _openGraphRepresentedControllerCount: Int { graph.representedControllerCount }
    var _openGraphRepresentedViewCount: Int { graph.representedViewCount }
    var _openGraphChangeCount: Int { graph.changeCount }
    var _openGraphSubscriptionCount: Int { graph.subscriptionCount }
    var _openGraphTaskCount: Int { graph.taskCount }
    var _openGraphLastAppliedAnimation: Animation? { lastAppliedAnimation }
}

public typealias UIHostingController<Content> = _OpenUIHostingController<Content>
    where Content: _OpenView

@MainActor
private func _openSelectedTabPage(
    pages: [_OpenTabPage],
    selection: AnyHashable
) -> (index: Int, page: _OpenTabPage)? {
    guard !pages.isEmpty else { return nil }
    let index = pages.firstIndex { $0.tag == selection } ?? 0
    return (index, pages[index])
}

@MainActor
private func _openContainedControllers(in root: _OpenViewNode) -> [UIViewController] {
    var result: [UIViewController] = []
    var identities: Set<ObjectIdentifier> = []

    func visit(_ node: _OpenViewNode) {
        switch node.kind {
        case .view:
            break
        case .viewController(let controller):
            if identities.insert(ObjectIdentifier(controller)).inserted {
                result.append(controller)
            }
        case .group(let children), .hStack(let children, _, _),
             .vStack(let children, _, _), .zStack(let children, _),
             .form(let children), .list(let children),
             .customLayout(_, let children), .grid(let children, _, _),
             .gridRow(let children):
            children.forEach(visit)
        case .section(let header, let footer, let rows):
            if let header { visit(header) }
            if let footer { visit(footer) }
            rows.forEach(visit)
        case .button(let label, let pressedLabel, _, _):
            visit(label)
            if let pressedLabel { visit(pressedLabel) }
        case .menu(let label, let pressedLabel, let content):
            visit(label)
            if let pressedLabel { visit(pressedLabel) }
            visit(content)
        case .geometry(let geometry):
            visit(geometry.resolve(CGSize(width: 390, height: 844)))
        case .scroll(let label), .scrollReader(let label, _),
             .navigationLink(let label, _), .link(let label, _),
             .toggle(let label, _, _):
            visit(label)
        case .picker(let label, let options, _, _):
            visit(label)
            options.forEach { visit($0.content) }
        case .tabView(let pages, let selection, _, _):
            if let selected = _openSelectedTabPage(pages: pages, selection: selection) {
                visit(selected.page.content)
            }
        case .navigation(let content, let configuration):
            visit(content)
            if let toolbar = configuration.toolbar { visit(toolbar) }
        case .modified(let content, let modification):
            visit(content)
            switch modification {
            case .background(let auxiliary, _), .overlay(let auxiliary, _),
                 .mask(let auxiliary, _), .toolbar(let auxiliary),
                 .contextMenu(let auxiliary), .safeAreaInset(_, _, let auxiliary),
                 .swipeActions(_, _, let auxiliary), .listRowBackground(let auxiliary):
                visit(auxiliary)
            case .alert(let configuration):
                visit(configuration.actions)
                visit(configuration.message)
            default:
                break
            }
        case .empty, .text, .image, .color, .roundedRectangle, .capsule,
             .divider, .progress, .slider, .spacer, .textField, .gradient:
            break
        }
    }

    visit(root)
    return result
}

@MainActor
private func _openContainedViews(in root: _OpenViewNode) -> [UIView] {
    var result: [UIView] = []
    var identities: Set<ObjectIdentifier> = []

    func visit(_ node: _OpenViewNode) {
        switch node.kind {
        case .view(let view):
            if identities.insert(ObjectIdentifier(view)).inserted {
                result.append(view)
            }
        case .group(let children), .hStack(let children, _, _),
             .vStack(let children, _, _), .zStack(let children, _),
             .form(let children), .list(let children),
             .customLayout(_, let children), .grid(let children, _, _),
             .gridRow(let children):
            children.forEach(visit)
        case .section(let header, let footer, let rows):
            if let header { visit(header) }
            if let footer { visit(footer) }
            rows.forEach(visit)
        case .button(let label, let pressedLabel, _, _):
            visit(label)
            if let pressedLabel { visit(pressedLabel) }
        case .menu(let label, let pressedLabel, let content):
            visit(label)
            if let pressedLabel { visit(pressedLabel) }
            visit(content)
        case .geometry(let geometry):
            visit(geometry.resolve(CGSize(width: 390, height: 844)))
        case .scroll(let label), .scrollReader(let label, _),
             .navigationLink(let label, _), .link(let label, _),
             .toggle(let label, _, _):
            visit(label)
        case .picker(let label, let options, _, _):
            visit(label)
            options.forEach { visit($0.content) }
        case .tabView(let pages, let selection, _, _):
            if let selected = _openSelectedTabPage(pages: pages, selection: selection) {
                visit(selected.page.content)
            }
        case .navigation(let content, let configuration):
            visit(content)
            if let toolbar = configuration.toolbar { visit(toolbar) }
        case .modified(let content, let modification):
            visit(content)
            switch modification {
            case .background(let auxiliary, _), .overlay(let auxiliary, _),
                 .mask(let auxiliary, _), .toolbar(let auxiliary),
                 .contextMenu(let auxiliary), .safeAreaInset(_, _, let auxiliary),
                 .swipeActions(_, _, let auxiliary), .listRowBackground(let auxiliary):
                visit(auxiliary)
            case .alert(let configuration):
                visit(configuration.actions)
                visit(configuration.message)
            default:
                break
            }
        case .empty, .text, .image, .color, .roundedRectangle, .capsule,
             .divider, .progress, .slider, .spacer, .textField,
             .viewController, .gradient:
            break
        }
    }

    visit(root)
    return result
}

@MainActor
private func _openAppearanceActions(
    in root: _OpenViewNode
) -> [_OpenAppearanceIdentity: _OpenAppearanceActions] {
    var result: [_OpenAppearanceIdentity: _OpenAppearanceActions] = [:]

    func visit(_ node: _OpenViewNode) {
        switch node.kind {
        case .group(let children), .hStack(let children, _, _),
             .vStack(let children, _, _), .zStack(let children, _),
             .form(let children), .list(let children),
             .customLayout(_, let children), .grid(let children, _, _),
             .gridRow(let children):
            children.forEach(visit)
        case .section(let header, let footer, let rows):
            if let header { visit(header) }
            if let footer { visit(footer) }
            rows.forEach(visit)
        case .button(let label, let pressedLabel, _, _):
            visit(label)
            if let pressedLabel { visit(pressedLabel) }
        case .menu(let label, let pressedLabel, let content):
            visit(label)
            if let pressedLabel { visit(pressedLabel) }
            visit(content)
        case .geometry(let geometry):
            visit(geometry.resolve(CGSize(width: 390, height: 844)))
        case .scroll(let label), .scrollReader(let label, _),
             .navigationLink(let label, _), .link(let label, _),
             .toggle(let label, _, _):
            visit(label)
        case .picker(let label, let options, _, _):
            visit(label)
            options.forEach { visit($0.content) }
        case .tabView(let pages, let selection, _, _):
            if let selected = _openSelectedTabPage(pages: pages, selection: selection) {
                visit(selected.page.content)
            }
        case .navigation(let content, let configuration):
            visit(content)
            if let toolbar = configuration.toolbar { visit(toolbar) }
        case .modified(let content, let modification):
            if case .onAppear(let identity, let action) = modification {
                let key = identity.map(_OpenAppearanceIdentity.graph)
                    ?? .ephemeral(ObjectIdentifier(node))
                result[key] = _OpenAppearanceActions(
                    appear: action,
                    disappear: nil
                )
            }
            if case .onDisappear(let identity, let action) = modification {
                let key = identity.map(_OpenAppearanceIdentity.graph)
                    ?? .ephemeral(ObjectIdentifier(node))
                result[key] = _OpenAppearanceActions(
                    appear: nil,
                    disappear: action
                )
            }
            visit(content)
            switch modification {
            case .background(let auxiliary, _), .overlay(let auxiliary, _),
                 .mask(let auxiliary, _), .toolbar(let auxiliary),
                 .contextMenu(let auxiliary), .safeAreaInset(_, _, let auxiliary),
                 .swipeActions(_, _, let auxiliary), .listRowBackground(let auxiliary):
                visit(auxiliary)
            case .alert(let configuration):
                visit(configuration.actions)
                visit(configuration.message)
            default:
                break
            }
        case .empty, .text, .image, .color, .roundedRectangle, .capsule,
             .divider, .progress, .slider, .spacer, .textField,
             .view, .viewController, .gradient:
            break
        }
    }

    visit(root)
    return result
}

@MainActor
private final class _SwiftUIHostingView: UIView {
    var didCompleteLayout: (@MainActor () -> Void)?
    var node: _OpenViewNode {
        didSet { setNeedsLayout() }
    }

    init(node: _OpenViewNode) {
        self.node = node
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Park retained represented views on the host before rebuilding the
        // lightweight structural wrappers. Reparenting within one window does
        // not synthesize didMoveToWindow(nil/current) pairs, so a stable
        // UIViewRepresentable receives one real mount callback rather than a
        // callback on every SwiftUI layout pass.
        let representedViews = _openContainedViews(in: node)
        let representedIdentities = Set(representedViews.map(ObjectIdentifier.init))
        for representedView in representedViews where representedView.superview !== self {
            addSubview(representedView)
        }
        for child in subviews
        where !representedIdentities.contains(ObjectIdentifier(child)) {
            child.removeFromSuperview()
        }
        clipsToBounds = false
        layer.cornerRadius = 0
        _ViewRenderer.place(node, in: bounds, on: self, environment: .default)
        didCompleteLayout?()
    }

    override var intrinsicContentSize: CGSize {
        _ViewRenderer.measure(
            node,
            proposed: CGSize(width: 10_000, height: 10_000),
            environment: .default
        )
    }
}

private struct _RenderEnvironment {
    var font: _OpenFont? = .body
    var weight: _OpenFont.Weight?
    var minimumScaleFactor: CGFloat = 0
    var allowsTightening = false
    var foregroundColor: _OpenColor?
    var tintColor: _OpenColor?
    var textAlignment: _OpenTextAlignment = .leading
    var lineLimit: Int?
    var lineLimitRange: ClosedRange<Int>?
    var imageResizable = false
    var imageContentMode: _OpenContentMode = .fit
    var imageScale: ImageScale = .medium
    var measuresUnboundedVerticalScroll = false
    var simultaneousTapActions: [@MainActor () -> Void] = []
    var isEnabled = true
    var focus: (
        get: @MainActor () -> Bool,
        set: @MainActor (Bool) -> Void
    )?
    var textContentType: UITextContentType?
    var autocapitalizationType: UITextAutocapitalizationType = .sentences
    var autocorrectionDisabled = false
    var submitAction: (@MainActor () -> Void)?
    var submitLabel: SubmitLabel = .return
    var keyboardDismissMode: ScrollDismissesKeyboardMode = .automatic
    var controlSize: ControlSize = .regular
    var usesCircularProgressStyle = true
    var usesMenuPickerStyle = false
    var symbolRenderingMode: SymbolRenderingMode?
    var scrollStorage: _OpenScrollProxyStorage?
    var scrollVisibilityObservers: [_OpenScrollVisibilityObserver] = []
    var scrollGeometryObservers: [_OpenScrollGeometryObserver] = []
    var refreshAction: (@MainActor () async -> Void)?
    var scrollIndicatorVisibility: Visibility = .automatic
    var listStyle: ListStyle = .automatic
    var menuIndicatorVisibility: Visibility = .automatic

    static let `default` = _RenderEnvironment()
}

@MainActor
private func _openInstallGesture(_ gesture: _OpenGestureNode, on host: UIView) {
    switch gesture.kind {
    case .tap(let action):
        host.addGestureRecognizer(
            UITapGestureRecognizer { recognizer in
                if recognizer.state == .ended { action() }
            }
        )
    case .longPress(let minimumDuration, let action):
        let recognizer = UILongPressGestureRecognizer { recognizer in
            if recognizer.state == .began { action(true) }
        }
        recognizer.minimumPressDuration = minimumDuration
        host.addGestureRecognizer(recognizer)
    case .drag(let minimumDistance, let coordinateSpace, let changed, let ended):
        var start = CGPoint.zero
        let recognizer = UIPanGestureRecognizer { recognizer in
            guard let pan = recognizer as? UIPanGestureRecognizer else { return }
            let coordinateView: UIView? = coordinateSpace == .global ? nil : host
            let location = pan.location(in: coordinateView)
            if pan.state == .began {
                let translation = pan.translation(in: coordinateView)
                start = CGPoint(
                    x: location.x - translation.x,
                    y: location.y - translation.y
                )
            }
            let velocityPoint = pan.velocity(in: coordinateView)
            let value = DragGesture.Value(
                location: location,
                startLocation: start,
                velocity: CGSize(width: velocityPoint.x, height: velocityPoint.y)
            )
            switch pan.state {
            case .began, .changed: changed(value)
            case .ended: ended(value)
            default: break
            }
        }
        recognizer.activationDistance = max(0, minimumDistance)
        host.addGestureRecognizer(recognizer)
    }
}

@MainActor
private func _openReducedPreference(
    in root: _OpenViewNode,
    listener: _OpenPreferenceListener,
    proposed: CGSize
) -> Any {
    var result = listener.defaultValue

    func visit(_ node: _OpenViewNode) {
        switch node.kind {
        case .group(let children), .hStack(let children, _, _),
             .vStack(let children, _, _), .zStack(let children, _),
             .form(let children), .list(let children),
             .customLayout(_, let children), .grid(let children, _, _),
             .gridRow(let children):
            children.forEach(visit)
        case .section(let header, let footer, let rows):
            if let header { visit(header) }
            rows.forEach(visit)
            if let footer { visit(footer) }
        case .button(let label, let pressed, _, _):
            visit(label)
            if let pressed { visit(pressed) }
        case .menu(let label, let pressed, let content):
            visit(label)
            if let pressed { visit(pressed) }
            visit(content)
        case .geometry(let geometry):
            visit(geometry.resolve(proposed))
        case .scroll(let content), .scrollReader(let content, _),
             .navigationLink(let content, _), .link(let content, _),
             .toggle(let content, _, _):
            visit(content)
        case .tabView(let pages, _, _, _):
            pages.forEach { visit($0.content) }
        case .picker(let label, let options, _, _):
            visit(label)
            options.forEach { visit($0.content) }
        case .navigation(let content, let configuration):
            visit(content)
            if let toolbar = configuration.toolbar { visit(toolbar) }
        case .modified(let content, let modification):
            visit(content)
            switch modification {
            case .preference(let record) where record.key == listener.key:
                listener.reduce(&result, record.value)
            case .background(let auxiliary, _), .overlay(let auxiliary, _),
                 .mask(let auxiliary, _), .toolbar(let auxiliary),
                 .contextMenu(let auxiliary), .safeAreaInset(_, _, let auxiliary),
                 .swipeActions(_, _, let auxiliary), .listRowBackground(let auxiliary):
                visit(auxiliary)
            case .alert(let configuration):
                visit(configuration.actions)
                visit(configuration.message)
            default: break
            }
        case .empty, .text, .image, .color, .roundedRectangle, .capsule,
             .divider, .progress, .slider, .spacer, .view,
             .viewController, .textField,
             .gradient:
            break
        }
    }

    visit(root)
    return result
}

@MainActor
private enum _ViewRenderer {
    static let defaultSpacing: CGFloat = 8
    static let defaultFormRowHeight: CGFloat = 44
    static let navigationBarHeight: CGFloat = 52
    static let toggleSize = CGSize(width: 63, height: 28)

    static func measure(
        _ node: _OpenViewNode,
        proposed: CGSize,
        environment: _RenderEnvironment
    ) -> CGSize {
        switch node.kind {
        case .empty:
            return .zero
        case .group(let children):
            return children.reduce(into: CGSize.zero) { result, child in
                let size = measure(child, proposed: proposed, environment: environment)
                result.width = max(result.width, size.width)
                result.height = max(result.height, size.height)
            }
        case .text(let string):
            let label = makeLabel(string, environment: environment)
            return label.sizeThatFits(_bounded(proposed))
        case .image(let source):
            return measureImage(source, proposed: proposed, environment: environment)
        case .color, .roundedRectangle, .capsule:
            return _bounded(proposed)
        case .divider:
            return CGSize(width: _bounded(proposed).width, height: 1)
        case .progress:
            let extent = _controlExtent(environment.controlSize)
            return CGSize(width: extent, height: extent)
        case .slider:
            return CGSize(width: max(100, _bounded(proposed).width), height: 34)
        case .spacer(let minLength):
            let value = max(0, minLength ?? 0)
            return CGSize(width: value, height: value)
        case .hStack(let children, _, let spacing):
            let gap = spacing ?? defaultSpacing
            var width = gap * CGFloat(max(0, children.count - 1))
            var height: CGFloat = 0
            for child in children {
                let size = measure(child, proposed: proposed, environment: environment)
                width += size.width
                height = max(height, size.height)
            }
            if children.contains(where: _isSpacer) {
                width = max(width, _bounded(proposed).width)
            }
            return CGSize(width: width, height: height)
        case .vStack(let children, _, let spacing):
            let gap = spacing ?? defaultSpacing
            var width: CGFloat = 0
            var height = gap * CGFloat(max(0, children.count - 1))
            for child in children {
                let size = measure(child, proposed: proposed, environment: environment)
                width = max(width, size.width)
                height += size.height
            }
            if children.contains(where: _isSpacer)
                && !environment.measuresUnboundedVerticalScroll {
                height = max(height, _bounded(proposed).height)
            }
            return CGSize(width: width, height: height)
        case .zStack(let children, _):
            return children.reduce(into: CGSize.zero) { result, child in
                let size = measure(child, proposed: proposed, environment: environment)
                result.width = max(result.width, size.width)
                result.height = max(result.height, size.height)
            }
        case .grid(let rows, let horizontalSpacing, let verticalSpacing):
            return gridLayout(
                rows,
                horizontalSpacing: horizontalSpacing ?? defaultSpacing,
                verticalSpacing: verticalSpacing ?? defaultSpacing,
                proposed: proposed,
                environment: environment
            ).size
        case .gridRow(let cells):
            let gap = defaultSpacing * CGFloat(max(0, cells.count - 1))
            let sizes = cells.map {
                measure($0, proposed: proposed, environment: environment)
            }
            return CGSize(
                width: sizes.reduce(gap) { $0 + $1.width },
                height: sizes.map(\.height).max() ?? 0
            )
        case .button(let label, _, _, _):
            return measure(label, proposed: proposed, environment: environment)
        case .menu(let label, _, _):
            return measure(label, proposed: proposed, environment: environment)
        case .geometry(let geometry):
            let viewport = _bounded(proposed)
            _ = measure(
                geometry.resolve(viewport),
                proposed: viewport,
                environment: environment
            )
            return viewport
        case .scroll(let content):
            let viewport = _bounded(proposed)
            var next = environment
            next.measuresUnboundedVerticalScroll = true
            let contentSize = measure(
                content,
                proposed: viewport,
                environment: next
            )
            return CGSize(
                width: max(viewport.width, min(contentSize.width, 10_000)),
                height: viewport.height
            )
        case .scrollReader(let content, _):
            return measure(content, proposed: proposed, environment: environment)
        case .customLayout(let layout, let children):
            var cache: () = ()
            return layout.sizeThatFits(
                proposal: ProposedViewSize(width: proposed.width, height: proposed.height),
                subviews: makeLayoutSubviews(children, environment: environment),
                cache: &cache
            )
        case .tabView(let pages, let selection, _, let indexDisplayMode):
            guard let selected = _openSelectedTabPage(
                pages: pages,
                selection: selection
            ) else { return .zero }
            let indicatorHeight = _pageIndicatorHeight(
                pageCount: pages.count,
                indexDisplayMode: indexDisplayMode
            )
            let childProposal = CGSize(
                width: proposed.width,
                height: max(0, proposed.height - indicatorHeight)
            )
            let child = measure(
                selected.page.content,
                proposed: childProposal,
                environment: environment
            )
            return CGSize(width: child.width, height: child.height + indicatorHeight)
        case .view(let view):
            return view.sizeThatFits(_bounded(proposed))
        case .viewController(let controller):
            controller.loadViewIfNeeded()
            return controller.view.sizeThatFits(_bounded(proposed))
        case .form(let rows):
            var width: CGFloat = 0
            var height: CGFloat = 0
            let rowProposal = CGSize(
                width: _bounded(proposed).width,
                height: defaultFormRowHeight
            )
            for row in rows {
                let size = measure(row, proposed: rowProposal, environment: environment)
                width = max(width, size.width)
                height += max(defaultFormRowHeight, size.height)
            }
            return CGSize(width: width, height: height)
        case .section(let header, let footer, let rows):
            let bounded = _bounded(proposed)
            let headerHeight: CGFloat = header == nil ? 12 : 28
            var height = headerHeight
            for row in rows {
                let size = measure(
                    row,
                    proposed: CGSize(width: bounded.width, height: defaultFormRowHeight),
                    environment: environment
                )
                height += max(defaultFormRowHeight, size.height)
            }
            let footerHeight: CGFloat = footer == nil ? 12 : 28
            return CGSize(width: bounded.width, height: height + footerHeight)
        case .toggle(let label, _, _):
            let labelSize = measure(label, proposed: proposed, environment: environment)
            return CGSize(
                width: min(_bounded(proposed).width, labelSize.width + 75),
                height: max(defaultFormRowHeight, labelSize.height, toggleSize.height)
            )
        case .textField(_, _, _, let axis, _):
            guard axis == .vertical else {
                return CGSize(width: _bounded(proposed).width, height: 34)
            }
            let lines = max(1, environment.lineLimitRange?.lowerBound ?? 1)
            let maximum = max(lines, environment.lineLimitRange?.upperBound
                ?? environment.lineLimit ?? lines)
            let desired = min(maximum, lines)
            let font = (environment.font ?? .body).resolve(weight: environment.weight)
            return CGSize(
                width: _bounded(proposed).width,
                height: max(34, font.lineHeight * CGFloat(desired) + 16)
            )
        case .picker(let label, let options, let selection, _):
            let labelSize = measure(label, proposed: proposed, environment: environment)
            let selectedSize = options.first(where: { $0.tag == selection }).map {
                measure($0.content, proposed: proposed, environment: environment)
            } ?? .zero
            return CGSize(
                width: min(
                    _bounded(proposed).width,
                    labelSize.width + selectedSize.width + 32
                ),
                height: max(defaultFormRowHeight, labelSize.height, selectedSize.height)
            )
        case .list(let rows):
            let viewport = _bounded(proposed)
            var height: CGFloat = 0
            let rowProposal = CGSize(
                width: max(0, viewport.width - 32),
                height: defaultFormRowHeight
            )
            for row in rows {
                let size = measure(row, proposed: rowProposal, environment: environment)
                height += max(defaultFormRowHeight, size.height)
            }
            return CGSize(width: viewport.width, height: min(viewport.height, height))
        case .navigationLink(let label, _):
            return measure(label, proposed: proposed, environment: environment)
        case .link(let label, _):
            return measure(label, proposed: proposed, environment: environment)
        case .navigation(let content, let configuration):
            let hasBarContent = configuration.title != nil || configuration.toolbar != nil
            let barHeight = configuration.barHidden || !hasBarContent ? 0 : navigationBarHeight
            let childProposal = CGSize(
                width: proposed.width,
                height: max(0, proposed.height - barHeight)
            )
            let child = measure(content, proposed: childProposal, environment: environment)
            return CGSize(width: child.width, height: child.height + barHeight)
        case .gradient:
            return _bounded(proposed)
        case .modified(let content, let modification):
            switch modification {
            case .font(let font):
                var next = environment
                next.font = font
                return measure(content, proposed: proposed, environment: next)
            case .fontWeight(let weight):
                var next = environment
                next.weight = weight
                return measure(content, proposed: proposed, environment: next)
            case .minimumScaleFactor(let factor):
                var next = environment
                next.minimumScaleFactor = factor
                return measure(content, proposed: proposed, environment: next)
            case .allowsTightening(let flag):
                var next = environment
                next.allowsTightening = flag
                return measure(content, proposed: proposed, environment: next)
            case .foregroundColor(let color):
                var next = environment
                next.foregroundColor = color
                return measure(content, proposed: proposed, environment: next)
            case .tint(let color):
                var next = environment
                next.tintColor = color
                return measure(content, proposed: proposed, environment: next)
            case .lineLimit(let limit):
                var next = environment
                next.lineLimit = limit
                next.lineLimitRange = nil
                return measure(content, proposed: proposed, environment: next)
            case .lineLimitRange(let range):
                var next = environment
                next.lineLimit = max(0, range.upperBound)
                next.lineLimitRange = range
                return measure(content, proposed: proposed, environment: next)
            case .truncationMode:
                return measure(content, proposed: proposed, environment: environment)
            case .fixedSize(let horizontal, let vertical):
                return measure(
                    content,
                    proposed: CGSize(
                        width: horizontal ? 10_000 : proposed.width,
                        height: vertical ? 10_000 : proposed.height
                    ),
                    environment: environment
                )
            case .focus(let get, let set):
                var next = environment
                next.focus = (get, set)
                return measure(content, proposed: proposed, environment: next)
            case .textContentType(let type):
                var next = environment
                next.textContentType = type
                return measure(content, proposed: proposed, environment: next)
            case .autocapitalization(let type):
                var next = environment
                next.autocapitalizationType = type
                return measure(content, proposed: proposed, environment: next)
            case .autocorrectionDisabled(let disabled):
                var next = environment
                next.autocorrectionDisabled = disabled
                return measure(content, proposed: proposed, environment: next)
            case .submit(let action):
                var next = environment
                next.submitAction = action
                return measure(content, proposed: proposed, environment: next)
            case .scrollDismissesKeyboard(let mode):
                var next = environment
                next.keyboardDismissMode = mode
                return measure(content, proposed: proposed, environment: next)
            case .controlSize(let size):
                var next = environment
                next.controlSize = size
                return measure(content, proposed: proposed, environment: next)
            case .imageScale(let scale):
                var next = environment
                next.imageScale = scale
                return measure(content, proposed: proposed, environment: next)
            case .circularProgressStyle:
                var next = environment
                next.usesCircularProgressStyle = true
                return measure(content, proposed: proposed, environment: next)
            case .menuPickerStyle:
                var next = environment
                next.usesMenuPickerStyle = true
                return measure(content, proposed: proposed, environment: next)
            case .menuIndicator(let visibility):
                var next = environment
                next.menuIndicatorVisibility = visibility
                return measure(content, proposed: proposed, environment: next)
            case .symbolRenderingMode(let mode):
                var next = environment
                next.symbolRenderingMode = mode
                return measure(content, proposed: proposed, environment: next)
            case .resizable:
                var next = environment
                next.imageResizable = true
                return measure(content, proposed: proposed, environment: next)
            case .aspectRatio(let ratio, let contentMode):
                var next = environment
                next.imageContentMode = contentMode
                if let ratio {
                    return aspectSize(
                        ratio: ratio,
                        contentMode: contentMode,
                        proposed: _bounded(proposed)
                    )
                }
                return measure(content, proposed: proposed, environment: next)
            case .frame(let width, let height, _):
                let childProposal = CGSize(
                    width: width ?? proposed.width,
                    height: height ?? proposed.height
                )
                let child = measure(content, proposed: childProposal, environment: environment)
                return CGSize(width: width ?? child.width, height: height ?? child.height)
            case .flexibleFrame(
                let minWidth,
                let maxWidth,
                let minHeight,
                let maxHeight,
                _
            ):
                let proposedWidth = _flexibleProposal(proposed.width, maximum: maxWidth)
                let proposedHeight = _flexibleProposal(proposed.height, maximum: maxHeight)
                let child = measure(
                    content,
                    proposed: CGSize(width: proposedWidth, height: proposedHeight),
                    environment: environment
                )
                return CGSize(
                    width: _flexibleExtent(
                        child.width,
                        proposed: proposed.width,
                        minimum: minWidth,
                        maximum: maxWidth
                    ),
                    height: _flexibleExtent(
                        child.height,
                        proposed: proposed.height,
                        minimum: minHeight,
                        maximum: maxHeight
                    )
                )
            case .padding(let edges, let length):
                let amount = max(0, length ?? 16)
                let horizontal = (edges.contains(.leading) ? amount : 0)
                    + (edges.contains(.trailing) ? amount : 0)
                let vertical = (edges.contains(.top) ? amount : 0)
                    + (edges.contains(.bottom) ? amount : 0)
                let inner = CGSize(
                    width: max(0, proposed.width - horizontal),
                    height: max(0, proposed.height - vertical)
                )
                let size = measure(content, proposed: inner, environment: environment)
                return CGSize(width: size.width + horizontal, height: size.height + vertical)
            case .edgeInsetsPadding(let insets):
                let horizontal = max(0, insets.leading) + max(0, insets.trailing)
                let vertical = max(0, insets.top) + max(0, insets.bottom)
                let inner = CGSize(
                    width: max(0, proposed.width - horizontal),
                    height: max(0, proposed.height - vertical)
                )
                let size = measure(content, proposed: inner, environment: environment)
                return CGSize(width: size.width + horizontal, height: size.height + vertical)
            case .background:
                return measure(content, proposed: proposed, environment: environment)
            case .listRowBackground:
                return measure(content, proposed: proposed, environment: environment)
            case .overlay:
                return measure(content, proposed: proposed, environment: environment)
            case .mask:
                return measure(content, proposed: proposed, environment: environment)
            case .multilineTextAlignment(let alignment):
                var next = environment
                next.textAlignment = alignment
                return measure(content, proposed: proposed, environment: next)
            case .tapAction, .simultaneousTapAction, .gesture, .onAppear,
                 .onDisappear,
                 .shadow, .colorScheme, .safeAreaIgnored, .opacity,
                 .scaleEffect, .layoutPriority, .accessibilityElement,
                 .accessibilityLabel, .accessibilityHint, .accessibilityValue,
                 .accessibilityTraits, .allowsHitTesting, .zIndex,
                 .glassEffect, .contextMenu, .matchedGeometry,
                 .accessibilityIdentifier, .alert, .presentation, .clipped, .hidden,
                 .submitLabel, .buttonBorderShape, .accessibilityAction,
                 .identifier, .preference, .preferenceListener,
                 .scrollVisibility, .scrollGeometry, .geometryObserver,
                 .refreshable, .scrollIndicators, .toolbarVisibility,
                 .toolbarBackgroundVisibility, .swipeActions,
                 .listRowSeparator, .searchToolbarBehavior, .projection:
                return measure(content, proposed: proposed, environment: environment)
            case .listStyle(let style):
                var next = environment
                next.listStyle = style
                return measure(content, proposed: proposed, environment: next)
            case .searchable:
                // The search field occupies the content's existing viewport;
                // placement reserves its height during rendering.
                return measure(content, proposed: proposed, environment: environment)
            case .safeAreaInset(let edge, let spacing, let insetContent):
                let body = measure(content, proposed: proposed, environment: environment)
                let inset = measure(
                    insetContent,
                    proposed: proposed,
                    environment: environment
                )
                let gap = max(0, spacing ?? 0)
                if edge == .top || edge == .bottom {
                    return CGSize(
                        width: max(body.width, inset.width),
                        height: body.height + inset.height + gap
                    )
                }
                return CGSize(
                    width: body.width + inset.width + gap,
                    height: max(body.height, inset.height)
                )
            case .previewLayout:
                return measure(content, proposed: proposed, environment: environment)
            case .clipRoundedRectangle:
                return measure(content, proposed: proposed, environment: environment)
            case .disabled(let disabled):
                var next = environment
                next.isEnabled = environment.isEnabled && !disabled
                return measure(content, proposed: proposed, environment: next)
            case .accessibilityHidden:
                return measure(content, proposed: proposed, environment: environment)
            case .effect, .navigationTitle, .navigationBarHidden,
                 .navigationBackButtonHidden, .navigationTitleDisplayMode,
                 .toolbar, .tag, .pageTabViewStyle:
                return measure(content, proposed: proposed, environment: environment)
            }
        }
    }

    private static func makeLayoutSubviews(
        _ children: [_OpenViewNode],
        environment: _RenderEnvironment
    ) -> LayoutSubviews {
        LayoutSubviews(children.enumerated().map { index, child in
            let placement = _OpenLayoutPlacement()
            return LayoutSubview(
                id: AnyHashable(index),
                measure: { proposal in
                    let size = proposal.replacingUnspecifiedDimensions(
                        by: CGSize(width: 10_000, height: 10_000)
                    )
                    return measure(child, proposed: size, environment: environment)
                },
                placement: placement
            )
        })
    }

    private struct _GridLayout {
        let cells: [[_OpenViewNode]]
        let columnWidths: [CGFloat]
        let rowHeights: [CGFloat]
        let horizontalSpacing: CGFloat
        let verticalSpacing: CGFloat
        let size: CGSize
    }

    /// SwiftUI grids establish a shared column table across every GridRow.
    /// The portable renderer gives each column an equal share of a finite
    /// proposal, then derives row heights from the tallest cell at that
    /// width. Ragged rows preserve their leading columns rather than being
    /// flattened into an unrelated HStack.
    private static func gridLayout(
        _ rows: [_OpenViewNode],
        horizontalSpacing: CGFloat,
        verticalSpacing: CGFloat,
        proposed: CGSize,
        environment: _RenderEnvironment
    ) -> _GridLayout {
        let cells = rows.map { row -> [_OpenViewNode] in
            if case .gridRow(let cells) = row.kind { return cells }
            return [row]
        }
        let count = cells.map(\.count).max() ?? 0
        guard count > 0 else {
            return _GridLayout(
                cells: cells,
                columnWidths: [],
                rowHeights: Array(repeating: 0, count: cells.count),
                horizontalSpacing: horizontalSpacing,
                verticalSpacing: verticalSpacing,
                size: .zero
            )
        }

        let bounded = _bounded(proposed)
        let horizontalGaps = max(0, horizontalSpacing) * CGFloat(count - 1)
        let available = max(0, bounded.width - horizontalGaps)
        let columnWidth = available / CGFloat(count)
        let columnWidths = Array(repeating: columnWidth, count: count)
        let rowHeights = cells.map { row in
            row.map { cell in
                measure(
                    cell,
                    proposed: CGSize(width: columnWidth, height: bounded.height),
                    environment: environment
                ).height
            }.max() ?? 0
        }
        let verticalGaps = max(0, verticalSpacing) * CGFloat(max(0, cells.count - 1))
        return _GridLayout(
            cells: cells,
            columnWidths: columnWidths,
            rowHeights: rowHeights,
            horizontalSpacing: max(0, horizontalSpacing),
            verticalSpacing: max(0, verticalSpacing),
            size: CGSize(
                width: bounded.width,
                height: rowHeights.reduce(verticalGaps, +)
            )
        )
    }

    private static func placeGrid(
        _ rows: [_OpenViewNode],
        horizontalSpacing: CGFloat,
        verticalSpacing: CGFloat,
        in rect: CGRect,
        on surface: UIView,
        environment: _RenderEnvironment
    ) {
        let layout = gridLayout(
            rows,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing,
            proposed: rect.size,
            environment: environment
        )
        var y = rect.minY
        for rowIndex in layout.cells.indices {
            var x = rect.minX
            let rowHeight = min(
                layout.rowHeights[rowIndex],
                max(0, rect.maxY - y)
            )
            for columnIndex in layout.cells[rowIndex].indices {
                guard layout.columnWidths.indices.contains(columnIndex) else { break }
                let width = layout.columnWidths[columnIndex]
                place(
                    layout.cells[rowIndex][columnIndex],
                    in: CGRect(x: x, y: y, width: width, height: rowHeight),
                    on: surface,
                    environment: environment
                )
                x += width + layout.horizontalSpacing
            }
            y += rowHeight + layout.verticalSpacing
        }
    }

    private static func aspectSize(
        ratio: CGFloat,
        contentMode: ContentMode,
        proposed: CGSize
    ) -> CGSize {
        guard ratio.isFinite, ratio > 0 else { return proposed }
        let widthBound = CGSize(width: proposed.width, height: proposed.width / ratio)
        let heightBound = CGSize(width: proposed.height * ratio, height: proposed.height)
        switch contentMode {
        case .fit:
            return widthBound.height <= proposed.height ? widthBound : heightBound
        case .fill:
            return widthBound.height >= proposed.height ? widthBound : heightBound
        }
    }

    static func place(
        _ node: _OpenViewNode,
        in rect: CGRect,
        on surface: UIView,
        environment: _RenderEnvironment
    ) {
        switch node.kind {
        case .empty:
            return
        case .group(let children):
            for child in children {
                place(child, in: rect, on: surface, environment: environment)
            }
        case .text(let string):
            let label = makeLabel(string, environment: environment)
            label.frame = rect
            label.accessibilityIdentifier = "SwiftUI.Text"
            surface.addSubview(label)
        case .image(let source):
            placeImage(source, in: rect, on: surface, environment: environment)
        case .color(let color):
            let view = UIView(frame: rect)
            view.backgroundColor = color.resolve()
            view.isUserInteractionEnabled = false
            view.accessibilityIdentifier = "SwiftUI.Color"
            surface.addSubview(view)
        case .roundedRectangle(let cornerRadius, let style):
            let view = UIView(frame: rect)
            view.isUserInteractionEnabled = false
            view.layer.cornerRadius = max(0, cornerRadius)
            switch style {
            case .fill(let color):
                view.backgroundColor = (color ?? environment.foregroundColor ?? .black).resolve()
                view.accessibilityIdentifier = "SwiftUI.RoundedRectangle.fill"
            case .stroke(let color, let lineWidth):
                view.backgroundColor = .clear
                view.layer.borderWidth = max(0, lineWidth)
                view.layer.borderColor = color.resolve().resolvedCGColor(with: view.traitCollection)
                view.accessibilityIdentifier = "SwiftUI.RoundedRectangle.stroke"
            }
            surface.addSubview(view)
        case .capsule(let style):
            let view = UIView(frame: rect)
            view.isUserInteractionEnabled = false
            view.layer.cornerRadius = max(0, min(rect.width, rect.height) / 2)
            switch style {
            case .fill(let color):
                view.backgroundColor = (color ?? environment.foregroundColor ?? .black).resolve()
                view.accessibilityIdentifier = "SwiftUI.Capsule.fill"
            case .stroke(let color, let lineWidth):
                view.backgroundColor = .clear
                view.layer.borderWidth = max(0, lineWidth)
                view.layer.borderColor = color.resolve().resolvedCGColor(with: view.traitCollection)
                view.accessibilityIdentifier = "SwiftUI.Capsule.stroke"
            }
            surface.addSubview(view)
        case .divider:
            let view = UIView(frame: CGRect(
                x: rect.minX,
                y: rect.midY - 0.5,
                width: rect.width,
                height: 1
            ))
            view.backgroundColor = .separator
            view.isUserInteractionEnabled = false
            view.accessibilityIdentifier = "SwiftUI.Divider"
            surface.addSubview(view)
        case .progress:
            let extent = _controlExtent(environment.controlSize)
            let indicator = UIActivityIndicatorView(style: .medium)
            indicator.frame = CGRect(
                x: rect.midX - extent / 2,
                y: rect.midY - extent / 2,
                width: extent,
                height: extent
            )
            indicator.color = (environment.tintColor ?? environment.foregroundColor)?.resolve()
                ?? UIActivityIndicatorView.defaultColor
            indicator.accessibilityIdentifier = "SwiftUI.ProgressView"
            if environment.usesCircularProgressStyle {
                indicator.accessibilityValue = "style=circular"
            }
            indicator.startAnimating()
            surface.addSubview(indicator)
        case .slider(let value, let minimum, let maximum, _, let setValue):
            let slider = UISlider(frame: rect)
            slider.minimumValue = Float(min(minimum, maximum))
            slider.maximumValue = Float(max(minimum, maximum))
            slider.value = Float(min(max(value, minimum), maximum))
            slider.minimumTrackTintColor = environment.tintColor?.resolve()
            slider.isEnabled = environment.isEnabled
            slider.accessibilityIdentifier = "SwiftUI.Slider"
            slider.accessibilityValue = String(Double(slider.value))
            slider.addTarget(for: .valueChanged) { control, _ in
                guard let slider = control as? UISlider else { return }
                setValue(Double(slider.value))
                slider.accessibilityValue = String(Double(slider.value))
            }
            surface.addSubview(slider)
        case .spacer:
            return
        case .gradient(let gradient, let start, let end):
            let view = UIGradientView(frame: rect)
            view.isUserInteractionEnabled = false
            view.colors = gradient.colors.map { $0.resolve() }
            view.locations = gradient.stops.map(\.location)
            view.startPoint = CGPoint(x: start.x, y: start.y)
            view.endPoint = CGPoint(x: end.x, y: end.y)
            view.accessibilityIdentifier = "SwiftUI.LinearGradient"
            surface.addSubview(view)
        case .hStack(let children, let alignment, let spacing):
            placeHStack(
                children,
                alignment: alignment,
                spacing: spacing ?? defaultSpacing,
                in: rect,
                on: surface,
                environment: environment
            )
        case .vStack(let children, let alignment, let spacing):
            placeVStack(
                children,
                alignment: alignment,
                spacing: spacing ?? defaultSpacing,
                in: rect,
                on: surface,
                environment: environment
            )
        case .zStack(let children, let alignment):
            let orderedChildren = children.enumerated().sorted { lhs, rhs in
                let lhsIndex = _zIndex(lhs.element)
                let rhsIndex = _zIndex(rhs.element)
                if lhsIndex == rhsIndex { return lhs.offset < rhs.offset }
                return lhsIndex < rhsIndex
            }.map(\.element)
            for child in orderedChildren {
                let size = measure(child, proposed: rect.size, environment: environment)
                place(
                    child,
                    in: alignedRect(
                        size: CGSize(
                            width: min(rect.width, size.width),
                            height: min(rect.height, size.height)
                        ),
                        in: rect,
                        alignment: alignment
                    ),
                    on: surface,
                    environment: environment
                )
            }
        case .grid(let rows, let horizontalSpacing, let verticalSpacing):
            placeGrid(
                rows,
                horizontalSpacing: horizontalSpacing ?? defaultSpacing,
                verticalSpacing: verticalSpacing ?? defaultSpacing,
                in: rect,
                on: surface,
                environment: environment
            )
        case .gridRow(let cells):
            placeHStack(
                cells,
                alignment: .center,
                spacing: defaultSpacing,
                in: rect,
                on: surface,
                environment: environment
            )
        case .button(let label, let pressedLabel, let role, let action):
            let control = _SwiftUIButtonControl(frame: rect)
            control.isOpaque = false
            control.backgroundColor = .clear
            control.accessibilityIdentifier = "SwiftUI.Button"
            control.accessibilityTraits = [.button]
            if role == .destructive {
                control.accessibilityHint = "Destructive action"
            }
            control.isEnabled = environment.isEnabled
            control.addTarget(for: .touchUpInside) { _, _ in action() }
            for simultaneousAction in environment.simultaneousTapActions {
                control.addTarget(for: .touchUpInside) { _, _ in simultaneousAction() }
            }
            surface.addSubview(control)
            place(
                label,
                in: control.normalHost.bounds,
                on: control.normalHost,
                environment: environment
            )
            if let pressedLabel {
                place(
                    pressedLabel,
                    in: control.pressedHost.bounds,
                    on: control.pressedHost,
                    environment: environment
                )
            }
            control.refreshAppearance()
        case .menu(let label, let pressedLabel, let content):
            let control = _SwiftUIMenuControl(frame: rect)
            control.isOpaque = false
            control.backgroundColor = .clear
            control.accessibilityIdentifier = "SwiftUI.Menu"
            control.accessibilityTraits = [.button]
            control.accessibilityLabel = _openMenuTitle(in: label)
            control.isEnabled = environment.isEnabled
            control.menu = UIMenu(children: _openMenuElements(in: content))
            surface.addSubview(control)
            place(
                label,
                in: control.normalHost.bounds,
                on: control.normalHost,
                environment: environment
            )
            if let pressedLabel {
                place(
                    pressedLabel,
                    in: control.pressedHost.bounds,
                    on: control.pressedHost,
                    environment: environment
                )
            }
            if environment.menuIndicatorVisibility != .hidden {
                let indicator = _SystemSymbolView(name: "chevron.down")
                indicator.frame = CGRect(
                    x: max(0, control.bounds.width - 12),
                    y: max(0, (control.bounds.height - 8) / 2),
                    width: 8,
                    height: 8
                )
                indicator.accessibilityIdentifier = "SwiftUI.Menu.indicator"
                control.addSubview(indicator)
            }
            control.refreshAppearance()
        case .geometry(let geometry):
            place(
                geometry.resolve(rect.size),
                in: rect,
                on: surface,
                environment: environment
            )
        case .scrollReader(let content, let storage):
            var next = environment
            next.scrollStorage = storage
            place(content, in: rect, on: surface, environment: next)
        case .customLayout(let layout, let children):
            let subviews = makeLayoutSubviews(children, environment: environment)
            var cache: () = ()
            layout.placeSubviews(
                in: rect,
                proposal: ProposedViewSize(width: rect.width, height: rect.height),
                subviews: subviews,
                cache: &cache
            )
            for (index, child) in children.enumerated() {
                let subview = subviews[index]
                let proposal = subview.placement.proposal
                let proposed = proposal.replacingUnspecifiedDimensions(by: rect.size)
                let measured = measure(child, proposed: proposed, environment: environment)
                let size = CGSize(
                    width: proposal.width ?? measured.width,
                    height: proposal.height ?? measured.height
                )
                let point = subview.placement.point ?? rect.origin
                let anchor = subview.placement.anchor
                place(
                    child,
                    in: CGRect(
                        x: point.x - size.width * anchor.x,
                        y: point.y - size.height * anchor.y,
                        width: size.width,
                        height: size.height
                    ),
                    on: surface,
                    environment: environment
                )
            }
        case .scroll(let content):
            let scrollView = _SwiftUIScrollView(frame: rect)
            scrollView.accessibilityIdentifier = "SwiftUI.ScrollView"
            switch environment.keyboardDismissMode {
            case .immediately:
                scrollView.keyboardDismissMode = .onDrag
            case .interactively:
                scrollView.keyboardDismissMode = .interactive
            case .automatic, .never:
                scrollView.keyboardDismissMode = .none
            }
            let showsIndicators = environment.scrollIndicatorVisibility != .hidden
            scrollView.showsVerticalScrollIndicator = showsIndicators
            scrollView.showsHorizontalScrollIndicator = showsIndicators
            surface.addSubview(scrollView)
            let storage = environment.scrollStorage ?? _OpenScrollProxyStorage()
            storage.scrollView = scrollView
            storage.targetRects.removeAll(keepingCapacity: true)
            var measurementEnvironment = environment
            measurementEnvironment.measuresUnboundedVerticalScroll = true
            measurementEnvironment.scrollStorage = storage
            let measured = measure(
                content,
                proposed: scrollView.bounds.size,
                environment: measurementEnvironment
            )
            let contentSize = CGSize(
                width: max(scrollView.bounds.width, measured.width),
                height: max(scrollView.bounds.height, measured.height)
            )
            scrollView.contentSize = contentSize
            place(
                content,
                in: CGRect(origin: .zero, size: contentSize),
                on: scrollView,
                environment: measurementEnvironment
            )
            if let refreshAction = environment.refreshAction {
                let refresh = UIRefreshControl()
                refresh.accessibilityIdentifier = "SwiftUI.RefreshControl"
                refresh.addTarget(for: .valueChanged) { control, _ in
                    guard let refresh = control as? UIRefreshControl else { return }
                    Task { @MainActor in
                        await refreshAction()
                        refresh.endRefreshing()
                    }
                }
                scrollView.refreshControl = refresh
            }
            let coordinator = _SwiftUIScrollCoordinator(
                storage: storage,
                geometryObservers: environment.scrollGeometryObservers,
                visibilityObservers: environment.scrollVisibilityObservers
            )
            scrollView.retainedCoordinator = coordinator
            scrollView.delegate = coordinator
            storage.coordinator = coordinator
            storage.notifyAfterScroll = { [weak scrollView, weak coordinator] in
                guard let scrollView, let coordinator else { return }
                coordinator.notify(scrollView)
            }
            coordinator.notify(scrollView)
        case .tabView(let pages, let selection, let setSelection, let indexDisplayMode):
            guard let selected = _openSelectedTabPage(
                pages: pages,
                selection: selection
            ) else { return }
            let indicatorHeight = _pageIndicatorHeight(
                pageCount: pages.count,
                indexDisplayMode: indexDisplayMode
            )
            place(
                selected.page.content,
                in: CGRect(
                    x: rect.minX,
                    y: rect.minY,
                    width: rect.width,
                    height: max(0, rect.height - indicatorHeight)
                ),
                on: surface,
                environment: environment
            )
            guard indicatorHeight > 0 else { return }
            let pageControl = UIPageControl(
                frame: CGRect(
                    x: rect.minX,
                    y: rect.maxY - indicatorHeight,
                    width: rect.width,
                    height: indicatorHeight
                )
            )
            pageControl.accessibilityIdentifier = "SwiftUI.TabView.pageControl"
            pageControl.numberOfPages = pages.count
            pageControl.currentPage = selected.index
            pageControl.addTarget(for: .valueChanged) { control, _ in
                guard let pageControl = control as? UIPageControl,
                      pages.indices.contains(pageControl.currentPage),
                      let tag = pages[pageControl.currentPage].tag else { return }
                setSelection(tag)
            }
            surface.addSubview(pageControl)
        case .view(let hosted):
            hosted.frame = rect
            hosted.accessibilityIdentifier = hosted.accessibilityIdentifier
                ?? "SwiftUI.UIViewRepresentable"
            surface.addSubview(hosted)
        case .viewController(let controller):
            controller.loadViewIfNeeded()
            guard let hosted = controller.view else { return }
            hosted.frame = rect
            hosted.accessibilityIdentifier = hosted.accessibilityIdentifier
                ?? "SwiftUI.UIViewControllerRepresentable"
            surface.addSubview(hosted)
        case .form(let rows):
            placeForm(rows, in: rect, on: surface, environment: environment)
        case .list(let rows):
            placeList(rows, in: rect, on: surface, environment: environment)
        case .section(let header, let footer, let rows):
            placeSection(
                header: header,
                footer: footer,
                rows: rows,
                in: rect,
                on: surface,
                environment: environment
            )
        case .toggle(let label, let isOn, let setIsOn):
            let toggle = UISwitch(frame: .zero)
            toggle.frame.origin = CGPoint(
                x: max(rect.minX, rect.maxX - toggleSize.width),
                y: rect.minY + max(0, (rect.height - toggleSize.height) / 2)
            )
            toggle.setOn(isOn, animated: false)
            toggle.isEnabled = environment.isEnabled
            toggle.accessibilityIdentifier = "SwiftUI.Toggle.switch"
            toggle.addTarget(for: .valueChanged) { control, _ in
                guard let toggle = control as? UISwitch else { return }
                setIsOn(toggle.isOn)
            }
            surface.addSubview(toggle)
            place(
                label,
                in: CGRect(
                    x: rect.minX,
                    y: rect.minY,
                    width: max(0, toggle.frame.minX - rect.minX - 12),
                    height: rect.height
                ),
                on: surface,
                environment: environment
            )
        case .textField(let title, let text, let isSecure, let axis, let setText):
            if axis == .vertical && !isSecure {
                let editor = _SwiftUITextView(frame: rect)
                editor.text = text
                editor.font = (environment.font ?? .body).resolve(weight: environment.weight)
                editor.textColor = environment.foregroundColor?.resolve() ?? .label
                editor.backgroundColor = .clear
                editor.isOpaque = false
                editor.textContainerInset = UIEdgeInsets(
                    top: 8,
                    left: 0,
                    bottom: 8,
                    right: 0
                )
                editor.textContentType = environment.textContentType
                editor.autocapitalizationType = environment.autocapitalizationType
                editor.autocorrectionType = environment.autocorrectionDisabled ? .no : .default
                editor.returnKeyType = _openReturnKeyType(environment.submitLabel)
                editor.isEditable = environment.isEnabled
                editor.accessibilityIdentifier = "SwiftUI.TextField.Multiline"
                editor.accessibilityLabel = title
                editor.getFocus = environment.focus?.get
                editor.setFocus = environment.focus?.set
                editor.setText = setText
                editor.submit = environment.submitAction
                surface.addSubview(editor)
                return
            }
            let field = _SwiftUITextField(frame: rect)
            field.borderStyle = .roundedRect
            field.placeholder = title
            field.text = text
            field.isSecureTextEntry = isSecure
            field.textContentType = environment.textContentType
            field.autocapitalizationType = environment.autocapitalizationType
            field.autocorrectionType = environment.autocorrectionDisabled ? .no : .default
            field.returnKeyType = _openReturnKeyType(environment.submitLabel)
            field.isEnabled = environment.isEnabled
            field.accessibilityIdentifier = isSecure
                ? "SwiftUI.SecureField"
                : "SwiftUI.TextField"
            field.getFocus = environment.focus?.get
            field.setFocus = environment.focus?.set
            field.addTarget(for: .editingChanged) { control, _ in
                guard let field = control as? UITextField else { return }
                setText(field.text ?? "")
            }
            field.addTarget(for: .editingDidBegin) { control, _ in
                guard let field = control as? _SwiftUITextField else { return }
                field.setFocus?(true)
            }
            field.addTarget(for: .editingDidEnd) { control, _ in
                guard let field = control as? _SwiftUITextField else { return }
                field.setFocus?(false)
            }
            if let submitAction = environment.submitAction {
                field.addTarget(for: .primaryActionTriggered) { _, _ in
                    submitAction()
                }
            }
            surface.addSubview(field)
        case .picker(let label, let options, let selection, let setSelection):
            let control: UIControl
            if environment.usesMenuPickerStyle {
                let button = UIButton(type: .system)
                button.frame = rect
                button.showsMenuAsPrimaryAction = true
                button.menu = UIMenu(
                    options: [.singleSelection],
                    children: options.map { option in
                        UIAction(
                            title: _openMenuTitle(in: option.content)
                                ?? String(describing: option.tag),
                            image: _openMenuImage(in: option.content),
                            attributes: environment.isEnabled ? [] : [.disabled],
                            state: option.tag == selection ? .on : .off
                        ) { _ in
                            setSelection(option.tag)
                        }
                    }
                )
                control = button
            } else {
                control = UIControl(frame: rect)
            }
            control.isEnabled = environment.isEnabled
            control.backgroundColor = .clear
            control.accessibilityIdentifier = "SwiftUI.Picker"
            surface.addSubview(control)
            let selectedIndex = options.firstIndex { $0.tag == selection } ?? 0
            let trailingWidth = max(88, rect.width * 0.42)
            place(
                label,
                in: CGRect(
                    x: 0,
                    y: 0,
                    width: max(0, control.bounds.width - trailingWidth - 12),
                    height: control.bounds.height
                ),
                on: control,
                environment: environment
            )
            if options.indices.contains(selectedIndex) {
                var selectedEnvironment = environment
                selectedEnvironment.foregroundColor = .init(uiColor: .secondaryLabel)
                selectedEnvironment.textAlignment = .trailing
                place(
                    options[selectedIndex].content,
                    in: CGRect(
                        x: max(0, control.bounds.width - trailingWidth),
                        y: 0,
                        width: max(0, trailingWidth - 20),
                        height: control.bounds.height
                    ),
                    on: control,
                    environment: selectedEnvironment
                )
            }
            let disclosure = _SystemSymbolView(
                name: environment.usesMenuPickerStyle ? "chevron.down" : "chevron.right"
            )
            disclosure.strokeColor = environment.isEnabled ? .secondaryLabel : .tertiaryLabel
            disclosure.frame = CGRect(
                x: max(0, control.bounds.width - 9),
                y: max(0, (control.bounds.height - 12) / 2),
                width: 7,
                height: 12
            )
            disclosure.accessibilityIdentifier = "SwiftUI.Picker.disclosure"
            control.addSubview(disclosure)
            if !environment.usesMenuPickerStyle {
                control.addTarget(for: .touchUpInside) { _, _ in
                    guard !options.isEmpty else { return }
                    let next = options[(selectedIndex + 1) % options.count]
                    setSelection(next.tag)
                }
            }
        case .navigationLink(let label, let makeDestinationController):
            let control = UIControl(frame: rect)
            control.isOpaque = false
            control.backgroundColor = .clear
            control.accessibilityIdentifier = "SwiftUI.NavigationLink"
            control.isEnabled = environment.isEnabled
            control.addTarget(for: .touchUpInside) { [weak control] _, _ in
                guard let control,
                      let source = _enclosingViewController(for: control),
                      let navigationController = source.navigationController else {
                    preconditionFailure(
                        "SwiftUI.NavigationLink requires an enclosing UINavigationController"
                    )
                }
                let destination = makeDestinationController()
                destination.loadViewIfNeeded()
                navigationController.pushViewController(destination, animated: true)
            }
            surface.addSubview(control)
            place(
                label,
                in: control.bounds.inset(
                    by: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 32)
                ),
                on: control,
                environment: environment
            )
            let disclosure = _SystemSymbolView(name: "chevron.right")
            disclosure.strokeColor = .label
            disclosure.frame = CGRect(
                x: max(0, control.bounds.width - 21),
                y: max(0, (control.bounds.height - 12) / 2),
                width: 7,
                height: 12
            )
            disclosure.accessibilityIdentifier = "SwiftUI.NavigationLink.disclosure"
            control.addSubview(disclosure)
        case .link(let label, let destination):
            let control = UIControl(frame: rect)
            control.backgroundColor = .clear
            control.isOpaque = false
            control.isEnabled = environment.isEnabled
            control.isAccessibilityElement = true
            control.accessibilityTraits = [.link]
            control.accessibilityIdentifier = "SwiftUI.Link"
            control.accessibilityLabel = _openMenuTitle(in: label)
            control.addTarget(for: .touchUpInside) { _, _ in
                UIApplication.shared.open(destination.absoluteString)
            }
            surface.addSubview(control)
            var next = environment
            next.foregroundColor = environment.tintColor ?? .init(uiColor: .link)
            place(label, in: control.bounds, on: control, environment: next)
        case .navigation(let content, let configuration):
            placeNavigation(
                content,
                configuration: configuration,
                in: rect,
                on: surface,
                environment: environment
            )
        case .modified(let content, let modification):
            switch modification {
            case .font(let font):
                var next = environment
                next.font = font
                place(content, in: rect, on: surface, environment: next)
            case .fontWeight(let weight):
                var next = environment
                next.weight = weight
                place(content, in: rect, on: surface, environment: next)
            case .minimumScaleFactor(let factor):
                var next = environment
                next.minimumScaleFactor = factor
                place(content, in: rect, on: surface, environment: next)
            case .allowsTightening(let flag):
                var next = environment
                next.allowsTightening = flag
                place(content, in: rect, on: surface, environment: next)
            case .foregroundColor(let color):
                var next = environment
                next.foregroundColor = color
                place(content, in: rect, on: surface, environment: next)
            case .tint(let color):
                var next = environment
                next.tintColor = color
                place(content, in: rect, on: surface, environment: next)
            case .lineLimit(let limit):
                var next = environment
                next.lineLimit = limit
                next.lineLimitRange = nil
                place(content, in: rect, on: surface, environment: next)
            case .lineLimitRange(let range):
                var next = environment
                next.lineLimit = max(0, range.upperBound)
                next.lineLimitRange = range
                place(content, in: rect, on: surface, environment: next)
            case .truncationMode:
                place(content, in: rect, on: surface, environment: environment)
            case .focus(let get, let set):
                var next = environment
                next.focus = (get, set)
                place(content, in: rect, on: surface, environment: next)
            case .textContentType(let type):
                var next = environment
                next.textContentType = type
                place(content, in: rect, on: surface, environment: next)
            case .autocapitalization(let type):
                var next = environment
                next.autocapitalizationType = type
                place(content, in: rect, on: surface, environment: next)
            case .autocorrectionDisabled(let disabled):
                var next = environment
                next.autocorrectionDisabled = disabled
                place(content, in: rect, on: surface, environment: next)
            case .submit(let action):
                var next = environment
                next.submitAction = action
                place(content, in: rect, on: surface, environment: next)
            case .submitLabel(let label):
                var next = environment
                next.submitLabel = label
                place(content, in: rect, on: surface, environment: next)
            case .scrollDismissesKeyboard(let mode):
                var next = environment
                next.keyboardDismissMode = mode
                place(content, in: rect, on: surface, environment: next)
            case .controlSize(let size):
                var next = environment
                next.controlSize = size
                place(content, in: rect, on: surface, environment: next)
            case .imageScale(let scale):
                var next = environment
                next.imageScale = scale
                place(content, in: rect, on: surface, environment: next)
            case .circularProgressStyle:
                var next = environment
                next.usesCircularProgressStyle = true
                place(content, in: rect, on: surface, environment: next)
            case .menuPickerStyle:
                var next = environment
                next.usesMenuPickerStyle = true
                place(content, in: rect, on: surface, environment: next)
            case .menuIndicator(let visibility):
                var next = environment
                next.menuIndicatorVisibility = visibility
                place(content, in: rect, on: surface, environment: next)
            case .symbolRenderingMode(let mode):
                var next = environment
                next.symbolRenderingMode = mode
                place(content, in: rect, on: surface, environment: next)
            case .resizable:
                var next = environment
                next.imageResizable = true
                place(content, in: rect, on: surface, environment: next)
            case .aspectRatio(let ratio, let contentMode):
                var next = environment
                next.imageContentMode = contentMode
                let destination: CGRect
                if let ratio {
                    destination = alignedRect(
                        size: aspectSize(
                            ratio: ratio,
                            contentMode: contentMode,
                            proposed: rect.size
                        ),
                        in: rect,
                        alignment: .center
                    )
                } else {
                    destination = rect
                }
                place(content, in: destination, on: surface, environment: next)
            case .frame(let width, let height, let alignment):
                let measured = measure(content, proposed: rect.size, environment: environment)
                let size = CGSize(width: width ?? min(rect.width, measured.width),
                                  height: height ?? min(rect.height, measured.height))
                let childRect = alignedRect(size: size, in: rect, alignment: alignment)
                place(content, in: childRect, on: surface, environment: environment)
            case .flexibleFrame(
                let minWidth,
                let maxWidth,
                let minHeight,
                let maxHeight,
                let alignment
            ):
                let measured = measure(content, proposed: rect.size, environment: environment)
                let size = CGSize(
                    width: _flexibleExtent(
                        measured.width,
                        proposed: rect.width,
                        minimum: minWidth,
                        maximum: maxWidth
                    ),
                    height: _flexibleExtent(
                        measured.height,
                        proposed: rect.height,
                        minimum: minHeight,
                        maximum: maxHeight
                    )
                )
                place(
                    content,
                    in: alignedRect(size: size, in: rect, alignment: alignment),
                    on: surface,
                    environment: environment
                )
            case .padding(let edges, let length):
                let amount = max(0, length ?? 16)
                let inset = UIEdgeInsets(
                    top: edges.contains(.top) ? amount : 0,
                    left: edges.contains(.leading) ? amount : 0,
                    bottom: edges.contains(.bottom) ? amount : 0,
                    right: edges.contains(.trailing) ? amount : 0
                )
                place(content, in: rect.inset(by: inset), on: surface, environment: environment)
            case .edgeInsetsPadding(let insets):
                place(
                    content,
                    in: rect.inset(
                        by: UIEdgeInsets(
                            top: max(0, insets.top),
                            left: max(0, insets.leading),
                            bottom: max(0, insets.bottom),
                            right: max(0, insets.trailing)
                        )
                    ),
                    on: surface,
                    environment: environment
                )
            case .background(let background, _):
                place(background, in: rect, on: surface, environment: environment)
                place(content, in: rect, on: surface, environment: environment)
            case .listRowBackground(let background):
                let host = _SwiftUIPassthroughView(frame: rect)
                host.accessibilityIdentifier = "SwiftUI.ListRowBackground"
                surface.addSubview(host)
                place(background, in: host.bounds, on: host, environment: environment)
                place(content, in: host.bounds, on: host, environment: environment)
            case .overlay(let overlay, _):
                place(content, in: rect, on: surface, environment: environment)
                place(overlay, in: rect, on: surface, environment: environment)
            case .mask(let maskNode, let alignment):
                let host = _SwiftUIPassthroughView(frame: rect)
                host.accessibilityIdentifier = "SwiftUI.Mask"
                surface.addSubview(host)
                place(content, in: host.bounds, on: host, environment: environment)
                let maskSize = measure(
                    maskNode,
                    proposed: host.bounds.size,
                    environment: environment
                )
                let maskRect = alignedRect(
                    size: CGSize(
                        width: min(host.bounds.width, maskSize.width),
                        height: min(host.bounds.height, maskSize.height)
                    ),
                    in: host.bounds,
                    alignment: alignment
                )
                let layer = CALayer()
                layer.bounds = CGRect(origin: .zero, size: maskRect.size)
                layer.position = CGPoint(x: maskRect.midX, y: maskRect.midY)
                layer.backgroundColor = UIColor.white.cgColor
                host.layer.mask = layer
            case .multilineTextAlignment(let alignment):
                var next = environment
                next.textAlignment = alignment
                place(content, in: rect, on: surface, environment: next)
            case .opacity(let opacity):
                let opacityHost = _SwiftUIPassthroughView(frame: rect)
                opacityHost.alpha = opacity
                opacityHost.accessibilityIdentifier = "SwiftUI.Opacity"
                surface.addSubview(opacityHost)
                place(content, in: opacityHost.bounds, on: opacityHost, environment: environment)
            case .scaleEffect(let scale):
                let scaleHost = _SwiftUIPassthroughView(frame: rect)
                scaleHost.transform = CGAffineTransform(scaleX: scale, y: scale)
                scaleHost.accessibilityIdentifier = "SwiftUI.ScaleEffect"
                surface.addSubview(scaleHost)
                place(content, in: scaleHost.bounds, on: scaleHost, environment: environment)
            case .projection(let resolve):
                let projectionHost = _SwiftUIPassthroughView(frame: rect)
                let projection = resolve(rect.size)
                if let transform = projection.affineTransform {
                    projectionHost.transform = transform
                }
                projectionHost.accessibilityIdentifier = "SwiftUI.GeometryEffect"
                surface.addSubview(projectionHost)
                place(
                    content,
                    in: projectionHost.bounds,
                    on: projectionHost,
                    environment: environment
                )
            case .layoutPriority:
                // Stack placement reads priority from the structural node;
                // outside a stack it is intentionally layout-transparent.
                place(content, in: rect, on: surface, environment: environment)
            case .fixedSize(let horizontal, let vertical):
                let ideal = measure(
                    content,
                    proposed: CGSize(
                        width: horizontal ? 10_000 : rect.width,
                        height: vertical ? 10_000 : rect.height
                    ),
                    environment: environment
                )
                let size = CGSize(
                    width: horizontal ? ideal.width : rect.width,
                    height: vertical ? ideal.height : rect.height
                )
                place(
                    content,
                    in: alignedRect(size: size, in: rect, alignment: .center),
                    on: surface,
                    environment: environment
                )
            case .tapAction(let action):
                let control = UIControl(frame: rect)
                control.isOpaque = false
                control.backgroundColor = .clear
                control.accessibilityIdentifier = "SwiftUI.TapGesture"
                control.isEnabled = environment.isEnabled
                control.addTarget(for: .touchUpInside) { _, _ in action() }
                surface.addSubview(control)
                place(content, in: control.bounds, on: control, environment: environment)
            case .simultaneousTapAction(let action):
                if _containsButton(content) {
                    var next = environment
                    next.simultaneousTapActions.append(action)
                    place(content, in: rect, on: surface, environment: next)
                } else {
                    let control = UIControl(frame: rect)
                    control.isOpaque = false
                    control.backgroundColor = .clear
                    control.accessibilityIdentifier = "SwiftUI.SimultaneousTapGesture"
                    control.isEnabled = environment.isEnabled
                    control.addTarget(for: .touchUpInside) { _, _ in action() }
                    surface.addSubview(control)
                    place(content, in: control.bounds, on: control, environment: environment)
                }
            case .gesture(let gesture):
                let host = UIView(frame: rect)
                host.backgroundColor = .clear
                host.isOpaque = false
                host.accessibilityIdentifier = "SwiftUI.Gesture"
                surface.addSubview(host)
                _openInstallGesture(gesture, on: host)
                place(content, in: host.bounds, on: host, environment: environment)
            case .onAppear, .onDisappear:
                place(content, in: rect, on: surface, environment: environment)
            case .shadow(let color, let radius, let x, let y):
                let shadowHost = _SwiftUIPassthroughView(frame: rect)
                shadowHost.backgroundColor = .clear
                shadowHost.isOpaque = false
                let resolved = color.resolve().resolvedCGColor(
                    with: shadowHost.traitCollection
                )
                shadowHost.layer.shadowColor = CGColor(
                    red: resolved.red,
                    green: resolved.green,
                    blue: resolved.blue,
                    alpha: 1
                )
                shadowHost.layer.shadowOpacity = Float(resolved.alpha)
                shadowHost.layer.shadowRadius = radius
                shadowHost.layer.shadowOffset = CGSize(width: x, height: y)
                shadowHost.accessibilityIdentifier = "SwiftUI.Shadow"
                surface.addSubview(shadowHost)
                place(content, in: shadowHost.bounds, on: shadowHost, environment: environment)
            case .colorScheme(let scheme):
                let traitHost = _SwiftUIPassthroughView(frame: rect)
                traitHost.backgroundColor = .clear
                traitHost.isOpaque = false
                traitHost.overrideUserInterfaceStyle = scheme == .dark ? .dark : .light
                traitHost.accessibilityIdentifier = "SwiftUI.ColorScheme"
                surface.addSubview(traitHost)
                place(content, in: traitHost.bounds, on: traitHost, environment: environment)
            case .safeAreaIgnored:
                // The portable host currently proposes its full bounds and
                // has no synthetic safe-area inset, so ignoring it is an
                // explicit identity operation.
                place(content, in: rect, on: surface, environment: environment)
            case .previewLayout:
                place(content, in: rect, on: surface, environment: environment)
            case .clipRoundedRectangle(let radius):
                if surface is _SwiftUIHostingView, rect == surface.bounds {
                    surface.layer.cornerRadius = radius
                    surface.clipsToBounds = radius > 0
                    place(content, in: rect, on: surface, environment: environment)
                } else {
                    let clippingView = _SwiftUIPassthroughView(frame: rect)
                    clippingView.layer.cornerRadius = radius
                    clippingView.clipsToBounds = radius > 0
                    clippingView.accessibilityIdentifier = "SwiftUI.ClipRoundedRectangle"
                    surface.addSubview(clippingView)
                    place(
                        content,
                        in: clippingView.bounds,
                        on: clippingView,
                        environment: environment
                    )
                }
            case .clipped:
                let clippingView = _SwiftUIPassthroughView(frame: rect)
                clippingView.clipsToBounds = true
                clippingView.accessibilityIdentifier = "SwiftUI.Clipped"
                surface.addSubview(clippingView)
                place(
                    content,
                    in: clippingView.bounds,
                    on: clippingView,
                    environment: environment
                )
            case .hidden:
                let hiddenHost = _SwiftUIPassthroughView(frame: rect)
                hiddenHost.isHidden = true
                hiddenHost.accessibilityIdentifier = "SwiftUI.Hidden"
                surface.addSubview(hiddenHost)
                place(content, in: hiddenHost.bounds, on: hiddenHost, environment: environment)
            case .disabled(let disabled):
                var next = environment
                next.isEnabled = environment.isEnabled && !disabled
                place(content, in: rect, on: surface, environment: next)
            case .accessibilityHidden(let hidden):
                let accessibilityHost = _SwiftUIPassthroughView(frame: rect)
                accessibilityHost.backgroundColor = .clear
                accessibilityHost.isOpaque = false
                accessibilityHost.accessibilityElementsHidden = hidden
                accessibilityHost.accessibilityIdentifier = "SwiftUI.AccessibilityHidden"
                surface.addSubview(accessibilityHost)
                place(
                    content,
                    in: accessibilityHost.bounds,
                    on: accessibilityHost,
                    environment: environment
                )
            case .accessibilityElement(let children):
                let accessibilityHost = _SwiftUIPassthroughView(frame: rect)
                accessibilityHost.backgroundColor = .clear
                accessibilityHost.isOpaque = false
                accessibilityHost.isAccessibilityElement = children != .contain
                accessibilityHost.accessibilityElementsHidden = children != .contain
                accessibilityHost.accessibilityIdentifier = "SwiftUI.AccessibilityElement"
                surface.addSubview(accessibilityHost)
                place(content, in: accessibilityHost.bounds, on: accessibilityHost,
                      environment: environment)
                if children == .combine {
                    _openMergeAccessibility(from: accessibilityHost, into: accessibilityHost)
                }
            case .accessibilityLabel(let label):
                let host = _openAccessibilityHost(frame: rect, identifier: "Label")
                host.accessibilityLabel = label
                surface.addSubview(host)
                place(content, in: host.bounds, on: host, environment: environment)
                _openMergeAccessibility(from: host, into: host)
            case .accessibilityHint(let hint):
                let host = _openAccessibilityHost(frame: rect, identifier: "Hint")
                host.accessibilityHint = hint
                surface.addSubview(host)
                place(content, in: host.bounds, on: host, environment: environment)
                _openMergeAccessibility(from: host, into: host)
            case .accessibilityValue(let value):
                let host = _openAccessibilityHost(frame: rect, identifier: "Value")
                host.accessibilityValue = value
                surface.addSubview(host)
                place(content, in: host.bounds, on: host, environment: environment)
                _openMergeAccessibility(from: host, into: host)
            case .accessibilityTraits(let traits):
                let host = _openAccessibilityHost(frame: rect, identifier: "Traits")
                host.accessibilityTraits.formUnion(_openUIKitTraits(traits))
                surface.addSubview(host)
                place(content, in: host.bounds, on: host, environment: environment)
                _openMergeAccessibility(from: host, into: host)
            case .accessibilityAction(let name, let action):
                let host = UIControl(frame: rect)
                host.backgroundColor = .clear
                host.isOpaque = false
                host.isAccessibilityElement = true
                host.accessibilityIdentifier = name.map { "SwiftUI.AccessibilityAction.\($0)" }
                    ?? "SwiftUI.AccessibilityAction.default"
                host.accessibilityHint = name
                host.addTarget(for: .primaryActionTriggered) { _, _ in action() }
                surface.addSubview(host)
                place(content, in: host.bounds, on: host, environment: environment)
                _openMergeAccessibility(from: host, into: host)
            case .allowsHitTesting(let enabled):
                let host = _SwiftUIPassthroughView(frame: rect)
                host.isUserInteractionEnabled = enabled
                host.accessibilityIdentifier = "SwiftUI.AllowsHitTesting"
                surface.addSubview(host)
                place(content, in: host.bounds, on: host, environment: environment)
            case .zIndex(let value):
                let host = _SwiftUIPassthroughView(frame: rect)
                host.accessibilityIdentifier = "SwiftUI.ZIndex.\(value)"
                surface.addSubview(host)
                place(content, in: host.bounds, on: host, environment: environment)
            case .glassEffect:
                let effectView = UIVisualEffectView(
                    effect: UIBlurEffect(style: .systemMaterial)
                )
                effectView.frame = rect
                effectView.accessibilityIdentifier = "SwiftUI.GlassEffect"
                surface.addSubview(effectView)
                effectView.layoutIfNeeded()
                place(
                    content,
                    in: effectView.contentView.bounds,
                    on: effectView.contentView,
                    environment: environment
                )
            case .buttonBorderShape(let shape):
                let host = _SwiftUIPassthroughView(frame: rect)
                switch shape.storage {
                case .automatic:
                    host.layer.cornerRadius = min(rect.height / 3, 12)
                case .capsule, .circle:
                    host.layer.cornerRadius = min(rect.width, rect.height) / 2
                case .roundedRectangle(let radius):
                    host.layer.cornerRadius = max(0, radius)
                }
                host.clipsToBounds = host.layer.cornerRadius > 0
                host.accessibilityIdentifier = "SwiftUI.ButtonBorderShape"
                surface.addSubview(host)
                place(content, in: host.bounds, on: host, environment: environment)
            case .contextMenu(let menuNode):
                let host = _SwiftUIContextMenuHost(frame: rect)
                host.accessibilityIdentifier = "SwiftUI.ContextMenu"
                host.menu = UIMenu(children: _openMenuElements(in: menuNode))
                host.installInteraction()
                surface.addSubview(host)
                place(content, in: host.bounds, on: host, environment: environment)
            case .matchedGeometry(let id, let namespace, let isSource):
                let host = _SwiftUIPassthroughView(frame: rect)
                host.accessibilityIdentifier = "SwiftUI.MatchedGeometry.\(namespace.rawValue).\(id).\(isSource)"
                surface.addSubview(host)
                place(content, in: host.bounds, on: host, environment: environment)
            case .accessibilityIdentifier(let identifier):
                let host = _SwiftUIPassthroughView(frame: rect)
                host.accessibilityIdentifier = identifier
                surface.addSubview(host)
                place(content, in: host.bounds, on: host, environment: environment)
            case .alert(let configuration):
                place(content, in: rect, on: surface, environment: environment)
                surface.addSubview(
                    _SwiftUIAlertPresentationHost(configuration: configuration)
                )
            case .presentation(let configuration):
                place(content, in: rect, on: surface, environment: environment)
                surface.addSubview(
                    _SwiftUIPresentationHost(configuration: configuration)
                )
            case .identifier(let identifier):
                environment.scrollStorage?.targetRects[identifier] = rect
                let host = _SwiftUIPassthroughView(frame: rect)
                host.accessibilityIdentifier = "SwiftUI.ID.\(identifier)"
                surface.addSubview(host)
                place(content, in: host.bounds, on: host, environment: environment)
            case .preference:
                place(content, in: rect, on: surface, environment: environment)
            case .preferenceListener(let listener):
                place(content, in: rect, on: surface, environment: environment)
                listener.action(
                    _openReducedPreference(
                        in: content,
                        listener: listener,
                        proposed: rect.size
                    )
                )
            case .scrollVisibility(let observer):
                var next = environment
                next.scrollVisibilityObservers.append(observer)
                place(content, in: rect, on: surface, environment: next)
            case .scrollGeometry(let observer):
                var next = environment
                next.scrollGeometryObservers.append(observer)
                place(content, in: rect, on: surface, environment: next)
            case .geometryObserver(let observer):
                place(content, in: rect, on: surface, environment: environment)
                observer.deliver(
                    observer.read(GeometryProxy(size: rect.size))
                )
            case .refreshable(let action):
                var next = environment
                next.refreshAction = action
                place(content, in: rect, on: surface, environment: next)
            case .scrollIndicators(let visibility):
                var next = environment
                next.scrollIndicatorVisibility = visibility
                place(content, in: rect, on: surface, environment: next)
            case .listStyle(let style):
                var next = environment
                next.listStyle = style
                place(content, in: rect, on: surface, environment: next)
            case .listRowSeparator:
                // Consumed by `placeList` when it creates the physical row
                // boundary. Outside a list it is layout-transparent.
                place(content, in: rect, on: surface, environment: environment)
            case .searchable(let configuration):
                let searchHeight = min(UISearchBar.standardHeight, max(0, rect.height))
                let search = _SwiftUISearchBar(
                    frame: CGRect(
                        x: rect.minX,
                        y: rect.minY,
                        width: rect.width,
                        height: searchHeight
                    )
                )
                search.text = configuration.getText()
                search.placeholder = configuration.prompt
                search.setText = configuration.setText
                search.accessibilityIdentifier = "SwiftUI.Searchable"
                search.searchBarStyle = configuration.placement == .toolbar
                    ? .minimal : .default
                surface.addSubview(search)
                place(
                    content,
                    in: CGRect(
                        x: rect.minX,
                        y: rect.minY + searchHeight,
                        width: rect.width,
                        height: max(0, rect.height - searchHeight)
                    ),
                    on: surface,
                    environment: environment
                )
            case .searchToolbarBehavior:
                // The behavior controls collapse policy during navigation;
                // the retained search bar remains fully functional when the
                // portable host has no scrolling navigation-bar chrome.
                place(content, in: rect, on: surface, environment: environment)
            case .safeAreaInset(let edge, let spacing, let insetContent):
                let insetSize = measure(
                    insetContent,
                    proposed: rect.size,
                    environment: environment
                )
                let gap = max(0, spacing ?? 0)
                switch edge {
                case .top:
                    place(insetContent, in: CGRect(x: rect.minX, y: rect.minY,
                          width: rect.width, height: insetSize.height),
                          on: surface, environment: environment)
                    place(content, in: CGRect(x: rect.minX,
                          y: rect.minY + insetSize.height + gap,
                          width: rect.width,
                          height: max(0, rect.height - insetSize.height - gap)),
                          on: surface, environment: environment)
                case .bottom:
                    place(content, in: CGRect(x: rect.minX, y: rect.minY,
                          width: rect.width,
                          height: max(0, rect.height - insetSize.height - gap)),
                          on: surface, environment: environment)
                    place(insetContent, in: CGRect(x: rect.minX,
                          y: rect.maxY - insetSize.height,
                          width: rect.width, height: insetSize.height),
                          on: surface, environment: environment)
                case .leading:
                    place(insetContent, in: CGRect(x: rect.minX, y: rect.minY,
                          width: insetSize.width, height: rect.height),
                          on: surface, environment: environment)
                    place(content, in: CGRect(x: rect.minX + insetSize.width + gap,
                          y: rect.minY,
                          width: max(0, rect.width - insetSize.width - gap),
                          height: rect.height), on: surface, environment: environment)
                case .trailing:
                    place(content, in: CGRect(x: rect.minX, y: rect.minY,
                          width: max(0, rect.width - insetSize.width - gap),
                          height: rect.height), on: surface, environment: environment)
                    place(insetContent, in: CGRect(x: rect.maxX - insetSize.width,
                          y: rect.minY, width: insetSize.width, height: rect.height),
                          on: surface, environment: environment)
                }
            case .swipeActions(_, _, let actions):
                let host = UIView(frame: rect)
                host.clipsToBounds = true
                host.accessibilityIdentifier = "SwiftUI.SwipeActions"
                surface.addSubview(host)
                let contentHost = _SwiftUIPassthroughView(frame: host.bounds)
                host.addSubview(contentHost)
                place(content, in: contentHost.bounds, on: contentHost, environment: environment)
                let actionWidth = min(96, max(44, host.bounds.width * 0.25))
                let actionHost = UIView(frame: CGRect(
                    x: host.bounds.width - actionWidth,
                    y: 0,
                    width: actionWidth,
                    height: host.bounds.height
                ))
                actionHost.backgroundColor = .systemOrange
                actionHost.accessibilityIdentifier = "SwiftUI.SwipeActions.actions"
                host.insertSubview(actionHost, belowSubview: contentHost)
                place(actions, in: actionHost.bounds, on: actionHost, environment: environment)
                let pan = UIPanGestureRecognizer { recognizer in
                    guard let pan = recognizer as? UIPanGestureRecognizer else { return }
                    let translation = pan.translation(in: host)
                    let x = min(0, max(-actionWidth, translation.x))
                    contentHost.transform = CGAffineTransform(translationX: x, y: 0)
                    if pan.state == .ended || pan.state == .cancelled {
                        let target = x < -actionWidth / 2 ? -actionWidth : 0
                        UIView.animate(withDuration: 0.2) {
                            contentHost.transform = CGAffineTransform(
                                translationX: target,
                                y: 0
                            )
                        }
                    }
                }
                host.addGestureRecognizer(pan)
            case .effect, .toolbarVisibility, .toolbarBackgroundVisibility,
                 .navigationTitle, .navigationBarHidden,
                 .navigationBackButtonHidden, .navigationTitleDisplayMode,
                 .toolbar, .tag, .pageTabViewStyle:
                // NavigationView consumes this metadata while building its
                // node.  Outside a NavigationView it leaves content intact.
                place(content, in: rect, on: surface, environment: environment)
            }
        }
    }

    private static func placeSection(
        header: _OpenViewNode?,
        footer: _OpenViewNode?,
        rows: [_OpenViewNode],
        in rect: CGRect,
        on surface: UIView,
        environment: _RenderEnvironment
    ) {
        let section = UIView(frame: rect)
        section.backgroundColor = .systemGroupedBackground
        section.clipsToBounds = true
        section.accessibilityIdentifier = "SwiftUI.Section"
        surface.addSubview(section)

        var y: CGFloat = header == nil ? 12 : 28
        if let header {
            var headerEnvironment = environment
            headerEnvironment.font = .caption
            headerEnvironment.foregroundColor = .init(uiColor: .secondaryLabel)
            place(
                header,
                in: CGRect(
                    x: 16,
                    y: 0,
                    width: max(0, section.bounds.width - 32),
                    height: 28
                ),
                on: section,
                environment: headerEnvironment
            )
        }

        for (index, row) in rows.enumerated() {
            let proposal = CGSize(
                width: max(0, section.bounds.width - 32),
                height: defaultFormRowHeight
            )
            let measured = measure(row, proposed: proposal, environment: environment)
            let height = max(defaultFormRowHeight, measured.height)
            guard y < section.bounds.height else { break }
            let rowView = UIView(
                frame: CGRect(
                    x: 0,
                    y: y,
                    width: section.bounds.width,
                    height: min(height, section.bounds.height - y)
                )
            )
            rowView.backgroundColor = .secondarySystemBackground
            rowView.accessibilityIdentifier = "SwiftUI.Section.row.\(index)"
            section.addSubview(rowView)
            place(
                row,
                in: rowView.bounds.inset(
                    by: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
                ),
                on: rowView,
                environment: environment
            )
            if index + 1 < rows.count {
                let separator = UIView(
                    frame: CGRect(
                        x: 16,
                        y: max(0, rowView.bounds.height - 0.5),
                        width: max(0, rowView.bounds.width - 16),
                        height: 0.5
                    )
                )
                separator.backgroundColor = .separator
                separator.isUserInteractionEnabled = false
                separator.accessibilityIdentifier = "SwiftUI.Section.separator.\(index)"
                rowView.addSubview(separator)
            }
            y += height
        }
        if let footer, y < section.bounds.height {
            var footerEnvironment = environment
            footerEnvironment.font = .caption
            footerEnvironment.foregroundColor = .init(uiColor: .secondaryLabel)
            place(
                footer,
                in: CGRect(
                    x: 16,
                    y: y,
                    width: max(0, section.bounds.width - 32),
                    height: min(28, section.bounds.height - y)
                ),
                on: section,
                environment: footerEnvironment
            )
        }
    }

    private static func placeForm(
        _ rows: [_OpenViewNode],
        in rect: CGRect,
        on surface: UIView,
        environment: _RenderEnvironment
    ) {
        let formView = UIView(frame: rect)
        formView.backgroundColor = .systemGroupedBackground
        formView.clipsToBounds = true
        formView.accessibilityIdentifier = "SwiftUI.Form"
        surface.addSubview(formView)

        var y: CGFloat = 0
        for (index, row) in rows.enumerated() {
            let proposal = CGSize(
                width: max(0, formView.bounds.width - 32),
                height: defaultFormRowHeight
            )
            let measured = measure(row, proposed: proposal, environment: environment)
            let rowHeight = max(defaultFormRowHeight, measured.height)
            guard y < formView.bounds.height else { break }

            if case .section = row.kind {
                place(
                    row,
                    in: CGRect(
                        x: 0,
                        y: y,
                        width: formView.bounds.width,
                        height: min(rowHeight, formView.bounds.height - y)
                    ),
                    on: formView,
                    environment: environment
                )
                y += rowHeight
                continue
            }

            let rowView = UIView(
                frame: CGRect(
                    x: 0,
                    y: y,
                    width: formView.bounds.width,
                    height: min(rowHeight, formView.bounds.height - y)
                )
            )
            rowView.backgroundColor = .secondarySystemBackground
            rowView.accessibilityIdentifier = "SwiftUI.Form.row.\(index)"
            formView.addSubview(rowView)

            place(
                row,
                in: rowView.bounds.inset(by: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)),
                on: rowView,
                environment: environment
            )
            y += rowHeight
        }
    }

    private static func placeList(
        _ rows: [_OpenViewNode],
        in rect: CGRect,
        on surface: UIView,
        environment: _RenderEnvironment
    ) {
        let list = UIScrollView(frame: rect)
        switch environment.listStyle.storage {
        case .grouped, .insetGrouped:
            list.backgroundColor = .systemGroupedBackground
        case .sidebar:
            list.backgroundColor = .secondarySystemBackground
        case .automatic, .plain:
            list.backgroundColor = .systemBackground
        }
        list.clipsToBounds = true
        list.accessibilityIdentifier = "SwiftUI.List"
        list.accessibilityValue = "style=\(environment.listStyle.storage)"
        surface.addSubview(list)

        var rowLayouts: [(node: _OpenViewNode, height: CGFloat)] = []
        var contentHeight: CGFloat = 0
        let horizontalInset: CGFloat
        switch environment.listStyle.storage {
        case .insetGrouped, .sidebar: horizontalInset = 12
        case .automatic, .plain, .grouped: horizontalInset = 0
        }
        let proposal = CGSize(
            width: max(0, list.bounds.width - 32 - horizontalInset * 2),
            height: defaultFormRowHeight
        )
        for row in rows {
            let measured = measure(row, proposed: proposal, environment: environment)
            let height = max(defaultFormRowHeight, measured.height)
            rowLayouts.append((row, height))
            contentHeight += height
        }
        list.contentSize = CGSize(
            width: list.bounds.width,
            height: max(list.bounds.height, contentHeight)
        )

        var y: CGFloat = 0
        for (index, layout) in rowLayouts.enumerated() {
            let rowFrame = CGRect(
                x: horizontalInset,
                y: y,
                width: max(0, list.bounds.width - horizontalInset * 2),
                height: layout.height
            )
            place(
                layout.node,
                in: rowFrame,
                on: list,
                environment: environment
            )
            let separatorVisibility = _listRowSeparatorVisibility(
                in: layout.node,
                edge: .bottom
            )
            if index + 1 < rowLayouts.count && separatorVisibility != .hidden {
                let separator = UIView(
                    frame: CGRect(
                        x: rowFrame.minX + 16,
                        y: rowFrame.maxY - 0.5,
                        width: max(0, rowFrame.width - 16),
                        height: 0.5
                    )
                )
                separator.backgroundColor = .separator
                separator.isUserInteractionEnabled = false
                separator.accessibilityIdentifier = "SwiftUI.List.separator.\(index)"
                list.addSubview(separator)
            }
            y += layout.height
        }
    }

    private static func _listRowSeparatorVisibility(
        in node: _OpenViewNode,
        edge: VerticalEdge.Set
    ) -> Visibility {
        guard case .modified(let content, let modification) = node.kind else {
            return .automatic
        }
        if case .listRowSeparator(let visibility, let edges) = modification,
           !edges.intersection(edge).isEmpty {
            return visibility
        }
        return _listRowSeparatorVisibility(in: content, edge: edge)
    }

    private static func placeNavigation(
        _ content: _OpenViewNode,
        configuration: _OpenNavigationConfiguration,
        in rect: CGRect,
        on surface: UIView,
        environment: _RenderEnvironment
    ) {
        let navigationView = UIView(frame: rect)
        navigationView.backgroundColor = .systemBackground
        navigationView.clipsToBounds = true
        navigationView.accessibilityIdentifier = "SwiftUI.NavigationView"
        surface.addSubview(navigationView)

        let hasBarContent = configuration.title != nil || configuration.toolbar != nil
        let barHeight = configuration.barHidden || !hasBarContent
            ? 0 : min(navigationBarHeight, navigationView.bounds.height)
        if let title = configuration.title, barHeight > 0 {
            let label = UILabel(
                frame: CGRect(
                    x: 16,
                    y: 0,
                    width: max(0, navigationView.bounds.width - 112),
                    height: barHeight
                )
            )
            label.text = title
            label.font = .systemFont(ofSize: 20, weight: .bold)
            label.textColor = .label
            label.accessibilityIdentifier = "SwiftUI.NavigationTitle"
            navigationView.addSubview(label)
        }
        if let toolbar = configuration.toolbar, barHeight > 0 {
            let measured = measure(
                toolbar,
                proposed: CGSize(width: 80, height: barHeight),
                environment: environment
            )
            let width = min(80, max(44, measured.width))
            place(
                toolbar,
                in: CGRect(
                    x: navigationView.bounds.width - width - 8,
                    y: 0,
                    width: width,
                    height: barHeight
                ),
                on: navigationView,
                environment: environment
            )
        }

        place(
            content,
            in: CGRect(
                x: 0,
                y: barHeight,
                width: navigationView.bounds.width,
                height: max(0, navigationView.bounds.height - barHeight)
            ),
            on: navigationView,
            environment: environment
        )
    }

    private static func placeHStack(
        _ children: [_OpenViewNode],
        alignment: _OpenVerticalAlignment,
        spacing: CGFloat,
        in rect: CGRect,
        on surface: UIView,
        environment: _RenderEnvironment
    ) {
        guard !children.isEmpty else { return }
        let sizes = children.map {
            measure($0, proposed: rect.size, environment: environment)
        }
        let spacerIndices = children.indices.filter { _isSpacer(children[$0]) }
        var widths = sizes.map(\.width)
        let fixedWidth = widths.enumerated().reduce(CGFloat.zero) { partial, entry in
            spacerIndices.contains(entry.offset) ? partial : partial + entry.element
        }
        let gaps = spacing * CGFloat(max(0, children.count - 1))
        var overflow = max(0, fixedWidth + gaps - rect.width)
        let compressionOrder = children.indices.sorted { lhs, rhs in
            let lhsPriority = _layoutPriority(children[lhs])
            let rhsPriority = _layoutPriority(children[rhs])
            if lhsPriority == rhsPriority { return lhs < rhs }
            return lhsPriority < rhsPriority
        }
        // Text is SwiftUI's compressible participant in Focus's title / spacer
        // / icon row.  Give it the short width and let UILabel honor the
        // minimumScaleFactor before sacrificing the trailing icon. Explicit
        // layout priority protects higher-priority title/content groups until
        // every lower-priority peer has yielded its available width.
        for index in compressionOrder where overflow > 0 && _containsText(children[index]) {
            let reduction = min(widths[index], overflow)
            widths[index] -= reduction
            overflow -= reduction
        }
        // A malformed or extremely small proposal can still over-constrain
        // non-text leaves.  Clamp them in source order rather than emitting
        // negative frames or placing later children beyond the padded edge.
        for index in compressionOrder where overflow > 0 && !spacerIndices.contains(index) {
            let reduction = min(widths[index], overflow)
            widths[index] -= reduction
            overflow -= reduction
        }
        let compressedFixedWidth = widths.enumerated().reduce(CGFloat.zero) { partial, entry in
            spacerIndices.contains(entry.offset) ? partial : partial + entry.element
        }
        let flexible = max(0, rect.width - compressedFixedWidth - gaps)
        let spacerWidth = spacerIndices.isEmpty ? 0 : flexible / CGFloat(spacerIndices.count)
        var x = rect.minX

        for index in children.indices {
            let size = sizes[index]
            let width = spacerIndices.contains(index)
                ? spacerWidth
                : min(widths[index], max(0, rect.maxX - x))
            let height = min(size.height, rect.height)
            let y: CGFloat
            switch alignment.value {
            case .top: y = rect.minY
            case .center: y = rect.minY + (rect.height - height) / 2
            case .bottom: y = rect.maxY - height
            }
            place(
                children[index],
                in: CGRect(x: x, y: y, width: max(0, width), height: max(0, height)),
                on: surface,
                environment: environment
            )
            x += width + spacing
        }
    }

    private static func placeVStack(
        _ children: [_OpenViewNode],
        alignment: _OpenHorizontalAlignment,
        spacing: CGFloat,
        in rect: CGRect,
        on surface: UIView,
        environment: _RenderEnvironment
    ) {
        guard !children.isEmpty else { return }
        let sizes = children.map {
            measure($0, proposed: rect.size, environment: environment)
        }
        let spacerIndices = children.indices.filter { _isSpacer(children[$0]) }
        let fixedHeight = sizes.enumerated().reduce(CGFloat.zero) { partial, entry in
            spacerIndices.contains(entry.offset) ? partial : partial + entry.element.height
        }
        let gaps = spacing * CGFloat(max(0, children.count - 1))
        let flexible = max(0, rect.height - fixedHeight - gaps)
        let spacerHeight = spacerIndices.isEmpty ? 0 : flexible / CGFloat(spacerIndices.count)
        var y = rect.minY

        for index in children.indices {
            let size = sizes[index]
            let height = spacerIndices.contains(index) ? spacerHeight : min(size.height, rect.maxY - y)
            let width = min(size.width, rect.width)
            let x: CGFloat
            switch alignment.value {
            case .leading: x = rect.minX
            case .center: x = rect.minX + (rect.width - width) / 2
            case .trailing: x = rect.maxX - width
            }
            place(
                children[index],
                in: CGRect(x: x, y: y, width: max(0, width), height: max(0, height)),
                on: surface,
                environment: environment
            )
            y += height + spacing
        }
    }

    private static func makeLabel(
        _ string: String,
        environment: _RenderEnvironment
    ) -> UILabel {
        let label = UILabel()
        label.text = string
        label.font = (environment.font ?? .body).resolve(weight: environment.weight)
        label.textColor = environment.foregroundColor?.resolve() ?? .label
        switch environment.textAlignment {
        case .leading: label.textAlignment = .left
        case .center: label.textAlignment = .center
        case .trailing: label.textAlignment = .right
        }
        label.adjustsFontSizeToFitWidth = environment.minimumScaleFactor > 0
        label.minimumScaleFactor = environment.minimumScaleFactor
        label.allowsDefaultTighteningForTruncation = environment.allowsTightening
        label.numberOfLines = max(0, environment.lineLimit ?? 0)
        label.lineBreakMode = environment.lineLimit == 1
            ? .byTruncatingTail
            : .byWordWrapping
        return label
    }

    private static func measureImage(
        _ source: _OpenImageSource,
        proposed: CGSize,
        environment: _RenderEnvironment
    ) -> CGSize {
        let natural: CGSize
        switch source {
        case .system:
            natural = CGSize(width: 18, height: 18)
        case .named(let name, let bundle):
            natural = UIImage(named: name, in: bundle, compatibleWith: nil)?.size
                ?? CGSize(width: 22, height: 22)
        case .uiImage(let image):
            natural = image.size
        }
        guard environment.imageResizable else {
            return CGSize(
                width: natural.width * environment.imageScale.factor,
                height: natural.height * environment.imageScale.factor
            )
        }
        let bounded = _bounded(proposed)
        guard natural.width > 0, natural.height > 0 else { return bounded }
        let sx = bounded.width / natural.width
        let sy = bounded.height / natural.height
        let factor = environment.imageContentMode == .fit ? min(sx, sy) : max(sx, sy)
        guard factor.isFinite, factor > 0 else { return natural }
        return CGSize(width: natural.width * factor, height: natural.height * factor)
    }

    private static func placeImage(
        _ source: _OpenImageSource,
        in rect: CGRect,
        on surface: UIView,
        environment: _RenderEnvironment
    ) {
        switch source {
        case .system(let name):
            let symbol = _SystemSymbolView(name: name)
            symbol.strokeColor = environment.foregroundColor?.resolve() ?? .label
            symbol.renderingMode = environment.symbolRenderingMode
            symbol.frame = rect
            symbol.accessibilityIdentifier = "SwiftUI.Image.systemName.\(name)"
            surface.addSubview(symbol)
        case .named(let name, let bundle):
            let raw = UIImage(named: name, in: bundle, compatibleWith: nil)
            let tinted = environment.foregroundColor.map { color in
                raw?.withTintColor(color.resolve())
            } ?? raw
            let imageView = UIImageView(image: tinted ?? nil)
            imageView.frame = rect
            imageView.contentMode = environment.imageContentMode == .fit
                ? .scaleAspectFit
                : .scaleAspectFill
            imageView.accessibilityIdentifier = "SwiftUI.Image.named.\(name)"
            surface.addSubview(imageView)
        case .uiImage(let image):
            let rendered = environment.foregroundColor.map { color in
                image.withTintColor(color.resolve())
            } ?? image
            let imageView = UIImageView(image: rendered)
            imageView.frame = rect
            imageView.contentMode = environment.imageContentMode == .fit
                ? .scaleAspectFit
                : .scaleAspectFill
            imageView.accessibilityIdentifier = "SwiftUI.Image.uiImage"
            surface.addSubview(imageView)
        }
    }

    private static func alignedRect(
        size: CGSize,
        in rect: CGRect,
        alignment: _OpenAlignment
    ) -> CGRect {
        let x: CGFloat
        switch alignment.horizontal.value {
        case .leading: x = rect.minX
        case .center: x = rect.minX + (rect.width - size.width) / 2
        case .trailing: x = rect.maxX - size.width
        }
        let y: CGFloat
        switch alignment.vertical.value {
        case .top: y = rect.minY
        case .center: y = rect.minY + (rect.height - size.height) / 2
        case .bottom: y = rect.maxY - size.height
        }
        return CGRect(origin: CGPoint(x: x, y: y), size: size)
    }

    private static func _isSpacer(_ node: _OpenViewNode) -> Bool {
        switch node.kind {
        case .spacer:
            return true
        case .modified(let content, _):
            return _isSpacer(content)
        default:
            return false
        }
    }

    private static func _containsText(_ node: _OpenViewNode) -> Bool {
        switch node.kind {
        case .text:
            return true
        case .modified(let content, _):
            return _containsText(content)
        case .group(let children), .hStack(let children, _, _),
             .vStack(let children, _, _), .zStack(let children, _),
             .grid(let children, _, _), .gridRow(let children):
            return children.contains(where: _containsText)
        case .button(let label, _, _, _), .link(let label, _),
             .navigationLink(let label, _), .toggle(let label, _, _):
            return _containsText(label)
        default:
            return false
        }
    }

    private static func _layoutPriority(_ node: _OpenViewNode) -> Double {
        switch node.kind {
        case .modified(_, .layoutPriority(let value)):
            return value
        case .modified(let content, _):
            return _layoutPriority(content)
        default:
            return 0
        }
    }

    private static func _zIndex(_ node: _OpenViewNode) -> Double {
        switch node.kind {
        case .modified(_, .zIndex(let value)):
            return value
        case .modified(let content, _):
            return _zIndex(content)
        default:
            return 0
        }
    }

    private static func _containsButton(_ node: _OpenViewNode) -> Bool {
        switch node.kind {
        case .button:
            return true
        case .navigationLink, .link:
            return true
        case .modified(let content, _):
            return _containsButton(content)
        case .group(let children), .hStack(let children, _, _),
             .vStack(let children, _, _), .zStack(let children, _),
             .form(let children), .list(let children),
             .grid(let children, _, _), .gridRow(let children):
            return children.contains(where: _containsButton)
        case .section(let header, let footer, let rows):
            return header.map(_containsButton) == true
                || footer.map(_containsButton) == true
                || rows.contains(where: _containsButton)
        case .toggle(let label, _, _):
            return _containsButton(label)
        case .picker(let label, let options, _, _):
            return _containsButton(label)
                || options.contains { _containsButton($0.content) }
        case .scroll(let content), .navigation(let content, _):
            return _containsButton(content)
        case .tabView(let pages, let selection, _, _):
            guard let selected = _openSelectedTabPage(
                pages: pages,
                selection: selection
            ) else { return false }
            return _containsButton(selected.page.content)
        default:
            return false
        }
    }

    private static func _pageIndicatorHeight(
        pageCount: Int,
        indexDisplayMode: PageTabViewStyle.IndexDisplayMode?
    ) -> CGFloat {
        switch indexDisplayMode {
        case .always:
            return 26
        case .automatic where pageCount > 1:
            return 26
        case .automatic, .never, .none:
            return 0
        }
    }

    private static func _bounded(_ size: CGSize) -> CGSize {
        CGSize(
            width: size.width.isFinite ? max(0, min(size.width, 10_000)) : 10_000,
            height: size.height.isFinite ? max(0, min(size.height, 10_000)) : 10_000
        )
    }

    private static func _controlExtent(_ size: ControlSize) -> CGFloat {
        switch size {
        case .mini: return 12
        case .small: return 16
        case .regular: return 20
        case .large: return 28
        case .extraLarge: return 36
        }
    }

    private static func _openReturnKeyType(_ label: SubmitLabel) -> UIReturnKeyType {
        switch label {
        case .done: return .done
        case .go: return .go
        case .send: return .send
        case .join: return .join
        case .route: return .route
        case .search: return .search
        case .return: return .default
        case .next: return .next
        case .continue: return .continue
        }
    }

    private static func _flexibleProposal(_ proposed: CGFloat, maximum: CGFloat?) -> CGFloat {
        guard let maximum else { return proposed }
        if maximum.isInfinite { return proposed }
        return min(proposed, max(0, maximum))
    }

    private static func _flexibleExtent(
        _ measured: CGFloat,
        proposed: CGFloat,
        minimum: CGFloat?,
        maximum: CGFloat?
    ) -> CGFloat {
        let lower = max(0, minimum ?? 0)
        guard let maximum else { return max(lower, min(measured, proposed)) }
        if maximum.isInfinite { return max(lower, max(0, proposed)) }
        return max(
            lower,
            min(max(0, measured), min(max(0, maximum), max(0, proposed)))
        )
    }
}

@MainActor
private final class _SystemSymbolView: UIView {
    let name: String
    var strokeColor: UIColor = .label
    var renderingMode: SymbolRenderingMode?

    init(name: String) {
        self.name = name
        super.init(frame: .zero)
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func drawContent(in canvas: Canvas, bounds: CGRect) {
        if name == "chevron.right" {
            let color = strokeColor.resolvedCGColor(with: traitCollection)
            var path = Path()
            path.move(to: CGPoint(x: bounds.minX + bounds.width * 0.2, y: bounds.minY))
            path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.midY))
            path.addLine(
                to: CGPoint(x: bounds.minX + bounds.width * 0.2, y: bounds.maxY)
            )
            canvas.stroke(path, color: color, lineWidth: max(1, bounds.width * 0.22))
            return
        }
        guard name == "magnifyingglass" else { return }
        let color = strokeColor.resolvedCGColor(with: traitCollection)
        let side = min(bounds.width, bounds.height)
        let lineWidth = max(1, side * 0.11)
        let circle = CGRect(
            x: bounds.minX + side * 0.08,
            y: bounds.minY + side * 0.08,
            width: side * 0.61,
            height: side * 0.61
        )
        var path = Path()
        let k: CGFloat = 0.5522847498307936
        let radius = circle.width / 2
        let center = CGPoint(x: circle.midX, y: circle.midY)
        path.move(to: CGPoint(x: center.x + radius, y: center.y))
        path.addCurve(
            to: CGPoint(x: center.x, y: center.y + radius),
            control1: CGPoint(x: center.x + radius, y: center.y + k * radius),
            control2: CGPoint(x: center.x + k * radius, y: center.y + radius)
        )
        path.addCurve(
            to: CGPoint(x: center.x - radius, y: center.y),
            control1: CGPoint(x: center.x - k * radius, y: center.y + radius),
            control2: CGPoint(x: center.x - radius, y: center.y + k * radius)
        )
        path.addCurve(
            to: CGPoint(x: center.x, y: center.y - radius),
            control1: CGPoint(x: center.x - radius, y: center.y - k * radius),
            control2: CGPoint(x: center.x - k * radius, y: center.y - radius)
        )
        path.addCurve(
            to: CGPoint(x: center.x + radius, y: center.y),
            control1: CGPoint(x: center.x + k * radius, y: center.y - radius),
            control2: CGPoint(x: center.x + radius, y: center.y - k * radius)
        )
        path.move(to: CGPoint(x: circle.maxX - lineWidth / 2, y: circle.maxY - lineWidth / 2))
        path.addLine(to: CGPoint(x: bounds.minX + side * 0.92, y: bounds.minY + side * 0.92))
        canvas.stroke(path, color: color, lineWidth: lineWidth)
    }
}
