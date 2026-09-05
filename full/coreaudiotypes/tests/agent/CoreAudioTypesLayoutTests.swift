import CoreAudioTypes

private func require(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError("COREAUDIOTYPES_TEST_FAIL: \(message)")
    }
}

private func requireEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    require(actual == expected, "\(message): \(actual) != \(expected)")
}

private func layoutMatches<T>(
    _ type: T.Type,
    size: Int,
    stride: Int,
    alignment: Int,
    name: String
) {
    requireEqual(MemoryLayout<T>.size, size, "\(name) size")
    requireEqual(MemoryLayout<T>.stride, stride, "\(name) stride")
    requireEqual(MemoryLayout<T>.alignment, alignment, "\(name) alignment")
}

func testAudioBufferLayout() {
    layoutMatches(AudioBuffer.self, size: 16, stride: 16, alignment: 8, name: "AudioBuffer")
    requireEqual(MemoryLayout<AudioBuffer>.offset(of: \.mNumberChannels), 0, "mNumberChannels")
    requireEqual(MemoryLayout<AudioBuffer>.offset(of: \.mDataByteSize), 4, "mDataByteSize")
    requireEqual(MemoryLayout<AudioBuffer>.offset(of: \.mData), 8, "mData")
    let zero = AudioBuffer()
    requireEqual(zero.mNumberChannels, 0, "empty channels")
    requireEqual(zero.mDataByteSize, 0, "empty size")
    require(zero.mData == nil, "empty mData stays nil")
    let filled = AudioBuffer(mNumberChannels: 2, mDataByteSize: 256, mData: nil)
    requireEqual(filled.mNumberChannels, 2, "memberwise channels")
    requireEqual(filled.mDataByteSize, 256, "memberwise size")
    require(filled.mData == nil, "memberwise mData stays nil")
}

func testAudioBufferListLayout() {
    layoutMatches(AudioBufferList.self, size: 24, stride: 24, alignment: 8, name: "AudioBufferList")
    requireEqual(MemoryLayout<AudioBufferList>.offset(of: \.mNumberBuffers), 0, "mNumberBuffers")
    requireEqual(MemoryLayout<AudioBufferList>.offset(of: \.mBuffers), 8, "mBuffers")
    let empty = AudioBufferList()
    requireEqual(empty.mNumberBuffers, 0, "empty count")
    let one = AudioBufferList(
        mNumberBuffers: 1,
        mBuffers: AudioBuffer(mNumberChannels: 1, mDataByteSize: 4, mData: nil)
    )
    requireEqual(one.mNumberBuffers, 1, "memberwise count")
    requireEqual(one.mBuffers.mNumberChannels, 1, "embedded buffer channels")
    requireEqual(one.mBuffers.mDataByteSize, 4, "embedded buffer size")
}

func testAudioChannelDescriptionLayout() {
    layoutMatches(
        AudioChannelDescription.self,
        size: 20,
        stride: 20,
        alignment: 4,
        name: "AudioChannelDescription"
    )
    requireEqual(MemoryLayout<AudioChannelDescription>.offset(of: \.mChannelLabel), 0, "mChannelLabel")
    requireEqual(MemoryLayout<AudioChannelDescription>.offset(of: \.mChannelFlags), 4, "mChannelFlags")
    requireEqual(MemoryLayout<AudioChannelDescription>.offset(of: \.mCoordinates), 8, "mCoordinates")
    let zero = AudioChannelDescription()
    requireEqual(zero.mChannelLabel, 0, "empty label")
    require(zero.mChannelFlags.isEmpty, "empty flags")
    requireEqual(zero.mCoordinates.0, 0, "empty x")
    requireEqual(zero.mCoordinates.1, 0, "empty y")
    requireEqual(zero.mCoordinates.2, 0, "empty z")
    let filled = AudioChannelDescription(
        mChannelLabel: kAudioChannelLabel_Left,
        mChannelFlags: .rectangularCoordinates,
        mCoordinates: (1, 2, 3)
    )
    requireEqual(filled.mChannelLabel, kAudioChannelLabel_Left, "memberwise label")
    require(filled.mChannelFlags.contains(.rectangularCoordinates), "memberwise flags")
    requireEqual(filled.mCoordinates.0, 1, "memberwise x")
    requireEqual(filled.mCoordinates.1, 2, "memberwise y")
    requireEqual(filled.mCoordinates.2, 3, "memberwise z")
}

