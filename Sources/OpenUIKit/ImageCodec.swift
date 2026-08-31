// PNG/JPEG/PDF decode + raster and PNG/JPEG encode. Owner: image module.
//
// The decoder is stb_image, ALREADY vendored inside the quartz package
// (Sources/CQuartz/pkg_image_io.cpp). This file is only the C-interop
// bridge: `QZImageDecodeRGBA` / `QZImageEncodePNG` / `QZImageEncodeJPEG`
// (patches/quartz/005-image-io-memory.patch, docs/QUARTZ_PATCHES.md) hand
// over STRAIGHT (non-premultiplied) RGBA8 buffers, which is exactly the
// Bitmap layout, so no premultiply round trip is involved and an
// encode → decode round trip is byte-exact for PNG.
//
// No Foundation: bytes go in and out as [UInt8].

import CQuartz

public enum ImageCodec {
    /// Decode PNG or JPEG bytes (sniffed) into a straight-alpha RGBA8
    /// Bitmap. nil when the data is not a supported image.
    public static func decode(_ data: [UInt8]) -> Bitmap? {
        guard !data.isEmpty else { return nil }
        var w: Int32 = 0, h: Int32 = 0
        guard let px = data.withUnsafeBufferPointer({ buf in
            QZImageDecodeRGBA(buf.baseAddress, data.count, &w, &h)
        }) else { return nil }
        defer { QZImageFreeRGBA(px) }
        let width = Int(w), height = Int(h)
        guard width > 0, height > 0 else { return nil }
        let bitmap = Bitmap(width: width, height: height)
        let count = width * height * 4
        bitmap.pixels.withUnsafeMutableBufferPointer { dst in
            for i in 0..<count { dst[i] = px[i] }
        }
        return bitmap
    }

    /// Rasterize the first page of a bounded PDF at `scale` pixels per PDF
    /// point. CQuartz parses the real xref/page/resource graph and rejects
    /// unsupported constructs before returning any partial bitmap.
    static func decodePDF(_ data: [UInt8], scale: CGFloat) -> Bitmap? {
        guard !data.isEmpty, scale.isFinite, scale > 0 else { return nil }
        let document = data.withUnsafeBufferPointer { bytes in
            QZPDFDocumentCreateWithBytes(bytes.baseAddress, bytes.count)
        }
        guard let document else { return nil }
        defer { QZPDFDocumentRelease(document) }
        guard QZPDFDocumentGetNumberOfPages(document) == 1,
              let page = QZPDFDocumentGetPage(document, 1) else { return nil }
        var width: Int32 = 0
        var height: Int32 = 0
        guard let pixels = QZPDFPageRasterizeRGBA(
            page, QZFloat(scale), &width, &height
        ) else { return nil }
        defer { QZImageFreeRGBA(pixels) }
        let w = Int(width)
        let h = Int(height)
        guard w > 0, h > 0,
              w <= Int.max / h / 4 else { return nil }
        let bitmap = Bitmap(width: w, height: h)
        bitmap.pixels.withUnsafeMutableBufferPointer { destination in
            for index in 0..<destination.count {
                destination[index] = pixels[index]
            }
        }
        return bitmap
    }

    /// Encode a Bitmap as PNG (straight alpha, RGBA8). nil on failure.
    public static func encodePNG(_ bitmap: Bitmap) -> [UInt8]? {
        encode(bitmap) { p, w, h, len in QZImageEncodePNG(p, w, h, len) }
    }

    /// Encode a Bitmap as JPEG. `quality` is UIKit's 0...1 compression
    /// quality (0 = smallest, 1 = best); JPEG has no alpha, so translucent
    /// pixels composite over the color they carry (stb writes RGB).
    public static func encodeJPEG(_ bitmap: Bitmap, quality: CGFloat) -> [UInt8]? {
        let q = Int32((Swift.max(0, Swift.min(1, quality)) * 100).rounded())
        return encode(bitmap) { p, w, h, len in
            QZImageEncodeJPEG(p, w, h, Swift.max(1, q), len)
        }
    }

    private static func encode(
        _ bitmap: Bitmap,
        _ body: (UnsafePointer<UInt8>?, Int32, Int32, UnsafeMutablePointer<Int>) -> UnsafeMutablePointer<UInt8>?
    ) -> [UInt8]? {
        guard bitmap.width > 0, bitmap.height > 0 else { return nil }
        var len = 0
        let out: UnsafeMutablePointer<UInt8>? = bitmap.pixels.withUnsafeBufferPointer { src in
            body(src.baseAddress, Int32(bitmap.width), Int32(bitmap.height), &len)
        }
        guard let out, len > 0 else { return nil }
        defer { QZImageFreeRGBA(out) }
        return Array(UnsafeBufferPointer(start: out, count: len))
    }
}
