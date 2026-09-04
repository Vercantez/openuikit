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

// MARK: - Hidden protocol identities required by the public graph

public protocol _IntentValue: Sendable {
    associatedtype ValueType = Self
    associatedtype UnwrappedType = Self
}

public protocol _SupportsAppDependencies {}

public struct _SnippetViewContainer: Sendable {}
public struct _SnippetIntentContainer: Sendable {}

public protocol _IntentValueRepresentable {}
public protocol _ParameterSummarySwitchCase {}

public protocol EntityIdentifierConvertible: Hashable, Sendable {}

extension String: EntityIdentifierConvertible {}
extension Int: EntityIdentifierConvertible {}
extension UUID: EntityIdentifierConvertible {}

public protocol PersistentlyIdentifiable {
    static var persistentIdentifier: String { get }
}

extension PersistentlyIdentifiable {
    public static var persistentIdentifier: String { String(describing: Self.self) }
}

public protocol TypeDisplayRepresentable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { get }
}

public protocol InstanceDisplayRepresentable: CustomLocalizedStringResourceConvertible {
    var displayRepresentation: DisplayRepresentation { get }
}

extension InstanceDisplayRepresentable {
    public var localizedStringResource: LocalizedStringResource {
        LocalizedStringResource(String(describing: displayRepresentation.title))
    }
}

public protocol CaseDisplayRepresentable: CustomLocalizedStringResourceConvertible, Hashable {
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] { get }
}

extension CaseDisplayRepresentable {
    public var localizedStringResource: LocalizedStringResource {
        LocalizedStringResource(String(describing: self))
    }
}

public protocol StaticDisplayRepresentable: CaseDisplayRepresentable, TypeDisplayRepresentable {}

public protocol DisplayRepresentable: InstanceDisplayRepresentable, TypeDisplayRepresentable {}

public protocol AppValue: PersistentlyIdentifiable, TypeDisplayRepresentable, _IntentValue, Sendable {}

// MARK: - Execution and results

public protocol IntentResult: Sendable {
    associatedtype Value: _IntentValue = Never
    associatedtype Dialog = Never
    associatedtype Snippet = Never
    associatedtype OpensAppIntent: AppIntent = Never
    var value: Value? { get }
}

extension IntentResult {
    public var value: Value? { nil }
}

public protocol ProvidesDialog: IntentResult where Self.Dialog == IntentDialog {}

public protocol ShowsSnippetView: IntentResult {}

public protocol ShowsSnippetIntent: IntentResult {}

public protocol OpensIntent: IntentResult {}

public protocol ReturnsValue<Value>: IntentResult {}

public struct IntentDialog: Sendable, Hashable,
    ExpressibleByStringLiteral, ExpressibleByStringInterpolation
{
    public let text: String

    public init(_ text: String) { self.text = text }
    public init(_ resource: LocalizedStringResource) { self.text = resource.key }
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
    public typealias Value = Never
    public typealias Dialog = IntentDialog
    public typealias Snippet = Never
    public typealias OpensAppIntent = Never

    public let dialog: IntentDialog?

    public init(dialog: IntentDialog? = nil) {
        self.dialog = dialog
    }
}

public struct IntentResultContainer<ResultValue, OpensType, SnippetType, DialogType>:
    IntentResult, Sendable
    where ResultValue: _IntentValue, OpensType: AppIntent
{
    public typealias Value = ResultValue
    public typealias OpensAppIntent = OpensType
    public typealias Snippet = SnippetType
    public typealias Dialog = DialogType

    public var storedValue: ResultValue?
    public var dialog: IntentDialog?
    public var opensIntent: (any AppIntent)?

    public init(
        value: ResultValue? = nil,
        dialog: IntentDialog? = nil,
        opensIntent: (any AppIntent)? = nil
    ) {
        self.storedValue = value
        self.dialog = dialog
        self.opensIntent = opensIntent
    }

    public var value: ResultValue? { storedValue }
}

extension IntentResultContainer: ProvidesDialog where DialogType == IntentDialog {}
extension IntentResultContainer: ShowsSnippetView where SnippetType == _SnippetViewContainer {}
extension IntentResultContainer: ShowsSnippetIntent where SnippetType == _SnippetIntentContainer {}
extension IntentResultContainer: OpensIntent {}
extension IntentResultContainer: ReturnsValue {}

public extension IntentResult where Self == IntentResultValue {
    static func result() -> Self {
        .init()
    }

