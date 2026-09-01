import Foundation

// Test-only surrounding declarations for compiling RevenueCat's exact,
// untouched AttributionFetcher and its three concrete proxy sources. They
// intentionally model only dependencies owned by other RevenueCat subsystems.

final class SystemInfo: @unchecked Sendable {
    let identifierForVendor: String? = nil

    func isOperatingSystemAtLeast(_ version: OperatingSystemVersion) -> Bool {
        _ = version
        return true
    }
}

enum ConfigureStrings: CustomStringConvertible {
    case adsupport_not_imported
    var description: String { "AdSupport not imported" }
}

enum AttributionStrings: CustomStringConvertible {
    case adservices_not_supported
    case adservices_mocking_token(String)
    case adservices_token_fetch_failed(error: Error)
    case adservices_token_unavailable_in_simulator
    case att_framework_present_but_couldnt_call_tracking_authorization_status
    case search_ads_attribution_cancelled_missing_att_framework

    var description: String {
        switch self {
        case .adservices_not_supported: "AdServices not supported"
        case let .adservices_mocking_token(token): "mock token \(token)"
        case let .adservices_token_fetch_failed(error): "token failed \(error)"
        case .adservices_token_unavailable_in_simulator: "simulator unavailable"
        case .att_framework_present_but_couldnt_call_tracking_authorization_status:
            "tracking status selector unavailable"
        case .search_ads_attribution_cancelled_missing_att_framework:
            "tracking framework unavailable"
        }
    }
}

enum Strings {
    static let configure = ConfigureStrings.self
    static let attribution = AttributionStrings.self
}

enum Logger {
    static func warn(_ message: some CustomStringConvertible) {
        _ = message.description
    }

    static func appleWarning(_ message: some CustomStringConvertible) {
        _ = message.description
    }
}

func RCTestAssertNotMainThread(
    file: StaticString = #fileID,
    line: UInt = #line
) {
    _ = file
    _ = line
}

extension String {
    func rot13() -> String { self }
}

@main
private enum RevenueCatAttributionRuntime {
    static func main() async {
        let fetcher = AttributionFetcher(
            attributionFactory: AttributionTypeFactory(),
            systemInfo: SystemInfo()
        )
        let token = await fetcher.adServicesToken
        precondition(token == nil)
        print(
            "REVENUECAT_ADSERVICES_UNTOUCHED_MACHO_OK " +
            "commit=57043e7 source=f15a4f4 token=unavailable"
        )
    }
}
