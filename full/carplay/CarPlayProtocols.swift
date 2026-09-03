import Foundation

public protocol CPApplicationDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication, didConnectCarInterfaceController interfaceController: CPInterfaceController, to window: CPWindow)
    func application(_ application: UIApplication, didDisconnectCarInterfaceController interfaceController: CPInterfaceController, from window: CPWindow)
    func application(_ application: UIApplication, didSelect maneuver: CPManeuver)
    func application(_ application: UIApplication, didSelect navigationAlert: CPNavigationAlert)
}

extension CPApplicationDelegate {
    public func application(_ application: UIApplication, didSelect maneuver: CPManeuver) {
        
    }
    public func application(_ application: UIApplication, didSelect navigationAlert: CPNavigationAlert) {
        
    }
}

@MainActor public protocol CPBarButtonProviding: NSObjectProtocol {
    var backButton: CPBarButton? { get set }
    var leadingNavigationBarButtons: [CPBarButton] { get set }
    var trailingNavigationBarButtons: [CPBarButton] { get set }
}

public protocol CPInstrumentClusterControllerDelegate: NSObjectProtocol {
    func instrumentClusterController(_ instrumentClusterController: CPInstrumentClusterController, didChangeCompassSetting compassSetting: CPInstrumentClusterSetting)
    func instrumentClusterController(_ instrumentClusterController: CPInstrumentClusterController, didChangeSpeedLimitSetting speedLimitSetting: CPInstrumentClusterSetting)
    func instrumentClusterControllerDidConnect(_ instrumentClusterWindow: UIWindow)
    func instrumentClusterControllerDidDisconnectWindow(_ instrumentClusterWindow: UIWindow)
    func instrumentClusterControllerDidZoom(in instrumentClusterController: CPInstrumentClusterController)
    func instrumentClusterControllerDidZoomOut(_ instrumentClusterController: CPInstrumentClusterController)
}

extension CPInstrumentClusterControllerDelegate {
    public func instrumentClusterController(_ instrumentClusterController: CPInstrumentClusterController, didChangeCompassSetting compassSetting: CPInstrumentClusterSetting) {
        
    }
    public func instrumentClusterController(_ instrumentClusterController: CPInstrumentClusterController, didChangeSpeedLimitSetting speedLimitSetting: CPInstrumentClusterSetting) {
        
    }
    public func instrumentClusterControllerDidZoom(in instrumentClusterController: CPInstrumentClusterController) {
        
    }
    public func instrumentClusterControllerDidZoomOut(_ instrumentClusterController: CPInstrumentClusterController) {
        
    }
}

@MainActor public protocol CPInterfaceControllerDelegate: NSObjectProtocol {
    func templateDidAppear(_ aTemplate: CPTemplate, animated: Bool)
    func templateDidDisappear(_ aTemplate: CPTemplate, animated: Bool)
    func templateWillAppear(_ aTemplate: CPTemplate, animated: Bool)
    func templateWillDisappear(_ aTemplate: CPTemplate, animated: Bool)
}

extension CPInterfaceControllerDelegate {
    public func templateDidAppear(_ aTemplate: CPTemplate, animated: Bool) {
        
    }
    public func templateDidDisappear(_ aTemplate: CPTemplate, animated: Bool) {
        
    }
    public func templateWillAppear(_ aTemplate: CPTemplate, animated: Bool) {
        
    }
    public func templateWillDisappear(_ aTemplate: CPTemplate, animated: Bool) {
        
    }
}

public protocol CPListTemplateDelegate: NSObjectProtocol {
    func listTemplate(_ listTemplate: CPListTemplate, didSelect item: CPListItem) async
}

@MainActor public protocol CPListTemplateItem: NSObjectProtocol {
    var isEnabled: Bool { get set }
    var text: String? { get }
    var userInfo: Any? { get set }
}

