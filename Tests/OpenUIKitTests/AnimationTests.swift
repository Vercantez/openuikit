// Animation-module tests (M6): UIView.animate recording, timing functions
// vs Core Animation reference values, the UIKit spring duration-fit model
// vs probed CASpringAnimation parameters, golden-extracted spring positions,
// affine interpolation, and presentation rendering through LayerBridge.
import XCTest
@testable import OpenUIKit

private typealias CGAffineTransform = OpenUIKit.CGAffineTransform

@MainActor
final class AnimationTests: XCTestCase {

    private var savedBackend: RenderBackend!
    private var savedCompositor: RenderCompositor!

    override func setUp() {
        super.setUp()
        savedBackend = OpenUIKitRuntime.renderBackend
        savedCompositor = OpenUIKitRuntime.compositor
        OpenUIKitRuntime.renderBackend = .quartz
        OpenUIKitRuntime.compositor = .layers
        OpenUIKitRuntime.animationTime = 0
        UIViewAnimationCompletionQueue.entries.removeAll()
    }

    override func tearDown() {
        OpenUIKitRuntime.renderBackend = savedBackend
        OpenUIKitRuntime.compositor = savedCompositor
        OpenUIKitRuntime.animationTime = 0
        UIViewAnimationCompletionQueue.entries.removeAll()
        super.tearDown()
    }

    // MARK: Recording semantics

    func testAnimateRecordsAndModelIsFinal() {
        let v = UIView(frame: CGRect(x: 10, y: 20, width: 40, height: 40))
        UIView.animate(withDuration: 1, delay: 0, options: [.curveLinear]) {
            v.alpha = 0.5
            v.center = CGPoint(x: 100, y: 100)
        }
        XCTAssertEqual(v.alpha, 0.5)                       // model = final
        XCTAssertEqual(v.center, CGPoint(x: 100, y: 100))
        XCTAssertEqual(v.animations.count, 2)
        guard case .scalar(let fromAlpha) = v.animations
            .first(where: { $0.property == .alpha })!.from else {
            return XCTFail("missing alpha from value")
        }
        XCTAssertEqual(fromAlpha, 1)
    }

    func testFrameChangeRecordsPositionAndBounds() {
        let v = UIView(frame: CGRect(x: 20, y: 20, width: 40, height: 40))
        UIView.animate(withDuration: 0.6, delay: 0, options: [.curveEaseOut]) {
            v.frame = CGRect(x: 20, y: 20, width: 160, height: 120)
        }
        XCTAssertEqual(Set(v.animations.map { "\($0.property)" }),
                       ["position", "bounds"])
    }

    func testSettersOutsideBlockDoNotRecord() {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        v.alpha = 0.25
        v.center = CGPoint(x: 5, y: 5)
        XCTAssertTrue(v.animations.isEmpty)
    }

    func testReanimatingSamePropertyReplaces() {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        UIView.animate(withDuration: 1, animations: { v.alpha = 0.5 })
        UIView.animate(withDuration: 2, animations: { v.alpha = 0 })
        XCTAssertEqual(v.animations.count, 1)
        XCTAssertEqual(v.animations[0].duration, 2)
        guard case .scalar(let to) = v.animations[0].to else {
            return XCTFail("bad to value")
        }
        XCTAssertEqual(to, 0)
    }

    // MARK: Completion handlers (delivered on the host clock)

    /// A block that records no animation has nothing to wait for — UIKit
    /// creates no CAAnimation and runs the handler right away.
    func testCompletionWithoutAnimationsRunsImmediately() {
        var finished: Bool?
        UIView.animate(withDuration: 0.1, animations: {},
                       completion: { finished = $0 })
        XCTAssertEqual(finished, true)
    }

    /// A real animation's completion waits for `delay + duration` on the
    /// clock and is delivered by the window tick, like UIKit's wall-clock
    /// delivery.
    func testCompletionFiresWhenClockPassesAnimationEnd() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        window.addSubview(v)
        OpenUIKitRuntime.animationTime = 0
        defer { OpenUIKitRuntime.animationTime = 0 }

