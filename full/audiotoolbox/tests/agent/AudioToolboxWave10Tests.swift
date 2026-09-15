import Foundation
import AudioToolbox

private func atW10Expect(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

private func atW10Mixer() -> AudioComponentInstance? {
    var description = AudioComponentDescription(
        componentType: kAudioUnitType_Mixer,
        componentSubType: kAudioUnitSubType_MultiChannelMixer,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
    let component = AudioComponentFindNext(nil, &description)
    var mixer: AudioComponentInstance?
    guard AudioComponentInstanceNew(component, &mixer) == 0, let unit = mixer else {
        return nil
    }
    guard AudioUnitInitialize(unit) == 0 else {
        return nil
    }
    return unit
}

private func atW10GenericOutput() -> AudioComponentInstance? {
    var description = AudioComponentDescription(
        componentType: kAudioUnitType_Output,
        componentSubType: kAudioUnitSubType_GenericOutput,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
    let component = AudioComponentFindNext(nil, &description)
    var unit: AudioComponentInstance?
    guard AudioComponentInstanceNew(component, &unit) == 0, let out = unit else {
        return nil
    }
    guard AudioUnitInitialize(out) == 0 else {
        return nil
    }
    return out
}

private func atW10FromLinear(
    _ linear: Float32,
    unit: AudioComponentInstance?,
    pid: AudioUnitParameterID,
    scope: AudioUnitScope,
    element: AudioUnitElement
) -> AudioUnitParameterValue {
    var param = AudioUnitParameter(
        mAudioUnit: unit,
        mParameterID: pid,
        mScope: scope,
        mElement: element
    )
    return withUnsafePointer(to: &param) { AUParameterValueFromLinear(linear, $0) }
}

private func atW10ToLinear(
    _ value: AudioUnitParameterValue,
    unit: AudioComponentInstance?,
    pid: AudioUnitParameterID,
    scope: AudioUnitScope,
    element: AudioUnitElement
) -> Float32 {
    var param = AudioUnitParameter(
        mAudioUnit: unit,
        mParameterID: pid,
        mScope: scope,
        mElement: element
    )
    return withUnsafePointer(to: &param) { AUParameterValueToLinear(value, $0) }
}

func testAUParameterValueFromLinear() {
    guard let mixer = atW10Mixer() else {
        fatalError("mixer")
    }
    // Hosted mixer volume is linear 0...1 (Apple-oracle pinned).
    atW10Expect(
        atW10FromLinear(0.5, unit: mixer, pid: kMultiChannelMixerParam_Volume, scope: kAudioUnitScope_Input, element: 0) == 0.5,
        "vol half"
    )
    atW10Expect(
        atW10FromLinear(0.0, unit: mixer, pid: kMultiChannelMixerParam_Volume, scope: kAudioUnitScope_Input, element: 1) == 0.0,
        "vol zero"
    )
    atW10Expect(
        atW10FromLinear(1.0, unit: mixer, pid: kMultiChannelMixerParam_Enable, scope: kAudioUnitScope_Input, element: 0) == 1.0,
        "enable full"
    )
    atW10Expect(
        atW10FromLinear(0.25, unit: mixer, pid: kMultiChannelMixerParam_Pan, scope: kAudioUnitScope_Output, element: 0) == 0.25,
        "pan quarter"
    )
    // Apple does not clamp: the linear formula extrapolates.
    atW10Expect(
        atW10FromLinear(1.5, unit: mixer, pid: kMultiChannelMixerParam_Volume, scope: kAudioUnitScope_Input, element: 0) == 1.5,
        "above range"
    )
    atW10Expect(
        atW10FromLinear(-0.5, unit: mixer, pid: kMultiChannelMixerParam_Volume, scope: kAudioUnitScope_Input, element: 0) == -0.5,
        "below range"
    )
    // Unpublished parameters fail closed to 0 (Apple-oracle pinned).
    atW10Expect(
        atW10FromLinear(0.5, unit: mixer, pid: kMultiChannelMixerParam_Enable, scope: kAudioUnitScope_Output, element: 0) == 0.0,
        "output enable invalid"
    )
    atW10Expect(
        atW10FromLinear(0.5, unit: mixer, pid: kMultiChannelMixerParam_Volume, scope: kAudioUnitScope_Global, element: 0) == 0.0,
        "global invalid"
    )
    atW10Expect(
        atW10FromLinear(0.5, unit: nil, pid: kMultiChannelMixerParam_Volume, scope: kAudioUnitScope_Input, element: 0) == 0.0,
        "nil unit"
    )
    guard let generic = atW10GenericOutput() else {
        fatalError("generic")
    }
    atW10Expect(
        atW10FromLinear(0.5, unit: generic, pid: 0, scope: kAudioUnitScope_Global, element: 0) == 0.0,
        "generic output has no parameters"
    )
    atW10Expect(AudioComponentInstanceDispose(mixer) == 0, "dispose mixer")
    atW10Expect(AudioComponentInstanceDispose(generic) == 0, "dispose generic")
}

func testAUParameterValueToLinear() {
    guard let mixer = atW10Mixer() else {
        fatalError("mixer")
    }
    atW10Expect(
        atW10ToLinear(0.5, unit: mixer, pid: kMultiChannelMixerParam_Volume, scope: kAudioUnitScope_Input, element: 0) == 0.5,
        "vol half"
    )
    atW10Expect(
        atW10ToLinear(1.0, unit: mixer, pid: kMultiChannelMixerParam_Enable, scope: kAudioUnitScope_Input, element: 0) == 1.0,
        "enable full"
    )
    atW10Expect(
        atW10ToLinear(0.75, unit: mixer, pid: kMultiChannelMixerParam_Pan, scope: kAudioUnitScope_Output, element: 0) == 0.75,
        "pan output"
    )
    // Apple does not clamp the inverse either.
    atW10Expect(
        atW10ToLinear(2.0, unit: mixer, pid: kMultiChannelMixerParam_Volume, scope: kAudioUnitScope_Input, element: 0) == 2.0,
        "above range"
    )
    atW10Expect(
        atW10ToLinear(-1.0, unit: mixer, pid: kMultiChannelMixerParam_Volume, scope: kAudioUnitScope_Input, element: 0) == -1.0,
        "below range"
    )
    // Round trip through both directions is the identity on hosted units.
    let roundTrip = atW10ToLinear(
        atW10FromLinear(0.3, unit: mixer, pid: kMultiChannelMixerParam_Volume, scope: kAudioUnitScope_Input, element: 0),
        unit: mixer,
        pid: kMultiChannelMixerParam_Volume,
        scope: kAudioUnitScope_Input,
        element: 0
    )
    atW10Expect(roundTrip == 0.3, "round trip")
    // Unpublished parameters fail closed to 0 (Apple-oracle pinned).
    atW10Expect(
        atW10ToLinear(0.5, unit: mixer, pid: kMultiChannelMixerParam_Enable, scope: kAudioUnitScope_Output, element: 0) == 0.0,
        "output enable invalid"
    )
    atW10Expect(
        atW10ToLinear(0.5, unit: mixer, pid: 0, scope: kAudioUnitScope_Global, element: 0) == 0.0,
        "global invalid"
    )
    atW10Expect(
        atW10ToLinear(0.5, unit: nil, pid: kMultiChannelMixerParam_Volume, scope: kAudioUnitScope_Input, element: 0) == 0.0,
        "nil unit"
    )
    atW10Expect(AudioComponentInstanceDispose(mixer) == 0, "dispose mixer")
}

func testGetAudioUnitParameterDisplayType() {
    let readWrite: AudioUnitParameterOptions = [.flag_IsReadable, .flag_IsWritable]
    atW10Expect(GetAudioUnitParameterDisplayType([]) == [], "empty")
    atW10Expect(GetAudioUnitParameterDisplayType(readWrite) == [], "linear")
    atW10Expect(
        GetAudioUnitParameterDisplayType(.flag_DisplaySquared) == .flag_DisplaySquared,
        "squared"
    )
    atW10Expect(
        GetAudioUnitParameterDisplayType([.flag_IsReadable, .flag_DisplayCubed]) == .flag_DisplayCubed,
        "cubed with readable"
    )
    atW10Expect(
        GetAudioUnitParameterDisplayType([.flag_IsReadable, .flag_DisplayExponential, .flag_CanRamp])
            == .flag_DisplayExponential,
        "exponential keeps only display bits"
    )
}

func testSetAudioUnitParameterDisplayType() {
    let readWrite: AudioUnitParameterOptions = [.flag_IsReadable, .flag_IsWritable]
    atW10Expect(
        SetAudioUnitParameterDisplayType(readWrite, .flag_DisplayCubed)
            == [.flag_IsReadable, .flag_IsWritable, .flag_DisplayCubed],
        "set cubed"
    )
    atW10Expect(
        SetAudioUnitParameterDisplayType([.flag_IsReadable, .flag_DisplaySquared], .flag_DisplayLogarithmic)
            == [.flag_IsReadable, .flag_DisplayLogarithmic],
        "replace squared with logarithmic"
    )
    atW10Expect(
        SetAudioUnitParameterDisplayType([.flag_IsReadable, .flag_DisplaySquared], []) == [.flag_IsReadable],
        "clear display"
    )
    // Non-mask bits in displayType pass through (Apple-oracle pinned).
    atW10Expect(
        SetAudioUnitParameterDisplayType(readWrite, .flag_CanRamp)
            == [.flag_IsReadable, .flag_IsWritable, .flag_CanRamp],
        "extra bits pass through"
    )
    // Round trip: Set then Get recovers the display type.
    let applied = SetAudioUnitParameterDisplayType(readWrite, .flag_DisplaySquareRoot)
    atW10Expect(GetAudioUnitParameterDisplayType(applied) == .flag_DisplaySquareRoot, "round trip")
}
