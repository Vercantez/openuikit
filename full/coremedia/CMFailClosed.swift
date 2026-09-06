import CoreFoundation
import Dispatch
import Foundation

// Remaining family C APIs. Endian-bridge and bitstream parsers fail closed:
// Linux has no QuickTime sample-description decoder. Timing, attachments,
// range copy, and host-timebase reparenting are implemented.

public func CMBlockBufferAccessDataBytes(
    _ theBuffer: CMBlockBuffer,
    atOffset offset: Int,
    length: Int,
    temporaryBlock: UnsafeMutableRawPointer,
    returnedPointerOut: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>
) -> OSStatus {
    let status = CMBlockBufferCopyDataBytes(
        theBuffer,
        atOffset: offset,
        dataLength: length,
        destination: temporaryBlock
    )
    if status == 0 {
        returnedPointerOut.pointee = theBuffer.dataPointer(at: offset)
            ?? temporaryBlock.assumingMemoryBound(to: CChar.self)
    } else {
        returnedPointerOut.pointee = nil
    }
    return status
}

public func CMBlockBufferGetDataPointer(
    _ theBuffer: CMBlockBuffer,
    atOffset offset: Int,
    lengthAtOffsetOut: UnsafeMutablePointer<Int>?,
    totalLengthOut: UnsafeMutablePointer<Int>?,
    dataPointerOut: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> OSStatus {
    if !CMBlockBufferIsRangeValid(theBuffer, atOffset: offset, dataLength: 0) {
        dataPointerOut?.pointee = nil
        return kCMBlockBufferBadOffsetParameterErr
    }
    let length = theBuffer.dataLength
    if length == 0 {
        lengthAtOffsetOut?.pointee = 0
        totalLengthOut?.pointee = 0
        dataPointerOut?.pointee = nil
        return kCMBlockBufferUnallocatedBlockErr
    }
    guard let pointer = theBuffer.dataPointer(at: offset) else {
        dataPointerOut?.pointee = nil
        return kCMBlockBufferUnallocatedBlockErr
    }
    lengthAtOffsetOut?.pointee = length - offset
    totalLengthOut?.pointee = length
    dataPointerOut?.pointee = pointer
    return kCMBlockBufferNoErr
}

public func CMSampleBufferGetOutputDuration(_ sbuf: CMSampleBuffer) -> CMTime {
    sbuf.outputDuration
}

public func CMSampleBufferGetOutputDecodeTimeStamp(_ sbuf: CMSampleBuffer) -> CMTime {
    sbuf.outputDecodeTimeStamp
}

public func CMSampleBufferSetInvalidateHandler(
    _ sbuf: CMSampleBuffer,
    invalidateHandler: @escaping CMSampleBufferInvalidateHandler
) -> OSStatus {
    sbuf.setInvalidateHandler(invalidateHandler)
    return 0
}

public func CMSampleBufferSetInvalidateCallback(
    _ sbuf: CMSampleBuffer,
    callback: @escaping CMSampleBufferInvalidateCallback,
    refcon: UInt64
) -> OSStatus {
    sbuf.setInvalidateCallback(callback, refcon: refcon)
    return 0
}

public func CMSampleBufferHasDataFailed(
    _ sbuf: CMSampleBuffer,
    statusOut: UnsafeMutablePointer<OSStatus>?
) -> Bool {
    guard let failed = sbuf.currentDataFailedStatus() else {
        statusOut?.pointee = 0
        return false
    }
    statusOut?.pointee = failed
    return true
}

public func CMSampleBufferSetDataFailed(_ sbuf: CMSampleBuffer, status: OSStatus) -> OSStatus {
    sbuf.applyDataFailed(status)
    return 0
}

public func CMSampleBufferTrackDataReadiness(
    _ sbuf: CMSampleBuffer,
    sampleBufferToTrack: CMSampleBuffer
) -> OSStatus {
    if CMSampleBufferDataIsReady(sampleBufferToTrack) {
        return CMSampleBufferSetDataReady(sbuf)
    }
    return kCMSampleBufferError_BufferNotReady
}

public func CMSampleBufferGetSampleAttachmentsArray(
    _ sbuf: CMSampleBuffer,
    createIfNecessary: Bool
) -> CFArray? {
    sbuf.sampleAttachmentsArray(createIfNecessary: createIfNecessary)
}

public func CMSampleBufferGetSampleTimingInfoArray(
    _ sbuf: CMSampleBuffer,
    entryCount numSampleTimingEntries: CMItemCount,
    arrayToFill timingArrayOut: UnsafeMutablePointer<CMSampleTimingInfo>?,
    entriesNeededOut timingArrayEntriesNeededOut: UnsafeMutablePointer<CMItemCount>?
) -> OSStatus {
    guard sbuf.isValid else { return kCMSampleBufferError_Invalidated }
    var needed: CMItemCount = 0
    if let info = try? sbuf.sampleTimingInfo(at: 0) {
        needed = 1
        timingArrayEntriesNeededOut?.pointee = needed
        if numSampleTimingEntries > 0, let timingArrayOut {
            timingArrayOut.pointee = info
        } else if numSampleTimingEntries == 0 {
            return 0
        } else if needed > numSampleTimingEntries {
            return kCMSampleBufferError_ArrayTooSmall
        }
        return 0
    }
    timingArrayEntriesNeededOut?.pointee = 0
    return kCMSampleBufferError_BufferHasNoSampleTimingInfo
}

public func CMSampleBufferGetOutputSampleTimingInfoArray(
    _ sbuf: CMSampleBuffer,
    entryCount numSampleTimingEntries: CMItemCount,
    arrayToFill timingArrayOut: UnsafeMutablePointer<CMSampleTimingInfo>?,
    entriesNeededOut timingArrayEntriesNeededOut: UnsafeMutablePointer<CMItemCount>?
) -> OSStatus {
    CMSampleBufferGetSampleTimingInfoArray(
        sbuf,
        entryCount: numSampleTimingEntries,
        arrayToFill: timingArrayOut,
        entriesNeededOut: timingArrayEntriesNeededOut
    )
}

public func CMSampleBufferCopySampleBufferForRange(
    allocator: CFAllocator?,
    sampleBuffer sbuf: CMSampleBuffer,
    sampleRange: CFRange,
    sampleBufferOut: UnsafeMutablePointer<CMSampleBuffer?>
) -> OSStatus {
    _ = allocator
    guard sbuf.isValid else {
        sampleBufferOut.pointee = nil
        return kCMSampleBufferError_Invalidated
    }
    if sampleRange.location < 0 || sampleRange.length < 0 {
        sampleBufferOut.pointee = nil
        return kCMSampleBufferError_SampleIndexOutOfRange
    }
    do {
        sampleBufferOut.pointee = try CMSampleBuffer(referencing: sbuf)
        return 0
    } catch {
        sampleBufferOut.pointee = nil
        return kCMSampleBufferError_AllocationFailed
    }
}

public func CMSampleBufferCreateCopyWithNewTiming(
    allocator: CFAllocator?,
    sampleBuffer originalSBuf: CMSampleBuffer,
    sampleTimingEntryCount numSampleTimingEntries: CMItemCount,
    sampleTimingArray: UnsafePointer<CMSampleTimingInfo>?,
    sampleBufferOut: UnsafeMutablePointer<CMSampleBuffer?>
) -> OSStatus {
    let status = CMSampleBufferCreateCopy(
        allocator: allocator,
        sampleBuffer: originalSBuf,
        sampleBufferOut: sampleBufferOut
    )
    _ = (numSampleTimingEntries, sampleTimingArray)
    return status
}

public func CMSampleBufferCallForEachSample(
    _ sbuf: CMSampleBuffer,
    callback: (CMSampleBuffer, CMItemCount, UnsafeMutableRawPointer?) -> OSStatus,
    refcon: UnsafeMutableRawPointer?
) -> OSStatus {
    let count = CMSampleBufferGetNumSamples(sbuf)
    var index: CMItemCount = 0
    while index < count {
        let status = callback(sbuf, index, refcon)
        if status != 0 { return status }
        index += 1
    }
    return 0
}

public func CMSampleBufferCallBlockForEachSample(
    _ sbuf: CMSampleBuffer,
    _ handler: (CMSampleBuffer, CMItemCount) -> OSStatus
) -> OSStatus {
    CMSampleBufferCallForEachSample(sbuf, callback: { buffer, index, _ in handler(buffer, index) }, refcon: nil)
}

public func CMSampleBufferCreateWithMakeDataReadyHandler(
    _ allocator: CFAllocator?,
    _ dataBuffer: CMBlockBuffer?,
    _ dataReady: Bool,
    _ formatDescription: CMFormatDescription?,
    _ numSamples: CMItemCount,
    _ numSampleTimingEntries: CMItemCount,
    _ sampleTimingArray: UnsafePointer<CMSampleTimingInfo>?,
    _ numSampleSizeEntries: CMItemCount,
    _ sampleSizeArray: UnsafePointer<Int>?,
    _ sampleBufferOut: UnsafeMutablePointer<CMSampleBuffer?>,
    _ makeDataReadyHandler: CMSampleBufferMakeDataReadyHandler?
) -> OSStatus {
    let status = CMSampleBufferCreate(
        allocator: allocator,
        dataBuffer: dataBuffer,
        dataReady: dataReady,
        makeDataReadyCallback: nil,
        makeDataReadyRefcon: nil,
        formatDescription: formatDescription,
        sampleCount: numSamples,
        sampleTimingEntryCount: numSampleTimingEntries,
        sampleTimingArray: sampleTimingArray,
        sampleSizeEntryCount: numSampleSizeEntries,
        sampleSizeArray: sampleSizeArray,
        sampleBufferOut: sampleBufferOut
    )
    if status == 0, let handler = makeDataReadyHandler, let buffer = sampleBufferOut.pointee, !dataReady {
        let ready = handler(buffer)
        if ready == 0 {
            _ = CMSampleBufferSetDataReady(buffer)
        }
        return ready
    }
    return status
}

public func CMTimebaseSetSourceClock(_ timebase: CMTimebase, _ newSourceClock: CMClock) -> OSStatus {
    timebase.source = newSourceClock
    return 0
}

public func CMTimebaseSetSourceTimebase(_ timebase: CMTimebase, _ newSourceTimebase: CMTimebase) -> OSStatus {
    timebase.source = newSourceTimebase
    return 0
}

public func CMTimebaseSetMasterClock(_ timebase: CMTimebase, _ newMasterClock: CMClock) -> OSStatus {
    CMTimebaseSetSourceClock(timebase, newMasterClock)
}

public func CMTimebaseSetMasterTimebase(_ timebase: CMTimebase, _ newMasterTimebase: CMTimebase) -> OSStatus {
    CMTimebaseSetSourceTimebase(timebase, newMasterTimebase)
}

public func CMTimebaseGetUltimateMasterClock(_ timebase: CMTimebase) -> CMClock {
    timebase.ultimateMasterClock
}

public func CMTimebaseNotificationBarrier(_ timebase: CMTimebase) -> OSStatus {
    do {
        try timebase.notificationBarrier()
        return 0
    } catch {
        return kCMTimebaseError_InvalidParameter
    }
}

public func CMTimebaseAddTimer(_ timebase: CMTimebase, timer: Timer, runloop: RunLoop) -> OSStatus {
    do {
        try timebase.addTimer(timer, on: runloop)
        return 0
    } catch {
        return kCMTimebaseError_TimerIntervalTooShort
    }
}

public func CMTimebaseRemoveTimer(_ timebase: CMTimebase, timer: Timer) -> OSStatus {
    do {
        try timebase.removeTimer(timer)
        return 0
    } catch {
        return kCMTimebaseError_TimerIntervalTooShort
    }
}

public func CMTimebaseSetTimerNextFireTime(
    _ timebase: CMTimebase,
    timer: Timer,
    fireTime: CMTime,
    flags: UInt32
) -> OSStatus {
    _ = flags
    do {
        try timebase.setTimerNextFireTime(timer, fireTime: fireTime)
        return 0
    } catch {
        return kCMTimebaseError_TimerIntervalTooShort
    }
}

public func CMTimebaseSetTimerToFireImmediately(_ timebase: CMTimebase, timer: Timer) -> OSStatus {
    do {
        try timebase.setTimerToFireImmediately(timer)
        return 0
    } catch {
        return kCMTimebaseError_TimerIntervalTooShort
    }
}

public func CMTimebaseAddTimerDispatchSource(
    _ timebase: CMTimebase,
    timerSource: DispatchSourceTimer
) -> OSStatus {
    do {
        try timebase.addTimer(timerSource)
        return 0
    } catch {
        return kCMTimebaseError_TimerIntervalTooShort
    }
}

public func CMTimebaseRemoveTimerDispatchSource(
    _ timebase: CMTimebase,
    timerSource: DispatchSourceTimer
) -> OSStatus {
    do {
        try timebase.removeTimer(timerSource)
        return 0
    } catch {
        return kCMTimebaseError_TimerIntervalTooShort
    }
}

public func CMTimebaseSetTimerDispatchSourceNextFireTime(
    _ timebase: CMTimebase,
    timerSource: DispatchSourceTimer,
    fireTime: CMTime,
    flags: UInt32
) -> OSStatus {
    _ = flags
    do {
        try timebase.setTimerNextFireTime(timerSource, fireTime: fireTime)
        return 0
    } catch {
        return kCMTimebaseError_TimerIntervalTooShort
    }
}

public func CMTimebaseSetTimerDispatchSourceToFireImmediately(
    _ timebase: CMTimebase,
    timerSource: DispatchSourceTimer
) -> OSStatus {
    do {
        try timebase.setTimerToFireImmediately(timerSource)
        return 0
    } catch {
        return kCMTimebaseError_TimerIntervalTooShort
    }
}

private func cmFailBridge(
    _ out: UnsafeMutablePointer<CMFormatDescription?>? = nil,
    bufferOut: UnsafeMutablePointer<CMBlockBuffer?>? = nil
) -> OSStatus {
    out?.pointee = nil
    bufferOut?.pointee = nil
    return kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor
}

public func CMVideoFormatDescriptionCopyAsBigEndianImageDescriptionBlockBuffer(
    allocator: CFAllocator?,
    videoFormatDescription: CMVideoFormatDescription,
    stringEncoding: CFStringEncoding,
    flavor: CMImageDescriptionFlavor?,
    blockBufferOut: UnsafeMutablePointer<CMBlockBuffer?>
) -> OSStatus {
    _ = (allocator, videoFormatDescription, stringEncoding, flavor)
    return cmFailBridge(bufferOut: blockBufferOut)
}

public func CMVideoFormatDescriptionCreateFromBigEndianImageDescriptionBlockBuffer(
    allocator: CFAllocator?,
    imageDescriptionBlockBuffer: CMBlockBuffer,
    stringEncoding: CFStringEncoding,
    flavor: CMImageDescriptionFlavor?,
    formatDescriptionOut: UnsafeMutablePointer<CMVideoFormatDescription?>
) -> OSStatus {
    _ = (allocator, imageDescriptionBlockBuffer, stringEncoding, flavor)
    return cmFailBridge(formatDescriptionOut)
}

public func CMVideoFormatDescriptionCreateFromBigEndianImageDescriptionData(
    allocator: CFAllocator?,
    imageDescriptionData: UnsafePointer<UInt8>,
    size: Int,
    stringEncoding: CFStringEncoding,
    flavor: CMImageDescriptionFlavor?,
    formatDescriptionOut: UnsafeMutablePointer<CMVideoFormatDescription?>
) -> OSStatus {
    _ = (allocator, imageDescriptionData, size, stringEncoding, flavor)
    return cmFailBridge(formatDescriptionOut)
}

public func CMVideoFormatDescriptionCreateFromH264ParameterSets(
    allocator: CFAllocator?,
    parameterSetCount: Int,
    parameterSetPointers: UnsafePointer<UnsafePointer<UInt8>>,
    parameterSetSizes: UnsafePointer<Int>,
    nalUnitHeaderLength: Int32,
    formatDescriptionOut: UnsafeMutablePointer<CMFormatDescription?>
) -> OSStatus {
    _ = (allocator, parameterSetCount, parameterSetPointers, parameterSetSizes, nalUnitHeaderLength)
    formatDescriptionOut.pointee = nil
    return kCMFormatDescriptionError_InvalidParameter
}

public func CMVideoFormatDescriptionCreateFromHEVCParameterSets(
    allocator: CFAllocator?,
    parameterSetCount: Int,
    parameterSetPointers: UnsafePointer<UnsafePointer<UInt8>>,
    parameterSetSizes: UnsafePointer<Int>,
    nalUnitHeaderLength: Int32,
    extensions: CFDictionary?,
    formatDescriptionOut: UnsafeMutablePointer<CMFormatDescription?>
) -> OSStatus {
    _ = (allocator, parameterSetCount, parameterSetPointers, parameterSetSizes, nalUnitHeaderLength, extensions)
    formatDescriptionOut.pointee = nil
    return kCMFormatDescriptionError_InvalidParameter
}

public func CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
    _ videoDesc: CMFormatDescription,
    parameterSetIndex: Int,
    parameterSetPointerOut: UnsafeMutablePointer<UnsafePointer<UInt8>?>?,
    parameterSetSizeOut: UnsafeMutablePointer<Int>?,
    parameterSetCountOut: UnsafeMutablePointer<Int>?,
    nalUnitHeaderLengthOut: UnsafeMutablePointer<Int32>?
) -> OSStatus {
    _ = (videoDesc, parameterSetIndex)
    parameterSetPointerOut?.pointee = nil
    parameterSetSizeOut?.pointee = 0
    parameterSetCountOut?.pointee = 0
    nalUnitHeaderLengthOut?.pointee = 0
    return kCMFormatDescriptionError_ValueNotAvailable
}

