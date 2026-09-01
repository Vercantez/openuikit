import Foundation

public final class AVAudioChannelLayout: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    private var storedLayout: AudioChannelLayout
    private var layoutStorage: UnsafeMutablePointer<AudioChannelLayout>

    public var layoutTag: AudioChannelLayoutTag { storedLayout.mChannelLayoutTag }
    public var channelCount: AVAudioChannelCount {
        let tag = layoutTag
        let count = tag & 0xFFFF
        return count == 0 ? 1 : count
    }
    public var layout: UnsafePointer<AudioChannelLayout> {
        UnsafePointer(layoutStorage)
    }

    public init(layout: UnsafePointer<AudioChannelLayout>) {
        storedLayout = layout.pointee
        layoutStorage = UnsafeMutablePointer<AudioChannelLayout>.allocate(capacity: 1)
        layoutStorage.initialize(to: storedLayout)
        super.init()
    }

    public convenience init?(layoutTag: AudioChannelLayoutTag) {
        var value = AudioChannelLayout(mChannelLayoutTag: layoutTag)
        self.init(layout: &value)
    }

    public required init?(coder: NSCoder) {
        let tag = UInt32(bitPattern: coder.decodeInt32(forKey: "tag"))
        storedLayout = AudioChannelLayout(mChannelLayoutTag: tag)
        layoutStorage = UnsafeMutablePointer<AudioChannelLayout>.allocate(capacity: 1)
        layoutStorage.initialize(to: storedLayout)
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(Int32(bitPattern: layoutTag), forKey: "tag")
    }

    deinit {
        layoutStorage.deinitialize(count: 1)
        layoutStorage.deallocate()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AVAudioChannelLayout else { return false }
        return storedLayout == other.storedLayout
    }
}

