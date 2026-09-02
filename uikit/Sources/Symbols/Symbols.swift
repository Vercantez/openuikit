// Portable value model for Apple's Symbols framework.
//
// Symbols effects are immutable descriptions. Rendering belongs to SwiftUI;
// this module preserves effect identity, direction, layer scope, options, and
// the same protocol families used for compile-time overload selection.

public protocol SymbolEffect: Hashable, Sendable {
    var configuration: SymbolEffectConfiguration { get }
}

public struct SymbolEffectConfiguration: Hashable, Sendable {
    @usableFromInline let kind: UInt8
    @usableFromInline let primary: Int16
    @usableFromInline let secondary: Int16
    @usableFromInline let scalar: Double

    @usableFromInline
    init(kind: UInt8, primary: Int16 = -1, secondary: Int16 = -1, scalar: Double = 0) {
        self.kind = kind
        self.primary = primary
        self.secondary = secondary
        self.scalar = scalar
    }
}

@_marker public protocol TransitionSymbolEffect {}
@_marker public protocol ContentTransitionSymbolEffect {}
@_marker public protocol IndefiniteSymbolEffect {}
@_marker public protocol DiscreteSymbolEffect {}

@inline(__always)
private func _flag(_ value: Bool?) -> Int16 {
    guard let value else { return -1 }
    return value ? 1 : 0
}

public struct PulseSymbolEffect: SymbolEffect {
    @usableFromInline var isLayered: Bool?
    @usableFromInline init(isLayered: Bool? = nil) { self.isLayered = isLayered }

    public var byLayer: Self { Self(isLayered: true) }
    public var wholeSymbol: Self { Self(isLayered: false) }
    public var configuration: SymbolEffectConfiguration {
        .init(kind: 1, primary: _flag(isLayered))
    }
}

public extension SymbolEffect where Self == PulseSymbolEffect {
    @_alwaysEmitIntoClient static var pulse: PulseSymbolEffect { PulseSymbolEffect() }
}

public struct BounceSymbolEffect: SymbolEffect {
    @usableFromInline var isUp: Bool?
    @usableFromInline var isLayered: Bool?
    @usableFromInline
    init(isUp: Bool? = nil, isLayered: Bool? = nil) {
        self.isUp = isUp
        self.isLayered = isLayered
    }

    public var up: Self { Self(isUp: true, isLayered: isLayered) }
    public var down: Self { Self(isUp: false, isLayered: isLayered) }
    public var byLayer: Self { Self(isUp: isUp, isLayered: true) }
    public var wholeSymbol: Self { Self(isUp: isUp, isLayered: false) }
    public var configuration: SymbolEffectConfiguration {
        .init(kind: 2, primary: _flag(isUp), secondary: _flag(isLayered))
    }
}

public extension SymbolEffect where Self == BounceSymbolEffect {
    @_alwaysEmitIntoClient static var bounce: BounceSymbolEffect { BounceSymbolEffect() }
}

public struct VariableColorSymbolEffect: SymbolEffect {
    @usableFromInline var isReversing: Bool?
    @usableFromInline var isIterative: Bool?
    @usableFromInline var hidesInactiveLayers: Bool?
    @usableFromInline
    init(
        isReversing: Bool? = nil,
        isIterative: Bool? = nil,
        hidesInactiveLayers: Bool? = nil
    ) {
        self.isReversing = isReversing
        self.isIterative = isIterative
        self.hidesInactiveLayers = hidesInactiveLayers
    }

    public var reversing: Self {
        Self(isReversing: true, isIterative: isIterative, hidesInactiveLayers: hidesInactiveLayers)
    }
    public var nonReversing: Self {
        Self(isReversing: false, isIterative: isIterative, hidesInactiveLayers: hidesInactiveLayers)
    }
    public var cumulative: Self {
        Self(isReversing: isReversing, isIterative: false, hidesInactiveLayers: hidesInactiveLayers)
    }
    public var iterative: Self {
        Self(isReversing: isReversing, isIterative: true, hidesInactiveLayers: hidesInactiveLayers)
    }
    public var hideInactiveLayers: Self {
        Self(isReversing: isReversing, isIterative: isIterative, hidesInactiveLayers: true)
    }
    public var dimInactiveLayers: Self {
        Self(isReversing: isReversing, isIterative: isIterative, hidesInactiveLayers: false)
    }
    public var configuration: SymbolEffectConfiguration {
        .init(
            kind: 3,
            primary: _flag(isReversing),
            secondary: _flag(isIterative),
            scalar: Double(_flag(hidesInactiveLayers))
        )
    }
}

