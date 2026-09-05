import Foundation

open class ARConfiguration: NSObject, NSCopying {
    public struct FrameSemantics: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let personSegmentation = FrameSemantics(rawValue: 1 << 0)
        public static let personSegmentationWithDepth = FrameSemantics(rawValue: 1 << 1)
        public static let bodyDetection = FrameSemantics(rawValue: 1 << 2)
        public static let sceneDepth = FrameSemantics(rawValue: 1 << 3)
        public static let smoothedSceneDepth = FrameSemantics(rawValue: 1 << 4)
    }

    public struct SceneReconstruction: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let mesh = SceneReconstruction(rawValue: 1 << 0)
        public static let meshWithClassification = SceneReconstruction(rawValue: 1 << 1)
    }

    public enum WorldAlignment: Int, Hashable, Sendable {
        case gravity = 0
        case gravityAndHeading = 1
        case camera = 2
    }

    open class VideoFormat: NSObject {
        public var framesPerSecond: Int { _framesPerSecond }
        public var imageResolution: CGSize { _imageResolution }
        public var isRecommendedForHighResolutionFrameCapturing: Bool {
            _isRecommendedForHighResolutionFrameCapturing
        }
        public var isVideoHDRSupported: Bool { _isVideoHDRSupported }

        private let _framesPerSecond: Int
        private let _imageResolution: CGSize
        private let _isRecommendedForHighResolutionFrameCapturing: Bool
        private let _isVideoHDRSupported: Bool

        init(
            framesPerSecond: Int,
            imageResolution: CGSize,
            isRecommendedForHighResolutionFrameCapturing: Bool,
            isVideoHDRSupported: Bool
        ) {
            self._framesPerSecond = framesPerSecond
            self._imageResolution = imageResolution
            self._isRecommendedForHighResolutionFrameCapturing = isRecommendedForHighResolutionFrameCapturing
            self._isVideoHDRSupported = isVideoHDRSupported
            super.init()
        }

        public static let unsupportedPlaceholder = VideoFormat(
            framesPerSecond: 0,
            imageResolution: .zero,
            isRecommendedForHighResolutionFrameCapturing: false,
            isVideoHDRSupported: false
        )

        public var captureDevicePosition: AVCaptureDevice.Position { .unspecified }
        public var captureDeviceType: AVCaptureDevice.DeviceType { .builtInWideAngleCamera }
        public var defaultColorSpace: AVCaptureColorSpace { .sRGB }
        public var defaultPhotoSettings: AVCapturePhotoSettings { AVCapturePhotoSettings() }
    }

    public class var isSupported: Bool { ARKitTestHook.isSimulatedDeviceInstalled }

    public class var supportedVideoFormats: [VideoFormat] { [] }

    public class var recommendedVideoFormatFor4KResolution: VideoFormat? { nil }

    public class var recommendedVideoFormatForHighResolutionFrameCapturing: VideoFormat? { nil }

    public class func supportsFrameSemantics(_ frameSemantics: FrameSemantics) -> Bool {
        _ = frameSemantics
        return false
    }

    public var frameSemantics: FrameSemantics = []
    public var isLightEstimationEnabled: Bool = false
    public var providesAudioData: Bool = false
    public var videoFormat: VideoFormat = .unsupportedPlaceholder
    public var videoHDRAllowed: Bool = false
    public var worldAlignment: WorldAlignment = .gravity

    public class var configurableCaptureDeviceForPrimaryCamera: AVCaptureDevice? { nil }

    public required override init() {
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = type(of: self).init()
        copy.frameSemantics = frameSemantics
        copy.isLightEstimationEnabled = isLightEstimationEnabled
        copy.providesAudioData = providesAudioData
        copy.videoFormat = videoFormat
        copy.videoHDRAllowed = videoHDRAllowed
        copy.worldAlignment = worldAlignment
        return copy
    }
}

open class ARWorldTrackingConfiguration: ARConfiguration {
    public enum EnvironmentTexturing: Int, Hashable, Sendable {
        case none = 0
        case manual = 1
        case automatic = 2
    }

