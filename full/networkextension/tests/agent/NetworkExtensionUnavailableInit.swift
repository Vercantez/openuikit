import NetworkExtension

/// Negative client: Apple marks `NEURLFilter.init` unavailable. This file must
/// fail typechecking against the Linux module.
enum NetworkExtensionUnavailableInitClient {
    static func attemptConstruction() {
        _ = NEURLFilter()
    }
}
