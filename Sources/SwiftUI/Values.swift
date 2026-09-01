#if canImport(Foundation)
import Foundation
#endif
import OpenUIKit

public struct _OpenFont: Hashable, Sendable {
    public enum TextStyle: Hashable, Sendable {
        case largeTitle
        case title
        case title2
        case headline
        case body
        case callout
        case subheadline
        case footnote
        case caption
        case caption2
        case title3
    }

    public struct Weight: Hashable, Sendable {
        let value: UIFont.Weight

        init(_ value: UIFont.Weight) {
            self.value = value
        }

        public static let regular = Weight(.regular)
        public static let medium = Weight(.medium)
        public static let semibold = Weight(.semibold)
        public static let bold = Weight(.bold)
    }

    /// SwiftUI exposes the same three system-font designs as UIFont. Keeping
    /// the public spelling nested under Font lets unchanged app code use
    /// `.system(size:weight:design:)` while the renderer continues to carry
    /// OpenUIKit's measured font descriptor directly.
    public typealias Design = UIFont.Design

    enum Storage: Hashable, Sendable {
        case textStyle(TextStyle)
        case uiFont(pointSize: CGFloat, weight: UIFont.Weight, design: UIFont.Design)
    }

    let storage: Storage

    private init(_ style: TextStyle) {
        storage = .textStyle(style)
    }

    /// CoreText is toll-free bridged to UIFont on Apple platforms.  The
    /// portable bridge preserves the same source spelling while carrying the
    /// immutable OpenUIKit font metrics directly.
    public init(_ font: CTFont) {
        storage = .uiFont(
            pointSize: font.pointSize,
            weight: font.weight,
            design: font.design
        )
    }

    public static let largeTitle = _OpenFont(.largeTitle)
    public static let title = _OpenFont(.title)
    public static let title2 = _OpenFont(.title2)
    public static let headline = _OpenFont(.headline)
    public static let body = _OpenFont(.body)
    public static let callout = _OpenFont(.callout)
    public static let subheadline = _OpenFont(.subheadline)
    public static let footnote = _OpenFont(.footnote)
    public static let caption = _OpenFont(.caption)
    public static let caption2 = _OpenFont(.caption2)
    public static let title3 = _OpenFont(.title3)

    public static func system(size: CGFloat) -> _OpenFont {
        _OpenFont(
            storage: .uiFont(pointSize: size, weight: .regular, design: .default)
        )
    }


    public static func system(
        size: CGFloat,
        weight: Weight = .regular,
        design: Design = .default
    ) -> _OpenFont {
        _OpenFont(
            storage: .uiFont(pointSize: size, weight: weight.value, design: design)
        )
    }

    public func bold() -> _OpenFont {
        weight(.bold)
    }

    /// Returns the same semantic text style or concrete font descriptor with
    /// a different weight. Unlike the view-level `fontWeight`, this value
    /// transformation composes before the font reaches the render
    /// environment (`.font(.headline.weight(.semibold))`).
    public func weight(_ weight: Weight) -> _OpenFont {
        switch storage {
        case .textStyle(let style):
            let pointSize: CGFloat
            switch style {
            case .largeTitle: pointSize = 34
            case .title: pointSize = 28
            case .title2: pointSize = 22
            case .title3: pointSize = 20
            case .headline, .body: pointSize = 17
            case .callout: pointSize = 16
            case .subheadline: pointSize = 15
            case .footnote: pointSize = 13
            case .caption: pointSize = 12
            case .caption2: pointSize = 11
            }
            return _OpenFont(
                storage: .uiFont(
                    pointSize: pointSize,
                    weight: weight.value,
                    design: .default
                )
            )
        case .uiFont(let pointSize, _, let design):
            return _OpenFont(
                storage: .uiFont(
                    pointSize: pointSize,
                    weight: weight.value,
                    design: design
                )
            )
        }
    }

    private init(storage: Storage) {
        self.storage = storage
    }

    func resolve(weight override: Weight?) -> UIFont {
        switch storage {
        case .textStyle(let style):
            let size: CGFloat
            switch style {
            case .largeTitle: size = 34
            case .title: size = 28
            case .title2: size = 22
            case .title3: size = 20
            case .callout: size = 16
            case .subheadline: size = 15
            case .footnote: size = 13
            case .caption: size = 12
            case .caption2: size = 11
            case .headline, .body: size = 17
            }
            let weight: UIFont.Weight = override?.value
                ?? (style == .headline ? .semibold : .regular)
            return .systemFont(ofSize: size, weight: weight)
        case .uiFont(let pointSize, let storedWeight, let design):
            let descriptor = UIFontDescriptor(
                pointSize: pointSize,
                weight: override?.value ?? storedWeight,
                design: design
            )
            return UIFont(descriptor: descriptor, size: pointSize)
        }
    }
}

