import Foundation
import MetalPerformanceShaders

func mpsUnormImage(_ device: MPSHostDevice, width: Int, height: Int, pixels: [UInt8]) -> MPSImage {
    let image = MPSImage(
        device: device,
        imageDescriptor: MPSImageDescriptor(
            channelFormat: .unorm8,
            width: width,
            height: height,
            featureChannels: 1
        )
    )
    pixels.withUnsafeBytes { raw in
        image.writeBytes(raw.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0)
    }
    return image
}

func mpsRead1(_ image: MPSImage) -> [UInt8] {
    var out = [UInt8](repeating: 0, count: image.width * image.height)
    out.withUnsafeMutableBytes { raw in
        image.readBytes(raw.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0)
    }
    return out
}

func testMPSImageConvolutionPixelExact() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let source = mpsUnormImage(device, width: 3, height: 3, pixels: [10, 20, 30, 40, 50, 60, 70, 80, 90])
    let dest = mpsUnormImage(device, width: 3, height: 3, pixels: Array(repeating: 0, count: 9))
    var identity: [Float] = [0, 0, 0, 0, 1, 0, 0, 0, 0]
    let conv = MPSImageConvolution(device: device, kernelWidth: 3, kernelHeight: 3, weights: &identity)
    conv.edgeMode = .zero
    conv.encode(commandBuffer: cmd, sourceImage: source, destinationImage: dest)
    precondition(mpsRead1(dest) == [10, 20, 30, 40, 50, 60, 70, 80, 90])

    let clipped = mpsUnormImage(device, width: 3, height: 3, pixels: Array(repeating: 7, count: 9))
    conv.clipRect = MTLRegion.make2D(1, 1, 1, 1)
    conv.offset = MPSOffset(x: 0, y: 0, z: 0)
    conv.encode(commandBuffer: cmd, sourceImage: source, destinationImage: clipped)
    let clippedOut = mpsRead1(clipped)
    // Apple: offset is the source coordinate of clipRect.origin, so dest(1,1) samples source(0,0).
    precondition(clippedOut[4] == 10, "clip origin maps to offset, got \(clippedOut)")
    precondition(clippedOut[0] == 7 && clippedOut[8] == 7, "pixels outside clipRect stay untouched, got \(clippedOut)")

    let aligned = mpsUnormImage(device, width: 3, height: 3, pixels: Array(repeating: 7, count: 9))
    conv.offset = MPSOffset(x: 1, y: 1, z: 0)
    conv.encode(commandBuffer: cmd, sourceImage: source, destinationImage: aligned)
    let alignedOut = mpsRead1(aligned)
    precondition(alignedOut[4] == 50, "offset=(1,1) should copy source(1,1), got \(alignedOut)")
    precondition(alignedOut[0] == 7 && alignedOut[8] == 7)

    conv.clipRect = MPSRectNoClip
    conv.offset = MPSOffset(x: 0, y: 0, z: 0)
    let shifted = mpsUnormImage(device, width: 3, height: 1, pixels: [0, 0, 0])
    let row = mpsUnormImage(device, width: 3, height: 1, pixels: [10, 20, 30])
    var unit: [Float] = [1]
    let shift = MPSImageConvolution(device: device, kernelWidth: 1, kernelHeight: 1, weights: &unit)
    shift.edgeMode = .zero
    shift.offset = MPSOffset(x: 1, y: 0, z: 0)
    shift.encode(commandBuffer: cmd, sourceImage: row, destinationImage: shifted)
    let shiftedPixels = mpsRead1(shifted)
    precondition(shiftedPixels[0] == 20, "offset.x=1 dest[0] should sample source x=1, got \(shiftedPixels)")
    precondition(shiftedPixels[1] == 30, "offset.x=1 dest[1] should sample source x=2, got \(shiftedPixels)")
    precondition(shiftedPixels[2] == 0, "offset.x=1 dest[2] is past the source, zero-padded, got \(shiftedPixels)")
}

