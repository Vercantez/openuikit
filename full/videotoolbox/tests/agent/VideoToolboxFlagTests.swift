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

func testOptionSetAndFlagRawValues() {
    let decodeAsync = VTDecodeFrameFlags.enableAsynchronousDecompression
    vtExpect(decodeAsync.rawValue == 1, "decode async rawValue")
    vtExpect(decodeAsync.rawValue == kVTDecodeFrame_EnableAsynchronousDecompression, "kVTDecodeFrame_EnableAsynchronousDecompression")
    vtExpect(VTDecodeFrameFlags.doNotOutputFrame.rawValue == kVTDecodeFrame_DoNotOutputFrame, "kVTDecodeFrame_DoNotOutputFrame")
    vtExpect(VTDecodeFrameFlags.oneXRealTimePlayback.rawValue == kVTDecodeFrame_1xRealTimePlayback, "kVTDecodeFrame_1xRealTimePlayback")
    vtExpect(VTDecodeFrameFlags.enableTemporalProcessing.rawValue == kVTDecodeFrame_EnableTemporalProcessing, "kVTDecodeFrame_EnableTemporalProcessing")
    vtExpect(VTDecodeFrameFlags(rawValue: 3).rawValue == 3, "VTDecodeFrameFlags init(rawValue:)")

    vtExpect(VTDecodeInfoFlags.asynchronous.rawValue == kVTDecodeInfo_Asynchronous, "kVTDecodeInfo_Asynchronous")
    vtExpect(VTDecodeInfoFlags.frameDropped.rawValue == kVTDecodeInfo_FrameDropped, "kVTDecodeInfo_FrameDropped")
    vtExpect(VTDecodeInfoFlags.imageBufferModifiable.rawValue == kVTDecodeInfo_ImageBufferModifiable, "kVTDecodeInfo_ImageBufferModifiable")
    vtExpect(VTDecodeInfoFlags.skippedLeadingFrameDropped.rawValue == kVTDecodeInfo_SkippedLeadingFrameDropped, "kVTDecodeInfo_SkippedLeadingFrameDropped")
    vtExpect(VTDecodeInfoFlags.frameInterrupted.rawValue == kVTDecodeInfo_FrameInterrupted, "kVTDecodeInfo_FrameInterrupted")
    vtExpect(VTDecodeInfoFlags(rawValue: 16).rawValue == 16, "VTDecodeInfoFlags init(rawValue:)")

    vtExpect(VTEncodeInfoFlags.asynchronous.rawValue == kVTEncodeInfo_Asynchronous, "kVTEncodeInfo_Asynchronous")
    vtExpect(VTEncodeInfoFlags.frameDropped.contains(.frameDropped), "VTEncodeInfoFlags.frameDropped")
    vtExpect(VTEncodeInfoFlags.frameDropped.rawValue == kVTEncodeInfo_FrameDropped, "kVTEncodeInfo_FrameDropped")
    vtExpect(VTEncodeInfoFlags(rawValue: 2).rawValue == 2, "VTEncodeInfoFlags init(rawValue:)")

    vtExpect(VTCompressionSessionOptionFlags.beginFinalPass.rawValue == kVTCompressionSessionBeginFinalPass, "kVTCompressionSessionBeginFinalPass")
    vtExpect(VTCompressionSessionOptionFlags(rawValue: 1).rawValue == 1, "VTCompressionSessionOptionFlags init(rawValue:)")
    vtExpect(VTCompressionSessionOptionFlags.beginFinalPass.rawValue == 1, "beginFinalPass rawValue")
}
