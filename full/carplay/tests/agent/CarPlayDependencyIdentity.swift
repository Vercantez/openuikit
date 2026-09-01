// Future EC2 integrated-client probe. The isolated host gate compiles only
// `CarPlayRuntime.swift` and does not stage UIKit or MapKit. Do not treat a
// passing isolated gate as evidence that this file ran.
//
// Required EC2 sequence:
// 1. Build guest Foundation, UIKit, and MapKit modules and dylibs.
// 2. Build CarPlay with those -I/-L paths.
// 3. Compile this file importing CarPlay, UIKit, and MapKit.
// 4. Link against libCarPlay.dylib (and the dependency dylibs).
// 5. Run with LD_LIBRARY_PATH, confirm libCarPlay.dylib is loaded, and print
//    exactly `CARPLAY_DEPENDENCY_IDENTITY_OK`.

@_spi(OpenUIKitHost) import CarPlay
import Foundation
import MapKit
import UIKit

@main
enum CarPlayDependencyIdentity {
    static func main() async {
        await MainActor.run {
            run()
        }
    }

    @MainActor
    static func run() {
        let image = UIImage()
        let color = UIColor.black
        let viewController = UIViewController()
        let mapItem = MKMapItem()

        let listItem = CPListItem(text: "Identity", detailText: "Probe", image: image)
        listItem.userInfo = viewController
        listItem.setImage(image)
        precondition(listItem.userInfo is UIViewController)

        let colorAction = CPAlertAction(title: "OK", color: color) { _ in }
        _ = colorAction.color

        let trip = CPTrip(origin: mapItem, destination: mapItem, routeChoices: [])
        precondition(trip.origin === mapItem)
        precondition(trip.destination === mapItem)

        let poi = CPPointOfInterest(
            location: mapItem,
            title: "Office",
            subtitle: nil,
            summary: nil,
            detailTitle: nil,
            detailSubtitle: nil,
            detailSummary: nil,
            pinImage: image
        )
        _ = CPPointOfInterestTemplate(title: "Places", pointsOfInterest: [poi], selectedIndex: 0)

        let list = CPListTemplate(
            title: "Identity",
            sections: [CPListSection(items: [listItem])]
        )
        let controller = CPInterfaceController()
        controller.connectHostVehicleSession(rootTemplate: list)
        controller.disconnectHostVehicleSession()

        let scene = makeScene()
        listItem.userInfo = scene
        precondition(listItem.userInfo is UIScene)
        _ = bindVehicleScenes as (UISceneSession, UIScene.ConnectionOptions, UIWindowScene) -> Void

        confirmCarPlayDylibLoaded()
        print("CARPLAY_DEPENDENCY_IDENTITY_OK")
    }

    @MainActor
    static func bindVehicleScenes(
        session: UISceneSession,
        connectionOptions: UIScene.ConnectionOptions,
        windowScene: UIWindowScene
    ) {
        let templateScene = CPTemplateApplicationScene(
            session: session,
            connectionOptions: connectionOptions
        )
        let dashboardScene = CPTemplateApplicationDashboardScene(
            session: session,
            connectionOptions: connectionOptions
        )
        let clusterScene = CPTemplateApplicationInstrumentClusterScene(
            session: session,
            connectionOptions: connectionOptions
        )
        let window = CPWindow(windowScene: windowScene)
        window.templateApplicationScene = templateScene
        _ = CPWindow(frame: .zero)
        _ = templateScene.interfaceController
        _ = templateScene.carWindow
        _ = dashboardScene.dashboardController
        _ = clusterScene.instrumentClusterController
        _ = UISceneSession.Role.carTemplateApplication
        _ = UISceneSession.Role.CPTemplateApplicationDashboardSceneSessionRoleApplication
        _ = UISceneSession.Role.CPTemplateApplicationInstrumentClusterSceneSessionRoleApplication
        _ = templateScene as UIScene
        _ = window as UIWindow
        _ = UIViewController()
    }

    @MainActor
    static func makeScene() -> UIScene {
        if let existing = UIApplication.shared.connectedScenes.first {
            return existing
        }
        let session = UISceneSession()
        let options = UIScene.ConnectionOptions()
        return CPTemplateApplicationScene(session: session, connectionOptions: options)
    }

    static func confirmCarPlayDylibLoaded() {
        let maps = (try? String(contentsOfFile: "/proc/self/maps", encoding: .utf8)) ?? ""
        precondition(
            maps.contains("libCarPlay.dylib"),
            "libCarPlay.dylib is not loaded in the process"
        )
    }
}
