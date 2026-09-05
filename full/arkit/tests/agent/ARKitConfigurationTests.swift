import Foundation
import ARKit

func testConfigurationUnsupportedWithoutHook() {
    ARKitTestHook.removeSimulatedDevice()
    arkitRequire(!ARConfiguration.isSupported, "base")
    arkitRequire(!ARWorldTrackingConfiguration.isSupported, "world")
    arkitRequire(!AROrientationTrackingConfiguration.isSupported, "orientation")
    arkitRequire(!ARFaceTrackingConfiguration.isSupported, "face")
    arkitRequire(!ARImageTrackingConfiguration.isSupported, "image")
    arkitRequire(!ARObjectScanningConfiguration.isSupported, "object")
    arkitRequire(!ARBodyTrackingConfiguration.isSupported, "body")
    arkitRequire(!ARPositionalTrackingConfiguration.isSupported, "positional")
    arkitRequire(!ARGeoTrackingConfiguration.isSupported, "geo")
    arkitRequire(ARWorldTrackingConfiguration.supportedVideoFormats.isEmpty, "formats")
    arkitRequire(ARWorldTrackingConfiguration.recommendedVideoFormatFor4KResolution == nil, "4K")
    arkitRequire(
        ARWorldTrackingConfiguration.recommendedVideoFormatForHighResolutionFrameCapturing == nil,
        "hi-res format"
    )
    arkitRequire(!ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentation), "semantics")
    arkitRequire(!ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh), "reconstruction")
    arkitRequire(!ARWorldTrackingConfiguration.supportsAppClipCodeTracking, "app clip")
    arkitRequire(!ARWorldTrackingConfiguration.supportsUserFaceTracking, "user face")
    arkitRequire(ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces == 0, "tracked faces")
    arkitRequire(!ARFaceTrackingConfiguration.supportsWorldTracking, "face world")
    arkitRequire(!ARBodyTrackingConfiguration.supportsAppClipCodeTracking, "body app clip")
    arkitRequire(!ARGeoTrackingConfiguration.supportsAppClipCodeTracking, "geo app clip")
    arkitRequire(ARConfiguration.configurableCaptureDeviceForPrimaryCamera == nil, "capture device")
}

func testWorldTrackingConfigurationCopy() {
    let world = ARWorldTrackingConfiguration()
    world.planeDetection = [.horizontal, .vertical]
    world.isLightEstimationEnabled = true
    world.providesAudioData = true
    world.videoHDRAllowed = true
    world.videoFormat = .unsupportedPlaceholder
    world.worldAlignment = .gravityAndHeading
    world.appClipCodeTrackingEnabled = true
    world.isAutoFocusEnabled = false
    world.automaticImageScaleEstimationEnabled = true
    world.isCollaborationEnabled = true
    world.maximumNumberOfTrackedImages = 2
    world.userFaceTrackingEnabled = true
    world.wantsHDREnvironmentTextures = true
    world.detectionImages = []
    world.detectionObjects = []
    world.initialWorldMap = ARWorldMap()
    world.sceneReconstruction = [.mesh]
    world.frameSemantics = [.bodyDetection]
    world.environmentTexturing = .manual
    let copy = world.copy() as! ARWorldTrackingConfiguration
    arkitRequire(copy !== world, "copy identity")
    arkitRequire(copy.planeDetection == world.planeDetection, "planes")
    arkitRequire(copy.isCollaborationEnabled, "collaboration")
    arkitRequire(copy.providesAudioData, "audio")
    arkitRequire(copy.videoHDRAllowed, "hdr")
    arkitRequire(copy.worldAlignment == .gravityAndHeading, "alignment")
    arkitRequire(copy.isLightEstimationEnabled, "light")
    arkitRequire(copy.appClipCodeTrackingEnabled, "app clip")
    arkitRequire(!copy.isAutoFocusEnabled, "autofocus")
    arkitRequire(copy.automaticImageScaleEstimationEnabled, "scale")
    arkitRequire(copy.maximumNumberOfTrackedImages == 2, "tracked images")
    arkitRequire(copy.userFaceTrackingEnabled, "user face")
    arkitRequire(copy.wantsHDREnvironmentTextures, "hdr env")
    arkitRequire(copy.environmentTexturing == .manual, "texturing")
    arkitRequire(copy.sceneReconstruction.contains(.mesh), "reconstruction")
    arkitRequire(copy.frameSemantics.contains(.bodyDetection), "semantics")
    arkitRequire(copy.initialWorldMap != nil, "world map")
}

