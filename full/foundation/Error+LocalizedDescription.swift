import FoundationEssentials

public extension Error {
    /// A human-readable description using this facade's canonical NSError
    /// domain/code bridge. `LocalizedError` remains the authoritative Swift
    /// customization point.
    var localizedDescription: String {
        if let error = self._getEmbeddedNSError() as? NSError {
            return error.localizedDescription
        }
        if let localized = self as? any LocalizedError {
            if let description = localized.errorDescription {
                return description
            }
            if let reason = localized.failureReason {
                return "The operation couldn’t be completed. \(reason)"
            }
        }
        return _convertErrorToNSError(self).localizedDescription
    }
}
