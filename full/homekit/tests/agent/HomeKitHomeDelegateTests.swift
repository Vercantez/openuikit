import Foundation
import HomeKit

private func hmRequire(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("HomeKit test failed: \(message)\n", stderr)
        exit(1)
    }
}

final class RecordingHomeDelegate: NSObject, HMHomeDelegate {
    var log: [String] = []

    func homeDidUpdateName(_ home: HMHome) { log.append("didUpdateName:\(home.name)") }
    func home(_ home: HMHome, didAdd accessory: HMAccessory) { log.append("addAccessory:\(accessory.name)") }
    func home(_ home: HMHome, didRemove accessory: HMAccessory) { log.append("removeAccessory:\(accessory.name)") }
    func home(_ home: HMHome, didAdd user: HMUser) { log.append("addUser:\(user.name)") }
    func home(_ home: HMHome, didRemove user: HMUser) { log.append("removeUser:\(user.name)") }
    func home(_ home: HMHome, didUpdate room: HMRoom, for accessory: HMAccessory) {
        log.append("updateRoom:\(room.name):\(accessory.name)")
    }
    func home(_ home: HMHome, didAdd room: HMRoom) { log.append("addRoom:\(room.name)") }
    func home(_ home: HMHome, didRemove room: HMRoom) { log.append("removeRoom:\(room.name)") }
    func home(_ home: HMHome, didUpdateNameFor room: HMRoom) { log.append("renameRoom:\(room.name)") }
    func home(_ home: HMHome, didAdd zone: HMZone) { log.append("addZone:\(zone.name)") }
    func home(_ home: HMHome, didRemove zone: HMZone) { log.append("removeZone:\(zone.name)") }
    func home(_ home: HMHome, didUpdateNameFor zone: HMZone) { log.append("renameZone:\(zone.name)") }
    func home(_ home: HMHome, didAdd room: HMRoom, to zone: HMZone) {
        log.append("addRoomToZone:\(room.name):\(zone.name)")
    }
    func home(_ home: HMHome, didRemove room: HMRoom, from zone: HMZone) {
        log.append("removeRoomFromZone:\(room.name):\(zone.name)")
    }
    func home(_ home: HMHome, didAdd group: HMServiceGroup) { log.append("addGroup:\(group.name)") }
    func home(_ home: HMHome, didRemove group: HMServiceGroup) { log.append("removeGroup:\(group.name)") }
    func home(_ home: HMHome, didUpdateNameFor group: HMServiceGroup) { log.append("renameGroup:\(group.name)") }
    func home(_ home: HMHome, didAdd service: HMService, to group: HMServiceGroup) {
        log.append("addServiceToGroup:\(service.name):\(group.name)")
    }
    func home(_ home: HMHome, didRemove service: HMService, from group: HMServiceGroup) {
        log.append("removeServiceFromGroup:\(service.name):\(group.name)")
    }
    func home(_ home: HMHome, didAdd actionSet: HMActionSet) { log.append("addActionSet:\(actionSet.name)") }
    func home(_ home: HMHome, didRemove actionSet: HMActionSet) { log.append("removeActionSet:\(actionSet.name)") }
    func home(_ home: HMHome, didUpdateNameFor actionSet: HMActionSet) { log.append("renameActionSet:\(actionSet.name)") }
    func home(_ home: HMHome, didUpdateActionsFor actionSet: HMActionSet) {
        log.append("updateActions:\(actionSet.name)")
    }
    func home(_ home: HMHome, didAdd trigger: HMTrigger) { log.append("addTrigger:\(trigger.name)") }
    func home(_ home: HMHome, didRemove trigger: HMTrigger) { log.append("removeTrigger:\(trigger.name)") }
    func home(_ home: HMHome, didUpdateNameFor trigger: HMTrigger) { log.append("renameTrigger:\(trigger.name)") }
    func home(_ home: HMHome, didUpdate trigger: HMTrigger) { log.append("updateTrigger:\(trigger.name)") }
    func home(_ home: HMHome, didUnblockAccessory accessory: HMAccessory) {
        log.append("unblock:\(accessory.name)")
    }
    func home(_ home: HMHome, didEncounterError error: any Error, for accessory: HMAccessory) {
        log.append("error:\((error as NSError).code):\(accessory.name)")
    }
    func home(_ home: HMHome, didUpdate homeHubState: HMHomeHubState) {
        log.append("hub:\(homeHubState.rawValue)")
    }
    func homeDidUpdateAccessControl(forCurrentUser home: HMHome) { log.append("accessControl:\(home.name)") }
    func homeDidUpdateSupportedFeatures(_ home: HMHome) { log.append("features:\(home.name)") }
}

