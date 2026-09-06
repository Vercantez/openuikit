import DeviceDiscoveryExtension
import Foundation

func ddExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}
