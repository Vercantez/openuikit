import Foundation

/// Numeric codes follow the public `RPError.h` `NS_ERROR_ENUM` reconstruction
/// used by header translators (objc2-replay-kit). Confirm against Xcode 26.1
/// before treating values as ABI-frozen.
public enum RPRecordingErrorCode: Int, Error, Sendable, Equatable, Hashable {
    case unknown = -5800
    case userDeclined = -5801
    case disabled = -5802
    case failedToStart = -5803
    case failed = -5804
    case insufficientStorage = -5805
    case interrupted = -5806
    case contentResize = -5807
    case broadcastInvalidSession = -5808
    case systemDormancy = -5809
    case entitlements = -5810
    case activePhoneCall = -5811
    case failedToSave = -5812
    case carPlay = -5813
    case failedApplicationConnectionInvalid = -5814
    case failedApplicationConnectionInterrupted = -5815
    case failedNoMatchingApplicationContext = -5816
    case failedMediaServicesFailure = -5817
    case videoMixingFailure = -5818
    case broadcastSetupFailed = -5819
    case failedToObtainURL = -5820
    case failedIncorrectTimeStamps = -5821
    case failedToProcessFirstSample = -5822
    case failedAssetWriterFailedToSave = -5823
    case failedNoAssetWriter = -5824
    case failedAssetWriterInWrongState = -5825
    case failedAssetWriterExportFailed = -5826
    case failedToRemoveFile = -5827
    case failedAssetWriterExportCanceled = -5828
    case attemptToStopNonRecording = -5829
    case attemptToStartInRecordingState = -5830
    case photoFailure = -5831
    case recordingInvalidSession = -5832
    case failedToStartCaptureStack = -5833
    case invalidParameter = -5834
    case filePermissions = -5835
    case exportClipToURLInProgress = -5836
    case codeSuccessful = 0
}

extension RPRecordingErrorCode: CustomNSError {
    public static var errorDomain: String { RPRecordingErrorDomain }

    public var errorCode: Int { rawValue }

    public var errorUserInfo: [String: Any] { [:] }
}

func replayKitUnavailableError(
    _ code: RPRecordingErrorCode = .failedToStartCaptureStack
) -> RPRecordingErrorCode {
    code
}
