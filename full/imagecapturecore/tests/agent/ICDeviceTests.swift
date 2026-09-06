@_spi(OpenUIKitHost) import ImageCaptureCore
import Foundation

final class HostDeviceDelegate: NSObject, ICDeviceDelegate {
    var opened: [(ICDevice, (any Error)?)] = []
    var closed: [(ICDevice, (any Error)?)] = []
    var ejected: [(ICDevice, (any Error)?)] = []
    var removed: [ICDevice] = []
    var ready: [ICDevice] = []
    var status: [(ICDevice, [ICDeviceStatus: Any])] = []
    var encountered: [(ICDevice, (any Error)?)] = []

    func didRemove(_ device: ICDevice) {
        removed.append(device)
    }

    func device(_ device: ICDevice, didOpenSessionWithError error: (any Error)?) {
        opened.append((device, error))
    }

    func device(_ device: ICDevice, didCloseSessionWithError error: (any Error)?) {
        closed.append((device, error))
    }

    func device(_ device: ICDevice, didEjectWithError error: (any Error)?) {
        ejected.append((device, error))
    }

    func device(_ device: ICDevice, didEncounterError error: (any Error)?) {
        encountered.append((device, error))
    }

    func device(_ device: ICDevice, didReceiveStatusInformation status: [ICDeviceStatus: Any]) {
        self.status.append((device, status))
    }

    func deviceDidBecomeReady(_ device: ICDevice) {
        ready.append(device)
    }
}

func testICDeviceBrowserInitAndIdleState() {
    let browser = ICDeviceBrowser()
    precondition(!browser.isBrowsing)
    precondition(!browser.isSuspended)
    precondition(browser.devices == nil)
    precondition(browser.contentsAuthorizationStatus == .denied)
    precondition(browser.controlAuthorizationStatus == .denied)
    precondition(browser.browsedDeviceTypeMask == .camera)
    _ = browser.delegate
}

func testICDeviceBrowserStartStopNeverInventDevices() {
    let browser = ICDeviceBrowser()
    browser.browsedDeviceTypeMask = .scanner
    precondition(browser.browsedDeviceTypeMask == .scanner)
    browser.start()
    precondition(browser.isBrowsing)
    precondition(browser.devices?.isEmpty == true)
    browser.stop()
    precondition(!browser.isBrowsing)
    precondition(browser.devices == nil)
}

func testICDeviceBrowserAuthorizationDenied() {
    let browser = ICDeviceBrowser()
    var contents: ICAuthorizationStatus?
    var control: ICAuthorizationStatus?
    browser.requestContentsAuthorization { status in
        contents = status
    }
    browser.requestControlAuthorization { status in
        control = status
    }
    precondition(contents == .denied)
    precondition(control == .denied)
    precondition(browser.contentsAuthorizationStatus == .denied)
    precondition(browser.controlAuthorizationStatus == .denied)
}

func testICDeviceBrowserResetAuthorization() {
    let browser = ICDeviceBrowser()
    var contents: ICAuthorizationStatus?
    var control: ICAuthorizationStatus?
    browser.resetContentsAuthorization { status in
        contents = status
    }
    browser.resetControlAuthorization { status in
        control = status
    }
    precondition(contents == .denied)
    precondition(control == .denied)
}

func testICDeviceHostProperties() {
    let device = ICDevice.hostMakeDevice(
        type: .scanner,
        name: "ScanJet",
        uuidString: "uuid-1",
        productKind: "Scanner",
        systemSymbolName: "scanner",
        transportType: ICDeviceTransport.transportTypeUSB.rawValue,
        capabilities: [ICDeviceCapability.canEjectOrDisconnect.rawValue],
        usbLocationID: 12,
        usbProductID: 34,
        usbVendorID: 56
    )
    precondition(device.type == .scanner)
    precondition(device.name == "ScanJet")
    precondition(device.uuidString == "uuid-1")
    precondition(device.productKind == "Scanner")
    precondition(device.systemSymbolName == "scanner")
    precondition(device.transportType == ICDeviceTransport.transportTypeUSB.rawValue)
    precondition(device.capabilities == [ICDeviceCapability.canEjectOrDisconnect.rawValue])
    precondition(device.usbLocationID == 12)
    precondition(device.usbProductID == 34)
    precondition(device.usbVendorID == 56)
    precondition(!device.hasOpenSession)
    precondition(device.icon == nil)
    let data = device.userData
    data?["k"] = "v"
    precondition(device.userData?["k"] as? String == "v")
}

func testICDeviceOpenSessionFailClosed() {
    let device = ICDevice.hostMakeDevice(type: .camera, name: "Cam")
    let delegate = HostDeviceDelegate()
    device.delegate = delegate
    device.requestOpenSession()
    precondition(!device.hasOpenSession)
    precondition(delegate.opened.count == 1)
    let error = delegate.opened[0].1 as? ICReturn
    precondition(error?.code == .deviceFailedToOpenSession)
}

func testICDeviceCloseSessionFailClosed() {
    let device = ICDevice.hostMakeDevice(type: .camera)
    let delegate = HostDeviceDelegate()
    device.delegate = delegate
    device.requestCloseSession()
    precondition(!device.hasOpenSession)
    precondition(delegate.closed.count == 1)
    let error = delegate.closed[0].1 as? ICReturn
    precondition(error?.code == .sessionNotOpened)
}

func testICDeviceEjectFailClosed() {
    let device = ICDevice.hostMakeDevice(type: .camera)
    let delegate = HostDeviceDelegate()
    device.delegate = delegate
    var completionError: (any Error)?
    device.requestEject(completion: { error in
        completionError = error
    })
    device.requestEject()
    precondition(delegate.ejected.count == 2)
    let typed = completionError as? ICReturnConnectionError
    precondition(typed?.code == .ejectFailed)
}

func testICDeviceOptionalDelegateDefaults() {
    let device = ICDevice.hostMakeDevice(type: .camera)
    let delegate = HostDeviceDelegate()
    delegate.device(device, didEncounterError: ICReturn(.invalidParam))
    delegate.device(device, didReceiveStatusInformation: [.statusNotificationKey: "warm"])
    delegate.deviceDidBecomeReady(device)
    delegate.didRemove(device)
    precondition(delegate.encountered.count == 1)
    precondition(delegate.status.count == 1)
    precondition(delegate.ready.count == 1)
    precondition(delegate.removed.count == 1)
}