public extension SymbolEffect where Self == VariableColorSymbolEffect {
    @_alwaysEmitIntoClient static var variableColor: VariableColorSymbolEffect {
        VariableColorSymbolEffect()
    }
}

public struct ScaleSymbolEffect: SymbolEffect {
    @usableFromInline var isUp: Bool?
    @usableFromInline var isLayered: Bool?
    @usableFromInline
    init(isUp: Bool? = nil, isLayered: Bool? = nil) {
        self.isUp = isUp
        self.isLayered = isLayered
    }

    public var up: Self { Self(isUp: true, isLayered: isLayered) }
    public var down: Self { Self(isUp: false, isLayered: isLayered) }
    public var byLayer: Self { Self(isUp: isUp, isLayered: true) }
    public var wholeSymbol: Self { Self(isUp: isUp, isLayered: false) }
    public var configuration: SymbolEffectConfiguration {
        .init(kind: 4, primary: _flag(isUp), secondary: _flag(isLayered))
    }
}

public extension SymbolEffect where Self == ScaleSymbolEffect {
    @_alwaysEmitIntoClient static var scale: ScaleSymbolEffect { ScaleSymbolEffect() }
}

public struct AppearSymbolEffect: SymbolEffect {
    @usableFromInline var isUp: Bool?
    @usableFromInline var isLayered: Bool?
    @usableFromInline
    init(isUp: Bool? = nil, isLayered: Bool? = nil) {
        self.isUp = isUp
        self.isLayered = isLayered
    }

    public var up: Self { Self(isUp: true, isLayered: isLayered) }
    public var down: Self { Self(isUp: false, isLayered: isLayered) }
    public var byLayer: Self { Self(isUp: isUp, isLayered: true) }
    public var wholeSymbol: Self { Self(isUp: isUp, isLayered: false) }
    public var configuration: SymbolEffectConfiguration {
        .init(kind: 5, primary: _flag(isUp), secondary: _flag(isLayered))
    }
}

public extension SymbolEffect where Self == AppearSymbolEffect {
    @_alwaysEmitIntoClient static var appear: AppearSymbolEffect { AppearSymbolEffect() }
}

public struct DisappearSymbolEffect: SymbolEffect {
    @usableFromInline var isUp: Bool?
    @usableFromInline var isLayered: Bool?
    @usableFromInline
    init(isUp: Bool? = nil, isLayered: Bool? = nil) {
        self.isUp = isUp
        self.isLayered = isLayered
    }

    public var up: Self { Self(isUp: true, isLayered: isLayered) }
    public var down: Self { Self(isUp: false, isLayered: isLayered) }
    public var byLayer: Self { Self(isUp: isUp, isLayered: true) }
    public var wholeSymbol: Self { Self(isUp: isUp, isLayered: false) }
    public var configuration: SymbolEffectConfiguration {
        .init(kind: 6, primary: _flag(isUp), secondary: _flag(isLayered))
    }
}

public extension SymbolEffect where Self == DisappearSymbolEffect {
    @_alwaysEmitIntoClient static var disappear: DisappearSymbolEffect {
        DisappearSymbolEffect()
    }
}

public struct ReplaceSymbolEffect: SymbolEffect {
    @usableFromInline var direction: Int16
    @usableFromInline var isLayered: Bool?
    @usableFromInline
    init(direction: Int16 = -1, isLayered: Bool? = nil) {
        self.direction = direction
        self.isLayered = isLayered
    }

