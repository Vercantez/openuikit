import XCTest
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
private final class EditMenuDelegateSpy: UIEditMenuInteractionDelegate {
    var requests: [UIEditMenuConfiguration] = []
    var suggestionCounts: [Int] = []
    var menu: UIMenu?
    var targetRequests = 0
    var presentationRequests = 0
    var dismissalRequests = 0
    func editMenuInteraction(_ interaction: UIEditMenuInteraction,
                             menuFor configuration: UIEditMenuConfiguration,
                             suggestedActions: [UIMenuElement]) -> UIMenu? {
        requests.append(configuration)
        suggestionCounts.append(suggestedActions.count)
        return menu
    }
    func editMenuInteraction(_ interaction: UIEditMenuInteraction,
                             targetRectFor configuration: UIEditMenuConfiguration) -> CGRect {
        targetRequests += 1
        return CGRect(origin: configuration.sourcePoint, size: .zero)
    }
    func editMenuInteraction(_ interaction: UIEditMenuInteraction,
                             willPresentMenuFor configuration: UIEditMenuConfiguration,
                             animator: UIEditMenuInteractionAnimating) { presentationRequests += 1 }
    func editMenuInteraction(_ interaction: UIEditMenuInteraction,
                             willDismissMenuFor configuration: UIEditMenuConfiguration,
                             animator: UIEditMenuInteractionAnimating) { dismissalRequests += 1 }
}

#if !os(Linux)
@MainActor
#endif
private final class DefaultEditMenuDelegate: UIEditMenuInteractionDelegate {}

#if !os(Linux)
@MainActor
#endif
private final class EditMenuAnimatorWitness: UIEditMenuInteractionAnimating {
    var animationCount = 0
    var completionCount = 0
    func addAnimations(_ animations: @escaping () -> Void) { animationCount += 1 }
    func addCompletion(_ completion: @escaping () -> Void) { completionCount += 1 }
}

#if !os(Linux)
@MainActor
#endif
final class UIEditMenuInteractionTests: XCTestCase {
    func testConfigurationPreservesIdentifierAndFractionalPoint() {
        let point = CGPoint(x: -2.25, y: 3.5)
        let configuration = UIEditMenuConfiguration(identifier: "sample", sourcePoint: point)
        XCTAssertEqual(configuration.identifier, AnyHashable("sample"))
        XCTAssertEqual(configuration.sourcePoint, point)
        XCTAssertEqual(configuration.preferredArrowDirection, .automatic)
        let directions: [UIEditMenuArrowDirection] = [.automatic, .up, .down, .left, .right]
        XCTAssertEqual(directions.map(\.rawValue), [0, 1, 2, 3, 4])
        for direction in directions {
            configuration.preferredArrowDirection = direction
            XCTAssertEqual(configuration.preferredArrowDirection, direction)
        }
    }

    func testNilIdentifierIsUniqueOpaqueUUIDDescription() {
        let first = UIEditMenuConfiguration(identifier: nil, sourcePoint: .zero)
        let second = UIEditMenuConfiguration(identifier: nil, sourcePoint: .zero)
        XCTAssertNotEqual(first.identifier, second.identifier)
        let description = String(describing: first.identifier)
        XCTAssertNotNil(UUID(uuidString: description))
        XCTAssertFalse(first.identifier.base is UUID)
        XCTAssertNotEqual(first.identifier, AnyHashable(description))
    }

    func testConfigurationCopiesMutableIdentifier() {
        let mutable = NSMutableString(string: "before")
        let configuration = UIEditMenuConfiguration(identifier: AnyHashable(mutable), sourcePoint: .zero)
        mutable.append("-after")
        XCTAssertEqual(String(describing: configuration.identifier), "before")
    }

    func testDelegateAndViewAreWeakAndAttachmentMovesBetweenViews() {
        var delegate: EditMenuDelegateSpy? = EditMenuDelegateSpy()
        let interaction = UIEditMenuInteraction(delegate: delegate)
        XCTAssertTrue(interaction.delegate === delegate)
        delegate = nil
        XCTAssertNil(interaction.delegate)
        XCTAssertNil(interaction.view)
        let first = UIView()
        let second = UIView()
        first.addInteraction(interaction)
        XCTAssertTrue(interaction.view === first)
        second.addInteraction(interaction)
        XCTAssertTrue(first.interactions.isEmpty)
        XCTAssertTrue(interaction.view === second)
        second.removeInteraction(interaction)
        XCTAssertNil(interaction.view)
        var temporary: UIView? = UIView()
        interaction.didMove(to: temporary)
        temporary = nil
        XCTAssertNil(interaction.view)
    }

    func testInitialLocationSentinelDependsOnAttachmentAndDestination() {
        let interaction = UIEditMenuInteraction(delegate: nil)
        let source = UIView(frame: CGRect(x: 40, y: 120, width: 260, height: 240))
        let sentinel = CGPoint(x: CGFloat.greatestFiniteMagnitude,
                               y: CGFloat.greatestFiniteMagnitude)
        XCTAssertEqual(interaction.location(in: nil), sentinel)
        XCTAssertEqual(interaction.location(in: source), .zero)
        source.addInteraction(interaction)
        XCTAssertEqual(interaction.location(in: source), sentinel)
        XCTAssertEqual(interaction.location(in: nil), sentinel)
    }

