import Foundation

/// Local identity of a MultipeerConnectivity peer.
///
/// Linux has no Apple peer-ID keychain or Bonjour identity. Each constructed
/// `MCPeerID` owns a portable UUID used for `NSCopying` and equality. Two
/// separately constructed peers with the same display name are not equal; a
/// copy is equal to its source. Apple's NSCoder keys and archive layout are
/// unobserved, so `init(coder:)` fails closed with `nil` and `encode(with:)`
/// writes no guessed ABI keys.
open class MCPeerID: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

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
        _ = coder
        return nil
    }

    open func encode(with coder: NSCoder) {
        _ = coder
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
