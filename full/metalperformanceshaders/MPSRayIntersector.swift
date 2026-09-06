import Foundation

open class MPSRayIntersector: MPSKernel, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public var cullMode: MTLCullMode = .none
    public var frontFacingWinding: MTLWinding = .clockwise
    public var intersectionDataType: MPSIntersectionDataType = .distance
    public var intersectionStride: Int = 0
    public var rayDataType: MPSRayDataType = .originDirection
    public var rayIndexDataType: MPSDataType = .uInt32
    public var rayMask: UInt32 = 0xFFFF_FFFF
    public var rayMaskOperator: MPSRayMaskOperator = .and
    public var rayMaskOptions: MPSRayMaskOptions = []
    public var rayStride: Int = 0
    public var boundingBoxIntersectionTestType: MPSBoundingBoxIntersectionTestType = .default
    public var triangleIntersectionTestType: MPSTriangleIntersectionTestType = .default

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }

    public required override init?(coder: NSCoder) {
        return nil
    }

    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = MPSRayIntersector(device: device ?? self.device)
        copied.options = options
        copied.label = label
        copied.cullMode = cullMode
        copied.frontFacingWinding = frontFacingWinding
        copied.intersectionDataType = intersectionDataType
        copied.intersectionStride = intersectionStride
        copied.rayDataType = rayDataType
        copied.rayIndexDataType = rayIndexDataType
        copied.rayMask = rayMask
        copied.rayMaskOperator = rayMaskOperator
        copied.rayMaskOptions = rayMaskOptions
        copied.rayStride = rayStride
        copied.boundingBoxIntersectionTestType = boundingBoxIntersectionTestType
        copied.triangleIntersectionTestType = triangleIntersectionTestType
        return copied as! Self
    }

    open func recommendedMinimumRayBatchSize(rayCount: Int) -> Int {
        max(rayCount, 1)
    }

    open func encodeIntersection(
        commandBuffer: any MTLCommandBuffer,
        intersectionType: MPSIntersectionType,
        rayBuffer: any MTLBuffer,
        rayBufferOffset: Int,
        intersectionBuffer: any MTLBuffer,
        intersectionBufferOffset: Int,
        rayCount: Int,
        accelerationStructure: MPSAccelerationStructure
    ) {
        _ = (
            commandBuffer, intersectionType, rayBuffer, rayBufferOffset, intersectionBuffer,
            intersectionBufferOffset, rayCount, accelerationStructure
        )
        MPSHostBoundary.refuseGPUEncode("MPSRayIntersector.encodeIntersection")
    }

    open func encodeIntersection(
        commandBuffer: any MTLCommandBuffer,
        intersectionType: MPSIntersectionType,
        rayBuffer: any MTLBuffer,
        rayBufferOffset: Int,
        intersectionBuffer: any MTLBuffer,
        intersectionBufferOffset: Int,
        rayCountBuffer: any MTLBuffer,
        rayCountBufferOffset: Int,
        accelerationStructure: MPSAccelerationStructure
    ) {
        _ = (rayCountBuffer, rayCountBufferOffset)
        encodeIntersection(
            commandBuffer: commandBuffer,
            intersectionType: intersectionType,
            rayBuffer: rayBuffer,
            rayBufferOffset: rayBufferOffset,
            intersectionBuffer: intersectionBuffer,
            intersectionBufferOffset: intersectionBufferOffset,
            rayCount: 0,
            accelerationStructure: accelerationStructure
        )
    }

    open func encodeIntersection(
        commandBuffer: any MTLCommandBuffer,
        intersectionType: MPSIntersectionType,
        rayBuffer: any MTLBuffer,
        rayBufferOffset: Int,
        rayIndexBuffer: any MTLBuffer,
        rayIndexBufferOffset: Int,
        intersectionBuffer: any MTLBuffer,
        intersectionBufferOffset: Int,
        rayIndexCount: Int,
        accelerationStructure: MPSAccelerationStructure
    ) {
        _ = (rayIndexBuffer, rayIndexBufferOffset, rayIndexCount)
        encodeIntersection(
            commandBuffer: commandBuffer,
            intersectionType: intersectionType,
            rayBuffer: rayBuffer,
            rayBufferOffset: rayBufferOffset,
            intersectionBuffer: intersectionBuffer,
            intersectionBufferOffset: intersectionBufferOffset,
            rayCount: rayIndexCount,
            accelerationStructure: accelerationStructure
        )
    }

    open func encodeIntersection(
        commandBuffer: any MTLCommandBuffer,
        intersectionType: MPSIntersectionType,
        rayBuffer: any MTLBuffer,
        rayBufferOffset: Int,
        rayIndexBuffer: any MTLBuffer,
        rayIndexBufferOffset: Int,
        intersectionBuffer: any MTLBuffer,
        intersectionBufferOffset: Int,
        rayIndexCountBuffer: any MTLBuffer,
        rayIndexCountBufferOffset: Int,
        accelerationStructure: MPSAccelerationStructure
    ) {
        _ = (rayIndexCountBuffer, rayIndexCountBufferOffset)
        encodeIntersection(
            commandBuffer: commandBuffer,
            intersectionType: intersectionType,
            rayBuffer: rayBuffer,
            rayBufferOffset: rayBufferOffset,
            rayIndexBuffer: rayIndexBuffer,
            rayIndexBufferOffset: rayIndexBufferOffset,
            intersectionBuffer: intersectionBuffer,
            intersectionBufferOffset: intersectionBufferOffset,
            rayIndexCount: 0,
            accelerationStructure: accelerationStructure
        )
    }

    open func encodeIntersection(
        commandBuffer: any MTLCommandBuffer,
        intersectionType: MPSIntersectionType,
        rayTexture: any MTLTexture,
        intersectionTexture: any MTLTexture,
        accelerationStructure: MPSAccelerationStructure
    ) {
        _ = (commandBuffer, intersectionType, rayTexture, intersectionTexture, accelerationStructure)
        MPSHostBoundary.refuseGPUEncode("MPSRayIntersector.encodeIntersection(texture:)")
    }
}
