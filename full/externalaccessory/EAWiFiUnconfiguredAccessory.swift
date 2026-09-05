import Foundation

/// Unconfigured MFI Wireless Accessory Configuration accessory.
///
/// Linux never discovers WAC accessories. The default instance stores
/// empty strings and an empty property set.
open class EAWiFiUnconfiguredAccessory: NSObject {
    private var _name: String
    private var _manufacturer: String
    private var _model: String
    private var _ssid: String
    private var _macAddress: String
    private var _properties: EAWiFiUnconfiguredAccessoryProperties

    public var name: String { _name }
    public var manufacturer: String { _manufacturer }
    public var model: String { _model }
    public var ssid: String { _ssid }
    public var macAddress: String { _macAddress }
    public var properties: EAWiFiUnconfiguredAccessoryProperties { _properties }

    public override init() {
        _name = ""
        _manufacturer = ""
        _model = ""
        _ssid = ""
        _macAddress = ""
        _properties = []
        super.init()
    }

    @_spi(OpenUIKitHost)
    public init(
        hostName name: String,
        manufacturer: String,
        model: String,
        ssid: String,
        macAddress: String,
        properties: EAWiFiUnconfiguredAccessoryProperties
    ) {
        _name = name
        _manufacturer = manufacturer
        _model = model
        _ssid = ssid
        _macAddress = macAddress
        _properties = properties
        super.init()
    }
}

/// Delegate for WAC browser callbacks. All four methods are required on Apple.
public protocol EAWiFiUnconfiguredAccessoryBrowserDelegate: NSObjectProtocol {
    func accessoryBrowser(
        _ browser: EAWiFiUnconfiguredAccessoryBrowser,
        didUpdate state: EAWiFiUnconfiguredAccessoryBrowserState
    )
    func accessoryBrowser(
        _ browser: EAWiFiUnconfiguredAccessoryBrowser,
        didFindUnconfiguredAccessories accessories: Set<EAWiFiUnconfiguredAccessory>
    )
    func accessoryBrowser(
        _ browser: EAWiFiUnconfiguredAccessoryBrowser,
        didRemoveUnconfiguredAccessories accessories: Set<EAWiFiUnconfiguredAccessory>
    )
    func accessoryBrowser(
        _ browser: EAWiFiUnconfiguredAccessoryBrowser,
        didFinishConfiguringAccessory accessory: EAWiFiUnconfiguredAccessory,
        with status: EAWiFiUnconfiguredAccessoryConfigurationStatus
    )
}

/// WAC browser.
///
/// Linux has no Apple Wireless Accessory Configuration daemon. Searching
/// fail-closes to `.wiFiUnavailable` on the caller thread (queue hops are
/// unobserved). Configuration fail-closes with `.failed`. No accessory is
/// ever found.
open class EAWiFiUnconfiguredAccessoryBrowser: NSObject {
    public weak var delegate: (any EAWiFiUnconfiguredAccessoryBrowserDelegate)?
    private var _queue: dispatch_queue_t?
    private var _searching = false

    public var unconfiguredAccessories: Set<EAWiFiUnconfiguredAccessory> { [] }

    public init(
        delegate: (any EAWiFiUnconfiguredAccessoryBrowserDelegate)?,
        queue: dispatch_queue_t?
    ) {
        self.delegate = delegate
        _queue = queue
        super.init()
    }

    @_spi(OpenUIKitHost)
    public var hostQueue: dispatch_queue_t? { _queue }

    @_spi(OpenUIKitHost)
    public var hostIsSearching: Bool { _searching }

    open func startSearchingForUnconfiguredAccessories(matching predicate: NSPredicate?) {
        _ = predicate
        _searching = false
        // Linux has no WAC/MFi Wi-Fi accessory daemon. Do not invent a
        // searching interval or discovered accessories.
        delegate?.accessoryBrowser(self, didUpdate: .wiFiUnavailable)
    }

    open func stopSearchingForUnconfiguredAccessories() {
        _searching = false
        delegate?.accessoryBrowser(self, didUpdate: .stopped)
    }

    open func configureAccessory(
        _ accessory: EAWiFiUnconfiguredAccessory,
        withConfigurationUIOn viewController: UIViewController
    ) {
        _ = viewController
        delegate?.accessoryBrowser(
            self,
            didFinishConfiguringAccessory: accessory,
            with: .failed
        )
    }
}