    static func result(dialog: IntentDialog) -> Self {
        .init(dialog: dialog)
    }
}

public protocol ParameterSummary {
    associatedtype Intent: AppIntent
}

public struct IntentParameterSummary<Intent: AppIntent>: ParameterSummary {
    public init() {}
}

public protocol AppIntent: PersistentlyIdentifiable, _SupportsAppDependencies, Sendable {
    associatedtype PerformResult: IntentResult
    associatedtype SummaryContent: ParameterSummary = IntentParameterSummary<Self>
    static var title: LocalizedStringResource { get }
    static var description: IntentDescription? { get }
    static var openAppWhenRun: Bool { get }
    static var isDiscoverable: Bool { get }
    static var supportedModes: IntentModes { get }
    static var authenticationPolicy: IntentAuthenticationPolicy { get }
    static var parameterSummary: Self.SummaryContent { get }
    func perform() async throws -> PerformResult
}

extension AppIntent {
    public static var title: LocalizedStringResource {
        LocalizedStringResource(String(describing: Self.self))
    }
    public static var description: IntentDescription? { nil }
    public static var openAppWhenRun: Bool { false }
    public static var isDiscoverable: Bool { true }
    public static var supportedModes: IntentModes { .background }
    public static var authenticationPolicy: IntentAuthenticationPolicy { .alwaysAllowed }
    public static var parameterSummary: IntentParameterSummary<Self> {
        IntentParameterSummary()
    }

    public var systemContext: IntentSystemContext { IntentSystemContext() }

    @discardableResult
    public func donate() -> IntentDonationIdentifier {
        IntentDonationManager.shared.recordLocal(self)
    }

    @discardableResult
    public func donate() async throws -> IntentDonationIdentifier {
        IntentDonationManager.shared.recordLocal(self)
    }

    @discardableResult
    public func donate(result: some IntentResult) -> IntentDonationIdentifier {
        _ = result
        return IntentDonationManager.shared.recordLocal(self)
    }

    @discardableResult
    public func donate(result: some IntentResult) async throws -> IntentDonationIdentifier {
        _ = result
        return IntentDonationManager.shared.recordLocal(self)
    }

    public func requestConfirmation() async throws {
        throw AppIntentError.Unrecoverable.unsupportedOnDevice
    }

    public func requestConfirmation(
        conditions: ConfirmationConditions = [],
        actionName: ConfirmationActionName = .continue,
        dialog: IntentDialog
    ) async throws {
        _ = conditions
        _ = actionName
        _ = dialog
        throw AppIntentError.Unrecoverable.unsupportedOnDevice
    }

    public func continueInForeground(
        _ dialog: IntentDialog? = nil,
        alwaysConfirm: Bool = true
    ) async throws {
        _ = dialog
        _ = alwaysConfirm
        throw AppIntentError.Unrecoverable.unsupportedOnDevice
    }

    public func needsToContinueInForegroundError(
        _ dialog: IntentDialog? = nil,
        alwaysConfirm: Bool = true
    ) -> AppIntentError {
        _ = dialog
        _ = alwaysConfirm
        return .Unrecoverable.unsupportedOnDevice
    }

    public func requestChoice(
        between options: [IntentChoiceOption],
        dialog: IntentDialog? = nil
    ) async throws -> IntentChoiceOption {
        _ = dialog
        guard let first = options.first else {
            throw AppIntentError.Unrecoverable.entityNotFound
        }
        return first
    }
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
    public init(_ resource: LocalizedStringResource) { self.text = resource.key }
    public init(stringLiteral value: String) { self.init(value) }
}

public struct TypeDisplayRepresentation: Sendable, Hashable,
    ExpressibleByStringLiteral
{
    public let name: String

    public init(name: String) { self.name = name }
    public init(name: LocalizedStringResource) { self.name = name.key }
    public init(stringLiteral value: String) { self.init(name: value) }
}

