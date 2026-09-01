import DeviceCheck
import Foundation

private func requireUnsupported(_ error: Error?) {
    guard let error = error as? DCError else {
        fatalError("expected typed DCError")
    }
    precondition(error.code == .featureUnsupported)
    precondition(error.errorCode == DCError.featureUnsupported.rawValue)
    precondition(DCError.errorDomain == DCErrorDomain)
}

@main
struct DeviceCheckGuestRuntime {
    static func main() async {
        precondition(DCDevice.current === DCDevice.current)
        precondition(DCAppAttestService.shared === DCAppAttestService.shared)
        precondition(!DCDevice.current.isSupported)
        precondition(!DCAppAttestService.shared.isSupported)

        let tokenResult = await withCheckedContinuation { continuation in
            DCDevice.current.generateToken { token, error in
                continuation.resume(returning: (token, error))
            }
        }
        precondition(tokenResult.0 == nil)
        requireUnsupported(tokenResult.1)

        let keyResult = await withCheckedContinuation { continuation in
            DCAppAttestService.shared.generateKey { keyID, error in
                continuation.resume(returning: (keyID, error))
            }
        }
        precondition(keyResult.0 == nil)
        requireUnsupported(keyResult.1)

        let hash = Data(repeating: 0xA5, count: 32)
        let attestResult = await withCheckedContinuation { continuation in
            DCAppAttestService.shared.attestKey(
                "unsupported-key",
                clientDataHash: hash
            ) { data, error in
                continuation.resume(returning: (data, error))
            }
        }
        precondition(attestResult.0 == nil)
        requireUnsupported(attestResult.1)

        let assertionResult = await withCheckedContinuation { continuation in
            DCAppAttestService.shared.generateAssertion(
                "unsupported-key",
                clientDataHash: hash
            ) { data, error in
                continuation.resume(returning: (data, error))
            }
        }
        precondition(assertionResult.0 == nil)
        requireUnsupported(assertionResult.1)

        do {
            _ = try await DCDevice.current.generateToken()
            fatalError("generateToken must fail closed")
        } catch {
            requireUnsupported(error)
        }
        do {
            _ = try await DCAppAttestService.shared.generateKey()
            fatalError("generateKey must fail closed")
        } catch {
            requireUnsupported(error)
        }
        do {
            _ = try await DCAppAttestService.shared.attestKey(
                "unsupported-key",
                clientDataHash: hash
            )
            fatalError("attestKey must fail closed")
        } catch {
            requireUnsupported(error)
        }
        do {
            _ = try await DCAppAttestService.shared.generateAssertion(
                "unsupported-key",
                clientDataHash: hash
            )
            fatalError("generateAssertion must fail closed")
        } catch {
            requireUnsupported(error)
        }

        print("DEVICECHECK_GUEST_OK singleton=2 callbacks=4 async=4 fail-closed=1")
    }
}
