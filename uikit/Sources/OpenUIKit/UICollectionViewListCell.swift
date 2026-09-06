// UICollectionViewListCell + UICollectionLayoutListConfiguration.
// Owner: list-cell cluster (firefox-ios 19 uses of UICollectionViewListCell).
//
// List layout insets / row height / corner radius start from the measured
// table content-configuration cells (53 pt, 16 pt inset, inset-grouped
// card radius 26). A list-cell oracle scene replaces any number that
// disagrees.

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif

public struct UICollectionLayoutListConfiguration {
    public enum Appearance: Int, Sendable {
        case plain = 0
        case grouped
        case insetGrouped
        case sidebar
        case sidebarPlain
    }

    public enum HeaderMode: Int, Sendable {
        case none = 0
        case supplementary
        case firstItemInSection
    }

    public enum FooterMode: Int, Sendable {
        case none = 0
        case supplementary
    }

    public var appearance: Appearance
    public var backgroundColor: UIColor?
    public var showsSeparators = true
    public var separatorConfiguration = UIListSeparatorConfiguration()
    public var itemSeparatorHandler: ((IndexPath, UIListSeparatorConfiguration) -> UIListSeparatorConfiguration)?
    public var headerMode: HeaderMode = .none
    public var footerMode: FooterMode = .none
    public var headerTopPadding: CGFloat?
    public var leadingSwipeActionsConfigurationProvider: ((IndexPath) -> UISwipeActionsConfiguration?)?
    public var trailingSwipeActionsConfigurationProvider: ((IndexPath) -> UISwipeActionsConfiguration?)?

    public init(appearance: Appearance) {
        self.appearance = appearance
        switch appearance {
        case .plain, .sidebarPlain:
            backgroundColor = .systemBackground
        case .grouped, .insetGrouped, .sidebar:
            backgroundColor = .systemGroupedBackground
        }
    }
}

public struct UIListSeparatorConfiguration: Hashable {
    public enum Visibility: Int, Hashable, Sendable {
        case automatic = 0
        case visible
        case hidden
    }

    public var topSeparatorVisibility: Visibility = .automatic
    public var bottomSeparatorVisibility: Visibility = .automatic
    public var topSeparatorInsets = NSDirectionalEdgeInsets()
    public var bottomSeparatorInsets = NSDirectionalEdgeInsets()
    public var color: UIColor = .separator
    public var visualEffect: UIVisualEffect?

    /// MEASURED tableview_plain separator, iPhone SE 2x / iOS 26.1: 1 pt
    /// `separator` color, inset 16 leading / 8 trailing on plain rows.
    public static let automaticInsets = NSDirectionalEdgeInsets(top: 0, leading: 16,
                                                                bottom: 0, trailing: 0)

    public init() {
        bottomSeparatorInsets = UIListSeparatorConfiguration.automaticInsets
    }

    public static func == (lhs: UIListSeparatorConfiguration, rhs: UIListSeparatorConfiguration) -> Bool {
        lhs.topSeparatorVisibility == rhs.topSeparatorVisibility
            && lhs.bottomSeparatorVisibility == rhs.bottomSeparatorVisibility
            && lhs.topSeparatorInsets == rhs.topSeparatorInsets
            && lhs.bottomSeparatorInsets == rhs.bottomSeparatorInsets
            && lhs.color == rhs.color
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(topSeparatorVisibility)
        hasher.combine(bottomSeparatorVisibility)
        hasher.combine(topSeparatorInsets.leading)
        hasher.combine(bottomSeparatorInsets.leading)
        hasher.combine(color)
    }
}

extension NSCollectionLayoutSection {
    public static func list(using configuration: UICollectionLayoutListConfiguration,
                            layoutEnvironment: NSCollectionLayoutEnvironment)
        -> NSCollectionLayoutSection {
        let width = layoutEnvironment.container.effectiveContentSize.width
        let height = UICollectionViewListCell.estimatedRowHeight(for: configuration.appearance)
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(height))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = UICollectionViewListCell.sectionInsets(
            for: configuration.appearance, containerWidth: width)
        section.interGroupSpacing = 0
        section._listConfiguration = configuration
        if configuration.headerMode == .supplementary {
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(40.5)),
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top)
            section.boundarySupplementaryItems.append(header)
        }
        if configuration.footerMode == .supplementary {
            let footer = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(30)),
                elementKind: UICollectionView.elementKindSectionFooter,
                alignment: .bottom)
            section.boundarySupplementaryItems.append(footer)
        }
        return section
    }
}

