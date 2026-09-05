import AlarmKit
import Foundation

// v1 sealed gate compiles only this file. It inlines tests/agent/*Tests.swift
// and invokes every depth-pass test* function before printing the runtime marker.


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


func testAlarmMetadataConformance() {
    let metadata = AlarmKitProbeMetadata(label: "probe")
    alarmKitExpectEqual(metadata.label, "probe", "metadata label")
    alarmKitExpect(metadata == AlarmKitProbeMetadata(label: "probe"), "metadata ==")
    alarmKitExpect(metadata != AlarmKitProbeMetadata(label: "other"), "metadata !=")
    _ = metadata.hashValue
}

func testAlarmAttributesInitAndContentState() {
    let presentation = alarmKitMakePresentation()
    let metadata = AlarmKitProbeMetadata(label: "probe")
    let attributes = AlarmAttributes(
        presentation: presentation,
        metadata: metadata,
        tintColor: Color(red: 0, green: 0, blue: 1, opacity: 1)
    )
    alarmKitExpectEqual(attributes.metadata?.label, "probe", "metadata")
    alarmKitExpectEqual(attributes.tintColor.blue, 1, "tint")
    alarmKitExpectEqual(attributes.presentation.alert.title.key, "Wake", "presentation")
    let _: AlarmAttributes<AlarmKitProbeMetadata>.ContentState.Type =
        AlarmPresentationState.self
}

func testAlarmAttributesCodable() {
    let attributes = AlarmAttributes(
        presentation: alarmKitMakePresentation(),
        metadata: AlarmKitProbeMetadata(label: "probe"),
        tintColor: Color(red: 0, green: 0, blue: 1, opacity: 1)
    )
    let decoded = alarmKitRoundTrip(attributes)
    alarmKitExpectEqual(decoded.metadata?.label, "probe", "attributes round-trip")
    alarmKitExpectEqual(decoded.tintColor.blue, 1, "tint round-trip")
}


func testAlarmButtonInitAndProperties() {
    let stop = alarmKitStopButton()
    alarmKitExpectEqual(stop.text.key, "Stop", "stop text")
    alarmKitExpectEqual(stop.systemImageName, "stop.circle", "stop image")
    alarmKitExpectEqual(stop.textColor.red, 1, "stop red")
    let listen = alarmKitListenButton()
    alarmKitExpectEqual(listen.systemImageName, "play.fill", "listen image")
    alarmKitExpectEqual(listen.text.key, "RADIO_ALARM_LISTEN", "listen text")
}

func testAlarmButtonCodable() {
    let decoded = alarmKitRoundTrip(alarmKitStopButton())
    alarmKitExpectEqual(decoded.systemImageName, "stop.circle", "button round-trip")
    alarmKitExpectEqual(decoded.text.key, "Stop", "button text round-trip")
}


func testAlarmConfigurationMemberwiseInit() {
    let attributes = AlarmAttributes(
        presentation: alarmKitMakePresentation(),
        metadata: AlarmKitProbeMetadata(label: "probe"),
        tintColor: Color(red: 0, green: 0, blue: 1, opacity: 1)
    )
    let configuration = AlarmManager.AlarmConfiguration(
        countdownDuration: Alarm.CountdownDuration(preAlert: 5, postAlert: nil),
        schedule: .fixed(Date(timeIntervalSince1970: 0)),
        attributes: attributes,
        stopIntent: AlarmKitEmptyIntent(),
        secondaryIntent: AlarmKitEmptyIntent(),
        sound: .default
    )
    alarmKitExpectEqual(configuration.sound.identifier, "default", "default sound")
    alarmKitExpect(configuration.stopIntent != nil, "stop intent stored")
    alarmKitExpect(configuration.secondaryIntent != nil, "secondary intent stored")
    alarmKitExpectEqual(configuration.countdownDuration?.preAlert, 5, "config duration")
}

func testAlarmConfigurationAlarmFactory() {
    let attributes = AlarmAttributes(
        presentation: alarmKitMakePresentation(),
        metadata: AlarmKitProbeMetadata(label: "x"),
        tintColor: .primary
    )
    let alarmConfig = AlarmManager.AlarmConfiguration<AlarmKitProbeMetadata>.alarm(
        schedule: .fixed(Date(timeIntervalSince1970: 1)),
        attributes: attributes,
        sound: AlertConfiguration.AlertSound(named: "radar")
    )
    alarmKitExpectEqual(alarmConfig.sound.identifier, "radar", "named sound")
    alarmKitExpect(alarmConfig.countdownDuration == nil, "alarm factory duration")
    alarmKitExpect(alarmConfig.schedule != nil, "alarm factory schedule")
}

func testAlarmConfigurationTimerFactory() {
    let attributes = AlarmAttributes(
        presentation: alarmKitMakePresentation(),
        metadata: AlarmKitProbeMetadata(label: "x"),
        tintColor: .primary
    )
    let timerConfig = AlarmManager.AlarmConfiguration<AlarmKitProbeMetadata>.timer(
        duration: 90,
        attributes: attributes
    )
    alarmKitExpectEqual(timerConfig.countdownDuration?.preAlert, 90, "timer duration")
    alarmKitExpect(timerConfig.schedule == nil, "timer has no schedule")
}


