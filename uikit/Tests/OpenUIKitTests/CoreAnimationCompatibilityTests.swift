import XCTest
@testable import OpenUIKit

private typealias PortableLayer = OpenUIKit.CALayer
private typealias PortableGradientLayer = OpenUIKit.CAGradientLayer
private typealias PortableBasicAnimation = OpenUIKit.CABasicAnimation
private typealias PortableTransaction = OpenUIKit.CATransaction
private typealias PortableCGColor = OpenUIKit.CGColor

#if !os(Linux)
@MainActor
#endif
private final class ProgressSubclassProbe: UIProgressView {
    let maskProbe = PortableLayer()
    var observerCalls = 0

    override var progress: Float {
        didSet {
            observerCalls += 1
            maskProbe.bounds.size.width = CGFloat(progress) * 100
        }
    }

    override func setProgress(_ progress: Float, animated: Bool) {
        super.setProgress(progress, animated: animated)
        PortableTransaction.begin()
        PortableTransaction.setAnimationDuration(animated ? 0.25 : 0)
        maskProbe.bounds.size.width = CGFloat(self.progress) * 100
        PortableTransaction.commit()
    }
}

#if !os(Linux)
@MainActor
#endif
private final class PresentedBoundsContentProbe: UIView {
    var sampledBounds: [CGRect] = []

    override func drawContent(in canvas: Canvas, bounds: CGRect) {
        sampledBounds.append(bounds)
        canvas.fill(rect: bounds, color: PortableCGColor(
            red: 1, green: 1, blue: 1, alpha: 1))
    }
}

#if !os(Linux)
@MainActor
#endif
// Linux XCTest 6.2.4 (swift-corelibs-xctest) discovers methods as
// `(T) -> () throws -> Void`. `@MainActor` on the class changes that type
// and crashes discovery (Linux trial 2026-09-05). Apple XCTest on Darwin
// runs isolated methods natively, so isolation stays behind `#if !os(Linux)`.
// Test targets pass `-swift-version 5` on Linux so `@preconcurrency @MainActor`
// UIKit calls from the now-nonisolated XCTestCase still type-check.
final class CoreAnimationCompatibilityTests: XCTestCase {
    private var savedTime: Double = 0
    private var savedDeadline: Double = 0

    override func setUp() {
        super.setUp()
        savedTime = OpenUIKitRuntime.animationTime
        savedDeadline = OpenUIKitRuntime.animationWorkDeadline
        OpenUIKitRuntime.animationTime = 10
        OpenUIKitRuntime.animationWorkDeadline = -.infinity
        PortableTransaction._resetForTesting()
    }

    override func tearDown() {
        PortableTransaction._resetForTesting()
        OpenUIKitRuntime.animationTime = savedTime
        OpenUIKitRuntime.animationWorkDeadline = savedDeadline
        super.tearDown()
    }

    func testKeyedBasicAnimationIsCopiedReplacedAndRemoved() {
        let layer = PortableLayer()
        layer.position = CGPoint(x: 5, y: 7)

        let first = PortableBasicAnimation(keyPath: "position")
        first.duration = 2
        first.fromValue = CGPoint(x: 5, y: 7)
        first.toValue = CGPoint(x: 25, y: 27)
        first.fillMode = .forwards
        first.isRemovedOnCompletion = false
        layer.add(first, forKey: "move")

        first.duration = 99
        XCTAssertEqual(layer.animation(forKey: "move")?.duration, 2,
                       "CALayer retains a copy, not the caller's animation")

        let replacement = PortableBasicAnimation(keyPath: "position")
        replacement.duration = 1
        replacement.fromValue = CGPoint(x: 1, y: 2)
        replacement.toValue = CGPoint(x: 3, y: 4)
        layer.add(replacement, forKey: "move")
        XCTAssertEqual(layer._explicitAnimations.count, 1)
        XCTAssertEqual(layer.animation(forKey: "move")?.duration, 1)

        layer.removeAnimation(forKey: "move")
        XCTAssertNil(layer.animation(forKey: "move"))
    }

    func testExplicitPositionPresentationAndForwardsFill() {
        let layer = PortableLayer()
        layer.position = CGPoint(x: 4, y: 8)
        let animation = PortableBasicAnimation(keyPath: "position")
        animation.duration = 4
        animation.fromValue = CGPoint(x: 4, y: 8)
        animation.toValue = CGPoint(x: 20, y: 24)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        layer.add(animation, forKey: "position")

        XCTAssertEqual(layer.position, CGPoint(x: 4, y: 8),
                       "explicit animation does not mutate the model layer")
        XCTAssertEqual(layer._presentationState(at: 12).position,
                       CGPoint(x: 12, y: 16))
        XCTAssertEqual(layer._presentationState(at: 30).position,
                       CGPoint(x: 20, y: 24))
    }

    func testTransactionImplicitFrameAnimationUsesHostClock() {
        let layer = PortableLayer()
        layer.anchorPoint = CGPoint(x: 0, y: 0)
        layer.frame = CGRect(x: 2, y: 4, width: 10, height: 12)

        PortableTransaction.begin()
        PortableTransaction.setAnimationDuration(2)
        layer.frame = CGRect(x: 12, y: 14, width: 30, height: 32)
        PortableTransaction.commit()

        XCTAssertEqual(layer.frame, CGRect(x: 12, y: 14, width: 30, height: 32),
                       "the model tree changes immediately")
        let start = layer._presentationState(at: 10)
        XCTAssertEqual(start.bounds.size, CGSize(width: 10, height: 12))
        XCTAssertEqual(start.position, CGPoint(x: 2, y: 4))
        let middle = layer._presentationState(at: 11)
        XCTAssertEqual(middle.bounds.size, CGSize(width: 20, height: 22))
        XCTAssertEqual(middle.position, CGPoint(x: 7, y: 9))
        let end = layer._presentationState(at: 12)
        XCTAssertEqual(end.bounds.size, CGSize(width: 30, height: 32))
        XCTAssertEqual(end.position, CGPoint(x: 12, y: 14))
        XCTAssertTrue(layer._explicitAnimations.isEmpty)
    }

