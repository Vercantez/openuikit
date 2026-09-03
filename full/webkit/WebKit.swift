@_exported import Foundation
#if canImport(FoundationNetworking)
@_exported import FoundationNetworking
#endif

#if canImport(UIKit)
@_exported import UIKit
#elseif canImport(OpenUIKit)
@_exported import OpenUIKit
#endif

#if canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
import class Foundation.NSObject
#endif

// Isolated Linux host compilation has no UIKit module. These lookalikes exist
// only when UIKit/OpenUIKit cannot be imported. They are not a substitute for
// a real UIKit product; `tests/agent/WebKitDependencyIdentity.swift` carries
// the genuine Foundation (and, when present, UIKit) imports for EC2.

#if !canImport(UIKit) && !canImport(OpenUIKit)

public struct UIEdgeInsets: Equatable, Sendable {
    public var top: CGFloat
    public var left: CGFloat
    public var bottom: CGFloat
    public var right: CGFloat

    public init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }

    public static let zero = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
}

public struct NSKeyValueObservingOptions: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let new = Self(rawValue: 1 << 0)
    public static let old = Self(rawValue: 1 << 1)
    public static let initial = Self(rawValue: 1 << 2)
    public static let prior = Self(rawValue: 1 << 3)
}

public final class NSKeyValueObservation: NSObject {
    public func invalidate() {}
}

public final class UIColor: NSObject {
    public let r: CGFloat
    public let g: CGFloat
    public let b: CGFloat
    public let a: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        r = red
        g = green
        b = blue
        a = alpha
        super.init()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UIColor else { return false }
        return r == other.r && g == other.g && b == other.b && a == other.a
    }

    public static let white = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    public static let black = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
    public static let clear = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
}

public final class UIImage: NSObject {}

@MainActor
open class UIView: NSObject {
    open var frame: CGRect
    open var bounds: CGRect
    public private(set) var subviews: [UIView] = []

    public init(frame: CGRect) {
        self.frame = frame
        self.bounds = CGRect(origin: .zero, size: frame.size)
        super.init()
    }

    public override init() {
        self.frame = .zero
        self.bounds = .zero
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.frame = .zero
        self.bounds = .zero
        super.init()
    }

    open func addSubview(_ view: UIView) {
        subviews.append(view)
    }

    open func layoutSubviews() {}
}

@MainActor
open class UIScrollView: UIView {}

@MainActor
open class UIViewController: NSObject {
    public override init() {
        super.init()
    }
}

#endif

/// Fail-closed unknown-engine error used by declared APIs that cannot succeed
/// without a Web Content process.
internal func WKPortableUnknown(_ operation: String, url: URL? = nil) -> WKError {
    WKError(code: .unknown, operation: operation, requestedURL: url)
}

internal func WKPortableCompleteAfterReturn(_ body: @escaping @MainActor () -> Void) {
    Task { @MainActor in
        await Task.yield()
        body()
    }
}

public let WKPreviewActionItemIdentifierAddToReadingList =
    "WKPreviewActionItemIdentifierAddToReadingList"
public let WKPreviewActionItemIdentifierCopy = "WKPreviewActionItemIdentifierCopy"
public let WKPreviewActionItemIdentifierOpen = "WKPreviewActionItemIdentifierOpen"
public let WKPreviewActionItemIdentifierShare = "WKPreviewActionItemIdentifierShare"

public let WKWebsiteDataTypeHashSalt = "WKWebsiteDataTypeHashSalt"
public let WKWebsiteDataTypeMediaKeys = "WKWebsiteDataTypeMediaKeys"
public let WKWebsiteDataTypeScreenTime = "WKWebsiteDataTypeScreenTime"
public let WKWebsiteDataTypeSearchFieldRecentSearches =
    "WKWebsiteDataTypeSearchFieldRecentSearches"

public struct URLScheme: Hashable, Sendable, RawRepresentable {
    public let rawValue: String

    public init?(rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        self.rawValue = trimmed.lowercased()
    }

    @MainActor
    public init?(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }
}
