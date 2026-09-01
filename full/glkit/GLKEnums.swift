import Foundation

public enum GLKFogMode: Int32, Equatable, Hashable, Sendable {
    case exp = 0
    case exp2 = 1
    case linear = 2
}

public enum GLKLightingType: Int32, Equatable, Hashable, Sendable {
    case perVertex = 0
    case perPixel = 1
}

public enum GLKTextureEnvMode: Int32, Equatable, Hashable, Sendable {
    case replace = 0
    case modulate = 1
    case decal = 2
}

public enum GLKTextureInfoAlphaState: Int32, Equatable, Hashable, Sendable {
    case none = 0
    case nonPremultiplied = 1
    case premultiplied = 2
}

public enum GLKTextureInfoOrigin: Int32, Equatable, Hashable, Sendable {
    case unknown = 0
    case topLeft = 1
    case bottomLeft = 2
}

public enum GLKTextureTarget: UInt32, Equatable, Hashable, Sendable {
    case target2D = 0x0DE1
    case targetCubeMap = 0x8513
    case targetCt = 2
}

public enum GLKVertexAttrib: Int32, Equatable, Hashable, Sendable {
    case position = 0
    case normal = 1
    case color = 2
    case texCoord0 = 3
    case texCoord1 = 4
}

public enum GLKViewDrawableColorFormat: Int32, Equatable, Hashable, Sendable {
    case RGBA8888 = 0
    case RGB565 = 1
    case SRGBA8888 = 2
}

public enum GLKViewDrawableDepthFormat: Int32, Equatable, Hashable, Sendable {
    case formatNone = 0
    case format16 = 1
    case format24 = 2
}

public enum GLKViewDrawableStencilFormat: Int32, Equatable, Hashable, Sendable {
    case formatNone = 0
    case format8 = 1
}

public enum GLKViewDrawableMultisample: Int32, Equatable, Hashable, Sendable {
    case multisampleNone = 0
    case multisample4X = 1
}

public struct GLKTextureLoaderError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: UInt32, Hashable, Sendable {
        case fileOrURLNotFound = 0
        case invalidNSData = 1
        case invalidCGImage = 2
        case unknownPathType = 3
        case unknownFileType = 4
        case pvrAtlasUnsupported = 5
        case cubeMapInvalidNumFiles = 6
        case compressedTextureUpload = 7
        case uncompressedTextureUpload = 8
        case unsupportedCubeMapDimensions = 9
        case unsupportedBitDepth = 10
        case unsupportedPVRFormat = 11
        case dataPreprocessingFailure = 12
        case mipmapUnsupported = 13
        case unsupportedOrientation = 14
        case reorientationFailure = 15
        case alphaPremultiplicationFailure = 16
        case invalidEAGLContext = 17
        case incompatibleFormatSRGB = 18
        case unsupportedTextureTarget = 19
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    /// Identifier-as-string domain. Exact Apple payload is unobserved.
    public static var errorDomain: String { GLKTextureLoaderErrorDomain }
    public var errorCode: Int { Int(code.rawValue) }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let fileOrURLNotFound = Code.fileOrURLNotFound
    public static let invalidNSData = Code.invalidNSData
    public static let invalidCGImage = Code.invalidCGImage
    public static let unknownPathType = Code.unknownPathType
    public static let unknownFileType = Code.unknownFileType
    public static let pvrAtlasUnsupported = Code.pvrAtlasUnsupported
    public static let cubeMapInvalidNumFiles = Code.cubeMapInvalidNumFiles
    public static let compressedTextureUpload = Code.compressedTextureUpload
    public static let uncompressedTextureUpload = Code.uncompressedTextureUpload
    public static let unsupportedCubeMapDimensions = Code.unsupportedCubeMapDimensions
    public static let unsupportedBitDepth = Code.unsupportedBitDepth
    public static let unsupportedPVRFormat = Code.unsupportedPVRFormat
    public static let dataPreprocessingFailure = Code.dataPreprocessingFailure
    public static let mipmapUnsupported = Code.mipmapUnsupported
    public static let unsupportedOrientation = Code.unsupportedOrientation
    public static let reorientationFailure = Code.reorientationFailure
    public static let alphaPremultiplicationFailure = Code.alphaPremultiplicationFailure
    public static let invalidEAGLContext = Code.invalidEAGLContext
    public static let incompatibleFormatSRGB = Code.incompatibleFormatSRGB
    public static let unsupportedTextureTarget = Code.unsupportedTextureTarget

    public static func == (lhs: GLKTextureLoaderError, rhs: GLKTextureLoaderError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension GLKTextureLoaderError.Code {
    public static func ~= (match: GLKTextureLoaderError.Code, error: any Error) -> Bool {
        (error as? GLKTextureLoaderError)?.code == match
    }
}
