import Foundation
import AlarmKit

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
