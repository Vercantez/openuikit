import Foundation

open class AVCaptureAudioChannel: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var averagePowerLevel: Float { 0 }
  public var peakHoldLevel: Float { 0 }
}

open class AVCaptureAudioDataOutput: AVCaptureOutput, @unchecked Sendable {
  public override init() { super.init() }
  public func setSampleBufferDelegate(_ sampleBufferDelegate: (any AVCaptureAudioDataOutputSampleBufferDelegate)?, queue sampleBufferCallbackQueue: DispatchQueue?) {}
  public var sampleBufferDelegate: (any AVCaptureAudioDataOutputSampleBufferDelegate)? { nil }
  public var sampleBufferCallbackQueue: DispatchQueue? { nil }
  public var spatialAudioChannelLayoutTag: AudioChannelLayoutTag {
      get { 0 }
      set { _ = newValue }
    }
  public func recommendedAudioSettingsForAssetWriter(writingTo outputFileType: AVFileType) -> [String : Any]? { nil }
}

public protocol AVCaptureAudioDataOutputSampleBufferDelegate : AnyObject {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
}

open class AVCaptureAutoExposureBracketedStillImageSettings: AVCaptureBracketedStillImageSettings, @unchecked Sendable {
  public override init() { super.init() }
  public var exposureTargetBias: Float { 0 }
}

open class AVCaptureBracketedStillImageSettings: NSObject, @unchecked Sendable {
  public override init() { super.init() }
}

public enum AVCaptureCameraLensSmudgeDetectionStatus: Int, Hashable, Sendable {
  case disabled = 0
  case smudgeNotDetected = 1
  case smudged = 2
  case unknown = 3
}

public enum AVCaptureColorSpace: Int, Hashable, Sendable {
  case sRGB = 0
  case P3_D65 = 1
  case HLG_BT2020 = 2
  case appleLog = 3
  case appleLog2 = 4
}

open class AVCaptureConnection: NSObject, @unchecked Sendable {
  private var storedPorts: [AVCaptureInput.Port] = []
  private var storedOutput: AVCaptureOutput?
  private var storedEnabled = true
  public override init() { super.init() }
  public convenience init(inputPorts ports: [AVCaptureInput.Port], output: AVCaptureOutput) {
    self.init()
    storedPorts = ports
    storedOutput = output
  }
  public var inputPorts: [AVCaptureInput.Port] { storedPorts }
  public var output: AVCaptureOutput? { storedOutput }
  public var isEnabled: Bool {
      get { storedEnabled }
      set { storedEnabled = newValue }
    }
  public var isActive: Bool { false }
  public var audioChannels: [AVCaptureAudioChannel] { [] }
  public var isVideoMirroringSupported: Bool { false }
  public var isVideoMirrored: Bool {
      get { false }
      set { _ = newValue }
    }
  public var automaticallyAdjustsVideoMirroring: Bool {
      get { false }
      set { _ = newValue }
    }
  public func isVideoRotationAngleSupported(_ videoRotationAngle: CGFloat) -> Bool { false }
  public var videoRotationAngle: CGFloat {
      get { 0 }
      set { _ = newValue }
    }
  public var isVideoOrientationSupported: Bool { false }
  public var videoOrientation: AVCaptureVideoOrientation {
      get { AVCaptureVideoOrientation(rawValue: 0)! }
      set { _ = newValue }
    }
  public var videoMaxScaleAndCropFactor: CGFloat { 0 }
  public var videoScaleAndCropFactor: CGFloat {
      get { 0 }
      set { _ = newValue }
    }
  public var preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode {
      get { AVCaptureVideoStabilizationMode(rawValue: 0)! }
      set { _ = newValue }
    }
  public var activeVideoStabilizationMode: AVCaptureVideoStabilizationMode { AVCaptureVideoStabilizationMode(rawValue: 0)! }
  public var isVideoStabilizationSupported: Bool { false }
  public var isVideoStabilizationEnabled: Bool { false }
  public var enablesVideoStabilizationWhenAvailable: Bool {
      get { false }
      set { _ = newValue }
    }
  public var isCameraIntrinsicMatrixDeliverySupported: Bool { false }
  public var isCameraIntrinsicMatrixDeliveryEnabled: Bool {
      get { false }
      set { _ = newValue }
    }
}

open class AVCaptureControl: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var isEnabled: Bool {
      get { false }
      set { _ = newValue }
    }
}

open class AVCaptureDataOutputSynchronizer: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(dataOutputs: [AVCaptureOutput]) { self.init() }
  public var dataOutputs: [AVCaptureOutput] { [] }
  public func setDelegate(_ delegate: (any AVCaptureDataOutputSynchronizerDelegate)?, queue delegateCallbackQueue: DispatchQueue?) {}
  public var delegate: (any AVCaptureDataOutputSynchronizerDelegate)? { nil }
  public var delegateCallbackQueue: DispatchQueue? { nil }
}

public protocol AVCaptureDataOutputSynchronizerDelegate : AnyObject {
  func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection)
}

open class AVCaptureDeferredPhotoProxy: AVCapturePhoto, @unchecked Sendable {
  public override init() { super.init() }
}

open class AVCaptureDepthDataOutput: AVCaptureOutput, @unchecked Sendable {
  public override init() { super.init() }
  public func setDelegate(_ delegate: (any AVCaptureDepthDataOutputDelegate)?, callbackQueue: DispatchQueue?) {}
  public var delegate: (any AVCaptureDepthDataOutputDelegate)? { nil }
  public var delegateCallbackQueue: DispatchQueue? { nil }
  public var alwaysDiscardsLateDepthData: Bool {
      get { false }
      set { _ = newValue }
    }
  public var isFilteringEnabled: Bool {
      get { false }
      set { _ = newValue }
    }
}

public protocol AVCaptureDepthDataOutputDelegate : AnyObject {
  func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection)
  func depthDataOutput(_ output: AVCaptureDepthDataOutput, didDrop depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection, reason: AVCaptureOutput.DataDroppedReason)
}

