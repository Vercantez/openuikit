import Foundation

// Remaining portable @Parameter storage: title / defaultValue / collection
// size / displayName / search criteria. Options providers and resolvers
// attach metadata only. Linux never consults Shortcuts or a UTI daemon.

public struct HostEmptySearchCriteria: SearchCriteria, Hashable, Sendable, _IntentValue {
    public typealias SearchScopes = Void
    public init() {}
}

public struct HostShowStringSearchResultsIntent: ShowInAppSearchResultsIntent {
    public static var title: LocalizedStringResource { "Show Search" }
    public static var searchScopes: [StringSearchScope] { [.general, .movies] }
    public var criteria: StringSearchCriteria
    public init() { self.criteria = StringSearchCriteria(term: "") }
    public init(criteria: StringSearchCriteria) { self.criteria = criteria }
    public func perform() async throws -> IntentResultValue { .result() }
}

public struct HostShowVoidSearchResultsIntent: ShowInAppSearchResultsIntent {
    public static var title: LocalizedStringResource { "Show Void Search" }
    public var criteria: HostEmptySearchCriteria
    public init() { self.criteria = HostEmptySearchCriteria() }
    public func perform() async throws -> IntentResultValue { .result() }
}

// MARK: - Bool displayName

extension IntentParameter where Value == Bool {
    public var displayName: Bool.IntentDisplayName? { storedBoolDisplayName }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Bool? = nil,
        displayName: Bool.IntentDisplayName?,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        storedBoolDisplayName = displayName
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        default defaultValue: Bool? = nil,
        displayName: Bool.IntentDisplayName?,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            displayName: displayName,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Bool? = nil,
        displayName: Bool.IntentDisplayName?,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            displayName: displayName,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        default defaultValue: Bool? = nil,
        displayName: Bool.IntentDisplayName?,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            displayName: displayName,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }
}

// MARK: - Int / Double description + controlStyle

extension IntentParameter where Value == Int {
    public convenience init(
        description: LocalizedStringResource? = nil,
        default defaultValue: Int? = nil,
        controlStyle: IntControlStyle = .stepper,
        inclusiveRange: InclusiveRange<Int>? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            controlStyle: controlStyle,
            inclusiveRange: inclusiveRange,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        default defaultValue: Int? = nil,
        controlStyle: IntControlStyle = .stepper,
        inclusiveRange: InclusiveRange<Int>? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            description: description,
            default: defaultValue,
            controlStyle: controlStyle,
            inclusiveRange: inclusiveRange,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Int? = nil,
        controlStyle: IntControlStyle = .stepper,
        inclusiveRange: InclusiveRange<Int>? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            controlStyle: controlStyle,
            inclusiveRange: inclusiveRange,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }
}

extension IntentParameter where Value == Double {
    public convenience init(
        description: LocalizedStringResource? = nil,
        default defaultValue: Double? = nil,
        controlStyle: DoubleControlStyle = .stepper,
        inclusiveRange: InclusiveRange<Double>? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            controlStyle: controlStyle,
            inclusiveRange: inclusiveRange,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        default defaultValue: Double? = nil,
        controlStyle: DoubleControlStyle = .stepper,
        inclusiveRange: InclusiveRange<Double>? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            description: description,
            default: defaultValue,
            controlStyle: controlStyle,
            inclusiveRange: inclusiveRange,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Double? = nil,
        controlStyle: DoubleControlStyle = .stepper,
        inclusiveRange: InclusiveRange<Double>? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            controlStyle: controlStyle,
            inclusiveRange: inclusiveRange,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }
}

// MARK: - String remaining inputOptions

extension IntentParameter where Value == String {
    public convenience init(
        description: LocalizedStringResource? = nil,
        default defaultValue: String? = nil,
        inputOptions: String.IntentInputOptions? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            inputOptions: inputOptions,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        default defaultValue: String? = nil,
        inputOptions: String.IntentInputOptions? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            description: description,
            default: defaultValue,
            inputOptions: inputOptions,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: String? = nil,
        inputOptions: String.IntentInputOptions? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            inputOptions: inputOptions,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        inputOptions: String.IntentInputOptions? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            inputOptions: inputOptions,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        inputOptions: String.IntentInputOptions? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            description: description,
            inputOptions: inputOptions,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        inputOptions: String.IntentInputOptions? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            inputOptions: inputOptions,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
        _ = resolvers
    }
}

// MARK: - Date remaining