public struct DisplayRepresentation: @unchecked Sendable, Hashable,
    ExpressibleByStringLiteral
{
    public struct Image: @unchecked Sendable, Hashable {
        public let systemName: String
        public let isTemplate: Bool?
        public let data: Data?
        public let url: URL?

        public struct DisplayStyle: Hashable, Sendable {
            public let rawValue: String
            public static let `default` = DisplayStyle(rawValue: "default")
            public static let circular = DisplayStyle(rawValue: "circular")
        }

        public init(systemName: String, isTemplate: Bool? = nil) {
            self.systemName = systemName
            self.isTemplate = isTemplate
            self.data = nil
            self.url = nil
        }

        public init(data: Data, isTemplate: Bool? = nil, displayStyle: DisplayStyle = .default) {
            self.systemName = ""
            self.isTemplate = isTemplate
            self.data = data
            self.url = nil
            _ = displayStyle
        }

        public init(data: Data, isTemplate: Bool? = nil) {
            self.init(data: data, isTemplate: isTemplate, displayStyle: .default)
        }

        public init(url: URL, isTemplate: Bool? = nil, displayStyle: DisplayStyle = .default) {
            self.systemName = ""
            self.isTemplate = isTemplate
            self.data = nil
            self.url = url
            _ = displayStyle
        }

        public init(url: URL, isTemplate: Bool? = nil) {
            self.init(url: url, isTemplate: isTemplate, displayStyle: .default)
        }

        public init(
            url: URL,
            width: Double,
            height: Double,
            isTemplate: Bool? = nil,
            displayStyle: DisplayStyle = .default
        ) {
            self.init(url: url, isTemplate: isTemplate, displayStyle: displayStyle)
            _ = width
            _ = height
        }

        public init(
            url: URL,
            width: Double,
            height: Double,
            isTemplate: Bool? = nil
        ) {
            self.init(url: url, width: width, height: height, isTemplate: isTemplate, displayStyle: .default)
        }

        public init(named name: String, isTemplate: Bool? = nil, displayStyle: DisplayStyle = .default) {
            self.init(systemName: name, isTemplate: isTemplate)
            _ = displayStyle
        }

        public init(named name: String, isTemplate: Bool? = nil) {
            self.init(named: name, isTemplate: isTemplate, displayStyle: .default)
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let name = (try? container.decode(String.self)) ?? ""
            self.init(systemName: name)
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(systemName)
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
            self.data = nil
            self.url = nil
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
            self.data = nil
            self.url = nil
            _ = tintColor
        }
        #else
        public init?(
            systemName: String,
            tintColor: UIColor? = nil,
            symbolConfiguration: UIImage.SymbolConfiguration? = nil
        ) {
            guard !systemName.isEmpty else { return nil }
            self.systemName = systemName
            self.isTemplate = symbolConfiguration == nil ? nil : true
            self.data = nil
            self.url = nil
            _ = tintColor
        }
        #endif
    }

    public let title: LocalizedStringResource
    public let subtitle: LocalizedStringResource?
    public let image: Image?
    public let synonyms: [LocalizedStringResource]

    public init(
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource? = nil,
        image: Image? = nil,
        synonyms: [LocalizedStringResource] = []
    ) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
        self.synonyms = synonyms
    }

    public init(title: String, subtitle: String? = nil, image: Image? = nil) {
        self.init(
            title: LocalizedStringResource(title),
            subtitle: subtitle.map { LocalizedStringResource($0) },
            image: image
        )
    }

    public init(stringLiteral value: String) {
        self.init(title: value)
    }
}

// MARK: - Modes, errors, donation

public struct IntentModes: OptionSet, Hashable, Sendable, ExpressibleByArrayLiteral {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let background = IntentModes(rawValue: 1 << 0)
    public static let foreground = IntentModes(rawValue: 1 << 1)

    public struct ForegroundMode: Hashable, Sendable {
        public let rawValue: UInt8
        public static let immediate = ForegroundMode(rawValue: 0)
        public static let deferred = ForegroundMode(rawValue: 1)
        public static let dynamic = ForegroundMode(rawValue: 2)
    }

    public static func foreground(_ foregroundMode: ForegroundMode) -> IntentModes {
        _ = foregroundMode
        return .foreground
    }

    public struct Current: Hashable, Sendable, CustomDebugStringConvertible {
        public static let background = Current(kind: 0)
        public static let foreground = Current(kind: 1)
        public let kind: UInt8
        public var canContinueInForeground: Bool { kind == 1 }
        public var debugDescription: String { kind == 1 ? "foreground" : "background" }
        private init(kind: UInt8) { self.kind = kind }
    }
}

public enum IntentAuthenticationPolicy: Sendable, Hashable {
    case alwaysAllowed
    case requiresAuthentication
    case requiresLocalDeviceAuthentication
}

public struct AppIntentError: Error, Hashable, Sendable, CustomStringConvertible {
    public let code: String
    public var description: String { code }
    public var localizedStringResource: LocalizedStringResource {
        LocalizedStringResource(code)
    }

