// GlyphRasterizer. Owner: text module.
//
// Wraps CSTBTrueType (stb_truetype) for glyph rasterization. Glyph POSITIONS
// always come from the metrics table (FontEngine) — stb only supplies shapes.
//
// Variable fonts: stb renders only the DEFAULT instance (SFNS default =
// opsz 28 / wght 400), but real UIKit renders the optical-size instance
// (opsz = point size) at the requested weight. FontVariations parses
// fvar/avar/glyf/gvar and produces instanced outlines which are rasterized
// through stbtt_Rasterize, so anti-aliasing is identical to the stb path.
//
// Scale mapping: stbtt_ScaleForMappingEmToPixels(size * canvasScale) — the
// em-to-pixels mapping CoreText uses. (ScaleForPixelHeight maps ascent+descent
// and comes out ~15% small for SF; verified against the advances table.)
//
// Font files (first readable wins):
//   OpenUIKitRuntime.fontPaths["system"|"mono"|"italic"] overrides, then
//   /System/Library/Fonts/SFNS.ttf, SFNSItalic.ttf for italic, SFNSMono.ttf
//   for monospaced, and /System/Library/Fonts/Supplemental/Arial.ttf as a
//   last resort. Missing files are handled gracefully: labels draw no glyphs.

// M15: a DEFAULT ARGUMENT or an `@inlinable` body may only use members whose
// defining module THIS FILE imports -- `CGRect.zero` and `CGFloat.pi` do not
// ride in on OpenCoreGraphics' typealias the way ordinary uses do. These are
// SCOPED imports on purpose: they satisfy that rule without pulling in
// CoreGraphics' CGColor / CGAffineTransform, which would collide with
// OpenCoreGraphics' own.
#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif


import CSTBTrueType

public final class GlyphFont {
    var info = stbtt_fontinfo()
    let data: UnsafeMutablePointer<UInt8>
    let count: Int
    private(set) var variations: FontVariations?
    /// Cache: (coordsKey << 40 | glyph) → instanced outline.
    private var outlineCache: [UInt64: [stbtt_vertex]] = [:]
    /// Registered normalized-coordinate sets (small; one per font instance used).
    private var coordsList: [[Double]] = []

    init?(path: String) {
        guard let bytes = ResourceIO.readFile(path), !bytes.isEmpty else { return nil }
        count = bytes.count
        data = UnsafeMutablePointer<UInt8>.allocate(capacity: bytes.count)
        bytes.withUnsafeBufferPointer { data.update(from: $0.baseAddress!, count: bytes.count) }
        let offset = stbtt_GetFontOffsetForIndex(data, 0)
        guard offset >= 0, stbtt_InitFont(&info, data, offset) != 0 else {
            data.deallocate()
            return nil
        }
        variations = FontVariations(bytes: data, count: count, fontOffset: Int(offset))
    }

    deinit { data.deallocate() }

    public func glyphIndex(of scalar: Unicode.Scalar) -> Int32 {
        stbtt_FindGlyphIndex(&info, Int32(bitPattern: scalar.value))
    }

    /// stb scale factor mapping em square to `pixels` pixels (CoreText-style).
    public func emScale(forPixels pixels: CGFloat) -> CGFloat {
        CGFloat(stbtt_ScaleForMappingEmToPixels(&info, Float(pixels)))
    }

    /// Advance of a glyph in points at `pointSize` from the font file's
    /// DEFAULT instance (fallback only — the metrics table wins).
    public func advancePoints(of scalar: Unicode.Scalar, pointSize: CGFloat) -> CGFloat {
        let g = glyphIndex(of: scalar)
        guard g != 0 else { return 0 }
        var adv: Int32 = 0
        var lsb: Int32 = 0
        stbtt_GetGlyphHMetrics(&info, g, &adv, &lsb)
        return CGFloat(adv) * emScale(forPixels: pointSize)
    }

    /// Register a normalized coordinate set, returning its cache key (0 = default).
    func registerCoords(_ coords: [Double]) -> Int {
        if coords.isEmpty || coords.allSatisfy({ $0 == 0 }) { return 0 }
        for (i, c) in coordsList.enumerated() where c == coords { return i + 1 }
        coordsList.append(coords)
        return coordsList.count
    }

