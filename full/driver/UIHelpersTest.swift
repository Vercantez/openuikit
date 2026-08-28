// UIHelpersTest.swift -- execute the OpenUIKit surfaces used by Focus's real
// 11-source UIHelpers package against the Foundation-invisible OpenUIKit
// module in an arm64 Mach-O guest. The package itself is compiled separately
// by the Focus census. This is deliberately behavioral: compile-only coverage
// would not catch broken state fallback, layer ordering, graphics-context
// restoration, animation interruption, or the delegate-window bridge.

import OpenUIKit

private func uiHelpersCheck(_ condition: @autoclosure () -> Bool,
                            _ label: String) -> Bool {
    let passed = condition()
    print("  \(label): \(passed ? "PASS" : "FAIL")")
    return passed
}

@MainActor
private final class UIHelpersWindowDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
}

@MainActor
private final class UIHelpersWindowlessDelegate: UIResponder, UIApplicationDelegate {}

@MainActor
func uiHelpersSelfTest() -> Bool {
    var ok = true

    // Objective-C's optional UIApplicationDelegate.window requirement becomes
    // two optional layers through an existential. Exercise reflection at run
    // time: this is the path a Focus source expression ending in `window??`
    // actually takes.
    let concrete = UIHelpersWindowDelegate()
    let delegate: any UIApplicationDelegate = concrete
    if case .some(.none) = delegate.window {
        ok = uiHelpersCheck(true, "delegate stored-nil keeps outer optional") && ok
    } else {
        ok = uiHelpersCheck(false, "delegate stored-nil keeps outer optional") && ok
    }
    concrete.window = UIWindow(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
    ok = uiHelpersCheck(delegate.window! === concrete.window,
                        "delegate reflection recovers window identity") && ok
    let windowless: any UIApplicationDelegate = UIHelpersWindowlessDelegate()
    ok = uiHelpersCheck(windowless.window == nil,
                        "windowless delegate keeps outer optional nil") && ok

    let normal = UIImage(bitmap: Bitmap(width: 10, height: 6))
    let highlighted = UIImage(bitmap: Bitmap(width: 14, height: 8))
    let selected = UIImage(bitmap: Bitmap(width: 12, height: 7))
    let button = UIButton(type: .system)
    button.setImage(normal, for: .normal)
    button.setImage(highlighted, for: .highlighted)
    button.setImage(selected, for: .selected)
    button.setTitle("Go", for: .normal)
    button.sizeToFit()
    button.layoutIfNeeded()
    ok = uiHelpersCheck(button.currentImage === normal
                        && button.imageView?.image === normal
                        && button.frame.size == CGSize(width: 30, height: 31)
                        && button.imageView?.frame == CGRect(x: 0, y: 12.5,
                                                            width: 10, height: 6)
                        && button.titleLabel?.frame == CGRect(x: 10, y: 6,
                                                              width: 20, height: 19),
                        "button image state and measured layout") && ok
    button.isHighlighted = true
    ok = uiHelpersCheck(button.currentImage === highlighted
                        && button.imageView?.image === highlighted,
                        "highlighted button selects exact-state image") && ok
    button.isHighlighted = false
    button.isSelected = true
    ok = uiHelpersCheck(button.currentImage === selected
                        && button.imageView?.image === selected,
                        "selected button selects exact-state image") && ok
    button.isHighlighted = true
    ok = uiHelpersCheck(button.currentImage === normal
                        && button.imageView?.image === normal,
                        "combined button state falls back to normal") && ok

    OpenUIKitRuntime.renderBackend = .swift
    OpenUIKitRuntime.compositor = .renderPass
    let layerView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 12))
    layerView.backgroundColor = .white
    let gradient = CAGradientLayer()
    gradient.frame = layerView.bounds
    gradient.colors = [UIColor.red.cgColor, UIColor.blue.cgColor]
    gradient.startPoint = CGPoint(x: 0, y: 0.5)
    gradient.endPoint = CGPoint(x: 1, y: 0.5)
    layerView.layer.insertSublayer(gradient, at: 0)
    let child = UIView(frame: CGRect(x: 15, y: 2, width: 10, height: 8))
    child.backgroundColor = .green
    layerView.addSubview(child)
    let layered = UIRenderer.render(layerView, scale: 1)
    func pixel(_ bitmap: Bitmap, _ x: Int, _ y: Int) -> [UInt8] {
        let offset = (y * bitmap.width + x) * 4
        return Array(bitmap.pixels[offset..<(offset + 4)])
    }
    let left = pixel(layered, 1, 6)
    let right = pixel(layered, 38, 6)
    ok = uiHelpersCheck(left[0] > left[2] && right[2] > right[0]
                        && pixel(layered, 20, 6) == [0, 255, 0, 255],
                        "gradient order beneath UIView child") && ok
    let attachedGradients = layerView.layer.sublayers?.compactMap {
        $0 as? CAGradientLayer
    } ?? []
    attachedGradients.forEach { $0.removeFromSuperlayer() }
    ok = uiHelpersCheck(attachedGradients.count == 1
                        && attachedGradients.first === gradient
                        && layerView.layer.sublayers == nil
                        && pixel(UIRenderer.render(layerView, scale: 1), 1, 6)
                           == [255, 255, 255, 255],
                        "gradient lookup and removal change output") && ok

    OpenUIKitRuntime.imageScreenScale = 2
    UIGraphicsBeginImageContextWithOptions(CGSize(width: 2, height: 1), false, 0)
    let outerContext = UIGraphicsGetCurrentContext()
    outerContext?.fill(
        rect: CGRect(x: 0, y: 0, width: 2, height: 1), color: UIColor.red.cgColor)

    UIGraphicsBeginImageContextWithOptions(CGSize(width: 1, height: 1), false, 1)
    let innerContext = UIGraphicsGetCurrentContext()
    let iconView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
    iconView.backgroundColor = .green
    if let innerContext { iconView.layer.render(in: innerContext) }
    let icon = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    let restoredOuterContext = UIGraphicsGetCurrentContext()
    let legacy = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    ok = uiHelpersCheck(legacy?.scale == 2
                        && legacy?.bitmap.width == 4
                        && legacy?.bitmap.height == 2
                        && legacy.map { pixel($0.bitmap, 2, 1) } == [255, 0, 0, 255]
                        && icon.map { pixel($0.bitmap, 0, 0) } == [0, 255, 0, 255]
                        && innerContext !== outerContext
                        && restoredOuterContext === outerContext
                        && UIGraphicsGetCurrentContext() == nil,
                        "nested legacy contexts restore and layer.render paints") && ok

    let translucentBitmap = Bitmap(width: 1, height: 1)
    translucentBitmap.pixels = [240, 80, 20, 128]
    let translucent = UIImage(bitmap: translucentBitmap)
    OpenUIKitRuntime.renderBackend = .quartz
    let format = UIGraphicsImageRendererFormat(scale: 1)
    let alphaImage = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1),
                                             format: format).image { _ in
        translucent.draw(at: .zero, blendMode: .normal, alpha: 0.5)
    }
    ok = uiHelpersCheck(alphaImage.bitmap.pixels == [239, 80, 20, 64],
                        "image draw applies global alpha once") && ok

    let animationWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
    let animated = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    animationWindow.addSubview(animated)
    var completions: [String] = []
    OpenUIKitRuntime.animationTime = 0
    UIView.transition(with: animated, duration: 1,
                      options: [.beginFromCurrentState, .curveLinear],
                      animations: { animated.alpha = 0 },
                      completion: { completions.append("old:\($0)") })
    OpenUIKitRuntime.animationTime = 0.4
    UIView.transition(with: animated, duration: 0.5,
                      options: [.beginFromCurrentState, .curveLinear],
                      animations: { animated.alpha = 1 },
                      completion: { completions.append("new:\($0)") })
    let interrupted = completions == ["old:false"]
    animationWindow.tick(timestamp: 0.9)
    ok = uiHelpersCheck(interrupted && completions == ["old:false", "new:true"],
                        "transition interruption completes old false, new true") && ok

    let scene = UIWindowScene()
    scene._hostConfigure(interfaceOrientation: .landscapeRight)
    UITextInputMode._hostConfigure(primaryLanguage: "en-US")
    ok = uiHelpersCheck(scene.interfaceOrientation == .landscapeRight
                        && scene.interfaceOrientation.isLandscape
                        && concrete.window?.textInputMode?.primaryLanguage == "en-US",
                        "host orientation and input mode") && ok
    return ok
}