    public static var restartPerform: AppIntentError { AppIntentError(code: "restartPerform") }

    public enum Unrecoverable: Sendable {
        public static let unknown = AppIntentError(code: "unknown")
        public static let notAllowed = AppIntentError(code: "notAllowed")
        public static let entityNotFound = AppIntentError(code: "entityNotFound")
        public static let networkFailure = AppIntentError(code: "networkFailure")
        public static let partialFailure = AppIntentError(code: "partialFailure")
        public static let unsupportedOnDevice = AppIntentError(code: "unsupportedOnDevice")
        public static let featureCurrentlyRestricted = AppIntentError(code: "featureCurrentlyRestricted")
    }

    public enum PermissionRequired: Sendable {
        public static let siri = AppIntentError(code: "siri")
        public static let photos = AppIntentError(code: "photos")
        public static let contacts = AppIntentError(code: "contacts")
        public static let bluetooth = AppIntentError(code: "bluetooth")
        public static let localNetwork = AppIntentError(code: "localNetwork")
        public static func location(precise: Bool = false) -> AppIntentError {
            AppIntentError(code: precise ? "locationPrecise" : "location")
        }
    }

    public enum UserActionRequired: Sendable {
        public static let signin = AppIntentError(code: "signin")
        public static let confirmation = AppIntentError(code: "confirmation")
        public static let accountSetup = AppIntentError(code: "accountSetup")
    }
}

public struct IntentDonationIdentifier: Hashable, Sendable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
}

public struct IntentDonationManager: Sendable {
    public static let shared = IntentDonationManager()

    private static let lock = NSLock()
    private static var identifiers: [IntentDonationIdentifier] = []

    public init() {}

    public func deleteDonations(matching predicate: IntentDonationMatchingPredicate) async throws {
        _ = predicate
        Self.resetLocalDonations()
    }

    fileprivate func recordLocal(_ intent: any AppIntent) -> IntentDonationIdentifier {
        let identifier = IntentDonationIdentifier(
            "local.\(type(of: intent)).\(Self.identifiers.count)"
        )
        Self.lock.lock()
        Self.identifiers.append(identifier)
        Self.lock.unlock()
        return identifier
    }

    public static var recordedLocalDonations: [IntentDonationIdentifier] {
        lock.lock()
        defer { lock.unlock() }
        return identifiers
    }

    public static func resetLocalDonations() {
        lock.lock()
        identifiers.removeAll()
        lock.unlock()
    }
}

public struct IntentDonationMatchingPredicate: Sendable {
    public init() {}
}

public struct IntentSystemContext: Sendable {
    public var currentMode: IntentModes.Current { .background }
    public init() {}
}

public struct IntentChoiceOption: Hashable, Sendable {
    public var title: LocalizedStringResource
    public struct Style: Hashable, Sendable {
        public static let `default` = Style()
        public init() {}
    }
    public init(title: LocalizedStringResource, style: Style = .default) {
        self.title = title
        _ = style
    }
}

public struct ConfirmationActionName: Hashable, Sendable {
    public let rawValue: String
    public static let `continue` = ConfirmationActionName(rawValue: "continue")
    public static let cancel = ConfirmationActionName(rawValue: "cancel")
    public static let ok = ConfirmationActionName(rawValue: "ok")
    public static let confirm = ConfirmationActionName(rawValue: "confirm")
    public static let destructive = ConfirmationActionName(rawValue: "destructive")
}

public struct ConfirmationConditions: OptionSet, Hashable, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let lowConfidenceSource = ConfirmationConditions(rawValue: 1 << 0)
}

// MARK: - Parameters and files

public enum InputConnectionBehavior: Sendable, Hashable {
    case connectToPreviousIntentResult
    case never
    case `default`
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
public final class IntentParameter<Value>: @unchecked Sendable
    where Value: _IntentValue, Value: Sendable
{
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
        set { storage.state = .value(newValue) }
    }

