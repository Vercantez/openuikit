// UIListContentConfiguration + UIListContentView. Owner: list-cell cluster.
//
// Text / image packing is the same job UITableViewCell already measured for
// `defaultContentConfiguration()` table rows (53 pt, 16 pt inset, 17 pt body
// + 15 pt secondary). Collection list cells reuse those numbers until a
// list-cell oracle scene names a different frame.

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif

public struct UIListContentConfiguration: UIContentConfiguration {
    public struct TextProperties: Hashable {
        public var font: UIFont = .preferredFont(forTextStyle: .body)
        public var color: UIColor = .label
        public var colorTransformer: UIConfigurationColorTransformer?
        public var alignment: NSTextAlignment = .natural
        public var lineBreakMode: NSLineBreakMode = .byTruncatingTail
        public var numberOfLines: Int = 0
        public var adjustsFontSizeToFitWidth = false
        public var minimumScaleFactor: CGFloat = 0
        public var allowsDefaultTighteningForTruncation = false
        public var adjustsFontForContentSizeCategory = true
        public var transform: TextTransform = .none

        public enum TextTransform: Int, Hashable, Sendable {
            case none = 0
            case uppercase
            case lowercase
            case capitalized
        }

        public func resolvedColor() -> UIColor {
            if let colorTransformer { return colorTransformer(color) }
            return color
        }

        public static func == (lhs: TextProperties, rhs: TextProperties) -> Bool {
            lhs.font.pointSize == rhs.font.pointSize
                && lhs.color == rhs.color
                && lhs.alignment == rhs.alignment
                && lhs.lineBreakMode == rhs.lineBreakMode
                && lhs.numberOfLines == rhs.numberOfLines
                && lhs.adjustsFontSizeToFitWidth == rhs.adjustsFontSizeToFitWidth
                && lhs.minimumScaleFactor == rhs.minimumScaleFactor
                && lhs.allowsDefaultTighteningForTruncation == rhs.allowsDefaultTighteningForTruncation
                && lhs.adjustsFontForContentSizeCategory == rhs.adjustsFontForContentSizeCategory
                && lhs.transform == rhs.transform
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(font.pointSize)
            hasher.combine(color)
            hasher.combine(numberOfLines)
            hasher.combine(transform)
        }
    }

    public struct ImageProperties: Hashable {
        public var preferredSymbolConfiguration: UIImage.SymbolConfiguration?
        public var tintColor: UIColor?
        public var tintColorTransformer: UIConfigurationColorTransformer?
        public var cornerRadius: CGFloat = 0
        public var reservedLayoutSize: CGSize = CGSize(width: -1, height: -1)
        public var maximumSize: CGSize = .zero
        public var accessibilityIgnoresInvertColors = false

        public func resolvedTintColor() -> UIColor? {
            guard let tintColor else { return nil }
            if let tintColorTransformer { return tintColorTransformer(tintColor) }
            return tintColor
        }

        public static func == (lhs: ImageProperties, rhs: ImageProperties) -> Bool {
            lhs.cornerRadius == rhs.cornerRadius
                && lhs.reservedLayoutSize == rhs.reservedLayoutSize
                && lhs.maximumSize == rhs.maximumSize
                && lhs.tintColor == rhs.tintColor
                && lhs.accessibilityIgnoresInvertColors == rhs.accessibilityIgnoresInvertColors
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(cornerRadius)
            hasher.combine(reservedLayoutSize.width)
            hasher.combine(reservedLayoutSize.height)
            hasher.combine(tintColor)
        }
    }

