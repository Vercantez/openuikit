import Foundation
import MetalPerformanceShaders

func testMPSImageFiltersConstruction() {
    let device = MPSHostDevice.shared
    let blur = MPSImageGaussianBlur(device: device, sigma: 2.5)
    precondition(blur.sigma == 2.5)
    precondition(blur.edgeMode == .clamp)
    let copied = blur.copy(with: nil, device: device)
    precondition(copied.sigma == 2.5)
    precondition(MPSImageGaussianBlur(coder: NSCoder(), device: device) == nil)
    _ = MPSImageGaussianBlur(device: device)

    let box = MPSImageBox(device: device, kernelWidth: 3, kernelHeight: 5)
    precondition(box.kernelWidth == 3)
    precondition(box.kernelHeight == 5)
    let boxCopy = box.copy(with: nil, device: device)
    precondition(boxCopy.kernelHeight == 5)
    _ = MPSImageBox(device: device)
    precondition(MPSImageBox(coder: NSCoder(), device: device) == nil)
    let tent = MPSImageTent(device: device, kernelWidth: 3, kernelHeight: 3)
    precondition(tent.kernelWidth == 3)
    _ = MPSImageTent(device: device)

    var transform: [Float] = [0.3, 0.5, 0.2]
    let sobel = MPSImageSobel(device: device, linearGrayColorTransform: &transform)
    precondition(sobel.colorTransform[0] == 0.3)
    _ = MPSImageSobel(device: device)
    precondition(MPSImageSobel(coder: NSCoder(), device: device) == nil)

    var histogramInfo = MPSImageHistogramInfo()
    histogramInfo.numberOfHistogramEntries = 256
    let histogram = MPSImageHistogram(device: device, histogramInfo: &histogramInfo)
    precondition(histogram.histogramSize(forSourceFormat: .rgba8Unorm) == 256 * 4 * 4)
    histogram.zeroHistogram = true
    histogram.minPixelThresholdValue = .zero
    histogram.clipRectSource = MPSRectNoClip
    _ = histogram.histogramInfo
    _ = MPSImageHistogram(device: device)
    precondition(MPSImageHistogram(coder: NSCoder(), device: device) == nil)

    let eq = MPSImageHistogramEqualization(device: device, histogramInfo: &histogramInfo)
    _ = eq.histogramInfo
    _ = MPSImageHistogramEqualization(device: device)
    precondition(MPSImageHistogramEqualization(coder: NSCoder(), device: device) == nil)
    let spec = MPSImageHistogramSpecification(device: device, histogramInfo: &histogramInfo)
    _ = spec.histogramInfo
    _ = MPSImageHistogramSpecification(device: device)
    precondition(MPSImageHistogramSpecification(coder: NSCoder(), device: device) == nil)

    let scale = MPSImageScale(device: device)
    var transform2 = MPSScaleTransform(scaleX: 2, scaleY: 2, translateX: 0, translateY: 0)
    withUnsafePointer(to: &transform2) { pointer in
        scale.scaleTransform = pointer
    }
    precondition(scale.scaleTransform?.pointee.scaleX == 2)
    scale.scaleTransform = nil
    precondition(scale.scaleTransform == nil)
    precondition(MPSImageScale(coder: NSCoder(), device: device) == nil)
    _ = MPSImageLanczosScale(device: device)
    precondition(MPSImageLanczosScale(coder: NSCoder(), device: device) == nil)
    _ = MPSImageBilinearScale(device: device)
    precondition(MPSImageBilinearScale(coder: NSCoder(), device: device) == nil)

    let bin = MPSImageThresholdBinary(device: device, thresholdValue: 0.4, maximumValue: 1, linearGrayColorTransform: &transform)
    precondition(bin.thresholdValue == 0.4 && bin.maximumValue == 1)
    _ = bin.transform
    _ = MPSImageThresholdBinary(device: device)
    precondition(MPSImageThresholdBinary(coder: NSCoder(), device: device) == nil)
    let inv = MPSImageThresholdBinaryInverse(device: device, thresholdValue: 0.2, maximumValue: 1, linearGrayColorTransform: nil)
    precondition(inv.thresholdValue == 0.2)
    _ = inv.transform
    _ = MPSImageThresholdBinaryInverse(device: device)
    precondition(MPSImageThresholdBinaryInverse(coder: NSCoder(), device: device) == nil)
    let toZero = MPSImageThresholdToZero(device: device, thresholdValue: 0.1, linearGrayColorTransform: nil)
    precondition(toZero.thresholdValue == 0.1)
    _ = toZero.transform
    _ = MPSImageThresholdToZero(device: device)
    precondition(MPSImageThresholdToZero(coder: NSCoder(), device: device) == nil)
    let trunc = MPSImageThresholdTruncate(device: device, thresholdValue: 0.9, linearGrayColorTransform: nil)
    precondition(trunc.thresholdValue == 0.9)
    _ = trunc.transform
    _ = MPSImageThresholdTruncate(device: device)
    precondition(MPSImageThresholdTruncate(coder: NSCoder(), device: device) == nil)
    let area = MPSImageAreaMax(device: device, kernelWidth: 3, kernelHeight: 3)
    precondition(area.kernelWidth == 3)
    _ = MPSImageAreaMax(device: device)
    precondition(MPSImageAreaMax(coder: NSCoder(), device: device) == nil)
    _ = MPSImageAreaMin(device: device, kernelWidth: 3, kernelHeight: 3)
    _ = MPSImageAreaMin(device: device)
}