func testAudioChannelLayoutLayout() {
    layoutMatches(AudioChannelLayout.self, size: 32, stride: 32, alignment: 4, name: "AudioChannelLayout")
    requireEqual(MemoryLayout<AudioChannelLayout>.offset(of: \.mChannelLayoutTag), 0, "mChannelLayoutTag")
    requireEqual(MemoryLayout<AudioChannelLayout>.offset(of: \.mChannelBitmap), 4, "mChannelBitmap")
    requireEqual(
        MemoryLayout<AudioChannelLayout>.offset(of: \.mNumberChannelDescriptions),
        8,
        "mNumberChannelDescriptions"
    )
    requireEqual(
        MemoryLayout<AudioChannelLayout>.offset(of: \.mChannelDescriptions),
        12,
        "mChannelDescriptions"
    )
    let empty = AudioChannelLayout()
    requireEqual(empty.mChannelLayoutTag, 0, "empty tag")
    require(empty.mChannelBitmap.isEmpty, "empty bitmap")
    requireEqual(empty.mNumberChannelDescriptions, 0, "empty description count")
    let filled = AudioChannelLayout(
        mChannelLayoutTag: kAudioChannelLayoutTag_Stereo,
        mChannelBitmap: [.bit_Left, .bit_Right],
        mNumberChannelDescriptions: 1,
        mChannelDescriptions: AudioChannelDescription(
            mChannelLabel: kAudioChannelLabel_Left,
            mChannelFlags: [],
            mCoordinates: (0, 0, 0)
        )
    )
    requireEqual(filled.mChannelLayoutTag, kAudioChannelLayoutTag_Stereo, "memberwise tag")
    require(filled.mChannelBitmap.contains(.bit_Left), "memberwise bitmap")
    requireEqual(filled.mNumberChannelDescriptions, 1, "memberwise count")
    requireEqual(filled.mChannelDescriptions.mChannelLabel, kAudioChannelLabel_Left, "embedded label")
}

func testAudioClassDescriptionLayout() {
    layoutMatches(AudioClassDescription.self, size: 12, stride: 12, alignment: 4, name: "AudioClassDescription")
    requireEqual(MemoryLayout<AudioClassDescription>.offset(of: \.mType), 0, "mType")
    requireEqual(MemoryLayout<AudioClassDescription>.offset(of: \.mSubType), 4, "mSubType")
    requireEqual(MemoryLayout<AudioClassDescription>.offset(of: \.mManufacturer), 8, "mManufacturer")
    let empty = AudioClassDescription()
    requireEqual(empty.mType, 0, "empty type")
    requireEqual(empty.mSubType, 0, "empty subtype")
    requireEqual(empty.mManufacturer, 0, "empty manufacturer")
    let filled = AudioClassDescription(mType: 1, mSubType: 2, mManufacturer: 3)
    requireEqual(filled.mType, 1, "memberwise type")
    requireEqual(filled.mSubType, 2, "memberwise subtype")
    requireEqual(filled.mManufacturer, 3, "memberwise manufacturer")
}

func testAudioFormatListItemLayout() {
    layoutMatches(AudioFormatListItem.self, size: 44, stride: 48, alignment: 8, name: "AudioFormatListItem")
    requireEqual(MemoryLayout<AudioFormatListItem>.offset(of: \.mASBD), 0, "mASBD")
    requireEqual(MemoryLayout<AudioFormatListItem>.offset(of: \.mChannelLayoutTag), 40, "mChannelLayoutTag")
    let empty = AudioFormatListItem()
    requireEqual(empty.mASBD.mSampleRate, 0, "empty asbd")
    requireEqual(empty.mChannelLayoutTag, 0, "empty tag")
    var asbd = AudioStreamBasicDescription()
    asbd.mSampleRate = 48000
    asbd.mFormatID = kAudioFormatLinearPCM
    let filled = AudioFormatListItem(mASBD: asbd, mChannelLayoutTag: kAudioChannelLayoutTag_Mono)
    requireEqual(filled.mASBD.mSampleRate, 48000, "memberwise sample rate")
    requireEqual(filled.mASBD.mFormatID, kAudioFormatLinearPCM, "memberwise format")
    requireEqual(filled.mChannelLayoutTag, kAudioChannelLayoutTag_Mono, "memberwise tag")
}