    func testNestedTransactionInheritsValuesWithoutMutatingParent() {
        var completionCalls = 0
        PortableTransaction.begin()
        PortableTransaction.setAnimationDuration(1.75)
        PortableTransaction.setDisableActions(true)
        PortableTransaction.setCompletionBlock { completionCalls += 1 }

        PortableTransaction.begin()
        XCTAssertEqual(PortableTransaction.animationDuration(), 1.75)
        XCTAssertTrue(PortableTransaction.disableActions())
        XCTAssertNotNil(PortableTransaction.completionBlock())
        PortableTransaction.setAnimationDuration(0.5)
        PortableTransaction.setDisableActions(false)
        PortableTransaction.commit()
        PortableTransaction.flush()
        XCTAssertEqual(completionCalls, 0,
                       "an inherited completion is not scheduled by the child")

        XCTAssertEqual(PortableTransaction.animationDuration(), 1.75)
        XCTAssertTrue(PortableTransaction.disableActions())
        PortableTransaction.commit()
        PortableTransaction.flush()
        XCTAssertEqual(completionCalls, 1)
        XCTAssertEqual(PortableTransaction.animationDuration(), 0.25)
        XCTAssertFalse(PortableTransaction.disableActions())
    }

    func testTransactionCompletionWaitsForLongestAnimationAndIsTickDriven() {
        let layer = PortableLayer()
        var calls: [String] = []
        PortableTransaction.begin()
        PortableTransaction.setCompletionBlock { calls.append("complete") }

        let animation = PortableBasicAnimation(keyPath: "position")
        animation.duration = 1.5
        animation.fromValue = CGPoint.zero
        animation.toValue = CGPoint(x: 10, y: 0)
        layer.add(animation, forKey: "move")
        PortableTransaction.commit()

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        window.tick(timestamp: 11.49)
        XCTAssertEqual(calls, [])
        window.tick(timestamp: 11.5)
        XCTAssertEqual(calls, ["complete"])
        window.tick(timestamp: 100)
        XCTAssertEqual(calls, ["complete"])
    }

