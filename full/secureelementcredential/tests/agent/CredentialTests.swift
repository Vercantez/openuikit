import Foundation
import SecureElementCredential

func sampleInstance() -> CredentialSession.Credential.InstanceInfo {
    CredentialSession.Credential.InstanceInfo(
        instanceAID: Data([0x01]),
        packageAID: Data([0x02]),
        moduleAID: Data([0x03]),
        securityDomainAID: Data([0x04]),
        securityDomainKeyInfo: Data([0x05, 0x06]),
        lifeCycleState: Data([0x07]),
        instanceType: .standalone
    )
}

func testCredentialIdentifier() {
    let id = UUID()
    let credential = CredentialSession.Credential(
        identifier: id,
        name: "transit",
        state: .installationPending
    )
    precondition(credential.identifier == id)
}

func testCredentialName() {
    let credential = CredentialSession.Credential(
        identifier: UUID(),
        name: "badge",
        state: .installationFailed
    )
    precondition(credential.name == "badge")
}

func testCredentialStateProperty() {
    let pending = CredentialSession.Credential(
        identifier: UUID(),
        name: "pending",
        state: .installationPending
    )
    switch pending.state {
    case .installationPending:
        break
    default:
        preconditionFailure("expected installationPending")
    }
}

func testCredentialInstalledState() {
    let instance = sampleInstance()
    let credential = CredentialSession.Credential(
        identifier: UUID(),
        name: "installed",
        state: .installed(instances: [instance])
    )
    switch credential.state {
    case .installed(let instances):
        precondition(instances.count == 1)
        precondition(instances[0].instanceAID == Data([0x01]))
    default:
        preconditionFailure("expected installed")
    }
}

func testCredentialEquality() {
    let id = UUID()
    let a = CredentialSession.Credential(identifier: id, name: "a", state: .installationPending)
    let b = CredentialSession.Credential(identifier: id, name: "a", state: .installationPending)
    let c = CredentialSession.Credential(identifier: UUID(), name: "a", state: .installationPending)
    precondition(a == b)
    precondition(a != c)
}

func testCredentialHash() {
    let id = UUID()
    let a = CredentialSession.Credential(identifier: id, name: "hash", state: .installationPending)
    let b = CredentialSession.Credential(identifier: id, name: "hash", state: .installationFailed)
    var h1 = Hasher()
    var h2 = Hasher()
    a.hash(into: &h1)
    b.hash(into: &h2)
    precondition(h1.finalize() == h2.finalize())
    precondition(a.hashValue == b.hashValue)
}

func testCredentialInequality() {
    let id = UUID()
    let a = CredentialSession.Credential(identifier: id, name: "left", state: .installationPending)
    let b = CredentialSession.Credential(identifier: id, name: "right", state: .installationPending)
    precondition(a != b)
    precondition(!(a != a))
}

func testCredentialTypealias() {
    let id = UUID()
    let nested = CredentialSession.Credential(identifier: id, name: "alias", state: .installationPending)
    let aliased: Credential = nested
    precondition(aliased.identifier == id)
    precondition(aliased.name == "alias")
}

func testCredentialStateCases() {
    let pending = CredentialSession.Credential.State.installationPending
    let failed = CredentialSession.Credential.State.installationFailed
    let installed = CredentialSession.Credential.State.installed(instances: [])
    precondition(pending != failed)
    precondition(pending != installed)
    precondition(failed != installed)
    precondition(installed == .installed(instances: []))
}

func testCredentialStateEquality() {
    let instance = sampleInstance()
    let a = CredentialSession.Credential.State.installed(instances: [instance])
    let b = CredentialSession.Credential.State.installed(instances: [instance])
    precondition(a == b)
    precondition(a != .installationPending)
}
