import Foundation

// Isolated-host lookalikes for types owned by modules this seed does not
// declare as dependencies. The EC2 identity probe imports Foundation only.

// NOTE (2026-09-15): the stand-ins below are also used on Apple hosts.
// No product file imports CoreGraphics, so the real CGColor (which is not
// Hashable/Codable and would break Artwork) is never pulled in; the
// isolated-host semantics stay identical on Linux and macOS.
#if !canImport(CoreGraphics) || os(macOS)
public struct CGColor: Hashable, Sendable {
    public var red: CGFloat
    public var green: CGFloat
    public var blue: CGFloat
    public var alpha: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}
#endif

// Same host-portability note as above: MusicPlayer.State/Queue rely on the
// zero-argument AnyPublisher() initializer, which real Combine does not
// provide, so the stand-in is used on Apple hosts too.
#if !canImport(Combine) || os(macOS)
public struct AnyPublisher<Output, Failure: Error>: Sendable {
    public init() {}
}

public protocol ObservableObject: AnyObject {
    associatedtype ObjectWillChangePublisher
    var objectWillChange: ObjectWillChangePublisher { get }
}
#endif

// Same host-portability note as above: ArtworkImage and the
// musicSubscriptionOffer overlay compile against the stand-in View on
// Apple hosts (SwiftUI overlays stay not-applicable in coverage).
#if !canImport(SwiftUI) || os(macOS)
public protocol View {
    associatedtype Body: View
    var body: Body { get }
}

public struct EmptyView: View {
    public init() {}
    public var body: EmptyView { self }
}

@resultBuilder
public enum ViewBuilder {
    public static func buildBlock() -> EmptyView { EmptyView() }
    public static func buildBlock<Content: View>(_ content: Content) -> Content { content }
}

@propertyWrapper
public struct Binding<Value> {
    public var wrappedValue: Value
    public var projectedValue: Binding<Value> { self }

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
        wrappedValue = get()
        _ = set
    }

    public static func constant(_ value: Value) -> Binding<Value> {
        Binding(wrappedValue: value)
    }
}
#endif
