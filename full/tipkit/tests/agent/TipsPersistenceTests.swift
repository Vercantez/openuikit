@_spi(OpenUIKitHost) import TipKit
import Foundation

func testConfigureCreatesApplicationDefaultStore() {
    TipsHostControl.resetForHostTests()
    let root = tipKitUniqueDirectory()
    TipsHostControl.setApplicationSupportRootForHost(root)
    try! Tips.configure([.datastoreLocation(.applicationDefault)])
    let url = root
        .appendingPathComponent("TipKit", isDirectory: true)
        .appendingPathComponent("datastore.json", isDirectory: false)
    precondition(FileManager.default.fileExists(atPath: url.path))
    precondition(TipsHostControl.datastoreFileURL()?.path == url.path)
}

func testURLDatastorePersistsDonationsAndParameters() {
    TipsHostControl.resetForHostTests()
    let store = tipKitUniqueDirectory().appendingPathComponent("tips.store")
    try! Tips.configure([.datastoreLocation(.url(store))])
    let event = Tips.Event<Tips.EmptyDonation>(id: "persist-open")
    event.sendDonation()
    let parameter = Tips.Parameter(wrappedValue: 0, id: "persist-count")
    parameter.wrappedValue = 9
    EligibleHostTip().invalidate(reason: .tipClosed)
    precondition(FileManager.default.fileExists(atPath: store.path))
    precondition(event.donations.count == 1)

    TipsHostControl.resetForHostTests()
    try! Tips.configure([.datastoreLocation(.url(store))])
    precondition(Tips.Event<Tips.EmptyDonation>(id: "persist-open").donations.count == 1)
    precondition(Tips.Parameter(wrappedValue: 0, id: "persist-count").wrappedValue == 9)
    precondition(EligibleHostTip().status == .invalidated(.tipClosed))
}

func testResetDatastoreClearsOnDiskStore() {
    TipsHostControl.resetForHostTests()
    let store = tipKitUniqueDirectory().appendingPathComponent("reset.store")
    try! Tips.configure([.datastoreLocation(.url(store))])
    Tips.Event<Tips.EmptyDonation>(id: "reset-open").sendDonation()
    EligibleHostTip().invalidate(reason: .actionPerformed)
    try! Tips.resetDatastore()
    precondition(Tips.Event<Tips.EmptyDonation>(id: "reset-open").donations.isEmpty)
    precondition(EligibleHostTip().status == .available)

    TipsHostControl.resetForHostTests()
    try! Tips.configure([.datastoreLocation(.url(store))])
    precondition(Tips.Event<Tips.EmptyDonation>(id: "reset-open").donations.isEmpty)
    precondition(EligibleHostTip().status == .available)
}

func testTransientParameterDoesNotPersist() {
    TipsHostControl.resetForHostTests()
    let store = tipKitUniqueDirectory().appendingPathComponent("transient.store")
    try! Tips.configure([.datastoreLocation(.url(store))])
    let parameter = Tips.Parameter(
        wrappedValue: true,
        id: "transient-flag",
        options: .transient
    )
    parameter.wrappedValue = false
    precondition(parameter.wrappedValue == false)

    TipsHostControl.resetForHostTests()
    try! Tips.configure([.datastoreLocation(.url(store))])
    let restored = Tips.Parameter(
        wrappedValue: true,
        id: "transient-flag",
        options: .transient
    )
    precondition(restored.wrappedValue == true)
}

func testCloudKitContainerIsFailClosed() {
    TipsHostControl.resetForHostTests()
    try! Tips.configure([.cloudKitContainer(.named("iCloud.example"))])
    let snapshot = TipsHostControl.snapshotConfig()
    precondition(snapshot.configured)
    precondition(TipsHostControl.cloudKitSyncEnabled() == false)
}
