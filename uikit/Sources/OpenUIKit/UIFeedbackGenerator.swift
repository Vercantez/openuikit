// Portable feedback generator. Hosts may bind `onImpact`; without a hardware
// haptic backend the generator still has deterministic preparation and event
// semantics for application logic and tests.

@preconcurrency @MainActor
open class UIFeedbackGenerator {
    public fileprivate(set) var isPrepared = false

    public init() {}

    open func prepare() { isPrepared = true }
}

@preconcurrency @MainActor
open class UIImpactFeedbackGenerator: UIFeedbackGenerator {
    public enum FeedbackStyle: Int, Sendable {
        case light = 0
        case medium = 1
        case heavy = 2
        case soft = 3
        case rigid = 4
    }

    public struct Impact: Sendable, Equatable {
        public let style: FeedbackStyle
        public let intensity: CGFloat
    }

    /// Optional host binding. Called synchronously exactly once per impact.
    public static var onImpact: ((Impact) -> Void)?
    public private(set) static var lastImpact: Impact?

    public let style: FeedbackStyle

    public init(style: FeedbackStyle) {
        self.style = style
        super.init()
    }

    open func impactOccurred() { impactOccurred(intensity: 1) }

    open func impactOccurred(intensity: CGFloat) {
        let event = Impact(style: style, intensity: min(1, max(0, intensity)))
        Self.lastImpact = event
        isPrepared = false
        Self.onImpact?(event)
    }
}
