/// Values that describe developer-defined, relative-attribution conversion values.
public enum CoarseConversionValue: String, Codable, Hashable, Sendable {
    /// A value that represents a developer-defined, coarse conversion value that is high.
    case high
    /// A value that represents a developer-defined, coarse conversion value that is low.
    case low
    /// A value that represents a developer-defined, coarse conversion value that is medium.
    case medium
}
