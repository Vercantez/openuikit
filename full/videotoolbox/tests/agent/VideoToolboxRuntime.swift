import VideoToolbox

func expect(_ condition: Bool, _ message: String) {
    guard condition else {
        fatalError("VIDEOTOOLBOX_RUNTIME_FAIL \(message)")
    }
}

expect(kVTPropertyNotSupportedErr == -12900, "kVTPropertyNotSupportedErr")
expect(kVTParameterErr == -12902, "kVTParameterErr")
expect(kVTInvalidSessionErr == -12903, "kVTInvalidSessionErr")
expect(kVTCouldNotFindVideoDecoderErr == -12906, "decoder missing")
expect(kVTCouldNotFindVideoEncoderErr == -12908, "encoder missing")
expect(kVTPixelTransferNotSupportedErr == -12905, "pixel transfer")
expect(kVTPixelRotationNotSupportedErr == -12914, "pixel rotation")
expect(kVTCouldNotFindExtensionErr == -19510, "extension")

expect(VTDecodeFrameFlags.enableAsynchronousDecompression.rawValue == kVTDecodeFrame_EnableAsynchronousDecompression, "decode flag")
expect(VTEncodeInfoFlags.frameDropped.contains(.frameDropped), "encode flag")

var compression: OpaquePointer?
let compressionStatus = VTCompressionSessionCreate(
    width: 1280,
    height: 720,
    codecType: 0x61766331,
    sessionOut: &compression
)
expect(compressionStatus == kVTCouldNotFindVideoEncoderErr, "compression create")
expect(compression == nil, "compression session nil")

var badSize: OpaquePointer?
expect(
    VTCompressionSessionCreate(width: 0, height: 720, codecType: 0x61766331, sessionOut: &badSize)
        == kVTParameterErr,
    "compression parameter"
)

var decompression: OpaquePointer?
expect(
    VTDecompressionSessionCreate(sessionOut: &decompression) == kVTCouldNotFindVideoDecoderErr,
    "decompression create"
)

expect(VTIsHardwareDecodeSupported(0x61766331) == false, "hardware decode")
expect(VTIsStereoMVHEVCDecodeSupported() == false, "mv-hevc decode")
expect(VTIsStereoMVHEVCEncodeSupported() == false, "mv-hevc encode")

var encoders: [String] = ["sentinel"]
expect(VTCopyVideoEncoderList(&encoders) == 0, "encoder list status")
expect(encoders.isEmpty, "encoder list empty")

var transfer: OpaquePointer?
expect(VTPixelTransferSessionCreate(sessionOut: &transfer) == 0, "pixel transfer create")
expect(transfer != nil, "pixel transfer session")
expect(
    VTSessionSetProperty(transfer, key: kVTPixelTransferPropertyKey_ScalingMode, value: "Trim") == 0,
    "set property"
)
var copied: String?
expect(
    VTSessionCopyProperty(transfer, key: kVTPixelTransferPropertyKey_ScalingMode, valueOut: &copied) == 0,
    "copy property"
)
expect(copied == "Trim", "copied scaling mode")
var dump: [String: String] = [:]
expect(VTSessionCopySerializableProperties(transfer, propertiesOut: &dump) == 0, "serializable")
expect(dump[kVTPixelTransferPropertyKey_ScalingMode] == "Trim", "dump")
expect(
    VTPixelTransferSessionTransferImage(transfer, source: nil, destination: nil)
        == kVTPixelTransferNotSupportedErr,
    "transfer image"
)
VTPixelTransferSessionInvalidate(transfer)
expect(VTSessionSetProperty(transfer, key: "x", value: "y") == kVTInvalidSessionErr, "invalid after invalidate")

var rotation: OpaquePointer?
expect(VTPixelRotationSessionCreate(sessionOut: &rotation) == 0, "rotation create")
expect(
    VTPixelRotationSessionRotateImage(rotation, source: nil, destination: nil)
        == kVTPixelRotationNotSupportedErr,
    "rotate"
)
VTPixelRotationSessionInvalidate(rotation)

var image: OpaquePointer?
expect(VTCreateCGImageFromCVPixelBuffer(pixelBuffer: nil, imageOut: &image) == kVTParameterErr, "cgimage nil")
var image2: OpaquePointer?
let fakeBuffer = OpaquePointer(bitPattern: 0x11)!
expect(
    VTCreateCGImageFromCVPixelBuffer(pixelBuffer: fakeBuffer, imageOut: &image2)
        == kVTAllocationFailedErr,
    "cgimage fail-closed"
)

var silo: OpaquePointer?
expect(VTFrameSiloCreate(siloOut: &silo) == kVTAllocationFailedErr, "frame silo")
var storage: OpaquePointer?
expect(VTMultiPassStorageCreate(storageOut: &storage) == kVTAllocationFailedErr, "multipass")
var raw: OpaquePointer?
expect(VTRAWProcessingSessionCreate(sessionOut: &raw) == kVTCouldNotFindExtensionErr, "raw")
var motion: OpaquePointer?
expect(VTMotionEstimationSessionCreate(sessionOut: &motion) == kVTCouldNotFindTemporalFilterErr, "motion")
var hdr: OpaquePointer?
expect(
    VTHDRPerFrameMetadataGenerationSessionCreate(framesPerSecond: 24, sessionOut: &hdr)
        == kVTAllocationFailedErr,
    "hdr"
)
expect(
    VTHDRPerFrameMetadataGenerationSessionCreate(framesPerSecond: 0, sessionOut: &hdr)
        == kVTParameterErr,
    "hdr fps"
)

expect(!kVTCompressionPropertyKey_AverageBitRate.isEmpty, "key nonempty")
expect(
    kVTCompressionPropertyKey_AverageBitRate != kVTCompressionPropertyKey_Quality,
    "keys distinct"
)

print("VIDEOTOOLBOX_AGENT_RUNTIME_OK")
