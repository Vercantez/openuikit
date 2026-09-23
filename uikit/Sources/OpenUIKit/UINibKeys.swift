// UINib archived keys -> UIKit object state. Owner: app-compat module.
//
// The key names and value encodings are read off `ibtool --compile` output
// (Tools/nib/nibdump.py prints any archive), field by field against the XML
// that produced it: the Pocket Casts cells (fixtures/realapp/nibs), the probe
// storyboard (Tools/oracle2/nibruntimeprobe/NibRuntimeProbe.storyboard) and
// Eidolon's two storyboards and keypad xib (fixtures/realapp/eidolon/nibs).
// What the keys DO is measured against iOS 26.1 loading the same compiled
// bytes (fixtures/nibruntime/oracle); a key with no such measurement is left
// in `UINib.unhandledKeys` rather than guessed.

#if canImport(Foundation)
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif

extension NibDecoder {
    // MARK: Applying archived keys

    func apply(_ object: NibArchive.Object, to target: AnyObject) {
        if let view = target as? UIView {
            applyView(object, to: view)
        } else if let flow = target as? UICollectionViewFlowLayout {
            applyFlowLayout(object, to: flow)
        }
    }

    /// A storyboard flow layout's archived sizes (IB's `collectionViewFlowLayout`).
    func applyFlowLayout(_ object: NibArchive.Object, to flow: UICollectionViewFlowLayout) {
        for pair in object.values {
            switch pair.key {
            case "UIItemSize":
                if let n = numbers(pair.value, count: 2) { flow.itemSize = CGSize(width: n[0], height: n[1]) }
            case "UIHeaderReferenceSize":
                if let n = numbers(pair.value, count: 2) { flow.headerReferenceSize = CGSize(width: n[0], height: n[1]) }
            case "UIFooterReferenceSize":
                if let n = numbers(pair.value, count: 2) { flow.footerReferenceSize = CGSize(width: n[0], height: n[1]) }
            case "UISectionInset":
                if let n = numbers(pair.value, count: 4) {
                    flow.sectionInset = UIEdgeInsets(top: n[0], left: n[1], bottom: n[2], right: n[3])
                }
            case "UIMinimumLineSpacing":
                if let v = cgFloat(pair.value) { flow.minimumLineSpacing = v }
            case "UIMinimumInteritemSpacing":
                if let v = cgFloat(pair.value) { flow.minimumInteritemSpacing = v }
            default:
                UINib.noteUnhandled("UICollectionViewFlowLayout.\(pair.key)")
            }
        }
    }

    /// UIKit's `UIViewContentMode` raw values (UIView.h), which the port's
    /// `UIViewContentMode` spells as cases without raw values.
    static let archivedContentModes: [UIViewContentMode] = [
        .scaleToFill, .scaleAspectFit, .scaleAspectFill, .redraw, .center,
        .top, .bottom, .left, .right, .topLeft, .topRight, .bottomLeft,
        .bottomRight,
    ]
    /// `NSTextAlignment` raw values on iOS (left = 0, centre = 1, right = 2,
    /// justified = 3, natural = 4).
    static let archivedAlignments: [NSTextAlignment] = [
        .left, .center, .right, .justified, .natural,
    ]
    /// `NSLineBreakMode` raw values.
    static let archivedLineBreaks: [NSLineBreakMode] = [
        .byWordWrapping, .byCharWrapping, .byClipping,
        .byTruncatingHead, .byTruncatingTail, .byTruncatingMiddle,
    ]

