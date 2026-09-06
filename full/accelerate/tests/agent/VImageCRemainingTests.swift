import Accelerate
import Foundation

func testVImageCRemaining0() {
    var storage = [UInt8](repeating: 0, count: 64)
    var u8: UInt8 = 0
    var i8: Int8 = 0
    var u16: UInt16 = 0
    var i16: Int16 = 0
    var u32: UInt32 = 0
    var i32: Int32 = 0
    var u64: UInt64 = 0
    var f32: Float = 0
    var f64: Double = 0
    var chDesc = vImageChannelDescription()
    var optBufPtr: UnsafePointer<vImage_Buffer>? = nil
    var optBufPtr2: UnsafePointer<vImage_Buffer>? = nil
    var optRawPtr: UnsafeMutableRawPointer? = nil
    var optRawPtr2: UnsafeMutableRawPointer? = nil
    var optConstRawPtr: UnsafeRawPointer? = nil
    var pairFF: (Float, Float) = (0, 0)
    var pixelFFFF: Pixel_FFFF = (0, 0, 0, 0)
    var pixel8888: Pixel_8888 = (0, 0, 0, 0)
    var optFloatPtr: UnsafePointer<Float>? = nil
    var optFloatPtr2: UnsafePointer<Float>? = nil
    var optHistMut: UnsafeMutablePointer<vImagePixelCount>? = nil
    var optHistConst: UnsafePointer<vImagePixelCount>? = nil
    var aff = vImage_AffineTransform()
    var affD = vImage_AffineTransform_Double()
    var perp = vImage_PerpsectiveTransform()
    var argb2yp = vImage_ARGBToYpCbCr()
    var yp2argb = vImage_YpCbCrToARGB()
    var ypRange = vImage_YpCbCrPixelRange()
    var ypMat = vImage_YpCbCrToARGBMatrix()
    var argbMat = vImage_ARGBToYpCbCrMatrix()
    u8 += 0; i8 += 0; u16 += 0; i16 += 0; u32 += 0; i32 += 0; u64 += 0; f32 += 0; f64 += 0
    chDesc.zero += 0
    optBufPtr = nil; optBufPtr2 = nil; optRawPtr = nil; optRawPtr2 = nil
    optConstRawPtr = nil; optFloatPtr = nil; optFloatPtr2 = nil
    optHistMut = nil; optHistConst = nil
    pairFF.0 += 0; pixelFFFF.0 += 0; pixel8888.0 += 0
    _ = optBufPtr; _ = optBufPtr2; _ = optRawPtr; _ = optRawPtr2
    _ = optConstRawPtr; _ = optFloatPtr; _ = optFloatPtr2; _ = optHistMut; _ = optHistConst
    aff.a += 0; affD.a += 0; perp.a += 0
    ypRange.Yp_bias += 0; ypMat.Yp += 0; argbMat.R_Yp += 0
    let argb2ypCopy = argb2yp; argb2yp = argb2ypCopy
    let yp2argbCopy = yp2argb; yp2argb = yp2argbCopy
    storage.withUnsafeMutableBytes { sb in
        var buf = vImage_Buffer(data: sb.baseAddress, height: 2, width: 2, rowBytes: 8)
        _ = vImageAffineWarpD_ARGB16F(&buf, &buf, nil, &affD, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageAffineWarpD_Planar16F(&buf, &buf, nil, &affD, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageAffineWarp_Planar16F(&buf, &buf, nil, &aff, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageCVImageFormat_Copy(vImageConstCVImageFormat())
        _ = vImageCVImageFormat_CopyChannelDescription(vImageCVImageFormat(), &chDesc, 0)
        _ = vImageCVImageFormat_CopyConversionMatrix(vImageCVImageFormat(), sb.baseAddress!, 0)
        _ = vImageCVImageFormat_GetAlphaHint(vImageConstCVImageFormat())
        _ = vImageCVImageFormat_GetChannelCount(vImageConstCVImageFormat())
        _ = vImageCVImageFormat_GetChannelDescription(vImageConstCVImageFormat(), 0)
        _ = vImageCVImageFormat_GetChannelNames(vImageConstCVImageFormat())
        _ = vImageCVImageFormat_GetConversionMatrix(vImageConstCVImageFormat(), nil)
        _ = vImageCVImageFormat_GetFormatCode(vImageConstCVImageFormat())
        _ = vImageCVImageFormat_GetUserData(vImageConstCVImageFormat())
        _ = vImageCVImageFormat_SetAlphaHint(vImageCVImageFormat(), 0)
        _ = vImageCVImageFormat_SetUserData(vImageCVImageFormat(), nil, nil)
        _ = vImageConvert_420Yp8_Cb8_Cr8ToARGB8888(&buf, &buf, &buf, &buf, &yp2argb, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_420Yp8_CbCr8ToARGB8888(&buf, &buf, &buf, &yp2argb, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_422CbYpCrYp16ToARGB16U(&buf, &buf, &yp2argb, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_422CbYpCrYp16ToARGB8888(&buf, &buf, &yp2argb, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_422CbYpCrYp8ToARGB8888(&buf, &buf, &yp2argb, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_422CrYpCbYpCbYpCbYpCrYpCrYp10ToARGB16Q12(&buf, &buf, &yp2argb, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_422CrYpCbYpCbYpCbYpCrYpCrYp10ToARGB8888(&buf, &buf, &yp2argb, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_422YpCbYpCr8ToARGB8888(&buf, &buf, &yp2argb, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_444CrYpCb10ToARGB16Q12(&buf, &buf, &yp2argb, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_444CrYpCb10ToARGB8888(&buf, &buf, &yp2argb, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_444CrYpCb8ToARGB8888(&buf, &buf, &yp2argb, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB16UToARGB8888(&buf, &buf, &u8, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB8888ToARGB16U(&buf, &buf, &u8, 0, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB8888ToRGB16U(&buf, &buf, &u8, 0, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGBToYpCbCr_GenerateConversion(&argbMat, &ypRange, &argb2yp, vImageARGBType(rawValue: 0), vImageYpCbCrType(rawValue: 0), vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_AnyToAny(vImageConverter(), &buf, &buf, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ChunkyToPlanar8(&optConstRawPtr, &optBufPtr, 0, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ChunkyToPlanarF(&optConstRawPtr, &optBufPtr, 0, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Indexed1toPlanar8(&buf, &buf, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Indexed2toPlanar8(&buf, &buf, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Indexed4toPlanar8(&buf, &buf, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Planar8toIndexed1(&buf, &buf, nil, &u8, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Planar8toIndexed2(&buf, &buf, nil, &u8, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Planar8toIndexed4(&buf, &buf, nil, &u8, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Planar8toPlanar1(&buf, &buf, nil, 0, vImage_Flags(kvImageNoFlags))
    }
}

func testVImageCRemaining1() {
    var storage = [UInt8](repeating: 0, count: 64)
    var u8: UInt8 = 0
    var i8: Int8 = 0
    var u16: UInt16 = 0
    var i16: Int16 = 0
    var u32: UInt32 = 0
    var i32: Int32 = 0
    var u64: UInt64 = 0
    var f32: Float = 0
    var f64: Double = 0
    var chDesc = vImageChannelDescription()
    var optBufPtr: UnsafePointer<vImage_Buffer>? = nil
    var optBufPtr2: UnsafePointer<vImage_Buffer>? = nil
    var optRawPtr: UnsafeMutableRawPointer? = nil
    var optRawPtr2: UnsafeMutableRawPointer? = nil
    var optConstRawPtr: UnsafeRawPointer? = nil
    var pairFF: (Float, Float) = (0, 0)
    var pixelFFFF: Pixel_FFFF = (0, 0, 0, 0)
    var pixel8888: Pixel_8888 = (0, 0, 0, 0)
    var optFloatPtr: UnsafePointer<Float>? = nil
    var optFloatPtr2: UnsafePointer<Float>? = nil
    var optHistMut: UnsafeMutablePointer<vImagePixelCount>? = nil
    var optHistConst: UnsafePointer<vImagePixelCount>? = nil
    var aff = vImage_AffineTransform()
    var affD = vImage_AffineTransform_Double()
    var perp = vImage_PerpsectiveTransform()
    var argb2yp = vImage_ARGBToYpCbCr()
    var yp2argb = vImage_YpCbCrToARGB()
    var ypRange = vImage_YpCbCrPixelRange()
    var ypMat = vImage_YpCbCrToARGBMatrix()
    var argbMat = vImage_ARGBToYpCbCrMatrix()
    u8 += 0; i8 += 0; u16 += 0; i16 += 0; u32 += 0; i32 += 0; u64 += 0; f32 += 0; f64 += 0
    chDesc.zero += 0
    optBufPtr = nil; optBufPtr2 = nil; optRawPtr = nil; optRawPtr2 = nil
    optConstRawPtr = nil; optFloatPtr = nil; optFloatPtr2 = nil
    optHistMut = nil; optHistConst = nil
    pairFF.0 += 0; pixelFFFF.0 += 0; pixel8888.0 += 0
    _ = optBufPtr; _ = optBufPtr2; _ = optRawPtr; _ = optRawPtr2
    _ = optConstRawPtr; _ = optFloatPtr; _ = optFloatPtr2; _ = optHistMut; _ = optHistConst
    aff.a += 0; affD.a += 0; perp.a += 0
    ypRange.Yp_bias += 0; ypMat.Yp += 0; argbMat.R_Yp += 0
    let argb2ypCopy = argb2yp; argb2yp = argb2ypCopy
    let yp2argbCopy = yp2argb; yp2argb = yp2argbCopy
    storage.withUnsafeMutableBytes { sb in
        var buf = vImage_Buffer(data: sb.baseAddress, height: 2, width: 2, rowBytes: 8)
        _ = vImageConvert_PlanarToChunky8(&optBufPtr, &optRawPtr, 0, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_PlanarToChunkyF(&optBufPtr, &optRawPtr, 0, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGB16UToARGB8888(&buf, &buf, &u8, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGB16UtoARGB16U(&buf, nil, 0, &buf, false, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGB16UtoBGRA16U(&buf, nil, 0, &buf, false, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGB16UtoRGBA16U(&buf, nil, 0, &buf, false, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGBFFFtoRGB888_dithered(&buf, &buf, &f32, &f32, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_XRGB2101010ToARGB16Q12(&buf, 0, &buf, 0, 0, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_XRGB2101010ToARGB16U(&buf, 0, &buf, 0, 0, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_YpCbCrToARGB_GenerateConversion(&ypMat, &ypRange, &yp2argb, vImageYpCbCrType(rawValue: 0), vImageARGBType(rawValue: 0), vImage_Flags(kvImageNoFlags))
        _ = vImageConverter_GetDestinationBufferOrder(vImageConverter())
        _ = vImageConverter_GetNumberOfDestinationBuffers(vImageConverter())
        _ = vImageConverter_GetNumberOfSourceBuffers(vImageConverter())
        _ = vImageConverter_GetSourceBufferOrder(vImageConverter())
        _ = vImageConverter_MustOperateOutOfPlace(vImageConverter(), nil, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageConvolveMultiKernel_ARGB8888(&buf, &buf, nil, 0, 0, nil, 0, 0, nil, nil, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageConvolveMultiKernel_ARGBFFFF(&buf, &buf, nil, 0, 0, &optFloatPtr, 0, 0, &f32, &f32, vImage_Flags(kvImageNoFlags))
        _ = vImageConvolveWithBias_Planar16F(&buf, &buf, nil, 0, 0, nil, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvolve_Planar16F(&buf, &buf, nil, 0, 0, nil, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        vImageDestroyGammaFunction(nil)
        vImageDestroyResamplingFilter(nil)
        _ = vImageDilate_ARGB8888(&buf, &buf, 0, 0, &u8, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageFloodFill_Planar16U(&buf, nil, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageGetPerspectiveWarp(&pairFF, &pairFF, &perp, vImage_Flags(kvImageNoFlags))
        _ = vImageGetResamplingFilterExtent(sb.baseAddress!, vImage_Flags(kvImageNoFlags))
        _ = vImageGetResamplingFilterSize(0, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageHistogramCalculation_ARGB8888(&buf, &optHistMut, vImage_Flags(kvImageNoFlags))
        _ = vImageHistogramCalculation_ARGBFFFF(&buf, &optHistMut, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageHistogramSpecification_ARGB8888(&buf, &buf, &optHistConst, vImage_Flags(kvImageNoFlags))
        _ = vImageHistogramSpecification_ARGBFFFF(&buf, &buf, nil, nil, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShearD_Planar16F(&buf, &buf, 0, 0, 0, 0, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShear_Planar16F(&buf, &buf, 0, 0, 0, 0, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShear_Planar16S(&buf, &buf, 0, 0, 0, 0, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShear_Planar16U(&buf, &buf, 0, 0, 0, 0, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShear_XRGB2101010W(&buf, &buf, 0, 0, 0, 0, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageInterpolatedLookupTable_PlanarF(&buf, &buf, &f32, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageLookupTable_8to64U(&buf, &buf, &u64, vImage_Flags(kvImageNoFlags))
        _ = vImageLookupTable_Planar16(&buf, &buf, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageLookupTable_Planar8toPlanar128(&buf, &buf, &pixelFFFF, vImage_Flags(kvImageNoFlags))
        _ = vImageLookupTable_Planar8toPlanar16(&buf, &buf, &u16, vImage_Flags(kvImageNoFlags))
    }
}

func testVImageCRemaining2() {
    var storage = [UInt8](repeating: 0, count: 64)
    var u8: UInt8 = 0
    var i8: Int8 = 0
    var u16: UInt16 = 0
    var i16: Int16 = 0
    var u32: UInt32 = 0
    var i32: Int32 = 0
    var u64: UInt64 = 0
    var f32: Float = 0
    var f64: Double = 0
    var chDesc = vImageChannelDescription()
    var optBufPtr: UnsafePointer<vImage_Buffer>? = nil
    var optBufPtr2: UnsafePointer<vImage_Buffer>? = nil
    var optRawPtr: UnsafeMutableRawPointer? = nil
    var optRawPtr2: UnsafeMutableRawPointer? = nil
    var optConstRawPtr: UnsafeRawPointer? = nil
    var pairFF: (Float, Float) = (0, 0)
    var pixelFFFF: Pixel_FFFF = (0, 0, 0, 0)
    var pixel8888: Pixel_8888 = (0, 0, 0, 0)
    var optFloatPtr: UnsafePointer<Float>? = nil
    var optFloatPtr2: UnsafePointer<Float>? = nil
    var optHistMut: UnsafeMutablePointer<vImagePixelCount>? = nil
    var optHistConst: UnsafePointer<vImagePixelCount>? = nil
    var aff = vImage_AffineTransform()
    var affD = vImage_AffineTransform_Double()
    var perp = vImage_PerpsectiveTransform()
    var argb2yp = vImage_ARGBToYpCbCr()
    var yp2argb = vImage_YpCbCrToARGB()
    var ypRange = vImage_YpCbCrPixelRange()
    var ypMat = vImage_YpCbCrToARGBMatrix()
    var argbMat = vImage_ARGBToYpCbCrMatrix()
    u8 += 0; i8 += 0; u16 += 0; i16 += 0; u32 += 0; i32 += 0; u64 += 0; f32 += 0; f64 += 0
    chDesc.zero += 0
    optBufPtr = nil; optBufPtr2 = nil; optRawPtr = nil; optRawPtr2 = nil
    optConstRawPtr = nil; optFloatPtr = nil; optFloatPtr2 = nil
    optHistMut = nil; optHistConst = nil
    pairFF.0 += 0; pixelFFFF.0 += 0; pixel8888.0 += 0
    _ = optBufPtr; _ = optBufPtr2; _ = optRawPtr; _ = optRawPtr2
    _ = optConstRawPtr; _ = optFloatPtr; _ = optFloatPtr2; _ = optHistMut; _ = optHistConst
    aff.a += 0; affD.a += 0; perp.a += 0
    ypRange.Yp_bias += 0; ypMat.Yp += 0; argbMat.R_Yp += 0
    let argb2ypCopy = argb2yp; argb2yp = argb2ypCopy
    let yp2argbCopy = yp2argb; yp2argb = yp2argbCopy
    storage.withUnsafeMutableBytes { sb in
        var buf = vImage_Buffer(data: sb.baseAddress, height: 2, width: 2, rowBytes: 8)
        _ = vImageLookupTable_Planar8toPlanar48(&buf, &buf, &u64, vImage_Flags(kvImageNoFlags))
        _ = vImageLookupTable_Planar8toPlanar96(&buf, &buf, &pixelFFFF, vImage_Flags(kvImageNoFlags))
        _ = vImageLookupTable_Planar8toPlanarF(&buf, &buf, &f32, vImage_Flags(kvImageNoFlags))
        _ = vImageLookupTable_PlanarFtoPlanar8(&buf, &buf, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageMatrixMultiply_Planar16S(&optBufPtr, &optBufPtr2, 0, 0, &i16, 0, nil, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageMatrixMultiply_Planar8(&optBufPtr, &optBufPtr2, 0, 0, &i16, 0, nil, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageMatrixMultiply_PlanarF(&optBufPtr, &optBufPtr2, 0, 0, &f32, nil, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageMultiDimensionalInterpolatedLookupTable_Planar16Q12(&buf, &buf, nil, OpaquePointer(bitPattern: 1)!, kvImageNoInterpolation, vImage_Flags(kvImageNoFlags))
        _ = vImageMultiDimensionalInterpolatedLookupTable_PlanarF(&buf, &buf, nil, OpaquePointer(bitPattern: 1)!, kvImageNoInterpolation, vImage_Flags(kvImageNoFlags))
        _ = vImageMultidimensionalTable_Create(&u16, 0, 0, &u8, kvImageMDTableHint_Float, vImage_Flags(kvImageNoFlags), nil)
        _ = vImageMultidimensionalTable_Release(nil)
        _ = vImageNewResamplingFilterForFunctionUsingBuffer(sb.baseAddress!, 0, nil, 0, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageOverwriteChannelsWithPixel_ARGB16U(nil, &buf, &buf, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageOverwriteChannelsWithPixel_ARGB8888(nil, &buf, &buf, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageOverwriteChannelsWithPixel_ARGBFFFF(nil, &buf, &buf, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageOverwriteChannelsWithScalar_ARGB8888(0, &buf, &buf, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageOverwriteChannelsWithScalar_ARGBFFFF(0, &buf, &buf, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageOverwriteChannelsWithScalar_Planar16F(0, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageOverwriteChannelsWithScalar_Planar16S(0, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageOverwriteChannelsWithScalar_Planar16U(0, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageOverwriteChannels_ARGB8888(&buf, &buf, &buf, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageOverwriteChannels_ARGBFFFF(&buf, &buf, &buf, 0, vImage_Flags(kvImageNoFlags))
        _ = vImagePermuteChannelsWithMaskedInsert_ARGB16U(&buf, &buf, &u8, 0, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImagePermuteChannelsWithMaskedInsert_ARGB8888(&buf, &buf, &u8, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImagePermuteChannelsWithMaskedInsert_ARGBFFFF(&buf, &buf, &u8, 0, &f32, vImage_Flags(kvImageNoFlags))
        _ = vImagePerspectiveWarp_ARGB16F(&buf, &buf, nil, &perp, 0, nil, vImage_Flags(kvImageNoFlags))
        _ = vImagePerspectiveWarp_ARGB16U(&buf, &buf, nil, &perp, 0, nil, vImage_Flags(kvImageNoFlags))
        _ = vImagePerspectiveWarp_ARGB8888(&buf, &buf, nil, &perp, 0, nil, vImage_Flags(kvImageNoFlags))
        _ = vImagePerspectiveWarp_Planar16F(&buf, &buf, nil, &perp, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImagePerspectiveWarp_Planar16U(&buf, &buf, nil, &perp, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImagePerspectiveWarp_Planar8(&buf, &buf, nil, &perp, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImagePiecewiseGamma_Planar16Q12(&buf, &buf, &f32, 0, &f32, 0, vImage_Flags(kvImageNoFlags))
        _ = vImagePiecewiseGamma_Planar16Q12toPlanar8(&buf, &buf, &f32, 0, &f32, 0, vImage_Flags(kvImageNoFlags))
        _ = vImagePiecewisePolynomial_Planar8toPlanarF(&buf, &buf, &optFloatPtr, &f32, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImagePiecewisePolynomial_PlanarF(&buf, &buf, &optFloatPtr, &f32, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImagePiecewisePolynomial_PlanarFtoPlanar8(&buf, &buf, &optFloatPtr, &f32, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImagePiecewiseRational_PlanarF(&buf, &buf, &optFloatPtr, &optFloatPtr2, &f32, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageRotate90_ARGB16F(&buf, &buf, 0, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageRotate90_ARGB16S(&buf, &buf, 0, &i16, vImage_Flags(kvImageNoFlags))
        _ = vImageRotate90_ARGB16U(&buf, &buf, 0, &u16, vImage_Flags(kvImageNoFlags))
    }
}

func testVImageCRemaining3() {
    var storage = [UInt8](repeating: 0, count: 64)
    var u8: UInt8 = 0
    var i8: Int8 = 0
    var u16: UInt16 = 0
    var i16: Int16 = 0
    var u32: UInt32 = 0
    var i32: Int32 = 0
    var u64: UInt64 = 0
    var f32: Float = 0
    var f64: Double = 0
    var chDesc = vImageChannelDescription()
    var optBufPtr: UnsafePointer<vImage_Buffer>? = nil
    var optBufPtr2: UnsafePointer<vImage_Buffer>? = nil
    var optRawPtr: UnsafeMutableRawPointer? = nil
    var optRawPtr2: UnsafeMutableRawPointer? = nil
    var optConstRawPtr: UnsafeRawPointer? = nil
    var pairFF: (Float, Float) = (0, 0)
    var pixelFFFF: Pixel_FFFF = (0, 0, 0, 0)
    var pixel8888: Pixel_8888 = (0, 0, 0, 0)
    var optFloatPtr: UnsafePointer<Float>? = nil
    var optFloatPtr2: UnsafePointer<Float>? = nil
    var optHistMut: UnsafeMutablePointer<vImagePixelCount>? = nil
    var optHistConst: UnsafePointer<vImagePixelCount>? = nil
    var aff = vImage_AffineTransform()
    var affD = vImage_AffineTransform_Double()
    var perp = vImage_PerpsectiveTransform()
    var argb2yp = vImage_ARGBToYpCbCr()
    var yp2argb = vImage_YpCbCrToARGB()
    var ypRange = vImage_YpCbCrPixelRange()
    var ypMat = vImage_YpCbCrToARGBMatrix()
    var argbMat = vImage_ARGBToYpCbCrMatrix()
    u8 += 0; i8 += 0; u16 += 0; i16 += 0; u32 += 0; i32 += 0; u64 += 0; f32 += 0; f64 += 0
    chDesc.zero += 0
    optBufPtr = nil; optBufPtr2 = nil; optRawPtr = nil; optRawPtr2 = nil
    optConstRawPtr = nil; optFloatPtr = nil; optFloatPtr2 = nil
    optHistMut = nil; optHistConst = nil
    pairFF.0 += 0; pixelFFFF.0 += 0; pixel8888.0 += 0
    _ = optBufPtr; _ = optBufPtr2; _ = optRawPtr; _ = optRawPtr2
    _ = optConstRawPtr; _ = optFloatPtr; _ = optFloatPtr2; _ = optHistMut; _ = optHistConst
    aff.a += 0; affD.a += 0; perp.a += 0
    ypRange.Yp_bias += 0; ypMat.Yp += 0; argbMat.R_Yp += 0
    let argb2ypCopy = argb2yp; argb2yp = argb2ypCopy
    let yp2argbCopy = yp2argb; yp2argb = yp2argbCopy
    storage.withUnsafeMutableBytes { sb in
        var buf = vImage_Buffer(data: sb.baseAddress, height: 2, width: 2, rowBytes: 8)
        _ = vImageRotate90_ARGBFFFF(&buf, &buf, 0, &f32, vImage_Flags(kvImageNoFlags))
        _ = vImageRotate90_CbCr16F(&buf, &buf, 0, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageRotate90_Planar16F(&buf, &buf, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageRotate90_Planar16U(&buf, &buf, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageRotate90_PlanarF(&buf, &buf, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageRotate_Planar16F(&buf, &buf, nil, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageSelectChannels_ARGB8888(&buf, &buf, &buf, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageSelectChannels_ARGBFFFF(&buf, &buf, &buf, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageSepConvolve_Planar16F(&buf, &buf, nil, 0, 0, nil, 0, nil, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageSepConvolve_Planar16U(&buf, &buf, nil, 0, 0, nil, 0, nil, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageSepConvolve_Planar8(&buf, &buf, nil, 0, 0, nil, 0, nil, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageSymmetricPiecewiseGamma_Planar16Q12(&buf, &buf, &f32, 0, &f32, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageSymmetricPiecewisePolynomial_PlanarF(&buf, &buf, &optFloatPtr, &f32, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageTableLookUp_Planar8(&buf, &buf, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShearD_Planar16F(&buf, &buf, 0, 0, 0, 0, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShear_Planar16F(&buf, &buf, 0, 0, 0, 0, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShear_Planar16S(&buf, &buf, 0, 0, 0, 0, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShear_Planar16U(&buf, &buf, 0, 0, 0, 0, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShear_XRGB2101010W(&buf, &buf, 0, 0, 0, 0, nil, 0, vImage_Flags(kvImageNoFlags))
    }
}

