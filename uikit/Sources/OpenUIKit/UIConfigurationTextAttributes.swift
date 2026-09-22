// UIConfigurationTextAttributesTransformer and the UIKit AttributedString
// scope it operates on. Owner: button module.
//
// WHY THIS EXISTS
// ---------------
// Kickstarter's design system (KDS) styles every button through
// `UIButton.Configuration.titleTextAttributesTransformer`:
//
//     buttonConfiguration.titleTextAttributesTransformer =
//       UIConfigurationTextAttributesTransformer { config in
//         var newConfig = config
//         newConfig.font = styleConfig.font
//         newConfig.foregroundColor = self.configuration?.baseForegroundColor
//                                     ?? self.tintColor
//         return newConfig
//       }
//
// (KDS/Sources/KDS/Buttons/KSRButtonStyleConfiguration.swift:60-72). The
// transformer's argument is an `AttributeContainer`, and `.font` /
// `.foregroundColor` reach `UIFont` / `UIColor` only through a UIKit
// AttributeScope. Foundation ships `AttributeScopes.FoundationAttributes`;
// the UIKit one is UIKit's, so the port declares it here, the same way
// Sources/SwiftUI/TextAttributes.swift declares SwiftUI's.
//
// MEASURED (iOS 26.1, Tools/oracle2/buttonconfigprobe, `transformers` and
// `explicitColorsPerState` sections):
//
//   * The container UIKit hands the transformer carries exactly two keys,
//     `NSFont` and `NSColor`: the resolved title font (17 pt body by default)
//     and the configuration's resolved base foreground colour — the raw
//     colour, before any state treatment. The probe's log line reads
//     `font=.SFUI-Regular@17.0 color=0.2039,0.7804,0.3490,1.0000` for a
//     `.filled()` whose `baseForegroundColor` is `systemGreen`.
//   * A transformer that returns its input unchanged leaves the title at
//     17 pt regular in `baseForegroundColor` — so the input really is the
//     resolved pair, not an empty container.
//   * Whatever the transformer returns WINS VERBATIM, in every state and at
//     full alpha. A `.filled()` with `baseForegroundColor` systemGreen and a
//     transformer forcing systemGreen renders systemGreen when normal,
//     highlighted AND disabled — where the same configuration without the
//     transformer renders systemGreen, systemGreen at alpha 0.75, and
//     `tertiaryLabel`. That asymmetry is the whole reason KDS installs the
//     transformer; its source comment says so.
//
// The scope is deliberately small: the four keys the corpus and the port's
// own drawing can honour. Adding a key here without a renderer that reads it
// would be a store-only member masquerading as a working one.

#if canImport(Foundation)
import Foundation
#elseif canImport(FoundationEssentials)
import FoundationEssentials
#endif

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
#endif

#if canImport(Foundation) || canImport(FoundationEssentials)

// MARK: - The UIKit attribute scope

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension AttributeScopes {
    var openUIKit: OpenUIKitAttributes.Type { OpenUIKitAttributes.self }

    /// UIKit's AttributedString scope. Named `OpenUIKitAttributes` rather than
    /// `UIKitAttributes` on purpose: on a Darwin host where Foundation already
    /// vends `AttributeScopes.UIKitAttributes`, a second declaration of that
    /// name would be a same-name-different-type collision in exactly the files
    /// that import both. The dynamic-member subscript below is what app code
    /// actually touches (`container.font`), and that is spelled the same
    /// either way.
    struct OpenUIKitAttributes: AttributeScope {
        public let font: FontAttribute
        public let foregroundColor: ForegroundColorAttribute
        public let backgroundColor: BackgroundColorAttribute
        public let kern: KerningAttribute
        public let foundation: AttributeScopes.FoundationAttributes
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension AttributeScopes.OpenUIKitAttributes {
    enum FontAttribute: AttributedStringKey {
        public typealias Value = UIFont
        public static let name = "NSFont"
    }

    enum ForegroundColorAttribute: AttributedStringKey {
        public typealias Value = UIColor
        public static let name = "NSColor"
    }

    enum BackgroundColorAttribute: AttributedStringKey {
        public typealias Value = UIColor
        public static let name = "NSBackgroundColor"
    }

    enum KerningAttribute: AttributedStringKey {
        public typealias Value = CGFloat
        public static let name = "NSKern"
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension AttributeDynamicLookup {
    subscript<T: AttributedStringKey>(
        dynamicMember keyPath: KeyPath<AttributeScopes.OpenUIKitAttributes, T>
    ) -> T {
        fatalError("AttributeDynamicLookup values are only used as key paths")
    }
}

// MARK: - The transformer

/// UIKit's `UIConfigurationTextAttributesTransformer`: a closure over an
/// `AttributeContainer`, invoked when a configuration resolves its title text
/// attributes.
///
/// UIKit declares this `Sendable` with a `@Sendable` closure. OpenUIKit does
/// not, and the reason is measured rather than stylistic: KDS's transformer
/// closes over `self` (a `@MainActor` `UIButton`) and reads
/// `self.configuration?.baseForegroundColor` inside the body. A `@Sendable`
/// requirement rejects that capture under strict concurrency, so the corpus
/// would not compile against a stricter-than-UIKit declaration.
@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public struct UIConfigurationTextAttributesTransformer {
    private let _transform: (AttributeContainer) -> AttributeContainer

    public init(_ transform: @escaping (AttributeContainer) -> AttributeContainer) {
        _transform = transform
    }

    public func callAsFunction(_ input: AttributeContainer) -> AttributeContainer {
        _transform(input)
    }

    /// UIKit spells the application `transformer(container)`; this is the
    /// same operation for call sites that prefer a named method.
    public func transform(_ input: AttributeContainer) -> AttributeContainer {
        _transform(input)
    }
}

// MARK: - Reading the two keys the port renders

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributeContainer {
    /// The `UIFont` under the UIKit scope's `NSFont` key, if present.
    var openUIKitFont: UIFont? {
        self[AttributeScopes.OpenUIKitAttributes.FontAttribute.self]
    }

    /// The `UIColor` under the UIKit scope's `NSColor` key, if present.
    var openUIKitForegroundColor: UIColor? {
        self[AttributeScopes.OpenUIKitAttributes.ForegroundColorAttribute.self]
    }

    /// The container UIKit hands a title transformer: the resolved font and
    /// the resolved base foreground colour, and nothing else (measured).
    static func openUIKitTitleAttributes(font: UIFont, foregroundColor: UIColor)
        -> AttributeContainer {
        var container = AttributeContainer()
        container[AttributeScopes.OpenUIKitAttributes.FontAttribute.self] = font
        container[AttributeScopes.OpenUIKitAttributes.ForegroundColorAttribute.self] =
            foregroundColor
        return container
    }
}

#endif
