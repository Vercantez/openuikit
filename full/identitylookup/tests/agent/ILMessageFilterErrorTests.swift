import Foundation
import IdentityLookup

func testMessageFilterErrorDomain() {
    precondition(ILMessageFilterErrorDomain == "ILMessageFilterErrorDomain")
    precondition(ILMessageFilterError.errorDomain == ILMessageFilterErrorDomain)
}

func testMessageFilterErrorCodeRawValues() {
    precondition(ILMessageFilterError.Code.system.rawValue == 1)
    precondition(ILMessageFilterError.Code.invalidNetworkURL.rawValue == 2)
    precondition(ILMessageFilterError.Code.networkURLUnauthorized.rawValue == 3)
    precondition(ILMessageFilterError.Code.networkRequestFailed.rawValue == 4)
    precondition(ILMessageFilterError.Code.redundantNetworkDeferral.rawValue == 5)
    precondition(ILMessageFilterError.Code(rawValue: 0) == nil)
    precondition(ILMessageFilterError.Code(rawValue: 1) == .system)
    precondition(ILMessageFilterError.Code(rawValue: 2) == .invalidNetworkURL)
    precondition(ILMessageFilterError.Code(rawValue: 3) == .networkURLUnauthorized)
    precondition(ILMessageFilterError.Code(rawValue: 4) == .networkRequestFailed)
    precondition(ILMessageFilterError.Code(rawValue: 5) == .redundantNetworkDeferral)
    precondition(ILMessageFilterError.Code(rawValue: 6) == nil)
    precondition(ILMessageFilterError.Code.system != .invalidNetworkURL)
    precondition(
        ILMessageFilterError.Code.system.hashValue
            == ILMessageFilterError.Code.system.hashValue
    )
    var hasher = Hasher()
    ILMessageFilterError.Code.networkRequestFailed.hash(into: &hasher)
    _ = hasher.finalize()
}

func testMessageFilterErrorStaticCodes() {
    precondition(ILMessageFilterError.system == .system)
    precondition(ILMessageFilterError.invalidNetworkURL == .invalidNetworkURL)
    precondition(ILMessageFilterError.networkURLUnauthorized == .networkURLUnauthorized)
    precondition(ILMessageFilterError.networkRequestFailed == .networkRequestFailed)
    precondition(ILMessageFilterError.redundantNetworkDeferral == .redundantNetworkDeferral)
}

func testMessageFilterErrorStruct() {
    let error = ILMessageFilterError(
        .invalidNetworkURL,
        userInfo: [NSLocalizedDescriptionKey: "bad url"]
    )
    precondition(error.code == .invalidNetworkURL)
    precondition(error.errorCode == 2)
    precondition(error.errorUserInfo[NSLocalizedDescriptionKey] as? String == "bad url")
    precondition(error.userInfo[NSLocalizedDescriptionKey] as? String == "bad url")
    precondition(error.localizedDescription == "bad url")
    precondition(error == ILMessageFilterError(.invalidNetworkURL))
    precondition(error != ILMessageFilterError(.system))
    precondition(error.hashValue == ILMessageFilterError(.invalidNetworkURL).hashValue)
    var hasher = Hasher()
    error.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(ILMessageFilterError.Code.invalidNetworkURL ~= error)
    precondition(!(ILMessageFilterError.Code.system ~= error))
    let fallback = ILMessageFilterError(.system)
    precondition(fallback.localizedDescription.contains("system"))
}
