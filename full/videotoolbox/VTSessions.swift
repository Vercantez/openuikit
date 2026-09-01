private let kVTCompressionSessionTypeID: CFTypeID = 0x5654_4353
private let kVTDecompressionSessionTypeID: CFTypeID = 0x5654_4453
private let kVTFrameSiloTypeID: CFTypeID = 0x5654_4653
private let kVTMultiPassStorageTypeID: CFTypeID = 0x5654_4D50
private let kVTPixelRotationSessionTypeID: CFTypeID = 0x5654_5052
private let kVTPixelTransferSessionTypeID: CFTypeID = 0x5654_5054

private func _vtIdentityEquals<T: AnyObject>(_ left: T, _ right: T) -> Bool {
    left === right
}

private func _vtIdentityHash<T: AnyObject>(_ value: T, into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(value))
}

public final class VTCompressionSession: Equatable, Hashable, @unchecked Sendable {
    /// Inert Linux handle. `VTCompressionSessionCreate` does not succeed; operations
    /// on this object remain fail-closed.
    public init() {}

    public static func == (left: VTCompressionSession, right: VTCompressionSession) -> Bool {
        _vtIdentityEquals(left, right)
    }

    public func hash(into hasher: inout Hasher) {
        _vtIdentityHash(self, into: &hasher)
    }
}

public final class VTDecompressionSession: Equatable, Hashable, @unchecked Sendable {
    /// Inert Linux handle. `VTDecompressionSessionCreate` does not succeed.
    public init() {}

    public static func == (left: VTDecompressionSession, right: VTDecompressionSession) -> Bool {
        _vtIdentityEquals(left, right)
    }

    public func hash(into hasher: inout Hasher) {
        _vtIdentityHash(self, into: &hasher)
    }
}

public final class VTFrameSilo: Equatable, Hashable, @unchecked Sendable {
    /// Inert Linux handle. `VTFrameSiloCreate` does not succeed.
    public init() {}

    public static func == (left: VTFrameSilo, right: VTFrameSilo) -> Bool {
        _vtIdentityEquals(left, right)
    }

    public func hash(into hasher: inout Hasher) {
        _vtIdentityHash(self, into: &hasher)
    }
}

public final class VTMultiPassStorage: Equatable, Hashable, @unchecked Sendable {
    /// Inert Linux handle. `VTMultiPassStorageCreate` does not succeed.
    public init() {}

    public static func == (left: VTMultiPassStorage, right: VTMultiPassStorage) -> Bool {
        _vtIdentityEquals(left, right)
    }

    public func hash(into hasher: inout Hasher) {
        _vtIdentityHash(self, into: &hasher)
    }
}

public final class VTPixelRotationSession: Equatable, Hashable, @unchecked Sendable {
    /// Inert Linux handle. `VTPixelRotationSessionCreate` does not succeed.
    public init() {}

    public static func == (left: VTPixelRotationSession, right: VTPixelRotationSession) -> Bool {
        _vtIdentityEquals(left, right)
    }

    public func hash(into hasher: inout Hasher) {
        _vtIdentityHash(self, into: &hasher)
    }
}

public final class VTPixelTransferSession: Equatable, Hashable, @unchecked Sendable {
    /// Inert Linux handle. `VTPixelTransferSessionCreate` does not succeed.
    public init() {}

    public static func == (left: VTPixelTransferSession, right: VTPixelTransferSession) -> Bool {
        _vtIdentityEquals(left, right)
    }

    public func hash(into hasher: inout Hasher) {
        _vtIdentityHash(self, into: &hasher)
    }
}

public func VTCompressionSessionGetTypeID() -> CFTypeID { kVTCompressionSessionTypeID }
public func VTDecompressionSessionGetTypeID() -> CFTypeID { kVTDecompressionSessionTypeID }
public func VTFrameSiloGetTypeID() -> CFTypeID { kVTFrameSiloTypeID }
public func VTMultiPassStorageGetTypeID() -> CFTypeID { kVTMultiPassStorageTypeID }
public func VTPixelRotationSessionGetTypeID() -> CFTypeID { kVTPixelRotationSessionTypeID }
public func VTPixelTransferSessionGetTypeID() -> CFTypeID { kVTPixelTransferSessionTypeID }

public func VTIsHardwareDecodeSupported(_ codecType: CMVideoCodecType) -> Bool {
    _ = codecType
    return false
}

public func VTIsStereoMVHEVCDecodeSupported() -> Bool { false }
public func VTIsStereoMVHEVCEncodeSupported() -> Bool { false }

