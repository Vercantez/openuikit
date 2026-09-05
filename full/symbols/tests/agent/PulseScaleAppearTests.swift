import Symbols

func testPulseSymbolEffect() {
    let pulse = PulseSymbolEffect.pulse
    _symbolsHashableEqual(pulse, PulseSymbolEffect.pulse)
    _symbolsHashableEqual(pulse.byLayer, PulseSymbolEffect.pulse.byLayer)
    _symbolsHashableEqual(pulse.wholeSymbol, PulseSymbolEffect.pulse.wholeSymbol)
    _symbolsHashableDistinct(pulse, pulse.byLayer)
    _symbolsHashableDistinct(pulse.byLayer, pulse.wholeSymbol)
    _symbolsHashableDistinct(pulse, pulse.wholeSymbol)
    precondition(pulse.byLayer.wholeSymbol == pulse.wholeSymbol)
    precondition(pulse.wholeSymbol.byLayer == pulse.byLayer)
    precondition(pulse.configuration != BounceSymbolEffect.bounce.configuration)
    _ = pulse.hashValue
    var hasher = Hasher()
    pulse.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(pulse != pulse.byLayer)
}

func testBounceSymbolEffect() {
    let bounce = BounceSymbolEffect.bounce
    _symbolsHashableEqual(bounce, BounceSymbolEffect.bounce)
    _symbolsHashableDistinct(bounce.up, bounce.down)
    _symbolsHashableDistinct(bounce, bounce.up)
    _symbolsHashableDistinct(bounce.byLayer, bounce.wholeSymbol)
    precondition(bounce.up.byLayer == BounceSymbolEffect.bounce.byLayer.up)
    precondition(bounce.down.wholeSymbol == BounceSymbolEffect.bounce.wholeSymbol.down)
    precondition(bounce.up.down == bounce.down)
    _ = bounce.hashValue
    var hasher = Hasher()
    bounce.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(bounce != bounce.down)
}

func testScaleSymbolEffect() {
    let scale = ScaleSymbolEffect.scale
    _symbolsHashableEqual(scale, ScaleSymbolEffect.scale)
    _symbolsHashableDistinct(scale.up, scale.down)
    _symbolsHashableDistinct(scale, scale.up)
    _symbolsHashableDistinct(scale.byLayer, scale.wholeSymbol)
    precondition(scale.up.wholeSymbol == ScaleSymbolEffect.scale.wholeSymbol.up)
    precondition(scale.down.byLayer == ScaleSymbolEffect.scale.byLayer.down)
    _symbolsAcceptIndefinite(scale)
    _ = scale.hashValue
    var hasher = Hasher()
    scale.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(scale != scale.up)
}

func testAppearSymbolEffect() {
    let appear = AppearSymbolEffect.appear
    _symbolsHashableEqual(appear, AppearSymbolEffect.appear)
    _symbolsHashableDistinct(appear.up, appear.down)
    _symbolsHashableDistinct(appear, appear.down)
    _symbolsHashableDistinct(appear.byLayer, appear.wholeSymbol)
    precondition(appear.up.byLayer == AppearSymbolEffect.appear.byLayer.up)
    _symbolsAcceptTransition(appear)
    _symbolsAcceptIndefinite(appear)
    _ = appear.hashValue
    var hasher = Hasher()
    appear.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(appear != appear.wholeSymbol)
}

func testDisappearSymbolEffect() {
    let disappear = DisappearSymbolEffect.disappear
    _symbolsHashableEqual(disappear, DisappearSymbolEffect.disappear)
    _symbolsHashableDistinct(disappear.up, disappear.down)
    _symbolsHashableDistinct(disappear, disappear.up)
    _symbolsHashableDistinct(disappear.byLayer, disappear.wholeSymbol)
    precondition(disappear.down.wholeSymbol == DisappearSymbolEffect.disappear.wholeSymbol.down)
    _symbolsAcceptTransition(disappear)
    _ = disappear.hashValue
    var hasher = Hasher()
    disappear.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(disappear != disappear.byLayer)
}
