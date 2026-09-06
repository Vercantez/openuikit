import Foundation
import ManagedAppDistribution

func testErrorCases() {
    let cases: [ManagedAppDistributionError] = [
        .unrecoverableError,
        .networkError,
        .deviceNotManaged,
        .unsupportedPlatform,
        .licenseNotFound,
        .appNotManaged,
    ]
    precondition(Set(cases).count == 6)
}

func testErrorDescriptionStrings() {
    let expected: [(ManagedAppDistributionError, String)] = [
        (.unrecoverableError, "An error that is unspecified and unrecoverable."),
        (.networkError, "An error that indicates a network issue."),
        (.deviceNotManaged, "An error that indicates this device isn't managed."),
        (.unsupportedPlatform, "An error that indicates the platform is unsupported."),
        (.licenseNotFound, "An error that indicates that a license wasn't found for requested app."),
        (.appNotManaged, "An error that indicates that the calling app is not managed"),
    ]
    for (error, text) in expected {
        precondition(error.description == text)
        precondition(error.errorDescription == text)
        precondition(error.failureReason == text)
    }
}

func testErrorRecoveryFailClosed() {
    let error = ManagedAppDistributionError.deviceNotManaged
    precondition(error.recoveryOptions.isEmpty)
    precondition(error.helpAnchor == nil)
    precondition(error.recoverySuggestion == nil)
    precondition(error.attemptRecovery(optionIndex: 0) == false)
    precondition(error.attemptRecovery(optionIndex: 99) == false)
}

func testErrorAttemptRecoveryHandler() {
    var delivered: Bool?
    ManagedAppDistributionError.networkError.attemptRecovery(optionIndex: 0) { recovered in
        delivered = recovered
    }
    precondition(delivered == false)
}

func testErrorCodableRoundTrip() {
    let cases: [ManagedAppDistributionError] = [
        .unrecoverableError,
        .networkError,
        .deviceNotManaged,
        .unsupportedPlatform,
        .licenseNotFound,
        .appNotManaged,
    ]
    for error in cases {
        let data = try! JSONEncoder().encode(error)
        let decoded = try! JSONDecoder().decode(ManagedAppDistributionError.self, from: data)
        precondition(decoded == error)
    }
}

func testErrorCodableRejectsUnknownCase() {
    let payload = Data(#"{"linuxCase":"not-a-real-case"}"#.utf8)
    do {
        _ = try JSONDecoder().decode(ManagedAppDistributionError.self, from: payload)
        preconditionFailure("unknown case must fail")
    } catch is DecodingError {
        // expected
    } catch {
        preconditionFailure("expected DecodingError")
    }
}

func testErrorHashableInequality() {
    precondition(ManagedAppDistributionError.networkError != .deviceNotManaged)
    precondition(!(ManagedAppDistributionError.appNotManaged != .appNotManaged))
    var hasher = Hasher()
    ManagedAppDistributionError.licenseNotFound.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(
        ManagedAppDistributionError.unsupportedPlatform.hashValue
            == ManagedAppDistributionError.unsupportedPlatform.hashValue
    )
}

func testErrorLocalizedDescription() {
    let error = ManagedAppDistributionError.unrecoverableError
    precondition(!error.localizedDescription.isEmpty)
    precondition(error.localizedDescription == error.description)
}

func testErrorLocalizedStringResource() {
    let error = ManagedAppDistributionError.deviceNotManaged
    precondition(error.localizedStringResource.key == error.description)
}