extension NSCollectionLayoutSection {
    var _listConfiguration: UICollectionLayoutListConfiguration? {
        get { _listConfigurationStorage }
        set { _listConfigurationStorage = newValue }
    }
}

// Stored beside the section object. A section is a class, so this lives on
// the instance through objc-style associated storage without Foundation.
extension NSCollectionLayoutSection {
    // Box so the value type can hang off the class.
    fileprivate var _listConfigurationStorage: UICollectionLayoutListConfiguration? {
        get { _ListConfigBox.get(self) }
        set { _ListConfigBox.set(self, newValue) }
    }
}

@MainActor
private enum _ListConfigBox {
    static var map: [ObjectIdentifier: UICollectionLayoutListConfiguration] = [:]
    static func get(_ section: NSCollectionLayoutSection) -> UICollectionLayoutListConfiguration? {
        map[ObjectIdentifier(section)]
    }
    static func set(_ section: NSCollectionLayoutSection,
                    _ value: UICollectionLayoutListConfiguration?) {
        if let value {
            map[ObjectIdentifier(section)] = value
        } else {
            map.removeValue(forKey: ObjectIdentifier(section))
        }
    }
}

extension UICollectionViewCompositionalLayout {
    /// Apple's spelling. `init(list:)` is the same object so existing
    /// call sites and the stored list-configuration box stay one path.
    public class func list(using configuration: UICollectionLayoutListConfiguration)
        -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout(list: configuration)
    }

    public convenience init(list configuration: UICollectionLayoutListConfiguration) {
        let stored = configuration
        self.init { _, environment in
            NSCollectionLayoutSection.list(using: stored, layoutEnvironment: environment)
        }
        _storedListConfiguration = configuration
    }

    var _storedListConfiguration: UICollectionLayoutListConfiguration? {
        get { _LayoutListBox.get(self) }
        set { _LayoutListBox.set(self, newValue) }
    }
}

@MainActor
private enum _LayoutListBox {
    static var map: [ObjectIdentifier: UICollectionLayoutListConfiguration] = [:]
    static func get(_ layout: UICollectionViewCompositionalLayout) -> UICollectionLayoutListConfiguration? {
        map[ObjectIdentifier(layout)]
    }
    static func set(_ layout: UICollectionViewCompositionalLayout,
                    _ value: UICollectionLayoutListConfiguration?) {
        if let value {
            map[ObjectIdentifier(layout)] = value
        } else {
            map.removeValue(forKey: ObjectIdentifier(layout))
        }
    }
}

@preconcurrency @MainActor
open class UICollectionViewListCell: UICollectionViewCell {
    /// MEASURED collection_list_plain Echo, iPhone SE 2x / iOS 26.1: **52**.
    /// Collection list `.cell()` / `.valueCell()` rows. (Table
    /// content-configuration cells stay 53; this is the collection list.)
    public static let defaultRowHeight: CGFloat = 52

    /// MEASURED collection_list_plain Alpha vs Echo, iPhone SE 2x / iOS 26.1:
    /// first cell model height 70.5, subsequent single-line cells 52.
    /// `headerTopPadding` automatic for `.plain` is **18.5**, baked into
    /// the first item's layout attributes (cell origin stays at the
    /// section start; presentationFrame was still 52 mid self-size).
    public static let plainHeaderTopPadding: CGFloat = 18.5

    /// MEASURED collection_list_inset card, iPhone SE 2x / iOS 26.1:
    /// left edge 16 at mid-cell, radius **26** (top y=35 left=42 = 16+26;
    /// at 7.5 pt from the section bottom, inset 8 matches r=26).
    public static let insetGroupedCornerRadius: CGFloat = 26

    public var accessories: [UICellAccessory] = [] {
        didSet { rebuildAccessories() }
    }
    public var indentationLevel: Int = 0 {
        didSet { setNeedsLayout() }
    }
    public var indentationWidth: CGFloat = 10 {
        didSet { setNeedsLayout() }
    }
    public var indentsAccessories = true {
        didSet { setNeedsLayout() }
    }

    public let separatorLayoutGuide = UILayoutGuide()

