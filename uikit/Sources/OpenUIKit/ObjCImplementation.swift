// The Objective-C implementation route (Darwin, OPENUIKIT_OBJC_IMPLEMENTATION
// set by Package.swift): UIResponder / UIView / UIWindow are DECLARED in
// Objective-C (Sources/OpenUIKitObjC/include) and implemented in Swift with
// SE-0436 `@objc @implementation`, so an Objective-C app class can subclass
// them (docs/agent_reports/objc-implementation-spike.md measured the shape,
// docs/agent_reports/objc-impl-chain1.md ports the first chain).
//
// Re-exporting the declaration module is what keeps `OpenUIKit.UIView` the
// name every client — the 89 Swift subclasses, the 13 `extension UIView`
// files, SwiftUI hosting, the real-app screens — has always used.
#if OPENUIKIT_OBJC_IMPLEMENTATION
@_exported import OpenUIKitObjC
// Scoped, like every sibling: the guest-route gate refuses a bare
// `import Foundation` in a library source even under this route's flag.
import class Foundation.NSObject

// MARK: - UITraitCollection in Objective-C signatures

/// `UITraitCollection` is a Swift struct (486 uses, mutated in place at 7
/// sites). `UIView.traitCollectionDidChange(_:)` is overridden by real app
/// source, so it must stay an overridable `@objc` member, and an `@objc`
/// signature needs an Objective-C-representable type. Bridging the struct
/// (`_ObjectiveCBridgeable`, the mechanism behind String/Array/URL in @objc
/// signatures) gives Objective-C a `UITraitCollection` class object and
/// leaves every Swift use of the struct untouched. Converting the struct to
/// a class is the recorded follow-up.
@objc(UITraitCollection)
public final class _UITraitCollectionObjC: NSObject {
    public let value: UITraitCollection
    public init(_ value: UITraitCollection) { self.value = value }

    nonisolated public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? _UITraitCollectionObjC else { return false }
        return other.value == value
    }
    nonisolated public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(value.userInterfaceStyle == .dark)
        hasher.combine(value.displayScale)
        hasher.combine(value.horizontalSizeClass.rawValue)
        hasher.combine(value.verticalSizeClass.rawValue)
        return hasher.finalize()
    }
}

extension UITraitCollection: _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = _UITraitCollectionObjC

    public func _bridgeToObjectiveC() -> _UITraitCollectionObjC {
        _UITraitCollectionObjC(self)
    }
    public static func _forceBridgeFromObjectiveC(
        _ source: _UITraitCollectionObjC, result: inout UITraitCollection?
    ) {
        result = source.value
    }
    public static func _conditionallyBridgeFromObjectiveC(
        _ source: _UITraitCollectionObjC, result: inout UITraitCollection?
    ) -> Bool {
        result = source.value
        return true
    }
    public static func _unconditionallyBridgeFromObjectiveC(
        _ source: _UITraitCollectionObjC?
    ) -> UITraitCollection {
        source?.value ?? UITraitCollection()
    }
}

// MARK: - UIEdgeInsets is the C struct from UIGeometry.h

extension UIEdgeInsets: Equatable {
    public init(top: CGFloat = 0, left: CGFloat = 0,
                bottom: CGFloat = 0, right: CGFloat = 0) {
        self.init()
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }
    public static let zero = UIEdgeInsets()
    public static func == (a: UIEdgeInsets, b: UIEdgeInsets) -> Bool {
        a.top == b.top && a.left == b.left && a.bottom == b.bottom && a.right == b.right
    }
}
#endif
