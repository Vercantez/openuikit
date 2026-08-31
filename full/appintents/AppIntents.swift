//===----------------------------------------------------------------------===//
// Portable AppIntents
//
// This is a process-local implementation of App Intents' executable model.
// Linux has no Shortcuts daemon or App Intents metadata extractor, so the
// portable boundary preserves intent execution, result/dialog values,
// parameter metadata, entity queries, and shortcut descriptions in-process.
// It never reports that an unavailable system registration succeeded.
//===----------------------------------------------------------------------===//

@_exported import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Execution and results

public protocol IntentResult: Sendable {}

public protocol ProvidesDialog: IntentResult {}

public protocol ShowsSnippetView: IntentResult {}

public struct IntentDialog: Sendable, Hashable,
    ExpressibleByStringLiteral, ExpressibleByStringInterpolation
{
    public let text: String

    public init(_ text: String) { self.text = text }
    public init(stringLiteral value: String) { self.init(value) }
    public init(stringInterpolation: StringInterpolation) {
        self.init(stringInterpolation.value)
    }

    public struct StringInterpolation: StringInterpolationProtocol {
        fileprivate var value: String

        public init(literalCapacity: Int, interpolationCount: Int) {
            value = ""
            value.reserveCapacity(literalCapacity + interpolationCount * 8)
        }

        public mutating func appendLiteral(_ literal: String) {
            value += literal
        }

        public mutating func appendInterpolation<T>(_ value: T) {
            self.value += String(describing: value)
        }
    }
}

/// Concrete value returned by the portable `.result(...)` factories.
public struct IntentResultValue: IntentResult, ProvidesDialog, ShowsSnippetView,
    Sendable, Hashable
{
    public let dialog: IntentDialog?

    public init(dialog: IntentDialog? = nil) {
        self.dialog = dialog
    }
}

public extension IntentResult where Self == IntentResultValue {
    static func result() -> Self {
        .init()
    }

    static func result(dialog: IntentDialog) -> Self {
        .init(dialog: dialog)
    }
}

public protocol AppIntent: Sendable {
    associatedtype PerformResult: IntentResult
    func perform() async throws -> PerformResult
}

/// Executes intents without pretending that a platform Shortcuts daemon is
/// present. The count is useful to hosts that need deterministic lifecycle
/// evidence.
public actor AppIntentRuntime {
    public static let shared = AppIntentRuntime()

    public private(set) var executionCount: UInt64 = 0

    public init() {}

    @discardableResult
    public func perform<I: AppIntent>(_ intent: I) async throws -> I.PerformResult {
        executionCount &+= 1
        return try await intent.perform()
    }
}

// MARK: - Descriptions

public struct IntentDescription: Sendable, Hashable, ExpressibleByStringLiteral {
    public let text: String

    public init(_ text: String) { self.text = text }
    public init(stringLiteral value: String) { self.init(value) }
}

public struct TypeDisplayRepresentation: Sendable, Hashable,
    ExpressibleByStringLiteral
{
    public let name: String

    public init(name: String) { self.name = name }
    public init(stringLiteral value: String) { self.init(name: value) }
}

public struct DisplayRepresentation: @unchecked Sendable, Hashable,
    ExpressibleByStringLiteral
{
    public struct Image: @unchecked Sendable, Hashable {
        public let systemName: String
        public let isTemplate: Bool?

        public init(systemName: String, isTemplate: Bool? = nil) {
            self.systemName = systemName
            self.isTemplate = isTemplate
        }

        #if canImport(UIKit)
        public init?(
            systemName: String,
            tintColor: UIColor? = nil,
            symbolConfiguration: UIImage.SymbolConfiguration? = nil
        ) {
            guard !systemName.isEmpty else { return nil }
            self.systemName = systemName
            self.isTemplate = symbolConfiguration == nil ? nil : true
            _ = tintColor
        }
        #elseif canImport(AppKit)
        public init?(
            systemName: String,
            tintColor: NSColor? = nil,
            symbolConfiguration: NSImage.SymbolConfiguration? = nil
        ) {
            guard !systemName.isEmpty else { return nil }
            self.systemName = systemName
            self.isTemplate = symbolConfiguration == nil ? nil : true
            _ = tintColor
        }
        #endif
    }

    public let title: String
    public let subtitle: String?
    public let image: Image?

    public init(title: String, subtitle: String? = nil, image: Image? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
    }

    public init(stringLiteral value: String) {
        self.init(title: value)
    }
}

// MARK: - Parameters and files

public enum InputConnectionBehavior: Sendable, Hashable {
    case connectToPreviousIntentResult
}

/// Content-type metadata accepted by `Parameter`.  Identifiers use the same
/// public UTI spellings as UniformTypeIdentifiers and can be losslessly mapped
/// to that framework once it is loaded.
public struct IntentFileContentType: Sendable, Hashable {
    public let identifier: String

    public init(_ identifier: String) { self.identifier = identifier }

    public static let item = Self("public.item")
    public static let data = Self("public.data")
    public static let image = Self("public.image")
    public static let jpeg = Self("public.jpeg")
    public static let png = Self("public.png")
    public static let gif = Self("com.compuserve.gif")
    public static let heic = Self("public.heic")
}

private protocol _OptionalIntentValue {
    static var _none: Any { get }
}

extension Optional: _OptionalIntentValue {
    fileprivate static var _none: Any { Self.none as Any }
}

private final class _ParameterStorage<Value>: @unchecked Sendable {
    enum State {
        case unset
        case value(Value)
    }

    var state: State = .unset
}

