import Foundation

/// Browser-session delegate.
public protocol ICDeviceBrowserDelegate: NSObjectProtocol {
    func deviceBrowser(_ browser: ICDeviceBrowser, didAdd device: ICDevice, moreComing: Bool)
    func deviceBrowser(_ browser: ICDeviceBrowser, didRemove device: ICDevice, moreGoing: Bool)
    func deviceBrowser(_ browser: ICDeviceBrowser, deviceDidChangeName device: ICDevice)
    func deviceBrowser(_ browser: ICDeviceBrowser, deviceDidChangeSharingState device: ICDevice)
    func deviceBrowserDidCancelSuspendOperations(_ browser: ICDeviceBrowser)
    func deviceBrowserDidResumeOperations(_ browser: ICDeviceBrowser)
    func deviceBrowserDidSuspendOperations(_ browser: ICDeviceBrowser)
    func deviceBrowserWillSuspendOperations(_ browser: ICDeviceBrowser)
}

extension ICDeviceBrowserDelegate {
    public func deviceBrowser(_ browser: ICDeviceBrowser, deviceDidChangeName device: ICDevice) {
        _ = browser
        _ = device
    }

    public func deviceBrowser(_ browser: ICDeviceBrowser, deviceDidChangeSharingState device: ICDevice) {
        _ = browser
        _ = device
    }

    public func deviceBrowserDidCancelSuspendOperations(_ browser: ICDeviceBrowser) {
        _ = browser
    }

    public func deviceBrowserDidResumeOperations(_ browser: ICDeviceBrowser) {
        _ = browser
    }

    public func deviceBrowserDidSuspendOperations(_ browser: ICDeviceBrowser) {
        _ = browser
    }

    public func deviceBrowserWillSuspendOperations(_ browser: ICDeviceBrowser) {
        _ = browser
    }
}

/// Device browser.
///
/// Linux has no Image Capture daemon or attached PTP/USB cameras.
/// `start()` records browsing state and never invents devices.
/// Contents/control authorization is fail-closed as `.denied`.
open class ICDeviceBrowser: NSObject {
    public unowned(unsafe) var delegate: (any ICDeviceBrowserDelegate)?
    open var browsedDeviceTypeMask: ICDeviceTypeMask = .camera

    private var _browsing = false
    private var _contentsAuthorizationStatus = ICAuthorizationStatus.denied
    private var _controlAuthorizationStatus = ICAuthorizationStatus.denied

    public override init() {
        super.init()
    }

    open var isBrowsing: Bool { _browsing }
    open var isSuspended: Bool { false }
    open var devices: [ICDevice]? { _browsing ? [] : nil }
    open var contentsAuthorizationStatus: ICAuthorizationStatus { _contentsAuthorizationStatus }
    open var controlAuthorizationStatus: ICAuthorizationStatus { _controlAuthorizationStatus }

    /// Begins browsing. Never reports a device; the catalog stays empty.
    open func start() {
        _browsing = true
    }

    open func stop() {
        _browsing = false
    }

    open func requestContentsAuthorization(completion: @escaping (ICAuthorizationStatus) -> Void) {
        _contentsAuthorizationStatus = .denied
        completion(_contentsAuthorizationStatus)
    }

    open func requestControlAuthorization(completion: @escaping (ICAuthorizationStatus) -> Void) {
        _controlAuthorizationStatus = .denied
        completion(_controlAuthorizationStatus)
    }

    open func resetContentsAuthorization(completion: @escaping (ICAuthorizationStatus) -> Void) {
        _contentsAuthorizationStatus = .denied
        completion(_contentsAuthorizationStatus)
    }

    open func resetControlAuthorization(completion: @escaping (ICAuthorizationStatus) -> Void) {
        _controlAuthorizationStatus = .denied
        completion(_controlAuthorizationStatus)
    }
}
