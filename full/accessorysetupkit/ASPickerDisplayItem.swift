import Foundation

/// Display item shown in the accessory picker. Product images are opaque
/// `NSObject` values because UIKit is not a declared dependency.
open class ASPickerDisplayItem: NSObject {
    /// Setup-flow bits. Positions match pinned
    /// `ASPickerDisplayItemSetupOptions` (`1 << 0/1/2`).
    public struct SetupOptions: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let rename = SetupOptions(rawValue: 1 << 0)
        public static let confirmAuthorization = SetupOptions(rawValue: 1 << 1)
        public static let finishInApp = SetupOptions(rawValue: 1 << 2)
    }

    private let storedName: String
    private let storedProductImage: UIImage
    private let storedDescriptor: ASDiscoveryDescriptor

    @available(*, unavailable, message: "Use init(name:productImage:descriptor:)")
    public override init() {
        fatalError("ASPickerDisplayItem.init is unsupported")
    }

    public init(name: String, productImage: UIImage, descriptor: ASDiscoveryDescriptor) {
        storedName = name
        storedProductImage = productImage
        storedDescriptor = descriptor
        super.init()
    }

    open var name: String { storedName }
    open var productImage: UIImage { storedProductImage }
    open var descriptor: ASDiscoveryDescriptor { storedDescriptor }
    open var renameOptions: ASAccessory.RenameOptions = []
    open var setupOptions: SetupOptions = []
}

/// Migration display item for accessories already paired outside Accessory
/// Setup Kit. Linux never migrates live peripherals.
open class ASMigrationDisplayItem: ASPickerDisplayItem {
    open var hotspotSSID: String?
    open var peripheralIdentifier: UUID?
    open var wifiAwarePairedDeviceID: ASAccessory.WiFiAwarePairedDeviceID = 0
}

/// Display item backed by a discovered accessory rather than a descriptor.
open class ASDiscoveredDisplayItem: ASPickerDisplayItem {
    private let storedAccessory: ASDiscoveredAccessory

    public init(
        name: String,
        productImage: UIImage,
        accessory: ASDiscoveredAccessory
    ) {
        storedAccessory = accessory
        super.init(
            name: name,
            productImage: productImage,
            descriptor: accessory.descriptor
        )
    }

    @_spi(OpenUIKitHost)
    public var hostDiscoveredAccessory: ASDiscoveredAccessory { storedAccessory }
}
