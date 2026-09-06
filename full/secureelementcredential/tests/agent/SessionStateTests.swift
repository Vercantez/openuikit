import Foundation
import SecureElementCredential

func sampleCredential(_ name: String = "card") -> CredentialSession.Credential {
    CredentialSession.Credential(
        identifier: UUID(),
        name: name,
        state: .installationPending
    )
}

func testSessionStateCases() {
    let credential = sampleCredential()
    let states: [CredentialSession.State] = [
        .management,
        .cardEmulation(credential: credential),
        .wired(credential: credential),
        .invalid,
    ]
    precondition(states.count == 4)
    precondition(CredentialSession.State.management != .invalid)
}

func testSessionStateEquality() {
    let credential = sampleCredential("same")
    precondition(CredentialSession.State.management == .management)
    precondition(CredentialSession.State.invalid == .invalid)
    let wired = CredentialSession.State.wired(credential: credential)
    let emulation = CredentialSession.State.cardEmulation(credential: credential)
    precondition(wired != emulation)
    precondition(wired == .wired(credential: credential))
}

func testSessionStateInequality() {
    precondition(CredentialSession.State.management != .invalid)
    precondition(!(CredentialSession.State.invalid != .invalid))
}

func testSessionStateAssociatedCredential() {
    let credential = sampleCredential("wired")
    switch CredentialSession.State.wired(credential: credential) {
    case .wired(let stored):
        precondition(stored == credential)
    default:
        preconditionFailure("expected wired")
    }
    switch CredentialSession.State.cardEmulation(credential: credential) {
    case .cardEmulation(let stored):
        precondition(stored.name == "wired")
    default:
        preconditionFailure("expected cardEmulation")
    }
}

func testNFCFieldCases() {
    let present = CredentialSession.NFCFieldInformation.fieldPresent
    let absent = CredentialSession.NFCFieldInformation.fieldAbsent
    precondition(present != absent)
    precondition(present == .fieldPresent)
    precondition(absent == .fieldAbsent)
}

func testNFCFieldEquality() {
    precondition(CredentialSession.NFCFieldInformation.fieldPresent == .fieldPresent)
    precondition(CredentialSession.NFCFieldInformation.fieldAbsent != .fieldPresent)
}

func testNFCFieldHash() {
    var h1 = Hasher()
    var h2 = Hasher()
    CredentialSession.NFCFieldInformation.fieldPresent.hash(into: &h1)
    CredentialSession.NFCFieldInformation.fieldPresent.hash(into: &h2)
    precondition(h1.finalize() == h2.finalize())
    precondition(
        CredentialSession.NFCFieldInformation.fieldPresent.hashValue
            != CredentialSession.NFCFieldInformation.fieldAbsent.hashValue
    )
}

func testNFCFieldInequality() {
    precondition(CredentialSession.NFCFieldInformation.fieldPresent != .fieldAbsent)
    precondition(!(CredentialSession.NFCFieldInformation.fieldAbsent != .fieldAbsent))
}

func testConnectivityEventInstanceAID() {
    let event = CredentialSession.ConnectivityEvent(
        instanceApplicationIdentifier: Data([0xA0, 0x00]),
        data: Data([0x90, 0x00])
    )
    precondition(event.instanceApplicationIdentifier == Data([0xA0, 0x00]))
}

func testConnectivityEventData() {
    let payload = Data([0x00, 0xA4, 0x04, 0x00])
    let event = CredentialSession.ConnectivityEvent(
        instanceApplicationIdentifier: Data([0x01]),
        data: payload
    )
    precondition(event.data == payload)
}
