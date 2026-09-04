// Open IntentsUI module. The controllers preserve the first-party lifecycle
// and delegate contracts while exposing explicit host actions. A Linux host
// can render its own phrase editor and call finish/cancel/delete; absent that
// host, no fake Siri account or fabricated success is reported.
//
// Isolated host compilation imports Foundation only. UIKit-owned superclasses
// (`UIViewController`, `UIButton`) are not declared dependencies of this seed,
// so the isolated types subclass `NSObject`. Intents-owned `INShortcut` and
// `INVoiceShortcut` are module-local stand-ins when Intents cannot be imported.

import Foundation

#if canImport(Intents)
@_spi(OpenIntentsHost) import Intents
#endif

/// Host presentation mode. Linux has no Siri add/edit sheet, so the only
/// supported path is a platform host driving `finish` / `cancel` / `delete`.
public enum INUIVoiceShortcutPresentationCapability: Int, Sendable {
    case unavailable = 0
    case hostDriven = 1
}

public enum INUIVoiceShortcutError: Error, Sendable {
    case emptyInvocationPhrase
    case shortcutNotFound
}

/// Bridged `NS_ENUM(NSUInteger, INUIAddVoiceShortcutButtonStyle)`.
/// Raw values match the pinned `dotnet/macios` `[Native]` order:
/// White, WhiteOutline, Black, BlackOutline, Automatic, AutomaticOutline.
public enum INUIAddVoiceShortcutButtonStyle: UInt, Hashable, Sendable {
    case white = 0
    case whiteOutline = 1
    case black = 2
    case blackOutline = 3
    case automatic = 4
    case automaticOutline = 5
}

/// Bridged `NS_ENUM(NSUInteger, INUIHostedViewContext)`.
/// Raw values match the pinned macios `[Native]` order: SiriSnippet, MapsCard.
public enum INUIHostedViewContext: UInt, Hashable, Sendable {
    case siriSnippet = 0
    case mapsCard = 1
}

/// Bridged `NS_ENUM(NSUInteger, INUIInteractiveBehavior)`.
/// Raw values match the pinned macios `[Native]` order:
/// None, NextView, Launch, GenericAction.
public enum INUIInteractiveBehavior: UInt, Hashable, Sendable {
    case none = 0
    case nextView = 1
    case launch = 2
    case genericAction = 3
}

@preconcurrency @MainActor
public protocol INUIAddVoiceShortcutViewControllerDelegate: NSObjectProtocol {
    func addVoiceShortcutViewController(
        _ controller: INUIAddVoiceShortcutViewController,
        didFinishWith voiceShortcut: INVoiceShortcut?,
        error: (any Error)?
    )
    func addVoiceShortcutViewControllerDidCancel(
        _ controller: INUIAddVoiceShortcutViewController
    )
}

@preconcurrency @MainActor
public protocol INUIEditVoiceShortcutViewControllerDelegate: NSObjectProtocol {
    func editVoiceShortcutViewController(
        _ controller: INUIEditVoiceShortcutViewController,
        didUpdate voiceShortcut: INVoiceShortcut?,
        error: (any Error)?
    )
    func editVoiceShortcutViewController(
        _ controller: INUIEditVoiceShortcutViewController,
        didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID
    )
    func editVoiceShortcutViewControllerDidCancel(
        _ controller: INUIEditVoiceShortcutViewController
    )
}

@preconcurrency @MainActor
public protocol INUIAddVoiceShortcutButtonDelegate: NSObjectProtocol {
    func present(
        _ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController,
        for addVoiceShortcutButton: INUIAddVoiceShortcutButton
    )
    func present(
        _ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController,
        for addVoiceShortcutButton: INUIAddVoiceShortcutButton
    )
}

/// Optional Siri hosted-view hints. Linux never hosts a Siri snippet, so the
/// protocol defaults are all `false`. Conformers may override; nothing here
/// claims a Siri UI is present.
@preconcurrency @MainActor
public protocol INUIHostedViewSiriProviding: NSObjectProtocol {
    var displaysMap: Bool { get }
    var displaysMessage: Bool { get }
    var displaysPaymentTransaction: Bool { get }
}

