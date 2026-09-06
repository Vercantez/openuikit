import Foundation


// MARK: - EndpointConstants
//
public struct EndpointConstants {
    
    public static var shared = EndpointConstants()

    public var engineBaseURL: NSString = "https://app.simplenote.com"
    
#if os(iOS)
    public var platformName: String = "iOS"
#else
    public var platformName: String = "macOS"
#endif
}


// MARK: - Convenience Properties
//
extension EndpointConstants {

    static var platformName: String {
        shared.platformName
    }
    
    static var loginRequestURL: String {
        shared.engineBaseURL.appendingPathComponent("/account/request-login")
    }
    static var loginCompletionURL: String {
        shared.engineBaseURL.appendingPathComponent("/account/complete-login")
    }
    
    static var simplenoteVerificationURL: String {
        shared.engineBaseURL.appendingPathComponent("/account/verify-email/")
    }

    static var simplenoteRequestSignupURL: String {
        shared.engineBaseURL.appendingPathComponent("/account/request-signup")
    }
    
    static var accountDeletionURL: String {
        shared.engineBaseURL.appendingPathComponent("/account/request-delete/")
    }
}
