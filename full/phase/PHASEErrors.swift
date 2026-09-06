import Foundation

/// Bridged `PHASEError` overlay. Raw values follow the pinned
/// `dotnet/macios` `PhaseError` enumeration (`InitializeFailed = 1346913633`,
/// `InvalidObject = 1346913634`).
@frozen
public struct PHASEError: Foundation._BridgedStoredNSError, @unchecked Sendable {
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = PHASEError

        case initializeFailed = 1_346_913_633
        case invalidObject = 1_346_913_634
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { PHASEErrorDomain }

    public static var initializeFailed: Code { .initializeFailed }
    public static var invalidObject: Code { .invalidObject }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_nsError.domain)
        hasher.combine(_nsError.code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }

    public static func == (lhs: PHASEError, rhs: PHASEError) -> Bool {
        lhs.code == rhs.code
    }

    public static func != (lhs: PHASEError, rhs: PHASEError) -> Bool {
        lhs.code != rhs.code
    }
}

/// Bridged `PHASEAssetError` overlay. Raw values follow pinned macios
/// `PhaseAssetError` (`FailedToLoad = 1346920801` … `MemoryAllocation = 1346920806`).
@frozen
public struct PHASEAssetError: Foundation._BridgedStoredNSError, @unchecked Sendable {
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = PHASEAssetError

        case failedToLoad = 1_346_920_801
        case invalidEngineInstance = 1_346_920_802
        case badParameters = 1_346_920_803
        case alreadyExists = 1_346_920_804
        case generalError = 1_346_920_805
        case memoryAllocation = 1_346_920_806
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { PHASEAssetErrorDomain }

    public static var failedToLoad: Code { .failedToLoad }
    public static var invalidEngineInstance: Code { .invalidEngineInstance }
    public static var badParameters: Code { .badParameters }
    public static var alreadyExists: Code { .alreadyExists }
    public static var generalError: Code { .generalError }
    public static var memoryAllocation: Code { .memoryAllocation }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_nsError.domain)
        hasher.combine(_nsError.code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }

    public static func == (lhs: PHASEAssetError, rhs: PHASEAssetError) -> Bool {
        lhs.code == rhs.code
    }

    public static func != (lhs: PHASEAssetError, rhs: PHASEAssetError) -> Bool {
        lhs.code != rhs.code
    }
}

/// Bridged `PHASESoundEventError` overlay. Raw values follow pinned macios
/// `PhaseSoundEventError` (`NotFound = 1346925665` … `OutOfMemory = 1346925670`).
@frozen
public struct PHASESoundEventError: Foundation._BridgedStoredNSError, @unchecked Sendable {
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = PHASESoundEventError

        case notFound = 1_346_925_665
        case badData = 1_346_925_666
        case invalidInstance = 1_346_925_667
        case apiMisuse = 1_346_925_668
        case systemNotInitialized = 1_346_925_669
        case outOfMemory = 1_346_925_670
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { PHASESoundEventErrorDomain }

    public static var notFound: Code { .notFound }
    public static var badData: Code { .badData }
    public static var invalidInstance: Code { .invalidInstance }
    public static var apiMisuse: Code { .apiMisuse }
    public static var systemNotInitialized: Code { .systemNotInitialized }
    public static var outOfMemory: Code { .outOfMemory }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_nsError.domain)
        hasher.combine(_nsError.code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }

    public static func == (lhs: PHASESoundEventError, rhs: PHASESoundEventError) -> Bool {
        lhs.code == rhs.code
    }

    public static func != (lhs: PHASESoundEventError, rhs: PHASESoundEventError) -> Bool {
        lhs.code != rhs.code
    }
}
