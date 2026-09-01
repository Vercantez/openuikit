import Foundation

public final class SCNScene: NSObject {
    public struct Attribute: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let startTime = Attribute(rawValue: "startTime")
        public static let endTime = Attribute(rawValue: "endTime")
        public static let frameRate = Attribute(rawValue: "frameRate")
        public static let upAxis = Attribute(rawValue: "upAxis")
    }

    public let rootNode = SCNNode()
    public let physicsWorld = SCNPhysicsWorld()
    public let background = SCNMaterialProperty()
    public let lightingEnvironment = SCNMaterialProperty()
    public var isPaused = false
    public var fogStartDistance: CGFloat = 0
    public var fogEndDistance: CGFloat = 0
    public var fogDensityExponent: CGFloat = 1
    public var fogColor: Any = NSNumber(value: 1)
    public var wantsScreenSpaceReflection = false
    public var screenSpaceReflectionSampleCount = 64
    public var screenSpaceReflectionMaximumDistance: CGFloat = 0
    public var screenSpaceReflectionStride: CGFloat = 0
    var _attributes: [String: Any] = [:]
    var _particleSystems: [(SCNParticleSystem, SCNMatrix4)] = []

    public override init() {
        super.init()
        physicsWorld._scene = self
    }

    public convenience init?(named name: String) {
        self.init(named: name, inDirectory: nil, options: nil)
    }

    public convenience init?(
        named name: String,
        inDirectory directory: String?,
        options: [SCNSceneSource.LoadingOption: Any]? = nil
    ) {
        _ = name
        _ = directory
        _ = options
        return nil
    }

    public convenience init(url: URL, options: [SCNSceneSource.LoadingOption: Any]? = nil) throws {
        _ = options
        throw NSError(
            domain: SCNErrorDomain,
            code: SCNConsistencyInvalidURIError,
            userInfo: [NSLocalizedDescriptionKey: "Scene asset loading is unavailable on Linux: \(url.path)"]
        )
    }

    public convenience init(URL url: URL, options: [SCNSceneSource.LoadingOption: Any]? = nil) throws {
        try self.init(url: url, options: options)
    }

    public required init?(coder: NSCoder) { return nil }

    public var particleSystems: [SCNParticleSystem]? {
        _particleSystems.isEmpty ? nil : _particleSystems.map(\.0)
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

    public func attribute(forKey key: String) -> Any? {
        _attributes[key]
    }

    public func setAttribute(_ attribute: Any?, forKey key: String) {
        if let attribute {
            _attributes[key] = attribute
        } else {
            _attributes.removeValue(forKey: key)
        }
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
        progressHandler?(
            0,
            NSError(
                domain: SCNErrorDomain,
                code: SCNConsistencyInvalidURIError,
                userInfo: [NSLocalizedDescriptionKey: "Scene export is unavailable on Linux"]
            ),
            &stop
        )
        return false
    }
}

public final class SCNSceneSource: NSObject {
    public struct LoadingOption: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
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
        public static let animationImportPolicyOption = LoadingOption(rawValue: "animationImportPolicyOption")
        public static let preserveOriginalTopology = LoadingOption(rawValue: "preserveOriginalTopology")
    }

    public struct AnimationImportPolicy: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let play = AnimationImportPolicy(rawValue: "play")
        public static let playRepeatedly = AnimationImportPolicy(rawValue: "playRepeatedly")
        public static let doNotPlay = AnimationImportPolicy(rawValue: "doNotPlay")
        public static let playUsingSceneTimeBase = AnimationImportPolicy(rawValue: "playUsingSceneTimeBase")
    }

    public private(set) var url: URL?

    public convenience init?(url: URL, options: [SCNSceneSource.LoadingOption: Any]? = nil) {
        self.init()
        _ = options
        self.url = url
    }

    public override init() {
        url = nil
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }

    public func scene(options: [SCNSceneSource.LoadingOption: Any]? = nil) throws -> SCNScene {
        _ = options
        throw NSError(
            domain: SCNErrorDomain,
            code: SCNConsistencyInvalidURIError,
            userInfo: [NSLocalizedDescriptionKey: "Scene source decoding is unavailable on Linux"]
        )
    }
}

public final class SCNTransaction: NSObject {
    private static var depth = 0
    private static var values: [String: Any] = [:]
    private static var _disableActions = false
    private static var _animationDuration: TimeInterval = 0
    private static var _completionBlock: (() -> Void)?

    public static func begin() {
        depth += 1
    }

    public static func commit() {
        if depth > 0 { depth -= 1 }
        if depth == 0 {
            let block = _completionBlock
            _completionBlock = nil
            block?()
        }
    }

    public static func flush() {}

    public static func lock() {}

    public static func unlock() {}

    public static func setValue(_ value: Any?, forKey key: String) {
        if let value {
            values[key] = value
        } else {
            values.removeValue(forKey: key)
        }
    }

    public static func value(forKey key: String) -> Any? {
        values[key]
    }

    public static var animationDuration: TimeInterval {
        get { _animationDuration }
        set { _animationDuration = newValue }
    }

    public static var disableActions: Bool {
        get { _disableActions }
        set { _disableActions = newValue }
    }

    public static var completionBlock: (() -> Void)? {
        get { _completionBlock }
        set { _completionBlock = newValue }
    }
}

public final class SCNReferenceNode: SCNNode {
    public var referenceURL: URL
    public var loadingPolicy = SCNReferenceLoadingPolicy.onDemand
    public private(set) var isLoaded = false

    public init?(url referenceURL: URL) {
        self.referenceURL = referenceURL
        super.init()
    }

    public convenience init?(URL referenceURL: URL) {
        self.init(url: referenceURL)
    }

    public required init() {
        self.referenceURL = URL(fileURLWithPath: "/dev/null")
        super.init()
    }

    public required init?(coder aDecoder: NSCoder) { return nil }

    public func load() {
        isLoaded = false
    }

    public func unload() {
        isLoaded = false
        for child in childNodes {
            child.removeFromParentNode()
        }
    }
}
