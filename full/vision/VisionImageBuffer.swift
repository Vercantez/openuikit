import Foundation

/// RGBA8888 raster used by every classical Vision request on Linux.
/// Origin is top-left in pixel space; Vision normalized boxes use lower-left.
public struct VisionRaster: Equatable, Sendable {
    public var width: Int
    public var height: Int
    public var pixels: [UInt8]

    public init(width: Int, height: Int, pixels: [UInt8]) {
        self.width = max(0, width)
        self.height = max(0, height)
        let count = self.width * self.height * 4
        if pixels.count >= count {
            self.pixels = Array(pixels.prefix(count))
        } else {
            var padded = pixels
            padded.append(contentsOf: repeatElement(0, count: max(0, count - pixels.count)))
            self.pixels = padded
        }
    }

    public init(width: Int, height: Int, filled: (UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 255)) {
        self.width = max(0, width)
        self.height = max(0, height)
        var pixels = [UInt8](repeating: 0, count: self.width * self.height * 4)
        for index in stride(from: 0, to: pixels.count, by: 4) {
            pixels[index] = filled.0
            pixels[index + 1] = filled.1
            pixels[index + 2] = filled.2
            pixels[index + 3] = filled.3
        }
        self.pixels = pixels
    }

    public init(cgImage: CGImage) {
        self.init(width: cgImage.width, height: cgImage.height, pixels: cgImage.pixels)
    }

    public init(ciImage: CIImage) throws {
        guard let cgImage = ciImage.cgImage else {
            throw vnMakeError(.invalidImage, description: "CIImage has no CGImage backing")
        }
        self.init(cgImage: cgImage)
    }

    public init(pixelBuffer: CVPixelBuffer) {
        self.init(width: pixelBuffer.width, height: pixelBuffer.height, pixels: pixelBuffer.pixels)
    }

    public func makeCGImage() -> CGImage {
        CGImage(width: width, height: height, pixels: pixels)
    }

    public func makeCIImage() -> CIImage {
        CIImage(cgImage: makeCGImage())
    }

    public func makePixelBuffer() -> CVPixelBuffer {
        CVPixelBuffer(width: width, height: height, pixels: pixels)
    }

    public subscript(x: Int, y: Int) -> (UInt8, UInt8, UInt8, UInt8) {
        get {
            guard x >= 0, y >= 0, x < width, y < height else { return (0, 0, 0, 0) }
            let offset = (y * width + x) * 4
            return (pixels[offset], pixels[offset + 1], pixels[offset + 2], pixels[offset + 3])
        }
        set {
            guard x >= 0, y >= 0, x < width, y < height else { return }
            let offset = (y * width + x) * 4
            pixels[offset] = newValue.0
            pixels[offset + 1] = newValue.1
            pixels[offset + 2] = newValue.2
            pixels[offset + 3] = newValue.3
        }
    }

    public func grayAt(_ x: Int, _ y: Int) -> UInt8 {
        let pixel = self[x, y]
        let value = 0.299 * Double(pixel.0) + 0.587 * Double(pixel.1) + 0.114 * Double(pixel.2)
        return UInt8(max(0, min(255, value.rounded())))
    }

    public func grayscale() -> [UInt8] {
        var gray = [UInt8](repeating: 0, count: width * height)
        if width == 0 || height == 0 { return gray }
        for y in 0..<height {
            for x in 0..<width {
                gray[y * width + x] = grayAt(x, y)
            }
        }
        return gray
    }

    public func cropped(toNormalized roi: CGRect) -> VisionRaster {
        let rect = VNImageRectForNormalizedRect(roi, width, height)
        let minX = max(0, Int(rect.minX.rounded(.down)))
        let minYTop = height - max(0, Int(rect.maxY.rounded(.up)))
        let maxX = min(width, Int(rect.maxX.rounded(.up)))
        let maxYTop = height - min(height, Int(rect.minY.rounded(.down)))
        let cropWidth = max(1, maxX - minX)
        let cropHeight = max(1, maxYTop - minYTop)
        var cropped = VisionRaster(width: cropWidth, height: cropHeight)
        for y in 0..<cropHeight {
            for x in 0..<cropWidth {
                cropped[x, y] = self[minX + x, minYTop + y]
            }
        }
        return cropped
    }

    public func applying(orientation: CGImagePropertyOrientation) -> VisionRaster {
        switch orientation {
        case .up:
            return self
        case .down:
            return rotated180()
        case .left:
            return rotated90CCW()
        case .right:
            return rotated90CW()
        case .upMirrored:
            return flippedHorizontally()
        case .downMirrored:
            return rotated180().flippedHorizontally()
        case .leftMirrored:
            return rotated90CCW().flippedHorizontally()
        case .rightMirrored:
            return rotated90CW().flippedHorizontally()
        }
    }

