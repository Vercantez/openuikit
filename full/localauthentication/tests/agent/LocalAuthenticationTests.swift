import Dispatch
import Foundation
import LocalAuthentication

private final class LALocked<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    func load() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func store(_ value: Value) {
        lock.lock()
        self.value = value
        lock.unlock()
    }
}

private func laAwait<T>(_ body: @escaping @Sendable () async throws -> T) -> Result<T, Error> {
    let semaphore = DispatchSemaphore(value: 0)
    let box = LALocked<Result<T, Error>?>(nil)
    Task {
        do {
            box.store(.success(try await body()))
        } catch {
            box.store(.failure(error))
        }
        semaphore.signal()
    }
    semaphore.wait()
    guard let result = box.load() else {
        preconditionFailure("async probe did not complete")
    }
    return result
}

private func laWaitReply<T>(_ body: (@escaping @Sendable (T) -> Void) -> Void) -> T {
    let semaphore = DispatchSemaphore(value: 0)
    let box = LALocked<T?>(nil)
    body { value in
        box.store(value)
        semaphore.signal()
    }
    semaphore.wait()
    guard let value = box.load() else {
        preconditionFailure("reply did not complete")
    }
    return value
}

private func laResetHostState() {
    LocalAuthenticationTestHook.setSimulatedDevicePasscodeEnabled(false)
    let done = DispatchSemaphore(value: 0)
    LARightStore.shared.removeAllRights { _ in
        done.signal()
    }
    done.wait()
}

private func laBridgedDomain() -> String {
    LAError._nsErrorDomain
}

private func laErrorTypeName<C: Foundation._ErrorCodeProtocol>(_: C.Type) -> String {
    String(describing: C._ErrorType.self)
}

private final class LAEnvironmentProbeObserver: NSObject, LAEnvironment.Observer {
    var calls = 0

    func environment(
        _ environment: LAEnvironment,
        stateDidChangeFromOldState oldState: LAEnvironment.State
    ) {
        _ = environment
        _ = oldState
        calls += 1
    }
}

func testLAErrorDomain() {
    // Measured 2026-09-05, Xcode 26.1 / macOS 26.0: both constants are this string.
    precondition(LAErrorDomain == "com.apple.LocalAuthentication")
    precondition(LAError.errorDomain == "com.apple.LocalAuthentication")
    precondition(LAError.errorDomain == LAErrorDomain)
    precondition(LAError._nsErrorDomain == LAErrorDomain)
    precondition(kLAErrorDomain == LAErrorDomain)
}

func testLAErrorCodes() {
    precondition(LAError.Code.authenticationFailed.rawValue == -1)
    precondition(LAError.Code.userCancel.rawValue == -2)
    precondition(LAError.Code.userFallback.rawValue == -3)
    precondition(LAError.Code.systemCancel.rawValue == -4)
    precondition(LAError.Code.passcodeNotSet.rawValue == -5)
    precondition(LAError.Code.touchIDNotAvailable.rawValue == -6)
    precondition(LAError.Code.touchIDNotEnrolled.rawValue == -7)
    precondition(LAError.Code.touchIDLockout.rawValue == -8)
    precondition(LAError.Code.appCancel.rawValue == -9)
    precondition(LAError.Code.invalidContext.rawValue == -10)
    precondition(LAError.Code.companionNotAvailable.rawValue == -11)
    precondition(LAError.Code.notInteractive.rawValue == -1004)
    precondition(LAError.Code.biometryNotAvailable == .touchIDNotAvailable)
    precondition(LAError.Code.biometryNotEnrolled == .touchIDNotEnrolled)
    precondition(LAError.Code.biometryLockout == .touchIDLockout)
    precondition(LAError.biometryNotAvailable == .biometryNotAvailable)
    precondition(LAError.authenticationFailed == .authenticationFailed)
    precondition(LAError.userCancel == .userCancel)
    precondition(LAError.userFallback == .userFallback)
    precondition(LAError.systemCancel == .systemCancel)
    precondition(LAError.passcodeNotSet == .passcodeNotSet)
    precondition(LAError.touchIDNotAvailable == .touchIDNotAvailable)
    precondition(LAError.touchIDNotEnrolled == .touchIDNotEnrolled)
    precondition(LAError.touchIDLockout == .touchIDLockout)
    precondition(LAError.appCancel == .appCancel)
    precondition(LAError.invalidContext == .invalidContext)
    precondition(LAError.notInteractive == .notInteractive)
    precondition(LAError.companionNotAvailable == .companionNotAvailable)
    precondition(LAError.biometryNotEnrolled == .biometryNotEnrolled)
    precondition(LAError.biometryLockout == .biometryLockout)
    precondition(LAError.Code(rawValue: -1) == .authenticationFailed)
    precondition(LAError.Code(rawValue: -1004) == .notInteractive)
    precondition(LAError.Code(rawValue: 0) == nil)
    precondition(LAError.Code.userCancel != .userFallback)
}

