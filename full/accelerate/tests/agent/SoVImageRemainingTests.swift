import Accelerate
import Foundation

func testSoVImageRemStructs() {
    _ = vImageWhitePoint.self
    let vivImageWhitePoint = vImageWhitePoint()
    _ = vivImageWhitePoint.white_x
    _ = vivImageWhitePoint.white_y
    _ = vImageWhitePoint(white_x: 0, white_y: 0)
    _ = vImageRGBPrimaries.self
    let vivImageRGBPrimaries = vImageRGBPrimaries()
    _ = vivImageRGBPrimaries.blue_x
    _ = vivImageRGBPrimaries.blue_y
    _ = vivImageRGBPrimaries.green_x
    _ = vivImageRGBPrimaries.green_y
    _ = vivImageRGBPrimaries.red_x
    _ = vivImageRGBPrimaries.red_y
    _ = vivImageRGBPrimaries.white_x
    _ = vivImageRGBPrimaries.white_y
    _ = vImageRGBPrimaries(red_x: 0, green_x: 0, blue_x: 0, white_x: 0, red_y: 0, green_y: 0, blue_y: 0, white_y: 0)
    _ = vImageTransferFunction.self
    let vivImageTransferFunction = vImageTransferFunction()
    _ = vivImageTransferFunction.c0
    _ = vivImageTransferFunction.c1
    _ = vivImageTransferFunction.c2
    _ = vivImageTransferFunction.c3
    _ = vivImageTransferFunction.c4
    _ = vivImageTransferFunction.c5
    _ = vivImageTransferFunction.cutoff
    _ = vivImageTransferFunction.gamma
    _ = vImageTransferFunction(c0: CGFloat(0), c1: CGFloat(0), c2: CGFloat(0), c3: CGFloat(0), gamma: CGFloat(0), cutoff: CGFloat(0), c4: CGFloat(0), c5: CGFloat(0))
    _ = vImage_AffineTransform.self
    let vivImage_AffineTransform = vImage_AffineTransform()
    _ = vivImage_AffineTransform.a
    _ = vivImage_AffineTransform.b
    _ = vivImage_AffineTransform.c
    _ = vivImage_AffineTransform.d
    _ = vivImage_AffineTransform.tx
    _ = vivImage_AffineTransform.ty
    _ = vImage_AffineTransform(a: Float(0), b: Float(0), c: Float(0), d: Float(0), tx: Float(0), ty: Float(0))
    _ = vImage_AffineTransform(a: CGFloat(0), b: CGFloat(0), c: CGFloat(0), d: CGFloat(0), tx: CGFloat(0), ty: CGFloat(0))
    _ = vImage_YpCbCrPixelRange.self
    let vivImage_YpCbCrPixelRange = vImage_YpCbCrPixelRange()
    _ = vivImage_YpCbCrPixelRange.CbCrMax
    _ = vivImage_YpCbCrPixelRange.CbCrMin
    _ = vivImage_YpCbCrPixelRange.CbCrRangeMax
    _ = vivImage_YpCbCrPixelRange.CbCr_bias
    _ = vivImage_YpCbCrPixelRange.YpMax
    _ = vivImage_YpCbCrPixelRange.YpMin
    _ = vivImage_YpCbCrPixelRange.YpRangeMax
    _ = vivImage_YpCbCrPixelRange.Yp_bias
    _ = vImage_YpCbCrPixelRange(Yp_bias: 0, CbCr_bias: 0, YpRangeMax: 0, CbCrRangeMax: 0, YpMax: 0, YpMin: 0, CbCrMax: 0, CbCrMin: 0)
    _ = vImageChannelDescription.self
    let vivImageChannelDescription = vImageChannelDescription()
    _ = vivImageChannelDescription.full
    _ = vivImageChannelDescription.max
    _ = vivImageChannelDescription.min
    _ = vivImageChannelDescription.zero
    _ = vImageChannelDescription(min: CGFloat(0), zero: CGFloat(0), full: CGFloat(0), max: CGFloat(0))
    _ = vImage_ARGBToYpCbCrMatrix.self
    let vivImage_ARGBToYpCbCrMatrix = vImage_ARGBToYpCbCrMatrix()
    _ = vivImage_ARGBToYpCbCrMatrix.B_Cb_R_Cr
    _ = vivImage_ARGBToYpCbCrMatrix.B_Cr
    _ = vivImage_ARGBToYpCbCrMatrix.B_Yp
    _ = vivImage_ARGBToYpCbCrMatrix.G_Cb
    _ = vivImage_ARGBToYpCbCrMatrix.G_Cr
    _ = vivImage_ARGBToYpCbCrMatrix.G_Yp
    _ = vivImage_ARGBToYpCbCrMatrix.R_Cb
    _ = vivImage_ARGBToYpCbCrMatrix.R_Yp
    _ = vImage_ARGBToYpCbCrMatrix(R_Yp: 0, G_Yp: 0, B_Yp: 0, R_Cb: 0, G_Cb: 0, B_Cb_R_Cr: 0, G_Cr: 0, B_Cr: 0)
    _ = vImage_YpCbCrToARGBMatrix.self
    let vivImage_YpCbCrToARGBMatrix = vImage_YpCbCrToARGBMatrix()
    _ = vivImage_YpCbCrToARGBMatrix.Cb_B
    _ = vivImage_YpCbCrToARGBMatrix.Cb_G
    _ = vivImage_YpCbCrToARGBMatrix.Cr_G
    _ = vivImage_YpCbCrToARGBMatrix.Cr_R
    _ = vivImage_YpCbCrToARGBMatrix.Yp
    _ = vImage_YpCbCrToARGBMatrix(Yp: 0, Cr_R: 0, Cr_G: 0, Cb_G: 0, Cb_B: 0)
    _ = vImage_PerpsectiveTransform.self
    let vivImage_PerpsectiveTransform = vImage_PerpsectiveTransform()
    _ = vivImage_PerpsectiveTransform.a
    _ = vivImage_PerpsectiveTransform.b
    _ = vivImage_PerpsectiveTransform.c
    _ = vivImage_PerpsectiveTransform.d
    _ = vivImage_PerpsectiveTransform.tx
    _ = vivImage_PerpsectiveTransform.ty
    _ = vivImage_PerpsectiveTransform.v
    _ = vivImage_PerpsectiveTransform.vx
    _ = vivImage_PerpsectiveTransform.vy
    _ = vImage_PerpsectiveTransform(a: 0, b: 0, c: 0, d: 0, tx: 0, ty: 0, vx: 0, vy: 0, v: 0)
    _ = vImage_AffineTransform_Double.self
    let vivImage_AffineTransform_Double = vImage_AffineTransform_Double()
    _ = vivImage_AffineTransform_Double.a
    _ = vivImage_AffineTransform_Double.b
    _ = vivImage_AffineTransform_Double.c
    _ = vivImage_AffineTransform_Double.d
    _ = vivImage_AffineTransform_Double.tx
    _ = vivImage_AffineTransform_Double.ty
    _ = vImage_AffineTransform_Double(a: Double(0), b: Double(0), c: Double(0), d: Double(0), tx: Double(0), ty: Double(0))
    _ = vImage_AffineTransform_Double(a: CGFloat(0), b: CGFloat(0), c: CGFloat(0), d: CGFloat(0), tx: CGFloat(0), ty: CGFloat(0))
    _ = vImage_ARGBToYpCbCr.self
    _ = vImage_ARGBToYpCbCr()
    _ = vImage_ARGBToYpCbCr(opaque: (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0))
    _ = vImage_YpCbCrToARGB.self
    _ = vImage_YpCbCrToARGB()
    _ = vImage_YpCbCrToARGB(opaque: (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0))
}

