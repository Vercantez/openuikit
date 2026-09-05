import Foundation
import MetalPerformanceShaders

func testMPSMatrixAndVector() {
    let device = MPSHostDevice.shared
    let desc = MPSMatrixDescriptor(rows: 4, columns: 8, rowBytes: 32, dataType: .float32)
    precondition(desc.rows == 4 && desc.columns == 8)
    precondition(desc.rowBytes == 32)
    precondition(desc.dataType == .float32)
    precondition(desc.matrices == 1)
    precondition(MPSMatrixDescriptor.rowBytes(forColumns: 8, dataType: .float32) == 32)
    precondition(MPSMatrixDescriptor.rowBytes(fromColumns: 8, dataType: .float32) == 32)
    let batched = MPSMatrixDescriptor(rows: 2, columns: 2, matrices: 3, rowBytes: 8, matrixBytes: 16, dataType: .float32)
    precondition(batched.matrices == 3 && batched.matrixBytes == 16)
    _ = MPSMatrixDescriptor(dimensions: 2, columns: 2, rowBytes: 8, dataType: .float32)
    _ = MPSMatrixDescriptor()
    let matrix = MPSMatrix(device: device, descriptor: desc)
    precondition(matrix.rows == 4 && matrix.columns == 8)
    precondition(matrix.rowBytes == 32)
    precondition(matrix.offset == 0)
    precondition(matrix.resourceSize() >= 32 * 4)
    _ = matrix.data
    _ = matrix.device
    _ = matrix.dataType
    _ = matrix.matrices
    _ = matrix.matrixBytes
    matrix.synchronize(on: device.makeCommandBuffer())
    let fromBuffer = MPSMatrix(buffer: matrix.data, descriptor: desc)
    precondition(fromBuffer.columns == 8)
    let fromOffset = MPSMatrix(buffer: matrix.data, offset: 0, descriptor: desc)
    precondition(fromOffset.offset == 0)

    let vdesc = MPSVectorDescriptor(length: 16, dataType: .float32)
    precondition(vdesc.length == 16)
    precondition(MPSVectorDescriptor.vectorBytes(forLength: 16, dataType: .float32) == 64)
    let vdesc2 = MPSVectorDescriptor(length: 8, vectors: 2, vectorBytes: 32, dataType: .float32)
    precondition(vdesc2.vectors == 2)
    _ = MPSVectorDescriptor()
    let vector = MPSVector(device: device, descriptor: vdesc)
    precondition(vector.length == 16)
    precondition(vector.resourceSize() >= 64)
    vector.synchronize(on: device.makeCommandBuffer())
    _ = vector.data
    _ = vector.device
    _ = vector.offset
    _ = vector.vectors
    _ = vector.vectorBytes
    _ = vector.dataType
    let vbuf = MPSVector(buffer: vector.data, descriptor: vdesc)
    precondition(vbuf.length == 16)
    let voff = MPSVector(buffer: vector.data, offset: 0, descriptor: vdesc)
    precondition(voff.offset == 0)

    let cmd = device.makeCommandBuffer()
    MPSTemporaryMatrix.prefetchStorage(with: cmd, matrixDescriptorList: [desc])
    let tmpMat = MPSTemporaryMatrix(commandBuffer: cmd, matrixDescriptor: desc)
    precondition(tmpMat.readCount == 1)
    MPSTemporaryVector.prefetchStorage(with: cmd, descriptorList: [vdesc])
    let tmpVec = MPSTemporaryVector(commandBuffer: cmd, descriptor: vdesc)
    precondition(tmpVec.readCount == 1)
}

