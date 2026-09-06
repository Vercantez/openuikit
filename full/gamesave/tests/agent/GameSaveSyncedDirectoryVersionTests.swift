import Foundation
@_spi(OpenUIKitHost) import GameSave

func testVersionType() {
    let url = URL(fileURLWithPath: "/tmp/gamesave-version/type", isDirectory: true)
    let version = GameSaveSyncedDirectory.Version(
        url: url,
        isLocal: true,
        localizedNameOfSavingComputer: "Linux Host",
        modifiedDate: Date(timeIntervalSince1970: 10)
    )
    precondition(type(of: version) == GameSaveSyncedDirectory.Version.self)
}

func testVersionIDTypealias() {
    precondition(GameSaveSyncedDirectory.Version.ID.self == URL.self)
}

func testVersionId() {
    let url = URL(fileURLWithPath: "/tmp/gamesave-version/id", isDirectory: true)
    let version = GameSaveSyncedDirectory.Version(
        url: url,
        isLocal: true,
        localizedNameOfSavingComputer: "Host",
        modifiedDate: Date(timeIntervalSince1970: 11)
    )
    precondition(version.id == url)
    precondition(version.id == version.url)
}

func testVersionIsLocal() {
    let url = URL(fileURLWithPath: "/tmp/gamesave-version/local", isDirectory: true)
    let local = GameSaveSyncedDirectory.Version(
        url: url,
        isLocal: true,
        localizedNameOfSavingComputer: "Host",
        modifiedDate: Date(timeIntervalSince1970: 12)
    )
    let remote = GameSaveSyncedDirectory.Version(
        url: url,
        isLocal: false,
        localizedNameOfSavingComputer: "Other",
        modifiedDate: Date(timeIntervalSince1970: 12)
    )
    precondition(local.isLocal)
    precondition(!remote.isLocal)
}

func testVersionLocalizedNameOfSavingComputer() {
    let url = URL(fileURLWithPath: "/tmp/gamesave-version/name", isDirectory: true)
    let version = GameSaveSyncedDirectory.Version(
        url: url,
        isLocal: true,
        localizedNameOfSavingComputer: "Studio Display Mac",
        modifiedDate: Date(timeIntervalSince1970: 13)
    )
    precondition(version.localizedNameOfSavingComputer == "Studio Display Mac")
}

func testVersionModifiedDate() {
    let url = URL(fileURLWithPath: "/tmp/gamesave-version/date", isDirectory: true)
    let original = Date(timeIntervalSince1970: 14)
    let version = GameSaveSyncedDirectory.Version(
        url: url,
        isLocal: true,
        localizedNameOfSavingComputer: "Host",
        modifiedDate: original
    )
    precondition(version.modifiedDate == original)
    let updated = Date(timeIntervalSince1970: 99)
    version.modifiedDate = updated
    precondition(version.modifiedDate == updated)
}

func testVersionURL() {
    let url = URL(fileURLWithPath: "/tmp/gamesave-version/url", isDirectory: true)
    let version = GameSaveSyncedDirectory.Version(
        url: url,
        isLocal: false,
        localizedNameOfSavingComputer: "Cloud",
        modifiedDate: Date(timeIntervalSince1970: 15)
    )
    precondition(version.url == url)
    precondition(version.url.isFileURL)
}

func testVersionDescription() {
    let url = URL(fileURLWithPath: "/tmp/gamesave-version/description", isDirectory: true)
    let version = GameSaveSyncedDirectory.Version(
        url: url,
        isLocal: true,
        localizedNameOfSavingComputer: "Host",
        modifiedDate: Date(timeIntervalSince1970: 16)
    )
    let text = version.description
    precondition(text.contains("GameSaveSyncedDirectory.Version"))
    precondition(text.contains("isLocal: true"))
    precondition(text.contains(url.absoluteString))
    precondition(String(describing: version) == text)
}
