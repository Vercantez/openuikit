import Foundation

public protocol SCNSceneRenderer: NSObjectProtocol {
    var scene: SCNScene? { get set }
    var sceneTime: TimeInterval { get set }
    var isPlaying: Bool { get set }
    var loops: Bool { get set }
    var pointOfView: SCNNode? { get set }
    var autoenablesDefaultLighting: Bool { get set }
    var isJitteringEnabled: Bool { get set }
    var isTemporalAntialiasingEnabled: Bool { get set }
    var showsStatistics: Bool { get set }
    var debugOptions: SCNDebugOptions { get set }
    var renderingAPI: SCNRenderingAPI { get }
    var overlaySKScene: Any? { get set }
    var delegate: SCNSceneRendererDelegate? { get set }
    var audioListener: SCNNode? { get set }
    var context: UnsafeMutableRawPointer? { get }
    var currentViewport: CGRect { get }
    var usesReverseZ: Bool { get set }
    func hitTest(_ point: CGPoint, options: [SCNHitTestOption: Any]?) -> [SCNHitTestResult]
    func isNode(_ node: SCNNode, insideFrustumOf pointOfView: SCNNode) -> Bool
    func nodesInsideFrustum(of pointOfView: SCNNode) -> [SCNNode]
    func prepare(_ object: Any, shouldAbortBlock block: (() -> Bool)?) -> Bool
    func prepare(_ objects: [Any]) async -> Bool
    func projectPoint(_ point: SCNVector3) -> SCNVector3
    func unprojectPoint(_ point: SCNVector3) -> SCNVector3
}

open class SCNHitTestResult: NSObject {
    public private(set) var node: SCNNode
    public private(set) var geometryIndex: Int
    public private(set) var faceIndex: Int
    public private(set) var localCoordinates: SCNVector3
    public private(set) var worldCoordinates: SCNVector3
    public private(set) var localNormal: SCNVector3
    public private(set) var worldNormal: SCNVector3
    public private(set) var modelTransform: SCNMatrix4
    public private(set) var boneNode: SCNNode?
    var _uv = CGPoint.zero

    public override init() {
        node = SCNNode()
        geometryIndex = 0
        faceIndex = 0
        localCoordinates = SCNVector3Zero
        worldCoordinates = SCNVector3Zero
        localNormal = SCNVector3(x: 0, y: 1, z: 0)
        worldNormal = SCNVector3(x: 0, y: 1, z: 0)
        modelTransform = SCNMatrix4Identity
        super.init()
    }

    convenience init(
        node: SCNNode,
        geometryIndex: Int,
        faceIndex: Int,
        localCoordinates: SCNVector3,
        worldCoordinates: SCNVector3,
        localNormal: SCNVector3,
        worldNormal: SCNVector3,
        modelTransform: SCNMatrix4
    ) {
        self.init()
        self.node = node
        self.geometryIndex = geometryIndex
        self.faceIndex = faceIndex
        self.localCoordinates = localCoordinates
        self.worldCoordinates = worldCoordinates
        self.localNormal = localNormal
        self.worldNormal = worldNormal
        self.modelTransform = modelTransform
    }

    public var simdLocalCoordinates: SIMD3<Float> { SIMD3(localCoordinates) }
    public var simdWorldCoordinates: SIMD3<Float> { SIMD3(worldCoordinates) }
    public var simdLocalNormal: SIMD3<Float> { SIMD3(localNormal) }
    public var simdWorldNormal: SIMD3<Float> { SIMD3(worldNormal) }

    public func textureCoordinates(withMappingChannel channel: Int) -> CGPoint {
        _ = channel
        return _uv
    }
}

open class SCNProgram: NSObject, NSCopying, NSSecureCoding {
    public var vertexShader: String?
    public var fragmentShader: String?
    public var vertexFunctionName: String?
    public var fragmentFunctionName: String?
    public var isOpaque: Bool = true
    public weak var delegate: SCNProgramDelegate?

    public override init() { super.init() }

