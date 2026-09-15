import Foundation

// Wave 16: portable in-process `ParameterSummaryWhenCondition` overloads.
//
// Everything below runs in-process on Linux. The overloads record the
// comparison operator and the supplied values as metadata and evaluate to
// the `otherwise` branch string. Linux has no running intent instance to
// evaluate a key path against and no Siri summary renderer, so the host
// never claims the condition matched: the `otherwise` branch is the
// fail-closed default. Two deliberate deviations from Apple's spelling are
// documented inline:
// - `when`/`otherwise` take plain closures. Apple's spelling applies
//   `@ParameterSummaryBuilder<Intent>` to both parameters, but the host
//   toolchain rejects result-builder attributes whose generic arguments
//   mention enclosing generic parameters (the same deviation wave 15 took
//   for comparator `withResolvers` closures).
// - The `identifier` overloads constrain `Parameter: AnyIntentValue` only.
//   Apple's refinements (`Parameter.Value.ValueType: AppEntity`,
//   `Parameter.Value.ValueType.ID == Int`) are unexpressible here because
//   the host `AnyIntentValue` carries no `Value` associated type; the
//   operator and the supplied `String`/`Int`/`[String]`/`[Int]` payloads
//   are still stored as metadata and the values are never sent to Siri.

extension ParameterSummaryWhenCondition
where Intent: AppIntent, WhenCondition: ParameterSummary, Otherwise: ParameterSummary {
    public init<Parameter: AnyIntentValue>(
        _ keyPath: KeyPath<Intent, Parameter>,
        identifier comparisonOperator: StringComparisonOperator,
        _ value: String,
        _ when: () -> WhenCondition,
        otherwise: () -> Otherwise
    ) {
        _ = keyPath
        _ = comparisonOperator
        _ = value
        _ = when
        evaluatedDisplayString = otherwise().evaluatedDisplayString
    }

    public init<Parameter: AnyIntentValue>(
        _ keyPath: KeyPath<Intent, Parameter>,
        identifier comparisonOperator: EquatableComparisonOperator,
        _ value: String,
        _ when: () -> WhenCondition,
        otherwise: () -> Otherwise
    ) {
        _ = keyPath
        _ = comparisonOperator
        _ = value
        _ = when
        evaluatedDisplayString = otherwise().evaluatedDisplayString
    }

    public init<Parameter: AnyIntentValue>(
        _ keyPath: KeyPath<Intent, Parameter>,
        identifier comparisonOperator: ComparableComparisonOperator,
        _ value: Int,
        _ when: () -> WhenCondition,
        otherwise: () -> Otherwise
    ) {
        _ = keyPath
        _ = comparisonOperator
        _ = value
        _ = when
        evaluatedDisplayString = otherwise().evaluatedDisplayString
    }

    public init<Parameter: AnyIntentValue>(
        _ keyPath: KeyPath<Intent, Parameter>,
        identifier comparisonOperator: EquatableComparisonOperator,
        _ value: Int,
        _ when: () -> WhenCondition,
        otherwise: () -> Otherwise
    ) {
        _ = keyPath
        _ = comparisonOperator
        _ = value
        _ = when
        evaluatedDisplayString = otherwise().evaluatedDisplayString
    }

    public init<Parameter: AnyIntentValue>(
        _ keyPath: KeyPath<Intent, Parameter>,
        identifier comparisonOperator: OneOfComparisonOperator,
        _ values: [String],
        _ when: () -> WhenCondition,
        otherwise: () -> Otherwise
    ) {
        _ = keyPath
        _ = comparisonOperator
        _ = values
        _ = when
        evaluatedDisplayString = otherwise().evaluatedDisplayString
    }

    public init<Parameter: AnyIntentValue>(
        _ keyPath: KeyPath<Intent, Parameter>,
        identifier comparisonOperator: OneOfComparisonOperator,
        _ values: [Int],
        _ when: () -> WhenCondition,
        otherwise: () -> Otherwise
    ) {
        _ = keyPath
        _ = comparisonOperator
        _ = values
        _ = when
        evaluatedDisplayString = otherwise().evaluatedDisplayString
    }

    public init(
        widgetFamily comparisonOperator: OneOfComparisonOperator,
        _ values: [IntentWidgetFamily],
        _ when: () -> WhenCondition,
        otherwise: () -> Otherwise
    ) {
        _ = comparisonOperator
        _ = values
        _ = when
        evaluatedDisplayString = otherwise().evaluatedDisplayString
    }

    public init(
        widgetFamily comparisonOperator: EquatableComparisonOperator,
        _ value: IntentWidgetFamily,
        _ when: () -> WhenCondition,
        otherwise: () -> Otherwise
    ) {
        _ = comparisonOperator
        _ = value
        _ = when
        evaluatedDisplayString = otherwise().evaluatedDisplayString
    }

    public init<Parameter: AnyIntentValue>(
        _ keyPath: KeyPath<Intent, Parameter>,
        _ comparisonOperator: HasValueComparisonOperator,
        _ when: () -> WhenCondition,
        otherwise: () -> Otherwise
    ) {
        _ = keyPath
        _ = comparisonOperator
        _ = when
        evaluatedDisplayString = otherwise().evaluatedDisplayString
    }
}
