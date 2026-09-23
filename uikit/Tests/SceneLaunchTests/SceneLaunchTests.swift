import XCTest
@testable import OpenUIKit

// The scene-manifest launch of Tools/oracle2/scenelaunchprobe, run on the port:
// the same classes (RootViewController / SceneDelegate / AppDelegate), the
// same compiled storyboard (fixtures/scenelaunch/Main.storyboardc = ibtool of
// the probe's Main.storyboard; its archived class is
// `_TtC11LaunchProbe18RootViewController`, aliased to this module), the same
// event strings. Expected lines are the transcript's EV lines
// (transcript-ios26.1.txt); the one intentional difference is recorded below.

nonisolated(unsafe) var launchEvents: [String] = []
func launchLog(_ s: String) { launchEvents.append(s) }

@MainActor func windowFacts(_ w: UIWindow?) -> String {
    guard let w else { return "window=nil" }
    return "window=\(type(of: w)) key=\(w.isKeyWindow) hidden=\(w.isHidden) scene=\(w.windowScene != nil) frame=\(w.frame) root=\(w.rootViewController.map { "\(type(of: $0))" } ?? "nil")"
}

final class RootViewController: UIViewController {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        launchLog("Root.init(coder:)")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        launchLog("Root.viewDidLoad \(windowFacts(view.window)) superview=\(view.superview != nil)")
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        launchLog("Root.viewWillAppear animated=\(animated) \(windowFacts(view.window))")
    }
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        launchLog("Root.viewSafeAreaInsetsDidChange \(view.safeAreaInsets)")
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        launchLog("Root.viewDidAppear animated=\(animated) \(windowFacts(view.window))")
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    override init() {
        super.init()
        launchLog("SceneDelegate.init")
    }
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        launchLog("scene(willConnectTo:) state=\(scene.activationState.rawValue) \(windowFacts(window)) config=\(session.configuration.name ?? "nil") storyboard=\(session.configuration.storyboard != nil) delegateClass=\(session.configuration.delegateClass.map { NSStringFromClass($0) } ?? "nil") urlContexts=\(connectionOptions.urlContexts.count) notificationResponse=\(connectionOptions.notificationResponse == nil ? "nil" : "set") shortcut=\(connectionOptions.shortcutItem == nil ? "nil" : "set") userActivities=\(connectionOptions.userActivities.count) restoration=\(session.stateRestorationActivity == nil ? "nil" : "set")")
    }
    func sceneWillEnterForeground(_ scene: UIScene) { launchLog("sceneWillEnterForeground state=\(scene.activationState.rawValue) \(windowFacts(window))") }
    func sceneDidBecomeActive(_ scene: UIScene) { launchLog("sceneDidBecomeActive state=\(scene.activationState.rawValue)") }
}

final class AppDelegate: UIResponder, UIApplicationDelegate {
    override init() {
        super.init()
        launchLog("AppDelegate.init state=\(UIApplication.shared.applicationState.rawValue)")
    }
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        launchLog("willFinishLaunching state=\(application.applicationState.rawValue) options=\(launchOptions == nil ? "nil" : "\(launchOptions!.count)")")
        return true
    }
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        launchLog("didFinishLaunching state=\(application.applicationState.rawValue) scenes=\(application.connectedScenes.count)")
        return true
    }
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let c = connectingSceneSession.configuration
        launchLog("configurationForConnecting name=\(c.name ?? "nil") delegateClass=\(c.delegateClass.map { NSStringFromClass($0) } ?? "nil") storyboard=\(c.storyboard != nil) role=\(connectingSceneSession.role.rawValue)")
        return c
    }
    func applicationDidBecomeActive(_ application: UIApplication) { launchLog("applicationDidBecomeActive (app delegate)") }
}

@MainActor
final class SceneLaunchTests: XCTestCase {
    static let fixtures = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("fixtures/scenelaunch").path

    func testManifestLaunchMatchesTheIOS261Transcript() {
        launchEvents = []
        let savedPaths = OpenUIKitRuntime.nibSearchPaths
        let savedAliases = UINibClassRegistry.moduleAliases
        OpenUIKitRuntime.nibSearchPaths = [Self.fixtures]
        UINibClassRegistry.moduleAliases["LaunchProbe"] = "SceneLaunchTests"
        UIScreen.main._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 393, height: 852), scale: 3)
        UIApplication._headlessSafeArea = UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
        defer {
            OpenUIKitRuntime.nibSearchPaths = savedPaths
            UINibClassRegistry.moduleAliases = savedAliases
            UIApplication._headlessSafeArea = nil
        }
        let info: [String: Any] = [
            "UIApplicationSceneManifest": [
                "UIApplicationSupportsMultipleScenes": false,
                "UISceneConfigurations": [
                    "UIWindowSceneSessionRoleApplication": [[
                        "UISceneConfigurationName": "Default Configuration",
                        "UISceneDelegateClassName": "SceneLaunchTests.SceneDelegate",
                        "UISceneStoryboardFile": "Main",
                    ]],
                ],
            ],
        ]
        let app = UIApplication._mainLaunch(delegateType: AppDelegate.self)
        let entries = UIApplication._sceneManifestEntries(infoDictionary: info)
        XCTAssertEqual(entries.count, 1)
        XCTAssertNotNil(app._hostConnectSceneFromManifest(entries[0]))
        app._hostActivateConnectedScenes()

        let frame = "(0.0, 0.0, 393.0, 852.0)"
        let expected = [
            "AppDelegate.init state=2",
            "willFinishLaunching state=2 options=nil",
            "didFinishLaunching state=2 scenes=0",
            "configurationForConnecting name=Default Configuration delegateClass=SceneLaunchTests.SceneDelegate storyboard=true role=UIWindowSceneSessionRoleApplication",
            "SceneDelegate.init",
            "Root.init(coder:)",
            // (transcript: "SceneDelegate.window set ..." -- the probe's didSet
            // on `window`; the port writes the stored property directly, so a
            // property observer there does not run. Recorded divergence.)
            "scene(willConnectTo:) state=-1 window=UIWindow key=false hidden=true scene=true frame=\(frame) root=RootViewController config=Default Configuration storyboard=true delegateClass=SceneLaunchTests.SceneDelegate urlContexts=0 notificationResponse=nil shortcut=nil userActivities=0 restoration=nil",
            "Root.viewDidLoad window=nil superview=false",
            "Root.viewWillAppear animated=false window=nil",
            "Root.viewSafeAreaInsetsDidChange UIEdgeInsets(top: 59.0, left: 0.0, bottom: 34.0, right: 0.0)",
            "sceneWillEnterForeground state=-1 window=UIWindow key=true hidden=false scene=true frame=\(frame) root=RootViewController",
            "Root.viewDidAppear animated=false window=UIWindow key=true hidden=false scene=true frame=\(frame) root=RootViewController",
            "sceneDidBecomeActive state=0",
        ]
        XCTAssertEqual(launchEvents, expected)
        if launchEvents != expected {
            for (i, e) in launchEvents.enumerated() { print("PORT[\(i)] \(e)") }
        }
    }
}
