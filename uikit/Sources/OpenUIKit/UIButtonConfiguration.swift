// UIButton.Configuration. Owner: button module.
//
// SCOPE
// -----
// Bounded by what real apps use, not by the SDK surface. The member list
// comes from Kickstarter's ios-oss corpus (28 uses in KDS plus 6 in
// Kickstarter-Framework/Library); docs/agent_reports/uibutton-configuration.md
// section 1 lists every site. Everything here is measured on the iOS 26.1
// oracle by Tools/oracle2/buttonconfigprobe (transcript:
// ios-26.1-iphone16.json beside it), and the numbers below quote that file.
//
// MEASURED DEFAULTS -- every factory, iPhone 16 / iOS 26.1
// -------------------------------------------------------
//   contentInsets  (7, 12, 7, 12)      imagePadding    0
//   titlePadding   1                   imagePlacement  .leading
//   titleAlignment .automatic          titleLineBreakMode .byWordWrapping
//   buttonSize     .medium             baseForeground/BackgroundColor nil
//   showsActivityIndicator false        imageReservation 0
//   background.strokeWidth 1 (with a clear stroke colour, so nothing draws)
//   cornerStyle    .dynamic, background.cornerRadius 17
//                  -- except the iOS 26 glass family: .capsule, radius 5.95
//   automaticallyUpdateForSelection  true, EXCEPT .filled / .borderedProminent
//                  / the glass family, which are false
//
// A title of "Configure" gives intrinsic 99 x 34.33333 in EVERY factory, with
// the title label at (12, 7, 75, 20.33333) in a 17 pt regular system font.
//
// CORNER RADIUS (measured across heights 20/28/34/44/60 at width 160)
// -------------------------------------------------------------------
//   .fixed    background.cornerRadius verbatim
//   .dynamic  min(height / 2, background.cornerRadius)
//   .small    height * 0.125     .medium  height * 0.175
//   .large    height * 0.25      .capsule height / 2
// The four proportional styles IGNORE background.cornerRadius: setting it to
// 6 on a 44 pt button leaves .small at 5.5, .medium at 7.7, .large at 11.
//
// ONE MEASURED QUIRK, REPRODUCED
// ------------------------------
// Assigning `cornerStyle` a value other than `.dynamic` resets
// `background.cornerRadius` to the system default 5.95; `.dynamic` keeps the
// factory's 17. Every corner row in the transcript reads back 5.95 except the
// `.dynamic` ones, which read 17. The setter below reproduces that, so an
// explicit `background.cornerRadius` assigned AFTER `cornerStyle` still wins
// (the transcript's `explicitRadius6_h44` rows).

#if canImport(Foundation)
import Foundation
#elseif canImport(FoundationEssentials)
import FoundationEssentials
#endif

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGSize
#endif

public extension UIButton {
    struct Configuration {
        // MARK: Nested types

        /// The port's marker for which factory produced this configuration.
        /// UIKit has no such property — it bakes the choice into private
        /// resolution — but OpenUIKit's drawing needs to name it, and scene
        /// fixtures already read it (Sources/openrender/SceneBuilder.swift).
        public enum Style: Hashable, Sendable {
            case plain
            case gray
            case tinted
            case filled
            case borderless
            case bordered
            case borderedTinted
            case borderedProminent
            case glass
        }

        public enum CornerStyle: Hashable, Sendable {
            case fixed
            case dynamic
            case small
            case medium
            case large
            case capsule
        }

        /// UIKit spells this `UIButton.Configuration.Size`; `ButtonSize` is
        /// the name the `buttonSize` property suggests and some call sites
        /// use, so both spellings resolve.
        public enum Size: Hashable, Sendable {
            case mini
            case small
            case medium
            case large
        }

        public typealias ButtonSize = Size

        public enum TitleAlignment: Hashable, Sendable {
            case automatic
            case leading
            case center
            case trailing
        }

        // MARK: Stored members

        public var style: Style

        /// Backing store for `title` / `attributedTitle`. MEASURED: they are
        /// ONE slot. Setting `attributedTitle` then reading `title` returns
        /// the attributed string's characters; assigning either replaces both
        /// (transcript `titles.titleAfterAttributed` reads "Plain" for both,
        /// `titles.attributedAfterTitle` reads "Attributed" for both).
        private var _titleText: String?
        private var _subtitleText: String?

