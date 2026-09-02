import CoreAudioTypes

func expect(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError("COREAUDIOTYPES_AGENT_RUNTIME_FAIL: \(message)")
    }
}

func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    expect(actual == expected, "\(message): \(actual) != \(expected)")
}

func layoutMatches<T>(
    _ type: T.Type,
    size: Int,
    stride: Int,
    alignment: Int,
    name: String
) {
    expectEqual(MemoryLayout<T>.size, size, "\(name) size")
    expectEqual(MemoryLayout<T>.stride, stride, "\(name) stride")
    expectEqual(MemoryLayout<T>.alignment, alignment, "\(name) alignment")
}

func proveAudioBufferLayout() {
    layoutMatches(AudioBuffer.self, size: 16, stride: 16, alignment: 8, name: "AudioBuffer")
    expectEqual(MemoryLayout<AudioBuffer>.offset(of: \.mNumberChannels), 0, "AudioBuffer.mNumberChannels")
    expectEqual(MemoryLayout<AudioBuffer>.offset(of: \.mDataByteSize), 4, "AudioBuffer.mDataByteSize")
    expectEqual(MemoryLayout<AudioBuffer>.offset(of: \.mData), 8, "AudioBuffer.mData")
    var zero = AudioBuffer()
    expectEqual(zero.mNumberChannels, 0, "AudioBuffer() channels")
    expectEqual(zero.mDataByteSize, 0, "AudioBuffer() size")
    expect(zero.mData == nil, "AudioBuffer() mData is nil and must not be dereferenced")
    zero = AudioBuffer(mNumberChannels: 2, mDataByteSize: 256, mData: nil)
    expectEqual(zero.mNumberChannels, 2, "AudioBuffer memberwise channels")
    expectEqual(zero.mDataByteSize, 256, "AudioBuffer memberwise size")
}

func proveAudioBufferListLayout() {
    layoutMatches(AudioBufferList.self, size: 24, stride: 24, alignment: 8, name: "AudioBufferList")
    expectEqual(MemoryLayout<AudioBufferList>.offset(of: \.mNumberBuffers), 0, "AudioBufferList.mNumberBuffers")
    expectEqual(MemoryLayout<AudioBufferList>.offset(of: \.mBuffers), 8, "AudioBufferList.mBuffers")
    let empty = AudioBufferList()
    expectEqual(empty.mNumberBuffers, 0, "AudioBufferList() count")
    let one = AudioBufferList(
        mNumberBuffers: 1,
        mBuffers: AudioBuffer(mNumberChannels: 1, mDataByteSize: 4, mData: nil)
    )
    expectEqual(one.mNumberBuffers, 1, "AudioBufferList memberwise count")
    expectEqual(one.mBuffers.mNumberChannels, 1, "embedded buffer channels")
}

func proveASBDLayout() {
    layoutMatches(
        AudioStreamBasicDescription.self,
        size: 40,
        stride: 40,
        alignment: 8,
        name: "AudioStreamBasicDescription"
    )
    expectEqual(MemoryLayout<AudioStreamBasicDescription>.offset(of: \.mSampleRate), 0, "mSampleRate")
    expectEqual(MemoryLayout<AudioStreamBasicDescription>.offset(of: \.mFormatID), 8, "mFormatID")
    expectEqual(MemoryLayout<AudioStreamBasicDescription>.offset(of: \.mFormatFlags), 12, "mFormatFlags")
    expectEqual(MemoryLayout<AudioStreamBasicDescription>.offset(of: \.mBytesPerPacket), 16, "mBytesPerPacket")
    expectEqual(MemoryLayout<AudioStreamBasicDescription>.offset(of: \.mFramesPerPacket), 20, "mFramesPerPacket")
    expectEqual(MemoryLayout<AudioStreamBasicDescription>.offset(of: \.mBytesPerFrame), 24, "mBytesPerFrame")
    expectEqual(MemoryLayout<AudioStreamBasicDescription>.offset(of: \.mChannelsPerFrame), 28, "mChannelsPerFrame")
    expectEqual(MemoryLayout<AudioStreamBasicDescription>.offset(of: \.mBitsPerChannel), 32, "mBitsPerChannel")
    expectEqual(MemoryLayout<AudioStreamBasicDescription>.offset(of: \.mReserved), 36, "mReserved")
    var asbd = AudioStreamBasicDescription()
    asbd.mSampleRate = 44100
    asbd.mFormatID = kAudioFormatLinearPCM
    asbd.mChannelsPerFrame = 2
    expectEqual(asbd.mSampleRate, 44100, "ASBD sample rate")
    expectEqual(asbd.mChannelsPerFrame, 2, "ASBD channels")
}

