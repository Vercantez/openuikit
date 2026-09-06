import Foundation
import ContactProvider

func testManagerType() {
    precondition(ContactProviderManager.self == ContactProviderManager.self)
    let manager = try! ContactProviderManager()
    precondition(type(of: manager) == ContactProviderManager.self)
}

func testManagerInitDefault() {
    let manager = try! ContactProviderManager()
    precondition(manager.domain.identifier == DefaultContactProviderDomain.identifier)
    precondition(manager.isEnabled == false)
}

func testManagerInitExplicitDefaultIdentifier() {
    let manager = try! ContactProviderManager(
        domainIdentifier: DefaultContactProviderDomain.identifier
    )
    precondition(manager.domain.identifier == "DefaultContactProviderDomain")
}

func testManagerInitUnknownDomainThrows() {
    do {
        _ = try ContactProviderManager(domainIdentifier: "unregistered.domain")
        preconditionFailure("expected domainNotRegistered")
    } catch let error as ContactProviderError {
        precondition(error == .domainNotRegistered)
        precondition(error.errorCode == 10)
    } catch {
        preconditionFailure("expected ContactProviderError")
    }
}

func testManagerDomain() {
    let manager = try! ContactProviderManager()
    let domain = manager.domain
    precondition(domain.identifier == DefaultContactProviderDomain.identifier)
    precondition(domain.displayName == DefaultContactProviderDomain().displayName)
    precondition(domain.userInfo.isEmpty)
}

func testManagerIsEnabled() {
    let manager = try! ContactProviderManager()
    precondition(manager.isEnabled == false)
}
