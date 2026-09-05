import Foundation
import AlarmKit

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
