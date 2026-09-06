import Foundation
import ManagedSettings

private func uniqueName() -> ManagedSettingsStore.Name {
    ManagedSettingsStore.Name(UUID().uuidString)
}

func testStoreDefaultInitSharesName() {
    let a = ManagedSettingsStore()
    let b = ManagedSettingsStore(named: .default)
    a.siri.denySiri = true
    precondition(b.siri.denySiri == true)
    a.clearAllSettings()
    precondition(b.siri.denySiri == nil)
}

func testStoreNamedSharing() {
    let name = uniqueName()
    let a = ManagedSettingsStore(named: name)
    let b = ManagedSettingsStore(named: name)
    a.passcode.lockPasscode = true
    precondition(b.passcode.lockPasscode == true)
}

func testStoreDistinctNames() {
    let a = ManagedSettingsStore(named: uniqueName())
    let b = ManagedSettingsStore(named: uniqueName())
    a.cellular.lockESIM = true
    precondition(b.cellular.lockESIM == nil)
}

func testStoreClearAllSettings() {
    let store = ManagedSettingsStore(named: uniqueName())
    store.account.lockAccounts = true
    store.media.denyExplicitContent = true
    store.safari.cookiePolicy = .never
    store.webContent.blockedByFilter = .all(except: [])
    store.clearAllSettings()
    precondition(store.account.lockAccounts == nil)
    precondition(store.media.denyExplicitContent == nil)
    precondition(store.safari.cookiePolicy == nil)
    precondition(store.webContent.blockedByFilter == nil)
}

func testStoreAccountProperty() {
    let store = ManagedSettingsStore(named: uniqueName())
    var settings = store.account
    settings.lockAccounts = false
    store.account = settings
    precondition(store.account.lockAccounts == false)
}

func testStoreApplicationProperty() {
    let store = ManagedSettingsStore(named: uniqueName())
    var settings = store.application
    settings.denyAppRemoval = false
    store.application = settings
    precondition(store.application.denyAppRemoval == false)
}

func testStoreAppStoreProperty() {
    let store = ManagedSettingsStore(named: uniqueName())
    var settings = store.appStore
    settings.maximumRating = 1000
    store.appStore = settings
    precondition(store.appStore.maximumRating == 1000)
}

func testStoreCellularProperty() {
    let store = ManagedSettingsStore(named: uniqueName())
    var settings = store.cellular
    settings.lockCellularPlan = false
    store.cellular = settings
    precondition(store.cellular.lockCellularPlan == false)
}

func testStoreDateAndTimeProperty() {
    let store = ManagedSettingsStore(named: uniqueName())
    var settings = store.dateAndTime
    settings.requireAutomaticDateAndTime = false
    store.dateAndTime = settings
    precondition(store.dateAndTime.requireAutomaticDateAndTime == false)
}

func testStoreGameCenterProperty() {
    let store = ManagedSettingsStore(named: uniqueName())
    var settings = store.gameCenter
    settings.denyAddingFriends = false
    store.gameCenter = settings
    precondition(store.gameCenter.denyAddingFriends == false)
}

func testStoreMediaProperty() {
    let store = ManagedSettingsStore(named: uniqueName())
    var settings = store.media
    settings.maximumMovieRating = 400
    store.media = settings
    precondition(store.media.maximumMovieRating == 400)
}

func testStorePasscodeProperty() {
    let store = ManagedSettingsStore(named: uniqueName())
    var settings = store.passcode
    settings.lockPasscode = false
    store.passcode = settings
    precondition(store.passcode.lockPasscode == false)
}

func testStoreSafariProperty() {
    let store = ManagedSettingsStore(named: uniqueName())
    var settings = store.safari
    settings.cookiePolicy = .currentWebsite
    store.safari = settings
    precondition(store.safari.cookiePolicy == .currentWebsite)
}

func testStoreShieldProperty() {
    let store = ManagedSettingsStore(named: uniqueName())
    var settings = store.shield
    settings.applicationCategories = ShieldSettings.ActivityCategoryPolicy<Application>.none
    store.shield = settings
    precondition(store.shield.applicationCategories == ShieldSettings.ActivityCategoryPolicy<Application>.none)
}

func testStoreSiriProperty() {
    let store = ManagedSettingsStore(named: uniqueName())
    var settings = store.siri
    settings.denySiri = false
    store.siri = settings
    precondition(store.siri.denySiri == false)
}

func testStoreWebContentProperty() {
    let store = ManagedSettingsStore(named: uniqueName())
    var settings = store.webContent
    settings.blockedByFilter = .auto([WebDomain(domain: "adult.example")], except: [])
    store.webContent = settings
    precondition(store.webContent.blockedByFilter == .auto([WebDomain(domain: "adult.example")], except: []))
}

func testEffectiveDenyExplicitContentUnapplied() {
    let store = ManagedSettingsStore(named: uniqueName())
    store.media.denyExplicitContent = true
    precondition(store.effectiveDenyExplicitContent == false)
    precondition(store.effectiveDenyExplicitContent == MediaSettings.denyExplicitContent.defaultValue)
}

func testEffectiveMaximumMovieRatingUnapplied() {
    let store = ManagedSettingsStore(named: uniqueName())
    store.media.maximumMovieRating = 200
    precondition(store.effectiveMaximumMovieRating == 1000)
    precondition(store.effectiveMaximumMovieRating == MediaSettings.maximumMovieRating.defaultValue)
}

func testEffectiveMaximumTVShowRatingUnapplied() {
    let store = ManagedSettingsStore(named: uniqueName())
    store.media.maximumTVShowRating = 300
    precondition(store.effectiveMaximumTVShowRating == 1000)
    precondition(store.effectiveMaximumTVShowRating == MediaSettings.maximumTVShowRating.defaultValue)
}

func testManagedSettingsGroupConformance() {
    let store = ManagedSettingsStore(named: uniqueName())
    let groups: [any ManagedSettingsGroup] = [
        store.account,
        store.application,
        store.appStore,
        store.cellular,
        store.dateAndTime,
        store.gameCenter,
        store.media,
        store.passcode,
        store.safari,
        store.shield,
        store.siri,
        store.webContent,
    ]
    precondition(groups.count == 12)
}

func testSettingMetadataDefaultValue() {
    let metadata = AccountSettings.lockAccounts
    precondition(metadata.defaultValue == false)
}

func testBoundedSettingMetadataBounds() {
    precondition(MediaSettings.maximumMovieRating.bounds.lowerBound == 0)
    precondition(MediaSettings.maximumMovieRating.bounds.upperBound == 1000)
    precondition(MediaSettings.maximumMovieRating.defaultValue == 1000)
}
