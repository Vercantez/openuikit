import Foundation

/// Base collaboration action delivered to `SWCollaborationActionHandler`.
///
/// Darwin vends these from the Messages / Shared with You daemon. Linux
/// constructs them through `@_spi(OpenUIKitHost)` so tests can exercise the
/// documented complete/fail/fulfill state machine without inventing a daemon.
///
/// Calling `fulfill()` or `fail()` more than once is a no-op: after either
/// method, `isComplete` stays `true`. Apple's trap-versus-no-op on a second
/// call is unobserved and recorded as an oracle question.
open class SWAction: NSObject, NSCopying, NSSecureCoding {
    public let uuid: UUID

    public var isComplete: Bool { hostCompletion != .pending }

    internal var hostCompletion: SWActionHostCompletion

    public static var supportsSecureCoding: Bool { true }

    public override init() {
        self.uuid = UUID()
        self.hostCompletion = .pending
        super.init()
    }

    internal init(uuid: UUID, completion: SWActionHostCompletion = .pending) {
        self.uuid = uuid
        self.hostCompletion = completion
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard let uuidString = swcDecodeObject(NSString.self, from: coder, key: "uuid") as String?,
              let uuid = UUID(uuidString: uuidString)
        else {
            return nil
        }
        self.uuid = uuid
        switch coder.decodeInteger(forKey: "completion") {
        case 1:
            self.hostCompletion = .fulfilled
        case 2:
            self.hostCompletion = .failed
        default:
            self.hostCompletion = .pending
        }
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(uuid.uuidString as NSString, forKey: "uuid")
        switch hostCompletion {
        case .pending:
            coder.encode(0, forKey: "completion")
        case .fulfilled:
            coder.encode(1, forKey: "completion")
        case .failed:
            coder.encode(2, forKey: "completion")
        }
    }

    /// Marks the action successful. Subsequent `fulfill()` / `fail()` calls
    /// are ignored.
    open func fulfill() {
        guard hostCompletion == .pending else { return }
        hostCompletion = .fulfilled
    }

    /// Marks the action failed. Subsequent `fulfill()` / `fail()` calls
    /// are ignored.
    open func fail() {
        guard hostCompletion == .pending else { return }
        hostCompletion = .failed
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        SWAction(uuid: uuid, completion: hostCompletion)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? SWAction else { return false }
        return uuid == other.uuid && hostCompletion == other.hostCompletion
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(uuid)
        hasher.combine(String(describing: hostCompletion))
        return hasher.finalize()
    }
}

/// Action asking the app to start a collaboration for the supplied metadata.
///
/// `fulfill(using:collaborationIdentifier:)` stores the URL and identifier
/// locally and marks the action complete. Linux does not register a CloudKit
/// share or contact Messages.
open class SWStartCollaborationAction: SWAction {
    public let collaborationMetadata: SWCollaborationMetadata

    internal var hostFulfilledURL: URL? = nil
    internal var hostFulfilledCollaborationIdentifier: SWCollaborationIdentifier? = nil

    internal init(collaborationMetadata: SWCollaborationMetadata) {
        self.collaborationMetadata = (collaborationMetadata.copy() as? SWCollaborationMetadata)
            ?? collaborationMetadata
        super.init()
    }

    internal init(
        uuid: UUID,
        completion: SWActionHostCompletion,
        collaborationMetadata: SWCollaborationMetadata,
        fulfilledURL: URL?,
        fulfilledIdentifier: SWCollaborationIdentifier?
    ) {
        self.collaborationMetadata = (collaborationMetadata.copy() as? SWCollaborationMetadata)
            ?? collaborationMetadata
        self.hostFulfilledURL = fulfilledURL
        self.hostFulfilledCollaborationIdentifier = fulfilledIdentifier
        super.init(uuid: uuid, completion: completion)
    }

