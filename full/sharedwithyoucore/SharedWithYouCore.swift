@_exported import Foundation

/// Linux starting point for Apple's public `SharedWithYouCore` module.
///
/// Identifier newtypes, collaboration option trees, person records, and the
/// `SWAction` complete/fail/fulfill state machine are implemented here. Linux has
/// no Messages, CloudKit sharing, or collaboration daemon: the coordinator
/// never invents incoming actions, identity proofs are stored bytes only, and
/// `fulfill(using:collaborationIdentifier:)` records a process-local URL
/// rather than registering an iCloud share.
///
/// Isolated host-gate success is not Apple collaboration-service success.

// MARK: - Collaboration identifiers
//
// Darwin overlays `NS_TYPED_EXTENSIBLE_ENUM` typedefs over `NSString`. Any
// string is a valid raw value; this port stores it unchanged.

/// CloudKit / Messages collaboration identifier.
public struct SWCollaborationIdentifier: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

/// Process-local collaboration identifier used before a cloud identifier exists.
public struct SWLocalCollaborationIdentifier: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

// MARK: - UTI

/// Uniform type identifier for collaboration option payloads.
///
/// Darwin UTF-8 bytes are unobserved (TBD exports the symbol, not the string).
/// This host-local value follows the Shared with You naming pattern and is
/// recorded as an oracle question.
public let UTCollaborationOptionsTypeIdentifier =
    "com.apple.sharedwithyou.collaboration-options"

// MARK: - Host error
//
// The public Xcode 26.1 surface has no NS_ERROR_ENUM. TBD exports the private
// `__SWActionResponseErrorDomain` without codes. Linux uses a local domain
// and never claims Apple integer identities.

/// Process-local fail-closed error for Apple-service boundaries.
public enum SharedWithYouCoreHostError: Int, Error, Sendable, Hashable, CustomNSError {
    /// Messages / CloudKit collaboration services are not present on Linux.
    case appleServiceUnavailable = 1
    /// An `NSCoder` archive lacked required keys.
    case incompleteArchive = 2

    public static var errorDomain: String { "SharedWithYouCoreHostErrorDomain" }

    public var errorCode: Int { rawValue }

    public var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: localizedDescription]
    }

    public var localizedDescription: String {
        switch self {
        case .appleServiceUnavailable:
            return "Shared with You collaboration services are unavailable on this Linux host."
        case .incompleteArchive:
            return "The archive is missing required SharedWithYouCore keys."
        }
    }
}

// MARK: - Action completion (host)

/// Process-local discriminator for `SWAction` fulfill versus fail.
/// Darwin does not publish this enum; `isComplete` is the public flag.
public enum SWActionHostCompletion: Equatable, Sendable {
    case pending
    case fulfilled
    case failed
}

// MARK: - Coding helpers

internal func swcDecodeObject<T: NSObject & NSCoding>(
    _ type: T.Type,
    from coder: NSCoder,
    key: String
) -> T? {
    guard coder.containsValue(forKey: key) else { return nil }
    return coder.decodeObject(of: type, forKey: key)
}

internal func swcCopyingArray<T: NSObject & NSCopying>(_ values: [T]) -> [T] {
    values.map { ($0.copy() as? T) ?? $0 }
}

internal func swcDecodeDataArray(from coder: NSCoder, key: String) -> [Data]? {
    guard coder.containsValue(forKey: key) else { return nil }
    guard let array = coder.decodeObject(
        of: [NSArray.self, NSData.self],
        forKey: key
    ) as? [NSData] else {
        return nil
    }
    return array.map { $0 as Data }
}

internal func swcEncodeDataArray(_ values: [Data], to coder: NSCoder, key: String) {
    coder.encode(values.map { $0 as NSData } as NSArray, forKey: key)
}

// MARK: - Host SPI

/// Linux host-test control. Hidden from ordinary `import SharedWithYouCore`
/// clients and not part of Apple's public SharedWithYouCore surface.
@_spi(OpenUIKitHost)
public enum SharedWithYouCoreHostControl {
    public static func makeAction(uuid: UUID = UUID()) -> SWAction {
        SWAction(uuid: uuid)
    }

    public static func actionCompletion(_ action: SWAction) -> SWActionHostCompletion {
        action.hostCompletion
    }

    public static func makeStartCollaborationAction(
        metadata: SWCollaborationMetadata
    ) -> SWStartCollaborationAction {
        SWStartCollaborationAction(collaborationMetadata: metadata)
    }

    public static func makeUpdateCollaborationParticipantsAction(
        metadata: SWCollaborationMetadata,
        addedIdentities: [SWPerson.Identity] = [],
        removedIdentities: [SWPerson.Identity] = []
    ) -> SWUpdateCollaborationParticipantsAction {
        SWUpdateCollaborationParticipantsAction(
            collaborationMetadata: metadata,
            addedIdentities: addedIdentities,
            removedIdentities: removedIdentities
        )
    }

    public static func fulfilledURL(_ action: SWStartCollaborationAction) -> URL? {
        action.hostFulfilledURL
    }

    public static func fulfilledCollaborationIdentifier(
        _ action: SWStartCollaborationAction
    ) -> SWCollaborationIdentifier? {
        action.hostFulfilledCollaborationIdentifier
    }

    public static func deliverStartAction(
        _ action: SWStartCollaborationAction,
        on coordinator: SWCollaborationCoordinator = .shared
    ) {
        coordinator.host_deliver(action)
    }

    public static func deliverUpdateAction(
        _ action: SWUpdateCollaborationParticipantsAction,
        on coordinator: SWCollaborationCoordinator = .shared
    ) {
        coordinator.host_deliver(action)
    }

    public static func makeIdentityProof(
        inclusionHashes: [Data] = [],
        publicKey: Data = Data(),
        publicKeyIndex: Int = 0
    ) -> SWPerson.IdentityProof {
        SWPerson.IdentityProof(
            inclusionHashes: inclusionHashes,
            publicKey: publicKey,
            publicKeyIndex: publicKeyIndex
        )
    }

    public static func personHandle(_ person: SWPerson) -> String? {
        person.handle
    }

    public static func personIdentity(_ person: SWPerson) -> SWPerson.Identity? {
        person.identity
    }

    public static func personDisplayName(_ person: SWPerson) -> String {
        person.displayName
    }

    public static func personThumbnailImageData(_ person: SWPerson) -> Data? {
        person.thumbnailImageData
    }

    public static func resetSharedCoordinator() {
        SWCollaborationCoordinator.shared.actionHandler = nil
    }
}
