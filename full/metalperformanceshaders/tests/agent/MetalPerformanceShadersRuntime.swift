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

print("METALPERFORMANCESHADERS_AGENT_RUNTIME_OK")