extension IntentParameter where Value == Date {
    public convenience init(
        description: LocalizedStringResource? = nil,
        default defaultValue: Date? = nil,
        kind: DateKind = .dateTime,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            kind: kind,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        kind: DateKind = .dateTime,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            kind: kind,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Date? = nil,
        kind: DateKind = .dateTime,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            kind: kind,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        default defaultValue: Date? = nil,
        kind: DateKind = .dateTime,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            kind: kind,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        kind: DateKind = .dateTime,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            kind: kind,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Date? = nil,
        kind: DateKind = .dateTime,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            kind: kind,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        default defaultValue: Date? = nil,
        kind: DateKind = .dateTime,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            kind: kind,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        kind: DateKind = .dateTime,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            kind: kind,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Date? = nil,
        kind: DateKind = .dateTime,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            kind: kind,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        default defaultValue: Date? = nil,
        kind: DateKind = .dateTime,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            kind: kind,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        kind: DateKind = .dateTime,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            kind: kind,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider,
            resolvers: resolvers
        )
    }
}

// MARK: - URL remaining

extension IntentParameter where Value == URL {
    public convenience init(
        description: LocalizedStringResource? = nil,
        default defaultValue: URL? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: nil,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        default defaultValue: URL? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            description: description,
            default: defaultValue,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
        _ = resolvers
    }
}

// MARK: - AttributedString remaining

extension IntentParameter where Value == AttributedString {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: AttributedString? = nil,
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
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        default defaultValue: AttributedString? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: nil,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        default defaultValue: AttributedString? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            description: description,
            default: defaultValue,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: AttributedString? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
        _ = resolvers
    }
}

// MARK: - StringSearchCriteria @Parameter

extension IntentParameter where Value == StringSearchCriteria {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }
}

// MARK: - IntentFile remaining

extension IntentParameter where Value == IntentFile {
    public convenience init(
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentFile? = nil,
        supportedContentTypes: [IntentFileContentType] = [.item],
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            supportedContentTypes: supportedContentTypes,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentFile? = nil,
        supportedTypeIdentifiers: [String] = ["public.item"],
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            supportedContentTypes: supportedTypeIdentifiers.map { IntentFileContentType($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        storedSupportedTypeIdentifiers = supportedTypeIdentifiers
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        supportedTypeIdentifiers: [String] = ["public.item"],
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            supportedTypeIdentifiers: supportedTypeIdentifiers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentFile? = nil,
        supportedContentTypes: [IntentFileContentType] = [.item],
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            description: description,
            default: defaultValue,
            supportedContentTypes: supportedContentTypes,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentFile? = nil,
        supportedContentTypes: [IntentFileContentType] = [.item],
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            supportedContentTypes: supportedContentTypes,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        supportedTypeIdentifiers: [String] = ["public.item"],
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            supportedTypeIdentifiers: supportedTypeIdentifiers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentFile? = nil,
        supportedContentTypes: [IntentFileContentType] = [.item],
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            description: description,
            default: defaultValue,
            supportedContentTypes: supportedContentTypes,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentFile? = nil,
        supportedContentTypes: [IntentFileContentType] = [.item],
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            supportedContentTypes: supportedContentTypes,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentFile? = nil,
        supportedTypeIdentifiers: [String] = ["public.item"],
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            supportedTypeIdentifiers: supportedTypeIdentifiers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentFile? = nil,
        supportedContentTypes: [IntentFileContentType] = [.item],
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            description: description,
            default: defaultValue,
            supportedContentTypes: supportedContentTypes,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentFile? = nil,
        supportedContentTypes: [IntentFileContentType] = [.item],
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            supportedContentTypes: supportedContentTypes,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        supportedTypeIdentifiers: [String] = ["public.item"],
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            supportedTypeIdentifiers: supportedTypeIdentifiers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
        _ = resolvers
    }
}

// MARK: - AppEntity remaining

extension IntentParameter where Value: AppEntity {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Value? = nil,
        requestValueDialog: IntentDialog? = nil,
        requestDisambiguationDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        self.defaultValue = defaultValue
        storedRequestDisambiguationDialog = requestDisambiguationDialog
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        default defaultValue: Value? = nil,
        requestValueDialog: IntentDialog? = nil,
        requestDisambiguationDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            requestValueDialog: requestValueDialog,
            requestDisambiguationDialog: requestDisambiguationDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        default defaultValue: Value? = nil,
        requestValueDialog: IntentDialog? = nil,
        requestDisambiguationDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        query: some EntityQuery
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            requestValueDialog: requestValueDialog,
            requestDisambiguationDialog: requestDisambiguationDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = query
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Value? = nil,
        requestValueDialog: IntentDialog? = nil,
        requestDisambiguationDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            requestValueDialog: requestValueDialog,
            requestDisambiguationDialog: requestDisambiguationDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        default defaultValue: Value? = nil,
        requestValueDialog: IntentDialog? = nil,
        requestDisambiguationDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            requestValueDialog: requestValueDialog,
            requestDisambiguationDialog: requestDisambiguationDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        requestDisambiguationDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            requestValueDialog: requestValueDialog,
            requestDisambiguationDialog: requestDisambiguationDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Value? = nil,
        requestValueDialog: IntentDialog? = nil,
        requestDisambiguationDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            requestValueDialog: requestValueDialog,
            requestDisambiguationDialog: requestDisambiguationDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        default defaultValue: Value? = nil,
        requestValueDialog: IntentDialog? = nil,
        requestDisambiguationDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            requestValueDialog: requestValueDialog,
            requestDisambiguationDialog: requestDisambiguationDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Value? = nil,
        requestValueDialog: IntentDialog? = nil,
        requestDisambiguationDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            requestValueDialog: requestValueDialog,
            requestDisambiguationDialog: requestDisambiguationDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        default defaultValue: Value? = nil,
        requestValueDialog: IntentDialog? = nil,
        requestDisambiguationDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            requestValueDialog: requestValueDialog,
            requestDisambiguationDialog: requestDisambiguationDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        requestDisambiguationDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            requestValueDialog: requestValueDialog,
            requestDisambiguationDialog: requestDisambiguationDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider,
            resolvers: resolvers
        )
    }
}

