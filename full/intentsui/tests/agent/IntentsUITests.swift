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
    var finishCount = 0
    var cancelCount = 0

    func addVoiceShortcutViewController(
        _ controller: INUIAddVoiceShortcutViewController,
        didFinishWith voiceShortcut: INVoiceShortcut?,
        error: (any Error)?
    ) {
        _ = controller
        self.voiceShortcut = voiceShortcut
        self.error = error
        finishCount += 1
    }

    func addVoiceShortcutViewControllerDidCancel(
        _ controller: INUIAddVoiceShortcutViewController
    ) {
        _ = controller
        cancelled = true
        cancelCount += 1
    }
}

private final class EditFinishProbe: NSObject, INUIEditVoiceShortcutViewControllerDelegate, @unchecked Sendable {
    var updated: INVoiceShortcut?
    var error: (any Error)?
    var deletedIdentifier: UUID?
    var cancelled = false
    var updateCount = 0
    var deleteCount = 0
    var cancelCount = 0

    func editVoiceShortcutViewController(
        _ controller: INUIEditVoiceShortcutViewController,
        didUpdate voiceShortcut: INVoiceShortcut?,
        error: (any Error)?
    ) {
        _ = controller
        updated = voiceShortcut
        self.error = error
        updateCount += 1
    }

    func editVoiceShortcutViewController(
        _ controller: INUIEditVoiceShortcutViewController,
        didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID
    ) {
        _ = controller
        deletedIdentifier = deletedVoiceShortcutIdentifier
        deleteCount += 1
    }

    func editVoiceShortcutViewControllerDidCancel(
        _ controller: INUIEditVoiceShortcutViewController
    ) {
        _ = controller
        cancelled = true
        cancelCount += 1
    }
}

private final class ButtonPresentProbe: NSObject, INUIAddVoiceShortcutButtonDelegate, @unchecked Sendable {
    var addController: INUIAddVoiceShortcutViewController?
    var editController: INUIEditVoiceShortcutViewController?
    var addButton: INUIAddVoiceShortcutButton?
    var editButton: INUIAddVoiceShortcutButton?
    var addPresentCount = 0
    var editPresentCount = 0

    func present(
        _ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController,
        for addVoiceShortcutButton: INUIAddVoiceShortcutButton
    ) {
        addController = addVoiceShortcutViewController
        addButton = addVoiceShortcutButton
        addPresentCount += 1
    }

    func present(
        _ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController,
        for addVoiceShortcutButton: INUIAddVoiceShortcutButton
    ) {
        editController = editVoiceShortcutViewController
        editButton = addVoiceShortcutButton
        editPresentCount += 1
    }
}

@MainActor
private final class DefaultSiriHints: NSObject, INUIHostedViewSiriProviding {}

@MainActor
private final class MapSiriHints: NSObject, INUIHostedViewSiriProviding {
    var displaysMap: Bool { true }
}

@MainActor
private final class MessageSiriHints: NSObject, INUIHostedViewSiriProviding {
    var displaysMessage: Bool { true }
}

