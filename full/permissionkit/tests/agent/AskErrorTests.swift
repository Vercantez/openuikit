import Foundation
import PermissionKit

func testAskErrorCases() {
    let unknown = AskError.unknown
    let invalid = AskError.invalidQuestion
    let sync = AskError.contactSyncNotSetup
    let limits = AskError.communicationLimitsNotEnabled
    let system = AskError.systemError(underlyingError: CocoaError(.fileNoSuchFile))
    switch unknown {
    case .unknown: break
    default: preconditionFailure("expected unknown")
    }
    switch invalid {
    case .invalidQuestion: break
    default: preconditionFailure("expected invalidQuestion")
    }
    switch sync {
    case .contactSyncNotSetup: break
    default: preconditionFailure("expected contactSyncNotSetup")
    }
    switch limits {
    case .communicationLimitsNotEnabled: break
    default: preconditionFailure("expected communicationLimitsNotEnabled")
    }
    switch system {
    case .systemError: break
    default: preconditionFailure("expected systemError")
    }
}

func testAskErrorErrorDescription() {
    precondition(AskError.unknown.errorDescription == "An unknown PermissionKit error occurred.")
    precondition(AskError.invalidQuestion.errorDescription == "The permission question is invalid.")
    precondition(AskError.contactSyncNotSetup.errorDescription == "Contact sync is not set up.")
    precondition(
        AskError.communicationLimitsNotEnabled.errorDescription
            == "Communication Limits are not enabled on this host."
    )
}

func testAskErrorLocalizedErrorDefaults() {
    let error = AskError.invalidQuestion
    precondition(error.failureReason == nil)
    precondition(error.recoverySuggestion == nil)
    precondition(error.helpAnchor == nil)
}

func testAskErrorLocalizedDescription() {
    let error: any Error = AskError.unknown
    precondition(error.localizedDescription == AskError.unknown.errorDescription)
}

func testAskErrorSystemErrorUnderlying() {
    let underlying = CocoaError(.featureUnsupported)
    let error = AskError.systemError(underlyingError: underlying)
    precondition(error.errorDescription == underlying.localizedDescription)
    if case .systemError(let wrapped) = error {
        precondition((wrapped as? CocoaError)?.code == .featureUnsupported)
    } else {
        preconditionFailure("expected systemError associated value")
    }
}
