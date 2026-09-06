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

public extension IntentResult {
    static func result<Content: View>(
        view: Content
    ) -> IntentResultContainer<Never, Never, _SnippetViewContainer, Never>
    where Self == IntentResultContainer<Never, Never, _SnippetViewContainer, Never> {
        _ = view
        return IntentResultContainer()
    }

    static func result<Value: _IntentValue, Content: View>(
        value: Value,
        view: Content
    ) -> IntentResultContainer<Value, Never, _SnippetViewContainer, Never>
    where Self == IntentResultContainer<Value, Never, _SnippetViewContainer, Never> {
        _ = view
        return IntentResultContainer(value: value)
    }

    static func result<Value: _IntentValue, Content: View>(
        value: Value,
        dialog: IntentDialog,
        view: Content
    ) -> IntentResultContainer<Value, Never, _SnippetViewContainer, IntentDialog>
    where Self == IntentResultContainer<Value, Never, _SnippetViewContainer, IntentDialog> {
        _ = view
        return IntentResultContainer(value: value, dialog: dialog)
    }

    static func result<Content: View>(
        content: () -> Content
    ) -> IntentResultContainer<Never, Never, _SnippetViewContainer, Never>
    where Self == IntentResultContainer<Never, Never, _SnippetViewContainer, Never> {
        _ = content()
        return IntentResultContainer()
    }

    static func result<Content: View>(
        opensIntent: some AppIntent,
        view: Content
    ) -> IntentResultContainer<Never, Never, _SnippetViewContainer, Never>
    where Self == IntentResultContainer<Never, Never, _SnippetViewContainer, Never> {
        _ = view
        return IntentResultContainer(opensIntent: opensIntent)
    }

    static func result<OpensAppIntent: AppIntent, Content: View>(
        opensIntent: OpensAppIntent,
        view: Content
    ) -> IntentResultContainer<Never, OpensAppIntent, _SnippetViewContainer, Never>
    where Self == IntentResultContainer<Never, OpensAppIntent, _SnippetViewContainer, Never> {
        _ = view
        return IntentResultContainer(opensIntent: opensIntent)
    }

    static func result<Content: View>(
        opensIntent: some AppIntent,
        dialog: IntentDialog,
        view: Content
    ) -> IntentResultContainer<Never, Never, _SnippetViewContainer, IntentDialog>
    where Self == IntentResultContainer<Never, Never, _SnippetViewContainer, IntentDialog> {
        _ = view
        return IntentResultContainer(dialog: dialog, opensIntent: opensIntent)
    }

    static func result<OpensAppIntent: AppIntent, Content: View>(
        opensIntent: OpensAppIntent,
        dialog: IntentDialog,
        view: Content
    ) -> IntentResultContainer<Never, OpensAppIntent, _SnippetViewContainer, IntentDialog>
    where Self == IntentResultContainer<Never, OpensAppIntent, _SnippetViewContainer, IntentDialog> {
        _ = view
        return IntentResultContainer(dialog: dialog, opensIntent: opensIntent)
    }

    static func result<Content: View>(
        opensIntent: some AppIntent,
        dialog: IntentDialog,
        content: () -> Content
    ) -> IntentResultContainer<Never, Never, _SnippetViewContainer, IntentDialog>
    where Self == IntentResultContainer<Never, Never, _SnippetViewContainer, IntentDialog> {
        _ = content()
        return IntentResultContainer(dialog: dialog, opensIntent: opensIntent)
    }

    static func result<OpensAppIntent: AppIntent, Content: View>(
        opensIntent: OpensAppIntent,
        dialog: IntentDialog,
        content: () -> Content
    ) -> IntentResultContainer<Never, OpensAppIntent, _SnippetViewContainer, IntentDialog>
    where Self == IntentResultContainer<Never, OpensAppIntent, _SnippetViewContainer, IntentDialog> {
        _ = content()
        return IntentResultContainer(dialog: dialog, opensIntent: opensIntent)
    }

    static func result<Content: View>(
        opensIntent: some AppIntent,
        content: () -> Content
    ) -> IntentResultContainer<Never, Never, _SnippetViewContainer, Never>
    where Self == IntentResultContainer<Never, Never, _SnippetViewContainer, Never> {
        _ = content()
        return IntentResultContainer(opensIntent: opensIntent)
    }

    static func result<OpensAppIntent: AppIntent, Content: View>(
        opensIntent: OpensAppIntent,
        content: () -> Content
    ) -> IntentResultContainer<Never, OpensAppIntent, _SnippetViewContainer, Never>
    where Self == IntentResultContainer<Never, OpensAppIntent, _SnippetViewContainer, Never> {
        _ = content()
        return IntentResultContainer(opensIntent: opensIntent)
    }

    static func result<Value: _IntentValue, Content: View>(
        value: Value,
        opensIntent: some AppIntent,
        view: Content
    ) -> IntentResultContainer<Value, Never, _SnippetViewContainer, Never>
    where Self == IntentResultContainer<Value, Never, _SnippetViewContainer, Never> {
        _ = view
        return IntentResultContainer(value: value, opensIntent: opensIntent)
    }