func testCountdownDurationInitAndProperties() {
    let duration = Alarm.CountdownDuration(preAlert: 15, postAlert: 30)
    alarmKitExpectEqual(duration.preAlert, 15, "preAlert")
    alarmKitExpectEqual(duration.postAlert, 30, "postAlert")
    let empty = Alarm.CountdownDuration(preAlert: nil, postAlert: nil)
    alarmKitExpect(empty.preAlert == nil, "nil preAlert")
    alarmKitExpect(empty.postAlert == nil, "nil postAlert")
}

func testCountdownDurationEquatable() {
    let duration = Alarm.CountdownDuration(preAlert: 15, postAlert: 30)
    let copy = Alarm.CountdownDuration(preAlert: 15, postAlert: 30)
    alarmKitExpect(duration == copy, "CountdownDuration ==")
    alarmKitExpect(!(duration != copy), "CountdownDuration !=")
    alarmKitExpect(
        duration != Alarm.CountdownDuration(preAlert: nil, postAlert: nil),
        "nil duration differs"
    )
}

func testCountdownDurationCodable() {
    let duration = Alarm.CountdownDuration(preAlert: 15, postAlert: 30)
    let decoded = alarmKitRoundTrip(duration)
    alarmKitExpectEqual(decoded.preAlert, 15, "decoded preAlert")
    alarmKitExpectEqual(decoded.postAlert, 30, "decoded postAlert")
    let empty = alarmKitRoundTrip(Alarm.CountdownDuration(preAlert: nil, postAlert: nil))
    alarmKitExpect(empty.preAlert == nil, "decoded nil preAlert")
}


struct AlarmKitProbeMetadata: AlarmMetadata {
    var label: String
}

struct AlarmKitEmptyIntent: LiveActivityIntent {}

final class AlarmKitErrorBox: @unchecked Sendable {
    var error: (any Error)?
}

func alarmKitExpect(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError("ALARMKIT_TEST_FAIL: \(message)")
    }
}

func alarmKitExpectEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    alarmKitExpect(actual == expected, "\(message): \(actual) != \(expected)")
}

func alarmKitRunBlocking(_ work: @escaping @Sendable () async throws -> Void) {
    let lock = DispatchSemaphore(value: 0)
    let box = AlarmKitErrorBox()
    Task {
        do {
            try await work()
        } catch {
            box.error = error
        }
        lock.signal()
    }
    lock.wait()
    if let error = box.error {
        fatalError("ALARMKIT_TEST_FAIL async: \(error)")
    }
}

func alarmKitRoundTrip<T: Codable>(_ value: T) -> T {
    do {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(value)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("ALARMKIT_TEST_FAIL round-trip: \(error)")
    }
}

func alarmKitRequireLinuxUnavailable(_ error: any Error) {
    let nsError = error as NSError
    alarmKitExpectEqual(nsError.domain, AlarmKitLinuxErrorDomain, "fail-closed domain")
    alarmKitExpectEqual(nsError.code, 1, "fail-closed code")
}

func alarmKitStopButton() -> AlarmButton {
    AlarmButton(
        text: LocalizedStringResource("Stop"),
        textColor: Color(red: 1, green: 0, blue: 0, opacity: 1),
        systemImageName: "stop.circle"
    )
}

func alarmKitListenButton() -> AlarmButton {
    AlarmButton(
        text: LocalizedStringResource("RADIO_ALARM_LISTEN"),
        textColor: Color(red: 1, green: 0.5, blue: 0, opacity: 1),
        systemImageName: "play.fill"
    )
}

func alarmKitMakePresentation() -> AlarmPresentation {
    let alert = AlarmPresentation.Alert(
        title: LocalizedStringResource("Wake"),
        stopButton: alarmKitStopButton(),
        secondaryButton: AlarmButton(
            text: "Snooze",
            textColor: .primary,
            systemImageName: "zzz"
        ),
        secondaryButtonBehavior: .countdown
    )
    let countdown = AlarmPresentation.Countdown(
        title: "Counting down",
        pauseButton: AlarmButton(
            text: "Pause",
            textColor: .primary,
            systemImageName: "pause.circle"
        )
    )
    let paused = AlarmPresentation.Paused(
        title: "Paused",
        resumeButton: AlarmButton(
            text: "Resume",
            textColor: .primary,
            systemImageName: "play.circle"
        )
    )
    return AlarmPresentation(alert: alert, countdown: countdown, paused: paused)
}

func alarmKitCollect<S: AsyncSequence>(_ sequence: S) async rethrows -> [S.Element] {
    var values: [S.Element] = []
    for try await element in sequence {
        values.append(element)
    }
    return values
}


func testAlarmManagerSharedIdentity() {
    alarmKitExpect(AlarmManager.shared === AlarmManager.shared, "shared identity")
}