public func VTCopyVideoEncoderList(
    _ options: CFDictionary?,
    _ listOfVideoEncodersOut: UnsafeMutablePointer<CFArray?>
) -> OSStatus {
    _ = options
    listOfVideoEncodersOut.pointee = []
    return noErr
}

public func VTCopySupportedPropertyDictionaryForEncoder(
    width: Int32,
    height: Int32,
    codecType: CMVideoCodecType,
    encoderSpecification: CFDictionary?,
    encoderIDOut: UnsafeMutablePointer<CFString?>?,
    supportedPropertiesOut: UnsafeMutablePointer<CFDictionary?>?
) -> OSStatus {
    _ = (width, height, codecType, encoderSpecification)
    encoderIDOut?.pointee = nil
    supportedPropertiesOut?.pointee = nil
    return kVTCouldNotFindVideoEncoderErr
}

public func VTCompressionSessionCreate(
    allocator: CFAllocator?,
    width: Int32,
    height: Int32,
    codecType: CMVideoCodecType,
    encoderSpecification: CFDictionary?,
    imageBufferAttributes sourceImageBufferAttributes: CFDictionary?,
    compressedDataAllocator: CFAllocator?,
    outputCallback: VTCompressionOutputCallback?,
    refcon outputCallbackRefCon: UnsafeMutableRawPointer?,
    compressionSessionOut: UnsafeMutablePointer<VTCompressionSession?>
) -> OSStatus {
    _ = (
        allocator, width, height, codecType, encoderSpecification,
        sourceImageBufferAttributes, compressedDataAllocator, outputCallback,
        outputCallbackRefCon
    )
    compressionSessionOut.pointee = nil
    return kVTCouldNotFindVideoEncoderErr
}

public func VTCompressionSessionPrepareToEncodeFrames(
    _ session: VTCompressionSession
) -> OSStatus {
    _ = session
    return kVTCouldNotFindVideoEncoderErr
}

public func VTCompressionSessionEncodeFrame(
    _ session: VTCompressionSession,
    imageBuffer: CVImageBuffer,
    presentationTimeStamp: CMTime,
    duration: CMTime,
    frameProperties: CFDictionary?,
    sourceFrameRefcon: UnsafeMutableRawPointer?,
    infoFlagsOut: UnsafeMutablePointer<VTEncodeInfoFlags>?
) -> OSStatus {
    _ = (session, imageBuffer, presentationTimeStamp, duration, frameProperties, sourceFrameRefcon)
    infoFlagsOut?.pointee = []
    return kVTCouldNotFindVideoEncoderErr
}

public func VTCompressionSessionEncodeFrame(
    _ session: VTCompressionSession,
    imageBuffer: CVImageBuffer,
    presentationTimeStamp: CMTime,
    duration: CMTime,
    frameProperties: CFDictionary?,
    infoFlagsOut: UnsafeMutablePointer<VTEncodeInfoFlags>?,
    outputHandler: @escaping VTCompressionOutputHandler
) -> OSStatus {
    _ = (session, imageBuffer, presentationTimeStamp, duration, frameProperties)
    infoFlagsOut?.pointee = []
    outputHandler(kVTCouldNotFindVideoEncoderErr, [], nil)
    return kVTCouldNotFindVideoEncoderErr
}

public func VTCompressionSessionEncodeMultiImageFrame(
    _ session: VTCompressionSession,
    taggedBuffers: [CMTaggedBuffer],
    presentationTimeStamp: CMTime,
    duration: CMTime,
    frameProperties: CFDictionary?,
    infoFlagsOut: UnsafeMutablePointer<VTEncodeInfoFlags>?,
    outputHandler: @escaping VTCompressionOutputHandler
) -> OSStatus {
    _ = (session, taggedBuffers, presentationTimeStamp, duration, frameProperties)
    infoFlagsOut?.pointee = []
    outputHandler(kVTCouldNotOutputTaggedBufferGroupErr, [], nil)
    return kVTCouldNotOutputTaggedBufferGroupErr
}

public func VTCompressionSessionCompleteFrames(
    _ session: VTCompressionSession,
    untilPresentationTimeStamp completeUntilPresentationTimeStamp: CMTime
) -> OSStatus {
    _ = (session, completeUntilPresentationTimeStamp)
    return kVTCouldNotFindVideoEncoderErr
}

