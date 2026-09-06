import Foundation
import SecureElementCredential

func testEventSessionInvalidated() {
    let event = CredentialSession.Event.sessionInvalidated(reason: .featureUnavailable)
    switch event {
    case .sessionInvalidated(let reason):
        precondition(reason == .featureUnavailable)
    default:
        preconditionFailure("expected sessionInvalidated")
    }
}

func testEventCredentialFinishedInstalling() {
    let credential = CredentialSession.Credential(
        identifier: UUID(),
        name: "done",
        state: .installationPending
    )
    let event = CredentialSession.Event.credentialFinishedInstalling(credential: credential)
    switch event {
    case .credentialFinishedInstalling(let stored):
        precondition(stored.name == "done")
    default:
        preconditionFailure("expected credentialFinishedInstalling")
    }
}

func testEventFieldStateChanged() {
    let event = CredentialSession.Event.fieldStateChanged(info: .fieldPresent)
    switch event {
    case .fieldStateChanged(let info):
        precondition(info == .fieldPresent)
    default:
        preconditionFailure("expected fieldStateChanged")
    }
}

func testEventConnectivityEvent() {
    let payload = CredentialSession.ConnectivityEvent(
        instanceApplicationIdentifier: Data([0x01]),
        data: Data([0x02])
    )
    let event = CredentialSession.Event.connectivityEvent(payload)
    switch event {
    case .connectivityEvent(let stored):
        precondition(stored.data == Data([0x02]))
    default:
        preconditionFailure("expected connectivityEvent")
    }
}

func testEventCardEmulationTimeout() {
    switch CredentialSession.Event.cardEmulationTimeout {
    case .cardEmulationTimeout:
        break
    default:
        preconditionFailure("expected cardEmulationTimeout")
    }
}

func testEventPresentmentTimeout() {
    switch CredentialSession.Event.presentmentIntentAssertionTimeout {
    case .presentmentIntentAssertionTimeout:
        break
    default:
        preconditionFailure("expected presentmentIntentAssertionTimeout")
    }
}

func testEventTypeExists() {
    let events: [CredentialSession.Event] = [
        .cardEmulationTimeout,
        .presentmentIntentAssertionTimeout,
        .fieldStateChanged(info: .fieldAbsent),
    ]
    precondition(events.count == 3)
}
