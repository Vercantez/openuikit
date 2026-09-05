import Foundation
import ManagedSettings

private func uniqueStore() -> ManagedSettingsStore {
    ManagedSettingsStore(named: ManagedSettingsStore.Name(UUID().uuidString))
}

func testAccountSettingsThroughStore() {
    let store = uniqueStore()
    precondition(store.account.lockAccounts == nil)
    store.account.lockAccounts = true
    precondition(store.account.lockAccounts == true)
    precondition(AccountSettings.lockAccounts.defaultValue == false)
}

func testApplicationSettingsBlockedApplications() {
    let store = uniqueStore()
    precondition(store.application.blockedApplications == nil)
    let app = Application(bundleIdentifier: "com.blocked")
    store.application.blockedApplications = [app]
    precondition(store.application.blockedApplications == [app])
    precondition(ApplicationSettings.blockedApplications.defaultValue.isEmpty)
}

func testApplicationSettingsDenyAppInstallation() {
    let store = uniqueStore()
    precondition(store.application.denyAppInstallation == nil)
    store.application.denyAppInstallation = true
    precondition(store.application.denyAppInstallation == true)
    precondition(ApplicationSettings.denyAppInstallation.defaultValue == false)
}

func testApplicationSettingsDenyAppRemoval() {
    let store = uniqueStore()
    precondition(store.application.denyAppRemoval == nil)
    store.application.denyAppRemoval = true
    precondition(store.application.denyAppRemoval == true)
    precondition(ApplicationSettings.denyAppRemoval.defaultValue == false)
}

func testAppStoreSettingsDenyInAppPurchases() {
    let store = uniqueStore()
    precondition(store.appStore.denyInAppPurchases == nil)
    store.appStore.denyInAppPurchases = true
    precondition(store.appStore.denyInAppPurchases == true)
    precondition(AppStoreSettings.denyInAppPurchases.defaultValue == false)
}

func testAppStoreSettingsMaximumRating() {
    let store = uniqueStore()
    precondition(store.appStore.maximumRating == nil)
    store.appStore.maximumRating = 600
    precondition(store.appStore.maximumRating == 600)
    precondition(AppStoreSettings.maximumRating.defaultValue == 1000)
    precondition(AppStoreSettings.maximumRating.bounds == 0...2000)
}

func testAppStoreSettingsRequirePasswordForPurchases() {
    let store = uniqueStore()
    precondition(store.appStore.requirePasswordForPurchases == nil)
    store.appStore.requirePasswordForPurchases = true
    precondition(store.appStore.requirePasswordForPurchases == true)
    precondition(AppStoreSettings.requirePasswordForPurchases.defaultValue == false)
}

func testCellularSettingsLockAppCellularData() {
    let store = uniqueStore()
    precondition(store.cellular.lockAppCellularData == nil)
    store.cellular.lockAppCellularData = true
    precondition(store.cellular.lockAppCellularData == true)
    precondition(CellularSettings.lockAppCellularData.defaultValue == false)
}

func testCellularSettingsLockCellularPlan() {
    let store = uniqueStore()
    precondition(store.cellular.lockCellularPlan == nil)
    store.cellular.lockCellularPlan = true
    precondition(store.cellular.lockCellularPlan == true)
    precondition(CellularSettings.lockCellularPlan.defaultValue == false)
}

func testCellularSettingsLockESIM() {
    let store = uniqueStore()
    precondition(store.cellular.lockESIM == nil)
    store.cellular.lockESIM = true
    precondition(store.cellular.lockESIM == true)
    precondition(CellularSettings.lockESIM.defaultValue == false)
}

func testDateAndTimeSettingsRequireAutomatic() {
    let store = uniqueStore()
    precondition(store.dateAndTime.requireAutomaticDateAndTime == nil)
    store.dateAndTime.requireAutomaticDateAndTime = true
    precondition(store.dateAndTime.requireAutomaticDateAndTime == true)
    precondition(DateAndTimeSettings.requireAutomaticDateAndTime.defaultValue == false)
}

func testGameCenterSettingsDenyAddingFriends() {
    let store = uniqueStore()
    precondition(store.gameCenter.denyAddingFriends == nil)
    store.gameCenter.denyAddingFriends = true
    precondition(store.gameCenter.denyAddingFriends == true)
    precondition(GameCenterSettings.denyAddingFriends.defaultValue == false)
}

func testGameCenterSettingsDenyMultiplayerGaming() {
    let store = uniqueStore()
    precondition(store.gameCenter.denyMultiplayerGaming == nil)
    store.gameCenter.denyMultiplayerGaming = true
    precondition(store.gameCenter.denyMultiplayerGaming == true)
    precondition(GameCenterSettings.denyMultiplayerGaming.defaultValue == false)
}

func testMediaSettingsDenyBookstoreErotica() {
    let store = uniqueStore()
    precondition(store.media.denyBookstoreErotica == nil)
    store.media.denyBookstoreErotica = true
    precondition(store.media.denyBookstoreErotica == true)
    precondition(MediaSettings.denyBookstoreErotica.defaultValue == false)
}