    public var projectedValue: IntentParameter<Value> { self }

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

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior? = nil
    ) {
        self.init(
            title: title.key,
            description: description?.key,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public func needsValueError(_ dialog: IntentDialog? = nil) -> AppIntentError {
        _ = dialog
        return .Unrecoverable.entityNotFound
    }

    public func needsDisambiguationError(
        among itemsToDisambiguate: [Value.ValueType],
        dialog: IntentDialog? = nil
    ) -> AppIntentError {
        _ = itemsToDisambiguate
        _ = dialog
        return .Unrecoverable.entityNotFound
    }
}

public typealias Parameter = IntentParameter

@propertyWrapper
public final class IntentParameterDependency<Intent: AppIntent>: @unchecked Sendable {
    private final class Storage: @unchecked Sendable {
        var value: Intent?
    }

    private let storage = Storage()

    public var wrappedValue: Intent? {
        get { storage.value }
        set { storage.value = newValue }
    }

    public init<Value>(_ keyPath: KeyPath<Intent, IntentParameter<Value>>) {
        _ = keyPath
    }
}

public struct IntentFile: @unchecked Sendable, Hashable {
    public let data: Data
    public let filename: String?
    public let fileURL: URL?
    public let type: IntentFileContentType?

    public enum IntentFileError: Error, Hashable, Sendable {
        case unreadable
        case unsupportedType
    }

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

public protocol AppEnum: AppValue, StaticDisplayRepresentable, RawRepresentable
    where Self.RawValue: LosslessStringConvertible
{
    static var typeDisplayRepresentation: TypeDisplayRepresentation { get }
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] { get }
}

public protocol AppEntity: AppValue, DisplayRepresentable, Identifiable
    where Self.ID: EntityIdentifierConvertible, Self.ID: Sendable
{
    associatedtype DefaultQuery: EntityQuery where DefaultQuery.Entity == Self
    static var defaultQuery: DefaultQuery { get }
    static var typeDisplayRepresentation: TypeDisplayRepresentation { get }
    var displayRepresentation: DisplayRepresentation { get }
}

public protocol ResultsCollection<Result> {
    associatedtype Result: _IntentValue
}

extension Array: ResultsCollection where Element: _IntentValue {
    public typealias Result = Element
}

public protocol DynamicOptionsProvider: _SupportsAppDependencies {
    associatedtype Result: ResultsCollection
    associatedtype DefaultValue: _IntentValue = Result.Result
    func results() async throws -> Self.Result
    func defaultResult() async -> DefaultValue?
}

extension DynamicOptionsProvider {
    public func defaultResult() async -> DefaultValue? { nil }
}

public protocol EntityQuery: DynamicOptionsProvider, PersistentlyIdentifiable, Sendable {
    associatedtype Entity: AppEntity
    associatedtype Result = [Entity]
    func entities(for identifiers: [Entity.ID]) async throws -> [Entity]
    func suggestedEntities() async throws -> [Entity]
    func defaultResult() async -> Entity?
}

public extension EntityQuery {
    func suggestedEntities() async throws -> [Entity] { [] }
    func defaultResult() async -> Entity? { nil }
    func results() async throws -> [Entity] {
        try await suggestedEntities()
    }
}

public protocol EnumerableEntityQuery: EntityQuery {
    func allEntities() async throws -> [Entity]
}

public protocol EntityStringQuery: EntityQuery {
    func entities(matching string: String) async throws -> [Entity]
}

public protocol UniqueAppEntityQuery: EnumerableEntityQuery where Entity: UniqueAppEntity {
    associatedtype Unique where Entity == Unique
    func uniqueEntity() async throws -> Unique
}

public protocol UniqueAppEntity: AppEntity where DefaultQuery: UniqueAppEntityQuery {}

public protocol TransientAppEntity: AppEntity {
    init()
}

public protocol FileEntity: AppEntity where ID == FileEntityIdentifier {}

public struct FileEntityIdentifier: Hashable, Sendable, EntityIdentifierConvertible {
    public let url: URL
    public init(_ url: URL) { self.url = url }
}

public protocol IndexedEntity: AppEntity {}
public protocol AssistantEntity: AppEntity {}
public protocol AssistantEnum: AppEnum {}
public protocol AssistantIntent: AppIntent {}
public protocol AssistantSchemaEnum: AssistantEnum {}
public protocol AssistantSchemaEntity: AssistantEntity {}
public protocol AssistantSchemaIntent: AssistantIntent {}

// MARK: - Widgets and shortcuts

public protocol SystemIntent: AppIntent {}

public protocol WidgetConfigurationIntent: AppIntent {}

public extension WidgetConfigurationIntent where PerformResult == IntentResultValue {
    func perform() async throws -> IntentResultValue {
        .result()
    }
}

public protocol ControlConfigurationIntent: AppIntent {}

public enum AppShortcutPhraseToken: Sendable, Hashable {
    case applicationName
}

public struct AppShortcutPhrase<Intent: AppIntent>: Sendable, Hashable,
    ExpressibleByStringLiteral, ExpressibleByStringInterpolation
{
    public let template: String

    public init(_ value: String) { template = value }
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
            value += token == .applicationName ? "${applicationName}" : ""
        }

        public mutating func appendInterpolation<Value, Subject>(_ subject: Subject)
            where Value: _IntentValue, Value: Sendable,
            Subject: KeyPath<Intent, IntentParameter<Value>>
        {
            _ = subject
            value += "${parameter}"
        }
    }
}

