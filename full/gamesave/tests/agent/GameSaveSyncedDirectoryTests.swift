import Foundation
@_spi(OpenUIKitHost) import GameSave

func testSyncedDirectoryType() {
    let directory = GameSaveSyncedDirectory.openDirectory(containerIdentifier: "type")
    precondition(type(of: directory) == GameSaveSyncedDirectory.self)
}

func testOpenDirectory() {
    let directory = GameSaveSyncedDirectory.openDirectory(containerIdentifier: "open.slot")
    guard case .local(let url) = directory.state else {
        preconditionFailure("expected local-only open; Linux has no iCloud daemon")
    }
    precondition(url.isFileURL)
    precondition(FileManager.default.fileExists(atPath: url.path))
    let file = url.appendingPathComponent("slot.dat")
    do {
        try Data("save".utf8).write(to: file)
    } catch {
        preconditionFailure("failed to write local save file")
    }
    precondition(FileManager.default.fileExists(atPath: file.path))
    let defaultDirectory = GameSaveSyncedDirectory.openDirectory()
    precondition(defaultDirectory.id == "GameSave.local")
    precondition(
        GameSaveSyncedDirectory.openDirectory(containerIdentifier: nil).id
            == defaultDirectory.id
    )
}

func testSyncedDirectoryId() {
    let directory = GameSaveSyncedDirectory.openDirectory(containerIdentifier: "id.container")
    precondition(directory.id == "id.container")
    precondition(directory.hostContainerIdentifier == "id.container")
}

func testSyncedDirectoryEquality() {
    let left = GameSaveSyncedDirectory.openDirectory(containerIdentifier: "equal")
    let right = GameSaveSyncedDirectory.openDirectory(containerIdentifier: "equal")
    let other = GameSaveSyncedDirectory.openDirectory(containerIdentifier: "other")
    precondition(left == right)
    precondition(!(left == other))
}

func testSyncedDirectoryInequality() {
    let left = GameSaveSyncedDirectory.openDirectory(containerIdentifier: "neq-a")
    let right = GameSaveSyncedDirectory.openDirectory(containerIdentifier: "neq-b")
    precondition(left != right)
    precondition(!(left != GameSaveSyncedDirectory.openDirectory(containerIdentifier: "neq-a")))
}

func testSyncedDirectoryIDTypealias() {
    precondition(GameSaveSyncedDirectory.ID.self == String.self)
}

func testSyncedDirectoryState() {
    let directory = GameSaveSyncedDirectory.openDirectory(containerIdentifier: "state")
    guard case .local(let url) = directory.state else {
        preconditionFailure("expected local")
    }
    precondition(url == directory.hostLocalURL)
    directory.hostEnterReady()
    guard case .ready(let readyURL) = directory.state else {
        preconditionFailure("expected ready after host inject")
    }
    precondition(readyURL == directory.hostLocalURL)
    directory.hostEnterOffline()
    guard case .offline = directory.state else {
        preconditionFailure("expected offline after host inject")
    }
}

func testSyncedDirectoryClose() {
    let directory = GameSaveSyncedDirectory.openDirectory(containerIdentifier: "close")
    guard case .local = directory.state else {
        preconditionFailure("expected local before close")
    }
    directory.close()
    guard case .closed = directory.state else {
        preconditionFailure("expected closed")
    }
    directory.close()
    guard case .closed = directory.state else {
        preconditionFailure("close is idempotent")
    }
}

func testResolveConflicts() {
    let directory = GameSaveSyncedDirectory.openDirectory(containerIdentifier: "conflict")
    let localURL = directory.hostLocalURL
    let otherURL = URL(fileURLWithPath: "/tmp/gamesave-conflict-other", isDirectory: true)
    let localVersion = GameSaveSyncedDirectory.Version(
        url: localURL,
        isLocal: true,
        localizedNameOfSavingComputer: "This Host",
        modifiedDate: Date(timeIntervalSince1970: 20)
    )
    let otherVersion = GameSaveSyncedDirectory.Version(
        url: otherURL,
        isLocal: false,
        localizedNameOfSavingComputer: "Other Host",
        modifiedDate: Date(timeIntervalSince1970: 21)
    )
    directory.resolveConflicts(with: otherVersion)
    guard case .local(let stillLocal) = directory.state else {
        preconditionFailure("resolve no-ops unless conflicted")
    }
    precondition(stillLocal == localURL)

    directory.hostEnterConflicted(versions: [localVersion, otherVersion])
    guard case .conflicted(let versions) = directory.state else {
        preconditionFailure("expected conflicted")
    }
    precondition(versions.count == 2)
    directory.resolveConflicts(with: otherVersion)
    guard case .local(let chosen) = directory.state else {
        preconditionFailure("expected local after resolve")
    }
    precondition(chosen == otherURL)
}
