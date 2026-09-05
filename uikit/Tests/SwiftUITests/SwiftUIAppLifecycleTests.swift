import XCTest
#if os(Linux)
@preconcurrency import OpenUIKit
#else
import OpenUIKit
#endif
#if os(Linux)
@preconcurrency @testable import SwiftUI
#else
@testable import SwiftUI
#endif

#if !os(Linux)
@MainActor
#endif
private final class LifecycleApplicationDelegate: NSObject, UIApplicationDelegate {
    static weak var latest: LifecycleApplicationDelegate?
    static var callbacks: [String] = []

    override init() {
        super.init()
        Self.latest = self
        Self.callbacks.append("init")
    }

    func application(
        _ application: UIApplication,
        willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Self.callbacks.append("willFinishLaunching")
        return true
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Self.callbacks.append("didFinishLaunching")
        return true
    }
}

#if !os(Linux)
@MainActor
#endif
private struct LifecycleRoot: View {
    let title: String

    var body: some View {
        Text(verbatim: title)
    }
}

#if !os(Linux)
@MainActor
#endif
private struct LifecycleApplication: App {
#if !os(Linux)
    @UIApplicationDelegateAdaptor(LifecycleApplicationDelegate.self)
    private var delegate
#endif

    var body: some Scene {
        WindowGroup("Primary") {
            LifecycleRoot(title: "Primary lifecycle root")
        }
        WindowGroup("Secondary") {
            LifecycleRoot(title: "Secondary lifecycle root")
        }
    }
}

#if !os(Linux)
@MainActor
#endif
private struct ConditionalSceneFixture: Scene {
    let primary: Bool

    @SceneBuilder var body: some Scene {
        if primary {
            WindowGroup("Conditional primary") { Text(verbatim: "primary") }
        } else {
            WindowGroup("Conditional fallback") { Text(verbatim: "fallback") }
        }
        for index in 0..<2 {
            WindowGroup("Array \(index)") { Text(verbatim: "array \(index)") }
        }
    }
}

#if !os(Linux)
@MainActor
#endif
private enum IncomingURLRecorder {
    static var values: [URL] = []
}

#if !os(Linux)
@MainActor
#endif
private struct IncomingURLApplication: App {
    var body: some Scene {
        WindowGroup("URL Handler") {
            Text("URL root")
                .onOpenURL { IncomingURLRecorder.values.append($0) }
        }
    }
}

#if !os(Linux)
@MainActor
#endif
final class SwiftUIAppLifecycleTests: XCTestCase {
    func testDefaultAppMainWitnessExistsWithoutGeneratedEntryPoint() {
        // Referencing (rather than invoking) the inherited witness proves an
        // untouched `@main struct ...: App` has a compiler-visible main.
        let defaultMain: @MainActor () -> Void = LifecycleApplication.main
        _ = defaultMain
    }

    func testBoundedApplicationHostTicksEveryWindowOnAPacedClockAndTerminates() {
        let session = _OpenSwiftUIApplicationLifecycle.launch(
            LifecycleApplication.self,
            preparePackagedResources: false
        )
        var clock = 10.0
        var deadlines: [Double] = []

        let result = _OpenSwiftUIApplicationLifecycle._runApplicationHost(
            application: session.application,
            windows: session.windows,
            boundedTurnCount: 3,
            now: { clock },
            waitUntil: { deadline in
                deadlines.append(deadline)
                clock = deadline
            }
        )

        XCTAssertEqual(result.turns, 3)
        XCTAssertEqual(result.windowTicks, 6)
        XCTAssertEqual(result.elapsed, 2.0 / 60.0, accuracy: 1e-9)
        XCTAssertEqual(deadlines.count, 2)
        XCTAssertEqual(deadlines[0], 10.0 + 1.0 / 60.0, accuracy: 1e-9)
        XCTAssertEqual(deadlines[1], 10.0 + 2.0 / 60.0, accuracy: 1e-9)
        XCTAssertEqual(OpenUIKitRuntime.animationTime, 2.0 / 60.0, accuracy: 1e-9)
        XCTAssertTrue(session.application.isTerminating)
    }

    func testApplicationHostTurnLimitUsesOnlyPositiveDecimalIntegers() {
        XCTAssertNil(_OpenSwiftUIApplicationLifecycle._applicationHostTurnLimit(nil))
        XCTAssertEqual(_OpenSwiftUIApplicationLifecycle._applicationHostTurnLimit("1"), 1)
        XCTAssertEqual(_OpenSwiftUIApplicationLifecycle._applicationHostTurnLimit("257"), 257)
    }

