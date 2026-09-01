import Foundation
#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif
#if canImport(CoreMedia)
import CoreMedia
#endif

public final class AVAudioChannelLayout: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public let layoutTag: UInt32
    public var channelCount: AVAudioChannelCount {
        let count = layoutTag & 0xFFFF
        return count == 0 ? 1 : count
    }

    public init?(layoutTag: UInt32) {
        self.layoutTag = layoutTag
        super.init()
    }

    public required init?(coder: NSCoder) {
        layoutTag = UInt32(bitPattern: coder.decodeInt32(forKey: "tag"))
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(Int32(bitPattern: layoutTag), forKey: "tag")
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AVAudioChannelLayout else { return false }
        return layoutTag == other.layoutTag
    }

    #if canImport(CoreAudioTypes) || canImport(AudioToolbox)
    private var layoutStorage: UnsafeMutablePointer<AudioChannelLayout>? = nil

    public var layout: UnsafePointer<AudioChannelLayout> {
        if let existing = layoutStorage {
            return UnsafePointer(existing)
        }
        let storage = UnsafeMutablePointer<AudioChannelLayout>.allocate(capacity: 1)
        storage.initialize(to: AudioChannelLayout())
        storage.pointee.mChannelLayoutTag = layoutTag
        layoutStorage = storage
        return UnsafePointer(storage)
    }

    public init(layout: UnsafePointer<AudioChannelLayout>) {
        self.layoutTag = layout.pointee.mChannelLayoutTag
        let storage = UnsafeMutablePointer<AudioChannelLayout>.allocate(capacity: 1)
        storage.initialize(to: layout.pointee)
        self.layoutStorage = storage
        super.init()
    }

    deinit {
        layoutStorage?.deinitialize(count: 1)
        layoutStorage?.deallocate()
    }
    #endif
}

public final class AVAudioFormat: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public let sampleRate: Double
    public let channelCount: AVAudioChannelCount
    public let commonFormat: AVAudioCommonFormat
    public let isInterleaved: Bool
    public let channelLayout: AVAudioChannelLayout?
    public var magicCookie: Data?

    public var isStandard: Bool {
        commonFormat == .pcmFormatFloat32 && isInterleaved == false && sampleRate > 0
    }

    public var settings: [String: Any] {
        [
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channelCount,
            AVLinearPCMIsFloatKey: commonFormat == .pcmFormatFloat32
                || commonFormat == .pcmFormatFloat64,
            AVLinearPCMIsNonInterleaved: !isInterleaved,
            AVLinearPCMBitDepthKey: bitDepth,
        ]
    }

    var bitDepth: Int {
        switch commonFormat {
        case .pcmFormatFloat64: return 64
        case .pcmFormatInt32, .pcmFormatFloat32: return 32
        case .pcmFormatInt16: return 16
        case .otherFormat: return 0
        }
    }

    var bytesPerSample: Int { max(bitDepth / 8, 0) }

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
        super.init()
    }

    public init(standardFormatWithSampleRate sampleRate: Double, channelLayout layout: AVAudioChannelLayout) {
        self.sampleRate = sampleRate
        self.channelCount = layout.channelCount
        self.commonFormat = .pcmFormatFloat32
        self.isInterleaved = false
        self.channelLayout = layout
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
        super.init()
    }

    public required init?(coder: NSCoder) {
        sampleRate = coder.decodeDouble(forKey: "sampleRate")
        channelCount = UInt32(bitPattern: coder.decodeInt32(forKey: "channels"))
        commonFormat = AVAudioCommonFormat(rawValue: UInt(coder.decodeInt32(forKey: "format")))
            ?? .pcmFormatFloat32
        isInterleaved = coder.decodeBool(forKey: "interleaved")
        channelLayout = nil
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(sampleRate, forKey: "sampleRate")
        coder.encode(Int32(bitPattern: channelCount), forKey: "channels")
        coder.encode(Int32(commonFormat.rawValue), forKey: "format")
        coder.encode(isInterleaved, forKey: "interleaved")
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AVAudioFormat else { return false }
        return sampleRate == other.sampleRate
            && channelCount == other.channelCount
            && commonFormat == other.commonFormat
            && isInterleaved == other.isInterleaved
    }

    #if canImport(CoreAudioTypes) || canImport(AudioToolbox)
    private var asbdStorage: UnsafeMutablePointer<AudioStreamBasicDescription>? = nil

    public var streamDescription: UnsafePointer<AudioStreamBasicDescription> {
        if let existing = asbdStorage {
            return UnsafePointer(existing)
        }
        let ptr = UnsafeMutablePointer<AudioStreamBasicDescription>.allocate(capacity: 1)
        ptr.initialize(to: Self.makeASBDValue(
            sampleRate: sampleRate,
            channels: channelCount,
            format: commonFormat,
            interleaved: isInterleaved
        ))
        asbdStorage = ptr
        return UnsafePointer(ptr)
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
        let storage = UnsafeMutablePointer<AudioStreamBasicDescription>.allocate(capacity: 1)
        storage.initialize(to: desc)
        self.asbdStorage = storage
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
        if desc.mFormatID != kAudioFormatLinearPCM {
            self.commonFormat = .otherFormat
        } else if (desc.mFormatFlags & kAudioFormatFlagIsFloat) != 0 {
            self.commonFormat = desc.mBitsPerChannel >= 64 ? .pcmFormatFloat64 : .pcmFormatFloat32
        } else {
            self.commonFormat = desc.mBitsPerChannel <= 16 ? .pcmFormatInt16 : .pcmFormatInt32
        }
        self.channelLayout = layout
        let storage = UnsafeMutablePointer<AudioStreamBasicDescription>.allocate(capacity: 1)
        storage.initialize(to: desc)
        self.asbdStorage = storage
        super.init()
    }

    deinit {
        asbdStorage?.deinitialize(count: 1)
        asbdStorage?.deallocate()
    }

    static func makeASBDValue(
        sampleRate: Double,
        channels: AVAudioChannelCount,
        format: AVAudioCommonFormat,
        interleaved: Bool
    ) -> AudioStreamBasicDescription {
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
        return AudioStreamBasicDescription(
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
    }
    #endif

    #if canImport(CoreMedia)
    public init(cmAudioFormatDescription formatDescription: CMAudioFormatDescription) {
        _ = formatDescription
        self.sampleRate = 0
        self.channelCount = 0
        self.commonFormat = .otherFormat
        self.isInterleaved = false
        self.channelLayout = nil
        super.init()
    }

    public init(CMAudioFormatDescription formatDescription: CMAudioFormatDescription) {
        _ = formatDescription
        self.sampleRate = 0
        self.channelCount = 0
        self.commonFormat = .otherFormat
        self.isInterleaved = false
        self.channelLayout = nil
        super.init()
    }
    #endif
}

