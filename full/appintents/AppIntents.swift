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
    public let supporting: String?
    public let systemImageName: String?

    public var full: String { text }

    public init(_ text: String) {
        self.text = text
        self.supporting = nil
        self.systemImageName = nil
    }

    public init(_ resource: LocalizedStringResource) { self.init(appIntentsString(resource)) }

    public init(full: LocalizedStringResource, supporting: LocalizedStringResource) {
        self.text = appIntentsString(full)
        self.supporting = appIntentsString(supporting)
        self.systemImageName = nil
    }

    public init(full: LocalizedStringResource, systemImageName: String) {
        self.text = appIntentsString(full)
        self.supporting = nil
        self.systemImageName = systemImageName
    }

    public init(
        full: LocalizedStringResource,
        supporting: LocalizedStringResource,
        systemImageName: String
    ) {
        self.text = appIntentsString(full)
        self.supporting = appIntentsString(supporting)
        self.systemImageName = systemImageName
    }

    public init(stringLiteral value: String) { self.init(value) }
    public init(stringInterpolation: StringInterpolation) {
        self.init(stringInterpolation.value)
    }

    public typealias StringLiteralType = String
    public typealias UnicodeScalarLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = String

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
    /// Portable empty / dialog-only factories stay on `IntentResultValue` so
    /// `EchoIntent.perform()` still infers that type (testIntentPerformEcho,
    /// testIntentDialogAndResultFactories). Apple's `IntentResultContainer`
    /// overloads for the same spellings are not substituted in.
    static func result() -> Self {
        .init()
    }

    static func result(dialog: IntentDialog) -> Self {
        .init(dialog: dialog)
    }
}

public extension IntentResult {
    static func result<Value: _IntentValue>(
        value: Value
    ) -> IntentResultContainer<Value, Never, Never, Never>
    where Self == IntentResultContainer<Value, Never, Never, Never> {
        IntentResultContainer(value: value)
    }

    static func result<Value: _IntentValue>(
        value: Value,
        dialog: IntentDialog
    ) -> IntentResultContainer<Value, Never, Never, IntentDialog>
    where Self == IntentResultContainer<Value, Never, Never, IntentDialog> {
        IntentResultContainer(value: value, dialog: dialog)
    }

    static func result<OpensAppIntent: AppIntent>(
        opensIntent: OpensAppIntent
    ) -> IntentResultContainer<Never, OpensAppIntent, Never, Never>
    where Self == IntentResultContainer<Never, OpensAppIntent, Never, Never> {
        IntentResultContainer(opensIntent: opensIntent)
    }

    static func result<OpensAppIntent: AppIntent>(
        opensIntent: OpensAppIntent,
        dialog: IntentDialog
    ) -> IntentResultContainer<Never, OpensAppIntent, Never, IntentDialog>
    where Self == IntentResultContainer<Never, OpensAppIntent, Never, IntentDialog> {
        IntentResultContainer(dialog: dialog, opensIntent: opensIntent)
    }
}

public protocol ParameterSummary {
    associatedtype Intent: AppIntent
    var evaluatedDisplayString: String { get }
}

extension ParameterSummary {
    public var evaluatedDisplayString: String { "" }
}