func testMPSImageBoxTentGaussianPixelExact() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let hot = mpsUnormImage(device, width: 3, height: 3, pixels: [0, 0, 0, 0, 255, 0, 0, 0, 0])
    let dest = mpsUnormImage(device, width: 3, height: 3, pixels: Array(repeating: 0, count: 9))
    let box = MPSImageBox(device: device, kernelWidth: 3, kernelHeight: 3)
    box.edgeMode = .zero
    box.encode(commandBuffer: cmd, sourceImage: hot, destinationImage: dest)
    // 255/9 = 28.333 → 28
    precondition(mpsRead1(dest)[4] == 28)

    let tentDest = mpsUnormImage(device, width: 3, height: 3, pixels: Array(repeating: 0, count: 9))
    let tent = MPSImageTent(device: device, kernelWidth: 3, kernelHeight: 3)
    tent.edgeMode = .zero
    tent.encode(commandBuffer: cmd, sourceImage: hot, destinationImage: tentDest)
    // center weight 4/16 → 63.75 → 64
    precondition(mpsRead1(tentDest)[4] == 64)

    let blurSrc = mpsUnormImage(device, width: 5, height: 1, pixels: [0, 0, 255, 0, 0])
    let blurDst = mpsUnormImage(device, width: 5, height: 1, pixels: [0, 0, 0, 0, 0])
    let blur = MPSImageGaussianBlur(device: device, sigma: 0.0001)
    blur.edgeMode = .zero
    blur.encode(commandBuffer: cmd, sourceImage: blurSrc, destinationImage: blurDst)
    let blurred = mpsRead1(blurDst)
    precondition(blurred[2] == 255)
    precondition(blurred[0] == 0 && blurred[4] == 0)
}

func testMPSImageMedianSobelLaplacianPixelExact() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let hot = mpsUnormImage(device, width: 3, height: 3, pixels: [0, 0, 0, 0, 255, 0, 0, 0, 0])
    let medianDest = mpsUnormImage(device, width: 3, height: 3, pixels: Array(repeating: 1, count: 9))
    let median = MPSImageMedian(device: device, kernelDiameter: 3)
    median.edgeMode = .zero
    median.encode(commandBuffer: cmd, sourceImage: hot, destinationImage: medianDest)
    precondition(mpsRead1(medianDest)[4] == 0)

    let edge = mpsUnormImage(device, width: 3, height: 3, pixels: [0, 0, 255, 0, 0, 255, 0, 0, 255])
    let sobelDest = mpsUnormImage(device, width: 3, height: 3, pixels: Array(repeating: 0, count: 9))
    let sobel = MPSImageSobel(device: device)
    sobel.edgeMode = .zero
    sobel.encode(commandBuffer: cmd, sourceImage: edge, destinationImage: sobelDest)
    precondition(mpsRead1(sobelDest)[4] == 255)

    let lapDest = mpsUnormImage(device, width: 3, height: 3, pixels: Array(repeating: 9, count: 9))
    let lap = MPSImageLaplacian(device: device)
    lap.bias = 0
    lap.edgeMode = .zero
    lap.encode(commandBuffer: cmd, sourceImage: hot, destinationImage: lapDest)
    let lapOut = mpsRead1(lapDest)
    precondition(lapOut[4] == 255)
    precondition(lapOut[1] == 0 && lapOut[3] == 0)
}

