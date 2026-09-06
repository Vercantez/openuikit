import Foundation
import HomeKit

private func hmRequire(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("HomeKit test failed: \(message)\n", stderr)
        exit(1)
    }
}

func testHomeLocalGraphRoomsZonesAndGroups() {
    let home = HMHome.host_make(name: "Cottage")
    hmRequire(home.uniqueIdentifier.uuidString.isEmpty == false, "home uuid")
    hmRequire(home.matterControllerID == home.uniqueIdentifier.uuidString, "matter id")
    hmRequire(home.supportsAddingNetworkRouter == false, "no router")
    hmRequire(home.rooms.isEmpty, "no rooms")
    hmRequire(home.zones.isEmpty, "no zones")
    hmRequire(home.serviceGroups.isEmpty, "no groups")
    hmRequire(home.accessories.isEmpty, "no accessories")
    hmRequire(home.triggers.isEmpty, "no triggers")
    hmRequire(home.currentUser.name == "Current User", "current user")
    hmRequire(home.users.count == 1, "users")
    let admin = home.homeAccessControl(for: home.currentUser)
    hmRequire(admin.isAdministrator, "admin")
    let other = HMUser.host_make(name: "Guest")
    hmRequire(!home.homeAccessControl(for: other).isAdministrator, "guest not admin")

    var addError: (any Error)?
    var kitchen: HMRoom?
    home.addRoom(named: "Kitchen") { room, error in
        kitchen = room
        addError = error
    }
    hmRequire(addError == nil, "add kitchen")
    hmRequire(kitchen?.name == "Kitchen", "kitchen name")
    hmRequire(kitchen?.uniqueIdentifier.uuidString.isEmpty == false, "kitchen uuid")
    hmRequire(home.rooms.count == 1, "one room")
    hmRequire(home.rooms.first === kitchen, "identity")

    var dup: (any Error)?
    home.addRoom(named: "kitchen") { _, error in dup = error }
    hmRequire(hmNSErrorCode(dup) == HMError.Code.objectWithSimilarNameExistsInHome.rawValue, "dup room")

    var emptyErr: (any Error)?
    home.addRoom(named: "") { _, error in emptyErr = error }
    hmRequire(hmNSErrorCode(emptyErr) == HMError.Code.stringShorterThanMinimum.rawValue, "empty room")

    var zone: HMZone?
    home.addZone(named: "Downstairs") { created, error in
        zone = created
        addError = error
    }
    hmRequire(addError == nil && zone?.name == "Downstairs", "zone")
    hmRequire(home.zones.count == 1, "one zone")
    hmRequire(zone?.uniqueIdentifier.uuidString.isEmpty == false, "zone uuid")

    var group: HMServiceGroup?
    home.addServiceGroup(named: "Lights") { created, error in
        group = created
        addError = error
    }
    hmRequire(addError == nil && group?.name == "Lights", "group")
    hmRequire(home.serviceGroups.count == 1, "one group")
    hmRequire(group?.services.isEmpty == true, "empty services")

    kitchen!.updateName("Kitchenette") { addError = $0 }
    hmRequire(addError == nil && kitchen?.name == "Kitchenette", "rename room")

    zone!.addRoom(kitchen!) { addError = $0 }
    hmRequire(addError == nil, "add room to zone")
    hmRequire(zone?.rooms.count == 1, "zone rooms")

    let entire = home.roomForEntireHome()
    zone!.addRoom(entire) { addError = $0 }
    hmRequire(hmNSErrorCode(addError) == HMError.Code.roomForHomeCannotBeInZone.rawValue, "entire home")

    entire.updateName("Nope") { addError = $0 }
    hmRequire(hmNSErrorCode(addError) == HMError.Code.roomForHomeCannotBeUpdated.rawValue, "entire rename")

    home.removeRoom(entire) { addError = $0 }
    hmRequire(hmNSErrorCode(addError) == HMError.Code.roomForHomeCannotBeUpdated.rawValue, "remove entire")

    zone!.removeRoom(kitchen!) { addError = $0 }
    hmRequire(addError == nil && zone?.rooms.isEmpty == true, "zone empty")

    home.removeZone(zone!) { addError = $0 }
    hmRequire(addError == nil && home.zones.isEmpty, "zone removed")

    home.removeServiceGroup(group!) { addError = $0 }
    hmRequire(addError == nil && home.serviceGroups.isEmpty, "group removed")

    home.removeRoom(kitchen!) { addError = $0 }
    hmRequire(addError == nil && home.rooms.isEmpty, "room removed")
}