extension IntentParameter where Value: AppEnum {
    public convenience init<Provider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        default defaultValue: Value? = nil,
        requestValueDialog: IntentDialog? = nil,
        requestDisambiguationDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        supportedValues: [Value] = [],
        optionsProvider: Provider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            requestValueDialog: requestValueDialog,
            requestDisambiguationDialog: requestDisambiguationDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            supportedValues: supportedValues
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        default defaultValue: Value? = nil,
        requestValueDialog: IntentDialog? = nil,
        requestDisambiguationDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        supportedValues: [Value] = [],
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            requestValueDialog: requestValueDialog,
            requestDisambiguationDialog: requestDisambiguationDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            supportedValues: supportedValues
        )
        _ = resolvers
    }
}

// MARK: - FileEntity remaining

extension IntentParameter where Value: FileEntity {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Value? = nil,
        supportedContentTypes: [IntentFileContentType]?,
        requestValueDialog: IntentDialog? = nil,
        requestDisambiguationDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            requestValueDialog: requestValueDialog,
            requestDisambiguationDialog: requestDisambiguationDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        if let supportedContentTypes {
            storedSupportedTypeIdentifiers = supportedContentTypes.map(\.identifier)
        }
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        default defaultValue: Value? = nil,
        supportedContentTypes: [IntentFileContentType]?,
        requestValueDialog: IntentDialog? = nil,
        requestDisambiguationDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            supportedContentTypes: supportedContentTypes,
            requestValueDialog: requestValueDialog,
            requestDisambiguationDialog: requestDisambiguationDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Value? = nil,
        supportedContentTypes: [IntentFileContentType]?,
        requestValueDialog: IntentDialog? = nil,
        requestDisambiguationDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        query: some EntityQuery
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            supportedContentTypes: supportedContentTypes,
            requestValueDialog: requestValueDialog,
            requestDisambiguationDialog: requestDisambiguationDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = query
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        default defaultValue: Value? = nil,
        supportedContentTypes: [IntentFileContentType]?,
        requestValueDialog: IntentDialog? = nil,
        requestDisambiguationDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        query: some EntityQuery
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            supportedContentTypes: supportedContentTypes,
            requestValueDialog: requestValueDialog,
            requestDisambiguationDialog: requestDisambiguationDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            query: query
        )
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Value? = nil,
        supportedContentTypes: [IntentFileContentType]?,
        requestValueDialog: IntentDialog? = nil,
        requestDisambiguationDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            supportedContentTypes: supportedContentTypes,
            requestValueDialog: requestValueDialog,
            requestDisambiguationDialog: requestDisambiguationDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        default defaultValue: Value? = nil,
        supportedContentTypes: [IntentFileContentType]?,
        requestValueDialog: IntentDialog? = nil,
        requestDisambiguationDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            supportedContentTypes: supportedContentTypes,
            requestValueDialog: requestValueDialog,
            requestDisambiguationDialog: requestDisambiguationDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Value? = nil,
        supportedContentTypes: [IntentFileContentType]?,
        requestValueDialog: IntentDialog? = nil,
        requestDisambiguationDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            supportedContentTypes: supportedContentTypes,
            requestValueDialog: requestValueDialog,
            requestDisambiguationDialog: requestDisambiguationDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        default defaultValue: Value? = nil,
        supportedContentTypes: [IntentFileContentType]?,
        requestValueDialog: IntentDialog? = nil,
        requestDisambiguationDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            supportedContentTypes: supportedContentTypes,
            requestValueDialog: requestValueDialog,
            requestDisambiguationDialog: requestDisambiguationDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Value? = nil,
        supportedContentTypes: [IntentFileContentType]?,
        requestValueDialog: IntentDialog? = nil,
        requestDisambiguationDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            supportedContentTypes: supportedContentTypes,
            requestValueDialog: requestValueDialog,
            requestDisambiguationDialog: requestDisambiguationDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        default defaultValue: Value? = nil,
        supportedContentTypes: [IntentFileContentType]?,
        requestValueDialog: IntentDialog? = nil,
        requestDisambiguationDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            supportedContentTypes: supportedContentTypes,
            requestValueDialog: requestValueDialog,
            requestDisambiguationDialog: requestDisambiguationDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider,
            resolvers: resolvers
        )
    }
}

