import Foundation
import ManagedSettings

/// Isolated-host identity probe. The sealed host gate does not compile this
/// file. The later EC2 integration build imports real Foundation and passes
/// genuine Foundation values through public ManagedSettings APIs.
func managedSettingsDependencyIdentityProbe() {
    let bundle: String = "com.example.foundation.app"
    let application = Application(bundleIdentifier: bundle)
    precondition(application.bundleIdentifier == bundle)

    let host: String = "example.com"
    let domain = WebDomain(domain: host)
    precondition(domain.domain == host)

    let nameValue: String = "identity-\(UUID().uuidString)"
    let storeName = ManagedSettingsStore.Name(rawValue: nameValue)
    precondition(storeName.rawValue == nameValue)
    let store = ManagedSettingsStore(named: storeName)
    store.application.denyAppRemoval = true
    precondition(store.application.denyAppRemoval == true)

    let payload = ["linuxOpaqueID": UUID().uuidString]
    let data = try! JSONSerialization.data(withJSONObject: payload)
    let token = try! JSONDecoder().decode(ApplicationToken.self, from: data)
    let tokenApp = Application(token: token)
    precondition(tokenApp.token == token)
}
