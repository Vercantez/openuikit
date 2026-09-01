#if os(macOS) || os(tvOS)
// LiveActivityIntent, AlertConfiguration, and ActivityAttributes are
// unavailable on this platform even when ActivityKit/AppIntents import.
// This probe is the future iOS/Linux identity client, not a macOS stand-in.
#elseif canImport(ActivityKit) && canImport(AppIntents) && canImport(SwiftUI) && (os(iOS) || os(watchOS) || os(visionOS) || os(Linux))
import ActivityKit
import AlarmKit
import AppIntents
import Foundation
import SwiftUI

#if os(Linux)
import Glibc
#endif

struct IdentityMetadata: AlarmMetadata {}

struct IdentityStopIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop"
    func perform() async throws -> some IntentResult {
        .result()
    }
}

func modulePrefix<T>(_ type: T.Type) -> String {
    String(reflecting: type).split(separator: ".").first.map(String.init) ?? ""
}

func acceptColor(_ color: Color) -> Color { color }
func acceptLocalized(_ resource: LocalizedStringResource) -> LocalizedStringResource {
    resource
}
func acceptSound(_ sound: AlertConfiguration.AlertSound) -> AlertConfiguration.AlertSound {
    sound
}
func acceptIntent(_ intent: any LiveActivityIntent) -> any LiveActivityIntent {
    intent
}
func acceptActivityAttributes<A: ActivityAttributes>(_ value: A) -> A.Type {
    _ = value
    return A.self
}

final class ProbeFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var firstSeen = false

    func markFirst() {
        lock.lock()
        firstSeen = true
        lock.unlock()
    }

    var sawFirst: Bool {
        lock.lock()
        defer { lock.unlock() }
        return firstSeen
    }
}

func requireKeyedEnumJSON<T: Encodable>(_ value: T) throws {
    let data = try JSONEncoder().encode(value)
    let object = try JSONSerialization.jsonObject(with: data)
    precondition(
        object is [String: Any],
        "graph-absent String raw Codable leaked: \(String(data: data, encoding: .utf8) ?? "<bin>")"
    )
}

func inspectLoadedDylib() {
#if os(Linux)
    guard let path = getenv("ALARMKIT_DYLIB").map({ String(cString: $0) }),
          !path.isEmpty
    else {
        return
    }
    guard let handle = dlopen(path, RTLD_NOW) else {
        fatalError("dlopen failed for \(path)")
    }
    defer { _ = dlclose(handle) }
    let candidates = ["$s8AlarmKit0A0VMa", "_$s8AlarmKit0A0VMa"]
    let found = candidates.contains { dlsym(handle, $0) != nil }
    precondition(found, "libAlarmKit.dylib is missing Alarm type metadata")
    let forbidden = [
        "$s8AlarmKit5ColorVMa",
        "_$s8AlarmKit5ColorVMa",
        "$s8AlarmKit23LocalizedStringResourceVMa",
        "_$s8AlarmKit23LocalizedStringResourceVMa",
        "$s8AlarmKit18ActivityAttributesPMa",
        "_$s8AlarmKit18ActivityAttributesPMa",
        "$s8AlarmKit18AlertConfigurationVMa",
        "_$s8AlarmKit18AlertConfigurationVMa",
        "$s8AlarmKit18LiveActivityIntentPMa",
        "_$s8AlarmKit18LiveActivityIntentPMa",
    ]
    for symbol in forbidden {
        precondition(dlsym(handle, symbol) == nil, "lookalike symbol present: \(symbol)")
    }
#endif
}

