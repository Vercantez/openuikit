#if canImport(Foundation)
import Foundation
#endif
import OpenUIKit

/// OpenUIKit-backed host for the stateless S1/S1.5 SwiftUI tree.
@preconcurrency @MainActor
open class _OpenUIHostingController<Content: _OpenView>: UIViewController {
    public var rootView: Content {
        didSet {
            guard let host = viewIfLoaded as? _SwiftUIHostingView else { return }
            host.node = rootView._makeOpenUIKitNode()
        }
    }

    public init(rootView: Content) {
        self.rootView = rootView
        super.init()
    }

    open override func loadView() {
        view = _SwiftUIHostingView(node: rootView._makeOpenUIKitNode())
    }
}

public typealias UIHostingController<Content> = _OpenUIHostingController<Content>
    where Content: _OpenView

@MainActor
private final class _SwiftUIHostingView: UIView {
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
    var imageResizable = false
    var imageContentMode: _OpenContentMode = .fit

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
            if children.contains(where: _isSpacer) {
                height = max(height, _bounded(proposed).height)
            }
            return CGSize(width: width, height: height)
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
        case .navigation(let content, let title):
            let barHeight = title == nil ? 0 : navigationBarHeight
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
            case .background:
                return measure(content, proposed: proposed, environment: environment)
            case .overlay:
                return measure(content, proposed: proposed, environment: environment)
            case .previewLayout:
                return measure(content, proposed: proposed, environment: environment)
            case .clipRoundedRectangle:
                return measure(content, proposed: proposed, environment: environment)
            case .navigationTitle:
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
            view.accessibilityIdentifier = "SwiftUI.Color"
            surface.addSubview(view)
        case .roundedRectangle(let cornerRadius, let style):
            let view = UIView(frame: rect)
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
        case .form(let rows):
            placeForm(rows, in: rect, on: surface, environment: environment)
        case .navigation(let content, let title):
            placeNavigation(
                content,
                title: title,
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
            case .padding(let edges, let length):
                let amount = max(0, length ?? 16)
                let inset = UIEdgeInsets(
                    top: edges.contains(.top) ? amount : 0,
                    left: edges.contains(.leading) ? amount : 0,
                    bottom: edges.contains(.bottom) ? amount : 0,
                    right: edges.contains(.trailing) ? amount : 0
                )
                place(content, in: rect.inset(by: inset), on: surface, environment: environment)
            case .background(let background, _):
                place(background, in: rect, on: surface, environment: environment)
                place(content, in: rect, on: surface, environment: environment)
            case .overlay(let overlay, _):
                place(content, in: rect, on: surface, environment: environment)
                place(overlay, in: rect, on: surface, environment: environment)
            case .previewLayout:
                place(content, in: rect, on: surface, environment: environment)
            case .clipRoundedRectangle(let radius):
                if surface is _SwiftUIHostingView, rect == surface.bounds {
                    surface.layer.cornerRadius = radius
                    surface.clipsToBounds = radius > 0
                    place(content, in: rect, on: surface, environment: environment)
                } else {
                    let clippingView = UIView(frame: rect)
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
            case .navigationTitle:
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
        title: String?,
        in rect: CGRect,
        on surface: UIView,
        environment: _RenderEnvironment
    ) {
        let navigationView = UIView(frame: rect)
        navigationView.backgroundColor = .systemBackground
        navigationView.clipsToBounds = true
        navigationView.accessibilityIdentifier = "SwiftUI.NavigationView"
        surface.addSubview(navigationView)

        let barHeight = title == nil ? 0 : min(navigationBarHeight, navigationView.bounds.height)
        if let title {
            let label = UILabel(
                frame: CGRect(x: 16, y: 0, width: max(0, navigationView.bounds.width - 32), height: barHeight)
            )
            label.text = title
            label.font = .systemFont(ofSize: 20, weight: .bold)
            label.textColor = .label
            label.accessibilityIdentifier = "SwiftUI.NavigationTitle"
            navigationView.addSubview(label)
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
        label.adjustsFontSizeToFitWidth = environment.minimumScaleFactor > 0
        label.minimumScaleFactor = environment.minimumScaleFactor
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

    private static func _bounded(_ size: CGSize) -> CGSize {
        CGSize(
            width: size.width.isFinite ? max(0, min(size.width, 10_000)) : 10_000,
            height: size.height.isFinite ? max(0, min(size.height, 10_000)) : 10_000
        )
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
