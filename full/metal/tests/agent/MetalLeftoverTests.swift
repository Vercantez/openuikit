import Foundation
import Metal

/// Covers the leftover C indirect-argument structs: bounding boxes,
/// timestamp heap entries, dispatch/stage-in argument blocks, intersection
/// function buffer arguments, and half-precision tessellation factors.
func testLeftoverIndirectStructs() {
    var box = MTLAxisAlignedBoundingBox(
        min: MTLPackedFloat3Make(0, 0, 0),
        max: MTLPackedFloat3Make(1, 2, 3)
    )
    box.min = MTLPackedFloat3Make(-1, -1, -1)
    box.max = MTLPackedFloat3Make(1, 1, 1)
    precondition(box.min.x == -1)
    precondition(box.max.z == 1)
    precondition(MTLAxisAlignedBoundingBox().min == MTLPackedFloat3())
    precondition(_MTLAxisAlignedBoundingBox(min: box.min, max: box.max) == box)

    var stamp = MTL4TimestampHeapEntry(timestamp: 42)
    stamp.timestamp = 7
    precondition(stamp.timestamp == 7)
    precondition(MTL4TimestampHeapEntry().timestamp == 0)

    var groups = MTLDispatchThreadgroupsIndirectArguments(threadgroupsPerGrid: (2, 3, 4))
    groups.threadgroupsPerGrid = (1, 1, 1)
    precondition(groups.threadgroupsPerGrid.0 == 1)
    precondition(MTLDispatchThreadgroupsIndirectArguments().threadgroupsPerGrid.2 == 0)

    var threads = MTLDispatchThreadsIndirectArguments(
        threadsPerGrid: (8, 8, 1),
        threadsPerThreadgroup: (4, 4, 1)
    )
    threads.threadsPerGrid = (16, 1, 1)
    threads.threadsPerThreadgroup = (8, 1, 1)
    precondition(threads.threadsPerGrid.0 == 16)
    precondition(threads.threadsPerThreadgroup.0 == 8)
    precondition(MTLDispatchThreadsIndirectArguments().threadsPerGrid.1 == 0)

    var ifArgs = MTLIntersectionFunctionBufferArguments(
        intersectionFunctionBuffer: 1,
        intersectionFunctionBufferSize: 64,
        intersectionFunctionStride: 16
    )
    ifArgs.intersectionFunctionBuffer = 2
    ifArgs.intersectionFunctionBufferSize = 128
    ifArgs.intersectionFunctionStride = 32
    precondition(ifArgs.intersectionFunctionBuffer == 2)
    precondition(ifArgs.intersectionFunctionBufferSize == 128)
    precondition(ifArgs.intersectionFunctionStride == 32)
    precondition(MTLIntersectionFunctionBufferArguments().intersectionFunctionBuffer == 0)

    var quad = MTLQuadTessellationFactorsHalf(
        edgeTessellationFactor: (1, 2, 3, 4),
        insideTessellationFactor: (5, 6)
    )
    quad.edgeTessellationFactor = (2, 2, 2, 2)
    quad.insideTessellationFactor = (3, 3)
    precondition(quad.edgeTessellationFactor.3 == 2)
    precondition(quad.insideTessellationFactor.1 == 3)
    precondition(MTLQuadTessellationFactorsHalf().edgeTessellationFactor.0 == 0)

    var stageIn = MTLStageInRegionIndirectArguments(
        stageInOrigin: (0, 0, 0),
        stageInSize: (8, 8, 1)
    )
    stageIn.stageInOrigin = (1, 2, 0)
    stageIn.stageInSize = (4, 4, 1)
    precondition(stageIn.stageInOrigin.1 == 2)
    precondition(stageIn.stageInSize.0 == 4)
    precondition(MTLStageInRegionIndirectArguments().stageInSize.2 == 0)

    var tri = MTLTriangleTessellationFactorsHalf(
        edgeTessellationFactor: (1, 2, 3),
        insideTessellationFactor: 4
    )
    tri.edgeTessellationFactor = (4, 4, 4)
    tri.insideTessellationFactor = 8
    precondition(tri.edgeTessellationFactor.2 == 4)
    precondition(tri.insideTessellationFactor == 8)
    precondition(MTLTriangleTessellationFactorsHalf().insideTessellationFactor == 0)
}

