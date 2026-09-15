#if canImport(SwiftUI)
import SwiftUI
#endif
import Foundation

/// `_SpriteKit_SwiftUI` overlay types. They compile as inert `View` values on
/// the isolated Foundation host. They do not present scenes, run a GPU frame
/// loop, or compile Metal shaders; Linux renders `EmptyView`.

public struct SpriteView: View {
    public typealias Body = EmptyView
    public var body: EmptyView { EmptyView() }

    public var scene: SKScene
    public var transition: SKTransition?
    public var isPaused: Bool
    public var preferredFramesPerSecond: Int
    public var options: Options
    public var debugOptions: DebugOptions
    public var shouldRender: (TimeInterval) -> Bool

    public init(
        scene: SKScene,
        transition: SKTransition? = nil,
        isPaused: Bool = false,
        preferredFramesPerSecond: Int = 60
    ) {
        self.scene = scene
        self.transition = transition
        self.isPaused = isPaused
        self.preferredFramesPerSecond = preferredFramesPerSecond
        self.options = [.shouldCullNonVisibleNodes]
        self.debugOptions = []
        self.shouldRender = { _ in true }
    }

    public init(
        scene: SKScene,
        transition: SKTransition? = nil,
        isPaused: Bool = false,
        preferredFramesPerSecond: Int = 60,
        options: Options = [.shouldCullNonVisibleNodes],
        shouldRender: @escaping (TimeInterval) -> Bool = { _ in true }
    ) {
        self.scene = scene
        self.transition = transition
        self.isPaused = isPaused
        self.preferredFramesPerSecond = preferredFramesPerSecond
        self.options = options
        self.debugOptions = []
        self.shouldRender = shouldRender
    }

    public init(
        scene: SKScene,
        transition: SKTransition? = nil,
        isPaused: Bool = false,
        preferredFramesPerSecond: Int = 60,
        options: Options = [.shouldCullNonVisibleNodes],
        debugOptions: DebugOptions,
        shouldRender: @escaping (TimeInterval) -> Bool = { _ in true }
    ) {
        self.scene = scene
        self.transition = transition
        self.isPaused = isPaused
        self.preferredFramesPerSecond = preferredFramesPerSecond
        self.options = options
        self.debugOptions = debugOptions
        self.shouldRender = shouldRender
    }

    public struct Options: OptionSet, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        /// Linux-host bit assignments; Apple raw values are unobserved here.
        public static let allowsTransparency = Options(rawValue: 1 << 0)
        public static let ignoresSiblingOrder = Options(rawValue: 1 << 1)
        public static let shouldCullNonVisibleNodes = Options(rawValue: 1 << 2)
    }

    public struct DebugOptions: OptionSet, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        /// Linux-host bit assignments; Apple raw values are unobserved here.
        public static let showsFields = DebugOptions(rawValue: 1 << 0)
        public static let showsPhysics = DebugOptions(rawValue: 1 << 1)
        public static let showsDrawCount = DebugOptions(rawValue: 1 << 2)
        public static let showsNodeCount = DebugOptions(rawValue: 1 << 3)
        public static let showsQuadCount = DebugOptions(rawValue: 1 << 4)
        public static let showsFPS = DebugOptions(rawValue: 1 << 5)
    }
}