public func VTCompressionSessionBeginPass(
    _ session: VTCompressionSession,
    flags beginPassFlags: VTCompressionSessionOptionFlags,
    _ reserved: UnsafeMutablePointer<UInt32>?
) -> OSStatus {
    _ = (session, beginPassFlags)
    reserved?.pointee = 0
    return kVTCouldNotFindVideoEncoderErr
}

public func VTCompressionSessionEndPass(
    _ session: VTCompressionSession,
    furtherPassesRequestedOut: UnsafeMutablePointer<DarwinBoolean>?,
    _ reserved: UnsafeMutablePointer<UInt32>?
) -> OSStatus {
    _ = session
    furtherPassesRequestedOut?.pointee = false
    reserved?.pointee = 0
    return kVTCouldNotFindVideoEncoderErr
}

public func VTCompressionSessionGetTimeRangesForNextPass(
    _ session: VTCompressionSession,
    timeRangeCountOut: UnsafeMutablePointer<CMItemCount>,
    timeRangeArrayOut: UnsafeMutablePointer<UnsafePointer<CMTimeRange>?>
) -> OSStatus {
    _ = session
    timeRangeCountOut.pointee = 0
    timeRangeArrayOut.pointee = nil
    return kVTCouldNotFindVideoEncoderErr
}

public func VTCompressionSessionGetPixelBufferPool(
    _ session: VTCompressionSession
) -> CVPixelBufferPool? {
    _ = session
    return nil
}

public func VTCompressionSessionInvalidate(_ session: VTCompressionSession) {
    _ = session
}

public func VTDecompressionSessionCreate(
    allocator: CFAllocator?,
    formatDescription videoFormatDescription: CMVideoFormatDescription,
    decoderSpecification videoDecoderSpecification: CFDictionary?,
    imageBufferAttributes destinationImageBufferAttributes: CFDictionary?,
    outputCallback: UnsafePointer<VTDecompressionOutputCallbackRecord>?,
    decompressionSessionOut: UnsafeMutablePointer<VTDecompressionSession?>
) -> OSStatus {
    _ = (
        allocator, videoFormatDescription, videoDecoderSpecification,
        destinationImageBufferAttributes, outputCallback
    )
    decompressionSessionOut.pointee = nil
    return kVTCouldNotFindVideoDecoderErr
}

public func VTDecompressionSessionCreate(
    allocator: CFAllocator?,
    formatDescription videoFormatDescription: CMVideoFormatDescription,
    decoderSpecification videoDecoderSpecification: CFDictionary?,
    imageBufferAttributes destinationImageBufferAttributes: CFDictionary?,
    decompressionSessionOut: UnsafeMutablePointer<VTDecompressionSession?>
) -> OSStatus {
    return VTDecompressionSessionCreate(
        allocator: allocator,
        formatDescription: videoFormatDescription,
        decoderSpecification: videoDecoderSpecification,
        imageBufferAttributes: destinationImageBufferAttributes,
        outputCallback: nil,
        decompressionSessionOut: decompressionSessionOut
    )
}

public func VTDecompressionSessionDecodeFrame(
    _ session: VTDecompressionSession,
    sampleBuffer: CMSampleBuffer,
    flags decodeFlags: VTDecodeFrameFlags,
    frameRefcon sourceFrameRefCon: UnsafeMutableRawPointer?,
    infoFlagsOut: UnsafeMutablePointer<VTDecodeInfoFlags>?
) -> OSStatus {
    _ = (session, sampleBuffer, decodeFlags, sourceFrameRefCon)
    infoFlagsOut?.pointee = []
    return kVTCouldNotFindVideoDecoderErr
}

public func VTDecompressionSessionDecodeFrame(
    _ session: VTDecompressionSession,
    sampleBuffer: CMSampleBuffer,
    flags decodeFlags: VTDecodeFrameFlags,
    frameOptions: CFDictionary?,
    frameRefcon sourceFrameRefCon: UnsafeMutableRawPointer?,
    infoFlagsOut: UnsafeMutablePointer<VTDecodeInfoFlags>?
) -> OSStatus {
    _ = frameOptions
    return VTDecompressionSessionDecodeFrame(
        session,
        sampleBuffer: sampleBuffer,
        flags: decodeFlags,
        frameRefcon: sourceFrameRefCon,
        infoFlagsOut: infoFlagsOut
    )
}