func testMPSImageThresholdPixelExact() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let source = mpsUnormImage(device, width: 3, height: 1, pixels: [64, 128, 200])
    let binDest = mpsUnormImage(device, width: 3, height: 1, pixels: [1, 1, 1])
    let binary = MPSImageThresholdBinary(device: device, thresholdValue: 0.5, maximumValue: 1, linearGrayColorTransform: nil)
    binary.encode(commandBuffer: cmd, sourceImage: source, destinationImage: binDest)
    precondition(mpsRead1(binDest) == [0, 255, 255])

    let toZeroDest = mpsUnormImage(device, width: 3, height: 1, pixels: [1, 1, 1])
    let toZero = MPSImageThresholdToZero(device: device, thresholdValue: 0.5, linearGrayColorTransform: nil)
    toZero.encode(commandBuffer: cmd, sourceImage: source, destinationImage: toZeroDest)
    precondition(mpsRead1(toZeroDest) == [0, 128, 200])

    let truncDest = mpsUnormImage(device, width: 3, height: 1, pixels: [1, 1, 1])
    let trunc = MPSImageThresholdTruncate(device: device, thresholdValue: 0.5, linearGrayColorTransform: nil)
    trunc.encode(commandBuffer: cmd, sourceImage: source, destinationImage: truncDest)
    precondition(mpsRead1(truncDest) == [64, 128, 128])
}

func testMPSImageAreaMorphologyPixelExact() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let source = mpsUnormImage(device, width: 3, height: 1, pixels: [10, 200, 30])
    let maxDest = mpsUnormImage(device, width: 3, height: 1, pixels: [0, 0, 0])
    let areaMax = MPSImageAreaMax(device: device, kernelWidth: 3, kernelHeight: 1)
    areaMax.edgeMode = .zero
    areaMax.encode(commandBuffer: cmd, sourceImage: source, destinationImage: maxDest)
    precondition(mpsRead1(maxDest) == [200, 200, 200])

    let minDest = mpsUnormImage(device, width: 3, height: 1, pixels: [0, 0, 0])
    let areaMin = MPSImageAreaMin(device: device, kernelWidth: 3, kernelHeight: 1)
    areaMin.edgeMode = .zero
    areaMin.encode(commandBuffer: cmd, sourceImage: source, destinationImage: minDest)
    precondition(mpsRead1(minDest) == [0, 10, 0])

    var zeros: [Float] = [0, 0, 0, 0, 0, 0, 0, 0, 0]
    let hot = mpsUnormImage(device, width: 3, height: 3, pixels: [0, 0, 0, 0, 255, 0, 0, 0, 0])
    let dilateDest = mpsUnormImage(device, width: 3, height: 3, pixels: Array(repeating: 0, count: 9))
    let dilate = MPSImageDilate(device: device, kernelWidth: 3, kernelHeight: 3, values: &zeros)
    dilate.edgeMode = .zero
    dilate.encode(commandBuffer: cmd, sourceImage: hot, destinationImage: dilateDest)
    precondition(mpsRead1(dilateDest)[4] == 255)

    let erodeDest = mpsUnormImage(device, width: 3, height: 3, pixels: Array(repeating: 9, count: 9))
    let erode = MPSImageErode(device: device, kernelWidth: 3, kernelHeight: 3, values: &zeros)
    erode.edgeMode = .zero
    erode.encode(commandBuffer: cmd, sourceImage: hot, destinationImage: erodeDest)
    precondition(mpsRead1(erodeDest)[4] == 0)
}

