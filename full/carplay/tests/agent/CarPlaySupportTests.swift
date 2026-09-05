import Foundation
@_spi(OpenUIKitHost) import CarPlay

final class HostNSCoder: NSCoder {
    override var allowsKeyedCoding: Bool { true }
}

func carPlayFailClosedCoder() -> NSCoder {
    HostNSCoder()
}

func carPlayHashValue<T: Hashable>(_ value: T) -> Int {
    var hasher = Hasher()
    value.hash(into: &hasher)
    return hasher.finalize()
}

func carPlayCheckEnum<T: Hashable & RawRepresentable>(_ values: [T]) {
    precondition(!values.isEmpty)
    for value in values {
        _ = carPlayHashValue(value)
        _ = value != values[0] || value == values[0]
        _ = T(rawValue: value.rawValue) == value
    }
}

func carPlayExerciseOptionSet<T: OptionSet>(_ a: T, _ b: T) where T.Element == T {
    let empty = T()
    precondition(empty.isEmpty)
    _ = T([a, b])
    _ = a.union(b)
    _ = a.intersection(b)
    _ = a.symmetricDifference(b)
    _ = a.subtracting(b)
    _ = a.isSubset(of: b)
    _ = a.isSuperset(of: b)
    _ = a.isDisjoint(with: b)
    _ = a.isStrictSubset(of: a.union(b))
    _ = a.union(b).isStrictSuperset(of: a)
    _ = a.contains(a)
    _ = a != b || a == b
    var y = a
    y.formUnion(b)
    y.formIntersection(a)
    y.formSymmetricDifference(b)
    y.subtract(a)
    _ = y.insert(a)
    _ = y.remove(a)
    _ = y.update(with: b)
}

func carPlayOnMain<T>(_ body: @MainActor () -> T) -> T {
    if Thread.isMainThread {
        return MainActor.assumeIsolated(body)
    }
    return DispatchQueue.main.sync {
        MainActor.assumeIsolated(body)
    }
}

final class RecordingInterfaceDelegate: NSObject, CPInterfaceControllerDelegate {
    var events: [String] = []
    func templateWillAppear(_ aTemplate: CPTemplate, animated: Bool) { events.append("willAppear") }
    func templateDidAppear(_ aTemplate: CPTemplate, animated: Bool) { events.append("didAppear") }
    func templateWillDisappear(_ aTemplate: CPTemplate, animated: Bool) { events.append("willDisappear") }
    func templateDidDisappear(_ aTemplate: CPTemplate, animated: Bool) { events.append("didDisappear") }
}

final class RecordingSceneDelegate: NSObject, CPTemplateApplicationSceneDelegate {
    var connected = false
    var disconnected = false
    var style: UIUserInterfaceStyle = .unspecified
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController, to window: CPWindow) { connected = true }
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {}
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController, from window: CPWindow) { disconnected = true }
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController) {}
    func contentStyleDidChange(_ contentStyle: UIUserInterfaceStyle) { style = contentStyle }
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didSelect maneuver: CPManeuver) {}
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didSelect navigationAlert: CPNavigationAlert) {}
}

final class RecordingTabDelegate: NSObject, CPTabBarTemplateDelegate {
    var selected: CPTemplate?
    func tabBarTemplate(_ tabBarTemplate: CPTabBarTemplate, didSelect selectedTemplate: CPTemplate) { selected = selectedTemplate }
}

final class RecordingNowPlayingObserver: NSObject, CPNowPlayingTemplateObserver {
    var upNext = 0
    var album = 0
    func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) { upNext += 1 }
    func nowPlayingTemplateAlbumArtistButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) { album += 1 }
}

final class RecordingSessionDelegate: NSObject, CPSessionConfigurationDelegate {
    var style: CPContentStyle = []
    var limited: CPLimitableUserInterface = []
    func sessionConfiguration(_ sessionConfiguration: CPSessionConfiguration, contentStyleChanged contentStyle: CPContentStyle) { style = contentStyle }
    func sessionConfiguration(_ sessionConfiguration: CPSessionConfiguration, limitedUserInterfacesChanged limitedUserInterfaces: CPLimitableUserInterface) { limited = limitedUserInterfaces }
}

final class RecordingSearchDelegate: NSObject, CPSearchTemplateDelegate {
    func searchTemplate(_ searchTemplate: CPSearchTemplate, selectedResult item: CPListItem) async {}
    func searchTemplate(_ searchTemplate: CPSearchTemplate, updatedSearchText searchText: String) async -> [CPListItem] {
        [CPListItem(text: searchText, detailText: "hit")]
    }
    func searchTemplateSearchButtonPressed(_ searchTemplate: CPSearchTemplate) {}
}

final class RecordingMapDelegate: NSObject, CPMapTemplateDelegate {}

final class RecordingPOIDelegate: NSObject, CPPointOfInterestTemplateDelegate {
    func pointOfInterestTemplate(_ pointOfInterestTemplate: CPPointOfInterestTemplate, didChangeMapRegion region: MKCoordinateRegion) {}
}

final class RecordingListDelegate: NSObject, CPListTemplateDelegate {
    func listTemplate(_ listTemplate: CPListTemplate, didSelect item: CPListItem) async {}
}

final class RecordingClusterDelegate: NSObject, CPInstrumentClusterControllerDelegate {
    func instrumentClusterControllerDidConnect(_ instrumentClusterWindow: UIWindow) {}
    func instrumentClusterControllerDidDisconnectWindow(_ instrumentClusterWindow: UIWindow) {}
}

final class RecordingDashDelegate: NSObject, CPTemplateApplicationDashboardSceneDelegate {}

final class RecordingClusterSceneDelegate: NSObject, CPTemplateApplicationInstrumentClusterSceneDelegate {}

final class RecordingAppDelegate: NSObject, CPApplicationDelegate {
    func application(_ application: UIApplication, didConnectCarInterfaceController interfaceController: CPInterfaceController, to window: CPWindow) {}
    func application(_ application: UIApplication, didDisconnectCarInterfaceController interfaceController: CPInterfaceController, from window: CPWindow) {}
}
