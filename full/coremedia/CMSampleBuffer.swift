import CoreFoundation
import Foundation

public final class CMSampleBuffer: CMAttachmentBearerProtocol, @unchecked Sendable {
    public struct Error {
        public static let allocationFailed = cmNSError(code: -12730)
        public static let requiredParameterMissing = cmNSError(code: -12731)
        public static let alreadyHasDataBuffer = cmNSError(code: -12732)
        public static let bufferNotReady = cmNSError(code: -12733)
        public static let sampleIndexOutOfRange = cmNSError(code: -12734)
        public static let bufferHasNoSampleSizes = cmNSError(code: -12735)
        public static let bufferHasNoSampleTimingInfo = cmNSError(code: -12736)
        public static let arrayTooSmall = cmNSError(code: -12737)
        public static let invalidEntryCount = cmNSError(code: -12738)
        public static let cannotSubdivide = cmNSError(code: -12739)
        public static let sampleTimingInfoInvalid = cmNSError(code: -12740)
        public static let invalidMediaTypeForOperation = cmNSError(code: -12741)
        public static let invalidSampleData = cmNSError(code: -12742)
        public static let invalidMediaFormat = cmNSError(code: -12743)
        public static let invalidated = cmNSError(code: -12744)
    }

    public struct Flags: OptionSet, Sendable, Hashable {
        public let rawValue: UInt32
        public init(rawValue: UInt32) { self.rawValue = rawValue }
    }

    public typealias T = CMSampleBuffer

    private static let processTypeID: CFTypeID = 0x434D_5342
    public static var typeID: CFTypeID { processTypeID }

    private let lock = CMUnfairLock()
    private var valid = true
    private var ready: Bool
    private var invalidateHandler: CMSampleBufferInvalidateHandler?
    private var invalidateCallback: CMSampleBufferInvalidateCallback?
    private var invalidateRefcon: UInt64 = 0
    private var invalidateFired = false
    fileprivate var ownedDataBuffer: CMBlockBuffer?
    fileprivate var ownedFormat: CMFormatDescription?
    fileprivate var timings: [CMSampleTimingInfo]
    fileprivate var sizes: [Int]
    fileprivate var sampleCount: Int
    public var attachments = CMAttachmentBearerAttachments()
    public var sampleAttachments: [[String: Any]] = []

    public init(
        dataBuffer: CMBlockBuffer?,
        formatDescription: CMFormatDescription?,
        numSamples: Int,
        sampleTimings: [CMSampleTimingInfo],
        sampleSizes: [Int],
        dataReady: Bool = true
    ) throws {
        if numSamples < 0 { throw Error.invalidEntryCount }
        if !sampleTimings.isEmpty && sampleTimings.count != 1 && sampleTimings.count != numSamples {
            throw Error.invalidEntryCount
        }
        if !sampleSizes.isEmpty && sampleSizes.count != 1 && sampleSizes.count != numSamples {
            throw Error.invalidEntryCount
        }
        self.ownedDataBuffer = dataBuffer
        self.ownedFormat = formatDescription
        self.sampleCount = numSamples
        self.timings = sampleTimings
        self.sizes = sampleSizes
        self.ready = dataReady
        if numSamples > 0 {
            self.sampleAttachments = Array(repeating: [:], count: numSamples)
        }
    }

    public var isValid: Bool {
        lock.locked { valid }
    }

    public var dataIsReady: Bool {
        lock.locked { valid && ready }
    }

    public var numSamples: Int {
        lock.locked { valid ? sampleCount : 0 }
    }

    public var dataBuffer: CMBlockBuffer? {
        lock.locked { valid ? ownedDataBuffer : nil }
    }

    public var formatDescription: CMFormatDescription? {
        lock.locked { valid ? ownedFormat : nil }
    }

    public var duration: CMTime {
        lock.locked { valid ? cmTotalDuration(timings, count: sampleCount) : .invalid }
    }

    public var presentationTimeStamp: CMTime {
        lock.locked {
            guard valid, let first = timings.first else { return .invalid }
            return first.presentationTimeStamp
        }
    }

    public var decodeTimeStamp: CMTime {
        lock.locked {
            guard valid, let first = timings.first else { return .invalid }
            if first.decodeTimeStamp.isValid { return first.decodeTimeStamp }
            return first.presentationTimeStamp
        }
    }

    public var outputPresentationTimeStamp: CMTime { presentationTimeStamp }

