// Real-iOS oracle for the focused UIHelpers compatibility cluster. It records
// stateful UIButton image selection/layout, UILabel shrinking output,
// UIImage's alpha draw, scene/input environment values, and interruption of
// an in-flight alpha animation with `.beginFromCurrentState`.
// Run with scripts/uihelpers_probe_sim.sh <outdir>.

import UIKit

private func f(_ value: CGFloat) -> String {
    String(format: "%.3f", Double(value))
}

private func rect(_ value: CGRect?) -> String {
    guard let value else { return "nil" }
    return "[\(f(value.minX)),\(f(value.minY)),\(f(value.width)),\(f(value.height))]"
}

private func size(_ value: CGSize) -> String {
    "[\(f(value.width)),\(f(value.height))]"
}

private func makeImage(size: CGSize, color: UIColor) -> UIImage {
    UIGraphicsImageRenderer(size: size).image { _ in
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
    }
}

private func pixel(_ image: UIImage) -> String {
    guard let cg = image.cgImage, let data = cg.dataProvider?.data,
          let bytes = CFDataGetBytePtr(data), CFDataGetLength(data) >= 4 else {
        return "nil"
    }
    let a = Int(bytes[3])
    func straight(_ component: UInt8) -> Int {
        guard a > 0 else { return 0 }
        return Int((Double(component) * 255 / Double(a)).rounded())
    }
    return "premulBGRA=[\(bytes[0]),\(bytes[1]),\(bytes[2]),\(bytes[3])] "
        + "straightRGBA=[\(straight(bytes[2])),\(straight(bytes[1])),"
        + "\(straight(bytes[0])),\(bytes[3])]"
}

private final class UIHelpersProbeDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var lines: [String] = []
    private var animatedView: UIView?
    private var oldAnimationCompletion: Bool?
    private var newTransitionCompletion: Bool?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let root = UIViewController()
        window.rootViewController = root
        window.makeKeyAndVisible()
        self.window = window

        let normal = makeImage(size: CGSize(width: 10, height: 6), color: .red)
        let highlighted = makeImage(size: CGSize(width: 14, height: 8), color: .blue)
        let selected = makeImage(size: CGSize(width: 12, height: 7), color: .green)
        let button = UIButton(type: .system)
        lines.append("button-empty imageView=\(button.imageView == nil ? "nil" : "present") current=\(button.currentImage == nil ? "nil" : "present") subviews=\(button.subviews.map { String(describing: type(of: $0)) }.joined(separator: "+"))")
        button.setImage(normal, for: .normal)
        button.sizeToFit()
        button.layoutIfNeeded()
        lines.append("button-image-only intrinsic=\(size(button.intrinsicContentSize)) frame=\(rect(button.frame)) image=\(rect(button.imageView?.frame)) title=\(rect(button.titleLabel?.frame)) normal=\(button.currentImage === normal)")

        button.setTitle("Go", for: .normal)
        button.sizeToFit()
        button.layoutIfNeeded()
        lines.append("button-image-title intrinsic=\(size(button.intrinsicContentSize)) frame=\(rect(button.frame)) image=\(rect(button.imageView?.frame)) title=\(rect(button.titleLabel?.frame))")

        button.setImage(highlighted, for: .highlighted)
        button.setImage(selected, for: .selected)
        button.isHighlighted = true
        button.layoutIfNeeded()
        lines.append("button-highlighted exact=\(button.currentImage === highlighted) image=\(rect(button.imageView?.frame))")
        button.isSelected = true
        button.layoutIfNeeded()
        lines.append("button-highlighted-selected highlighted=\(button.currentImage === highlighted) selected=\(button.currentImage === selected) normal=\(button.currentImage === normal)")
        button.setImage(nil, for: [.highlighted, .selected])
        lines.append("button-combined-nil highlighted=\(button.currentImage === highlighted) selected=\(button.currentImage === selected) normal=\(button.currentImage === normal)")
        button.isHighlighted = false
        button.isSelected = false
        button.frame = CGRect(x: 10, y: 20, width: 80, height: 44)
        button.layoutIfNeeded()
        lines.append("button-fixed frame=\(rect(button.frame)) image=\(rect(button.imageView?.frame)) title=\(rect(button.titleLabel?.frame))")

        let text = "Shrink me please"
        for (name, adjusts, minimum): (String, Bool, CGFloat) in [
            ("plain", false, 0), ("shrink", true, 0.6), ("floor", true, 0.9),
        ] {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 80, height: 30))
            label.font = .systemFont(ofSize: 20)
            label.text = text
            label.adjustsFontSizeToFitWidth = adjusts
            label.minimumScaleFactor = minimum
            let image = UIGraphicsImageRenderer(size: label.bounds.size).image { context in
                label.layer.render(in: context.cgContext)
            }
            let docs = FileManager.default.urls(for: .documentDirectory,
                                                in: .userDomainMask)[0]
            try! image.pngData()!.write(to: docs.appendingPathComponent("label-\(name).png"))
            lines.append("label-\(name) adjusts=\(label.adjustsFontSizeToFitWidth) minimum=\(f(label.minimumScaleFactor)) font=\(f(label.font.pointSize)) intrinsic=\(size(label.intrinsicContentSize))")
        }

        let translucent = makeImage(size: CGSize(width: 1, height: 1),
                                    color: UIColor(red: 240 / 255, green: 80 / 255,
                                                   blue: 20 / 255, alpha: 0.5))
        let alphaImage = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in
            translucent.draw(at: .zero, blendMode: .normal, alpha: 0.5)
        }
        lines.append("image-alpha pixel=\(pixel(alphaImage))")

        lines.append("environment orientation=\(window.windowScene?.interfaceOrientation.rawValue.description ?? "nil") landscape=\(window.windowScene?.interfaceOrientation.isLandscape.description ?? "nil") input=\(window.textInputMode?.primaryLanguage ?? "nil")")

        let animated = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        root.view.addSubview(animated)
        animatedView = animated
        UIView.animate(withDuration: 2, delay: 0, options: .curveLinear, animations: {
            animated.alpha = 0
        }, completion: { [weak self] finished in
            self?.oldAnimationCompletion = finished
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.measureInterruption()
        }
        return true
    }

    private func measureInterruption() {
        guard let animated = animatedView else { return }
        let before = animated.layer.presentation()?.opacity ?? -1
        UIView.transition(with: animated, duration: 1,
                          options: [.beginFromCurrentState, .curveLinear],
                          animations: { animated.alpha = 1 },
                          completion: { [weak self] finished in
                              self?.newTransitionCompletion = finished
                          })
        let animation = animated.layer.animation(forKey: "opacity") as? CABasicAnimation
        let from = animation?.fromValue.map { "\($0)" } ?? "nil"
        let to = animation?.toValue.map { "\($0)" } ?? "nil"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self else { return }
            self.lines.append(
                "transition before=\(f(CGFloat(before))) from=\(from) to=\(to) "
                + "old=\(self.oldAnimationCompletion.map(String.init) ?? "nil") "
                + "new=\(self.newTransitionCompletion.map(String.init) ?? "nil")")
            self.finish()
        }
    }

    private func finish() {
        let docs = FileManager.default.urls(for: .documentDirectory,
                                            in: .userDomainMask)[0]
        let output = lines.joined(separator: "\n") + "\n"
        try! output.write(to: docs.appendingPathComponent("uihelpers.txt"),
                          atomically: true, encoding: .utf8)
        print(output, terminator: "")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exit(0) }
    }
}

_ = UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil,
                      NSStringFromClass(UIHelpersProbeDelegate.self))
