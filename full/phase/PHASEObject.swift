import Foundation

#if canImport(ModelIO)
import ModelIO
#endif

open class PHASEObject: NSObject {
    public private(set) weak var parent: PHASEObject?
    private var childStorage: [PHASEObject] = []
    public var transform: simd_float4x4 = .identity
    weak var engine: PHASEEngine?

    public var children: [PHASEObject] { childStorage }

    public class var right: simd_float3 { simd_float3(1, 0, 0) }
    public class var up: simd_float3 { simd_float3(0, 1, 0) }
    public class var forward: simd_float3 { simd_float3(0, 0, -1) }

    public var worldTransform: simd_float4x4 {
        get {
            if let parent {
                return phaseMultiply(parent.worldTransform, transform)
            }
            return transform
        }
        set {
            if let parent {
                transform = phaseMultiply(phaseInvertAffine(parent.worldTransform), newValue)
            } else {
                transform = newValue
            }
        }
    }

    public init(engine: PHASEEngine) {
        self.engine = engine
        super.init()
    }

    init(unbound: Void) {
        super.init()
    }

    public func addChild(_ child: PHASEObject) throws {
        if child === self {
            throw PHASEError(
                .invalidObject,
                userInfo: phaseLinuxReason("cannot add an object as a child of itself")
            )
        }
        var ancestor: PHASEObject? = self
        while let current = ancestor {
            if current === child {
                throw PHASEError(
                    .invalidObject,
                    userInfo: phaseLinuxReason("cannot add an ancestor as a child")
                )
            }
            ancestor = current.parent
        }
        if let existingParent = child.parent, existingParent !== self {
            existingParent.removeChild(child)
        }
        if !childStorage.contains(where: { $0 === child }) {
            childStorage.append(child)
        }
        child.parent = self
    }

    public func removeChild(_ child: PHASEObject) {
        childStorage.removeAll { $0 === child }
        if child.parent === self {
            child.parent = nil
        }
    }

    public func removeChildren() {
        let snapshot = childStorage
        childStorage.removeAll()
        for child in snapshot where child.parent === self {
            child.parent = nil
        }
    }
}

public final class PHASEListener: PHASEObject {
    public var gain: Double = 1
    public var automaticHeadTrackingFlags: PHASEAutomaticHeadTrackingFlags = []

    public override init(engine: PHASEEngine) {
        super.init(engine: engine)
    }
}

public final class PHASESource: PHASEObject {
    public var gain: Double = 1
    public private(set) var shapes: [PHASEShape] = []

    public override init(engine: PHASEEngine) {
        super.init(engine: engine)
    }

    public init(engine: PHASEEngine, shapes: [PHASEShape]) {
        self.shapes = shapes
        super.init(engine: engine)
    }
}

public final class PHASEOccluder: PHASEObject {
    public private(set) var shapes: [PHASEShape] = []

    public init(engine: PHASEEngine, shapes: [PHASEShape]) {
        self.shapes = shapes
        super.init(engine: engine)
    }
}

public final class PHASEMaterial: NSObject {
    public let preset: PHASEMaterialPreset

    public init(engine: PHASEEngine, preset: PHASEMaterialPreset) {
        _ = engine
        self.preset = preset
        super.init()
    }
}

public final class PHASEShape: NSObject {
    public final class Element: NSObject {
        public var material: PHASEMaterial?
    }

    public private(set) var elements: [Element]

#if canImport(ModelIO)
    public init(engine: PHASEEngine, mesh: MDLMesh) {
        _ = engine
        _ = mesh
        self.elements = [Element()]
        super.init()
    }

    public convenience init(engine: PHASEEngine, mesh: MDLMesh, materials: [PHASEMaterial]) {
        self.init(engine: engine, mesh: mesh)
        if let first = elements.first, let material = materials.first {
            first.material = material
        }
    }
#else
    @_spi(OpenUIKitHost)
    public init(engine: PHASEEngine, hostElementCount: Int = 1) {
        _ = engine
        self.elements = (0..<max(hostElementCount, 0)).map { _ in Element() }
        super.init()
    }
#endif
}
