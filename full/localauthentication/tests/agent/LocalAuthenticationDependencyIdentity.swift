import Foundation
import LocalAuthentication

/// Isolated-host identity probe. Real Foundation values pass through
/// LocalAuthentication APIs. The sealed host gate does not compile this file.
func localAuthenticationDependencyIdentityProbe() {
    LocalAuthenticationTestHook.setSimulatedDevicePasscodeEnabled(false)
    let context = LAContext()
    let reason: String = "dependency-identity"
    context.localizedReason = reason
    precondition(context.localizedReason == reason)

    let cancel: String? = "Cancel"
    context.localizedCancelTitle = cancel
    precondition(context.localizedCancelTitle == cancel)

    let fallback: String? = "Fallback"
    context.localizedFallbackTitle = fallback
    precondition(context.localizedFallbackTitle == fallback)

    let reuse: TimeInterval = 0
    context.touchIDAuthenticationAllowableReuseDuration = reuse
    precondition(context.touchIDAuthenticationAllowableReuseDuration == reuse)

    let failures: NSNumber? = NSNumber(value: 3)
    context.maxBiometryFailures = failures
    precondition(context.maxBiometryFailures == failures)

    let password = Data([0x70, 0x69, 0x6E])
    precondition(context.setCredential(password, type: .applicationPassword))
    precondition(context.isCredentialSet(.applicationPassword))

    var typed: LAError?
    precondition(!context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &typed))
    precondition(typed?.code == .passcodeNotSet)
    precondition(typed?._nsError.domain == "com.apple.LocalAuthentication")

    let domain: String = LAErrorDomain
    precondition(domain == "com.apple.LocalAuthentication")
    let bridged = LAError(.userCancel, userInfo: ["foundation": domain])
    precondition(bridged.userInfo["foundation"] as? String == domain)
    let ns = bridged as NSError
    precondition(ns.domain == LAErrorDomain)
}

#if LOCALAUTHENTICATION_IDENTITY_MAIN
localAuthenticationDependencyIdentityProbe()
print("LOCALAUTHENTICATION_DEPENDENCY_IDENTITY_OK")
#endif