/// Covers the async pipeline completion-handler aliases and the fail-closed
/// IO compression context surface. Linux has no compression backend, so
/// creation returns nil, appends are inert, and flush reports `.error`.
func testLeftoverCompletionHandlersAndCompression() {
    let binaryHandler: MTL4NewBinaryFunctionCompletionHandler = { function, error in
        _ = (function, error)
    }
    binaryHandler(nil, nil)
    let mlHandler: MTL4NewMachineLearningPipelineStateCompletionHandler = { state, error in
        _ = (state, error)
    }
    mlHandler(nil, nil)
    let computeHandler: MTLNewComputePipelineStateWithReflectionCompletionHandler = { state, reflection, error in
        _ = (state, reflection, error)
    }
    computeHandler(nil, nil, nil)
    let libraryHandler: MTLNewDynamicLibraryCompletionHandler = { library, error in
        _ = (library, error)
    }
    libraryHandler(nil, nil)
    let renderHandler: MTLNewRenderPipelineStateWithReflectionCompletionHandler = { state, reflection, error in
        _ = (state, reflection, error)
    }
    renderHandler(nil, nil, nil)

    precondition(MTLIOCompressionContextDefaultChunkSize() == 65536)
    let missing = MTLIOCreateCompressionContext("/tmp/none.bin", .lzfse, MTLIOCompressionContextDefaultChunkSize())
    precondition(missing == nil)
    var scratch: UInt8 = 0
    withUnsafePointer(to: &scratch) { pointer in
        let raw = UnsafeRawPointer(pointer)
        let token = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)
        defer { token.deallocate() }
        let context: MTLIOCompressionContext = token
        MTLIOCompressionContextAppendData(context, raw, 1)
        precondition(MTLIOFlushAndDestroyCompressionContext(context) == .error)
    }
}

/// Covers the leftover vertex stage descriptors, render-pass sample-buffer
/// attachments, and the MTLType reflection root.
func testLeftoverVertexAndSampleDescriptors() {
    let attribute = MTLAttributeDescriptor()
    attribute.format = .float3
    attribute.offset = 12
    attribute.bufferIndex = 1
    precondition(attribute.format == .float3)
    precondition(attribute.offset == 12)
    precondition(attribute.bufferIndex == 1)
    let attributes = MTLAttributeDescriptorArray()
    attributes[0].format = .float2
    attributes[0].offset = 0
    attributes[0].bufferIndex = 0
    precondition(attributes[0].format == .float2)

    let layout = MTLBufferLayoutDescriptor()
    layout.stride = 24
    layout.stepFunction = .perVertex
    layout.stepRate = 1
    precondition(layout.stride == 24)
    precondition(layout.stepFunction == .perVertex)
    precondition(layout.stepRate == 1)
    let layouts = MTLBufferLayoutDescriptorArray()
    layouts[1].stride = 16
    layouts[1].stepFunction = .perInstance
    layouts[1].stepRate = 2
    precondition(layouts[1].stepRate == 2)

    let stage = MTLStageInputOutputDescriptor()
    stage.attributes[0].format = .float4
    stage.layouts[0].stride = 16
    stage.indexType = .uint32
    stage.indexBufferIndex = 3
    precondition(stage.attributes[0].format == .float4)
    precondition(stage.layouts[0].stride == 16)
    precondition(stage.indexType == .uint32)
    precondition(stage.indexBufferIndex == 3)
    stage.reset()
    precondition(stage.indexBufferIndex == 0)

    let pass = MTLRenderPassDescriptor()
    pass.sampleBufferAttachments[0].startOfVertexSampleIndex = 0
    pass.sampleBufferAttachments[0].endOfVertexSampleIndex = 2
    pass.sampleBufferAttachments[0].startOfFragmentSampleIndex = 2
    pass.sampleBufferAttachments[0].endOfFragmentSampleIndex = 4
    pass.sampleBufferAttachments[0].sampleBuffer = nil
    precondition(pass.sampleBufferAttachments[0].endOfFragmentSampleIndex == 4)
    let sampleArray = MTLRenderPassSampleBufferAttachmentDescriptorArray()
    sampleArray[1].startOfVertexSampleIndex = 1
    precondition(sampleArray[1].startOfVertexSampleIndex == 1)
    let sampleDesc = MTLRenderPassSampleBufferAttachmentDescriptor()
    sampleDesc.startOfVertexSampleIndex = 0
    sampleDesc.endOfVertexSampleIndex = 1
    sampleDesc.startOfFragmentSampleIndex = 1
    sampleDesc.endOfFragmentSampleIndex = 2
    precondition(sampleDesc.endOfVertexSampleIndex == 1)

    let type = MTLType()
    precondition(type.dataType == .none)
}

