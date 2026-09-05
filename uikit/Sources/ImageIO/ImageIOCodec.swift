// PNG/JPEG bytes through CQuartz (same entry points as OpenUIKit.ImageCodec).
// Kept here so ImageIO does not depend on OpenUIKit.

import CQuartz
import OpenCoreGraphics

func imageioDecodeBitmap(_ data: [UInt8]) -> Bitmap? {
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

func imageioEncodePNG(_ bitmap: Bitmap) -> [UInt8]? {
    imageioEncode(bitmap) { p, w, h, len in QZImageEncodePNG(p, w, h, len) }
}

func imageioEncodeJPEG(_ bitmap: Bitmap, quality: CGFloat) -> [UInt8]? {
    let q = Int32((max(0, min(1, quality)) * 100).rounded())
    return imageioEncode(bitmap) { p, w, h, len in
        QZImageEncodeJPEG(p, w, h, max(1, q), len)
    }
}

private func imageioEncode(
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
