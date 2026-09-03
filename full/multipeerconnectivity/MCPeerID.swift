import Foundation

/// Local peer identity. Equality is NSObject identity; Darwin archive keys and
/// any internal UUID layout are unobserved, so `init(coder:)` fails closed.
open class MCPeerID: NSObject, NSSecureCoding {
    private let _displayName: String

    public var displayName: String { _displayName }

    public static var supportsSecureCoding: Bool { true }

    @available(*, unavailable)
    public override init() {
        fatalError("use init(displayName:)")
    }

    public init(displayName myDisplayName: String) {
        precondition(!myDisplayName.isEmpty, "MCPeerID displayName must be nonempty")
        _displayName = myDisplayName
        super.init()
    }

    public required init?(coder: NSCoder) {
        // Apple keyed-archive field names are unobserved. Refuse every archive
        // rather than guess a layout.
        _ = coder
        return nil
    }

    public func encode(with coder: NSCoder) {
        // Do not write guessed Apple archive keys.
        _ = coder
    }
}
