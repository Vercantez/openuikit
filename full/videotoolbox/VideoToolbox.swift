import Foundation

public typealias OSStatus = Int32

public let kVTPropertyNotSupportedErr: OSStatus = -12900
public let kVTPropertyReadOnlyErr: OSStatus = -12901
public let kVTParameterErr: OSStatus = -12902
public let kVTInvalidSessionErr: OSStatus = -12903
public let kVTAllocationFailedErr: OSStatus = -12904
public let kVTPixelTransferNotSupportedErr: OSStatus = -12905
public let kVTCouldNotFindVideoDecoderErr: OSStatus = -12906
public let kVTCouldNotCreateInstanceErr: OSStatus = -12907
public let kVTCouldNotFindVideoEncoderErr: OSStatus = -12908
public let kVTVideoDecoderBadDataErr: OSStatus = -12909
public let kVTVideoDecoderUnsupportedDataFormatErr: OSStatus = -12910
public let kVTVideoDecoderMalfunctionErr: OSStatus = -12911
public let kVTVideoEncoderMalfunctionErr: OSStatus = -12912
public let kVTVideoDecoderNotAvailableNowErr: OSStatus = -12913
public let kVTImageRotationNotSupportedErr: OSStatus = -12914
public let kVTPixelRotationNotSupportedErr: OSStatus = -12914
public let kVTVideoEncoderNotAvailableNowErr: OSStatus = -12915
public let kVTFormatDescriptionChangeNotSupportedErr: OSStatus = -12916
public let kVTInsufficientSourceColorDataErr: OSStatus = -12917
public let kVTCouldNotCreateColorCorrectionDataErr: OSStatus = -12918
public let kVTColorSyncTransformConvertFailedErr: OSStatus = -12919
public let kVTVideoDecoderAuthorizationErr: OSStatus = -12210
public let kVTVideoEncoderAuthorizationErr: OSStatus = -12211
public let kVTColorCorrectionPixelTransferFailedErr: OSStatus = -12212
public let kVTMultiPassStorageIdentifierMismatchErr: OSStatus = -12913
public let kVTMultiPassStorageInvalidErr: OSStatus = -12214
public let kVTFrameSiloInvalidTimeStampErr: OSStatus = -12215
public let kVTFrameSiloInvalidTimeRangeErr: OSStatus = -12216
public let kVTCouldNotFindTemporalFilterErr: OSStatus = -12217
public let kVTPixelTransferNotPermittedErr: OSStatus = -12218
public let kVTColorCorrectionImageRotationFailedErr: OSStatus = -12219
public let kVTVideoDecoderRemovedErr: OSStatus = -17690
public let kVTSessionMalfunctionErr: OSStatus = -17691
public let kVTVideoDecoderNeedsRosettaErr: OSStatus = -17692
public let kVTVideoEncoderNeedsRosettaErr: OSStatus = -17693
public let kVTVideoDecoderReferenceMissingErr: OSStatus = -17694
public let kVTVideoDecoderCallbackMessagingErr: OSStatus = -17695
public let kVTVideoDecoderUnknownErr: OSStatus = -17696
public let kVTExtensionDisabledErr: OSStatus = -17697
public let kVTVideoEncoderMVHEVCVideoLayerIDsMismatchErr: OSStatus = -17698
public let kVTCouldNotOutputTaggedBufferGroupErr: OSStatus = -17699
public let kVTCouldNotFindExtensionErr: OSStatus = -19510
public let kVTExtensionConflictErr: OSStatus = -19511
public let kVTVideoEncoderAutoWhiteBalanceNotLockedErr: OSStatus = -19512

public typealias VTCompressionSessionRef = OpaquePointer
public typealias VTDecompressionSessionRef = OpaquePointer
public typealias VTSessionRef = OpaquePointer
public typealias VTPixelTransferSessionRef = OpaquePointer
public typealias VTPixelRotationSessionRef = OpaquePointer
public typealias VTMultiPassStorageRef = OpaquePointer
public typealias VTFrameSiloRef = OpaquePointer
public typealias VTRAWProcessingSessionRef = OpaquePointer
public typealias VTHDRPerFrameMetadataGenerationSessionRef = OpaquePointer
public typealias VTMotionEstimationSessionRef = OpaquePointer

public struct VTDecodeFrameFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let enableAsynchronousDecompression = VTDecodeFrameFlags(rawValue: 1)
    public static let doNotOutputFrame = VTDecodeFrameFlags(rawValue: 2)
    public static let oneXRealTimePlayback = VTDecodeFrameFlags(rawValue: 4)
    public static let enableTemporalProcessing = VTDecodeFrameFlags(rawValue: 8)
}

public let kVTDecodeFrame_EnableAsynchronousDecompression: UInt32 = 1
public let kVTDecodeFrame_DoNotOutputFrame: UInt32 = 2
public let kVTDecodeFrame_1xRealTimePlayback: UInt32 = 4
public let kVTDecodeFrame_EnableTemporalProcessing: UInt32 = 8

public struct VTDecodeInfoFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let asynchronous = VTDecodeInfoFlags(rawValue: 1)
    public static let frameDropped = VTDecodeInfoFlags(rawValue: 2)
    public static let imageBufferModifiable = VTDecodeInfoFlags(rawValue: 4)
    public static let skippedLeadingFrameDropped = VTDecodeInfoFlags(rawValue: 8)
    public static let frameInterrupted = VTDecodeInfoFlags(rawValue: 16)
}

