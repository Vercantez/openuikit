@_spi(OpenUIKitHost) import AlarmKit
import Foundation

struct RuntimeMetadata: AlarmMetadata {}

final class ProbeFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var firstSeen = false
    private var secondSeen = false

    func markFirst() {
        lock.lock()
        firstSeen = true
        lock.unlock()
    }

    func markSecond() {
        lock.lock()
        secondSeen = true
        lock.unlock()
    }

    var sawFirst: Bool {
        lock.lock()
        defer { lock.unlock() }
        return firstSeen
    }

    var sawSecond: Bool {
        lock.lock()
        defer { lock.unlock() }
        return secondSeen
    }
}

func requireHostBoundary(_ error: Error) {
    guard error is AlarmKitHostBoundary else {
        fatalError("expected AlarmKitHostBoundary, got \(error)")
    }
}

func roundTrip<T: Codable>(_ value: T) throws -> T {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let data = try encoder.encode(value)
    return try decoder.decode(T.self, from: data)
}

func requireEqual<T: Equatable>(_ lhs: T, _ rhs: T) {
    precondition(lhs == rhs)
}

func requireKeyedEnumJSON<T: Encodable>(_ value: T) throws {
    let data = try JSONEncoder().encode(value)
    let object = try JSONSerialization.jsonObject(with: data)
    precondition(
        object is [String: Any],
        "graph-absent String raw Codable leaked: \(String(data: data, encoding: .utf8) ?? "<bin>")"
    )
}

func waitUntil(_ flag: ProbeFlag, spins: Int = 400) async {
    var count = 0
    while !flag.sawFirst && count < spins {
        try? await Task.sleep(nanoseconds: 1_000_000)
        count += 1
    }
    precondition(flag.sawFirst)
}