/// Covers function stitching nodes/graphs/attributes plus the Metal 4
/// machine-learning descriptor and reflection value objects.
func testLeftoverFunctionStitching() {
    let input = MTLFunctionStitchingInputNode(argumentIndex: 0)
    input.argumentIndex = 2
    precondition(input.argumentIndex == 2)
    let nodeInput: any MTLFunctionStitchingNode = input
    precondition((nodeInput as? MTLFunctionStitchingInputNode)?.argumentIndex == 2)

    let function = MTLFunctionStitchingFunctionNode(
        name: "stitched",
        arguments: [input],
        controlDependencies: []
    )
    function.name = "renamed"
    function.arguments = [input]
    function.controlDependencies = []
    precondition(function.name == "renamed")
    precondition(function.arguments.count == 1)
    precondition(function.controlDependencies.isEmpty)
    _ = function.copy()

    let inline = MTLFunctionStitchingAttributeAlwaysInline()
    let attribute: any MTLFunctionStitchingAttribute = inline
    _ = attribute
    let graph = MTLFunctionStitchingGraph(
        functionName: "graph",
        nodes: [function],
        outputNode: function,
        attributes: [inline]
    )
    graph.functionName = "graph2"
    graph.nodes = [function]
    graph.outputNode = function
    graph.attributes = [inline]
    precondition(graph.functionName == "graph2")
    precondition(graph.nodes.count == 1)
    precondition(graph.outputNode?.name == "renamed")
    precondition(graph.attributes.count == 1)

    let mlDesc = MTL4MachineLearningPipelineDescriptor()
    mlDesc.label = "ml"
    mlDesc.machineLearningFunctionDescriptor = MTL4FunctionDescriptor()
    mlDesc.setInputDimensions(MTLTensorExtents(rank: 2, extents: [4, 4]), bufferIndex: 0)
    precondition(mlDesc.label == "ml")
    precondition(mlDesc.machineLearningFunctionDescriptor != nil)
    precondition(mlDesc.inputDimensions(bufferIndex: 0)?.extents == [4, 4])
    precondition(mlDesc.inputDimensions(bufferIndex: 1) == nil)
    mlDesc.setInputDimensions(nil, bufferIndex: 0)
    precondition(mlDesc.inputDimensions(bufferIndex: 0) == nil)
    mlDesc.reset()
    precondition(mlDesc.label == nil)

    let reflection = MTL4MachineLearningPipelineReflection(bindings: [])
    reflection.bindings = []
    precondition(reflection.bindings.isEmpty)

    let stitched = MTL4StitchedFunctionDescriptor()
    stitched.functionDescriptors = [MTL4FunctionDescriptor()]
    stitched.functionGraph = graph
    precondition(stitched.functionDescriptors?.count == 1)
    precondition(stitched.functionGraph?.functionName == "graph2")
}

