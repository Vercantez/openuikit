import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(Network)
import Network
#endif

/// UIKit picker that lists nearby devices on Darwin.
///
/// Linux `isSupported(_:using:)` is always `false`. The failable convenience
/// initializers therefore return `nil` and never start a Bonjour/Wi-Fi Aware
/// browser. `endpoint` is declared as `async throws` and always throws
/// `DeviceDiscoveryUIUnavailable.linuxHost`; the sealed runner cannot await it.
///
/// macios notes that constructing the ObjC initializer when unsupported can
/// trap. The Swift overlay is `init?`. Linux follows the failable signature
/// (returns `nil`) rather than crashing; see `oracle-questions.tsv`.
///
/// https://developer.apple.com/documentation/devicediscoveryui/dddevicepickerviewcontroller
open class DDDevicePickerViewController: UIViewController {
#if canImport(UIKit)
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        return nil
    }
#endif

    /// Darwin reports whether browsing this descriptor is supported.
    /// Linux has no mDNS/Wi-Fi Aware discovery; always `false`.
    public static func isSupported(
        _ browseDescriptor: NWBrowser.Descriptor,
        using: NWParameters? = nil
    ) -> Bool {
        _ = browseDescriptor
        _ = using
        return false
    }

    /// Failable overlay initializer. Linux returns `nil` because
    /// `isSupported` is `false`.
    public convenience init?(
        browseDescriptor: NWBrowser.Descriptor,
        parameters: NWParameters? = nil
    ) {
        self.init(
            browseDescriptor: browseDescriptor,
            parameters: parameters,
            access: .default
        )
    }

    /// Failable overlay initializer with pairing access. Linux returns `nil`.
    public convenience init?(
        browseDescriptor: NWBrowser.Descriptor,
        parameters: NWParameters? = nil,
        access: DDDevicePairingAccess = .default
    ) {
        _ = browseDescriptor
        _ = parameters
        _ = access
        return nil
    }

    /// Darwin yields the user-selected endpoint. Linux always fails closed.
    public var endpoint: NWEndpoint {
        get async throws {
            throw DeviceDiscoveryUIUnavailable.linuxHost(
                operation: "DDDevicePickerViewController.endpoint"
            )
        }
    }
}