    var isListEditing = false {
        didSet { if isListEditing != oldValue { setNeedsLayout(); setNeedsUpdateConfiguration() } }
    }
    var isListExpanded = false {
        didSet { if isListExpanded != oldValue { setNeedsUpdateConfiguration() } }
    }
    var isListReordering = false
    var isListSwiped = false {
        didSet { if isListSwiped != oldValue { setNeedsUpdateConfiguration() } }
    }

    private var accessoryViews: [UIView] = []
    private let separator = _UICollectionViewListSeparatorView()
    private let backgroundHost = _UIBackgroundConfigurationView()
    private var installedContentView: (UIView & UIContentView)?
    private var _contentConfiguration: (any UIContentConfiguration)?
    private var _backgroundConfiguration: UIBackgroundConfiguration?
    public var automaticallyUpdatesContentConfiguration = true
    public var automaticallyUpdatesBackgroundConfiguration = true
    public var configurationUpdateHandler: ((UICollectionViewCell, UICellConfigurationState) -> Void)?
    private var needsConfigurationUpdate = true

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureListCell()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureListCell()
    }

    private func configureListCell() {
        addLayoutGuide(separatorLayoutGuide)
        separator.isUserInteractionEnabled = false
        addSubview(separator)
        backgroundHost.isUserInteractionEnabled = false
        insertSubview(backgroundHost, at: 0)
        backgroundColor = nil
    }

    open func defaultContentConfiguration() -> UIListContentConfiguration {
        .cell()
    }

    open func defaultBackgroundConfiguration() -> UIBackgroundConfiguration {
        if let list = (collectionView?.collectionViewLayout as? UICollectionViewCompositionalLayout)?
            ._storedListConfiguration {
            switch list.appearance {
            case .plain, .sidebarPlain: return .listPlainCell()
            case .grouped, .insetGrouped: return .listGroupedCell()
            case .sidebar: return .listSidebarCell()
            }
        }
        return .listCell()
    }

    open var contentConfiguration: (any UIContentConfiguration)? {
        get { _contentConfiguration }
        set {
            _contentConfiguration = newValue
            installContent()
            setNeedsLayout()
        }
    }

    open var backgroundConfiguration: UIBackgroundConfiguration? {
        get { _backgroundConfiguration }
        set {
            _backgroundConfiguration = newValue
            applyBackground()
        }
    }

    open var configurationState: UICellConfigurationState {
        var state = UICellConfigurationState(traitCollection: traitCollection)
        state.isSelected = isSelected
        state.isHighlighted = isHighlighted
        state.isEditing = isListEditing
        state.isExpanded = isListExpanded
        state.isSwiped = isListSwiped
        state.isReordering = isListReordering
        return state
    }

    open func setNeedsUpdateConfiguration() {
        needsConfigurationUpdate = true
        setNeedsLayout()
    }

    open func updateConfiguration(using state: UICellConfigurationState) {
        if automaticallyUpdatesContentConfiguration, let current = _contentConfiguration {
            _contentConfiguration = current.updated(for: state)
            installContent()
        }
        if automaticallyUpdatesBackgroundConfiguration {
            let base = _backgroundConfiguration ?? defaultBackgroundConfiguration()
            _backgroundConfiguration = base.updated(for: state)
            applyBackground()
        }
        configurationUpdateHandler?(self, state)
        needsConfigurationUpdate = false
    }

    private func installContent() {
        installedContentView?.removeFromSuperview()
        installedContentView = nil
        guard let configuration = _contentConfiguration else { return }
        let view = configuration.makeContentView()
        view.configuration = configuration
        contentView.addSubview(view)
        installedContentView = view
    }

    private func applyBackground() {
        let config = _backgroundConfiguration ?? defaultBackgroundConfiguration()
        backgroundHost.configuration = config
        backgroundHost.isHidden = false
        setNeedsLayout()
    }

    private func rebuildAccessories() {
        for v in accessoryViews { v.removeFromSuperview() }
        accessoryViews.removeAll()
        for accessory in accessories {
            let view = makeAccessoryView(accessory)
            addSubview(view)
            accessoryViews.append(view)
        }
        setNeedsLayout()
    }

    private func makeAccessoryView(_ accessory: UICellAccessory) -> UIView {
        if let custom = accessory.customView { return custom }
        switch accessory.kind {
        case .disclosure, .outlineDisclosure, .popUpMenu:
            let v = UITableCellAccessoryView(frame: .zero)
            v.accessoryType = .disclosureIndicator
            if let tint = accessory.tintColor { v.tintColor = tint }
            return v
        case .checkmark:
            let v = UITableCellAccessoryView(frame: .zero)
            v.accessoryType = .checkmark
            if let tint = accessory.tintColor { v.tintColor = tint }
            return v
        case .delete:
            return UITableViewCellEditControl(frame: .zero)
        case .insert:
            let v = _UICollectionViewListInsertControl(frame: .zero)
            if let tint = accessory.tintColor { v.tintColor = tint }
            return v
        case .reorder:
            return UITableViewCellReorderControl(frame: .zero)
        case .multiselect:
            return _UICollectionViewListMultiselectControl(frame: .zero)
        case .label:
            let label = UILabel()
            label.text = accessory.labelText
            label.font = .preferredFont(forTextStyle: .body)
            label.textColor = accessory.tintColor ?? .secondaryLabel
            label.textAlignment = .right
            return label
        case .customView:
            return accessory.customView ?? UIView()
        }
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        isListSwiped = false
        isListEditing = false
        isListExpanded = false
        isListReordering = false
        _openHideSwipe()
    }

    open override func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        let attrs = layoutAttributes
        var size = attrs.size
        if size.width < 1 { size.width = bounds.width }
        let height = preferredHeight(forWidth: size.width)
        if height > 0 { size.height = height }
        attrs.size = size
        return attrs
    }

    func preferredHeight(forWidth width: CGFloat) -> CGFloat {
        let leading = leadingAccessoriesWidth()
        let trailing = trailingAccessoriesWidth()
        let indent = CGFloat(max(0, indentationLevel)) * indentationWidth
        let contentWidth = max(0, width - leading - trailing - indent)
        if let list = installedContentView as? UIListContentView {
            let packed = list.preferredHeight(forWidth: contentWidth)
            return max(UICollectionViewListCell.defaultRowHeight, packed)
        }
        if let view = installedContentView {
            view.frame = CGRect(x: 0, y: 0, width: contentWidth, height: 0)
            view.layoutIfNeeded()
            let fitting = view.systemLayoutSizeFitting(
                CGSize(width: contentWidth, height: 0),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel)
            return max(UICollectionViewListCell.defaultRowHeight, fitting.height)
        }
        return UICollectionViewListCell.defaultRowHeight
    }

    private func leadingAccessoriesWidth() -> CGFloat {
        for accessory in accessories where accessory.isLeading {
            if accessory.isVisible(isEditing: isListEditing) { return 40 }
        }
        return 0
    }

    private func trailingAccessoriesWidth() -> CGFloat {
        var w: CGFloat = 0
        for accessory in accessories where !accessory.isLeading {
            guard accessory.isVisible(isEditing: isListEditing) else { continue }
            switch accessory.kind {
            case .disclosure, .outlineDisclosure: w = max(w, 30)
            case .checkmark, .reorder: w = max(w, 40)
            default: w = max(w, accessory.standardWidth() + 16)
            }
        }
        return w
    }

    open override func layoutSubviews() {
        if needsConfigurationUpdate {
            updateConfiguration(using: configurationState)
        }
        super.layoutSubviews()
        let rtl = _layoutIsRTL
        let indent = CGFloat(max(0, indentationLevel)) * indentationWidth
        let h = bounds.height
        let w = bounds.width

        var leadingExtent: CGFloat = 0
        var trailingExtent: CGFloat = 0
        var leadingViews: [(UIView, UICellAccessory, CGFloat)] = []
        var trailingViews: [(UIView, UICellAccessory, CGFloat)] = []
        for (i, accessory) in accessories.enumerated() {
            guard i < accessoryViews.count else { break }
            let view = accessoryViews[i]
            let visible = accessory.isVisible(isEditing: isListEditing)
            view.isHidden = !visible
            guard visible else { continue }
            if accessory.isLeading {
                leadingViews.append((view, accessory, accessory.standardWidth()))
            } else {
                trailingViews.append((view, accessory, accessory.standardWidth()))
            }
        }

        // MEASURED collection_list_accessories, iPhone SE 2x / iOS 26.1:
        // delete/insert/multiselect control abs x 15, 26×26; contentView x 40.
        if !leadingViews.isEmpty {
            var x: CGFloat = rtl ? w - 15 : 15 + (indentsAccessories ? indent : 0)
            for (view, accessory, width) in leadingViews {
                let box = max(width, 26)
                let y = (h - box) / 2
                if rtl {
                    view.frame = CGRect(x: x - box, y: y, width: box, height: box)
                    x = view.frame.minX
                } else {
                    view.frame = CGRect(x: x, y: y, width: box, height: box)
                    x = view.frame.maxX
                }
                _ = accessory
            }
            leadingExtent = 40 + (indentsAccessories ? indent : 0)
        } else {
            leadingExtent = indentsAccessories ? indent : 0
        }

        // Trailing accessories. MEASURED collection_list_plain / accessories:
        // disclosure box 14×14 at x 345 (trailing 16); chevron 10.5×14 at
        // x 347. checkmark 19×18 at x 337.5 (trailing 18.5); content width
        // 335 (40 pt reserved). reorder 27×44 at x 333.5. outline visual
        // 44×44 at x 330 but content still 345 (disclosure reserved).
        if !trailingViews.isEmpty {
            // MEASURED collection_list_accessories + TableEditor t6800,
            // iPhone SE 2x / iOS 26.1: pack from the trailing edge.
            // Disclosure-only: box 14×14 at trailing **16** (abs 329).
            // Checkmark-only: box 19×18 at trailing **18.5** (abs 321.5).
            // Disclosure+checkmark: disclosure stays at 329, checkmark
            // packs inward at abs **299.5**, gap **10.5**.
            var cursor: CGFloat?
            for (view, accessory, width) in trailingViews {
                let boxW: CGFloat
                let boxH: CGFloat
                switch accessory.kind {
                case .disclosure, .outlineDisclosure:
                    boxW = 14; boxH = 14
                case .checkmark:
                    boxW = 19; boxH = 18
                case .reorder:
                    boxW = 27; boxH = min(h, 44)
                case .label:
                    let fit = (view as? UILabel)?.sizeThatFits(CGSize(width: 200, height: h))
                        ?? CGSize(width: width, height: h)
                    boxW = max(width, fit.width); boxH = h
                default:
                    boxW = max(width, 14); boxH = min(max(width, 14), h)
                }
                if cursor == nil {
                    let inset: CGFloat
                    if case .checkmark = accessory.kind { inset = 18.5 }
                    else { inset = 16 }
                    cursor = rtl ? inset : w - inset
                } else {
                    cursor = rtl ? cursor! + 10.5 : cursor! - 10.5
                }
                let x = rtl ? cursor! : cursor! - boxW
                let y: CGFloat
                if case .label = accessory.kind { y = 0 }
                else { y = (h - boxH) / 2 }
                view.frame = CGRect(x: x, y: y, width: boxW, height: boxH)
                cursor = rtl ? x + boxW : x
            }
            trailingExtent = rtl ? (cursor ?? 0) : (w - (cursor ?? w))
        }

        let contentX = rtl ? trailingExtent : leadingExtent
        let contentW = max(0, w - leadingExtent - trailingExtent)
        contentView.frame = CGRect(x: contentX, y: 0, width: contentW, height: h)
        installedContentView?.frame = contentView.bounds
        backgroundHost.frame = bounds
        if let bg = backgroundView { insertSubview(backgroundHost, aboveSubview: bg) }
        applyInsetGroupedCorners()

        // MEASURED collection_list_plain separator, iPhone SE 2x / iOS 26.1:
        // [16, cellBottom-1, 343, 1] (leading 16, trailing 16). With a
        // leading accessory the separator starts at 56 (= 16+40).
        let list = (collectionView?.collectionViewLayout as? UICollectionViewCompositionalLayout)?
            ._storedListConfiguration
        let showSep = list?.showsSeparators ?? true
        var last = false
        if let cv = collectionView, let path = cv.indexPath(for: self) {
            last = path.item + 1 == cv.numberOfItems(inSection: path.section)
        }
        separator.isHidden = !showSep || last
        let sepInset: CGFloat = 16
        let sepX = rtl ? sepInset : (leadingExtent == 0 ? sepInset : leadingExtent + sepInset)
        separator.frame = CGRect(x: sepX, y: h - 1,
                                 width: max(0, w - sepX - sepInset),
                                 height: 1)
        separatorLayoutGuide._solvedFrame = separator.frame
        layoutSwipeOverlay()
    }

    private func applyInsetGroupedCorners() {
        backgroundHost.layer.cornerRadius = 0
        backgroundHost.layer.maskedCorners = ._allKnown
        guard let list = (collectionView?.collectionViewLayout as? UICollectionViewCompositionalLayout)?
            ._storedListConfiguration,
              list.appearance == .insetGrouped,
              let cv = collectionView,
              let path = cv.indexPath(for: self) else { return }
        let last = cv.numberOfItems(inSection: path.section) - 1
        var mask: CACornerMask = []
        if path.item == 0 {
            mask.insert(.layerMinXMinYCorner)
            mask.insert(.layerMaxXMinYCorner)
        }
        if path.item == last {
            mask.insert(.layerMinXMaxYCorner)
            mask.insert(.layerMaxXMaxYCorner)
        }
        guard !mask.isEmpty else { return }
        backgroundHost.layer.cornerRadius = UICollectionViewListCell.insetGroupedCornerRadius
        backgroundHost.layer.maskedCorners = mask
        backgroundHost.clipsToBounds = true
    }

    static func estimatedRowHeight(for appearance: UICollectionLayoutListConfiguration.Appearance) -> CGFloat {
        defaultRowHeight
    }

    static func headerTopPadding(for appearance: UICollectionLayoutListConfiguration.Appearance) -> CGFloat {
        switch appearance {
        case .plain, .sidebarPlain:
            return plainHeaderTopPadding
        case .grouped, .insetGrouped, .sidebar:
            return 0
        }
    }

    /// MEASURED collection_list_inset, iPhone SE 2x / iOS 26.1: first cell
    /// abs `[16, 35, 343, 52]` so side inset **16**, section top **35**.
    /// Second section starts at y 242.5 = 207.5 + 35 (first section
    /// 35+52+68.5+52). Plain uses contentInsets 0 and bakes 18.5 into
    /// the first item instead (collection_list_plain Alpha 70.5).
    static func sectionInsets(for appearance: UICollectionLayoutListConfiguration.Appearance,
                              containerWidth: CGFloat) -> NSDirectionalEdgeInsets {
        switch appearance {
        case .insetGrouped:
            return NSDirectionalEdgeInsets(top: 35, leading: 16, bottom: 0, trailing: 16)
        case .grouped:
            return NSDirectionalEdgeInsets(top: 35, leading: 0, bottom: 0, trailing: 0)
        case .sidebar, .sidebarPlain:
            return NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
        case .plain:
            return .zero
        }
    }
}