    public func setSemantic(_ semantic: String?, forSymbol symbol: String, options: [String: Any]? = nil) {
        _ = semantic
        _ = symbol
        _ = options
    }

    public func semantic(forSymbol symbol: String) -> String? {
        _ = symbol
        return nil
    }

    public func handleBinding(ofBufferNamed name: String, frequency: SCNBufferFrequency, handler: @escaping SCNBufferBindingBlock) {
        _ = name
        _ = frequency
        _ = handler
    }

    public func copy(with zone: NSZone? = nil) -> Any { SCNProgram() }
    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}

open class SCNTechnique: NSObject, NSCopying, NSSecureCoding {
    public var dictionaryRepresentation: [String: Any]

    public override init() {
        dictionaryRepresentation = [:]
        super.init()
    }

    public convenience init?(dictionary: [String: Any]) {
        self.init()
        self.dictionaryRepresentation = dictionary
    }

    public convenience init?(bySequencingTechniques techniques: [SCNTechnique]) {
        self.init()
        _ = techniques
    }

    public func handleBinding(ofSymbol symbol: String, using block: SCNBindingBlock?) {
        _ = symbol
        _ = block
    }

    public func setObject(_ obj: Any?, forKeyedSubscript key: NSCopying) {
        _ = obj
        _ = key
    }

    public subscript(key: Any) -> Any? {
        get {
            dictionaryRepresentation[String(describing: key)]
        }
        set {
            dictionaryRepresentation[String(describing: key)] = newValue
        }
    }

    public func copy(with zone: NSZone? = nil) -> Any { SCNTechnique() }
    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}

open class SCNRenderer: NSObject, SCNSceneRenderer, SCNTechniqueSupport {
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
    public var nextFrameTime: TimeInterval = 0
    public var technique: SCNTechnique?
    var _viewport = CGRect(x: 0, y: 0, width: 64, height: 64)
    public var linux_lastImage: SCNCPUImage?

    public override init() { super.init() }

    public func render() {
        linux_lastImage = linux_snapshot(size: _viewport.size, atTime: sceneTime)
    }
    public func render(atTime time: TimeInterval) {
        sceneTime = time
        scene?.linux_advanceTime(0)
        linux_lastImage = linux_snapshot(size: _viewport.size, atTime: time)
    }
    public func update(atTime time: TimeInterval) {
        sceneTime = time
        scene?.linux_advanceTime(0)
    }
    public func updateProbes(_ lightProbes: [SCNNode], atTime time: TimeInterval) {
        _ = lightProbes
        sceneTime = time
    }

    public func linux_snapshot(size: CGSize, atTime time: TimeInterval = 0) -> SCNCPUImage {
        sceneTime = time
        let image = _scnRasterize(scene: scene, pointOfView: pointOfView, size: size, autoenablesDefaultLighting: autoenablesDefaultLighting)
        linux_lastImage = image
        return image
    }

    public func hitTest(_ point: CGPoint, options: [SCNHitTestOption: Any]? = nil) -> [SCNHitTestResult] {
        guard let scene else { return [] }
        let size = currentViewport.size.width > 0 ? currentViewport.size : CGSize(width: 64, height: 64)
        let ndcX = Float((point.x / size.width) * 2 - 1)
        let ndcY = Float(1 - (point.y / size.height) * 2)
        let near = unprojectPoint(SCNVector3(ndcX, ndcY, -1))
        let far = unprojectPoint(SCNVector3(ndcX, ndcY, 1))
        return _scnHitTestSegment(root: scene.rootNode, from: near, to: far, options: options ?? [:], spaceNode: nil)
    }

    public func isNode(_ node: SCNNode, insideFrustumOf pointOfView: SCNNode) -> Bool {
        nodesInsideFrustum(of: pointOfView).contains { $0 === node }
    }

    public func nodesInsideFrustum(of pointOfView: SCNNode) -> [SCNNode] {
        guard let scene else { return [] }
        var found: [SCNNode] = []
        scene.rootNode.enumerateHierarchy { node, _ in
            if node.geometry != nil || node.camera != nil {
                found.append(node)
            }
        }
        _ = pointOfView
        return found
    }