public struct IntentParameterSummary<Intent: AppIntent>: ParameterSummary,
    ExpressibleByStringLiteral, ExpressibleByStringInterpolation
{
    public let evaluatedDisplayString: String

    public init() { evaluatedDisplayString = "" }

    public init(_ string: ParameterSummaryString<Intent>, table: String? = nil) {
        evaluatedDisplayString = string.evaluatedDisplayString
        _ = table
    }

    public init(
        _ string: ParameterSummaryString<Intent>,
        table: String? = nil,
        @ParameterKeyPathsBuilder _ additionalParameterKeyPaths: () -> [PartialKeyPath<Intent>]
    ) {
        evaluatedDisplayString = string.evaluatedDisplayString
        _ = table
        _ = additionalParameterKeyPaths()
    }

    public init(
        @ParameterKeyPathsBuilder _ additionalParameterKeyPaths: () -> [PartialKeyPath<Intent>]
    ) {
        evaluatedDisplayString = ""
        _ = additionalParameterKeyPaths()
    }

    public init(stringLiteral value: String) { evaluatedDisplayString = value }
    public init(stringInterpolation: StringInterpolation) {
        evaluatedDisplayString = stringInterpolation.value
    }

    public typealias StringLiteralType = String
    public typealias UnicodeScalarLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = String

    public struct StringInterpolation: StringInterpolationProtocol {
        fileprivate var value = ""
        public init(literalCapacity: Int, interpolationCount: Int) {
            value.reserveCapacity(literalCapacity + interpolationCount * 12)
        }
        public mutating func appendLiteral(_ literal: String) { value += literal }
        public mutating func appendInterpolation<Value: _IntentValue>(
            _ keyPath: KeyPath<Intent, IntentParameter<Value>>
        ) {
            _ = keyPath
            value += "${parameter}"
        }
        public mutating func appendInterpolation<T>(_ other: T) {
            value += String(describing: other)
        }
    }

    @resultBuilder
    public enum ParameterKeyPathsBuilder {
        public static func buildBlock(_ blocks: PartialKeyPath<Intent>...) -> [PartialKeyPath<Intent>] {
            Array(blocks)
        }

        public static func buildExpression<ValueType>(
            _ expression: KeyPath<Intent, IntentParameter<ValueType>>
        ) -> PartialKeyPath<Intent>
        where ValueType: _IntentValue, ValueType: Sendable {
            expression
        }
    }
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
    public typealias Parameter = IntentParameter
    public typealias Summary = IntentParameterSummary<Self>
    public typealias Option = IntentChoiceOption
    public typealias Case = ParameterSummaryCaseCondition
    public typealias When = ParameterSummaryWhenCondition
    public typealias Switch<Value, CaseCondition> = ParameterSummarySwitchCondition<Self, Value, CaseCondition>
        where Value: _IntentValue, CaseCondition: _ParameterSummarySwitchCase
    public typealias DefaultCase = ParameterSummaryDefaultCaseCondition

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

    @discardableResult
    public func perform(_ intent: any AppIntent) async throws -> any IntentResult {
        executionCount &+= 1
        return try await intent.perform()
    }
}

// MARK: - Descriptions

public struct IntentDescription: Sendable, ExpressibleByStringLiteral {
    public let text: String
    public let categoryName: LocalizedStringResource?
    public let searchKeywords: [LocalizedStringResource]
    public let resultValueName: LocalizedStringResource?

    public var descriptionText: LocalizedStringResource {
        LocalizedStringResource(text)
    }

    public init(_ text: String) {
        self.text = text
        self.categoryName = nil
        self.searchKeywords = []
        self.resultValueName = nil
    }

    public init(_ resource: LocalizedStringResource) {
        self.init(appIntentsString(resource))
    }

    public init(
        _ descriptionText: LocalizedStringResource,
        categoryName: LocalizedStringResource? = nil,
        searchKeywords: [LocalizedStringResource] = []
    ) {
        self.text = appIntentsString(descriptionText)
        self.categoryName = categoryName
        self.searchKeywords = searchKeywords
        self.resultValueName = nil
    }

    public init(
        _ descriptionText: LocalizedStringResource,
        categoryName: LocalizedStringResource? = nil,
        searchKeywords: [LocalizedStringResource] = [],
        resultValueName: LocalizedStringResource?
    ) {
        self.text = appIntentsString(descriptionText)
        self.categoryName = categoryName
        self.searchKeywords = searchKeywords
        self.resultValueName = resultValueName
    }

    public init(stringLiteral value: String) { self.init(value) }