    public struct GlyphBitmap {
        public var mask: [UInt8]   // width*height coverage bytes
        public var width: Int
        public var height: Int
        public var offsetX: Int    // add to pen x (device px, floor)
        public var offsetY: Int    // add to baseline y (device px); negative above
    }

    /// Filtered-mask cache: (coordsKey, glyph, phaseX) → smoothed bitmap.
    private var filteredCache: [UInt64: GlyphBitmap] = [:]

    /// Rasterize with CoreGraphics-style font smoothing (see GlyphSmoothing):
    /// sharp layer over a Gaussian halo layer, computed from a 4x
    /// supersampled coverage mask. `phaseX` is the quarter-pixel
    /// subposition 0...3; the vertical phase is 0 in practice (UIKit label
    /// baselines land on whole device pixels).
    public func rasterizeSmoothed(glyph g: Int32, devicePixelSize: CGFloat, phaseX: Int,
                                  coordsKey: Int = 0) -> GlyphBitmap? {
        guard g != 0 else { return nil }
        let sizeKey = UInt64(Swift.max(0, Swift.min(0x3FFFFF, Int(devicePixelSize * 16))))
        let key = UInt64(coordsKey & 0xFF) << 56 | UInt64(phaseX & 3) << 54
                | sizeKey << 32 | UInt64(UInt32(bitPattern: g))
        if let c = filteredCache[key] { return c }
        guard let hi = rasterize(glyph: g, pixelSize: devicePixelSize * 4,
                                 shiftX: 0, shiftY: 0, coordsKey: coordsKey) else { return nil }
        let R = GlyphSmoothing.haloRadius
        let taps = GlyphSmoothing.gaussTaps
        // pointSize at scale 2 reference (devicePixelSize = pt * scale)
        let (gain, alpha) = GlyphSmoothing.gainAlpha(for: devicePixelSize / 2)

        // Work on a canvas padded by P supersamples so the halo can spread
        // beyond the glyph bounding box.
        let P = R + 4
        let hw = hi.width + 2 * P, hh = hi.height + 2 * P
        guard hw < 4096, hh < 4096 else { return nil }
        var hiPad = [Float](repeating: 0, count: hw * hh)
        hi.mask.withUnsafeBufferPointer { hbuf in
            hiPad.withUnsafeMutableBufferPointer { pb in
                for y in 0..<hi.height {
                    let src = y * hi.width
                    let dst = (y + P) * hw + P
                    for x in 0..<hi.width { pb[dst + x] = Float(hbuf[src + x]) }
                }
            }
        }
        // Halo: separable Gaussian blur.
        var tmp = [Float](repeating: 0, count: hw * hh)
        var halo = [Float](repeating: 0, count: hw * hh)
        hiPad.withUnsafeBufferPointer { pb in
            tmp.withUnsafeMutableBufferPointer { tb in
                for y in 0..<hh {
                    let row = y * hw
                    for x in 0..<hw {
                        var acc: Float = 0
                        let lo = Swift.max(-R, -x), hiT = Swift.min(R, hw - 1 - x)
                        if lo > hiT { continue }
                        for t in lo...hiT { acc += pb[row + x + t] * taps[t + R] }
                        tb[row + x] = acc
                    }
                }
            }
        }
        tmp.withUnsafeBufferPointer { tb in
            halo.withUnsafeMutableBufferPointer { hb in
                for y in 0..<hh {
                    for x in 0..<hw {
                        var acc: Float = 0
                        let lo = Swift.max(-R, -y), hiT = Swift.min(R, hh - 1 - y)
                        if lo > hiT { continue }
                        for t in lo...hiT { acc += tb[(y + t) * hw + x] * taps[t + R] }
                        hb[y * hw + x] = acc
                    }
                }
            }
        }

        // Downsample both layers 4:1 at the quarter-phase offset and combine.
        // Padded sample (hy, hx) sits at 4x coordinates
        // (offy4 + hy - P, offx4 + hx - P) relative to the integer pen
        // position; output pixel (Y, X) averages 4x samples 4X...4X+3.
        let offx4 = hi.offsetX + phaseX - P
        let offy4 = hi.offsetY - P
        let x0 = Int((Double(offx4) / 4).rounded(.down))
        let x1 = Int((Double(offx4 + hw - 1) / 4).rounded(.up))
        let y0 = Int((Double(offy4) / 4).rounded(.down))
        let y1 = Int((Double(offy4 + hh - 1) / 4).rounded(.up))
        let w = x1 - x0 + 1, h = y1 - y0 + 1
        guard w > 0, h > 0, w < 2048, h < 2048 else { return nil }
        var out = [UInt8](repeating: 0, count: w * h)
        let fa = Float(alpha), fg = Float(gain)
        hiPad.withUnsafeBufferPointer { pb in
            halo.withUnsafeBufferPointer { hb in
                out.withUnsafeMutableBufferPointer { obuf in
                    for Y in 0..<h {
                        let baseRow = 4 * (Y + y0) - offy4
                        for X in 0..<w {
                            let baseCol = 4 * (X + x0) - offx4
                            var s: Float = 0
                            var hl: Float = 0
                            for v in 0..<4 {
                                let hy = baseRow + v
                                if hy < 0 || hy >= hh { continue }
                                let rowOff = hy * hw
                                for u in 0..<4 {
                                    let hx = baseCol + u
                                    if hx < 0 || hx >= hw { continue }
                                    s += pb[rowOff + hx]
                                    hl += hb[rowOff + hx]
                                }
                            }
                            s /= 16 * 255
                            hl /= 16 * 255
                            let sharp = fa * s
                            let haloV = fg * hl
                            let p = sharp + haloV - sharp * haloV
                            if p <= 0.002 { continue }
                            obuf[Y * w + X] = UInt8((Swift.min(p, 1) * 255).rounded())
                        }
                    }
                }
            }
        }
        let bmp = GlyphBitmap(mask: out, width: w, height: h, offsetX: x0, offsetY: y0)
        filteredCache[key] = bmp
        return bmp
    }

