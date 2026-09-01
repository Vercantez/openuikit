import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(MapKit)
import MapKit
#endif

@MainActor
public protocol CPListTemplateItem: AnyObject {
    var isEnabled: Bool { get set }
    var text: String? { get }
    var userInfo: Any? { get set }
}

@MainActor
public protocol CPSelectableListItem: CPListTemplateItem {
    var handler: ((any CPSelectableListItem, @escaping () -> Void) -> Void)? { get set }
}

@MainActor
public protocol CPBarButtonProviding: AnyObject {
    var backButton: CPBarButton? { get set }
    var leadingNavigationBarButtons: [CPBarButton] { get set }
    var trailingNavigationBarButtons: [CPBarButton] { get set }
}

@MainActor
public protocol CPInterfaceControllerDelegate: AnyObject {
    func templateDidAppear(_ aTemplate: CPTemplate, animated: Bool)
    func templateDidDisappear(_ aTemplate: CPTemplate, animated: Bool)
    func templateWillAppear(_ aTemplate: CPTemplate, animated: Bool)
    func templateWillDisappear(_ aTemplate: CPTemplate, animated: Bool)
}

@MainActor
public extension CPInterfaceControllerDelegate {
    func templateDidAppear(_ aTemplate: CPTemplate, animated: Bool) {}
    func templateDidDisappear(_ aTemplate: CPTemplate, animated: Bool) {}
    func templateWillAppear(_ aTemplate: CPTemplate, animated: Bool) {}
    func templateWillDisappear(_ aTemplate: CPTemplate, animated: Bool) {}
}

@MainActor
public protocol CPListTemplateDelegate: AnyObject {
    func listTemplate(_ listTemplate: CPListTemplate, didSelect item: CPListItem) async
}

@MainActor
public protocol CPTabBarTemplateDelegate: AnyObject {
    func tabBarTemplate(_ tabBarTemplate: CPTabBarTemplate, didSelect selectedTemplate: CPTemplate)
}

@MainActor
public protocol CPNowPlayingTemplateObserver: AnyObject {
    func nowPlayingTemplateAlbumArtistButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate)
    func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate)
}

public extension CPNowPlayingTemplateObserver {
    func nowPlayingTemplateAlbumArtistButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {}
    func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {}
}

@MainActor
public protocol CPSearchTemplateDelegate: AnyObject {
    func searchTemplate(_ searchTemplate: CPSearchTemplate, selectedResult item: CPListItem) async
    func searchTemplate(_ searchTemplate: CPSearchTemplate, updatedSearchText searchText: String) async -> [CPListItem]
    func searchTemplateSearchButtonPressed(_ searchTemplate: CPSearchTemplate)
}

@MainActor
public extension CPSearchTemplateDelegate {
    func searchTemplateSearchButtonPressed(_ searchTemplate: CPSearchTemplate) {}
}

#if canImport(MapKit)
@MainActor
public protocol CPPointOfInterestTemplateDelegate: AnyObject {
    func pointOfInterestTemplate(
        _ pointOfInterestTemplate: CPPointOfInterestTemplate,
        didChangeMapRegion region: MKCoordinateRegion
    )
    func pointOfInterestTemplate(
        _ pointOfInterestTemplate: CPPointOfInterestTemplate,
        didSelectPointOfInterest pointOfInterest: CPPointOfInterest
    )
}

@MainActor
public extension CPPointOfInterestTemplateDelegate {
    func pointOfInterestTemplate(
        _ pointOfInterestTemplate: CPPointOfInterestTemplate,
        didSelectPointOfInterest pointOfInterest: CPPointOfInterest
    ) {}
}
#endif

@MainActor
public protocol CPSessionConfigurationDelegate: AnyObject {
    func sessionConfiguration(
        _ sessionConfiguration: CPSessionConfiguration,
        contentStyleChanged contentStyle: CPContentStyle
    )
    func sessionConfiguration(
        _ sessionConfiguration: CPSessionConfiguration,
        limitedUserInterfacesChanged limitedUserInterfaces: CPLimitableUserInterface
    )
}

@MainActor
public extension CPSessionConfigurationDelegate {
    func sessionConfiguration(
        _ sessionConfiguration: CPSessionConfiguration,
        contentStyleChanged contentStyle: CPContentStyle
    ) {}
    func sessionConfiguration(
        _ sessionConfiguration: CPSessionConfiguration,
        limitedUserInterfacesChanged limitedUserInterfaces: CPLimitableUserInterface
    ) {}
}

