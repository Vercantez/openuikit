@_spi(OpenIntentsHost) import Intents

private final class ProbeIntent: INIntent, @unchecked Sendable {}

@main
struct IntentsRuntimeProbe {
    static func main() {
        INVoiceShortcutCenter.shared.removeAll()

        let intent = ProbeIntent()
        intent.suggestedInvocationPhrase = "Erase"
        let shortcut = INShortcut(intent: intent)
        let installed = INVoiceShortcutCenter.shared.install(
            shortcut,
            invocationPhrase: "Erase"
        )

        var observed: [INVoiceShortcut] = []
        var observedError: Error?
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { values, error in
            observed = values ?? []
            observedError = error
        }
        precondition(observedError == nil)
        precondition(observed.count == 1)
        precondition(observed[0] === installed)
        precondition(observed[0].shortcut.intent === intent)

        let updated = INVoiceShortcutCenter.shared.update(
            installed,
            invocationPhrase: "Clear browsing data"
        )
        precondition(updated.identifier == installed.identifier)
        precondition(updated.invocationPhrase == "Clear browsing data")

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .outgoing
        interaction.donate()
        precondition(INInteraction.donatedInteractions.count == 1)
        precondition(INInteraction.donatedInteractions[0] === interaction)
        INInteraction.deleteAll()
        precondition(INInteraction.donatedInteractions.isEmpty)

        let resolved = INStringResolutionResult.success(with: "portable")
        precondition(resolved.outcome == .success)
        precondition(resolved.resolvedValue as? String == "portable")
        let collection = INObjectCollection(items: [intent])
        precondition(collection.items.count == 1)

        precondition(INFocusStatusCenter.default.authorizationStatus == .restricted)
        var authorization: INFocusStatusAuthorizationStatus?
        INFocusStatusCenter.default.requestAuthorization { authorization = $0 }
        precondition(authorization == .restricted)

        precondition(INVoiceShortcutCenter.shared.remove(identifier: updated.identifier))
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { values, _ in
            precondition(values?.isEmpty == true)
        }
        print("OPEN_INTENTS_RUNTIME_OK")
    }
}
