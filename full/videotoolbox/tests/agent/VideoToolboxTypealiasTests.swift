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

func testSessionRefTypealiases() {
    vtExpect(MemoryLayout<VTSessionRef>.size == MemoryLayout<OpaquePointer>.size, "VTSessionRef")
    vtExpect(MemoryLayout<VTFrameSiloRef>.size == MemoryLayout<OpaquePointer>.size, "VTFrameSiloRef")
    vtExpect(MemoryLayout<VTMultiPassStorageRef>.size == MemoryLayout<OpaquePointer>.size, "VTMultiPassStorageRef")
    vtExpect(MemoryLayout<VTCompressionSessionRef>.size == MemoryLayout<OpaquePointer>.size, "VTCompressionSessionRef")
    vtExpect(MemoryLayout<VTDecompressionSessionRef>.size == MemoryLayout<OpaquePointer>.size, "VTDecompressionSessionRef")
    vtExpect(MemoryLayout<VTPixelRotationSessionRef>.size == MemoryLayout<OpaquePointer>.size, "VTPixelRotationSessionRef")
    vtExpect(MemoryLayout<VTPixelTransferSessionRef>.size == MemoryLayout<OpaquePointer>.size, "VTPixelTransferSessionRef")
    vtExpect(MemoryLayout<VTRAWProcessingSessionRef>.size == MemoryLayout<OpaquePointer>.size, "VTRAWProcessingSessionRef")
    vtExpect(MemoryLayout<VTMotionEstimationSessionRef>.size == MemoryLayout<OpaquePointer>.size, "VTMotionEstimationSessionRef")
    vtExpect(MemoryLayout<VTHDRPerFrameMetadataGenerationSessionRef>.size == MemoryLayout<OpaquePointer>.size, "VTHDRPerFrameMetadataGenerationSessionRef")
    vtExpect(MemoryLayout<OSStatus>.size == MemoryLayout<Int32>.size, "OSStatus")
    _ = VTSessionRef.self
    _ = VTFrameSiloRef.self
    _ = VTMultiPassStorageRef.self
    _ = VTCompressionSessionRef.self
    _ = VTDecompressionSessionRef.self
    _ = VTPixelRotationSessionRef.self
    _ = VTPixelTransferSessionRef.self
    _ = VTRAWProcessingSessionRef.self
    _ = VTMotionEstimationSessionRef.self
    _ = VTHDRPerFrameMetadataGenerationSessionRef.self
    _ = OSStatus.self
}