public final class AVAudioFormat: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public let sampleRate: Double
    public let channelCount: AVAudioChannelCount
    public let commonFormat: AVAudioCommonFormat
    public let isInterleaved: Bool
    public let channelLayout: AVAudioChannelLayout?
    public var magicCookie: Data?
    public let formatDescription: CMAudioFormatDescription = OpaquePointer(bitPattern: 1)!

    private var asbdStorage: UnsafeMutablePointer<AudioStreamBasicDescription>

    public var isStandard: Bool {
        commonFormat == .pcmFormatFloat32 && isInterleaved == false && sampleRate > 0
    }

    public var streamDescription: UnsafePointer<AudioStreamBasicDescription> {
        UnsafePointer(asbdStorage)
    }

    public var settings: [String: Any] {
        [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channelCount,
            AVLinearPCMIsFloatKey: commonFormat == .pcmFormatFloat32
                || commonFormat == .pcmFormatFloat64,
            AVLinearPCMIsNonInterleaved: !isInterleaved,
            AVLinearPCMBitDepthKey: bitDepth,
        ]
    }

    private var bitDepth: Int {
        switch commonFormat {
        case .pcmFormatFloat64: return 64
        case .pcmFormatInt32, .pcmFormatFloat32: return 32
        case .pcmFormatInt16: return 16
        case .otherFormat: return 0
        }
    }

    private var bytesPerChannel: UInt32 {
        UInt32(max(bitDepth / 8, 0))
    }

    public init?(
        standardFormatWithSampleRate sampleRate: Double,
        channels: AVAudioChannelCount
    ) {
        guard sampleRate > 0, channels > 0 else { return nil }
        self.sampleRate = sampleRate
        self.channelCount = channels
        self.commonFormat = .pcmFormatFloat32
        self.isInterleaved = false
        self.channelLayout = nil
        self.asbdStorage = Self.makeASBD(
            sampleRate: sampleRate,
            channels: channels,
            format: .pcmFormatFloat32,
            interleaved: false
        )
        super.init()
    }

    public init(standardFormatWithSampleRate sampleRate: Double, channelLayout layout: AVAudioChannelLayout) {
        self.sampleRate = sampleRate
        self.channelCount = layout.channelCount
        self.commonFormat = .pcmFormatFloat32
        self.isInterleaved = false
        self.channelLayout = layout
        self.asbdStorage = Self.makeASBD(
            sampleRate: sampleRate,
            channels: layout.channelCount,
            format: .pcmFormatFloat32,
            interleaved: false
        )
        super.init()
    }

    public init?(
        commonFormat format: AVAudioCommonFormat,
        sampleRate: Double,
        channels: AVAudioChannelCount,
        interleaved: Bool
    ) {
        guard format != .otherFormat, sampleRate > 0, channels > 0 else { return nil }
        self.sampleRate = sampleRate
        self.channelCount = channels
        self.commonFormat = format
        self.isInterleaved = interleaved
        self.channelLayout = nil
        self.asbdStorage = Self.makeASBD(
            sampleRate: sampleRate,
            channels: channels,
            format: format,
            interleaved: interleaved
        )
        super.init()
    }

    public init(
        commonFormat format: AVAudioCommonFormat,
        sampleRate: Double,
        interleaved: Bool,
        channelLayout layout: AVAudioChannelLayout
    ) {
        self.sampleRate = sampleRate
        self.channelCount = layout.channelCount
        self.commonFormat = format
        self.isInterleaved = interleaved
        self.channelLayout = layout
        self.asbdStorage = Self.makeASBD(
            sampleRate: sampleRate,
            channels: layout.channelCount,
            format: format,
            interleaved: interleaved
        )
        super.init()
    }

    public init?(settings: [String: Any]) {
        let rate = (settings[AVSampleRateKey] as? Double)
            ?? (settings[AVSampleRateKey] as? NSNumber)?.doubleValue
            ?? 0
        let channels = (settings[AVNumberOfChannelsKey] as? AVAudioChannelCount)
            ?? (settings[AVNumberOfChannelsKey] as? NSNumber)?.uint32Value
            ?? 0
        let isFloat = (settings[AVLinearPCMIsFloatKey] as? Bool)
            ?? (settings[AVLinearPCMIsFloatKey] as? NSNumber)?.boolValue
            ?? true
        let nonInterleaved = (settings[AVLinearPCMIsNonInterleaved] as? Bool)
            ?? (settings[AVLinearPCMIsNonInterleaved] as? NSNumber)?.boolValue
            ?? true
        let depth = (settings[AVLinearPCMBitDepthKey] as? Int)
            ?? (settings[AVLinearPCMBitDepthKey] as? NSNumber)?.intValue
            ?? 32
        guard rate > 0, channels > 0 else { return nil }
        let format: AVAudioCommonFormat
        if isFloat && depth >= 64 {
            format = .pcmFormatFloat64
        } else if isFloat {
            format = .pcmFormatFloat32
        } else if depth <= 16 {
            format = .pcmFormatInt16
        } else {
            format = .pcmFormatInt32
        }
        self.sampleRate = rate
        self.channelCount = channels
        self.commonFormat = format
        self.isInterleaved = !nonInterleaved
        self.channelLayout = nil
        self.asbdStorage = Self.makeASBD(
            sampleRate: rate,
            channels: channels,
            format: format,
            interleaved: !nonInterleaved
        )
        super.init()
    }

    public init?(streamDescription asbd: UnsafePointer<AudioStreamBasicDescription>) {
        let desc = asbd.pointee
        guard desc.mSampleRate > 0, desc.mChannelsPerFrame > 0 else { return nil }
        self.sampleRate = desc.mSampleRate
        self.channelCount = desc.mChannelsPerFrame
        self.isInterleaved = (desc.mFormatFlags & kAudioFormatFlagIsNonInterleaved) == 0
        if desc.mFormatID != kAudioFormatLinearPCM {
            self.commonFormat = .otherFormat
        } else if (desc.mFormatFlags & kAudioFormatFlagIsFloat) != 0 {
            self.commonFormat = desc.mBitsPerChannel >= 64 ? .pcmFormatFloat64 : .pcmFormatFloat32
        } else {
            self.commonFormat = desc.mBitsPerChannel <= 16 ? .pcmFormatInt16 : .pcmFormatInt32
        }
        self.channelLayout = nil
        self.asbdStorage = UnsafeMutablePointer<AudioStreamBasicDescription>.allocate(capacity: 1)
        self.asbdStorage.initialize(to: desc)
        super.init()
    }

    public init?(
        streamDescription asbd: UnsafePointer<AudioStreamBasicDescription>,
        channelLayout layout: AVAudioChannelLayout?
    ) {
        let desc = asbd.pointee
        guard desc.mSampleRate > 0 else { return nil }
        self.sampleRate = desc.mSampleRate
        self.channelCount = layout?.channelCount ?? desc.mChannelsPerFrame
        self.isInterleaved = (desc.mFormatFlags & kAudioFormatFlagIsNonInterleaved) == 0
        self.commonFormat = .pcmFormatFloat32
        self.channelLayout = layout
        self.asbdStorage = UnsafeMutablePointer<AudioStreamBasicDescription>.allocate(capacity: 1)
        self.asbdStorage.initialize(to: desc)
        super.init()
    }

    public init(cmAudioFormatDescription formatDescription: CMAudioFormatDescription) {
        _ = formatDescription
        self.sampleRate = 44100
        self.channelCount = 2
        self.commonFormat = .pcmFormatFloat32
        self.isInterleaved = false
        self.channelLayout = nil
        self.asbdStorage = Self.makeASBD(
            sampleRate: 44100,
            channels: 2,
            format: .pcmFormatFloat32,
            interleaved: false
        )
        super.init()
    }

    public init(CMAudioFormatDescription formatDescription: CMAudioFormatDescription) {
        _ = formatDescription
        self.sampleRate = 44100
        self.channelCount = 2
        self.commonFormat = .pcmFormatFloat32
        self.isInterleaved = false
        self.channelLayout = nil
        self.asbdStorage = Self.makeASBD(
            sampleRate: 44100,
            channels: 2,
            format: .pcmFormatFloat32,
            interleaved: false
        )
        super.init()
    }

    public required init?(coder: NSCoder) {
        sampleRate = coder.decodeDouble(forKey: "sampleRate")
        channelCount = UInt32(bitPattern: coder.decodeInt32(forKey: "channels"))
        commonFormat = AVAudioCommonFormat(rawValue: UInt(coder.decodeInt32(forKey: "format")))
            ?? .pcmFormatFloat32
        isInterleaved = coder.decodeBool(forKey: "interleaved")
        channelLayout = nil
        asbdStorage = Self.makeASBD(
            sampleRate: sampleRate,
            channels: channelCount,
            format: commonFormat,
            interleaved: isInterleaved
        )
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(sampleRate, forKey: "sampleRate")
        coder.encode(Int32(bitPattern: channelCount), forKey: "channels")
        coder.encode(Int32(commonFormat.rawValue), forKey: "format")
        coder.encode(isInterleaved, forKey: "interleaved")
    }

    deinit {
        asbdStorage.deinitialize(count: 1)
        asbdStorage.deallocate()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AVAudioFormat else { return false }
        return sampleRate == other.sampleRate
            && channelCount == other.channelCount
            && commonFormat == other.commonFormat
            && isInterleaved == other.isInterleaved
    }

    var bytesPerFrame: Int {
        let width = max(bitDepth / 8, 1)
        if isInterleaved {
            return width * Int(channelCount)
        }
        return width
    }

    var channelDataByteCount: Int {
        // Used by PCM buffers; callers supply frame capacity.
        bytesPerFrame
    }

    static func makeASBD(
        sampleRate: Double,
        channels: AVAudioChannelCount,
        format: AVAudioCommonFormat,
        interleaved: Bool
    ) -> UnsafeMutablePointer<AudioStreamBasicDescription> {
        let bits: UInt32
        var flags: AudioFormatFlags = kAudioFormatFlagIsPacked
        switch format {
        case .pcmFormatFloat32:
            bits = 32
            flags |= kAudioFormatFlagIsFloat
        case .pcmFormatFloat64:
            bits = 64
            flags |= kAudioFormatFlagIsFloat
        case .pcmFormatInt16:
            bits = 16
            flags |= kAudioFormatFlagIsSignedInteger
        case .pcmFormatInt32:
            bits = 32
            flags |= kAudioFormatFlagIsSignedInteger
        case .otherFormat:
            bits = 0
        }
        if !interleaved {
            flags |= kAudioFormatFlagIsNonInterleaved
        }
        let bytesPerChannel = bits / 8
        let channelsPerFrame: UInt32 = interleaved ? channels : 1
        let bytesPerFrame = bytesPerChannel * channelsPerFrame
        let ptr = UnsafeMutablePointer<AudioStreamBasicDescription>.allocate(capacity: 1)
        ptr.initialize(
            to: AudioStreamBasicDescription(
                mSampleRate: sampleRate,
                mFormatID: kAudioFormatLinearPCM,
                mFormatFlags: flags,
                mBytesPerPacket: bytesPerFrame,
                mFramesPerPacket: 1,
                mBytesPerFrame: bytesPerFrame,
                mChannelsPerFrame: channels,
                mBitsPerChannel: bits,
                mReserved: 0
            )
        )
        return ptr
    }
}