    public func resized(width newWidth: Int, height newHeight: Int) -> VisionRaster {
        let dstW = max(1, newWidth)
        let dstH = max(1, newHeight)
        if dstW == width && dstH == height { return self }
        var output = VisionRaster(width: dstW, height: dstH)
        for y in 0..<dstH {
            let srcY = min(height - 1, Int((Double(y) + 0.5) * Double(height) / Double(dstH)))
            for x in 0..<dstW {
                let srcX = min(width - 1, Int((Double(x) + 0.5) * Double(width) / Double(dstW)))
                output[x, y] = self[srcX, srcY]
            }
        }
        return output
    }

    public func netpbmData() -> Data {
        let body = "P6\n\(width) \(height)\n255\n"
        var bytes = Array(body.utf8)
        bytes.reserveCapacity(bytes.count + width * height * 3)
        for y in 0..<height {
            for x in 0..<width {
                let pixel = self[x, y]
                bytes.append(pixel.0)
                bytes.append(pixel.1)
                bytes.append(pixel.2)
            }
        }
        return Data(bytes)
    }

    private func flippedHorizontally() -> VisionRaster {
        var output = VisionRaster(width: width, height: height)
        for y in 0..<height {
            for x in 0..<width {
                output[width - 1 - x, y] = self[x, y]
            }
        }
        return output
    }

    private func rotated180() -> VisionRaster {
        var output = VisionRaster(width: width, height: height)
        for y in 0..<height {
            for x in 0..<width {
                output[width - 1 - x, height - 1 - y] = self[x, y]
            }
        }
        return output
    }

    private func rotated90CW() -> VisionRaster {
        var output = VisionRaster(width: height, height: width)
        for y in 0..<height {
            for x in 0..<width {
                output[height - 1 - y, x] = self[x, y]
            }
        }
        return output
    }

    private func rotated90CCW() -> VisionRaster {
        var output = VisionRaster(width: height, height: width)
        for y in 0..<height {
            for x in 0..<width {
                output[y, width - 1 - x] = self[x, y]
            }
        }
        return output
    }
}

enum VisionImageCodec {
    static func decode(_ data: Data) throws -> VisionRaster {
        if data.isEmpty {
            throw vnMakeError(.invalidImage, description: "empty image data")
        }
        if let raster = decodeNetpbm(data) {
            return raster
        }
        if let raster = decodeVisionRaw(data) {
            return raster
        }
        throw vnMakeError(.invalidFormat, description: "unsupported image encoding")
    }

