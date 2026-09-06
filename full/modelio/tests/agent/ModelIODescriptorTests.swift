import Foundation
import ModelIO

func testVertexBufferLayout() {
    let layout = MDLVertexBufferLayout(stride: 24)
    mdlCheck(layout.stride == 24, "stride")
    let clone = layout.copy() as! MDLVertexBufferLayout
    mdlCheck(clone.stride == 24, "copy")
}

func testVertexAttribute() {
    let attribute = MDLVertexAttribute(
        name: MDLVertexAttributePosition,
        format: .float3,
        offset: 0,
        bufferIndex: 1
    )
    mdlCheck(attribute.name == MDLVertexAttributePosition, "name")
    mdlCheck(attribute.format == .float3, "format")
    mdlCheck(attribute.offset == 0, "offset")
    mdlCheck(attribute.bufferIndex == 1, "index")
    attribute.time = 1.5
    attribute.initializationValue = SIMD4<Float>(1, 2, 3, 4)
    mdlCheck(attribute.time == 1.5, "time")
    mdlCheck(attribute.initializationValue.y == 2, "init value")
}

func testVertexDescriptor() {
    let descriptor = MDLVertexDescriptor()
    mdlCheck(descriptor.attributes.count == 0, "empty attributes")
    mdlCheck(descriptor.layouts.count == 0, "empty layouts")
}

func testVertexDescriptorCopy() {
    let descriptor = MDLVertexDescriptor()
    descriptor.addOrReplaceAttribute(
        MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: 0, bufferIndex: 0)
    )
    let copy = MDLVertexDescriptor(vertexDescriptor: descriptor)
    mdlCheck(copy.attributeNamed(MDLVertexAttributeNormal) != nil, "copied attribute")
}

func testVertexDescriptorReset() {
    let descriptor = MDLVertexDescriptor()
    descriptor.addOrReplaceAttribute(
        MDLVertexAttribute(name: "tmp", format: .float, offset: 0, bufferIndex: 0)
    )
    descriptor.reset()
    mdlCheck(descriptor.attributeNamed("tmp") == nil, "reset")
}

func testPackedOffsetsAndStrides() {
    let descriptor = MDLVertexDescriptor()
    descriptor.addOrReplaceAttribute(
        MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 99, bufferIndex: 0)
    )
    descriptor.addOrReplaceAttribute(
        MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: 0, bufferIndex: 0)
    )
    descriptor.setPackedOffsets()
    let position = descriptor.attributeNamed(MDLVertexAttributePosition)!
    let normal = descriptor.attributeNamed(MDLVertexAttributeNormal)!
    mdlCheck(position.offset == 0, "first packed offset")
    mdlCheck(normal.offset == 12, "second packed offset")
    descriptor.setPackedStrides()
    let layout = descriptor.layouts[0] as! MDLVertexBufferLayout
    mdlCheck(layout.stride == 24, "packed stride")
    descriptor.removeAttributeNamed(MDLVertexAttributeNormal)
    mdlCheck(descriptor.attributeNamed(MDLVertexAttributeNormal) == nil, "removed")
}

func testVertexAttributeData() {
    let data = MDLVertexAttributeData()
    mdlCheck(data.stride == 0, "default stride")
    mdlCheck(data.format == .invalid, "default format")
    mdlCheck(data.bufferSize == 0, "default size")
    _ = data.dataStart
    _ = data.map
}
