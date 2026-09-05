import Foundation

public protocol HMHomeManagerDelegate: NSObjectProtocol {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager)
    func homeManagerDidUpdatePrimaryHome(_ manager: HMHomeManager)
    func homeManager(_ manager: HMHomeManager, didAdd home: HMHome)
    func homeManager(_ manager: HMHomeManager, didRemove home: HMHome)
    func homeManager(_ manager: HMHomeManager, didReceiveAddAccessoryRequest request: HMAddAccessoryRequest)
    func homeManager(_ manager: HMHomeManager, didUpdate status: HMHomeManagerAuthorizationStatus)
}

extension HMHomeManagerDelegate {
    public func homeManagerDidUpdateHomes(_ manager: HMHomeManager) { _ = manager }
    public func homeManagerDidUpdatePrimaryHome(_ manager: HMHomeManager) { _ = manager }
    public func homeManager(_ manager: HMHomeManager, didAdd home: HMHome) { _ = (manager, home) }
    public func homeManager(_ manager: HMHomeManager, didRemove home: HMHome) { _ = (manager, home) }
    public func homeManager(_ manager: HMHomeManager, didReceiveAddAccessoryRequest request: HMAddAccessoryRequest) {
        _ = (manager, request)
    }
    public func homeManager(_ manager: HMHomeManager, didUpdate status: HMHomeManagerAuthorizationStatus) {
        _ = (manager, status)
    }
}

public protocol HMAccessoryDelegate: NSObjectProtocol, Sendable {
    func accessoryDidUpdateName(_ accessory: HMAccessory)
    func accessory(_ accessory: HMAccessory, didUpdateNameFor service: HMService)
    func accessory(_ accessory: HMAccessory, didUpdateAssociatedServiceTypeFor service: HMService)
    func accessoryDidUpdateServices(_ accessory: HMAccessory)
    func accessory(_ accessory: HMAccessory, didAdd profile: HMAccessoryProfile)
    func accessory(_ accessory: HMAccessory, didRemove profile: HMAccessoryProfile)
    func accessoryDidUpdateReachability(_ accessory: HMAccessory)
    func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic)
    func accessory(_ accessory: HMAccessory, didUpdateFirmwareVersion firmwareVersion: String)
}

extension HMAccessoryDelegate {
    public func accessoryDidUpdateName(_ accessory: HMAccessory) { _ = accessory }
    public func accessory(_ accessory: HMAccessory, didUpdateNameFor service: HMService) { _ = (accessory, service) }
    public func accessory(_ accessory: HMAccessory, didUpdateAssociatedServiceTypeFor service: HMService) {
        _ = (accessory, service)
    }
    public func accessoryDidUpdateServices(_ accessory: HMAccessory) { _ = accessory }
    public func accessory(_ accessory: HMAccessory, didAdd profile: HMAccessoryProfile) { _ = (accessory, profile) }
    public func accessory(_ accessory: HMAccessory, didRemove profile: HMAccessoryProfile) { _ = (accessory, profile) }
    public func accessoryDidUpdateReachability(_ accessory: HMAccessory) { _ = accessory }
    public func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic) {
        _ = (accessory, service, characteristic)
    }
    public func accessory(_ accessory: HMAccessory, didUpdateFirmwareVersion firmwareVersion: String) {
        _ = (accessory, firmwareVersion)
    }
}

public protocol HMAccessoryBrowserDelegate: NSObjectProtocol {
    func accessoryBrowser(_ browser: HMAccessoryBrowser, didFindNewAccessory accessory: HMAccessory)
    func accessoryBrowser(_ browser: HMAccessoryBrowser, didRemoveNewAccessory accessory: HMAccessory)
}

extension HMAccessoryBrowserDelegate {
    public func accessoryBrowser(_ browser: HMAccessoryBrowser, didFindNewAccessory accessory: HMAccessory) {
        _ = (browser, accessory)
    }
    public func accessoryBrowser(_ browser: HMAccessoryBrowser, didRemoveNewAccessory accessory: HMAccessory) {
        _ = (browser, accessory)
    }
}