        /// `AttributedString` is macOS 12 / iOS 15, and availability cannot
        /// sit on a stored property, so the two attributed slots are stored
        /// type-erased and surfaced by the gated accessors below — the same
        /// shape the two text-attribute transformers use.
        private var _attributedTitleStorage: Any?
        private var _attributedSubtitleStorage: Any?

        #if canImport(Foundation) || canImport(FoundationEssentials)
        @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
        public var attributedTitle: AttributedString? {
            get { _attributedTitleStorage as? AttributedString }
            set {
                _attributedTitleStorage = newValue
                _titleText = newValue.map { String($0.characters) }
            }
        }

        @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
        public var attributedSubtitle: AttributedString? {
            get { _attributedSubtitleStorage as? AttributedString }
            set {
                _attributedSubtitleStorage = newValue
                _subtitleText = newValue.map { String($0.characters) }
            }
        }
        #endif

        public var title: String? {
            get { _titleText }
            set {
                _titleText = newValue
                _attributedTitleStorage = nil
            }
        }

        public var subtitle: String? {
            get { _subtitleText }
            set {
                _subtitleText = newValue
                _attributedSubtitleStorage = nil
            }
        }

        public var image: UIImage?

        /// Gap between the image and the title block. Measured: 0 by default
        /// in every factory, and it adds to the intrinsic size one-for-one
        /// (leading placement, "Go" + `star.fill`: 74 pt at padding 0, 80 at
        /// 6, 94 at 20).
        public var imagePadding: CGFloat

        /// Gap between title and subtitle. Measured default 1: a
        /// title+subtitle `.filled()` is 51 pt tall = 7 + 20.33333 + 1 +
        /// 15.66667 + 7.
        public var titlePadding: CGFloat

        public var imagePlacement: NSDirectionalRectEdge

        /// Space reserved for an image even when there is none. Stored; the
        /// port's layout does not consume it (default 0 everywhere measured).
        public var imageReservation: CGFloat

        public var titleAlignment: TitleAlignment

        /// Measured default `.byWordWrapping` (raw 0) in every factory. A
        /// wrapping mode gives the title label `numberOfLines = 0`, a
        /// truncating mode gives it 1.
        public var titleLineBreakMode: NSLineBreakMode
        public var subtitleLineBreakMode: NSLineBreakMode

        public var contentInsets: NSDirectionalEdgeInsets

        public var baseForegroundColor: UIColor?
        public var baseBackgroundColor: UIColor?

        public var background: UIBackgroundConfiguration

        public var showsActivityIndicator: Bool

        /// Measured false for `.filled()`, `.borderedProminent()` and the
        /// glass family; true for the other five factories. When true, a
        /// selected button takes a tint fill at alpha 0.18.
        public var automaticallyUpdateForSelection: Bool

        #if canImport(Foundation) || canImport(FoundationEssentials)
        @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
        public var titleTextAttributesTransformer: UIConfigurationTextAttributesTransformer? {
            get { _titleTextAttributesTransformer as? UIConfigurationTextAttributesTransformer }
            set { _titleTextAttributesTransformer = newValue }
        }

        @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
        public var subtitleTextAttributesTransformer: UIConfigurationTextAttributesTransformer? {
            get { _subtitleTextAttributesTransformer as? UIConfigurationTextAttributesTransformer }
            set { _subtitleTextAttributesTransformer = newValue }
        }

        /// Availability cannot sit on a stored property, so the two
        /// transformers are stored type-erased and surfaced by the typed
        /// accessors above.
        private var _titleTextAttributesTransformer: Any?
        private var _subtitleTextAttributesTransformer: Any?
        #endif

        /// Applied to the image's tint. KDS installs one that returns the
        /// button's `tintColor` unconditionally.
        public var imageColorTransformer: UIConfigurationColorTransformer?

        private var _cornerStyle: CornerStyle
        public var cornerStyle: CornerStyle {
            get { _cornerStyle }
            set {
                _cornerStyle = newValue
                // See the file header: measured on iOS 26.1, assigning any
                // non-`.dynamic` corner style drops `background.cornerRadius`
                // to the system default.
                if newValue != .dynamic {
                    background.cornerRadius = Configuration.systemCornerRadius
                }
            }
        }

