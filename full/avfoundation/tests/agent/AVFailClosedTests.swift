import Foundation
import AVFoundation

func testAVErrorHashable() {
    precondition(AVError.unknown == AVError.unknown)
    precondition(AVError(.unknown) == AVError(.unknown))
    precondition(AVError(.unknown) != AVError(.mediaServicesWereReset))
    var hasher = Hasher()
    AVError(.encoderNotFound).hash(into: &hasher)
    _ = hasher.finalize()
}

func testAVErrorUserInfoKeys() {
    precondition(AVErrorDeviceKey == "AVErrorDeviceKey")
    precondition(AVErrorTimeKey == "AVErrorTimeKey")
    precondition(AVErrorFileSizeKey == "AVErrorFileSizeKey")
    precondition(AVErrorPIDKey == "AVErrorPIDKey")
    precondition(AVErrorRecordingSuccessfullyFinishedKey == "AVErrorRecordingSuccessfullyFinishedKey")
    precondition(AVErrorMediaTypeKey == "AVErrorMediaTypeKey")
    precondition(AVErrorMediaSubTypeKey == "AVErrorMediaSubTypeKey")
    precondition(AVErrorPresentationTimeStampKey == "AVErrorPresentationTimeStampKey")
    precondition(AVErrorPersistentTrackIDKey == "AVErrorPersistentTrackIDKey")
    precondition(AVErrorFileTypeKey == "AVErrorFileTypeKey")
    let stamped = AVError(.noImageAtTime, userInfo: [AVErrorTimeKey: CMTime.zero])
    precondition(stamped.time == .zero)
    precondition(stamped.errorCode == AVError.Code.noImageAtTime.rawValue)
    precondition(AVError.errorDomain == AVFoundationErrorDomain)
}

func testAVAssetWriterStartWritingFailsClosedWithEncoderNotFound() {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("openav-writer-fail-\(UUID().uuidString).mp4")
    try? FileManager.default.removeItem(at: url)
    do {
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        precondition(writer.outputURL == url)
        precondition(writer.outputFileType == .mp4)
        precondition(writer.status == .unknown)
        precondition(writer.error == nil)
        precondition(writer.availableMediaTypes.contains(.video))
        precondition(!writer.startWriting())
        precondition(writer.status == .failed)
        precondition((writer.error as? AVError)?.code == .encoderNotFound)
        do {
            try writer.start()
            preconditionFailure("AVAssetWriter.start() must fail closed")
        } catch let error as AVError {
            precondition(error.code == .encoderNotFound)
        } catch {
            preconditionFailure("unexpected error \(error)")
        }
    } catch {
        preconditionFailure("AVAssetWriter designated initializer should succeed: \(error)")
    }
}

func testAVAssetReaderStartReadingFailsClosedWithDecoderNotFound() {
    let asset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/openav-missing-reader.mp4"))
    do {
        let reader = try AVAssetReader(asset: asset)
        precondition(reader.asset === asset)
        precondition(reader.status == .unknown)
        precondition(!reader.startReading())
        precondition(reader.status == .failed)
        precondition((reader.error as? AVError)?.code == .decoderNotFound)
        precondition(AVAssetReader.Status.cancelled.rawValue == 4)
        precondition(AVAssetReader.Status.failed.rawValue == 3)
        precondition(AVAssetReader.Status.unknown.rawValue == 0)
        precondition(AVAssetReader.Status.reading.rawValue == 1)
        precondition(AVAssetReader.Status.completed.rawValue == 2)
        precondition(AVAssetWriter.Status.cancelled.rawValue == 4)
        precondition(AVAssetWriter.Status.unknown.rawValue == 0)
        precondition(AVAssetWriter.Status.writing.rawValue == 1)
        precondition(AVAssetWriter.Status.completed.rawValue == 2)
        precondition(AVAssetWriter.Status.failed.rawValue == 3)
        do {
            try reader.start()
            preconditionFailure("AVAssetReader.start() must fail closed")
        } catch let error as AVError {
            precondition(error.code == .decoderNotFound)
        } catch {
            preconditionFailure("unexpected error \(error)")
        }
    } catch {
        preconditionFailure("AVAssetReader designated initializer should succeed: \(error)")
    }
}

