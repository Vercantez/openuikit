import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

public class MDLMaterialProperty: NSObject, MDLNamed, NSCopying {
    public var name: String
    public var semantic: MDLMaterialSemantic
    public var type: MDLMaterialPropertyType
    public var stringValue: String?
    public var urlValue: URL?
    public var textureSamplerValue: MDLTextureSampler?
    public var floatValue: Float = 0
    public var float2Value: SIMD2<Float> = SIMD2()
    public var float3Value: SIMD3<Float> = SIMD3()
    public var float4Value: SIMD4<Float> = SIMD4()
    public var matrix4x4: matrix_float4x4 = .identity
    public var luminance: Float = 0
#if canImport(CoreGraphics)
    public var color: CGColor?
#endif

    public init(name: String, semantic: MDLMaterialSemantic) {
        self.name = name
        self.semantic = semantic
        self.type = .none
        super.init()
    }

    public convenience init(name: String, semantic: MDLMaterialSemantic, url URL: URL?) {
        self.init(name: name, semantic: semantic)
        self.urlValue = URL
        self.type = .URL
    }

    public convenience init(name: String, semantic: MDLMaterialSemantic, URL: URL?) {
        self.init(name: name, semantic: semantic, url: URL)
    }

    public convenience init(name: String, semantic: MDLMaterialSemantic, string: String?) {
        self.init(name: name, semantic: semantic)
        self.stringValue = string
        self.type = .string
    }

    public convenience init(name: String, semantic: MDLMaterialSemantic, float value: Float) {
        self.init(name: name, semantic: semantic)
        self.floatValue = value
        self.type = .float
    }

    public convenience init(name: String, semantic: MDLMaterialSemantic, float2 value: SIMD2<Float>) {
        self.init(name: name, semantic: semantic)
        self.float2Value = value
        self.type = .float2
    }

    public convenience init(name: String, semantic: MDLMaterialSemantic, float3 value: SIMD3<Float>) {
        self.init(name: name, semantic: semantic)
        self.float3Value = value
        self.type = .float3
    }

    public convenience init(name: String, semantic: MDLMaterialSemantic, float4 value: SIMD4<Float>) {
        self.init(name: name, semantic: semantic)
        self.float4Value = value
        self.type = .float4
    }

    public convenience init(name: String, semantic: MDLMaterialSemantic, matrix4x4 value: matrix_float4x4) {
        self.init(name: name, semantic: semantic)
        self.matrix4x4 = value
        self.type = .matrix44
    }

    public convenience init(name: String, semantic: MDLMaterialSemantic, textureSampler: MDLTextureSampler?) {
        self.init(name: name, semantic: semantic)
        self.textureSamplerValue = textureSampler
        self.type = .texture
    }

#if canImport(CoreGraphics)
    public convenience init(name: String, semantic: MDLMaterialSemantic, color: CGColor) {
        self.init(name: name, semantic: semantic)
        self.color = color
        self.type = .color
    }
#endif

    public func setProperties(_ property: MDLMaterialProperty) {
        semantic = property.semantic
        type = property.type
        stringValue = property.stringValue
        urlValue = property.urlValue
        textureSamplerValue = property.textureSamplerValue
        floatValue = property.floatValue
        float2Value = property.float2Value
        float3Value = property.float3Value
        float4Value = property.float4Value
        matrix4x4 = property.matrix4x4
        luminance = property.luminance
#if canImport(CoreGraphics)
        color = property.color
#endif
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let clone = MDLMaterialProperty(name: name, semantic: semantic)
        clone.setProperties(self)
        clone.name = name
        return clone
    }
}

public class MDLScatteringFunction: NSObject, MDLNamed {
    public var name: String = "scattering"
    public let baseColor: MDLMaterialProperty
    public let emission: MDLMaterialProperty
    public let specular: MDLMaterialProperty
    public let materialIndexOfRefraction: MDLMaterialProperty
    public let interfaceIndexOfRefraction: MDLMaterialProperty
    public let normal: MDLMaterialProperty
    public let ambientOcclusion: MDLMaterialProperty
    public let ambientOcclusionScale: MDLMaterialProperty

    public override init() {
        baseColor = MDLMaterialProperty(name: "baseColor", semantic: .baseColor, float3: SIMD3(0.8, 0.8, 0.8))
        emission = MDLMaterialProperty(name: "emission", semantic: .emission, float3: SIMD3())
        specular = MDLMaterialProperty(name: "specular", semantic: .specular, float: 0)
        materialIndexOfRefraction = MDLMaterialProperty(name: "ior", semantic: .materialIndexOfRefraction, float: 1.5)
        interfaceIndexOfRefraction = MDLMaterialProperty(name: "interfaceIor", semantic: .interfaceIndexOfRefraction, float: 1)
        normal = MDLMaterialProperty(name: "normal", semantic: .tangentSpaceNormal, float3: SIMD3(0, 0, 1))
        ambientOcclusion = MDLMaterialProperty(name: "ao", semantic: .ambientOcclusion, float: 1)
        ambientOcclusionScale = MDLMaterialProperty(name: "aoScale", semantic: .ambientOcclusionScale, float: 1)
        super.init()
    }
}

