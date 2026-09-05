import Dispatch
import Foundation

#if canImport(Combine)
@_exported import Combine
#endif

// MARK: - Unchecked work (private-queue delivery)

/// Wraps a non-Sendable reply so it can hop onto the framework-private queue.
/// Pattern taken from the AppTrackingTransparency host lane.
private struct LAUncheckedWork: @unchecked Sendable {
    let body: () -> Void
}

private final class LAOnceFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var delivered = false

    func take() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if delivered {
            return false
        }
        delivered = true
        return true
    }
}

/// Private serial queue for `evaluatePolicy` / rights completions.
/// Apple: LAContext.h — "The block is executed on a private queue internal to
/// the framework in an unspecified threading context." Measured as non-inline
/// on this port: the caller returns before the reply runs.
private let laReplyQueue = DispatchQueue(
    label: "LocalAuthentication.reply",
    qos: .utility
)

private func laDeliver(_ body: @escaping () -> Void) {
    let once = LAOnceFlag()
    let work = LAUncheckedWork(body: body)
    laReplyQueue.async {
        guard once.take() else { return }
        work.body()
    }
}

// MARK: - Linux test hook

/// Linux-only process flag. Not an Apple API.
///
/// Apple's `LAPolicyDeviceOwnerAuthentication` cannot start when no device
/// passcode is set (`LAErrorPasscodeNotSet`, LAContext.h / LAError.h). Linux
/// has no passcode broker. Tests that need a simulated credential call
/// `LocalAuthenticationTestHook.setSimulatedDevicePasscodeEnabled(true)`.
/// Biometric and companion policies still fail closed: this host has no
/// Secure Enclave and no companion hardware.
public enum LocalAuthenticationTestHook: Sendable {
    private static let lock = NSLock()
    private static var simulatedDevicePasscode = false

    public static func setSimulatedDevicePasscodeEnabled(_ enabled: Bool) {
        lock.lock()
        simulatedDevicePasscode = enabled
        lock.unlock()
    }

    public static var isSimulatedDevicePasscodeEnabled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return simulatedDevicePasscode
    }

    /// Holds the private reply queue so a test can `invalidate()` an in-flight
    /// `evaluatePolicy` before the reply runs. `body` must not wait on a reply.
    public static func withHeldReplies(_ body: () -> Void) {
        let gate = DispatchSemaphore(value: 0)
        laReplyQueue.async {
            gate.wait()
        }
        body()
        gate.signal()
    }
}

// MARK: - Error domain and reuse bound

/// Process-local identity for Apple's `LAErrorDomain` / `kLAErrorDomain`.
///
/// Measured 2026-09-05 on this Mac, Xcode 26.1 / macOS 26.0
/// (`/tmp/la-oracle.swift` against the SDK LocalAuthentication):
/// `LAErrorDomain == kLAErrorDomain == "com.apple.LocalAuthentication"`.
/// Corroborated by `LAPublicDefines.h`: `#define kLAErrorDomain "com.apple.LocalAuthentication"`.
public let LAErrorDomain = "com.apple.LocalAuthentication"

/// Maximum accepted Touch ID / Face ID unlock reuse interval, in seconds.
///
/// Measured 2026-09-05: `LATouchIDAuthenticationMaximumAllowableReuseDuration == 300.0`
/// on the same Mac probe. Matches LAContext.h: "The maximum supported interval
/// is 5 minutes". The stored `touchIDAuthenticationAllowableReuseDuration`
/// property is **not** clamped on set (probe: assigning `10000` read back
/// `10000.0`); values above 300 do not increase the accepted interval.
public let LATouchIDAuthenticationMaximumAllowableReuseDuration: TimeInterval = 300

