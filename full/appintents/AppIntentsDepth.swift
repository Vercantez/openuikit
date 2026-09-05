import Foundation

/// Host-driven entity resolution. Linux has no Shortcuts metadata extractor,
/// so suggested / identifier / default lookups are process-local.
public enum EntityResolutionEngine {
    private static let lock = NSLock()
    private static var catalogs: [String: [Any]] = [:]
    private static var defaults: [String: Any] = [:]

    private static func key<E>(_ type: E.Type) -> String {
        String(describing: type)
    }

    public static func reset() {
        lock.lock()
        catalogs.removeAll()
        defaults.removeAll()
        lock.unlock()
    }

    public static func register<E: AppEntity>(_ entities: [E], default defaultEntity: E? = nil) {
        lock.lock()
        catalogs[key(E.self)] = entities
        if let defaultEntity {
            defaults[key(E.self)] = defaultEntity
        } else {
            defaults[key(E.self)] = entities.first
        }
        lock.unlock()
    }

    public static func suggestedEntities<E: AppEntity>(_ type: E.Type) -> [E] {
        lock.lock()
        defer { lock.unlock() }
        return catalogs[key(type)] as? [E] ?? []
    }

    public static func entities<E: AppEntity>(for identifiers: [E.ID], as type: E.Type) -> [E] {
        let all = suggestedEntities(type)
        return all.filter { entity in
            identifiers.contains { $0 == entity.id }
        }
    }

    public static func defaultResult<E: AppEntity>(_ type: E.Type) -> E? {
        lock.lock()
        defer { lock.unlock() }
        return defaults[key(type)] as? E
    }

    public static func entities<E: AppEntity>(matching string: String, as type: E.Type) -> [E] {
        suggestedEntities(type).filter { entity in
            let title = appIntentsString(entity.displayRepresentation.title)
            let ident = String(describing: entity.id)
            return title.hasPrefix(string) || ident.hasPrefix(string)
        }
    }

    public static func allEntities<E: AppEntity>(_ type: E.Type) -> [E] {
        suggestedEntities(type)
    }
}

extension String {
    public struct IntentInputOptions: Sendable, Hashable {
        public enum KeyboardType: Sendable, Hashable {
            case asciiCapable
            case numbersAndPunctuation
            case URL
            case `default`
            case numberPad
        }

        public enum CapitalizationType: Sendable, Hashable {
            case allCharacters
            case none
            case words
            case sentences
        }

        public var keyboardType: KeyboardType
        public var capitalizationType: CapitalizationType
        public var multiline: Bool
        public var autocorrect: Bool
        public var smartQuotes: Bool
        public var smartDashes: Bool

        public init(
            keyboardType: KeyboardType = .default,
            capitalizationType: CapitalizationType = .sentences,
            multiline: Bool = false,
            autocorrect: Bool = true,
            smartQuotes: Bool = true,
            smartDashes: Bool = true
        ) {
            self.keyboardType = keyboardType
            self.capitalizationType = capitalizationType
            self.multiline = multiline
            self.autocorrect = autocorrect
            self.smartQuotes = smartQuotes
            self.smartDashes = smartDashes
        }
    }
}

extension IntentParameter where Value == String {
    public var inputOptions: String.IntentInputOptions? {
        storedInputOptionsBox as? String.IntentInputOptions
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: String? = nil,
        inputOptions: String.IntentInputOptions? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        self.defaultValue = defaultValue
        storedInputOptionsBox = inputOptions
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        inputOptions: String.IntentInputOptions? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            inputOptions: inputOptions,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }
}

extension IntentParameter {
    public func resolveDynamicOptions<E: AppEntity>(as type: E.Type) -> [E] {
        if let typed = storedResolvedOptions as? [E], !typed.isEmpty {
            return typed
        }
        return EntityResolutionEngine.suggestedEntities(type)
    }
}

extension AppIntentsHost {
    public static func suggestedEntities<E: AppEntity>(_ type: E.Type) -> [E] {
        EntityResolutionEngine.suggestedEntities(type)
    }

    public static func performOnHost<R: IntentResult>(
        _ intent: any AppIntent,
        result: R
    ) -> R {
        _ = intent
        return result
    }
}

extension ForegroundContinuableIntent {
    public static var authenticationPolicy: IntentAuthenticationPolicy { .alwaysAllowed }
}
