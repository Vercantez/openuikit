// GlyphRasterizer. Owner: text module.
//
// Wraps CSTBTrueType (stb_truetype) for glyph rasterization. Glyph POSITIONS
// always come from the metrics table (FontEngine) — stb only supplies shapes.
//
// Scale mapping: stbtt_ScaleForMappingEmToPixels(size * canvasScale) — the
// em-to-pixels mapping CoreText uses. (ScaleForPixelHeight maps ascent+descent
// and comes out ~15% small for SF; verified against the advances table.)
//
// Font files (first readable wins):
//   OpenUIKitRuntime.fontPaths["system"|"mono"|"italic"] overrides, then
//   /System/Library/Fonts/SFNS.ttf (variable; stb renders the default
//   instance — acceptable for now), SFNSMono.ttf for monospaced, and
//   /System/Library/Fonts/Supplemental/Arial.ttf as a last resort.
// Missing files are handled gracefully: labels simply draw no glyphs.

import CSTBTrueType

public final class GlyphFont {
    var info = stbtt_fontinfo()
    let data: UnsafeMutablePointer<UInt8>
    let count: Int

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
    }

    deinit { data.deallocate() }

    public func glyphIndex(of scalar: Unicode.Scalar) -> Int32 {
        stbtt_FindGlyphIndex(&info, Int32(bitPattern: scalar.value))
    }

    /// stb scale factor mapping em square to `pixels` pixels (CoreText-style).
    public func emScale(forPixels pixels: CGFloat) -> CGFloat {
        CGFloat(stbtt_ScaleForMappingEmToPixels(&info, Float(pixels)))
    }

    /// Advance of a glyph in points at `pointSize` (from the font file; only
    /// used for characters missing from the metrics table, e.g. U+2026).
    public func advancePoints(of scalar: Unicode.Scalar, pointSize: CGFloat) -> CGFloat {
        let g = glyphIndex(of: scalar)
        guard g != 0 else { return 0 }
        var adv: Int32 = 0
        var lsb: Int32 = 0
        stbtt_GetGlyphHMetrics(&info, g, &adv, &lsb)
        return CGFloat(adv) * emScale(forPixels: pointSize)
    }

    public struct GlyphBitmap {
        public var mask: [UInt8]   // width*height coverage bytes
        public var width: Int
        public var height: Int
        public var offsetX: Int    // add to pen x (device px, floor)
        public var offsetY: Int    // add to baseline y (device px); negative above
    }

    /// Rasterize a glyph at `pixelSize` device pixels per em-mapped point
    /// size, with a horizontal subpixel shift in [0, 1).
    public func rasterize(glyph g: Int32, pixelSize: CGFloat, shiftX: CGFloat) -> GlyphBitmap? {
        guard g != 0 else { return nil }
        let s = Float(emScale(forPixels: pixelSize))
        var x0: Int32 = 0, y0: Int32 = 0, x1: Int32 = 0, y1: Int32 = 0
        stbtt_GetGlyphBitmapBoxSubpixel(&info, g, s, s, Float(shiftX), 0, &x0, &y0, &x1, &y1)
        let w = Int(x1 - x0), h = Int(y1 - y0)
        guard w > 0, h > 0, w < 4096, h < 4096 else { return nil }
        var mask = [UInt8](repeating: 0, count: w * h)
        mask.withUnsafeMutableBufferPointer { buf in
            stbtt_MakeGlyphBitmapSubpixel(&info, buf.baseAddress, Int32(w), Int32(h), Int32(w),
                                          s, s, Float(shiftX), 0, g)
        }
        return GlyphBitmap(mask: mask, width: w, height: h, offsetX: Int(x0), offsetY: Int(y0))
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

    /// Best available font file for the given UIFont; nil if none readable.
    public static func font(for font: UIFont) -> GlyphFont? {
        let overrides = OpenUIKitRuntime.fontPaths
        var paths: [String] = []
        switch font.design {
        case .monospaced:
            if let o = overrides["mono"] { paths.append(o) }
            paths.append("/System/Library/Fonts/SFNSMono.ttf")
        case .italic:
            if let o = overrides["italic"] { paths.append(o) }
            paths.append("/System/Library/Fonts/SFNS.ttf")
        case .default:
            if let o = overrides[font.weight.name] { paths.append(o) }
            if let o = overrides["system"] { paths.append(o) }
            paths.append("/System/Library/Fonts/SFNS.ttf")
        }
        paths.append("/System/Library/Fonts/Supplemental/Arial.ttf")
        return load(paths)
    }
}
