import Foundation

// Typed @Parameter inits for remaining Foundation.Measurement families.
// Nested unit enums live in AppIntentsMeasurement.swift; these inits store
// defaultValue / defaultUnit / unit on the wrapper and copy them onto
// IntentParameterContext. Options providers and resolvers attach metadata
// only. Linux never claims a locale-adjusted Foundation unit picker.

extension IntentParameter where Value == Measurement<UnitMass> {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Mass? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            unit: nil,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            unitAdjustForLocale: nil,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: defaultUnit?.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Mass? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Mass,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: unit,
            unit: unit,
            defaultUnitAdjustForLocale: false,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: unit.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Mass,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Mass? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Mass? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Mass,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Mass,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
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

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers,
            optionsProvider: optionsProvider
        )
    }
}

extension IntentParameter where Value == Measurement<UnitArea> {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Area? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            unit: nil,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            unitAdjustForLocale: nil,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: defaultUnit?.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Area? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Area,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: unit,
            unit: unit,
            defaultUnitAdjustForLocale: false,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: unit.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Area,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Area? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Area? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Area,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Area,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
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

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers,
            optionsProvider: optionsProvider
        )
    }
}

extension IntentParameter where Value == Measurement<UnitPower> {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Power? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            unit: nil,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            unitAdjustForLocale: nil,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: defaultUnit?.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Power? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Power,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: unit,
            unit: unit,
            defaultUnitAdjustForLocale: false,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: unit.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Power,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Power? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Power? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Power,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Power,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
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

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers,
            optionsProvider: optionsProvider
        )
    }
}

extension IntentParameter where Value == Measurement<UnitPressure> {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Pressure? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            unit: nil,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            unitAdjustForLocale: nil,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: defaultUnit?.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Pressure? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Pressure,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: unit,
            unit: unit,
            defaultUnitAdjustForLocale: false,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: unit.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Pressure,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Pressure? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Pressure? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Pressure,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Pressure,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
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

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers,
            optionsProvider: optionsProvider
        )
    }
}

extension IntentParameter where Value == Measurement<UnitFrequency> {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Frequency? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            unit: nil,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            unitAdjustForLocale: nil,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: defaultUnit?.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Frequency? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Frequency,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: unit,
            unit: unit,
            defaultUnitAdjustForLocale: false,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: unit.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Frequency,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Frequency? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Frequency? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Frequency,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Frequency,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
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

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers,
            optionsProvider: optionsProvider
        )
    }
}

extension IntentParameter where Value == Measurement<UnitDuration> {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Duration? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            unit: nil,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            unitAdjustForLocale: nil,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: defaultUnit?.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Duration? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Duration,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: unit,
            unit: unit,
            defaultUnitAdjustForLocale: false,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: unit.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Duration,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Duration? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Duration? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Duration,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Duration,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
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

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers,
            optionsProvider: optionsProvider
        )
    }
}

extension IntentParameter where Value == Measurement<UnitAngle> {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Angle? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            unit: nil,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            unitAdjustForLocale: nil,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: defaultUnit?.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Angle? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Angle,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: unit,
            unit: unit,
            defaultUnitAdjustForLocale: false,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: unit.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Angle,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Angle? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Angle? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Angle,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Angle,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
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

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers,
            optionsProvider: optionsProvider
        )
    }
}

extension IntentParameter where Value == Measurement<UnitElectricCharge> {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: ElectricCharge? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            unit: nil,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            unitAdjustForLocale: nil,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: defaultUnit?.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: ElectricCharge? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: ElectricCharge,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: unit,
            unit: unit,
            defaultUnitAdjustForLocale: false,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: unit.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: ElectricCharge,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: ElectricCharge? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: ElectricCharge? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: ElectricCharge,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: ElectricCharge,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
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

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers,
            optionsProvider: optionsProvider
        )
    }
}

extension IntentParameter where Value == Measurement<UnitEnergy> {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Energy? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            unit: nil,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            unitAdjustForLocale: nil,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: defaultUnit?.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Energy? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Energy,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: unit,
            unit: unit,
            defaultUnitAdjustForLocale: false,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: unit.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Energy,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Energy? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Energy? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Energy,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Energy,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
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

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers,
            optionsProvider: optionsProvider
        )
    }
}

extension IntentParameter where Value == Measurement<UnitElectricCurrent> {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: ElectricCurrent? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            unit: nil,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            unitAdjustForLocale: nil,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: defaultUnit?.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: ElectricCurrent? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: ElectricCurrent,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: unit,
            unit: unit,
            defaultUnitAdjustForLocale: false,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: unit.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: ElectricCurrent,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: ElectricCurrent? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: ElectricCurrent? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: ElectricCurrent,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: ElectricCurrent,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
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

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers,
            optionsProvider: optionsProvider
        )
    }
}

extension IntentParameter where Value == Measurement<UnitElectricResistance> {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: ElectricResistance? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            unit: nil,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            unitAdjustForLocale: nil,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: defaultUnit?.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: ElectricResistance? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: ElectricResistance,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: unit,
            unit: unit,
            defaultUnitAdjustForLocale: false,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: unit.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: ElectricResistance,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: ElectricResistance? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: ElectricResistance? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: ElectricResistance,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: ElectricResistance,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
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

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers,
            optionsProvider: optionsProvider
        )
    }
}