#if canImport(UIKit)
public protocol CPApplicationDelegate: UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didConnectCarInterfaceController interfaceController: CPInterfaceController,
        to window: CPWindow
    )
    func application(
        _ application: UIApplication,
        didDisconnectCarInterfaceController interfaceController: CPInterfaceController,
        from window: CPWindow
    )
    func application(_ application: UIApplication, didSelect maneuver: CPManeuver)
    func application(_ application: UIApplication, didSelect navigationAlert: CPNavigationAlert)
}

public extension CPApplicationDelegate {
    func application(_ application: UIApplication, didSelect maneuver: CPManeuver) {}
    func application(_ application: UIApplication, didSelect navigationAlert: CPNavigationAlert) {}
}

public protocol CPTemplateApplicationDashboardSceneDelegate: UISceneDelegate {
    func templateApplicationDashboardScene(
        _ templateApplicationDashboardScene: CPTemplateApplicationDashboardScene,
        didConnect dashboardController: CPDashboardController,
        to window: UIWindow
    )
    func templateApplicationDashboardScene(
        _ templateApplicationDashboardScene: CPTemplateApplicationDashboardScene,
        didDisconnect dashboardController: CPDashboardController,
        from window: UIWindow
    )
}

public extension CPTemplateApplicationDashboardSceneDelegate {
    func templateApplicationDashboardScene(
        _ templateApplicationDashboardScene: CPTemplateApplicationDashboardScene,
        didConnect dashboardController: CPDashboardController,
        to window: UIWindow
    ) {}
    func templateApplicationDashboardScene(
        _ templateApplicationDashboardScene: CPTemplateApplicationDashboardScene,
        didDisconnect dashboardController: CPDashboardController,
        from window: UIWindow
    ) {}
}

@MainActor
public protocol CPTemplateApplicationInstrumentClusterSceneDelegate: UISceneDelegate {
    func contentStyleDidChange(_ contentStyle: UIUserInterfaceStyle)
    func templateApplicationInstrumentClusterScene(
        _ templateApplicationInstrumentClusterScene: CPTemplateApplicationInstrumentClusterScene,
        didConnect instrumentClusterController: CPInstrumentClusterController
    )
    func templateApplicationInstrumentClusterScene(
        _ templateApplicationInstrumentClusterScene: CPTemplateApplicationInstrumentClusterScene,
        didDisconnectInstrumentClusterController instrumentClusterController: CPInstrumentClusterController
    )
}

@MainActor
public extension CPTemplateApplicationInstrumentClusterSceneDelegate {
    func contentStyleDidChange(_ contentStyle: UIUserInterfaceStyle) {}
    func templateApplicationInstrumentClusterScene(
        _ templateApplicationInstrumentClusterScene: CPTemplateApplicationInstrumentClusterScene,
        didConnect instrumentClusterController: CPInstrumentClusterController
    ) {}
    func templateApplicationInstrumentClusterScene(
        _ templateApplicationInstrumentClusterScene: CPTemplateApplicationInstrumentClusterScene,
        didDisconnectInstrumentClusterController instrumentClusterController: CPInstrumentClusterController
    ) {}
}

public protocol CPTemplateApplicationSceneDelegate: UISceneDelegate {
    func contentStyleDidChange(_ contentStyle: UIUserInterfaceStyle)
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    )
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController,
        to window: CPWindow
    )
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    )
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController,
        from window: CPWindow
    )
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didSelect maneuver: CPManeuver
    )
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didSelect navigationAlert: CPNavigationAlert
    )
}

public extension CPTemplateApplicationSceneDelegate {
    func contentStyleDidChange(_ contentStyle: UIUserInterfaceStyle) {}
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {}
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController,
        to window: CPWindow
    ) {}
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {}
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController,
        from window: CPWindow
    ) {}
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didSelect maneuver: CPManeuver
    ) {}
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didSelect navigationAlert: CPNavigationAlert
    ) {}
}
#else
public protocol CPApplicationDelegate: AnyObject {}
public protocol CPTemplateApplicationDashboardSceneDelegate: AnyObject {}
public protocol CPTemplateApplicationInstrumentClusterSceneDelegate: AnyObject {}
public protocol CPTemplateApplicationSceneDelegate: AnyObject {}
#endif