    public var downUp: Self { Self(direction: 0, isLayered: isLayered) }
    public var upUp: Self { Self(direction: 1, isLayered: isLayered) }
    public var offUp: Self { Self(direction: 2, isLayered: isLayered) }
    public var byLayer: Self { Self(direction: direction, isLayered: true) }
    public var wholeSymbol: Self { Self(direction: direction, isLayered: false) }
    public var configuration: SymbolEffectConfiguration {
        .init(kind: 7, primary: direction, secondary: _flag(isLayered))
    }

    public struct MagicReplace: SymbolEffect {
        @usableFromInline let fallback: ReplaceSymbolEffect
        public var configuration: SymbolEffectConfiguration {
            .init(
                kind: 8,
                primary: fallback.direction,
                secondary: _flag(fallback.isLayered)
            )
        }
    }

    public func magic(fallback: ReplaceSymbolEffect) -> MagicReplace {
        MagicReplace(fallback: fallback)
    }
}

public extension SymbolEffect where Self == ReplaceSymbolEffect {
    @_alwaysEmitIntoClient static var replace: ReplaceSymbolEffect { ReplaceSymbolEffect() }
}

public extension ReplaceSymbolEffect {
    static var downUp: Self { Self().downUp }
    static var upUp: Self { Self().upUp }
    static var offUp: Self { Self().offUp }
}

public struct AutomaticSymbolEffect: SymbolEffect {
    @usableFromInline init() {}
    public var configuration: SymbolEffectConfiguration { .init(kind: 9) }
}

public extension SymbolEffect where Self == AutomaticSymbolEffect {
    @_alwaysEmitIntoClient static var automatic: AutomaticSymbolEffect {
        AutomaticSymbolEffect()
    }
}

private enum _WiggleStyle: Hashable, Sendable {
    case clockwise, counterClockwise, left, right, up, down, forward, backward
    case custom(Double)
}

public struct WiggleSymbolEffect: SymbolEffect {
    private var style: _WiggleStyle?
    @usableFromInline var isLayered: Bool?
    @usableFromInline init(isLayered: Bool? = nil) {
        style = nil
        self.isLayered = isLayered
    }
    private init(style: _WiggleStyle?, isLayered: Bool?) {
        self.style = style
        self.isLayered = isLayered
    }

    public var clockwise: Self { Self(style: .clockwise, isLayered: isLayered) }
    public var counterClockwise: Self { Self(style: .counterClockwise, isLayered: isLayered) }
    public var left: Self { Self(style: .left, isLayered: isLayered) }
    public var right: Self { Self(style: .right, isLayered: isLayered) }
    public var up: Self { Self(style: .up, isLayered: isLayered) }
    public var down: Self { Self(style: .down, isLayered: isLayered) }
    public var forward: Self { Self(style: .forward, isLayered: isLayered) }
    public var backward: Self { Self(style: .backward, isLayered: isLayered) }
    public func custom(angle: Double) -> Self {
        Self(style: .custom(angle), isLayered: isLayered)
    }
    public var byLayer: Self { Self(style: style, isLayered: true) }
    public var wholeSymbol: Self { Self(style: style, isLayered: false) }
    public var configuration: SymbolEffectConfiguration {
        let code: Int16
        let scalar: Double
        switch style {
        case nil: (code, scalar) = (-1, 0)
        case .clockwise: (code, scalar) = (0, 0)
        case .counterClockwise: (code, scalar) = (1, 0)
        case .left: (code, scalar) = (2, 0)
        case .right: (code, scalar) = (3, 0)
        case .up: (code, scalar) = (4, 0)
        case .down: (code, scalar) = (5, 0)
        case .forward: (code, scalar) = (6, 0)
        case .backward: (code, scalar) = (7, 0)
        case .custom(let angle): (code, scalar) = (8, angle)
        }
        return .init(kind: 10, primary: code, secondary: _flag(isLayered), scalar: scalar)
    }
}

public extension SymbolEffect where Self == WiggleSymbolEffect {
    @_alwaysEmitIntoClient static var wiggle: WiggleSymbolEffect { WiggleSymbolEffect() }
}

