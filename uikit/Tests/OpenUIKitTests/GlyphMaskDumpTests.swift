// Text-module tooling test: dumps 4x-supersampled instanced glyph masks for
// offline filter fitting (writes to the session scratch dir when the
// OPENUIKIT_DUMP_DIR environment variable is set; skipped otherwise).
import Foundation
import XCTest
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
final class GlyphMaskDumpTests: XCTestCase {

    func testDumpMasks() throws {
        guard let dir = ProcessInfo.processInfo.environment["OPENUIKIT_DUMP_DIR"] else {
            throw XCTSkip("no dump dir")
        }
        let env = ProcessInfo.processInfo.environment
        let gradOverride = env["OPENUIKIT_DUMP_GRAD"].flatMap(Double.init)
        let wghtOverride = env["OPENUIKIT_DUMP_WGHT"].flatMap(Double.init)
        var meta: [[String: Any]] = []
        let sizes = env["OPENUIKIT_DUMP_SIZES"].map {
            $0.split(separator: ",").compactMap { Double($0) }
        } ?? [17.0, 34.0]
        for size in sizes {
            let uifont = UIFont.systemFont(ofSize: CGFloat(size))
            guard var inst = GlyphRasterizer.font(for: uifont) else {
                throw XCTSkip("no system font")
            }
            if gradOverride != nil || wghtOverride != nil,
               let vars = inst.font.variations {
                var user: [UInt32: Double] = [
                    GlyphRasterizer.tag("wght"): wghtOverride ?? 400,
                    GlyphRasterizer.tag("opsz"): size,
                ]
                if let g = gradOverride { user[GlyphRasterizer.tag("GRAD")] = g }
                let coords = vars.normalizedCoords(user)
                let key = inst.font.registerCoords(coords)
                inst = InstancedGlyphFont(font: inst.font, coordsKey: key)
            }
            for ch in (env["OPENUIKIT_DUMP_GLYPHS"] ?? "HoxnS08Mge") {
                let g = inst.glyphIndex(of: ch.unicodeScalars.first!)
                guard g != 0,
                      let bmp = inst.rasterize(glyph: g, pixelSize: CGFloat(size) * 2 * 4,
                                               shiftX: 0, shiftY: 0) else { continue }
                let name = "mask_\(Int(size))_\(ch.unicodeScalars.first!.value).bin"
                let url = URL(fileURLWithPath: dir + "/" + name)
                try Data(bmp.mask).write(to: url)
                meta.append(["size": size, "ch": String(ch), "file": name,
                             "w": bmp.width, "h": bmp.height,
                             "offx": bmp.offsetX, "offy": bmp.offsetY])
            }
        }
        let data = try JSONSerialization.data(withJSONObject: meta, options: [.prettyPrinted])
        try data.write(to: URL(fileURLWithPath: dir + "/masks_meta.json"))
        print("dumped \(meta.count) masks")
    }
}
