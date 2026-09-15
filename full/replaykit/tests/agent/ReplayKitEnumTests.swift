import Foundation
import ReplayKit

private func rkEnumHashProbe<T: Hashable>(_ a: T, _ b: T) {
    precondition(a == a)
    precondition(a != b)
    precondition(a.hashValue == a.hashValue)
    var hasher = Hasher()
    a.hash(into: &hasher)
    b.hash(into: &hasher)
    _ = hasher.finalize()
    _ = a.hashValue
    _ = b.hashValue
}

func testRPCameraPositionValues() {
    precondition(RPCameraPosition.front == .front)
    precondition(RPCameraPosition.back == .back)
    precondition(RPCameraPosition.front != .back)
    precondition(RPCameraPosition.front.rawValue == 1)
    precondition(RPCameraPosition.back.rawValue == 2)
    precondition(RPCameraPosition(rawValue: 1) == .front)
    precondition(RPCameraPosition(rawValue: 2) == .back)
    precondition(RPCameraPosition(rawValue: 0) == nil)
    precondition(RPCameraPosition(rawValue: 99) == nil)
    rkEnumHashProbe(RPCameraPosition.front, RPCameraPosition.back)
}

func testRPSampleBufferTypeValues() {
    precondition(RPSampleBufferType.video == .video)
    precondition(RPSampleBufferType.audioApp == .audioApp)
    precondition(RPSampleBufferType.audioMic == .audioMic)
    precondition(RPSampleBufferType.video != .audioApp)
    precondition(RPSampleBufferType.audioApp != .audioMic)
    precondition(RPSampleBufferType.video != .audioMic)
    precondition(RPSampleBufferType.video.rawValue == 1)
    precondition(RPSampleBufferType.audioApp.rawValue == 2)
    precondition(RPSampleBufferType.audioMic.rawValue == 3)
    precondition(RPSampleBufferType(rawValue: 1) == .video)
    precondition(RPSampleBufferType(rawValue: 2) == .audioApp)
    precondition(RPSampleBufferType(rawValue: 3) == .audioMic)
    precondition(RPSampleBufferType(rawValue: 0) == nil)
    precondition(RPSampleBufferType(rawValue: 99) == nil)
    rkEnumHashProbe(RPSampleBufferType.video, RPSampleBufferType.audioApp)
    rkEnumHashProbe(RPSampleBufferType.audioApp, RPSampleBufferType.audioMic)
}

func testRPRecordingErrorCodeValues() {
    let table: [(RPRecordingErrorCode, Int)] = [
        (.codeSuccessful, 0),
        (.unknown, -5800),
        (.userDeclined, -5801),
        (.disabled, -5802),
        (.failedToStart, -5803),
        (.failed, -5804),
        (.insufficientStorage, -5805),
        (.interrupted, -5806),
        (.contentResize, -5807),
        (.broadcastInvalidSession, -5808),
        (.systemDormancy, -5809),
        (.entitlements, -5810),
        (.activePhoneCall, -5811),
        (.failedToSave, -5812),
        (.carPlay, -5813),
        (.failedApplicationConnectionInvalid, -5814),
        (.failedApplicationConnectionInterrupted, -5815),
        (.failedNoMatchingApplicationContext, -5816),
        (.failedMediaServicesFailure, -5817),
        (.videoMixingFailure, -5818),
        (.broadcastSetupFailed, -5819),
        (.failedToObtainURL, -5820),
        (.failedIncorrectTimeStamps, -5821),
        (.failedToProcessFirstSample, -5822),
        (.failedAssetWriterFailedToSave, -5823),
        (.failedNoAssetWriter, -5824),
        (.failedAssetWriterInWrongState, -5825),
        (.failedAssetWriterExportFailed, -5826),
        (.failedToRemoveFile, -5827),
        (.failedAssetWriterExportCanceled, -5828),
        (.attemptToStopNonRecording, -5829),
        (.attemptToStartInRecordingState, -5830),
        (.photoFailure, -5831),
        (.recordingInvalidSession, -5832),
        (.failedToStartCaptureStack, -5833),
        (.invalidParameter, -5834),
        (.filePermissions, -5835),
        (.exportClipToURLInProgress, -5836),
    ]
    precondition(table.count == 38)
    precondition(Set(table.map { $0.1 }).count == 38)
    var hasher = Hasher()
    for (code, raw) in table {
        precondition(code.rawValue == raw)
        precondition(RPRecordingErrorCode(rawValue: raw) == code)
        code.hash(into: &hasher)
        _ = code.hashValue
    }
    _ = hasher.finalize()
    precondition(RPRecordingErrorCode(rawValue: 0) == .codeSuccessful)
    precondition(RPRecordingErrorCode(rawValue: -5800) == .unknown)
    precondition(RPRecordingErrorCode(rawValue: -5836) == .exportClipToURLInProgress)
    precondition(RPRecordingErrorCode(rawValue: -1) == nil)
    precondition(RPRecordingErrorCode(rawValue: 1) == nil)
    precondition(RPRecordingErrorCode.unknown != .disabled)
    precondition(RPRecordingErrorCode.codeSuccessful != .unknown)
    rkEnumHashProbe(RPRecordingErrorCode.unknown, RPRecordingErrorCode.disabled)
    rkEnumHashProbe(RPRecordingErrorCode.codeSuccessful, RPRecordingErrorCode.entitlements)
}
