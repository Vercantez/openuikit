import Symbols
import Foundation

func testSymbolEffectOptionsDefaultAndSpeed() {
    let defaults = SymbolEffectOptions.default
    _symbolsHashableEqual(defaults, SymbolEffectOptions.default)
    let fast = defaults.speed(2)
    let fastStatic = SymbolEffectOptions.speed(2)
    _symbolsHashableEqual(fast, fastStatic)
    _symbolsHashableDistinct(defaults, fast)
    _symbolsHashableDistinct(SymbolEffectOptions.speed(1), SymbolEffectOptions.speed(2))
    precondition(fast.speed(0.5) == SymbolEffectOptions.speed(0.5))
    _ = defaults.hashValue
    var hasher = Hasher()
    defaults.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(defaults != fast)
}

func testSymbolEffectOptionsRepeatingFlags() {
    let repeating = SymbolEffectOptions.repeating
    let nonRepeating = SymbolEffectOptions.nonRepeating
    _symbolsHashableEqual(repeating, SymbolEffectOptions.default.repeating)
    _symbolsHashableEqual(nonRepeating, SymbolEffectOptions.default.nonRepeating)
    _symbolsHashableDistinct(repeating, nonRepeating)
    _symbolsHashableDistinct(repeating, SymbolEffectOptions.default)
    let sped = SymbolEffectOptions.speed(1.25).repeating
    precondition(sped == SymbolEffectOptions.repeating.speed(1.25))
    precondition(SymbolEffectOptions.speed(1.25).nonRepeating == nonRepeating.speed(1.25))
    _ = repeating.hashValue
    _ = nonRepeating.hashValue
    precondition(repeating != nonRepeating)
}

func testSymbolEffectOptionsRepeatCount() {
    let three = SymbolEffectOptions.repeat(3)
    let threeInstance = SymbolEffectOptions.default.repeat(3)
    let unlimited = SymbolEffectOptions.repeat(nil as Int?)
    _symbolsHashableEqual(three, threeInstance)
    _symbolsHashableDistinct(three, unlimited)
    _symbolsHashableDistinct(three, SymbolEffectOptions.repeat(2))
    _symbolsHashableDistinct(three, SymbolEffectOptions.repeating)
    precondition(SymbolEffectOptions.speed(3).repeat(3) == three.speed(3))
    _ = three.hashValue
    var hasher = Hasher()
    three.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(three != unlimited)
}

func testSymbolEffectOptionsRepeatBehavior() {
    let continuous = SymbolEffectOptions.RepeatBehavior.continuous
    let periodic = SymbolEffectOptions.RepeatBehavior.periodic
    let periodicNil = SymbolEffectOptions.RepeatBehavior.periodic(nil, delay: nil)
    let periodicCount = SymbolEffectOptions.RepeatBehavior.periodic(4, delay: nil)
    let delay: TimeInterval = 0.2
    let periodicDelay = SymbolEffectOptions.RepeatBehavior.periodic(nil, delay: delay)
    let periodicBoth = SymbolEffectOptions.RepeatBehavior.periodic(2, delay: delay)

    let optionsContinuous = SymbolEffectOptions.repeat(continuous)
    let optionsPeriodic = SymbolEffectOptions.default.repeat(periodic)
    _symbolsHashableEqual(optionsPeriodic, SymbolEffectOptions.repeat(periodicNil))
    _symbolsHashableDistinct(optionsContinuous, optionsPeriodic)
    _symbolsHashableDistinct(
        SymbolEffectOptions.repeat(periodicCount),
        SymbolEffectOptions.repeat(periodicDelay)
    )
    _symbolsHashableDistinct(
        SymbolEffectOptions.repeat(periodicBoth),
        SymbolEffectOptions.repeat(periodicCount)
    )
    _symbolsHashableDistinct(optionsContinuous, SymbolEffectOptions.repeating)
    _symbolsHashableDistinct(optionsPeriodic, SymbolEffectOptions.repeat(nil as Int?))
    precondition(
        SymbolEffectOptions.speed(1.1).repeat(continuous)
            == optionsContinuous.speed(1.1)
    )
    _ = optionsContinuous.hashValue
    var hasher = Hasher()
    optionsContinuous.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(optionsContinuous != optionsPeriodic)
}

func testSymbolEffectConfigurationEquality() {
    let pulse = PulseSymbolEffect.pulse.configuration
    let bounce = BounceSymbolEffect.bounce.configuration
    _symbolsHashableEqual(pulse, PulseSymbolEffect.pulse.configuration)
    _symbolsHashableDistinct(pulse, bounce)
    _symbolsHashableDistinct(pulse, PulseSymbolEffect.pulse.byLayer.configuration)
    _symbolsHashableEqual(
        ScaleSymbolEffect.scale.up.configuration,
        ScaleSymbolEffect.scale.up.configuration
    )
    _ = pulse.hashValue
    var hasher = Hasher()
    pulse.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(pulse != bounce)
}
