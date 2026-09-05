import Foundation
import AlarmKit

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