#if canImport(CoreAudioTypes) || canImport(AudioToolbox)
func avfaudioAudioBufferListByteCount(maximumBuffers: Int) -> Int {
    let buffers = max(maximumBuffers, 1)
    let header = MemoryLayout<AudioBufferList>.size
    let extra = MemoryLayout<AudioBuffer>.stride * (buffers - 1)
    return header + extra
}

func avfaudioAllocateAudioBufferList(
    maximumBuffers: Int
) -> UnsafeMutablePointer<AudioBufferList> {
    let buffers = max(maximumBuffers, 1)
    let byteCount = avfaudioAudioBufferListByteCount(maximumBuffers: buffers)
    let alignment = max(MemoryLayout<AudioBufferList>.alignment, MemoryLayout<AudioBuffer>.alignment)
    let raw = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: alignment)
    raw.initializeMemory(as: UInt8.self, repeating: 0, count: byteCount)
    let list = raw.bindMemory(to: AudioBufferList.self, capacity: 1)
    list.pointee.mNumberBuffers = UInt32(buffers)
    return list
}

func avfaudioAudioBuffers(
    _ list: UnsafeMutablePointer<AudioBufferList>
) -> UnsafeMutablePointer<AudioBuffer> {
    let offset = MemoryLayout<AudioBufferList>.offset(of: \.mBuffers)
        ?? MemoryLayout<UInt32>.stride
    return UnsafeMutableRawPointer(list).advanced(by: offset).assumingMemoryBound(to: AudioBuffer.self)
}

func avfaudioDeallocateAudioBufferList(_ list: UnsafeMutablePointer<AudioBufferList>) {
    UnsafeMutableRawPointer(list).deallocate()
}
#endif

open class AVAudioBuffer: NSObject, @unchecked Sendable {
    public let format: AVAudioFormat

    public init(format: AVAudioFormat) {
        self.format = format
        super.init()
    }

    #if canImport(CoreAudioTypes) || canImport(AudioToolbox)
    var ablStorage: UnsafeMutablePointer<AudioBufferList>? = nil

