import Foundation
import AlarmKit

@Sendable
private func throwingNeverSequence(_ value: [Alarm]) async throws -> AlarmManager.AlarmUpdates {
    _ = value
    return AlarmManager.AlarmUpdates()
}

@Sendable
private func throwingNeverAuthSequence(
    _ value: AlarmManager.AuthorizationState
) async throws -> AlarmManager.AlarmAuthorizationStateUpdates {
    _ = value
    return AlarmManager.AlarmAuthorizationStateUpdates()
}

func testAlarmUpdatesAllSatisfyFirstContains() {
    let updates = AlarmManager.AlarmUpdates()
    alarmKitRunBlocking {
        let all = await updates.allSatisfy { !$0.isEmpty }
        alarmKitExpect(all, "empty allSatisfy is vacuously true")
        let first = await updates.first { !$0.isEmpty }
        alarmKitExpect(first == nil, "empty first(where:)")
        let contains = await updates.contains { !$0.isEmpty }
        alarmKitExpect(!contains, "empty contains(where:)")
    }
}

func testAlarmUpdatesMapAndCompactMap() {
    let updates = AlarmManager.AlarmUpdates()
    alarmKitRunBlocking {
        let mapped = await alarmKitCollect(updates.map { $0.count })
        alarmKitExpect(mapped.isEmpty, "empty map")
        let throwingMapped = try await alarmKitCollect(
            updates.map { (alarms) async throws in alarms.count }
        )
        alarmKitExpect(throwingMapped.isEmpty, "empty throwing map")
        let compact = await alarmKitCollect(updates.compactMap { $0.first })
        alarmKitExpect(compact.isEmpty, "empty compactMap")
        let throwingCompact = try await alarmKitCollect(
            updates.compactMap { (alarms) async throws in alarms.first }
        )
        alarmKitExpect(throwingCompact.isEmpty, "empty throwing compactMap")
    }
}

func testAlarmUpdatesFilterDropPrefix() {
    let updates = AlarmManager.AlarmUpdates()
    alarmKitRunBlocking {
        let filtered = await alarmKitCollect(updates.filter { !$0.isEmpty })
        alarmKitExpect(filtered.isEmpty, "empty filter")
        let dropped = await alarmKitCollect(updates.drop { $0.isEmpty })
        alarmKitExpect(dropped.isEmpty, "empty drop(while:)")
        let dropFirst = await alarmKitCollect(updates.dropFirst())
        alarmKitExpect(dropFirst.isEmpty, "empty dropFirst")
        let prefixCount = await alarmKitCollect(updates.prefix(3))
        alarmKitExpect(prefixCount.isEmpty, "empty prefix(count)")
        let prefixWhile = await alarmKitCollect(updates.prefix { $0.isEmpty })
        alarmKitExpect(prefixWhile.isEmpty, "empty prefix(while:)")
    }
}

func testAlarmUpdatesReduceMinMax() {
    let updates = AlarmManager.AlarmUpdates()
    alarmKitRunBlocking {
        let reduced = await updates.reduce(0) { partial, alarms in
            partial + alarms.count
        }
        alarmKitExpectEqual(reduced, 0, "empty reduce")
        let reducedInto = await updates.reduce(into: 0) { partial, alarms in
            partial += alarms.count
        }
        alarmKitExpectEqual(reducedInto, 0, "empty reduce(into:)")
        let maximum = await updates.max { lhs, rhs in lhs.count < rhs.count }
        alarmKitExpect(maximum == nil, "empty max(by:)")
        let minimum = await updates.min { lhs, rhs in lhs.count < rhs.count }
        alarmKitExpect(minimum == nil, "empty min(by:)")
    }
}

func testAlarmUpdatesFlatMapOverloads() {
    let updates = AlarmManager.AlarmUpdates()
    alarmKitRunBlocking {
        let flatNever = await alarmKitCollect(
            updates.flatMap { _ in AlarmManager.AlarmUpdates() }
        )
        alarmKitExpect(flatNever.isEmpty, "empty flatMap Never")
        let flatThrowing = try await alarmKitCollect(
            updates.flatMap { alarms async throws in
                _ = alarms
                return AlarmManager.AlarmUpdates()
            }
        )
        alarmKitExpect(flatThrowing.isEmpty, "empty throwing flatMap")
        let typedThrowing: AsyncThrowingFlatMapSequence<
            AlarmManager.AlarmUpdates, AlarmManager.AlarmUpdates
        > = updates.flatMap(throwingNeverSequence)
        let typedValues = try await alarmKitCollect(typedThrowing)
        alarmKitExpect(typedValues.isEmpty, "typed throwing flatMap")
    }
}