public protocol HMCameraStreamControlDelegate: NSObjectProtocol {
    func cameraStreamControlDidStartStream(_ cameraStreamControl: HMCameraStreamControl)
    func cameraStreamControl(_ cameraStreamControl: HMCameraStreamControl, didStopStreamWithError error: (any Error)?)
}

extension HMCameraStreamControlDelegate {
    public func cameraStreamControlDidStartStream(_ cameraStreamControl: HMCameraStreamControl) {
        _ = cameraStreamControl
    }
    public func cameraStreamControl(
        _ cameraStreamControl: HMCameraStreamControl,
        didStopStreamWithError error: (any Error)?
    ) {
        _ = (cameraStreamControl, error)
    }
}

public protocol HMCameraSnapshotControlDelegate: NSObjectProtocol {
    func cameraSnapshotControl(
        _ cameraSnapshotControl: HMCameraSnapshotControl,
        didTake snapshot: HMCameraSnapshot?,
        error: (any Error)?
    )
    func cameraSnapshotControlDidUpdateMostRecentSnapshot(_ cameraSnapshotControl: HMCameraSnapshotControl)
}

extension HMCameraSnapshotControlDelegate {
    public func cameraSnapshotControl(
        _ cameraSnapshotControl: HMCameraSnapshotControl,
        didTake snapshot: HMCameraSnapshot?,
        error: (any Error)?
    ) {
        _ = (cameraSnapshotControl, snapshot, error)
    }
    public func cameraSnapshotControlDidUpdateMostRecentSnapshot(_ cameraSnapshotControl: HMCameraSnapshotControl) {
        _ = cameraSnapshotControl
    }
}

public protocol HMNetworkConfigurationProfileDelegate: NSObjectProtocol {
    func profileDidUpdateNetworkAccessMode(_ profile: HMNetworkConfigurationProfile)
}

extension HMNetworkConfigurationProfileDelegate {
    public func profileDidUpdateNetworkAccessMode(_ profile: HMNetworkConfigurationProfile) { _ = profile }
}

public protocol HMHomeDelegate: NSObjectProtocol {
    func homeDidUpdateName(_ home: HMHome)
    func home(_ home: HMHome, didAdd accessory: HMAccessory)
    func home(_ home: HMHome, didRemove accessory: HMAccessory)
    func home(_ home: HMHome, didAdd user: HMUser)
    func home(_ home: HMHome, didRemove user: HMUser)
    func home(_ home: HMHome, didUpdate room: HMRoom, for accessory: HMAccessory)
    func home(_ home: HMHome, didAdd room: HMRoom)
    func home(_ home: HMHome, didRemove room: HMRoom)
    func home(_ home: HMHome, didUpdateNameFor room: HMRoom)
    func home(_ home: HMHome, didAdd zone: HMZone)
    func home(_ home: HMHome, didRemove zone: HMZone)
    func home(_ home: HMHome, didUpdateNameFor zone: HMZone)
    func home(_ home: HMHome, didAdd room: HMRoom, to zone: HMZone)
    func home(_ home: HMHome, didRemove room: HMRoom, from zone: HMZone)
    func home(_ home: HMHome, didAdd group: HMServiceGroup)
    func home(_ home: HMHome, didRemove group: HMServiceGroup)
    func home(_ home: HMHome, didUpdateNameFor group: HMServiceGroup)
    func home(_ home: HMHome, didAdd service: HMService, to group: HMServiceGroup)
    func home(_ home: HMHome, didRemove service: HMService, from group: HMServiceGroup)
    func home(_ home: HMHome, didAdd actionSet: HMActionSet)
    func home(_ home: HMHome, didRemove actionSet: HMActionSet)
    func home(_ home: HMHome, didUpdateNameFor actionSet: HMActionSet)
    func home(_ home: HMHome, didUpdateActionsFor actionSet: HMActionSet)
    func home(_ home: HMHome, didAdd trigger: HMTrigger)
    func home(_ home: HMHome, didRemove trigger: HMTrigger)
    func home(_ home: HMHome, didUpdateNameFor trigger: HMTrigger)
    func home(_ home: HMHome, didUpdate trigger: HMTrigger)
    func home(_ home: HMHome, didUnblockAccessory accessory: HMAccessory)
    func home(_ home: HMHome, didEncounterError error: any Error, for accessory: HMAccessory)
    func home(_ home: HMHome, didUpdate homeHubState: HMHomeHubState)
    func homeDidUpdateAccessControl(forCurrentUser home: HMHome)
    func homeDidUpdateSupportedFeatures(_ home: HMHome)
}

