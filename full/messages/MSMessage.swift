import Foundation

/// Opaque session token for updating an `MSMessage` bubble.
///
/// Linux coding round-trips a process-local identifier. The Darwin archive
/// layout is unobserved.
open class MSSession: NSObject, NSSecureCoding {
    public let linuxSessionIdentifier: UUID

    public override init() {
        self.linuxSessionIdentifier = UUID()
        super.init()
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        let decoded = coder.decodeObject(
            of: NSString.self,
            forKey: "linuxSessionIdentifier"
        ) as String?
        self.linuxSessionIdentifier = decoded.flatMap(UUID.init(uuidString:)) ?? UUID()
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(
            linuxSessionIdentifier.uuidString as NSString,
            forKey: "linuxSessionIdentifier"
        )
    }
}

/// Abstract layout base. Subclasses copy their stored fields.
open class MSMessageLayout: NSObject, NSCopying {
    public override init() {
        super.init()
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        MSMessageLayout()
    }
}

/// Template balloon captions and media. `image` (`UIImage`) is omitted on
/// the isolated host: UIKit is not importable and a public lookalike is
/// forbidden.
open class MSMessageTemplateLayout: MSMessageLayout {
    public var caption: String?
    public var subcaption: String?
    public var trailingCaption: String?
    public var trailingSubcaption: String?
    public var mediaFileURL: URL?
    public var imageTitle: String?
    public var imageSubtitle: String?

    public override init() {
        super.init()
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        let copy = MSMessageTemplateLayout()
        copy.caption = caption
        copy.subcaption = subcaption
        copy.trailingCaption = trailingCaption
        copy.trailingSubcaption = trailingSubcaption
        copy.mediaFileURL = mediaFileURL
        copy.imageTitle = imageTitle
        copy.imageSubtitle = imageSubtitle
        return copy
    }
}

/// Live-layout wrapper around a template alternate.
open class MSMessageLiveLayout: MSMessageLayout {
    public let alternateLayout: MSMessageTemplateLayout

    public init(alternateLayout: MSMessageTemplateLayout) {
        self.alternateLayout = (alternateLayout.copy() as? MSMessageTemplateLayout)
            ?? alternateLayout
        super.init()
    }

    @available(*, unavailable)
    public override init() {
        fatalError("MSMessageLiveLayout requires init(alternateLayout:)")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        MSMessageLiveLayout(alternateLayout: alternateLayout)
    }
}

/// Interactive iMessage balloon. Linux stores caller fields and copies the
/// layout; it never marks a message pending or assigns an Apple sender.
open class MSMessage: NSObject, NSCopying, NSSecureCoding {
    public private(set) var session: MSSession?
    public private(set) var isPending: Bool
    public private(set) var senderParticipantIdentifier: UUID
    public var shouldExpire: Bool
    public var accessibilityLabel: String?
    public var summaryText: String?
    public var error: (any Error)?
    public var url: URL?

    private var storedLayout: MSMessageLayout?

    public var layout: MSMessageLayout? {
        get { storedLayout }
        set {
            storedLayout = newValue.flatMap { $0.copy() as? MSMessageLayout }
        }
    }

    public override init() {
        self.session = nil
        self.isPending = false
        self.senderParticipantIdentifier = MessagesLinuxSupport.nullParticipant
        self.shouldExpire = false
        super.init()
    }

    public init(session: MSSession) {
        self.session = session
        self.isPending = false
        self.senderParticipantIdentifier = MessagesLinuxSupport.nullParticipant
        self.shouldExpire = false
        super.init()
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        let session = coder.decodeObject(
            of: MSSession.self,
            forKey: "linuxSession"
        )
        self.session = session
        self.isPending = coder.decodeBool(forKey: "linuxPending")
        let sender = coder.decodeObject(
            of: NSString.self,
            forKey: "linuxSender"
        ) as String?
        self.senderParticipantIdentifier =
            sender.flatMap(UUID.init(uuidString:)) ?? MessagesLinuxSupport.nullParticipant
        self.shouldExpire = coder.decodeBool(forKey: "linuxShouldExpire")
        self.accessibilityLabel = coder.decodeObject(
            of: NSString.self,
            forKey: "linuxAccessibilityLabel"
        ) as String?
        self.summaryText = coder.decodeObject(
            of: NSString.self,
            forKey: "linuxSummaryText"
        ) as String?
        if let urlString = coder.decodeObject(
            of: NSString.self,
            forKey: "linuxURL"
        ) as String? {
            self.url = URL(string: urlString)
        } else {
            self.url = nil
        }
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(session, forKey: "linuxSession")
        coder.encode(isPending, forKey: "linuxPending")
        coder.encode(senderParticipantIdentifier.uuidString as NSString, forKey: "linuxSender")
        coder.encode(shouldExpire, forKey: "linuxShouldExpire")
        coder.encode(accessibilityLabel as NSString?, forKey: "linuxAccessibilityLabel")
        coder.encode(summaryText as NSString?, forKey: "linuxSummaryText")
        coder.encode(url?.absoluteString as NSString?, forKey: "linuxURL")
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        let copy: MSMessage
        if let session {
            copy = MSMessage(session: session)
        } else {
            copy = MSMessage()
        }
        copy.isPending = isPending
        copy.senderParticipantIdentifier = senderParticipantIdentifier
        copy.shouldExpire = shouldExpire
        copy.accessibilityLabel = accessibilityLabel
        copy.summaryText = summaryText
        copy.error = error
        copy.url = url
        copy.layout = layout
        return copy
    }
}
