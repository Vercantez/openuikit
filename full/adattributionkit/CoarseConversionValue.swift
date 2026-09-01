/// Values that describe developer-defined, relative-attribution conversion values.
///
/// Raw strings follow Swift `String` enum case names from the public graph.
/// Apple's shipped raw literals are unobserved in this seed.
public enum CoarseConversionValue: String, Codable, Hashable, Sendable {
    /// A value that represents a developer-defined, coarse conversion value that is high.
    case high
    /// A value that represents a developer-defined, coarse conversion value that is low.
    case low
    /// A value that represents a developer-defined, coarse conversion value that is medium.
    case medium
}
