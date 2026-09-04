import Foundation

#if canImport(Combine)
@_exported import Combine
#endif

/// Process-local identity for Apple's `LAErrorDomain` constant. The isolated
/// seed records the exported symbol, not the Apple binary string payload.
public let LAErrorDomain = "LAErrorDomain"

/// Bridged Local Authentication error.
///
/// The pinned API digester records a stored `_nsError: NSError` and
/// `init(_nsError:)`. Linux Foundation exposes
/// `Foundation._BridgedStoredNSError` and `Foundation._ErrorCodeProtocol`.
/// Foundation's protocol-default `hash(into:)` / `hashValue` witnesses trap
/// on this toolchain, so those Hashable members are provided here.
///
/// Raw values come from the pinned `dotnet/macios` `LAStatus` enum
/// (`AuthenticationFailed = -1` through `CompanionNotAvailable = -11`,
/// `NotInteractive = -1004`). `biometry*` names are static aliases of the
/// `touchID*` cases, matching the API-digester overlay.
@frozen
public struct LAError: Foundation._BridgedStoredNSError, @unchecked Sendable {
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = LAError

        case authenticationFailed = -1
        case userCancel = -2
        case userFallback = -3
        case systemCancel = -4
        case passcodeNotSet = -5
        case touchIDNotAvailable = -6
        case touchIDNotEnrolled = -7
        case touchIDLockout = -8
        case appCancel = -9
        case invalidContext = -10
        case companionNotAvailable = -11
        case notInteractive = -1004

        public static var biometryNotAvailable: Code { .touchIDNotAvailable }
        public static var biometryNotEnrolled: Code { .touchIDNotEnrolled }
        public static var biometryLockout: Code { .touchIDLockout }
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { LAErrorDomain }

    public static var authenticationFailed: Code { .authenticationFailed }
    public static var userCancel: Code { .userCancel }
    public static var userFallback: Code { .userFallback }
    public static var systemCancel: Code { .systemCancel }
    public static var passcodeNotSet: Code { .passcodeNotSet }
    public static var touchIDNotAvailable: Code { .touchIDNotAvailable }
    public static var touchIDNotEnrolled: Code { .touchIDNotEnrolled }
    public static var touchIDLockout: Code { .touchIDLockout }
    public static var appCancel: Code { .appCancel }
    public static var invalidContext: Code { .invalidContext }
    public static var notInteractive: Code { .notInteractive }
    public static var companionNotAvailable: Code { .companionNotAvailable }
    public static var biometryNotAvailable: Code { .biometryNotAvailable }
    public static var biometryNotEnrolled: Code { .biometryNotEnrolled }
    public static var biometryLockout: Code { .biometryLockout }

    /// Convenience retained from the original Linux lane so in-tree guests that
    /// construct `LAError(_ code:)` keep compiling.
    public init(_ code: Code, reason: String? = nil) {
        var info: [String: Any] = [:]
        if let reason {
            info[NSLocalizedDescriptionKey] = reason
        }
        self.init(code, userInfo: info)
    }

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

/// Policies accepted by the portable local-authentication boundary.
///
/// Raw values 1 and 2 match the original lane and the pinned macios
/// `LAPolicy` enum. Companion cases share 3 and 4 with the deprecated Watch
/// policies (macios `DeviceOwnerAuthenticationWithCompanion = 3`).
public enum LAPolicy: Int, Sendable {
    case deviceOwnerAuthenticationWithBiometrics = 1
    case deviceOwnerAuthentication = 2
    case deviceOwnerAuthenticationWithCompanion = 3
    case deviceOwnerAuthenticationWithBiometricsOrCompanion = 4
}

public enum LABiometryType: Int, Sendable {
    case none = 0
    case touchID = 1
    case faceID = 2
    case opticID = 4