func testAudioStreamBasicDescriptionLayout() {
    layoutMatches(
        AudioStreamBasicDescription.self,
        size: 40,
        stride: 40,
        alignment: 8,
        name: "AudioStreamBasicDescription"
    )
    requireEqual(MemoryLayout<AudioStreamBasicDescription>.offset(of: \.mSampleRate), 0, "mSampleRate")
    requireEqual(MemoryLayout<AudioStreamBasicDescription>.offset(of: \.mFormatID), 8, "mFormatID")
    requireEqual(MemoryLayout<AudioStreamBasicDescription>.offset(of: \.mFormatFlags), 12, "mFormatFlags")
    requireEqual(MemoryLayout<AudioStreamBasicDescription>.offset(of: \.mBytesPerPacket), 16, "mBytesPerPacket")
    requireEqual(MemoryLayout<AudioStreamBasicDescription>.offset(of: \.mFramesPerPacket), 20, "mFramesPerPacket")
    requireEqual(MemoryLayout<AudioStreamBasicDescription>.offset(of: \.mBytesPerFrame), 24, "mBytesPerFrame")
    requireEqual(MemoryLayout<AudioStreamBasicDescription>.offset(of: \.mChannelsPerFrame), 28, "mChannelsPerFrame")
    requireEqual(MemoryLayout<AudioStreamBasicDescription>.offset(of: \.mBitsPerChannel), 32, "mBitsPerChannel")
    requireEqual(MemoryLayout<AudioStreamBasicDescription>.offset(of: \.mReserved), 36, "mReserved")
    let empty = AudioStreamBasicDescription()
    requireEqual(empty.mSampleRate, 0, "empty sample rate")
    requireEqual(empty.mFormatID, 0, "empty format")
    requireEqual(empty.mChannelsPerFrame, 0, "empty channels")
    let filled = AudioStreamBasicDescription(
        mSampleRate: 44100,
        mFormatID: kAudioFormatLinearPCM,
        mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
        mBytesPerPacket: 4,
        mFramesPerPacket: 1,
        mBytesPerFrame: 4,
        mChannelsPerFrame: 2,
        mBitsPerChannel: 16,
        mReserved: 0
    )
    requireEqual(filled.mSampleRate, 44100, "memberwise sample rate")
    requireEqual(filled.mFormatID, kAudioFormatLinearPCM, "memberwise format")
    requireEqual(filled.mFormatFlags, kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked, "memberwise flags")
    requireEqual(filled.mBytesPerPacket, 4, "memberwise bytes/packet")
    requireEqual(filled.mFramesPerPacket, 1, "memberwise frames/packet")
    requireEqual(filled.mBytesPerFrame, 4, "memberwise bytes/frame")
    requireEqual(filled.mChannelsPerFrame, 2, "memberwise channels")
    requireEqual(filled.mBitsPerChannel, 16, "memberwise bits")
    requireEqual(filled.mReserved, 0, "memberwise reserved")
}

func testAudioStreamPacketDescriptionLayout() {
    layoutMatches(
        AudioStreamPacketDescription.self,
        size: 16,
        stride: 16,
        alignment: 8,
        name: "AudioStreamPacketDescription"
    )
    requireEqual(MemoryLayout<AudioStreamPacketDescription>.offset(of: \.mStartOffset), 0, "mStartOffset")
    requireEqual(
        MemoryLayout<AudioStreamPacketDescription>.offset(of: \.mVariableFramesInPacket),
        8,
        "mVariableFramesInPacket"
    )
    requireEqual(MemoryLayout<AudioStreamPacketDescription>.offset(of: \.mDataByteSize), 12, "mDataByteSize")
    let empty = AudioStreamPacketDescription()
    requireEqual(empty.mStartOffset, 0, "empty offset")
    requireEqual(empty.mVariableFramesInPacket, 0, "empty variable frames")
    requireEqual(empty.mDataByteSize, 0, "empty size")
    let filled = AudioStreamPacketDescription(
        mStartOffset: 1024,
        mVariableFramesInPacket: 3,
        mDataByteSize: 64
    )
    requireEqual(filled.mStartOffset, 1024, "memberwise offset")
    requireEqual(filled.mVariableFramesInPacket, 3, "memberwise variable frames")
    requireEqual(filled.mDataByteSize, 64, "memberwise size")
}

