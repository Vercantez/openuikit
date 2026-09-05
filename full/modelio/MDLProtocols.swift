import Foundation

public protocol MDLNamed: AnyObject {
    var name: String { get set }
}

public protocol MDLComponent: NSObjectProtocol {}

public protocol MDLJointAnimation: AnyObject {}

public protocol MDLAssetResolver: NSObjectProtocol {
    func canResolveAssetNamed(_ name: String) -> Bool
    func resolveAssetNamed(_ name: String) -> URL
}

public protocol MDLMeshBuffer: NSCopying, NSObjectProtocol {
    var allocator: any MDLMeshBufferAllocator { get }
    var length: UInt { get }
    var type: MDLMeshBufferType { get }
    var zone: any MDLMeshBufferZone { get }
    func fill(_ data: Data, offset: UInt)
    func map() -> MDLMeshBufferMap
}

public protocol MDLMeshBufferAllocator: NSObjectProtocol {
    func newBuffer(_ length: UInt, type: MDLMeshBufferType) -> any MDLMeshBuffer
    func newBuffer(from zone: (any MDLMeshBufferZone)?, data: Data, type: MDLMeshBufferType) -> (any MDLMeshBuffer)?
    func newBuffer(from zone: (any MDLMeshBufferZone)?, length: UInt, type: MDLMeshBufferType) -> (any MDLMeshBuffer)?
    func newBuffer(with data: Data, type: MDLMeshBufferType) -> any MDLMeshBuffer
    func newZone(_ capacity: UInt) -> any MDLMeshBufferZone
    func newZoneForBuffers(withSize sizes: [NSNumber], andType types: [NSNumber]) -> any MDLMeshBufferZone
}

public protocol MDLMeshBufferZone: NSObjectProtocol {
    var allocator: any MDLMeshBufferAllocator { get }
    var capacity: UInt { get }
}

/// Apple inherits `NSFastEnumeration`; Linux Foundation does not expose it.
public protocol MDLObjectContainerComponent: MDLComponent {
    var count: UInt { get }
    var objects: [MDLObject] { get }
    func add(_ object: MDLObject)
    func remove(_ object: MDLObject)
    subscript(index: UInt) -> MDLObject { get }
}

public protocol MDLTransformComponent: MDLComponent {
    var keyTimes: [NSNumber] { get }
    var matrix: matrix_float4x4 { get set }
    var maximumTime: TimeInterval { get }
    var minimumTime: TimeInterval { get }
    var resetsTransform: Bool { get set }
    func localTransform(atTime time: TimeInterval) -> matrix_float4x4
    func setLocalTransform(_ transform: matrix_float4x4)
    func setLocalTransform(_ transform: matrix_float4x4, forTime time: TimeInterval)
    static func globalTransform(with object: MDLObject, atTime time: TimeInterval) -> matrix_float4x4
}

public protocol MDLTransformOp: AnyObject {
    var name: String { get }
    func isInverseOp() -> Bool
    func double4x4(atTime time: TimeInterval) -> matrix_double4x4
    func float4x4(atTime time: TimeInterval) -> matrix_float4x4
}

public protocol MDLLightProbeIrradianceDataSource: NSObjectProtocol {
    var boundingBox: MDLAxisAlignedBoundingBox { get set }
    var sphericalHarmonicsLevel: UInt { get set }
    func sphericalHarmonicsCoefficients(atPosition position: SIMD3<Float>) -> Data
}

extension MDLTransformComponent {
    public static func globalTransform(with object: MDLObject, atTime time: TimeInterval) -> matrix_float4x4 {
        var current: MDLObject? = object
        var result = matrix_float4x4.identity
        var chain: [MDLObject] = []
        while let node = current {
            chain.append(node)
            current = node.parent
        }
        for node in chain.reversed() {
            if let transform = node.transform {
                result = mdlMul(result, transform.localTransform(atTime: time))
            }
        }
        return result
    }
}
