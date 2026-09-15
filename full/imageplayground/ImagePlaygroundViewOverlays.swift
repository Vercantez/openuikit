import Foundation

// Linux-host identity overlays for the ImagePlayground SwiftUI surface.
// Compiled only when SwiftUI is absent (isolated host). When a real
// SwiftUI module is on the link line this block compiles out; see
// ImagePlaygroundDependentSurface.swift for the Darwin extensions.
// Linux has no SwiftUI layout engine, sheet presentation, or environment
// propagation, so every modifier returns `self` and every environment
// value reports the same host default as the Darwin extension. These are
// not a Linux SwiftUI port.

#if !canImport(SwiftUI)

public protocol View {
    associatedtype Body: View
    var body: Body { get }
}

public struct EmptyView: View {
    public init() {}
    public var body: Never { preconditionFailure("EmptyView has no body") }
}

extension Never: View {
    public var body: Never { preconditionFailure("Never has no body") }
}

@propertyWrapper
public struct Binding<Value> {
    private let getter: () -> Value
    private let setter: (Value) -> Void

    public var wrappedValue: Value {
        get { getter() }
        nonmutating set { setter(newValue) }
    }

    public var projectedValue: Binding<Value> { self }

    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
        self.getter = get
        self.setter = set
    }

    public static func constant(_ value: Value) -> Binding<Value> {
        Binding(get: { value }, set: { _ in })
    }
}

/// Opaque image stand-in for the `sourceImage: Image?` sheet parameters.
/// Linux never decodes or renders image bytes.
public struct Image: View {
    public typealias Body = EmptyView

    public var body: EmptyView { EmptyView() }

    public init() {}
}

public struct EnvironmentValues {
    public init() {}

    public var imagePlaygroundPersonalizationPolicy: ImagePlaygroundPersonalizationPolicy {
        .automatic
    }

    public var imagePlaygroundAllowedGenerationStyles: [ImagePlaygroundStyle] {
        ImagePlaygroundStyle.all
    }

    public var imagePlaygroundSelectedGenerationStyle: ImagePlaygroundStyle {
        .illustration
    }

    public var supportsImagePlayground: Bool { false }
}

extension View {
    /// Identity overlay; Linux never applies a generation style to layout.
    /// (`nonisolated` in the Darwin extension; the host lookalike drops the
    /// isolation attribute so synchronous evidence tests can call it.)
    public func imagePlaygroundGenerationStyle(
        _ style: ImagePlaygroundStyle,
        in allowedStyles: [ImagePlaygroundStyle] = ImagePlaygroundStyle.all
    ) -> Self {
        self
    }

    /// Identity overlay; Linux never propagates a personalization policy.
    public func imagePlaygroundPersonalizationPolicy(
        _ policy: ImagePlaygroundPersonalizationPolicy = .automatic
    ) -> Self {
        self
    }

    /// Identity overlay; Linux never presents the image playground sheet.
    /// The closures are recorded in neither direction and never invoked.
    public func imagePlaygroundSheet(
        isPresented: Binding<Bool>,
        concepts: [ImagePlaygroundConcept] = [],
        sourceImage: Image? = nil,
        onCompletion: @escaping (URL) -> Void,
        onCancellation: (() -> Void)? = nil
    ) -> Self {
        self
    }

    /// Identity overlay; Linux never presents the image playground sheet.
    public func imagePlaygroundSheet(
        isPresented: Binding<Bool>,
        concepts: [ImagePlaygroundConcept] = [],
        sourceImageURL: URL,
        onCompletion: @escaping (URL) -> Void,
        onCancellation: (() -> Void)? = nil
    ) -> Self {
        self
    }

    /// Identity overlay; Linux never presents the image playground sheet.
    public func imagePlaygroundSheet(
        isPresented: Binding<Bool>,
        concept: String,
        sourceImage: Image? = nil,
        onCompletion: @escaping (URL) -> Void,
        onCancellation: (() -> Void)? = nil
    ) -> Self {
        self
    }

    /// Identity overlay; Linux never presents the image playground sheet.
    public func imagePlaygroundSheet(
        isPresented: Binding<Bool>,
        concept: String,
        sourceImageURL: URL,
        onCompletion: @escaping (URL) -> Void,
        onCancellation: (() -> Void)? = nil
    ) -> Self {
        self
    }
}

#endif