func testLAErrorEqualityAndHash() {
    let empty = LAError(.authenticationFailed)
    precondition(empty.errorCode == -1)
    precondition(empty.code == .authenticationFailed)
    precondition(!empty.localizedDescription.isEmpty)

    let sentinel = LAError(.authenticationFailed, userInfo: ["sentinel": "value"])
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(empty == LAError(.authenticationFailed))
    precondition(sentinel != empty)

    var hasherA = Hasher()
    var hasherB = Hasher()
    empty.hash(into: &hasherA)
    LAError(.authenticationFailed).hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    _ = empty.hashValue

    precondition(LAError.Code.userCancel.hashValue == LAError.Code.userCancel.hashValue)
    var codeHasher = Hasher()
    LAError.Code.invalidContext.hash(into: &codeHasher)
    _ = codeHasher.finalize()
}

func testLAErrorPatternMatch() {
    let error: any Error = LAError(.userCancel)
    precondition(LAError.Code.userCancel ~= error)
    precondition(!(LAError.Code.authenticationFailed ~= error))
    do {
        throw LAError(.notInteractive)
    } catch let error as LAError where error.code == .notInteractive {
        ()
    } catch {
        preconditionFailure("expected Code.notInteractive pattern match")
    }
}

func testLAErrorNSErrorBridge() {
    let userInfo: [String: Any] = ["la": "bridge"]
    let typed = LAError(.appCancel, userInfo: userInfo)
    precondition(typed._nsError.domain == LAErrorDomain)
    precondition(typed._nsError.code == -9)
    precondition(typed._nsError.userInfo["la"] as? String == "bridge")

    let bridged = typed as NSError
    precondition(bridged.domain == LAErrorDomain)
    precondition(bridged.code == LAError.Code.appCancel.rawValue)

    let fromStored = LAError(_nsError: typed._nsError)
    precondition(fromStored.code == .appCancel)
    precondition(fromStored == typed)

    let withReason = LAError(.biometryNotAvailable, reason: "unavailable")
    precondition(withReason.code == .biometryNotAvailable)
    precondition(withReason.localizedDescription == "unavailable")
}

func testLAErrorProtocolConformance() {
    precondition(laBridgedDomain() == LAErrorDomain)
    precondition(laErrorTypeName(LAError.Code.self) == String(describing: LAError.self))
    var seen: Set<Int> = []
    seen.insert(LAError(.passcodeNotSet).hashValue)
    seen.insert(LAError(.passcodeNotSet).hashValue)
    precondition(seen.count == 1)
}

func testLAPolicyRawValues() {
    precondition(LAPolicy.deviceOwnerAuthenticationWithBiometrics.rawValue == 1)
    precondition(LAPolicy.deviceOwnerAuthentication.rawValue == 2)
    precondition(LAPolicy.deviceOwnerAuthenticationWithCompanion.rawValue == 3)
    precondition(LAPolicy.deviceOwnerAuthenticationWithBiometricsOrCompanion.rawValue == 4)
    precondition(LAPolicy(rawValue: 1) == .deviceOwnerAuthenticationWithBiometrics)
    precondition(LAPolicy(rawValue: 99) == nil)
    precondition(LAPolicy.deviceOwnerAuthentication != .deviceOwnerAuthenticationWithBiometrics)
    var hasher = Hasher()
    LAPolicy.deviceOwnerAuthentication.hash(into: &hasher)
    _ = hasher.finalize()
    _ = LAPolicy.deviceOwnerAuthentication.hashValue
}

func testLABiometryTypeRawValues() {
    precondition(LABiometryType.none.rawValue == 0)
    precondition(LABiometryType.touchID.rawValue == 1)
    precondition(LABiometryType.faceID.rawValue == 2)
    precondition(LABiometryType.opticID.rawValue == 4)
    precondition(LABiometryType.LABiometryNone == .none)
    precondition(LABiometryType(rawValue: 2) == .faceID)
    precondition(LABiometryType(rawValue: 3) == nil)
    precondition(LABiometryType.touchID != .faceID)
    var hasher = Hasher()
    LABiometryType.opticID.hash(into: &hasher)
    _ = hasher.finalize()
    _ = LABiometryType.none.hashValue
}

