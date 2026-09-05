// Env-gated helper: dumps the pure-geometry portion of the corner_radius
// scene rendered by the OpenCoreGraphics rasterizer, for offline comparison
// against golden/corner_radius.png. Skipped unless RASTER_DUMP is set.
import XCTest
import Foundation
@testable import OpenCoreGraphics

private typealias CGColor = OpenCoreGraphics.CGColor

#if !os(Linux)
@MainActor
#endif
final class GoldenDumpTests: XCTestCase {
    func testDumpCornerRadiusGeometry() throws {
        guard let out = ProcessInfo.processInfo.environment["RASTER_DUMP"] else {
            throw XCTSkip("set RASTER_DUMP=<path.png> to dump")
        }
        // Reproduce corner_radius scene geometry (no text) at scale 2.
        let bmp = Bitmap(width: 640, height: 480)
        let c = Canvas(bitmap: bmp, scale: 2)
        // NOTE: golden/corner_radius.png has a transparent background (the
        // oracle does not paint the root background into the layer render),
        // so leave the background transparent for a direct RGBA comparison.
        func hex(_ r: Int, _ g: Int, _ b: Int) -> CGColor {
            CGColor(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, alpha: 1)
        }
        let blue = hex(0x19, 0x71, 0xC2)
        let red = hex(0xE0, 0x31, 0x31)
        let green = hex(0x2F, 0x9E, 0x44)
        func rr(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ rad: Double, _ col: CGColor) {
            c.fill(Path.roundedRect(OpenCoreGraphics.CGRect(x: x, y: y, width: w, height: h),
                                    cornerRadius: rad), color: col)
        }
        rr(16, 16, 80, 60, 4, blue)
        rr(112, 16, 80, 60, 12, blue)
        rr(208, 16, 80, 60, 30, blue)
        rr(16, 96, 80, 80, 40, red)
        rr(112, 96, 80, 40, 20, red)
        rr(208, 96, 80, 60, 100, green)
        let data = bmp.pngData()
        FileManager.default.createFile(atPath: out, contents: Data(data))
    }
}