/// Covers reflection binding value objects, counters, function-log debug
/// locations, and IO scratch buffers.
func testLeftoverBindingReflection() {
    let counter = LinuxMTLCounter(name: "tessellator")
    let counterProto: any MTLCounter = counter
    precondition(counterProto.name == "tessellator")
    let set = LinuxMTLCounterSet(name: "render", counters: [counter])
    precondition(set.name == "render")
    precondition(set.counters.count == 1)
    precondition(set.counters.first?.name == "tessellator")
    let setProto: any MTLCounterSet = set
    precondition(setProto.counters.count == 1)
    precondition(setProto.name == "render")

    let location = LinuxMTLFunctionLogDebugLocation(
        functionName: "vertex_main",
        url: URL(string: "file:///shader.metal"),
        line: 10,
        column: 4
    )
    precondition(location.functionName == "vertex_main")
    precondition(location.url?.lastPathComponent == "shader.metal")
    precondition(location.line == 10)
    precondition(location.column == 4)
    let log: any MTLFunctionLog = LinuxMTLFunctionLog(
        type: .validation,
        encoderLabel: "enc",
        function: nil,
        debugLocation: location
    )
    precondition(log.debugLocation?.line == 10)
    precondition(log.encoderLabel == "enc")

    let device = MTLCreateSystemDefaultDevice()!
    let allocator = LinuxMTLIOScratchBufferAllocator(device: device)
    let scratch = allocator.makeScratchBuffer(minimumSize: 64)!
    precondition(scratch.buffer.length == 64)
    precondition(allocator.makeScratchBuffer(minimumSize: -1) == nil)

    let payload = LinuxMTLObjectPayloadBinding(
        name: "payload",
        index: 0,
        access: .readWrite,
        alignment: 16,
        dataSize: 64
    )
    let payloadProto: any MTLObjectPayloadBinding = payload
    precondition(payloadProto.objectPayloadAlignment == 16)
    precondition(payloadProto.objectPayloadDataSize == 64)
    precondition(payload.name == "payload")

    let textureBinding = LinuxMTLTextureBinding(
        name: "color",
        index: 1,
        access: .readOnly,
        isDepthTexture: false,
        textureDataType: .float,
        textureType: .type2D,
        arrayLength: 1
    )
    let textureProto: any MTLTextureBinding = textureBinding
    precondition(textureProto.arrayLength == 1)
    precondition(textureProto.isDepthTexture == false)
    precondition(textureProto.textureDataType == .float)
    precondition(textureProto.textureType == .type2D)

    let threadgroup = LinuxMTLThreadgroupBinding(
        name: "shared",
        index: 2,
        access: .readWrite,
        alignment: 16,
        dataSize: 256
    )
    let threadgroupProto: any MTLThreadgroupBinding = threadgroup
    precondition(threadgroupProto.threadgroupMemoryAlignment == 16)
    precondition(threadgroupProto.threadgroupMemoryDataSize == 256)

    let tensorBinding = LinuxMTLTensorBinding(
        name: "weights",
        index: 3,
        access: .readOnly,
        dimensions: MTLTensorExtents(rank: 2, extents: [8, 8]),
        indexType: .uint,
        tensorDataType: .float32
    )
    let tensorProto: any MTLTensorBinding = tensorBinding
    precondition(tensorProto.dimensions?.extents == [8, 8])
    precondition(tensorProto.indexType == .uint)
    precondition(tensorProto.tensorDataType == .float32)
}

