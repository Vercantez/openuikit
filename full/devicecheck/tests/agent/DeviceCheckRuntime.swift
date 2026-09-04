import DeviceCheck
import Foundation

/// Standalone runtime probe for the DeviceCheck lane. The sealed host gate
/// compiles `*Tests.swift` rather than this file.
func deviceCheckAgentRuntimeMain() {
    precondition(DCErrorDomain == "com.apple.devicecheck.error")
    precondition(DCError.errorDomain == DCErrorDomain)
    precondition(DCError.Code.featureUnsupported.rawValue == 1)
    precondition(DCError.Code(rawValue: 5) == nil)
    precondition(DCError.featureUnsupported == DCError.Code.featureUnsupported)

    let empty = DCError(.featureUnsupported)
    precondition(empty.userInfo.isEmpty)
    precondition(empty.errorUserInfo.isEmpty)
    precondition(empty.errorCode == 1)
    precondition(empty == DCError(.featureUnsupported))
    precondition(empty != DCError(.invalidInput))
    precondition(!empty.localizedDescription.isEmpty)

    var hasher = Hasher()
    empty.hash(into: &hasher)
    DCError.Code.invalidKey.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(empty.hashValue == DCError(.featureUnsupported).hashValue)

    let unsupported: any Error = empty
    precondition(DCError.Code.featureUnsupported ~= unsupported)

    precondition(DCDevice.current === DCDevice.current)
    precondition(DCDevice.current.isSupported == false)
    precondition(DCAppAttestService.shared === DCAppAttestService.shared)
    precondition(DCAppAttestService.shared.isSupported == false)

    var tokenCount = 0
    DCDevice.current.generateToken { token, error in
        tokenCount += 1
        precondition(token == nil)
        guard let dcError = error as? DCError else {
            fatalError("expected typed DCError")
        }
        precondition(dcError.code == .featureUnsupported)
    }
    precondition(tokenCount == 1)

    var keyCount = 0
    DCAppAttestService.shared.generateKey { keyID, error in
        keyCount += 1
        precondition(keyID == nil)
        guard let dcError = error as? DCError else {
            fatalError("expected typed DCError")
        }
        precondition(dcError.code == .featureUnsupported)
    }
    precondition(keyCount == 1)

    print("DEVICECHECK_AGENT_RUNTIME_OK")
}

#if DEVICECHECK_RUNTIME_MAIN
deviceCheckAgentRuntimeMain()
#endif