/// Bridged Local Authentication error.
///
/// The pinned API digester records a stored `_nsError: NSError` and
/// `init(_nsError:)`. Linux Foundation exposes
/// `Foundation._BridgedStoredNSError` and `Foundation._ErrorCodeProtocol`.
/// Foundation's protocol-default `hash(into:)` / `hashValue` witnesses trap
/// on this toolchain, so those Hashable members are provided here.
///
/// Raw values from `LAPublicDefines.h` (Xcode 26.1 iPhoneOS / MacOSX SDK):
/// `kLAErrorAuthenticationFailed = -1` through `kLAErrorInvalidContext = -10`,
/// `kLAErrorWatchNotAvailable` / `kLAErrorCompanionNotAvailable = -11`,
/// `kLAErrorNotInteractive = -1004`. `biometry*` names are static aliases of
/// the `touchID*` cases (`kLAErrorBiometryNotAvailable = kLAErrorTouchIDNotAvailable`).
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

    public static var errorDomain: String { LAErrorDomain }

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

    /// Convenience retained so in-tree guests that construct `LAError(_ code:)`
    /// keep compiling.
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

// MARK: - Policies and types

/// Policies accepted by `LAContext`.
///
/// Raw values from `LAPublicDefines.h`:
/// `kLAPolicyDeviceOwnerAuthenticationWithBiometrics = 1`,
/// `kLAPolicyDeviceOwnerAuthentication = 2`,
/// companion / Watch share 3, biometrics-or-companion / Watch share 4.
public enum LAPolicy: Int, Sendable {
    case deviceOwnerAuthenticationWithBiometrics = 1
    case deviceOwnerAuthentication = 2
    case deviceOwnerAuthenticationWithCompanion = 3
    case deviceOwnerAuthenticationWithBiometricsOrCompanion = 4
}

/// Biometry kinds. Raw values from `LAPublicDefines.h`:
/// `kLABiometryTypeNone = 0`, `TouchID = 1<<0`, `FaceID = 1<<1`, `OpticID = 1<<2`.
/// Measured on the Mac probe: `touchID.rawValue == 1`, `faceID == 2`, `opticID == 4`.
public enum LABiometryType: Int, Sendable {
    case none = 0
    case touchID = 1
    case faceID = 2
    case opticID = 4

    /// Historical C alias `LABiometryNone`.
    public static var LABiometryNone: LABiometryType { .none }
}

/// iOS Swift overlay cases. Watch/none exist as C macros, not Swift cases.
/// Raw values from `LAPublicDefines.h`: `Mac = 1<<1`, `Vision = 1<<2`.
public enum LACompanionType: Int, Sendable {
    case mac = 2
    case vision = 4
}

public enum LACredentialType: Int, Sendable {
    case applicationPassword = 0
    case smartCardPIN = -3
}

/// Sequential NS_ENUM order from `LAPublicDefines.h` (`CreateItem = 0` … `UseKeyKeyExchange = 5`).
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

/// Linux has no device-owner authentication broker, Secure Enclave, or
/// biometric sensor. `biometryType` is always `.none`.
///
/// Policy preflight (`canEvaluatePolicy`):
/// - biometric policies → `LAError.biometryNotAvailable` (`LAContext.h`)
/// - `deviceOwnerAuthentication` → `LAError.passcodeNotSet` unless
///   `LocalAuthenticationTestHook` has registered a simulated passcode
/// - companion policies → `LAError.companionNotAvailable` (`LAContext.h`)
///
/// `evaluatePolicy` delivers the same errors asynchronously on
/// `LocalAuthentication.reply` (Apple: private framework queue, LAContext.h).
/// `invalidate()` cancels in-flight evaluations with `LAError.appCancel` and
/// later calls fail with `LAError.invalidContext` (LAContext.h).
/// `interactionNotAllowed` → `LAError.notInteractive` (LAContext.h).
///
/// Linux Foundation has no `NSErrorPointer` typealias (measured
/// `docker exec uikit-linux swift -e 'import Foundation; print(NSErrorPointer.self)'`).
/// The original lane and in-tree first-party guests pass
/// `UnsafeMutablePointer<LAError?>?`.
open class LAContext: NSObject {
    public override init() {
        super.init()
    }

