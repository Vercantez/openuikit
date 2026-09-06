import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(Network)
import Network
#endif

/// UIKit pairing controller that presents a local-device advertiser on Darwin.
///
/// Linux stores the listener provider and access, records `viewDidLoad`, and
/// never starts advertising or presents a pairing sheet.
/// `isSupported(_:)` is always `false` on this host.
///
/// https://developer.apple.com/documentation/devicediscoveryui/dddevicepairingviewcontroller
public final class DDDevicePairingViewController: UIViewController {
    private let listenerProvider: any ListenerProvider
    let linuxAccess: DDDevicePairingAccess
    private(set) var linuxViewDidLoadCount = 0
    private(set) var linuxAdvertisingAttempted = false

#if canImport(UIKit)
    public init(
        listenerProvider: any ListenerProvider,
        access: DDDevicePairingAccess
    ) {
        self.listenerProvider = listenerProvider
        self.linuxAccess = access
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        return nil
    }
#else
    public init(
        listenerProvider: any ListenerProvider,
        access: DDDevicePairingAccess
    ) {
        self.listenerProvider = listenerProvider
        self.linuxAccess = access
        super.init()
    }
#endif

    /// Darwin reports whether the listener provider can advertise here.
    /// Linux has no device-discovery daemon; always `false`.
    public static func isSupported(_ listenerProvider: any ListenerProvider) -> Bool {
        _ = listenerProvider
        return false
    }

    /// Darwin loads the pairing UI. Linux records the call and does not
    /// advertise or present a sheet.
    public override func viewDidLoad() {
        super.viewDidLoad()
        linuxViewDidLoadCount += 1
        linuxAdvertisingAttempted = false
        _ = listenerProvider
    }
}
