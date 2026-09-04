import AdServices
import Foundation

// Isolated host-gate success against toolchain Foundation is not integrated
// guest-Foundation success. This probe is for a future clean EC2 run that
// builds guest Foundation first, then AdServices with that `-I` / `-L`.

func adServicesDependencyIdentityProbe() {
    let date = Date(timeIntervalSince1970: 1)
    let data = Data("adservices-identity".utf8)
    precondition(type(of: date) == Date.self)
    precondition(type(of: data) == Data.self)
    precondition(!String(reflecting: type(of: date)).hasPrefix("AdServices."))
    precondition(!String(reflecting: type(of: data)).hasPrefix("AdServices."))

    let error = AAAttributionError(
        .networkError,
        userInfo: [
            NSLocalizedDescriptionKey: "identity",
            "date": date,
            "payload": data,
        ]
    )
    precondition(error.userInfo["date"] as? Date == date)
    precondition(error.userInfo["payload"] as? Data == data)
    precondition(AAAttributionError.errorDomain == AAAttributionErrorDomain)
    precondition(error.errorCode == 1)

    let bridged = error as NSError
    precondition(bridged.domain == AAAttributionErrorDomain)
    precondition(bridged.code == 1)
    precondition(!String(reflecting: type(of: bridged)).hasPrefix("AdServices."))
    precondition(type(of: bridged) == NSError.self)

    print("ADSERVICES_DEPENDENCY_IDENTITY_OK")
}

#if ADSERVICES_IDENTITY_MAIN
adServicesDependencyIdentityProbe()
#endif