func testAuthorizationStateCases() {
    let states: [AlarmManager.AuthorizationState] = [
        .notDetermined, .denied, .authorized,
    ]
    alarmKitExpectEqual(states.count, 3, "three authorization states")
    alarmKitExpect(AlarmManager.AuthorizationState.denied != .authorized, "auth !=")
    alarmKitExpect(AlarmManager.AuthorizationState.notDetermined == .notDetermined, "auth ==")
    _ = AlarmManager.AuthorizationState.denied.hashValue
    var hasher = Hasher()
    AlarmManager.AuthorizationState.authorized.hash(into: &hasher)
    _ = hasher.finalize()
}

func testAuthorizationStateCodable() {
    alarmKitExpectEqual(
        alarmKitRoundTrip(AlarmManager.AuthorizationState.notDetermined),
        .notDetermined,
        "auth round-trip"
    )
    alarmKitExpectEqual(
        alarmKitRoundTrip(AlarmManager.AuthorizationState.denied),
        .denied,
        "denied round-trip"
    )
}

func testAlarmManagerInitialAuthorization() {
    // A fresh process starts notDetermined; later tests may deny the singleton.
    let state = AlarmManager.shared.authorizationState
    alarmKitExpect(
        state == .notDetermined || state == .denied,
        "authorization is fail-closed"
    )
}

func testAlarmManagerAlarmsFailClosed() {
    do {
        _ = try AlarmManager.shared.alarms
        fatalError("ALARMKIT_TEST_FAIL: alarms must throw")
    } catch {
        alarmKitRequireLinuxUnavailable(error)
    }
}

func testAlarmManagerStopPauseCancelResumeCountdownFailClosed() {
    let probeID = UUID()
    let manager = AlarmManager.shared
    do { try manager.stop(id: probeID); fatalError("stop must throw") } catch {
        alarmKitRequireLinuxUnavailable(error)
    }
    do { try manager.pause(id: probeID); fatalError("pause must throw") } catch {
        alarmKitRequireLinuxUnavailable(error)
    }
    do { try manager.cancel(id: probeID); fatalError("cancel must throw") } catch {
        alarmKitRequireLinuxUnavailable(error)
    }
    do { try manager.resume(id: probeID); fatalError("resume must throw") } catch {
        alarmKitRequireLinuxUnavailable(error)
    }
    do { try manager.countdown(id: probeID); fatalError("countdown must throw") } catch {
        alarmKitRequireLinuxUnavailable(error)
    }
}

func testAlarmManagerScheduleFailClosed() {
    let attributes = AlarmAttributes(
        presentation: alarmKitMakePresentation(),
        metadata: AlarmKitProbeMetadata(label: "x"),
        tintColor: .primary
    )
    let configuration = AlarmManager.AlarmConfiguration(
        attributes: attributes,
        sound: .default
    )
    let probeID = UUID()
    alarmKitRunBlocking {
        do {
            _ = try await AlarmManager.shared.schedule(
                id: probeID,
                configuration: configuration
            )
            fatalError("ALARMKIT_TEST_FAIL: schedule must throw")
        } catch {
            alarmKitRequireLinuxUnavailable(error)
        }
    }
}

func testAlarmManagerRequestAuthorizationDenied() {
    alarmKitRunBlocking {
        let state = try await AlarmManager.shared.requestAuthorization()
        alarmKitExpectEqual(state, .denied, "requestAuthorization returns denied")
        alarmKitExpectEqual(
            AlarmManager.shared.authorizationState,
            .denied,
            "stored denied"
        )
    }
}

func testAlarmErrorMaximumLimitReached() {
    let limit = AlarmManager.AlarmError.maximumLimitReached
    alarmKitExpect(limit == .maximumLimitReached, "error ==")
    alarmKitExpect(!(limit != .maximumLimitReached), "error !=")
    _ = limit.hashValue
    var hasher = Hasher()
    limit.hash(into: &hasher)
    _ = hasher.finalize()
    alarmKitExpect(!limit.localizedDescription.isEmpty, "localizedDescription")
    let _: any Error = limit
}

func testCorpusVLCRadioAlarmConstruction() {
    // Mirrors videolan/vlc-ios VLCRadioAlarmService construction. Linux must
    // accept the value types and refuse schedule/alarms/cancel.
    let days: [Locale.Weekday] = [.monday, .friday]
    let schedule = Alarm.Schedule.relative(
        .init(
            time: .init(hour: 7, minute: 15),
            repeats: days.isEmpty ? .never : .weekly(days)
        )
    )
    let tint = Color(red: 1, green: 0.5, blue: 0, opacity: 1)
    let listen = AlarmButton(
        text: LocalizedStringResource("RADIO_ALARM_LISTEN"),
        textColor: tint,
        systemImageName: "play.fill"
    )
    let alert = AlarmPresentation.Alert(
        title: LocalizedStringResource("Station"),
        secondaryButton: listen,
        secondaryButtonBehavior: .custom
    )
    let attributes = AlarmAttributes(
        presentation: AlarmPresentation(alert: alert),
        metadata: AlarmKitProbeMetadata(label: "vlc"),
        tintColor: tint
    )
    let configuration = AlarmManager.AlarmConfiguration(
        schedule: schedule,
        attributes: attributes,
        secondaryIntent: AlarmKitEmptyIntent()
    )
    alarmKitExpect(configuration.schedule != nil, "vlc schedule stored")
    alarmKitExpectEqual(
        configuration.attributes.presentation.alert.secondaryButtonBehavior,
        .custom,
        "vlc custom secondary"
    )
    alarmKitRunBlocking {
        do {
            _ = try await AlarmManager.shared.schedule(
                id: UUID(),
                configuration: configuration
            )
            fatalError("ALARMKIT_TEST_FAIL: corpus schedule must throw")
        } catch {
            alarmKitRequireLinuxUnavailable(error)
        }
    }
}