func testAVAssetImageGeneratorCopyCGImageFailsClosedWithNoImageAtTime() {
    let asset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/openav-missing-generator.mp4"))
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    var actualTime = CMTime.invalid
    do {
        _ = try generator.copyCGImage(
            at: CMTime(seconds: 0, preferredTimescale: 600),
            actualTime: &actualTime
        )
        preconditionFailure("copyCGImage should fail closed")
    } catch let error as AVError {
        precondition(error.code == .noImageAtTime)
        precondition(actualTime == .invalid)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testAVAssetImageGeneratorGenerateTimesFailsClosedWithNoImageAtTime() {
    let generator = AVAssetImageGenerator(
        asset: AVURLAsset(url: URL(fileURLWithPath: "/tmp/openav-missing-generator.mp4"))
    )
    var seen = 0
    generator.generateCGImagesAsynchronously(forTimes: [NSNumber(value: 0)]) { _, image, _, result, error in
        seen += 1
        precondition(image == nil)
        precondition(result == .failed)
        precondition((error as? AVError)?.code == .noImageAtTime)
    }
    precondition(seen == 1)
}

func testAVCaptureDeviceInputFailsClosedUnauthorized() {
    let device = AVCaptureDevice.default(
        .builtInWideAngleCamera,
        for: .video,
        position: .back
    ) ?? AVCaptureDevice()
    do {
        _ = try AVCaptureDeviceInput(device: device)
        preconditionFailure("device input should fail closed")
    } catch let error as AVError {
        precondition(error.code == .applicationIsNotAuthorizedToUseDevice)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testAVCaptureDeviceDiscoverySessionEmptyOnLinux() {
    let session = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .builtInMicrophone],
        mediaType: .video,
        position: .unspecified
    )
    precondition(session.devices.isEmpty)
    precondition(session.supportedMultiCamDeviceSets.isEmpty)
    precondition(AVCaptureDevice.default(for: .video) == nil)
    precondition(AVCaptureDevice.devices(for: .audio).isEmpty)
}

func testAVPlayerLooperReadyThenCancelled() {
    let player = AVQueuePlayer()
    let item = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/openav-looper.mp4"))
    let looper = AVPlayerLooper(player: player, templateItem: item)
    precondition(looper.status == .ready)
    precondition(looper.loopCount == 0)
    precondition(player.items().count == 1)
    precondition(looper.loopingPlayerItems.count == 1)
    precondition(looper.error == nil)
    looper.disableLooping()
    precondition(looper.status == .cancelled)
    precondition(AVPlayerLooper.Status.ready.rawValue == 1)
    precondition(AVPlayerLooper.Status.cancelled.rawValue == 3)
    precondition(AVPlayerLooper.Status.failed.rawValue == 2)
    precondition(AVPlayerLooper.Status.unknown.rawValue == 0)
    precondition(AVPlayerLooper.ItemOrdering.loopingItemsPrecedeExistingItems.rawValue == 0)
    precondition(AVPlayerLooper.ItemOrdering.loopingItemsFollowExistingItems.rawValue == 1)
}

func testAVAudioMixAndVideoCompositionInstructionModels() {
    let mix = AVMutableAudioMix()
    let parameters = AVMutableAudioMixInputParameters()
    parameters.trackID = 1
    parameters.setVolume(0.5, at: .zero)
    parameters.setVolumeRamp(
        fromStartVolume: 0,
        toEndVolume: 1,
        timeRange: CMTimeRange(start: .zero, duration: CMTime(seconds: 1, preferredTimescale: 1))
    )
    mix.inputParameters = [parameters]
    precondition(mix.inputParameters.count == 1)
    precondition(parameters.trackID == 1)
    var start: Float = 0
    var end: Float = 0
    var range = CMTimeRange.invalid
    precondition(parameters.getVolumeRamp(for: .zero, startVolume: &start, endVolume: &end, timeRange: &range))
    precondition(start == 0)
    precondition(end == 1)

    let composition = AVMutableVideoComposition()
    composition.frameDuration = CMTime(value: 1, timescale: 30)
    composition.renderSize = CGSize(width: 1920, height: 1080)
    composition.renderScale = 1
    composition.sourceTrackIDForFrameTiming = 1
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.timeRange = CMTimeRange(
        start: .zero,
        duration: CMTime(seconds: 2, preferredTimescale: 1)
    )
    instruction.backgroundColor = nil
    instruction.enablePostProcessing = true
    let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: AVAssetTrack())
    layer.setOpacity(1, at: .zero)
    layer.setTransform(CGAffineTransform.identity, at: .zero)
    instruction.layerInstructions = [layer]
    composition.instructions = [instruction]
    precondition(composition.instructions.count == 1)
    precondition(composition.renderSize.width == 1920)
    precondition(composition.renderSize.height == 1080)
    precondition(composition.frameDuration.timescale == 30)
    precondition(composition.sourceTrackIDForFrameTiming == 1)
    precondition(instruction.enablePostProcessing)
    precondition(instruction.timeRange.duration.seconds == 2)
    precondition(layer.trackID == 0)
}

func testAVCMTimeRangeValueBridgesCMTimeRange() {
    let range = CMTimeRange(start: .zero, duration: CMTime(seconds: 4, preferredTimescale: 1))
    let boxed = AVCMTimeRangeValue.nsValue(for: range)
    let roundTrip = AVCMTimeRangeValue.range(from: boxed)
    precondition(abs(roundTrip.duration.seconds - 4) < 0.001)
    precondition(roundTrip.start == .zero)
}

func testAVPlayerItemLoadedTimeRangesEmptyWhenAssetMissing() {
    let asset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/openav-missing-player-item.mp4"))
    let item = AVPlayerItem(asset: asset)
    precondition(item.tracks.isEmpty)
    precondition(item.loadedTimeRanges.isEmpty)
    precondition(item.presentationSize == .zero)
    precondition(item.error == nil)
    precondition(!item.duration.isValid)
}

func testAVPlayerPeriodicObserverRegistration() {
    let player = AVPlayer(url: URL(fileURLWithPath: "/tmp/openav-missing-periodic.mp4"))
    let token = player.addPeriodicTimeObserver(
        forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
        queue: nil
    ) { _ in }
    player.removeTimeObserver(token)
    precondition(player.timeControlStatus == .paused)
    precondition(player.status == .readyToPlay)
}

func testAVMediaTypeAndCharacteristicRawValues() {
    precondition(AVMediaType.video.rawValue == "video")
    precondition(AVMediaType.audio.rawValue == "audio")
    precondition(AVMediaType.text.rawValue == "text")
    precondition(AVMediaType.closedCaption.rawValue == "closedCaption")
    precondition(AVMediaType.subtitle.rawValue == "subtitle")
    precondition(AVMediaType.timecode.rawValue == "timecode")
    precondition(AVMediaType.metadata.rawValue == "metadata")
    precondition(AVMediaType.muxed.rawValue == "muxed")
    precondition(AVMediaType.haptic.rawValue == "haptic")
    precondition(AVMediaType.metadataObject.rawValue == "metadataObject")
    precondition(AVMediaType.depthData.rawValue == "depthData")
    precondition(AVMediaType.auxiliaryPicture.rawValue == "auxiliaryPicture")
    precondition(AVMediaCharacteristic.visual.rawValue == "visual")
    precondition(AVMediaCharacteristic.audible.rawValue == "audible")
    precondition(AVMediaCharacteristic.legible.rawValue == "legible")
    precondition(AVMediaCharacteristic.frameBased.rawValue == "frameBased")
    precondition(AVMediaCharacteristic.easyToRead.rawValue == "easyToRead")
    precondition(AVMediaCharacteristic.describesVideoForAccessibility.rawValue == "describesVideoForAccessibility")
    precondition(AVMediaCharacteristic.describesMusicAndSoundForAccessibility.rawValue == "describesMusicAndSoundForAccessibility")
    precondition(AVMediaCharacteristic.transcribesSpokenDialogForAccessibility.rawValue == "transcribesSpokenDialogForAccessibility")
    precondition(AVMediaCharacteristic.containsHDRVideo.rawValue == "containsHDRVideo")
    precondition(AVMediaCharacteristic.containsStereoMultiviewVideo.rawValue == "containsStereoMultiviewVideo")
    precondition(AVMediaCharacteristic.containsAlphaChannel.rawValue == "containsAlphaChannel")
    precondition(AVMediaCharacteristic.enhancesSpeechIntelligibility.rawValue == "enhancesSpeechIntelligibility")
    precondition(AVMediaCharacteristic.usesWideGamutColorSpace.rawValue == "usesWideGamutColorSpace")
    precondition(AVMediaCharacteristic.isMainProgramContent.rawValue == "isMainProgramContent")
    precondition(AVMediaCharacteristic.isAuxiliaryContent.rawValue == "isAuxiliaryContent")
    precondition(AVMediaCharacteristic.languageTranslation.rawValue == "languageTranslation")
}

func testAVVideoCodecAndApertureRawValues() {
    precondition(AVVideoCodecType.h264.rawValue == "h264")
    precondition(AVVideoCodecType.hevc.rawValue == "hevc")
    precondition(AVVideoCodecType.jpeg.rawValue == "jpeg")
    precondition(AVVideoCodecType.JPEGXL.rawValue == "JPEGXL")
    precondition(AVVideoCodecType.proRes422.rawValue == "proRes422")
    precondition(AVVideoCodecType.proRes422HQ.rawValue == "proRes422HQ")
    precondition(AVVideoCodecType.proRes422LT.rawValue == "proRes422LT")
    precondition(AVVideoCodecType.proRes422Proxy.rawValue == "proRes422Proxy")
    precondition(AVVideoCodecType.proRes4444.rawValue == "proRes4444")
    precondition(AVVideoCodecType.appleProRes4444XQ.rawValue == "appleProRes4444XQ")
    precondition(AVVideoCodecType.proResRAW.rawValue == "proResRAW")
    precondition(AVVideoCodecType.proResRAWHQ.rawValue == "proResRAWHQ")
    precondition(AVVideoCodecType.hevcWithAlpha.rawValue == "hevcWithAlpha")
    precondition(AVVideoApertureMode.cleanAperture.rawValue == "cleanAperture")
    precondition(AVVideoApertureMode.productionAperture.rawValue == "productionAperture")
    precondition(AVVideoApertureMode.encodedPixels.rawValue == "encodedPixels")
    precondition(AVAssetImageGenerator.Result.succeeded.rawValue == 0)
    precondition(AVAssetImageGenerator.Result.failed.rawValue == 1)
    precondition(AVAssetImageGenerator.Result.cancelled.rawValue == 2)
    precondition(AVAssetImageGenerator.ApertureMode.cleanAperture.rawValue == "cleanAperture")
    precondition(AVAssetImageGenerator.DynamicRangePolicy.forceSDR.rawValue == "forceSDR")
    precondition(AVAssetImageGenerator.DynamicRangePolicy.matchSource.rawValue == "matchSource")
}
