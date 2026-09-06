import Foundation
import ManagedApp

func testManagedAppConfigurationDecodingErrorProtocol() {
    var error = ManagedAppProbeDecodingError(
        code: ManagedAppConfigurationDecodingErrorCode(rawValue: 7)!,
        message: "bad landmark"
    )
    let boxed: any ManagedAppConfigurationDecodingError = error
    managedAppExpect(boxed is any Error)
    managedAppExpectEqual(error.code.rawValue, 7)
    error.code = ManagedAppConfigurationDecodingErrorCode(rawValue: 8)!
    managedAppExpectEqual(error.code.rawValue, 8)
}

func testManagedAppConfigurationDecodingErrorCodeProperty() {
    var error = ManagedAppProbeDecodingError(
        code: ManagedAppConfigurationDecodingErrorCode(
            rawValue: ManagedAppConfigurationDecodingErrorCode.keyNotFound
        )!,
        message: "missing key"
    )
    managedAppExpectEqual(
        error.code.rawValue,
        ManagedAppConfigurationDecodingErrorCode.keyNotFound
    )
    let replacement = ManagedAppConfigurationDecodingErrorCode(rawValue: 3)!
    error.code = replacement
    managedAppExpectEqual(error.code, replacement)
}

func testManagedAppConfigurationDecodingErrorMessageProperty() {
    var error = ManagedAppProbeDecodingError(
        code: ManagedAppConfigurationDecodingErrorCode(rawValue: 1)!,
        message: "hello"
    )
    managedAppExpectEqual(error.message, "hello")
    error.message = "world"
    managedAppExpectEqual(error.message, "world")
    managedAppExpectEqual(error.message.count, 5)
}

func testManagedAppConfigurationDecodingErrorCodable() {
    let error = ManagedAppProbeDecodingError(
        code: ManagedAppConfigurationDecodingErrorCode(
            rawValue: ManagedAppConfigurationDecodingErrorCode.dataCorrupted
        )!,
        message: "plist truncated"
    )
    let data = try! JSONEncoder().encode(error)
    let decoded = try! JSONDecoder().decode(ManagedAppProbeDecodingError.self, from: data)
    managedAppExpectEqual(decoded, error)
    managedAppExpectEqual(decoded.message, "plist truncated")
}
