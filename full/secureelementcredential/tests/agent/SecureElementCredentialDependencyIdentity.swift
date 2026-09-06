import Foundation
import SecureElementCredential

/// Isolated-host identity probe. The sealed host gate does not compile this
/// file. The later EC2 integration build imports real Foundation and passes
/// genuine Foundation values through public SecureElementCredential APIs.
func secureElementCredentialDependencyIdentityProbe() {
    let identifier = UUID()
    let aid = Data([0xA0, 0x00, 0x00, 0x00])
    let credential = CredentialSession.Credential(
        identifier: identifier,
        name: Bundle.main.bundleIdentifier ?? "linux.secureelementcredential",
        state: .installationPending
    )
    precondition(credential.identifier == identifier)
    precondition(credential.name == (Bundle.main.bundleIdentifier ?? "linux.secureelementcredential"))

    let info = CredentialSession.SecureElementInfo(
        hardwareReleaseVersionInfo: "linux-host",
        secureElementPlatformSigningCertificate: aid
    )
    precondition(info.secureElementPlatformSigningCertificate == aid)

    let options = CredentialSession.CardEmulationOptions()
    _ = options
    let alias: CardEmulationOptions = options
    _ = alias
}
