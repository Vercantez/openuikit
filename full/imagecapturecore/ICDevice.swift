import Foundation

/// Device-session delegate. Required methods match the Swift overlay;
/// optional methods have empty defaults.
public protocol ICDeviceDelegate: NSObjectProtocol {
    func didRemove(_ device: ICDevice)
    func device(_ device: ICDevice, didOpenSessionWithError error: (any Error)?)
    func device(_ device: ICDevice, didCloseSessionWithError error: (any Error)?)
    func device(_ device: ICDevice, didEjectWithError error: (any Error)?)
    func device(_ device: ICDevice, didEncounterError error: (any Error)?)
    func device(_ device: ICDevice, didReceiveStatusInformation status: [ICDeviceStatus: Any])
    func deviceDidBecomeReady(_ device: ICDevice)
}

extension ICDeviceDelegate {
    public func device(_ device: ICDevice, didEjectWithError error: (any Error)?) {
        _ = device
        _ = error
    }

    public func device(_ device: ICDevice, didEncounterError error: (any Error)?) {
        _ = device
        _ = error
    }

    public func device(_ device: ICDevice, didReceiveStatusInformation status: [ICDeviceStatus: Any]) {
        _ = device
        _ = status
    }

    public func deviceDidBecomeReady(_ device: ICDevice) {
        _ = device
    }
}

/// Image Capture device.
///
/// Linux has no Image Capture daemon, USB/PTP camera, or scanner.
/// Session open, close, and eject fail-closed with documented error
/// codes. Apple's `-init` is unsupported; tests construct records
/// through `@_spi(OpenUIKitHost)`.
open class ICDevice: NSObject {
    public unowned(unsafe) var delegate: (any ICDeviceDelegate)?

    private var _type: ICDeviceType
    private var _name: String?
    private var _uuidString: String?
    private var _productKind: String?
    private var _systemSymbolName: String?
    private var _transportType: String?
    private var _capabilities: [String]
    private var _hasOpenSession = false
    private var _usbLocationID: Int32 = 0
    private var _usbProductID: Int32 = 0
    private var _usbVendorID: Int32 = 0
    private var _userData: NSMutableDictionary?
    private var _icon: CGImage?

    @available(*, unavailable, message: "ICDevice is created by ICDeviceBrowser; Linux constructs records via host SPI")
    public override init() {
        fatalError("ICDevice.init is unsupported")
    }

    init(hostType type: ICDeviceType) {
        _type = type
        _capabilities = []
        super.init()
    }

    func hostApplyIdentity(
        name: String?,
        uuidString: String?,
        productKind: String? = nil,
        systemSymbolName: String? = nil,
        transportType: String? = nil,
        capabilities: [String],
        usbLocationID: Int32 = 0,
        usbProductID: Int32 = 0,
        usbVendorID: Int32 = 0
    ) {
        _name = name
        _uuidString = uuidString
        _productKind = productKind
        _systemSymbolName = systemSymbolName
        _transportType = transportType
        _capabilities = capabilities
        _usbLocationID = usbLocationID
        _usbProductID = usbProductID
        _usbVendorID = usbVendorID
    }

    @_spi(OpenUIKitHost)
    public static func hostMakeDevice(
        type: ICDeviceType,
        name: String? = nil,
        uuidString: String? = nil,
        productKind: String? = nil,
        systemSymbolName: String? = nil,
        transportType: String? = nil,
        capabilities: [String] = [],
        usbLocationID: Int32 = 0,
        usbProductID: Int32 = 0,
        usbVendorID: Int32 = 0
    ) -> ICDevice {
        let device = ICDevice(hostType: type)
        device.hostApplyIdentity(
            name: name,
            uuidString: uuidString,
            productKind: productKind,
            systemSymbolName: systemSymbolName,
            transportType: transportType,
            capabilities: capabilities,
            usbLocationID: usbLocationID,
            usbProductID: usbProductID,
            usbVendorID: usbVendorID
        )
        return device
    }

    open var type: ICDeviceType { _type }
    open var name: String? { _name }
    open var uuidString: String? { _uuidString }
    open var productKind: String? { _productKind }
    open var systemSymbolName: String? { _systemSymbolName }
    open var transportType: String? { _transportType }
    open var capabilities: [String] { _capabilities }
    open var hasOpenSession: Bool { _hasOpenSession }
    open var usbLocationID: Int32 { _usbLocationID }
    open var usbProductID: Int32 { _usbProductID }
    open var usbVendorID: Int32 { _usbVendorID }
    open var icon: CGImage? { _icon }

    open var userData: NSMutableDictionary? {
        if _userData == nil {
            _userData = NSMutableDictionary()
        }
        return _userData
    }

    /// Fail-closed: no Image Capture daemon. Reports
    /// `deviceFailedToOpenSession` and leaves `hasOpenSession` false.
    open func requestOpenSession() {
        _hasOpenSession = false
        delegate?.device(self, didOpenSessionWithError: ICReturn(.deviceFailedToOpenSession))
    }

    open func requestOpenSession(options: [ICSessionOptions: Any]? = nil) async throws {
        _ = options
        _hasOpenSession = false
        throw ICReturn(.deviceFailedToOpenSession)
    }

    /// Fail-closed: there is never an open session.
    open func requestCloseSession() {
        _hasOpenSession = false
        delegate?.device(self, didCloseSessionWithError: ICReturn(.sessionNotOpened))
    }

    open func requestCloseSession(options: [ICSessionOptions: Any]? = nil) async throws {
        _ = options
        _hasOpenSession = false
        throw ICReturn(.sessionNotOpened)
    }

    open func requestEject() {
        delegate?.device(self, didEjectWithError: ICReturnConnectionError(.ejectFailed))
    }

    open func requestEject(completion: @escaping ((any Error)?) -> Void) {
        let error = ICReturnConnectionError(.ejectFailed)
        delegate?.device(self, didEjectWithError: error)
        completion(error)
    }
}
