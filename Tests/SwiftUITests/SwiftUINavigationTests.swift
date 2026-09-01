import XCTest
@testable import OpenUIKit
@testable import SwiftUI

private struct NavigationPathFixture: View {
    let path: Binding<NavigationPath>

    var body: some View {
        NavigationStack(path: path) {
            VStack {
                Text("Root")
                    .accessibilityIdentifier("navigation-root")
            }
            .navigationTitle("Root")
            .navigationDestination(for: Int.self) { value in
                NavigationDismissDestination(value: value)
                    .navigationTitle("Number \(value)")
            }
        }
    }
}

private struct NavigationDismissDestination: View {
    let value: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Text("Value \(value)")
                .accessibilityIdentifier("navigation-value")
            Button("Dismiss Value") { dismiss() }
        }
    }
}

private struct SplitFixture: View {
    let visibility: Binding<NavigationSplitViewVisibility>

    var body: some View {
        NavigationSplitView(columnVisibility: visibility) {
            Text("Sidebar")
                .accessibilityIdentifier("split-sidebar")
                .navigationSplitViewColumnWidth(min: 280, ideal: 340, max: 380)
        } detail: {
            Text("Detail")
                .accessibilityIdentifier("split-detail")
        }
    }
}

@MainActor
private final class ApplicationShellRecorder {
    var dismissals = 0
    var phases: [(ScrollPhase, ScrollPhase, CGPoint)] = []
}

private struct SheetCallbackContent: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button("Close Callback Sheet") { dismiss() }
    }
}

private struct SheetCallbackFixture: View {
    let recorder: ApplicationShellRecorder
    @State private var isPresented = false

    var body: some View {
        Button("Show Callback Sheet") { isPresented = true }
            .sheet(isPresented: $isPresented, onDismiss: {
                recorder.dismissals += 1
            }) {
                SheetCallbackContent()
            }
    }
}

private struct ScrollPhaseFixture: View {
    let recorder: ApplicationShellRecorder

    var body: some View {
        ScrollView {
            Color.red.frame(width: 80, height: 1_000)
        }
        .scrollDisabled(false)
        .scrollDisabled(true)
        .onScrollPhaseChange { old, new, context in
            recorder.phases.append((old, new, context.geometry.contentOffset))
        }
    }
}

private struct NavigationDisappearFixture: View {
    let showsTrackedContent: Bool
    let disappeared: @MainActor () -> Void

    var body: some View {
        NavigationStack {
            if showsTrackedContent {
                Text("Tracked")
                    .onDisappear(perform: disappeared)
            } else {
                Text("Replacement")
            }
        }
    }
}

