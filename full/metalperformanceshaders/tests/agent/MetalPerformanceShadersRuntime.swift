import MetalPerformanceShaders
import Foundation

precondition(MPSSupportsMTLDevice(nil) == false)
precondition(MPSGetPreferredDevice(.Default) == nil)
precondition(MPSGetPreferredDevice(.lowPower) == nil)

precondition(MPSSizeofMPSDataType(.float32) == 4)
precondition(MPSSizeofMPSDataType(.float16) == 2)
precondition(MPSSizeofMPSDataType(.uInt8) == 1)
precondition(MPSDataTypeBitsCount(.float32) == 32)
precondition(MPSDataTypeBitsCount(.int8) == 8)
precondition(MPSDataType.intBit == .signedBit)

var options: MPSKernelOptions = [.skipAPIValidation, .allowReducedPrecision]
precondition(options.contains(.skipAPIValidation))
options.formUnion(.verbose)
precondition(options.contains(.verbose))
precondition(!MPSKernelOptions.none.contains(.skipAPIValidation))

let edge = MPSImageEdgeMode.clamp
precondition(edge.rawValue == 1)
precondition(MPSAlphaType.premultiplied.rawValue == 1)

let device = MPSHostDevice.shared
precondition(MPSSupportsMTLDevice(device) == false)
precondition(device.name == "MPSHostDevice")

let descriptor = MPSImageDescriptor(
    channelFormat: .unorm8,
    width: 8,
    height: 4,
    featureChannels: 4
)
precondition(descriptor.width == 8)
precondition(descriptor.height == 4)
precondition(descriptor.pixelFormat == .rgba8Unorm)
let copied = descriptor.copy() as MPSImageDescriptor
precondition(copied.width == 8)

let image = MPSImage(device: device, imageDescriptor: descriptor)
precondition(image.width == 8)
precondition(image.height == 4)
precondition(image.featureChannels == 4)
precondition(image.resourceSize() > 0)

var pixels = [UInt8](repeating: 0, count: 8 * 4 * 4)
for i in 0..<pixels.count { pixels[i] = UInt8(i % 251) }
pixels.withUnsafeBytes { raw in
    image.writeBytes(raw.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0)
}
var roundtrip = [UInt8](repeating: 1, count: pixels.count)
roundtrip.withUnsafeMutableBytes { raw in
    image.readBytes(raw.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0)
}
precondition(roundtrip == pixels)

let blur = MPSImageGaussianBlur(device: device, sigma: 2.5)
precondition(blur.sigma == 2.5)
precondition(blur.edgeMode == .clamp)
let region = blur.sourceRegion(destinationSize: MTLSize(width: 8, height: 4, depth: 1))
precondition(region.size.width == 8)
precondition(region.size.height == 4)
let blurCopy = blur.copy(with: nil, device: device)
precondition(blurCopy.sigma == 2.5)

var histogramInfo = MPSImageHistogramInfo()
histogramInfo.numberOfHistogramEntries = 256
let histogram = MPSImageHistogram(device: device, histogramInfo: &histogramInfo)
precondition(histogram.histogramSize(forSourceFormat: .rgba8Unorm) == 256 * 4 * 4)

let box = MPSImageBox(device: device, kernelWidth: 3, kernelHeight: 5)
precondition(box.kernelWidth == 3)
precondition(box.kernelHeight == 5)
_ = MPSImageTent(device: device, kernelWidth: 3, kernelHeight: 3)

let matrixDesc = MPSMatrixDescriptor(rows: 4, columns: 8, rowBytes: 32, dataType: .float32)
precondition(MPSMatrixDescriptor.rowBytes(forColumns: 8, dataType: .float32) == 32)
let matrix = MPSMatrix(device: device, descriptor: matrixDesc)
precondition(matrix.rows == 4)
precondition(matrix.columns == 8)
precondition(matrix.resourceSize() >= 32 * 4)

let vectorDesc = MPSVectorDescriptor(length: 16, dataType: .float32)
let vector = MPSVector(device: device, descriptor: vectorDesc)
precondition(vector.length == 16)

let params = MPSFindIntegerDivisionParams(7)
precondition(params.divisor == 7)
precondition(params.recip > 0)

