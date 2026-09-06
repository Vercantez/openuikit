import CoreFoundation
import CoreMedia
import Dispatch
import Foundation

func testCMSampleBufferMakeDataReadyCallback() {
    let data = CMBlockBuffer(data: Data([1, 2, 3, 4]))
    var sample: CMSampleBuffer?
    var callbackRuns = 0
    let callback: CMSampleBufferMakeDataReadyCallback = { buffer, _ in
        callbackRuns += 1
        precondition(!CMSampleBufferDataIsReady(buffer))
        return 0
    }
    precondition(
        CMSampleBufferCreate(
            allocator: nil,
            dataBuffer: data,
            dataReady: false,
            makeDataReadyCallback: callback,
            makeDataReadyRefcon: nil,
            formatDescription: nil,
            sampleCount: 1,
            sampleTimingEntryCount: 0,
            sampleTimingArray: nil,
            sampleSizeEntryCount: 0,
            sampleSizeArray: nil,
            sampleBufferOut: &sample
        ) == 0
    )
    precondition(!CMSampleBufferDataIsReady(sample!))
    precondition(CMSampleBufferMakeDataReady(sample!) == 0)
    precondition(callbackRuns == 1)
    precondition(CMSampleBufferDataIsReady(sample!))
}

func testCMTimeMapDurationFromRangeToRangeAndShow() {
    let from = CMTimeRange(start: .zero, duration: CMTime(value: 2, timescale: 1))
    let to = CMTimeRange(start: .zero, duration: CMTime(value: 10, timescale: 1))
    let mapped = CMTimeMapDurationFromRangeToRange(
        CMTime(value: 1, timescale: 1),
        fromRange: from,
        toRange: to
    )
    precondition(abs(CMTimeGetSeconds(mapped) - 5.0) < 0.0001)
    CMTimeShow(mapped)
}

func testCMAudioClockCreateUnsupported() {
    var clock: CMClock?
    precondition(CMAudioClockCreate(allocator: nil, clockOut: &clock) == kCMClockError_UnsupportedOperation)
    precondition(clock == nil)
}

func testCMTimebaseDispatchSourceTimersFailClosed() {
    let clock = CMClockGetHostTimeClock()
    var timebase: CMTimebase?
    precondition(
        CMTimebaseCreateWithSourceClock(allocator: nil, sourceClock: clock, timebaseOut: &timebase) == 0
    )
    // Linux libdispatch traps if a timer source is released without resume+cancel.
    let source = DispatchSource.makeTimerSource()
    source.setEventHandler {}
    source.schedule(deadline: DispatchTime.distantFuture)
    source.resume()
    defer { source.cancel() }
    precondition(
        CMTimebaseAddTimerDispatchSource(timebase!, timerSource: source)
            == kCMTimebaseError_TimerIntervalTooShort
    )
    precondition(
        CMTimebaseSetTimerDispatchSourceNextFireTime(
            timebase!,
            timerSource: source,
            fireTime: .zero,
            flags: 0
        ) == kCMTimebaseError_TimerIntervalTooShort
    )
    precondition(
        CMTimebaseSetTimerDispatchSourceToFireImmediately(timebase!, timerSource: source)
            == kCMTimebaseError_TimerIntervalTooShort
    )
    precondition(
        CMTimebaseRemoveTimerDispatchSource(timebase!, timerSource: source)
            == kCMTimebaseError_TimerIntervalTooShort
    )
}

func testCMVideoFormatDescriptionParameterSetsFailClosed() {
    var desc: CMFormatDescription?
    var pointer: UnsafePointer<UInt8> = UnsafePointer(bitPattern: 1)!
    var size = 1
    precondition(
        withUnsafePointer(to: &pointer) { pointerPtr in
            CMVideoFormatDescriptionCreateFromH264ParameterSets(
                allocator: nil,
                parameterSetCount: 1,
                parameterSetPointers: pointerPtr,
                parameterSetSizes: &size,
                nalUnitHeaderLength: 4,
                formatDescriptionOut: &desc
            )
        } == kCMFormatDescriptionError_InvalidParameter
    )
    precondition(desc == nil)
    precondition(
        withUnsafePointer(to: &pointer) { pointerPtr in
            CMVideoFormatDescriptionCreateFromHEVCParameterSets(
                allocator: nil,
                parameterSetCount: 1,
                parameterSetPointers: pointerPtr,
                parameterSetSizes: &size,
                nalUnitHeaderLength: 4,
                extensions: nil,
                formatDescriptionOut: &desc
            )
        } == kCMFormatDescriptionError_InvalidParameter
    )
    let video = try! CMFormatDescription(videoCodecType: .h264, width: 16, height: 16, extensions: nil)
    var outPointer: UnsafePointer<UInt8>?
    var outSize = 1
    var count = 1
    var nal: Int32 = 1
    precondition(
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
            video,
            parameterSetIndex: 0,
            parameterSetPointerOut: &outPointer,
            parameterSetSizeOut: &outSize,
            parameterSetCountOut: &count,
            nalUnitHeaderLengthOut: &nal
        ) == kCMFormatDescriptionError_ValueNotAvailable
    )
    precondition(
        CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(
            video,
            parameterSetIndex: 0,
            parameterSetPointerOut: &outPointer,
            parameterSetSizeOut: &outSize,
            parameterSetCountOut: &count,
            nalUnitHeaderLengthOut: &nal
        ) == kCMFormatDescriptionError_ValueNotAvailable
    )
}

