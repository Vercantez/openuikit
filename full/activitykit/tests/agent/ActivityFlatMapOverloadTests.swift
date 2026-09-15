@_spi(OpenUIKitHost) import ActivityKit
import Foundation

// Each test below pins one of the two leftover non-throwing `flatMap`
// overloads by calling it from a generic context where only that overload
// is applicable:
//
// - `*FlatMapSameFailure` uses `where O.Failure == S.Failure` with an
//   unconstrained `S.Failure`, so only the
//   `Other.Failure == Self.Failure` overload applies (the doubly-`Never`
//   overload needs `S.Failure == Never` and the single-`Never` overload
//   needs `O.Failure == Never`, neither of which is known).
// - `*FlatMapNeverFailure` uses `where O.Failure == Never` with an
//   unconstrained `S.Failure`, so only the `Other.Failure == Never`
//   overload applies.
//
// A direct call on a concrete sequence can never select these overloads:
// `Self.Failure` is the defaulted `Never`, so the strictly more
// constrained doubly-`Never` overload always wins there. Constructing the
// mapped sequence is synchronous, so no `await` is needed.

func testActivityUpdatesFlatMapSameFailure() {
    func applySameFailure<S: AsyncSequence, O: AsyncSequence>(
        _ sequence: S,
        _ transform: @escaping (S.Element) async -> O
    ) -> AsyncFlatMapSequence<S, O> where O.Failure == S.Failure {
        sequence.flatMap(transform)
    }
    let sequence = Activity<ProbeAttributes>.activityUpdates
    let mapped = applySameFailure(sequence) { _ in
        AsyncStream<Int> { continuation in continuation.finish() }
    }
    activityKitRequire(
        String(describing: type(of: mapped)).contains("AsyncFlatMapSequence"),
        "same-failure flatMap"
    )
}

func testActivityUpdatesFlatMapNeverFailure() {
    func applyNeverFailure<S: AsyncSequence, O: AsyncSequence>(
        _ sequence: S,
        _ transform: @escaping (S.Element) async -> O
    ) -> AsyncFlatMapSequence<S, O> where O.Failure == Never {
        sequence.flatMap(transform)
    }
    let sequence = Activity<ProbeAttributes>.activityUpdates
    let mapped = applyNeverFailure(sequence) { _ in
        AsyncStream<Int> { continuation in continuation.finish() }
    }
    activityKitRequire(
        String(describing: type(of: mapped)).contains("AsyncFlatMapSequence"),
        "never-failure flatMap"
    )
}

func testActivityStateUpdatesFlatMapSameFailure() {
    func applySameFailure<S: AsyncSequence, O: AsyncSequence>(
        _ sequence: S,
        _ transform: @escaping (S.Element) async -> O
    ) -> AsyncFlatMapSequence<S, O> where O.Failure == S.Failure {
        sequence.flatMap(transform)
    }
    activityKitReset()
    let activity = try! activityKitRequest("fm-state-same")
    let mapped = applySameFailure(activity.activityStateUpdates) { _ in
        AsyncStream<Int> { continuation in continuation.finish() }
    }
    activityKitRequire(
        String(describing: type(of: mapped)).contains("AsyncFlatMapSequence"),
        "same-failure flatMap"
    )
}

func testActivityStateUpdatesFlatMapNeverFailure() {
    func applyNeverFailure<S: AsyncSequence, O: AsyncSequence>(
        _ sequence: S,
        _ transform: @escaping (S.Element) async -> O
    ) -> AsyncFlatMapSequence<S, O> where O.Failure == Never {
        sequence.flatMap(transform)
    }
    activityKitReset()
    let activity = try! activityKitRequest("fm-state-never")
    let mapped = applyNeverFailure(activity.activityStateUpdates) { _ in
        AsyncStream<Int> { continuation in continuation.finish() }
    }
    activityKitRequire(
        String(describing: type(of: mapped)).contains("AsyncFlatMapSequence"),
        "never-failure flatMap"
    )
}

func testContentUpdatesFlatMapSameFailure() {
    func applySameFailure<S: AsyncSequence, O: AsyncSequence>(
        _ sequence: S,
        _ transform: @escaping (S.Element) async -> O
    ) -> AsyncFlatMapSequence<S, O> where O.Failure == S.Failure {
        sequence.flatMap(transform)
    }
    activityKitReset()
    let activity = try! activityKitRequest("fm-content-same")
    let mapped = applySameFailure(activity.contentUpdates) { _ in
        AsyncStream<Int> { continuation in continuation.finish() }
    }
    activityKitRequire(
        String(describing: type(of: mapped)).contains("AsyncFlatMapSequence"),
        "same-failure flatMap"
    )
}

func testContentUpdatesFlatMapNeverFailure() {
    func applyNeverFailure<S: AsyncSequence, O: AsyncSequence>(
        _ sequence: S,
        _ transform: @escaping (S.Element) async -> O
    ) -> AsyncFlatMapSequence<S, O> where O.Failure == Never {
        sequence.flatMap(transform)
    }
    activityKitReset()
    let activity = try! activityKitRequest("fm-content-never")
    let mapped = applyNeverFailure(activity.contentUpdates) { _ in
        AsyncStream<Int> { continuation in continuation.finish() }
    }
    activityKitRequire(
        String(describing: type(of: mapped)).contains("AsyncFlatMapSequence"),
        "never-failure flatMap"
    )
}

