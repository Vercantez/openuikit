@_spi(OpenUIKitHost) import AccessorySetupKit
import Foundation

func testASAccessorySessionActivateDeliversActivated() {
    let session = ASAccessorySession()
    precondition(session.accessories.isEmpty)
    var events: [ASAccessoryEvent] = []
    session.activate(on: DispatchQueue(label: "as.session.activate")) { event in
        events.append(event)
    }
    precondition(events.count == 1)
    precondition(events[0].eventType == .activated)
    precondition(events[0].accessory == nil)
    precondition(events[0].error == nil)
    precondition(session.accessories.isEmpty)
}

func testASAccessorySessionInvalidateDeliversInvalidated() {
    let session = ASAccessorySession()
    var types: [ASAccessoryEventType] = []
    session.activate(on: DispatchQueue(label: "as.session.invalidate")) { event in
        types.append(event.eventType)
    }
    session.invalidate()
    precondition(types == [.activated, .invalidated])
    session.invalidate()
    precondition(types == [.activated, .invalidated])
}

func testASAccessorySessionShowPickerFailClosed() {
    let session = ASAccessorySession()
    var idleError: (any Error)?
    session.showPicker { error in
        idleError = error
    }
    let idle = idleError as? ASError
    precondition(idle?.code == .invalidated)

    session.activate(on: DispatchQueue(label: "as.session.picker")) { _ in }
    var activeError: (any Error)?
    session.showPicker { error in
        activeError = error
    }
    let active = activeError as? ASError
    precondition(active?.code == .pickerRestricted)
}

func testASAccessorySessionShowPickerForItemsFailClosed() {
    let session = ASAccessorySession()
    session.activate(on: DispatchQueue(label: "as.session.picker.items")) { _ in }
    let item = ASPickerDisplayItem(
        name: "Lamp",
        productImage: NSObject(),
        descriptor: ASDiscoveryDescriptor()
    )
    var captured: (any Error)?
    session.showPicker(for: [item]) { error in
        captured = error
    }
    let typed = captured as? ASError
    precondition(typed?.code == .pickerRestricted)
}

func testASAccessorySessionFinishPickerDiscoveryFailClosed() {
    let session = ASAccessorySession()
    session.activate(on: DispatchQueue(label: "as.session.finish.discovery")) { _ in }
    var captured: (any Error)?
    session.finishPickerDiscovery { error in
        captured = error
    }
    let typed = captured as? ASError
    precondition(typed?.code == .pickerRestricted)
}

func testASAccessorySessionUpdatePickerFailClosed() {
    let session = ASAccessorySession()
    session.activate(on: DispatchQueue(label: "as.session.update.picker")) { _ in }
    let accessory = ASDiscoveredAccessory(hostDisplayName: "Found")
    let item = ASDiscoveredDisplayItem(
        name: "Found",
        productImage: NSObject(),
        accessory: accessory
    )
    var captured: (any Error)?
    session.updatePicker(showing: [item]) { error in
        captured = error
    }
    let typed = captured as? ASError
    precondition(typed?.code == .pickerRestricted)
}

func testASAccessorySessionAuthorizationFailClosed() {
    let session = ASAccessorySession()
    session.activate(on: DispatchQueue(label: "as.session.auth")) { _ in }
    let accessory = ASAccessory(hostDisplayName: "NeedAuth")
    let settings = ASAccessorySettings()
    var finishError: (any Error)?
    session.finishAuthorization(for: accessory, settings: settings) { error in
        finishError = error
    }
    precondition((finishError as? ASError)?.code == .invalidRequest)

    var failError: (any Error)?
    session.failAuthorization(for: accessory) { error in
        failError = error
    }
    precondition((failError as? ASError)?.code == .invalidRequest)

    var removeError: (any Error)?
    session.removeAccessory(accessory) { error in
        removeError = error
    }
    precondition((removeError as? ASError)?.code == .invalidRequest)

    var renameError: (any Error)?
    session.renameAccessory(accessory, options: .ssid) { error in
        renameError = error
    }
    precondition((renameError as? ASError)?.code == .invalidRequest)

    var updateError: (any Error)?
    session.updateAuthorization(for: accessory, descriptor: ASDiscoveryDescriptor()) { error in
        updateError = error
    }
    precondition((updateError as? ASError)?.code == .invalidRequest)
}

func testASAccessorySessionInvalidatedRefusesPicker() {
    let session = ASAccessorySession()
    session.activate(on: DispatchQueue(label: "as.session.dead")) { _ in }
    session.invalidate()
    var captured: (any Error)?
    session.showPicker { error in
        captured = error
    }
    precondition((captured as? ASError)?.code == .invalidated)
}

func testASAccessorySessionPickerDisplaySettings() {
    let session = ASAccessorySession()
    precondition(session.pickerDisplaySettings == nil)
    let settings = ASPickerDisplaySettings()
    settings.discoveryTimeout = .long
    session.pickerDisplaySettings = settings
    precondition(session.pickerDisplaySettings === settings)
    precondition(session.pickerDisplaySettings?.discoveryTimeout == .long)
}

func testASAccessorySessionActivateAfterInvalidate() {
    let session = ASAccessorySession()
    var types: [ASAccessoryEventType] = []
    session.activate(on: DispatchQueue(label: "as.session.reanimate")) { event in
        types.append(event.eventType)
    }
    session.invalidate()
    session.activate(on: DispatchQueue(label: "as.session.reanimate.2")) { event in
        types.append(event.eventType)
    }
    precondition(types.last == .invalidated)
    let last = types.last
    _ = last
    precondition((types.filter { $0 == .invalidated }.count) >= 2)
}