func run() async throws {
    inspectLoadedDylib()

    precondition(modulePrefix(Color.self) == "SwiftUI")
    precondition(modulePrefix(SwiftUI.Color.self) == "SwiftUI")
    precondition(ObjectIdentifier(Color.self) == ObjectIdentifier(SwiftUI.Color.self))
    precondition(modulePrefix(LocalizedStringResource.self) == "Foundation")
    precondition(modulePrefix(Foundation.LocalizedStringResource.self) == "Foundation")
    precondition(
        ObjectIdentifier(LocalizedStringResource.self)
            == ObjectIdentifier(Foundation.LocalizedStringResource.self)
    )
    precondition(modulePrefix(AlertConfiguration.self) == "ActivityKit")
    precondition(modulePrefix(ActivityKit.AlertConfiguration.self) == "ActivityKit")
    precondition(modulePrefix(Alarm.self) == "AlarmKit")
    precondition(String(reflecting: LiveActivityIntent.self).hasPrefix("AppIntents"))
    precondition(String(reflecting: ActivityAttributes.self).hasPrefix("ActivityKit"))
    precondition(!String(reflecting: Color.self).hasPrefix("AlarmKit"))
    precondition(!String(reflecting: LocalizedStringResource.self).hasPrefix("AlarmKit"))
    precondition(!String(reflecting: AlertConfiguration.self).hasPrefix("AlarmKit"))

    let color = acceptColor(.red)
    let title = acceptLocalized("Identity title")
    let sound = acceptSound(.default)
    let intent = acceptIntent(IdentityStopIntent())
    _ = sound
    _ = intent

    let stop = AlarmButton(
        text: title,
        textColor: color,
        systemImageName: "stop"
    )
    let pause = AlarmButton(
        text: acceptLocalized("Pause"),
        textColor: color,
        systemImageName: "pause"
    )
    let resume = AlarmButton(
        text: acceptLocalized("Resume"),
        textColor: color,
        systemImageName: "play"
    )
    let alert = AlarmPresentation.Alert(
        title: title,
        stopButton: stop,
        secondaryButton: pause,
        secondaryButtonBehavior: .custom
    )
    let countdown = AlarmPresentation.Countdown(title: title, pauseButton: pause)
    let paused = AlarmPresentation.Paused(title: title, resumeButton: resume)
    let presentation = AlarmPresentation(
        alert: alert,
        countdown: countdown,
        paused: paused
    )
    let attributes = AlarmAttributes(
        presentation: presentation,
        metadata: IdentityMetadata(),
        tintColor: color
    )
    precondition(acceptActivityAttributes(attributes) == AlarmAttributes<IdentityMetadata>.self)
    let _: AlarmAttributes<IdentityMetadata>.ContentState.Type = AlarmPresentationState.self

    let configuration = AlarmManager.AlarmConfiguration(
        countdownDuration: Alarm.CountdownDuration(preAlert: 15, postAlert: nil),
        schedule: .relative(
            .init(time: .init(hour: 7, minute: 0), repeats: .never)
        ),
        attributes: attributes,
        stopIntent: IdentityStopIntent(),
        secondaryIntent: nil,
        sound: .default
    )
    _ = AlarmManager.AlarmConfiguration<IdentityMetadata>.alarm(
        schedule: .fixed(Date(timeIntervalSince1970: 0)),
        attributes: attributes,
        stopIntent: IdentityStopIntent(),
        sound: .default
    )
    _ = configuration

    do {
        _ = try JSONEncoder().encode(stop)
        fatalError("AlarmButton Color encoding is unobserved and must fail closed")
    } catch {
        _ = error
    }
    do {
        _ = try JSONEncoder().encode(presentation)
        fatalError("AlarmPresentation Color encoding is unobserved and must fail closed")
    } catch {
        _ = error
    }
    do {
        _ = try JSONEncoder().encode(attributes)
        fatalError("AlarmAttributes Color encoding is unobserved and must fail closed")
    } catch {
        _ = error
    }

    do {
        _ = try await AlarmManager.shared.schedule(
            id: UUID(),
            configuration: configuration
        )
        fatalError("schedule must not invent daemon success")
    } catch {
        _ = error
    }

    try requireKeyedEnumJSON(Alarm.State.scheduled)
    try requireKeyedEnumJSON(AlarmManager.AuthorizationState.notDetermined)
    try requireKeyedEnumJSON(AlarmPresentation.Alert.SecondaryButtonBehavior.countdown)
    requireEqualBehavior()

    let encodedState = try JSONEncoder().encode(Alarm.State.alerting)
    let decodedState = try JSONDecoder().decode(Alarm.State.self, from: encodedState)
    precondition(decodedState == .alerting)
    requireEqual(
        try JSONDecoder().decode(
            AlarmPresentation.Alert.SecondaryButtonBehavior.self,
            from: try JSONEncoder().encode(AlarmPresentation.Alert.SecondaryButtonBehavior.custom)
        ),
        .custom
    )

    let firstFlag = ProbeFlag()
    let pending = Task {
        var iterator = AlarmManager.shared.authorizationUpdates.makeAsyncIterator()
        let first = await iterator.next()
        precondition(first == .notDetermined)
        firstFlag.markFirst()
        return await iterator.next()
    }
    var spins = 0
    while !firstFlag.sawFirst && spins < 400 {
        try await Task.sleep(nanoseconds: 1_000_000)
        spins += 1
    }
    precondition(firstFlag.sawFirst)
    try await Task.sleep(nanoseconds: 20_000_000)
    pending.cancel()
    precondition(await pending.value == nil)

    print("ALARMKIT_DEPENDENCY_IDENTITY_OK")
}

func requireEqualBehavior() {
    precondition(
        AlarmPresentation.Alert.SecondaryButtonBehavior.countdown
            != .custom
    )
}

func requireEqual<T: Equatable>(_ lhs: T, _ rhs: T) {
    precondition(lhs == rhs)
}

try await run()
#else
#error("AlarmKitDependencyIdentity.swift requires ActivityKit, AppIntents, Foundation, and SwiftUI with LiveActivityIntent, AlertConfiguration, and ActivityAttributes actually available")
#endif
