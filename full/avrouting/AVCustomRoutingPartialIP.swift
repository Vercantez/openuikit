import Foundation

/// A partial IP address plus mask describing a range of known route IPs.
///
/// Address and mask `Data` values are copied at initialization. Linux
/// does not validate length or IPv4-vs-IPv6 shape: Darwin's rejection
/// rules are unobserved.
///
/// Apple graph: `open class AVCustomRoutingPartialIP: NSObject`, Sendable,
/// iOS 16.1+. Pinned macios marks `DisableDefaultCtor`; designated
/// `init(address:mask:)`.
open class AVCustomRoutingPartialIP: NSObject, @unchecked Sendable {
    public let address: Data
    public let mask: Data

    public init(address: Data, mask: Data) {
        self.address = Data(address)
        self.mask = Data(mask)
        super.init()
    }

    @available(*, unavailable)
    public override init() {
        fatalError("AVCustomRoutingPartialIP requires init(address:mask:)")
    }
}