func testAudioStreamPacketDependencyDescriptionLayout() {
    layoutMatches(
        AudioStreamPacketDependencyDescription.self,
        size: 16,
        stride: 16,
        alignment: 4,
        name: "AudioStreamPacketDependencyDescription"
    )
    requireEqual(
        MemoryLayout<AudioStreamPacketDependencyDescription>.offset(of: \.mIsIndependentlyDecodable),
        0,
        "mIsIndependentlyDecodable"
    )
    requireEqual(
        MemoryLayout<AudioStreamPacketDependencyDescription>.offset(of: \.mPreRollCount),
        4,
        "mPreRollCount"
    )
    requireEqual(MemoryLayout<AudioStreamPacketDependencyDescription>.offset(of: \.mFlags), 8, "mFlags")
    requireEqual(MemoryLayout<AudioStreamPacketDependencyDescription>.offset(of: \.mReserved), 12, "mReserved")
    let empty = AudioStreamPacketDependencyDescription()
    requireEqual(empty.mIsIndependentlyDecodable, 0, "empty independent")
    requireEqual(empty.mPreRollCount, 0, "empty preroll")
    requireEqual(empty.mFlags, 0, "empty flags")
    requireEqual(empty.mReserved, 0, "empty reserved")
    let filled = AudioStreamPacketDependencyDescription(
        mIsIndependentlyDecodable: 1,
        mPreRollCount: 2,
        mFlags: 3,
        mReserved: 4
    )
    requireEqual(filled.mIsIndependentlyDecodable, 1, "memberwise independent")
    requireEqual(filled.mPreRollCount, 2, "memberwise preroll")
    requireEqual(filled.mFlags, 3, "memberwise flags")
    requireEqual(filled.mReserved, 4, "memberwise reserved")
}

func testAudioTimeStampLayout() {
    layoutMatches(AudioTimeStamp.self, size: 64, stride: 64, alignment: 8, name: "AudioTimeStamp")
    requireEqual(MemoryLayout<AudioTimeStamp>.offset(of: \.mSampleTime), 0, "mSampleTime")
    requireEqual(MemoryLayout<AudioTimeStamp>.offset(of: \.mHostTime), 8, "mHostTime")
    requireEqual(MemoryLayout<AudioTimeStamp>.offset(of: \.mRateScalar), 16, "mRateScalar")
    requireEqual(MemoryLayout<AudioTimeStamp>.offset(of: \.mWordClockTime), 24, "mWordClockTime")
    requireEqual(MemoryLayout<AudioTimeStamp>.offset(of: \.mSMPTETime), 32, "mSMPTETime")
    requireEqual(MemoryLayout<AudioTimeStamp>.offset(of: \.mFlags), 56, "mFlags")
    requireEqual(MemoryLayout<AudioTimeStamp>.offset(of: \.mReserved), 60, "mReserved")
    let empty = AudioTimeStamp()
    requireEqual(empty.mSampleTime, 0, "empty sample")
    requireEqual(empty.mHostTime, 0, "empty host")
    require(empty.mFlags.isEmpty, "empty flags")
    requireEqual(empty.mSMPTETime.mType, .type24, "embedded SMPTE default")
    let smpte = SMPTETime(
        mSubframes: 1,
        mSubframeDivisor: 80,
        mCounter: 2,
        mType: .type25,
        mFlags: .valid,
        mHours: 3,
        mMinutes: 4,
        mSeconds: 5,
        mFrames: 6
    )
    let filled = AudioTimeStamp(
        mSampleTime: 128,
        mHostTime: 99,
        mRateScalar: 1.5,
        mWordClockTime: 7,
        mSMPTETime: smpte,
        mFlags: [.sampleTimeValid, .hostTimeValid],
        mReserved: 0
    )
    requireEqual(filled.mSampleTime, 128, "memberwise sample")
    requireEqual(filled.mHostTime, 99, "memberwise host")
    requireEqual(filled.mRateScalar, 1.5, "memberwise rate")
    requireEqual(filled.mWordClockTime, 7, "memberwise word clock")
    requireEqual(filled.mSMPTETime.mType, .type25, "memberwise SMPTE")
    requireEqual(filled.mFlags, .sampleHostTimeValid, "memberwise flags")
    requireEqual(filled.mReserved, 0, "memberwise reserved")
}

