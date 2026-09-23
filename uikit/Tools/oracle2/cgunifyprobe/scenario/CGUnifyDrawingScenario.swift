// cgunifyprobe scenario, part 2: drawing through UIKit's current CGContext
// and UIImage <-> CGImage (docs/agent_reports/cg-unify.md). Same rules as
// ../scenario/CGUnifyScenario.swift: `import UIKit` only, compiled against
// Apple's UIKit on the simulator and against OpenUIKit by CGUnifyTests.
#if canImport(CoreGraphics)
import UIKit

final class CGUnifyProbeDrawView: UIView {
    var log: [String] = []
    override func draw(_ rect: CGRect) {
        guard let cg = UIGraphicsGetCurrentContext() else { log.append("draw ctx=nil"); return }
        log.append("draw rect=\(rect) clip=\(cg.boundingBoxOfClipPath)")
        UIColor.red.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 1, height: 1))
        cg.setFillColor(UIColor.blue.cgColor)
        cg.fill(CGRect(x: 1, y: 0, width: 1, height: 1))
        UIRectFill(CGRect(x: 2, y: 0, width: 1, height: 1))
        UIBezierPath(rect: CGRect(x: 3, y: 0, width: 1, height: 1)).fill()
        cg.saveGState()
        cg.translateBy(x: 0, y: 1)
        UIColor.green.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 1, height: 1))
        cg.restoreGState()
        UIRectFill(CGRect(x: 1, y: 1, width: 1, height: 1))
        cg.setStrokeColor(UIColor.black.cgColor)
        cg.setLineWidth(1)
        cg.move(to: CGPoint(x: 2, y: 1.5))
        cg.addLine(to: CGPoint(x: 4, y: 1.5))
        cg.strokePath()
    }
}

@MainActor
public func cgUnifyDrawingTranscript() -> [String] {
    var out: [String] = []
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1

    out.append("## renderer context")
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 2), format: format)
    var contextLines: [String] = []
    let image = renderer.image { ctx in
        let cg: CGContext = ctx.cgContext
        contextLines.append("same-as-current \(cg === UIGraphicsGetCurrentContext())")
        contextLines.append("ctm=\(cgUnifyDescribe(cg.ctm)) clip=\(cg.boundingBoxOfClipPath)")
        UIColor.red.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 1, height: 1))
        cg.setFillColor(UIColor.blue.cgColor)
        cg.fill(CGRect(x: 1, y: 0, width: 1, height: 1))
        UIRectFill(CGRect(x: 2, y: 0, width: 1, height: 1))
        UIBezierPath(rect: CGRect(x: 3, y: 0, width: 1, height: 1)).fill()
        cg.saveGState()
        cg.translateBy(x: 0, y: 1)
        contextLines.append("translated ctm=\(cgUnifyDescribe(cg.ctm))")
        UIColor.green.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 1, height: 1))
        cg.restoreGState()
        UIRectFill(CGRect(x: 1, y: 1, width: 1, height: 1))
        ctx.fill(CGRect(x: 2, y: 1, width: 1, height: 1))
    }
    out += contextLines
    if let cgImage = image.cgImage {
        let px = cgUnifyPixels(cgImage)
        out.append("image \(cgImage.width)x\(cgImage.height) scale=\(image.scale)")
        out.append("row0 \(cgUnifyRow(px, width: 4, y: 0))")
        out.append("row1 \(cgUnifyRow(px, width: 4, y: 1))")
    } else {
        out.append("image.cgImage nil")
    }

    out.append("## draw(_:)")
    let dv = CGUnifyProbeDrawView(frame: CGRect(x: 0, y: 0, width: 4, height: 2))
    dv.backgroundColor = .white
    dv.contentScaleFactor = 1
    let drawn = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 2), format: format).image { ctx in
        dv.layer.render(in: ctx.cgContext)
    }
    out += dv.log
    if let cgImage = drawn.cgImage {
        let px = cgUnifyPixels(cgImage)
        out.append("row0 \(cgUnifyRow(px, width: 4, y: 0))")
        out.append("row1 \(cgUnifyRow(px, width: 4, y: 1))")
    }

    out.append("## uiimage cgImage")
    let solid = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 1), format: format).image { _ in
        UIColor(red: 1, green: 0, blue: 0, alpha: 0.5).setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 1, height: 1))
    }
    if let cg = solid.cgImage {
        out.append("cgImage \(cg.width)x\(cg.height) bpc=\(cg.bitsPerComponent) bpp=\(cg.bitsPerPixel)")
        out.append("pixels \(cgUnifyRow(cgUnifyPixels(cg), width: 2, y: 0))")
        let back = UIImage(cgImage: cg)
        out.append("UIImage(cgImage:) size=\(back.size) scale=\(back.scale)")
        let back2 = UIImage(cgImage: cg, scale: 2, orientation: .up)
        out.append("UIImage(cgImage:scale:2) size=\(back2.size) scale=\(back2.scale)")
        if let cg2 = back.cgImage { out.append("round trip pixels \(cgUnifyRow(cgUnifyPixels(cg2), width: 2, y: 0))") }
    }
    return out
}
#endif
