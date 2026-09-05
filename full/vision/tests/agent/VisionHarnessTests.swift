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

func visionWaitFor<T>(_ work: @escaping () async throws -> T) -> T {
    let lock = DispatchSemaphore(value: 0)
    var stored: Result<T, Error>?
    Task {
        do {
            stored = .success(try await work())
        } catch {
            stored = .failure(error)
        }
        lock.signal()
    }
    lock.wait()
    return try! stored!.get()
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

func testHarnessRectangleImage() {
    let image = visionRectangleImage()
    visionExpect(image.width == 80 && image.height == 80, "harness raster")
}
