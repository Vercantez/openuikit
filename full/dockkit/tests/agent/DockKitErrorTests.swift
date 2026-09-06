import Foundation
import DockKit

func testDockKitErrorCases() {
    let cases: [DockKitError] = [
        .notSupported,
        .notConnected,
        .notSupportedByDevice,
        .invalidParameter,
        .noSubjectFound,
        .frameRateTooLow,
        .cameraTCCMissing,
        .frameRateTooHigh,
    ]
    precondition(cases.count == 8)
    precondition(DockKitError.notSupported != .notConnected)
    precondition(DockKitError.notSupportedByDevice != .invalidParameter)
    precondition(DockKitError.noSubjectFound != .frameRateTooLow)
    precondition(DockKitError.cameraTCCMissing != .frameRateTooHigh)
}

func testDockKitErrorEqualityAndHash() {
    let a = DockKitError.notSupported
    let b = DockKitError.notSupported
    let c = DockKitError.notConnected
    precondition(a == b)
    precondition(a != c)
    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    b.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == b.hashValue)
}

func testDockKitErrorDescriptions() {
    let error = DockKitError.notSupported
    precondition(error.errorDescription == "DockKit is not supported on this platform.")
    precondition(error.failureReason == nil)
    precondition(error.helpAnchor == nil)
    precondition(error.recoverySuggestion == nil)
    precondition(error.localizedDescription == error.errorDescription)

    precondition(DockKitError.notConnected.errorDescription != nil)
    precondition(DockKitError.notSupportedByDevice.errorDescription != nil)
    precondition(DockKitError.invalidParameter.errorDescription == "A DockKit parameter is invalid.")
    precondition(DockKitError.noSubjectFound.errorDescription != nil)
    precondition(DockKitError.frameRateTooLow.errorDescription != nil)
    precondition(DockKitError.cameraTCCMissing.errorDescription != nil)
    precondition(DockKitError.frameRateTooHigh.errorDescription != nil)
}
