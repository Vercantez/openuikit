#if canImport(Foundation)
import Foundation
#endif
import OpenUIKit

public struct _OpenFont: Equatable, Sendable {
    public enum TextStyle: Equatable, Sendable {
        case headline
        case body
        case title3
    }

    public struct Weight: Equatable, Sendable {
        let value: UIFont.Weight

        init(_ value: UIFont.Weight) {
            self.value = value
        }

        public static let regular = Weight(.regular)
        public static let medium = Weight(.medium)
        public static let semibold = Weight(.semibold)
        public static let bold = Weight(.bold)
    }

    enum Storage: Equatable, Sendable {
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

    public static let headline = _OpenFont(.headline)
    public static let body = _OpenFont(.body)
    public static let title3 = _OpenFont(.title3)

    public static func system(size: CGFloat) -> _OpenFont {
        _OpenFont(
            storage: .uiFont(pointSize: size, weight: .regular, design: .default)
        )
    }

    public func bold() -> _OpenFont {
        switch storage {
        case .textStyle(let style):
            let pointSize: CGFloat
            switch style {
            case .headline, .body: pointSize = 17
            case .title3: pointSize = 20
            }
            return _OpenFont(
                storage: .uiFont(pointSize: pointSize, weight: .bold, design: .default)
            )
        case .uiFont(let pointSize, _, let design):
            return _OpenFont(
                storage: .uiFont(pointSize: pointSize, weight: .bold, design: design)
            )
        }
    }

    private init(storage: Storage) {
        self.storage = storage
    }

    func resolve(weight override: Weight?) -> UIFont {
        switch storage {
        case .textStyle(let style):
            let size: CGFloat = style == .title3 ? 20 : 17
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

public struct _OpenColor {
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

    public func opacity(_ opacity: CGFloat) -> _OpenColor {
        _OpenColor(storage: .opacity(storage, min(max(opacity, 0), 1)))
    }

    private init(storage: Storage) {
        self.storage = storage
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

public struct _OpenGradient {
    public let colors: [_OpenColor]

    public init(colors: [_OpenColor]) {
        self.colors = colors
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
    public static let center = _OpenUnitPoint(x: 0.5, y: 0.5)
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
}

public enum _OpenEdge: Int, Sendable {
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

public enum _OpenContentMode: Sendable {
    case fit
    case fill
}

public enum _OpenPreviewLayout: Sendable {
    case sizeThatFits
}

public protocol _OpenShape {}

public struct _OpenRoundedRectangle: _OpenShape {
    public let cornerRadius: CGFloat

    public init(cornerRadius: CGFloat) {
        self.cornerRadius = cornerRadius
    }
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
public typealias ContentMode = _OpenContentMode
public typealias PreviewLayout = _OpenPreviewLayout
public typealias Shape = _OpenShape
public typealias RoundedRectangle = _OpenRoundedRectangle