extension HMHomeDelegate {
    public func homeDidUpdateName(_ home: HMHome) { _ = home }
    public func home(_ home: HMHome, didAdd accessory: HMAccessory) { _ = (home, accessory) }
    public func home(_ home: HMHome, didRemove accessory: HMAccessory) { _ = (home, accessory) }
    public func home(_ home: HMHome, didAdd user: HMUser) { _ = (home, user) }
    public func home(_ home: HMHome, didRemove user: HMUser) { _ = (home, user) }
    public func home(_ home: HMHome, didUpdate room: HMRoom, for accessory: HMAccessory) { _ = (home, room, accessory) }
    public func home(_ home: HMHome, didAdd room: HMRoom) { _ = (home, room) }
    public func home(_ home: HMHome, didRemove room: HMRoom) { _ = (home, room) }
    public func home(_ home: HMHome, didUpdateNameFor room: HMRoom) { _ = (home, room) }
    public func home(_ home: HMHome, didAdd zone: HMZone) { _ = (home, zone) }
    public func home(_ home: HMHome, didRemove zone: HMZone) { _ = (home, zone) }
    public func home(_ home: HMHome, didUpdateNameFor zone: HMZone) { _ = (home, zone) }
    public func home(_ home: HMHome, didAdd room: HMRoom, to zone: HMZone) { _ = (home, room, zone) }
    public func home(_ home: HMHome, didRemove room: HMRoom, from zone: HMZone) { _ = (home, room, zone) }
    public func home(_ home: HMHome, didAdd group: HMServiceGroup) { _ = (home, group) }
    public func home(_ home: HMHome, didRemove group: HMServiceGroup) { _ = (home, group) }
    public func home(_ home: HMHome, didUpdateNameFor group: HMServiceGroup) { _ = (home, group) }
    public func home(_ home: HMHome, didAdd service: HMService, to group: HMServiceGroup) { _ = (home, service, group) }
    public func home(_ home: HMHome, didRemove service: HMService, from group: HMServiceGroup) {
        _ = (home, service, group)
    }
    public func home(_ home: HMHome, didAdd actionSet: HMActionSet) { _ = (home, actionSet) }
    public func home(_ home: HMHome, didRemove actionSet: HMActionSet) { _ = (home, actionSet) }
    public func home(_ home: HMHome, didUpdateNameFor actionSet: HMActionSet) { _ = (home, actionSet) }
    public func home(_ home: HMHome, didUpdateActionsFor actionSet: HMActionSet) { _ = (home, actionSet) }
    public func home(_ home: HMHome, didAdd trigger: HMTrigger) { _ = (home, trigger) }
    public func home(_ home: HMHome, didRemove trigger: HMTrigger) { _ = (home, trigger) }
    public func home(_ home: HMHome, didUpdateNameFor trigger: HMTrigger) { _ = (home, trigger) }
    public func home(_ home: HMHome, didUpdate trigger: HMTrigger) { _ = (home, trigger) }
    public func home(_ home: HMHome, didUnblockAccessory accessory: HMAccessory) { _ = (home, accessory) }
    public func home(_ home: HMHome, didEncounterError error: any Error, for accessory: HMAccessory) {
        _ = (home, error, accessory)
    }
    public func home(_ home: HMHome, didUpdate homeHubState: HMHomeHubState) { _ = (home, homeHubState) }
    public func homeDidUpdateAccessControl(forCurrentUser home: HMHome) { _ = home }
    public func homeDidUpdateSupportedFeatures(_ home: HMHome) { _ = home }
}
