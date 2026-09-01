import DeviceCheck
import Foundation

func deviceCheckCallbackSurface(hash: Data) {
    let device: DCDevice = .current
    _ = device.isSupported
    device.generateToken { (token: Data?, error: Error?) in
        _ = token
        _ = error
    }

    let service: DCAppAttestService = .shared
    _ = service.isSupported
    service.generateKey { (keyID: String?, error: Error?) in
        _ = keyID
        _ = error
    }
    service.attestKey("key", clientDataHash: hash) {
        (attestation: Data?, error: Error?) in
        _ = attestation
        _ = error
    }
    service.generateAssertion("key", clientDataHash: hash) {
        (assertion: Data?, error: Error?) in
        _ = assertion
        _ = error
    }
}

func deviceCheckAsyncSurface(hash: Data) async {
    do {
        let _: Data = try await DCDevice.current.generateToken()
        let keyID: String = try await DCAppAttestService.shared.generateKey()
        let _: Data = try await DCAppAttestService.shared.attestKey(
            keyID,
            clientDataHash: hash
        )
        let _: Data = try await DCAppAttestService.shared.generateAssertion(
            keyID,
            clientDataHash: hash
        )
    } catch let error as DCError {
        _ = error.code
    } catch {
        _ = error
    }
}

func deviceCheckErrorSurface() {
    let error = DCError(.featureUnsupported)
    _ = error.code == .featureUnsupported
    _ = DCError.unknownSystemFailure
    _ = DCError.featureUnsupported
    _ = DCError.invalidInput
    _ = DCError.invalidKey
    _ = DCError.serverUnavailable
    _ = DCErrorDomain
}
