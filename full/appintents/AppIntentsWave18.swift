import Foundation

// Wave 18: portable in-process coverage for leftover declared surface.
//
// Everything below runs in-process on Linux. Siri, Shortcuts, Spotlight,
// Watch workout, snippet UI, and Apple-service behavior stay fail-closed or
// deferred; these members store metadata or record local state and never
// claim a daemon round trip. Deliberate deviations from Apple's spelling are
// documented inline:
// - Builder `buildBlock` overloads take homogeneous predictions/conditions
//   and return count-preserving `[Any]` stores. Apple's arities combine
//   heterogeneous tuples; the host toolchain cannot express those tuple
//   arities without variadic generics, so arity sampling preserves the
//   observable behavior (component count) instead.
// - `withResolvers` and summary/condition builder closures take plain
//   closures. The host toolchain rejects result-builder attributes whose
//   generic arguments mention enclosing generic parameters (same deviation
//   waves 15/16 took); resolver specs and display strings are still stored.
// - Sequence comparator overloads constrain on `Sequence` plus a new host
//   `_SequenceIntentValue` marker instead of Apple's underscored protocol.
// - `CSSearchableItem(appEntity:)` records nothing: Linux never writes
//   `CSSearchableIndex`, and macOS uses the real designated initializer.

// MARK: - Query and condition aliases

extension EntityPropertyQuery {
    /// Property wrapper used by entity-property declarations.
    public typealias Property = EntityQueryProperty
}

extension ParameterSummaryTupleCaseCondition {
    public typealias Summary = Never
}

// MARK: - Assistant schema locality defaults

extension AssistantSchemaEnum {
    /// Oracle: a plain `AssistantSchemaEnum` reports `false`.
    public static var isAssistantOnly: Bool { false }
}

extension AssistantSchemaEntity {
    /// Oracle: a plain `AssistantSchemaEntity` reports `false`.
    public static var isAssistantOnly: Bool { false }
}

extension AssistantSchemaIntent {
    /// Oracle: a plain `AssistantSchemaIntent` reports `false`.
    public static var isAssistantOnly: Bool { false }
}

// MARK: - Comparator stored-transform accessors

extension EqualToComparator {
    public var mappingTransform: ((PropertyType) -> ComparatorMappingType)? {
        get { hostMappingTransform as? ((PropertyType) -> ComparatorMappingType) }
        set { hostMappingTransform = newValue }
    }
}

extension NotEqualToComparator {
    public var mappingTransform: ((PropertyType) -> ComparatorMappingType)? {
        get { hostMappingTransform as? ((PropertyType) -> ComparatorMappingType) }
        set { hostMappingTransform = newValue }
    }
}

extension IsBetweenComparator {
    public var mappingTransform: ((InputType, InputType) -> ComparatorMappingType)? {
        get { hostMappingTransform as? ((InputType, InputType) -> ComparatorMappingType) }
        set { hostMappingTransform = newValue }
    }
}

extension ContainsComparator {
    public var mappingTransform: ((InputType) -> ComparatorMappingType)? {
        get { hostMappingTransform as? ((InputType) -> ComparatorMappingType) }
        set { hostMappingTransform = newValue }
    }
}

extension HasPrefixComparator {
    public var mappingTransform: ((InputType) -> ComparatorMappingType)? {
        get { hostMappingTransform as? ((InputType) -> ComparatorMappingType) }
        set { hostMappingTransform = newValue }
    }
}

extension HasSuffixComparator {
    public var mappingTransform: ((InputType) -> ComparatorMappingType)? {
        get { hostMappingTransform as? ((InputType) -> ComparatorMappingType) }
        set { hostMappingTransform = newValue }
    }
}

// MARK: - Sequence intent values

/// Host marker for sequence-backed intent values. Comparators use it to pick
/// element-wise overloads; nothing is sent to a query daemon.
public protocol _SequenceIntentValue: _IntentValue, Sequence {}

extension Array: _SequenceIntentValue where Element: _IntentValue {}

// MARK: - Nil-literal and sequence comparator overloads