/// Source-compatible CoreText bridge for Focus's `Font(uiFont as CTFont)`.
/// OpenUIKit's UIFont is already a value type carrying the portable metrics,
/// so the non-Darwin representation needs no opaque CoreText object.
public typealias CTFont = UIFont

public struct _OpenColor: Hashable, @unchecked Sendable {
    indirect enum Storage {
        case resolved(UIColor)
        case named(String, Bundle?)
        case opacity(Storage, CGFloat)
    }

    let storage: Storage

    public init(_ name: String, bundle: Bundle? = nil) {
        storage = .named(name, bundle)
    }

    public init(uiColor: UIColor) {
        storage = .resolved(uiColor)
    }

    public init(_ uiColor: UIColor) {
        storage = .resolved(uiColor)
    }

    public static let clear = _OpenColor(uiColor: .clear)
    public static let black = _OpenColor(uiColor: .black)
    public static let white = _OpenColor(uiColor: .white)
    public static let red = _OpenColor(uiColor: .red)
    public static let green = _OpenColor(uiColor: .green)
    public static let blue = _OpenColor(uiColor: .blue)
    public static let gray = _OpenColor(uiColor: .gray)
    public static let primary = _OpenColor(uiColor: .label)
    public static let secondary = _OpenColor(uiColor: .secondaryLabel)

    public func opacity(_ opacity: Double) -> _OpenColor {
        _OpenColor(storage: .opacity(storage, CGFloat(min(max(opacity, 0), 1))))
    }

    private init(storage: Storage) {
        self.storage = storage
    }

    public static func == (lhs: _OpenColor, rhs: _OpenColor) -> Bool {
        storageEqual(lhs.storage, rhs.storage)
    }

    public func hash(into hasher: inout Hasher) {
        Self.hash(storage, into: &hasher)
    }

    private static func storageEqual(_ lhs: Storage, _ rhs: Storage) -> Bool {
        switch (lhs, rhs) {
        case (.resolved(let lhs), .resolved(let rhs)):
            return lhs == rhs
        case (.named(let lhsName, let lhsBundle),
              .named(let rhsName, let rhsBundle)):
            return lhsName == rhsName
                && lhsBundle?.bundlePath == rhsBundle?.bundlePath
        case (.opacity(let lhsStorage, let lhsOpacity),
              .opacity(let rhsStorage, let rhsOpacity)):
            return lhsOpacity == rhsOpacity && storageEqual(lhsStorage, rhsStorage)
        default:
            return false
        }
    }

    private static func hash(_ storage: Storage, into hasher: inout Hasher) {
        switch storage {
        case .resolved(let color):
            hasher.combine(0)
            hasher.combine(color)
        case .named(let name, let bundle):
            hasher.combine(1)
            hasher.combine(name)
            hasher.combine(bundle?.bundlePath)
        case .opacity(let nested, let opacity):
            hasher.combine(2)
            hash(nested, into: &hasher)
            hasher.combine(opacity)
        }
    }

    @MainActor
    func resolve() -> UIColor {
        switch storage {
        case .resolved(let color):
            return color
        case .named(let name, let bundle):
            return UIColor(named: name, in: bundle, compatibleWith: nil) ?? .clear
        case .opacity(let storage, let opacity):
            let base = _OpenColor(storage: storage).resolve()
            return base.withAlphaComponent(base.cgColor.alpha * opacity)
        }
    }
}

/// The app-facing shape-style protocol used by foregroundStyle. The portable
/// renderer resolves a style to a deterministic foreground color today; the
/// protocol boundary leaves room for true masked gradient rendering without
/// changing application source or ABI.
@MainActor
public protocol _OpenShapeStyle {
    func _openResolvedForegroundColor() -> _OpenColor
}

extension _OpenColor: _OpenShapeStyle {
    public func _openResolvedForegroundColor() -> _OpenColor { self }
}

