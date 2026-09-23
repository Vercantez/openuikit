import XCTest
@testable import OpenUIKit

/// NetNewsWire batch D rows. MEASURED iPhone 16 / iOS 26.1
/// (Tools/oracle2/nnwmiscprobe/transcript-ios26.1.txt) and Apple QuartzCore
/// (Tools/oracle2/springsettleprobe/transcript-macos.txt).
@MainActor
final class NNWMiscMembersTests: XCTestCase {
    // MARK: UISlider.TrackConfiguration

    func testTrackConfigurationDefaultsAndTickPositions() {
        let slider = UISlider(frame: CGRect(x: 0, y: 0, width: 300, height: 30))
        XCTAssertNil(slider.trackConfiguration)
        let six = UISlider.TrackConfiguration(allowsTickValuesOnly: true, numberOfTicks: 6)
        XCTAssertTrue(six.allowsTickValuesOnly)
        XCTAssertEqual(six.ticks.map(\.position), [0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
        XCTAssertEqual(six.neutralValue, 0)
        XCTAssertEqual(six.enabledRange, 0...1)
        let three = UISlider.TrackConfiguration(numberOfTicks: 3)
        XCTAssertTrue(three.allowsTickValuesOnly)
        XCTAssertEqual(three.ticks.map(\.position), [0.0, 0.5, 1.0])
    }

    func testTickOnlySliderSnapsToNearestTickInItsRange() {
        let slider = UISlider(frame: CGRect(x: 0, y: 0, width: 300, height: 30))
        slider.minimumValue = 0
        slider.maximumValue = 5
        slider.trackConfiguration = .init(allowsTickValuesOnly: true, numberOfTicks: 6)
        let measured: [(Float, Float)] = [(0.4, 0), (0.6, 1), (2.49, 2), (2.51, 3), (5, 5)]
        for (set, expected) in measured {
            slider.value = set
            XCTAssertEqual(slider.value, expected, "set \(set)")
        }
    }

    // MARK: animate(springDuration:...)

    func testSpringDurationDefaultsBuildMeasuredCASpring() {
        let v = UIView(frame: .zero)
        v.alpha = 1
        let savedTime = OpenUIKitRuntime.animationTime
        defer { OpenUIKitRuntime.animationTime = savedTime }
        OpenUIKitRuntime.animationTime = 100
        var completed: [Bool] = []
        UIView.animate {
            v.alpha = 0
        } completion: { completed.append($0) }
        XCTAssertEqual(v.alpha, 0, "model value changes at once")
        guard let anim = v.animations.last else { return XCTFail("no animation recorded") }
        XCTAssertEqual(anim.duration, 0.7999999999999999, accuracy: 1e-12)
        guard case .springCoefficients(let k, let d, let velocity) = anim.timing else {
            return XCTFail("not a coefficient spring: \(anim.timing)")
        }
        XCTAssertEqual(k, 157.91367041742973, accuracy: 1e-9)
        XCTAssertEqual(d, 25.132741228718345, accuracy: 1e-9)
        XCTAssertEqual(velocity, 0)
        OpenUIKitRuntime.animationTime = 100.7
        UIView._stepAnimationCompletions(to: 100.7)
        XCTAssertEqual(completed, [])
        OpenUIKitRuntime.animationTime = 100.81
        UIView._stepAnimationCompletions(to: 100.81)
        XCTAssertEqual(completed, [true])
    }

    func testSpringCoefficientsAndSettlingMatchQuartzCore() {
        // (p, bounce) -> (stiffness, damping, settlingDuration), QuartzCore.
        let rows: [(Double, Double, Double, Double, Double)] = [
            (0.5, 0.0, 157.91367041742973, 25.132741228718345, 0.7999999999999999),
            (1.0, 0.0, 39.47841760435743, 12.566370614359172, 1.5000000000000002),
            (0.25, 0.0, 631.6546816697189, 50.26548245743669, 0.4),
            (0.5, 0.3, 157.91367041742973, 17.59291886010284, 0.8629552831744205),
            (0.5, 0.7, 157.91367041742973, 7.539822368615504, 1.904872615017113),
            (0.35, 0.15, 322.27279677026473, 30.51832863487228, 0.5156554893625898),
        ]
        for (p, b, k, d, settle) in rows {
            let c = UIViewSpring.coefficients(perceptualDuration: p, bounce: b)
            XCTAssertEqual(c.stiffness, k, accuracy: 1e-9, "p \(p) b \(b)")
            XCTAssertEqual(c.damping, d, accuracy: 1e-9, "p \(p) b \(b)")
            XCTAssertEqual(UIViewSpring.settlingDuration(stiffness: c.stiffness, damping: c.damping),
                           settle, accuracy: 1e-9, "p \(p) b \(b)")
        }
        XCTAssertEqual(UIViewSpring.coefficients(perceptualDuration: 0.5, bounce: -0.3).damping,
                       35.90391604102621, accuracy: 1e-9)
        XCTAssertEqual(UIViewSpring.settlingDuration(stiffness: 100, damping: 10),
                       1.4727003346780927, accuracy: 1e-9)
        XCTAssertEqual(UIViewSpring.settlingDuration(stiffness: 300, damping: 20),
                       0.7442555275721707, accuracy: 1e-9)
    }

    // MARK: UIScene notification names

    func testSceneNotificationNames() {
        XCTAssertEqual(UIScene.didEnterBackgroundNotification.rawValue, "UISceneDidEnterBackgroundNotification")
        XCTAssertEqual(UIScene.willEnterForegroundNotification.rawValue, "UISceneWillEnterForegroundNotification")
        XCTAssertEqual(UIScene.didActivateNotification.rawValue, "UISceneDidActivateNotification")
        XCTAssertEqual(UIScene.willDeactivateNotification.rawValue, "UISceneWillDeactivateNotification")
        XCTAssertEqual(UIScene.willConnectNotification.rawValue, "UISceneWillConnectNotification")
        XCTAssertEqual(UIScene.didDisconnectNotification.rawValue, "UISceneDidDisconnectNotification")
    }

#if canImport(ObjectiveC)
    // MARK: registerForTraitChanges(_:target:action:)

    final class TraitTarget: UIViewController {
        var hits: [String] = []
        @objc func sizeCategoryChanged(_ env: UIViewController, previous: UITraitCollection) {
            hits.append("action env=\(type(of: env)) prev=\(previous.preferredContentSizeCategory.rawValue) now=\(env.traitCollection.preferredContentSizeCategory.rawValue)")
        }
        @objc func noArgs() { hits.append("noArgs") }
    }

    func testTraitTargetActionFiresSynchronouslyWithEnvironmentAndPrevious() {
        let vc = TraitTarget()
        vc.registerForTraitChanges([UITraitPreferredContentSizeCategory.self], target: vc,
                                   action: #selector(TraitTarget.sizeCategoryChanged(_:previous:)))
        vc.registerForTraitChanges([UITraitPreferredContentSizeCategory.self], target: vc,
                                   action: #selector(TraitTarget.noArgs))
        let current = vc.view.traitCollection
        let previous = current._with { $0.preferredContentSizeCategory = .extraSmall }
        XCTAssertNotEqual(current.preferredContentSizeCategory, .extraSmall)
        vc.view._traitsDidChange(previous: previous)
        XCTAssertEqual(vc.hits, [
            "action env=TraitTarget prev=\(UIContentSizeCategory.extraSmall.rawValue) now=\(current.preferredContentSizeCategory.rawValue)",
            "noArgs",
        ])
        // An unrelated trait change does not fire a size-category registration.
        vc.hits = []
        vc.view._traitsDidChange(previous: current)
        XCTAssertEqual(vc.hits, [])
    }
#endif
}
