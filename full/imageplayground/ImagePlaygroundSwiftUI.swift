enum ImagePlaygroundSwiftUIAvailability {
    static var isLinked: Bool {
        #if canImport(SwiftUI)
        true
        #else
        false
        #endif
    }
}

#if canImport(SwiftUI)
import SwiftUI

private enum ImagePlaygroundPersonalizationPolicyKey: EnvironmentKey {
    static let defaultValue = ImagePlaygroundPersonalizationPolicy.automatic
}

private enum ImagePlaygroundAllowedGenerationStylesKey: EnvironmentKey {
    static let defaultValue = ImagePlaygroundStyle.all
}

private enum ImagePlaygroundSelectedGenerationStyleKey: EnvironmentKey {
    static let defaultValue = ImagePlaygroundStyle.illustration
}

private enum ImagePlaygroundSupportsKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    public var imagePlaygroundPersonalizationPolicy: ImagePlaygroundPersonalizationPolicy {
        get { self[ImagePlaygroundPersonalizationPolicyKey.self] }
        set { self[ImagePlaygroundPersonalizationPolicyKey.self] = newValue }
    }

    public var imagePlaygroundAllowedGenerationStyles: [ImagePlaygroundStyle] {
        get { self[ImagePlaygroundAllowedGenerationStylesKey.self] }
        set { self[ImagePlaygroundAllowedGenerationStylesKey.self] = newValue }
    }

    public var imagePlaygroundSelectedGenerationStyle: ImagePlaygroundStyle {
        get { self[ImagePlaygroundSelectedGenerationStyleKey.self] }
        set { self[ImagePlaygroundSelectedGenerationStyleKey.self] = newValue }
    }

    /// Always `false` on this starting point: no generative service is present.
    public var supportsImagePlayground: Bool {
        get { self[ImagePlaygroundSupportsKey.self] }
        set { self[ImagePlaygroundSupportsKey.self] = newValue }
    }
}

extension View {
    public func imagePlaygroundGenerationStyle(
        _ style: ImagePlaygroundStyle,
        in allowedStyles: [ImagePlaygroundStyle] = ImagePlaygroundStyle.all
    ) -> some View {
        environment(\.imagePlaygroundSelectedGenerationStyle, style)
            .environment(\.imagePlaygroundAllowedGenerationStyles, allowedStyles)
    }

    public func imagePlaygroundPersonalizationPolicy(
        _ policy: ImagePlaygroundPersonalizationPolicy = .automatic
    ) -> some View {
        environment(\.imagePlaygroundPersonalizationPolicy, policy)
    }

    /// Fail-closed: does not present Apple's generation sheet or invoke
    /// `onCompletion` with a fabricated file URL.
    @MainActor
    public func imagePlaygroundSheet(
        isPresented: Binding<Bool>,
        concept: String,
        sourceImage: Image? = nil,
        onCompletion: @escaping (URL) -> Void,
        onCancellation: (() -> Void)? = nil
    ) -> some View {
        _ = (isPresented, concept, sourceImage, onCompletion, onCancellation)
        return self
    }

    @MainActor
    public func imagePlaygroundSheet(
        isPresented: Binding<Bool>,
        concept: String,
        sourceImageURL: URL,
        onCompletion: @escaping (URL) -> Void,
        onCancellation: (() -> Void)? = nil
    ) -> some View {
        _ = (isPresented, concept, sourceImageURL, onCompletion, onCancellation)
        return self
    }

    @MainActor
    public func imagePlaygroundSheet(
        isPresented: Binding<Bool>,
        concepts: [ImagePlaygroundConcept] = [],
        sourceImage: Image? = nil,
        onCompletion: @escaping (URL) -> Void,
        onCancellation: (() -> Void)? = nil
    ) -> some View {
        _ = (isPresented, concepts, sourceImage, onCompletion, onCancellation)
        return self
    }

    @MainActor
    public func imagePlaygroundSheet(
        isPresented: Binding<Bool>,
        concepts: [ImagePlaygroundConcept] = [],
        sourceImageURL: URL,
        onCompletion: @escaping (URL) -> Void,
        onCancellation: (() -> Void)? = nil
    ) -> some View {
        _ = (isPresented, concepts, sourceImageURL, onCompletion, onCancellation)
        return self
    }
}
#endif
