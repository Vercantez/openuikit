import Foundation
@_spi(OpenUIKitHost) import ScreenTime

func testWebHistoryType() {
    let history = STWebHistory(profileIdentifier: nil)
    precondition(type(of: history) == STWebHistory.self)
    let object: NSObject = history
    precondition(object === history)
}

func testWebHistoryInitBundleIdentifier() {
    do {
        let history = try STWebHistory(bundleIdentifier: "com.example.browser")
        precondition(history.bundleIdentifier == "com.example.browser")
        precondition(history.profileIdentifier == nil)
    } catch {
        preconditionFailure("nonempty bundle identifier must construct a handle: \(error)")
    }
    do {
        _ = try STWebHistory(bundleIdentifier: "   ")
        preconditionFailure("whitespace bundle identifier must throw")
    } catch let error as STScreenTimeError {
        precondition(error == .invalidBundleIdentifier)
    } catch {
        preconditionFailure("expected STScreenTimeError.invalidBundleIdentifier")
    }
}

func testWebHistoryInitBundleAndProfile() {
    let profile = STWebHistory.ProfileIdentifier("Profile.Work")
    do {
        let history = try STWebHistory(
            bundleIdentifier: "com.example.browser",
            profileIdentifier: profile
        )
        precondition(history.bundleIdentifier == "com.example.browser")
        precondition(history.profileIdentifier == profile)
    } catch {
        preconditionFailure("valid bundle and profile must construct: \(error)")
    }
    do {
        _ = try STWebHistory(bundleIdentifier: "", profileIdentifier: profile)
        preconditionFailure("empty bundle identifier must throw")
    } catch let error as STScreenTimeError {
        precondition(error.code == .invalidBundleIdentifier)
    } catch {
        preconditionFailure("expected invalidBundleIdentifier")
    }
}

func testWebHistoryInitProfileIdentifier() {
    let profile = STWebHistory.ProfileIdentifier("Profile.Personal")
    let withProfile = STWebHistory(profileIdentifier: profile)
    precondition(withProfile.profileIdentifier == profile)
    precondition(withProfile.bundleIdentifier == nil)
    let without = STWebHistory(profileIdentifier: nil)
    precondition(without.profileIdentifier == nil)
}

func testWebHistoryDeleteAllHistory() {
    let history = STWebHistory(profileIdentifier: nil)
    history.deleteAllHistory()
    history.deleteAllHistory()
}

func testWebHistoryDeleteHistoryDuringInterval() {
    let history = STWebHistory(profileIdentifier: nil)
    let interval = DateInterval(
        start: Date(timeIntervalSince1970: 0),
        duration: 3600
    )
    history.deleteHistory(during: interval)
}

func testWebHistoryDeleteHistoryForURL() {
    let history = STWebHistory(profileIdentifier: nil)
    let url = URL(string: "https://example.invalid/")!
    history.deleteHistory(for: url)
}

func testWebHistoryFetchAllHistoryCompletionFailClosed() {
    let history = STWebHistory(profileIdentifier: nil)
    var calls = 0
    var receivedURLs: Set<URL>? = Set()
    var receivedError: (any Error)?
    history.fetchAllHistory { urls, error in
        calls += 1
        receivedURLs = urls
        receivedError = error
    }
    precondition(calls == 1, "completion must run inline")
    precondition(receivedURLs == nil)
    let typed = receivedError as? STScreenTimeError
    precondition(typed == ScreenTimeHostControl.linuxFetchError)
}

func testWebHistoryFetchHistoryDuringFailClosed() {
    let history = try! STWebHistory(bundleIdentifier: "com.example.browser")
    let method: (DateInterval) async throws -> Set<URL> = history.fetchHistory(during:)
    _ = method
    let interval = DateInterval(start: Date(timeIntervalSince1970: 10), duration: 5)
    do {
        _ = try ScreenTimeHostControl.fetchHistorySync(history, during: interval)
        preconditionFailure("Linux must not invent a successful history fetch")
    } catch let error as STScreenTimeError {
        precondition(error == .unavailable)
    } catch {
        preconditionFailure("expected STScreenTimeError.unavailable")
    }
}
