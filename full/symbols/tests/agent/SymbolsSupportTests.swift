import Symbols

func _symbolsHashableEqual<T: Hashable>(_ left: T, _ right: T) {
    precondition(left == right)
    precondition(!(left != right))
    precondition(left.hashValue == right.hashValue)
    var hasher = Hasher()
    left.hash(into: &hasher)
    _ = hasher.finalize()
}

func _symbolsHashableDistinct<T: Hashable>(_ left: T, _ right: T) {
    precondition(left != right)
    precondition(!(left == right))
}

func _symbolsReadConfiguration<T: SymbolEffect>(_ effect: T) -> SymbolEffectConfiguration {
    effect.configuration
}

func _symbolsAcceptDiscrete<T: DiscreteSymbolEffect>(_ effect: T) {
    _ = effect
}

func _symbolsAcceptIndefinite<T: IndefiniteSymbolEffect>(_ effect: T) {
    _ = effect
}

func _symbolsAcceptTransition<T: TransitionSymbolEffect>(_ effect: T) {
    _ = effect
}

func _symbolsAcceptContentTransition<T: ContentTransitionSymbolEffect>(_ effect: T) {
    _ = effect
}

func testSymbolEffectProtocolRequirement() {
    let pulse = PulseSymbolEffect.pulse
    let throughProtocol = _symbolsReadConfiguration(pulse)
    precondition(throughProtocol == pulse.configuration)
    _symbolsHashableEqual(throughProtocol, pulse.configuration)
    _symbolsAcceptIndefinite(pulse)
    _symbolsAcceptDiscrete(pulse)
}

func testDiscreteSymbolEffectProtocol() {
    _symbolsAcceptDiscrete(PulseSymbolEffect.pulse)
    _symbolsAcceptDiscrete(BounceSymbolEffect.bounce)
    _symbolsAcceptDiscrete(VariableColorSymbolEffect.variableColor)
    _symbolsAcceptDiscrete(WiggleSymbolEffect.wiggle)
    _symbolsAcceptDiscrete(RotateSymbolEffect.rotate)
    _symbolsAcceptDiscrete(BreatheSymbolEffect.breathe)
}

func testIndefiniteSymbolEffectProtocol() {
    _symbolsAcceptIndefinite(PulseSymbolEffect.pulse)
    _symbolsAcceptIndefinite(ScaleSymbolEffect.scale)
    _symbolsAcceptIndefinite(AppearSymbolEffect.appear)
    _symbolsAcceptIndefinite(DisappearSymbolEffect.disappear)
    _symbolsAcceptIndefinite(DrawOnSymbolEffect.drawOn)
    _symbolsAcceptIndefinite(DrawOffSymbolEffect.drawOff)
}

func testTransitionSymbolEffectProtocol() {
    _symbolsAcceptTransition(AppearSymbolEffect.appear)
    _symbolsAcceptTransition(DisappearSymbolEffect.disappear)
    _symbolsAcceptTransition(AutomaticSymbolEffect.automatic)
    _symbolsAcceptTransition(DrawOnSymbolEffect.drawOn)
    _symbolsAcceptTransition(DrawOffSymbolEffect.drawOff)
}

func testContentTransitionSymbolEffectProtocol() {
    _symbolsAcceptContentTransition(ReplaceSymbolEffect.replace)
    _symbolsAcceptContentTransition(ReplaceSymbolEffect.replace.magic(fallback: .offUp))
    _symbolsAcceptContentTransition(AutomaticSymbolEffect.automatic)
}