@MainActor
final class SwiftUINavigationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(true)
        OpenUIKitRuntime.animationTime = 0
    }

    override func tearDown() {
        UIView.setAnimationsEnabled(true)
        OpenUIKitRuntime.animationTime = 0
        super.tearDown()
    }

    func testNavigationPathPushRetainsPrefixFailsClosedAndPopsBackIntoBinding() throws {
        var path = NavigationPath()
        let binding = Binding(
            get: { path },
            set: { path = $0 }
        )
        let controller = UIHostingController(
            rootView: NavigationPathFixture(path: binding)
        )
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 360, height: 640))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.layoutIfNeeded()

        let navigation = try XCTUnwrap(
            controller.children.compactMap { $0 as? UINavigationController }.first
        )
        XCTAssertEqual(navigation.viewControllers.count, 1)
        XCTAssertEqual(navigation.topViewController?.title, "Root")

        path.append(7)
        controller.rootView = NavigationPathFixture(path: binding)
        controller.view.layoutIfNeeded()
        XCTAssertEqual(navigation.viewControllers.count, 2)
        XCTAssertEqual(navigation.topViewController?.title, "Number 7")
        let retained = try XCTUnwrap(navigation.topViewController)

        // Unknown types do not manufacture a blank controller and do not
        // disturb the longest resolvable prefix.
        path.append("unsupported")
        controller.rootView = NavigationPathFixture(path: binding)
        controller.view.layoutIfNeeded()
        XCTAssertEqual(navigation.viewControllers.count, 2)
        XCTAssertTrue(navigation.topViewController === retained)
        XCTAssertEqual(path.count, 2)

        path.removeLast()
        controller.rootView = NavigationPathFixture(path: binding)
        window.tick(timestamp: 1)
        _ = navigation.popViewController(animated: true)
        window.tick(timestamp: 2)
        XCTAssertTrue(path.isEmpty)
        XCTAssertEqual(navigation.viewControllers.count, 1)

        path.append(9)
        controller.rootView = NavigationPathFixture(path: binding)
        window.tick(timestamp: 3)
        let destination = try XCTUnwrap(navigation.topViewController)
        destination.view.layoutIfNeeded()
        let dismiss = try XCTUnwrap(
            descendants(destination.view).compactMap { $0 as? UIControl }.first {
                descendants($0).compactMap { ($0 as? UILabel)?.text }
                    .contains("Dismiss Value")
            }
        )
        dismiss.sendActions(for: .touchUpInside)
        XCTAssertTrue(path.isEmpty)
        controller.rootView = NavigationPathFixture(path: binding)
        controller.view.layoutIfNeeded()
        XCTAssertEqual(navigation.viewControllers.count, 1)
    }

    func testNavigationSplitVisibilityRetainsBothColumnsOrDetailOnly() throws {
        var visibility = NavigationSplitViewVisibility.all
        let binding = Binding(
            get: { visibility },
            set: { visibility = $0 }
        )
        let controller = UIHostingController(rootView: SplitFixture(visibility: binding))
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 1_000, height: 600)
        host.layoutIfNeeded()

        XCTAssertNotNil(descendant(host, identifier: "SwiftUI.NavigationSplitView"))
        XCTAssertNotNil(descendant(host, identifier: "split-sidebar"))
        XCTAssertNotNil(descendant(host, identifier: "split-detail"))

        visibility = .detailOnly
        controller.rootView = SplitFixture(visibility: binding)
        host.layoutIfNeeded()
        XCTAssertNil(descendant(host, identifier: "split-sidebar"))
        XCTAssertNotNil(descendant(host, identifier: "split-detail"))
    }

    func testNavigationNodePairsDisappearWhenVisibleContentLeavesItsGraph() throws {
        var disappearances = 0
        let action: @MainActor () -> Void = { disappearances += 1 }
        let controller = UIHostingController(
            rootView: NavigationDisappearFixture(
                showsTrackedContent: true,
                disappeared: action
            )
        )
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.layoutIfNeeded()
        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()

        controller.rootView = NavigationDisappearFixture(
            showsTrackedContent: false,
            disappeared: action
        )
        controller.view.layoutIfNeeded()
        XCTAssertEqual(disappearances, 1)

        // Rebuilding an already-absent branch does not double-deliver.
        controller.rootView = NavigationDisappearFixture(
            showsTrackedContent: false,
            disappeared: action
        )
        controller.view.layoutIfNeeded()
        XCTAssertEqual(disappearances, 1)
    }

    func testGlobalAnimationGateCommitsModelsAndRestoresNestedState() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        var completed: Bool?
        UIView.setAnimationsEnabled(false)
        UIView.animate(withDuration: 4, animations: {
            view.alpha = 0.25
        }, completion: { completed = $0 })

        XCTAssertEqual(view.alpha, 0.25)
        XCTAssertTrue(view.animations.isEmpty)
        XCTAssertEqual(completed, true)
        XCTAssertFalse(UIView.areAnimationsEnabled)

        UIView.setAnimationsEnabled(true)
        UIView.performWithoutAnimation {
            XCTAssertFalse(UIView.areAnimationsEnabled)
            UIView.performWithoutAnimation {
                XCTAssertFalse(UIView.areAnimationsEnabled)
                view.center = CGPoint(x: 30, y: 30)
            }
        }
        XCTAssertTrue(UIView.areAnimationsEnabled)
        XCTAssertEqual(view.center, CGPoint(x: 30, y: 30))
        XCTAssertTrue(view.animations.isEmpty)
    }

    func testSheetOnDismissRunsAfterConcreteDismissalExactlyOnce() throws {
        OpenUIKit.Timer._reset()
        _OpenInvalidationScheduler.forceHostClockForTesting = true
        defer {
            _OpenInvalidationScheduler.forceHostClockForTesting = false
            OpenUIKit.Timer._reset()
        }

        let recorder = ApplicationShellRecorder()
        let controller = UIHostingController(
            rootView: SheetCallbackFixture(recorder: recorder)
        )
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.layoutIfNeeded()

        try XCTUnwrap(control(named: "Show Callback Sheet", in: controller.view))
            .sendActions(for: .touchUpInside)
        flush(controller.view)
        let presented = try XCTUnwrap(controller.presentedViewController)
        presented.view.layoutIfNeeded()
        XCTAssertEqual(recorder.dismissals, 0)

        try XCTUnwrap(control(named: "Close Callback Sheet", in: presented.view))
            .sendActions(for: .touchUpInside)
        flush(controller.view)
        XCTAssertEqual(recorder.dismissals, 0, "callback waits for UIKit teardown")
        window.tick(timestamp: 10)
        XCTAssertNil(controller.presentedViewController)
        XCTAssertEqual(recorder.dismissals, 1)
    }

    func testContentUnavailableAndScrollPhaseUseRetainedRuntimeSurfaces() throws {
        let unavailable = UIHostingController(
            rootView: ContentUnavailableView(
                "Nothing Here",
                systemImage: "tray",
                description: Text("Try again later")
            )
        )
        unavailable.view.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
        unavailable.view.layoutIfNeeded()
        let labels = descendants(unavailable.view).compactMap { $0 as? UILabel }
        XCTAssertTrue(labels.contains { $0.text == "Nothing Here" })
        XCTAssertTrue(labels.contains { $0.text == "Try again later" })
        XCTAssertNotNil(descendant(
            unavailable.view,
            identifier: "SwiftUI.Image.systemName.tray"
        ))

        let recorder = ApplicationShellRecorder()
        let scrollHost = UIHostingController(rootView: ScrollPhaseFixture(recorder: recorder))
        scrollHost.view.frame = CGRect(x: 0, y: 0, width: 200, height: 240)
        scrollHost.view.layoutIfNeeded()
        let scroll = try XCTUnwrap(
            descendants(scrollHost.view).compactMap { $0 as? UIScrollView }.first
        )
        XCTAssertFalse(scroll.isScrollEnabled)
        scroll.contentOffset = CGPoint(x: 0, y: 42)
        scroll.delegate?.scrollViewWillBeginDragging(scroll)
        scroll.delegate?.scrollViewWillBeginDecelerating(scroll)
        scroll.delegate?.scrollViewDidEndDecelerating(scroll)
        XCTAssertEqual(recorder.phases.map { $0.0 }, [.idle, .interacting, .decelerating])
        XCTAssertEqual(recorder.phases.map { $0.1 }, [.interacting, .decelerating, .idle])
        XCTAssertEqual(recorder.phases.map { $0.2.y }, [42, 42, 42])
    }

    private func flush(_ host: UIView) {
        XCTAssertTrue(OpenUIKit.Timer._hasScheduledTimers)
        OpenUIKit.Timer._step(to: OpenUIKit.Timer.currentTime)
        host.layoutIfNeeded()
    }

    private func control(named title: String, in root: UIView) -> UIControl? {
        descendants(root).compactMap { $0 as? UIControl }.first { control in
            descendants(control).compactMap { ($0 as? UILabel)?.text }.contains(title)
        }
    }

    private func descendant(_ root: UIView, identifier: String) -> UIView? {
        descendants(root).first { $0.accessibilityIdentifier == identifier }
    }

    private func descendants(_ root: UIView) -> [UIView] {
        root.subviews.flatMap { [$0] + descendants($0) }
    }
}
