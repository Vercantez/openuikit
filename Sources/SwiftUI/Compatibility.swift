@_exported import DeveloperToolsSupport
import OpenUIKit
import OpenCoreGraphics

/// The source-facing key retained by SwiftUI controls until their strings are
/// resolved in the active bundle/locale. The portable renderer currently uses
/// the deterministic development-language value while preserving the nominal
/// type and interpolation boundary for future localized lookup.
public struct _OpenLocalizedStringKey: Equatable, ExpressibleByStringLiteral,
    ExpressibleByStringInterpolation
{
    public let rawValue: String

    nonisolated public init(_ value: String) {
        rawValue = value
    }

    nonisolated public init(stringLiteral value: String) {
        rawValue = value
    }

    nonisolated public init(stringInterpolation: StringInterpolation) {
        rawValue = stringInterpolation.value
    }

    public struct StringInterpolation: StringInterpolationProtocol {
        var value: String

        nonisolated public init(literalCapacity: Int, interpolationCount: Int) {
            _ = interpolationCount
            value = ""
            value.reserveCapacity(literalCapacity)
        }

        nonisolated public mutating func appendLiteral(_ literal: String) {
            value.append(literal)
        }

        nonisolated public mutating func appendInterpolation(_ string: String) {
            value.append(string)
        }

        nonisolated public mutating func appendInterpolation(_ substring: Substring) {
            value.append(contentsOf: substring)
        }

        nonisolated public mutating func appendInterpolation<T>(_ value: T) {
            self.value.append(String(describing: value))
        }
    }
}

public typealias LocalizedStringKey = _OpenLocalizedStringKey

/// Type erasure retains the concrete view value and defers node construction
/// until it enters the mounted graph, so dynamic properties keep their normal
/// preparation and invalidation semantics.
public struct _OpenAnyView: _OpenView {
    public typealias Body = Never
    private let makeNode: @MainActor () -> _OpenViewNode

    public init<Content: _OpenView>(_ view: Content) {
        makeNode = { view._makeOpenUIKitNode() }
    }

    public init<Content: _OpenView>(erasing view: Content) {
        self.init(view)
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        makeNode()
    }
}

public typealias AnyView = _OpenAnyView

public protocol _OpenVectorArithmetic: AdditiveArithmetic {
    mutating func scale(by rhs: Double)
    var magnitudeSquared: Double { get }
}

public typealias VectorArithmetic = _OpenVectorArithmetic

extension Double: _OpenVectorArithmetic {
    public mutating func scale(by rhs: Double) { self *= rhs }
    public var magnitudeSquared: Double { self * self }
}

extension Float: _OpenVectorArithmetic {
    public mutating func scale(by rhs: Double) { self *= Float(rhs) }
    public var magnitudeSquared: Double { Double(self * self) }
}

extension CGFloat: _OpenVectorArithmetic {
    public mutating func scale(by rhs: Double) { self *= CGFloat(rhs) }
    public var magnitudeSquared: Double { Double(self * self) }
}

public struct _OpenEmptyAnimatableData: _OpenVectorArithmetic, Sendable {
    public init() {}
    public static let zero = _OpenEmptyAnimatableData()
    public static func + (lhs: Self, rhs: Self) -> Self { _ = lhs; _ = rhs; return .zero }
    public static func - (lhs: Self, rhs: Self) -> Self { _ = lhs; _ = rhs; return .zero }
    public mutating func scale(by rhs: Double) { _ = rhs }
    public var magnitudeSquared: Double { 0 }
}

public typealias EmptyAnimatableData = _OpenEmptyAnimatableData

public protocol _OpenAnimatable {
    associatedtype AnimatableData: VectorArithmetic
    var animatableData: AnimatableData { get set }
}

public extension _OpenAnimatable where AnimatableData == EmptyAnimatableData {
    var animatableData: EmptyAnimatableData {
        get { .zero }
        set { _ = newValue }
    }
}

public typealias Animatable = _OpenAnimatable

public struct _OpenProjectionTransform: Equatable, Sendable {
    public var m11: CGFloat = 1
    public var m12: CGFloat = 0
    public var m13: CGFloat = 0
    public var m21: CGFloat = 0
    public var m22: CGFloat = 1
    public var m23: CGFloat = 0
    public var m31: CGFloat = 0
    public var m32: CGFloat = 0
    public var m33: CGFloat = 1

