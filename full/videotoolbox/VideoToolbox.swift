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

private enum LinuxVTKind: Equatable {
    case pixelTransfer
    case pixelRotation
}

private final class LinuxVTSession {
    let kind: LinuxVTKind
    var properties: [String: String]
    var valid: Bool

    init(kind: LinuxVTKind) {
        self.kind = kind
        self.properties = [:]
        self.valid = true
    }
}

private let sessionLock = NSLock()
private var sessionTable: [UInt: LinuxVTSession] = [:]
private var nextSessionID: UInt = 1

private func storeSession(_ session: LinuxVTSession) -> OpaquePointer {
    sessionLock.lock()
    defer { sessionLock.unlock() }
    nextSessionID += 1
    let identifier = nextSessionID
    sessionTable[identifier] = session
    return OpaquePointer(bitPattern: Int(identifier))!
}

private func lookupSession(_ pointer: OpaquePointer?) -> LinuxVTSession? {
    guard let pointer else { return nil }
    let identifier = UInt(bitPattern: pointer)
    sessionLock.lock()
    defer { sessionLock.unlock() }
    return sessionTable[identifier]
}

private func removeSession(_ pointer: OpaquePointer?) {
    guard let pointer else { return }
    let identifier = UInt(bitPattern: pointer)
    sessionLock.lock()
    sessionTable[identifier] = nil
    sessionLock.unlock()
}

private func statusForSession(_ pointer: OpaquePointer?) -> OSStatus {
    guard let session = lookupSession(pointer) else {
        return kVTInvalidSessionErr
    }
    return session.valid ? 0 : kVTInvalidSessionErr
}

public func VTCompressionSessionCreate(
    width: Int32,
    height: Int32,
    codecType: UInt32,
    sessionOut: inout OpaquePointer?
) -> OSStatus {
    sessionOut = nil
    if width <= 0 || height <= 0 || codecType == 0 {
        return kVTParameterErr
    }
    return kVTCouldNotFindVideoEncoderErr
}

public func VTCompressionSessionInvalidate(_ session: OpaquePointer?) {
    removeSession(session)
}

public func VTCompressionSessionEncodeFrame(_ session: OpaquePointer?) -> OSStatus {
    _ = session
    return kVTInvalidSessionErr
}

public func VTCompressionSessionCompleteFrames(_ session: OpaquePointer?) -> OSStatus {
    _ = session
    return kVTInvalidSessionErr
}

public func VTCompressionSessionPrepareToEncodeFrames(_ session: OpaquePointer?) -> OSStatus {
    _ = session
    return kVTInvalidSessionErr
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
    _ = session
    return kVTInvalidSessionErr
}

public func VTCompressionSessionEndPass(
    _ session: OpaquePointer?,
    furtherPassesRequestedOut: inout Bool
) -> OSStatus {
    furtherPassesRequestedOut = false
    _ = session
    return kVTInvalidSessionErr
}

public func VTCompressionSessionGetTimeRangesForNextPass(_ session: OpaquePointer?) -> OSStatus {
    _ = session
    return kVTInvalidSessionErr
}

public func VTDecompressionSessionCreate(sessionOut: inout OpaquePointer?) -> OSStatus {
    sessionOut = nil
    return kVTCouldNotFindVideoDecoderErr
}

public func VTDecompressionSessionInvalidate(_ session: OpaquePointer?) {
    removeSession(session)
}

public func VTDecompressionSessionDecodeFrame(_ session: OpaquePointer?) -> OSStatus {
    _ = session
    return kVTInvalidSessionErr
}

public func VTDecompressionSessionDecodeFrameWithOutputHandler(_ session: OpaquePointer?) -> OSStatus {
    _ = session
    return kVTInvalidSessionErr
}

public func VTDecompressionSessionDecodeFrameWithMultiImageCapableOutputHandler(
    _ session: OpaquePointer?
) -> OSStatus {
    _ = session
    return kVTInvalidSessionErr
}

public func VTDecompressionSessionFinishDelayedFrames(_ session: OpaquePointer?) -> OSStatus {
    _ = session
    return kVTInvalidSessionErr
}

public func VTDecompressionSessionWaitForAsynchronousFrames(_ session: OpaquePointer?) -> OSStatus {
    _ = session
    return kVTInvalidSessionErr
}

public func VTDecompressionSessionCanAcceptFormatDescription(_ session: OpaquePointer?) -> Bool {
    _ = session
    return false
}

public func VTDecompressionSessionCopyBlackPixelBuffer(
    _ session: OpaquePointer?,
    pixelBufferOut: inout OpaquePointer?
) -> OSStatus {
    pixelBufferOut = nil
    _ = session
    return kVTInvalidSessionErr
}

