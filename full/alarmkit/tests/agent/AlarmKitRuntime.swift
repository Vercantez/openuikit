import AlarmKit
import Foundation

private func expect(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError("ALARMKIT_AGENT_RUNTIME_FAIL: \(message)")
    }
}

private func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    expect(actual == expected, "\(message): \(actual) != \(expected)")
}

private struct ProbeMetadata: AlarmMetadata {
    var label: String
}

private final class ErrorBox: @unchecked Sendable {
    var error: (any Error)?
}

private func runBlocking(_ work: @escaping @Sendable () async throws -> Void) {
    let lock = DispatchSemaphore(value: 0)
    let box = ErrorBox()
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
        fatalError("ALARMKIT_AGENT_RUNTIME_FAIL async: \(error)")
    }
}

private func requireLinuxUnavailable(_ error: any Error) {
    let nsError = error as NSError
    expectEqual(nsError.domain, AlarmKitLinuxErrorDomain, "fail-closed domain")
    expectEqual(nsError.code, 1, "fail-closed code")
}

private func roundTrip<T: Codable>(_ value: T) throws -> T {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(value)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(T.self, from: data)
}

private func makeStopButton() -> AlarmButton {
    AlarmButton(
        text: LocalizedStringResource("Stop"),
        textColor: Color(red: 1, green: 0, blue: 0, opacity: 1),
        systemImageName: "stop.circle"
    )
}

private func makeSnoozeButton() -> AlarmButton {
    AlarmButton(
        text: "Snooze",
        textColor: .primary,
        systemImageName: "zzz"
    )
}

