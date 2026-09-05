import Foundation
import Dispatch
import GameController

func testEnumAndOptionSetMembers() {
    _ = GCControllerPlayerIndex.self
    _ = GCDeviceBattery.State.self
    _ = GCDevicePhysicalInputElementChange.self
    _ = GCDualSenseAdaptiveTrigger.Mode.self
    _ = GCDualSenseAdaptiveTrigger.Status.self
    _ = GCExtendedGamepadSnapshotDataVersion.self
    _ = GCMicroGamepadSnapshotDataVersion.self
    _ = GCControllerElement.SystemGestureState.self
    _ = GCControllerTouchpad.TouchState.self
    _ = GCPhysicalInputSourceDirection.self
    _ = GCUIEventTypes.self
    precondition(GCControllerPlayerIndex.indexUnset.rawValue == -1)
    precondition(GCControllerPlayerIndex.index1.rawValue == 0)
    precondition(GCControllerPlayerIndex.index2.rawValue == 1)
    precondition(GCControllerPlayerIndex.index3.rawValue == 2)
    precondition(GCControllerPlayerIndex.index4.rawValue == 3)
    precondition(GCDeviceBattery.State.unknown.rawValue == 0)
    precondition(GCDeviceBattery.State.discharging.rawValue == 1)
    precondition(GCDeviceBattery.State.charging.rawValue == 2)
    precondition(GCDeviceBattery.State.full.rawValue == 3)
    precondition(GCDevicePhysicalInputElementChange.unknownChange.rawValue == -1)
    precondition(GCDevicePhysicalInputElementChange.noChange.rawValue == 0)
    precondition(GCDevicePhysicalInputElementChange.changed.rawValue == 1)
    precondition(GCDualSenseAdaptiveTrigger.Mode.off.rawValue == 0)
    precondition(GCDualSenseAdaptiveTrigger.Mode.feedback.rawValue == 1)
    precondition(GCDualSenseAdaptiveTrigger.Mode.weapon.rawValue == 2)
    precondition(GCDualSenseAdaptiveTrigger.Mode.vibration.rawValue == 3)
    precondition(GCDualSenseAdaptiveTrigger.Mode.slopeFeedback.rawValue == 4)
    precondition(GCDualSenseAdaptiveTrigger.Status.unknown.rawValue == 0)
    precondition(GCDualSenseAdaptiveTrigger.Status.feedbackNoLoad.rawValue == 1)
    precondition(GCDualSenseAdaptiveTrigger.Status.feedbackLoadApplied.rawValue == 2)
    precondition(GCDualSenseAdaptiveTrigger.Status.weaponReady.rawValue == 3)
    precondition(GCDualSenseAdaptiveTrigger.Status.weaponFiring.rawValue == 4)
    precondition(GCDualSenseAdaptiveTrigger.Status.weaponFired.rawValue == 5)
    precondition(GCDualSenseAdaptiveTrigger.Status.vibrationNotVibrating.rawValue == 6)
    precondition(GCDualSenseAdaptiveTrigger.Status.vibrationIsVibrating.rawValue == 7)
    precondition(GCDualSenseAdaptiveTrigger.Status.slopeFeedbackReady.rawValue == 8)
    precondition(GCDualSenseAdaptiveTrigger.Status.slopeFeedbackApplyingLoad.rawValue == 9)
    precondition(GCDualSenseAdaptiveTrigger.Status.slopeFeedbackFinished.rawValue == 10)
    precondition(GCExtendedGamepadSnapshotDataVersion.version1.rawValue == 1)
    precondition(GCExtendedGamepadSnapshotDataVersion.version2.rawValue == 2)
    precondition(GCMicroGamepadSnapshotDataVersion.version1.rawValue == 1)
    precondition(GCControllerElement.SystemGestureState.enabled.rawValue == 0)
    precondition(GCControllerElement.SystemGestureState.alwaysReceive.rawValue == 1)
    precondition(GCControllerElement.SystemGestureState.disabled.rawValue == 2)
    precondition(GCControllerTouchpad.TouchState.up.rawValue == 0)
    precondition(GCControllerTouchpad.TouchState.down.rawValue == 1)
    precondition(GCControllerTouchpad.TouchState.moving.rawValue == 2)
    precondition(GCPhysicalInputSourceDirection.up.rawValue == 1 << 0)
    precondition(GCPhysicalInputSourceDirection.down.rawValue == 1 << 1)
    precondition(GCPhysicalInputSourceDirection.left.rawValue == 1 << 2)
    precondition(GCPhysicalInputSourceDirection.right.rawValue == 1 << 3)
    precondition(GCUIEventTypes.gamepad.rawValue == 1 << 0)
    precondition(GCControllerPlayerIndex.index1 != .index2)
    precondition(GCDeviceBattery.State.charging != .full)
    precondition(GCDevicePhysicalInputElementChange.changed != .noChange)
    precondition(GCDualSenseAdaptiveTrigger.Mode.off != .feedback)
    precondition(GCDualSenseAdaptiveTrigger.Status.unknown != .weaponReady)
    precondition(GCExtendedGamepadSnapshotDataVersion.version1 != .version2)
    precondition(GCMicroGamepadSnapshotDataVersion(rawValue: 99) == nil)
    precondition(GCControllerElement.SystemGestureState.enabled != .disabled)
    precondition(GCControllerTouchpad.TouchState.up != .down)
    precondition(GCPhysicalInputSourceDirection.up != .down)
    precondition(GCUIEventTypes.gamepad != GCUIEventTypes())
    _ = GCPhysicalInputSourceDirection()
    _ = GCPhysicalInputSourceDirection(rawValue: 1)
    _ = GCUIEventTypes()
    _ = GCUIEventTypes(rawValue: 1)
    _ = GCControllerPlayerIndex(rawValue: 0)
    _ = GCDeviceBattery.State(rawValue: 0)
    _ = GCDevicePhysicalInputElementChange(rawValue: 0)
    _ = GCDualSenseAdaptiveTrigger.Mode(rawValue: 0)
    _ = GCDualSenseAdaptiveTrigger.Status(rawValue: 0)
    _ = GCExtendedGamepadSnapshotDataVersion(rawValue: 1)
    _ = GCMicroGamepadSnapshotDataVersion(rawValue: 1)
    _ = GCControllerElement.SystemGestureState(rawValue: 0)
    _ = GCControllerTouchpad.TouchState(rawValue: 0)
    var hasher = Hasher()
    GCControllerPlayerIndex.indexUnset.hash(into: &hasher)
    GCControllerPlayerIndex.index1.hash(into: &hasher)
    GCControllerPlayerIndex.index2.hash(into: &hasher)
    GCControllerPlayerIndex.index3.hash(into: &hasher)
    GCControllerPlayerIndex.index4.hash(into: &hasher)
    GCDeviceBattery.State.charging.hash(into: &hasher)
    GCDevicePhysicalInputElementChange.changed.hash(into: &hasher)
    GCDualSenseAdaptiveTrigger.Mode.off.hash(into: &hasher)
    GCDualSenseAdaptiveTrigger.Status.unknown.hash(into: &hasher)
    GCExtendedGamepadSnapshotDataVersion.version1.hash(into: &hasher)
    GCMicroGamepadSnapshotDataVersion.version1.hash(into: &hasher)
    GCControllerElement.SystemGestureState.enabled.hash(into: &hasher)
    GCControllerTouchpad.TouchState.up.hash(into: &hasher)
    _ = hasher.finalize()
    _ = Set([GCControllerPlayerIndex.index1, .index2, .index3, .index4, .indexUnset])
    _ = Set([GCDeviceBattery.State.unknown, .charging, .discharging, .full])
    _ = Set([GCDevicePhysicalInputElementChange.changed, .noChange, .unknownChange])
    _ = Set([GCDualSenseAdaptiveTrigger.Mode.off, .feedback, .weapon, .vibration, .slopeFeedback])
    _ = Set([
        GCDualSenseAdaptiveTrigger.Status.unknown,
        .feedbackNoLoad, .feedbackLoadApplied,
        .weaponReady, .weaponFiring, .weaponFired,
        .vibrationNotVibrating, .vibrationIsVibrating,
        .slopeFeedbackReady, .slopeFeedbackApplyingLoad, .slopeFeedbackFinished
    ])
}