func provePacketDescriptionLayout() {
    layoutMatches(
        AudioStreamPacketDescription.self,
        size: 16,
        stride: 16,
        alignment: 8,
        name: "AudioStreamPacketDescription"
    )
    expectEqual(MemoryLayout<AudioStreamPacketDescription>.offset(of: \.mStartOffset), 0, "mStartOffset")
    expectEqual(
        MemoryLayout<AudioStreamPacketDescription>.offset(of: \.mVariableFramesInPacket),
        8,
        "mVariableFramesInPacket"
    )
    expectEqual(MemoryLayout<AudioStreamPacketDescription>.offset(of: \.mDataByteSize), 12, "packet mDataByteSize")
}

func provePacketDependencyLayout() {
    layoutMatches(
        AudioStreamPacketDependencyDescription.self,
        size: 16,
        stride: 16,
        alignment: 4,
        name: "AudioStreamPacketDependencyDescription"
    )
    expectEqual(
        MemoryLayout<AudioStreamPacketDependencyDescription>.offset(of: \.mIsIndependentlyDecodable),
        0,
        "mIsIndependentlyDecodable"
    )
    expectEqual(MemoryLayout<AudioStreamPacketDependencyDescription>.offset(of: \.mPreRollCount), 4, "mPreRollCount")
    expectEqual(MemoryLayout<AudioStreamPacketDependencyDescription>.offset(of: \.mFlags), 8, "dep mFlags")
    expectEqual(MemoryLayout<AudioStreamPacketDependencyDescription>.offset(of: \.mReserved), 12, "dep mReserved")
}

func proveSMPTETimeLayout() {
    layoutMatches(SMPTETime.self, size: 24, stride: 24, alignment: 4, name: "SMPTETime")
    expectEqual(MemoryLayout<SMPTETime>.offset(of: \.mSubframes), 0, "mSubframes")
    expectEqual(MemoryLayout<SMPTETime>.offset(of: \.mSubframeDivisor), 2, "mSubframeDivisor")
    expectEqual(MemoryLayout<SMPTETime>.offset(of: \.mCounter), 4, "mCounter")
    expectEqual(MemoryLayout<SMPTETime>.offset(of: \.mType), 8, "SMPTE mType")
    expectEqual(MemoryLayout<SMPTETime>.offset(of: \.mFlags), 12, "SMPTE mFlags")
    expectEqual(MemoryLayout<SMPTETime>.offset(of: \.mHours), 16, "mHours")
    expectEqual(MemoryLayout<SMPTETime>.offset(of: \.mMinutes), 18, "mMinutes")
    expectEqual(MemoryLayout<SMPTETime>.offset(of: \.mSeconds), 20, "mSeconds")
    expectEqual(MemoryLayout<SMPTETime>.offset(of: \.mFrames), 22, "mFrames")
    let smpte = SMPTETime()
    expectEqual(smpte.mType, SMPTETimeType.type24, "zero SMPTE type")
    expect(smpte.mFlags.isEmpty, "zero SMPTE flags")
}

