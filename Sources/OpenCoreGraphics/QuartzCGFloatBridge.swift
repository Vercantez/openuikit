// Keep the portable Swift CGFloat distinct from libquartz's C ABI scalar.
// Apple SDK overlays perform this conversion at their CoreGraphics boundary;
// Foundation-hidden guests need the equivalent boundary explicitly.

import CQuartz

#if !canImport(Foundation)
extension QZPoint {
    @inline(__always)
    public init(x: CGFloat, y: CGFloat) {
        self.init(x: QZFloat(x), y: QZFloat(y))
    }
}

extension QZSize {
    @inline(__always)
    public init(width: CGFloat, height: CGFloat) {
        self.init(width: QZFloat(width), height: QZFloat(height))
    }
}

extension QZAffineTransform {
    @inline(__always)
    public init(a: CGFloat, b: CGFloat, c: CGFloat, d: CGFloat,
                tx: CGFloat, ty: CGFloat) {
        self.init(a: QZFloat(a), b: QZFloat(b), c: QZFloat(c),
                  d: QZFloat(d), tx: QZFloat(tx), ty: QZFloat(ty))
    }
}

@inline(__always)
func QZContextSetAlpha(_ context: QZContextRef!, _ alpha: CGFloat) {
    CQuartz.QZContextSetAlpha(context, QZFloat(alpha))
}

@inline(__always)
func QZContextSetShadowWithColor(
    _ context: QZContextRef!, _ offset: QZSize, _ blur: CGFloat,
    _ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat
) {
    CQuartz.QZContextSetShadowWithColor(
        context, offset, QZFloat(blur), QZFloat(red), QZFloat(green),
        QZFloat(blue), QZFloat(alpha))
}

@inline(__always)
func QZContextSetRGBFillColor(
    _ context: QZContextRef!, _ red: CGFloat, _ green: CGFloat,
    _ blue: CGFloat, _ alpha: CGFloat
) {
    CQuartz.QZContextSetRGBFillColor(
        context, QZFloat(red), QZFloat(green), QZFloat(blue), QZFloat(alpha))
}

@inline(__always)
func QZContextSetRGBStrokeColor(
    _ context: QZContextRef!, _ red: CGFloat, _ green: CGFloat,
    _ blue: CGFloat, _ alpha: CGFloat
) {
    CQuartz.QZContextSetRGBStrokeColor(
        context, QZFloat(red), QZFloat(green), QZFloat(blue), QZFloat(alpha))
}

@inline(__always)
func QZContextSetLineWidth(_ context: QZContextRef!, _ width: CGFloat) {
    CQuartz.QZContextSetLineWidth(context, QZFloat(width))
}

@inline(__always)
func QZContextSetMiterLimit(_ context: QZContextRef!, _ limit: CGFloat) {
    CQuartz.QZContextSetMiterLimit(context, QZFloat(limit))
}

@inline(__always)
func QZContextMoveToPoint(
    _ context: QZContextRef!, _ x: CGFloat, _ y: CGFloat
) {
    CQuartz.QZContextMoveToPoint(context, QZFloat(x), QZFloat(y))
}

@inline(__always)
func QZContextAddLineToPoint(
    _ context: QZContextRef!, _ x: CGFloat, _ y: CGFloat
) {
    CQuartz.QZContextAddLineToPoint(context, QZFloat(x), QZFloat(y))
}

@inline(__always)
func QZContextAddQuadCurveToPoint(
    _ context: QZContextRef!, _ controlX: CGFloat, _ controlY: CGFloat,
    _ x: CGFloat, _ y: CGFloat
) {
    CQuartz.QZContextAddQuadCurveToPoint(
        context, QZFloat(controlX), QZFloat(controlY), QZFloat(x), QZFloat(y))
}

@inline(__always)
func QZContextAddCurveToPoint(
    _ context: QZContextRef!, _ control1X: CGFloat, _ control1Y: CGFloat,
    _ control2X: CGFloat, _ control2Y: CGFloat, _ x: CGFloat, _ y: CGFloat
) {
    CQuartz.QZContextAddCurveToPoint(
        context, QZFloat(control1X), QZFloat(control1Y),
        QZFloat(control2X), QZFloat(control2Y), QZFloat(x), QZFloat(y))
}
#endif
