import Symbols

private enum _OpenSymbolEffectKind: String {
    case appear
    case bounce
    case breathe
    case disappear
    case drawOff
    case drawOn
    case pulse
    case rotate
    case scale
    case variableColor
    case wiggle
    case other
}

private func _openSymbolEffectKind<Effect: SymbolEffect>(
    _ effect: Effect
) -> _OpenSymbolEffectKind {
    switch effect {
    case is AppearSymbolEffect: return .appear
    case is BounceSymbolEffect: return .bounce
    case is BreatheSymbolEffect: return .breathe
    case is DisappearSymbolEffect: return .disappear
    case is DrawOffSymbolEffect: return .drawOff
    case is DrawOnSymbolEffect: return .drawOn
    case is PulseSymbolEffect: return .pulse
    case is RotateSymbolEffect: return .rotate
    case is ScaleSymbolEffect: return .scale
    case is VariableColorSymbolEffect: return .variableColor
    case is WiggleSymbolEffect: return .wiggle
    default: return .other
    }
}

private struct _OpenSymbolEffectModifier: ViewModifier {
    let kind: _OpenSymbolEffectKind
    let isActive: Bool
    let trigger: String?

    @_OpenViewBuilder
    func body(content: Content) -> some _OpenView {
        switch kind {
        case .appear:
            content
                .opacity(isActive ? 1 : 0)
                .accessibilityIdentifier("SwiftUI.SymbolEffect.appear")
        case .disappear:
            content
                .opacity(isActive ? 0 : 1)
                .accessibilityIdentifier("SwiftUI.SymbolEffect.disappear")
        case .pulse, .variableColor:
            content
                .opacity(isActive ? 0.72 : 1)
                .accessibilityIdentifier("SwiftUI.SymbolEffect.\(kind.rawValue)")
        case .bounce:
            content
                .scaleEffect(isActive ? 1.08 : 1)
                .accessibilityIdentifier("SwiftUI.SymbolEffect.bounce")
        case .breathe, .scale:
            content
                .scaleEffect(isActive ? 0.94 : 1)
                .accessibilityIdentifier("SwiftUI.SymbolEffect.\(kind.rawValue)")
        case .rotate, .wiggle:
            content
                .scaleEffect(isActive ? 0.98 : 1)
                .accessibilityIdentifier("SwiftUI.SymbolEffect.\(kind.rawValue)")
        case .drawOn:
            content
                .opacity(isActive ? 1 : 0)
                .accessibilityIdentifier("SwiftUI.SymbolEffect.drawOn")
        case .drawOff:
            content
                .opacity(isActive ? 0 : 1)
                .accessibilityIdentifier("SwiftUI.SymbolEffect.drawOff")
        case .other:
            content.accessibilityIdentifier("SwiftUI.SymbolEffect.other")
        }
    }
}

public extension _OpenView {
    func symbolEffect<Effect>(
        _ effect: Effect,
        options: SymbolEffectOptions = .default,
        isActive: Bool = true
    ) -> some _OpenView where Effect: SymbolEffect & IndefiniteSymbolEffect {
        _ = options
        return modifier(
            _OpenSymbolEffectModifier(
                kind: _openSymbolEffectKind(effect),
                isActive: isActive,
                trigger: nil
            )
        )
    }

    func symbolEffect<Effect, Value>(
        _ effect: Effect,
        options: SymbolEffectOptions = .default,
        value: Value
    ) -> some _OpenView
    where Effect: SymbolEffect & DiscreteSymbolEffect, Value: Equatable {
        _ = options
        return modifier(
            _OpenSymbolEffectModifier(
                kind: _openSymbolEffectKind(effect),
                isActive: true,
                trigger: String(reflecting: value)
            )
        )
    }
}