@preconcurrency @MainActor
final class _UICollectionViewListSeparatorView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .separator
        isUserInteractionEnabled = false
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .separator
        isUserInteractionEnabled = false
    }
}

@preconcurrency @MainActor
final class _UICollectionViewListInsertControl: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = nil
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isOpaque = false
        backgroundColor = nil
    }
    override func drawContent(in canvas: Canvas, bounds: CGRect) {
        let fill = UIColor.systemGreen.resolvedCGColor(with: traitCollection)
        canvas.fill(UITableViewCellEditControl.ellipse(in: bounds.insetBy(dx: 2, dy: 2)),
                    color: fill)
        let arm = CGRect(x: bounds.midX - 5.25, y: bounds.midY - 0.75, width: 10.5, height: 1.5)
        let upright = CGRect(x: bounds.midX - 0.75, y: bounds.midY - 5.25, width: 1.5, height: 10.5)
        canvas.fill(UITableViewCellEditControl.rectPath(arm),
                    color: CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        canvas.fill(UITableViewCellEditControl.rectPath(upright),
                    color: CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    }
}

@preconcurrency @MainActor
final class _UICollectionViewListMultiselectControl: UIView {
    var isOn = false { didSet { setNeedsDisplay() } }
    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = nil
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isOpaque = false
        backgroundColor = nil
    }
    override func drawContent(in canvas: Canvas, bounds: CGRect) {
        let ring = bounds.insetBy(dx: 3, dy: 3)
        if isOn {
            canvas.fill(UITableViewCellEditControl.ellipse(in: ring),
                        color: (tintColor ?? UIColor.systemBlue)
                            .resolvedCGColor(with: traitCollection))
        } else {
            canvas.stroke(UITableViewCellEditControl.ellipse(in: ring),
                          color: UIColor.tertiaryLabel.resolvedCGColor(with: traitCollection),
                          lineWidth: 1.5)
        }
    }
}