/// Color's concrete static members remain available when generic
/// foregroundStyle inference starts from `some ShapeStyle` (for example
/// `.foregroundStyle(.white)`).  Keep semantic primary/secondary on the
/// hierarchical style below so those spellings retain adaptive label colors.
public extension _OpenShapeStyle where Self == _OpenColor {
    static var clear: _OpenColor { .clear }
    static var black: _OpenColor { .black }
    static var white: _OpenColor { .white }
    static var red: _OpenColor { .red }
    static var green: _OpenColor { .green }
    static var blue: _OpenColor { .blue }
    static var gray: _OpenColor { .gray }
    static var orange: _OpenColor { _OpenColor(uiColor: UIColor.orange) }
}

public struct _OpenHierarchicalShapeStyle: _OpenShapeStyle, Sendable {
    enum Level: Sendable { case primary, secondary, tertiary, quaternary }
    let level: Level

    public func _openResolvedForegroundColor() -> _OpenColor {
        switch level {
        case .primary: return .primary
        case .secondary: return .secondary
        case .tertiary:
            return _OpenColor(uiColor: .tertiaryLabel)
        case .quaternary:
            return _OpenColor(uiColor: .quaternaryLabel)
        }
    }
}

public extension _OpenShapeStyle where Self == _OpenHierarchicalShapeStyle {
    static var primary: _OpenHierarchicalShapeStyle {
        _OpenHierarchicalShapeStyle(level: .primary)
    }

    static var secondary: _OpenHierarchicalShapeStyle {
        _OpenHierarchicalShapeStyle(level: .secondary)
    }

    static var tertiary: _OpenHierarchicalShapeStyle {
        _OpenHierarchicalShapeStyle(level: .tertiary)
    }

    static var quaternary: _OpenHierarchicalShapeStyle {
        _OpenHierarchicalShapeStyle(level: .quaternary)
    }
}

public struct _OpenGradient: Sendable {
    public struct Stop: Sendable {
        public let color: _OpenColor
        public let location: CGFloat

        public init(color: _OpenColor, location: CGFloat) {
            self.color = color
            self.location = min(max(location, 0), 1)
        }
    }

    public let stops: [Stop]

    public var colors: [_OpenColor] { stops.map(\.color) }

    public init(colors: [_OpenColor]) {
        guard colors.count > 1 else {
            stops = colors.map { Stop(color: $0, location: 0) }
            return
        }
        let denominator = CGFloat(colors.count - 1)
        stops = colors.enumerated().map { index, color in
            Stop(color: color, location: CGFloat(index) / denominator)
        }
    }

    public init(stops: [Stop]) {
        // UIKit's gradient layer consumes monotonically ordered locations.
        // SwiftUI accepts caller order, but sorting here gives the portable
        // rasterizer deterministic behavior for malformed or reversed input.
        self.stops = stops.enumerated().sorted { lhs, rhs in
            if lhs.element.location == rhs.element.location {
                return lhs.offset < rhs.offset
            }
            return lhs.element.location < rhs.element.location
        }.map(\.element)
    }
}

// The implementation name is intentionally distinct from Apple's historical
// ABI symbol (`SwiftUI.UnitPoint`).  New Apple SDKs annotate SwiftUICore's
// type as originally-defined-in SwiftUI; a local nominal with that exact
// mangling makes the Darwin compiler's mandatory SIL linker abort.  The public
// source spelling remains UnitPoint through the alias below, while Linux has
// no such SDK collision either way.
public struct _OpenUnitPoint: Equatable, Sendable {
    public let x: CGFloat
    public let y: CGFloat

    public init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }

    public static let topLeading = _OpenUnitPoint(x: 0, y: 0)
    public static let top = _OpenUnitPoint(x: 0.5, y: 0)
    public static let topTrailing = _OpenUnitPoint(x: 1, y: 0)
    public static let leading = _OpenUnitPoint(x: 0, y: 0.5)
    public static let center = _OpenUnitPoint(x: 0.5, y: 0.5)
    public static let trailing = _OpenUnitPoint(x: 1, y: 0.5)
    public static let bottomLeading = _OpenUnitPoint(x: 0, y: 1)
    public static let bottom = _OpenUnitPoint(x: 0.5, y: 1)
    public static let bottomTrailing = _OpenUnitPoint(x: 1, y: 1)
}

public typealias UnitPoint = _OpenUnitPoint

public struct _OpenHorizontalAlignment: Equatable, Sendable {
    enum Value: Equatable, Sendable { case leading, center, trailing }
    let value: Value

    private init(_ value: Value) { self.value = value }

    public static let leading = _OpenHorizontalAlignment(.leading)
    public static let center = _OpenHorizontalAlignment(.center)
    public static let trailing = _OpenHorizontalAlignment(.trailing)
}

