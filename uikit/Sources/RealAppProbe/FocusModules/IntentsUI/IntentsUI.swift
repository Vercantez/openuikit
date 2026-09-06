// Harness stub for IntentsUI. SettingsViewController conforms to the
// add/edit-shortcut delegate protocols; those methods are not called
// during the static Settings capture. SiriShortcuts.swift:88 constructs
// INUIAddVoiceShortcutViewController(shortcut:).

import Foundation
import Intents
import OpenUIKit

open class INUIAddVoiceShortcutViewController: UIViewController {
    public weak var delegate: INUIAddVoiceShortcutViewControllerDelegate?
    public init(shortcut: INShortcut) {
        super.init(nibName: nil, bundle: nil)
        _ = shortcut
    }
}

open class INUIEditVoiceShortcutViewController: UIViewController {
    public weak var delegate: INUIEditVoiceShortcutViewControllerDelegate?
    public init(voiceShortcut: INVoiceShortcut) {
        super.init(nibName: nil, bundle: nil)
        _ = voiceShortcut
    }
}

public protocol INUIAddVoiceShortcutViewControllerDelegate: AnyObject {
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController,
                                        didFinishWith voiceShortcut: INVoiceShortcut?,
                                        error: Error?)
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController)
}

public protocol INUIEditVoiceShortcutViewControllerDelegate: AnyObject {
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didUpdate voiceShortcut: INVoiceShortcut?,
                                         error: Error?)
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID)
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController)
}
