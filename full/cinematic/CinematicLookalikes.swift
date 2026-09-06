import Foundation

/// Isolated-host stand-ins for CoreMedia, CoreGraphics, CoreVideo, Metal, and
/// AVFoundation types. Cinematic's seed lists only Foundation; the sealed gate
/// cannot import those modules. These types are not ports of the real
/// frameworks and are compiled out when the genuine modules are imported.

public typealias OSType = UInt32

#if !canImport(CoreMedia)
public typealias CMTimeValue = Int64
public typealias CMTimeScale = Int32
public typealias CMTimeEpoch = Int64
public typealias CMPersistentTrackID = Int32

public struct CMTime: Hashable, Sendable, Comparable {
    public var value: CMTimeValue
    public var timescale: CMTimeScale
    public var flags: UInt32
    public var epoch: CMTimeEpoch

    public init(
        value: CMTimeValue,
        timescale: CMTimeScale,
        flags: UInt32 = 1,
        epoch: CMTimeEpoch = 0
    ) {
        self.value = value
        self.timescale = timescale
        self.flags = flags
        self.epoch = epoch
    }

    public init(seconds: Double, preferredTimescale: CMTimeScale) {
        if preferredTimescale <= 0 {
            self = .invalid
            return
        }
        self.init(
            value: CMTimeValue((seconds * Double(preferredTimescale)).rounded()),
            timescale: preferredTimescale
        )
    }

    public static let zero = CMTime(value: 0, timescale: 1)
    public static let invalid = CMTime(value: 0, timescale: 0, flags: 0, epoch: 0)

    public var isValid: Bool { flags & 1 != 0 && timescale != 0 }

    public var seconds: Double {
        guard isValid else { return .nan }
        return Double(value) / Double(timescale)
    }

    public static func < (lhs: CMTime, rhs: CMTime) -> Bool {
        lhs.seconds < rhs.seconds
    }
}

public struct CMTimeRange: Hashable, Sendable {
    public var start: CMTime
    public var duration: CMTime

    public init(start: CMTime, duration: CMTime) {
        self.start = start
        self.duration = duration
    }

    public static let zero = CMTimeRange(start: .zero, duration: .zero)
    public static let invalid = CMTimeRange(start: .invalid, duration: .invalid)

    public var end: CMTime {
        guard start.isValid, duration.isValid else { return .invalid }
        return CMTime(
            seconds: start.seconds + duration.seconds,
            preferredTimescale: start.timescale == 0 ? 1 : start.timescale
        )
    }

    /// Half-open containment matching CoreMedia's usual `CMTimeRangeContainsTime`.
    public func containsTime(_ time: CMTime) -> Bool {
        guard time.isValid, start.isValid, duration.isValid else { return false }
        let t = time.seconds
        let s = start.seconds
        let e = s + duration.seconds
        return t >= s && t < e
    }
}

open class CMSampleBuffer: NSObject, @unchecked Sendable {}
#endif

#if !canImport(CoreGraphics)
public struct CGAffineTransform: Hashable, Sendable {
    public var a: CGFloat
    public var b: CGFloat
    public var c: CGFloat
    public var d: CGFloat
    public var tx: CGFloat
    public var ty: CGFloat

    public init(
        a: CGFloat = 1,
        b: CGFloat = 0,
        c: CGFloat = 0,
        d: CGFloat = 1,
        tx: CGFloat = 0,
        ty: CGFloat = 0
    ) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.tx = tx
        self.ty = ty
    }

    public static let identity = CGAffineTransform()
}
#endif

#if !canImport(CoreVideo)
open class CVPixelBuffer: NSObject, @unchecked Sendable {
    public var width: Int
    public var height: Int
    public var pixelFormatType: OSType
    public var floatSamples: [Float]

    public init(
        width: Int = 0,
        height: Int = 0,
        pixelFormatType: OSType = 0,
        floatSamples: [Float] = []
    ) {
        self.width = width
        self.height = height
        self.pixelFormatType = pixelFormatType
        self.floatSamples = floatSamples
        super.init()
    }
}

public typealias CVBuffer = CVPixelBuffer
#endif

#if !canImport(Metal)
public protocol MTLCommandQueue: AnyObject {}
public protocol MTLCommandBuffer: AnyObject {}
public protocol MTLTexture: AnyObject {}

/// Isolated-host Metal command-queue token. It does not encode GPU work.
public final class CNHostMTLCommandQueue: MTLCommandQueue {
    public init() {}
}

public final class CNHostMTLCommandBuffer: MTLCommandBuffer {
    public init() {}
}

public final class CNHostMTLTexture: MTLTexture {
    public init() {}
}
#endif

#if !canImport(AVFoundation)
open class AVAsset: NSObject, @unchecked Sendable {
    public let url: URL?

    public init(url: URL? = nil) {
        self.url = url
        super.init()
    }
}

open class AVAssetTrack: NSObject, @unchecked Sendable {
    public let trackID: CMPersistentTrackID
    public let mediaType: String

    public init(trackID: CMPersistentTrackID = 1, mediaType: String = "vide") {
        self.trackID = trackID
        self.mediaType = mediaType
        super.init()
    }
}

open class AVMutableComposition: AVAsset, @unchecked Sendable {
    public override init(url: URL? = nil) {
        super.init(url: url)
    }
}

open class AVTimedMetadataGroup: NSObject, @unchecked Sendable {
    public override init() { super.init() }
}

open class AVAudioMix: NSObject, @unchecked Sendable {
    public override init() { super.init() }
}
#endif