    public typealias StringLiteralType = String
    public typealias UnicodeScalarLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = String
}

public struct TypeDisplayRepresentation: Sendable, ExpressibleByStringLiteral
{
    public let name: String
    public let numericFormat: LocalizedStringResource?
    public let synonyms: [LocalizedStringResource]

    public init(name: String) {
        self.name = name
        self.numericFormat = nil
        self.synonyms = []
    }

    public init(name: LocalizedStringResource) {
        self.init(name: appIntentsString(name))
    }

    public init(
        name: LocalizedStringResource,
        numericFormat: LocalizedStringResource? = nil
    ) {
        self.name = appIntentsString(name)
        self.numericFormat = numericFormat
        self.synonyms = []
    }

    public init(
        name: LocalizedStringResource,
        numericFormat: LocalizedStringResource? = nil,
        synonyms: [LocalizedStringResource] = []
    ) {
        self.name = appIntentsString(name)
        self.numericFormat = numericFormat
        self.synonyms = synonyms
    }

    public init(stringLiteral value: String) { self.init(name: value) }

    public typealias StringLiteralType = String
    public typealias UnicodeScalarLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = String
}

public struct DisplayRepresentation: @unchecked Sendable, ExpressibleByStringLiteral
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

    public typealias StringLiteralType = String
    public typealias UnicodeScalarLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = String
}

