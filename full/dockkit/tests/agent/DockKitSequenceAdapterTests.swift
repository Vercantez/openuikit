import Foundation
import DockKit

func testAsyncSequenceMap() {
    let events = DockAccessory.AccessoryEvents()
    _ = events.map { $0 }
    _ = events.map { (event) async throws -> DockAccessory.AccessoryEvent in event }

    let motion = DockAccessory.MotionStates()
    _ = motion.map { $0 }
    _ = motion.map { (state) async throws -> DockAccessory.MotionState in state }

    let changes = DockAccessory.StateChanges()
    _ = changes.map { $0 }
    _ = changes.map { (change) async throws -> DockAccessory.StateChange in change }

    let batteries = DockAccessory.BatteryStates()
    _ = batteries.map { $0 }
    _ = batteries.map { (state) async throws -> DockAccessory.BatteryState in state }

    let tracking = DockAccessory.TrackingStates()
    _ = tracking.map { $0 }
    _ = tracking.map { (state) async throws -> DockAccessory.TrackingState in state }
}

func testAsyncSequenceCompactMap() {
    let events = DockAccessory.AccessoryEvents()
    _ = events.compactMap { $0 }
    _ = events.compactMap { (event) async throws -> DockAccessory.AccessoryEvent? in event }

    let motion = DockAccessory.MotionStates()
    _ = motion.compactMap { $0 }
    _ = motion.compactMap { (state) async throws -> DockAccessory.MotionState? in state }

    let changes = DockAccessory.StateChanges()
    _ = changes.compactMap { $0 }
    _ = changes.compactMap { (change) async throws -> DockAccessory.StateChange? in change }

    let batteries = DockAccessory.BatteryStates()
    _ = batteries.compactMap { $0 }
    _ = batteries.compactMap { (state) async throws -> DockAccessory.BatteryState? in state }

    let tracking = DockAccessory.TrackingStates()
    _ = tracking.compactMap { $0 }
    _ = tracking.compactMap { (state) async throws -> DockAccessory.TrackingState? in state }
}

func testAsyncSequenceFilter() {
    _ = DockAccessory.AccessoryEvents().filter { _ in true }
    _ = DockAccessory.MotionStates().filter { _ in true }
    _ = DockAccessory.StateChanges().filter { _ in true }
    _ = DockAccessory.BatteryStates().filter { _ in true }
    _ = DockAccessory.TrackingStates().filter { _ in true }
}

func testAsyncSequenceDropWhile() {
    _ = DockAccessory.AccessoryEvents().drop(while: { _ in false })
    _ = DockAccessory.MotionStates().drop(while: { _ in false })
    _ = DockAccessory.StateChanges().drop(while: { _ in false })
    _ = DockAccessory.BatteryStates().drop(while: { _ in false })
    _ = DockAccessory.TrackingStates().drop(while: { _ in false })
}

func testAsyncSequenceDropFirst() {
    _ = DockAccessory.AccessoryEvents().dropFirst()
    _ = DockAccessory.MotionStates().dropFirst(0)
    _ = DockAccessory.StateChanges().dropFirst(1)
    _ = DockAccessory.BatteryStates().dropFirst(2)
    _ = DockAccessory.TrackingStates().dropFirst()
}

func testAsyncSequencePrefixCount() {
    _ = DockAccessory.AccessoryEvents().prefix(0)
    _ = DockAccessory.MotionStates().prefix(1)
    _ = DockAccessory.StateChanges().prefix(2)
    _ = DockAccessory.BatteryStates().prefix(3)
    _ = DockAccessory.TrackingStates().prefix(4)
}

func testAsyncSequencePrefixWhile() {
    _ = DockAccessory.AccessoryEvents().prefix(while: { _ in false })
    _ = DockAccessory.MotionStates().prefix(while: { _ in false })
    _ = DockAccessory.StateChanges().prefix(while: { _ in false })
    _ = DockAccessory.BatteryStates().prefix(while: { _ in false })
    _ = DockAccessory.TrackingStates().prefix(while: { _ in false })
}

func testAsyncSequenceFlatMap() {
    let events = DockAccessory.AccessoryEvents()
    _ = events.flatMap { _ in events }
    _ = events.flatMap { _ async throws in events }

    let motion = DockAccessory.MotionStates()
    _ = motion.flatMap { _ in motion }
    _ = motion.flatMap { _ async throws in motion }

    let changes = DockAccessory.StateChanges()
    _ = changes.flatMap { _ in changes }
    _ = changes.flatMap { _ async throws in changes }

    let batteries = DockAccessory.BatteryStates()
    _ = batteries.flatMap { _ in batteries }
    _ = batteries.flatMap { _ async throws in batteries }

    let tracking = DockAccessory.TrackingStates()
    _ = tracking.flatMap { _ in tracking }
    _ = tracking.flatMap { _ async throws in tracking }
}
