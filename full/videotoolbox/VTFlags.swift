public struct VTCompressionSessionOptionFlags: OptionSet, Hashable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let beginFinalPass = VTCompressionSessionOptionFlags(rawValue: 1 << 0)
}

public struct VTDecodeFrameFlags: OptionSet, Hashable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let enableAsynchronousDecompression = VTDecodeFrameFlags(rawValue: 1 << 0)
    public static let doNotOutputFrame = VTDecodeFrameFlags(rawValue: 1 << 1)
    public static let oneXRealTimePlayback = VTDecodeFrameFlags(rawValue: 1 << 2)
    public static let enableTemporalProcessing = VTDecodeFrameFlags(rawValue: 1 << 3)
}

public struct VTDecodeInfoFlags: OptionSet, Hashable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let asynchronous = VTDecodeInfoFlags(rawValue: 1 << 0)
    public static let frameDropped = VTDecodeInfoFlags(rawValue: 1 << 1)
    public static let imageBufferModifiable = VTDecodeInfoFlags(rawValue: 1 << 2)
    public static let skippedLeadingFrameDropped = VTDecodeInfoFlags(rawValue: 1 << 3)
    public static let frameInterrupted = VTDecodeInfoFlags(rawValue: 1 << 4)
}

public struct VTEncodeInfoFlags: OptionSet, Hashable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let asynchronous = VTEncodeInfoFlags(rawValue: 1 << 0)
    public static let frameDropped = VTEncodeInfoFlags(rawValue: 1 << 1)
}

public struct VTInt32Point: Equatable, Hashable, Sendable {
    public var x: Int32
    public var y: Int32

    public init() {
        self.x = 0
        self.y = 0
    }

    public init(x: Int32, y: Int32) {
        self.x = x
        self.y = y
    }
}

public struct VTInt32Size: Equatable, Hashable, Sendable {
    public var width: Int32
    public var height: Int32

    public init() {
        self.width = 0
        self.height = 0
    }

    public init(width: Int32, height: Int32) {
        self.width = width
        self.height = height
    }
}

public struct VTHDRPerFrameMetadataGenerationHDRFormatType: RawRepresentable, Hashable, Sendable {
    public var rawValue: CFString

    public init(rawValue: CFString) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: CFString) {
        self.rawValue = rawValue
    }
}

public typealias VTCompressionOutputCallback = (
    UnsafeMutableRawPointer?,
    UnsafeMutableRawPointer?,
    OSStatus,
    VTEncodeInfoFlags,
    CMSampleBuffer?
) -> Void

public typealias VTCompressionOutputHandler = (
    OSStatus,
    VTEncodeInfoFlags,
    CMSampleBuffer?
) -> Void

public typealias VTDecompressionOutputCallback = (
    UnsafeMutableRawPointer?,
    UnsafeMutableRawPointer?,
    OSStatus,
    VTDecodeInfoFlags,
    CVImageBuffer?,
    CMTime,
    CMTime
) -> Void

public typealias VTDecompressionOutputHandler = (
    OSStatus,
    VTDecodeInfoFlags,
    CVImageBuffer?,
    CMTime,
    CMTime
) -> Void

public typealias VTDecompressionMultiImageCapableOutputHandler = (
    OSStatus,
    VTDecodeInfoFlags,
    CVImageBuffer?,
    __CMTaggedBufferGroup?,
    CMTime,
    CMTime
) -> Void

public typealias VTDecompressionOutputMultiImageCallback = (
    UnsafeMutableRawPointer?,
    UnsafeMutableRawPointer?,
    OSStatus,
    VTDecodeInfoFlags,
    __CMTaggedBufferGroup?,
    CMTime,
    CMTime
) -> Void

public typealias VTMotionEstimationOutputHandler = (
    OSStatus,
    __VTMotionEstimationInfoFlags,
    CFDictionary?,
    CVPixelBuffer?
) -> Void

public struct VTDecompressionOutputCallbackRecord {
    public var decompressionOutputCallback: VTDecompressionOutputCallback?
    public var decompressionOutputRefCon: UnsafeMutableRawPointer?

    public init() {
        self.decompressionOutputCallback = nil
        self.decompressionOutputRefCon = nil
    }

    public init(
        decompressionOutputCallback: VTDecompressionOutputCallback?,
        decompressionOutputRefCon: UnsafeMutableRawPointer?
    ) {
        self.decompressionOutputCallback = decompressionOutputCallback
        self.decompressionOutputRefCon = decompressionOutputRefCon
    }
}