        var finished: Bool?
        UIView.animate(withDuration: 0.5, delay: 0.25, options: [],
                       animations: { v.alpha = 0 },
                       completion: { finished = $0 })
        XCTAssertNil(finished, "completion must not run synchronously")
        XCTAssertTrue(UIView._hasPendingAnimationCompletions)

        window.tick(timestamp: 0.5)
        XCTAssertNil(finished, "still before delay + duration")

        window.tick(timestamp: 0.75)
        XCTAssertEqual(finished, true)
        XCTAssertFalse(UIView._hasPendingAnimationCompletions)
    }

    /// The end time is measured from the clock when the block ran, not from
    /// zero: a host that animates at t = 10 completes at t = 10.3.
    func testCompletionEndIsRelativeToCommitTime() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        window.addSubview(v)
        OpenUIKitRuntime.animationTime = 10
        defer { OpenUIKitRuntime.animationTime = 0 }

        var fired = false
        UIView.animate(withDuration: 0.3, animations: { v.alpha = 0 },
                       completion: { _ in fired = true })
        window.tick(timestamp: 10.2)
        XCTAssertFalse(fired)
        window.tick(timestamp: 10.3)
        XCTAssertTrue(fired)
    }

    /// Handlers are delivered oldest-end-first, and a completion that starts
    /// a new animation gets its own completion on a LATER tick (one run-loop
    /// turn per batch — no unbounded chain inside a single tick).
    func testCompletionOrderingAndChaining() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let a = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        let b = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        window.addSubview(a)
        window.addSubview(b)
        OpenUIKitRuntime.animationTime = 0
        defer { OpenUIKitRuntime.animationTime = 0 }

        var order: [String] = []
        UIView.animate(withDuration: 0.4, animations: { b.alpha = 0 },
                       completion: { _ in order.append("long") })
        UIView.animate(withDuration: 0.2, animations: { a.alpha = 0 },
                       completion: { _ in
                           order.append("short")
                           UIView.animate(withDuration: 0.1,
                                          animations: { a.alpha = 1 },
                                          completion: { _ in order.append("chained") })
                       })

        OpenUIKitRuntime.animationTime = 0.4
        window.tick(timestamp: 0.4)
        XCTAssertEqual(order, ["short", "long"])

        // The chained animation was committed at 0.4, so it ends at 0.5.
        OpenUIKitRuntime.animationTime = 0.5
        window.tick(timestamp: 0.5)
        XCTAssertEqual(order, ["short", "long", "chained"])
    }

    // MARK: Timing functions (bezier solver vs CA reference values)

    /// Reference y(x) values computed independently (30-digit solve of the
    /// unit cubic bezier), matching Core Animation's standard curves —
    /// verified empirically against oracle2 golden frame positions.
    func testBezierEaseInOut() {
        let expected: [(Double, Double)] = [
            (0.1, 0.0197224535), (0.2, 0.0816598563), (0.25, 0.1291619310),
            (0.4, 0.3318838701), (0.5, 0.5), (0.6, 0.6681161299),
            (0.75, 0.8708380690), (0.9, 0.9802775465),
        ]
        assertCurve(.curveEaseInOut, expected)
    }

    func testBezierEaseIn() {
        assertCurve(.curveEaseIn, [
            (0.25, 0.0934646507), (0.5, 0.3153568126), (0.75, 0.6218618692),
        ])
    }

    func testBezierEaseOut() {
        assertCurve(.curveEaseOut, [
            (0.25, 0.3781381308), (0.5, 0.6846431874), (0.75, 0.9065353493),
        ])
    }

    func testBezierLinear() {
        assertCurve(.curveLinear, [(0.25, 0.25), (0.5, 0.5), (0.9, 0.9)])
    }

    private func assertCurve(_ options: UIView.AnimationOptions,
                             _ expected: [(x: Double, y: Double)],
                             file: StaticString = #filePath, line: UInt = #line) {
        let anim = UIViewAnimation(property: .alpha, from: .scalar(0),
                                   to: .scalar(1), delay: 0, duration: 1,
                                   timing: options.timingCurve)
        for (x, y) in expected {
            let u = LayerBridge.animationProgress(anim, at: x)
            XCTAssertEqual(Double(u), y, accuracy: 2e-5,
                           "curve at x=\(x)", file: file, line: line)
        }
    }

    func testProgressDelayAndCompletion() {
        let anim = UIViewAnimation(property: .alpha, from: .scalar(0),
                                   to: .scalar(1), delay: 0.2, duration: 0.4,
                                   timing: UIView.AnimationOptions.curveEaseInOut.timingCurve)
        XCTAssertEqual(LayerBridge.animationProgress(anim, at: 0), 0)      // backwards fill
        XCTAssertEqual(LayerBridge.animationProgress(anim, at: 0.19), 0)
        XCTAssertEqual(LayerBridge.animationProgress(anim, at: 0.6), 1)    // completed: model
        XCTAssertEqual(LayerBridge.animationProgress(anim, at: 5), 1)
        // Mid-flight: local 0.25 -> easeInOut(0.25).
        XCTAssertEqual(Double(LayerBridge.animationProgress(anim, at: 0.3)),
                       0.1291619310, accuracy: 2e-5)
    }

    // MARK: Spring duration fit (vs probed UIKit CASpringAnimation params)

    /// UIKit-generated CASpringAnimation parameters captured with
    /// ORACLE2_ANIM_DEBUG (mass = 1): the duration-fit model must
    /// reproduce stiffness = omega_n^2 to high precision.
    func testSpringNaturalFrequencyMatchesUIKit() {
        let probes: [(z: CGFloat, D: Double, stiffness: Double)] = [
            (0.35, 1.0, 286.40942818911714),   // anim_spring_bounce
            (0.6, 0.8, 190.21427544499548),    // anim_spring_move
            (0.1, 1.0, 2125.3901278407934),
            (0.2, 1.0, 707.2217886060563),
            (0.5, 1.0, 161.7195025042016),
            (0.8, 1.0, 80.89737200360506),
            (0.9, 1.0, 71.92472915770972),
            (0.99, 1.0, 80.02518243167793),
            (0.5, 0.3, 1796.8833611577954),
            (0.5, 0.5, 646.8780100168065),
            (0.5, 2.0, 40.4298756260504),
        ]
        for p in probes {
            let wn = UIViewSpring.naturalFrequency(dampingRatio: p.z,
                                                   initialVelocity: 0,
                                                   duration: p.D)
            XCTAssertEqual(wn * wn, p.stiffness,
                           accuracy: p.stiffness * 1e-6,
                           "stiffness for z=\(p.z) D=\(p.D)")
        }
    }

    func testSpringCriticalDamping() {
        // Probed: z=1, D=1 -> stiffness 85.25592900599884 (omega*D solves
        // (1+x)e^-x = 0.001); with v=1 -> stiffness 83.13803615388531.
        let w0 = UIViewSpring.naturalFrequency(dampingRatio: 1,
                                               initialVelocity: 0, duration: 1)
        XCTAssertEqual(w0 * w0, 85.25592900599884, accuracy: 1e-3)
        let w1 = UIViewSpring.naturalFrequency(dampingRatio: 1,
                                               initialVelocity: 1, duration: 1)
        XCTAssertEqual(w1 * w1, 83.13803615388531, accuracy: 1e-3)
    }

    func testSpringVelocityUpperBranch() {
        // Probed upper-branch solutions (see KNOWN_GAPS for the
        // large-velocity branch UIKit's own solver jumps to).
        let cases: [(v: CGFloat, stiffness: Double)] = [
            (0.25, 159.67233773812114),
            (1.0, 152.86841381792456),
            (1.5, 147.61602003056592),
            (-2.0, 175.4224123383425),
        ]
        for c in cases {
            let wn = UIViewSpring.naturalFrequency(dampingRatio: 0.5,
                                                   initialVelocity: c.v,
                                                   duration: 1)
            XCTAssertEqual(wn * wn, c.stiffness, accuracy: c.stiffness * 1e-5,
                           "stiffness for v=\(c.v)")
        }
    }

    /// Spring presentation positions vs box centers extracted (subpixel)
    /// from the oracle2 golden frames. Residual of the model (documented in
    /// docs/QUARTZ_NOTES.md): <= 0.16 pt at every golden capture point
    /// except the fastest overshoot frame of the damping-0.35 spring
    /// (t=0.15, +0.64 pt) — the same offset remains when the damped-spring
    /// formula is driven by UIKit's own probed CASpringAnimation
    /// stiffness/damping, so it is CA's evaluator deviating from the ideal
    /// solution there, not our duration fit. Well inside the compare
    /// threshold (worst frame 99.76 % vs 99.5 % required).
    func testSpringPositionsMatchGoldens() {
        // anim_spring_move: center.x 50 -> 150, D=0.8, damping 0.6.
        assertSpringTrack(damping: 0.6, duration: 0.8, from: 50, to: 150,
                          samples: [(0.15, 130.98), (0.3, 159.39),
                                    (0.45, 151.06), (0.6, 149.06),
                                    (0.8, 150.0)])
        // anim_spring_bounce: center.y 40 -> 160, D=1.0, damping 0.35.
        assertSpringTrack(damping: 0.35, duration: 1.0, from: 40, to: 160,
                          samples: [(0.3, 166.65), (0.45, 152.12),
                                    (0.6, 163.52), (0.8, 158.94),
                                    (1.0, 160.0)])
        // Fastest overshoot frame: 0.64 pt CA-evaluator residual (header).
        assertSpringTrack(damping: 0.35, duration: 1.0, from: 40, to: 160,
                          samples: [(0.15, 183.54)], tolerance: 0.8)
    }

    private func assertSpringTrack(damping: CGFloat, duration: Double,
                                   from: CGFloat, to: CGFloat,
                                   samples: [(t: Double, x: Double)],
                                   tolerance: Double = 0.5,
                                   file: StaticString = #filePath,
                                   line: UInt = #line) {
        let anim = UIViewAnimation(
            property: .position, from: .point(CGPoint(x: from, y: 0)),
            to: .point(CGPoint(x: to, y: 0)), delay: 0, duration: duration,
            timing: .spring(dampingRatio: damping, initialVelocity: 0))
        for (t, x) in samples {
            let u = LayerBridge.animationProgress(anim, at: t)
            let pos = Double(from + (to - from) * u)
            XCTAssertEqual(pos, x, accuracy: tolerance,
                           "spring position at t=\(t)", file: file, line: line)
        }
    }

    // MARK: Affine interpolation (CA decomposition)

    func testTransformRotationInterpolates() {
        let rot90 = CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: 0, ty: 0)
        let half = UIViewTransformInterpolation.interpolate(.identity, rot90, 0.5)
        let expected = CGAffineTransform(rotationAngle: .pi / 4)
        for (got, want) in [(half.a, expected.a), (half.b, expected.b),
                            (half.c, expected.c), (half.d, expected.d)] {
            XCTAssertEqual(Double(got), Double(want), accuracy: 1e-9)
        }
        // Pure rotation throughout: determinant (area) stays 1 — matches
        // the constant-area anim_transform_rotate goldens.
        for u in [0.1, 0.3, 0.7, 0.9] {
            let m = UIViewTransformInterpolation.interpolate(.identity, rot90,
                                                             CGFloat(u))
            XCTAssertEqual(Double(m.a * m.d - m.b * m.c), 1, accuracy: 1e-12)
        }
    }

    func testTransformScaleTranslationInterpolate() {
        let m1 = CGAffineTransform(a: 3, b: 0, c: 0, d: 5, tx: 10, ty: -20)
        let mid = UIViewTransformInterpolation.interpolate(.identity, m1, 0.5)
        XCTAssertEqual(Double(mid.a), 2, accuracy: 1e-12)
        XCTAssertEqual(Double(mid.d), 3, accuracy: 1e-12)
        XCTAssertEqual(Double(mid.tx), 5, accuracy: 1e-12)
        XCTAssertEqual(Double(mid.ty), -10, accuracy: 1e-12)
        XCTAssertEqual(Double(mid.b), 0, accuracy: 1e-12)
        XCTAssertEqual(Double(mid.c), 0, accuracy: 1e-12)
    }

    // MARK: Presentation rendering (LayerBridge end-to-end)

    /// A red box fading 1 -> 0 linearly over white: the composited pixel
    /// tracks the presentation alpha at the seek time (the anim_fade
    /// validation, shrunk).
    func testPresentationAlphaRendering() {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 8))
        let bg = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 8))
        bg.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        let box = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 8))
        box.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        host.addSubview(bg)
        host.addSubview(box)
        UIView.animate(withDuration: 1, delay: 0, options: [.curveLinear]) {
            box.alpha = 0
        }
        func greenAt(_ t: Double) -> Int {
            OpenUIKitRuntime.animationTime = t
            let bmp = UIRenderer.render(host, scale: 1)
            return Int(bmp.pixels[(4 * 8 + 4) * 4 + 1]) // G channel, center
        }
        XCTAssertEqual(greenAt(0), 0)          // opaque red
        XCTAssertEqual(greenAt(1.5), 255)      // fully faded: white
        let mid = greenAt(0.5)                 // alpha 0.5 over white
        XCTAssertEqual(mid, 128, accuracy: 3)
        XCTAssertEqual(greenAt(0.25), 64, accuracy: 3)
    }

    func testPresentationPositionRendering() {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 4))
        let box = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: 4))
        box.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        host.addSubview(box)
        UIView.animate(withDuration: 1, delay: 0, options: [.curveLinear]) {
            box.center = CGPoint(x: 14, y: 2)
        }
        func redRow(_ t: Double) -> [Int] {
            OpenUIKitRuntime.animationTime = t
            let bmp = UIRenderer.render(host, scale: 1)
            return (0..<16).map { Int(bmp.pixels[(2 * 16 + $0) * 4]) }
        }
        // t=0: box at x [0,4); t=0.5: centered at 8 -> [6,10); t=1: [12,16).
        XCTAssertEqual(redRow(0)[1], 255)
        XCTAssertEqual(redRow(0)[8], 0)
        XCTAssertEqual(redRow(0.5)[8], 255)
        XCTAssertEqual(redRow(0.5)[1], 0)
        XCTAssertEqual(redRow(1)[14], 255)
        XCTAssertEqual(redRow(1)[8], 0)
    }

    // MARK: Transcendental helpers

    func testLn() {
        XCTAssertEqual(_ln(1), 0, accuracy: 1e-15)
        XCTAssertEqual(_ln(2.718281828459045), 1, accuracy: 1e-14)
        XCTAssertEqual(_ln(1000), 6.907755278982137, accuracy: 1e-13)
        XCTAssertEqual(_ln(0.001), -6.907755278982137, accuracy: 1e-13)
        XCTAssertEqual(_ln(1e12), 27.631021115928547, accuracy: 1e-12)
    }

    func testAtan2() {
        XCTAssertEqual(Double(_atan2(0, 1)), 0, accuracy: 1e-15)
        XCTAssertEqual(Double(_atan2(1, 0)), Double.pi / 2, accuracy: 1e-14)
        XCTAssertEqual(Double(_atan2(1, 1)), Double.pi / 4, accuracy: 1e-14)
        XCTAssertEqual(Double(_atan2(-1, 1)), -Double.pi / 4, accuracy: 1e-14)
        XCTAssertEqual(Double(_atan2(1, -1)), 3 * Double.pi / 4, accuracy: 1e-14)
        XCTAssertEqual(Double(_atan2(-1, -1)), -3 * Double.pi / 4, accuracy: 1e-14)
        XCTAssertEqual(Double(_atan2(0.3, 0.9)), 0.3217505543966422,
                       accuracy: 1e-14)
    }
}
