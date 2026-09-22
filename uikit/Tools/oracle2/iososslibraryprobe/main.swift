// Members ios-oss Library needs (pass 3), read on a private iPhone 16 /
// iOS 26.1 (scripts/iososs_library_probe_sim.sh). One `key=value` per line.
import SwiftUI
import UIKit
import UserNotifications

func out(_ key: String, _ value: Any?) {
    if let value { print("\(key)=\(value)") } else { print("\(key)=nil") }
}

/// PaddingLabel's shape (Library PaddingLabel.swift).
final class InsetLabel: UILabel {
    var insets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    var drawTextRects: [CGRect] = []
    override func drawText(in rect: CGRect) {
        drawTextRects.append(rect)
        super.drawText(in: rect.inset(by: insets))
    }
}

final class PlainLabel: UILabel {
    var drawTextRects: [CGRect] = []
    override func drawText(in rect: CGRect) {
        drawTextRects.append(rect)
        super.drawText(in: rect)
    }
}

func inkBounds(_ image: UIImage) -> String {
    guard let cg = image.cgImage, let data = cg.dataProvider?.data, let p = CFDataGetBytePtr(data) else { return "?" }
    let w = cg.width, h = cg.height, bpr = cg.bytesPerRow
    var minX = w, minY = h, maxX = -1, maxY = -1
    for y in 0..<h { for x in 0..<w {
        let o = y * bpr + x * 4
        // any non-white pixel (label drawn black on white)
        if p[o] < 200 || p[o + 1] < 200 || p[o + 2] < 200 {
            minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
        }
    } }
    return maxX < 0 ? "none" : "x=\(minX)...\(maxX) y=\(minY)...\(maxY) scale=\(image.scale)"
}

@MainActor
func render(_ view: UIView) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 2
    format.opaque = true
    return UIGraphicsImageRenderer(size: view.bounds.size, format: format).image { ctx in
        UIColor.white.setFill()
        ctx.fill(view.bounds)
        view.layer.render(in: ctx.cgContext)
    }
}

@MainActor
func measure() {
    let v = UIView()
    out("view.maximumContentSizeCategory", v.maximumContentSizeCategory?.rawValue)
    out("view.minimumContentSizeCategory", v.minimumContentSizeCategory?.rawValue)
    v.maximumContentSizeCategory = .medium
    out("view.maximumContentSizeCategory.set", v.maximumContentSizeCategory?.rawValue)
    out("contentSizeCategory.medium", UIContentSizeCategory.medium.rawValue)
    out("vc.shouldAutomaticallyForwardAppearanceMethods", UIViewController().shouldAutomaticallyForwardAppearanceMethods)
    out("unAuthorizationStatus.raws", [UNAuthorizationStatus.notDetermined, .denied, .authorized, .provisional, .ephemeral].map(\.rawValue))

    for (name, label) in [("plain", PlainLabel(frame: CGRect(x: 0, y: 0, width: 120, height: 40))),
                          ("inset", InsetLabel(frame: CGRect(x: 0, y: 0, width: 120, height: 40)))] as [(String, UILabel)] {
        label.text = "Hi"
        label.font = .systemFont(ofSize: 17)
        label.textColor = .black
        label.backgroundColor = .white
        out("label.\(name).intrinsic", label.intrinsicContentSize)
        let img = render(label)
        out("label.\(name).ink", inkBounds(img))
        if let l = label as? PlainLabel { out("label.\(name).drawTextRects", l.drawTextRects) }
        if let l = label as? InsetLabel { out("label.\(name).drawTextRects", l.drawTextRects) }
    }
    out("text.truncationMode.raws", [Text.TruncationMode.head, .tail, .middle].map { "\($0)" })
}

MainActor.assumeIsolated { measure() }
print("done=1")
