import Foundation
import SecureElementCredential

func testSecureElementInfoHardwareVersion() {
    let info = CredentialSession.SecureElementInfo(
        hardwareReleaseVersionInfo: "se-1.0",
        secureElementPlatformSigningCertificate: Data()
    )
    precondition(info.hardwareReleaseVersionInfo == "se-1.0")
}

func testSecureElementInfoCertificate() {
    let certificate = Data([0x30, 0x82, 0x01, 0x0A])
    let info = CredentialSession.SecureElementInfo(
        hardwareReleaseVersionInfo: "rel",
        secureElementPlatformSigningCertificate: certificate
    )
    precondition(info.secureElementPlatformSigningCertificate == certificate)
}

func testSecureElementInfoEncode() {
    let info = CredentialSession.SecureElementInfo(
        hardwareReleaseVersionInfo: "encode-me",
        secureElementPlatformSigningCertificate: Data([0xAB])
    )
    do {
        let data = try JSONEncoder().encode(info)
        precondition(!data.isEmpty)
    } catch {
        preconditionFailure("encode failed: \(error)")
    }
}

func testSecureElementInfoDecode() {
    let original = CredentialSession.SecureElementInfo(
        hardwareReleaseVersionInfo: "round-trip",
        secureElementPlatformSigningCertificate: Data([0x01, 0x02])
    )
    do {
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CredentialSession.SecureElementInfo.self, from: data)
        precondition(decoded.hardwareReleaseVersionInfo == "round-trip")
        precondition(decoded.secureElementPlatformSigningCertificate == Data([0x01, 0x02]))
    } catch {
        preconditionFailure("round-trip failed: \(error)")
    }
}

func testCardEmulationOptionsInit() {
    let options = CredentialSession.CardEmulationOptions()
    let again = CredentialSession.CardEmulationOptions.init()
    _ = options
    _ = again
}

func testCardEmulationOptionsTypealias() {
    let nested = CredentialSession.CardEmulationOptions()
    let aliased: CardEmulationOptions = nested
    _ = aliased
}
