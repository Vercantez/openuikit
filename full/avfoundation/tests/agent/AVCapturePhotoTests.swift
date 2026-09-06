import Foundation
import AVFoundation

private final class AVCapturePhotoFailClosedDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    var finishError: AVError?
    var resolvedID: Int64 = 0

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: (any Error)?
    ) {
        finishError = error as? AVError
        _ = photo
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
        error: (any Error)?
    ) {
        resolvedID = resolvedSettings.uniqueID
        if finishError == nil {
            finishError = error as? AVError
        }
        _ = output
    }
}

private final class AVCaptureReadinessProbe: NSObject, AVCapturePhotoOutputReadinessCoordinatorDelegate {
    var changes = 0
    func readinessCoordinator(
        _ coordinator: AVCapturePhotoOutputReadinessCoordinator,
        captureReadinessDidChange captureReadiness: AVCapturePhotoOutput.CaptureReadiness
    ) {
        changes += 1
        _ = (coordinator, captureReadiness)
    }
}

func testAVCapturePhotoOutputFailClosedModel() {
    let output = AVCapturePhotoOutput()
    precondition(output.supportedFlashModes.isEmpty)
    precondition(output.availablePhotoPixelFormatTypes.isEmpty)
    precondition(output.availableRawPhotoPixelFormatTypes.isEmpty)
    precondition(output.supportedPhotoPixelFormatTypes(for: .jpg).isEmpty)
    precondition(output.supportedRawPhotoPixelFormatTypes(for: .dng).isEmpty)
    precondition(output.preparedPhotoSettingsArray.isEmpty)
    precondition(output.availablePhotoCodecTypes.isEmpty)
    precondition(output.availableRawPhotoCodecTypes.isEmpty)
    precondition(!output.isAppleProRAWSupported)
    output.isAppleProRAWEnabled = true
    precondition(output.isAppleProRAWEnabled)
    precondition(!AVCapturePhotoOutput.isBayerRAWPixelFormat(0x42474152))
    precondition(!AVCapturePhotoOutput.isAppleProRAWPixelFormat(0x6170726f))
    precondition(output.availablePhotoFileTypes.isEmpty)
    precondition(output.availableRawPhotoFileTypes.isEmpty)
    precondition(output.supportedPhotoCodecTypes(for: .jpg).isEmpty)
    precondition(output.supportedRawPhotoCodecTypes(forRawPhotoPixelFormatType: 0, fileType: .dng).isEmpty)
    output.maxPhotoQualityPrioritization = .quality
    precondition(output.maxPhotoQualityPrioritization == .quality)
    precondition(!output.isFastCapturePrioritizationSupported)
    output.isFastCapturePrioritizationEnabled = true
    precondition(output.isFastCapturePrioritizationEnabled)
    precondition(!output.isAutoDeferredPhotoDeliverySupported)
    output.isAutoDeferredPhotoDeliveryEnabled = true
    precondition(output.isAutoDeferredPhotoDeliveryEnabled)
    precondition(!output.isStillImageStabilizationSupported)
    precondition(!output.isStillImageStabilizationScene)
    precondition(!output.isVirtualDeviceFusionSupported)
    precondition(!output.isDualCameraFusionSupported)
    precondition(!output.isVirtualDeviceConstituentPhotoDeliverySupported)
    precondition(!output.isDualCameraDualPhotoDeliverySupported)
    output.isVirtualDeviceConstituentPhotoDeliveryEnabled = true
    precondition(output.isVirtualDeviceConstituentPhotoDeliveryEnabled)
    output.isDualCameraDualPhotoDeliveryEnabled = true
    precondition(output.isDualCameraDualPhotoDeliveryEnabled)
    precondition(!output.isCameraCalibrationDataDeliverySupported)
    precondition(!output.isAutoRedEyeReductionSupported)
    precondition(!output.isFlashScene)
    let monitor = AVCapturePhotoSettings()
    output.photoSettingsForSceneMonitoring = monitor
    precondition(output.photoSettingsForSceneMonitoring === monitor)
    output.isHighResolutionCaptureEnabled = true
    precondition(output.isHighResolutionCaptureEnabled)
    output.maxPhotoDimensions = CMVideoDimensions(width: 1920, height: 1080)
    precondition(output.maxPhotoDimensions.width == 1920)
    precondition(output.maxBracketedCapturePhotoCount == 0)
    precondition(!output.isLensStabilizationDuringBracketedCaptureSupported)
    precondition(!output.isLivePhotoCaptureSupported)
    output.isLivePhotoCaptureEnabled = true
    precondition(output.isLivePhotoCaptureEnabled)
    output.isLivePhotoCaptureSuspended = true
    precondition(output.isLivePhotoCaptureSuspended)
    output.preservesLivePhotoCaptureSuspendedOnSessionStop = true
    precondition(output.preservesLivePhotoCaptureSuspendedOnSessionStop)
    output.isLivePhotoAutoTrimmingEnabled = true
    precondition(output.isLivePhotoAutoTrimmingEnabled)
    precondition(output.availableLivePhotoVideoCodecTypes.isEmpty)
    precondition(AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: CMSampleBuffer(), previewPhotoSampleBuffer: nil) == nil)
    precondition(AVCapturePhotoOutput.dngPhotoDataRepresentation(forRawSampleBuffer: CMSampleBuffer(), previewPhotoSampleBuffer: nil) == nil)
    precondition(!output.isContentAwareDistortionCorrectionSupported)
    output.isContentAwareDistortionCorrectionEnabled = true
    precondition(output.isContentAwareDistortionCorrectionEnabled)
    precondition(!output.isZeroShutterLagSupported)
    output.isZeroShutterLagEnabled = true
    precondition(output.isZeroShutterLagEnabled)
    precondition(!output.isResponsiveCaptureSupported)
    output.isResponsiveCaptureEnabled = true
    precondition(output.isResponsiveCaptureEnabled)
    precondition(output.captureReadiness == .sessionNotRunning)
    precondition(AVCapturePhotoOutput.CaptureReadiness.sessionNotRunning.rawValue == 0)
    precondition(!output.isConstantColorSupported)
    output.isConstantColorEnabled = true
    precondition(output.isConstantColorEnabled)
    precondition(!output.isShutterSoundSuppressionSupported)
    precondition(!output.isCameraSensorOrientationCompensationSupported)
    output.isCameraSensorOrientationCompensationEnabled = true
    precondition(output.isCameraSensorOrientationCompensationEnabled)
    precondition(!output.isDepthDataDeliverySupported)
    output.isDepthDataDeliveryEnabled = true
    precondition(output.isDepthDataDeliveryEnabled)
    precondition(!output.isPortraitEffectsMatteDeliverySupported)
    output.isPortraitEffectsMatteDeliveryEnabled = true
    precondition(output.isPortraitEffectsMatteDeliveryEnabled)
    precondition(output.availableSemanticSegmentationMatteTypes.isEmpty)
    output.enabledSemanticSegmentationMatteTypes = []
    precondition(output.enabledSemanticSegmentationMatteTypes.isEmpty)
    let delegate = AVCapturePhotoFailClosedDelegate()
    let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg.rawValue])
    output.capturePhoto(with: settings, delegate: delegate)
    precondition(delegate.finishError?.code == .applicationIsNotAuthorizedToUseDevice)
    precondition(delegate.resolvedID == settings.uniqueID)
    let coordinator = AVCapturePhotoOutputReadinessCoordinator(photoOutput: output)
    precondition(coordinator.captureReadiness == AVCapturePhotoOutput.CaptureReadiness.sessionNotRunning)
    let readiness = AVCaptureReadinessProbe()
    coordinator.delegate = readiness
    coordinator.startTrackingCaptureRequest(using: settings)
    precondition(readiness.changes == 1)
    coordinator.stopTrackingCaptureRequest(using: settings.uniqueID)
    coordinator.delegate = nil
    precondition(coordinator.delegate == nil)
}

