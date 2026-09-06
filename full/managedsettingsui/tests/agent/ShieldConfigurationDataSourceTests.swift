import Foundation
@_spi(OpenUIKitHost) import ManagedSettingsUI

private struct LinuxTokenPayload: Encodable {
    let linuxOpaqueID: UUID
}

private func linuxActivityCategory(uuidString: String) -> ActivityCategory {
    let uuid = UUID(uuidString: uuidString)!
    let data = try! JSONEncoder().encode(LinuxTokenPayload(linuxOpaqueID: uuid))
    let token = try! JSONDecoder().decode(ActivityCategoryToken.self, from: data)
    return ActivityCategory(token: token)
}

func testShieldConfigurationDataSourceClass() {
    let source = ShieldConfigurationDataSource()
    let asObject: NSObject = source
    precondition(asObject === source)
    precondition(source is ShieldConfigurationDataSource)
    precondition(type(of: source) == ShieldConfigurationDataSource.self)
}

func testShieldConfigurationDataSourceInit() {
    ManagedSettingsUIHostControl.reset()
    let source = ShieldConfigurationDataSource()
    precondition(ManagedSettingsUIHostControl.lastShieldingRequest() == nil)
    precondition(!ManagedSettingsUIHostControl.didPresentShield())

    do {
        try ManagedSettingsUIHostControl.presentShield(ShieldConfiguration())
        preconditionFailure("Linux must not present a shield")
    } catch let error as ManagedSettingsUIUnavailable {
        precondition(error == .linuxHost(operation: "presentShield"))
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testConfigurationShieldingApplication() {
    ManagedSettingsUIHostControl.reset()
    let source = ShieldConfigurationDataSource()
    let application = Application(bundleIdentifier: "com.example.blocked")
    let configuration = source.configuration(shielding: application)
    precondition(ManagedSettingsUIHostControl.isSystemDefaultAppearance(configuration))
    precondition(
        ManagedSettingsUIHostControl.lastShieldingRequest()
            == .application(bundleIdentifier: "com.example.blocked")
    )
    precondition(!ManagedSettingsUIHostControl.didPresentShield())
    precondition(application.localizedDisplayName == nil)

    final class CustomSource: ShieldConfigurationDataSource {
        override func configuration(shielding application: Application) -> ShieldConfiguration {
            ShieldConfiguration(
                title: ShieldConfiguration.Label(
                    text: application.bundleIdentifier ?? "",
                    color: .red
                )
            )
        }
    }
    let custom = CustomSource()
    let overridden = custom.configuration(
        shielding: Application(bundleIdentifier: "com.example.custom")
    )
    precondition(overridden.title?.text == "com.example.custom")
    precondition(!ManagedSettingsUIHostControl.isSystemDefaultAppearance(overridden))
}

func testConfigurationShieldingApplicationInCategory() {
    ManagedSettingsUIHostControl.reset()
    let source = ShieldConfigurationDataSource()
    let application = Application(bundleIdentifier: "com.example.social")
    let category = linuxActivityCategory(uuidString: "11111111-1111-1111-1111-111111111111")
    precondition(category.token != nil)
    precondition(category.localizedDisplayName == nil)
    let configuration = source.configuration(shielding: application, in: category)
    precondition(ManagedSettingsUIHostControl.isSystemDefaultAppearance(configuration))
    precondition(
        ManagedSettingsUIHostControl.lastShieldingRequest()
            == .applicationInCategory(
                bundleIdentifier: "com.example.social",
                categoryTokenPresent: true
            )
    )
    precondition(!ManagedSettingsUIHostControl.didPresentShield())
}

func testConfigurationShieldingWebDomain() {
    ManagedSettingsUIHostControl.reset()
    let source = ShieldConfigurationDataSource()
    let domain = WebDomain(domain: "blocked.example")
    let configuration = source.configuration(shielding: domain)
    precondition(ManagedSettingsUIHostControl.isSystemDefaultAppearance(configuration))
    precondition(
        ManagedSettingsUIHostControl.lastShieldingRequest()
            == .webDomain(domain: "blocked.example")
    )
    precondition(!ManagedSettingsUIHostControl.didPresentShield())
    precondition(domain.token == nil)
}

func testConfigurationShieldingWebDomainInCategory() {
    ManagedSettingsUIHostControl.reset()
    let source = ShieldConfigurationDataSource()
    let domain = WebDomain(domain: "games.example")
    let category = linuxActivityCategory(uuidString: "22222222-2222-2222-2222-222222222222")
    let configuration = source.configuration(shielding: domain, in: category)
    precondition(ManagedSettingsUIHostControl.isSystemDefaultAppearance(configuration))
    precondition(
        ManagedSettingsUIHostControl.lastShieldingRequest()
            == .webDomainInCategory(domain: "games.example", categoryTokenPresent: true)
    )
    precondition(!ManagedSettingsUIHostControl.didPresentShield())

    do {
        try ManagedSettingsUIHostControl.presentShield(configuration)
        preconditionFailure("Linux must not present a category website shield")
    } catch let error as ManagedSettingsUIUnavailable {
        precondition(error == .linuxHost(operation: "presentShield"))
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}
