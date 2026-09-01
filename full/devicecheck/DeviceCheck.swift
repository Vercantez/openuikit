@_exported import Foundation

/// Apple's public DeviceCheck error domain. The committed SDK contract names
/// the exported `_DCErrorDomain` symbol but does not record the string
/// payload; this spelling matches the `NS_ERROR_ENUM` identifier.
public let DCErrorDomain = "DCErrorDomain"

/// Portable counterpart of DeviceCheck's bridged `NS_ERROR_ENUM`.
///
/// Numeric codes follow the public Xcode 26.1 `DCError.h` enumeration:
/// `unknownSystemFailure = 0` through `serverUnavailable = 4`.
public struct DCError: Error, CustomNSError, Hashable, Equatable, Sendable {
    public enum Code: Int, Hashable, Sendable {
        case unknownSystemFailure = 0
        case featureUnsupported = 1
        case invalidInput = 2
        case invalidKey = 3
        case serverUnavailable = 4
    }

    public let code: Code

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        _ = userInfo
    }

    public var userInfo: [String: Any] { errorUserInfo }

    public static var errorDomain: String { DCErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] {
        [
            NSLocalizedDescriptionKey: Self.defaultReason(for: code)
        ]
    }

    public static let unknownSystemFailure = Code.unknownSystemFailure
    public static let featureUnsupported = Code.featureUnsupported
    public static let invalidInput = Code.invalidInput
    public static let invalidKey = Code.invalidKey
    public static let serverUnavailable = Code.serverUnavailable

    private static func defaultReason(for code: Code) -> String {
        switch code {
        case .unknownSystemFailure:
            return "A DeviceCheck system failure occurred"
        case .featureUnsupported:
            return "DeviceCheck is unavailable on this host"
        case .invalidInput:
            return "The DeviceCheck request input was invalid"
        case .invalidKey:
            return "The App Attest key was invalid"
        case .serverUnavailable:
            return "The DeviceCheck server is unavailable"
        }
    }
}

extension DCError.Code {
    /// Allow matching a DeviceCheck error code against an arbitrary error.
    public static func ~= (match: DCError.Code, error: any Error) -> Bool {
        (error as? DCError)?.code == match
    }
}

private func _deviceCheckUnsupportedError() -> DCError {
    DCError(.featureUnsupported)
}

private func _completeUnsupported<Value>(
    _ completion: @escaping (Value?, (any Error)?) -> Void
) {
    completion(nil, _deviceCheckUnsupportedError())
}

private func _awaitUnsupported<Value>() async throws -> Value {
    throw _deviceCheckUnsupportedError()
}

/// Linux has no Apple DeviceCheck token service. `isSupported` is therefore
/// `false`, and token generation fails closed with `featureUnsupported`.
/// Fabricating a device token would be a security bug.
@available(iOS 11.0, macOS 10.15, tvOS 11.0, watchOS 9.0, *)
open class DCDevice: NSObject {
    private static let _current = DCDevice()

    open class var current: DCDevice { _current }

    open var isSupported: Bool { false }

    open func generateToken(
        completionHandler completion: @escaping (Data?, (any Error)?) -> Void
    ) {
        _completeUnsupported(completion)
    }

    open func generateToken() async throws -> Data {
        try await _awaitUnsupported()
    }
}

/// Linux has no App Attest or Secure Enclave attestation service.
/// `isSupported` is `false`, and every key, attestation, and assertion
/// operation fails closed. Fabricating cryptographic material would be a
/// security bug.
@available(iOS 14.0, macOS 11.0, tvOS 15.0, watchOS 9.0, *)
open class DCAppAttestService: NSObject {
    private static let _shared = DCAppAttestService()

    open class var shared: DCAppAttestService { _shared }

    open var isSupported: Bool { false }

    open func generateKey(
        completionHandler: @escaping (String?, (any Error)?) -> Void
    ) {
        _completeUnsupported(completionHandler)
    }

    open func generateKey() async throws -> String {
        try await _awaitUnsupported()
    }

    open func attestKey(
        _ keyId: String,
        clientDataHash: Data,
        completionHandler: @escaping (Data?, (any Error)?) -> Void
    ) {
        _ = (keyId, clientDataHash)
        _completeUnsupported(completionHandler)
    }

    open func attestKey(
        _ keyId: String,
        clientDataHash: Data
    ) async throws -> Data {
        _ = (keyId, clientDataHash)
        return try await _awaitUnsupported()
    }

    open func generateAssertion(
        _ keyId: String,
        clientDataHash: Data,
        completionHandler: @escaping (Data?, (any Error)?) -> Void
    ) {
        _ = (keyId, clientDataHash)
        _completeUnsupported(completionHandler)
    }

    open func generateAssertion(
        _ keyId: String,
        clientDataHash: Data
    ) async throws -> Data {
        _ = (keyId, clientDataHash)
        return try await _awaitUnsupported()
    }
}
