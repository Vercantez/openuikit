import Foundation

public struct _MPSPackedFloat3: Equatable, Sendable {
    public var x: Float
    public var y: Float
    public var z: Float

    public var elements: (Float, Float, Float) {
        get { (x, y, z) }
        set {
            x = newValue.0
            y = newValue.1
            z = newValue.2
        }
    }

    public init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }

    public init() {
        self.init(x: 0, y: 0, z: 0)
    }

    public init(elements: (Float, Float, Float)) {
        self.init(x: elements.0, y: elements.1, z: elements.2)
    }

    public static func == (lhs: _MPSPackedFloat3, rhs: _MPSPackedFloat3) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
    }
}

public typealias MPSPackedFloat3 = _MPSPackedFloat3

public struct _MPSAxisAlignedBoundingBox: Equatable, Sendable {
    public var min: vector_float3
    public var max: vector_float3

    public init(min: vector_float3, max: vector_float3) {
        self.min = min
        self.max = max
    }

    public init() {
        self.init(min: .zero, max: .zero)
    }
}

public typealias MPSAxisAlignedBoundingBox = _MPSAxisAlignedBoundingBox

public struct MPSRayOriginDirection: Equatable, Sendable {
    public var origin: vector_float3
    public var direction: vector_float3

    public init(origin: vector_float3, direction: vector_float3) {
        self.origin = origin
        self.direction = direction
    }

    public init() {
        self.init(origin: .zero, direction: .zero)
    }
}

public struct MPSRayPackedOriginDirection: Equatable, Sendable {
    public var origin: MPSPackedFloat3
    public var direction: MPSPackedFloat3

    public init(origin: MPSPackedFloat3, direction: MPSPackedFloat3) {
        self.origin = origin
        self.direction = direction
    }

    public init() {
        self.init(origin: MPSPackedFloat3(), direction: MPSPackedFloat3())
    }
}

public struct MPSRayOriginMaskDirectionMaxDistance: Equatable, Sendable {
    public var origin: MPSPackedFloat3
    public var mask: UInt32
    public var direction: MPSPackedFloat3
    public var maxDistance: Float

    public init(
        origin: MPSPackedFloat3,
        mask: UInt32,
        direction: MPSPackedFloat3,
        maxDistance: Float
    ) {
        self.origin = origin
        self.mask = mask
        self.direction = direction
        self.maxDistance = maxDistance
    }

    public init() {
        self.init(origin: MPSPackedFloat3(), mask: 0, direction: MPSPackedFloat3(), maxDistance: 0)
    }
}

public struct MPSRayOriginMinDistanceDirectionMaxDistance: Equatable, Sendable {
    public var origin: MPSPackedFloat3
    public var minDistance: Float
    public var direction: MPSPackedFloat3
    public var maxDistance: Float

    public init(
        origin: MPSPackedFloat3,
        minDistance: Float,
        direction: MPSPackedFloat3,
        maxDistance: Float
    ) {
        self.origin = origin
        self.minDistance = minDistance
        self.direction = direction
        self.maxDistance = maxDistance
    }

    public init() {
        self.init(
            origin: MPSPackedFloat3(),
            minDistance: 0,
            direction: MPSPackedFloat3(),
            maxDistance: 0
        )
    }
}

public struct MPSIntersectionDistance: Equatable, Sendable {
    public var distance: Float

    public init(distance: Float) {
        self.distance = distance
    }

    public init() {
        self.init(distance: 0)
    }
}

public struct MPSIntersectionDistancePrimitiveIndex: Equatable, Sendable {
    public var distance: Float
    public var primitiveIndex: UInt32

    public init(distance: Float, primitiveIndex: UInt32) {
        self.distance = distance
        self.primitiveIndex = primitiveIndex
    }

    public init() {
        self.init(distance: 0, primitiveIndex: 0)
    }
}

public struct MPSIntersectionDistancePrimitiveIndexCoordinates: Equatable, Sendable {
    public var distance: Float
    public var primitiveIndex: UInt32
    public var coordinates: vector_float2

    public init(distance: Float, primitiveIndex: UInt32, coordinates: vector_float2) {
        self.distance = distance
        self.primitiveIndex = primitiveIndex
        self.coordinates = coordinates
    }

