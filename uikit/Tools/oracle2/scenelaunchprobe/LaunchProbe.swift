// Scene-manifest launch oracle (NetNewsWire's shape): `@main` on a
// UIApplicationDelegate, Info.plist UIApplicationSceneManifest with
// UISceneDelegateClassName + UISceneStoryboardFile, the scene delegate never
// creating its window. Records the event order and the launch-time member
// facts NetNewsWire's AppDelegate / SceneDelegate / SceneCoordinator read.
// Build and run: run.sh (iPhone 16, iOS 26.1). Output: transcript-ios26.1.txt.
import UIKit
import UserNotifications

nonisolated(unsafe) var events: [String] = []
func log(_ s: String) { events.append(s); print("EV " + s) }

func windowFacts(_ w: UIWindow?) -> String {
    guard let w else { return "window=nil" }
    return "window=\(type(of: w)) key=\(w.isKeyWindow) hidden=\(w.isHidden) scene=\(w.windowScene != nil) frame=\(w.frame) root=\(w.rootViewController.map { "\(type(of: $0))" } ?? "nil")"
}

final class RootViewController: UIViewController {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        log("Root.init(coder:)")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        log("Root.viewDidLoad \(windowFacts(view.window)) superview=\(view.superview != nil)")
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        log("Root.viewWillAppear animated=\(animated) \(windowFacts(view.window))")
    }
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        log("Root.viewSafeAreaInsetsDidChange \(view.safeAreaInsets)")
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        log("Root.viewDidAppear animated=\(animated) \(windowFacts(view.window))")
        Probe.facts(self)
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow? {
        didSet { log("SceneDelegate.window set \(windowFacts(window))") }
    }
    override init() {
        super.init()
        log("SceneDelegate.init")
    }
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        log("scene(willConnectTo:) state=\(scene.activationState.rawValue) \(windowFacts(window)) config=\(session.configuration.name ?? "nil") storyboard=\(session.configuration.storyboard != nil) delegateClass=\(session.configuration.delegateClass.map { NSStringFromClass($0) } ?? "nil") urlContexts=\(connectionOptions.urlContexts.count) notificationResponse=\(connectionOptions.notificationResponse == nil ? "nil" : "set") shortcut=\(connectionOptions.shortcutItem == nil ? "nil" : "set") userActivities=\(connectionOptions.userActivities.count) restoration=\(session.stateRestorationActivity == nil ? "nil" : "set")")
    }
    func sceneWillEnterForeground(_ scene: UIScene) { log("sceneWillEnterForeground state=\(scene.activationState.rawValue) \(windowFacts(window))") }
    func sceneDidBecomeActive(_ scene: UIScene) { log("sceneDidBecomeActive state=\(scene.activationState.rawValue)") }
}

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    override init() {
        super.init()
        log("AppDelegate.init state=\(UIApplication.shared.applicationState.rawValue)")
    }
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        log("willFinishLaunching state=\(application.applicationState.rawValue) options=\(launchOptions == nil ? "nil" : "\(launchOptions!.count)")")
        return true
    }
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        log("didFinishLaunching state=\(application.applicationState.rawValue) scenes=\(application.connectedScenes.count)")
        Probe.appFacts(application)
        return true
    }
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let c = connectingSceneSession.configuration
        log("configurationForConnecting name=\(c.name ?? "nil") delegateClass=\(c.delegateClass.map { NSStringFromClass($0) } ?? "nil") storyboard=\(c.storyboard != nil) role=\(connectingSceneSession.role.rawValue)")
        return c
    }
    func applicationDidBecomeActive(_ application: UIApplication) { log("applicationDidBecomeActive (app delegate)") }
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        log("didRegisterForRemoteNotifications tokenBytes=\(deviceToken.count)")
    }
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        let e = error as NSError
        log("didFailToRegisterForRemoteNotifications domain=\(e.domain) code=\(e.code) msg=\(e.localizedDescription)")
    }
}

