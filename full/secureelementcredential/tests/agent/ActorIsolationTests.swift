import SecureElementCredential

/// Hop onto the session actor so isolation witnesses can be exercised.
///
/// `assertIsolated`, `assumeIsolated`, and `preconditionIsolated` trap when
/// the current executor is not the session actor. Awaiting this isolated
/// helper hops to the actor, so the `(isolated CredentialSession)` closure
/// runs while isolated and each witness succeeds instead of trapping.
extension CredentialSession {
    func runIsolated(_ operation: (isolated CredentialSession) -> Void) {
        operation(self)
    }
}

func testActorAssertIsolated() async {
    let session = CredentialSession()
    await session.runIsolated { isolated in
        isolated.assertIsolated()
    }
}

func testActorAssumeIsolated() async {
    let session = CredentialSession()
    await session.runIsolated { isolated in
        let value = isolated.assumeIsolated { _ in 42 }
        precondition(value == 42)
    }
}

func testActorPreconditionIsolated() async {
    let session = CredentialSession()
    await session.runIsolated { isolated in
        isolated.preconditionIsolated()
    }
}