    public init() {}

    public init(_ transform: OpenCoreGraphics.CGAffineTransform) {
        m11 = transform.a
        m12 = transform.b
        m21 = transform.c
        m22 = transform.d
        m31 = transform.tx
        m32 = transform.ty
    }

    public var isIdentity: Bool { self == Self() }
    public var isAffine: Bool { m13 == 0 && m23 == 0 && m33 == 1 }

    public mutating func invert() -> Bool {
        let determinant = m11 * (m22 * m33 - m23 * m32)
            - m12 * (m21 * m33 - m23 * m31)
            + m13 * (m21 * m32 - m22 * m31)
        guard determinant != 0 else { return false }
        let source = self
        m11 = (source.m22 * source.m33 - source.m23 * source.m32) / determinant
        m12 = (source.m13 * source.m32 - source.m12 * source.m33) / determinant
        m13 = (source.m12 * source.m23 - source.m13 * source.m22) / determinant
        m21 = (source.m23 * source.m31 - source.m21 * source.m33) / determinant
        m22 = (source.m11 * source.m33 - source.m13 * source.m31) / determinant
        m23 = (source.m13 * source.m21 - source.m11 * source.m23) / determinant
        m31 = (source.m21 * source.m32 - source.m22 * source.m31) / determinant
        m32 = (source.m12 * source.m31 - source.m11 * source.m32) / determinant
        m33 = (source.m11 * source.m22 - source.m12 * source.m21) / determinant
        return true
    }

    public func inverted() -> Self {
        var result = self
        _ = result.invert()
        return result
    }

    var affineTransform: OpenCoreGraphics.CGAffineTransform? {
        guard isAffine else { return nil }
        return OpenCoreGraphics.CGAffineTransform(
            a: m11, b: m12, c: m21, d: m22, tx: m31, ty: m32
        )
    }
}

public typealias ProjectionTransform = _OpenProjectionTransform

@preconcurrency @MainActor
public protocol _OpenGeometryEffect: Animatable, ViewModifier where Body == Never {
    nonisolated func effectValue(size: CGSize) -> ProjectionTransform
    static var _affectsLayout: Bool { get }
}

public extension _OpenGeometryEffect {
    static var _affectsLayout: Bool { false }

    func body(content: Content) -> Never {
        _ = content
        fatalError("GeometryEffect is rendered through effectValue(size:)")
    }
}

public typealias GeometryEffect = _OpenGeometryEffect

@preconcurrency @MainActor
public protocol _OpenAnimatableModifier: Animatable, ViewModifier {}

public typealias AnimatableModifier = _OpenAnimatableModifier

@attached(accessor)
@attached(peer, names: prefixed(__Key_))
public macro Entry() = #externalMacro(
    module: "OpenSwiftUIMacros",
    type: "EntryMacro"
)

public extension _OpenText {
    nonisolated init(_ key: LocalizedStringKey) {
        self.init(verbatim: key.rawValue)
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
public extension _OpenImage {
    nonisolated init(_ resource: ImageResource) {
        self.init(resource.name, bundle: resource.bundle)
    }
}

public extension _OpenLabel where Title == _OpenText, Icon == _OpenImage {
    nonisolated init(_ titleKey: LocalizedStringKey, image name: String) {
        title = _OpenText(titleKey)
        icon = _OpenImage(name)
    }

    nonisolated init<S: StringProtocol>(_ title: S, image name: String) {
        self.init(LocalizedStringKey(String(title)), image: name)
    }

    nonisolated init(_ titleKey: LocalizedStringKey, systemImage: String) {
        title = _OpenText(titleKey)
        icon = _OpenImage(systemName: systemImage)
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    nonisolated init(_ titleKey: LocalizedStringKey, image resource: ImageResource) {
        title = _OpenText(titleKey)
        icon = _OpenImage(resource)
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    nonisolated init<S: StringProtocol>(_ title: S, image resource: ImageResource) {
        self.init(LocalizedStringKey(String(title)), image: resource)
    }
}
