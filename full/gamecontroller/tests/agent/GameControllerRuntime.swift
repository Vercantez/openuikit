import Foundation
import Dispatch
import GameController

precondition(GCController.controllers().isEmpty)
precondition(GCController.current == nil)
precondition(GCKeyboard.coalesced == nil)
precondition(GCMouse.current == nil)
precondition(GCMouse.mice().isEmpty)

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
precondition(snapshot.motion?.hasAttitude == false)
precondition(snapshot.haptics == nil)
precondition(snapshot.productCategory == GCProductCategoryHID)

let handlerQueue = DispatchQueue(label: "gc.handler.test")
let handlerKey = DispatchSpecificKey<UInt8>()
handlerQueue.setSpecific(key: handlerKey, value: 7)
snapshot.handlerQueue = handlerQueue
precondition(snapshot.handlerQueue === handlerQueue)

let pad = snapshot.extendedGamepad!
precondition(pad.buttonA.value == 0)
precondition(!pad.buttonA.isPressed)

let handlerGate = DispatchSemaphore(value: 0)
var handlerQueueHonored = false
var handlerFireCount = 0
pad.buttonA.valueChangedHandler = { _, _, _ in
    handlerFireCount += 1
    handlerQueueHonored = DispatchQueue.getSpecific(key: handlerKey) == 7
    handlerGate.signal()
}
pad.buttonA.setValue(1)
precondition(pad.buttonA.isPressed)
precondition(pad.buttonA.value == 1)
precondition(handlerFireCount == 0)
precondition(handlerGate.wait(timeout: .now() + 2) == .success)
precondition(handlerFireCount == 1)
precondition(handlerQueueHonored)

pad.leftThumbstick.setValueForXAxis(0.5, yAxis: -0.25)
precondition(abs(pad.leftThumbstick.xAxis.value - 0.5) < 0.0001)
precondition(abs(pad.leftThumbstick.yAxis.value + 0.25) < 0.0001)
precondition(pad.leftThumbstick.right.isPressed)
precondition(!pad.leftThumbstick.left.isPressed)

let captured = snapshot.capture()
precondition(captured.isSnapshot)
precondition(captured.extendedGamepad?.buttonA.isPressed == true)

let snapshotBlob = pad.saveSnapshot().snapshotData
precondition(!snapshotBlob.isEmpty)
var decoded = GCExtendedGamepadSnapshotData()
precondition(GCExtendedGamepadSnapshotDataFromNSData(&decoded, snapshotBlob))
precondition(decoded.buttonA == 1)

var encoded = GCExtendedGamepadSnapshotData()
encoded.buttonX = 0.75
encoded.leftTrigger = 0.4
let roundTrip = NSDataFromGCExtendedGamepadSnapshotData(&encoded)
var restored = GCExtendedGamepadSnapshotData()
precondition(GCExtendedGamepadSnapshotDataFromNSData(&restored, roundTrip))
precondition(abs(restored.buttonX - 0.75) < 0.0001)
precondition(abs(restored.leftTrigger - 0.4) < 0.0001)

let micro = GCController.withMicroGamepad()
precondition(micro.microGamepad != nil)
micro.microGamepad?.buttonA.setValue(1)
precondition(micro.microGamepad?.buttonA.isPressed == true)

let point = GCPoint2Make(1.5, -2)
precondition(GCPoint2Equal(point, GCPoint2(x: 1.5, y: -2)))
precondition(!GCPoint2Equal(point, GCPoint2Zero))

precondition(GCKeyCode.keyA.rawValue == 0x04)
precondition(GCKeyCode.escape.rawValue == 0x29)

let names = GCButtonElementName.a
precondition(names.rawValue == GCInputButtonA)
let collection = GCPhysicalInputElementCollection<any GCPhysicalInputElement>()
precondition(collection.isEmpty)
precondition(collection[GCButtonElementName.a] == nil)

let virtual = GCVirtualController(configuration: GCVirtualController.Configuration())
precondition(virtual.controller == nil)
let virtualGate = DispatchSemaphore(value: 0)
var virtualError: (any Error)?
var virtualCount = 0
virtual.connect { error in
    virtualError = error
    virtualCount += 1
    virtualGate.signal()
}
precondition(virtualCount == 0)
precondition(virtualError == nil)
precondition(virtualGate.wait(timeout: .now() + 2) == .success)
precondition(virtualCount == 1)
precondition(virtualError != nil)

let dual = GCDualSenseAdaptiveTrigger()
dual.setModeFeedbackWithStartPosition(0.2, resistiveStrength: 0.8)
precondition(dual.mode == .feedback)
precondition(dual.status == .unknown)
dual.setModeOff()
precondition(dual.mode == .off)

let color = GCColor(red: 0.1, green: 0.2, blue: 0.3)
precondition(color.red == 0.1)

GCController.shouldMonitorBackgroundEvents = true
precondition(GCController.shouldMonitorBackgroundEvents)

let connect = GCController.DidConnectMessage(controller: snapshot)
precondition(connect.controller === snapshot)
precondition(GCController.DidConnectMessage.name == Notification.Name.GCControllerDidConnect)

print("GAMECONTROLLER_AGENT_RUNTIME_OK")
