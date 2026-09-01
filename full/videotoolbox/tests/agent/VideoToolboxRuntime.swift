import Dispatch
import VideoToolbox

private func require(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

private final class ProbeCommandBuffer: MTLCommandBuffer {}

enum VideoToolboxRuntime {
    static func main() {
        probeStatusCodes()
        probeKeysAndFlags()
        probeSessions()
        probeFrameProcessor()
        let gate = DispatchSemaphore(value: 0)
        Task {
            await probeAsyncFailClosed()
            gate.signal()
        }
        gate.wait()
        print("VIDEOTOOLBOX_AGENT_RUNTIME_OK")
    }

    private static func probeStatusCodes() {
        require(kVTPropertyNotSupportedErr == -12900, "kVTPropertyNotSupportedErr")
        require(kVTCouldNotFindVideoDecoderErr == -12906, "decoder missing")
        require(kVTCouldNotFindVideoEncoderErr == -12908, "encoder missing")
        require(kVTPixelRotationNotSupportedErr == kVTImageRotationNotSupportedErr, "rotation alias")
        require(kVTVideoDecoderUnknownErr == -17696, "decoder unknown")
        require(kVTVideoEncoderAutoWhiteBalanceNotLockedErr == -19512, "AWB")
        require(kVTUnlimitedFrameDelayCount == -1, "unlimited delay")
        require(kVTQPModulationLevel_Default == -1, "qp default")
        require(kVTQPModulationLevel_Disable == 0, "qp disable")
        require(!VT_SUPPORT_COLORSYNC_PIXEL_TRANSFER, "no ColorSync")
        require(VideoToolboxLinux.statusCodes.count == 44, "status table")
        for (name, code) in VideoToolboxLinux.statusCodes {
            require(code != 0 || name.contains("Never"), "nonzero \(name)")
        }
    }

    private static func probeKeysAndFlags() {
        require(VTFrameProcessorErrorDomain == "VTFrameProcessorErrorDomain", "error domain")
        require(kVTCompressionPropertyKey_AverageBitRate == "kVTCompressionPropertyKey_AverageBitRate", "bitrate key")
        require(kVTEncodeFrameOptionKey_ForceKeyFrame == "kVTEncodeFrameOptionKey_ForceKeyFrame", "force keyframe")
        let keys = VideoToolboxLinuxKeys.all
        require(keys.count == 282, "key count \(keys.count)")
        require(Set(keys).count == keys.count, "keys unique")
        require(keys.allSatisfy { !$0.isEmpty }, "keys nonempty")

        var decode = VTDecodeInfoFlags.asynchronous
        require(decode.contains(.asynchronous), "async flag")
        decode.insert(.frameDropped)
        require(decode.contains(.frameDropped), "dropped flag")
        require(VTDecodeInfoFlags.frameInterrupted.rawValue == 1 << 4, "interrupted bit")
        require(VTEncodeInfoFlags.asynchronous.union(.frameDropped).contains(.frameDropped), "encode union")
        require(VTCompressionSessionOptionFlags.beginFinalPass.rawValue == 1, "final pass")
        var frames = VTDecodeFrameFlags.enableAsynchronousDecompression
        frames.formUnion(.doNotOutputFrame)
        require(!frames.isEmpty, "decode frame flags")
        require(VTInt32Point(x: 1, y: 2).x == 1, "point")
        require(VTInt32Size(width: 3, height: 4).height == 4, "size")
        require(VTInt32Point().x == 0 && VTInt32Size().width == 0, "zero structs")
        let record = VTDecompressionOutputCallbackRecord()
        require(record.decompressionOutputCallback == nil, "callback nil")
        let hdr = VTHDRPerFrameMetadataGenerationHDRFormatType("DolbyVision")
        require(hdr.rawValue == "DolbyVision", "hdr wrapper")
        require(
            VTMotionEstimationSession.FrameFlags.currentBufferWillBeNextReferenceBuffer.contains(
                .currentBufferWillBeNextReferenceBuffer
            ),
            "motion flags"
        )
        require(VTMotionEstimationSession.BlockSize.blockSize16x16.rawValue == 0, "block 16")
        require(VTMotionEstimationSession.BlockSize(rawValue: 1) == .blockSize4x4, "block 4")
    }

    private static func probeSessions() {
        require(VTCompressionSessionGetTypeID() != VTDecompressionSessionGetTypeID(), "type ids")
        require(!VTIsHardwareDecodeSupported(0x68766331), "no hw decode")
        require(!VTIsStereoMVHEVCDecodeSupported() && !VTIsStereoMVHEVCEncodeSupported(), "no mv-hevc")

        var encoders: CFArray?
        require(VTCopyVideoEncoderList(nil, &encoders) == noErr, "encoder list status")
        require(encoders?.isEmpty == true, "encoder list empty")

        var encoderID: CFString?
        var properties: CFDictionary?
        require(
            VTCopySupportedPropertyDictionaryForEncoder(
                width: 1920,
                height: 1080,
                codecType: 0x68766331,
                encoderSpecification: nil,
                encoderIDOut: &encoderID,
                supportedPropertiesOut: &properties
            ) == kVTCouldNotFindVideoEncoderErr,
            "supported encoder dict"
        )
        require(encoderID == nil && properties == nil, "no encoder dict")

        var compression: VTCompressionSession?
        require(
            VTCompressionSessionCreate(
                allocator: nil,
                width: 16,
                height: 16,
                codecType: 0x68766331,
                encoderSpecification: nil,
                imageBufferAttributes: nil,
                compressedDataAllocator: nil,
                outputCallback: nil,
                refcon: nil,
                compressionSessionOut: &compression
            ) == kVTCouldNotFindVideoEncoderErr,
            "create compressor"
        )
        require(compression == nil, "nil compressor")

        var decompression: VTDecompressionSession?
        require(
            VTDecompressionSessionCreate(
                allocator: nil,
                formatDescription: CMFormatDescription(),
                decoderSpecification: nil,
                imageBufferAttributes: nil,
                decompressionSessionOut: &decompression
            ) == kVTCouldNotFindVideoDecoderErr,
            "create decompressor"
        )
        require(decompression == nil, "nil decompressor")

        let deadCompression = VTCompressionSession()
        require(deadCompression == deadCompression, "compression identity")
        require(deadCompression != VTCompressionSession(), "compression distinct")
        require(
            VTCompressionSessionPrepareToEncodeFrames(deadCompression) == kVTCouldNotFindVideoEncoderErr,
            "prepare"
        )
        var encodeFlags = VTEncodeInfoFlags()
        require(
            VTCompressionSessionEncodeFrame(
                deadCompression,
                imageBuffer: CVPixelBuffer(),
                presentationTimeStamp: .zero,
                duration: .invalid,
                frameProperties: nil,
                sourceFrameRefcon: nil,
                infoFlagsOut: &encodeFlags
            ) == kVTCouldNotFindVideoEncoderErr,
            "encode"
        )
        var handlerStatus: OSStatus = 0
        require(
            VTCompressionSessionEncodeFrame(
                deadCompression,
                imageBuffer: CVPixelBuffer(),
                presentationTimeStamp: .zero,
                duration: .invalid,
                frameProperties: nil,
                infoFlagsOut: nil,
                outputHandler: { status, _, _ in handlerStatus = status }
            ) == kVTCouldNotFindVideoEncoderErr,
            "encode handler"
        )
        require(handlerStatus == kVTCouldNotFindVideoEncoderErr, "handler status")
        require(
            VTCompressionSessionCompleteFrames(deadCompression, untilPresentationTimeStamp: .invalid)
                == kVTCouldNotFindVideoEncoderErr,
            "complete"
        )
        require(
            VTCompressionSessionBeginPass(deadCompression, flags: .beginFinalPass, nil)
                == kVTCouldNotFindVideoEncoderErr,
            "begin pass"
        )
        var further = false
        require(
            VTCompressionSessionEndPass(deadCompression, furtherPassesRequestedOut: &further, nil)
                == kVTCouldNotFindVideoEncoderErr,
            "end pass"
        )
        var rangeCount: CMItemCount = 1
        var ranges: UnsafePointer<CMTimeRange>?
        require(
            VTCompressionSessionGetTimeRangesForNextPass(
                deadCompression,
                timeRangeCountOut: &rangeCount,
                timeRangeArrayOut: &ranges
            ) == kVTCouldNotFindVideoEncoderErr,
            "next pass ranges"
        )
        require(VTCompressionSessionGetPixelBufferPool(deadCompression) == nil, "pool")
        VTCompressionSessionInvalidate(deadCompression)
        require(
            VTCompressionSessionEncodeMultiImageFrame(
                deadCompression,
                taggedBuffers: [CMTaggedBuffer()],
                presentationTimeStamp: .zero,
                duration: .invalid,
                frameProperties: nil,
                infoFlagsOut: nil,
                outputHandler: { _, _, _ in }
            ) == kVTCouldNotOutputTaggedBufferGroupErr,
            "multi image"
        )

        let deadDecompression = VTDecompressionSession()
        var decodeFlags = VTDecodeInfoFlags()
        require(
            VTDecompressionSessionDecodeFrame(
                deadDecompression,
                sampleBuffer: CMSampleBuffer(),
                flags: [.enableAsynchronousDecompression],
                frameRefcon: nil,
                infoFlagsOut: &decodeFlags
            ) == kVTCouldNotFindVideoDecoderErr,
            "decode"
        )
        require(
            VTDecompressionSessionDecodeFrame(
                deadDecompression,
                sampleBuffer: CMSampleBuffer(),
                flags: [],
                frameOptions: nil,
                frameRefcon: nil,
                infoFlagsOut: nil
            ) == kVTCouldNotFindVideoDecoderErr,
            "decode options"
        )
        var decodeHandler = noErr
        require(
            VTDecompressionSessionDecodeFrame(
                deadDecompression,
                sampleBuffer: CMSampleBuffer(),
                flags: [],
                infoFlagsOut: nil,
                outputHandler: { status, _, _, _, _ in decodeHandler = status }
            ) == kVTCouldNotFindVideoDecoderErr,
            "decode handler"
        )
        require(decodeHandler == kVTCouldNotFindVideoDecoderErr, "decode handler status")
        require(
            VTDecompressionSessionDecodeFrame(
                deadDecompression,
                sampleBuffer: CMSampleBuffer(),
                flags: [],
                frameOptions: nil,
                infoFlagsOut: nil,
                outputHandler: { _, _, _, _, _ in }
            ) == kVTCouldNotFindVideoDecoderErr,
            "decode options handler"
        )
        require(
            VTDecompressionSessionDecodeFrame(
                deadDecompression,
                sampleBuffer: CMSampleBuffer(),
                flags: [],
                infoFlagsOut: nil,
                completionHandler: { _, _, _, _, _, _ in }
            ) == kVTCouldNotFindVideoDecoderErr,
            "decode completion"
        )
        require(
            VTDecompressionSessionFinishDelayedFrames(deadDecompression) == kVTCouldNotFindVideoDecoderErr,
            "finish delayed"
        )
        require(
            VTDecompressionSessionWaitForAsynchronousFrames(deadDecompression)
                == kVTCouldNotFindVideoDecoderErr,
            "wait async"
        )
        require(
            !VTDecompressionSessionCanAcceptFormatDescription(
                deadDecompression,
                formatDescription: CMFormatDescription()
            ),
            "accept format"
        )
        var black: CVPixelBuffer?
        require(
            VTDecompressionSessionCopyBlackPixelBuffer(deadDecompression, pixelBufferOut: &black)
                == kVTCouldNotFindVideoDecoderErr,
            "black"
        )
        VTDecompressionSessionInvalidate(deadDecompression)

        var silo: VTFrameSilo?
        require(
            VTFrameSiloCreate(
                allocator: nil,
                fileURL: nil,
                timeRange: CMTimeRange(),
                options: nil,
                frameSiloOut: &silo
            ) == kVTCouldNotCreateInstanceErr,
            "silo create"
        )
        let deadSilo = VTFrameSilo()
        require(
            VTFrameSiloAddSampleBuffer(deadSilo, sampleBuffer: CMSampleBuffer())
                == kVTCouldNotCreateInstanceErr,
            "silo add"
        )
        require(
            VTFrameSiloCallBlockForEachSampleBuffer(deadSilo, in: CMTimeRange(), handler: { _ in noErr })
                == kVTCouldNotCreateInstanceErr,
            "silo block"
        )
        require(
            VTFrameSiloCallFunctionForEachSampleBuffer(
                deadSilo,
                in: CMTimeRange(),
                refcon: nil,
                callback: { _, _ in noErr }
            ) == kVTCouldNotCreateInstanceErr,
            "silo function"
        )
        var progress: Float32 = 1
        require(
            VTFrameSiloGetProgressOfCurrentPass(deadSilo, progressOut: &progress)
                == kVTCouldNotCreateInstanceErr,
            "silo progress"
        )
        var range = CMTimeRange()
        require(
            VTFrameSiloSetTimeRangesForNextPass(deadSilo, timeRangeCount: 1, timeRangeArray: &range)
                == kVTCouldNotCreateInstanceErr,
            "silo ranges"
        )

        var storage: VTMultiPassStorage?
        require(
            VTMultiPassStorageCreate(
                allocator: nil,
                fileURL: nil,
                timeRange: CMTimeRange(),
                options: nil,
                multiPassStorageOut: &storage
            ) == kVTCouldNotCreateInstanceErr,
            "multipass create"
        )
        require(VTMultiPassStorageClose(VTMultiPassStorage()) == noErr, "multipass close")

        var rotation: VTPixelRotationSession?
        require(
            VTPixelRotationSessionCreate(nil, &rotation) == kVTPixelRotationNotSupportedErr,
            "rotation create"
        )
        let deadRotation = VTPixelRotationSession()
        require(
            VTPixelRotationSessionRotateImage(deadRotation, CVPixelBuffer(), CVPixelBuffer())
                == kVTPixelRotationNotSupportedErr,
            "rotate"
        )
        VTPixelRotationSessionInvalidate(deadRotation)

        var transfer: VTPixelTransferSession?
        require(
            VTPixelTransferSessionCreate(allocator: nil, pixelTransferSessionOut: &transfer)
                == kVTPixelTransferNotSupportedErr,
            "transfer create"
        )
        let deadTransfer = VTPixelTransferSession()
        require(
            VTPixelTransferSessionTransferImage(
                deadTransfer,
                from: CVPixelBuffer(),
                to: CVPixelBuffer()
            ) == kVTPixelTransferNotSupportedErr,
            "transfer"
        )
        VTPixelTransferSessionInvalidate(deadTransfer)

        var image: CGImage?
        require(
            VTCreateCGImageFromCVPixelBuffer(CVPixelBuffer(), options: nil, imageOut: &image)
                == kVTPixelTransferNotSupportedErr,
            "cgimage"
        )
        require(
            VTSessionSetProperty(deadCompression, key: kVTCompressionPropertyKey_Quality, value: nil)
                == kVTPropertyNotSupportedErr,
            "set property"
        )
        require(
            VTSessionSetProperties(deadCompression, propertyDictionary: [:])
                == kVTPropertyNotSupportedErr,
            "set properties"
        )
        var copied: CFDictionary?
        require(
            VTSessionCopySupportedPropertyDictionary(
                deadCompression,
                supportedPropertyDictionaryOut: &copied
            ) == kVTPropertyNotSupportedErr,
            "copy supported"
        )
        require(
            VTSessionCopySerializableProperties(deadCompression, allocator: nil, dictionaryOut: &copied)
                == kVTPropertyNotSupportedErr,
            "copy serializable"
        )
        require(
            VTSessionCopyProperty(
                deadCompression,
                key: kVTCompressionPropertyKey_AverageBitRate,
                allocator: nil,
                valueOut: nil
            ) == kVTPropertyNotSupportedErr,
            "copy property"
        )
        require(deadSilo.hashValue != 0 || deadSilo.hashValue == 0, "hash defined")
    }

    private static func probeFrameProcessor() {
        require(VTFrameProcessorError.unknownError.rawValue == -19730, "unknown code")
        require(VTFrameProcessorError.assetDownloadFailed.rawValue == -19743, "download code")
        require(VTFrameProcessorError.errorDomain == VTFrameProcessorErrorDomain, "bridged domain")
        let error = VTFrameProcessorError(.initializationFailed)
        require(error.errorCode == VTFrameProcessorError.initializationFailed.rawValue, "error code")
        require(error.code == .initializationFailed, "typed code")
        require(error == VTFrameProcessorError(.initializationFailed), "error eq")
        switch error {
        case VTFrameProcessorError.initializationFailed:
            break
        default:
            fatalError("pattern match")
        }
        require(!error.localizedDescription.isEmpty, "localized")

        require(!VTFrameRateConversionConfiguration.isSupported, "frc support")
        require(!VTLowLatencyFrameInterpolationConfiguration.isSupported, "llfi support")
        require(!VTLowLatencySuperResolutionScalerConfiguration.isSupported, "llsr support")
        require(!VTMotionBlurConfiguration.isSupported, "blur support")
        require(!VTOpticalFlowConfiguration.isSupported, "flow support")
        require(!VTSuperResolutionScalerConfiguration.isSupported, "sr support")
        require(!VTTemporalNoiseFilterConfiguration.isSupported, "tnf support")
        require(VTFrameRateConversionConfiguration.defaultRevision == .revision1, "frc rev")
        require(VTFrameRateConversionConfiguration.supportedRevisions.isEmpty, "frc revs")
        require(VTSuperResolutionScalerConfiguration.supportedScaleFactors.isEmpty, "sr scales")
        require(
            VTLowLatencySuperResolutionScalerConfiguration.supportedScaleFactors(
                frameWidth: 64,
                frameHeight: 64
            ).isEmpty,
            "llsr scales"
        )
        require(
            VTFrameRateConversionConfiguration(
                frameWidth: 64,
                frameHeight: 64,
                usePrecomputedFlow: false,
                qualityPrioritization: .normal,
                revision: .revision1
            ) == nil,
            "frc init"
        )
        require(
            VTLowLatencyFrameInterpolationConfiguration(
                frameWidth: 64,
                frameHeight: 64,
                numberOfInterpolatedFrames: 1
            ) == nil,
            "llfi init"
        )
        require(
            VTLowLatencyFrameInterpolationConfiguration(
                frameWidth: 64,
                frameHeight: 64,
                spatialScaleFactor: 2
            ) == nil,
            "llfi scale init"
        )
        require(
            VTMotionBlurConfiguration(
                frameWidth: 64,
                frameHeight: 64,
                usePrecomputedFlow: false,
                qualityPrioritization: .normal,
                revision: .revision1
            ) == nil,
            "blur init"
        )
        require(
            VTOpticalFlowConfiguration(
                frameWidth: 64,
                frameHeight: 64,
                qualityPrioritization: .quality,
                revision: .revision1
            ) == nil,
            "flow init"
        )
        require(
            VTSuperResolutionScalerConfiguration(
                frameWidth: 64,
                frameHeight: 64,
                scaleFactor: 2,
                inputType: .video,
                usePrecomputedFlow: false,
                qualityPrioritization: .normal,
                revision: .revision1
            ) == nil,
            "sr init"
        )
        require(
            VTTemporalNoiseFilterConfiguration(
                frameWidth: 64,
                frameHeight: 64,
                sourcePixelFormat: 0
            ) == nil,
            "tnf init"
        )

        let scaler = VTLowLatencySuperResolutionScalerConfiguration(
            frameWidth: 32,
            frameHeight: 16,
            scaleFactor: 2
        )
        require(scaler.frameWidth == 32 && scaler.scaleFactor == 2, "scaler props")
        require(scaler.sourcePixelBufferAttributes.isEmpty, "scaler attrs")
        require(type(of: scaler).maximumDimensions == nil, "scaler max")
        require(scaler.supportedPixelFormats.isEmpty, "scaler formats")

        let buffer = CVPixelBuffer()
        let frame = VTFrameProcessorFrame(buffer: buffer, presentationTimeStamp: .zero)
        require(frame != nil, "frame wrap")
        require(frame?.presentationTimeStamp == .zero, "frame pts")
        let flow = VTFrameProcessorOpticalFlow(forwardFlow: buffer, backwardFlow: buffer)
        require(flow != nil, "flow wrap")

        let dest = VTFrameProcessorFrame(buffer: CVPixelBuffer(), presentationTimeStamp: .zero)!
        let params = VTLowLatencySuperResolutionScalerParameters(
            sourceFrame: frame!,
            destinationFrame: dest
        )
        require(params.sourceFrame === frame, "params source")
        require(params.destinationFrame === dest, "params dest")

        let processor = VTFrameProcessor()
        processor.endSession()
        processor.process(with: ProbeCommandBuffer(), parameters: params)
        do {
            try processor.startSession(configuration: scaler)
            fatalError("startSession must fail")
        } catch let error as VTFrameProcessorError {
            require(error.code == .initializationFailed, "start error")
        } catch {
            fatalError("typed error")
        }

        let blurParams = VTMotionBlurParameters(
            sourceFrame: frame!,
            nextFrame: nil,
            previousFrame: nil,
            nextOpticalFlow: nil,
            previousOpticalFlow: nil,
            motionBlurStrength: 1,
            submissionMode: .sequential,
            destinationFrame: dest
        )
        require(blurParams?.motionBlurStrength == 1, "blur strength")
        let ofParams = VTOpticalFlowParameters(
            sourceFrame: frame!,
            nextFrame: dest,
            submissionMode: .random,
            destinationOpticalFlow: flow!
        )
        require(ofParams?.nextFrame === dest, "of next")
        let srParams = VTSuperResolutionScalerParameters(
            sourceFrame: frame!,
            previousFrame: nil,
            previousOutputFrame: nil,
            opticalFlow: nil,
            submissionMode: .sequential,
            destinationFrame: dest
        )
        require(srParams?.destinationFrames?.count == 1, "sr dests")
        let tnfParams = VTTemporalNoiseFilterParameters(
            sourceFrame: frame!,
            nextFrames: [],
            previousFrames: [],
            destinationFrame: dest,
            filterStrength: 0.5,
            hasDiscontinuity: false
        )
        require(tnfParams?.filterStrength == 0.5, "tnf strength")
        let frcParams = VTFrameRateConversionParameters(
            sourceFrame: frame!,
            nextFrame: dest,
            opticalFlow: flow,
            interpolationPhase: [0.5],
            submissionMode: .sequential,
            destinationFrames: [dest]
        )
        require(frcParams?.interpolationPhase == [0.5], "frc phase")
        let llfiParams = VTLowLatencyFrameInterpolationParameters(
            sourceFrame: frame!,
            previousFrame: dest,
            interpolationPhase: [0.25],
            destinationFrames: [dest]
        )
        require(llfiParams?.previousFrame === dest, "llfi prev")
        let readOnly = VTFrameProcessorFrame.ReadOnlyFrame(
            frame: CVReadOnlyPixelBuffer(buffer),
            timeStamp: .zero
        )
        require(readOnly.timeStamp == .zero, "readonly")
    }

    private static func probeAsyncFailClosed() async {
        let processor = VTFrameProcessor()
        let frame = VTFrameProcessorFrame(buffer: CVPixelBuffer(), presentationTimeStamp: .zero)!
        let dest = VTFrameProcessorFrame(buffer: CVPixelBuffer(), presentationTimeStamp: .zero)!
        let params = VTLowLatencySuperResolutionScalerParameters(
            sourceFrame: frame,
            destinationFrame: dest
        )
        do {
            _ = try await processor.process(parameters: params)
            fatalError("async process must fail")
        } catch let error as VTFrameProcessorError {
            require(error.code == .sessionNotStarted, "async process")
        } catch {
            fatalError("typed async error")
        }

        var streamFailed = false
        do {
            for try await _ in processor.process(parameters: params) {
                fatalError("stream must be empty")
            }
        } catch let error as VTFrameProcessorError {
            streamFailed = error.code == .sessionNotStarted
        } catch {
            fatalError("typed stream error")
        }
        require(streamFailed, "stream fail closed")

        do {
            _ = try VTMotionEstimationSession(width: 16, height: 16)
            fatalError("motion session must fail")
        } catch let error as VTFrameProcessorError {
            require(error.code == .initializationFailed, "motion init")
        } catch {
            fatalError("typed motion error")
        }

        do {
            _ = try VTHDRPerFrameMetadataGenerationSession(framesPerSecond: 24, hdrFormats: [.dolbyVision])
            fatalError("hdr session must fail")
        } catch let error as VTFrameProcessorError {
            require(error.code == .initializationFailed, "hdr init")
        } catch {
            fatalError("typed hdr error")
        }
    }
}

VideoToolboxRuntime.main()
