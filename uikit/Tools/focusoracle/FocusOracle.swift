// Observation-only harness, compiled beside unmodified Blockzilla by xcodebuild.
import UIKit
import Onboarding

@_cdecl("FocusOracleStart")
func focusOracleStart() {
    let shown: Set<ToolTipRoute> = [.onboarding(.v1), .onboarding(.v2), .searchBar, .menu]
    UserDefaults.standard.set(try! JSONEncoder().encode(shown), forKey: OnboardingConstants.shownTips)
    UserDefaults.standard.set(true, forKey: OnboardingConstants.onboardingDidAppear)
    UserDefaults.standard.set(true, forKey: OnboardingConstants.showOldOnboarding)
    // Mirror FocusBrowserLaunch.prepareReturningUserDefaults, before UIApplicationMain.
    NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
        // The real app focuses its URL field on launch. Exercise the app's
        // Cancel control to capture the requested keyboard-dismissed home.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            guard let window = (UIApplication.shared.delegate as? AppDelegate)?.window else { return }
            func cancel(_ view: UIView) {
                if let button = view as? UIButton, button.accessibilityIdentifier == "URLBar.cancelButton" {
                    button.sendActions(for: .touchUpInside)
                }
                for child in view.subviews { cancel(child) }
            }
            cancel(window)
        }
        for seconds in [3.0, 4.0, 5.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { captureFocus(seconds) }
        }
    }
}

private func rect(_ r: CGRect) -> [Double] {
    [r.minX, r.minY, r.width, r.height].map { (Double($0)*1000).rounded()/1000 }
}
private func dump(_ v: UIView, path: String, window: UIWindow, rows: inout [[String: Any]]) {
    let p = v.layer.presentation()
    var row: [String: Any] = ["path": path, "class": String(describing: type(of: v)),
        "frame": rect(v.frame), "abs": rect(v.convert(v.bounds, to: window)),
        "bounds": rect(v.bounds), "accessibilityIdentifier": v.accessibilityIdentifier ?? "", "pframe": rect(p?.frame ?? v.layer.frame),
        "pbounds": rect(p?.bounds ?? v.layer.bounds), "alpha": v.alpha,
        "popacity": p?.opacity ?? v.layer.opacity, "hidden": v.isHidden,
        "animationKeys": v.layer.animationKeys() ?? [],
        "playing": p.map { $0.frame != v.layer.frame || $0.bounds != v.layer.bounds || $0.opacity != v.layer.opacity } ?? false]
    let sa = v.safeAreaInsets
    row["safeAreaInsets"] = [sa.top, sa.left, sa.bottom, sa.right]
    if let label = v as? UILabel { row["text"] = label.text; row["font"] = [label.font.fontName, label.font.pointSize] }
    if let field = v as? UITextField { row["text"] = field.text; row["placeholder"] = field.placeholder; row["firstResponder"] = field.isFirstResponder }
    rows.append(row)
    for (i, child) in v.subviews.enumerated() { dump(child, path: path.isEmpty ? "\(i)" : "\(path).\(i)", window: window, rows: &rows) }
}

private func captureFocus(_ seconds: Double) {
    guard let window = (UIApplication.shared.delegate as? AppDelegate)?.window else { return }
    let name = "realapp_focus_browser_light.t\(Int(seconds*1000))"
    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let format = UIGraphicsImageRendererFormat()
    format.scale = window.screen.scale
    format.opaque = true
    format.preferredRange = .extended
    let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
        window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
    }
    try! normalizedSRGB(image).pngData()!.write(to: docs.appendingPathComponent(name+".png"))
    // AFTER capture; compare presentation to the model LAYER, not UIView.frame
    // (keyboard-fidelity/confprobe convention: UIButtonLabel may differ at rest).
    var rows: [[String: Any]] = []
    dump(window, path: "", window: window, rows: &rows)
    let payload: [String: Any] = ["name": "realapp_focus_browser_light", "captureSecondsAfterActive": seconds,
        "screen": ["width":window.bounds.width, "height":window.bounds.height, "scale":window.screen.scale], "views":rows]
    try! JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]).write(to: docs.appendingPathComponent(name+".layout.json"))
    if seconds == 5 { try! Data("done".utf8).write(to: docs.appendingPathComponent("DONE")) }
}

// Same straight-alpha sRGB encoding as confprobe.
func normalizedSRGB(_ img: UIImage) -> UIImage {
    guard let cg = img.cgImage else { return img }
    let w = cg.width, h = cg.height
    var premul = [UInt8](repeating: 0, count: w * h * 4)
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    guard let ctx = CGContext(data: &premul, width: w, height: h, bitsPerComponent: 8,
                              bytesPerRow: w * 4, space: space,
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return img }
    ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
    var straight = [UInt8](repeating: 0, count: w * h * 4)
    for i in 0..<(w * h) {
        let a = Int(premul[i * 4 + 3])
        if a == 0 { continue }
        for c in 0..<3 {
            let v = Int(premul[i * 4 + c]) * 255 + a / 2
            straight[i * 4 + c] = UInt8(min(255, v / a))
        }
        straight[i * 4 + 3] = UInt8(a)
    }
    let data = Data(straight)
    guard let provider = CGDataProvider(data: data as CFData),
          let out = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32,
                            bytesPerRow: w * 4, space: space,
                            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                            provider: provider, decode: nil, shouldInterpolate: false,
                            intent: .defaultIntent) else { return img }
    return UIImage(cgImage: out, scale: img.scale, orientation: .up)
}