    /// The archived state of one view. `scalarsOnly` re-applies just the
    /// property keys — no subviews, constraints or content-view binding —
    /// for a framework class whose own `init(coder:)` resets properties
    /// after `super.init(coder:)` returned (UILabel's defaults, UIButton's
    /// title font): see `UINibCoder.reapplyFrameworkState`.
    func applyView(_ object: NibArchive.Object, to view: UIView, scalarsOnly: Bool = false) {
        // Bounds + centre, UIKit's archived spelling of `frame`. Applied
        // FIRST so a subview's autoresizing starts from the right size.
        if !scalarsOnly, let bounds = numbers(object.first("UIBounds"), count: 4) {
            if let center = numbers(object.first("UICenter"), count: 2) {
                view.frame = CGRect(x: center[0] - bounds[2] / 2,
                                    y: center[1] - bounds[3] / 2,
                                    width: bounds[2], height: bounds[3])
            } else {
                view.frame = CGRect(x: 0, y: 0, width: bounds[2], height: bounds[3])
            }
        }

        // A UITableViewCell's `contentView` is `let` in the port (and is the
        // view its layoutSubviews positions), so the archived content view is
        // BOUND to the live one before anything else can construct a second
        // one: every constraint that names the archived index then resolves to
        // the view that is really in the hierarchy. UIKit reaches the same
        // shape through `-setContentView:` while decoding.
        var boundContentView = false
        if !scalarsOnly, let cell = view as? UITableViewCell,
           case .reference(let contentIndex)? = object.first("UIContentView"),
           contentIndex >= 0, contentIndex < archive.objects.count {
            built[contentIndex] = cell.contentView
            applyView(archive.objects[contentIndex], to: cell.contentView)
            awakened.append(cell.contentView)
            // The nib's cell has no textLabel/imageView (`UITextLabel` and
            // `UIImageView` decode as nil); the port creates them eagerly in
            // `init(style:)`, so take them out of the hierarchy or they show
            // up as two extra views in every layout dump.
            cell.textLabel?.removeFromSuperview()
            cell.imageView?.removeFromSuperview()
            boundContentView = true
        }
        // A storyboard collection-view cell archives its content view under
        // the same key (NetNewsWire's FeedCell prototype: `UIContentView`
        // holds the title, count and icon with their constraints). Bound to
        // the cell's own `contentView`, as above; before, the archived view
        // was built as an unrelated second subview, the real content view
        // stayed empty and Auto Layout self-sizing had nothing to measure.
        if !scalarsOnly, !boundContentView, let cell = view as? UICollectionViewCell,
           case .reference(let contentIndex)? = object.first("UIContentView"),
           contentIndex >= 0, contentIndex < archive.objects.count {
            built[contentIndex] = cell.contentView
            applyView(archive.objects[contentIndex], to: cell.contentView)
            awakened.append(cell.contentView)
            boundContentView = true
        }

        // `-[UIView initWithCoder:]` sets userInteractionEnabled from the
        // ABSENCE of `UIUserInteractionDisabled`: MEASURED (eidolonnibs
        // oracle) five archived image views with no such key report true on
        // iOS 26.1, although a programmatic UIImageView reports false.
        if object.first("UIUserInteractionDisabled") == nil {
            view.isUserInteractionEnabled = true
        }

        for pair in object.values {
            switch pair.key {
            case "UIBounds", "UICenter",
                 // Class-swap bookkeeping, read by `makeSwapped`.
                 "UIClassName", "UIOriginalClassName",
                 // Archived state the port models elsewhere, or that has no
                 // effect on a rendered frame. Listed so the silence is a
                 // decision rather than an omission.
                 "UIDeepDrawRect", "UIViewSemanticContentAttribute",
                 "UIViewLargeContentStoredProperties", "UISystemBackgroundView",
                 "UIContentConfigurationView", "UITextLabel", "UIDetailTextLabel",
                 "UIImageView", "UIPrefetchingEnabled", "UIFillerRowHeight",
                 "UIInsetsContentViewsToSafeArea",
                 "UIScrollViewIndicatorInsetAdjustmentBehavior",
                 "UIScrollViewContentInsetAdjustmentBehavior",
                 "UIShadowOffset", "UIHighlightedColor", "UIBaselineAdjustment",
                 "UIAutoresizeSubviews", "UISelectionStyle", "UIIndentationWidth",
                 "UIDisableUpdateTextColorOnTraitCollectionChange",
                 "UIDisableTextColorUpdateOnTraitCollectionChange",
                 "UIStyle", "UISeparatorStyleIOS5AndLater", "UIBouncesZoom",
                 "UIMultipleTouchEnabled", "UIClearsContextBeforeDrawing",
                 "UISectionHeaderTopPadding",
                 "UIAdjustsFontSizeToFit", "UIEnabled",
                 // A layout guide view's bookkeeping (see _UILayoutGuide).
                 "_UILayoutGuideIdentifier", "_UILayoutGuideConstraintsToRemove",
                 // Pointer / text-input niceties with no rendered effect.
                 "UIPointerInteractionEnabled", "UIBehavioralStyle":
                continue

            case "UIAutoresizingMask":
                if let raw = int(pair.value) {
                    view.autoresizingMask = UIView.AutoresizingMask(rawValue: UInt(raw))
                }
            case "UIClipsToBounds":
                // MEASURED: all 19 archived UITextFields in Eidolon's
                // storyboards carry UIClipsToBounds = true and report false
                // on iOS 26.1 (a programmatic field reports false, and true
                // after `clipsToBounds = true`) — the text field's decode
                // does not keep it.
                if view is UITextField { continue }
                if let flag = bool(pair.value) { view.clipsToBounds = flag }
            case "UIOpaque":
                if let flag = bool(pair.value) { view.isOpaque = flag }
            case "UIHidden":
                if let flag = bool(pair.value) { view.isHidden = flag }
            case "UIAlpha":
                if let alpha = cgFloat(pair.value) { view.alpha = alpha }
            case "UITag":
                if let tag = int(pair.value) { view.tag = tag }
            case "UIUserInteractionDisabled":
                if let flag = bool(pair.value) { view.isUserInteractionEnabled = !flag }
            case "UIBackgroundColor":
                if case .reference(let i) = pair.value {
                    view.backgroundColor = build(i) as? UIColor
                }
            case "UITintColor":
                if case .reference(let i) = pair.value, let color = build(i) as? UIColor {
                    view.tintColor = color
                }
            case "UIViewDoesNotTranslateAutoresizingMaskIntoConstraints":
                if let flag = bool(pair.value) {
                    view.translatesAutoresizingMaskIntoConstraints = !flag
                }
            case "UIViewContentHuggingPriority":
                if let (h, v) = priorityPair(pair.value) {
                    view.setContentHuggingPriority(UILayoutPriority(Float(h)), for: .horizontal)
                    view.setContentHuggingPriority(UILayoutPriority(Float(v)), for: .vertical)
                }
            case "UIViewContentCompressionResistancePriority":
                if let (h, v) = priorityPair(pair.value) {
                    view.setContentCompressionResistancePriority(
                        UILayoutPriority(Float(h)), for: .horizontal)
                    view.setContentCompressionResistancePriority(
                        UILayoutPriority(Float(v)), for: .vertical)
                }
            case "UIViewAutolayoutConstraints":
                guard !scalarsOnly, case .reference(let i) = pair.value else { continue }
                for element in arrayElements(at: i) {
                    if let constraint = element as? NSLayoutConstraint {
                        deferredConstraints.append(constraint)
                    }
                }
            case "UISubviews":
                guard !scalarsOnly, !boundContentView, case .reference(let i) = pair.value else { continue }
                // A segmented control archives its private segment views;
                // the port's control draws its own (its segments come from
                // `UISegments`), so they are not added.
                if view is UISegmentedControl { continue }
                for element in arrayElements(at: i) {
                    if let sub = element as? UIView, sub.superview !== view { view.addSubview(sub) }
                }
            case "UIContentView":
                continue
            case "UIContentMode":
                if let raw = int(pair.value),
                   raw >= 0, raw < NibDecoder.archivedContentModes.count {
                    view.contentMode = NibDecoder.archivedContentModes[raw]
                }
            case "UIViewLayoutMargins":
                if let m = numbers(pair.value, count: 4) {
                    view.layoutMargins = UIEdgeInsets(top: m[0], left: m[1], bottom: m[2], right: m[3])
                }
            case "UIViewLayoutMarginsAreDirectional", "UIViewPreservesSuperviewMargins",
                 "UIViewEdgesPreservingSuperviewLayoutMargins",
                 "UIViewInsetsLayoutMarginsFromSafeArea":
                continue
            default:
                applySpecific(pair, to: view)
            }
        }
    }

