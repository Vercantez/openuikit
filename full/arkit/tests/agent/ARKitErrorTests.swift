import Foundation
import ARKit

func testARErrorCodesAndDomain() {
    arkitRequire(ARErrorDomain == "com.apple.arkit.error", "ARErrorDomain string")
    arkitRequire(ARError.errorDomain == ARErrorDomain, "CustomNSError domain")
    let codes: [(ARError.Code, Int)] = [
        (.unsupportedConfiguration, 100),
        (.sensorUnavailable, 101),
        (.sensorFailed, 102),
        (.cameraUnauthorized, 103),
        (.microphoneUnauthorized, 104),
        (.locationUnauthorized, 105),
        (.highResolutionFrameCaptureInProgress, 106),
        (.highResolutionFrameCaptureFailed, 107),
        (.worldTrackingFailed, 200),
        (.geoTrackingNotAvailableAtLocation, 201),
        (.geoTrackingFailed, 202),
        (.invalidReferenceImage, 300),
        (.invalidReferenceObject, 301),
        (.invalidWorldMap, 302),
        (.invalidConfiguration, 303),
        (.invalidCollaborationData, 304),
        (.insufficientFeatures, 400),
        (.objectMergeFailed, 401),
        (.fileIOFailed, 500),
        (.requestFailed, 501),
    ]
    arkitRequire(codes.count == 20, "documented ARError.Code count")
    for (code, raw) in codes {
        arkitRequire(code.rawValue == raw, "raw \(raw)")
        arkitRequire(ARError.Code(rawValue: raw) == code, "init raw \(raw)")
    }
    arkitRequire(ARError.unsupportedConfiguration == .unsupportedConfiguration, "static unsupportedConfiguration")
    arkitRequire(ARError.sensorUnavailable == .sensorUnavailable, "static sensorUnavailable")
    arkitRequire(ARError.sensorFailed == .sensorFailed, "static sensorFailed")
    arkitRequire(ARError.cameraUnauthorized == .cameraUnauthorized, "static cameraUnauthorized")
    arkitRequire(ARError.microphoneUnauthorized == .microphoneUnauthorized, "static microphoneUnauthorized")
    arkitRequire(ARError.locationUnauthorized == .locationUnauthorized, "static locationUnauthorized")
    arkitRequire(ARError.highResolutionFrameCaptureInProgress == .highResolutionFrameCaptureInProgress, "static hi-res in progress")
    arkitRequire(ARError.highResolutionFrameCaptureFailed == .highResolutionFrameCaptureFailed, "static hi-res failed")
    arkitRequire(ARError.worldTrackingFailed == .worldTrackingFailed, "static worldTrackingFailed")
    arkitRequire(ARError.geoTrackingNotAvailableAtLocation == .geoTrackingNotAvailableAtLocation, "static geo not available")
    arkitRequire(ARError.geoTrackingFailed == .geoTrackingFailed, "static geoTrackingFailed")
    arkitRequire(ARError.invalidReferenceImage == .invalidReferenceImage, "static invalidReferenceImage")
    arkitRequire(ARError.invalidReferenceObject == .invalidReferenceObject, "static invalidReferenceObject")
    arkitRequire(ARError.invalidWorldMap == .invalidWorldMap, "static invalidWorldMap")
    arkitRequire(ARError.invalidConfiguration == .invalidConfiguration, "static invalidConfiguration")
    arkitRequire(ARError.invalidCollaborationData == .invalidCollaborationData, "static invalidCollaborationData")
    arkitRequire(ARError.insufficientFeatures == .insufficientFeatures, "static insufficientFeatures")
    arkitRequire(ARError.objectMergeFailed == .objectMergeFailed, "static objectMergeFailed")
    arkitRequire(ARError.fileIOFailed == .fileIOFailed, "static fileIOFailed")
    arkitRequire(ARError.requestFailed == .requestFailed, "static requestFailed")
}

func testARErrorValueSemantics() {
    let error = ARError(.sensorUnavailable, userInfo: [NSLocalizedDescriptionKey: "sensor"])
    arkitRequire(error.code == .sensorUnavailable, "code storage")
    arkitRequire(error.errorCode == 101, "errorCode")
    arkitRequire((error.errorUserInfo[NSLocalizedDescriptionKey] as? String) == "sensor", "errorUserInfo")
    arkitRequire((error.userInfo[NSLocalizedDescriptionKey] as? String) == "sensor", "userInfo")
    arkitRequire(error == ARError(.sensorUnavailable, userInfo: [NSLocalizedDescriptionKey: "sensor"]), "equality")
    arkitRequire(error != ARError(.sensorFailed), "inequality")
    arkitRequire(ARError.Code.sensorUnavailable ~= error, "pattern match")
    _ = error.hashValue
    var hasher = Hasher()
    error.hash(into: &hasher)
    ARError.Code.fileIOFailed.hash(into: &hasher)
    _ = ARError.Code.geoTrackingFailed.hashValue
    _ = error.localizedDescription
    arkitRequire(ARError(.unsupportedConfiguration) != ARError(.sensorFailed), "code inequality")
}
