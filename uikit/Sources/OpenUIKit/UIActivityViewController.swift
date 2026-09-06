// UIActivityViewController — AN HONEST STUB. Owner: viewcontroller module
// (M13, docs/APP_COMPAT.md cluster #5 "Share / system UI", 84 uses in three
// of the four corpus apps).
//
// READ THIS BEFORE USING IT: **this controller shares nothing.** The iOS
// share sheet is system UI backed by extensions, XPC services and a
// remote-view controller; none of that exists off iOS, and none of its chrome
// can be measured by the oracles (it is not even drawn in the app's own
// process). What OpenUIKit can honestly provide, and does:
//
//   - the TYPE, so `UIActivityViewController(activityItems:
//     applicationActivities:)` compiles and an app's share plumbing builds;
//   - a real presentation: it presents as the measured page sheet, and its
//     content is a plain `UITableView` listing the titles of the activities
//     the APP supplied (`applicationActivities`) — no system activities
//     exist, so none are listed. With nothing to list, the sheet says so.
//   - `completionWithItemsHandler` fires exactly when UIKit's does: with
//     `(type, true, items, nil)` after an app activity is picked, and with
//     `(nil, false, nil, nil)` when the sheet is dismissed without one.
//
// The chrome is therefore NOT the iOS share sheet and no fixture claims it
// is; the sheet around it IS the measured page sheet, and the rows are the
// measured table-cell metrics. Recorded in docs/KNOWN_GAPS.md.

#if canImport(Foundation)
import class Foundation.Operation
#endif

/// UIKit's `UIActivity` — the app-supplied activity. Subclass it and
/// override `activityTitle` / `perform()`.
@preconcurrency @MainActor
open class UIActivity {
    public struct ActivityType: Hashable, Sendable, ExpressibleByStringLiteral {
        public let rawValue: String
        public init(_ rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { self.rawValue = value }
        /// A few of UIKit's system types, so `excludedActivityTypes` lists
        /// compile. Nothing here ever performs one.
        public static let postToFacebook = ActivityType("com.apple.UIKit.activity.PostToFacebook")
        public static let postToTwitter = ActivityType("com.apple.UIKit.activity.PostToTwitter")
        public static let message = ActivityType("com.apple.UIKit.activity.Message")
        public static let mail = ActivityType("com.apple.UIKit.activity.Mail")
        public static let print = ActivityType("com.apple.UIKit.activity.Print")
        public static let copyToPasteboard = ActivityType("com.apple.UIKit.activity.CopyToPasteboard")
        public static let assignToContact = ActivityType("com.apple.UIKit.activity.AssignToContact")
        public static let saveToCameraRoll = ActivityType("com.apple.UIKit.activity.SaveToCameraRoll")
        public static let addToReadingList = ActivityType("com.apple.UIKit.activity.AddToReadingList")
        public static let airDrop = ActivityType("com.apple.UIKit.activity.AirDrop")
        public static let openInIBooks = ActivityType("com.apple.UIKit.activity.OpenInIBooks")
        public static let markupAsPDF = ActivityType("com.apple.UIKit.activity.MarkupAsPDF")
        public static let sharePlay = ActivityType("com.apple.UIKit.activity.SharePlay")
        public static let collaborationInviteWithLink = ActivityType("com.apple.UIKit.activity.CollaborationInviteWithLink")
        public static let collaborationCopyLink = ActivityType("com.apple.UIKit.activity.CollaborationCopyLink")
        public static let addToHomeScreen = ActivityType("com.apple.UIKit.activity.AddToHomeScreen")
    }

    public enum Category: Sendable { case action, share }

    public init() {}

    open var activityType: ActivityType? { nil }
    open var activityTitle: String? { nil }
    open var activityImage: UIImage? { nil }
    @MainActor
    open class var activityCategory: Category { .action }

    open func canPerform(withActivityItems activityItems: [Any]) -> Bool { true }
    open func prepare(withActivityItems activityItems: [Any]) {}
    open func perform() { activityDidFinish(true) }

