import Foundation

open class SCNScene: NSObject, NSSecureCoding {
    public struct Attribute: RawRepresentable, Hashable, Sendable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let startTime = Attribute(rawValue: "startTime")
        public static let endTime = Attribute(rawValue: "endTime")
        public static let frameRate = Attribute(rawValue: "frameRate")
        public static let upAxis = Attribute(rawValue: "upAxis")
    }

    public let rootNode: SCNNode
    public let physicsWorld: SCNPhysicsWorld
    public let background: SCNMaterialProperty
    public let lightingEnvironment: SCNMaterialProperty
    public var isPaused: Bool = false
    public var fogStartDistance: CGFloat = 0
    public var fogEndDistance: CGFloat = 0
    public var fogDensityExponent: CGFloat = 1
    public var fogColor: Any = SCNVector4(x: 1, y: 1, z: 1, w: 1)
    public var wantsScreenSpaceReflection: Bool = false
    public var screenSpaceReflectionSampleCount: Int = 64
    public var screenSpaceReflectionMaximumDistance: CGFloat = 1000
    public var screenSpaceReflectionStride: CGFloat = 8
    var _attributes: [String: Any] = [:]
    var _particleSystems: [(SCNParticleSystem, SCNMatrix4)] = []

    public override init() {
        rootNode = SCNNode()
        physicsWorld = SCNPhysicsWorld()
        background = SCNMaterialProperty()
        lightingEnvironment = SCNMaterialProperty()
        super.init()
        physicsWorld._root = rootNode
    }

    public convenience init?(named name: String) {
        _ = name
        return nil
    }

    public convenience init?(named name: String, inDirectory directory: String?, options: [SCNSceneSource.LoadingOption: Any]? = nil) {
        _ = name
        _ = directory
        _ = options
        return nil
    }

    public convenience init(url: URL, options: [SCNSceneSource.LoadingOption: Any]? = nil) throws {
        throw NSError(domain: SCNErrorDomain, code: SCNConsistencyInvalidURIError, userInfo: [
            NSLocalizedDescriptionKey: "SCNScene URL loading is unavailable on this Linux host"
        ])
    }

    public convenience init(URL url: URL, options: [SCNSceneSource.LoadingOption: Any]? = nil) throws {
        try self.init(url: url, options: options)
    }

    public func attribute(forKey key: String) -> Any? { _attributes[key] }
    public func setAttribute(_ attribute: Any?, forKey key: String) {
        _attributes[key] = attribute
    }

    public var particleSystems: [SCNParticleSystem]? {
        let systems = _particleSystems.map(\.0)
        return systems.isEmpty ? nil : systems
    }

    public func addParticleSystem(_ system: SCNParticleSystem, transform: SCNMatrix4) {
        _particleSystems.append((system, transform))
    }

    public func removeParticleSystem(_ system: SCNParticleSystem) {
        _particleSystems.removeAll { $0.0 === system }
    }

    public func removeAllParticleSystems() {
        _particleSystems.removeAll()
    }

    public func write(
        to url: URL,
        options: [String: Any]? = nil,
        delegate: (any SCNSceneExportDelegate)?,
        progressHandler: SCNSceneExportProgressHandler? = nil
    ) -> Bool {
        _ = url
        _ = options
        _ = delegate
        var stop = ObjCBool(false)
        progressHandler?(0, NSError(domain: SCNErrorDomain, code: -1, userInfo: nil), &stop)
        return false
    }

    /// Linux CPU action/physics clock. Physics uses a fixed `timeStep`.
    public func linux_advanceTime(_ dt: TimeInterval) {
        if isPaused { return }
        rootNode.linux_advanceTime(dt)
        for (system, _) in _particleSystems {
            system.linux_advance(dt)
        }
        physicsWorld._linuxStep(dt)
    }

    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
}