    static func result<Value: _IntentValue, OpensAppIntent: AppIntent, Content: View>(
        value: Value,
        opensIntent: OpensAppIntent,
        view: Content
    ) -> IntentResultContainer<Value, OpensAppIntent, _SnippetViewContainer, Never>
    where Self == IntentResultContainer<Value, OpensAppIntent, _SnippetViewContainer, Never> {
        _ = view
        return IntentResultContainer(value: value, opensIntent: opensIntent)
    }

    static func result<Value: _IntentValue, Content: View>(
        value: Value,
        opensIntent: some AppIntent,
        dialog: IntentDialog,
        view: Content
    ) -> IntentResultContainer<Value, Never, _SnippetViewContainer, IntentDialog>
    where Self == IntentResultContainer<Value, Never, _SnippetViewContainer, IntentDialog> {
        _ = view
        return IntentResultContainer(value: value, dialog: dialog, opensIntent: opensIntent)
    }

    static func result<Value: _IntentValue, OpensAppIntent: AppIntent, Content: View>(
        value: Value,
        opensIntent: OpensAppIntent,
        dialog: IntentDialog,
        view: Content
    ) -> IntentResultContainer<Value, OpensAppIntent, _SnippetViewContainer, IntentDialog>
    where Self == IntentResultContainer<Value, OpensAppIntent, _SnippetViewContainer, IntentDialog> {
        _ = view
        return IntentResultContainer(value: value, dialog: dialog, opensIntent: opensIntent)
    }

    static func result<Value: _IntentValue, Content: View>(
        value: Value,
        opensIntent: some AppIntent,
        dialog: IntentDialog,
        content: () -> Content
    ) -> IntentResultContainer<Value, Never, _SnippetViewContainer, IntentDialog>
    where Self == IntentResultContainer<Value, Never, _SnippetViewContainer, IntentDialog> {
        _ = content()
        return IntentResultContainer(value: value, dialog: dialog, opensIntent: opensIntent)
    }

    static func result<Value: _IntentValue, OpensAppIntent: AppIntent, Content: View>(
        value: Value,
        opensIntent: OpensAppIntent,
        dialog: IntentDialog,
        content: () -> Content
    ) -> IntentResultContainer<Value, OpensAppIntent, _SnippetViewContainer, IntentDialog>
    where Self == IntentResultContainer<Value, OpensAppIntent, _SnippetViewContainer, IntentDialog> {
        _ = content()
        return IntentResultContainer(value: value, dialog: dialog, opensIntent: opensIntent)
    }

    static func result<Value: _IntentValue, Content: View>(
        value: Value,
        opensIntent: some AppIntent,
        content: () -> Content
    ) -> IntentResultContainer<Value, Never, _SnippetViewContainer, Never>
    where Self == IntentResultContainer<Value, Never, _SnippetViewContainer, Never> {
        _ = content()
        return IntentResultContainer(value: value, opensIntent: opensIntent)
    }

    static func result<Value: _IntentValue, OpensAppIntent: AppIntent, Content: View>(
        value: Value,
        opensIntent: OpensAppIntent,
        content: () -> Content
    ) -> IntentResultContainer<Value, OpensAppIntent, _SnippetViewContainer, Never>
    where Self == IntentResultContainer<Value, OpensAppIntent, _SnippetViewContainer, Never> {
        _ = content()
        return IntentResultContainer(value: value, opensIntent: opensIntent)
    }

    static func result<Content: View>(
        dialog: IntentDialog,
        view: Content
    ) -> IntentResultContainer<Never, Never, _SnippetViewContainer, IntentDialog>
    where Self == IntentResultContainer<Never, Never, _SnippetViewContainer, IntentDialog> {
        _ = view
        return IntentResultContainer(dialog: dialog)
    }

    static func result<Content: View>(
        dialog: IntentDialog,
        content: () -> Content
    ) -> IntentResultContainer<Never, Never, _SnippetViewContainer, IntentDialog>
    where Self == IntentResultContainer<Never, Never, _SnippetViewContainer, IntentDialog> {
        _ = content()
        return IntentResultContainer(dialog: dialog)
    }
}

extension IntentParameterContext {
    public func requestConfirmation<ViewType: View>(
        for itemToConfirm: Value.ValueType,
        dialog: IntentDialog? = nil,
        view: ViewType
    ) async throws -> Bool {
        _ = itemToConfirm
        _ = dialog
        _ = view
        throw AppIntentError.Unrecoverable.unsupportedOnDevice
    }

    public func requestConfirmation<ViewType: View>(
        for itemToConfirm: Value.ValueType,
        dialog: IntentDialog? = nil,
        @ViewBuilder view: () -> ViewType
    ) async throws -> Bool {
        _ = itemToConfirm
        _ = dialog
        _ = view()
        throw AppIntentError.Unrecoverable.unsupportedOnDevice
    }
}


