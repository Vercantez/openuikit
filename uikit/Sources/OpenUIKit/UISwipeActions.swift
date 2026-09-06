// UISwipeActionsConfiguration + UIContextualAction. Owner: table/collection
// extras (APP_LADDER §4 row 9: 10 apps / 67 uses each).
//
// Revealed-button metrics from swipeprobe list_rest_180 / list_image_180
// (iPhone SE 2x / iOS 26.1). Destructive fill is systemRed
// (1.000, 0.220, 0.235) = (255, 56, 60), the same TableEditor t900 disc.

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif

@preconcurrency @MainActor
open class UIContextualAction {
    public enum Style: Int, Sendable {
        case normal = 0
        case destructive
    }

    public typealias Handler = (UIContextualAction, UIView, @escaping (Bool) -> Void) -> Void

    public let style: Style
    public var title: String?
    public var backgroundColor: UIColor?
    public var image: UIImage?
    public let handler: Handler

    public init(style: Style, title: String?, handler: @escaping Handler) {
        self.style = style
        self.title = title
        self.handler = handler
        switch style {
        case .destructive:
            // MEASURED TableEditor t900 edit disc, iPhone SE 2x / iOS 26.1:
            // systemRed sRGB (255, 56, 60). Destructive swipe buttons use
            // the same semantic colour; a swipe-reveal probe replaces the
            // button WIDTH, not this fill.
            backgroundColor = .systemRed
        case .normal:
            backgroundColor = .systemGray
        }
    }

    public static func contextualAction(style: Style, title: String?,
                                        handler: @escaping Handler) -> UIContextualAction {
        UIContextualAction(style: style, title: title, handler: handler)
    }
}

@preconcurrency @MainActor
open class UISwipeActionsConfiguration {
    public let actions: [UIContextualAction]
    public var performsFirstActionWithFullSwipe: Bool = true

    public init(actions: [UIContextualAction]) {
        self.actions = actions
    }
}

extension UITableView {
    /// Programmatic reveal used by SceneBuilder / conformance. Real UIKit
    /// has no public equivalent; SceneKit on the oracle uses a pan.
    public func _openRevealSwipeActions(at indexPath: IndexPath,
                                        edge: UIRectEdge,
                                        progress: CGFloat) {
        guard let cell = cellForRow(at: indexPath) else { return }
        let config: UISwipeActionsConfiguration?
        if edge.contains(.left) {
            config = (delegate as? UITableViewDelegate)?
                .tableView(self, leadingSwipeActionsConfigurationForRowAt: indexPath)
        } else {
            config = (delegate as? UITableViewDelegate)?
                .tableView(self, trailingSwipeActionsConfigurationForRowAt: indexPath)
        }
        guard let config else { return }
        cell._openRevealSwipe(config, edge: edge, progress: progress)
    }
}

extension UICollectionView {
    public func _openRevealSwipeActions(at indexPath: IndexPath,
                                        edge: UIRectEdge,
                                        progress: CGFloat) {
        guard let cell = cellForItem(at: indexPath) as? UICollectionViewListCell else { return }
        let list = (collectionViewLayout as? UICollectionViewCompositionalLayout)?
            ._storedListConfiguration
        let config: UISwipeActionsConfiguration?
        if edge.contains(.left) {
            config = list?.leadingSwipeActionsConfigurationProvider?(indexPath)
        } else {
            config = list?.trailingSwipeActionsConfigurationProvider?(indexPath)
        }
        guard let config else { return }
        cell._openRevealSwipe(config, edge: edge, progress: progress)
    }
}

extension UITableViewCell {
    func _openRevealSwipe(_ configuration: UISwipeActionsConfiguration,
                          edge: UIRectEdge, progress: CGFloat) {
        _SwipeHost.install(on: self, configuration: configuration,
                           edge: edge, progress: progress)
    }
}

extension UICollectionViewListCell {
    func _openRevealSwipe(_ configuration: UISwipeActionsConfiguration,
                          edge: UIRectEdge, progress: CGFloat) {
        isListSwiped = progress > 0
        _SwipeHost.install(on: self, configuration: configuration,
                           edge: edge, progress: progress)
        setNeedsLayout()
    }

