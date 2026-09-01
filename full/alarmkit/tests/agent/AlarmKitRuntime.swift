import AlarmKit
import Foundation

struct EmptyAlarmMetadata: AlarmMetadata {}

struct StopAlarmIntent: LiveActivityIntent {}

func requireUnavailable(_ error: Error) {
    guard error is AlarmKitUnavailableError else {
        fatalError("expected AlarmKitUnavailableError, got \(error)")
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

func run() async throws {
    precondition(AlarmManager.shared === AlarmManager.shared)
    precondition(AlarmManager.shared.authorizationState == .notDetermined)
    precondition(AlarmManager.AuthorizationState.notDetermined != .denied)
    precondition(AlarmManager.AuthorizationState.denied != .authorized)
    precondition(AlarmManager.AlarmError.maximumLimitReached == .maximumLimitReached)
    var errorHasher = Hasher()
    AlarmManager.AlarmError.maximumLimitReached.hash(into: &errorHasher)
    _ = errorHasher.finalize()
    _ = AlarmManager.AlarmError.maximumLimitReached.hashValue
    precondition(!AlarmManager.AlarmError.maximumLimitReached.localizedDescription.isEmpty)

    let auth = try await AlarmManager.shared.requestAuthorization()
    precondition(auth == .denied)
    precondition(AlarmManager.shared.authorizationState == .denied)
    let authAgain = try await AlarmManager.shared.requestAuthorization()
    precondition(authAgain == .denied)
    requireEqual(try roundTrip(AlarmManager.AuthorizationState.denied), .denied)

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
        precondition(state == state)
        _ = state.hashValue
        var stateHasher = Hasher()
        state.hash(into: &stateHasher)
    }
    precondition(Alarm.State.scheduled != .alerting)

    let stop = AlarmButton(
        text: "Done",
        textColor: Color.white,
        systemImageName: "checkmark"
    )
    precondition(stop.systemImageName == "checkmark")
    precondition(stop.text.key == "Done")
    let snooze = AlarmButton(
        text: "Snooze",
        textColor: Color.pink,
        systemImageName: "bell.slash"
    )
    let decodedStop = try roundTrip(stop)
    precondition(decodedStop.systemImageName == "checkmark")
    precondition(decodedStop.textColor == Color.white)

    let alert = AlarmPresentation.Alert(
        title: "Eggs are ready!",
        stopButton: stop,
        secondaryButton: snooze,
        secondaryButtonBehavior: .countdown
    )
    precondition(alert.title.key == "Eggs are ready!")
    precondition(alert.stopButton.systemImageName == "checkmark")
    precondition(alert.secondaryButton?.systemImageName == "bell.slash")
    precondition(alert.secondaryButtonBehavior == .countdown)
    precondition(
        AlarmPresentation.Alert.SecondaryButtonBehavior.countdown != .custom
    )
    _ = AlarmPresentation.Alert.SecondaryButtonBehavior.custom.hashValue
    let defaultStopAlert = AlarmPresentation.Alert(title: "Timer")
    precondition(defaultStopAlert.stopButton.systemImageName == "stop.circle.fill")
    requireEqual(try roundTrip(alert.secondaryButtonBehavior), .countdown)

    let countdownPresentation = AlarmPresentation.Countdown(
        title: "Cooking",
        pauseButton: AlarmButton(
            text: "Pause",
            textColor: Color.blue,
            systemImageName: "pause"
        )
    )
    let pausedPresentation = AlarmPresentation.Paused(
        title: "Paused",
        resumeButton: AlarmButton(
            text: "Resume",
            textColor: Color.green,
            systemImageName: "play"
        )
    )
    let presentation = AlarmPresentation(
        alert: alert,
        countdown: countdownPresentation,
        paused: pausedPresentation
    )
    precondition(presentation.alert.title.key == "Eggs are ready!")
    precondition(presentation.countdown?.title.key == "Cooking")
    precondition(presentation.paused?.title.key == "Paused")
    let decodedPresentation = try roundTrip(presentation)
    precondition(decodedPresentation.alert.stopButton.systemImageName == "checkmark")

    let attributes = AlarmAttributes(
        presentation: presentation,
        metadata: EmptyAlarmMetadata(),
        tintColor: Color.indigo
    )
    precondition(attributes.tintColor == Color.indigo)
    precondition(attributes.metadata != nil)
    let decodedAttributes = try roundTrip(attributes)
    precondition(decodedAttributes.tintColor == Color.indigo)
    let _: AlarmAttributes<EmptyAlarmMetadata>.ContentState.Type =
        AlarmPresentationState.self

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

    let alarmID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    let alarmJSON = Data(
        """
        {"id":"\(alarmID.uuidString)","state":"scheduled","schedule":null}
        """.utf8
    )
    let alarm = try JSONDecoder().decode(Alarm.self, from: alarmJSON)
    precondition(alarm.id == alarmID)
    precondition(alarm.state == .scheduled)
    precondition(alarm.schedule == nil)
    precondition(alarm.countdownDuration == nil)
    let encodedAlarm = try JSONEncoder().encode(alarm)
    let decodedAlarm = try JSONDecoder().decode(Alarm.self, from: encodedAlarm)
    precondition(decodedAlarm.id == alarm.id)
    precondition(decodedAlarm.state == .scheduled)

    let configuration = AlarmManager.AlarmConfiguration(
        countdownDuration: duration,
        schedule: relativeSchedule,
        attributes: attributes,
        stopIntent: StopAlarmIntent(),
        secondaryIntent: nil,
        sound: .default
    )
    let alarmConfiguration = AlarmManager.AlarmConfiguration<EmptyAlarmMetadata>.alarm(
        schedule: fixed,
        attributes: attributes,
        sound: .named("custom-tone")
    )
    let timerConfiguration = AlarmManager.AlarmConfiguration<EmptyAlarmMetadata>.timer(
        duration: 90,
        attributes: attributes,
        sound: .silent
    )
    _ = alarmConfiguration
    _ = timerConfiguration
    precondition(AlertConfiguration.AlertSound.default != .silent)

    do {
        _ = try await AlarmManager.shared.schedule(
            id: alarmID,
            configuration: configuration
        )
        fatalError("schedule must fail closed")
    } catch {
        requireUnavailable(error)
    }

    do {
        _ = try AlarmManager.shared.alarms
        fatalError("alarms must fail closed")
    } catch {
        requireUnavailable(error)
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
            requireUnavailable(error)
        }
    }

    var updateCount = 0
    for await snapshot in AlarmManager.shared.alarmUpdates {
        updateCount += 1
        precondition(snapshot.isEmpty)
    }
    precondition(updateCount == 1)

    var authCount = 0
    for await state in AlarmManager.shared.authorizationUpdates {
        authCount += 1
        precondition(state == .denied)
    }
    precondition(authCount == 1)

    let prefixEmpty = AlarmManager.shared.alarmUpdates.prefix(1)
    var prefixCount = 0
    for await _ in prefixEmpty {
        prefixCount += 1
    }
    precondition(prefixCount == 1)

    print("ALARMKIT_AGENT_RUNTIME_OK")
}

try await run()