let batch = image.batchRepresentation()
precondition(batch.count == 1)
precondition(MPSImageBatchResourceSize(batch) == image.resourceSize())
let iterate = MPSImageBatchIterate(batch) { _, index in
    index == 0 ? 0 : 1
}
precondition(iterate == 0)

let kernel = MPSKernel(device: device)
kernel.label = "probe"
kernel.options = .skipAPIValidation
let kernelCopy = kernel.copy(with: nil, device: device)
precondition(kernelCopy.label == "probe")

precondition(MPSRectNoClip.size.width > 0)
let imageType = MPSGetImageType(image)
precondition(imageType.rawValue != 0)

let commandBuffer = device.makeCommandBuffer()
MPSHintTemporaryMemoryHighWaterMark(commandBuffer, 4096)
MPSSetHeapCacheDuration(commandBuffer, 0)

let packed = MPSPackedFloat3(x: 1, y: 2, z: 3)
precondition(packed.elements.1 == 2)
let nd = MPSNDArray(device: device, descriptor: MPSNDArrayDescriptor(dataType: .float32, shape: [2, 2]))
precondition(nd.length(ofDimension: 0) == 2)
precondition(MPSImageMedian.minKernelDiameter() == 3)
precondition(MPSImageMedian.maxKernelDiameter() == 9)

let aDesc = MPSMatrixDescriptor(rows: 2, columns: 2, rowBytes: 8, dataType: .float32)
let a = MPSMatrix(device: device, descriptor: aDesc)
let b = MPSMatrix(device: device, descriptor: aDesc)
let c = MPSMatrix(device: device, descriptor: aDesc)
let ap = a.data.contents.bindMemory(to: Float.self, capacity: 4)
let bp = b.data.contents.bindMemory(to: Float.self, capacity: 4)
ap[0] = 1; ap[1] = 0; ap[2] = 0; ap[3] = 1
bp[0] = 2; bp[1] = 3; bp[2] = 4; bp[3] = 5
let gemm = MPSMatrixMultiplication(device: device, resultRows: 2, resultColumns: 2, interiorColumns: 2)
gemm.encode(commandBuffer: commandBuffer, leftMatrix: a, rightMatrix: b, resultMatrix: c)
let cp = c.data.contents.bindMemory(to: Float.self, capacity: 4)
precondition(abs(cp[0] - 2) < 0.001)
precondition(abs(cp[3] - 5) < 0.001)

MPSHostBoundary.reset()
let unary = MPSUnaryImageKernel(device: device)
unary.encode(commandBuffer: commandBuffer, sourceImage: image, destinationImage: image)
precondition(MPSHostBoundary.lastRefusedAPI != nil)

func mpsRuntimeUnorm(_ width: Int, _ height: Int, _ pixels: [UInt8]) -> MPSImage {
    let runtimeImage = MPSImage(
        device: device,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: width, height: height, featureChannels: 1)
    )
    pixels.withUnsafeBytes { raw in
        runtimeImage.writeBytes(raw.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0)
    }
    return runtimeImage
}
func mpsRuntimeRead(_ runtimeImage: MPSImage) -> [UInt8] {
    var out = [UInt8](repeating: 0, count: runtimeImage.width * runtimeImage.height)
    out.withUnsafeMutableBytes { raw in
        runtimeImage.readBytes(raw.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0)
    }
    return out
}

var identity: [Float] = [0, 0, 0, 0, 1, 0, 0, 0, 0]
let conv = MPSImageConvolution(device: device, kernelWidth: 3, kernelHeight: 3, weights: &identity)
conv.edgeMode = .zero
let convSrc = mpsRuntimeUnorm(3, 3, [10, 20, 30, 40, 50, 60, 70, 80, 90])
let convDst = mpsRuntimeUnorm(3, 3, Array(repeating: 0, count: 9))
conv.encode(commandBuffer: commandBuffer, sourceImage: convSrc, destinationImage: convDst)
precondition(mpsRuntimeRead(convDst) == [10, 20, 30, 40, 50, 60, 70, 80, 90])
let clipped = mpsRuntimeUnorm(3, 3, Array(repeating: 7, count: 9))
conv.clipRect = MTLRegion.make2D(1, 1, 1, 1)
conv.offset = MPSOffset(x: 1, y: 1, z: 0)
conv.encode(commandBuffer: commandBuffer, sourceImage: convSrc, destinationImage: clipped)
precondition(mpsRuntimeRead(clipped)[4] == 50)
precondition(mpsRuntimeRead(clipped)[0] == 7)

