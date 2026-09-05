/// Concrete `SymbolEffect` value types.
///
/// Each modifier returns a new value with that axis updated (last write wins
/// on the same axis). Unmodified fields stay `.unspecified` rather than
/// inventing Apple defaults that the sealed inputs do not record.

public struct PulseSymbolEffect: SymbolEffect, IndefiniteSymbolEffect, DiscreteSymbolEffect {
    public var configuration: SymbolEffectConfiguration

    init(configuration: SymbolEffectConfiguration) {
        self.configuration = configuration
    }

    public var byLayer: PulseSymbolEffect {
        PulseSymbolEffect(configuration: configuration.replacing { $0.layering = .byLayer })
    }

    public var wholeSymbol: PulseSymbolEffect {
        PulseSymbolEffect(configuration: configuration.replacing { $0.layering = .wholeSymbol })
    }

    public static func == (a: PulseSymbolEffect, b: PulseSymbolEffect) -> Bool {
        a.configuration == b.configuration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(configuration)
    }
}

extension SymbolEffect where Self == PulseSymbolEffect {
    public static var pulse: PulseSymbolEffect {
        PulseSymbolEffect(configuration: SymbolEffectConfiguration(kind: .pulse))
    }
}

public struct BounceSymbolEffect: SymbolEffect, IndefiniteSymbolEffect, DiscreteSymbolEffect {
    public var configuration: SymbolEffectConfiguration

    init(configuration: SymbolEffectConfiguration) {
        self.configuration = configuration
    }

    public var up: BounceSymbolEffect {
        BounceSymbolEffect(configuration: configuration.replacing { $0.vertical = .up })
    }

    public var down: BounceSymbolEffect {
        BounceSymbolEffect(configuration: configuration.replacing { $0.vertical = .down })
    }

    public var byLayer: BounceSymbolEffect {
        BounceSymbolEffect(configuration: configuration.replacing { $0.layering = .byLayer })
    }

    public var wholeSymbol: BounceSymbolEffect {
        BounceSymbolEffect(configuration: configuration.replacing { $0.layering = .wholeSymbol })
    }

    public static func == (a: BounceSymbolEffect, b: BounceSymbolEffect) -> Bool {
        a.configuration == b.configuration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(configuration)
    }
}

extension SymbolEffect where Self == BounceSymbolEffect {
    public static var bounce: BounceSymbolEffect {
        BounceSymbolEffect(configuration: SymbolEffectConfiguration(kind: .bounce))
    }
}

public struct VariableColorSymbolEffect: SymbolEffect, IndefiniteSymbolEffect, DiscreteSymbolEffect {
    public var configuration: SymbolEffectConfiguration

    init(configuration: SymbolEffectConfiguration) {
        self.configuration = configuration
    }

    public var iterative: VariableColorSymbolEffect {
        VariableColorSymbolEffect(configuration: configuration.replacing { $0.variableFill = .iterative })
    }

    public var cumulative: VariableColorSymbolEffect {
        VariableColorSymbolEffect(configuration: configuration.replacing { $0.variableFill = .cumulative })
    }

    public var reversing: VariableColorSymbolEffect {
        VariableColorSymbolEffect(configuration: configuration.replacing { $0.variableReverse = .reversing })
    }

    public var nonReversing: VariableColorSymbolEffect {
        VariableColorSymbolEffect(configuration: configuration.replacing { $0.variableReverse = .nonReversing })
    }

    public var hideInactiveLayers: VariableColorSymbolEffect {
        VariableColorSymbolEffect(
            configuration: configuration.replacing { $0.variableInactive = .hideInactiveLayers }
        )
    }

    public var dimInactiveLayers: VariableColorSymbolEffect {
        VariableColorSymbolEffect(
            configuration: configuration.replacing { $0.variableInactive = .dimInactiveLayers }
        )
    }

    public static func == (
        a: VariableColorSymbolEffect,
        b: VariableColorSymbolEffect
    ) -> Bool {
        a.configuration == b.configuration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(configuration)
    }
}

extension SymbolEffect where Self == VariableColorSymbolEffect {
    public static var variableColor: VariableColorSymbolEffect {
        VariableColorSymbolEffect(configuration: SymbolEffectConfiguration(kind: .variableColor))
    }
}

public struct ScaleSymbolEffect: SymbolEffect, IndefiniteSymbolEffect {
    public var configuration: SymbolEffectConfiguration

    init(configuration: SymbolEffectConfiguration) {
        self.configuration = configuration
    }

    public var up: ScaleSymbolEffect {
        ScaleSymbolEffect(configuration: configuration.replacing { $0.vertical = .up })
    }

    public var down: ScaleSymbolEffect {
        ScaleSymbolEffect(configuration: configuration.replacing { $0.vertical = .down })
    }

