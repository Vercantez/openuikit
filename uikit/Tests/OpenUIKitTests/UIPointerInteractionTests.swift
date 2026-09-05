import XCTest
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
private final class PointerStyleDelegate: UIPointerInteractionDelegate {
    var styleRequests = 0

    func pointerInteraction(_ interaction: UIPointerInteraction,
                            styleFor region: UIPointerRegion) -> UIPointerStyle? {
        styleRequests += 1
        guard let view = interaction.view else { return nil }
        return UIPointerStyle(effect: .lift(UITargetedPreview(view: view)))
    }
}

#if !os(Linux)
@MainActor
#endif
private final class DefaultPointerDelegate: UIPointerInteractionDelegate {}

#if !os(Linux)
@MainActor
#endif
private final class TrackingInteraction: UIInteraction {
    private(set) weak var view: UIView?
    var moves: [String] = []

    func willMove(to view: UIView?) {
        moves.append(view == nil ? "will:nil" : "will:view")
    }

    func didMove(to view: UIView?) {
        self.view = view
        moves.append(view == nil ? "did:nil" : "did:view")
    }
}

#if !os(Linux)
@MainActor
#endif
final class UIPointerInteractionTests: XCTestCase {
    func testInteractionDefaultsAndAttachmentLifecycle() {
        let delegate = PointerStyleDelegate()
        let interaction = UIPointerInteraction(delegate: delegate)
        let first = UIView()
        let second = UIView()

        XCTAssertTrue(interaction.delegate === delegate)
        XCTAssertTrue(interaction.isEnabled)
        XCTAssertNil(interaction.view)

        first.addInteraction(interaction)
        XCTAssertTrue(interaction.view === first)
        XCTAssertEqual(first.interactions.count, 1)

        // UIKit retargets one interaction rather than leaving it registered
        // in both views.
        second.addInteraction(interaction)
        XCTAssertTrue(first.interactions.isEmpty)
        XCTAssertEqual(second.interactions.count, 1)
        XCTAssertTrue(second.interactions.first === interaction)
        XCTAssertTrue(interaction.view === second)

        second.removeInteraction(interaction)
        XCTAssertTrue(second.interactions.isEmpty)
        XCTAssertNil(interaction.view)
    }

    func testAddInteractionRetargetsAnyUIInteractionInLifecycleOrder() {
        let interaction = TrackingInteraction()
        let first = UIView()
        let second = UIView()

        first.addInteraction(interaction)
        first.addInteraction(interaction)
        XCTAssertEqual(first.interactions.count, 1)
        XCTAssertEqual(interaction.moves, ["will:view", "did:view"])

        // Removing an interaction from a view that does not own it is inert.
        second.removeInteraction(interaction)
        XCTAssertTrue(interaction.view === first)
        XCTAssertEqual(interaction.moves, ["will:view", "did:view"])

        second.addInteraction(interaction)

        XCTAssertTrue(first.interactions.isEmpty)
        XCTAssertTrue(second.interactions.first === interaction)
        XCTAssertTrue(interaction.view === second)
        XCTAssertEqual(interaction.moves,
                       ["will:view", "did:view", "will:nil", "did:nil",
                        "will:view", "did:view"])
    }

    func testDelegateIsWeak() {
        var delegate: PointerStyleDelegate? = PointerStyleDelegate()
        let interaction = UIPointerInteraction(delegate: delegate)
        XCTAssertNotNil(interaction.delegate)

        delegate = nil
        XCTAssertNil(interaction.delegate)
    }

