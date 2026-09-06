// Portable feedback generators. There is no haptic hardware on a Linux
// guest; the honest shape is a call-recording no-op with UIKit's API.
//
// MEASURED ValuesProbe, iPhone SE 3rd gen / iOS 26.1
// (`OpenUIKit-2x-uikit-tail-values`):
//   `UIImpactFeedbackGenerator(style:view:)` attaches as a UIInteraction
//   (`view.interactions` contains the generator).
//   `FeedbackStyle.medium.rawValue == 1`.
//   `UINotificationFeedbackGenerator.FeedbackType` is success=0, warning=1,
//   error=2.
//   `init(view:)` is the iOS 17.5 Swift name of `+feedbackGeneratorForView:`
//   (UIFeedbackGenerator.h); impact also has `init(style:view:)`.
//   `impactOccurred(intensity:at:)` / `notificationOccurred(_:at:)` /
//   `selectionChanged(at:)` compile and return. Intensity is clamped to
//   [0, 1] by this recording backend (portable; hardware clip is
//   unobservable).

#if canImport(Foundation)
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif

@preconcurrency @MainActor
open class UIFeedbackGenerator: NSObject, UIInteraction {
    public fileprivate(set) var isPrepared = false
    public private(set) weak var view: UIView?

    /// Deprecated UIKit spelling (`init` / iOS 10). Prefer `init(view:)`.
    public override init() {
        super.init()
    }

    /// iOS 17.5 `+feedbackGeneratorForView:` → Swift `init(view:)`.
    /// MEASURED ValuesProbe: the generator is in `view.interactions`.
    public init(view: UIView) {
        super.init()
        view.addInteraction(self)
    }

    open func prepare() { isPrepared = true }

    public func willMove(to view: UIView?) {}

    public func didMove(to view: UIView?) {
        self.view = view
    }
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
        public let location: CGPoint?
        public init(style: FeedbackStyle, intensity: CGFloat,
                    location: CGPoint? = nil) {
            self.style = style
            self.intensity = intensity
            self.location = location
        }
    }

    /// Optional host binding. Called synchronously exactly once per impact.
    public static var onImpact: ((Impact) -> Void)?
    public private(set) static var lastImpact: Impact?

    public let style: FeedbackStyle

    /// Deprecated UIKit spelling (`initWithStyle:`). Prefer `init(style:view:)`.
    public init(style: FeedbackStyle) {
        self.style = style
        super.init()
    }

    /// iOS 17.5 `+feedbackGeneratorWithStyle:forView:`.
    public init(style: FeedbackStyle, view: UIView) {
        self.style = style
        super.init(view: view)
    }

    /// Inherited `init(view:)` has no style argument. UIKit still vends it
    /// through the superclass factory; the style stored here is `.medium`
    /// (rawValue 1, the original iOS 10 default case). Unmeasured which
    /// style the hardware uses for this spelling — recorded as OPEN.
    public override init(view: UIView) {
        self.style = .medium
        super.init(view: view)
    }

    open func impactOccurred() { impactOccurred(intensity: 1) }

    open func impactOccurred(at location: CGPoint) {
        impactOccurred(intensity: 1, at: location)
    }

    open func impactOccurred(intensity: CGFloat) {
        record(intensity: intensity, location: nil)
    }

    open func impactOccurred(intensity: CGFloat, at location: CGPoint) {
        record(intensity: intensity, location: location)
    }

    private func record(intensity: CGFloat, location: CGPoint?) {
        let event = Impact(style: style,
                           intensity: min(1, max(0, intensity)),
                           location: location)
        Self.lastImpact = event
        isPrepared = false
        Self.onImpact?(event)
    }
}

@preconcurrency @MainActor
open class UINotificationFeedbackGenerator: UIFeedbackGenerator {
    public enum FeedbackType: Int, Sendable {
        case success = 0
        case warning = 1
        case error = 2
    }

    public struct Notification: Sendable, Equatable {
        public let type: FeedbackType
        public let location: CGPoint?
        public init(type: FeedbackType, location: CGPoint? = nil) {
            self.type = type
            self.location = location
        }
    }

    public static var onNotification: ((Notification) -> Void)?
    public private(set) static var lastNotification: Notification?

    open func notificationOccurred(_ notificationType: FeedbackType) {
        record(notificationType, location: nil)
    }

    open func notificationOccurred(_ notificationType: FeedbackType,
                                   at location: CGPoint) {
        record(notificationType, location: location)
    }

    private func record(_ type: FeedbackType, location: CGPoint?) {
        let event = Notification(type: type, location: location)
        Self.lastNotification = event
        isPrepared = false
        Self.onNotification?(event)
    }
}

@preconcurrency @MainActor
open class UISelectionFeedbackGenerator: UIFeedbackGenerator {
    public struct Selection: Sendable, Equatable {
        public let location: CGPoint?
        public init(location: CGPoint? = nil) { self.location = location }
    }

    public static var onSelection: ((Selection) -> Void)?
    public private(set) static var lastSelection: Selection?

    open func selectionChanged() { record(location: nil) }

    open func selectionChanged(at location: CGPoint) {
        record(location: location)
    }

    private func record(location: CGPoint?) {
        let event = Selection(location: location)
        Self.lastSelection = event
        isPrepared = false
        Self.onSelection?(event)
    }
}
