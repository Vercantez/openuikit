/// Policy for enabling or disabling personalization in the system interface.
///
/// Raw values follow Swift's default `Int` assignment in symbol-graph case
/// order (`automatic` = 0, `enabled` = 1, `disabled` = 2). Apple's runtime
/// integers are not in the pinned public inputs; see `oracle-questions.tsv`.
public enum ImagePlaygroundPersonalizationPolicy: Int, Hashable, Sendable {
    /// Choose the most appropriate personalization behavior.
    ///
    /// Apple's documentation says this equals ``enabled`` by default. Linux
    /// still preserves the distinct case so callers can round-trip the policy.
    case automatic = 0
    /// Enable personalization features.
    case enabled = 1
    /// Disable personalization features.
    case disabled = 2
}
