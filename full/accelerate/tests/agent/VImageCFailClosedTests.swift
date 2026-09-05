import Accelerate
import Foundation

func testVImageCFailClosed0() {
    var storage = [UInt8](repeating: 0, count: 64)
    var u8: UInt8 = 0
    var i8: Int8 = 0
    var u16: UInt16 = 0
    var i16: Int16 = 0
    var u32: UInt32 = 0
    var i32: Int32 = 0
    var f32: Float = 0
    var f64: Double = 0
    var aff = vImage_AffineTransform()
    var affD = vImage_AffineTransform_Double()
    var argb2yp = vImage_ARGBToYpCbCr()
    var yp2argb = vImage_YpCbCrToARGB()
    var ypRange = vImage_YpCbCrPixelRange()
    var ypMat = vImage_YpCbCrToARGBMatrix()
    var argbMat = vImage_ARGBToYpCbCrMatrix()
    u8 += 0; i8 += 0; u16 += 0; i16 += 0; u32 += 0; i32 += 0; f32 += 0; f64 += 0
    aff.a += 0; affD.a += 0
    let argb2ypCopy = argb2yp
    argb2yp = argb2ypCopy
    let yp2argbCopy = yp2argb
    yp2argb = yp2argbCopy
    ypRange.Yp_bias += 0
    ypMat.Yp += 0
    argbMat.R_Yp += 0
    storage.withUnsafeMutableBytes { sb in
        var buf = vImage_Buffer(data: sb.baseAddress, height: 2, width: 2, rowBytes: 8)

        _ = vImageAffineWarpD_ARGB16S(&buf, &buf, nil, &affD, &i16, vImage_Flags(kvImageNoFlags))
        _ = vImageAffineWarpD_ARGB16U(&buf, &buf, nil, &affD, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageAffineWarpD_ARGB8888(&buf, &buf, nil, &affD, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageAffineWarpD_ARGBFFFF(&buf, &buf, nil, &affD, &f32, vImage_Flags(kvImageNoFlags))
        _ = vImageAffineWarpD_CbCr16F(&buf, &buf, nil, &affD, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageAffineWarpD_Planar8(&buf, &buf, nil, &affD, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageAffineWarpD_PlanarF(&buf, &buf, nil, &affD, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageAffineWarp_ARGB16F(&buf, &buf, nil, &aff, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageAffineWarp_ARGB16S(&buf, &buf, nil, &aff, &i16, vImage_Flags(kvImageNoFlags))
        _ = vImageAffineWarp_ARGB16U(&buf, &buf, nil, &aff, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageAffineWarp_ARGB8888(&buf, &buf, nil, &aff, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageAffineWarp_ARGBFFFF(&buf, &buf, nil, &aff, &f32, vImage_Flags(kvImageNoFlags))
        _ = vImageAffineWarp_CbCr16F(&buf, &buf, nil, &aff, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageAffineWarp_Planar8(&buf, &buf, nil, &aff, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageAffineWarp_PlanarF(&buf, &buf, nil, &aff, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageAlphaBlend_ARGBFFFF(&buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageAlphaBlend_NonpremultipliedToPremultiplied_ARGB8888(&buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageAlphaBlend_NonpremultipliedToPremultiplied_ARGBFFFF(&buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageAlphaBlend_NonpremultipliedToPremultiplied_Planar8(&buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageAlphaBlend_NonpremultipliedToPremultiplied_PlanarF(&buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageAlphaBlend_Planar8(&buf, &buf, &buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageAlphaBlend_PlanarF(&buf, &buf, &buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageBufferFill_ARGB16F(&buf, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageBufferFill_ARGB16S(&buf, &i16, vImage_Flags(kvImageNoFlags))
        _ = vImageBufferFill_ARGB16U(&buf, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageBufferFill_ARGBFFFF(&buf, &f32, vImage_Flags(kvImageNoFlags))
        _ = vImageBufferFill_CbCr16S(&buf, &i16, vImage_Flags(kvImageNoFlags))
        _ = vImageBufferFill_CbCr16U(&buf, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageClipToAlpha_Planar8(&buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageClipToAlpha_PlanarF(&buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageClip_PlanarF(&buf, &buf, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageContrastStretch_ARGBFFFF(&buf, &buf, nil, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageContrastStretch_PlanarF(&buf, &buf, nil, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_16SToF(&buf, &buf, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_16UToF(&buf, &buf, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_422CbYpCrYp8_AA8ToARGB8888(&buf, &buf, &buf, &yp2argb, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_444AYpCbCr16ToARGB16U(&buf, &buf, &yp2argb, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_444AYpCbCr16ToARGB8888(&buf, &buf, &yp2argb, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_444AYpCbCr8ToARGB8888(&buf, &buf, &yp2argb, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_444CbYpCrA8ToARGB8888(&buf, &buf, &yp2argb, &u8, vImage_Flags(kvImageNoFlags))
    }
}

func testVImageCFailClosed1() {
    var storage = [UInt8](repeating: 0, count: 64)
    var u8: UInt8 = 0
    var i8: Int8 = 0
    var u16: UInt16 = 0
    var i16: Int16 = 0
    var u32: UInt32 = 0
    var i32: Int32 = 0
    var f32: Float = 0
    var f64: Double = 0
    var aff = vImage_AffineTransform()
    var affD = vImage_AffineTransform_Double()
    var argb2yp = vImage_ARGBToYpCbCr()
    var yp2argb = vImage_YpCbCrToARGB()
    var ypRange = vImage_YpCbCrPixelRange()
    var ypMat = vImage_YpCbCrToARGBMatrix()
    var argbMat = vImage_ARGBToYpCbCrMatrix()
    u8 += 0; i8 += 0; u16 += 0; i16 += 0; u32 += 0; i32 += 0; f32 += 0; f64 += 0
    aff.a += 0; affD.a += 0
    let argb2ypCopy = argb2yp
    argb2yp = argb2ypCopy
    let yp2argbCopy = yp2argb
    yp2argb = yp2argbCopy
    ypRange.Yp_bias += 0
    ypMat.Yp += 0
    argbMat.R_Yp += 0
    storage.withUnsafeMutableBytes { sb in
        var buf = vImage_Buffer(data: sb.baseAddress, height: 2, width: 2, rowBytes: 8)

        _ = vImageConvert_ARGB1555toPlanar8(&buf, &buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB16Q12To422CrYpCbYpCbYpCbYpCrYpCrYp10(&buf, &buf, &argb2yp, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB16Q12To444CrYpCb10(&buf, &buf, &argb2yp, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB16Q12ToARGB2101010(&buf, &buf, 0, 0, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB16Q12ToRGBA1010102(&buf, &buf, 0, 0, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB16Q12ToXRGB2101010(&buf, &buf, 0, 0, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB16UTo422CbYpCrYp16(&buf, &buf, &argb2yp, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB16UTo444AYpCbCr16(&buf, &buf, &argb2yp, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB16UToARGB2101010(&buf, &buf, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB16UToRGBA1010102(&buf, &buf, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB16UToXRGB2101010(&buf, &buf, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB16UtoARGB8888_dithered(&buf, &buf, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB16UtoPlanar16U(&buf, &buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB16UtoRGB16U(&buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB2101010ToARGB16F(&buf, &buf, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB2101010ToARGB16Q12(&buf, &buf, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB2101010ToARGB16U(&buf, &buf, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB2101010ToARGB8888(&buf, &buf, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB2101010ToARGBFFFF(&buf, &buf, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB8888To420Yp8_Cb8_Cr8(&buf, &buf, &buf, &buf, &argb2yp, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB8888To420Yp8_CbCr8(&buf, &buf, &buf, &argb2yp, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB8888To422CbYpCrYp16(&buf, &buf, &argb2yp, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB8888To422CbYpCrYp8(&buf, &buf, &argb2yp, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB8888To422CbYpCrYp8_AA8(&buf, &buf, &buf, &argb2yp, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB8888To422CrYpCbYpCbYpCbYpCrYpCrYp10(&buf, &buf, &argb2yp, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB8888To422YpCbYpCr8(&buf, &buf, &argb2yp, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB8888To444AYpCbCr16(&buf, &buf, &argb2yp, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB8888To444AYpCbCr8(&buf, &buf, &argb2yp, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB8888To444CbYpCrA8(&buf, &buf, &argb2yp, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB8888To444CrYpCb10(&buf, &buf, &argb2yp, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB8888To444CrYpCb8(&buf, &buf, &argb2yp, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB8888ToARGB2101010(&buf, &buf, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB8888ToRGBA1010102(&buf, &buf, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB8888ToXRGB2101010(&buf, &buf, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB8888toARGB1555_dithered(&buf, &buf, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB8888toPlanar16Q12(&buf, &buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB8888toPlanarF(&buf, &buf, &buf, &buf, &buf, &f32, &f32, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB8888toRGB565_dithered(&buf, &buf, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGB8888toRGB888(&buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGBFFFFToARGB2101010(&buf, &buf, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
    }
}

func testVImageCFailClosed2() {
    var storage = [UInt8](repeating: 0, count: 64)
    var u8: UInt8 = 0
    var i8: Int8 = 0
    var u16: UInt16 = 0
    var i16: Int16 = 0
    var u32: UInt32 = 0
    var i32: Int32 = 0
    var f32: Float = 0
    var f64: Double = 0
    var aff = vImage_AffineTransform()
    var affD = vImage_AffineTransform_Double()
    var argb2yp = vImage_ARGBToYpCbCr()
    var yp2argb = vImage_YpCbCrToARGB()
    var ypRange = vImage_YpCbCrPixelRange()
    var ypMat = vImage_YpCbCrToARGBMatrix()
    var argbMat = vImage_ARGBToYpCbCrMatrix()
    u8 += 0; i8 += 0; u16 += 0; i16 += 0; u32 += 0; i32 += 0; f32 += 0; f64 += 0
    aff.a += 0; affD.a += 0
    let argb2ypCopy = argb2yp
    argb2yp = argb2ypCopy
    let yp2argbCopy = yp2argb
    yp2argb = yp2argbCopy
    ypRange.Yp_bias += 0
    ypMat.Yp += 0
    argbMat.R_Yp += 0
    storage.withUnsafeMutableBytes { sb in
        var buf = vImage_Buffer(data: sb.baseAddress, height: 2, width: 2, rowBytes: 8)

        _ = vImageConvert_ARGBFFFFToXRGB2101010(&buf, &buf, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGBFFFFtoARGB8888_dithered(&buf, &buf, &f32, &f32, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGBFFFFtoPlanar8(&buf, &buf, &buf, &buf, &buf, &f32, &f32, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGBFFFFtoPlanarF(&buf, &buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_ARGBFFFFtoRGBFFF(&buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_BGRA16UtoRGB16U(&buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_BGRA8888toRGB565_dithered(&buf, &buf, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_BGRA8888toRGB888(&buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_BGRAFFFFtoRGBFFF(&buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_BGRX8888ToPlanar8(&buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_BGRXFFFFToPlanarF(&buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_FTo16S(&buf, &buf, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_FTo16U(&buf, &buf, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Planar16Q12toARGB16F(&buf, &buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Planar16Q12toARGB8888(&buf, &buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Planar16Q12toRGB16F(&buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Planar16Q12toRGB888(&buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Planar16UtoARGB16U(&buf, &buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Planar16UtoPlanar8_dithered(&buf, &buf, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Planar16UtoRGB16U(&buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Planar8ToARGBFFFF(&buf, &buf, &buf, &buf, &buf, &f32, &f32, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Planar8ToBGRX8888(&buf, &buf, &buf, 0, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Planar8ToBGRXFFFF(&buf, &buf, &buf, 0, &buf, &f32, &f32, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Planar8ToXRGB8888(0, &buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Planar8ToXRGBFFFF(0, &buf, &buf, &buf, &buf, &f32, &f32, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Planar8toARGB1555(&buf, &buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Planar8toPlanar2(&buf, &buf, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Planar8toPlanar4(&buf, &buf, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Planar8toRGB565(&buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_Planar8toRGB888(&buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_PlanarFToARGB8888(&buf, &buf, &buf, &buf, &buf, &f32, &f32, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_PlanarFToBGRX8888(&buf, &buf, &buf, 0, &buf, &f32, &f32, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_PlanarFToBGRXFFFF(&buf, &buf, &buf, 0, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_PlanarFToXRGB8888(0, &buf, &buf, &buf, &buf, &f32, &f32, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_PlanarFToXRGBFFFF(0, &buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_PlanarFtoARGBFFFF(&buf, &buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_PlanarFtoPlanar8_dithered(&buf, &buf, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_PlanarFtoRGBFFF(&buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGB16UtoPlanar16U(&buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGB16UtoRGB888_dithered(&buf, &buf, 0, vImage_Flags(kvImageNoFlags))
    }
}

func testVImageCFailClosed3() {
    var storage = [UInt8](repeating: 0, count: 64)
    var u8: UInt8 = 0
    var i8: Int8 = 0
    var u16: UInt16 = 0
    var i16: Int16 = 0
    var u32: UInt32 = 0
    var i32: Int32 = 0
    var f32: Float = 0
    var f64: Double = 0
    var aff = vImage_AffineTransform()
    var affD = vImage_AffineTransform_Double()
    var argb2yp = vImage_ARGBToYpCbCr()
    var yp2argb = vImage_YpCbCrToARGB()
    var ypRange = vImage_YpCbCrPixelRange()
    var ypMat = vImage_YpCbCrToARGBMatrix()
    var argbMat = vImage_ARGBToYpCbCrMatrix()
    u8 += 0; i8 += 0; u16 += 0; i16 += 0; u32 += 0; i32 += 0; f32 += 0; f64 += 0
    aff.a += 0; affD.a += 0
    let argb2ypCopy = argb2yp
    argb2yp = argb2ypCopy
    let yp2argbCopy = yp2argb
    yp2argb = yp2argbCopy
    ypRange.Yp_bias += 0
    ypMat.Yp += 0
    argbMat.R_Yp += 0
    storage.withUnsafeMutableBytes { sb in
        var buf = vImage_Buffer(data: sb.baseAddress, height: 2, width: 2, rowBytes: 8)

        _ = vImageConvert_RGB565toARGB1555(&buf, &buf, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGB565toARGB8888(0, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGB565toBGRA8888(0, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGB565toPlanar8(&buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGB565toRGBA5551(&buf, &buf, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGB565toRGBA8888(0, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGB888toARGB8888(&buf, &buf, 0, &buf, false, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGB888toBGRA8888(&buf, &buf, 0, &buf, false, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGB888toPlanar16Q12(&buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGB888toPlanar8(&buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGB888toRGB565_dithered(&buf, &buf, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGB888toRGBA8888(&buf, &buf, 0, &buf, false, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGBA1010102ToARGB16Q12(&buf, &buf, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGBA1010102ToARGB16U(&buf, &buf, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGBA1010102ToARGB8888(&buf, &buf, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGBA16UtoRGB16U(&buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGBA8888toRGB565_dithered(&buf, &buf, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGBA8888toRGB888(&buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGBA8888toRGBA5551_dithered(&buf, &buf, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGBAFFFFtoRGBFFF(&buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGBFFFtoARGBFFFF(&buf, &buf, 0, &buf, false, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGBFFFtoBGRAFFFF(&buf, &buf, 0, &buf, false, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGBFFFtoPlanarF(&buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_RGBFFFtoRGBAFFFF(&buf, &buf, 0, &buf, false, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_XRGB2101010ToARGB16F(&buf, 0, &buf, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_XRGB2101010ToARGB8888(&buf, 0, &buf, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_XRGB2101010ToARGBFFFF(&buf, 0, &buf, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_XRGB8888ToPlanar8(&buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvert_XRGBFFFFToPlanarF(&buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageConvolveFloatKernel_ARGB8888(&buf, &buf, nil, 0, 0, &f32, 0, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvolveWithBias_ARGB16F(&buf, &buf, nil, 0, 0, &f32, 0, 0, 0, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageConvolveWithBias_ARGB8888(&buf, &buf, nil, 0, 0, &i16, 0, 0, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvolveWithBias_ARGBFFFF(&buf, &buf, nil, 0, 0, &f32, 0, 0, 0, &f32, vImage_Flags(kvImageNoFlags))
        _ = vImageConvolveWithBias_Planar8(&buf, &buf, nil, 0, 0, &i16, 0, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvolveWithBias_PlanarF(&buf, &buf, nil, 0, 0, &f32, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvolve_ARGB16F(&buf, &buf, nil, 0, 0, &f32, 0, 0, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageConvolve_ARGB8888(&buf, &buf, nil, 0, 0, &i16, 0, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageConvolve_ARGBFFFF(&buf, &buf, nil, 0, 0, &f32, 0, 0, &f32, vImage_Flags(kvImageNoFlags))
        _ = vImageConvolve_Planar8(&buf, &buf, nil, 0, 0, &i16, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageConvolve_PlanarF(&buf, &buf, nil, 0, 0, &f32, 0, 0, 0, vImage_Flags(kvImageNoFlags))
    }
}

func testVImageCFailClosed4() {
    var storage = [UInt8](repeating: 0, count: 64)
    var u8: UInt8 = 0
    var i8: Int8 = 0
    var u16: UInt16 = 0
    var i16: Int16 = 0
    var u32: UInt32 = 0
    var i32: Int32 = 0
    var f32: Float = 0
    var f64: Double = 0
    var aff = vImage_AffineTransform()
    var affD = vImage_AffineTransform_Double()
    var argb2yp = vImage_ARGBToYpCbCr()
    var yp2argb = vImage_YpCbCrToARGB()
    var ypRange = vImage_YpCbCrPixelRange()
    var ypMat = vImage_YpCbCrToARGBMatrix()
    var argbMat = vImage_ARGBToYpCbCrMatrix()
    u8 += 0; i8 += 0; u16 += 0; i16 += 0; u32 += 0; i32 += 0; f32 += 0; f64 += 0
    aff.a += 0; affD.a += 0
    let argb2ypCopy = argb2yp
    argb2yp = argb2ypCopy
    let yp2argbCopy = yp2argb
    yp2argb = yp2argbCopy
    ypRange.Yp_bias += 0
    ypMat.Yp += 0
    argbMat.R_Yp += 0
    storage.withUnsafeMutableBytes { sb in
        var buf = vImage_Buffer(data: sb.baseAddress, height: 2, width: 2, rowBytes: 8)

        _ = vImageCreateGammaFunction(0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageDilate_ARGBFFFF(&buf, &buf, 0, 0, &f32, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageDilate_Planar8(&buf, &buf, 0, 0, &u8, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageDilate_PlanarF(&buf, &buf, 0, 0, &f32, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageEndsInContrastStretch_ARGB8888(&buf, &buf, &u32, &u32, vImage_Flags(kvImageNoFlags))
        _ = vImageEndsInContrastStretch_ARGBFFFF(&buf, &buf, nil, &u32, &u32, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageEndsInContrastStretch_Planar8(&buf, &buf, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageEndsInContrastStretch_PlanarF(&buf, &buf, nil, 0, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageEqualization_ARGBFFFF(&buf, &buf, nil, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageEqualization_PlanarF(&buf, &buf, nil, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageErode_ARGB8888(&buf, &buf, 0, 0, &u8, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageErode_ARGBFFFF(&buf, &buf, 0, 0, &f32, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageErode_Planar8(&buf, &buf, 0, 0, &u8, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageErode_PlanarF(&buf, &buf, 0, 0, &f32, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageExtractChannel_ARGB16U(&buf, &buf, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageExtractChannel_ARGB8888(&buf, &buf, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageExtractChannel_ARGBFFFF(&buf, &buf, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageFlatten_ARGB16Q12(&buf, &buf, &i16, false, vImage_Flags(kvImageNoFlags))
        _ = vImageFlatten_ARGB16U(&buf, &buf, &u16, false, vImage_Flags(kvImageNoFlags))
        _ = vImageFlatten_ARGB8888(&buf, &buf, &u8, false, vImage_Flags(kvImageNoFlags))
        _ = vImageFlatten_ARGB8888ToRGB888(&buf, &buf, &u8, false, vImage_Flags(kvImageNoFlags))
        _ = vImageFlatten_ARGBFFFF(&buf, &buf, &f32, false, vImage_Flags(kvImageNoFlags))
        _ = vImageFlatten_ARGBFFFFToRGBFFF(&buf, &buf, &f32, false, vImage_Flags(kvImageNoFlags))
        _ = vImageFlatten_BGRA8888ToRGB888(&buf, &buf, &u8, false, vImage_Flags(kvImageNoFlags))
        _ = vImageFlatten_BGRAFFFFToRGBFFF(&buf, &buf, &f32, false, vImage_Flags(kvImageNoFlags))
        _ = vImageFlatten_RGBA16Q12(&buf, &buf, &i16, false, vImage_Flags(kvImageNoFlags))
        _ = vImageFlatten_RGBA16U(&buf, &buf, &u16, false, vImage_Flags(kvImageNoFlags))
        _ = vImageFlatten_RGBA8888(&buf, &buf, &u8, false, vImage_Flags(kvImageNoFlags))
        _ = vImageFlatten_RGBA8888ToRGB888(&buf, &buf, &u8, false, vImage_Flags(kvImageNoFlags))
        _ = vImageFlatten_RGBAFFFF(&buf, &buf, &f32, false, vImage_Flags(kvImageNoFlags))
        _ = vImageFlatten_RGBAFFFFToRGBFFF(&buf, &buf, &f32, false, vImage_Flags(kvImageNoFlags))
        _ = vImageFloodFill_ARGB16U(&buf, nil, 0, 0, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageFloodFill_ARGB8888(&buf, nil, 0, 0, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageFloodFill_Planar8(&buf, nil, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageGamma_Planar8toPlanarF(&buf, &buf, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageGamma_PlanarF(&buf, &buf, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageGamma_PlanarFtoPlanar8(&buf, &buf, nil, vImage_Flags(kvImageNoFlags))
        var histEntries: vImagePixelCount = 0
        _ = vImageHistogramCalculation_PlanarF(&buf, &histEntries, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageHistogramSpecification_Planar8(&buf, &buf, &histEntries, vImage_Flags(kvImageNoFlags))
        _ = vImageHistogramSpecification_PlanarF(&buf, &buf, nil, &histEntries, 0, 0, 0, vImage_Flags(kvImageNoFlags))
    }
}

func testVImageCFailClosed5() {
    var storage = [UInt8](repeating: 0, count: 64)
    var u8: UInt8 = 0
    var i8: Int8 = 0
    var u16: UInt16 = 0
    var i16: Int16 = 0
    var u32: UInt32 = 0
    var i32: Int32 = 0
    var f32: Float = 0
    var f64: Double = 0
    var aff = vImage_AffineTransform()
    var affD = vImage_AffineTransform_Double()
    var argb2yp = vImage_ARGBToYpCbCr()
    var yp2argb = vImage_YpCbCrToARGB()
    var ypRange = vImage_YpCbCrPixelRange()
    var ypMat = vImage_YpCbCrToARGBMatrix()
    var argbMat = vImage_ARGBToYpCbCrMatrix()
    u8 += 0; i8 += 0; u16 += 0; i16 += 0; u32 += 0; i32 += 0; f32 += 0; f64 += 0
    aff.a += 0; affD.a += 0
    let argb2ypCopy = argb2yp
    argb2yp = argb2ypCopy
    let yp2argbCopy = yp2argb
    yp2argb = yp2argbCopy
    ypRange.Yp_bias += 0
    ypMat.Yp += 0
    argbMat.R_Yp += 0
    storage.withUnsafeMutableBytes { sb in
        var buf = vImage_Buffer(data: sb.baseAddress, height: 2, width: 2, rowBytes: 8)

        _ = vImageHorizontalShearD_ARGB16F(&buf, &buf, 0, 0, 0, 0, nil, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShearD_ARGB16S(&buf, &buf, 0, 0, 0, 0, nil, &i16, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShearD_ARGB16U(&buf, &buf, 0, 0, 0, 0, nil, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShearD_ARGB8888(&buf, &buf, 0, 0, 0, 0, nil, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShearD_ARGBFFFF(&buf, &buf, 0, 0, 0, 0, nil, &f32, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShearD_CbCr16F(&buf, &buf, 0, 0, 0, 0, nil, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShearD_CbCr16S(&buf, &buf, 0, 0, 0, 0, nil, &i16, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShearD_CbCr16U(&buf, &buf, 0, 0, 0, 0, nil, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShearD_Planar8(&buf, &buf, 0, 0, 0, 0, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShearD_PlanarF(&buf, &buf, 0, 0, 0, 0, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShear_ARGB16F(&buf, &buf, 0, 0, 0, 0, nil, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShear_ARGB16S(&buf, &buf, 0, 0, 0, 0, nil, &i16, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShear_ARGB16U(&buf, &buf, 0, 0, 0, 0, nil, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShear_ARGB8888(&buf, &buf, 0, 0, 0, 0, nil, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShear_ARGBFFFF(&buf, &buf, 0, 0, 0, 0, nil, &f32, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShear_CbCr16F(&buf, &buf, 0, 0, 0, 0, nil, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShear_CbCr16S(&buf, &buf, 0, 0, 0, 0, nil, &i16, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShear_CbCr16U(&buf, &buf, 0, 0, 0, 0, nil, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShear_CbCr8(&buf, &buf, 0, 0, 0, 0, nil, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShear_Planar8(&buf, &buf, 0, 0, 0, 0, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalShear_PlanarF(&buf, &buf, 0, 0, 0, 0, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageLookupTable_Planar8toPlanar24(&buf, &buf, &u32, vImage_Flags(kvImageNoFlags))
        _ = vImageMatrixMultiply_ARGB8888(&buf, &buf, &i16, 0, &i16, &i32, vImage_Flags(kvImageNoFlags))
        _ = vImageMatrixMultiply_ARGB8888ToPlanar8(&buf, &buf, &i16, 0, &i16, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageMatrixMultiply_ARGBFFFF(&buf, &buf, &f32, &f32, &f32, vImage_Flags(kvImageNoFlags))
        _ = vImageMatrixMultiply_ARGBFFFFToPlanarF(&buf, &buf, &f32, &f32, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageMax_ARGB8888(&buf, &buf, nil, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageMax_ARGBFFFF(&buf, &buf, nil, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageMax_Planar8(&buf, &buf, nil, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageMax_PlanarF(&buf, &buf, nil, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageMin_ARGB8888(&buf, &buf, nil, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageMin_ARGBFFFF(&buf, &buf, nil, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageMin_Planar8(&buf, &buf, nil, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageMin_PlanarF(&buf, &buf, nil, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageMultidimensionalTable_Retain(nil)
        _ = vImageNewResamplingFilter(0, vImage_Flags(kvImageNoFlags))
        _ = vImageOverwriteChannelsWithScalar_Planar8(0, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageOverwriteChannelsWithScalar_PlanarF(0, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImagePNGDecompressionFilter(&buf, 0, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImagePermuteChannels_ARGB16F(&buf, &buf, &u8, vImage_Flags(kvImageNoFlags))
    }
}

func testVImageCFailClosed6() {
    var storage = [UInt8](repeating: 0, count: 64)
    var u8: UInt8 = 0
    var i8: Int8 = 0
    var u16: UInt16 = 0
    var i16: Int16 = 0
    var u32: UInt32 = 0
    var i32: Int32 = 0
    var f32: Float = 0
    var f64: Double = 0
    var aff = vImage_AffineTransform()
    var affD = vImage_AffineTransform_Double()
    var argb2yp = vImage_ARGBToYpCbCr()
    var yp2argb = vImage_YpCbCrToARGB()
    var ypRange = vImage_YpCbCrPixelRange()
    var ypMat = vImage_YpCbCrToARGBMatrix()
    var argbMat = vImage_ARGBToYpCbCrMatrix()
    u8 += 0; i8 += 0; u16 += 0; i16 += 0; u32 += 0; i32 += 0; f32 += 0; f64 += 0
    aff.a += 0; affD.a += 0
    let argb2ypCopy = argb2yp
    argb2yp = argb2ypCopy
    let yp2argbCopy = yp2argb
    yp2argb = yp2argbCopy
    ypRange.Yp_bias += 0
    ypMat.Yp += 0
    argbMat.R_Yp += 0
    storage.withUnsafeMutableBytes { sb in
        var buf = vImage_Buffer(data: sb.baseAddress, height: 2, width: 2, rowBytes: 8)

        _ = vImagePermuteChannels_ARGB16U(&buf, &buf, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImagePermuteChannels_ARGB8888(&buf, &buf, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImagePermuteChannels_ARGBFFFF(&buf, &buf, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImagePermuteChannels_RGB888(&buf, &buf, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImagePiecewiseGamma_Planar8(&buf, &buf, &f32, 0, &f32, 0, vImage_Flags(kvImageNoFlags))
        _ = vImagePiecewiseGamma_Planar8toPlanar16Q12(&buf, &buf, &f32, 0, &f32, 0, vImage_Flags(kvImageNoFlags))
        _ = vImagePiecewiseGamma_Planar8toPlanarF(&buf, &buf, &f32, 0, &f32, 0, vImage_Flags(kvImageNoFlags))
        _ = vImagePiecewiseGamma_PlanarF(&buf, &buf, &f32, 0, &f32, 0, vImage_Flags(kvImageNoFlags))
        _ = vImagePiecewiseGamma_PlanarFtoPlanar8(&buf, &buf, &f32, 0, &f32, 0, vImage_Flags(kvImageNoFlags))
        _ = vImagePremultipliedAlphaBlendDarken_RGBA8888(&buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImagePremultipliedAlphaBlendLighten_RGBA8888(&buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImagePremultipliedAlphaBlendMultiply_RGBA8888(&buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImagePremultipliedAlphaBlendScreen_RGBA8888(&buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImagePremultipliedAlphaBlendWithPermute_ARGB8888(&buf, &buf, &buf, &u8, false, vImage_Flags(kvImageNoFlags))
        _ = vImagePremultipliedAlphaBlendWithPermute_RGBA8888(&buf, &buf, &buf, &u8, false, vImage_Flags(kvImageNoFlags))
        _ = vImagePremultipliedAlphaBlend_ARGB8888(&buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImagePremultipliedAlphaBlend_ARGBFFFF(&buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImagePremultipliedAlphaBlend_BGRA8888(&buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImagePremultipliedAlphaBlend_BGRAFFFF(&buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImagePremultipliedAlphaBlend_Planar8(&buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImagePremultipliedAlphaBlend_PlanarF(&buf, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImagePremultipliedConstAlphaBlend_ARGB8888(&buf, 0, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImagePremultipliedConstAlphaBlend_ARGBFFFF(&buf, 0, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImagePremultipliedConstAlphaBlend_Planar8(&buf, 0, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImagePremultipliedConstAlphaBlend_PlanarF(&buf, 0, &buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImagePremultiplyData_Planar8(&buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImagePremultiplyData_PlanarF(&buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageRichardsonLucyDeConvolve_ARGB8888(&buf, &buf, nil, 0, 0, &i16, &i16, 0, 0, 0, 0, 0, 0, &u8, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageRichardsonLucyDeConvolve_ARGBFFFF(&buf, &buf, nil, 0, 0, &f32, &f32, 0, 0, 0, 0, &f32, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageRichardsonLucyDeConvolve_Planar8(&buf, &buf, nil, 0, 0, &i16, &i16, 0, 0, 0, 0, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageRichardsonLucyDeConvolve_PlanarF(&buf, &buf, nil, 0, 0, &f32, &f32, 0, 0, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageRotate_ARGB16F(&buf, &buf, nil, 0, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageRotate_ARGB16S(&buf, &buf, nil, 0, &i16, vImage_Flags(kvImageNoFlags))
        _ = vImageRotate_ARGB16U(&buf, &buf, nil, 0, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageRotate_ARGB8888(&buf, &buf, nil, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageRotate_ARGBFFFF(&buf, &buf, nil, 0, &f32, vImage_Flags(kvImageNoFlags))
        _ = vImageRotate_CbCr16F(&buf, &buf, nil, 0, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageRotate_Planar8(&buf, &buf, nil, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageRotate_PlanarF(&buf, &buf, nil, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageScale_ARGB16F(&buf, &buf, nil, vImage_Flags(kvImageNoFlags))
    }
}

func testVImageCFailClosed7() {
    var storage = [UInt8](repeating: 0, count: 64)
    var u8: UInt8 = 0
    var i8: Int8 = 0
    var u16: UInt16 = 0
    var i16: Int16 = 0
    var u32: UInt32 = 0
    var i32: Int32 = 0
    var f32: Float = 0
    var f64: Double = 0
    var aff = vImage_AffineTransform()
    var affD = vImage_AffineTransform_Double()
    var argb2yp = vImage_ARGBToYpCbCr()
    var yp2argb = vImage_YpCbCrToARGB()
    var ypRange = vImage_YpCbCrPixelRange()
    var ypMat = vImage_YpCbCrToARGBMatrix()
    var argbMat = vImage_ARGBToYpCbCrMatrix()
    u8 += 0; i8 += 0; u16 += 0; i16 += 0; u32 += 0; i32 += 0; f32 += 0; f64 += 0
    aff.a += 0; affD.a += 0
    let argb2ypCopy = argb2yp
    argb2yp = argb2ypCopy
    let yp2argbCopy = yp2argb
    yp2argb = yp2argbCopy
    ypRange.Yp_bias += 0
    ypMat.Yp += 0
    argbMat.R_Yp += 0
    storage.withUnsafeMutableBytes { sb in
        var buf = vImage_Buffer(data: sb.baseAddress, height: 2, width: 2, rowBytes: 8)

        _ = vImageScale_ARGB16S(&buf, &buf, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageScale_ARGB16U(&buf, &buf, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageScale_ARGBFFFF(&buf, &buf, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageScale_CbCr16F(&buf, &buf, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageScale_CbCr16U(&buf, &buf, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageScale_CbCr8(&buf, &buf, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageScale_Planar16F(&buf, &buf, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageScale_Planar16S(&buf, &buf, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageScale_Planar16U(&buf, &buf, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageScale_PlanarF(&buf, &buf, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageScale_XRGB2101010W(&buf, &buf, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageSepConvolve_ARGB8888(&buf, &buf, nil, 0, 0, &f32, 0, &f32, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageSepConvolve_Planar8to16U(&buf, &buf, nil, 0, 0, &f32, 0, &f32, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageSepConvolve_PlanarF(&buf, &buf, nil, 0, 0, &f32, 0, &f32, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageSymmetricPiecewiseGamma_PlanarF(&buf, &buf, &f32, 0, &f32, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageTableLookUp_ARGB8888(&buf, &buf, nil, nil, nil, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageTentConvolve_ARGB8888(&buf, &buf, nil, 0, 0, 0, 0, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageTentConvolve_Planar8(&buf, &buf, nil, 0, 0, 0, 0, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageUnpremultiplyData_Planar8(&buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageUnpremultiplyData_PlanarF(&buf, &buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShearD_ARGB16F(&buf, &buf, 0, 0, 0, 0, nil, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShearD_ARGB16S(&buf, &buf, 0, 0, 0, 0, nil, &i16, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShearD_ARGB16U(&buf, &buf, 0, 0, 0, 0, nil, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShearD_ARGB8888(&buf, &buf, 0, 0, 0, 0, nil, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShearD_ARGBFFFF(&buf, &buf, 0, 0, 0, 0, nil, &f32, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShearD_CbCr16F(&buf, &buf, 0, 0, 0, 0, nil, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShearD_CbCr16S(&buf, &buf, 0, 0, 0, 0, nil, &i16, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShearD_CbCr16U(&buf, &buf, 0, 0, 0, 0, nil, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShearD_Planar8(&buf, &buf, 0, 0, 0, 0, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShearD_PlanarF(&buf, &buf, 0, 0, 0, 0, nil, 0, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShear_ARGB16F(&buf, &buf, 0, 0, 0, 0, nil, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShear_ARGB16S(&buf, &buf, 0, 0, 0, 0, nil, &i16, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShear_ARGB16U(&buf, &buf, 0, 0, 0, 0, nil, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShear_ARGB8888(&buf, &buf, 0, 0, 0, 0, nil, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShear_ARGBFFFF(&buf, &buf, 0, 0, 0, 0, nil, &f32, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShear_CbCr16F(&buf, &buf, 0, 0, 0, 0, nil, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShear_CbCr16S(&buf, &buf, 0, 0, 0, 0, nil, &i16, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShear_CbCr16U(&buf, &buf, 0, 0, 0, 0, nil, &u16, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShear_CbCr8(&buf, &buf, 0, 0, 0, 0, nil, &u8, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalShear_Planar8(&buf, &buf, 0, 0, 0, 0, nil, 0, vImage_Flags(kvImageNoFlags))
    }
}

func testVImageCFailClosed8() {
    var storage = [UInt8](repeating: 0, count: 64)
    var u8: UInt8 = 0
    var i8: Int8 = 0
    var u16: UInt16 = 0
    var i16: Int16 = 0
    var u32: UInt32 = 0
    var i32: Int32 = 0
    var f32: Float = 0
    var f64: Double = 0
    var aff = vImage_AffineTransform()
    var affD = vImage_AffineTransform_Double()
    var argb2yp = vImage_ARGBToYpCbCr()
    var yp2argb = vImage_YpCbCrToARGB()
    var ypRange = vImage_YpCbCrPixelRange()
    var ypMat = vImage_YpCbCrToARGBMatrix()
    var argbMat = vImage_ARGBToYpCbCrMatrix()
    u8 += 0; i8 += 0; u16 += 0; i16 += 0; u32 += 0; i32 += 0; f32 += 0; f64 += 0
    aff.a += 0; affD.a += 0
    let argb2ypCopy = argb2yp
    argb2yp = argb2ypCopy
    let yp2argbCopy = yp2argb
    yp2argb = yp2argbCopy
    ypRange.Yp_bias += 0
    ypMat.Yp += 0
    argbMat.R_Yp += 0
    storage.withUnsafeMutableBytes { sb in
        var buf = vImage_Buffer(data: sb.baseAddress, height: 2, width: 2, rowBytes: 8)

        _ = vImageVerticalShear_PlanarF(&buf, &buf, 0, 0, 0, 0, nil, 0, vImage_Flags(kvImageNoFlags))
    }
}

