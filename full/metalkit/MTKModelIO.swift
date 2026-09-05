import Foundation

private let metalFromModelIO: [(MDLVertexFormat, MTLVertexFormat)] = [
    (.invalid, .invalid),
    (.uChar, .uchar),
    (.uChar2, .uchar2),
    (.uChar3, .uchar3),
    (.uChar4, .uchar4),
    (.char, .char),
    (.char2, .char2),
    (.char3, .char3),
    (.char4, .char4),
    (.uCharNormalized, .ucharNormalized),
    (.uChar2Normalized, .uchar2Normalized),
    (.uChar3Normalized, .uchar3Normalized),
    (.uChar4Normalized, .uchar4Normalized),
    (.charNormalized, .charNormalized),
    (.char2Normalized, .char2Normalized),
    (.char3Normalized, .char3Normalized),
    (.char4Normalized, .char4Normalized),
    (.uShort, .ushort),
    (.uShort2, .ushort2),
    (.uShort3, .ushort3),
    (.uShort4, .ushort4),
    (.short, .short),
    (.short2, .short2),
    (.short3, .short3),
    (.short4, .short4),
    (.uShortNormalized, .ushortNormalized),
    (.uShort2Normalized, .ushort2Normalized),
    (.uShort3Normalized, .ushort3Normalized),
    (.uShort4Normalized, .ushort4Normalized),
    (.shortNormalized, .shortNormalized),
    (.short2Normalized, .short2Normalized),
    (.short3Normalized, .short3Normalized),
    (.short4Normalized, .short4Normalized),
    (.uInt, .uint),
    (.uInt2, .uint2),
    (.uInt3, .uint3),
    (.uInt4, .uint4),
    (.int, .int),
    (.int2, .int2),
    (.int3, .int3),
    (.int4, .int4),
    (.half, .half),
    (.half2, .half2),
    (.half3, .half3),
    (.half4, .half4),
    (.float, .float),
    (.float2, .float2),
    (.float3, .float3),
    (.float4, .float4),
    (.int1010102Normalized, .int1010102Normalized),
    (.uInt1010102Normalized, .uint1010102Normalized),
]

public func MTKMetalVertexFormatFromModelIO(_ vertexFormat: MDLVertexFormat) -> MTLVertexFormat {
    metalFromModelIO.first(where: { $0.0 == vertexFormat })?.1 ?? .invalid
}

public func MTKModelIOVertexFormatFromMetal(_ vertexFormat: MTLVertexFormat) -> MDLVertexFormat {
    metalFromModelIO.first(where: { $0.1 == vertexFormat })?.0 ?? .invalid
}

public func MTKMetalVertexDescriptorFromModelIO(
    _ modelIODescriptor: MDLVertexDescriptor
) -> MTLVertexDescriptor? {
    do {
        return try MTKMetalVertexDescriptorFromModelIOWithError(modelIODescriptor)
    } catch {
        return nil
    }
}

public func MTKMetalVertexDescriptorFromModelIOWithError(
    _ modelIODescriptor: MDLVertexDescriptor
) throws -> MTLVertexDescriptor {
    let descriptor = MTLVertexDescriptor()
    for (index, attribute) in modelIODescriptor.attributes.enumerated() {
        let metalFormat = MTKMetalVertexFormatFromModelIO(attribute.format)
        if attribute.format != .invalid && metalFormat == .invalid {
            throw metalKitModelError(.unsupportedVertexFormat(attribute.format))
        }
        descriptor.attributes[index].format = metalFormat
        descriptor.attributes[index].offset = attribute.offset
        descriptor.attributes[index].bufferIndex = attribute.bufferIndex
    }
    for (index, layout) in modelIODescriptor.layouts.enumerated() {
        descriptor.layouts[index].stride = layout.stride
        descriptor.layouts[index].stepFunction = .perVertex
        descriptor.layouts[index].stepRate = 1
    }
    return descriptor
}

public func MTKModelIOVertexDescriptorFromMetal(
    _ metalDescriptor: MTLVertexDescriptor
) -> MDLVertexDescriptor {
    (try? MTKModelIOVertexDescriptorFromMetalWithError(metalDescriptor)) ?? MDLVertexDescriptor()
}

public func MTKModelIOVertexDescriptorFromMetalWithError(
    _ metalDescriptor: MTLVertexDescriptor
) throws -> MDLVertexDescriptor {
    var attributes: [MDLVertexAttribute] = []
    for index in metalDescriptor.attributes.populatedIndices {
        let attribute = metalDescriptor.attributes[index]
        let modelFormat = MTKModelIOVertexFormatFromMetal(attribute.format)
        if attribute.format != .invalid && modelFormat == .invalid {
            throw metalKitModelError(.unsupportedMetalVertexFormat(attribute.format))
        }
        attributes.append(
            MDLVertexAttribute(
                name: "attr\(index)",
                format: modelFormat,
                offset: attribute.offset,
                bufferIndex: attribute.bufferIndex
            )
        )
    }
    var layouts: [MDLVertexBufferLayout] = []
    for index in metalDescriptor.layouts.populatedIndices {
        layouts.append(MDLVertexBufferLayout(stride: metalDescriptor.layouts[index].stride))
    }
    return MDLVertexDescriptor(attributes: attributes, layouts: layouts)
}

enum MetalKitModelFailure: Error {
    case unsupportedVertexFormat(MDLVertexFormat)
    case unsupportedMetalVertexFormat(MTLVertexFormat)
    case unsupportedIndexType(MDLIndexBitDepth)
    case unsupportedGeometry(MDLGeometryType)
    case missingDeviceBuffer

    var nsError: NSError {
        let message: String
        switch self {
        case .unsupportedVertexFormat:
            message = "ModelIO vertex format has no Metal counterpart"
        case .unsupportedMetalVertexFormat:
            message = "Metal vertex format has no ModelIO counterpart"
        case .unsupportedIndexType:
            message = "ModelIO index bit depth is not a Metal index type"
        case .unsupportedGeometry:
            message = "ModelIO geometry type cannot be drawn as a Metal primitive"
        case .missingDeviceBuffer:
            message = "MTLDevice refused a software mesh buffer"
        }
        return NSError(
            domain: MTKModelError.domain.rawValue,
            code: 0,
            userInfo: [
                NSLocalizedDescriptionKey: message,
                MTKModelError.key.rawValue: message,
            ]
        )
    }
}

func metalKitModelError(_ failure: MetalKitModelFailure) -> NSError {
    failure.nsError
}