open class AVAudioBuffer: NSObject, @unchecked Sendable {
    public let format: AVAudioFormat
    private var listStorage: UnsafeMutablePointer<AudioBufferList>

    public var audioBufferList: UnsafePointer<AudioBufferList> {
        UnsafePointer(listStorage)
    }
    public var mutableAudioBufferList: UnsafeMutablePointer<AudioBufferList> { listStorage }

    public init(format: AVAudioFormat) {
        self.format = format
        self.listStorage = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
        self.listStorage.initialize(to: AudioBufferList())
        super.init()
    }

    deinit {
        listStorage.deinitialize(count: 1)
        listStorage.deallocate()
    }

    func bindList(channels: UInt32, byteSize: UInt32, data: UnsafeMutableRawPointer?) {
        listStorage.pointee = AudioBufferList(
            mNumberBuffers: format.isInterleaved ? 1 : max(channels, 1),
            mBuffers: AudioBuffer(
                mNumberChannels: format.isInterleaved ? channels : 1,
                mDataByteSize: byteSize,
                mData: data
            )
        )
    }
}

public final class AVAudioPCMBuffer: AVAudioBuffer, @unchecked Sendable {
    public let frameCapacity: AVAudioFrameCount
    public var frameLength: AVAudioFrameCount = 0 {
        didSet {
            if frameLength > frameCapacity { frameLength = frameCapacity }
        }
    }
    public let stride: Int
    private let storage: UnsafeMutableRawPointer
    private let byteCount: Int
    private let channelCount: Int
    private var channelPointers: UnsafeMutablePointer<UnsafeMutableRawPointer>
    private var floatPointers: UnsafeMutablePointer<UnsafeMutablePointer<Float>>?
    private var int16Pointers: UnsafeMutablePointer<UnsafeMutablePointer<Int16>>?
    private var int32Pointers: UnsafeMutablePointer<UnsafeMutablePointer<Int32>>?