public let kVTDecodeInfo_Asynchronous: UInt32 = 1
public let kVTDecodeInfo_FrameDropped: UInt32 = 2
public let kVTDecodeInfo_ImageBufferModifiable: UInt32 = 4
public let kVTDecodeInfo_SkippedLeadingFrameDropped: UInt32 = 8
public let kVTDecodeInfo_FrameInterrupted: UInt32 = 16

public struct VTEncodeInfoFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let asynchronous = VTEncodeInfoFlags(rawValue: 1)
    public static let frameDropped = VTEncodeInfoFlags(rawValue: 2)
}

public let kVTEncodeInfo_Asynchronous: UInt32 = 1
public let kVTEncodeInfo_FrameDropped: UInt32 = 2

public struct VTCompressionSessionOptionFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let beginFinalPass = VTCompressionSessionOptionFlags(rawValue: 1)
}

public let kVTCompressionSessionBeginFinalPass: UInt32 = 1

public typealias VTDecompressionOutputCallback = (
    _ status: OSStatus,
    _ infoFlags: VTDecodeInfoFlags,
    _ imageBuffer: OpaquePointer?,
    _ presentationTimeStamp: VTMediaTime,
    _ presentationDuration: VTMediaTime,
    _ sourceFrameRefCon: UnsafeMutableRawPointer?
) -> Void

public typealias VTCompressionOutputCallback = (
    _ status: OSStatus,
    _ infoFlags: VTEncodeInfoFlags,
    _ sampleBuffer: OpaquePointer?,
    _ sourceFrameRefCon: UnsafeMutableRawPointer?
) -> Void

public func VTHostCreatePixelBuffer(
    width: Int32,
    height: Int32,
    pixelFormat: UInt32,
    pixelBufferOut: inout OpaquePointer?
) -> OSStatus {
    pixelBufferOut = nil
    if width <= 0 || height <= 0 || !vtSupportedPixelFormat(pixelFormat) {
        return kVTParameterErr
    }
    let buffer = VTHostPixelBuffer(width: Int(width), height: Int(height), pixelFormat: pixelFormat)
    pixelBufferOut = vtStore(.pixelBuffer(buffer))
    return 0
}

public func VTHostFillPixelBuffer(
    _ pixelBuffer: OpaquePointer?,
    red: UInt8,
    green: UInt8,
    blue: UInt8,
    alpha: UInt8
) -> OSStatus {
    guard let buffer = vtLookupPixelBuffer(pixelBuffer) else { return kVTParameterErr }
    let fill = VTPackedRGBA(r: red, g: green, b: blue, a: alpha)
    if buffer.isPlanar {
        vtFillYUV(buffer: buffer, fill: fill)
    } else {
        vtFillPacked(buffer: buffer, fill: fill)
    }
    return 0
}

public func VTHostPixelBufferGetWidth(_ pixelBuffer: OpaquePointer?) -> Int32 {
    guard let buffer = vtLookupPixelBuffer(pixelBuffer) else { return 0 }
    return Int32(buffer.width)
}

public func VTHostPixelBufferGetHeight(_ pixelBuffer: OpaquePointer?) -> Int32 {
    guard let buffer = vtLookupPixelBuffer(pixelBuffer) else { return 0 }
    return Int32(buffer.height)
}

public func VTHostPixelBufferGetPixelFormat(_ pixelBuffer: OpaquePointer?) -> UInt32 {
    guard let buffer = vtLookupPixelBuffer(pixelBuffer) else { return 0 }
    return buffer.pixelFormat
}

public func VTHostPixelBufferGetByte(_ pixelBuffer: OpaquePointer?, x: Int, y: Int, channel: Int) -> UInt8 {
    guard let buffer = vtLookupPixelBuffer(pixelBuffer) else { return 0 }
    let pixel = vtReadPackedPixel(buffer, x: x, y: y)
    switch channel {
    case 0: return pixel.r
    case 1: return pixel.g
    case 2: return pixel.b
    default: return pixel.a
    }
}

public func VTHostCreateSampleBuffer(
    format: VTVideoFormatDescription,
    pixelBuffer: OpaquePointer?,
    encoded: [UInt8] = [],
    presentationTimeStamp: VTMediaTime,
    duration: VTMediaTime,
    sampleBufferOut: inout OpaquePointer?
) -> OSStatus {
    sampleBufferOut = nil
    if format.width <= 0 || format.height <= 0 || format.codecType == 0 {
        return kVTParameterErr
    }
    let sample = VTHostSampleBuffer(
        format: format,
        pixelBuffer: pixelBuffer,
        encoded: encoded,
        pts: presentationTimeStamp,
        duration: duration
    )
    sampleBufferOut = vtStore(.sampleBuffer(sample))
    return 0
}

public func VTHostSampleBufferGetPresentationTimeStamp(_ sampleBuffer: OpaquePointer?) -> VTMediaTime {
    vtLookupSampleBuffer(sampleBuffer)?.pts ?? .invalid
}

public func VTHostSampleBufferGetDuration(_ sampleBuffer: OpaquePointer?) -> VTMediaTime {
    vtLookupSampleBuffer(sampleBuffer)?.duration ?? .invalid
}

public func VTHostCGImageGetWidth(_ image: OpaquePointer?) -> Int32 {
    guard case .image(let box)? = vtLookup(image) else { return 0 }
    return Int32(box.width)
}

public func VTHostCGImageGetHeight(_ image: OpaquePointer?) -> Int32 {
    guard case .image(let box)? = vtLookup(image) else { return 0 }
    return Int32(box.height)
}

public func VTHostCGImageGetByte(_ image: OpaquePointer?, offset: Int) -> UInt8 {
    guard case .image(let box)? = vtLookup(image) else { return 0 }
    guard box.rgba.indices.contains(offset) else { return 0 }
    return box.rgba[offset]
}