    /// Historical C alias `LABiometryNone`.
    public static var LABiometryNone: LABiometryType { .none }
}

/// iOS Swift overlay cases only. Watch/none exist as C macros, not Swift cases.
/// Raw values match macios `LACompanionType` bit flags (`Mac = 1 << 1`).
public enum LACompanionType: Int, Sendable {
    case mac = 2
    case vision = 4
}

public enum LACredentialType: Int, Sendable {
    case applicationPassword = 0
    case smartCardPIN = -3
}

/// Sequential NS_ENUM order from the pinned macios `LAAccessControlOperation`.
public enum LAAccessControlOperation: Int, Sendable {
    case createItem = 0
    case useItem = 1
    case createKey = 2
    case useKeySign = 3
    case useKeyDecrypt = 4
    case useKeyKeyExchange = 5
}

// MARK: - C macros (Int32 overlays of the public defines)

public var kLAAccessControlOperationCreateItem: Int32 { Int32(LAAccessControlOperation.createItem.rawValue) }
public var kLAAccessControlOperationUseItem: Int32 { Int32(LAAccessControlOperation.useItem.rawValue) }
public var kLAAccessControlOperationCreateKey: Int32 { Int32(LAAccessControlOperation.createKey.rawValue) }
public var kLAAccessControlOperationUseKeySign: Int32 { Int32(LAAccessControlOperation.useKeySign.rawValue) }
public var kLAAccessControlOperationUseKeyDecrypt: Int32 { Int32(LAAccessControlOperation.useKeyDecrypt.rawValue) }
public var kLAAccessControlOperationUseKeyKeyExchange: Int32 { Int32(LAAccessControlOperation.useKeyKeyExchange.rawValue) }

public var kLABiometryTypeNone: Int32 { Int32(LABiometryType.none.rawValue) }
public var kLABiometryTypeTouchID: Int32 { Int32(LABiometryType.touchID.rawValue) }
public var kLABiometryTypeFaceID: Int32 { Int32(LABiometryType.faceID.rawValue) }
public var kLABiometryTypeOpticID: Int32 { Int32(LABiometryType.opticID.rawValue) }

public var kLACompanionTypeNone: Int32 { 0 }
public var kLACompanionTypeWatch: Int32 { 1 }
public var kLACompanionTypeMac: Int32 { Int32(LACompanionType.mac.rawValue) }
public var kLACompanionTypeVision: Int32 { Int32(LACompanionType.vision.rawValue) }

public var kLACredentialTypeApplicationPassword: Int32 { Int32(LACredentialType.applicationPassword.rawValue) }
public var kLACredentialSmartCardPIN: Int32 { Int32(LACredentialType.smartCardPIN.rawValue) }

public var kLAErrorAuthenticationFailed: Int32 { Int32(LAError.Code.authenticationFailed.rawValue) }
public var kLAErrorUserCancel: Int32 { Int32(LAError.Code.userCancel.rawValue) }
public var kLAErrorUserFallback: Int32 { Int32(LAError.Code.userFallback.rawValue) }
public var kLAErrorSystemCancel: Int32 { Int32(LAError.Code.systemCancel.rawValue) }
public var kLAErrorPasscodeNotSet: Int32 { Int32(LAError.Code.passcodeNotSet.rawValue) }
public var kLAErrorTouchIDNotAvailable: Int32 { Int32(LAError.Code.touchIDNotAvailable.rawValue) }
public var kLAErrorTouchIDNotEnrolled: Int32 { Int32(LAError.Code.touchIDNotEnrolled.rawValue) }
public var kLAErrorTouchIDLockout: Int32 { Int32(LAError.Code.touchIDLockout.rawValue) }
public var kLAErrorAppCancel: Int32 { Int32(LAError.Code.appCancel.rawValue) }
public var kLAErrorInvalidContext: Int32 { Int32(LAError.Code.invalidContext.rawValue) }
public var kLAErrorNotInteractive: Int32 { Int32(LAError.Code.notInteractive.rawValue) }
public var kLAErrorCompanionNotAvailable: Int32 { Int32(LAError.Code.companionNotAvailable.rawValue) }
public var kLAErrorBiometryNotAvailable: Int32 { Int32(LAError.Code.biometryNotAvailable.rawValue) }
public var kLAErrorBiometryNotEnrolled: Int32 { Int32(LAError.Code.biometryNotEnrolled.rawValue) }
public var kLAErrorBiometryLockout: Int32 { Int32(LAError.Code.biometryLockout.rawValue) }
public var kLAErrorWatchNotAvailable: Int32 { -11 }
public var kLAErrorBiometryNotPaired: Int32 { -12 }
public var kLAErrorBiometryDisconnected: Int32 { -13 }
public var kLAErrorInvalidDimensions: Int32 { -14 }
public var kLAErrorDomain: String { LAErrorDomain }

public var kLAPolicyDeviceOwnerAuthenticationWithBiometrics: Int32 {
    Int32(LAPolicy.deviceOwnerAuthenticationWithBiometrics.rawValue)
}
public var kLAPolicyDeviceOwnerAuthentication: Int32 {
    Int32(LAPolicy.deviceOwnerAuthentication.rawValue)
}
public var kLAPolicyDeviceOwnerAuthenticationWithCompanion: Int32 {
    Int32(LAPolicy.deviceOwnerAuthenticationWithCompanion.rawValue)
}
public var kLAPolicyDeviceOwnerAuthenticationWithBiometricsOrCompanion: Int32 {
    Int32(LAPolicy.deviceOwnerAuthenticationWithBiometricsOrCompanion.rawValue)
}
public var kLAPolicyDeviceOwnerAuthenticationWithWatch: Int32 { 3 }
public var kLAPolicyDeviceOwnerAuthenticationWithBiometricsOrWatch: Int32 { 4 }
public var kLAPolicyDeviceOwnerAuthenticationWithWristDetection: Int32 { 5 }

// MARK: - Context

/// Linux has no device-owner authentication broker. The context is still a
/// real mutable request object, but every capability query and evaluation
/// fails closed with `biometryNotAvailable` (or `invalidContext` after
/// `invalidate()`).
///
/// Linux Foundation has no `NSErrorPointer` typealias. The original lane and
/// in-tree first-party guests pass `UnsafeMutablePointer<LAError?>?`.
open class LAContext: NSObject {
    public override init() {
        super.init()
    }

