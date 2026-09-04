@_spi(OpenUIKitHost) import IntentsUI
import Foundation

private func intentsUIOnMain(_ work: @escaping @Sendable @MainActor () -> Void) {
    if Thread.isMainThread {
        MainActor.assumeIsolated(work)
        return
    }
    DispatchQueue.main.sync {
        MainActor.assumeIsolated(work)
    }
}

private final class AddFinishProbe: NSObject, INUIAddVoiceShortcutViewControllerDelegate, @unchecked Sendable {
    var voiceShortcut: INVoiceShortcut?
    var error: (any Error)?
    var cancelled = false

    func addVoiceShortcutViewController(
        _ controller: INUIAddVoiceShortcutViewController,
        didFinishWith voiceShortcut: INVoiceShortcut?,
        error: (any Error)?
    ) {
        _ = controller
        self.voiceShortcut = voiceShortcut
        self.error = error
    }

    func addVoiceShortcutViewControllerDidCancel(
        _ controller: INUIAddVoiceShortcutViewController
    ) {
        _ = controller
        cancelled = true
    }
}

private final class EditFinishProbe: NSObject, INUIEditVoiceShortcutViewControllerDelegate, @unchecked Sendable {
    var updated: INVoiceShortcut?
    var error: (any Error)?
    var deletedIdentifier: UUID?
    var cancelled = false

    func editVoiceShortcutViewController(
        _ controller: INUIEditVoiceShortcutViewController,
        didUpdate voiceShortcut: INVoiceShortcut?,
        error: (any Error)?
    ) {
        _ = controller
        updated = voiceShortcut
        self.error = error
    }

    func editVoiceShortcutViewController(
        _ controller: INUIEditVoiceShortcutViewController,
        didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID
    ) {
        _ = controller
        deletedIdentifier = deletedVoiceShortcutIdentifier
    }

    func editVoiceShortcutViewControllerDidCancel(
        _ controller: INUIEditVoiceShortcutViewController
    ) {
        _ = controller
        cancelled = true
    }
}

private final class ButtonPresentProbe: NSObject, INUIAddVoiceShortcutButtonDelegate, @unchecked Sendable {
    var addController: INUIAddVoiceShortcutViewController?
    var editController: INUIEditVoiceShortcutViewController?
    var addButton: INUIAddVoiceShortcutButton?
    var editButton: INUIAddVoiceShortcutButton?

    func present(
        _ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController,
        for addVoiceShortcutButton: INUIAddVoiceShortcutButton
    ) {
        addController = addVoiceShortcutViewController
        addButton = addVoiceShortcutButton
    }

    func present(
        _ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController,
        for addVoiceShortcutButton: INUIAddVoiceShortcutButton
    ) {
        editController = editVoiceShortcutViewController
        editButton = addVoiceShortcutButton
    }
}

@MainActor
private final class DefaultSiriHints: NSObject, INUIHostedViewSiriProviding {}

@MainActor
private final class MapSiriHints: NSObject, INUIHostedViewSiriProviding {
    var displaysMap: Bool { true }
}

@MainActor
private final class HostedViewStub: NSObject, INUIHostedViewControlling {}

func testAddVoiceShortcutButtonStyleRawValues() {
    precondition(INUIAddVoiceShortcutButtonStyle.white.rawValue == 0)
    precondition(INUIAddVoiceShortcutButtonStyle.whiteOutline.rawValue == 1)
    precondition(INUIAddVoiceShortcutButtonStyle.black.rawValue == 2)
    precondition(INUIAddVoiceShortcutButtonStyle.blackOutline.rawValue == 3)
    precondition(INUIAddVoiceShortcutButtonStyle.automatic.rawValue == 4)
    precondition(INUIAddVoiceShortcutButtonStyle.automaticOutline.rawValue == 5)
    precondition(INUIAddVoiceShortcutButtonStyle(rawValue: 0) == .white)
    precondition(INUIAddVoiceShortcutButtonStyle(rawValue: 1) == .whiteOutline)
    precondition(INUIAddVoiceShortcutButtonStyle(rawValue: 2) == .black)
    precondition(INUIAddVoiceShortcutButtonStyle(rawValue: 3) == .blackOutline)
    precondition(INUIAddVoiceShortcutButtonStyle(rawValue: 4) == .automatic)
    precondition(INUIAddVoiceShortcutButtonStyle(rawValue: 5) == .automaticOutline)
    precondition(INUIAddVoiceShortcutButtonStyle(rawValue: 6) == nil)
    precondition(INUIAddVoiceShortcutButtonStyle.white != .black)
    precondition(
        INUIAddVoiceShortcutButtonStyle.automatic.hashValue
            == INUIAddVoiceShortcutButtonStyle.automatic.hashValue
    )
    var hasher = Hasher()
    INUIAddVoiceShortcutButtonStyle.blackOutline.hash(into: &hasher)
    _ = hasher.finalize()
}