    func testTransactionCompletionTracksRemovalReplacementAndInfinity() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 10, height: 10))

        do {
            let layer = PortableLayer()
            var calls = 0
            PortableTransaction.begin()
            PortableTransaction.setCompletionBlock { calls += 1 }
            let animation = PortableBasicAnimation(keyPath: "opacity")
            animation.duration = 0.4
            animation.fromValue = 0.0
            animation.toValue = 1.0
            layer.add(animation, forKey: "fade")
            PortableTransaction.commit()

            OpenUIKitRuntime.animationTime = 10.053
            layer.removeAnimation(forKey: "fade")
            window.tick(timestamp: 10.052)
            XCTAssertEqual(calls, 0)
            window.tick(timestamp: 10.053)
            XCTAssertEqual(calls, 1)
        }

        do {
            OpenUIKitRuntime.animationTime = 20
            let layer = PortableLayer()
            var calls = 0
            PortableTransaction.begin()
            PortableTransaction.setCompletionBlock { calls += 1 }
            let original = PortableBasicAnimation(keyPath: "opacity")
            original.duration = 0.4
            original.fromValue = 0.0
            original.toValue = 1.0
            layer.add(original, forKey: "fade")
            PortableTransaction.commit()

            OpenUIKitRuntime.animationTime = 20.01
            let replacement = PortableBasicAnimation(keyPath: "opacity")
            replacement.duration = 0.1
            replacement.fromValue = 0.0
            replacement.toValue = 1.0
            layer.add(replacement, forKey: "fade")
            window.tick(timestamp: 20.109)
            XCTAssertEqual(calls, 1,
                           "cross-transaction replacement retires old work")
            window.tick(timestamp: 20.111)
            XCTAssertEqual(calls, 1)
        }

        do {
            OpenUIKitRuntime.animationTime = 30
            let layer = PortableLayer()
            var calls = 0
            PortableTransaction.begin()
            PortableTransaction.setCompletionBlock { calls += 1 }
            let infinite = PortableBasicAnimation(keyPath: "opacity")
            infinite.duration = 0.1
            infinite.repeatCount = .infinity
            infinite.fromValue = 0.0
            infinite.toValue = 1.0
            layer.add(infinite, forKey: "fade")
            PortableTransaction.commit()
            window.tick(timestamp: 100)
            XCTAssertEqual(calls, 0)
            OpenUIKitRuntime.animationTime = 100
            layer.removeAllAnimations()
            window.tick(timestamp: 100)
            XCTAssertEqual(calls, 1)
        }
    }

    func testFractionalRepeatForwardsFillEndsAtFractionalPhase() {
        let layer = PortableLayer()
        layer.opacity = 1
        let animation = PortableBasicAnimation(keyPath: "opacity")
        animation.duration = 2
        animation.repeatCount = 2.5
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        layer.add(animation, forKey: "fade")

        XCTAssertEqual(layer._presentationState(at: 15).opacity, 0.5,
                       accuracy: 0.0001)
    }

    func testExplicitAnimationOutsideTransactionPublishesWorkDeadline() {
        let layer = PortableLayer()
        let animation = PortableBasicAnimation(keyPath: "position")
        animation.duration = 0.75
        animation.fromValue = CGPoint.zero
        animation.toValue = CGPoint(x: 10, y: 0)
        layer.add(animation, forKey: "move")
        XCTAssertEqual(OpenUIKitRuntime.animationWorkDeadline, 10.75,
                       accuracy: 0.0001)
    }

    func testMissingFromEndpointUsesInterruptedPresentationValue() {
        let layer = PortableLayer()
        layer.position = CGPoint(x: 100, y: 0)
        let first = PortableBasicAnimation(keyPath: "position")
        first.duration = 2
        first.fromValue = CGPoint.zero
        first.toValue = CGPoint(x: 100, y: 0)
        layer.add(first, forKey: "move")

        OpenUIKitRuntime.animationTime = 11
        let replacement = PortableBasicAnimation(keyPath: "position")
        replacement.duration = 2
        replacement.toValue = CGPoint(x: 200, y: 0)
        layer.add(replacement, forKey: "move")
        XCTAssertEqual(layer._presentationState(at: 11).position.x, 50,
                       accuracy: 0.0001)
        XCTAssertEqual(layer._presentationState(at: 12).position.x, 125,
                       accuracy: 0.0001)
    }

    func testBackingLayerOpacityAnimationRendersInBothCompositors() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 4))
        view.backgroundColor = .white
        let animation = PortableBasicAnimation(keyPath: "opacity")
        animation.duration = 2
        animation.fromValue = 0.0
        animation.toValue = 1.0
        view.layer.add(animation, forKey: "fade")
        OpenUIKitRuntime.animationTime = 11

        for bitmap in [
            LayerBridge.render(view, scale: 1),
            UIRenderer.renderPassRender(view, scale: 1),
        ] {
            let alpha = bitmap.pixels[(2 * bitmap.width + 4) * 4 + 3]
            XCTAssertGreaterThanOrEqual(alpha, 126)
            XCTAssertLessThanOrEqual(alpha, 129)
        }
    }

    func testTransparentSolidMaskAgreesAcrossRenderers() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 4))
        let layer = PortableLayer()
        layer.anchorPoint = CGPoint(x: 0, y: 0)
        layer.frame = root.bounds
        layer.backgroundColor = PortableCGColor(
            red: 1, green: 1, blue: 1, alpha: 1)
        let mask = PortableLayer()
        mask.anchorPoint = CGPoint(x: 0, y: 0)
        mask.frame = root.bounds
        mask.backgroundColor = PortableCGColor(
            red: 1, green: 1, blue: 1, alpha: 0)
        layer.mask = mask
        root.layer.addSublayer(layer)

        for bitmap in [
            LayerBridge.render(root, scale: 1),
            UIRenderer.renderPassRender(root, scale: 1),
        ] {
            XCTAssertTrue(bitmap.pixels.enumerated().allSatisfy {
                $0.offset % 4 != 3 || $0.element == 0
            })
        }
    }

    func testZeroDurationAndDisabledActionsDoNotLeaveImplicitAnimations() {
        let layer = PortableLayer()
        PortableTransaction.begin()
        PortableTransaction.setAnimationDuration(0)
        layer.bounds = CGRect(x: 0, y: 0, width: 20, height: 20)
        PortableTransaction.commit()
        XCTAssertTrue(layer._explicitAnimations.isEmpty)

        PortableTransaction.begin()
        PortableTransaction.setAnimationDuration(4)
        PortableTransaction.setDisableActions(true)
        layer.position = CGPoint(x: 9, y: 9)
        PortableTransaction.commit()
        XCTAssertTrue(layer._explicitAnimations.isEmpty)
    }

    func testProgressViewAnimatedSetterHasImmediateModelAndClockedPresentation() {
        let progress = UIProgressView(
            frame: CGRect(x: 0, y: 0, width: 100, height: 4))
        progress.progress = 0.2
        progress.setProgress(0.8, animated: true)

        XCTAssertEqual(progress.progress, 0.8)
        XCTAssertEqual(progress._presentationProgress(at: 10), 0.2)
        XCTAssertEqual(progress._presentationProgress(at: 10.125), 0.5,
                       accuracy: 0.0001)
        XCTAssertEqual(progress._presentationProgress(at: 10.25), 0.8)

        OpenUIKitRuntime.animationTime = 20
        progress.progress = 0.2
        progress.setProgress(0.8, animated: true)
        XCTAssertEqual(progress._presentationProgress(at: 20.125), 0.5,
                       accuracy: 0.0001)
        OpenUIKitRuntime.animationTime = 20.125
        progress.setProgress(0.1, animated: true)
        XCTAssertEqual(progress._presentationProgress(at: 20.125), 0.5,
                       accuracy: 0.0001,
                       "reversal begins at the current presentation value")
    }

    func testProgressMethodLetsSubclassInstallOneAnimationAfterSuper() {
        let progress = ProgressSubclassProbe()
        progress.maskProbe.bounds = CGRect(x: 0, y: 0, width: 0, height: 4)

        progress.setProgress(0.8, animated: true)

        XCTAssertEqual(progress.progress, 0.8)
        XCTAssertEqual(progress.observerCalls, 0,
                       "super.setProgress must not eagerly invoke an override observer")
        XCTAssertEqual(progress.maskProbe.bounds.width, 80, accuracy: 0.0001)
        XCTAssertEqual(progress.maskProbe._presentationState(at: 10).bounds.width, 0)
        XCTAssertEqual(progress.maskProbe._presentationState(at: 10.125).bounds.width,
                       40, accuracy: 0.0001)
        XCTAssertEqual(progress.maskProbe._presentationState(at: 10.25).bounds.width,
                       80, accuracy: 0.0001)

        progress.progress = 0.25
        XCTAssertEqual(progress.observerCalls, 1,
                       "direct model assignment still invokes the subclass observer")
        XCTAssertEqual(progress.maskProbe.bounds.width, 25, accuracy: 0.0001)
    }

    func testGradientLocationsAnimateAndLayerMaskClipsQuartzPixels() {
        let gradient = PortableGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: 20, height: 8)
        gradient.colors = [
            PortableCGColor(red: 1, green: 0, blue: 0, alpha: 1),
            PortableCGColor(red: 1, green: 0, blue: 0, alpha: 1),
        ]
        gradient.locations = [0, 1]
        gradient.drawsAsynchronously = false

        let locationAnimation = PortableBasicAnimation(keyPath: "locations")
        locationAnimation.duration = 2
        // Preserve Focus's exact source shape: without contextual annotation,
        // these endpoint arrays arrive through Any as [Double] on Darwin.
        locationAnimation.fromValue = [0.0, 0.5]
        locationAnimation.toValue = [0.5, 1.0]
        locationAnimation.fillMode = .forwards
        locationAnimation.isRemovedOnCompletion = false
        gradient.add(locationAnimation, forKey: "locations")
        XCTAssertEqual(gradient._presentationState(at: 11).locations!, [0.25, 0.75])

        let mask = PortableLayer()
        mask.anchorPoint = CGPoint(x: 0, y: 0)
        mask.frame = CGRect(x: 0, y: 0, width: 7, height: 8)
        mask.backgroundColor = PortableCGColor(red: 1, green: 1, blue: 1, alpha: 1)
        gradient.mask = mask

        let previousParent = PortableLayer()
        previousParent.addSublayer(mask)
        XCTAssertTrue(mask.superlayer === previousParent)
        gradient.mask = mask
        XCTAssertNil(mask.superlayer, "installing a mask removes it from a sublayer tree")

        let root = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 8))
        root.layer.addSublayer(gradient)
        for bitmap in [
            LayerBridge.render(root, scale: 1),
            UIRenderer.renderPassRender(root, scale: 1),
        ] {
            func alpha(_ x: Int) -> UInt8 {
                bitmap.pixels[(4 * 20 + x) * 4 + 3]
            }
            XCTAssertGreaterThan(alpha(3), 240)
            XCTAssertEqual(alpha(12), 0)
        }

        PortableTransaction.begin()
        PortableTransaction.setAnimationDuration(2)
        mask.frame = CGRect(x: 0, y: 0, width: 15, height: 8)
        PortableTransaction.commit()
        OpenUIKitRuntime.animationTime = 11
        for bitmap in [
            LayerBridge.render(root, scale: 1),
            UIRenderer.renderPassRender(root, scale: 1),
        ] {
            func alpha(_ x: Int) -> UInt8 {
                bitmap.pixels[(4 * 20 + x) * 4 + 3]
            }
            XCTAssertGreaterThan(alpha(9), 240,
                                 "the mask width interpolates at half time")
            XCTAssertEqual(alpha(13), 0)
        }
        XCTAssertTrue(gradient.mask === mask)
        XCTAssertNil(mask.superlayer, "a mask is retained but is not a sublayer")

        let newOwner = PortableLayer()
        newOwner.mask = mask
        XCTAssertNil(gradient.mask, "a mask layer has only one owning layer")
        XCTAssertTrue(newOwner.mask === mask)
    }

    func testReplacementGetsFreshWorkIdentityAcrossTransactions() {
        let layer = PortableLayer()
        var calls: [String] = []

        PortableTransaction.begin()
        PortableTransaction.setCompletionBlock { calls.append("old") }
        let old = PortableBasicAnimation(keyPath: "opacity")
        old.duration = 4
        old.fromValue = 0.0
        old.toValue = 1.0
        layer.add(old, forKey: "fade")
        PortableTransaction.commit()

        OpenUIKitRuntime.animationTime = 10.25
        PortableTransaction.begin()
        PortableTransaction.setCompletionBlock { calls.append("new") }
        let replacement = PortableBasicAnimation(keyPath: "opacity")
        replacement.duration = 1
        replacement.fromValue = 0.0
        replacement.toValue = 1.0
        layer.add(replacement, forKey: "fade")
        PortableTransaction.commit()

        PortableTransaction.flush()
        XCTAssertEqual(calls, ["old"])
        PortableTransaction._stepCompletions(to: 11.249)
        XCTAssertEqual(calls, ["old"])
        PortableTransaction._stepCompletions(to: 11.25)
        XCTAssertEqual(calls, ["old", "new"])
    }

    func testSameTransactionReplacementCompletionWaitsForNewWork() {
        let layer = PortableLayer()
        var calls = 0
        PortableTransaction.begin()
        PortableTransaction.setCompletionBlock { calls += 1 }
        let old = PortableBasicAnimation(keyPath: "opacity")
        old.duration = 4
        old.fromValue = 0.0
        old.toValue = 1.0
        layer.add(old, forKey: "fade")
        let replacement = PortableBasicAnimation(keyPath: "opacity")
        replacement.duration = 1
        replacement.fromValue = 0.0
        replacement.toValue = 1.0
        layer.add(replacement, forKey: "fade")
        PortableTransaction.commit()

        PortableTransaction._stepCompletions(to: 10.999)
        XCTAssertEqual(calls, 0)
        PortableTransaction._stepCompletions(to: 11)
        XCTAssertEqual(calls, 1)
    }

    func testWorkRegistryAndDeadlineRetireOnRemovalExpiryAndLayerDeinit() {
        do {
            let layer = PortableLayer()
            let infinite = PortableBasicAnimation(keyPath: "opacity")
            infinite.duration = 0.1
            infinite.repeatCount = .infinity
            infinite.fromValue = 0.0
            infinite.toValue = 1.0
            layer.add(infinite, forKey: "spin")
            XCTAssertEqual(OpenUIKitRuntime.animationWorkDeadline, .infinity)
            layer.removeAnimation(forKey: "spin")
            XCTAssertEqual(OpenUIKitRuntime.animationWorkDeadline, -.infinity)
            XCTAssertEqual(PortableTransaction._workRegistryCountForTesting, 0)
        }

        do {
            let layer = PortableLayer()
            let finite = PortableBasicAnimation(keyPath: "opacity")
            finite.duration = 0.5
            finite.fromValue = 0.0
            finite.toValue = 1.0
            layer.add(finite, forKey: "finite")
            PortableTransaction._stepCompletions(to: 10.5)
            XCTAssertEqual(OpenUIKitRuntime.animationWorkDeadline, -.infinity)
            XCTAssertEqual(PortableTransaction._workRegistryCountForTesting, 0)
        }

        var completionCalls = 0
        weak var releasedLayer: PortableLayer?
        do {
            var layer: PortableLayer? = PortableLayer()
            releasedLayer = layer
            PortableTransaction.begin()
            PortableTransaction.setCompletionBlock { completionCalls += 1 }
            let finite = PortableBasicAnimation(keyPath: "opacity")
            finite.duration = 20
            finite.fromValue = 0.0
            finite.toValue = 1.0
            layer!.add(finite, forKey: "owned")
            PortableTransaction.commit()
            layer = nil
        }
        XCTAssertNil(releasedLayer)
        XCTAssertEqual(OpenUIKitRuntime.animationWorkDeadline, -.infinity)
        PortableTransaction.flush()
        XCTAssertEqual(completionCalls, 1)
        XCTAssertEqual(PortableTransaction._workRegistryCountForTesting, 0)

        let churnLayer = PortableLayer()
        for _ in 0..<20_000 {
            let animation = PortableBasicAnimation(keyPath: "opacity")
            animation.duration = 1
            animation.fromValue = 0.0
            animation.toValue = 1.0
            churnLayer.add(animation, forKey: "churn")
            churnLayer.removeAnimation(forKey: "churn")
        }
        XCTAssertEqual(PortableTransaction._workRegistryCountForTesting, 0)
    }

    func testEndpointShapesAreStrictAndNilModelLocationsCanAnimate() {
        let layer = PortableLayer()
        let scalarDouble: Double = 0.25
        let scalar = PortableBasicAnimation(keyPath: "opacity")
        scalar.fromValue = scalarDouble
        scalar.toValue = Double(0.75)
        XCTAssertNotNil(layer._resolvedEndpoints(for: scalar,
                                                  keyPath: "opacity"),
                        "Linux Double is distinct from Foundation.CGFloat")

        let size = PortableBasicAnimation(keyPath: "bounds.size")
        size.fromValue = CGSize(width: 10, height: 20)
        size.toValue = CGSize(width: 30, height: 40)
        XCTAssertNotNil(layer._resolvedEndpoints(for: size,
                                                  keyPath: "bounds.size"))

        let wrongOpacity = PortableBasicAnimation(keyPath: "opacity")
        wrongOpacity.fromValue = CGPoint.zero
        wrongOpacity.toValue = CGPoint(x: 1, y: 1)
        XCTAssertNil(layer._resolvedEndpoints(for: wrongOpacity,
                                               keyPath: "opacity"))

        let mixedPosition = PortableBasicAnimation(keyPath: "position")
        mixedPosition.fromValue = CGPoint.zero
        mixedPosition.toValue = 1.0
        XCTAssertNil(layer._resolvedEndpoints(for: mixedPosition,
                                               keyPath: "position"))

        let gradient = PortableGradientLayer()
        gradient.colors = [
            PortableCGColor(red: 1, green: 0, blue: 0, alpha: 1),
            PortableCGColor(red: 0, green: 0, blue: 1, alpha: 1),
        ]
        XCTAssertNil(gradient.locations)
        let supplied = PortableBasicAnimation(keyPath: "locations")
        let suppliedFrom: [Double] = [0.0, 0.25]
        let suppliedTo: [Double] = [0.75, 1.0]
        supplied.fromValue = suppliedFrom
        supplied.toValue = suppliedTo
        XCTAssertNotNil(gradient._resolvedEndpoints(for: supplied,
                                                     keyPath: "locations"),
                        "Linux [Double] is distinct from [Foundation.CGFloat]")

        gradient.colors!.append(
            PortableCGColor(red: 0, green: 1, blue: 0, alpha: 1))
        let focusShape = PortableBasicAnimation(keyPath: "locations")
        focusShape.fromValue = [0.0, 0.0, 0.0, 0.2, 0.4, 0.6, 0.8]
        focusShape.toValue = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.0]
        XCTAssertNotNil(gradient._resolvedEndpoints(for: focusShape,
                                                     keyPath: "locations"),
                        "Focus intentionally supplies seven stops for three colors")

        let unequal = PortableBasicAnimation(keyPath: "locations")
        unequal.fromValue = [0.0, 0.5]
        unequal.toValue = [0.0, 0.5, 1.0]
        XCTAssertNil(gradient._resolvedEndpoints(for: unequal,
                                                  keyPath: "locations"))
        let omitted = PortableBasicAnimation(keyPath: "locations")
        omitted.toValue = [0.5, 1.0]
        XCTAssertNil(gradient._resolvedEndpoints(for: omitted,
                                                  keyPath: "locations"))
    }

    func testByValueEndpointPrecedenceMatchesNativeCoreAnimation() {
        func midpoint(
            from: Any? = nil, to: Any? = nil, by: Any? = nil
        ) -> CGFloat {
            let layer = PortableLayer()
            layer.cornerRadius = 0.5
            let animation = PortableBasicAnimation(keyPath: "cornerRadius")
            animation.duration = 10
            animation.fromValue = from
            animation.toValue = to
            animation.byValue = by
            layer.add(animation, forKey: "probe")
            return layer._presentationState(at: 15).cornerRadius
        }

        XCTAssertEqual(midpoint(from: 1.0, to: 9.0, by: 2.0), 5,
                       accuracy: 0.0001)
        XCTAssertEqual(midpoint(from: 1.0, by: 2.0), 2,
                       accuracy: 0.0001)
        XCTAssertEqual(midpoint(to: 9.0, by: 2.0), 8,
                       accuracy: 0.0001)
        XCTAssertEqual(midpoint(from: 1.0), 0.75, accuracy: 0.0001)
        XCTAssertEqual(midpoint(to: 9.0), 4.75, accuracy: 0.0001)
        XCTAssertEqual(midpoint(by: 2.0), 1.5, accuracy: 0.0001)
        XCTAssertEqual(midpoint(), 0.5, accuracy: 0.0001)

        // iOS ignores the third value when a complete from/to pair exists,
        // even when that ignored byValue has the wrong dynamic shape.
        XCTAssertEqual(
            midpoint(from: 1.0, to: 9.0, by: CGPoint(x: 2, y: 3)),
            5,
            accuracy: 0.0001
        )
    }

    func testByValueArithmeticCoversEveryDecodedValueShape() {
        let scalar = PortableLayer()
        scalar.borderWidth = 2
        let scalarAnimation = PortableBasicAnimation(keyPath: "borderWidth")
        scalarAnimation.duration = 2
        scalarAnimation.byValue = 6.0
        scalar.add(scalarAnimation, forKey: "scalar")
        XCTAssertEqual(scalar._presentationState(at: 11).borderWidth, 5,
                       accuracy: 0.0001)

        let point = PortableLayer()
        point.anchorPoint = CGPoint(x: 0.2, y: 0.3)
        let pointAnimation = PortableBasicAnimation(keyPath: "anchorPoint")
        pointAnimation.duration = 2
        pointAnimation.byValue = CGPoint(x: 0.4, y: 0.6)
        point.add(pointAnimation, forKey: "point")
        let presentedPoint = point._presentationState(at: 11).anchorPoint
        XCTAssertEqual(presentedPoint.x, 0.4, accuracy: 0.0001)
        XCTAssertEqual(presentedPoint.y, 0.6, accuracy: 0.0001)

        let size = PortableLayer()
        size.shadowOffset = CGSize(width: 2, height: 4)
        let sizeAnimation = PortableBasicAnimation(keyPath: "shadowOffset")
        sizeAnimation.duration = 2
        sizeAnimation.byValue = CGSize(width: 6, height: 8)
        size.add(sizeAnimation, forKey: "size")
        XCTAssertEqual(size._presentationState(at: 11).shadowOffset,
                       CGSize(width: 5, height: 8))

        let rect = PortableLayer()
        rect.bounds = CGRect(x: 1, y: 2, width: 20, height: 30)
        let rectAnimation = PortableBasicAnimation(keyPath: "bounds")
        rectAnimation.duration = 2
        rectAnimation.byValue = CGRect(x: 4, y: 6, width: 8, height: 10)
        rect.add(rectAnimation, forKey: "rect")
        XCTAssertEqual(rect._presentationState(at: 11).bounds,
                       CGRect(x: 3, y: 5, width: 24, height: 35))

        let vector = PortableGradientLayer()
        vector.colors = [
            PortableCGColor(red: 1, green: 0, blue: 0, alpha: 1),
            PortableCGColor(red: 0, green: 0, blue: 1, alpha: 1),
        ]
        vector.locations = [0.2, 0.4]
        let vectorAnimation = PortableBasicAnimation(keyPath: "locations")
        vectorAnimation.duration = 2
        vectorAnimation.byValue = [0.3, 0.4]
        vector.add(vectorAnimation, forKey: "vector")
        let locations = vector._presentationState(at: 11).locations!
        XCTAssertEqual(locations[0], 0.35, accuracy: 0.0001)
        XCTAssertEqual(locations[1], 0.6, accuracy: 0.0001)
    }

    func testByValueShapeValidationHappensOnlyWhenByValueParticipates() {
        let layer = PortableLayer()
        let invalid = PortableBasicAnimation(keyPath: "opacity")
        invalid.byValue = CGPoint(x: 1, y: 2)
        XCTAssertNil(layer._resolvedEndpoints(for: invalid,
                                               keyPath: "opacity"))

        let ignored = PortableBasicAnimation(keyPath: "opacity")
        ignored.fromValue = 0.0
        ignored.toValue = 1.0
        ignored.byValue = CGPoint(x: 1, y: 2)
        XCTAssertNotNil(layer._resolvedEndpoints(for: ignored,
                                                  keyPath: "opacity"))

        let gradient = PortableGradientLayer()
        let mismatched = PortableBasicAnimation(keyPath: "locations")
        mismatched.fromValue = [0.0, 0.5]
        mismatched.byValue = [0.1, 0.2, 0.3]
        XCTAssertNil(gradient._resolvedEndpoints(for: mismatched,
                                                  keyPath: "locations"))
    }

    func testByValueAndFromOnlyStartFromInterruptedRenderTreeValue() {
        let fromOnly = PortableLayer()
        fromOnly.cornerRadius = 10
        let first = PortableBasicAnimation(keyPath: "cornerRadius")
        first.duration = 2
        first.fromValue = 0.0
        first.toValue = 8.0
        fromOnly.add(first, forKey: "radius")

        OpenUIKitRuntime.animationTime = 11
        let replacement = PortableBasicAnimation(keyPath: "cornerRadius")
        replacement.duration = 2
        replacement.fromValue = 2.0
        fromOnly.add(replacement, forKey: "radius")
        XCTAssertEqual(fromOnly._presentationState(at: 12).cornerRadius, 3,
                       accuracy: 0.0001,
                       "from-only ends at the interrupted presentation (4)")

        let byOnly = PortableLayer()
        byOnly.borderWidth = 10
        let old = PortableBasicAnimation(keyPath: "borderWidth")
        old.duration = 2
        old.fromValue = 1.0
        old.toValue = 5.0
        OpenUIKitRuntime.animationTime = 20
        byOnly.add(old, forKey: "border")

        OpenUIKitRuntime.animationTime = 21
        let additive = PortableBasicAnimation(keyPath: "borderWidth")
        additive.duration = 2
        additive.byValue = 2.0
        byOnly.add(additive, forKey: "border")
        XCTAssertEqual(byOnly._presentationState(at: 22).borderWidth, 4,
                       accuracy: 0.0001,
                       "by-only starts at interrupted presentation 3")
    }

    func testNumericLayerPropertiesImplicitlyAnimateOnHostClock() {
        let layer = PortableLayer()
        layer.anchorPoint = CGPoint(x: 0, y: 0)
        layer.borderWidth = 0
        layer.shadowOpacity = 0
        layer.shadowRadius = 0
        layer.shadowOffset = .zero

        PortableTransaction.begin()
        PortableTransaction.setAnimationDuration(2)
        layer.anchorPoint = CGPoint(x: 1, y: 0.5)
        layer.borderWidth = 4
        layer.shadowOpacity = 0.8
        layer.shadowRadius = 6
        layer.shadowOffset = CGSize(width: 8, height: 10)
        PortableTransaction.commit()

        let middle = layer._presentationState(at: 11)
        XCTAssertEqual(middle.anchorPoint, CGPoint(x: 0.5, y: 0.25))
        XCTAssertEqual(middle.borderWidth, 2, accuracy: 0.0001)
        XCTAssertEqual(middle.shadowOpacity, 0.4, accuracy: 0.0001)
        XCTAssertEqual(middle.shadowRadius, 3, accuracy: 0.0001)
        XCTAssertEqual(middle.shadowOffset, CGSize(width: 4, height: 5))
    }

    func testAnimatedAnchorAndBorderWidthRenderInBothCompositors() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 16))
        let child = UIView(frame: CGRect(x: 8, y: 4, width: 8, height: 8))
        child.backgroundColor = .white
        child.layer.borderColor = PortableCGColor(
            red: 1, green: 0, blue: 0, alpha: 1)
        child.layer.borderWidth = 4
        root.addSubview(child)

        let anchor = PortableBasicAnimation(keyPath: "anchorPoint")
        anchor.duration = 2
        anchor.fromValue = CGPoint(x: 0.5, y: 0.5)
        anchor.byValue = CGPoint(x: 0.5, y: 0)
        child.layer.add(anchor, forKey: "anchor")
        let border = PortableBasicAnimation(keyPath: "borderWidth")
        border.duration = 2
        border.fromValue = 0.0
        border.byValue = 4.0
        child.layer.add(border, forKey: "border")
        OpenUIKitRuntime.animationTime = 11

        for bitmap in [
            LayerBridge.render(root, scale: 1),
            UIRenderer.renderPassRender(root, scale: 1),
        ] {
            func rgba(_ x: Int, _ y: Int) -> ArraySlice<UInt8> {
                let start = (y * bitmap.width + x) * 4
                return bitmap.pixels[start..<(start + 4)]
            }
            XCTAssertGreaterThan(rgba(6, 8)[rgba(6, 8).startIndex + 3], 240,
                                 "animated anchor moves the left edge to x=6")
            XCTAssertEqual(rgba(14, 8)[rgba(14, 8).startIndex + 3], 0)
            XCTAssertLessThan(rgba(7, 8)[rgba(7, 8).startIndex + 1], 16,
                              "two-point presented border covers x=7")
            XCTAssertGreaterThan(rgba(9, 8)[rgba(9, 8).startIndex + 1], 240,
                                 "presented border is 2, not model width 4")
        }
    }

    func testAnimatedShadowPresentationDrivesBothCompositors() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 32, height: 16))
        let child = UIView(frame: CGRect(x: 4, y: 6, width: 8, height: 4))
        child.backgroundColor = .white
        child.layer.shadowColor = PortableCGColor(
            red: 0, green: 0, blue: 0, alpha: 1)
        child.layer.shadowOpacity = 1
        child.layer.shadowRadius = 2
        child.layer.shadowOffset = CGSize(width: 4, height: 0)
        root.addSubview(child)

        let opacity = PortableBasicAnimation(keyPath: "shadowOpacity")
        opacity.duration = 2
        opacity.fromValue = 0.0
        opacity.byValue = 1.0
        child.layer.add(opacity, forKey: "shadowOpacity")
        let radius = PortableBasicAnimation(keyPath: "shadowRadius")
        radius.duration = 2
        radius.fromValue = 0.0
        radius.byValue = 2.0
        child.layer.add(radius, forKey: "shadowRadius")
        let offset = PortableBasicAnimation(keyPath: "shadowOffset")
        offset.duration = 2
        offset.fromValue = CGSize.zero
        offset.byValue = CGSize(width: 4, height: 0)
        child.layer.add(offset, forKey: "shadowOffset")

        let middle = child.layer._presentationState(at: 11)
        XCTAssertEqual(middle.shadowOpacity, 0.5, accuracy: 0.0001)
        XCTAssertEqual(middle.shadowRadius, 1, accuracy: 0.0001)
        XCTAssertEqual(middle.shadowOffset, CGSize(width: 2, height: 0))

        for renderer: (UIView) -> Bitmap in [
            { LayerBridge.render($0, scale: 1) },
            { UIRenderer.renderPassRender($0, scale: 1) },
        ] {
            OpenUIKitRuntime.animationTime = 10
            let start = renderer(root)
            XCTAssertEqual(start.pixels[(8 * start.width + 13) * 4 + 3], 0,
                           "zero presented opacity casts no model shadow")
            OpenUIKitRuntime.animationTime = 11
            let middleFrame = renderer(root)
            XCTAssertGreaterThan(
                middleFrame.pixels[(8 * middleFrame.width + 13) * 4 + 3], 0,
                "presented offset/radius/opacity cast a live shadow"
            )
        }
    }

    func testBackingLayerComposesUIViewBoundsWithExplicitSize() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 10))
        view.bounds = CGRect(x: 10, y: 2, width: 20, height: 10)
        UIView.animate(withDuration: 2) {
            view.bounds = CGRect(x: 20, y: 6, width: 40, height: 20)
        }
        let size = PortableBasicAnimation(keyPath: "bounds.size")
        size.duration = 2
        size.fromValue = CGSize(width: 20, height: 10)
        size.toValue = CGSize(width: 60, height: 30)
        view.layer.add(size, forKey: "size")

        let state = LayerBridge.presentationState(of: view, at: 11)
        XCTAssertEqual(state.bounds.origin, CGPoint(x: 15, y: 4))
        XCTAssertEqual(state.bounds.size, CGSize(width: 40, height: 20))
    }

    func testPresentedBoundsDriveContentGenerationPlacementAndCache() {
        let view = PresentedBoundsContentProbe(
            frame: CGRect(x: 0, y: 0, width: 12, height: 4))
        let bounds = PortableBasicAnimation(keyPath: "bounds")
        bounds.duration = 2
        bounds.fromValue = CGRect(x: 0, y: 0, width: 4, height: 4)
        bounds.toValue = CGRect(x: 0, y: 0, width: 12, height: 4)
        view.layer.add(bounds, forKey: "bounds")

        OpenUIKitRuntime.animationTime = 10
        _ = LayerBridge.render(view, scale: 1)
        _ = LayerBridge.render(view, scale: 1)
        XCTAssertEqual(view.sampledBounds, [
            CGRect(x: 0, y: 0, width: 4, height: 4),
        ], "unchanged presented bounds should reuse the content image")

        OpenUIKitRuntime.animationTime = 11
        let layers = LayerBridge.render(view, scale: 1)
        XCTAssertEqual(view.sampledBounds.last,
                       CGRect(x: 0, y: 0, width: 8, height: 4))
        XCTAssertEqual(view.sampledBounds.count, 2,
                       "presented-size change must invalidate content cache")
        let renderPass = UIRenderer.renderPassRender(view, scale: 1)
        XCTAssertEqual(view.sampledBounds.last,
                       CGRect(x: 0, y: 0, width: 8, height: 4))
        for bitmap in [layers, renderPass] {
            XCTAssertGreaterThan(bitmap.pixels[(2 * 12 + 7) * 4 + 3], 240)
            XCTAssertEqual(bitmap.pixels[(2 * 12 + 10) * 4 + 3], 0)
        }
    }

    func testBackingLayerMaskUsesPresentedGeometryAlphaAndBypassesCache() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 8))
        let view = UIView(frame: root.bounds)
        view.backgroundColor = .white
        root.addSubview(view)
        let mask = PortableLayer()
        mask.anchorPoint = CGPoint(x: 0, y: 0)
        mask.frame = CGRect(x: 0, y: 0, width: 8, height: 8)
        mask.backgroundColor = PortableCGColor(
            red: 1, green: 1, blue: 1, alpha: 1)
        view.layer.mask = mask

        let opaque = LayerBridge.render(root, scale: 1)
        XCTAssertGreaterThan(opaque.pixels[(4 * 20 + 4) * 4 + 3], 240)
        XCTAssertEqual(opaque.pixels[(4 * 20 + 12) * 4 + 3], 0)

        mask.backgroundColor = PortableCGColor(
            red: 1, green: 1, blue: 1, alpha: 0.5)
        _ = LayerBridge.render(root, scale: 1)
        PortableTransaction.begin()
        PortableTransaction.setAnimationDuration(2)
        mask.frame = CGRect(x: 0, y: 0, width: 16, height: 8)
        PortableTransaction.commit()
        OpenUIKitRuntime.animationTime = 11

        for bitmap in [
            LayerBridge.render(root, scale: 1),
            UIRenderer.renderPassRender(root, scale: 1),
        ] {
            let inside = bitmap.pixels[(4 * 20 + 10) * 4 + 3]
            XCTAssertGreaterThanOrEqual(inside, 126)
            XCTAssertLessThanOrEqual(inside, 129)
            XCTAssertEqual(bitmap.pixels[(4 * 20 + 14) * 4 + 3], 0)
        }
    }

    func testBackingMaskCoversGroupedShadowInBothCompositors() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 8))
        view.backgroundColor = .white
        view.alpha = 0.5
        view.layer.shadowColor = PortableCGColor(
            red: 0, green: 0, blue: 0, alpha: 1)
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 0
        view.layer.shadowOffset = .zero

        let mask = PortableLayer()
        mask.anchorPoint = .zero
        mask.frame = CGRect(x: 0, y: 0, width: 5, height: 8)
        mask.backgroundColor = PortableCGColor(
            red: 1, green: 1, blue: 1, alpha: 1)
        view.layer.mask = mask

        // Measured with QuartzCore CALayer.render(in:): the mask is an
        // outer alpha mask over both the group-opacity content and its
        // shadow. It does not leave an unmasked shadow in x=5..<20.
        for bitmap in [
            LayerBridge.render(view, scale: 1),
            UIRenderer.renderPassRender(view, scale: 1),
        ] {
            let row = (0..<20).map { bitmap.pixels[(4 * 20 + $0) * 4 + 3] }
            XCTAssertEqual(row, [UInt8](repeating: 192, count: 5)
                + [UInt8](repeating: 0, count: 15))
        }

        // A translucent mask attenuates the already-composited 0.75 alpha
        // once (0.75 * 0.5 = 0.375 -> 96), rather than attenuating the
        // overlapping shadow and content as independent draw operations.
        mask.backgroundColor = PortableCGColor(
            red: 1, green: 1, blue: 1, alpha: 0.5)
        for bitmap in [
            LayerBridge.render(view, scale: 1),
            UIRenderer.renderPassRender(view, scale: 1),
        ] {
            let row = (0..<20).map { bitmap.pixels[(4 * 20 + $0) * 4 + 3] }
            XCTAssertEqual(row, [UInt8](repeating: 96, count: 5)
                + [UInt8](repeating: 0, count: 15))
        }
    }

    func testRoundedBackingMaskCoverageWrapsFinalGroupComposite() {
        let savedBackend = OpenUIKitRuntime.renderBackend
        OpenUIKitRuntime.renderBackend = .quartz
        defer { OpenUIKitRuntime.renderBackend = savedBackend }

        let view = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 8))
        view.backgroundColor = .white
        view.alpha = 0.5
        view.layer.shadowColor = PortableCGColor(
            red: 0, green: 0, blue: 0, alpha: 1)
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 0
        view.layer.shadowOffset = .zero

        let mask = PortableLayer()
        mask.anchorPoint = .zero
        mask.frame = CGRect(x: 0, y: 0, width: 5, height: 8)
        mask.cornerRadius = 3
        mask.backgroundColor = PortableCGColor(
            red: 1, green: 1, blue: 1, alpha: 1)
        view.layer.mask = mask

        for maskOpacity: CGFloat in [1, 0.5] {
            mask.backgroundColor = PortableCGColor(
                red: 1, green: 1, blue: 1, alpha: maskOpacity)
            let bridge = LayerBridge.render(view, scale: 4)
            let expectedPrefix: [UInt8] = maskOpacity == 1
                ? [0, 0, 59, 190] + [UInt8](repeating: 192, count: 12)
                    + [190, 59, 0, 0]
                : [0, 0, 29, 95] + [UInt8](repeating: 96, count: 12)
                    + [95, 29, 0, 0]
            let bridgeRow = (0..<bridge.width).map {
                bridge.pixels[(4 * bridge.width + $0) * 4 + 3]
            }
            XCTAssertEqual(bridgeRow,
                           expectedPrefix + [UInt8](repeating: 0, count: 60))

            for backend: RenderBackend in [.quartz, .swift] {
                OpenUIKitRuntime.renderBackend = backend
                let renderPass = UIRenderer.renderPassRender(view, scale: 4)

                // Obtain this backend's geometric mask coverage without a
                // shadow/group overlap. The correct grouped result is that
                // completed 0.75-alpha composite multiplied by coverage once.
                view.alpha = 1
                view.layer.shadowOpacity = 0
                let coverage = UIRenderer.renderPassRender(view, scale: 4)
                view.alpha = 0.5
                view.layer.shadowOpacity = 1
                let actualAlpha = stride(from: 3, to: renderPass.pixels.count,
                                         by: 4).map { renderPass.pixels[$0] }
                let expectedAlpha = stride(from: 3, to: coverage.pixels.count,
                                           by: 4).map {
                    UInt8((Int(coverage.pixels[$0]) * 192 + 127) / 255)
                }
                XCTAssertEqual(actualAlpha, expectedAlpha,
                               "\(backend) must apply curved coverage once")
                if case .quartz = backend {
                    XCTAssertEqual(renderPass.pixels, bridge.pixels,
                                   "QZ renderers must agree byte-for-byte")
                }
            }
        }
    }

    func testPresentedRootBoundsControlNeutralizationCullingAndShadow() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 8))
        root.bounds = CGRect(x: 20, y: 0, width: 30, height: 8)
        let child = UIView(frame: CGRect(x: 2, y: 1, width: 6, height: 6))
        child.backgroundColor = .white
        root.addSubview(child)
        let reveal = PortableBasicAnimation(keyPath: "bounds")
        reveal.duration = 2
        reveal.fromValue = CGRect(x: 0, y: 0, width: 30, height: 8)
        reveal.toValue = root.bounds
        root.layer.add(reveal, forKey: "reveal")

        let bitmap = LayerBridge.render(root, scale: 1)
        XCTAssertGreaterThan(bitmap.pixels[(4 * 30 + 5) * 4 + 3], 240,
                             "presented root region must not cull its child")

        let shadowRoot = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 6))
        shadowRoot.bounds.size.width = 10
        shadowRoot.backgroundColor = .white
        shadowRoot.alpha = 0.5
        shadowRoot.layer.shadowOpacity = 1
        shadowRoot.layer.shadowOffset = .zero
        shadowRoot.layer.shadowRadius = 0
        UIView.animate(withDuration: 2) {
            shadowRoot.bounds.size.width = 20
        }
        for rendered in [
            LayerBridge.render(shadowRoot, scale: 1),
            UIRenderer.renderPassRender(shadowRoot, scale: 1),
        ] {
            XCTAssertGreaterThan(rendered.pixels[(3 * 20 + 5) * 4 + 3], 0)
            XCTAssertEqual(rendered.pixels[(3 * 20 + 14) * 4 + 3], 0,
                           "shadow silhouette must use presented bounds")
        }
    }
}
