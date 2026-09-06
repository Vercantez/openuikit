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
