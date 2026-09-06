import Foundation

/// Calendar recurrence rules are Foundation values. Linux stores them
/// in-process; EventKit / Calendar daemon recurrence expansion is unobserved.
extension Calendar.RecurrenceRule: _IntentValue {}

extension IntentParameterContext where Value == IntentCurrencyAmount {
    public var currencyCodes: [String]? { storedCurrencyCodes }
}

extension IntentParameterContext where Value == IntentPerson {
    public var parameterMode: IntentPerson.ParameterMode? { storedPersonMode }
}

extension IntentParameterContext where Value == DateComponents {
    public var dateKind: IntentParameter<DateComponents>.DateKind? {
        nil
    }
}

// MARK: - DateComponents @Parameter

extension IntentParameter where Value == DateComponents {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: DateComponents? = nil,
        kind: DateKind = .dateTime,
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
        storedDateKind = kind
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        default defaultValue: DateComponents? = nil,
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
        default defaultValue: DateComponents? = nil,
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
        default defaultValue: DateComponents? = nil,
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
        default defaultValue: DateComponents? = nil,
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
        default defaultValue: DateComponents? = nil,
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
        default defaultValue: DateComponents? = nil,
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
        default defaultValue: DateComponents? = nil,
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

// MARK: - IntentCurrencyAmount @Parameter

extension IntentParameter where Value == IntentCurrencyAmount {
    public var currencyCodes: [String]? { storedCurrencyCodes }
    public var inclusiveRange: (lowerBound: Decimal, upperBound: Decimal)? {
        storedDecimalInclusiveRange
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentCurrencyAmount? = nil,
        currencyCodes: [String] = [],
        inclusiveRange: (lowerBound: Decimal, upperBound: Decimal)? = nil,
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
        storedCurrencyCodes = currencyCodes
        storedDecimalInclusiveRange = inclusiveRange
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentCurrencyAmount? = nil,
        currencyCodes: [String] = [],
        inclusiveRange: (lowerBound: Decimal, upperBound: Decimal)? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            currencyCodes: currencyCodes,
            inclusiveRange: inclusiveRange,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        currencyCodes: [String] = [],
        inclusiveRange: (lowerBound: Decimal, upperBound: Decimal)? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            currencyCodes: currencyCodes,
            inclusiveRange: inclusiveRange,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentCurrencyAmount? = nil,
        currencyCodes: [String] = [],
        inclusiveRange: (lowerBound: Decimal, upperBound: Decimal)? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            currencyCodes: currencyCodes,
            inclusiveRange: inclusiveRange,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentCurrencyAmount? = nil,
        currencyCodes: [String] = [],
        inclusiveRange: (lowerBound: Decimal, upperBound: Decimal)? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            currencyCodes: currencyCodes,
            inclusiveRange: inclusiveRange,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        currencyCodes: [String] = [],
        inclusiveRange: (lowerBound: Decimal, upperBound: Decimal)? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            currencyCodes: currencyCodes,
            inclusiveRange: inclusiveRange,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentCurrencyAmount? = nil,
        currencyCodes: [String] = [],
        inclusiveRange: (lowerBound: Decimal, upperBound: Decimal)? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            currencyCodes: currencyCodes,
            inclusiveRange: inclusiveRange,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentCurrencyAmount? = nil,
        currencyCodes: [String] = [],
        inclusiveRange: (lowerBound: Decimal, upperBound: Decimal)? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            currencyCodes: currencyCodes,
            inclusiveRange: inclusiveRange,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        currencyCodes: [String] = [],
        inclusiveRange: (lowerBound: Decimal, upperBound: Decimal)? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            currencyCodes: currencyCodes,
            inclusiveRange: inclusiveRange,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentCurrencyAmount? = nil,
        currencyCodes: [String] = [],
        inclusiveRange: (lowerBound: Decimal, upperBound: Decimal)? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            currencyCodes: currencyCodes,
            inclusiveRange: inclusiveRange,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentCurrencyAmount? = nil,
        currencyCodes: [String] = [],
        inclusiveRange: (lowerBound: Decimal, upperBound: Decimal)? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            currencyCodes: currencyCodes,
            inclusiveRange: inclusiveRange,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        currencyCodes: [String] = [],
        inclusiveRange: (lowerBound: Decimal, upperBound: Decimal)? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            currencyCodes: currencyCodes,
            inclusiveRange: inclusiveRange,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider,
            resolvers: resolvers
        )
    }
}

