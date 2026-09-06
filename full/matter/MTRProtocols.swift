import Foundation

public protocol MTRStorage: NSObjectProtocol {
    func storageData(forKey key: String) -> Data?
    func setStorageData(_ value: Data, forKey key: String) -> Bool
    func removeStorageData(forKey key: String) -> Bool
}

public protocol MTRPersistentStorageDelegate: MTRStorage {}

public protocol MTRKeypair: NSObjectProtocol {
    func signMessageECDSA_RAW(_ message: Data) -> Data
    func signMessageECDSA_DER(_ message: Data) -> Data
}

public protocol MTRDeviceControllerStorageDelegate: NSObjectProtocol {}

public protocol MTRDeviceControllerDelegate: NSObjectProtocol {}

public protocol MTRDevicePairingDelegate: NSObjectProtocol {}

public protocol MTRCommissionableBrowserDelegate: NSObjectProtocol {}

public protocol MTRXPCServerProtocol_MTRDevice: NSObjectProtocol {}

public protocol MTRXPCServerProtocol_MTRDeviceController: NSObjectProtocol {}

public protocol MTRXPCServerProtocol: MTRXPCServerProtocol_MTRDevice, MTRXPCServerProtocol_MTRDeviceController {}

public protocol MTRNOCChainIssuer: NSObjectProtocol {}

public protocol MTROperationalCertificateIssuer: NSObjectProtocol {}

public protocol MTRDeviceDelegate: NSObjectProtocol {
    func device(_ device: MTRDevice, stateChanged state: MTRDeviceState)
    func device(_ device: MTRDevice, receivedAttributeReport attributeReport: [[String: Any]])
    func device(_ device: MTRDevice, receivedEventReport eventReport: [[String: Any]])
    func deviceBecameActive(_ device: MTRDevice)
    func deviceCachePrimed(_ device: MTRDevice)
    func deviceConfigurationChanged(_ device: MTRDevice)
}

extension MTRDeviceDelegate {
    public func deviceBecameActive(_ device: MTRDevice) { _ = device }
    public func deviceCachePrimed(_ device: MTRDevice) { _ = device }
    public func deviceConfigurationChanged(_ device: MTRDevice) { _ = device }
}

public protocol MTRXPCClientProtocol_MTRDevice: NSObjectProtocol {}

public protocol MTRXPCClientProtocol_MTRDeviceController: NSObjectProtocol {}

public protocol MTRXPCClientProtocol: MTRXPCClientProtocol_MTRDevice, MTRXPCClientProtocol_MTRDeviceController {}

public protocol MTRDeviceAttestationDelegate: NSObjectProtocol {}

public protocol MTROTAProviderDelegate: NSObjectProtocol {}

public protocol MTRDeviceControllerClientProtocol: NSObjectProtocol {}

public protocol MTRDeviceControllerServerProtocol: NSObjectProtocol {}

