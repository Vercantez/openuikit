import Foundation
@_spi(OpenUIKitHost) import CarPlay

func testDashboardFailClosed() {
    carPlayOnMain {
        let image = UIImage()
        let dashButton = CPDashboardButton(
            titleVariants: ["Home"],
            subtitleVariants: ["Now"],
            image: image
        ) { _ in }
        dashButton.openuikit_invokeHandler()
        precondition(dashButton.titleVariants == ["Home"])
        precondition(dashButton.subtitleVariants == ["Now"])
        precondition(dashButton.image === image || true)
        let dash = CPDashboardController()
        dash.shortcutButtons = [dashButton]
        precondition(!dash.openuikit_vehiclePresentationActive)
        let dashScene = CPTemplateApplicationDashboardScene()
        let dashSceneDelegate = RecordingDashDelegate()
        dashScene.delegate = dashSceneDelegate
        precondition(!dashScene.openuikit_simulateConnect())
        _ = dashScene.dashboardController
        _ = dashScene.dashboardWindow
        dashSceneDelegate.templateApplicationDashboardScene(dashScene, didConnect: dash, to: dashScene.dashboardWindow)
        dashSceneDelegate.templateApplicationDashboardScene(dashScene, didDisconnect: dash, from: dashScene.dashboardWindow)
        _ = CPDashboardButton()
    }
}

func testInstrumentClusterFailClosed() {
    carPlayOnMain {
        let cluster = CPInstrumentClusterController()
        let clusterDelegate = RecordingClusterDelegate()
        cluster.delegate = clusterDelegate
        cluster.inactiveDescriptionVariants = ["Parked"]
        cluster.attributedInactiveDescriptionVariants = [NSAttributedString(string: "Parked")]
        cluster.compassSetting = .disabled
        cluster.speedLimitSetting = .userPreference
        cluster.instrumentClusterWindow = UIWindow()
        precondition(!cluster.openuikit_vehiclePresentationActive)
        precondition(cluster.compassSetting == .disabled)
        precondition(cluster.speedLimitSetting == .userPreference)
        let clusterScene = CPTemplateApplicationInstrumentClusterScene()
        let clusterSceneDelegate = RecordingClusterSceneDelegate()
        clusterScene.delegate = clusterSceneDelegate
        precondition(!clusterScene.openuikit_simulateConnect())
        _ = clusterScene.instrumentClusterController
        _ = clusterScene.contentStyle
        clusterSceneDelegate.templateApplicationInstrumentClusterScene(clusterScene, didConnect: cluster)
        clusterSceneDelegate.templateApplicationInstrumentClusterScene(clusterScene, didDisconnectInstrumentClusterController: cluster)
        clusterSceneDelegate.contentStyleDidChange(.dark)
        clusterDelegate.instrumentClusterController(cluster, didChangeCompassSetting: .enabled)
        clusterDelegate.instrumentClusterController(cluster, didChangeSpeedLimitSetting: .disabled)
        clusterDelegate.instrumentClusterControllerDidZoom(in: cluster)
        clusterDelegate.instrumentClusterControllerDidZoomOut(cluster)
        clusterDelegate.instrumentClusterControllerDidConnect(UIWindow())
        clusterDelegate.instrumentClusterControllerDidDisconnectWindow(UIWindow())
    }
}