open class AVCaptureDevice: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public struct AspectRatio: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
    public static let ratio1x1 = AspectRatio(rawValue: "ratio1x1")
    public static let ratio16x9 = AspectRatio(rawValue: "ratio16x9")
    public static let ratio9x16 = AspectRatio(rawValue: "ratio9x16")
    public static let ratio4x3 = AspectRatio(rawValue: "ratio4x3")
    public static let ratio3x4 = AspectRatio(rawValue: "ratio3x4")
  }
  public enum AutoFocusRangeRestriction: Int, Hashable, Sendable {
    case none = 0
    case near = 1
    case far = 2
  }
  public enum CenterStageControlMode: Int, Hashable, Sendable {
    case user = 0
    case app = 1
    case cooperative = 2
  }
  public enum CinematicVideoFocusMode: Int, Hashable, Sendable {
    case none = 0
    case strong = 1
    case weak = 2
  }
  public struct DeviceType: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
    public static let external = DeviceType(rawValue: "external")
    public static let microphone = DeviceType(rawValue: "microphone")
    public static let builtInWideAngleCamera = DeviceType(rawValue: "builtInWideAngleCamera")
    public static let builtInTelephotoCamera = DeviceType(rawValue: "builtInTelephotoCamera")
    public static let builtInUltraWideCamera = DeviceType(rawValue: "builtInUltraWideCamera")
    public static let builtInDualCamera = DeviceType(rawValue: "builtInDualCamera")
    public static let builtInDualWideCamera = DeviceType(rawValue: "builtInDualWideCamera")
    public static let builtInTripleCamera = DeviceType(rawValue: "builtInTripleCamera")
    public static let builtInTrueDepthCamera = DeviceType(rawValue: "builtInTrueDepthCamera")
    public static let builtInLiDARDepthCamera = DeviceType(rawValue: "builtInLiDARDepthCamera")
    public static let continuityCamera = DeviceType(rawValue: "continuityCamera")
    public static let builtInDuoCamera = DeviceType(rawValue: "builtInDuoCamera")
    public static let builtInMicrophone = DeviceType(rawValue: "builtInMicrophone")
  }
  open class DiscoverySession: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public convenience init(deviceTypes: [AVCaptureDevice.DeviceType], mediaType: AVMediaType?, position: AVCaptureDevice.Position) { self.init() }
    public var devices: [AVCaptureDevice] { [] }
    public var supportedMultiCamDeviceSets: [Set<AVCaptureDevice>] { [] }
  }
  public enum ExposureMode: Int, Hashable, Sendable {
    case locked = 0
    case autoExpose = 1
    case continuousAutoExposure = 2
    case custom = 3
  }
  public enum FlashMode: Int, Hashable, Sendable {
    case off = 0
    case on = 1
    case auto = 2
  }
  public enum FocusMode: Int, Hashable, Sendable {
    case locked = 0
    case autoFocus = 1
    case continuousAutoFocus = 2
  }
  open class Format: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public enum AutoFocusSystem: Int, Hashable, Sendable {
      case none = 0
      case contrastDetection = 1
      case phaseDetection = 2
    }
    public var supportedColorSpaces: [AVCaptureColorSpace] { [] }
    public var supportedMaxPhotoDimensions: [CMVideoDimensions] { [] }
    public var secondaryNativeResolutionZoomFactors: [CGFloat] { [] }
    public var supportedVideoZoomFactorsForDepthDataDelivery: [CGFloat] { [] }
    public var supportedVideoZoomRangesForDepthDataDelivery: [ClosedRange<CGFloat>] { [] }
    public var systemRecommendedVideoZoomRange: ClosedRange<CGFloat>? { nil }
    public var systemRecommendedExposureBiasRange: ClosedRange<Float>? { nil }
    public var isPortraitEffectsMatteStillImageDeliverySupported: Bool { false }
    public var isMultiCamSupported: Bool { false }
    public var isSpatialVideoCaptureSupported: Bool { false }
    public var geometricDistortionCorrectedVideoFieldOfView: Float { 0 }
    public var isCenterStageSupported: Bool { false }
    public var videoMinZoomFactorForCenterStage: CGFloat { 0 }
    public var videoMaxZoomFactorForCenterStage: CGFloat { 0 }
    public var videoFrameRateRangeForCenterStage: AVFrameRateRange? { nil }
    public var isPortraitEffectSupported: Bool { false }
    public var videoFrameRateRangeForPortraitEffect: AVFrameRateRange? { nil }
    public var isStudioLightSupported: Bool { false }
    public var videoFrameRateRangeForStudioLight: AVFrameRateRange? { nil }
    public var reactionEffectsSupported: Bool { false }
    public var videoFrameRateRangeForReactionEffectsInProgress: AVFrameRateRange? { nil }
    public var isBackgroundReplacementSupported: Bool { false }
    public var videoFrameRateRangeForBackgroundReplacement: AVFrameRateRange? { nil }
    public var isCinematicVideoCaptureSupported: Bool { false }
    public var defaultSimulatedAperture: Float { 0 }
    public var minSimulatedAperture: Float { 0 }
    public var maxSimulatedAperture: Float { 0 }
    public var videoMinZoomFactorForCinematicVideo: CGFloat { 0 }
    public var videoMaxZoomFactorForCinematicVideo: CGFloat { 0 }
    public var videoFrameRateRangeForCinematicVideo: AVFrameRateRange? { nil }
    public var supportedDynamicAspectRatios: [AVCaptureDevice.AspectRatio] { [] }
    public func videoFieldOfView(for aspectRatio: AVCaptureDevice.AspectRatio, geometricDistortionCorrected: Bool) -> Float { 0 }
    public var isSmartFramingSupported: Bool { false }
    public var isCameraLensSmudgeDetectionSupported: Bool { false }
    public var mediaType: AVMediaType { AVMediaType(rawValue: "") }
    public var formatDescription: CMFormatDescription { CMFormatDescription() }
    public var videoSupportedFrameRateRanges: [AVFrameRateRange] { [] }
    public var videoFieldOfView: Float { 0 }
    public var isVideoBinned: Bool { false }
    public func isVideoStabilizationModeSupported(_ videoStabilizationMode: AVCaptureVideoStabilizationMode) -> Bool { false }
    public var isVideoStabilizationSupported: Bool { false }
    public var videoMaxZoomFactor: CGFloat { 0 }
    public var videoZoomFactorUpscaleThreshold: CGFloat { 0 }
    public var minExposureDuration: CMTime { .zero }
    public var maxExposureDuration: CMTime { .zero }
    public var minISO: Float { 0 }
    public var maxISO: Float { 0 }
    public var isGlobalToneMappingSupported: Bool { false }
    public var isVideoHDRSupported: Bool { false }
    public var highResolutionStillImageDimensions: CMVideoDimensions { CMVideoDimensions(width: 0, height: 0) }
    public var isHighPhotoQualitySupported: Bool { false }
    public var isHighestPhotoQualitySupported: Bool { false }
    public var autoFocusSystem: AVCaptureDevice.Format.AutoFocusSystem { AVCaptureDevice.Format.AutoFocusSystem(rawValue: 0)! }
    public var videoMinZoomFactorForDepthDataDelivery: CGFloat { 0 }
    public var videoMaxZoomFactorForDepthDataDelivery: CGFloat { 0 }
    public var zoomFactorsOutsideOfVideoZoomRangesForDepthDeliverySupported: Bool { false }
    public var supportedDepthDataFormats: [AVCaptureDevice.Format] { [] }
    public var unsupportedCaptureOutputClasses: [AnyClass] { [] }
    public var isAutoVideoFrameRateSupported: Bool { false }
  }
  public enum LensStabilizationStatus: Int, Hashable, Sendable {
    case unsupported = 0
    case off = 1
    case active = 2
    case outOfRange = 3
    case unavailable = 4
  }
  public enum MicrophoneMode: Int, Hashable, Sendable {
    case standard = 0
    case wideSpectrum = 1
    case voiceIsolation = 2
  }
  public enum Position: Int, Hashable, Sendable {
    case unspecified = 0
    case back = 1
    case front = 2
  }
  public struct PrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let videoZoomChanged = PrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions(rawValue: 1 << 0)
    public static let focusModeChanged = PrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions(rawValue: 1 << 1)
    public static let exposureModeChanged = PrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions(rawValue: 1 << 2)
  }
  public enum PrimaryConstituentDeviceSwitchingBehavior: Int, Hashable, Sendable {
    case unsupported = 0
    case auto = 1
    case restricted = 2
    case locked = 3
  }
  open class RotationCoordinator: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    weak var storedDevice: AVCaptureDevice?
    weak var storedPreviewLayer: CALayer?
    public convenience init(device: AVCaptureDevice, previewLayer: CALayer?) {
      self.init()
      storedDevice = device
      storedPreviewLayer = previewLayer
    }
    public var device: AVCaptureDevice? { storedDevice }
    public var previewLayer: CALayer? { storedPreviewLayer }
    public var videoRotationAngleForHorizonLevelPreview: CGFloat { 0 }
    public var videoRotationAngleForHorizonLevelCapture: CGFloat { 0 }
  }
  open class SystemPressureState: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public struct Factors: OptionSet, Hashable, Sendable {
      public let rawValue: UInt
      public init(rawValue: UInt) { self.rawValue = rawValue }
      public static let systemTemperature = Factors(rawValue: 1 << 0)
      public static let peakPower = Factors(rawValue: 1 << 1)
      public static let depthModuleTemperature = Factors(rawValue: 1 << 2)
      public static let cameraTemperature = Factors(rawValue: 1 << 3)
    }
    public struct Level: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
      public let rawValue: String
      public init(rawValue: String) { self.rawValue = rawValue }
      public init(stringLiteral value: String) { self.init(rawValue: value) }
      public static let nominal = Level(rawValue: "nominal")
      public static let fair = Level(rawValue: "fair")
      public static let serious = Level(rawValue: "serious")
      public static let critical = Level(rawValue: "critical")
      public static let shutdown = Level(rawValue: "shutdown")
    }
    public var level: AVCaptureDevice.SystemPressureState.Level { AVCaptureDevice.SystemPressureState.Level(rawValue: "") }
    public var factors: AVCaptureDevice.SystemPressureState.Factors { AVCaptureDevice.SystemPressureState.Factors(rawValue: 0) }
  }
  public enum SystemUserInterface: Int, Hashable, Sendable {
    case videoEffects = 0
    case microphoneModes = 1
  }
  public enum TorchMode: Int, Hashable, Sendable {
    case off = 0
    case on = 1
    case auto = 2
  }
  public struct WhiteBalanceChromaticityValues: Sendable {
    public init() {}
    public init(x: Float, y: Float) {
      self.x = x
      self.y = y
    }
    public var x: Float = 0
    public var y: Float = 0
  }
  public struct WhiteBalanceGains: Sendable {
    public init() {}
    public init(redGain: Float, greenGain: Float, blueGain: Float) {
      self.redGain = redGain
      self.greenGain = greenGain
      self.blueGain = blueGain
    }
    public var redGain: Float = 0
    public var greenGain: Float = 0
    public var blueGain: Float = 0
  }
  public enum WhiteBalanceMode: Int, Hashable, Sendable {
    case locked = 0
    case autoWhiteBalance = 1
    case continuousAutoWhiteBalance = 2
  }
  public struct WhiteBalanceTemperatureAndTintValues: Sendable {
    public init() {}
    public static let tungsten: AVCaptureDevice.WhiteBalanceTemperatureAndTintValues = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: 3200, tint: 0)
    public static let fluorescent: AVCaptureDevice.WhiteBalanceTemperatureAndTintValues = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: 4000, tint: 0)
    public static let daylight: AVCaptureDevice.WhiteBalanceTemperatureAndTintValues = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: 6500, tint: 0)
    public static let cloudy: AVCaptureDevice.WhiteBalanceTemperatureAndTintValues = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: 7500, tint: 0)
    public static let shadow: AVCaptureDevice.WhiteBalanceTemperatureAndTintValues = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: 9000, tint: 0)
    public init(temperature: Float, tint: Float) {
      self.temperature = temperature
      self.tint = tint
    }
    public var temperature: Float = 0
    public var tint: Float = 0
  }
  public class func devices() -> [AVCaptureDevice] { [] }
  public class func devices(for mediaType: AVMediaType) -> [AVCaptureDevice] { [] }
  public class func `default`(for mediaType: AVMediaType) -> AVCaptureDevice? { nil }
  public convenience init?(uniqueID deviceUniqueID: String) {
    _ = deviceUniqueID
    return nil
  }
  public var uniqueID: String { "" }
  public var modelID: String { "" }
  public var localizedName: String { "" }
  public var manufacturer: String { "" }
  public func hasMediaType(_ mediaType: AVMediaType) -> Bool { false }
  public func lockForConfiguration() throws {
    throw AVError(.applicationIsNotAuthorizedToUseDevice)
  }
  public func unlockForConfiguration() {}
  public func supportsSessionPreset(_ preset: AVCaptureSession.Preset) -> Bool { false }
  public var isConnected: Bool { false }
  public var isSuspended: Bool { false }
  public var formats: [AVCaptureDevice.Format] { [] }
  public var activeFormat: AVCaptureDevice.Format {
      get { AVCaptureDevice.Format() }
      set { _ = newValue }
    }
  public var activeVideoMinFrameDuration: CMTime {
      get { .zero }
      set { _ = newValue }
    }
  public var activeVideoMaxFrameDuration: CMTime {
      get { .zero }
      set { _ = newValue }
    }
  public var isVideoFrameDurationLocked: Bool { false }
  public var minSupportedLockedVideoFrameDuration: CMTime { .zero }
  public var isFollowingExternalSyncDevice: Bool { false }
  public var minSupportedExternalSyncFrameDuration: CMTime { .zero }
  public var isAutoVideoFrameRateEnabled: Bool {
      get { false }
      set { _ = newValue }
    }
  public var position: AVCaptureDevice.Position { AVCaptureDevice.Position(rawValue: 0)! }
  public var deviceType: AVCaptureDevice.DeviceType { AVCaptureDevice.DeviceType(rawValue: "") }
  public class func `default`(_ deviceType: AVCaptureDevice.DeviceType, for mediaType: AVMediaType?, position: AVCaptureDevice.Position) -> AVCaptureDevice? { nil }
  public class var userPreferredCamera: AVCaptureDevice? {
      get { nil }
      set { _ = newValue }
    }
  public class var systemPreferredCamera: AVCaptureDevice? { nil }
  public var systemPressureState: AVCaptureDevice.SystemPressureState { AVCaptureDevice.SystemPressureState() }
  public var isVirtualDevice: Bool { false }
  public var constituentDevices: [AVCaptureDevice] { [] }
  public var virtualDeviceSwitchOverVideoZoomFactors: [NSNumber] { [] }
  public func setPrimaryConstituentDeviceSwitchingBehavior(_ switchingBehavior: AVCaptureDevice.PrimaryConstituentDeviceSwitchingBehavior, restrictedSwitchingBehaviorConditions: AVCaptureDevice.PrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions) {}
  public var primaryConstituentDeviceSwitchingBehavior: AVCaptureDevice.PrimaryConstituentDeviceSwitchingBehavior { AVCaptureDevice.PrimaryConstituentDeviceSwitchingBehavior(rawValue: 0)! }
  public var primaryConstituentDeviceRestrictedSwitchingBehaviorConditions: AVCaptureDevice.PrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions { AVCaptureDevice.PrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions(rawValue: 0) }
  public var activePrimaryConstituentDeviceSwitchingBehavior: AVCaptureDevice.PrimaryConstituentDeviceSwitchingBehavior { AVCaptureDevice.PrimaryConstituentDeviceSwitchingBehavior(rawValue: 0)! }
  public var activePrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions: AVCaptureDevice.PrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions { AVCaptureDevice.PrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions(rawValue: 0) }
  public var activePrimaryConstituent: AVCaptureDevice? { nil }
  public var supportedFallbackPrimaryConstituentDevices: [AVCaptureDevice] { [] }
  public var fallbackPrimaryConstituentDevices: [AVCaptureDevice] {
      get { [] }
      set { _ = newValue }
    }
  public var hasFlash: Bool { false }
  public var isFlashAvailable: Bool { false }
  public var isFlashActive: Bool { false }
  public func isFlashModeSupported(_ flashMode: AVCaptureDevice.FlashMode) -> Bool { false }
  public var flashMode: AVCaptureDevice.FlashMode {
      get { AVCaptureDevice.FlashMode(rawValue: 0)! }
      set { _ = newValue }
    }
  public var hasTorch: Bool { false }
  public var isTorchAvailable: Bool { false }
  public var isTorchActive: Bool { false }
  public var torchLevel: Float { 0 }
  public func isTorchModeSupported(_ torchMode: AVCaptureDevice.TorchMode) -> Bool { false }
  public var torchMode: AVCaptureDevice.TorchMode {
      get { AVCaptureDevice.TorchMode(rawValue: 0)! }
      set { _ = newValue }
    }
  public func setTorchModeOn(level torchLevel: Float) throws {
    _ = torchLevel
    throw AVError(.torchLevelUnavailable)
  }
  public func isFocusModeSupported(_ focusMode: AVCaptureDevice.FocusMode) -> Bool { false }
  public var isLockingFocusWithCustomLensPositionSupported: Bool { false }
  public var focusMode: AVCaptureDevice.FocusMode {
      get { AVCaptureDevice.FocusMode(rawValue: 0)! }
      set { _ = newValue }
    }
  public var isFocusPointOfInterestSupported: Bool { false }
  public var focusPointOfInterest: CGPoint {
      get { .zero }
      set { _ = newValue }
    }
  public var isFocusRectOfInterestSupported: Bool { false }
  public var minFocusRectOfInterestSize: CGSize { .zero }
  public var focusRectOfInterest: CGRect {
      get { .zero }
      set { _ = newValue }
    }
  public func defaultRectForFocusPoint(ofInterest pointOfInterest: CGPoint) -> CGRect { .zero }
  public var isAdjustingFocus: Bool { false }
  public var isAutoFocusRangeRestrictionSupported: Bool { false }
  public var autoFocusRangeRestriction: AVCaptureDevice.AutoFocusRangeRestriction {
      get { AVCaptureDevice.AutoFocusRangeRestriction(rawValue: 0)! }
      set { _ = newValue }
    }
  public var isSmoothAutoFocusSupported: Bool { false }
  public var isSmoothAutoFocusEnabled: Bool {
      get { false }
      set { _ = newValue }
    }
  public var automaticallyAdjustsFaceDrivenAutoFocusEnabled: Bool {
      get { false }
      set { _ = newValue }
    }
  public var isFaceDrivenAutoFocusEnabled: Bool {
      get { false }
      set { _ = newValue }
    }
  public var lensPosition: Float { 0 }
  public func setFocusModeLocked(lensPosition: Float) async -> CMTime { .zero }
  public var minimumFocusDistance: Int { 0 }
  public func setCinematicVideoTrackingFocus(detectedObjectID: Int, focusMode: AVCaptureDevice.CinematicVideoFocusMode) {}
  public func setCinematicVideoTrackingFocus(at point: CGPoint, focusMode: AVCaptureDevice.CinematicVideoFocusMode) {}
  public func setCinematicVideoFixedFocus(at point: CGPoint, focusMode: AVCaptureDevice.CinematicVideoFocusMode) {}
  public func isExposureModeSupported(_ exposureMode: AVCaptureDevice.ExposureMode) -> Bool { false }
  public var exposureMode: AVCaptureDevice.ExposureMode {
      get { AVCaptureDevice.ExposureMode(rawValue: 0)! }
      set { _ = newValue }
    }
  public var isExposurePointOfInterestSupported: Bool { false }
  public var exposurePointOfInterest: CGPoint {
      get { .zero }
      set { _ = newValue }
    }
  public var isExposureRectOfInterestSupported: Bool { false }
  public var minExposureRectOfInterestSize: CGSize { .zero }
  public var exposureRectOfInterest: CGRect {
      get { .zero }
      set { _ = newValue }
    }
  public func defaultRectForExposurePoint(ofInterest pointOfInterest: CGPoint) -> CGRect { .zero }
  public var automaticallyAdjustsFaceDrivenAutoExposureEnabled: Bool {
      get { false }
      set { _ = newValue }
    }
  public var isFaceDrivenAutoExposureEnabled: Bool {
      get { false }
      set { _ = newValue }
    }
  public var activeMaxExposureDuration: CMTime {
      get { .zero }
      set { _ = newValue }
    }
  public var isAdjustingExposure: Bool { false }
  public var lensAperture: Float { 0 }
  public var exposureDuration: CMTime { .zero }
  public var iso: Float { 0 }
  public func setExposureModeCustom(duration: CMTime, iso ISO: Float) async -> CMTime { .zero }
  public var exposureTargetOffset: Float { 0 }
  public var exposureTargetBias: Float { 0 }
  public var minExposureTargetBias: Float { 0 }
  public var maxExposureTargetBias: Float { 0 }
  public func setExposureTargetBias(_ bias: Float) async -> CMTime { .zero }
  public var isGlobalToneMappingEnabled: Bool {
      get { false }
      set { _ = newValue }
    }
  public func isWhiteBalanceModeSupported(_ whiteBalanceMode: AVCaptureDevice.WhiteBalanceMode) -> Bool { false }
  public var isLockingWhiteBalanceWithCustomDeviceGainsSupported: Bool { false }
  public var whiteBalanceMode: AVCaptureDevice.WhiteBalanceMode {
      get { AVCaptureDevice.WhiteBalanceMode(rawValue: 0)! }
      set { _ = newValue }
    }
  public var isAdjustingWhiteBalance: Bool { false }
  public var deviceWhiteBalanceGains: AVCaptureDevice.WhiteBalanceGains { AVCaptureDevice.WhiteBalanceGains() }
  public var grayWorldDeviceWhiteBalanceGains: AVCaptureDevice.WhiteBalanceGains { AVCaptureDevice.WhiteBalanceGains() }
  public var maxWhiteBalanceGain: Float { 0 }
  public func setWhiteBalanceModeLocked(with whiteBalanceGains: AVCaptureDevice.WhiteBalanceGains) async -> CMTime { .zero }
  public func chromaticityValues(for whiteBalanceGains: AVCaptureDevice.WhiteBalanceGains) -> AVCaptureDevice.WhiteBalanceChromaticityValues { AVCaptureDevice.WhiteBalanceChromaticityValues() }
  public func deviceWhiteBalanceGains(for chromaticityValues: AVCaptureDevice.WhiteBalanceChromaticityValues) -> AVCaptureDevice.WhiteBalanceGains { AVCaptureDevice.WhiteBalanceGains() }
  public func temperatureAndTintValues(for whiteBalanceGains: AVCaptureDevice.WhiteBalanceGains) -> AVCaptureDevice.WhiteBalanceTemperatureAndTintValues { AVCaptureDevice.WhiteBalanceTemperatureAndTintValues() }
  public func deviceWhiteBalanceGains(for tempAndTintValues: AVCaptureDevice.WhiteBalanceTemperatureAndTintValues) -> AVCaptureDevice.WhiteBalanceGains { AVCaptureDevice.WhiteBalanceGains() }
  public var isSubjectAreaChangeMonitoringEnabled: Bool {
      get { false }
      set { _ = newValue }
    }
  public var isLowLightBoostSupported: Bool { false }
  public var isLowLightBoostEnabled: Bool { false }
  public var automaticallyEnablesLowLightBoostWhenAvailable: Bool {
      get { false }
      set { _ = newValue }
    }
  private var storedVideoZoomFactor: CGFloat = 1
  public var videoZoomFactor: CGFloat {
      get { storedVideoZoomFactor }
      set { storedVideoZoomFactor = newValue }
    }
  public func ramp(toVideoZoomFactor factor: CGFloat, withRate rate: Float) {}
  public var isRampingVideoZoom: Bool { false }
  public func cancelVideoZoomRamp() {}
  public var dualCameraSwitchOverVideoZoomFactor: CGFloat { 0 }
  public var displayVideoZoomFactorMultiplier: CGFloat { 0 }
  // Linux has no capture hardware. Measured testAVCaptureAuthorizationDenied:
  // authorizationStatus(for:) == .denied; requestAccess(for:) == false.
  public class func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus {
    _ = mediaType
    return .denied
  }
  public class func requestAccess(for mediaType: AVMediaType) async -> Bool {
    _ = mediaType
    return false
  }
  public var automaticallyAdjustsVideoHDREnabled: Bool {
      get { false }
      set { _ = newValue }
    }
  public var isVideoHDREnabled: Bool {
      get { false }
      set { _ = newValue }
    }
  public var activeColorSpace: AVCaptureColorSpace {
      get { AVCaptureColorSpace(rawValue: 0)! }
      set { _ = newValue }
    }
  public var activeDepthDataFormat: AVCaptureDevice.Format? {
      get { nil }
      set { _ = newValue }
    }
  public var activeDepthDataMinFrameDuration: CMTime {
      get { .zero }
      set { _ = newValue }
    }
  public var minAvailableVideoZoomFactor: CGFloat { 1 }
  public var maxAvailableVideoZoomFactor: CGFloat { 1 }
  public var isGeometricDistortionCorrectionSupported: Bool { false }
  public var isGeometricDistortionCorrectionEnabled: Bool {
      get { false }
      set { _ = newValue }
    }
  public class func extrinsicMatrix(from fromDevice: AVCaptureDevice, to toDevice: AVCaptureDevice) -> Data? { nil }
  public class var centerStageControlMode: AVCaptureDevice.CenterStageControlMode {
      get { AVCaptureDevice.CenterStageControlMode(rawValue: 0)! }
      set { _ = newValue }
    }
  public class var isCenterStageEnabled: Bool {
      get { false }
      set { _ = newValue }
    }
  public var isCenterStageActive: Bool { false }
  public var centerStageRectOfInterest: CGRect {
      get { .zero }
      set { _ = newValue }
    }
  public class var isPortraitEffectEnabled: Bool { false }
  public var isPortraitEffectActive: Bool { false }
  public class var reactionEffectsEnabled: Bool { false }
  public class var reactionEffectGesturesEnabled: Bool { false }
  public var canPerformReactionEffects: Bool { false }
  public var availableReactionTypes: Set<AVCaptureReactionType> { [] }
  public func performEffect(for reactionType: AVCaptureReactionType) {}
  public var reactionEffectsInProgress: [AVCaptureReactionEffectState] { [] }
  public class var isBackgroundReplacementEnabled: Bool { false }
  public var isBackgroundReplacementActive: Bool { false }
  public var isContinuityCamera: Bool { false }
  public var companionDeskViewCamera: AVCaptureDevice? { nil }
  public class var preferredMicrophoneMode: AVCaptureDevice.MicrophoneMode { AVCaptureDevice.MicrophoneMode(rawValue: 0)! }
  public class var activeMicrophoneMode: AVCaptureDevice.MicrophoneMode { AVCaptureDevice.MicrophoneMode(rawValue: 0)! }
  public class func showSystemUserInterface(_ systemUserInterface: AVCaptureDevice.SystemUserInterface) {}
  public var spatialCaptureDiscomfortReasons: Set<AVSpatialCaptureDiscomfortReason> { [] }
  public var cinematicVideoCaptureSceneMonitoringStatuses: Set<AVCaptureSceneMonitoringStatus> { [] }
  public var dynamicAspectRatio: AVCaptureDevice.AspectRatio? { nil }
  public var dynamicDimensions: CMVideoDimensions { CMVideoDimensions(width: 0, height: 0) }
  public func setDynamicAspectRatio(_ dynamicAspectRatio: AVCaptureDevice.AspectRatio) async throws -> CMTime { return .zero }
  public var smartFramingMonitor: AVCaptureSmartFramingMonitor? { nil }
  public var nominalFocalLengthIn35mmFilm: Float { 0 }
  public class var isStudioLightEnabled: Bool { false }
  public var isStudioLightActive: Bool { false }
  public func setCameraLensSmudgeDetectionEnabled(_ cameraLensSmudgeDetectionEnabled: Bool, detectionInterval: CMTime) {}
  public var isCameraLensSmudgeDetectionEnabled: Bool { false }
  public var cameraLensSmudgeDetectionInterval: CMTime { .zero }
  public var cameraLensSmudgeDetectionStatus: AVCaptureCameraLensSmudgeDetectionStatus { AVCaptureCameraLensSmudgeDetectionStatus(rawValue: 0)! }
  public static let maxAvailableTorchLevel: Float = 0
  public static let currentLensPosition: Float = 0
  public static let currentExposureDuration: CMTime = .zero
  public static let currentISO: Float = 0
  public static let currentExposureTargetBias: Float = 0
  public static let currentWhiteBalanceGains: AVCaptureDevice.WhiteBalanceGains = AVCaptureDevice.WhiteBalanceGains()
  public static let wasConnectedNotification: Notification.Name = Notification.Name("AVCaptureDeviceWasConnectedNotification")
  public static let wasDisconnectedNotification: Notification.Name = Notification.Name("AVCaptureDeviceWasDisconnectedNotification")
  public static let subjectAreaDidChangeNotification: Notification.Name = Notification.Name("AVCaptureDeviceSubjectAreaDidChangeNotification")
}

