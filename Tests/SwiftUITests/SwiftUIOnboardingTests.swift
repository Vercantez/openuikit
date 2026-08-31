// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// API combinations are derived from Mozilla Focus's exact 21-source
// BlockzillaPackage/Sources/Onboarding target at revision
// a2832521c1daa0c23419c73705ae043ed60c9791.  No Focus source is copied here;
// scripts/prove_focus_onboarding_swiftui.sh is the byte-exact source gate.

import XCTest
import Combine
@testable import SwiftUI
import OpenUIKit

private struct InteractionFixture: View {
    let appeared: @MainActor () -> Void
    let tappedBackground: @MainActor () -> Void
    let pressedButton: @MainActor () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.01)
                .onTapGesture(perform: tappedBackground)
                .ignoresSafeArea()

            VStack {
                Text("Welcome")
                    .font(.system(size: 20).bold())
                    .multilineTextAlignment(.center)

                Button(action: pressedButton) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
        .onAppear(perform: appeared)
    }
}

private struct ScrollingFixture: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Color.red.frame(height: 45)
                Color.green.frame(height: 45)
                Color.blue.frame(height: 45)
                Color.black.frame(height: 45)
            }
        }
    }
}

private struct SpacerScrollingFixture: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Color.red.frame(height: 20)
                Spacer()
                Color.blue.frame(height: 20)
            }
        }
    }
}

private struct MultilineFixture: View {
    var body: some View {
        Text("A long onboarding sentence that must wrap onto several lines")
            .frame(width: 90)
    }
}

private struct SimultaneousButtonFixture: View {
    let primary: @MainActor () -> Void
    let simultaneous: @MainActor () -> Void

    var body: some View {
        Button(action: primary) {
            Text("Continue")
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.blue)
                .cornerRadius(8)
        }
        .frame(width: 120, height: 44)
        .simultaneousGesture(TapGesture().onEnded { _ in simultaneous() })
    }
}

private struct NavigationFixture: View {
    let done: @MainActor () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Text("Instructions")
                }
                .navigationTitle("Tutorial")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    Button("Done", action: done)
                }
            }
        }
    }
}

@MainActor
private final class RepresentedController: UIViewController {
    var loads = 0
    var updateValues: [Int] = []
    var containmentEvents: [String] = []
    var appearanceEvents: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        loads += 1
        view.backgroundColor = .green
        view.accessibilityIdentifier = "RepresentedController.view"
    }

    override func willMove(toParent parent: UIViewController?) {
        containmentEvents.append(parent == nil ? "will-remove" : "will-add")
    }

    override func didMove(toParent parent: UIViewController?) {
        containmentEvents.append(parent == nil ? "did-remove" : "did-add")
    }

    override func viewWillAppear(_ animated: Bool) {
        appearanceEvents.append("will-appear")
    }

    override func viewDidAppear(_ animated: Bool) {
        appearanceEvents.append("did-appear")
    }

    override func viewWillDisappear(_ animated: Bool) {
        appearanceEvents.append("will-disappear")
    }

    override func viewDidDisappear(_ animated: Bool) {
        appearanceEvents.append("did-disappear")
    }
}

private struct ControllerFixture: UIViewControllerRepresentable {
    let value: Int
    let make: @MainActor () -> RepresentedController

    func makeUIViewController(context: Context) -> RepresentedController {
        make()
    }

    func updateUIViewController(
        _ uiViewController: RepresentedController,
        context: Context
    ) {
        uiViewController.updateValues.append(value)
    }
}

private final class RuntimeModel: Combine.ObservableObject {
    @Combine.Published var value = 0
    @Combine.Published var showsController = true
}

private struct RepresentableLifecycleFixture: View {
    @ObservedObject var model: RuntimeModel
    let make: @MainActor () -> RepresentedController

    var body: some View {
        if model.showsController {
            ControllerFixture(value: model.value, make: make)
        } else {
            Text("removed")
        }
    }
}

@MainActor
private final class RepresentedViewCoordinator {
    let state: RepresentedViewState

    init(state: RepresentedViewState) {
        self.state = state
    }
}

@MainActor
private final class RepresentedViewState {
    var makeCoordinatorCount = 0
    var makeViewCount = 0
    var dismantleCount = 0
    weak var view: RepresentedView?
}

