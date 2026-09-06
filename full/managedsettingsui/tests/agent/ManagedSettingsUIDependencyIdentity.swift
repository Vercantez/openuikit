import Foundation
import ManagedSettings
import ManagedSettingsUI
@_spi(OpenUIKitHost) import ManagedSettingsUI

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest ManagedSettings/UIKit
// success. This file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest ManagedSettings, Foundation, UIKit (and their dylibs).
// 2. Build ManagedSettingsUI with those modules on `-I` / `-L`.
// 3. Link this file as a client that imports ManagedSettingsUI and every
//    declared dependency.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `MANAGEDSETTINGSUI_DEPENDENCY_IDENTITY_OK` and that
//    `libManagedSettingsUI.dylib` was loaded.

private func assertNotManagedSettingsUIType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("ManagedSettingsUI."))
}

func assertFoundationIdentity() {
    let label = ShieldConfiguration.Label(text: "Blocked", color: .black)
    precondition(label.text == "Blocked")
    _ = Foundation.UUID.self
    _ = Foundation.Data.self
}

func assertManagedSettingsIdentity() {
    let application = Application(bundleIdentifier: "com.example.app")
    assertNotManagedSettingsUIType(application)
    precondition(application.bundleIdentifier == "com.example.app")
    precondition(application.localizedDisplayName == nil)

    let webDomain = WebDomain(domain: "example.com")
    assertNotManagedSettingsUIType(webDomain)
    precondition(webDomain.domain == "example.com")

    struct TokenPayload: Encodable {
        let linuxOpaqueID: UUID
    }
    let payload = TokenPayload(
        linuxOpaqueID: UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")!
    )
    let data = try! JSONEncoder().encode(payload)
    let token = try! JSONDecoder().decode(ActivityCategoryToken.self, from: data)
    assertNotManagedSettingsUIType(token)
    let category = ActivityCategory(token: token)
    assertNotManagedSettingsUIType(category)
    precondition(category.localizedDisplayName == nil)

    ManagedSettingsUIHostControl.reset()
    let source = ShieldConfigurationDataSource()
    let applicationConfig = source.configuration(shielding: application)
    precondition(ManagedSettingsUIHostControl.isSystemDefaultAppearance(applicationConfig))
    let categoryConfig = source.configuration(shielding: application, in: category)
    precondition(ManagedSettingsUIHostControl.isSystemDefaultAppearance(categoryConfig))
    let domainConfig = source.configuration(shielding: webDomain)
    precondition(ManagedSettingsUIHostControl.isSystemDefaultAppearance(domainConfig))
}

func managedSettingsUIDependencyIdentityMain() {
    assertFoundationIdentity()
    assertManagedSettingsIdentity()
    print("MANAGEDSETTINGSUI_DEPENDENCY_IDENTITY_OK")
}