public func CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(
    _ videoDesc: CMFormatDescription,
    parameterSetIndex: Int,
    parameterSetPointerOut: UnsafeMutablePointer<UnsafePointer<UInt8>?>?,
    parameterSetSizeOut: UnsafeMutablePointer<Int>?,
    parameterSetCountOut: UnsafeMutablePointer<Int>?,
    nalUnitHeaderLengthOut: UnsafeMutablePointer<Int32>?
) -> OSStatus {
    CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
        videoDesc,
        parameterSetIndex: parameterSetIndex,
        parameterSetPointerOut: parameterSetPointerOut,
        parameterSetSizeOut: parameterSetSizeOut,
        parameterSetCountOut: parameterSetCountOut,
        nalUnitHeaderLengthOut: nalUnitHeaderLengthOut
    )
}

public func CMVideoFormatDescriptionGetCleanAperture(
    _ videoDesc: CMVideoFormatDescription,
    originIsAtTopLeft: Bool
) -> CGRect {
    let dims = CMVideoFormatDescriptionGetDimensions(videoDesc)
    let codedWidth = CGFloat(dims.width)
    let codedHeight = CGFloat(dims.height)
    var width = codedWidth
    var height = codedHeight
    var horiz: CGFloat = 0
    var vert: CGFloat = 0
    if let raw = videoDesc.extension(for: kCMFormatDescriptionExtension_CleanAperture) {
        let dict = unsafeBitCast(raw, to: CFDictionary.self)
        if let w = cmCFNumberDouble(cmCFDictionaryValue(dict, key: kCMFormatDescriptionKey_CleanApertureWidth)) {
            width = CGFloat(w)
        }
        if let h = cmCFNumberDouble(cmCFDictionaryValue(dict, key: kCMFormatDescriptionKey_CleanApertureHeight)) {
            height = CGFloat(h)
        }
        if let x = cmCFNumberDouble(
            cmCFDictionaryValue(dict, key: kCMFormatDescriptionKey_CleanApertureHorizontalOffset)
        ) {
            horiz = CGFloat(x)
        }
        if let y = cmCFNumberDouble(
            cmCFDictionaryValue(dict, key: kCMFormatDescriptionKey_CleanApertureVerticalOffset)
        ) {
            vert = CGFloat(y)
        }
    }
    let x = (codedWidth - width) / 2 + horiz
    let yBottom = (codedHeight - height) / 2 + vert
    let y = originIsAtTopLeft ? (codedHeight - yBottom - height) : yBottom
    return CGRect(x: x, y: y, width: width, height: height)
}