func testMPSMatrixMultiplicationCPU() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let aDesc = MPSMatrixDescriptor(rows: 2, columns: 3, rowBytes: 12, dataType: .float32)
    let bDesc = MPSMatrixDescriptor(rows: 3, columns: 2, rowBytes: 8, dataType: .float32)
    let cDesc = MPSMatrixDescriptor(rows: 2, columns: 2, rowBytes: 8, dataType: .float32)
    let a = MPSMatrix(device: device, descriptor: aDesc)
    let b = MPSMatrix(device: device, descriptor: bDesc)
    let c = MPSMatrix(device: device, descriptor: cDesc)
    let aPtr = a.data.contents.bindMemory(to: Float.self, capacity: 6)
    let bPtr = b.data.contents.bindMemory(to: Float.self, capacity: 6)
    let valuesA: [Float] = [1, 2, 3, 4, 5, 6]
    let valuesB: [Float] = [7, 8, 9, 10, 11, 12]
    for i in 0..<6 { aPtr[i] = valuesA[i]; bPtr[i] = valuesB[i] }
    let gemm = MPSMatrixMultiplication(
        device: device,
        transposeLeft: false,
        transposeRight: false,
        resultRows: 2,
        resultColumns: 2,
        interiorColumns: 3,
        alpha: 1,
        beta: 0
    )
    gemm.resultMatrixOrigin = MTLOrigin(x: 0, y: 0, z: 0)
    gemm.leftMatrixOrigin = MTLOrigin(x: 0, y: 0, z: 0)
    gemm.rightMatrixOrigin = MTLOrigin(x: 0, y: 0, z: 0)
    gemm.batchStart = 0
    gemm.batchSize = 1
    gemm.encode(commandBuffer: cmd, leftMatrix: a, rightMatrix: b, resultMatrix: c)
    let cPtr = c.data.contents.bindMemory(to: Float.self, capacity: 4)
    // [1,2,3; 4,5,6] * [7,8; 9,10; 11,12] = [58, 64; 139, 154]
    precondition(abs(cPtr[0] - 58) < 0.001)
    precondition(abs(cPtr[1] - 64) < 0.001)
    precondition(abs(cPtr[2] - 139) < 0.001)
    precondition(abs(cPtr[3] - 154) < 0.001)
    _ = MPSMatrixMultiplication(device: device, resultRows: 2, resultColumns: 2, interiorColumns: 3)
    _ = MPSMatrixMultiplication(device: device)
    precondition(MPSMatrixMultiplication(coder: NSCoder(), device: device) == nil)

    let vecDesc = MPSVectorDescriptor(length: 3, dataType: .float32)
    let outDesc = MPSVectorDescriptor(length: 2, dataType: .float32)
    let x = MPSVector(device: device, descriptor: vecDesc)
    let y = MPSVector(device: device, descriptor: outDesc)
    let xPtr = x.data.contents.bindMemory(to: Float.self, capacity: 3)
    xPtr[0] = 1; xPtr[1] = 1; xPtr[2] = 1
    let gemv = MPSMatrixVectorMultiplication(device: device, transpose: false, rows: 2, columns: 3, alpha: 1, beta: 0)
    gemv.encode(commandBuffer: cmd, inputMatrix: a, inputVector: x, resultVector: y)
    let yPtr = y.data.contents.bindMemory(to: Float.self, capacity: 2)
    precondition(abs(yPtr[0] - 6) < 0.001)
    precondition(abs(yPtr[1] - 15) < 0.001)
    _ = MPSMatrixVectorMultiplication(device: device, rows: 2, columns: 3)
    _ = MPSMatrixVectorMultiplication(device: device)
    precondition(MPSMatrixVectorMultiplication(coder: NSCoder(), device: device) == nil)
}