/// Covers visible/intersection function-table factories and the array/range
/// table-binding overloads on argument, compute, and render encoders.
func testLeftoverFunctionTables() {
    let device = MTLCreateSystemDefaultDevice()!
    let renderPipeline = try! device.makeRenderPipelineState(descriptor: {
        let d = MTLRenderPipelineDescriptor()
        d.colorAttachments[0].pixelFormat = .rgba8Unorm
        return d
    }())
    let visibleDesc = MTLVisibleFunctionTableDescriptor()
    visibleDesc.functionCount = 4
    let visible = renderPipeline.makeVisibleFunctionTable(descriptor: visibleDesc, stage: .vertex)!
    visible.setFunction(nil, index: 0)
    visible.setFunctions([nil, nil], range: 0..<2)
    _ = visible.gpuResourceID
    let intersectionDesc = MTLIntersectionFunctionTableDescriptor()
    intersectionDesc.functionCount = 4
    let intersection = renderPipeline.makeIntersectionFunctionTable(descriptor: intersectionDesc, stage: .fragment)!
    intersection.setFunction(nil, index: 1)
    intersection.setFunctions([nil], range: 1..<2)
    let scratchBuffer = device.makeBuffer(length: 16, options: [])!
    intersection.setBuffer(scratchBuffer, offset: 0, index: 0)
    intersection.setBuffers([scratchBuffer, nil], offsets: [0, 8], range: 0..<2)
    intersection.setVisibleFunctionTable(visible, bufferIndex: 0)
    intersection.setVisibleFunctionTables([visible, nil], bufferRange: 0..<2)
    intersection.setOpaqueCurveIntersectionFunction(signature: [], index: 0)
    intersection.setOpaqueCurveIntersectionFunction(signature: [], range: NSRange(location: 0, length: 1))
    intersection.setOpaqueTriangleIntersectionFunction(signature: [], index: 0)
    intersection.setOpaqueTriangleIntersectionFunction(signature: [], range: NSRange(location: 0, length: 1))
    _ = intersection.gpuResourceID

    let library = MTLMakeCPUBuiltinLibrary(device)
    let fill = library.makeFunction(name: MTLCPUBuiltinKernel.fillUInt32.rawValue)!
    let computePipeline = try! device.makeComputePipelineState(function: fill)
    let computeVisible = computePipeline.makeVisibleFunctionTable(descriptor: visibleDesc)!
    computeVisible.setFunction(nil, index: 3)
    computeVisible.setFunctions([nil, nil, nil], range: 0..<3)
    let computeIntersection = computePipeline.makeIntersectionFunctionTable(descriptor: intersectionDesc)!
    computeIntersection.setFunction(nil, index: 0)
    computeIntersection.setBuffer(nil, offset: 0, index: 1)

    let argument = MTLArgumentDescriptor.argumentDescriptor()
    argument.index = 0
    let encoder = device.makeArgumentEncoder(arguments: [argument])!
    encoder.setVisibleFunctionTables([visible, nil], range: 0..<1)
    encoder.setIntersectionFunctionTables([intersection, nil], range: 0..<1)

    let queue = device.makeCommandQueue()!
    let commandBuffer = queue.makeCommandBuffer()!
    let compute = commandBuffer.makeComputeCommandEncoder()!
    compute.setVisibleFunctionTables([visible], bufferRange: 0..<1)
    compute.setIntersectionFunctionTables([intersection], bufferRange: 0..<1)
    compute.endEncoding()

    let renderPass = MTLRenderPassDescriptor()
    let render = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass)!
    render.setTileVisibleFunctionTables([visible], bufferRange: 0..<1)
    render.setVertexVisibleFunctionTables([visible], bufferRange: 0..<1)
    render.setFragmentVisibleFunctionTables([visible], bufferRange: 0..<1)
    render.setTileIntersectionFunctionTables([intersection], bufferRange: 0..<1)
    render.setVertexIntersectionFunctionTables([intersection], bufferRange: 0..<1)
    render.setFragmentIntersectionFunctionTables([intersection], bufferRange: 0..<1)
    var heapResource: any MTLResource = scratchBuffer
    withUnsafePointer(to: &heapResource) { pointer in
        render.use(pointer, count: 1, usage: .read, stages: .vertex)
    }
    let heap = device.makeHeap(descriptor: {
        let d = MTLHeapDescriptor()
        d.size = 4096
        return d
    }())!
    var heapValue: any MTLHeap = heap
    withUnsafePointer(to: &heapValue) { pointer in
        render.use(pointer, count: 1, stages: .fragment)
    }
    let icbDesc = MTLIndirectCommandBufferDescriptor()
    let icb = device.makeIndirectCommandBuffer(descriptor: icbDesc, maxCommandCount: 2, options: [])!
    let rangeBuffer = device.makeBuffer(length: 8, options: [])!
    rangeBuffer.contents().storeBytes(of: UInt32(0), as: UInt32.self)
    rangeBuffer.contents().advanced(by: 4).storeBytes(of: UInt32(0), as: UInt32.self)
    render.executeCommandsInBuffer(icb, range: 0..<0)
    render.executeCommandsInBuffer(icb, indirectBuffer: rangeBuffer, offset: 0)
    render.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    precondition(MTLCommandBufferError(.notPermitted) != MTLCommandBufferError(.internal))
    precondition(MTLLibraryError(.compileFailure) != MTLLibraryError(.fileNotFound))
}