@MainActor
private final class RepresentedView: UIView {
    var updateValues: [Int] = []
    var windowEvents: [Bool] = []

    override func didMoveToWindow() {
        windowEvents.append(window != nil)
    }
}

private struct ViewRepresentableFixture: UIViewRepresentable {
    let value: Int
    let state: RepresentedViewState

    func makeCoordinator() -> RepresentedViewCoordinator {
        state.makeCoordinatorCount += 1
        return RepresentedViewCoordinator(state: state)
    }

    func makeUIView(context: Context) -> RepresentedView {
        precondition(context.coordinator.state === state)
        state.makeViewCount += 1
        let view = RepresentedView()
        state.view = view
        return view
    }

    func updateUIView(_ uiView: RepresentedView, context: Context) {
        precondition(context.coordinator.state === state)
        uiView.updateValues.append(value)
    }

    static func dismantleUIView(
        _ uiView: RepresentedView,
        coordinator: RepresentedViewCoordinator
    ) {
        _ = uiView
        coordinator.state.dismantleCount += 1
    }
}

private final class RepresentedViewModel: Combine.ObservableObject {
    @Combine.Published var value = 0
    @Combine.Published var isVisible = true
}

private struct ViewRepresentableLifecycleFixture: View {
    @ObservedObject var model: RepresentedViewModel
    let state: RepresentedViewState

    var body: some View {
        if model.isVisible {
            ViewRepresentableFixture(value: model.value, state: state)
                .frame(width: 90, height: 70)
        } else {
            Text("removed")
        }
    }
}

private struct StableAppearanceFixture: View {
    @ObservedObject var model: RuntimeModel
    let appeared: @MainActor () -> Void

    var body: some View {
        Text("value=\(model.value)")
            .onAppear(perform: appeared)
    }
}

private enum TestPage: Hashable {
    case first
    case second
}

private final class PageModel: Combine.ObservableObject {
    @Combine.Published var selection: TestPage = .first
}

private struct PageFixture: View {
    @ObservedObject var model: PageModel

    var body: some View {
        TabView(selection: $model.selection) {
            Text("first page").tag(TestPage.first)
            Text("second page").tag(TestPage.second)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}

private struct EffectsFixture: View {
    var body: some View {
        Color.black.opacity(0.25)
            .frame(width: 40, height: 40)
            .shadow(radius: 5)
            .colorScheme(.dark)
    }
}

@MainActor
final class SwiftUIOnboardingTests: XCTestCase {
    func testInteractionLifecycleFontInsetsAndFlexibleButtonExecute() throws {
        var appearanceCount = 0
        var backgroundTapCount = 0
        var buttonCount = 0
        let fixture = InteractionFixture(
            appeared: { appearanceCount += 1 },
            tappedBackground: { backgroundTapCount += 1 },
            pressedButton: { buttonCount += 1 }
        )
        let controller = UIHostingController(rootView: fixture)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 120))
        let host = try XCTUnwrap(controller.view)
        host.frame = window.bounds
        window.addSubview(host)
        window.layoutIfNeeded()
        host.layoutIfNeeded()

        XCTAssertEqual(appearanceCount, 0, "layout alone is not an appearance")
        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()
        XCTAssertEqual(appearanceCount, 1)
        host.setNeedsLayout()
        host.layoutIfNeeded()
        XCTAssertEqual(appearanceCount, 1, "onAppear fires once per mounted node")

        let label = try XCTUnwrap(
            descendants(host).compactMap { $0 as? UILabel }.first { $0.text == "Welcome" }
        )
        XCTAssertEqual(label.font.pointSize, 20, accuracy: 0.001)
        XCTAssertEqual(label.font.weight, .bold)
        XCTAssertEqual(label.textAlignment, .center)

        let button = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.Button") as? UIControl
        )
        XCTAssertGreaterThanOrEqual(button.frame.width, 168)
        button.sendActions(for: .touchUpInside)
        XCTAssertEqual(buttonCount, 1)

