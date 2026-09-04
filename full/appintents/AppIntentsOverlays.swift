import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(UIKit)
import UIKit
#endif

public struct SiriTipView: View {
    public init<Intent>(intent: Intent, isVisible: Binding<Bool>? = nil) where Intent: AppIntent {
        _ = intent
        _ = isVisible
    }
    public var body: some View { EmptyView() }
}

public struct SiriTipViewStyle: Hashable, Sendable {
    private let token: UInt8

    public static let dark = SiriTipViewStyle(token: 0)
    public static let light = SiriTipViewStyle(token: 1)
    public static let automatic = SiriTipViewStyle(token: 2)

    public init() {
        self.token = 2
    }

    private init(token: UInt8) {
        self.token = token
    }
}

public struct ShortcutsLink: View {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct ShortcutsLinkStyle: Hashable, Sendable {
    public static let automatic = ShortcutsLinkStyle()
    public init() {}
}

public final class ShortcutsUIButton: UIButton, @unchecked Sendable {
    public var style: ShortcutsLinkStyle = .automatic
    public init(style: ShortcutsLinkStyle = .automatic) {
        self.style = style
        super.init()
    }
    public override func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        super.addTarget(target, action: action, for: controlEvents)
    }
    public override func sizeThatFits(_ size: CGSize) -> CGSize { size }
}

public final class SiriTipUIView: UIView, @unchecked Sendable {
    public var isPresented: Bool = false
    public var allowsDismissal: Bool = true
    public var style: SiriTipViewStyle = .automatic
    public init(style: SiriTipViewStyle = .automatic) {
        self.style = style
        super.init()
    }
    public override func didMoveToWindow() { super.didMoveToWindow() }
    public override func sizeThatFits(_ size: CGSize) -> CGSize { size }
    public override var intrinsicContentSize: CGSize { .zero }
    public func setIntent<Intent>(intent: Intent) where Intent: AppIntent {
        _ = intent
    }
}