public struct _OpenVerticalAlignment: Equatable, Sendable {
    enum Value: Equatable, Sendable { case top, center, bottom }
    let value: Value

    private init(_ value: Value) { self.value = value }

    public static let top = _OpenVerticalAlignment(.top)
    public static let center = _OpenVerticalAlignment(.center)
    public static let bottom = _OpenVerticalAlignment(.bottom)
}

public struct _OpenAlignment: Equatable, Sendable {
    public let horizontal: _OpenHorizontalAlignment
    public let vertical: _OpenVerticalAlignment

    public init(horizontal: _OpenHorizontalAlignment, vertical: _OpenVerticalAlignment) {
        self.horizontal = horizontal
        self.vertical = vertical
    }

    public static let center = _OpenAlignment(horizontal: .center, vertical: .center)
    public static let top = _OpenAlignment(horizontal: .center, vertical: .top)
    public static let topLeading = _OpenAlignment(horizontal: .leading, vertical: .top)
    public static let topTrailing = _OpenAlignment(horizontal: .trailing, vertical: .top)
    public static let leading = _OpenAlignment(horizontal: .leading, vertical: .center)
    public static let trailing = _OpenAlignment(horizontal: .trailing, vertical: .center)
    public static let bottom = _OpenAlignment(horizontal: .center, vertical: .bottom)
    public static let bottomLeading = _OpenAlignment(horizontal: .leading, vertical: .bottom)
    public static let bottomTrailing = _OpenAlignment(horizontal: .trailing, vertical: .bottom)
}

public enum _OpenEdge: Int, Hashable, Sendable {
    case top
    case leading
    case bottom
    case trailing

    public struct Set: OptionSet, Sendable {
        public let rawValue: UInt8

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        public static let top = Set(rawValue: 1 << _OpenEdge.top.rawValue)
        public static let leading = Set(rawValue: 1 << _OpenEdge.leading.rawValue)
        public static let bottom = Set(rawValue: 1 << _OpenEdge.bottom.rawValue)
        public static let trailing = Set(rawValue: 1 << _OpenEdge.trailing.rawValue)
        public static let horizontal: Set = [.leading, .trailing]
        public static let vertical: Set = [.top, .bottom]
        public static let all: Set = [.horizontal, .vertical]
    }
}

/// The vertical-only edge domain used by row-separator configuration. It is
/// intentionally distinct from `Edge.Set`: this keeps contextual `.top` and
/// `.bottom` inference identical to SwiftUI and prevents meaningless leading
/// or trailing separator requests from entering the retained graph.
public enum _OpenVerticalEdge: UInt8, Hashable, Sendable {
    case top
    case bottom

    public struct Set: OptionSet, Hashable, Sendable {
        public let rawValue: UInt8

        public init(rawValue: UInt8) { self.rawValue = rawValue }

        public static let top = Set(rawValue: 1 << 0)
        public static let bottom = Set(rawValue: 1 << 1)
        public static let all: Set = [.top, .bottom]
    }
}

public enum _OpenContentMode: Sendable {
    case fit
    case fill
}

public enum _OpenButtonRole: Sendable {
    case destructive
    case cancel
}

/// The two layout axes.  SwiftUI models the single-axis spelling separately
/// from `Axis.Set`; text fields use the former while scroll containers use the
/// latter.  Keeping the raw value stable makes the value cheap to carry in a
/// retained render node.
public enum _OpenAxis: UInt8, Hashable, Sendable {
    case horizontal
    case vertical

    public struct Set: OptionSet, Hashable, Sendable {
        public let rawValue: UInt8

        public init(rawValue: UInt8) { self.rawValue = rawValue }

        public static let horizontal = Set(rawValue: 1 << 0)
        public static let vertical = Set(rawValue: 1 << 1)
        public static let all: Set = [.horizontal, .vertical]
    }
}

public enum _OpenSubmitLabel: UInt8, Hashable, Sendable {
    case done
    case go
    case send
    case join
    case route
    case search
    case `return`
    case next
    case `continue`
}

/// Relative symbol/image sizing carried through the SwiftUI render
/// environment. The scale applies to non-resizable images and SF Symbols;
/// explicit frames and resizable content continue to own their dimensions.
public enum _OpenImageScale: UInt8, Hashable, Sendable {
    case small
    case medium
    case large

    var factor: CGFloat {
        switch self {
        case .small: return 0.75
        case .medium: return 1
        case .large: return 1.5
        }
    }
}