@MainActor public protocol CPMapTemplateDelegate: NSObjectProtocol {
    func mapTemplate(_ mapTemplate: CPMapTemplate, didDismiss navigationAlert: CPNavigationAlert, dismissalContext: CPNavigationAlert.DismissalContext)
    func mapTemplate(_ mapTemplate: CPMapTemplate, didEndPanGestureWithVelocity velocity: CGPoint)
    func mapTemplate(_ mapTemplate: CPMapTemplate, didEndZoomGestureWithVelocity velocity: CGFloat)
    func mapTemplate(_ mapTemplate: CPMapTemplate, didRotateWithCenter center: CGPoint, rotation: CGFloat, velocity: CGFloat)
    func mapTemplate(_ mapTemplate: CPMapTemplate, didShow navigationAlert: CPNavigationAlert)
    func mapTemplate(_ mapTemplate: CPMapTemplate, didUpdatePanGestureWithTranslation translation: CGPoint, velocity: CGPoint)
    func mapTemplate(_ mapTemplate: CPMapTemplate, didUpdateZoomGestureWithCenter center: CGPoint, scale: CGFloat, velocity: CGFloat)
    func mapTemplate(_ mapTemplate: CPMapTemplate, displayStyleFor maneuver: CPManeuver) -> CPManeuverDisplayStyle
    func mapTemplate(_ mapTemplate: CPMapTemplate, panBeganWith direction: CPMapTemplate.PanDirection)
    func mapTemplate(_ mapTemplate: CPMapTemplate, panEndedWith direction: CPMapTemplate.PanDirection)
    func mapTemplate(_ mapTemplate: CPMapTemplate, panWith direction: CPMapTemplate.PanDirection)
    func mapTemplate(_ mapTemplate: CPMapTemplate, pitchEndedWithCenter center: CGPoint)
    func mapTemplate(_ mapTemplate: CPMapTemplate, pitchWithCenter center: CGPoint)
    func mapTemplate(_ mapTemplate: CPMapTemplate, rotationDidEndWithVelocity velocity: CGFloat)
    func mapTemplate(_ mapTemplate: CPMapTemplate, selectedPreviewFor trip: CPTrip, using routeChoice: CPRouteChoice)
    func mapTemplate(_ mapTemplate: CPMapTemplate, shouldShowNotificationFor maneuver: CPManeuver) -> Bool
    func mapTemplate(_ mapTemplate: CPMapTemplate, shouldShowNotificationFor navigationAlert: CPNavigationAlert) -> Bool
    func mapTemplate(_ mapTemplate: CPMapTemplate, shouldUpdateNotificationFor maneuver: CPManeuver, with travelEstimates: CPTravelEstimates) -> Bool
    func mapTemplate(_ mapTemplate: CPMapTemplate, startedTrip trip: CPTrip, using routeChoice: CPRouteChoice)
    func mapTemplate(_ mapTemplate: CPMapTemplate, willDismiss navigationAlert: CPNavigationAlert, dismissalContext: CPNavigationAlert.DismissalContext)
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

extension CPMapTemplateDelegate {
    public func mapTemplate(_ mapTemplate: CPMapTemplate, didDismiss navigationAlert: CPNavigationAlert, dismissalContext: CPNavigationAlert.DismissalContext) {
        
    }
    public func mapTemplate(_ mapTemplate: CPMapTemplate, didEndPanGestureWithVelocity velocity: CGPoint) {
        
    }
    public func mapTemplate(_ mapTemplate: CPMapTemplate, didEndZoomGestureWithVelocity velocity: CGFloat) {
        
    }
    public func mapTemplate(_ mapTemplate: CPMapTemplate, didRotateWithCenter center: CGPoint, rotation: CGFloat, velocity: CGFloat) {
        
    }
    public func mapTemplate(_ mapTemplate: CPMapTemplate, didShow navigationAlert: CPNavigationAlert) {
        
    }
    public func mapTemplate(_ mapTemplate: CPMapTemplate, didUpdatePanGestureWithTranslation translation: CGPoint, velocity: CGPoint) {
        
    }
    public func mapTemplate(_ mapTemplate: CPMapTemplate, didUpdateZoomGestureWithCenter center: CGPoint, scale: CGFloat, velocity: CGFloat) {
        
    }
    public func mapTemplate(_ mapTemplate: CPMapTemplate, displayStyleFor maneuver: CPManeuver) -> CPManeuverDisplayStyle {
        return []
    }
    public func mapTemplate(_ mapTemplate: CPMapTemplate, panBeganWith direction: CPMapTemplate.PanDirection) {
        
    }
    public func mapTemplate(_ mapTemplate: CPMapTemplate, panEndedWith direction: CPMapTemplate.PanDirection) {
        
    }
    public func mapTemplate(_ mapTemplate: CPMapTemplate, panWith direction: CPMapTemplate.PanDirection) {
        
    }
    public func mapTemplate(_ mapTemplate: CPMapTemplate, pitchEndedWithCenter center: CGPoint) {
        
    }
    public func mapTemplate(_ mapTemplate: CPMapTemplate, pitchWithCenter center: CGPoint) {
        
    }
    public func mapTemplate(_ mapTemplate: CPMapTemplate, rotationDidEndWithVelocity velocity: CGFloat) {
        
    }
    public func mapTemplate(_ mapTemplate: CPMapTemplate, selectedPreviewFor trip: CPTrip, using routeChoice: CPRouteChoice) {
        
    }
    public func mapTemplate(_ mapTemplate: CPMapTemplate, shouldShowNotificationFor maneuver: CPManeuver) -> Bool {
        return false
    }
    public func mapTemplate(_ mapTemplate: CPMapTemplate, shouldShowNotificationFor navigationAlert: CPNavigationAlert) -> Bool {
        return false
    }
    public func mapTemplate(_ mapTemplate: CPMapTemplate, shouldUpdateNotificationFor maneuver: CPManeuver, with travelEstimates: CPTravelEstimates) -> Bool {
        return false
    }
    public func mapTemplate(_ mapTemplate: CPMapTemplate, startedTrip trip: CPTrip, using routeChoice: CPRouteChoice) {
        
    }
    public func mapTemplate(_ mapTemplate: CPMapTemplate, willDismiss navigationAlert: CPNavigationAlert, dismissalContext: CPNavigationAlert.DismissalContext) {
        
    }
    public func mapTemplate(_ mapTemplate: CPMapTemplate, willShow navigationAlert: CPNavigationAlert) {
        
    }
    public func mapTemplateDidBeginPanGesture(_ mapTemplate: CPMapTemplate) {
        
    }
    public func mapTemplateDidBeginPitchGesture(_ mapTemplate: CPMapTemplate) {
        
    }
    public func mapTemplateDidBeginRotationGesture(_ mapTemplate: CPMapTemplate) {
        
    }
    public func mapTemplateDidBeginZoomGesture(_ mapTemplate: CPMapTemplate) {
        
    }
    public func mapTemplateDidCancelNavigation(_ mapTemplate: CPMapTemplate) {
        
    }
    public func mapTemplateDidDismissPanningInterface(_ mapTemplate: CPMapTemplate) {
        
    }
    public func mapTemplateDidShowPanningInterface(_ mapTemplate: CPMapTemplate) {
        
    }
    public func mapTemplateShouldProvideNavigationMetadata(_ mapTemplate: CPMapTemplate) -> Bool {
        return false
    }
    public func mapTemplateWillDismissPanningInterface(_ mapTemplate: CPMapTemplate) {
        
    }
}

public protocol CPNowPlayingTemplateObserver: NSObjectProtocol {
    func nowPlayingTemplateAlbumArtistButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate)
    func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate)
}