private func makePresentation() -> AlarmPresentation {
    let alert = AlarmPresentation.Alert(
        title: LocalizedStringResource("Wake"),
        stopButton: makeStopButton(),
        secondaryButton: makeSnoozeButton(),
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

private func proveCountdownDuration() throws {
    let duration = Alarm.CountdownDuration(preAlert: 15, postAlert: 30)
    expectEqual(duration.preAlert, 15, "preAlert")
    expectEqual(duration.postAlert, 30, "postAlert")
    let copy = Alarm.CountdownDuration(preAlert: 15, postAlert: 30)
    expect(duration == copy, "CountdownDuration ==")
    expect(!(duration != copy), "CountdownDuration !=")
    let decoded = try roundTrip(duration)
    expectEqual(decoded.preAlert, 15, "decoded preAlert")
    expectEqual(decoded.postAlert, 30, "decoded postAlert")
    let empty = Alarm.CountdownDuration(preAlert: nil, postAlert: nil)
    expect(empty.preAlert == nil, "nil preAlert")
    expect(empty.postAlert == nil, "nil postAlert")
    expect(empty != duration, "nil duration differs")
}

private func proveSchedule() throws {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let fixed = Alarm.Schedule.fixed(date)
    let time = Alarm.Schedule.Relative.Time(hour: 7, minute: 30)
    expectEqual(time.hour, 7, "hour")
    expectEqual(time.minute, 30, "minute")
    expect(time == Alarm.Schedule.Relative.Time(hour: 7, minute: 30), "Time ==")
    expect(time != Alarm.Schedule.Relative.Time(hour: 8, minute: 0), "Time !=")
    _ = time.hashValue
    var hasher = Hasher()
    time.hash(into: &hasher)

    let never = Alarm.Schedule.Relative(time: time)
    expectEqual(never.time.hour, 7, "relative hour")
    expect(never.repeats == .never, "default repeats")
    expect(Alarm.Schedule.Relative.Recurrence.never == .never, "never ==")
    expect(Alarm.Schedule.Relative.Recurrence.never != .weekly([.monday]), "never !=")
    _ = Alarm.Schedule.Relative.Recurrence.never.hashValue
    var recurrenceHasher = Hasher()
    Alarm.Schedule.Relative.Recurrence.never.hash(into: &recurrenceHasher)

    let weekly = Alarm.Schedule.Relative.Recurrence.weekly([.monday, .friday])
    let relative = Alarm.Schedule.Relative(time: time, repeats: weekly)
    expect(relative.repeats == weekly, "weekly repeats")
    expect(relative != never, "relative !=")
    _ = relative.hashValue
    var relativeHasher = Hasher()
    relative.hash(into: &relativeHasher)

    let relativeSchedule = Alarm.Schedule.relative(relative)
    expect(fixed != relativeSchedule, "schedule !=")
    expect(fixed == Alarm.Schedule.fixed(date), "fixed ==")
    _ = fixed.hashValue
    var scheduleHasher = Hasher()
    fixed.hash(into: &scheduleHasher)

    let decodedFixed = try roundTrip(fixed)
    if case .fixed(let decodedDate) = decodedFixed {
        expectEqual(
            decodedDate.timeIntervalSince1970,
            date.timeIntervalSince1970,
            "fixed date"
        )
    } else {
        fatalError("ALARMKIT_AGENT_RUNTIME_FAIL: expected fixed schedule")
    }
    let decodedRelative = try roundTrip(relativeSchedule)
    if case .relative(let decoded) = decodedRelative {
        expectEqual(decoded.time.hour, 7, "decoded relative hour")
        expectEqual(decoded.time.minute, 30, "decoded relative minute")
        expect(decoded.repeats == weekly, "decoded weekly")
    } else {
        fatalError("ALARMKIT_AGENT_RUNTIME_FAIL: expected relative schedule")
    }

    let decodedTime = try roundTrip(time)
    expectEqual(decodedTime.hour, 7, "decoded time hour")
    let decodedRecurrence = try roundTrip(weekly)
    expect(decodedRecurrence == weekly, "decoded recurrence")
    let decodedNever = try roundTrip(Alarm.Schedule.Relative.Recurrence.never)
    expect(decodedNever == .never, "decoded never")
}

private func proveState() throws {
    let states: [Alarm.State] = [.scheduled, .countdown, .paused, .alerting]
    expect(Set(states).count == 4, "four states")
    expect(Alarm.State.scheduled == .scheduled, "state ==")
    expect(Alarm.State.scheduled != .alerting, "state !=")
    _ = Alarm.State.paused.hashValue
    var hasher = Hasher()
    Alarm.State.countdown.hash(into: &hasher)
    for state in states {
        expectEqual(try roundTrip(state), state, "state round-trip \(state)")
    }
}

private func proveAlarmCodable() throws {
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
    let data = try JSONSerialization.data(withJSONObject: payload)
    let decoder = JSONDecoder()
    let alarm = try decoder.decode(Alarm.self, from: data)
    expectEqual(
        alarm.id,
        UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!,
        "alarm id"
    )
    expectEqual(alarm.state, .scheduled, "alarm state")
    expectEqual(alarm.countdownDuration?.preAlert, 10, "alarm preAlert")
    expectEqual(alarm.countdownDuration?.postAlert, 20, "alarm postAlert")
    if case .relative(let relative) = alarm.schedule {
        expectEqual(relative.time.hour, 6, "decoded hour")
        expectEqual(relative.time.minute, 45, "decoded minute")
    } else {
        fatalError("ALARMKIT_AGENT_RUNTIME_FAIL: expected relative schedule on alarm")
    }
    let encoded = try roundTrip(alarm)
    expectEqual(encoded.id, alarm.id, "round-trip id")
    expectEqual(encoded.state, alarm.state, "round-trip state")
}

private func proveButtonsAndPresentation() throws {
    let stop = makeStopButton()
    expectEqual(stop.text.key, "Stop", "stop text")
    expectEqual(stop.systemImageName, "stop.circle", "stop image")
    expectEqual(stop.textColor.red, 1, "stop red")
    let decodedButton = try roundTrip(stop)
    expectEqual(decodedButton.systemImageName, "stop.circle", "button round-trip")

    let custom = AlarmPresentation.Alert.SecondaryButtonBehavior.custom
    let countdown = AlarmPresentation.Alert.SecondaryButtonBehavior.countdown
    expect(custom == .custom, "behavior ==")
    expect(custom != countdown, "behavior !=")
    _ = custom.hashValue
    var hasher = Hasher()
    countdown.hash(into: &hasher)
    expectEqual(try roundTrip(custom), custom, "behavior round-trip")

    let presentation = makePresentation()
    expectEqual(presentation.alert.title.key, "Wake", "alert title")
    expectEqual(presentation.alert.stopButton.systemImageName, "stop.circle", "alert stop")
    expect(presentation.alert.secondaryButton != nil, "secondary present")
    expectEqual(
        presentation.alert.secondaryButtonBehavior,
        .countdown,
        "secondary behavior"
    )
    expectEqual(presentation.countdown?.title.key, "Counting down", "countdown title")
    expectEqual(presentation.paused?.title.key, "Paused", "paused title")
    expectEqual(
        presentation.paused?.resumeButton.systemImageName,
        "play.circle",
        "resume image"
    )
    let decodedPresentation = try roundTrip(presentation)
    expectEqual(decodedPresentation.alert.title.key, "Wake", "presentation round-trip")

    let defaultStop = AlarmPresentation.Alert(title: "Default stop")
    expectEqual(defaultStop.stopButton.systemImageName, "stop.circle", "placeholder stop")
    expectEqual(defaultStop.title.key, "Default stop", "default title")
    expect(defaultStop.secondaryButton == nil, "no secondary")
}

private func provePresentationState() throws {
    let id = UUID()
    let alertMode = AlarmPresentationState.Mode.alert(
        AlarmPresentationState.Mode.Alert(
            time: Alarm.Schedule.Relative.Time(hour: 5, minute: 0)
        )
    )
    let countdownMode = AlarmPresentationState.Mode.countdown(
        AlarmPresentationState.Mode.Countdown(
            totalCountdownDuration: 60,
            previouslyElapsedDuration: 10,
            startDate: Date(timeIntervalSince1970: 100),
            fireDate: Date(timeIntervalSince1970: 160)
        )
    )
    let pausedMode = AlarmPresentationState.Mode.paused(
        AlarmPresentationState.Mode.Paused(
            totalCountdownDuration: 60,
            previouslyElapsedDuration: 15
        )
    )
    expect(alertMode != countdownMode, "mode !=")
    if case .alert(let alert) = alertMode {
        expectEqual(alert.time.hour, 5, "mode alert hour")
        expect(alert == AlarmPresentationState.Mode.Alert(time: alert.time), "alert ==")
        _ = alert.hashValue
        var alertHasher = Hasher()
        alert.hash(into: &alertHasher)
    } else {
        fatalError("ALARMKIT_AGENT_RUNTIME_FAIL: expected alert mode")
    }
    if case .countdown(let countdown) = countdownMode {
        expectEqual(countdown.totalCountdownDuration, 60, "countdown total")
        expectEqual(countdown.previouslyElapsedDuration, 10, "countdown elapsed")
        expectEqual(countdown.startDate.timeIntervalSince1970, 100, "start")
        expectEqual(countdown.fireDate.timeIntervalSince1970, 160, "fire")
        _ = countdown.hashValue
        var countdownHasher = Hasher()
        countdown.hash(into: &countdownHasher)
    } else {
        fatalError("ALARMKIT_AGENT_RUNTIME_FAIL: expected countdown mode")
    }
    if case .paused(let paused) = pausedMode {
        expectEqual(paused.previouslyElapsedDuration, 15, "paused elapsed")
        _ = paused.hashValue
        var pausedHasher = Hasher()
        paused.hash(into: &pausedHasher)
    } else {
        fatalError("ALARMKIT_AGENT_RUNTIME_FAIL: expected paused mode")
    }
    _ = alertMode.hashValue
    var modeHasher = Hasher()
    alertMode.hash(into: &modeHasher)

    let state = AlarmPresentationState(alarmID: id, mode: alertMode)
    expectEqual(state.alarmID, id, "presentation state id")
    expect(state == AlarmPresentationState(alarmID: id, mode: alertMode), "state ==")
    expect(state != AlarmPresentationState(alarmID: id, mode: pausedMode), "state !=")
    _ = state.hashValue
    var stateHasher = Hasher()
    state.hash(into: &stateHasher)
    let decoded = try roundTrip(state)
    expectEqual(decoded.alarmID, id, "decoded presentation state id")
}

private func proveAttributesAndConfiguration() throws {
    let presentation = makePresentation()
    let metadata = ProbeMetadata(label: "probe")
    let attributes = AlarmAttributes(
        presentation: presentation,
        metadata: metadata,
        tintColor: Color(red: 0, green: 0, blue: 1, opacity: 1)
    )
    expectEqual(attributes.metadata?.label, "probe", "metadata")
    expectEqual(attributes.tintColor.blue, 1, "tint")
    let _: AlarmAttributes<ProbeMetadata>.ContentState.Type = AlarmPresentationState.self
    let decodedAttributes = try roundTrip(attributes)
    expectEqual(decodedAttributes.metadata?.label, "probe", "attributes round-trip")

    let configuration = AlarmManager.AlarmConfiguration(
        countdownDuration: Alarm.CountdownDuration(preAlert: 5, postAlert: nil),
        schedule: .fixed(Date(timeIntervalSince1970: 0)),
        attributes: attributes,
        stopIntent: nil,
        secondaryIntent: nil,
        sound: .default
    )
    expectEqual(configuration.sound.identifier, "default", "default sound")
    expect(configuration.stopIntent == nil, "no stop intent")

    let alarmConfig = AlarmManager.AlarmConfiguration<ProbeMetadata>.alarm(
        schedule: .fixed(Date(timeIntervalSince1970: 1)),
        attributes: attributes,
        sound: AlertConfiguration.AlertSound(named: "radar")
    )
    expectEqual(alarmConfig.sound.identifier, "radar", "named sound")
    expect(alarmConfig.countdownDuration == nil, "alarm factory duration")

    let timerConfig = AlarmManager.AlarmConfiguration<ProbeMetadata>.timer(
        duration: 90,
        attributes: attributes
    )
    expectEqual(timerConfig.countdownDuration?.preAlert, 90, "timer duration")
    expect(timerConfig.schedule == nil, "timer has no schedule")
}

private func proveManagerFailClosed() throws {
    let manager = AlarmManager.shared
    expectEqual(manager.authorizationState, .notDetermined, "initial auth")

    do {
        _ = try manager.alarms
        fatalError("ALARMKIT_AGENT_RUNTIME_FAIL: alarms must throw")
    } catch {
        requireLinuxUnavailable(error)
    }

    let probeID = UUID()
    do { try manager.stop(id: probeID); fatalError("stop must throw") } catch {
        requireLinuxUnavailable(error)
    }
    do { try manager.pause(id: probeID); fatalError("pause must throw") } catch {
        requireLinuxUnavailable(error)
    }
    do { try manager.cancel(id: probeID); fatalError("cancel must throw") } catch {
        requireLinuxUnavailable(error)
    }
    do { try manager.resume(id: probeID); fatalError("resume must throw") } catch {
        requireLinuxUnavailable(error)
    }
    do { try manager.countdown(id: probeID); fatalError("countdown must throw") } catch {
        requireLinuxUnavailable(error)
    }

    let attributes = AlarmAttributes(
        presentation: makePresentation(),
        metadata: ProbeMetadata(label: "x"),
        tintColor: .primary
    )
    let configuration = AlarmManager.AlarmConfiguration(
        attributes: attributes,
        sound: .default
    )
    runBlocking {
        do {
            _ = try await AlarmManager.shared.schedule(id: probeID, configuration: configuration)
            fatalError("ALARMKIT_AGENT_RUNTIME_FAIL: schedule must throw")
        } catch {
            requireLinuxUnavailable(error)
        }
        let state = try await AlarmManager.shared.requestAuthorization()
        expectEqual(state, .denied, "requestAuthorization returns denied")
        expectEqual(AlarmManager.shared.authorizationState, .denied, "stored denied")
    }

    runBlocking {
        var alarmIterator = AlarmManager.AlarmUpdates().makeAsyncIterator()
        let alarmElement: [Alarm]? = await alarmIterator.next()
        expect(alarmElement == nil, "alarmUpdates is empty")
        var authIterator = AlarmManager.AlarmAuthorizationStateUpdates().makeAsyncIterator()
        let authElement: AlarmManager.AuthorizationState? = await authIterator.next()
        expect(authElement == nil, "authorizationUpdates is empty")

        var opaqueAlarm = AlarmManager.shared.alarmUpdates.makeAsyncIterator()
        let opaqueAlarmElement: [Alarm]? = try await opaqueAlarm.next()
        expect(opaqueAlarmElement == nil, "opaque alarmUpdates is empty")
        var opaqueAuth = AlarmManager.shared.authorizationUpdates.makeAsyncIterator()
        let opaqueAuthElement: AlarmManager.AuthorizationState? = try await opaqueAuth.next()
        expect(opaqueAuthElement == nil, "opaque authorizationUpdates is empty")
    }

    let limit = AlarmManager.AlarmError.maximumLimitReached
    expect(limit == .maximumLimitReached, "error ==")
    expect(!(limit != .maximumLimitReached), "error !=")
    _ = limit.hashValue
    var hasher = Hasher()
    limit.hash(into: &hasher)
    _ = limit.localizedDescription
    let _: any Error = limit

    _ = AlarmManager.AuthorizationState.authorized
    expect(AlarmManager.AuthorizationState.denied != .authorized, "auth !=")
    expectEqual(
        try roundTrip(AlarmManager.AuthorizationState.notDetermined),
        .notDetermined,
        "auth round-trip"
    )
    _ = AlarmManager.AuthorizationState.denied.hashValue
}

do {
    try proveCountdownDuration()
    try proveSchedule()
    try proveState()
    try proveAlarmCodable()
    try proveButtonsAndPresentation()
    try provePresentationState()
    try proveAttributesAndConfiguration()
    try proveManagerFailClosed()
} catch {
    fatalError("ALARMKIT_AGENT_RUNTIME_FAIL: \(error)")
}

print("ALARMKIT_AGENT_RUNTIME_OK")
