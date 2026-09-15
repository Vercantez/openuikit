import Accelerate
import Foundation

// Interleaved pixel-format structural audit: ComponentType aliases plus the
// format declarations themselves. All values are static structural facts, no
// Apple service behavior.

func testVImageInterleavedComponentTypes() {
    _ = vImage.Interleaved8x2.self
    _ = vImage.Interleaved8x2.ComponentType.self
    precondition(vImage.Interleaved8x2.channelCount == 2)
    _ = vImage.Interleaved8x3.self
    _ = vImage.Interleaved8x3.ComponentType.self
    precondition(vImage.Interleaved8x3.channelCount == 3)
    _ = vImage.Interleaved8x4.self
    _ = vImage.Interleaved8x4.ComponentType.self
    precondition(vImage.Interleaved8x4.channelCount == 4)
    _ = vImage.InterleavedFx2.self
    _ = vImage.InterleavedFx2.ComponentType.self
    precondition(vImage.InterleavedFx2.channelCount == 2)
    _ = vImage.InterleavedFx3.self
    _ = vImage.InterleavedFx3.ComponentType.self
    precondition(vImage.InterleavedFx3.channelCount == 3)
    _ = vImage.InterleavedFx4.ComponentType.self
    precondition(vImage.InterleavedFx4.channelCount == 4)
    _ = vImage.Interleaved16Fx2.self
    _ = vImage.Interleaved16Fx2.ComponentType.self
    precondition(vImage.Interleaved16Fx2.channelCount == 2)
    _ = vImage.Interleaved16Fx4.self
    _ = vImage.Interleaved16Fx4.ComponentType.self
    precondition(vImage.Interleaved16Fx4.channelCount == 4)
    _ = vImage.Interleaved16Ux2.self
    _ = vImage.Interleaved16Ux2.ComponentType.self
    precondition(vImage.Interleaved16Ux2.channelCount == 2)
    _ = vImage.Interleaved16Ux4.self
    _ = vImage.Interleaved16Ux4.ComponentType.self
    precondition(vImage.Interleaved16Ux4.channelCount == 4)
    // Pin the alias targets without inventing behavior.
    precondition(vImage.Interleaved8x2.ComponentType.self == Pixel_8.self)
    precondition(vImage.InterleavedFx2.ComponentType.self == Pixel_F.self)
    precondition(vImage.Interleaved16Fx2.ComponentType.self == Pixel_16F.self)
    precondition(vImage.Interleaved16Ux2.ComponentType.self == Pixel_16U.self)
}

func testVImagePlanarComponentTypes() {
    _ = vImage.Planar8.ComponentType.self
    precondition(vImage.Planar8.channelCount == 1)
    _ = vImage.PlanarF.ComponentType.self
    precondition(vImage.PlanarF.channelCount == 1)
    _ = vImage.Planar16F.self
    _ = vImage.Planar16F.ComponentType.self
    precondition(vImage.Planar16F.ComponentType.self == Pixel_16F.self)
    _ = vImage.Planar16U.self
    _ = vImage.Planar16U.ComponentType.self
    precondition(vImage.Planar16U.ComponentType.self == Pixel_16U.self)
    _ = vImage.Planar8x2.ComponentType.self
    _ = vImage.Planar8x2.PlanarPixelFormat.self
    precondition(vImage.Planar8x2.planeCount == 2)
    _ = vImage.Planar8x3.ComponentType.self
    _ = vImage.Planar8x3.PlanarPixelFormat.self
    precondition(vImage.Planar8x3.planeCount == 3)
    _ = vImage.Planar8x4.ComponentType.self
    _ = vImage.Planar8x4.PlanarPixelFormat.self
    precondition(vImage.Planar8x4.planeCount == 4)
    _ = vImage.PlanarFx2.PlanarPixelFormat.self
    _ = vImage.PlanarFx2.ComponentType.self
    precondition(vImage.PlanarFx2.planeCount == 2)
    _ = vImage.PlanarFx3.PlanarPixelFormat.self
    _ = vImage.PlanarFx3.ComponentType.self
    precondition(vImage.PlanarFx3.planeCount == 3)
    _ = vImage.PlanarFx4.PlanarPixelFormat.self
    _ = vImage.PlanarFx4.ComponentType.self
    precondition(vImage.PlanarFx4.planeCount == 4)
    _ = vImage.DynamicPixelFormat.self
    _ = vImage.DynamicPixelFormat.ComponentType.self
    _ = vImage.StructuringElement<UInt8>.self
    precondition(vImage.Planar8.ComponentType.self == Pixel_8.self)
    precondition(vImage.PlanarF.ComponentType.self == Pixel_F.self)
}

