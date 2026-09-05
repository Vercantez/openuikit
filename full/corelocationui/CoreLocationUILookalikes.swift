@_exported import Foundation

// Isolated-host stand-ins for UIKit and SwiftUI types named by the public
// CoreLocationUI surface. The sealed host gate compiles this module alone.
// When a real `UIKit` / `SwiftUI` module is on the link line, these blocks
// compile out. They are not a Linux UIKit or SwiftUI port.

#if !canImport(UIKit)

open class UIView: NSObject {
    public var frame: CGRect

    public init(frame: CGRect = .zero) {
        self.frame = frame
        super.init()
    }
}

open class UIControl: UIView {
    public struct Event: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        /// Apple's `UIControl.Event.touchUpInside` is `1 << 6`.
        public static let touchUpInside = Event(rawValue: 1 << 6)
    }

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
    }

    /// Isolated-host no-op. Darwin dispatches registered targets. Linux does
    /// not invent a control-event delivery path for location authorization.
    open func sendActions(for controlEvents: Event) {
        _ = controlEvents
    }
}

#endif

#if !canImport(SwiftUI)

public protocol View {
    associatedtype Body: View
    var body: Body { get }
}

@resultBuilder
public enum ViewBuilder {
    public static func buildBlock() -> EmptyView {
        EmptyView()
    }

    public static func buildBlock<Content: View>(_ content: Content) -> Content {
        content
    }

    public static func buildExpression<Content: View>(_ content: Content) -> Content {
        content
    }
}

public struct EmptyView: View {
    public init() {}
    public var body: Never { preconditionFailure("EmptyView has no body") }
}

extension Never: View {
    public var body: Never { preconditionFailure("Never has no body") }
}

#endif
