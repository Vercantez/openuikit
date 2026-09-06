// UIContentConfiguration / UIContentView / UICellConfigurationState /
// UIBackgroundConfiguration. Owner: list-cell cluster (APP_LADDER §8
// firefox-ios UICollectionViewListCell 19, UIListContentConfiguration 5,
// UIBackgroundConfiguration 5).
//
// Geometry and fills that are not cited next to a rule are seeded from the
// already-measured table content-configuration cells (53 pt, 16 pt inset)
// and replaced once the list-cell oracle scenes land.

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif

public struct UIAxis: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let horizontal = UIAxis(rawValue: 1 << 0)
    public static let vertical = UIAxis(rawValue: 1 << 1)
    public static let both: UIAxis = [.horizontal, .vertical]
}

public struct NSDirectionalRectEdge: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let top = NSDirectionalRectEdge(rawValue: 1 << 0)
    public static let leading = NSDirectionalRectEdge(rawValue: 1 << 1)
    public static let bottom = NSDirectionalRectEdge(rawValue: 1 << 2)
    public static let trailing = NSDirectionalRectEdge(rawValue: 1 << 3)
    public static let all: NSDirectionalRectEdge = [.top, .leading, .bottom, .trailing]
}

public typealias UIConfigurationColorTransformer = @Sendable (UIColor) -> UIColor

public struct UIConfigurationStateCustomKey: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}

@MainActor
public protocol UIConfigurationState {
    var traitCollection: UITraitCollection { get set }
    init(traitCollection: UITraitCollection)
    subscript(key: UIConfigurationStateCustomKey) -> AnyHashable? { get set }
}

@MainActor
public protocol UIContentConfiguration {
    func makeContentView() -> UIView & UIContentView
    func updated(for state: any UIConfigurationState) -> Self
}

@MainActor
public protocol UIContentView: AnyObject {
    var configuration: any UIContentConfiguration { get set }
}

extension UIView {
    public typealias ContentMode = UIViewContentMode
}

public struct UICellConfigurationState: UIConfigurationState, Hashable {
    public var traitCollection: UITraitCollection
    public var isDisabled = false
    public var isHighlighted = false
    public var isSelected = false
    public var isFocused = false
    public var isPinned = false
    public var isEditing = false
    public var isExpanded = false
    public var isSwiped = false
    public var isReordering = false
    public var cellDragState: DragState = .none
    public var cellDropState: DropState = .none
    private var extras: [UIConfigurationStateCustomKey: AnyHashable] = [:]

    public enum DragState: Int, Hashable, Sendable {
        case none = 0
        case lifting
        case dragging
    }

    public enum DropState: Int, Hashable, Sendable {
        case none = 0
        case notTargeted
        case targeted
    }

    public init(traitCollection: UITraitCollection) {
        self.traitCollection = traitCollection
    }

    public subscript(key: UIConfigurationStateCustomKey) -> AnyHashable? {
        get { extras[key] }
        set { extras[key] = newValue }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(isDisabled)
        hasher.combine(isHighlighted)
        hasher.combine(isSelected)
        hasher.combine(isFocused)
        hasher.combine(isPinned)
        hasher.combine(isEditing)
        hasher.combine(isExpanded)
        hasher.combine(isSwiped)
        hasher.combine(isReordering)
        hasher.combine(cellDragState)
        hasher.combine(cellDropState)
    }

    public static func == (lhs: UICellConfigurationState, rhs: UICellConfigurationState) -> Bool {
        lhs.isDisabled == rhs.isDisabled
            && lhs.isHighlighted == rhs.isHighlighted
            && lhs.isSelected == rhs.isSelected
            && lhs.isFocused == rhs.isFocused
            && lhs.isPinned == rhs.isPinned
            && lhs.isEditing == rhs.isEditing
            && lhs.isExpanded == rhs.isExpanded
            && lhs.isSwiped == rhs.isSwiped
            && lhs.isReordering == rhs.isReordering
            && lhs.cellDragState == rhs.cellDragState
            && lhs.cellDropState == rhs.cellDropState
    }
}

public struct UIBackgroundConfiguration: Hashable {
    public var customView: UIView?
    public var cornerRadius: CGFloat = 0
    public var backgroundInsets: NSDirectionalEdgeInsets = .zero
    public var edgesAddingLayoutMarginsToBackgroundInsets: NSDirectionalRectEdge = .all
    public var backgroundColor: UIColor?
    public var backgroundColorTransformer: UIConfigurationColorTransformer?
    public var visualEffect: UIVisualEffect?
    public var image: UIImage?
    public var imageContentMode: UIView.ContentMode = .scaleToFill
    public var strokeWidth: CGFloat = 0
    public var strokeColor: UIColor?
    public var strokeColorTransformer: UIConfigurationColorTransformer?
    public var strokeOutset: CGFloat = 0

    public init() {}

