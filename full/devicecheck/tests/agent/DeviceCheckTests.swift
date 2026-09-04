import Dispatch
import Foundation
import DeviceCheck

private final class DCLocked<Value>: @unchecked Sendable {
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

private func dcAwait<T>(_ body: @escaping @Sendable () async throws -> T) -> Result<T, Error> {
    let semaphore = DispatchSemaphore(value: 0)
    let box = DCLocked<Result<T, Error>?>(nil)
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

private func requireUnsupported(_ error: (any Error)?) -> DCError {
    guard let error = error as? DCError else {
        preconditionFailure("expected typed DCError")
    }
    precondition(error.code == .featureUnsupported)
    precondition(error.errorCode == DCError.Code.featureUnsupported.rawValue)
    precondition(error.errorCode == 1)
    return error
}

func testDCErrorDomain() {
    precondition(DCErrorDomain == "com.apple.devicecheck.error")
    precondition(DCError.errorDomain == "com.apple.devicecheck.error")
    precondition(DCError.errorDomain == DCErrorDomain)
}

func testDCErrorCodeRawValues() {
    typealias Code = DCError.Code
    precondition(Code.unknownSystemFailure.rawValue == 0)
    precondition(Code.featureUnsupported.rawValue == 1)
    precondition(Code.invalidInput.rawValue == 2)
    precondition(Code.invalidKey.rawValue == 3)
    precondition(Code.serverUnavailable.rawValue == 4)
    precondition(Code(rawValue: 0) == .unknownSystemFailure)
    precondition(Code(rawValue: 1) == .featureUnsupported)
    precondition(Code(rawValue: 2) == .invalidInput)
    precondition(Code(rawValue: 3) == .invalidKey)
    precondition(Code(rawValue: 4) == .serverUnavailable)
    precondition(Code(rawValue: 5) == nil)
    precondition(Code(rawValue: -1) == nil)
}

func testDCErrorStaticCodeAliases() {
    precondition(DCError.unknownSystemFailure == DCError.Code.unknownSystemFailure)
    precondition(DCError.featureUnsupported == DCError.Code.featureUnsupported)
    precondition(DCError.invalidInput == DCError.Code.invalidInput)
    precondition(DCError.invalidKey == DCError.Code.invalidKey)
    precondition(DCError.serverUnavailable == DCError.Code.serverUnavailable)
}

func testDCErrorInitUserInfoAndCustomNSError() {
    let empty = DCError(.featureUnsupported)
    precondition(empty.code == .featureUnsupported)
    precondition(empty.userInfo.isEmpty)
    precondition(empty.errorUserInfo.isEmpty)
    precondition(empty.errorCode == 1)
    precondition(!empty.userInfo.keys.contains(NSLocalizedDescriptionKey))
    precondition(!empty.errorUserInfo.keys.contains(NSLocalizedDescriptionKey))

    let sentinel = DCError(
        .invalidInput,
        userInfo: ["sentinel": "value"]
    )
    precondition(sentinel.code == .invalidInput)
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(sentinel.userInfo.count == 1)
    precondition(sentinel.errorUserInfo.count == 1)
    precondition(!sentinel.userInfo.keys.contains(NSLocalizedDescriptionKey))
    precondition(sentinel.errorCode == DCError.Code.invalidInput.rawValue)
}

func testDCErrorEquality() {
    let empty = DCError(.featureUnsupported)
    let emptyAgain = DCError(.featureUnsupported)
    precondition(empty == emptyAgain)
    precondition(!(empty != emptyAgain))

    let sentinel = DCError(.featureUnsupported, userInfo: ["sentinel": "value"])
    precondition(sentinel != empty)
    precondition(!(sentinel == empty))
    precondition(empty != DCError(.invalidInput))
    precondition(
        DCError(.featureUnsupported, userInfo: ["sentinel": "a"]) !=
            DCError(.featureUnsupported, userInfo: ["sentinel": "b"])
    )

    let intOne = DCError(.invalidInput, userInfo: ["x": 1])
    let stringOne = DCError(.invalidInput, userInfo: ["x": "1"])
    precondition(intOne != stringOne)
}

func testDCErrorHashable() {
    let empty = DCError(.featureUnsupported)
    let sentinel = DCError(.featureUnsupported, userInfo: ["sentinel": "value"])
    precondition(empty.hashValue == sentinel.hashValue)

    var hasherA = Hasher()
    var hasherB = Hasher()
    empty.hash(into: &hasherA)
    DCError(.featureUnsupported).hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())

    let sameCode = [
        DCError(.invalidInput),
        DCError(.invalidInput, userInfo: ["x": 1]),
        DCError(.invalidInput, userInfo: ["x": "1"]),
    ]
    precondition(Set(sameCode.map(\.hashValue)).count == 1)
    precondition(sameCode[0] != sameCode[1])
    precondition(sameCode[1] != sameCode[2])
}

func testDCErrorCodeHashable() {
    var hasher = Hasher()
    DCError.Code.featureUnsupported.hash(into: &hasher)
    DCError.Code.invalidKey.hash(into: &hasher)
    _ = hasher.finalize()

    precondition(DCError.Code.invalidInput.hashValue == DCError.Code.invalidInput.hashValue)
    precondition(DCError.Code.invalidInput.hashValue != DCError.Code.invalidKey.hashValue)

    var set: Set<DCError.Code> = []
    for code in [
        DCError.Code.unknownSystemFailure,
        .featureUnsupported,
        .invalidInput,
        .invalidKey,
        .serverUnavailable,
    ] {
        set.insert(code)
    }
    precondition(set.count == 5)
    precondition(set.contains(.featureUnsupported))
}

func testDCErrorCodePatternMatch() {
    let unsupported: any Error = DCError(.featureUnsupported)
    precondition(DCError.Code.featureUnsupported ~= unsupported)
    precondition(!(DCError.Code.invalidInput ~= unsupported))
    precondition(!(DCError.Code.featureUnsupported ~= NSError(domain: "x", code: 1)))
}

func testDCErrorLocalizedDescription() {
    let error = DCError(.featureUnsupported)
    let description = error.localizedDescription
    precondition(!description.isEmpty)
}

func testDCDeviceCurrentIdentity() {
    let device = DCDevice.current
    precondition(device === DCDevice.current)
    let asObject: NSObject = device
    precondition(asObject === device)
    precondition(type(of: device) == DCDevice.self)
}

func testDCDeviceIsSupportedFalse() {
    precondition(DCDevice.current.isSupported == false)
}

func testDCDeviceGenerateTokenCallbackFailClosed() {
    var count = 0
    var token: Data? = Data()
    var error: (any Error)?
    DCDevice.current.generateToken { data, received in
        count += 1
        token = data
        error = received
    }
    precondition(count == 1)
    precondition(token == nil)
    _ = requireUnsupported(error)
}

func testDCDeviceGenerateTokenAsyncFailClosed() {
    let result = dcAwait { try await DCDevice.current.generateToken() }
    switch result {
    case .success:
        preconditionFailure("generateToken must fail closed")
    case .failure(let error):
        _ = requireUnsupported(error)
    }
}

func testDCAppAttestServiceSharedIdentity() {
    let service = DCAppAttestService.shared
    precondition(service === DCAppAttestService.shared)
    let asObject: NSObject = service
    precondition(asObject === service)
    precondition(type(of: service) == DCAppAttestService.self)
}

func testDCAppAttestServiceIsSupportedFalse() {
    precondition(DCAppAttestService.shared.isSupported == false)
}

func testDCAppAttestServiceGenerateKeyFailClosed() {
    var count = 0
    var keyID: String? = "sentinel"
    var error: (any Error)?
    DCAppAttestService.shared.generateKey { value, received in
        count += 1
        keyID = value
        error = received
    }
    precondition(count == 1)
    precondition(keyID == nil)
    _ = requireUnsupported(error)

    let result = dcAwait { try await DCAppAttestService.shared.generateKey() }
    switch result {
    case .success:
        preconditionFailure("generateKey must fail closed")
    case .failure(let asyncError):
        _ = requireUnsupported(asyncError)
    }
}

func testDCAppAttestServiceAttestKeyFailClosed() {
    let hash = Data(repeating: 0xA5, count: 32)
    var count = 0
    var attestation: Data? = Data()
    var error: (any Error)?
    DCAppAttestService.shared.attestKey(
        "unsupported-key",
        clientDataHash: hash
    ) { data, received in
        count += 1
        attestation = data
        error = received
    }
    precondition(count == 1)
    precondition(attestation == nil)
    _ = requireUnsupported(error)

    let result = dcAwait {
        try await DCAppAttestService.shared.attestKey(
            "unsupported-key",
            clientDataHash: hash
        )
    }
    switch result {
    case .success:
        preconditionFailure("attestKey must fail closed")
    case .failure(let asyncError):
        _ = requireUnsupported(asyncError)
    }
}

func testDCAppAttestServiceGenerateAssertionFailClosed() {
    let hash = Data(repeating: 0x5A, count: 32)
    var count = 0
    var assertion: Data? = Data()
    var error: (any Error)?
    DCAppAttestService.shared.generateAssertion(
        "unsupported-key",
        clientDataHash: hash
    ) { data, received in
        count += 1
        assertion = data
        error = received
    }
    precondition(count == 1)
    precondition(assertion == nil)
    _ = requireUnsupported(error)

    let result = dcAwait {
        try await DCAppAttestService.shared.generateAssertion(
            "unsupported-key",
            clientDataHash: hash
        )
    }
    switch result {
    case .success:
        preconditionFailure("generateAssertion must fail closed")
    case .failure(let asyncError):
        _ = requireUnsupported(asyncError)
    }
}
