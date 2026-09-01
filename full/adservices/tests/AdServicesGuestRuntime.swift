import AdServices
import Foundation

@main
private enum AdServicesGuestRuntime {
    static func main() {
        precondition(
            AAAttributionErrorDomain ==
                "com.apple.ap.adservices.attributionError"
        )
        precondition(AAAttributionError.Code.networkError.rawValue == 1)
        precondition(AAAttributionError.Code.internalError.rawValue == 2)
        precondition(AAAttributionError.Code.platformNotSupported.rawValue == 3)

        do {
            _ = try AAAttribution.attributionToken()
            preconditionFailure("portable attribution must never fabricate a token")
        } catch let error as AAAttributionError {
            precondition(error.code == .platformNotSupported)
            let bridged = error as NSError
            precondition(bridged.domain == AAAttributionErrorDomain)
            precondition(bridged.code == 3)
        } catch {
            preconditionFailure("unexpected attribution error: \(error)")
        }

        print(
            "AD_SERVICES_GUEST_MACHO_OK token=unavailable " +
            "domain=\(AAAttributionErrorDomain) code=3 policy=fail-closed"
        )
    }
}