private func vtRequireSession(_ pointer: OpaquePointer?, kind: VTObjectKind? = nil) -> LinuxVTSession? {
    guard let session = vtLookupSession(pointer), session.valid else { return nil }
    if let kind, session.kind != kind { return nil }
    return session
}

public func VTCompressionSessionCreate(
    width: Int32,
    height: Int32,
    codecType: UInt32,
    sessionOut: inout OpaquePointer?
) -> OSStatus {
    return VTCompressionSessionCreate(
        width: width,
        height: height,
        codecType: codecType,
        outputCallback: nil,
        sessionOut: &sessionOut
    )
}

public func VTCompressionSessionCreate(
    width: Int32,
    height: Int32,
    codecType: UInt32,
    outputCallback: VTCompressionOutputCallback?,
    sessionOut: inout OpaquePointer?
) -> OSStatus {
    sessionOut = nil
    if width <= 0 || height <= 0 || codecType == 0 {
        return kVTParameterErr
    }
    if codecType == kVTVideoCodecType_JPEG || codecType == kVTVideoCodecType_JPEG_OpenDML {
        if !vtJPEGEncoderReachable() {
            return kVTCouldNotFindVideoEncoderErr
        }
    }
    return kVTCouldNotFindVideoEncoderErr
}

public func VTCompressionSessionInvalidate(_ session: OpaquePointer?) {
    if let box = vtLookupSession(session) {
        box.valid = false
    }
    vtRemoveObject(session)
}

public func VTCompressionSessionEncodeFrame(_ session: OpaquePointer?) -> OSStatus {
    var info = VTEncodeInfoFlags(rawValue: 0)
    return VTCompressionSessionEncodeFrame(
        session,
        imageBuffer: nil,
        presentationTimeStamp: .invalid,
        duration: .invalid,
        sourceFrameRefCon: nil,
        infoFlagsOut: &info
    )
}

public func VTCompressionSessionEncodeFrame(
    _ session: OpaquePointer?,
    imageBuffer: OpaquePointer?,
    presentationTimeStamp: VTMediaTime,
    duration: VTMediaTime,
    sourceFrameRefCon: UnsafeMutableRawPointer?,
    infoFlagsOut: inout VTEncodeInfoFlags
) -> OSStatus {
    infoFlagsOut = []
    _ = imageBuffer
    _ = presentationTimeStamp
    _ = duration
    _ = sourceFrameRefCon
    guard vtRequireSession(session, kind: .compression) != nil else {
        return kVTInvalidSessionErr
    }
    return kVTCouldNotFindVideoEncoderErr
}

public func VTCompressionSessionCompleteFrames(_ session: OpaquePointer?) -> OSStatus {
    guard let box = vtRequireSession(session, kind: .compression) else {
        return kVTInvalidSessionErr
    }
    box.pendingEncode = 0
    box.properties[kVTCompressionPropertyKey_NumberOfPendingFrames] = "0"
    return 0
}

public func VTCompressionSessionPrepareToEncodeFrames(_ session: OpaquePointer?) -> OSStatus {
    guard let box = vtRequireSession(session, kind: .compression) else {
        return kVTInvalidSessionErr
    }
    box.prepared = true
    return 0
}

public func VTCompressionSessionGetPixelBufferPool(_ session: OpaquePointer?) -> OpaquePointer? {
    _ = session
    return nil
}

public func VTCompressionSessionBeginPass(
    _ session: OpaquePointer?,
    flags: VTCompressionSessionOptionFlags
) -> OSStatus {
    _ = flags
    guard let box = vtRequireSession(session, kind: .compression) else {
        return kVTInvalidSessionErr
    }
    box.progress = 0
    return 0
}

public func VTCompressionSessionEndPass(
    _ session: OpaquePointer?,
    furtherPassesRequestedOut: inout Bool
) -> OSStatus {
    furtherPassesRequestedOut = false
    guard vtRequireSession(session, kind: .compression) != nil else {
        return kVTInvalidSessionErr
    }
    return 0
}

public func VTCompressionSessionGetTimeRangesForNextPass(_ session: OpaquePointer?) -> OSStatus {
    guard vtRequireSession(session, kind: .compression) != nil else {
        return kVTInvalidSessionErr
    }
    return 0
}

public func VTDecompressionSessionCreate(sessionOut: inout OpaquePointer?) -> OSStatus {
    sessionOut = nil
    return kVTParameterErr
}

public func VTDecompressionSessionCreate(
    formatDescription: VTVideoFormatDescription,
    destinationPixelFormat: UInt32 = kVTPixelFormat_32BGRA,
    outputCallback: VTDecompressionOutputCallback?,
    sessionOut: inout OpaquePointer?
) -> OSStatus {
    sessionOut = nil
    if formatDescription.width <= 0 || formatDescription.height <= 0 || formatDescription.codecType == 0 {
        return kVTParameterErr
    }
    if vtHardwareCodec(formatDescription.codecType) {
        return kVTCouldNotFindVideoDecoderErr
    }
    if formatDescription.codecType == kVTVideoCodecType_JPEG || codecIsMotionJPEG(formatDescription.codecType) {
        return kVTCouldNotFindVideoDecoderErr
    }
    if !formatDescription.isUncompressed {
        return kVTCouldNotFindVideoDecoderErr
    }
    if destinationPixelFormat != 0 && !vtSupportedPixelFormat(destinationPixelFormat) {
        return kVTParameterErr
    }
    let box = LinuxVTSession(kind: .decompression)
    box.width = formatDescription.width
    box.height = formatDescription.height
    box.codecType = formatDescription.codecType
    box.format = formatDescription
    box.destinationPixelFormat = destinationPixelFormat == 0 ? kVTPixelFormat_32BGRA : destinationPixelFormat
    box.decodeCallback = outputCallback
    box.properties[kVTDecompressionPropertyKey_SupportedPixelFormatsOrderedByQuality] =
        "\(kVTPixelFormat_32BGRA),\(kVTPixelFormat_32RGBA),\(kVTPixelFormat_32ARGB)"
    box.properties[kVTDecompressionPropertyKey_SupportedPixelFormatsOrderedByPerformance] =
        "\(kVTPixelFormat_32BGRA),\(kVTPixelFormat_32RGBA)"
    sessionOut = vtStore(.session(box))
    return 0
}