func testMPSMatrixCopy() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let desc = MPSMatrixDescriptor(rows: 2, columns: 2, rowBytes: 8, dataType: .float32)
    let src = MPSMatrix(device: device, descriptor: desc)
    let dst = MPSMatrix(device: device, descriptor: desc)
    let s = src.data.contents.bindMemory(to: Float.self, capacity: 4)
    s[0] = 1; s[1] = 2; s[2] = 3; s[3] = 4
    let offsets = MPSMatrixCopyOffsets()
    let copyDesc = MPSMatrixCopyDescriptor(sourceMatrix: src, destinationMatrix: dst, offsets: offsets)
    copyDesc.setCopyOperationAt(0, sourceMatrix: src, destinationMatrix: dst, offsets: offsets)
    _ = MPSMatrixCopyDescriptor(device: device, count: 1)
    _ = MPSMatrixCopyDescriptor(sourceMatrices: [src], destinationMatrices: [dst], offsetVector: nil, offset: 0)
    let copy = MPSMatrixCopy(
        device: device,
        copyRows: 2,
        copyColumns: 2,
        sourcesAreTransposed: false,
        destinationsAreTransposed: false
    )
    precondition(copy.copyRows == 2 && copy.copyColumns == 2)
    precondition(!copy.sourcesAreTransposed && !copy.destinationsAreTransposed)
    copy.encode(commandBuffer: cmd, copyDescriptor: copyDesc)
    let d = dst.data.contents.bindMemory(to: Float.self, capacity: 4)
    precondition(d[0] == 1 && d[3] == 4)
    copy.encode(
        commandBuffer: cmd,
        copyDescriptor: copyDesc,
        rowPermuteIndices: nil,
        rowPermuteOffset: 0,
        columnPermuteIndices: nil,
        columnPermuteOffset: 0
    )
    _ = MPSMatrixCopy(device: device)
    precondition(MPSMatrixCopy(coder: NSCoder(), device: device) == nil)

    let image = MPSImage(
        device: device,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 2, height: 2, featureChannels: 1)
    )
    let img2mat = MPSImageCopyToMatrix(device: device, dataLayout: .HeightxWidthxFeatureChannels)
    precondition(img2mat.dataLayout == .HeightxWidthxFeatureChannels)
    img2mat.destinationMatrixOrigin = MTLOrigin(x: 0, y: 0, z: 0)
    img2mat.destinationMatrixBatchIndex = 0
    img2mat.encode(commandBuffer: cmd, sourceImage: image, destinationMatrix: dst)
    img2mat.encodeBatch(commandBuffer: cmd, sourceImages: [image], destinationMatrix: dst)
    _ = MPSImageCopyToMatrix(device: device)
    precondition(MPSImageCopyToMatrix(coder: NSCoder(), device: device) == nil)

    let mat2img = MPSMatrixCopyToImage(device: device, dataLayout: .HeightxWidthxFeatureChannels)
    precondition(mat2img.dataLayout == .HeightxWidthxFeatureChannels)
    mat2img.sourceMatrixOrigin = MTLOrigin(x: 0, y: 0, z: 0)
    mat2img.sourceMatrixBatchIndex = 0
    mat2img.encode(commandBuffer: cmd, sourceMatrix: src, destinationImage: image)
    mat2img.encodeBatch(commandBuffer: cmd, sourceMatrix: src, destinationImages: [image])
    _ = MPSMatrixCopyToImage(device: device)
    precondition(MPSMatrixCopyToImage(coder: NSCoder(), device: device) == nil)
}

func testMPSNDArrayDescriptorAndHostIO() {
    let device = MPSHostDevice.shared
    var sizes = [2, 3, 4]
    let descriptor = MPSNDArrayDescriptor(dataType: .float32, dimensionCount: 3, dimensionSizes: &sizes)
    precondition(descriptor.numberOfDimensions == 3)
    precondition(descriptor.length(ofDimension: 0) == 2)
    precondition(descriptor.length(ofDimension: 1) == 3)
    precondition(descriptor.dataType == .float32)
    descriptor.preferPackedRows = true
    precondition(descriptor.preferPackedRows)
    let slice = descriptor.sliceRange(forDimension: 1)
    precondition(slice.length == 3)
    descriptor.sliceDimension(1, withSubrange: MPSDimensionSlice(start: 1, length: 1))
    precondition(descriptor.sliceRange(forDimension: 1).length == 1)
    descriptor.transposeDimension(0, withDimension: 1)
    var order = [1, 0, 2]
    descriptor.permute(withDimensionOrder: &order)
    var reshape = [4, 6]
    descriptor.reshape(withDimensionCount: 2, dimensionSizes: &reshape)
    precondition(descriptor.numberOfDimensions == 2)
    descriptor.reshape(withShape: [2, 2, 2])
    precondition(descriptor.getShape().map { $0.intValue } == [2, 2, 2])
    let dimOrder = descriptor.dimensionOrder()
    precondition(dimOrder[0] == 0)
    let fromShape = MPSNDArrayDescriptor(dataType: .float16, shape: [5, 7])
    precondition(fromShape.length(ofDimension: 1) == 7)

    let array = MPSNDArray(device: device, descriptor: fromShape)
    precondition(array.numberOfDimensions == 2)
    precondition(array.length(ofDimension: 0) == 5)
    precondition(array.dataType == .float16)
    precondition(array.dataTypeSize == 2)
    precondition(array.resourceSize() == 5 * 7 * 2)
    array.label = "nd"
    precondition(array.label == "nd")
    precondition(array.parent == nil)
    _ = array.device
    let copiedDesc = array.descriptor()
    precondition(copiedDesc.length(ofDimension: 1) == 7)
    var payload = [Float16](repeating: 1.5, count: 35)
    payload.withUnsafeMutableBytes { raw in
        array.writeBytes(raw.baseAddress!, strideBytes: nil)
    }
    var roundtrip = [Float16](repeating: 0, count: 35)
    roundtrip.withUnsafeMutableBytes { raw in
        array.readBytes(raw.baseAddress!, strideBytes: nil)
    }
    precondition(roundtrip[0] == 1.5)
    let view = array.arrayView(with: MPSNDArrayDescriptor(dataType: .float16, shape: [5, 7]))
    precondition(view?.parent === array)
    let cmd = device.makeCommandBuffer()
    _ = array.arrayView(with: cmd, descriptor: fromShape, aliasing: .default)
    _ = array.arrayView(withShape: [5, 7], strides: [14, 2])
    var dim = [5, 7]
    var strides = [14, 2]
    _ = array.arrayView(withDimensionCount: 2, dimensionSizes: &dim, strides: &strides)
    array.synchronize(on: cmd)
    precondition(array.userBuffer() == nil)
    _ = MPSNDArray.defaultAllocator()
    let scalar = MPSNDArray(device: device, scalar: 3)
    precondition(scalar.resourceSize() == 4)
    let buffer = device.makeBuffer(length: 64)
    let fromBuf = MPSNDArray(buffer: buffer, offset: 0, descriptor: MPSNDArrayDescriptor(dataType: .float32, shape: [4]))
    precondition(fromBuf.userBuffer() === buffer)
    fromBuf.exportData(
        with: cmd,
        to: buffer,
        destinationDataType: .float32,
        offset: 0,
        rowStrides: nil
    )
    fromBuf.importData(
        with: cmd,
        from: buffer,
        sourceDataType: .float32,
        offset: 0,
        rowStrides: nil
    )
    let alloc = MPSNDArrayDefaultAllocator()
    precondition(MPSNDArrayDefaultAllocator.supportsSecureCoding)
    alloc.encode(with: NSCoder())
    _ = MPSNDArrayDefaultAllocator(coder: NSCoder())
    let allocated = alloc.array(
        for: cmd,
        arrayDescriptor: MPSNDArrayDescriptor(dataType: .float32, shape: [2]),
        kernel: MPSKernel(device: device)
    )
    precondition(allocated.numberOfDimensions == 1)
    let tmp = MPSTemporaryNDArray(
        commandBuffer: cmd,
        descriptor: MPSNDArrayDescriptor(dataType: .float32, shape: [3])
    )
    precondition(tmp.readCount == 1)
    _ = MPSTemporaryNDArray.defaultAllocator()
}

