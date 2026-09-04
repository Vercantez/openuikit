import AdServices
import Foundation

/// Schema-v1-style local runtime probe. The sealed schema-v2 gate compiles
/// `*Tests.swift` plus generated load-smoke instead of this file.
func adServicesRuntimeProbe() {
    precondition(AAAttributionErrorDomain == "com.apple.ap.adservices.attributionError")
    precondition(AAAttributionError.Code.networkError.rawValue == 1)
    precondition(AAAttributionError.Code.internalError.rawValue == 2)
    precondition(AAAttributionError.Code.platformNotSupported.rawValue == 3)
    do {
        _ = try AAAttribution.attributionToken()
        preconditionFailure("portable attribution must never fabricate a token")
    } catch let error as AAAttributionError {
        precondition(error.code == .platformNotSupported)
    } catch {
        preconditionFailure("unexpected attribution error: \(error)")
    }
    print("ADSERVICES_AGENT_RUNTIME_OK")
}

adServicesRuntimeProbe()
