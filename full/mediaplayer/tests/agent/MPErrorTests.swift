import Foundation
@_spi(OpenUIKitHost) import MediaPlayer

func testMPErrorCodes() {
    let codes: [(MPError.Code, Int)] = [
        (.unknown, 0),
        (.permissionDenied, 1),
        (.cloudServiceCapabilityMissing, 2),
        (.networkConnectionFailed, 3),
        (.notFound, 4),
        (.notSupported, 5),
        (.cancelled, 6),
        (.requestTimedOut, 7),
    ]
    for (code, raw) in codes {
        precondition(code.rawValue == raw)
        let error = MPError(code, userInfo: ["k": "v"])
        precondition(error.code == code)
        precondition(error.errorCode == raw)
        precondition(error.errorUserInfo["k"] as? String == "v")
        precondition(error == MPError(code))
        precondition(error != MPError(.unknown) || code == .unknown)
        precondition(code ~= error)
        let ns = error as NSError
        precondition(ns.domain == "MPErrorDomain")
        precondition(ns.code == raw)
        _ = error.localizedDescription
        _ = error.hashValue
        var hasher = Hasher()
        error.hash(into: &hasher)
        _ = hasher.finalize()
        var codeHasher = Hasher()
        code.hash(into: &codeHasher)
        _ = codeHasher.finalize()
        _ = code.hashValue
    }
    precondition(MPError.errorDomain == "MPErrorDomain")
    precondition(MPErrorDomain == "MPErrorDomain")
    precondition(MPError.unknown == .unknown)
    precondition(MPError.permissionDenied == .permissionDenied)
    precondition(MPError.cloudServiceCapabilityMissing == .cloudServiceCapabilityMissing)
    precondition(MPError.networkConnectionFailed == .networkConnectionFailed)
    precondition(MPError.notFound == .notFound)
    precondition(MPError.notSupported == .notSupported)
    precondition(MPError.cancelled == .cancelled)
    precondition(MPError.requestTimedOut == .requestTimedOut)
    let mismatch = MPError(.notSupported)
    precondition(!(MPError.cancelled ~= mismatch))
    precondition(MPError.Code(rawValue: 5) == .notSupported)
    precondition(MPError.Code(rawValue: 99) == nil)
}
