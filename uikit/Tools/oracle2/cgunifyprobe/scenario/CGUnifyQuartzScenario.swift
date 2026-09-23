// cgunifyprobe scenario, part 3: Core Animation is QuartzCore's
// (docs/agent_reports/cg-unify.md, phase 3). Same rules as
// CGUnifyScenario.swift: `import UIKit` only (UIKit re-exports QuartzCore),
// compiled against Apple's UIKit on the simulator and against OpenUIKit by
// CGUnifyTests.
#if canImport(CoreGraphics)
import UIKit

@MainActor
public func cgUnifyQuartzTranscript() -> [String] {
    var out: [String] = []
    let describe: (CGColor?) -> String = cgUnifyDescribe
    out.append("## quartzcore")
    out.append("classes \(NSStringFromClass(CALayer.self)) \(NSStringFromClass(CAGradientLayer.self)):\(NSStringFromClass(CAGradientLayer.superclass()!)) \(NSStringFromClass(CAShapeLayer.self)):\(NSStringFromClass(CAShapeLayer.superclass()!))")
    out.append("CATransform3DIsIdentity(CATransform3DIdentity) \(CATransform3DIsIdentity(CATransform3DIdentity))")
    out.append("CATransaction.animationDuration() \(CATransaction.animationDuration())")
    let shape = CAShapeLayer()
    out.append("CAShapeLayer fillColor \(describe(shape.fillColor)) lineWidth \(shape.lineWidth)")

    let standalone = CALayer()
    out.append("CALayer().needsLayout() \(standalone.needsLayout())")
    standalone.setValue(2.5, forKey: "ouk.arbitrary")
    out.append("arbitrary key \(standalone.value(forKey: "ouk.arbitrary") ?? "nil")")

    let view = UIView(frame: CGRect(x: 10, y: 20, width: 30, height: 40))
    out.append("view.layer.delegate === view \(view.layer.delegate === view) needsLayout \(view.layer.needsLayout())")
    out.append("view.layer bounds=\(view.layer.bounds) position=\(view.layer.position) frame=\(view.layer.frame)")
    view.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
    view.alpha = 0.5
    view.isHidden = true
    out.append("view -> layer backgroundColor \(describe(view.layer.backgroundColor)) opacity \(view.layer.opacity) hidden \(view.layer.isHidden)")
    view.layer.opacity = 0.25
    view.layer.isHidden = false
    view.layer.bounds = CGRect(x: 0, y: 0, width: 50, height: 60)
    view.layer.position = CGPoint(x: 100, y: 200)
    out.append("layer -> view alpha \(view.alpha) hidden \(view.isHidden) frame \(view.frame)")
    view.transform = CGAffineTransform(scaleX: 2, y: 3)
    out.append("view.transform -> layer.affineTransform \(cgUnifyDescribe(view.layer.affineTransform()))")
    view.transform = .identity

    let owner = CALayer()
    let mask = CALayer()
    owner.mask = mask
    out.append("mask.superlayer === owner \(mask.superlayer === owner) sublayers \(owner.sublayers?.count ?? 0)")

    out.append("## quartzcore render")
    let root = CALayer()
    root.frame = CGRect(x: 0, y: 0, width: 4, height: 2)
    root.backgroundColor = UIColor.red.cgColor
    let child = CALayer()
    child.frame = CGRect(x: 2, y: 0, width: 2, height: 1)
    child.backgroundColor = UIColor.blue.cgColor
    root.addSublayer(child)
    let hidden = CALayer()
    hidden.frame = CGRect(x: 0, y: 1, width: 1, height: 1)
    hidden.backgroundColor = UIColor.green.cgColor
    hidden.isHidden = true
    root.addSublayer(hidden)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let image = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 2), format: format).image { ctx in
        root.render(in: ctx.cgContext)
    }
    if let cg = image.cgImage {
        let px = cgUnifyPixels(cg)
        out.append("row0 \(cgUnifyRow(px, width: 4, y: 0))")
        out.append("row1 \(cgUnifyRow(px, width: 4, y: 1))")
    }
    return out
}
#endif
