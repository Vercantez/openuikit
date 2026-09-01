import Foundation

public enum CVAttachmentMode: UInt32, Sendable, Hashable {
    case shouldNotPropagate = 0
    case shouldPropagate = 1
}

public struct CVPixelBufferLockFlags: OptionSet, Sendable, Hashable {
    public let rawValue: CVOptionFlags
    public init(rawValue: CVOptionFlags) { self.rawValue = rawValue }
    public static let readOnly = CVPixelBufferLockFlags(rawValue: 0x0000_0001)
}

public struct CVPixelBufferPoolFlushFlags: OptionSet, Sendable, Hashable {
    public let rawValue: CVOptionFlags
    public init(rawValue: CVOptionFlags) { self.rawValue = rawValue }
    public static let excessBuffers = CVPixelBufferPoolFlushFlags(rawValue: 1)
}

public struct CVTimeFlags: OptionSet, Sendable, Hashable {
    public let rawValue: Int32
    public init(rawValue: Int32) { self.rawValue = rawValue }
    public static let isIndefinite = CVTimeFlags(rawValue: 1)
}

public struct CVSMPTETimeFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let valid = CVSMPTETimeFlags(rawValue: 1)
    public static let running = CVSMPTETimeFlags(rawValue: 2)
}

public struct CVTimeStampFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt64
    public init(rawValue: UInt64) { self.rawValue = rawValue }

    public static let videoTimeValid = CVTimeStampFlags(rawValue: 1 << 0)
    public static let hostTimeValid = CVTimeStampFlags(rawValue: 1 << 1)
    public static let smpteTimeValid = CVTimeStampFlags(rawValue: 1 << 2)
    public static let videoRefreshPeriodValid = CVTimeStampFlags(rawValue: 1 << 3)
    public static let rateScalarValid = CVTimeStampFlags(rawValue: 1 << 4)
    public static let topField = CVTimeStampFlags(rawValue: 1 << 5)
    public static let bottomField = CVTimeStampFlags(rawValue: 1 << 6)
    public static let videoHostTimeValid: CVTimeStampFlags = [.videoTimeValid, .hostTimeValid]
    public static let isInterlaced: CVTimeStampFlags = [.topField, .bottomField]
}

public enum CVSMPTETimeType: UInt32, Sendable, Hashable {
    case type24 = 0
    case type25 = 1
    case type30Drop = 2
    case type30 = 3
    case type2997 = 4
    case type2997Drop = 5
    case type60 = 6
    case type5994 = 7
}

public struct CVSMPTETime: Sendable, Equatable {
    public var subframes: Int16
    public var subframeDivisor: Int16
    public var counter: UInt32
    public var type: UInt32
    public var flags: UInt32
    public var hours: Int16
    public var minutes: Int16
    public var seconds: Int16
    public var frames: Int16

    public init(
        subframes: Int16,
        subframeDivisor: Int16,
        counter: UInt32,
        type: UInt32,
        flags: UInt32,
        hours: Int16,
        minutes: Int16,
        seconds: Int16,
        frames: Int16
    ) {
        self.subframes = subframes
        self.subframeDivisor = subframeDivisor
        self.counter = counter
        self.type = type
        self.flags = flags
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
        self.frames = frames
    }

    public init(
        subframes: Int16,
        subframeDivisor: Int16,
        counter: UInt32,
        type: CVSMPTETimeType,
        flags: CVSMPTETimeFlags,
        hours: Int16,
        minutes: Int16,
        seconds: Int16,
        frames: Int16
    ) {
        self.init(
            subframes: subframes,
            subframeDivisor: subframeDivisor,
            counter: counter,
            type: type.rawValue,
            flags: flags.rawValue,
            hours: hours,
            minutes: minutes,
            seconds: seconds,
            frames: frames
        )
    }

    public init() {
        self.init(
            subframes: 0,
            subframeDivisor: 0,
            counter: 0,
            type: 0,
            flags: 0,
            hours: 0,
            minutes: 0,
            seconds: 0,
            frames: 0
        )
    }