func run() async throws {
    _ = RuntimeMetadata()
    precondition(AlarmManager.shared === AlarmManager.shared)
    precondition(AlarmManager.shared.authorizationState == .notDetermined)
    precondition(AlarmManager.AuthorizationState.notDetermined != .denied)
    precondition(AlarmManager.AuthorizationState.denied != .authorized)
    try requireKeyedEnumJSON(AlarmManager.AuthorizationState.notDetermined)
    try requireKeyedEnumJSON(Alarm.State.scheduled)
    try requireKeyedEnumJSON(Alarm.State.paused)
    precondition(AlarmManager.AlarmError.maximumLimitReached == .maximumLimitReached)
    precondition(!(AlarmManager.AlarmError.maximumLimitReached != .maximumLimitReached))
    var errorHasher = Hasher()
    AlarmManager.AlarmError.maximumLimitReached.hash(into: &errorHasher)
    _ = errorHasher.finalize()
    _ = AlarmManager.AlarmError.maximumLimitReached.hashValue
    precondition(!AlarmManager.AlarmError.maximumLimitReached.localizedDescription.isEmpty)

    var authHasher = Hasher()
    AlarmManager.AuthorizationState.denied.hash(into: &authHasher)
    _ = AlarmManager.AuthorizationState.authorized.hashValue
    _ = AlarmManager.AuthorizationState.notDetermined.hashValue

    let beforeAuth = AlarmManager.shared.authorizationState
    do {
        _ = try await AlarmManager.shared.requestAuthorization()
        fatalError("requestAuthorization must not invent a decision")
    } catch {
        requireHostBoundary(error)
    }
    precondition(AlarmManager.shared.authorizationState == beforeAuth)
    precondition(AlarmManager.shared.authorizationState == .notDetermined)
    requireEqual(
        try roundTrip(AlarmManager.AuthorizationState.denied),
        .denied
    )
    requireEqual(
        try roundTrip(AlarmManager.AuthorizationState.authorized),
        .authorized
    )
    requireEqual(
        try roundTrip(AlarmManager.AuthorizationState.notDetermined),
        .notDetermined
    )

    let duration = Alarm.CountdownDuration(preAlert: 10, postAlert: 9 * 60)
    precondition(duration.preAlert == 10)
    precondition(duration.postAlert == 540)
    precondition(duration == Alarm.CountdownDuration(preAlert: 10, postAlert: 540))
    precondition(duration != Alarm.CountdownDuration(preAlert: 1, postAlert: nil))
    requireEqual(try roundTrip(duration), duration)

    let time = Alarm.Schedule.Relative.Time(hour: 6, minute: 30)
    precondition(time.hour == 6)
    precondition(time.minute == 30)
    precondition(time == Alarm.Schedule.Relative.Time(hour: 6, minute: 30))
    precondition(time != Alarm.Schedule.Relative.Time(hour: 7, minute: 0))
    requireEqual(try roundTrip(time), time)
    var timeHasher = Hasher()
    time.hash(into: &timeHasher)
    _ = time.hashValue

    let never = Alarm.Schedule.Relative.Recurrence.never
    let weekly = Alarm.Schedule.Relative.Recurrence.weekly([.monday, .wednesday, .friday])
    precondition(never != weekly)
    requireEqual(try roundTrip(never), never)
    requireEqual(try roundTrip(weekly), weekly)
    var recurrenceHasher = Hasher()
    weekly.hash(into: &recurrenceHasher)
    _ = weekly.hashValue
    _ = never.hashValue

    let relative = Alarm.Schedule.Relative(time: time, repeats: weekly)
    precondition(relative.time == time)
    precondition(relative.repeats == weekly)
    let relativeDefault = Alarm.Schedule.Relative(time: time)
    precondition(relativeDefault.repeats == .never)
    precondition(relative != relativeDefault)
    requireEqual(try roundTrip(relative), relative)
    _ = relative.hashValue

    let fixedDate = Date(timeIntervalSince1970: 1_800_000_000)
    let fixed = Alarm.Schedule.fixed(fixedDate)
    let relativeSchedule = Alarm.Schedule.relative(relative)
    precondition(fixed != relativeSchedule)
    requireEqual(try roundTrip(fixed), fixed)
    requireEqual(try roundTrip(relativeSchedule), relativeSchedule)
    _ = fixed.hashValue
    var scheduleHasher = Hasher()
    relativeSchedule.hash(into: &scheduleHasher)

    let states: [Alarm.State] = [.scheduled, .countdown, .paused, .alerting]
    for state in states {
        requireEqual(try roundTrip(state), state)
        try requireKeyedEnumJSON(state)
        precondition(state == state)
        _ = state.hashValue
        var stateHasher = Hasher()
        state.hash(into: &stateHasher)
    }
    precondition(Alarm.State.scheduled != .alerting)
    precondition(Alarm.State.countdown != .paused)

    let fire = Date(timeIntervalSince1970: 1_800_000_060)
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let presentationState = AlarmPresentationState(
        alarmID: UUID(uuidString: "00000000-0000-0000-0000-0000000000aa")!,
        mode: .countdown(
            .init(
                totalCountdownDuration: 60,
                previouslyElapsedDuration: 12,
                startDate: start,
                fireDate: fire
            )
        )
    )
    precondition(presentationState.mode != .alert(.init(time: time)))
    let pausedMode = AlarmPresentationState.Mode.paused(
        .init(totalCountdownDuration: 60, previouslyElapsedDuration: 12)
    )
    precondition(pausedMode != presentationState.mode)
    _ = presentationState.hashValue
    _ = AlarmPresentationState.Mode.Alert(time: time).hashValue
    _ = AlarmPresentationState.Mode.Paused(
        totalCountdownDuration: 1,
        previouslyElapsedDuration: 0
    ).hashValue
    _ = AlarmPresentationState.Mode.Countdown(
        totalCountdownDuration: 1,
        previouslyElapsedDuration: 0,
        startDate: start,
        fireDate: fire
    ).hashValue
    requireEqual(try roundTrip(presentationState), presentationState)
    let alertState = AlarmPresentationState(
        alarmID: presentationState.alarmID,
        mode: .alert(.init(time: time))
    )
    requireEqual(try roundTrip(alertState), alertState)
    let pausedState = AlarmPresentationState(
        alarmID: presentationState.alarmID,
        mode: pausedMode
    )
    requireEqual(try roundTrip(pausedState), pausedState)

    let alarmID: Alarm.ID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    let alarm = Alarm(
        id: alarmID,
        countdownDuration: duration,
        state: .scheduled,
        schedule: relativeSchedule
    )
    precondition(alarm.id == alarmID)
    precondition(alarm.state == .scheduled)
    precondition(alarm.schedule == relativeSchedule)
    precondition(alarm.countdownDuration == duration)
    let decodedAlarm = try roundTrip(alarm)
    precondition(decodedAlarm.id == alarm.id)
    precondition(decodedAlarm.state == .scheduled)
    precondition(decodedAlarm.countdownDuration == duration)

    do {
        _ = try AlarmManager.shared.alarms
        fatalError("alarms must fail closed")
    } catch {
        requireHostBoundary(error)
    }

    let mutating: [(String, () throws -> Void)] = [
        ("countdown", { try AlarmManager.shared.countdown(id: alarmID) }),
        ("cancel", { try AlarmManager.shared.cancel(id: alarmID) }),
        ("stop", { try AlarmManager.shared.stop(id: alarmID) }),
        ("pause", { try AlarmManager.shared.pause(id: alarmID) }),
        ("resume", { try AlarmManager.shared.resume(id: alarmID) }),
    ]
    for (name, operation) in mutating {
        do {
            try operation()
            fatalError("\(name) must fail closed")
        } catch {
            requireHostBoundary(error)
        }
    }

    await testOngoingSequences()
    await testMultipleIteratorsAndOrdering()
    await testCancellation()
    await testDeallocation()
    await testConcurrentManager()

    print("ALARMKIT_AGENT_RUNTIME_OK")
}