    public struct PlaneDetection: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let horizontal = PlaneDetection(rawValue: 1 << 0)
        public static let vertical = PlaneDetection(rawValue: 1 << 1)
    }

    public override class var isSupported: Bool { ARKitTestHook.isSimulatedDeviceInstalled }

    public class var supportsAppClipCodeTracking: Bool { false }

    public class var supportsUserFaceTracking: Bool { false }

    public class func supportsSceneReconstruction(
        _ sceneReconstruction: ARConfiguration.SceneReconstruction
    ) -> Bool {
        _ = sceneReconstruction
        return false
    }

    public var appClipCodeTrackingEnabled: Bool = false
    public var isAutoFocusEnabled: Bool = true
    public var automaticImageScaleEstimationEnabled: Bool = false
    public var isCollaborationEnabled: Bool = false
    public var detectionImages: Set<ARReferenceImage>! = []
    public var detectionObjects: Set<ARReferenceObject> = []
    public var environmentTexturing: EnvironmentTexturing = .none
    public var initialWorldMap: ARWorldMap?
    public var maximumNumberOfTrackedImages: Int = 0
    public var planeDetection: PlaneDetection = []
    public var sceneReconstruction: ARConfiguration.SceneReconstruction = []
    public var userFaceTrackingEnabled: Bool = false
    public var wantsHDREnvironmentTextures: Bool = false

    public required init() {
        super.init()
    }

    public override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! ARWorldTrackingConfiguration
        copy.appClipCodeTrackingEnabled = appClipCodeTrackingEnabled
        copy.isAutoFocusEnabled = isAutoFocusEnabled
        copy.automaticImageScaleEstimationEnabled = automaticImageScaleEstimationEnabled
        copy.isCollaborationEnabled = isCollaborationEnabled
        copy.detectionImages = detectionImages
        copy.detectionObjects = detectionObjects
        copy.environmentTexturing = environmentTexturing
        copy.initialWorldMap = initialWorldMap
        copy.maximumNumberOfTrackedImages = maximumNumberOfTrackedImages
        copy.planeDetection = planeDetection
        copy.sceneReconstruction = sceneReconstruction
        copy.userFaceTrackingEnabled = userFaceTrackingEnabled
        copy.wantsHDREnvironmentTextures = wantsHDREnvironmentTextures
        return copy
    }
}

open class AROrientationTrackingConfiguration: ARConfiguration {
    public override class var isSupported: Bool { ARKitTestHook.isSimulatedDeviceInstalled }
    public var isAutoFocusEnabled: Bool = true

    public required init() {
        super.init()
    }

    public override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! AROrientationTrackingConfiguration
        copy.isAutoFocusEnabled = isAutoFocusEnabled
        return copy
    }
}

open class ARFaceTrackingConfiguration: ARConfiguration {
    public override class var isSupported: Bool { ARKitTestHook.isSimulatedDeviceInstalled }
    public class var supportedNumberOfTrackedFaces: Int { ARKitTestHook.isSimulatedDeviceInstalled ? 1 : 0 }
    public class var supportsWorldTracking: Bool { false }
    public var maximumNumberOfTrackedFaces: Int = 1
    public var isWorldTrackingEnabled: Bool = false

    public required init() {
        super.init()
    }

    public override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! ARFaceTrackingConfiguration
        copy.maximumNumberOfTrackedFaces = maximumNumberOfTrackedFaces
        copy.isWorldTrackingEnabled = isWorldTrackingEnabled
        return copy
    }
}

open class ARImageTrackingConfiguration: ARConfiguration {
    public override class var isSupported: Bool { ARKitTestHook.isSimulatedDeviceInstalled }
    public var isAutoFocusEnabled: Bool = true
    public var maximumNumberOfTrackedImages: Int = 1
    public var trackingImages: Set<ARReferenceImage> = []

    public required init() {
        super.init()
    }

    public override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! ARImageTrackingConfiguration
        copy.isAutoFocusEnabled = isAutoFocusEnabled
        copy.maximumNumberOfTrackedImages = maximumNumberOfTrackedImages
        copy.trackingImages = trackingImages
        return copy
    }
}

open class ARObjectScanningConfiguration: ARConfiguration {
    public override class var isSupported: Bool { ARKitTestHook.isSimulatedDeviceInstalled }
    public var isAutoFocusEnabled: Bool = true
    public var planeDetection: ARWorldTrackingConfiguration.PlaneDetection = []

    public required init() {
        super.init()
    }

