import Foundation
import DockKit

func testAccessoryEventsMakeAsyncIterator() {
    let events = DockAccessory.AccessoryEvents()
    let iterator = events.makeAsyncIterator()
    _ = iterator
    let _: DockAccessory.AccessoryEvents.Element.Type = DockAccessory.AccessoryEvent.self
    let _: DockAccessory.AccessoryEvents.AsyncIterator.Type = DockAccessory.AccessoryEvents.Iterator.self
    let _: DockAccessory.AccessoryEvents.Iterator.Element.Type = DockAccessory.AccessoryEvent.self
}

func testMotionStatesMakeAsyncIterator() {
    let states = DockAccessory.MotionStates()
    let iterator = states.makeAsyncIterator()
    _ = iterator
    let _: DockAccessory.MotionStates.Element.Type = DockAccessory.MotionState.self
    let _: DockAccessory.MotionStates.AsyncIterator.Type = DockAccessory.MotionStates.Iterator.self
    let _: DockAccessory.MotionStates.Iterator.Element.Type = DockAccessory.MotionState.self
}

func testStateChangesMakeAsyncIterator() {
    let changes = DockAccessory.StateChanges()
    let iterator = changes.makeAsyncIterator()
    _ = iterator
    let _: DockAccessory.StateChanges.Element.Type = DockAccessory.StateChange.self
    let _: DockAccessory.StateChanges.AsyncIterator.Type = DockAccessory.StateChanges.Iterator.self
    let _: DockAccessory.StateChanges.Iterator.Element.Type = DockAccessory.StateChange.self
}

func testBatteryStatesMakeAsyncIterator() {
    let states = DockAccessory.BatteryStates()
    let iterator = states.makeAsyncIterator()
    _ = iterator
    let _: DockAccessory.BatteryStates.Element.Type = DockAccessory.BatteryState.self
    let _: DockAccessory.BatteryStates.AsyncIterator.Type = DockAccessory.BatteryStates.Iterator.self
    let _: DockAccessory.BatteryStates.Iterator.Element.Type = DockAccessory.BatteryState.self
}

func testTrackingStatesMakeAsyncIterator() {
    let states = DockAccessory.TrackingStates()
    let iterator = states.makeAsyncIterator()
    _ = iterator
    let _: DockAccessory.TrackingStates.Element.Type = DockAccessory.TrackingState.self
    let _: DockAccessory.TrackingStates.AsyncIterator.Type = DockAccessory.TrackingStates.Iterator.self
    let _: DockAccessory.TrackingStates.Iterator.Element.Type = DockAccessory.TrackingState.self
}

func testEmptyAsyncSequenceTypesExist() {
    precondition(DockAccessory.AccessoryEvents.Iterator.self == DockAccessory.AccessoryEvents.AsyncIterator.self)
    precondition(DockAccessory.MotionStates.Iterator.self == DockAccessory.MotionStates.AsyncIterator.self)
    precondition(DockAccessory.StateChanges.Iterator.self == DockAccessory.StateChanges.AsyncIterator.self)
    precondition(DockAccessory.BatteryStates.Iterator.self == DockAccessory.BatteryStates.AsyncIterator.self)
    precondition(DockAccessory.TrackingStates.Iterator.self == DockAccessory.TrackingStates.AsyncIterator.self)
}
