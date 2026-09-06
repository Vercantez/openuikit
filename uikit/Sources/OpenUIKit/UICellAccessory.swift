// UICellAccessory. Owner: list-cell cluster (disclosure, checkmark, reorder,
// delete, insert, multiselect, outlineDisclosure, label, customView).
//
// Glyph sizes seed from the measured UITableViewCell accessories (chevron
// 10.5×14 at trailing 16, checkmark 19×18 at trailing 18.5, edit disc 22 in
// a 26 box, reorder 27×15). Collection list accessories are replaced with
// list-cell oracle numbers once those scenes land.

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif

public struct UICellAccessory: Hashable {
    public enum DisplayedState: Int, Hashable, Sendable {
        case always = 0
        case whenEditing
        case whenNotEditing
    }

    public struct Position: Hashable, Sendable {
        public var index: Int
        public var offset: Int
        public init(index: Int = 0, offset: Int = 0) {
            self.index = index
            self.offset = offset
        }
    }

    public enum Placement: Hashable {
        case leading(displayed: DisplayedState, at: Position)
        case trailing(displayed: DisplayedState, at: Position)
    }

    public struct LayoutDimension: Hashable, Sendable {
        var value: CGFloat
        var usesStandard: Bool

        public static var standard: LayoutDimension {
            LayoutDimension(value: 0, usesStandard: true)
        }
        public static func actual(_ actual: CGFloat) -> LayoutDimension {
            LayoutDimension(value: actual, usesStandard: false)
        }
        public static func custom(_ custom: CGFloat) -> LayoutDimension {
            LayoutDimension(value: custom, usesStandard: false)
        }
    }

    public struct DisclosureIndicatorOptions: Hashable, Sendable {
        public var reservedLayoutWidth: LayoutDimension
        public var tintColor: UIColor?
        public init(reservedLayoutWidth: LayoutDimension = .standard,
                    tintColor: UIColor? = nil) {
            self.reservedLayoutWidth = reservedLayoutWidth
            self.tintColor = tintColor
        }
    }

    public struct CustomViewConfiguration {
        public var customView: UIView
        public var placement: Placement
        public var isHidden: Bool
        public var reservedLayoutWidth: LayoutDimension
        public var tintColor: UIColor?
        public var maintainsFixedSize: Bool

        public init(customView: UIView,
                    placement: Placement,
                    isHidden: Bool = false,
                    reservedLayoutWidth: LayoutDimension = .standard,
                    tintColor: UIColor? = nil,
                    maintainsFixedSize: Bool = false) {
            self.customView = customView
            self.placement = placement
            self.isHidden = isHidden
            self.reservedLayoutWidth = reservedLayoutWidth
            self.tintColor = tintColor
            self.maintainsFixedSize = maintainsFixedSize
        }
    }

    public struct OutlineDisclosureOptions: Hashable, Sendable {
        public enum Style: Int, Hashable, Sendable {
            case automatic = 0
            case header
            case cell
        }
        public var style: Style
        public var isHidden: Bool
        public var reservedLayoutWidth: LayoutDimension
        public var tintColor: UIColor?
        public init(style: Style = .automatic,
                    isHidden: Bool = false,
                    reservedLayoutWidth: LayoutDimension = .standard,
                    tintColor: UIColor? = nil) {
            self.style = style
            self.isHidden = isHidden
            self.reservedLayoutWidth = reservedLayoutWidth
            self.tintColor = tintColor
        }
    }

    public struct LabelOptions: Hashable {
        public var font: UIFont?
        public var reservedLayoutWidth: LayoutDimension
        public var tintColor: UIColor?
        public var adjustsFontForContentSizeCategory: Bool
        public init(font: UIFont? = nil,
                    reservedLayoutWidth: LayoutDimension = .standard,
                    tintColor: UIColor? = nil,
                    adjustsFontForContentSizeCategory: Bool = true) {
            self.font = font
            self.reservedLayoutWidth = reservedLayoutWidth
            self.tintColor = tintColor
            self.adjustsFontForContentSizeCategory = adjustsFontForContentSizeCategory
        }
    }

    enum Kind: Hashable {
        case disclosure
        case checkmark
        case delete
        case insert
        case reorder
        case multiselect
        case outlineDisclosure
        case label(String)
        case customView
        case popUpMenu
    }