    open var localizedReason = ""
    open var localizedCancelTitle: String?
    open var localizedFallbackTitle: String?
    open var interactionNotAllowed = false
    /// Always `.none` on Linux: no Touch ID / Face ID / Optic ID hardware.
    open private(set) var biometryType: LABiometryType = .none
    open var maxBiometryFailures: NSNumber?
    /// Default 0 (LAContext.h). Not clamped on set (Mac probe 2026-09-05:
    /// assigning 10000 read back 10000). The accepted reuse interval cannot
    /// exceed `LATouchIDAuthenticationMaximumAllowableReuseDuration` (300).
    open var touchIDAuthenticationAllowableReuseDuration: TimeInterval = 0
    /// Nil until a successful biometric evaluation. Linux never evaluates
    /// biometrics successfully, so this stays nil (LAContext.h).
    open private(set) var evaluatedPolicyDomainState: Data?

    open var domainState: LADomainState {
        LADomainState(portableMarker: ())
    }

    private let lock = NSLock()
    private var invalidated = false
    private var applicationPassword: Data?
    private var inFlight: [UInt64: (Bool, Error?) -> Void] = [:]
    private var nextFlight: UInt64 = 1

    open func canEvaluatePolicy(
        _ policy: LAPolicy,
        error: UnsafeMutablePointer<LAError?>? = nil
    ) -> Bool {
        lock.lock()
        let isInvalid = invalidated
        lock.unlock()
        if isInvalid {
            error?.pointee = LAError(
                .invalidContext,
                reason: "LAContext has been invalidated"
            )
            return false
        }
        if let failure = policyPreflightError(policy) {
            error?.pointee = failure
            return false
        }
        error?.pointee = nil
        return true
    }

