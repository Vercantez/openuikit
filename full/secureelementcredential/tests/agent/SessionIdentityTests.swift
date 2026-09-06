import Foundation
import SecureElementCredential

func testCredentialSessionInit() {
    let session = CredentialSession()
    _ = session
}

func testCredentialSessionEquality() {
    let a = CredentialSession()
    let b = a
    let c = CredentialSession()
    precondition(a == b)
    precondition(a != c)
}

func testCredentialSessionInequality() {
    let a = CredentialSession()
    let b = CredentialSession()
    precondition(a != b)
    precondition(!(a != a))
}

func testCredentialSessionUnownedExecutor() {
    let session = CredentialSession()
    _ = session.unownedExecutor
}

func testPresentmentIntentAssertionClass() {
    let assertion = CredentialSession.PresentmentIntentAssertion()
    let active = CredentialSession.PresentmentIntentAssertion(state: .active)
    _ = assertion
    _ = active
}

func testPresentmentStateCases() {
    let active = CredentialSession.PresentmentIntentAssertion.State.active
    let invalid = CredentialSession.PresentmentIntentAssertion.State.invalid
    precondition(active != invalid)
    precondition(active == .active)
}

func testPresentmentStateEquality() {
    precondition(CredentialSession.PresentmentIntentAssertion.State.active == .active)
    precondition(CredentialSession.PresentmentIntentAssertion.State.invalid != .active)
}

func testPresentmentStateHash() {
    var h1 = Hasher()
    var h2 = Hasher()
    CredentialSession.PresentmentIntentAssertion.State.active.hash(into: &h1)
    CredentialSession.PresentmentIntentAssertion.State.active.hash(into: &h2)
    precondition(h1.finalize() == h2.finalize())
    precondition(
        CredentialSession.PresentmentIntentAssertion.State.active.hashValue
            != CredentialSession.PresentmentIntentAssertion.State.invalid.hashValue
    )
}

func testPresentmentStateInequality() {
    precondition(
        CredentialSession.PresentmentIntentAssertion.State.active != .invalid
    )
    precondition(
        !(CredentialSession.PresentmentIntentAssertion.State.invalid != .invalid)
    )
}