    func testDetachedRequestAndIdleMethodsDoNotQueryDelegate() {
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = saved }
        let spy = EditMenuDelegateSpy()
        let interaction = UIEditMenuInteraction(delegate: spy)
        interaction.reloadVisibleMenu()
        interaction.dismissMenu()
        interaction.updateVisibleMenuPosition(animated: false)
        interaction.presentEditMenu(with: UIEditMenuConfiguration(identifier: "sample", sourcePoint: CGPoint(x: 70, y: 90)))
        XCTAssertTrue(spy.requests.isEmpty)
        XCTAssertEqual(spy.targetRequests, 0)
        XCTAssertEqual(spy.presentationRequests, 0)
        XCTAssertEqual(spy.dismissalRequests, 0)
    }

    func testUnwindowedRequestRetainsPointAndCanReloadAfterRemoval() {
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = saved }
        let spy = EditMenuDelegateSpy()
        let interaction = UIEditMenuInteraction(delegate: spy)
        let source = UIView(frame: CGRect(x: 40, y: 120, width: 260, height: 240))
        let destination = UIView()
        let configuration = UIEditMenuConfiguration(identifier: "sample", sourcePoint: CGPoint(x: 70, y: 90))
        source.addInteraction(interaction)
        interaction.presentEditMenu(with: configuration)
        XCTAssertEqual(spy.requests.count, 1)
        XCTAssertTrue(spy.requests.first === configuration)
        for view: UIView? in [source, destination, nil] {
            XCTAssertEqual(interaction.location(in: view), configuration.sourcePoint)
        }
        source.removeInteraction(interaction)
        interaction.reloadVisibleMenu()
        interaction.updateVisibleMenuPosition(animated: true)
        interaction.dismissMenu()
        XCTAssertEqual(spy.requests.count, 2)
        XCTAssertEqual(spy.targetRequests, 0)
        XCTAssertEqual(spy.presentationRequests, 0)
        XCTAssertEqual(spy.dismissalRequests, 0)
        XCTAssertEqual(interaction.location(in: nil), configuration.sourcePoint)
    }

    func testUnsupportedNonemptyMenuDoesNotClaimPresentationOrInvokeAction() {
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = saved }
        let spy = EditMenuDelegateSpy()
        var actionCalls = 0
        spy.menu = UIMenu(children: [UIAction(title: "Probe action") { _ in actionCalls += 1 }])
        let interaction = UIEditMenuInteraction(delegate: spy)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let source = UIView()
        window.addSubview(source)
        source.addInteraction(interaction)
        interaction.presentEditMenu(with: UIEditMenuConfiguration(identifier: "sample", sourcePoint: CGPoint(x: 70, y: 90)))
        interaction.updateVisibleMenuPosition(animated: true)
        interaction.dismissMenu()
        XCTAssertEqual(spy.requests.count, 1)
        XCTAssertEqual(spy.suggestionCounts, [0])
        XCTAssertEqual(spy.targetRequests, 0)
        XCTAssertEqual(spy.presentationRequests, 0)
        XCTAssertEqual(spy.dismissalRequests, 0)
        XCTAssertEqual(actionCalls, 0)
        XCTAssertEqual(window.subviews.count, 1)
    }

    func testOptionalDelegateDefaultsRequireNoImplementationOrAnimations() {
        let delegate = DefaultEditMenuDelegate()
        let interaction = UIEditMenuInteraction(delegate: delegate)
        let configuration = UIEditMenuConfiguration(identifier: "sample", sourcePoint: CGPoint(x: 70, y: 90))
        let animator: UIEditMenuInteractionAnimating = EditMenuAnimatorWitness()
        XCTAssertNil(delegate.editMenuInteraction(interaction, menuFor: configuration, suggestedActions: []))
        XCTAssertEqual(delegate.editMenuInteraction(interaction, targetRectFor: configuration),
                       CGRect(x: 70, y: 90, width: 0, height: 0))
        delegate.editMenuInteraction(interaction, willPresentMenuFor: configuration, animator: animator)
        delegate.editMenuInteraction(interaction, willDismissMenuFor: configuration, animator: animator)
        XCTAssertEqual((animator as? EditMenuAnimatorWitness)?.animationCount, 0)
        XCTAssertEqual((animator as? EditMenuAnimatorWitness)?.completionCount, 0)
    }

    func testCatalystCutDoesNotResolvePresentationRequests() {
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .macOS
        defer { OpenUIKitRuntime.systemFontCut = saved }
        let spy = EditMenuDelegateSpy()
        let interaction = UIEditMenuInteraction(delegate: spy)
        let source = UIView()
        source.addInteraction(interaction)
        interaction.presentEditMenu(with: UIEditMenuConfiguration(identifier: "sample", sourcePoint: .zero))
        interaction.reloadVisibleMenu()
        XCTAssertTrue(spy.requests.isEmpty)
    }
}