public enum _OpenTextTruncationMode: UInt8, Hashable, Sendable {
    case head
    case middle
    case tail
}

public struct _OpenContentShapeKinds: OptionSet, Hashable, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let interaction = _OpenContentShapeKinds(rawValue: 1 << 0)
    public static let dragPreview = _OpenContentShapeKinds(rawValue: 1 << 1)
    public static let contextMenuPreview = _OpenContentShapeKinds(rawValue: 1 << 2)
    public static let hoverEffect = _OpenContentShapeKinds(rawValue: 1 << 3)
}

public struct _OpenAccessibilityActionKind: Hashable, Sendable {
    private let rawValue: UInt8
    private init(_ rawValue: UInt8) { self.rawValue = rawValue }

    public static let `default` = _OpenAccessibilityActionKind(0)
    public static let escape = _OpenAccessibilityActionKind(1)
}

public enum _OpenVisibility: UInt8, Hashable, Sendable {
    case automatic
    case visible
    case hidden
}

public struct _OpenToolbarPlacement: Hashable, Sendable {
    private let rawValue: UInt8
    private init(_ rawValue: UInt8) { self.rawValue = rawValue }

    public static let automatic = _OpenToolbarPlacement(0)
    public static let navigationBar = _OpenToolbarPlacement(1)
    public static let bottomBar = _OpenToolbarPlacement(2)
}

public struct _OpenButtonBorderShape: Hashable, Sendable {
    enum Storage: Hashable, Sendable { case automatic, capsule, circle, roundedRectangle(CGFloat) }
    let storage: Storage

    private init(_ storage: Storage) { self.storage = storage }
    public static let automatic = _OpenButtonBorderShape(.automatic)
    public static let capsule = _OpenButtonBorderShape(.capsule)
    public static let circle = _OpenButtonBorderShape(.circle)
    public static func roundedRectangle(radius: CGFloat) -> _OpenButtonBorderShape {
        _OpenButtonBorderShape(.roundedRectangle(radius))
    }
}

public struct _OpenGlass: Hashable, Sendable {
    let isInteractive: Bool

    private init(isInteractive: Bool) { self.isInteractive = isInteractive }
    public static let regular = _OpenGlass(isInteractive: false)

    public func interactive(_ enabled: Bool = true) -> _OpenGlass {
        _OpenGlass(isInteractive: enabled)
    }
}

public struct _OpenGlassEffectTransition: Hashable, Sendable {
    private let rawValue: UInt8
    private init(_ rawValue: UInt8) { self.rawValue = rawValue }
    public static let identity = _OpenGlassEffectTransition(0)
    public static let matchedGeometry = _OpenGlassEffectTransition(1)
}

public enum _OpenAccessibilityChildBehavior: Sendable {
    case ignore
    case contain
    case combine
}

public struct _OpenAccessibilityTraits: OptionSet, Sendable {
    public let rawValue: UInt64

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    public static let isButton = _OpenAccessibilityTraits(rawValue: 1 << 0)
    public static let isLink = _OpenAccessibilityTraits(rawValue: 1 << 1)
    public static let isHeader = _OpenAccessibilityTraits(rawValue: 1 << 2)
    public static let isImage = _OpenAccessibilityTraits(rawValue: 1 << 3)
    public static let isSelected = _OpenAccessibilityTraits(rawValue: 1 << 4)
}

public struct _OpenMatchedGeometryProperties: OptionSet, Sendable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let position = _OpenMatchedGeometryProperties(rawValue: 1 << 0)
    public static let size = _OpenMatchedGeometryProperties(rawValue: 1 << 1)
    public static let frame: _OpenMatchedGeometryProperties = [.position, .size]
}

public struct _OpenContentTransition: Hashable, Sendable {
    enum Storage: Hashable, Sendable { case identity, numericText }
    let storage: Storage

    private init(_ storage: Storage) { self.storage = storage }

    public static let identity = _OpenContentTransition(.identity)
    public static func numericText() -> _OpenContentTransition {
        _OpenContentTransition(.numericText)
    }
}

public struct _OpenAnyTransition: Hashable, Sendable {
    indirect enum Storage: Hashable, Sendable {
        case identity
        case opacity
        case move(_OpenEdge)
        case offset(CGFloat, CGFloat)
        case combined(Storage, Storage)
        case asymmetric(Storage, Storage)
        case modifier
    }

    let storage: Storage

    private init(_ storage: Storage) { self.storage = storage }

