import Foundation
@_spi(OpenUIKitHost) import GameSave

private func gamesaveStateTestURL(_ name: String) -> URL {
    URL(fileURLWithPath: "/tmp/gamesave-state-tests/\(name)", isDirectory: true)
}

func testStateType() {
    let url = gamesaveStateTestURL("type")
    let state: GameSaveSyncedDirectory.State = .local(url)
    precondition(type(of: state) == GameSaveSyncedDirectory.State.self)
}

func testStateReady() {
    let url = gamesaveStateTestURL("ready")
    let state = GameSaveSyncedDirectory.State.ready(url)
    guard case .ready(let stored) = state else {
        preconditionFailure("expected ready")
    }
    precondition(stored == url)
}

func testStateOffline() {
    let url = gamesaveStateTestURL("offline")
    let state = GameSaveSyncedDirectory.State.offline(url)
    guard case .offline(let stored) = state else {
        preconditionFailure("expected offline")
    }
    precondition(stored == url)
}

func testStateLocal() {
    let url = gamesaveStateTestURL("local")
    let state = GameSaveSyncedDirectory.State.local(url)
    guard case .local(let stored) = state else {
        preconditionFailure("expected local")
    }
    precondition(stored == url)
}

func testStateSyncing() {
    let state = GameSaveSyncedDirectory.State.syncing
    guard case .syncing = state else {
        preconditionFailure("expected syncing")
    }
}

func testStateConflicted() {
    let url = gamesaveStateTestURL("conflicted")
    let version = GameSaveSyncedDirectory.Version(
        url: url,
        isLocal: true,
        localizedNameOfSavingComputer: "Test Mac",
        modifiedDate: Date(timeIntervalSince1970: 1)
    )
    let state = GameSaveSyncedDirectory.State.conflicted(versions: [version])
    guard case .conflicted(let versions) = state else {
        preconditionFailure("expected conflicted")
    }
    precondition(versions.count == 1)
    precondition(versions[0] === version)
}

func testStateError() {
    let error = NSError(domain: GameSaveErrorDomain, code: 1)
    let state = GameSaveSyncedDirectory.State.error(error)
    guard case .error(let stored) = state else {
        preconditionFailure("expected error")
    }
    let nsError = stored as NSError
    precondition(nsError.domain == GameSaveErrorDomain)
    precondition(nsError.code == 1)
}

func testStateClosed() {
    let state = GameSaveSyncedDirectory.State.closed
    guard case .closed = state else {
        preconditionFailure("expected closed")
    }
}

func testStateDescription() {
    let url = gamesaveStateTestURL("description")
    precondition(GameSaveSyncedDirectory.State.ready(url).description.hasPrefix("ready("))
    precondition(GameSaveSyncedDirectory.State.offline(url).description.hasPrefix("offline("))
    precondition(GameSaveSyncedDirectory.State.local(url).description.hasPrefix("local("))
    precondition(GameSaveSyncedDirectory.State.syncing.description == "syncing")
    precondition(GameSaveSyncedDirectory.State.closed.description == "closed")
    let version = GameSaveSyncedDirectory.Version(
        url: url,
        isLocal: false,
        localizedNameOfSavingComputer: "Other",
        modifiedDate: Date(timeIntervalSince1970: 2)
    )
    let conflicted = GameSaveSyncedDirectory.State.conflicted(versions: [version])
    precondition(conflicted.description == "conflicted(count: 1)")
    let error = GameSaveSyncedDirectory.State.error(NSError(domain: GameSaveErrorDomain, code: 1))
    precondition(error.description.hasPrefix("error("))
}