extension IntentParameter where Value == Measurement<UnitElectricPotentialDifference> {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: ElectricPotentialDifference? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            unit: nil,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            unitAdjustForLocale: nil,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: defaultUnit?.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: ElectricPotentialDifference? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: ElectricPotentialDifference,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: unit,
            unit: unit,
            defaultUnitAdjustForLocale: false,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: unit.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: ElectricPotentialDifference,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: ElectricPotentialDifference? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: ElectricPotentialDifference? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: ElectricPotentialDifference,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: ElectricPotentialDifference,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
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

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers,
            optionsProvider: optionsProvider
        )
    }
}

extension IntentParameter where Value == Measurement<UnitSpeed> {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Speed? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            unit: nil,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            unitAdjustForLocale: nil,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: defaultUnit?.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Speed? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Speed,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: unit,
            unit: unit,
            defaultUnitAdjustForLocale: false,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: unit.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Speed,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Speed? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Speed? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Speed,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Speed,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
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

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers,
            optionsProvider: optionsProvider
        )
    }
}

extension IntentParameter where Value == Measurement<UnitTemperature> {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Temperature? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            unit: nil,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            unitAdjustForLocale: nil,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: defaultUnit?.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Temperature? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Temperature,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: unit,
            unit: unit,
            defaultUnitAdjustForLocale: false,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: unit.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Temperature,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Temperature? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Temperature? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Temperature,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Temperature,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
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

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers,
            optionsProvider: optionsProvider
        )
    }
}

extension IntentParameter where Value == Measurement<UnitFuelEfficiency> {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: FuelEfficiency? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            unit: nil,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            unitAdjustForLocale: nil,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: defaultUnit?.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: FuelEfficiency? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: FuelEfficiency,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: unit,
            unit: unit,
            defaultUnitAdjustForLocale: false,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: unit.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: FuelEfficiency,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: FuelEfficiency? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: FuelEfficiency? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: FuelEfficiency,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: FuelEfficiency,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
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

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers,
            optionsProvider: optionsProvider
        )
    }
}

extension IntentParameter where Value == Measurement<UnitAcceleration> {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Acceleration? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            unit: nil,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            unitAdjustForLocale: nil,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: defaultUnit?.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Acceleration? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Acceleration,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: unit,
            unit: unit,
            defaultUnitAdjustForLocale: false,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: unit.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Acceleration,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Acceleration? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Acceleration? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Acceleration,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Acceleration,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
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

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers,
            optionsProvider: optionsProvider
        )
    }
}

extension IntentParameter where Value == Measurement<UnitConcentrationMass> {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: ConcentrationMass? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            unit: nil,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            unitAdjustForLocale: nil,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: defaultUnit?.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: ConcentrationMass? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: ConcentrationMass,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: unit,
            unit: unit,
            defaultUnitAdjustForLocale: false,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: unit.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: ConcentrationMass,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: ConcentrationMass? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: ConcentrationMass? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: ConcentrationMass,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: ConcentrationMass,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
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

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers,
            optionsProvider: optionsProvider
        )
    }
}

extension IntentParameter where Value == Measurement<UnitDispersion> {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Dispersion? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            unit: nil,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            unitAdjustForLocale: nil,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: defaultUnit?.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Dispersion? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Dispersion,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: unit,
            unit: unit,
            defaultUnitAdjustForLocale: false,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: unit.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Dispersion,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Dispersion? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Dispersion? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Dispersion,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Dispersion,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
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

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers,
            optionsProvider: optionsProvider
        )
    }
}

extension IntentParameter where Value == Measurement<UnitIlluminance> {
    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Illuminance? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            unit: nil,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            unitAdjustForLocale: nil,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: defaultUnit?.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Illuminance? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Illuminance,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        applyHostMeasurement(
            defaultValue: defaultValue,
            defaultUnit: unit,
            unit: unit,
            defaultUnitAdjustForLocale: false,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            foundationUnit: unit.foundationUnit
        )
    }

    public convenience init(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Illuminance,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Illuminance? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Illuminance? = nil,
        defaultUnitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            defaultUnit: defaultUnit,
            defaultUnitAdjustForLocale: defaultUnitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<Spec: ResolverSpecification>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Illuminance,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: title,
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        _ = resolvers
    }

    public convenience init<Spec: ResolverSpecification>(
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        unit: Illuminance,
        unitAdjustForLocale: Bool = false,
        supportsNegativeNumbers: Bool = true,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            defaultValue: defaultValue,
            unit: unit,
            unitAdjustForLocale: unitAdjustForLocale,
            supportsNegativeNumbers: supportsNegativeNumbers,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers
        )
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: appIntentsString(title),
            description: description.map { appIntentsString($0) },
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior
        )
        optionsProviderAttached = true
        _ = optionsProvider
    }

    public convenience init<OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            optionsProvider: optionsProvider
        )
    }

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
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

    public convenience init<Spec: ResolverSpecification, OptionsProvider: DynamicOptionsProvider>(
        description: LocalizedStringResource? = nil,
        requestValueDialog: IntentDialog? = nil,
        inputConnectionBehavior: InputConnectionBehavior = .default,
        resolvers: Spec,
        optionsProvider: OptionsProvider
    ) {
        self.init(
            title: LocalizedStringResource(""),
            description: description,
            requestValueDialog: requestValueDialog,
            inputConnectionBehavior: inputConnectionBehavior,
            resolvers: resolvers,
            optionsProvider: optionsProvider
        )
    }
}