    var kind: Kind
    var displayed: DisplayedState
    var placement: Placement
    var reservedLayoutWidth: LayoutDimension
    var tintColor: UIColor?
    var backgroundColor: UIColor?
    var actionHandler: (() -> Void)?
    var customView: UIView?
    var labelText: String?
    var outlineOptions: OutlineDisclosureOptions?
    var maintainsFixedSize = false
    var isHiddenFlag = false

    init(kind: Kind,
         displayed: DisplayedState,
         placement: Placement,
         reservedLayoutWidth: LayoutDimension,
         tintColor: UIColor?) {
        self.kind = kind
        self.displayed = displayed
        self.placement = placement
        self.reservedLayoutWidth = reservedLayoutWidth
        self.tintColor = tintColor
    }

    public static func == (lhs: UICellAccessory, rhs: UICellAccessory) -> Bool {
        lhs.kind == rhs.kind
            && lhs.displayed == rhs.displayed
            && lhs.placement == rhs.placement
            && lhs.reservedLayoutWidth == rhs.reservedLayoutWidth
            && lhs.tintColor == rhs.tintColor
            && lhs.labelText == rhs.labelText
            && lhs.customView === rhs.customView
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(kind)
        hasher.combine(displayed)
        hasher.combine(reservedLayoutWidth)
        hasher.combine(tintColor)
        hasher.combine(labelText)
        hasher.combine(customView.map { ObjectIdentifier($0) })
    }

    public static func disclosureIndicator(
        displayed: DisplayedState = .always,
        reservedLayoutWidth: LayoutDimension = .standard,
        tintColor: UIColor? = nil,
        options: DisclosureIndicatorOptions = DisclosureIndicatorOptions()
    ) -> UICellAccessory {
        var a = UICellAccessory(kind: .disclosure,
                                displayed: displayed,
                                placement: .trailing(displayed: displayed, at: Position()),
                                reservedLayoutWidth: reservedLayoutWidth,
                                tintColor: tintColor ?? options.tintColor)
        if options.reservedLayoutWidth.usesStandard == false {
            a.reservedLayoutWidth = options.reservedLayoutWidth
        }
        return a
    }

    public static func checkmark(
        displayed: DisplayedState = .always,
        reservedLayoutWidth: LayoutDimension = .standard,
        tintColor: UIColor? = nil
    ) -> UICellAccessory {
        UICellAccessory(kind: .checkmark,
                        displayed: displayed,
                        placement: .trailing(displayed: displayed, at: Position()),
                        reservedLayoutWidth: reservedLayoutWidth,
                        tintColor: tintColor)
    }

    public static func delete(
        displayed: DisplayedState = .whenEditing,
        reservedLayoutWidth: LayoutDimension = .standard,
        tintColor: UIColor? = nil,
        backgroundColor: UIColor? = nil,
        actionHandler: (() -> Void)? = nil
    ) -> UICellAccessory {
        var a = UICellAccessory(kind: .delete,
                                displayed: displayed,
                                placement: .leading(displayed: displayed, at: Position()),
                                reservedLayoutWidth: reservedLayoutWidth,
                                tintColor: tintColor)
        a.backgroundColor = backgroundColor
        a.actionHandler = actionHandler
        return a
    }

    public static func insert(
        displayed: DisplayedState = .whenEditing,
        reservedLayoutWidth: LayoutDimension = .standard,
        tintColor: UIColor? = nil,
        backgroundColor: UIColor? = nil,
        actionHandler: (() -> Void)? = nil
    ) -> UICellAccessory {
        var a = UICellAccessory(kind: .insert,
                                displayed: displayed,
                                placement: .leading(displayed: displayed, at: Position()),
                                reservedLayoutWidth: reservedLayoutWidth,
                                tintColor: tintColor)
        a.backgroundColor = backgroundColor
        a.actionHandler = actionHandler
        return a
    }

    public static func reorder(
        displayed: DisplayedState = .whenEditing,
        reservedLayoutWidth: LayoutDimension = .standard,
        tintColor: UIColor? = nil
    ) -> UICellAccessory {
        UICellAccessory(kind: .reorder,
                        displayed: displayed,
                        placement: .trailing(displayed: displayed, at: Position()),
                        reservedLayoutWidth: reservedLayoutWidth,
                        tintColor: tintColor)
    }