    /// UIKit's completion signal from a custom activity.
    public private(set) var didFinishCompleted: Bool?
    open func activityDidFinish(_ completed: Bool) {
        didFinishCompleted = completed
        _onFinish?(completed)
    }
    var _onFinish: ((Bool) -> Void)?
}

/// UIKit's protocol for items that describe themselves to activities.
/// Declared for source compatibility (16 census uses of `NSItemProvider`
/// sit next to it); nothing consumes it, because nothing shares.
@preconcurrency @MainActor
public protocol UIActivityItemSource: AnyObject {
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any
    func activityViewController(_ activityViewController: UIActivityViewController,
                                itemForActivityType activityType: UIActivity.ActivityType?) -> Any?
    func activityViewController(_ activityViewController: UIActivityViewController,
                                subjectForActivityType activityType: UIActivity.ActivityType?) -> String
}

public extension UIActivityItemSource {
    func activityViewController(_ activityViewController: UIActivityViewController,
                                subjectForActivityType activityType: UIActivity.ActivityType?) -> String { "" }
    func activityViewController(_ activityViewController: UIActivityViewController,
                                dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String { "" }
    func activityViewController(_ activityViewController: UIActivityViewController,
                                thumbnailImageForActivityType activityType: UIActivity.ActivityType?,
                                suggestedSize size: CGSize) -> UIImage? {
        _ = size
        return nil
    }
}

#if canImport(Foundation)
/// A placeholder activity item that produces its payload on a background
/// operation. OpenUIKit has no share sheet to run the operation; `item`
/// returns the placeholder unless a subclass overrides it.
open class UIActivityItemProvider: Operation, UIActivityItemSource, @unchecked Sendable {
    public let placeholderItem: Any?
    open var activityType: UIActivity.ActivityType?

    public init(placeholderItem: Any) {
        self.placeholderItem = placeholderItem
        super.init()
    }

    open var item: Any { placeholderItem as Any }

    public func activityViewControllerPlaceholderItem(
        _ activityViewController: UIActivityViewController
    ) -> Any {
        placeholderItem as Any
    }

    public func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        self.activityType = activityType
        return item
    }
}
#endif

@preconcurrency @MainActor
open class UIActivityViewController: UIViewController,
                                     UITableViewDataSource, UITableViewDelegate {
    public typealias CompletionWithItemsHandler =
        (UIActivity.ActivityType?, Bool, [Any]?, Error?) -> Void

    public let activityItems: [Any]
    public let applicationActivities: [UIActivity]?
    public var excludedActivityTypes: [UIActivity.ActivityType]?
    public var completionWithItemsHandler: CompletionWithItemsHandler?

    /// The activities actually offered: the app's, minus excluded ones,
    /// minus any that decline the items. Never any system activity.
    public var availableActivities: [UIActivity] {
        (applicationActivities ?? []).filter { a in
            if let t = a.activityType, excludedActivityTypes?.contains(t) == true { return false }
            return a.canPerform(withActivityItems: activityItems)
        }
    }

    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    /// Set when an activity is chosen, so the dismissal reports the right
    /// completion (UIKit reports "not completed" for a plain dismissal).
    var pickedActivity: UIActivity?

    public init(activityItems: [Any], applicationActivities: [UIActivity]?) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
        super.init()
        modalPresentationStyle = .pageSheet
    }

    open override func loadView() {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        v.backgroundColor = .systemGroupedBackground
        tableView.frame = v.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.delegate = self
        v.addSubview(tableView)
        view = v
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // One completion per presentation, whichever way it ended.
        guard let handler = completionWithItemsHandler else { return }
        completionWithItemsHandler = nil
        if let picked = pickedActivity {
            handler(picked.activityType, true, activityItems, nil)
        } else {
            handler(nil, false, nil, nil)
        }
    }

    // MARK: Table (the honest list — see the file header)

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Swift.max(availableActivities.count, 1)
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Share"
    }

    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "activity")
        let list = availableActivities
        if list.isEmpty {
            cell.textLabel.text = "No sharing services are available."
            cell.textLabel.textColor = .secondaryLabel
        } else {
            cell.textLabel.text = list[indexPath.row].activityTitle ?? ""
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let list = availableActivities
        guard indexPath.row < list.count else { return }
        let activity = list[indexPath.row]
        pickedActivity = activity
        activity.prepare(withActivityItems: activityItems)
        activity._onFinish = { [weak self] completed in
            if !completed { self?.pickedActivity = nil }
        }
        activity.perform()
        dismiss(animated: true)
    }
}