    open var localizedReason = ""
    open var localizedCancelTitle: String?
    open var localizedFallbackTitle: String?
    open var interactionNotAllowed = false
    open private(set) var biometryType: LABiometryType = .none
    open var maxBiometryFailures: NSNumber?
    open var touchIDAuthenticationAllowableReuseDuration: TimeInterval = 0
    open private(set) var evaluatedPolicyDomainState: Data?

    open var domainState: LADomainState {
        LADomainState(portableMarker: ())
    }

    private var invalidated = false
    private var applicationPassword: Data?

    open func canEvaluatePolicy(
        _ policy: LAPolicy,
        error: UnsafeMutablePointer<LAError?>? = nil
    ) -> Bool {
        _ = policy
        error?.pointee = failClosedError()
        return false
    }

    open func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String,
        reply: @escaping @Sendable (Bool, Error?) -> Void
    ) {
        _ = policy
        self.localizedReason = localizedReason
        reply(false, failClosedError())
    }

    open func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String
    ) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            evaluatePolicy(policy, localizedReason: localizedReason) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }

    open func invalidate() {
        invalidated = true
        applicationPassword = nil
    }

    open func setCredential(_ credential: Data?, type: LACredentialType) -> Bool {
        guard !invalidated else { return false }
        switch type {
        case .applicationPassword:
            applicationPassword = credential
            return credential != nil
        case .smartCardPIN:
            return false
        }
    }

    open func isCredentialSet(_ type: LACredentialType) -> Bool {
        guard !invalidated else { return false }
        switch type {
        case .applicationPassword:
            return applicationPassword != nil
        case .smartCardPIN:
            return false
        }
    }

    private func failClosedError() -> LAError {
        LAError(
            invalidated ? .invalidContext : .biometryNotAvailable,
            reason: "Local authentication is unavailable on this host"
        )
    }
}

// MARK: - Domain state

open class LADomainState: NSObject {
    @available(*, unavailable)
    public override init() {
        fatalError("LADomainState is produced by LAContext.domainState")
    }

    init(portableMarker: Void) {
        biometry = LADomainStateBiometry(portableMarker: ())
        companion = LADomainStateCompanion(portableMarker: ())
        super.init()
    }

    open private(set) var biometry: LADomainStateBiometry
    open private(set) var companion: LADomainStateCompanion
    open private(set) var stateHash: Data?
}

open class LADomainStateBiometry: NSObject {
    @available(*, unavailable)
    public override init() {
        fatalError("LADomainStateBiometry is produced by LADomainState")
    }

    init(portableMarker: Void) {
        super.init()
    }

    open private(set) var biometryType: LABiometryType = .none
    open private(set) var stateHash: Data?
}

open class LADomainStateCompanion: NSObject {
    @available(*, unavailable)
    public override init() {
        fatalError("LADomainStateCompanion is produced by LADomainState")
    }

    init(portableMarker: Void) {
        super.init()
    }

    open var availableCompanionTypes: Set<LACompanionType> { [] }
    open private(set) var stateHash: Data?