private func codecIsMotionJPEG(_ codecType: UInt32) -> Bool {
    codecType == kVTVideoCodecType_JPEG || codecType == kVTVideoCodecType_JPEG_OpenDML
}

public func VTDecompressionSessionInvalidate(_ session: OpaquePointer?) {
    if let box = vtLookupSession(session) {
        box.valid = false
        box.decodeCallback = nil
    }
    vtRemoveObject(session)
}

public func VTDecompressionSessionDecodeFrame(_ session: OpaquePointer?) -> OSStatus {
    var info = VTDecodeInfoFlags(rawValue: 0)
    return VTDecompressionSessionDecodeFrame(
        session,
        sampleBuffer: nil,
        decodeFlags: [],
        sourceFrameRefCon: nil,
        infoFlagsOut: &info
    )
}

public func VTDecompressionSessionDecodeFrame(
    _ session: OpaquePointer?,
    sampleBuffer: OpaquePointer?,
    decodeFlags: VTDecodeFrameFlags,
    sourceFrameRefCon: UnsafeMutableRawPointer?,
    infoFlagsOut: inout VTDecodeInfoFlags
) -> OSStatus {
    infoFlagsOut = []
    guard let box = vtRequireSession(session, kind: .decompression) else {
        return kVTInvalidSessionErr
    }
    guard let sample = vtLookupSampleBuffer(sampleBuffer), sample.valid else {
        return kVTParameterErr
    }
    return vtDecodeFrame(
        box,
        sample: sample,
        decodeFlags: decodeFlags,
        sourceFrameRefCon: sourceFrameRefCon,
        infoFlagsOut: &infoFlagsOut,
        outputHandler: nil
    )
}

public func VTDecompressionSessionDecodeFrameWithOutputHandler(_ session: OpaquePointer?) -> OSStatus {
    var info = VTDecodeInfoFlags(rawValue: 0)
    return VTDecompressionSessionDecodeFrameWithOutputHandler(
        session,
        sampleBuffer: nil,
        decodeFlags: [],
        infoFlagsOut: &info,
        outputHandler: { _, _, _, _, _, _ in }
    )
}

public func VTDecompressionSessionDecodeFrameWithOutputHandler(
    _ session: OpaquePointer?,
    sampleBuffer: OpaquePointer?,
    decodeFlags: VTDecodeFrameFlags,
    infoFlagsOut: inout VTDecodeInfoFlags,
    outputHandler: @escaping VTDecompressionOutputCallback
) -> OSStatus {
    infoFlagsOut = []
    guard let box = vtRequireSession(session, kind: .decompression) else {
        return kVTInvalidSessionErr
    }
    guard let sample = vtLookupSampleBuffer(sampleBuffer), sample.valid else {
        return kVTParameterErr
    }
    return vtDecodeFrame(
        box,
        sample: sample,
        decodeFlags: decodeFlags,
        sourceFrameRefCon: nil,
        infoFlagsOut: &infoFlagsOut,
        outputHandler: outputHandler
    )
}

public func VTDecompressionSessionDecodeFrameWithMultiImageCapableOutputHandler(
    _ session: OpaquePointer?
) -> OSStatus {
    return VTDecompressionSessionDecodeFrameWithOutputHandler(session)
}

private func vtDecodeFrame(
    _ box: LinuxVTSession,
    sample: VTHostSampleBuffer,
    decodeFlags: VTDecodeFrameFlags,
    sourceFrameRefCon: UnsafeMutableRawPointer?,
    infoFlagsOut: inout VTDecodeInfoFlags,
    outputHandler: VTDecompressionOutputCallback?
) -> OSStatus {
    if !sample.format.isUncompressed {
        return kVTCouldNotFindVideoDecoderErr
    }
    if decodeFlags.contains(.doNotOutputFrame) {
        infoFlagsOut.insert(.frameDropped)
        return 0
    }
    let work = {
        vtEmitDecodedFrame(
            box,
            sample: sample,
            decodeFlags: decodeFlags,
            sourceFrameRefCon: sourceFrameRefCon,
            outputHandler: outputHandler
        )
    }
    if decodeFlags.contains(.enableAsynchronousDecompression) {
        infoFlagsOut.insert(.asynchronous)
        box.asyncLock.lock()
        box.asyncOutstanding += 1
        box.properties[kVTDecompressionPropertyKey_NumberOfFramesBeingDecoded] = "\(box.asyncOutstanding)"
        box.asyncLock.unlock()
        DispatchQueue.global(qos: .userInitiated).async {
            _ = work()
            box.asyncLock.lock()
            box.asyncOutstanding = max(0, box.asyncOutstanding - 1)
            box.properties[kVTDecompressionPropertyKey_NumberOfFramesBeingDecoded] = "\(box.asyncOutstanding)"
            box.asyncLock.broadcast()
            box.asyncLock.unlock()
        }
        return 0
    }
    return work()
}

