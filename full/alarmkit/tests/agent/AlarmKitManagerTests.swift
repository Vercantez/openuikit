import Foundation
import AlarmKit

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