@MainActor enum Probe {
    static func appFacts(_ app: UIApplication) {
        print("FACT UIBackgroundTaskIdentifier.invalid=\(UIBackgroundTaskIdentifier.invalid.rawValue)")
        print("FACT UIBackgroundFetchResult newData=\(UIBackgroundFetchResult.newData.rawValue) noData=\(UIBackgroundFetchResult.noData.rawValue) failed=\(UIBackgroundFetchResult.failed.rawValue)")
        print("FACT UIStatusBarAnimation none=\(UIStatusBarAnimation.none.rawValue) fade=\(UIStatusBarAnimation.fade.rawValue) slide=\(UIStatusBarAnimation.slide.rawValue)")
        var expired = 0
        let t1 = app.beginBackgroundTask { expired += 1 }
        let t2 = app.beginBackgroundTask(withName: "probe") { expired += 1 }
        print("FACT beginBackgroundTask t1=\(t1.rawValue) t2=\(t2.rawValue) distinct=\(t1 != t2) invalid=\(t1 == .invalid) remaining>0=\(app.backgroundTimeRemaining > 0) remainingIsMax=\(app.backgroundTimeRemaining == .greatestFiniteMagnitude)")
        app.endBackgroundTask(t1)
        app.endBackgroundTask(t2)
        app.endBackgroundTask(t2)
        app.endBackgroundTask(.invalid)
        print("FACT endBackgroundTask twice/invalid ok expired=\(expired)")
        print("FACT isRegisteredForRemoteNotifications before=\(app.isRegisteredForRemoteNotifications)")
        app.registerForRemoteNotifications()
        print("FACT isRegisteredForRemoteNotifications after-call=\(app.isRegisteredForRemoteNotifications)")
        print("FACT shortcutItems=\(app.shortcutItems?.count ?? -1)")
    }

    static func facts(_ vc: UIViewController) {
        let app = UIApplication.shared
        print("FACT isRegisteredForRemoteNotifications at-appear=\(app.isRegisteredForRemoteNotifications)")
        print("FACT vc.prefersStatusBarHidden=\(vc.prefersStatusBarHidden) preferredStatusBarUpdateAnimation=\(vc.preferredStatusBarUpdateAnimation.rawValue)")
        vc.setNeedsStatusBarAppearanceUpdate()
        let split = UISplitViewController(style: .doubleColumn)
        print("FACT split.prefersStatusBarHidden=\(split.prefersStatusBarHidden) anim=\(split.preferredStatusBarUpdateAnimation.rawValue)")
        print("FACT vc.undoManager=\(vc.undoManager.map { "\(type(of: $0))" } ?? "nil") window.undoManager=\(vc.view.window?.undoManager.map { "\(type(of: $0))" } ?? "nil") same=\(vc.undoManager === vc.view.window?.undoManager) detachedVC=\(UIViewController().undoManager.map { "\(type(of: $0))" } ?? "nil") app=\(app.undoManager.map { "\(type(of: $0))" } ?? "nil")")
        let item = UINavigationItem(title: "t")
        print("FACT navigationItem.subtitle=\(item.subtitle.map { "\"\($0)\"" } ?? "nil") subtitleView=\(item.subtitleView == nil ? "nil" : "set")")
        let flex = UIBarButtonItem.flexibleSpace()
        let fixed = UIBarButtonItem.fixedSpace(12)
        print("FACT flexibleSpace title=\(flex.title ?? "nil") image=\(flex.image == nil ? "nil" : "set") width=\(flex.width) isEnabled=\(flex.isEnabled) target=\(flex.target == nil ? "nil" : "set") action=\(flex.action.map { NSStringFromSelector($0) } ?? "nil") fixedWidth=\(fixed.width) menu=\(flex.menu == nil ? "nil" : "set")")
        let a = UIContextualAction(style: .destructive, title: "Delete") { _, _, done in done(true) }
        print("FACT UIContextualAction.accessibilityLabel=\(a.accessibilityLabel ?? "nil")")
        a.accessibilityLabel = "x"
        print("FACT UIContextualAction.accessibilityLabel set=\(a.accessibilityLabel ?? "nil")")
        let nav = UINavigationController(rootViewController: UIViewController())
        let v2 = UIViewController(), v3 = UIViewController()
        nav.pushViewController(v2, animated: false)
        nav.pushViewController(v3, animated: false)
        let popped = nav.popToViewController(v2, animated: false)
        let notInStack = nav.popToViewController(UIViewController(), animated: false)
        let toTop = nav.popToViewController(v2, animated: false)
        print("FACT popToViewController popped=\(popped?.count ?? -1) poppedIsV3=\(popped?.first === v3) stack=\(nav.viewControllers.count) notInStack=\(notInStack.map { "\($0.count)" } ?? "nil") alreadyTop=\(toTop.map { "\($0.count)" } ?? "nil")")
        print("DONE")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { exit(0) }
    }
}
