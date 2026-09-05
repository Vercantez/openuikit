import Foundation

/// Delegate callbacks for ``SHSession`` match attempts.
///
/// Optional methods have empty defaults. Linux delivers them synchronously on
/// the caller of ``SHSession/match(_:)``.
public protocol SHSessionDelegate: NSObjectProtocol {
    func session(_ session: SHSession, didFind match: SHMatch)
    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: (any Error)?)
}

extension SHSessionDelegate {
    public func session(_ session: SHSession, didFind match: SHMatch) {}
    public func session(
        _ session: SHSession,
        didNotFindMatchFor signature: SHSignature,
        error: (any Error)?
    ) {}
}

/// A one-shot or streaming matcher bound to a catalog.
///
/// Default sessions use the unavailable Apple catalog and fail closed with
/// ``SHError/Code-swift.enum/matchAttemptFailed``. Sessions bound to
/// ``SHCustomCatalog`` compare `dataRepresentation` bytes and report either
/// a match or `didNotFindMatch` with a `nil` error.
public class SHSession: NSObject {
    public let catalog: SHCatalog
    public weak var delegate: (any SHSessionDelegate)?

    public override init() {
        self.catalog = SHCatalog()
        super.init()
    }

    public init(catalog: SHCatalog) {
        self.catalog = catalog
        super.init()
    }

    /// Match `signature` against the bound catalog and notify `delegate`
    /// on this thread. Never talks to Apple's service.
    public func match(_ signature: SHSignature) {
        let outcome = evaluate(signature)
        switch outcome {
        case .match(let match):
            delegate?.session(self, didFind: match)
        case .noMatch(let query):
            delegate?.session(self, didNotFindMatchFor: query, error: nil)
        case .error(let error, let query):
            delegate?.session(self, didNotFindMatchFor: query, error: error)
        }
    }

    /// Async one-shot equivalent of ``match(_:)``. Declared for coverage; the
    /// sealed runner cannot await, so focused tests exercise ``match(_:)``.
    public func result(from signature: SHSignature) async -> SHSession.Result {
        evaluate(signature)
    }

    /// Streaming results. Linux never records microphone input, so the
    /// sequence is empty.
    public var results: Results {
        Results(outcomes: [])
    }

    internal func evaluate(_ signature: SHSignature) -> Result {
        if signature.dataRepresentation.isEmpty {
            return .error(SHError(.signatureInvalid), signature)
        }
        let minimum = catalog.minimumQuerySignatureDuration
        let maximum = catalog.maximumQuerySignatureDuration
        if signature.duration + 0.0 < minimum || signature.duration > maximum {
            return .error(SHError(.signatureDurationInvalid), signature)
        }
        if let match = catalog.match(query: signature) {
            return .match(match)
        }
        if catalog.usesRemoteShazamService {
            return .error(SHError(.matchAttemptFailed), signature)
        }
        return .noMatch(signature)
    }

    /// Outcome of a match attempt.
    @frozen public enum Result {
        case match(SHMatch)
        case noMatch(SHSignature)
        case error(any Error, SHSignature)
    }

    /// An async sequence of ``Result`` values. Empty unless a future host
    /// feeds streaming matches.
    public struct Results: AsyncSequence {
        public typealias Element = SHSession.Result
        public typealias AsyncIterator = Iterator

        internal let outcomes: [SHSession.Result]

        public func makeAsyncIterator() -> Iterator {
            Iterator(outcomes: outcomes)
        }

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = SHSession.Results.Element

            private let outcomes: [SHSession.Result]
            private var index = 0

            internal init(outcomes: [SHSession.Result]) {
                self.outcomes = outcomes
            }

            public mutating func next() async -> SHSession.Results.Element? {
                guard index < outcomes.count else { return nil }
                let value = outcomes[index]
                index += 1
                return value
            }
        }
    }
}