public func VTDecompressionSessionDecodeFrame(
    _ session: VTDecompressionSession,
    sampleBuffer: CMSampleBuffer,
    flags decodeFlags: VTDecodeFrameFlags,
    infoFlagsOut: UnsafeMutablePointer<VTDecodeInfoFlags>?,
    outputHandler: @escaping VTDecompressionOutputHandler
) -> OSStatus {
    _ = (session, sampleBuffer, decodeFlags)
    infoFlagsOut?.pointee = []
    outputHandler(kVTCouldNotFindVideoDecoderErr, [], nil, .invalid, .invalid)
    return kVTCouldNotFindVideoDecoderErr
}

public func VTDecompressionSessionDecodeFrame(
    _ session: VTDecompressionSession,
    sampleBuffer: CMSampleBuffer,
    flags decodeFlags: VTDecodeFrameFlags,
    frameOptions: CFDictionary?,
    infoFlagsOut: UnsafeMutablePointer<VTDecodeInfoFlags>?,
    outputHandler: @escaping VTDecompressionOutputHandler
) -> OSStatus {
    _ = frameOptions
    return VTDecompressionSessionDecodeFrame(
        session,
        sampleBuffer: sampleBuffer,
        flags: decodeFlags,
        infoFlagsOut: infoFlagsOut,
        outputHandler: outputHandler
    )
}

public func VTDecompressionSessionDecodeFrame(
    _ session: VTDecompressionSession,
    sampleBuffer: CMSampleBuffer,
    flags decodeFlags: VTDecodeFrameFlags,
    infoFlagsOut: UnsafeMutablePointer<VTDecodeInfoFlags>?,
    completionHandler: @escaping (
        OSStatus, VTDecodeInfoFlags, CVImageBuffer?, [CMTaggedBuffer]?, CMTime, CMTime
    ) -> Void
) -> OSStatus {
    _ = (session, sampleBuffer, decodeFlags)
    infoFlagsOut?.pointee = []
    completionHandler(kVTCouldNotFindVideoDecoderErr, [], nil, nil, .invalid, .invalid)
    return kVTCouldNotFindVideoDecoderErr
}

public func VTDecompressionSessionFinishDelayedFrames(
    _ session: VTDecompressionSession
) -> OSStatus {
    _ = session
    return kVTCouldNotFindVideoDecoderErr
}

public func VTDecompressionSessionWaitForAsynchronousFrames(
    _ session: VTDecompressionSession
) -> OSStatus {
    _ = session
    return kVTCouldNotFindVideoDecoderErr
}

public func VTDecompressionSessionCanAcceptFormatDescription(
    _ session: VTDecompressionSession,
    formatDescription newFormatDesc: CMFormatDescription
) -> Bool {
    _ = (session, newFormatDesc)
    return false
}

public func VTDecompressionSessionCopyBlackPixelBuffer(
    _ session: VTDecompressionSession,
    pixelBufferOut: UnsafeMutablePointer<CVPixelBuffer?>
) -> OSStatus {
    _ = session
    pixelBufferOut.pointee = nil
    return kVTCouldNotFindVideoDecoderErr
}

public func VTDecompressionSessionInvalidate(_ session: VTDecompressionSession) {
    _ = session
}

public func VTFrameSiloCreate(
    allocator: CFAllocator?,
    fileURL: CFURL?,
    timeRange: CMTimeRange,
    options: CFDictionary?,
    frameSiloOut: UnsafeMutablePointer<VTFrameSilo?>
) -> OSStatus {
    _ = (allocator, fileURL, timeRange, options)
    frameSiloOut.pointee = nil
    return kVTCouldNotCreateInstanceErr
}

public func VTFrameSiloAddSampleBuffer(
    _ silo: VTFrameSilo,
    sampleBuffer: CMSampleBuffer
) -> OSStatus {
    _ = (silo, sampleBuffer)
    return kVTCouldNotCreateInstanceErr
}

public func VTFrameSiloCallBlockForEachSampleBuffer(
    _ silo: VTFrameSilo,
    in timeRange: CMTimeRange,
    handler: (CMSampleBuffer) -> OSStatus
) -> OSStatus {
    _ = (silo, timeRange, handler)
    return kVTCouldNotCreateInstanceErr
}

public func VTFrameSiloCallFunctionForEachSampleBuffer(
    _ silo: VTFrameSilo,
    in timeRange: CMTimeRange,
    refcon: UnsafeMutableRawPointer?,
    callback: (UnsafeMutableRawPointer?, CMSampleBuffer) -> OSStatus
) -> OSStatus {
    _ = (silo, timeRange, refcon, callback)
    return kVTCouldNotCreateInstanceErr
}

public func VTFrameSiloGetProgressOfCurrentPass(
    _ silo: VTFrameSilo,
    progressOut: UnsafeMutablePointer<Float32>
) -> OSStatus {
    _ = silo
    progressOut.pointee = 0
    return kVTCouldNotCreateInstanceErr
}