func testLACompanionTypeRawValues() {
    precondition(LACompanionType.mac.rawValue == 2)
    precondition(LACompanionType.vision.rawValue == 4)
    precondition(LACompanionType(rawValue: 2) == .mac)
    precondition(LACompanionType(rawValue: 1) == nil)
    precondition(LACompanionType.mac != .vision)
    var hasher = Hasher()
    LACompanionType.mac.hash(into: &hasher)
    _ = hasher.finalize()
    _ = LACompanionType.vision.hashValue
}

func testLACredentialTypeRawValues() {
    precondition(LACredentialType.applicationPassword.rawValue == 0)
    precondition(LACredentialType.smartCardPIN.rawValue == -3)
    precondition(LACredentialType(rawValue: 0) == .applicationPassword)
    precondition(LACredentialType(rawValue: 1) == nil)
    precondition(LACredentialType.applicationPassword != .smartCardPIN)
    var hasher = Hasher()
    LACredentialType.smartCardPIN.hash(into: &hasher)
    _ = hasher.finalize()
    _ = LACredentialType.applicationPassword.hashValue
}

func testLAAccessControlOperationRawValues() {
    precondition(LAAccessControlOperation.createItem.rawValue == 0)
    precondition(LAAccessControlOperation.useItem.rawValue == 1)
    precondition(LAAccessControlOperation.createKey.rawValue == 2)
    precondition(LAAccessControlOperation.useKeySign.rawValue == 3)
    precondition(LAAccessControlOperation.useKeyDecrypt.rawValue == 4)
    precondition(LAAccessControlOperation.useKeyKeyExchange.rawValue == 5)
    precondition(LAAccessControlOperation(rawValue: 5) == .useKeyKeyExchange)
    precondition(LAAccessControlOperation(rawValue: 6) == nil)
    precondition(LAAccessControlOperation.createItem != .useItem)
    var hasher = Hasher()
    LAAccessControlOperation.createKey.hash(into: &hasher)
    _ = hasher.finalize()
    _ = LAAccessControlOperation.useKeySign.hashValue
}

func testLARightStateRawValues() {
    precondition(LARight.State.unknown.rawValue == 0)
    precondition(LARight.State.authorizing.rawValue == 1)
    precondition(LARight.State.authorized.rawValue == 2)
    precondition(LARight.State.notAuthorized.rawValue == 3)
    precondition(LARight.State(rawValue: 2) == .authorized)
    precondition(LARight.State(rawValue: 4) == nil)
    precondition(LARight.State.unknown != .authorized)
    var hasher = Hasher()
    LARight.State.notAuthorized.hash(into: &hasher)
    _ = hasher.finalize()
    _ = LARight.State.unknown.hashValue
}

