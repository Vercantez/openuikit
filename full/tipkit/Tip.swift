import Foundation

/// Linux `Tip` engine without SwiftUI `Text` / `Image` requirements.
///
/// Apple's protocol also has `title: Text`, `message: Text?`, and
/// `image: Image?`. Those members stay omitted here because this isolated
/// host has no SwiftUI module and this port does not substitute TipKit-owned
/// lookalikes for those identities.
public protocol Tip: Identifiable, Sendable {
    var id: String { get }
    @Tips.RuleBuilder var rules: [Self.Rule] { get }
    @Tips.ActionBuilder var actions: [Self.Action] { get }
    @Tips.OptionsBuilder var options: [any TipOption] { get }
}

extension Tip {
    public typealias Status = Tips.Status
    public typealias InvalidationReason = Tips.InvalidationReason
    public typealias Action = Tips.Action
    public typealias Rule = Tips.Rule
    public typealias Event = Tips.Event
    public typealias Option = TipOption
    public typealias IgnoresDisplayFrequency = Tips.IgnoresDisplayFrequency
    public typealias MaxDisplayCount = Tips.MaxDisplayCount
    public typealias MaxDisplayDuration = Tips.MaxDisplayDuration

    public var id: String { String(describing: Self.self) }

    public var rules: [Self.Rule] { return [] }

    public var actions: [Self.Action] { return [] }

    public var options: [any TipOption] { return [] }

    public var status: Self.Status {
        TipsStore.shared.status(
            id: id,
            typeKey: String(describing: Self.self),
            rules: rules
        )
    }

    public var shouldDisplay: Bool {
        TipsStore.shared.shouldDisplay(
            id: id,
            typeKey: String(describing: Self.self),
            rules: rules
        )
    }

    public var statusUpdates: AsyncStream<Self.Status> {
        let id = self.id
        let typeKey = String(describing: Self.self)
        let rules = self.rules
        return AsyncStream { continuation in
            continuation.yield(
                TipsStore.shared.status(id: id, typeKey: typeKey, rules: rules)
            )
            let token = TipsStore.shared.addStatusListener {
                continuation.yield(
                    TipsStore.shared.status(id: id, typeKey: typeKey, rules: rules)
                )
            }
            continuation.onTermination = { _ in
                TipsStore.shared.removeStatusListener(token)
            }
        }
    }

    public var shouldDisplayUpdates:
        AsyncMapSequence<AsyncStream<Self.Status>, Bool>
    {
        statusUpdates.map { status in
            if case .available = status {
                return true
            }
            return false
        }
    }

    public func invalidate(reason: Self.InvalidationReason) {
        TipsStore.shared.invalidate(id: id, reason: reason)
    }

    public func resetEligibility() async {
        TipsStore.shared.resetEligibility(id: id)
    }
}

extension Tip {
    @_spi(OpenUIKitHost)
    public func recordDisplayForHost() {
        let maxCount = options.compactMap { $0 as? Tips.MaxDisplayCount }
            .map(\.maxDisplayCount)
            .first
        TipsStore.shared.recordDisplay(id: id, maxDisplayCount: maxCount)
    }
}

/// Type-erased `Tip` that forwards identity, rules, actions, and options.
/// Presentation (`title` / `message` / `image`) remains gated with the SwiftUI
/// members on `Tip`.
public struct AnyTip: Tip {
    public typealias ID = String

    private let base: any Tip

    public init(_ tip: any Tip) {
        self.base = tip
    }

    public var id: String { base.id }

    public var rules: [Tips.Rule] { return base.rules }

    public var actions: [Tips.Action] { return base.actions }

    public var options: [any TipOption] { return base.options }
}
