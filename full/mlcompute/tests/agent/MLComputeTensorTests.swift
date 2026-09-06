import Foundation
import MLCompute

func testTensorDescriptorShapeAndStride() {
    precondition(MLCTensorDescriptor.maxTensorDimensions == 5)
    let descriptor = MLCTensorDescriptor(shape: [2, 3, 4], dataType: .float32)!
    precondition(descriptor.shape == [2, 3, 4])
    precondition(descriptor.stride == [12, 4, 1])
    precondition(descriptor.dimensionCount == 3)
    precondition(descriptor.dataType == .float32)
    precondition(descriptor.tensorAllocationSizeInBytes == 2 * 3 * 4 * 4)
    precondition(descriptor.sequenceLengths == nil)
    precondition(descriptor.sortedSequences == false)
    precondition(descriptor.batchSizePerSequenceStep == nil)
    let nchw = MLCTensorDescriptor(width: 5, height: 6, featureChannelCount: 3, batchSize: 2)!
    precondition(nchw.shape == [2, 3, 6, 5])
    let typed = MLCTensorDescriptor(
        width: 2,
        height: 2,
        featureChannelCount: 1,
        batchSize: 1,
        dataType: .int32
    )!
    precondition(typed.dataType == .int32)
    let weights = MLCTensorDescriptor(
        convolutionWeightsWithWidth: 3,
        height: 3,
        inputFeatureChannelCount: 4,
        outputFeatureChannelCount: 8,
        dataType: .float32
    )!
    precondition(weights.shape == [8, 4, 3, 3])
    let dense = MLCTensorDescriptor(
        convolutionWeightsWithInputFeatureChannelCount: 10,
        outputFeatureChannelCount: 5,
        dataType: .float32
    )!
    precondition(dense.shape == [5, 10])
    let biases = MLCTensorDescriptor(convolutionBiasesWithFeatureChannelCount: 8, dataType: .float32)!
    precondition(biases.shape == [8])
    let sequenced = MLCTensorDescriptor(
        shape: [4, 2, 3],
        sequenceLengths: [3, 4],
        sortedSequences: true,
        dataType: .float32
    )!
    precondition(sequenced.sortedSequences)
    precondition(sequenced.sequenceLengths == [3, 4])
    precondition(MLCTensorDescriptor(shape: [1, 2, 3, 4, 5, 6], dataType: .float32) == nil)
    let copy = descriptor.copy() as! MLCTensorDescriptor
    precondition(copy.shape == descriptor.shape)
}

func testTensorDataRoundTrip() {
    var bytes: [Float] = [1, 2, 3, 4]
    let data = bytes.withUnsafeMutableBufferPointer { buffer in
        MLCTensorData(bytesNoCopy: UnsafeMutableRawPointer(buffer.baseAddress!), length: 16)
    }
    precondition(data.length == 16)
    precondition(data.linuxData().count == 16)
    var owned: [Float] = [9, 8]
    var deallocated = false
    let withDeallocator = owned.withUnsafeMutableBufferPointer { buffer in
        MLCTensorData(
            bytesNoCopy: UnsafeMutableRawPointer(buffer.baseAddress!),
            length: 8,
            deallocator: { _, _ in deallocated = true }
        )
    }
    precondition(withDeallocator.length == 8)
    _ = withDeallocator
    let immutable: [Float] = [5, 6]
    immutable.withUnsafeBytes { buffer in
        let copied = MLCTensorData(immutableBytesNoCopy: buffer.baseAddress!, length: 8)
        precondition(copied.length == 8)
    }
    let fromData = MLCTensorData(linuxCopying: Data([1, 2, 3]))
    precondition(fromData.length == 3)
    _ = deallocated
}

func testTensorFillAndNumerics() {
    let filled = MLCTensor(shape: [2, 2], fillWithData: NSNumber(value: Float(3)), dataType: .float32)
    precondition(filled.descriptor.shape == [2, 2])
    precondition(filled.linuxHostFloats() == [3, 3, 3, 3])
    precondition(filled.hasValidNumerics)
    precondition(filled.data?.count == 16)
    precondition(filled.tensorID > 0)
    filled.label = "input"
    precondition(filled.label == "input")
    precondition(filled.device == nil)
    precondition(filled.optimizerData.isEmpty)
    precondition(filled.optimizerDeviceData.isEmpty)
    let random = MLCTensor(shape: [4], randomInitializerType: .glorotUniform)
    precondition(random.linuxHostFloats()?.count == 4)
    let xavier = MLCTensor(descriptor: MLCTensorDescriptor(shape: [2, 2], dataType: .float32)!, randomInitializerType: .xavier)
    precondition(xavier.descriptor.shape == [2, 2])
    let nchw = MLCTensor(width: 2, height: 2, featureChannelCount: 1, batchSize: 1, fillWithData: 1.5, dataType: .float32)
    precondition(nchw.linuxHostFloats()?.first == 1.5)
}

