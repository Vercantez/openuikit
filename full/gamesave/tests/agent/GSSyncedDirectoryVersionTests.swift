import Foundation
@_spi(OpenUIKitHost) import GameSave

func testGSVersionType() {
    let version = GameSaveSyncedDirectory.Version(
        url: URL(fileURLWithPath: "/tmp/gamesave-gs-version/type", isDirectory: true),
        isLocal: true,
        localizedNameOfSavingComputer: "Host",
        modifiedDate: Date(timeIntervalSince1970: 50)
    )
    let objc = GSSyncedDirectoryVersion(hostVersion: version)
    let asObject: NSObject = objc
    precondition(asObject === objc)
    precondition(type(of: objc) == GSSyncedDirectoryVersion.self)
}

func testGSVersionDescription() {
    let url = URL(fileURLWithPath: "/tmp/gamesave-gs-version/description", isDirectory: true)
    let version = GameSaveSyncedDirectory.Version(
        url: url,
        isLocal: false,
        localizedNameOfSavingComputer: "Other",
        modifiedDate: Date(timeIntervalSince1970: 51)
    )
    let objc = GSSyncedDirectoryVersion(hostVersion: version)
    precondition(objc.description == version.description)
    precondition(objc.description.contains("isLocal: false"))
}

func testGSVersionIsLocal() {
    let url = URL(fileURLWithPath: "/tmp/gamesave-gs-version/local", isDirectory: true)
    let local = GSSyncedDirectoryVersion(
        hostVersion: GameSaveSyncedDirectory.Version(
            url: url,
            isLocal: true,
            localizedNameOfSavingComputer: "Host",
            modifiedDate: Date(timeIntervalSince1970: 52)
        )
    )
    let remote = GSSyncedDirectoryVersion(
        hostVersion: GameSaveSyncedDirectory.Version(
            url: url,
            isLocal: false,
            localizedNameOfSavingComputer: "Other",
            modifiedDate: Date(timeIntervalSince1970: 52)
        )
    )
    precondition(local.isLocal)
    precondition(!remote.isLocal)
}

func testGSVersionLocalizedName() {
    let objc = GSSyncedDirectoryVersion(
        hostVersion: GameSaveSyncedDirectory.Version(
            url: URL(fileURLWithPath: "/tmp/gamesave-gs-version/name", isDirectory: true),
            isLocal: true,
            localizedNameOfSavingComputer: "Living Room Mac",
            modifiedDate: Date(timeIntervalSince1970: 53)
        )
    )
    precondition(objc.localizedNameOfSavingComputer == "Living Room Mac")
}

func testGSVersionModifiedDate() {
    let date = Date(timeIntervalSince1970: 54)
    let objc = GSSyncedDirectoryVersion(
        hostVersion: GameSaveSyncedDirectory.Version(
            url: URL(fileURLWithPath: "/tmp/gamesave-gs-version/date", isDirectory: true),
            isLocal: true,
            localizedNameOfSavingComputer: "Host",
            modifiedDate: date
        )
    )
    precondition(objc.modifiedDate == date)
}

func testGSVersionURL() {
    let url = URL(fileURLWithPath: "/tmp/gamesave-gs-version/url", isDirectory: true)
    let objc = GSSyncedDirectoryVersion(
        hostVersion: GameSaveSyncedDirectory.Version(
            url: url,
            isLocal: false,
            localizedNameOfSavingComputer: "Cloud",
            modifiedDate: Date(timeIntervalSince1970: 55)
        )
    )
    precondition(objc.url == url)
    precondition(objc.url.isFileURL)
}
