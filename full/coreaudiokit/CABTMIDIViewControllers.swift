import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Bluetooth MIDI central browser. Darwin scans Core Bluetooth for MIDI
/// peripherals. Linux constructs the controller and reports zero discovered
/// devices; it never starts a BLE scan.
///
/// https://developer.apple.com/documentation/coreaudiokit/cabtmidicentralviewcontroller
open class CABTMIDICentralViewController: UITableViewController {
    public convenience init() {
        self.init(style: .plain)
    }

    public override init(style: UITableView.Style) {
        super.init(style: style)
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    var hostDiscoveredPeripheralCount: Int { 0 }
}

/// Bluetooth MIDI local peripheral advertiser. Darwin makes this device a
/// MIDI-over-BLE peripheral. Linux constructs the controller and never
/// advertises.
///
/// https://developer.apple.com/documentation/coreaudiokit/cabtmidilocalperipheralviewcontroller
open class CABTMIDILocalPeripheralViewController: UIViewController {
    public override init() {
        super.init()
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    var hostIsAdvertising: Bool { false }
}