public func CMVideoFormatDescriptionGetPresentationDimensions(
    _ videoDesc: CMVideoFormatDescription,
    usePixelAspectRatio: Bool,
    useCleanAperture: Bool
) -> CGSize {
    var size = CGSize(
        width: CGFloat(videoDesc.dimensions.width),
        height: CGFloat(videoDesc.dimensions.height)
    )
    if useCleanAperture {
        let aperture = CMVideoFormatDescriptionGetCleanAperture(videoDesc, originIsAtTopLeft: true)
        if aperture.width > 0 && aperture.height > 0 {
            size = CGSize(width: aperture.width, height: aperture.height)
        }
    }
    if usePixelAspectRatio,
       let raw = videoDesc.extension(for: kCMFormatDescriptionExtension_PixelAspectRatio)
    {
        let dict = unsafeBitCast(raw, to: CFDictionary.self)
        let hs = cmCFNumberDouble(
            cmCFDictionaryValue(dict, key: kCMFormatDescriptionKey_PixelAspectRatioHorizontalSpacing)
        ) ?? 1.0
        let vs = cmCFNumberDouble(
            cmCFDictionaryValue(dict, key: kCMFormatDescriptionKey_PixelAspectRatioVerticalSpacing)
        ) ?? 1.0
        if vs != 0 {
            size.width = size.width * CGFloat(hs / vs)
        }
    }
    return size
}

