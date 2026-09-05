import Foundation
import ImageIO

func imageioRequire(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

func imageioSampleImage() -> CGImage {
    let image = CGImage(width: 2, height: 1)
    image.pixels = [255, 0, 0, 255, 0, 255, 0, 255]
    return image
}

func imageioSolidImage(width: Int, height: Int, rgba: [UInt8]) -> CGImage {
    let image = CGImage(width: width, height: height)
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    for i in 0..<(width * height) {
        pixels[i * 4] = rgba[0]
        pixels[i * 4 + 1] = rgba[1]
        pixels[i * 4 + 2] = rgba[2]
        pixels[i * 4 + 3] = rgba[3]
    }
    image.pixels = pixels
    return image
}

func imageioGradient16x12() -> CGImage {
    let image = CGImage(width: 16, height: 12)
    var pixels = [UInt8](repeating: 0, count: 16 * 12 * 4)
    for y in 0..<12 {
        for x in 0..<16 {
            let i = (y * 16 + x) * 4
            pixels[i] = UInt8(min(255, x * 16))
            pixels[i + 1] = UInt8(min(255, y * 20))
            pixels[i + 2] = 128
            pixels[i + 3] = 255
        }
    }
    image.pixels = pixels
    return image
}

func imageioEncodedSample(_ type: CFString) -> Data {
    let data = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(data, type, 1, nil) else {
        fatalError("destination \(type)")
    }
    CGImageDestinationAddImage(dest, imageioSampleImage(), nil)
    imageioRequire(CGImageDestinationFinalize(dest), "finalize \(type)")
    return data as Data
}

func imageioFixtureData(_ name: String) -> Data {
    let here = URL(fileURLWithPath: #filePath)
    let url = here.deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("fixtures")
        .appendingPathComponent(name)
    guard let data = try? Data(contentsOf: url) else {
        fatalError("missing fixture \(name) at \(url.path)")
    }
    return data
}

func imageioMaxPixelDelta(_ left: CGImage, _ right: CGImage) -> Int {
    imageioRequire(left.width == right.width && left.height == right.height, "size")
    var maxDelta = 0
    let count = min(left.pixels.count, right.pixels.count)
    var i = 0
    while i < count {
        let d = abs(Int(left.pixels[i]) - Int(right.pixels[i]))
        if d > maxDelta { maxDelta = d }
        i += 1
    }
    return maxDelta
}

func imageioInt(_ value: Any?) -> Int? {
    if let n = value as? Int { return n }
    if let n = value as? Int32 { return Int(n) }
    if let n = value as? UInt32 { return Int(n) }
    if let n = value as? NSNumber { return n.intValue }
    return nil
}

func imageioDouble(_ value: Any?) -> Double? {
    if let n = value as? Double { return n }
    if let n = value as? Int { return Double(n) }
    if let n = value as? NSNumber { return n.doubleValue }
    return nil
}