    /// Per-class archived keys.
    func applySpecific(_ pair: (key: String, value: NibArchive.Value), to view: UIView) {
        if let label = view as? UILabel {
            switch pair.key {
            case "UIText":
                if let text = string(pair.value) { label.text = text }
                return
            case "UIAttributedText":
                if let text = string(pair.value) { label.text = text }
                return
            case "UIFont":
                if case .reference(let i) = pair.value,
                   let box = build(i) as? NibFontBox { label.font = box.font }
                return
            case "UITextColor":
                if case .reference(let i) = pair.value,
                   let color = build(i) as? UIColor { label.textColor = color }
                return
            case "UINumberOfLines":
                if let n = int(pair.value) { label.numberOfLines = n }
                return
            case "UITextAlignment":
                if let raw = int(pair.value),
                   raw >= 0, raw < NibDecoder.archivedAlignments.count {
                    label.textAlignment = NibDecoder.archivedAlignments[raw]
                }
                return
            case "UILineBreakMode":
                if let raw = int(pair.value),
                   raw >= 0, raw < NibDecoder.archivedLineBreaks.count {
                    label.lineBreakMode = NibDecoder.archivedLineBreaks[raw]
                }
                return
            case "UIAdjustsFontForContentSizeCategory":
                if let flag = bool(pair.value) {
                    label.adjustsFontForContentSizeCategory = flag
                }
                return
            case "UIMinimumScaleFactor":
                if let factor = cgFloat(pair.value) { label.minimumScaleFactor = factor }
                return
            case "UIMinimumFontSize", "UIAdjustsLetterSpacingToFit":
                return
            default: break
            }
        }
        if let imageView = view as? UIImageView {
            if pair.key == "UIImage" {
                if case .reference(let i) = pair.value {
                    imageView.image = build(i) as? UIImage
                }
                return
            }
        }
        if let button = view as? UIButton {
            switch pair.key {
            case "UIButtonStatefulContent":
                guard case .reference(let i) = pair.value else { return }
                for (key, value) in dictionaryPairs(at: i) {
                    guard let number = key as? NibNumberBox,
                          let content = value as? NibButtonContentBox else { continue }
                    let state = UIControl.State(rawValue: UInt(number.value))
                    if let title = content.title { button.setTitle(title, for: state) }
                    if let color = content.titleColor { button.setTitleColor(color, for: state) }
                    if let image = content.image { button.setImage(image, for: state) }
                    if content.backgroundImage != nil {
                        UINib.noteUnhandled("UIButton.backgroundImage")
                    }
                }
                return
            case "UIFont":
                if case .reference(let i) = pair.value,
                   let box = build(i) as? NibFontBox { button.titleLabel?.font = box.font }
                return
            case "UIContentEdgeInsets":
                if let m = numbers(pair.value, count: 4) {
                    button._contentEdgeInsets = UIEdgeInsets(top: m[0], left: m[1], bottom: m[2], right: m[3])
                }
                return
            case "UIButtonType", "UIAdjustsImageWhenHighlighted", "UIAdjustsImageWhenDisabled",
                 "UIButtonConfiguration", "UIReversesTitleShadowWhenHighlighted",
                 "UIShowsTouchWhenHighlighted":
                // The type is chosen at construction; the rest is highlight
                // styling with no rest-state effect.
                return
            default: break
            }
        }
        if let control = view as? UIControl {
            switch pair.key {
            case "UIContentHorizontalAlignment":
                if let raw = int(pair.value),
                   let alignment = UIControl.ContentHorizontalAlignment(rawValue: raw) {
                    control.contentHorizontalAlignment = alignment
                }
                return
            case "UIContentVerticalAlignment":
                if let raw = int(pair.value),
                   let alignment = UIControl.ContentVerticalAlignment(rawValue: raw) {
                    control.contentVerticalAlignment = alignment
                }
                return
            case "UIContentVerticalAlignment2":
                return
            case "UIDisabled":
                if let flag = bool(pair.value) { control.isEnabled = !flag }
                return
            case "UISelected":
                if let flag = bool(pair.value) { control.isSelected = flag }
                return
            case "UIHighlighted":
                if let flag = bool(pair.value) { control.isHighlighted = flag }
                return
            default: break
            }
        }
        if let field = view as? UITextField {
            switch pair.key {
            case "UIText":
                if let text = string(pair.value) { field.text = text }
                return
            case "UIPlaceholder":
                if let text = string(pair.value) { field.placeholder = text }
                return
            case "UIFont":
                if case .reference(let i) = pair.value,
                   let box = build(i) as? NibFontBox { field.font = box.font }
                return
            case "UITextColor":
                if case .reference(let i) = pair.value,
                   let color = build(i) as? UIColor { field.textColor = color }
                return
            case "UIBorderStyle":
                if let raw = int(pair.value), let style = UITextField.BorderStyle(rawValue: raw) {
                    field.borderStyle = style
                }
                return
            case "UIMinimumFontSize", "UIClearButtonOffset", "UIRoundedRectBackgroundCornerRadius",
                 "UIAutocorrectionType", "UIKeyboardType", "UIReturnKeyType",
                 "UISpellCheckingType", "UIAutocapitalizationType", "UISecureTextEntry",
                 "UITextContentType", "UIClearButtonMode":
                // Keyboard traits and edit-time chrome: no rest-state pixels.
                return
            default: break
            }
        }
        if let textView = view as? UITextView {
            switch pair.key {
            case "UIText":
                if let text = string(pair.value) { textView.text = text }
                return
            case "UIAttributedText":
                if let text = string(pair.value) { textView.text = text }
                return
            case "UIFont":
                if case .reference(let i) = pair.value,
                   let box = build(i) as? NibFontBox { textView.font = box.font }
                return
            case "UITextColor":
                if case .reference(let i) = pair.value,
                   let color = build(i) as? UIColor { textView.textColor = color }
                return
            case "UIEditable":
                if let flag = bool(pair.value) { textView.isEditable = flag }
                return
            case "UISelectable":
                if let flag = bool(pair.value) { textView.isSelectable = flag }
                return
            case "UITextAlignment", "UIContentSize", "UITextAllowsNumberPadPopover",
                 "UITextHighlightAttributes", "UIDataDetectorTypes":
                return
            default: break
            }
        }
        if let collection = view as? UICollectionView {
            switch pair.key {
            case "UICollectionLayout":
                if case .reference(let i) = pair.value, let layout = build(i) as? UICollectionViewLayout {
                    collection.collectionViewLayout = layout
                }
                return
            case "UICollectionViewCellPrototypeNibExternalObjects",
                 "UICollectionViewSupplementaryViewPrototypeNibExternalObjects":
                // Empty for every storyboard prototype measured (NetNewsWire).
                guard case .reference(let i) = pair.value else { return }
                for (_, value) in dictionaryPairs(at: i) {
                    if let table = value as? NibDictionaryBox, !dictionaryPairs(at: table.index).isEmpty {
                        UINib.noteUnhandled("UICollectionView.prototypeExternalObjects")
                    }
                }
                return
            case "UICollectionViewPrefetchingEnabled", "UIAllowsUserInitiatedMultipleSelection":
                // No rendered effect (the port does not prefetch; selection
                // gestures are host-driven).
                return
            case "UICollectionViewCellNibDict":
                // A storyboard collection view's prototype cells: reuse
                // identifier -> embedded nib (NetNewsWire Main.storyboard
                // "FeedCell" / "Folder").
                guard case .reference(let i) = pair.value else { return }
                for (key, value) in dictionaryPairs(at: i) {
                    if let identifier = key as? NibString, let nib = value as? UINib {
                        collection.register(nib, forCellWithReuseIdentifier: identifier.value)
                    }
                }
                return
            case "UICollectionViewSupplementaryViewNibDict":
                // "<kind>/<reuse identifier>" -> embedded nib
                // ("UICollectionElementKindSectionHeader/Container").
                guard case .reference(let i) = pair.value else { return }
                for (key, value) in dictionaryPairs(at: i) {
                    guard let composite = key as? NibString, let nib = value as? UINib,
                          let slash = composite.value.firstIndex(of: "/") else { continue }
                    let kind = String(composite.value[..<slash])
                    let identifier = String(composite.value[composite.value.index(after: slash)...])
                    collection.register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
                }
                return
            default: break
            }
        }
        if let table = view as? UITableView {
            switch pair.key {
            case "UITableViewCellPrototypeNibs":
                // A storyboard table's prototype cells: reuse identifier ->
                // embedded nib, registered as `register(_:forCellReuseIdentifier:)`
                // does (MEASURED: `dequeueReusableCell(withIdentifier:)`
                // returns the prototype's custom class with its outlet set
                // and awakeFromNib run).
                guard case .reference(let i) = pair.value else { return }
                for (key, value) in dictionaryPairs(at: i) {
                    if let identifier = key as? NibString, let nib = value as? UINib {
                        table.register(nib, forCellReuseIdentifier: identifier.value)
                    }
                }
                return
            case "UITableViewCellPrototypeNibExternalObjects":
                guard case .reference(let i) = pair.value else { return }
                for (_, value) in dictionaryPairs(at: i) {
                    if let table = value as? NibDictionaryBox, !dictionaryPairs(at: table.index).isEmpty {
                        UINib.noteUnhandled("UITableView.prototypeExternalObjects")
                    }
                }
                return
            case "UITableViewStyle":
                // UIKit's UITableViewStyle: plain = 0, grouped = 1,
                // insetGrouped = 2.
                if let raw = int(pair.value) {
                    let styles: [UITableView.Style] = [.plain, .grouped, .insetGrouped]
                    if raw >= 0, raw < styles.count { table._setArchivedStyle(styles[raw]) }
                }
                return
            case "UIRowHeight":
                if let h = cgFloat(pair.value) { table.rowHeight = h }
                return
            case "UIEstimatedRowHeight":
                if let h = cgFloat(pair.value) { table.estimatedRowHeight = h }
                return
            case "UIEstimatedSectionHeaderHeight":
                if let h = cgFloat(pair.value) { table.estimatedSectionHeaderHeight = h }
                return
            case "UIEstimatedSectionFooterHeight":
                if let h = cgFloat(pair.value) { table.estimatedSectionFooterHeight = h }
                return
            case "UISectionHeaderHeight":
                if let h = cgFloat(pair.value) { table.sectionHeaderHeight = h }
                return
            case "UISectionFooterHeight":
                if let h = cgFloat(pair.value) { table.sectionFooterHeight = h }
                return
            case "UISeparatorColor":
                if case .reference(let i) = pair.value {
                    table.separatorColor = (build(i) as? UIColor)
                }
                return
            case "UISeparatorInsetReference":
                // Present whenever IB has an opinion, and an opinion is
                // exactly what makes the inset explicit. The three fixture
                // nibs all archive a zero inset (no `UISeparatorInset` key),
                // so a non-zero one stays unhandled rather than guessed —
                // there is nothing to measure its encoding against.
                if let raw = int(pair.value),
                   let reference = UITableView.SeparatorInsetReference(rawValue: raw) {
                    table.separatorInsetReference = reference
                    table.separatorInset = .zero
                }
                return
            case "UISeparatorStyle":
                // UIKit: none = 0, singleLine = 1 (the etched styles are
                // deprecated aliases of singleLine).
                if let raw = int(pair.value) {
                    table.separatorStyle = raw == 0 ? .none : .singleLine
                }
                return
            default: break
            }
        }
        if let cell = view as? UITableViewCell {
            switch pair.key {
            case "UIReuseIdentifier":
                if let identifier = string(pair.value) { cell._setNibReuseIdentifier(identifier) }
                return
            case "UIViewPreservesSpecificSuperviewMargins":
                return
            default: break
            }
        }
        if let scroll = view as? UIScrollView {
            switch pair.key {
            case "UIAlwaysBounceVertical":
                if let flag = bool(pair.value) { scroll.alwaysBounceVertical = flag }
                return
            case "UIAlwaysBounceHorizontal":
                if let flag = bool(pair.value) { scroll.alwaysBounceHorizontal = flag }
                return
            case "UIShowsHorizontalScrollIndicator":
                if let flag = bool(pair.value) { scroll.showsHorizontalScrollIndicator = flag }
                return
            case "UIShowsVerticalScrollIndicator":
                if let flag = bool(pair.value) { scroll.showsVerticalScrollIndicator = flag }
                return
            case "UIDelaysContentTouches", "UICanCancelContentTouches":
                return
            default: break
            }
        }
        if let toggle = view as? UISwitch {
            switch pair.key {
            case "UISwitchOn":
                if let flag = bool(pair.value) { toggle.isOn = flag }
                return
            case "UISwitchEnabled":
                return
            default: break
            }
        }
        if let slider = view as? UISlider {
            switch pair.key {
            case "UIMinValue":
                if let v = cgFloat(pair.value) { slider.minimumValue = Float(v) }
                return
            case "UIMaxValue":
                if let v = cgFloat(pair.value) { slider.maximumValue = Float(v) }
                return
            case "UIValue":
                if let v = cgFloat(pair.value) { slider.value = Float(v) }
                return
            default: break
            }
        }
        if let stack = view as? UIStackView {
            switch pair.key {
            case "UIStackViewArrangedSubviews":
                guard case .reference(let i) = pair.value else { return }
                for case let arranged as UIView in arrangedElementsForStack(i) {
                    stack.addArrangedSubview(arranged)
                }
                return
            case "UIStackViewAxis":
                // UILayoutConstraintAxis: horizontal = 0, vertical = 1.
                if let raw = int(pair.value) { stack.axis = raw == 1 ? .vertical : .horizontal }
                return
            case "UIStackViewDistribution":
                // UIStackViewDistribution raw values (UIStackView.h).
                let all: [UIStackView.Distribution] = [.fill, .fillEqually, .fillProportionally,
                                                       .equalSpacing, .equalCentering]
                if let raw = int(pair.value), raw >= 0, raw < all.count { stack.distribution = all[raw] }
                return
            case "UIStackViewAlignment":
                // UIStackViewAlignment: fill 0, leading = top 1,
                // firstBaseline 2, center 3, trailing = bottom 4,
                // lastBaseline 5. The port spells top/bottom separately for a
                // horizontal stack; `UIStackViewAxis` precedes this key.
                guard let raw = int(pair.value) else { return }
                let vertical = stack.axis == .vertical
                switch raw {
                case 0: stack.alignment = .fill
                case 1: stack.alignment = vertical ? .leading : .top
                case 2: stack.alignment = .firstBaseline
                case 3: stack.alignment = .center
                case 4: stack.alignment = vertical ? .trailing : .bottom
                case 5: stack.alignment = .lastBaseline
                default: UINib.noteUnhandled("UIStackViewAlignment:\(raw)")
                }
                return
            case "UIStackViewSpacing":
                if let spacing = cgFloat(pair.value) { stack.spacing = spacing }
                return
            case "UIStackViewLayoutMarginsRelative":
                if let flag = bool(pair.value) { stack.isLayoutMarginsRelativeArrangement = flag }
                return
            case "UIStackViewBaselineRelative":
                if bool(pair.value) == true { UINib.noteUnhandled("UIStackView.baselineRelative") }
                return
            default: break
            }
        }
        if let spinner = view as? UIActivityIndicatorView {
            switch pair.key {
            case "UIAnimating":
                if bool(pair.value) == true { spinner.startAnimating() }
                return
            case "UIHidesWhenStopped":
                if let flag = bool(pair.value) { spinner.hidesWhenStopped = flag }
                return
            case "UIColor":
                if let color = self.object(pair.value) as? UIColor { spinner.color = color }
                return
            case "UIActivityIndicatorViewStyle-Modern", "UIActivityIndicatorViewStyle":
                return
            default: break
            }
        }
        if let segments = view as? UISegmentedControl {
            switch pair.key {
            case "UISegments":
                guard case .reference(let i) = pair.value else { return }
                for (offset, element) in arrayElements(at: i).enumerated() {
                    if let segment = element as? NibSegmentBox {
                        segments.insertSegment(withTitle: segment.title, at: offset, animated: false)
                    }
                }
                return
            case "UISelectedSegmentIndex":
                if let index = int(pair.value) { segments.selectedSegmentIndex = index }
                return
            default: break
            }
        }
        UINib.noteUnhandled("\(type(of: view)).\(pair.key)")
    }

