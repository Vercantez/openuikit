import Foundation

/// A collaboration highlight. Linux never consults CloudKit or Messages
/// for collaboration metadata; instances exist only as host fixtures or
/// decoded archives.
open class SWCollaborationHighlight: SWHighlight {
    public let collaborationIdentifier: String
    public let title: String?
    public let creationDate: Date
    public let contentType: UTType

    init(
        hostURL: URL,
        hostIdentifier: String,
        collaborationIdentifier: String,
        title: String?,
        creationDate: Date,
        contentType: UTType
    ) {
        self.collaborationIdentifier = collaborationIdentifier
        self.title = title
        self.creationDate = creationDate
        self.contentType = contentType
        super.init(hostURL: hostURL, hostIdentifier: hostIdentifier)
    }

    public override func copy(with zone: NSZone? = nil) -> Any {
        SWCollaborationHighlight(
            hostURL: url,
            hostIdentifier: (identifier as? NSString as String?) ?? String(describing: identifier),
            collaborationIdentifier: collaborationIdentifier,
            title: title,
            creationDate: creationDate,
            contentType: contentType
        )
    }

    public required init?(coder: NSCoder) {
        guard
            let collaborationIdentifier = coder.decodeObject(
                of: NSString.self,
                forKey: "collaborationIdentifier"
            ) as String?,
            let creationDate = coder.decodeObject(of: NSDate.self, forKey: "creationDate") as Date?,
            let contentIdentifier = coder.decodeObject(
                of: NSString.self,
                forKey: "contentType"
            ) as String?
        else {
            return nil
        }
        self.collaborationIdentifier = collaborationIdentifier
        self.title = coder.decodeObject(of: NSString.self, forKey: "title") as String?
        self.creationDate = creationDate
        self.contentType = UTType(identifier: contentIdentifier)
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(collaborationIdentifier as NSString, forKey: "collaborationIdentifier")
        coder.encode(title as NSString?, forKey: "title")
        coder.encode(creationDate as NSDate, forKey: "creationDate")
        coder.encode(contentType.identifier as NSString, forKey: "contentType")
    }
}
