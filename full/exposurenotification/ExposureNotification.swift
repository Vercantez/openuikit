import Dispatch
import Foundation

// Linux starting point for Apple's ExposureNotification. There is no
// Exposure Notification daemon, Bluetooth TEK radio, entitlement prompt,
// or Apple diagnosis-key service on this host. Value types, error codes,
// configuration storage, and the ENManager lifecycle are implemented here.
// Daemon, hardware, and privacy-gated operations fail closed.

/// Darwin `dispatch_queue_t` overlay used by `ENManager.dispatchQueue`.
public typealias dispatch_queue_t = DispatchQueue

// MARK: - Scalar aliases (ENCommon.h)

public typealias ENAttenuation = UInt8
public typealias ENIntervalNumber = UInt32
public typealias ENRiskLevel = UInt8
public typealias ENRiskLevelValue = UInt8
public typealias ENRiskScore = UInt8

// MARK: - Handler aliases

public typealias ENActivityHandler = (ENActivityFlags) -> Void
public typealias ENDetectExposuresHandler = (ENExposureDetectionSummary?, (any Error)?) -> Void
public typealias ENDiagnosisKeysAvailableHandler = ([ENTemporaryExposureKey]) -> Void
public typealias ENErrorHandler = ((any Error)?) -> Void
/// Darwin uses `AutoreleasingUnsafeMutablePointer`; that type is absent on
/// Linux Swift. The pointed-to type is preserved.
public typealias ENErrorOutType = UnsafeMutablePointer<NSError?>
public typealias ENGetDiagnosisKeysHandler = ([ENTemporaryExposureKey]?, (any Error)?) -> Void
public typealias ENGetExposureInfoHandler = ([ENExposureInfo]?, (any Error)?) -> Void
public typealias ENGetExposureWindowsHandler = ([ENExposureWindow]?, (any Error)?) -> Void
public typealias ENGetUserTraveledHandler = (Bool, (any Error)?) -> Void

// MARK: - Constants
//
// Integer bounds match the objc2-exposure-notification bindings generated
// from Apple's ENCommon.h (`ENAttenuationMin = 0` … `ENRiskWeightMaxV2 = 250`).
// `ENDaysSinceOnsetOfSymptomsUnknown` is an exported NSInteger sentinel used as
// a dictionary key for unspecified onset; this port uses `Int32.max` because
// the matching protobuf field is int32. NSIntegerMax vs INT32_MAX is an
// oracle question.

public let ENErrorDomain = "ENErrorDomain"

public let ENDaysSinceOnsetOfSymptomsUnknown: Int = Int(Int32.max)

public var ENAttenuationMin: Int { 0 }
public var ENAttenuationMax: Int { 0xFF }

public var ENRiskLevelMin: Int { 0 }
public var ENRiskLevelMax: Int { 7 }

public var ENRiskLevelValueMin: Int { 0 }
public var ENRiskLevelValueMax: Int { 8 }

public var ENRiskScoreMin: Int { 0 }
public var ENRiskScoreMax: Int { 255 }

public var ENRiskWeightDefault: Int { 1 }
public var ENRiskWeightDefaultV2: Int { 100 }
public var ENRiskWeightMax: Int { 100 }
public var ENRiskWeightMaxV2: Int { 250 }
public var ENRiskWeightMin: Int { 0 }

/// C macro `EN_FEATURE_GENERAL`. Apple's header bytes are absent; this port
/// treats the feature-general compile flag as 1 (enabled in the SDK graph).
public var EN_FEATURE_GENERAL: Int32 { 1 }

// MARK: - Activity flags (NS_OPTIONS UInt32)

public struct ENActivityFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let reserved1 = ENActivityFlags(rawValue: 1 << 0)
    public static let reserved2 = ENActivityFlags(rawValue: 1 << 1)
    public static let periodicRun = ENActivityFlags(rawValue: 1 << 2)
    public static let preAuthorizedKeyReleaseNotificationTapped = ENActivityFlags(rawValue: 1 << 3)
}

// MARK: - Enumerations
//
// Raw values follow NS_ENUM sequential assignment from Apple's documented
// case order (unknown/lowest/none = 0) and the API-digester child order for
// ENError.Code (unknown = 1 … travelStatusNotAvailable = 17).

public enum ENAuthorizationStatus: Int, Equatable, Hashable, Sendable {
    case unknown = 0
    case restricted = 1
    case notAuthorized = 2
    case authorized = 3
}

public enum ENStatus: Int, Equatable, Hashable, Sendable {
    case unknown = 0
    case active = 1
    case disabled = 2
    case bluetoothOff = 3
    case restricted = 4
    case paused = 5
    case unauthorized = 6
}

public enum ENCalibrationConfidence: UInt8, Equatable, Hashable, Sendable {
    case lowest = 0
    case low = 1
    case medium = 2
    case high = 3
}

public enum ENInfectiousness: UInt32, Equatable, Hashable, Sendable {
    case none = 0
    case standard = 1
    case high = 2
}

public enum ENDiagnosisReportType: UInt32, Equatable, Hashable, Sendable {
    case unknown = 0
    case confirmedTest = 1
    case confirmedClinicalDiagnosis = 2
    case selfReported = 3
    case recursive = 4
    case revoked = 5
}

public enum ENVariantOfConcernType: UInt32, Equatable, Hashable, Sendable {
    case typeUnknown = 0
    case type1 = 1
    case type2 = 2
    case type3 = 3
    case type4 = 4
}

// MARK: - ENError (NS_ERROR_ENUM overlay)

/// Bridged Exposure Notification error.
///
/// Raw values are the NS_ERROR_ENUM integers `unknown = 1` through
/// `travelStatusNotAvailable = 17`, matching API-digester child order.
@frozen
public struct ENError: Foundation._BridgedStoredNSError, @unchecked Sendable {
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = ENError

        case unknown = 1
        case badParameter = 2
        case notEntitled = 3
        case notAuthorized = 4
        case unsupported = 5
        case invalidated = 6
        case bluetoothOff = 7
        case insufficientStorage = 8
        case notEnabled = 9
        case apiMisuse = 10
        case `internal` = 11
        case insufficientMemory = 12
        case rateLimited = 13
        case restricted = 14
        case badFormat = 15
        case dataInaccessible = 16
        case travelStatusNotAvailable = 17
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { ENErrorDomain }

    public static var errorDomain: String { ENErrorDomain }

    public static var unknown: Code { .unknown }
    public static var badParameter: Code { .badParameter }
    public static var notEntitled: Code { .notEntitled }
    public static var notAuthorized: Code { .notAuthorized }
    public static var unsupported: Code { .unsupported }
    public static var invalidated: Code { .invalidated }
    public static var bluetoothOff: Code { .bluetoothOff }
    public static var insufficientStorage: Code { .insufficientStorage }
    public static var notEnabled: Code { .notEnabled }
    public static var apiMisuse: Code { .apiMisuse }
    public static var `internal`: Code { .internal }
    public static var insufficientMemory: Code { .insufficientMemory }
    public static var rateLimited: Code { .rateLimited }
    public static var restricted: Code { .restricted }
    public static var badFormat: Code { .badFormat }
    public static var dataInaccessible: Code { .dataInaccessible }
    public static var travelStatusNotAvailable: Code { .travelStatusNotAvailable }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_nsError.domain)
        hasher.combine(_nsError.code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

extension ENError.Code {
    public static func ~= (match: ENError.Code, error: any Error) -> Bool {
        if let typed = error as? ENError {
            return typed.code == match
        }
        let nsError = error as NSError
        return nsError.domain == ENErrorDomain && nsError.code == match.rawValue
    }
}
