#if canImport(Foundation)
import Foundation
#endif
import OpenUIKit

public struct _OpenFont: Equatable, Sendable {
    public enum TextStyle: Equatable, Sendable {
        case headline
        case body
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

    let style: TextStyle

    private init(_ style: TextStyle) {
        self.style = style
    }

    public static let headline = _OpenFont(.headline)
    public static let body = _OpenFont(.body)
}

public struct _OpenColor {
    enum Storage {
        case resolved(UIColor)
        case named(String, Bundle?)
    }

    let storage: Storage

    public init(_ name: String, bundle: Bundle? = nil) {
        storage = .named(name, bundle)
    }

    public init(uiColor: UIColor) {
        storage = .resolved(uiColor)
    }

    public static let clear = _OpenColor(uiColor: .clear)
    public static let black = _OpenColor(uiColor: .black)
    public static let white = _OpenColor(uiColor: .white)
    public static let red = _OpenColor(uiColor: .red)
    public static let green = _OpenColor(uiColor: .green)
    public static let blue = _OpenColor(uiColor: .blue)

    @MainActor
    func resolve() -> UIColor {
        switch storage {
        case .resolved(let color):
            return color
        case .named(let name, let bundle):
            return UIColor(named: name, in: bundle, compatibleWith: nil) ?? .clear
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
