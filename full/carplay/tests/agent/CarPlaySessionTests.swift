import Foundation
@_spi(OpenUIKitHost) import CarPlay

func testSceneConnectDisconnectAndWindow() {
    carPlayOnMain {
        let sceneDelegate = RecordingSceneDelegate()
        let scene = CPTemplateApplicationScene()
        scene.delegate = sceneDelegate
        scene.openuikit_connectSimulatedSession(style: .dark)
        precondition(sceneDelegate.connected)
        precondition(scene.contentStyle == .dark)
        let controller = scene.interfaceController
        precondition(controller.hostSessionConnected)
        let window = scene.carWindow
        precondition(window.templateApplicationScene === scene)
        _ = window.mapButtonSafeAreaLayoutGuide
        _ = window.frame
        _ = CPWindow(frame: .zero)
        sceneDelegate.templateApplicationScene(scene, didSelect: CPManeuver())
        let alertAction = CPAlertAction(title: "A", style: .default, handler: { _ in })
        sceneDelegate.templateApplicationScene(scene, didSelect: CPNavigationAlert(
            titleVariants: ["Alert"],
            subtitleVariants: ["Sub"],
            image: UIImage(),
            primaryAction: alertAction,
            secondaryAction: nil,
            duration: CPNavigationAlertMinimumDuration
        ))
        scene.openuikit_disconnectSimulatedSession()
        precondition(sceneDelegate.disconnected)
        controller.setRootTemplate(CPListTemplate(title: "Root", sections: []), animated: false)
        controller.pushTemplate(CPListTemplate(title: "Child", sections: []), animated: false)
        precondition(controller.templates.count <= 1)
        scene.openuikit_connectSimulatedSession(style: .light)
        precondition(scene.contentStyle == .light)
    }
}

func testSessionConfigurationStyles() {
    carPlayOnMain {
        let sessionDelegate = RecordingSessionDelegate()
        let config = CPSessionConfiguration(delegate: sessionDelegate)
        precondition(config.limitedUserInterfaces.isEmpty)
        config.delegate = sessionDelegate
        config.openuikit_applySimulatedStyle(.dark)
        config.openuikit_applyLimitedUserInterfaces([.lists, .keyboard])
        precondition(sessionDelegate.style.contains(.dark))
        precondition(sessionDelegate.limited.contains(.lists))
        precondition(config.contentStyle.contains(.dark))
        _ = CPSessionConfiguration()
    }
}

func testSceneSessionRoleConstants() {
    _ = UISceneSession.Role.carTemplateApplication
    _ = UISceneSession.Role.CPTemplateApplicationDashboardSceneSessionRoleApplication
    _ = UISceneSession.Role.CPTemplateApplicationInstrumentClusterSceneSessionRoleApplication
}

func testApplicationDelegateHooks() {
    carPlayOnMain {
        let scene = CPTemplateApplicationScene()
        scene.openuikit_connectSimulatedSession(style: .light)
        let controller = scene.interfaceController
        let window = scene.carWindow
        let appDelegate = RecordingAppDelegate()
        appDelegate.application(UIApplication.shared, didConnectCarInterfaceController: controller, to: window)
        appDelegate.application(UIApplication.shared, didDisconnectCarInterfaceController: controller, from: window)
        appDelegate.application(UIApplication.shared, didSelect: CPManeuver())
        let alertAction = CPAlertAction(title: "A", style: .default, handler: { _ in })
        appDelegate.application(
            UIApplication.shared,
            didSelect: CPNavigationAlert(
                titleVariants: ["X"],
                subtitleVariants: nil,
                image: nil,
                primaryAction: alertAction,
                secondaryAction: nil,
                duration: 1
            )
        )
    }
}