        let tap = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.TapGesture") as? UIControl
        )
        let backgroundPoint = CGPoint(x: 1, y: 1)
        XCTAssertTrue(window.hitTest(backgroundPoint, with: nil) === tap)
        window.sendTouch(.began, at: backgroundPoint, timestamp: 1)
        window.sendTouch(.ended, at: backgroundPoint, timestamp: 1.05)
        XCTAssertEqual(backgroundTapCount, 1)

        var animationResult = 0
        let returned: Int = withAnimation {
            animationResult = 7
            return 11
        }
        XCTAssertEqual(animationResult, 7)
        XCTAssertEqual(returned, 11)
    }

    func testScrollViewUsesContentGeometryAndLongBuilderOrder() throws {
        let controller = UIHostingController(rootView: ScrollingFixture())
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 120, height: 100)
        host.layoutIfNeeded()

        let scroll = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.ScrollView") as? UIScrollView
        )
        XCTAssertEqual(scroll.frame, host.bounds)
        XCTAssertEqual(scroll.contentSize, CGSize(width: 120, height: 180))

        let colors = descendants(scroll).filter {
            $0.accessibilityIdentifier == "SwiftUI.Color"
        }
        XCTAssertEqual(colors.count, 4)
        XCTAssertEqual(colors.map(\.frame.origin.y), [0, 45, 90, 135])
    }

    func testMultilineTextUsesUnlimitedWordWrappedLabelGeometry() throws {
        let controller = UIHostingController(rootView: MultilineFixture())
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 90, height: 180)
        host.layoutIfNeeded()

        let label = try XCTUnwrap(descendants(host).compactMap { $0 as? UILabel }.first)
        XCTAssertEqual(label.numberOfLines, 0)
        XCTAssertEqual(label.lineBreakMode, .byWordWrapping)
        let wrapped = label.sizeThatFits(CGSize(width: 90, height: 1_000))
        XCTAssertGreaterThan(wrapped.height, label.font.lineHeight * 2)
        XCTAssertGreaterThan(label.frame.height, label.font.lineHeight * 2)
        XCTAssertLessThanOrEqual(label.frame.width, 90)
    }

    func testScrollViewVStackSpacerUsesViewportInsteadOfArtificialTail() throws {
        let controller = UIHostingController(rootView: SpacerScrollingFixture())
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 120, height: 100)
        host.layoutIfNeeded()

        let scroll = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.ScrollView") as? UIScrollView
        )
        XCTAssertEqual(scroll.contentSize, CGSize(width: 120, height: 100))
        let colors = descendants(scroll).filter {
            $0.accessibilityIdentifier == "SwiftUI.Color"
        }
        XCTAssertEqual(colors.map(\.frame.origin.y), [0, 80])
        XCTAssertEqual(colors.map(\.frame.height), [20, 20])
    }

    func testNestedButtonDeliversPrimaryAndSimultaneousActionThroughTouchRouting() throws {
        var primaryCount = 0
        var simultaneousCount = 0
        let controller = UIHostingController(
            rootView: SimultaneousButtonFixture(
                primary: { primaryCount += 1 },
                simultaneous: { simultaneousCount += 1 }
            )
        )
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 120, height: 44))
        let host = try XCTUnwrap(controller.view)
        host.frame = window.bounds
        window.addSubview(host)
        window.layoutIfNeeded()
        host.layoutIfNeeded()

        let button = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.Button") as? UIControl
        )
        XCTAssertTrue(window.hitTest(CGPoint(x: 60, y: 22), with: nil) === button)
        window.sendTouch(.began, at: CGPoint(x: 60, y: 22), timestamp: 0)
        window.sendTouch(.ended, at: CGPoint(x: 60, y: 22), timestamp: 0.05)

        XCTAssertEqual(primaryCount, 1)
        XCTAssertEqual(simultaneousCount, 1)
    }

    func testNestedNavigationPreferencesAndToolbarActionReachHost() throws {
        var doneCount = 0
        let controller = UIHostingController(
            rootView: NavigationFixture(done: { doneCount += 1 })
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 240, height: 180)
        host.layoutIfNeeded()

        let title = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.NavigationTitle") as? UILabel
        )
        XCTAssertEqual(title.text, "Tutorial")
        XCTAssertEqual(title.frame.height, 52, accuracy: 0.001)

        let scroll = try XCTUnwrap(descendant(host, identifier: "SwiftUI.ScrollView"))
        XCTAssertEqual(scroll.frame, CGRect(x: 0, y: 52, width: 240, height: 128))

        let buttons = descendants(host).compactMap { $0 as? UIControl }.filter {
            $0.accessibilityIdentifier == "SwiftUI.Button"
        }
        XCTAssertEqual(buttons.count, 1)
        buttons[0].sendActions(for: .touchUpInside)
        XCTAssertEqual(doneCount, 1)
    }

    func testUIViewControllerRepresentableRetainsUpdatesContainsAndForwardsAppearance() async throws {
        let model = RuntimeModel()
        var makeCount = 0
        var represented: RepresentedController?
        let controller = UIHostingController(
            rootView: RepresentableLifecycleFixture(
                model: model,
                make: {
                    makeCount += 1
                    let made = RepresentedController()
                    represented = made
                    return made
                }
            )
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 90, height: 70)
        host.layoutIfNeeded()
        let first = try XCTUnwrap(represented)

        let mounted = try XCTUnwrap(
            descendant(host, identifier: "RepresentedController.view")
        )
        XCTAssertTrue(mounted === first.view)
        XCTAssertEqual(mounted.frame, host.bounds)
        XCTAssertEqual(first.loads, 1)
        XCTAssertEqual(makeCount, 1)
        XCTAssertEqual(first.updateValues, [0])
        XCTAssertTrue(first.parent === controller)
        XCTAssertEqual(first.containmentEvents, ["will-add", "did-add"])
        XCTAssertEqual(controller._openGraphRepresentedControllerCount, 1)

        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()
        XCTAssertEqual(first.appearanceEvents, ["will-appear", "did-appear"])

        model.value = 7
        await drainMainActor()
        host.layoutIfNeeded()
        XCTAssertEqual(makeCount, 1, "stable graph identity must reuse the controller")
        XCTAssertEqual(first.updateValues, [0, 7])
        XCTAssertTrue(first.parent === controller)
        XCTAssertTrue(
            descendant(host, identifier: "RepresentedController.view") === first.view
        )

        model.showsController = false
        await drainMainActor()
        host.layoutIfNeeded()
        XCTAssertNil(first.parent)
        XCTAssertNil(first.view.superview)
        XCTAssertEqual(
            first.containmentEvents,
            ["will-add", "did-add", "will-remove", "did-remove"]
        )
        XCTAssertEqual(
            first.appearanceEvents,
            ["will-appear", "did-appear", "will-disappear", "did-disappear"]
        )
        XCTAssertEqual(controller._openGraphRepresentedControllerCount, 0)
    }

    func testUIViewRepresentableRetainsViewCoordinatorAndRealWindowLifecycle() async throws {
        let model = RepresentedViewModel()
        let state = RepresentedViewState()
        let controller = UIHostingController(
            rootView: ViewRepresentableLifecycleFixture(model: model, state: state)
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 90, height: 70)
        host.layoutIfNeeded()
        let represented = try XCTUnwrap(state.view)

        XCTAssertEqual(state.makeCoordinatorCount, 1)
        XCTAssertEqual(state.makeViewCount, 1)
        XCTAssertEqual(represented.updateValues, [0])
        XCTAssertEqual(represented.windowEvents, [])
        XCTAssertEqual(controller._openGraphRepresentedViewCount, 1)
        XCTAssertTrue(
            descendant(host, identifier: "SwiftUI.UIViewRepresentable") === represented
        )

        let window = UIWindow(frame: host.bounds)
        window.rootViewController = controller
        XCTAssertTrue(represented.window === window)
        XCTAssertEqual(represented.windowEvents, [true])

        // A structural re-layout may rebuild SwiftUI wrapper views, but the
        // represented UIView stays mounted in the same UIWindow.
        host.setNeedsLayout()
        host.layoutIfNeeded()
        XCTAssertEqual(represented.windowEvents, [true])

        model.value = 7
        await drainMainActor()
        host.layoutIfNeeded()
        XCTAssertEqual(state.makeCoordinatorCount, 1)
        XCTAssertEqual(state.makeViewCount, 1)
        XCTAssertEqual(represented.updateValues, [0, 7])
        XCTAssertEqual(represented.windowEvents, [true])
        XCTAssertTrue(state.view === represented)

        model.isVisible = false
        await drainMainActor()
        host.layoutIfNeeded()
        XCTAssertEqual(state.dismantleCount, 1)
        XCTAssertNil(represented.superview)
        XCTAssertNil(represented.window)
        XCTAssertEqual(represented.windowEvents, [true, false])
        XCTAssertEqual(controller._openGraphRepresentedViewCount, 0)
    }

    func testOnAppearTracksHostAppearanceAndStableGraphIdentity() async throws {
        let model = RuntimeModel()
        var appearances = 0
        let controller = UIHostingController(
            rootView: StableAppearanceFixture(
                model: model,
                appeared: { appearances += 1 }
            )
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 120, height: 44)
        host.layoutIfNeeded()
        XCTAssertEqual(appearances, 0)

        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()
        XCTAssertEqual(appearances, 1)

        model.value = 1
        await drainMainActor()
        host.layoutIfNeeded()
        XCTAssertEqual(appearances, 1, "body rebuild must preserve onAppear identity")

        controller.beginAppearanceTransition(false, animated: false)
        controller.endAppearanceTransition()
        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()
        XCTAssertEqual(appearances, 2, "a genuine reappearance must deliver again")
    }

    func testTaggedPageSelectionAndPageControlRerenderTheVisiblePage() async throws {
        let model = PageModel()
        let controller = UIHostingController(rootView: PageFixture(model: model))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 180, height: 120))
        let host = try XCTUnwrap(controller.view)
        host.frame = window.bounds
        window.addSubview(host)
        window.layoutIfNeeded()
        host.layoutIfNeeded()

        XCTAssertEqual(texts(in: host), ["first page"])
        var pageControl = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.TabView.pageControl") as? UIPageControl
        )
        XCTAssertEqual(pageControl.numberOfPages, 2)
        XCTAssertEqual(pageControl.currentPage, 0)

        model.selection = .second
        await drainMainActor()
        host.layoutIfNeeded()
        XCTAssertEqual(texts(in: host), ["second page"])
        pageControl = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.TabView.pageControl") as? UIPageControl
        )
        XCTAssertEqual(pageControl.currentPage, 1)

        let previousPagePoint = CGPoint(
            x: pageControl.frame.minX + 1,
            y: pageControl.frame.midY
        )
        XCTAssertTrue(window.hitTest(previousPagePoint, with: nil) === pageControl)
        window.sendTouch(.began, at: previousPagePoint, timestamp: 0)
        window.sendTouch(.ended, at: previousPagePoint, timestamp: 0.05)
        XCTAssertEqual(model.selection, .first)
        await drainMainActor()
        host.layoutIfNeeded()
        XCTAssertEqual(texts(in: host), ["first page"])
    }

    func testOpacityShadowColorSchemeAndPageAppearanceAreStateful() throws {
        let controller = UIHostingController(rootView: EffectsFixture())
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        host.layoutIfNeeded()

        let traitHost = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.ColorScheme")
        )
        let shadowHost = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.Shadow")
        )
        XCTAssertEqual(traitHost.overrideUserInterfaceStyle, .dark)
        XCTAssertEqual(shadowHost.layer.shadowRadius, 5, accuracy: 0.001)
        XCTAssertEqual(shadowHost.layer.shadowOpacity, 0.33, accuracy: 0.001)

        let rendered = UIRenderer.render(host, scale: 1)
        XCTAssertEqual(alpha(rendered, x: 30, y: 30), 64)

        let proxy = UIPageControl.appearance()
        let savedCurrent = proxy.currentPageIndicatorTintColor
        let savedPage = proxy.pageIndicatorTintColor
        defer {
            proxy.currentPageIndicatorTintColor = savedCurrent
            proxy.pageIndicatorTintColor = savedPage
        }
        proxy.currentPageIndicatorTintColor = .systemBlue
        proxy.pageIndicatorTintColor = .systemGray
        let page = UIPageControl()
        XCTAssertEqual(page.currentPageIndicatorTintColor, .systemBlue)
        XCTAssertEqual(page.pageIndicatorTintColor, .systemGray)
    }

    private func descendant(_ root: UIView, identifier: String) -> UIView? {
        descendants(root).first { $0.accessibilityIdentifier == identifier }
    }

    private func descendants(_ root: UIView) -> [UIView] {
        root.subviews.flatMap { [$0] + descendants($0) }
    }

    private func alpha(_ bitmap: Bitmap, x: Int, y: Int) -> Int {
        Int(bitmap.pixels[(y * bitmap.width + x) * 4 + 3])
    }

    private func texts(in root: UIView) -> [String] {
        descendants(root).compactMap { ($0 as? UILabel)?.text }
    }

    private func drainMainActor() async {
        for _ in 0..<4 { await Task.yield() }
    }
}
