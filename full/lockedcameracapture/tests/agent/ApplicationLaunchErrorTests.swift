import Foundation
@_spi(OpenUIKitHost) import LockedCameraCapture

private typealias LaunchError = LockedCameraCaptureSession.ApplicationLaunchError

func testApplicationLaunchErrorType() {
    let values: [LaunchError] = [.unknown, .applicationNotFound, .authenticationFailed]
    precondition(values.count == 3)
    precondition(type(of: LaunchError.unknown) == LaunchError.self)
}

func testApplicationLaunchErrorCases() {
    let table: [(LaunchError, Int)] = [
        (.unknown, 0),
        (.applicationNotFound, 1),
        (.authenticationFailed, 2),
    ]
    precondition(Set(table.map(\.0)).count == 3)
    precondition(Set(table.map(\.1)).count == 3)
    for (value, _) in table {
        switch value {
        case .unknown, .applicationNotFound, .authenticationFailed:
            break
        }
    }
}

func testApplicationLaunchErrorErrorCode() {
    precondition(LaunchError.unknown.errorCode == 0)
    precondition(LaunchError.applicationNotFound.errorCode == 1)
    precondition(LaunchError.authenticationFailed.errorCode == 2)
    let nsUnknown = LaunchError.unknown as NSError
    precondition(nsUnknown.code == 0)
    let nsMissing = LaunchError.applicationNotFound as NSError
    precondition(nsMissing.code == 1)
    let nsAuth = LaunchError.authenticationFailed as NSError
    precondition(nsAuth.code == 2)
}

func testApplicationLaunchErrorErrorDomain() {
    precondition(LaunchError.errorDomain == "LockedCameraCaptureSession.ApplicationLaunchError")
    let nsError = LaunchError.unknown as NSError
    precondition(nsError.domain == LaunchError.errorDomain)
    let nsMissing = LaunchError.applicationNotFound as NSError
    precondition(nsMissing.domain == LaunchError.errorDomain)
}

func testApplicationLaunchErrorSynthesizedErrorDomain() {
    let viaProtocol: any CustomNSError = LaunchError.authenticationFailed
    precondition(type(of: viaProtocol).errorDomain == LaunchError.errorDomain)
    precondition(LaunchError.errorDomain == (LaunchError.unknown as NSError).domain)
}

func testApplicationLaunchErrorFailureReason() {
    precondition(LaunchError.unknown.failureReason == "The launch failed with an unknown error.")
    precondition(
        LaunchError.applicationNotFound.failureReason
            == "The launch failed because the system didn't find the application."
    )
    precondition(
        LaunchError.authenticationFailed.failureReason
            == "The launch failed because authentication failed and the device is locked."
    )
}

func testApplicationLaunchErrorErrorDescription() {
    let unknown: (any LocalizedError) = LaunchError.unknown
    precondition(unknown.errorDescription == nil)
    let missing: (any LocalizedError) = LaunchError.applicationNotFound
    precondition(missing.errorDescription == nil)
}

func testApplicationLaunchErrorRecoverySuggestion() {
    let unknown: (any LocalizedError) = LaunchError.unknown
    precondition(unknown.recoverySuggestion == nil)
    let auth: (any LocalizedError) = LaunchError.authenticationFailed
    precondition(auth.recoverySuggestion == nil)
}

func testApplicationLaunchErrorHelpAnchor() {
    let unknown: (any LocalizedError) = LaunchError.unknown
    precondition(unknown.helpAnchor == nil)
    let missing: (any LocalizedError) = LaunchError.applicationNotFound
    precondition(missing.helpAnchor == nil)
}

func testApplicationLaunchErrorErrorUserInfo() {
    let info = LaunchError.unknown.errorUserInfo
    precondition(info[NSLocalizedFailureReasonErrorKey] as? String == LaunchError.unknown.failureReason)
    let emptyKeys = LaunchError.applicationNotFound.errorUserInfo
    precondition(emptyKeys[NSLocalizedFailureReasonErrorKey] as? String != nil)
}

func testApplicationLaunchErrorEquality() {
    precondition(LaunchError.unknown == LaunchError.unknown)
    precondition(LaunchError.applicationNotFound == LaunchError.applicationNotFound)
    precondition(LaunchError.authenticationFailed == LaunchError.authenticationFailed)
    precondition(LaunchError.unknown != LaunchError.applicationNotFound)
    precondition(!(LaunchError.unknown == LaunchError.authenticationFailed))
}

func testApplicationLaunchErrorInequality() {
    precondition(LaunchError.unknown != LaunchError.applicationNotFound)
    precondition(LaunchError.applicationNotFound != LaunchError.authenticationFailed)
    precondition(!(LaunchError.unknown != LaunchError.unknown))
    precondition(!(LaunchError.authenticationFailed != LaunchError.authenticationFailed))
}

func testApplicationLaunchErrorHashInto() {
    var hasherA = Hasher()
    LaunchError.unknown.hash(into: &hasherA)
    var hasherB = Hasher()
    LaunchError.unknown.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())

    var hasherUnknown = Hasher()
    LaunchError.unknown.hash(into: &hasherUnknown)
    var hasherMissing = Hasher()
    LaunchError.applicationNotFound.hash(into: &hasherMissing)
    precondition(hasherUnknown.finalize() != hasherMissing.finalize())
}

func testApplicationLaunchErrorHashValue() {
    precondition(LaunchError.unknown.hashValue == LaunchError.unknown.hashValue)
    precondition(LaunchError.applicationNotFound.hashValue == LaunchError.applicationNotFound.hashValue)
    precondition(LaunchError.unknown.hashValue != LaunchError.applicationNotFound.hashValue)
    _ = LaunchError.authenticationFailed.hashValue
}

func testApplicationLaunchErrorLocalizedDescription() {
    let unknown = LaunchError.unknown.localizedDescription
    precondition(!unknown.isEmpty)
    let missing = LaunchError.applicationNotFound.localizedDescription
    precondition(!missing.isEmpty)
    let auth = LaunchError.authenticationFailed.localizedDescription
    precondition(!auth.isEmpty)
}
