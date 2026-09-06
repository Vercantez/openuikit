import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Attribution chip for content that Messages marked Shared with You.
///
/// Linux never talks to Messages. The view stores presentation fields and
/// returns an empty `highlightMenu`. It does not layout Apple attribution
/// chrome.
open class SWAttributionView: UIView {
    public var highlight: SWHighlight?
    public var displayContext: DisplayContext = .summary
    public var horizontalAlignment: HorizontalAlignment = .default
    public var backgroundStyle: BackgroundStyle = .default
    public var preferredMaxLayoutWidth: CGFloat = 0
    public var menuTitleForHideAction: String?
    public var supplementalMenu: UIMenu?

    /// Always an empty menu. Darwin would include Hide / Open / collaboration
    /// actions sourced from Messages.
    public var highlightMenu: UIMenu {
        UIMenu(title: menuTitleForHideAction ?? "", children: [])
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
}
