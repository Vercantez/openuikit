import Foundation
import CryptoTokenKit

private func tkMust(_ condition: Bool, _ message: String) {
    if !condition {
        preconditionFailure(message)
    }
}

func testTKErrorDomain() {
    tkMust(TKErrorDomain == "TKErrorDomain", "TKErrorDomain")
    tkMust(TKError.errorDomain == TKErrorDomain, "TKError.errorDomain")
    tkMust(TKError._nsErrorDomain == TKErrorDomain, "_nsErrorDomain")
}

func testTKErrorCodeRawValues() {
    let expected: [(TKError.Code, Int)] = [
        (.notImplemented, -1),
        (.communicationError, -2),
        (.corruptedData, -3),
        (.canceledByUser, -4),
        (.authenticationFailed, -5),
        (.objectNotFound, -6),
        (.tokenNotFound, -7),
        (.badParameter, -8),
        (.authenticationNeeded, -9),
    ]
    for (code, raw) in expected {
        tkMust(code.rawValue == raw, "raw \(code) \(code.rawValue)")
        tkMust(TKError.Code(rawValue: raw) == code, "init raw \(raw)")
    }
    tkMust(TKError.Code(rawValue: 0) == nil, "unknown raw")
}

func testTKErrorStaticCodeAliases() {
    tkMust(TKError.notImplemented == .notImplemented, "notImplemented")
    tkMust(TKError.communicationError == .communicationError, "communicationError")
    tkMust(TKError.corruptedData == .corruptedData, "corruptedData")
    tkMust(TKError.canceledByUser == .canceledByUser, "canceledByUser")
    tkMust(TKError.authenticationFailed == .authenticationFailed, "authenticationFailed")
    tkMust(TKError.objectNotFound == .objectNotFound, "objectNotFound")
    tkMust(TKError.tokenNotFound == .tokenNotFound, "tokenNotFound")
    tkMust(TKError.badParameter == .badParameter, "badParameter")
    tkMust(TKError.authenticationNeeded == .authenticationNeeded, "authenticationNeeded")
    tkMust(TKError.TKErrorTokenNotFound == .tokenNotFound, "TKErrorTokenNotFound")
    tkMust(TKError.TKErrorObjectNotFound == .objectNotFound, "TKErrorObjectNotFound")
    tkMust(TKError.TKErrorAuthenticationFailed == .authenticationFailed, "TKErrorAuthenticationFailed")
    tkMust(TKError.Code.TKErrorTokenNotFound == .tokenNotFound, "Code.TKErrorTokenNotFound")
    tkMust(TKError.Code.TKErrorObjectNotFound == .objectNotFound, "Code.TKErrorObjectNotFound")
    tkMust(TKError.Code.TKErrorAuthenticationFailed == .authenticationFailed, "Code.TKErrorAuthenticationFailed")
}

func testTKErrorBridging() {
    let error = TKError(.badParameter, userInfo: ["k": "v"])
    tkMust(error.code == .badParameter, "code")
    tkMust(error.errorCode == -8, "errorCode")
    tkMust(error.userInfo["k"] as? String == "v", "userInfo")
    tkMust((error.errorUserInfo["k"] as? String) == "v", "errorUserInfo")
    let ns = error as NSError
    tkMust(ns.domain == TKErrorDomain, "ns domain")
    tkMust(ns.code == -8, "ns code")
    tkMust(TKError.Code.badParameter ~= error, "~=")
    let other = TKError(.badParameter, userInfo: ["k": "v"])
    tkMust(error == other, "==")
    let different = TKError(.tokenNotFound)
    tkMust(error != different, "!=")
    var hasher = Hasher()
    error.hash(into: &hasher)
    tkMust(error.hashValue == error.hashValue, "hashValue")
    tkMust(!error.localizedDescription.isEmpty, "localizedDescription")
    let fromNS = TKError(_nsError: ns)
    tkMust(fromNS.code == .badParameter, "from ns")
}