open class AVCaptureDeviceInput: AVCaptureInput, @unchecked Sendable {
  public override init() { super.init() }
  public convenience init(device: AVCaptureDevice) throws {
    self.init()
    _ = device
    throw AVError(.applicationIsNotAuthorizedToUseDevice)
  }
  public var device: AVCaptureDevice { AVCaptureDevice() }
  public var unifiedAutoExposureDefaultsEnabled: Bool {
      get { false }
      set { _ = newValue }
    }
  public func ports(for mediaType: AVMediaType?, sourceDeviceType: AVCaptureDevice.DeviceType?, sourceDevicePosition: AVCaptureDevice.Position) -> [AVCaptureInput.Port] { [] }
  public var videoMinFrameDurationOverride: CMTime {
      get { .zero }
      set { _ = newValue }
    }
  public var isLockedVideoFrameDurationSupported: Bool { false }
  public var activeLockedVideoFrameDuration: CMTime {
      get { .zero }
      set { _ = newValue }
    }
  public var isExternalSyncSupported: Bool { false }
  public func follow(_ externalSyncDevice: AVExternalSyncDevice, videoFrameDuration frameDuration: CMTime, delegate: (any AVExternalSyncDeviceDelegate)?) {}
  public var activeExternalSyncVideoFrameDuration: CMTime { .zero }
  public var externalSyncDevice: AVExternalSyncDevice? { nil }
  public func unfollowExternalSyncDevice() {}
  public func isMultichannelAudioModeSupported(_ multichannelAudioMode: AVCaptureMultichannelAudioMode) -> Bool { false }
  public var multichannelAudioMode: AVCaptureMultichannelAudioMode {
      get { AVCaptureMultichannelAudioMode(rawValue: 0)! }
      set { _ = newValue }
    }
  public var isWindNoiseRemovalSupported: Bool { false }
  public var isWindNoiseRemovalEnabled: Bool {
      get { false }
      set { _ = newValue }
    }
  public var isCinematicVideoCaptureSupported: Bool { false }
  public var isCinematicVideoCaptureEnabled: Bool {
      get { false }
      set { _ = newValue }
    }
  public var simulatedAperture: Float {
      get { 0 }
      set { _ = newValue }
    }
}

open class AVCaptureExternalDisplayConfiguration: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var shouldMatchFrameRate: Bool {
      get { false }
      set { _ = newValue }
    }
  public var bypassColorSpaceConversion: Bool {
      get { false }
      set { _ = newValue }
    }
  public var preferredResolution: CMVideoDimensions {
      get { CMVideoDimensions(width: 0, height: 0) }
      set { _ = newValue }
    }
}

open class AVCaptureExternalDisplayConfigurator: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var device: AVCaptureDevice? { nil }
  public var isActive: Bool { false }
  public func stop() {}
  public var activeExternalDisplayFrameRate: Double { 0 }
  public class var isMatchingFrameRateSupported: Bool { false }
  public class var isBypassingColorSpaceConversionSupported: Bool { false }
  public class var isPreferredResolutionSupported: Bool { false }
}

open class AVCaptureFileOutput: AVCaptureOutput, @unchecked Sendable {
  var storedOutputFileURL: URL?
  var storedMaxRecordedDuration = CMTime.zero
  var storedMaxRecordedFileSize: Int64 = 0
  var storedMinFreeDiskSpaceLimit: Int64 = 0
  public override init() { super.init() }
  public var outputFileURL: URL? { storedOutputFileURL }
  public func startRecording(to outputFileURL: URL, recordingDelegate delegate: any AVCaptureFileOutputRecordingDelegate) {
    storedOutputFileURL = outputFileURL
    let error = AVError(.applicationIsNotAuthorizedToUseDevice)
    delegate.fileOutput(self, didFinishRecordingTo: outputFileURL, from: [], error: error)
  }
  public func stopRecording() {}
  public var isRecording: Bool { false }
  public var isRecordingPaused: Bool { false }
  public func pauseRecording() {}
  public func resumeRecording() {}
  public var recordedDuration: CMTime { .zero }
  public var recordedFileSize: Int64 { 0 }
  public var maxRecordedDuration: CMTime {
      get { storedMaxRecordedDuration }
      set { storedMaxRecordedDuration = newValue }
    }
  public var maxRecordedFileSize: Int64 {
      get { storedMaxRecordedFileSize }
      set { storedMaxRecordedFileSize = newValue }
    }
  public var minFreeDiskSpaceLimit: Int64 {
      get { storedMinFreeDiskSpaceLimit }
      set { storedMinFreeDiskSpaceLimit = newValue }
    }
}