func testAudioValueRangeLayout() {
    layoutMatches(AudioValueRange.self, size: 16, stride: 16, alignment: 8, name: "AudioValueRange")
    requireEqual(MemoryLayout<AudioValueRange>.offset(of: \.mMinimum), 0, "mMinimum")
    requireEqual(MemoryLayout<AudioValueRange>.offset(of: \.mMaximum), 8, "mMaximum")
    let empty = AudioValueRange()
    requireEqual(empty.mMinimum, 0, "empty min")
    requireEqual(empty.mMaximum, 0, "empty max")
    let filled = AudioValueRange(mMinimum: 20, mMaximum: 20000)
    requireEqual(filled.mMinimum, 20, "memberwise min")
    requireEqual(filled.mMaximum, 20000, "memberwise max")
}

func testAudioValueTranslationLayout() {
    layoutMatches(AudioValueTranslation.self, size: 28, stride: 32, alignment: 8, name: "AudioValueTranslation")
    requireEqual(MemoryLayout<AudioValueTranslation>.offset(of: \.mInputData), 0, "mInputData")
    requireEqual(MemoryLayout<AudioValueTranslation>.offset(of: \.mInputDataSize), 8, "mInputDataSize")
    requireEqual(MemoryLayout<AudioValueTranslation>.offset(of: \.mOutputData), 16, "mOutputData")
    requireEqual(MemoryLayout<AudioValueTranslation>.offset(of: \.mOutputDataSize), 24, "mOutputDataSize")
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
            requireEqual(translation.mInputDataSize, 4, "input size")
            requireEqual(translation.mOutputDataSize, 4, "output size")
            require(translation.mInputData != translation.mOutputData, "distinct pointers")
        }
    }
}

func testSMPTETimeLayout() {
    layoutMatches(SMPTETime.self, size: 24, stride: 24, alignment: 4, name: "SMPTETime")
    requireEqual(MemoryLayout<SMPTETime>.offset(of: \.mSubframes), 0, "mSubframes")
    requireEqual(MemoryLayout<SMPTETime>.offset(of: \.mSubframeDivisor), 2, "mSubframeDivisor")
    requireEqual(MemoryLayout<SMPTETime>.offset(of: \.mCounter), 4, "mCounter")
    requireEqual(MemoryLayout<SMPTETime>.offset(of: \.mType), 8, "mType")
    requireEqual(MemoryLayout<SMPTETime>.offset(of: \.mFlags), 12, "mFlags")
    requireEqual(MemoryLayout<SMPTETime>.offset(of: \.mHours), 16, "mHours")
    requireEqual(MemoryLayout<SMPTETime>.offset(of: \.mMinutes), 18, "mMinutes")
    requireEqual(MemoryLayout<SMPTETime>.offset(of: \.mSeconds), 20, "mSeconds")
    requireEqual(MemoryLayout<SMPTETime>.offset(of: \.mFrames), 22, "mFrames")
    let empty = SMPTETime()
    requireEqual(empty.mSubframes, 0, "empty subframes")
    requireEqual(empty.mSubframeDivisor, 0, "empty divisor")
    requireEqual(empty.mCounter, 0, "empty counter")
    requireEqual(empty.mType, .type24, "empty type")
    require(empty.mFlags.isEmpty, "empty flags")
    requireEqual(empty.mHours, 0, "empty hours")
    requireEqual(empty.mMinutes, 0, "empty minutes")
    requireEqual(empty.mSeconds, 0, "empty seconds")
    requireEqual(empty.mFrames, 0, "empty frames")
    let filled = SMPTETime(
        mSubframes: 10,
        mSubframeDivisor: 80,
        mCounter: 1,
        mType: .type30Drop,
        mFlags: [.valid, .running],
        mHours: 1,
        mMinutes: 2,
        mSeconds: 3,
        mFrames: 4
    )
    requireEqual(filled.mSubframes, 10, "memberwise subframes")
    requireEqual(filled.mSubframeDivisor, 80, "memberwise divisor")
    requireEqual(filled.mCounter, 1, "memberwise counter")
    requireEqual(filled.mType, .type30Drop, "memberwise type")
    require(filled.mFlags.contains(.valid) && filled.mFlags.contains(.running), "memberwise flags")
    requireEqual(filled.mHours, 1, "memberwise hours")
    requireEqual(filled.mMinutes, 2, "memberwise minutes")
    requireEqual(filled.mSeconds, 3, "memberwise seconds")
    requireEqual(filled.mFrames, 4, "memberwise frames")
}
