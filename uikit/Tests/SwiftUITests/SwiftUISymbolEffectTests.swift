import XCTest
import Symbols
#if os(Linux)
@preconcurrency @testable import SwiftUI
#else
@testable import SwiftUI
#endif
#if os(Linux)
@preconcurrency @testable import OpenUIKit
#else
@testable import OpenUIKit
#endif

final class SwiftUISymbolEffectTests: XCTestCase {
    func testEffectValuesPreserveDirectionLayerAndMode() {
        XCTAssertNotEqual(PulseSymbolEffect.pulse, .pulse.byLayer)
        XCTAssertNotEqual(BounceSymbolEffect.bounce.up, .bounce.down)
        XCTAssertNotEqual(BounceSymbolEffect.bounce.up.byLayer, .bounce.up.wholeSymbol)
        XCTAssertNotEqual(
            VariableColorSymbolEffect.variableColor.iterative.hideInactiveLayers,
            .variableColor.cumulative.dimInactiveLayers
        )
        XCTAssertNotEqual(WiggleSymbolEffect.wiggle.clockwise, .wiggle.counterClockwise)
        XCTAssertNotEqual(DrawOffSymbolEffect.drawOff.reversed, .drawOff.nonReversed)
    }

    func testOptionsComposeWithoutDiscardingPriorState() {
        XCTAssertNotEqual(SymbolEffectOptions.default, .speed(0.5))
        XCTAssertNotEqual(
            SymbolEffectOptions.speed(0.5).repeat(.periodic(3, delay: 0.2)),
            SymbolEffectOptions.speed(1).repeat(.periodic(3, delay: 0.2))
        )
        XCTAssertNotEqual(
            SymbolEffectOptions.speed(0.5).repeat(.periodic(3, delay: 0.2)),
            SymbolEffectOptions.speed(0.5).repeat(.continuous)
        )
    }

    func testButtonKitProtocolFamiliesCompile() {
        func requireIndefinite<T: SymbolEffect & IndefiniteSymbolEffect>(_: T) {}
        func requireDiscrete<T: SymbolEffect & DiscreteSymbolEffect>(_: T) {}

        requireIndefinite(AppearSymbolEffect.appear)
        requireIndefinite(DisappearSymbolEffect.disappear)
        requireIndefinite(ScaleSymbolEffect.scale)
        requireIndefinite(DrawOnSymbolEffect.drawOn)
        requireIndefinite(DrawOffSymbolEffect.drawOff)
        requireDiscrete(BounceSymbolEffect.bounce)
        requireDiscrete(PulseSymbolEffect.pulse)
        requireDiscrete(VariableColorSymbolEffect.variableColor)
        requireDiscrete(BreatheSymbolEffect.breathe)
        requireDiscrete(RotateSymbolEffect.rotate)
        requireDiscrete(WiggleSymbolEffect.wiggle)
    }

    func testIndefiniteEffectLowersToVisibleRenderState() throws {
        let controller = UIHostingController(
            rootView: Image(systemName: "arrow.clockwise")
                .symbolEffect(.pulse, isActive: true)
        )
        let root = try XCTUnwrap(controller.view)
        root.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        root.layoutIfNeeded()

        let effect = try XCTUnwrap(
            descendant(root, identifier: "SwiftUI.SymbolEffect.pulse")
        )
        let opacity = try XCTUnwrap(
            descendants(effect).first { $0.accessibilityIdentifier == "SwiftUI.Opacity" }
        )
        XCTAssertEqual(opacity.alpha, 0.72, accuracy: 0.001)
    }

    func testInactiveEffectPreservesIdentityAndRestState() throws {
        let controller = UIHostingController(
            rootView: Image(systemName: "arrow.clockwise")
                .symbolEffect(.pulse, isActive: false)
        )
        let root = try XCTUnwrap(controller.view)
        root.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        root.layoutIfNeeded()

        let effect = try XCTUnwrap(
            descendant(root, identifier: "SwiftUI.SymbolEffect.pulse")
        )
        let opacity = try XCTUnwrap(
            descendants(effect).first { $0.accessibilityIdentifier == "SwiftUI.Opacity" }
        )
        XCTAssertEqual(opacity.alpha, 1, accuracy: 0.001)
    }

    func testDiscreteEffectLowersToTransformRenderState() throws {
        let controller = UIHostingController(
            rootView: Image(systemName: "exclamationmark.triangle")
                .symbolEffect(.bounce, value: 1)
        )
        let root = try XCTUnwrap(controller.view)
        root.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        root.layoutIfNeeded()

        let effect = try XCTUnwrap(
            descendant(root, identifier: "SwiftUI.SymbolEffect.bounce")
        )
        let scale = try XCTUnwrap(
            descendants(effect).first { $0.accessibilityIdentifier == "SwiftUI.ScaleEffect" }
        )
        XCTAssertNotEqual(scale.transform, .identity)
    }

    private func descendant(_ root: UIView, identifier: String) -> UIView? {
        ([root] + descendants(root)).first { $0.accessibilityIdentifier == identifier }
    }

    private func descendants(_ root: UIView) -> [UIView] {
        root.subviews.flatMap { [$0] + descendants($0) }
    }
}