    public static func multiselect(
        displayed: DisplayedState = .whenEditing,
        reservedLayoutWidth: LayoutDimension = .standard,
        tintColor: UIColor? = nil
    ) -> UICellAccessory {
        UICellAccessory(kind: .multiselect,
                        displayed: displayed,
                        placement: .leading(displayed: displayed, at: Position()),
                        reservedLayoutWidth: reservedLayoutWidth,
                        tintColor: tintColor)
    }

    public static func outlineDisclosure(
        displayed: DisplayedState = .always,
        options: OutlineDisclosureOptions = OutlineDisclosureOptions(),
        actionHandler: (() -> Void)? = nil
    ) -> UICellAccessory {
        // MEASURED collection_list_accessories Outline, iPhone SE 2x /
        // iOS 26.1: `_UICollectionViewListAccessoryDisclosure` 44×44 at
        // x 330 (trailing), chevron UIImageView 10.5×14 at x 347. Default
        // placement is trailing so the 14×14 disclosure box sits at
        // trailing 16 (same ink as Disclosure).
        var a = UICellAccessory(kind: .outlineDisclosure,
                                displayed: displayed,
                                placement: .trailing(displayed: displayed, at: Position()),
                                reservedLayoutWidth: options.reservedLayoutWidth,
                                tintColor: options.tintColor)
        a.outlineOptions = options
        a.actionHandler = actionHandler
        a.isHiddenFlag = options.isHidden
        return a
    }

    public static func label(
        text: String,
        displayed: DisplayedState = .always,
        options: LabelOptions = LabelOptions()
    ) -> UICellAccessory {
        var a = UICellAccessory(kind: .label(text),
                                displayed: displayed,
                                placement: .trailing(displayed: displayed, at: Position()),
                                reservedLayoutWidth: options.reservedLayoutWidth,
                                tintColor: options.tintColor)
        a.labelText = text
        return a
    }

    public static func customView(configuration: CustomViewConfiguration) -> UICellAccessory {
        var a = UICellAccessory(kind: .customView,
                                displayed: configuration.displayedState,
                                placement: configuration.placement,
                                reservedLayoutWidth: configuration.reservedLayoutWidth,
                                tintColor: configuration.tintColor)
        a.customView = configuration.customView
        a.maintainsFixedSize = configuration.maintainsFixedSize
        a.isHiddenFlag = configuration.isHidden
        return a
    }

    public static func popUpMenu(
        _ menu: UIMenu,
        displayed: DisplayedState = .always,
        reservedLayoutWidth: LayoutDimension = .standard,
        tintColor: UIColor? = nil
    ) -> UICellAccessory {
        UICellAccessory(kind: .popUpMenu,
                        displayed: displayed,
                        placement: .trailing(displayed: displayed, at: Position()),
                        reservedLayoutWidth: reservedLayoutWidth,
                        tintColor: tintColor)
    }

    var isLeading: Bool {
        if case .leading = placement { return true }
        return false
    }

    func isVisible(isEditing: Bool) -> Bool {
        if isHiddenFlag { return false }
        switch displayed {
        case .always: return true
        case .whenEditing: return isEditing
        case .whenNotEditing: return !isEditing
        }
    }

    /// Standard reserved width. MEASURED UITableViewCell accessories,
    /// iPhone SE 2x / iOS 26.1: disclosure 10.5, checkmark 19, edit 26,
    /// reorder 27. List-cell oracle scenes replace these if they differ.
    func standardWidth() -> CGFloat {
        if !reservedLayoutWidth.usesStandard { return reservedLayoutWidth.value }
        switch kind {
        case .disclosure: return UITableViewCell.disclosureSize.width
        case .checkmark: return UITableViewCell.checkmarkSize.width
        case .delete, .insert, .multiselect: return 26
        case .reorder: return UITableViewCell.reorderWidth
        case .outlineDisclosure: return UITableViewCell.disclosureSize.width
        case .label: return 0
        case .customView:
            return customView?.bounds.width ?? customView?.intrinsicContentSize.width ?? 0
        case .popUpMenu: return 24
        }
    }
}

extension UICellAccessory.CustomViewConfiguration {
    var displayedState: UICellAccessory.DisplayedState {
        switch placement {
        case .leading(let displayed, _): return displayed
        case .trailing(let displayed, _): return displayed
        }
    }
}

extension UICellAccessory.Placement {
    public static var leading: UICellAccessory.Placement {
        .leading(displayed: .always, at: UICellAccessory.Position())
    }
    public static var trailing: UICellAccessory.Placement {
        .trailing(displayed: .always, at: UICellAccessory.Position())
    }
}