    public var floatChannelData: UnsafePointer<UnsafeMutablePointer<Float>>? {
        floatPointers.map { UnsafePointer($0) }
    }
    public var int16ChannelData: UnsafePointer<UnsafeMutablePointer<Int16>>? {
        int16Pointers.map { UnsafePointer($0) }
    }
    public var int32ChannelData: UnsafePointer<UnsafeMutablePointer<Int32>>? {
        int32Pointers.map { UnsafePointer($0) }
    }

    public init?(pcmFormat format: AVAudioFormat, frameCapacity: AVAudioFrameCount) {
        guard format.commonFormat != .otherFormat, frameCapacity > 0 else { return nil }
        self.frameCapacity = frameCapacity
        self.channelCount = Int(format.channelCount)
        self.stride = format.isInterleaved ? channelCount : 1
        let bytesPerSample: Int
        switch format.commonFormat {
        case .pcmFormatFloat64: bytesPerSample = 8
        case .pcmFormatFloat32, .pcmFormatInt32: bytesPerSample = 4
        case .pcmFormatInt16: bytesPerSample = 2
        case .otherFormat: bytesPerSample = 0
        }
        let frames = Int(frameCapacity)
        let planes = format.isInterleaved ? 1 : max(channelCount, 1)
        self.byteCount = max(bytesPerSample * frames * stride * planes, 1)
        self.storage = UnsafeMutableRawPointer.allocate(
            byteCount: byteCount,
            alignment: MemoryLayout<Float>.alignment
        )
        self.storage.initializeMemory(as: UInt8.self, repeating: 0, count: byteCount)
        self.channelPointers = UnsafeMutablePointer<UnsafeMutableRawPointer>.allocate(
            capacity: max(channelCount, 1)
        )
        super.init(format: format)
        let planeBytes = format.isInterleaved
            ? byteCount
            : bytesPerSample * frames
        for index in 0..<max(channelCount, 1) {
            if format.isInterleaved {
                channelPointers[index] = storage
            } else {
                channelPointers[index] = storage.advanced(by: index * planeBytes)
            }
        }
        switch format.commonFormat {
        case .pcmFormatFloat32:
            let ptrs = UnsafeMutablePointer<UnsafeMutablePointer<Float>>.allocate(
                capacity: max(channelCount, 1)
            )
            for index in 0..<max(channelCount, 1) {
                ptrs[index] = channelPointers[index].assumingMemoryBound(to: Float.self)
            }
            floatPointers = ptrs
        case .pcmFormatInt16:
            let ptrs = UnsafeMutablePointer<UnsafeMutablePointer<Int16>>.allocate(
                capacity: max(channelCount, 1)
            )
            for index in 0..<max(channelCount, 1) {
                ptrs[index] = channelPointers[index].assumingMemoryBound(to: Int16.self)
            }
            int16Pointers = ptrs
        case .pcmFormatInt32:
            let ptrs = UnsafeMutablePointer<UnsafeMutablePointer<Int32>>.allocate(
                capacity: max(channelCount, 1)
            )
            for index in 0..<max(channelCount, 1) {
                ptrs[index] = channelPointers[index].assumingMemoryBound(to: Int32.self)
            }
            int32Pointers = ptrs
        default:
            break
        }
        bindList(
            channels: format.channelCount,
            byteSize: UInt32(planeBytes),
            data: storage
        )
    }