func testSoVImageRemEnums() {
    _ = vImageARGBType.self
    precondition(vImageARGBType(rawValue: 0).rawValue == 0)
    precondition(vImageARGBType(0) == vImageARGBType(rawValue: 0))
    precondition(vImageARGBType(rawValue: 0) != vImageARGBType(rawValue: 1))
    _ = vImageYpCbCrType.self
    precondition(vImageYpCbCrType(rawValue: 0).rawValue == 0)
    precondition(vImageYpCbCrType(0) == vImageYpCbCrType(rawValue: 0))
    precondition(vImageYpCbCrType(rawValue: 0) != vImageYpCbCrType(rawValue: 1))
    _ = vImageMDTableUsageHint.self
    precondition(vImageMDTableUsageHint(rawValue: 0).rawValue == 0)
    precondition(vImageMDTableUsageHint(0) == vImageMDTableUsageHint(rawValue: 0))
    precondition(vImageMDTableUsageHint(rawValue: 0) != vImageMDTableUsageHint(rawValue: 1))
    _ = vImage_InterpolationMethod.self
    precondition(vImage_InterpolationMethod(rawValue: 0).rawValue == 0)
    precondition(vImage_InterpolationMethod(0) == vImage_InterpolationMethod(rawValue: 0))
    precondition(vImage_InterpolationMethod(rawValue: 0) != vImage_InterpolationMethod(rawValue: 1))
}
