// A module literally named `UIKit` that re-exports OpenUIKit.
//
// Why this exists: the real-app harness (Sources/RealAppProbe) vendors
// UNMODIFIED source files from a shipping iOS app, and every one of them
// starts with `import UIKit`. Without this shim each vendored file would need
// that line rewritten to `import OpenUIKit`, which would show up in the
// adaptation ledger as noise — a module rename says nothing about API
// coverage, which is what docs/REAL_APP_TEST.md is measuring.
//
// It is safe on both platforms: `import UIKit` does not resolve to anything in
// the macOS SDK (UIKit ships in the iOS / Mac Catalyst SDKs only), and there is
// no UIKit at all on Linux, so this target is the only `UIKit` in scope.
//
// This target is a shim by definition and is labelled as such in the report.
// It re-exports framework API and owns only bounded compatibility overlays:
// the local identity aliases that control unqualified lookup and the UIKit
// #Preview declarations whose implementation lives in host/target modules.
//
// M15: it re-exports Foundation as well, because REAL UIKit does
// (`@_exported import Foundation` is in UIKit's own swiftinterface). That is
// what makes an app file whose only import line is `import UIKit` able to name
// `NSCoder` — the corpus's single most common missing type, 344 of 5,099
// files. It became possible only once OpenUIKit's geometry types were
// Foundation's own; before M15 this line would have made every `CGRect` in
// every vendored file ambiguous. Linux-built Mach-O app builds do not yet
// have the complete Foundation umbrella, but they do stage the open-source
// FoundationEssentials module. Re-exporting it on that path preserves real
// UIKit's app-facing contract: an unchanged file with only `import UIKit`
// sees the canonical `IndexPath`, rather than OpenUIKit's old fallback value.
#if canImport(Foundation)
@_exported import Foundation
#elseif canImport(FoundationEssentials)
@_exported import FoundationEssentials
#endif
#if canImport(ObjectiveC)
@_exported import ObjectiveC
#endif
@_exported import OpenUIKit