func testPresentationStateAlertMode() {
    let alert = AlarmPresentationState.Mode.Alert(
        time: Alarm.Schedule.Relative.Time(hour: 5, minute: 0)
    )
    alarmKitExpectEqual(alert.time.hour, 5, "mode alert hour")
    alarmKitExpectEqual(alert.time.minute, 0, "mode alert minute")
    alarmKitExpect(
        alert == AlarmPresentationState.Mode.Alert(time: alert.time),
        "alert =="
    )
    alarmKitExpect(
        alert != AlarmPresentationState.Mode.Alert(
            time: Alarm.Schedule.Relative.Time(hour: 6, minute: 0)
        ),
        "alert !="
    )
    _ = alert.hashValue
    var hasher = Hasher()
    alert.hash(into: &hasher)
    _ = hasher.finalize()
    let mode = AlarmPresentationState.Mode.alert(alert)
    if case .alert(let nested) = mode {
        alarmKitExpectEqual(nested.time.hour, 5, "nested alert hour")
    } else {
        fatalError("ALARMKIT_TEST_FAIL: expected alert mode")
    }
}

func testPresentationStateAlertModeCodable() {
    let mode = AlarmPresentationState.Mode.alert(
        AlarmPresentationState.Mode.Alert(
            time: Alarm.Schedule.Relative.Time(hour: 5, minute: 0)
        )
    )
    let decoded = alarmKitRoundTrip(mode)
    if case .alert(let alert) = decoded {
        alarmKitExpectEqual(alert.time.hour, 5, "decoded alert hour")
    } else {
        fatalError("ALARMKIT_TEST_FAIL: expected decoded alert mode")
    }
}

func testPresentationStateCountdownMode() {
    let countdown = AlarmPresentationState.Mode.Countdown(
        totalCountdownDuration: 60,
        previouslyElapsedDuration: 10,
        startDate: Date(timeIntervalSince1970: 100),
        fireDate: Date(timeIntervalSince1970: 160)
    )
    alarmKitExpectEqual(countdown.totalCountdownDuration, 60, "countdown total")
    alarmKitExpectEqual(countdown.previouslyElapsedDuration, 10, "countdown elapsed")
    alarmKitExpectEqual(countdown.startDate.timeIntervalSince1970, 100, "start")
    alarmKitExpectEqual(countdown.fireDate.timeIntervalSince1970, 160, "fire")
    alarmKitExpect(countdown == countdown, "countdown ==")
    alarmKitExpect(
        countdown != AlarmPresentationState.Mode.Countdown(
            totalCountdownDuration: 1,
            previouslyElapsedDuration: 0,
            startDate: Date(timeIntervalSince1970: 0),
            fireDate: Date(timeIntervalSince1970: 1)
        ),
        "countdown !="
    )
    _ = countdown.hashValue
    var hasher = Hasher()
    countdown.hash(into: &hasher)
    _ = hasher.finalize()
    let mode = AlarmPresentationState.Mode.countdown(countdown)
    if case .countdown(let nested) = mode {
        alarmKitExpectEqual(nested.totalCountdownDuration, 60, "nested total")
    } else {
        fatalError("ALARMKIT_TEST_FAIL: expected countdown mode")
    }
}

func testPresentationStateCountdownModeCodable() {
    let mode = AlarmPresentationState.Mode.countdown(
        AlarmPresentationState.Mode.Countdown(
            totalCountdownDuration: 60,
            previouslyElapsedDuration: 10,
            startDate: Date(timeIntervalSince1970: 100),
            fireDate: Date(timeIntervalSince1970: 160)
        )
    )
    let decoded = alarmKitRoundTrip(mode)
    if case .countdown(let countdown) = decoded {
        alarmKitExpectEqual(countdown.fireDate.timeIntervalSince1970, 160, "decoded fire")
    } else {
        fatalError("ALARMKIT_TEST_FAIL: expected decoded countdown mode")
    }
}

