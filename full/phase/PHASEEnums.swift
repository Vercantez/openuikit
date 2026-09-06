import Foundation

/// FourCC / sequential raw values follow pinned `dotnet/macios` PHASE enums.

public enum PHASECalibrationMode: Int, Hashable, Sendable {
    case none = 0
    case relativeSpl = 1
    case absoluteSpl = 2
}

public enum PHASECullOption: Int, Hashable, Sendable {
    case terminate = 0
    case sleepWakeAtZero = 1
    case sleepWakeAtRandomOffset = 2
    case sleepWakeAtRealtimeOffset = 3
    case doNotCull = 4
}

public enum PHASECurveType: Int, Hashable, Sendable {
    case linear = 1_668_435_054
    case squared = 1_668_436_849
    case inverseSquared = 1_668_434_257
    case cubed = 1_668_432_757
    case inverseCubed = 1_668_434_243
    case sine = 1_668_436_846
    case inverseSine = 1_668_434_259
    case sigmoid = 1_668_436_839
    case inverseSigmoid = 1_668_434_247
    case holdStartValue = 1_668_434_003
    case jumpToEndValue = 1_668_434_501
}

public enum PHASEMaterialPreset: Int, Hashable, Sendable {
    case cardboard = 1_833_136_740
    case glass = 1_833_397_363
    case brick = 1_833_071_211
    case concrete = 1_833_132_914
    case drywall = 1_833_202_295
    case wood = 1_834_448_228
}

public enum PHASENormalizationMode: Int, Hashable, Sendable {
    case none = 0
    case dynamic = 1
}

public enum PHASEPlaybackMode: Int, Hashable, Sendable {
    case oneShot = 0
    case looping = 1
}

public enum PHASEPushStreamCompletionCallbackCondition: Int, Hashable, Sendable {
    case dataRendered = 0
}

public enum PHASEReverbPreset: Int, Hashable, Sendable {
    case none = 1_917_742_958
    case smallRoom = 1_918_063_213
    case mediumRoom = 1_917_669_997
    case largeRoom = 1_917_604_401
    case largeRoom2 = 1_917_604_402
    case mediumChamber = 1_917_666_152
    case largeChamber = 1_917_600_616
    case mediumHall = 1_917_667_377
    case mediumHall2 = 1_917_667_378
    case mediumHall3 = 1_917_667_379
    case largeHall = 1_917_601_841
    case largeHall2 = 1_917_601_842
    case cathedral = 1_917_023_336
}

public enum PHASESpatializationMode: Int, Hashable, Sendable {
    case automatic = 0
    case alwaysUseBinaural = 1
    case alwaysUseChannelBased = 2
}

/// Piecewise unit-interval easing used by `PHASEEnvelope.evaluate(x:)`.
/// Exact Apple sigmoid steepness is unobserved; this uses a logistic with
/// scale 12. Inverse curves are `1 - f(1 - t)` of the forward family.
func phaseEase(_ t: Double, _ curve: PHASECurveType) -> Double {
    let x = min(max(t, 0), 1)
    switch curve {
    case .linear:
        return x
    case .squared:
        return x * x
    case .inverseSquared:
        let y = 1 - x
        return 1 - y * y
    case .cubed:
        return x * x * x
    case .inverseCubed:
        let y = 1 - x
        return 1 - y * y * y
    case .sine:
        return sin(x * Double.pi / 2)
    case .inverseSine:
        return 1 - sin((1 - x) * Double.pi / 2)
    case .sigmoid:
        return 1 / (1 + exp(-12 * (x - 0.5)))
    case .inverseSigmoid:
        return 1 - (1 / (1 + exp(-12 * ((1 - x) - 0.5))))
    case .holdStartValue:
        return 0
    case .jumpToEndValue:
        return 1
    }
}
