// Open IntentsUI module. The controllers preserve the first-party lifecycle
// and delegate contracts while exposing explicit host actions. A Linux host
// can render its own phrase editor and call finish/cancel/delete; absent that
// host, no fake Siri account or fabricated success is reported.

@_exported import UIKit
@_exported @_spi(OpenIntentsHost) import Intents

public enum INUIVoiceShortcutPresentationCapability: Int, Sendable {
    case unavailable = 0
    case hostDriven = 1
}

public enum INUIVoiceShortcutError: Error, Sendable {
    case emptyInvocationPhrase
    case shortcutNotFound
}

@MainActor
public protocol INUIAddVoiceShortcutViewControllerDelegate: AnyObject {
    func addVoiceShortcutViewController(
        _ controller: INUIAddVoiceShortcutViewController,
        didFinishWith voiceShortcut: INVoiceShortcut?,
        error: Error?
    )
    func addVoiceShortcutViewControllerDidCancel(
        _ controller: INUIAddVoiceShortcutViewController
    )
}

@MainActor
public protocol INUIEditVoiceShortcutViewControllerDelegate: AnyObject {
    func editVoiceShortcutViewController(
        _ controller: INUIEditVoiceShortcutViewController,
        didUpdate voiceShortcut: INVoiceShortcut?,
        error: Error?
    )
    func editVoiceShortcutViewController(
        _ controller: INUIEditVoiceShortcutViewController,
        didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID
    )
    func editVoiceShortcutViewControllerDidCancel(
        _ controller: INUIEditVoiceShortcutViewController
    )
}

@MainActor
open class INUIAddVoiceShortcutViewController: UIViewController {
    public static let presentationCapability: INUIVoiceShortcutPresentationCapability = .hostDriven

    public let shortcut: INShortcut
    public weak var delegate: (any INUIAddVoiceShortcutViewControllerDelegate)?

    public init(shortcut: INShortcut) {
        self.shortcut = shortcut
        super.init(nibName: nil, bundle: nil)
    }

    /// Host action corresponding to the system sheet's Add button.
    open func finish(invocationPhrase: String) {
        let phrase = invocationPhrase
        guard phrase.contains(where: { !$0.isWhitespace }) else {
            delegate?.addVoiceShortcutViewController(
                self,
                didFinishWith: nil,
                error: INUIVoiceShortcutError.emptyInvocationPhrase
            )
            return
        }
        let value = INVoiceShortcutCenter.shared.install(
            shortcut,
            invocationPhrase: phrase
        )
        delegate?.addVoiceShortcutViewController(self, didFinishWith: value, error: nil)
    }

    /// Host action corresponding to the system sheet's Cancel button.
    open func cancel() {
        delegate?.addVoiceShortcutViewControllerDidCancel(self)
    }
}

@MainActor
open class INUIEditVoiceShortcutViewController: UIViewController {
    public static let presentationCapability: INUIVoiceShortcutPresentationCapability = .hostDriven

    public private(set) var voiceShortcut: INVoiceShortcut
    public weak var delegate: (any INUIEditVoiceShortcutViewControllerDelegate)?

    public init(voiceShortcut: INVoiceShortcut) {
        self.voiceShortcut = voiceShortcut
        super.init(nibName: nil, bundle: nil)
    }

    /// Host action corresponding to Save in the system editor.
    open func finish(invocationPhrase: String) {
        let phrase = invocationPhrase
        guard phrase.contains(where: { !$0.isWhitespace }) else {
            delegate?.editVoiceShortcutViewController(
                self,
                didUpdate: nil,
                error: INUIVoiceShortcutError.emptyInvocationPhrase
            )
            return
        }
        voiceShortcut = INVoiceShortcutCenter.shared.update(
            voiceShortcut,
            invocationPhrase: phrase
        )
        delegate?.editVoiceShortcutViewController(self, didUpdate: voiceShortcut, error: nil)
    }

    /// Host action corresponding to Delete in the system editor.
    open func delete() {
        let identifier = voiceShortcut.identifier
        guard INVoiceShortcutCenter.shared.remove(identifier: identifier) else {
            delegate?.editVoiceShortcutViewController(
                self,
                didUpdate: nil,
                error: INUIVoiceShortcutError.shortcutNotFound
            )
            return
        }
        delegate?.editVoiceShortcutViewController(
            self,
            didDeleteVoiceShortcutWithIdentifier: identifier
        )
    }

    /// Host action corresponding to Cancel in the system editor.
    open func cancel() {
        delegate?.editVoiceShortcutViewControllerDidCancel(self)
    }
}