func testMPSGaussianCPUEncode() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let source = MPSImage(
        device: device,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 8, height: 8, featureChannels: 1)
    )
    let dest = MPSImage(
        device: device,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 8, height: 8, featureChannels: 1)
    )
    var pixels = [UInt8](repeating: 0, count: 64)
    pixels[4 * 8 + 4] = 255
    pixels.withUnsafeBytes { raw in
        source.writeBytes(raw.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0)
    }
    let blur = MPSImageGaussianBlur(device: device, sigma: 1)
    blur.encode(commandBuffer: cmd, sourceImage: source, destinationImage: dest)
    var out = [UInt8](repeating: 0, count: 64)
    out.withUnsafeMutableBytes { raw in
        dest.readBytes(raw.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0)
    }
    precondition(out[4 * 8 + 4] > 0)
    precondition(out[4 * 8 + 3] > 0)
}

func testMPSHistogramCPUEncode() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 4, height: 4, mipmapped: false)
    let texture = device.makeTexture(descriptor: descriptor)
    var bytes = Data(count: 4 * 4 * 4)
    bytes.withUnsafeMutableBytes { raw in
        for i in stride(from: 0, to: 64, by: 4) {
            raw.storeBytes(of: UInt8(255), toByteOffset: i, as: UInt8.self)
            raw.storeBytes(of: UInt8(0), toByteOffset: i + 1, as: UInt8.self)
            raw.storeBytes(of: UInt8(0), toByteOffset: i + 2, as: UInt8.self)
            raw.storeBytes(of: UInt8(255), toByteOffset: i + 3, as: UInt8.self)
        }
    }
    texture.bytes = bytes
    var info = MPSImageHistogramInfo()
    info.numberOfHistogramEntries = 256
    info.histogramForAlpha = ObjCBool(true)
    let histogram = MPSImageHistogram(device: device, histogramInfo: &info)
    let buffer = device.makeBuffer(length: histogram.histogramSize(forSourceFormat: .rgba8Unorm))
    histogram.encode(to: cmd, sourceTexture: texture, histogram: buffer, histogramOffset: 0)
    let counts = buffer.contents.bindMemory(to: UInt32.self, capacity: 256 * 4)
    precondition(counts[255] == 16)
    precondition(counts[256 + 0] == 16)
}

func testMPSConvolutionAndArithmetic() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    var identity: [Float] = [0, 0, 0, 0, 1, 0, 0, 0, 0]
    let conv = MPSImageConvolution(device: device, kernelWidth: 3, kernelHeight: 3, weights: &identity)
    precondition(conv.kernelWidth == 3 && conv.kernelHeight == 3)
    conv.bias = 0
    precondition(conv.bias == 0)
    _ = MPSImageConvolution(device: device)
    precondition(MPSImageConvolution(coder: NSCoder(), device: device) == nil)
    let source = MPSImage(
        device: device,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 4, height: 4, featureChannels: 1)
    )
    let dest = MPSImage(
        device: device,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 4, height: 4, featureChannels: 1)
    )
    var pixels = [UInt8](repeating: 32, count: 16)
    pixels[0] = 200
    pixels.withUnsafeBytes { raw in
        source.writeBytes(raw.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0)
    }
    conv.encode(commandBuffer: cmd, sourceImage: source, destinationImage: dest)
    var out = [UInt8](repeating: 0, count: 16)
    out.withUnsafeMutableBytes { raw in
        dest.readBytes(raw.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0)
    }
    precondition(out[0] > 100)

    let box = MPSImageBox(device: device, kernelWidth: 3, kernelHeight: 3)
    box.encode(commandBuffer: cmd, sourceImage: source, destinationImage: dest)

    let transposed = MPSImage(
        device: device,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 4, height: 4, featureChannels: 1)
    )
    let transpose = MPSImageTranspose(device: device)
    transpose.encode(commandBuffer: cmd, sourceImage: source, destinationImage: transposed)
    precondition(MPSImageTranspose(coder: NSCoder(), device: device) == nil)

    let add = MPSImageAdd(device: device)
    add.primaryScale = 1
    add.secondaryScale = 1
    add.bias = 0
    add.minimumValue = 0
    add.maximumValue = 1
    add.primaryStrideInPixels = MTLSize(width: 1, height: 1, depth: 1)
    add.secondaryStrideInPixels = MTLSize(width: 1, height: 1, depth: 1)
    add.encode(commandBuffer: cmd, primaryImage: source, secondaryImage: source, destinationImage: dest)
    _ = MPSImageSubtract(device: device)
    _ = MPSImageMultiply(device: device)
    _ = MPSImageDivide(device: device)
    _ = MPSImageArithmetic(device: device)
    precondition(MPSImageArithmetic(coder: NSCoder(), device: device) == nil)
}