func testAVCapturePhotoSettingsStoredModel() {
    let format = [AVVideoCodecKey: AVVideoCodecType.jpeg.rawValue]
    let settings = AVCapturePhotoSettings(format: format)
    precondition(settings.uniqueID != 0)
    precondition(settings.format?[AVVideoCodecKey] as? String == AVVideoCodecType.jpeg.rawValue)
    precondition(settings.availablePreviewPhotoPixelFormatTypes.isEmpty)
    settings.flashMode = .auto
    precondition(settings.flashMode == .auto)
    settings.isAutoRedEyeReductionEnabled = true
    precondition(settings.isAutoRedEyeReductionEnabled)
    settings.photoQualityPrioritization = .quality
    precondition(settings.photoQualityPrioritization == .quality)
    settings.isAutoStillImageStabilizationEnabled = true
    precondition(settings.isAutoStillImageStabilizationEnabled)
    settings.isAutoVirtualDeviceFusionEnabled = true
    precondition(settings.isAutoVirtualDeviceFusionEnabled)
    settings.isAutoDualCameraFusionEnabled = true
    precondition(settings.isAutoDualCameraFusionEnabled)
    settings.virtualDeviceConstituentPhotoDeliveryEnabledDevices = []
    precondition(settings.virtualDeviceConstituentPhotoDeliveryEnabledDevices.isEmpty)
    settings.isDualCameraDualPhotoDeliveryEnabled = true
    precondition(settings.isDualCameraDualPhotoDeliveryEnabled)
    settings.isHighResolutionPhotoEnabled = true
    precondition(settings.isHighResolutionPhotoEnabled)
    settings.maxPhotoDimensions = CMVideoDimensions(width: 4032, height: 3024)
    precondition(settings.maxPhotoDimensions.width == 4032)
    settings.isDepthDataDeliveryEnabled = true
    precondition(settings.isDepthDataDeliveryEnabled)
    settings.embedsDepthDataInPhoto = true
    precondition(settings.embedsDepthDataInPhoto)
    settings.isDepthDataFiltered = true
    precondition(settings.isDepthDataFiltered)
    settings.isCameraCalibrationDataDeliveryEnabled = true
    precondition(settings.isCameraCalibrationDataDeliveryEnabled)
    settings.isPortraitEffectsMatteDeliveryEnabled = true
    precondition(settings.isPortraitEffectsMatteDeliveryEnabled)
    settings.embedsPortraitEffectsMatteInPhoto = true
    precondition(settings.embedsPortraitEffectsMatteInPhoto)
    settings.enabledSemanticSegmentationMatteTypes = []
    precondition(settings.enabledSemanticSegmentationMatteTypes.isEmpty)
    settings.embedsSemanticSegmentationMattesInPhoto = true
    precondition(settings.embedsSemanticSegmentationMattesInPhoto)
    settings.metadata = ["key": "value"]
    precondition(settings.metadata["key"] as? String == "value")
    let liveURL = URL(fileURLWithPath: "/tmp/openav-live.mov")
    settings.livePhotoMovieFileURL = liveURL
    precondition(settings.livePhotoMovieFileURL == liveURL)
    settings.livePhotoVideoCodecType = .hevc
    precondition(settings.livePhotoVideoCodecType == .hevc)
    settings.livePhotoMovieMetadata = []
    precondition(settings.livePhotoMovieMetadata.isEmpty)
    settings.previewPhotoFormat = ["width": 320]
    precondition(settings.previewPhotoFormat != nil)
    precondition(settings.availableEmbeddedThumbnailPhotoCodecTypes.isEmpty)
    settings.embeddedThumbnailPhotoFormat = ["codec": "jpeg"]
    precondition(settings.embeddedThumbnailPhotoFormat != nil)
    precondition(settings.availableRawEmbeddedThumbnailPhotoCodecTypes.isEmpty)
    settings.rawEmbeddedThumbnailPhotoFormat = ["codec": "dng"]
    precondition(settings.rawEmbeddedThumbnailPhotoFormat != nil)
    settings.isAutoContentAwareDistortionCorrectionEnabled = true
    precondition(settings.isAutoContentAwareDistortionCorrectionEnabled)
    settings.isConstantColorEnabled = true
    precondition(settings.isConstantColorEnabled)
    settings.isConstantColorFallbackPhotoDeliveryEnabled = true
    precondition(settings.isConstantColorFallbackPhotoDeliveryEnabled)
    settings.isShutterSoundSuppressionEnabled = true
    precondition(settings.isShutterSoundSuppressionEnabled)
    settings.rawFileFormat = ["raw": true]
    precondition(settings.rawFileFormat != nil)
    let copied = AVCapturePhotoSettings(from: settings)
    precondition(copied.uniqueID != settings.uniqueID)
    precondition(copied.flashMode == .auto)
    let rawOnly = AVCapturePhotoSettings(rawPixelFormatType: 0x42474152)
    precondition(rawOnly.uniqueID != settings.uniqueID)
    let rawProcessed = AVCapturePhotoSettings(rawPixelFormatType: 0x42474152, processedFormat: format)
    precondition(rawProcessed.format != nil)
    let typed = AVCapturePhotoSettings(
        rawPixelFormatType: 0x42474152,
        rawFileType: .dng,
        processedFormat: format,
        processedFileType: .jpg
    )
    precondition(typed.rawFileType == .dng)
    precondition(typed.processedFileType == .jpg)
}