    /// Rasterize a glyph at `pixelSize` device pixels per em-mapped point
    /// size, with subpixel shifts in [0, 1). `coordsKey` selects a
    /// registered variation instance (0 = font default).
    public func rasterize(glyph g: Int32, pixelSize: CGFloat, shiftX: CGFloat,
                          shiftY: CGFloat = 0, coordsKey: Int = 0) -> GlyphBitmap? {
        guard g != 0 else { return nil }
        if coordsKey > 0, coordsKey <= coordsList.count, variations != nil {
            if let bmp = rasterizeInstanced(glyph: g, pixelSize: pixelSize, shiftX: shiftX,
                                            shiftY: shiftY, coordsKey: coordsKey) {
                return bmp
            }
            // fall through to default-instance rendering on failure
        }
        let s = Float(emScale(forPixels: pixelSize))
        var x0: Int32 = 0, y0: Int32 = 0, x1: Int32 = 0, y1: Int32 = 0
        stbtt_GetGlyphBitmapBoxSubpixel(&info, g, s, s, Float(shiftX), Float(shiftY),
                                        &x0, &y0, &x1, &y1)
        let w = Int(x1 - x0), h = Int(y1 - y0)
        guard w > 0, h > 0, w < 4096, h < 4096 else { return nil }
        var mask = [UInt8](repeating: 0, count: w * h)
        mask.withUnsafeMutableBufferPointer { buf in
            stbtt_MakeGlyphBitmapSubpixel(&info, buf.baseAddress, Int32(w), Int32(h), Int32(w),
                                          s, s, Float(shiftX), Float(shiftY), g)
        }
        return GlyphBitmap(mask: mask, width: w, height: h, offsetX: Int(x0), offsetY: Int(y0))
    }

