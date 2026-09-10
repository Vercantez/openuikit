// UIBarItem — the abstract base UIKit gives every bar item.
// Owner: viewcontroller module (M13 "bars & appearance").
//
// SDK EVIDENCE (iOS 26.1,
// .../iPhoneSimulator26.1.sdk/System/Library/Frameworks/UIKit.framework/
// Headers/):
//
//   UIBarItem.h:19        UIKIT_EXTERN … NS_SWIFT_UI_ACTOR
//                         @interface UIBarItem : NSObject <NSCoding, UIAppearance>
//     :24   enabled                        BOOL, default YES
//     :25   title                          NSString *  (nullable, copy)
//     :26   image                          UIImage *   (nullable, strong)
//     :27   landscapeImagePhone            UIImage *   (nullable, strong)
//     :30   largeContentSizeImage          UIImage *   (nullable, strong)
//     :32   imageInsets                    UIEdgeInsets, default zero
//     :33   landscapeImagePhoneInsets      UIEdgeInsets, default zero
//     :34   largeContentSizeImageInsets    UIEdgeInsets, default zero
//     :35   tag                            NSInteger, default 0
//     :39   -setTitleTextAttributes:forState:
//     :40   -titleTextAttributesForState:
//   UIBarButtonItem.h:69  @interface UIBarButtonItem : UIBarItem <NSCoding>
//   UITabBarItem.h:35     @interface UITabBarItem : UIBarItem
//   UIAccessibilityIdentification.h:33
//                         @interface UIBarItem (UIAccessibility) <UIAccessibilityIdentification>
//
// The port had no `UIBarItem` at all and made `UIBarButtonItem` and
// `UITabBarItem` unrelated root classes. That cost
// docs/agent_reports/ios-oss-launch.md two "UIBarItem type absent"
// diagnostics plus every `UIBarItemProtocol` / `UIBarButtonItemProtocol` /
// `UITabBarItemProtocol` conformance in Kickstarter-Prelude, whose protocol
// chain is rooted at `NSObjectProtocol`.
//
// NOT adopted: `NSCoding` (the port has no archiver for a bar item) and
// `UIAppearance` (the port has no appearance proxy). Both would be
// unmeasured stubs; recorded in docs/KNOWN_GAPS.md.

// NSObject provider, chosen exactly as UIResponder.swift chooses it.
#if canImport(Foundation)
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
#error("OpenUIKit requires Foundation.NSObject or ObjectiveC.NSObject")
#endif

@preconcurrency @MainActor
open class UIBarItem: NSObject, UIAccessibilityIdentification {
    /// Default YES (UIBarItem.h:24).
    open var isEnabled: Bool = true
    open var title: String?
    open var image: UIImage?
    /// iPhone-landscape variant. Storage only: the port's bars do not switch
    /// artwork on rotation, so nothing reads it (docs/KNOWN_GAPS.md).
    open var landscapeImagePhone: UIImage?
    /// Large-content (accessibility) artwork. Storage only, same reason.
    open var largeContentSizeImage: UIImage?
    /// Storage only: the port's bars lay items out on their own measured
    /// metrics and no fixture insets an item image (docs/KNOWN_GAPS.md).
    open var imageInsets: UIEdgeInsets = .zero
    open var landscapeImagePhoneInsets: UIEdgeInsets = .zero
    open var largeContentSizeImageInsets: UIEdgeInsets = .zero
    open var tag: Int = 0

    /// UIAccessibilityIdentification. UIKit keeps this on the bar item, not
    /// on the private descendant view that draws it (iOS 26.1 runtime probe,
    /// recorded when the property was on UIBarButtonItem).
    open var accessibilityIdentifier: String?

    private var _titleTextAttributes: [UIControl.State: [NSAttributedString.Key: Any]] = [:]

    public override init() { super.init() }

    // Relayout notification stays where it already was: `UITabBarItem`
    // overrides `title` to keep its `setNeedsLayout`, and `UIBarButtonItem`
    // keeps having none. The re-parent therefore moves no pixels.

    /// UIBarItem.h:39. Storage only: the port's bars draw item titles with
    /// the bar's own measured metrics, and no fixture sets these.
    open func setTitleTextAttributes(_ attributes: [NSAttributedString.Key: Any]?,
                                     for state: UIControl.State) {
        if let attributes {
            _titleTextAttributes[state] = attributes
        } else {
            _titleTextAttributes.removeValue(forKey: state)
        }
    }

    /// UIBarItem.h:40.
    open func titleTextAttributes(for state: UIControl.State)
        -> [NSAttributedString.Key: Any]? {
        _titleTextAttributes[state]
    }
}