@propertyWrapper
public struct Parameter<Value>: @unchecked Sendable {
    public struct Metadata: Sendable, Hashable {
        public let title: String
        public let description: String?
        public let requestValueDialog: IntentDialog?
        public let supportedContentTypes: [IntentFileContentType]
        public let inputConnectionBehavior: InputConnectionBehavior?
    }

    private let storage: _ParameterStorage<Value>
    public let metadata: Metadata

    public var wrappedValue: Value {
        get {
            switch storage.state {
            case let .value(value):
                return value
            case .unset:
                if let optional = Value.self as? any _OptionalIntentValue.Type,
                   let value = optional._none as? Value {
                    return value
                }
                preconditionFailure(
                    "AppIntent parameter '\(metadata.title)' has not been supplied"
                )
            }
        }
        nonmutating set { storage.state = .value(newValue) }
    }

    public var projectedValue: Parameter<Value> { self }

    public init(
        title: String,
        description: String? = nil,
        requestValueDialog: IntentDialog? = nil,
        supportedContentTypes: [IntentFileContentType] = [],
        inputConnectionBehavior: InputConnectionBehavior? = nil
    ) {
        self.storage = _ParameterStorage()
        self.metadata = Metadata(
            title: title,
            description: description,
            requestValueDialog: requestValueDialog,
            supportedContentTypes: supportedContentTypes,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }
}

@propertyWrapper
public struct IntentParameterDependency<Intent>: @unchecked Sendable {
    private final class Storage: @unchecked Sendable {
        var value: Intent?
    }

    private let storage = Storage()

    public var wrappedValue: Intent? {
        get { storage.value }
        nonmutating set { storage.value = newValue }
    }

    public init<Value>(_ keyPath: KeyPath<Intent, Parameter<Value>>) {
        _ = keyPath
    }
}

public struct IntentFile: @unchecked Sendable, Hashable {
    public let data: Data
    public let filename: String?
    public let fileURL: URL?
    public let type: IntentFileContentType?

    public init(
        data: Data,
        filename: String? = nil,
        type: IntentFileContentType? = nil
    ) {
        self.data = data
        self.filename = filename
        self.fileURL = nil
        self.type = type
    }

    public init(fileURL: URL, filename: String? = nil, type: IntentFileContentType? = nil) {
        self.data = Data()
        self.filename = filename
        self.fileURL = fileURL
        self.type = type
    }
}

// MARK: - Entities and enums

public protocol AppEnum: RawRepresentable, Hashable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { get }
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] { get }
}

public protocol AppEntity: Identifiable {
    associatedtype DefaultQuery: EntityQuery where DefaultQuery.Entity == Self

    static var defaultQuery: DefaultQuery { get }
    static var typeDisplayRepresentation: TypeDisplayRepresentation { get }
    var displayRepresentation: DisplayRepresentation { get }
}

public protocol EntityQuery {
    associatedtype Entity: AppEntity

    func entities(for identifiers: [Entity.ID]) async throws -> [Entity]
    func suggestedEntities() async throws -> [Entity]
    func defaultResult() async -> Entity?
}

public extension EntityQuery {
    func suggestedEntities() async throws -> [Entity] { [] }
    func defaultResult() async -> Entity? { nil }
}

// MARK: - Widgets and shortcuts

public protocol WidgetConfigurationIntent: AppIntent {}

public extension WidgetConfigurationIntent {
    func perform() async throws -> some IntentResult {
        .result()
    }
}

public struct AppShortcutPhraseToken: Sendable, Hashable {
    fileprivate let rawValue: String
    public static let applicationName = Self(rawValue: "${applicationName}")
}

public struct AppShortcutPhrase: Sendable, Hashable,
    ExpressibleByStringLiteral, ExpressibleByStringInterpolation
{
    public let template: String

    public init(stringLiteral value: String) { template = value }
    public init(stringInterpolation: StringInterpolation) {
        template = stringInterpolation.value
    }

    public struct StringInterpolation: StringInterpolationProtocol {
        fileprivate var value = ""

        public init(literalCapacity: Int, interpolationCount: Int) {
            value.reserveCapacity(literalCapacity + interpolationCount * 12)
        }

        public mutating func appendLiteral(_ literal: String) { value += literal }

        public mutating func appendInterpolation(_ token: AppShortcutPhraseToken) {
            value += token.rawValue
        }
    }
}

public struct AppShortcut: @unchecked Sendable {
    public let intent: any AppIntent
    public let phrases: [AppShortcutPhrase]
    public let shortTitle: String
    public let systemImageName: String

    public init<I: AppIntent>(
        intent: I,
        phrases: [AppShortcutPhrase],
        shortTitle: String,
        systemImageName: String
    ) {
        self.intent = intent
        self.phrases = phrases
        self.shortTitle = shortTitle
        self.systemImageName = systemImageName
    }
}

@resultBuilder
public enum AppShortcutsBuilder {
    public static func buildBlock(_ components: AppShortcut...) -> [AppShortcut] {
        components
    }

    public static func buildArray(_ components: [[AppShortcut]]) -> [AppShortcut] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [AppShortcut]?) -> [AppShortcut] {
        component ?? []
    }

    public static func buildEither(first component: [AppShortcut]) -> [AppShortcut] {
        component
    }

    public static func buildEither(second component: [AppShortcut]) -> [AppShortcut] {
        component
    }
}

public protocol AppShortcutsProvider {
    @AppShortcutsBuilder static var appShortcuts: [AppShortcut] { get }
}

public enum AppIntentsPortable {
    /// There is no system Shortcuts registrar in the Linux guest. Descriptions
    /// and executable intent values remain available to an embedding host.
    public static let supportsSystemRegistration = false
}