public struct RotateSymbolEffect: SymbolEffect {
    @usableFromInline var isClockwise: Bool?
    @usableFromInline var isLayered: Bool?
    @usableFromInline
    init(isClockwise: Bool? = nil, isLayered: Bool? = nil) {
        self.isClockwise = isClockwise
        self.isLayered = isLayered
    }

    public var clockwise: Self { Self(isClockwise: true, isLayered: isLayered) }
    public var counterClockwise: Self { Self(isClockwise: false, isLayered: isLayered) }
    public var byLayer: Self { Self(isClockwise: isClockwise, isLayered: true) }
    public var wholeSymbol: Self { Self(isClockwise: isClockwise, isLayered: false) }
    public var configuration: SymbolEffectConfiguration {
        .init(kind: 11, primary: _flag(isClockwise), secondary: _flag(isLayered))
    }
}

public extension SymbolEffect where Self == RotateSymbolEffect {
    @_alwaysEmitIntoClient static var rotate: RotateSymbolEffect { RotateSymbolEffect() }
}

private enum _BreatheStyle: Int16, Hashable, Sendable { case pulse, plain }

public struct BreatheSymbolEffect: SymbolEffect {
    private var style: _BreatheStyle?
    @usableFromInline var isLayered: Bool?
    @usableFromInline init(isLayered: Bool? = nil) {
        style = nil
        self.isLayered = isLayered
    }
    private init(style: _BreatheStyle?, isLayered: Bool?) {
        self.style = style
        self.isLayered = isLayered
    }

    public var pulse: Self { Self(style: .pulse, isLayered: isLayered) }
    public var plain: Self { Self(style: .plain, isLayered: isLayered) }
    public var byLayer: Self { Self(style: style, isLayered: true) }
    public var wholeSymbol: Self { Self(style: style, isLayered: false) }
    public var configuration: SymbolEffectConfiguration {
        .init(kind: 12, primary: style?.rawValue ?? -1, secondary: _flag(isLayered))
    }
}

public extension SymbolEffect where Self == BreatheSymbolEffect {
    @_alwaysEmitIntoClient static var breathe: BreatheSymbolEffect { BreatheSymbolEffect() }
}

public struct DrawOnSymbolEffect: SymbolEffect {
    @usableFromInline var isLayered: Bool?
    @usableFromInline var isIndividual: Bool?
    @usableFromInline
    init(isLayered: Bool? = nil, isIndividual: Bool? = nil) {
        self.isLayered = isLayered
        self.isIndividual = isIndividual
    }

    public var byLayer: Self { Self(isLayered: true, isIndividual: isIndividual) }
    public var wholeSymbol: Self { Self(isLayered: false, isIndividual: isIndividual) }
    public var individually: Self { Self(isLayered: isLayered, isIndividual: true) }
    public var configuration: SymbolEffectConfiguration {
        .init(kind: 13, primary: _flag(isLayered), secondary: _flag(isIndividual))
    }
}

public extension SymbolEffect where Self == DrawOnSymbolEffect {
    @_alwaysEmitIntoClient static var drawOn: DrawOnSymbolEffect { DrawOnSymbolEffect() }
}

public struct DrawOffSymbolEffect: SymbolEffect {
    @usableFromInline var isLayered: Bool?
    @usableFromInline var isIndividual: Bool?
    @usableFromInline var isReversed: Bool?
    @usableFromInline
    init(
        isLayered: Bool? = nil,
        isIndividual: Bool? = nil,
        isReversed: Bool? = nil
    ) {
        self.isLayered = isLayered
        self.isIndividual = isIndividual
        self.isReversed = isReversed
    }

    public var byLayer: Self {
        Self(isLayered: true, isIndividual: isIndividual, isReversed: isReversed)
    }
    public var wholeSymbol: Self {
        Self(isLayered: false, isIndividual: isIndividual, isReversed: isReversed)
    }
    public var individually: Self {
        Self(isLayered: isLayered, isIndividual: true, isReversed: isReversed)
    }
    public var reversed: Self {
        Self(isLayered: isLayered, isIndividual: isIndividual, isReversed: true)
    }
    public var nonReversed: Self {
        Self(isLayered: isLayered, isIndividual: isIndividual, isReversed: false)
    }
    public var configuration: SymbolEffectConfiguration {
        .init(
            kind: 14,
            primary: _flag(isLayered),
            secondary: _flag(isIndividual),
            scalar: Double(_flag(isReversed))
        )
    }
}