func testTensorBindCopyAndQuantize() {
    let tensor = MLCTensor(shape: [2], fillWithData: NSNumber(value: Float(4)), dataType: .float32)
    var payload: [Float] = [1, 2]
    let written = payload.withUnsafeMutableBufferPointer { buffer in
        tensor.bindAndWriteData(
            MLCTensorData(bytesNoCopy: UnsafeMutableRawPointer(buffer.baseAddress!), length: 8),
            to: MLCDevice.cpu()
        )
    }
    precondition(written)
    precondition(tensor.device?.actualDeviceType == .cpu)
    precondition(tensor.synchronizeData())
    var dest = [Float](repeating: 0, count: 2)
    dest.withUnsafeMutableBufferPointer { buffer in
        precondition(
            tensor.copyDataFromDeviceMemory(
                toBytes: UnsafeMutableRawPointer(buffer.baseAddress!),
                length: 8,
                synchronizeWithDevice: true
            )
        )
    }
    precondition(dest == [1, 2])
    let quantized = tensor.quantized(to: .int8, scale: 1, bias: 0)!
    precondition(quantized.descriptor.dataType == .int8)
    let scale = MLCTensor(shape: [1], fillWithData: NSNumber(value: Float(1)), dataType: .float32)
    let zero = MLCTensor(shape: [1], fillWithData: NSNumber(value: Float(0)), dataType: .float32)
    let axisQuant = tensor.quantized(to: .uint8, scale: scale, bias: zero, axis: 0)
    precondition(axisQuant != nil)
    let dequant = quantized.dequantized(to: .float32, scale: scale, zeroPoint: zero)
    precondition(dequant != nil)
    let dequantAxis = quantized.dequantized(to: .float32, scale: scale, bias: zero, axis: 0)
    precondition(dequantAxis != nil)
    let opt = MLCTensorData(linuxCopying: Data(count: 8))
    precondition(tensor.bindOptimizerData([opt], deviceData: [MLCTensorOptimizerDeviceData()]))
    precondition(tensor.synchronizeOptimizerData())
    precondition(MLCDevice.cpu().type == .cpu)
}

func testTensorConvenienceInits() {
    let descriptor = MLCTensorDescriptor(shape: [2, 2], dataType: .float32)!
    let empty = MLCTensor(descriptor: descriptor)
    precondition(empty.descriptor.dimensionCount == 2)
    let payload = MLCTensorData(linuxCopying: Data(count: 16))
    let withData = MLCTensor(descriptor: descriptor, data: payload)
    precondition(withData.data?.count == 16)
    let fill = MLCTensor(descriptor: descriptor, fillWithData: NSNumber(value: Float(1)))
    precondition(fill.linuxHostFloats()?.first == 1)
    let shaped = MLCTensor(shape: [3], dataType: .int32)
    precondition(shaped.descriptor.dataType == .int32)
    let shapedData = MLCTensor(shape: [4], data: MLCTensorData(linuxCopying: Data(count: 16)), dataType: .float32)
    precondition(shapedData.descriptor.shape == [4])
    let nchw = MLCTensor(width: 2, height: 2, featureChannelCount: 1, batchSize: 1)
    precondition(nchw.descriptor.shape == [1, 1, 2, 2])
    let nchwData = MLCTensor(
        width: 1,
        height: 1,
        featureChannelCount: 1,
        batchSize: 1,
        data: MLCTensorData(linuxCopying: Data(count: 4))
    )
    precondition(nchwData.descriptor.shape.last == 1)
    let nchwTyped = MLCTensor(
        width: 1,
        height: 1,
        featureChannelCount: 1,
        batchSize: 1,
        data: MLCTensorData(linuxCopying: Data(count: 4)),
        dataType: .float32
    )
    precondition(nchwTyped.descriptor.dataType == .float32)
    let nchwRandom = MLCTensor(
        width: 1,
        height: 1,
        featureChannelCount: 1,
        batchSize: 1,
        randomInitializerType: .uniform
    )
    precondition(nchwRandom.linuxHostFloats()?.count == 1)
    let seq = MLCTensor(sequenceLength: 3, featureChannelCount: 2, batchSize: 1)
    precondition(seq.descriptor.shape == [3, 1, 2])
    let seqData = MLCTensor(
        sequenceLength: 2,
        featureChannelCount: 1,
        batchSize: 1,
        data: nil
    )
    precondition(seqData.descriptor.shape.first == 2)
    let seqRandom = MLCTensor(
        sequenceLength: 2,
        featureChannelCount: 1,
        batchSize: 1,
        randomInitializerType: .uniform
    )
    precondition(seqRandom.linuxHostFloats()?.count == 2)
    let variable = MLCTensor(
        sequenceLengths: [1, 2],
        sortedSequences: true,
        featureChannelCount: 1,
        batchSize: 2
    )!
    precondition(variable.descriptor.sortedSequences)
    let variableRandom = MLCTensor(
        sequenceLengths: [2],
        sortedSequences: false,
        featureChannelCount: 1,
        batchSize: 1,
        randomInitializerType: .uniform
    )!
    precondition(variableRandom.descriptor.shape.first == 2)
}

func testTensorParameterAndDeviceData() {
    let tensor = MLCTensor(shape: [2])
    let parameter = MLCTensorParameter(tensor: tensor)
    precondition(parameter.tensor === tensor)
    precondition(parameter.isUpdatable)
    parameter.isUpdatable = false
    precondition(parameter.isUpdatable == false)
    let withOpt = MLCTensorParameter(tensor: tensor, optimizerData: [MLCTensorData(linuxCopying: Data(count: 8))])
    precondition(withOpt.tensor.optimizerData.count == 1)
    let deviceData = MLCTensorOptimizerDeviceData()
    _ = ObjectIdentifier(deviceData)
}
