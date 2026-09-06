import Foundation
@_spi(OpenUIKitHost) import GameSave

func testGSDirectoryStateType() {
    let directory = GSSyncedDirectory.open(forContainerIdentifier: "state-type")
    let snapshot = directory.directoryState
    precondition(type(of: snapshot) == GSSyncedDirectoryState.self)
    let asObject: NSObject = snapshot
    precondition(asObject === snapshot)
}

func testGSDirectoryStateState() {
    let directory = GSSyncedDirectory.open(forContainerIdentifier: "state-state")
    precondition(directory.directoryState.state == .local)
    directory.hostSwiftDirectory.hostEnterReady()
    precondition(directory.directoryState.state == .ready)
    directory.hostSwiftDirectory.hostEnterOffline()
    precondition(directory.directoryState.state == .offline)
    directory.close()
    precondition(directory.directoryState.state == .closed)
}

func testGSDirectoryStateURL() {
    let directory = GSSyncedDirectory.open(forContainerIdentifier: "state-url")
    let url = directory.directoryState.url
    precondition(url == directory.hostSwiftDirectory.hostLocalURL)
    directory.hostSwiftDirectory.hostEnterSyncing()
    precondition(directory.directoryState.url == nil)
    directory.close()
    precondition(directory.directoryState.url == nil)
}

func testGSDirectoryStateConflictedVersions() {
    let directory = GSSyncedDirectory.open(forContainerIdentifier: "state-conflict")
    precondition(directory.directoryState.conflictedVersions == nil)
    let version = GameSaveSyncedDirectory.Version(
        url: directory.hostSwiftDirectory.hostLocalURL,
        isLocal: true,
        localizedNameOfSavingComputer: "Host",
        modifiedDate: Date(timeIntervalSince1970: 40)
    )
    directory.hostSwiftDirectory.hostEnterConflicted(versions: [version])
    let versions = directory.directoryState.conflictedVersions
    precondition(versions?.count == 1)
    precondition(versions?[0].url == version.url)
    precondition(versions?[0].isLocal == true)
}

func testGSDirectoryStateError() {
    let directory = GSSyncedDirectory.open(forContainerIdentifier: "state-error")
    precondition(directory.directoryState.error == nil)
    let error = NSError(domain: GameSaveErrorDomain, code: 1, userInfo: nil)
    directory.hostSwiftDirectory.hostEnterError(error)
    precondition(directory.directoryState.state == .error)
    let stored = directory.directoryState.error as NSError?
    precondition(stored?.domain == GameSaveErrorDomain)
    precondition(stored?.code == 1)
}