public protocol AVCaptureFileOutputRecordingDelegate : AnyObject {
  func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection])
  func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, startPTS: CMTime, from connections: [AVCaptureConnection])
  func fileOutput(_ output: AVCaptureFileOutput, didPauseRecordingTo fileURL: URL, from connections: [AVCaptureConnection])
  func fileOutput(_ output: AVCaptureFileOutput, didResumeRecordingTo fileURL: URL, from connections: [AVCaptureConnection])
  func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: (any Error)?)
}

extension AVCaptureFileOutputRecordingDelegate {
  public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
    _ = (output, fileURL, connections)
  }
  public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, startPTS: CMTime, from connections: [AVCaptureConnection]) {
    _ = (output, fileURL, startPTS, connections)
  }
  public func fileOutput(_ output: AVCaptureFileOutput, didPauseRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
    _ = (output, fileURL, connections)
  }
  public func fileOutput(_ output: AVCaptureFileOutput, didResumeRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
    _ = (output, fileURL, connections)
  }
  public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: (any Error)?) {
    _ = (output, outputFileURL, connections, error)
  }
}

open class AVCaptureFraming: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var aspectRatio: AVCaptureDevice.AspectRatio { AVCaptureDevice.AspectRatio(rawValue: "") }
  public var zoomFactor: Float { 0 }
}

open class AVCaptureIndexPicker: AVCaptureControl, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(_ localizedTitle: String, symbolName: String, numberOfIndexes: Int) { self.init() }
  convenience init(_ localizedTitle: String, symbolName: String, numberOfIndexes: Int, localizedTitleTransform: (Int) -> String) { self.init() }
  convenience init(_ localizedTitle: String, symbolName: String, localizedIndexTitles: [String]) { self.init() }
  public var selectedIndex: Int {
      get { 0 }
      set { _ = newValue }
    }
  public var localizedTitle: String { "" }
  public var symbolName: String { "" }
  public var numberOfIndexes: Int { 0 }
  public var localizedIndexTitles: [String] { [] }
  public var accessibilityIdentifier: String? {
      get { nil }
      set { _ = newValue }
    }
}

open class AVCaptureInput: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  open class Port: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public var input: AVCaptureInput { AVCaptureInput() }
    public var mediaType: AVMediaType { AVMediaType(rawValue: "") }
    public var formatDescription: CMFormatDescription? { nil }
    public var isEnabled: Bool {
        get { false }
        set { _ = newValue }
      }
    public var clock: CMClock? { nil }
    public var sourceDeviceType: AVCaptureDevice.DeviceType? { nil }
    public var sourceDevicePosition: AVCaptureDevice.Position { AVCaptureDevice.Position(rawValue: 0)! }
    public static let formatDescriptionDidChangeNotification: Notification.Name = Notification.Name("formatDescriptionDidChangeNotification")
  }
  public var ports: [AVCaptureInput.Port] { [] }
}

open class AVCaptureManualExposureBracketedStillImageSettings: AVCaptureBracketedStillImageSettings, @unchecked Sendable {
  public override init() { super.init() }
  public var exposureDuration: CMTime { .zero }
  public var iso: Float { 0 }
}

open class AVCaptureMetadataInput: AVCaptureInput, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(formatDescription desc: CMMetadataFormatDescription, clock: CMClock) { self.init() }
  public func append(_ metadata: AVTimedMetadataGroup) throws { throw AVFoundationPortableError.mediaServiceUnavailable }
}

open class AVCaptureMetadataOutput: AVCaptureOutput, @unchecked Sendable {
  public override init() { super.init() }
  public func setMetadataObjectsDelegate(_ objectsDelegate: (any AVCaptureMetadataOutputObjectsDelegate)?, queue objectsCallbackQueue: DispatchQueue?) {}
  public var metadataObjectsDelegate: (any AVCaptureMetadataOutputObjectsDelegate)? { nil }
  public var metadataObjectsCallbackQueue: DispatchQueue? { nil }
  public var availableMetadataObjectTypes: [AVMetadataObject.ObjectType] { [] }
  public var metadataObjectTypes: [AVMetadataObject.ObjectType]! {
      get { [] }
      set { _ = newValue }
    }
  public var rectOfInterest: CGRect {
      get { .zero }
      set { _ = newValue }
    }
  public var requiredMetadataObjectTypesForCinematicVideoCapture: [AVMetadataObject.ObjectType] { [] }
}

public protocol AVCaptureMetadataOutputObjectsDelegate : AnyObject {
  func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection)
}

open class AVCaptureMovieFileOutput: AVCaptureFileOutput, @unchecked Sendable {
  private var storedFragmentInterval = CMTime.invalid
  private var storedMetadata: [AVMetadataItem]?
  private var storedOutputSettings: [ObjectIdentifier: [String : Any]] = [:]
  private var storedRecordOrientation: [ObjectIdentifier: Bool] = [:]
  private var storedSwitchingEnabled = false
  private var storedSwitchingBehavior = AVCaptureDevice.PrimaryConstituentDeviceSwitchingBehavior.unsupported
  private var storedSwitchingConditions = AVCaptureDevice.PrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions()
  private var storedSpatialEnabled = false
  public override init() { super.init() }
  public var movieFragmentInterval: CMTime {
      get { storedFragmentInterval }
      set { storedFragmentInterval = newValue }
    }
  public var metadata: [AVMetadataItem]? {
      get { storedMetadata }
      set { storedMetadata = newValue }
    }
  public var availableVideoCodecTypes: [AVVideoCodecType] { [] }
  public func supportedOutputSettingsKeys(for connection: AVCaptureConnection) -> [String] {
    _ = connection
    return []
  }
  public func outputSettings(for connection: AVCaptureConnection) -> [String : Any] {
    storedOutputSettings[ObjectIdentifier(connection)] ?? [:]
  }
  public func setOutputSettings(_ outputSettings: [String : Any]?, for connection: AVCaptureConnection) {
    storedOutputSettings[ObjectIdentifier(connection)] = outputSettings ?? [:]
  }
  public func recordsVideoOrientationAndMirroringChangesAsMetadataTrack(for connection: AVCaptureConnection) -> Bool {
    storedRecordOrientation[ObjectIdentifier(connection)] ?? false
  }
  public func setRecordsVideoOrientationAndMirroringChangesAsMetadataTrack(_ doRecordChanges: Bool, for connection: AVCaptureConnection) {
    storedRecordOrientation[ObjectIdentifier(connection)] = doRecordChanges
  }
  public var isPrimaryConstituentDeviceSwitchingBehaviorForRecordingEnabled: Bool {
      get { storedSwitchingEnabled }
      set { storedSwitchingEnabled = newValue }
    }
  public func setPrimaryConstituentDeviceSwitchingBehaviorForRecording(_ switchingBehavior: AVCaptureDevice.PrimaryConstituentDeviceSwitchingBehavior, restrictedSwitchingBehaviorConditions: AVCaptureDevice.PrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions) {
    storedSwitchingBehavior = switchingBehavior
    storedSwitchingConditions = restrictedSwitchingBehaviorConditions
  }
  public var primaryConstituentDeviceSwitchingBehaviorForRecording: AVCaptureDevice.PrimaryConstituentDeviceSwitchingBehavior { storedSwitchingBehavior }
  public var primaryConstituentDeviceRestrictedSwitchingBehaviorConditionsForRecording: AVCaptureDevice.PrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions { storedSwitchingConditions }
  public var isSpatialVideoCaptureSupported: Bool { false }
  public var isSpatialVideoCaptureEnabled: Bool {
      get { storedSpatialEnabled }
      set { storedSpatialEnabled = newValue }
    }
}

open class AVCaptureMultiCamSession: AVCaptureSession, @unchecked Sendable {
  public override init() { super.init() }
  public class var isMultiCamSupported: Bool { false }
  public var systemPressureCost: Float { 0 }
}

public enum AVCaptureMultichannelAudioMode: Int, Hashable, Sendable {
  case none = 0
  case stereo = 1
  case firstOrderAmbisonics = 2
}

open class AVCaptureOutput: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public enum DataDroppedReason: Int, Hashable, Sendable {
    case none = 0
    case lateData = 1
    case outOfBuffers = 2
    case discontinuity = 3
  }
  public var connections: [AVCaptureConnection] { [] }
  public func connection(with mediaType: AVMediaType) -> AVCaptureConnection? { nil }
  public func transformedMetadataObject(for metadataObject: AVMetadataObject, connection: AVCaptureConnection) -> AVMetadataObject? { nil }
  public func metadataOutputRectConverted(fromOutputRect rectInOutputCoordinates: CGRect) -> CGRect { .zero }
  public func outputRectConverted(fromMetadataOutputRect rectInMetadataOutputCoordinates: CGRect) -> CGRect { .zero }
  public var isDeferredStartSupported: Bool { false }
  public var isDeferredStartEnabled: Bool {
      get { false }
      set { _ = newValue }
    }
}

open class AVCapturePhoto: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var timestamp: CMTime { .invalid }
  public var isRawPhoto: Bool { false }
  public var pixelBuffer: CVPixelBuffer? { nil }
  public var previewPixelBuffer: CVPixelBuffer? { nil }
  public var embeddedThumbnailPhotoFormat: [String : Any]? { nil }
  public var depthData: AVDepthData? { nil }
  public var portraitEffectsMatte: AVPortraitEffectsMatte? { nil }
  public func semanticSegmentationMatte(for semanticSegmentationMatteType: AVSemanticSegmentationMatte.MatteType) -> AVSemanticSegmentationMatte? { nil }
  public var metadata: [String : Any] { [:] }
  public var cameraCalibrationData: AVCameraCalibrationData? { nil }
  public var resolvedSettings: AVCaptureResolvedPhotoSettings { AVCaptureResolvedPhotoSettings() }
  public var photoCount: Int { 0 }
  public var sourceDeviceType: AVCaptureDevice.DeviceType? { nil }
  public var constantColorConfidenceMap: CVPixelBuffer? { nil }
  public var constantColorCenterWeightedMeanConfidenceLevel: Float { 0 }
  public var isConstantColorFallbackPhoto: Bool { false }
  public func fileDataRepresentation() -> Data? { nil }
  public func fileDataRepresentation(with customizer: any AVCapturePhotoFileDataRepresentationCustomizer) -> Data? { nil }
  public func fileDataRepresentation(withReplacementMetadata replacementMetadata: [String : Any]?, replacementEmbeddedThumbnailPhotoFormat: [String : Any]?, replacementEmbeddedThumbnailPixelBuffer: CVPixelBuffer?, replacementDepthData: AVDepthData?) -> Data? { nil }
  public func cgImageRepresentation() -> CGImage? { nil }
  public func previewCGImageRepresentation() -> CGImage? { nil }
  public var bracketSettings: AVCaptureBracketedStillImageSettings? { nil }
  public var sequenceCount: Int { 0 }
  public var lensStabilizationStatus: AVCaptureDevice.LensStabilizationStatus { AVCaptureDevice.LensStabilizationStatus(rawValue: 0)! }
}

open class AVCapturePhotoBracketSettings: AVCapturePhotoSettings, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(rawPixelFormatType: OSType, processedFormat: [String : Any]?, bracketedSettings: [AVCaptureBracketedStillImageSettings]) { self.init() }
  convenience init(rawPixelFormatType: OSType, rawFileType: AVFileType?, processedFormat: [String : Any]?, processedFileType: AVFileType?, bracketedSettings: [AVCaptureBracketedStillImageSettings]) { self.init() }
  public var bracketedSettings: [AVCaptureBracketedStillImageSettings] { [] }
  public var isLensStabilizationEnabled: Bool {
      get { false }
      set { _ = newValue }
    }
}

public protocol AVCapturePhotoCaptureDelegate : AnyObject {
  func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings)
  func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings)
  func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings)
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?)
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishCapturingDeferredPhotoProxy deferredPhotoProxy: AVCaptureDeferredPhotoProxy?, error: (any Error)?)
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: (any Error)?)
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingRawPhoto rawSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: (any Error)?)
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishRecordingLivePhotoMovieForEventualFileAt outputFileURL: URL, resolvedSettings: AVCaptureResolvedPhotoSettings)
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: (any Error)?)
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: (any Error)?)
}

extension AVCapturePhotoCaptureDelegate {
  public func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
    _ = (output, resolvedSettings)
  }
  public func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
    _ = (output, resolvedSettings)
  }
  public func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
    _ = (output, resolvedSettings)
  }
  public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
    _ = (output, photo, error)
  }
  public func photoOutput(_ output: AVCapturePhotoOutput, didFinishCapturingDeferredPhotoProxy deferredPhotoProxy: AVCaptureDeferredPhotoProxy?, error: (any Error)?) {
    _ = (output, deferredPhotoProxy, error)
  }
  public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: (any Error)?) {
    _ = (output, photoSampleBuffer, previewPhotoSampleBuffer, resolvedSettings, bracketSettings, error)
  }
  public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingRawPhoto rawSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: (any Error)?) {
    _ = (output, rawSampleBuffer, previewPhotoSampleBuffer, resolvedSettings, bracketSettings, error)
  }
  public func photoOutput(_ output: AVCapturePhotoOutput, didFinishRecordingLivePhotoMovieForEventualFileAt outputFileURL: URL, resolvedSettings: AVCaptureResolvedPhotoSettings) {
    _ = (output, outputFileURL, resolvedSettings)
  }
  public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: (any Error)?) {
    _ = (output, outputFileURL, duration, photoDisplayTime, resolvedSettings, error)
  }
  public func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: (any Error)?) {
    _ = (output, resolvedSettings, error)
  }
}

