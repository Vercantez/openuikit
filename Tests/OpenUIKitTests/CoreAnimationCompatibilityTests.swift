import XCTest
@testable import OpenUIKit

private typealias PortableLayer = OpenUIKit.CALayer
private typealias PortableGradientLayer = OpenUIKit.CAGradientLayer
private typealias PortableBasicAnimation = OpenUIKit.CABasicAnimation
private typealias PortableTransaction = OpenUIKit.CATransaction
private typealias PortableCGColor = OpenUIKit.CGColor

@MainActor
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

@MainActor
final class CoreAnimationCompatibilityTests: XCTestCase {
    private var savedTime: Double = 0
    private var savedDeadline: Double = 0

    override func setUp() {
        super.setUp()
        savedTime = OpenUIKitRuntime.animationTime
        savedDeadline = OpenUIKitRuntime.animationWorkDeadline
        OpenUIKitRuntime.animationTime = 10
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
        locationAnimation.fromValue = [CGFloat(0), CGFloat(0.5)]
        locationAnimation.toValue = [CGFloat(0.5), CGFloat(1)]
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
}