func testCMEndianSampleDescriptionBridgesFailClosed() {
    let buffer = CMBlockBuffer(data: Data([0, 1, 2, 3, 4, 5, 6, 7]))
    var desc: CMFormatDescription?
    var outBuffer: CMBlockBuffer?
    let video = try! CMFormatDescription(videoCodecType: .h264, width: 8, height: 8, extensions: nil)
    precondition(
        CMVideoFormatDescriptionCreateFromBigEndianImageDescriptionBlockBuffer(
            allocator: nil,
            imageDescriptionBlockBuffer: buffer,
            stringEncoding: CFStringBuiltInEncodings.UTF8.rawValue,
            flavor: nil,
            formatDescriptionOut: &desc
        ) == kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor
    )
    let bytes: [UInt8] = [0, 1, 2, 3]
    precondition(
        bytes.withUnsafeBufferPointer { raw in
            CMVideoFormatDescriptionCreateFromBigEndianImageDescriptionData(
                allocator: nil,
                imageDescriptionData: raw.baseAddress!,
                size: raw.count,
                stringEncoding: CFStringBuiltInEncodings.UTF8.rawValue,
                flavor: nil,
                formatDescriptionOut: &desc
            )
        } == kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor
    )
    precondition(
        CMClosedCaptionFormatDescriptionCopyAsBigEndianClosedCaptionDescriptionBlockBuffer(
            allocator: nil,
            closedCaptionFormatDescription: video,
            flavor: nil,
            blockBufferOut: &outBuffer
        ) == kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor
    )
    precondition(
        CMClosedCaptionFormatDescriptionCreateFromBigEndianClosedCaptionDescriptionBlockBuffer(
            allocator: nil,
            bigEndianClosedCaptionDescriptionBlockBuffer: buffer,
            flavor: nil,
            formatDescriptionOut: &desc
        ) == kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor
    )
    precondition(
        bytes.withUnsafeBufferPointer { raw in
            CMClosedCaptionFormatDescriptionCreateFromBigEndianClosedCaptionDescriptionData(
                allocator: nil,
                bigEndianClosedCaptionDescriptionData: raw.baseAddress!,
                size: raw.count,
                flavor: nil,
                formatDescriptionOut: &desc
            )
        } == kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor
    )
    precondition(
        CMMetadataFormatDescriptionCopyAsBigEndianMetadataDescriptionBlockBuffer(
            allocator: nil,
            metadataFormatDescription: video,
            flavor: nil,
            blockBufferOut: &outBuffer
        ) == kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor
    )
    precondition(
        CMMetadataFormatDescriptionCreateFromBigEndianMetadataDescriptionBlockBuffer(
            allocator: nil,
            bigEndianMetadataDescriptionBlockBuffer: buffer,
            flavor: nil,
            formatDescriptionOut: &desc
        ) == kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor
    )
    precondition(
        bytes.withUnsafeBufferPointer { raw in
            CMMetadataFormatDescriptionCreateFromBigEndianMetadataDescriptionData(
                allocator: nil,
                bigEndianMetadataDescriptionData: raw.baseAddress!,
                size: raw.count,
                flavor: nil,
                formatDescriptionOut: &desc
            )
        } == kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor
    )
    precondition(
        CMTextFormatDescriptionCreateFromBigEndianTextDescriptionBlockBuffer(
            allocator: nil,
            bigEndianTextDescriptionBlockBuffer: buffer,
            flavor: nil,
            mediaType: kCMMediaType_Text,
            formatDescriptionOut: &desc
        ) == kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor
    )
    precondition(
        bytes.withUnsafeBufferPointer { raw in
            CMTextFormatDescriptionCreateFromBigEndianTextDescriptionData(
                allocator: nil,
                bigEndianTextDescriptionData: raw.baseAddress!,
                size: raw.count,
                flavor: nil,
                mediaType: kCMMediaType_Text,
                formatDescriptionOut: &desc
            )
        } == kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor
    )
    precondition(
        CMTimeCodeFormatDescriptionCreateFromBigEndianTimeCodeDescriptionBlockBuffer(
            allocator: nil,
            bigEndianTimeCodeDescriptionBlockBuffer: buffer,
            flavor: nil,
            formatDescriptionOut: &desc
        ) == kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor
    )
    precondition(
        bytes.withUnsafeBufferPointer { raw in
            CMTimeCodeFormatDescriptionCreateFromBigEndianTimeCodeDescriptionData(
                allocator: nil,
                bigEndianTimeCodeDescriptionData: raw.baseAddress!,
                size: raw.count,
                flavor: nil,
                formatDescriptionOut: &desc
            )
        } == kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor
    )
}