func proveAudioTimeStampLayout() {
    layoutMatches(AudioTimeStamp.self, size: 64, stride: 64, alignment: 8, name: "AudioTimeStamp")
    expectEqual(MemoryLayout<AudioTimeStamp>.offset(of: \.mSampleTime), 0, "mSampleTime")
    expectEqual(MemoryLayout<AudioTimeStamp>.offset(of: \.mHostTime), 8, "mHostTime")
    expectEqual(MemoryLayout<AudioTimeStamp>.offset(of: \.mRateScalar), 16, "mRateScalar")
    expectEqual(MemoryLayout<AudioTimeStamp>.offset(of: \.mWordClockTime), 24, "mWordClockTime")
    expectEqual(MemoryLayout<AudioTimeStamp>.offset(of: \.mSMPTETime), 32, "mSMPTETime")
    expectEqual(MemoryLayout<AudioTimeStamp>.offset(of: \.mFlags), 56, "ts mFlags")
    expectEqual(MemoryLayout<AudioTimeStamp>.offset(of: \.mReserved), 60, "ts mReserved")
}

func proveChannelDescriptionLayout() {
    layoutMatches(
        AudioChannelDescription.self,
        size: 20,
        stride: 20,
        alignment: 4,
        name: "AudioChannelDescription"
    )
    expectEqual(MemoryLayout<AudioChannelDescription>.offset(of: \.mChannelLabel), 0, "mChannelLabel")
    expectEqual(MemoryLayout<AudioChannelDescription>.offset(of: \.mChannelFlags), 4, "mChannelFlags")
    expectEqual(MemoryLayout<AudioChannelDescription>.offset(of: \.mCoordinates), 8, "mCoordinates")
    expectEqual(MemoryLayout<(Float32, Float32, Float32)>.size, 12, "coordinate tuple size")
}

func proveChannelLayoutLayout() {
    layoutMatches(AudioChannelLayout.self, size: 32, stride: 32, alignment: 4, name: "AudioChannelLayout")
    expectEqual(MemoryLayout<AudioChannelLayout>.offset(of: \.mChannelLayoutTag), 0, "mChannelLayoutTag")
    expectEqual(MemoryLayout<AudioChannelLayout>.offset(of: \.mChannelBitmap), 4, "mChannelBitmap")
    expectEqual(
        MemoryLayout<AudioChannelLayout>.offset(of: \.mNumberChannelDescriptions),
        8,
        "mNumberChannelDescriptions"
    )
    expectEqual(
        MemoryLayout<AudioChannelLayout>.offset(of: \.mChannelDescriptions),
        12,
        "mChannelDescriptions"
    )
}

func proveRemainingStructLayouts() {
    layoutMatches(AudioClassDescription.self, size: 12, stride: 12, alignment: 4, name: "AudioClassDescription")
    expectEqual(MemoryLayout<AudioClassDescription>.offset(of: \.mType), 0, "class mType")
    expectEqual(MemoryLayout<AudioClassDescription>.offset(of: \.mSubType), 4, "mSubType")
    expectEqual(MemoryLayout<AudioClassDescription>.offset(of: \.mManufacturer), 8, "mManufacturer")

    layoutMatches(AudioFormatListItem.self, size: 44, stride: 48, alignment: 8, name: "AudioFormatListItem")
    expectEqual(MemoryLayout<AudioFormatListItem>.offset(of: \.mASBD), 0, "mASBD")
    expectEqual(MemoryLayout<AudioFormatListItem>.offset(of: \.mChannelLayoutTag), 40, "format list tag")

    layoutMatches(AudioValueRange.self, size: 16, stride: 16, alignment: 8, name: "AudioValueRange")
    expectEqual(MemoryLayout<AudioValueRange>.offset(of: \.mMinimum), 0, "mMinimum")
    expectEqual(MemoryLayout<AudioValueRange>.offset(of: \.mMaximum), 8, "mMaximum")

    layoutMatches(AudioValueTranslation.self, size: 28, stride: 32, alignment: 8, name: "AudioValueTranslation")
    expectEqual(MemoryLayout<AudioValueTranslation>.offset(of: \.mInputData), 0, "mInputData")
    expectEqual(MemoryLayout<AudioValueTranslation>.offset(of: \.mInputDataSize), 8, "mInputDataSize")
    expectEqual(MemoryLayout<AudioValueTranslation>.offset(of: \.mOutputData), 16, "mOutputData")
    expectEqual(MemoryLayout<AudioValueTranslation>.offset(of: \.mOutputDataSize), 24, "mOutputDataSize")
}

