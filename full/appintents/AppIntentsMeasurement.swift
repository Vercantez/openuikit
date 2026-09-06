import Foundation

// Measurement unit catalogs and @Parameter inits for Foundation.Measurement.
// Nested unit names come from the pinned 26.1 graph. Linux stores the enum
// case and builds Measurement with UnitType(symbol:converter:) using an
// identity converter; it does not invent Apple locale coefficients.

extension Measurement: _IntentValue where UnitType: Unit {}

extension IntentParameter {
    func applyHostMeasurement<UnitType: Dimension>(
        defaultValue: Double?,
        defaultUnit: Any?,
        unit: Any?,
        defaultUnitAdjustForLocale: Bool,
        unitAdjustForLocale: Bool?,
        supportsNegativeNumbers: Bool,
        foundationUnit: UnitType?
    ) where Value == Measurement<UnitType> {
        storedMeasurementDefaultUnit = defaultUnit
        storedMeasurementUnit = unit ?? defaultUnit
        storedUnitAdjustForLocale = unitAdjustForLocale ?? defaultUnitAdjustForLocale
        storedSupportsNegativeNumbers = supportsNegativeNumbers
        if let defaultValue, let foundationUnit {
            self.defaultValue = Measurement(value: defaultValue, unit: foundationUnit)
        }
    }

    public func makeContext() -> IntentParameterContext<Value> {
        var context = IntentParameterContext<Value>(
            title: LocalizedStringResource(metadata.title),
            isOptional: isOptional
        )
        context.storedDefaultUnit = storedMeasurementDefaultUnit
        context.storedUnit = storedMeasurementUnit
        context.storedUnitAdjustForLocale = storedUnitAdjustForLocale
        context.storedSupportsNegativeNumbers = storedSupportsNegativeNumbers
        return context
    }
}

extension IntentParameter where Value == Measurement<UnitVolume> {
    public enum Volume: String, CaseIterable, Hashable, Sendable {
        case cubicMiles
        case cubicYards
        case deciliters
        case kiloliters
        case megaliters
        case metricCups
        case centiliters
        case cubicInches
        case cubicMeters
        case fluidOunces
        case milliliters
        case tablespoons
        case imperialPints
        case imperialQuarts
        case cubicDecimeters
        case cubicKilometers
        case imperialGallons
        case cubicCentimeters
        case cubicMillimeters
        case imperialTeaspoons
        case imperialFluidOunces
        case imperialTablespoons
        case cups
        case pints
        case liters
        case quarts
        case bushels
        case gallons
        case acreFeet
        case cubicFeet
        case teaspoons

