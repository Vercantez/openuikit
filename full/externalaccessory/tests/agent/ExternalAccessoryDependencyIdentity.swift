import ExternalAccessory
import Foundation

/// Isolated-host identity probe. The sealed host gate does not compile this
/// file. The later EC2 integration build imports real Foundation and passes
/// genuine Foundation values through public ExternalAccessory APIs.
func externalAccessoryDependencyIdentityProbe() {
    let domain: String = EABluetoothAccessoryPickerErrorDomain
    precondition(domain == "EABluetoothAccessoryPickerErrorDomain")

    let info: [String: Any] = ["foundation": UUID().uuidString]
    let error = EABluetoothAccessoryPickerError(.resultFailed, userInfo: info)
    precondition(error.userInfo["foundation"] as? String == info["foundation"] as? String)
    let ns = error as NSError
    precondition(ns.domain == EABluetoothAccessoryPickerErrorDomain)
    precondition(ns.code == EABluetoothAccessoryPickerError.Code.resultFailed.rawValue)

    let predicate = NSPredicate(value: true)
    var captured: (any Error)?
    EAAccessoryManager.shared().showBluetoothAccessoryPicker(withNameFilter: predicate) { err in
        captured = err
    }
    let picker = captured as? EABluetoothAccessoryPickerError
    precondition(picker?.code == .resultFailed)

    let name = NSNotification.Name.EAAccessoryDidConnect
    precondition(name.rawValue == "EAAccessoryDidConnectNotification")
    _ = EAAccessoryKey
    _ = NotificationCenter.default
}