open class SCNSceneSource: NSObject {
    public struct LoadingOption: RawRepresentable, Hashable, Sendable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let createNormalsIfAbsent = LoadingOption(rawValue: "createNormalsIfAbsent")
        public static let checkConsistency = LoadingOption(rawValue: "checkConsistency")
        public static let flattenScene = LoadingOption(rawValue: "flattenScene")
        public static let useSafeMode = LoadingOption(rawValue: "useSafeMode")
        public static let assetDirectoryURLs = LoadingOption(rawValue: "assetDirectoryURLs")
        public static let overrideAssetURLs = LoadingOption(rawValue: "overrideAssetURLs")
        public static let strictConformance = LoadingOption(rawValue: "strictConformance")
        public static let convertUnitsToMeters = LoadingOption(rawValue: "convertUnitsToMeters")
        public static let convertToYUp = LoadingOption(rawValue: "convertToYUp")
        public static let animationImportPolicy = LoadingOption(rawValue: "animationImportPolicy")
        public static let preserveOriginalTopology = LoadingOption(rawValue: "preserveOriginalTopology")
    }

    public struct AnimationImportPolicy: RawRepresentable, Hashable, Sendable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let play = AnimationImportPolicy(rawValue: "play")
        public static let playRepeatedly = AnimationImportPolicy(rawValue: "playRepeatedly")
        public static let doNotPlay = AnimationImportPolicy(rawValue: "doNotPlay")
        public static let playUsingSceneTimeBase = AnimationImportPolicy(rawValue: "playUsingSceneTimeBase")
    }

    public private(set) var url: URL?
    public private(set) var data: Data?

    public override init() { super.init() }

    public convenience init?(url: URL, options: [LoadingOption: Any]? = nil) {
        self.init()
        self.url = url
        _ = options
    }

    public convenience init?(URL url: URL, options: [LoadingOption: Any]? = nil) {
        self.init(url: url, options: options)
    }

    public convenience init?(data: Data, options: [LoadingOption: Any]? = nil) {
        self.init()
        self.data = data
        _ = options
    }

    public func scene(options: [LoadingOption: Any]? = nil) throws -> SCNScene {
        _ = options
        throw NSError(domain: SCNErrorDomain, code: SCNConsistencyInvalidURIError, userInfo: [
            NSLocalizedDescriptionKey: "SCNSceneSource has no Apple archive decoder on this Linux host"
        ])
    }

    public func scene(options: [LoadingOption: Any]?, statusHandler: SCNSceneSourceStatusHandler?) -> SCNScene? {
        var stop = ObjCBool(false)
        statusHandler?(0, .error, NSError(domain: SCNErrorDomain, code: SCNConsistencyInvalidURIError, userInfo: nil), &stop)
        return nil
    }

    public func property(forKey key: String) -> Any? {
        switch key {
        case SCNSceneSourceAssetAuthorKey,
             SCNSceneSourceAssetAuthoringToolKey,
             SCNSceneSourceAssetContributorsKey,
             SCNSceneSourceAssetUnitKey,
             SCNSceneSourceAssetUnitMeterKey,
             SCNSceneSourceAssetUnitNameKey,
             SCNSceneSourceAssetUpAxisKey:
            return nil
        case SCNSceneSourceAssetCreatedDateKey, SCNSceneSourceAssetModifiedDateKey:
            guard let url else { return nil }
            return (try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey]))
                .flatMap { key == SCNSceneSourceAssetCreatedDateKey ? $0.creationDate : $0.contentModificationDate }
        default:
            return nil
        }
    }

    public func identifiersOfEntries(withClass entryClass: AnyClass) -> [String] {
        _ = entryClass
        return []
    }

    public func entryWithIdentifier(_ uid: String, withClass entryClass: AnyClass) -> Any? {
        _ = uid
        _ = entryClass
        return nil
    }

    public func entries(passingTest predicate: (Any, String, UnsafeMutablePointer<ObjCBool>) -> Bool) -> [Any] {
        _ = predicate
        return []
    }
}
