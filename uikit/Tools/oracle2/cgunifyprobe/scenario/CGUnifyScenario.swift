// cgunifyprobe scenario, part 1: CoreGraphics types and UIKit's re-exports
// (docs/agent_reports/cg-unify.md).
//
// The SAME file is compiled for the iOS 26.1 simulator against Apple's UIKit
// (../run.sh writes ../transcript-ios26.1.txt) and against OpenUIKit as the
// SwiftPM target `OpenUIKitCGUnifyFixtures` (Tests/CGUnifyTests replays it and
// compares). It imports UIKit ONLY: every CoreGraphics and ImageIO name below
// has to arrive through UIKit's re-exports, as on iOS. Apple toolchains only:
// without CoreGraphics (Linux) the port's own types stay.
#if canImport(CoreGraphics)
import UIKit

public func cgUnifyFormat(_ v: CGFloat) -> String {
    let r = (v * 1_000_000).rounded() / 1_000_000
    return r == 0 ? "0" : "\(r)"
}

public func cgUnifyDescribe(_ c: CGColor?) -> String {
    guard let c else { return "nil" }
    let space = c.colorSpace.flatMap { $0.name.map { $0 as String } } ?? "?"
    let model: String
    switch c.colorSpace?.model {
    case .monochrome?: model = "gray"
    case .rgb?: model = "rgb"
    default: model = "other"
    }
    let comps = (c.components ?? []).map(cgUnifyFormat).joined(separator: " ")
    return "model=\(model) n=\(c.numberOfComponents) [\(comps)] space=\(space.replacingOccurrences(of: "kCGColorSpace", with: ""))"
}

public func cgUnifyDescribe(_ t: CGAffineTransform) -> String {
    let f = cgUnifyFormat
    return "[\(f(t.a)) \(f(t.b)) \(f(t.c)) \(f(t.d)) \(f(t.tx)) \(f(t.ty))]"
}