extension CPNowPlayingTemplateObserver {
    public func nowPlayingTemplateAlbumArtistButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
        
    }
    public func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
        
    }
}

@MainActor public protocol CPPointOfInterestTemplateDelegate: NSObjectProtocol {
    func pointOfInterestTemplate(_ pointOfInterestTemplate: CPPointOfInterestTemplate, didChangeMapRegion region: MKCoordinateRegion)
    func pointOfInterestTemplate(_ pointOfInterestTemplate: CPPointOfInterestTemplate, didSelectPointOfInterest pointOfInterest: CPPointOfInterest)
}

extension CPPointOfInterestTemplateDelegate {
    public func pointOfInterestTemplate(_ pointOfInterestTemplate: CPPointOfInterestTemplate, didSelectPointOfInterest pointOfInterest: CPPointOfInterest) {
        
    }
}

@MainActor public protocol CPSearchTemplateDelegate: NSObjectProtocol {
    func searchTemplate(_ searchTemplate: CPSearchTemplate, selectedResult item: CPListItem) async
    func searchTemplate(_ searchTemplate: CPSearchTemplate, updatedSearchText searchText: String) async -> [CPListItem]
    func searchTemplateSearchButtonPressed(_ searchTemplate: CPSearchTemplate)
}

extension CPSearchTemplateDelegate {
    public func searchTemplateSearchButtonPressed(_ searchTemplate: CPSearchTemplate) {
        
    }
}

