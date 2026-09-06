import Foundation

/// A custom device route discovered by the system routing picker.
///
/// Darwin vends instances from the routing daemon. Linux has no that
/// daemon and no Bluetooth / Network endpoint discovery: `networkEndpoint`
/// is always `nil`. `bluetoothIdentifier` is stored only when a Linux-only
/// initializer supplies one; the default initializer leaves it `nil`.
///
/// Apple graph: `open class AVCustomDeviceRoute: NSObject`, Sendable,
/// iOS 16+. Properties are get-only.
open class AVCustomDeviceRoute: NSObject, @unchecked Sendable {
    /// Bluetooth identifier of the route, when the system supplied one.
    public let bluetoothIdentifier: UUID?

    /// Network endpoint of the route. Always `nil` on Linux: Network is
    /// not a declared dependency and there is no route-discovery daemon.
    public var networkEndpoint: nw_endpoint_t? {
        nil
    }

    public override init() {
        self.bluetoothIdentifier = nil
        super.init()
    }

    /// Linux-only construction. Darwin instances are created by the
    /// routing controller, not by this initializer.
    public init(bluetoothIdentifier: UUID?) {
        self.bluetoothIdentifier = bluetoothIdentifier
        super.init()
    }
}