/// RGBA8 pixels of a CGImage, drawn 1:1 with Apple's CoreGraphics into a
/// premultiplied sRGB context.
public func cgUnifyPixels(_ image: CGImage) -> [UInt8] {
    let w = image.width, h = image.height
    var out = [UInt8](repeating: 0, count: w * h * 4)
    out.withUnsafeMutableBytes { raw in
        let ctx = CGContext(data: raw.baseAddress, width: w, height: h, bitsPerComponent: 8,
                            bytesPerRow: w * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setBlendMode(.copy)
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
    }
    return out
}

public func cgUnifyRow(_ px: [UInt8], width: Int, y: Int) -> String {
    (0..<width).map { x in
        let i = (y * width + x) * 4
        return "\(px[i]),\(px[i + 1]),\(px[i + 2]),\(px[i + 3])"
    }.joined(separator: " ")
}

@MainActor
public func cgUnifyTypesTranscript() -> [String] {
    var out: [String] = []
    let describe: (CGColor?) -> String = cgUnifyDescribe
    out.append("## color")
    let colors: [(String, UIColor)] = [
        ("red", .red), ("white", .white), ("clear", .clear), ("black", .black),
        ("rgb(0.2,0.4,0.6,0.8)", UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.8)),
        ("white(0.5,1)", UIColor(white: 0.5, alpha: 1)),
        ("rgb(1.2,-0.1,0.5,1)", UIColor(red: 1.2, green: -0.1, blue: 0.5, alpha: 1)),
    ]
    for (name, color) in colors {
        out.append("\(name).cgColor \(describe(color.cgColor))")
    }
    let gray = CGColor(gray: 0.25, alpha: 0.5)
    out.append("UIColor(cgColor: gray 0.25/0.5).cgColor \(describe(UIColor(cgColor: gray).cgColor))")
    let srgb = CGColor(srgbRed: 0.1, green: 0.2, blue: 0.3, alpha: 1)
    out.append("UIColor(cgColor: srgb).cgColor \(describe(UIColor(cgColor: srgb).cgColor))")
    out.append("UIColor(cgColor: srgb) == UIColor(red:0.1,…) \(UIColor(cgColor: srgb) == UIColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 1))")
    out.append("UIColor(cgColor: red.cgColor) == red \(UIColor(cgColor: UIColor.red.cgColor) == UIColor.red)")

    out.append("## layer")
    let layer = CALayer()
    out.append("CALayer().backgroundColor \(describe(layer.backgroundColor))")
    out.append("CALayer().borderColor \(describe(layer.borderColor))")
    out.append("CALayer().shadowColor \(describe(layer.shadowColor))")
    layer.backgroundColor = srgb
    out.append("backgroundColor = srgb -> \(describe(layer.backgroundColor)) same-object \(layer.backgroundColor === srgb)")
    let view = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: 4))
    view.backgroundColor = UIColor(white: 0.5, alpha: 1)
    out.append("view(white 0.5).layer.backgroundColor \(describe(view.layer.backgroundColor))")
    view.layer.backgroundColor = UIColor.red.cgColor
    out.append("view.layer.backgroundColor = red -> view.backgroundColor \(describe(view.backgroundColor?.cgColor))")
    let gradient = CAGradientLayer()
    gradient.colors = [UIColor.red.cgColor, srgb]
    let read = (gradient.colors as? [CGColor]) ?? []
    out.append("gradient.colors \(read.map(describe).joined(separator: " | "))")

    out.append("## transform")
    out.append("rotation(pi/2) \(cgUnifyDescribe(CGAffineTransform(rotationAngle: .pi / 2)))")
    out.append("rotation(pi/6) \(cgUnifyDescribe(CGAffineTransform(rotationAngle: .pi / 6)))")
    let t = CGAffineTransform(translationX: 10, y: 20).scaledBy(x: 2, y: 3).rotated(by: .pi / 4)
    out.append("translate(10,20).scaled(2,3).rotated(pi/4) \(cgUnifyDescribe(t))")
    out.append("inverted \(cgUnifyDescribe(t.inverted()))")
    out.append("point(1,1).applying \(CGPoint(x: 1, y: 1).applying(t))")
    out.append("rect(0,0,10,10).applying \(CGRect(x: 0, y: 0, width: 10, height: 10).applying(t))")
    let view2 = UIView(frame: CGRect(x: 10, y: 10, width: 40, height: 20))
    view2.transform = CGAffineTransform(scaleX: 2, y: 2)
    out.append("view.transform=scale2 frame=\(view2.frame) transform=\(cgUnifyDescribe(view2.transform))")
    out.append("identity.isIdentity \(CGAffineTransform.identity.isIdentity)")

    out.append("## path")
    func elements(_ path: CGPath) -> String {
        var kinds: [String] = []
        path.applyWithBlock { element in
            let e = element.pointee
            switch e.type {
            case .moveToPoint: kinds.append("m\(e.points[0])")
            case .addLineToPoint: kinds.append("l\(e.points[0])")
            case .addQuadCurveToPoint: kinds.append("q\(e.points[1])")
            case .addCurveToPoint: kinds.append("c\(e.points[2])")
            case .closeSubpath: kinds.append("z")
            @unknown default: kinds.append("?")
            }
        }
        return kinds.joined(separator: " ")
    }
    let rectPath = UIBezierPath(rect: CGRect(x: 1, y: 2, width: 3, height: 4))
    out.append("rect.cgPath \(elements(rectPath.cgPath))")
    out.append("oval.cgPath \(elements(UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 4, height: 2)).cgPath))")
    let ellipse = CGPath(ellipseIn: CGRect(x: 0, y: 0, width: 4, height: 2), transform: nil)
    let wrapped = UIBezierPath(cgPath: ellipse)
    out.append("UIBezierPath(cgPath: ellipse).bounds \(wrapped.bounds) same-elements \(elements(wrapped.cgPath) == elements(ellipse))")
    let line = UIBezierPath()
    line.move(to: CGPoint(x: 0, y: 0))
    line.addLine(to: CGPoint(x: 5, y: 5))
    line.cgPath = CGPath(rect: CGRect(x: 0, y: 0, width: 2, height: 2), transform: nil)
    out.append("cgPath = rect -> bounds \(line.bounds) elements \(elements(line.cgPath))")

    out.append("## bitmap context")
    if let ctx = CGContext(data: nil, width: 2, height: 2, bitsPerComponent: 8, bytesPerRow: 0,
                           space: CGColorSpaceCreateDeviceRGB(),
                           bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue).rawValue) {
        ctx.setFillColor(UIColor.red.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 2))
        if let made = ctx.makeImage() {
            out.append("makeImage \(made.width)x\(made.height) row0 \(cgUnifyRow(cgUnifyPixels(made), width: 2, y: 0))")

            out.append("## imageio")
            let data = NSMutableData()
            if let dest = CGImageDestinationCreateWithData(data as CFMutableData, "public.png" as CFString, 1, nil) {
                CGImageDestinationAddImage(dest, made, nil)
                out.append("destination finalize \(CGImageDestinationFinalize(dest))")
            }
            if let src = CGImageSourceCreateWithData(data as CFData, nil) {
                out.append("source count=\(CGImageSourceGetCount(src)) type=\(CGImageSourceGetType(src).map { $0 as String } ?? "nil")")
                if let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any] {
                    out.append("pixelWidth=\(props[kCGImagePropertyPixelWidth] ?? "nil") pixelHeight=\(props[kCGImagePropertyPixelHeight] ?? "nil")")
                }
                let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
                                                kCGImageSourceThumbnailMaxPixelSize: 1,
                                                kCGImageSourceCreateThumbnailWithTransform: true]
                let thumb = CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary)
                out.append("thumbnail \(thumb.map { "\($0.width)x\($0.height)" } ?? "nil")")
            }
        }
    }
    return out
}
#endif