func testVImageKernelSizeOptions() {
    _ = vImage.ConvolutionKernel2D<UInt8>.self
    let k1 = vImage.ConvolutionKernel2D<UInt8>(values: [1, 2, 3, 4], size: vImage.Size(width: 2, height: 2))
    precondition(k1.width == 2 && k1.height == 2 && k1.values == [1, 2, 3, 4])
    let k2 = vImage.ConvolutionKernel2D<UInt8>(values: [1, 2, 3, 4], width: 2, height: 2)
    precondition(k2.width == 2 && k2.height == 2 && k2.values == [1, 2, 3, 4])
    let sz = vImage.Size(width: 2, height: 3)
    precondition(sz.width == 2 && sz.height == 3)
    _ = vImage.Options.Element.self
    _ = vImage.Options.ArrayLiteralElement.self
    _ = vImage.Options.RawValue.self
    let opts: vImage.Options = [.noFlags, .imageExtend]
    precondition(opts.contains(.imageExtend))
    precondition(vImage.Error.RawValue.self == Int.self)
    precondition(vImage.Error.noError.rawValue == 0)
    _ = vImage.PixelBuffer<vImage.Planar8>.Element.self
    _ = vImage.PixelBuffer<vImage.Planar8>.Histogram888.self
    _ = vImage.PixelBuffer<vImage.Planar8>.Histogram8888.self
    _ = vImage.PixelBuffer<vImage.PlanarF>.HistogramFFF.self
    _ = vImage.PixelBuffer<vImage.PlanarF>.HistogramFFFF.self
    let pb = vImage.PixelBuffer<vImage.Planar8>(pixelValues: [1, 2, 3, 4], size: sz)
    let h: vImage.PixelBuffer<vImage.Planar8>.Histogram888 = ([1], [2], [3])
    precondition(h.0 == [1])
    _ = pb
}

// Apple-measured vImage gamma/matrix constants (macOS 26.1 / Xcode 26.1,
// `xcrun swiftc` probe 2026-09-15: g11o9=8 g5o11=4 g5o9=2 g9o11=9 g9o5=3
// bt709f=10 bt709r=11 srgbF=6 srgbR=7 mtxARGB=1 mtxNone=0). Table-driven
// constant sharing is permitted by the contract.

func testOraclePinnedVImageGammaMatrix() {
    precondition(kvImageGamma_11_over_9_half_precision == 8)
    precondition(kvImageGamma_5_over_11_half_precision == 4)
    precondition(kvImageGamma_5_over_9_half_precision == 2)
    precondition(kvImageGamma_9_over_11_half_precision == 9)
    precondition(kvImageGamma_9_over_5_half_precision == 3)
    precondition(kvImageGamma_BT709_forward_half_precision == 10)
    precondition(kvImageGamma_BT709_reverse_half_precision == 11)
    precondition(kvImageGamma_sRGB_forward_half_precision == 6)
    precondition(kvImageGamma_sRGB_reverse_half_precision == 7)
    precondition(kvImageMatrixType_ARGBToYpCbCrMatrix == 1)
    precondition(kvImageMatrixType_None == 0)
}