func testMediaSettingsDenyExplicitContent() {
    let store = uniqueStore()
    precondition(store.media.denyExplicitContent == nil)
    store.media.denyExplicitContent = true
    precondition(store.media.denyExplicitContent == true)
    precondition(MediaSettings.denyExplicitContent.defaultValue == false)
}

func testMediaSettingsDenyMusicService() {
    let store = uniqueStore()
    precondition(store.media.denyMusicService == nil)
    store.media.denyMusicService = true
    precondition(store.media.denyMusicService == true)
    precondition(MediaSettings.denyMusicService.defaultValue == false)
}

func testMediaSettingsMaximumMovieRating() {
    let store = uniqueStore()
    precondition(store.media.maximumMovieRating == nil)
    store.media.maximumMovieRating = 500
    precondition(store.media.maximumMovieRating == 500)
    precondition(MediaSettings.maximumMovieRating.defaultValue == 1000)
    precondition(MediaSettings.maximumMovieRating.bounds == 0...1000)
}

func testMediaSettingsMaximumTVShowRating() {
    let store = uniqueStore()
    precondition(store.media.maximumTVShowRating == nil)
    store.media.maximumTVShowRating = 600
    precondition(store.media.maximumTVShowRating == 600)
    precondition(MediaSettings.maximumTVShowRating.defaultValue == 1000)
    precondition(MediaSettings.maximumTVShowRating.bounds == 0...1000)
}

func testPasscodeSettingsLockPasscode() {
    let store = uniqueStore()
    precondition(store.passcode.lockPasscode == nil)
    store.passcode.lockPasscode = true
    precondition(store.passcode.lockPasscode == true)
    precondition(PasscodeSettings.lockPasscode.defaultValue == false)
}

func testSafariSettingsCookiePolicy() {
    let store = uniqueStore()
    precondition(store.safari.cookiePolicy == nil)
    store.safari.cookiePolicy = .never
    precondition(store.safari.cookiePolicy == .never)
    precondition(SafariSettings.cookiePolicy.defaultValue == .always)
}

func testSafariSettingsDenyAutoFill() {
    let store = uniqueStore()
    precondition(store.safari.denyAutoFill == nil)
    store.safari.denyAutoFill = true
    precondition(store.safari.denyAutoFill == true)
    precondition(SafariSettings.denyAutoFill.defaultValue == false)
}

func testSiriSettingsDenySiri() {
    let store = uniqueStore()
    precondition(store.siri.denySiri == nil)
    store.siri.denySiri = true
    precondition(store.siri.denySiri == true)
    precondition(SiriSettings.denySiri.defaultValue == false)
}

func testWebContentSettingsBlockedByFilter() {
    let store = uniqueStore()
    precondition(store.webContent.blockedByFilter == nil)
    store.webContent.blockedByFilter = WebContentSettings.FilterPolicy.none
    precondition(store.webContent.blockedByFilter == WebContentSettings.FilterPolicy.none)
    store.webContent.blockedByFilter = .specific([WebDomain(domain: "blocked.example")])
    precondition(store.webContent.blockedByFilter != WebContentSettings.FilterPolicy.none)
    precondition(WebContentSettings.blockedByFilter.defaultValue == WebContentSettings.FilterPolicy.none)
}

func testShieldSettingsApplications() {
    let store = uniqueStore()
    precondition(store.shield.applications == nil)
    let token: ApplicationToken = {
        let json = Data("{\"linuxOpaqueID\":\"D4D4D4D4-D4D4-44D4-84D4-D4D4D4D4D4D4\"}".utf8)
        return try! JSONDecoder().decode(ApplicationToken.self, from: json)
    }()
    store.shield.applications = [token]
    precondition(store.shield.applications == [token])
    precondition(ShieldSettings.applications.defaultValue.isEmpty)
}

func testShieldSettingsApplicationCategories() {
    let store = uniqueStore()
    precondition(store.shield.applicationCategories == nil)
    store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy<Application>.none
    precondition(store.shield.applicationCategories == ShieldSettings.ActivityCategoryPolicy<Application>.none)
    precondition(ShieldSettings.applicationCategories.defaultValue == ShieldSettings.ActivityCategoryPolicy<Application>.none)
}

func testShieldSettingsWebDomains() {
    let store = uniqueStore()
    precondition(store.shield.webDomains == nil)
    let token: WebDomainToken = {
        let json = Data("{\"linuxOpaqueID\":\"E5E5E5E5-E5E5-45E5-85E5-E5E5E5E5E5E5\"}".utf8)
        return try! JSONDecoder().decode(WebDomainToken.self, from: json)
    }()
    store.shield.webDomains = [token]
    precondition(store.shield.webDomains == [token])
    precondition(ShieldSettings.webDomains.defaultValue.isEmpty)
}

func testShieldSettingsWebDomainCategories() {
    let store = uniqueStore()
    precondition(store.shield.webDomainCategories == nil)
    store.shield.webDomainCategories = .all(except: [])
    precondition(store.shield.webDomainCategories == .all(except: []))
    precondition(ShieldSettings.webDomainCategories.defaultValue == ShieldSettings.ActivityCategoryPolicy<WebDomain>.none)
}
