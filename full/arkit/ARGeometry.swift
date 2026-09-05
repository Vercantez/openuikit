import Foundation

open class ARFaceGeometry: NSObject, NSSecureCoding {
    public var vertexCount: Int { vertices.count }
    public var triangleCount: Int { triangleIndices.count / 3 }
    public var vertices: [simd_float3] { _vertices }
    public var textureCoordinates: [vector_float2] { _textureCoordinates }
    public var triangleIndices: [Int16] { _triangleIndices }

    private let _vertices: [simd_float3]
    private let _textureCoordinates: [vector_float2]
    private let _triangleIndices: [Int16]

    public static var supportsSecureCoding: Bool { true }

    public init(
        vertices: [simd_float3] = [],
        textureCoordinates: [vector_float2] = [],
        triangleIndices: [Int16] = []
    ) {
        self._vertices = vertices
        self._textureCoordinates = textureCoordinates
        self._triangleIndices = triangleIndices
        super.init()
    }

    public init?(blendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber]) {
        _ = blendShapes
        return nil
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }
}

open class ARPlaneGeometry: NSObject, NSSecureCoding {
    public var vertexCount: Int { vertices.count }
    public var triangleCount: Int { triangleIndices.count / 3 }
    public var vertices: [simd_float3] { _vertices }
    public var textureCoordinates: [vector_float2] { _textureCoordinates }
    public var triangleIndices: [Int16] { _triangleIndices }
    public var boundaryVertices: [simd_float3] { _boundaryVertices }

    private let _vertices: [simd_float3]
    private let _textureCoordinates: [vector_float2]
    private let _triangleIndices: [Int16]
    private let _boundaryVertices: [simd_float3]

    public static var supportsSecureCoding: Bool { true }

    public init(
        vertices: [simd_float3] = [],
        textureCoordinates: [vector_float2] = [],
        triangleIndices: [Int16] = [],
        boundaryVertices: [simd_float3] = []
    ) {
        self._vertices = vertices
        self._textureCoordinates = textureCoordinates
        self._triangleIndices = triangleIndices
        self._boundaryVertices = boundaryVertices
        super.init()
    }

    static func rectangle(center: simd_float3, extent: simd_float3) -> ARPlaneGeometry {
        let hx = extent.x / 2
        let hz = extent.z / 2
        let vertices = [
            simd_float3(center.x - hx, center.y, center.z - hz),
            simd_float3(center.x + hx, center.y, center.z - hz),
            simd_float3(center.x + hx, center.y, center.z + hz),
            simd_float3(center.x - hx, center.y, center.z + hz),
        ]
        let textureCoordinates: [vector_float2] = [
            simd_float2(0, 0),
            simd_float2(1, 0),
            simd_float2(1, 1),
            simd_float2(0, 1),
        ]
        let triangleIndices: [Int16] = [0, 1, 2, 0, 2, 3]
        return ARPlaneGeometry(
            vertices: vertices,
            textureCoordinates: textureCoordinates,
            triangleIndices: triangleIndices,
            boundaryVertices: vertices
        )
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }
}

open class ARGeometrySource: NSObject, NSSecureCoding {
    public var componentsPerVector: Int { _componentsPerVector }
    public var count: Int { _count }
    public var offset: Int { _offset }
    public var stride: Int { _stride }
    public var buffer: any MTLBuffer { ARKitHostMTLBuffer() }
    public var format: MTLVertexFormat { componentsPerVector == 3 ? .float3 : .float }

    private let _componentsPerVector: Int
    private let _count: Int
    private let _offset: Int
    private let _stride: Int

    public static var supportsSecureCoding: Bool { true }

    init(componentsPerVector: Int = 3, count: Int = 0, offset: Int = 0, stride: Int = 12) {
        self._componentsPerVector = componentsPerVector
        self._count = count
        self._offset = offset
        self._stride = stride
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }

    public subscript(index: Int32) -> (Float, Float, Float) {
        _ = index
        return (0, 0, 0)
    }
}

open class ARGeometryElement: NSObject, NSSecureCoding {
    public var bytesPerIndex: Int { _bytesPerIndex }
    public var count: Int { _count }
    public var indexCountPerPrimitive: Int { _indexCountPerPrimitive }
    public var primitiveType: ARGeometryPrimitiveType { _primitiveType }
    public var buffer: any MTLBuffer { ARKitHostMTLBuffer() }

    private let _bytesPerIndex: Int
    private let _count: Int
    private let _indexCountPerPrimitive: Int
    private let _primitiveType: ARGeometryPrimitiveType

    public static var supportsSecureCoding: Bool { true }

