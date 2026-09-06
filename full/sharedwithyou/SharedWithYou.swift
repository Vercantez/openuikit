@_exported import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

/// Linux starting point for Apple's public `SharedWithYou` module.
///
/// Isolated host compilation has Foundation only. UIKit types used by
/// attribution and collaboration views are the lookalikes in
/// `SharedWithYouLookalikes.swift` until a real UIKit module is on the
/// link line. Linux has no Messages, Shared with You daemon, CloudKit
/// sharing sheet, or collaboration identity service: every path that would
/// contact those Apple services stays fail-closed.

/// Process-local identity of Apple's `_SWHighlightErrorDomain` TBD export.
public let SWHighlightErrorDomain = "SWHighlightErrorDomain"

/// Type identifier string for collaboration metadata item providers.
///
/// Darwin bytes are unobserved on this host. The provisional UTI follows
/// the SharedWithYouCore `UTCollaborationOptionsTypeIdentifier` naming
/// pattern and is recorded as an oracle question.
public let SWCollaborationMetadataTypeIdentifier =
    "com.apple.sharedwithyou.collaboration-metadata"

/// Collaboration identifier used by `SWHighlightCenter` overlays.
public typealias SWCollaborationIdentifier = String

// MARK: - Attribution view enumerations
//
// Raw values follow the pinned dotnet-macios `Native` enums, which match
// NS_ENUM declaration order starting at 0.

extension SWAttributionView {
    /// Background treatment for an attribution view.
    public enum BackgroundStyle: Int, Sendable, Hashable {
        case `default` = 0
        case color = 1
        case material = 2
    }

    /// Summary versus detail presentation of an attribution view.
    public enum DisplayContext: Int, Sendable, Hashable {
        case summary = 0
        case detail = 1
    }

    /// Horizontal placement of attribution content.
    public enum HorizontalAlignment: Int, Sendable, Hashable {
        case `default` = 0
        case leading = 1
        case center = 2
        case trailing = 3
    }
}

// MARK: - Highlight center errors

/// Bridged `NS_ERROR_ENUM` for `SWHighlightCenter`.
///
/// Raw values follow the pinned dotnet-macios `SWHighlightCenterErrorCode`
/// (`NoError = 0` through `AccessDenied = 3`) and the TBD export
/// `_SWHighlightErrorDomain`.
public enum SWHighlightCenterErrorCode: Int, Error, Sendable, Hashable, CustomNSError {
    case noError = 0
    case internalError = 1
    case invalidURL = 2
    case accessDenied = 3

    public static var errorDomain: String { SWHighlightErrorDomain }

    public var errorCode: Int { rawValue }

    public var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: localizedDescription]
    }

    public var localizedDescription: String {
        switch self {
        case .noError:
            return "No highlight-center error."
        case .internalError:
            return "The highlight center encountered an internal error."
        case .invalidURL:
            return "The highlight URL is invalid."
        case .accessDenied:
            return "Highlight-center access is denied on this Linux host."
        }
    }
}

// MARK: - Event triggers
//
// Change / membership / persistence triggers start at 1 in the pinned
// macios bindings (`Edit = 1`, `AddedCollaborator = 1`, `Created = 1`).

/// What kind of collaborative edit produced a change event.
public enum SWHighlightChangeEventTrigger: Int, Sendable, Hashable {
    case edit = 1
    case comment = 2
}

/// Collaborator added or removed.
public enum SWHighlightMembershipEventTrigger: Int, Sendable, Hashable {
    case addedCollaborator = 1
    case removedCollaborator = 2
}

/// File-system style persistence of a shared highlight.
public enum SWHighlightPersistenceEventTrigger: Int, Sendable, Hashable {
    case created = 1
    case deleted = 2
    case renamed = 3
    case moved = 4
}

// MARK: - Host SPI

/// Linux host-test control. Hidden from ordinary `import SharedWithYou`
/// clients and not part of Apple's public SharedWithYou surface.
@_spi(OpenUIKitHost)
public enum SharedWithYouHostControl {
    /// Makes a process-local highlight. Darwin would only vend highlights
    /// from the Messages Shared with You daemon.
    public static func makeHighlight(
        url: URL,
        identifier: String = "host.highlight"
    ) -> SWHighlight {
        SWHighlight(hostURL: url, hostIdentifier: identifier)
    }

    /// Makes a process-local collaboration highlight.
    public static func makeCollaborationHighlight(
        url: URL,
        identifier: String = "host.highlight",
        collaborationIdentifier: String = "host.collaboration",
        title: String? = "Host Collaboration",
        creationDate: Date = Date(timeIntervalSince1970: 0),
        contentType: UTType = UTType(identifier: "public.data")
    ) -> SWCollaborationHighlight {
        SWCollaborationHighlight(
            hostURL: url,
            hostIdentifier: identifier,
            collaborationIdentifier: collaborationIdentifier,
            title: title,
            creationDate: creationDate,
            contentType: contentType
        )
    }

    /// Makes a process-local person record. Darwin identities come from
    /// CloudKit collaboration participants.
    public static func makePerson(
        handle: String? = "host@example.invalid",
        displayName: String = "Host Person",
        identity: SWPerson.Identity? = nil,
        thumbnailImageData: Data? = nil
    ) -> SWPerson {
        SWPerson(
            handle: handle,
            identity: identity,
            displayName: displayName,
            thumbnailImageData: thumbnailImageData
        )
    }

    /// Posted-notice count on a highlight center. Notices never leave process.
    public static func postedNoticeCount(_ center: SWHighlightCenter) -> Int {
        center.hostPostedNoticeCount
    }

    /// Whether the collaboration view is storing a manage-button flag.
    public static func showsManageButton(_ view: SWCollaborationView) -> Bool {
        view.hostShowsManageButton
    }

    /// Content view last supplied to `setContent(_:)`.
    public static func contentView(_ view: SWCollaborationView) -> UIView? {
        view.hostContentView
    }
}