func testMPSTypealiases() {
    let _: MPSCopyAllocator? = nil
    let _: MPSAccelerationStructureCompletionHandler = { _ in }
    let _: MPSNNGraphCompletionHandler = { _, _ in }
    let _: MPSGradientNodeBlock = { _, _, _, _ in }
    let caps: MPSDeviceCaps = 0
    _ = caps
    let constant: MPSFunctionConstant = -1
    _ = constant
    let metalConst: MPSFunctionConstantInMetal = 0
    _ = metalConst
    _ = MTLPixelFormat.invalid
    _ = MTLPixelFormat.r8Unorm
    _ = MTLPixelFormat.r16Float
    _ = MTLPixelFormat.r32Float
    _ = MTLPixelFormat.rgba8Unorm
    _ = MTLPixelFormat.rgba16Float
    _ = MTLPixelFormat.rgba32Float
    _ = MTLPixelFormat.bgra8Unorm
    _ = MTLTextureUsage.unknown
    _ = MTLTextureUsage.shaderRead
    _ = MTLTextureUsage.shaderWrite
    _ = MTLTextureUsage.renderTarget
    _ = MTLTextureUsage.pixelFormatView
    _ = MTLCPUCacheMode.defaultCache
    _ = MTLCPUCacheMode.writeCombined
    _ = MTLStorageMode.shared
    _ = MTLStorageMode.managed
    _ = MTLStorageMode.private
    _ = MTLStorageMode.memoryless
    _ = MTLTextureType.type1D
    _ = MTLTextureType.type1DArray
    _ = MTLTextureType.type2D
    _ = MTLTextureType.type2DArray
    _ = MTLTextureType.type2DMultisample
    _ = MTLTextureType.typeCube
    _ = MTLTextureType.typeCubeArray
    _ = MTLTextureType.type3D
    let origin = MTLOrigin(x: 1, y: 2, z: 3)
    _ = origin
    let size = MTLSize(width: 1, height: 2, depth: 3)
    _ = size
    let region = MTLRegion(origin: origin, size: size)
    _ = region
}