func testPublicDefinesMacros() {
    precondition(kLAAccessControlOperationCreateItem == 0)
    precondition(kLAAccessControlOperationUseItem == 1)
    precondition(kLAAccessControlOperationCreateKey == 2)
    precondition(kLAAccessControlOperationUseKeySign == 3)
    precondition(kLAAccessControlOperationUseKeyDecrypt == 4)
    precondition(kLAAccessControlOperationUseKeyKeyExchange == 5)
    precondition(kLABiometryTypeNone == 0)
    precondition(kLABiometryTypeTouchID == 1)
    precondition(kLABiometryTypeFaceID == 2)
    precondition(kLABiometryTypeOpticID == 4)
    precondition(kLACompanionTypeNone == 0)
    precondition(kLACompanionTypeWatch == 1)
    precondition(kLACompanionTypeMac == 2)
    precondition(kLACompanionTypeVision == 4)
    precondition(kLACredentialTypeApplicationPassword == 0)
    precondition(kLACredentialSmartCardPIN == -3)
    precondition(kLAErrorAuthenticationFailed == -1)
    precondition(kLAErrorUserCancel == -2)
    precondition(kLAErrorUserFallback == -3)
    precondition(kLAErrorSystemCancel == -4)
    precondition(kLAErrorPasscodeNotSet == -5)
    precondition(kLAErrorTouchIDNotAvailable == -6)
    precondition(kLAErrorTouchIDNotEnrolled == -7)
    precondition(kLAErrorTouchIDLockout == -8)
    precondition(kLAErrorAppCancel == -9)
    precondition(kLAErrorInvalidContext == -10)
    precondition(kLAErrorWatchNotAvailable == -11)
    precondition(kLAErrorCompanionNotAvailable == -11)
    precondition(kLAErrorBiometryNotPaired == -12)
    precondition(kLAErrorBiometryDisconnected == -13)
    precondition(kLAErrorInvalidDimensions == -14)
    precondition(kLAErrorBiometryNotAvailable == -6)
    precondition(kLAErrorBiometryNotEnrolled == -7)
    precondition(kLAErrorBiometryLockout == -8)
    precondition(kLAErrorNotInteractive == -1004)
    precondition(kLAPolicyDeviceOwnerAuthenticationWithBiometrics == 1)
    precondition(kLAPolicyDeviceOwnerAuthentication == 2)
    precondition(kLAPolicyDeviceOwnerAuthenticationWithWatch == 3)
    precondition(kLAPolicyDeviceOwnerAuthenticationWithCompanion == 3)
    precondition(kLAPolicyDeviceOwnerAuthenticationWithBiometricsOrWatch == 4)
    precondition(kLAPolicyDeviceOwnerAuthenticationWithBiometricsOrCompanion == 4)
    precondition(kLAPolicyDeviceOwnerAuthenticationWithWristDetection == 5)
}

func testLATouchIDAuthenticationMaximumAllowableReuseDuration() {
    // Measured 2026-09-05: constant is 300.0; setter is not clamped (10000 stays 10000).
    precondition(LATouchIDAuthenticationMaximumAllowableReuseDuration == 300)
    let context = LAContext()
    precondition(context.touchIDAuthenticationAllowableReuseDuration == 0)
    context.touchIDAuthenticationAllowableReuseDuration = 10_000
    precondition(context.touchIDAuthenticationAllowableReuseDuration == 10_000)
    context.touchIDAuthenticationAllowableReuseDuration = 1.5
    precondition(context.touchIDAuthenticationAllowableReuseDuration == 1.5)
}

func testLAContextStorageAndBiometryType() {
    laResetHostState()
    let context = LAContext()
    precondition(context.biometryType == .none)
    precondition(context.localizedReason == "")
    precondition(context.localizedCancelTitle == nil)
    precondition(context.localizedFallbackTitle == nil)
    precondition(context.interactionNotAllowed == false)
    precondition(context.maxBiometryFailures == nil)
    precondition(context.touchIDAuthenticationAllowableReuseDuration == 0)
    precondition(context.evaluatedPolicyDomainState == nil)

    context.localizedReason = "unlock"
    context.localizedCancelTitle = "Stop"
    context.localizedFallbackTitle = "Passcode"
    context.interactionNotAllowed = true
    context.maxBiometryFailures = NSNumber(value: 2)
    context.touchIDAuthenticationAllowableReuseDuration = 1.5
    precondition(context.localizedReason == "unlock")
    precondition(context.localizedCancelTitle == "Stop")
    precondition(context.localizedFallbackTitle == "Passcode")
    precondition(context.interactionNotAllowed)
    precondition(context.maxBiometryFailures == NSNumber(value: 2))
    precondition(context.touchIDAuthenticationAllowableReuseDuration == 1.5)
}

func testLAContextCanEvaluatePolicyFailClosed() {
    laResetHostState()
    let context = LAContext()
    var bioError: LAError?
    precondition(
        !context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &bioError)
    )
    precondition(bioError?.code == .biometryNotAvailable)
    precondition(bioError?._nsError.domain == LAErrorDomain)

    var passError: LAError?
    precondition(!context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &passError))
    precondition(passError?.code == .passcodeNotSet)

    var companionError: LAError?
    precondition(
        !context.canEvaluatePolicy(.deviceOwnerAuthenticationWithCompanion, error: &companionError)
    )
    precondition(companionError?.code == .companionNotAvailable)

    var bothError: LAError?
    precondition(
        !context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometricsOrCompanion,
            error: &bothError
        )
    )
    precondition(bothError?.code == .biometryNotAvailable)

    precondition(!context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil))
}