public protocol AVCapturePhotoFileDataRepresentationCustomizer : AnyObject {
  func replacementMetadata(for photo: AVCapturePhoto) -> [String : Any]?
  func replacementDepthData(for photo: AVCapturePhoto) -> AVDepthData?
  func replacementPortraitEffectsMatte(for photo: AVCapturePhoto) -> AVPortraitEffectsMatte?
  func replacementSemanticSegmentationMatte(ofType semanticSegmentationMatteType: AVSemanticSegmentationMatte.MatteType, for photo: AVCapturePhoto) -> AVSemanticSegmentationMatte?
  func replacementAppleProRAWCompressionSettings(for photo: AVCapturePhoto, defaultSettings: [String : Any], maximumBitDepth: Int) -> [String : Any]
}

extension AVCapturePhotoFileDataRepresentationCustomizer {
  public func replacementMetadata(for photo: AVCapturePhoto) -> [String : Any]? {
    _ = photo
    return nil
  }
  public func replacementDepthData(for photo: AVCapturePhoto) -> AVDepthData? {
    _ = photo
    return nil
  }
  public func replacementPortraitEffectsMatte(for photo: AVCapturePhoto) -> AVPortraitEffectsMatte? {
    _ = photo
    return nil
  }
  public func replacementSemanticSegmentationMatte(ofType semanticSegmentationMatteType: AVSemanticSegmentationMatte.MatteType, for photo: AVCapturePhoto) -> AVSemanticSegmentationMatte? {
    _ = (semanticSegmentationMatteType, photo)
    return nil
  }
  public func replacementAppleProRAWCompressionSettings(for photo: AVCapturePhoto, defaultSettings: [String : Any], maximumBitDepth: Int) -> [String : Any] {
    _ = (photo, maximumBitDepth)
    return defaultSettings
  }
}

open class AVCapturePhotoOutput: AVCaptureOutput, @unchecked Sendable {
  final class PortableState {
    var appleProRAWEnabled = false
    var autoDeferredPhotoDeliveryEnabled = false
    var fastCapturePrioritizationEnabled = false
    var virtualDeviceConstituentPhotoDeliveryEnabled = false
    var dualCameraDualPhotoDeliveryEnabled = false
    var highResolutionCaptureEnabled = false
    var livePhotoCaptureEnabled = false
    var livePhotoCaptureSuspended = false
    var preservesLivePhotoCaptureSuspendedOnSessionStop = false
    var livePhotoAutoTrimmingEnabled = false
    var contentAwareDistortionCorrectionEnabled = false
    var zeroShutterLagEnabled = false
    var responsiveCaptureEnabled = false
    var constantColorEnabled = false
    var cameraSensorOrientationCompensationEnabled = false
    var depthDataDeliveryEnabled = false
    var portraitEffectsMatteDeliveryEnabled = false
    var maxPhotoQualityPrioritization = AVCapturePhotoOutput.QualityPrioritization.speed
    var maxPhotoDimensions = CMVideoDimensions(width: 0, height: 0)
    var photoSettingsForSceneMonitoring: AVCapturePhotoSettings?
    var enabledSemanticSegmentationMatteTypes: [AVSemanticSegmentationMatte.MatteType] = []
  }

  let portableState = PortableState()

  public override init() { super.init() }
  public enum CaptureReadiness: Int, Hashable, Sendable {
    case sessionNotRunning = 0
    case ready = 1
    case notReadyMomentarily = 2
    case notReadyWaitingForCapture = 3
    case notReadyWaitingForProcessing = 4
  }
  public enum QualityPrioritization: Int, Hashable, Sendable {
    case speed = 0
    case balanced = 1
    case quality = 2
  }
  public var supportedFlashModes: [AVCaptureDevice.FlashMode] { [] }
  public var availablePhotoPixelFormatTypes: [OSType] { [] }
  public var availableRawPhotoPixelFormatTypes: [OSType] { [] }
  public func supportedPhotoPixelFormatTypes(for fileType: AVFileType) -> [OSType] {
    _ = fileType
    return []
  }
  public func supportedRawPhotoPixelFormatTypes(for fileType: AVFileType) -> [OSType] {
    _ = fileType
    return []
  }
  public func capturePhoto(with settings: AVCapturePhotoSettings, delegate: any AVCapturePhotoCaptureDelegate) {
    let resolved = AVCaptureResolvedPhotoSettings()
    resolved.portableUniqueID = settings.uniqueID
    let error = AVError(.applicationIsNotAuthorizedToUseDevice)
    delegate.photoOutput(self, didFinishProcessingPhoto: AVCapturePhoto(), error: error)
    delegate.photoOutput(self, didFinishCaptureFor: resolved, error: error)
  }
  public var preparedPhotoSettingsArray: [AVCapturePhotoSettings] { [] }
  public func setPreparedPhotoSettingsArray(_ preparedPhotoSettingsArray: [AVCapturePhotoSettings]) async throws {
    _ = preparedPhotoSettingsArray
    throw AVFoundationPortableError.mediaServiceUnavailable
  }
  public var availablePhotoCodecTypes: [AVVideoCodecType] { [] }
  public var availableRawPhotoCodecTypes: [AVVideoCodecType] { [] }
  public var isAppleProRAWSupported: Bool { false }
  public var isAppleProRAWEnabled: Bool {
    get { portableState.appleProRAWEnabled }
    set { portableState.appleProRAWEnabled = newValue }
  }
  public class func isBayerRAWPixelFormat(_ pixelFormat: OSType) -> Bool {
    _ = pixelFormat
    return false
  }
  public class func isAppleProRAWPixelFormat(_ pixelFormat: OSType) -> Bool {
    _ = pixelFormat
    return false
  }
  public var availablePhotoFileTypes: [AVFileType] { [] }
  public var availableRawPhotoFileTypes: [AVFileType] { [] }
  public func supportedPhotoCodecTypes(for fileType: AVFileType) -> [AVVideoCodecType] {
    _ = fileType
    return []
  }
  public func supportedRawPhotoCodecTypes(forRawPhotoPixelFormatType pixelFormatType: OSType, fileType: AVFileType) -> [AVVideoCodecType] {
    _ = (pixelFormatType, fileType)
    return []
  }
  public var maxPhotoQualityPrioritization: AVCapturePhotoOutput.QualityPrioritization {
    get { portableState.maxPhotoQualityPrioritization }
    set { portableState.maxPhotoQualityPrioritization = newValue }
  }
  public var isFastCapturePrioritizationSupported: Bool {
    get { false }
    set { _ = newValue }
  }
  public var isFastCapturePrioritizationEnabled: Bool {
    get { portableState.fastCapturePrioritizationEnabled }
    set { portableState.fastCapturePrioritizationEnabled = newValue }
  }
  public var isAutoDeferredPhotoDeliverySupported: Bool { false }
  public var isAutoDeferredPhotoDeliveryEnabled: Bool {
    get { portableState.autoDeferredPhotoDeliveryEnabled }
    set { portableState.autoDeferredPhotoDeliveryEnabled = newValue }
  }
  public var isStillImageStabilizationSupported: Bool { false }
  public var isStillImageStabilizationScene: Bool { false }
  public var isVirtualDeviceFusionSupported: Bool { false }
  public var isDualCameraFusionSupported: Bool { false }
  public var isVirtualDeviceConstituentPhotoDeliverySupported: Bool { false }
  public var isDualCameraDualPhotoDeliverySupported: Bool { false }
  public var isVirtualDeviceConstituentPhotoDeliveryEnabled: Bool {
    get { portableState.virtualDeviceConstituentPhotoDeliveryEnabled }
    set { portableState.virtualDeviceConstituentPhotoDeliveryEnabled = newValue }
  }
  public var isDualCameraDualPhotoDeliveryEnabled: Bool {
    get { portableState.dualCameraDualPhotoDeliveryEnabled }
    set { portableState.dualCameraDualPhotoDeliveryEnabled = newValue }
  }
  public var isCameraCalibrationDataDeliverySupported: Bool { false }
  public var isAutoRedEyeReductionSupported: Bool { false }
  public var isFlashScene: Bool { false }
  public var photoSettingsForSceneMonitoring: AVCapturePhotoSettings? {
    get { portableState.photoSettingsForSceneMonitoring }
    set { portableState.photoSettingsForSceneMonitoring = newValue }
  }
  public var isHighResolutionCaptureEnabled: Bool {
    get { portableState.highResolutionCaptureEnabled }
    set { portableState.highResolutionCaptureEnabled = newValue }
  }
  public var maxPhotoDimensions: CMVideoDimensions {
    get { portableState.maxPhotoDimensions }
    set { portableState.maxPhotoDimensions = newValue }
  }
  public var maxBracketedCapturePhotoCount: Int { 0 }
  public var isLensStabilizationDuringBracketedCaptureSupported: Bool { false }
  public var isLivePhotoCaptureSupported: Bool { false }
  public var isLivePhotoCaptureEnabled: Bool {
    get { portableState.livePhotoCaptureEnabled }
    set { portableState.livePhotoCaptureEnabled = newValue }
  }
  public var isLivePhotoCaptureSuspended: Bool {
    get { portableState.livePhotoCaptureSuspended }
    set { portableState.livePhotoCaptureSuspended = newValue }
  }
  public var preservesLivePhotoCaptureSuspendedOnSessionStop: Bool {
    get { portableState.preservesLivePhotoCaptureSuspendedOnSessionStop }
    set { portableState.preservesLivePhotoCaptureSuspendedOnSessionStop = newValue }
  }
  public var isLivePhotoAutoTrimmingEnabled: Bool {
    get { portableState.livePhotoAutoTrimmingEnabled }
    set { portableState.livePhotoAutoTrimmingEnabled = newValue }
  }
  public var availableLivePhotoVideoCodecTypes: [AVVideoCodecType] { [] }
  public class func jpegPhotoDataRepresentation(forJPEGSampleBuffer JPEGSampleBuffer: CMSampleBuffer, previewPhotoSampleBuffer: CMSampleBuffer?) -> Data? {
    _ = (JPEGSampleBuffer, previewPhotoSampleBuffer)
    return nil
  }
  public class func dngPhotoDataRepresentation(forRawSampleBuffer rawSampleBuffer: CMSampleBuffer, previewPhotoSampleBuffer: CMSampleBuffer?) -> Data? {
    _ = (rawSampleBuffer, previewPhotoSampleBuffer)
    return nil
  }
  public var isContentAwareDistortionCorrectionSupported: Bool { false }
  public var isContentAwareDistortionCorrectionEnabled: Bool {
    get { portableState.contentAwareDistortionCorrectionEnabled }
    set { portableState.contentAwareDistortionCorrectionEnabled = newValue }
  }
  public var isZeroShutterLagSupported: Bool { false }
  public var isZeroShutterLagEnabled: Bool {
    get { portableState.zeroShutterLagEnabled }
    set { portableState.zeroShutterLagEnabled = newValue }
  }
  public var isResponsiveCaptureSupported: Bool { false }
  public var isResponsiveCaptureEnabled: Bool {
    get { portableState.responsiveCaptureEnabled }
    set { portableState.responsiveCaptureEnabled = newValue }
  }
  public var captureReadiness: AVCapturePhotoOutput.CaptureReadiness { .sessionNotRunning }
  public var isConstantColorSupported: Bool { false }
  public var isConstantColorEnabled: Bool {
    get { portableState.constantColorEnabled }
    set { portableState.constantColorEnabled = newValue }
  }
  public var isShutterSoundSuppressionSupported: Bool { false }
  public var isCameraSensorOrientationCompensationSupported: Bool { false }
  public var isCameraSensorOrientationCompensationEnabled: Bool {
    get { portableState.cameraSensorOrientationCompensationEnabled }
    set { portableState.cameraSensorOrientationCompensationEnabled = newValue }
  }
  public var isDepthDataDeliverySupported: Bool { false }
  public var isDepthDataDeliveryEnabled: Bool {
    get { portableState.depthDataDeliveryEnabled }
    set { portableState.depthDataDeliveryEnabled = newValue }
  }
  public var isPortraitEffectsMatteDeliverySupported: Bool { false }
  public var isPortraitEffectsMatteDeliveryEnabled: Bool {
    get { portableState.portraitEffectsMatteDeliveryEnabled }
    set { portableState.portraitEffectsMatteDeliveryEnabled = newValue }
  }
  public var availableSemanticSegmentationMatteTypes: [AVSemanticSegmentationMatte.MatteType] { [] }
  public var enabledSemanticSegmentationMatteTypes: [AVSemanticSegmentationMatte.MatteType] {
    get { portableState.enabledSemanticSegmentationMatteTypes }
    set { portableState.enabledSemanticSegmentationMatteTypes = newValue }
  }
}

