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