private func vtEmitDecodedFrame(
    _ box: LinuxVTSession,
    sample: VTHostSampleBuffer,
    decodeFlags: VTDecodeFrameFlags,
    sourceFrameRefCon: UnsafeMutableRawPointer?,
    outputHandler: VTDecompressionOutputCallback?
) -> OSStatus {
    _ = decodeFlags
    var output: OpaquePointer?
    let status = vtCopyDecodedImage(box, sample: sample, output: &output)
    let info = VTDecodeInfoFlags.imageBufferModifiable
    let callback = outputHandler ?? box.decodeCallback
    callback?(status, info, output, sample.pts, sample.duration, sourceFrameRefCon)
    return status
}

private func vtCopyDecodedImage(
    _ box: LinuxVTSession,
    sample: VTHostSampleBuffer,
    output: inout OpaquePointer?
) -> OSStatus {
    output = nil
    let destFormat = box.destinationPixelFormat
    let destWidth = Int(box.width)
    let destHeight = Int(box.height)
    let destination = VTHostPixelBuffer(width: destWidth, height: destHeight, pixelFormat: destFormat)
    if let sourcePointer = sample.pixelBuffer, let source = vtLookupPixelBuffer(sourcePointer) {
        let status = vtTransferPixels(source: source, destination: destination, scalingMode: .normal)
        if status != 0 { return status }
    } else if sample.format.codecType == destFormat && sample.encoded.count == destination.data.count {
        destination.data = sample.encoded
    } else {
        return kVTVideoDecoderBadDataErr
    }
    output = vtStore(.pixelBuffer(destination))
    return 0
}

public func VTDecompressionSessionFinishDelayedFrames(_ session: OpaquePointer?) -> OSStatus {
    guard let box = vtRequireSession(session, kind: .decompression) else {
        return kVTInvalidSessionErr
    }
    box.pendingDecode = 0
    return 0
}

public func VTDecompressionSessionWaitForAsynchronousFrames(_ session: OpaquePointer?) -> OSStatus {
    guard let box = vtRequireSession(session, kind: .decompression) else {
        return kVTInvalidSessionErr
    }
    box.asyncLock.lock()
    while box.asyncOutstanding > 0 {
        box.asyncLock.wait()
    }
    box.asyncLock.unlock()
    return 0
}

public func VTDecompressionSessionCanAcceptFormatDescription(_ session: OpaquePointer?) -> Bool {
    return VTDecompressionSessionCanAcceptFormatDescription(session, formatDescription: nil)
}

public func VTDecompressionSessionCanAcceptFormatDescription(
    _ session: OpaquePointer?,
    formatDescription: VTVideoFormatDescription?
) -> Bool {
    guard let box = vtRequireSession(session, kind: .decompression), let current = box.format else {
        return false
    }
    guard let formatDescription else { return false }
    if formatDescription.codecType != current.codecType {
        return false
    }
    if formatDescription.width == current.width && formatDescription.height == current.height {
        return true
    }
    return box.properties[kVTDecompressionPropertyKey_AllowBitstreamToChangeFrameDimensions].flatMap(vtBooleanValue) == true
}

public func VTDecompressionSessionCopyBlackPixelBuffer(
    _ session: OpaquePointer?,
    pixelBufferOut: inout OpaquePointer?
) -> OSStatus {
    pixelBufferOut = nil
    guard let box = vtRequireSession(session, kind: .decompression) else {
        return kVTInvalidSessionErr
    }
    return VTHostCreatePixelBuffer(
        width: box.width,
        height: box.height,
        pixelFormat: box.destinationPixelFormat,
        pixelBufferOut: &pixelBufferOut
    )
}

public func VTSessionSetProperty(_ session: OpaquePointer?, key: String, value: String) -> OSStatus {
    guard let box = vtRequireSession(session) else {
        return kVTInvalidSessionErr
    }
    if key.isEmpty {
        return kVTParameterErr
    }
    let status = vtValidateProperty(kind: box.kind, key: key, value: value)
    if status != 0 {
        return status
    }
    box.properties[key] = value
    return 0
}

public func VTSessionCopyProperty(
    _ session: OpaquePointer?,
    key: String,
    valueOut: inout String?
) -> OSStatus {
    valueOut = nil
    guard let box = vtRequireSession(session) else {
        return kVTInvalidSessionErr
    }
    if key.isEmpty {
        return kVTParameterErr
    }
    guard let value = box.properties[key] else {
        let catalog = vtPropertyCatalog(for: box.kind)
        if catalog[key] == nil {
            return kVTPropertyNotSupportedErr
        }
        return kVTPropertyNotSupportedErr
    }
    valueOut = value
    return 0
}

public func VTSessionSetProperties(
    _ session: OpaquePointer?,
    properties: [String: String]
) -> OSStatus {
    guard let box = vtRequireSession(session) else {
        return kVTInvalidSessionErr
    }
    for (key, value) in properties {
        let status = vtValidateProperty(kind: box.kind, key: key, value: value)
        if status != 0 {
            return status
        }
        box.properties[key] = value
    }
    return 0
}

public func VTSessionCopySerializableProperties(
    _ session: OpaquePointer?,
    propertiesOut: inout [String: String]
) -> OSStatus {
    propertiesOut = [:]
    guard let box = vtRequireSession(session) else {
        return kVTInvalidSessionErr
    }
    propertiesOut = vtCopySerializable(box)
    return 0
}

