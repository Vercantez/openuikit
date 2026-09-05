import Foundation

/// Shared accessory manager.
///
/// Apple's `-init` is unsupported (`+sharedAccessoryManager` is the
/// entry point). Linux has no External Accessory daemon or Bluetooth
/// picker UI: `connectedAccessories` is empty, local-notification
/// registration is a no-op that never posts connect/disconnect events,
/// and the picker fail-closes with `resultFailed`.
open class EAAccessoryManager: NSObject {
    private static let _shared = EAAccessoryManager(token: ())
    private var notificationRegistrationCount = 0

    @available(*, unavailable, message: "Use EAAccessoryManager.shared()")
    public override init() {
        fatalError("EAAccessoryManager.init is unsupported")
    }

    private init(token: ()) {
        super.init()
    }

    open class func shared() -> EAAccessoryManager {
        _shared
    }

    open var connectedAccessories: [EAAccessory] { [] }

    open func registerForLocalNotifications() {
        notificationRegistrationCount += 1
    }

    open func unregisterForLocalNotifications() {
        if notificationRegistrationCount > 0 {
            notificationRegistrationCount -= 1
        }
    }

    /// ObjC completion-based picker. Linux has no Bluetooth accessory
    /// picker UI; the completion is invoked synchronously with
    /// `EABluetoothAccessoryPickerError.resultFailed`.
    open func showBluetoothAccessoryPicker(
        withNameFilter predicate: NSPredicate?,
        completion: EABluetoothAccessoryPickerCompletion?
    ) {
        _ = predicate
        completion?(EABluetoothAccessoryPickerError(.resultFailed))
    }

    /// Swift async overlay of `showBluetoothAccessoryPickerWithNameFilter:completion:`.
    /// Throws immediately; there is no picker UI on Linux.
    open func showBluetoothAccessoryPicker(withNameFilter predicate: NSPredicate?) async throws {
        _ = predicate
        throw EABluetoothAccessoryPickerError(.resultFailed)
    }

    @_spi(OpenUIKitHost)
    public var hostNotificationRegistrationCount: Int {
        notificationRegistrationCount
    }
}