    public var audioBufferList: UnsafePointer<AudioBufferList> {
        UnsafePointer(mutableAudioBufferList)
    }

    public var mutableAudioBufferList: UnsafeMutablePointer<AudioBufferList> {
        if let existing = ablStorage {
            return existing
        }
        let list = avfaudioAllocateAudioBufferList(maximumBuffers: 1)
        ablStorage = list
        return list
    }

    deinit {
        if let ablStorage {
            avfaudioDeallocateAudioBufferList(ablStorage)
        }
    }
    #endif
}

public final class AVAudioPCMBuffer: AVAudioBuffer, @unchecked Sendable {
    public let frameCapacity: AVAudioFrameCount
    public var frameLength: AVAudioFrameCount = 0 {
        didSet {
            if frameLength > frameCapacity { frameLength = frameCapacity }
        }
    }
    public let stride: Int
    private let channelCount: Int
    private let bytesPerSample: Int
    private var ownedStorage: UnsafeMutableRawPointer?
    private var ownedByteCount: Int = 0
    private var channelPointers: UnsafeMutablePointer<UnsafeMutableRawPointer>
    private var floatPointers: UnsafeMutablePointer<UnsafeMutablePointer<Float>>?
    private var int16Pointers: UnsafeMutablePointer<UnsafeMutablePointer<Int16>>?
    private var int32Pointers: UnsafeMutablePointer<UnsafeMutablePointer<Int32>>?
    private let deallocatorOnce = AVFAudioCallbackDelivery.Once()
    #if canImport(CoreAudioTypes) || canImport(AudioToolbox)
    private var noCopyList: UnsafePointer<AudioBufferList>? = nil
    private var noCopyDeallocator: ((UnsafePointer<AudioBufferList>) -> Void)? = nil
    #endif

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
        self.stride = format.isInterleaved ? max(channelCount, 1) : 1
        self.bytesPerSample = format.bytesPerSample
        let frames = Int(frameCapacity)
        let planes = format.isInterleaved ? 1 : max(channelCount, 1)
        let byteCount = max(bytesPerSample * frames * stride * planes, 1)
        let storage = UnsafeMutableRawPointer.allocate(
            byteCount: byteCount,
            alignment: max(MemoryLayout<Float>.alignment, 16)
        )
        storage.initializeMemory(as: UInt8.self, repeating: 0, count: byteCount)
        self.ownedStorage = storage
        self.ownedByteCount = byteCount
        self.channelPointers = UnsafeMutablePointer<UnsafeMutableRawPointer>.allocate(
            capacity: max(channelCount, 1)
        )
        super.init(format: format)
        let planeBytes = format.isInterleaved ? byteCount : max(bytesPerSample * frames, 1)
        for index in 0..<max(channelCount, 1) {
            if format.isInterleaved {
                channelPointers[index] = storage
            } else {
                channelPointers[index] = storage.advanced(by: index * planeBytes)
            }
        }
        bindTypedChannelPointers()
        #if canImport(CoreAudioTypes) || canImport(AudioToolbox)
        installOwnedAudioBufferList(planeBytes: planeBytes)
        #endif
    }

    public convenience init?(
        PCMFormat format: AVAudioFormat,
        frameCapacity: AVAudioFrameCount
    ) {
        self.init(pcmFormat: format, frameCapacity: frameCapacity)
    }

    #if canImport(CoreAudioTypes) || canImport(AudioToolbox)
    public init?(
        pcmFormat format: AVAudioFormat,
        bufferListNoCopy bufferList: UnsafePointer<AudioBufferList>,
        deallocator: ((UnsafePointer<AudioBufferList>) -> Void)? = nil
    ) {
        let bufferCount = Int(bufferList.pointee.mNumberBuffers)
        guard format.commonFormat != .otherFormat, bufferCount >= 1 else { return nil }
        let buffers = avfaudioAudioBuffers(UnsafeMutablePointer(mutating: bufferList))
        let first = buffers[0]
        guard let data = first.mData, first.mDataByteSize > 0, format.bytesPerSample > 0 else {
            return nil
        }
        let expectedBuffers = format.isInterleaved ? 1 : max(Int(format.channelCount), 1)
        guard bufferCount == expectedBuffers else { return nil }
        var planes: [UnsafeMutableRawPointer] = []
        if format.isInterleaved {
            planes = Array(repeating: data, count: max(Int(format.channelCount), 1))
        } else {
            planes.reserveCapacity(expectedBuffers)
            for index in 0..<expectedBuffers {
                guard let plane = buffers[index].mData else { return nil }
                planes.append(plane)
            }
        }
        self.frameCapacity = AVAudioFrameCount(
            Int(first.mDataByteSize) / max(
                format.bytesPerSample * (format.isInterleaved ? Int(format.channelCount) : 1),
                1
            )
        )
        self.channelCount = Int(format.channelCount)
        self.stride = format.isInterleaved ? max(channelCount, 1) : 1
        self.bytesPerSample = format.bytesPerSample
        self.ownedStorage = nil
        self.noCopyList = bufferList
        self.noCopyDeallocator = deallocator
        self.channelPointers = UnsafeMutablePointer<UnsafeMutableRawPointer>.allocate(
            capacity: max(channelCount, 1)
        )
        super.init(format: format)
        for index in 0..<max(channelCount, 1) {
            channelPointers[index] = planes[index]
        }
        bindTypedChannelPointers()
        ablStorage = UnsafeMutablePointer(mutating: bufferList)
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

    private func installOwnedAudioBufferList(planeBytes: Int) {
        let buffers = format.isInterleaved ? 1 : max(channelCount, 1)
        let list = avfaudioAllocateAudioBufferList(maximumBuffers: buffers)
        let ablBuffers = avfaudioAudioBuffers(list)
        if format.isInterleaved {
            ablBuffers[0] = AudioBuffer(
                mNumberChannels: UInt32(channelCount),
                mDataByteSize: UInt32(planeBytes),
                mData: ownedStorage
            )
        } else {
            for index in 0..<buffers {
                ablBuffers[index] = AudioBuffer(
                    mNumberChannels: 1,
                    mDataByteSize: UInt32(planeBytes),
                    mData: channelPointers[index]
                )
            }
        }
        ablStorage = list
    }
    #endif

    private func bindTypedChannelPointers() {
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
    }

    deinit {
        floatPointers?.deallocate()
        int16Pointers?.deallocate()
        int32Pointers?.deallocate()
        channelPointers.deallocate()
        #if canImport(CoreAudioTypes) || canImport(AudioToolbox)
        if let noCopyList {
            ablStorage = nil
            if deallocatorOnce.claim() {
                noCopyDeallocator?(noCopyList)
            }
        } else if let ownedStorage {
            ownedStorage.deallocate()
        }
        #else
        ownedStorage?.deallocate()
        #endif
    }
}