// UIKit owns the typed AttributedString keys for font and text decoration.
// Foundation deliberately cannot define these keys because their values are
// UIKit types.  Keep this overlay in the literal `UIKit` module so unchanged
// application source can use `attributed.font`, `attributed.foregroundColor`,
// and the Objective-C attribute-dictionary bridge exactly as it does on iOS.
#if canImport(Foundation) || canImport(FoundationEssentials)
@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributeScopes {
    public var uiKit: UIKitAttributes.Type { UIKitAttributes.self }

    public struct UIKitAttributes: AttributeScope {
        public let font: FontAttribute
        public let paragraphStyle: ParagraphStyleAttribute
        public let foregroundColor: ForegroundColorAttribute
        public let backgroundColor: BackgroundColorAttribute
        public let ligature: LigatureAttribute
        public let kern: KernAttribute
        public let tracking: TrackingAttribute
        public let strikethroughStyle: StrikethroughStyleAttribute
        public let underlineStyle: UnderlineStyleAttribute
        public let strokeColor: StrokeColorAttribute
        public let strokeWidth: StrokeWidthAttribute
        public let baselineOffset: BaselineOffsetAttribute
        public let underlineColor: UnderlineColorAttribute
        public let strikethroughColor: StrikethroughColorAttribute
        public let obliqueness: ObliquenessAttribute
        public let expansion: ExpansionAttribute
        public let textItemTag: TextItemTagAttribute
        public let foundation: AttributeScopes.FoundationAttributes
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributeDynamicLookup {
    @_disfavoredOverload
    public subscript<T: AttributedStringKey>(
        dynamicMember keyPath: KeyPath<AttributeScopes.UIKitAttributes, T>
    ) -> T {
        fatalError("AttributeDynamicLookup values are only used as key paths")
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributeScopes.UIKitAttributes {
    public enum FontAttribute: AttributedStringKey, Sendable {
        public typealias Value = OpenUIKit.UIFont
        public static let name = "NSFont"
    }

    public enum ParagraphStyleAttribute: AttributedStringKey, Sendable {
        public typealias Value = OpenUIKit.NSParagraphStyle
        public static let name = "NSParagraphStyle"
    }

    public enum ForegroundColorAttribute: AttributedStringKey, Sendable {
        public typealias Value = OpenUIKit.UIColor
        public static let name = "NSColor"
    }

    public enum BackgroundColorAttribute: AttributedStringKey, Sendable {
        public typealias Value = OpenUIKit.UIColor
        public static let name = "NSBackgroundColor"
    }

    public enum LigatureAttribute: AttributedStringKey, Sendable {
        public typealias Value = Int
        public static let name = "NSLigature"
    }

    public enum KernAttribute: AttributedStringKey, Sendable {
        public typealias Value = CGFloat
        public static let name = "NSKern"
    }

    public enum TrackingAttribute: AttributedStringKey, Sendable {
        public typealias Value = CGFloat
        public static let name = "NSTracking"
    }

    public enum StrikethroughStyleAttribute: AttributedStringKey, Sendable {
        public typealias Value = OpenUIKit.NSUnderlineStyle
        public static let name = "NSStrikethrough"
    }

    public enum UnderlineStyleAttribute: AttributedStringKey, Sendable {
        public typealias Value = OpenUIKit.NSUnderlineStyle
        public static let name = "NSUnderline"
    }

    public enum StrokeColorAttribute: AttributedStringKey, Sendable {
        public typealias Value = OpenUIKit.UIColor
        public static let name = "NSStrokeColor"
    }

    public enum StrokeWidthAttribute: AttributedStringKey, Sendable {
        public typealias Value = CGFloat
        public static let name = "NSStrokeWidth"
    }

    public enum BaselineOffsetAttribute: AttributedStringKey, Sendable {
        public typealias Value = CGFloat
        public static let name = "NSBaselineOffset"
    }

    public enum UnderlineColorAttribute: AttributedStringKey, Sendable {
        public typealias Value = OpenUIKit.UIColor
        public static let name = "NSUnderlineColor"
    }

    public enum StrikethroughColorAttribute: AttributedStringKey, Sendable {
        public typealias Value = OpenUIKit.UIColor
        public static let name = "NSStrikethroughColor"
    }

    public enum ObliquenessAttribute: AttributedStringKey, Sendable {
        public typealias Value = CGFloat
        public static let name = "NSObliqueness"
    }

    public enum ExpansionAttribute: AttributedStringKey, Sendable {
        public typealias Value = CGFloat
        public static let name = "NSExpansion"
    }

    public enum TextItemTagAttribute: AttributedStringKey, Sendable {
        public typealias Value = String
        public static let name = "NSTextItemTag"
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributeContainer {
    /// Converts OpenUIKit's Objective-C-shaped text dictionary into typed
    /// Foundation attributes. As on Apple platforms, unknown keys and values
    /// with the wrong dynamic type are dropped rather than trapping.
    public init(_ dictionary: [OpenUIKit.NSAttributedString.Key: Any]) {
        self.init()
        for (key, value) in dictionary {
            switch key {
            case .font:
                if let value = value as? OpenUIKit.UIFont {
                    self[AttributeScopes.UIKitAttributes.FontAttribute.self] = value
                }
            case .paragraphStyle:
                if let value = value as? OpenUIKit.NSParagraphStyle {
                    self[AttributeScopes.UIKitAttributes.ParagraphStyleAttribute.self] = value
                }
            case .foregroundColor:
                if let value = value as? OpenUIKit.UIColor {
                    self[AttributeScopes.UIKitAttributes.ForegroundColorAttribute.self] = value
                }
            case .backgroundColor:
                if let value = value as? OpenUIKit.UIColor {
                    self[AttributeScopes.UIKitAttributes.BackgroundColorAttribute.self] = value
                }
            case .kern:
                if let value = value as? CGFloat {
                    self[AttributeScopes.UIKitAttributes.KernAttribute.self] = value
                }
            case .tracking:
                if let value = value as? CGFloat {
                    self[AttributeScopes.UIKitAttributes.TrackingAttribute.self] = value
                }
            case .underlineStyle:
                if let value = value as? OpenUIKit.NSUnderlineStyle {
                    self[AttributeScopes.UIKitAttributes.UnderlineStyleAttribute.self] = value
                } else if let value = value as? Int {
                    self[AttributeScopes.UIKitAttributes.UnderlineStyleAttribute.self] =
                        OpenUIKit.NSUnderlineStyle(rawValue: value)
                }
            case .strikethroughStyle:
                if let value = value as? OpenUIKit.NSUnderlineStyle {
                    self[AttributeScopes.UIKitAttributes.StrikethroughStyleAttribute.self] = value
                } else if let value = value as? Int {
                    self[AttributeScopes.UIKitAttributes.StrikethroughStyleAttribute.self] =
                        OpenUIKit.NSUnderlineStyle(rawValue: value)
                }
            case .strokeColor:
                if let value = value as? OpenUIKit.UIColor {
                    self[AttributeScopes.UIKitAttributes.StrokeColorAttribute.self] = value
                }
            case .strokeWidth:
                if let value = value as? CGFloat {
                    self[AttributeScopes.UIKitAttributes.StrokeWidthAttribute.self] = value
                }
            case .baselineOffset:
                if let value = value as? CGFloat {
                    self[AttributeScopes.UIKitAttributes.BaselineOffsetAttribute.self] = value
                }
            case .underlineColor:
                if let value = value as? OpenUIKit.UIColor {
                    self[AttributeScopes.UIKitAttributes.UnderlineColorAttribute.self] = value
                }
            case .strikethroughColor:
                if let value = value as? OpenUIKit.UIColor {
                    self[AttributeScopes.UIKitAttributes.StrikethroughColorAttribute.self] = value
                }
            default:
                continue
            }
        }
    }
}
#endif

// Preview is app-side machinery: the DeveloperToolsSupport module is built
// against the app-facing Foundation facade, so re-exporting it from a
// Foundation-hidden (FoundationEssentials-only) shim compile would drag the
// hidden module back in. canImport(DeveloperToolsSupport) alone is not enough
// — the module can exist while its Foundation dependency is deliberately
// invisible (the target-15 contract), which fails at import, not at canImport.
#if canImport(DeveloperToolsSupport) && canImport(Foundation)
@_exported @_spi(OpenUIKitPreview) import DeveloperToolsSupport

// UIKit's first bounded #Preview slice stores an unchanged UIView or
// UIViewController body in target-side DeveloperToolsSupport metadata. There
// is no preview renderer/host yet; the SPI is deliberately only a handoff for
// tests and a future host, not application API.
@available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
extension DeveloperToolsSupport.Preview {
    @MainActor
    public init(body: @escaping @MainActor () -> UIView) {
        self.init(_openUIKitBody: { body() })
    }

    @MainActor
    public init(body: @escaping @MainActor () -> UIViewController) {
        self.init(_openUIKitBody: { body() })
    }
}

/// Creates target-side preview metadata for one UIKit view expression.
///
/// Named previews, traits, and a live preview host are intentionally outside
/// this first source-compatibility slice and fail closed.
@available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
@freestanding(declaration)
public macro Preview(
    @DeveloperToolsSupport.PreviewMacroBodyBuilder<UIView>
    body: @escaping @MainActor () -> UIView
) = #externalMacro(
    module: "OpenUIKitPreviewMacros",
    type: "UIKitPreviewMacro"
)

/// Creates target-side preview metadata for one UIKit controller expression.
@available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
@freestanding(declaration)
public macro Preview(
    @DeveloperToolsSupport.PreviewMacroBodyBuilder<UIViewController>
    body: @escaping @MainActor () -> UIViewController
) = #externalMacro(
    module: "OpenUIKitPreviewMacros",
    type: "UIKitPreviewMacro"
)
#endif

// These local aliases deliberately win unqualified lookup through the
// re-exporting UIKit module. On Foundation-visible builds OpenUIKit's
// Notification, NSNotification and OperationQueue aliases already have
// Foundation identity, and Foundation+Objective-C also aliases the center;
// importing UIKit plus Foundation therefore names one declaration. Portable
// builds retain OpenUIKit's selector-capable center behind the same spelling.
public typealias Notification = OpenUIKit.Notification
#if canImport(Foundation) || canImport(ObjectiveC)
public typealias NSNotification = OpenUIKit.NSNotification
#endif
public typealias NotificationCenter = OpenUIKit.NotificationCenter
public typealias OperationQueue = OpenUIKit.OperationQueue
public typealias Timer = OpenUIKit.Timer
public typealias NSAttributedString = OpenUIKit.NSAttributedString
public typealias NSMutableAttributedString = OpenUIKit.NSMutableAttributedString

// Foundation/AppKit also ships an NSDiffableDataSourceSnapshot declaration.
// UIKit applications must resolve the snapshot paired with this shim's
// UITableViewDiffableDataSource, so publish a local alias that wins through
// the re-export boundary just as the Notification aliases above do.
public typealias NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>
    = OpenUIKit.NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>
    where SectionIdentifierType: Hashable, ItemIdentifierType: Hashable
public typealias UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>
    = OpenUIKit.UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>
    where SectionIdentifierType: Hashable, ItemIdentifierType: Hashable