public struct AppShortcut: @unchecked Sendable {
    public let intent: any AppIntent
    public let phrases: [AppShortcutPhrase<Never>]
    public let shortTitle: String
    public let systemImageName: String

    public init<I: AppIntent>(
        intent: I,
        phrases: [AppShortcutPhrase<I>],
        shortTitle: String,
        systemImageName: String
    ) {
        self.intent = intent
        self.phrases = phrases.map { AppShortcutPhrase<Never>($0.template) }
        self.shortTitle = shortTitle
        self.systemImageName = systemImageName
    }

    public init<I: AppIntent>(
        intent: I,
        phrases: [AppShortcutPhrase<I>],
        shortTitle: LocalizedStringResource,
        systemImageName: String
    ) {
        self.init(
            intent: intent,
            phrases: phrases,
            shortTitle: shortTitle.key,
            systemImageName: systemImageName
        )
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

public protocol AppShortcutsProvider: Sendable {
    @AppShortcutsBuilder static var appShortcuts: [AppShortcut] { get }
    static var shortcutTileColor: ShortcutTileColor { get }
}

extension AppShortcutsProvider {
    public static var shortcutTileColor: ShortcutTileColor { .navy }
}

public enum ShortcutTileColor: Sendable, Hashable {
    case red, blue, lime, navy, pink, teal, grape, orange, purple, yellow
    case grayBlue, grayBrown, grayGreen, lightBlue, tangerine
}

public enum AppIntentsPortable {
    /// There is no system Shortcuts registrar in the Linux guest. Descriptions
    /// and executable intent values remain available to an embedding host.
    public static let supportsSystemRegistration = false
}

// MARK: - Built-in intent values

extension Never: _IntentValue, AppIntent {
    public static var title: LocalizedStringResource { LocalizedStringResource("Never") }
    public func perform() async throws -> IntentResultValue { .result() }
}

extension String: _IntentValue, AppValue {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation { "String" }
}

extension Int: _IntentValue, AppValue {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation { "Int" }
}

extension Bool: _IntentValue, AppValue {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation { "Bool" }
}

extension Double: _IntentValue, AppValue {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation { "Double" }
}

extension Float: _IntentValue {
}

extension Decimal: _IntentValue {}
extension URL: _IntentValue, AppValue {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation { "URL" }
}
extension Date: _IntentValue, AppValue {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation { "Date" }
}
extension UUID: _IntentValue {}
extension Data: _IntentValue {}
extension AttributedString: _IntentValue {}
extension DateComponents: _IntentValue {}
extension IntentFile: _IntentValue {}
extension IntentDialog: _IntentValue {}
extension Optional: _IntentValue where Wrapped: _IntentValue {}
extension Array: _IntentValue where Element: _IntentValue {}

public struct OpenURLIntent: AppIntent {
    public var url: URL
    public init(_ url: URL) { self.url = url }
    public init() { self.url = URL(fileURLWithPath: "/") }
    public static var title: LocalizedStringResource { "Open URL" }
    public func perform() async throws -> IntentResultValue {
        .result()
    }
}

public struct EmptySnippetIntent: AppIntent, SnippetIntent {
    public init() {}
    public static var title: LocalizedStringResource { "Empty Snippet" }
    public func perform() async throws -> IntentResultValue { .result() }
}

public protocol SnippetIntent: AppIntent {}

public protocol DeprecatedAppIntent: AppIntent {
    associatedtype ReplacementIntent: AppIntent = Never
    static var deprecation: IntentDeprecation<ReplacementIntent> { get }
}

extension DeprecatedAppIntent {
    public static var deprecation: IntentDeprecation<Never> {
        IntentDeprecation()
    }
}

public struct IntentDeprecation<ReplacementIntent: AppIntent>: Sendable {
    public init() {}
}

public protocol CustomIntentMigratedAppIntent: AppIntent {
    static var intentClassName: String { get }
}

extension CustomIntentMigratedAppIntent {
    public static var persistentIdentifier: String { intentClassName }
}
