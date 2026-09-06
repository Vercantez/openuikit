import Foundation
import VideoSubscriberAccount

func testAuthenticationSchemeValues() {
    precondition(VSAccountProviderAuthenticationScheme.saml.rawValue == "VSAccountProviderAuthenticationSchemeSAML")
    precondition(VSAccountProviderAuthenticationScheme.api.rawValue == "VSAccountProviderAuthenticationSchemeAPI")
    let custom = VSAccountProviderAuthenticationScheme(rawValue: "custom.scheme")
    precondition(custom.rawValue == "custom.scheme")
    let copied = VSAccountProviderAuthenticationScheme("VSAccountProviderAuthenticationSchemeSAML")
    precondition(copied == .saml)
    precondition(VSAccountProviderAuthenticationScheme.saml != .api)
    precondition(
        VSAccountProviderAuthenticationScheme.api.hashValue
            == VSAccountProviderAuthenticationScheme.api.hashValue
    )
    var hasher = Hasher()
    VSAccountProviderAuthenticationScheme.saml.hash(into: &hasher)
    _ = hasher.finalize()
}

func testCheckAccessOptionPrompt() {
    precondition(VSCheckAccessOption.prompt.rawValue == "VSCheckAccessOptionPrompt")
    let copy = VSCheckAccessOption(rawValue: "VSCheckAccessOptionPrompt")
    precondition(copy == .prompt)
    precondition(VSCheckAccessOption(rawValue: "other") != .prompt)
    precondition(VSCheckAccessOption.prompt.hashValue == VSCheckAccessOption.prompt.hashValue)
    var hasher = Hasher()
    VSCheckAccessOption.prompt.hash(into: &hasher)
    _ = hasher.finalize()
}

func testOpenTVProviderSettingsURLString() {
    precondition(VSOpenTVProviderSettingsURLString == "VSOpenTVProviderSettingsURLString")
    precondition(!VSOpenTVProviderSettingsURLString.isEmpty)
}