func testPresentationStatePausedMode() {
    let paused = AlarmPresentationState.Mode.Paused(
        totalCountdownDuration: 60,
        previouslyElapsedDuration: 15
    )
    alarmKitExpectEqual(paused.totalCountdownDuration, 60, "paused total")
    alarmKitExpectEqual(paused.previouslyElapsedDuration, 15, "paused elapsed")
    alarmKitExpect(paused == paused, "paused ==")
    alarmKitExpect(
        paused != AlarmPresentationState.Mode.Paused(
            totalCountdownDuration: 1,
            previouslyElapsedDuration: 0
        ),
        "paused !="
    )
    _ = paused.hashValue
    var hasher = Hasher()
    paused.hash(into: &hasher)
    _ = hasher.finalize()
    let mode = AlarmPresentationState.Mode.paused(paused)
    if case .paused(let nested) = mode {
        alarmKitExpectEqual(nested.previouslyElapsedDuration, 15, "nested elapsed")
    } else {
        fatalError("ALARMKIT_TEST_FAIL: expected paused mode")
    }
}

func testPresentationStatePausedModeCodable() {
    let mode = AlarmPresentationState.Mode.paused(
        AlarmPresentationState.Mode.Paused(
            totalCountdownDuration: 60,
            previouslyElapsedDuration: 15
        )
    )
    let decoded = alarmKitRoundTrip(mode)
    if case .paused(let paused) = decoded {
        alarmKitExpectEqual(paused.previouslyElapsedDuration, 15, "decoded paused elapsed")
    } else {
        fatalError("ALARMKIT_TEST_FAIL: expected decoded paused mode")
    }
}

func testPresentationStateIdentity() {
    let id = UUID()
    let alertMode = AlarmPresentationState.Mode.alert(
        AlarmPresentationState.Mode.Alert(
            time: Alarm.Schedule.Relative.Time(hour: 5, minute: 0)
        )
    )
    let pausedMode = AlarmPresentationState.Mode.paused(
        AlarmPresentationState.Mode.Paused(
            totalCountdownDuration: 60,
            previouslyElapsedDuration: 15
        )
    )
    alarmKitExpect(alertMode != pausedMode, "mode !=")
    _ = alertMode.hashValue
    var modeHasher = Hasher()
    alertMode.hash(into: &modeHasher)
    _ = modeHasher.finalize()

    let state = AlarmPresentationState(alarmID: id, mode: alertMode)
    alarmKitExpectEqual(state.alarmID, id, "presentation state id")
    alarmKitExpect(state.mode == alertMode, "presentation state mode")
    alarmKitExpect(state == AlarmPresentationState(alarmID: id, mode: alertMode), "state ==")
    alarmKitExpect(state != AlarmPresentationState(alarmID: id, mode: pausedMode), "state !=")
    _ = state.hashValue
    var hasher = Hasher()
    state.hash(into: &hasher)
    _ = hasher.finalize()
}

func testPresentationStateCodable() {
    let id = UUID()
    let state = AlarmPresentationState(
        alarmID: id,
        mode: .alert(
            AlarmPresentationState.Mode.Alert(
                time: Alarm.Schedule.Relative.Time(hour: 5, minute: 0)
            )
        )
    )
    let decoded = alarmKitRoundTrip(state)
    alarmKitExpectEqual(decoded.alarmID, id, "decoded presentation state id")
}


func testSecondaryButtonBehaviorCases() {
    let custom = AlarmPresentation.Alert.SecondaryButtonBehavior.custom
    let countdown = AlarmPresentation.Alert.SecondaryButtonBehavior.countdown
    alarmKitExpect(custom == .custom, "behavior ==")
    alarmKitExpect(custom != countdown, "behavior !=")
    _ = custom.hashValue
    var hasher = Hasher()
    countdown.hash(into: &hasher)
    _ = hasher.finalize()
}

func testSecondaryButtonBehaviorCodable() {
    let custom = AlarmPresentation.Alert.SecondaryButtonBehavior.custom
    alarmKitExpectEqual(alarmKitRoundTrip(custom), custom, "behavior round-trip")
    alarmKitExpectEqual(
        alarmKitRoundTrip(AlarmPresentation.Alert.SecondaryButtonBehavior.countdown),
        .countdown,
        "countdown behavior round-trip"
    )
}

func testAlarmPresentationAlertFullInit() {
    let presentation = alarmKitMakePresentation()
    alarmKitExpectEqual(presentation.alert.title.key, "Wake", "alert title")
    alarmKitExpectEqual(
        presentation.alert.stopButton.systemImageName,
        "stop.circle",
        "alert stop"
    )
    alarmKitExpect(presentation.alert.secondaryButton != nil, "secondary present")
    alarmKitExpectEqual(
        presentation.alert.secondaryButtonBehavior,
        .countdown,
        "secondary behavior"
    )
}

func testAlarmPresentationAlertDefaultStopButton() {
    let defaultStop = AlarmPresentation.Alert(
        title: LocalizedStringResource("Default stop"),
        secondaryButton: alarmKitListenButton(),
        secondaryButtonBehavior: .custom
    )
    alarmKitExpectEqual(
        defaultStop.stopButton.systemImageName,
        "stop.circle",
        "placeholder stop"
    )
    alarmKitExpectEqual(defaultStop.title.key, "Default stop", "default title")
    alarmKitExpectEqual(
        defaultStop.secondaryButton?.systemImageName,
        "play.fill",
        "corpus listen button"
    )
    alarmKitExpectEqual(defaultStop.secondaryButtonBehavior, .custom, "corpus custom")
}