func testMPSAdditionalImageKernels() {
    let device = MPSHostDevice.shared
    precondition(MPSImageMedian.minKernelDiameter() == 3)
    precondition(MPSImageMedian.maxKernelDiameter() == 9)
    let median = MPSImageMedian(device: device, kernelDiameter: 5)
    precondition(median.kernelDiameter == 5)
    _ = MPSImageMedian(device: device)
    precondition(MPSImageMedian(coder: NSCoder(), device: device) == nil)
    var values: [Float] = [0, 1, 0, 1, 1, 1, 0, 1, 0]
    let dilate = MPSImageDilate(device: device, kernelWidth: 3, kernelHeight: 3, values: &values)
    precondition(dilate.kernelWidth == 3 && dilate.kernelHeight == 3)
    _ = MPSImageDilate(device: device)
    precondition(MPSImageDilate(coder: NSCoder(), device: device) == nil)
    _ = MPSImageErode(device: device, kernelWidth: 3, kernelHeight: 3, values: &values)
    _ = MPSImageErode(device: device)
    _ = MPSImageIntegral(device: device)
    _ = MPSImageIntegralOfSquares(device: device)
    let lap = MPSImageLaplacian(device: device)
    lap.bias = 0.1
    precondition(lap.bias == 0.1)
    var weights: [Float] = Array(repeating: 0.04, count: 25)
    let pyramid = MPSImagePyramid(device: device, kernelWidth: 5, kernelHeight: 5, weights: &weights)
    precondition(pyramid.kernelWidth == 5 && pyramid.kernelHeight == 5)
    _ = MPSImagePyramid(device: device)
    _ = MPSImagePyramid(device: device, centerWeight: 0.4)
    precondition(MPSImagePyramid(coder: NSCoder(), device: device) == nil)
    _ = MPSImageGaussianPyramid(device: device)
    let lapPyr = MPSImageLaplacianPyramid(device: device)
    lapPyr.laplacianBias = 0
    lapPyr.laplacianScale = 1
    precondition(lapPyr.laplacianScale == 1)
    _ = MPSImageLaplacianPyramidAdd(device: device)
    _ = MPSImageLaplacianPyramidSubtract(device: device)
    let reduce = MPSImageReduceUnary(device: device)
    reduce.clipRectSource = MPSRectNoClip
    _ = MPSImageReduceRowMin(device: device)
    _ = MPSImageReduceRowMax(device: device)
    _ = MPSImageReduceRowMean(device: device)
    _ = MPSImageReduceRowSum(device: device)
    _ = MPSImageReduceColumnMin(device: device)
    _ = MPSImageReduceColumnMax(device: device)
    _ = MPSImageReduceColumnMean(device: device)
    _ = MPSImageReduceColumnSum(device: device)
    let mean = MPSImageStatisticsMean(device: device)
    mean.clipRectSource = MPSRectNoClip
    precondition(MPSImageStatisticsMean(coder: NSCoder(), device: device) == nil)
    let meanVar = MPSImageStatisticsMeanAndVariance(device: device)
    meanVar.clipRectSource = MPSRectNoClip
    precondition(MPSImageStatisticsMeanAndVariance(coder: NSCoder(), device: device) == nil)
    let minMax = MPSImageStatisticsMinAndMax(device: device)
    minMax.clipRectSource = MPSRectNoClip
    precondition(MPSImageStatisticsMinAndMax(coder: NSCoder(), device: device) == nil)
    let toZeroInv = MPSImageThresholdToZeroInverse(device: device, thresholdValue: 0.3, linearGrayColorTransform: nil)
    precondition(toZeroInv.thresholdValue == 0.3)
    _ = toZeroInv.transform
    _ = MPSImageThresholdToZeroInverse(device: device)
    precondition(MPSImageThresholdToZeroInverse(coder: NSCoder(), device: device) == nil)
    var gray: [Float] = [0.299, 0.587, 0.114]
    let canny = MPSImageCanny(device: device, linearToGrayScaleTransform: &gray, sigma: 1.2)
    precondition(canny.sigma == 1.2)
    canny.highThreshold = 0.9
    canny.lowThreshold = 0.2
    canny.useFastMode = true
    precondition(canny.highThreshold == 0.9 && canny.useFastMode)
    _ = canny.colorTransform
    _ = MPSImageCanny(device: device)
    precondition(MPSImageCanny(coder: NSCoder(), device: device) == nil)
    var range = MPSImageKeypointRangeInfo(maximumKeypoints: 8, minimumThresholdValue: 0.1)
    let keypoints = MPSImageFindKeypoints(device: device, info: &range)
    precondition(keypoints.keypointRangeInfo.maximumKeypoints == 8)
    _ = MPSImageFindKeypoints(device: device)
    precondition(MPSImageFindKeypoints(coder: NSCoder(), device: device) == nil)
}
