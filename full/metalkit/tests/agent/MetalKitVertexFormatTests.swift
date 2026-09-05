import Foundation
import MetalKit

func testVertexFormatRoundTripTable() {
    let pairs: [(MDLVertexFormat, MTLVertexFormat)] = [
        (.float2, .float2),
        (.float3, .float3),
        (.float4, .float4),
        (.uChar4Normalized, .uchar4Normalized),
        (.int1010102Normalized, .int1010102Normalized),
        (.half2, .half2),
        (.uInt, .uint),
        (.char4, .char4),
    ]
    for (model, metal) in pairs {
        precondition(MTKMetalVertexFormatFromModelIO(model) == metal)
        precondition(MTKModelIOVertexFormatFromMetal(metal) == model)
    }
    precondition(MTKMetalVertexFormatFromModelIO(.invalid) == .invalid)
    precondition(MTKModelIOVertexFormatFromMetal(.invalid) == .invalid)
}

func testUnmappedMetalFormatIsInvalid() {
    precondition(MTKModelIOVertexFormatFromMetal(.uchar4Normalized_bgra) == .invalid)
    precondition(MTKMetalVertexFormatFromModelIO(MDLVertexFormat(rawValue: 0xFFFF)) == .invalid)
}

func testMetalVertexDescriptorFromModelIO() {
    let attribute = MDLVertexAttribute(name: "position", format: .float3, offset: 0, bufferIndex: 0)
    let layout = MDLVertexBufferLayout(stride: 12)
    let model = MDLVertexDescriptor(attributes: [attribute], layouts: [layout])
    let metal = MTKMetalVertexDescriptorFromModelIO(model)
    precondition(metal != nil)
    precondition(metal!.attributes[0].format == .float3)
    precondition(metal!.attributes[0].offset == 0)
    precondition(metal!.attributes[0].bufferIndex == 0)
    precondition(metal!.layouts[0].stride == 12)
}

func testMetalVertexDescriptorFromModelIOWithError() {
    let attribute = MDLVertexAttribute(name: "uv", format: .float2, offset: 12, bufferIndex: 0)
    let model = MDLVertexDescriptor(
        attributes: [attribute],
        layouts: [MDLVertexBufferLayout(stride: 20)]
    )
    let metal = try! MTKMetalVertexDescriptorFromModelIOWithError(model)
    precondition(metal.attributes[0].format == .float2)
    precondition(metal.attributes[0].offset == 12)
}

func testModelIOVertexDescriptorFromMetal() {
    let metal = MTLVertexDescriptor()
    metal.attributes[0].format = .float4
    metal.attributes[0].offset = 0
    metal.attributes[0].bufferIndex = 0
    metal.layouts[0].stride = 16
    let model = MTKModelIOVertexDescriptorFromMetal(metal)
    precondition(model.attributes.count == 1)
    precondition(model.attributes[0].format == .float4)
    precondition(model.layouts[0].stride == 16)
}

func testModelIOVertexDescriptorFromMetalWithError() {
    let metal = MTLVertexDescriptor()
    metal.attributes[1].format = .uchar4Normalized
    metal.attributes[1].offset = 4
    metal.attributes[1].bufferIndex = 1
    metal.layouts[1].stride = 8
    let model = try! MTKModelIOVertexDescriptorFromMetalWithError(metal)
    precondition(model.attributes[0].format == .uChar4Normalized)
    precondition(model.attributes[0].bufferIndex == 1)
}

func testUnsupportedVertexFormatThrows() {
    let attribute = MDLVertexAttribute(
        name: "unknown",
        format: MDLVertexFormat(rawValue: 0xDEAD),
        offset: 0,
        bufferIndex: 0
    )
    let model = MDLVertexDescriptor(attributes: [attribute], layouts: [])
    do {
        _ = try MTKMetalVertexDescriptorFromModelIOWithError(model)
        preconditionFailure("expected throw")
    } catch let error as NSError {
        precondition(error.domain == MTKModelError.domain.rawValue)
    }
    precondition(MTKMetalVertexDescriptorFromModelIO(model) == nil)
}