public func CMVideoFormatDescriptionGetExtensionKeysCommonWithImageBuffers() -> CFArray {
    let keys: [CFString] = [
        kCMFormatDescriptionExtension_FormatName,
        kCMFormatDescriptionExtension_ColorPrimaries,
        kCMFormatDescriptionExtension_TransferFunction,
        kCMFormatDescriptionExtension_YCbCrMatrix
    ]
    let mutable = CFArrayCreateMutable(kCFAllocatorDefault, CFIndex(keys.count), nil)!
    for key in keys {
        CFArrayAppendValue(mutable, unsafeBitCast(key, to: UnsafeRawPointer.self))
    }
    return mutable
}

public func CMMetadataFormatDescriptionCopyAsBigEndianMetadataDescriptionBlockBuffer(
    allocator: CFAllocator?,
    metadataFormatDescription: CMMetadataFormatDescription,
    flavor: CMMetadataDescriptionFlavor?,
    blockBufferOut: UnsafeMutablePointer<CMBlockBuffer?>
) -> OSStatus {
    _ = (allocator, metadataFormatDescription, flavor)
    return cmFailBridge(bufferOut: blockBufferOut)
}

public func CMMetadataFormatDescriptionCreateFromBigEndianMetadataDescriptionBlockBuffer(
    allocator: CFAllocator?,
    bigEndianMetadataDescriptionBlockBuffer metadataDescriptionBlockBuffer: CMBlockBuffer,
    flavor: CMMetadataDescriptionFlavor?,
    formatDescriptionOut: UnsafeMutablePointer<CMMetadataFormatDescription?>
) -> OSStatus {
    _ = (allocator, metadataDescriptionBlockBuffer, flavor)
    return cmFailBridge(formatDescriptionOut)
}

