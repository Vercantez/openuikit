#if canImport(SwiftUI)
import SwiftUI
#endif
import Foundation

/// `SceneView` overlay type. It compiles as an inert `View` value on the
/// isolated Foundation host. Linux renders EmptyView; it never presents
/// SceneKit UI, loads scenes, or starts a render loop.

#if !canImport(SwiftUI)
public protocol View {
    associatedtype Body: View
    @ViewBuilder var body: Body { get }
}

extension Never: View {
    public typealias Body = Never
    public var body: Never {
        fatalError("Never has no View body")
    }
}

public struct EmptyView: View {
    public init() {}
    public var body: Never {
        fatalError("EmptyView is a leaf")
    }
}

@resultBuilder
public enum ViewBuilder {
    public static func buildBlock() -> EmptyView { EmptyView() }

    public static func buildBlock<Content: View>(_ content: Content) -> Content {
        content
    }

    public static func buildExpression<Content: View>(_ content: Content) -> Content {
        content
    }
}
#endif

/// Linux-host `SceneView`: an identity `View` overlay over the CPU scene
/// graph. The initializer mirrors the Apple parameter names and defaults;
/// stored values are bookkeeping only. `delegate` is accepted and ignored
/// (no render loop on Linux). `body` renders `EmptyView`.
public struct SceneView: View {
    public typealias Body = EmptyView
    public var body: EmptyView { EmptyView() }

    public struct Options: OptionSet {
        public var rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let rendersContinuously = Options(rawValue: 1 << 0)
        public static let allowsCameraControl = Options(rawValue: 1 << 1)
        public static let jitteringEnabled = Options(rawValue: 1 << 2)
        public static let temporalAntialiasingEnabled = Options(rawValue: 1 << 3)
        public static let autoenablesDefaultLighting = Options(rawValue: 1 << 4)
    }

    public var scene: SCNScene?
    public var pointOfView: SCNNode?
    public var options: Options
    public var preferredFramesPerSecond: Int
    public var antialiasingMode: SCNAntialiasingMode
    public var technique: SCNTechnique?

    public init(
        scene: SCNScene? = nil,
        pointOfView: SCNNode? = nil,
        options: Options = [],
        preferredFramesPerSecond: Int = 60,
        antialiasingMode: SCNAntialiasingMode = .multisampling4X,
        delegate: (any SCNSceneRendererDelegate)? = nil,
        technique: SCNTechnique? = nil
    ) {
        self.scene = scene
        self.pointOfView = pointOfView
        self.options = options
        self.preferredFramesPerSecond = preferredFramesPerSecond
        self.antialiasingMode = antialiasingMode
        self.technique = technique
        _ = delegate
    }
}
