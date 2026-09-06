import CoreFoundation
import CoreMedia
import Foundation

func testCMReadySampleBufferDataBufferAndTiming() {
    let data = CMReadOnlyDataBlockBuffer(Data([1, 2, 3, 4]))
    let format = try! CMFormatDescription(
        mediaType: .video,
        mediaSubType: .h264,
        extensions: nil
    )
    let properties = CMSampleBuffer.SamplePropertiesCollection(
        sampleCount: 1,
        sizes: .uniform(4),
        timings: .sequential(
            startingAt: CMSampleTimingInfo(
                duration: CMTime(value: 1, timescale: 30),
                presentationTimeStamp: CMTime(value: 10, timescale: 30),
                decodeTimeStamp: CMTime(value: 9, timescale: 30)
            )
        )
    )
    var ready = try! CMReadySampleBuffer<CMReadOnlyDataBlockBuffer>(
        dataBuffer: data,
        formatDescription: format,
        sampleProperties: properties
    )
    precondition(ready.formatDescription === format)
    precondition(ready.sampleCount == 1)
    precondition(ready.totalSampleSize == 4)
    precondition(ready.duration.value == 1)
    precondition(ready.presentationTimeStamp.value == 10)
    precondition(ready.decodeTimeStamp.value == 9)
    precondition(ready.outputDecodeTimeStamp.value == 9)
    precondition(ready.outputPresentationTimeStamp.value == 10)
    ready.presentationTimeStamp = CMTime(value: 11, timescale: 30)
    precondition(ready.presentationTimeStamp.value == 11)
    ready.duration = CMTime(value: 2, timescale: 30)
    precondition(ready.duration.value == 2)
    ready.decodeTimeStamp = CMTime(value: 8, timescale: 30)
    precondition(ready.decodeTimeStamp.value == 8)
    ready.outputPresentationTimeStamp = CMTime(value: 12, timescale: 30)
    precondition(ready.outputPresentationTimeStamp.value == 12)
    ready.sampleAttachments.displayImmediately = true
    precondition(ready.sampleAttachments.displayImmediately)
    precondition(ready.sampleProperties.sampleCount == 1)
    precondition(ready.splitSamples().count == 1)
    precondition(ready.content.count == 4)
    let unsafe = CMReadySampleBuffer<CMReadOnlyDataBlockBuffer>(unsafeWithDataBuffer: ready.sampleBuffer)
    precondition(unsafe.sampleBuffer === ready.sampleBuffer)
    let wrapped = CMReadySampleBuffer<CMReadOnlyDataBlockBuffer>(ready.sampleBuffer)
    precondition(wrapped != nil)
}

func testCMReadySampleBufferMarkerAndUnsafeBuffer() {
    let marker = try! CMReadySampleBuffer<CMReadOnlyDataBlockBuffer>(
        markerAt: CMTime(value: 5, timescale: 1),
        duration: CMTime(value: 1, timescale: 1)
    )
    precondition(marker.markerTimeStamp.value == 5)
    precondition(marker.duration.value == 1)
    let sample = try! CMSampleBuffer(
        dataBuffer: CMBlockBuffer(data: Data([9])),
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [CMSampleTimingInfo(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)],
        sampleSizes: [1],
        dataReady: true
    )
    let unsafe = CMReadySampleBuffer<CMReadOnlyDataBlockBuffer>(unsafeBuffer: sample)
    precondition(unsafe.sampleBuffer === sample)
    let optional = CMReadySampleBuffer<CMReadOnlyDataBlockBuffer>(sample)
    precondition(optional != nil)
}