extension ContainsComparator
where Property: EntityProperty<PropertyType>, PropertyType: _IntentValue, PropertyType: Sendable,
    PropertyType: ExpressibleByNilLiteral, PropertyType.UnwrappedType == String, InputType == String
{
    public convenience init(mappingTransform: @escaping (InputType) -> ComparatorMappingType) {
        self.init()
        self.mappingTransform = mappingTransform
    }
    public convenience init<Spec: ResolverSpecification>(
        withResolvers resolvers: @escaping () -> Spec,
        mappingTransform: @escaping (InputType) -> ComparatorMappingType
    ) {
        self.init()
        self.mappingTransform = mappingTransform
        hostResolverSpecification = resolvers()
    }
}

extension ContainsComparator
where Property: EntityProperty<PropertyType>, PropertyType: _IntentValue, PropertyType: Sendable,
    PropertyType: ExpressibleByNilLiteral, PropertyType.UnwrappedType == AttributedString,
    InputType == AttributedString
{
    public convenience init(mappingTransform: @escaping (InputType) -> ComparatorMappingType) {
        self.init()
        self.mappingTransform = mappingTransform
    }
    public convenience init<Spec: ResolverSpecification>(
        withResolvers resolvers: @escaping () -> Spec,
        mappingTransform: @escaping (InputType) -> ComparatorMappingType
    ) {
        self.init()
        self.mappingTransform = mappingTransform
        hostResolverSpecification = resolvers()
    }
}

extension ContainsComparator
where Property: EntityProperty<PropertyType>, PropertyType: _IntentValue, PropertyType: Sendable,
    PropertyType: _SequenceIntentValue, PropertyType: Sequence,
    InputType: Equatable, InputType == PropertyType.Element
{
    public convenience init(mappingTransform: @escaping (InputType) -> ComparatorMappingType) {
        self.init()
        self.mappingTransform = mappingTransform
    }
    public convenience init<Spec: ResolverSpecification>(
        withResolvers resolvers: @escaping () -> Spec,
        mappingTransform: @escaping (InputType) -> ComparatorMappingType
    ) {
        self.init()
        self.mappingTransform = mappingTransform
        hostResolverSpecification = resolvers()
    }
}

extension ContainsComparator
where Property: EntityProperty<PropertyType>, PropertyType: _IntentValue, PropertyType: Sendable,
    PropertyType: ExpressibleByNilLiteral, PropertyType.UnwrappedType: _SequenceIntentValue,
    PropertyType.UnwrappedType: Sequence,
    InputType: Equatable, InputType == PropertyType.UnwrappedType.Element
{
    public convenience init(mappingTransform: @escaping (InputType) -> ComparatorMappingType) {
        self.init()
        self.mappingTransform = mappingTransform
    }
    public convenience init<Spec: ResolverSpecification>(
        withResolvers resolvers: @escaping () -> Spec,
        mappingTransform: @escaping (InputType) -> ComparatorMappingType
    ) {
        self.init()
        self.mappingTransform = mappingTransform
        hostResolverSpecification = resolvers()
    }
}

extension HasPrefixComparator
where Property: EntityProperty<PropertyType>, PropertyType: _IntentValue, PropertyType: Sendable,
    PropertyType: ExpressibleByNilLiteral, PropertyType.UnwrappedType == String, InputType == String
{
    public convenience init(mappingTransform: @escaping (InputType) -> ComparatorMappingType) {
        self.init()
        self.mappingTransform = mappingTransform
    }
    public convenience init<Spec: ResolverSpecification>(
        withResolvers resolvers: @escaping () -> Spec,
        mappingTransform: @escaping (InputType) -> ComparatorMappingType
    ) {
        self.init()
        self.mappingTransform = mappingTransform
        hostResolverSpecification = resolvers()
    }
}