    public convenience init?(
        PCMFormat format: AVAudioFormat,
        frameCapacity: AVAudioFrameCount
    ) {
        self.init(pcmFormat: format, frameCapacity: frameCapacity)
    }

    public init?(
        pcmFormat format: AVAudioFormat,
        bufferListNoCopy bufferList: UnsafePointer<AudioBufferList>,
        deallocator: ((UnsafePointer<AudioBufferList>) -> Void)? = nil
    ) {
        // Linux starting point does not adopt caller-owned AudioBufferList storage.
        _ = bufferList
        _ = deallocator
        return nil
    }

    public convenience init?(
        PCMFormat format: AVAudioFormat,
        bufferListNoCopy bufferList: UnsafePointer<AudioBufferList>,
        deallocator: ((UnsafePointer<AudioBufferList>) -> Void)? = nil
    ) {
        self.init(
            pcmFormat: format,
            bufferListNoCopy: bufferList,
            deallocator: deallocator
        )
    }

    deinit {
        floatPointers?.deallocate()
        int16Pointers?.deallocate()
        int32Pointers?.deallocate()
        channelPointers.deallocate()
        storage.deallocate()
    }
}

public final class AVAudioCompressedBuffer: AVAudioBuffer, @unchecked Sendable {
    public let packetCapacity: AVAudioPacketCount
    public let maximumPacketSize: Int
    public var packetCount: AVAudioPacketCount = 0
    public var byteLength: UInt32 = 0
    public let byteCapacity: UInt32
    public let data: UnsafeMutableRawPointer
    public var packetDescriptions: UnsafeMutablePointer<AudioStreamPacketDescription>?
    public var packetDependencies: [AudioStreamPacketDependencyDescription]?

