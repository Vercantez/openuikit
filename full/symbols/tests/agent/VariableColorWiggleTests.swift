import Symbols

func testVariableColorSymbolEffect() {
    let color = VariableColorSymbolEffect.variableColor
    _symbolsHashableEqual(color, VariableColorSymbolEffect.variableColor)
    _symbolsHashableDistinct(color.iterative, color.cumulative)
    _symbolsHashableDistinct(color, color.iterative)
    _symbolsHashableDistinct(color.reversing, color.nonReversing)
    _symbolsHashableDistinct(color.hideInactiveLayers, color.dimInactiveLayers)
    let composed = color.iterative.reversing.dimInactiveLayers
    precondition(composed == VariableColorSymbolEffect.variableColor.dimInactiveLayers.reversing.iterative)
    precondition(composed.cumulative == color.cumulative.reversing.dimInactiveLayers)
    precondition(composed.nonReversing.hideInactiveLayers == color.iterative.nonReversing.hideInactiveLayers)
    _ = color.hashValue
    var hasher = Hasher()
    color.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(color != color.cumulative)
}

func testWiggleSymbolEffect() {
    let wiggle = WiggleSymbolEffect.wiggle
    _symbolsHashableEqual(wiggle, WiggleSymbolEffect.wiggle)
    _symbolsHashableDistinct(wiggle.up, wiggle.down)
    _symbolsHashableDistinct(wiggle.left, wiggle.right)
    _symbolsHashableDistinct(wiggle.forward, wiggle.backward)
    _symbolsHashableDistinct(wiggle.clockwise, wiggle.counterClockwise)
    _symbolsHashableDistinct(wiggle.custom(angle: 0.25), wiggle.custom(angle: 0.5))
    _symbolsHashableDistinct(wiggle.custom(angle: 0), wiggle.clockwise)
    _symbolsHashableDistinct(wiggle, wiggle.custom(angle: 1))
    _symbolsHashableDistinct(wiggle.byLayer, wiggle.wholeSymbol)
    precondition(wiggle.left.byLayer == WiggleSymbolEffect.wiggle.byLayer.left)
    precondition(wiggle.custom(angle: 1.5).wholeSymbol == WiggleSymbolEffect.wiggle.wholeSymbol.custom(angle: 1.5))
    precondition(wiggle.up.right == wiggle.right)
    _ = wiggle.hashValue
    var hasher = Hasher()
    wiggle.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(wiggle != wiggle.forward)
}

func testRotateSymbolEffect() {
    let rotate = RotateSymbolEffect.rotate
    _symbolsHashableEqual(rotate, RotateSymbolEffect.rotate)
    _symbolsHashableDistinct(rotate.clockwise, rotate.counterClockwise)
    _symbolsHashableDistinct(rotate, rotate.clockwise)
    _symbolsHashableDistinct(rotate.byLayer, rotate.wholeSymbol)
    precondition(rotate.clockwise.byLayer == RotateSymbolEffect.rotate.byLayer.clockwise)
    precondition(rotate.counterClockwise.wholeSymbol == RotateSymbolEffect.rotate.wholeSymbol.counterClockwise)
    _ = rotate.hashValue
    var hasher = Hasher()
    rotate.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(rotate != rotate.wholeSymbol)
}

func testBreatheSymbolEffect() {
    let breathe = BreatheSymbolEffect.breathe
    _symbolsHashableEqual(breathe, BreatheSymbolEffect.breathe)
    _symbolsHashableDistinct(breathe.plain, breathe.pulse)
    _symbolsHashableDistinct(breathe, breathe.plain)
    _symbolsHashableDistinct(breathe.byLayer, breathe.wholeSymbol)
    precondition(breathe.pulse.byLayer == BreatheSymbolEffect.breathe.byLayer.pulse)
    precondition(breathe.plain.wholeSymbol == BreatheSymbolEffect.breathe.wholeSymbol.plain)
    _ = breathe.hashValue
    var hasher = Hasher()
    breathe.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(breathe != breathe.pulse)
}