func testLAContextCanEvaluatePolicyPasscodeHook() {
    laResetHostState()
    LocalAuthenticationTestHook.setSimulatedDevicePasscodeEnabled(true)
    defer { LocalAuthenticationTestHook.setSimulatedDevicePasscodeEnabled(false) }

    let context = LAContext()
    var passError: LAError? = LAError(.authenticationFailed)
    precondition(context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &passError))
    precondition(passError == nil)

    var bioError: LAError?
    precondition(
        !context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &bioError)
    )
    precondition(bioError?.code == .biometryNotAvailable)
}

func testLAContextEvaluatePolicyFailClosed() {
    laResetHostState()
    let context = LAContext()
    let bio = laWaitReply { reply in
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "host gate"
        ) { success, error in
            reply((success, error as? LAError))
        }
    }
    precondition(bio.0 == false)
    precondition(bio.1?.code == .biometryNotAvailable)
    precondition(context.localizedReason == "host gate")

    let pass = laWaitReply { reply in
        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "passcode"
        ) { success, error in
            reply((success, error as? LAError))
        }
    }
    precondition(pass.0 == false)
    precondition(pass.1?.code == .passcodeNotSet)

    switch laAwait({
        try await context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "host gate async"
        )
    }) {
    case .success:
        preconditionFailure("portable authentication reported success")
    case .failure(let error):
        precondition((error as? LAError)?.code == .passcodeNotSet)
    }
}

func testLAContextEvaluatePolicyQueue() {
    laResetHostState()
    let context = LAContext()
    let started = LALocked(false)
    let finished = LALocked(false)
    context.evaluatePolicy(
        .deviceOwnerAuthenticationWithBiometrics,
        localizedReason: "queue"
    ) { success, error in
        precondition(!success)
        precondition((error as? LAError)?.code == .biometryNotAvailable)
        finished.store(true)
    }
    started.store(true)
    // Apple: LAContext.h — reply is not inline; the call returns first.
    precondition(finished.load() == false)
    precondition(started.load())
    let deadline = Date().addingTimeInterval(2)
    while !finished.load() && Date() < deadline {
        Thread.sleep(forTimeInterval: 0.01)
    }
    precondition(finished.load())
}

func testLAContextEvaluatePolicyInteractionNotAllowed() {
    laResetHostState()
    let context = LAContext()
    context.interactionNotAllowed = true
    let result = laWaitReply { reply in
        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "no ui"
        ) { success, error in
            reply((success, error as? LAError))
        }
    }
    precondition(result.0 == false)
    precondition(result.1?.code == .notInteractive)
}

func testLAContextEvaluatePolicyPasscodeHook() {
    laResetHostState()
    LocalAuthenticationTestHook.setSimulatedDevicePasscodeEnabled(true)
    defer { LocalAuthenticationTestHook.setSimulatedDevicePasscodeEnabled(false) }

    let context = LAContext()
    let result = laWaitReply { reply in
        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "hook"
        ) { success, error in
            reply((success, error as? LAError))
        }
    }
    precondition(result.0)
    precondition(result.1 == nil)
    precondition(context.evaluatedPolicyDomainState == nil)

    switch laAwait({
        try await context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "hook async"
        )
    }) {
    case .success(let success):
        precondition(success)
    case .failure:
        preconditionFailure("simulated passcode evaluation failed")
    }
}

func testLAContextInvalidateInFlightAppCancel() {
    laResetHostState()
    let context = LAContext()
    let box = LALocked<(Bool, LAError?)?>(nil)
    let done = DispatchSemaphore(value: 0)
    LocalAuthenticationTestHook.withHeldReplies {
        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "in-flight"
        ) { success, error in
            box.store((success, error as? LAError))
            done.signal()
        }
        context.invalidate()
    }
    done.wait()
    let result = box.load()
    precondition(result?.0 == false)
    precondition(result?.1?.code == .appCancel)
}

func testLAContextInvalidateThenInvalidContext() {
    laResetHostState()
    let context = LAContext()
    context.invalidate()
    var authError: LAError?
    precondition(!context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError))
    precondition(authError?.code == .invalidContext)

    let result = laWaitReply { reply in
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "x") { success, error in
            reply((success, error as? LAError))
        }
    }
    precondition(result.0 == false)
    precondition(result.1?.code == .invalidContext)

    switch laAwait({
        try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "y")
    }) {
    case .success:
        preconditionFailure("invalidated context reported success")
    case .failure(let error):
        precondition((error as? LAError)?.code == .invalidContext)
    }
}