func testOngoingSequences() async {
    let alarmFlag = ProbeFlag()
    let alarmWaiter = Task {
        var iterator = AlarmManager.shared.alarmUpdates.makeAsyncIterator()
        _ = await iterator.next()
        alarmFlag.markFirst()
        _ = await iterator.next()
        alarmFlag.markSecond()
    }
    await waitUntil(alarmFlag)
    try? await Task.sleep(nanoseconds: 40_000_000)
    precondition(!alarmFlag.sawSecond)
    alarmWaiter.cancel()

    let authFlag = ProbeFlag()
    let authWaiter = Task {
        var iterator = AlarmManager.shared.authorizationUpdates.makeAsyncIterator()
        _ = await iterator.next()
        authFlag.markFirst()
        _ = await iterator.next()
        authFlag.markSecond()
    }
    await waitUntil(authFlag)
    try? await Task.sleep(nanoseconds: 40_000_000)
    precondition(!authFlag.sawSecond)
    authWaiter.cancel()
}

func testMultipleIteratorsAndOrdering() async {
    let manager = AlarmManager.hostIsolated()
    var first = manager.authorizationUpdates.makeAsyncIterator()
    var second = manager.authorizationUpdates.makeAsyncIterator()
    let firstSnap = await first.next()
    let secondSnap = await second.next()
    precondition(firstSnap == .notDetermined)
    precondition(secondSnap == .notDetermined)

    manager.hostPublishAuthorization(.denied)
    let firstDenied = await first.next()
    let secondDenied = await second.next()
    precondition(firstDenied == .denied)
    precondition(secondDenied == .denied)
    manager.hostPublishAuthorization(.authorized)
    let firstAuthorized = await first.next()
    let secondAuthorized = await second.next()
    precondition(firstAuthorized == .authorized)
    precondition(secondAuthorized == .authorized)
    precondition(manager.authorizationState == .authorized)

    var alarmA = manager.alarmUpdates.makeAsyncIterator()
    var alarmB = manager.alarmUpdates.makeAsyncIterator()
    let emptyA = await alarmA.next()
    let emptyB = await alarmB.next()
    precondition(emptyA?.isEmpty == true)
    precondition(emptyB?.isEmpty == true)
    let snapshot = [
        Alarm(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            countdownDuration: nil,
            state: .scheduled,
            schedule: nil
        )
    ]
    manager.hostPublishAlarms(snapshot)
    let nextA = await alarmA.next()
    let nextB = await alarmB.next()
    precondition(nextA?.count == 1)
    precondition(nextB?.count == 1)
    precondition(nextA?.first?.id == snapshot[0].id)
    precondition(nextB?.first?.state == .scheduled)
}

func testCancellation() async {
    let manager = AlarmManager.hostIsolated()
    let finished = ProbeFlag()
    let task = Task {
        var count = 0
        for await _ in manager.authorizationUpdates {
            count += 1
        }
        finished.markFirst()
        return count
    }
    try? await Task.sleep(nanoseconds: 20_000_000)
    task.cancel()
    await waitUntil(finished)
    switch await task.result {
    case .success(let count):
        precondition(count == 1)
    case .failure:
        fatalError("authorizationUpdates must finish as nil on cancel, not throw")
    }
}

func testDeallocation() async {
    var manager: AlarmManager? = AlarmManager.hostIsolated()
    weak let weakManager = manager
    let updates = manager!.alarmUpdates
    var iterator = updates.makeAsyncIterator()
    let first = await iterator.next()
    precondition(first?.isEmpty == true)
    manager = nil
    precondition(weakManager == nil)
    let finished = await iterator.next()
    precondition(finished == nil)
}

func testConcurrentManager() async {
    let manager = AlarmManager.hostIsolated()
    let alarmID = UUID()
    await withTaskGroup(of: Void.self) { group in
        for index in 0..<24 {
            group.addTask {
                if index % 2 == 0 {
                    do {
                        try manager.stop(id: alarmID)
                        fatalError("concurrent stop must fail closed")
                    } catch {
                        requireHostBoundary(error)
                    }
                } else {
                    do {
                        _ = try await manager.requestAuthorization()
                        fatalError("concurrent authorization must fail closed")
                    } catch {
                        requireHostBoundary(error)
                    }
                }
                _ = manager.authorizationState
            }
        }
    }
    precondition(manager.authorizationState == .notDetermined)
}

try await run()