    public var byLayer: ScaleSymbolEffect {
        ScaleSymbolEffect(configuration: configuration.replacing { $0.layering = .byLayer })
    }

    public var wholeSymbol: ScaleSymbolEffect {
        ScaleSymbolEffect(configuration: configuration.replacing { $0.layering = .wholeSymbol })
    }

    public static func == (a: ScaleSymbolEffect, b: ScaleSymbolEffect) -> Bool {
        a.configuration == b.configuration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(configuration)
    }
}

extension SymbolEffect where Self == ScaleSymbolEffect {
    public static var scale: ScaleSymbolEffect {
        ScaleSymbolEffect(configuration: SymbolEffectConfiguration(kind: .scale))
    }
}

public struct AppearSymbolEffect: SymbolEffect, TransitionSymbolEffect, IndefiniteSymbolEffect {
    public var configuration: SymbolEffectConfiguration

    init(configuration: SymbolEffectConfiguration) {
        self.configuration = configuration
    }

    public var up: AppearSymbolEffect {
        AppearSymbolEffect(configuration: configuration.replacing { $0.vertical = .up })
    }

    public var down: AppearSymbolEffect {
        AppearSymbolEffect(configuration: configuration.replacing { $0.vertical = .down })
    }

    public var byLayer: AppearSymbolEffect {
        AppearSymbolEffect(configuration: configuration.replacing { $0.layering = .byLayer })
    }

    public var wholeSymbol: AppearSymbolEffect {
        AppearSymbolEffect(configuration: configuration.replacing { $0.layering = .wholeSymbol })
    }

    public static func == (a: AppearSymbolEffect, b: AppearSymbolEffect) -> Bool {
        a.configuration == b.configuration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(configuration)
    }
}

extension SymbolEffect where Self == AppearSymbolEffect {
    public static var appear: AppearSymbolEffect {
        AppearSymbolEffect(configuration: SymbolEffectConfiguration(kind: .appear))
    }
}

public struct DisappearSymbolEffect: SymbolEffect, TransitionSymbolEffect, IndefiniteSymbolEffect {
    public var configuration: SymbolEffectConfiguration

    init(configuration: SymbolEffectConfiguration) {
        self.configuration = configuration
    }

    public var up: DisappearSymbolEffect {
        DisappearSymbolEffect(configuration: configuration.replacing { $0.vertical = .up })
    }

    public var down: DisappearSymbolEffect {
        DisappearSymbolEffect(configuration: configuration.replacing { $0.vertical = .down })
    }

    public var byLayer: DisappearSymbolEffect {
        DisappearSymbolEffect(configuration: configuration.replacing { $0.layering = .byLayer })
    }

    public var wholeSymbol: DisappearSymbolEffect {
        DisappearSymbolEffect(configuration: configuration.replacing { $0.layering = .wholeSymbol })
    }

    public static func == (a: DisappearSymbolEffect, b: DisappearSymbolEffect) -> Bool {
        a.configuration == b.configuration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(configuration)
    }
}

extension SymbolEffect where Self == DisappearSymbolEffect {
    public static var disappear: DisappearSymbolEffect {
        DisappearSymbolEffect(configuration: SymbolEffectConfiguration(kind: .disappear))
    }
}

public struct ReplaceSymbolEffect: SymbolEffect, ContentTransitionSymbolEffect {
    public var configuration: SymbolEffectConfiguration

    init(configuration: SymbolEffectConfiguration) {
        self.configuration = configuration
    }

    public var downUp: ReplaceSymbolEffect {
        ReplaceSymbolEffect(configuration: configuration.replacing { $0.replace = .downUp })
    }

    public var upUp: ReplaceSymbolEffect {
        ReplaceSymbolEffect(configuration: configuration.replacing { $0.replace = .upUp })
    }

    public var offUp: ReplaceSymbolEffect {
        ReplaceSymbolEffect(configuration: configuration.replacing { $0.replace = .offUp })
    }

    public var byLayer: ReplaceSymbolEffect {
        ReplaceSymbolEffect(configuration: configuration.replacing { $0.layering = .byLayer })
    }

    public var wholeSymbol: ReplaceSymbolEffect {
        ReplaceSymbolEffect(configuration: configuration.replacing { $0.layering = .wholeSymbol })
    }

    public static var downUp: ReplaceSymbolEffect {
        ReplaceSymbolEffect.replace.downUp
    }

    public static var upUp: ReplaceSymbolEffect {
        ReplaceSymbolEffect.replace.upUp
    }

    public static var offUp: ReplaceSymbolEffect {
        ReplaceSymbolEffect.replace.offUp
    }

