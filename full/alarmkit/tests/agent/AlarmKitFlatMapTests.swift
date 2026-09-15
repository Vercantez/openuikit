import Foundation
import AlarmKit

// Constrained generic helpers that bind the two less-specific AsyncSequence
// flatMap witnesses. A concrete Never-failure base always resolves to the
// Never/Never overload, so these helpers keep `Failure == Never` unprovable:
// only the named witness satisfies the generic environment, and successful
// compilation proves the binding.
func alarmKitFlatMapMatchedFailures<S: AsyncSequence, Seg: AsyncSequence>(
    _ sequence: S,
    _ transform: @Sendable @escaping (S.Element) async -> Seg
) -> AsyncFlatMapSequence<S, Seg> where S.Failure == Seg.Failure {
    sequence.flatMap(transform)
}

func alarmKitFlatMapNeverSegment<S: AsyncSequence, Seg: AsyncSequence>(
    _ sequence: S,
    _ transform: @Sendable @escaping (S.Element) async -> Seg
) -> AsyncFlatMapSequence<S, Seg> where Seg.Failure == Never {
    sequence.flatMap(transform)
}

func testAlarmUpdatesFlatMapSpecializedOverloads() {
    let updates = AlarmManager.AlarmUpdates()
    alarmKitRunBlocking {
        let matched = alarmKitFlatMapMatchedFailures(updates) { _ in
            AlarmManager.AlarmUpdates()
        }
        let matchedValues = await alarmKitCollect(matched)
        alarmKitExpect(matchedValues.isEmpty, "empty Failure==Failure flatMap")
        let neverSegment = alarmKitFlatMapNeverSegment(updates) { _ in
            AlarmManager.AlarmUpdates()
        }
        let neverValues = await alarmKitCollect(neverSegment)
        alarmKitExpect(neverValues.isEmpty, "empty Segment.Failure==Never flatMap")
    }
}

func testAuthorizationUpdatesFlatMapSpecializedOverloads() {
    let updates = AlarmManager.AlarmAuthorizationStateUpdates()
    alarmKitRunBlocking {
        let matched = alarmKitFlatMapMatchedFailures(updates) { _ in
            AlarmManager.AlarmAuthorizationStateUpdates()
        }
        let matchedValues = await alarmKitCollect(matched)
        alarmKitExpect(matchedValues.isEmpty, "empty auth Failure==Failure flatMap")
        let neverSegment = alarmKitFlatMapNeverSegment(updates) { _ in
            AlarmManager.AlarmAuthorizationStateUpdates()
        }
        let neverValues = await alarmKitCollect(neverSegment)
        alarmKitExpect(neverValues.isEmpty, "empty auth Segment.Failure==Never flatMap")
    }
}
