#if canImport(ManagedSettings)
import ManagedSettings
#endif

/// The base class for the principal object of an app extension that configures
/// a shield's appearance.
///
/// Apple's documentation: the system provides a default appearance for any
/// methods that a subclass doesn't override, or if the extension takes too long
/// to return. Linux returns `ShieldConfiguration()` (all `nil` fields) and
/// never presents a shield, talks to a Family Controls daemon, or enforces
/// an extension-host timeout.
///
/// https://developer.apple.com/documentation/managedsettingsui/shieldconfigurationdatasource
open class ShieldConfigurationDataSource: NSObject {
    /// Creates a shield-configuration data source.
    ///
    /// Apple's surface is `override dynamic init()`. Linux has no ObjC
    /// message-send dynamism for this class; the designated `NSObject`
    /// override is the stored initializer.
    public override init() {
        super.init()
    }

    /// Requests a configuration to use for a shield that covers an application.
    ///
    /// The default implementation returns the system-default (all-`nil`)
    /// configuration. Linux records the request and does not present UI.
    open func configuration(shielding application: Application) -> ShieldConfiguration {
        ManagedSettingsUIHostRegistry.shared.record(
            .application(bundleIdentifier: application.bundleIdentifier)
        )
        return ShieldConfiguration()
    }

    /// Requests a configuration to use for a shield that covers an application
    /// because of its category.
    open func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        ManagedSettingsUIHostRegistry.shared.record(
            .applicationInCategory(
                bundleIdentifier: application.bundleIdentifier,
                categoryTokenPresent: category.token != nil
            )
        )
        return ShieldConfiguration()
    }

    /// Requests a configuration to use for a shield that covers a website.
    open func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        ManagedSettingsUIHostRegistry.shared.record(
            .webDomain(domain: webDomain.domain)
        )
        return ShieldConfiguration()
    }

    /// Requests a configuration to use for a shield that covers a website
    /// because of its category.
    open func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        ManagedSettingsUIHostRegistry.shared.record(
            .webDomainInCategory(
                domain: webDomain.domain,
                categoryTokenPresent: category.token != nil
            )
        )
        return ShieldConfiguration()
    }
}