func flexibleByteCount(leadingOffset: Int, elementStride: Int, count: Int) -> Int? {
    if count < 0 {
        return nil
    }
    let (product, productOverflow) = elementStride.multipliedReportingOverflow(by: count)
    if productOverflow {
        return nil
    }
    let (total, totalOverflow) = leadingOffset.addingReportingOverflow(product)
    if totalOverflow {
        return nil
    }
    return total
}

func proveFlexibleArrayFormulas() {
    let bufferLead = MemoryLayout<AudioBufferList>.offset(of: \.mBuffers)!
    let bufferStride = MemoryLayout<AudioBuffer>.stride
    expectEqual(bufferLead, 8, "buffer leading offset")
    expectEqual(bufferStride, 16, "buffer stride")
    expectEqual(flexibleByteCount(leadingOffset: bufferLead, elementStride: bufferStride, count: 0), 8, "zero buffers")
    expectEqual(flexibleByteCount(leadingOffset: bufferLead, elementStride: bufferStride, count: 1), 24, "one buffer")
    expectEqual(flexibleByteCount(leadingOffset: bufferLead, elementStride: bufferStride, count: 4), 72, "four buffers")
    expect(flexibleByteCount(leadingOffset: bufferLead, elementStride: bufferStride, count: -1) == nil, "negative buffers")
    let maxSafe = (Int.max - bufferLead) / bufferStride
    expect(
        flexibleByteCount(leadingOffset: bufferLead, elementStride: bufferStride, count: maxSafe) != nil,
        "maximal-safe buffer count"
    )
    expect(
        flexibleByteCount(leadingOffset: bufferLead, elementStride: bufferStride, count: maxSafe + 1) == nil,
        "overflow buffer count"
    )

    let channelLead = MemoryLayout<AudioChannelLayout>.offset(of: \.mChannelDescriptions)!
    let channelStride = MemoryLayout<AudioChannelDescription>.stride
    expectEqual(channelLead, 12, "channel leading offset")
    expectEqual(channelStride, 20, "channel description stride")
    expectEqual(
        flexibleByteCount(leadingOffset: channelLead, elementStride: channelStride, count: 0),
        12,
        "zero descriptions"
    )
    expectEqual(
        flexibleByteCount(leadingOffset: channelLead, elementStride: channelStride, count: 1),
        32,
        "one description"
    )
    expectEqual(
        flexibleByteCount(leadingOffset: channelLead, elementStride: channelStride, count: 4),
        92,
        "four descriptions"
    )
}

func proveBufferPointerWalk() {
    let count = 4
    let lead = MemoryLayout<AudioBufferList>.offset(of: \.mBuffers)!
    let stride = MemoryLayout<AudioBuffer>.stride
    let bytes = lead + stride * count
    let raw = UnsafeMutableRawPointer.allocate(
        byteCount: bytes,
        alignment: MemoryLayout<AudioBufferList>.alignment
    )
    defer { raw.deallocate() }
    raw.initializeMemory(as: UInt8.self, repeating: 0, count: bytes)
    let list = raw.assumingMemoryBound(to: AudioBufferList.self)
    list.pointee.mNumberBuffers = UInt32(count)
    for index in 0..<count {
        let buffer = raw.advanced(by: lead + stride * index).assumingMemoryBound(to: AudioBuffer.self)
        buffer.pointee = AudioBuffer(
            mNumberChannels: UInt32(index + 1),
            mDataByteSize: UInt32(index * 16),
            mData: nil
        )
    }
    expectEqual(list.pointee.mNumberBuffers, 4, "walk count")
    expectEqual(list.pointee.mBuffers.mNumberChannels, 1, "first embedded buffer")
    for index in 0..<count {
        let buffer = raw.advanced(by: lead + stride * index).assumingMemoryBound(to: AudioBuffer.self)
        expectEqual(buffer.pointee.mNumberChannels, UInt32(index + 1), "walked buffer \(index)")
        expect(buffer.pointee.mData == nil, "walked buffer mData stays nil")
    }
}

