import Foundation

/// Delegate for accessory disconnect. The protocol method is optional on
/// Apple; this overlay supplies an empty default.
public protocol EAAccessoryDelegate: NSObjectProtocol {
    func accessoryDidDisconnect(_ accessory: EAAccessory)
}

extension EAAccessoryDelegate {
    public func accessoryDidDisconnect(_ accessory: EAAccessory) {
        _ = accessory
    }
}

/// Connected MFi accessory record.
///
/// Apple's `-init` is unsupported (`EAAccessoryManager` creates instances).
/// Linux has no External Accessory daemon, so
/// `EAAccessoryManager.connectedAccessories` is always empty. Tests construct
/// records through `@_spi(OpenUIKitHost)` without claiming a live accessory.
open class EAAccessory: NSObject {
    private var _connected: Bool
    private var _connectionID: UInt
    private var _name: String
    private var _manufacturer: String
    private var _modelNumber: String
    private var _serialNumber: String
    private var _firmwareRevision: String
    private var _hardwareRevision: String
    private var _protocolStrings: [String]
    private var _dockType: String
    private var _delegate: (any EAAccessoryDelegate)?

    public unowned(unsafe) var delegate: (any EAAccessoryDelegate)? {
        get { _delegate }
        set { _delegate = newValue }
    }

    public var isConnected: Bool { _connected }
    public var connectionID: UInt { _connectionID }
    public var name: String { _name }
    public var manufacturer: String { _manufacturer }
    public var modelNumber: String { _modelNumber }
    public var serialNumber: String { _serialNumber }
    public var firmwareRevision: String { _firmwareRevision }
    public var hardwareRevision: String { _hardwareRevision }
    public var protocolStrings: [String] { _protocolStrings }
    public var dockType: String { _dockType }

    @available(*, unavailable, message: "EAAccessoryManager is responsible for creating EAAccessory instances")
    public override init() {
        fatalError("EAAccessory.init is unsupported")
    }

    init(
        connected: Bool,
        connectionID: UInt,
        name: String,
        manufacturer: String,
        modelNumber: String,
        serialNumber: String,
        firmwareRevision: String,
        hardwareRevision: String,
        protocolStrings: [String],
        dockType: String
    ) {
        _connected = connected
        _connectionID = connectionID
        _name = name
        _manufacturer = manufacturer
        _modelNumber = modelNumber
        _serialNumber = serialNumber
        _firmwareRevision = firmwareRevision
        _hardwareRevision = hardwareRevision
        _protocolStrings = protocolStrings
        _dockType = dockType
        super.init()
    }

    /// Host-only constructor. Does not register the accessory with
    /// `EAAccessoryManager.connectedAccessories`.
    @_spi(OpenUIKitHost)
    public static func hostMakeAccessory(
        connected: Bool = false,
        connectionID: UInt = 0,
        name: String = "",
        manufacturer: String = "",
        modelNumber: String = "",
        serialNumber: String = "",
        firmwareRevision: String = "",
        hardwareRevision: String = "",
        protocolStrings: [String] = [],
        dockType: String = ""
    ) -> EAAccessory {
        EAAccessory(
            connected: connected,
            connectionID: connectionID,
            name: name,
            manufacturer: manufacturer,
            modelNumber: modelNumber,
            serialNumber: serialNumber,
            firmwareRevision: firmwareRevision,
            hardwareRevision: hardwareRevision,
            protocolStrings: protocolStrings,
            dockType: dockType
        )
    }

    /// Host-driven disconnect callback. Does not invent a hardware unplug.
    @_spi(OpenUIKitHost)
    public func hostNotifyDisconnect() {
        _connected = false
        _delegate?.accessoryDidDisconnect(self)
    }
}