    public var image: UIImage?
    public var imageProperties = ImageProperties()
    public var text: String?
    public var attributedText: NSAttributedString?
    public var textProperties = TextProperties()
    public var secondaryText: String?
    public var secondaryAttributedText: NSAttributedString?
    public var secondaryTextProperties: TextProperties = {
        var p = TextProperties()
        p.font = .preferredFont(forTextStyle: .subheadline)
        p.color = .secondaryLabel
        return p
    }()
    public var axesPreservingSuperviewLayoutMargins: UIAxis = []
    public var directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 16,
                                                                  bottom: 8, trailing: 16)
    public var prefersSideBySideTextAndSecondaryText = false
    public var imageToTextPadding: CGFloat = 12
    public var textToSecondaryTextHorizontalPadding: CGFloat = 8
    public var textToSecondaryTextVerticalPadding: CGFloat = 2

    enum StyleKind: Int, Sendable {
        case cell, subtitleCell, valueCell
        case plainHeader, groupedHeader
        case plainFooter, groupedFooter
        case sidebarCell, sidebarSubtitleCell
        case accompaniedSidebarCell, accompaniedSidebarSubtitleCell
        case prominentInsetGroupedHeader, extraProminentInsetGroupedHeader
    }

    var styleKind: StyleKind = .cell

    public init() {}

    public static func cell() -> UIListContentConfiguration {
        var c = UIListContentConfiguration()
        c.styleKind = .cell
        c.textProperties.numberOfLines = 1
        c.secondaryTextProperties.numberOfLines = 1
        // MEASURED collection_list_plain Echo / Charlie, iPhone SE 2x /
        // iOS 26.1: 52 pt cell, label rel y 16, height 20.5, bottom 15.5
        // (16+20.5+15.5 = 52).
        c.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16,
                                                             bottom: 15.5, trailing: 16)
        return c
    }

    public static func subtitleCell() -> UIListContentConfiguration {
        var c = cell()
        c.styleKind = .subtitleCell
        c.prefersSideBySideTextAndSecondaryText = false
        c.secondaryTextProperties.font = .preferredFont(forTextStyle: .subheadline)
        c.secondaryTextProperties.color = .secondaryLabel
        // MEASURED collection_list_plain Bravo, iPhone SE 2x / iOS 26.1:
        // cell 68.5, primary rel y 15 / 20.5, secondary y 35.5 / 18,
        // bottom 15, vertical gap 0 (15+20.5+18+15 = 68.5).
        c.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 15, leading: 16,
                                                             bottom: 15, trailing: 16)
        c.textToSecondaryTextVerticalPadding = 0
        return c
    }

    public static func valueCell() -> UIListContentConfiguration {
        var c = cell()
        c.styleKind = .valueCell
        c.prefersSideBySideTextAndSecondaryText = true
        c.secondaryTextProperties.font = .preferredFont(forTextStyle: .body)
        c.secondaryTextProperties.color = .secondaryLabel
        c.secondaryTextProperties.alignment = .right
        return c
    }

    public static func plainHeader() -> UIListContentConfiguration {
        var c = UIListContentConfiguration()
        c.styleKind = .plainHeader
        c.textProperties.font = .systemFont(ofSize: 13, weight: .semibold)
        c.textProperties.color = .secondaryLabel
        c.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 16,
                                                             bottom: 6, trailing: 16)
        return c
    }

    public static func groupedHeader() -> UIListContentConfiguration {
        var c = plainHeader()
        c.styleKind = .groupedHeader
        c.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 16,
                                                             bottom: 6, trailing: 16)
        return c
    }

    public static func prominentInsetGroupedHeader() -> UIListContentConfiguration {
        var c = groupedHeader()
        c.styleKind = .prominentInsetGroupedHeader
        c.textProperties.font = .preferredFont(forTextStyle: .title2)
        c.textProperties.color = .label
        return c
    }

    public static func extraProminentInsetGroupedHeader() -> UIListContentConfiguration {
        var c = prominentInsetGroupedHeader()
        c.styleKind = .extraProminentInsetGroupedHeader
        c.textProperties.font = .preferredFont(forTextStyle: .title1)
        return c
    }

    public static func plainFooter() -> UIListContentConfiguration {
        var c = UIListContentConfiguration()
        c.styleKind = .plainFooter
        c.textProperties.font = .systemFont(ofSize: 13)
        c.textProperties.color = .secondaryLabel
        c.textProperties.numberOfLines = 0
        c.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 16,
                                                             bottom: 6, trailing: 16)
        return c
    }

    public static func groupedFooter() -> UIListContentConfiguration {
        var c = plainFooter()
        c.styleKind = .groupedFooter
        return c
    }

    public static func sidebarCell() -> UIListContentConfiguration {
        var c = cell()
        c.styleKind = .sidebarCell
        return c
    }

    public static func sidebarSubtitleCell() -> UIListContentConfiguration {
        var c = subtitleCell()
        c.styleKind = .sidebarSubtitleCell
        return c
    }

    public static func accompaniedSidebarCell() -> UIListContentConfiguration {
        var c = cell()
        c.styleKind = .accompaniedSidebarCell
        return c
    }

    public static func accompaniedSidebarSubtitleCell() -> UIListContentConfiguration {
        var c = subtitleCell()
        c.styleKind = .accompaniedSidebarSubtitleCell
        return c
    }

    public func makeContentView() -> UIView & UIContentView {
        UIListContentView(configuration: self)
    }

    public func updated(for state: any UIConfigurationState) -> UIListContentConfiguration {
        var next = self
        if let cell = state as? UICellConfigurationState, cell.isDisabled {
            next.textProperties.color = .tertiaryLabel
            next.secondaryTextProperties.color = .tertiaryLabel
        }
        return next
    }
}