    public init() {
        self.init(distance: 0, primitiveIndex: 0, coordinates: .zero)
    }
}

public struct MPSIntersectionDistancePrimitiveIndexInstanceIndex: Equatable, Sendable {
    public var distance: Float
    public var primitiveIndex: UInt32
    public var instanceIndex: UInt32

    public init(distance: Float, primitiveIndex: UInt32, instanceIndex: UInt32) {
        self.distance = distance
        self.primitiveIndex = primitiveIndex
        self.instanceIndex = instanceIndex
    }

    public init() {
        self.init(distance: 0, primitiveIndex: 0, instanceIndex: 0)
    }
}

public struct MPSIntersectionDistancePrimitiveIndexInstanceIndexCoordinates: Equatable, Sendable {
    public var distance: Float
    public var primitiveIndex: UInt32
    public var instanceIndex: UInt32
    public var coordinates: vector_float2

    public init(
        distance: Float,
        primitiveIndex: UInt32,
        instanceIndex: UInt32,
        coordinates: vector_float2
    ) {
        self.distance = distance
        self.primitiveIndex = primitiveIndex
        self.instanceIndex = instanceIndex
        self.coordinates = coordinates
    }

    public init() {
        self.init(distance: 0, primitiveIndex: 0, instanceIndex: 0, coordinates: .zero)
    }
}

public struct MPSIntersectionDistancePrimitiveIndexBufferIndex: Equatable, Sendable {
    public var distance: Float
    public var primitiveIndex: UInt32
    public var bufferIndex: UInt32

    public init(distance: Float, primitiveIndex: UInt32, bufferIndex: UInt32) {
        self.distance = distance
        self.primitiveIndex = primitiveIndex
        self.bufferIndex = bufferIndex
    }

    public init() {
        self.init(distance: 0, primitiveIndex: 0, bufferIndex: 0)
    }
}

public struct MPSIntersectionDistancePrimitiveIndexBufferIndexCoordinates: Equatable, Sendable {
    public var distance: Float
    public var primitiveIndex: UInt32
    public var bufferIndex: UInt32
    public var coordinates: vector_float2

    public init(
        distance: Float,
        primitiveIndex: UInt32,
        bufferIndex: UInt32,
        coordinates: vector_float2
    ) {
        self.distance = distance
        self.primitiveIndex = primitiveIndex
        self.bufferIndex = bufferIndex
        self.coordinates = coordinates
    }

    public init() {
        self.init(distance: 0, primitiveIndex: 0, bufferIndex: 0, coordinates: .zero)
    }
}

public struct MPSIntersectionDistancePrimitiveIndexBufferIndexInstanceIndex: Equatable, Sendable {
    public var distance: Float
    public var primitiveIndex: UInt32
    public var bufferIndex: UInt32
    public var instanceIndex: UInt32

    public init(
        distance: Float,
        primitiveIndex: UInt32,
        bufferIndex: UInt32,
        instanceIndex: UInt32
    ) {
        self.distance = distance
        self.primitiveIndex = primitiveIndex
        self.bufferIndex = bufferIndex
        self.instanceIndex = instanceIndex
    }

    public init() {
        self.init(distance: 0, primitiveIndex: 0, bufferIndex: 0, instanceIndex: 0)
    }
}

public struct MPSIntersectionDistancePrimitiveIndexBufferIndexInstanceIndexCoordinates: Equatable, Sendable {
    public var distance: Float
    public var primitiveIndex: UInt32
    public var bufferIndex: UInt32
    public var instanceIndex: UInt32
    public var coordinates: vector_float2

    public init(
        distance: Float,
        primitiveIndex: UInt32,
        bufferIndex: UInt32,
        instanceIndex: UInt32,
        coordinates: vector_float2
    ) {
        self.distance = distance
        self.primitiveIndex = primitiveIndex
        self.bufferIndex = bufferIndex
        self.instanceIndex = instanceIndex
        self.coordinates = coordinates
    }

    public init() {
        self.init(distance: 0, primitiveIndex: 0, bufferIndex: 0, instanceIndex: 0, coordinates: .zero)
    }
}