    func _openHideSwipe() {
        _SwipeHost.remove(from: self)
        isListSwiped = false
    }

    func layoutSwipeOverlay() {
        _SwipeHost.layout(in: self)
    }
}

/// Revealed swipe buttons. Every constant is a named sample from
/// `/tmp/swipeprobe` `list_rest_180` / `list_image_180` on iPhone SE 2x /
/// iOS 26.1 (plain `UICollectionViewListCell`, two trailing actions).
@preconcurrency @MainActor
final class _UISwipeActionButton: UIView {
    let action: UIContextualAction
    private let titleLabel = UILabel()
    private let imageView = UIImageView()

    /// MEASURED list_rest_180: Flag/Delete `_UISwipeActionDynamicButton`
    /// height **44**, y **4** in the 52-pt row.
    static let capsuleHeight: CGFloat = 44
    static let capsuleY: CGFloat = 4
    /// MEASURED list_rest_180 PNG: top-edge left inset of the orange
    /// capsule is **13** pt (quarter-circle samples at y=2/4/6 match r=13
    /// within 1 pt of AA). Not a 22-pt pill of the 44-pt height.
    static let capsuleCornerRadius: CGFloat = 13
    /// MEASURED list_rest_180: leading/trailing/between gap in
    /// `UISwipeActionDynamicPullView` is **10** (Flag x=10, Delete x=83.5
    /// = 10+63.5+10, pull width 157 = 2×63.5 + 3×10).
    static let pullPadding: CGFloat = 10
    /// MEASURED list_rest_180: title UILabel font **13**, height 16.
    static let titleFontSize: CGFloat = 13
    /// MEASURED list_rest_180 Delete: label x **12**, width 39.5 →
    /// button 63.5 = 12 + 39.5 + 12. Flag text 26 + 24 = 50, equalized
    /// to 63.5 when every action is title-only.
    static let titleInset: CGFloat = 12
    /// MEASURED list_image_180 trash `UIImageView` **14.5×16.5** at
    /// x=12, y=13.5; 4 pt gap to the title at x=30.5.
    static let imageTitleGap: CGFloat = 4
    static let measuredTrashSize = CGSize(width: 14.5, height: 16.5)

    /// MEASURED swipeprobe-flick, iPhone SE 2x / iOS 26.1, plain 375-wide
    /// list cell, hold=0: travel **250** does not fire, **260** fires
    /// `Delete` (`performsFirstActionWithFullSwipe`). Hold 0.45 s pans of
    /// 40…240 never fire — rest-reveal, not full-swipe. The rest-reveal
    /// SPI (`progress == 1`) lays out the settled pull, not the expansion.
    static let fullSwipeTravelPt: CGFloat = 260
    static let fullSwipeNoFireTravelPt: CGFloat = 250

    init(action: UIContextualAction) {
        self.action = action
        super.init(frame: .zero)
        backgroundColor = action.backgroundColor
        clipsToBounds = true
        layer.cornerRadius = Self.capsuleCornerRadius
        titleLabel.text = action.title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: Self.titleFontSize)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        addSubview(titleLabel)
        imageView.image = action.image
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var hasTitle: Bool {
        guard let t = action.title else { return false }
        return !t.isEmpty
    }

    var hasImage: Bool { action.image != nil }

    func preferredWidth() -> CGFloat {
        let textW = titleTextWidth()
        if hasImage && hasTitle {
            let img = imageSize()
            return Self.titleInset + img.width + Self.imageTitleGap + textW + Self.titleInset
        }
        if hasTitle {
            return Self.titleInset + textW + Self.titleInset
        }
        if hasImage {
            let img = imageSize()
            return Self.titleInset + img.width + Self.titleInset
        }
        return Self.titleInset * 2
    }

    private func titleTextWidth() -> CGFloat {
        titleLabel.font = .systemFont(ofSize: Self.titleFontSize)
        titleLabel.text = action.title
        return titleLabel.sizeThatFits(CGSize(width: 400, height: 16)).width
    }

