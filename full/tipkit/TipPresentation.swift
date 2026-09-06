import Foundation

/// Linux configuration model for Apple's `TipViewStyleConfiguration`.
/// SwiftUI `Text` / `Image` presentation fields are omitted; `tip` and
/// `actions` are the Foundation surface that can be truthful here.
public struct TipViewStyleConfiguration: Sendable {
    public let tip: any Tip

    public init(tip: any Tip) {
        self.tip = tip
    }

    public var actions: [Tips.Action] { tip.actions }
}

/// Linux configuration protocol. `Body` is unconstrained because this host
/// has no SwiftUI `View`.
public protocol TipViewStyle {
    associatedtype Body
    typealias Configuration = TipViewStyleConfiguration
    func makeBody(configuration: Self.Configuration) -> Self.Body
}

public struct MiniTipViewStyle: TipViewStyle {
    public typealias Body = TipViewStyleConfiguration

    public init() {}

    public func makeBody(
        configuration: MiniTipViewStyle.Configuration
    ) -> MiniTipViewStyle.Body {
        configuration
    }
}

extension TipViewStyle where Self == MiniTipViewStyle {
    public static var miniTip: MiniTipViewStyle { MiniTipViewStyle() }
}

/// Linux configuration model for Apple's `TipView`. It holds a tip and an
/// action handler; it does not produce a SwiftUI `View` body.
public struct TipView<Content: Tip> {
    public let tip: Content?
    public let actionHandler: (Tips.Action) -> Void

    public init(
        _ tip: Content?,
        action: @escaping (Tips.Action) -> Void = { _ in }
    ) {
        self.tip = tip
        self.actionHandler = action
    }
}

extension TipView where Content == AnyTip {
    public init(
        _ tip: (any Tip)?,
        action: @escaping (Tips.Action) -> Void = { _ in }
    ) {
        self.tip = tip.map(AnyTip.init)
        self.actionHandler = action
    }
}

/// Linux configuration model. Not a `UIView`; stores tip, style, and layout
/// numbers that a host can apply. UIKit `UIColor` / SwiftUI `ShapeStyle` /
/// `Edge` members stay omitted.
public final class TipUIView: @unchecked Sendable {
    public let tip: any Tip
    public var cornerRadius: CGFloat
    public var imageSize: CGSize
    public var viewStyle: any TipViewStyle
    public let actionHandler: (Tips.Action) -> Void

    public init(
        _ tip: any Tip,
        actionHandler: @escaping (Tips.Action) -> Void = { _ in }
    ) {
        self.tip = tip
        self.cornerRadius = 0
        self.imageSize = CGSize(width: 0, height: 0)
        self.viewStyle = MiniTipViewStyle()
        self.actionHandler = actionHandler
    }
}

/// Linux configuration model. Not a `UICollectionViewCell`.
public final class TipUICollectionViewCell: @unchecked Sendable {
    public var frame: CGRect
    public var tip: (any Tip)?
    public var cornerRadius: CGFloat
    public var imageSize: CGSize
    public var viewStyle: any TipViewStyle
    public var actionHandler: (Tips.Action) -> Void

    public init(frame: CGRect) {
        self.frame = frame
        self.tip = nil
        self.cornerRadius = 0
        self.imageSize = CGSize(width: 0, height: 0)
        self.viewStyle = MiniTipViewStyle()
        self.actionHandler = { _ in }
    }

    public init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    @discardableResult
    public func configureTip(
        _ tip: any Tip,
        actionHandler: @escaping (Tips.Action) -> Void = { _ in }
    ) -> Self {
        self.tip = tip
        self.actionHandler = actionHandler
        return self
    }
}

/// Linux configuration model. Not a `UICollectionReusableView`.
public final class TipUICollectionReusableView: @unchecked Sendable {
    public var frame: CGRect
    public var tip: (any Tip)?
    public var cornerRadius: CGFloat
    public var imageSize: CGSize
    public var viewStyle: any TipViewStyle
    public var actionHandler: (Tips.Action) -> Void

    public init(frame: CGRect) {
        self.frame = frame
        self.tip = nil
        self.cornerRadius = 0
        self.imageSize = CGSize(width: 0, height: 0)
        self.viewStyle = MiniTipViewStyle()
        self.actionHandler = { _ in }
    }

    public init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    @discardableResult
    public func configureTip(
        _ tip: any Tip,
        actionHandler: @escaping (Tips.Action) -> Void = { _ in }
    ) -> Self {
        self.tip = tip
        self.actionHandler = actionHandler
        return self
    }
}

/// Linux configuration model. Not a `UIViewController`; stores nib identity
/// and a tip. UIKit popover source items stay omitted.
public final class TipUIPopoverViewController: @unchecked Sendable {
    public let nibName: String?
    public let bundle: Bundle?
    public var tip: (any Tip)?
    public var imageSize: CGSize
    public var viewStyle: any TipViewStyle
    public var actionHandler: (Tips.Action) -> Void

    public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.nibName = nibNameOrNil
        self.bundle = nibBundleOrNil
        self.tip = nil
        self.imageSize = CGSize(width: 0, height: 0)
        self.viewStyle = MiniTipViewStyle()
        self.actionHandler = { _ in }
    }

    public init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public func configure(
        _ tip: any Tip,
        actionHandler: @escaping (Tips.Action) -> Void = { _ in }
    ) {
        self.tip = tip
        self.actionHandler = actionHandler
    }
}
