@_spi(OpenUIKitHost) import ExtensionFoundation
import Observation

func testMonitorInitHasEmptyIdentities() {
    let monitor = AppExtensionPoint.Monitor()
    precondition(monitor.identities.isEmpty)
}

func testMonitorStateDefaults() {
    let monitor = AppExtensionPoint.Monitor()
    let state = monitor.state
    precondition(state.identities.isEmpty)
    precondition(state.disabledCount == 0)
    precondition(state.unapprovedCount == 0)
}

func testMonitorStateEquality() {
    let a = AppExtensionPoint.Monitor().state
    let b = AppExtensionPoint.Monitor().state
    precondition(a == b)
    precondition(!(a != b))
}

func testMonitorStateInequalityWhenCountsDiffer() {
    let empty = AppExtensionPoint.Monitor.State(
        hostIdentities: [],
        unapprovedCount: 0,
        disabledCount: 0
    )
    let disabled = AppExtensionPoint.Monitor.State(
        hostIdentities: [],
        unapprovedCount: 0,
        disabledCount: 1
    )
    precondition(empty != disabled)
    precondition(disabled.disabledCount == 1)
}

func testMonitorStateUnapprovedCount() {
    let state = AppExtensionPoint.Monitor.State(
        hostIdentities: [],
        unapprovedCount: 4,
        disabledCount: 0
    )
    precondition(state.unapprovedCount == 4)
    precondition(state.disabledCount == 0)
}

func testMonitorStateStoresIdentities() {
    let identity = AppExtensionIdentity(
        bundleIdentifier: "com.example.ext",
        extensionPointIdentifier: "editor",
        localizedName: "Editor"
    )
    let state = AppExtensionPoint.Monitor.State(
        hostIdentities: [identity],
        unapprovedCount: 0,
        disabledCount: 0
    )
    precondition(state.identities.count == 1)
    precondition(state.identities[0] == identity)
}

func testMonitorIsObservable() {
    let monitor = AppExtensionPoint.Monitor()
    func takeObservable(_ value: any Observable) -> Bool {
        _ = value
        return true
    }
    precondition(takeObservable(monitor))
}

func testMonitorAddAppExtensionPointTracksAsync() async {
    let point = AppExtensionPoint.Bind.buildBlock(
        AppExtensionPoint.Identifier("com.example.async-add")
    )
    let monitor = AppExtensionPoint.Monitor()
    do {
        try await monitor.addAppExtensionPoint(point)
    } catch {
        preconditionFailure("addAppExtensionPoint must not throw \(error)")
    }
    precondition(monitor.host_trackedCount == 1)
    precondition(monitor.identities.isEmpty)
}

func testMonitorInitWithPointAsync() async {
    let point = AppExtensionPoint.Bind.buildBlock(
        AppExtensionPoint.Identifier("com.example.async-init")
    )
    let monitor: AppExtensionPoint.Monitor
    do {
        monitor = try await AppExtensionPoint.Monitor(appExtensionPoint: point)
    } catch {
        preconditionFailure("Monitor init must not throw \(error)")
    }
    precondition(monitor.host_trackedCount == 1)
    precondition(monitor.identities.isEmpty)
}

func testMonitorRemoveAppExtensionPointAsync() async {
    let point = AppExtensionPoint.Bind.buildBlock(
        AppExtensionPoint.Identifier("com.example.async-remove")
    )
    let monitor = AppExtensionPoint.Monitor()
    do {
        try await monitor.addAppExtensionPoint(point)
    } catch {
        preconditionFailure("addAppExtensionPoint must not throw \(error)")
    }
    precondition(monitor.host_trackedCount == 1)
    do {
        try await monitor.removeAppExtensionPoint(point)
    } catch {
        preconditionFailure("removeAppExtensionPoint must not throw \(error)")
    }
    precondition(monitor.host_trackedCount == 0)
    precondition(monitor.identities.isEmpty)
}