        public var foundationUnit: UnitVolume {
            UnitVolume(symbol: rawValue, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    public typealias AllCases = [Volume]
}

extension IntentParameter where Value == Measurement<UnitVolume> {
    public var defaultUnit: Volume? { storedMeasurementDefaultUnit as? Volume }
    public var unit: Volume? { storedMeasurementUnit as? Volume }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Volume? = nil,
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
        defaultUnit: Volume? = nil,
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
        unit: Volume,
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
        unit: Volume,
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
        defaultUnit: Volume? = nil,
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
        defaultUnit: Volume? = nil,
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
        unit: Volume,
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
        unit: Volume,
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

extension IntentParameterContext where Value == Measurement<UnitVolume> {
    public var defaultUnit: IntentParameter<Measurement<UnitVolume>>.Volume? {
        storedDefaultUnit as? IntentParameter<Measurement<UnitVolume>>.Volume
    }
    public var unit: IntentParameter<Measurement<UnitVolume>>.Volume? {
        storedUnit as? IntentParameter<Measurement<UnitVolume>>.Volume
    }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameter where Value == Measurement<UnitLength> {
    public enum Length: String, CaseIterable, Hashable, Sendable {
        case decameters
        case decimeters
        case kilometers
        case lightyears
        case megameters
        case nanometers
        case picometers
        case centimeters
        case hectometers
        case micrometers
        case millimeters
        case nauticalMiles
        case astronomicalUnits
        case scandinavianMiles
        case feet
        case miles
        case yards
        case inches
        case meters
        case fathoms
        case parsecs
        case furlongs

        public var foundationUnit: UnitLength {
            UnitLength(symbol: rawValue, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    public typealias AllCases = [Length]
}

extension IntentParameter where Value == Measurement<UnitLength> {
    public var defaultUnit: Length? { storedMeasurementDefaultUnit as? Length }
    public var unit: Length? { storedMeasurementUnit as? Length }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: Length? = nil,
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
        defaultUnit: Length? = nil,
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
        unit: Length,
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
        unit: Length,
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
        defaultUnit: Length? = nil,
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
        defaultUnit: Length? = nil,
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
        unit: Length,
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
        unit: Length,
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

extension IntentParameterContext where Value == Measurement<UnitLength> {
    public var defaultUnit: IntentParameter<Measurement<UnitLength>>.Length? {
        storedDefaultUnit as? IntentParameter<Measurement<UnitLength>>.Length
    }
    public var unit: IntentParameter<Measurement<UnitLength>>.Length? {
        storedUnit as? IntentParameter<Measurement<UnitLength>>.Length
    }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameter where Value == Measurement<UnitInformationStorage> {
    public enum InformationStorage: String, CaseIterable, Hashable, Sendable {
        case yottabytes
        case zettabytes
        case bits
        case bytes
        case exabits
        case nibbles
        case exabytes
        case exbibits
        case gibibits
        case gigabits
        case kibibits
        case kilobits
        case mebibits
        case megabits
        case pebibits
        case petabits
        case tebibits
        case terabits
        case yobibits
        case zebibits
        case exbibytes
        case gibibytes
        case gigabytes
        case kibibytes
        case kilobytes
        case mebibytes
        case megabytes
        case pebibytes
        case petabytes
        case tebibytes
        case terabytes
        case yobibytes
        case yottabits
        case zebibytes
        case zettabits

        public var foundationUnit: UnitInformationStorage {
            UnitInformationStorage(symbol: rawValue, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    public typealias AllCases = [InformationStorage]
}

extension IntentParameter where Value == Measurement<UnitInformationStorage> {
    public var defaultUnit: InformationStorage? { storedMeasurementDefaultUnit as? InformationStorage }
    public var unit: InformationStorage? { storedMeasurementUnit as? InformationStorage }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }

    public convenience init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        defaultValue: Double? = nil,
        defaultUnit: InformationStorage? = nil,
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
        defaultUnit: InformationStorage? = nil,
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
        unit: InformationStorage,
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
        unit: InformationStorage,
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
        defaultUnit: InformationStorage? = nil,
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
        defaultUnit: InformationStorage? = nil,
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
        unit: InformationStorage,
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
        unit: InformationStorage,
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

extension IntentParameterContext where Value == Measurement<UnitInformationStorage> {
    public var defaultUnit: IntentParameter<Measurement<UnitInformationStorage>>.InformationStorage? {
        storedDefaultUnit as? IntentParameter<Measurement<UnitInformationStorage>>.InformationStorage
    }
    public var unit: IntentParameter<Measurement<UnitInformationStorage>>.InformationStorage? {
        storedUnit as? IntentParameter<Measurement<UnitInformationStorage>>.InformationStorage
    }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameter where Value == Measurement<UnitMass> {
    public enum Mass: String, CaseIterable, Hashable, Sendable {
        case centigrams
        case metricTons
        case micrograms
        case milligrams
        case ouncesTroy
        case grams
        case slugs
        case carats
        case ounces
        case pounds
        case stones
        case decigrams
        case kilograms
        case nanograms
        case picograms
        case shortTons

        public var foundationUnit: UnitMass {
            UnitMass(symbol: rawValue, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    public typealias AllCases = [Mass]
}

extension IntentParameter where Value == Measurement<UnitMass> {
    public var defaultUnit: Mass? { storedMeasurementDefaultUnit as? Mass }
    public var unit: Mass? { storedMeasurementUnit as? Mass }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameterContext where Value == Measurement<UnitMass> {
    public var defaultUnit: IntentParameter<Measurement<UnitMass>>.Mass? {
        storedDefaultUnit as? IntentParameter<Measurement<UnitMass>>.Mass
    }
    public var unit: IntentParameter<Measurement<UnitMass>>.Mass? {
        storedUnit as? IntentParameter<Measurement<UnitMass>>.Mass
    }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameter where Value == Measurement<UnitArea> {
    public enum Area: String, CaseIterable, Hashable, Sendable {
        case squareFeet
        case squareMiles
        case squareYards
        case squareInches
        case squareMeters
        case squareKilometers
        case squareMegameters
        case squareNanometers
        case squareCentimeters
        case squareMicrometers
        case squareMillimeters
        case ares
        case acres
        case hectares

        public var foundationUnit: UnitArea {
            UnitArea(symbol: rawValue, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    public typealias AllCases = [Area]
}

extension IntentParameter where Value == Measurement<UnitArea> {
    public var defaultUnit: Area? { storedMeasurementDefaultUnit as? Area }
    public var unit: Area? { storedMeasurementUnit as? Area }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameterContext where Value == Measurement<UnitArea> {
    public var defaultUnit: IntentParameter<Measurement<UnitArea>>.Area? {
        storedDefaultUnit as? IntentParameter<Measurement<UnitArea>>.Area
    }
    public var unit: IntentParameter<Measurement<UnitArea>>.Area? {
        storedUnit as? IntentParameter<Measurement<UnitArea>>.Area
    }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameter where Value == Measurement<UnitPower> {
    public enum Power: String, CaseIterable, Hashable, Sendable {
        case femtowatts
        case horsepower
        case microwatts
        case milliwatts
        case watts
        case gigawatts
        case kilowatts
        case megawatts
        case nanowatts
        case picowatts
        case terawatts

        public var foundationUnit: UnitPower {
            UnitPower(symbol: rawValue, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    public typealias AllCases = [Power]
}

extension IntentParameter where Value == Measurement<UnitPower> {
    public var defaultUnit: Power? { storedMeasurementDefaultUnit as? Power }
    public var unit: Power? { storedMeasurementUnit as? Power }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameterContext where Value == Measurement<UnitPower> {
    public var defaultUnit: IntentParameter<Measurement<UnitPower>>.Power? {
        storedDefaultUnit as? IntentParameter<Measurement<UnitPower>>.Power
    }
    public var unit: IntentParameter<Measurement<UnitPower>>.Power? {
        storedUnit as? IntentParameter<Measurement<UnitPower>>.Power
    }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameter where Value == Measurement<UnitPressure> {
    public enum Pressure: String, CaseIterable, Hashable, Sendable {
        case gigapascals
        case kilopascals
        case megapascals
        case hectopascals
        case inchesOfMercury
        case millimetersOfMercury
        case newtonsPerMetersSquared
        case poundsForcePerSquareInch
        case bars
        case millibars

        public var foundationUnit: UnitPressure {
            UnitPressure(symbol: rawValue, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    public typealias AllCases = [Pressure]
}

extension IntentParameter where Value == Measurement<UnitPressure> {
    public var defaultUnit: Pressure? { storedMeasurementDefaultUnit as? Pressure }
    public var unit: Pressure? { storedMeasurementUnit as? Pressure }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameterContext where Value == Measurement<UnitPressure> {
    public var defaultUnit: IntentParameter<Measurement<UnitPressure>>.Pressure? {
        storedDefaultUnit as? IntentParameter<Measurement<UnitPressure>>.Pressure
    }
    public var unit: IntentParameter<Measurement<UnitPressure>>.Pressure? {
        storedUnit as? IntentParameter<Measurement<UnitPressure>>.Pressure
    }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameter where Value == Measurement<UnitFrequency> {
    public enum Frequency: String, CaseIterable, Hashable, Sendable {
        case microhertz
        case millihertz
        case framesPerSecond
        case hertz
        case gigahertz
        case kilohertz
        case megahertz
        case nanohertz
        case terahertz

        public var foundationUnit: UnitFrequency {
            UnitFrequency(symbol: rawValue, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    public typealias AllCases = [Frequency]
}

extension IntentParameter where Value == Measurement<UnitFrequency> {
    public var defaultUnit: Frequency? { storedMeasurementDefaultUnit as? Frequency }
    public var unit: Frequency? { storedMeasurementUnit as? Frequency }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameterContext where Value == Measurement<UnitFrequency> {
    public var defaultUnit: IntentParameter<Measurement<UnitFrequency>>.Frequency? {
        storedDefaultUnit as? IntentParameter<Measurement<UnitFrequency>>.Frequency
    }
    public var unit: IntentParameter<Measurement<UnitFrequency>>.Frequency? {
        storedUnit as? IntentParameter<Measurement<UnitFrequency>>.Frequency
    }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameter where Value == Measurement<UnitDuration> {
    public enum Duration: String, CaseIterable, Hashable, Sendable {
        case nanoseconds
        case picoseconds
        case microseconds
        case milliseconds
        case hours
        case minutes
        case seconds

        public var foundationUnit: UnitDuration {
            UnitDuration(symbol: rawValue, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    public typealias AllCases = [Duration]
}

extension IntentParameter where Value == Measurement<UnitDuration> {
    public var defaultUnit: Duration? { storedMeasurementDefaultUnit as? Duration }
    public var unit: Duration? { storedMeasurementUnit as? Duration }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameterContext where Value == Measurement<UnitDuration> {
    public var defaultUnit: IntentParameter<Measurement<UnitDuration>>.Duration? {
        storedDefaultUnit as? IntentParameter<Measurement<UnitDuration>>.Duration
    }
    public var unit: IntentParameter<Measurement<UnitDuration>>.Duration? {
        storedUnit as? IntentParameter<Measurement<UnitDuration>>.Duration
    }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameter where Value == Measurement<UnitAngle> {
    public enum Angle: String, CaseIterable, Hashable, Sendable {
        case arcMinutes
        case arcSeconds
        case revolutions
        case degrees
        case radians
        case gradians

        public var foundationUnit: UnitAngle {
            UnitAngle(symbol: rawValue, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    public typealias AllCases = [Angle]
}

extension IntentParameter where Value == Measurement<UnitAngle> {
    public var defaultUnit: Angle? { storedMeasurementDefaultUnit as? Angle }
    public var unit: Angle? { storedMeasurementUnit as? Angle }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameterContext where Value == Measurement<UnitAngle> {
    public var defaultUnit: IntentParameter<Measurement<UnitAngle>>.Angle? {
        storedDefaultUnit as? IntentParameter<Measurement<UnitAngle>>.Angle
    }
    public var unit: IntentParameter<Measurement<UnitAngle>>.Angle? {
        storedUnit as? IntentParameter<Measurement<UnitAngle>>.Angle
    }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameter where Value == Measurement<UnitElectricCharge> {
    public enum ElectricCharge: String, CaseIterable, Hashable, Sendable {
        case ampereHours
        case kiloampereHours
        case megaampereHours
        case microampereHours
        case milliampereHours
        case coulombs

        public var foundationUnit: UnitElectricCharge {
            UnitElectricCharge(symbol: rawValue, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    public typealias AllCases = [ElectricCharge]
}

extension IntentParameter where Value == Measurement<UnitElectricCharge> {
    public var defaultUnit: ElectricCharge? { storedMeasurementDefaultUnit as? ElectricCharge }
    public var unit: ElectricCharge? { storedMeasurementUnit as? ElectricCharge }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameterContext where Value == Measurement<UnitElectricCharge> {
    public var defaultUnit: IntentParameter<Measurement<UnitElectricCharge>>.ElectricCharge? {
        storedDefaultUnit as? IntentParameter<Measurement<UnitElectricCharge>>.ElectricCharge
    }
    public var unit: IntentParameter<Measurement<UnitElectricCharge>>.ElectricCharge? {
        storedUnit as? IntentParameter<Measurement<UnitElectricCharge>>.ElectricCharge
    }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameter where Value == Measurement<UnitEnergy> {
    public enum Energy: String, CaseIterable, Hashable, Sendable {
        case kilojoules
        case kilocalories
        case kilowattHours
        case joules
        case calories

        public var foundationUnit: UnitEnergy {
            UnitEnergy(symbol: rawValue, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    public typealias AllCases = [Energy]
}

extension IntentParameter where Value == Measurement<UnitEnergy> {
    public var defaultUnit: Energy? { storedMeasurementDefaultUnit as? Energy }
    public var unit: Energy? { storedMeasurementUnit as? Energy }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameterContext where Value == Measurement<UnitEnergy> {
    public var defaultUnit: IntentParameter<Measurement<UnitEnergy>>.Energy? {
        storedDefaultUnit as? IntentParameter<Measurement<UnitEnergy>>.Energy
    }
    public var unit: IntentParameter<Measurement<UnitEnergy>>.Energy? {
        storedUnit as? IntentParameter<Measurement<UnitEnergy>>.Energy
    }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameter where Value == Measurement<UnitElectricCurrent> {
    public enum ElectricCurrent: String, CaseIterable, Hashable, Sendable {
        case kiloamperes
        case megaamperes
        case microamperes
        case milliamperes
        case amperes

        public var foundationUnit: UnitElectricCurrent {
            UnitElectricCurrent(symbol: rawValue, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    public typealias AllCases = [ElectricCurrent]
}

extension IntentParameter where Value == Measurement<UnitElectricCurrent> {
    public var defaultUnit: ElectricCurrent? { storedMeasurementDefaultUnit as? ElectricCurrent }
    public var unit: ElectricCurrent? { storedMeasurementUnit as? ElectricCurrent }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameterContext where Value == Measurement<UnitElectricCurrent> {
    public var defaultUnit: IntentParameter<Measurement<UnitElectricCurrent>>.ElectricCurrent? {
        storedDefaultUnit as? IntentParameter<Measurement<UnitElectricCurrent>>.ElectricCurrent
    }
    public var unit: IntentParameter<Measurement<UnitElectricCurrent>>.ElectricCurrent? {
        storedUnit as? IntentParameter<Measurement<UnitElectricCurrent>>.ElectricCurrent
    }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameter where Value == Measurement<UnitElectricResistance> {
    public enum ElectricResistance: String, CaseIterable, Hashable, Sendable {
        case ohms
        case kiloohms
        case megaohms
        case microohms
        case milliohms

        public var foundationUnit: UnitElectricResistance {
            UnitElectricResistance(symbol: rawValue, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    public typealias AllCases = [ElectricResistance]
}

extension IntentParameter where Value == Measurement<UnitElectricResistance> {
    public var defaultUnit: ElectricResistance? { storedMeasurementDefaultUnit as? ElectricResistance }
    public var unit: ElectricResistance? { storedMeasurementUnit as? ElectricResistance }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameterContext where Value == Measurement<UnitElectricResistance> {
    public var defaultUnit: IntentParameter<Measurement<UnitElectricResistance>>.ElectricResistance? {
        storedDefaultUnit as? IntentParameter<Measurement<UnitElectricResistance>>.ElectricResistance
    }
    public var unit: IntentParameter<Measurement<UnitElectricResistance>>.ElectricResistance? {
        storedUnit as? IntentParameter<Measurement<UnitElectricResistance>>.ElectricResistance
    }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameter where Value == Measurement<UnitElectricPotentialDifference> {
    public enum ElectricPotentialDifference: String, CaseIterable, Hashable, Sendable {
        case microvolts
        case millivolts
        case volts
        case kilovolts
        case megavolts

        public var foundationUnit: UnitElectricPotentialDifference {
            UnitElectricPotentialDifference(symbol: rawValue, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    public typealias AllCases = [ElectricPotentialDifference]
}

extension IntentParameter where Value == Measurement<UnitElectricPotentialDifference> {
    public var defaultUnit: ElectricPotentialDifference? { storedMeasurementDefaultUnit as? ElectricPotentialDifference }
    public var unit: ElectricPotentialDifference? { storedMeasurementUnit as? ElectricPotentialDifference }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameterContext where Value == Measurement<UnitElectricPotentialDifference> {
    public var defaultUnit: IntentParameter<Measurement<UnitElectricPotentialDifference>>.ElectricPotentialDifference? {
        storedDefaultUnit as? IntentParameter<Measurement<UnitElectricPotentialDifference>>.ElectricPotentialDifference
    }
    public var unit: IntentParameter<Measurement<UnitElectricPotentialDifference>>.ElectricPotentialDifference? {
        storedUnit as? IntentParameter<Measurement<UnitElectricPotentialDifference>>.ElectricPotentialDifference
    }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameter where Value == Measurement<UnitSpeed> {
    public enum Speed: String, CaseIterable, Hashable, Sendable {
        case milesPerHour
        case metersPerSecond
        case kilometersPerHour
        case knots

        public var foundationUnit: UnitSpeed {
            UnitSpeed(symbol: rawValue, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    public typealias AllCases = [Speed]
}

extension IntentParameter where Value == Measurement<UnitSpeed> {
    public var defaultUnit: Speed? { storedMeasurementDefaultUnit as? Speed }
    public var unit: Speed? { storedMeasurementUnit as? Speed }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameterContext where Value == Measurement<UnitSpeed> {
    public var defaultUnit: IntentParameter<Measurement<UnitSpeed>>.Speed? {
        storedDefaultUnit as? IntentParameter<Measurement<UnitSpeed>>.Speed
    }
    public var unit: IntentParameter<Measurement<UnitSpeed>>.Speed? {
        storedUnit as? IntentParameter<Measurement<UnitSpeed>>.Speed
    }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameter where Value == Measurement<UnitTemperature> {
    public enum Temperature: String, CaseIterable, Hashable, Sendable {
        case fahrenheit
        case kelvin
        case celsius

        public var foundationUnit: UnitTemperature {
            UnitTemperature(symbol: rawValue, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    public typealias AllCases = [Temperature]
}

extension IntentParameter where Value == Measurement<UnitTemperature> {
    public var defaultUnit: Temperature? { storedMeasurementDefaultUnit as? Temperature }
    public var unit: Temperature? { storedMeasurementUnit as? Temperature }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameterContext where Value == Measurement<UnitTemperature> {
    public var defaultUnit: IntentParameter<Measurement<UnitTemperature>>.Temperature? {
        storedDefaultUnit as? IntentParameter<Measurement<UnitTemperature>>.Temperature
    }
    public var unit: IntentParameter<Measurement<UnitTemperature>>.Temperature? {
        storedUnit as? IntentParameter<Measurement<UnitTemperature>>.Temperature
    }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameter where Value == Measurement<UnitFuelEfficiency> {
    public enum FuelEfficiency: String, CaseIterable, Hashable, Sendable {
        case milesPerGallon
        case litersPer100Kilometers
        case milesPerImperialGallon

        public var foundationUnit: UnitFuelEfficiency {
            UnitFuelEfficiency(symbol: rawValue, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    public typealias AllCases = [FuelEfficiency]
}

extension IntentParameter where Value == Measurement<UnitFuelEfficiency> {
    public var defaultUnit: FuelEfficiency? { storedMeasurementDefaultUnit as? FuelEfficiency }
    public var unit: FuelEfficiency? { storedMeasurementUnit as? FuelEfficiency }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameterContext where Value == Measurement<UnitFuelEfficiency> {
    public var defaultUnit: IntentParameter<Measurement<UnitFuelEfficiency>>.FuelEfficiency? {
        storedDefaultUnit as? IntentParameter<Measurement<UnitFuelEfficiency>>.FuelEfficiency
    }
    public var unit: IntentParameter<Measurement<UnitFuelEfficiency>>.FuelEfficiency? {
        storedUnit as? IntentParameter<Measurement<UnitFuelEfficiency>>.FuelEfficiency
    }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameter where Value == Measurement<UnitAcceleration> {
    public enum Acceleration: String, CaseIterable, Hashable, Sendable {
        case metersPerSecondSquared
        case gravity

        public var foundationUnit: UnitAcceleration {
            UnitAcceleration(symbol: rawValue, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    public typealias AllCases = [Acceleration]
}

extension IntentParameter where Value == Measurement<UnitAcceleration> {
    public var defaultUnit: Acceleration? { storedMeasurementDefaultUnit as? Acceleration }
    public var unit: Acceleration? { storedMeasurementUnit as? Acceleration }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameterContext where Value == Measurement<UnitAcceleration> {
    public var defaultUnit: IntentParameter<Measurement<UnitAcceleration>>.Acceleration? {
        storedDefaultUnit as? IntentParameter<Measurement<UnitAcceleration>>.Acceleration
    }
    public var unit: IntentParameter<Measurement<UnitAcceleration>>.Acceleration? {
        storedUnit as? IntentParameter<Measurement<UnitAcceleration>>.Acceleration
    }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameter where Value == Measurement<UnitConcentrationMass> {
    public enum ConcentrationMass: String, CaseIterable, Hashable, Sendable {
        case gramsPerLiter
        case milligramsPerDeciliter

        public var foundationUnit: UnitConcentrationMass {
            UnitConcentrationMass(symbol: rawValue, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    public typealias AllCases = [ConcentrationMass]
}

extension IntentParameter where Value == Measurement<UnitConcentrationMass> {
    public var defaultUnit: ConcentrationMass? { storedMeasurementDefaultUnit as? ConcentrationMass }
    public var unit: ConcentrationMass? { storedMeasurementUnit as? ConcentrationMass }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameterContext where Value == Measurement<UnitConcentrationMass> {
    public var defaultUnit: IntentParameter<Measurement<UnitConcentrationMass>>.ConcentrationMass? {
        storedDefaultUnit as? IntentParameter<Measurement<UnitConcentrationMass>>.ConcentrationMass
    }
    public var unit: IntentParameter<Measurement<UnitConcentrationMass>>.ConcentrationMass? {
        storedUnit as? IntentParameter<Measurement<UnitConcentrationMass>>.ConcentrationMass
    }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameter where Value == Measurement<UnitDispersion> {
    public enum Dispersion: String, CaseIterable, Hashable, Sendable {
        case partsPerMillion

        public var foundationUnit: UnitDispersion {
            UnitDispersion(symbol: rawValue, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    public typealias AllCases = [Dispersion]
}

extension IntentParameter where Value == Measurement<UnitDispersion> {
    public var defaultUnit: Dispersion? { storedMeasurementDefaultUnit as? Dispersion }
    public var unit: Dispersion? { storedMeasurementUnit as? Dispersion }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameterContext where Value == Measurement<UnitDispersion> {
    public var defaultUnit: IntentParameter<Measurement<UnitDispersion>>.Dispersion? {
        storedDefaultUnit as? IntentParameter<Measurement<UnitDispersion>>.Dispersion
    }
    public var unit: IntentParameter<Measurement<UnitDispersion>>.Dispersion? {
        storedUnit as? IntentParameter<Measurement<UnitDispersion>>.Dispersion
    }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameter where Value == Measurement<UnitIlluminance> {
    public enum Illuminance: String, CaseIterable, Hashable, Sendable {
        case lux

        public var foundationUnit: UnitIlluminance {
            UnitIlluminance(symbol: rawValue, converter: UnitConverterLinear(coefficient: 1))
        }
    }

    public typealias AllCases = [Illuminance]
}

extension IntentParameter where Value == Measurement<UnitIlluminance> {
    public var defaultUnit: Illuminance? { storedMeasurementDefaultUnit as? Illuminance }
    public var unit: Illuminance? { storedMeasurementUnit as? Illuminance }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

extension IntentParameterContext where Value == Measurement<UnitIlluminance> {
    public var defaultUnit: IntentParameter<Measurement<UnitIlluminance>>.Illuminance? {
        storedDefaultUnit as? IntentParameter<Measurement<UnitIlluminance>>.Illuminance
    }
    public var unit: IntentParameter<Measurement<UnitIlluminance>>.Illuminance? {
        storedUnit as? IntentParameter<Measurement<UnitIlluminance>>.Illuminance
    }
    public var unitAdjustForLocale: Bool? { storedUnitAdjustForLocale }
    public var supportsNegativeNumbers: Bool? { storedSupportsNegativeNumbers }
}

