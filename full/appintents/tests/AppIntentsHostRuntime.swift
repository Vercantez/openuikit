import AppIntents

private struct EchoIntent: AppIntent {
    let value: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "echo=\(value)")
    }
}

private struct ShortcutCatalog: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: EchoIntent(value: "one"),
            phrases: ["Echo with \(.applicationName)"],
            shortTitle: "Echo",
            systemImageName: "waveform"
        )
        AppShortcut(
            intent: EchoIntent(value: "two"),
            phrases: ["Repeat with \(.applicationName)"],
            shortTitle: "Repeat",
            systemImageName: "repeat"
        )
    }
}

@main
private struct AppIntentsHostRuntime {
    static func main() async throws {
        let result = try await AppIntentRuntime.shared.perform(
            EchoIntent(value: "portable")
        )
        precondition(
            (result as? IntentResultValue)?.dialog?.text == "echo=portable"
        )
        let executionCount = await AppIntentRuntime.shared.executionCount
        precondition(executionCount == 1)
        precondition(ShortcutCatalog.appShortcuts.count == 2)
        precondition(
            ShortcutCatalog.appShortcuts[0].phrases[0].template ==
                "Echo with ${applicationName}"
        )
        precondition(!AppIntentsPortable.supportsSystemRegistration)
        print(
            "APPINTENTS_HOST_RUNTIME_OK execution=1 shortcuts=2 " +
            "system-registration=unavailable"
        )
    }
}
