import AppClip
import Foundation

// Isolated host-gate success against toolchain Foundation is not integrated
// guest-Foundation success. This probe is for a future clean EC2 run that
// builds guest Foundation first, then AppClip with that `-I` / `-L`.

func appClipDependencyIdentityProbe() {
    let date = Date(timeIntervalSince1970: 1)
    let data = Data("appclip-identity".utf8)
    let url = URL(string: "https://example.apple.com/appclip")!
    precondition(type(of: date) == Date.self)
    precondition(type(of: data) == Data.self)
    precondition(type(of: url) == URL.self)
    precondition(!String(reflecting: type(of: date)).hasPrefix("AppClip."))
    precondition(!String(reflecting: type(of: data)).hasPrefix("AppClip."))
    precondition(!String(reflecting: type(of: url)).hasPrefix("AppClip."))

    let error = APActivationPayloadError(
        .disallowed,
        userInfo: [
            NSLocalizedDescriptionKey: "identity",
            "date": date,
            "payload": data,
            "url": url,
        ]
    )
    precondition(error.userInfo["date"] as? Date == date)
    precondition(error.userInfo["payload"] as? Data == data)
    precondition(error.userInfo["url"] as? URL == url)
    precondition(APActivationPayloadError.errorDomain == APActivationPayloadErrorDomain)
    precondition(error.errorCode == 1)

    let bridged = error as NSError
    precondition(bridged.domain == APActivationPayloadErrorDomain)
    precondition(bridged.code == 1)
    precondition(!String(reflecting: type(of: bridged)).hasPrefix("AppClip."))
    precondition(type(of: bridged) == NSError.self)

    let payload = APActivationPayload()
    precondition(payload.url == nil)
    precondition(type(of: payload) == APActivationPayload.self)

    print("APPCLIP_DEPENDENCY_IDENTITY_OK")
}

#if APPCLIP_IDENTITY_MAIN
appClipDependencyIdentityProbe()
#endif