extension HasSuffixComparator
where Property: EntityProperty<PropertyType>, PropertyType: _IntentValue, PropertyType: Sendable,
    PropertyType: ExpressibleByNilLiteral, PropertyType.UnwrappedType == String, InputType == String
{
    public convenience init(mappingTransform: @escaping (InputType) -> ComparatorMappingType) {
        self.init()
        self.mappingTransform = mappingTransform
    }
    public convenience init<Spec: ResolverSpecification>(
        withResolvers resolvers: @escaping () -> Spec,
        mappingTransform: @escaping (InputType) -> ComparatorMappingType
    ) {
        self.init()
        self.mappingTransform = mappingTransform
        hostResolverSpecification = resolvers()
    }
}

// MARK: - Prediction builders

extension IntentPredictionsBuilder {
    /// Count-preserving in-process combination. Linux predicts nothing.
    public static func buildBlock() -> [Any] { [] }
    public static func buildBlock<Intent: AppIntent, Value: _IntentValue>(
        _ prediction: IntentPrediction<Intent, Value>
    ) -> [Any] {
        [prediction]
    }
    public static func buildBlock<Intent0: AppIntent, Value0: _IntentValue, Intent1: AppIntent, Value1: _IntentValue>(
        _ first: IntentPrediction<Intent0, Value0>,
        _ second: IntentPrediction<Intent1, Value1>
    ) -> [Any] {
        [first, second]
    }
    public static func buildBlock<Intent0: AppIntent, Value0: _IntentValue, Intent1: AppIntent, Value1: _IntentValue, Intent2: AppIntent, Value2: _IntentValue>(
        _ first: IntentPrediction<Intent0, Value0>,
        _ second: IntentPrediction<Intent1, Value1>,
        _ third: IntentPrediction<Intent2, Value2>
    ) -> [Any] {
        [first, second, third]
    }
    public static func buildExpression<Intent: AppIntent, Value: _IntentValue>(
        _ prediction: IntentPrediction<Intent, Value>
    ) -> IntentPrediction<Intent, Value> {
        prediction
    }
}

extension ParameterSummaryCaseBuilder {
    /// Count-preserving in-process combination. Linux never matches a case.
    public static func buildBlock() -> [Any] { [] }
    public static func buildBlock<C0>(_ first: C0) -> [Any] { [first] }
    public static func buildBlock<C0, C1>(_ first: C0, _ second: C1) -> [Any] {
        [first, second]
    }
    public static func buildBlock<C0, C1, C2>(_ first: C0, _ second: C1, _ third: C2) -> [Any] {
        [first, second, third]
    }
    public static func buildExpression<C>(_ condition: C) -> C { condition }
}

// MARK: - Intent predictions

extension IntentPrediction {
    public init<A0: _IntentValue & Sendable>(
        parameters: (A0, IntentParameter<A0>, KeyPath<Intent, IntentParameter<A0>>),
        displayRepresentation: @escaping (A0) -> DisplayRepresentation
    ) {
        self.init()
        _ = displayRepresentation
    }
    public init<A0: _IntentValue & Sendable, A1: _IntentValue & Sendable>(
        parameters: (
            (A0, IntentParameter<A0>, KeyPath<Intent, IntentParameter<A0>>),
            (A1, IntentParameter<A1>, KeyPath<Intent, IntentParameter<A1>>)
        ),
        displayRepresentation: @escaping (A0, A1) -> DisplayRepresentation
    ) {
        self.init()
        _ = displayRepresentation
    }
    public init<A0: _IntentValue & Sendable, A1: _IntentValue & Sendable, A2: _IntentValue & Sendable>(
        parameters: (
            (A0, IntentParameter<A0>, KeyPath<Intent, IntentParameter<A0>>),
            (A1, IntentParameter<A1>, KeyPath<Intent, IntentParameter<A1>>),
            (A2, IntentParameter<A2>, KeyPath<Intent, IntentParameter<A2>>)
        ),
        displayRepresentation: @escaping (A0, A1, A2) -> DisplayRepresentation
    ) {
        self.init()
        _ = displayRepresentation
    }
    public init(displayRepresentation: @escaping () -> DisplayRepresentation) {
        self.init()
        _ = displayRepresentation
    }
    public init(
        _ keyPath: KeyPath<Intent, IntentParameter<T>>,
        displayRepresentation: @escaping (T) -> DisplayRepresentation
    ) where T: _IntentValue, T: Sendable {
        self.init()
        _ = keyPath
        _ = displayRepresentation
    }
}

