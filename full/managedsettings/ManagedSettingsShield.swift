import Foundation

// MARK: - Shield action

/// Constants that describe a user's action for your extension to handle.
///
/// Raw values follow Swift's implicit `Int` assignment in API-digester
/// declaration order. Central review should confirm Apple's runtime integers.
public enum ShieldAction: Int, Equatable, Hashable {
    /// The user pressed the top button on a shield.
    case primaryButtonPressed = 0
    /// The user pressed the optional secondary button.
    case secondaryButtonPressed = 1

    public typealias RawValue = Int
}

/// Constants a shield-action extension uses to tell the system how to respond.
///
/// Raw values follow Swift's implicit `Int` assignment in API-digester
/// declaration order. Central review should confirm Apple's runtime integers.
public enum ShieldActionResponse: Int, Equatable, Hashable {
    /// The system doesn't need to take any additional action.
    case none = 0
    /// Close the current application or web browser.
    case close = 1
    /// Defer a response (for example while contacting a parent device).
    case `defer` = 2

    public typealias RawValue = Int
}

/// A class for an extension that handles shield actions.
///
/// Linux has no shield UI or Managed Settings extension host. The default
/// `handle` implementations invoke `completionHandler` synchronously with
/// `.none` (no additional system action) and never invent a shield bypass.
open class ShieldActionDelegate: NSObject {
    public override init() {
        super.init()
    }

    /// Respond to a user action when a shield covers an application.
    open func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        _ = action
        _ = application
        completionHandler(.none)
    }

    /// Respond to a user action when a shield covers a category.
    open func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        _ = action
        _ = category
        completionHandler(.none)
    }

    /// Respond to a user action when a shield covers a website.
    open func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        _ = action
        _ = webDomain
        completionHandler(.none)
    }
}