    public static let identity = _OpenAnyTransition(.identity)
    public static let opacity = _OpenAnyTransition(.opacity)

    public static func move(edge: _OpenEdge) -> _OpenAnyTransition {
        _OpenAnyTransition(.move(edge))
    }

    public static func offset(x: CGFloat = 0, y: CGFloat = 0) -> _OpenAnyTransition {
        _OpenAnyTransition(.offset(x, y))
    }

    public static func asymmetric(
        insertion: _OpenAnyTransition,
        removal: _OpenAnyTransition
    ) -> _OpenAnyTransition {
        _OpenAnyTransition(.asymmetric(insertion.storage, removal.storage))
    }

    public static func modifier<Active: _OpenViewModifierProtocol, Identity: _OpenViewModifierProtocol>(
        active: Active,
        identity: Identity
    ) -> _OpenAnyTransition {
        _ = active
        _ = identity
        return _OpenAnyTransition(.modifier)
    }

    public func combined(with other: _OpenAnyTransition) -> _OpenAnyTransition {
        _OpenAnyTransition(.combined(storage, other.storage))
    }
}

public enum _OpenPreviewLayout: Sendable {
    case sizeThatFits
}

public protocol _OpenShape {}

public enum _OpenRoundedCornerStyle: Sendable {
    case circular
    case continuous
}

public struct _OpenRoundedRectangle: _OpenShape {
    public let cornerRadius: CGFloat
    public let style: _OpenRoundedCornerStyle

    public init(
        cornerRadius: CGFloat,
        style: _OpenRoundedCornerStyle = .circular
    ) {
        self.cornerRadius = cornerRadius
        self.style = style
    }
}

public struct _OpenRectangle: _OpenShape, Sendable {
    public init() {}
}

public struct _OpenCapsule: _OpenShape, Sendable {
    public let style: _OpenRoundedCornerStyle

    public init(style: _OpenRoundedCornerStyle = .circular) {
        self.style = style
    }
}

public struct _OpenCircle: _OpenShape, Sendable {
    public init() {}
}

public extension _OpenShape where Self == _OpenCapsule {
    static var capsule: _OpenCapsule { _OpenCapsule() }
}

public extension _OpenShape where Self == _OpenCircle {
    static var circle: _OpenCircle { _OpenCircle() }
}

// Source spellings.  The implementation nominals carry an Open prefix to
// avoid colliding with SwiftUICore's `@_originallyDefinedIn(module: "SwiftUI")`
// ABI symbols when this literal module is validated with an Apple SDK.
public typealias Font = _OpenFont
public typealias Color = _OpenColor
public typealias Gradient = _OpenGradient
public typealias HorizontalAlignment = _OpenHorizontalAlignment
public typealias VerticalAlignment = _OpenVerticalAlignment
public typealias Alignment = _OpenAlignment
public typealias Edge = _OpenEdge
public typealias VerticalEdge = _OpenVerticalEdge
public typealias ContentMode = _OpenContentMode
public typealias ButtonRole = _OpenButtonRole
public typealias Axis = _OpenAxis
public typealias SubmitLabel = _OpenSubmitLabel
public typealias ImageScale = _OpenImageScale
public typealias TextTruncationMode = _OpenTextTruncationMode
public typealias ContentShapeKinds = _OpenContentShapeKinds
public typealias AccessibilityActionKind = _OpenAccessibilityActionKind
public typealias Visibility = _OpenVisibility
public typealias ToolbarPlacement = _OpenToolbarPlacement
public typealias ButtonBorderShape = _OpenButtonBorderShape
public typealias Glass = _OpenGlass
public typealias GlassEffectTransition = _OpenGlassEffectTransition
public typealias AccessibilityChildBehavior = _OpenAccessibilityChildBehavior
public typealias AccessibilityTraits = _OpenAccessibilityTraits
public typealias MatchedGeometryProperties = _OpenMatchedGeometryProperties
public typealias ContentTransition = _OpenContentTransition
public typealias AnyTransition = _OpenAnyTransition
public typealias PreviewLayout = _OpenPreviewLayout
public typealias Shape = _OpenShape
public typealias ShapeStyle = _OpenShapeStyle
public typealias RoundedRectangle = _OpenRoundedRectangle
public typealias RoundedCornerStyle = _OpenRoundedCornerStyle
public typealias Rectangle = _OpenRectangle
public typealias Capsule = _OpenCapsule
public typealias Circle = _OpenCircle