/// Covers the array/range overloads on argument, compute, blit, and
/// indirect encoders, plus counter-sample-buffer resolution.
func testLeftoverEncoderOverloads() {
    let device = MTLCreateSystemDefaultDevice()!
    let first = MTLArgumentDescriptor.argumentDescriptor()
    first.index = 0
    let second = MTLArgumentDescriptor.argumentDescriptor()
    second.index = 1
    let encoder = device.makeArgumentEncoder(arguments: [first, second])!
    let slots = device.makeBuffer(length: 32, options: [])!
    encoder.setArgumentBuffer(slots, offset: 0)
    encoder.setBuffers([slots, nil], offsets: [0, 0], range: 0..<2)
    encoder.setTextures([nil, nil], range: 0..<2)
    encoder.setSamplerStates([nil, nil], range: 0..<2)
    encoder.setDepthStencilStates([nil, nil], range: 0..<2)
    encoder.setRenderPipelineStates([nil, nil], range: 0..<2)
    let library = MTLMakeCPUBuiltinLibrary(device)
    let fill = library.makeFunction(name: MTLCPUBuiltinKernel.fillUInt32.rawValue)!
    let pipeline = try! device.makeComputePipelineState(function: fill)
    encoder.setComputePipelineStates([pipeline, nil], range: 0..<2)
    let pipelines: [(any MTLComputePipelineState)?] = [pipeline, nil]
    pipelines.withUnsafeBufferPointer { pointer in
        encoder.setComputePipelineStates(pointer.baseAddress!, with: NSRange(location: 0, length: 2))
    }
    encoder.setIndirectCommandBuffers([nil, nil], range: 0..<2)

    let queue = device.makeCommandQueue()!
    let commandBuffer = queue.makeCommandBuffer()!
    let compute = commandBuffer.makeComputeCommandEncoder()!
    compute.setBuffers([slots, nil], offsets: [0, 8], range: 0..<2)
    compute.setBuffers([slots], offsets: [0], attributeStrides: [16], range: 0..<1)
    compute.setTextures([nil], range: 0..<1)
    compute.setSamplerStates([nil], range: 0..<1)
    compute.setSamplerStates([nil], lodMinClamps: [0], lodMaxClamps: [10], range: 0..<1)
    compute.useResources([slots], usage: .read)
    compute.useHeaps([])
    compute.endEncoding()

    let blitBuffer = commandBuffer.makeBlitCommandEncoder()!
    let counterDesc = MTLCounterSampleBufferDescriptor()
    counterDesc.sampleCount = 2
    let counterBuffer = try! device.makeCounterSampleBuffer(descriptor: counterDesc)
    precondition((try? counterBuffer.resolveCounterRange(0..<1)) == nil)
    let destination = device.makeBuffer(length: 16, options: [])!
    blitBuffer.resolveCounters(counterBuffer, range: 0..<1, destinationBuffer: destination, destinationOffset: 0)
    precondition(destination.contents().load(as: UInt64.self) == 0)
    blitBuffer.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    let icbDesc = MTLIndirectCommandBufferDescriptor()
    let icb = device.makeIndirectCommandBuffer(descriptor: icbDesc, maxCommandCount: 2, options: [])!
    let indirect = icb.indirectComputeCommand(at: 0)
    indirect.setStageIn(MTLRegionMake2D(0, 0, 4, 4))
    indirect.reset()
}