    public var flagOptions: CVSMPTETimeFlags {
        get { CVSMPTETimeFlags(rawValue: flags) }
        set { flags = newValue.rawValue }
    }

    public var typeOptions: CVSMPTETimeType {
        get { CVSMPTETimeType(rawValue: type) ?? .type24 }
        set { type = newValue.rawValue }
    }
}

public struct CVTime: Sendable, Equatable {
    public var timeValue: Int64
    public var timeScale: Int32
    public var flags: Int32

    public init(timeValue: Int64, timeScale: Int32, flags: Int32) {
        self.timeValue = timeValue
        self.timeScale = timeScale
        self.flags = flags
    }

    public init(timeValue: Int64, timeScale: Int32) {
        self.init(timeValue: timeValue, timeScale: timeScale, flags: 0)
    }

    public init() {
        self.init(timeValue: 0, timeScale: 0, flags: 0)
    }

    public var flagOptions: CVTimeFlags {
        get { CVTimeFlags(rawValue: flags) }
        set { flags = newValue.rawValue }
    }

    public static var zero: CVTime { CVTime(timeValue: 0, timeScale: 1, flags: 0) }
    public static var indefinite: CVTime {
        CVTime(timeValue: 0, timeScale: 0, flags: CVTimeFlags.isIndefinite.rawValue)
    }
}

public let kCVZeroTime = CVTime.zero
public let kCVIndefiniteTime = CVTime.indefinite

public struct CVTimeStamp: Sendable, Equatable {
    public var version: UInt32
    public var videoTimeScale: Int32
    public var videoTime: Int64
    public var hostTime: UInt64
    public var rateScalar: Double
    public var videoRefreshPeriod: Int64
    public var smpteTime: CVSMPTETime
    public var flags: UInt64
    public var reserved: UInt64

    public init(
        version: UInt32,
        videoTimeScale: Int32,
        videoTime: Int64,
        hostTime: UInt64,
        rateScalar: Double,
        videoRefreshPeriod: Int64,
        smpteTime: CVSMPTETime,
        flags: UInt64,
        reserved: UInt64
    ) {
        self.version = version
        self.videoTimeScale = videoTimeScale
        self.videoTime = videoTime
        self.hostTime = hostTime
        self.rateScalar = rateScalar
        self.videoRefreshPeriod = videoRefreshPeriod
        self.smpteTime = smpteTime
        self.flags = flags
        self.reserved = reserved
    }

    public init() {
        self.init(
            version: 0,
            videoTimeScale: 0,
            videoTime: 0,
            hostTime: 0,
            rateScalar: 1,
            videoRefreshPeriod: 0,
            smpteTime: CVSMPTETime(),
            flags: 0,
            reserved: 0
        )
    }

    public init(
        videoTime: CVTime? = nil,
        hostTime: UInt64? = nil,
        rateScaler: Double? = nil,
        videoRefreshPeriod: Int64? = nil,
        smpteTime: CVSMPTETime? = nil,
        topField: Bool = false,
        bottomField: Bool = false
    ) {
        var stamp = CVTimeStamp()
        var flags = CVTimeStampFlags()
        if let videoTime {
            stamp.videoTime = videoTime.timeValue
            stamp.videoTimeScale = videoTime.timeScale
            flags.insert(.videoTimeValid)
        }
        if let hostTime {
            stamp.hostTime = hostTime
            flags.insert(.hostTimeValid)
        }
        if let rateScaler {
            stamp.rateScalar = rateScaler
            flags.insert(.rateScalarValid)
        }
        if let videoRefreshPeriod {
            stamp.videoRefreshPeriod = videoRefreshPeriod
            flags.insert(.videoRefreshPeriodValid)
        }
        if let smpteTime {
            stamp.smpteTime = smpteTime
            flags.insert(.smpteTimeValid)
        }
        if topField { flags.insert(.topField) }
        if bottomField { flags.insert(.bottomField) }
        stamp.flags = flags.rawValue
        self = stamp
    }

    public var flagOptions: CVTimeStampFlags {
        get { CVTimeStampFlags(rawValue: flags) }
        set { flags = newValue.rawValue }
    }
}