func testHomeLocalGraphActionSetsAndExecute() {
    let home = HMHome.host_make(name: "Cabin")
    var error: (any Error)?
    var set: HMActionSet?
    home.addActionSet(named: "Movie") { created, err in
        set = created
        error = err
    }
    hmRequire(error == nil, "add set")
    hmRequire(set?.name == "Movie", "name")
    hmRequire(set?.actionSetType == HMActionSetTypeUserDefined, "type")
    hmRequire(set?.isExecuting == false, "idle")
    hmRequire(set?.lastExecutionDate == nil, "never")
    hmRequire(set?.uniqueIdentifier.uuidString.isEmpty == false, "uuid")
    hmRequire(home.actionSets.count == 1, "one set")

    home.executeActionSet(set!) { error = $0 }
    hmRequire(hmNSErrorCode(error) == HMError.Code.noActionsInActionSet.rawValue, "empty actions")

    let characteristic = HMCharacteristic.host_make(
        type: HMCharacteristicTypePowerState,
        properties: [HMCharacteristicPropertyWritable],
        metadata: nil,
        value: NSNumber(value: false)
    )
    let action = HMCharacteristicWriteAction<NSNumber>(
        characteristic: characteristic,
        targetValue: NSNumber(value: true)
    )
    set!.addAction(action) { error = $0 }
    hmRequire(error == nil, "add action")
    hmRequire(set!.actions.count == 1, "one action")

    home.executeActionSet(set!) { error = $0 }
    hmRequire(hmNSErrorCode(error) == HMError.Code.noHomeHub.rawValue, "no hub")

    home.host_setHomeHubState(.connected)
    hmRequire(home.homeHubState == .connected, "connected")
    home.executeActionSet(set!) { error = $0 }
    hmRequire(error == nil, "local execute")
    hmRequire((characteristic.value as? NSNumber)?.boolValue == true, "wrote")
    hmRequire(set?.isExecuting == false, "finished")
    hmRequire(set?.lastExecutionDate != nil, "stamped")

    set!.removeAction(action) { error = $0 }
    hmRequire(error == nil && set!.actions.isEmpty, "removed action")

    home.host_installBuiltinActionSets()
    let wake = home.builtinActionSet(ofType: HMActionSetTypeWakeUp)
    hmRequire(wake != nil, "wake")
    home.removeActionSet(wake!) { error = $0 }
    hmRequire(hmNSErrorCode(error) == HMError.Code.cannotRemoveBuiltinActionSet.rawValue, "builtin")

    home.removeActionSet(set!) { error = $0 }
    hmRequire(error == nil, "remove user set")
}

func testHomeFailClosedPairingAndUsers() {
    let home = HMHome.host_make(name: "Lockbox")
    let accessory = HMAccessory.host_make(name: "Lock")
    var error: (any Error)?
    home.addAccessory(accessory) { error = $0 }
    hmRequire(hmNSErrorCode(error) == HMError.Code.accessoryNotReachable.rawValue, "pair")
    home.addAndSetUpAccessories { error = $0 }
    hmRequire(hmNSErrorCode(error) == HMError.Code.missingEntitlement.rawValue, "setup")
    let url = URL(string: "homekit://setup")!
    let payload = HMAccessorySetupPayload(url: url)!
    var accessories: [HMAccessory]?
    home.addAndSetUpAccessories(payload: payload) { result, err in
        accessories = result
        error = err
    }
    hmRequire(accessories == nil, "no accessories")
    hmRequire(hmNSErrorCode(error) == HMError.Code.missingEntitlement.rawValue, "payload setup")

    var user: HMUser?
    home.addUser { created, err in
        user = created
        error = err
    }
    hmRequire(user == nil, "no user")
    hmRequire(hmNSErrorCode(error) == HMError.Code.homeAccessNotAuthorized.rawValue, "add user")
    home.removeUser(HMUser.host_make(name: "X")) { error = $0 }
    hmRequire(hmNSErrorCode(error) == HMError.Code.homeAccessNotAuthorized.rawValue, "remove user")
    home.manageUsers { error = $0 }
    hmRequire(hmNSErrorCode(error) == HMError.Code.homeAccessNotAuthorized.rawValue, "manage")

    var nameError: (any Error)?
    home.updateName("Lockbox 2") { nameError = $0 }
    hmRequire(nameError == nil && home.name == "Lockbox 2", "local rename")
    home.updateName("") { nameError = $0 }
    hmRequire(hmNSErrorCode(nameError) == HMError.Code.stringShorterThanMinimum.rawValue, "empty home")
}

func testHomeAttachAssignUnblockAndTriggers() {
    let home = HMHome.host_make(name: "Studio")
    var error: (any Error)?
    var room: HMRoom?
    home.addRoom(named: "Office") { created, err in
        room = created
        error = err
    }
    hmRequire(error == nil, "room")
    let accessory = HMAccessory.host_make(
        name: "Lamp",
        reachable: true,
        bridged: true,
        blocked: true,
        manufacturer: "Acme",
        model: "L1"
    )
    home.host_attachAccessory(accessory)
    hmRequire(home.accessories.count == 1, "attached")
    hmRequire(accessory.home === home, "home backref")
    hmRequire(accessory.room === home.roomForEntireHome(), "entire room")
    hmRequire(accessory.isBlocked, "blocked")
    hmRequire(accessory.isBridged, "bridged")
    hmRequire(accessory.manufacturer == "Acme", "mfr")
    hmRequire(accessory.model == "L1", "model")

    home.assignAccessory(accessory, to: room!) { error = $0 }
    hmRequire(error == nil, "assign")
    hmRequire(accessory.room === room, "room")
    hmRequire(room!.accessories.contains(where: { $0 === accessory }), "room list")

    home.unblockAccessory(accessory) { error = $0 }
    hmRequire(error == nil && accessory.isBlocked == false, "unblocked")

    let lone = HMAccessory.host_make(name: "Solo", bridged: false, blocked: true)
    home.host_attachAccessory(lone)
    home.unblockAccessory(lone) { error = $0 }
    hmRequire(hmNSErrorCode(error) == HMError.Code.cannotUnblockNonBridgeAccessory.rawValue, "non-bridge")

    let trigger = HMTimerTrigger(
        name: "Dawn",
        fireDate: Date(timeIntervalSince1970: 1_700_000_000),
        recurrence: nil
    )
    home.addTrigger(trigger) { error = $0 }
    hmRequire(error == nil && home.triggers.count == 1, "trigger")
    hmRequire(trigger.home === home, "trigger home")
    home.removeTrigger(trigger) { error = $0 }
    hmRequire(error == nil && home.triggers.isEmpty, "removed trigger")

    home.removeAccessory(accessory) { error = $0 }
    hmRequire(error == nil, "removed accessory")
    hmRequire(accessory.home == nil, "cleared home")
}