    public init(format: AVAudioFormat, packetCapacity: AVAudioPacketCount) {
        self.packetCapacity = packetCapacity
        self.maximumPacketSize = 0
        self.byteCapacity = packetCapacity * 256
        self.data = UnsafeMutableRawPointer.allocate(
            byteCount: Int(max(byteCapacity, 1)),
            alignment: 16
        )
        super.init(format: format)
    }

    public init(
        format: AVAudioFormat,
        packetCapacity: AVAudioPacketCount,
        maximumPacketSize: Int
    ) {
        self.packetCapacity = packetCapacity
        self.maximumPacketSize = maximumPacketSize
        self.byteCapacity = packetCapacity * UInt32(max(maximumPacketSize, 1))
        self.data = UnsafeMutableRawPointer.allocate(
            byteCount: Int(max(byteCapacity, 1)),
            alignment: 16
        )
        super.init(format: format)
    }

    deinit {
        data.deallocate()
    }
}

public final class AVAudioTime: NSObject, @unchecked Sendable {
    public let hostTime: UInt64
    public let sampleTime: AVAudioFramePosition
    public let sampleRate: Double
    public let isHostTimeValid: Bool
    public let isSampleTimeValid: Bool

    public var audioTimeStamp: AudioTimeStamp {
        AudioTimeStamp(
            mSampleTime: isSampleTimeValid ? Double(sampleTime) : 0,
            mHostTime: isHostTimeValid ? hostTime : 0,
            mRateScalar: 1,
            mFlags: (isHostTimeValid ? 1 : 0) | (isSampleTimeValid ? 2 : 0)
        )
    }

    public init(hostTime: UInt64) {
        self.hostTime = hostTime
        self.sampleTime = 0
        self.sampleRate = 0
        self.isHostTimeValid = true
        self.isSampleTimeValid = false
        super.init()
    }

    public init(sampleTime: AVAudioFramePosition, atRate sampleRate: Double) {
        self.hostTime = 0
        self.sampleTime = sampleTime
        self.sampleRate = sampleRate
        self.isHostTimeValid = false
        self.isSampleTimeValid = true
        super.init()
    }

    public init(hostTime: UInt64, sampleTime: AVAudioFramePosition, atRate sampleRate: Double) {
        self.hostTime = hostTime
        self.sampleTime = sampleTime
        self.sampleRate = sampleRate
        self.isHostTimeValid = true
        self.isSampleTimeValid = true
        super.init()
    }

    public init(audioTimeStamp ts: UnsafePointer<AudioTimeStamp>, sampleRate: Double) {
        let stamp = ts.pointee
        self.hostTime = stamp.mHostTime
        self.sampleTime = AVAudioFramePosition(stamp.mSampleTime)
        self.sampleRate = sampleRate
        self.isHostTimeValid = stamp.mHostTime != 0
        self.isSampleTimeValid = stamp.mFlags != 0
        super.init()
    }

    public class func hostTime(forSeconds seconds: TimeInterval) -> UInt64 {
        UInt64((max(seconds, 0) * 1_000_000_000.0).rounded())
    }

    public class func seconds(forHostTime hostTime: UInt64) -> TimeInterval {
        TimeInterval(hostTime) / 1_000_000_000.0
    }

    public func extrapolateTime(fromAnchor anchorTime: AVAudioTime) -> AVAudioTime? {
        guard isSampleTimeValid, anchorTime.isSampleTimeValid, sampleRate > 0 else {
            return nil
        }
        let delta = sampleTime - anchorTime.sampleTime
        if anchorTime.isHostTimeValid {
            let extra = Self.hostTime(forSeconds: TimeInterval(delta) / sampleRate)
            return AVAudioTime(
                hostTime: anchorTime.hostTime + extra,
                sampleTime: sampleTime,
                atRate: sampleRate
            )
        }
        return AVAudioTime(sampleTime: sampleTime, atRate: sampleRate)
    }
}