public struct CVPlanarComponentInfo: Sendable, Equatable {
    public var offset: Int32
    public var rowBytes: UInt32
    public init(offset: Int32, rowBytes: UInt32) {
        self.offset = offset
        self.rowBytes = rowBytes
    }
    public init() { self.init(offset: 0, rowBytes: 0) }
}

public struct CVPlanarPixelBufferInfo: Sendable, Equatable {
    public var componentInfo: CVPlanarComponentInfo
    public init(componentInfo: CVPlanarComponentInfo) { self.componentInfo = componentInfo }
    public init() { self.init(componentInfo: CVPlanarComponentInfo()) }
}

public struct CVPlanarPixelBufferInfo_YCbCrBiPlanar: Sendable, Equatable {
    public var componentInfoY: CVPlanarComponentInfo
    public var componentInfoCbCr: CVPlanarComponentInfo
    public init(componentInfoY: CVPlanarComponentInfo, componentInfoCbCr: CVPlanarComponentInfo) {
        self.componentInfoY = componentInfoY
        self.componentInfoCbCr = componentInfoCbCr
    }
    public init() {
        self.init(componentInfoY: CVPlanarComponentInfo(), componentInfoCbCr: CVPlanarComponentInfo())
    }
}

public struct CVPlanarPixelBufferInfo_YCbCrPlanar: Sendable, Equatable {
    public var componentInfoY: CVPlanarComponentInfo
    public var componentInfoCb: CVPlanarComponentInfo
    public var componentInfoCr: CVPlanarComponentInfo
    public init(
        componentInfoY: CVPlanarComponentInfo,
        componentInfoCb: CVPlanarComponentInfo,
        componentInfoCr: CVPlanarComponentInfo
    ) {
        self.componentInfoY = componentInfoY
        self.componentInfoCb = componentInfoCb
        self.componentInfoCr = componentInfoCr
    }
    public init() {
        self.init(
            componentInfoY: CVPlanarComponentInfo(),
            componentInfoCb: CVPlanarComponentInfo(),
            componentInfoCr: CVPlanarComponentInfo()
        )
    }
}

public struct CVFillExtendedPixelsCallBackData {
    public var version: CFIndex
    public var fillCallBack: CVFillExtendedPixelsCallBack?
    public var refCon: UnsafeMutableRawPointer?
    public init(
        version: CFIndex,
        fillCallBack: CVFillExtendedPixelsCallBack?,
        refCon: UnsafeMutableRawPointer?
    ) {
        self.version = version
        self.fillCallBack = fillCallBack
        self.refCon = refCon
    }
    public init() { self.init(version: 0, fillCallBack: nil, refCon: nil) }
}

public let kCVReturnSuccess: CVReturn = 0
public let kCVReturnFirst: CVReturn = -6660
public let kCVReturnError: CVReturn = -6660
public let kCVReturnInvalidArgument: CVReturn = -6661
public let kCVReturnAllocationFailed: CVReturn = -6662
public let kCVReturnUnsupported: CVReturn = -6663
public let kCVReturnInvalidDisplay: CVReturn = -6670
public let kCVReturnDisplayLinkAlreadyRunning: CVReturn = -6671
public let kCVReturnDisplayLinkNotRunning: CVReturn = -6672
public let kCVReturnDisplayLinkCallbacksNotSet: CVReturn = -6673
public let kCVReturnInvalidPixelFormat: CVReturn = -6680
public let kCVReturnInvalidSize: CVReturn = -6681
public let kCVReturnInvalidPixelBufferAttributes: CVReturn = -6682
public let kCVReturnPixelBufferNotOpenGLCompatible: CVReturn = -6683
public let kCVReturnPixelBufferNotMetalCompatible: CVReturn = -6684
public let kCVReturnWouldExceedAllocationThreshold: CVReturn = -6689
public let kCVReturnPoolAllocationFailed: CVReturn = -6690
public let kCVReturnInvalidPoolAttributes: CVReturn = -6691
public let kCVReturnRetry: CVReturn = -6692
public let kCVReturnLast: CVReturn = -6699