public func VTSessionCopySupportedPropertyDictionary(
    _ session: OpaquePointer?,
    propertiesOut: inout [String: String]
) -> OSStatus {
    propertiesOut = [:]
    guard let box = vtRequireSession(session) else {
        return kVTInvalidSessionErr
    }
    propertiesOut = vtSupportedPropertyDictionary(for: box)
    return 0
}

public func VTPixelTransferSessionCreate(sessionOut: inout OpaquePointer?) -> OSStatus {
    let box = LinuxVTSession(kind: .pixelTransfer)
    sessionOut = vtStore(.session(box))
    return 0
}

public func VTPixelTransferSessionInvalidate(_ session: OpaquePointer?) {
    if let box = vtLookupSession(session) {
        box.valid = false
    }
    vtRemoveObject(session)
}

public func VTPixelTransferSessionTransferImage(
    _ session: OpaquePointer?,
    source: OpaquePointer?,
    destination: OpaquePointer?
) -> OSStatus {
    guard let box = vtRequireSession(session, kind: .pixelTransfer) else {
        return kVTInvalidSessionErr
    }
    guard let sourceBuffer = vtLookupPixelBuffer(source),
          let destinationBuffer = vtLookupPixelBuffer(destination) else {
        return kVTPixelTransferNotSupportedErr
    }
    let mode = vtParseScaleMode(box.properties[kVTPixelTransferPropertyKey_ScalingMode])
    return vtTransferPixels(source: sourceBuffer, destination: destinationBuffer, scalingMode: mode)
}

public func VTPixelTransferSessionGetTypeID() -> UInt {
    return 0
}

public func VTPixelRotationSessionCreate(sessionOut: inout OpaquePointer?) -> OSStatus {
    let box = LinuxVTSession(kind: .pixelRotation)
    sessionOut = vtStore(.session(box))
    return 0
}

public func VTPixelRotationSessionInvalidate(_ session: OpaquePointer?) {
    if let box = vtLookupSession(session) {
        box.valid = false
    }
    vtRemoveObject(session)
}

public func VTPixelRotationSessionRotateImage(
    _ session: OpaquePointer?,
    source: OpaquePointer?,
    destination: OpaquePointer?
) -> OSStatus {
    guard let box = vtRequireSession(session, kind: .pixelRotation) else {
        return kVTInvalidSessionErr
    }
    guard let sourceBuffer = vtLookupPixelBuffer(source),
          let destinationBuffer = vtLookupPixelBuffer(destination) else {
        return kVTPixelRotationNotSupportedErr
    }
    let rotation = box.properties[kVTPixelRotationPropertyKey_Rotation] ?? kVTRotation_0
    let flipH = vtBooleanValue(box.properties[kVTPixelRotationPropertyKey_FlipHorizontalOrientation] ?? "false") ?? false
    let flipV = vtBooleanValue(box.properties[kVTPixelRotationPropertyKey_FlipVerticalOrientation] ?? "false") ?? false
    return vtRotatePixels(
        source: sourceBuffer,
        destination: destinationBuffer,
        rotation: rotation,
        flipHorizontal: flipH,
        flipVertical: flipV
    )
}

public func VTPixelRotationSessionGetTypeID() -> UInt {
    return 0
}

public func VTCreateCGImageFromCVPixelBuffer(
    pixelBuffer: OpaquePointer?,
    imageOut: inout OpaquePointer?
) -> OSStatus {
    imageOut = nil
    if pixelBuffer == nil {
        return kVTParameterErr
    }
    guard let buffer = vtLookupPixelBuffer(pixelBuffer) else {
        return kVTParameterErr
    }
    let image = VTHostCGImage(width: buffer.width, height: buffer.height, rgba: vtRGBABytes(from: buffer))
    imageOut = vtStore(.image(image))
    return 0
}

public func VTIsHardwareDecodeSupported(_ codecType: UInt32) -> Bool {
    _ = codecType
    return false
}

public func VTIsStereoMVHEVCDecodeSupported() -> Bool {
    return false
}

public func VTIsStereoMVHEVCEncodeSupported() -> Bool {
    return false
}

public func VTCopyVideoEncoderList(_ encoderListOut: inout [String]) -> OSStatus {
    encoderListOut = []
    if vtJPEGEncoderReachable() {
        encoderListOut = ["jpeg"]
    }
    return 0
}

public func VTCopySupportedPropertyDictionaryForEncoder(
    width: Int32,
    height: Int32,
    codecType: UInt32,
    encoderIdentifierOut: inout String?,
    propertiesOut: inout [String: String]
) -> OSStatus {
    encoderIdentifierOut = nil
    propertiesOut = [:]
    if width <= 0 || height <= 0 || codecType == 0 {
        return kVTParameterErr
    }
    return kVTCouldNotFindVideoEncoderErr
}

public func VTRegisterProfessionalVideoWorkflowVideoDecoders() {}

public func VTRegisterProfessionalVideoWorkflowVideoEncoders() {}

public func VTRegisterSupplementalVideoDecoderIfAvailable(_ codecType: UInt32) {
    _ = codecType
}

public func VTCopyVideoDecoderExtensionProperties(_ propertiesOut: inout [String: String]) -> OSStatus {
    propertiesOut = [:]
    return kVTCouldNotFindExtensionErr
}

public func VTCopyRAWProcessorExtensionProperties(_ propertiesOut: inout [String: String]) -> OSStatus {
    propertiesOut = [:]
    return kVTCouldNotFindExtensionErr
}

public func VTMultiPassStorageCreate(storageOut: inout OpaquePointer?) -> OSStatus {
    let box = LinuxVTSession(kind: .multiPass)
    sessionOutBind(&storageOut, box)
    return 0
}