func proveChannelPointerWalk() {
    let count = 4
    let lead = MemoryLayout<AudioChannelLayout>.offset(of: \.mChannelDescriptions)!
    let stride = MemoryLayout<AudioChannelDescription>.stride
    let bytes = lead + stride * count
    let raw = UnsafeMutableRawPointer.allocate(
        byteCount: bytes,
        alignment: MemoryLayout<AudioChannelLayout>.alignment
    )
    defer { raw.deallocate() }
    raw.initializeMemory(as: UInt8.self, repeating: 0, count: bytes)
    let layout = raw.assumingMemoryBound(to: AudioChannelLayout.self)
    layout.pointee.mNumberChannelDescriptions = UInt32(count)
    layout.pointee.mChannelLayoutTag = kAudioChannelLayoutTag_UseChannelDescriptions
    for index in 0..<count {
        let description = raw.advanced(by: lead + stride * index)
            .assumingMemoryBound(to: AudioChannelDescription.self)
        description.pointee = AudioChannelDescription(
            mChannelLabel: AudioChannelLabel(index + 1),
            mChannelFlags: .rectangularCoordinates,
            mCoordinates: (Float32(index), Float32(index) + 0.5, -1)
        )
    }
    expectEqual(layout.pointee.mChannelDescriptions.mChannelLabel, 1, "first embedded description")
    for index in 0..<count {
        let description = raw.advanced(by: lead + stride * index)
            .assumingMemoryBound(to: AudioChannelDescription.self)
        expectEqual(description.pointee.mChannelLabel, AudioChannelLabel(index + 1), "walked description \(index)")
        expectEqual(description.pointee.mCoordinates.0, Float32(index), "coordinate x \(index)")
    }
}

func proveOptionSets() {
    let emptyBits = AudioChannelBitmap()
    expect(emptyBits.isEmpty, "empty bitmap")
    let stereo: AudioChannelBitmap = [.bit_Left, .bit_Right]
    expect(stereo.contains(.bit_Left), "stereo left")
    expect(stereo.contains(.bit_Right), "stereo right")
    expect(!stereo.contains(.bit_Center), "stereo not center")
    expectEqual(stereo.union(.bit_Center).intersection(.bit_Center), .bit_Center, "bitmap union/intersection")
    expect(stereo != .bit_Left, "bitmap !=")
    var mutable = AudioChannelBitmap(rawValue: 0)
    _ = mutable.insert(.bit_LFEScreen)
    expect(mutable.contains(.bit_LFEScreen), "insert LFE")
    _ = mutable.remove(.bit_LFEScreen)
    expect(!mutable.contains(.bit_LFEScreen), "remove LFE")
    expectEqual(
        AudioChannelBitmap(rawValue: 0x5).rawValue,
        0x5,
        "bitmap raw-value round trip"
    )

    let flags: AudioChannelFlags = [.rectangularCoordinates, .meters]
    expect(flags.contains(.rectangularCoordinates), "rect")
    expect(flags.contains(.meters), "meters")
    expect(!flags.contains(.sphericalCoordinates), "not spherical")
    expectEqual(AudioChannelFlags(rawValue: flags.rawValue), flags, "channel flags round trip")

    var timestampFlags: AudioTimeStampFlags = [.sampleTimeValid]
    timestampFlags.formUnion(.hostTimeValid)
    expectEqual(timestampFlags, .sampleHostTimeValid, "sampleHostTimeValid is the sample+host union")
    expect(timestampFlags.contains(.sampleTimeValid) && timestampFlags.contains(.hostTimeValid), "both valid")
    expectEqual(
        AudioTimeStampFlags.sampleTimeValid.union(.rateScalarValid).symmetricDifference(.rateScalarValid),
        .sampleTimeValid,
        "timestamp flags symmetric difference"
    )
    expectEqual(AudioTimeStampFlags(rawValue: 0x15).rawValue, 0x15, "timestamp flags round trip")

    let smpte: SMPTETimeFlags = [.valid, .running]
    expect(smpte.contains(.valid) && smpte.contains(.running), "smpte flags")
    expectEqual(SMPTETimeFlags(rawValue: smpte.rawValue), smpte, "smpte flags round trip")
    expect(!SMPTETimeFlags().contains(.valid), "empty smpte flags")
}

