import Foundation

/// Ordered or first-available grouping of `Tip` values.
///
/// `currentTip` is the first grouped tip whose `shouldDisplay` is true. Linux
/// does not present UI; this is eligibility only. `firstAvailable` and
/// `ordered` currently share that scan order because there is no display-history
/// oracle for a different first-available ranking.
public final class TipGroup: @unchecked Sendable {
    public enum Priority: Hashable, Sendable {
        case firstAvailable
        case ordered
    }

    public let priority: Priority
    private let tips: [any Tip]

    public init(
        _ priority: Priority = .firstAvailable,
        @Tips.GroupBuilder _ builder: () -> [any Tip] = { [] }
    ) {
        self.priority = priority
        self.tips = builder()
    }

    func currentTipValue() -> (any Tip)? {
        tips.first { $0.shouldDisplay }
    }

    @MainActor
    public var currentTip: (any Tip)? {
        currentTipValue()
    }

    public var currentTipUpdates: some AsyncSequence<any Tip, Never> {
        AsyncStream { continuation in
            if let tip = self.currentTipValue() {
                continuation.yield(tip)
            }
            let token = TipsStore.shared.addStatusListener { [weak self] in
                if let tip = self?.currentTipValue() {
                    continuation.yield(tip)
                }
            }
            continuation.onTermination = { _ in
                TipsStore.shared.removeStatusListener(token)
            }
        }
    }
}
