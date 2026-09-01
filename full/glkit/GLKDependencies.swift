import Foundation

/// Linux stand-in for `OpenGLES.EAGLSharegroup` until that module is linked.
open class EAGLSharegroup: NSObject {}

/// Linux stand-in for `OpenGLES.EAGLContext` until that module is linked.
open class EAGLContext: NSObject {
    open var sharegroup: EAGLSharegroup?

    public override init() {
        super.init()
    }

    public init(sharegroup: EAGLSharegroup) {
        self.sharegroup = sharegroup
        super.init()
    }
}

/// Linux stand-in for `CoreGraphics.CGImage` until that module is linked.
open class CGImage: NSObject {}

/// Linux stand-in for `UIKit.UIImage` until that module is linked.
/// Snapshot APIs return an empty image rather than inventing framebuffer bytes.
open class UIImage: NSObject {
    public var size: CGSize = .zero
}

/// Linux stand-in for Model I/O until that module is linked.
public struct MDLVertexFormat: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let invalid = MDLVertexFormat(rawValue: 0)
    public static let packedBit = MDLVertexFormat(rawValue: 0x1000)
    public static let uCharBits = MDLVertexFormat(rawValue: 0x10000)
    public static let charBits = MDLVertexFormat(rawValue: 0x20000)
    public static let uCharNormalizedBits = MDLVertexFormat(rawValue: 0x30000)
    public static let charNormalizedBits = MDLVertexFormat(rawValue: 0x40000)
    public static let uShortBits = MDLVertexFormat(rawValue: 0x50000)
    public static let shortBits = MDLVertexFormat(rawValue: 0x60000)
    public static let uShortNormalizedBits = MDLVertexFormat(rawValue: 0x70000)
    public static let shortNormalizedBits = MDLVertexFormat(rawValue: 0x80000)
    public static let uIntBits = MDLVertexFormat(rawValue: 0x90000)
    public static let intBits = MDLVertexFormat(rawValue: 0xA0000)
    public static let halfBits = MDLVertexFormat(rawValue: 0xB0000)
    public static let floatBits = MDLVertexFormat(rawValue: 0xC0000)

    public static let uChar = MDLVertexFormat(rawValue: uCharBits.rawValue | 1)
    public static let uChar2 = MDLVertexFormat(rawValue: uCharBits.rawValue | 2)
    public static let uChar3 = MDLVertexFormat(rawValue: uCharBits.rawValue | 3)
    public static let uChar4 = MDLVertexFormat(rawValue: uCharBits.rawValue | 4)
    public static let char = MDLVertexFormat(rawValue: charBits.rawValue | 1)
    public static let char2 = MDLVertexFormat(rawValue: charBits.rawValue | 2)
    public static let char3 = MDLVertexFormat(rawValue: charBits.rawValue | 3)
    public static let char4 = MDLVertexFormat(rawValue: charBits.rawValue | 4)
    public static let uCharNormalized = MDLVertexFormat(rawValue: uCharNormalizedBits.rawValue | 1)
    public static let uChar2Normalized = MDLVertexFormat(rawValue: uCharNormalizedBits.rawValue | 2)
    public static let uChar3Normalized = MDLVertexFormat(rawValue: uCharNormalizedBits.rawValue | 3)
    public static let uChar4Normalized = MDLVertexFormat(rawValue: uCharNormalizedBits.rawValue | 4)
    public static let charNormalized = MDLVertexFormat(rawValue: charNormalizedBits.rawValue | 1)
    public static let char2Normalized = MDLVertexFormat(rawValue: charNormalizedBits.rawValue | 2)
    public static let char3Normalized = MDLVertexFormat(rawValue: charNormalizedBits.rawValue | 3)
    public static let char4Normalized = MDLVertexFormat(rawValue: charNormalizedBits.rawValue | 4)
    public static let uShort = MDLVertexFormat(rawValue: uShortBits.rawValue | 1)
    public static let uShort2 = MDLVertexFormat(rawValue: uShortBits.rawValue | 2)
    public static let uShort3 = MDLVertexFormat(rawValue: uShortBits.rawValue | 3)
    public static let uShort4 = MDLVertexFormat(rawValue: uShortBits.rawValue | 4)
    public static let short = MDLVertexFormat(rawValue: shortBits.rawValue | 1)
    public static let short2 = MDLVertexFormat(rawValue: shortBits.rawValue | 2)
    public static let short3 = MDLVertexFormat(rawValue: shortBits.rawValue | 3)
    public static let short4 = MDLVertexFormat(rawValue: shortBits.rawValue | 4)
    public static let uShortNormalized = MDLVertexFormat(rawValue: uShortNormalizedBits.rawValue | 1)
    public static let uShort2Normalized = MDLVertexFormat(rawValue: uShortNormalizedBits.rawValue | 2)
    public static let uShort3Normalized = MDLVertexFormat(rawValue: uShortNormalizedBits.rawValue | 3)
    public static let uShort4Normalized = MDLVertexFormat(rawValue: uShortNormalizedBits.rawValue | 4)
    public static let shortNormalized = MDLVertexFormat(rawValue: shortNormalizedBits.rawValue | 1)
    public static let short2Normalized = MDLVertexFormat(rawValue: shortNormalizedBits.rawValue | 2)
    public static let short3Normalized = MDLVertexFormat(rawValue: shortNormalizedBits.rawValue | 3)
    public static let short4Normalized = MDLVertexFormat(rawValue: shortNormalizedBits.rawValue | 4)
    public static let uInt = MDLVertexFormat(rawValue: uIntBits.rawValue | 1)
    public static let uInt2 = MDLVertexFormat(rawValue: uIntBits.rawValue | 2)
    public static let uInt3 = MDLVertexFormat(rawValue: uIntBits.rawValue | 3)
    public static let uInt4 = MDLVertexFormat(rawValue: uIntBits.rawValue | 4)
    public static let int = MDLVertexFormat(rawValue: intBits.rawValue | 1)
    public static let int2 = MDLVertexFormat(rawValue: intBits.rawValue | 2)
    public static let int3 = MDLVertexFormat(rawValue: intBits.rawValue | 3)
    public static let int4 = MDLVertexFormat(rawValue: intBits.rawValue | 4)
    public static let half = MDLVertexFormat(rawValue: halfBits.rawValue | 1)
    public static let half2 = MDLVertexFormat(rawValue: halfBits.rawValue | 2)
    public static let half3 = MDLVertexFormat(rawValue: halfBits.rawValue | 3)
    public static let half4 = MDLVertexFormat(rawValue: halfBits.rawValue | 4)
    public static let float = MDLVertexFormat(rawValue: floatBits.rawValue | 1)
    public static let float2 = MDLVertexFormat(rawValue: floatBits.rawValue | 2)
    public static let float3 = MDLVertexFormat(rawValue: floatBits.rawValue | 3)
    public static let float4 = MDLVertexFormat(rawValue: floatBits.rawValue | 4)
}

public enum MDLMeshBufferType: UInt, Sendable {
    case vertex = 0
    case index = 1
}

public protocol MDLMeshBufferZone: AnyObject {}

open class MDLVertexDescriptor: NSObject {}

open class MDLAsset: NSObject {}

open class MDLMesh: NSObject {
    open var name: String = ""
    open var vertexCount: Int = 0
    open var vertexDescriptor = MDLVertexDescriptor()
}