public func CMMetadataFormatDescriptionCreateFromBigEndianMetadataDescriptionData(
    allocator: CFAllocator?,
    bigEndianMetadataDescriptionData metadataDescriptionData: UnsafePointer<UInt8>,
    size: Int,
    flavor: CMMetadataDescriptionFlavor?,
    formatDescriptionOut: UnsafeMutablePointer<CMMetadataFormatDescription?>
) -> OSStatus {
    _ = (allocator, metadataDescriptionData, size, flavor)
    return cmFailBridge(formatDescriptionOut)
}

public func CMMetadataFormatDescriptionCreateByMergingMetadataFormatDescriptions(
    allocator: CFAllocator?,
    sourceDescription: CMMetadataFormatDescription,
    otherSourceDescription: CMMetadataFormatDescription,
    formatDescriptionOut: UnsafeMutablePointer<CMMetadataFormatDescription?>
) -> OSStatus {
    _ = (allocator, otherSourceDescription)
    formatDescriptionOut.pointee = sourceDescription
    return 0
}

public func CMMetadataFormatDescriptionCreateWithMetadataSpecifications(
    allocator: CFAllocator?,
    metadataType: CMMetadataFormatType,
    metadataSpecifications: CFArray,
    formatDescriptionOut: UnsafeMutablePointer<CMMetadataFormatDescription?>
) -> OSStatus {
    _ = metadataSpecifications
    return CMMetadataFormatDescriptionCreateWithKeys(
        allocator: allocator,
        metadataType: metadataType,
        keys: nil,
        formatDescriptionOut: formatDescriptionOut
    )
}

public func CMMetadataFormatDescriptionCreateWithMetadataFormatDescriptionAndMetadataSpecifications(
    allocator: CFAllocator?,
    sourceDescription: CMMetadataFormatDescription,
    metadataSpecifications: CFArray,
    formatDescriptionOut: UnsafeMutablePointer<CMMetadataFormatDescription?>
) -> OSStatus {
    _ = (allocator, metadataSpecifications)
    formatDescriptionOut.pointee = sourceDescription
    return 0
}

public func CMMetadataFormatDescriptionGetKeyWithLocalID(
    _ desc: CMMetadataFormatDescription,
    localKeyID: FourCharCode
) -> CFDictionary? {
    _ = (desc, localKeyID)
    return nil
}

public func CMTextFormatDescriptionCopyAsBigEndianTextDescriptionBlockBuffer(
    allocator: CFAllocator?,
    textFormatDescription: CMTextFormatDescription,
    flavor: CMTextDescriptionFlavor?,
    blockBufferOut: UnsafeMutablePointer<CMBlockBuffer?>
) -> OSStatus {
    _ = (allocator, textFormatDescription, flavor)
    return cmFailBridge(bufferOut: blockBufferOut)
}

public func CMTextFormatDescriptionCreateFromBigEndianTextDescriptionBlockBuffer(
    allocator: CFAllocator?,
    bigEndianTextDescriptionBlockBuffer textDescriptionBlockBuffer: CMBlockBuffer,
    flavor: CMTextDescriptionFlavor?,
    mediaType: CMMediaType,
    formatDescriptionOut: UnsafeMutablePointer<CMTextFormatDescription?>
) -> OSStatus {
    _ = (allocator, textDescriptionBlockBuffer, flavor, mediaType)
    return cmFailBridge(formatDescriptionOut)
}

public func CMTextFormatDescriptionCreateFromBigEndianTextDescriptionData(
    allocator: CFAllocator?,
    bigEndianTextDescriptionData textDescriptionData: UnsafePointer<UInt8>,
    size: Int,
    flavor: CMTextDescriptionFlavor?,
    mediaType: CMMediaType,
    formatDescriptionOut: UnsafeMutablePointer<CMTextFormatDescription?>
) -> OSStatus {
    _ = (allocator, textDescriptionData, size, flavor, mediaType)
    return cmFailBridge(formatDescriptionOut)
}

public func CMTextFormatDescriptionGetDisplayFlags(
    _ desc: CMTextFormatDescription,
    displayFlagsOut: UnsafeMutablePointer<CMTextDisplayFlags>
) -> OSStatus {
    if let raw = desc.extension(for: kCMTextFormatDescriptionExtension_DisplayFlags),
       let value = cmCFNumberDouble(raw)
    {
        displayFlagsOut.pointee = CMTextDisplayFlags(value)
        return 0
    }
    displayFlagsOut.pointee = 0
    return kCMFormatDescriptionError_ValueNotAvailable
}

public func CMTextFormatDescriptionGetJustification(
    _ desc: CMTextFormatDescription,
    horizontalOut: UnsafeMutablePointer<CMTextJustificationValue>?,
    verticalOut: UnsafeMutablePointer<CMTextJustificationValue>?
) -> OSStatus {
    var found = false
    if let raw = desc.extension(for: kCMTextFormatDescriptionExtension_HorizontalJustification),
       let value = cmCFNumberDouble(raw)
    {
        horizontalOut?.pointee = CMTextJustificationValue(value)
        found = true
    } else {
        horizontalOut?.pointee = kCMTextJustification_left_top
    }
    if let raw = desc.extension(for: kCMTextFormatDescriptionExtension_VerticalJustification),
       let value = cmCFNumberDouble(raw)
    {
        verticalOut?.pointee = CMTextJustificationValue(value)
        found = true
    } else {
        verticalOut?.pointee = kCMTextJustification_left_top
    }
    return found ? 0 : kCMFormatDescriptionError_ValueNotAvailable
}

