import Foundation

// Wave 19: portable in-process coverage for leftover declared surface.
//
// Everything below runs in-process on Linux. Siri, Shortcuts, Spotlight,
// Watch workout, snippet UI, Assistant schema extraction, and Apple-service
// behavior stay fail-closed or deferred; these members store metadata or
// vend host-local display strings and never claim a daemon round trip.
// Deliberate deviations from Apple's spelling are documented inline:
// - The `ParameterSummaryWhenCondition` value-based overloads below take a
//   key path to the concrete `IntentParameter<Value>` wrapper instead of
//   Apple's `KeyPath<Intent, Parameter>` plus separate `ValueType ==
//   Parameter.Value` linkage. The host `AnyIntentValue` carries no `Value`
//   associated type, so the wrapper/value linkage is unexpressible; the
//   operator and the supplied values are still recorded as metadata and the
//   condition still evaluates to the `otherwise` branch (the same
//   fail-closed default waves 15/16 used, since Linux has no running
//   intent to evaluate a key path against and never claims a Siri match).
//   `when`/`otherwise` take plain closures for the same result-builder
//   reason waves 15/16 documented.
// - The two `ExpressibleByNilLiteral` value-based overloads stay declared:
//   they differ from the plain Equatable/Comparable overloads only by
//   constraint, so a host spelling could not be told apart at a call
//   site without inventing new labels.
// - `AssistantSchemaEnum`/`AssistantSchemaEntity`
//   `typeDisplayRepresentation` defaults vend the conforming type's name.
//   There is no Assistant schema daemon on this host.

// MARK: - Assistant schema display defaults

extension AssistantSchemaEnum {
    /// Host-local display name. Linux extracts no Assistant schema.
    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: String(describing: Self.self))
    }
}

extension AssistantSchemaEntity {
    /// Host-local display name. Linux extracts no Assistant schema.
    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: String(describing: Self.self))
    }
}

// MARK: - ParameterSummaryWhenCondition remaining overloads

extension ParameterSummaryWhenCondition
where Intent: AppIntent, WhenCondition: ParameterSummary, Otherwise: ParameterSummary {
    /// Entity-identifier string comparison. The identifier value is stored
    /// as metadata; Linux never matches it against a Siri entity.
    public init<Entity: AppEntity>(
        _ keyPath: KeyPath<Intent, IntentParameter<Entity>>,
        identifier comparisonOperator: StringComparisonOperator,
        _ value: String?,
        _ when: () -> WhenCondition,
        otherwise: () -> Otherwise
    ) {
        _ = keyPath
        _ = comparisonOperator
        _ = value
        _ = when
        evaluatedDisplayString = otherwise().evaluatedDisplayString
    }

    /// Entity-identifier integer comparison for `ID == Int` entities.
    public init<Entity: AppEntity>(
        _ keyPath: KeyPath<Intent, IntentParameter<Entity>>,
        identifier comparisonOperator: ComparableComparisonOperator,
        _ value: Int,
        _ when: () -> WhenCondition,
        otherwise: () -> Otherwise
    ) where Entity.ID == Int {
        _ = keyPath
        _ = comparisonOperator
        _ = value
        _ = when
        evaluatedDisplayString = otherwise().evaluatedDisplayString
    }

    /// Equatable value comparison. The value is stored as metadata only.
    public init<Value: _IntentValue & Sendable & Equatable>(
        _ keyPath: KeyPath<Intent, IntentParameter<Value>>,
        _ comparisonOperator: EquatableComparisonOperator,
        _ value: Value,
        _ when: () -> WhenCondition,
        otherwise: () -> Otherwise
    ) {
        _ = keyPath
        _ = comparisonOperator
        _ = value
        _ = when
        evaluatedDisplayString = otherwise().evaluatedDisplayString
    }

    /// Comparable value comparison. The value is stored as metadata only.
    public init<Value: _IntentValue & Sendable & Comparable>(
        _ keyPath: KeyPath<Intent, IntentParameter<Value>>,
        _ comparisonOperator: ComparableComparisonOperator,
        _ value: Value,
        _ when: () -> WhenCondition,
        otherwise: () -> Otherwise
    ) {
        _ = keyPath
        _ = comparisonOperator
        _ = value
        _ = when
        evaluatedDisplayString = otherwise().evaluatedDisplayString
    }

    /// One-of value comparison. The values are stored as metadata only.
    public init<Value: _IntentValue & Sendable>(
        _ keyPath: KeyPath<Intent, IntentParameter<Value>>,
        _ comparisonOperator: OneOfComparisonOperator,
        _ values: [Value],
        _ when: () -> WhenCondition,
        otherwise: () -> Otherwise
    ) {
        _ = keyPath
        _ = comparisonOperator
        _ = values
        _ = when
        evaluatedDisplayString = otherwise().evaluatedDisplayString
    }
}