private func sessionOutBind(_ pointer: inout OpaquePointer?, _ box: LinuxVTSession) {
    pointer = vtStore(.session(box))
}

public func VTMultiPassStorageClose(_ storage: OpaquePointer?) -> OSStatus {
    guard let box = vtRequireSession(storage, kind: .multiPass) else {
        return kVTInvalidSessionErr
    }
    box.closed = true
    box.valid = false
    return 0
}

public func VTFrameSiloCreate(siloOut: inout OpaquePointer?) -> OSStatus {
    let box = LinuxVTSession(kind: .frameSilo)
    siloOut = vtStore(.session(box))
    return 0
}

public func VTFrameSiloAddSampleBuffer(_ silo: OpaquePointer?, sampleBuffer: OpaquePointer?) -> OSStatus {
    guard let box = vtRequireSession(silo, kind: .frameSilo) else {
        return kVTInvalidSessionErr
    }
    guard let sample = vtLookupSampleBuffer(sampleBuffer), sample.valid else {
        return kVTParameterErr
    }
    if !sample.pts.isValid {
        return kVTFrameSiloInvalidTimeStampErr
    }
    box.frames.append(sample)
    box.frames.sort { $0.pts.seconds < $1.pts.seconds }
    return 0
}

public func VTFrameSiloSetTimeRangesForNextPass(_ silo: OpaquePointer?) -> OSStatus {
    guard let box = vtRequireSession(silo, kind: .frameSilo) else {
        return kVTInvalidSessionErr
    }
    box.progress = 0
    return 0
}

public func VTFrameSiloGetProgressOfCurrentPass(
    _ silo: OpaquePointer?,
    progressOut: inout Double
) -> OSStatus {
    progressOut = 0
    guard let box = vtRequireSession(silo, kind: .frameSilo) else {
        return kVTInvalidSessionErr
    }
    if box.frames.isEmpty {
        progressOut = 1
    } else {
        progressOut = box.progress
    }
    return 0
}

public func VTFrameSiloCallFunctionForEachSampleBuffer(_ silo: OpaquePointer?) -> OSStatus {
    return VTFrameSiloCallFunctionForEachSampleBuffer(silo) { _ in 0 }
}

public func VTFrameSiloCallFunctionForEachSampleBuffer(
    _ silo: OpaquePointer?,
    body: (OpaquePointer?) -> OSStatus
) -> OSStatus {
    guard let box = vtRequireSession(silo, kind: .frameSilo) else {
        return kVTInvalidSessionErr
    }
    for (index, _) in box.frames.enumerated() {
        let pointer = vtStore(.sampleBuffer(box.frames[index]))
        let status = body(pointer)
        if status != 0 {
            return status
        }
    }
    box.progress = 1
    return 0
}

public func VTRAWProcessingSessionCreate(sessionOut: inout OpaquePointer?) -> OSStatus {
    sessionOut = nil
    return kVTCouldNotFindExtensionErr
}

public func VTRAWProcessingSessionInvalidate(_ session: OpaquePointer?) {
    vtRemoveObject(session)
}

public func VTRAWProcessingSessionGetTypeID() -> UInt {
    return 0
}

public func VTRAWProcessingSessionCompleteFrames(_ session: OpaquePointer?) -> OSStatus {
    _ = session
    return kVTInvalidSessionErr
}

public func VTRAWProcessingSessionProcessFrame(_ session: OpaquePointer?) -> OSStatus {
    _ = session
    return kVTInvalidSessionErr
}

public func VTRAWProcessingSessionCopyProcessingParameters(
    _ session: OpaquePointer?,
    parametersOut: inout [String: String]
) -> OSStatus {
    parametersOut = [:]
    _ = session
    return kVTInvalidSessionErr
}

public func VTRAWProcessingSessionSetProcessingParameters(
    _ session: OpaquePointer?,
    parameters: [String: String]
) -> OSStatus {
    _ = parameters
    _ = session
    return kVTInvalidSessionErr
}

public func VTRAWProcessingSessionSetParameterChangedHandler(_ session: OpaquePointer?) -> OSStatus {
    _ = session
    return kVTInvalidSessionErr
}

public func VTRAWProcessingSessionSetParameterChangedHander(_ session: OpaquePointer?) -> OSStatus {
    return VTRAWProcessingSessionSetParameterChangedHandler(session)
}

public func VTMotionEstimationSessionCreate(sessionOut: inout OpaquePointer?) -> OSStatus {
    sessionOut = nil
    return kVTCouldNotFindTemporalFilterErr
}

public func VTMotionEstimationSessionInvalidate(_ session: OpaquePointer?) {
    vtRemoveObject(session)
}

public func VTHDRPerFrameMetadataGenerationSessionCreate(
    framesPerSecond: Float,
    sessionOut: inout OpaquePointer?
) -> OSStatus {
    sessionOut = nil
    if framesPerSecond <= 0 {
        return kVTParameterErr
    }
    return kVTAllocationFailedErr
}

public func VTHDRPerFrameMetadataGenerationSessionInvalidate(_ session: OpaquePointer?) {
    vtRemoveObject(session)
}

public func VTHDRPerFrameMetadataGenerationSessionGetTypeID() -> UInt {
    return 0
}

public func VTCompressionSessionEncodeMultiImageFrame(_ session: OpaquePointer?) -> OSStatus {
    _ = session
    return kVTInvalidSessionErr
}

public func VTCompressionSessionEncodeMultiImageFrameWithOutputHandler(
    _ session: OpaquePointer?
) -> OSStatus {
    _ = session
    return kVTInvalidSessionErr
}