func testLAContextCredentials() {
    laResetHostState()
    let context = LAContext()
    precondition(!context.isCredentialSet(.applicationPassword))
    precondition(!context.isCredentialSet(.smartCardPIN))
    precondition(context.setCredential(Data([1, 2, 3]), type: .applicationPassword))
    precondition(context.isCredentialSet(.applicationPassword))
    precondition(!context.setCredential(Data([4]), type: .smartCardPIN))
    precondition(!context.isCredentialSet(.smartCardPIN))
    precondition(context.setCredential(nil, type: .applicationPassword) == false)
    precondition(!context.isCredentialSet(.applicationPassword))

    let other = LAContext()
    precondition(other.setCredential(Data([9]), type: .applicationPassword))
    other.invalidate()
    precondition(!other.setCredential(Data([9]), type: .applicationPassword))
    precondition(!other.isCredentialSet(.applicationPassword))
}

func testLAContextDomainState() {
    laResetHostState()
    let context = LAContext()
    let domain = context.domainState
    precondition(domain.biometry.biometryType == .none)
    precondition(domain.biometry.stateHash == nil)
    precondition(domain.companion.stateHash == nil)
    precondition(domain.companion.availableCompanionTypes.isEmpty)
    precondition(domain.companion.stateHash(for: .mac) == nil)
    precondition(domain.companion.stateHash(for: .vision) == nil)
    precondition(domain.stateHash == nil)
    precondition(context.evaluatedPolicyDomainState == nil)
}

func testLAAuthenticationRequirement() {
    let fallback = LABiometryFallbackRequirement.default
    let passcode = LABiometryFallbackRequirement.devicePasscode
    precondition(fallback === LABiometryFallbackRequirement.default)
    precondition(passcode === LABiometryFallbackRequirement.devicePasscode)
    precondition(fallback !== passcode)

    let requirement = LAAuthenticationRequirement.default
    precondition(requirement === LAAuthenticationRequirement.default)
    precondition(LAAuthenticationRequirement.biometry === LAAuthenticationRequirement.biometry)
    precondition(
        LAAuthenticationRequirement.biometryCurrentSet
            === LAAuthenticationRequirement.biometryCurrentSet
    )
    let withFallback = LAAuthenticationRequirement.biometry(fallback: passcode)
    precondition(type(of: withFallback) == LAAuthenticationRequirement.self)
    _ = LAAuthenticationRequirement()
    _ = LABiometryFallbackRequirement()
}

func testLARightStateMachineFailClosed() {
    laResetHostState()
    let right = LARight()
    precondition(right.state == .unknown)
    precondition(right.tag == 0)
    right.tag = 7
    precondition(right.tag == 7)

    let required = LARight(requirement: .biometry)
    precondition(required.state == .unknown)

    switch laAwait({
        try await right.authorize(localizedReason: "authorize")
    }) {
    case .success:
        preconditionFailure("LARight.authorize reported success")
    case .failure(let error):
        precondition((error as? LAError)?.code == .passcodeNotSet)
    }
    precondition(right.state == .notAuthorized)

    switch laAwait({
        try await required.authorize(localizedReason: "bio")
    }) {
    case .success:
        preconditionFailure("biometry right reported success")
    case .failure(let error):
        precondition((error as? LAError)?.code == .biometryNotAvailable)
    }
    precondition(required.state == .notAuthorized)

    let canAuthorize = laWaitReply { reply in
        right.checkCanAuthorize { error in
            reply(error as? LAError)
        }
    }
    precondition(canAuthorize?.code == .passcodeNotSet)

    let deauthCalls = LALocked(0)
    let deauthDone = DispatchSemaphore(value: 0)
    right.deauthorize {
        deauthCalls.store(deauthCalls.load() + 1)
        deauthDone.signal()
    }
    deauthDone.wait()
    precondition(deauthCalls.load() == 1)
    precondition(right.state == .notAuthorized)
}

func testLARightStateMachinePasscodeHook() {
    laResetHostState()
    LocalAuthenticationTestHook.setSimulatedDevicePasscodeEnabled(true)
    defer { LocalAuthenticationTestHook.setSimulatedDevicePasscodeEnabled(false) }

    let right = LARight()
    precondition(right.state == .unknown)
    let canAuthorize = laWaitReply { reply in
        right.checkCanAuthorize { error in
            reply(error)
        }
    }
    precondition(canAuthorize == nil)
    precondition(right.state == .unknown)

    switch laAwait({
        try await right.authorize(localizedReason: "login")
    }) {
    case .success:
        ()
    case .failure:
        preconditionFailure("default right should authorize with simulated passcode")
    }
    precondition(right.state == .authorized)

    let deauthDone = DispatchSemaphore(value: 0)
    right.deauthorize {
        deauthDone.signal()
    }
    deauthDone.wait()
    precondition(right.state == .notAuthorized)
}