/// Covers the Metal 4 archive default-linking overloads, the fail-closed
/// machine-learning compiler entry point, the ML command encoder, the
/// buffer/texture Metal 4 compute copies, and the oracle-pinned
/// `unspecialized` enumeration values.
func testLeftoverMetal4Surface() {
    let device = MTLCreateSystemDefaultDevice()!
    precondition(MTLBlendFactor.unspecialized.rawValue == 19)
    precondition(MTLBlendOperation.unspecialized.rawValue == 5)
    precondition(MTLPixelFormat.unspecialized.rawValue == 263)

    let archive: any MTL4Archive = LinuxMTL4Archive()
    archive.label = "leftover2"
    precondition(archive.label == "leftover2")
    let binaryDesc = MTL4BinaryFunctionDescriptor()
    do {
        _ = try archive.makeBinaryFunction(descriptor: binaryDesc)
        preconditionFailure("binary archive lookup must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        preconditionFailure("expected MTLLibraryError")
    }
    do {
        _ = try archive.makeRenderPipelineState(descriptor: MTL4PipelineDescriptor(), dynamicLinkingDescriptor: nil)
        preconditionFailure("archive render pipeline must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        preconditionFailure("expected MTLLibraryError")
    }
    do {
        _ = try archive.makeComputePipelineState(
            descriptor: MTL4ComputePipelineDescriptor(),
            dynamicLinkingDescriptor: nil
        )
        preconditionFailure("archive compute pipeline must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        preconditionFailure("expected MTLLibraryError")
    }

    let compilerDesc = MTL4CompilerDescriptor()
    let compiler = try! device.makeCompiler(descriptor: compilerDesc)
    do {
        _ = try compiler.makeMachineLearningPipelineState(descriptor: MTL4MachineLearningPipelineDescriptor())
        preconditionFailure("ML pipeline creation must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        preconditionFailure("expected MTLLibraryError")
    }

    let allocator = device.makeCommandAllocator()!
    let queue = try! device.makeMTL4CommandQueue(descriptor: MTL4CommandQueueDescriptor())
    let commandBuffer = device.makeCommandBuffer()!
    commandBuffer.beginCommandBuffer(allocator: allocator)
    let mlEncoder = commandBuffer.makeMachineLearningCommandEncoder()!
    let mlState = LinuxMTL4MachineLearningPipelineState(
        device: device,
        label: "ml",
        intermediatesHeapSize: 0,
        reflection: MTL4MachineLearningPipelineReflection()
    )
    precondition(mlState.device.name == device.name)
    precondition(mlState.intermediatesHeapSize == 0)
    precondition(mlState.label == "ml")
    precondition(mlState.reflection?.bindings.isEmpty == true)
    precondition(mlState.allocatedSize == 0)
    let tableDesc = MTL4ArgumentTableDescriptor()
    tableDesc.maxBufferBindCount = 1
    let table = try! device.makeArgumentTable(descriptor: tableDesc)
    mlEncoder.setPipelineState(mlState)
    mlEncoder.setArgumentTable(table)
    let heapDesc = MTLHeapDescriptor()
    heapDesc.size = 4096
    let heap = device.makeHeap(descriptor: heapDesc)!
    mlEncoder.dispatchNetwork(intermediatesHeap: heap)
    mlEncoder.endEncoding()

    let compute = commandBuffer.makeComputeCommandEncoder()!
    let source = device.makeBuffer(length: 8, options: [])!
    source.contents().storeBytes(of: UInt64(0x1122334455667788), as: UInt64.self)
    let dest = device.makeBuffer(length: 8, options: [])!
    let icbDesc = MTLIndirectCommandBufferDescriptor()
    let icb = device.makeIndirectCommandBuffer(descriptor: icbDesc, maxCommandCount: 2, options: [])!
    compute.resetCommands(buffer: icb, range: 0..<2)
    compute.copyCommands(sourceBuffer: icb, sourceRange: 0..<1, destinationBuffer: icb, destinationIndex: 1)
    compute.optimizeCommands(buffer: icb, range: 0..<2)
    compute.executeCommands(buffer: icb, range: 0..<0)
    let texDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Unorm, width: 2, height: 2, mipmapped: false)
    texDesc.usage = [.shaderRead, .shaderWrite]
    let texture = device.makeTexture(descriptor: texDesc)!
    compute.copy(
        sourceBuffer: source,
        sourceOffset: 0,
        sourceBytesPerRow: 2,
        sourceBytesPerImage: 4,
        sourceSize: MTLSizeMake(2, 2, 1),
        destinationTexture: texture,
        destinationSlice: 0,
        destinationLevel: 0,
        destinationOrigin: MTLOrigin(),
        options: []
    )
    compute.copy(
        sourceTexture: texture,
        sourceSlice: 0,
        sourceLevel: 0,
        sourceOrigin: MTLOrigin(),
        sourceSize: MTLSizeMake(2, 2, 1),
        destinationBuffer: dest,
        destinationOffset: 0,
        destinationBytesPerRow: 2,
        destinationBytesPerImage: 4,
        options: []
    )
    compute.fill(buffer: dest, range: 0..<8, value: 0xAB)
    compute.endEncoding()

    let renderPass = MTL4RenderPassDescriptor()
    renderPass.tileWidth = 4
    renderPass.tileHeight = 4
    let render = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass, options: [])!
    render.executeCommands(buffer: icb, range: 0..<0)
    render.setDepthTestBounds(0...1)
    render.setVertexAmplificationCount(1)
    render.setVertexAmplificationCount([MTLVertexAmplificationViewMapping()])
    render.endEncoding()
    commandBuffer.endCommandBuffer()
    queue.commit([commandBuffer], options: nil)
    precondition(dest.contents().load(as: UInt8.self) == 0xAB)
    var copied = [UInt8](repeating: 0, count: 4)
    copied.withUnsafeMutableBytes { raw in
        texture.getBytes(raw.baseAddress!, bytesPerRow: 2, from: MTLRegionMake2D(0, 0, 2, 2), mipmapLevel: 0)
    }
    precondition(copied == [0x88, 0x77, 0x66, 0x55])
    precondition(MTLCommandBufferError(.notPermitted) == MTLCommandBufferError(.notPermitted))
    _ = MTLCommandBufferError(.notPermitted).localizedDescription
}