    private func instancedOutline(glyph: Int32, coordsKey: Int) -> [stbtt_vertex]? {
        let key = UInt64(coordsKey) << 40 | UInt64(UInt32(bitPattern: glyph))
        if let v = outlineCache[key] { return v }
        guard let vars = variations else { return nil }
        let coords = coordsList[coordsKey - 1]
        guard let verts = vars.instancedVertices(glyph: Int(glyph), coords: coords) else {
            return nil
        }
        outlineCache[key] = verts
        return verts
    }

    private func rasterizeInstanced(glyph g: Int32, pixelSize: CGFloat, shiftX: CGFloat,
                                    shiftY: CGFloat, coordsKey: Int) -> GlyphBitmap? {
        guard var verts = instancedOutline(glyph: g, coordsKey: coordsKey),
              !verts.isEmpty else { return nil }
        let s = emScale(forPixels: pixelSize)
        // Outline bbox (control points included — conservative, matches shape).
        var minX = Double.infinity, minY = Double.infinity
        var maxX = -Double.infinity, maxY = -Double.infinity
        for v in verts {
            minX = Swift.min(minX, Double(v.x)); maxX = Swift.max(maxX, Double(v.x))
            minY = Swift.min(minY, Double(v.y)); maxY = Swift.max(maxY, Double(v.y))
            if v.type == 3 {  // curve: include control point
                minX = Swift.min(minX, Double(v.cx)); maxX = Swift.max(maxX, Double(v.cx))
                minY = Swift.min(minY, Double(v.cy)); maxY = Swift.max(maxY, Double(v.cy))
            }
        }
        guard minX <= maxX, minY <= maxY else { return nil }
        let fs = Double(s)
        let ix0 = Int((minX * fs + Double(shiftX)).rounded(.down))
        let iy0 = Int((-maxY * fs + Double(shiftY)).rounded(.down))
        let ix1 = Int((maxX * fs + Double(shiftX)).rounded(.up))
        let iy1 = Int((-minY * fs + Double(shiftY)).rounded(.up))
        let w = ix1 - ix0, h = iy1 - iy0
        guard w > 0, h > 0, w < 4096, h < 4096 else { return nil }
        var mask = [UInt8](repeating: 0, count: w * h)
        var ok = false
        mask.withUnsafeMutableBufferPointer { buf in
            var bm = stbtt__bitmap(w: Int32(w), h: Int32(h), stride: Int32(w),
                                   pixels: buf.baseAddress)
            verts.withUnsafeMutableBufferPointer { vb in
                stbtt_Rasterize(&bm, 0.35, vb.baseAddress, Int32(vb.count),
                                Float(s), Float(s), Float(shiftX), Float(shiftY),
                                Int32(ix0), Int32(iy0), 1, nil)
                ok = true
            }
        }
        guard ok else { return nil }
        return GlyphBitmap(mask: mask, width: w, height: h, offsetX: ix0, offsetY: iy0)
    }
}

/// A glyph font plus the variation instance real UIKit would use for a
/// given UIFont (normalized axis coordinates, pre-registered for caching).
public struct InstancedGlyphFont {
    public let font: GlyphFont
    let coordsKey: Int

    public func glyphIndex(of scalar: Unicode.Scalar) -> Int32 {
        font.glyphIndex(of: scalar)
    }

    public func rasterize(glyph g: Int32, pixelSize: CGFloat, shiftX: CGFloat,
                          shiftY: CGFloat = 0) -> GlyphFont.GlyphBitmap? {
        font.rasterize(glyph: g, pixelSize: pixelSize, shiftX: shiftX, shiftY: shiftY,
                       coordsKey: coordsKey)
    }

    public func rasterizeSmoothed(glyph g: Int32, devicePixelSize: CGFloat, phaseX: Int)
        -> GlyphFont.GlyphBitmap? {
        font.rasterizeSmoothed(glyph: g, devicePixelSize: devicePixelSize, phaseX: phaseX,
                               coordsKey: coordsKey)
    }

    public func advancePoints(of scalar: Unicode.Scalar, pointSize: CGFloat) -> CGFloat {
        font.advancePoints(of: scalar, pointSize: pointSize)
    }
}