func testMPSImageScaleTransposeHistogramPixelExact() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let source = mpsUnormImage(device, width: 2, height: 1, pixels: [0, 255])
    let bilinearDest = mpsUnormImage(device, width: 4, height: 1, pixels: [1, 1, 1, 1])
    let bilinear = MPSImageBilinearScale(device: device)
    bilinear.edgeMode = .clamp
    bilinear.encode(commandBuffer: cmd, sourceImage: source, destinationImage: bilinearDest)
    let scaled = mpsRead1(bilinearDest)
    // srcX = (x+0.5)*0.5 - 0.5 → -0.25, 0.25, 0.75, 1.25 → 0, 64, 191, 255
    precondition(scaled == [0, 64, 191, 255])

    let lanczosDest = mpsUnormImage(device, width: 2, height: 1, pixels: [1, 1])
    let lanczos = MPSImageLanczosScale(device: device)
    lanczos.edgeMode = .clamp
    lanczos.encode(commandBuffer: cmd, sourceImage: source, destinationImage: lanczosDest)
    precondition(mpsRead1(lanczosDest) == [0, 255])

    let grid = mpsUnormImage(device, width: 2, height: 3, pixels: [1, 2, 3, 4, 5, 6])
    let transposed = mpsUnormImage(device, width: 3, height: 2, pixels: Array(repeating: 0, count: 6))
    MPSImageTranspose(device: device).encode(commandBuffer: cmd, sourceImage: grid, destinationImage: transposed)
    precondition(mpsRead1(transposed) == [1, 3, 5, 2, 4, 6])

    let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Unorm, width: 4, height: 1, mipmapped: false)
    let texture = device.makeTexture(descriptor: descriptor)
    let bytes = Data([0, 0, 255, 255])
    texture.bytes = bytes
    var info = MPSImageHistogramInfo()
    info.numberOfHistogramEntries = 4
    info.histogramForAlpha = ObjCBool(false)
    let histogram = MPSImageHistogram(device: device, histogramInfo: &info)
    let buffer = device.makeBuffer(length: histogram.histogramSize(forSourceFormat: .r8Unorm))
    histogram.encode(to: cmd, sourceTexture: texture, histogram: buffer, histogramOffset: 0)
    let counts = buffer.contents.bindMemory(to: UInt32.self, capacity: 16)
    precondition(counts[0] == 2)
    precondition(counts[3] == 2)

    let eq = MPSImageHistogramEqualization(device: device, histogramInfo: &info)
    eq.encodeTransform(to: cmd, sourceTexture: texture, histogram: buffer, histogramOffset: 0)
    let eqSrc = mpsUnormImage(device, width: 4, height: 1, pixels: [0, 0, 255, 255])
    let eqDest = mpsUnormImage(device, width: 4, height: 1, pixels: [9, 9, 9, 9])
    eq.encode(commandBuffer: cmd, sourceImage: eqSrc, destinationImage: eqDest)
    let equalized = mpsRead1(eqDest)
    precondition(equalized[0] == equalized[1])
    precondition(equalized[2] == 255 && equalized[3] == 255)
    precondition(equalized[0] < equalized[2])
}

func testMPSImageFeatureChannelLayout() {
    let device = MPSHostDevice.shared
    let image = MPSImage(
        device: device,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 2, height: 2, featureChannels: 3)
    )
    // CHW: C0=1,2,3,4  C1=5,6,7,8  C2=9,10,11,12
    let chw: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    chw.withUnsafeBytes { raw in
        image.writeBytes(raw.baseAddress!, dataLayout: .featureChannelsxHeightxWidth, imageIndex: 0)
    }
    var hwc = [UInt8](repeating: 0, count: 12)
    hwc.withUnsafeMutableBytes { raw in
        image.readBytes(raw.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0)
    }
    // pixel (0,0) = C0,C1,C2 = 1,5,9
    precondition(hwc[0] == 1 && hwc[1] == 5 && hwc[2] == 9)
    precondition(hwc[3] == 2 && hwc[4] == 6 && hwc[5] == 10)

    let cmd = device.makeCommandBuffer()
    let temporary = MPSTemporaryImage(
        commandBuffer: cmd,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 2, height: 2, featureChannels: 3)
    )
    precondition(temporary.readCount == 1)
    precondition(temporary.featureChannels == 3)
    chw.withUnsafeBytes { raw in
        temporary.writeBytes(raw.baseAddress!, dataLayout: .featureChannelsxHeightxWidth, imageIndex: 0)
    }
    var back = [UInt8](repeating: 0, count: 12)
    back.withUnsafeMutableBytes { raw in
        temporary.readBytes(raw.baseAddress!, dataLayout: .featureChannelsxHeightxWidth, imageIndex: 0)
    }
    precondition(back == chw)
}