@preconcurrency @MainActor
open class UIListContentView: UIView, UIContentView {
    private let imageView = UIImageView()
    private let textLabel = UILabel()
    private let secondaryLabel = UILabel()
    private var _configuration: UIListContentConfiguration

    public var configuration: any UIContentConfiguration {
        get { _configuration }
        set {
            if let c = newValue as? UIListContentConfiguration {
                _configuration = c
                apply()
            }
        }
    }

    public var textLayoutGuide: UILayoutGuide { _textLayoutGuide }
    public var secondaryTextLayoutGuide: UILayoutGuide { _secondaryTextLayoutGuide }
    public var imageLayoutGuide: UILayoutGuide { _imageLayoutGuide }

    private let _textLayoutGuide = UILayoutGuide()
    private let _secondaryTextLayoutGuide = UILayoutGuide()
    private let _imageLayoutGuide = UILayoutGuide()

    public init(configuration: UIListContentConfiguration) {
        _configuration = configuration
        super.init(frame: .zero)
        isOpaque = false
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        addSubview(textLabel)
        addSubview(secondaryLabel)
        addLayoutGuide(_textLayoutGuide)
        addLayoutGuide(_secondaryTextLayoutGuide)
        addLayoutGuide(_imageLayoutGuide)
        apply()
    }

    public required init?(coder: NSCoder) {
        _configuration = .cell()
        super.init(coder: coder)
        isOpaque = false
        addSubview(imageView)
        addSubview(textLabel)
        addSubview(secondaryLabel)
        addLayoutGuide(_textLayoutGuide)
        addLayoutGuide(_secondaryTextLayoutGuide)
        addLayoutGuide(_imageLayoutGuide)
        apply()
    }

    public func supports(_ configuration: any UIContentConfiguration) -> Bool {
        configuration is UIListContentConfiguration
    }

    private func apply() {
        let c = _configuration
        imageView.image = c.image
        imageView.tintColor = c.imageProperties.resolvedTintColor()
        imageView.layer.cornerRadius = c.imageProperties.cornerRadius
        imageView.isHidden = c.image == nil
        applyText(c.text, attributed: c.attributedText,
                  properties: c.textProperties, to: textLabel)
        applyText(c.secondaryText, attributed: c.secondaryAttributedText,
                  properties: c.secondaryTextProperties, to: secondaryLabel)
        secondaryLabel.isHidden = (c.secondaryText == nil && c.secondaryAttributedText == nil)
        setNeedsLayout()
    }

    private func applyText(_ text: String?, attributed: NSAttributedString?,
                           properties: UIListContentConfiguration.TextProperties,
                           to label: UILabel) {
        label.font = properties.font
        label.textColor = properties.resolvedColor()
        label.textAlignment = properties.alignment
        label.lineBreakMode = properties.lineBreakMode
        label.numberOfLines = properties.numberOfLines
        label.adjustsFontSizeToFitWidth = properties.adjustsFontSizeToFitWidth
        label.minimumScaleFactor = properties.minimumScaleFactor
        label.allowsDefaultTighteningForTruncation = properties.allowsDefaultTighteningForTruncation
        if let attributed {
            label.attributedText = attributed
        } else if let text {
            switch properties.transform {
            case .none: label.text = text
            case .uppercase: label.text = text.uppercased()
            case .lowercase: label.text = text.lowercased()
            case .capitalized:
                // Avoid String.capitalized (Foundation) so Linux guests
                // without a Foundation import still compile this file.
                var out = ""
                var cap = true
                for ch in text {
                    if ch == " " || ch == "\n" || ch == "\t" {
                        cap = true
                        out.append(ch)
                    } else if cap {
                        out.append(String(ch).uppercased())
                        cap = false
                    } else {
                        out.append(String(ch).lowercased())
                    }
                }
                label.text = out
            }
        } else {
            label.text = nil
            label.attributedText = nil
        }
    }

    open override var intrinsicContentSize: CGSize {
        let height = preferredHeight(forWidth: bounds.width > 1 ? bounds.width : 320)
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }

