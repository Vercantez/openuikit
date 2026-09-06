import Foundation

public enum MDLAnimatedValueInterpolation: UInt, Equatable, Hashable, Sendable {
    case constant = 0
    case linear = 1
}

public enum MDLCameraProjection: UInt, Equatable, Hashable, Sendable {
    case perspective = 0
    case orthographic = 1
}

public enum MDLDataPrecision: UInt, Equatable, Hashable, Sendable {
    case undefined = 0
    case float = 1
    case double = 2
}

public enum MDLGeometryType: Int, Equatable, Hashable, Sendable {
    case points = 0
    case lines = 1
    case triangles = 2
    case triangleStrips = 3
    case quads = 4
    case variableTopology = 5
}

public enum MDLIndexBitDepth: UInt, Equatable, Hashable, Sendable {
    case invalid = 0
    case uInt8 = 8
    case uInt16 = 16
    case uInt32 = 32

    public static var uint8: MDLIndexBitDepth { .uInt8 }
    public static var uint16: MDLIndexBitDepth { .uInt16 }
    public static var uint32: MDLIndexBitDepth { .uInt32 }
}

public enum MDLLightType: UInt, Equatable, Hashable, Sendable {
    case unknown = 0
    case ambient = 1
    case directional = 2
    case spot = 3
    case point = 4
    case linear = 5
    case discArea = 6
    case rectangularArea = 7
    case superElliptical = 8
    case photometric = 9
    case probe = 10
    case environment = 11
}

public enum MDLMaterialFace: UInt, Equatable, Hashable, Sendable {
    case front = 0
    case back = 1
    case doubleSided = 2
}

public enum MDLMaterialMipMapFilterMode: UInt, Equatable, Hashable, Sendable {
    case nearest = 0
    case linear = 1
}

public enum MDLMaterialPropertyType: UInt, Equatable, Hashable, Sendable {
    case none = 0
    case string = 1
    case URL = 2
    case texture = 3
    case color = 4
    case float = 5
    case float2 = 6
    case float3 = 7
    case float4 = 8
    case matrix44 = 9
    case buffer = 10
}

public enum MDLMaterialSemantic: UInt, Equatable, Hashable, Sendable {
    case baseColor = 0
    case subsurface = 1
    case metallic = 2
    case specular = 3
    case specularExponent = 4
    case specularTint = 5
    case roughness = 6
    case anisotropic = 7
    case anisotropicRotation = 8
    case sheen = 9
    case sheenTint = 10
    case clearcoat = 11
    case clearcoatGloss = 12
    case emission = 13
    case bump = 14
    case opacity = 15
    case interfaceIndexOfRefraction = 16
    case materialIndexOfRefraction = 17
    case objectSpaceNormal = 18
    case tangentSpaceNormal = 19
    case displacement = 20
    case displacementScale = 21
    case ambientOcclusion = 22
    case ambientOcclusionScale = 23
    case none = 0x8000
    case userDefined = 0x8001
}

public enum MDLMaterialTextureFilterMode: UInt, Equatable, Hashable, Sendable {
    case nearest = 0
    case linear = 1
}

public enum MDLMaterialTextureWrapMode: UInt, Equatable, Hashable, Sendable {
    case clamp = 0
    case `repeat` = 1
    case mirror = 2
}

public enum MDLMeshBufferType: UInt, Equatable, Hashable, Sendable {
    case vertex = 1
    case index = 2
    case custom = 3
}

public enum MDLProbePlacement: Int, Equatable, Hashable, Sendable {
    case uniformGrid = 0
    case irradianceDistribution = 1
}

public enum MDLTextureChannelEncoding: Int, Equatable, Hashable, Sendable {
    case uInt8 = 1
    case uInt16 = 2
    case uInt24 = 3
    case uInt32 = 4
    case float16 = 258
    case float16SR = 770
    case float32 = 260

    public static var uint8: MDLTextureChannelEncoding { .uInt8 }
    public static var uint16: MDLTextureChannelEncoding { .uInt16 }
    public static var uint24: MDLTextureChannelEncoding { .uInt24 }
    public static var uint32: MDLTextureChannelEncoding { .uInt32 }
}

public enum MDLTransformOpRotationOrder: UInt, Equatable, Hashable, Sendable {
    case xyz = 1
    case xzy = 2
    case yxz = 3
    case yzx = 4
    case zxy = 5
    case zyx = 6
}

