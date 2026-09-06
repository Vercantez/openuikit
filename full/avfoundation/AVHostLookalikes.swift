import Foundation
#if canImport(CoreImage)
import CoreImage
#endif

public typealias OSType = UInt32

#if !canImport(CoreMedia)
/// Host-only CoreMedia lookalikes so isolated Linux compilation can type-check
/// AVFoundation signatures. These are not a CoreMedia module and are not Apple ABI.
public typealias CMTimeValue = Int64
public typealias CMTimeScale = Int32
public typealias CMTimeEpoch = Int64
public typealias CMPersistentTrackID = Int32
public typealias CMVideoCodecType = UInt32

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
    public static let indefinite = CMTime(value: 0, timescale: 0, flags: 17, epoch: 0)
    public static let positiveInfinity = CMTime(value: 0, timescale: 0, flags: 5, epoch: 0)
    public static let negativeInfinity = CMTime(value: 0, timescale: 0, flags: 9, epoch: 0)

    public var isValid: Bool { flags & 1 != 0 }
    public var seconds: Double {
        guard timescale != 0 else { return 0 }
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

    /// Half-open `[start, start+duration)` like CoreMedia `CMTimeRangeContainsTime`.
    /// A zero-duration range matches only its start instant so `setOpacity(_:at:)` ramps can be read back.
    public func containsTime(_ time: CMTime) -> Bool {
        guard start.isValid, duration.isValid, time.isValid else { return false }
        let t = time.seconds
        let s = start.seconds
        let d = duration.seconds
        if d == 0 { return abs(t - s) < 1e-9 }
        return t >= s && t < (s + d)
    }
}

public struct CMTimeMapping: Hashable, Sendable {
    public var source: CMTimeRange
    public var target: CMTimeRange

    public init(source: CMTimeRange, target: CMTimeRange) {
        self.source = source
        self.target = target
    }

    public init() {
        self.source = .zero
        self.target = .zero
    }
}

public struct CMVideoDimensions: Hashable, Sendable {
    public var width: Int32
    public var height: Int32

    public init(width: Int32, height: Int32) {
        self.width = width
        self.height = height
    }
}

public struct CMTag: Hashable, Sendable {
    public var rawValue: UInt64
    public init(rawValue: UInt64) { self.rawValue = rawValue }
}

public struct CMStereoViewComponents: OptionSet, Hashable, Sendable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
}

public struct CMProjectionType: RawRepresentable, Hashable, Sendable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
}

open class CMSampleBuffer: NSObject, @unchecked Sendable {}
open class CMFormatDescription: NSObject, @unchecked Sendable {
    public struct Extensions: Sendable {
        public struct Value: Sendable {
            public struct CameraCalibrationDataLensCollection: Sendable {
                public init() {}
            }
            public init() {}
        }
        public init() {}
    }
}
open class CMAudioFormatDescription: CMFormatDescription, @unchecked Sendable {}
open class CMVideoFormatDescription: CMFormatDescription, @unchecked Sendable {}
open class CMMetadataFormatDescription: CMFormatDescription, @unchecked Sendable {}
open class CMClock: NSObject, @unchecked Sendable {}
open class CMTimebase: NSObject, @unchecked Sendable {}

public struct CMReadySampleBuffer<Content> {
    public var content: Content
    public init(content: Content) { self.content = content }
}

public struct CMTaggedBuffer<Content> {
    public var content: Content
    public init(content: Content) { self.content = content }
}

public struct CMTaggedDynamicBuffer: Sendable {
    public init() {}
}

extension CMSampleBuffer {
    public enum DynamicContent {}
}
#endif

#if !canImport(CoreVideo)
open class CVPixelBuffer: NSObject, @unchecked Sendable {}
open class CVMutablePixelBuffer: CVPixelBuffer, @unchecked Sendable {
    open class Pool: NSObject, @unchecked Sendable {}
}
open class CVReadOnlyPixelBuffer: NSObject, @unchecked Sendable {}
open class CVPixelBufferPool: NSObject, @unchecked Sendable {}

public struct CVPixelBufferCreationAttributes: Sendable {
    public init() {}
}

public struct CVPixelBufferAttributes: Sendable {
    public init() {}
}
#endif

#if !canImport(CoreGraphics)
open class CGImage: NSObject, @unchecked Sendable {}
open class CGColor: NSObject, @unchecked Sendable {}
open class CGContext: NSObject, @unchecked Sendable {}

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

public struct CGImagePropertyOrientation: RawRepresentable, Hashable, Sendable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
}
#endif

#if !canImport(CoreImage)
open class CIImage: NSObject, @unchecked Sendable {}
open class CIContext: NSObject, @unchecked Sendable {}
open class CIBarcodeDescriptor: NSObject, @unchecked Sendable {}
#endif

#if !canImport(QuartzCore)
/// Host-only QuartzCore lookalike so isolated Linux compilation can type-check
/// `AVPlayerLayer`. This is not a QuartzCore module and is not Apple ABI.
open class CALayer: NSObject, @unchecked Sendable {
    public var frame: CGRect = .zero
    public var bounds: CGRect = .zero
    public var position: CGPoint = .zero
    public var opacity: Float = 1
    public var isHidden: Bool = false
    public var backgroundColor: CGColor?
    public override init() { super.init() }
}
#endif

#if !canImport(AudioToolbox) && !canImport(CoreAudioTypes)
public typealias AudioFormatID = UInt32
public typealias AudioChannelLayoutTag = UInt32

public struct AudioAttributes: Sendable {
    public init() {}
}
#endif
