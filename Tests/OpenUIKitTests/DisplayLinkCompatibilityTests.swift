import XCTest
@testable import OpenUIKit

@MainActor
final class DisplayLinkCompatibilityTests: XCTestCase {
    override func setUp() async throws {
        OpenUIKit.CADisplayLink._reset()
    }

    override func tearDown() async throws {
        OpenUIKit.CADisplayLink._reset()
    }

    func testAppleShapedContentModeAndCoreTimeAlias() {
        let mode: UIView.ContentMode = .scaleAspectFit
        XCTAssertEqual(mode, UIViewContentMode.scaleAspectFit)
        let interval: CFTimeInterval = 1.0 / 60.0
        XCTAssertEqual(interval, 1.0 / 60.0)
    }

    func testPortableDisplayLinkRunsOnWindowHostClock() {
        final class Target: SelectorDispatching {
            var timestamps: [CFTimeInterval] = []
            func perform(_ selectorName: String, with sender: Any?) -> Bool {
                guard selectorName == "tick:",
                      let link = sender as? OpenUIKit.CADisplayLink else {
                    return false
                }
                timestamps.append(link.timestamp)
                return true
            }
        }

        let target = Target()
        let link = OpenUIKit.CADisplayLink(target: target, selector: .named("tick:"))
        XCTAssertFalse(link.isPaused)
        XCTAssertEqual(link.duration, 1.0 / 60.0)
        link.add(to: .main, forMode: .common)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        window.tick(timestamp: 0.25)
        window.tick(timestamp: 0.5)
        XCTAssertEqual(target.timestamps, [0.25, 0.5])
        XCTAssertEqual(link.targetTimestamp, 0.5 + 1.0 / 60.0, accuracy: 1e-12)

        link.isPaused = true
        window.tick(timestamp: 0.75)
        XCTAssertEqual(target.timestamps, [0.25, 0.5])
        link.invalidate()
        XCTAssertFalse(OpenUIKit.CADisplayLink._hasActiveDisplayLinks)
    }

    func testLayerDisplayCallsOverridableUIImageViewSurface() {
        final class AnimatedImageView: UIImageView {
            var displayCount = 0
            override func display(_ layer: OpenUIKit.CALayer) {
                super.display(layer)
                displayCount += 1
            }
        }

        let imageView = AnimatedImageView(frame: .zero)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        window.addSubview(imageView)
        imageView.layer.setNeedsDisplay()
        window.tick(timestamp: 1)
        XCTAssertEqual(imageView.displayCount, 1)
        window.tick(timestamp: 2)
        XCTAssertEqual(imageView.displayCount, 1)
    }

#if canImport(ObjectiveC)
    func testDisplayLinkInvokesObjectiveCVisibleSwiftRootTarget() {
        final class RootTarget {
            var callCount = 0
            @MainActor @objc func tick(_ link: OpenUIKit.CADisplayLink) {
                _ = link.duration
                callCount += 1
            }
        }

        let target = RootTarget()
        let link = OpenUIKit.CADisplayLink(
            target: target,
            selector: #selector(RootTarget.tick(_:))
        )
        link.add(to: OpenUIKit.RunLoop.main, forMode: OpenUIKit.RunLoop.Mode.common)
        UIWindow(frame: .zero).tick(timestamp: 3)
        XCTAssertEqual(target.callCount, 1)
    }
#endif
}