    public func magic(fallback: ReplaceSymbolEffect) -> MagicReplace {
        MagicReplace(
            configuration: configuration.replacing { snapshot in
                snapshot.kind = .magicReplace
                snapshot.hasMagicFallback = true
                snapshot.magicFallbackReplace = fallback.configuration.snapshot.replace
                snapshot.magicFallbackLayering = fallback.configuration.snapshot.layering
            }
        )
    }

    public static func == (a: ReplaceSymbolEffect, b: ReplaceSymbolEffect) -> Bool {
        a.configuration == b.configuration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(configuration)
    }

    public struct MagicReplace: SymbolEffect, ContentTransitionSymbolEffect {
        public var configuration: SymbolEffectConfiguration

        init(configuration: SymbolEffectConfiguration) {
            self.configuration = configuration
        }

        public static func == (a: MagicReplace, b: MagicReplace) -> Bool {
            a.configuration == b.configuration
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(configuration)
        }
    }
}

extension SymbolEffect where Self == ReplaceSymbolEffect {
    public static var replace: ReplaceSymbolEffect {
        ReplaceSymbolEffect(configuration: SymbolEffectConfiguration(kind: .replace))
    }
}

public struct AutomaticSymbolEffect: SymbolEffect, TransitionSymbolEffect, ContentTransitionSymbolEffect {
    public var configuration: SymbolEffectConfiguration

    init(configuration: SymbolEffectConfiguration) {
        self.configuration = configuration
    }

    public static func == (a: AutomaticSymbolEffect, b: AutomaticSymbolEffect) -> Bool {
        a.configuration == b.configuration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(configuration)
    }
}

extension SymbolEffect where Self == AutomaticSymbolEffect {
    public static var automatic: AutomaticSymbolEffect {
        AutomaticSymbolEffect(configuration: SymbolEffectConfiguration(kind: .automatic))
    }
}

public struct WiggleSymbolEffect: SymbolEffect, IndefiniteSymbolEffect, DiscreteSymbolEffect {
    public var configuration: SymbolEffectConfiguration

    init(configuration: SymbolEffectConfiguration) {
        self.configuration = configuration
    }

    public var up: WiggleSymbolEffect {
        WiggleSymbolEffect(configuration: configuration.replacing { $0.wiggle = .up })
    }

    public var down: WiggleSymbolEffect {
        WiggleSymbolEffect(configuration: configuration.replacing { $0.wiggle = .down })
    }

    public var left: WiggleSymbolEffect {
        WiggleSymbolEffect(configuration: configuration.replacing { $0.wiggle = .left })
    }

    public var right: WiggleSymbolEffect {
        WiggleSymbolEffect(configuration: configuration.replacing { $0.wiggle = .right })
    }

    public var forward: WiggleSymbolEffect {
        WiggleSymbolEffect(configuration: configuration.replacing { $0.wiggle = .forward })
    }

    public var backward: WiggleSymbolEffect {
        WiggleSymbolEffect(configuration: configuration.replacing { $0.wiggle = .backward })
    }

    public var clockwise: WiggleSymbolEffect {
        WiggleSymbolEffect(configuration: configuration.replacing { $0.wiggle = .clockwise })
    }

    public var counterClockwise: WiggleSymbolEffect {
        WiggleSymbolEffect(configuration: configuration.replacing { $0.wiggle = .counterClockwise })
    }

    public func custom(angle: Double) -> WiggleSymbolEffect {
        WiggleSymbolEffect(configuration: configuration.replacing { $0.wiggle = .custom(angle) })
    }

    public var byLayer: WiggleSymbolEffect {
        WiggleSymbolEffect(configuration: configuration.replacing { $0.layering = .byLayer })
    }

    public var wholeSymbol: WiggleSymbolEffect {
        WiggleSymbolEffect(configuration: configuration.replacing { $0.layering = .wholeSymbol })
    }

    public static func == (a: WiggleSymbolEffect, b: WiggleSymbolEffect) -> Bool {
        a.configuration == b.configuration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(configuration)
    }
}

extension SymbolEffect where Self == WiggleSymbolEffect {
    public static var wiggle: WiggleSymbolEffect {
        WiggleSymbolEffect(configuration: SymbolEffectConfiguration(kind: .wiggle))
    }
}

public struct RotateSymbolEffect: SymbolEffect, IndefiniteSymbolEffect, DiscreteSymbolEffect {
    public var configuration: SymbolEffectConfiguration

    init(configuration: SymbolEffectConfiguration) {
        self.configuration = configuration
    }

    public var clockwise: RotateSymbolEffect {
        RotateSymbolEffect(configuration: configuration.replacing { $0.rotation = .clockwise })
    }

    public var counterClockwise: RotateSymbolEffect {
        RotateSymbolEffect(configuration: configuration.replacing { $0.rotation = .counterClockwise })
    }

