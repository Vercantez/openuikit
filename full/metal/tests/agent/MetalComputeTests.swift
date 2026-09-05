import Foundation
import Metal

func testCPUBuiltinCompute() {
    let device = MTLCreateSystemDefaultDevice()!
    let library = MTLMakeCPUBuiltinLibrary(device)
    library.label = "cpu-builtin"
    precondition(library.label == "cpu-builtin")
    precondition(library.device.name == device.name)
    precondition(library.functionNames.contains(MTLCPUBuiltinKernel.fillUInt32.rawValue))
    precondition(library.type == .executable)
    _ = library.installName
    let fill = library.makeFunction(name: MTLCPUBuiltinKernel.fillUInt32.rawValue)!
    precondition(fill.name == MTLCPUBuiltinKernel.fillUInt32.rawValue)
    precondition(fill.functionType == .kernel)
    precondition(fill.device.name == device.name)
    _ = fill.options
    _ = fill.patchType
    _ = fill.patchControlPointCount
    _ = fill.vertexAttributes
    _ = fill.stageInputAttributes
    _ = fill.functionConstantsDictionary
    fill.label = "fill"
    precondition(fill.label == "fill")
    _ = fill.makeArgumentEncoder(bufferIndex: 0)
    let descriptor = MTLFunctionDescriptor()
    descriptor.name = MTLCPUBuiltinKernel.fillUInt32.rawValue
    _ = try! library.makeFunction(descriptor: descriptor)
    _ = try! library.makeFunction(name: fill.name, constantValues: MTLFunctionConstantValues())
    precondition(library.reflection(functionName: fill.name) == nil)
    let pipeline = try! device.makeComputePipelineState(function: fill)
    precondition(pipeline.maxTotalThreadsPerThreadgroup == 64)
    precondition(pipeline.threadExecutionWidth == 1)
    precondition(pipeline.staticThreadgroupMemoryLength == 0)
    precondition(!pipeline.supportIndirectCommandBuffers)
    precondition(pipeline.shaderValidation == .disabled)
    _ = pipeline.requiredThreadsPerThreadgroup
    _ = pipeline.allocatedSize
    _ = pipeline.gpuResourceID
    _ = pipeline.imageblockMemoryLength(forDimensions: MTLSizeMake(1, 1, 1))
    let computeDesc = MTLComputePipelineDescriptor()
    computeDesc.computeFunction = fill
    _ = try! device.makeComputePipelineState(descriptor: computeDesc)
    let buffer = device.makeBuffer(length: 16, options: [])!
    var constant: UInt32 = 0xA1B2C3D4
    let queue = device.makeCommandQueue()!
    let commandBuffer = queue.makeCommandBuffer()!
    let encoder = commandBuffer.makeComputeCommandEncoder()!
    encoder.label = "compute"
    precondition(encoder.dispatchType == .serial)
    encoder.setComputePipelineState(pipeline)
    encoder.setBuffer(buffer, offset: 0, index: 0)
    encoder.setBuffer(buffer, offset: 0, attributeStride: 4, index: 0)
    encoder.setBufferOffset(0, index: 0)
    encoder.setBufferOffset(offset: 0, attributeStride: 4, index: 0)
    withUnsafeBytes(of: &constant) { raw in
        encoder.setBytes(raw.baseAddress!, length: 4, index: 1)
        encoder.setBytes(raw.baseAddress!, length: 4, attributeStride: 4, index: 1)
    }
    encoder.setTexture(nil, index: 0)
    encoder.setSamplerState(nil, index: 0)
    encoder.setSamplerState(nil, lodMinClamp: 0, lodMaxClamp: 1, index: 0)
    encoder.setThreadgroupMemoryLength(0, index: 0)
    encoder.setImageblockWidth(1, height: 1)
    encoder.setStageInRegion(MTLRegionMake2D(0, 0, 1, 1))
    encoder.memoryBarrier(scope: .buffers)
    encoder.useResource(buffer, usage: .write)
    encoder.useHeap(device.makeHeap(descriptor: MTLHeapDescriptor())!)
    encoder.barrier(afterQueueStages: .dispatch, beforeStages: .dispatch)
    encoder.dispatchThreadgroups(MTLSizeMake(4, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
    encoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    for index in 0..<4 {
        let value = buffer.contents().advanced(by: index * 4).load(as: UInt32.self)
        precondition(value == 0xA1B2C3D4)
    }

    let addFn = library.makeFunction(name: MTLCPUBuiltinKernel.addUInt32.rawValue)!
    let addPipeline = try! device.makeComputePipelineState(function: addFn)
    let a = device.makeBuffer(length: 8, options: [])!
    let b = device.makeBuffer(length: 8, options: [])!
    let out = device.makeBuffer(length: 8, options: [])!
    a.contents().storeBytes(of: UInt32(2), as: UInt32.self)
    a.contents().advanced(by: 4).storeBytes(of: UInt32(3), as: UInt32.self)
    b.contents().storeBytes(of: UInt32(5), as: UInt32.self)
    b.contents().advanced(by: 4).storeBytes(of: UInt32(7), as: UInt32.self)
    let addBuffer = queue.makeCommandBuffer()!
    let addEncoder = addBuffer.makeComputeCommandEncoder(dispatchType: .serial)!
    addEncoder.setComputePipelineState(addPipeline)
    addEncoder.setBuffer(a, offset: 0, index: 0)
    addEncoder.setBuffer(b, offset: 0, index: 1)
    addEncoder.setBuffer(out, offset: 0, index: 2)
    addEncoder.dispatchThreads(MTLSizeMake(2, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
    addEncoder.endEncoding()
    addBuffer.commit()
    addBuffer.waitUntilCompleted()
    precondition(out.contents().load(as: UInt32.self) == 7)
    precondition(out.contents().advanced(by: 4).load(as: UInt32.self) == 10)

    let copyFn = library.makeFunction(name: MTLCPUBuiltinKernel.copyUInt8.rawValue)!
    let copyPipeline = try! device.makeComputePipelineState(function: copyFn)
    let src = device.makeBuffer(length: 3, options: [])!
    let dst = device.makeBuffer(length: 3, options: [])!
    src.contents().storeBytes(of: UInt8(9), as: UInt8.self)
    src.contents().advanced(by: 1).storeBytes(of: UInt8(8), as: UInt8.self)
    src.contents().advanced(by: 2).storeBytes(of: UInt8(7), as: UInt8.self)
    let copyPass = MTLComputePassDescriptor()
    let copyCB = queue.makeCommandBuffer()!
    let copyEnc = copyCB.makeComputeCommandEncoder(descriptor: copyPass)!
    copyEnc.setComputePipelineState(copyPipeline)
    copyEnc.setBuffer(src, offset: 0, index: 0)
    copyEnc.setBuffer(dst, offset: 0, index: 1)
    copyEnc.dispatchThreadgroups(MTLSizeMake(3, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
    copyEnc.endEncoding()
    copyCB.commit()
    copyCB.waitUntilCompleted()
    precondition(dst.contents().load(as: UInt8.self) == 9)
    precondition(library.makeFunction(name: "kernel void k()") == nil)
}