    func testSceneBuilderPreservesConditionalAndArrayWindowGroups() {
        let node = ConditionalSceneFixture(primary: false)
            ._makeOpenUIKitSceneNode()
        XCTAssertEqual(
            node.windows.map(\.title),
            ["Conditional fallback", "Array 0", "Array 1"]
        )
    }

#if !os(Linux)
    func testLaunchInstallsDelegateAndHostsEveryWindowGroupInOpenUIKit() throws {
        LifecycleApplicationDelegate.latest = nil
        LifecycleApplicationDelegate.callbacks = []

        let session = _OpenSwiftUIApplicationLifecycle.launch(
            LifecycleApplication.self,
            preparePackagedResources: false
        )

        let delegate = try XCTUnwrap(LifecycleApplicationDelegate.latest)
        XCTAssertTrue(session.applicationDelegate === delegate)
        XCTAssertTrue(session.application.delegate === delegate)
        XCTAssertEqual(
            LifecycleApplicationDelegate.callbacks,
            ["init", "willFinishLaunching", "didFinishLaunching"]
        )
        XCTAssertEqual(session.application.applicationState, .active)

        XCTAssertEqual(session.scenes.count, 2)
        XCTAssertEqual(session.windows.count, 2)
        XCTAssertEqual(session.rootViewControllers.count, 2)
        XCTAssertEqual(session.scenes.map(\.activationState), [.foregroundActive, .foregroundActive])
        XCTAssertEqual(session.scenes.map(\.title), ["Primary", "Secondary"])
        XCTAssertEqual(
            session.scenes.map { $0.session.persistentIdentifier },
            ["SwiftUI.WindowGroup.0", "SwiftUI.WindowGroup.1"]
        )

        for index in session.windows.indices {
            let window = session.windows[index]
            XCTAssertTrue(window.windowScene === session.scenes[index])
            XCTAssertTrue(window.rootViewController === session.rootViewControllers[index])
            XCTAssertFalse(window.isHidden)
            XCTAssertNotNil(session.scenes[index].keyWindow)
            XCTAssertGreaterThan(window.bounds.width, 0)
            XCTAssertGreaterThan(window.bounds.height, 0)
        }
        XCTAssertTrue(session.windows.last?.isKeyWindow == true)

        let primaryController = try XCTUnwrap(
            session.rootViewControllers[0] as? UIHostingController<LifecycleRoot>
        )
        let secondaryController = try XCTUnwrap(
            session.rootViewControllers[1] as? UIHostingController<LifecycleRoot>
        )
        XCTAssertEqual(
            labels(in: try XCTUnwrap(primaryController.view)).map(\.text),
            ["Primary lifecycle root"]
        )
        XCTAssertEqual(
            labels(in: try XCTUnwrap(secondaryController.view)).map(\.text),
            ["Secondary lifecycle root"]
        )
    }
#endif

    func testSessionDeliversIncomingURLsToRetainedViewHandlers() throws {
        IncomingURLRecorder.values = []
        let session = _OpenSwiftUIApplicationLifecycle.launch(
            IncomingURLApplication.self,
            preparePackagedResources: false
        )
        let url = try XCTUnwrap(URL(string: "icecubesapp://status/42"))

        XCTAssertTrue(session.openURL(url))
        XCTAssertEqual(IncomingURLRecorder.values, [url])

        // A session without an installed handler fails closed rather than
        // reporting a URL as consumed merely because it has a window.
        let unhandled = _OpenSwiftUIApplicationLifecycle.launch(
            LifecycleApplication.self,
            preparePackagedResources: false
        )
        XCTAssertFalse(unhandled.openURL(url))
    }

    func testPackagedResourceConfigurationIsRelocatableAndExact() throws {
        let fileManager = FileManager.default
        let work = fileManager.temporaryDirectory
            .appendingPathComponent("OpenUIKitAppLifecycle-\(UUID().uuidString)")
        let openUIKit = work.appendingPathComponent("OpenUIKit")
        let fonts = openUIKit.appendingPathComponent("fonts")
        try fileManager.createDirectory(at: fonts, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: work) }

        let repository = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        for name in ["system_colors.json", "font_metrics.json"] {
            try fileManager.copyItem(
                at: repository
                    .appendingPathComponent("Sources/OpenUIKit/Resources")
                    .appendingPathComponent(name),
                to: openUIKit.appendingPathComponent(name)
            )
        }
        try Data([0x4F, 0x70, 0x65, 0x6E]).write(
            to: fonts.appendingPathComponent("DejaVuSans.ttf")
        )
        try Data([0x42, 0x6F, 0x6C, 0x64]).write(
            to: fonts.appendingPathComponent("DejaVuSans-Bold.ttf")
        )

        let savedRoot = OpenUIKitRuntime.resourceRoot
        let savedSearchPaths = OpenUIKitRuntime.imageSearchPaths
        let savedScale = OpenUIKitRuntime.imageScreenScale
        let savedFontPaths = OpenUIKitRuntime.fontPaths
        defer {
            OpenUIKitRuntime.resourceRoot = savedRoot
            OpenUIKitRuntime.imageSearchPaths = savedSearchPaths
            OpenUIKitRuntime.imageScreenScale = savedScale
            OpenUIKitRuntime.fontPaths = savedFontPaths
            UIImage.clearNamedCache()
        }

        OpenUIKitRuntime.configureApplicationBundleResources(at: work.path)

        XCTAssertEqual(OpenUIKitRuntime.resourceRoot, openUIKit.path)
        XCTAssertEqual(OpenUIKitRuntime.imageSearchPaths, [work.path])
        XCTAssertEqual(OpenUIKitRuntime.imageScreenScale, 2)
        XCTAssertEqual(
            OpenUIKitRuntime.fontPaths,
            [
                "system": fonts.appendingPathComponent("DejaVuSans.ttf").path,
                "medium": fonts.appendingPathComponent("DejaVuSans-Bold.ttf").path,
                "semibold": fonts.appendingPathComponent("DejaVuSans-Bold.ttf").path,
                "bold": fonts.appendingPathComponent("DejaVuSans-Bold.ttf").path,
                "heavy": fonts.appendingPathComponent("DejaVuSans-Bold.ttf").path,
                "black": fonts.appendingPathComponent("DejaVuSans-Bold.ttf").path,
            ]
        )
    }

    private func labels(in root: UIView) -> [UILabel] {
        var result: [UILabel] = []
        func visit(_ view: UIView) {
            if let label = view as? UILabel { result.append(label) }
            view.subviews.forEach(visit)
        }
        visit(root)
        return result
    }
}