        private var _buttonSize: Size
        public var buttonSize: Size {
            get { _buttonSize }
            set {
                _buttonSize = newValue
                // Measured: the size carries its own content insets --
                // mini/small (5, 10, 5, 10), medium (7, 12, 7, 12),
                // large (15, 20, 15, 20).
                contentInsets = Configuration.contentInsets(for: newValue)
            }
        }

        // MARK: Measured constants

        /// The corner radius a non-`.dynamic` corner style falls back to,
        /// and the glass family's factory radius (transcript: every
        /// `cornerStyles` row that is not `.dynamic` reads back 5.95).
        static let systemCornerRadius: CGFloat = 5.95

        /// The `.dynamic` factory radius (transcript: `factoryDefaults`).
        static let dynamicCornerRadius: CGFloat = 17

        static func contentInsets(for size: Size) -> NSDirectionalEdgeInsets {
            switch size {
            case .mini, .small:
                return NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
            case .medium:
                return NSDirectionalEdgeInsets(top: 7, leading: 12, bottom: 7, trailing: 12)
            case .large:
                return NSDirectionalEdgeInsets(top: 15, leading: 20, bottom: 15, trailing: 20)
            }
        }

        /// Measured title point size per button size: 15 pt for mini and
        /// small, 17 pt for medium and large (transcript `buttonSizes`,
        /// intrinsic 87.33333 x 28 versus 99 x 34.33333).
        static func titleFontSize(for size: Size) -> CGFloat {
            switch size {
            case .mini, .small: return 15
            case .medium, .large: return 17
            }
        }

        /// Measured subtitle point size: 13 pt regular (transcript
        /// `titles.titleAndSubtitle`, subtitle label 46.66667 x 15.66667).
        static let subtitleFontSize: CGFloat = 13

        // MARK: Init

        public init(style: Style) {
            self.style = style
            _titleText = nil
            _subtitleText = nil
            _attributedTitleStorage = nil
            _attributedSubtitleStorage = nil
            #if canImport(Foundation) || canImport(FoundationEssentials)
            _titleTextAttributesTransformer = nil
            _subtitleTextAttributesTransformer = nil
            #endif
            image = nil
            imagePadding = 0
            titlePadding = 1
            imagePlacement = .leading
            imageReservation = 0
            titleAlignment = .automatic
            titleLineBreakMode = .byWordWrapping
            subtitleLineBreakMode = .byWordWrapping
            _buttonSize = .medium
            contentInsets = Configuration.contentInsets(for: .medium)
            baseForegroundColor = nil
            baseBackgroundColor = nil
            showsActivityIndicator = false
            imageColorTransformer = nil
            // DELIBERATE DIVERGENCE, documented in the report: the oracle
            // reads a factory's `background.backgroundColor` back as an
            // opaque-zero clear rather than nil, and then REPLACES it during
            // resolution (`updated(for:)` overwrites exactly that one field).
            // The port leaves it nil so that "nil means derive from the
            // style, non-nil means use verbatim" is expressible — which is
            // what every corpus site relies on, because KDS and AlertBanner
            // both assign an explicit per-state colour and expect it drawn
            // untouched.
            var background = UIBackgroundConfiguration()
            // Measured: every factory carries strokeWidth 1 with a clear
            // stroke colour, so no border draws until one is assigned.
            background.strokeWidth = 1
            switch style {
            case .glass:
                _cornerStyle = .capsule
                background.cornerRadius = Configuration.systemCornerRadius
            default:
                _cornerStyle = .dynamic
                background.cornerRadius = Configuration.dynamicCornerRadius
            }
            self.background = background
            switch style {
            case .filled, .borderedProminent, .glass:
                automaticallyUpdateForSelection = false
            case .plain, .gray, .tinted, .borderless, .bordered, .borderedTinted:
                automaticallyUpdateForSelection = true
            }
        }

        // MARK: Factories

        public static func plain() -> Configuration { Configuration(style: .plain) }
        public static func gray() -> Configuration { Configuration(style: .gray) }
        public static func tinted() -> Configuration { Configuration(style: .tinted) }
        public static func filled() -> Configuration { Configuration(style: .filled) }
        public static func borderless() -> Configuration { Configuration(style: .borderless) }
        public static func bordered() -> Configuration { Configuration(style: .bordered) }
        public static func borderedTinted() -> Configuration {
            Configuration(style: .borderedTinted)
        }

        public static func borderedProminent() -> Configuration {
            Configuration(style: .borderedProminent)
        }

