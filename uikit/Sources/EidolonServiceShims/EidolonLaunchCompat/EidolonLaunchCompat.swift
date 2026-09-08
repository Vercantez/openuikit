import Foundation
import Keys

public enum EidolonLaunchError: Error, CustomStringConvertible {
    case serviceCredentialsUnavailable

    public var description: String {
        "Eidolon launch blocked: Artsy service credentials and a verified unavailable network transport are absent. Empty credentials would enable successful bundled sample responses. No app delegate or network provider was constructed."
    }
}

/// A gate before the unchanged app is initialized, not a replacement screen.
public enum EidolonLaunchCompat {
    public static func preflight() throws {
        // AppDelegate.swift:18 constructs Networking.newDefaultNetworking() in
        // a stored-property initializer. APIKeys.swift:31 chooses demo responses
        // for key/secret lengths < 2. Therefore this check must precede the
        // AppDelegate initializer, not just didFinishLaunchingWithOptions.
        guard EidolonKeys.servicesAvailable else {
            throw EidolonLaunchError.serviceCredentialsUnavailable
        }
    }

    /// The closure owns the actual AppDelegate/application construction. It
    /// cannot run while the service boundary is unavailable.
    public static func withLaunchPreflight<Application>(
        _ createApplication: () throws -> Application
    ) throws -> Application {
        try preflight()
        return try createApplication()
    }
}