extension DisplayRepresentation: Hashable {
    public static func == (lhs: DisplayRepresentation, rhs: DisplayRepresentation) -> Bool {
        String(describing: lhs.title) == String(describing: rhs.title)
            && String(describing: lhs.subtitle) == String(describing: rhs.subtitle)
            && lhs.image == rhs.image
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(String(describing: title))
        hasher.combine(String(describing: subtitle))
        hasher.combine(image)
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

public struct IntentChoiceOption: Sendable {
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

extension IntentChoiceOption: Hashable {
    public static func == (lhs: IntentChoiceOption, rhs: IntentChoiceOption) -> Bool {
        String(describing: lhs.title) == String(describing: rhs.title)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(String(describing: title))
    }
}

public struct ConfirmationActionName: Hashable, Sendable {
    public let rawValue: String
    public static let `continue` = ConfirmationActionName(rawValue: "continue")
    public static let cancel = ConfirmationActionName(rawValue: "cancel")
    public static let ok = ConfirmationActionName(rawValue: "ok")
    public static let confirm = ConfirmationActionName(rawValue: "confirm")
    public static let destructive = ConfirmationActionName(rawValue: "destructive")
    public static let startNavigation = ConfirmationActionName(rawValue: "startNavigation")
    public static let `do` = ConfirmationActionName(rawValue: "do")
    public static let go = ConfirmationActionName(rawValue: "go")
    public static let add = ConfirmationActionName(rawValue: "add")
    public static let buy = ConfirmationActionName(rawValue: "buy")
    public static let get = ConfirmationActionName(rawValue: "get")
    public static let log = ConfirmationActionName(rawValue: "log")
    public static let pay = ConfirmationActionName(rawValue: "pay")
    public static let run = ConfirmationActionName(rawValue: "run")
    public static let set = ConfirmationActionName(rawValue: "set")
    public static let book = ConfirmationActionName(rawValue: "book")
    public static let call = ConfirmationActionName(rawValue: "call")
    public static let find = ConfirmationActionName(rawValue: "find")
    public static let open = ConfirmationActionName(rawValue: "open")
    public static let play = ConfirmationActionName(rawValue: "play")
    public static let post = ConfirmationActionName(rawValue: "post")
    public static let send = ConfirmationActionName(rawValue: "send")
    public static let view = ConfirmationActionName(rawValue: "view")
    public static let order = ConfirmationActionName(rawValue: "order")
    public static let share = ConfirmationActionName(rawValue: "share")
    public static let start = ConfirmationActionName(rawValue: "start")
    public static let create = ConfirmationActionName(rawValue: "create")
    public static let filter = ConfirmationActionName(rawValue: "filter")
    public static let search = ConfirmationActionName(rawValue: "search")
    public static let toggle = ConfirmationActionName(rawValue: "toggle")
    public static let turnOn = ConfirmationActionName(rawValue: "turnOn")
    public static let addData = ConfirmationActionName(rawValue: "addData")
    public static let checkIn = ConfirmationActionName(rawValue: "checkIn")
    public static let request = ConfirmationActionName(rawValue: "request")
    public static let turnOff = ConfirmationActionName(rawValue: "turnOff")
    public static let download = ConfirmationActionName(rawValue: "download")
    public static let playSound = ConfirmationActionName(rawValue: "playSound")

    public static func custom(
        acceptLabel: LocalizedStringResource,
        acceptAlternatives: [LocalizedStringResource],
        denyLabel: LocalizedStringResource,
        denyAlternatives: [LocalizedStringResource],
        destructive: Bool = false
    ) -> ConfirmationActionName {
        _ = acceptAlternatives
        _ = denyLabel
        _ = denyAlternatives
        _ = destructive
        return ConfirmationActionName(rawValue: "custom:" + appIntentsString(acceptLabel))
    }
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

protocol _OptionalIntentValue {
    static var _none: Any { get }
}

extension Optional: _OptionalIntentValue {
    static var _none: Any { Self.none as Any }
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

    public enum IntControlStyle: Sendable, Hashable {
        case field
        case stepper
    }

    public enum DoubleControlStyle: Sendable, Hashable {
        case field
        case slider
        case stepper
    }

    public typealias InclusiveRange<Bound: Comparable> = (lowerBound: Bound, upperBound: Bound)

    private let storage: _ParameterStorage<Value>
    public let metadata: Metadata
    var defaultValue: Value?
    var storedIntControlStyle: IntControlStyle?
    var storedDoubleControlStyle: DoubleControlStyle?
    var storedInclusiveRange: (lowerBound: String, upperBound: String)?
    var storedDateKind: DateKind?
    var storedInputOptionsBox: Any?
    var storedResolvedOptions: [Any] = []
    var optionsProviderAttached = false

    public var dateKind: DateKind? { storedDateKind }

    public var wrappedValue: Value {
        get {
            switch storage.state {
            case let .value(value):
                return value
            case .unset:
                if let defaultValue {
                    return defaultValue
                }
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
        self.defaultValue = nil
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Value? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior? = nil
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        self.defaultValue = defaultValue
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

    public enum ValueState: Sendable {
        case set(Value)
        case unset
    }

    public var valueState: ValueState {
        switch storage.state {
        case let .value(value):
            return .set(value)
        case .unset:
            return .unset
        }
    }

    public var isOptional: Bool {
        Value.self is any _OptionalIntentValue.Type
    }

    /// Linux has no parameter prompt UI. Apple's async request throws after
    /// a system dialog; this host returns unsupportedOnDevice.
    public func requestValue(_ dialog: IntentDialog? = nil) async throws -> Value.ValueType {
        _ = dialog
        throw AppIntentError.Unrecoverable.unsupportedOnDevice
    }

    public func requestValue(_ dialog: IntentDialog? = nil) -> any Error {
        _ = dialog
        return AppIntentError.Unrecoverable.unsupportedOnDevice
    }

    public func requestDisambiguation(
        among itemsToDisambiguate: [Value.ValueType],
        dialog: IntentDialog? = nil
    ) async throws -> Value.ValueType {
        _ = itemsToDisambiguate
        _ = dialog
        throw AppIntentError.Unrecoverable.unsupportedOnDevice
    }

    public enum DateKind: Sendable, Hashable {
        case date
        case time
        case dateTime
    }

    public enum PlacemarkDisplayStyle: Sendable, Hashable {
        case city
        case name
        case address
    }
}

extension IntentParameter where Value == Int {
    public var controlStyle: IntControlStyle? { storedIntControlStyle }
    public var inclusiveRange: InclusiveRange<Int>? {
        guard let stored = storedInclusiveRange,
              let lower = Int(stored.lowerBound),
              let upper = Int(stored.upperBound) else {
            return nil
        }
        return (lower, upper)
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Int? = nil,
        controlStyle: IntControlStyle = .stepper,
        inclusiveRange: InclusiveRange<Int>? = nil,
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
        storedIntControlStyle = controlStyle
        if let inclusiveRange {
            storedInclusiveRange = (
                String(inclusiveRange.lowerBound),
                String(inclusiveRange.upperBound)
            )
        }
    }
}

extension IntentParameter where Value == Double {
    public var controlStyle: DoubleControlStyle? { storedDoubleControlStyle }
    public var inclusiveRange: InclusiveRange<Double>? {
        guard let stored = storedInclusiveRange,
              let lower = Double(stored.lowerBound),
              let upper = Double(stored.upperBound) else {
            return nil
        }
        return (lower, upper)
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Double? = nil,
        controlStyle: DoubleControlStyle = .stepper,
        inclusiveRange: InclusiveRange<Double>? = nil,
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
        storedDoubleControlStyle = controlStyle
        if let inclusiveRange {
            storedInclusiveRange = (
                String(inclusiveRange.lowerBound),
                String(inclusiveRange.upperBound)
            )
        }
    }
}

public typealias Parameter = IntentParameter

@propertyWrapper
public final class IntentParameterDependency<Intent: AppIntent>: @unchecked Sendable {
    private final class Storage: @unchecked Sendable {
        var projection: IntentProjection<Intent>?
    }

    private let storage = Storage()

    public var wrappedValue: IntentProjection<Intent>? {
        get { storage.projection }
        set { storage.projection = newValue }
    }

    public var debugDescription: String {
        String(describing: Intent.self)
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
    public var removedOnCompletion: Bool = false

    public enum IntentFileError: Error, Hashable, Sendable {
        case unreadable
        case unsupportedType
        case failedToLoadFile
        case failedToLoadData

        public static var errorDomain: String { "AppIntents.IntentFileError" }
        public var errorCode: Int {
            switch self {
            case .unreadable: return 1
            case .unsupportedType: return 2
            case .failedToLoadFile: return 3
            case .failedToLoadData: return 4
            }
        }
        public var errorUserInfo: [String: Any] { ["errorCode": errorCode] }
    }

    public static var typeDisplayRepresentation: TypeDisplayRepresentation { "File" }

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: filename ?? "file")
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
    init()
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

extension UniqueAppEntityQuery {
    public func allEntities() async throws -> [Entity] {
        [try await uniqueEntity()]
    }

    public func suggestedEntities() async throws -> [Entity] {
        try await allEntities()
    }

    public func entities(for identifiers: [Entity.ID]) async throws -> [Entity] {
        let entity = try await uniqueEntity()
        for identifier in identifiers {
            if identifier == entity.id {
                return [entity]
            }
        }
        return []
    }
}

public protocol UniqueAppEntity: AppEntity where DefaultQuery: UniqueAppEntityQuery {}

public protocol TransientAppEntity: AppEntity where ID == UUID {
    init()
}

public struct _TransientAppEntityQuery<Entity: TransientAppEntity>: EntityQuery, EnumerableEntityQuery {
    public typealias Result = [Entity]
    public init() {}

    public func entities(for identifiers: [Entity.ID]) async throws -> [Entity] {
        EntityResolutionEngine.entities(for: identifiers, as: Entity.self)
    }

    public func suggestedEntities() async throws -> [Entity] {
        EntityResolutionEngine.suggestedEntities(Entity.self)
    }

    public func defaultResult() async -> Entity? {
        EntityResolutionEngine.defaultResult(Entity.self)
    }

    public func allEntities() async throws -> [Entity] {
        EntityResolutionEngine.suggestedEntities(Entity.self)
    }
}

extension TransientAppEntity where DefaultQuery == _TransientAppEntityQuery<Self> {
    public static var defaultQuery: _TransientAppEntityQuery<Self> { _TransientAppEntityQuery() }
}

public protocol FileEntity: AppEntity where ID == FileEntityIdentifier {}

public struct FileEntityIdentifier: Hashable, Sendable, EntityIdentifierConvertible {
    public let url: URL
    public let draftIdentifier: String?

    public var isDraft: Bool { draftIdentifier != nil }

    public var entityIdentifierString: String {
        if let draftIdentifier {
            return "draft:" + draftIdentifier
        }
        return url.absoluteString
    }

    public init(_ url: URL) {
        self.url = url
        self.draftIdentifier = nil
    }

    private init(draft identifier: String) {
        self.url = URL(fileURLWithPath: "/tmp/appintents-draft/" + identifier)
        self.draftIdentifier = identifier
    }

    public static func file(url: URL) throws -> FileEntityIdentifier {
        FileEntityIdentifier(url)
    }

    public static func draft(identifier: String) -> FileEntityIdentifier {
        FileEntityIdentifier(draft: identifier)
    }

    public static func entityIdentifier(for entityIdentifierString: String) -> FileEntityIdentifier? {
        if entityIdentifierString.hasPrefix("draft:") {
            let token = String(entityIdentifierString.dropFirst(6))
            guard !token.isEmpty else { return nil }
            return .draft(identifier: token)
        }
        if entityIdentifierString.hasPrefix("/") {
            return FileEntityIdentifier(URL(fileURLWithPath: entityIdentifierString))
        }
        if let url = URL(string: entityIdentifierString), url.scheme != nil {
            return FileEntityIdentifier(url)
        }
        return nil
    }
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

    public typealias StringLiteralType = String
    public typealias UnicodeScalarLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = String

    public struct StringInterpolation: StringInterpolationProtocol {
        fileprivate var value = ""

        public init(literalCapacity: Int, interpolationCount: Int) {
            value.reserveCapacity(literalCapacity + interpolationCount * 12)
        }

        public mutating func appendLiteral(_ literal: String) { value += literal }

        public mutating func appendInterpolation(_ token: AppShortcutPhraseToken) {
            // Measured: "Add feed with \(.applicationName)" →
            // "Add feed with ${applicationName}"
            // (testAppShortcutBuilderUpdateAndApplicationNameToken, Linux swiftc).
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
            shortTitle: appIntentsString(shortTitle),
            systemImageName: systemImageName
        )
    }
}

@resultBuilder
public enum AppShortcutsBuilder {
    public static func buildBlock() -> [AppShortcut] { [] }

    public static func buildBlock(_ components: AppShortcut...) -> [AppShortcut] {
        components
    }

    public static func buildBlock(_ components: [AppShortcut]...) -> [AppShortcut] {
        components.flatMap { $0 }
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

    public static func buildExpression(_ component: AppShortcut) -> AppShortcut {
        component
    }

    public static func buildLimitedAvailability(_ components: [AppShortcut]) -> [AppShortcut] {
        components
    }
}

public protocol AppShortcutsProvider: Sendable {
    @AppShortcutsBuilder static var appShortcuts: [AppShortcut] { get }
    static var shortcutTileColor: ShortcutTileColor { get }
}

extension AppShortcutsProvider {
    public static var shortcutTileColor: ShortcutTileColor { .navy }
    public static var negativePhrases: NegativeAppShortcutPhrases { NegativeAppShortcutPhrases() }

    /// Linux has no Shortcuts daemon. Apple's call asks the system to
    /// re-extract parameter options; this is a documented no-op.
    public static func updateAppShortcutParameters() {}
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