func testLARightStoreInMemory() {
    laResetHostState()
    let store = LARightStore.shared
    precondition(store === LARightStore.shared)
    let right = LARight()
    right.tag = 11

    switch laAwait({
        try await store.saveRight(right, identifier: "id")
    }) {
    case .success(let persisted):
        precondition(persisted.tag == 11)
        precondition(persisted.state == .unknown)
    case .failure:
        preconditionFailure("in-memory saveRight failed")
    }

    switch laAwait({
        try await store.right(forIdentifier: "id")
    }) {
    case .success(let loaded):
        precondition(loaded.tag == 11)
    case .failure:
        preconditionFailure("in-memory right(forIdentifier:) missed a save")
    }

    switch laAwait({
        try await store.saveRight(right, identifier: "secret-id", secret: Data([1, 2]))
    }) {
    case .success(let persisted):
        let loaded = laWaitReply { reply in
            persisted.secret.loadData { data, error in
                reply((data, error as? LAError))
            }
        }
        precondition(loaded.0 == nil)
        precondition(loaded.1?.code == .invalidContext)
    case .failure:
        preconditionFailure("saveRight(secret:) failed")
    }

    switch laAwait({
        try await store.removeRight(forIdentifier: "id")
    }) {
    case .success:
        ()
    case .failure:
        preconditionFailure("removeRight(forIdentifier:) failed")
    }

    switch laAwait({
        try await store.right(forIdentifier: "id")
    }) {
    case .success:
        preconditionFailure("removed right was still stored")
    case .failure(let error):
        precondition((error as? LAError)?.code == .invalidContext)
    }

    let removeAll = laWaitReply { reply in
        store.removeAllRights { error in
            reply(error)
        }
    }
    precondition(removeAll == nil)
}

func testLAPersistedRightKeysFailClosed() {
    laResetHostState()
    let right = LARight()
    switch laAwait({
        try await LARightStore.shared.saveRight(right, identifier: "key-id")
    }) {
    case .success(let persisted):
        let exported = laWaitReply { reply in
            persisted.key.publicKey.exportBytes { data, error in
                reply((data, error as? LAError))
            }
        }
        precondition(exported.0 == nil)
        precondition(exported.1?.code == .invalidContext)
        precondition(persisted.key.publicKey === persisted.key.publicKey)
        _ = persisted.secret
    case .failure:
        preconditionFailure("saveRight for key probe failed")
    }
}

func testLAEnvironmentFailClosed() {
    let environment = LAEnvironment.currentUser
    precondition(environment === LAEnvironment.currentUser)
    let state = environment.state
    precondition(state.biometry != nil)
    precondition(state.biometry?.biometryType == LABiometryType.none)
    precondition(state.biometry?.isEnrolled == false)
    precondition(state.biometry?.isLockedOut == false)
    precondition(state.biometry?.isUsable == false)
    precondition(state.biometry?.builtInSensorInaccessible == true)
    precondition(state.biometry?.stateHash == Data())
    precondition(state.biometry?.localizedName == "")
    precondition(state.biometry?.iconSystemName == "")
    precondition(state.userPassword != nil)
    precondition(state.userPassword?.isSet == false)
    precondition(state.companions.isEmpty)
    precondition(state.allMechanisms.count == 2)

    let copy = state.copy() as? LAEnvironment.State
    precondition(copy === state)

    let observer = LAEnvironmentProbeObserver()
    environment.addObserver(observer)
    environment.removeObserver(observer)
    precondition(observer.calls == 0)
}

func testLAErrorSynthesizedOperators() {
    precondition(LAAccessControlOperation.createItem != .useItem)
    precondition(LABiometryType.none != .touchID)
    precondition(LACompanionType.mac != .vision)
    precondition(LACredentialType.applicationPassword != .smartCardPIN)
    precondition(LAError(.userCancel) != LAError(.userFallback))
    precondition(LAPolicy.deviceOwnerAuthentication != .deviceOwnerAuthenticationWithBiometrics)
    precondition(LARight.State.unknown != .authorized)
}
