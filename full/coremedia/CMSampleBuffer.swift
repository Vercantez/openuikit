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
        public static let dataFailed = cmNSError(code: Int(kCMSampleBufferError_DataFailed))
        public static let dataCanceled = cmNSError(code: Int(kCMSampleBufferError_DataCanceled))
    }

    public struct Flags: OptionSet, Sendable, Hashable {
        public let rawValue: UInt32
        public init(rawValue: UInt32) { self.rawValue = rawValue }
        public static let audioBufferListAssure16ByteAlignment = Flags(
            rawValue: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment
        )
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
    fileprivate var makeDataReadyCallback: CMSampleBufferMakeDataReadyCallback?
    fileprivate var makeDataReadyRefcon: UnsafeMutableRawPointer?
    fileprivate var ownedDataBuffer: CMBlockBuffer?
    fileprivate var ownedFormat: CMFormatDescription?
    fileprivate var timings: [CMSampleTimingInfo]
    fileprivate var sizes: [Int]
    fileprivate var sampleCount: Int
    public var attachments = CMAttachmentBearerAttachments()
    public var sampleAttachments: [[String: Any]] = []
    fileprivate var dataFailedStatus: OSStatus? = nil
    fileprivate var sampleAttachmentArray: NSMutableArray?

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

    public var outputPresentationTimeStamp: CMTime {
        get {
            lock.locked { valid ? (outputPTS ?? presentationTimeStampUnlocked()) : .invalid }
        }
        set {
            lock.locked { outputPTS = newValue }
        }
    }

    public var outputDuration: CMTime { duration }
    public var outputDecodeTimeStamp: CMTime { decodeTimeStamp }

    internal func replaceTimingField(_ keyPath: WritableKeyPath<CMSampleTimingInfo, CMTime>, with time: CMTime) {
        lock.locked {
            if timings.isEmpty {
                var info = CMSampleTimingInfo.invalid
                info[keyPath: keyPath] = time
                timings = [info]
            } else {
                timings[0][keyPath: keyPath] = time
            }
        }
    }

    private var outputPTS: CMTime?

    public init(referencing object: CMSampleBuffer) throws {
        self.ownedDataBuffer = object.ownedDataBuffer
        self.ownedFormat = object.ownedFormat
        self.sampleCount = object.sampleCount
        self.timings = object.timings
        self.sizes = object.sizes
        self.ready = object.ready
        self.valid = object.valid
        self.attachments = object.attachments
        self.sampleAttachments = object.sampleAttachments
        self.outputPTS = object.outputPTS
        self.dataFailedStatus = object.dataFailedStatus
        self.sampleAttachmentArray = object.sampleAttachmentArray
    }

    internal func applyDataFailed(_ status: OSStatus) {
        lock.locked {
            dataFailedStatus = status
            ready = false
        }
    }

    internal func currentDataFailedStatus() -> OSStatus? {
        lock.locked { dataFailedStatus }
    }

    internal func sampleAttachmentsArray(createIfNecessary: Bool) -> CFArray? {
        lock.locked {
            if sampleAttachmentArray == nil && createIfNecessary {
                let array = NSMutableArray()
                let n = max(0, sampleCount)
                for _ in 0..<n {
                    array.add(NSMutableDictionary())
                }
                sampleAttachmentArray = array
            }
            return sampleAttachmentArray.map { unsafeBitCast($0, to: CFArray.self) }
        }
    }

    private func presentationTimeStampUnlocked() -> CMTime {
        guard valid, let first = timings.first else { return .invalid }
        return first.presentationTimeStamp
    }

    public var totalSampleSize: Int {
        lock.locked {
            guard valid else { return 0 }
            if sizes.isEmpty { return ownedDataBuffer?.dataLength ?? 0 }
            if sizes.count == 1 { return sizes[0] * sampleCount }
            return sizes.reduce(0, +)
        }
    }

    public func setOutputPresentationTimeStamp(_ pts: CMTime) throws {
        if !isValid { throw Error.invalidated }
        outputPresentationTimeStamp = pts
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
        var callback: CMSampleBufferMakeDataReadyCallback?
        var refcon: UnsafeMutableRawPointer?
        try lock.locked {
            if !valid { throw Error.invalidated }
            callback = makeDataReadyCallback
            refcon = makeDataReadyRefcon
        }
        if let callback {
            let status = callback(self, refcon)
            if status != 0 {
                throw cmNSError(code: Int(status))
            }
        }
        try lock.locked {
            if !valid { throw Error.invalidated }
            ready = true
        }
    }

    fileprivate func installMakeDataReadyCallback(
        _ callback: CMSampleBufferMakeDataReadyCallback?,
        refcon: UnsafeMutableRawPointer?
    ) {
        lock.locked {
            makeDataReadyCallback = callback
            makeDataReadyRefcon = refcon
        }
    }

    func forceNotReady() {
        lock.locked { ready = false }
    }

    fileprivate func replaceDataBuffer(_ buffer: CMBlockBuffer) -> OSStatus {
        lock.locked {
            if !valid { return kCMSampleBufferError_Invalidated }
            if ownedDataBuffer != nil { return kCMSampleBufferError_AlreadyHasDataBuffer }
            ownedDataBuffer = buffer
            return 0
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

    internal func copyTimingsAndSizes() -> (timings: [CMSampleTimingInfo], sizes: [Int], count: Int) {
        lock.locked { (timings, sizes, sampleCount) }
    }

    internal func replaceTimings(_ newTimings: [CMSampleTimingInfo]) {
        lock.locked { timings = newTimings }
    }

    internal func slicedCopy(location: Int, length: Int) throws -> CMSampleBuffer {
        try lock.locked {
            if !valid { throw Error.invalidated }
            if location < 0 || length < 0 || location + length > sampleCount {
                throw Error.sampleIndexOutOfRange
            }
            var slicedTimings: [CMSampleTimingInfo] = []
            if !timings.isEmpty {
                if timings.count == 1 {
                    slicedTimings = [timings[0]]
                } else {
                    slicedTimings = Array(timings[location..<(location + length)])
                }
            }
            var slicedSizes: [Int] = []
            if !sizes.isEmpty {
                if sizes.count == 1 {
                    slicedSizes = [sizes[0]]
                } else {
                    slicedSizes = Array(sizes[location..<(location + length)])
                }
            }
            return try CMSampleBuffer(
                dataBuffer: ownedDataBuffer,
                formatDescription: ownedFormat,
                numSamples: length,
                sampleTimings: slicedTimings,
                sampleSizes: slicedSizes,
                dataReady: ready
            )
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

public func CMSampleBufferSetOutputPresentationTimeStamp(_ sbuf: CMSampleBuffer, newValue: CMTime) -> OSStatus {
    do {
        try sbuf.setOutputPresentationTimeStamp(newValue)
        return 0
    } catch {
        return kCMSampleBufferError_Invalidated
    }
}

public func CMSampleBufferCreateReady(
    allocator: CFAllocator?,
    dataBuffer: CMBlockBuffer?,
    formatDescription: CMFormatDescription?,
    sampleCount: CMItemCount,
    sampleTimingEntryCount: CMItemCount,
    sampleTimingArray: UnsafePointer<CMSampleTimingInfo>?,
    sampleSizeEntryCount: CMItemCount,
    sampleSizeArray: UnsafePointer<Int>?,
    sampleBufferOut: UnsafeMutablePointer<CMSampleBuffer?>
) -> OSStatus {
    _ = allocator
    var timings: [CMSampleTimingInfo] = []
    if let sampleTimingArray, sampleTimingEntryCount > 0 {
        timings = Array(UnsafeBufferPointer(start: sampleTimingArray, count: Int(sampleTimingEntryCount)))
    }
    var sizes: [Int] = []
    if let sampleSizeArray, sampleSizeEntryCount > 0 {
        sizes = Array(UnsafeBufferPointer(start: sampleSizeArray, count: Int(sampleSizeEntryCount)))
    }
    do {
        let sample = try CMSampleBuffer(
            dataBuffer: dataBuffer,
            formatDescription: formatDescription,
            numSamples: Int(sampleCount),
            sampleTimings: timings,
            sampleSizes: sizes,
            dataReady: true
        )
        sampleBufferOut.pointee = sample
        return 0
    } catch {
        sampleBufferOut.pointee = nil
        return kCMSampleBufferError_InvalidEntryCount
    }
}

public func CMSampleBufferCreate(
    allocator: CFAllocator?,
    dataBuffer: CMBlockBuffer?,
    dataReady: Bool,
    makeDataReadyCallback: CMSampleBufferMakeDataReadyCallback?,
    makeDataReadyRefcon: UnsafeMutableRawPointer?,
    formatDescription: CMFormatDescription?,
    sampleCount: CMItemCount,
    sampleTimingEntryCount: CMItemCount,
    sampleTimingArray: UnsafePointer<CMSampleTimingInfo>?,
    sampleSizeEntryCount: CMItemCount,
    sampleSizeArray: UnsafePointer<Int>?,
    sampleBufferOut: UnsafeMutablePointer<CMSampleBuffer?>
) -> OSStatus {
    let status = CMSampleBufferCreateReady(
        allocator: allocator,
        dataBuffer: dataBuffer,
        formatDescription: formatDescription,
        sampleCount: sampleCount,
        sampleTimingEntryCount: sampleTimingEntryCount,
        sampleTimingArray: sampleTimingArray,
        sampleSizeEntryCount: sampleSizeEntryCount,
        sampleSizeArray: sampleSizeArray,
        sampleBufferOut: sampleBufferOut
    )
    if status == 0, let sample = sampleBufferOut.pointee {
        sample.installMakeDataReadyCallback(makeDataReadyCallback, refcon: makeDataReadyRefcon)
        if !dataReady {
            sample.forceNotReady()
        }
    }
    return status
}

public func CMSampleBufferCreateCopy(
    allocator: CFAllocator?,
    sampleBuffer sbuf: CMSampleBuffer,
    sampleBufferOut: UnsafeMutablePointer<CMSampleBuffer?>
) -> OSStatus {
    _ = allocator
    do {
        sampleBufferOut.pointee = try CMSampleBuffer(referencing: sbuf)
        return 0
    } catch {
        sampleBufferOut.pointee = nil
        return kCMSampleBufferError_AllocationFailed
    }
}

public func CMSampleBufferInvalidate(_ sbuf: CMSampleBuffer) -> OSStatus {
    sbuf.invalidate()
    return 0
}

public func CMSampleBufferMakeDataReady(_ sbuf: CMSampleBuffer) -> OSStatus {
    do {
        try sbuf.makeDataReady()
        return 0
    } catch {
        return kCMSampleBufferError_Invalidated
    }
}

public func CMSampleBufferSetDataReady(_ sbuf: CMSampleBuffer) -> OSStatus {
    CMSampleBufferMakeDataReady(sbuf)
}

public func CMSampleBufferGetSampleTimingInfo(
    _ sbuf: CMSampleBuffer,
    at sampleIndex: CMItemIndex,
    timingInfoOut: UnsafeMutablePointer<CMSampleTimingInfo>
) -> OSStatus {
    do {
        timingInfoOut.pointee = try sbuf.sampleTimingInfo(at: Int(sampleIndex))
        return 0
    } catch let error as NSError {
        return OSStatus(error.code)
    } catch {
        return kCMSampleBufferError_SampleIndexOutOfRange
    }
}

public func CMSampleBufferGetSampleSizeArray(
    _ sbuf: CMSampleBuffer,
    sizeArrayEntries: CMItemCount,
    sizeArrayOut: UnsafeMutablePointer<Int>?,
    sizeArrayEntriesNeededOut: UnsafeMutablePointer<CMItemCount>?
) -> OSStatus {
    let count = sbuf.numSamples
    sizeArrayEntriesNeededOut?.pointee = CMItemCount(count)
    if count == 0 { return 0 }
    if sizeArrayEntries < count { return kCMSampleBufferError_ArrayTooSmall }
    guard let sizeArrayOut else { return kCMSampleBufferError_RequiredParameterMissing }
    for index in 0..<count {
        sizeArrayOut.advanced(by: index).pointee = (try? sbuf.sampleSize(at: index)) ?? 0
    }
    return 0
}

public func CMSampleBufferSetDataBuffer(_ sbuf: CMSampleBuffer, dataBuffer: CMBlockBuffer) -> OSStatus {
    sbuf.replaceDataBuffer(dataBuffer)
}

public func CMSetAttachment(
    _ target: CMAttachmentBearer,
    key: CFString,
    value: CFTypeRef?,
    attachmentMode: CMAttachmentMode
) {
    guard let bearer = target as? CMAttachmentBearerProtocol else { return }
    let name = unsafeBitCast(key, to: NSString.self) as String
    guard let value else {
        bearer.attachments[name] = nil
        return
    }
    if attachmentMode == kCMAttachmentMode_ShouldPropagate {
        bearer.attachments[name] = .shouldPropagate(value)
    } else {
        bearer.attachments[name] = .shouldNotPropagate(value)
    }
}

public func CMGetAttachment(
    _ target: CMAttachmentBearer,
    key: CFString,
    attachmentModeOut: UnsafeMutablePointer<CMAttachmentMode>?
) -> CFTypeRef? {
    guard let bearer = target as? CMAttachmentBearerProtocol else { return nil }
    let name = unsafeBitCast(key, to: NSString.self) as String
    guard let entry = bearer.attachments[name] else { return nil }
    attachmentModeOut?.pointee = entry.mode.rawValue
    return entry.value as CFTypeRef
}

public func CMRemoveAttachment(_ target: CMAttachmentBearer, key: CFString) {
    guard let bearer = target as? CMAttachmentBearerProtocol else { return }
    let name = unsafeBitCast(key, to: NSString.self) as String
    bearer.attachments[name] = nil
}

public func CMRemoveAllAttachments(_ target: CMAttachmentBearer) {
    guard let bearer = target as? CMAttachmentBearerProtocol else { return }
    bearer.attachments.removeAll()
}

public func CMPropagateAttachments(_ source: CMAttachmentBearer, destination: CMAttachmentBearer) {
    guard let src = source as? CMAttachmentBearerProtocol,
          let dst = destination as? CMAttachmentBearerProtocol
    else { return }
    src.propagateAttachments(to: dst)
}

public func CMSetAttachments(
    _ target: CMAttachmentBearer,
    attachments theAttachments: CFDictionary,
    attachmentMode: CMAttachmentMode
) {
    let count = Int(CFDictionaryGetCount(theAttachments))
    if count <= 0 { return }
    var keys = Array<UnsafeRawPointer?>(repeating: nil, count: count)
    var values = Array<UnsafeRawPointer?>(repeating: nil, count: count)
    keys.withUnsafeMutableBufferPointer { keyBuf in
        values.withUnsafeMutableBufferPointer { valBuf in
            CFDictionaryGetKeysAndValues(theAttachments, keyBuf.baseAddress, valBuf.baseAddress)
        }
    }
    for index in 0..<count {
        guard let keyPtr = keys[index], let valPtr = values[index] else { continue }
        CMSetAttachment(
            target,
            key: unsafeBitCast(keyPtr, to: CFString.self),
            value: unsafeBitCast(valPtr, to: CFTypeRef.self),
            attachmentMode: attachmentMode
        )
    }
}

public func CMCopyDictionaryOfAttachments(
    allocator: CFAllocator?,
    target: CMAttachmentBearer,
    attachmentMode: CMAttachmentMode
) -> CFDictionary? {
    _ = allocator
    guard let bearer = target as? CMAttachmentBearerProtocol else { return nil }
    let map = attachmentMode == kCMAttachmentMode_ShouldPropagate
        ? bearer.attachments.propagated
        : bearer.attachments.nonPropagated
    var pairs: [(CFString, CFTypeRef)] = []
    for (key, value) in map {
        pairs.append((cmMakeCFString(key), value as CFTypeRef))
    }
    if pairs.isEmpty { return nil }
    return cmCFDictionary(pairs)
}

private func cmTotalDuration(_ timings: [CMSampleTimingInfo], count: Int) -> CMTime {
    guard let first = timings.first else { return .invalid }
    if count <= 0 {
        return first.duration
    }
    if timings.count == 1 {
        return CMTimeMultiply(first.duration, multiplier: Int32(count))
    }
    var total = CMTime.zero
    for timing in timings {
        total = CMTimeAdd(total, timing.duration)
    }
    return total
}