    /// MEASURED tableview_grouped / tableview_plain content-configuration
    /// cells, iPhone SE 2x / iOS 26.1: grouped fill is
    /// `secondarySystemGroupedBackground`; plain fill is nil (the table
    /// paints `systemBackground`). Collection list cells reuse those fills
    /// until a list-cell scene names a different one.
    public static func listPlainCell() -> UIBackgroundConfiguration {
        var c = UIBackgroundConfiguration()
        c.backgroundColor = nil
        return c
    }

    public static func listGroupedCell() -> UIBackgroundConfiguration {
        var c = UIBackgroundConfiguration()
        c.backgroundColor = .secondarySystemGroupedBackground
        return c
    }

    public static func listCell() -> UIBackgroundConfiguration {
        listPlainCell()
    }

    public static func listPlainHeaderFooter() -> UIBackgroundConfiguration {
        var c = UIBackgroundConfiguration()
        c.backgroundColor = nil
        return c
    }

    public static func listGroupedHeaderFooter() -> UIBackgroundConfiguration {
        var c = UIBackgroundConfiguration()
        c.backgroundColor = nil
        return c
    }

    public static func listHeader() -> UIBackgroundConfiguration {
        listPlainHeaderFooter()
    }

    public static func listFooter() -> UIBackgroundConfiguration {
        listPlainHeaderFooter()
    }

    public static func listSidebarCell() -> UIBackgroundConfiguration {
        var c = UIBackgroundConfiguration()
        c.backgroundColor = nil
        c.cornerRadius = 10
        return c
    }

    public static func listSidebarHeader() -> UIBackgroundConfiguration {
        listPlainHeaderFooter()
    }

    public static func listAccompaniedSidebarCell() -> UIBackgroundConfiguration {
        listSidebarCell()
    }

    public static func clear() -> UIBackgroundConfiguration {
        var c = UIBackgroundConfiguration()
        c.backgroundColor = .clear
        return c
    }

    public func updated(for state: any UIConfigurationState) -> UIBackgroundConfiguration {
        var next = self
        if let cell = state as? UICellConfigurationState {
            if cell.isSelected || cell.isHighlighted {
                // MEASURED TableEditor t6800 Alpha, iPhone SE 2x / iOS 26.1:
                // selected insetGrouped list cell fill (209, 209, 214) =
                // systemGray4, the same UITableViewCell.selectionColor.
                // Unselected grouped fill is secondarySystemGroupedBackground
                // (white); nil plain fill also becomes selectionColor.
                next.backgroundColor = UITableViewCell.selectionColor
            }
        }
        return next
    }

    public func resolvedBackgroundColor(for tintColor: UIColor) -> UIColor? {
        let base = backgroundColor ?? tintColor
        if let backgroundColorTransformer {
            return backgroundColorTransformer(base)
        }
        return backgroundColor
    }

    public func resolvedStrokeColor(for tintColor: UIColor) -> UIColor? {
        let base = strokeColor ?? tintColor
        if let strokeColorTransformer {
            return strokeColorTransformer(base)
        }
        return strokeColor
    }

    public static func == (lhs: UIBackgroundConfiguration, rhs: UIBackgroundConfiguration) -> Bool {
        lhs.cornerRadius == rhs.cornerRadius
            && lhs.backgroundInsets == rhs.backgroundInsets
            && lhs.edgesAddingLayoutMarginsToBackgroundInsets == rhs.edgesAddingLayoutMarginsToBackgroundInsets
            && lhs.backgroundColor == rhs.backgroundColor
            && lhs.strokeWidth == rhs.strokeWidth
            && lhs.strokeColor == rhs.strokeColor
            && lhs.strokeOutset == rhs.strokeOutset
            && lhs.imageContentMode == rhs.imageContentMode
            && lhs.customView === rhs.customView
            && lhs.image === rhs.image
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(cornerRadius)
        hasher.combine(backgroundInsets.top)
        hasher.combine(backgroundInsets.leading)
        hasher.combine(backgroundInsets.bottom)
        hasher.combine(backgroundInsets.trailing)
        hasher.combine(edgesAddingLayoutMarginsToBackgroundInsets.rawValue)
        hasher.combine(backgroundColor)
        hasher.combine(strokeWidth)
        hasher.combine(strokeColor)
        hasher.combine(strokeOutset)
        hasher.combine(customView.map { ObjectIdentifier($0) })
        hasher.combine(image.map { ObjectIdentifier($0) })
    }
}

@preconcurrency @MainActor
final class _UIBackgroundConfigurationView: UIView {
    var configuration = UIBackgroundConfiguration() {
        didSet { apply() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isUserInteractionEnabled = false
        isOpaque = false
    }

    private func apply() {
        backgroundColor = configuration.backgroundColor
        layer.cornerRadius = configuration.cornerRadius
        if configuration.cornerRadius > 0 { clipsToBounds = true }
        if let custom = configuration.customView, custom.superview !== self {
            addSubview(custom)
        }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        configuration.customView?.frame = bounds
    }
}