    public func prepare(_ object: Any, shouldAbortBlock block: (() -> Bool)? = nil) -> Bool {
        _ = object
        _ = block
        return true
    }

    public func prepare(_ objects: [Any]) async -> Bool {
        _ = objects
        return true
    }

    public func projectPoint(_ point: SCNVector3) -> SCNVector3 {
        let view = _scnViewMatrix(pointOfView)
        let proj = _scnProjectionMatrix(pointOfView, size: currentViewport.size)
        let clip = _scnTransformH(SCNMatrix4Mult(view, proj), point)
        if clip.w == 0 { return point }
        return SCNVector3(x: clip.x / clip.w, y: clip.y / clip.w, z: clip.z / clip.w)
    }

    public func unprojectPoint(_ point: SCNVector3) -> SCNVector3 {
        let view = _scnViewMatrix(pointOfView)
        let proj = _scnProjectionMatrix(pointOfView, size: currentViewport.size)
        let inv = SCNMatrix4Invert(SCNMatrix4Mult(view, proj))
        let clip = SCNVector4(x: point.x, y: point.y, z: point.z, w: 1)
        let world = _scnTransformH4(inv, clip)
        if world.w == 0 { return point }
        return SCNVector3(x: world.x / world.w, y: world.y / world.w, z: world.z / world.w)
    }

    public var audioListener: SCNNode?
    public var context: UnsafeMutableRawPointer? { nil }
    public var currentViewport: CGRect {
        get { _viewport }
        set { _viewport = newValue }
    }
    public var usesReverseZ: Bool = false
}

open class SCNCameraController: NSObject {
    public weak var delegate: SCNCameraControllerDelegate?
    public weak var pointOfView: SCNNode?
    public var target: SCNVector3 = SCNVector3Zero
    public var automaticTarget: Bool = true
    public var worldUp: SCNVector3 = SCNNode.localUp
    public var interactionMode: SCNInteractionMode = .orbitTurntable
    public var minimumVerticalAngle: CGFloat = 0
    public var maximumVerticalAngle: CGFloat = 0
    public var minimumHorizontalAngle: Float = 0
    public var maximumHorizontalAngle: Float = 0
    public var inertiaEnabled: Bool = false
    public var inertiaFriction: CGFloat = 0.05
    public var isInertiaRunning: Bool { false }

    public override init() { super.init() }

    public func translateInCameraSpaceBy(x deltaX: Float, y deltaY: Float, z deltaZ: Float) {
        guard let node = pointOfView else { return }
        node.localTranslate(by: SCNVector3(x: deltaX, y: deltaY, z: deltaZ))
    }

    public func frameNodes(_ nodes: [SCNNode]) { _ = nodes }
    public func rotateBy(x deltaX: Float, y deltaY: Float) {
        _ = deltaX
        _ = deltaY
    }
    public func rollBy(_ delta: Float) { _ = delta }
    public func dollyBy(_ delta: Float) { _ = delta }
    public func rollAroundTarget(_ delta: Float) { _ = delta }
    public func dollyToTarget(_ delta: Float) { _ = delta }
    public func dolly(toTarget delta: Float) { dollyToTarget(delta) }
    public func dolly(by delta: Float, onScreenPoint point: CGPoint, viewport: CGSize) {
        _ = point
        _ = viewport
        dollyBy(delta)
    }
    public func roll(by delta: Float, aroundScreenPoint point: CGPoint, viewport: CGSize) {
        _ = point
        _ = viewport
        rollBy(delta)
    }
    public func clearRoll() {}
    public func stopInertia() {}
    public func beginInteraction(_ location: CGPoint, withViewport viewport: CGSize) {
        _ = location
        _ = viewport
    }
    public func continueInteraction(_ location: CGPoint, withViewport viewport: CGSize, sensitivity: CGFloat) {
        _ = location
        _ = viewport
        _ = sensitivity
    }
    public func endInteraction(_ location: CGPoint, withViewport viewport: CGSize, velocity: CGPoint) {
        _ = location
        _ = viewport
        _ = velocity
    }
}
