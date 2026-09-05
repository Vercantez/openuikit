import Foundation
import Dispatch
import GameController

func testControllerRegistryAndNotifications() {
    final class Box: @unchecked Sendable {
        var discoveryCount = 0
        var connected: Notification?
        var disconnected: Notification?
        var becameCurrent: Notification?
    }
    let box = Box()
    GCSimulatedInput.reset()
    precondition(!GCSimulatedInput.linuxEvdevAvailable)
    precondition(GCController.controllers().isEmpty)
    precondition(GCController.current == nil)

    let discoveryGate = DispatchSemaphore(value: 0)
    GCController.startWirelessControllerDiscovery {
        box.discoveryCount += 1
        discoveryGate.signal()
    }
    precondition(box.discoveryCount == 0)
    precondition(discoveryGate.wait(timeout: .now() + 2) == .success)
    precondition(box.discoveryCount == 1)
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

    let nc = NotificationCenter.default
    let tok1 = nc.addObserver(forName: .GCControllerDidConnect, object: nil, queue: nil) { box.connected = $0 }
    let tok2 = nc.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: nil) { box.disconnected = $0 }
    let tok3 = nc.addObserver(forName: .GCControllerDidBecomeCurrent, object: nil, queue: nil) { box.becameCurrent = $0 }

    let simulated = GCSimulatedInput.makeExtendedGamepad()
    GCSimulatedInput.attach(simulated)
    precondition(GCController.controllers().contains(where: { $0 === simulated }))
    precondition(GCController.current === simulated)
    precondition(box.connected?.object as? GCController === simulated)
    precondition(box.becameCurrent?.object as? GCController === simulated)
    precondition(!simulated.isSnapshot)
    let captured = simulated.capture()
    precondition(captured.isSnapshot)

    GCSimulatedInput.detach(simulated)
    precondition(box.disconnected?.object as? GCController === simulated || box.disconnected != nil)
    nc.removeObserver(tok1)
    nc.removeObserver(tok2)
    nc.removeObserver(tok3)
    GCSimulatedInput.reset()
    precondition(GCController.controllers().isEmpty)
    _ = GCController.self
}