    func testDisabledOrDetachedInteractionDoesNotResolveStyle() {
        let delegate = PointerStyleDelegate()
        let interaction = UIPointerInteraction(delegate: delegate)
        let view = UIView()
        let region = UIPointerRegion(rect: view.bounds)

        XCTAssertNil(interaction._resolvedStyle(for: region))
        XCTAssertEqual(delegate.styleRequests, 0)

        view.addInteraction(interaction)
        let style = interaction._resolvedStyle(for: region)
        XCTAssertNotNil(style)
        XCTAssertEqual(delegate.styleRequests, 1)

        interaction.isEnabled = false
        XCTAssertNil(interaction._resolvedStyle(for: region))
        XCTAssertEqual(delegate.styleRequests, 1)

        interaction.isEnabled = true
        view.removeInteraction(interaction)
        XCTAssertNil(interaction._resolvedStyle(for: region))
        XCTAssertEqual(delegate.styleRequests, 1)
    }

    func testDefaultDelegateStyleIsNil() {
        let delegate = DefaultPointerDelegate()
        let interaction = UIPointerInteraction(delegate: delegate)
        let view = UIView()
        view.addInteraction(interaction)

        XCTAssertNil(interaction._resolvedStyle(for: UIPointerRegion(rect: view.bounds)))
    }

    func testNilDelegateAndInvalidateAreInert() {
        let nilDelegateInteraction = UIPointerInteraction(delegate: nil)
        let view = UIView()
        view.addInteraction(nilDelegateInteraction)
        XCTAssertNil(nilDelegateInteraction.delegate)
        XCTAssertNil(nilDelegateInteraction._resolvedStyle(
            for: UIPointerRegion(rect: view.bounds)))

        let delegate = PointerStyleDelegate()
        let interaction = UIPointerInteraction(delegate: delegate)
        view.addInteraction(interaction)
        XCTAssertTrue(interaction.isEnabled)
        interaction.invalidate()
        XCTAssertTrue(interaction.isEnabled)
        XCTAssertEqual(delegate.styleRequests, 0)

        interaction.isEnabled = false
        interaction.invalidate()
        XCTAssertFalse(interaction.isEnabled)
        XCTAssertEqual(delegate.styleRequests, 0)
    }

    func testRegionEffectShapeAndStylePreserveInputs() {
        let rect = CGRect(x: 1, y: 2, width: 30, height: 40)
        let region = UIPointerRegion(rect: rect, identifier: "row")
        XCTAssertEqual(region.rect, rect)
        XCTAssertEqual(region.identifier, AnyHashable("row"))

        let view = UIView()
        let preview = UITargetedPreview(view: view)
        let effect = UIPointerEffect.lift(preview)
        XCTAssertTrue(effect.preview === preview)
        guard case .lift(let storedPreview) = effect else {
            return XCTFail("effect did not retain its lift case")
        }
        XCTAssertTrue(storedPreview === preview)

        let shape = UIPointerShape.roundedRect(rect, radius: 6)
        let style = UIPointerStyle(effect: effect, shape: shape)
        guard case .lift(let stylePreview) = style._effect else {
            return XCTFail("style did not retain its pointer effect")
        }
        XCTAssertTrue(stylePreview === preview)
        guard case .roundedRect(let storedRect, let radius)? = style._shape else {
            return XCTFail("style did not retain its pointer shape")
        }
        XCTAssertEqual(storedRect, rect)
        XCTAssertEqual(radius, 6)

        let hover = UIPointerEffect.hover(preview)
        guard case let .hover(hoverPreview, tint, shadow, scaled) = hover else {
            return XCTFail("effect did not retain its hover case")
        }
        XCTAssertTrue(hoverPreview === preview)
        XCTAssertEqual(tint, .overlay)
        XCTAssertFalse(shadow)
        XCTAssertTrue(scaled)
        XCTAssertEqual(UIPointerShape.defaultCornerRadius, CGFloat.leastNormalMagnitude)
    }

    func testButtonPointerToggleDefaultsOffAndRoundTrips() {
        let button = UIButton(type: .system)
        XCTAssertFalse(button.isPointerInteractionEnabled)
        button.isPointerInteractionEnabled = true
        XCTAssertTrue(button.isPointerInteractionEnabled)
        button.isPointerInteractionEnabled = false
        XCTAssertFalse(button.isPointerInteractionEnabled)
    }
}
