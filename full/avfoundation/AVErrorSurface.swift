import Foundation

public struct AVError: Error, @unchecked Sendable {
  public let code: Code
  public let userInfo: [String: Any]
  public init(_ code: Code, userInfo: [String: Any] = [:]) {
    self.code = code
    self.userInfo = userInfo
  }
  public var errorCode: Int { code.rawValue }
  public var errorUserInfo: [String: Any] { userInfo }
  public var localizedDescription: String { "AVError.\(code)" }
  public static var errorDomain: String { AVFoundationErrorDomain }
  public var device: String? { userInfo[AVErrorDeviceKey] as? String }
  public var time: CMTime? { userInfo[AVErrorTimeKey] as? CMTime }
  public var fileSize: Int64? { userInfo[AVErrorFileSizeKey] as? Int64 }
  public var processID: Int? { userInfo[AVErrorPIDKey] as? Int }
  public var recordingSuccessfullyFinished: Bool? { userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool }
  public var mediaType: String? { userInfo[AVErrorMediaTypeKey] as? String }
  public var mediaSubtypes: [Int]? { userInfo[AVErrorMediaSubTypeKey] as? [Int] }
  public var presentationTimeStamp: CMTime? { userInfo[AVErrorPresentationTimeStampKey] as? CMTime }
  public var persistentTrackID: CMPersistentTrackID? { userInfo[AVErrorPersistentTrackIDKey] as? CMPersistentTrackID }
  public var fileType: AVFileType? { userInfo[AVErrorFileTypeKey] as? AVFileType }
  public enum Code: Int, Hashable, Sendable {
    case unknown = -11800
    case outOfMemory = -11801
    case sessionNotRunning = -11803
    case deviceAlreadyUsedByAnotherSession = -11804
    case noDataCaptured = -11805
    case sessionConfigurationChanged = -11806
    case diskFull = -11807
    case deviceWasDisconnected = -11808
    case mediaChanged = -11809
    case maximumDurationReached = -11810
    case maximumFileSizeReached = -11811
    case mediaDiscontinuity = -11812
    case maximumNumberOfSamplesForFileFormatReached = -11813
    case deviceNotConnected = -11814
    case deviceInUseByAnotherApplication = -11815
    case deviceLockedForConfigurationByAnotherProcess = -11817
    case sessionWasInterrupted = -11818
    case mediaServicesWereReset = -11819
    case exportFailed = -11820
    case decodeFailed = -11821
    case invalidSourceMedia = -11822
    case fileAlreadyExists = -11823
    case compositionTrackSegmentsNotContiguous = -11824
    case invalidCompositionTrackSegmentDuration = -11825
    case invalidCompositionTrackSegmentSourceStartTime = -11826
    case invalidCompositionTrackSegmentSourceDuration = -11827
    case fileFormatNotRecognized = -11828
    case fileFailedToParse = -11829
    case maximumStillImageCaptureRequestsExceeded = -11830
    case contentIsProtected = -11831
    case noImageAtTime = -11832
    case decoderNotFound = -11833
    case encoderNotFound = -11834
    case contentIsNotAuthorized = -11835
    case applicationIsNotAuthorized = -11836
    case deviceIsNotAvailableInBackground = -11837
    case operationNotSupportedForAsset = -11838
    case decoderTemporarilyUnavailable = -11839
    case encoderTemporarilyUnavailable = -11840
    case invalidVideoComposition = -11841
    case referenceForbiddenByReferencePolicy = -11842
    case invalidOutputURLPathExtension = -11843
    case screenCaptureFailed = -11844
    case displayWasDisabled = -11845
    case torchLevelUnavailable = -11846
    case operationInterrupted = -11847
    case incompatibleAsset = -11848
    case failedToLoadMediaData = -11849
    case serverIncorrectlyConfigured = -11850
    case applicationIsNotAuthorizedToUseDevice = -11852
    case failedToParse = -11853
    case fileTypeDoesNotSupportSampleReferences = -11854
    case undecodableMediaData = -11855
    case airPlayControllerRequiresInternet = -11856
    case airPlayReceiverRequiresInternet = -11857
    case videoCompositorFailed = -11858
    case recordingAlreadyInProgress = -11859
    case unsupportedOutputSettings = -11861
    case operationNotAllowed = -11862
    case contentIsUnavailable = -11863
    case formatUnsupported = -11864
    case malformedDepth = -11865
    case contentNotUpdated = -11866
    case noLongerPlayable = -11867
    case noCompatibleAlternatesForExternalDisplay = -11868
    case noSourceTrack = -11869
    case externalPlaybackNotSupportedForAsset = -11870
    case operationNotSupportedForPreset = -11871
    case sessionHardwareCostOverage = -11872
    case unsupportedDeviceActiveFormat = -11873
    case incorrectlyConfigured = -11875
    case segmentStartedWithNonSyncSample = -11876
    case rosettaNotInstalled = -11877
    case operationCancelled = -11878
    case contentKeyRequestCancelled = -11879
    case invalidSampleCursor = -11880
    case failedToLoadSampleData = -11881
    case airPlayReceiverTemporarilyUnavailable = -11882
    case encodeFailed = -11883
    case sandboxExtensionDenied = -11884
    case toneMappingFailed = -11885
    case noSmartFramingsEnabled = -11890
    case autoWhiteBalanceNotLocked = -11891
    case followExternalSyncDeviceTimedOut = -11892
  }
  public static var unknown: Code { .unknown }
  public static var outOfMemory: Code { .outOfMemory }
  public static var sessionNotRunning: Code { .sessionNotRunning }
  public static var deviceAlreadyUsedByAnotherSession: Code { .deviceAlreadyUsedByAnotherSession }
  public static var noDataCaptured: Code { .noDataCaptured }
  public static var sessionConfigurationChanged: Code { .sessionConfigurationChanged }
  public static var diskFull: Code { .diskFull }
  public static var deviceWasDisconnected: Code { .deviceWasDisconnected }
  public static var mediaChanged: Code { .mediaChanged }
  public static var maximumDurationReached: Code { .maximumDurationReached }
  public static var maximumFileSizeReached: Code { .maximumFileSizeReached }
  public static var mediaDiscontinuity: Code { .mediaDiscontinuity }
  public static var maximumNumberOfSamplesForFileFormatReached: Code { .maximumNumberOfSamplesForFileFormatReached }
  public static var deviceNotConnected: Code { .deviceNotConnected }
  public static var deviceInUseByAnotherApplication: Code { .deviceInUseByAnotherApplication }
  public static var deviceLockedForConfigurationByAnotherProcess: Code { .deviceLockedForConfigurationByAnotherProcess }
  public static var sessionWasInterrupted: Code { .sessionWasInterrupted }
  public static var mediaServicesWereReset: Code { .mediaServicesWereReset }
  public static var exportFailed: Code { .exportFailed }
  public static var decodeFailed: Code { .decodeFailed }
  public static var invalidSourceMedia: Code { .invalidSourceMedia }
  public static var fileAlreadyExists: Code { .fileAlreadyExists }
  public static var compositionTrackSegmentsNotContiguous: Code { .compositionTrackSegmentsNotContiguous }
  public static var invalidCompositionTrackSegmentDuration: Code { .invalidCompositionTrackSegmentDuration }
  public static var invalidCompositionTrackSegmentSourceStartTime: Code { .invalidCompositionTrackSegmentSourceStartTime }
  public static var invalidCompositionTrackSegmentSourceDuration: Code { .invalidCompositionTrackSegmentSourceDuration }
  public static var fileFormatNotRecognized: Code { .fileFormatNotRecognized }
  public static var fileFailedToParse: Code { .fileFailedToParse }
  public static var maximumStillImageCaptureRequestsExceeded: Code { .maximumStillImageCaptureRequestsExceeded }
  public static var contentIsProtected: Code { .contentIsProtected }
  public static var noImageAtTime: Code { .noImageAtTime }
  public static var decoderNotFound: Code { .decoderNotFound }
  public static var encoderNotFound: Code { .encoderNotFound }
  public static var contentIsNotAuthorized: Code { .contentIsNotAuthorized }
  public static var applicationIsNotAuthorized: Code { .applicationIsNotAuthorized }
  public static var deviceIsNotAvailableInBackground: Code { .deviceIsNotAvailableInBackground }
  public static var operationNotSupportedForAsset: Code { .operationNotSupportedForAsset }
  public static var decoderTemporarilyUnavailable: Code { .decoderTemporarilyUnavailable }
  public static var encoderTemporarilyUnavailable: Code { .encoderTemporarilyUnavailable }
  public static var invalidVideoComposition: Code { .invalidVideoComposition }
  public static var referenceForbiddenByReferencePolicy: Code { .referenceForbiddenByReferencePolicy }
  public static var invalidOutputURLPathExtension: Code { .invalidOutputURLPathExtension }
  public static var screenCaptureFailed: Code { .screenCaptureFailed }
  public static var displayWasDisabled: Code { .displayWasDisabled }
  public static var torchLevelUnavailable: Code { .torchLevelUnavailable }
  public static var operationInterrupted: Code { .operationInterrupted }
  public static var incompatibleAsset: Code { .incompatibleAsset }
  public static var failedToLoadMediaData: Code { .failedToLoadMediaData }
  public static var serverIncorrectlyConfigured: Code { .serverIncorrectlyConfigured }
  public static var applicationIsNotAuthorizedToUseDevice: Code { .applicationIsNotAuthorizedToUseDevice }
  public static var failedToParse: Code { .failedToParse }
  public static var fileTypeDoesNotSupportSampleReferences: Code { .fileTypeDoesNotSupportSampleReferences }
  public static var undecodableMediaData: Code { .undecodableMediaData }
  public static var airPlayControllerRequiresInternet: Code { .airPlayControllerRequiresInternet }
  public static var airPlayReceiverRequiresInternet: Code { .airPlayReceiverRequiresInternet }
  public static var videoCompositorFailed: Code { .videoCompositorFailed }
  public static var recordingAlreadyInProgress: Code { .recordingAlreadyInProgress }
  public static var unsupportedOutputSettings: Code { .unsupportedOutputSettings }
  public static var operationNotAllowed: Code { .operationNotAllowed }
  public static var contentIsUnavailable: Code { .contentIsUnavailable }
  public static var formatUnsupported: Code { .formatUnsupported }
  public static var malformedDepth: Code { .malformedDepth }
  public static var contentNotUpdated: Code { .contentNotUpdated }
  public static var noLongerPlayable: Code { .noLongerPlayable }
  public static var noCompatibleAlternatesForExternalDisplay: Code { .noCompatibleAlternatesForExternalDisplay }
  public static var noSourceTrack: Code { .noSourceTrack }
  public static var externalPlaybackNotSupportedForAsset: Code { .externalPlaybackNotSupportedForAsset }
  public static var operationNotSupportedForPreset: Code { .operationNotSupportedForPreset }
  public static var sessionHardwareCostOverage: Code { .sessionHardwareCostOverage }
  public static var unsupportedDeviceActiveFormat: Code { .unsupportedDeviceActiveFormat }
  public static var incorrectlyConfigured: Code { .incorrectlyConfigured }
  public static var segmentStartedWithNonSyncSample: Code { .segmentStartedWithNonSyncSample }
  public static var rosettaNotInstalled: Code { .rosettaNotInstalled }
  public static var operationCancelled: Code { .operationCancelled }
  public static var contentKeyRequestCancelled: Code { .contentKeyRequestCancelled }
  public static var invalidSampleCursor: Code { .invalidSampleCursor }
  public static var failedToLoadSampleData: Code { .failedToLoadSampleData }
  public static var airPlayReceiverTemporarilyUnavailable: Code { .airPlayReceiverTemporarilyUnavailable }
  public static var encodeFailed: Code { .encodeFailed }
  public static var sandboxExtensionDenied: Code { .sandboxExtensionDenied }
  public static var toneMappingFailed: Code { .toneMappingFailed }
  public static var noSmartFramingsEnabled: Code { .noSmartFramingsEnabled }
  public static var autoWhiteBalanceNotLocked: Code { .autoWhiteBalanceNotLocked }
  public static var followExternalSyncDeviceTimedOut: Code { .followExternalSyncDeviceTimedOut }
}
extension AVError: Hashable {
  public static func == (lhs: AVError, rhs: AVError) -> Bool { lhs.code == rhs.code }
  public func hash(into hasher: inout Hasher) { hasher.combine(code) }
}

extension AVError: CustomNSError {}