    open func stateHash(for companionType: LACompanionType) -> Data? {
        _ = companionType
        return nil
    }
}

// MARK: - Requirements

open class LAAuthenticationRequirement: NSObject {
    public required override init() {
        super.init()
    }

    private static let defaultRequirement = LAAuthenticationRequirement()
    private static let biometryRequirement = LAAuthenticationRequirement()
    private static let biometryCurrentSetRequirement = LAAuthenticationRequirement()

    open class var `default`: LAAuthenticationRequirement { defaultRequirement }
    open class var biometry: LAAuthenticationRequirement { biometryRequirement }
    open class var biometryCurrentSet: LAAuthenticationRequirement { biometryCurrentSetRequirement }

    open class func biometry(fallback: LABiometryFallbackRequirement) -> Self {
        _ = fallback
        return Self()
    }
}

open class LABiometryFallbackRequirement: NSObject {
    public override init() {
        super.init()
    }

    private static let defaultRequirement = LABiometryFallbackRequirement()
    private static let devicePasscodeRequirement = LABiometryFallbackRequirement()

    open class var `default`: LABiometryFallbackRequirement { defaultRequirement }
    open class var devicePasscode: LABiometryFallbackRequirement { devicePasscodeRequirement }
}

// MARK: - Rights

open class LARight: NSObject {
    public enum State: Int, Sendable {
        case unknown = 0
        case authorizing = 1
        case authorized = 2
        case notAuthorized = 3
    }

    public override init() {
        self.requirement = .default
        super.init()
    }

    public init(requirement: LAAuthenticationRequirement) {
        self.requirement = requirement
        super.init()
    }

    private let requirement: LAAuthenticationRequirement
    open private(set) var state: State = .unknown
    open var tag: Int = 0

    open func authorize(localizedReason: String) async throws {
        _ = localizedReason
        throw LAError(
            .biometryNotAvailable,
            reason: "Local authentication is unavailable on this host"
        )
    }

    open func checkCanAuthorize(completion handler: @escaping ((any Error)?) -> Void) {
        handler(
            LAError(
                .biometryNotAvailable,
                reason: "Local authentication is unavailable on this host"
            )
        )
    }

    open func deauthorize(completion handler: @escaping () -> Void) {
        if state == .authorized {
            state = .notAuthorized
        }
        handler()
    }
}

open class LAPersistedRight: LARight {
    @available(*, unavailable)
    public override init() {
        fatalError("LAPersistedRight is produced by LARightStore")
    }

    @available(*, unavailable)
    public override init(requirement: LAAuthenticationRequirement) {
        fatalError("LAPersistedRight is produced by LARightStore")
    }

    init(portableMarker: Void) {
        super.init()
        key = LAPrivateKey(portableMarker: ())
        secret = LASecret(portableMarker: ())
    }

    open private(set) var key: LAPrivateKey = LAPrivateKey(portableMarker: ())
    open private(set) var secret: LASecret = LASecret(portableMarker: ())
}

open class LAPrivateKey: NSObject {
    @available(*, unavailable)
    public override init() {
        fatalError("LAPrivateKey is produced by LAPersistedRight")
    }

    init(portableMarker: Void) {
        super.init()
        publicKey = LAPublicKey(portableMarker: ())
    }

    open private(set) var publicKey: LAPublicKey = LAPublicKey(portableMarker: ())
}

open class LAPublicKey: NSObject {
    @available(*, unavailable)
    public override init() {
        fatalError("LAPublicKey is produced by LAPrivateKey")
    }

    init(portableMarker: Void) {
        super.init()
    }

    open func exportBytes(completion handler: @escaping (Data?, (any Error)?) -> Void) {
        handler(
            nil,
            LAError(
                .biometryNotAvailable,
                reason: "Local authentication is unavailable on this host"
            )
        )
    }
}

open class LASecret: NSObject {
    @available(*, unavailable)
    public override init() {
        fatalError("LASecret is produced by LAPersistedRight")
    }

    init(portableMarker: Void) {
        super.init()
    }

    open func loadData(completion handler: @escaping (Data?, (any Error)?) -> Void) {
        handler(
            nil,
            LAError(
                .biometryNotAvailable,
                reason: "Local authentication is unavailable on this host"
            )
        )
    }
}

open class LARightStore: NSObject {
    private static let sharedStore = LARightStore(portableMarker: ())

    private init(portableMarker: Void) {
        super.init()
    }

