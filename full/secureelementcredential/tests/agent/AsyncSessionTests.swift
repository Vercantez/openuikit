import Foundation
import SecureElementCredential

func testStartSessionThrows() async {
    do {
        _ = try await CredentialSession.startSession()
        preconditionFailure("startSession should throw")
    } catch let code as CredentialSession.ErrorCode {
        precondition(code == .featureUnavailable)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}

func testIsEligibleThrows() async {
    do {
        _ = try await CredentialSession.isEligible
        preconditionFailure("isEligible should throw")
    } catch let code as CredentialSession.ErrorCode {
        precondition(code == .featureUnavailable)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}

func testSessionStateValue() async {
    let session = CredentialSession()
    let state = await session.state
    precondition(state == .invalid)
}

func testEventStreamCompletes() async {
    let session = CredentialSession()
    let stream = await session.eventStream
    var count = 0
    for await event in stream {
        count += 1
        if case .sessionInvalidated(let reason) = event {
            precondition(reason == .featureUnavailable)
        } else {
            preconditionFailure("unexpected event")
        }
    }
    precondition(count == 1)
}

func testSecureElementInfoThrows() async {
    let session = CredentialSession()
    do {
        _ = try await session.secureElementInfo
        preconditionFailure("secureElementInfo should throw")
    } catch let code as CredentialSession.ErrorCode {
        precondition(code == .featureUnavailable)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}

func testSessionInvalidateThrows() async {
    let session = CredentialSession()
    do {
        try await session.invalidate()
        preconditionFailure("invalidate should throw")
    } catch let code as CredentialSession.ErrorCode {
        precondition(code == .featureUnavailable)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}

func testListCredentialsThrows() async {
    let session = CredentialSession()
    do {
        _ = try await session.listCredentials()
        preconditionFailure("listCredentials should throw")
    } catch let code as CredentialSession.ErrorCode {
        precondition(code == .featureUnavailable)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}

func testProvisionCredentialThrows() async {
    let session = CredentialSession()
    do {
        _ = try await session.provisionCredential(configurationUUID: UUID(), name: "test")
        preconditionFailure("provisionCredential should throw")
    } catch let code as CredentialSession.ErrorCode {
        precondition(code == .featureUnavailable)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}

func testDeleteCredentialThrows() async {
    let session = CredentialSession()
    let credential = CredentialSession.Credential(
        identifier: UUID(), name: "test", state: .installed(instances: [])
    )
    do {
        try await session.deleteCredential(credential)
        preconditionFailure("deleteCredential should throw")
    } catch let code as CredentialSession.ErrorCode {
        precondition(code == .featureUnavailable)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}

func testEnterWiredModeThrows() async {
    let session = CredentialSession()
    let credential = CredentialSession.Credential(
        identifier: UUID(), name: "test", state: .installed(instances: [])
    )
    do {
        try await session.enterWiredMode(using: credential)
        preconditionFailure("enterWiredMode should throw")
    } catch let code as CredentialSession.ErrorCode {
        precondition(code == .featureUnavailable)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}

func testTransceiveThrows() async {
    let session = CredentialSession()
    do {
        _ = try await session.transceive(Data([0x00, 0xA4]))
        preconditionFailure("transceive should throw")
    } catch let code as CredentialSession.ErrorCode {
        precondition(code == .featureUnavailable)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}

func testEndWiredModeThrows() async {
    let session = CredentialSession()
    do {
        try await session.endWiredMode()
        preconditionFailure("endWiredMode should throw")
    } catch let code as CredentialSession.ErrorCode {
        precondition(code == .featureUnavailable)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}

func testAcquirePresentmentAssertionThrows() async {
    let session = CredentialSession()
    do {
        _ = try await session.acquirePresentmentAssertion()
        preconditionFailure("acquirePresentmentAssertion should throw")
    } catch let code as CredentialSession.ErrorCode {
        precondition(code == .featureUnavailable)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}

func testEndCardEmulationThrows() async {
    let session = CredentialSession()
    do {
        try await session.endCardEmulation()
        preconditionFailure("endCardEmulation should throw")
    } catch let code as CredentialSession.ErrorCode {
        precondition(code == .featureUnavailable)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}

func testSessionConfigurationThrows() async {
    let session = CredentialSession()
    do {
        _ = try await session.configuration()
        preconditionFailure("configuration should throw")
    } catch let code as CredentialSession.ErrorCode {
        precondition(code == .featureUnavailable)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}

func testSecurityDomainCounterThrows() async {
    let info = CredentialSession.Credential.InstanceInfo(
        instanceAID: Data([0xA0]),
        packageAID: Data([0xA1]),
        moduleAID: Data([0xA2]),
        securityDomainAID: Data([0xA3]),
        securityDomainKeyInfo: Data([0xA4]),
        lifeCycleState: Data([0x07]),
        instanceType: .standalone
    )
    do {
        _ = try await info.securityDomainCounter
        preconditionFailure("securityDomainCounter should throw")
    } catch let code as CredentialSession.ErrorCode {
        precondition(code == .featureUnavailable)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}

func testPresentmentAssertionStateValue() async {
    let assertion = CredentialSession.PresentmentIntentAssertion(state: .active)
    let state = await assertion.state
    precondition(state == .active)
    let invalid = CredentialSession.PresentmentIntentAssertion()
    let invalidState = await invalid.state
    precondition(invalidState == .invalid)
}

func testRelinquishThrows() async {
    let assertion = CredentialSession.PresentmentIntentAssertion()
    do {
        try await assertion.relinquish()
        preconditionFailure("relinquish should throw")
    } catch let code as CredentialSession.ErrorCode {
        precondition(code == .featureUnavailable)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}

func testPerformCardEmulationWithCurrentCredentialThrows() async {
    let transaction = CredentialTransaction()
    do {
        try await transaction.performCardEmulationTransactionWithCurrentCredential()
        preconditionFailure("performCardEmulationTransactionWithCurrentCredential should throw")
    } catch let code as CredentialSession.ErrorCode {
        precondition(code == .featureUnavailable)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}

func testPerformTransactionThrows() async {
    let transaction = CredentialTransaction()
    let credential = CredentialSession.Credential(
        identifier: UUID(), name: "test", state: .installed(instances: [])
    )
    do {
        try await transaction.performTransaction(using: credential)
        preconditionFailure("performTransaction should throw")
    } catch let code as CredentialSession.ErrorCode {
        precondition(code == .featureUnavailable)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}

func testPerformTransactionInWiredModeThrows() async {
    let transaction = CredentialTransaction()
    let credential = CredentialSession.Credential(
        identifier: UUID(), name: "test", state: .installed(instances: [])
    )
    do {
        try await transaction.performTransactionInWiredMode(using: credential, instanceAID: Data([0xA0]))
        preconditionFailure("performTransactionInWiredMode should throw")
    } catch let code as CredentialSession.ErrorCode {
        precondition(code == .featureUnavailable)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}

func testConfigurationInvalidateThrows() async {
    let configuration = CredentialTransaction.Configuration()
    do {
        try await configuration.invalidate()
        preconditionFailure("Configuration.invalidate should throw")
    } catch let code as CredentialSession.ErrorCode {
        precondition(code == .featureUnavailable)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}