func testOtherConfigurationCopies() {
    let face = ARFaceTrackingConfiguration()
    face.maximumNumberOfTrackedFaces = 2
    face.isWorldTrackingEnabled = true
    arkitRequire((face.copy() as! ARFaceTrackingConfiguration).maximumNumberOfTrackedFaces == 2, "face")
    arkitRequire((face.copy() as! ARFaceTrackingConfiguration).isWorldTrackingEnabled, "face world")

    let image = ARImageTrackingConfiguration()
    image.maximumNumberOfTrackedImages = 4
    image.isAutoFocusEnabled = false
    image.trackingImages = []
    arkitRequire((image.copy() as! ARImageTrackingConfiguration).maximumNumberOfTrackedImages == 4, "image")

    let body = ARBodyTrackingConfiguration()
    body.automaticSkeletonScaleEstimationEnabled = true
    body.planeDetection = [.vertical]
    body.appClipCodeTrackingEnabled = true
    body.isAutoFocusEnabled = false
    body.automaticImageScaleEstimationEnabled = true
    body.detectionImages = []
    body.environmentTexturing = .automatic
    body.initialWorldMap = ARWorldMap()
    body.maximumNumberOfTrackedImages = 1
    body.wantsHDREnvironmentTextures = true
    let bodyCopy = body.copy() as! ARBodyTrackingConfiguration
    arkitRequire(bodyCopy.automaticSkeletonScaleEstimationEnabled, "body skeleton scale")
    arkitRequire(bodyCopy.planeDetection.contains(.vertical), "body planes")

    let geo = ARGeoTrackingConfiguration()
    geo.maximumNumberOfTrackedImages = 3
    geo.appClipCodeTrackingEnabled = true
    geo.automaticImageScaleEstimationEnabled = true
    geo.detectionImages = []
    geo.detectionObjects = []
    geo.environmentTexturing = .none
    geo.planeDetection = [.horizontal]
    geo.wantsHDREnvironmentTextures = true
    arkitRequire((geo.copy() as! ARGeoTrackingConfiguration).maximumNumberOfTrackedImages == 3, "geo")

    let positional = ARPositionalTrackingConfiguration()
    positional.planeDetection = [.horizontal]
    positional.initialWorldMap = ARWorldMap()
    arkitRequire(!(positional.copy() as! ARPositionalTrackingConfiguration).planeDetection.isEmpty, "positional")

    let objectScan = ARObjectScanningConfiguration()
    objectScan.planeDetection = [.vertical]
    objectScan.isAutoFocusEnabled = false
    arkitRequire((objectScan.copy() as! ARObjectScanningConfiguration).planeDetection.contains(.vertical), "object")

    let orientation = AROrientationTrackingConfiguration()
    orientation.isAutoFocusEnabled = false
    arkitRequire(!(orientation.copy() as! AROrientationTrackingConfiguration).isAutoFocusEnabled, "orientation")
}

func testVideoFormatPlaceholder() {
    let format = ARConfiguration.VideoFormat.unsupportedPlaceholder
    arkitRequire(format.framesPerSecond == 0, "fps")
    arkitRequire(format.imageResolution == .zero, "resolution")
    arkitRequire(!format.isRecommendedForHighResolutionFrameCapturing, "hi-res flag")
    arkitRequire(!format.isVideoHDRSupported, "hdr flag")
    _ = format.captureDevicePosition
    _ = format.captureDeviceType
    _ = format.defaultColorSpace
    _ = format.defaultPhotoSettings
}

func testConfigurationSupportedWithHook() {
    ARKitTestHook.removeSimulatedDevice()
    ARKitTestHook.installSimulatedDevice()
    defer { ARKitTestHook.removeSimulatedDevice() }
    arkitRequire(ARConfiguration.isSupported, "base")
    arkitRequire(ARWorldTrackingConfiguration.isSupported, "world")
    arkitRequire(ARFaceTrackingConfiguration.isSupported, "face")
    arkitRequire(ARImageTrackingConfiguration.isSupported, "image")
    arkitRequire(ARBodyTrackingConfiguration.isSupported, "body")
    arkitRequire(ARGeoTrackingConfiguration.isSupported, "geo")
    arkitRequire(ARPositionalTrackingConfiguration.isSupported, "positional")
    arkitRequire(AROrientationTrackingConfiguration.isSupported, "orientation")
    arkitRequire(ARObjectScanningConfiguration.isSupported, "object")
    arkitRequire(ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces == 1, "tracked faces")
    arkitRequire(ARConfiguration.supportedVideoFormats.isEmpty, "formats stay empty")
}