        /// iOS 26's glass button. OpenUIKit has no glass material renderer for
        /// buttons yet, so this resolves as a `.plain()` fill with the glass
        /// family's measured `.capsule` corner style and `.label` foreground
        /// (Kickstarter guards its one use with `if #available(iOS 26.0, *)`).
        public static func glass() -> Configuration { Configuration(style: .glass) }

        // MARK: Resolution

        /// UIKit's `updated(for:)`. MEASURED (transcript `updatedFor`): the
        /// ONLY field it changes is `background.backgroundColor`, which it
        /// fills in with the state-resolved fill — normal gives the base
        /// background at full alpha, highlighted the same colour at alpha
        /// 0.75, disabled the system gray (0.4706, 0.4706, 0.5020) at alpha
        /// 0.12. `baseForegroundColor` and `baseBackgroundColor` come back
        /// exactly as they were assigned.
        ///
        /// UIKit's declared parameter is `any UIConfigurationState`; the
        /// button itself is what the oracle probe passed and what this
        /// resolves against, because the fill depends on the button's tint
        /// as well as its state.
        @MainActor
        public func updated(for button: UIButton) -> Configuration {
            var copy = self
            copy.background.backgroundColor = button.resolvedConfigurationBackgroundColor(self)
            return copy
        }
    }
}

// MARK: - Bridging an OpenUIKit attributed string into AttributedString

#if canImport(Foundation) || canImport(FoundationEssentials)
@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension AttributedString {
    /// `AttributedString(NSAttributedString(...))`, for OpenUIKit's own
    /// `NSAttributedString`.
    ///
    /// The port deliberately keeps its own attributed-string class rather
    /// than aliasing Foundation's (Sources/OpenUIKit/FoundationTypes.swift
    /// explains why: Foundation's traps when a plain Swift value is stored
    /// twice for one key on Linux). Foundation's own
    /// `AttributedString.init(_:)` therefore does not accept it, and
    /// Kickstarter writes exactly that call —
    /// `AttributedString(NSAttributedString(string:attributes:))` in
    /// PledgeOverTimePaymentScheduleViewController.swift:209. This
    /// initializer closes that gap; it carries across the two keys the
    /// port's button drawing reads, font and foreground colour.
    init(_ attributedString: NSAttributedString) {
        self.init()
        // The port's runs carry a UTF-16 length, not their own substring, so
        // walk the backing string alongside them.
        let utf16 = Array(attributedString.string.utf16)
        var offset = 0
        for run in attributedString.runs {
            let end = Swift.min(offset + run.length, utf16.count)
            guard offset < end else { offset = end; continue }
            let text = String(decoding: utf16[offset..<end], as: UTF16.self)
            offset = end
            var piece = AttributedString(text)
            if let font = run.attributes[NSAttributedString.Key.font] as? UIFont {
                piece[AttributeScopes.OpenUIKitAttributes.FontAttribute.self] = font
            }
            if let color = run.attributes[NSAttributedString.Key.foregroundColor] as? UIColor {
                piece[AttributeScopes.OpenUIKitAttributes.ForegroundColorAttribute.self] = color
            }
            if let color = run.attributes[NSAttributedString.Key.backgroundColor] as? UIColor {
                piece[AttributeScopes.OpenUIKitAttributes.BackgroundColorAttribute.self] = color
            }
            append(piece)
        }
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension NSAttributedString {
    /// The inverse of the initializer above: the port's drawing pipeline
    /// consumes `NSAttributedString`, so a configuration's `attributedTitle`
    /// is converted back before it reaches a label.
    static func fromAttributedString(_ value: AttributedString,
                                     defaultFont: UIFont,
                                     defaultColor: UIColor) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for run in value.runs {
            let text = String(value[run.range].characters)
            guard !text.isEmpty else { continue }
            var attributes: [NSAttributedString.Key: Any] = [
                .font: run[AttributeScopes.OpenUIKitAttributes.FontAttribute.self]
                    ?? defaultFont,
                .foregroundColor:
                    run[AttributeScopes.OpenUIKitAttributes.ForegroundColorAttribute.self]
                    ?? defaultColor,
            ]
            if let background =
                run[AttributeScopes.OpenUIKitAttributes.BackgroundColorAttribute.self] {
                attributes[.backgroundColor] = background
            }
            result.append(NSAttributedString(string: text, attributes: attributes))
        }
        return result
    }
}
#endif
