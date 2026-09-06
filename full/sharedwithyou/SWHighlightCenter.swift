import Foundation

/// Delegate for `SWHighlightCenter` highlight-list changes.
public protocol SWHighlightCenterDelegate: NSObjectProtocol {
    func highlightCenterHighlightsDidChange(_ highlightCenter: SWHighlightCenter)
}

/// Process-local highlight center.
///
/// Darwin talks to the Messages Shared with You daemon. Linux never
/// contacts that daemon: `highlights` is empty, lookups throw or complete
/// with `accessDenied`, and `postNotice` only records a process-local
/// ledger that `clearNotices` can empty.
open class SWHighlightCenter: NSObject {
    public weak var delegate: (any SWHighlightCenterDelegate)?

    /// Always empty. Linux has no Messages Shared with You corpus.
    public var highlights: [SWHighlight] { [] }

    /// Darwin returns a localized "Shared with You" collection title.
    /// Linux has no catalog, so this is empty until an Apple oracle
    /// observes the exact string.
    public class var highlightCollectionTitle: String { "" }

    /// Always false. Linux has no system collaboration support.
    public class var isSystemCollaborationSupportAvailable: Bool { false }

    private let lock = NSLock()
    private var postedNotices: [URL] = []

    public override init() {
        super.init()
    }

    var hostPostedNoticeCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return postedNotices.count
    }

    /// Completes immediately with `accessDenied`. Never fabricates a highlight.
    public func getHighlightFor(
        _ URL: URL,
        completionHandler: @escaping (SWHighlight?, (any Error)?) -> Void
    ) {
        _ = URL
        completionHandler(nil, SWHighlightCenterErrorCode.accessDenied)
    }

    /// Always throws `accessDenied`. Linux has no collaboration store.
    public func collaborationHighlight(
        forIdentifier collaborationIdentifier: String
    ) throws -> SWCollaborationHighlight {
        _ = collaborationIdentifier
        throw SWHighlightCenterErrorCode.accessDenied
    }

    /// Completes immediately with `accessDenied`. Never fabricates a
    /// collaboration highlight from a URL.
    public func collaborationHighlight(for URL: URL) async throws -> SWCollaborationHighlight {
        _ = URL
        throw SWHighlightCenterErrorCode.accessDenied
    }

    /// Completes immediately with `accessDenied`. Linux cannot sign
    /// CloudKit collaboration identity proofs.
    public func getSignedIdentityProof(
        for collaborationHighlight: SWCollaborationHighlight,
        using data: Data,
        completionHandler: @escaping (SWPerson.SignedIdentityProof?, (any Error)?) -> Void
    ) {
        _ = (collaborationHighlight, data)
        completionHandler(nil, SWHighlightCenterErrorCode.accessDenied)
    }

    /// Records a process-local notice. Does not deliver to Messages.
    public func postNotice(for event: any SWHighlightEvent) {
        lock.lock()
        postedNotices.append(event.highlightURL)
        lock.unlock()
    }

    /// Drops process-local notices whose URL matches `highlight.url`.
    public func clearNotices(for highlight: SWCollaborationHighlight) {
        lock.lock()
        postedNotices.removeAll { $0 == highlight.url }
        lock.unlock()
    }
}