    public required init?(coder: NSCoder) {
        guard let metadata = swcDecodeObject(
            SWCollaborationMetadata.self,
            from: coder,
            key: "collaborationMetadata"
        ) else {
            return nil
        }
        self.collaborationMetadata = metadata
        if let urlString = swcDecodeObject(NSString.self, from: coder, key: "fulfilledURL") as String? {
            self.hostFulfilledURL = URL(string: urlString)
        } else {
            self.hostFulfilledURL = nil
        }
        if let raw = swcDecodeObject(
            NSString.self,
            from: coder,
            key: "fulfilledCollaborationIdentifier"
        ) as String? {
            self.hostFulfilledCollaborationIdentifier = SWCollaborationIdentifier(rawValue: raw)
        } else {
            self.hostFulfilledCollaborationIdentifier = nil
        }
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(collaborationMetadata, forKey: "collaborationMetadata")
        if let url = hostFulfilledURL {
            coder.encode(url.absoluteString as NSString, forKey: "fulfilledURL")
        }
        if let identifier = hostFulfilledCollaborationIdentifier {
            coder.encode(identifier.rawValue as NSString, forKey: "fulfilledCollaborationIdentifier")
        }
    }

    /// Completes the start action with a collaboration URL and identifier.
    ///
    /// Darwin would publish those values to the sharing daemon. Linux stores
    /// them on the action and calls `fulfill()`. A second call is a no-op.
    open func fulfill(using url: URL, collaborationIdentifier: SWCollaborationIdentifier) {
        guard hostCompletion == .pending else { return }
        hostFulfilledURL = url
        hostFulfilledCollaborationIdentifier = collaborationIdentifier
        fulfill()
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        SWStartCollaborationAction(
            uuid: uuid,
            completion: hostCompletion,
            collaborationMetadata: collaborationMetadata,
            fulfilledURL: hostFulfilledURL,
            fulfilledIdentifier: hostFulfilledCollaborationIdentifier
        )
    }
}

/// Action asking the app to add or remove collaboration participants.
///
/// Linux never receives these from a daemon. Host tests construct them with
/// the supplied identity lists. `fulfill()` / `fail()` follow `SWAction`.
open class SWUpdateCollaborationParticipantsAction: SWAction {
    public let collaborationMetadata: SWCollaborationMetadata
    public let addedIdentities: [SWPerson.Identity]
    public let removedIdentities: [SWPerson.Identity]

    internal init(
        collaborationMetadata: SWCollaborationMetadata,
        addedIdentities: [SWPerson.Identity],
        removedIdentities: [SWPerson.Identity]
    ) {
        self.collaborationMetadata = (collaborationMetadata.copy() as? SWCollaborationMetadata)
            ?? collaborationMetadata
        self.addedIdentities = swcCopyingArray(addedIdentities)
        self.removedIdentities = swcCopyingArray(removedIdentities)
        super.init()
    }

    internal init(
        uuid: UUID,
        completion: SWActionHostCompletion,
        collaborationMetadata: SWCollaborationMetadata,
        addedIdentities: [SWPerson.Identity],
        removedIdentities: [SWPerson.Identity]
    ) {
        self.collaborationMetadata = (collaborationMetadata.copy() as? SWCollaborationMetadata)
            ?? collaborationMetadata
        self.addedIdentities = swcCopyingArray(addedIdentities)
        self.removedIdentities = swcCopyingArray(removedIdentities)
        super.init(uuid: uuid, completion: completion)
    }

    public required init?(coder: NSCoder) {
        guard let metadata = swcDecodeObject(
            SWCollaborationMetadata.self,
            from: coder,
            key: "collaborationMetadata"
        ) else {
            return nil
        }
        self.collaborationMetadata = metadata
        self.addedIdentities = (coder.decodeObject(
            of: [NSArray.self, SWPerson.Identity.self],
            forKey: "addedIdentities"
        ) as? [SWPerson.Identity]) ?? []
        self.removedIdentities = (coder.decodeObject(
            of: [NSArray.self, SWPerson.Identity.self],
            forKey: "removedIdentities"
        ) as? [SWPerson.Identity]) ?? []
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(collaborationMetadata, forKey: "collaborationMetadata")
        coder.encode(addedIdentities as NSArray, forKey: "addedIdentities")
        coder.encode(removedIdentities as NSArray, forKey: "removedIdentities")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        SWUpdateCollaborationParticipantsAction(
            uuid: uuid,
            completion: hostCompletion,
            collaborationMetadata: collaborationMetadata,
            addedIdentities: addedIdentities,
            removedIdentities: removedIdentities
        )
    }
}
