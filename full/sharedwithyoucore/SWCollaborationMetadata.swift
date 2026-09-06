import Foundation

/// Metadata describing a collaboration for the share sheet and action
/// handlers.
///
/// Constructing metadata with a collaboration identifier does not mint a
/// local identifier, and vice versa: the unused identifier is empty. Darwin's
/// minting policy is unobserved. Share-option properties copy on set
/// (`@NSCopying`).
open class SWCollaborationMetadata: NSObject, NSCopying, NSSecureCoding {
    public let collaborationIdentifier: SWCollaborationIdentifier
    public let localIdentifier: SWLocalCollaborationIdentifier
    public var title: String?
    public var initiatorHandle: String?
    public var initiatorNameComponents: PersonNameComponents?

    private var storedDefaultShareOptions: SWCollaborationShareOptions?
    private var storedUserSelectedShareOptions: SWCollaborationShareOptions?

    public var defaultShareOptions: SWCollaborationShareOptions? {
        get { storedDefaultShareOptions }
        set {
            storedDefaultShareOptions = newValue.flatMap { $0.copy() as? SWCollaborationShareOptions }
        }
    }

    public var userSelectedShareOptions: SWCollaborationShareOptions? {
        get { storedUserSelectedShareOptions }
        set {
            storedUserSelectedShareOptions = newValue.flatMap { $0.copy() as? SWCollaborationShareOptions }
        }
    }

    public static var supportsSecureCoding: Bool { true }

    internal init(
        collaborationIdentifier: SWCollaborationIdentifier,
        localIdentifier: SWLocalCollaborationIdentifier
    ) {
        self.collaborationIdentifier = collaborationIdentifier
        self.localIdentifier = localIdentifier
        super.init()
    }

    public convenience init(collaborationIdentifier: SWCollaborationIdentifier) {
        self.init(
            collaborationIdentifier: collaborationIdentifier,
            localIdentifier: SWLocalCollaborationIdentifier("")
        )
    }

    public convenience init(localIdentifier: SWLocalCollaborationIdentifier) {
        self.init(
            collaborationIdentifier: SWCollaborationIdentifier(""),
            localIdentifier: localIdentifier
        )
    }

    public required init?(coder: NSCoder) {
        guard let collaborationRaw = swcDecodeObject(
            NSString.self,
            from: coder,
            key: "collaborationIdentifier"
        ) as String?,
            let localRaw = swcDecodeObject(
                NSString.self,
                from: coder,
                key: "localIdentifier"
            ) as String?
        else {
            return nil
        }
        self.collaborationIdentifier = SWCollaborationIdentifier(rawValue: collaborationRaw)
        self.localIdentifier = SWLocalCollaborationIdentifier(rawValue: localRaw)
        self.title = swcDecodeObject(NSString.self, from: coder, key: "title") as String?
        self.initiatorHandle = swcDecodeObject(NSString.self, from: coder, key: "initiatorHandle") as String?
        let given = swcDecodeObject(NSString.self, from: coder, key: "initiatorGivenName") as String?
        let family = swcDecodeObject(NSString.self, from: coder, key: "initiatorFamilyName") as String?
        if given != nil || family != nil {
            var components = PersonNameComponents()
            components.givenName = given
            components.familyName = family
            self.initiatorNameComponents = components
        } else {
            self.initiatorNameComponents = nil
        }
        self.storedDefaultShareOptions = swcDecodeObject(
            SWCollaborationShareOptions.self,
            from: coder,
            key: "defaultShareOptions"
        )
        self.storedUserSelectedShareOptions = swcDecodeObject(
            SWCollaborationShareOptions.self,
            from: coder,
            key: "userSelectedShareOptions"
        )
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(collaborationIdentifier.rawValue as NSString, forKey: "collaborationIdentifier")
        coder.encode(localIdentifier.rawValue as NSString, forKey: "localIdentifier")
        if let title {
            coder.encode(title as NSString, forKey: "title")
        }
        if let initiatorHandle {
            coder.encode(initiatorHandle as NSString, forKey: "initiatorHandle")
        }
        if let given = initiatorNameComponents?.givenName {
            coder.encode(given as NSString, forKey: "initiatorGivenName")
        }
        if let family = initiatorNameComponents?.familyName {
            coder.encode(family as NSString, forKey: "initiatorFamilyName")
        }
        if let storedDefaultShareOptions {
            coder.encode(storedDefaultShareOptions, forKey: "defaultShareOptions")
        }
        if let storedUserSelectedShareOptions {
            coder.encode(storedUserSelectedShareOptions, forKey: "userSelectedShareOptions")
        }
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        let copy = SWCollaborationMetadata(
            collaborationIdentifier: collaborationIdentifier,
            localIdentifier: localIdentifier
        )
        copy.title = title
        copy.initiatorHandle = initiatorHandle
        copy.initiatorNameComponents = initiatorNameComponents
        copy.defaultShareOptions = defaultShareOptions
        copy.userSelectedShareOptions = userSelectedShareOptions
        return copy
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? SWCollaborationMetadata else { return false }
        return collaborationIdentifier == other.collaborationIdentifier
            && localIdentifier == other.localIdentifier
            && title == other.title
            && initiatorHandle == other.initiatorHandle
            && initiatorNameComponents == other.initiatorNameComponents
            && storedDefaultShareOptions == other.storedDefaultShareOptions
            && storedUserSelectedShareOptions == other.storedUserSelectedShareOptions
    }
}