@MainActor
private final class PaymentSiriHints: NSObject, INUIHostedViewSiriProviding {
    var displaysPaymentTransaction: Bool { true }
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
    precondition(INUIAddVoiceShortcutButtonStyle.whiteOutline != .blackOutline)
    precondition(INUIAddVoiceShortcutButtonStyle.automatic != .automaticOutline)
    precondition(
        INUIAddVoiceShortcutButtonStyle.automatic.hashValue
            == INUIAddVoiceShortcutButtonStyle.automatic.hashValue
    )
    precondition(
        INUIAddVoiceShortcutButtonStyle.white.hashValue
            != INUIAddVoiceShortcutButtonStyle.black.hashValue
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
    precondition(
        INUIHostedViewContext.siriSnippet.hashValue != INUIHostedViewContext.mapsCard.hashValue
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
    precondition(INUIInteractiveBehavior.nextView != .genericAction)
    precondition(
        INUIInteractiveBehavior.genericAction.hashValue
            == INUIInteractiveBehavior.genericAction.hashValue
    )
    precondition(
        INUIInteractiveBehavior.none.hashValue != INUIInteractiveBehavior.launch.hashValue
    )
    var hasher = Hasher()
    INUIInteractiveBehavior.nextView.hash(into: &hasher)
    _ = hasher.finalize()
}

func testAddVoiceShortcutButtonClass() {
    intentsUIOnMain {
        let button = INUIAddVoiceShortcutButton(style: .white)
        precondition(type(of: button) == INUIAddVoiceShortcutButton.self)
        precondition(ObjectIdentifier(button as AnyObject) != ObjectIdentifier(NSObject()))
        precondition(
            INUIAddVoiceShortcutViewController.presentationCapability == .hostDriven
        )
    }
}

func testAddVoiceShortcutButtonInitStyle() {
    intentsUIOnMain {
        let white = INUIAddVoiceShortcutButton(style: .white)
        precondition(white.style == .white)
        let outline = INUIAddVoiceShortcutButton(style: .automaticOutline)
        precondition(outline.style == .automaticOutline)
        let black = INUIAddVoiceShortcutButton(style: .black)
        precondition(black.style == .black)
    }
}

func testAddVoiceShortcutButtonSetStyle() {
    intentsUIOnMain {
        let button = INUIAddVoiceShortcutButton(style: .white)
        button.setStyle(.automaticOutline)
        precondition(button.style == .automaticOutline)
        button.setStyle(.black)
        precondition(button.style == .black)
        button.setStyle(.whiteOutline)
        precondition(button.style == .whiteOutline)
    }
}

func testAddVoiceShortcutButtonStyleGet() {
    intentsUIOnMain {
        let button = INUIAddVoiceShortcutButton(style: .blackOutline)
        precondition(button.style == .blackOutline)
        button.setStyle(.automatic)
        precondition(button.style == .automatic)
    }
}

func testAddVoiceShortcutButtonCornerRadius() {
    intentsUIOnMain {
        let button = INUIAddVoiceShortcutButton(style: .blackOutline)
        precondition(button.cornerRadius == 0)
        button.cornerRadius = 12
        precondition(button.cornerRadius == 12)
        button.cornerRadius = 0
        precondition(button.cornerRadius == 0)
        button.cornerRadius = 3.5
        precondition(button.cornerRadius == 3.5)
    }
}

func testAddVoiceShortcutButtonDelegateIdentity() {
    intentsUIOnMain {
        let button = INUIAddVoiceShortcutButton(style: .white)
        precondition(button.delegate == nil)
        let probe = ButtonPresentProbe()
        button.delegate = probe
        precondition(button.delegate === probe)
        button.delegate = nil
        precondition(button.delegate == nil)

        var owned: ButtonPresentProbe? = ButtonPresentProbe()
        button.delegate = owned
        weak let weakProbe = owned
        precondition(weakProbe != nil)
        owned = nil
        precondition(weakProbe == nil)
        precondition(button.delegate == nil)
    }
}

func testAddVoiceShortcutButtonShortcutIdentity() {
    intentsUIOnMain {
        let button = INUIAddVoiceShortcutButton(style: .automatic)
        precondition(button.shortcut == nil)
        let shortcut = INShortcut()
        button.shortcut = shortcut
        precondition(button.shortcut === shortcut)
        let other = INShortcut()
        button.shortcut = other
        precondition(button.shortcut === other)
        precondition(button.shortcut !== shortcut)
        button.shortcut = nil
        precondition(button.shortcut == nil)
    }
}

func testAddVoiceShortcutButtonDelegateProtocol() {
    intentsUIOnMain {
        let button = INUIAddVoiceShortcutButton(style: .whiteOutline)
        let probe: any INUIAddVoiceShortcutButtonDelegate = ButtonPresentProbe()
        button.delegate = probe
        precondition(button.delegate === probe as AnyObject)
        let shortcut = INShortcut()
        button.shortcut = shortcut
        button.presentAddVoiceShortcut()
        let typed = probe as! ButtonPresentProbe
        precondition(typed.addPresentCount == 1)
        precondition(typed.addController?.shortcut === shortcut)
    }
}

func testAddButtonPresentAddRequiresShortcut() {
    intentsUIOnMain {
        let button = INUIAddVoiceShortcutButton(style: .whiteOutline)
        let probe = ButtonPresentProbe()
        button.delegate = probe
        button.presentAddVoiceShortcut()
        precondition(probe.addController == nil)
        precondition(probe.addPresentCount == 0)
        precondition(probe.editPresentCount == 0)
        let shortcut = INShortcut()
        button.shortcut = shortcut
        button.presentAddVoiceShortcut()
        precondition(probe.addController != nil)
        precondition(probe.addController?.shortcut === shortcut)
        precondition(probe.addButton === button)
        precondition(probe.addPresentCount == 1)
        precondition(probe.editController == nil)
        precondition(probe.editPresentCount == 0)
        button.presentAddVoiceShortcut()
        precondition(probe.addPresentCount == 2)
        button.shortcut = nil
        button.presentAddVoiceShortcut()
        precondition(probe.addPresentCount == 2)
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
        precondition(probe.editPresentCount == 1)
        precondition(probe.addController == nil)
        precondition(probe.addPresentCount == 0)
    }
}

func testAddVoiceShortcutViewControllerClass() {
    intentsUIOnMain {
        IntentsUIHostControl.resetVoiceShortcuts()
        let controller = INUIAddVoiceShortcutViewController(shortcut: INShortcut())
        precondition(type(of: controller) == INUIAddVoiceShortcutViewController.self)
        precondition(
            INUIAddVoiceShortcutViewController.presentationCapability == .hostDriven
        )
    }
}

func testAddVoiceShortcutViewControllerInit() {
    intentsUIOnMain {
        IntentsUIHostControl.resetVoiceShortcuts()
        let shortcut = INShortcut()
        let controller = INUIAddVoiceShortcutViewController(shortcut: shortcut)
        precondition(controller.shortcut === shortcut)
        let other = INUIAddVoiceShortcutViewController(shortcut: shortcut)
        precondition(other.shortcut === shortcut)
        precondition(controller !== other)
    }
}

func testAddVoiceShortcutViewControllerDelegateIdentity() {
    intentsUIOnMain {
        let controller = INUIAddVoiceShortcutViewController(shortcut: INShortcut())
        precondition(controller.delegate == nil)
        let probe = AddFinishProbe()
        controller.delegate = probe
        precondition(controller.delegate === probe)
        controller.delegate = nil
        precondition(controller.delegate == nil)

        var owned: AddFinishProbe? = AddFinishProbe()
        controller.delegate = owned
        weak let weakProbe = owned
        owned = nil
        precondition(weakProbe == nil)
        precondition(controller.delegate == nil)
    }
}

func testAddVoiceShortcutViewControllerDelegateProtocol() {
    intentsUIOnMain {
        IntentsUIHostControl.resetVoiceShortcuts()
        let controller = INUIAddVoiceShortcutViewController(shortcut: INShortcut())
        let probe: any INUIAddVoiceShortcutViewControllerDelegate = AddFinishProbe()
        controller.delegate = probe
        controller.finish(invocationPhrase: "Protocol finish")
        let typed = probe as! AddFinishProbe
        precondition(typed.finishCount == 1)
        precondition(typed.voiceShortcut?.invocationPhrase == "Protocol finish")
        precondition(typed.error == nil)
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
        precondition(probe.finishCount == 1)
        let identifier = probe.voiceShortcut!.identifier
        precondition(IntentsUIHostControl.voiceShortcut(identifier: identifier)?.invocationPhrase == "Play podcast")

        controller.finish(invocationPhrase: "   \t")
        precondition(probe.voiceShortcut == nil)
        precondition((probe.error as? INUIVoiceShortcutError) == .emptyInvocationPhrase)
        precondition(probe.finishCount == 2)
        precondition(IntentsUIHostControl.voiceShortcut(identifier: identifier)?.invocationPhrase == "Play podcast")

        controller.finish(invocationPhrase: "")
        precondition((probe.error as? INUIVoiceShortcutError) == .emptyInvocationPhrase)
        precondition(INUIVoiceShortcutError.emptyInvocationPhrase != .shortcutNotFound)
        precondition(
            INUIVoiceShortcutError.emptyInvocationPhrase.hashValue
                == INUIVoiceShortcutError.emptyInvocationPhrase.hashValue
        )
    }
}

func testAddVoiceShortcutCancel() {
    intentsUIOnMain {
        IntentsUIHostControl.resetVoiceShortcuts()
        let controller = INUIAddVoiceShortcutViewController(shortcut: INShortcut())
        let probe = AddFinishProbe()
        controller.delegate = probe
        controller.cancel()
        precondition(probe.cancelled)
        precondition(probe.cancelCount == 1)
        precondition(probe.voiceShortcut == nil)
        precondition(probe.error == nil)
        precondition(probe.finishCount == 0)
        controller.finish(invocationPhrase: "After cancel")
        precondition(probe.finishCount == 1)
        precondition(probe.voiceShortcut?.invocationPhrase == "After cancel")
        controller.cancel()
        precondition(probe.cancelCount == 2)
        precondition(probe.voiceShortcut?.invocationPhrase == "After cancel")
    }
}

func testEditVoiceShortcutViewControllerClass() {
    intentsUIOnMain {
        IntentsUIHostControl.resetVoiceShortcuts()
        let installed = IntentsUIHostControl.install(
            INShortcut(),
            invocationPhrase: "Class probe"
        )
        let controller = INUIEditVoiceShortcutViewController(voiceShortcut: installed)
        precondition(type(of: controller) == INUIEditVoiceShortcutViewController.self)
        precondition(
            INUIEditVoiceShortcutViewController.presentationCapability == .hostDriven
        )
    }
}

func testEditVoiceShortcutViewControllerInit() {
    intentsUIOnMain {
        IntentsUIHostControl.resetVoiceShortcuts()
        let shortcut = INShortcut()
        let installed = IntentsUIHostControl.install(
            shortcut,
            invocationPhrase: "Original phrase"
        )
        let controller = INUIEditVoiceShortcutViewController(voiceShortcut: installed)
        precondition(controller.voiceShortcut.identifier == installed.identifier)
        precondition(controller.voiceShortcut.invocationPhrase == "Original phrase")
        precondition(controller.voiceShortcut.shortcut === shortcut)
    }
}

func testEditVoiceShortcutViewControllerDelegateIdentity() {
    intentsUIOnMain {
        IntentsUIHostControl.resetVoiceShortcuts()
        let installed = IntentsUIHostControl.install(
            INShortcut(),
            invocationPhrase: "Delegate identity"
        )
        let controller = INUIEditVoiceShortcutViewController(voiceShortcut: installed)
        precondition(controller.delegate == nil)
        let probe = EditFinishProbe()
        controller.delegate = probe
        precondition(controller.delegate === probe)
        controller.delegate = nil
        precondition(controller.delegate == nil)

        var owned: EditFinishProbe? = EditFinishProbe()
        controller.delegate = owned
        weak let weakProbe = owned
        owned = nil
        precondition(weakProbe == nil)
        precondition(controller.delegate == nil)
    }
}

func testEditVoiceShortcutViewControllerDelegateProtocol() {
    intentsUIOnMain {
        IntentsUIHostControl.resetVoiceShortcuts()
        let installed = IntentsUIHostControl.install(
            INShortcut(),
            invocationPhrase: "Protocol edit"
        )
        let controller = INUIEditVoiceShortcutViewController(voiceShortcut: installed)
        let probe: any INUIEditVoiceShortcutViewControllerDelegate = EditFinishProbe()
        controller.delegate = probe
        controller.finish(invocationPhrase: "Protocol updated")
        let typed = probe as! EditFinishProbe
        precondition(typed.updateCount == 1)
        precondition(typed.updated?.invocationPhrase == "Protocol updated")
        precondition(typed.error == nil)
    }
}

func testEditVoiceShortcutUpdate() {
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
        precondition(probe.updated?.shortcut === shortcut)
        precondition(controller.voiceShortcut.invocationPhrase == "Updated phrase")
        precondition(controller.voiceShortcut.identifier == installed.identifier)
        precondition(probe.updateCount == 1)
        precondition(probe.deleteCount == 0)
        precondition(
            IntentsUIHostControl.voiceShortcut(identifier: installed.identifier)?.invocationPhrase
                == "Updated phrase"
        )

        controller.finish(invocationPhrase: " ")
        precondition(probe.updated == nil)
        precondition((probe.error as? INUIVoiceShortcutError) == .emptyInvocationPhrase)
        precondition(controller.voiceShortcut.invocationPhrase == "Updated phrase")
        precondition(
            IntentsUIHostControl.voiceShortcut(identifier: installed.identifier)?.invocationPhrase
                == "Updated phrase"
        )
    }
}

func testEditVoiceShortcutDelete() {
    intentsUIOnMain {
        IntentsUIHostControl.resetVoiceShortcuts()
        let installed = IntentsUIHostControl.install(
            INShortcut(),
            invocationPhrase: "Delete me"
        )
        let controller = INUIEditVoiceShortcutViewController(voiceShortcut: installed)
        let probe = EditFinishProbe()
        controller.delegate = probe
        controller.delete()
        precondition(probe.deletedIdentifier == installed.identifier)
        precondition(probe.deleteCount == 1)
        precondition(IntentsUIHostControl.voiceShortcut(identifier: installed.identifier) == nil)

        probe.updated = installed
        controller.delete()
        precondition((probe.error as? INUIVoiceShortcutError) == .shortcutNotFound)
        precondition(probe.updated == nil)
        precondition(probe.deleteCount == 1)
        precondition(INUIVoiceShortcutError.shortcutNotFound != .emptyInvocationPhrase)
    }
}

func testEditVoiceShortcutCancel() {
    intentsUIOnMain {
        IntentsUIHostControl.resetVoiceShortcuts()
        let installed = IntentsUIHostControl.install(
            INShortcut(),
            invocationPhrase: "Keep me"
        )
        let controller = INUIEditVoiceShortcutViewController(voiceShortcut: installed)
        let probe = EditFinishProbe()
        controller.delegate = probe
        controller.cancel()
        precondition(probe.cancelled)
        precondition(probe.cancelCount == 1)
        precondition(probe.updated == nil)
        precondition(probe.deletedIdentifier == nil)
        precondition(
            IntentsUIHostControl.voiceShortcut(identifier: installed.identifier)?.invocationPhrase
                == "Keep me"
        )
        controller.finish(invocationPhrase: "Still kept until save")
        precondition(probe.updated?.invocationPhrase == "Still kept until save")
        controller.cancel()
        precondition(probe.cancelCount == 2)
        precondition(
            IntentsUIHostControl.voiceShortcut(identifier: installed.identifier)?.invocationPhrase
                == "Still kept until save"
        )
    }
}

func testHostedViewControllingMarker() {
    intentsUIOnMain {
        let stub = HostedViewStub()
        let existential: any INUIHostedViewControlling = stub
        precondition(existential === stub)
        precondition(type(of: stub) == HostedViewStub.self)
    }
}

func testHostedViewSiriProvidingProtocol() {
    intentsUIOnMain {
        let defaults = DefaultSiriHints()
        let existential: any INUIHostedViewSiriProviding = defaults
        precondition(existential.displaysMap == false)
        precondition(existential.displaysMessage == false)
        precondition(existential.displaysPaymentTransaction == false)
        precondition(type(of: defaults) == DefaultSiriHints.self)
    }
}

func testHostedViewSiriProvidingDisplaysMap() {
    intentsUIOnMain {
        let defaults = DefaultSiriHints()
        precondition(defaults.displaysMap == false)
        let map = MapSiriHints()
        precondition(map.displaysMap == true)
        let existential: any INUIHostedViewSiriProviding = map
        precondition(existential.displaysMap == true)
        precondition(existential.displaysMessage == false)
        precondition(existential.displaysPaymentTransaction == false)
    }
}

func testHostedViewSiriProvidingDisplaysMessage() {
    intentsUIOnMain {
        let defaults = DefaultSiriHints()
        precondition(defaults.displaysMessage == false)
        let message = MessageSiriHints()
        precondition(message.displaysMessage == true)
        let existential: any INUIHostedViewSiriProviding = message
        precondition(existential.displaysMessage == true)
        precondition(existential.displaysMap == false)
        precondition(existential.displaysPaymentTransaction == false)
    }
}

func testHostedViewSiriProvidingDisplaysPaymentTransaction() {
    intentsUIOnMain {
        let defaults = DefaultSiriHints()
        precondition(defaults.displaysPaymentTransaction == false)
        let payment = PaymentSiriHints()
        precondition(payment.displaysPaymentTransaction == true)
        let existential: any INUIHostedViewSiriProviding = payment
        precondition(existential.displaysPaymentTransaction == true)
        precondition(existential.displaysMap == false)
        precondition(existential.displaysMessage == false)
    }
}
