import AudioToolbox

private func wave9Expect(_ condition: Bool, _ message: String) {
    if !condition { fatalError(message) }
}

func testWave9MeterAndUserEventRecords() {
    let meter = AudioUnitMeterClipping(peakValueSinceLastCall: -1.5, sawInfinity: 1, sawNotANumber: 0)
    wave9Expect(meter.peakValueSinceLastCall == -1.5 && meter.sawInfinity == 1 && meter.sawNotANumber == 0, "meter fields")
    wave9Expect(AudioUnitMeterClipping().peakValueSinceLastCall == 0, "meter zero init")
    let event = MusicEventUserData(length: 1, data: 0x7f)
    wave9Expect(event.length == 1 && event.data == 0x7f, "flexible data prefix")
    wave9Expect(MusicEventUserData().length == 0, "event zero init")
}

func testWave9PublicScalarAliases() {
    let channelCount: AUAudioChannelCount = 2
    let frameCount: AUAudioFrameCount = 512
    let sampleTime: AUEventSampleTime = -4
    let node: AUNode = -9
    let address: AUParameterAddress = 0x1234
    let value: AUValue = 0.5
    let element: AudioUnitElement = 3
    let parameter: AudioUnitParameterID = 4
    let property: AudioUnitPropertyID = 5
    let scope: AudioUnitScope = 6
    let fileProperty: AudioFilePropertyID = 7
    let fileType: AudioFileTypeID = 8
    let streamProperty: AudioFileStreamPropertyID = 9
    let formatProperty: AudioFormatPropertyID = 10
    let converterProperty: AudioConverterPropertyID = 11
    let queueParameter: AudioQueueParameterID = 12
    let queueProperty: AudioQueuePropertyID = 13
    let servicesProperty: AudioServicesPropertyID = 14
    let extProperty: ExtAudioFilePropertyID = 15
    let eventType: MusicEventType = 16
    let sound: SystemSoundID = 17
    let codecProperty: AudioCodecPropertyID = 18
    wave9Expect(channelCount == 2 && frameCount == 512 && sampleTime == -4 && node == -9, "AU aliases")
    wave9Expect(address == 0x1234 && value == 0.5 && element + parameter + property + scope == 18, "parameter aliases")
    wave9Expect(fileProperty + fileType + streamProperty + formatProperty == 34, "file aliases")
    wave9Expect(converterProperty + queueParameter + queueProperty + servicesProperty + extProperty + eventType + sound + codecProperty == 116, "framework aliases")

    let token = OpaquePointer(bitPattern: 0x1000)!
    let component: AudioComponent = token
    let unit: AudioUnit = token
    let codec: AudioCodec = token
    let converter: AudioConverterRef = token
    let stream: AudioFileStreamID = token
    let ext: ExtAudioFileRef = token
    let listener: AUParameterListenerRef = token
    let eventListener: AUEventListenerRef = token
    let method: AudioComponentMethod = token
    wave9Expect(component == unit && unit == codec && converter == stream && stream == ext, "opaque aliases")
    wave9Expect(listener == eventListener && method == component, "listener aliases")
}

func testWave9CallbackAliasInvocation() {
    let queue = OpaquePointer(bitPattern: 0x2000)!
    let output: AudioQueueOutputCallback = { userData, queue, buffer in
        wave9Expect(userData == nil && queue == OpaquePointer(bitPattern: 0x2000), "output callback arguments")
        wave9Expect(buffer.pointee.mAudioDataByteSize == 0, "output callback buffer")
    }
    let storage = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)
    defer { storage.deallocate() }
    var buffer = AudioQueueBuffer(mAudioDataBytesCapacity: 1, mAudioData: storage, mAudioDataByteSize: 0, mUserData: nil, mPacketDescriptionCapacity: 0, mPacketDescriptions: nil, mPacketDescriptionCount: 0)
    withUnsafeMutablePointer(to: &buffer) { output(nil, queue, $0) }
    let completion: AudioServicesSystemSoundCompletionProc = { sound, data in
        wave9Expect(sound == 41 && data == nil, "sound completion arguments")
    }
    completion(41, nil)
}

func testWave9ParameterClassIdentity() {
    let node: AUParameterNode = AUParameterNode()
    let parameter: AUParameter = AUParameter()
    parameter.identifier = "gain"
    parameter.minValue = -1
    parameter.maxValue = 1
    parameter.setValue(2, originator: nil)
    wave9Expect(node.displayName(withLength: 4).isEmpty, "node behavior")
    wave9Expect(parameter.identifier == "gain" && parameter.value == 1, "parameter class behavior")
}

func testWave9InputAndSessionAliases() {
    let property: AudioSessionPropertyID = 73
    let interruption: AudioSessionInterruptionType = 2
    wave9Expect(property == 73 && interruption == 2, "session scalar aliases")
    let listener: AudioSessionPropertyListener = { data, identifier, size, value in
        wave9Expect(data == nil && identifier == 73 && size == 4 && value == nil, "session listener arguments")
    }
    listener(nil, property, 4, nil)

    let queue = OpaquePointer(bitPattern: 0x3000)!
    let storage = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)
    defer { storage.deallocate() }
    var buffer = AudioQueueBuffer(mAudioDataBytesCapacity: 1, mAudioData: storage, mAudioDataByteSize: 0, mUserData: nil, mPacketDescriptionCapacity: 0, mPacketDescriptions: nil, mPacketDescriptionCount: 0)
    let input: AudioQueueInputCallback = { data, callbackQueue, callbackBuffer, startTime, packetCount, descriptions in
        wave9Expect(data == nil && callbackQueue == queue && callbackBuffer.pointee.mAudioDataByteSize == 0, "input callback identity")
        wave9Expect(startTime == nil && packetCount == 0 && descriptions == nil, "input callback metadata")
    }
    withUnsafeMutablePointer(to: &buffer) { input(nil, queue, $0, nil, 0, nil) }
}
