import Foundation

/// Apple's public Automatic Assessment error domain string
/// (`AEAssessmentErrorDomain`).
public let AEAssessmentErrorDomain = "AEAssessmentErrorDomain"

/// Linux user-info key for `AEAssessmentError.notInstalledParticipants`.
///
/// The Darwin `AENotInstalledParticipantsKey` NSString payload is unobserved;
/// this overlay uses the ObjC field name until an Apple-oracle probe records
/// the live bytes.
let AENotInstalledParticipantsUserInfoKey = "AENotInstalledParticipantsKey"

/// Linux user-info key for `AEAssessmentError.restrictedSystemParticipants`.
let AERestrictedSystemParticipantsUserInfoKey = "AERestrictedSystemParticipantsKey"

/// Portable counterpart of Automatic Assessment's bridged
/// `NS_ERROR_ENUM(AEAssessmentErrorDomain)`.
///
/// Numeric codes follow the public Xcode 26.1 / pinned macios
/// `AEAssessmentErrorCode` order (`unknown = 1` through
/// `requiredParticipantsNotAvailable = 5`). Stored `userInfo` is preserved
/// exactly; this overlay does not insert a default localized-description
/// entry.
public struct AEAssessmentError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case unknown = 1
        case unsupportedPlatform = 2
        case multipleParticipantsNotSupported = 3
        case configurationUpdatesNotSupported = 4
        case requiredParticipantsNotAvailable = 5
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { AEAssessmentErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public var localizedDescription: String {
        if let description = userInfo[NSLocalizedDescriptionKey] as? String {
            return description
        }
        return "The operation couldn’t be completed. (\(AEAssessmentErrorDomain) error \(errorCode).)"
    }

    public static var unknown: Code { .unknown }
    public static var unsupportedPlatform: Code { .unsupportedPlatform }
    public static var multipleParticipantsNotSupported: Code { .multipleParticipantsNotSupported }
    public static var configurationUpdatesNotSupported: Code { .configurationUpdatesNotSupported }
    public static var requiredParticipantsNotAvailable: Code { .requiredParticipantsNotAvailable }

    /// Bundle identifiers of participant apps that are not installed.
    ///
    /// Linux reads `[String]` (or an `NSArray` of strings) from
    /// `AENotInstalledParticipantsUserInfoKey`. Darwin key bytes are
    /// unobserved.
    public var notInstalledParticipants: [String]? {
        stringArray(for: AENotInstalledParticipantsUserInfoKey)
    }

    /// Bundle identifiers of restricted system participant apps.
    public var restrictedSystemParticipants: [String]? {
        stringArray(for: AERestrictedSystemParticipantsUserInfoKey)
    }

    public static func == (lhs: AEAssessmentError, rhs: AEAssessmentError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    private func stringArray(for key: String) -> [String]? {
        if let strings = userInfo[key] as? [String] {
            return strings
        }
        if let array = userInfo[key] as? NSArray {
            let strings = array.compactMap { $0 as? String }
            if strings.count == array.count {
                return strings
            }
        }
        return nil
    }
}

extension AEAssessmentError.Code {
    public static func ~= (match: AEAssessmentError.Code, error: any Error) -> Bool {
        (error as? AEAssessmentError)?.code == match
    }
}