public extension SymbolEffect where Self == DrawOffSymbolEffect {
    @_alwaysEmitIntoClient static var drawOff: DrawOffSymbolEffect { DrawOffSymbolEffect() }
}

extension AppearSymbolEffect: TransitionSymbolEffect, IndefiniteSymbolEffect {}
extension DisappearSymbolEffect: TransitionSymbolEffect, IndefiniteSymbolEffect {}
extension AutomaticSymbolEffect: TransitionSymbolEffect, ContentTransitionSymbolEffect {}
extension ReplaceSymbolEffect: ContentTransitionSymbolEffect {}
extension ReplaceSymbolEffect.MagicReplace: ContentTransitionSymbolEffect {}
extension PulseSymbolEffect: IndefiniteSymbolEffect, DiscreteSymbolEffect {}
extension VariableColorSymbolEffect: IndefiniteSymbolEffect, DiscreteSymbolEffect {}
extension ScaleSymbolEffect: IndefiniteSymbolEffect {}
extension WiggleSymbolEffect: IndefiniteSymbolEffect, DiscreteSymbolEffect {}
extension RotateSymbolEffect: IndefiniteSymbolEffect, DiscreteSymbolEffect {}
extension BreatheSymbolEffect: IndefiniteSymbolEffect, DiscreteSymbolEffect {}
extension BounceSymbolEffect: IndefiniteSymbolEffect, DiscreteSymbolEffect {}
extension DrawOnSymbolEffect: TransitionSymbolEffect, IndefiniteSymbolEffect {}
extension DrawOffSymbolEffect: TransitionSymbolEffect, IndefiniteSymbolEffect {}

public struct SymbolEffectOptions: Hashable, Sendable {
    fileprivate enum Repetition: Hashable, Sendable {
        case unspecified
        case periodic(count: Int?, delay: Double?)
        case continuous
        case nonRepeating
    }

    private var speedValue: Double
    private var repetition: Repetition

    private init(speed: Double = 1, repetition: Repetition = .unspecified) {
        speedValue = speed
        self.repetition = repetition
    }

    public static var `default`: Self { Self() }
    public static func speed(_ speed: Double) -> Self { Self(speed: speed) }
    public func speed(_ speed: Double) -> Self {
        Self(speed: speed, repetition: repetition)
    }
    public static func `repeat`(_ count: Int?) -> Self {
        Self(repetition: .periodic(count: count, delay: nil))
    }
    public func `repeat`(_ count: Int?) -> Self {
        Self(speed: speedValue, repetition: .periodic(count: count, delay: nil))
    }
    public static var repeating: Self { Self(repetition: .periodic(count: nil, delay: nil)) }
    public var repeating: Self {
        Self(speed: speedValue, repetition: .periodic(count: nil, delay: nil))
    }
    public static var nonRepeating: Self { Self(repetition: .nonRepeating) }
    public var nonRepeating: Self { Self(speed: speedValue, repetition: .nonRepeating) }

    public struct RepeatBehavior: Hashable, Sendable {
        fileprivate let repetition: Repetition
        fileprivate init(_ repetition: Repetition) { self.repetition = repetition }

        public static var periodic: Self { Self(.periodic(count: nil, delay: nil)) }
        public static func periodic(_ count: Int? = nil, delay: Double? = nil) -> Self {
            Self(.periodic(count: count, delay: delay))
        }
        public static var continuous: Self { Self(.continuous) }
    }

    public func `repeat`(_ behavior: RepeatBehavior) -> Self {
        Self(speed: speedValue, repetition: behavior.repetition)
    }
    public static func `repeat`(_ behavior: RepeatBehavior) -> Self {
        Self(repetition: behavior.repetition)
    }
}