public final class AVAudioCompressedBuffer: AVAudioBuffer, @unchecked Sendable {
    public let packetCapacity: AVAudioPacketCount
    public let maximumPacketSize: Int
    public var packetCount: AVAudioPacketCount = 0
    public var byteLength: UInt32 = 0
    public let byteCapacity: UInt32
    public let data: UnsafeMutableRawPointer
    #if canImport(CoreAudioTypes) || canImport(AudioToolbox)
    public var packetDescriptions: UnsafeMutablePointer<AudioStreamPacketDescription>?
    public var packetDependencies: [AudioStreamPacketDependencyDescription]?
    #endif

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

    #if canImport(CoreAudioTypes) || canImport(AudioToolbox)
    public var audioTimeStamp: AudioTimeStamp {
        var stamp = AudioTimeStamp()
        stamp.mSampleTime = isSampleTimeValid ? Double(sampleTime) : 0
        stamp.mHostTime = isHostTimeValid ? hostTime : 0
        stamp.mRateScalar = 1
        stamp.mFlags = avfaudioTimeStampFlags(
            hostValid: isHostTimeValid,
            sampleValid: isSampleTimeValid
        )
        return stamp
    }

    public init(audioTimeStamp ts: UnsafePointer<AudioTimeStamp>, sampleRate: Double) {
        let stamp = ts.pointee
        self.hostTime = stamp.mHostTime
        self.sampleTime = AVAudioFramePosition(stamp.mSampleTime)
        self.sampleRate = sampleRate
        self.isHostTimeValid = stamp.mFlags.contains(.hostTimeValid)
        self.isSampleTimeValid = stamp.mFlags.contains(.sampleTimeValid)
        super.init()
    }
    #endif
}

#if canImport(CoreAudioTypes) || canImport(AudioToolbox)
func avfaudioTimeStampFlags(hostValid: Bool, sampleValid: Bool) -> AudioTimeStampFlags {
    var flags: AudioTimeStampFlags = []
    if hostValid {
        flags.insert(.hostTimeValid)
    }
    if sampleValid {
        flags.insert(.sampleTimeValid)
    }
    return flags
}
#endif
