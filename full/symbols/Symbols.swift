@_exported import Foundation

/// A value-semantic SF Symbol animation effect.
///
/// Linux implements the public configuration surface. Applying an effect to a
/// rendered symbol is a SwiftUI / UIKit concern and is not performed here.
public protocol SymbolEffect: Hashable, Sendable {
    var configuration: SymbolEffectConfiguration { get }
}

/// Marker for effects that can run as a discrete (value-triggered) animation.
public protocol DiscreteSymbolEffect {}

/// Marker for effects that can run as an indefinite animation.
public protocol IndefiniteSymbolEffect {}

/// Marker for appear / disappear / draw / automatic transition effects.
public protocol TransitionSymbolEffect {}

/// Marker for content-replacement transitions.
public protocol ContentTransitionSymbolEffect {}

/// Opaque, hashable snapshot of a `SymbolEffect`'s public modifiers.
///
/// There is no public memberwise initializer: clients obtain a configuration
/// from an effect. Equality is the documented way to observe modifier state.
public struct SymbolEffectConfiguration: Hashable, Sendable {
    enum Kind: String, Hashable, Sendable {
        case pulse
        case bounce
        case variableColor
        case scale
        case appear
        case disappear
        case replace
        case magicReplace
        case automatic
        case wiggle
        case rotate
        case breathe
        case drawOn
        case drawOff
    }

    enum Layering: String, Hashable, Sendable {
        case unspecified
        case byLayer
        case wholeSymbol
        case individually
    }

    enum VerticalDirection: String, Hashable, Sendable {
        case unspecified
        case up
        case down
    }

    enum RotationDirection: String, Hashable, Sendable {
        case unspecified
        case clockwise
        case counterClockwise
    }

    enum VariableColorFill: String, Hashable, Sendable {
        case unspecified
        case iterative
        case cumulative
    }

    enum VariableColorReverse: String, Hashable, Sendable {
        case unspecified
        case reversing
        case nonReversing
    }

    enum VariableColorInactive: String, Hashable, Sendable {
        case unspecified
        case hideInactiveLayers
        case dimInactiveLayers
    }

    enum BreatheStyle: String, Hashable, Sendable {
        case unspecified
        case plain
        case pulse
    }

    enum ReplaceStyle: String, Hashable, Sendable {
        case unspecified
        case downUp
        case upUp
        case offUp
    }

    enum DrawOffReverse: String, Hashable, Sendable {
        case unspecified
        case reversed
        case nonReversed
    }

    enum WiggleMotion: Hashable, Sendable {
        case unspecified
        case up
        case down
        case left
        case right
        case forward
        case backward
        case clockwise
        case counterClockwise
        case custom(Double)
    }

    struct Snapshot: Hashable, Sendable {
        var kind: Kind
        var layering: Layering
        var vertical: VerticalDirection
        var rotation: RotationDirection
        var variableFill: VariableColorFill
        var variableReverse: VariableColorReverse
        var variableInactive: VariableColorInactive
        var breathe: BreatheStyle
        var replace: ReplaceStyle
        var drawOffReverse: DrawOffReverse
        var wiggle: WiggleMotion
        var magicFallbackReplace: ReplaceStyle
        var magicFallbackLayering: Layering
        var hasMagicFallback: Bool
    }

    var snapshot: Snapshot

    init(kind: Kind) {
        snapshot = Snapshot(
            kind: kind,
            layering: .unspecified,
            vertical: .unspecified,
            rotation: .unspecified,
            variableFill: .unspecified,
            variableReverse: .unspecified,
            variableInactive: .unspecified,
            breathe: .unspecified,
            replace: .unspecified,
            drawOffReverse: .unspecified,
            wiggle: .unspecified,
            magicFallbackReplace: .unspecified,
            magicFallbackLayering: .unspecified,
            hasMagicFallback: false
        )
    }

    func replacing(_ mutate: (inout Snapshot) -> Void) -> SymbolEffectConfiguration {
        var next = self
        mutate(&next.snapshot)
        return next
    }

    public static func == (
        a: SymbolEffectConfiguration,
        b: SymbolEffectConfiguration
    ) -> Bool {
        a.snapshot == b.snapshot
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(snapshot)
    }
}

/// Playback options for a symbol effect (repeat policy and speed).
///
/// These values configure animation playback. Linux does not drive a renderer;
/// the options remain pure data so SwiftUI/UIKit hosts can consume them later.
public struct SymbolEffectOptions: Hashable, Sendable {
    enum RepeatMode: Hashable, Sendable {
        case unspecified
        case repeating
        case nonRepeating
        case count(Int?)
        case behavior(RepeatBehavior.Storage)
    }

    var repeatMode: RepeatMode
    var speed: Double?

    init(repeatMode: RepeatMode = .unspecified, speed: Double? = nil) {
        self.repeatMode = repeatMode
        self.speed = speed
    }

    public static var `default`: SymbolEffectOptions {
        SymbolEffectOptions()
    }

    public static var repeating: SymbolEffectOptions {
        SymbolEffectOptions(repeatMode: .repeating)
    }

    public var repeating: SymbolEffectOptions {
        SymbolEffectOptions(repeatMode: .repeating, speed: speed)
    }

    public static var nonRepeating: SymbolEffectOptions {
        SymbolEffectOptions(repeatMode: .nonRepeating)
    }

    public var nonRepeating: SymbolEffectOptions {
        SymbolEffectOptions(repeatMode: .nonRepeating, speed: speed)
    }

    public static func speed(_ speed: Double) -> SymbolEffectOptions {
        SymbolEffectOptions(speed: speed)
    }

    public func speed(_ speed: Double) -> SymbolEffectOptions {
        SymbolEffectOptions(repeatMode: repeatMode, speed: speed)
    }

    public static func `repeat`(_ count: Int?) -> SymbolEffectOptions {
        SymbolEffectOptions(repeatMode: .count(count))
    }

    public func `repeat`(_ count: Int?) -> SymbolEffectOptions {
        SymbolEffectOptions(repeatMode: .count(count), speed: speed)
    }

    public static func `repeat`(
        _ behavior: SymbolEffectOptions.RepeatBehavior
    ) -> SymbolEffectOptions {
        SymbolEffectOptions(repeatMode: .behavior(behavior.storage))
    }

    public func `repeat`(
        _ behavior: SymbolEffectOptions.RepeatBehavior
    ) -> SymbolEffectOptions {
        SymbolEffectOptions(repeatMode: .behavior(behavior.storage), speed: speed)
    }

    public static func == (a: SymbolEffectOptions, b: SymbolEffectOptions) -> Bool {
        a.repeatMode == b.repeatMode && a.speed == b.speed
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(repeatMode)
        hasher.combine(speed)
    }

    /// Repeat policy for a symbol effect. Not independently `Equatable` in the
    /// sealed public census; compare by applying the behavior to options.
    public struct RepeatBehavior: Sendable {
        enum Storage: Hashable, Sendable {
            case continuous
            case periodic(count: Int?, delay: Double?)
        }

        var storage: Storage

        public static var continuous: RepeatBehavior {
            RepeatBehavior(storage: .continuous)
        }

        public static var periodic: RepeatBehavior {
            RepeatBehavior(storage: .periodic(count: nil, delay: nil))
        }

        public static func periodic(
            _ count: Int? = nil,
            delay: Double? = nil
        ) -> RepeatBehavior {
            RepeatBehavior(storage: .periodic(count: count, delay: delay))
        }
    }
}