    public override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! ARObjectScanningConfiguration
        copy.isAutoFocusEnabled = isAutoFocusEnabled
        copy.planeDetection = planeDetection
        return copy
    }
}

open class ARBodyTrackingConfiguration: ARConfiguration {
    public override class var isSupported: Bool { ARKitTestHook.isSimulatedDeviceInstalled }
    public class var supportsAppClipCodeTracking: Bool { false }
    public var appClipCodeTrackingEnabled: Bool = false
    public var isAutoFocusEnabled: Bool = true
    public var automaticImageScaleEstimationEnabled: Bool = false
    public var automaticSkeletonScaleEstimationEnabled: Bool = false
    public var detectionImages: Set<ARReferenceImage> = []
    public var environmentTexturing: ARWorldTrackingConfiguration.EnvironmentTexturing = .none
    public var initialWorldMap: ARWorldMap?
    public var maximumNumberOfTrackedImages: Int = 0
    public var planeDetection: ARWorldTrackingConfiguration.PlaneDetection = []
    public var wantsHDREnvironmentTextures: Bool = false

    public required init() {
        super.init()
    }

    public override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! ARBodyTrackingConfiguration
        copy.appClipCodeTrackingEnabled = appClipCodeTrackingEnabled
        copy.isAutoFocusEnabled = isAutoFocusEnabled
        copy.automaticImageScaleEstimationEnabled = automaticImageScaleEstimationEnabled
        copy.automaticSkeletonScaleEstimationEnabled = automaticSkeletonScaleEstimationEnabled
        copy.detectionImages = detectionImages
        copy.environmentTexturing = environmentTexturing
        copy.initialWorldMap = initialWorldMap
        copy.maximumNumberOfTrackedImages = maximumNumberOfTrackedImages
        copy.planeDetection = planeDetection
        copy.wantsHDREnvironmentTextures = wantsHDREnvironmentTextures
        return copy
    }
}

open class ARPositionalTrackingConfiguration: ARConfiguration {
    public override class var isSupported: Bool { ARKitTestHook.isSimulatedDeviceInstalled }
    public var initialWorldMap: ARWorldMap?
    public var planeDetection: ARWorldTrackingConfiguration.PlaneDetection = []

    public required init() {
        super.init()
    }

    public override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! ARPositionalTrackingConfiguration
        copy.initialWorldMap = initialWorldMap
        copy.planeDetection = planeDetection
        return copy
    }
}

open class ARGeoTrackingConfiguration: ARConfiguration {
    public override class var isSupported: Bool { ARKitTestHook.isSimulatedDeviceInstalled }
    public class var supportsAppClipCodeTracking: Bool { false }

    public class func checkAvailability(
        completionHandler: @escaping (Bool, (any Error)?) -> Void
    ) {
        completionHandler(false, ARError(.geoTrackingNotAvailableAtLocation))
    }

    public class func checkAvailability(
        at coordinate: CLLocationCoordinate2D,
        completionHandler: @escaping (Bool, (any Error)?) -> Void
    ) {
        _ = coordinate
        completionHandler(false, ARError(.geoTrackingNotAvailableAtLocation))
    }

    public var appClipCodeTrackingEnabled: Bool = false
    public var automaticImageScaleEstimationEnabled: Bool = false
    public var detectionImages: Set<ARReferenceImage>! = []
    public var detectionObjects: Set<ARReferenceObject> = []
    public var environmentTexturing: ARWorldTrackingConfiguration.EnvironmentTexturing = .none
    public var maximumNumberOfTrackedImages: Int = 0
    public var planeDetection: ARWorldTrackingConfiguration.PlaneDetection = []
    public var wantsHDREnvironmentTextures: Bool = false

    public required init() {
        super.init()
    }

    public override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! ARGeoTrackingConfiguration
        copy.appClipCodeTrackingEnabled = appClipCodeTrackingEnabled
        copy.automaticImageScaleEstimationEnabled = automaticImageScaleEstimationEnabled
        copy.detectionImages = detectionImages
        copy.detectionObjects = detectionObjects
        copy.environmentTexturing = environmentTexturing
        copy.maximumNumberOfTrackedImages = maximumNumberOfTrackedImages
        copy.planeDetection = planeDetection
        copy.wantsHDREnvironmentTextures = wantsHDREnvironmentTextures
        return copy
    }
}