func testAlarmPresentationCountdownPaused() {
    let presentation = alarmKitMakePresentation()
    alarmKitExpectEqual(presentation.countdown?.title.key, "Counting down", "countdown title")
    alarmKitExpectEqual(
        presentation.countdown?.pauseButton?.systemImageName,
        "pause.circle",
        "pause image"
    )
    alarmKitExpectEqual(presentation.paused?.title.key, "Paused", "paused title")
    alarmKitExpectEqual(
        presentation.paused?.resumeButton.systemImageName,
        "play.circle",
        "resume image"
    )
}

func testAlarmPresentationCodable() {
    let decoded = alarmKitRoundTrip(alarmKitMakePresentation())
    alarmKitExpectEqual(decoded.alert.title.key, "Wake", "presentation round-trip")
    alarmKitExpectEqual(decoded.countdown?.title.key, "Counting down", "countdown round-trip")
    alarmKitExpectEqual(decoded.paused?.title.key, "Paused", "paused round-trip")
}


func testScheduleRelativeTime() {
    let time = Alarm.Schedule.Relative.Time(hour: 7, minute: 30)
    alarmKitExpectEqual(time.hour, 7, "hour")
    alarmKitExpectEqual(time.minute, 30, "minute")
    alarmKitExpect(time == Alarm.Schedule.Relative.Time(hour: 7, minute: 30), "Time ==")
    alarmKitExpect(time != Alarm.Schedule.Relative.Time(hour: 8, minute: 0), "Time !=")
    _ = time.hashValue
    var hasher = Hasher()
    time.hash(into: &hasher)
    _ = hasher.finalize()
}

func testScheduleRelativeTimeCodable() {
    let time = Alarm.Schedule.Relative.Time(hour: 7, minute: 30)
    let decoded = alarmKitRoundTrip(time)
    alarmKitExpectEqual(decoded.hour, 7, "decoded time hour")
    alarmKitExpectEqual(decoded.minute, 30, "decoded time minute")
}

func testScheduleRecurrenceCases() {
    alarmKitExpect(Alarm.Schedule.Relative.Recurrence.never == .never, "never ==")
    alarmKitExpect(
        Alarm.Schedule.Relative.Recurrence.never != .weekly([.monday]),
        "never !="
    )
    let weekly = Alarm.Schedule.Relative.Recurrence.weekly([.monday, .friday])
    alarmKitExpect(weekly == .weekly([.monday, .friday]), "weekly ==")
    _ = Alarm.Schedule.Relative.Recurrence.never.hashValue
    var hasher = Hasher()
    weekly.hash(into: &hasher)
    _ = hasher.finalize()
}

func testScheduleRecurrenceCodable() {
    let weekly = Alarm.Schedule.Relative.Recurrence.weekly([.monday, .friday])
    alarmKitExpectEqual(alarmKitRoundTrip(weekly), weekly, "decoded weekly")
    alarmKitExpectEqual(
        alarmKitRoundTrip(Alarm.Schedule.Relative.Recurrence.never),
        .never,
        "decoded never"
    )
}

func testScheduleRelativeInit() {
    let time = Alarm.Schedule.Relative.Time(hour: 7, minute: 30)
    let never = Alarm.Schedule.Relative(time: time)
    alarmKitExpectEqual(never.time.hour, 7, "relative hour")
    alarmKitExpect(never.repeats == .never, "default repeats")
    let weekly = Alarm.Schedule.Relative(
        time: time,
        repeats: .weekly([.monday, .friday])
    )
    alarmKitExpect(weekly.repeats == .weekly([.monday, .friday]), "weekly repeats")
    alarmKitExpect(weekly != never, "relative !=")
    alarmKitExpect(weekly == weekly, "relative ==")
    _ = weekly.hashValue
    var hasher = Hasher()
    never.hash(into: &hasher)
    _ = hasher.finalize()
}

func testScheduleRelativeCodable() {
    let relative = Alarm.Schedule.Relative(
        time: Alarm.Schedule.Relative.Time(hour: 6, minute: 45),
        repeats: .weekly([.monday, .wednesday])
    )
    let decoded = alarmKitRoundTrip(relative)
    alarmKitExpectEqual(decoded.time.hour, 6, "decoded relative hour")
    alarmKitExpectEqual(decoded.time.minute, 45, "decoded relative minute")
    alarmKitExpect(decoded.repeats == .weekly([.monday, .wednesday]), "decoded repeats")
}

func testScheduleFixedAndRelativeCases() {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let fixed = Alarm.Schedule.fixed(date)
    let relative = Alarm.Schedule.relative(
        Alarm.Schedule.Relative(time: Alarm.Schedule.Relative.Time(hour: 7, minute: 30))
    )
    alarmKitExpect(fixed != relative, "schedule !=")
    alarmKitExpect(fixed == Alarm.Schedule.fixed(date), "fixed ==")
    _ = fixed.hashValue
    var hasher = Hasher()
    relative.hash(into: &hasher)
    _ = hasher.finalize()
}