open class AVCapturePhotoOutputReadinessCoordinator: NSObject, @unchecked Sendable {
  var portableDelegate: (any AVCapturePhotoOutputReadinessCoordinatorDelegate)?
  var portableReadiness = AVCapturePhotoOutput.CaptureReadiness.sessionNotRunning
  var portableTracked: Set<Int64> = []

  public override init() { super.init() }
  public convenience init(photoOutput: AVCapturePhotoOutput) {
    self.init()
    portableReadiness = photoOutput.captureReadiness
  }
  public var delegate: (any AVCapturePhotoOutputReadinessCoordinatorDelegate)? {
    get { portableDelegate }
    set { portableDelegate = newValue }
  }
  public var captureReadiness: AVCapturePhotoOutput.CaptureReadiness { portableReadiness }
  public func startTrackingCaptureRequest(using settings: AVCapturePhotoSettings) {
    portableTracked.insert(settings.uniqueID)
    portableDelegate?.readinessCoordinator(self, captureReadinessDidChange: portableReadiness)
  }
  public func stopTrackingCaptureRequest(using settingsUniqueID: Int64) {
    portableTracked.remove(settingsUniqueID)
  }
}

public protocol AVCapturePhotoOutputReadinessCoordinatorDelegate : AnyObject {
  func readinessCoordinator(_ coordinator: AVCapturePhotoOutputReadinessCoordinator, captureReadinessDidChange captureReadiness: AVCapturePhotoOutput.CaptureReadiness)
}

open class AVCapturePhotoSettings: NSObject, @unchecked Sendable {
  private static let idLock = NSLock()
  private static var nextUniqueID: Int64 = 1

  static func allocateUniqueID() -> Int64 {
    idLock.lock()
    defer { idLock.unlock() }
    let value = nextUniqueID
    nextUniqueID += 1
    return value
  }

  var portableUniqueID: Int64
  var portableFormat: [String: Any]?
  var portableRawFileFormat: [String: Any]?
  var portableProcessedFileType: AVFileType?
  var portableRawFileType: AVFileType?
  var portableFlashMode = AVCaptureDevice.FlashMode.off
  var portableAutoRedEyeReductionEnabled = false
  var portablePhotoQualityPrioritization = AVCapturePhotoOutput.QualityPrioritization.speed
  var portableAutoStillImageStabilizationEnabled = false
  var portableAutoVirtualDeviceFusionEnabled = false
  var portableAutoDualCameraFusionEnabled = false
  var portableVirtualDeviceConstituentPhotoDeliveryEnabledDevices: [AVCaptureDevice] = []
  var portableDualCameraDualPhotoDeliveryEnabled = false
  var portableHighResolutionPhotoEnabled = false
  var portableMaxPhotoDimensions = CMVideoDimensions(width: 0, height: 0)
  var portableDepthDataDeliveryEnabled = false
  var portableEmbedsDepthDataInPhoto = false
  var portableDepthDataFiltered = false
  var portableCameraCalibrationDataDeliveryEnabled = false
  var portablePortraitEffectsMatteDeliveryEnabled = false
  var portableEmbedsPortraitEffectsMatteInPhoto = false
  var portableEnabledSemanticSegmentationMatteTypes: [AVSemanticSegmentationMatte.MatteType] = []
  var portableEmbedsSemanticSegmentationMattesInPhoto = false
  var portableMetadata: [String: Any] = [:]
  var portableLivePhotoMovieFileURL: URL?
  var portableLivePhotoVideoCodecType = AVVideoCodecType(rawValue: "")
  var portableLivePhotoMovieMetadata: [AVMetadataItem] = []
  var portablePreviewPhotoFormat: [String: Any]?
  var portableEmbeddedThumbnailPhotoFormat: [String: Any]?
  var portableRawEmbeddedThumbnailPhotoFormat: [String: Any]?
  var portableAutoContentAwareDistortionCorrectionEnabled = false
  var portableConstantColorEnabled = false
  var portableConstantColorFallbackPhotoDeliveryEnabled = false
  var portableShutterSoundSuppressionEnabled = false

  public override init() {
    portableUniqueID = AVCapturePhotoSettings.allocateUniqueID()
    super.init()
  }

  public var availablePreviewPhotoPixelFormatTypes: [OSType] { [] }

  public convenience init(format: [String : Any]?) {
    self.init()
    portableFormat = format
  }

  public convenience init(rawPixelFormatType: OSType) {
    self.init()
    _ = rawPixelFormatType
  }

  public convenience init(rawPixelFormatType: OSType, processedFormat: [String : Any]?) {
    self.init(format: processedFormat)
    _ = rawPixelFormatType
  }

  public convenience init(
    rawPixelFormatType: OSType,
    rawFileType: AVFileType?,
    processedFormat: [String : Any]?,
    processedFileType: AVFileType?
  ) {
    self.init(format: processedFormat)
    _ = rawPixelFormatType
    portableRawFileType = rawFileType
    portableProcessedFileType = processedFileType
  }

  public convenience init(from photoSettings: AVCapturePhotoSettings) {
    self.init(format: photoSettings.format)
    portableRawFileFormat = photoSettings.rawFileFormat
    portableProcessedFileType = photoSettings.processedFileType
    portableRawFileType = photoSettings.rawFileType
    portableFlashMode = photoSettings.flashMode
    portableAutoRedEyeReductionEnabled = photoSettings.isAutoRedEyeReductionEnabled
    portablePhotoQualityPrioritization = photoSettings.photoQualityPrioritization
    portableHighResolutionPhotoEnabled = photoSettings.isHighResolutionPhotoEnabled
    portableMaxPhotoDimensions = photoSettings.maxPhotoDimensions
    portableDepthDataDeliveryEnabled = photoSettings.isDepthDataDeliveryEnabled
    portableMetadata = photoSettings.metadata
    portableLivePhotoMovieFileURL = photoSettings.livePhotoMovieFileURL
    portablePreviewPhotoFormat = photoSettings.previewPhotoFormat
  }

  public var uniqueID: Int64 { portableUniqueID }
  public var format: [String : Any]? { portableFormat }
  public var rawFileFormat: [String : Any]? {
    get { portableRawFileFormat }
    set { portableRawFileFormat = newValue }
  }
  public var processedFileType: AVFileType? { portableProcessedFileType }
  public var rawFileType: AVFileType? { portableRawFileType }
  public var flashMode: AVCaptureDevice.FlashMode {
    get { portableFlashMode }
    set { portableFlashMode = newValue }
  }
  public var isAutoRedEyeReductionEnabled: Bool {
    get { portableAutoRedEyeReductionEnabled }
    set { portableAutoRedEyeReductionEnabled = newValue }
  }
  public var photoQualityPrioritization: AVCapturePhotoOutput.QualityPrioritization {
    get { portablePhotoQualityPrioritization }
    set { portablePhotoQualityPrioritization = newValue }
  }
  public var isAutoStillImageStabilizationEnabled: Bool {
    get { portableAutoStillImageStabilizationEnabled }
    set { portableAutoStillImageStabilizationEnabled = newValue }
  }
  public var isAutoVirtualDeviceFusionEnabled: Bool {
    get { portableAutoVirtualDeviceFusionEnabled }
    set { portableAutoVirtualDeviceFusionEnabled = newValue }
  }
  public var isAutoDualCameraFusionEnabled: Bool {
    get { portableAutoDualCameraFusionEnabled }
    set { portableAutoDualCameraFusionEnabled = newValue }
  }
  public var virtualDeviceConstituentPhotoDeliveryEnabledDevices: [AVCaptureDevice] {
    get { portableVirtualDeviceConstituentPhotoDeliveryEnabledDevices }
    set { portableVirtualDeviceConstituentPhotoDeliveryEnabledDevices = newValue }
  }
  public var isDualCameraDualPhotoDeliveryEnabled: Bool {
    get { portableDualCameraDualPhotoDeliveryEnabled }
    set { portableDualCameraDualPhotoDeliveryEnabled = newValue }
  }
  public var isHighResolutionPhotoEnabled: Bool {
    get { portableHighResolutionPhotoEnabled }
    set { portableHighResolutionPhotoEnabled = newValue }
  }
  public var maxPhotoDimensions: CMVideoDimensions {
    get { portableMaxPhotoDimensions }
    set { portableMaxPhotoDimensions = newValue }
  }
  public var isDepthDataDeliveryEnabled: Bool {
    get { portableDepthDataDeliveryEnabled }
    set { portableDepthDataDeliveryEnabled = newValue }
  }
  public var embedsDepthDataInPhoto: Bool {
    get { portableEmbedsDepthDataInPhoto }
    set { portableEmbedsDepthDataInPhoto = newValue }
  }
  public var isDepthDataFiltered: Bool {
    get { portableDepthDataFiltered }
    set { portableDepthDataFiltered = newValue }
  }
  public var isCameraCalibrationDataDeliveryEnabled: Bool {
    get { portableCameraCalibrationDataDeliveryEnabled }
    set { portableCameraCalibrationDataDeliveryEnabled = newValue }
  }
  public var isPortraitEffectsMatteDeliveryEnabled: Bool {
    get { portablePortraitEffectsMatteDeliveryEnabled }
    set { portablePortraitEffectsMatteDeliveryEnabled = newValue }
  }
  public var embedsPortraitEffectsMatteInPhoto: Bool {
    get { portableEmbedsPortraitEffectsMatteInPhoto }
    set { portableEmbedsPortraitEffectsMatteInPhoto = newValue }
  }
  public var enabledSemanticSegmentationMatteTypes: [AVSemanticSegmentationMatte.MatteType] {
    get { portableEnabledSemanticSegmentationMatteTypes }
    set { portableEnabledSemanticSegmentationMatteTypes = newValue }
  }
  public var embedsSemanticSegmentationMattesInPhoto: Bool {
    get { portableEmbedsSemanticSegmentationMattesInPhoto }
    set { portableEmbedsSemanticSegmentationMattesInPhoto = newValue }
  }
  public var metadata: [String : Any] {
    get { portableMetadata }
    set { portableMetadata = newValue }
  }
  public var livePhotoMovieFileURL: URL? {
    get { portableLivePhotoMovieFileURL }
    set { portableLivePhotoMovieFileURL = newValue }
  }
  public var livePhotoVideoCodecType: AVVideoCodecType {
    get { portableLivePhotoVideoCodecType }
    set { portableLivePhotoVideoCodecType = newValue }
  }
  public var livePhotoMovieMetadata: [AVMetadataItem]! {
    get { portableLivePhotoMovieMetadata }
    set { portableLivePhotoMovieMetadata = newValue ?? [] }
  }
  public var previewPhotoFormat: [String : Any]? {
    get { portablePreviewPhotoFormat }
    set { portablePreviewPhotoFormat = newValue }
  }
  public var availableEmbeddedThumbnailPhotoCodecTypes: [AVVideoCodecType] { [] }
  public var embeddedThumbnailPhotoFormat: [String : Any]? {
    get { portableEmbeddedThumbnailPhotoFormat }
    set { portableEmbeddedThumbnailPhotoFormat = newValue }
  }
  public var availableRawEmbeddedThumbnailPhotoCodecTypes: [AVVideoCodecType] { [] }
  public var rawEmbeddedThumbnailPhotoFormat: [String : Any]? {
    get { portableRawEmbeddedThumbnailPhotoFormat }
    set { portableRawEmbeddedThumbnailPhotoFormat = newValue }
  }
  public var isAutoContentAwareDistortionCorrectionEnabled: Bool {
    get { portableAutoContentAwareDistortionCorrectionEnabled }
    set { portableAutoContentAwareDistortionCorrectionEnabled = newValue }
  }
  public var isConstantColorEnabled: Bool {
    get { portableConstantColorEnabled }
    set { portableConstantColorEnabled = newValue }
  }
  public var isConstantColorFallbackPhotoDeliveryEnabled: Bool {
    get { portableConstantColorFallbackPhotoDeliveryEnabled }
    set { portableConstantColorFallbackPhotoDeliveryEnabled = newValue }
  }
  public var isShutterSoundSuppressionEnabled: Bool {
    get { portableShutterSoundSuppressionEnabled }
    set { portableShutterSoundSuppressionEnabled = newValue }
  }
}

open class AVCaptureReactionEffectState: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var reactionType: AVCaptureReactionType { AVCaptureReactionType(rawValue: "") }
  public var startTime: CMTime { .zero }
  public var endTime: CMTime { .zero }
}

public struct AVCaptureReactionType: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  public static let thumbsUp = AVCaptureReactionType(rawValue: "thumbsUp")
  public static let thumbsDown = AVCaptureReactionType(rawValue: "thumbsDown")
  public static let balloons = AVCaptureReactionType(rawValue: "balloons")
  public static let heart = AVCaptureReactionType(rawValue: "heart")
  public static let fireworks = AVCaptureReactionType(rawValue: "fireworks")
  public static let rain = AVCaptureReactionType(rawValue: "rain")
  public static let confetti = AVCaptureReactionType(rawValue: "confetti")
  public static let lasers = AVCaptureReactionType(rawValue: "lasers")
}