    init(
        bytesPerIndex: Int = 4,
        count: Int = 0,
        indexCountPerPrimitive: Int = 3,
        primitiveType: ARGeometryPrimitiveType = .triangle
    ) {
        self._bytesPerIndex = bytesPerIndex
        self._count = count
        self._indexCountPerPrimitive = indexCountPerPrimitive
        self._primitiveType = primitiveType
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }

    public subscript(index: Int) -> [Int32] {
        _ = index
        return []
    }
}

open class ARMeshGeometry: NSObject, NSSecureCoding {
    public var vertices: ARGeometrySource { _vertices }
    public var normals: ARGeometrySource { _normals }
    public var faces: ARGeometryElement { _faces }
    public var classification: ARGeometrySource? { nil }

    private let _vertices: ARGeometrySource
    private let _normals: ARGeometrySource
    private let _faces: ARGeometryElement

    public static var supportsSecureCoding: Bool { true }

    init(
        vertices: ARGeometrySource = ARGeometrySource(),
        normals: ARGeometrySource = ARGeometrySource(),
        faces: ARGeometryElement = ARGeometryElement()
    ) {
        self._vertices = vertices
        self._normals = normals
        self._faces = faces
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }
}

open class ARSkeletonDefinition: NSObject {
    public class var defaultBody2D: ARSkeletonDefinition { _defaultBody2D }
    public class var defaultBody3D: ARSkeletonDefinition { _defaultBody3D }

    public var jointCount: Int { jointNames.count }
    public var jointNames: [String] { _jointNames }
    public var parentIndices: [Int] { _parentIndices }
    public var neutralBodySkeleton3D: ARSkeleton3D? { nil }

    private let _jointNames: [String]
    private let _parentIndices: [Int]

    private static let _defaultBody2D = ARSkeletonDefinition(jointNames: ARSkeleton.JointName.knownNames)
    private static let _defaultBody3D = ARSkeletonDefinition(jointNames: ARSkeleton.JointName.knownNames)

    init(jointNames: [String]) {
        self._jointNames = jointNames
        self._parentIndices = jointNames.enumerated().map { index, _ in index == 0 ? -1 : 0 }
        super.init()
    }

    public func index(for jointName: ARSkeleton.JointName) -> Int {
        jointNames.firstIndex(of: jointName.rawValue) ?? -1
    }
}

open class ARSkeleton: NSObject {
    public struct JointName: RawRepresentable, Hashable, Sendable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public static let root = JointName(rawValue: "root")
        public static let head = JointName(rawValue: "head_joint")
        public static let leftShoulder = JointName(rawValue: "left_shoulder_1_joint")
        public static let rightShoulder = JointName(rawValue: "right_shoulder_1_joint")
        public static let leftHand = JointName(rawValue: "left_hand_joint")
        public static let rightHand = JointName(rawValue: "right_hand_joint")
        public static let leftFoot = JointName(rawValue: "left_foot_joint")
        public static let rightFoot = JointName(rawValue: "right_foot_joint")

        public init?(_ recognizedPointKey: VNRecognizedPointKey) {
            // Vision recognized-point keys are not observed on this host.
            _ = recognizedPointKey
            return nil
        }

        static var knownNames: [String] {
            [
                root.rawValue,
                head.rawValue,
                leftShoulder.rawValue,
                rightShoulder.rawValue,
                leftHand.rawValue,
                rightHand.rawValue,
                leftFoot.rawValue,
                rightFoot.rawValue,
            ]
        }
    }

    public var definition: ARSkeletonDefinition { _definition }

    private let _definition: ARSkeletonDefinition

    public init(definition: ARSkeletonDefinition = .defaultBody3D) {
        self._definition = definition
        super.init()
    }

    public func isJointTracked(_ jointIndex: Int) -> Bool {
        _ = jointIndex
        return false
    }
}

open class ARSkeleton3D: ARSkeleton {
    public var jointLocalTransforms: [simd_float4x4] { [] }
    public var jointModelTransforms: [simd_float4x4] { [] }

    public func localTransform(for jointName: ARSkeleton.JointName) -> simd_float4x4? {
        _ = jointName
        return nil
    }

    public func modelTransform(for jointName: ARSkeleton.JointName) -> simd_float4x4? {
        _ = jointName
        return nil
    }
}

open class ARSkeleton2D: ARSkeleton {
    public var jointLandmarks: [simd_float2] { [] }

    public func landmark(for jointName: ARSkeleton.JointName) -> simd_float2? {
        _ = jointName
        return nil
    }
}

open class ARBody2D: NSObject {
    public var skeleton: ARSkeleton2D { _skeleton }
    private let _skeleton = ARSkeleton2D(definition: .defaultBody2D)
}
