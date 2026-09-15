import Foundation

// Wave 17: portable in-process data-model defaults.
//
// Every member below is synchronous process-local metadata. Siri, Shortcuts,
// Spotlight, Watch workout, and snippet-UI behavior stay fail-closed or
// deferred; these defaults never claim a daemon round trip. Numerics marked
// "oracle" were pinned on 2026-09-14 with a tiny `import AppIntents` probe
// compiled by Xcode 26.1 `swiftc` (transcripts in scratch/oracle-2026-09-14/).

// MARK: - Assistant schema locality

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

// MARK: - Predictable / workout intents

extension StartWorkoutIntent {
    /// Linux has no Watch workout daemon, so there is nothing to invalidate.
    /// The call is recorded nowhere and succeeds trivially.
    public static func invalidateSuggestedWorkouts() {}
}

extension SnippetIntent {
    /// Linux presents no snippet UI, so reload is a documented no-op.
    public static func reload() {}
}

// MARK: - Resolver specification defaults

extension AppEnum {
    /// Oracle: a plain `AppEnum` vends an empty specification for itself.
    public static var defaultResolverSpecification: some ResolverSpecification {
        EmptyResolverSpecification<Self>()
    }
}

extension AppEntity {
    /// Oracle: a plain `AppEntity` vends an empty specification for itself.
    public static var defaultResolverSpecification: EmptyResolverSpecification<Self> {
        EmptyResolverSpecification()
    }
}

extension AppEntity where Self: AppEnum {
    /// Oracle: an `AppEntity`-conforming enum vends an empty specification.
    public static var defaultResolverSpecification: some ResolverSpecification {
        EmptyResolverSpecification<Self>()
    }
}

extension IntentFile {
    /// Oracle: `EmptyResolverSpecification<IntentFile>`.
    public static var defaultResolverSpecification: EmptyResolverSpecification<IntentFile> {
        EmptyResolverSpecification()
    }
}

extension IntentPerson {
    /// Oracle: `EmptyResolverSpecification<IntentPerson>`.
    public static var defaultResolverSpecification: EmptyResolverSpecification<IntentPerson> {
        EmptyResolverSpecification()
    }
}

extension IntentCurrencyAmount {
    /// Oracle: `EmptyResolverSpecification<IntentCurrencyAmount>`.
    public static var defaultResolverSpecification: EmptyResolverSpecification<IntentCurrencyAmount> {
        EmptyResolverSpecification()
    }
}

extension EntityIdentifier {
    /// Oracle: `EntityIdentifier.valueMaximumLength == 4096`.
    public static var valueMaximumLength: Int { 4096 }

    /// Oracle: `EmptyResolverSpecification<EntityIdentifier>`.
    public static var defaultResolverSpecification: EmptyResolverSpecification<EntityIdentifier> {
        EmptyResolverSpecification()
    }
}

extension IntentWidgetFamily {
    /// Oracle: `EmptyResolverSpecification<IntentWidgetFamily>`.
    public static var defaultResolverSpecification: EmptyResolverSpecification<IntentWidgetFamily> {
        EmptyResolverSpecification()
    }
}

// MARK: - Parameter summary widget-family namespace

extension ParameterSummarySwitchCondition.WidgetFamily {
    /// Host placeholder for the widget-family switch namespace. Linux never
    /// evaluates a widget family, so this records an empty branch string.
    public static var widgetFamily: ParameterSummarySwitchCondition<Intent, Value, CaseCondition> {
        ParameterSummarySwitchCondition(evaluatedDisplayString: "")
    }
}