let layout = MPSImage(
    device: device,
    imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 2, height: 2, featureChannels: 3)
)
let chw: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
chw.withUnsafeBytes { raw in
    layout.writeBytes(raw.baseAddress!, dataLayout: .featureChannelsxHeightxWidth, imageIndex: 0)
}
var hwc = [UInt8](repeating: 0, count: 12)
hwc.withUnsafeMutableBytes { raw in
    layout.readBytes(raw.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0)
}
precondition(hwc[0] == 1 && hwc[1] == 5 && hwc[2] == 9)

let softDesc = MPSMatrixDescriptor(rows: 1, columns: 3, rowBytes: 12, dataType: .float32)
let softIn = MPSMatrix(device: device, descriptor: softDesc)
let softOut = MPSMatrix(device: device, descriptor: softDesc)
let sp = softIn.data.contents.bindMemory(to: Float.self, capacity: 3)
sp[0] = 1; sp[1] = 2; sp[2] = 3
let softmax = MPSMatrixSoftMax(device: device)
softmax.sourceRows = 1
softmax.sourceColumns = 3
softmax.encode(commandBuffer: commandBuffer, inputMatrix: softIn, resultMatrix: softOut)
let so = softOut.data.contents.bindMemory(to: Float.self, capacity: 3)
precondition(abs(so[0] + so[1] + so[2] - 1) < 0.0001)
precondition(so[2] > so[1] && so[1] > so[0])

let cnnDesc = MPSCNNConvolutionDescriptor(
    kernelWidth: 1,
    kernelHeight: 1,
    inputFeatureChannels: 1,
    outputFeatureChannels: 1
)
precondition(cnnDesc.kernelWidth == 1)
var cnnWeights: [Float] = [1]
var cnnBias: [Float] = [0]
let cnn = MPSCNNConvolution(
    device: device,
    convolutionDescriptor: cnnDesc,
    kernelWeights: &cnnWeights,
    biasTerms: &cnnBias,
    flags: .none
)
MPSHostBoundary.reset()
cnn.encode(commandBuffer: commandBuffer, sourceImage: convSrc, destinationImage: convDst)
precondition(MPSHostBoundary.lastRefusedAPI != nil)

let rays = MPSRayIntersector(device: device)
rays.cullMode = .back
MPSHostBoundary.reset()
rays.encodeIntersection(
    commandBuffer: commandBuffer,
    intersectionType: .nearest,
    rayBuffer: device.makeBuffer(length: 64),
    rayBufferOffset: 0,
    intersectionBuffer: device.makeBuffer(length: 64),
    intersectionBufferOffset: 0,
    rayCount: 1,
    accelerationStructure: MPSAccelerationStructure(device: device)
)
precondition(MPSHostBoundary.lastRefusedAPI != nil)

let neuron = MPSMatrixNeuron(device: device)
neuron.sourceNumberOfFeatureVectors = 1
neuron.sourceInputFeatureChannels = 2
neuron.setNeuronType(.reLU, parameterA: 0, parameterB: 0, parameterC: 0)
let nIn = MPSMatrix(device: device, descriptor: MPSMatrixDescriptor(rows: 1, columns: 2, rowBytes: 8, dataType: .float32))
let nOut = MPSMatrix(device: device, descriptor: MPSMatrixDescriptor(rows: 1, columns: 2, rowBytes: 8, dataType: .float32))
let np = nIn.data.contents.bindMemory(to: Float.self, capacity: 2)
np[0] = -1
np[1] = 2
neuron.encode(commandBuffer: commandBuffer, inputMatrix: nIn, biasVector: nil, resultMatrix: nOut)
let no = nOut.data.contents.bindMemory(to: Float.self, capacity: 2)
precondition(abs(no[0] - 0) < 0.001 && abs(no[1] - 2) < 0.001)