func testHostedViewContextRawValues() {
    precondition(INUIHostedViewContext.siriSnippet.rawValue == 0)
    precondition(INUIHostedViewContext.mapsCard.rawValue == 1)
    precondition(INUIHostedViewContext(rawValue: 0) == .siriSnippet)
    precondition(INUIHostedViewContext(rawValue: 1) == .mapsCard)
    precondition(INUIHostedViewContext(rawValue: 2) == nil)
    precondition(INUIHostedViewContext.siriSnippet != .mapsCard)
    precondition(
        INUIHostedViewContext.mapsCard.hashValue == INUIHostedViewContext.mapsCard.hashValue
    )
    var hasher = Hasher()
    INUIHostedViewContext.siriSnippet.hash(into: &hasher)
    _ = hasher.finalize()
}

func testInteractiveBehaviorRawValues() {
    precondition(INUIInteractiveBehavior.none.rawValue == 0)
    precondition(INUIInteractiveBehavior.nextView.rawValue == 1)
    precondition(INUIInteractiveBehavior.launch.rawValue == 2)
    precondition(INUIInteractiveBehavior.genericAction.rawValue == 3)
    precondition(INUIInteractiveBehavior(rawValue: 0) == INUIInteractiveBehavior.none)
    precondition(INUIInteractiveBehavior(rawValue: 1) == .nextView)
    precondition(INUIInteractiveBehavior(rawValue: 2) == .launch)
    precondition(INUIInteractiveBehavior(rawValue: 3) == .genericAction)
    precondition(INUIInteractiveBehavior(rawValue: 4) == nil)
    precondition(INUIInteractiveBehavior.none != .launch)
    precondition(
        INUIInteractiveBehavior.genericAction.hashValue
            == INUIInteractiveBehavior.genericAction.hashValue
    )
    var hasher = Hasher()
    INUIInteractiveBehavior.nextView.hash(into: &hasher)
    _ = hasher.finalize()
}

func testAddButtonInitStyleAndSetStyle() {
    intentsUIOnMain {
        let button = INUIAddVoiceShortcutButton(style: .white)
        precondition(button.style == .white)
        button.setStyle(.automaticOutline)
        precondition(button.style == .automaticOutline)
        button.setStyle(.black)
        precondition(button.style == .black)
    }
}

func testAddButtonCornerRadiusRoundTrip() {
    intentsUIOnMain {
        let button = INUIAddVoiceShortcutButton(style: .blackOutline)
        button.cornerRadius = 12
        precondition(button.cornerRadius == 12)
        button.cornerRadius = 0
        precondition(button.cornerRadius == 0)
    }
}

func testAddButtonShortcutIdentity() {
    intentsUIOnMain {
        let button = INUIAddVoiceShortcutButton(style: .automatic)
        precondition(button.shortcut == nil)
        let shortcut = INShortcut()
        button.shortcut = shortcut
        precondition(button.shortcut === shortcut)
        button.shortcut = nil
        precondition(button.shortcut == nil)
    }
}

func testAddButtonPresentAddRequiresShortcut() {
    intentsUIOnMain {
        let button = INUIAddVoiceShortcutButton(style: .whiteOutline)
        let probe = ButtonPresentProbe()
        button.delegate = probe
        button.presentAddVoiceShortcut()
        precondition(probe.addController == nil)
        let shortcut = INShortcut()
        button.shortcut = shortcut
        button.presentAddVoiceShortcut()
        precondition(probe.addController != nil)
        precondition(probe.addController?.shortcut === shortcut)
        precondition(probe.addButton === button)
        precondition(probe.editController == nil)
    }
}

