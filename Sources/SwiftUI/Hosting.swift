#if canImport(Foundation)
import Foundation
#endif
import OpenUIKit

private enum _OpenAppearanceIdentity: Hashable {
    case graph(_OpenGraphIdentity)
    case ephemeral(ObjectIdentifier)
}

/// Structural SwiftUI wrappers must not become accidental touch targets.
/// They still expose interactive descendants (notably nested Buttons), while
/// their otherwise-transparent surface falls through to the enclosing view.
@MainActor
private final class _SwiftUIPassthroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return hit === self ? nil : hit
    }
}

/// OpenUIKit-backed host for the SwiftUI tree and its retained dynamic state.
@preconcurrency @MainActor
open class _OpenUIHostingController<Content: _OpenView>: UIViewController {
    private let graph = _OpenGraphHost()
    private var installedRepresentedControllers: [ObjectIdentifier: UIViewController] = [:]
    private var pendingRepresentedControllerMoves: Set<ObjectIdentifier> = []
    private var appearanceTransitionChildren: Set<ObjectIdentifier> = []
    private var activeAppearActions: [
        _OpenAppearanceIdentity: @MainActor () -> Void
    ] = [:]
    private var deliveredAppearActions: Set<_OpenAppearanceIdentity> = []
    private var hostIsVisible = false

    public var rootView: Content {
        didSet {
            guard viewIfLoaded is _SwiftUIHostingView else { return }
            install(graph.evaluate(rootView))
        }
    }

    public init(rootView: Content) {
        self.rootView = rootView
        super.init()
        graph.invalidate = { [weak self] in
            guard let self,
                  self.viewIfLoaded is _SwiftUIHostingView else { return }
            self.install(self.graph.evaluate(self.rootView))
        }
    }

    open override func loadView() {
        let node = graph.evaluate(rootView)
        let host = _SwiftUIHostingView(node: node)
        host.didCompleteLayout = { [weak self] in
            self?.completeRepresentedControllerMounts()
        }
        view = host
        install(node)
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
        deliveredAppearActions.removeAll(keepingCapacity: true)
    }

    private func install(_ node: _OpenViewNode) {
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

        activeAppearActions = _openAppearanceActions(in: node)
        deliveredAppearActions.formIntersection(activeAppearActions.keys)
        host.node = node
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
        for (key, action) in activeAppearActions
        where !deliveredAppearActions.contains(key) {
            action()
            deliveredAppearActions.insert(key)
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
        case .viewController(let controller):
            if identities.insert(ObjectIdentifier(controller)).inserted {
                result.append(controller)
            }
        case .group(let children), .hStack(let children, _, _),
             .vStack(let children, _, _), .zStack(let children, _),
             .form(let children):
            children.forEach(visit)
        case .button(let label, _), .scroll(let label):
            visit(label)
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
                 .toolbar(let auxiliary):
                visit(auxiliary)
            default:
                break
            }
        case .empty, .text, .image, .color, .roundedRectangle, .spacer, .gradient:
            break
        }
    }

    visit(root)
    return result
}