open class AVCaptureResolvedPhotoSettings: NSObject, @unchecked Sendable {
  var portableUniqueID: Int64 = 0
  public override init() { super.init() }
  public var uniqueID: Int64 { portableUniqueID }
  public var photoDimensions: CMVideoDimensions { CMVideoDimensions(width: 0, height: 0) }
  public var rawPhotoDimensions: CMVideoDimensions { CMVideoDimensions(width: 0, height: 0) }
  public var previewDimensions: CMVideoDimensions { CMVideoDimensions(width: 0, height: 0) }
  public var embeddedThumbnailDimensions: CMVideoDimensions { CMVideoDimensions(width: 0, height: 0) }
  public var rawEmbeddedThumbnailDimensions: CMVideoDimensions { CMVideoDimensions(width: 0, height: 0) }
  public var portraitEffectsMatteDimensions: CMVideoDimensions { CMVideoDimensions(width: 0, height: 0) }
  public func dimensionsForSemanticSegmentationMatte(ofType semanticSegmentationMatteType: AVSemanticSegmentationMatte.MatteType) -> CMVideoDimensions { CMVideoDimensions(width: 0, height: 0) }
  public var livePhotoMovieDimensions: CMVideoDimensions { CMVideoDimensions(width: 0, height: 0) }
  public var isFlashEnabled: Bool { false }
  public var isRedEyeReductionEnabled: Bool { false }
  public var deferredPhotoProxyDimensions: CMVideoDimensions { CMVideoDimensions(width: 0, height: 0) }
  public var isStillImageStabilizationEnabled: Bool { false }
  public var isVirtualDeviceFusionEnabled: Bool { false }
  public var isDualCameraFusionEnabled: Bool { false }
  public var expectedPhotoCount: Int { 0 }
  public var photoProcessingTimeRange: CMTimeRange { .zero }
  public var isContentAwareDistortionCorrectionEnabled: Bool { false }
  public var isFastCapturePrioritizationEnabled: Bool { false }
}

public struct AVCaptureSceneMonitoringStatus: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  public static let notEnoughLight = AVCaptureSceneMonitoringStatus(rawValue: "notEnoughLight")
}

open class AVCaptureSession: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public enum InterruptionReason: Int, Hashable, Sendable {
    case videoDeviceNotAvailableInBackground = 0
    case audioDeviceInUseByAnotherClient = 1
    case videoDeviceInUseByAnotherClient = 2
    case videoDeviceNotAvailableWithMultipleForegroundApps = 3
    case videoDeviceNotAvailableDueToSystemPressure = 4
    case sensitiveContentMitigationActivated = 5
  }
  public struct Preset: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
    public static let photo = Preset(rawValue: "photo")
    public static let high = Preset(rawValue: "high")
    public static let medium = Preset(rawValue: "medium")
    public static let low = Preset(rawValue: "low")
    public static let cif352x288 = Preset(rawValue: "cif352x288")
    public static let vga640x480 = Preset(rawValue: "vga640x480")
    public static let hd1280x720 = Preset(rawValue: "hd1280x720")
    public static let hd1920x1080 = Preset(rawValue: "hd1920x1080")
    public static let hd4K3840x2160 = Preset(rawValue: "hd4K3840x2160")
    public static let iFrame960x540 = Preset(rawValue: "iFrame960x540")
    public static let iFrame1280x720 = Preset(rawValue: "iFrame1280x720")
    public static let inputPriority = Preset(rawValue: "inputPriority")
  }
  private var storedPreset = AVCaptureSession.Preset.high
  private var storedUsesApplicationAudioSession = true
  private var storedAutomaticallyConfiguresApplicationAudioSession = true
  private var storedConfiguresMixWithOthers = false
  private var storedConfiguresBluetoothHQ = false
  private var storedAutomaticallyConfiguresWideColor = true
  private var storedMultitaskingCameraAccessEnabled = false
  private var storedAutomaticallyRunsDeferredStart = false
  weak var storedControlsDelegate: (any AVCaptureSessionControlsDelegate)?
  var storedControlsDelegateQueue: DispatchQueue?
  weak var storedDeferredStartDelegate: (any AVCaptureSessionDeferredStartDelegate)?
  var storedDeferredStartDelegateQueue: DispatchQueue?
  public func canSetSessionPreset(_ preset: AVCaptureSession.Preset) -> Bool {
    _ = preset
    return false
  }
  public var sessionPreset: AVCaptureSession.Preset {
      get { storedPreset }
      set { storedPreset = newValue }
    }
  public var inputs: [AVCaptureInput] { [] }
  public func canAddInput(_ input: AVCaptureInput) -> Bool {
    _ = input
    return false
  }
  public func addInput(_ input: AVCaptureInput) { _ = input }
  public func removeInput(_ input: AVCaptureInput) { _ = input }
  public var outputs: [AVCaptureOutput] { [] }
  public func canAddOutput(_ output: AVCaptureOutput) -> Bool {
    _ = output
    return false
  }
  public func addOutput(_ output: AVCaptureOutput) { _ = output }
  public func removeOutput(_ output: AVCaptureOutput) { _ = output }
  public func addInputWithNoConnections(_ input: AVCaptureInput) { _ = input }
  public func addOutputWithNoConnections(_ output: AVCaptureOutput) { _ = output }
  public var connections: [AVCaptureConnection] { [] }
  public func canAddConnection(_ connection: AVCaptureConnection) -> Bool { false }
  public func addConnection(_ connection: AVCaptureConnection) { _ = connection }
  public func removeConnection(_ connection: AVCaptureConnection) { _ = connection }
  public var supportsControls: Bool { false }
  public var maxControlsCount: Int { 0 }
  public func setControlsDelegate(_ controlsDelegate: (any AVCaptureSessionControlsDelegate)?, queue controlsDelegateCallbackQueue: DispatchQueue?) {
    storedControlsDelegate = controlsDelegate
    storedControlsDelegateQueue = controlsDelegateCallbackQueue
  }
  public var controlsDelegate: (any AVCaptureSessionControlsDelegate)? { storedControlsDelegate }
  public var controlsDelegateCallbackQueue: DispatchQueue? { storedControlsDelegateQueue }
  public var controls: [AVCaptureControl] { [] }
  public func canAddControl(_ control: AVCaptureControl) -> Bool {
    _ = control
    return false
  }
  public func addControl(_ control: AVCaptureControl) { _ = control }
  public func removeControl(_ control: AVCaptureControl) { _ = control }
  public func beginConfiguration() {}
  public func commitConfiguration() {}
  // Measured testAVCaptureSessionFailClosed: startRunning() leaves isRunning false.
  public var isRunning: Bool { false }
  public var isInterrupted: Bool { false }
  public var isMultitaskingCameraAccessSupported: Bool { false }
  public var isMultitaskingCameraAccessEnabled: Bool {
      get { storedMultitaskingCameraAccessEnabled }
      set { storedMultitaskingCameraAccessEnabled = newValue }
    }
  public var usesApplicationAudioSession: Bool {
      get { storedUsesApplicationAudioSession }
      set { storedUsesApplicationAudioSession = newValue }
    }
  public var automaticallyConfiguresApplicationAudioSession: Bool {
      get { storedAutomaticallyConfiguresApplicationAudioSession }
      set { storedAutomaticallyConfiguresApplicationAudioSession = newValue }
    }
  public var configuresApplicationAudioSessionToMixWithOthers: Bool {
      get { storedConfiguresMixWithOthers }
      set { storedConfiguresMixWithOthers = newValue }
    }
  public var configuresApplicationAudioSessionForBluetoothHighQualityRecording: Bool {
      get { storedConfiguresBluetoothHQ }
      set { storedConfiguresBluetoothHQ = newValue }
    }
  public var automaticallyConfiguresCaptureDeviceForWideColor: Bool {
      get { storedAutomaticallyConfiguresWideColor }
      set { storedAutomaticallyConfiguresWideColor = newValue }
    }
  public func startRunning() {}
  public func stopRunning() {}
  public var synchronizationClock: CMClock? { nil }
  public var masterClock: CMClock? { nil }
  public var hardwareCost: Float { 0 }
  public var isManualDeferredStartSupported: Bool { false }
  public var automaticallyRunsDeferredStart: Bool {
      get { storedAutomaticallyRunsDeferredStart }
      set { storedAutomaticallyRunsDeferredStart = newValue }
    }
  public func runDeferredStartWhenNeeded() {}
  public var deferredStartDelegate: (any AVCaptureSessionDeferredStartDelegate)? { storedDeferredStartDelegate }
  public var deferredStartDelegateCallbackQueue: DispatchQueue? { storedDeferredStartDelegateQueue }
  public func setDeferredStartDelegate(_ deferredStartDelegate: (any AVCaptureSessionDeferredStartDelegate)?, deferredStartDelegateCallbackQueue: DispatchQueue?) {
    storedDeferredStartDelegate = deferredStartDelegate
    storedDeferredStartDelegateQueue = deferredStartDelegateCallbackQueue
  }
  public static let runtimeErrorNotification: Notification.Name = Notification.Name("AVCaptureSessionRuntimeErrorNotification")
  public static let didStartRunningNotification: Notification.Name = Notification.Name("AVCaptureSessionDidStartRunningNotification")
  public static let didStopRunningNotification: Notification.Name = Notification.Name("AVCaptureSessionDidStopRunningNotification")
  public static let wasInterruptedNotification: Notification.Name = Notification.Name("AVCaptureSessionWasInterruptedNotification")
  public static let interruptionEndedNotification: Notification.Name = Notification.Name("AVCaptureSessionInterruptionEndedNotification")
}

public protocol AVCaptureSessionControlsDelegate : AnyObject {
  func sessionControlsDidBecomeActive(_ session: AVCaptureSession)
  func sessionControlsWillEnterFullscreenAppearance(_ session: AVCaptureSession)
  func sessionControlsWillExitFullscreenAppearance(_ session: AVCaptureSession)
  func sessionControlsDidBecomeInactive(_ session: AVCaptureSession)
}

public protocol AVCaptureSessionDeferredStartDelegate : AnyObject {
  func sessionWillRunDeferredStart(_ session: AVCaptureSession)
  func sessionDidRunDeferredStart(_ session: AVCaptureSession)
}

open class AVCaptureSlider: AVCaptureControl, @unchecked Sendable {
  public override init() { super.init() }
  public var prominentValues: [Float] {
      get { [] }
      set { _ = newValue }
    }
  convenience init(_ localizedTitle: String, symbolName: String, in range: ClosedRange<Float>) { self.init() }
  convenience init(_ localizedTitle: String, symbolName: String, in range: ClosedRange<Float>, step: Float) { self.init() }
  convenience init(_ localizedTitle: String, symbolName: String, values: [Float]) { self.init() }
  public var value: Float {
      get { 0 }
      set { _ = newValue }
    }
  public var localizedValueFormat: String? {
      get { nil }
      set { _ = newValue }
    }
  public var localizedTitle: String { "" }
  public var symbolName: String { "" }
  public var accessibilityIdentifier: String? {
      get { nil }
      set { _ = newValue }
    }
}

open class AVCaptureSmartFramingMonitor: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var supportedFramings: [AVCaptureFraming] { [] }
  public var enabledFramings: [AVCaptureFraming] {
      get { [] }
      set { _ = newValue }
    }
  public var recommendedFraming: AVCaptureFraming? { nil }
  public func startMonitoring() throws { throw AVFoundationPortableError.mediaServiceUnavailable }
  public func stopMonitoring() {}
  public var isMonitoring: Bool { false }
}

open class AVCaptureSpatialAudioMetadataSampleGenerator: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var timedMetadataSampleBufferFormatDescription: CMFormatDescription { CMFormatDescription() }
  public func newTimedMetadataSampleBufferAndResetAnalyzer() -> Unmanaged<CMSampleBuffer>? { nil }
  public func resetAnalyzer() {}
}

open class AVCaptureStillImageOutput: AVCaptureOutput, @unchecked Sendable {
  private var storedOutputSettings: [String : Any] = [:]
  private var storedAutoStabilization = false
  private var storedHighRes = false
  private var storedOrientationCompensation = false
  private var storedLensStabilization = false
  public override init() { super.init() }
  public var outputSettings: [String : Any] {
      get { storedOutputSettings }
      set { storedOutputSettings = newValue }
    }
  public var availableImageDataCVPixelFormatTypes: [NSNumber] { [] }
  public var availableImageDataCodecTypes: [AVVideoCodecType] { [] }
  public var isStillImageStabilizationSupported: Bool { false }
  public var automaticallyEnablesStillImageStabilizationWhenAvailable: Bool {
      get { storedAutoStabilization }
      set { storedAutoStabilization = newValue }
    }
  public var isStillImageStabilizationActive: Bool { false }
  public var isHighResolutionStillImageOutputEnabled: Bool {
      get { storedHighRes }
      set { storedHighRes = newValue }
    }
  public var isCameraSensorOrientationCompensationSupported: Bool { false }
  public var isCameraSensorOrientationCompensationEnabled: Bool {
      get { storedOrientationCompensation }
      set { storedOrientationCompensation = newValue }
    }
  public var isCapturingStillImage: Bool { false }
  public class func jpegStillImageNSDataRepresentation(_ jpegSampleBuffer: CMSampleBuffer) -> Data? {
    _ = jpegSampleBuffer
    return nil
  }
  public var maxBracketedCaptureStillImageCount: Int { 0 }
  public var isLensStabilizationDuringBracketedCaptureSupported: Bool { false }
  public var isLensStabilizationDuringBracketedCaptureEnabled: Bool {
      get { storedLensStabilization }
      set { storedLensStabilization = newValue }
    }
  public func captureStillImageAsynchronously(
    from connection: AVCaptureConnection,
    completionHandler handler: @escaping (CMSampleBuffer?, (any Error)?) -> Void
  ) {
    _ = connection
    handler(nil, AVError(.applicationIsNotAuthorizedToUseDevice))
  }
  public func captureStillImageBracketAsynchronously(
    from connection: AVCaptureConnection,
    withSettingsArray settings: [AVCaptureBracketedStillImageSettings],
    completionHandler handler: @escaping (CMSampleBuffer?, AVCaptureBracketedStillImageSettings?, (any Error)?) -> Void
  ) {
    _ = (connection, settings)
    handler(nil, nil, AVError(.applicationIsNotAuthorizedToUseDevice))
  }
  public func prepareToCaptureStillImageBracket(
    from connection: AVCaptureConnection,
    withSettingsArray settings: [AVCaptureBracketedStillImageSettings],
    completionHandler handler: @escaping (Bool, (any Error)?) -> Void
  ) {
    _ = (connection, settings)
    handler(false, AVError(.applicationIsNotAuthorizedToUseDevice))
  }
}