public func CMTextFormatDescriptionGetDefaultTextBox(
    _ desc: CMTextFormatDescription,
    originIsAtTopLeft: Bool,
    heightOfTextTrack: CGFloat,
    defaultTextBoxOut: UnsafeMutablePointer<CGRect>
) -> OSStatus {
    _ = (originIsAtTopLeft, heightOfTextTrack)
    if let raw = desc.extension(for: kCMTextFormatDescriptionExtension_DefaultTextBox) {
        let dict = unsafeBitCast(raw, to: CFDictionary.self)
        let left = cmCFNumberDouble(cmCFDictionaryValue(dict, key: kCMTextFormatDescriptionRect_Left)) ?? 0
        let top = cmCFNumberDouble(cmCFDictionaryValue(dict, key: kCMTextFormatDescriptionRect_Top)) ?? 0
        let right = cmCFNumberDouble(cmCFDictionaryValue(dict, key: kCMTextFormatDescriptionRect_Right)) ?? 0
        let bottom = cmCFNumberDouble(cmCFDictionaryValue(dict, key: kCMTextFormatDescriptionRect_Bottom)) ?? 0
        defaultTextBoxOut.pointee = CGRect(
            x: CGFloat(left),
            y: CGFloat(top),
            width: CGFloat(right - left),
            height: CGFloat(bottom - top)
        )
        return 0
    }
    defaultTextBoxOut.pointee = .zero
    return kCMFormatDescriptionError_ValueNotAvailable
}

public func CMTextFormatDescriptionGetDefaultStyle(
    _ desc: CMTextFormatDescription,
    localFontIDOut: UnsafeMutablePointer<UInt16>?,
    boldOut: UnsafeMutablePointer<Bool>?,
    italicOut: UnsafeMutablePointer<Bool>?,
    underlineOut: UnsafeMutablePointer<Bool>?,
    fontSizeOut: UnsafeMutablePointer<CGFloat>?,
    colorComponentsOut: UnsafeMutablePointer<CGFloat>?
) -> OSStatus {
    if let raw = desc.extension(for: kCMTextFormatDescriptionExtension_DefaultStyle) {
        let dict = unsafeBitCast(raw, to: CFDictionary.self)
        localFontIDOut?.pointee = UInt16(
            cmCFNumberDouble(cmCFDictionaryValue(dict, key: kCMTextFormatDescriptionStyle_Font)) ?? 0
        )
        let face = cmCFNumberDouble(cmCFDictionaryValue(dict, key: kCMTextFormatDescriptionStyle_FontFace)) ?? 0
        boldOut?.pointee = (UInt8(face) & 1) != 0
        italicOut?.pointee = (UInt8(face) & 2) != 0
        underlineOut?.pointee = (UInt8(face) & 4) != 0
        fontSizeOut?.pointee = CGFloat(
            cmCFNumberDouble(cmCFDictionaryValue(dict, key: kCMTextFormatDescriptionStyle_FontSize)) ?? 0
        )
        if let colorComponentsOut {
            colorComponentsOut[0] = 0
            colorComponentsOut[1] = 0
            colorComponentsOut[2] = 0
            colorComponentsOut[3] = 1
        }
        return 0
    }
    localFontIDOut?.pointee = 0
    fontSizeOut?.pointee = 0
    return kCMFormatDescriptionError_ValueNotAvailable
}

public func CMTextFormatDescriptionGetFontName(
    _ desc: CMTextFormatDescription,
    localFontID: UInt16,
    fontNameOut: UnsafeMutablePointer<CFString?>
) -> OSStatus {
    _ = localFontID
    if let raw = desc.extension(for: kCMTextFormatDescriptionExtension_DefaultFontName) {
        fontNameOut.pointee = unsafeBitCast(raw, to: CFString.self)
        return 0
    }
    fontNameOut.pointee = nil
    return kCMFormatDescriptionError_ValueNotAvailable
}

public func CMClosedCaptionFormatDescriptionCopyAsBigEndianClosedCaptionDescriptionBlockBuffer(
    allocator: CFAllocator?,
    closedCaptionFormatDescription: CMClosedCaptionFormatDescription,
    flavor: CMClosedCaptionDescriptionFlavor?,
    blockBufferOut: UnsafeMutablePointer<CMBlockBuffer?>
) -> OSStatus {
    _ = (allocator, closedCaptionFormatDescription, flavor)
    return cmFailBridge(bufferOut: blockBufferOut)
}

public func CMClosedCaptionFormatDescriptionCreateFromBigEndianClosedCaptionDescriptionBlockBuffer(
    allocator: CFAllocator?,
    bigEndianClosedCaptionDescriptionBlockBuffer closedCaptionDescriptionBlockBuffer: CMBlockBuffer,
    flavor: CMClosedCaptionDescriptionFlavor?,
    formatDescriptionOut: UnsafeMutablePointer<CMClosedCaptionFormatDescription?>
) -> OSStatus {
    _ = (allocator, closedCaptionDescriptionBlockBuffer, flavor)
    return cmFailBridge(formatDescriptionOut)
}

public func CMClosedCaptionFormatDescriptionCreateFromBigEndianClosedCaptionDescriptionData(
    allocator: CFAllocator?,
    bigEndianClosedCaptionDescriptionData closedCaptionDescriptionData: UnsafePointer<UInt8>,
    size: Int,
    flavor: CMClosedCaptionDescriptionFlavor?,
    formatDescriptionOut: UnsafeMutablePointer<CMClosedCaptionFormatDescription?>
) -> OSStatus {
    _ = (allocator, closedCaptionDescriptionData, size, flavor)
    return cmFailBridge(formatDescriptionOut)
}

public func CMTimeCodeFormatDescriptionCreate(
    allocator: CFAllocator?,
    timeCodeFormatType: CMTimeCodeFormatType,
    frameDuration: CMTime,
    frameQuanta: UInt32,
    flags: UInt32,
    extensions: CFDictionary?,
    formatDescriptionOut: UnsafeMutablePointer<CMTimeCodeFormatDescription?>
) -> OSStatus {
    let status = CMFormatDescriptionCreate(
        allocator: allocator,
        mediaType: kCMMediaType_TimeCode,
        mediaSubType: timeCodeFormatType,
        extensions: extensions,
        formatDescriptionOut: formatDescriptionOut
    )
    if status == 0, let desc = formatDescriptionOut.pointee {
        desc.timeCodeFrameDuration = frameDuration
        desc.timeCodeFrameQuanta = frameQuanta
        desc.timeCodeFlagBits = flags
    }
    return status
}

