import Foundation

/// Settings applied when finishing authorization. Linux never authorizes a
/// live accessory; the object still stores SSID and bridging identifier.
open class ASAccessorySettings: NSObject {
    public override init() {
        super.init()
    }

    open class var `default`: ASAccessorySettings {
        ASAccessorySettings()
    }

    open var ssid: String?
    open var bluetoothTransportBridgingIdentifier: Data?
}