public func VTDecompressionSessionDecodeFrameWithOptions(_ session: OpaquePointer?) -> OSStatus {
    return VTDecompressionSessionDecodeFrame(session)
}

public func VTDecompressionSessionDecodeFrameWithOptionsAndOutputHandler(
    _ session: OpaquePointer?
) -> OSStatus {
    return VTDecompressionSessionDecodeFrameWithOutputHandler(session)
}

public func VTDecompressionSessionSetMultiImageCallback(_ session: OpaquePointer?) -> OSStatus {
    guard vtRequireSession(session, kind: .decompression) != nil else {
        return kVTInvalidSessionErr
    }
    return kVTPropertyNotSupportedErr
}

public func VTMotionEstimationSessionGetTypeID() -> UInt {
    return 0
}

public func VTHostAllPropertyKeys() -> [String] {
    vtAllPublicKeys()
}

public func VTHostAllErrorConstants() -> [(String, OSStatus)] {
    [
        ("kVTPropertyNotSupportedErr", kVTPropertyNotSupportedErr),
        ("kVTPropertyReadOnlyErr", kVTPropertyReadOnlyErr),
        ("kVTParameterErr", kVTParameterErr),
        ("kVTInvalidSessionErr", kVTInvalidSessionErr),
        ("kVTAllocationFailedErr", kVTAllocationFailedErr),
        ("kVTPixelTransferNotSupportedErr", kVTPixelTransferNotSupportedErr),
        ("kVTCouldNotFindVideoDecoderErr", kVTCouldNotFindVideoDecoderErr),
        ("kVTCouldNotCreateInstanceErr", kVTCouldNotCreateInstanceErr),
        ("kVTCouldNotFindVideoEncoderErr", kVTCouldNotFindVideoEncoderErr),
        ("kVTVideoDecoderBadDataErr", kVTVideoDecoderBadDataErr),
        ("kVTVideoDecoderUnsupportedDataFormatErr", kVTVideoDecoderUnsupportedDataFormatErr),
        ("kVTVideoDecoderMalfunctionErr", kVTVideoDecoderMalfunctionErr),
        ("kVTVideoEncoderMalfunctionErr", kVTVideoEncoderMalfunctionErr),
        ("kVTVideoDecoderNotAvailableNowErr", kVTVideoDecoderNotAvailableNowErr),
        ("kVTImageRotationNotSupportedErr", kVTImageRotationNotSupportedErr),
        ("kVTPixelRotationNotSupportedErr", kVTPixelRotationNotSupportedErr),
        ("kVTVideoEncoderNotAvailableNowErr", kVTVideoEncoderNotAvailableNowErr),
        ("kVTFormatDescriptionChangeNotSupportedErr", kVTFormatDescriptionChangeNotSupportedErr),
        ("kVTInsufficientSourceColorDataErr", kVTInsufficientSourceColorDataErr),
        ("kVTCouldNotCreateColorCorrectionDataErr", kVTCouldNotCreateColorCorrectionDataErr),
        ("kVTColorSyncTransformConvertFailedErr", kVTColorSyncTransformConvertFailedErr),
        ("kVTVideoDecoderAuthorizationErr", kVTVideoDecoderAuthorizationErr),
        ("kVTVideoEncoderAuthorizationErr", kVTVideoEncoderAuthorizationErr),
        ("kVTColorCorrectionPixelTransferFailedErr", kVTColorCorrectionPixelTransferFailedErr),
        ("kVTMultiPassStorageIdentifierMismatchErr", kVTMultiPassStorageIdentifierMismatchErr),
        ("kVTMultiPassStorageInvalidErr", kVTMultiPassStorageInvalidErr),
        ("kVTFrameSiloInvalidTimeStampErr", kVTFrameSiloInvalidTimeStampErr),
        ("kVTFrameSiloInvalidTimeRangeErr", kVTFrameSiloInvalidTimeRangeErr),
        ("kVTCouldNotFindTemporalFilterErr", kVTCouldNotFindTemporalFilterErr),
        ("kVTPixelTransferNotPermittedErr", kVTPixelTransferNotPermittedErr),
        ("kVTColorCorrectionImageRotationFailedErr", kVTColorCorrectionImageRotationFailedErr),
        ("kVTVideoDecoderRemovedErr", kVTVideoDecoderRemovedErr),
        ("kVTSessionMalfunctionErr", kVTSessionMalfunctionErr),
        ("kVTVideoDecoderNeedsRosettaErr", kVTVideoDecoderNeedsRosettaErr),
        ("kVTVideoEncoderNeedsRosettaErr", kVTVideoEncoderNeedsRosettaErr),
        ("kVTVideoDecoderReferenceMissingErr", kVTVideoDecoderReferenceMissingErr),
        ("kVTVideoDecoderCallbackMessagingErr", kVTVideoDecoderCallbackMessagingErr),
        ("kVTVideoDecoderUnknownErr", kVTVideoDecoderUnknownErr),
        ("kVTExtensionDisabledErr", kVTExtensionDisabledErr),
        ("kVTVideoEncoderMVHEVCVideoLayerIDsMismatchErr", kVTVideoEncoderMVHEVCVideoLayerIDsMismatchErr),
        ("kVTCouldNotOutputTaggedBufferGroupErr", kVTCouldNotOutputTaggedBufferGroupErr),
        ("kVTCouldNotFindExtensionErr", kVTCouldNotFindExtensionErr),
        ("kVTExtensionConflictErr", kVTExtensionConflictErr),
        ("kVTVideoEncoderAutoWhiteBalanceNotLockedErr", kVTVideoEncoderAutoWhiteBalanceNotLockedErr),
    ]
}
