import Foundation
import IntentsUI

#if canImport(Intents)
import Intents
#endif
#if canImport(UIKit)
import UIKit
#endif

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest Intents/UIKit success.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Foundation (and Intents/UIKit when those lanes exist).
// 2. Build IntentsUI with those modules on `-I` / `-L`.
// 3. Link this file as a client that imports IntentsUI and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `INTENTSUI_DEPENDENCY_IDENTITY_OK` and that `libIntentsUI.dylib`
//    was loaded.
//
// Isolated host compilation has Foundation only. Assertions that need
// Intents/UIKit are compiled only when those modules exist.

private func assertNotIntentsUIType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("IntentsUI."))
}

private final class IdentityAddProbe: NSObject, INUIAddVoiceShortcutViewControllerDelegate {
    var voiceShortcut: INVoiceShortcut?

    func addVoiceShortcutViewController(
        _ controller: INUIAddVoiceShortcutViewController,
        didFinishWith voiceShortcut: INVoiceShortcut?,
        error: (any Error)?
    ) {
        _ = (controller, error)
        self.voiceShortcut = voiceShortcut
    }

    func addVoiceShortcutViewControllerDidCancel(
        _ controller: INUIAddVoiceShortcutViewController
    ) {
        _ = controller
    }
}

private final class IdentityEditProbe: NSObject, INUIEditVoiceShortcutViewControllerDelegate {
    var deletedIdentifier: UUID?

    func editVoiceShortcutViewController(
        _ controller: INUIEditVoiceShortcutViewController,
        didUpdate voiceShortcut: INVoiceShortcut?,
        error: (any Error)?
    ) {
        _ = (controller, voiceShortcut, error)
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
    }
}

@MainActor
private func assertFoundationIdentity() {
    let identifier = UUID()
    assertNotIntentsUIType(identifier)

    let shortcut = INShortcut()
    let add = INUIAddVoiceShortcutViewController(shortcut: shortcut)
    let addProbe = IdentityAddProbe()
    add.delegate = addProbe
    add.finish(invocationPhrase: "Identity phrase")
    let installed = addProbe.voiceShortcut
    precondition(installed != nil)

    let edit = INUIEditVoiceShortcutViewController(voiceShortcut: installed!)
    let editProbe = IdentityEditProbe()
    edit.delegate = editProbe
    edit.delete()
    precondition(editProbe.deletedIdentifier == installed!.identifier)
    precondition(editProbe.deletedIdentifier != identifier)
}

#if canImport(Intents)
@MainActor
private func assertIntentsIdentity() {
    let intent = INIntent()
    let shortcut = INShortcut(intent: intent)
    assertNotIntentsUIType(shortcut)
    let add = INUIAddVoiceShortcutViewController(shortcut: shortcut)
    precondition(add.shortcut === shortcut)
}
#endif

#if canImport(UIKit)
@MainActor
private func assertUIKitNote() {
    // Darwin superclasses are UIViewController / UIButton. Isolated Linux
    // subclasses NSObject because UIKit is not a declared seed dependency.
    let add = INUIAddVoiceShortcutViewController(shortcut: INShortcut())
    _ = add
}
#endif

@MainActor
func intentsUIDependencyIdentityMain() {
    assertFoundationIdentity()
    #if canImport(Intents)
    assertIntentsIdentity()
    #endif
    #if canImport(UIKit)
    assertUIKitNote()
    #endif
    print("INTENTSUI_DEPENDENCY_IDENTITY_OK")
}

Task { @MainActor in
    intentsUIDependencyIdentityMain()
    exit(0)
}
dispatchMain()
