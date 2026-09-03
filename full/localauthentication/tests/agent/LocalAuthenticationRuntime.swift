import Foundation
import LocalAuthentication

/// Schema-v2 host compilation uses `*Tests.swift` plus a generated runner.
/// This probe remains for schema-v1-style / later EC2 invocation and is not
/// compiled by `tests/acceptance/test_host.sh`.
func localAuthenticationRuntimeProbe() {
    precondition(LAErrorDomain == "LAErrorDomain")
    precondition(LAPolicy.deviceOwnerAuthentication.rawValue == 2)
    let context = LAContext()
    var error: LAError?
    precondition(
        !context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
    )
    precondition(error?.code == .biometryNotAvailable)
    precondition(context.biometryType == .none)
}