    /// A stack's arranged subviews, in order.
    func arrangedElementsForStack(_ index: Int) -> [AnyObject] {
        arrayElements(at: index)
    }

    // MARK: Non-view objects

    func makeNavigationItem(_ object: NibArchive.Object, index: Int) -> AnyObject? {
        let item = UINavigationItem(title: string(object.first("UITitle")))
        built[index] = item
        for pair in object.values {
            switch pair.key {
            case "UITitle", "UIAttributedTitle", "UICenterItemGroups", "UINavigationBar",
                 "UILargeTitleDisplayMode":
                continue
            case "UIPrompt":
                item.prompt = string(pair.value)
            case "UIBackButtonTitle":
                item.backButtonTitle = string(pair.value)
            case "UIHidesBackButton":
                if let flag = bool(pair.value) { item.hidesBackButton = flag }
            case "UILeftBarButtonItem", "UIRightBarButtonItem":
                continue
            case "UILeftBarButtonItems":
                if case .reference(let i) = pair.value {
                    item.leftBarButtonItems = arrayElements(at: i).compactMap { $0 as? UIBarButtonItem }
                }
            case "UIRightBarButtonItems":
                if case .reference(let i) = pair.value {
                    item.rightBarButtonItems = arrayElements(at: i).compactMap { $0 as? UIBarButtonItem }
                }
            case "UITitleView":
                item.titleView = self.object(pair.value) as? UIView
            default:
                UINib.noteUnhandled("UINavigationItem.\(pair.key)")
            }
        }
        return item
    }

