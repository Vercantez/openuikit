import Foundation

/// Local identity of a MultipeerConnectivity peer.
///
/// Linux has no Apple peer-ID keychain or Bonjour identity. Each constructed
/// `MCPeerID` therefore owns a portable UUID that is preserved across
/// `NSCopying` and `NSSecureCoding`. Two separately constructed peers with the
/// same display name are not equal. Apple's archive key names and any
/// device-stable identity scheme remain oracle questions; this codec is a
/// Linux-local round trip, not an Apple archive claim.
open class MCPeerID: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    private static let displayNameKey = "displayName"
    private static let identityKey = "identity"

    open var displayName: String { _displayName }
    let identity: UUID

    private let _displayName: String

    public init(displayName myDisplayName: String) {
        _displayName = myDisplayName
        identity = UUID()
        super.init()
    }

    init(displayName: String, identity: UUID) {
        _displayName = displayName
        self.identity = identity
        super.init()
    }

    public required init?(coder: NSCoder) {
        let decodedName = coder.decodeObject(
            of: NSString.self,
            forKey: Self.displayNameKey
        ) as String?
        let decodedIdentity = coder.decodeObject(
            of: NSString.self,
            forKey: Self.identityKey
        ) as String?
        guard let decodedName,
              let decodedIdentity,
              let uuid = UUID(uuidString: decodedIdentity)
        else {
            return nil
        }
        _displayName = decodedName
        identity = uuid
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(_displayName, forKey: Self.displayNameKey)
        coder.encode(identity.uuidString, forKey: Self.identityKey)
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return MCPeerID(displayName: _displayName, identity: identity)
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MCPeerID else { return false }
        return identity == other.identity
    }

    open override var hash: Int {
        identity.hashValue
    }
}
