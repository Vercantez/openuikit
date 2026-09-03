import Foundation

/// Tip grouping without SwiftUI `Tip` existentials on this isolated host.
/// `currentTip` / builder init remain gated until a real SwiftUI `Tip` exists.
public final class TipGroup: @unchecked Sendable {
    public enum Priority: Hashable, Sendable {
        case firstAvailable
        case ordered
    }

    public let priority: Priority

    public init(_ priority: Priority = .firstAvailable) {
        self.priority = priority
    }
}