func testContentStateUpdatesFlatMapSameFailure() {
    func applySameFailure<S: AsyncSequence, O: AsyncSequence>(
        _ sequence: S,
        _ transform: @escaping (S.Element) async -> O
    ) -> AsyncFlatMapSequence<S, O> where O.Failure == S.Failure {
        sequence.flatMap(transform)
    }
    activityKitReset()
    let activity = try! activityKitRequest("fm-cstate-same")
    let mapped = applySameFailure(activity.contentStateUpdates) { _ in
        AsyncStream<Int> { continuation in continuation.finish() }
    }
    activityKitRequire(
        String(describing: type(of: mapped)).contains("AsyncFlatMapSequence"),
        "same-failure flatMap"
    )
}

func testContentStateUpdatesFlatMapNeverFailure() {
    func applyNeverFailure<S: AsyncSequence, O: AsyncSequence>(
        _ sequence: S,
        _ transform: @escaping (S.Element) async -> O
    ) -> AsyncFlatMapSequence<S, O> where O.Failure == Never {
        sequence.flatMap(transform)
    }
    activityKitReset()
    let activity = try! activityKitRequest("fm-cstate-never")
    let mapped = applyNeverFailure(activity.contentStateUpdates) { _ in
        AsyncStream<Int> { continuation in continuation.finish() }
    }
    activityKitRequire(
        String(describing: type(of: mapped)).contains("AsyncFlatMapSequence"),
        "never-failure flatMap"
    )
}

func testPushTokenUpdatesFlatMapSameFailure() {
    func applySameFailure<S: AsyncSequence, O: AsyncSequence>(
        _ sequence: S,
        _ transform: @escaping (S.Element) async -> O
    ) -> AsyncFlatMapSequence<S, O> where O.Failure == S.Failure {
        sequence.flatMap(transform)
    }
    activityKitReset()
    let activity = try! activityKitRequest("fm-token-same")
    let mapped = applySameFailure(activity.pushTokenUpdates) { _ in
        AsyncStream<Int> { continuation in continuation.finish() }
    }
    activityKitRequire(
        String(describing: type(of: mapped)).contains("AsyncFlatMapSequence"),
        "same-failure flatMap"
    )
}

func testPushTokenUpdatesFlatMapNeverFailure() {
    func applyNeverFailure<S: AsyncSequence, O: AsyncSequence>(
        _ sequence: S,
        _ transform: @escaping (S.Element) async -> O
    ) -> AsyncFlatMapSequence<S, O> where O.Failure == Never {
        sequence.flatMap(transform)
    }
    activityKitReset()
    let activity = try! activityKitRequest("fm-token-never")
    let mapped = applyNeverFailure(activity.pushTokenUpdates) { _ in
        AsyncStream<Int> { continuation in continuation.finish() }
    }
    activityKitRequire(
        String(describing: type(of: mapped)).contains("AsyncFlatMapSequence"),
        "never-failure flatMap"
    )
}

func testActivityEnablementUpdatesFlatMapSameFailure() {
    func applySameFailure<S: AsyncSequence, O: AsyncSequence>(
        _ sequence: S,
        _ transform: @escaping (S.Element) async -> O
    ) -> AsyncFlatMapSequence<S, O> where O.Failure == S.Failure {
        sequence.flatMap(transform)
    }
    let sequence = ActivityAuthorizationInfo().activityEnablementUpdates
    let mapped = applySameFailure(sequence) { _ in
        AsyncStream<Int> { continuation in continuation.finish() }
    }
    activityKitRequire(
        String(describing: type(of: mapped)).contains("AsyncFlatMapSequence"),
        "same-failure flatMap"
    )
}

func testActivityEnablementUpdatesFlatMapNeverFailure() {
    func applyNeverFailure<S: AsyncSequence, O: AsyncSequence>(
        _ sequence: S,
        _ transform: @escaping (S.Element) async -> O
    ) -> AsyncFlatMapSequence<S, O> where O.Failure == Never {
        sequence.flatMap(transform)
    }
    let sequence = ActivityAuthorizationInfo().activityEnablementUpdates
    let mapped = applyNeverFailure(sequence) { _ in
        AsyncStream<Int> { continuation in continuation.finish() }
    }
    activityKitRequire(
        String(describing: type(of: mapped)).contains("AsyncFlatMapSequence"),
        "never-failure flatMap"
    )
}

func testFrequentPushEnablementUpdatesFlatMapSameFailure() {
    func applySameFailure<S: AsyncSequence, O: AsyncSequence>(
        _ sequence: S,
        _ transform: @escaping (S.Element) async -> O
    ) -> AsyncFlatMapSequence<S, O> where O.Failure == S.Failure {
        sequence.flatMap(transform)
    }
    let sequence = ActivityAuthorizationInfo().frequentPushEnablementUpdates
    let mapped = applySameFailure(sequence) { _ in
        AsyncStream<Int> { continuation in continuation.finish() }
    }
    activityKitRequire(
        String(describing: type(of: mapped)).contains("AsyncFlatMapSequence"),
        "same-failure flatMap"
    )
}

func testFrequentPushEnablementUpdatesFlatMapNeverFailure() {
    func applyNeverFailure<S: AsyncSequence, O: AsyncSequence>(
        _ sequence: S,
        _ transform: @escaping (S.Element) async -> O
    ) -> AsyncFlatMapSequence<S, O> where O.Failure == Never {
        sequence.flatMap(transform)
    }
    let sequence = ActivityAuthorizationInfo().frequentPushEnablementUpdates
    let mapped = applyNeverFailure(sequence) { _ in
        AsyncStream<Int> { continuation in continuation.finish() }
    }
    activityKitRequire(
        String(describing: type(of: mapped)).contains("AsyncFlatMapSequence"),
        "never-failure flatMap"
    )
}