@MainActor
private func _openAppearanceActions(
    in root: _OpenViewNode
) -> [_OpenAppearanceIdentity: @MainActor () -> Void] {
    var result: [_OpenAppearanceIdentity: @MainActor () -> Void] = [:]

    func visit(_ node: _OpenViewNode) {
        switch node.kind {
        case .group(let children), .hStack(let children, _, _),
             .vStack(let children, _, _), .zStack(let children, _),
             .form(let children):
            children.forEach(visit)
        case .button(let label, _), .scroll(let label):
            visit(label)
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
                result[key] = action
            }
            visit(content)
            switch modification {
            case .background(let auxiliary, _), .overlay(let auxiliary, _),
                 .toolbar(let auxiliary):
                visit(auxiliary)
            default:
                break
            }
        case .empty, .text, .image, .color, .roundedRectangle, .spacer,
             .viewController, .gradient:
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
        for child in subviews {
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
    var foregroundColor: _OpenColor?
    var textAlignment: _OpenTextAlignment = .leading
    var imageResizable = false
    var imageContentMode: _OpenContentMode = .fit
    var measuresUnboundedVerticalScroll = false
    var simultaneousTapActions: [@MainActor () -> Void] = []

    static let `default` = _RenderEnvironment()
}

@MainActor
private enum _ViewRenderer {
    static let defaultSpacing: CGFloat = 8
    static let defaultFormRowHeight: CGFloat = 44
    static let navigationBarHeight: CGFloat = 52

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
        case .color, .roundedRectangle:
            return _bounded(proposed)
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
        case .button(let label, _):
            return measure(label, proposed: proposed, environment: environment)
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
            case .foregroundColor(let color):
                var next = environment
                next.foregroundColor = color
                return measure(content, proposed: proposed, environment: next)
            case .resizable:
                var next = environment
                next.imageResizable = true
                return measure(content, proposed: proposed, environment: next)
            case .aspectRatio(let contentMode):
                var next = environment
                next.imageContentMode = contentMode
                return measure(content, proposed: proposed, environment: next)
            case .frame(let width, let height, _):
                let childProposal = CGSize(
                    width: width ?? proposed.width,
                    height: height ?? proposed.height
                )
                let child = measure(content, proposed: childProposal, environment: environment)
                return CGSize(width: width ?? child.width, height: height ?? child.height)
            case .flexibleFrame(let maxWidth, let maxHeight, _):
                let proposedWidth = _flexibleProposal(proposed.width, maximum: maxWidth)
                let proposedHeight = _flexibleProposal(proposed.height, maximum: maxHeight)
                let child = measure(
                    content,
                    proposed: CGSize(width: proposedWidth, height: proposedHeight),
                    environment: environment
                )
                return CGSize(
                    width: _flexibleExtent(child.width, proposed: proposed.width, maximum: maxWidth),
                    height: _flexibleExtent(child.height, proposed: proposed.height, maximum: maxHeight)
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
            case .overlay:
                return measure(content, proposed: proposed, environment: environment)
            case .multilineTextAlignment(let alignment):
                var next = environment
                next.textAlignment = alignment
                return measure(content, proposed: proposed, environment: next)
            case .tapAction, .simultaneousTapAction, .onAppear,
                 .shadow, .colorScheme, .safeAreaIgnored:
                return measure(content, proposed: proposed, environment: environment)
            case .previewLayout:
                return measure(content, proposed: proposed, environment: environment)
            case .clipRoundedRectangle:
                return measure(content, proposed: proposed, environment: environment)
            case .navigationTitle, .navigationBarHidden,
                 .navigationBackButtonHidden, .navigationTitleDisplayMode,
                 .toolbar, .tag, .pageTabViewStyle:
                return measure(content, proposed: proposed, environment: environment)
            }
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
        case .spacer:
            return
        case .gradient(let gradient, let start, let end):
            let view = UIGradientView(frame: rect)
            view.isUserInteractionEnabled = false
            view.colors = gradient.colors.map { $0.resolve() }
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
            for child in children {
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
        case .button(let label, let action):
            let control = UIControl(frame: rect)
            control.isOpaque = false
            control.backgroundColor = .clear
            control.accessibilityIdentifier = "SwiftUI.Button"
            control.addTarget(for: .touchUpInside) { _, _ in action() }
            for simultaneousAction in environment.simultaneousTapActions {
                control.addTarget(for: .touchUpInside) { _, _ in simultaneousAction() }
            }
            surface.addSubview(control)
            place(label, in: control.bounds, on: control, environment: environment)
        case .scroll(let content):
            let scrollView = UIScrollView(frame: rect)
            scrollView.accessibilityIdentifier = "SwiftUI.ScrollView"
            surface.addSubview(scrollView)
            var measurementEnvironment = environment
            measurementEnvironment.measuresUnboundedVerticalScroll = true
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
                environment: environment
            )
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
        case .viewController(let controller):
            controller.loadViewIfNeeded()
            guard let hosted = controller.view else { return }
            hosted.frame = rect
            hosted.accessibilityIdentifier = hosted.accessibilityIdentifier
                ?? "SwiftUI.UIViewControllerRepresentable"
            surface.addSubview(hosted)
        case .form(let rows):
            placeForm(rows, in: rect, on: surface, environment: environment)
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
            case .foregroundColor(let color):
                var next = environment
                next.foregroundColor = color
                place(content, in: rect, on: surface, environment: next)
            case .resizable:
                var next = environment
                next.imageResizable = true
                place(content, in: rect, on: surface, environment: next)
            case .aspectRatio(let contentMode):
                var next = environment
                next.imageContentMode = contentMode
                place(content, in: rect, on: surface, environment: next)
            case .frame(let width, let height, let alignment):
                let measured = measure(content, proposed: rect.size, environment: environment)
                let size = CGSize(width: width ?? min(rect.width, measured.width),
                                  height: height ?? min(rect.height, measured.height))
                let childRect = alignedRect(size: size, in: rect, alignment: alignment)
                place(content, in: childRect, on: surface, environment: environment)
            case .flexibleFrame(let maxWidth, let maxHeight, let alignment):
                let measured = measure(content, proposed: rect.size, environment: environment)
                let size = CGSize(
                    width: _flexibleExtent(measured.width, proposed: rect.width, maximum: maxWidth),
                    height: _flexibleExtent(measured.height, proposed: rect.height, maximum: maxHeight)
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
            case .overlay(let overlay, _):
                place(content, in: rect, on: surface, environment: environment)
                place(overlay, in: rect, on: surface, environment: environment)
            case .multilineTextAlignment(let alignment):
                var next = environment
                next.textAlignment = alignment
                place(content, in: rect, on: surface, environment: next)
            case .tapAction(let action):
                let control = UIControl(frame: rect)
                control.isOpaque = false
                control.backgroundColor = .clear
                control.accessibilityIdentifier = "SwiftUI.TapGesture"
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
                    control.addTarget(for: .touchUpInside) { _, _ in action() }
                    surface.addSubview(control)
                    place(content, in: control.bounds, on: control, environment: environment)
                }
            case .onAppear:
                place(content, in: rect, on: surface, environment: environment)
            case .shadow(let radius):
                let shadowHost = _SwiftUIPassthroughView(frame: rect)
                shadowHost.backgroundColor = .clear
                shadowHost.isOpaque = false
                shadowHost.layer.shadowColor = UIColor.black.cgColor
                shadowHost.layer.shadowOpacity = 0.33
                shadowHost.layer.shadowRadius = radius
                shadowHost.layer.shadowOffset = .zero
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
            case .navigationTitle, .navigationBarHidden,
                 .navigationBackButtonHidden, .navigationTitleDisplayMode,
                 .toolbar, .tag, .pageTabViewStyle:
                // NavigationView consumes this metadata while building its
                // node.  Outside a NavigationView it leaves content intact.
                place(content, in: rect, on: surface, environment: environment)
            }
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
        // Text is SwiftUI's compressible participant in Focus's title / spacer
        // / icon row.  Give it the short width and let UILabel honor the
        // minimumScaleFactor before sacrificing the trailing icon.
        for index in children.indices where overflow > 0 && _containsText(children[index]) {
            let reduction = min(widths[index], overflow)
            widths[index] -= reduction
            overflow -= reduction
        }
        // A malformed or extremely small proposal can still over-constrain
        // non-text leaves.  Clamp them in source order rather than emitting
        // negative frames or placing later children beyond the padded edge.
        for index in children.indices where overflow > 0 && !spacerIndices.contains(index) {
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
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
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
        guard environment.imageResizable else { return natural }
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
        if case .spacer = node.kind { return true }
        return false
    }

    private static func _containsText(_ node: _OpenViewNode) -> Bool {
        switch node.kind {
        case .text:
            return true
        case .modified(let content, _):
            return _containsText(content)
        case .group(let children):
            return children.contains(where: _containsText)
        default:
            return false
        }
    }

    private static func _containsButton(_ node: _OpenViewNode) -> Bool {
        switch node.kind {
        case .button:
            return true
        case .modified(let content, _):
            return _containsButton(content)
        case .group(let children), .hStack(let children, _, _),
             .vStack(let children, _, _), .zStack(let children, _),
             .form(let children):
            return children.contains(where: _containsButton)
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

    private static func _flexibleProposal(_ proposed: CGFloat, maximum: CGFloat?) -> CGFloat {
        guard let maximum else { return proposed }
        if maximum.isInfinite { return proposed }
        return min(proposed, max(0, maximum))
    }

    private static func _flexibleExtent(
        _ measured: CGFloat,
        proposed: CGFloat,
        maximum: CGFloat?
    ) -> CGFloat {
        guard let maximum else { return min(measured, proposed) }
        if maximum.isInfinite { return max(0, proposed) }
        return min(max(0, measured), min(max(0, maximum), max(0, proposed)))
    }
}

@MainActor
private final class _SystemSymbolView: UIView {
    let name: String
    var strokeColor: UIColor = .label

    init(name: String) {
        self.name = name
        super.init(frame: .zero)
        isOpaque = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func drawContent(in canvas: Canvas, bounds: CGRect) {
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