func testCMSwapEndianDescriptionsFailClosed() {
    var bytes: [UInt8] = [0, 1, 2, 3, 4, 5, 6, 7]
    let unsupported = kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor
    precondition(
        bytes.withUnsafeMutableBufferPointer {
            CMSwapBigEndianImageDescriptionToHost($0.baseAddress!, $0.count)
        } == unsupported
    )
    precondition(
        bytes.withUnsafeMutableBufferPointer {
            CMSwapHostEndianImageDescriptionToBig($0.baseAddress!, $0.count)
        } == unsupported
    )
    precondition(
        bytes.withUnsafeMutableBufferPointer {
            CMSwapBigEndianSoundDescriptionToHost($0.baseAddress!, $0.count)
        } == unsupported
    )
    precondition(
        bytes.withUnsafeMutableBufferPointer {
            CMSwapHostEndianSoundDescriptionToBig($0.baseAddress!, $0.count)
        } == unsupported
    )
    precondition(
        bytes.withUnsafeMutableBufferPointer {
            CMSwapBigEndianTextDescriptionToHost($0.baseAddress!, $0.count)
        } == unsupported
    )
    precondition(
        bytes.withUnsafeMutableBufferPointer {
            CMSwapHostEndianTextDescriptionToBig($0.baseAddress!, $0.count)
        } == unsupported
    )
    precondition(
        bytes.withUnsafeMutableBufferPointer {
            CMSwapBigEndianMetadataDescriptionToHost($0.baseAddress!, $0.count)
        } == unsupported
    )
    precondition(
        bytes.withUnsafeMutableBufferPointer {
            CMSwapHostEndianMetadataDescriptionToBig($0.baseAddress!, $0.count)
        } == unsupported
    )
    precondition(
        bytes.withUnsafeMutableBufferPointer {
            CMSwapBigEndianClosedCaptionDescriptionToHost($0.baseAddress!, $0.count)
        } == unsupported
    )
    precondition(
        bytes.withUnsafeMutableBufferPointer {
            CMSwapHostEndianClosedCaptionDescriptionToBig($0.baseAddress!, $0.count)
        } == unsupported
    )
    precondition(
        bytes.withUnsafeMutableBufferPointer {
            CMSwapBigEndianTimeCodeDescriptionToHost($0.baseAddress!, $0.count)
        } == unsupported
    )
    precondition(
        bytes.withUnsafeMutableBufferPointer {
            CMSwapHostEndianTimeCodeDescriptionToBig($0.baseAddress!, $0.count)
        } == unsupported
    )
}

func testCMMetadataDataTypeRegistryRegisterDataType() {
    let dataType = "public.coremedia.test-type".withCString { pointer in
        CFStringCreateWithCString(
            kCFAllocatorDefault,
            pointer,
            CFStringBuiltInEncodings.UTF8.rawValue
        )!
    }
    let description = "test".withCString { pointer in
        CFStringCreateWithCString(
            kCFAllocatorDefault,
            pointer,
            CFStringBuiltInEncodings.UTF8.rawValue
        )!
    }
    let conforming = CFArrayCreateMutable(kCFAllocatorDefault, 1, nil)!
    CFArrayAppendValue(conforming, unsafeBitCast(kCMMetadataBaseDataType_UTF8, to: UnsafeRawPointer.self))
    precondition(
        CMMetadataDataTypeRegistryRegisterDataType(
            dataType,
            description: description,
            conformingDataTypes: conforming
        ) == 0
    )
    precondition(CMMetadataDataTypeRegistryDataTypeIsRegistered(dataType))
    precondition(
        CMMetadataDataTypeRegistryRegisterDataType(
            dataType,
            description: description,
            conformingDataTypes: conforming
        ) == kCMMetadataDataTypeRegistryError_DataTypeAlreadyRegistered
    )
}
