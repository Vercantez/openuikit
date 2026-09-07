import AudioToolbox
#if canImport(CoreFoundation)
import CoreFoundation
#endif

private func wave8Expect(_ condition: Bool, _ message: String) {
    if !condition { fatalError(message) }
}

func testAUNodeRenderCallbackRecord() {
    let callback = AURenderCallbackStruct()
    let value = AUNodeRenderCallback(destNode: -7, destInputNumber: 3, cback: callback)
    wave8Expect(value.destNode == -7 && value.destInputNumber == 3, "node callback fields")
    wave8Expect(value.cback.inputProc == nil, "node callback payload")
    let zero = AUNodeRenderCallback()
    wave8Expect(zero.destNode == 0 && zero.destInputNumber == 0, "node callback zero init")
}

func testAudioUnitConnectionRecord() {
    let token = OpaquePointer(bitPattern: 0x1234)
    let value = AudioUnitConnection(sourceAudioUnit: token, sourceOutputNumber: 5, destInputNumber: 9)
    wave8Expect(value.sourceAudioUnit == token, "connection unit")
    wave8Expect(value.sourceOutputNumber == 5 && value.destInputNumber == 9, "connection fields")
    let zero = AudioUnitConnection()
    wave8Expect(zero.sourceAudioUnit == nil && zero.sourceOutputNumber == 0, "connection zero init")
}

func testAudioUnitPropertyRecord() {
    let token = OpaquePointer(bitPattern: 0x4321)!
    let value = AudioUnitProperty(mAudioUnit: token, mPropertyID: 11, mScope: 12, mElement: 13)
    wave8Expect(value.mAudioUnit == token && value.mPropertyID == 11, "property identity")
    wave8Expect(value.mScope == 12 && value.mElement == 13, "property addressing")
}

func testMixerDistanceParamsRecord() {
    let value = MixerDistanceParams(mReferenceDistance: 1.25, mMaxDistance: 50, mMaxAttenuation: -24)
    wave8Expect(value.mReferenceDistance == 1.25, "reference distance")
    wave8Expect(value.mMaxDistance == 50 && value.mMaxAttenuation == -24, "distance fields")
    let zero = MixerDistanceParams()
    wave8Expect(zero.mReferenceDistance == 0 && zero.mMaxDistance == 0, "distance zero init")
}

func testNoteParamsControlValueRecord() {
    let value = NoteParamsControlValue(mID: 99, mValue: -0.5)
    wave8Expect(value.mID == 99 && value.mValue == -0.5, "control fields")
    let zero = NoteParamsControlValue()
    wave8Expect(zero.mID == 0 && zero.mValue == 0, "control zero init")
}

func testAudioUnitExternalBufferRecord() {
    var bytes: [UInt8] = [1, 2, 3]
    bytes.withUnsafeMutableBufferPointer { pointer in
        let value = AudioUnitExternalBuffer(buffer: pointer.baseAddress!, size: UInt32(pointer.count))
        wave8Expect(value.size == 3 && value.buffer[1] == 2, "external buffer preserves borrowed storage")
        value.buffer[2] = 8
    }
    wave8Expect(bytes == [1, 2, 8], "external buffer mutation")
}

func testExtendedTempoEventRecord() {
    let value = ExtendedTempoEvent(bpm: 123.5)
    wave8Expect(value.bpm == 123.5, "tempo field")
    wave8Expect(ExtendedTempoEvent().bpm == 0, "tempo zero init")
}

func testMusicTrackLoopInfoRecord() {
    let value = MusicTrackLoopInfo(loopDuration: 7.25, numberOfLoops: -1)
    wave8Expect(value.loopDuration == 7.25 && value.numberOfLoops == -1, "loop fields")
    let zero = MusicTrackLoopInfo()
    wave8Expect(zero.loopDuration == 0 && zero.numberOfLoops == 0, "loop zero init")
}

#if canImport(CoreFoundation)
func testAUPresetEventRecord() {
    let propertyList: CFPropertyList = CFStringCreateWithCString(nil, "wave8", CFStringBuiltInEncodings.UTF8.rawValue)
    let unmanaged = Unmanaged.passUnretained(propertyList)
    let value = AUPresetEvent(scope: 4, element: 2, preset: unmanaged)
    wave8Expect(value.scope == 4 && value.element == 2, "preset addressing")
    wave8Expect(CFEqual(value.preset.takeUnretainedValue(), propertyList), "preset payload")
}
#endif
