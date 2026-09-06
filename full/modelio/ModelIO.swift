import Foundation

/// Linux starting point for Apple's public ModelIO module.
/// Isolated host compilation produces `libModelIO.dylib` with Foundation only.
/// Texture UTI `write(to:type:)` takes `NSString` on this host (no CoreFoundation CFString).

public let MDLVertexAttributeAnisotropy = "anisotropy"
public let MDLVertexAttributeBinormal = "binormal"
public let MDLVertexAttributeBitangent = "bitangent"
public let MDLVertexAttributeColor = "color"
public let MDLVertexAttributeEdgeCrease = "edgeCrease"
public let MDLVertexAttributeJointIndices = "jointIndices"
public let MDLVertexAttributeJointWeights = "jointWeights"
public let MDLVertexAttributeNormal = "normal"
public let MDLVertexAttributeOcclusionValue = "occlusionValue"
public let MDLVertexAttributePosition = "position"
public let MDLVertexAttributeShadingBasisU = "shadingBasisU"
public let MDLVertexAttributeShadingBasisV = "shadingBasisV"
public let MDLVertexAttributeSubdivisionStencil = "subdivisionStencil"
public let MDLVertexAttributeTangent = "tangent"
public let MDLVertexAttributeTextureCoordinate = "textureCoordinate"

/// Public UTI *names* as documented identifiers. Exact Apple payload strings
/// remain an oracle question; tests assert these Linux constants, not Apple's
/// binary table.
public let kUTType3dObject = "public.3d-content"
public let kUTTypeAlembic = "org.alembic.alembic"
public let kUTTypePolygon = "public.polygon-file"
public let kUTTypeStereolithography = "public.standard-tesselated-geometry-format"
public let kUTTypeUniversalSceneDescription = "com.pixar.universal-scene-description"
public let kUTTypeUniversalSceneDescriptionMobile = "com.pixar.universal-scene-description-mobile"

public let ModelIOLinuxErrorDomain = "org.openuikit.ModelIO.linux"

public enum ModelIOLinuxErrorCode: Int, Sendable {
    case appleImporterRequired = 1
    case unsupportedFileExtension = 2
    case exportFailed = 3
    case emptyBuffer = 4
}

public enum ModelIOLinuxError: Error, Equatable {
    case appleImporterRequired(String)
    case unsupportedFileExtension(String)
    case exportFailed(String)
    case emptyBuffer

    public var nsError: NSError {
        let code: ModelIOLinuxErrorCode
        let message: String
        switch self {
        case .appleImporterRequired(let ext):
            code = .appleImporterRequired
            message = "Apple USD/Alembic importer is required for .\(ext)"
        case .unsupportedFileExtension(let ext):
            code = .unsupportedFileExtension
            message = "No Linux importer for .\(ext)"
        case .exportFailed(let ext):
            code = .exportFailed
            message = "Linux exporter refused .\(ext)"
        case .emptyBuffer:
            code = .emptyBuffer
            message = "Mesh buffer is empty"
        }
        return NSError(
            domain: ModelIOLinuxErrorDomain,
            code: code.rawValue,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}

func modelIOLinuxError(_ error: ModelIOLinuxError) -> NSError {
    error.nsError
}

func modelIOChannelByteCount(_ encoding: MDLTextureChannelEncoding) -> Int {
    switch encoding {
    case .uInt8: return 1
    case .uInt16: return 2
    case .uInt24: return 3
    case .uInt32: return 4
    case .float16, .float16SR: return 2
    case .float32: return 4
    }
}

func modelIOVertexFormatStride(_ format: MDLVertexFormat) -> Int {
    let packed = (format.rawValue & MDLVertexFormat.packedBit.rawValue) != 0
    if packed {
        return 4
    }
    let count = Int(format.rawValue & 0xF)
    let bits = format.rawValue & 0xF0000
    let component: Int
    switch bits {
    case MDLVertexFormat.uCharBits.rawValue,
         MDLVertexFormat.charBits.rawValue,
         MDLVertexFormat.uCharNormalizedBits.rawValue,
         MDLVertexFormat.charNormalizedBits.rawValue:
        component = 1
    case MDLVertexFormat.uShortBits.rawValue,
         MDLVertexFormat.shortBits.rawValue,
         MDLVertexFormat.uShortNormalizedBits.rawValue,
         MDLVertexFormat.shortNormalizedBits.rawValue,
         MDLVertexFormat.halfBits.rawValue:
        component = 2
    default:
        component = 4
    }
    return max(component * max(count, 1), 0)
}
