#if canImport(Glibc)
import Glibc
#endif
import Foundation
@_spi(OpenUIKitHost) import Vision

func visionExpect(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("VISION_AGENT_RUNTIME_FAIL \(message)\n", stderr)
        exit(1)
    }
}

func visionExpectEqual<T: Equatable>(_ lhs: T, _ rhs: T, _ message: String) {
    visionExpect(lhs == rhs, "\(message): \(lhs) != \(rhs)")
}

func visionRectangleImage() -> CGImage {
    var raster = VisionRaster(width: 80, height: 80, filled: (0, 0, 0, 255))
    for y in 20..<60 {
        for x in 20..<60 {
            raster[x, y] = (255, 255, 255, 255)
        }
    }
    return raster.makeCGImage()
}

func visionHorizonImage(slope: Double = 0.25) -> CGImage {
    var raster = VisionRaster(width: 80, height: 80, filled: (0, 0, 0, 255))
    for y in 0..<80 {
        for x in 0..<80 {
            if Double(y) < 20 + slope * Double(x) {
                raster[x, y] = (220, 220, 220, 255)
            }
        }
    }
    return raster.makeCGImage()
}

func visionUniformGrayImage() -> CGImage {
    VisionRaster(width: 80, height: 80, filled: (128, 128, 128, 255)).makeCGImage()
}

func visionTextLinesImage() -> CGImage {
    var raster = VisionRaster(width: 80, height: 80, filled: (255, 255, 255, 255))
    for y in 20..<26 {
        for x in 10..<70 {
            raster[x, y] = (10, 10, 10, 255)
        }
    }
    for y in 40..<46 {
        for x in 10..<55 {
            raster[x, y] = (10, 10, 10, 255)
        }
    }
    return raster.makeCGImage()
}

/// Deterministic pseudo-random grayscale texture (LCG, fixed seed) with an integer
/// wrap-around shift. Gives block-matching optical flow trackable texture everywhere.
func visionNoiseTextureImage(shiftX: Int = 0, shiftY: Int = 0, size: Int = 80) -> CGImage {
    let dimension = max(8, size)
    var seed: UInt64 = 0x1234_5678_9ABC_DEF1
    var base = [UInt8](repeating: 0, count: dimension * dimension)
    for index in 0..<base.count {
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        base[index] = UInt8((seed >> 33) & 0xFF)
    }
    var raster = VisionRaster(width: dimension, height: dimension, filled: (0, 0, 0, 255))
    for y in 0..<dimension {
        for x in 0..<dimension {
            let sx = ((x - shiftX) % dimension + dimension) % dimension
            let sy = ((y - shiftY) % dimension + dimension) % dimension
            let value = base[sy * dimension + sx]
            raster[x, y] = (value, value, value, 255)
        }
    }
    return raster.makeCGImage()
}

func visionExpectOverlayInvalidModel<T>(_ work: () throws -> T, _ message: String) {
    do {
        _ = try work()
        visionExpect(false, message + " should fail closed")
    } catch let error as VisionError {
        if case .invalidModel = error {
            visionExpect(true, message)
        } else {
            visionExpect(false, "\(message) unexpected \(error)")
        }
    } catch {
        visionExpect(false, "\(message) wrong type \(error)")
    }
}

func testHarnessRectangleImage() {
    let image = visionRectangleImage()
    visionExpect(image.width == 80 && image.height == 80, "harness raster")
}
