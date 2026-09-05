import Foundation

/// In-process registry so a widget or Linux host can enumerate
/// `AppShortcutsProvider` catalogs and perform a registered intent from a
/// parameter dictionary. There is no Shortcuts daemon on this host.
public enum AppIntentsHost {
    private static let lock = NSLock()
    private static var shortcutProviders: [() -> [AppShortcut]] = []
    private static var factories: [String: ([String: Any]) throws -> any AppIntent] = [:]

    public static func reset() {
        lock.lock()
        shortcutProviders.removeAll()
        factories.removeAll()
        lock.unlock()
    }

    public static func registerShortcuts<Provider: AppShortcutsProvider>(_ type: Provider.Type) {
        lock.lock()
        shortcutProviders.append({ type.appShortcuts })
        lock.unlock()
    }

    public static func registeredShortcuts() -> [AppShortcut] {
        lock.lock()
        defer { lock.unlock() }
        return shortcutProviders.flatMap { $0() }
    }

    public static func registerIntent<Intent: AppIntent>(
        _ type: Intent.Type,
        factory: @escaping ([String: Any]) throws -> Intent
    ) {
        lock.lock()
        factories[type.persistentIdentifier] = { try factory($0) }
        lock.unlock()
    }

    public static func applyParameters(_ intent: Any, parameters: [String: Any]) {
        for (label, child) in Mirror(reflecting: intent).children {
            guard let label else { continue }
            let name: String
            // Measured: Mirror labels for `@Parameter` are `_url`; strip a
            // leading `_` via hasPrefix (testHostRegistryEnumeratesShortcutsAndPerformsFromParameters).
            if label.hasPrefix("_") {
                name = String(label.dropFirst())
            } else {
                name = label
            }
            guard let supplied = parameters[name] else { continue }
            if let parameter = child as? IntentParameter<String>, let value = supplied as? String {
                parameter.wrappedValue = value
            } else if let parameter = child as? IntentParameter<Int>, let value = supplied as? Int {
                parameter.wrappedValue = value
            } else if let parameter = child as? IntentParameter<Bool>, let value = supplied as? Bool {
                parameter.wrappedValue = value
            } else if let parameter = child as? IntentParameter<Double>, let value = supplied as? Double {
                parameter.wrappedValue = value
            } else if let parameter = child as? IntentParameter<URL>, let value = supplied as? URL {
                parameter.wrappedValue = value
            }
        }
    }

    private static func factory(for identifier: String) -> (([String: Any]) throws -> any AppIntent)? {
        lock.lock()
        defer { lock.unlock() }
        return factories[identifier]
    }

    public static func perform(
        identifier: String,
        parameters: [String: Any] = [:]
    ) async throws -> any IntentResult {
        guard let factory = factory(for: identifier) else {
            throw AppIntentError.Unrecoverable.entityNotFound
        }
        let intent = try factory(parameters)
        return try await AppIntentRuntime.shared.perform(intent)
    }
}

extension EnumerableEntityQuery {
    public static var findIntentDescription: IntentDescription? { nil }
}

extension DynamicOptionsProvider {
    public typealias ItemCollection = IntentItemCollection
    public typealias ParameterDependency = IntentParameterDependency
}

extension _SupportsAppDependencies {
    public typealias Dependency = AppDependency
}

extension IntentParameter {
    public convenience init<Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Value? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior? = nil,
        optionsProvider: Provider
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public var hasOptionsProvider: Bool { optionsProviderAttached }

    public func attachResolvedOptions(_ options: [Any]) {
        storedResolvedOptions = options
    }

    public var resolvedDynamicOptions: [Any] { storedResolvedOptions }
}