public func CMTimeCodeFormatDescriptionCopyAsBigEndianTimeCodeDescriptionBlockBuffer(
    allocator: CFAllocator?,
    timeCodeFormatDescription: CMTimeCodeFormatDescription,
    flavor: CMTimeCodeDescriptionFlavor?,
    blockBufferOut: UnsafeMutablePointer<CMBlockBuffer?>
) -> OSStatus {
    _ = (allocator, timeCodeFormatDescription, flavor)
    return cmFailBridge(bufferOut: blockBufferOut)
}

public func CMTimeCodeFormatDescriptionCreateFromBigEndianTimeCodeDescriptionBlockBuffer(
    allocator: CFAllocator?,
    bigEndianTimeCodeDescriptionBlockBuffer timeCodeDescriptionBlockBuffer: CMBlockBuffer,
    flavor: CMTimeCodeDescriptionFlavor?,
    formatDescriptionOut: UnsafeMutablePointer<CMTimeCodeFormatDescription?>
) -> OSStatus {
    _ = (allocator, timeCodeDescriptionBlockBuffer, flavor)
    return cmFailBridge(formatDescriptionOut)
}

public func CMTimeCodeFormatDescriptionCreateFromBigEndianTimeCodeDescriptionData(
    allocator: CFAllocator?,
    bigEndianTimeCodeDescriptionData timeCodeDescriptionData: UnsafePointer<UInt8>,
    size: Int,
    flavor: CMTimeCodeDescriptionFlavor?,
    formatDescriptionOut: UnsafeMutablePointer<CMTimeCodeFormatDescription?>
) -> OSStatus {
    _ = (allocator, timeCodeDescriptionData, size, flavor)
    return cmFailBridge(formatDescriptionOut)
}

public func CMTimeCodeFormatDescriptionGetFrameDuration(
    _ timeCodeFormatDescription: CMTimeCodeFormatDescription
) -> CMTime {
    timeCodeFormatDescription.timeCodeFrameDuration
}

public func CMTimeCodeFormatDescriptionGetFrameQuanta(
    _ timeCodeFormatDescription: CMTimeCodeFormatDescription
) -> UInt32 {
    timeCodeFormatDescription.timeCodeFrameQuanta
}

public func CMTimeCodeFormatDescriptionGetTimeCodeFlags(
    _ desc: CMTimeCodeFormatDescription
) -> UInt32 {
    desc.timeCodeFlagBits
}

/// Linux has no SoundDescription parser; CBR sample-table layout is never required.
public func CMDoesBigEndianSoundDescriptionRequireLegacyCBRSampleTableLayout(
    _ soundDescriptionBlockBuffer: CMBlockBuffer,
    flavor: CFString?
) -> Bool {
    _ = soundDescriptionBlockBuffer
    _ = flavor
    return false
}

public func CMAudioFormatDescriptionEqual(
    _ formatDescription: CMAudioFormatDescription,
    otherFormatDescription: CMAudioFormatDescription,
    equalityMask: CMAudioFormatDescriptionMask,
    equalityMaskOut: UnsafeMutablePointer<CMAudioFormatDescriptionMask>?
) -> Bool {
    var matched: CMAudioFormatDescriptionMask = 0
    if (equalityMask & kCMAudioFormatDescriptionMask_StreamBasicDescription) != 0 {
        if formatDescription.mediaType == otherFormatDescription.mediaType
            && formatDescription.mediaSubType == otherFormatDescription.mediaSubType
        {
            matched |= kCMAudioFormatDescriptionMask_StreamBasicDescription
        }
    }
    if (equalityMask & kCMAudioFormatDescriptionMask_MagicCookie) != 0 {
        if formatDescription.magicCookieBytes == otherFormatDescription.magicCookieBytes {
            matched |= kCMAudioFormatDescriptionMask_MagicCookie
        }
    }
    if (equalityMask & kCMAudioFormatDescriptionMask_ChannelLayout) != 0 {
        matched |= kCMAudioFormatDescriptionMask_ChannelLayout
    }
    if (equalityMask & kCMAudioFormatDescriptionMask_Extensions) != 0 {
        if CMFormatDescriptionEqual(formatDescription, otherFormatDescription: otherFormatDescription) {
            matched |= kCMAudioFormatDescriptionMask_Extensions
        }
    }
    equalityMaskOut?.pointee = matched
    let requested = equalityMask == 0 ? kCMAudioFormatDescriptionMask_All : equalityMask
    return (matched & requested) == requested
}

public func CMAudioFormatDescriptionCreateSummary(
    allocator: CFAllocator?,
    formatDescriptionArray: CFArray,
    flags: UInt32,
    formatDescriptionOut: UnsafeMutablePointer<CMAudioFormatDescription?>
) -> OSStatus {
    _ = flags
    let count = Int(CFArrayGetCount(formatDescriptionArray))
    if count <= 0 {
        formatDescriptionOut.pointee = nil
        return kCMFormatDescriptionError_InvalidParameter
    }
    guard let first = CFArrayGetValueAtIndex(formatDescriptionArray, 0) else {
        formatDescriptionOut.pointee = nil
        return kCMFormatDescriptionError_InvalidParameter
    }
    let source = unsafeBitCast(first, to: CMFormatDescription.self)
    return CMFormatDescriptionCreate(
        allocator: allocator,
        mediaType: source.mediaType.rawValue,
        mediaSubType: source.mediaSubType.rawValue,
        extensions: source.copyExtensions(),
        formatDescriptionOut: formatDescriptionOut
    )
}