public class MDLPhysicallyPlausibleScatteringFunction: MDLScatteringFunction {
    public let version: Int = 1
    public let subsurface: MDLMaterialProperty
    public let metallic: MDLMaterialProperty
    public let specularAmount: MDLMaterialProperty
    public let specularTint: MDLMaterialProperty
    public let roughness: MDLMaterialProperty
    public let anisotropic: MDLMaterialProperty
    public let anisotropicRotation: MDLMaterialProperty
    public let sheen: MDLMaterialProperty
    public let sheenTint: MDLMaterialProperty
    public let clearcoat: MDLMaterialProperty
    public let clearcoatGloss: MDLMaterialProperty

    public override init() {
        subsurface = MDLMaterialProperty(name: "subsurface", semantic: .subsurface, float: 0)
        metallic = MDLMaterialProperty(name: "metallic", semantic: .metallic, float: 0)
        specularAmount = MDLMaterialProperty(name: "specularAmount", semantic: .specular, float: 0.5)
        specularTint = MDLMaterialProperty(name: "specularTint", semantic: .specularTint, float: 0)
        roughness = MDLMaterialProperty(name: "roughness", semantic: .roughness, float: 0.5)
        anisotropic = MDLMaterialProperty(name: "anisotropic", semantic: .anisotropic, float: 0)
        anisotropicRotation = MDLMaterialProperty(name: "anisotropicRotation", semantic: .anisotropicRotation, float: 0)
        sheen = MDLMaterialProperty(name: "sheen", semantic: .sheen, float: 0)
        sheenTint = MDLMaterialProperty(name: "sheenTint", semantic: .sheenTint, float: 0)
        clearcoat = MDLMaterialProperty(name: "clearcoat", semantic: .clearcoat, float: 0)
        clearcoatGloss = MDLMaterialProperty(name: "clearcoatGloss", semantic: .clearcoatGloss, float: 1)
        super.init()
    }
}

public class MDLMaterial: NSObject, MDLNamed {
    public var name: String
    public var scatteringFunction: MDLScatteringFunction
    public var base: MDLMaterial?
    public var materialFace: MDLMaterialFace = .front
    private var storage: [MDLMaterialProperty] = []

    public var count: UInt { UInt(storage.count) }

    public init(name: String, scatteringFunction: MDLScatteringFunction) {
        self.name = name
        self.scatteringFunction = scatteringFunction
        super.init()
    }

    public convenience override init() {
        self.init(name: "", scatteringFunction: MDLPhysicallyPlausibleScatteringFunction())
    }

    public func setProperty(_ property: MDLMaterialProperty) {
        if let index = storage.firstIndex(where: { $0.name == property.name }) {
            storage[index] = property
        } else {
            storage.append(property)
        }
    }

    public func remove(_ property: MDLMaterialProperty) {
        storage.removeAll { $0 === property || $0.name == property.name }
    }

    public func removeAllProperties() {
        storage.removeAll()
    }

    public func propertyNamed(_ name: String) -> MDLMaterialProperty? {
        storage.first { $0.name == name } ?? base?.propertyNamed(name)
    }

    public func property(with semantic: MDLMaterialSemantic) -> MDLMaterialProperty? {
        storage.first { $0.semantic == semantic } ?? base?.property(with: semantic)
    }

    public func properties(with semantic: MDLMaterialSemantic) -> [MDLMaterialProperty] {
        storage.filter { $0.semantic == semantic }
    }

    public subscript(idx: UInt) -> MDLMaterialProperty? {
        guard idx < count else { return nil }
        return storage[Int(idx)]
    }

    public subscript(name: String) -> MDLMaterialProperty? {
        propertyNamed(name)
    }

    public func loadTextures(using resolver: any MDLAssetResolver) {
        resolveTextures(with: resolver)
    }

    public func resolveTextures(with resolver: any MDLAssetResolver) {
        for property in storage {
            if let name = property.stringValue ?? property.urlValue?.lastPathComponent,
               resolver.canResolveAssetNamed(name) {
                property.urlValue = resolver.resolveAssetNamed(name)
            }
        }
    }

}

public class MDLMaterialPropertyNode: NSObject, MDLNamed {
    public var name: String = ""
    public var inputs: [MDLMaterialProperty]
    public var outputs: [MDLMaterialProperty]
    public var evaluationFunction: (MDLMaterialPropertyNode) -> Void

    public init(
        inputs: [MDLMaterialProperty],
        outputs: [MDLMaterialProperty],
        evaluationFunction function: @escaping (MDLMaterialPropertyNode) -> Void
    ) {
        self.inputs = inputs
        self.outputs = outputs
        self.evaluationFunction = function
        super.init()
    }
}

public class MDLMaterialPropertyConnection: NSObject, MDLNamed {
    public var name: String = ""
    public private(set) weak var output: MDLMaterialProperty?
    public private(set) weak var input: MDLMaterialProperty?

    public init(output: MDLMaterialProperty, input: MDLMaterialProperty) {
        self.output = output
        self.input = input
        super.init()
    }
}

public class MDLMaterialPropertyGraph: MDLMaterialPropertyNode {
    public let nodes: [MDLMaterialPropertyNode]
    public let connections: [MDLMaterialPropertyConnection]

    public init(nodes: [MDLMaterialPropertyNode], connections: [MDLMaterialPropertyConnection]) {
        self.nodes = nodes
        self.connections = connections
        super.init(inputs: [], outputs: [], evaluationFunction: { _ in })
    }

    public func evaluate() {
        for connection in connections {
            if let output = connection.output, let input = connection.input {
                input.setProperties(output)
            }
        }
        for node in nodes {
            node.evaluationFunction(node)
        }
    }
}