open class AVCaptureSynchronizedData: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var timestamp: CMTime { .zero }
}

open class AVCaptureSynchronizedDataCollection: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public struct Iterator: Sendable {
    public init() {}
    public mutating func next() -> AVCaptureSynchronizedData? { nil }
    public typealias Element = AVCaptureSynchronizedData
  }
  public func makeIterator() -> AVCaptureSynchronizedDataCollection.Iterator { AVCaptureSynchronizedDataCollection.Iterator() }
  public typealias Element = AVCaptureSynchronizedData
  public func synchronizedData(for captureOutput: AVCaptureOutput) -> AVCaptureSynchronizedData? { nil }
  public subscript(key: AVCaptureOutput) -> AVCaptureSynchronizedData? { nil }
  public var count: Int { 0 }
}

open class AVCaptureSynchronizedDepthData: AVCaptureSynchronizedData, @unchecked Sendable {
  public override init() { super.init() }
  public var depthData: AVDepthData { AVDepthData() }
  public var depthDataWasDropped: Bool { false }
  public var droppedReason: AVCaptureOutput.DataDroppedReason { AVCaptureOutput.DataDroppedReason(rawValue: 0)! }
}

open class AVCaptureSynchronizedMetadataObjectData: AVCaptureSynchronizedData, @unchecked Sendable {
  public override init() { super.init() }
  public var metadataObjects: [AVMetadataObject] { [] }
}

open class AVCaptureSynchronizedSampleBufferData: AVCaptureSynchronizedData, @unchecked Sendable {
  public override init() { super.init() }
  public var sampleBuffer: CMSampleBuffer { CMSampleBuffer() }
  public var sampleBufferWasDropped: Bool { false }
  public var droppedReason: AVCaptureOutput.DataDroppedReason { AVCaptureOutput.DataDroppedReason(rawValue: 0)! }
}

open class AVCaptureSystemExposureBiasSlider: AVCaptureControl, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(device: AVCaptureDevice) { self.init() }
  convenience init(device: AVCaptureDevice, action: @escaping (Float) -> Void) { self.init() }
}

open class AVCaptureSystemZoomSlider: AVCaptureControl, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(device: AVCaptureDevice) { self.init() }
  convenience init(device: AVCaptureDevice, action: @escaping (CGFloat) -> Void) { self.init() }
}

public struct AVCaptureTimecode: Sendable {
  public init() {}
  public init(hours: UInt8, minutes: UInt8, seconds: UInt8, frames: UInt8, userBits: UInt32, frameDuration: CMTime, sourceType: AVCaptureTimecode.SourceType) {}
  public var hours: UInt8 = 0
  public var minutes: UInt8 = 0
  public var seconds: UInt8 = 0
  public var frames: UInt8 = 0
  public var userBits: UInt32 = 0
  public var frameDuration: CMTime = .zero
  public var sourceType: AVCaptureTimecode.SourceType = AVCaptureTimecode.SourceType(rawValue: 0)!
  public static func createMetadataSampleBuffer(from timecode: AVCaptureTimecode, associatedWithPresentationTimeStamp presentationTimeStamp: CMTime) -> Unmanaged<CMSampleBuffer>? { nil }
  public static func createMetadataSampleBuffer(from timecode: AVCaptureTimecode, forDuration duration: CMTime) -> Unmanaged<CMSampleBuffer>? { nil }
  public static func advanced(_ timecode: AVCaptureTimecode, by framesToAdd: Int64) -> AVCaptureTimecode { AVCaptureTimecode() }
  open class Source: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public var displayName: String { "" }
    public var type: AVCaptureTimecode.SourceType { AVCaptureTimecode.SourceType(rawValue: 0)! }
    public var uuid: UUID { UUID() }
  }
  public enum SourceType: Int, Hashable, Sendable {
    case frameCount = 0
    case realTimeClock = 1
    case external = 2
  }
}

open class AVCaptureTimecodeGenerator: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public enum SynchronizationStatus: Int, Hashable, Sendable {
    case unknown = 0
    case sourceSelected = 1
    case synchronizing = 2
    case synchronized = 3
    case timedOut = 4
    case sourceUnavailable = 5
    case sourceUnsupported = 6
    case notRequired = 7
  }
  public var availableSources: [AVCaptureTimecode.Source] { [] }
  public var currentSource: AVCaptureTimecode.Source { AVCaptureTimecode.Source() }
  public var delegate: (any AVCaptureTimecodeGeneratorDelegate)? { nil }
  public var delegateCallbackQueue: DispatchQueue? { nil }
  public func setDelegate(_ delegate: (any AVCaptureTimecodeGeneratorDelegate)?, queue callbackQueue: DispatchQueue?) {}
  public var synchronizationTimeout: TimeInterval {
      get { 0 }
      set { _ = newValue }
    }
  public var timecodeAlignmentOffset: TimeInterval {
      get { 0 }
      set { _ = newValue }
    }
  public var timecodeFrameDuration: CMTime {
      get { .zero }
      set { _ = newValue }
    }
  public func startSynchronization(source: AVCaptureTimecode.Source) {}
  public func generateInitialTimecode() -> AVCaptureTimecode { AVCaptureTimecode() }
  public class var frameCountSource: AVCaptureTimecode.Source { AVCaptureTimecode.Source() }
  public class var realTimeClockSource: AVCaptureTimecode.Source { AVCaptureTimecode.Source() }
}

public protocol AVCaptureTimecodeGeneratorDelegate : AnyObject {
  func timecodeGenerator(_ generator: AVCaptureTimecodeGenerator, didReceiveUpdate timecode: AVCaptureTimecode, from source: AVCaptureTimecode.Source)
  func timecodeGenerator(_ generator: AVCaptureTimecodeGenerator, transitionedTo synchronizationStatus: AVCaptureTimecodeGenerator.SynchronizationStatus, for source: AVCaptureTimecode.Source)
  func timecodeGenerator(_ generator: AVCaptureTimecodeGenerator, didUpdateAvailableSources availableSources: [AVCaptureTimecode.Source])
}

open class AVCaptureVideoDataOutput: AVCaptureOutput, @unchecked Sendable {
  public override init() { super.init() }
  private var storedVideoSettings: [String : Any] = [:]
  private var storedAlwaysDiscardsLateVideoFrames = true
  private var storedAutomaticallyConfiguresOutputBufferDimensions = true
  private var storedDeliversPreviewSizedOutputBuffers = false
  private var storedPreparesCellularRadioForNetworkConnection = false
  private var storedPreservesDynamicHDRMetadata = false
  weak var storedSampleBufferDelegate: (any AVCaptureVideoDataOutputSampleBufferDelegate)?
  var storedSampleBufferCallbackQueue: DispatchQueue?
  public var availableVideoPixelFormatTypes: [OSType] { [] }
  public func setSampleBufferDelegate(_ sampleBufferDelegate: (any AVCaptureVideoDataOutputSampleBufferDelegate)?, queue sampleBufferCallbackQueue: DispatchQueue?) {
    storedSampleBufferDelegate = sampleBufferDelegate
    storedSampleBufferCallbackQueue = sampleBufferCallbackQueue
  }
  public var sampleBufferDelegate: (any AVCaptureVideoDataOutputSampleBufferDelegate)? { storedSampleBufferDelegate }
  public var sampleBufferCallbackQueue: DispatchQueue? { storedSampleBufferCallbackQueue }
  public var videoSettings: [String : Any]! {
      get { storedVideoSettings }
      set { storedVideoSettings = newValue ?? [:] }
    }
  public func recommendedVideoSettingsForAssetWriter(writingTo outputFileType: AVFileType) -> [String : Any]? {
    _ = outputFileType
    return nil
  }
  public func availableVideoCodecTypesForAssetWriter(writingTo outputFileType: AVFileType) -> [AVVideoCodecType] {
    _ = outputFileType
    return []
  }
  public func recommendedVideoSettings(forVideoCodecType videoCodecType: AVVideoCodecType, assetWriterOutputFileType outputFileType: AVFileType) -> [String : Any]? {
    _ = (videoCodecType, outputFileType)
    return nil
  }
  public func recommendedVideoSettings(forVideoCodecType videoCodecType: AVVideoCodecType, assetWriterOutputFileType outputFileType: AVFileType, outputFileURL: URL?) -> [String : Any]? {
    _ = (videoCodecType, outputFileType, outputFileURL)
    return nil
  }
  public func recommendedMovieMetadata(forVideoCodecType videoCodecType: AVVideoCodecType, assetWriterOutputFileType outputFileType: AVFileType) -> [AVMetadataItem]? {
    _ = (videoCodecType, outputFileType)
    return nil
  }
  public var recommendedMediaTimeScaleForAssetWriter: CMTimeScale { 0 }
  public var availableVideoCodecTypes: [AVVideoCodecType] { [] }
  public var alwaysDiscardsLateVideoFrames: Bool {
      get { storedAlwaysDiscardsLateVideoFrames }
      set { storedAlwaysDiscardsLateVideoFrames = newValue }
    }
  public var automaticallyConfiguresOutputBufferDimensions: Bool {
      get { storedAutomaticallyConfiguresOutputBufferDimensions }
      set { storedAutomaticallyConfiguresOutputBufferDimensions = newValue }
    }
  public var deliversPreviewSizedOutputBuffers: Bool {
      get { storedDeliversPreviewSizedOutputBuffers }
      set { storedDeliversPreviewSizedOutputBuffers = newValue }
    }
  public var preparesCellularRadioForNetworkConnection: Bool {
      get { storedPreparesCellularRadioForNetworkConnection }
      set { storedPreparesCellularRadioForNetworkConnection = newValue }
    }
  public var preservesDynamicHDRMetadata: Bool {
      get { storedPreservesDynamicHDRMetadata }
      set { storedPreservesDynamicHDRMetadata = newValue }
    }
}

public protocol AVCaptureVideoDataOutputSampleBufferDelegate : AnyObject {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
  func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
}

public enum AVCaptureVideoOrientation: Int, Hashable, Sendable {
  case portrait = 0
  case portraitUpsideDown = 1
  case landscapeRight = 2
  case landscapeLeft = 3
}

public enum AVCaptureVideoStabilizationMode: Int, Hashable, Sendable {
  case off = 0
  case standard = 1
  case cinematic = 2
  case cinematicExtended = 3
  case previewOptimized = 4
  case cinematicExtendedEnhanced = 5
  case lowLatency = 6
  case auto = 7
}

open class AVDepthData: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public enum Accuracy: Int, Hashable, Sendable {
    case relative = 0
    case absolute = 1
  }
  public enum Quality: Int, Hashable, Sendable {
    case low = 0
    case high = 1
  }
  public var availableDepthDataTypes: [OSType] { [] }
  convenience init(fromDictionaryRepresentation imageSourceAuxDataInfoDictionary: [AnyHashable : Any]) throws { throw AVFoundationPortableError.mediaServiceUnavailable }
  public func replacingDepthDataMap(with pixelBuffer: CVPixelBuffer) throws -> Self { throw AVFoundationPortableError.mediaServiceUnavailable }
  public var depthDataMap: CVPixelBuffer { CVPixelBuffer() }
  public var depthDataQuality: AVDepthData.Quality { AVDepthData.Quality(rawValue: 0)! }
  public var isDepthDataFiltered: Bool { false }
  public var depthDataAccuracy: AVDepthData.Accuracy { AVDepthData.Accuracy(rawValue: 0)! }
  public var cameraCalibrationData: AVCameraCalibrationData? { nil }
}

open class AVSemanticSegmentationMatte: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public struct MatteType: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
    public static let skin = MatteType(rawValue: "skin")
    public static let hair = MatteType(rawValue: "hair")
    public static let teeth = MatteType(rawValue: "teeth")
    public static let glasses = MatteType(rawValue: "glasses")
  }
  public var matteType: AVSemanticSegmentationMatte.MatteType { AVSemanticSegmentationMatte.MatteType(rawValue: "") }
  public func replacingSemanticSegmentationMatte(with pixelBuffer: CVPixelBuffer) throws -> Self { throw AVFoundationPortableError.mediaServiceUnavailable }
  public var mattingImage: CVPixelBuffer { CVPixelBuffer() }
}