public struct MDLVertexFormat: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt

    public init?(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public init(_ raw: UInt) {
        self.rawValue = raw
    }

    public static let invalid = MDLVertexFormat(0)
    public static let packedBit = MDLVertexFormat(0x1000)
    public static let uCharBits = MDLVertexFormat(0x10000)
    public static let charBits = MDLVertexFormat(0x20000)
    public static let uCharNormalizedBits = MDLVertexFormat(0x30000)
    public static let charNormalizedBits = MDLVertexFormat(0x40000)
    public static let uShortBits = MDLVertexFormat(0x50000)
    public static let shortBits = MDLVertexFormat(0x60000)
    public static let uShortNormalizedBits = MDLVertexFormat(0x70000)
    public static let shortNormalizedBits = MDLVertexFormat(0x80000)
    public static let uIntBits = MDLVertexFormat(0x90000)
    public static let intBits = MDLVertexFormat(0xA0000)
    public static let halfBits = MDLVertexFormat(0xB0000)
    public static let floatBits = MDLVertexFormat(0xC0000)

    public static let uChar = MDLVertexFormat(0x10000 | 1)
    public static let uChar2 = MDLVertexFormat(0x10000 | 2)
    public static let uChar3 = MDLVertexFormat(0x10000 | 3)
    public static let uChar4 = MDLVertexFormat(0x10000 | 4)
    public static let char = MDLVertexFormat(0x20000 | 1)
    public static let char2 = MDLVertexFormat(0x20000 | 2)
    public static let char3 = MDLVertexFormat(0x20000 | 3)
    public static let char4 = MDLVertexFormat(0x20000 | 4)
    public static let uCharNormalized = MDLVertexFormat(0x30000 | 1)
    public static let uChar2Normalized = MDLVertexFormat(0x30000 | 2)
    public static let uChar3Normalized = MDLVertexFormat(0x30000 | 3)
    public static let uChar4Normalized = MDLVertexFormat(0x30000 | 4)
    public static let charNormalized = MDLVertexFormat(0x40000 | 1)
    public static let char2Normalized = MDLVertexFormat(0x40000 | 2)
    public static let char3Normalized = MDLVertexFormat(0x40000 | 3)
    public static let char4Normalized = MDLVertexFormat(0x40000 | 4)
    public static let uShort = MDLVertexFormat(0x50000 | 1)
    public static let uShort2 = MDLVertexFormat(0x50000 | 2)
    public static let uShort3 = MDLVertexFormat(0x50000 | 3)
    public static let uShort4 = MDLVertexFormat(0x50000 | 4)
    public static let short = MDLVertexFormat(0x60000 | 1)
    public static let short2 = MDLVertexFormat(0x60000 | 2)
    public static let short3 = MDLVertexFormat(0x60000 | 3)
    public static let short4 = MDLVertexFormat(0x60000 | 4)
    public static let uShortNormalized = MDLVertexFormat(0x70000 | 1)
    public static let uShort2Normalized = MDLVertexFormat(0x70000 | 2)
    public static let uShort3Normalized = MDLVertexFormat(0x70000 | 3)
    public static let uShort4Normalized = MDLVertexFormat(0x70000 | 4)
    public static let shortNormalized = MDLVertexFormat(0x80000 | 1)
    public static let short2Normalized = MDLVertexFormat(0x80000 | 2)
    public static let short3Normalized = MDLVertexFormat(0x80000 | 3)
    public static let short4Normalized = MDLVertexFormat(0x80000 | 4)
    public static let uInt = MDLVertexFormat(0x90000 | 1)
    public static let uInt2 = MDLVertexFormat(0x90000 | 2)
    public static let uInt3 = MDLVertexFormat(0x90000 | 3)
    public static let uInt4 = MDLVertexFormat(0x90000 | 4)
    public static let int = MDLVertexFormat(0xA0000 | 1)
    public static let int2 = MDLVertexFormat(0xA0000 | 2)
    public static let int3 = MDLVertexFormat(0xA0000 | 3)
    public static let int4 = MDLVertexFormat(0xA0000 | 4)
    public static let half = MDLVertexFormat(0xB0000 | 1)
    public static let half2 = MDLVertexFormat(0xB0000 | 2)
    public static let half3 = MDLVertexFormat(0xB0000 | 3)
    public static let half4 = MDLVertexFormat(0xB0000 | 4)
    public static let float = MDLVertexFormat(0xC0000 | 1)
    public static let float2 = MDLVertexFormat(0xC0000 | 2)
    public static let float3 = MDLVertexFormat(0xC0000 | 3)
    public static let float4 = MDLVertexFormat(0xC0000 | 4)
    public static let int1010102Normalized = MDLVertexFormat(0xA0000 | 0x1000 | 4)
    public static let uInt1010102Normalized = MDLVertexFormat(0x90000 | 0x1000 | 4)
}
