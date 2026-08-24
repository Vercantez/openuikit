// UIImage — portable image model. Owner: image module.
//
// A UIImage wraps an RGBA8 Bitmap (the pixel backing store) plus a scale
// factor, mirroring real UIKit: `size` is in POINTS (pixel size / scale).
// Images in this project are synthesized procedurally by the scene runner
// (see docs/SCENE_SPEC.md) — there is no asset/file loading here.

public final class UIImage {
    /// Pixel backing store (width/height are in PIXELS at `scale`).
    public let bitmap: Bitmap
    /// Pixels-per-point of the backing store (like UIImage.scale).
    public let scale: CGFloat

    /// Logical size in points (pixel size / scale), like UIImage.size.
    public var size: CGSize {
        CGSize(width: CGFloat(bitmap.width) / scale,
               height: CGFloat(bitmap.height) / scale)
    }

    public init(bitmap: Bitmap, scale: CGFloat = 1) {
        self.bitmap = bitmap
        self.scale = scale > 0 ? scale : 1
    }

    // MARK: CG-compatible resampling
    //
    // Real CG (oracle: layer.render into a CGContext, default interpolation)
    // does NOT use plain bilinear filtering when scaling image contents.
    // Probing the oracle with magnified step edges (see ImageViewTests and
    // module notes) shows a separable resampler that:
    //   1. samples at s = (d + 0.5) * srcSize / dstSize - 0.5 (standard
    //      center-aligned mapping, edge-clamped),
    //   2. quantizes the fractional part t to eighths: k = round(8t),
    //   3. uses a WARPED weight from a fixed table instead of t itself:
    //        W = [0, 1/16, 1/8, 1/4, 1/2, 3/4, 7/8, 15/16, 1]
    // which yields the dyadic staircase edge profiles real CG produces
    // (255, 239, 223, 191, 128, 64, 32, 16, 0 across a magnified
    // black/white edge). Verified exactly against oracle renders at scales
    // 1.5x, 2.5x and 20x; plain bilinear is off by up to 44/255 at seams.
    static let resampleWeights: [CGFloat] = [
        0, 1.0 / 16, 1.0 / 8, 1.0 / 4, 1.0 / 2, 3.0 / 4, 7.0 / 8, 15.0 / 16, 1,
    ]

    /// Resample the backing bitmap to an exact pixel size using the
    /// CG-compatible warped-weight filter (premultiplied-alpha sampling).
    /// Returns the original bitmap when the size already matches.
    func resampledBitmap(width dw: Int, height dh: Int) -> Bitmap {
        let sw = bitmap.width, sh = bitmap.height
        if dw == sw && dh == sh { return bitmap }
        let out = Bitmap(width: dw, height: dh)
        guard dw > 0, dh > 0, sw > 0, sh > 0 else { return out }
        let W = UIImage.resampleWeights

        // Per-axis source index pairs + warped weights.
        func axis(_ dst: Int, _ src: Int) -> ([Int], [Int], [CGFloat]) {
            var i0 = [Int](), i1 = [Int](), w = [CGFloat]()
            i0.reserveCapacity(dst); i1.reserveCapacity(dst); w.reserveCapacity(dst)
            for d in 0..<dst {
                let s = (CGFloat(d) + 0.5) * CGFloat(src) / CGFloat(dst) - 0.5
                let f = s.rounded(.down)
                let t = s - f
                let k = Int((8 * t).rounded())
                let a = Int(f)
                i0.append(Swift.min(Swift.max(a, 0), src - 1))
                i1.append(Swift.min(Swift.max(a + 1, 0), src - 1))
                w.append(W[k])
            }
            return (i0, i1, w)
        }
        let (xi0, xi1, xw) = axis(dw, sw)
        let (yi0, yi1, yw) = axis(dh, sh)

        bitmap.pixels.withUnsafeBufferPointer { src in
            out.pixels.withUnsafeMutableBufferPointer { dst in
                @inline(__always) func premul(_ x: Int, _ y: Int) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
                    let o = (y * sw + x) * 4
                    let a = CGFloat(src[o + 3])
                    return (CGFloat(src[o]) * a, CGFloat(src[o + 1]) * a,
                            CGFloat(src[o + 2]) * a, a * 255)
                }
                @inline(__always) func b8(_ v: CGFloat) -> UInt8 {
                    UInt8(Swift.max(0, Swift.min(255, v.rounded())))
                }
                for y in 0..<dh {
                    let wy = yw[y], y0 = yi0[y], y1 = yi1[y]
                    for x in 0..<dw {
                        let wx = xw[x], x0 = xi0[x], x1 = xi1[x]
                        let s00 = premul(x0, y0), s10 = premul(x1, y0)
                        let s01 = premul(x0, y1), s11 = premul(x1, y1)
                        let w00 = (1 - wx) * (1 - wy), w10 = wx * (1 - wy)
                        let w01 = (1 - wx) * wy, w11 = wx * wy
                        let pr = s00.0 * w00 + s10.0 * w10 + s01.0 * w01 + s11.0 * w11
                        let pg = s00.1 * w00 + s10.1 * w10 + s01.1 * w01 + s11.1 * w11
                        let pb = s00.2 * w00 + s10.2 * w10 + s01.2 * w01 + s11.2 * w11
                        let pa = s00.3 * w00 + s10.3 * w10 + s01.3 * w01 + s11.3 * w11
                        let o = (y * dw + x) * 4
                        if pa <= 0 {
                            dst[o] = 0; dst[o + 1] = 0; dst[o + 2] = 0; dst[o + 3] = 0
                        } else {
                            let inv = 255 / pa
                            dst[o] = b8(pr * inv); dst[o + 1] = b8(pg * inv)
                            dst[o + 2] = b8(pb * inv); dst[o + 3] = b8(pa / 255)
                        }
                    }
                }
            }
        }
        return out
    }
}