@MainActor public protocol CPSelectableListItem: CPListTemplateItem {
    var handler: ((any CPSelectableListItem, @escaping () -> Void) -> Void)? { get set }
}

@MainActor public protocol CPSessionConfigurationDelegate: NSObjectProtocol {
    func sessionConfiguration(_ sessionConfiguration: CPSessionConfiguration, contentStyleChanged contentStyle: CPContentStyle)
    func sessionConfiguration(_ sessionConfiguration: CPSessionConfiguration, limitedUserInterfacesChanged limitedUserInterfaces: CPLimitableUserInterface)
}

extension CPSessionConfigurationDelegate {
    public func sessionConfiguration(_ sessionConfiguration: CPSessionConfiguration, contentStyleChanged contentStyle: CPContentStyle) {
        
    }
    public func sessionConfiguration(_ sessionConfiguration: CPSessionConfiguration, limitedUserInterfacesChanged limitedUserInterfaces: CPLimitableUserInterface) {
        
    }
}

@MainActor public protocol CPTabBarTemplateDelegate: NSObjectProtocol {
    func tabBarTemplate(_ tabBarTemplate: CPTabBarTemplate, didSelect selectedTemplate: CPTemplate)
}

public protocol CPTemplateApplicationDashboardSceneDelegate: UISceneDelegate {
    func templateApplicationDashboardScene(_ templateApplicationDashboardScene: CPTemplateApplicationDashboardScene, didConnect dashboardController: CPDashboardController, to window: UIWindow)
    func templateApplicationDashboardScene(_ templateApplicationDashboardScene: CPTemplateApplicationDashboardScene, didDisconnect dashboardController: CPDashboardController, from window: UIWindow)
}

extension CPTemplateApplicationDashboardSceneDelegate {
    public func templateApplicationDashboardScene(_ templateApplicationDashboardScene: CPTemplateApplicationDashboardScene, didConnect dashboardController: CPDashboardController, to window: UIWindow) {
        
    }
    public func templateApplicationDashboardScene(_ templateApplicationDashboardScene: CPTemplateApplicationDashboardScene, didDisconnect dashboardController: CPDashboardController, from window: UIWindow) {
        
    }
}

@MainActor public protocol CPTemplateApplicationInstrumentClusterSceneDelegate: UISceneDelegate {
    func contentStyleDidChange(_ contentStyle: UIUserInterfaceStyle)
    func templateApplicationInstrumentClusterScene(_ templateApplicationInstrumentClusterScene: CPTemplateApplicationInstrumentClusterScene, didConnect instrumentClusterController: CPInstrumentClusterController)
    func templateApplicationInstrumentClusterScene(_ templateApplicationInstrumentClusterScene: CPTemplateApplicationInstrumentClusterScene, didDisconnectInstrumentClusterController instrumentClusterController: CPInstrumentClusterController)
}

extension CPTemplateApplicationInstrumentClusterSceneDelegate {
    public func contentStyleDidChange(_ contentStyle: UIUserInterfaceStyle) {
        
    }
    public func templateApplicationInstrumentClusterScene(_ templateApplicationInstrumentClusterScene: CPTemplateApplicationInstrumentClusterScene, didConnect instrumentClusterController: CPInstrumentClusterController) {
        
    }
    public func templateApplicationInstrumentClusterScene(_ templateApplicationInstrumentClusterScene: CPTemplateApplicationInstrumentClusterScene, didDisconnectInstrumentClusterController instrumentClusterController: CPInstrumentClusterController) {
        
    }
}

public protocol CPTemplateApplicationSceneDelegate: UISceneDelegate {
    func contentStyleDidChange(_ contentStyle: UIUserInterfaceStyle)
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController)
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController, to window: CPWindow)
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController)
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController, from window: CPWindow)
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didSelect maneuver: CPManeuver)
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didSelect navigationAlert: CPNavigationAlert)
}

extension CPTemplateApplicationSceneDelegate {
    public func contentStyleDidChange(_ contentStyle: UIUserInterfaceStyle) {
        
    }
    public func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        
    }
    public func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController, to window: CPWindow) {
        
    }
    public func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        
    }
    public func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController, from window: CPWindow) {
        
    }
    public func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didSelect maneuver: CPManeuver) {
        
    }
    public func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didSelect navigationAlert: CPNavigationAlert) {
        
    }
}

