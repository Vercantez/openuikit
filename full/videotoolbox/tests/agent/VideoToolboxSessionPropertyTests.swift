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

func testSessionPropertyRoundTrip() {
    var transfer: OpaquePointer?
    vtExpectStatus(VTPixelTransferSessionCreate(sessionOut: &transfer), 0, "property fixture")
    vtExpectStatus(
        VTSessionSetProperty(transfer, key: kVTPixelTransferPropertyKey_ScalingMode, value: kVTScalingMode_Trim),
        0,
        "VTSessionSetProperty"
    )
    var copied: String?
    vtExpectStatus(
        VTSessionCopyProperty(transfer, key: kVTPixelTransferPropertyKey_ScalingMode, valueOut: &copied),
        0,
        "VTSessionCopyProperty"
    )
    vtExpect(copied == kVTScalingMode_Trim, "copied scaling mode")
    vtExpectStatus(
        VTSessionSetProperty(transfer, key: kVTPixelTransferPropertyKey_ScalingMode, value: "not-a-mode"),
        kVTParameterErr,
        "bad scaling"
    )
    vtExpectStatus(
        VTSessionSetProperties(transfer, properties: [kVTPixelTransferPropertyKey_ScalingMode: kVTScalingMode_Normal]),
        0,
        "VTSessionSetProperties"
    )
    copied = nil
    vtExpectStatus(
        VTSessionCopyProperty(transfer, key: kVTPixelTransferPropertyKey_ScalingMode, valueOut: &copied),
        0,
        "copy after set properties"
    )
    vtExpect(copied == kVTScalingMode_Normal, "set properties value")

    var dump: [String: String] = [:]
    vtExpectStatus(VTSessionCopySerializableProperties(transfer, propertiesOut: &dump), 0, "VTSessionCopySerializableProperties")
    vtExpect(dump[kVTPixelTransferPropertyKey_ScalingMode] == kVTScalingMode_Normal, "serializable dump")
    var catalog: [String: String] = [:]
    vtExpectStatus(VTSessionCopySupportedPropertyDictionary(transfer, propertiesOut: &catalog), 0, "VTSessionCopySupportedPropertyDictionary")
    vtExpect(catalog[kVTPixelTransferPropertyKey_ScalingMode]?.contains(kVTPropertyType_Enumeration) == true, "enum type")
    vtExpectStatus(
        VTSessionSetProperty(transfer, key: "not-a-real-key", value: "x"),
        kVTPropertyNotSupportedErr,
        "unknown key"
    )
    vtExpectStatus(VTSessionSetProperty(nil, key: kVTPixelTransferPropertyKey_ScalingMode, value: kVTScalingMode_Trim), kVTInvalidSessionErr, "nil session")
    VTPixelTransferSessionInvalidate(transfer)

    var decoder: OpaquePointer?
    let format = VTVideoFormatDescription(codecType: kVTPixelFormat_32BGRA, width: 4, height: 4)
    vtExpectStatus(
        VTDecompressionSessionCreate(formatDescription: format, outputCallback: nil, sessionOut: &decoder),
        0,
        "decomp property fixture"
    )
    vtExpectStatus(VTSessionSetProperty(decoder, key: kVTDecompressionPropertyKey_ThreadCount, value: "4"), 0, "set threads")
    copied = nil
    vtExpectStatus(VTSessionCopyProperty(decoder, key: kVTDecompressionPropertyKey_ThreadCount, valueOut: &copied), 0, "copy threads")
    vtExpect(copied == "4", "thread value")
    vtExpectStatus(VTSessionSetProperty(decoder, key: kVTDecompressionPropertyKey_ThreadCount, value: "0"), kVTParameterErr, "thread range")
    vtExpectStatus(
        VTSessionSetProperty(decoder, key: kVTDecompressionPropertyKey_UsingHardwareAcceleratedVideoDecoder, value: "true"),
        kVTPropertyReadOnlyErr,
        "hw decoder readonly"
    )
    VTDecompressionSessionInvalidate(decoder)
}
