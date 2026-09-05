import Foundation

#if canImport(Intents)
@_spi(OpenIntentsHost) import Intents
#endif

// MARK: - Intents isolation stand-ins
//
// The isolated host gate compiles IntentsUI with Foundation only. Apple's
// `INShortcut` and `INVoiceShortcut` are owned by Intents, which is not a
// declared seed dependency and is not present on this Linux toolchain.
// These stand-ins exist so IntentsUI-owned initializers and delegates
// type-check. They are not a Linux Intents port, do not talk to Siri, and
// must be deleted when a real Intents module is on the link line.

#if !canImport(Intents)
open class INShortcut: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

open class INVoiceShortcut: NSObject, @unchecked Sendable {
    public let identifier: UUID
    public let invocationPhrase: String
    public let shortcut: INShortcut

    public init(
        identifier: UUID = UUID(),
        invocationPhrase: String,
        shortcut: INShortcut
    ) {
        self.identifier = identifier
        self.invocationPhrase = invocationPhrase
        self.shortcut = shortcut
        super.init()
    }
}
#endif

/// Process-local voice-shortcut table used when Intents is absent.
/// Linux never consults Siri or the system shortcut database.
enum IntentsUIHostVoiceShortcuts {
    private static let lock = NSLock()
    private static var values: [UUID: INVoiceShortcut] = [:]

    static func reset() {
        #if canImport(Intents)
        INVoiceShortcutCenter.shared.removeAll()
        #else
        lock.lock()
        values.removeAll(keepingCapacity: false)
        lock.unlock()
        #endif
    }

    static func install(
        _ shortcut: INShortcut,
        invocationPhrase: String,
        identifier: UUID = UUID()
    ) -> INVoiceShortcut {
        #if canImport(Intents)
        return INVoiceShortcutCenter.shared.install(
            shortcut,
            invocationPhrase: invocationPhrase,
            identifier: identifier
        )
        #else
        let voiceShortcut = INVoiceShortcut(
            identifier: identifier,
            invocationPhrase: invocationPhrase,
            shortcut: shortcut
        )
        lock.lock()
        values[identifier] = voiceShortcut
        lock.unlock()
        return voiceShortcut
        #endif
    }

    static func update(
        _ voiceShortcut: INVoiceShortcut,
        invocationPhrase: String
    ) -> INVoiceShortcut {
        #if canImport(Intents)
        return INVoiceShortcutCenter.shared.update(
            voiceShortcut,
            invocationPhrase: invocationPhrase
        )
        #else
        return install(
            voiceShortcut.shortcut,
            invocationPhrase: invocationPhrase,
            identifier: voiceShortcut.identifier
        )
        #endif
    }

    static func remove(identifier: UUID) -> Bool {
        #if canImport(Intents)
        return INVoiceShortcutCenter.shared.remove(identifier: identifier)
        #else
        lock.lock()
        let removed = values.removeValue(forKey: identifier) != nil
        lock.unlock()
        return removed
        #endif
    }

    static func value(identifier: UUID) -> INVoiceShortcut? {
        #if canImport(Intents)
        return nil
        #else
        lock.lock()
        let value = values[identifier]
        lock.unlock()
        return value
        #endif
    }
}
