@_spi(OpenUIKitHost) import TipKit
import Foundation

func testConfigurationCloudKitAndFrequency() {
    let automatic = Tips.ConfigurationOption.CloudKitContainer.automatic
    let named = Tips.ConfigurationOption.CloudKitContainer.named("iCloud.example")
    precondition(automatic != named)
    precondition(automatic == .automatic)
    let daily = Tips.ConfigurationOption.DisplayFrequency.daily
    precondition(daily == .daily)
    precondition(Tips.ConfigurationOption.DisplayFrequency.hourly != .weekly)
    precondition(Tips.ConfigurationOption.DisplayFrequency.monthly != .immediate)
    _ = Tips.ConfigurationOption.displayFrequency(.hourly)
    _ = Tips.ConfigurationOption.cloudKitContainer(.automatic)
    _ = Tips.ConfigurationOption.cloudKitContainer(nil)
}

func testDatastoreLocationFailClosed() {
    let memory = Tips.ConfigurationOption.DatastoreLocation.applicationDefault
    let url = Tips.ConfigurationOption.DatastoreLocation.url(
        URL(fileURLWithPath: "/tmp/tipkit-should-not-be-created.store")
    )
    precondition(memory != url)
    precondition(memory == .applicationDefault)
    do {
        _ = try Tips.ConfigurationOption.DatastoreLocation.groupContainer(
            identifier: "group.example"
        )
        fatalError("groupContainer must throw")
    } catch let error as TipKitError {
        precondition(error == .missingGroupContainerEntitlements)
    } catch {
        fatalError("groupContainer must throw TipKitError")
    }
    _ = Tips.ConfigurationOption.datastoreLocation(memory)
}

func testConfigureOnceAndResetDatastore() {
    TipsHostControl.resetForHostTests()
    let store = tipKitUniqueDirectory().appendingPathComponent("tips.store")
    try! Tips.configure([
        .displayFrequency(.daily),
        .datastoreLocation(.url(store)),
        .cloudKitContainer(.named("iCloud.example")),
    ])
    let snapshot = TipsHostControl.snapshotConfig()
    precondition(snapshot.configured)
    precondition(snapshot.frequency == .daily)
    precondition(FileManager.default.fileExists(atPath: store.path))
    precondition(TipsHostControl.cloudKitSyncEnabled() == false)
    do {
        try Tips.configure()
        fatalError("second configure must throw")
    } catch let error as TipKitError {
        precondition(error == .tipsDatastoreAlreadyConfigured)
    } catch {
        fatalError("second configure must throw TipKitError")
    }

    let tip = EligibleHostTip()
    tip.invalidate(reason: .actionPerformed)
    precondition(tip.status == .invalidated(.actionPerformed))
    try! Tips.resetDatastore()
    precondition(tip.status == .available)
}