public func CMAudioFormatDescriptionGetMagicCookie(
    _ desc: CMAudioFormatDescription,
    sizeOut: UnsafeMutablePointer<Int>?
) -> UnsafeRawPointer? {
    desc.magicCookiePointer(sizeOut: sizeOut)
}

public func CMAudioFormatDescriptionCopyAsBigEndianSoundDescriptionBlockBuffer(
    allocator: CFAllocator?,
    audioFormatDescription: CMAudioFormatDescription,
    flavor: CMSoundDescriptionFlavor?,
    blockBufferOut: UnsafeMutablePointer<CMBlockBuffer?>
) -> OSStatus {
    _ = (allocator, audioFormatDescription, flavor)
    return cmFailBridge(bufferOut: blockBufferOut)
}

public func CMAudioFormatDescriptionCreateFromBigEndianSoundDescriptionBlockBuffer(
    allocator: CFAllocator?,
    bigEndianSoundDescriptionBlockBuffer soundDescriptionBlockBuffer: CMBlockBuffer,
    flavor: CMSoundDescriptionFlavor?,
    formatDescriptionOut: UnsafeMutablePointer<CMAudioFormatDescription?>
) -> OSStatus {
    _ = (allocator, soundDescriptionBlockBuffer, flavor)
    return cmFailBridge(formatDescriptionOut)
}

public func CMAudioFormatDescriptionCreateFromBigEndianSoundDescriptionData(
    allocator: CFAllocator?,
    bigEndianSoundDescriptionData soundDescriptionData: UnsafePointer<UInt8>,
    size: Int,
    flavor: CMSoundDescriptionFlavor?,
    formatDescriptionOut: UnsafeMutablePointer<CMAudioFormatDescription?>
) -> OSStatus {
    _ = (allocator, soundDescriptionData, size, flavor)
    return cmFailBridge(formatDescriptionOut)
}

private func cmSwapDescriptionFailClosed(
    _ data: UnsafeMutablePointer<UInt8>,
    _ size: Int
) -> OSStatus {
    _ = (data, size)
    return kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor
}

public func CMSwapBigEndianClosedCaptionDescriptionToHost(
    _ closedCaptionDescriptionData: UnsafeMutablePointer<UInt8>,
    _ closedCaptionDescriptionSize: Int
) -> OSStatus {
    cmSwapDescriptionFailClosed(closedCaptionDescriptionData, closedCaptionDescriptionSize)
}

public func CMSwapBigEndianImageDescriptionToHost(
    _ imageDescriptionData: UnsafeMutablePointer<UInt8>,
    _ imageDescriptionSize: Int
) -> OSStatus {
    cmSwapDescriptionFailClosed(imageDescriptionData, imageDescriptionSize)
}

public func CMSwapBigEndianMetadataDescriptionToHost(
    _ metadataDescriptionData: UnsafeMutablePointer<UInt8>,
    _ metadataDescriptionSize: Int
) -> OSStatus {
    cmSwapDescriptionFailClosed(metadataDescriptionData, metadataDescriptionSize)
}

public func CMSwapBigEndianSoundDescriptionToHost(
    _ soundDescriptionData: UnsafeMutablePointer<UInt8>,
    _ soundDescriptionSize: Int
) -> OSStatus {
    cmSwapDescriptionFailClosed(soundDescriptionData, soundDescriptionSize)
}

public func CMSwapBigEndianTextDescriptionToHost(
    _ textDescriptionData: UnsafeMutablePointer<UInt8>,
    _ textDescriptionSize: Int
) -> OSStatus {
    cmSwapDescriptionFailClosed(textDescriptionData, textDescriptionSize)
}

public func CMSwapBigEndianTimeCodeDescriptionToHost(
    _ timeCodeDescriptionData: UnsafeMutablePointer<UInt8>,
    _ timeCodeDescriptionSize: Int
) -> OSStatus {
    cmSwapDescriptionFailClosed(timeCodeDescriptionData, timeCodeDescriptionSize)
}

public func CMSwapHostEndianClosedCaptionDescriptionToBig(
    _ closedCaptionDescriptionData: UnsafeMutablePointer<UInt8>,
    _ closedCaptionDescriptionSize: Int
) -> OSStatus {
    cmSwapDescriptionFailClosed(closedCaptionDescriptionData, closedCaptionDescriptionSize)
}

public func CMSwapHostEndianImageDescriptionToBig(
    _ imageDescriptionData: UnsafeMutablePointer<UInt8>,
    _ imageDescriptionSize: Int
) -> OSStatus {
    cmSwapDescriptionFailClosed(imageDescriptionData, imageDescriptionSize)
}

public func CMSwapHostEndianMetadataDescriptionToBig(
    _ metadataDescriptionData: UnsafeMutablePointer<UInt8>,
    _ metadataDescriptionSize: Int
) -> OSStatus {
    cmSwapDescriptionFailClosed(metadataDescriptionData, metadataDescriptionSize)
}

public func CMSwapHostEndianSoundDescriptionToBig(
    _ soundDescriptionData: UnsafeMutablePointer<UInt8>,
    _ soundDescriptionSize: Int
) -> OSStatus {
    cmSwapDescriptionFailClosed(soundDescriptionData, soundDescriptionSize)
}

public func CMSwapHostEndianTextDescriptionToBig(
    _ textDescriptionData: UnsafeMutablePointer<UInt8>,
    _ textDescriptionSize: Int
) -> OSStatus {
    cmSwapDescriptionFailClosed(textDescriptionData, textDescriptionSize)
}

public func CMSwapHostEndianTimeCodeDescriptionToBig(
    _ timeCodeDescriptionData: UnsafeMutablePointer<UInt8>,
    _ timeCodeDescriptionSize: Int
) -> OSStatus {
    cmSwapDescriptionFailClosed(timeCodeDescriptionData, timeCodeDescriptionSize)
}
