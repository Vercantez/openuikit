import Foundation
import VideoToolbox

func vtExpect(_ condition: Bool, _ message: String) {
    guard condition else {
        fatalError("VIDEOTOOLBOX_RUNTIME_FAIL \(message)")
    }
}

func vtExpectStatus(_ status: OSStatus, _ expected: OSStatus, _ message: String) {
    vtExpect(status == expected, "\(message) got \(status) expected \(expected)")
}

final class VTTestBox: @unchecked Sendable {
    var image: OpaquePointer?
    var pts = VTMediaTime.invalid
    var duration = VTMediaTime.invalid
    var count = 0
    var handlerCalled = false
    var visited = 0
}

func testRAWProcessingSessionFailClosed() {
    var raw: OpaquePointer?
    vtExpectStatus(VTRAWProcessingSessionCreate(sessionOut: &raw), kVTCouldNotFindExtensionErr, "VTRAWProcessingSessionCreate")
    VTRAWProcessingSessionInvalidate(raw)
    vtExpect(VTRAWProcessingSessionGetTypeID() == 0, "VTRAWProcessingSessionGetTypeID")
    vtExpectStatus(VTRAWProcessingSessionCompleteFrames(nil), kVTInvalidSessionErr, "VTRAWProcessingSessionCompleteFrames")
    vtExpectStatus(VTRAWProcessingSessionProcessFrame(nil), kVTInvalidSessionErr, "VTRAWProcessingSessionProcessFrame")
    var rawParams: [String: String] = ["a": "b"]
    vtExpectStatus(VTRAWProcessingSessionCopyProcessingParameters(nil, parametersOut: &rawParams), kVTInvalidSessionErr, "VTRAWProcessingSessionCopyProcessingParameters")
    vtExpectStatus(VTRAWProcessingSessionSetProcessingParameters(nil, parameters: ["k": "v"]), kVTInvalidSessionErr, "VTRAWProcessingSessionSetProcessingParameters")
    vtExpectStatus(VTRAWProcessingSessionSetParameterChangedHandler(nil), kVTInvalidSessionErr, "VTRAWProcessingSessionSetParameterChangedHandler")
    vtExpectStatus(VTRAWProcessingSessionSetParameterChangedHander(nil), kVTInvalidSessionErr, "VTRAWProcessingSessionSetParameterChangedHander")
}

func testMotionEstimationSessionFailClosed() {
    var motion: OpaquePointer?
    vtExpectStatus(VTMotionEstimationSessionCreate(sessionOut: &motion), kVTCouldNotFindTemporalFilterErr, "VTMotionEstimationSessionCreate")
    VTMotionEstimationSessionInvalidate(motion)
    vtExpect(VTMotionEstimationSessionGetTypeID() == 0, "VTMotionEstimationSessionGetTypeID")
}

func testHDRMetadataSessionFailClosed() {
    var hdr: OpaquePointer?
    vtExpectStatus(
        VTHDRPerFrameMetadataGenerationSessionCreate(framesPerSecond: 24, sessionOut: &hdr),
        kVTAllocationFailedErr,
        "VTHDRPerFrameMetadataGenerationSessionCreate"
    )
    vtExpectStatus(
        VTHDRPerFrameMetadataGenerationSessionCreate(framesPerSecond: 0, sessionOut: &hdr),
        kVTParameterErr,
        "hdr fps"
    )
    VTHDRPerFrameMetadataGenerationSessionInvalidate(hdr)
    vtExpect(VTHDRPerFrameMetadataGenerationSessionGetTypeID() == 0, "VTHDRPerFrameMetadataGenerationSessionGetTypeID")
}

func testHardwareAndEncoderDiscovery() {
    vtExpect(VTIsHardwareDecodeSupported(kVTVideoCodecType_H264) == false, "VTIsHardwareDecodeSupported h264")
    vtExpect(VTIsHardwareDecodeSupported(kVTPixelFormat_32BGRA) == false, "VTIsHardwareDecodeSupported bgra")
    vtExpect(VTIsStereoMVHEVCDecodeSupported() == false, "VTIsStereoMVHEVCDecodeSupported")
    vtExpect(VTIsStereoMVHEVCEncodeSupported() == false, "VTIsStereoMVHEVCEncodeSupported")

    var encoders: [String] = ["sentinel"]
    vtExpectStatus(VTCopyVideoEncoderList(&encoders), 0, "VTCopyVideoEncoderList")
    vtExpect(encoders.isEmpty, "encoder list empty")

    var encoderID: String?
    var encoderProps: [String: String] = ["x": "y"]
    vtExpectStatus(
        VTCopySupportedPropertyDictionaryForEncoder(
            width: 64,
            height: 64,
            codecType: kVTVideoCodecType_H264,
            encoderIdentifierOut: &encoderID,
            propertiesOut: &encoderProps
        ),
        kVTCouldNotFindVideoEncoderErr,
        "VTCopySupportedPropertyDictionaryForEncoder"
    )
    vtExpect(encoderID == nil, "encoder id nil")
    vtExpect(encoderProps.isEmpty, "encoder props empty")
}

func testProfessionalWorkflowRegistration() {
    VTRegisterProfessionalVideoWorkflowVideoDecoders()
    VTRegisterProfessionalVideoWorkflowVideoEncoders()
    VTRegisterSupplementalVideoDecoderIfAvailable(kVTVideoCodecType_H264)
}

func testExtensionPropertyQueries() {
    var extProps: [String: String] = ["x": "y"]
    vtExpectStatus(VTCopyVideoDecoderExtensionProperties(&extProps), kVTCouldNotFindExtensionErr, "VTCopyVideoDecoderExtensionProperties")
    vtExpect(extProps.isEmpty, "decoder ext empty")
    vtExpectStatus(VTCopyRAWProcessorExtensionProperties(&extProps), kVTCouldNotFindExtensionErr, "VTCopyRAWProcessorExtensionProperties")
}
