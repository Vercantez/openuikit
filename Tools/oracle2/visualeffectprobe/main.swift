import Darwin
import Foundation
import UIKit

private func rect(_ value: CGRect) -> String {
    "(\(value.minX),\(value.minY),\(value.width),\(value.height))"
}

private func equality(_ name: String, _ lhs: NSObject, _ rhs: NSObject) {
    print("\(name) identity=\(lhs === rhs) equal=\(lhs.isEqual(rhs)) hashes=\(lhs.hash),\(rhs.hash)")
}

private func archive(_ effect: UIVisualEffect) -> UIVisualEffect {
    let data = try! NSKeyedArchiver.archivedData(
        withRootObject: effect,
        requiringSecureCoding: true
    )
    return try! NSKeyedUnarchiver.unarchivedObject(
        ofClasses: [UIVisualEffect.self, UIBlurEffect.self, UIVibrancyEffect.self],
        from: data
    ) as! UIVisualEffect
}

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Launch the built probe with the `direct-add` argument to reproduce
        // UIKit's NSInternalInconsistencyException hierarchy boundary.
        if CommandLine.arguments.dropFirst().contains("direct-add") {
            let effectView = UIVisualEffectView(
                effect: UIBlurEffect(style: .regular)
            )
            effectView.addSubview(UIView(frame: .zero))
            return false
        }

        let baseAppearance = UIBarAppearance()
        let toolbarAppearance = UIToolbarAppearance()
        let tabAppearance = UITabBarAppearance()
        let oldDefaultEffect = baseAppearance.backgroundEffect
        print("fresh.base-toolbar=\(baseAppearance.backgroundEffect === toolbarAppearance.backgroundEffect)")
        print("fresh.base-tab=\(baseAppearance.backgroundEffect === tabAppearance.backgroundEffect)")
        baseAppearance.configureWithDefaultBackground()
        print("reset.same-old=\(baseAppearance.backgroundEffect === oldDefaultEffect)")
        print("reset.same-toolbar=\(baseAppearance.backgroundEffect === toolbarAppearance.backgroundEffect)")
        let chromeFactoryA = UIBlurEffect(style: .systemChromeMaterial)
        let chromeFactoryB = UIBlurEffect(style: .systemChromeMaterial)
        print("factory.same=\(chromeFactoryA === chromeFactoryB)")
        print("fresh.base-factory=\(baseAppearance.backgroundEffect === chromeFactoryA)")
        let baseAppearanceCopy = UIBarAppearance(
            barAppearance: baseAppearance)
        print("copy.same=\(baseAppearanceCopy.backgroundEffect === baseAppearance.backgroundEffect)")

        let lightA = UIBlurEffect(style: .light)
        let lightB = UIBlurEffect(style: .light)
        let dark = UIBlurEffect(style: .dark)
        let regular = UIBlurEffect(style: .regular)
        let inertBlur = UIBlurEffect()
        equality("blur.same", lightA, lightB)
        equality("blur.cross-style", lightA, dark)
        equality("blur.inert-vs-light", inertBlur, lightA)
        equality("blur.archive", lightA, archive(lightA))
        print("blur.hashes inert=\(inertBlur.hash) light=\(lightA.hash) dark=\(dark.hash) regular=\(regular.hash)")

        let labelA = UIVibrancyEffect(blurEffect: lightA, style: .label)
        let labelB = UIVibrancyEffect(blurEffect: lightB, style: .label)
        let secondary = UIVibrancyEffect(
            blurEffect: lightB,
            style: .secondaryLabel
        )
        let darkLabel = UIVibrancyEffect(blurEffect: dark, style: .label)
        let inertVibrancyA = UIVibrancyEffect()
        let inertVibrancyB = UIVibrancyEffect()
        let inertBlurVibrancy = UIVibrancyEffect(blurEffect: inertBlur)
        equality("vibrancy.same", labelA, labelB)
        equality("vibrancy.cross-style", labelA, secondary)
        equality("vibrancy.cross-blur", labelA, darkLabel)
        equality("vibrancy.inert", inertVibrancyA, inertVibrancyB)
        equality("vibrancy.nil-vs-inert-blur", inertVibrancyA, inertBlurVibrancy)
        equality("vibrancy.inert-vs-light", inertVibrancyA, labelA)
        equality("vibrancy.archive", labelA, archive(labelA))
        print("vibrancy.hashes inert=\(inertVibrancyA.hash) inertBlur=\(inertBlurVibrancy.hash) light=\(labelA.hash) dark=\(darkLabel.hash)")

        func combined(
            _ name: String,
            _ effect: UIVisualEffect?,
            accessFirst: Bool
        ) {
            let view = UIVisualEffectView(effect: effect)
            view.frame = CGRect(x: 10, y: 20, width: 120, height: 80)
            var saved: UIView?
            if accessFirst {
                saved = view.contentView
            }
            view.bounds = CGRect(x: 7, y: 9, width: 200, height: 110)
            let content = saved ?? view.contentView
            print("\(name) accessFirst=\(accessFirst) content=\(rect(content.frame))")
        }

        combined("nil", nil, accessFirst: false)
        combined("nil", nil, accessFirst: true)
        combined("base", UIVisualEffect(), accessFirst: false)
        combined("base", UIVisualEffect(), accessFirst: true)
        combined("blur", UIBlurEffect(style: .regular), accessFirst: false)
        combined("blur", UIBlurEffect(style: .regular), accessFirst: true)
        combined("vibrancy", UIVibrancyEffect(), accessFirst: false)
        combined("vibrancy", UIVibrancyEffect(), accessFirst: true)

        let nilOrigin = UIVisualEffectView(effect: nil)
        nilOrigin.frame = CGRect(x: 10, y: 20, width: 120, height: 80)
        let nilOriginContent = nilOrigin.contentView
        nilOrigin.bounds.origin = CGPoint(x: 7, y: 9)
        nilOrigin.layoutIfNeeded()
        print("nil-origin-after-access content=\(rect(nilOriginContent.frame))")

        let lateBlur = UIVisualEffectView(frame: CGRect(
            x: 10,
            y: 20,
            width: 120,
            height: 80
        ))
        let lateBlurContent = lateBlur.contentView
        lateBlur.effect = UIBlurEffect(style: .regular)
        lateBlur.bounds = CGRect(x: 7, y: 9, width: 200, height: 110)
        lateBlur.layoutIfNeeded()
        print("frame-access-blur-combined content=\(rect(lateBlurContent.frame))")

        let toggle = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        toggle.frame = CGRect(x: 10, y: 20, width: 120, height: 80)
        let toggleContent = toggle.contentView
        toggle.bounds.origin = CGPoint(x: 7, y: 9)
        toggle.layoutIfNeeded()
        toggle.effect = nil
        print("blur-to-nil-immediate content=\(rect(toggleContent.frame))")

        func assignment(
            _ name: String,
            initial: UIVisualEffect?,
            replacement: (UIVisualEffect?) -> UIVisualEffect?
        ) {
            let view = UIVisualEffectView(effect: initial)
            view.frame = CGRect(x: 10, y: 20, width: 120, height: 80)
            let content = view.contentView
            view.bounds.origin = CGPoint(x: 7, y: 9)
            view.layoutIfNeeded()
            view.effect = replacement(view.effect)
            print("\(name)=\(rect(content.frame))")
        }
        assignment("blur-to-nil",
                   initial: UIBlurEffect(style: .regular)) { _ in nil }
        assignment("blur-to-base",
                   initial: UIBlurEffect(style: .regular)) {
            _ in UIVisualEffect()
        }
        assignment("blur-to-vibrancy",
                   initial: UIBlurEffect(style: .regular)) {
            _ in UIVibrancyEffect()
        }
        assignment("blur-to-blur",
                   initial: UIBlurEffect(style: .regular)) {
            _ in UIBlurEffect(style: .dark)
        }
        assignment("blur-to-same",
                   initial: UIBlurEffect(style: .regular)) { $0 }
        assignment("blur-to-equal",
                   initial: UIBlurEffect(style: .regular)) {
            _ in UIBlurEffect(style: .regular)
        }
        assignment("nil-to-nil", initial: nil) { _ in nil }
        assignment("nil-to-base", initial: nil) { _ in UIVisualEffect() }
        assignment("nil-to-blur", initial: nil) {
            _ in UIBlurEffect(style: .regular)
        }
        assignment("nil-to-vibrancy", initial: nil) {
            _ in UIVibrancyEffect()
        }
        assignment("base-to-nil", initial: UIVisualEffect()) { _ in nil }
        assignment("base-to-base", initial: UIVisualEffect()) {
            _ in UIVisualEffect()
        }
        assignment("vibrancy-to-nil", initial: UIVibrancyEffect()) {
            _ in nil
        }
        assignment("vibrancy-to-blur", initial: UIVibrancyEffect()) {
            _ in UIBlurEffect(style: .regular)
        }
        assignment(
            "vibrancy-equal-style",
            initial: UIVibrancyEffect(
                blurEffect: UIBlurEffect(style: .light), style: .label)
        ) { _ in
            UIVibrancyEffect(
                blurEffect: UIBlurEffect(style: .light),
                style: .secondaryLabel)
        }
        assignment(
            "vibrancy-different-blur",
            initial: UIVibrancyEffect(
                blurEffect: UIBlurEffect(style: .light), style: .label)
        ) { _ in
            UIVibrancyEffect(
                blurEffect: UIBlurEffect(style: .dark), style: .label)
        }
        assignment("vibrancy-inert-equal", initial: UIVibrancyEffect()) {
            _ in UIVibrancyEffect()
        }
        assignment("vibrancy-inert-explicit", initial: UIVibrancyEffect()) {
            _ in UIVibrancyEffect(blurEffect: UIBlurEffect())
        }

        func lazyAssignment(
            _ name: String,
            initial: UIVisualEffect?,
            replacement: UIVisualEffect?
        ) {
            let view = UIVisualEffectView(effect: initial)
            view.frame = CGRect(x: 10, y: 20, width: 120, height: 80)
            view.bounds = CGRect(x: 7, y: 9, width: 200, height: 110)
            view.effect = replacement
            print("\(name)=\(rect(view.contentView.frame))")
        }
        lazyAssignment("lazy-nil-to-vibrancy", initial: nil,
                       replacement: UIVibrancyEffect())
        lazyAssignment("lazy-blur-to-vibrancy",
                       initial: UIBlurEffect(style: .regular),
                       replacement: UIVibrancyEffect())
        lazyAssignment("lazy-base-to-vibrancy", initial: UIVisualEffect(),
                       replacement: UIVibrancyEffect())
        lazyAssignment("lazy-nil-to-blur", initial: nil,
                       replacement: UIBlurEffect(style: .regular))
        lazyAssignment("lazy-nil-to-base", initial: nil,
                       replacement: UIVisualEffect())

        fflush(stdout)
        exit(0)
    }
}
