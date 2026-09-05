import Foundation

/// A session that owns recording and matching.
///
/// Linux has no microphone. The object constructs, reports `.idle`, and
/// `cancel()` returns to `.idle`. `prepare()` and `result()` are fail-closed
/// async surfaces (declared; the sealed runner cannot await).
public final class SHManagedSession: @unchecked Sendable {
    public enum State: Hashable, Sendable {
        case idle
        case prerecording
        case matching
    }

    private var storedState: State
    private var cancelled = false
    private let session: SHSession

    public var state: State { storedState }

    public init() {
        self.session = SHSession()
        self.storedState = .idle
    }

    public init(catalog: SHCatalog) {
        self.session = SHSession(catalog: catalog)
        self.storedState = .idle
    }

    public func cancel() {
        cancelled = true
        storedState = .idle
    }

    public func prepare() async {
        if cancelled {
            storedState = .idle
            return
        }
        storedState = .prerecording
    }

    public func result() async -> SHSession.Result {
        storedState = .matching
        let empty = SHSignature(uncheckedData: Data(), duration: 0)
        let outcome: SHSession.Result
        if session.catalog.usesRemoteShazamService {
            outcome = .error(SHError(.matchAttemptFailed), empty)
        } else {
            outcome = .noMatch(empty)
        }
        storedState = .idle
        return outcome
    }

    public var results: SHSession.Results {
        session.results
    }
}
