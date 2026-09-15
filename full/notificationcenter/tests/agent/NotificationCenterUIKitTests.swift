import Foundation
#if canImport(UIKit)
import UIKit
#endif
@_spi(OpenUIKitHost) import NotificationCenter

private final class NCWave4MarginWidget: NSObject, NCWidgetProviding {}

func testWidgetMarginInsetsPassthrough() {
#if canImport(UIKit)
    let widget = NCWave4MarginWidget()
    let proposed = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    let accepted: UIEdgeInsets = widget.widgetMarginInsets(
        forProposedMarginInsets: proposed
    )
    precondition(accepted == proposed)
    let zero: UIEdgeInsets = widget.widgetMarginInsets(
        forProposedMarginInsets: .zero
    )
    precondition(zero == .zero)
    let custom = UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4)
    precondition(
        widget.widgetMarginInsets(forProposedMarginInsets: custom) == custom
    )
#else
    // UIKit is unavailable on the sealed host: the Today View margin-inset
    // requirement does not exist here. The portable widget surface must stay
    // fail-closed instead of fabricating insets.
    let widget: any NCWidgetProviding = NCWave4MarginWidget()
    var result: NCUpdateResult?
    widget.widgetPerformUpdate { result = $0 }
    precondition(result == .noData)
    precondition(NCWidgetController.systemWidgetHostAvailable == false)
#endif
}

func testNotificationCenterVibrancyEffects() {
#if canImport(UIKit)
    let center: UIVibrancyEffect = UIVibrancyEffect.notificationCenter()
    let primary: UIVibrancyEffect = UIVibrancyEffect.widgetPrimary()
    let secondary: UIVibrancyEffect = UIVibrancyEffect.widgetSecondary()
    let styled: UIVibrancyEffect = UIVibrancyEffect.widgetEffect(
        forVibrancyStyle: .label
    )
    let fill: UIVibrancyEffect = UIVibrancyEffect.widgetEffect(
        forVibrancyStyle: .fill
    )
    // Factories return inert instances; they never apply Apple compositing.
    precondition(center !== primary)
    precondition(primary !== secondary)
    precondition(center !== secondary)
    precondition(styled !== fill)
    precondition(center !== styled)
#else
    // No UIKit host means no Notification Center compositor. Vibrancy
    // factories are absent here; record the fail-closed boundary instead.
    precondition(NCWidgetController.systemWidgetHostAvailable == false)
    let widget: any NCWidgetProviding = NCWave4MarginWidget()
    var result: NCUpdateResult?
    widget.widgetPerformUpdate { result = $0 }
    precondition(result == .noData)
#endif
}