func proveEnums() {
    expectEqual(MemoryLayout<AudioChannelCoordinateIndex>.stride, 4, "coordinate index stride")
    expectEqual(MemoryLayout<AudioChannelCoordinateIndex>.alignment, 4, "coordinate index alignment")
    expectEqual(MemoryLayout<SMPTETimeType>.stride, 4, "SMPTE type stride")
    expectEqual(MemoryLayout<SMPTETimeType>.alignment, 4, "SMPTE type alignment")
    expectEqual(MemoryLayout<MPEG4ObjectID>.stride, 8, "MPEG object stride")
    expectEqual(MemoryLayout<MPEG4ObjectID>.alignment, 8, "MPEG object alignment")
    expectEqual(AudioChannelCoordinateIndex.coordinates_Azimuth, .coordinates_LeftRight, "azimuth alias")
    expectEqual(AudioChannelCoordinateIndex.coordinates_Elevation, .coordinates_BackFront, "elevation alias")
    expectEqual(AudioChannelCoordinateIndex.coordinates_Distance, .coordinates_DownUp, "distance alias")
    expect(AudioChannelCoordinateIndex(rawValue: 0) == .coordinates_LeftRight, "coordinate raw 0")
    expect(SMPTETimeType(rawValue: 0) == .type24, "SMPTE 0")
    expect(SMPTETimeType.type25 != .type24, "SMPTE !=")
    expect(MPEG4ObjectID.AAC_LC != .aac_Main, "MPEG4 distinct")
    expect(MPEG4ObjectID(rawValue: 2) == .AAC_LC, "MPEG4 LC raw")
    let hashed = Set([SMPTETimeType.type24, .type24, .type30])
    expectEqual(hashed.count, 2, "SMPTETimeType Hashable")
    expectEqual(Set([MPEG4ObjectID.AAC_LC, .AAC_LC, .CELP]).count, 2, "MPEG4ObjectID Hashable")
    expectEqual(
        Set([AudioChannelCoordinateIndex.coordinates_LeftRight, .coordinates_Azimuth, .coordinates_DownUp]).count,
        2,
        "coordinate Hashable aliases"
    )
    expectEqual(AVAudioSessionErrorInsufficientPriority, 561017449, "insufficient priority global")
}