public func VTFrameSiloSetTimeRangesForNextPass(
    _ silo: VTFrameSilo,
    timeRangeCount: CMItemCount,
    timeRangeArray: UnsafePointer<CMTimeRange>
) -> OSStatus {
    _ = (silo, timeRangeCount, timeRangeArray)
    return kVTCouldNotCreateInstanceErr
}

public func VTMultiPassStorageCreate(
    allocator: CFAllocator?,
    fileURL: CFURL?,
    timeRange: CMTimeRange,
    options: CFDictionary?,
    multiPassStorageOut: UnsafeMutablePointer<VTMultiPassStorage?>
) -> OSStatus {
    _ = (allocator, fileURL, timeRange, options)
    multiPassStorageOut.pointee = nil
    return kVTCouldNotCreateInstanceErr
}

public func VTMultiPassStorageClose(_ multiPassStorage: VTMultiPassStorage) -> OSStatus {
    _ = multiPassStorage
    return noErr
}

public func VTPixelRotationSessionCreate(
    _ allocator: CFAllocator?,
    _ pixelRotationSessionOut: UnsafeMutablePointer<VTPixelRotationSession?>
) -> OSStatus {
    _ = allocator
    pixelRotationSessionOut.pointee = nil
    return kVTPixelRotationNotSupportedErr
}

public func VTPixelRotationSessionInvalidate(_ session: VTPixelRotationSession) {
    _ = session
}

public func VTPixelRotationSessionRotateImage(
    _ session: VTPixelRotationSession,
    _ sourceBuffer: CVPixelBuffer,
    _ destinationBuffer: CVPixelBuffer
) -> OSStatus {
    _ = (session, sourceBuffer, destinationBuffer)
    return kVTPixelRotationNotSupportedErr
}

public func VTPixelTransferSessionCreate(
    allocator: CFAllocator?,
    pixelTransferSessionOut: UnsafeMutablePointer<VTPixelTransferSession?>
) -> OSStatus {
    _ = allocator
    pixelTransferSessionOut.pointee = nil
    return kVTPixelTransferNotSupportedErr
}

public func VTPixelTransferSessionInvalidate(_ session: VTPixelTransferSession) {
    _ = session
}

public func VTPixelTransferSessionTransferImage(
    _ session: VTPixelTransferSession,
    from sourceBuffer: CVPixelBuffer,
    to destinationBuffer: CVPixelBuffer
) -> OSStatus {
    _ = (session, sourceBuffer, destinationBuffer)
    return kVTPixelTransferNotSupportedErr
}

public func VTCreateCGImageFromCVPixelBuffer(
    _ pixelBuffer: CVPixelBuffer,
    options: CFDictionary?,
    imageOut: UnsafeMutablePointer<CGImage?>
) -> OSStatus {
    _ = (pixelBuffer, options)
    imageOut.pointee = nil
    return kVTPixelTransferNotSupportedErr
}

public func VTSessionCopyProperty(
    _ session: VTSession,
    key propertyKey: CFString,
    allocator: CFAllocator?,
    valueOut propertyValueOut: UnsafeMutableRawPointer?
) -> OSStatus {
    _ = (session, propertyKey, allocator, propertyValueOut)
    return kVTPropertyNotSupportedErr
}

public func VTSessionCopySerializableProperties(
    _ session: VTSession,
    allocator: CFAllocator?,
    dictionaryOut: UnsafeMutablePointer<CFDictionary?>
) -> OSStatus {
    _ = (session, allocator)
    dictionaryOut.pointee = nil
    return kVTPropertyNotSupportedErr
}

public func VTSessionCopySupportedPropertyDictionary(
    _ session: VTSession,
    supportedPropertyDictionaryOut: UnsafeMutablePointer<CFDictionary?>
) -> OSStatus {
    _ = session
    supportedPropertyDictionaryOut.pointee = nil
    return kVTPropertyNotSupportedErr
}

public func VTSessionSetProperties(
    _ session: VTSession,
    propertyDictionary: CFDictionary
) -> OSStatus {
    _ = (session, propertyDictionary)
    return kVTPropertyNotSupportedErr
}

public func VTSessionSetProperty(
    _ session: VTSession,
    key propertyKey: CFString,
    value propertyValue: CFTypeRef?
) -> OSStatus {
    _ = (session, propertyKey, propertyValue)
    return kVTPropertyNotSupportedErr
}