    open func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String,
        reply: @escaping @Sendable (Bool, Error?) -> Void
    ) {
        // Apple: LAContext.h — "localizedReason parameter is mandatory and the
        // call will throw NSInvalidArgumentException if nil or empty string".
        precondition(
            !localizedReason.isEmpty,
            "evaluatePolicy localizedReason must be nonempty"
        )
        self.localizedReason = localizedReason

        let flight: UInt64
        lock.lock()
        if invalidated {
            lock.unlock()
            laDeliver {
                reply(
                    false,
                    LAError(.invalidContext, reason: "LAContext has been invalidated")
                )
            }
            return
        }
        flight = nextFlight
        nextFlight += 1
        inFlight[flight] = { success, error in
            reply(success, error)
        }
        lock.unlock()

        laDeliver { [self] in
            self.finishFlight(flight, policy: policy)
        }
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

    /// Apple: LAContext.h — "Invalidation terminates any existing policy
    /// evaluation and the respective call will fail with LAErrorAppCancel.
    /// After the context has been invalidated, it can not be used for policy
    /// evaluation and an attempt to do so will fail with LAErrorInvalidContext."
    open func invalidate() {
        lock.lock()
        invalidated = true
        applicationPassword = nil
        let pending = inFlight
        inFlight.removeAll()
        lock.unlock()
        let cancel = LAError(
            .appCancel,
            reason: "LAContext.invalidate() canceled an in-flight evaluation"
        )
        for (_, reply) in pending {
            laDeliver {
                reply(false, cancel)
            }
        }
    }

    open func setCredential(_ credential: Data?, type: LACredentialType) -> Bool {
        lock.lock()
        defer { lock.unlock() }
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
        lock.lock()
        defer { lock.unlock() }
        guard !invalidated else { return false }
        switch type {
        case .applicationPassword:
            return applicationPassword != nil
        case .smartCardPIN:
            return false
        }
    }

    private func finishFlight(_ flight: UInt64, policy: LAPolicy) {
        lock.lock()
        guard let reply = inFlight.removeValue(forKey: flight) else {
            lock.unlock()
            return
        }
        let isInvalid = invalidated
        let interactionForbidden = interactionNotAllowed
        lock.unlock()

        if isInvalid {
            reply(
                false,
                LAError(.appCancel, reason: "LAContext.invalidate() canceled an in-flight evaluation")
            )
            return
        }
        if interactionForbidden {
            // Apple: LAContext.h — "it will eventually fail with
            // LAErrorNotInteractive instead of displaying the authentication UI."
            reply(
                false,
                LAError(
                    .notInteractive,
                    reason: "interactionNotAllowed forbids authentication UI"
                )
            )
            return
        }
        if let failure = policyPreflightError(policy) {
            reply(false, failure)
            return
        }
        reply(true, nil)
    }

    private func policyPreflightError(_ policy: LAPolicy) -> LAError? {
        switch policy {
        case .deviceOwnerAuthenticationWithBiometrics,
             .deviceOwnerAuthenticationWithBiometricsOrCompanion:
            // Apple: LAContext.h — biometric policy fails with
            // LAErrorBiometryNotAvailable when Touch ID / Face ID is absent.
            return LAError(
                .biometryNotAvailable,
                reason: "Biometry is not available on this host"
            )
        case .deviceOwnerAuthentication:
            if LocalAuthenticationTestHook.isSimulatedDevicePasscodeEnabled {
                return nil
            }
            // Apple: LAError.h — "Authentication could not start because
            // passcode is not set on the device."
            return LAError(
                .passcodeNotSet,
                reason: "Device passcode is not set on this host"
            )
        case .deviceOwnerAuthenticationWithCompanion:
            // Apple: LAContext.h — "If no nearby paired companion device can
            // be found, LAErrorCompanionNotAvailable is returned."
            return LAError(
                .companionNotAvailable,
                reason: "No companion device is available on this host"
            )
        }
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

/// Apple: LARequirement.h — default is user authentication (biometry or
/// passcode); `biometry` / `biometryCurrentSet` require a sensor.
open class LAAuthenticationRequirement: NSObject {
    enum Kind: Sendable {
        case `default`
        case biometry
        case biometryCurrentSet
        case biometryWithFallback(LABiometryFallbackRequirement.Kind)
    }

    var kind: Kind

    public required override init() {
        self.kind = .default
        super.init()
    }

    private static let defaultRequirement = LAAuthenticationRequirement()
    private static let biometryRequirement: LAAuthenticationRequirement = {
        let value = LAAuthenticationRequirement()
        value.kind = .biometry
        return value
    }()
    private static let biometryCurrentSetRequirement: LAAuthenticationRequirement = {
        let value = LAAuthenticationRequirement()
        value.kind = .biometryCurrentSet
        return value
    }()

    open class var `default`: LAAuthenticationRequirement { defaultRequirement }
    open class var biometry: LAAuthenticationRequirement { biometryRequirement }
    open class var biometryCurrentSet: LAAuthenticationRequirement { biometryCurrentSetRequirement }

    open class func biometry(fallback: LABiometryFallbackRequirement) -> Self {
        let value = Self()
        value.kind = .biometryWithFallback(fallback.kind)
        return value
    }

    /// Linux preflight: biometry-only requirements fail closed;
    /// default / passcode fallback honor the simulated-passcode hook.
    func preflightError() -> LAError? {
        switch kind {
        case .biometry, .biometryCurrentSet:
            return LAError(
                .biometryNotAvailable,
                reason: "Biometry is not available on this host"
            )
        case .default, .biometryWithFallback:
            if LocalAuthenticationTestHook.isSimulatedDevicePasscodeEnabled {
                return nil
            }
            return LAError(
                .passcodeNotSet,
                reason: "Device passcode is not set on this host"
            )
        }
    }
}

open class LABiometryFallbackRequirement: NSObject {
    enum Kind: Sendable {
        case `default`
        case devicePasscode
    }

    let kind: Kind

    public override init() {
        self.kind = .default
        super.init()
    }

    init(kind: Kind) {
        self.kind = kind
        super.init()
    }

    private static let defaultRequirement = LABiometryFallbackRequirement(kind: .default)
    private static let devicePasscodeRequirement = LABiometryFallbackRequirement(kind: .devicePasscode)

    open class var `default`: LABiometryFallbackRequirement { defaultRequirement }
    open class var devicePasscode: LABiometryFallbackRequirement { devicePasscodeRequirement }
}

// MARK: - Rights

/// Apple: LARight.h — states in documented order:
/// `unknown (0)` → `authorizing (1)` after `authorize` is called →
/// `authorized (2)` on success or `notAuthorized (3)` on rejection.
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

    let requirement: LAAuthenticationRequirement
    private let lock = NSLock()
    private var _state: State = .unknown
    open var tag: Int = 0

    open private(set) var state: State {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _state
        }
        set {
            lock.lock()
            _state = newValue
            lock.unlock()
        }
    }

    open func authorize(localizedReason: String) async throws {
        try authorizeSync(localizedReason: localizedReason)
    }

    open func authorize(
        localizedReason: String,
        completion handler: @escaping @Sendable ((any Error)?) -> Void
    ) {
        laDeliver { [self] in
            do {
                try self.authorizeSync(localizedReason: localizedReason)
                handler(nil)
            } catch {
                handler(error)
            }
        }
    }

    private func authorizeSync(localizedReason: String) throws {
        precondition(
            !localizedReason.isEmpty,
            "authorize localizedReason must be nonempty"
        )
        // Apple: LARight.h — unknown → authorizing when authorize is called,
        // then authorized on success or notAuthorized on rejection.
        state = .authorizing
        if let error = requirement.preflightError() {
            state = .notAuthorized
            throw error
        }
        state = .authorized
    }

    open func checkCanAuthorize(completion handler: @escaping @Sendable ((any Error)?) -> Void) {
        let error = requirement.preflightError()
        laDeliver {
            handler(error)
        }
    }

    /// Apple: LARight.h — "Invalidates a previously authorized right."
    open func deauthorize(completion handler: @escaping @Sendable () -> Void) {
        if state == .authorized {
            state = .notAuthorized
        }
        laDeliver {
            handler()
        }
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

    let identifier: String

    init(identifier: String, requirement: LAAuthenticationRequirement, secret: Data?) {
        self.identifier = identifier
        let privateKey = LAPrivateKey(portableMarker: ())
        self.key = privateKey
        self.secret = LASecret(portableMarker: (), stored: secret, owner: nil)
        super.init(requirement: requirement)
        self.secret.bindOwner(self)
    }

    open private(set) var key: LAPrivateKey
    open private(set) var secret: LASecret
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

    /// Linux has no Secure Enclave key material. Fail closed with
    /// `LAError.invalidContext` (brief: keys fail closed with invalidContext).
    open func exportBytes(completion handler: @escaping @Sendable (Data?, (any Error)?) -> Void) {
        laDeliver {
            handler(
                nil,
                LAError(
                    .invalidContext,
                    reason: "No Secure Enclave key material on this host"
                )
            )
        }
    }
}

open class LASecret: NSObject {
    @available(*, unavailable)
    public override init() {
        fatalError("LASecret is produced by LAPersistedRight")
    }

    private let stored: Data?
    private weak var owner: LAPersistedRight?

    init(portableMarker: Void, stored: Data? = nil, owner: LAPersistedRight? = nil) {
        self.stored = stored
        self.owner = owner
        super.init()
    }

    func bindOwner(_ owner: LAPersistedRight) {
        self.owner = owner
    }

    /// Returns the in-memory secret when the owning right is authorized.
    /// Otherwise fails closed with `invalidContext` (no enclave).
    open func loadData(completion handler: @escaping @Sendable (Data?, (any Error)?) -> Void) {
        let data = stored
        let authorized = owner?.state == .authorized
        laDeliver {
            if authorized, let data {
                handler(data, nil)
            } else {
                handler(
                    nil,
                    LAError(
                        .invalidContext,
                        reason: "Secret is unavailable until the persisted right is authorized"
                    )
                )
            }
        }
    }
}

/// Persistent storage for `LARight` instances.
///
/// Apple backs this with the Keychain. Linux has an in-memory store on
/// `LARightStore.shared` so save/load/remove round-trip in-process. Contents
/// vanish with the process. Key operations on persisted rights still fail
/// closed: there is no Secure Enclave.
open class LARightStore: NSObject {
    private static let sharedStore = LARightStore(portableMarker: ())

    private let lock = NSLock()
    private var records: [String: StoredRight] = [:]

    private struct StoredRight {
        var requirementKind: LAAuthenticationRequirement.Kind
        var secret: Data?
        var tag: Int
    }

    private init(portableMarker: Void) {
        super.init()
    }

    @available(*, unavailable)
    public override init() {
        fatalError("Use LARightStore.shared")
    }

    open class var shared: LARightStore { sharedStore }

    private func loadRecord(_ identifier: String) -> StoredRight? {
        lock.lock()
        defer { lock.unlock() }
        return records[identifier]
    }

    private func storeRecord(_ identifier: String, _ record: StoredRight) {
        lock.lock()
        records[identifier] = record
        lock.unlock()
    }

    private func deleteRecord(_ identifier: String) {
        lock.lock()
        records.removeValue(forKey: identifier)
        lock.unlock()
    }

    private func deleteAllRecords() {
        lock.lock()
        records.removeAll()
        lock.unlock()
    }

    open func right(forIdentifier identifier: String) async throws -> LAPersistedRight {
        guard let record = loadRecord(identifier) else {
            throw LAError(
                .invalidContext,
                reason: "No right stored for identifier"
            )
        }
        return makePersisted(identifier: identifier, record: record)
    }

    open func saveRight(_ right: LARight, identifier: String) async throws -> LAPersistedRight {
        try await saveRight(right, identifier: identifier, secret: nil)
    }

    open func saveRight(
        _ right: LARight,
        identifier: String,
        secret: Data
    ) async throws -> LAPersistedRight {
        try await saveRight(right, identifier: identifier, secret: Optional(secret))
    }

    open func removeRight(_ right: LAPersistedRight) async throws {
        try await removeRight(forIdentifier: right.identifier)
    }

    open func removeRight(forIdentifier identifier: String) async throws {
        deleteRecord(identifier)
    }

    open func removeAllRights(completion handler: @escaping @Sendable ((any Error)?) -> Void) {
        deleteAllRecords()
        laDeliver {
            handler(nil)
        }
    }

    private func saveRight(
        _ right: LARight,
        identifier: String,
        secret: Data?
    ) async throws -> LAPersistedRight {
        let record = StoredRight(
            requirementKind: right.requirement.kind,
            secret: secret,
            tag: right.tag
        )
        storeRecord(identifier, record)
        let persisted = makePersisted(identifier: identifier, record: record)
        persisted.tag = right.tag
        return persisted
    }

    private func makePersisted(identifier: String, record: StoredRight) -> LAPersistedRight {
        let requirement: LAAuthenticationRequirement
        switch record.requirementKind {
        case .default:
            requirement = .default
        case .biometry:
            requirement = .biometry
        case .biometryCurrentSet:
            requirement = .biometryCurrentSet
        case .biometryWithFallback(let fallbackKind):
            let fallback: LABiometryFallbackRequirement
            switch fallbackKind {
            case .default:
                fallback = .default
            case .devicePasscode:
                fallback = .devicePasscode
            }
            requirement = LAAuthenticationRequirement.biometry(fallback: fallback)
        }
        let persisted = LAPersistedRight(
            identifier: identifier,
            requirement: requirement,
            secret: record.secret
        )
        persisted.tag = record.tag
        return persisted
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
