import Foundation
import ContactProvider

func testDefaultDomainType() {
    let domain = DefaultContactProviderDomain()
    precondition(type(of: domain) == DefaultContactProviderDomain.self)
}

func testDefaultDomainInit() {
    let domain = DefaultContactProviderDomain()
    precondition(!domain.displayName.isEmpty)
    precondition(domain.userInfo.isEmpty)
    precondition(domain.identifier == DefaultContactProviderDomain.identifier)
}

func testDefaultDomainStaticIdentifier() {
    precondition(DefaultContactProviderDomain.identifier == "DefaultContactProviderDomain")
    precondition(!DefaultContactProviderDomain.identifier.isEmpty)
}

func testDefaultDomainInstanceIdentifier() {
    let domain = DefaultContactProviderDomain()
    precondition(domain.identifier == DefaultContactProviderDomain.identifier)
    precondition(domain.identifier == "DefaultContactProviderDomain")
}

func testDefaultDomainDisplayName() {
    let domain = DefaultContactProviderDomain()
    precondition(domain.displayName == ProcessInfo.processInfo.processName
        || domain.displayName == (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)
        || domain.displayName == (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String))
    precondition(!domain.displayName.isEmpty)
}

func testDefaultDomainUserInfo() {
    let domain = DefaultContactProviderDomain()
    precondition(domain.userInfo.isEmpty)
    precondition(domain.userInfo.keys.isEmpty)
}

func testContactProviderDomainConformance() {
    let domain: any ContactProviderDomain = DefaultContactProviderDomain()
    precondition(domain.identifier == DefaultContactProviderDomain.identifier)
}

func testDomainIdentifierRequirement() {
    let domain: any ContactProviderDomain = DefaultContactProviderDomain()
    precondition(domain.identifier == "DefaultContactProviderDomain")
}

func testDomainDisplayNameRequirement() {
    let domain: any ContactProviderDomain = DefaultContactProviderDomain()
    precondition(!domain.displayName.isEmpty)
}

func testDomainUserInfoRequirement() {
    let domain: any ContactProviderDomain = DefaultContactProviderDomain()
    precondition(domain.userInfo.isEmpty)
}