    private func imageSize() -> CGSize {
        if let img = action.image, img.size.width > 0, img.size.height > 0 {
            return img.size
        }
        return Self.measuredTrashSize
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let textW = titleTextWidth()
        if hasImage && hasTitle {
            let img = imageSize()
            let iy = (bounds.height - img.height) / 2
            imageView.frame = CGRect(x: Self.titleInset, y: iy,
                                     width: img.width, height: img.height)
            titleLabel.frame = CGRect(x: Self.titleInset + img.width + Self.imageTitleGap,
                                      y: (bounds.height - 16) / 2,
                                      width: textW, height: 16)
        } else if hasImage {
            imageView.frame = bounds.insetBy(dx: Self.titleInset, dy: Self.titleInset)
            titleLabel.frame = .zero
        } else {
            imageView.frame = .zero
            let x = max(Self.titleInset, (bounds.width - textW) / 2)
            titleLabel.frame = CGRect(x: x, y: (bounds.height - 16) / 2,
                                      width: textW, height: 16)
        }
    }
}

@MainActor
enum _SwipeHost {
    static func install(on view: UIView,
                        configuration: UISwipeActionsConfiguration,
                        edge: UIRectEdge, progress: CGFloat) {
        remove(from: view)
        let host = _UISwipeHostView()
        host.configuration = configuration
        host.edge = edge
        host.progress = min(1, max(0, progress))
        view.addSubview(host)
        host.rebuild()
        host.tag = _UISwipeHostView.hostTag
    }

    static func remove(from view: UIView) {
        for sub in view.subviews {
            if sub is _UISwipeHostView { sub.removeFromSuperview() }
        }
    }

    static func layout(in view: UIView) {
        for sub in view.subviews {
            if let host = sub as? _UISwipeHostView {
                host.frame = view.bounds
                host.layoutButtons()
            }
        }
    }
}

@preconcurrency @MainActor
final class _UISwipeHostView: UIView {
    static let hostTag = 0x53574950
    var configuration: UISwipeActionsConfiguration?
    var edge: UIRectEdge = .right
    var progress: CGFloat = 0
    private var buttons: [_UISwipeActionButton] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = nil
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func rebuild() {
        for b in buttons { b.removeFromSuperview() }
        buttons.removeAll()
        guard let actions = configuration?.actions else { return }
        for action in actions {
            let button = _UISwipeActionButton(action: action)
            addSubview(button)
            buttons.append(button)
        }
        layoutButtons()
    }

    func layoutButtons() {
        let count = buttons.count
        guard count > 0 else { return }
        var widths = buttons.map { $0.preferredWidth() }
        let allTitleOnly = buttons.allSatisfy { $0.hasTitle && !$0.hasImage }
        if allTitleOnly {
            let shared = widths.max() ?? 0
            widths = Array(repeating: shared, count: count)
        }
        let pad = _UISwipeActionButton.pullPadding
        let rest = widths.reduce(0, +) + pad * CGFloat(count + 1)
        let revealed = rest * progress
        let leading = edge.contains(.left)
        let capsuleH = _UISwipeActionButton.capsuleHeight
        let capsuleY = _UISwipeActionButton.capsuleY
        // Trailing: first action sits nearest the trailing edge (Delete at
        // x=83.5, Flag at x=10 in list_rest_180). Leading keeps array order.
        let order: [Int]
        if leading {
            order = Array(0..<count)
        } else {
            order = Array((0..<count).reversed())
        }
        var x: CGFloat
        if leading {
            x = pad
        } else {
            x = bounds.width - revealed + pad
        }
        for i in order {
            let w = widths[i]
            buttons[i].frame = CGRect(x: x, y: capsuleY, width: w, height: capsuleH)
            x += w + pad
        }
        if let cell = superview {
            let shift = leading ? revealed : -revealed
            if let list = cell as? UICollectionViewListCell {
                list.contentView.transform = CGAffineTransform(translationX: shift, y: 0)
            } else if let table = cell as? UITableViewCell {
                table.contentView.transform = CGAffineTransform(translationX: shift, y: 0)
            }
        }
    }
}