    func preferredHeight(forWidth width: CGFloat) -> CGFloat {
        let c = _configuration
        let rtl = _layoutIsRTL
        let leading = rtl ? c.directionalLayoutMargins.trailing : c.directionalLayoutMargins.leading
        let trailing = rtl ? c.directionalLayoutMargins.leading : c.directionalLayoutMargins.trailing
        var textWidth = max(0, width - leading - trailing)
        if c.image != nil {
            let img = imageSize()
            textWidth = max(0, textWidth - img.width - c.imageToTextPadding)
        }
        let t = textLabel.sizeThatFits(CGSize(width: textWidth,
                                              height: CGFloat.greatestFiniteMagnitude))
        var h = c.directionalLayoutMargins.top + t.height + c.directionalLayoutMargins.bottom
        if !secondaryLabel.isHidden {
            if c.prefersSideBySideTextAndSecondaryText {
                let s = secondaryLabel.sizeThatFits(
                    CGSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude))
                h = c.directionalLayoutMargins.top
                    + max(t.height, s.height)
                    + c.directionalLayoutMargins.bottom
            } else {
                let s = secondaryLabel.sizeThatFits(
                    CGSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude))
                h += c.textToSecondaryTextVerticalPadding + s.height
            }
        }
        if c.image != nil {
            h = max(h, imageSize().height + c.directionalLayoutMargins.top
                    + c.directionalLayoutMargins.bottom)
        }
        return h
    }

    private func imageSize() -> CGSize {
        let c = _configuration
        if c.imageProperties.reservedLayoutSize.width > 0 {
            return c.imageProperties.reservedLayoutSize
        }
        if let img = c.image { return img.size }
        return .zero
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        let c = _configuration
        let rtl = _layoutIsRTL
        let leadingM = rtl ? c.directionalLayoutMargins.trailing : c.directionalLayoutMargins.leading
        let trailingM = rtl ? c.directionalLayoutMargins.leading : c.directionalLayoutMargins.trailing
        var x = leadingM
        // MEASURED collection_list_plain Alpha, iPhone SE 2x / iOS 26.1:
        // first cell model 70.5 (= 52 + 18.5 headerTopPadding) with the
        // label at y 35, not centered in 70.5. Extra height sits above
        // the packed 52 pt row (16+18.5 = 34.5 ≈ 35).
        let packed = preferredHeight(forWidth: bounds.width)
        let extraTop = max(0, bounds.height - packed)
        let topM = c.directionalLayoutMargins.top + extraTop
        let innerH = max(0, bounds.height - topM - c.directionalLayoutMargins.bottom)
        if !imageView.isHidden {
            let img = imageSize()
            let iy = topM + (innerH - img.height) / 2
            imageView.frame = CGRect(x: x, y: iy, width: img.width, height: img.height)
            x += img.width + c.imageToTextPadding
        }
        let textMax = max(0, bounds.width - x - trailingM)
        if c.prefersSideBySideTextAndSecondaryText, !secondaryLabel.isHidden {
            let primary = textLabel.sizeThatFits(
                CGSize(width: textMax, height: CGFloat.greatestFiniteMagnitude))
            let secondary = secondaryLabel.sizeThatFits(
                CGSize(width: textMax, height: CGFloat.greatestFiniteMagnitude))
            let gap = c.textToSecondaryTextHorizontalPadding
            let secondaryW = min(secondary.width, textMax * 0.5)
            let primaryW = max(0, textMax - secondaryW - gap)
            let py = topM + (innerH - primary.height) / 2
            let sy = topM + (innerH - secondary.height) / 2
            if rtl {
                secondaryLabel.frame = CGRect(x: x, y: sy, width: secondaryW, height: secondary.height)
                textLabel.frame = CGRect(x: x + secondaryW + gap, y: py,
                                         width: min(primaryW, primary.width), height: primary.height)
            } else {
                textLabel.frame = CGRect(x: x, y: py,
                                         width: min(primaryW, primary.width), height: primary.height)
                secondaryLabel.frame = CGRect(x: x + primaryW + gap, y: sy,
                                              width: secondaryW, height: secondary.height)
            }
        } else {
            let primary = textLabel.sizeThatFits(
                CGSize(width: textMax, height: CGFloat.greatestFiniteMagnitude))
            var y = topM
            if secondaryLabel.isHidden {
                y = topM + (innerH - primary.height) / 2
            }
            textLabel.frame = CGRect(x: x, y: y,
                                     width: min(textMax, primary.width),
                                     height: primary.height)
            if !secondaryLabel.isHidden {
                let secondary = secondaryLabel.sizeThatFits(
                    CGSize(width: textMax, height: CGFloat.greatestFiniteMagnitude))
                secondaryLabel.frame = CGRect(x: x,
                                              y: textLabel.frame.maxY + c.textToSecondaryTextVerticalPadding,
                                              width: min(textMax, secondary.width),
                                              height: secondary.height)
            }
        }
        _textLayoutGuide._solvedFrame = textLabel.frame
        _secondaryTextLayoutGuide._solvedFrame = secondaryLabel.frame
        _imageLayoutGuide._solvedFrame = imageView.frame
    }
}