public protocol CPInstrumentClusterControllerDelegate: AnyObject {
    func instrumentClusterController(
        _ instrumentClusterController: CPInstrumentClusterController,
        didChangeCompassSetting compassSetting: CPInstrumentClusterSetting
    )
    func instrumentClusterController(
        _ instrumentClusterController: CPInstrumentClusterController,
        didChangeSpeedLimitSetting speedLimitSetting: CPInstrumentClusterSetting
    )
    #if canImport(UIKit)
    func instrumentClusterControllerDidConnect(_ instrumentClusterWindow: UIWindow)
    func instrumentClusterControllerDidDisconnectWindow(_ instrumentClusterWindow: UIWindow)
    #endif
    func instrumentClusterControllerDidZoom(in instrumentClusterController: CPInstrumentClusterController)
    func instrumentClusterControllerDidZoomOut(_ instrumentClusterController: CPInstrumentClusterController)
}

public extension CPInstrumentClusterControllerDelegate {
    func instrumentClusterController(
        _ instrumentClusterController: CPInstrumentClusterController,
        didChangeCompassSetting compassSetting: CPInstrumentClusterSetting
    ) {}
    func instrumentClusterController(
        _ instrumentClusterController: CPInstrumentClusterController,
        didChangeSpeedLimitSetting speedLimitSetting: CPInstrumentClusterSetting
    ) {}
    func instrumentClusterControllerDidZoom(in instrumentClusterController: CPInstrumentClusterController) {}
    func instrumentClusterControllerDidZoomOut(_ instrumentClusterController: CPInstrumentClusterController) {}
}

@MainActor
public protocol CPMapTemplateDelegate: AnyObject {
    func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        didDismiss navigationAlert: CPNavigationAlert,
        dismissalContext: CPNavigationAlert.DismissalContext
    )
    func mapTemplate(_ mapTemplate: CPMapTemplate, didEndPanGestureWithVelocity velocity: CGPoint)
    func mapTemplate(_ mapTemplate: CPMapTemplate, didEndZoomGestureWithVelocity velocity: CGFloat)
    func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        didRotateWithCenter center: CGPoint,
        rotation: CGFloat,
        velocity: CGFloat
    )
    func mapTemplate(_ mapTemplate: CPMapTemplate, didShow navigationAlert: CPNavigationAlert)
    func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        didUpdatePanGestureWithTranslation translation: CGPoint,
        velocity: CGPoint
    )
    func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        didUpdateZoomGestureWithCenter center: CGPoint,
        scale: CGFloat,
        velocity: CGFloat
    )
    func mapTemplate(_ mapTemplate: CPMapTemplate, displayStyleFor maneuver: CPManeuver) -> CPManeuverDisplayStyle
    func mapTemplate(_ mapTemplate: CPMapTemplate, panBeganWith direction: CPMapTemplate.PanDirection)
    func mapTemplate(_ mapTemplate: CPMapTemplate, panEndedWith direction: CPMapTemplate.PanDirection)
    func mapTemplate(_ mapTemplate: CPMapTemplate, panWith direction: CPMapTemplate.PanDirection)
    func mapTemplate(_ mapTemplate: CPMapTemplate, pitchEndedWithCenter center: CGPoint)
    func mapTemplate(_ mapTemplate: CPMapTemplate, pitchWithCenter center: CGPoint)
    func mapTemplate(_ mapTemplate: CPMapTemplate, rotationDidEndWithVelocity velocity: CGFloat)
    #if canImport(MapKit)
    func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        selectedPreviewFor trip: CPTrip,
        using routeChoice: CPRouteChoice
    )
    func mapTemplate(_ mapTemplate: CPMapTemplate, startedTrip trip: CPTrip, using routeChoice: CPRouteChoice)
    #endif
    func mapTemplate(_ mapTemplate: CPMapTemplate, shouldShowNotificationFor maneuver: CPManeuver) -> Bool
    func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        shouldShowNotificationFor navigationAlert: CPNavigationAlert
    ) -> Bool
    func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        shouldUpdateNotificationFor maneuver: CPManeuver,
        with travelEstimates: CPTravelEstimates
    ) -> Bool
    func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        willDismiss navigationAlert: CPNavigationAlert,
        dismissalContext: CPNavigationAlert.DismissalContext
    )
    func mapTemplate(_ mapTemplate: CPMapTemplate, willShow navigationAlert: CPNavigationAlert)
    func mapTemplateDidBeginPanGesture(_ mapTemplate: CPMapTemplate)
    func mapTemplateDidBeginPitchGesture(_ mapTemplate: CPMapTemplate)
    func mapTemplateDidBeginRotationGesture(_ mapTemplate: CPMapTemplate)
    func mapTemplateDidBeginZoomGesture(_ mapTemplate: CPMapTemplate)
    func mapTemplateDidCancelNavigation(_ mapTemplate: CPMapTemplate)
    func mapTemplateDidDismissPanningInterface(_ mapTemplate: CPMapTemplate)
    func mapTemplateDidShowPanningInterface(_ mapTemplate: CPMapTemplate)
    func mapTemplateShouldProvideNavigationMetadata(_ mapTemplate: CPMapTemplate) -> Bool
    func mapTemplateWillDismissPanningInterface(_ mapTemplate: CPMapTemplate)
}

