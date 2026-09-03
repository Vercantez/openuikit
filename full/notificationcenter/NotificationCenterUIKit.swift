// UIKit.UIVibrancyEffect Today View factories.
//
// The nominal type is UIKit's. Factories return inert UIKit effects and do
// not apply Apple blur, vibrancy, or Notification Center compositing.
// Linux without staged UIKit does not compile this file's body.

#if canImport(UIKit)
import UIKit

extension UIVibrancyEffect {
    public class func notificationCenter() -> UIVibrancyEffect {
        UIVibrancyEffect()
    }

    public class func widgetPrimary() -> UIVibrancyEffect {
        UIVibrancyEffect()
    }

    public class func widgetSecondary() -> UIVibrancyEffect {
        UIVibrancyEffect()
    }

    public class func widgetEffect(
        forVibrancyStyle vibrancyStyle: UIVibrancyEffectStyle
    ) -> UIVibrancyEffect {
        _ = vibrancyStyle
        return UIVibrancyEffect()
    }
}

#endif