let fc = MPSMatrixFullyConnected(device: device)
fc.sourceNumberOfFeatureVectors = 1
fc.sourceInputFeatureChannels = 2
fc.sourceOutputFeatureChannels = 2
let ident = MPSMatrix(device: device, descriptor: MPSMatrixDescriptor(rows: 2, columns: 2, rowBytes: 8, dataType: .float32))
let ip = ident.data.contents.bindMemory(to: Float.self, capacity: 4)
ip[0] = 1; ip[1] = 0; ip[2] = 0; ip[3] = 1
let fcOut = MPSMatrix(device: device, descriptor: MPSMatrixDescriptor(rows: 1, columns: 2, rowBytes: 8, dataType: .float32))
fc.encode(commandBuffer: commandBuffer, inputMatrix: nIn, weightMatrix: ident, biasVector: nil, resultMatrix: fcOut)
let fo = fcOut.data.contents.bindMemory(to: Float.self, capacity: 2)
precondition(abs(fo[0] + 1) < 0.001 && abs(fo[1] - 2) < 0.001)

let bn = MPSMatrixBatchNormalization(device: device)
bn.sourceNumberOfFeatureVectors = 2
bn.sourceInputFeatureChannels = 1
bn.computeStatistics = true
bn.epsilon = 0
let bnIn = MPSMatrix(device: device, descriptor: MPSMatrixDescriptor(rows: 2, columns: 1, rowBytes: 4, dataType: .float32))
let bnOut = MPSMatrix(device: device, descriptor: MPSMatrixDescriptor(rows: 2, columns: 1, rowBytes: 4, dataType: .float32))
let bnPointer = bnIn.data.contents.bindMemory(to: Float.self, capacity: 2)
bnPointer[0] = 1
bnPointer[1] = 3
let mean = MPSVector(device: device, descriptor: MPSVectorDescriptor(length: 1, dataType: .float32))
let variance = MPSVector(device: device, descriptor: MPSVectorDescriptor(length: 1, dataType: .float32))
bn.encode(
    commandBuffer: commandBuffer,
    inputMatrix: bnIn,
    meanVector: mean,
    varianceVector: variance,
    gammaVector: nil,
    betaVector: nil,
    resultMatrix: bnOut
)
let bo = bnOut.data.contents.bindMemory(to: Float.self, capacity: 2)
precondition(abs(bo[0] + 1) < 0.001 && abs(bo[1] - 1) < 0.001)

let accel = MPSAccelerationStructure(device: device)
precondition(accel.status == .unbuilt)
MPSHostBoundary.reset()
accel.rebuild()
precondition(MPSHostBoundary.lastRefusedAPI != nil)

// Local continuation: the sealed runtime also executes the newly delivered path.
let reshapeSource = MPSNDArray(device: device, descriptor: MPSNDArrayDescriptor(dataType: .float32, sizes: [2, 3]))
var reshapeValues: [Float] = [1, 2, 3, 4, 5, 6]
reshapeValues.withUnsafeMutableBytes { reshapeSource.writeBytes($0.baseAddress!, strideBytes: nil) }
let reshapeKernel = MPSNDArrayIdentity(device: device)
MPSHostBoundary.reset()
let reshapeView = reshapeKernel.reshape(with: nil, sourceArray: reshapeSource, shape: [3, 2], destinationArray: nil)!
precondition(reshapeView.parent === reshapeSource && reshapeView.length(ofDimension: 0) == 3)
reshapeValues = [6, 5, 4, 3, 2, 1]
reshapeValues.withUnsafeMutableBytes { reshapeView.writeBytes($0.baseAddress!, strideBytes: nil) }
var reshapeRead = [Float](repeating: 0, count: 6)
reshapeRead.withUnsafeMutableBytes { reshapeSource.readBytes($0.baseAddress!, strideBytes: nil) }
precondition(reshapeRead == reshapeValues && MPSHostBoundary.lastRefusedAPI == nil)

let sliceImage = MPSImage(device: device,
    imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 2, height: 1, featureChannels: 5))
let sliceValues: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
sliceValues.withUnsafeBytes { sliceImage.writeBytes($0.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0) }
precondition(sliceImage.texture.arrayLength == 2 && sliceImage.resourceSize() == 16)
let reshapedImage = MPSNNReshape(device: device).encode(commandBuffer: commandBuffer, sourceImage: sliceImage,
    reshapedWidth: 1, reshapedHeight: 5, reshapedFeatureChannels: 2)
var sliceRead = [UInt8](repeating: 0, count: 10)
sliceRead.withUnsafeMutableBytes { reshapedImage.readBytes($0.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0) }
precondition(sliceRead == sliceValues && reshapedImage.height == 5)

print("METALPERFORMANCESHADERS_AGENT_RUNTIME_OK")