    @available(*, unavailable)
    public override init() {
        fatalError("Use LARightStore.shared")
    }

    open class var shared: LARightStore { sharedStore }

    open func right(forIdentifier identifier: String) async throws -> LAPersistedRight {
        _ = identifier
        throw LAError(
            .biometryNotAvailable,
            reason: "Local authentication is unavailable on this host"
        )
    }

    open func saveRight(_ right: LARight, identifier: String) async throws -> LAPersistedRight {
        _ = right
        _ = identifier
        throw LAError(
            .biometryNotAvailable,
            reason: "Local authentication is unavailable on this host"
        )
    }

    open func saveRight(
        _ right: LARight,
        identifier: String,
        secret: Data
    ) async throws -> LAPersistedRight {
        _ = right
        _ = identifier
        _ = secret
        throw LAError(
            .biometryNotAvailable,
            reason: "Local authentication is unavailable on this host"
        )
    }

    open func removeRight(_ right: LAPersistedRight) async throws {
        _ = right
        throw LAError(
            .biometryNotAvailable,
            reason: "Local authentication is unavailable on this host"
        )
    }

    open func removeRight(forIdentifier identifier: String) async throws {
        _ = identifier
        throw LAError(
            .biometryNotAvailable,
            reason: "Local authentication is unavailable on this host"
        )
    }

    open func removeAllRights(completion handler: @escaping ((any Error)?) -> Void) {
        handler(
            LAError(
                .biometryNotAvailable,
                reason: "Local authentication is unavailable on this host"
            )
        )
    }
}

// MARK: - Environment

open class LAEnvironment: NSObject {
    public protocol Observer: NSObjectProtocol {
        func environment(_ environment: LAEnvironment, stateDidChangeFromOldState oldState: State)
    }

    open class Mechanism: NSObject {
        init(portableMarker: Void) {
            super.init()
        }

        @available(*, unavailable)
        public override init() {
            fatalError("LAEnvironment.Mechanism is produced by LAEnvironment.State")
        }

        open private(set) var isUsable = false
        open private(set) var localizedName = ""
        open private(set) var iconSystemName = ""
    }

    open class MechanismBiometry: Mechanism {
        open private(set) var biometryType: LABiometryType = .none
        open private(set) var builtInSensorInaccessible = true
        open private(set) var isEnrolled = false
        open private(set) var isLockedOut = false
        open private(set) var stateHash = Data()
    }

    open class MechanismCompanion: Mechanism {
        open private(set) var type: LACompanionType = .mac
        open private(set) var stateHash: Data?
    }

    open class MechanismUserPassword: Mechanism {
        open private(set) var isSet = false
    }

    open class State: NSObject, NSCopying {
        init(portableMarker: Void) {
            let biometry = MechanismBiometry(portableMarker: ())
            let password = MechanismUserPassword(portableMarker: ())
            self.biometry = biometry
            self.userPassword = password
            self.companions = []
            self.allMechanisms = [biometry, password]
            super.init()
        }

        @available(*, unavailable)
        public override init() {
            fatalError("LAEnvironment.State is produced by LAEnvironment")
        }

        open private(set) var allMechanisms: [Mechanism]
        open private(set) var biometry: MechanismBiometry?
        open private(set) var companions: [MechanismCompanion]
        open private(set) var userPassword: MechanismUserPassword?

        public func copy(with zone: NSZone? = nil) -> Any {
            _ = zone
            return self
        }
    }

    private static let current = LAEnvironment(portableMarker: ())

    open class var currentUser: LAEnvironment { current }

    open private(set) var state: State

    private var observers: [ObjectIdentifier: WeakObserver] = [:]

    private init(portableMarker: Void) {
        self.state = State(portableMarker: ())
        super.init()
    }

    @available(*, unavailable)
    public override init() {
        fatalError("Use LAEnvironment.currentUser")
    }

    open func addObserver(_ observer: any Observer) {
        let object = observer as AnyObject
        observers[ObjectIdentifier(object)] = WeakObserver(value: object)
    }

    open func removeObserver(_ observer: any Observer) {
        let object = observer as AnyObject
        observers.removeValue(forKey: ObjectIdentifier(object))
    }
}

private struct WeakObserver {
    weak var value: AnyObject?
}

extension LAEnvironment.Observer {
    public func environment(
        _ environment: LAEnvironment,
        stateDidChangeFromOldState oldState: LAEnvironment.State
    ) {
        _ = environment
        _ = oldState
    }
}