    public var byLayer: RotateSymbolEffect {
        RotateSymbolEffect(configuration: configuration.replacing { $0.layering = .byLayer })
    }

    public var wholeSymbol: RotateSymbolEffect {
        RotateSymbolEffect(configuration: configuration.replacing { $0.layering = .wholeSymbol })
    }

    public static func == (a: RotateSymbolEffect, b: RotateSymbolEffect) -> Bool {
        a.configuration == b.configuration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(configuration)
    }
}

extension SymbolEffect where Self == RotateSymbolEffect {
    public static var rotate: RotateSymbolEffect {
        RotateSymbolEffect(configuration: SymbolEffectConfiguration(kind: .rotate))
    }
}

public struct BreatheSymbolEffect: SymbolEffect, IndefiniteSymbolEffect, DiscreteSymbolEffect {
    public var configuration: SymbolEffectConfiguration

    init(configuration: SymbolEffectConfiguration) {
        self.configuration = configuration
    }

    public var plain: BreatheSymbolEffect {
        BreatheSymbolEffect(configuration: configuration.replacing { $0.breathe = .plain })
    }

    public var pulse: BreatheSymbolEffect {
        BreatheSymbolEffect(configuration: configuration.replacing { $0.breathe = .pulse })
    }

    public var byLayer: BreatheSymbolEffect {
        BreatheSymbolEffect(configuration: configuration.replacing { $0.layering = .byLayer })
    }

    public var wholeSymbol: BreatheSymbolEffect {
        BreatheSymbolEffect(configuration: configuration.replacing { $0.layering = .wholeSymbol })
    }

    public static func == (a: BreatheSymbolEffect, b: BreatheSymbolEffect) -> Bool {
        a.configuration == b.configuration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(configuration)
    }
}

extension SymbolEffect where Self == BreatheSymbolEffect {
    public static var breathe: BreatheSymbolEffect {
        BreatheSymbolEffect(configuration: SymbolEffectConfiguration(kind: .breathe))
    }
}

public struct DrawOnSymbolEffect: SymbolEffect, TransitionSymbolEffect, IndefiniteSymbolEffect {
    public var configuration: SymbolEffectConfiguration

    init(configuration: SymbolEffectConfiguration) {
        self.configuration = configuration
    }

    public var byLayer: DrawOnSymbolEffect {
        DrawOnSymbolEffect(configuration: configuration.replacing { $0.layering = .byLayer })
    }

    public var wholeSymbol: DrawOnSymbolEffect {
        DrawOnSymbolEffect(configuration: configuration.replacing { $0.layering = .wholeSymbol })
    }

    public var individually: DrawOnSymbolEffect {
        DrawOnSymbolEffect(configuration: configuration.replacing { $0.layering = .individually })
    }

    public static func == (a: DrawOnSymbolEffect, b: DrawOnSymbolEffect) -> Bool {
        a.configuration == b.configuration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(configuration)
    }
}

extension SymbolEffect where Self == DrawOnSymbolEffect {
    public static var drawOn: DrawOnSymbolEffect {
        DrawOnSymbolEffect(configuration: SymbolEffectConfiguration(kind: .drawOn))
    }
}

public struct DrawOffSymbolEffect: SymbolEffect, TransitionSymbolEffect, IndefiniteSymbolEffect {
    public var configuration: SymbolEffectConfiguration

    init(configuration: SymbolEffectConfiguration) {
        self.configuration = configuration
    }

    public var byLayer: DrawOffSymbolEffect {
        DrawOffSymbolEffect(configuration: configuration.replacing { $0.layering = .byLayer })
    }

    public var wholeSymbol: DrawOffSymbolEffect {
        DrawOffSymbolEffect(configuration: configuration.replacing { $0.layering = .wholeSymbol })
    }

    public var individually: DrawOffSymbolEffect {
        DrawOffSymbolEffect(configuration: configuration.replacing { $0.layering = .individually })
    }

    public var reversed: DrawOffSymbolEffect {
        DrawOffSymbolEffect(configuration: configuration.replacing { $0.drawOffReverse = .reversed })
    }

    public var nonReversed: DrawOffSymbolEffect {
        DrawOffSymbolEffect(configuration: configuration.replacing { $0.drawOffReverse = .nonReversed })
    }

    public static func == (a: DrawOffSymbolEffect, b: DrawOffSymbolEffect) -> Bool {
        a.configuration == b.configuration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(configuration)
    }
}

extension SymbolEffect where Self == DrawOffSymbolEffect {
    public static var drawOff: DrawOffSymbolEffect {
        DrawOffSymbolEffect(configuration: SymbolEffectConfiguration(kind: .drawOff))
    }
}
