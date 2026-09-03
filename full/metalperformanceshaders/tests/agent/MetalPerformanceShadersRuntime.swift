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

print("METALPERFORMANCESHADERS_AGENT_RUNTIME_OK")
