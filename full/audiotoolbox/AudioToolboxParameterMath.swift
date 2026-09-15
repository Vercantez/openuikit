import Foundation

/// Oracle-pinned Audio Unit v2 parameter math.
///
/// Pinned against Apple AudioToolbox on macOS (Xcode 26.1) with a tiny
/// `import AudioToolbox` probe compiled via `xcrun swiftc` and executed
/// against real Apple units (MultiChannelMixer, Delay, Reverb2,
/// Distortion, GenericOutput, ScheduledSoundPlayer):
///
/// - Linear parameters interpolate without clamping:
///   `Delay` feedback (`min -99.9`, `max 99.9`, linear display) maps
///   `-0.5 -> -199.8`, `0.5 -> 0.0`, `1.5 -> 199.8`, and the inverse maps
///   `-200.0 -> -0.501001`, `200.0 -> 1.501001`.
/// - Parameters the unit does not publish (mixer global scope, mixer output
///   parameter 1, any `GenericOutput` / `ScheduledSoundPlayer` parameter)
///   convert to exactly `0.0` in both directions.
/// - The hosted Linux software mixer publishes only linear `0...1`
///   parameters (input IDs 0/1/2, output IDs 0/2), matching Apple's
///   MultiChannelMixer ranges, so the linear formula is the only reachable
///   path on Linux. Tapered display flags have no Linux-hosted unit and
///   deliberately fall back to the linear formula; the Apple taper curves
///   (square-root, cubed, exponential) and the remaining unpinned tapers
///   are recorded in `oracle-questions.tsv` instead of guessed here.
/// - `GetAudioUnitParameterDisplayType` returns `flags & DisplayMask` and
///   `SetAudioUnitParameterDisplayType` returns
///   `(flags & ~DisplayMask) | displayType` with `displayType` OR-ed in
///   unmasked (Apple maps an out-of-mask bit such as bit 25 straight
///   through). The mask applied here is the port's own
///   `flag_DisplayMask`; Apple's wider mask divergence is an oracle
///   question, not a silent semantic change.

internal func atLinearParameterRange(
    _ parameter: AudioUnitParameter
) -> (min: AudioUnitParameterValue, max: AudioUnitParameterValue)? {
    guard let handle = parameter.mAudioUnit,
        let unit = ATRegistry.shared.lookup(handle, as: ATAudioUnitObject.self),
        unit.isMixer
    else {
        return nil
    }
    let pid = parameter.mParameterID
    let scope = parameter.mScope
    if scope == kAudioUnitScope_Input
        && (pid == kMultiChannelMixerParam_Volume
            || pid == kMultiChannelMixerParam_Enable
            || pid == kMultiChannelMixerParam_Pan)
    {
        return (min: 0, max: 1)
    }
    if scope == kAudioUnitScope_Output
        && (pid == kMultiChannelMixerParam_Volume
            || pid == kMultiChannelMixerParam_Pan)
    {
        return (min: 0, max: 1)
    }
    return nil
}

public func AUParameterValueFromLinear(
    _ inLinearValue: Float32,
    _ inParameter: UnsafePointer<AudioUnitParameter>
) -> AudioUnitParameterValue {
    guard let range = atLinearParameterRange(inParameter.pointee) else {
        return 0
    }
    return range.min + inLinearValue * (range.max - range.min)
}

public func AUParameterValueToLinear(
    _ inParameterValue: AudioUnitParameterValue,
    _ inParameter: UnsafePointer<AudioUnitParameter>
) -> Float32 {
    guard let range = atLinearParameterRange(inParameter.pointee) else {
        return 0
    }
    let span = range.max - range.min
    guard span != 0 else {
        return 0
    }
    return (inParameterValue - range.min) / span
}

public func GetAudioUnitParameterDisplayType(
    _ flags: AudioUnitParameterOptions
) -> AudioUnitParameterOptions {
    flags.intersection(.flag_DisplayMask)
}

public func SetAudioUnitParameterDisplayType(
    _ flags: AudioUnitParameterOptions,
    _ displayType: AudioUnitParameterOptions
) -> AudioUnitParameterOptions {
    flags.subtracting(.flag_DisplayMask).union(displayType)
}
