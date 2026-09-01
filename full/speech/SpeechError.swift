/// Apple's public Speech error domain string, attested by the Xcode 26.1
/// `NS_ERROR_ENUM` binding (`ErrorDomain("SFSpeechErrorDomain")`).
public let SFSpeechErrorDomain = "SFSpeechErrorDomain"

/// Bridged Speech error. Classic codes 1, 2, 7, 8, 12, 13 follow the public
/// `SFSpeechErrorCode` header. Analyzer overlay codes occupy unused integer
/// slots and are recorded as oracle questions until an Apple runtime probe
/// confirms them.
public struct SFSpeechError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case internalServiceError = 1
        case audioReadFailed = 2
        case audioDisordered = 3
        case unexpectedAudioFormat = 4
        case noModel = 5
        case incompatibleAudioFormats = 6
        case undefinedTemplateClassName = 7
        case malformedSupplementalModel = 8
        case moduleOutputFailed = 9
        case assetLocaleNotAllocated = 10
        case tooManyAssetLocalesAllocated = 11
        case timeout = 12
        case missingParameter = 13
        case cannotAllocateUnsupportedLocale = 15
        case insufficientResources = 16
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { SFSpeechErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static func == (lhs: SFSpeechError, rhs: SFSpeechError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    public static let internalServiceError = Code.internalServiceError
    public static let audioReadFailed = Code.audioReadFailed
    public static let undefinedTemplateClassName = Code.undefinedTemplateClassName
    public static let malformedSupplementalModel = Code.malformedSupplementalModel
    public static let timeout = Code.timeout
    public static let missingParameter = Code.missingParameter
}

extension SFSpeechError.Code {
    public static func ~= (match: SFSpeechError.Code, error: any Error) -> Bool {
        (error as? SFSpeechError)?.code == match
    }
}