func testScheduleCodable() {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let fixed = Alarm.Schedule.fixed(date)
    let decodedFixed = alarmKitRoundTrip(fixed)
    if case .fixed(let decodedDate) = decodedFixed {
        alarmKitExpectEqual(
            decodedDate.timeIntervalSince1970,
            date.timeIntervalSince1970,
            "fixed date"
        )
    } else {
        fatalError("ALARMKIT_TEST_FAIL: expected fixed schedule")
    }

    let weekly = Alarm.Schedule.Relative.Recurrence.weekly([.monday, .friday])
    let relativeSchedule = Alarm.Schedule.relative(
        Alarm.Schedule.Relative(
            time: Alarm.Schedule.Relative.Time(hour: 7, minute: 30),
            repeats: weekly
        )
    )
    let decodedRelative = alarmKitRoundTrip(relativeSchedule)
    if case .relative(let decoded) = decodedRelative {
        alarmKitExpectEqual(decoded.time.hour, 7, "decoded relative hour")
        alarmKitExpectEqual(decoded.time.minute, 30, "decoded relative minute")
        alarmKitExpect(decoded.repeats == weekly, "decoded weekly")
    } else {
        fatalError("ALARMKIT_TEST_FAIL: expected relative schedule")
    }
}


func testAlarmStateCases() {
    let cases: [Alarm.State] = [.scheduled, .countdown, .paused, .alerting]
    alarmKitExpectEqual(cases.count, 4, "four Alarm.State cases")
    alarmKitExpectEqual(Alarm.State.scheduled, .scheduled, "scheduled identity")
    alarmKitExpect(Alarm.State.countdown != .paused, "countdown is not paused")
    alarmKitExpect(Alarm.State.alerting != .scheduled, "alerting is not scheduled")
}

func testAlarmStateEquatableHashable() {
    alarmKitExpect(Alarm.State.scheduled == .scheduled, "state ==")
    alarmKitExpect(Alarm.State.scheduled != .alerting, "state !=")
    _ = Alarm.State.paused.hashValue
    var hasher = Hasher()
    Alarm.State.countdown.hash(into: &hasher)
    _ = hasher.finalize()
    alarmKitExpectEqual(
        Alarm.State.scheduled.hashValue,
        Alarm.State.scheduled.hashValue,
        "equal states hash equal"
    )
}

func testAlarmStateCodable() {
    for state in [Alarm.State.scheduled, .countdown, .paused, .alerting] {
        alarmKitExpectEqual(alarmKitRoundTrip(state), state, "state round-trip \(state)")
    }
}


func testAlarmUpdatesTypesAndEmptyNext() {
    let _: AlarmManager.AlarmUpdates.Element.Type = [Alarm].self
    let _: AlarmManager.AlarmUpdates.AsyncIterator.Type =
        AlarmManager.AlarmUpdates.Iterator.self
    let _: AlarmManager.AlarmUpdates.Iterator.Element.Type = [Alarm].self
    alarmKitRunBlocking {
        var iterator = AlarmManager.AlarmUpdates().makeAsyncIterator()
        let element: [Alarm]? = await iterator.next()
        alarmKitExpect(element == nil, "alarmUpdates is empty")
        var opaque = AlarmManager.shared.alarmUpdates.makeAsyncIterator()
        let opaqueElement: [Alarm]? = try await opaque.next()
        alarmKitExpect(opaqueElement == nil, "opaque alarmUpdates is empty")
    }
}

func testAlarmUpdatesNextIsolation() {
    alarmKitRunBlocking {
        var iterator = AlarmManager.AlarmUpdates().makeAsyncIterator()
        let isolated: [Alarm]? = await iterator.next(isolation: nil)
        alarmKitExpect(isolated == nil, "next(isolation:) is empty")
    }
}

func testAuthorizationUpdatesTypesAndEmptyNext() {
    let _: AlarmManager.AlarmAuthorizationStateUpdates.Element.Type =
        AlarmManager.AuthorizationState.self
    let _: AlarmManager.AlarmAuthorizationStateUpdates.AsyncIterator.Type =
        AlarmManager.AlarmAuthorizationStateUpdates.Iterator.self
    let _: AlarmManager.AlarmAuthorizationStateUpdates.Iterator.Element.Type =
        AlarmManager.AuthorizationState.self
    alarmKitRunBlocking {
        var iterator = AlarmManager.AlarmAuthorizationStateUpdates().makeAsyncIterator()
        let element: AlarmManager.AuthorizationState? = await iterator.next()
        alarmKitExpect(element == nil, "authorizationUpdates is empty")
        var opaque = AlarmManager.shared.authorizationUpdates.makeAsyncIterator()
        let opaqueElement: AlarmManager.AuthorizationState? = try await opaque.next()
        alarmKitExpect(opaqueElement == nil, "opaque authorizationUpdates is empty")
    }
}

