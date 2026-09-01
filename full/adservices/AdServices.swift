@_exported import Foundation

/// Apple's public attribution error domain. Keeping the observed domain and
/// numeric codes is important because SDKs commonly log the bridged NSError.
public let AAAttributionErrorDomain =
    "com.apple.ap.adservices.attributionError"

public struct AAAttributionError: Error, CustomNSError, Equatable, Sendable {
    public struct Code: RawRepresentable, Equatable, Hashable, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let networkError = Code(rawValue: 1)
        public static let internalError = Code(rawValue: 2)
        public static let platformNotSupported = Code(rawValue: 3)
    }

    public let code: Code

    public init(_ code: Code) {
        self.code = code
    }

    public static var errorDomain: String { AAAttributionErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] {
        [
            NSLocalizedDescriptionKey:
                "Apple Ads attribution is unavailable on this host"
        ]
    }
}

/// Linux has no Apple Ads attribution daemon, App Store receipt identity, or
/// corresponding privacy boundary. Returning a fabricated token would be both
/// semantically wrong and unsafe, so this API deterministically fails closed.
@available(iOS 14.3, macOS 11.1, tvOS 14.3, *)
open class AAAttribution: NSObject {
    public class func attributionToken() throws -> String {
        throw AAAttributionError(.platformNotSupported)
    }
}