public enum GlyphRasterizer {
    static var cache: [String: GlyphFont] = [:]
    static var failed: Set<String> = []

    static func load(_ paths: [String]) -> GlyphFont? {
        for p in paths where !p.isEmpty {
            if let f = cache[p] { return f }
            if failed.contains(p) { continue }
            if let f = GlyphFont(path: p) {
                cache[p] = f
                return f
            }
            failed.insert(p)
        }
        return nil
    }

    static func tag(_ s: StaticString) -> UInt32 {
        var v: UInt32 = 0
        s.withUTF8Buffer { buf in
            for b in buf { v = v << 8 | UInt32(b) }
        }
        return v
    }

    /// wght axis value used by UIKit's system font for each UIFont.Weight
    /// (from SFNS.ttf named instances at wdth=100, GRAD=400).
    static func systemWght(_ w: UIFont.Weight) -> Double {
        switch w {
        case .ultraLight: return 30.925003051757812
        case .thin: return 110.72500610351562
        case .light: return 274.31500244140625
        case .regular: return 400
        case .medium: return 510
        case .semibold: return 590
        case .bold: return 700
        case .heavy: return 860
        case .black: return 1000
        }
    }

    /// SF Mono named instances: (wght, YAXS).
    static func monoCoords(_ w: UIFont.Weight) -> (Double, Double) {
        switch w {
        case .ultraLight, .thin, .light: return (294.673095703125, 294.673095703125)
        case .regular: return (400, 324.3341064453125)
        case .medium: return (483.53509521484375, 320.7021942138672)
        case .semibold: return (571.3074951171875, 324.9394073486328)
        case .bold: return (683.2929992675781, 335.8352966308594)
        case .heavy, .black: return (900, 294.673095703125)
        }
    }

    /// SF Italic named instances: (wght, YAXS).
    static func italicCoords(_ w: UIFont.Weight) -> (Double, Double) {
        switch w {
        case .ultraLight: return (28.92999267578125, 400)
        case .thin: return (112.72000122070312, 400)
        case .light: return (276.30999755859375, 400)
        case .regular: return (400, 400)
        case .medium: return (508, 436)
        case .semibold: return (590.8000030517578, 419.1999969482422)
        case .bold: return (700, 430)
        case .heavy: return (858.3999938964844, 400)
        case .black: return (1000, 400)
        }
    }

    /// Best available font file + variation instance for the given UIFont.
    public static func font(for font: UIFont) -> InstancedGlyphFont? {
        let overrides = OpenUIKitRuntime.fontPaths
        var paths: [String] = []
        switch font.design {
        case .monospaced:
            if let o = overrides["mono"] { paths.append(o) }
            paths.append("/System/Library/Fonts/SFNSMono.ttf")
        case .italic:
            if let o = overrides["italic"] { paths.append(o) }
            paths.append("/System/Library/Fonts/SFNSItalic.ttf")
            paths.append("/System/Library/Fonts/SFNS.ttf")
        case .default:
            if let o = overrides[font.weight.name] { paths.append(o) }
            if let o = overrides["system"] { paths.append(o) }
            paths.append("/System/Library/Fonts/SFNS.ttf")
        }
        paths.append("/System/Library/Fonts/Supplemental/Arial.ttf")
        guard let gf = load(paths) else { return nil }

        var key = 0
        if let vars = gf.variations {
            var user: [UInt32: Double] = [:]
            switch font.design {
            case .default:
                user[tag("wght")] = systemWght(font.weight)
                user[tag("opsz")] = Double(font.pointSize)
            case .italic:
                let (w, y) = italicCoords(font.weight)
                user[tag("wght")] = w
                user[tag("YAXS")] = y
                user[tag("opsz")] = Double(font.pointSize)
            case .monospaced:
                let (w, y) = monoCoords(font.weight)
                user[tag("wght")] = w
                user[tag("YAXS")] = y
            }
            let coords = vars.normalizedCoords(user)
            key = gf.registerCoords(coords)
        }
        return InstancedGlyphFont(font: gf, coordsKey: key)
    }
}
