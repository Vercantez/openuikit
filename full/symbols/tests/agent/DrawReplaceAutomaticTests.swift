import Symbols

func testDrawOnSymbolEffect() {
    let drawOn = DrawOnSymbolEffect.drawOn
    _symbolsHashableEqual(drawOn, DrawOnSymbolEffect.drawOn)
    _symbolsHashableDistinct(drawOn.byLayer, drawOn.wholeSymbol)
    _symbolsHashableDistinct(drawOn.individually, drawOn.byLayer)
    _symbolsHashableDistinct(drawOn.individually, drawOn.wholeSymbol)
    _symbolsHashableDistinct(drawOn, drawOn.individually)
    precondition(drawOn.byLayer.individually == drawOn.individually)
    precondition(drawOn.wholeSymbol.byLayer == drawOn.byLayer)
    _symbolsAcceptTransition(drawOn)
    _symbolsAcceptIndefinite(drawOn)
    _ = drawOn.hashValue
    var hasher = Hasher()
    drawOn.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(drawOn != drawOn.wholeSymbol)
}

func testDrawOffSymbolEffect() {
    let drawOff = DrawOffSymbolEffect.drawOff
    _symbolsHashableEqual(drawOff, DrawOffSymbolEffect.drawOff)
    _symbolsHashableDistinct(drawOff.byLayer, drawOff.wholeSymbol)
    _symbolsHashableDistinct(drawOff.individually, drawOff.byLayer)
    _symbolsHashableDistinct(drawOff.reversed, drawOff.nonReversed)
    _symbolsHashableDistinct(drawOff, drawOff.reversed)
    precondition(drawOff.individually.reversed == DrawOffSymbolEffect.drawOff.reversed.individually)
    precondition(drawOff.wholeSymbol.nonReversed == DrawOffSymbolEffect.drawOff.nonReversed.wholeSymbol)
    _symbolsAcceptTransition(drawOff)
    _ = drawOff.hashValue
    var hasher = Hasher()
    drawOff.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(drawOff != drawOff.individually)
}

func testReplaceSymbolEffect() {
    let replace = ReplaceSymbolEffect.replace
    _symbolsHashableEqual(replace, ReplaceSymbolEffect.replace)
    _symbolsHashableDistinct(replace.downUp, replace.upUp)
    _symbolsHashableDistinct(replace.upUp, replace.offUp)
    _symbolsHashableDistinct(replace, replace.downUp)
    _symbolsHashableEqual(ReplaceSymbolEffect.downUp, replace.downUp)
    _symbolsHashableEqual(ReplaceSymbolEffect.upUp, replace.upUp)
    _symbolsHashableEqual(ReplaceSymbolEffect.offUp, replace.offUp)
    _symbolsHashableDistinct(replace.byLayer, replace.wholeSymbol)
    precondition(ReplaceSymbolEffect.upUp.byLayer == replace.byLayer.upUp)
    precondition(ReplaceSymbolEffect.offUp.wholeSymbol == replace.wholeSymbol.offUp)
    _symbolsAcceptContentTransition(replace)
    _ = replace.hashValue
    var hasher = Hasher()
    replace.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(replace != replace.offUp)
}

func testMagicReplaceSymbolEffect() {
    let fallback = ReplaceSymbolEffect.offUp
    let magic = ReplaceSymbolEffect.downUp.magic(fallback: fallback)
    let same = ReplaceSymbolEffect.downUp.magic(fallback: ReplaceSymbolEffect.offUp)
    let other = ReplaceSymbolEffect.upUp.magic(fallback: fallback)
    let otherFallback = ReplaceSymbolEffect.downUp.magic(fallback: .upUp)
    _symbolsHashableEqual(magic, same)
    _symbolsHashableDistinct(magic, other)
    _symbolsHashableDistinct(magic, otherFallback)
    precondition(magic.configuration != ReplaceSymbolEffect.downUp.configuration)
    precondition(magic.configuration != fallback.configuration)
    _symbolsAcceptContentTransition(magic)
    _ = magic.hashValue
    var hasher = Hasher()
    magic.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(magic != other)
}

func testAutomaticSymbolEffect() {
    let automatic = AutomaticSymbolEffect.automatic
    _symbolsHashableEqual(automatic, AutomaticSymbolEffect.automatic)
    precondition(automatic.configuration != ReplaceSymbolEffect.replace.configuration)
    precondition(automatic.configuration != AppearSymbolEffect.appear.configuration)
    _symbolsAcceptTransition(automatic)
    _symbolsAcceptContentTransition(automatic)
    _ = automatic.hashValue
    var hasher = Hasher()
    automatic.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(!(automatic != AutomaticSymbolEffect.automatic))
}