func testHomeDelegateNotifications() {
    let home = HMHome.host_make(name: "Hall")
    let recorder = RecordingHomeDelegate()
    home.delegate = recorder
    hmRequire(home.delegate === recorder, "delegate set")

    var error: (any Error)?
    var room: HMRoom?
    home.addRoom(named: "Den") { created, err in
        room = created
        error = err
    }
    hmRequire(error == nil, "room")
    room!.updateName("Study") { error = $0 }

    var zone: HMZone?
    home.addZone(named: "West") { created, err in
        zone = created
        error = err
    }
    zone!.updateName("West Wing") { error = $0 }
    zone!.addRoom(room!) { error = $0 }
    zone!.removeRoom(room!) { error = $0 }

    var group: HMServiceGroup?
    home.addServiceGroup(named: "Fans") { created, err in
        group = created
        error = err
    }
    group!.updateName("Ceiling Fans") { error = $0 }
    let service = HMService.host_make(name: "Fan", serviceType: HMServiceTypeFan)
    group!.addService(service) { error = $0 }
    group!.removeService(service) { error = $0 }

    var set: HMActionSet?
    home.addActionSet(named: "Scene") { created, err in
        set = created
        error = err
    }
    set!.updateName("Evening") { error = $0 }
    let action = HMAction()
    set!.addAction(action) { error = $0 }

    let trigger = HMTimerTrigger(
        name: "Noon",
        fireDate: Date(timeIntervalSince1970: 2_000_000_000),
        recurrence: nil
    )
    home.addTrigger(trigger) { error = $0 }
    trigger.updateName("Midday") { error = $0 }
    let triggerSet = HMActionSet.host_make(name: "Owned", actionSetType: HMActionSetTypeTriggerOwned)
    trigger.addActionSet(triggerSet) { error = $0 }
    trigger.removeActionSet(triggerSet) { error = $0 }

    let accessory = HMAccessory.host_make(name: "Bridge", bridged: true, blocked: true)
    home.host_attachAccessory(accessory, room: room)
    home.unblockAccessory(accessory) { error = $0 }
    home.host_setHomeHubState(.disconnected)
    home.host_setSupportsAddingNetworkRouter(true)
    hmRequire(home.supportsAddingNetworkRouter, "router flag")
    home.host_notifyAccessControlUpdated()
    home.host_notifyEncounteredError(HMError(.accessoryIsBusy), for: accessory)
    let extra = HMUser.host_make(name: "Pat")
    home.host_addLocalUser(extra)
    home.host_removeLocalUser(extra)
    home.removeAccessory(accessory) { error = $0 }
    home.removeTrigger(trigger) { error = $0 }
    home.removeActionSet(set!) { error = $0 }
    home.removeServiceGroup(group!) { error = $0 }
    home.removeZone(zone!) { error = $0 }
    home.removeRoom(room!) { error = $0 }
    home.updateName("Foyer") { error = $0 }

    let expected: [String] = [
        "addRoom:Den",
        "renameRoom:Study",
        "addZone:West",
        "renameZone:West Wing",
        "addRoomToZone:Study:West Wing",
        "removeRoomFromZone:Study:West Wing",
        "addGroup:Fans",
        "renameGroup:Ceiling Fans",
        "addServiceToGroup:Fan:Ceiling Fans",
        "removeServiceFromGroup:Fan:Ceiling Fans",
        "addActionSet:Scene",
        "renameActionSet:Evening",
        "updateActions:Evening",
        "addTrigger:Noon",
        "renameTrigger:Midday",
        "updateTrigger:Midday",
        "updateTrigger:Midday",
        "addAccessory:Bridge",
        "unblock:Bridge",
        "hub:2",
        "features:Hall",
        "accessControl:Hall",
        "error:14:Bridge",
        "addUser:Pat",
        "removeUser:Pat",
        "removeAccessory:Bridge",
        "removeTrigger:Midday",
        "removeActionSet:Evening",
        "removeGroup:Ceiling Fans",
        "removeZone:West Wing",
        "removeRoom:Study",
        "didUpdateName:Foyer",
    ]
    hmRequire(recorder.log == expected, "log \(recorder.log)")
}
