// UITextItem — the iOS 17 text-item model behind
// `textView(_:primaryActionFor:defaultAction:)` and
// `textView(_:menuConfigurationFor:defaultMenu:)`.
// Owner: text-input module. §9.6 BLOCKING row for WordPress-iOS (12 uses),
// wikipedia-ios (8) and firefox-ios (1).
//
// MEASURED Tools/oracle2/wordpressrowsprobe, iPhone 16 / iOS 26.1
// (`ios-26.1-iphone16-textitem.json`; docs/agent_reports/wordpress-textitem-popover.md):
//
//   * The Swift surface is `content` (`.link(URL)` / `.textAttachment` /
//     `.tag(String)`) and `range`. The ObjC `contentType` / `link` /
//     `tagIdentifier` / `textAttachment` members are hidden by API notes
//     (`__contentType` …) — an app cannot name them, so they are not here.
//   * `range` is the effective range of the attribute run in UTF-16 units
//     (link "Apple" at 5…10 → `[5, 5]`; tag "tagword" → `[14, 7]`;
//     attachment → `[27, 1]`).
//   * The default action handed to the delegate has an EMPTY title, the
//     identifier `UITextInteractableItemDefaultAction`, no image, no
//     attributes. The default menu for a link is titled with the URL's
//     absolute string, identifier `UITextItemDefaultMenuIdentifier`, three
//     children "Open" / "Copy" / "Share…"; for an attachment the same
//     identifier, empty title, "Copy Image" / "Save to Camera Roll"; for a
//     tag an EMPTY menu (no children) with a dynamic identifier.
//   * `UITextItemTagAttributeName` is the string "UITextItemTagAttribute".

#if canImport(Foundation)
import struct Foundation.URL

@preconcurrency @MainActor
open class UITextItem {
    public enum Content {
        case link(URL)
        case textAttachment(NSTextAttachment)
        case tag(String)
    }

    public let content: Content
    public let range: NSRange

    init(content: Content, range: NSRange) {
        self.content = content
        self.range = range
    }

    /// Identifier of the action the text view hands the delegate as
    /// `defaultAction` (MEASURED: title "", this identifier).
    public static let defaultActionIdentifier =
        UIAction.Identifier("UITextInteractableItemDefaultAction")
    /// Identifier of the link / attachment default menu (MEASURED).
    public static let defaultMenuIdentifier =
        UIMenu.Identifier("UITextItemDefaultMenuIdentifier")

    /// `UITextItemMenuPreview`. The port presents menus without a preview;
    /// the object is carried for the configuration's sake.
    @preconcurrency @MainActor
    public final class MenuPreview {
        public let view: UIView?
        private init(view: UIView?) { self.view = view }
        public static let `default` = MenuPreview(view: nil)
        public convenience init(view: UIView) { self.init(view: view as UIView?) }
    }

    /// `UITextItemMenuConfiguration`. WordPress spells it
    /// `.init(menu: defaultMenu)`.
    @preconcurrency @MainActor
    public final class MenuConfiguration {
        public let menu: UIMenu
        public let preview: MenuPreview?
        public init(menu: UIMenu) {
            self.menu = menu
            self.preview = .default
        }
        public init(preview: MenuPreview?, menu: UIMenu) {
            self.menu = menu
            self.preview = preview
        }
    }
}

extension NSAttributedString.Key {
    /// `UITextItemTagAttributeName` (MEASURED raw "UITextItemTagAttribute").
    /// A run carrying it becomes a `.tag(identifier)` text item.
    public static let textItemTag = NSAttributedString.Key("UITextItemTagAttribute")
}

/// The animator handed to `textItemMenuWillDisplayFor` / `…WillEndFor`.
/// The port's menu platter appears without a transition, so animations run
/// at once and completions run right after them.
@preconcurrency @MainActor
final class _UITextItemMenuAnimator: UIContextMenuInteractionAnimating {
    var previewViewController: UIViewController? { nil }
    private var completions: [() -> Void] = []
    func addAnimations(_ animations: @escaping () -> Void) { animations() }
    func addCompletion(_ completion: @escaping () -> Void) { completions.append(completion) }
    func finish() {
        let c = completions
        completions = []
        for f in c { f() }
    }
}

#endif
