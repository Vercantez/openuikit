import FoundationEssentials

public extension Error {
    /// A human-readable description without requiring the Objective-C
    /// `NSError` bridge.
    ///
    /// `LocalizedError` remains the authoritative customization point. The
    /// descriptive fallback is deliberately truthful about the Swift error
    /// value until the complete NSError domain/code bridge is available.
    var localizedDescription: String {
        if let localized = self as? any LocalizedError {
            if let description = localized.errorDescription {
                return description
            }
            if let reason = localized.failureReason {
                return "The operation couldn’t be completed. \(reason)"
            }
        }
        return String(describing: self)
    }
}