func proveTypealiasesAndFunction() {
    expectEqual(MemoryLayout<AudioChannelLabel>.size, 4, "AudioChannelLabel")
    expectEqual(MemoryLayout<AudioChannelLayoutTag>.size, 4, "AudioChannelLayoutTag")
    expectEqual(MemoryLayout<AudioFormatID>.size, 4, "AudioFormatID")
    expectEqual(MemoryLayout<AudioFormatFlags>.size, 4, "AudioFormatFlags")
    expectEqual(MemoryLayout<AudioSampleType>.size, 2, "AudioSampleType")
    expectEqual(MemoryLayout<AudioUnitSampleType>.size, 4, "AudioUnitSampleType")
    expectEqual(MemoryLayout<AudioSessionID>.size, 4, "AudioSessionID")
    expectEqual(MemoryLayout<AVAudioInteger>.size, MemoryLayout<Int>.size, "AVAudioInteger")
    expectEqual(MemoryLayout<AVAudioUInteger>.size, MemoryLayout<UInt>.size, "AVAudioUInteger")
    expectEqual(
        AudioChannelLayoutTag_GetNumberOfChannels(kAudioChannelLayoutTag_Mono),
        1,
        "mono channel count"
    )
    expectEqual(
        AudioChannelLayoutTag_GetNumberOfChannels(kAudioChannelLayoutTag_Stereo),
        2,
        "stereo channel count"
    )
    expectEqual(
        AudioChannelLayoutTag_GetNumberOfChannels(kAudioChannelLayoutTag_UseChannelDescriptions),
        0,
        "use descriptions count"
    )
    let packed: AudioChannelLayoutTag = (200 << 16) | 12
    expectEqual(AudioChannelLayoutTag_GetNumberOfChannels(packed), 12, "packed 12")
}

func proveTranslationWithoutNil() {
    var input: UInt32 = 0xAABBCCDD
    var output: UInt32 = 0
    withUnsafeMutableBytes(of: &input) { inputBytes in
        withUnsafeMutableBytes(of: &output) { outputBytes in
            let translation = AudioValueTranslation(
                mInputData: inputBytes.baseAddress!,
                mInputDataSize: 4,
                mOutputData: outputBytes.baseAddress!,
                mOutputDataSize: 4
            )
            expectEqual(translation.mInputDataSize, 4, "input size")
            expectEqual(translation.mOutputDataSize, 4, "output size")
            expect(translation.mInputData != translation.mOutputData, "distinct pointers")
        }
    }
}

func proveDeclaredConstantsExist() {
    expect(kAudioFormatLinearPCM != kAudioFormatMPEG4AAC, "format IDs distinct")
    expect(kAudioFormatFlagIsFloat != kAudioFormatFlagIsPacked, "format flags distinct")
    expect(kAudioChannelLabel_Left != kAudioChannelLabel_Right, "labels distinct")
    expect(kAudioChannelLabel_Unknown != kAudioChannelLabel_Unused, "unknown vs unused")
    expect(kAudio_NoError == 0, "no error")
    expect(kAudioStreamAnyRate == 0, "any rate")
    expect(CA_PREFER_FIXED_POINT == 1, "Apple fixed-point preference")
    expect(COREAUDIOTYPES_VERSION == 20211130, "CoreAudioTypes version")
}

proveAudioBufferLayout()
proveAudioBufferListLayout()
proveASBDLayout()
provePacketDescriptionLayout()
provePacketDependencyLayout()
proveSMPTETimeLayout()
proveAudioTimeStampLayout()
proveChannelDescriptionLayout()
proveChannelLayoutLayout()
proveRemainingStructLayouts()
proveFlexibleArrayFormulas()
proveBufferPointerWalk()
proveChannelPointerWalk()
proveOptionSets()
proveEnums()
proveTypealiasesAndFunction()
proveTranslationWithoutNil()
proveDeclaredConstantsExist()

print(
    "TRAIL buffer_stride=\(MemoryLayout<AudioBuffer>.stride) "
        + "channel_desc_stride=\(MemoryLayout<AudioChannelDescription>.stride) "
        + "extra_buffers_4=\(MemoryLayout<AudioBufferList>.offset(of: \.mBuffers)! + 4 * MemoryLayout<AudioBuffer>.stride) "
        + "extra_channels_4=\(MemoryLayout<AudioChannelLayout>.offset(of: \.mChannelDescriptions)! + 4 * MemoryLayout<AudioChannelDescription>.stride)"
)
print("COREAUDIOTYPES_AGENT_RUNTIME_OK")
