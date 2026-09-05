import Foundation

/// A Shared with You highlight. Darwin vends these from the Messages
/// Shared with You daemon; Linux only constructs them through host SPI
/// or secure coding.
open class SWHighlight: NSObject, NSCopying, NSSecureCoding {
    public let url: URL
    public let identifier: any NSCopying & NSSecureCoding

    init(hostURL: URL, hostIdentifier: String) {
        self.url = hostURL
        self.identifier = hostIdentifier as NSString
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        SWHighlight(
            hostURL: url,
            hostIdentifier: (identifier as? NSString as String?) ?? String(describing: identifier)
        )
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        guard let url = coder.decodeObject(of: NSURL.self, forKey: "url") as URL? else {
            return nil
        }
        let identifier = coder.decodeObject(
            of: [NSString.self, NSUUID.self],
            forKey: "identifier"
        )
        guard let stored = identifier as? (any NSCopying & NSSecureCoding) else {
            return nil
        }
        self.url = url
        self.identifier = stored
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(url as NSURL, forKey: "url")
        coder.encode(identifier, forKey: "identifier")
    }
}