// MARK: - Collection size

extension IntentParameter where Value: RangeReplaceableCollection, Value.Element: AppEntity {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Value.Element? = nil,
        size: IntentCollectionSize,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            inputConnectionBehavior: inputConnectionBehavior
        )
        storedCollectionSize = size
        if let defaultValue {
            var collection = Value()
            collection.append(defaultValue)
            self.defaultValue = collection
        }
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        default defaultValue: Value.Element? = nil,
        size: IntentCollectionSize,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            size: size,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Value.Element? = nil,
        size: IntentCollectionSize,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        query: some EntityQuery
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            size: size,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = query
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        default defaultValue: Value.Element? = nil,
        size: IntentCollectionSize,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        query: some EntityQuery
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            size: size,
            inputConnectionBehavior: inputConnectionBehavior,
            query: query
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Value.Element? = nil,
        size: IntentCollectionSize,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            size: size,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        default defaultValue: Value.Element? = nil,
        size: IntentCollectionSize,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            size: size,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }
}

extension IntentParameter where Value: RangeReplaceableCollection, Value.Element == IntentPerson {
    public var parameterMode: IntentPerson.ParameterMode? { storedPersonMode }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentPerson? = nil,
        mode: IntentPerson.ParameterMode = .contact,
        size: IntentCollectionSize,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            inputConnectionBehavior: inputConnectionBehavior
        )
        storedPersonMode = mode
        storedCollectionSize = size
        if let defaultValue {
            var collection = Value()
            collection.append(defaultValue)
            self.defaultValue = collection
        }
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentPerson? = nil,
        mode: IntentPerson.ParameterMode = .contact,
        size: IntentCollectionSize,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            mode: mode,
            size: size,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        mode: IntentPerson.ParameterMode = .contact,
        size: IntentCollectionSize,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            mode: mode,
            size: size,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }
}

extension IntentParameter where Value: RangeReplaceableCollection, Value.Element: FileEntity {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Value.Element? = nil,
        supportedContentTypes: [IntentFileContentType]?,
        size: IntentCollectionSize,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            inputConnectionBehavior: inputConnectionBehavior
        )
        storedCollectionSize = size
        if let supportedContentTypes {
            storedSupportedTypeIdentifiers = supportedContentTypes.map(\.identifier)
        }
        if let defaultValue {
            var collection = Value()
            collection.append(defaultValue)
            self.defaultValue = collection
        }
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        default defaultValue: Value.Element? = nil,
        supportedContentTypes: [IntentFileContentType]?,
        size: IntentCollectionSize,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            supportedContentTypes: supportedContentTypes,
            size: size,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Value.Element? = nil,
        supportedContentTypes: [IntentFileContentType]?,
        size: IntentCollectionSize,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        query: some EntityQuery
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            supportedContentTypes: supportedContentTypes,
            size: size,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = query
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        default defaultValue: Value.Element? = nil,
        supportedContentTypes: [IntentFileContentType]?,
        size: IntentCollectionSize,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        query: some EntityQuery
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            supportedContentTypes: supportedContentTypes,
            size: size,
            inputConnectionBehavior: inputConnectionBehavior,
            query: query
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: Value.Element? = nil,
        supportedContentTypes: [IntentFileContentType]?,
        size: IntentCollectionSize,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            supportedContentTypes: supportedContentTypes,
            size: size,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        default defaultValue: Value.Element? = nil,
        supportedContentTypes: [IntentFileContentType]?,
        size: IntentCollectionSize,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            supportedContentTypes: supportedContentTypes,
            size: size,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }
}

extension IntentParameter where Value == [URL] {
    public convenience init(
        description: LocalizedStringResource? = nil,
        default defaultValue: [URL?],
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        self.defaultValue = defaultValue.compactMap { $0 }
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        default defaultValue: [URL?],
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            description: description,
            default: defaultValue,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: [URL?],
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        self.defaultValue = defaultValue.compactMap { $0 }
        _ = resolvers
    }
}
