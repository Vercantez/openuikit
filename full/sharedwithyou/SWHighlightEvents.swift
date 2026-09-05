import Foundation

/// An event that can be posted through `SWHighlightCenter`.
public protocol SWHighlightEvent: NSObjectProtocol, NSCopying, NSSecureCoding {
    var highlightURL: URL { get }
}

/// Collaborative edit or comment against a highlight.
open class SWHighlightChangeEvent: NSObject, SWHighlightEvent, NSCopying, NSSecureCoding {
    public let changeEventTrigger: SWHighlightChangeEventTrigger
    public let highlightURL: URL

    public init(highlight: SWHighlight, trigger: SWHighlightChangeEventTrigger) {
        self.highlightURL = highlight.url
        self.changeEventTrigger = trigger
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SWHighlightChangeEvent(
            highlight: SWHighlight(
                hostURL: highlightURL,
                hostIdentifier: "copied"
            ),
            trigger: changeEventTrigger
        )
        return copy
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        guard coder.containsValue(forKey: "trigger"), coder.containsValue(forKey: "highlightURL") else {
            return nil
        }
        let raw = coder.decodeInteger(forKey: "trigger")
        guard
            let trigger = SWHighlightChangeEventTrigger(rawValue: raw),
            let url = coder.decodeObject(of: NSURL.self, forKey: "highlightURL") as URL?
        else {
            return nil
        }
        self.changeEventTrigger = trigger
        self.highlightURL = url
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(changeEventTrigger.rawValue, forKey: "trigger")
        coder.encode(highlightURL as NSURL, forKey: "highlightURL")
    }
}

/// Collaborator added or removed.
open class SWHighlightMembershipEvent: NSObject, SWHighlightEvent, NSCopying, NSSecureCoding {
    public let membershipEventTrigger: SWHighlightMembershipEventTrigger
    public let highlightURL: URL

    public init(highlight: SWHighlight, trigger: SWHighlightMembershipEventTrigger) {
        self.highlightURL = highlight.url
        self.membershipEventTrigger = trigger
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        SWHighlightMembershipEvent(
            highlight: SWHighlight(hostURL: highlightURL, hostIdentifier: "copied"),
            trigger: membershipEventTrigger
        )
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        guard coder.containsValue(forKey: "trigger"), coder.containsValue(forKey: "highlightURL") else {
            return nil
        }
        let raw = coder.decodeInteger(forKey: "trigger")
        guard
            let trigger = SWHighlightMembershipEventTrigger(rawValue: raw),
            let url = coder.decodeObject(of: NSURL.self, forKey: "highlightURL") as URL?
        else {
            return nil
        }
        self.membershipEventTrigger = trigger
        self.highlightURL = url
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(membershipEventTrigger.rawValue, forKey: "trigger")
        coder.encode(highlightURL as NSURL, forKey: "highlightURL")
    }
}

/// Mention of a collaborator on a highlight.
open class SWHighlightMentionEvent: NSObject, SWHighlightEvent, NSCopying, NSSecureCoding {
    public let mentionedPersonHandle: String
    public let highlightURL: URL

    public init(highlight: SWHighlight, mentionedPersonCloudKitShareHandle handle: String) {
        self.highlightURL = highlight.url
        self.mentionedPersonHandle = handle
        super.init()
    }

    public init(highlight: SWHighlight, mentionedPersonIdentity identity: SWPerson.Identity) {
        self.highlightURL = highlight.url
        self.mentionedPersonHandle = identity.rootHash.base64EncodedString()
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        SWHighlightMentionEvent(
            highlight: SWHighlight(hostURL: highlightURL, hostIdentifier: "copied"),
            mentionedPersonCloudKitShareHandle: mentionedPersonHandle
        )
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        guard coder.containsValue(forKey: "handle"), coder.containsValue(forKey: "highlightURL") else {
            return nil
        }
        guard
            let handle = coder.decodeObject(of: NSString.self, forKey: "handle") as String?,
            let url = coder.decodeObject(of: NSURL.self, forKey: "highlightURL") as URL?
        else {
            return nil
        }
        self.mentionedPersonHandle = handle
        self.highlightURL = url
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(mentionedPersonHandle as NSString, forKey: "handle")
        coder.encode(highlightURL as NSURL, forKey: "highlightURL")
    }
}

/// Created, deleted, renamed, or moved.
open class SWHighlightPersistenceEvent: NSObject, SWHighlightEvent, NSCopying, NSSecureCoding {
    public let persistenceEventTrigger: SWHighlightPersistenceEventTrigger
    public let highlightURL: URL

    public init(highlight: SWHighlight, trigger: SWHighlightPersistenceEventTrigger) {
        self.highlightURL = highlight.url
        self.persistenceEventTrigger = trigger
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        SWHighlightPersistenceEvent(
            highlight: SWHighlight(hostURL: highlightURL, hostIdentifier: "copied"),
            trigger: persistenceEventTrigger
        )
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        guard coder.containsValue(forKey: "trigger"), coder.containsValue(forKey: "highlightURL") else {
            return nil
        }
        let raw = coder.decodeInteger(forKey: "trigger")
        guard
            let trigger = SWHighlightPersistenceEventTrigger(rawValue: raw),
            let url = coder.decodeObject(of: NSURL.self, forKey: "highlightURL") as URL?
        else {
            return nil
        }
        self.persistenceEventTrigger = trigger
        self.highlightURL = url
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(persistenceEventTrigger.rawValue, forKey: "trigger")
        coder.encode(highlightURL as NSURL, forKey: "highlightURL")
    }
}
