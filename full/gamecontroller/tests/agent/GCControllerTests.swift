import Foundation
import Dispatch
import GameController

func testControllerRegistryAndNotifications() {
    GCSimulatedInput.reset()
    precondition(!GCSimulatedInput.linuxEvdevAvailable)
    precondition(GCController.controllers().isEmpty)
    precondition(GCController.current == nil)

    let discoveryGate = DispatchSemaphore(value: 0)
    var discoveryCount = 0
    GCController.startWirelessControllerDiscovery {
        discoveryCount += 1
        discoveryGate.signal()
    }
    precondition(discoveryCount == 0)
    precondition(discoveryGate.wait(timeout: .now() + 2) == .success)
    precondition(discoveryCount == 1)
    GCController.stopWirelessControllerDiscovery()

    let snapshot = GCController.withExtendedGamepad()
    precondition(snapshot.isSnapshot)
    precondition(!snapshot.isAttachedToDevice)
    precondition(snapshot.extendedGamepad != nil)
    precondition(snapshot.gamepad != nil)
    precondition(snapshot.motion != nil)
    precondition(snapshot.haptics == nil)
    precondition(snapshot.battery == nil)
    precondition(snapshot.light == nil)
    precondition(snapshot.productCategory == GCProductCategoryHID)
    precondition(snapshot.vendorName == nil)
    precondition(snapshot.playerIndex == .indexUnset)
    precondition(GCController.controllers().isEmpty)

    snapshot.playerIndex = .index1
    precondition(snapshot.playerIndex == .index1)
    snapshot.controllerPausedHandler = { _ in }
    _ = snapshot.physicalInputProfile
    _ = snapshot.input

    let handlerQueue = DispatchQueue(label: "gc.controller.handler")
    snapshot.handlerQueue = handlerQueue
    precondition(snapshot.handlerQueue === handlerQueue)

    GCController.shouldMonitorBackgroundEvents = true
    precondition(GCController.shouldMonitorBackgroundEvents)

    var connectedNote: Notification?
    var disconnectedNote: Notification?
    var becameCurrentNote: Notification?
    let nc = NotificationCenter.default
    let tok1 = nc.addObserver(forName: .GCControllerDidConnect, object: nil, queue: nil) { connectedNote = $0 }
    let tok2 = nc.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: nil) { disconnectedNote = $0 }
    let tok3 = nc.addObserver(forName: .GCControllerDidBecomeCurrent, object: nil, queue: nil) { becameCurrentNote = $0 }

    let simulated = GCSimulatedInput.makeExtendedGamepad()
    GCSimulatedInput.attach(simulated)
    precondition(GCController.controllers().contains(where: { $0 === simulated }))
    precondition(GCController.current === simulated)
    precondition(connectedNote?.object as? GCController === simulated)
    precondition(becameCurrentNote?.object as? GCController === simulated)
    precondition(!simulated.isSnapshot)
    let captured = simulated.capture()
    precondition(captured.isSnapshot)

    GCSimulatedInput.detach(simulated)
    precondition(disconnectedNote?.object as? GCController === simulated || disconnectedNote != nil)
    nc.removeObserver(tok1)
    nc.removeObserver(tok2)
    nc.removeObserver(tok3)
    GCSimulatedInput.reset()
    precondition(GCController.controllers().isEmpty)
    _ = GCController.self
}
