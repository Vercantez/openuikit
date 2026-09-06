import Foundation

public protocol BEScrollViewDelegate: UIScrollViewDelegate {
    func parentScrollView(for scrollView: BEScrollView) -> BEScrollView?
    func scrollView(
        _ scrollView: BEScrollView,
        handle scrollUpdate: BEScrollViewScrollUpdate
    ) async -> Bool
}

extension BEScrollViewDelegate {
    public func parentScrollView(for scrollView: BEScrollView) -> BEScrollView? {
        _ = scrollView
        return nil
    }

    /// Linux has no compositor-driven nested scroll handoff. Always `false`.
    public func scrollView(
        _ scrollView: BEScrollView,
        handle scrollUpdate: BEScrollViewScrollUpdate
    ) async -> Bool {
        _ = scrollView
        _ = scrollUpdate
        return false
    }
}

public final class BEScrollView: UIScrollView, @unchecked Sendable {
    public weak var delegate: (any BEScrollViewDelegate)?

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
    }
}

public final class BEScrollViewScrollUpdate: NSObject, @unchecked Sendable {
    public enum Phase: Int, Equatable, Hashable, Sendable {
        case began = 0
        case changed = 1
        case ended = 2
        case cancelled = 3
    }

    public let timestamp: TimeInterval
    public let phase: Phase
    public let location: CGPoint
    public let translation: CGPoint

    public static func host_make(
        timestamp: TimeInterval,
        phase: Phase,
        location: CGPoint,
        translation: CGPoint
    ) -> BEScrollViewScrollUpdate {
        BEScrollViewScrollUpdate(
            timestamp: timestamp,
            phase: phase,
            location: location,
            translation: translation
        )
    }

    private init(
        timestamp: TimeInterval,
        phase: Phase,
        location: CGPoint,
        translation: CGPoint
    ) {
        self.timestamp = timestamp
        self.phase = phase
        self.location = location
        self.translation = translation
        super.init()
    }

    public func location(in view: UIView?) -> CGPoint {
        _ = view
        return location
    }

    public func translation(in view: UIView?) -> CGPoint {
        _ = view
        return translation
    }
}
