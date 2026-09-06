import Foundation
@_spi(OpenUIKitHost) import LockedCameraCapture

private func resetManager() {
    LockedCameraCaptureManager.shared.hostReset()
}

func testLockedCameraCaptureManagerClass() {
    resetManager()
    let manager = LockedCameraCaptureManager.shared
    precondition(type(of: manager) == LockedCameraCaptureManager.self)
    let asObject: AnyObject = manager
    precondition(asObject === manager)
}

func testManagerShared() {
    resetManager()
    let a = LockedCameraCaptureManager.shared
    let b = LockedCameraCaptureManager.shared
    precondition(a === b)
}

func testManagerSessionContentURLs() {
    resetManager()
    let manager = LockedCameraCaptureManager.shared
    precondition(manager.sessionContentURLs.isEmpty)
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("LockedCameraCapture-manager-\(UUID().uuidString)")
    manager.hostRegisterSessionContentURL(url)
    precondition(manager.sessionContentURLs == [url])
    manager.hostRegisterSessionContentURL(url)
    precondition(manager.sessionContentURLs == [url])
}

func testSessionContentUpdateType() {
    let sample: LockedCameraCaptureManager.SessionContentUpdate = .initial(urls: [])
    switch sample {
    case .initial(let urls):
        precondition(urls.isEmpty)
    case .added, .removed:
        preconditionFailure("expected initial")
    }
}

func testSessionContentUpdateCases() {
    let a = URL(fileURLWithPath: "/tmp/lcc-a")
    let b = URL(fileURLWithPath: "/tmp/lcc-b")
    let initial: LockedCameraCaptureManager.SessionContentUpdate = .initial(urls: [a, b])
    let added: LockedCameraCaptureManager.SessionContentUpdate = .added(url: a)
    let removed: LockedCameraCaptureManager.SessionContentUpdate = .removed(url: b)
    switch initial {
    case .initial(let urls):
        precondition(urls == [a, b])
    default:
        preconditionFailure("initial")
    }
    switch added {
    case .added(let url):
        precondition(url == a)
    default:
        preconditionFailure("added")
    }
    switch removed {
    case .removed(let url):
        precondition(url == b)
    default:
        preconditionFailure("removed")
    }
}

func testSessionContentUpdates() {
    resetManager()
    let manager = LockedCameraCaptureManager.shared
    let seq = manager.sessionContentUpdates
    precondition(type(of: seq) == LockedCameraCaptureSessionContentUpdates.self)
    let snapshot = manager.hostSessionContentUpdateSnapshot
    precondition(snapshot.count == 1)
    switch snapshot[0] {
    case .initial(let urls):
        precondition(urls.isEmpty)
    default:
        preconditionFailure("expected initial empty snapshot")
    }
    _ = seq.makeAsyncIterator()
}

func testManagerInvalidateSessionContentAt() {
    resetManager()
    let manager = LockedCameraCaptureManager.shared
    let ignored = URL(fileURLWithPath: "/tmp/lcc-ignored-\(UUID().uuidString)")
    do {
        try manager.invalidateSessionContent(at: ignored)
        precondition(manager.sessionContentURLs.isEmpty)

        let owned = FileManager.default.temporaryDirectory
            .appendingPathComponent("LockedCameraCapture-owned-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: owned, withIntermediateDirectories: true)
        manager.hostRegisterSessionContentURL(owned)
        precondition(manager.sessionContentURLs == [owned])
        try manager.invalidateSessionContent(at: owned)
        precondition(manager.sessionContentURLs.isEmpty)
        precondition(!FileManager.default.fileExists(atPath: owned.path))
        let snapshot = manager.hostSessionContentUpdateSnapshot
        precondition(snapshot.count == 3)
        switch snapshot[1] {
        case .added(let url):
            precondition(url == owned)
        default:
            preconditionFailure("expected added")
        }
        switch snapshot[2] {
        case .removed(let url):
            precondition(url == owned)
        default:
            preconditionFailure("expected removed")
        }
    } catch {
        preconditionFailure("invalidateSessionContent(at:) filesystem failure")
    }
}

func testBeginDelayingAppearance() {
    resetManager()
    let manager = LockedCameraCaptureManager.shared
    precondition(manager.hostAppearanceDelayDepth == 0)
    manager.beginDelayingAppearance()
    precondition(manager.hostAppearanceDelayDepth == 1)
    manager.beginDelayingAppearance()
    precondition(manager.hostAppearanceDelayDepth == 2)
}

func testEndDelayingAppearance() {
    resetManager()
    let manager = LockedCameraCaptureManager.shared
    manager.endDelayingAppearance()
    precondition(manager.hostAppearanceDelayDepth == 0)
    manager.beginDelayingAppearance()
    manager.beginDelayingAppearance()
    manager.endDelayingAppearance()
    precondition(manager.hostAppearanceDelayDepth == 1)
    manager.endDelayingAppearance()
    precondition(manager.hostAppearanceDelayDepth == 0)
    manager.endDelayingAppearance()
    precondition(manager.hostAppearanceDelayDepth == 0)
}