extension INUIHostedViewSiriProviding {
    public var displaysMap: Bool { false }
    public var displaysMessage: Bool { false }
    public var displaysPaymentTransaction: Bool { false }
}

/// Marker protocol for Siri/Maps hosted intent UI. The `configure*` methods
/// take Intents-owned `INParameter` / `INInteraction` and a CoreGraphics size;
/// those signatures are not declared on the isolated host.
@preconcurrency @MainActor
public protocol INUIHostedViewControlling: NSObjectProtocol {}

@preconcurrency @MainActor
open class INUIAddVoiceShortcutViewController: NSObject {
    public static let presentationCapability: INUIVoiceShortcutPresentationCapability = .hostDriven

    public let shortcut: INShortcut
    public weak var delegate: (any INUIAddVoiceShortcutViewControllerDelegate)?

    public init(shortcut: INShortcut) {
        self.shortcut = shortcut
        super.init()
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
        let value = IntentsUIHostVoiceShortcuts.install(
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

@preconcurrency @MainActor
open class INUIEditVoiceShortcutViewController: NSObject {
    public static let presentationCapability: INUIVoiceShortcutPresentationCapability = .hostDriven

    public private(set) var voiceShortcut: INVoiceShortcut
    public weak var delegate: (any INUIEditVoiceShortcutViewControllerDelegate)?

    public init(voiceShortcut: INVoiceShortcut) {
        self.voiceShortcut = voiceShortcut
        super.init()
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
        voiceShortcut = IntentsUIHostVoiceShortcuts.update(
            voiceShortcut,
            invocationPhrase: phrase
        )
        delegate?.editVoiceShortcutViewController(self, didUpdate: voiceShortcut, error: nil)
    }

    /// Host action corresponding to Delete in the system editor.
    open func delete() {
        let identifier = voiceShortcut.identifier
        guard IntentsUIHostVoiceShortcuts.remove(identifier: identifier) else {
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

/// Add-to-Siri control. Isolated host subclasses `NSObject` because `UIButton`
/// is UIKit-owned. Linux never draws the system button or talks to Siri; a
/// host calls `presentAddVoiceShortcut()` / `presentEditVoiceShortcut(_:)`.
@preconcurrency @MainActor
open class INUIAddVoiceShortcutButton: NSObject {
    public private(set) var style: INUIAddVoiceShortcutButtonStyle
    public weak var delegate: (any INUIAddVoiceShortcutButtonDelegate)?
    public var shortcut: INShortcut?
    public var cornerRadius: CGFloat = 0

    public init(style: INUIAddVoiceShortcutButtonStyle) {
        self.style = style
        super.init()
    }

    open func setStyle(_ style: INUIAddVoiceShortcutButtonStyle) {
        self.style = style
    }

    /// Host action corresponding to a tap that should present the add sheet.
    /// Does nothing when `shortcut` is nil. Never consults Siri to decide
    /// between add and edit.
    open func presentAddVoiceShortcut() {
        guard let shortcut else { return }
        let controller = INUIAddVoiceShortcutViewController(shortcut: shortcut)
        delegate?.present(controller, for: self)
    }

    /// Host action corresponding to a tap that should present the edit sheet
    /// for an already-installed voice shortcut identity.
    open func presentEditVoiceShortcut(_ voiceShortcut: INVoiceShortcut) {
        let controller = INUIEditVoiceShortcutViewController(voiceShortcut: voiceShortcut)
        delegate?.present(controller, for: self)
    }
}

/// Linux host-test control. Not part of Apple's public IntentsUI surface.
@_spi(OpenUIKitHost)
public enum IntentsUIHostControl {
    public static func resetVoiceShortcuts() {
        IntentsUIHostVoiceShortcuts.reset()
    }

    @discardableResult
    public static func install(
        _ shortcut: INShortcut,
        invocationPhrase: String
    ) -> INVoiceShortcut {
        IntentsUIHostVoiceShortcuts.install(shortcut, invocationPhrase: invocationPhrase)
    }
}