    public var totalSampleSize: Int {
        lock.locked {
            guard valid else { return 0 }
            if sizes.isEmpty { return ownedDataBuffer?.dataLength ?? 0 }
            if sizes.count == 1 { return sizes[0] * sampleCount }
            return sizes.reduce(0, +)
        }
    }

    public func invalidate() {
        var handler: CMSampleBufferInvalidateHandler?
        var callback: CMSampleBufferInvalidateCallback?
        var refcon: UInt64 = 0
        lock.locked {
            valid = false
            ready = false
            guard !invalidateFired else { return }
            invalidateFired = true
            handler = invalidateHandler
            callback = invalidateCallback
            refcon = invalidateRefcon
        }
        handler?(self)
        callback?(self, refcon)
    }

    public func setInvalidateHandler(_ handler: @escaping CMSampleBufferInvalidateHandler) {
        lock.locked { invalidateHandler = handler }
    }

    public func setInvalidateCallback(
        _ callback: @escaping CMSampleBufferInvalidateCallback,
        refcon: UInt64
    ) {
        lock.locked {
            invalidateCallback = callback
            invalidateRefcon = refcon
        }
    }

    public func makeDataReady() throws {
        try lock.locked {
            if !valid { throw Error.invalidated }
            ready = true
        }
    }

    public func sampleTimingInfo(at index: Int) throws -> CMSampleTimingInfo {
        try lock.locked {
            if !valid { throw Error.invalidated }
            if timings.isEmpty { throw Error.bufferHasNoSampleTimingInfo }
            if index < 0 || index >= sampleCount { throw Error.sampleIndexOutOfRange }
            if timings.count == 1 { return timings[0] }
            return timings[index]
        }
    }

    public func sampleSize(at index: Int) throws -> Int {
        try lock.locked {
            if !valid { throw Error.invalidated }
            if sizes.isEmpty { throw Error.bufferHasNoSampleSizes }
            if index < 0 || index >= sampleCount { throw Error.sampleIndexOutOfRange }
            if sizes.count == 1 { return sizes[0] }
            return sizes[index]
        }
    }

    public func copyDataBytes() throws -> Data {
        try lock.locked {
            if !valid { throw Error.invalidated }
            if !ready { throw Error.bufferNotReady }
            guard let buffer = ownedDataBuffer else { throw Error.requiredParameterMissing }
            return try buffer.dataBytes()
        }
    }
}

public func CMSampleBufferGetPresentationTimeStamp(_ sbuf: CMSampleBuffer) -> CMTime {
    sbuf.presentationTimeStamp
}

public func CMSampleBufferGetDecodeTimeStamp(_ sbuf: CMSampleBuffer) -> CMTime {
    sbuf.decodeTimeStamp
}

public func CMSampleBufferGetDuration(_ sbuf: CMSampleBuffer) -> CMTime {
    sbuf.duration
}

public func CMSampleBufferGetNumSamples(_ sbuf: CMSampleBuffer) -> CMItemCount {
    CMItemCount(sbuf.numSamples)
}

public func CMSampleBufferIsValid(_ sbuf: CMSampleBuffer) -> Bool {
    sbuf.isValid
}

public func CMSampleBufferDataIsReady(_ sbuf: CMSampleBuffer) -> Bool {
    sbuf.dataIsReady
}

public func CMSampleBufferGetDataBuffer(_ sbuf: CMSampleBuffer) -> CMBlockBuffer? {
    sbuf.dataBuffer
}

public func CMSampleBufferGetFormatDescription(_ sbuf: CMSampleBuffer) -> CMFormatDescription? {
    sbuf.formatDescription
}

public func CMSampleBufferGetTotalSampleSize(_ sbuf: CMSampleBuffer) -> Int {
    sbuf.totalSampleSize
}

public func CMSampleBufferGetSampleSize(_ sbuf: CMSampleBuffer, at sampleIndex: CMItemIndex) -> Int {
    (try? sbuf.sampleSize(at: Int(sampleIndex))) ?? 0
}

public func CMSampleBufferGetTypeID() -> CFTypeID {
    CMSampleBuffer.typeID
}

public func CMSampleBufferGetOutputPresentationTimeStamp(_ sbuf: CMSampleBuffer) -> CMTime {
    sbuf.outputPresentationTimeStamp
}

private func cmTotalDuration(_ timings: [CMSampleTimingInfo], count: Int) -> CMTime {
    guard count > 0, let first = timings.first else { return .invalid }
    if timings.count == 1 {
        return CMTimeMultiply(first.duration, multiplier: Int32(count))
    }
    var total = CMTime.zero
    for timing in timings {
        total = CMTimeAdd(total, timing.duration)
    }
    return total
}