func testAddButtonPresentEdit() {
    intentsUIOnMain {
        IntentsUIHostControl.resetVoiceShortcuts()
        let shortcut = INShortcut()
        let installed = IntentsUIHostControl.install(
            shortcut,
            invocationPhrase: "Open library"
        )
        let button = INUIAddVoiceShortcutButton(style: .black)
        let probe = ButtonPresentProbe()
        button.delegate = probe
        button.presentEditVoiceShortcut(installed)
        precondition(probe.editController != nil)
        precondition(probe.editController?.voiceShortcut.identifier == installed.identifier)
        precondition(probe.editButton === button)
        precondition(probe.addController == nil)
    }
}

func testAddVoiceShortcutFinishStoresPhrase() {
    intentsUIOnMain {
        IntentsUIHostControl.resetVoiceShortcuts()
        let shortcut = INShortcut()
        let controller = INUIAddVoiceShortcutViewController(shortcut: shortcut)
        precondition(controller.shortcut === shortcut)
        let probe = AddFinishProbe()
        controller.delegate = probe
        controller.finish(invocationPhrase: "Play podcast")
        precondition(probe.error == nil)
        precondition(probe.voiceShortcut?.invocationPhrase == "Play podcast")
        precondition(probe.voiceShortcut?.shortcut === shortcut)
        precondition(probe.cancelled == false)
    }
}

func testAddVoiceShortcutEmptyPhraseFailsClosed() {
    intentsUIOnMain {
        IntentsUIHostControl.resetVoiceShortcuts()
        let controller = INUIAddVoiceShortcutViewController(shortcut: INShortcut())
        let probe = AddFinishProbe()
        controller.delegate = probe
        controller.finish(invocationPhrase: "   \t")
        precondition(probe.voiceShortcut == nil)
        let typed = probe.error as? INUIVoiceShortcutError
        precondition(typed == .emptyInvocationPhrase)
        controller.finish(invocationPhrase: "")
        precondition((probe.error as? INUIVoiceShortcutError) == .emptyInvocationPhrase)
    }
}

func testAddVoiceShortcutCancel() {
    intentsUIOnMain {
        let controller = INUIAddVoiceShortcutViewController(shortcut: INShortcut())
        let probe = AddFinishProbe()
        controller.delegate = probe
        controller.cancel()
        precondition(probe.cancelled)
        precondition(probe.voiceShortcut == nil)
        precondition(probe.error == nil)
    }
}

func testEditVoiceShortcutUpdateAndDelete() {
    intentsUIOnMain {
        IntentsUIHostControl.resetVoiceShortcuts()
        let shortcut = INShortcut()
        let installed = IntentsUIHostControl.install(
            shortcut,
            invocationPhrase: "Original phrase"
        )
        let controller = INUIEditVoiceShortcutViewController(voiceShortcut: installed)
        let probe = EditFinishProbe()
        controller.delegate = probe
        controller.finish(invocationPhrase: "Updated phrase")
        precondition(probe.error == nil)
        precondition(probe.updated?.invocationPhrase == "Updated phrase")
        precondition(probe.updated?.identifier == installed.identifier)
        precondition(controller.voiceShortcut.invocationPhrase == "Updated phrase")

        controller.delete()
        precondition(probe.deletedIdentifier == installed.identifier)

        controller.delete()
        precondition((probe.error as? INUIVoiceShortcutError) == .shortcutNotFound)
        precondition(probe.updated == nil)
    }
}

func testEditVoiceShortcutEmptyPhraseAndCancel() {
    intentsUIOnMain {
        IntentsUIHostControl.resetVoiceShortcuts()
        let installed = IntentsUIHostControl.install(
            INShortcut(),
            invocationPhrase: "Keep me"
        )
        let controller = INUIEditVoiceShortcutViewController(voiceShortcut: installed)
        let probe = EditFinishProbe()
        controller.delegate = probe
        controller.finish(invocationPhrase: " ")
        precondition(probe.updated == nil)
        precondition((probe.error as? INUIVoiceShortcutError) == .emptyInvocationPhrase)
        controller.cancel()
        precondition(probe.cancelled)
    }
}

func testHostedViewSiriProvidingDefaultsAndOverride() {
    intentsUIOnMain {
        let defaults = DefaultSiriHints()
        precondition(defaults.displaysMap == false)
        precondition(defaults.displaysMessage == false)
        precondition(defaults.displaysPaymentTransaction == false)
        let map = MapSiriHints()
        precondition(map.displaysMap == true)
        precondition(map.displaysMessage == false)
        _ = HostedViewStub()
    }
}