// MARK: - IntentPerson @Parameter

extension IntentParameter where Value == IntentPerson {
    public var parameterMode: IntentPerson.ParameterMode? { storedPersonMode }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentPerson? = nil,
        mode: IntentPerson.ParameterMode = .emailOrPhone,
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
        storedPersonMode = mode
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentPerson? = nil,
        mode: IntentPerson.ParameterMode = .emailOrPhone,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            mode: mode,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        mode: IntentPerson.ParameterMode = .emailOrPhone,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            mode: mode,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentPerson? = nil,
        mode: IntentPerson.ParameterMode = .emailOrPhone,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            mode: mode,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentPerson? = nil,
        mode: IntentPerson.ParameterMode = .emailOrPhone,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            mode: mode,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        mode: IntentPerson.ParameterMode = .emailOrPhone,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            mode: mode,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentPerson? = nil,
        mode: IntentPerson.ParameterMode = .emailOrPhone,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            mode: mode,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentPerson? = nil,
        mode: IntentPerson.ParameterMode = .emailOrPhone,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            mode: mode,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        mode: IntentPerson.ParameterMode = .emailOrPhone,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            mode: mode,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentPerson? = nil,
        mode: IntentPerson.ParameterMode = .emailOrPhone,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            mode: mode,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentPerson? = nil,
        mode: IntentPerson.ParameterMode = .emailOrPhone,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            mode: mode,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        mode: IntentPerson.ParameterMode = .emailOrPhone,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            mode: mode,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider,
            resolvers: resolvers
        )
    }
}

// MARK: - IntentPaymentMethod @Parameter

extension IntentParameter where Value == IntentPaymentMethod {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentPaymentMethod? = nil,
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
        default defaultValue: IntentPaymentMethod? = nil,
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

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentPaymentMethod? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
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

    public convenience init<Provider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentPaymentMethod? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
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
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentPaymentMethod? = nil,
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

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentPaymentMethod? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentPaymentMethod? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        default defaultValue: IntentPaymentMethod? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider,
            resolvers: resolvers
        )
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
            default: nil,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider,
            resolvers: resolvers
        )
    }
}

// MARK: - CLPlacemark @Parameter

extension IntentParameter where Value == CLPlacemark {
    public var displayStyle: PlacemarkDisplayStyle? { storedPlacemarkDisplayStyle }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: CLPlacemark? = nil,
        displayStyle: PlacemarkDisplayStyle = .name,
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
        storedPlacemarkDisplayStyle = displayStyle
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        default defaultValue: CLPlacemark? = nil,
        displayStyle: PlacemarkDisplayStyle = .name,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            displayStyle: displayStyle,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        displayStyle: PlacemarkDisplayStyle = .name,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            displayStyle: displayStyle,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: CLPlacemark? = nil,
        displayStyle: PlacemarkDisplayStyle = .name,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            displayStyle: displayStyle,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        default defaultValue: CLPlacemark? = nil,
        displayStyle: PlacemarkDisplayStyle = .name,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            displayStyle: displayStyle,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        displayStyle: PlacemarkDisplayStyle = .name,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            displayStyle: displayStyle,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: CLPlacemark? = nil,
        displayStyle: PlacemarkDisplayStyle = .name,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            displayStyle: displayStyle,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        default defaultValue: CLPlacemark? = nil,
        displayStyle: PlacemarkDisplayStyle = .name,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            displayStyle: displayStyle,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        displayStyle: PlacemarkDisplayStyle = .name,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            displayStyle: displayStyle,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        default defaultValue: CLPlacemark? = nil,
        displayStyle: PlacemarkDisplayStyle = .name,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: defaultValue,
            displayStyle: displayStyle,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        default defaultValue: CLPlacemark? = nil,
        displayStyle: PlacemarkDisplayStyle = .name,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            default: defaultValue,
            displayStyle: displayStyle,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification, Provider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        displayStyle: PlacemarkDisplayStyle = .name,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: Provider,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            default: nil,
            displayStyle: displayStyle,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider,
            resolvers: resolvers
        )
    }
}
