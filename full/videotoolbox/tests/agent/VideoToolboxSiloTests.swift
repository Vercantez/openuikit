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

func testFrameSiloSamplePass() {
    var sourceBGRA: OpaquePointer?
    vtExpectStatus(
        VTHostCreatePixelBuffer(width: 4, height: 4, pixelFormat: kVTPixelFormat_32BGRA, pixelBufferOut: &sourceBGRA),
        0,
        "source"
    )
    let bgraFormat = VTVideoFormatDescription(codecType: kVTPixelFormat_32BGRA, width: 4, height: 4)
    var sample: OpaquePointer?
    vtExpectStatus(
        VTHostCreateSampleBuffer(
            format: bgraFormat,
            pixelBuffer: sourceBGRA,
            presentationTimeStamp: VTMediaTime(value: 1, timescale: 1),
            duration: VTMediaTime.zero,
            sampleBufferOut: &sample
        ),
        0,
        "sample"
    )
    var sample2: OpaquePointer?
    vtExpectStatus(
        VTHostCreateSampleBuffer(
            format: bgraFormat,
            pixelBuffer: sourceBGRA,
            presentationTimeStamp: VTMediaTime(value: 2, timescale: 1),
            duration: VTMediaTime.zero,
            sampleBufferOut: &sample2
        ),
        0,
        "sample2"
    )

    var silo: OpaquePointer?
    vtExpectStatus(VTFrameSiloCreate(siloOut: &silo), 0, "VTFrameSiloCreate")
    vtExpect(silo != nil, "silo session")
    vtExpectStatus(VTFrameSiloAddSampleBuffer(silo, sampleBuffer: sample), 0, "VTFrameSiloAddSampleBuffer")
    vtExpectStatus(VTFrameSiloAddSampleBuffer(silo, sampleBuffer: sample2), 0, "add sample2")
    vtExpectStatus(VTFrameSiloSetTimeRangesForNextPass(silo), 0, "VTFrameSiloSetTimeRangesForNextPass")
    var progress = -1.0
    vtExpectStatus(VTFrameSiloGetProgressOfCurrentPass(silo, progressOut: &progress), 0, "VTFrameSiloGetProgressOfCurrentPass")
    let box = VTTestBox()
    vtExpectStatus(
        VTFrameSiloCallFunctionForEachSampleBuffer(silo) { pointer in
            box.visited += 1
            vtExpect(VTHostSampleBufferGetPresentationTimeStamp(pointer).isValid, "silo pts")
            return 0
        },
        0,
        "VTFrameSiloCallFunctionForEachSampleBuffer"
    )
    vtExpect(box.visited == 2, "visited \(box.visited)")
    vtExpectStatus(VTFrameSiloGetProgressOfCurrentPass(silo, progressOut: &progress), 0, "progress after")
    vtExpect(progress == 1, "complete pass")
    vtExpectStatus(VTFrameSiloCallFunctionForEachSampleBuffer(nil), kVTInvalidSessionErr, "foreach nil")
}

func testMultiPassStorageCreateAndClose() {
    var storage: OpaquePointer?
    vtExpectStatus(VTMultiPassStorageCreate(storageOut: &storage), 0, "VTMultiPassStorageCreate")
    vtExpectStatus(VTMultiPassStorageClose(storage), 0, "VTMultiPassStorageClose")
    vtExpectStatus(VTMultiPassStorageClose(nil), kVTInvalidSessionErr, "multipass nil")
}