    func makeBarButtonItem(_ object: NibArchive.Object, index: Int) -> AnyObject? {
        let item: UIBarButtonItem
        if let raw = int(object.first("UISystemItem")),
           let system = UIBarButtonItem.SystemItem(rawValue: raw) {
            item = UIBarButtonItem(barButtonSystemItem: system)
        } else {
            item = UIBarButtonItem()
        }
        built[index] = item
        for pair in object.values {
            switch pair.key {
            case "UITitle":
                item.title = string(pair.value)
            case "UIStyle":
                // UIBarButtonItemStyle: plain = 0, bordered = 1 (deprecated,
                // renders plain), done = 2.
                if let raw = int(pair.value) { item.style = raw == 2 ? .done : .plain }
            case "UIEnabled":
                if let flag = bool(pair.value) { item.isEnabled = flag }
            case "UIImage":
                item.image = self.object(pair.value) as? UIImage
            case "UITag":
                if let tag = int(pair.value) { item.tag = tag }
            case "UICustomView":
                if let view = self.object(pair.value) as? UIView { item.customView = view }
            case "UISystemItem", "UIIsSystemItem":
                continue
            default:
                UINib.noteUnhandled("UIBarButtonItem.\(pair.key)")
            }
        }
        return item
    }

    func makeGestureRecognizer(_ object: NibArchive.Object, index: Int) -> AnyObject? {
        let recognizer: UIGestureRecognizer
        switch object.className {
        case "UITapGestureRecognizer":
            recognizer = UITapGestureRecognizer()
        case "UILongPressGestureRecognizer":
            recognizer = UILongPressGestureRecognizer()
        case "UIPanGestureRecognizer":
            recognizer = UIPanGestureRecognizer()
        case "UISwipeGestureRecognizer":
            recognizer = UISwipeGestureRecognizer()
        case "UIPinchGestureRecognizer":
            recognizer = UIPinchGestureRecognizer()
        default:
            UINib.noteUnhandled("class:\(object.className)")
            return nil
        }
        register(recognizer, at: index)
        for pair in object.values {
            switch pair.key {
            case "UIGestureRecognizer.allowedTouchTypes",
                 "UIGestureRecognizer.requiresExclusiveTouchType",
                 "UITapGestureRecognizer._imp", "UILongPressGestureRecognizer._imp":
                continue
            case "UIGestureRecognizer.enabled":
                if let flag = bool(pair.value) { recognizer.isEnabled = flag }
            case "UIGestureRecognizer.cancelsTouchesInView":
                if let flag = bool(pair.value) { recognizer.cancelsTouchesInView = flag }
            case "UIGestureRecognizer.delaysTouchesBegan", "UIGestureRecognizer.delaysTouchesEnded":
                continue
            default:
                UINib.noteUnhandled("\(object.className).\(pair.key)")
            }
        }
        return recognizer
    }
}

/// A pre-iOS-11 top or bottom layout guide archived as a view (storyboards
/// saved before safe areas: every Eidolon scene). UIKit's class of the same
/// name is a hidden `UIView` subclass, and the oracle dumps it under this
/// name, so the port keeps the name.
@preconcurrency @MainActor
final class _UILayoutGuide: UIView {}
