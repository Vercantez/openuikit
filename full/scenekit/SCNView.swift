import Foundation

#if canImport(UIKit)
import UIKit
#endif

open class _SCNCameraControlConfiguration: NSObject, SCNCameraControlConfiguration {
    public var allowsTranslation: Bool = true
    public var autoSwitchToFreeCamera: Bool = true
    public var flyModeVelocity: CGFloat = 1
    public var panSensitivity: CGFloat = 1
    public var rotationSensitivity: CGFloat = 1
    public var truckSensitivity: CGFloat = 1
}

open class SCNView: NSObject, SCNSceneRenderer, SCNTechniqueSupport {
    public struct Option: RawRepresentable, Hashable, Sendable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let preferredRenderingAPI = Option(rawValue: "preferredRenderingAPI")
        public static let preferredDevice = Option(rawValue: "preferredDevice")
        public static let preferLowPowerDevice = Option(rawValue: "preferLowPowerDevice")
    }

    public var scene: SCNScene?
    public var sceneTime: TimeInterval = 0
    public var isPlaying: Bool = false
    public var loops: Bool = true
    public var pointOfView: SCNNode?
    public var autoenablesDefaultLighting: Bool = false
    public var isJitteringEnabled: Bool = false
    public var isTemporalAntialiasingEnabled: Bool = false
    public var showsStatistics: Bool = false
    public var debugOptions: SCNDebugOptions = []
    public var renderingAPI: SCNRenderingAPI { .metal }
    public var overlaySKScene: Any?
    public weak var delegate: SCNSceneRendererDelegate?
    public var technique: SCNTechnique?
    public var allowsCameraControl: Bool = false
    public var antialiasingMode: SCNAntialiasingMode = .none
    public var preferredFramesPerSecond: Int = 60
    public var rendersContinuously: Bool = false
    public let defaultCameraController = SCNCameraController()
    public let cameraControlConfiguration: any SCNCameraControlConfiguration = _SCNCameraControlConfiguration()
    public var audioListener: SCNNode?
    public var context: UnsafeMutableRawPointer? { nil }
    public var usesReverseZ: Bool = false
    var _frame = CGRect(x: 0, y: 0, width: 64, height: 64)
    let _cpuRenderer = SCNRenderer()

    public override init() {
        super.init()
    }

    public init(frame: CGRect, options: [String: Any]? = nil) {
        super.init()
        _frame = frame
        _ = options
    }

    public var currentViewport: CGRect { _frame }

    public func play(_ sender: Any?) {
        _ = sender
        isPlaying = true
    }

    public func pause(_ sender: Any?) {
        _ = sender
        isPlaying = false
    }

    public func stop(_ sender: Any?) {
        _ = sender
        isPlaying = false
        sceneTime = 0
    }

    public func linux_snapshot() -> SCNCPUImage {
        _cpuRenderer.scene = scene
        _cpuRenderer.pointOfView = pointOfView ?? _defaultPointOfView()
        _cpuRenderer.autoenablesDefaultLighting = autoenablesDefaultLighting
        return _cpuRenderer.linux_snapshot(size: _frame.size)
    }

    public func hitTest(_ point: CGPoint, options: [SCNHitTestOption: Any]? = nil) -> [SCNHitTestResult] {
        _cpuRenderer.scene = scene
        _cpuRenderer.pointOfView = pointOfView ?? _defaultPointOfView()
        _cpuRenderer.currentViewport = _frame
        return _cpuRenderer.hitTest(point, options: options)
    }

    public func isNode(_ node: SCNNode, insideFrustumOf pointOfView: SCNNode) -> Bool {
        _cpuRenderer.isNode(node, insideFrustumOf: pointOfView)
    }

    public func nodesInsideFrustum(of pointOfView: SCNNode) -> [SCNNode] {
        _cpuRenderer.scene = scene
        return _cpuRenderer.nodesInsideFrustum(of: pointOfView)
    }

    public func prepare(_ object: Any, shouldAbortBlock block: (() -> Bool)? = nil) -> Bool {
        _cpuRenderer.prepare(object, shouldAbortBlock: block)
    }

    public func prepare(_ objects: [Any]) async -> Bool {
        await _cpuRenderer.prepare(objects)
    }

    public func projectPoint(_ point: SCNVector3) -> SCNVector3 {
        _cpuRenderer.scene = scene
        _cpuRenderer.pointOfView = pointOfView ?? _defaultPointOfView()
        _cpuRenderer.currentViewport = _frame
        return _cpuRenderer.projectPoint(point)
    }

    public func unprojectPoint(_ point: SCNVector3) -> SCNVector3 {
        _cpuRenderer.scene = scene
        _cpuRenderer.pointOfView = pointOfView ?? _defaultPointOfView()
        _cpuRenderer.currentViewport = _frame
        return _cpuRenderer.unprojectPoint(point)
    }

    private func _defaultPointOfView() -> SCNNode? {
        scene?.rootNode.childNodes.first { $0.camera != nil }
    }
}
