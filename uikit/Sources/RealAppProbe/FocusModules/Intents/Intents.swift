// Fail-closed Intents for mozilla-mobile/focus-ios a2832521
// (SiriShortcuts.swift, SettingsViewController INUI* delegates).
// SiriShortcuts imports only Intents + IntentsUI, so this module
// re-exports Foundation/UIKit the way the app target's bridging header
// did. MEASURED Blockzilla 2026-09-06: 18 unique diagnostics in
// SiriShortcuts.swift (NSUserActivity, EraseIntent, DispatchQueue,
// UIViewController, formSheet, INVoiceShortcut.shortcut).

@_exported import Foundation
@_exported import UIKit

open class INIntent: NSObject {
    public var suggestedInvocationPhrase: String?
    public override init() { super.init() }
}

public final class INShortcut: NSObject {
    public var intent: INIntent?
    public var userActivity: NSUserActivity?
    public init(intent: INIntent) {
        self.intent = intent
        super.init()
    }
    public init(userActivity: NSUserActivity) {
        self.userActivity = userActivity
        super.init()
    }
}

public final class INVoiceShortcut: NSObject {
    public var shortcut: INShortcut
    public var identifier: UUID
    public init(shortcut: INShortcut, identifier: UUID = UUID()) {
        self.shortcut = shortcut
        self.identifier = identifier
        super.init()
    }
}

public final class INInteraction: NSObject {
    public var intent: INIntent
    public init(intent: INIntent, response: Any?) {
        self.intent = intent
        super.init()
        _ = response
    }
    public func donate(completion: ((Error?) -> Void)? = nil) {
        completion?(nil)
    }
}

public final class INVoiceShortcutCenter {
    public static let shared = INVoiceShortcutCenter()
    public func getAllVoiceShortcuts(
        completion: @escaping ([INVoiceShortcut]?, Error?) -> Void
    ) {
        completion([], nil)
    }
}

#if canImport(Foundation)
extension NSUserActivity {
    /// AppDelegate.swift:293 `userActivity.interaction?.intent`.
    /// On UIKit this comes from the Intents overlay.
    public var interaction: INInteraction? { nil }
    /// SiriShortcuts.swift:43. Darwin Foundation's NSUserActivity Swift
    /// overlay on macOS 11 may omit the Intents phrase.
    public var suggestedInvocationPhrase: String? {
        get { nil }
        set { _ = newValue }
    }
}
#endif
