import Foundation
import UIKit
@_spi(OpenUIKitHost) import NotificationCenter

func takesUIKitInsets(_ value: UIKit.UIEdgeInsets) {}
func takesUIKitEffect(_ value: UIKit.UIVibrancyEffect) {}
func takesUIKitStyle(_ value: UIKit.UIVibrancyEffectStyle) {}
func takesFoundationContext(_ value: Foundation.NSExtensionContext) {}
func takesCGSize(_ value: CGSize) {}
func takesDisplayMode(_ value: NCWidgetDisplayMode) {}
func takesUpdateResult(_ value: NCUpdateResult) {}

private final class IdentityWidget: NSObject, NCWidgetProviding {
    func widgetMarginInsets(
        forProposedMarginInsets defaultMarginInsets: UIEdgeInsets
    ) -> UIEdgeInsets {
        defaultMarginInsets
    }
}

func proveNotificationCenterCanonicalIdentities() {
    let insets = UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4)
    takesUIKitInsets(insets)
    let widget = IdentityWidget()
    let returnedInsets: UIKit.UIEdgeInsets = widget.widgetMarginInsets(
        forProposedMarginInsets: insets
    )
    takesUIKitInsets(returnedInsets)
    precondition(returnedInsets == insets)

    let notification: UIKit.UIVibrancyEffect = .notificationCenter()
    let primary: UIKit.UIVibrancyEffect = .widgetPrimary()
    let secondary: UIKit.UIVibrancyEffect = .widgetSecondary()
    let styled: UIKit.UIVibrancyEffect = .widgetEffect(forVibrancyStyle: .label)
    takesUIKitEffect(notification)
    takesUIKitEffect(primary)
    takesUIKitEffect(secondary)
    takesUIKitEffect(styled)
    takesUIKitStyle(.fill)
    precondition(notification !== primary)

    let context: Foundation.NSExtensionContext = NSExtensionContext()
    takesFoundationContext(context)
    takesDisplayMode(context.widgetLargestAvailableDisplayMode)
    takesDisplayMode(context.widgetActiveDisplayMode)
    takesCGSize(context.widgetMaximumSize(for: .compact))
    context.widgetLargestAvailableDisplayMode = .expanded
    context.setPortableActiveDisplayMode(.expanded)
    context.setPortableWidgetMaximumSize(
        CGSize(width: 320, height: 110),
        for: .compact
    )
    takesFoundationContext(context)

    takesUpdateResult(.noData)
    takesDisplayMode(.compact)

    let insetsName = String(reflecting: UIEdgeInsets.self)
    let effectName = String(reflecting: UIVibrancyEffect.self)
    let contextName = String(reflecting: NSExtensionContext.self)
    precondition(!insetsName.contains("NotificationCenter"))
    precondition(!effectName.contains("NotificationCenter"))
    precondition(!contextName.contains("NotificationCenter"))
    precondition(insetsName.contains("UIKit") || insetsName == "UIEdgeInsets")
    precondition(effectName.contains("UIKit") || effectName == "UIVibrancyEffect")
    precondition(
        contextName.contains("Foundation") || contextName == "NSExtensionContext"
    )
}

proveNotificationCenterCanonicalIdentities()
print("NOTIFICATIONCENTER_IDENTITY_PROBE_OK")