// MARK: - Parameter summary conditions

extension ParameterSummaryCaseCondition {
    public init(_ value: Value, _ parameterSummary: () -> Summary) {
        self.init()
        matched = value
        evaluatedDisplayString = (parameterSummary() as? any ParameterSummary)?.evaluatedDisplayString ?? ""
    }
    public init(_ values: [Value], _ parameterSummary: () -> Summary) {
        self.init()
        matched = values.first
        evaluatedDisplayString = (parameterSummary() as? any ParameterSummary)?.evaluatedDisplayString ?? ""
    }
}

extension ParameterSummarySwitchCondition {
    public init(
        _ keyPath: KeyPath<Intent, IntentParameter<Value>>,
        _ builder: () -> CaseCondition
    ) where Value: _IntentValue, Value: Sendable {
        self.init()
        _ = keyPath
        evaluatedDisplayString = (builder() as? any ParameterSummary)?.evaluatedDisplayString ?? ""
    }
    public init(
        _ widgetFamily: WidgetFamily,
        _ builder: () -> CaseCondition
    ) where Value == IntentWidgetFamily {
        self.init()
        _ = widgetFamily
        evaluatedDisplayString = (builder() as? any ParameterSummary)?.evaluatedDisplayString ?? ""
    }
}

extension ParameterSummaryDefaultCaseCondition {
    public init(_ parameterSummary: () -> Summary) {
        self.init()
        evaluatedDisplayString = (parameterSummary() as? any ParameterSummary)?.evaluatedDisplayString ?? ""
    }
}

// MARK: - Shortcut presentation initializer

extension AppShortcut {
    public init<
        Intent: AppIntent, Value: _IntentValue & Sendable,
        Parameter: IntentParameter<Value>, ParameterKeyPath: KeyPath<Intent, Parameter>
    >(
        intent: Intent,
        phrases: [AppShortcutPhrase<Intent>],
        shortTitle: LocalizedStringResource,
        systemImageName: String,
        parameterPresentation: AppShortcutParameterPresentation<Intent, Value, Parameter, ParameterKeyPath>
    ) {
        self.init(intent: intent, phrases: phrases, shortTitle: shortTitle, systemImageName: systemImageName)
        _ = parameterPresentation
    }
}

// MARK: - Fail-closed initializers

extension OpenURLIntent {
    /// Linux has no URL-representation registry, so resolving an
    /// enum-backed URL stays fail-closed instead of inventing a URL.
    public init(urlRepresentable: some URLRepresentableEnum) throws {
        _ = urlRepresentable
        throw AppIntentError.Unrecoverable.unsupportedOnDevice
    }
}

extension ShortcutsLink {
    /// Linux presents no Shortcuts UI; the action is accepted and never run.
    public init(action: @escaping () -> Void) {
        self.init()
        _ = action
    }
}

extension CSSearchableItem {
    /// Linux never writes `CSSearchableIndex`; the item carries no payload.
    public convenience init<Entity: IndexedEntity>(appEntity: Entity) {
        #if canImport(CoreSpotlight)
        self.init(
            uniqueIdentifier: String(describing: Entity.self) + "/" + String(describing: appEntity.id),
            domainIdentifier: nil
        )
        #else
        self.init()
        #endif
        _ = appEntity
    }
    /// Linux never writes `CSSearchableIndex`; priority is recorded nowhere.
    public convenience init<Entity: IndexedEntity>(appEntity: Entity, priority: Int) {
        #if canImport(CoreSpotlight)
        self.init(
            uniqueIdentifier: String(describing: Entity.self) + "/" + String(describing: appEntity.id),
            domainIdentifier: nil
        )
        #else
        self.init()
        #endif
        _ = appEntity
        _ = priority
    }
}
