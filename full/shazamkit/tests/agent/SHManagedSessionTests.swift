import Foundation
import ShazamKit

func testSHManagedSessionType() {
    precondition(type(of: SHManagedSession()) == SHManagedSession.self)
}

func testSHManagedSessionInit() {
    let session = SHManagedSession()
    precondition(session.state == .idle)
}

func testSHManagedSessionInitCatalog() {
    let session = SHManagedSession(catalog: SHCustomCatalog())
    precondition(session.state == .idle)
}

func testSHManagedSessionState() {
    precondition(SHManagedSession().state == .idle)
}

func testSHManagedSessionCancel() {
    let session = SHManagedSession()
    session.cancel()
    precondition(session.state == .idle)
}

func testSHManagedSessionResults() {
    _ = SHManagedSession().results
}

func testSHManagedSessionStateCases() {
    let states: [SHManagedSession.State] = [.idle, .prerecording, .matching]
    precondition(states.count == 3)
    precondition(SHManagedSession.State.idle == .idle)
    precondition(SHManagedSession.State.prerecording == .prerecording)
    precondition(SHManagedSession.State.matching == .matching)
}

func testSHManagedSessionStateEquality() {
    precondition(SHManagedSession.State.idle == .idle)
    precondition(!(SHManagedSession.State.idle == .matching))
}

func testSHManagedSessionStateInequality() {
    precondition(SHManagedSession.State.idle != .prerecording)
    precondition(!(SHManagedSession.State.matching != .matching))
}

func testSHManagedSessionStateHashInto() {
    var hasher = Hasher()
    SHManagedSession.State.idle.hash(into: &hasher)
    _ = hasher.finalize()
}

func testSHManagedSessionStateHashValue() {
    _ = SHManagedSession.State.matching.hashValue
}

func testSHLibraryType() {
    precondition(type(of: SHLibrary.default) == SHLibrary.self)
}

func testSHLibraryDefault() {
    precondition(SHLibrary.default === SHLibrary.default)
}

func testSHLibraryItems() {
    precondition(SHLibrary.default.items.isEmpty)
}

func testSHMediaLibraryType() {
    precondition(type(of: SHMediaLibrary.default) == SHMediaLibrary.self)
}

func testSHMediaLibraryDefault() {
    precondition(SHMediaLibrary.default === SHMediaLibrary.default)
}