public func VTSessionSetProperty(_ session: OpaquePointer?, key: String, value: String) -> OSStatus {
    guard let box = lookupSession(session), box.valid else {
        return kVTInvalidSessionErr
    }
    if key.isEmpty {
        return kVTParameterErr
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
    guard let box = lookupSession(session), box.valid else {
        return kVTInvalidSessionErr
    }
    if key.isEmpty {
        return kVTParameterErr
    }
    guard let value = box.properties[key] else {
        return kVTPropertyNotSupportedErr
    }
    valueOut = value
    return 0
}

public func VTSessionSetProperties(
    _ session: OpaquePointer?,
    properties: [String: String]
) -> OSStatus {
    guard let box = lookupSession(session), box.valid else {
        return kVTInvalidSessionErr
    }
    for (key, value) in properties {
        box.properties[key] = value
    }
    return 0
}

public func VTSessionCopySerializableProperties(
    _ session: OpaquePointer?,
    propertiesOut: inout [String: String]
) -> OSStatus {
    propertiesOut = [:]
    guard let box = lookupSession(session), box.valid else {
        return kVTInvalidSessionErr
    }
    propertiesOut = box.properties
    return 0
}

public func VTSessionCopySupportedPropertyDictionary(
    _ session: OpaquePointer?,
    propertiesOut: inout [String: String]
) -> OSStatus {
    propertiesOut = [:]
    guard let box = lookupSession(session), box.valid else {
        return kVTInvalidSessionErr
    }
    propertiesOut = box.properties
    return 0
}

public func VTPixelTransferSessionCreate(sessionOut: inout OpaquePointer?) -> OSStatus {
    let box = LinuxVTSession(kind: .pixelTransfer)
    sessionOut = storeSession(box)
    return 0
}

public func VTPixelTransferSessionInvalidate(_ session: OpaquePointer?) {
    if let box = lookupSession(session) {
        box.valid = false
    }
    removeSession(session)
}

public func VTPixelTransferSessionTransferImage(
    _ session: OpaquePointer?,
    source: OpaquePointer?,
    destination: OpaquePointer?
) -> OSStatus {
    _ = source
    _ = destination
    let status = statusForSession(session)
    if status != 0 {
        return status
    }
    return kVTPixelTransferNotSupportedErr
}

public func VTPixelTransferSessionGetTypeID() -> UInt {
    return 0
}

public func VTPixelRotationSessionCreate(sessionOut: inout OpaquePointer?) -> OSStatus {
    let box = LinuxVTSession(kind: .pixelRotation)
    sessionOut = storeSession(box)
    return 0
}

public func VTPixelRotationSessionInvalidate(_ session: OpaquePointer?) {
    if let box = lookupSession(session) {
        box.valid = false
    }
    removeSession(session)
}

public func VTPixelRotationSessionRotateImage(
    _ session: OpaquePointer?,
    source: OpaquePointer?,
    destination: OpaquePointer?
) -> OSStatus {
    _ = source
    _ = destination
    let status = statusForSession(session)
    if status != 0 {
        return status
    }
    return kVTPixelRotationNotSupportedErr
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
    return kVTAllocationFailedErr
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
    storageOut = nil
    return kVTAllocationFailedErr
}

public func VTMultiPassStorageClose(_ storage: OpaquePointer?) -> OSStatus {
    _ = storage
    return kVTInvalidSessionErr
}

public func VTFrameSiloCreate(siloOut: inout OpaquePointer?) -> OSStatus {
    siloOut = nil
    return kVTAllocationFailedErr
}

public func VTFrameSiloAddSampleBuffer(_ silo: OpaquePointer?, sampleBuffer: OpaquePointer?) -> OSStatus {
    _ = silo
    _ = sampleBuffer
    return kVTInvalidSessionErr
}

public func VTFrameSiloSetTimeRangesForNextPass(_ silo: OpaquePointer?) -> OSStatus {
    _ = silo
    return kVTInvalidSessionErr
}

public func VTFrameSiloGetProgressOfCurrentPass(
    _ silo: OpaquePointer?,
    progressOut: inout Double
) -> OSStatus {
    progressOut = 0
    _ = silo
    return kVTInvalidSessionErr
}

public func VTFrameSiloCallFunctionForEachSampleBuffer(_ silo: OpaquePointer?) -> OSStatus {
    _ = silo
    return kVTInvalidSessionErr
}

public func VTRAWProcessingSessionCreate(sessionOut: inout OpaquePointer?) -> OSStatus {
    sessionOut = nil
    return kVTCouldNotFindExtensionErr
}

public func VTRAWProcessingSessionInvalidate(_ session: OpaquePointer?) {
    removeSession(session)
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
    removeSession(session)
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
    removeSession(session)
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
    _ = session
    return kVTInvalidSessionErr
}

public func VTDecompressionSessionDecodeFrameWithOptionsAndOutputHandler(
    _ session: OpaquePointer?
) -> OSStatus {
    _ = session
    return kVTInvalidSessionErr
}

public func VTDecompressionSessionSetMultiImageCallback(_ session: OpaquePointer?) -> OSStatus {
    _ = session
    return kVTInvalidSessionErr
}

public func VTMotionEstimationSessionGetTypeID() -> UInt {
    return 0
}