func testAuthorizationUpdatesAllSatisfyFirstContains() {
    let updates = AlarmManager.AlarmAuthorizationStateUpdates()
    alarmKitRunBlocking {
        let all = await updates.allSatisfy { $0 == .authorized }
        alarmKitExpect(all, "empty auth allSatisfy is vacuously true")
        let first = await updates.first { $0 == .authorized }
        alarmKitExpect(first == nil, "empty auth first(where:)")
        let containsWhere = await updates.contains { $0 == .denied }
        alarmKitExpect(!containsWhere, "empty auth contains(where:)")
        let containsValue = await updates.contains(.denied)
        alarmKitExpect(!containsValue, "empty auth contains(_:)")
    }
}

func testAuthorizationUpdatesMapAndCompactMap() {
    let updates = AlarmManager.AlarmAuthorizationStateUpdates()
    alarmKitRunBlocking {
        let mapped = await alarmKitCollect(updates.map { $0 == .authorized })
        alarmKitExpect(mapped.isEmpty, "empty auth map")
        let throwingMapped = try await alarmKitCollect(
            updates.map { (state) async throws in state }
        )
        alarmKitExpect(throwingMapped.isEmpty, "empty auth throwing map")
        let compact = await alarmKitCollect(
            updates.compactMap { $0 == .denied ? $0 : nil }
        )
        alarmKitExpect(compact.isEmpty, "empty auth compactMap")
        let throwingCompact = try await alarmKitCollect(
            updates.compactMap { (state) async throws in Optional(state) }
        )
        alarmKitExpect(throwingCompact.isEmpty, "empty auth throwing compactMap")
    }
}

func testAuthorizationUpdatesFilterDropPrefix() {
    let updates = AlarmManager.AlarmAuthorizationStateUpdates()
    alarmKitRunBlocking {
        let filtered = await alarmKitCollect(updates.filter { $0 == .authorized })
        alarmKitExpect(filtered.isEmpty, "empty auth filter")
        let dropped = await alarmKitCollect(updates.drop { $0 == .notDetermined })
        alarmKitExpect(dropped.isEmpty, "empty auth drop(while:)")
        let dropFirst = await alarmKitCollect(updates.dropFirst(2))
        alarmKitExpect(dropFirst.isEmpty, "empty auth dropFirst")
        let prefixCount = await alarmKitCollect(updates.prefix(1))
        alarmKitExpect(prefixCount.isEmpty, "empty auth prefix(count)")
        let prefixWhile = await alarmKitCollect(updates.prefix { $0 == .authorized })
        alarmKitExpect(prefixWhile.isEmpty, "empty auth prefix(while:)")
    }
}

func testAuthorizationUpdatesReduceMinMax() {
    let updates = AlarmManager.AlarmAuthorizationStateUpdates()
    alarmKitRunBlocking {
        let reduced = await updates.reduce(0) { partial, _ in partial + 1 }
        alarmKitExpectEqual(reduced, 0, "empty auth reduce")
        let reducedInto = await updates.reduce(into: [AlarmManager.AuthorizationState]()) {
            partial, state in
            partial.append(state)
        }
        alarmKitExpect(reducedInto.isEmpty, "empty auth reduce(into:)")
        let maximum = await updates.max { lhs, rhs in lhs.hashValue < rhs.hashValue }
        alarmKitExpect(maximum == nil, "empty auth max(by:)")
        let minimum = await updates.min { lhs, rhs in lhs.hashValue < rhs.hashValue }
        alarmKitExpect(minimum == nil, "empty auth min(by:)")
    }
}

func testAuthorizationUpdatesFlatMapOverloads() {
    let updates = AlarmManager.AlarmAuthorizationStateUpdates()
    alarmKitRunBlocking {
        let flatNever = await alarmKitCollect(
            updates.flatMap { _ in AlarmManager.AlarmAuthorizationStateUpdates() }
        )
        alarmKitExpect(flatNever.isEmpty, "empty auth flatMap Never")
        let flatThrowing = try await alarmKitCollect(
            updates.flatMap { state async throws in
                _ = state
                return AlarmManager.AlarmAuthorizationStateUpdates()
            }
        )
        alarmKitExpect(flatThrowing.isEmpty, "empty auth throwing flatMap")
        let typedThrowing: AsyncThrowingFlatMapSequence<
            AlarmManager.AlarmAuthorizationStateUpdates,
            AlarmManager.AlarmAuthorizationStateUpdates
        > = updates.flatMap(throwingNeverAuthSequence)
        let typedValues = try await alarmKitCollect(typedThrowing)
        alarmKitExpect(typedValues.isEmpty, "typed auth throwing flatMap")
    }
}