    static func decode(url: URL) throws -> VisionRaster {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw vnMakeError(.ioError, description: "cannot read image URL")
        }
        return try decode(data)
    }

    /// `VNR1` + little-endian UInt32 width/height + RGBA8888 pixels.
    static func encodeRaw(_ raster: VisionRaster) -> Data {
        var data = Data("VNR1".utf8)
        func appendU32(_ value: UInt32) {
            var le = value.littleEndian
            withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
        }
        appendU32(UInt32(raster.width))
        appendU32(UInt32(raster.height))
        data.append(contentsOf: raster.pixels)
        return data
    }

    private static func decodeVisionRaw(_ data: Data) -> VisionRaster? {
        guard data.count >= 12 else { return nil }
        let magic = data.prefix(4)
        guard magic == Data("VNR1".utf8) else { return nil }
        let width = data.subdata(in: 4..<8).withUnsafeBytes { $0.loadUnaligned(as: UInt32.self).littleEndian }
        let height = data.subdata(in: 8..<12).withUnsafeBytes { $0.loadUnaligned(as: UInt32.self).littleEndian }
        let count = Int(width) * Int(height) * 4
        guard data.count >= 12 + count else { return nil }
        let pixels = Array(data[12..<(12 + count)])
        return VisionRaster(width: Int(width), height: Int(height), pixels: pixels)
    }

    private static func decodeNetpbm(_ data: Data) -> VisionRaster? {
        guard data.count >= 3 else { return nil }
        guard data[0] == 0x50, data[1] == 0x31 || data[1] == 0x32 || data[1] == 0x33
                || data[1] == 0x34 || data[1] == 0x35 || data[1] == 0x36 else {
            return nil
        }
        let kind = data[1]
        if kind == 0x34 || kind == 0x35 || kind == 0x36 {
            return decodeNetpbmBinary(data, kind: kind)
        }
        return decodeNetpbmAscii(data, kind: kind)
    }

    private static func decodeNetpbmBinary(_ data: Data, kind: UInt8) -> VisionRaster? {
        var index = 2
        func skip() {
            while index < data.count {
                let byte = data[index]
                if byte == 0x23 {
                    while index < data.count, data[index] != 0x0a { index += 1 }
                } else if byte == 0x20 || byte == 0x09 || byte == 0x0a || byte == 0x0d {
                    index += 1
                } else {
                    break
                }
            }
        }
        func readToken() -> String? {
            skip()
            let start = index
            while index < data.count {
                let byte = data[index]
                if byte == 0x20 || byte == 0x09 || byte == 0x0a || byte == 0x0d { break }
                index += 1
            }
            guard index > start else { return nil }
            return String(bytes: data[start..<index], encoding: .ascii)
        }
        guard let widthToken = readToken(), let heightToken = readToken(),
              let width = Int(widthToken), let height = Int(heightToken) else {
            return nil
        }
        var maxValue = 1
        if kind != 0x34 {
            guard let maxToken = readToken(), let parsed = Int(maxToken) else { return nil }
            maxValue = max(1, parsed)
        }
        skip()
        if index < data.count, data[index] == 0x0a || data[index] == 0x0d { index += 1 }
        var raster = VisionRaster(width: width, height: height, filled: (0, 0, 0, 255))
        switch kind {
        case 0x34:
            let rowBytes = (width + 7) / 8
            guard data.count >= index + rowBytes * height else { return nil }
            for y in 0..<height {
                for x in 0..<width {
                    let byte = data[index + y * rowBytes + x / 8]
                    let bit = (byte >> (7 - (x % 8))) & 1
                    let value: UInt8 = bit == 0 ? 255 : 0
                    raster[x, y] = (value, value, value, 255)
                }
            }
        case 0x35:
            guard data.count >= index + width * height else { return nil }
            for y in 0..<height {
                for x in 0..<width {
                    let raw = data[index + y * width + x]
                    let value = UInt8(min(255, Int(raw) * 255 / maxValue))
                    raster[x, y] = (value, value, value, 255)
                }
            }
        default:
            guard data.count >= index + width * height * 3 else { return nil }
            for y in 0..<height {
                for x in 0..<width {
                    let offset = index + (y * width + x) * 3
                    let r = UInt8(min(255, Int(data[offset]) * 255 / maxValue))
                    let g = UInt8(min(255, Int(data[offset + 1]) * 255 / maxValue))
                    let b = UInt8(min(255, Int(data[offset + 2]) * 255 / maxValue))
                    raster[x, y] = (r, g, b, 255)
                }
            }
        }
        return raster
    }

    private static func decodeNetpbmAscii(_ data: Data, kind: UInt8) -> VisionRaster? {
        guard let text = String(data: data, encoding: .ascii) else { return nil }
        var tokens: [String] = []
        for line in text.split(whereSeparator: { $0 == "\n" || $0 == "\r" }) {
            let trimmed = line.split(separator: "#", maxSplits: 1).first ?? line[...]
            tokens.append(contentsOf: trimmed.split { $0.isWhitespace }.map(String.init))
        }
        guard tokens.count >= 3 else { return nil }
        guard let width = Int(tokens[1]), let height = Int(tokens[2]) else { return nil }
        var raster = VisionRaster(width: width, height: height, filled: (255, 255, 255, 255))
        var cursor = 3
        if kind != 0x31 {
            cursor += 1
        }
        func next() -> Int {
            guard cursor < tokens.count, let value = Int(tokens[cursor]) else { return 0 }
            cursor += 1
            return value
        }
        for y in 0..<height {
            for x in 0..<width {
                switch kind {
                case 0x31:
                    let bit = next()
                    let value: UInt8 = bit == 0 ? 255 : 0
                    raster[x, y] = (value, value, value, 255)
                case 0x32:
                    let value = UInt8(max(0, min(255, next())))
                    raster[x, y] = (value, value, value, 255)
                default:
                    let r = UInt8(max(0, min(255, next())))
                    let g = UInt8(max(0, min(255, next())))
                    let b = UInt8(max(0, min(255, next())))
                    raster[x, y] = (r, g, b, 255)
                }
            }
        }
        return raster
    }
}

public struct VisionImageContext {
    public let raster: VisionRaster
    public let orientation: CGImagePropertyOrientation
    public let options: [VNImageOption: Any]

    public var width: Int { raster.width }
    public var height: Int { raster.height }

    public func rasterForROI(_ roi: CGRect) -> VisionRaster {
        if VNNormalizedRectIsIdentityRect(roi) {
            return raster
        }
        return raster.cropped(toNormalized: roi)
    }
}

func visionPath(from points: [SIMD2<Float>]) -> CGPath {
    let path = CGPath()
    guard let first = points.first else { return path }
    path.move(to: CGPoint(x: Double(first.x), y: Double(first.y)))
    for point in points.dropFirst() {
        path.addLine(to: CGPoint(x: Double(point.x), y: Double(point.y)))
    }
    if points.count > 2 {
        path.closeSubpath()
    }
    return path
}

func visionNormalizedBox(
    minX: Double,
    minY: Double,
    maxX: Double,
    maxY: Double,
    width: Int,
    height: Int
) -> CGRect {
    let imageHeight = max(height, 1)
    // Pixel y is top-left; Vision normalized y is lower-left.
    let left = minX / Double(max(width, 1))
    let right = maxX / Double(max(width, 1))
    let bottom = 1 - maxY / Double(imageHeight)
    let top = 1 - minY / Double(imageHeight)
    return CGRect(x: left, y: bottom, width: max(0, right - left), height: max(0, top - bottom))
}

func visionNormalizedPoint(x: Double, y: Double, width: Int, height: Int) -> CGPoint {
    CGPoint(
        x: x / Double(max(width, 1)),
        y: 1 - y / Double(max(height, 1))
    )
}
