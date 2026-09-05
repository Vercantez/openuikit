@_spi(OpenUIKitHost) import IntentsUI
import Foundation

/// Schema-v2 host gate compiles `*Tests.swift` and a generated runner, not this
/// file. Keep it as a standalone probe of the host-driven shortcut controllers.

private func intentsUIRuntimeOnMain(_ work: @escaping @Sendable @MainActor () -> Void) {
    if Thread.isMainThread {
        MainActor.assumeIsolated(work)
        return
    }
    DispatchQueue.main.sync {
        MainActor.assumeIsolated(work)
    }
}

func intentsUIRuntimeProbe() {
    precondition(INUIAddVoiceShortcutButtonStyle.white.rawValue == 0)
    precondition(INUIAddVoiceShortcutButtonStyle.automaticOutline.rawValue == 5)
    precondition(INUIHostedViewContext.siriSnippet.rawValue == 0)
    precondition(INUIInteractiveBehavior.none.rawValue == 0)
    precondition(
        INUIAddVoiceShortcutViewController.presentationCapability == .hostDriven
    )
    precondition(
        INUIEditVoiceShortcutViewController.presentationCapability == .hostDriven
    )

    intentsUIRuntimeOnMain {
        IntentsUIHostControl.resetVoiceShortcuts()
        let shortcut = INShortcut()
        let add = INUIAddVoiceShortcutViewController(shortcut: shortcut)
        precondition(add.shortcut === shortcut)

        let button = INUIAddVoiceShortcutButton(style: .black)
        button.setStyle(.white)
        precondition(button.style == .white)
        button.cornerRadius = 8
        precondition(button.cornerRadius == 8)

        precondition(INUIVoiceShortcutError.emptyInvocationPhrase != .shortcutNotFound)
    }

    print("INTENTSUI_AGENT_RUNTIME_OK")
}

intentsUIRuntimeProbe()