func testAuthorizationUpdatesNextIsolation() {
    alarmKitRunBlocking {
        var iterator = AlarmManager.AlarmAuthorizationStateUpdates().makeAsyncIterator()
        let isolated: AlarmManager.AuthorizationState? =
            await iterator.next(isolation: nil)
        alarmKitExpect(isolated == nil, "auth next(isolation:) is empty")
    }
}


func testAlarmIDTypealias() {
    let id: Alarm.ID = UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!
    alarmKitExpectEqual(
        id,
        UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!,
        "Alarm.ID is UUID"
    )
}

func testAlarmDecodeEncode() {
    let payload: [String: Any] = [
        "id": "123e4567-e89b-12d3-a456-426614174000",
        "state": "scheduled",
        "schedule": [
            "relative": [
                "time": ["hour": 6, "minute": 45],
                "repeats": ["weekly": ["mon", "wed"]],
            ]
        ],
        "countdownDuration": ["preAlert": 10, "postAlert": 20],
    ]
    let data: Data
    let alarm: Alarm
    do {
        data = try JSONSerialization.data(withJSONObject: payload)
        alarm = try JSONDecoder().decode(Alarm.self, from: data)
    } catch {
        fatalError("ALARMKIT_TEST_FAIL decode Alarm: \(error)")
    }
    alarmKitExpectEqual(
        alarm.id,
        UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!,
        "alarm id"
    )
    alarmKitExpectEqual(alarm.state, .scheduled, "alarm state")
    alarmKitExpectEqual(alarm.countdownDuration?.preAlert, 10, "alarm preAlert")
    alarmKitExpectEqual(alarm.countdownDuration?.postAlert, 20, "alarm postAlert")
    if case .relative(let relative) = alarm.schedule {
        alarmKitExpectEqual(relative.time.hour, 6, "decoded hour")
        alarmKitExpectEqual(relative.time.minute, 45, "decoded minute")
    } else {
        fatalError("ALARMKIT_TEST_FAIL: expected relative schedule on alarm")
    }
    let encoded = alarmKitRoundTrip(alarm)
    alarmKitExpectEqual(encoded.id, alarm.id, "round-trip id")
    alarmKitExpectEqual(encoded.state, alarm.state, "round-trip state")
    alarmKitExpectEqual(
        encoded.countdownDuration?.preAlert,
        alarm.countdownDuration?.preAlert,
        "round-trip countdown"
    )
}


testAlarmUpdatesAllSatisfyFirstContains()
testAlarmUpdatesMapAndCompactMap()
testAlarmUpdatesFilterDropPrefix()
testAlarmUpdatesReduceMinMax()
testAlarmUpdatesFlatMapOverloads()
testAuthorizationUpdatesAllSatisfyFirstContains()
testAuthorizationUpdatesMapAndCompactMap()
testAuthorizationUpdatesFilterDropPrefix()
testAuthorizationUpdatesReduceMinMax()
testAuthorizationUpdatesFlatMapOverloads()
testAlarmMetadataConformance()
testAlarmAttributesInitAndContentState()
testAlarmAttributesCodable()
testAlarmButtonInitAndProperties()
testAlarmButtonCodable()
testAlarmConfigurationMemberwiseInit()
testAlarmConfigurationAlarmFactory()
testAlarmConfigurationTimerFactory()
testCountdownDurationInitAndProperties()
testCountdownDurationEquatable()
testCountdownDurationCodable()
testAlarmManagerSharedIdentity()
testAuthorizationStateCases()
testAuthorizationStateCodable()
testAlarmManagerInitialAuthorization()
testAlarmManagerAlarmsFailClosed()
testAlarmManagerStopPauseCancelResumeCountdownFailClosed()
testAlarmManagerScheduleFailClosed()
testAlarmManagerRequestAuthorizationDenied()
testAlarmErrorMaximumLimitReached()
testCorpusVLCRadioAlarmConstruction()
testPresentationStateAlertMode()
testPresentationStateAlertModeCodable()
testPresentationStateCountdownMode()
testPresentationStateCountdownModeCodable()
testPresentationStatePausedMode()
testPresentationStatePausedModeCodable()
testPresentationStateIdentity()
testPresentationStateCodable()
testSecondaryButtonBehaviorCases()
testSecondaryButtonBehaviorCodable()
testAlarmPresentationAlertFullInit()
testAlarmPresentationAlertDefaultStopButton()
testAlarmPresentationCountdownPaused()
testAlarmPresentationCodable()
testScheduleRelativeTime()
testScheduleRelativeTimeCodable()
testScheduleRecurrenceCases()
testScheduleRecurrenceCodable()
testScheduleRelativeInit()
testScheduleRelativeCodable()
testScheduleFixedAndRelativeCases()
testScheduleCodable()
testAlarmStateCases()
testAlarmStateEquatableHashable()
testAlarmStateCodable()
testAlarmUpdatesTypesAndEmptyNext()
testAlarmUpdatesNextIsolation()
testAuthorizationUpdatesTypesAndEmptyNext()
testAuthorizationUpdatesNextIsolation()
testAlarmIDTypealias()
testAlarmDecodeEncode()

print("ALARMKIT_AGENT_RUNTIME_OK")

