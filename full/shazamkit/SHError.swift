import Foundation

/// The error domain for ShazamKit failures.
///
/// Raw string is the ObjC constant name. Apple's exact CFString payload is
/// unobserved on this host; see `oracle-questions.tsv`.
public let SHErrorDomain: String = "SHErrorDomain"

/// A ShazamKit failure. Codes use the pinned dotnet-macios explicit integers
/// (secondary binding corroboration of the ordered API-digester enum).
public struct SHError: Error, CustomNSError, LocalizedError {
    public enum Code: Int, Hashable, Sendable {
        case invalidAudioFormat = 100
        case audioDiscontinuity = 101
        case signatureInvalid = 200
        case signatureDurationInvalid = 201
        case matchAttemptFailed = 202
        case customCatalogInvalid = 300
        case customCatalogInvalidURL = 301
        case mediaLibrarySyncFailed = 400
        case internalError = 500
        case mediaItemFetchFailed = 600
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { SHErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static var invalidAudioFormat: Code { .invalidAudioFormat }
    public static var audioDiscontinuity: Code { .audioDiscontinuity }
    public static var signatureInvalid: Code { .signatureInvalid }
    public static var signatureDurationInvalid: Code { .signatureDurationInvalid }
    public static var matchAttemptFailed: Code { .matchAttemptFailed }
    public static var customCatalogInvalid: Code { .customCatalogInvalid }
    public static var customCatalogInvalidURL: Code { .customCatalogInvalidURL }
    public static var mediaLibrarySyncFailed: Code { .mediaLibrarySyncFailed }
    public static var internalError: Code { .internalError }
    public static var mediaItemFetchFailed: Code { .mediaItemFetchFailed }

    public var errorDescription: String? {
        switch code {
        case .invalidAudioFormat:
            return "The audio format is invalid."
        case .audioDiscontinuity:
            return "The audio stream was discontinuous."
        case .signatureInvalid:
            return "The signature is invalid."
        case .signatureDurationInvalid:
            return "The signature duration is invalid."
        case .matchAttemptFailed:
            return "The match attempt failed."
        case .customCatalogInvalid:
            return "The custom catalog is invalid."
        case .customCatalogInvalidURL:
            return "The custom catalog URL is invalid."
        case .mediaLibrarySyncFailed:
            return "The media library could not be synchronized."
        case .internalError:
            return "An internal ShazamKit error occurred."
        case .mediaItemFetchFailed:
            return "The media item could not be fetched."
        }
    }

    public var localizedDescription: String {
        errorDescription ?? "SHError(\(code.rawValue))"
    }

    public static func == (lhs: SHError, rhs: SHError) -> Bool {
        lhs.code == rhs.code
    }

    public static func != (lhs: SHError, rhs: SHError) -> Bool {
        lhs.code != rhs.code
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

extension SHError: Hashable {}

extension SHError.Code {
    /// Matches `SHError.Code` against a thrown `SHError` (or `any Error`).
    public static func ~= (match: SHError.Code, error: any Error) -> Bool {
        if let shError = error as? SHError {
            return shError.code == match
        }
        let nsError = error as NSError
        return nsError.domain == SHErrorDomain && nsError.code == match.rawValue
    }
}