@MainActor
public extension CPMapTemplateDelegate {
    func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        didDismiss navigationAlert: CPNavigationAlert,
        dismissalContext: CPNavigationAlert.DismissalContext
    ) {}
    func mapTemplate(_ mapTemplate: CPMapTemplate, didEndPanGestureWithVelocity velocity: CGPoint) {}
    func mapTemplate(_ mapTemplate: CPMapTemplate, didEndZoomGestureWithVelocity velocity: CGFloat) {}
    func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        didRotateWithCenter center: CGPoint,
        rotation: CGFloat,
        velocity: CGFloat
    ) {}
    func mapTemplate(_ mapTemplate: CPMapTemplate, didShow navigationAlert: CPNavigationAlert) {}
    func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        didUpdatePanGestureWithTranslation translation: CGPoint,
        velocity: CGPoint
    ) {}
    func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        didUpdateZoomGestureWithCenter center: CGPoint,
        scale: CGFloat,
        velocity: CGFloat
    ) {}
    func mapTemplate(_ mapTemplate: CPMapTemplate, displayStyleFor maneuver: CPManeuver) -> CPManeuverDisplayStyle {
        []
    }
    func mapTemplate(_ mapTemplate: CPMapTemplate, panBeganWith direction: CPMapTemplate.PanDirection) {}
    func mapTemplate(_ mapTemplate: CPMapTemplate, panEndedWith direction: CPMapTemplate.PanDirection) {}
    func mapTemplate(_ mapTemplate: CPMapTemplate, panWith direction: CPMapTemplate.PanDirection) {}
    func mapTemplate(_ mapTemplate: CPMapTemplate, pitchEndedWithCenter center: CGPoint) {}
    func mapTemplate(_ mapTemplate: CPMapTemplate, pitchWithCenter center: CGPoint) {}
    func mapTemplate(_ mapTemplate: CPMapTemplate, rotationDidEndWithVelocity velocity: CGFloat) {}
    #if canImport(MapKit)
    func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        selectedPreviewFor trip: CPTrip,
        using routeChoice: CPRouteChoice
    ) {}
    func mapTemplate(_ mapTemplate: CPMapTemplate, startedTrip trip: CPTrip, using routeChoice: CPRouteChoice) {}
    #endif
    func mapTemplate(_ mapTemplate: CPMapTemplate, shouldShowNotificationFor maneuver: CPManeuver) -> Bool {
        false
    }
    func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        shouldShowNotificationFor navigationAlert: CPNavigationAlert
    ) -> Bool {
        false
    }
    func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        shouldUpdateNotificationFor maneuver: CPManeuver,
        with travelEstimates: CPTravelEstimates
    ) -> Bool {
        false
    }
    func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        willDismiss navigationAlert: CPNavigationAlert,
        dismissalContext: CPNavigationAlert.DismissalContext
    ) {}
    func mapTemplate(_ mapTemplate: CPMapTemplate, willShow navigationAlert: CPNavigationAlert) {}
    func mapTemplateDidBeginPanGesture(_ mapTemplate: CPMapTemplate) {}
    func mapTemplateDidBeginPitchGesture(_ mapTemplate: CPMapTemplate) {}
    func mapTemplateDidBeginRotationGesture(_ mapTemplate: CPMapTemplate) {}
    func mapTemplateDidBeginZoomGesture(_ mapTemplate: CPMapTemplate) {}
    func mapTemplateDidCancelNavigation(_ mapTemplate: CPMapTemplate) {}
    func mapTemplateDidDismissPanningInterface(_ mapTemplate: CPMapTemplate) {}
    func mapTemplateDidShowPanningInterface(_ mapTemplate: CPMapTemplate) {}
    func mapTemplateShouldProvideNavigationMetadata(_ mapTemplate: CPMapTemplate) -> Bool { false }
    func mapTemplateWillDismissPanningInterface(_ mapTemplate: CPMapTemplate) {}
}
